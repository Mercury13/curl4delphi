unit Curl.Easy;

interface

uses
  // System
  System.Classes, System.SysUtils,
  // cUrl
  Curl.Lib, Curl.Interfaces;

type
  TCurlVerifyHost = (
      CURL_VERIFYHOST_NONE,
      CURL_VERIFYHOST_EXISTENCE,
      CURL_VERIFYHOST_MATCH );

  ICurl = interface (ICloseable)
    ['{5B165EC5-E831-4814-8263-C8D18AE8760E}']
    function GetHandle : HCurl;
    property Handle : HCurl read GetHandle;

    ///  Sets a cURL option.
    ///  SetXXX functions are simply wrappers for SetOpt.
    function SetOpt(aOption : TCurlOffOption; aData : TCurlOff) : ICurl;                overload;
    function SetOpt(aOption : TCurlOption; aData : pointer) : ICurl;                    overload;
    function SetOpt(aOption : TCurlIntOption; aData : NativeUInt) : ICurl;              overload;
    function SetOpt(aOption : TCurlIntOption; aData : boolean) : ICurl;                 overload;
    function SetOpt(aOption : TCurlStringOption; aData : PAnsiChar) : ICurl;            overload;
    function SetOpt(aOption : TCurlStringOption; aData : RawByteString) : ICurl;        overload;
    function SetOpt(aOption : TCurlStringOption; aData : UnicodeString) : ICurl;        overload;
    function SetOpt(aOption : TCurlProxyTypeOption; aData : TCurlProxyType) : ICurl;    overload;
    function SetOpt(aOption : TCurlUseSslOption; aData : TCurlUseSsl) : ICurl;          overload;
    function SetOpt(aOption : TCurlFtpMethodOption; aData : TCurlFtpMethod) : ICurl;    overload;
    function SetOpt(aOption : TCurlIpResolveOption; aData : TCurlIpResolve) : ICurl;    overload;
    function SetOpt(aOption : TCurlRtspSeqOption; aData : TCurlRtspSeq) : ICurl;        overload;
    function SetOpt(aOption : TCurlNetRcOption; aData : TCurlNetrc) : ICurl;            overload;
    function SetOpt(aOption : TCurlSslVersionOption; aData : TCurlSslVersion) : ICurl;  overload;
    function SetOpt(aOption : TCurlSlistOption; aData : PCurlSList) : ICurl;            overload;
              deprecated 'Use SetXXX instead: SetCustomHeaders, SetResolveList, etc.';
    function SetOpt(aOption : TCurlPostOption; aData : PCurlHttpPost) : ICurl;          overload;
              deprecated 'Use SetForm or property Form instead.';

    ///  Sets a URL. Equivalent to SetOpt(CURLOPT_URL, aData).
    function SetUrl(aData : PAnsiChar) : ICurl;           overload;
    function SetUrl(aData : RawByteString) : ICurl;       overload;
    function SetUrl(aData : UnicodeString) : ICurl;       overload;
    function SetUrl(aData : ICurlStringBuilder) : ICurl;  overload;

    ///  Sets a CA file for SSL
    function SetCaFile(aData : PAnsiChar) : ICurl;      overload;
    function SetCaFile(aData : RawByteString) : ICurl;  overload;
    function SetCaFile(aData : UnicodeString) : ICurl;  overload;

    ///  Sets a user-agent
    function SetUserAgent(aData : PAnsiChar) : ICurl;      overload;
    function SetUserAgent(aData : RawByteString) : ICurl;  overload;
    function SetUserAgent(aData : UnicodeString) : ICurl;  overload;

    ///  Set verify option
    function SetSslVerifyHost(aData : TCurlVerifyHost) : ICurl;
    function SetSslVerifyPeer(aData : boolean) : ICurl;

    ///  Sets a receiver stream. Equivalent to twin SetOpt,
    ///  WRITEFUNCTION and WRITEDATA.
    ///  Does not destroy the stream, you should dispose of it manually!
    ///  If aData = nil: removes all custom receivers.
    function SetRecvStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;

    ///  Sets a sender stream. Equivalent to twin SetOpt,
    ///  READFUNCTION and READDATA.
    ///  Does not destroy the stream, you should dispose of it manually!
    ///  If aData = nil: removes all custom senders.
    function SetSendStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;

    ///  Sets a receiver stream. Equivalent to twin SetOpt,
    ///  HEADERFUNCTION and HEADERDATA.
    ///  Does not destroy the stream, you should dispose of it manually!
    ///  If aData = nil: removes all custom receivers.
    function SetHeaderStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;

    ///  Sets whether cURL will follow redirections.
    function SetFollowLocation(aData : boolean) : ICurl;

    ///  Gets/sets form data
    function SetForm(aForm : ICurlCustomForm) : ICurl;
    function Form : ICurlCustomForm;

    ///  For all these options the object stores a reference to an ICurlCustomSList
    ///  for itself.

    ///  This points to a linked list of headers. This
    ///  list is also used for RTSP.
    function SetCustomHeaders(v : ICurlCustomSList) : ICurl;
    ///  send linked-list of post-transfer QUOTE commands
    function SetPostQuote(v : ICurlCustomSList) : ICurl;
    ///  Provide a pointer to a curl_slist with variables to pass to the telnet
    ///  negotiations. The variables should be in the format <option=value>.
    ///  libcurl supports the options 'TTYPE', 'XDISPLOC' and 'NEW_ENV'.
    ///  See the TELNET standard for details.
    function SetTelnetOptions(v : ICurlCustomSList) : ICurl;
    ///  send linked-list of pre-transfer QUOTE commands
    function SetQuote(v : ICurlCustomSList) : ICurl;
    ///  Set aliases for HTTP 200 in the HTTP Response header
    function SetPreQuote(v : ICurlCustomSList) : ICurl;
    ///  Set aliases for HTTP 200 in the HTTP Response header
    function SetHttp200Aliases(v : ICurlCustomSList) : ICurl;
    ///  set the SMTP mail receiver(s)
    function SetMailRcpt(v : ICurlCustomSList) : ICurl;
    ///  send linked-list of name:port:address sets
    function SetResolveList(v : ICurlCustomSList) : ICurl;
    ///  This points to a linked list of headers used for proxy requests only,
    ///  struct curl_slist kind
    function SetProxyHeader(v : ICurlCustomSList) : ICurl;
    /// Linked-list of host:port:connect-to-host:connect-to-port,
    /// overrides the URL's host:port (only for the network layer) */
    function SetConnectTo(v : ICurlCustomSlist) : ICurl;

    function SetProxyFromIe : ICurl;

    ///  Performs the action.
    ///  Actually does RaiseIf(PerformNe).
    function Perform : ICurl;

    ///  Performs the action w/o throwing an error.
    ///  The user should process error codes for himself.
    function PerformNe : TCurlCode;

    ///  Does nothing if aCode is OK; otherwise localizes the error message
    ///  and throws an exception.
    ///  Sometimes you’d like to process some errors in place w/o bulky
    ///  try/except. Then you run PerformNe, manually process some errors,
    ///  and do RaiseIf for everything else.
    function RaiseIf(aCode : TCurlCode) : ICurl;

    ///  Returns some information.
    ///  GetXXX functions are wrappers for GetInfo.
    function GetInfo(aCode : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;
    function GetInfo(aInfo : TCurlOffInfo) : TCurlOff;  overload;
    function GetInfo(aInfo : TCurlPtrInfo) : pointer;  overload;
    function GetInfo(aInfo : TCurlSocketInfo) : TCurlSocket;  overload;
    function GetInfo(aInfo : TCurlDoubleInfoDeprecated) : double;  overload;
          deprecated 'Use TCurlOffInfo version';

    ///  Returns response code. Equivalent to GetInfo(CURLINFO_RESPONSE_CODE).
    function GetResponseCode : longint;

    ///  Makes an exact copy, e.g. for multithreading.
    ///  @warning  Receiver, sender and header streams will be shared,
    ///        but not auto-destroyed. Form, together with its streams,
    ///        will be shared. So it is wise to replace all streams with unique
    ///        copies for each clone.
    ///  @warning  String lists assigned via SetXXX are shared and,
    ///        as they are ref-counted, destroyed when the last reference
    ///        disappears. For large objects assigned via SetOpt the programmer
    ///        should bother about destruction for himself.
    function Clone : ICurl;
  end;

  TEasyCurlImpl = class (TInterfacedObject, ICurl)
  private
    fHandle : HCurl;
    fCustomHeaders, fPostQuote, fTelnetOptions, fQuote, fPreQuote,
        fHttp200Aliases, fMailRcpt, fResolveList, fProxyHeader,
        fConnectTo : ICurlCustomSList;
    fForm : ICurlCustomForm;
    // We won’t save a few bytes of memory; repeatable code is more important.
    fRecvStream, fSendStream, fHeaderStream : TCurlAutoStream;

    function SetSList(
            aOpt : TCurlSlistOption;
            var aOldValue : ICurlCustomSList;
            aNewValue : ICurlCustomSList) : ICurl;

    procedure RewindStreams;
  public
    constructor Create;  overload;
    constructor Create(aSource : TEasyCurlImpl);  overload;
    destructor Destroy;  override;
    function GetHandle : HCurl;

    function RaiseIf(aCode : TCurlCode) : ICurl;  inline;

    function SetOpt(aOption : TCurlOffOption; aData : TCurlOff) : ICurl;  overload;
    function SetOpt(aOption : TCurlOption; aData : pointer) : ICurl;  overload;
    function SetOpt(aOption : TCurlIntOption; aData : NativeUInt) : ICurl;  overload;
    function SetOpt(aOption : TCurlIntOption; aData : boolean) : ICurl;  overload;
    function SetOpt(aOption : TCurlStringOption; aData : PAnsiChar) : ICurl;  overload;
    function SetOpt(aOption : TCurlStringOption; aData : RawByteString) : ICurl;  overload;
    function SetOpt(aOption : TCurlStringOption; aData : UnicodeString) : ICurl;  overload;
    function SetOpt(aOption : TCurlSlistOption; aData : PCurlSList) : ICurl;  overload;
    function SetOpt(aOption : TCurlPostOption; aData : PCurlHttpPost) : ICurl;  overload;
    function SetOpt(aOption : TCurlProxyTypeOption; aData : TCurlProxyType) : ICurl;  overload;
    function SetOpt(aOption : TCurlUseSslOption; aData : TCurlUseSsl) : ICurl;  overload;
    function SetOpt(aOption : TCurlFtpMethodOption; aData : TCurlFtpMethod) : ICurl;  overload;
    function SetOpt(aOption : TCurlIpResolveOption; aData : TCurlIpResolve) : ICurl;  overload;
    function SetOpt(aOption : TCurlRtspSeqOption; aData : TCurlRtspSeq) : ICurl;  overload;
    function SetOpt(aOption : TCurlNetRcOption; aData : TCurlNetrc) : ICurl;  overload;
    function SetOpt(aOption : TCurlSslVersionOption; aData : TCurlSslVersion) : ICurl;  overload;

    function SetUrl(aData : PAnsiChar) : ICurl;      overload;   inline;
    function SetUrl(aData : RawByteString) : ICurl;  overload;   inline;
    function SetUrl(aData : UnicodeString) : ICurl;  overload;   inline;
    function SetUrl(aData : ICurlStringBuilder) : ICurl;  overload;  inline;

    function SetCaFile(aData : PAnsiChar) : ICurl;      overload;   inline;
    function SetCaFile(aData : RawByteString) : ICurl;  overload;   inline;
    function SetCaFile(aData : UnicodeString) : ICurl;  overload;   inline;

    function SetUserAgent(aData : PAnsiChar) : ICurl;      overload;
    function SetUserAgent(aData : RawByteString) : ICurl;  overload;
    function SetUserAgent(aData : UnicodeString) : ICurl;  overload;

    function SetSslVerifyHost(aData : TCurlVerifyHost) : ICurl;
    function SetSslVerifyPeer(aData : boolean) : ICurl;

    function SetRecvStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;
    function SetSendStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;
    function SetHeaderStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;

    function SetFollowLocation(aData : boolean) : ICurl;

    function SetForm(aForm : ICurlCustomForm) : ICurl;
    function Form : ICurlCustomForm;

    function SetCustomHeaders(v : ICurlCustomSList) : ICurl;
    function SetPostQuote(v : ICurlCustomSList) : ICurl;
    function SetTelnetOptions(v : ICurlCustomSList) : ICurl;
    function SetQuote(v : ICurlCustomSList) : ICurl;
    function SetPreQuote(v : ICurlCustomSList) : ICurl;
    function SetHttp200Aliases(v : ICurlCustomSList) : ICurl;
    function SetMailRcpt(v : ICurlCustomSList) : ICurl;
    function SetResolveList(v : ICurlCustomSList) : ICurl;
    function SetProxyHeader(v : ICurlCustomSList) : ICurl;
    function SetConnectTo(v : ICurlCustomSlist) : ICurl;
    function SetProxyFromIe : ICurl;

    function Perform : ICurl;
    function PerformNe : TCurlCode;

    function GetInfo(aInfo : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;
    function GetInfo(aInfo : TCurlDoubleInfoDeprecated) : double;  overload;
    function GetInfo(aInfo : TCurlOffInfo) : TCurlOff;  overload;
    function GetInfo(aInfo : TCurlPtrInfo) : pointer;  overload;
    function GetInfo(aInfo : TCurlSocketInfo) : TCurlSocket;  overload;

    function GetResponseCode : longint;

    ///  This is implementation of ICurl.Clone. If you dislike
    ///  reference-counting, use TEasyCurlImpl.Create(someCurl).
    function Clone : ICurl;

    procedure CloseStreams;
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

function CurlGet : ICurl;

implementation

uses
  System.Win.Registry, Winapi.Windows;

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
  fSendStream.Init;
  fRecvStream.Init;
  fHeaderStream.Init;
  fHandle := curl_easy_init;
  if fHandle = nil then
    raise ECurlInternal.Create('[TEasyCurlImpl.Create] Cannot create cURL object.');
end;

constructor TEasyCurlImpl.Create(aSource : TEasyCurlImpl);
begin
  inherited Create;
  // Streams
  fSendStream.InitFrom(aSource.fSendStream);
  fRecvStream.InitFrom(aSource.fRecvStream);
  fHeaderStream.InitFrom(aSource.fHeaderStream);
  // Handle
  fHandle := curl_easy_duphandle(aSource.fHandle);
  if fHandle = nil then
    raise ECurlInternal.Create('[TEasyCurlImpl.Create(TEasyCurlImpl)] Cannot clone cURL object.');
  // Copy settings!
  fForm := aSource.fForm;
  fCustomHeaders := aSource.fCustomHeaders;
  fPostQuote := aSource.fPostQuote;
  fTelnetOptions := aSource.fTelnetOptions;
  fPreQuote := aSource.fPreQuote;
  fHttp200Aliases := aSource.fHttp200Aliases;
  fMailRcpt := aSource.fMailRcpt;
  fResolveList := aSource.fResolveList;
  fProxyHeader := aSource.fProxyHeader;
end;

destructor TEasyCurlImpl.Destroy;
begin
  CloseStreams;
  curl_easy_cleanup(fHandle);
  inherited;
end;

function TEasyCurlImpl.RaiseIf(aCode : TCurlCode) : ICurl;
begin
  if aCode <> CURLE_OK then
    raise ECurlError.Create(Self, aCode);
  Result := Self;
end;


function TEasyCurlImpl.GetHandle : HCurl;
begin
  Result := fHandle;
end;

function TEasyCurlImpl.Perform : ICurl;
begin
  RaiseIf(PerformNe);
  Result := Self;
end;

function TEasyCurlImpl.PerformNe : TCurlCode;
begin
  RewindStreams;
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

function TEasyCurlImpl.GetInfo(aInfo : TCurlDoubleInfoDeprecated) : double;
begin
  {$WARN SYMBOL_DEPRECATED OFF}
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
  {$WARN SYMBOL_DEPRECATED DEFAULT}
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlPtrInfo) : pointer;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlOffInfo) : TCurlOff;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.GetInfo(aInfo : TCurlSocketInfo) : TCurlSocket;
begin
  RaiseIf(curl_easy_getinfo(fHandle, aInfo, Result));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlOffOption; aData : TCurlOff) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlStringOption; aData : PAnsiChar) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlOption; aData : pointer) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlIntOption; aData : NativeUInt) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlIntOption; aData : boolean) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlStringOption; aData : RawByteString) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, PAnsiChar(aData)));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlStringOption; aData : UnicodeString) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, PAnsiChar(UTF8Encode(aData))));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlSlistOption; aData : PCurlSList) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlPostOption; aData : PCurlHttpPost) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlProxyTypeOption; aData : TCurlProxyType) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlUseSslOption; aData : TCurlUseSsl) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlFtpMethodOption; aData : TCurlFtpMethod) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlIpResolveOption; aData : TCurlIpResolve) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlRtspSeqOption; aData : TCurlRtspSeq) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlNetRcOption; aData : TCurlNetrc) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.SetOpt(aOption : TCurlSslVersionOption; aData : TCurlSslVersion) : ICurl;
