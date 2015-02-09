program Simple;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas',
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas';

const
  // I won’t use example.com, as someone removed redirection from example.com
  // AFAIK, ithappens.ru redirects to ithappens.me
  Url = 'http://ithappens.me/';
  MaxFileSize = 180;
var
  curl : IEasyCurl;
  code : integer;
  ul, dl : double;
  effurl : PAnsiChar;
  cookies : PCurlSList;
begin
  try
    curl := GetCurl;
    curl.setOpt(CURLOPT_URL, Url);
    curl.setOpt(CURLOPT_FOLLOWLOCATION, true);
    curl.setOpt(CURLOPT_MAXFILESIZE, MaxFileSize);

    // Perform the request, res will get the return code
    curl.Perform;
    code := curl.GetInfo(CURLINFO_RESPONSE_CODE);
    ul := curl.GetInfo(CURLINFO_SIZE_UPLOAD);
    dl := curl.GetInfo(CURLINFO_SIZE_DOWNLOAD);
    effurl := curl.GetInfo(CURLINFO_EFFECTIVE_URL);
    cookies := curl.GetInfo(CURLINFO_SSL_ENGINES);
    Writeln(Format('HTTP response code: %d', [ code ] ));
    Writeln(Format('Uploaded: %d', [ round(ul) ] ));
    Writeln(Format('Downloaded: %d', [ round(dl) ] ));
    Writeln(Format('Effective URL: %s', [ effurl ] ));
    Writeln('SSL engines:');
    while cookies <> nil do begin
      Writeln ('- ', cookies^.Data);
      cookies := cookies^.Next;
    end;
  except
    on e : Exception do
      Writeln(Format('cURL failed: %s',
              [ e.Message ] ));
  end;

  Readln;
end.

