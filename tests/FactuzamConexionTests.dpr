program FactuzamConexionTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  PruebasPerfilConexion in 'PruebasPerfilConexion.pas',
  PruebasDialectosSql in 'PruebasDialectosSql.pas',
  PruebasCatalogoSqlMotores in 'PruebasCatalogoSqlMotores.pas',
  PruebasFabricaConexionUniDAC in 'PruebasFabricaConexionUniDAC.pas',
  PruebasProteccionDatosFacturacion in
    'PruebasProteccionDatosFacturacion.pas',
  PruebasGeneradorProcesosProteccion in
    'PruebasGeneradorProcesosProteccion.pas',
  PruebasRestauracionCopiasReglas in
    'PruebasRestauracionCopiasReglas.pas',
  PruebasCorreoValidacion in 'PruebasCorreoValidacion.pas';

const
  CODIGO_CORRECTO = 0;
  CODIGO_PRUEBAS_FALLIDAS = 1;
  CODIGO_ERROR_RUNNER = 2;

var
  oRunner: ITestRunner;
  oResultados: IRunResults;
  oLogger: ITestLogger;

begin
  System.ExitCode := CODIGO_ERROR_RUNNER;
  try
    TDUnitX.CheckCommandLine;
    oRunner := TDUnitX.CreateRunner;
    oRunner.UseRTTI := True;
    oRunner.FailsOnNoAsserts := False;
    oLogger := TDUnitXConsoleLogger.Create(True);
    oRunner.AddLogger(oLogger);
    oResultados := oRunner.Execute;
    if oResultados.AllPassed then
      System.ExitCode := CODIGO_CORRECTO
    else
      System.ExitCode := CODIGO_PRUEBAS_FALLIDAS;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Error del runner DUnitX: ', E.Message);
      System.ExitCode := CODIGO_ERROR_RUNNER;
    end;
  end;
end.