begin
  Result := RaiseIf(curl_easy_setopt(fHandle, aOption, aData));
end;

function TEasyCurlImpl.Clone : ICurl;
begin
  Result := TEasyCurlImpl.Create(Self);
end;

function TEasyCurlImpl.SetUrl(aData : PAnsiChar) : ICurl;
begin
  Result := SetOpt(CURLOPT_URL, aData);
end;

function TEasyCurlImpl.SetUrl(aData : RawByteString) : ICurl;
begin
  Result := SetOpt(CURLOPT_URL, aData);
end;

function TEasyCurlImpl.SetUrl(aData : UnicodeString) : ICurl;
begin
  Result := SetOpt(CURLOPT_URL, aData);
end;

function TEasyCurlImpl.SetUrl(aData : ICurlStringBuilder) : ICurl;
begin
  Result := SetUrl(aData.Build);
end;

function TEasyCurlImpl.SetCaFile(aData : PAnsiChar) : ICurl;
begin
  Result := SetOpt(CURLOPT_CAINFO, aData);
end;

function TEasyCurlImpl.SetCaFile(aData : RawByteString) : ICurl;
begin
  Result := SetOpt(CURLOPT_CAINFO, aData);
end;

function TEasyCurlImpl.SetCaFile(aData : UnicodeString) : ICurl;
begin
  Result := SetOpt(CURLOPT_CAINFO, aData);
