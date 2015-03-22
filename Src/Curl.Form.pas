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
  public
    constructor Create;
    destructor Destroy;  override;

    procedure Add(aName, aValue : PAnsiChar);  overload;
    procedure Add(aName, aValue : RawByteString);  overload;  inline;
    procedure Add(aName, aValue : string);  overload;
    procedure Add(aField : ICurlField);  overload;
    procedure Add(aArray : array of TCurlPostOption);  overload;

    function RawValue : PCurlHttpPost;
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
end;


procedure TCurlForm.Add(aName, aValue : PAnsiChar);
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, aName,
          CURLFORM_COPYCONTENTS, aValue,
          CURLFORM_END);
end;

procedure TCurlForm.Add(aName, aValue : RawByteString);
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_COPYNAME, PAnsiChar(aName),
          CURLFORM_NAMELENGTH, PAnsiChar(length(aName)),
          CURLFORM_COPYCONTENTS, PAnsiChar(aValue),
          CURLFORM_CONTENTSLENGTH, PAnsiChar(length(aValue)),
          CURLFORM_END);
end;

procedure TCurlForm.Add(aName, aValue : string);
begin
  Add(UTF8Encode(aName), UTF8Encode(aValue));
end;

procedure TCurlForm.Add(aArray : array of TCurlPostOption);
begin
  curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(@aArray[0]),
          CURLFORM_END);
end;

procedure TCurlForm.Add(aField : ICurlField);
begin
  Store(aField.Storage);
  curl_formadd(fStart, fEnd,
          CURLFORM_ARRAY, PAnsiChar(aField.Build),
          CURLFORM_END);
end;

function TCurlForm.RawValue : PCurlHttpPost;
begin
  Result := fStart;
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

    function Name(x : RawByteString) : ICurlField;
    function PtrName(x : RawByteString) : ICurlField;

    function ContentRaw(x : RawByteString) : ICurlField;  overload;
    function Content(x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(x : string) : ICurlField;

    function UploadFile(x : string) : ICurlField;
    function ContentType(x : RawByteString) : ICurlField;

    // Custom file uploading
    function FileName(x : RawByteString) : ICurlField;
    function FileBuffer(x : RawByteString) : ICurlField;  overload;
    function FileBuffer(length : integer; const data) : ICurlField;  overload;
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
  Reserve(1);
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

function TCurlField.Name(x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_COPYNAME, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.PtrName(x : RawByteString) : ICurlField;
begin
  Add(CURLFORM_PTRNAME, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.ContentRaw(x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(Length(x)));
  Add(CURLFORM_COPYCONTENTS, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.Content(x : string) : ICurlField;
begin
  Result := ContentRaw(UTF8Encode(x));
end;

function TCurlField.Content(length : integer; const data) : ICurlField;
begin
  Add(CURLFORM_CONTENTSLENGTH, PAnsiChar(length));
  Add(CURLFORM_COPYCONTENTS, PAnsiChar(@data));
  Result := Self;
end;

function TCurlField.PtrContent(x : RawByteString) : ICurlField;
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

function TCurlField.FileContent(x : string) : ICurlField;
var
  utf : RawByteString;
begin
  utf := UTF8Encode(x);
  Store(utf);
  Add(CURLFORM_FILECONTENT, PAnsiChar(utf));
  Result := Self;
end;

function TCurlField.UploadFile(x : string) : ICurlField;
var
  utf : RawByteString;
begin
  utf := UTF8Encode(x);
  Store(utf);
  Add(CURLFORM_FILE, PAnsiChar(utf));
  Result := Self;
end;

function TCurlField.FileName(x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_FILENAME, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.FileBuffer(x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_BUFFER, PAnsiChar(Length(x)));
  Add(CURLFORM_BUFFERPTR, PAnsiChar(x));
  Result := Self;
end;

function TCurlField.FileBuffer(length : integer; const data) : ICurlField;
begin
  Add(CURLFORM_BUFFER, PAnsiChar(length));
  Add(CURLFORM_BUFFERPTR, PAnsiChar(@data));
  Result := Self;
end;

function TCurlField.FileStream(x : TStream) : ICurlField;
begin
  raise ENotSupportedException.Create('[TCurlField.FileStream] Not implemented');
  Result := Self;
end;

function TCurlField.CustomHeaders(x : ICurlSlist) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTHEADER, PAnsiChar(x.RawValue));
  Result := Self;
end;

function TCurlField.ContentType(x : RawByteString) : ICurlField;
begin
  Store(x);
  Add(CURLFORM_CONTENTTYPE, PAnsiChar(Length(x)));
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
