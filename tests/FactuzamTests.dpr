program FactuzamTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  Datasnap.DBClient,
  MidasLib,
  // Registro explicito del proveedor MySQL para las pruebas de
  // conexiones: antes llegaba por arrastre de un uses retirado
  // en la Fase 2b (inLibGridColumnChooser -> UniDataConn).
  MySQLUniProvider,
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
  inLibGestorCopiaLineasCompra in
    '..\src\Lib\inLibGestorCopiaLineasCompra.pas',
  inLibDiag in '..\src\Lib\inLibDiag.pas',
  inLibCadenas in '..\src\Lib\inLibCadenas.pas',
  inLibCifrado in '..\src\Lib\inLibCifrado.pas',
  inLibCifradoCopias in
    '..\src\Lib\inLibCifradoCopias.pas',
  inLibCopiasSeguridadIntf in
    '..\src\Lib\inLibCopiasSeguridadIntf.pas',
  inLibCopiasSeguridadReglas in
    '..\src\Lib\inLibCopiasSeguridadReglas.pas',
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
  inLibDocumentoIntf in
    '..\src\Lib\inLibDocumentoIntf.pas',
  inLibDocumento in
    '..\src\Lib\inLibDocumento.pas',
  inLibValidacionDocumento in
    '..\src\Lib\inLibValidacionDocumento.pas',
  inLibPresentacionDocumento in
    '..\src\Lib\inLibPresentacionDocumento.pas',
  inLibFacturasCobrosPresentacion in
    '..\src\Lib\inLibFacturasCobrosPresentacion.pas',
  inLibFacturasEstadoFiscalPresentacion in
    '..\src\Lib\inLibFacturasEstadoFiscalPresentacion.pas',
  inLibFacturasOperacionFiscal in
    '..\src\Lib\inLibFacturasOperacionFiscal.pas',
  inLibFacturasConsolidacionPresentacion in
    '..\src\Lib\inLibFacturasConsolidacionPresentacion.pas',
  inLibShowMto in '..\src\Lib\inLibShowMto.pas',
  inLibImpuestosComun in '..\src\Lib\inLibImpuestosComun.pas',
  inLibComprasImpuestos in '..\src\Lib\inLibComprasImpuestos.pas',
  inLibVentasImpuestos in '..\src\Lib\inLibVentasImpuestos.pas',
  inLibMotorFiscalVenta in
    '..\src\Lib\inLibMotorFiscalVenta.pas',
  inLibSqlSeguro in '..\src\Lib\inLibSqlSeguro.pas',
  inLibRectificativas in '..\src\Lib\inLibRectificativas.pas',
  inLibArticulosFiltro in '..\src\Lib\inLibArticulosFiltro.pas',
  inLibArticulosAltaTarifas in
    '..\src\Lib\inLibArticulosAltaTarifas.pas',
  inLibStockCeldaDocumento in
    '..\src\Lib\inLibStockCeldaDocumento.pas',
  inLibCajaTipos in '..\src\Caja\Lib\inLibCajaTipos.pas',
  inLibFaseCobro in '..\src\Caja\Lib\inLibFaseCobro.pas',
  inLibCajaVentaIntf in '..\src\Caja\Lib\inLibCajaVentaIntf.pas',
  inLibCajaVentaCliente in
    '..\src\Caja\Lib\inLibCajaVentaCliente.pas',
  inLibCajaVentaOperacion in
    '..\src\Caja\Lib\inLibCajaVentaOperacion.pas',
  inLibCajaDescuentos in '..\src\Caja\Lib\inLibCajaDescuentos.pas',
  inLibCajaRectificacion in
    '..\src\Caja\Lib\inLibCajaRectificacion.pas',
  inLibCajaCierreVenta in '..\src\Caja\Lib\inLibCajaCierreVenta.pas',
  inLibComprasSesionesReglas in
    '..\src\Lib\inLibComprasSesionesReglas.pas',
  inLibCatalogoSqlIntf in
    '..\src\Lib\inLibCatalogoSqlIntf.pas',
  inLibCatalogoSqlValidacion in
    '..\src\Lib\inLibCatalogoSqlValidacion.pas',
  inLibCatalogoSqlPerfiles in
    '..\src\Lib\inLibCatalogoSqlPerfiles.pas',
  inLibCatalogoSqlAdmin in
    '..\src\Lib\inLibCatalogoSqlAdmin.pas',
  inLibCatalogoSqlRegistro in
    '..\src\Lib\inLibCatalogoSqlRegistro.pas',
  inLibCatalogoSqlIncidencias in
    '..\src\Lib\inLibCatalogoSqlIncidencias.pas',
  inLibCatalogoSqlEjecucion in
    '..\src\Lib\inLibCatalogoSqlEjecucion.pas',
  inLibComprasSesionesIntf in
    '..\src\Lib\inLibComprasSesionesIntf.pas',
  inLibComprasSesionesCreacion in
    '..\src\Lib\inLibComprasSesionesCreacion.pas',
  inLibComprasSesionesMaterializacionIntf in
    '..\src\Lib\inLibComprasSesionesMaterializacionIntf.pas',
  inLibComprasSesiones in
    '..\src\Lib\inLibComprasSesiones.pas',
  inLibComprasSesionesMaterializar in
    '..\src\Lib\inLibComprasSesionesMaterializar.pas',
  UniDataComprasSesionesRepositorio in
    '..\src\DataModules\UniDataComprasSesionesRepositorio.pas',
  UniDataComprasSesionesUnidadTrabajo in
    '..\src\DataModules\UniDataComprasSesionesUnidadTrabajo.pas',
  UniDataVerifactuColaRepositorio in
    '..\src\verifactu\UniDataVerifactuColaRepositorio.pas',
  UniDataVerifactuNoVerifactuExport in
    '..\src\verifactu\UniDataVerifactuNoVerifactuExport.pas',
  UniDataVerifactuColaProcesador in
    '..\src\verifactu\UniDataVerifactuColaProcesador.pas',
  UniDataVerifactuColaResultados in
    '..\src\verifactu\UniDataVerifactuColaResultados.pas',
  UniDataVerifactuColaOperaciones in
    '..\src\verifactu\UniDataVerifactuColaOperaciones.pas',
  UniDataAlbaranesCompraMovimientos in
    '..\src\DataModules\UniDataAlbaranesCompraMovimientos.pas',
  UniDataDevolucionesCompraMovimientos in
    '..\src\DataModules\UniDataDevolucionesCompraMovimientos.pas',
  UniDataArticulosVariaciones in
    '..\src\DataModules\UniDataArticulosVariaciones.pas',
  UniDataFotosRepositorio in
    '..\src\DataModules\UniDataFotosRepositorio.pas',
  UniDataGridPivoteCompraRepositorio in
    '..\src\DataModules\UniDataGridPivoteCompraRepositorio.pas',
  UniDataPedidosCompraOperaciones in
    '..\src\DataModules\UniDataPedidosCompraOperaciones.pas',
  UniDataVentasWsJson in
    '..\src\DataModules\UniDataVentasWsJson.pas',
  UniDataCatalogoSqlValidacion in
    '..\src\DataModules\UniDataCatalogoSqlValidacion.pas',
  UniDataFacturasRepositorio in
    '..\src\DataModules\UniDataFacturasRepositorio.pas',
  UniDataFacturasLecturas in
    '..\src\DataModules\UniDataFacturasLecturas.pas',
  UniDataFacturaeRepositorio in
    '..\src\DataModules\UniDataFacturaeRepositorio.pas',
  UniDataCajaConsultasRepositorio in
    '..\src\Caja\DataModules\UniDataCajaConsultasRepositorio.pas',
  inLibArticulosResolverIntf in
    '..\src\Lib\inLibArticulosResolverIntf.pas',
  UniDataArticulosResolverRepositorio in
    '..\src\DataModules\UniDataArticulosResolverRepositorio.pas',
  inLibArticulosValidadorIntf in
    '..\src\Lib\inLibArticulosValidadorIntf.pas',
  UniDataArticulosValidadorRepositorio in
    '..\src\DataModules\UniDataArticulosValidadorRepositorio.pas',
  inLibArticulosAtributosIntf in
    '..\src\Lib\inLibArticulosAtributosIntf.pas',
  UniDataArticulosAtributosRepositorio in
    '..\src\DataModules\UniDataArticulosAtributosRepositorio.pas',
  inLibTraspasoTicketIntf in
    '..\src\Caja\Lib\inLibTraspasoTicketIntf.pas',
  UniDataTraspasoTicketRepositorio in
    '..\src\Caja\DataModules\UniDataTraspasoTicketRepositorio.pas',
  inLibArqueoIntf in
    '..\src\Caja\Lib\inLibArqueoIntf.pas',
  UniDataArqueoRepositorio in
    '..\src\Caja\DataModules\UniDataArqueoRepositorio.pas',
  inLibArqueoTicketIntf in
    '..\src\Caja\Lib\inLibArqueoTicketIntf.pas',
  UniDataArqueoTicketRepositorio in
    '..\src\Caja\DataModules\UniDataArqueoTicketRepositorio.pas',
  inLibTiraCajaTicketIntf in
    '..\src\Caja\Lib\inLibTiraCajaTicketIntf.pas',
  UniDataTiraCajaTicketRepositorio in
    '..\src\Caja\DataModules\UniDataTiraCajaTicketRepositorio.pas',
  inLibTicketsCajaIntf in
    '..\src\Caja\Lib\inLibTicketsCajaIntf.pas',
  UniDataTicketsCajaRepositorio in
    '..\src\Caja\DataModules\UniDataTicketsCajaRepositorio.pas',
  UniDataCatalogoSqlAplicacion in
    '..\src\DataModules\UniDataCatalogoSqlAplicacion.pas',
  inLibPerfilesUsuarioValores in
    '..\src\Lib\inLibPerfilesUsuarioValores.pas',
  inLibExcepcionesAplicacionIntf in
    '..\src\Lib\inLibExcepcionesAplicacionIntf.pas',
  inLibJsonSeguro in '..\src\Lib\inLibJsonSeguro.pas',
  inLibTraduccionesIntf in
    '..\src\Lib\inLibTraduccionesIntf.pas',
  inLibTraducciones in '..\src\Lib\inLibTraducciones.pas',
  inLibPivoteVentaCalculo in
    '..\src\Lib\inLibPivoteVentaCalculo.pas',
  inLibPivoteVentaIntf in
    '..\src\Lib\inLibPivoteVentaIntf.pas',
  inLibPivoteVentaModelo in
    '..\src\Lib\inLibPivoteVentaModelo.pas',
  PruebasAtributosPaleta in 'PruebasAtributosPaleta.pas',
  PruebasColumnasDocumento in 'PruebasColumnasDocumento.pas',
  PruebasFiltroUsuario in 'PruebasFiltroUsuario.pas',
  PruebasGestorFiltrosMto in 'PruebasGestorFiltrosMto.pas',
  PruebasGestorPerfilesMto in 'PruebasGestorPerfilesMto.pas',
  PruebasGestorGuiasGridMto in 'PruebasGestorGuiasGridMto.pas',
  PruebasGestorTareasMto in 'PruebasGestorTareasMto.pas',
  PruebasGestorArticulosMto in 'PruebasGestorArticulosMto.pas',
  PruebasGestorCopiaLineasCompra in
    'PruebasGestorCopiaLineasCompra.pas',
  PruebasDiagnosticoMetadata in 'PruebasDiagnosticoMetadata.pas',
  PruebasCadenas in 'PruebasCadenas.pas',
  PruebasCifrado in 'PruebasCifrado.pas',
  PruebasCopiasSeguridad in 'PruebasCopiasSeguridad.pas',
  PruebasConfiguracionIni in 'PruebasConfiguracionIni.pas',
  PruebasIdentificacionFiscalBancaria in
    'PruebasIdentificacionFiscalBancaria.pas',
  PruebasConexiones in 'PruebasConexiones.pas',
  PruebasDatasets in 'PruebasDatasets.pas',
  PruebasValoresAutomaticos in
    'PruebasValoresAutomaticos.pas',
  PruebasBusquedasCompra in 'PruebasBusquedasCompra.pas',
  PruebasDocumento in 'PruebasDocumento.pas',
  PruebasCatalogoSql in 'PruebasCatalogoSql.pas',
  PruebasCatalogoSqlRepositorios in
    'PruebasCatalogoSqlRepositorios.pas',
  PruebasArticulosResolverCatalogo in
    'PruebasArticulosResolverCatalogo.pas',
  PruebasArticulosCatalogoSql22 in
    'PruebasArticulosCatalogoSql22.pas',
  PruebasArticulosAltaTarifas in
    'PruebasArticulosAltaTarifas.pas',
  PruebasStockCeldaDocumento in
    'PruebasStockCeldaDocumento.pas',
  PruebasCajaVentaCliente in
    'PruebasCajaVentaCliente.pas',
  PruebasCajaVentaOperacion in
    'PruebasCajaVentaOperacion.pas',
  PruebasTraspasoTicketCatalogo in
    'PruebasTraspasoTicketCatalogo.pas',
  PruebasArqueoCatalogo in
    'PruebasArqueoCatalogo.pas',
  PruebasArqueoTicketCatalogo in
    'PruebasArqueoTicketCatalogo.pas',
  PruebasTiraCajaTicketCatalogo in
    'PruebasTiraCajaTicketCatalogo.pas',
  PruebasTicketsCajaCatalogo in
    'PruebasTicketsCajaCatalogo.pas',
  DoblesComprasSesiones in
    'DoblesComprasSesiones.pas',
  PruebasComprasSesionesRepositorio in
    'PruebasComprasSesionesRepositorio.pas',
  PruebasComprasSesionesCreacion in
    'PruebasComprasSesionesCreacion.pas',
  DoblesPivoteVenta in 'DoblesPivoteVenta.pas',
  PruebasPivoteVenta in 'PruebasPivoteVenta.pas',
  PruebasValidacionTallasCompra in
    'PruebasValidacionTallasCompra.pas',
  PruebasPresentacionDocumento in
    'PruebasPresentacionDocumento.pas',
  PruebasNavegacionDocumento in
    'PruebasNavegacionDocumento.pas',
  PruebasImpuestosComun in 'PruebasImpuestosComun.pas',
  PruebasTotalesDocumentos in 'PruebasTotalesDocumentos.pas',
  PruebasSqlSeguro in 'PruebasSqlSeguro.pas',
  PruebasRectificativas in 'PruebasRectificativas.pas',
  PruebasReglasCompartidas in 'PruebasReglasCompartidas.pas',
  PruebasCajaVenta in 'PruebasCajaVenta.pas',
  PruebasFacturasServicios in 'PruebasFacturasServicios.pas',
  PruebasFacturasLecturas in 'PruebasFacturasLecturas.pas',
  PruebasFacturaePersistencia in 'PruebasFacturaePersistencia.pas',
  PruebasFacturasCobrosPresentacion in
    'PruebasFacturasCobrosPresentacion.pas',
  PruebasFacturasEstadoFiscalPresentacion in
    'PruebasFacturasEstadoFiscalPresentacion.pas',
  PruebasFacturasOperacionFiscal in
    'PruebasFacturasOperacionFiscal.pas',
  PruebasFacturasConsolidacionPresentacion in
    'PruebasFacturasConsolidacionPresentacion.pas',
  PruebasExcepcionesAplicacion in
    'PruebasExcepcionesAplicacion.pas',
  PruebasEmisionFiscal in 'PruebasEmisionFiscal.pas',
  PruebasAlbaranesCompraMovimientos in
    'PruebasAlbaranesCompraMovimientos.pas',
  PruebasDevolucionesCompraMovimientos in
    'PruebasDevolucionesCompraMovimientos.pas',
  PruebasArticulosVariaciones in
    'PruebasArticulosVariaciones.pas',
  PruebasFotosPersistencia in
    'PruebasFotosPersistencia.pas',
  PruebasGridPivoteCompraPersistencia in
    'PruebasGridPivoteCompraPersistencia.pas',
  PruebasPedidosCompra in 'PruebasPedidosCompra.pas',
  PruebasVentasWsJson in 'PruebasVentasWsJson.pas',
  PruebasVerifactuColaRepositorio in
    'PruebasVerifactuColaRepositorio.pas',
  PruebasExportacionNoVerifactuPersistencia in
    'PruebasExportacionNoVerifactuPersistencia.pas',
  PruebasJsonSeguro in 'PruebasJsonSeguro.pas',
  PruebasTraducciones in 'PruebasTraducciones.pas';

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
