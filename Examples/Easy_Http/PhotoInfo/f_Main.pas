unit f_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Curl.Interfaces;

type
  TfmMain = class(TForm)
    edUrl: TEdit;
    Label3: TLabel;
    memoResponse: TMemo;
    Label1: TLabel;
    btEasy: TButton;
    btHard: TButton;
    Label2: TLabel;
    btSynthStream: TButton;
    od: TOpenDialog;
    btSynthMemory: TButton;
    btCloneDemo: TButton;
    btSynthMemory2: TButton;
    btSynthMemory3: TButton;
    procedure btHardClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btEasyClick(Sender: TObject);
    procedure btSynthStreamClick(Sender: TObject);
    procedure btSynthMemoryClick(Sender: TObject);
    procedure btCloneDemoClick(Sender: TObject);
    procedure btSynthMemory2Click(Sender: TObject);
    procedure btSynthMemory3Click(Sender: TObject);
  private
    { Private declarations }
    pngStream : TMemoryStream;
    function GetFile(
          out rFname : string; out rFtype : RawByteString) : boolean;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

uses
  Curl.Easy, Curl.Form, Curl.Lib,
  Curl.Slist, Vcl.Imaging.PngImage;

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
var
  png : TPngImage;
begin
  // Synthetic image — stream
  png := TPngImage.CreateBlank(COLOR_RGB, 8, 123, 456);
  try
    pngStream := TMemoryStream.Create;
    png.SaveToStream(pngStream);
  finally
    png.Free;
  end;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  pngStream.Free;
end;

function TfmMain.GetFile(
        out rFname : string; out rFtype : RawByteString) : boolean;
var
  ext : string;
begin
  if not od.Execute
    then Exit(false);

  rFname := ExpandFileName(od.FileName);
  ext := UpperCase(ExtractFileExt(od.FileName), loInvariantLocale);
  if ext = '.PNG'
    then rFType := 'image/png'
  else if (ext = '.JPG') or (ext = '.JPEG')
    then rFType := 'image/jpeg'
  else Exit(false);
  Exit(true);
end;

procedure TfmMain.btCloneDemoClick(Sender: TObject);
var
  curl1, curl2 : ICurl;
  fname : string;
  ftype : RawByteString;
begin
  // It is BAD code!! — it is just an illustration that options are copied.
  // cur1 and curl2 share streams, so problems will rise when we use them
  // simultaneously, or destroy curl1 prematurely.
  if not GetFile(fname, ftype) then Exit;

  curl1 := CurlGet;
  curl1.SwitchRecvToString
       .SetUrl(edUrl.Text)
       .SetOpt(CURLOPT_POST, true)
       .SetForm(CurlGetForm.AddFile('photo', fname, ftype));

  curl2 := curl1.Clone;
  curl2.Perform;
  memoResponse.Text := UTF8ToString(curl2.ResponseBody);
end;

procedure TfmMain.btEasyClick(Sender: TObject);
var
  curl : ICurl;
  fname : string;
  ftype : RawByteString;
begin
  // Disk file — easy way
  if not GetFile(fname, ftype) then Exit;

  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm(CurlGetForm.AddFile('photo', fname, ftype))
      .Perform;
  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

procedure TfmMain.btHardClick(Sender: TObject);
var
  curl : ICurl;
  fname : string;
  ftype : RawByteString;
begin
  // Disk file — hard way
  if not GetFile(fname, ftype) then Exit;

  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm(CurlGetForm.Add(
                  CurlGetField
                      .Name('photo')
                      .UploadFile(fname)
                      .ContentType(ftype)))
      .Perform;

  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

procedure TfmMain.btSynthMemory2Click(Sender: TObject);
var
  curl : ICurl;
begin
  // cURL
  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm(CurlGetForm.AddFileBuffer(
                    'photo', 'synth_buffer2.png', 'image/png',
                    pngStream.Size, pngStream.Memory^))
      .Perform;
  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

procedure TfmMain.btSynthMemory3Click(Sender: TObject);
var
  curl : ICurl;
  str : RawByteString;
begin
  SetLength(str, pngStream.Size);
  Move(pngStream.Memory^, PAnsiChar(str)^, pngStream.Size);
  // cURL
  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm(CurlGetForm.AddFileBuffer(
                    'photo', 'synth_buffer3.png', 'image/png', str))
      .Perform;
  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

procedure TfmMain.btSynthMemoryClick(Sender: TObject);
var
  curl : ICurl;
begin
  // cURL
  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm(CurlGetForm.Add(
                  CurlGetField
                      .Name('photo')
                      .FileBuffer(
                          'synth_buffer.png', pngStream.Size, pngStream.Memory^)
                      .ContentType('image/png')))
      .Perform;
  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

procedure TfmMain.btSynthStreamClick(Sender: TObject);
var
  curl : ICurl;
begin
  // Seek the stream to beginning again
  pngStream.Position := 0;

  // cURL
  curl := CurlGet;
  curl.SwitchRecvToString
      .SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      .SetForm( CurlGetForm.Add(
                  CurlGetField
                      .Name('photo')
                      .FileStream(pngStream, [csfAutoRewind])
                      .ContentType('image/png')
                      .FileName('synth_stream.png')))
      .Perform;
  memoResponse.Text := UTF8ToString(curl.ResponseBody);
end;

end.

