program PruebaVentasWs;

uses
  Vcl.Forms,
  UPrincipal in 'UPrincipal.pas' {frmPrincipal},
  UParametrosPrueba in 'UParametrosPrueba.pas',
  inLibParametrosIntf in '..\Lib\inLibParametrosIntf.pas',
  inLibFactuzamApi in '..\Lib\inLibFactuzamApi.pas',
  inLibVentasWsJson in '..\Lib\inLibVentasWsJson.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'PruebaVentasWs';
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
