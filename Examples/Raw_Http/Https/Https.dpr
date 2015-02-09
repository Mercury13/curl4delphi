program Https;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LibCurl in '..\..\..\Src\LibCurl.pas';

{$DEFINE SKIP_PEER_VERIFICATION}
{.$DEFINE SKIP_HOSTNAME_VERIFICATION}

var
  curl : TCurlHandle;
  res : TCurlCode;
  code : longint;
begin
  curl_global_init(CURL_GLOBAL_DEFAULT);

  curl := curl_easy_init;
  if curl <> nil then begin
    curl_easy_setopt(curl, CURLOPT_URL, 'https://ukr.net/');
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, true);

{$IFDEF SKIP_PEER_VERIFICATION}
    // If you want to connect to a site who isn't using a certificate that is
    // signed by one of the certs in the CA bundle you have, you can skip the
    // verification of the server's certificate. This makes the connection
    // A LOT LESS SECURE.
    //
    // If you have a CA cert for the server stored someplace else than in the
    // default bundle, then the CURLOPT_CAPATH option might come handy for
    // you.
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
{$ENDIF}

{$IFDEF SKIP_HOSTNAME_VERIFICATION}
    // If the site you're connecting to uses a different host name that what
    // they have mentioned in their server certificate's commonName (or
    // subjectAltName) fields, libcurl will refuse to connect. You can skip
    // this check, but this will make the connection less secure.
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
{$ENDIF}

    // Perform the request, res will get the return code
    res := curl_easy_perform(curl);
    // Check for errors
    if (res = CURLE_OK) then begin
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, @code);
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
