{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsg                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal de compatibilidad para los catálogos de mensajes.        }
{    No añadir recursos nuevos; caduca al migrar el último consumidor.         }
{******************************************************************************}
unit inLibMsg;

interface

function SClassRttiNotFnd: string;
function SLocateNotFnd: string;
function SResWinFNotFnd: string;
function SCliToTbl: string;
function SEmpToTbl: string;
function SErrorDecryptPassBBDD: string;
function SErrorDecryptPass: string;
function SErrorAuthPass: string;
function SErrorPassMatch: string;
function SErrorPassMatchBBDD: string;
function SEnterPassBBDD: string;
function SScriptSuccess: string;
function SFailLoadScriptBBDD: string;
function SCreateSuccBBDD: string;
function SErrorCreateBBDD: string;
function SBBDDUpdateTo: string;
function SNotExistsUpBBDDFile: string;
function SAdviceUpdateBBDD: string;
function SPasswordBBDDChanged: string;
function SWantDefChgBBDD: string;
function SAdvMsg: string;
function SNoConnBBDD: string;
function SConnSuccBBDD: string;
function SGetPassBBDD: string;
function SConnFailBBDD: string;
function SErrorSentenciaScript: string;
function SSolicitudPassBBDD: string;
function SSolicitudNuevoPassBBDD: string;
function SScriptEjecutado: string;
function SScriptNoEjecutado: string;
function SErrorConexionServidorBBDD: string;
function SErrorEstructuraBBDD: string;
function SErrorConexionBBDD: string;
function SErrorInicioAutomatico: string;
function SLicenciaEstablecida: string;
function SLicenciaNoEstablecidaSinNif: string;
function SErrorEstablecerLicencia: string;
function SModoDemo: string;
function SCancelacionSolicitada: string;
function SPreguntaCancelarOperacion: string;
function SOperacionCancelada: string;
function SCopiaSeguridadGuardada: string;
function SErrorCrearCopiaSeguridad: string;
function SRestauracionCancelada: string;
function SErrorRestaurarCopiaSeguridad: string;
function SErrorContrasenaCopiaVacia: string;
function SErrorTipoRestauracionNoPermitido: string;
function SPreguntaReemplazarFichero: string;
function SCopiaSeguridadCancelada: string;
function SCargaScriptCancelada: string;
function SUsuarioNoExiste: string;
function SDescripcionParametroIdioma: string;
function SErrorContextoSesionFormularioNoConfigurado: string;
function SErrorServicioAuditoriaDatosNoConfigurado: string;
function SErrorProveedorEdicionParametrosNoConfigurado: string;
function SErrorParametrosAplicacionEditablesNoConfigurados: string;
function SInfoParametrosGuardados: string;
function SAvisoParametrosRestringidosIgnorados: string;
function SAvisoParametrosRestringidosNoGuardados: string;
function SInfoSinCambiosParametros: string;
function SInfoLayoutGuardado: string;
function SPreguntaSalirSinGuardar: string;
function SAvisoSinUsuariosParametrosGuardados: string;
function STituloCambiarUsuario: string;
function SSolicitudCambiarUsuario: string;
function SErrorUsuarioNoEncontrado: string;
function SErrorEnviarTicketImpresora: string;
function SAvisoSinComandosESCPOSImpresora: string;
function SInfoTicketEnviadoImpresora: string;
function SErrorImprimir: string;
function SAvisoSinComandosESCPOSPDF: string;
function SInfoPDFGuardado: string;
function SInfoPNGGuardado: string;
function SErrorContextoInicioSesionNoProporcionado: string;
function SErrorParametrosSinEstadoLicencia: string;
function SErrorParametrosAplicacionSinContratoEdicion: string;
function SErrorParametrosCajaSinContratoEdicion: string;
function SErrorServicioConexionesNoDisponible: string;
function SCertificadoQuedaMenosUnDia: string;
function SCertificadoQuedaUnDia: string;
function SCertificadoQuedanDias: string;
function SAvisoCertificadoCaducado: string;
function SAvisoCertificadoProximoCaducar: string;
function SAvisoCertificadosCaducidad: string;
function SAvisoCargaPermisosRestringidos: string;
function SInfoCopiaSeguridadGuardada: string;
function SAvisoRestauracionCancelada: string;
function SErrorEjecutarScript: string;
function SPreguntaSalirAplicacion: string;
function SPreguntaCopiaSeguridadAntesDDL: string;
function SPreguntaCopiaAntesRestaurarCifrada: string;
function SInfoScriptCancelado: string;
function SErrorAbrirDireccion: string;
function SAvisoAlbaranFacturado: string;
function SPreguntaBorrarAlbaran: string;
function SAvisoAlmacenSalidaAlbaranObligatorio: string;
function SErrorLineaAlbaranSinArticulo: string;
function SErrorCabeceraAlbaranSinGrabar: string;
function SErrorAsignarLineaAlbaran: string;
function SErrorContadorAlbaran: string;
function SAvisoAlmacenDestinoAlbaranCompraObligatorio: string;
function SAvisoAlbaranCompraFacturado: string;
function SPreguntaBorrarAlbaranCompra: string;
function SErrorContadorAlbaranCompra: string;
function SErrorCodigoSkuCodigoBarrasObligatorio: string;
function SErrorCampoCodigoBarrasAusente: string;
function SErrorCodigoSkuObligatorio: string;
function SErrorFilaCodigoBarrasInexistente: string;
function SErrorProveedorPrincipalArticulo: string;
function SErrorDescripcionArticulo: string;
function SPreguntaDesactivarTarifaSinPrecio: string;
function SPreguntaActivarTarifaConPrecio: string;
function SErrorTarifaFechasConcurrentes: string;
function SErrorAtributoBasicoObligatorio: string;
function SErrorCodigoAtributoBasicoObligatorio: string;
function SErrorNombreAtributoBasicoObligatorio: string;
function SErrorValorColeccionAtributosObligatorio: string;
function SPreguntaBorrarClienteConFacturas: string;
function SErrorRazonSocialCliente: string;
function SErrorCambiarFormatoSesion: string;
function SErrorEmpresaSesionObligatoria: string;
function SErrorSerieSesionObligatoria: string;
function SErrorContadorSesion: string;
function SErrorCodigoSerieEmpresa: string;
function SAvisoColacionSesion: string;
function SAvisoTimeoutServidor: string;
function SErrorBBDDDuplicado: string;
function SErrorBBDDCamposObligatorios: string;
function SErrorBBDDCampoDesconocido: string;
function SErrorBBDDTablaNoExiste: string;
function SErrorBBDDSinPermisos: string;
function SErrorBBDDClaveForaneaNoExiste: string;
function SErrorBBDDRegistroDependiente: string;
function SErrorBBDDDatoDemasiadoLargo: string;
function SErrorBBDDCredencialesIncorrectas: string;
function SErrorBBDDConexionServidor: string;
function SErrorBBDDConexionPerdida: string;
function SErrorBBDDConexionPerdidaConsulta: string;
function SErrorBBDDTimeoutBloqueo: string;
function SErrorBBDDDeadlock: string;
function SErrorBBDDTablaYaExiste: string;
function SErrorBBDDProcedimientoYaExiste: string;
function SErrorBBDDGenerico: string;
function SDetalleErrorMySQL: string;
function SErrorAbrirConsultaOpe: string;
function SErrorAlmacenSalidaDevolucionCompra: string;
function SAvisoDevolucionCompraFacturada: string;
function SPreguntaBorrarDevolucionCompra: string;
function SErrorCabeceraDevolucionCompraSinGrabar: string;
function SErrorContadorDevolucionCompra: string;
function SErrorTipoDestinoDocumentoTrabajo: string;
function SErrorDestinoCompartidoNoExiste: string;
function SErrorDestinoCompartirObligatorio: string;
function SErrorCompartirDocumentoTrabajoSoloPropietario: string;
function SErrorCabeceraDocumentoTrabajoSinGrabar: string;
function SErrorCompartirDocumentoTrabajoConsigoMismo: string;
function SErrorBorrarDocumentoTrabajoSoloPropietario: string;
function SErrorCambiarPropietarioDocumentoTrabajo: string;
function SErrorTituloDocumentoTrabajoObligatorio: string;
function SErrorBorrarLineasDocumentoTrabajoSoloPropietario: string;
function SErrorEditarLineasDocumentoTrabajoSoloPropietario: string;
function SErrorArticuloLineaDocumentoTrabajoObligatorio: string;
function SErrorSkuLineaDocumentoTrabajoObligatorio: string;
function SErrorDejarCompartirDocumentoTrabajoSoloPropietario: string;
function SErrorDestinoCompartidoObligatorio: string;
function SErrorBorrarEfectoCompraRemesado: string;
function SErrorBorrarEfectoCompraPagado: string;
function SErrorFusionarEfectosCompraEstado: string;
function SErrorFusionarEfectosCompraOrigen: string;
function SErrorFusionarEfectosCompraSinPendiente: string;
function SErrorBorrarEfectoVentaRemesado: string;
function SErrorBorrarEfectoVentaCobrado: string;
function SErrorFusionarEfectosVentaEstado: string;
function SErrorFusionarEfectosVentaOrigen: string;
function SErrorFusionarEfectosVentaSinPendiente: string;
function SPreguntaCambioCriticoEmpresa: string;
function SErrorPorcentajeRetencionEmpresa: string;
function SErrorRetencionesEmpresaConcurrentes: string;
function SErrorSerieEmpresa: string;
function SErrorIbanEmpresa: string;
function SPreguntaBorrarEmpresaConFacturas: string;
function SErrorRazonSocialEmpresa: string;
function SErrorCodigoEmpresa: string;
function SErrorOperacionIntracomunitariaClienteNoUE: string;
function SErrorOperacionExportacionClienteNoExtranjero: string;
function SErrorOperacionSinIvaConCuota: string;
function SErrorNifIvaClienteExtranjero: string;
function SErrorCalcularBorradorDetalle: string;
function SErrorCalculoBorrador: string;
function SErrorTipoIvaFactura: string;
function SErrorBorrarBorradorFase: string;
function SPreguntaBorrarFactura: string;
function SErrorBorrarBorradorEfectosCobrados: string;
function SErrorInsertarLineasCabeceraFactura: string;
function SErrorBorradorSinGrabarParaLineas: string;
function SErrorSerieFacturaOtraEmpresa: string;
function SErrorRazonSocialClienteBorrador: string;
function SErrorRazonSocialEmpresaBorrador: string;
function SErrorSerieBorradorObligatoria: string;
function SErrorPaisClienteEmpresaBorrador: string;
function SErrorFechaBorradorObligatoria: string;
function SErrorNifClienteFactura: string;
function SErrorNifEmpresaFactura: string;
function SErrorFechaFacturaAnteriorSerie: string;
function SAvisoFechaBorradorFutura: string;
function SErrorCabeceraBorradorSinGrabar: string;
function SErrorAsignarNumeroFactura: string;
function SAvisoHuecoNumeracionFactura: string;
function SErrorCerrarFacturaCompraSinLineas: string;
function SErrorBorrarFacturaCompraEfectosPagados: string;
function SPreguntaBorrarFacturaCompra: string;
function SErrorCabeceraFacturaCompraSinGrabar: string;
function SErrorContadorFacturaCompra: string;
function SAvisoPropiedadFamiliaDuplicada: string;
function SErrorNombreFamilia: string;
function SErrorFamiliaPadreIgualHija: string;
function SErrorServicioConexionesDatosNoConfigurado: string;
function SErrorContextoSesionFiltrosNoConfigurado: string;
function SErrorCodigoFacturaeFormaPago: string;
function SErrorDescripcionFormaPago: string;
function SErrorContextoSesionModuloDatosNoConfigurado: string;
function SErrorSerieInventarioObligatoria: string;
function SErrorContadorLineasInventarioNoInstalado: string;
function SErrorCabeceraInventarioSinGrabarParaReserva: string;
function SErrorCabeceraInventarioNoEncontrada: string;
function SErrorActualizarContadorLineasInventario: string;
function SErrorEmpresaCabeceraInventarioObligatoria: string;
function SErrorAlmacenCabeceraInventarioObligatorio: string;
function SErrorSerieCabeceraInventarioObligatoria: string;
function SErrorNumeroCabeceraInventarioObligatorio: string;
function SErrorAtributoLineaInventarioObligatorio: string;
function SPreguntaCrearSkuInventario: string;
function SErrorSkuInventarioNoExiste: string;
function SErrorEliminarLineasInventarioNoAbierto: string;
function SErrorAnadirLineaCabeceraInventario: string;
function SErrorRecalcularInventarioNoAbierto: string;
function SErrorAplicarInventarioNoAbierto: string;
function SErrorAplicarInventarioSinLineas: string;
function SErrorEliminarRegularizacionInventarioNoAplicado: string;
function SErrorCargarArticulosInventarioNoAbierto: string;
function SErrorCompletarInventarioNoAbierto: string;
function SErrorArticuloLineaInventarioObligatorio: string;
function SErrorAnadirSkusInventarioNoAbierto: string;
function SErrorValorAtributoSkuInventarioNoEncontrado: string;
function SErrorCodigoIva: string;
function SErrorGrupoIvaNoExiste: string;
function SErrorRangoFechasIva: string;
function SErrorDescripcionGrupoIva: string;
function SErrorCodigoGrupoIva: string;
function SErrorDosGruposIvaPredeterminados: string;
function SAvisoEdicionMovimientoAlmacen: string;
function SPreguntaBorrarPedidoVenta: string;
function SErrorLineaPedidoSinArticulo: string;
function SErrorCabeceraPedidoSinGrabar: string;
function SErrorAsignarLineaPedido: string;
function SAvisoAlmacenSalidaPedidoObligatorio: string;
function SAvisoClientePedidoObligatorio: string;
function SAvisoClientePedidoNoExiste: string;
function SAvisoAlmacenDestinoPedidoCompraObligatorio: string;
function SPreguntaBorrarPedidoCompra: string;
function SErrorContadorPedidoCompra: string;
function SErrorContextoSesionPerfilesNoConfigurado: string;
function SErrorProveedorKitsNoSeleccionado: string;
function SErrorProveedorKitsSinGrabar: string;
function SErrorCodigoKitProveedorObligatorio: string;
function SErrorNombreKitProveedorObligatorio: string;
function SErrorKitProveedorNoSeleccionadoParaTallas: string;
function SErrorTallaDestinoKitProveedorObligatoria: string;
function SErrorKitProveedorNoSeleccionado: string;
function SErrorSistemaTallasKitProveedorObligatorio: string;
function SErrorCodigoAutomaticoProveedor: string;
function SErrorOrdenAutomaticoProveedor: string;
function SErrorRemesaVentaNoSeleccionada: string;
function SErrorRemesaVentaNoEncontrada: string;
function SErrorRemesaVentaSinEfectosPendientes: string;
function SErrorGuardarCodigoAcreedorSepa: string;
function SErrorGuardarMandatoSepaCliente: string;
function SErrorNombreSesionCambioTarifaObligatorio: string;
function SErrorTarifaDestinoObligatoria: string;
function SErrorNombreUsuario: string;
function SErrorUsuarioCoincideGrupo: string;
function SErrorCodigoAtributoVariacionObligatorio: string;
function SErrorConexionPrincipalTrabajoNoDisponible: string;
function SErrorPrefijoEanSesionLargo: string;
function SErrorColorBasicoMaterializacionNoExiste: string;
function SErrorAlmacenSesionParaAlbaranCompra: string;
function SErrorAlmacenSesionParaPedidoCompra: string;
function SErrorAlmacenSesionParaPendienteRecibir: string;
function SAvisoSelectorConjuntoFilaNoImplementado: string;
function STituloNuevaFilaCompra: string;
function SSolicitudNombreFilaCompra: string;
function SAvisoConjuntoPivotCompraObligatorio: string;
function SErrorConjuntoPivotCompraNoExiste: string;
function STituloAnadirValorPivotCompra: string;
function SSolicitudNombreValorPivotCompra: string;
function SSolicitudOrdenValorPivotCompra: string;
function SErrorDistribuidorTallasNoRegistrado: string;
function SErrorInvarianteUnidadesTallas: string;
function SErrorAlmacenDistribucionTallasNoDisponible: string;
function SErrorArticuloSkuNoEncontrado: string;
function SAvisoArticuloSinAtributos: string;
function SErrorFactoriaTallasHorizontalObligatoria: string;
function SErrorOperacionCanceladaUsuario: string;
function SErrorRestauracionEstructuraIncompleta: string;
function SErrorNombreBBDDDestinoVacio: string;
function SErrorFicheroCopiaNoExiste: string;
function SErrorDesencriptarCopia: string;
function SErrorAlbaranCompraMovimientosNoEncontrado: string;
function SErrorAlbaranCompraMovimientosYaGenerados: string;
function SErrorAlbaranCompraSinCantidadParaMovimientos: string;
function SErrorDivisaNoEncontrada: string;
function SErrorHttpDivisas: string;
function SErrorRedDivisas: string;
function SErrorJsonDivisas: string;
function SErrorPruebaPilaJcl: string;
function SErrorDevolucionCompraMovimientosNoEncontrada: string;
function SErrorDevolucionCompraMovimientosYaGenerados: string;
function SErrorDevolucionCompraSinCantidadParaMovimientos: string;
function SErrorEmpresaSinAlmacenActivo: string;
function SErrorAlmacenDepositosEmpresaNoEncontrado: string;
function SErrorLimitePeticionesCripto: string;
function SErrorHttpCripto: string;
function SErrorRedCripto: string;
function SErrorJsonCripto: string;
function SPreguntaCrearDocumentoTrabajo: string;
function STituloAgregarDocumentoTrabajo: string;
function STituloNuevoDocumentoTrabajo: string;
function SSolicitudTituloDocumentoTrabajo: string;
function SErrorArticuloDocumentoTrabajoNoActivo: string;
function SErrorArticuloDocumentoTrabajoVariosSkus: string;
function SInfoUnidadAgregadaDocumentoTrabajo: string;
function STituloDocumentoTrabajo: string;
function SErrorArticuloNoExiste: string;
function SErrorEntradaArticuloVacia: string;
function SErrorCodigoBarrasNoEncontrado: string;
function SErrorArticuloEntradaNoEncontrado: string;
function SAvisoArticuloRequiereSku: string;
function SErrorArticuloVariacionSinSkusActivos: string;
function SErrorArticuloSinSkusActivos: string;
function SErrorSkuNoPerteneceArticulo: string;
function SErrorSesionCompraNoActiva: string;
function SErrorLineaArticuloSesionNoSeleccionada: string;
function SErrorLineaSesionSinNumero: string;
function SErrorSistemaTallasLineaSesionObligatorio: string;
function SErrorKitProveedorNoExiste: string;
function SErrorKitSinSistemaTallas: string;
function SErrorTallajeKitNoCoincide: string;
function SErrorGestorTallasNoInicializado: string;
function SErrorKitSinTallasDefinidas: string;
function SAvisoTallasKitSinCorrespondencia: string;
function SErrorTallasKitSinCorrespondencia: string;
function SErrorSesionIncidenciasSinDetalle: string;
function SErrorDataModuleSesionNoInicializado: string;
function SErrorSesionNoCerradaParaRevertir: string;
function SErrorRestauracionNoFinalizada: string;
function SErrorCodigoArticuloResolverObligatorio: string;
function SErrorArticuloResolverNoExiste: string;
function SAvisoArticuloResolverRequiereSku: string;
function STextoLineaIncidenciaSesion: string;
function STextoCabeceraIncidenciaSesion: string;
function SFormatoIncidenciaSesion: string;
function SErrorSesionInactivaIncidencia: string;
function STipoIncidenciaCabecera: string;
function SErrorEmpresaSesionFaltante: string;
function SErrorProveedorSesionFaltante: string;
function SErrorAlmacenSesionFaltante: string;
function SErrorSesionSinLineas: string;
function STipoIncidenciaDuplicadoInterno: string;
function SErrorCodigoDuplicadoInternoSesion: string;
function STipoIncidenciaDuplicado: string;
function SErrorCodigoDuplicadoSesion: string;
function STextoArticuloInactivoSesion: string;
function STipoIncidenciaCodigo: string;
function SErrorLineaSesionSinCodigo: string;
function STipoIncidenciaDescripcion: string;
function SErrorLineaSesionSinDescripcion: string;
function STipoIncidenciaCantidades: string;
function SErrorLineaMatrizSinCantidades: string;
function STipoIncidenciaSistemaTallas: string;
function SErrorLineaMatrizSinSistemaTallas: string;
function SErrorCodigoEanMinimo7Digitos: string;
function SErrorCodigoBarrasNoNumerico: string;
function SErrorCodigoEanMinimo12Digitos: string;
function SErrorFacturaeFaltaCampo: string;
function STextoNifParteFacturae: string;
function STextoRazonSocialParteFacturae: string;
function STextoDireccionParteFacturae: string;
function STextoCodigoPostalParteFacturae: string;
function STextoPoblacionParteFacturae: string;
function STextoProvinciaParteFacturae: string;
function SErrorDocumentoFiscalParteFacturae: string;
function SErrorFaltaCodigoDir3Facturae: string;
function SErrorCodigoDir3LargoFacturae: string;
function STextoEmpresaEmisoraFacturae: string;
function STextoClienteFacturae: string;
function STextoOficinaContableFacturae: string;
function STextoOrganoGestorFacturae: string;
function STextoUnidadTramitadoraFacturae: string;
function SErrorNombrePersonaFisicaFacturae: string;
function SErrorApellidosPersonaFisicaFacturae: string;
function SErrorCodigoPagoFacturaeInvalido: string;
function SErrorFacturaeNoExiste: string;
function SErrorFacturaeTipoVentaInvalido: string;
function SErrorFacturaeNoConsolidada: string;
function SErrorFacturaeFechaOficialFaltante: string;
function SErrorLineaFacturaeSinDescripcion: string;
function SErrorLineaFacturaeCantidadCero: string;
function SErrorFacturaeSinLineas: string;
function SErrorBasesFacturaeNoCuadran: string;
function SErrorTotalesFacturaeNoCuadran: string;
function SErrorEmitirFacturae: string;
function SErrorCertificadoFacturaeNoConfigurado: string;
function SErrorConexionFacturaeNoDisponible: string;
function SErrorFicheroSalidaFacturaeNoIndicado: string;
function SErrorPorcentajeIvaFueraRango: string;
function SErrorPrecioFacturaNegativo: string;
function SErrorRespuestaHttpFactuzamApi: string;
function SErrorFactuzamApiNoConfigurada: string;
function SInfoEventoFactuzamApiRecibido: string;
function SInfoConsultaFactuzamApiRealizada: string;
function SInfoDocumentoFactuzamApiGuardado: string;
function SInfoDocumentoFactuzamApiDescargado: string;
function SErrorImportarImagenCodec: string;
function SErrorGuardarFotoSinCodigoArticulo: string;
function SErrorFicheroOrigenFotoNoExiste: string;
function SErrorDirectorioFotosNoConfigurado: string;
function SErrorFotoNoRegistradaParaRotar: string;
function SErrorFotoSesionSinSerie: string;
function SErrorFotoSesionSinNumero: string;
function SErrorFotoSesionLineaInvalida: string;
function STextoParametroUrlFotosNube: string;
function STextoParametroTokenFotosNube: string;
function STextoParametroReferenciaFotosNube: string;
function STextoParametroCarpetaFotosNube: string;
function SErrorParametrosFotosNubeFaltantes: string;
function SErrorServidorFotosNubeHttp: string;
function SErrorConexionServidorFotosNube: string;
function SErrorAbrirImpresoraTicket: string;
function SErrorIniciarDocumentoImpresora: string;
function SErrorEscribirImpresora: string;
function SErrorEjecutorBusquedasNoRegistrado: string;
function SErrorOperacionCajaNoEncontrada: string;
function SErrorValoresAtributoNoDefinidos: string;
function SErrorColorCompraNoSeleccionado: string;
function SErrorConexionResolverColorCompra: string;
function SErrorColorBasicoCompraNoExiste: string;
function SErrorResolverColorCompra: string;
function SErrorArticuloSinSistemaTallasPivote: string;
function SErrorSistemaTallasSuperaMaximoPivote: string;
function SErrorSkuFueraSistemaTallasPivote: string;
function SErrorActivarPivoteTallas: string;
function SErrorActivarTallasHorizontalesParaColor: string;
function SErrorLineaActivaColorNoDisponible: string;
function SErrorColorCompraConCantidades: string;
function SErrorConsultaLineasCompraNoAbierta: string;
function SErrorLineaActivaColorNoEncontrada: string;
function SErrorLineaActivaCompraSinArticulo: string;
function SPreguntaEliminarLineaTallasVenta: string;
function SErrorArticuloSkuNoEncontradoSinDetalle: string;
function SPreguntaEliminarLineaSkuCantidadCero: string;
function SInfoLineaPedidoTallaNoExiste: string;
function SAvisoSistemaTallasSuperaMaximo: string;
function SErrorHojaCalculoNoActiva: string;
function SErrorControlHojaCalculoObligatorio: string;
function SErrorGuardarHojaCalculoControlObligatorio: string;
function SErrorIbanInvalido: string;
function SErrorPaisIbanInvalido: string;
function SErrorDigitoControlIbanInvalido: string;
function SErrorLongitudCuentaBancariaInvalida: string;
function SErrorCuentaBancariaInvalida: string;
function SErrorDigitoControlCuentaBancaria: string;
function SErrorPaisIbanInvalidoTipos: string;
function SErrorDigitoControlIbanInvalidoTipos: string;
function STextoParametroUrlInventarioNube: string;
function STextoParametroTokenInventarioNube: string;
function STextoParametroReferenciaInventarioNube: string;
function SErrorParametrosInventarioNubeFaltantes: string;
function SErrorServidorInventarioNubeHttp: string;
function SErrorConexionServidorInventarioNube: string;
function SErrorInventarioNubeSinIdRecuento: string;
function SErrorDialogoPermisosLayoutNoRegistrado: string;
function STextoResetearLayout: string;
function SInfoLayoutReseteado: string;
function SErrorLimiteDemoFacturas: string;
function SErrorNifEmpresaLicenciaNoConfigurado: string;
function SInfoLicenciaSinNifEmpresa: string;
function SErrorLicenciaNoEncontrada: string;
function SInfoLicenciaValida: string;
function SErrorLicenciaNifsNoCoinciden: string;
function SErrorAccesoFicheroLog: string;
function SErrorCrearMutexLog: string;
function SErrorParametrosAplicacionNoProporcionados: string;
function SErrorRespuestaFormateadorSqlVacia: string;
function SErrorRespuestaFormateadorSqlInesperada: string;
function SErrorServicioPerfilesNoProporcionado: string;
function SErrorCargarPerfilParametros: string;
function SErrorPedidoCompraSinPendientesAlmacen: string;
function SErrorAlmacenPedidoCompraNoSeleccionado: string;
function SErrorPedidoCompraSinCantidadesRecibir: string;
function SErrorContadorAlbaranCompraNoDisponible: string;
function SErrorCrearLineasAlbaranCompra: string;
function SInfoAlbaranCompraCreado: string;
function SErrorAlbaranCompraDestinoNoSeleccionado: string;
function SInfoLineasIncorporadasAlbaranCompra: string;
function SErrorIncorporarLineasAlbaranCompra: string;
function SInfoLineasIncorporadasAlbaranCompraConCantidad: string;
function SErrorConexionPermisosNoDisponible: string;
function SErrorPreviewExcelNoRegistrado: string;
function SErrorPreviewTicketNoRegistrado: string;
function SErrorRespuestaNtpNoValida: string;
function SInfoRelojFiscalCorrecto: string;
function SErrorRelojSistemaFueraMargenLegal: string;
function SErrorComprobarRelojFiscalNtp: string;
function SErrorContextoSinIban: string;
function SErrorContextoIbanNoValido: string;
function SErrorNifEmpresaAcreedorSepaNoValido: string;
function SErrorClienteSinMandatoSepa: string;
function STextoBancoCobroRemesa: string;
function SErrorConexionGenerarRemesaSepa: string;
function SErrorArchivoSalidaSepaNoIndicado: string;
function SErrorRemesaSinFechaCobro: string;
function SErrorBancoCobroRemesaNoEncontrado: string;
function SErrorBancoCobroSinCodigoAcreedorSepa: string;
function SErrorCodigoAcreedorSepaNoValido: string;
function SErrorEfectoSinNombreCliente: string;
function STextoClienteSepa: string;
function SErrorClienteSinFechaFirmaMandatoSepa: string;
function SErrorRecalcularTotalesFactura: string;
function SErrorGenerarContadorAutomatico: string;
function SErrorConexionBbddConExcepcion: string;
function SErrorNumeroCuentaInvalido: string;
function SErrorNifNoValido: string;
function SErrorLetraDniIncorrecta: string;
function SErrorServicioPerfilesUsuarioNoConfigurado: string;
function SErrorCrearSeleccionarDocumentoAntesLineas: string;
function SErrorCrearSeleccionarDocumentoAntesTallas: string;
function SErrorArticuloCursoSinSistemaTallas: string;
function SErrorAltaSeleccionarArticuloConTallas: string;
function SErrorArticuloSinSistemaTallasCompra: string;
function SErrorActivarTallasHorizontalesCompra: string;
function SErrorEncolarVentaWebservice: string;
function SErrorFacturaWebserviceNoExiste: string;
function SErrorExportarNoVerifactuSinCertificado: string;
function SErrorExportarNoVerifactuSinColumnasEventos: string;
function SErrorExportarNoVerifactuSinColumnasFacturacion: string;
function SErrorExportarNoVerifactuRegistrosSinFirma: string;
function SErrorConexionExportarNoVerifactu: string;
function SErrorArchivoBaseExportacionNoIndicado: string;
function STextoTipoError: string;
function STextoTipoAviso: string;
function SFormatoDetalleVerificacion: string;
function SErrorModoExportacionNoCoincide: string;
function SErrorXmlFirmadoNoLegible: string;
function SErrorFirmaEventoRaizIncorrecta: string;
function SErrorEventoFirmadoNoEncontrado: string;
function SErrorFirmaFacturaRaizIncorrecta: string;
function SErrorFirmaXadesNodoAeatIncorrecto: string;
function SErrorFirmaXadesSinCertificado: string;
function SErrorFirmaXadesSinSignedInfo: string;
function SErrorCanonicalizacionFirmaAeat: string;
function SErrorMetodoFirmaNoRsaSha256: string;
function SErrorReferenciasSignedInfo: string;
function SErrorReferenciaDocumentoFirmado: string;
function SErrorTransformacionFirmaEnveloped: string;
function SErrorDigestRegistroNoSha256: string;
function SErrorReferenciaSignedProperties: string;
function SErrorCanonicalizacionSignedProperties: string;
function SErrorDigestSignedPropertiesNoSha256: string;
function SErrorQualifyingPropertiesXades: string;
function SErrorSignedPropertiesXades: string;
function SErrorSigningCertificateXades: string;
function SErrorPoliticaFirmaAge: string;
function SErrorIdentificadorPoliticaAge: string;
function SErrorDigestPoliticaAgeNoSha1: string;
function SErrorDigestValuePoliticaAge: string;
function SErrorUrlPoliticaAge: string;
function SFormatoEtiquetaEvento: string;
function SErrorEventoHashPropioNoSha256: string;
function SAvisoEventoPrimerHashAnteriorNoCero: string;
function SErrorEventoHashAnteriorNoCoincide: string;
function SErrorEventoSinRegistroXmlFirmado: string;
function SErrorEventoHuellaNoCoincide: string;
function SErrorEventoFirmaGuardadaSinFirmaXml: string;
function SErrorEventoSinFirmaXades: string;
function SErrorEventoSignatureValueNoCoincide: string;
function SErrorEventoFirmaDigitalNoCoincide: string;
function STextoRegistroFacturaIndice: string;
function SFormatoEtiquetaFactura: string;
function SAvisoFacturaSinPeticionCompletaXml: string;
function SErrorFacturaHashPeticionNoCoincide: string;
function SErrorFacturaSinRegistroXmlFirmado: string;
function SErrorFacturaHashRegistroNoCoincide: string;
function SErrorFacturaGuardadaSinFirmaXml: string;
function SErrorFacturaSinFirmaDigitalXades: string;
function SErrorFacturaSignatureValueNoCoincide: string;
function STextoEventos: string;
function STextoFacturacion: string;
function SErrorFicheroEventosNoExiste: string;
function SErrorFicheroEventosRaizIncorrecta: string;
function SErrorFicheroEventosVacio: string;
function SErrorFicheroFacturacionNoExiste: string;
function SErrorFicheroFacturacionRaizIncorrecta: string;
function SErrorFicheroFacturacionVacio: string;
function SErrorVerificarEventos: string;
function SErrorVerificarFacturacion: string;
function SInfoVerificacionCorrecta: string;
function SFormatoModoActual: string;
function SResumenVerificacionNoVerifactu: string;
function SDepuracionComponenteNoTcxLabel: string;
function SDepuracionComponenteNoTcxTabSheet: string;
function SDepuracionComponenteNoTcxDbCheckBox: string;
function SDepuracionComponenteNoTcxButton: string;
function SDepuracionComponenteNoTcxGroupBox: string;
function SDepuracionComponenteNoTcxDbRadioGroup: string;
function SDepuracionComponenteNoSpeedButton: string;
function SDepuracionComponenteNoTcxRadioButton: string;
function SErrorImagenNoExiste: string;
function SErrorAbrirProveedorCriptografico: string;
function SErrorCrearHashCriptografico: string;
function SErrorCalcularHash: string;
function SErrorObtenerTamanoHash: string;
function SErrorObtenerValorHash: string;
function SErrorOperacionCriptografica: string;
function SErrorProveedorCertificadoSinSha256: string;
function STextoCertificadoTodaviaNoValido: string;
function STextoCertificadoCaducado: string;
function SErrorCertificadoNoVigente: string;
function SErrorCertificadoVigenteNoEncontrado: string;
function SErrorCertificadoEmpresaNoConfigurado: string;
function SErrorCrearHashSha256Firma: string;
function SErrorCargarDatosFirma: string;
function SErrorCalcularTamanoFirmaSha256: string;
function SErrorFirmarSha256: string;
function SErrorCalcularTamanoFirmaNCrypt: string;
function SErrorFirmaNCrypt: string;
function SErrorAbrirClavePrivadaCertificado: string;
function SErrorXmlMalFormadoCanonicalizar: string;
function SErrorElementoRaizXmlNoEncontrado: string;
function SErrorNombreNodoRaizNoDeterminado: string;
function SErrorCierreAperturaRaizNoEncontrado: string;
function SErrorCierreNodoRaizNoEncontrado: string;
function SErrorCierreNodoNoEncontrado: string;
function SErrorNifProductorEventoVerifactuInvalido: string;
function SErrorEmpresaEventosVerifactuNoConfigurada: string;
function SErrorNifEmisorEventoNoVerifactuInvalido: string;
function SErrorFacturaRequisitosFiscalesNoExiste: string;
function SErrorEmpresaSinNifEmisionFiscal: string;
function SErrorNifProductorVerifactuInvalido: string;
function SErrorCertificadoFiscalEmpresaNoUtilizable: string;
function SErrorFirmaCertificadoNoVerifactuDesactivada: string;
function SErrorCertificadoEventosNoVerifactuNoConfigurado: string;
function SErrorFirmarEventoNoVerifactu: string;
function SErrorRelojEventoNoVerifactu: string;
function SErrorColumnasFirmaFacturacionNoDisponibles: string;
function STextoRegistroFacturacionNoVerifactu: string;
function SErrorFirmaRegistroNoVerifactuObligatoria: string;
function SErrorNifProductorSoftwareVerifactuInvalido: string;
function SErrorFacturaExtranjeraSinNifIva: string;
function SErrorFacturaSinNifClienteValido: string;
function SErrorNifEmisorVerifactuInvalido: string;
function SErrorFacturaRegistroFiscalNoEncontrada: string;
function SAvisoQrPngNoGenerado: string;
function SErrorFacturaEnvioVerifactuNoEncontrada: string;
function SErrorRespuestaServicioInesperada: string;
function SErrorRespuestaHttpAeat: string;
function SErrorRespuestaRegistroAeat: string;
function SErrorEstadoEnvioAeat: string;
function SErrorServicioInstalacionHttp: string;
function SErrorReferenciaGlobalInstalacionFaltante: string;
function SErrorApiKeyInstalacionFaltante: string;
function SErrorServicioJsonInvalido: string;
function SErrorServicioSinNumeroInstalacion: string;
function SErrorServicioSinDatosDeclaracion: string;
function SErrorDeclaracionVersionNoSolicitada: string;
function SErrorDeclaracionSifIncorrecto: string;
function SErrorDeclaracionDescargadaVacia: string;
function SErrorPaginaPublicaHttp: string;
function SErrorDeclaracionWebserviceOtraVersion: string;
function SErrorDeclaracionPaginaPublicaOtraVersion: string;
function SErrorDeclaracionResponsableNoDisponible: string;
function SErrorEmpresaInstalacionSifNoConfigurada: string;
function SErrorEmpresaSinRazonSocial: string;
function SErrorNifEmpresaInstalacionInvalido: string;
function SErrorEmpresaSinNumeroInstalacionSif: string;
function SErrorNumeroInstalacionSifIncorrecto: string;
function SErrorNumeroInstalacionSinVersion: string;
function SErrorVersionNumeroInstalacionIncorrecta: string;
function SInfoExportacionNoVerifactuGenerada: string;
function SInfoVerificacionNoVerifactuCorrecta: string;
function SErrorVerificacionNoVerifactu: string;
function SPreguntaAbrirSeriesAlbaranVenta: string;
function SErrorAlbaranVentaNoAbierto: string;
function SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta: string;
function SPreguntaGrabarAlbaranVentaSinSku: string;
function SErrorAlbaranVentaNoInicializado: string;
function SErrorCrearSeleccionarAlbaranAntesLineas: string;
function SPreguntaEliminarLineaAlbaranVenta: string;
function SErrorAlbaranVentaSinLineas: string;
function SAvisoSeleccionarLineasBorradorAlbaran: string;
function SAvisoLineasAlbaranConBorrador: string;
function SPreguntaGenerarBorradorLineasAlbaran: string;
function SInfoBorradorFacturaCreado: string;
function SErrorCrearBorradorFactura: string;
function SPreguntaGenerarBorradorTodoAlbaran: string;
function SAvisoAlbaranSinPedidoVenta: string;
function SAvisoAlbaranSinBorrador: string;
function SErrorProveedorNoSeleccionadoBuscarArticulos: string;
function SErrorAlbaranCompraNoAbierto: string;
function SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra: string;
function SErrorAlbaranCompraNoInicializado: string;
function STextoAlbaranCompra: string;
function SPreguntaAbrirSeriesAlbaranCompra: string;
function SErrorAlbaranCompraSinImpresionActivo: string;
function SErrorAlbaranCompraNoActivo: string;
function SPreguntaGrabarAlbaranCompraSinSku: string;
function SErrorAlbaranCompraNecesarioElegirEmpresa: string;
function SErrorAlbaranCompraNecesarioElegirProveedor: string;
function SErrorArticuloNoSeleccionadoElegirColor: string;
function SErrorArticuloSinColoresBasicosActivos: string;
function SAvisoAlbaranCompraSinPedido: string;
function SAvisoAlbaranCompraSinFactura: string;
function SPreguntaEliminarLineaAlbaranCompra: string;
function SErrorArticuloSinTipoVariacion: string;
function SErrorPrecioTarifaNoSeleccionado: string;
function SErrorPrecioTarifaNoGuardado: string;
function SAvisoRevisionArticulo: string;
function SErrorGuardarPropiedadesArticulo: string;
function SErrorGuardarVariacionesArticulo: string;
function SPreguntaReconstruirStock: string;
function STituloReconstruirStock: string;
function SErrorReconstruirStock: string;
function SInfoStockReconstruido: string;
function SErrorArticuloNoSeleccionadoImprimirEtiquetas: string;
function SErrorArticuloNoSeleccionadoGenerarCodigos: string;
function SErrorArticuloSinSkusActivosGenerarCodigos: string;
function SPreguntaGenerarCodigosBarras: string;
function SInfoGeneracionCodigosBarras: string;
function SErrorArticuloNoSeleccionadoVerificarCodigos: string;
function SErrorDetalleCodigoBarrasInvalido: string;
function SInfoVerificacionCodigosBarrasCorrecta: string;
function SAvisoVerificacionCodigosBarras: string;
function SInfoPrecargaArticuloGuardada: string;
function STextoAtributoBasicoSinValor: string;
function SPreguntaCrearAtributoBasicoSku: string;
function STituloCrearAtributoBasico: string;
function SErrorSkuColorNoSeleccionado: string;
function STextoActivarSkusColor: string;
function STextoDesactivarSkusColor: string;
function SPreguntaCambiarActivoSkusColor: string;
function STextoSkusColorActivados: string;
function STextoSkusColorDesactivados: string;
function SInfoSkusColorActualizados: string;
function SErrorColorPaletaBusquedaInvalido: string;
function SErrorOperacionSinBorrador: string;
function SErrorBorradorNoCerradoFiscalmente: string;
function SPreguntaAnularFiscalmenteBorrador: string;
function SPreguntaBorrarMovimientosTicketAnulado: string;
function SPreguntaMovimientosRectificativaSustitutiva: string;
function SInfoAnulacionVerifactuEncolada: string;
function SInfoAnulacionNoVerifactuRegistrada: string;
function SInfoAnulacionSinVerifactuRegistrada: string;
function SErrorFacturarTicketRequiereSimplificado: string;
function SInfoBorradorSustitucionTicketCreado: string;
function SErrorRectificarRectificativa: string;
function SPreguntaRectificarBorrador: string;
function SErrorOperacionCorreoNoEncontrada: string;
function STituloEnviarDocumentacion: string;
function SSolicitudCorreoElectronico: string;
function SErrorCorreoElectronicoObligatorio: string;
function SErrorEnviarCorreoOperacion: string;
function SErrorOperacionSinTicket: string;
function SPreguntaBorrarPropiedadPlantillaCompra: string;
function SPreguntaBorrarKitPlantillaCompra: string;
function SInfoIbanValidado: string;
function SErrorCabeceraSesionAntesLineas: string;
function SErrorSesionSinDocumentosCreados: string;
function SErrorMantenimientoTipoDocumentoNoDisponible: string;
function SPreguntaAbrirSeriesSesionCompra: string;
function SErrorLineaSesionDescargarFotosNoSeleccionada: string;
function SErrorLineaSesionSinCodigoArticulo: string;
function SErrorDescargarFotosArticulo: string;
function SInfoFotosArticuloDescargadas: string;
function SErrorSesionElegirProveedorNoSeleccionada: string;
function SErrorProveedorSesionSinKits: string;
function SErrorKitProveedorDesplegableNoSeleccionado: string;
function SPreguntaBorrarLineaSesionCompra: string;
function SErrorLineaSesionAsignarFotoNoSeleccionada: string;
function SInfoFotoLineaSesionAsignada: string;
function SErrorAsignarFotoSesion: string;
function SErrorGuardarFotoSesion: string;
function SErrorSesionYaMaterializada: string;
function SInfoDuplicadosSesionMarcadosReusar: string;
function SInfoSesionMaterializadaSinDocumentos: string;
function SErrorSesionNoCerradaParaReversion: string;
function SPreguntaRevertirSesionCompra: string;
function SInfoSesionRevertida: string;
function SErrorRevertirSesionCompra: string;
function SErrorSesionActivaImprimirNoDisponible: string;
function SErrorSistemasTallasSesionNoDisponibles: string;
function SErrorCambiarSistemaTallasModeloExistente: string;
function SErrorLineaSesionAsignarFamiliaNoSeleccionada: string;
function SErrorColoresBasicosSesionNoDisponibles: string;
function SInfoEfectoConciliado: string;
function SErrorConciliarEfecto: string;
function SErrorEfectoNoSeleccionado: string;
function SErrorCarteraEfectosNoAbierta: string;
function SErrorEfectosCompraFusionInsuficientes: string;
function SErrorEfectosVentaFusionInsuficientes: string;
function SPreguntaFusionarEfectos: string;
function SInfoEfectosConciliados: string;
function SErrorFusionarEfectos: string;
function SErrorContadorSerieEmpresa: string;
function SErrorEmpresaCrearSeriesNoSeleccionada: string;
function SInfoSeriesEmpresaCreadas: string;
function SErrorEmpresaNoSeleccionada: string;
function SInfoInstalacionSifEmpresaDisponible: string;
function SErrorDocumentoTrabajoNoSeleccionadoListado: string;
function SErrorDocumentoTrabajoSinGrabarListado: string;
function SErrorDocumentoTrabajoSinLineasListado: string;
function SErrorDocumentoTrabajoNoSeleccionadoCargar: string;
function SErrorCargarDocumentoTrabajoNoPropietario: string;
function SErrorDocumentoTrabajoSinGrabarCargar: string;
function SErrorDocumentoTrabajoNoSeleccionadoCompartir: string;
function SInfoDocumentoTrabajoCompartido: string;
function SInfoDocumentoTrabajoYaCompartido: string;
function SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas: string;
function SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas: string;
function SErrorDocumentoTrabajoNoSeleccionadoEnviar: string;
function SErrorDocumentoTrabajoSinGrabarEnviar: string;
function SErrorDocumentoTrabajoSinLineasEnviar: string;
function SErrorContadorAlbaranDocumentoTrabajo: string;
function SInfoAlbaranDocumentoTrabajoCreado: string;
function SErrorVentaTpvNoAbiertaDocumentoTrabajo: string;
function SInfoLineasDocumentoTrabajoVolcadasTpv: string;
function SAvisoLineasDocumentoTrabajoNoVolcadasTpv: string;
function SErrorContadorInventarioDocumentoTrabajo: string;
function SInfoInventarioDocumentoTrabajoCreado: string;
function SInfoCambioTarifasDocumentoTrabajoCreado: string;
function SPreguntaAbrirSeriesDevolucionCompra: string;
function SErrorLineaColorDevolucionNoEncontrada: string;
function SErrorDevolucionCompraSinImpresionActiva: string;
function SErrorDevolucionCompraNoActiva: string;
function SErrorProveedorDevolucionFilaNoSeleccionado: string;
function SErrorAlmacenDevolucionFilaNoSeleccionado: string;
function SErrorFilaDevolucionStockNoSeleccionada: string;
function SErrorArticuloDevolucionFilaNoSeleccionado: string;
function SErrorColorDevolucionFilaNoSeleccionado: string;
function SErrorStockDevolucionFilaNoDisponible: string;
function SPreguntaPrepararStockFilaDevolucion: string;
function SInfoStockFilaDevolucionPreparado: string;
function SPreguntaGrabarDevolucionCompraSinSku: string;
function SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion: string;
function SErrorDevolucionCompraNoAbierta: string;
function SErrorArticuloNoSeleccionadoBuscarSkusDevolucion: string;
function SErrorDevolucionCompraElegirEmpresaNoSeleccionada: string;
function SErrorDevolucionCompraElegirProveedorNoSeleccionada: string;
function SPreguntaEliminarLineaDevolucionCompra: string;
function SErrorFotoArticuloNoActivoDescargar: string;
function SErrorFotoArticuloNoActivo: string;
function SErrorGuardarFotoArticulo: string;
function SErrorFotoSkuNoActivo: string;
function SErrorNivelAtributosFotoNoSeleccionado: string;
function SPreguntaEliminarFotoActual: string;
function SAvisoLimiteRegistrosFacturaSimplificada: string;
function SErrorBorradorVentaMayorNoSeleccionado: string;
function SErrorGuardarAntesEmitirEdoc: string;
function SErrorPersonaFisicaEdocSinDatos: string;
function SInfoEdocEmitido: string;
function SPreguntaAbrirSeriesFacturaCompra: string;
function SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra: string;
function SErrorFacturaCompraNoAbierta: string;
function SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra: string;
function SErrorFacturaCompraSinImpresionActiva: string;
function SAvisoEtiquetasBorradorCompraPendientes: string;
function SPreguntaGrabarFacturaCompraSinSku: string;
function SErrorFacturaCompraNoInicializada: string;
function SErrorFacturaCompraElegirProveedorNoSeleccionada: string;
function SInfoGeneracionEfectosPagoCancelada: string;
function SInfoEfectosPagoGenerados: string;
function SAvisoEfectosPagoNoGenerados: string;
function SErrorGenerarEfectosPagoSinBorrador: string;
function SErrorEfectoCompraNoSeleccionado: string;
function SPreguntaEliminarLineaFacturaCompra: string;
function SInfoImpresionEfectosCobroEnRemesas: string;
function SPreguntaReemplazarCobros: string;
function STituloMensajeAdvertencia: string;
function SInfoGeneracionCobrosCancelada: string;
function SInfoEfectosCobroGenerados: string;
function SAvisoEfectosCobroNoGenerados: string;
function SErrorGenerarEfectosCobroSinBorrador: string;
function SAvisoBorradorPendienteImpresionFiscal: string;
function SErrorGuardarFacturaAntesImprimir: string;
function SInfoEfectoMarcadoDevuelto: string;
function SErrorMarcarEfectoDevuelto: string;
function SInfoEfectoMarcadoPendiente: string;
function SErrorMarcarEfectoPendiente: string;
function SErrorEfectoSinImportePendiente: string;
function SErrorTarifaSeleccionadaNoEncontrada: string;
function SErrorBorradorListaNoSeleccionado: string;
function SErrorBorradorNoCerradoAccionFiscal: string;
function SPreguntaAccionFiscalBorrador: string;
function SInfoAccionFiscalEncolada: string;
function SInfoAccionFiscalNoVerifactu: string;
function SInfoAccionFiscalSinVerifactu: string;
function SErrorBorradorYaLanzadoFiscalmente: string;
function SErrorBorradorSinLineasLanzar: string;
function SErrorBorradorNormalSinNif: string;
function SPreguntaLanzarBorradorFiscal: string;
function SInfoBorradorVerifactuPendiente: string;
function SInfoBorradorNoVerifactuRegistrado: string;
function SInfoBorradorSinVerifactuEmitido: string;
function SErrorBorradorConsolidadoNoReabrible: string;
function SInfoBorradorYaEnBorrador: string;
function SPreguntaDevolverBorrador: string;
function SErrorAltaAeatAceptadaNoReabrible: string;
function SErrorBorradorEnProcesoNoReabrible: string;
function SInfoBorradorReabierto: string;
function SPreguntaGrabarFacturaVentaSinSku: string;
function SErrorCompletarDatosBorrador: string;
function SErrorContadorAutomaticoBusqueda: string;
function SInfoRegistroBusquedaCreado: string;
function SErrorInsertarRegistroBusqueda: string;
function SInfoTextoNoEncontrado: string;
function STituloBusquedaGlobal: string;
function SSolicitudTextoBusquedaGlobal: string;
function SInfoProcesosBusquedaNoEncontrados: string;
function SPreguntaIgnorarErrorScript: string;
function SErrorMetadatoSinScript: string;
function SErrorDatosCopiarNoDisponibles: string;
function SPreguntaCopiarFilasPortapapeles: string;
function SPreguntaIgnorarErrorComandoScript: string;
function SErrorEjecucionProceso: string;
function SErrorComandoSqlProceso: string;
function SErrorConexionTrabajoNoDisponible: string;
function SInfoDatosGuardados: string;
function SErrorGrabarDatos: string;
function SPreguntaGrabarCambiosPendientes: string;
function STituloMensajeAdvertenciaGen: string;
function SInfoCambiosGrabados: string;
function SInfoCambiosCancelados: string;
function SErrorConexionPrincipalNoDisponible: string;
function SErrorPermisoInsertarRegistro: string;
function SErrorPermisoModificarRegistro: string;
function SErrorPermisoGuardarRegistro: string;
function SErrorPermisoBorrarRegistro: string;
function SPreguntaEliminarRegistro: string;
function STituloConfirmarEliminacion: string;
function SPreguntaEliminarRegistroConHijos: string;
function SAvisoDesactivarRegistroConHijos: string;
function SAvisoDesactivarRegistroSinHijos: string;
function SDescripcionHijosGenerica: string;
function STextoOpcionesBorradoRegistro: string;
function SErrorFiltroSinCondiciones: string;
function SErrorFiltroActualVacio: string;
function SPreguntaSobrescribirFiltro: string;
function STituloSobrescribirFiltro: string;
function SInfoFiltroSobrescrito: string;
function SInfoFiltroGuardado: string;
function SErrorArticuloInventarioNoExiste: string;
function SErrorLineasInventarioNoAbiertas: string;
function SErrorLineaInventarioNoEditable: string;
function SErrorArticuloInventarioNoEncontrado: string;
function SErrorArticuloInventarioTipoSinStock: string;
function SErrorArticuloInventarioAtributosSinSku: string;
function SInfoLineasCsvInventarioLeidas: string;
function SErrorMigracionRecuentoInventariosNoAplicada: string;
function SErrorGrabarCabeceraInventarioAutomaticamente: string;
function SErrorGrabarCabeceraInventarioAutomaticamenteDetalle: string;
function SErrorInventarioNoAbiertoEditar: string;
function SPreguntaRecalcularInventario: string;
function SInfoRecalculoInventario: string;
function SPreguntaAplicarInventario: string;
function SErrorAplicarInventario: string;
function SErrorAplicacionInventario: string;
function SErrorRefrescarInventarioAplicado: string;
function SInfoInventarioAplicado: string;
function SErrorInventarioNoSeleccionadoAnadirLineas: string;
function SErrorAnadirLineasInventarioEstado: string;
function SErrorLineaInventarioNoSeleccionadaParaSkus: string;
function SErrorLineaInventarioSinArticulo: string;
function SErrorAnadirSkusInventario: string;
function SInfoSinSkusAnadidosInventario: string;
function SInfoSkusAnadidosInventario: string;
function SPreguntaEliminarLineaInventario: string;
function SErrorEliminarRegularizacionInventarioEstado: string;
function SPreguntaEliminarRegularizacionInventario: string;
function SInfoRegularizacionInventarioEliminada: string;
function SErrorInventarioNoActivo: string;
function SErrorInventarioDebeEstarAbierto: string;
function SErrorFamiliaInventarioNoSeleccionada: string;
function SPreguntaCargarFamiliaInventario: string;
function SErrorProveedorInventarioNoSeleccionado: string;
function SPreguntaCargarProveedorInventario: string;
function SPreguntaCompletarInventario: string;
function SPreguntaCargarTodoInventario: string;
function SErrorInventarioNoSeleccionado: string;
function SPreguntaGuardarInventarioEnEdicion: string;
function SPreguntaRecalcularTrasCargarBloqueInventario: string;
function SErrorArchivoImportacionInventarioNoExiste: string;
function SErrorImportacionInventarioSinDatos: string;
function SInfoImportacionInventario: string;
function SErrorEnviarRecuentoInventarioNoAbierto: string;
function SPreguntaEnviarRecuentoInventario: string;
function SInfoInventarioEnviadoRecuento: string;
function SErrorEnviarRecuentoInventario: string;
function SErrorInventarioNoEnviadoRecuento: string;
function SErrorRecogerRecuentoInventarioNoAbierto: string;
function SInfoRecuentoInventarioRecogido: string;
function SErrorRecogerRecuentoInventario: string;
function SAvisoLimiteRegistrosMovimientosAlmacen: string;
function SPreguntaAbrirSeriesPedidoVenta: string;
function SErrorPedidoVentaNoAbierto: string;
function SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta: string;
function SPreguntaGrabarPedidoVentaSinSku: string;
function SErrorClienteNoSeleccionadoPedidoVenta: string;
function SErrorClientePedidoVentaNoExiste: string;
function SErrorPedidoVentaNoInicializado: string;
function SErrorCrearSeleccionarPedidoAntesLineas: string;
function SPreguntaEliminarLineaPedidoVentaConTallas: string;
function SPreguntaEliminarLineaPedidoVenta: string;
function SPreguntaMarcarLineasPendientesAlbaranar: string;
function SErrorPedidoVentaSinLineas: string;
function SPreguntaCrearAlbaranPedidoVentaSinSku: string;
function SErrorPedidoVentaSinCantidadAlbaranar: string;
function SErrorAnadirAlbaranDesdePedidoVenta: string;
function SErrorCrearAlbaranDesdePedidoVenta: string;
function SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra: string;
function SErrorPedidoCompraNoAbierto: string;
function SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra: string;
function SErrorPedidoCompraNoInicializado: string;
function STextoPedidoCompra: string;
function SErrorExpandirRecibidosNoActivo: string;
function SInfoTallasPendientesRecibirNoDisponibles: string;
function SInfoPedidoCompraSinPendientesRecibir: string;
function SPreguntaGrabarPedidoCompraSinSku: string;
function SErrorPedidoCompraNecesarioElegirEmpresa: string;
function SErrorPedidoCompraNecesarioElegirProveedor: string;
function SErrorTallasHorizontalesNecesariasElegirColor: string;
function SErrorArticuloNoSeleccionadoElegirColorPedidoCompra: string;
function SErrorArticuloPedidoCompraSinColoresBasicos: string;
function SPreguntaEliminarLineaPedidoCompra: string;
function SPreguntaAbrirSeriesPedidoCompra: string;
function SErrorPedidoCompraNoActivo: string;
function SErrorPedidoCompraNoActivoCrearAlbaran: string;
function SErrorCrearAlbaranDesdePedidoCompra: string;
function SErrorNodoPermisosNoSeleccionado: string;
function SErrorOrigenDestinoPermisosNoSeleccionados: string;
function SErrorOrigenDestinoPermisosIguales: string;
function SInfoModoReemplazarPermisos: string;
function SInfoModoCombinarPermisos: string;
function SInfoAlcancePermisosMenu: string;
function SInfoAlcanceTodosPermisos: string;
function SPreguntaCopiarPermisos: string;
function SInfoPermisosCopiados: string;
function SPreguntaBorrarKitProveedor: string;
function SErrorRemesaCompraNoSeleccionada: string;
function SErrorEliminarRemesaCompraConCargo: string;
function SPreguntaEliminarRemesaCompra: string;
function SInfoRemesaCompraEliminada: string;
function SErrorEliminarRemesaCompra: string;
function SErrorAnadirEfectosRemesaCompraConCargo: string;
function SErrorEfectosRemesaCompraNoCargados: string;
function SErrorEfectoRemesaCompraNoSeleccionado: string;
function SErrorQuitarEfectosRemesaCompraConCargo: string;
function SPreguntaQuitarEfectoRemesaCompra: string;
function SInfoEfectoRemesaCompraQuitado: string;
function SErrorQuitarEfectoRemesaCompra: string;
function SErrorBancoPagoRemesaNoAsignado: string;
function SErrorEfectoRemesaCompraSinPendiente: string;
function STextoEfectoPendienteRemesaCompra: string;
function SInfoEfectoRemesaCompraConciliado: string;
function SErrorConciliarEfectoRemesaCompra: string;
function SErrorRemesaCompraSinImportePendiente: string;
function STextoRemesaCompraPendiente: string;
function SInfoEfectosRemesaCompraConciliados: string;
function SErrorConciliarRemesaCompra: string;
function SErrorBancoPagoNoSeleccionado: string;
function SInfoBancoPagoRemesaAsignado: string;
function SErrorAsignarBancoPagoRemesa: string;
function STituloFechaCargoRemesa: string;
function SSolicitudFechaCargoRemesa: string;
function SInfoFechaCargoRemesaActualizada: string;
function SErrorActualizarFechaCargoRemesa: string;
function SErrorFechaCargoRemesaNoValida: string;
function SErrorEliminarRemesaVentaConCobro: string;
function SPreguntaEliminarRemesaVenta: string;
function SInfoRemesaVentaEliminada: string;
function SErrorEliminarRemesaVenta: string;
function SErrorAnadirEfectosRemesaVentaConCobro: string;
function SErrorEfectosRemesaVentaNoCargados: string;
function SErrorEfectoRemesaVentaNoSeleccionado: string;
function SErrorQuitarEfectosRemesaVentaConCobro: string;
function SPreguntaQuitarEfectoRemesaVenta: string;
function SInfoEfectoRemesaVentaQuitado: string;
function SErrorQuitarEfectoRemesaVenta: string;
function SErrorBancoCobroRemesaNoAsignado: string;
function SErrorEfectoRemesaVentaSinPendiente: string;
function STextoEfectoPendienteRemesaVenta: string;
function SInfoEfectoRemesaVentaConciliado: string;
function SErrorConciliarEfectoRemesaVenta: string;
function SErrorRemesaVentaSinImportePendiente: string;
function STextoRemesaVentaPendiente: string;
function SInfoEfectosRemesaVentaConciliados: string;
function SErrorConciliarRemesaVenta: string;
function SErrorBancoCobroNoSeleccionado: string;
function SInfoBancoCobroRemesaAsignado: string;
function SErrorAsignarBancoCobroRemesa: string;
function STituloFechaCobroRemesa: string;
function SSolicitudFechaCobroRemesa: string;
function SInfoFechaCobroRemesaActualizada: string;
function SErrorActualizarFechaCobroRemesa: string;
function SErrorFechaCobroRemesaNoValida: string;
function SInfoOrdenSepaRemesaVentaGenerada: string;
function SErrorGenerarOrdenSepaRemesaVenta: string;
function SErrorCodigoBarrasStockNoEncontrado: string;
function SErrorEntradaStockNoEncontrada: string;
function SErrorSkuCeldaStockNoEncontrado: string;
function SErrorCeldaStockVariosSkus: string;
function SErrorArticuloStockNoSeleccionadoOperaciones: string;
function SErrorCeldaTallaStockNoSeleccionada: string;
function SErrorColumnaTallaStockNoSeleccionada: string;
function SErrorFilaStockNoIdentificada: string;
function SErrorColorStockNoUnico: string;
function SErrorTallaStockVariosSkus: string;
function STituloOperacionesCajaStock: string;
function SErrorArticuloStockNoSeleccionadoDocumento: string;
function SErrorEstadoStockNoEsExistencias: string;
function SErrorCeldaStockNoSeleccionada: string;
function SErrorCeldaCantidadStockNoSeleccionada: string;
function SErrorFilaExistenciasStockNoSeleccionada: string;
function SErrorColumnaStockDocumentoNoSeleccionada: string;
function SErrorGrupoFilaStockNoLeido: string;
function SErrorAlmacenStockNoUnico: string;
function SErrorColorStockUnidadNoUnico: string;
function STituloConsultaStock: string;
function SErrorArticuloStockNoSeleccionadoFotos: string;
function SInfoArticulosRelacionadosStockNoDisponibles: string;
function SErrorTarifaNoSeleccionada: string;
function SPreguntaGuardarTarifaAntesContinuar: string;
function SErrorSesionTarifaNoSeleccionada: string;
function SInfoLineasSesionTarifaRecalculadas: string;
function SErrorCalcularSesionTarifa: string;
function SPreguntaAplicarSesionTarifa: string;
function SErrorAplicarSesionTarifa: string;
function SInfoLineasSesionTarifaAplicadas: string;
function SPreguntaLimpiarFiltrosAddBlock: string;
function SErrorAlmacenesSoloStockAddBlock: string;
function SPreguntaPrevisualizarAddBlock: string;
function SInfoArticulosYaCargadosAddBlock: string;
function SPreguntaConfirmarAddBlock: string;
function SInfoArticulosAnadidosAddBlock: string;
function SErrorDestinoDocumentoTrabajoAddBlock: string;
function SErrorAlmacenesDocumentoTrabajoAddBlock: string;
function SPreguntaConfirmarDocumentoTrabajoAddBlock: string;
function SInfoLineasDocumentoTrabajoAddBlock: string;
function SErrorInsertarLineasDocumentoTrabajoAddBlock: string;
function SErrorDestinoInventarioAddBlock: string;
function SPreguntaConfirmarInventarioAddBlock: string;
function SInfoLineasInventarioAddBlock: string;
function SErrorInsertarLineasInventarioAddBlock: string;
function SErrorTarifaDestinoAddBlockNoSeleccionada: string;
function SErrorTarifaOrigenAddBlockNoSeleccionada: string;
function SErrorTarifasAddBlockCoincidentes: string;
function SErrorMultiploAjusteAddBlockNoValido: string;
function SPreguntaConfirmarTarifaAddBlock: string;
function SInfoArticulosTarifaAddBlockAnadidos: string;
function SErrorInsertarTarifaAddBlock: string;
function SPreguntaQuitarPropiedadArticulo: string;
function SErrorArticuloNoGuardadoValoresColor: string;
function SErrorArticuloNoGuardadoAnadirPropiedades: string;
function SErrorPropiedadObligatoriaFamilia: string;
function SErrorPrecioCosteMargenNoValido: string;
function SErrorMargenNoValido: string;
function SErrorAjusteMargenNoValido: string;
function SErrorGuardarCambiosMargen: string;
function SErrorProveedorPrincipalCosteNoAsignado: string;
function SErrorEmpresaEfectosRemesaNoIndicada: string;
function SInfoEfectosPendientesRemesaNoEncontrados: string;
function SErrorEfectosRemesaNoSeleccionados: string;
function SErrorRemesaExistenteNoSeleccionada: string;
function SInfoEfectosCargadosRemesa: string;
function SPreguntaConfirmarCargaSesionTarifa: string;
function SInfoArticulosCargadosSesionTarifa: string;
function SErrorCargarSesionTarifa: string;
function SErrorTipoDocumentoSesionNoSeleccionado: string;
function SErrorSerieAlbaranSesionNoIndicada: string;
function SErrorSeriePedidoSesionNoIndicada: string;
function SErrorAlmacenDestinoSesionNoIndicado: string;
function SErrorCertificadoNoSeleccionado: string;
function SErrorEmpleadoEntradaCambioNoIndicado: string;
function SErrorImporteEntradaCambioNoValido: string;
function STituloAvisoEntradaCambio: string;
function SErrorDestinoEnvioIncompleto: string;
function SErrorTarifaEtiquetasNoSeleccionada: string;
function SInfoLayoutEtiquetasGuardado: string;
function SErrorEmpresaProveedorFacturacionNoIndicados: string;
function SInfoAlbaranesPendientesProveedorNoEncontrados: string;
function SPreguntaFacturarTodosAlbaranesListados: string;
function SErrorBorradorAlbaranesExistenteNoSeleccionado: string;
function SInfoAlbaranesGeneradosEnBorrador: string;
function SErrorDataModuleAlbaranesNoAsignado: string;
function SErrorAlbaranesNoSeleccionados: string;
function SInfoBorradoresGenerados: string;
function SErrorClienteBorradorNoSeleccionado: string;
function SErrorSerieBorradorNoSeleccionada: string;
function SErrorFechaBorradorNoIndicada: string;
function SErrorClienteFacturarTicketNoExiste: string;
function SErrorRazonSocialFacturarTicketObligatoria: string;
function SErrorDocumentoFiscalFacturarTicketNoValido: string;
function SErrorCrearBorradorFacturarTicket: string;
function SPreguntaSuperarLimiteCargaArticulos: string;
function SErrorDimensionesSkuNoDefinidas: string;
function SErrorValoresSkuNoSeleccionados: string;
function SErrorValoresDimensionesSkuIncompletos: string;
function SInfoCombinacionesSkuGeneradas: string;
function STituloAnadirValorSku: string;
function SSolicitudNombreValorSku: string;
function SSolicitudOrdenNuevoValorSku: string;
function SPreguntaGuardarValorSkuGlobal: string;
function SPreguntaUsarValorSkuTemporal: string;
function STituloCambiarOrdenValorSku: string;
function SSolicitudOrdenValorSku: string;
function SErrorOrdenValorSkuNoValido: string;
function SPreguntaCambiarOrdenValorSkuGlobal: string;
function STituloCambiarOrdenAtributoSku: string;
function SSolicitudOrdenAtributoSku: string;
function SErrorOrdenAtributoSkuNoValido: string;
function SPreguntaEditarCamposExtraInforme: string;
function SErrorPrivilegiosBorrarFormato: string;
function SPreguntaBorrarFormato: string;
function SPreguntaReemplazarInforme: string;
function STituloAdvertenciaInforme: string;
function SErrorContrasenasNoCoinciden: string;
function SErrorFiltroNoSeleccionado: string;
function SErrorFiltroSinCondicionesAplicar: string;
function SErrorFiltroSinCondicionesGuardar: string;
function SInfoCambiosFiltroGuardados: string;
function SErrorPantallaSinFiltroAplicado: string;
function SPreguntaReemplazarFiltro: string;
function STituloReemplazarFiltro: string;
function SInfoFiltroReemplazado: string;
function SErrorFiltroPropioDuplicado: string;
function SInfoCopiaFiltroGuardada: string;
function SPreguntaBorrarFiltro: string;
function STituloConfirmarBorradoFiltro: string;
function SInfoFiltroCompartidoGrupo: string;
function SInfoFiltroCompartidoTodos: string;
function SErrorNombreFiltroNoIndicado: string;
function SErrorCodigoGuiaNoIndicado: string;
function SErrorTablaExternaGuiaNoSeleccionada: string;
function SErrorCampoMasterGuiaNoSeleccionado: string;
function SErrorCampoDetailGuiaNoSeleccionado: string;
function SInfoGuiaAnadida: string;
function SInfoGuiasEliminarNoEncontradas: string;
function SPreguntaEliminarGuia: string;
function SErrorFacturaCompraExportarNoPreparada: string;
function SErrorDataModulePedidosNoAsignado: string;
function SInfoImportacionPedidosFinalizada: string;
function SErrorConexionOperacionesCajaSkuNoDisponible: string;
function SErrorImporteConciliadoNoValido: string;
function SErrorImporteConciliadoSuperaPendiente: string;
function SErrorNombreFormatoWizardNoIndicado: string;
function SErrorNombreFormatoWizardNoModificado: string;
function SErrorDatasetMasterWizardNoSeleccionado: string;
function SErrorCamposMasterWizardNoSeleccionados: string;
function SErrorTablaExternaWizardNoSeleccionada: string;
function SErrorCamposTablaExternaWizardNoSeleccionados: string;
function SErrorPrepararImpresionDeclaracionResponsable: string;
function SErrorImprimirDeclaracionResponsable: string;
function SInfoNumeroInstalacionSifDisponible: string;
function SErrorGenerarNumeroInstalacionSif: string;
function SErrorSerieDocumentoNoIndicada: string;
function SErrorFechaInicioDocumentoNoIndicada: string;
function SErrorFechaFinDocumentoNoIndicada: string;
function SErrorRangoFechasDocumentoNoValido: string;
function SInfoEmpresaSinCuentasBancarias: string;
function SErrorAlmacenPedidoNoSeleccionado: string;
function SInfoAlbaranesIncorporarNoDisponibles: string;
function SErrorSerieAlbaranPedidoNoIndicada: string;
function SInfoLogGuardado: string;
function SErrorAlmacenAlbaranNoSeleccionado: string;
function SErrorAlbaranDestinoNoSeleccionado: string;
function SErrorCodigoAcreedorSepaNoIndicado: string;
function SErrorLongitudCodigoAcreedorSepa: string;
function SErrorFormatoCodigoAcreedorSepaNoValido: string;
function SErrorSecuenciaSepaNoValida: string;
function SErrorClientesSinMandatoSepa: string;
function SErrorMandatosSepaLongitudNoValida: string;
function SErrorClientesSinFechaFirmaMandatoSepa: string;
function SErrorCodigoFormaPagoCajaObligatorio: string;
function SErrorDescripcionFormaPagoCajaObligatoria: string;
function SErrorParametrosAplicacionCajaNoConfigurados: string;
function SErrorParametrosModuloCajaNoConfigurados: string;
function SErrorContextoSesionCajaNoConfigurado: string;
function SErrorOperacionCajaSinLineas: string;
function SErrorRazonSocialClienteFacturaCajaObligatoria: string;
function SErrorDocumentoFiscalClienteCajaNoValido: string;
function SErrorDocumentoFiscalEmpresaCajaNoValido: string;
function SErrorFechaTicketSerieNoValida: string;
function SErrorCuadreCobroParcialCaja: string;
function SErrorFacturaRectificativaCajaSinOriginal: string;
function SErrorGuardarTicketCaja: string;
function SErrorCuadrarFacturaCaja: string;
function SErrorRedimirValeCaja: string;
function SErrorContextoSesionTraspasoNoConfigurado: string;
function SErrorSkuTraspasoIncompleto: string;
function SErrorArticuloSkuTraspasoNoCoincide: string;
function SErrorStockTraspasoInsuficiente: string;
function SErrorLineasTraspasoNoDisponibles: string;
function SErrorAlmacenDestinoTraspasoNoSeleccionado: string;
function SErrorAlmacenesTraspasoCoincidentes: string;
function SErrorLineasSolicitudTraspasoNoDisponibles: string;
function SErrorAlmacenOrigenSolicitudNoSeleccionado: string;
function SErrorSolicitudTraspasoMismoAlmacen: string;
function SErrorSolicitudTraspasoNoCargada: string;
function SErrorPermisoAbrirCajon: string;
function SErrorImpresoraTicketsCajaNoConfigurada: string;
function SErrorContextoImpresoraCajaNoProporcionado: string;
function SErrorReferenciaPagoCajaNoIndicada: string;
function SErrorFactorCambioCajaNoValido: string;
function SErrorHashBlockchainCajaNoIndicado: string;
function SErrorValeCajaNoSeleccionado: string;
function SErrorPinValeCajaNoIndicado: string;
function SErrorPinValeCajaIncorrecto: string;
function SErrorProveedorParametrosCajaNoConfigurado: string;
function SErrorParametrosCajaEditablesNoConfigurados: string;
function SInfoLayoutCajaGuardado: string;
function SInfoParametrosCajaGuardados: string;
function SInfoParametrosCajaSinCambios: string;
function SPreguntaSalirParametrosCajaSinGuardar: string;
function SInfoUsuariosParametrosCajaNoEncontrados: string;
function STituloCambiarUsuarioParametrosCaja: string;
function SSolicitudCambiarUsuarioParametrosCaja: string;
function SErrorUsuarioParametrosCajaNoEncontrado: string;
function SInfoPrecargaCajaGuardada: string;
function SErrorAsignarUbicacionCaja: string;
function STituloHoraCaja: string;
function SSolicitudHoraCaja: string;
function SErrorHoraCajaNoValida: string;
function SErrorUbicacionCajaBuscarOperacionesNoAsignada: string;
function SErrorUbicacionCajaArqueoNoAsignada: string;
function SErrorUbicacionCajaTraspasoNoAsignada: string;
function SErrorRectificacionCajaNoAdmiteBorrador: string;
function SErrorClienteBorradorCajaNoAsignado: string;
function SErrorNifClienteBorradorCajaNoIndicado: string;
function SErrorFechaSerieEmisionCajaNoValida: string;
function SAvisoHuecosNumeracionSerieCaja: string;
function SErrorNumeroBorradorCajaNoValido: string;
function SErrorNumeroBorradorCajaExistente: string;
function SErrorNumeroBorradorCajaNoEsHueco: string;
function STituloEnviarDocumentacionCaja: string;
function SSolicitudCorreoDocumentacionCaja: string;
function SErrorCorreoDocumentacionCajaNoIndicado: string;
function SErrorCreditoClienteCajaNoPermitido: string;
function SErrorImporteCreditoCajaNoPendiente: string;
function SAvisoLimiteOperacionesCaja: string;
function SErrorOperacionCajaExportarNoSeleccionada: string;
function SErrorSkuVentaCajaNoExiste: string;
function SErrorSkuVentaCajaNoActivo: string;
function SErrorArticuloVentaCajaSinStock: string;
function SErrorVendedorCajaNoAsignado: string;
function SErrorCodigoBarrasVentaCajaNoEncontrado: string;
function SErrorLineaDepositoCajaNoCancelable: string;
function SErrorArticuloVentaCajaNoEncontrado: string;
function SPreguntaCancelarVentaCaja: string;
function SErrorLineaDepositoCajaNoEliminable: string;
function SPreguntaBorrarVentaCaja: string;
function SInfoValeCajaEntregar: string;
function SErrorCorreoOperacionCajaNoEnviado: string;
function SErrorTipoRectificativaCajaNoIndicado: string;
function SErrorBorradorRectificarCajaNoEncontrado: string;
function SErrorClienteDepositosCajaNoSeleccionado: string;
function SErrorValoresAtributoCajaNoDefinidos: string;
function SPreguntaEliminarOperacionCajaPendiente: string;
function SErrorArticuloCajaNoEncontradoDescatalogado: string;
function SErrorCantidadArticuloDepositoCajaNoValida: string;
function SErrorCodigoClienteCajaNoExiste: string;
function SErrorEmpleadoCajaNoEncontrado: string;
function SErrorSolicitudesTraspasoPendientesNoEncontradas: string;
function SErrorCargarSolicitudTraspaso: string;
function SErrorSolicitudTraspasoCerrarNoCargada: string;
function SPreguntaCerrarSolicitudTraspaso: string;
function SInfoSolicitudTraspasoCerrada: string;
function SErrorDenegarSolicitudTraspasoModoNoValido: string;
function SErrorSolicitudTraspasoDenegarNoCargada: string;
function STituloDenegarSolicitudTraspaso: string;
function SSolicitudMotivoRechazoTraspaso: string;
function SErrorMotivoDenegacionTraspasoNoIndicado: string;
function SInfoPeticionTraspasoDenegada: string;
function SInfoSolicitudTraspasoEnviada: string;
function SErrorEmpleadoTraspasoNoIndicado: string;
function SErrorEmpleadoTraspasoNoEncontrado: string;
function SErrorSolicitudTraspasoAtenderNoCargada: string;
function SErrorMotivoLineasTraspasoNoIndicado: string;
function SInfoSolicitudTraspasoAtendida: string;
function SPreguntaDenegarPeticionTraspasoCompleta: string;
function SInfoTraspasoGrabado: string;
function SErrorEmpleadoGastoCajaNoIndicado: string;
function SErrorImporteGastoCajaNoValido: string;
function STituloAvisoCaja: string;
function SErrorArqueoCajaNoSeleccionado: string;
function SErrorPermisoResumenArqueoCaja: string;
function SInfoOperacionesFacturadasArqueoCajaNoEncontradas: string;
function STituloTiraCaja: string;
function SErrorVendedorArqueoCajaNoIndicado: string;
function STituloVendedorArqueoCajaObligatorio: string;
function SErrorVendedorArqueoCajaNoValido: string;
function STituloVendedorArqueoCajaNoValido: string;
function SErrorArqueoCajaDuplicado: string;
function STituloArqueoCajaDuplicado: string;
function SErrorRecuentoArqueoCajaNoDisponible: string;
function SPreguntaGrabarArqueoCaja: string;
function STituloConfirmarArqueoCaja: string;

