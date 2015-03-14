unit Curl.Easy;

interface

uses
  // System
  System.Classes, System.SysUtils,
  // cUrl
  Curl.Lib;

type
  IEasyCurl = interface
    function GetHandle : TCurlHandle;
    property Handle : TCurlHandle read GetHandle;

    ///  Sets a cURL option.
    ///  SetXXX functions are simply wrappers for SetOpt.
    procedure SetOpt(aOption : TCurlOffOption; aData : TCurlOff);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : PAnsiChar);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : pointer);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : NativeUInt);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : boolean);  overload;

    ///  Sets a URL. Equivalent to SetOpt(CURLOPT_URL, aData).
    procedure SetUrl(aData : PAnsiChar);  overload;
    procedure SetUrl(aData : RawByteString);  overload;
    procedure SetUrl(aData : UnicodeString);  overload;

    ///  Sets a CA file for SSL
    procedure SetCaFile(aData : PAnsiChar);      overload;
    procedure SetCaFile(aData : RawByteString);  overload;
    procedure SetCaFile(aData : UnicodeString);  overload;

    ///  Sets an SSL version
    procedure SetSslVersion(aData : TCurlSslVersion);

    ///  Sets a receiver stream. Equivalent to twin SetOpt,
    ///  WRITE_FUNCTION and WRITE_DATA.
    ///  Does not destroy the stream, you should dispose of it manually!
    ///  If aData = nil: removes all custom receivers.
    procedure SetRecvStream(aData : TStream);

    ///  Sets a sender stream. Equivalent to twin SetOpt,
    ///  READ_FUNCTION and READ_DATA.
    ///  Does not destroy the stream, you should dispose of it manually!
    ///  If aData = nil: removes all custom senders.
    procedure SetSendStream(aData : TStream);

    ///  Sets whether cURL will follow redirections.
    procedure SetFollowLocation(aData : boolean);

    ///  Removes custom HTTP headers
    procedure RemoveCustomHeaders;

    ///  Sets custom HTTP headers
    procedure SetCustomHeaders(const x : array of RawByteString);

    ///  Performs the action.
    ///  Actually does RaiseIf(PerformNe).
    procedure Perform;

    ///  Performs the action w/o throwing an error.
    ///  The user should process error codes for himself.
    function PerformNe : TCurlCode;

    ///  Does nothing if aCode is OK; otherwise localizes the error message
    ///  and throws an exception.
    ///  Sometimes you’d like to process some errors in place w/o bulky
    ///  try/except. Then you run PerformNe, manually process some errors,
    ///  and do RaiseIf for everything else.
    procedure RaiseIf(aCode : TCurlCode);

    ///  Returns some information.
    ///  GetXXX functions are wrappers for GetInfo.
    function GetInfo(aCode : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;

    ///  Returns response code. Equivalent to GetInfo(CURLINFO_RESPONSE_CODE).
    function GetResponseCode : longint;

    function Clone : IEasyCurl;
  end;

  ECurl = class (Exception) end;

  ECurlInternal = class (Exception) end;

  TEasyCurlImpl = class (TInterfacedObject, IEasyCurl)
  private
    type
      TSListEntry = record
        str : RawByteString;
        entry : TCurlSList;
      end;
      OaSListEntry = array of TSListEntry;
  private
    fHandle : TCurlHandle;
    fCustomHeaders : OaSListEntry;
    class procedure LinkList(var x : OaSListEntry);  static;
  public
    constructor Create;  overload;
    constructor Create(aSource : TEasyCurlImpl);  overload;
    destructor Destroy;  override;
    function GetHandle : TCurlHandle;

    procedure RaiseIf(aCode : TCurlCode);  inline;

    procedure SetOpt(aOption : TCurlOffOption; aData : TCurlOff);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : PAnsiChar);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : pointer);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : NativeUInt);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : boolean);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : RawByteString);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : UnicodeString);  overload;

    procedure SetUrl(aData : PAnsiChar);      overload;   inline;
    procedure SetUrl(aData : RawByteString);  overload;   inline;
    procedure SetUrl(aData : UnicodeString);  overload;   inline;

    procedure SetCaFile(aData : PAnsiChar);      overload;   inline;
    procedure SetCaFile(aData : RawByteString);  overload;   inline;
    procedure SetCaFile(aData : UnicodeString);  overload;   inline;

    procedure SetSslVersion(aData : TCurlSslVersion);  inline;

    procedure SetRecvStream(aData : TStream);
    procedure SetSendStream(aData : TStream);

    procedure SetFollowLocation(aData : boolean);

    procedure RemoveCustomHeaders;
    procedure SetCustomHeaders(const x : array of RawByteString);

    procedure Perform;
    function PerformNe : TCurlCode;

    function GetInfo(aInfo : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;

    function GetResponseCode : longint;

    function Clone : IEasyCurl;

    class function StreamWrite(
            var Buffer;
            Size, NItems : NativeUInt;
            OutStream : pointer) : NativeUInt;  cdecl;  static;
    class function StreamRead(
            var Buffer;
            Size, NItems : NativeUInt;
            OutStream : pointer) : NativeUInt;  cdecl;  static;
  end;

  ECurlError = class (ECurl)
  private
    fCode : TCurlCode;
  public
    constructor Create(aObject : TEasyCurlImpl; aCode : TCurlCode);
    property Code : TCurlCode read fCode;
  end;

  /// Converts a cURL error code into localized string.
  /// It does not rely on any localization engine and string storage technology,
  ///   whether it is Windows resource, text file or XML.
  /// The default version (CurlDefaultLocalize.ErrorMsg) just takes strings from
  ///   cURL DLL.
  EvCurlLocalizeError = function (
        aObject : TEasyCurlImpl; aCode : TCurlCode) : string of object;

  CurlDefaultLocalize = class
  public
    class function ErrorMsg(
        aObject : TEasyCurlImpl; aCode : TCurlCode) : string;
  end;

var
  CurlLocalizeError : EvCurlLocalizeError = CurlDefaultLocalize.ErrorMsg;

function GetCurl : IEasyCurl;

implementation

///// Errors and error localization ////////////////////////////////////////////

class function CurlDefaultLocalize.ErrorMsg(
    aObject : TEasyCurlImpl; aCode : TCurlCode) : string;
begin
  Result := string(curl_easy_strerror(aCode));
end;


///// ECurl and descendents ////////////////////////////////////////////////////

constructor ECurlError.Create(aObject : TEasyCurlImpl; aCode : TCurlCode);
begin
  inherited Create(CurlLocalizeError(aObject, aCode));
  fCode := aCode;
end;


///// TEasyCurlImpl ////////////////////////////////////////////////////////////

constructor TEasyCurlImpl.Create;
begin
  inherited;
  fHandle := curl_easy_init;
  if fHandle = nil then
    raise ECurlInternal.Create('[TEasyCurlImpl.Create] Cannot create cURL object.');
end;

constructor TEasyCurlImpl.Create(aSource : TEasyCurlImpl);
begin
  inherited Create;
  fHandle := curl_easy_duphandle(aSource.fHandle);
  if fHandle = nil then
    raise ECurlInternal.Create('[TEasyCurlImpl.Create(TEasyCurlImpl)] Cannot clone cURL object.');
end;

destructor TEasyCurlImpl.Destroy;
begin
  curl_easy_cleanup(fHandle);
  inherited;
end;

procedure TEasyCurlImpl.RaiseIf(aCode : TCurlCode);
begin
  if aCode <> CURLE_OK then
    raise ECurlError.Create(Self, aCode);
end;


function TEasyCurlImpl.GetHandle : TCurlHandle;
begin
  Result := fHandle;
end;

procedure TEasyCurlImpl.Perform;
begin
  RaiseIf(curl_easy_perform(fHandle));
end;

function TEasyCurlImpl.PerformNe : TCurlCode;
begin
  Result := curl_easy_perform(fHandle);
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlLongInfo) : longint;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlDoubleInfo) : double;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlSListInfo) : PCurlSList;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlOffOption; aData : TCurlOff);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlOption; aData : PAnsiChar);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlOption; aData : pointer);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlIntOption; aData : NativeUInt);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlIntOption; aData : boolean);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlOption; aData : RawByteString);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, PAnsiChar(aData)));
end;

