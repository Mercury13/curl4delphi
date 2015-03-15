unit f_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Curl.Easy, Curl.Lib;

const
  // W = progress in permille (-1 = unknown), L unused
  WM_PROGRESS = WM_USER + 1;
  // W = whether success, L unused
  WM_STOP = WM_USER + 2;
  // Params unused
  WM_SELECTFILE = WM_USER + 3;

type
  TMyThread = class (TThread)
  private
    curl : IEasyCurl;
    progress : integer;
    fs : TFileStream;
    wantSelectFile : boolean;
    wantedFileName : string;
    class function HeaderFunc(
          var Buffer;
          Size, NItems : NativeUInt;
          OutStream : pointer) : NativeUInt;  cdecl;  static;
    class function XferInfo(
          ClientP : pointer;
          DlTotal, DlNow, UlTotal, UlNow : TCurlOff) : integer;  cdecl;  static;
    procedure SelectFileSync;
    procedure SelectFileIfOk;
  protected
    procedure Execute;  override;
  public
    constructor Create(const aUrl, aTempName : string);
  end;

  TSelectFileState = (
        sfsNameUnknown,     // Initial — file name is unknown
        sfsPending,         // We put a message to queue
        sfsInProgress,      // In progress
        sfsSlowpoke,        // The user was so slow that it downloaded before he made a decision
        sfsDone );          // Done

  TfmMain = class(TForm)
    edUrl: TEdit;
    Label1: TLabel;
    btDownload: TButton;
    progress: TProgressBar;
    sd: TSaveDialog;
    lbError: TLabel;
    procedure btDownloadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ServeSelectFile;
    procedure SetProgressPos(x : integer);
  private
    thread : TMyThread;
    SelectState : TSelectFileState;
    TempFileName : string;
    procedure DisableControls;
    procedure EnableControls(aWantedProgress : integer);
    ///  @return [+] stopped  [-] no thread
    function StopThread : boolean;
    procedure MoveFile;
    procedure DeleteTempFile;
    procedure SetErrorMsg(s : string);
  protected
    procedure WmProgress(var aMsg : TMessage);  message WM_PROGRESS;
    procedure WmStop(var aMsg : TMessage);  message WM_STOP;
    procedure WmSelectFile(var aMsg : TMessage);  message WM_SELECTFILE;
  public
    wantedFileName, selectedFileName : string;
    procedure DeferedSelectFile;
    procedure AsyncProgress(aPermille : integer);
    procedure AsyncStop(aSuccess : boolean);
    procedure SetError(s : string);
  end;

var
  fmMain: TfmMain;

implementation

uses
  System.IOUtils,
  Curl.HttpCodes;

{$R *.dfm}

var
  WantStop : boolean = false;

class function TMyThread.XferInfo(
      ClientP : pointer;
      DlTotal, DlNow, UlTotal, UlNow : TCurlOff) : integer;
var
  slf : TMyThread;
  newprog : integer;
begin
  if WantStop
    then Exit(1);

  slf := TMyThread(ClientP);
  if DlTotal <> 0
    then newprog := dlNow * 1000 div dlTotal
    else newprog := -1;
  if newprog <> slf.progress then begin
    slf.progress := newprog;
    fmMain.AsyncProgress(newprog);
  end;
  Result := 0;
end;

procedure TMyThread.SelectFileSync;
begin
  if wantedFileName <> ''
    then fmMain.wantedFileName := wantedFileName;
  fmMain.DeferedSelectFile;
  wantSelectFile := false;
end;

procedure TMyThread.SelectFileIfOk;
begin
  if curl.GetResponseCode <> HTTP_OK
    then raise Exception.CreateFmt('HTTP error #%d.', [curl.GetResponseCode]);
  Synchronize(SelectFileSync);
end;

procedure TakeToFirst(var s : string; c : char);
var
  p : integer;
begin
  p := Pos(c, s);
  if p <> 0
    then s := Copy(s, 1, p - 1);
end;