implementation

uses
  inLibMsgComun,
  inLibMsgConfiguracion,
  inLibMsgArticulos,
  inLibMsgVentas,
  inLibMsgCompras,
  inLibMsgFacturas,
  inLibMsgCaja,
  inLibMsgIntegraciones,
  inLibMsgVerifactu;

function SClassRttiNotFnd: string;
begin
  Result :=
    inLibMsgComun.SClassRttiNotFnd;
end;
function SLocateNotFnd: string;
begin
  Result :=
    inLibMsgComun.SLocateNotFnd;
end;
function SResWinFNotFnd: string;
begin
  Result :=
    inLibMsgComun.SResWinFNotFnd;
end;
function SCliToTbl: string;
begin
  Result :=
    inLibMsgFacturas.SCliToTbl;
end;
function SEmpToTbl: string;
begin
  Result :=
    inLibMsgFacturas.SEmpToTbl;
end;
function SErrorDecryptPassBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorDecryptPassBBDD;
end;
function SErrorDecryptPass: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorDecryptPass;
end;
function SErrorAuthPass: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorAuthPass;
end;
function SErrorPassMatch: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPassMatch;
end;
function SErrorPassMatchBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPassMatchBBDD;
end;
function SEnterPassBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SEnterPassBBDD;
end;
function SScriptSuccess: string;
begin
  Result :=
    inLibMsgConfiguracion.SScriptSuccess;
