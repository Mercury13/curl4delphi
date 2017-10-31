program Simple;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas';

const
  // I won’t use example.com, as someone removed redirection from example.com
  // AFAIK, ithappens.ru redirects to ithappens.me
  Url = 'http://ithappens.ru/';
var
  curl : HCurl;
  res : TCurlCode;
  code : longint;
  ul, dl : TCurlOff;
  effurl : PAnsiChar;
  engines : PCurlSList;
begin
  curl := curl_easy_init;
  if curl <> nil then begin
    curl_easy_setopt(curl, CURLOPT_URL, Url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, true);

    // Perform the request, res will get the return code
    res := curl_easy_perform(curl);
    // Check for errors
    if (res = CURLE_OK) then begin
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, code);
      curl_easy_getinfo(curl, CURLINFO_SIZE_UPLOAD_T, ul);
      curl_easy_getinfo(curl, CURLINFO_SIZE_DOWNLOAD_T, dl);
      curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, effurl);
      curl_easy_getinfo(curl, CURLINFO_SSL_ENGINES, engines);
      Writeln(Format('HTTP response code: %d', [ code ] ));
      Writeln(Format('Uploaded: %d', [ ul ] ));
      Writeln(Format('Downloaded: %d', [ dl ] ));
      Writeln(Format('Effective URL: %s', [ effurl ] ));
      Writeln('SSL engines:');
      while engines <> nil do begin
        Writeln ('- ', engines^.Data);
        engines := engines^.Next;
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
