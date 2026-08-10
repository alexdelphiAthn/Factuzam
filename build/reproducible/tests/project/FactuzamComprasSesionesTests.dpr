program FactuzamComprasSesionesTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  PruebasFotosProvisionales in
    'PruebasFotosProvisionales.pas',
  PruebasImportacionPedidoOcr in
    'PruebasImportacionPedidoOcr.pas',
  PruebasNavegacionComprasSesion in
    'PruebasNavegacionComprasSesion.pas',
  PruebasVisorPedidoOriginal in
    'PruebasVisorPedidoOriginal.pas';

var
  oEjecutor: ITestRunner;
  oResultados: IRunResults;
  oLogger: ITestLogger;
begin
  try
    oEjecutor := TDUnitX.CreateRunner;
    oEjecutor.UseRTTI := True;
    oLogger := TDUnitXConsoleLogger.Create(True);
    oEjecutor.AddLogger(oLogger);
    oResultados := oEjecutor.Execute;
    if oResultados.AllPassed then
      ExitCode := 0
    else
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