end;

function TEasyCurlImpl.SetUserAgent(aData : PAnsiChar) : ICurl;
begin
  Result := SetOpt(CURLOPT_USERAGENT, aData);
end;

function TEasyCurlImpl.SetUserAgent(aData : RawByteString) : ICurl;
begin
  Result := SetOpt(CURLOPT_USERAGENT, PAnsiChar(aData));
end;

function TEasyCurlImpl.SetUserAgent(aData : UnicodeString) : ICurl;
begin
  Result := SetOpt(CURLOPT_USERAGENT, PAnsiChar(UTF8Encode(aData)));
end;

function TEasyCurlImpl.SetRecvStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;
begin
  fRecvStream.Assign(aData, aFlags);
  SetOpt(CURLOPT_WRITEDATA, aData);
  if aData = nil
    then SetOpt(CURLOPT_WRITEFUNCTION, nil)
    else SetOpt(CURLOPT_WRITEFUNCTION, @CurlStreamWrite);
  Result := Self;
end;


function TEasyCurlImpl.SetSendStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;
begin
  // Form and sender stream exclude each other
  fForm := nil;
  fSendStream.Assign(aData, aFlags);
  SetOpt(CURLOPT_READDATA, aData);
  if aData = nil
    then SetOpt(CURLOPT_READFUNCTION, nil)
    else SetOpt(CURLOPT_READFUNCTION, @CurlStreamRead);
  Result := Self;
