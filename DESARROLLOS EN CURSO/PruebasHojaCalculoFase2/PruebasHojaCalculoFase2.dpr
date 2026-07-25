program PruebasHojaCalculoFase2;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  MidasLib,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  inLibHojaCalculoIntf in '..\..\src\Lib\inLibHojaCalculoIntf.pas',
  inLibMovVentasArtExcel in '..\..\src\Lib\inLibMovVentasArtExcel.pas',
  inLibHojaCalculoFalso in
    '..\PruebasHojaCalculoFase1\inLibHojaCalculoFalso.pas',
  inLibMovVentasArtExcelTests in 'inLibMovVentasArtExcelTests.pas';

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
