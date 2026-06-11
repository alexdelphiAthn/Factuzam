program Fzam;

uses
//  {$IFDEF DEBUG}
//  FastMM4,
//  {$ENDIF}
  Forms,
  MidasLib,
  {$IF CompilerVersion >= 37.0}
  Vcl.Consts in 'src\vcl37\Vcl.Consts.pas',
  {$ELSE}
  {$IFDEF VER350}
  Vcl.Consts in 'src\vcl\Vcl.Consts.pas',
  {$ENDIF }
  {$ENDIF }
  Sysutils,
  Classes,
  dxCore,
  JclDebug,
  JclHookExcept,
  inLibDevExp in 'src\Lib\inLibDevExp.pas',
  inLibDir in 'src\Lib\inLibDir.pas',
  inLibGlobalVar in 'src\Lib\inLibGlobalVar.pas',
  inLibLog in 'src\Lib\inLibLog.pas',
  inLibDiag in 'src\Lib\inLibDiag.pas',
  inLibtb in 'src\Lib\inLibtb.pas',
  inLibUser in 'src\Lib\inLibUser.pas',
  inLibWin in 'src\Lib\inLibWin.pas',
  inLibShowMto in 'src\Lib\inLibShowMto.pas',
  inLibUnitForm in 'src\Lib\inLibUnitForm.pas',
  inLibMsg in 'src\Lib\inLibMsg.pas',
  inLibNet in 'src\Lib\inLibNet.pas',
  inLibScriptDB in 'src\Lib\inLibScriptDB.pas',
  inLibIBAN in 'src\Lib\inLibIBAN.pas',
  inLibFacturas in 'src\Lib\inLibFacturas.pas',
  inLibInformesGuiasCache in 'src\Lib\inLibInformesGuiasCache.pas',
  inLibGridColumnChooser in 'src\Lib\inLibGridColumnChooser.pas',
  inLibConfigCampos in 'src\Lib\inLibConfigCampos.pas',
  inLibPermisos in 'src\Lib\inLibPermisos.pas',
  inLibPermisosAdmin in 'src\Lib\inLibPermisosAdmin.pas',
  inMtoFrmBase in 'src\Core\inMtoFrmBase.pas' {frmBase},
  inMtoLogon in 'src\Core\inMtoLogon.pas' {frmLogon},
  inMtoPrincipal in 'src\Core\inMtoPrincipal.pas' {frmMtoPrincipal},
  inMtoGen in 'src\Forms\inMtoGen.pas' {frmMtoGen},
  inMtoFacturasBase in 'src\Forms\inMtoFacturasBase.pas' {frmMtoFacturasBase},
  inMtoFacturasNormal in 'src\Forms\inMtoFacturasNormal.pas' {frmMtoFacturasNormal},
  inMtoFacturasSimplif in 'src\Forms\inMtoFacturasSimplif.pas' {frmMtoFacturasSimplif},
  inMtoArticulos in 'src\Forms\inMtoArticulos.pas' {frmMtoArticulos},
  inMtoClientes in 'src\Forms\inMtoClientes.pas' {frmMtoClientes},
  inMtoContadores in 'src\Forms\inMtoContadores.pas' {frmMtoContadores},
  inMtoEmpresas in 'src\Forms\inMtoEmpresas.pas' {frmMtoEmpresas},
  inMtoFamilias in 'src\Forms\inMtoFamilias.pas' {frmMtoFamilias},
  inMtoFormasdePago in 'src\Forms\inMtoFormasdePago.pas' {frmMtoFormasdePago},
  inMtoGeneradorProcesos in 'src\Forms\inMtoGeneradorProcesos.pas' {frmMtoGeneradorProcesos},
  inMtoGenSearch in 'src\Forms\inMtoGenSearch.pas' {frmMtoSearch},
  inMtoEmpleados in 'src\Forms\inMtoEmpleados.pas' {frmMtoEmpleados},
  inMtoGrupos in 'src\Forms\inMtoGrupos.pas' {frmMtoGrupos},
  inMtoIvas in 'src\Forms\inMtoIvas.pas' {frmMtoIvas},
  inMtoIvasGrupos in 'src\Forms\inMtoIvasGrupos.pas' {frmMtoIvasGrupos},
  inMtoProveedores in 'src\Forms\inMtoProveedores.pas' {frmMtoProveedores},
  inMtoTarifas in 'src\Forms\inMtoTarifas.pas' {frmMtoTarifas},
  inMtoUsuarios in 'src\Forms\inMtoUsuarios.pas' {frmMtoUsuarios},
  inMtoUsuariosPerfiles in 'src\Forms\inMtoUsuariosPerfiles.pas' {frmMtoUsuariosPerfiles},
  inMtoPermisos in 'src\Forms\inMtoPermisos.pas' {frmMtoPermisos},
  inMtoPermisosArbol in 'src\Forms\inMtoPermisosArbol.pas' {frmMtoPermisosArbol},
  inMtoModalArtTar in 'src\Modals\inMtoModalArtTar.pas' {frmMtoModalArtTar},
  inMtoModalFacRec in 'src\Modals\inMtoModalFacRec.pas' {frmGenFacRec},
  inMtoModalGenFilter in 'src\Modals\inMtoModalGenFilter.pas' {frmModalGenFilter},
  inMtoModalGenImp in 'src\Modals\inMtoModalGenImp.pas' {frmPrint},
  inMtoModalGenImpEle in 'src\Modals\inMtoModalGenImpEle.pas' {frmMtoModalGenImpEle},
  inMtoModalGenImpSave in 'src\Modals\inMtoModalGenImpSave.pas' {frmModalGenImpSave},
  inMtoModalGuiasBase in 'src\Modals\inMtoModalGuiasBase.pas' {frmModalGuiasBase},
  inMtoModalInformesGuias in 'src\Modals\inMtoModalInformesGuias.pas' {frmModalInformesGuias},
  inMtoModalGridGuias in 'src\Modals\inMtoModalGridGuias.pas' {frmModalGridGuias},
  inMtoModalWizardEditar in 'src\Modals\inMtoModalWizardEditar.pas' {frmModalWizardEditar},
  inMtoModalGenPass in 'src\Modals\inMtoModalGenPass.pas' {frmModalGenPass},
  inMtoModalImpFac in 'src\Modals\inMtoModalImpFac.pas' {frmPrintFac},
  inMtoModalImpRecFac in 'src\Modals\inMtoModalImpRecFac.pas' {frmPrintRecFac},
  inMtoModalImpSesion in 'src\Modals\inMtoModalImpSesion.pas' {frmPrintSesion},
  inMtoModalImpAlbCompra in 'src\Modals\inMtoModalImpAlbCompra.pas' {frmPrintAlbCompra},
  inMtoModalImpAlbCompraV in 'src\Modals\inMtoModalImpAlbCompraV.pas' {frmPrintAlbCompraV},
  inMtoModalEtiqAlb in 'src\Modals\inMtoModalEtiqAlb.pas' {frmPrintEtiqArt: TfrmPrintEtiqAlb},
  inMtoModalImpDevCompra in 'src\Modals\inMtoModalImpDevCompra.pas' {frmPrintDevCompra},
  inMtoModalImpDevCompraV in 'src\Modals\inMtoModalImpDevCompraV.pas' {frmPrintDevCompraV},
  inMtoModalEtiqDev in 'src\Modals\inMtoModalEtiqDev.pas' {frmPrintEtiqArt: TfrmPrintEtiqDev},
  inMtoModalDistribuidor in 'src\Modals\inMtoModalDistribuidor.pas' {frmModalDistribuidor},
  inMtoModalDocsCreados in 'src\Modals\inMtoModalDocsCreados.pas' {frmModalDocsCreados},
  inMtoModalCliEti in 'src\Modals\inMtoModalCliEti.pas' {frmPrintCliEti},
  inMtoModalEtiqArt in 'src\Modals\inMtoModalEtiqArt.pas' {frmPrintEtiqArt},
  inMtoModalImpMultiFiltro in 'src\Modals\inMtoModalImpMultiFiltro.pas' {frmPrintMultiFiltro},
  inMtoModalImpBalanceTallas in 'src\Modals\inMtoModalImpBalanceTallas.pas' {frmPrintBalanceTallas},
  inMtoModalImpBalanceSinTallas in 'src\Modals\inMtoModalImpBalanceSinTallas.pas' {frmPrintBalanceSinTallas},
  inMtoModalImpMovVentasArt in 'src\Modals\inMtoModalImpMovVentasArt.pas' {frmPrintMovVentasArt},
  inMtoSplash in 'src\Core\inMtoSplash.pas' {frmSplash},
  UniDataConn in 'src\DataModules\UniDataConn.pas' {dmConn: TDataModule},
  UniDataGen in 'src\DataModules\UniDataGen.pas' {dmBase: TDataModule},
  UniDataArticulos in 'src\DataModules\UniDataArticulos.pas' {dmArticulos: TdmArticulos},
  UniDataClientes in 'src\DataModules\UniDataClientes.pas' {dmClientes: TdmClientes},
  UniDataContadores in 'src\DataModules\UniDataContadores.pas' {dmContadores: dmContadores},
  UniDataEmpresas in 'src\DataModules\UniDataEmpresas.pas' {dmEmpresas: TdmEmpresas},
  UniDataFamilias in 'src\DataModules\UniDataFamilias.pas' {dmFamilias1. TdmFamilias},
  UniDataFormasdePago in 'src\DataModules\UniDataFormasdePago.pas' {dmFormasdePago: TdmFormasdePago},
  UniDataGeneradorProcesos in 'src\DataModules\UniDataGeneradorProcesos.pas' {dmGeneradorProcesos: TDataModule},
  UniDataEmpleados in 'src\DataModules\UniDataEmpleados.pas' {dmEmpleados: TDataModule},
  UniDataGrupos in 'src\DataModules\UniDataGrupos.pas' {dmGrupos: TDataModule},
  UniDataIvas in 'src\DataModules\UniDataIvas.pas' {dmIvas: TDataModule},
  UniDataIvasGrupos in 'src\DataModules\UniDataIvasGrupos.pas' {dmIvasGrupos: TDataModule},
  UniDataPerfiles in 'src\DataModules\UniDataPerfiles.pas' {dmPerfiles: TDataModule},
  UniDataProveedores in 'src\DataModules\UniDataProveedores.pas' {dmProveedores: TDataModule},
  UniDataTarifas in 'src\DataModules\UniDataTarifas.pas' {dmTarifas: TDataModule},
  UniDataUsuarios in 'src\DataModules\UniDataUsuarios.pas' {dmUsuarios: TDataModule},
  UniDataUsuariosPerfiles in 'src\DataModules\UniDataUsuariosPerfiles.pas' {dmUsuariosPerfiles: TDataModule},
  UniDataPermisosGrupo in 'src\DataModules\UniDataPermisosGrupo.pas' {dmPermisosGrupo: TDataModule},
  UniDataFacturas in 'src\DataModules\UniDataFacturas.pas' {dmFacturas: TdmFacturas},
  UniDataGenFilter in 'src\DataModules\UniDataGenFilter.pas' {dmGenFilter: TDataModule},
  inMtoPedidos in 'src\Forms\inMtoPedidos.pas' {frmMtoPedidos},
  UniDataPedidos in 'src\DataModules\UniDataPedidos.pas' {/cxButtonHelper in 'cxButtonHelper.pas';: TdmPedidos},
  inMtoPaises in 'src\Forms\inMtoPaises.pas' {frmMtoPaises},
  UniDataPaises in 'src\DataModules\UniDataPaises.pas' {dmPaises: TDataModule},
  inMtoUnidadesMedida in 'src\Forms\inMtoUnidadesMedida.pas' {frmMtoUnidadesMedida},
  UniDataUnidadesMedida in 'src\DataModules\UniDataUnidadesMedida.pas' {dmUnidadesMedida: TDataModule},
  inLibCertificates in 'src\Lib\inLibCertificates.pas',
  inMtoModalEmpCer in 'src\Modals\inMtoModalEmpCer.pas',
  inMtoCajaMenu in 'src\Caja\Forms\inMtoCajaMenu.pas' {frmMtoMenuCaja},
  inMtoCajaOpe in 'src\Caja\Forms\inMtoCajaOpe.pas' {frmMtoOpeCaja},
  UniDataCaja in 'src\Caja\DataModules\UniDataCaja.pas' {dmCajaOpe},
  inMtoTraspasoOpe in 'src\Caja\Forms\inMtoTraspasoOpe.pas' {frmMtoOpeTraspaso},
  UniDataTraspaso in 'src\Caja\DataModules\UniDataTraspaso.pas' {dmTraspaso: TDataModule},
  inLibTraspasoTicket in 'src\Caja\Lib\inLibTraspasoTicket.pas',
  inLibGridArticulos in 'src\Lib\inLibGridArticulos.pas',
  inLibLectorScanner in 'src\Lib\inLibLectorScanner.pas',
  inMtoCajaFaseCobro in 'src\Caja\Forms\inMtoCajaFaseCobro.pas' {frmMtoCajaFaseCobro},
  inMtoCajaFormasPago in 'src\Caja\Forms\inMtoCajaFormasPago.pas' {frmMtoCajaFormasPago},
  UniDataCajaFormasPago in 'src\Caja\DataModules\UniDataCajaFormasPago.pas' {dmCajaFormasPago: TdmCajaFormasPago},
  inLibDefaultValues in 'src\Lib\inLibDefaultValues.pas',
  inLibGenBusq in 'src\Lib\inLibGenBusq.pas',
  inMtoAlmacenes in 'src\Forms\inMtoAlmacenes.pas' {frmMtoAlmacenes},
  UniDataAlmacenes in 'src\DataModules\UniDataAlmacenes.pas' {dmAlmacenes: TDataModule},
  inMtoModalCajDef in 'src\Modals\inMtoModalCajDef.pas' {frmMtoModalCajDef},
  inLibFormManager in 'src\Lib\inLibFormManager.pas',
  inMtoPreviewExcel in 'src\Core\inMtoPreviewExcel.pas' {frmMtoPreviewExcel},
  inLibDevExcel in 'src\Lib\inLibDevExcel.pas',
  inLibdxSpreadSheetStrs_ESP in 'src\Lib\inLibdxSpreadSheetStrs_ESP.pas',
  inMtoCajaReferenciaPago in 'src\Caja\Forms\inMtoCajaReferenciaPago.pas' {frmCajaReferenciaPago},
  inLibFaseCobro in 'src\Caja\Lib\inLibFaseCobro.pas',
  inLibCriptoCurr in 'src\Lib\inLibCriptoCurr.pas',
  inLibDivCurr in 'src\Lib\inLibDivCurr.pas',
  inMtoCajaSeleccionVale in 'src\Caja\Forms\inMtoCajaSeleccionVale.pas' {frmMtoCajaSeleccionVale},
  inMtoCajaParam in 'src\Caja\Forms\inMtoCajaParam.pas' {frmMtoCajaParam},
  inLibCajaParam in 'src\Caja\Lib\inLibCajaParam.pas',
  inLibArqueo in 'src\Caja\Lib\inLibArqueo.pas',
  inLibArqueoTicket in 'src\Caja\Lib\inLibArqueoTicket.pas',
  inLibArqueoPersistencia in 'src\Caja\Lib\inLibArqueoPersistencia.pas',
  inLibGenerarTicketCaja in 'src\Caja\Lib\inLibGenerarTicketCaja.pas',
  inMtoModalArqueo in 'src\Caja\Modals\inMtoModalArqueo.pas' {frmModalArqueo},
  inMtoModalArqueosHistCaja in 'src\Caja\Modals\inMtoModalArqueosHistCaja.pas' {frmModalArqueosHistCaja},
  inMtoModalImpArqueos in 'src\Caja\Modals\inMtoModalImpArqueos.pas' {frmPrintArqueos},
  inMtoModalImpOperaciones in 'src\Caja\Modals\inMtoModalImpOperaciones.pas' {frmPrintOperaciones},
  inMtoModalImpPagos in 'src\Caja\Modals\inMtoModalImpPagos.pas' {frmPrintPagos},
  inMtoModalImpDepositos in 'src\Caja\Modals\inMtoModalImpDepositos.pas' {frmPrintDepositos},
  inMtoModalEntradaCambio in 'src\Modals\inMtoModalEntradaCambio.pas' {frmModalEntradaCambio},
  inMtoModalGastoCaja in 'src\Caja\Modals\inMtoModalGastoCaja.pas' {frmModalGastoCaja},
  inLibFacturaExcel in 'src\Lib\inLibFacturaExcel.pas',
  inLibDocCompraExcel in 'src\Lib\inLibDocCompraExcel.pas',
  inLibInventarioExcel in 'src\Lib\inLibInventarioExcel.pas',
  inLibBalanceTallasExcel in 'src\Lib\inLibBalanceTallasExcel.pas',
  inLibBalanceSinTallasExcel in 'src\Lib\inLibBalanceSinTallasExcel.pas',
  inLibMovVentasArtExcel in 'src\Lib\inLibMovVentasArtExcel.pas',
  inLibInventarioNube in 'src\Lib\inLibInventarioNube.pas',
  ts.core.sqlparser in 'src\Lib\sqlformatter\ts.core.sqlparser.pas',
  ts.core.sqlscanner in 'src\Lib\sqlformatter\ts.core.sqlscanner.pas',
  ts.core.sqltree in 'src\Lib\sqlformatter\ts.core.sqltree.pas',
  ts.core.utils in 'src\Lib\sqlformatter\ts.core.utils.pas',
  ts.editor.codeformatters in 'src\Lib\sqlformatter\ts.editor.codeformatters.pas',
  ts.editor.codeformatters.sql in 'src\Lib\sqlformatter\ts.editor.codeformatters.sql.pas',
  Backup.Engine in 'src\Lib\backup\Backup.Engine.pas',
  Core_Engine in 'src\Lib\backup\Core_Engine.pas',
  Core_Helpers in 'src\Lib\backup\Core_Helpers.pas',
  Providers_MySQL in 'src\Lib\backup\Providers_MySQL.pas',
  Providers_MySQL_Helpers in 'src\Lib\backup\Providers_MySQL_Helpers.pas',
  Core_Interfaces in 'src\Lib\backup\Core_Interfaces.pas',
  Backup.Types in 'src\Lib\backup\Backup.Types.pas',
  ScriptWriters in 'src\Lib\backup\ScriptWriters.pas',
  inLibEAN13 in 'src\Lib\inLibEAN13.pas',
  Vcl.Themes,
  Vcl.Styles,
  inLibArticulosPropiedades in 'src\Lib\inLibArticulosPropiedades.pas',
  inLibArticulosVariaciones in 'src\Lib\inLibArticulosVariaciones.pas',
  inMtoModalAceptCancel in 'src\Modals\inMtoModalAceptCancel.pas' {frmModalAceptCancel},
  inMtoModalGenerarSKUs in 'src\Modals\inMtoModalGenerarSKUs.pas' {frmMtoModalGenerarSKUS},
  inLibFTicket in 'src\Lib\inLibFTicket.pas',
  inMtoPreviewTicket in 'src\Core\inMtoPreviewTicket.pas' {frmMtoPreviewTicket},
  inLibBuscarImpresora in 'src\Lib\inLibBuscarImpresora.pas',
  DelphiZXIngQRCode in 'src\Lib3par\DelphiZXIngQRCode.pas',
  inLibGenerarTicket in 'src\Lib\inLibGenerarTicket.pas',
  inLibGenerarTicketBD in 'src\Lib\inLibGenerarTicketBD.pas',
  inLibData in 'src\Lib\inLibData.pas',
  inLibAppParam in 'src\Lib\inLibAppParam.pas',
  inLibUnidadesMedida in 'src\Lib\inLibUnidadesMedida.pas',
  inLibGridCantidad in 'src\Lib\inLibGridCantidad.pas',
  inMtoAppParam in 'src\Core\inMtoAppParam.pas' {frmMtoAppParam},
  inLibPathTokens in 'src\Lib\inLibPathTokens.pas',
  uGenericIfThen in 'src\Lib\uGenericIfThen.pas',
  UniDataConsultaOpe in 'src\DataModules\UniDataConsultaOpe.pas' {dmConsultaOpe: TDataModule},
  inMtoConsultaOpe in 'src\Forms\inMtoConsultaOpe.pas' {frmConsultaOpe},
  inLibVentasCalendario in 'src\Lib\inLibVentasCalendario.pas',
  inLibLayoutForm in 'src\Lib\inLibLayoutForm.pas',
  inMtoInventarios in 'src\Forms\inMtoInventarios.pas' {frmMtoInventarios},
  UniDataInventarios in 'src\DataModules\UniDataInventarios.pas' {dmInventarios: TDataModule},
  inMtoAtributosConjuntos in 'src\Forms\inMtoAtributosConjuntos.pas' {frmMtoAtributosConjuntos},
  UniDataAtributosConjuntos in 'src\DataModules\UniDataAtributosConjuntos.pas' {dmAtributosConjuntos: TDataModule},
  inMtoAtributosBasicos in 'src\Forms\inMtoAtributosBasicos.pas' {frmMtoAtributosBasicos},
  UniDataAtributosBasicos in 'src\DataModules\UniDataAtributosBasicos.pas' {dmAtributosBasicos: TDataModule},
  inMtoVariaciones in 'src\Forms\inMtoVariaciones.pas' {frmMtoVariaciones},
  UniDataVariaciones in 'src\DataModules\UniDataVariaciones.pas' {dmVariaciones: TdmVariaciones},
  inMtoPropiedades in 'src\Forms\inMtoPropiedades.pas' {frmMtoPropiedades},
  UniDataPropiedades in 'src\DataModules\UniDataPropiedades.pas' {dmPropiedades: TDataModule},
  inMtoPropiedadesValores in 'src\Forms\inMtoPropiedadesValores.pas' {frmMtoPropiedadesValores},
  UniDataPropiedadesValores in 'src\DataModules\UniDataPropiedadesValores.pas' {dmPropiedadesValores: TDataModule},
  inMtoMovimientosAlmacen in 'src\Forms\inMtoMovimientosAlmacen.pas' {frmMtoMovimientosAlmacen},
  UniDataMovimientosAlmacen in 'src\DataModules\UniDataMovimientosAlmacen.pas' {dmMovimientosAlmacen: TDataModule},
  inMtoDepositosCliente in 'src\Forms\inMtoDepositosCliente.pas' {frmMtoDepositosCliente},
  UniDataDepositosCliente in 'src\DataModules\UniDataDepositosCliente.pas' {dmDepositosCliente: TDataModule},
  inMtoAlbaranes in 'src\Forms\inMtoAlbaranes.pas' {frmMtoAlbaranes},
  UniDataAlbaranes in 'src\DataModules\UniDataAlbaranes.pas' {dmAlbaranes: TdmAlbaranes},
  inMtoAlbaranesCompra in 'src\Forms\inMtoAlbaranesCompra.pas' {frmMtoAlbaranesCompra},
  UniDataAlbaranesCompra in 'src\DataModules\UniDataAlbaranesCompra.pas' {dmAlbaranesCompra: TdmAlbaranesCompra},
  inMtoDevolucionesCompra in 'src\Forms\inMtoDevolucionesCompra.pas' {frmMtoDevolucionesCompra},
  UniDataDevolucionesCompra in 'src\DataModules\UniDataDevolucionesCompra.pas' {dmDevolucionesCompra: TdmDevolucionesCompra},
  inMtoFacturasCompra in 'src\Forms\inMtoFacturasCompra.pas' {frmMtoFacturasCompra},
  UniDataFacturasCompra in 'src\DataModules\UniDataFacturasCompra.pas' {dmFacturasCompra: TdmFacturasCompra},
  inMtoEfectosCompra in 'src\Forms\inMtoEfectosCompra.pas' {frmMtoEfectosCompra},
  UniDataEfectosCompra in 'src\DataModules\UniDataEfectosCompra.pas' {dmEfectosCompra: TdmEfectosCompra},
  inMtoRemesasCompra in 'src\Forms\inMtoRemesasCompra.pas' {frmMtoRemesasCompra},
  UniDataRemesasCompra in 'src\DataModules\UniDataRemesasCompra.pas' {dmRemesasCompra: TdmRemesasCompra},
  inMtoModalFacturarAlbaranes in 'src\Modals\inMtoModalFacturarAlbaranes.pas' {frmModalFacturarAlbaranes},
  inMtoModalCargarEfectosRemesa in 'src\Modals\inMtoModalCargarEfectosRemesa.pas' {frmModalCargarEfectosRemesa},
  inMtoModalRegistrarPago in 'src\Modals\inMtoModalRegistrarPago.pas' {frmModalRegistrarPago},
  inMtoModalVerPagosEfecto in 'src\Modals\inMtoModalVerPagosEfecto.pas' {frmModalVerPagosEfecto},
  inMtoPedidosCompra in 'src\Forms\inMtoPedidosCompra.pas' {frmMtoPedidosCompra},
  UniDataPedidosCompra in 'src\DataModules\UniDataPedidosCompra.pas' {dmPedidosCompra: TdmPedidosCompra},
  inMtoModalSelAlmacenPedido in 'src\Modals\inMtoModalSelAlmacenPedido.pas' {frmModalSelAlmacenPedido},
  inMtoModalSelAlmacenAlbaran in 'src\Modals\inMtoModalSelAlmacenAlbaran.pas' {frmModalSelAlmacenAlbaran},
  inLibPedidosCompra in 'src\Lib\inLibPedidosCompra.pas',
  inLibGridPivoteCompra in 'src\Lib\inLibGridPivoteCompra.pas',
  inMtoModalFacturarAlbaranesFechas in 'src\Modals\inMtoModalFacturarAlbaranesFechas.pas' {frmModalFacturarAlbaranesFechas},
  inMtoCajaOperacionesHist in 'src\Caja\Forms\inMtoCajaOperacionesHist.pas' {frmMtoCajaOperacionesHist},
  UniDataCajaOperacionesHist in 'src\Caja\DataModules\UniDataCajaOperacionesHist.pas' {dmCajaOperacionesHist: TDataModule},
  inMtoCajaArqueosHist in 'src\Caja\Forms\inMtoCajaArqueosHist.pas' {frmMtoCajaArqueosHist},
  UniDataCajaArqueosHist in 'src\Caja\DataModules\UniDataCajaArqueosHist.pas' {dmCajaArqueosHist: TDataModule},
  inMtoCajaPagosHist in 'src\Caja\Forms\inMtoCajaPagosHist.pas' {frmMtoCajaPagosHist},
  UniDataCajaPagosHist in 'src\Caja\DataModules\UniDataCajaPagosHist.pas' {dmCajaPagosHist: TDataModule},
  inMtoCajaValesHist in 'src\Caja\Forms\inMtoCajaValesHist.pas' {frmMtoCajaValesHist},
  UniDataCajaValesHist in 'src\Caja\DataModules\UniDataCajaValesHist.pas' {dmCajaValesHist: TDataModule},
  inMtoModalAddBlockBase in 'src\Modals\inMtoModalAddBlockBase.pas' {frmModalAddBlockBase},
  inMtoModalAddBlockInventario in 'src\Modals\inMtoModalAddBlockInventario.pas' {frmModalAddBlockInventario},
  inMtoModalAddBlockTarifa in 'src\Modals\inMtoModalAddBlockTarifa.pas' {frmModalAddBlockTarifa},
  inLibDBStructure in 'src\Lib\inLibDBStructure.pas',
  inLibBackupWorker in 'src\Lib\inLibBackupWorker.pas',
  UniDataComprasSesiones in 'src\DataModules\UniDataComprasSesiones.pas' {dmComprasSesiones: TdmComprasSesiones},
  inMtoComprasPlantillas in 'src\Forms\inMtoComprasPlantillas.pas' {frmMtoComprasPlantillas},
  inMtoModalSesionMaterializar in 'src\Modals\inMtoModalSesionMaterializar.pas' {frmModalSesionMaterializar},
  inMtoModalSesionDuplicado in 'src\Modals\inMtoModalSesionDuplicado.pas' {frmModalSesionDuplicado},
  inMtoModalIncidencias in 'src\Modals\inMtoModalIncidencias.pas' {frmModalIncidencias},
  inMtoModalCrearAlbaranSesion in 'src\Modals\inMtoModalCrearAlbaranSesion.pas' {frmModalCrearAlbaranSesion},
  inLibComprasSesiones in 'src\Lib\inLibComprasSesiones.pas',
  inLibGridTallasInline in 'src\Lib\inLibGridTallasInline.pas',
  inLibComprasSesionesMaterializar in 'src\Lib\inLibComprasSesionesMaterializar.pas',
  inLibAlbaranesCompraMovimientos in 'src\Lib\inLibAlbaranesCompraMovimientos.pas',
  inLibDevolucionesCompraMovimientos in 'src\Lib\inLibDevolucionesCompraMovimientos.pas',
  inLibContadorLineas in 'src\Lib\inLibContadorLineas.pas',
  inMtoModalAltaRapida in 'src\Modals\inMtoModalAltaRapida.pas' {frmMtoModalAltaRapida},
  inLibArticulosValidador in 'src\Lib\inLibArticulosValidador.pas',
  inLibArticulosResolver in 'src\Lib\inLibArticulosResolver.pas',
  inMtoModalAddPreciosTar in 'src\Modals\inMtoModalAddPreciosTar.pas' {frmMtoModalAddPreciosTar},
  inMtoModalCalcularMargen in 'src\Modals\inMtoModalCalcularMargen.pas' {frmModalCalcularMargen},
  inLibArticulosAtributosLookup in 'src\Lib\inLibArticulosAtributosLookup.pas',
  inLibAtributosPaleta in 'src\Lib\inLibAtributosPaleta.pas',
  inMtoModalScriptLog in 'src\Modals\inMtoModalScriptLog.pas' {frmMtoModalScriptLog},
  inLibPresta in 'src\Lib\inLibPresta.pas',
  inLibScanDateTime in 'src\Lib\inLibScanDateTime.pas',
  inMtoModalImportarPedidosPS in 'src\Modals\inMtoModalImportarPedidosPS.pas' {frmModalImportarPedidosPS},
  inLibPrestaImporter in 'src\Lib\inLibPrestaImporter.pas',
  inMtoModalSelFamilia in 'src\Modals\inMtoModalSelFamilia.pas' {frmModalSelFamilia},
  inLibFotos in 'src\Lib\inLibFotos.pas',
  inLibFotosNube in 'src\Lib\inLibFotosNube.pas',
  inMtoFotoArticulo in 'src\Forms\inMtoFotoArticulo.pas' {frmFotoArticulo},
  inMtoStockConsulta in 'src\Forms\inMtoStockConsulta.pas' {frmStockConsulta},
  inMtoModalFotoArticulo in 'src\Modals\inMtoModalFotoArticulo.pas',
  inMtoComprasSesiones in 'src\Forms\inMtoComprasSesiones.pas' {frmMtoComprasSesiones};

