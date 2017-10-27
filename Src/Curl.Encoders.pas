unit Curl.Encoders;

interface

uses
  Curl.Interfaces;

type
  TCurlChars = set of AnsiChar;

  ICurlGetBuilder = interface (ICurlStringBuilder)
    ['{1952FC73-9D2B-4AF4-93E7-1D3BFADE7353}']
    function Param(aName, aValue : RawByteString) : ICurlGetBuilder;  overload;
    function Param(aName : RawByteString; aValue : string) : ICurlGetBuilder;  overload;
  end;

function CurlUrlEncodeCustom(
        const s : RawByteString;
        const aAllowedChars : TCurlChars) : RawByteString;  overload;
function CurlUrlEncodeCustom(
        const s : UnicodeString;
        const aAllowedChars : TCurlChars) : RawByteString;  overload;

///  Does “full” URL encoding.
///  All characters that have special meaning in URLs are %-encoded
function CurlUrlEncodeFull(const s : RawByteString) : RawByteString;  overload;
function CurlUrlEncodeFull(const s : UnicodeString) : RawByteString;  overload;

///  Does “light” URL encoding for GET parameters.
function CurlUrlEncodeParam(const s : RawByteString) : RawByteString;  overload;
function CurlUrlEncodeParam(const s : UnicodeString) : RawByteString;  overload;

///  Returns an ICurlGetBuilder that builds a GET URL.
function CurlGetBuilder(const aUrl : RawByteString) : ICurlGetBuilder;  overload;
function CurlGetBuilder(const aUrl : UnicodeString) : ICurlGetBuilder;  overload;

const
  CurlFullChars = [ '0'..'9', 'A'..'Z', 'a'..'z', '-', '_', '.', '~' ];
  CurlParamChars = CurlFullChars +
              [ '!', '*', '(', ')', '@', '$', ',', '/', '[', ']' ];

implementation

function CurlUrlEncodeCustom(
        const s : RawByteString;
        const aAllowedChars : TCurlChars) : RawByteString;
const
  hexDigits : array [0..15] of AnsiChar = '0123456789ABCDEF';
var
  i, n, n1 : integer;
  c : AnsiChar;
begin
  n := length(s);
  n1 := n;
  for i := 1 to length(s) do begin
    c := s[i];
    if not (c in aAllowedChars)
      then Inc(n1, 2);
  end;
  if n1 = n
    then Exit(s);

  // Start encoding
  SetLength(Result, n1);
  n1 := 1;

  for i := 1 to n do begin
    c := s[i];
    if c in aAllowedChars then begin
      Result[n1] := c;
      Inc(n1);
    end else begin
      Result[n1] := '%';
      Result[n1 + 1] := hexDigits[ord(c) shr 4];
      Result[n1 + 2] := hexDigits[ord(c) and $0F];
      Inc(n1, 3);
    end;
  end;
end;


function CurlUrlEncodeCustom(
        const s : UnicodeString;
        const aAllowedChars : TCurlChars) : RawByteString;
begin
  Result := CurlUrlEncodeCustom(UTF8Encode(s), aAllowedChars);
end;


function CurlUrlEncodeFull(const s : RawByteString) : RawByteString;
begin
  Result := CurlUrlEncodeCustom(s, CurlFullChars);
end;

function CurlUrlEncodeFull(const s : UnicodeString) : RawByteString;
begin
  Result := CurlUrlEncodeCustom(s, CurlFullChars);
end;


function CurlUrlEncodeParam(const s : RawByteString) : RawByteString;
begin
  Result := CurlUrlEncodeCustom(s, CurlParamChars);
end;


function CurlUrlEncodeParam(const s : UnicodeString) : RawByteString;  overload;
begin
  Result := CurlUrlEncodeCustom(s, CurlParamChars);
end;

///// TCurlGetBuilder //////////////////////////////////////////////////////////


type
  TCurlGetBuilder = class (TInterfacedObject, ICurlGetBuilder)
  private
    fUrl : RawByteString;
    fHasParam : boolean;
  public
    constructor Create(aUrl : RawByteString);
    function Build : RawByteString;
    function Param(aName, aValue : RawByteString) : ICurlGetBuilder;  overload;
    function Param(aName : RawByteString; aValue : string) : ICurlGetBuilder;  overload;
  end;


constructor TCurlGetBuilder.Create(aUrl : RawByteString);
const
  Question : RawByteString = '?';
begin
  inherited Create;
  fUrl := aUrl;
  fHasParam := (Pos(Question, aUrl) <> 0);
end;


function TCurlGetBuilder.Build : RawByteString;
begin
  Result := fUrl;
end;

function TCurlGetBuilder.Param(aName, aValue : RawByteString) : ICurlGetBuilder;
var
  c : AnsiChar;
begin
  if fHasParam
    then c := '&'
    else c := '?';
  fUrl := fUrl + (c + CurlUrlEncodeParam(aName) + '=' + CurlUrlEncodeParam(aValue));
  fHasParam := true;
  Result := Self;
end;

function TCurlGetBuilder.Param(aName : RawByteString; aValue : string) : ICurlGetBuilder;
begin
  Result := Param(aName, UTF8Encode(aValue));
end;

function CurlGetBuilder(const aUrl : RawByteString) : ICurlGetBuilder;
begin
  Result := TCurlGetBuilder.Create(aUrl);
end;

function CurlGetBuilder(const aUrl : UnicodeString) : ICurlGetBuilder;
begin
  Result := CurlGetBuilder(UTF8Encode(aUrl));
end;

end.
