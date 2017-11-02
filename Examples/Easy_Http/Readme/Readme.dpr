program Readme;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas',
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.Interfaces in '..\..\..\Src\Curl.Interfaces.pas';

var
  curl : ICurl;
begin
  try
    curl := CurlGet;
    curl.SetUrl('http://example.com')
        .SetProxyFromIe
        .SetUserAgent(ChromeUserAgent)
        .SwitchRecvToString
        .Perform;
    //curl.Perform;   // Uncomment to test that the stream properly rewinds
    Writeln(curl.ResponseBody);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
