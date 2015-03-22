unit Curl.Form;

interface

uses
  // cURL
  Curl.Lib, Curl.Interfaces;

function CurlGetForm : ICurlForm;
//function CurlGetField : ICurlField;

implementation

uses
  // System
  System.Classes;

///// TCurlForm ////////////////////////////////////////////////////////////////

type
  TCurlForm = class (TInterfacedObject, ICurlForm)
  private
    fStart, fEnd : PCurlHttpPost;
  public
    constructor Create;
    destructor Destroy;  override;

    procedure Add(aName, aValue : PAnsiChar);  overload;
    procedure Add(aName, aValue : RawByteString);  overload;  inline;
    procedure Add(aName, aValue : string);  overload;
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

///// Misc. functions //////////////////////////////////////////////////////////

function CurlGetForm : ICurlForm;
begin
  Result := TCurlForm.Create;
end;

end.