function ParseContentDisposition(const s : string) : string;
const
  HeaderStr = 'filename=';
var
  p : integer;
  c1 : char;
begin
  p := Pos(HeaderStr, s);
  if p = 0
    then Exit('');

  Inc(p, Length(HeaderStr));
  Result := Copy(s, p);
  // s is now 'filename; blah' or '"filename"; blah'

  if Result= ''
    then Exit;
  c1 := Result[1];
  if CharInSet(c1, ['"', '''']) then begin
    // Delete quote
    Result := Copy(Result, 2);
    // Take until quote
    TakeToFirst(Result, c1);
  end else begin
    // Take until semicolon
    TakeToFirst(Result, ';');
  end;
end;

class function TMyThread.HeaderFunc(
      var Buffer;
      Size, NItems : NativeUInt;
      OutStream : pointer) : NativeUInt;  cdecl;
const
  HeaderStart = 'Content-Disposition:';
var
  slf : TMyThread;
  raw : RawByteString;
  s : string;
  p, p1 : integer;
begin
  Result := Size * NItems;
  slf := TMyThread(OutStream);
  if slf.wantSelectFile then begin
    SetLength(raw, Result);
    Move(Buffer, PAnsiChar(raw)^, Result);
    s := Trim(UTF8ToString(raw));
    // Now s is a header
    if s = '' then begin
      // Last line of header?
      slf.SelectFileIfOk;
    end else if Copy(s, 1, Length(HeaderStart)) = HeaderStart then begin
      s := ParseContentDisposition(s);
      if s <> '' then begin
        slf.wantedFileName := s;
        slf.SelectFileIfOk;
      end;
    end;
  end;
end;

constructor TMyThread.Create(const aUrl, aTempName : string);
begin
  inherited Create(true);
  wantSelectFile := true;
  wantedFileName := '';
  fs := TFileStream.Create(aTempName, fmCreate);
  curl := GetCurl;
  curl.SetUrl(aUrl);
  curl.SetRecvStream(fs);
  curl.SetFollowLocation(true);
  // Progress
  curl.SetOpt(CURLOPT_NOPROGRESS, 0);
  curl.SetOpt(CURLOPT_XFERINFOFUNCTION, @XferInfo);
  curl.SetOpt(CURLOPT_XFERINFODATA, Self);
  // Header parsing
  curl.SetOpt(CURLOPT_HEADERFUNCTION, @HeaderFunc);
  curl.SetOpt(CURLOPT_HEADERDATA, Self);
  progress := 0;

  Suspended := false;
end;

procedure TMyThread.Execute;
begin
  try
    try
      curl.Perform;
    finally
      fs.Free;
    end;
    if curl.GetResponseCode = HTTP_OK
      then fmMain.AsyncStop(true)
      else fmMain.SetError(Format('HTTP error %d.', [curl.GetResponseCode]));
  except
    on e : ECurlError do
      if e.Code = CURLE_ABORTED_BY_CALLBACK
        then fmMain.SetError('Operation stopped.')
        else fmMain.SetError(e.Message);
    on e : Exception do
      fmMain.SetError(e.Message);
    else
      fmMain.SetError('Unknown error');
  end;
end;

procedure TfmMain.SetProgressPos(x : integer);
begin
  progress.Style := pbstNormal;
  progress.Position := x;
end;

procedure TfmMain.EnableControls(aWantedProgress : integer);
begin
  btDownload.Enabled := true;
  edUrl.Enabled := true;
  SetProgressPos(aWantedProgress);
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if StopThread
    then DeleteTempFile;
  Action := caFree;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  SetErrorMsg('Started.');
end;

procedure TfmMain.DisableControls;
begin
  btDownload.Enabled := false;
  edUrl.Enabled := false;
  SetProgressPos(0);
end;

procedure TfmMain.WmProgress(var aMsg : TMessage);
begin
  if aMsg.WParam < 0
    then progress.Style := pbstMarquee
    else SetProgressPos(aMsg.WParam);
end;

procedure TfmMain.AsyncProgress(aPermille : integer);
begin
  PostMessage(Handle, WM_PROGRESS, aPermille, 0);
end;

procedure TfmMain.DeleteTempFile;
begin
  DeleteFile(TempFileName)
end;

procedure TfmMain.MoveFile;
begin
  if SelectedFileName = '' then begin
    DeleteTempFile;
  end else begin
    if not RenameFile(TempFileName, SelectedFileName) then begin
      Screen.Cursor := crHourGlass;
      try
        CopyFile(PChar(TempFileName), PChar(SelectedFileName), false);
        DeleteTempFile;
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TfmMain.WmStop(var aMsg : TMessage);
begin
  StopThread;
  if aMsg.WParam <> 0 then begin
    case SelectState of
    sfsNameUnknown : DeleteTempFile;  // Something’s wrong — stopped thread, name unknown
    sfsPending: begin                 // Download so fast that we even didn’t call message
        ServeSelectFile;
        MoveFile;
      end;
    sfsInProgress:      // The user is still selecting file name
      SelectState := sfsSlowpoke;
    sfsDone: MoveFile;  // Done
    end;
    SetErrorMsg('Done.');
    EnableControls(1000);
  end else begin
    DeleteTempFile;
    EnableControls(0);
  end;
end;

procedure TfmMain.AsyncStop(aSuccess : boolean);
begin
  PostMessage(Handle, WM_STOP, ord(aSuccess), 0);
end;

procedure TfmMain.btDownloadClick(Sender: TObject);
var
  url : string;
  p : integer;
begin
  SetErrorMsg('Downloading…');
  WantedFileName := '';
  url := edUrl.Text;
  if Pos('?', url) = 0 then begin
    p := LastDelimiter('/', url);
    WantedFileName := Copy(url, p + 1);
  end;
  SelectedFileName := '';
  SelectState := sfsNameUnknown;
  TempFileName := ExpandFileName(TPath.GetTempFileName);
  DisableControls;
  try
    thread := TMyThread.Create(url, tempFileName);
  except
    on e : Exception do begin
      SetErrorMsg(e.Message);
      EnableControls(0);
    end;
  end;
end;

function TfmMain.StopThread : boolean;
begin
  if thread = nil
    then Exit(false);
  WantStop := true;
  thread.WaitFor;
  FreeAndNil(thread);
  WantStop := false;
  Result := true;
end;

procedure TfmMain.WmSelectFile(var aMsg : TMessage);
begin
  ServeSelectFile;
end;

procedure TfmMain.ServeSelectFile;
const
  AllFiles = 'All files (*.*)|*.*';
var
  ext : string;
begin
  if SelectState <> sfsPending
    then Exit;
  SelectState := sfsInProgress;
  if wantedFileName = '' then begin
    sd.FileName := '';
    sd.Filter := 'All files (*.*)|*.*';
  end else begin
    sd.FileName := ExtractFileName(wantedFileName);
    ext := ExtractFileExt(wantedFileName);
    if ext = ''
      then sd.Filter := 'All files (*.*)|*.*'
      else sd.Filter := Format('%0:s files(*.%0:s)|*.%0:s|' + AllFiles, [ext]);
  end;
  if sd.Execute then begin
    SelectedFileName := ExpandFileName(sd.FileName);
    // While we were choosing a filename, the file downloaded?
    if SelectState = sfsSlowpoke
      then MoveFile;
  end else begin
    StopThread;
    EnableControls(0);
    // While we were choosing a filename, the file downloaded?
    if SelectState = sfsSlowpoke
      then DeleteTempFile;
  end;
  SelectState := sfsDone;
end;

procedure TfmMain.DeferedSelectFile;
begin
  SelectState := sfsPending;
  PostMessage(Handle, WM_SELECTFILE, 0, 0);
end;

procedure TfmMain.SetErrorMsg(s : string);
begin
  lbError.Caption := s;
end;

procedure TfmMain.SetError(s : string);
begin
  SetErrorMsg(s);
  AsyncStop(false);
end;

end.
