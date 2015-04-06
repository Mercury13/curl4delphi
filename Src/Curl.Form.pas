unit Curl.Form;

interface

uses
  // System
  System.Classes,
  // cURL
  Curl.Lib, Curl.Interfaces;

type
  ICurlField = interface (ICurlCustomField)
    function Name(const x : RawByteString) : ICurlField;

    function ContentRaw(const x : RawByteString) : ICurlField;
    function Content(const x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    ///  Sets content from a RawByteString.
    ///  @warning  This RawByteString should live until Perform ends.
    function PtrContent(const x : RawByteString) : ICurlField;  overload;
    ///  Sets content from a memory buffer.
    ///  @warning  This buffer should live until Perform ends.
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    // Unused right now: FORM_FILECONTENT is not Unicode-aware
    //function FileContent(const x : string) : ICurlField;

    ///  @warning
    ///  When you do UploadFile, you SHOULD use Delphi streams for all
    ///     other reading operations of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function UploadFile(const aFname : string) : ICurlField;

    function ContentType(const aFname : RawByteString) : ICurlField;

    // Sets a file name
    function FileName(const x : RawByteString) : ICurlField;
    // Sets file data, either as RawByteString or as data buffer
    function FileBuffer(
            const aFname, aData : RawByteString) : ICurlField;  overload;
    function FileBuffer(
            const aFname : RawByteString;
            length : integer; const data) : ICurlField;  overload;
    ///  @warning
    ///  When you assign FileStream, you SHOULD use Delphi streams for all
    ///     other reading operations of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function FileStream(x : TStream; aFlags : TCurlStreamFlags) : ICurlField;

    function CustomHeaders(x : ICurlCustomSList) : ICurlField;
  end;

  ICurlForm = interface (ICurlCustomForm)
    ///  This is the simplest version of Add; use it if you want something
    ///  like name=value.
    function Add(aName, aValue : RawByteString) : ICurlForm;  overload;
    function Add(aName, aValue : string) : ICurlForm;  overload;
    ///  This is a rawmost version of Add.
    ///  @warning  Please have CURLFORM_END in the end.
    ///  @warning  Some options of Windows cURL request disk file name
    ///         in a single-byte encoding.
    function Add(aArray : array of TCurlPostOption) : ICurlForm;  overload;
    ///  Adds a field using a special array-builder.
    function Add(aField : ICurlCustomField) : ICurlForm;  overload;

    ///  Adds a single disk file for uploading.
    ///  @warning  Because of cURL bug, it uses a stream internally.
    ///     You SHOULD use Delphi streams for all other reading operations
    ///     of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function AddFile(
              aFieldName : RawByteString;
              aFileName : string;
              aContentType : RawByteString) : ICurlForm;  overload;
  end;

function CurlGetForm : ICurlForm;
function CurlGetField : ICurlField;

implementation

uses
  // System
  System.SysUtils, System.Generics.Collections,
  // Curl
  Curl.Easy;

///// TCurlStreamStorage ///////////////////////////////////////////////////////

///
///  An object that stores one or several ref-counted objects.
///
type
  TCurlStreamStorage = class (TInterfacedObject, IRewindable)
  protected
    fStreams : TList<TCurlAutoStream>;
    fDoesUseStream : boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Store(aStream : TStream; aFlags : TCurlStreamFlags);
    procedure RewindStreams;  virtual;
    procedure CloseStreams;   virtual;
    function ReadFunction : EvCurlRead;
  end;

constructor TCurlStreamStorage.Create;
begin
  inherited;
  fStreams := nil;
  fDoesUseStream := false;
end;

destructor TCurlStreamStorage.Destroy;
begin
  CloseStreams;
  inherited;
end;

procedure TCurlStreamStorage.Store(
        aStream : TStream; aFlags : TCurlStreamFlags);
var
  q : TCurlAutoStream;
begin
  fDoesUseStream := true;
  if aFlags <> [] then begin
    q.Stream := aStream;
    q.Flags := aFlags;
    if fStreams = nil
      then fStreams := TList<TCurlAutoStream>.Create;
    fStreams.Add(q);
  end;
end;

procedure TCurlStreamStorage.RewindStreams;
var
  q : TCurlAutoStream;
begin
  if fStreams <> nil then
    for q in fStreams do
      q.RewindRead;
end;

