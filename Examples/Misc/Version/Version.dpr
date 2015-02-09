program Version;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.StrUtils,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas';

const
  CurlAgeNames : array [TCurlVersion] of string = (
        'first', 'second', 'third', 'fourth' );
  CurlFeatureNames : array [0..19] of string = (
        'ipv6', 'kerberos4', 'ssl', 'libz', 'ntlm', 'gssnegotiate',
        'debug', 'asyncdns', 'spnego', 'largefile', 'idn',
        'sspi', 'iconv', 'curldebug', 'tlssrp', 'ntlmwb',
        'http2', 'gssapi', 'kerberos5', 'unixsockets' );

var
  vi : PCurlVersionInfo;
  i : integer;
  protocol : PPAnsiChar;
  hasProtocol : boolean;
begin
  Writeln(Format('Binding version: %s (hex %x)',
          [ CurlBindingVersionString, CurlBindingVersionHex ]));
  Writeln('Actual version: ', curl_version);

  vi := curl_version_info;
  Writeln;
  Writeln('Details:');
  Writeln('Age: ', CurlAgeNames[vi^.age]);
  Writeln(Format('Version: %s (hex %x) for %s',
        [vi^.version, vi^.version_num, vi^.host]));

  Write('Features: ');
  for i := 0 to 19 do
    Write(' ', CurlFeatureNames[i],
              IfThen(vi^.features and (1 shl i) <> 0, '+', '-'));
  Writeln;

  Writeln(Format('SSL version: %s (hex %x)',
        [ vi^.ssl_version, vi^.ssl_version_num ]));
  Writeln(Format('Libz version: %s',
        [ vi^.libz_version ]));

  Write('Supported protocols: ');
  hasProtocol := false;
  protocol := vi^.protocols;
  while protocol^ <> nil do begin
    if hasProtocol
      then Write(', ');
    Write(protocol^);
    hasProtocol := true;
    inc(protocol);
  end;
  Writeln;

  Writeln(Format('Ares version: %s (hex %x)', [ vi^.ares, vi^.ares_num ]));
  Writeln(Format('Libidn version: %s', [ vi^.libidn ]));
  Writeln(Format('Iconv version: %x', [ vi^.iconv_ver_num ]));
  Writeln(Format('Libssh version: %s', [ vi^.libssh_version ]));

  Readln;
end.
