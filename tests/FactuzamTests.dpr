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
  inLibFiltroUsuario in
    '..\src\Lib\inLibFiltroUsuario.pas',
  inLibGestorFiltrosMto in
    '..\src\Lib\inLibGestorFiltrosMto.pas',
  inLibGestorPerfilesMto in
    '..\src\Lib\inLibGestorPerfilesMto.pas',
  inLibGestorGuiasGridMto in
    '..\src\Lib\inLibGestorGuiasGridMto.pas',
  inLibGestorTareasMto in
    '..\src\Lib\inLibGestorTareasMto.pas',
  inLibGestorArticulosMto in
    '..\src\Lib\inLibGestorArticulosMto.pas',
  inLibDiag in '..\src\Lib\inLibDiag.pas',
  inLibCadenas in '..\src\Lib\inLibCadenas.pas',
  inLibCifrado in '..\src\Lib\inLibCifrado.pas',
  inLibConfiguracionIni in
    '..\src\Lib\inLibConfiguracionIni.pas',
  inLibDocumentoFiscal in
    '..\src\Lib\inLibDocumentoFiscal.pas',
  inLibIBAN in '..\src\Lib\inLibIBAN.pas',
  inLibConexionesIntf in
    '..\src\Lib\inLibConexionesIntf.pas',
  inLibConexionesUniDAC in
    '..\src\Lib\inLibConexionesUniDAC.pas',
  inLibDatasets in '..\src\Lib\inLibDatasets.pas',
  inLibValoresAutomaticos in
    '..\src\Lib\inLibValoresAutomaticos.pas',
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
  inLibComprasSesionesReglas in
    '..\src\Lib\inLibComprasSesionesReglas.pas',
  inLibPerfilesUsuarioValores in
    '..\src\Lib\inLibPerfilesUsuarioValores.pas',
  PruebasAtributosPaleta in 'PruebasAtributosPaleta.pas',
  PruebasColumnasDocumento in 'PruebasColumnasDocumento.pas',
  PruebasFiltroUsuario in 'PruebasFiltroUsuario.pas',
  PruebasGestorFiltrosMto in 'PruebasGestorFiltrosMto.pas',
  PruebasGestorPerfilesMto in 'PruebasGestorPerfilesMto.pas',
  PruebasGestorGuiasGridMto in 'PruebasGestorGuiasGridMto.pas',
  PruebasGestorTareasMto in 'PruebasGestorTareasMto.pas',
  PruebasGestorArticulosMto in 'PruebasGestorArticulosMto.pas',
  PruebasDiagnosticoMetadata in 'PruebasDiagnosticoMetadata.pas',
  PruebasCadenas in 'PruebasCadenas.pas',
  PruebasCifrado in 'PruebasCifrado.pas',
  PruebasConfiguracionIni in 'PruebasConfiguracionIni.pas',
  PruebasIdentificacionFiscalBancaria in
    'PruebasIdentificacionFiscalBancaria.pas',
  PruebasConexiones in 'PruebasConexiones.pas',
  PruebasDatasets in 'PruebasDatasets.pas',
  PruebasValoresAutomaticos in
    'PruebasValoresAutomaticos.pas',
  PruebasBusquedasCompra in 'PruebasBusquedasCompra.pas',
  PruebasValidacionTallasCompra in
    'PruebasValidacionTallasCompra.pas',
  PruebasPresentacionDocumento in
    'PruebasPresentacionDocumento.pas',
  PruebasNavegacionDocumento in
    'PruebasNavegacionDocumento.pas',
  PruebasImpuestosComun in 'PruebasImpuestosComun.pas',
  PruebasTotalesDocumentos in 'PruebasTotalesDocumentos.pas',
  PruebasRectificativas in 'PruebasRectificativas.pas',
  PruebasReglasCompartidas in 'PruebasReglasCompartidas.pas';

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
