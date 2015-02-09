unit Curl.Easy;

interface

uses
  // System
  System.SysUtils,
  // cUrl
  Curl.Lib;

type
  IEasyCurl = interface
    function GetHandle : TCurlHandle;
    property Handle : TCurlHandle read GetHandle;

    procedure SetOpt(aOption : TCurlOffOption; aData : TCurlOff);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : PAnsiChar);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : pointer);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : NativeUInt);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : boolean);  overload;

    procedure Perform;

    ///  Performs the action w/o throwing an error.
    ///  The user should process error codes for himself.
    function PerformNe : TCurlCode;

    function GetInfo(aCode : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;

    function Clone : IEasyCurl;
  end;

  ECurl = class (Exception) end;

  ECurlInternal = class (Exception) end;

  TEasyCurlImpl = class (TInterfacedObject, IEasyCurl)
  private
    fHandle : TCurlHandle;

    procedure RaiseIf(aCode : TCurlCode);  inline;
  public
    constructor Create;  overload;
    constructor Create(aSource : TEasyCurlImpl);  overload;
    destructor Destroy;  override;
    function GetHandle : TCurlHandle;

    procedure SetOpt(aOption : TCurlOffOption; aData : TCurlOff);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : PAnsiChar);  overload;
    procedure SetOpt(aOption : TCurlOption; aData : pointer);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : NativeUInt);  overload;
    procedure SetOpt(aOption : TCurlIntOption; aData : boolean);  overload;

    procedure Perform;
    function PerformNe : TCurlCode;

    function GetInfo(aInfo : TCurlLongInfo) : longint;  overload;
    function GetInfo(aInfo : TCurlStringInfo) : PAnsiChar;  overload;
    function GetInfo(aInfo : TCurlDoubleInfo) : double;  overload;
    function GetInfo(aInfo : TCurlSListInfo) : PCurlSList;  overload;

    function Clone : IEasyCurl;
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

function TEasyCurlImpl.Clone : IEasyCurl;
begin
  Result := TEasyCurlImpl.Create(Self);
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
