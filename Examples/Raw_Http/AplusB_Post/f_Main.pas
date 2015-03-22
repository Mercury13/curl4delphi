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
  Curl.Lib,
  Curl.RawByteStream,
  Curl.Slist;

{$R *.dfm}

function StreamWrite(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Write(Buffer, Size * NItems);
end;


procedure TfmMain.btAddClick(Sender: TObject);
var
  curl : TCurlHandle;
  post, last : PCurlHttpPost;
  code : TCurlCode;
  stream : TRawByteStream;
  list : ICurlSList;
begin
  post := nil;
  last := nil;
  curl := curl_easy_init;
  stream := TRawByteStream.Create;
  list := CurlGetSlist;
  list.Add('Alpha: Bravo');
  list.Add('Charlie: Delta');
  try
    curl_easy_setopt(curl, CURLOPT_URL, UTF8Encode(edUrl.Text));
    curl_easy_setopt(curl, CURLOPT_POST, true);
    // Some free hostings may require a browser-like user-agent.
    curl_easy_setopt(curl, CURLOPT_USERAGENT,
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0');

    curl_formadd(post, last,
            CURLFORM_COPYNAME, 'a',
            CURLFORM_COPYCONTENTS, PAnsiChar(UTF8Encode(edA.Text)),
            CURLFORM_CONTENTHEADER, PAnsiChar(list.RawValue),
            CURLFORM_END);

    curl_formadd(post, last,
            CURLFORM_COPYNAME, 'b',
            CURLFORM_COPYCONTENTS, PAnsiChar(UTF8Encode(edB.Text)),
            CURLFORM_END);

    curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, stream);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, @StreamWrite);
    code := curl_easy_perform(curl);
    if code = CURLE_OK
      then memoResponse.Text := string(stream.Data)
      else memoResponse.Text := string(curl_easy_strerror(code));

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