end;
function SFailLoadScriptBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SFailLoadScriptBBDD;
end;
function SCreateSuccBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SCreateSuccBBDD;
end;
function SErrorCreateBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorCreateBBDD;
end;
function SBBDDUpdateTo: string;
begin
  Result :=
    inLibMsgConfiguracion.SBBDDUpdateTo;
end;
function SNotExistsUpBBDDFile: string;
begin
  Result :=
    inLibMsgConfiguracion.SNotExistsUpBBDDFile;
end;
function SAdviceUpdateBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SAdviceUpdateBBDD;
end;
function SPasswordBBDDChanged: string;
begin
  Result :=
    inLibMsgConfiguracion.SPasswordBBDDChanged;
end;
function SWantDefChgBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SWantDefChgBBDD;
end;
function SAdvMsg: string;
begin
  Result :=
    inLibMsgComun.SAdvMsg;
end;
function SNoConnBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SNoConnBBDD;
end;
function SConnSuccBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SConnSuccBBDD;
end;
function SGetPassBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SGetPassBBDD;
end;
function SConnFailBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SConnFailBBDD;
end;
function SErrorSentenciaScript: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorSentenciaScript;
end;
function SSolicitudPassBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SSolicitudPassBBDD;
end;
function SSolicitudNuevoPassBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SSolicitudNuevoPassBBDD;
end;
function SScriptEjecutado: string;
begin
  Result :=
    inLibMsgConfiguracion.SScriptEjecutado;
end;
function SScriptNoEjecutado: string;
begin
  Result :=
    inLibMsgConfiguracion.SScriptNoEjecutado;
end;
function SErrorConexionServidorBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorConexionServidorBBDD;
end;
function SErrorEstructuraBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorEstructuraBBDD;
end;
function SErrorConexionBBDD: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorConexionBBDD;
end;
function SErrorInicioAutomatico: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorInicioAutomatico;
end;
function SLicenciaEstablecida: string;
begin
  Result :=
    inLibMsgConfiguracion.SLicenciaEstablecida;
end;
function SLicenciaNoEstablecidaSinNif: string;
begin
  Result :=
    inLibMsgConfiguracion.SLicenciaNoEstablecidaSinNif;
end;
function SErrorEstablecerLicencia: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorEstablecerLicencia;
end;
function SModoDemo: string;
begin
  Result :=
    inLibMsgConfiguracion.SModoDemo;
end;
function SCancelacionSolicitada: string;
begin
  Result :=
    inLibMsgConfiguracion.SCancelacionSolicitada;
end;
function SPreguntaCancelarOperacion: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaCancelarOperacion;
end;
function SOperacionCancelada: string;
begin
  Result :=
    inLibMsgConfiguracion.SOperacionCancelada;
end;
function SCopiaSeguridadGuardada: string;
begin
  Result :=
    inLibMsgConfiguracion.SCopiaSeguridadGuardada;
end;
function SErrorCrearCopiaSeguridad: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorCrearCopiaSeguridad;
end;
function SRestauracionCancelada: string;
begin
  Result :=
    inLibMsgConfiguracion.SRestauracionCancelada;
end;
function SErrorRestaurarCopiaSeguridad: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorRestaurarCopiaSeguridad;
end;
function SErrorContrasenaCopiaVacia: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorContrasenaCopiaVacia;
end;
function SErrorTipoRestauracionNoPermitido: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorTipoRestauracionNoPermitido;
end;
function SPreguntaReemplazarFichero: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaReemplazarFichero;
end;
function SCopiaSeguridadCancelada: string;
begin
  Result :=
    inLibMsgConfiguracion.SCopiaSeguridadCancelada;
end;
function SCargaScriptCancelada: string;
begin
  Result :=
    inLibMsgConfiguracion.SCargaScriptCancelada;
end;
function SUsuarioNoExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SUsuarioNoExiste;
end;
function SDescripcionParametroIdioma: string;
begin
  Result :=
    inLibMsgConfiguracion.SDescripcionParametroIdioma;
end;
function SErrorContextoSesionFormularioNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorContextoSesionFormularioNoConfigurado;
end;
function SErrorServicioAuditoriaDatosNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorServicioAuditoriaDatosNoConfigurado;
end;
function SErrorProveedorEdicionParametrosNoConfigurado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorProveedorEdicionParametrosNoConfigurado;
end;
function SErrorParametrosAplicacionEditablesNoConfigurados: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorParametrosAplicacionEditablesNoConfigurados;
end;
function SInfoParametrosGuardados: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoParametrosGuardados;
end;
function SAvisoParametrosRestringidosIgnorados: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoParametrosRestringidosIgnorados;
end;
function SAvisoParametrosRestringidosNoGuardados: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoParametrosRestringidosNoGuardados;
end;
function SInfoSinCambiosParametros: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoSinCambiosParametros;
end;
function SInfoLayoutGuardado: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoLayoutGuardado;
end;
function SPreguntaSalirSinGuardar: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaSalirSinGuardar;
end;
function SAvisoSinUsuariosParametrosGuardados: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoSinUsuariosParametrosGuardados;
end;
function STituloCambiarUsuario: string;
begin
  Result :=
    inLibMsgConfiguracion.STituloCambiarUsuario;
end;
function SSolicitudCambiarUsuario: string;
begin
  Result :=
    inLibMsgConfiguracion.SSolicitudCambiarUsuario;
end;
function SErrorUsuarioNoEncontrado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorUsuarioNoEncontrado;
end;
function SErrorEnviarTicketImpresora: string;
begin
  Result :=
    inLibMsgFacturas.SErrorEnviarTicketImpresora;
end;
function SAvisoSinComandosESCPOSImpresora: string;
begin
  Result :=
    inLibMsgComun.SAvisoSinComandosESCPOSImpresora;
end;
function SInfoTicketEnviadoImpresora: string;
begin
  Result :=
    inLibMsgFacturas.SInfoTicketEnviadoImpresora;
end;
function SErrorImprimir: string;
begin
  Result :=
    inLibMsgComun.SErrorImprimir;
end;
function SAvisoSinComandosESCPOSPDF: string;
begin
  Result :=
    inLibMsgComun.SAvisoSinComandosESCPOSPDF;
end;
function SInfoPDFGuardado: string;
begin
  Result :=
    inLibMsgComun.SInfoPDFGuardado;
end;
function SInfoPNGGuardado: string;
begin
  Result :=
    inLibMsgComun.SInfoPNGGuardado;
end;
function SErrorContextoInicioSesionNoProporcionado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorContextoInicioSesionNoProporcionado;
end;
function SErrorParametrosSinEstadoLicencia: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorParametrosSinEstadoLicencia;
end;
function SErrorParametrosAplicacionSinContratoEdicion: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorParametrosAplicacionSinContratoEdicion;
end;
function SErrorParametrosCajaSinContratoEdicion: string;
begin
  Result :=
    inLibMsgCaja.SErrorParametrosCajaSinContratoEdicion;
end;
function SErrorServicioConexionesNoDisponible: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorServicioConexionesNoDisponible;
end;
function SCertificadoQuedaMenosUnDia: string;
begin
  Result :=
    inLibMsgConfiguracion.SCertificadoQuedaMenosUnDia;
end;
function SCertificadoQuedaUnDia: string;
begin
  Result :=
    inLibMsgConfiguracion.SCertificadoQuedaUnDia;
end;
function SCertificadoQuedanDias: string;
begin
  Result :=
    inLibMsgConfiguracion.SCertificadoQuedanDias;
end;
function SAvisoCertificadoCaducado: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoCertificadoCaducado;
end;
function SAvisoCertificadoProximoCaducar: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoCertificadoProximoCaducar;
end;
function SAvisoCertificadosCaducidad: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoCertificadosCaducidad;
end;
function SAvisoCargaPermisosRestringidos: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoCargaPermisosRestringidos;
end;
function SInfoCopiaSeguridadGuardada: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoCopiaSeguridadGuardada;
end;
function SAvisoRestauracionCancelada: string;
begin
  Result :=
    inLibMsgConfiguracion.SAvisoRestauracionCancelada;
end;
function SErrorEjecutarScript: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorEjecutarScript;
end;
function SPreguntaSalirAplicacion: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaSalirAplicacion;
end;
function SPreguntaCopiaSeguridadAntesDDL: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaCopiaSeguridadAntesDDL;
end;
function SPreguntaCopiaAntesRestaurarCifrada: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaCopiaAntesRestaurarCifrada;
end;
function SInfoScriptCancelado: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoScriptCancelado;
end;
function SErrorAbrirDireccion: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorAbrirDireccion;
end;
function SAvisoAlbaranFacturado: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoAlbaranFacturado;
end;
function SPreguntaBorrarAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaBorrarAlbaran;
end;
function SAvisoAlmacenSalidaAlbaranObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SAvisoAlmacenSalidaAlbaranObligatorio;
end;
function SErrorLineaAlbaranSinArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaAlbaranSinArticulo;
end;
function SErrorCabeceraAlbaranSinGrabar: string;
begin
  Result :=
    inLibMsgVentas.SErrorCabeceraAlbaranSinGrabar;
end;
function SErrorAsignarLineaAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SErrorAsignarLineaAlbaran;
end;
function SErrorContadorAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SErrorContadorAlbaran;
end;
function SAvisoAlmacenDestinoAlbaranCompraObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SAvisoAlmacenDestinoAlbaranCompraObligatorio;
end;
function SAvisoAlbaranCompraFacturado: string;
begin
  Result :=
    inLibMsgCompras.SAvisoAlbaranCompraFacturado;
end;
function SPreguntaBorrarAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarAlbaranCompra;
end;
function SErrorContadorAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorAlbaranCompra;
end;
function SErrorCodigoSkuCodigoBarrasObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoSkuCodigoBarrasObligatorio;
end;
function SErrorCampoCodigoBarrasAusente: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCampoCodigoBarrasAusente;
end;
function SErrorCodigoSkuObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoSkuObligatorio;
end;
function SErrorFilaCodigoBarrasInexistente: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFilaCodigoBarrasInexistente;
end;
function SErrorProveedorPrincipalArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorProveedorPrincipalArticulo;
end;
function SErrorDescripcionArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDescripcionArticulo;
end;
function SPreguntaDesactivarTarifaSinPrecio: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaDesactivarTarifaSinPrecio;
end;
function SPreguntaActivarTarifaConPrecio: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaActivarTarifaConPrecio;
end;
function SErrorTarifaFechasConcurrentes: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaFechasConcurrentes;
end;
function SErrorAtributoBasicoObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAtributoBasicoObligatorio;
end;
function SErrorCodigoAtributoBasicoObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoAtributoBasicoObligatorio;
end;
function SErrorNombreAtributoBasicoObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorNombreAtributoBasicoObligatorio;
end;
function SErrorValorColeccionAtributosObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorValorColeccionAtributosObligatorio;
end;
function SPreguntaBorrarClienteConFacturas: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaBorrarClienteConFacturas;
end;
function SErrorRazonSocialCliente: string;
begin
  Result :=
    inLibMsgVentas.SErrorRazonSocialCliente;
end;
function SErrorCambiarFormatoSesion: string;
begin
  Result :=
    inLibMsgCompras.SErrorCambiarFormatoSesion;
end;
function SErrorEmpresaSesionObligatoria: string;
begin
  Result :=
    inLibMsgCompras.SErrorEmpresaSesionObligatoria;
end;
function SErrorSerieSesionObligatoria: string;
begin
  Result :=
    inLibMsgCompras.SErrorSerieSesionObligatoria;
end;
function SErrorContadorSesion: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorSesion;
end;
function SErrorCodigoSerieEmpresa: string;
begin
  Result :=
    inLibMsgCompras.SErrorCodigoSerieEmpresa;
end;
function SAvisoColacionSesion: string;
begin
  Result :=
    inLibMsgComun.SAvisoColacionSesion;
end;
function SAvisoTimeoutServidor: string;
begin
  Result :=
    inLibMsgComun.SAvisoTimeoutServidor;
