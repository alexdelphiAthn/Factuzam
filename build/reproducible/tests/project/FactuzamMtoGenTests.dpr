program FactuzamMtoGenTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  PruebasInteraccionFiltrosMto in
    'PruebasInteraccionFiltrosMto.pas';

var
  Ejecutor: ITestRunner;
  Resultados: IRunResults;
  Logger: ITestLogger;
begin
  try
    Ejecutor := TDUnitX.CreateRunner;
    Ejecutor.UseRTTI := True;
    Logger := TDUnitXConsoleLogger.Create(True);
    Ejecutor.AddLogger(Logger);
    Resultados := Ejecutor.Execute;
    if Resultados.AllPassed then
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
