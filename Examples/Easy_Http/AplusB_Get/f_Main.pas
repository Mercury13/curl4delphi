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
  Curl.Interfaces, Curl.Easy, Curl.Lib, Curl.RawByteStream, Curl.Encoders;

{$R *.dfm}

procedure TfmMain.btAddClick(Sender: TObject);
const
  UserAgent : PAnsiChar =
      'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0';
var
  curl : ICurl;
  stream : TRawByteStream;
begin
  curl := CurlGet;
  stream := TRawByteStream.Create;

  curl.SetUserAgent(UserAgent);
  curl.SetUrl(CurlGetBuilder(edUrl.Text)
                .Param('a', edA.Text)
                .Param('b', edB.Text));
  curl.SetRecvStream(stream, [csfAutoDestroy]);
  curl.Perform;
  memoResponse.Text := string(stream.Data)
          + #13#10#13#10'URL: ' +
          string(curl.GetInfo(CURLINFO_EFFECTIVE_URL));
end;

end.