end;
function SErrorBBDDDuplicado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDDuplicado;
end;
function SErrorBBDDCamposObligatorios: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDCamposObligatorios;
end;
function SErrorBBDDCampoDesconocido: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDCampoDesconocido;
end;
function SErrorBBDDTablaNoExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDTablaNoExiste;
end;
function SErrorBBDDSinPermisos: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDSinPermisos;
end;
function SErrorBBDDClaveForaneaNoExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDClaveForaneaNoExiste;
end;
function SErrorBBDDRegistroDependiente: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDRegistroDependiente;
end;
function SErrorBBDDDatoDemasiadoLargo: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDDatoDemasiadoLargo;
end;
function SErrorBBDDCredencialesIncorrectas: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDCredencialesIncorrectas;
end;
function SErrorBBDDConexionServidor: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDConexionServidor;
end;
function SErrorBBDDConexionPerdida: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDConexionPerdida;
end;
function SErrorBBDDConexionPerdidaConsulta: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDConexionPerdidaConsulta;
end;
function SErrorBBDDTimeoutBloqueo: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDTimeoutBloqueo;
end;
function SErrorBBDDDeadlock: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDDeadlock;
end;
function SErrorBBDDTablaYaExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDTablaYaExiste;
end;
function SErrorBBDDProcedimientoYaExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDProcedimientoYaExiste;
end;
function SErrorBBDDGenerico: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorBBDDGenerico;
end;
function SDetalleErrorMySQL: string;
begin
  Result :=
    inLibMsgComun.SDetalleErrorMySQL;
end;
function SErrorAbrirConsultaOpe: string;
begin
  Result :=
    inLibMsgComun.SErrorAbrirConsultaOpe;
end;
function SErrorAlmacenSalidaDevolucionCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenSalidaDevolucionCompra;
end;
function SAvisoDevolucionCompraFacturada: string;
begin
  Result :=
    inLibMsgCompras.SAvisoDevolucionCompraFacturada;
end;
function SPreguntaBorrarDevolucionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarDevolucionCompra;
end;
function SErrorCabeceraDevolucionCompraSinGrabar: string;
begin
  Result :=
    inLibMsgCompras.SErrorCabeceraDevolucionCompraSinGrabar;
end;
function SErrorContadorDevolucionCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorDevolucionCompra;
end;
function SErrorTipoDestinoDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SErrorTipoDestinoDocumentoTrabajo;
end;
function SErrorDestinoCompartidoNoExiste: string;
begin
  Result :=
    inLibMsgVentas.SErrorDestinoCompartidoNoExiste;
end;
function SErrorDestinoCompartirObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SErrorDestinoCompartirObligatorio;
end;
function SErrorCompartirDocumentoTrabajoSoloPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorCompartirDocumentoTrabajoSoloPropietario;
end;
function SErrorCabeceraDocumentoTrabajoSinGrabar: string;
begin
  Result :=
    inLibMsgVentas.SErrorCabeceraDocumentoTrabajoSinGrabar;
end;
function SErrorCompartirDocumentoTrabajoConsigoMismo: string;
begin
  Result :=
    inLibMsgVentas.SErrorCompartirDocumentoTrabajoConsigoMismo;
end;
function SErrorBorrarDocumentoTrabajoSoloPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorBorrarDocumentoTrabajoSoloPropietario;
end;
function SErrorCambiarPropietarioDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SErrorCambiarPropietarioDocumentoTrabajo;
end;
function SErrorTituloDocumentoTrabajoObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SErrorTituloDocumentoTrabajoObligatorio;
end;
function SErrorBorrarLineasDocumentoTrabajoSoloPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorBorrarLineasDocumentoTrabajoSoloPropietario;
end;
function SErrorEditarLineasDocumentoTrabajoSoloPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorEditarLineasDocumentoTrabajoSoloPropietario;
end;
function SErrorArticuloLineaDocumentoTrabajoObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloLineaDocumentoTrabajoObligatorio;
end;
function SErrorSkuLineaDocumentoTrabajoObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuLineaDocumentoTrabajoObligatorio;
end;
function SErrorDejarCompartirDocumentoTrabajoSoloPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorDejarCompartirDocumentoTrabajoSoloPropietario;
end;
function SErrorDestinoCompartidoObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SErrorDestinoCompartidoObligatorio;
end;
function SErrorBorrarEfectoCompraRemesado: string;
begin
  Result :=
    inLibMsgCompras.SErrorBorrarEfectoCompraRemesado;
end;
function SErrorBorrarEfectoCompraPagado: string;
begin
  Result :=
    inLibMsgCompras.SErrorBorrarEfectoCompraPagado;
end;
function SErrorFusionarEfectosCompraEstado: string;
begin
  Result :=
    inLibMsgCompras.SErrorFusionarEfectosCompraEstado;
end;
function SErrorFusionarEfectosCompraOrigen: string;
begin
  Result :=
    inLibMsgCompras.SErrorFusionarEfectosCompraOrigen;
end;
function SErrorFusionarEfectosCompraSinPendiente: string;
begin
  Result :=
    inLibMsgCompras.SErrorFusionarEfectosCompraSinPendiente;
end;
function SErrorBorrarEfectoVentaRemesado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBorrarEfectoVentaRemesado;
end;
function SErrorBorrarEfectoVentaCobrado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBorrarEfectoVentaCobrado;
end;
function SErrorFusionarEfectosVentaEstado: string;
begin
  Result :=
    inLibMsgVentas.SErrorFusionarEfectosVentaEstado;
end;
function SErrorFusionarEfectosVentaOrigen: string;
begin
  Result :=
    inLibMsgVentas.SErrorFusionarEfectosVentaOrigen;
end;
function SErrorFusionarEfectosVentaSinPendiente: string;
begin
  Result :=
    inLibMsgVentas.SErrorFusionarEfectosVentaSinPendiente;
end;
function SPreguntaCambioCriticoEmpresa: string;
begin
  Result :=
    inLibMsgComun.SPreguntaCambioCriticoEmpresa;
end;
function SErrorPorcentajeRetencionEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorPorcentajeRetencionEmpresa;
end;
function SErrorRetencionesEmpresaConcurrentes: string;
begin
  Result :=
    inLibMsgComun.SErrorRetencionesEmpresaConcurrentes;
end;
function SErrorSerieEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorSerieEmpresa;
end;
function SErrorIbanEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorIbanEmpresa;
end;
function SPreguntaBorrarEmpresaConFacturas: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaBorrarEmpresaConFacturas;
end;
function SErrorRazonSocialEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorRazonSocialEmpresa;
end;
function SErrorCodigoEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoEmpresa;
end;
function SErrorOperacionIntracomunitariaClienteNoUE: string;
begin
  Result :=
    inLibMsgVentas.SErrorOperacionIntracomunitariaClienteNoUE;
end;
function SErrorOperacionExportacionClienteNoExtranjero: string;
begin
  Result :=
    inLibMsgVentas.SErrorOperacionExportacionClienteNoExtranjero;
end;
function SErrorOperacionSinIvaConCuota: string;
begin
  Result :=
    inLibMsgFacturas.SErrorOperacionSinIvaConCuota;
end;
function SErrorNifIvaClienteExtranjero: string;
begin
  Result :=
    inLibMsgVentas.SErrorNifIvaClienteExtranjero;
end;
function SErrorCalcularBorradorDetalle: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCalcularBorradorDetalle;
end;
function SErrorCalculoBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCalculoBorrador;
end;
function SErrorTipoIvaFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorTipoIvaFactura;
end;
function SErrorBorrarBorradorFase: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorrarBorradorFase;
end;
function SPreguntaBorrarFactura: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaBorrarFactura;
end;
function SErrorBorrarBorradorEfectosCobrados: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorrarBorradorEfectosCobrados;
end;
function SErrorInsertarLineasCabeceraFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorInsertarLineasCabeceraFactura;
end;
function SErrorBorradorSinGrabarParaLineas: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorSinGrabarParaLineas;
end;
function SErrorSerieFacturaOtraEmpresa: string;
begin
  Result :=
    inLibMsgFacturas.SErrorSerieFacturaOtraEmpresa;
end;
function SErrorRazonSocialClienteBorrador: string;
begin
  Result :=
    inLibMsgVentas.SErrorRazonSocialClienteBorrador;
end;
function SErrorRazonSocialEmpresaBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SErrorRazonSocialEmpresaBorrador;
end;
function SErrorSerieBorradorObligatoria: string;
begin
  Result :=
    inLibMsgFacturas.SErrorSerieBorradorObligatoria;
end;
function SErrorPaisClienteEmpresaBorrador: string;
begin
  Result :=
    inLibMsgVentas.SErrorPaisClienteEmpresaBorrador;
end;
function SErrorFechaBorradorObligatoria: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFechaBorradorObligatoria;
end;
function SErrorNifClienteFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorNifClienteFactura;
end;
function SErrorNifEmpresaFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorNifEmpresaFactura;
end;
function SErrorFechaFacturaAnteriorSerie: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFechaFacturaAnteriorSerie;
end;
function SAvisoFechaBorradorFutura: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoFechaBorradorFutura;
end;
function SErrorCabeceraBorradorSinGrabar: string;
begin
  Result :=
    inLibMsgComun.SErrorCabeceraBorradorSinGrabar;
end;
function SErrorAsignarNumeroFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorAsignarNumeroFactura;
end;
function SAvisoHuecoNumeracionFactura: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoHuecoNumeracionFactura;
end;
function SErrorCerrarFacturaCompraSinLineas: string;
begin
  Result :=
    inLibMsgCompras.SErrorCerrarFacturaCompraSinLineas;
end;
function SErrorBorrarFacturaCompraEfectosPagados: string;
begin
  Result :=
    inLibMsgCompras.SErrorBorrarFacturaCompraEfectosPagados;
end;
function SPreguntaBorrarFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarFacturaCompra;
end;
function SErrorCabeceraFacturaCompraSinGrabar: string;
begin
  Result :=
    inLibMsgCompras.SErrorCabeceraFacturaCompraSinGrabar;
end;
function SErrorContadorFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorFacturaCompra;
end;
function SAvisoPropiedadFamiliaDuplicada: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoPropiedadFamiliaDuplicada;
end;
function SErrorNombreFamilia: string;
begin
  Result :=
    inLibMsgArticulos.SErrorNombreFamilia;
end;
function SErrorFamiliaPadreIgualHija: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFamiliaPadreIgualHija;
end;
function SErrorServicioConexionesDatosNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorServicioConexionesDatosNoConfigurado;
end;
function SErrorContextoSesionFiltrosNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorContextoSesionFiltrosNoConfigurado;
end;
function SErrorCodigoFacturaeFormaPago: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCodigoFacturaeFormaPago;
end;
function SErrorDescripcionFormaPago: string;
begin
  Result :=
    inLibMsgComun.SErrorDescripcionFormaPago;
end;
function SErrorContextoSesionModuloDatosNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorContextoSesionModuloDatosNoConfigurado;
end;
function SErrorSerieInventarioObligatoria: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSerieInventarioObligatoria;
end;
function SErrorContadorLineasInventarioNoInstalado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorContadorLineasInventarioNoInstalado;
end;
function SErrorCabeceraInventarioSinGrabarParaReserva: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCabeceraInventarioSinGrabarParaReserva;
end;
function SErrorCabeceraInventarioNoEncontrada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCabeceraInventarioNoEncontrada;
end;
function SErrorActualizarContadorLineasInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorActualizarContadorLineasInventario;
end;
function SErrorEmpresaCabeceraInventarioObligatoria: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEmpresaCabeceraInventarioObligatoria;
end;
function SErrorAlmacenCabeceraInventarioObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAlmacenCabeceraInventarioObligatorio;
end;
function SErrorSerieCabeceraInventarioObligatoria: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSerieCabeceraInventarioObligatoria;
end;
function SErrorNumeroCabeceraInventarioObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorNumeroCabeceraInventarioObligatorio;
end;
function SErrorAtributoLineaInventarioObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAtributoLineaInventarioObligatorio;
end;
function SPreguntaCrearSkuInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCrearSkuInventario;
end;
function SErrorSkuInventarioNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuInventarioNoExiste;
end;
function SErrorEliminarLineasInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEliminarLineasInventarioNoAbierto;
end;
function SErrorAnadirLineaCabeceraInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAnadirLineaCabeceraInventario;
end;
function SErrorRecalcularInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorRecalcularInventarioNoAbierto;
end;
function SErrorAplicarInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAplicarInventarioNoAbierto;
end;
function SErrorAplicarInventarioSinLineas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAplicarInventarioSinLineas;
end;
function SErrorEliminarRegularizacionInventarioNoAplicado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEliminarRegularizacionInventarioNoAplicado;
end;
function SErrorCargarArticulosInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCargarArticulosInventarioNoAbierto;
end;
function SErrorCompletarInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCompletarInventarioNoAbierto;
end;
function SErrorArticuloLineaInventarioObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloLineaInventarioObligatorio;
end;
function SErrorAnadirSkusInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAnadirSkusInventarioNoAbierto;
end;
function SErrorValorAtributoSkuInventarioNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorValorAtributoSkuInventarioNoEncontrado;
end;
function SErrorCodigoIva: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoIva;
end;
function SErrorGrupoIvaNoExiste: string;
begin
  Result :=
    inLibMsgComun.SErrorGrupoIvaNoExiste;
end;
function SErrorRangoFechasIva: string;
begin
  Result :=
    inLibMsgComun.SErrorRangoFechasIva;
end;
function SErrorDescripcionGrupoIva: string;
begin
  Result :=
    inLibMsgComun.SErrorDescripcionGrupoIva;
end;
function SErrorCodigoGrupoIva: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoGrupoIva;
end;
function SErrorDosGruposIvaPredeterminados: string;
begin
  Result :=
    inLibMsgComun.SErrorDosGruposIvaPredeterminados;
end;
function SAvisoEdicionMovimientoAlmacen: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoEdicionMovimientoAlmacen;
end;
function SPreguntaBorrarPedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaBorrarPedidoVenta;
end;
function SErrorLineaPedidoSinArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaPedidoSinArticulo;
end;
function SErrorCabeceraPedidoSinGrabar: string;
begin
  Result :=
    inLibMsgVentas.SErrorCabeceraPedidoSinGrabar;
end;
function SErrorAsignarLineaPedido: string;
begin
  Result :=
    inLibMsgVentas.SErrorAsignarLineaPedido;
end;
function SAvisoAlmacenSalidaPedidoObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SAvisoAlmacenSalidaPedidoObligatorio;
end;
function SAvisoClientePedidoObligatorio: string;
begin
  Result :=
    inLibMsgVentas.SAvisoClientePedidoObligatorio;
end;
function SAvisoClientePedidoNoExiste: string;
begin
  Result :=
    inLibMsgVentas.SAvisoClientePedidoNoExiste;
end;
function SAvisoAlmacenDestinoPedidoCompraObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SAvisoAlmacenDestinoPedidoCompraObligatorio;
end;
function SPreguntaBorrarPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarPedidoCompra;
end;
function SErrorContadorPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorPedidoCompra;
end;
function SErrorContextoSesionPerfilesNoConfigurado: string;
begin
  Result :=
    inLibMsgComun.SErrorContextoSesionPerfilesNoConfigurado;
end;
function SErrorProveedorKitsNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorKitsNoSeleccionado;
end;
function SErrorProveedorKitsSinGrabar: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorKitsSinGrabar;
end;
function SErrorCodigoKitProveedorObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SErrorCodigoKitProveedorObligatorio;
end;
function SErrorNombreKitProveedorObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SErrorNombreKitProveedorObligatorio;
end;
function SErrorKitProveedorNoSeleccionadoParaTallas: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitProveedorNoSeleccionadoParaTallas;
end;
function SErrorTallaDestinoKitProveedorObligatoria: string;
begin
  Result :=
    inLibMsgCompras.SErrorTallaDestinoKitProveedorObligatoria;
end;
function SErrorKitProveedorNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitProveedorNoSeleccionado;
end;
function SErrorSistemaTallasKitProveedorObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SErrorSistemaTallasKitProveedorObligatorio;
end;
function SErrorCodigoAutomaticoProveedor: string;
begin
  Result :=
    inLibMsgCompras.SErrorCodigoAutomaticoProveedor;
end;
function SErrorOrdenAutomaticoProveedor: string;
begin
  Result :=
    inLibMsgCompras.SErrorOrdenAutomaticoProveedor;
end;
function SErrorRemesaVentaNoSeleccionada: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaVentaNoSeleccionada;
end;
function SErrorRemesaVentaNoEncontrada: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaVentaNoEncontrada;
end;
function SErrorRemesaVentaSinEfectosPendientes: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaVentaSinEfectosPendientes;
end;
function SErrorGuardarCodigoAcreedorSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorGuardarCodigoAcreedorSepa;
end;
function SErrorGuardarMandatoSepaCliente: string;
begin
  Result :=
    inLibMsgVentas.SErrorGuardarMandatoSepaCliente;
end;
function SErrorNombreSesionCambioTarifaObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorNombreSesionCambioTarifaObligatorio;
end;
function SErrorTarifaDestinoObligatoria: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaDestinoObligatoria;
end;
function SErrorNombreUsuario: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorNombreUsuario;
end;
function SErrorUsuarioCoincideGrupo: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorUsuarioCoincideGrupo;
end;
function SErrorCodigoAtributoVariacionObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoAtributoVariacionObligatorio;
end;
function SErrorConexionPrincipalTrabajoNoDisponible: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorConexionPrincipalTrabajoNoDisponible;
end;
function SErrorPrefijoEanSesionLargo: string;
begin
  Result :=
    inLibMsgCompras.SErrorPrefijoEanSesionLargo;
end;
function SErrorColorBasicoMaterializacionNoExiste: string;
begin
  Result :=
    inLibMsgCompras.SErrorColorBasicoMaterializacionNoExiste;
end;
function SErrorAlmacenSesionParaAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenSesionParaAlbaranCompra;
end;
function SErrorAlmacenSesionParaPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenSesionParaPedidoCompra;
end;
function SErrorAlmacenSesionParaPendienteRecibir: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenSesionParaPendienteRecibir;
end;
function SAvisoSelectorConjuntoFilaNoImplementado: string;
begin
  Result :=
    inLibMsgCompras.SAvisoSelectorConjuntoFilaNoImplementado;
end;
function STituloNuevaFilaCompra: string;
begin
  Result :=
    inLibMsgCompras.STituloNuevaFilaCompra;
end;
function SSolicitudNombreFilaCompra: string;
begin
  Result :=
    inLibMsgCompras.SSolicitudNombreFilaCompra;
end;
function SAvisoConjuntoPivotCompraObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SAvisoConjuntoPivotCompraObligatorio;
end;
function SErrorConjuntoPivotCompraNoExiste: string;
begin
  Result :=
    inLibMsgCompras.SErrorConjuntoPivotCompraNoExiste;
end;
function STituloAnadirValorPivotCompra: string;
begin
  Result :=
    inLibMsgCompras.STituloAnadirValorPivotCompra;
end;
function SSolicitudNombreValorPivotCompra: string;
begin
  Result :=
    inLibMsgCompras.SSolicitudNombreValorPivotCompra;
end;
function SSolicitudOrdenValorPivotCompra: string;
begin
  Result :=
    inLibMsgCompras.SSolicitudOrdenValorPivotCompra;
end;
function SErrorDistribuidorTallasNoRegistrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDistribuidorTallasNoRegistrado;
end;
function SErrorInvarianteUnidadesTallas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInvarianteUnidadesTallas;
end;
function SErrorAlmacenDistribucionTallasNoDisponible: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAlmacenDistribucionTallasNoDisponible;
end;
function SErrorArticuloSkuNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSkuNoEncontrado;
end;
function SAvisoArticuloSinAtributos: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoArticuloSinAtributos;
end;
function SErrorFactoriaTallasHorizontalObligatoria: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFactoriaTallasHorizontalObligatoria;
end;
function SErrorOperacionCanceladaUsuario: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorOperacionCanceladaUsuario;
end;
function SErrorRestauracionEstructuraIncompleta: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorRestauracionEstructuraIncompleta;
end;
function SErrorNombreBBDDDestinoVacio: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorNombreBBDDDestinoVacio;
end;
function SErrorFicheroCopiaNoExiste: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorFicheroCopiaNoExiste;
end;
function SErrorDesencriptarCopia: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorDesencriptarCopia;
end;
function SErrorAlbaranCompraMovimientosNoEncontrado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraMovimientosNoEncontrado;
end;
function SErrorAlbaranCompraMovimientosYaGenerados: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraMovimientosYaGenerados;
end;
function SErrorAlbaranCompraSinCantidadParaMovimientos: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraSinCantidadParaMovimientos;
end;
function SErrorDivisaNoEncontrada: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorDivisaNoEncontrada;
end;
function SErrorHttpDivisas: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorHttpDivisas;
end;
function SErrorRedDivisas: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorRedDivisas;
end;
function SErrorJsonDivisas: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorJsonDivisas;
end;
function SErrorPruebaPilaJcl: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorPruebaPilaJcl;
end;
function SErrorDevolucionCompraMovimientosNoEncontrada: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraMovimientosNoEncontrada;
end;
function SErrorDevolucionCompraMovimientosYaGenerados: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraMovimientosYaGenerados;
end;
function SErrorDevolucionCompraSinCantidadParaMovimientos: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraSinCantidadParaMovimientos;
end;
function SErrorEmpresaSinAlmacenActivo: string;
begin
  Result :=
    inLibMsgComun.SErrorEmpresaSinAlmacenActivo;
end;
function SErrorAlmacenDepositosEmpresaNoEncontrado: string;
begin
  Result :=
    inLibMsgComun.SErrorAlmacenDepositosEmpresaNoEncontrado;
end;
function SErrorLimitePeticionesCripto: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorLimitePeticionesCripto;
end;
function SErrorHttpCripto: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorHttpCripto;
end;
function SErrorRedCripto: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorRedCripto;
end;
function SErrorJsonCripto: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorJsonCripto;
end;
function SPreguntaCrearDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaCrearDocumentoTrabajo;
end;
function STituloAgregarDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.STituloAgregarDocumentoTrabajo;
end;
function STituloNuevoDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.STituloNuevoDocumentoTrabajo;
end;
function SSolicitudTituloDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SSolicitudTituloDocumentoTrabajo;
end;
function SErrorArticuloDocumentoTrabajoNoActivo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloDocumentoTrabajoNoActivo;
end;
function SErrorArticuloDocumentoTrabajoVariosSkus: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloDocumentoTrabajoVariosSkus;
end;
function SInfoUnidadAgregadaDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SInfoUnidadAgregadaDocumentoTrabajo;
end;
function STituloDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.STituloDocumentoTrabajo;
end;
function SErrorArticuloNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoExiste;
end;
function SErrorEntradaArticuloVacia: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEntradaArticuloVacia;
end;
function SErrorCodigoBarrasNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoBarrasNoEncontrado;
end;
function SErrorArticuloEntradaNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloEntradaNoEncontrado;
end;
function SAvisoArticuloRequiereSku: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoArticuloRequiereSku;
end;
function SErrorArticuloVariacionSinSkusActivos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloVariacionSinSkusActivos;
end;
function SErrorArticuloSinSkusActivos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSinSkusActivos;
end;
function SErrorSkuNoPerteneceArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuNoPerteneceArticulo;
end;
function SErrorSesionCompraNoActiva: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionCompraNoActiva;
end;
function SErrorLineaArticuloSesionNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaArticuloSesionNoSeleccionada;
end;
function SErrorLineaSesionSinNumero: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaSesionSinNumero;
end;
function SErrorSistemaTallasLineaSesionObligatorio: string;
begin
  Result :=
    inLibMsgCompras.SErrorSistemaTallasLineaSesionObligatorio;
end;
function SErrorKitProveedorNoExiste: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitProveedorNoExiste;
end;
function SErrorKitSinSistemaTallas: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitSinSistemaTallas;
end;
function SErrorTallajeKitNoCoincide: string;
begin
  Result :=
    inLibMsgCompras.SErrorTallajeKitNoCoincide;
end;
function SErrorGestorTallasNoInicializado: string;
begin
  Result :=
    inLibMsgCompras.SErrorGestorTallasNoInicializado;
end;
function SErrorKitSinTallasDefinidas: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitSinTallasDefinidas;
end;
function SAvisoTallasKitSinCorrespondencia: string;
begin
  Result :=
    inLibMsgCompras.SAvisoTallasKitSinCorrespondencia;
end;
function SErrorTallasKitSinCorrespondencia: string;
begin
  Result :=
    inLibMsgCompras.SErrorTallasKitSinCorrespondencia;
end;
function SErrorSesionIncidenciasSinDetalle: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionIncidenciasSinDetalle;
end;
function SErrorDataModuleSesionNoInicializado: string;
begin
  Result :=
    inLibMsgCompras.SErrorDataModuleSesionNoInicializado;
end;
function SErrorSesionNoCerradaParaRevertir: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionNoCerradaParaRevertir;
end;
function SErrorRestauracionNoFinalizada: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorRestauracionNoFinalizada;
end;
function SErrorCodigoArticuloResolverObligatorio: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoArticuloResolverObligatorio;
end;
function SErrorArticuloResolverNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloResolverNoExiste;
end;
function SAvisoArticuloResolverRequiereSku: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoArticuloResolverRequiereSku;
end;
function STextoLineaIncidenciaSesion: string;
begin
  Result :=
    inLibMsgCompras.STextoLineaIncidenciaSesion;
end;
function STextoCabeceraIncidenciaSesion: string;
begin
  Result :=
    inLibMsgCompras.STextoCabeceraIncidenciaSesion;
end;
function SFormatoIncidenciaSesion: string;
begin
  Result :=
    inLibMsgCompras.SFormatoIncidenciaSesion;
end;
function SErrorSesionInactivaIncidencia: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionInactivaIncidencia;
end;
function STipoIncidenciaCabecera: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaCabecera;
end;
function SErrorEmpresaSesionFaltante: string;
begin
  Result :=
    inLibMsgCompras.SErrorEmpresaSesionFaltante;
end;
function SErrorProveedorSesionFaltante: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorSesionFaltante;
end;
function SErrorAlmacenSesionFaltante: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenSesionFaltante;
end;
function SErrorSesionSinLineas: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionSinLineas;
end;
function STipoIncidenciaDuplicadoInterno: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaDuplicadoInterno;
end;
function SErrorCodigoDuplicadoInternoSesion: string;
begin
  Result :=
    inLibMsgCompras.SErrorCodigoDuplicadoInternoSesion;
end;
function STipoIncidenciaDuplicado: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaDuplicado;
end;
function SErrorCodigoDuplicadoSesion: string;
begin
  Result :=
    inLibMsgCompras.SErrorCodigoDuplicadoSesion;
end;
function STextoArticuloInactivoSesion: string;
begin
  Result :=
    inLibMsgArticulos.STextoArticuloInactivoSesion;
end;
function STipoIncidenciaCodigo: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaCodigo;
end;
function SErrorLineaSesionSinCodigo: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaSesionSinCodigo;
end;
function STipoIncidenciaDescripcion: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaDescripcion;
end;
function SErrorLineaSesionSinDescripcion: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaSesionSinDescripcion;
end;
function STipoIncidenciaCantidades: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaCantidades;
end;
function SErrorLineaMatrizSinCantidades: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaMatrizSinCantidades;
end;
function STipoIncidenciaSistemaTallas: string;
begin
  Result :=
    inLibMsgCompras.STipoIncidenciaSistemaTallas;
end;
function SErrorLineaMatrizSinSistemaTallas: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaMatrizSinSistemaTallas;
end;
function SErrorCodigoEanMinimo7Digitos: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoEanMinimo7Digitos;
end;
function SErrorCodigoBarrasNoNumerico: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoBarrasNoNumerico;
end;
function SErrorCodigoEanMinimo12Digitos: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoEanMinimo12Digitos;
end;
function SErrorFacturaeFaltaCampo: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeFaltaCampo;
end;
function STextoNifParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoNifParteFacturae;
end;
function STextoRazonSocialParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoRazonSocialParteFacturae;
end;
function STextoDireccionParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoDireccionParteFacturae;
end;
function STextoCodigoPostalParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoCodigoPostalParteFacturae;
end;
function STextoPoblacionParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoPoblacionParteFacturae;
end;
function STextoProvinciaParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoProvinciaParteFacturae;
end;
function SErrorDocumentoFiscalParteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorDocumentoFiscalParteFacturae;
end;
function SErrorFaltaCodigoDir3Facturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFaltaCodigoDir3Facturae;
end;
function SErrorCodigoDir3LargoFacturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCodigoDir3LargoFacturae;
end;
function STextoEmpresaEmisoraFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoEmpresaEmisoraFacturae;
end;
function STextoClienteFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoClienteFacturae;
end;
function STextoOficinaContableFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoOficinaContableFacturae;
end;
function STextoOrganoGestorFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoOrganoGestorFacturae;
end;
function STextoUnidadTramitadoraFacturae: string;
begin
  Result :=
    inLibMsgFacturas.STextoUnidadTramitadoraFacturae;
end;
function SErrorNombrePersonaFisicaFacturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorNombrePersonaFisicaFacturae;
end;
function SErrorApellidosPersonaFisicaFacturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorApellidosPersonaFisicaFacturae;
end;
function SErrorCodigoPagoFacturaeInvalido: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCodigoPagoFacturaeInvalido;
end;
function SErrorFacturaeNoExiste: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeNoExiste;
end;
function SErrorFacturaeTipoVentaInvalido: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeTipoVentaInvalido;
end;
function SErrorFacturaeNoConsolidada: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeNoConsolidada;
end;
function SErrorFacturaeFechaOficialFaltante: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeFechaOficialFaltante;
end;
function SErrorLineaFacturaeSinDescripcion: string;
begin
  Result :=
    inLibMsgFacturas.SErrorLineaFacturaeSinDescripcion;
end;
function SErrorLineaFacturaeCantidadCero: string;
begin
  Result :=
    inLibMsgFacturas.SErrorLineaFacturaeCantidadCero;
end;
function SErrorFacturaeSinLineas: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaeSinLineas;
end;
function SErrorBasesFacturaeNoCuadran: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBasesFacturaeNoCuadran;
end;
function SErrorTotalesFacturaeNoCuadran: string;
begin
  Result :=
    inLibMsgFacturas.SErrorTotalesFacturaeNoCuadran;
end;
function SErrorEmitirFacturae: string;
begin
  Result :=
    inLibMsgFacturas.SErrorEmitirFacturae;
end;
function SErrorCertificadoFacturaeNoConfigurado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCertificadoFacturaeNoConfigurado;
end;
function SErrorConexionFacturaeNoDisponible: string;
begin
  Result :=
    inLibMsgFacturas.SErrorConexionFacturaeNoDisponible;
end;
function SErrorFicheroSalidaFacturaeNoIndicado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFicheroSalidaFacturaeNoIndicado;
end;
function SErrorPorcentajeIvaFueraRango: string;
begin
  Result :=
    inLibMsgFacturas.SErrorPorcentajeIvaFueraRango;
