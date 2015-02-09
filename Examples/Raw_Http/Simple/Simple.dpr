program Simple;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas';

const
  // I won’t use example.com, as someone removed redirection from example.com
  // AFAIK, ithappens.ru redirects to ithappens.me
  Url = 'http://ithappens.me/';
  MaxFileSize = 2000;
var
  curl : TCurlHandle;
  res : TCurlCode;
  code : longint;
  ul, dl : double;
  effurl : PAnsiChar;
  cookies : PCurlSList;
begin
  curl := curl_easy_init;
  if curl <> nil then begin
    curl_easy_setopt(curl, CURLOPT_URL, Url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, true);
    curl_easy_setopt(curl, CURLOPT_MAXFILESIZE, MaxFileSize);

    // Perform the request, res will get the return code
    res := curl_easy_perform(curl);
    // Check for errors
    if (res = CURLE_OK) then begin
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, code);
      curl_easy_getinfo(curl, CURLINFO_SIZE_UPLOAD, ul);
      curl_easy_getinfo(curl, CURLINFO_SIZE_DOWNLOAD, dl);
      curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, effurl);
      curl_easy_getinfo(curl, CURLINFO_SSL_ENGINES, cookies);
      Writeln(Format('HTTP response code: %d', [ code ] ));
      Writeln(Format('Uploaded: %d', [ round(ul) ] ));
      Writeln(Format('Downloaded: %d', [ round(dl) ] ));
      Writeln(Format('Effective URL: %s', [ effurl ] ));
      Writeln('SSL engines:');
      while cookies <> nil do begin
        Writeln ('- ', cookies^.Data);
        cookies := cookies^.Next;
      end;
    end else begin
      Writeln(Format('curl_easy_perform() failed: %s',
              [ curl_easy_strerror(res) ] ));
    end;

    // always cleanup
    curl_easy_cleanup(curl);
  end;

  Readln;
end.
