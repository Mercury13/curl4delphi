program Https;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas';

var
  curl : HCurl;
  res : TCurlCode;
  code : longint;
begin
  curl_global_init(CURL_GLOBAL_DEFAULT);

  curl := curl_easy_init;
  if curl <> nil then begin
    curl_easy_setopt(curl, CURLOPT_URL, 'https://ukr.net/');
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, true);
    curl_easy_setopt(curl, CURLOPT_CAINFO, 'cacert.pem');
    // Unicode is also supported!
    //curl_easy_setopt(curl, CURLOPT_CAINFO, PChar(UTF8Encode('α×β.pem')));

    // Perform the request, res will get the return code
    res := curl_easy_perform(curl);
    // Check for errors
    if (res = CURLE_OK) then begin
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, code);
      Writeln;
      Writeln(Format('HTTP response code: %d', [ code ] ));
    end else begin
      Writeln(Format('curl_easy_perform() failed: %s',
              [ curl_easy_strerror(res) ] ));
    end;
    // always cleanup
    curl_easy_cleanup(curl);
  end;

  curl_global_cleanup;

  Readln;
end.