end;
function SErrorPrecioFacturaNegativo: string;
begin
  Result :=
    inLibMsgFacturas.SErrorPrecioFacturaNegativo;
end;
function SErrorRespuestaHttpFactuzamApi: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorRespuestaHttpFactuzamApi;
end;
function SErrorFactuzamApiNoConfigurada: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorFactuzamApiNoConfigurada;
end;
function SInfoEventoFactuzamApiRecibido: string;
begin
  Result :=
    inLibMsgIntegraciones.SInfoEventoFactuzamApiRecibido;
end;
function SInfoConsultaFactuzamApiRealizada: string;
begin
  Result :=
    inLibMsgIntegraciones.SInfoConsultaFactuzamApiRealizada;
end;
function SInfoDocumentoFactuzamApiGuardado: string;
begin
  Result :=
    inLibMsgIntegraciones.SInfoDocumentoFactuzamApiGuardado;
end;
function SInfoDocumentoFactuzamApiDescargado: string;
begin
  Result :=
    inLibMsgIntegraciones.SInfoDocumentoFactuzamApiDescargado;
end;
function SErrorImportarImagenCodec: string;
begin
  Result :=
    inLibMsgArticulos.SErrorImportarImagenCodec;
end;
function SErrorGuardarFotoSinCodigoArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarFotoSinCodigoArticulo;
end;
function SErrorFicheroOrigenFotoNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFicheroOrigenFotoNoExiste;
end;
function SErrorDirectorioFotosNoConfigurado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDirectorioFotosNoConfigurado;
end;
function SErrorFotoNoRegistradaParaRotar: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoNoRegistradaParaRotar;
end;
function SErrorFotoSesionSinSerie: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoSesionSinSerie;
end;
function SErrorFotoSesionSinNumero: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoSesionSinNumero;
end;
function SErrorFotoSesionLineaInvalida: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoSesionLineaInvalida;
end;
function STextoParametroUrlFotosNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroUrlFotosNube;
end;
function STextoParametroTokenFotosNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroTokenFotosNube;
end;
function STextoParametroReferenciaFotosNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroReferenciaFotosNube;
end;
function STextoParametroCarpetaFotosNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroCarpetaFotosNube;
end;
function SErrorParametrosFotosNubeFaltantes: string;
begin
  Result :=
    inLibMsgArticulos.SErrorParametrosFotosNubeFaltantes;
end;
function SErrorServidorFotosNubeHttp: string;
begin
  Result :=
    inLibMsgArticulos.SErrorServidorFotosNubeHttp;
end;
function SErrorConexionServidorFotosNube: string;
begin
  Result :=
    inLibMsgArticulos.SErrorConexionServidorFotosNube;
end;
function SErrorAbrirImpresoraTicket: string;
begin
  Result :=
    inLibMsgFacturas.SErrorAbrirImpresoraTicket;
end;
function SErrorIniciarDocumentoImpresora: string;
begin
  Result :=
    inLibMsgFacturas.SErrorIniciarDocumentoImpresora;
end;
function SErrorEscribirImpresora: string;
begin
  Result :=
    inLibMsgFacturas.SErrorEscribirImpresora;
end;
function SErrorEjecutorBusquedasNoRegistrado: string;
begin
  Result :=
    inLibMsgComun.SErrorEjecutorBusquedasNoRegistrado;
end;
function SErrorOperacionCajaNoEncontrada: string;
begin
  Result :=
    inLibMsgCaja.SErrorOperacionCajaNoEncontrada;
end;
function SErrorValoresAtributoNoDefinidos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorValoresAtributoNoDefinidos;
end;
function SErrorColorCompraNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorColorCompraNoSeleccionado;
end;
function SErrorConexionResolverColorCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorConexionResolverColorCompra;
end;
function SErrorColorBasicoCompraNoExiste: string;
begin
  Result :=
    inLibMsgCompras.SErrorColorBasicoCompraNoExiste;
end;
function SErrorResolverColorCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorResolverColorCompra;
end;
function SErrorArticuloSinSistemaTallasPivote: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSinSistemaTallasPivote;
end;
function SErrorSistemaTallasSuperaMaximoPivote: string;
begin
  Result :=
    inLibMsgCompras.SErrorSistemaTallasSuperaMaximoPivote;
end;
function SErrorSkuFueraSistemaTallasPivote: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuFueraSistemaTallasPivote;
end;
function SErrorActivarPivoteTallas: string;
begin
  Result :=
    inLibMsgCompras.SErrorActivarPivoteTallas;
end;
function SErrorActivarTallasHorizontalesParaColor: string;
begin
  Result :=
    inLibMsgCompras.SErrorActivarTallasHorizontalesParaColor;
end;
function SErrorLineaActivaColorNoDisponible: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaActivaColorNoDisponible;
end;
function SErrorColorCompraConCantidades: string;
begin
  Result :=
    inLibMsgCompras.SErrorColorCompraConCantidades;
end;
function SErrorConsultaLineasCompraNoAbierta: string;
begin
  Result :=
    inLibMsgCompras.SErrorConsultaLineasCompraNoAbierta;
end;
function SErrorLineaActivaColorNoEncontrada: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaActivaColorNoEncontrada;
end;
function SErrorLineaActivaCompraSinArticulo: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaActivaCompraSinArticulo;
end;
function SPreguntaEliminarLineaTallasVenta: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEliminarLineaTallasVenta;
end;
function SErrorArticuloSkuNoEncontradoSinDetalle: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSkuNoEncontradoSinDetalle;
end;
function SPreguntaEliminarLineaSkuCantidadCero: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEliminarLineaSkuCantidadCero;
end;
function SInfoLineaPedidoTallaNoExiste: string;
begin
  Result :=
    inLibMsgVentas.SInfoLineaPedidoTallaNoExiste;
end;
function SAvisoSistemaTallasSuperaMaximo: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoSistemaTallasSuperaMaximo;
end;
function SErrorHojaCalculoNoActiva: string;
begin
  Result :=
    inLibMsgComun.SErrorHojaCalculoNoActiva;
end;
function SErrorControlHojaCalculoObligatorio: string;
begin
  Result :=
    inLibMsgComun.SErrorControlHojaCalculoObligatorio;
end;
function SErrorGuardarHojaCalculoControlObligatorio: string;
begin
  Result :=
    inLibMsgComun.SErrorGuardarHojaCalculoControlObligatorio;
end;
function SErrorIbanInvalido: string;
begin
  Result :=
    inLibMsgComun.SErrorIbanInvalido;
end;
function SErrorPaisIbanInvalido: string;
begin
  Result :=
    inLibMsgComun.SErrorPaisIbanInvalido;
end;
function SErrorDigitoControlIbanInvalido: string;
begin
  Result :=
    inLibMsgComun.SErrorDigitoControlIbanInvalido;
end;
function SErrorLongitudCuentaBancariaInvalida: string;
begin
  Result :=
    inLibMsgComun.SErrorLongitudCuentaBancariaInvalida;
end;
function SErrorCuentaBancariaInvalida: string;
begin
  Result :=
    inLibMsgComun.SErrorCuentaBancariaInvalida;
end;
function SErrorDigitoControlCuentaBancaria: string;
begin
  Result :=
    inLibMsgComun.SErrorDigitoControlCuentaBancaria;
end;
function SErrorPaisIbanInvalidoTipos: string;
begin
  Result :=
    inLibMsgComun.SErrorPaisIbanInvalidoTipos;
end;
function SErrorDigitoControlIbanInvalidoTipos: string;
begin
  Result :=
    inLibMsgComun.SErrorDigitoControlIbanInvalidoTipos;
end;
function STextoParametroUrlInventarioNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroUrlInventarioNube;
end;
function STextoParametroTokenInventarioNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroTokenInventarioNube;
end;
function STextoParametroReferenciaInventarioNube: string;
begin
  Result :=
    inLibMsgArticulos.STextoParametroReferenciaInventarioNube;
end;
function SErrorParametrosInventarioNubeFaltantes: string;
begin
  Result :=
    inLibMsgArticulos.SErrorParametrosInventarioNubeFaltantes;
end;
function SErrorServidorInventarioNubeHttp: string;
begin
  Result :=
    inLibMsgArticulos.SErrorServidorInventarioNubeHttp;
end;
function SErrorConexionServidorInventarioNube: string;
begin
  Result :=
    inLibMsgArticulos.SErrorConexionServidorInventarioNube;
end;
function SErrorInventarioNubeSinIdRecuento: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNubeSinIdRecuento;
end;
function SErrorDialogoPermisosLayoutNoRegistrado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorDialogoPermisosLayoutNoRegistrado;
end;
function STextoResetearLayout: string;
begin
  Result :=
    inLibMsgComun.STextoResetearLayout;
end;
function SInfoLayoutReseteado: string;
begin
  Result :=
    inLibMsgComun.SInfoLayoutReseteado;
end;
function SErrorLimiteDemoFacturas: string;
begin
  Result :=
    inLibMsgFacturas.SErrorLimiteDemoFacturas;
end;
function SErrorNifEmpresaLicenciaNoConfigurado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorNifEmpresaLicenciaNoConfigurado;
end;
function SInfoLicenciaSinNifEmpresa: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoLicenciaSinNifEmpresa;
end;
function SErrorLicenciaNoEncontrada: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorLicenciaNoEncontrada;
end;
function SInfoLicenciaValida: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoLicenciaValida;
end;
function SErrorLicenciaNifsNoCoinciden: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorLicenciaNifsNoCoinciden;
end;
function SErrorAccesoFicheroLog: string;
begin
  Result :=
    inLibMsgComun.SErrorAccesoFicheroLog;
end;
function SErrorCrearMutexLog: string;
begin
  Result :=
    inLibMsgComun.SErrorCrearMutexLog;
end;
function SErrorParametrosAplicacionNoProporcionados: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorParametrosAplicacionNoProporcionados;
end;
function SErrorRespuestaFormateadorSqlVacia: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorRespuestaFormateadorSqlVacia;
end;
function SErrorRespuestaFormateadorSqlInesperada: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorRespuestaFormateadorSqlInesperada;
end;
function SErrorServicioPerfilesNoProporcionado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorServicioPerfilesNoProporcionado;
end;
function SErrorCargarPerfilParametros: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorCargarPerfilParametros;
end;
function SErrorPedidoCompraSinPendientesAlmacen: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraSinPendientesAlmacen;
end;
function SErrorAlmacenPedidoCompraNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenPedidoCompraNoSeleccionado;
end;
function SErrorPedidoCompraSinCantidadesRecibir: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraSinCantidadesRecibir;
end;
function SErrorContadorAlbaranCompraNoDisponible: string;
begin
  Result :=
    inLibMsgCompras.SErrorContadorAlbaranCompraNoDisponible;
end;
function SErrorCrearLineasAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorCrearLineasAlbaranCompra;
end;
function SInfoAlbaranCompraCreado: string;
begin
  Result :=
    inLibMsgCompras.SInfoAlbaranCompraCreado;
end;
function SErrorAlbaranCompraDestinoNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraDestinoNoSeleccionado;
end;
function SInfoLineasIncorporadasAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SInfoLineasIncorporadasAlbaranCompra;
end;
function SErrorIncorporarLineasAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorIncorporarLineasAlbaranCompra;
end;
function SInfoLineasIncorporadasAlbaranCompraConCantidad: string;
begin
  Result :=
    inLibMsgCompras.SInfoLineasIncorporadasAlbaranCompraConCantidad;
end;
function SErrorConexionPermisosNoDisponible: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorConexionPermisosNoDisponible;
end;
function SErrorPreviewExcelNoRegistrado: string;
begin
  Result :=
    inLibMsgComun.SErrorPreviewExcelNoRegistrado;
end;
function SErrorPreviewTicketNoRegistrado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorPreviewTicketNoRegistrado;
end;
function SErrorRespuestaNtpNoValida: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRespuestaNtpNoValida;
end;
function SInfoRelojFiscalCorrecto: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoRelojFiscalCorrecto;
end;
function SErrorRelojSistemaFueraMargenLegal: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRelojSistemaFueraMargenLegal;
end;
function SErrorComprobarRelojFiscalNtp: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorComprobarRelojFiscalNtp;
end;
function SErrorContextoSinIban: string;
begin
  Result :=
    inLibMsgVentas.SErrorContextoSinIban;
end;
function SErrorContextoIbanNoValido: string;
begin
  Result :=
    inLibMsgVentas.SErrorContextoIbanNoValido;
end;
function SErrorNifEmpresaAcreedorSepaNoValido: string;
begin
  Result :=
    inLibMsgVentas.SErrorNifEmpresaAcreedorSepaNoValido;
end;
function SErrorClienteSinMandatoSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorClienteSinMandatoSepa;
end;
function STextoBancoCobroRemesa: string;
begin
  Result :=
    inLibMsgVentas.STextoBancoCobroRemesa;
end;
function SErrorConexionGenerarRemesaSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorConexionGenerarRemesaSepa;
end;
function SErrorArchivoSalidaSepaNoIndicado: string;
begin
  Result :=
    inLibMsgVentas.SErrorArchivoSalidaSepaNoIndicado;
end;
function SErrorRemesaSinFechaCobro: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaSinFechaCobro;
end;
function SErrorBancoCobroRemesaNoEncontrado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBancoCobroRemesaNoEncontrado;
end;
function SErrorBancoCobroSinCodigoAcreedorSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorBancoCobroSinCodigoAcreedorSepa;
end;
function SErrorCodigoAcreedorSepaNoValido: string;
begin
  Result :=
    inLibMsgVentas.SErrorCodigoAcreedorSepaNoValido;
end;
function SErrorEfectoSinNombreCliente: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectoSinNombreCliente;
end;
function STextoClienteSepa: string;
begin
  Result :=
    inLibMsgVentas.STextoClienteSepa;
end;
function SErrorClienteSinFechaFirmaMandatoSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorClienteSinFechaFirmaMandatoSepa;
end;
function SErrorRecalcularTotalesFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorRecalcularTotalesFactura;
end;
function SErrorGenerarContadorAutomatico: string;
begin
  Result :=
    inLibMsgComun.SErrorGenerarContadorAutomatico;
end;
function SErrorConexionBbddConExcepcion: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorConexionBbddConExcepcion;
end;
function SErrorNumeroCuentaInvalido: string;
begin
  Result :=
    inLibMsgComun.SErrorNumeroCuentaInvalido;
end;
function SErrorNifNoValido: string;
begin
  Result :=
    inLibMsgComun.SErrorNifNoValido;
end;
function SErrorLetraDniIncorrecta: string;
begin
  Result :=
    inLibMsgComun.SErrorLetraDniIncorrecta;
end;
function SErrorServicioPerfilesUsuarioNoConfigurado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorServicioPerfilesUsuarioNoConfigurado;
end;
function SErrorCrearSeleccionarDocumentoAntesLineas: string;
begin
  Result :=
    inLibMsgComun.SErrorCrearSeleccionarDocumentoAntesLineas;
end;
function SErrorCrearSeleccionarDocumentoAntesTallas: string;
begin
  Result :=
    inLibMsgComun.SErrorCrearSeleccionarDocumentoAntesTallas;
end;
function SErrorArticuloCursoSinSistemaTallas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloCursoSinSistemaTallas;
end;
function SErrorAltaSeleccionarArticuloConTallas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAltaSeleccionarArticuloConTallas;
end;
function SErrorArticuloSinSistemaTallasCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloSinSistemaTallasCompra;
end;
function SErrorActivarTallasHorizontalesCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorActivarTallasHorizontalesCompra;
end;
function SErrorEncolarVentaWebservice: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorEncolarVentaWebservice;
end;
function SErrorFacturaWebserviceNoExiste: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaWebserviceNoExiste;
end;
function SErrorExportarNoVerifactuSinCertificado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorExportarNoVerifactuSinCertificado;
end;
function SErrorExportarNoVerifactuSinColumnasEventos: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorExportarNoVerifactuSinColumnasEventos;
end;
function SErrorExportarNoVerifactuSinColumnasFacturacion: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorExportarNoVerifactuSinColumnasFacturacion;
end;
function SErrorExportarNoVerifactuRegistrosSinFirma: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorExportarNoVerifactuRegistrosSinFirma;
end;
function SErrorConexionExportarNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorConexionExportarNoVerifactu;
end;
function SErrorArchivoBaseExportacionNoIndicado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorArchivoBaseExportacionNoIndicado;
end;
function STextoTipoError: string;
begin
  Result :=
    inLibMsgVerifactu.STextoTipoError;
end;
function STextoTipoAviso: string;
begin
  Result :=
    inLibMsgVerifactu.STextoTipoAviso;
end;
function SFormatoDetalleVerificacion: string;
begin
  Result :=
    inLibMsgVerifactu.SFormatoDetalleVerificacion;
end;
function SErrorModoExportacionNoCoincide: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorModoExportacionNoCoincide;
end;
function SErrorXmlFirmadoNoLegible: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorXmlFirmadoNoLegible;
end;
function SErrorFirmaEventoRaizIncorrecta: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaEventoRaizIncorrecta;
end;
function SErrorEventoFirmadoNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoFirmadoNoEncontrado;
end;
function SErrorFirmaFacturaRaizIncorrecta: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFirmaFacturaRaizIncorrecta;
end;
function SErrorFirmaXadesNodoAeatIncorrecto: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaXadesNodoAeatIncorrecto;
end;
function SErrorFirmaXadesSinCertificado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaXadesSinCertificado;
end;
function SErrorFirmaXadesSinSignedInfo: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaXadesSinSignedInfo;
end;
function SErrorCanonicalizacionFirmaAeat: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCanonicalizacionFirmaAeat;
end;
function SErrorMetodoFirmaNoRsaSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorMetodoFirmaNoRsaSha256;
end;
function SErrorReferenciasSignedInfo: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorReferenciasSignedInfo;
end;
function SErrorReferenciaDocumentoFirmado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorReferenciaDocumentoFirmado;
end;
function SErrorTransformacionFirmaEnveloped: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorTransformacionFirmaEnveloped;
end;
function SErrorDigestRegistroNoSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDigestRegistroNoSha256;
end;
function SErrorReferenciaSignedProperties: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorReferenciaSignedProperties;
end;
function SErrorCanonicalizacionSignedProperties: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCanonicalizacionSignedProperties;
end;
function SErrorDigestSignedPropertiesNoSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDigestSignedPropertiesNoSha256;
end;
function SErrorQualifyingPropertiesXades: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorQualifyingPropertiesXades;
end;
function SErrorSignedPropertiesXades: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorSignedPropertiesXades;
end;
function SErrorSigningCertificateXades: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorSigningCertificateXades;
end;
function SErrorPoliticaFirmaAge: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorPoliticaFirmaAge;
end;
function SErrorIdentificadorPoliticaAge: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorIdentificadorPoliticaAge;
end;
function SErrorDigestPoliticaAgeNoSha1: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDigestPoliticaAgeNoSha1;
end;
function SErrorDigestValuePoliticaAge: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDigestValuePoliticaAge;
end;
function SErrorUrlPoliticaAge: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorUrlPoliticaAge;
end;
function SFormatoEtiquetaEvento: string;
begin
  Result :=
    inLibMsgVerifactu.SFormatoEtiquetaEvento;
end;
function SErrorEventoHashPropioNoSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoHashPropioNoSha256;
end;
function SAvisoEventoPrimerHashAnteriorNoCero: string;
begin
  Result :=
    inLibMsgVerifactu.SAvisoEventoPrimerHashAnteriorNoCero;
end;
function SErrorEventoHashAnteriorNoCoincide: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoHashAnteriorNoCoincide;
end;
function SErrorEventoSinRegistroXmlFirmado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoSinRegistroXmlFirmado;
end;
function SErrorEventoHuellaNoCoincide: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoHuellaNoCoincide;
end;
function SErrorEventoFirmaGuardadaSinFirmaXml: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoFirmaGuardadaSinFirmaXml;
end;
function SErrorEventoSinFirmaXades: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoSinFirmaXades;
end;
function SErrorEventoSignatureValueNoCoincide: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoSignatureValueNoCoincide;
end;
function SErrorEventoFirmaDigitalNoCoincide: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEventoFirmaDigitalNoCoincide;
end;
function STextoRegistroFacturaIndice: string;
begin
  Result :=
    inLibMsgFacturas.STextoRegistroFacturaIndice;
end;
function SFormatoEtiquetaFactura: string;
begin
  Result :=
    inLibMsgFacturas.SFormatoEtiquetaFactura;
end;
function SAvisoFacturaSinPeticionCompletaXml: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoFacturaSinPeticionCompletaXml;
end;
function SErrorFacturaHashPeticionNoCoincide: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaHashPeticionNoCoincide;
end;
function SErrorFacturaSinRegistroXmlFirmado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaSinRegistroXmlFirmado;
end;
function SErrorFacturaHashRegistroNoCoincide: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaHashRegistroNoCoincide;
end;
function SErrorFacturaGuardadaSinFirmaXml: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaGuardadaSinFirmaXml;
end;
function SErrorFacturaSinFirmaDigitalXades: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFacturaSinFirmaDigitalXades;
end;
function SErrorFacturaSignatureValueNoCoincide: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaSignatureValueNoCoincide;
end;
function STextoEventos: string;
begin
  Result :=
    inLibMsgVerifactu.STextoEventos;
end;
function STextoFacturacion: string;
begin
  Result :=
    inLibMsgFacturas.STextoFacturacion;
end;
function SErrorFicheroEventosNoExiste: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFicheroEventosNoExiste;
end;
function SErrorFicheroEventosRaizIncorrecta: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFicheroEventosRaizIncorrecta;
end;
function SErrorFicheroEventosVacio: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFicheroEventosVacio;
end;
function SErrorFicheroFacturacionNoExiste: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFicheroFacturacionNoExiste;
end;
function SErrorFicheroFacturacionRaizIncorrecta: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFicheroFacturacionRaizIncorrecta;
end;
function SErrorFicheroFacturacionVacio: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFicheroFacturacionVacio;
end;
function SErrorVerificarEventos: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorVerificarEventos;
end;
function SErrorVerificarFacturacion: string;
begin
  Result :=
    inLibMsgFacturas.SErrorVerificarFacturacion;
end;
function SInfoVerificacionCorrecta: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoVerificacionCorrecta;
end;
function SFormatoModoActual: string;
begin
  Result :=
    inLibMsgVerifactu.SFormatoModoActual;
end;
function SResumenVerificacionNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SResumenVerificacionNoVerifactu;
end;
function SDepuracionComponenteNoTcxLabel: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxLabel;
end;
function SDepuracionComponenteNoTcxTabSheet: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxTabSheet;
end;
function SDepuracionComponenteNoTcxDbCheckBox: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxDbCheckBox;
end;
function SDepuracionComponenteNoTcxButton: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxButton;
end;
function SDepuracionComponenteNoTcxGroupBox: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxGroupBox;
end;
function SDepuracionComponenteNoTcxDbRadioGroup: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxDbRadioGroup;
end;
function SDepuracionComponenteNoSpeedButton: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoSpeedButton;
end;
function SDepuracionComponenteNoTcxRadioButton: string;
begin
  Result :=
    inLibMsgComun.SDepuracionComponenteNoTcxRadioButton;
end;
function SErrorImagenNoExiste: string;
begin
  Result :=
    inLibMsgComun.SErrorImagenNoExiste;
end;
function SErrorAbrirProveedorCriptografico: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorAbrirProveedorCriptografico;
end;
function SErrorCrearHashCriptografico: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCrearHashCriptografico;
end;
function SErrorCalcularHash: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCalcularHash;
end;
function SErrorObtenerTamanoHash: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorObtenerTamanoHash;
end;
function SErrorObtenerValorHash: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorObtenerValorHash;
end;
function SErrorOperacionCriptografica: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorOperacionCriptografica;
end;
function SErrorProveedorCertificadoSinSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorProveedorCertificadoSinSha256;
end;
function STextoCertificadoTodaviaNoValido: string;
begin
  Result :=
    inLibMsgVerifactu.STextoCertificadoTodaviaNoValido;
end;
function STextoCertificadoCaducado: string;
begin
  Result :=
    inLibMsgVerifactu.STextoCertificadoCaducado;
end;
function SErrorCertificadoNoVigente: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCertificadoNoVigente;
end;
function SErrorCertificadoVigenteNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCertificadoVigenteNoEncontrado;
end;
function SErrorCertificadoEmpresaNoConfigurado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCertificadoEmpresaNoConfigurado;
end;
function SErrorCrearHashSha256Firma: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCrearHashSha256Firma;
end;
function SErrorCargarDatosFirma: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCargarDatosFirma;
end;
function SErrorCalcularTamanoFirmaSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCalcularTamanoFirmaSha256;
end;
function SErrorFirmarSha256: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmarSha256;
end;
function SErrorCalcularTamanoFirmaNCrypt: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCalcularTamanoFirmaNCrypt;
end;
function SErrorFirmaNCrypt: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaNCrypt;
end;
function SErrorAbrirClavePrivadaCertificado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorAbrirClavePrivadaCertificado;
end;
function SErrorXmlMalFormadoCanonicalizar: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorXmlMalFormadoCanonicalizar;
end;
function SErrorElementoRaizXmlNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorElementoRaizXmlNoEncontrado;
end;
function SErrorNombreNodoRaizNoDeterminado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNombreNodoRaizNoDeterminado;
end;
function SErrorCierreAperturaRaizNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCierreAperturaRaizNoEncontrado;
end;
function SErrorCierreNodoRaizNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCierreNodoRaizNoEncontrado;
end;
function SErrorCierreNodoNoEncontrado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCierreNodoNoEncontrado;
end;
function SErrorNifProductorEventoVerifactuInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifProductorEventoVerifactuInvalido;
end;
function SErrorEmpresaEventosVerifactuNoConfigurada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEmpresaEventosVerifactuNoConfigurada;
end;
function SErrorNifEmisorEventoNoVerifactuInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifEmisorEventoNoVerifactuInvalido;
end;
function SErrorFacturaRequisitosFiscalesNoExiste: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaRequisitosFiscalesNoExiste;
end;
function SErrorEmpresaSinNifEmisionFiscal: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEmpresaSinNifEmisionFiscal;
end;
function SErrorNifProductorVerifactuInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifProductorVerifactuInvalido;
end;
function SErrorCertificadoFiscalEmpresaNoUtilizable: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCertificadoFiscalEmpresaNoUtilizable;
end;
function SErrorFirmaCertificadoNoVerifactuDesactivada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaCertificadoNoVerifactuDesactivada;
end;
function SErrorCertificadoEventosNoVerifactuNoConfigurado: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorCertificadoEventosNoVerifactuNoConfigurado;
end;
function SErrorFirmarEventoNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmarEventoNoVerifactu;
end;
function SErrorRelojEventoNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRelojEventoNoVerifactu;
end;
function SErrorColumnasFirmaFacturacionNoDisponibles: string;
begin
  Result :=
    inLibMsgFacturas.SErrorColumnasFirmaFacturacionNoDisponibles;
end;
function STextoRegistroFacturacionNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.STextoRegistroFacturacionNoVerifactu;
end;
function SErrorFirmaRegistroNoVerifactuObligatoria: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFirmaRegistroNoVerifactuObligatoria;
end;
function SErrorNifProductorSoftwareVerifactuInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifProductorSoftwareVerifactuInvalido;
end;
function SErrorFacturaExtranjeraSinNifIva: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaExtranjeraSinNifIva;
end;
function SErrorFacturaSinNifClienteValido: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturaSinNifClienteValido;
end;
function SErrorNifEmisorVerifactuInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifEmisorVerifactuInvalido;
end;
function SErrorFacturaRegistroFiscalNoEncontrada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFacturaRegistroFiscalNoEncontrada;
end;
function SAvisoQrPngNoGenerado: string;
begin
  Result :=
    inLibMsgVerifactu.SAvisoQrPngNoGenerado;
end;
function SErrorFacturaEnvioVerifactuNoEncontrada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorFacturaEnvioVerifactuNoEncontrada;
end;
function SErrorRespuestaServicioInesperada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRespuestaServicioInesperada;
end;
function SErrorRespuestaHttpAeat: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRespuestaHttpAeat;
end;
function SErrorRespuestaRegistroAeat: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorRespuestaRegistroAeat;
end;
function SErrorEstadoEnvioAeat: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEstadoEnvioAeat;
end;
function SErrorServicioInstalacionHttp: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorServicioInstalacionHttp;
end;
function SErrorReferenciaGlobalInstalacionFaltante: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorReferenciaGlobalInstalacionFaltante;
end;
function SErrorApiKeyInstalacionFaltante: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorApiKeyInstalacionFaltante;
end;
function SErrorServicioJsonInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorServicioJsonInvalido;
end;
function SErrorServicioSinNumeroInstalacion: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorServicioSinNumeroInstalacion;
end;
function SErrorServicioSinDatosDeclaracion: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorServicioSinDatosDeclaracion;
end;
function SErrorDeclaracionVersionNoSolicitada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDeclaracionVersionNoSolicitada;
end;
function SErrorDeclaracionSifIncorrecto: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDeclaracionSifIncorrecto;
end;
function SErrorDeclaracionDescargadaVacia: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDeclaracionDescargadaVacia;
end;
function SErrorPaginaPublicaHttp: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorPaginaPublicaHttp;
end;
function SErrorDeclaracionWebserviceOtraVersion: string;
begin
  Result :=
    inLibMsgIntegraciones.SErrorDeclaracionWebserviceOtraVersion;
end;
function SErrorDeclaracionPaginaPublicaOtraVersion: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDeclaracionPaginaPublicaOtraVersion;
end;
function SErrorDeclaracionResponsableNoDisponible: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorDeclaracionResponsableNoDisponible;
end;
function SErrorEmpresaInstalacionSifNoConfigurada: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEmpresaInstalacionSifNoConfigurada;
end;
function SErrorEmpresaSinRazonSocial: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEmpresaSinRazonSocial;
end;
function SErrorNifEmpresaInstalacionInvalido: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNifEmpresaInstalacionInvalido;
end;
function SErrorEmpresaSinNumeroInstalacionSif: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorEmpresaSinNumeroInstalacionSif;
end;
function SErrorNumeroInstalacionSifIncorrecto: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNumeroInstalacionSifIncorrecto;
end;
function SErrorNumeroInstalacionSinVersion: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorNumeroInstalacionSinVersion;
end;
function SErrorVersionNumeroInstalacionIncorrecta: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorVersionNumeroInstalacionIncorrecta;
end;
function SInfoExportacionNoVerifactuGenerada: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoExportacionNoVerifactuGenerada;
end;
function SInfoVerificacionNoVerifactuCorrecta: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoVerificacionNoVerifactuCorrecta;
end;
function SErrorVerificacionNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorVerificacionNoVerifactu;
end;
function SPreguntaAbrirSeriesAlbaranVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaAbrirSeriesAlbaranVenta;
end;
function SErrorAlbaranVentaNoAbierto: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlbaranVentaNoAbierto;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta;
end;
function SPreguntaGrabarAlbaranVentaSinSku: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGrabarAlbaranVentaSinSku;
end;
function SErrorAlbaranVentaNoInicializado: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlbaranVentaNoInicializado;
end;
function SErrorCrearSeleccionarAlbaranAntesLineas: string;
begin
  Result :=
    inLibMsgVentas.SErrorCrearSeleccionarAlbaranAntesLineas;
