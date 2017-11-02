unit f_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfmMain = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edA: TEdit;
    edB: TEdit;
    btAdd: TButton;
    edUrl: TEdit;
    Label3: TLabel;
    memoResponse: TMemo;
    procedure btAddClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

uses
  Curl.Lib, Curl.Interfaces;

{$R *.dfm}

function StreamWrite(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Write(Buffer, Size * NItems);
end;


procedure TfmMain.btAddClick(Sender: TObject);
const
  sA : PAnsiChar = 'a';
var
  curl : HCurl;
  post, last : PCurlHttpPost;
  headers, headersEnd : PCurlSList;
  code : TCurlCode;
  stream : TRawByteStream;
  effurl : PAnsiChar;
  respcode : LongInt;
begin
  post := nil;
  last := nil;
  curl := curl_easy_init;
  stream := TRawByteStream.Create;

  // For simplicity, I’ll use a wrapper for SList.
  headers := nil;
  curl_slist_append(headers, 'Alpha: Bravo');
  curl_slist_append(headers, 'Charlie: Delta');

  try
    curl_easy_setopt(curl, CURLOPT_URL, UTF8Encode(edUrl.Text));
    curl_easy_setopt(curl, CURLOPT_POST, true);
    // Some free hostings may require a browser-like user-agent.
    curl_easy_setopt(curl, CURLOPT_USERAGENT, FirefoxUserAgent);
    // Set proxy from IE
    curl_easy_setopt(curl, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);
    curl_easy_setopt(curl, CURLOPT_PROXY, ProxyFromIe);

    // Show issues of vararg initial
    curl_formadd_initial(post, last,
            CURLFORM_COPYNAME, sA,
            CURLFORM_COPYCONTENTS, PAnsiChar(UTF8Encode(edA.Text)),
            CURLFORM_CONTENTHEADER, headers,
            CURLFORM_END);

    // formadd is more type-safe
    curl_formadd(post, last,
            CURLFORM_COPYNAME, 'b',
            CURLFORM_COPYCONTENTS, PAnsiChar(UTF8Encode(edB.Text)),
            CURLFORM_END);

    curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, stream);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, @StreamWrite);
    code := curl_easy_perform(curl);
    if code = CURLE_OK then begin
      curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, effurl);
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, respcode);
      memoResponse.Text := string(stream.Data) + #13#10#13#10'URL: ' + effurl
          + #10#10'Response code: ' + IntToStr(respcode);
    end else begin
      memoResponse.Text := string(curl_easy_strerror(code));
    end;

  finally
    stream.Free;
    curl_easy_cleanup(curl);
    curl_formfree(post);
  end;
end;

initialization
  curl_global_init(CURL_GLOBAL_DEFAULT);
finalization
  curl_global_cleanup;
end.

