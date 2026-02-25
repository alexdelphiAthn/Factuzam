program Project1;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {FormMain},
  UFactura in 'UFactura.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