procedure TEasyCurlImpl.SetOpt(aOption : TCurlOption; aData : UnicodeString);
begin
  RaiseIf(curl_easy_setopt(fHandle, aOption, PAnsiChar(UTF8Encode(aData))));
end;

function TEasyCurlImpl.Clone : IEasyCurl;
begin
  Result := TEasyCurlImpl.Create(Self);
end;

procedure TEasyCurlImpl.SetUrl(aData : PAnsiChar);
begin
  SetOpt(CURLOPT_URL, aData);
end;

procedure TEasyCurlImpl.SetUrl(aData : RawByteString);
begin
  SetOpt(CURLOPT_URL, aData);
end;

procedure TEasyCurlImpl.SetUrl(aData : UnicodeString);
begin
  SetOpt(CURLOPT_URL, aData);
end;

procedure TEasyCurlImpl.SetCaFile(aData : PAnsiChar);
begin
  SetOpt(CURLOPT_CAINFO, aData);
end;

procedure TEasyCurlImpl.SetCaFile(aData : RawByteString);
begin
  SetOpt(CURLOPT_CAINFO, aData);
end;

procedure TEasyCurlImpl.SetCaFile(aData : UnicodeString);
begin
  SetOpt(CURLOPT_CAINFO, aData);
end;

procedure TEasyCurlImpl.SetSslVersion(aData : TCurlSslVersion);
begin
  SetOpt(CURLOPT_SSLVERSION, ord(aData));