end;

function TEasyCurlImpl.SetHeaderStream(aData : TStream; aFlags : TCurlStreamFlags) : ICurl;
begin
  fHeaderStream.Assign(aData, aFlags);
  SetOpt(CURLOPT_HEADERDATA, aData);
  if aData = nil
    then SetOpt(CURLOPT_HEADERFUNCTION, nil)
    else SetOpt(CURLOPT_HEADERFUNCTION, @CurlStreamWrite);
  Result := Self;
end;

function TEasyCurlImpl.GetResponseCode : longint;
begin
  Result := GetInfo(CURLINFO_RESPONSE_CODE);
end;

function TEasyCurlImpl.SetSList(
        aOpt : TCurlSlistOption;
        var aOldValue : ICurlCustomSList;
        aNewValue : ICurlCustomSList) : ICurl;
var
  rawVal : PCurlSList;
begin
  // New value = nil — do not dereference
  if aNewValue = nil
    then rawVal := nil
    else rawVal := aNewValue.RawValue;

  // Raw value = nil — do not store
  if rawVal = nil
    then aOldValue := nil
    else aOldValue := aNewValue;

  Result := SetOpt(aOpt, rawVal);
end;

function TEasyCurlImpl.SetCustomHeaders(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_HTTPHEADER, fCustomHeaders, v);
end;

