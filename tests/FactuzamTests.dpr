program FactuzamTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  Datasnap.DBClient,
  MidasLib,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  inLibAtributosPaleta in
    '..\src\Lib\inLibAtributosPaleta.pas',
  inLibColumnasDocumento in
    '..\src\Lib\inLibColumnasDocumento.pas',
  inLibBusquedasCompra in
    '..\src\Lib\inLibBusquedasCompra.pas',
  inLibValidacionDocumento in
    '..\src\Lib\inLibValidacionDocumento.pas',
  inLibPresentacionDocumento in
    '..\src\Lib\inLibPresentacionDocumento.pas',
  inLibShowMto in '..\src\Lib\inLibShowMto.pas',
  inLibImpuestosComun in '..\src\Lib\inLibImpuestosComun.pas',
  inLibComprasImpuestos in '..\src\Lib\inLibComprasImpuestos.pas',
  inLibVentasImpuestos in '..\src\Lib\inLibVentasImpuestos.pas',
  inLibRectificativas in '..\src\Lib\inLibRectificativas.pas',
  PruebasAtributosPaleta in 'PruebasAtributosPaleta.pas',
  PruebasColumnasDocumento in 'PruebasColumnasDocumento.pas',
  PruebasBusquedasCompra in 'PruebasBusquedasCompra.pas',
  PruebasValidacionTallasCompra in
    'PruebasValidacionTallasCompra.pas',
  PruebasPresentacionDocumento in
    'PruebasPresentacionDocumento.pas',
  PruebasNavegacionDocumento in
    'PruebasNavegacionDocumento.pas',
  PruebasImpuestosComun in 'PruebasImpuestosComun.pas',
  PruebasTotalesDocumentos in 'PruebasTotalesDocumentos.pas',
  PruebasRectificativas in 'PruebasRectificativas.pas';

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
