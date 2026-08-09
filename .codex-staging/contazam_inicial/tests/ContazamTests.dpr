program ContazamTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  MidasLib,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  inLibContabilidadTipos in
    '..\src\Lib\inLibContabilidadTipos.pas',
  inLibValidacionAsientos in
    '..\src\Lib\inLibValidacionAsientos.pas',
  PruebasValidacionAsientos in
    'PruebasValidacionAsientos.pas',
  inLibExportadorXlsx in
    '..\src\Lib\inLibExportadorXlsx.pas',
  PruebasExportadorXlsx in
    'PruebasExportadorXlsx.pas',
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  PruebasConfiguracion in
    'PruebasConfiguracion.pas',
  inLibDir in
    '..\src\Lib\inLibDir.pas',
  inLibLogIntf in
    '..\src\Lib\inLibLogIntf.pas',
  inLibLog in
    '..\src\Lib\inLibLog.pas',
  PruebasLog in
    'PruebasLog.pas',
  inLibLiteralesIntf in
    '..\src\Lib\inLibLiteralesIntf.pas',
  inLibLiterales in
    '..\src\Lib\inLibLiterales.pas',
  inLibLiteralesDataSet in
    '..\src\Lib\inLibLiteralesDataSet.pas',
  PruebasLiterales in
    'PruebasLiterales.pas';

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
