program StreamedDl;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.SysUtils,
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas',
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.RawByteStream in '..\..\..\Src\Curl.RawByteStream.pas',
  Curl.Interfaces in '..\..\..\Src\Curl.Interfaces.pas';

const
  // I won’t use example.com, as someone removed redirection from example.com
  // AFAIK, ithappens.ru redirects to ithappens.me
  Url = 'http://ithappens.ru/';
var
  curl : ICurl;
  code : integer;
  fs : TFileStream;
  rbs : TRawByteStream;
begin
  try
    curl := CurlGet;
    curl.setUrl(Url);
    curl.SetFollowLocation(true);

    fs := TFileStream.Create('index.html', fmCreate);
    curl.SetRecvStream(fs);

    // Perform the request
    try
      curl.Perform;
    finally
      fs.Free;
    end;

    // Perform once again, to RawByteStream.
    // And write the first 1000
    rbs := TRawByteStream.Create;
    curl.SetRecvStream(rbs);
    try
      curl.Perform;
      Writeln(Copy(rbs.Data, 1, 1000));
    finally
      rbs.Free;
    end;

    // Check for some info
    code := curl.GetResponseCode;
    Writeln(Format('HTTP response code: %d', [ code ] ));
  except
    on e : Exception do
      Writeln(Format('cURL failed: %s',
              [ e.Message ] ));
  end;

  Readln;
end.
