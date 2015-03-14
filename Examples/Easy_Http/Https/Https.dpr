program Https;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas';

var
  curl : IEasyCurl;
  res : TCurlCode;
  code : longint;
begin
  try
    curl := GetCurl;
    curl.SetUrl('https://ukr.net');
    curl.SetFollowLocation(true);
    curl.SetCaFile('cacert.pem');

    // Perform the request, res will get the return code
    curl.Perform;

    // Check for errors
    Writeln(Format('HTTP response code: %d', [ curl.GetResponseCode ] ));
  except
    on e : Exception do
      writeln('cURL failed: ', e.Message);
  end;

  Readln;
end.
