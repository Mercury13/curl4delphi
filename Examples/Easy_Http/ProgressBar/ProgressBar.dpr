program ProgressBar;

uses
  Vcl.Forms,
  f_Main in 'f_Main.pas' {fmMain},
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.Easy in '..\..\..\Src\Curl.Easy.pas',
  Curl.HttpCodes in '..\..\..\Src\Curl.HttpCodes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
