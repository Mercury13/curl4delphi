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
  Curl.Easy,
  Curl.Form,
  Curl.Lib,
  Curl.RawByteStream;

{$R *.dfm}

procedure TfmMain.btAddClick(Sender: TObject);
var
  curl : IEasyCurl;
  form : ICurlForm;
  stream : TRawByteStream;
begin
  curl := GetCurl;
  form := GetCurlForm;
  stream := TRawByteStream.Create;
  try
    curl.SetUrl(edUrl.Text);
    curl.SetOpt(CURLOPT_POST, true);

    form.Add('a', edA.Text);
    form.Add('b', edB.Text);

    curl.Form := form;
    curl.SetRecvStream(stream);
    curl.Perform;
    memoResponse.Text := string(stream.Data)
  finally
    stream.Free;
  end;
end;

end.

