program FactuzamTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  Datasnap.DBClient,
  MidasLib,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  inLibImpuestosComun in '..\src\Lib\inLibImpuestosComun.pas',
  inLibComprasImpuestos in '..\src\Lib\inLibComprasImpuestos.pas',
  inLibVentasImpuestos in '..\src\Lib\inLibVentasImpuestos.pas',
  PruebasImpuestosComun in 'PruebasImpuestosComun.pas',
  PruebasTotalesDocumentos in 'PruebasTotalesDocumentos.pas';

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