end;
function SPreguntaEliminarLineaAlbaranVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaEliminarLineaAlbaranVenta;
end;
function SErrorAlbaranVentaSinLineas: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlbaranVentaSinLineas;
end;
function SAvisoSeleccionarLineasBorradorAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SAvisoSeleccionarLineasBorradorAlbaran;
end;
function SAvisoLineasAlbaranConBorrador: string;
begin
  Result :=
    inLibMsgVentas.SAvisoLineasAlbaranConBorrador;
end;
function SPreguntaGenerarBorradorLineasAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaGenerarBorradorLineasAlbaran;
end;
function SInfoBorradorFacturaCreado: string;
begin
  Result :=
    inLibMsgFacturas.SInfoBorradorFacturaCreado;
end;
function SErrorCrearBorradorFactura: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCrearBorradorFactura;
end;
function SPreguntaGenerarBorradorTodoAlbaran: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaGenerarBorradorTodoAlbaran;
end;
function SAvisoAlbaranSinPedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SAvisoAlbaranSinPedidoVenta;
end;
function SAvisoAlbaranSinBorrador: string;
begin
  Result :=
    inLibMsgVentas.SAvisoAlbaranSinBorrador;
end;
function SErrorProveedorNoSeleccionadoBuscarArticulos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorProveedorNoSeleccionadoBuscarArticulos;
end;
function SErrorAlbaranCompraNoAbierto: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraNoAbierto;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra;
end;
function SErrorAlbaranCompraNoInicializado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraNoInicializado;
end;
function STextoAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.STextoAlbaranCompra;
end;
function SPreguntaAbrirSeriesAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaAbrirSeriesAlbaranCompra;
end;
function SErrorAlbaranCompraSinImpresionActivo: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraSinImpresionActivo;
end;
function SErrorAlbaranCompraNoActivo: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraNoActivo;
end;
function SPreguntaGrabarAlbaranCompraSinSku: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaGrabarAlbaranCompraSinSku;
end;
function SErrorAlbaranCompraNecesarioElegirEmpresa: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraNecesarioElegirEmpresa;
end;
function SErrorAlbaranCompraNecesarioElegirProveedor: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlbaranCompraNecesarioElegirProveedor;
end;
function SErrorArticuloNoSeleccionadoElegirColor: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoElegirColor;
end;
function SErrorArticuloSinColoresBasicosActivos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSinColoresBasicosActivos;
end;
function SAvisoAlbaranCompraSinPedido: string;
begin
  Result :=
    inLibMsgCompras.SAvisoAlbaranCompraSinPedido;
end;
function SAvisoAlbaranCompraSinFactura: string;
begin
  Result :=
    inLibMsgCompras.SAvisoAlbaranCompraSinFactura;
end;
function SPreguntaEliminarLineaAlbaranCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaEliminarLineaAlbaranCompra;
end;
function SErrorArticuloSinTipoVariacion: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSinTipoVariacion;
end;
function SErrorPrecioTarifaNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorPrecioTarifaNoSeleccionado;
end;
function SErrorPrecioTarifaNoGuardado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorPrecioTarifaNoGuardado;
end;
function SAvisoRevisionArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoRevisionArticulo;
end;
function SErrorGuardarPropiedadesArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarPropiedadesArticulo;
end;
function SErrorGuardarVariacionesArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarVariacionesArticulo;
end;
function SPreguntaReconstruirStock: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaReconstruirStock;
end;
function STituloReconstruirStock: string;
begin
  Result :=
    inLibMsgArticulos.STituloReconstruirStock;
end;
function SErrorReconstruirStock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorReconstruirStock;
end;
function SInfoStockReconstruido: string;
begin
  Result :=
    inLibMsgArticulos.SInfoStockReconstruido;
end;
function SErrorArticuloNoSeleccionadoImprimirEtiquetas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoImprimirEtiquetas;
end;
function SErrorArticuloNoSeleccionadoGenerarCodigos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoGenerarCodigos;
end;
function SErrorArticuloSinSkusActivosGenerarCodigos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloSinSkusActivosGenerarCodigos;
end;
function SPreguntaGenerarCodigosBarras: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGenerarCodigosBarras;
end;
function SInfoGeneracionCodigosBarras: string;
begin
  Result :=
    inLibMsgArticulos.SInfoGeneracionCodigosBarras;
end;
function SErrorArticuloNoSeleccionadoVerificarCodigos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoVerificarCodigos;
end;
function SErrorDetalleCodigoBarrasInvalido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDetalleCodigoBarrasInvalido;
end;
function SInfoVerificacionCodigosBarrasCorrecta: string;
begin
  Result :=
    inLibMsgArticulos.SInfoVerificacionCodigosBarrasCorrecta;
end;
function SAvisoVerificacionCodigosBarras: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoVerificacionCodigosBarras;
end;
function SInfoPrecargaArticuloGuardada: string;
begin
  Result :=
    inLibMsgArticulos.SInfoPrecargaArticuloGuardada;
end;
function STextoAtributoBasicoSinValor: string;
begin
  Result :=
    inLibMsgArticulos.STextoAtributoBasicoSinValor;
end;
function SPreguntaCrearAtributoBasicoSku: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCrearAtributoBasicoSku;
end;
function STituloCrearAtributoBasico: string;
begin
  Result :=
    inLibMsgArticulos.STituloCrearAtributoBasico;
end;
function SErrorSkuColorNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuColorNoSeleccionado;
end;
function STextoActivarSkusColor: string;
begin
  Result :=
    inLibMsgArticulos.STextoActivarSkusColor;
end;
function STextoDesactivarSkusColor: string;
begin
  Result :=
    inLibMsgArticulos.STextoDesactivarSkusColor;
end;
function SPreguntaCambiarActivoSkusColor: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCambiarActivoSkusColor;
end;
function STextoSkusColorActivados: string;
begin
  Result :=
    inLibMsgArticulos.STextoSkusColorActivados;
end;
function STextoSkusColorDesactivados: string;
begin
  Result :=
    inLibMsgArticulos.STextoSkusColorDesactivados;
end;
function SInfoSkusColorActualizados: string;
begin
  Result :=
    inLibMsgArticulos.SInfoSkusColorActualizados;
end;
function SErrorColorPaletaBusquedaInvalido: string;
begin
  Result :=
    inLibMsgComun.SErrorColorPaletaBusquedaInvalido;
end;
function SErrorOperacionSinBorrador: string;
begin
  Result :=
    inLibMsgComun.SErrorOperacionSinBorrador;
end;
function SErrorBorradorNoCerradoFiscalmente: string;
begin
  Result :=
    inLibMsgComun.SErrorBorradorNoCerradoFiscalmente;
end;
function SPreguntaAnularFiscalmenteBorrador: string;
begin
  Result :=
    inLibMsgComun.SPreguntaAnularFiscalmenteBorrador;
end;
function SPreguntaBorrarMovimientosTicketAnulado: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaBorrarMovimientosTicketAnulado;
end;
function SPreguntaMovimientosRectificativaSustitutiva: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaMovimientosRectificativaSustitutiva;
end;
function SInfoAnulacionVerifactuEncolada: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAnulacionVerifactuEncolada;
end;
function SInfoAnulacionNoVerifactuRegistrada: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAnulacionNoVerifactuRegistrada;
end;
function SInfoAnulacionSinVerifactuRegistrada: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAnulacionSinVerifactuRegistrada;
end;
function SErrorFacturarTicketRequiereSimplificado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFacturarTicketRequiereSimplificado;
end;
function SInfoBorradorSustitucionTicketCreado: string;
begin
  Result :=
    inLibMsgFacturas.SInfoBorradorSustitucionTicketCreado;
end;
function SErrorRectificarRectificativa: string;
begin
  Result :=
    inLibMsgFacturas.SErrorRectificarRectificativa;
end;
function SPreguntaRectificarBorrador: string;
begin
  Result :=
    inLibMsgComun.SPreguntaRectificarBorrador;
end;
function SErrorOperacionCorreoNoEncontrada: string;
begin
  Result :=
    inLibMsgComun.SErrorOperacionCorreoNoEncontrada;
end;
function STituloEnviarDocumentacion: string;
begin
  Result :=
    inLibMsgComun.STituloEnviarDocumentacion;
end;
function SSolicitudCorreoElectronico: string;
begin
  Result :=
    inLibMsgComun.SSolicitudCorreoElectronico;
end;
function SErrorCorreoElectronicoObligatorio: string;
begin
  Result :=
    inLibMsgComun.SErrorCorreoElectronicoObligatorio;
end;
function SErrorEnviarCorreoOperacion: string;
begin
  Result :=
    inLibMsgComun.SErrorEnviarCorreoOperacion;
end;
function SErrorOperacionSinTicket: string;
begin
  Result :=
    inLibMsgFacturas.SErrorOperacionSinTicket;
end;
function SPreguntaBorrarPropiedadPlantillaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarPropiedadPlantillaCompra;
end;
function SPreguntaBorrarKitPlantillaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarKitPlantillaCompra;
end;
function SInfoIbanValidado: string;
begin
  Result :=
    inLibMsgVentas.SInfoIbanValidado;
end;
function SErrorCabeceraSesionAntesLineas: string;
begin
  Result :=
    inLibMsgCompras.SErrorCabeceraSesionAntesLineas;
end;
function SErrorSesionSinDocumentosCreados: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionSinDocumentosCreados;
end;
function SErrorMantenimientoTipoDocumentoNoDisponible: string;
begin
  Result :=
    inLibMsgCompras.SErrorMantenimientoTipoDocumentoNoDisponible;
end;
function SPreguntaAbrirSeriesSesionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaAbrirSeriesSesionCompra;
end;
function SErrorLineaSesionDescargarFotosNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaSesionDescargarFotosNoSeleccionada;
end;
function SErrorLineaSesionSinCodigoArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaSesionSinCodigoArticulo;
end;
function SErrorDescargarFotosArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDescargarFotosArticulo;
end;
function SInfoFotosArticuloDescargadas: string;
begin
  Result :=
    inLibMsgArticulos.SInfoFotosArticuloDescargadas;
end;
function SErrorSesionElegirProveedorNoSeleccionada: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionElegirProveedorNoSeleccionada;
end;
function SErrorProveedorSesionSinKits: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorSesionSinKits;
end;
function SErrorKitProveedorDesplegableNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorKitProveedorDesplegableNoSeleccionado;
end;
function SPreguntaBorrarLineaSesionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarLineaSesionCompra;
end;
function SErrorLineaSesionAsignarFotoNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaSesionAsignarFotoNoSeleccionada;
end;
function SInfoFotoLineaSesionAsignada: string;
begin
  Result :=
    inLibMsgArticulos.SInfoFotoLineaSesionAsignada;
end;
function SErrorAsignarFotoSesion: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAsignarFotoSesion;
end;
function SErrorGuardarFotoSesion: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarFotoSesion;
end;
function SErrorSesionYaMaterializada: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionYaMaterializada;
end;
function SInfoDuplicadosSesionMarcadosReusar: string;
begin
  Result :=
    inLibMsgCompras.SInfoDuplicadosSesionMarcadosReusar;
end;
function SInfoSesionMaterializadaSinDocumentos: string;
begin
  Result :=
    inLibMsgCompras.SInfoSesionMaterializadaSinDocumentos;
end;
function SErrorSesionNoCerradaParaReversion: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionNoCerradaParaReversion;
end;
function SPreguntaRevertirSesionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaRevertirSesionCompra;
end;
function SInfoSesionRevertida: string;
begin
  Result :=
    inLibMsgCompras.SInfoSesionRevertida;
end;
function SErrorRevertirSesionCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorRevertirSesionCompra;
end;
function SErrorSesionActivaImprimirNoDisponible: string;
begin
  Result :=
    inLibMsgCompras.SErrorSesionActivaImprimirNoDisponible;
end;
function SErrorSistemasTallasSesionNoDisponibles: string;
begin
  Result :=
    inLibMsgCompras.SErrorSistemasTallasSesionNoDisponibles;
end;
function SErrorCambiarSistemaTallasModeloExistente: string;
begin
  Result :=
    inLibMsgCompras.SErrorCambiarSistemaTallasModeloExistente;
end;
function SErrorLineaSesionAsignarFamiliaNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaSesionAsignarFamiliaNoSeleccionada;
end;
function SErrorColoresBasicosSesionNoDisponibles: string;
begin
  Result :=
    inLibMsgCompras.SErrorColoresBasicosSesionNoDisponibles;
end;
function SInfoEfectoConciliado: string;
begin
  Result :=
    inLibMsgComun.SInfoEfectoConciliado;
end;
function SErrorConciliarEfecto: string;
begin
  Result :=
    inLibMsgComun.SErrorConciliarEfecto;
end;
function SErrorEfectoNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorEfectoNoSeleccionado;
end;
function SErrorCarteraEfectosNoAbierta: string;
begin
  Result :=
    inLibMsgComun.SErrorCarteraEfectosNoAbierta;
end;
function SErrorEfectosCompraFusionInsuficientes: string;
begin
  Result :=
    inLibMsgCompras.SErrorEfectosCompraFusionInsuficientes;
end;
function SErrorEfectosVentaFusionInsuficientes: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectosVentaFusionInsuficientes;
end;
function SPreguntaFusionarEfectos: string;
begin
  Result :=
    inLibMsgComun.SPreguntaFusionarEfectos;
end;
function SInfoEfectosConciliados: string;
begin
  Result :=
    inLibMsgComun.SInfoEfectosConciliados;
end;
function SErrorFusionarEfectos: string;
begin
  Result :=
    inLibMsgComun.SErrorFusionarEfectos;
end;
function SErrorContadorSerieEmpresa: string;
begin
  Result :=
    inLibMsgComun.SErrorContadorSerieEmpresa;
end;
function SErrorEmpresaCrearSeriesNoSeleccionada: string;
begin
  Result :=
    inLibMsgComun.SErrorEmpresaCrearSeriesNoSeleccionada;
end;
function SInfoSeriesEmpresaCreadas: string;
begin
  Result :=
    inLibMsgComun.SInfoSeriesEmpresaCreadas;
end;
function SErrorEmpresaNoSeleccionada: string;
begin
  Result :=
    inLibMsgComun.SErrorEmpresaNoSeleccionada;
end;
function SInfoInstalacionSifEmpresaDisponible: string;
begin
  Result :=
    inLibMsgComun.SInfoInstalacionSifEmpresaDisponible;
end;
function SErrorDocumentoTrabajoNoSeleccionadoListado: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoNoSeleccionadoListado;
end;
function SErrorDocumentoTrabajoSinGrabarListado: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinGrabarListado;
end;
function SErrorDocumentoTrabajoSinLineasListado: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinLineasListado;
end;
function SErrorDocumentoTrabajoNoSeleccionadoCargar: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoNoSeleccionadoCargar;
end;
function SErrorCargarDocumentoTrabajoNoPropietario: string;
begin
  Result :=
    inLibMsgVentas.SErrorCargarDocumentoTrabajoNoPropietario;
end;
function SErrorDocumentoTrabajoSinGrabarCargar: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinGrabarCargar;
end;
function SErrorDocumentoTrabajoNoSeleccionadoCompartir: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoNoSeleccionadoCompartir;
end;
function SInfoDocumentoTrabajoCompartido: string;
begin
  Result :=
    inLibMsgVentas.SInfoDocumentoTrabajoCompartido;
end;
function SInfoDocumentoTrabajoYaCompartido: string;
begin
  Result :=
    inLibMsgVentas.SInfoDocumentoTrabajoYaCompartido;
end;
function SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas;
end;
function SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas;
end;
function SErrorDocumentoTrabajoNoSeleccionadoEnviar: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoNoSeleccionadoEnviar;
end;
function SErrorDocumentoTrabajoSinGrabarEnviar: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinGrabarEnviar;
end;
function SErrorDocumentoTrabajoSinLineasEnviar: string;
begin
  Result :=
    inLibMsgVentas.SErrorDocumentoTrabajoSinLineasEnviar;
end;
function SErrorContadorAlbaranDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SErrorContadorAlbaranDocumentoTrabajo;
end;
function SInfoAlbaranDocumentoTrabajoCreado: string;
begin
  Result :=
    inLibMsgVentas.SInfoAlbaranDocumentoTrabajoCreado;
end;
function SErrorVentaTpvNoAbiertaDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgVentas.SErrorVentaTpvNoAbiertaDocumentoTrabajo;
end;
function SInfoLineasDocumentoTrabajoVolcadasTpv: string;
begin
  Result :=
    inLibMsgVentas.SInfoLineasDocumentoTrabajoVolcadasTpv;
end;
function SAvisoLineasDocumentoTrabajoNoVolcadasTpv: string;
begin
  Result :=
    inLibMsgVentas.SAvisoLineasDocumentoTrabajoNoVolcadasTpv;
end;
function SErrorContadorInventarioDocumentoTrabajo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorContadorInventarioDocumentoTrabajo;
end;
function SInfoInventarioDocumentoTrabajoCreado: string;
begin
  Result :=
    inLibMsgArticulos.SInfoInventarioDocumentoTrabajoCreado;
end;
function SInfoCambioTarifasDocumentoTrabajoCreado: string;
begin
  Result :=
    inLibMsgArticulos.SInfoCambioTarifasDocumentoTrabajoCreado;
end;
function SPreguntaAbrirSeriesDevolucionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaAbrirSeriesDevolucionCompra;
end;
function SErrorLineaColorDevolucionNoEncontrada: string;
begin
  Result :=
    inLibMsgCompras.SErrorLineaColorDevolucionNoEncontrada;
end;
function SErrorDevolucionCompraSinImpresionActiva: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraSinImpresionActiva;
end;
function SErrorDevolucionCompraNoActiva: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraNoActiva;
end;
function SErrorProveedorDevolucionFilaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorDevolucionFilaNoSeleccionado;
end;
function SErrorAlmacenDevolucionFilaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenDevolucionFilaNoSeleccionado;
end;
function SErrorFilaDevolucionStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFilaDevolucionStockNoSeleccionada;
end;
function SErrorArticuloDevolucionFilaNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloDevolucionFilaNoSeleccionado;
end;
function SErrorColorDevolucionFilaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorColorDevolucionFilaNoSeleccionado;
end;
function SErrorStockDevolucionFilaNoDisponible: string;
begin
  Result :=
    inLibMsgArticulos.SErrorStockDevolucionFilaNoDisponible;
end;
function SPreguntaPrepararStockFilaDevolucion: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaPrepararStockFilaDevolucion;
end;
function SInfoStockFilaDevolucionPreparado: string;
begin
  Result :=
    inLibMsgArticulos.SInfoStockFilaDevolucionPreparado;
end;
function SPreguntaGrabarDevolucionCompraSinSku: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaGrabarDevolucionCompraSinSku;
end;
function SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion: string;
begin
  Result :=
    inLibMsgArticulos.SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion;
end;
function SErrorDevolucionCompraNoAbierta: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraNoAbierta;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusDevolucion: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoBuscarSkusDevolucion;
end;
function SErrorDevolucionCompraElegirEmpresaNoSeleccionada: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraElegirEmpresaNoSeleccionada;
end;
function SErrorDevolucionCompraElegirProveedorNoSeleccionada: string;
begin
  Result :=
    inLibMsgCompras.SErrorDevolucionCompraElegirProveedorNoSeleccionada;
end;
function SPreguntaEliminarLineaDevolucionCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaEliminarLineaDevolucionCompra;
end;
function SErrorFotoArticuloNoActivoDescargar: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoArticuloNoActivoDescargar;
end;
function SErrorFotoArticuloNoActivo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoArticuloNoActivo;
end;
function SErrorGuardarFotoArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarFotoArticulo;
end;
function SErrorFotoSkuNoActivo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFotoSkuNoActivo;
end;
function SErrorNivelAtributosFotoNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorNivelAtributosFotoNoSeleccionado;
end;
function SPreguntaEliminarFotoActual: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEliminarFotoActual;
end;
function SAvisoLimiteRegistrosFacturaSimplificada: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoLimiteRegistrosFacturaSimplificada;
end;
function SErrorBorradorVentaMayorNoSeleccionado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorVentaMayorNoSeleccionado;
end;
function SErrorGuardarAntesEmitirEdoc: string;
begin
  Result :=
    inLibMsgFacturas.SErrorGuardarAntesEmitirEdoc;
end;
function SErrorPersonaFisicaEdocSinDatos: string;
begin
  Result :=
    inLibMsgFacturas.SErrorPersonaFisicaEdocSinDatos;
end;
function SInfoEdocEmitido: string;
begin
  Result :=
    inLibMsgFacturas.SInfoEdocEmitido;
end;
function SPreguntaAbrirSeriesFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaAbrirSeriesFacturaCompra;
end;
function SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra;
end;
function SErrorFacturaCompraNoAbierta: string;
begin
  Result :=
    inLibMsgCompras.SErrorFacturaCompraNoAbierta;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra;
end;
function SErrorFacturaCompraSinImpresionActiva: string;
begin
  Result :=
    inLibMsgCompras.SErrorFacturaCompraSinImpresionActiva;
end;
function SAvisoEtiquetasBorradorCompraPendientes: string;
begin
  Result :=
    inLibMsgCompras.SAvisoEtiquetasBorradorCompraPendientes;
end;
function SPreguntaGrabarFacturaCompraSinSku: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaGrabarFacturaCompraSinSku;
end;
function SErrorFacturaCompraNoInicializada: string;
begin
  Result :=
    inLibMsgCompras.SErrorFacturaCompraNoInicializada;
end;
function SErrorFacturaCompraElegirProveedorNoSeleccionada: string;
begin
  Result :=
    inLibMsgCompras.SErrorFacturaCompraElegirProveedorNoSeleccionada;
end;
function SInfoGeneracionEfectosPagoCancelada: string;
begin
  Result :=
    inLibMsgCompras.SInfoGeneracionEfectosPagoCancelada;
end;
function SInfoEfectosPagoGenerados: string;
begin
  Result :=
    inLibMsgCompras.SInfoEfectosPagoGenerados;
end;
function SAvisoEfectosPagoNoGenerados: string;
begin
  Result :=
    inLibMsgCompras.SAvisoEfectosPagoNoGenerados;
end;
function SErrorGenerarEfectosPagoSinBorrador: string;
begin
  Result :=
    inLibMsgCompras.SErrorGenerarEfectosPagoSinBorrador;
end;
function SErrorEfectoCompraNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorEfectoCompraNoSeleccionado;
end;
function SPreguntaEliminarLineaFacturaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaEliminarLineaFacturaCompra;
end;
function SInfoImpresionEfectosCobroEnRemesas: string;
begin
  Result :=
    inLibMsgVentas.SInfoImpresionEfectosCobroEnRemesas;
end;
function SPreguntaReemplazarCobros: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaReemplazarCobros;
end;
function STituloMensajeAdvertencia: string;
begin
  Result :=
    inLibMsgFacturas.STituloMensajeAdvertencia;
end;
function SInfoGeneracionCobrosCancelada: string;
begin
  Result :=
    inLibMsgFacturas.SInfoGeneracionCobrosCancelada;
end;
function SInfoEfectosCobroGenerados: string;
begin
  Result :=
    inLibMsgFacturas.SInfoEfectosCobroGenerados;
end;
function SAvisoEfectosCobroNoGenerados: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoEfectosCobroNoGenerados;
end;
function SErrorGenerarEfectosCobroSinBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SErrorGenerarEfectosCobroSinBorrador;
end;
function SAvisoBorradorPendienteImpresionFiscal: string;
begin
  Result :=
    inLibMsgFacturas.SAvisoBorradorPendienteImpresionFiscal;
end;
function SErrorGuardarFacturaAntesImprimir: string;
begin
  Result :=
    inLibMsgFacturas.SErrorGuardarFacturaAntesImprimir;
end;
function SInfoEfectoMarcadoDevuelto: string;
begin
  Result :=
    inLibMsgFacturas.SInfoEfectoMarcadoDevuelto;
end;
function SErrorMarcarEfectoDevuelto: string;
begin
  Result :=
    inLibMsgFacturas.SErrorMarcarEfectoDevuelto;
end;
function SInfoEfectoMarcadoPendiente: string;
begin
  Result :=
    inLibMsgFacturas.SInfoEfectoMarcadoPendiente;
end;
function SErrorMarcarEfectoPendiente: string;
begin
  Result :=
    inLibMsgFacturas.SErrorMarcarEfectoPendiente;
end;
function SErrorEfectoSinImportePendiente: string;
begin
  Result :=
    inLibMsgFacturas.SErrorEfectoSinImportePendiente;
end;
function SErrorTarifaSeleccionadaNoEncontrada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaSeleccionadaNoEncontrada;
end;
function SErrorBorradorListaNoSeleccionado: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorListaNoSeleccionado;
end;
function SErrorBorradorNoCerradoAccionFiscal: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorNoCerradoAccionFiscal;
end;
function SPreguntaAccionFiscalBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaAccionFiscalBorrador;
end;
function SInfoAccionFiscalEncolada: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAccionFiscalEncolada;
end;
function SInfoAccionFiscalNoVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAccionFiscalNoVerifactu;
end;
function SInfoAccionFiscalSinVerifactu: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoAccionFiscalSinVerifactu;
end;
function SErrorBorradorYaLanzadoFiscalmente: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorYaLanzadoFiscalmente;
end;
function SErrorBorradorSinLineasLanzar: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorSinLineasLanzar;
end;
function SErrorBorradorNormalSinNif: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorNormalSinNif;
end;
function SPreguntaLanzarBorradorFiscal: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaLanzarBorradorFiscal;
end;
function SInfoBorradorVerifactuPendiente: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoBorradorVerifactuPendiente;
end;
function SInfoBorradorNoVerifactuRegistrado: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoBorradorNoVerifactuRegistrado;
end;
function SInfoBorradorSinVerifactuEmitido: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoBorradorSinVerifactuEmitido;
end;
function SErrorBorradorConsolidadoNoReabrible: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorConsolidadoNoReabrible;
end;
function SInfoBorradorYaEnBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SInfoBorradorYaEnBorrador;
end;
function SPreguntaDevolverBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaDevolverBorrador;
end;
function SErrorAltaAeatAceptadaNoReabrible: string;
begin
  Result :=
    inLibMsgFacturas.SErrorAltaAeatAceptadaNoReabrible;
end;
function SErrorBorradorEnProcesoNoReabrible: string;
begin
  Result :=
    inLibMsgFacturas.SErrorBorradorEnProcesoNoReabrible;
end;
function SInfoBorradorReabierto: string;
begin
  Result :=
    inLibMsgFacturas.SInfoBorradorReabierto;
end;
function SPreguntaGrabarFacturaVentaSinSku: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaGrabarFacturaVentaSinSku;
end;
function SErrorCompletarDatosBorrador: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCompletarDatosBorrador;
end;
function SErrorContadorAutomaticoBusqueda: string;
begin
  Result :=
    inLibMsgComun.SErrorContadorAutomaticoBusqueda;
end;
function SInfoRegistroBusquedaCreado: string;
begin
  Result :=
    inLibMsgComun.SInfoRegistroBusquedaCreado;
end;
function SErrorInsertarRegistroBusqueda: string;
begin
  Result :=
    inLibMsgComun.SErrorInsertarRegistroBusqueda;
end;
function SInfoTextoNoEncontrado: string;
begin
  Result :=
    inLibMsgComun.SInfoTextoNoEncontrado;
end;
function STituloBusquedaGlobal: string;
begin
  Result :=
    inLibMsgComun.STituloBusquedaGlobal;
end;
function SSolicitudTextoBusquedaGlobal: string;
begin
  Result :=
    inLibMsgComun.SSolicitudTextoBusquedaGlobal;
end;
function SInfoProcesosBusquedaNoEncontrados: string;
begin
  Result :=
    inLibMsgComun.SInfoProcesosBusquedaNoEncontrados;
end;
function SPreguntaIgnorarErrorScript: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaIgnorarErrorScript;
end;
function SErrorMetadatoSinScript: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorMetadatoSinScript;
end;
function SErrorDatosCopiarNoDisponibles: string;
begin
  Result :=
    inLibMsgComun.SErrorDatosCopiarNoDisponibles;
end;
function SPreguntaCopiarFilasPortapapeles: string;
begin
  Result :=
    inLibMsgComun.SPreguntaCopiarFilasPortapapeles;
end;
function SPreguntaIgnorarErrorComandoScript: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaIgnorarErrorComandoScript;
end;
function SErrorEjecucionProceso: string;
begin
  Result :=
    inLibMsgComun.SErrorEjecucionProceso;
end;
function SErrorComandoSqlProceso: string;
begin
  Result :=
    inLibMsgComun.SErrorComandoSqlProceso;
end;
function SErrorConexionTrabajoNoDisponible: string;
begin
  Result :=
    inLibMsgComun.SErrorConexionTrabajoNoDisponible;
end;
function SInfoDatosGuardados: string;
begin
  Result :=
    inLibMsgComun.SInfoDatosGuardados;
end;
function SErrorGrabarDatos: string;
begin
  Result :=
    inLibMsgComun.SErrorGrabarDatos;
end;
function SPreguntaGrabarCambiosPendientes: string;
begin
  Result :=
    inLibMsgComun.SPreguntaGrabarCambiosPendientes;
end;
function STituloMensajeAdvertenciaGen: string;
begin
  Result :=
    inLibMsgComun.STituloMensajeAdvertenciaGen;
end;
function SInfoCambiosGrabados: string;
begin
  Result :=
    inLibMsgComun.SInfoCambiosGrabados;
end;
function SInfoCambiosCancelados: string;
begin
  Result :=
    inLibMsgComun.SInfoCambiosCancelados;
end;
function SErrorConexionPrincipalNoDisponible: string;
begin
  Result :=
    inLibMsgComun.SErrorConexionPrincipalNoDisponible;
end;
function SErrorPermisoInsertarRegistro: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPermisoInsertarRegistro;
end;
function SErrorPermisoModificarRegistro: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPermisoModificarRegistro;
end;
function SErrorPermisoGuardarRegistro: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPermisoGuardarRegistro;
end;
function SErrorPermisoBorrarRegistro: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPermisoBorrarRegistro;
end;
function SPreguntaEliminarRegistro: string;
begin
  Result :=
    inLibMsgComun.SPreguntaEliminarRegistro;
