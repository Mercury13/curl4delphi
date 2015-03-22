unit Curl.Form;

interface

uses
  // System
  System.Classes,
  // cURL
  Curl.Lib;

type
  ICurlForm = interface
    procedure Add(aName, aValue : RawByteString);  overload;
    procedure Add(aName, aValue : string);  overload;
    ///  @warning
    ///  This is a rawmost version of Add. Please have CURLFORM_END
    ///     in the end.
    procedure Add(aArray : array of TCurlPostOption);  overload;

    function DoesUseStreams : boolean;
    function RawValue : PCurlHttpPost;
  end;

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

    function DoesUseStreams : boolean;
    function RawValue : PCurlHttpPost;
  end;

function GetCurlForm : ICurlForm;

implementation

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

function TCurlForm.DoesUseStreams : boolean;
begin
  Result := false;
end;

function TCurlForm.RawValue : PCurlHttpPost;
begin
  Result := fStart;
end;

function GetCurlForm : ICurlForm;
begin
  Result := TCurlForm.Create;
end;

end.
