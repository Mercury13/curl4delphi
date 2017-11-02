program AplusB_Post;

uses
  Vcl.Forms,
  f_Main in 'f_Main.pas' {fmMain},
  Curl.Lib in '..\..\..\Src\Curl.Lib.pas',
  Curl.Slist in '..\..\..\Src\Curl.Slist.pas',
  Curl.Interfaces in '..\..\..\Src\Curl.Interfaces.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
