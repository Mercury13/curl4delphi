program AplusB_Get;

uses
  Vcl.Forms,
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas',
  f_Main in 'f_Main.pas' {fmMain},
  Curl.Interfaces in '..\..\..\Src\Curl.Interfaces.pas',
  Curl.Slist in '..\..\..\Src\Curl.Slist.pas',
  Curl.Encoders in '..\..\..\Src\Curl.Encoders.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