function TEasyCurlImpl.SetPostQuote(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_POSTQUOTE, fPostQuote, v);
end;

function TEasyCurlImpl.SetTelnetOptions(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_TELNETOPTIONS, fTelnetOptions, v);
end;

function TEasyCurlImpl.SetQuote(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_PREQUOTE, fQuote, v);
end;

function TEasyCurlImpl.SetPreQuote(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_PREQUOTE, fPreQuote, v);
end;

function TEasyCurlImpl.SetHttp200Aliases(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_HTTP200ALIASES, fHttp200Aliases, v);
end;

function TEasyCurlImpl.SetMailRcpt(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_MAIL_RCPT, fMailRcpt, v);
end;

function TEasyCurlImpl.SetResolveList(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_RESOLVE, fResolveList, v);
end;

function TEasyCurlImpl.SetProxyHeader(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_PROXYHEADER, fProxyHeader, v);
end;

function TEasyCurlImpl.SetConnectTo(v : ICurlCustomSList) : ICurl;
begin
  Result := SetSList(CURLOPT_CONNECT_TO, fConnectTo, v);
end;

function TEasyCurlImpl.SetFollowLocation(aData : boolean) : ICurl;
begin
  Result := SetOpt(CURLOPT_FOLLOWLOCATION, aData);