end;
function STituloConfirmarEliminacion: string;
begin
  Result :=
    inLibMsgComun.STituloConfirmarEliminacion;
end;
function SPreguntaEliminarRegistroConHijos: string;
begin
  Result :=
    inLibMsgComun.SPreguntaEliminarRegistroConHijos;
end;
function SAvisoDesactivarRegistroConHijos: string;
begin
  Result :=
    inLibMsgComun.SAvisoDesactivarRegistroConHijos;
end;
function SAvisoDesactivarRegistroSinHijos: string;
begin
  Result :=
    inLibMsgComun.SAvisoDesactivarRegistroSinHijos;
end;
function SDescripcionHijosGenerica: string;
begin
  Result :=
    inLibMsgComun.SDescripcionHijosGenerica;
end;
function STextoOpcionesBorradoRegistro: string;
begin
  Result :=
    inLibMsgComun.STextoOpcionesBorradoRegistro;
end;
function SErrorFiltroSinCondiciones: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroSinCondiciones;
end;
function SErrorFiltroActualVacio: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroActualVacio;
end;
function SPreguntaSobrescribirFiltro: string;
begin
  Result :=
    inLibMsgComun.SPreguntaSobrescribirFiltro;
end;
function STituloSobrescribirFiltro: string;
begin
  Result :=
    inLibMsgComun.STituloSobrescribirFiltro;
end;
function SInfoFiltroSobrescrito: string;
begin
  Result :=
    inLibMsgComun.SInfoFiltroSobrescrito;
end;
function SInfoFiltroGuardado: string;
begin
  Result :=
    inLibMsgComun.SInfoFiltroGuardado;
end;
function SErrorArticuloInventarioNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloInventarioNoExiste;
end;
function SErrorLineasInventarioNoAbiertas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineasInventarioNoAbiertas;
end;
function SErrorLineaInventarioNoEditable: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaInventarioNoEditable;
end;
function SErrorArticuloInventarioNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloInventarioNoEncontrado;
end;
function SErrorArticuloInventarioTipoSinStock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloInventarioTipoSinStock;
end;
function SErrorArticuloInventarioAtributosSinSku: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloInventarioAtributosSinSku;
end;
function SInfoLineasCsvInventarioLeidas: string;
begin
  Result :=
    inLibMsgArticulos.SInfoLineasCsvInventarioLeidas;
end;
function SErrorMigracionRecuentoInventariosNoAplicada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorMigracionRecuentoInventariosNoAplicada;
end;
function SErrorGrabarCabeceraInventarioAutomaticamente: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGrabarCabeceraInventarioAutomaticamente;
end;
function SErrorGrabarCabeceraInventarioAutomaticamenteDetalle: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGrabarCabeceraInventarioAutomaticamenteDetalle;
end;
function SErrorInventarioNoAbiertoEditar: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNoAbiertoEditar;
end;
function SPreguntaRecalcularInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaRecalcularInventario;
end;
function SInfoRecalculoInventario: string;
begin
  Result :=
    inLibMsgArticulos.SInfoRecalculoInventario;
end;
function SPreguntaAplicarInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaAplicarInventario;
end;
function SErrorAplicarInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAplicarInventario;
end;
function SErrorAplicacionInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAplicacionInventario;
end;
function SErrorRefrescarInventarioAplicado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorRefrescarInventarioAplicado;
end;
function SInfoInventarioAplicado: string;
begin
  Result :=
    inLibMsgArticulos.SInfoInventarioAplicado;
end;
function SErrorInventarioNoSeleccionadoAnadirLineas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNoSeleccionadoAnadirLineas;
end;
function SErrorAnadirLineasInventarioEstado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAnadirLineasInventarioEstado;
end;
function SErrorLineaInventarioNoSeleccionadaParaSkus: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaInventarioNoSeleccionadaParaSkus;
end;
function SErrorLineaInventarioSinArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorLineaInventarioSinArticulo;
end;
function SErrorAnadirSkusInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAnadirSkusInventario;
end;
function SInfoSinSkusAnadidosInventario: string;
begin
  Result :=
    inLibMsgArticulos.SInfoSinSkusAnadidosInventario;
end;
function SInfoSkusAnadidosInventario: string;
begin
  Result :=
    inLibMsgArticulos.SInfoSkusAnadidosInventario;
end;
function SPreguntaEliminarLineaInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEliminarLineaInventario;
end;
function SErrorEliminarRegularizacionInventarioEstado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEliminarRegularizacionInventarioEstado;
end;
function SPreguntaEliminarRegularizacionInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEliminarRegularizacionInventario;
end;
function SInfoRegularizacionInventarioEliminada: string;
begin
  Result :=
    inLibMsgArticulos.SInfoRegularizacionInventarioEliminada;
end;
function SErrorInventarioNoActivo: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNoActivo;
end;
function SErrorInventarioDebeEstarAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioDebeEstarAbierto;
end;
function SErrorFamiliaInventarioNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFamiliaInventarioNoSeleccionada;
end;
function SPreguntaCargarFamiliaInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCargarFamiliaInventario;
end;
function SErrorProveedorInventarioNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorProveedorInventarioNoSeleccionado;
end;
function SPreguntaCargarProveedorInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCargarProveedorInventario;
end;
function SPreguntaCompletarInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCompletarInventario;
end;
function SPreguntaCargarTodoInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCargarTodoInventario;
end;
function SErrorInventarioNoSeleccionado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNoSeleccionado;
end;
function SPreguntaGuardarInventarioEnEdicion: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGuardarInventarioEnEdicion;
end;
function SPreguntaRecalcularTrasCargarBloqueInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaRecalcularTrasCargarBloqueInventario;
end;
function SErrorArchivoImportacionInventarioNoExiste: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArchivoImportacionInventarioNoExiste;
end;
function SErrorImportacionInventarioSinDatos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorImportacionInventarioSinDatos;
end;
function SInfoImportacionInventario: string;
begin
  Result :=
    inLibMsgArticulos.SInfoImportacionInventario;
end;
function SErrorEnviarRecuentoInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEnviarRecuentoInventarioNoAbierto;
end;
function SPreguntaEnviarRecuentoInventario: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaEnviarRecuentoInventario;
end;
function SInfoInventarioEnviadoRecuento: string;
begin
  Result :=
    inLibMsgArticulos.SInfoInventarioEnviadoRecuento;
end;
function SErrorEnviarRecuentoInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEnviarRecuentoInventario;
end;
function SErrorInventarioNoEnviadoRecuento: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInventarioNoEnviadoRecuento;
end;
function SErrorRecogerRecuentoInventarioNoAbierto: string;
begin
  Result :=
    inLibMsgArticulos.SErrorRecogerRecuentoInventarioNoAbierto;
end;
function SInfoRecuentoInventarioRecogido: string;
begin
  Result :=
    inLibMsgArticulos.SInfoRecuentoInventarioRecogido;
end;
function SErrorRecogerRecuentoInventario: string;
begin
  Result :=
    inLibMsgArticulos.SErrorRecogerRecuentoInventario;
end;
function SAvisoLimiteRegistrosMovimientosAlmacen: string;
begin
  Result :=
    inLibMsgArticulos.SAvisoLimiteRegistrosMovimientosAlmacen;
end;
function SPreguntaAbrirSeriesPedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaAbrirSeriesPedidoVenta;
end;
function SErrorPedidoVentaNoAbierto: string;
begin
  Result :=
    inLibMsgVentas.SErrorPedidoVentaNoAbierto;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta;
end;
function SPreguntaGrabarPedidoVentaSinSku: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGrabarPedidoVentaSinSku;
end;
function SErrorClienteNoSeleccionadoPedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorClienteNoSeleccionadoPedidoVenta;
end;
function SErrorClientePedidoVentaNoExiste: string;
begin
  Result :=
    inLibMsgVentas.SErrorClientePedidoVentaNoExiste;
end;
function SErrorPedidoVentaNoInicializado: string;
begin
  Result :=
    inLibMsgVentas.SErrorPedidoVentaNoInicializado;
end;
function SErrorCrearSeleccionarPedidoAntesLineas: string;
begin
  Result :=
    inLibMsgVentas.SErrorCrearSeleccionarPedidoAntesLineas;
end;
function SPreguntaEliminarLineaPedidoVentaConTallas: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaEliminarLineaPedidoVentaConTallas;
end;
function SPreguntaEliminarLineaPedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaEliminarLineaPedidoVenta;
end;
function SPreguntaMarcarLineasPendientesAlbaranar: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaMarcarLineasPendientesAlbaranar;
end;
function SErrorPedidoVentaSinLineas: string;
begin
  Result :=
    inLibMsgVentas.SErrorPedidoVentaSinLineas;
end;
function SPreguntaCrearAlbaranPedidoVentaSinSku: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCrearAlbaranPedidoVentaSinSku;
end;
function SErrorPedidoVentaSinCantidadAlbaranar: string;
begin
  Result :=
    inLibMsgVentas.SErrorPedidoVentaSinCantidadAlbaranar;
end;
function SErrorAnadirAlbaranDesdePedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorAnadirAlbaranDesdePedidoVenta;
end;
function SErrorCrearAlbaranDesdePedidoVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorCrearAlbaranDesdePedidoVenta;
end;
function SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra;
end;
function SErrorPedidoCompraNoAbierto: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNoAbierto;
end;
function SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra;
end;
function SErrorPedidoCompraNoInicializado: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNoInicializado;
end;
function STextoPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.STextoPedidoCompra;
end;
function SErrorExpandirRecibidosNoActivo: string;
begin
  Result :=
    inLibMsgCompras.SErrorExpandirRecibidosNoActivo;
end;
function SInfoTallasPendientesRecibirNoDisponibles: string;
begin
  Result :=
    inLibMsgCompras.SInfoTallasPendientesRecibirNoDisponibles;
end;
function SInfoPedidoCompraSinPendientesRecibir: string;
begin
  Result :=
    inLibMsgCompras.SInfoPedidoCompraSinPendientesRecibir;
end;
function SPreguntaGrabarPedidoCompraSinSku: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaGrabarPedidoCompraSinSku;
end;
function SErrorPedidoCompraNecesarioElegirEmpresa: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNecesarioElegirEmpresa;
end;
function SErrorPedidoCompraNecesarioElegirProveedor: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNecesarioElegirProveedor;
end;
function SErrorTallasHorizontalesNecesariasElegirColor: string;
begin
  Result :=
    inLibMsgCompras.SErrorTallasHorizontalesNecesariasElegirColor;
end;
function SErrorArticuloNoSeleccionadoElegirColorPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloNoSeleccionadoElegirColorPedidoCompra;
end;
function SErrorArticuloPedidoCompraSinColoresBasicos: string;
begin
  Result :=
    inLibMsgCompras.SErrorArticuloPedidoCompraSinColoresBasicos;
end;
function SPreguntaEliminarLineaPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaEliminarLineaPedidoCompra;
end;
function SPreguntaAbrirSeriesPedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaAbrirSeriesPedidoCompra;
end;
function SErrorPedidoCompraNoActivo: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNoActivo;
end;
function SErrorPedidoCompraNoActivoCrearAlbaran: string;
begin
  Result :=
    inLibMsgCompras.SErrorPedidoCompraNoActivoCrearAlbaran;
end;
function SErrorCrearAlbaranDesdePedidoCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorCrearAlbaranDesdePedidoCompra;
end;
function SErrorNodoPermisosNoSeleccionado: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorNodoPermisosNoSeleccionado;
end;
function SErrorOrigenDestinoPermisosNoSeleccionados: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorOrigenDestinoPermisosNoSeleccionados;
end;
function SErrorOrigenDestinoPermisosIguales: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorOrigenDestinoPermisosIguales;
end;
function SInfoModoReemplazarPermisos: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoModoReemplazarPermisos;
end;
function SInfoModoCombinarPermisos: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoModoCombinarPermisos;
end;
function SInfoAlcancePermisosMenu: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoAlcancePermisosMenu;
end;
function SInfoAlcanceTodosPermisos: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoAlcanceTodosPermisos;
end;
function SPreguntaCopiarPermisos: string;
begin
  Result :=
    inLibMsgConfiguracion.SPreguntaCopiarPermisos;
end;
function SInfoPermisosCopiados: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoPermisosCopiados;
end;
function SPreguntaBorrarKitProveedor: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaBorrarKitProveedor;
end;
function SErrorRemesaCompraNoSeleccionada: string;
begin
  Result :=
    inLibMsgCompras.SErrorRemesaCompraNoSeleccionada;
end;
function SErrorEliminarRemesaCompraConCargo: string;
begin
  Result :=
    inLibMsgCompras.SErrorEliminarRemesaCompraConCargo;
end;
function SPreguntaEliminarRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaEliminarRemesaCompra;
end;
function SInfoRemesaCompraEliminada: string;
begin
  Result :=
    inLibMsgCompras.SInfoRemesaCompraEliminada;
end;
function SErrorEliminarRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorEliminarRemesaCompra;
end;
function SErrorAnadirEfectosRemesaCompraConCargo: string;
begin
  Result :=
    inLibMsgCompras.SErrorAnadirEfectosRemesaCompraConCargo;
end;
function SErrorEfectosRemesaCompraNoCargados: string;
begin
  Result :=
    inLibMsgCompras.SErrorEfectosRemesaCompraNoCargados;
end;
function SErrorEfectoRemesaCompraNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorEfectoRemesaCompraNoSeleccionado;
end;
function SErrorQuitarEfectosRemesaCompraConCargo: string;
begin
  Result :=
    inLibMsgCompras.SErrorQuitarEfectosRemesaCompraConCargo;
end;
function SPreguntaQuitarEfectoRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SPreguntaQuitarEfectoRemesaCompra;
end;
function SInfoEfectoRemesaCompraQuitado: string;
begin
  Result :=
    inLibMsgCompras.SInfoEfectoRemesaCompraQuitado;
end;
function SErrorQuitarEfectoRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorQuitarEfectoRemesaCompra;
end;
function SErrorBancoPagoRemesaNoAsignado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBancoPagoRemesaNoAsignado;
end;
function SErrorEfectoRemesaCompraSinPendiente: string;
begin
  Result :=
    inLibMsgCompras.SErrorEfectoRemesaCompraSinPendiente;
end;
function STextoEfectoPendienteRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.STextoEfectoPendienteRemesaCompra;
end;
function SInfoEfectoRemesaCompraConciliado: string;
begin
  Result :=
    inLibMsgCompras.SInfoEfectoRemesaCompraConciliado;
end;
function SErrorConciliarEfectoRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorConciliarEfectoRemesaCompra;
end;
function SErrorRemesaCompraSinImportePendiente: string;
begin
  Result :=
    inLibMsgCompras.SErrorRemesaCompraSinImportePendiente;
end;
function STextoRemesaCompraPendiente: string;
begin
  Result :=
    inLibMsgCompras.STextoRemesaCompraPendiente;
end;
function SInfoEfectosRemesaCompraConciliados: string;
begin
  Result :=
    inLibMsgCompras.SInfoEfectosRemesaCompraConciliados;
end;
function SErrorConciliarRemesaCompra: string;
begin
  Result :=
    inLibMsgCompras.SErrorConciliarRemesaCompra;
end;
function SErrorBancoPagoNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorBancoPagoNoSeleccionado;
end;
function SInfoBancoPagoRemesaAsignado: string;
begin
  Result :=
    inLibMsgVentas.SInfoBancoPagoRemesaAsignado;
end;
function SErrorAsignarBancoPagoRemesa: string;
begin
  Result :=
    inLibMsgVentas.SErrorAsignarBancoPagoRemesa;
end;
function STituloFechaCargoRemesa: string;
begin
  Result :=
    inLibMsgVentas.STituloFechaCargoRemesa;
end;
function SSolicitudFechaCargoRemesa: string;
begin
  Result :=
    inLibMsgVentas.SSolicitudFechaCargoRemesa;
end;
function SInfoFechaCargoRemesaActualizada: string;
begin
  Result :=
    inLibMsgVentas.SInfoFechaCargoRemesaActualizada;
end;
function SErrorActualizarFechaCargoRemesa: string;
begin
  Result :=
    inLibMsgVentas.SErrorActualizarFechaCargoRemesa;
end;
function SErrorFechaCargoRemesaNoValida: string;
begin
  Result :=
    inLibMsgVentas.SErrorFechaCargoRemesaNoValida;
end;
function SErrorEliminarRemesaVentaConCobro: string;
begin
  Result :=
    inLibMsgVentas.SErrorEliminarRemesaVentaConCobro;
end;
function SPreguntaEliminarRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaEliminarRemesaVenta;
end;
function SInfoRemesaVentaEliminada: string;
begin
  Result :=
    inLibMsgVentas.SInfoRemesaVentaEliminada;
end;
function SErrorEliminarRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorEliminarRemesaVenta;
end;
function SErrorAnadirEfectosRemesaVentaConCobro: string;
begin
  Result :=
    inLibMsgVentas.SErrorAnadirEfectosRemesaVentaConCobro;
end;
function SErrorEfectosRemesaVentaNoCargados: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectosRemesaVentaNoCargados;
end;
function SErrorEfectoRemesaVentaNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectoRemesaVentaNoSeleccionado;
end;
function SErrorQuitarEfectosRemesaVentaConCobro: string;
begin
  Result :=
    inLibMsgVentas.SErrorQuitarEfectosRemesaVentaConCobro;
end;
function SPreguntaQuitarEfectoRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaQuitarEfectoRemesaVenta;
end;
function SInfoEfectoRemesaVentaQuitado: string;
begin
  Result :=
    inLibMsgVentas.SInfoEfectoRemesaVentaQuitado;
end;
function SErrorQuitarEfectoRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorQuitarEfectoRemesaVenta;
end;
function SErrorBancoCobroRemesaNoAsignado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBancoCobroRemesaNoAsignado;
end;
function SErrorEfectoRemesaVentaSinPendiente: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectoRemesaVentaSinPendiente;
end;
function STextoEfectoPendienteRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.STextoEfectoPendienteRemesaVenta;
end;
function SInfoEfectoRemesaVentaConciliado: string;
begin
  Result :=
    inLibMsgVentas.SInfoEfectoRemesaVentaConciliado;
end;
function SErrorConciliarEfectoRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorConciliarEfectoRemesaVenta;
end;
function SErrorRemesaVentaSinImportePendiente: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaVentaSinImportePendiente;
end;
function STextoRemesaVentaPendiente: string;
begin
  Result :=
    inLibMsgVentas.STextoRemesaVentaPendiente;
end;
function SInfoEfectosRemesaVentaConciliados: string;
begin
  Result :=
    inLibMsgVentas.SInfoEfectosRemesaVentaConciliados;
end;
function SErrorConciliarRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorConciliarRemesaVenta;
end;
function SErrorBancoCobroNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBancoCobroNoSeleccionado;
end;
function SInfoBancoCobroRemesaAsignado: string;
begin
  Result :=
    inLibMsgVentas.SInfoBancoCobroRemesaAsignado;
end;
function SErrorAsignarBancoCobroRemesa: string;
begin
  Result :=
    inLibMsgVentas.SErrorAsignarBancoCobroRemesa;
end;
function STituloFechaCobroRemesa: string;
begin
  Result :=
    inLibMsgVentas.STituloFechaCobroRemesa;
end;
function SSolicitudFechaCobroRemesa: string;
begin
  Result :=
    inLibMsgVentas.SSolicitudFechaCobroRemesa;
end;
function SInfoFechaCobroRemesaActualizada: string;
begin
  Result :=
    inLibMsgVentas.SInfoFechaCobroRemesaActualizada;
end;
function SErrorActualizarFechaCobroRemesa: string;
begin
  Result :=
    inLibMsgVentas.SErrorActualizarFechaCobroRemesa;
end;
function SErrorFechaCobroRemesaNoValida: string;
begin
  Result :=
    inLibMsgVentas.SErrorFechaCobroRemesaNoValida;
end;
function SInfoOrdenSepaRemesaVentaGenerada: string;
begin
  Result :=
    inLibMsgVentas.SInfoOrdenSepaRemesaVentaGenerada;
end;
function SErrorGenerarOrdenSepaRemesaVenta: string;
begin
  Result :=
    inLibMsgVentas.SErrorGenerarOrdenSepaRemesaVenta;
end;
function SErrorCodigoBarrasStockNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCodigoBarrasStockNoEncontrado;
end;
function SErrorEntradaStockNoEncontrada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEntradaStockNoEncontrada;
end;
function SErrorSkuCeldaStockNoEncontrado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSkuCeldaStockNoEncontrado;
end;
function SErrorCeldaStockVariosSkus: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCeldaStockVariosSkus;
end;
function SErrorArticuloStockNoSeleccionadoOperaciones: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloStockNoSeleccionadoOperaciones;
end;
function SErrorCeldaTallaStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCeldaTallaStockNoSeleccionada;
end;
function SErrorColumnaTallaStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorColumnaTallaStockNoSeleccionada;
end;
function SErrorFilaStockNoIdentificada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFilaStockNoIdentificada;
end;
function SErrorColorStockNoUnico: string;
begin
  Result :=
    inLibMsgArticulos.SErrorColorStockNoUnico;
end;
function SErrorTallaStockVariosSkus: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTallaStockVariosSkus;
end;
function STituloOperacionesCajaStock: string;
begin
  Result :=
    inLibMsgCaja.STituloOperacionesCajaStock;
end;
function SErrorArticuloStockNoSeleccionadoDocumento: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloStockNoSeleccionadoDocumento;
end;
function SErrorEstadoStockNoEsExistencias: string;
begin
  Result :=
    inLibMsgArticulos.SErrorEstadoStockNoEsExistencias;
end;
function SErrorCeldaStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCeldaStockNoSeleccionada;
end;
function SErrorCeldaCantidadStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCeldaCantidadStockNoSeleccionada;
end;
function SErrorFilaExistenciasStockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorFilaExistenciasStockNoSeleccionada;
end;
function SErrorColumnaStockDocumentoNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorColumnaStockDocumentoNoSeleccionada;
end;
function SErrorGrupoFilaStockNoLeido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGrupoFilaStockNoLeido;
end;
function SErrorAlmacenStockNoUnico: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAlmacenStockNoUnico;
end;
function SErrorColorStockUnidadNoUnico: string;
begin
  Result :=
    inLibMsgArticulos.SErrorColorStockUnidadNoUnico;
end;
function STituloConsultaStock: string;
begin
  Result :=
    inLibMsgArticulos.STituloConsultaStock;
end;
function SErrorArticuloStockNoSeleccionadoFotos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloStockNoSeleccionadoFotos;
end;
function SInfoArticulosRelacionadosStockNoDisponibles: string;
begin
  Result :=
    inLibMsgArticulos.SInfoArticulosRelacionadosStockNoDisponibles;
end;
function SErrorTarifaNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaNoSeleccionada;
end;
function SPreguntaGuardarTarifaAntesContinuar: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGuardarTarifaAntesContinuar;
end;
function SErrorSesionTarifaNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorSesionTarifaNoSeleccionada;
end;
function SInfoLineasSesionTarifaRecalculadas: string;
begin
  Result :=
    inLibMsgArticulos.SInfoLineasSesionTarifaRecalculadas;
end;
function SErrorCalcularSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCalcularSesionTarifa;
end;
function SPreguntaAplicarSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaAplicarSesionTarifa;
end;
function SErrorAplicarSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAplicarSesionTarifa;
end;
function SInfoLineasSesionTarifaAplicadas: string;
begin
  Result :=
    inLibMsgArticulos.SInfoLineasSesionTarifaAplicadas;
end;
function SPreguntaLimpiarFiltrosAddBlock: string;
begin
  Result :=
    inLibMsgComun.SPreguntaLimpiarFiltrosAddBlock;
end;
function SErrorAlmacenesSoloStockAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAlmacenesSoloStockAddBlock;
end;
function SPreguntaPrevisualizarAddBlock: string;
begin
  Result :=
    inLibMsgComun.SPreguntaPrevisualizarAddBlock;
end;
function SInfoArticulosYaCargadosAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SInfoArticulosYaCargadosAddBlock;
end;
function SPreguntaConfirmarAddBlock: string;
begin
  Result :=
    inLibMsgComun.SPreguntaConfirmarAddBlock;
end;
function SInfoArticulosAnadidosAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SInfoArticulosAnadidosAddBlock;
end;
function SErrorDestinoDocumentoTrabajoAddBlock: string;
begin
  Result :=
    inLibMsgVentas.SErrorDestinoDocumentoTrabajoAddBlock;
end;
function SErrorAlmacenesDocumentoTrabajoAddBlock: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlmacenesDocumentoTrabajoAddBlock;
end;
function SPreguntaConfirmarDocumentoTrabajoAddBlock: string;
begin
  Result :=
    inLibMsgVentas.SPreguntaConfirmarDocumentoTrabajoAddBlock;
end;
function SInfoLineasDocumentoTrabajoAddBlock: string;
begin
  Result :=
    inLibMsgVentas.SInfoLineasDocumentoTrabajoAddBlock;
end;
function SErrorInsertarLineasDocumentoTrabajoAddBlock: string;
begin
  Result :=
    inLibMsgVentas.SErrorInsertarLineasDocumentoTrabajoAddBlock;
end;
function SErrorDestinoInventarioAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDestinoInventarioAddBlock;
end;
function SPreguntaConfirmarInventarioAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaConfirmarInventarioAddBlock;
end;
function SInfoLineasInventarioAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SInfoLineasInventarioAddBlock;
end;
function SErrorInsertarLineasInventarioAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInsertarLineasInventarioAddBlock;
end;
function SErrorTarifaDestinoAddBlockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaDestinoAddBlockNoSeleccionada;
end;
function SErrorTarifaOrigenAddBlockNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaOrigenAddBlockNoSeleccionada;
end;
function SErrorTarifasAddBlockCoincidentes: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifasAddBlockCoincidentes;
end;
function SErrorMultiploAjusteAddBlockNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorMultiploAjusteAddBlockNoValido;
end;
function SPreguntaConfirmarTarifaAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaConfirmarTarifaAddBlock;
end;
function SInfoArticulosTarifaAddBlockAnadidos: string;
begin
  Result :=
    inLibMsgArticulos.SInfoArticulosTarifaAddBlockAnadidos;
end;
function SErrorInsertarTarifaAddBlock: string;
begin
  Result :=
    inLibMsgArticulos.SErrorInsertarTarifaAddBlock;
end;
function SPreguntaQuitarPropiedadArticulo: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaQuitarPropiedadArticulo;
end;
function SErrorArticuloNoGuardadoValoresColor: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoGuardadoValoresColor;
end;
function SErrorArticuloNoGuardadoAnadirPropiedades: string;
begin
  Result :=
    inLibMsgArticulos.SErrorArticuloNoGuardadoAnadirPropiedades;
end;
function SErrorPropiedadObligatoriaFamilia: string;
begin
  Result :=
    inLibMsgArticulos.SErrorPropiedadObligatoriaFamilia;
end;
function SErrorPrecioCosteMargenNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorPrecioCosteMargenNoValido;
end;
function SErrorMargenNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorMargenNoValido;
end;
function SErrorAjusteMargenNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorAjusteMargenNoValido;
end;
function SErrorGuardarCambiosMargen: string;
begin
  Result :=
    inLibMsgArticulos.SErrorGuardarCambiosMargen;
end;
function SErrorProveedorPrincipalCosteNoAsignado: string;
begin
  Result :=
    inLibMsgArticulos.SErrorProveedorPrincipalCosteNoAsignado;
end;
function SErrorEmpresaEfectosRemesaNoIndicada: string;
begin
  Result :=
    inLibMsgVentas.SErrorEmpresaEfectosRemesaNoIndicada;
end;
function SInfoEfectosPendientesRemesaNoEncontrados: string;
begin
  Result :=
    inLibMsgVentas.SInfoEfectosPendientesRemesaNoEncontrados;
end;
function SErrorEfectosRemesaNoSeleccionados: string;
begin
  Result :=
    inLibMsgVentas.SErrorEfectosRemesaNoSeleccionados;
end;
function SErrorRemesaExistenteNoSeleccionada: string;
begin
  Result :=
    inLibMsgVentas.SErrorRemesaExistenteNoSeleccionada;
end;
function SInfoEfectosCargadosRemesa: string;
begin
  Result :=
    inLibMsgVentas.SInfoEfectosCargadosRemesa;
end;
function SPreguntaConfirmarCargaSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaConfirmarCargaSesionTarifa;
end;
function SInfoArticulosCargadosSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SInfoArticulosCargadosSesionTarifa;
end;
function SErrorCargarSesionTarifa: string;
begin
  Result :=
    inLibMsgArticulos.SErrorCargarSesionTarifa;
end;
function SErrorTipoDocumentoSesionNoSeleccionado: string;
begin
  Result :=
    inLibMsgCompras.SErrorTipoDocumentoSesionNoSeleccionado;
end;
function SErrorSerieAlbaranSesionNoIndicada: string;
begin
  Result :=
    inLibMsgVentas.SErrorSerieAlbaranSesionNoIndicada;
end;
function SErrorSeriePedidoSesionNoIndicada: string;
begin
  Result :=
    inLibMsgVentas.SErrorSeriePedidoSesionNoIndicada;
end;
function SErrorAlmacenDestinoSesionNoIndicado: string;
begin
  Result :=
    inLibMsgCompras.SErrorAlmacenDestinoSesionNoIndicado;
end;
function SErrorCertificadoNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorCertificadoNoSeleccionado;
end;
function SErrorEmpleadoEntradaCambioNoIndicado: string;
begin
  Result :=
    inLibMsgComun.SErrorEmpleadoEntradaCambioNoIndicado;
end;
function SErrorImporteEntradaCambioNoValido: string;
begin
  Result :=
    inLibMsgComun.SErrorImporteEntradaCambioNoValido;
end;
function STituloAvisoEntradaCambio: string;
begin
  Result :=
    inLibMsgComun.STituloAvisoEntradaCambio;
end;
function SErrorDestinoEnvioIncompleto: string;
begin
  Result :=
    inLibMsgComun.SErrorDestinoEnvioIncompleto;
end;
function SErrorTarifaEtiquetasNoSeleccionada: string;
begin
  Result :=
    inLibMsgArticulos.SErrorTarifaEtiquetasNoSeleccionada;
end;
function SInfoLayoutEtiquetasGuardado: string;
begin
  Result :=
    inLibMsgArticulos.SInfoLayoutEtiquetasGuardado;
end;
function SErrorEmpresaProveedorFacturacionNoIndicados: string;
begin
  Result :=
    inLibMsgFacturas.SErrorEmpresaProveedorFacturacionNoIndicados;
end;
function SInfoAlbaranesPendientesProveedorNoEncontrados: string;
begin
  Result :=
    inLibMsgVentas.SInfoAlbaranesPendientesProveedorNoEncontrados;
