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
  Curl.Interfaces, Curl.Easy, Curl.Form, Curl.Lib, Curl.RawByteStream,
  Curl.Slist;

{$R *.dfm}

procedure TfmMain.btAddClick(Sender: TObject);
var
  curl : ICurl;
  form : ICurlForm;
  stream : TRawByteStream;
begin
  curl := CurlGet;
  form := CurlGetForm;
  stream := TRawByteStream.Create;

  curl.SetUrl(edUrl.Text);
  curl.SetOpt(CURLOPT_POST, true);
  // I tested it on my free hosting — it has a bot protection.
  curl.SetUserAgent(FirefoxUserAgent);

  // Complex version (requires additional headers)
  form.Add(CurlGetField
             .Name('a')
             .Content(edA.Text)
             .CustomHeaders(CurlGetSlist
                              .AddRaw('Alpha: Bravo')
                              .AddRaw('Charlie: Delta')));

  // Simple version (just add a field)
  form.Add('b', edB.Text);

  curl.Form := form;
  curl.SetRecvStream(stream, [csfAutoDestroy]);
  curl.Perform;
  memoResponse.Text := string(stream.Data);
end;

end.

