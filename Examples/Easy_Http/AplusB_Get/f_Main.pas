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
  Curl.Interfaces, Curl.Easy, Curl.Lib, Curl.Encoders;

{$R *.dfm}

procedure TfmMain.btAddClick(Sender: TObject);
var
  curl : ICurl;
begin
  curl := CurlGet;

  curl.SetUserAgent(FirefoxUserAgent)
      .SetUrl(CurlGetBuilder(edUrl.Text)
                .Param('a', edA.Text)
                .Param('b', edB.Text))
      .SwitchRecvToString
      .Perform;
  memoResponse.Text := string(curl.ResponseBody)
          + #13#10#13#10'URL: ' +
          string(curl.GetInfo(CURLINFO_EFFECTIVE_URL));
end;

end.