procedure TCurlStreamStorage.CloseStreams;
var
  q : TCurlAutoStream;
begin
  if fStreams <> nil then begin
    for q in fStreams do
      q.Destroy;
    FreeAndNil(fStreams);
  end;
end;

function TCurlStreamStorage.ReadFunction : EvCurlRead;
begin
  if fDoesUseStream
    then Result := @CurlStreamRead
    else Result := nil;
end;


///// TCurlStorage /////////////////////////////////////////////////////////////

type
  TCurlStorage<Intf : IInterface> = class (TCurlStreamStorage)
  protected
    fStorage : TList<Intf>;
    procedure Store(x : Intf);  overload;
  public
    constructor Create;
    destructor Destroy; override;
  end;

constructor TCurlStorage<Intf>.Create;
begin
  inherited;
  fStorage := nil;
end;

destructor TCurlStorage<Intf>.Destroy;
begin
  fStorage.Free;
  inherited;
end;

procedure TCurlStorage<Intf>.Store(x : Intf);
begin
  if x <> nil then begin
    if fStorage = nil
      then fStorage := TList<Intf>.Create;
    fStorage.Add(x);
  end;
end;

///// TCurlForm ////////////////////////////////////////////////////////////////

type
  TCurlForm = class (TCurlStorage<ICurlCustomField>, ICurlForm)
  private
    fStart, fEnd : PCurlHttpPost;
    class procedure RaiseIf(v : TCurlFormCode);  static;
  public
    constructor Create;
    destructor Destroy;  override;

    function Add(aName, aValue : PAnsiChar) : ICurlForm;  overload;
    function Add(aName, aValue : RawByteString) : ICurlForm;  overload;  inline;
    function Add(aName, aValue : string) : ICurlForm;  overload;
    function Add(aField : ICurlCustomField) : ICurlForm;  overload;
    function Add(aArray : array of TCurlPostOption) : ICurlForm;  overload;

    function AddFile(
              aFieldName : RawByteString;
              aFileName : string;
              aContentType : RawByteString) : ICurlForm;

    function RawValue : PCurlHttpPost;
    procedure RewindStreams;  override;
    procedure CloseStreams;  override;
  end;

constructor TCurlForm.Create;
begin
  inherited;
  fStart := nil;
  fEnd := nil;
end;


destructor TCurlForm.Destroy;
begin
  curl_formfree(fStart);
  fStreams.Free;
end;


class procedure TCurlForm.RaiseIf(v : TCurlFormCode);
const
  OptionNames : array [TCurlFormCode] of string = (
      '',                               // CURL_FORMADD_OK,
      'Not enough memory',              // CURL_FORMADD_MEMORY,
      'An option os mentioned twice',   // CURL_FORMADD_OPTION_TWICE,
      'Nil as an option',               // CURL_FORMADD_NULL,
      'Unknown option',                 // CURL_FORMADD_UNKNOWN_OPTION,
      'Incomplete option set',          // CURL_FORMADD_INCOMPLETE,
      'Illegal array',                  // CURL_FORMADD_ILLEGAL_ARRAY,
      'cURL is built w/o this feature'  // CURL_FORMADD_DISABLED
  );
begin
  if v = CURL_FORMADD_OK then Exit;
  raise ECurlInternal.Create(OptionNames[v]);
end;


function TCurlForm.Add(aName, aValue : PAnsiChar) : ICurlForm;
begin
  RaiseIf(curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, aName,
          CURLFORM_COPYCONTENTS, aValue,
          CURLFORM_END));
  Result := Self;
end;

function TCurlForm.Add(aName, aValue : RawByteString) : ICurlForm;
begin
  RaiseIf(curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, PAnsiChar(aName),
          CURLFORM_NAMELENGTH, PAnsiChar(length(aName)),
          CURLFORM_COPYCONTENTS, PAnsiChar(aValue),
          CURLFORM_CONTENTSLENGTH, PAnsiChar(length(aValue)),
          CURLFORM_END));
  Result := Self;
end;

function TCurlForm.Add(aName, aValue : string) : ICurlForm;
begin
  Result := Add(UTF8Encode(aName), UTF8Encode(aValue));
end;

function TCurlForm.Add(aArray : array of TCurlPostOption) : ICurlForm;
begin
  RaiseIf(curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(@aArray[0]),
          CURLFORM_END));
  Result := Self;
