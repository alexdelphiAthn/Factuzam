program CertApiWeb;

uses
  Vcl.Forms,
  UPrincipal in 'UPrincipal.pas' {frmPrincipal},
  inLibClienteApi in 'inLibClienteApi.pas',
  inLibFirmaApi in 'inLibFirmaApi.pas',
  inLibProteccionWindows in 'inLibProteccionWindows.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CertApiWeb';
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
