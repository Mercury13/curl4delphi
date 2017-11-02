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
  // Form
  form := CurlGetForm;
  // Complex version (requires additional headers)
  form.Add(CurlGetField
             .Name('a')
             .Content(edA.Text)
             .CustomHeaders(CurlGetSlist
                              .AddRaw('Alpha: Bravo')
                              .AddRaw('Charlie: Delta')))
      // Simple version (just add a field)
      .Add('b', edB.Text);

  // Stream
  stream := TRawByteStream.Create;

  curl := CurlGet;
  curl.SetUrl(edUrl.Text)
      .SetOpt(CURLOPT_POST, true)
      // I tested it on my free hosting — it has a bot protection.
      .SetUserAgent(FirefoxUserAgent)
      .SetForm(form)
      .SetRecvStream(stream, [csfAutoDestroy])
      .Perform;
  memoResponse.Text := string(stream.Data);
end;

end.