end;
function SPreguntaFacturarTodosAlbaranesListados: string;
begin
  Result :=
    inLibMsgFacturas.SPreguntaFacturarTodosAlbaranesListados;
end;
function SErrorBorradorAlbaranesExistenteNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorBorradorAlbaranesExistenteNoSeleccionado;
end;
function SInfoAlbaranesGeneradosEnBorrador: string;
begin
  Result :=
    inLibMsgVentas.SInfoAlbaranesGeneradosEnBorrador;
end;
function SErrorDataModuleAlbaranesNoAsignado: string;
begin
  Result :=
    inLibMsgVentas.SErrorDataModuleAlbaranesNoAsignado;
end;
function SErrorAlbaranesNoSeleccionados: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlbaranesNoSeleccionados;
end;
function SInfoBorradoresGenerados: string;
begin
  Result :=
    inLibMsgFacturas.SInfoBorradoresGenerados;
end;
function SErrorClienteBorradorNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorClienteBorradorNoSeleccionado;
end;
function SErrorSerieBorradorNoSeleccionada: string;
begin
  Result :=
    inLibMsgComun.SErrorSerieBorradorNoSeleccionada;
end;
function SErrorFechaBorradorNoIndicada: string;
begin
  Result :=
    inLibMsgComun.SErrorFechaBorradorNoIndicada;
end;
function SErrorClienteFacturarTicketNoExiste: string;
begin
  Result :=
    inLibMsgFacturas.SErrorClienteFacturarTicketNoExiste;
end;
function SErrorRazonSocialFacturarTicketObligatoria: string;
begin
  Result :=
    inLibMsgFacturas.SErrorRazonSocialFacturarTicketObligatoria;
end;
function SErrorDocumentoFiscalFacturarTicketNoValido: string;
begin
  Result :=
    inLibMsgFacturas.SErrorDocumentoFiscalFacturarTicketNoValido;
end;
function SErrorCrearBorradorFacturarTicket: string;
begin
  Result :=
    inLibMsgFacturas.SErrorCrearBorradorFacturarTicket;
end;
function SPreguntaSuperarLimiteCargaArticulos: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaSuperarLimiteCargaArticulos;
end;
function SErrorDimensionesSkuNoDefinidas: string;
begin
  Result :=
    inLibMsgArticulos.SErrorDimensionesSkuNoDefinidas;
end;
function SErrorValoresSkuNoSeleccionados: string;
begin
  Result :=
    inLibMsgArticulos.SErrorValoresSkuNoSeleccionados;
end;
function SErrorValoresDimensionesSkuIncompletos: string;
begin
  Result :=
    inLibMsgArticulos.SErrorValoresDimensionesSkuIncompletos;
end;
function SInfoCombinacionesSkuGeneradas: string;
begin
  Result :=
    inLibMsgArticulos.SInfoCombinacionesSkuGeneradas;
end;
function STituloAnadirValorSku: string;
begin
  Result :=
    inLibMsgArticulos.STituloAnadirValorSku;
end;
function SSolicitudNombreValorSku: string;
begin
  Result :=
    inLibMsgArticulos.SSolicitudNombreValorSku;
end;
function SSolicitudOrdenNuevoValorSku: string;
begin
  Result :=
    inLibMsgArticulos.SSolicitudOrdenNuevoValorSku;
end;
function SPreguntaGuardarValorSkuGlobal: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaGuardarValorSkuGlobal;
end;
function SPreguntaUsarValorSkuTemporal: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaUsarValorSkuTemporal;
end;
function STituloCambiarOrdenValorSku: string;
begin
  Result :=
    inLibMsgArticulos.STituloCambiarOrdenValorSku;
end;
function SSolicitudOrdenValorSku: string;
begin
  Result :=
    inLibMsgArticulos.SSolicitudOrdenValorSku;
end;
function SErrorOrdenValorSkuNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorOrdenValorSkuNoValido;
end;
function SPreguntaCambiarOrdenValorSkuGlobal: string;
begin
  Result :=
    inLibMsgArticulos.SPreguntaCambiarOrdenValorSkuGlobal;
end;
function STituloCambiarOrdenAtributoSku: string;
begin
  Result :=
    inLibMsgArticulos.STituloCambiarOrdenAtributoSku;
end;
function SSolicitudOrdenAtributoSku: string;
begin
  Result :=
    inLibMsgArticulos.SSolicitudOrdenAtributoSku;
end;
function SErrorOrdenAtributoSkuNoValido: string;
begin
  Result :=
    inLibMsgArticulos.SErrorOrdenAtributoSkuNoValido;
end;
function SPreguntaEditarCamposExtraInforme: string;
begin
  Result :=
    inLibMsgComun.SPreguntaEditarCamposExtraInforme;
end;
function SErrorPrivilegiosBorrarFormato: string;
begin
  Result :=
    inLibMsgComun.SErrorPrivilegiosBorrarFormato;
end;
function SPreguntaBorrarFormato: string;
begin
  Result :=
    inLibMsgComun.SPreguntaBorrarFormato;
end;
function SPreguntaReemplazarInforme: string;
begin
  Result :=
    inLibMsgComun.SPreguntaReemplazarInforme;
end;
function STituloAdvertenciaInforme: string;
begin
  Result :=
    inLibMsgComun.STituloAdvertenciaInforme;
end;
function SErrorContrasenasNoCoinciden: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorContrasenasNoCoinciden;
end;
function SErrorFiltroNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroNoSeleccionado;
end;
function SErrorFiltroSinCondicionesAplicar: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroSinCondicionesAplicar;
end;
function SErrorFiltroSinCondicionesGuardar: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroSinCondicionesGuardar;
end;
function SInfoCambiosFiltroGuardados: string;
begin
  Result :=
    inLibMsgComun.SInfoCambiosFiltroGuardados;
end;
function SErrorPantallaSinFiltroAplicado: string;
begin
  Result :=
    inLibMsgComun.SErrorPantallaSinFiltroAplicado;
end;
function SPreguntaReemplazarFiltro: string;
begin
  Result :=
    inLibMsgComun.SPreguntaReemplazarFiltro;
end;
function STituloReemplazarFiltro: string;
begin
  Result :=
    inLibMsgComun.STituloReemplazarFiltro;
end;
function SInfoFiltroReemplazado: string;
begin
  Result :=
    inLibMsgComun.SInfoFiltroReemplazado;
end;
function SErrorFiltroPropioDuplicado: string;
begin
  Result :=
    inLibMsgComun.SErrorFiltroPropioDuplicado;
end;
function SInfoCopiaFiltroGuardada: string;
begin
  Result :=
    inLibMsgComun.SInfoCopiaFiltroGuardada;
end;
function SPreguntaBorrarFiltro: string;
begin
  Result :=
    inLibMsgComun.SPreguntaBorrarFiltro;
end;
function STituloConfirmarBorradoFiltro: string;
begin
  Result :=
    inLibMsgComun.STituloConfirmarBorradoFiltro;
end;
function SInfoFiltroCompartidoGrupo: string;
begin
  Result :=
    inLibMsgComun.SInfoFiltroCompartidoGrupo;
end;
function SInfoFiltroCompartidoTodos: string;
begin
  Result :=
    inLibMsgComun.SInfoFiltroCompartidoTodos;
end;
function SErrorNombreFiltroNoIndicado: string;
begin
  Result :=
    inLibMsgComun.SErrorNombreFiltroNoIndicado;
end;
function SErrorCodigoGuiaNoIndicado: string;
begin
  Result :=
    inLibMsgComun.SErrorCodigoGuiaNoIndicado;
end;
function SErrorTablaExternaGuiaNoSeleccionada: string;
begin
  Result :=
    inLibMsgComun.SErrorTablaExternaGuiaNoSeleccionada;
end;
function SErrorCampoMasterGuiaNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorCampoMasterGuiaNoSeleccionado;
end;
function SErrorCampoDetailGuiaNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorCampoDetailGuiaNoSeleccionado;
end;
function SInfoGuiaAnadida: string;
begin
  Result :=
    inLibMsgComun.SInfoGuiaAnadida;
end;
function SInfoGuiasEliminarNoEncontradas: string;
begin
  Result :=
    inLibMsgComun.SInfoGuiasEliminarNoEncontradas;
end;
function SPreguntaEliminarGuia: string;
begin
  Result :=
    inLibMsgComun.SPreguntaEliminarGuia;
end;
function SErrorFacturaCompraExportarNoPreparada: string;
begin
  Result :=
    inLibMsgCompras.SErrorFacturaCompraExportarNoPreparada;
end;
function SErrorDataModulePedidosNoAsignado: string;
begin
  Result :=
    inLibMsgVentas.SErrorDataModulePedidosNoAsignado;
end;
function SInfoImportacionPedidosFinalizada: string;
begin
  Result :=
    inLibMsgVentas.SInfoImportacionPedidosFinalizada;
end;
function SErrorConexionOperacionesCajaSkuNoDisponible: string;
begin
  Result :=
    inLibMsgCaja.SErrorConexionOperacionesCajaSkuNoDisponible;
end;
function SErrorImporteConciliadoNoValido: string;
begin
  Result :=
    inLibMsgComun.SErrorImporteConciliadoNoValido;
end;
function SErrorImporteConciliadoSuperaPendiente: string;
begin
  Result :=
    inLibMsgComun.SErrorImporteConciliadoSuperaPendiente;
end;
function SErrorNombreFormatoWizardNoIndicado: string;
begin
  Result :=
    inLibMsgComun.SErrorNombreFormatoWizardNoIndicado;
end;
function SErrorNombreFormatoWizardNoModificado: string;
begin
  Result :=
    inLibMsgComun.SErrorNombreFormatoWizardNoModificado;
end;
function SErrorDatasetMasterWizardNoSeleccionado: string;
begin
  Result :=
    inLibMsgComun.SErrorDatasetMasterWizardNoSeleccionado;
end;
function SErrorCamposMasterWizardNoSeleccionados: string;
begin
  Result :=
    inLibMsgComun.SErrorCamposMasterWizardNoSeleccionados;
end;
function SErrorTablaExternaWizardNoSeleccionada: string;
begin
  Result :=
    inLibMsgComun.SErrorTablaExternaWizardNoSeleccionada;
end;
function SErrorCamposTablaExternaWizardNoSeleccionados: string;
begin
  Result :=
    inLibMsgComun.SErrorCamposTablaExternaWizardNoSeleccionados;
end;
function SErrorPrepararImpresionDeclaracionResponsable: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorPrepararImpresionDeclaracionResponsable;
end;
function SErrorImprimirDeclaracionResponsable: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorImprimirDeclaracionResponsable;
end;
function SInfoNumeroInstalacionSifDisponible: string;
begin
  Result :=
    inLibMsgVerifactu.SInfoNumeroInstalacionSifDisponible;
end;
function SErrorGenerarNumeroInstalacionSif: string;
begin
  Result :=
    inLibMsgVerifactu.SErrorGenerarNumeroInstalacionSif;
end;
function SErrorSerieDocumentoNoIndicada: string;
begin
  Result :=
    inLibMsgComun.SErrorSerieDocumentoNoIndicada;
end;
function SErrorFechaInicioDocumentoNoIndicada: string;
begin
  Result :=
    inLibMsgComun.SErrorFechaInicioDocumentoNoIndicada;
end;
function SErrorFechaFinDocumentoNoIndicada: string;
begin
  Result :=
    inLibMsgComun.SErrorFechaFinDocumentoNoIndicada;
end;
function SErrorRangoFechasDocumentoNoValido: string;
begin
  Result :=
    inLibMsgComun.SErrorRangoFechasDocumentoNoValido;
end;
function SInfoEmpresaSinCuentasBancarias: string;
begin
  Result :=
    inLibMsgComun.SInfoEmpresaSinCuentasBancarias;
end;
function SErrorAlmacenPedidoNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlmacenPedidoNoSeleccionado;
end;
function SInfoAlbaranesIncorporarNoDisponibles: string;
begin
  Result :=
    inLibMsgVentas.SInfoAlbaranesIncorporarNoDisponibles;
end;
function SErrorSerieAlbaranPedidoNoIndicada: string;
begin
  Result :=
    inLibMsgVentas.SErrorSerieAlbaranPedidoNoIndicada;
end;
function SInfoLogGuardado: string;
begin
  Result :=
    inLibMsgConfiguracion.SInfoLogGuardado;
end;
function SErrorAlmacenAlbaranNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlmacenAlbaranNoSeleccionado;
end;
function SErrorAlbaranDestinoNoSeleccionado: string;
begin
  Result :=
    inLibMsgVentas.SErrorAlbaranDestinoNoSeleccionado;
end;
function SErrorCodigoAcreedorSepaNoIndicado: string;
begin
  Result :=
    inLibMsgVentas.SErrorCodigoAcreedorSepaNoIndicado;
end;
function SErrorLongitudCodigoAcreedorSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorLongitudCodigoAcreedorSepa;
end;
function SErrorFormatoCodigoAcreedorSepaNoValido: string;
begin
  Result :=
    inLibMsgVentas.SErrorFormatoCodigoAcreedorSepaNoValido;
end;
function SErrorSecuenciaSepaNoValida: string;
begin
  Result :=
    inLibMsgVentas.SErrorSecuenciaSepaNoValida;
end;
function SErrorClientesSinMandatoSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorClientesSinMandatoSepa;
end;
function SErrorMandatosSepaLongitudNoValida: string;
begin
  Result :=
    inLibMsgVentas.SErrorMandatosSepaLongitudNoValida;
end;
function SErrorClientesSinFechaFirmaMandatoSepa: string;
begin
  Result :=
    inLibMsgVentas.SErrorClientesSinFechaFirmaMandatoSepa;
end;
function SErrorCodigoFormaPagoCajaObligatorio: string;
begin
  Result :=
    inLibMsgCaja.SErrorCodigoFormaPagoCajaObligatorio;
end;
function SErrorDescripcionFormaPagoCajaObligatoria: string;
begin
  Result :=
    inLibMsgCaja.SErrorDescripcionFormaPagoCajaObligatoria;
end;
function SErrorParametrosAplicacionCajaNoConfigurados: string;
begin
  Result :=
    inLibMsgCaja.SErrorParametrosAplicacionCajaNoConfigurados;
end;
function SErrorParametrosModuloCajaNoConfigurados: string;
begin
  Result :=
    inLibMsgCaja.SErrorParametrosModuloCajaNoConfigurados;
end;
function SErrorContextoSesionCajaNoConfigurado: string;
begin
  Result :=
    inLibMsgCaja.SErrorContextoSesionCajaNoConfigurado;
end;
function SErrorOperacionCajaSinLineas: string;
begin
  Result :=
    inLibMsgCaja.SErrorOperacionCajaSinLineas;
end;
function SErrorRazonSocialClienteFacturaCajaObligatoria: string;
begin
  Result :=
    inLibMsgCaja.SErrorRazonSocialClienteFacturaCajaObligatoria;
end;
function SErrorDocumentoFiscalClienteCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorDocumentoFiscalClienteCajaNoValido;
end;
function SErrorDocumentoFiscalEmpresaCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorDocumentoFiscalEmpresaCajaNoValido;
end;
function SErrorFechaTicketSerieNoValida: string;
begin
  Result :=
    inLibMsgFacturas.SErrorFechaTicketSerieNoValida;
end;
function SErrorCuadreCobroParcialCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorCuadreCobroParcialCaja;
end;
function SErrorFacturaRectificativaCajaSinOriginal: string;
begin
  Result :=
    inLibMsgCaja.SErrorFacturaRectificativaCajaSinOriginal;
end;
function SErrorGuardarTicketCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorGuardarTicketCaja;
end;
function SErrorCuadrarFacturaCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorCuadrarFacturaCaja;
end;
function SErrorRedimirValeCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorRedimirValeCaja;
end;
function SErrorContextoSesionTraspasoNoConfigurado: string;
begin
  Result :=
    inLibMsgCaja.SErrorContextoSesionTraspasoNoConfigurado;
end;
function SErrorSkuTraspasoIncompleto: string;
begin
  Result :=
    inLibMsgCaja.SErrorSkuTraspasoIncompleto;
end;
function SErrorArticuloSkuTraspasoNoCoincide: string;
begin
  Result :=
    inLibMsgCaja.SErrorArticuloSkuTraspasoNoCoincide;
end;
function SErrorStockTraspasoInsuficiente: string;
begin
  Result :=
    inLibMsgCaja.SErrorStockTraspasoInsuficiente;
end;
function SErrorLineasTraspasoNoDisponibles: string;
begin
  Result :=
    inLibMsgCaja.SErrorLineasTraspasoNoDisponibles;
end;
function SErrorAlmacenDestinoTraspasoNoSeleccionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorAlmacenDestinoTraspasoNoSeleccionado;
end;
function SErrorAlmacenesTraspasoCoincidentes: string;
begin
  Result :=
    inLibMsgCaja.SErrorAlmacenesTraspasoCoincidentes;
end;
function SErrorLineasSolicitudTraspasoNoDisponibles: string;
begin
  Result :=
    inLibMsgCaja.SErrorLineasSolicitudTraspasoNoDisponibles;
end;
function SErrorAlmacenOrigenSolicitudNoSeleccionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorAlmacenOrigenSolicitudNoSeleccionado;
end;
function SErrorSolicitudTraspasoMismoAlmacen: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudTraspasoMismoAlmacen;
end;
function SErrorSolicitudTraspasoNoCargada: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudTraspasoNoCargada;
end;
function SErrorPermisoAbrirCajon: string;
begin
  Result :=
    inLibMsgConfiguracion.SErrorPermisoAbrirCajon;
end;
function SErrorImpresoraTicketsCajaNoConfigurada: string;
begin
  Result :=
    inLibMsgCaja.SErrorImpresoraTicketsCajaNoConfigurada;
end;
function SErrorContextoImpresoraCajaNoProporcionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorContextoImpresoraCajaNoProporcionado;
end;
function SErrorReferenciaPagoCajaNoIndicada: string;
begin
  Result :=
    inLibMsgCaja.SErrorReferenciaPagoCajaNoIndicada;
end;
function SErrorFactorCambioCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorFactorCambioCajaNoValido;
end;
function SErrorHashBlockchainCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorHashBlockchainCajaNoIndicado;
end;
function SErrorValeCajaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorValeCajaNoSeleccionado;
end;
function SErrorPinValeCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorPinValeCajaNoIndicado;
end;
function SErrorPinValeCajaIncorrecto: string;
begin
  Result :=
    inLibMsgCaja.SErrorPinValeCajaIncorrecto;
end;
function SErrorProveedorParametrosCajaNoConfigurado: string;
begin
  Result :=
    inLibMsgCaja.SErrorProveedorParametrosCajaNoConfigurado;
end;
function SErrorParametrosCajaEditablesNoConfigurados: string;
begin
  Result :=
    inLibMsgCaja.SErrorParametrosCajaEditablesNoConfigurados;
end;
function SInfoLayoutCajaGuardado: string;
begin
  Result :=
    inLibMsgCaja.SInfoLayoutCajaGuardado;
end;
function SInfoParametrosCajaGuardados: string;
begin
  Result :=
    inLibMsgCaja.SInfoParametrosCajaGuardados;
end;
function SInfoParametrosCajaSinCambios: string;
begin
  Result :=
    inLibMsgCaja.SInfoParametrosCajaSinCambios;
end;
function SPreguntaSalirParametrosCajaSinGuardar: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaSalirParametrosCajaSinGuardar;
end;
function SInfoUsuariosParametrosCajaNoEncontrados: string;
begin
  Result :=
    inLibMsgCaja.SInfoUsuariosParametrosCajaNoEncontrados;
end;
function STituloCambiarUsuarioParametrosCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloCambiarUsuarioParametrosCaja;
end;
function SSolicitudCambiarUsuarioParametrosCaja: string;
begin
  Result :=
    inLibMsgCaja.SSolicitudCambiarUsuarioParametrosCaja;
end;
function SErrorUsuarioParametrosCajaNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorUsuarioParametrosCajaNoEncontrado;
end;
function SInfoPrecargaCajaGuardada: string;
begin
  Result :=
    inLibMsgCaja.SInfoPrecargaCajaGuardada;
end;
function SErrorAsignarUbicacionCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorAsignarUbicacionCaja;
end;
function STituloHoraCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloHoraCaja;
end;
function SSolicitudHoraCaja: string;
begin
  Result :=
    inLibMsgCaja.SSolicitudHoraCaja;
end;
function SErrorHoraCajaNoValida: string;
begin
  Result :=
    inLibMsgCaja.SErrorHoraCajaNoValida;
end;
function SErrorUbicacionCajaBuscarOperacionesNoAsignada: string;
begin
  Result :=
    inLibMsgCaja.SErrorUbicacionCajaBuscarOperacionesNoAsignada;
end;
function SErrorUbicacionCajaArqueoNoAsignada: string;
begin
  Result :=
    inLibMsgCaja.SErrorUbicacionCajaArqueoNoAsignada;
end;
function SErrorUbicacionCajaTraspasoNoAsignada: string;
begin
  Result :=
    inLibMsgCaja.SErrorUbicacionCajaTraspasoNoAsignada;
end;
function SErrorRectificacionCajaNoAdmiteBorrador: string;
begin
  Result :=
    inLibMsgCaja.SErrorRectificacionCajaNoAdmiteBorrador;
end;
function SErrorClienteBorradorCajaNoAsignado: string;
begin
  Result :=
    inLibMsgCaja.SErrorClienteBorradorCajaNoAsignado;
end;
function SErrorNifClienteBorradorCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorNifClienteBorradorCajaNoIndicado;
end;
function SErrorFechaSerieEmisionCajaNoValida: string;
begin
  Result :=
    inLibMsgCaja.SErrorFechaSerieEmisionCajaNoValida;
end;
function SAvisoHuecosNumeracionSerieCaja: string;
begin
  Result :=
    inLibMsgCaja.SAvisoHuecosNumeracionSerieCaja;
end;
function SErrorNumeroBorradorCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorNumeroBorradorCajaNoValido;
end;
function SErrorNumeroBorradorCajaExistente: string;
begin
  Result :=
    inLibMsgCaja.SErrorNumeroBorradorCajaExistente;
end;
function SErrorNumeroBorradorCajaNoEsHueco: string;
begin
  Result :=
    inLibMsgCaja.SErrorNumeroBorradorCajaNoEsHueco;
end;
function STituloEnviarDocumentacionCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloEnviarDocumentacionCaja;
end;
function SSolicitudCorreoDocumentacionCaja: string;
begin
  Result :=
    inLibMsgCaja.SSolicitudCorreoDocumentacionCaja;
end;
function SErrorCorreoDocumentacionCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorCorreoDocumentacionCajaNoIndicado;
end;
function SErrorCreditoClienteCajaNoPermitido: string;
begin
  Result :=
    inLibMsgCaja.SErrorCreditoClienteCajaNoPermitido;
end;
function SErrorImporteCreditoCajaNoPendiente: string;
begin
  Result :=
    inLibMsgCaja.SErrorImporteCreditoCajaNoPendiente;
end;
function SAvisoLimiteOperacionesCaja: string;
begin
  Result :=
    inLibMsgCaja.SAvisoLimiteOperacionesCaja;
end;
function SErrorOperacionCajaExportarNoSeleccionada: string;
begin
  Result :=
    inLibMsgCaja.SErrorOperacionCajaExportarNoSeleccionada;
end;
function SErrorSkuVentaCajaNoExiste: string;
begin
  Result :=
    inLibMsgCaja.SErrorSkuVentaCajaNoExiste;
end;
function SErrorSkuVentaCajaNoActivo: string;
begin
  Result :=
    inLibMsgCaja.SErrorSkuVentaCajaNoActivo;
end;
function SErrorArticuloVentaCajaSinStock: string;
begin
  Result :=
    inLibMsgCaja.SErrorArticuloVentaCajaSinStock;
end;
function SErrorVendedorCajaNoAsignado: string;
begin
  Result :=
    inLibMsgCaja.SErrorVendedorCajaNoAsignado;
end;
function SErrorCodigoBarrasVentaCajaNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorCodigoBarrasVentaCajaNoEncontrado;
end;
function SErrorLineaDepositoCajaNoCancelable: string;
begin
  Result :=
    inLibMsgCaja.SErrorLineaDepositoCajaNoCancelable;
end;
function SErrorArticuloVentaCajaNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorArticuloVentaCajaNoEncontrado;
end;
function SPreguntaCancelarVentaCaja: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaCancelarVentaCaja;
end;
function SErrorLineaDepositoCajaNoEliminable: string;
begin
  Result :=
    inLibMsgCaja.SErrorLineaDepositoCajaNoEliminable;
end;
function SPreguntaBorrarVentaCaja: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaBorrarVentaCaja;
end;
function SInfoValeCajaEntregar: string;
begin
  Result :=
    inLibMsgCaja.SInfoValeCajaEntregar;
end;
function SErrorCorreoOperacionCajaNoEnviado: string;
begin
  Result :=
    inLibMsgCaja.SErrorCorreoOperacionCajaNoEnviado;
end;
function SErrorTipoRectificativaCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorTipoRectificativaCajaNoIndicado;
end;
function SErrorBorradorRectificarCajaNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorBorradorRectificarCajaNoEncontrado;
end;
function SErrorClienteDepositosCajaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorClienteDepositosCajaNoSeleccionado;
end;
function SErrorValoresAtributoCajaNoDefinidos: string;
begin
  Result :=
    inLibMsgCaja.SErrorValoresAtributoCajaNoDefinidos;
end;
function SPreguntaEliminarOperacionCajaPendiente: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaEliminarOperacionCajaPendiente;
end;
function SErrorArticuloCajaNoEncontradoDescatalogado: string;
begin
  Result :=
    inLibMsgCaja.SErrorArticuloCajaNoEncontradoDescatalogado;
end;
function SErrorCantidadArticuloDepositoCajaNoValida: string;
begin
  Result :=
    inLibMsgCaja.SErrorCantidadArticuloDepositoCajaNoValida;
end;
function SErrorCodigoClienteCajaNoExiste: string;
begin
  Result :=
    inLibMsgCaja.SErrorCodigoClienteCajaNoExiste;
end;
function SErrorEmpleadoCajaNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorEmpleadoCajaNoEncontrado;
end;
function SErrorSolicitudesTraspasoPendientesNoEncontradas: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudesTraspasoPendientesNoEncontradas;
end;
function SErrorCargarSolicitudTraspaso: string;
begin
  Result :=
    inLibMsgCaja.SErrorCargarSolicitudTraspaso;
end;
function SErrorSolicitudTraspasoCerrarNoCargada: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudTraspasoCerrarNoCargada;
end;
function SPreguntaCerrarSolicitudTraspaso: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaCerrarSolicitudTraspaso;
end;
function SInfoSolicitudTraspasoCerrada: string;
begin
  Result :=
    inLibMsgCaja.SInfoSolicitudTraspasoCerrada;
end;
function SErrorDenegarSolicitudTraspasoModoNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorDenegarSolicitudTraspasoModoNoValido;
end;
function SErrorSolicitudTraspasoDenegarNoCargada: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudTraspasoDenegarNoCargada;
end;
function STituloDenegarSolicitudTraspaso: string;
begin
  Result :=
    inLibMsgCaja.STituloDenegarSolicitudTraspaso;
end;
function SSolicitudMotivoRechazoTraspaso: string;
begin
  Result :=
    inLibMsgCaja.SSolicitudMotivoRechazoTraspaso;
end;
function SErrorMotivoDenegacionTraspasoNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorMotivoDenegacionTraspasoNoIndicado;
end;
function SInfoPeticionTraspasoDenegada: string;
begin
  Result :=
    inLibMsgCaja.SInfoPeticionTraspasoDenegada;
end;
function SInfoSolicitudTraspasoEnviada: string;
begin
  Result :=
    inLibMsgCaja.SInfoSolicitudTraspasoEnviada;
end;
function SErrorEmpleadoTraspasoNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorEmpleadoTraspasoNoIndicado;
end;
function SErrorEmpleadoTraspasoNoEncontrado: string;
begin
  Result :=
    inLibMsgCaja.SErrorEmpleadoTraspasoNoEncontrado;
end;
function SErrorSolicitudTraspasoAtenderNoCargada: string;
begin
  Result :=
    inLibMsgCaja.SErrorSolicitudTraspasoAtenderNoCargada;
end;
function SErrorMotivoLineasTraspasoNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorMotivoLineasTraspasoNoIndicado;
end;
function SInfoSolicitudTraspasoAtendida: string;
begin
  Result :=
    inLibMsgCaja.SInfoSolicitudTraspasoAtendida;
end;
function SPreguntaDenegarPeticionTraspasoCompleta: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaDenegarPeticionTraspasoCompleta;
end;
function SInfoTraspasoGrabado: string;
begin
  Result :=
    inLibMsgCaja.SInfoTraspasoGrabado;
end;
function SErrorEmpleadoGastoCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorEmpleadoGastoCajaNoIndicado;
end;
function SErrorImporteGastoCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorImporteGastoCajaNoValido;
end;
function STituloAvisoCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloAvisoCaja;
end;
function SErrorArqueoCajaNoSeleccionado: string;
begin
  Result :=
    inLibMsgCaja.SErrorArqueoCajaNoSeleccionado;
end;
function SErrorPermisoResumenArqueoCaja: string;
begin
  Result :=
    inLibMsgCaja.SErrorPermisoResumenArqueoCaja;
end;
function SInfoOperacionesFacturadasArqueoCajaNoEncontradas: string;
begin
  Result :=
    inLibMsgCaja.SInfoOperacionesFacturadasArqueoCajaNoEncontradas;
end;
function STituloTiraCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloTiraCaja;
end;
function SErrorVendedorArqueoCajaNoIndicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorVendedorArqueoCajaNoIndicado;
end;
function STituloVendedorArqueoCajaObligatorio: string;
begin
  Result :=
    inLibMsgCaja.STituloVendedorArqueoCajaObligatorio;
end;
function SErrorVendedorArqueoCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.SErrorVendedorArqueoCajaNoValido;
end;
function STituloVendedorArqueoCajaNoValido: string;
begin
  Result :=
    inLibMsgCaja.STituloVendedorArqueoCajaNoValido;
end;
function SErrorArqueoCajaDuplicado: string;
begin
  Result :=
    inLibMsgCaja.SErrorArqueoCajaDuplicado;
end;
function STituloArqueoCajaDuplicado: string;
begin
  Result :=
    inLibMsgCaja.STituloArqueoCajaDuplicado;
end;
function SErrorRecuentoArqueoCajaNoDisponible: string;
begin
  Result :=
    inLibMsgCaja.SErrorRecuentoArqueoCajaNoDisponible;
end;
function SPreguntaGrabarArqueoCaja: string;
begin
  Result :=
    inLibMsgCaja.SPreguntaGrabarArqueoCaja;
end;
function STituloConfirmarArqueoCaja: string;
begin
  Result :=
    inLibMsgCaja.STituloConfirmarArqueoCaja;
end;

end.