{$R *.res}
{$R fondo.res}

var
  frmLogon: TfrmLogon;
  AutoLoginSuccessful: Boolean;

begin
//  {$IFDEF DEBUG}
//      ReportMemoryLeaksOnShutdown := True;
//  {$ENDIF}
  // Tracking de excepciones con JCL: rellena E.StackTrace al lanzar
  // cualquier excepcion. AppException en inMtoPrincipal ya vuelca el
  // detalle (incluido el stack) al log y al modal del usuario.
  Include(JclStackTrackingOptions, stStack);
  Include(JclStackTrackingOptions, stStaticModuleList);
  JclStartExceptionTracking;
  TdxDiacriticStringOptions.ComparisonMode :=
                                   TdxDiacriticStringComparisonMode.Insensitive;
  TdxDiacriticStringOptions.NormalizationMode :=
                                     TdxDiacriticStringNormalizationMode.System;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Fzam';
  frmLogon := TfrmLogon.Create(Application);
  try
    AutoLoginSuccessful := False;
    if (frmLogon.IsInitializeAuto) then
    begin
      frmLogon.btnAceptarClick(nil);
      AutoLoginSuccessful := (frmLogon.sSuccess = 'S');
    end;
    if (not AutoLoginSuccessful) then
    begin
      frmLogon.ShowModal;
      //frmLogon.Caption := Application.Title;
    end;
    if (frmLogon.sSuccess <> 'S') then
      Exit;
  finally
    frmLogon.Free;
  end;
  // Fuente global para toda la aplicacion
  Application.DefaultFont.Name   := 'Lucida Sans';
  Application.DefaultFont.Height := -15;
  Screen.MenuFont.Name := 'Lucida Sans';
  Screen.MenuFont.Size := 11;
  Application.CreateForm(TfrmMtoPrincipal, frmMtoPrincipal);
  // Diagnóstico: con /teststack se encola una excepción de prueba
  // para verificar JCL stack trace + AppException + log + modal.
  if FindCmdLineSwitch('teststack', True) then
    TThread.ForceQueue(nil, procedure
                            begin
                              inLibDiag.ProbarStackTrace;
                            end);
  Application.Run;
end.