end;

class function TEasyCurlImpl.StreamWrite(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Write(Buffer, Size * NItems);
end;


class function TEasyCurlImpl.StreamRead(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Read(Buffer, Size * NItems);
end;

procedure TEasyCurlImpl.SetRecvStream(aData : TStream);
begin
  SetOpt(CURLOPT_WRITEDATA, aData);
  if aData = nil
    then SetOpt(CURLOPT_WRITEFUNCTION, nil)
    else SetOpt(CURLOPT_WRITEFUNCTION, @StreamWrite);
end;

procedure TEasyCurlImpl.SetSendStream(aData : TStream);
begin
  SetOpt(CURLOPT_READDATA, aData);
  if aData = nil
    then SetOpt(CURLOPT_READFUNCTION, nil)
    else SetOpt(CURLOPT_READFUNCTION, @StreamRead);
end;

function TEasyCurlImpl.GetResponseCode : longint;
begin
  Result := GetInfo(CURLINFO_RESPONSE_CODE);
end;

class procedure TEasyCurlImpl.LinkList(var x : OaSListEntry);
var
  i : integer;
  curr : ^TSListEntry;
  prev : PCurlSList;
begin
  prev := nil;
  for i := High(x) downto Low(x) do begin
    curr := @x[i];
    curr^.entry.Data := PAnsiChar(curr^.str);
    curr^.entry.Next := prev;
    prev := @curr^.entry;
  end;
end;

procedure TEasyCurlImpl.RemoveCustomHeaders;
begin
  SetLength(fCustomHeaders, 0);
  SetOpt(CURLOPT_HTTPHEADER, nil);
end;

procedure TEasyCurlImpl.SetCustomHeaders(const x : array of RawByteString);
var
  i, n : integer;
begin
  n := Length(x);
  if n = 0 then begin
    RemoveCustomHeaders;
  end else begin
    SetLength(fCustomHeaders, Length(x));
    for i := 0 to n - 1 do
      fCustomHeaders[i].str := x[i];
    LinkList(fCustomHeaders);
    SetOpt(CURLOPT_HTTPHEADER, @fCustomHeaders[0].entry);
  end;
end;

procedure TEasyCurlImpl.SetFollowLocation(aData : boolean);
begin
  SetOpt(CURLOPT_FOLLOWLOCATION, aData);
end;

///// Standalone functions /////////////////////////////////////////////////////

function GetCurl : IEasyCurl;
begin
  Result := TEasyCurlImpl.Create;
end;

initialization
  curl_global_init(CURL_GLOBAL_DEFAULT);
finalization
  curl_global_cleanup;
end.
