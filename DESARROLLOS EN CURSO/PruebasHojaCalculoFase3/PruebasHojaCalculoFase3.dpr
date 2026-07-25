program PruebasHojaCalculoFase3;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  inLibHojaCalculoIntf in '..\..\src\Lib\inLibHojaCalculoIntf.pas',
  inLibHojaCalculoUtil in '..\..\src\Lib\inLibHojaCalculoUtil.pas',
  inLibHojaCalculoDevEx in '..\..\src\Lib\inLibHojaCalculoDevEx.pas',
  inLibDevExcel in '..\..\src\Lib\inLibDevExcel.pas',
  inLibInventarioExcel in '..\..\src\Lib\inLibInventarioExcel.pas',
  inLibHojaCalculoFalso in
    '..\PruebasHojaCalculoFase1\inLibHojaCalculoFalso.pas',
  inLibInventarioImportTests in 'inLibInventarioImportTests.pas';

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