end;

function TCurlForm.Add(aField : ICurlCustomField) : ICurlForm;
begin
  if aField.DoesStore
    then Store(aField);
  RaiseIf(curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(aField.Build),
          CURLFORM_END));
  if aField.DoesUseStream
    then fDoesUseStream := true;

  Result := Self;
end;

function TCurlForm.AddFile(
          aFieldName : RawByteString;
          aFileName : string;
          aContentType : RawByteString) : ICurlForm;
var
  stream : TFileStream;
begin
// Used to be…
//  u8 := UTF8Encode(aFileName);
//  curl_formadd(fStart, fEnd,
//          CURLFORM_COPYNAME, PAnsiChar(aFieldName),
//          CURLFORM_NAMELENGTH, PAnsiChar(length(aFieldName)),
//          CURLFORM_FILE, PAnsiChar(u8),
//          CURLFORM_CONTENTTYPE, PAnsiChar(aContentType),
//          CURLFORM_END);
  // CURLFORM_FILE is not Unicode-enabled, so we’ll do this thingy.
  stream := TFileStream.Create(aFileName, fmOpenRead + fmShareDenyWrite);
  RaiseIf(curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, PAnsiChar(aFieldName),
          CURLFORM_NAMELENGTH, PAnsiChar(length(aFieldName)),
          CURLFORM_FILENAME, PAnsiChar(UTF8Encode(ExtractFileName(aFileName))),
          CURLFORM_STREAM, PAnsiChar(stream),
          CURLFORM_CONTENTSLENGTH, PAnsiChar(stream.Size),
          CURLFORM_CONTENTTYPE, PAnsiChar(aContentType),
          CURLFORM_END));
  Store(stream, [csfAutoRewind, csfAutoDestroy]);
  fDoesUseStream := true;
  Result := Self;
end;

function TCurlForm.RawValue : PCurlHttpPost;
begin
  Result := fStart;
end;

procedure TCurlForm.RewindStreams;
var
  fld : ICurlCustomField;
begin
  inherited;
  if fStorage <> nil then
    for fld in fStorage do
      fld.RewindStreams;
end;

procedure TCurlForm.CloseStreams;
var
  fld : ICurlCustomField;
begin
  inherited;
  if fStorage <> nil then
    for fld in fStorage do
      fld.CloseStreams;
end;


///// TCurlField ///////////////////////////////////////////////////////////////

const
  ZeroField : PAnsiChar = #0;

function ToPtr(length : integer; const data) : PAnsiChar;
begin
  if length = 0
    then Result := ZeroField
    else Result := PAnsiChar(@data);
end;

