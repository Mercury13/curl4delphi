unit Curl.Form;

interface

uses
  // cURL
  Curl.Lib, Curl.Interfaces;

function CurlGetForm : ICurlForm;
function CurlGetField : ICurlField;

implementation

uses
  // System
  System.Classes,
  System.Generics.Collections,
  // Curl
  Curl.Easy;

///// TCurlStorage /////////////////////////////////////////////////////////////


///
///  An object that stores one or several ref-counted objects.
///
type
  TCurlStorage = class (TInterfacedObject)
  private
    fSingleStorage : IInterface;
    fMultiStorage : IInterfaceList;
  protected
    procedure Store(x : IInterface);
  public
    function Storage : IInterface;
  end;

procedure TCurlStorage.Store(x : IInterface);
begin
  if x = nil
    then Exit;

  // Store only one object?
  if fSingleStorage = nil then begin
    fSingleStorage := x;
    Exit;
  end;

  // Otherwise convert single storage to multi-storage
  if fMultiStorage = nil then begin
    fMultiStorage := TInterfaceList.Create;
    fMultiStorage.Add(fSingleStorage);
    fSingleStorage := nil;
  end;

  fMultiStorage.Add(x);
end;

function TCurlStorage.Storage : IInterface;
begin
  if fSingleStorage <> nil
    then Result := fSingleStorage
    else Result := fMultiStorage;
end;

///// TCurlForm ////////////////////////////////////////////////////////////////

type
  TCurlForm = class (TCurlStorage, ICurlForm)
  private
    fStart, fEnd : PCurlHttpPost;
    fDoesUseStream : boolean;
  public
    constructor Create;
    destructor Destroy;  override;

    function Add(aName, aValue : PAnsiChar) : ICurlForm;  overload;
    function Add(aName, aValue : RawByteString) : ICurlForm;  overload;  inline;
    function Add(aName, aValue : string) : ICurlForm;  overload;
    function Add(aField : ICurlField) : ICurlForm;  overload;
    function Add(aArray : array of TCurlPostOption) : ICurlForm;  overload;

    function AddDiskFile(
              aFieldName : RawByteString;
              aFileName : string;
              aContentType : RawByteString) : ICurlForm;

    function RawValue : PCurlHttpPost;
    function DoesUseStream : boolean;
  end;

constructor TCurlForm.Create;
begin
  inherited;
  fStart := nil;
  fEnd := nil;
  fDoesUseStream := false;
end;


destructor TCurlForm.Destroy;
begin
  curl_formfree(fStart);
end;


function TCurlForm.Add(aName, aValue : PAnsiChar) : ICurlForm;
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, aName,
          CURLFORM_COPYCONTENTS, aValue,
          CURLFORM_END);
  Result := Self;
end;

function TCurlForm.Add(aName, aValue : RawByteString) : ICurlForm;
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, PAnsiChar(aName),
          CURLFORM_NAMELENGTH, PAnsiChar(length(aName)),
          CURLFORM_COPYCONTENTS, PAnsiChar(aValue),
          CURLFORM_CONTENTSLENGTH, PAnsiChar(length(aValue)),
          CURLFORM_END);
  Result := Self;
end;

function TCurlForm.Add(aName, aValue : string) : ICurlForm;
begin
  Result := Add(UTF8Encode(aName), UTF8Encode(aValue));
end;

function TCurlForm.Add(aArray : array of TCurlPostOption) : ICurlForm;
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(@aArray[0]),
          CURLFORM_END);
  Result := Self;
end;

function TCurlForm.Add(aField : ICurlField) : ICurlForm;
begin
  Store(aField.Storage);
  curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(aField.Build),
          CURLFORM_END);
  if aField.DoesUseStream
    then fDoesUseStream := true;

  Result := Self;
end;

function TCurlForm.AddDiskFile(
          aFieldName : RawByteString;
          aFileName : string;
          aContentType : RawByteString) : ICurlForm;
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, PAnsiChar(aFieldName),
          CURLFORM_NAMELENGTH, PAnsiChar(length(aFieldName)),
          CURLFORM_FILE, PAnsiChar(UTF8Encode(aFileName)),
          CURLFORM_CONTENTTYPE, PAnsiChar(aContentType),
          CURLFORM_END);
  Result := Self;
end;

function TCurlForm.RawValue : PCurlHttpPost;
begin
  Result := fStart;
end;

function TCurlForm.DoesUseStream : boolean;
begin
  Result := fDoesUseStream;
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
  TCurlField = class (TCurlStorage, ICurlField)
  private
    fData : array of TCurlForms;
    fSize : integer;

    fStrings : TList<RawByteString>;
    fIsLocked : boolean;
    fDoesUseStream : boolean;

    procedure Store(x : RawByteString);  overload;
    procedure Add(aOption : TCurlFormOption; aValue : PAnsiChar);
    function Capacity : integer;  inline;
    procedure Reserve(x : integer);  inline;
  public
    constructor Create;
    destructor Destroy;  override;

    function Name(const x : RawByteString) : ICurlField;
    function PtrName(const x : RawByteString) : ICurlField;

    function ContentRaw(const x : RawByteString) : ICurlField;  overload;
    function Content(const x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(const x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(const x : string) : ICurlField;

    function UploadFile(const aFname : string) : ICurlField;
    function ContentType(const x : RawByteString) : ICurlField;

    // Custom file uploading
    function FileName(const x : RawByteString) : ICurlField;
    function FileBuffer(
            const aFname, aData : RawByteString) : ICurlField;  overload;
    function FileBuffer(
            const aFname : RawByteString;
            length : integer; const data) : ICurlField;  overload;
    function FileStream(x : TStream) : ICurlField;

    function CustomHeaders(x : ICurlSlist) : ICurlField;

    function DoesUseStream : boolean;

    function Build : PCurlHttpPost;
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

function TCurlField.PtrName(const x : RawByteString) : ICurlField;
begin
  Add(CURLFORM_PTRNAME, PAnsiChar(x));
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

function TCurlField.FileContent(const x : string) : ICurlField;
var
  utf : RawByteString;
begin
  utf := UTF8Encode(x);
  Store(utf);
  Add(CURLFORM_FILECONTENT, PAnsiChar(utf));
  Result := Self;
end;

function TCurlField.UploadFile(const aFname : string) : ICurlField;
var
  utf : RawByteString;
begin
  utf := UTF8Encode(aFname);
  Store(utf);
  Add(CURLFORM_FILE, PAnsiChar(utf));
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

function TCurlField.FileStream(x : TStream) : ICurlField;
begin
  fDoesUseStream := true;
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(x.Size));
  Add(CURLFORM_STREAM, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.CustomHeaders(x : ICurlSlist) : ICurlField;
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

function TCurlField.Build : PCurlHttpPost;
begin
  Add(CURLFORM_END, nil);
  fIsLocked := true;
  Result := @fData[0];
end;

function TCurlField.DoesUseStream : boolean;
begin
  Result := fDoesUseStream;
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
