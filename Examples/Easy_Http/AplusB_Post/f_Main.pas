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
  Curl.Interfaces, Curl.Easy, Curl.Form, Curl.Lib, Curl.RawByteStream;

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
  try
    curl.SetUrl(edUrl.Text);
    curl.SetOpt(CURLOPT_POST, true);
    // I tested it on my free hosting — it has a bot protection.
    curl.SetOpt(CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0');

    form.Add('a', edA.Text);
    form.Add('b', edB.Text);

    curl.Form := form;
    curl.SetRecvStream(stream);
    curl.Perform;
    memoResponse.Text := string(stream.Data);
  finally
    stream.Free;
  end;
end;

end.