type
  TCurlField = class (TCurlStorage<IInterface>, ICurlField)
  private
    fData : array of TCurlForms;
    fSize : integer;

    fStrings : TList<RawByteString>;
    fIsLocked : boolean;

    procedure Store(x : RawByteString);  overload;
    procedure Add(aOption : TCurlFormOption; aValue : PAnsiChar);
    function Capacity : integer;  inline;
    procedure Reserve(x : integer);  inline;
  public
    constructor Create;
    destructor Destroy;  override;

    function Name(const x : RawByteString) : ICurlField;

    function ContentRaw(const x : RawByteString) : ICurlField;  overload;
    function Content(const x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(const x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    //function FileContent(const x : string) : ICurlField;

    function UploadFile(const aFname : string) : ICurlField;
    function ContentType(const x : RawByteString) : ICurlField;

    // Custom file uploading
    function FileName(const x : RawByteString) : ICurlField;
    function FileBuffer(
            const aFname, aData : RawByteString) : ICurlField;  overload;
    function FileBuffer(
            const aFname : RawByteString;
            length : integer; const data) : ICurlField;  overload;
    function FileStream(x : TStream; aFlags : TCurlStreamFlags) : ICurlField;

    function CustomHeaders(x : ICurlCustomSList) : ICurlField;

    function DoesUseStream : boolean;
    function DoesStore : boolean;

    function Build : PCurlForms;
  end;

constructor TCurlField.Create;
begin
  inherited;
  fStrings := TList<RawByteString>.Create;
  fSize := 0;
  Reserve(10);
end;


destructor TCurlField.Destroy;
begin
  fStrings.Free;
  inherited;
end;

function TCurlField.Capacity : integer;
begin
  Result := Length(fData);
end;


procedure TCurlField.Reserve(x : integer);
begin
  SetLength(fData, x);
end;

procedure TCurlField.Add(aOption : TCurlFormOption; aValue : PAnsiChar);
begin
  if fIsLocked then
    raise ECurlInternal.Create(
          '[TCurlField.Add] Cannot add to locked field, create another!');
  if fSize >= Capacity
    then Reserve(Capacity * 2);
  with fData[fSize] do begin
    Option := aOption;
    Value := aValue;
  end;
  Inc(fSize);
end;

procedure TCurlField.Store(x : RawByteString);
begin
  fStrings.Add(x);
end;

function TCurlField.Name(const x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_COPYNAME, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.ContentRaw(const x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(Length(x)));
  Add(CURLFORM_COPYCONTENTS, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.Content(const x : string) : ICurlField;
begin
  Result := ContentRaw(UTF8Encode(x));
end;

function TCurlField.Content(length : integer; const data) : ICurlField;
begin
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(length));
  Add(CURLFORM_COPYCONTENTS, PAnsiChar(@data));
  Result := Self;
end;

function TCurlField.PtrContent(const x : RawByteString) : ICurlField;
begin
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(length(x)));
  Add(CURLFORM_PTRCONTENTS, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.PtrContent(length : integer; const data) : ICurlField;
begin
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(length));
  Add(CURLFORM_PTRCONTENTS, ToPtr(length, data));
  Result := Self;
end;

//function TCurlField.FileContent(const x : string) : ICurlField;
//var
//  utf : RawByteString;
//begin
//  /// @todo [bug] FileContent is not Unicode-enabled
//  utf := UTF8Encode(x);
//  Store(utf);
//  Add(CURLFORM_FILECONTENT, PAnsiChar(utf));
//  Result := Self;
//end;

function TCurlField.UploadFile(const aFname : string) : ICurlField;
var
  utf : RawByteString;
  stream : TStream;
begin
  utf := UTF8Encode(aFname);
  Store(utf);

  stream := TFileStream.Create(aFname, fmOpenRead + fmShareDenyWrite);
  Store(stream, [csfAutoRewind, csfAutoDestroy]);

  Add(CURLFORM_FILENAME, PAnsiChar(utf));
  Add(CURLFORM_STREAM, PAnsiChar(stream));
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(stream.Size));

  Result := Self;
end;

function TCurlField.FileName(const x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_FILENAME, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.FileBuffer(const aFname, aData : RawByteString) : ICurlField;
begin
  Store(aFname);
  Store(aData);
  Add(CURLFORM_BUFFER, PAnsiChar(aFname));
  Add(CURLFORM_BUFFERPTR, PAnsiChar(aData));
  Add(CURLFORM_BUFFERLENGTH, PAnsiChar(Length(aData)));
  Result := Self;
end;

function TCurlField.FileBuffer(
        const aFname : RawByteString;
        length : integer; const data) : ICurlField;
begin
  Store(aFname);
  Add(CURLFORM_BUFFER, PAnsiChar(aFname));
  Add(CURLFORM_BUFFERPTR, PAnsiChar(@data));
  Add(CURLFORM_BUFFERLENGTH, PAnsiChar(length));
  Result := Self;
end;

function TCurlField.FileStream(x : TStream; aFlags : TCurlStreamFlags) : ICurlField;
begin
  Store(x, aFlags);
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(x.Size));
  Add(CURLFORM_STREAM, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.CustomHeaders(x : ICurlCustomSList) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTHEADER, PAnsiChar(x.RawValue));
  Result := Self;
end;

function TCurlField.ContentType(const x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTTYPE, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.Build : PCurlForms;
begin
  if not fIsLocked then begin
    Add(CURLFORM_END, nil);
    fIsLocked := true;
  end;
  Result := @fData[0];
end;

function TCurlField.DoesUseStream : boolean;
begin
  Result := fDoesUseStream;
end;

function TCurlField.DoesStore : boolean;
begin
  Result := (fStreams <> nil) or (fStorage <> nil);
end;

///// Misc. functions //////////////////////////////////////////////////////////

function CurlGetForm : ICurlForm;
begin
  Result := TCurlForm.Create;
end;

function CurlGetField : ICurlField;
begin
  Result := TCurlField.Create;
end;

end.