end;


function TEasyCurlImpl.SetSslVerifyHost(aData : TCurlVerifyHost) : ICurl;
begin
  Result := SetOpt(CURLOPT_SSL_VERIFYHOST, ord(aData));
end;


function TEasyCurlImpl.SetSslVerifyPeer(aData : boolean) : ICurl;
begin
  Result := SetOpt(CURLOPT_SSL_VERIFYPEER, aData);
end;

function TEasyCurlImpl.SetForm(aForm : ICurlCustomForm) : ICurl;
begin
  // Form and sender stream exclude each other
  fSendStream.Destroy;
  if aForm <> nil then begin
    SetOpt(CURLOPT_HTTPPOST, aForm.RawValue);
    SetOpt(CURLOPT_READFUNCTION, @aForm.ReadFunction);
  end else begin
    SetOpt(CURLOPT_HTTPPOST, nil);
    SetOpt(CURLOPT_READFUNCTION, nil);
  end;
  fForm := aForm;
  Result := Self;
end;

function TEasyCurlImpl.Form : ICurlCustomForm;
begin
  Result := fForm;
end;

procedure TEasyCurlImpl.RewindStreams;
begin
  if fForm <> nil
    then fForm.RewindStreams;
  fSendStream.RewindRead;
  fRecvStream.RewindWrite;
  fHeaderStream.RewindWrite;
end;

procedure TEasyCurlImpl.CloseStreams;
begin
  if fForm <> nil
    then fForm.CloseStreams;
  fSendStream.Destroy;
  fRecvStream.Destroy;
  fHeaderStream.Destroy;
end;

function TEasyCurlImpl.SetProxyFromIe : ICurl;
var
  reg : TRegistry;
  us : UnicodeString;
  strs : TStringList;
  i, pEqual : integer;
  s : string;
begin
  strs := nil;
  reg  := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKeyReadOnly('\Software\Microsoft\Windows\CurrentVersion\Internet Settings');
    if reg.ReadInteger('ProxyEnable') <> 0 then begin
        us := reg.ReadString('ProxyServer');
        strs := TStringList.Create;
        strs.Delimiter := ';';
        strs.StrictDelimiter := true;
        strs.DelimitedText := us;

        for i := 0 to strs.Count - 1 do begin
            s := strs[i];
            pEqual := Pos('=', s);
            if pEqual > 0 then begin
                if Trim(Copy(s, 0, pEqual)) <> 'http'
                  then continue;
            end;

            SetOpt(CURLOPT_PROXYTYPE, CURLPROXY_HTTP);
            SetOpt(CURLOPT_PROXY, Copy(s, pEqual + 1, Length(s)));
            break;
        end;
    end;
    reg.CloseKey;
  finally
    reg.Free;
    strs.Free;
  end;
  Result := Self;
end;


///// Standalone functions /////////////////////////////////////////////////////

function CurlGet : ICurl;
begin
  Result := TEasyCurlImpl.Create;
end;

initialization
  curl_global_init(CURL_GLOBAL_DEFAULT);
finalization
  curl_global_cleanup;
end.
