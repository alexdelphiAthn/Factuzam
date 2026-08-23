unit inLibRegistroResourcestringTraducciones;

interface

type
  TRegistrarResourcestringTraduccion = reference to procedure(
    const AClave, AContexto: string;
    ARecurso: PResStringRec);

procedure EnumerarResourcestringsTraduccion(
  const ARegistrar: TRegistrarResourcestringTraduccion);

implementation

uses
  inLibMsgArticulos,
  inLibMsgCaja,
  inLibMsgCompras,
  inLibMsgComun,
  inLibMsgConfiguracion,
  inLibMsgFacturas,
  inLibMsgIntegraciones,
  inLibMsgTickets,
  inLibMsgVentas,
  inLibMsgVerifactu,
  Vcl.Consts;

{$WARN SYMBOL_DEPRECATED OFF}
procedure EnumerarResourcestringsTraduccion(
  const ARegistrar: TRegistrarResourcestringTraduccion);
begin
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaAlbaranSinArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaAlbaranSinArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoSkuCodigoBarrasObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoSkuCodigoBarrasObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCampoCodigoBarrasAusente',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCampoCodigoBarrasAusente);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoSkuObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoSkuObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFilaCodigoBarrasInexistente',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFilaCodigoBarrasInexistente);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorProveedorPrincipalArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorProveedorPrincipalArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDescripcionArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDescripcionArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPermisoCambiarMarcaWebArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPermisoCambiarMarcaWebArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaDesactivarArticuloPrestaShop',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaDesactivarArticuloPrestaShop);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaDesactivarTarifaSinPrecio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaDesactivarTarifaSinPrecio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaActivarTarifaConPrecio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaActivarTarifaConPrecio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaFechasConcurrentes',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaFechasConcurrentes);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAtributoBasicoObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAtributoBasicoObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoAtributoBasicoObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoAtributoBasicoObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorNombreAtributoBasicoObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorNombreAtributoBasicoObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValorColeccionAtributosObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValorColeccionAtributosObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloLineaDocumentoTrabajoObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloLineaDocumentoTrabajoObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuLineaDocumentoTrabajoObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuLineaDocumentoTrabajoObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoPropiedadFamiliaDuplicada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoPropiedadFamiliaDuplicada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorNombreFamilia',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorNombreFamilia);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFamiliaPadreIgualHija',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFamiliaPadreIgualHija);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSerieInventarioObligatoria',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSerieInventarioObligatoria);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorContadorLineasInventarioNoInstalado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorContadorLineasInventarioNoInstalado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCabeceraInventarioSinGrabarParaReserva',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCabeceraInventarioSinGrabarParaReserva);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCabeceraInventarioNoEncontrada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCabeceraInventarioNoEncontrada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorActualizarContadorLineasInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorActualizarContadorLineasInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEmpresaCabeceraInventarioObligatoria',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEmpresaCabeceraInventarioObligatoria);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAlmacenCabeceraInventarioObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAlmacenCabeceraInventarioObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSerieCabeceraInventarioObligatoria',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSerieCabeceraInventarioObligatoria);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorNumeroCabeceraInventarioObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorNumeroCabeceraInventarioObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAtributoLineaInventarioObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAtributoLineaInventarioObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCrearSkuInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCrearSkuInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuInventarioNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuInventarioNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEliminarLineasInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEliminarLineasInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAnadirLineaCabeceraInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAnadirLineaCabeceraInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorRecalcularInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorRecalcularInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAplicarInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAplicarInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAplicarInventarioSinLineas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAplicarInventarioSinLineas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEliminarRegularizacionInventarioNoAplicado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEliminarRegularizacionInventarioNoAplicado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCargarArticulosInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCargarArticulosInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCompletarInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCompletarInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloLineaInventarioObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloLineaInventarioObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAnadirSkusInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAnadirSkusInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValorAtributoSkuInventarioNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValorAtributoSkuInventarioNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoEdicionMovimientoAlmacen',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoEdicionMovimientoAlmacen);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaPedidoSinArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaPedidoSinArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorNombreSesionCambioTarifaObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorNombreSesionCambioTarifaObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaDestinoObligatoria',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaDestinoObligatoria);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoAtributoVariacionObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoAtributoVariacionObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDistribuidorTallasNoRegistrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDistribuidorTallasNoRegistrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPersistenciaTallasNoRegistrada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPersistenciaTallasNoRegistrada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticulosVariacionesNoRegistradas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticulosVariacionesNoRegistradas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPersistenciaFotosNoRegistrada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPersistenciaFotosNoRegistrada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValidadorArticulosNoInyectado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValidadorArticulosNoInyectado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLookupAtributosNoInyectado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLookupAtributosNoInyectado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInvarianteUnidadesTallas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInvarianteUnidadesTallas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAlmacenDistribucionTallasNoDisponible',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAlmacenDistribucionTallasNoDisponible);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSkuNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSkuNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoArticuloSinAtributos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoArticuloSinAtributos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFactoriaTallasHorizontalObligatoria',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFactoriaTallasHorizontalObligatoria);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloDocumentoTrabajoNoActivo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloDocumentoTrabajoNoActivo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloDocumentoTrabajoVariosSkus',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloDocumentoTrabajoVariosSkus);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEntradaArticuloVacia',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEntradaArticuloVacia);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoBarrasNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoBarrasNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloEntradaNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloEntradaNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoArticuloRequiereSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoArticuloRequiereSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloVariacionSinSkusActivos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloVariacionSinSkusActivos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSinSkusActivos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSinSkusActivos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuNoPerteneceArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuNoPerteneceArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaArticuloSesionNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaArticuloSesionNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoArticuloResolverObligatorio',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoArticuloResolverObligatorio);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloResolverNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloResolverNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoArticuloResolverRequiereSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoArticuloResolverRequiereSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoArticuloInactivoSesion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoArticuloInactivoSesion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoBarrasNoNumerico',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoBarrasNoNumerico);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorImportarImagenCodec',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorImportarImagenCodec);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGuardarFotoSinCodigoArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGuardarFotoSinCodigoArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFicheroOrigenFotoNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFicheroOrigenFotoNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDirectorioFotosNoConfigurado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDirectorioFotosNoConfigurado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoNoRegistradaParaRotar',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoNoRegistradaParaRotar);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoSesionSinSerie',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoSesionSinSerie);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoSesionSinNumero',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoSesionSinNumero);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoSesionLineaInvalida',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoSesionLineaInvalida);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroUrlFotosNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroUrlFotosNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroTokenFotosNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroTokenFotosNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroReferenciaFotosNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroReferenciaFotosNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroCarpetaFotosNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroCarpetaFotosNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorParametrosFotosNubeFaltantes',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorParametrosFotosNubeFaltantes);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorServidorFotosNubeHttp',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorServidorFotosNubeHttp);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorConexionServidorFotosNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorConexionServidorFotosNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValoresAtributoNoDefinidos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValoresAtributoNoDefinidos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSinSistemaTallasPivote',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSinSistemaTallasPivote);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuFueraSistemaTallasPivote',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuFueraSistemaTallasPivote);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEliminarLineaTallasVenta',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEliminarLineaTallasVenta);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSkuNoEncontradoSinDetalle',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSkuNoEncontradoSinDetalle);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEliminarLineaSkuCantidadCero',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEliminarLineaSkuCantidadCero);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoSistemaTallasSuperaMaximo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoSistemaTallasSuperaMaximo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroUrlInventarioNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroUrlInventarioNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroTokenInventarioNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroTokenInventarioNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoParametroReferenciaInventarioNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoParametroReferenciaInventarioNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorParametrosInventarioNubeFaltantes',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorParametrosInventarioNubeFaltantes);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorServidorInventarioNubeHttp',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorServidorInventarioNubeHttp);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorConexionServidorInventarioNube',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorConexionServidorInventarioNube);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNubeSinIdRecuento',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNubeSinIdRecuento);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloCursoSinSistemaTallas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloCursoSinSistemaTallas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAltaSeleccionarArticuloConTallas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAltaSeleccionarArticuloConTallas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGrabarAlbaranVentaSinSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGrabarAlbaranVentaSinSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorProveedorNoSeleccionadoBuscarArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorProveedorNoSeleccionadoBuscarArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoElegirColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoElegirColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSinColoresBasicosActivos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSinColoresBasicosActivos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSinTipoVariacion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSinTipoVariacion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPrecioTarifaNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPrecioTarifaNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPrecioTarifaNoGuardado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPrecioTarifaNoGuardado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoRevisionArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoRevisionArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGuardarPropiedadesArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGuardarPropiedadesArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGuardarVariacionesArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGuardarVariacionesArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaReconstruirStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaReconstruirStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloReconstruirStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloReconstruirStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorReconstruirStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorReconstruirStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoStockReconstruido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoStockReconstruido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoImprimirEtiquetas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoImprimirEtiquetas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoGenerarCodigos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoGenerarCodigos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloSinSkusActivosGenerarCodigos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloSinSkusActivosGenerarCodigos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGenerarCodigosBarras',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGenerarCodigosBarras);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoGeneracionCodigosBarras',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoGeneracionCodigosBarras);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoVerificarCodigos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoVerificarCodigos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDetalleCodigoBarrasInvalido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDetalleCodigoBarrasInvalido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoVerificacionCodigosBarrasCorrecta',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoVerificacionCodigosBarrasCorrecta);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoVerificacionCodigosBarras',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoVerificacionCodigosBarras);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoPrecargaArticuloGuardada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoPrecargaArticuloGuardada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoAtributoBasicoSinValor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoAtributoBasicoSinValor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCrearAtributoBasicoSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCrearAtributoBasicoSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloCrearAtributoBasico',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloCrearAtributoBasico);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuColorNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuColorNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoActivarSkusColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoActivarSkusColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoDesactivarSkusColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoDesactivarSkusColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCambiarActivoSkusColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCambiarActivoSkusColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoSkusColorActivados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoSkusColorActivados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoSkusColorDesactivados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoSkusColorDesactivados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoSkusColorActualizados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoSkusColorActualizados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaSesionAsignarFamiliaNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaSesionAsignarFamiliaNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorContadorInventarioDocumentoTrabajo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorContadorInventarioDocumentoTrabajo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoInventarioDocumentoTrabajoCreado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoInventarioDocumentoTrabajoCreado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoCambioTarifasDocumentoTrabajoCreado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoCambioTarifasDocumentoTrabajoCreado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFilaDevolucionStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFilaDevolucionStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloDevolucionFilaNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloDevolucionFilaNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorStockDevolucionFilaNoDisponible',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorStockDevolucionFilaNoDisponible);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaPrepararStockFilaDevolucion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaPrepararStockFilaDevolucion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoStockFilaDevolucionPreparado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoStockFilaDevolucionPreparado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusDevolucion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoBuscarSkusDevolucion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoArticuloNoActivoDescargar',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoArticuloNoActivoDescargar);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoArticuloNoActivo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoArticuloNoActivo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGuardarFotoArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGuardarFotoArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFotoSkuNoActivo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFotoSkuNoActivo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorNivelAtributosFotoNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorNivelAtributosFotoNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEliminarFotoActual',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEliminarFotoActual);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaSeleccionadaNoEncontrada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaSeleccionadaNoEncontrada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloInventarioNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloInventarioNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineasInventarioNoAbiertas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineasInventarioNoAbiertas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaInventarioNoEditable',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaInventarioNoEditable);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloInventarioNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloInventarioNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloInventarioTipoSinStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloInventarioTipoSinStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloInventarioAtributosSinSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloInventarioAtributosSinSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoLineasCsvInventarioLeidas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoLineasCsvInventarioLeidas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorMigracionRecuentoInventariosNoAplicada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorMigracionRecuentoInventariosNoAplicada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGrabarCabeceraInventarioAutomaticamente',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGrabarCabeceraInventarioAutomaticamente);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGrabarCabeceraInventarioAutomaticamenteDetalle',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGrabarCabeceraInventarioAutomaticamenteDetalle);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNoAbiertoEditar',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNoAbiertoEditar);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaRecalcularInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaRecalcularInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoRecalculoInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoRecalculoInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaAplicarInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaAplicarInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAplicarInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAplicarInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAplicacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAplicacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorRefrescarInventarioAplicado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorRefrescarInventarioAplicado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoInventarioAplicado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoInventarioAplicado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNoSeleccionadoAnadirLineas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNoSeleccionadoAnadirLineas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAnadirLineasInventarioEstado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAnadirLineasInventarioEstado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaInventarioNoSeleccionadaParaSkus',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaInventarioNoSeleccionadaParaSkus);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorLineaInventarioSinArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorLineaInventarioSinArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAnadirSkusInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAnadirSkusInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoSinSkusAnadidosInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoSinSkusAnadidosInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoSkusAnadidosInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoSkusAnadidosInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEliminarLineaInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEliminarLineaInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEliminarRegularizacionInventarioEstado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEliminarRegularizacionInventarioEstado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEliminarRegularizacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEliminarRegularizacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoRegularizacionInventarioEliminada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoRegularizacionInventarioEliminada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNoActivo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNoActivo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioDebeEstarAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioDebeEstarAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFamiliaInventarioNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFamiliaInventarioNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCargarFamiliaInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCargarFamiliaInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorProveedorInventarioNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorProveedorInventarioNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCargarProveedorInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCargarProveedorInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCompletarInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCompletarInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCargarTodoInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCargarTodoInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNoSeleccionado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNoSeleccionado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGuardarInventarioEnEdicion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGuardarInventarioEnEdicion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaRecalcularTrasCargarBloqueInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaRecalcularTrasCargarBloqueInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArchivoImportacionInventarioNoExiste',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArchivoImportacionInventarioNoExiste);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorImportacionInventarioSinDatos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorImportacionInventarioSinDatos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloIncidenciasImportacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloIncidenciasImportacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STextoIncidenciasImportacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STextoIncidenciasImportacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SFormatoIncidenciaCantidadImportacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SFormatoIncidenciaCantidadImportacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SFormatoIncidenciaPmpNuevoImportacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SFormatoIncidenciaPmpNuevoImportacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoImportacionInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoImportacionInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEnviarRecuentoInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEnviarRecuentoInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaEnviarRecuentoInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaEnviarRecuentoInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoInventarioEnviadoRecuento',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoInventarioEnviadoRecuento);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEnviarRecuentoInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEnviarRecuentoInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInventarioNoEnviadoRecuento',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInventarioNoEnviadoRecuento);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorRecogerRecuentoInventarioNoAbierto',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorRecogerRecuentoInventarioNoAbierto);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoRecuentoInventarioRecogido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoRecuentoInventarioRecogido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorRecogerRecuentoInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorRecogerRecuentoInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SAvisoLimiteRegistrosMovimientosAlmacen',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SAvisoLimiteRegistrosMovimientosAlmacen);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGrabarPedidoVentaSinSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGrabarPedidoVentaSinSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCrearAlbaranPedidoVentaSinSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCrearAlbaranPedidoVentaSinSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCodigoBarrasStockNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCodigoBarrasStockNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEntradaStockNoEncontrada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEntradaStockNoEncontrada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSkuCeldaStockNoEncontrado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSkuCeldaStockNoEncontrado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCeldaStockVariosSkus',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCeldaStockVariosSkus);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloStockNoSeleccionadoOperaciones',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloStockNoSeleccionadoOperaciones);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCeldaTallaStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCeldaTallaStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorColumnaTallaStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorColumnaTallaStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFilaStockNoIdentificada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFilaStockNoIdentificada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorColorStockNoUnico',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorColorStockNoUnico);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTallaStockVariosSkus',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTallaStockVariosSkus);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloStockNoSeleccionadoDocumento',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloStockNoSeleccionadoDocumento);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorEstadoStockNoEsExistencias',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorEstadoStockNoEsExistencias);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCeldaStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCeldaStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCeldaCantidadStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCeldaCantidadStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorFilaExistenciasStockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorFilaExistenciasStockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorColumnaStockDocumentoNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorColumnaStockDocumentoNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGrupoFilaStockNoLeido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGrupoFilaStockNoLeido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAlmacenStockNoUnico',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAlmacenStockNoUnico);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorColorStockUnidadNoUnico',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorColorStockUnidadNoUnico);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloConsultaStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloConsultaStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloStockNoSeleccionadoFotos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloStockNoSeleccionadoFotos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoArticulosRelacionadosStockNoDisponibles',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoArticulosRelacionadosStockNoDisponibles);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGuardarTarifaAntesContinuar',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGuardarTarifaAntesContinuar);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorSesionTarifaNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorSesionTarifaNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoLineasSesionTarifaRecalculadas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoLineasSesionTarifaRecalculadas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCalcularSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCalcularSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaAplicarSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaAplicarSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAplicarSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAplicarSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoLineasSesionTarifaAplicadas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoLineasSesionTarifaAplicadas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAlmacenesSoloStockAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAlmacenesSoloStockAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAlmacenesVentasAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAlmacenesVentasAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoArticulosYaCargadosAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoArticulosYaCargadosAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoArticulosAnadidosAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoArticulosAnadidosAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDestinoInventarioAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDestinoInventarioAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaConfirmarInventarioAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaConfirmarInventarioAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoLineasInventarioAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoLineasInventarioAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInsertarLineasInventarioAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInsertarLineasInventarioAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaDestinoAddBlockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaDestinoAddBlockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaOrigenAddBlockNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaOrigenAddBlockNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifasAddBlockCoincidentes',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifasAddBlockCoincidentes);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorMultiploAjusteAddBlockNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorMultiploAjusteAddBlockNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaConfirmarTarifaAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaConfirmarTarifaAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoArticulosTarifaAddBlockAnadidos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoArticulosTarifaAddBlockAnadidos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorInsertarTarifaAddBlock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorInsertarTarifaAddBlock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaQuitarPropiedadArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaQuitarPropiedadArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoGuardadoValoresColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoGuardadoValoresColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorArticuloNoGuardadoAnadirPropiedades',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorArticuloNoGuardadoAnadirPropiedades);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPropiedadObligatoriaFamilia',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPropiedadObligatoriaFamilia);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorPrecioCosteMargenNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorPrecioCosteMargenNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorMargenNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorMargenNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorAjusteMargenNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorAjusteMargenNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorGuardarCambiosMargen',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorGuardarCambiosMargen);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorProveedorPrincipalCosteNoAsignado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorProveedorPrincipalCosteNoAsignado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaConfirmarCargaSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaConfirmarCargaSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoArticulosCargadosSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoArticulosCargadosSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorCargarSesionTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorCargarSesionTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorTarifaEtiquetasNoSeleccionada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorTarifaEtiquetasNoSeleccionada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoLayoutEtiquetasGuardado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoLayoutEtiquetasGuardado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaSuperarLimiteCargaArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaSuperarLimiteCargaArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorDimensionesSkuNoDefinidas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorDimensionesSkuNoDefinidas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValoresSkuNoSeleccionados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValoresSkuNoSeleccionados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorValoresDimensionesSkuIncompletos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorValoresDimensionesSkuIncompletos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SInfoCombinacionesSkuGeneradas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SInfoCombinacionesSkuGeneradas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloAnadirValorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloAnadirValorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SSolicitudNombreValorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SSolicitudNombreValorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SSolicitudOrdenNuevoValorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SSolicitudOrdenNuevoValorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaGuardarValorSkuGlobal',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaGuardarValorSkuGlobal);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaUsarValorSkuTemporal',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaUsarValorSkuTemporal);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloCambiarOrdenValorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloCambiarOrdenValorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SSolicitudOrdenValorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SSolicitudOrdenValorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorOrdenValorSkuNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorOrdenValorSkuNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SPreguntaCambiarOrdenValorSkuGlobal',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SPreguntaCambiarOrdenValorSkuGlobal);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloCambiarOrdenAtributoSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloCambiarOrdenAtributoSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SSolicitudOrdenAtributoSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SSolicitudOrdenAtributoSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SErrorOrdenAtributoSkuNoValido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SErrorOrdenAtributoSkuNoValido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloSeleccionTarifasArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloSeleccionTarifasArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionAnadirPropiedad',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionAnadirPropiedad);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionTipoVariacion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionTipoVariacion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionNombreOrden',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionNombreOrden);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionControlesExpandido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionControlesExpandido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionControlesContraido',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionControlesContraido);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotoDelSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotoDelSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotoHeredadaGrupo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotoHeredadaGrupo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotoHeredadaArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotoHeredadaArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSinFotoPara',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSinFotoPara);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionTabDetalleInventarioSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionTabDetalleInventarioSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionTabDetalleInventarioDesglose',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionTabDetalleInventarioDesglose);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionAtributoN',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionAtributoN);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionModoSimplificado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionModoSimplificado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionModoDesglosado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionModoDesglosado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SHintCoincidenciasPara',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SHintCoincidenciasPara);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SHintArticuloAnterior',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SHintArticuloAnterior);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SHintArticuloSiguiente',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SHintArticuloSiguiente);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotosMismaFamilia',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotosMismaFamilia);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotosMismoProveedor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotosMismoProveedor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionFotosMismaTemporada',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionFotosMismaTemporada);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColoresTallas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColoresTallas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColAlmacen',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColAlmacen);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColEstado',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColEstado);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColTotal',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColTotal);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSesionesCambiosTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSesionesCambiosTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionRedondearHaciaArriba',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionRedondearHaciaArriba);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCargarArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCargarArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCalcularLineas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCalcularLineas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionAplicarTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionAplicarTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionRefrescar',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionRefrescar);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionTabLineasTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionTabLineasTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCeroArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCeroArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionNumSeleccionados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionNumSeleccionados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSinAlmacenesSeleccionados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSinAlmacenesSeleccionados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionAlmacenesSeleccionados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionAlmacenesSeleccionados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionArticulosCoincidenFiltro',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionArticulosCoincidenFiltro);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionInventarioDestino',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionInventarioDestino);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloAnadirBloqueInventario',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloAnadirBloqueInventario);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloAnadirBloqueTarifa',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloAnadirBloqueTarifa);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SHintQuitarPropiedad',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SHintQuitarPropiedad);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionPorColorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionPorColorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionPorColor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionPorColor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SHintFijarPropiedadPorColorSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SHintFijarPropiedadPorColorSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSinColoresSkuDefinidos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSinColoresSkuDefinidos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'STituloCargarArticulosSesionTarifas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      STituloCargarArticulosSesionTarifas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionDistribucionKit',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionDistribucionKit);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColKit',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColKit);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionDocumentoEtiqueta',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionDocumentoEtiqueta);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCalcularNumero',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCalcularNumero);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSeCargaranArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSeCargaranArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionDemasiadosArticulosFiltro',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionDemasiadosArticulosFiltro);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionGrupoModo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionGrupoModo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionModoEntreFechas',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionModoEntreFechas);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionModoPorAcumulados',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionModoPorAcumulados);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionGrupoDetalle',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionGrupoDetalle);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionTipoVariacionDetalle',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionTipoVariacionDetalle);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColSkuArtColorTalla',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColSkuArtColorTalla);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColArticulo',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColArticulo);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColArticuloSku',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColArticuloSku);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColTipoCantidad',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColTipoCantidad);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColCantidad',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColCantidad);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColTallaN',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColTallaN);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColDescripcion',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColDescripcion);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColCodigoBarras',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColCodigoBarras);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColRefProveedor',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColRefProveedor);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionColStock',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionColStock);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionSinArticulos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionSinArticulos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCargandoMovimientos',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCargandoMovimientos);
  ARegistrar(
    'inLibMsgArticulos.' +
    'SCaptionCargandoMovimientosProgreso',
    'src/Lib/inLibMsgArticulos.pas',
    @inLibMsgArticulos.
      SCaptionCargandoMovimientosProgreso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorParametrosCajaSinContratoEdicion',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorParametrosCajaSinContratoEdicion);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorOperacionCajaNoEncontrada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorOperacionCajaNoEncontrada);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloOperacionesCajaStock',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloOperacionesCajaStock);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorConexionOperacionesCajaSkuNoDisponible',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorConexionOperacionesCajaSkuNoDisponible);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCodigoFormaPagoCajaObligatorio',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCodigoFormaPagoCajaObligatorio);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorDescripcionFormaPagoCajaObligatoria',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorDescripcionFormaPagoCajaObligatoria);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorParametrosAplicacionCajaNoConfigurados',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorParametrosAplicacionCajaNoConfigurados);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorParametrosModuloCajaNoConfigurados',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorParametrosModuloCajaNoConfigurados);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorContextoSesionCajaNoConfigurado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorContextoSesionCajaNoConfigurado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorOperacionCajaSinLineas',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorOperacionCajaSinLineas);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCambioIvaSoloArticuloInmaterial',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCambioIvaSoloArticuloInmaterial);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorRazonSocialClienteFacturaCajaObligatoria',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorRazonSocialClienteFacturaCajaObligatoria);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorDocumentoFiscalClienteCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorDocumentoFiscalClienteCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorDocumentoFiscalEmpresaCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorDocumentoFiscalEmpresaCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCuadreCobroParcialCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCuadreCobroParcialCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorFacturaRectificativaCajaSinOriginal',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorFacturaRectificativaCajaSinOriginal);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorGuardarTicketCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorGuardarTicketCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCuadrarFacturaCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCuadrarFacturaCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorRedimirValeCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorRedimirValeCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorContextoSesionTraspasoNoConfigurado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorContextoSesionTraspasoNoConfigurado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSkuTraspasoIncompleto',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSkuTraspasoIncompleto);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSkuTraspasoNoDisponible',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSkuTraspasoNoDisponible);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArticuloSkuTraspasoNoCoincide',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArticuloSkuTraspasoNoCoincide);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorStockTraspasoInsuficiente',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorStockTraspasoInsuficiente);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorLineasTraspasoNoDisponibles',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorLineasTraspasoNoDisponibles);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorAlmacenDestinoTraspasoNoSeleccionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorAlmacenDestinoTraspasoNoSeleccionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorAlmacenesTraspasoCoincidentes',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorAlmacenesTraspasoCoincidentes);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorLineasSolicitudTraspasoNoDisponibles',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorLineasSolicitudTraspasoNoDisponibles);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorAlmacenOrigenSolicitudNoSeleccionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorAlmacenOrigenSolicitudNoSeleccionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudTraspasoMismoAlmacen',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudTraspasoMismoAlmacen);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudTraspasoNoCargada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudTraspasoNoCargada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorLineaSolicitudTraspasoNoActualizada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorLineaSolicitudTraspasoNoActualizada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorImpresoraTicketsCajaNoConfigurada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorImpresoraTicketsCajaNoConfigurada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorContextoImpresoraCajaNoProporcionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorContextoImpresoraCajaNoProporcionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorReferenciaPagoCajaNoIndicada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorReferenciaPagoCajaNoIndicada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorFactorCambioCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorFactorCambioCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorHashBlockchainCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorHashBlockchainCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorValeCajaNoSeleccionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorValeCajaNoSeleccionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorPinValeCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorPinValeCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorPinValeCajaIncorrecto',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorPinValeCajaIncorrecto);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorProveedorParametrosCajaNoConfigurado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorProveedorParametrosCajaNoConfigurado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorParametrosCajaEditablesNoConfigurados',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorParametrosCajaEditablesNoConfigurados);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoLayoutCajaGuardado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoLayoutCajaGuardado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoParametrosCajaGuardados',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoParametrosCajaGuardados);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoParametrosCajaSinCambios',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoParametrosCajaSinCambios);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaSalirParametrosCajaSinGuardar',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaSalirParametrosCajaSinGuardar);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoUsuariosParametrosCajaNoEncontrados',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoUsuariosParametrosCajaNoEncontrados);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloCambiarUsuarioParametrosCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloCambiarUsuarioParametrosCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SSolicitudCambiarUsuarioParametrosCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SSolicitudCambiarUsuarioParametrosCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorUsuarioParametrosCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorUsuarioParametrosCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoPrecargaCajaGuardada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoPrecargaCajaGuardada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorAsignarUbicacionCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorAsignarUbicacionCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloHoraCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloHoraCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SSolicitudHoraCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SSolicitudHoraCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorHoraCajaNoValida',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorHoraCajaNoValida);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorUbicacionCajaBuscarOperacionesNoAsignada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorUbicacionCajaBuscarOperacionesNoAsignada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorUbicacionCajaArqueoNoAsignada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorUbicacionCajaArqueoNoAsignada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorUbicacionCajaTraspasoNoAsignada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorUbicacionCajaTraspasoNoAsignada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorRectificacionCajaNoAdmiteBorrador',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorRectificacionCajaNoAdmiteBorrador);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorClienteBorradorCajaNoAsignado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorClienteBorradorCajaNoAsignado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorNifClienteBorradorCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorNifClienteBorradorCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorFechaSerieEmisionCajaNoValida',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorFechaSerieEmisionCajaNoValida);
  ARegistrar(
    'inLibMsgCaja.' +
    'SAvisoHuecosNumeracionSerieCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SAvisoHuecosNumeracionSerieCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorNumeroBorradorCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorNumeroBorradorCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorNumeroBorradorCajaExistente',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorNumeroBorradorCajaExistente);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorNumeroBorradorCajaNoEsHueco',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorNumeroBorradorCajaNoEsHueco);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloEnviarDocumentacionCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloEnviarDocumentacionCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SSolicitudCorreoDocumentacionCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SSolicitudCorreoDocumentacionCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCorreoDocumentacionCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCorreoDocumentacionCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCreditoClienteCajaNoPermitido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCreditoClienteCajaNoPermitido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorImporteCreditoCajaNoPendiente',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorImporteCreditoCajaNoPendiente);
  ARegistrar(
    'inLibMsgCaja.' +
    'SAvisoLimiteOperacionesCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SAvisoLimiteOperacionesCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorOperacionCajaExportarNoSeleccionada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorOperacionCajaExportarNoSeleccionada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSkuVentaCajaNoExiste',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSkuVentaCajaNoExiste);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSkuVentaCajaNoActivo',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSkuVentaCajaNoActivo);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArticuloVentaCajaSinStock',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArticuloVentaCajaSinStock);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorVendedorCajaNoAsignado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorVendedorCajaNoAsignado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCodigoBarrasVentaCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCodigoBarrasVentaCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorLineaDepositoCajaNoCancelable',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorLineaDepositoCajaNoCancelable);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArticuloVentaCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArticuloVentaCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaCancelarVentaCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaCancelarVentaCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorLineaDepositoCajaNoEliminable',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorLineaDepositoCajaNoEliminable);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaBorrarVentaCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaBorrarVentaCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoValeCajaEntregar',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoValeCajaEntregar);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCorreoOperacionCajaNoEnviado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCorreoOperacionCajaNoEnviado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTipoRectificativaCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTipoRectificativaCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorBorradorRectificarCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorBorradorRectificarCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorClienteDepositosCajaNoSeleccionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorClienteDepositosCajaNoSeleccionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorValoresAtributoCajaNoDefinidos',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorValoresAtributoCajaNoDefinidos);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaEliminarOperacionCajaPendiente',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaEliminarOperacionCajaPendiente);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArticuloCajaNoEncontradoDescatalogado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArticuloCajaNoEncontradoDescatalogado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCantidadArticuloDepositoCajaNoValida',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCantidadArticuloDepositoCajaNoValida);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCodigoClienteCajaNoExiste',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCodigoClienteCajaNoExiste);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorEmpleadoCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorEmpleadoCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudesTraspasoPendientesNoEncontradas',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudesTraspasoPendientesNoEncontradas);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorCargarSolicitudTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorCargarSolicitudTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudTraspasoCerrarNoCargada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudTraspasoCerrarNoCargada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaCerrarSolicitudTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaCerrarSolicitudTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoSolicitudTraspasoCerrada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoSolicitudTraspasoCerrada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorDenegarSolicitudTraspasoModoNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorDenegarSolicitudTraspasoModoNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudTraspasoDenegarNoCargada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudTraspasoDenegarNoCargada);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloDenegarSolicitudTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloDenegarSolicitudTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SSolicitudMotivoRechazoTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SSolicitudMotivoRechazoTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorMotivoDenegacionTraspasoNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorMotivoDenegacionTraspasoNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoPeticionTraspasoDenegada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoPeticionTraspasoDenegada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoSolicitudTraspasoEnviada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoSolicitudTraspasoEnviada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorEmpleadoTraspasoNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorEmpleadoTraspasoNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorEmpleadoTraspasoNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorEmpleadoTraspasoNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorSolicitudTraspasoAtenderNoCargada',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorSolicitudTraspasoAtenderNoCargada);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorMotivoLineasTraspasoNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorMotivoLineasTraspasoNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoSolicitudTraspasoAtendida',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoSolicitudTraspasoAtendida);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaDenegarPeticionTraspasoCompleta',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaDenegarPeticionTraspasoCompleta);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoTraspasoGrabado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoTraspasoGrabado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorEmpleadoGastoCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorEmpleadoGastoCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorImporteGastoCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorImporteGastoCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloAvisoCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloAvisoCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArqueoCajaNoSeleccionado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArqueoCajaNoSeleccionado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorPermisoResumenArqueoCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorPermisoResumenArqueoCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoOperacionesFacturadasArqueoCajaNoEncontradas',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoOperacionesFacturadasArqueoCajaNoEncontradas);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloTiraCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloTiraCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorVendedorArqueoCajaNoIndicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorVendedorArqueoCajaNoIndicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloVendedorArqueoCajaObligatorio',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloVendedorArqueoCajaObligatorio);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorVendedorArqueoCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorVendedorArqueoCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloVendedorArqueoCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloVendedorArqueoCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorArqueoCajaDuplicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorArqueoCajaDuplicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloArqueoCajaDuplicado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloArqueoCajaDuplicado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorRecuentoArqueoCajaNoDisponible',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorRecuentoArqueoCajaNoDisponible);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorRestanteArqueoCajaNoValido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorRestanteArqueoCajaNoValido);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaGrabarArqueoCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaGrabarArqueoCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloConfirmarArqueoCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloConfirmarArqueoCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SPreguntaImprimirJustificanteCierreCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SPreguntaImprimirJustificanteCierreCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloJustificanteCierreCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloJustificanteCierreCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloOperacionCajaReal',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloOperacionCajaReal);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionUnaOperacion',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionUnaOperacion);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionNumOperaciones',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionNumOperaciones);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionPendienteDevolver',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionPendienteDevolver);
  ARegistrar(
    'inLibMsgCaja.' +
    'SHintSinDescuentoGlobalDeposito',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SHintSinDescuentoGlobalDeposito);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionPendienteCobro',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionPendienteCobro);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionEmpresaAlmacenCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionEmpresaAlmacenCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloOperacionNCajaReal',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloOperacionNCajaReal);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloTraspasosAlmacenCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloTraspasosAlmacenCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionVentaContado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionVentaContado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionTotalCero',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionTotalCero);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionTotalImporte',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionTotalImporte);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionRectificativaTipo',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionRectificativaTipo);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloBusquedaEmpleadosCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloBusquedaEmpleadosCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionCargandoOperaciones',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionCargandoOperaciones);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionCargandoOperacionesProgreso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionCargandoOperacionesProgreso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionIrABorrador',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionIrABorrador);
  ARegistrar(
    'inLibMsgCaja.' +
    'SHintIrABorrador',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SHintIrABorrador);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionTabBorrador',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionTabBorrador);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionEquivalenciaEurDivisa',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionEquivalenciaEurDivisa);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionEquivalenciaDivisaEur',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionEquivalenciaDivisaEur);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColCodigoVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColCodigoVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColEstadoVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColEstadoVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColImporteVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColImporteVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColFechaEmisionVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColFechaEmisionVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColCaducidadVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColCaducidadVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColObservacionesVale',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColObservacionesVale);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColDescripcionTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColDescripcionTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColUdsTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColUdsTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColCosteTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColCosteTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColStockOrigenTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColStockOrigenTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColPedidasTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColPedidasTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColMotivoRechazoTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColMotivoRechazoTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColSirvoTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColSirvoTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionAlmacenOrigen',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionAlmacenOrigen);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionAlmacenDestino',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionAlmacenDestino);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionF12ConTicket',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionF12ConTicket);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionF12EnviarSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionF12EnviarSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionF12ServirConTicket',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionF12ServirConTicket);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionImporteTraspaso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionImporteTraspaso);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloSolicitudesPendientesAtender',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloSolicitudesPendientesAtender);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColNumeroSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColNumeroSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColSerieSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColSerieSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColFechaSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColFechaSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColPideAlmacen',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColPideAlmacen);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColEstadoSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColEstadoSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionColLineasSolicitud',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionColLineasSolicitud);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionAtender',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionAtender);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionNoAtender',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionNoAtender);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionImprimir',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionImprimir);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionEmpleadoNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionEmpleadoNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionSinStock',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionSinStock);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionImporteEur',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionImporteEur);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionDesgloseEfectivo',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionDesgloseEfectivo);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloHistoricoArqueosCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloHistoricoArqueosCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionRetirarSobranteRecuento',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionRetirarSobranteRecuento);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionTpvRestringido',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionTpvRestringido);
  ARegistrar(
    'inLibMsgCaja.' +
    'STituloTiraCajaNumero',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      STituloTiraCajaNumero);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionTodasLasSeries',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionTodasLasSeries);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionImprimirQrNoDisponible',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionImprimirQrNoDisponible);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorMotivoDevolucionCajaObligatorio',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorMotivoDevolucionCajaObligatorio);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTicketDevolucionCajaNoEncontrado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTicketDevolucionCajaNoEncontrado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTicketDevolucionCajaEsRectificativa',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTicketDevolucionCajaEsRectificativa);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTicketDevolucionCajaDatosOperacion',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTicketDevolucionCajaDatosOperacion);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTicketDevolucionCajaDatosDocumento',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTicketDevolucionCajaDatosDocumento);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorTicketDevolucionCajaSinSeleccion',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorTicketDevolucionCajaSinSeleccion);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoTicketDevolucionCajaLocalizado',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoTicketDevolucionCajaLocalizado);
  ARegistrar(
    'inLibMsgCaja.' +
    'SInfoVentasOrigenSkuCaja',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SInfoVentasOrigenSkuCaja);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorVentaOrigenCajaSinSeleccion',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorVentaOrigenCajaSinSeleccion);
  ARegistrar(
    'inLibMsgCaja.' +
    'SErrorDevolucionTicketOperacionEnCurso',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SErrorDevolucionTicketOperacionEnCurso);
  ARegistrar(
    'inLibMsgCaja.' +
    'SAvisoDevolucionTicketOtraEmpresa',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SAvisoDevolucionTicketOtraEmpresa);
  ARegistrar(
    'inLibMsgCaja.' +
    'SCaptionDevolucionTicketDe',
    'src/Lib/inLibMsgCaja.pas',
    @inLibMsgCaja.
      SCaptionDevolucionTicketDe);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPersistenciaGridPivoteCompraNoRegistrada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPersistenciaGridPivoteCompraNoRegistrada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoAlmacenDestinoAlbaranCompraObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoAlmacenDestinoAlbaranCompraObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoAlbaranCompraFacturado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoAlbaranCompraFacturado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCambiarFormatoSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCambiarFormatoSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEmpresaSesionObligatoria',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEmpresaSesionObligatoria);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSerieSesionObligatoria',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSerieSesionObligatoria);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCodigoSerieEmpresa',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCodigoSerieEmpresa);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenSalidaDevolucionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenSalidaDevolucionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoDevolucionCompraFacturada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoDevolucionCompraFacturada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarDevolucionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarDevolucionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCabeceraDevolucionCompraSinGrabar',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCabeceraDevolucionCompraSinGrabar);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorDevolucionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorDevolucionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorBorrarEfectoCompraRemesado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorBorrarEfectoCompraRemesado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorBorrarEfectoCompraPagado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorBorrarEfectoCompraPagado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFusionarEfectosCompraEstado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFusionarEfectosCompraEstado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFusionarEfectosCompraOrigen',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFusionarEfectosCompraOrigen);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFusionarEfectosCompraSinPendiente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFusionarEfectosCompraSinPendiente);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCerrarFacturaCompraSinLineas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCerrarFacturaCompraSinLineas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorBorrarFacturaCompraEfectosPagados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorBorrarFacturaCompraEfectosPagados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCabeceraFacturaCompraSinGrabar',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCabeceraFacturaCompraSinGrabar);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoAlmacenDestinoPedidoCompraObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoAlmacenDestinoPedidoCompraObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorKitsNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorKitsNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorKitsSinGrabar',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorKitsSinGrabar);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCodigoKitProveedorObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCodigoKitProveedorObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorNombreKitProveedorObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorNombreKitProveedorObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitProveedorNoSeleccionadoParaTallas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitProveedorNoSeleccionadoParaTallas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorTallaDestinoKitProveedorObligatoria',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorTallaDestinoKitProveedorObligatoria);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitProveedorNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitProveedorNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSistemaTallasKitProveedorObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSistemaTallasKitProveedorObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCodigoAutomaticoProveedor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCodigoAutomaticoProveedor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorOrdenAutomaticoProveedor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorOrdenAutomaticoProveedor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPrefijoEanSesionLargo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPrefijoEanSesionLargo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColorBasicoMaterializacionNoExiste',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColorBasicoMaterializacionNoExiste);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenSesionParaAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenSesionParaAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenSesionParaPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenSesionParaPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenSesionParaPendienteRecibir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenSesionParaPendienteRecibir);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoSelectorConjuntoFilaNoImplementado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoSelectorConjuntoFilaNoImplementado);
  ARegistrar(
    'inLibMsgCompras.' +
    'STituloNuevaFilaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STituloNuevaFilaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SSolicitudNombreFilaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SSolicitudNombreFilaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoConjuntoPivotCompraObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoConjuntoPivotCompraObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorConjuntoPivotCompraNoExiste',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorConjuntoPivotCompraNoExiste);
  ARegistrar(
    'inLibMsgCompras.' +
    'STituloAnadirValorPivotCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STituloAnadirValorPivotCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SSolicitudNombreValorPivotCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SSolicitudNombreValorPivotCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SSolicitudOrdenValorPivotCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SSolicitudOrdenValorPivotCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraMovimientosNoEncontrado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraMovimientosNoEncontrado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraMovimientosYaGenerados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraMovimientosYaGenerados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraSinCantidadParaMovimientos',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraSinCantidadParaMovimientos);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorMovimientosAlbaranCompraNoRegistrados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorMovimientosAlbaranCompraNoRegistrados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidosCompraNoRegistrados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidosCompraNoRegistrados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorMovimientosDevolucionCompraNoRegistrados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorMovimientosDevolucionCompraNoRegistrados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraMovimientosNoEncontrada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraMovimientosNoEncontrada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraMovimientosYaGenerados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraMovimientosYaGenerados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraSinCantidadParaMovimientos',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraSinCantidadParaMovimientos);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionCompraNoActiva',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionCompraNoActiva);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionSinNumero',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionSinNumero);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSistemaTallasLineaSesionObligatorio',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSistemaTallasLineaSesionObligatorio);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitProveedorNoExiste',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitProveedorNoExiste);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitSinSistemaTallas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitSinSistemaTallas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorTallajeKitNoCoincide',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorTallajeKitNoCoincide);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorGestorTallasNoInicializado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorGestorTallasNoInicializado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitSinTallasDefinidas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitSinTallasDefinidas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoTallasKitSinCorrespondencia',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoTallasKitSinCorrespondencia);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorTallasKitSinCorrespondencia',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorTallasKitSinCorrespondencia);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionIncidenciasSinDetalle',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionIncidenciasSinDetalle);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDataModuleSesionNoInicializado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDataModuleSesionNoInicializado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionNoCerradaParaRevertir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionNoCerradaParaRevertir);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoLineaIncidenciaSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoLineaIncidenciaSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoCabeceraIncidenciaSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoCabeceraIncidenciaSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SFormatoIncidenciaSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SFormatoIncidenciaSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionInactivaIncidencia',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionInactivaIncidencia);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaCabecera',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaCabecera);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEmpresaSesionFaltante',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEmpresaSesionFaltante);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorSesionFaltante',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorSesionFaltante);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenSesionFaltante',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenSesionFaltante);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionSinLineas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionSinLineas);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaDuplicadoInterno',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaDuplicadoInterno);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCodigoDuplicadoInternoSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCodigoDuplicadoInternoSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaDuplicado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaDuplicado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCodigoDuplicadoSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCodigoDuplicadoSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaCodigo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaCodigo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionSinCodigo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionSinCodigo);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaDescripcion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaDescripcion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionSinDescripcion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionSinDescripcion);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaCantidades',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaCantidades);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaMatrizSinCantidades',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaMatrizSinCantidades);
  ARegistrar(
    'inLibMsgCompras.' +
    'STipoIncidenciaSistemaTallas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STipoIncidenciaSistemaTallas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaMatrizSinSistemaTallas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaMatrizSinSistemaTallas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColorCompraNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColorCompraNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorConexionResolverColorCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorConexionResolverColorCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColorBasicoCompraNoExiste',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColorBasicoCompraNoExiste);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorResolverColorCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorResolverColorCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSistemaTallasSuperaMaximoPivote',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSistemaTallasSuperaMaximoPivote);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorActivarPivoteTallas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorActivarPivoteTallas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorActivarTallasHorizontalesParaColor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorActivarTallasHorizontalesParaColor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaActivaColorNoDisponible',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaActivaColorNoDisponible);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColorCompraConCantidades',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColorCompraConCantidades);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorConsultaLineasCompraNoAbierta',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorConsultaLineasCompraNoAbierta);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaActivaColorNoEncontrada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaActivaColorNoEncontrada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaActivaCompraSinArticulo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaActivaCompraSinArticulo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraSinPendientesAlmacen',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraSinPendientesAlmacen);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenPedidoCompraNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenPedidoCompraNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraSinCantidadesRecibir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraSinCantidadesRecibir);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorContadorAlbaranCompraNoDisponible',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorContadorAlbaranCompraNoDisponible);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCrearLineasAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCrearLineasAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoAlbaranCompraCreado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoAlbaranCompraCreado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraDestinoNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraDestinoNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoLineasIncorporadasAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoLineasIncorporadasAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorIncorporarLineasAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorIncorporarLineasAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoLineasIncorporadasAlbaranCompraConCantidad',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoLineasIncorporadasAlbaranCompraConCantidad);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloSinSistemaTallasCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloSinSistemaTallasCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorActivarTallasHorizontalesCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorActivarTallasHorizontalesCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraNoAbierto',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraNoAbierto);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraNoInicializado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraNoInicializado);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaAbrirSeriesAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaAbrirSeriesAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraSinImpresionActivo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraSinImpresionActivo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraNoActivo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraNoActivo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaGrabarAlbaranCompraSinSku',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaGrabarAlbaranCompraSinSku);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraNecesarioElegirEmpresa',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraNecesarioElegirEmpresa);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlbaranCompraNecesarioElegirProveedor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlbaranCompraNecesarioElegirProveedor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoAlbaranCompraSinPedido',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoAlbaranCompraSinPedido);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoAlbaranCompraSinFactura',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoAlbaranCompraSinFactura);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaEliminarLineaAlbaranCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaEliminarLineaAlbaranCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarPropiedadPlantillaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarPropiedadPlantillaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarKitPlantillaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarKitPlantillaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCabeceraSesionAntesLineas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCabeceraSesionAntesLineas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionSinDocumentosCreados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionSinDocumentosCreados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorMantenimientoTipoDocumentoNoDisponible',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorMantenimientoTipoDocumentoNoDisponible);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaAbrirSeriesSesionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaAbrirSeriesSesionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionElegirProveedorNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionElegirProveedorNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorSesionSinKits',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorSesionSinKits);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorKitProveedorDesplegableNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorKitProveedorDesplegableNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarLineaSesionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarLineaSesionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionYaMaterializada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionYaMaterializada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoDuplicadosSesionMarcadosReusar',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoDuplicadosSesionMarcadosReusar);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoSesionMaterializadaSinDocumentos',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoSesionMaterializadaSinDocumentos);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionNoCerradaParaReversion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionNoCerradaParaReversion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorReversionSesionMigracionPendiente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorReversionSesionMigracionPendiente);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorReversionSesionConIncidencias',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorReversionSesionConIncidencias);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionSalidaPosterior',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionSalidaPosterior);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionPedidoRecibido',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionPedidoRecibido);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionTipoDocumento',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionTipoDocumento);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionDocumentoIncompleto',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionDocumentoIncompleto);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionReferenciaSinMapa',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionReferenciaSinMapa);
  ARegistrar(
    'inLibMsgCompras.' +
    'SIncidenciaReversionDocumentoCompartido',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SIncidenciaReversionDocumentoCompartido);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaRevertirSesionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaRevertirSesionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoSesionRevertida',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoSesionRevertida);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorRevertirSesionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorRevertirSesionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSesionActivaImprimirNoDisponible',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSesionActivaImprimirNoDisponible);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorSistemasTallasSesionNoDisponibles',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorSistemasTallasSesionNoDisponibles);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCambiarSistemaTallasModeloExistente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCambiarSistemaTallasModeloExistente);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColoresBasicosSesionNoDisponibles',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColoresBasicosSesionNoDisponibles);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEfectosCompraFusionInsuficientes',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEfectosCompraFusionInsuficientes);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaAbrirSeriesDevolucionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaAbrirSeriesDevolucionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaColorDevolucionNoEncontrada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaColorDevolucionNoEncontrada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraSinImpresionActiva',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraSinImpresionActiva);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraNoActiva',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraNoActiva);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorDevolucionFilaNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorDevolucionFilaNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenDevolucionFilaNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenDevolucionFilaNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorColorDevolucionFilaNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorColorDevolucionFilaNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaGrabarDevolucionCompraSinSku',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaGrabarDevolucionCompraSinSku);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraNoAbierta',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraNoAbierta);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraElegirEmpresaNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraElegirEmpresaNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDevolucionCompraElegirProveedorNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDevolucionCompraElegirProveedorNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaEliminarLineaDevolucionCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaEliminarLineaDevolucionCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaAbrirSeriesFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaAbrirSeriesFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFacturaCompraNoAbierta',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFacturaCompraNoAbierta);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFacturaCompraSinImpresionActiva',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFacturaCompraSinImpresionActiva);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoEtiquetasBorradorCompraPendientes',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoEtiquetasBorradorCompraPendientes);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaGrabarFacturaCompraSinSku',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaGrabarFacturaCompraSinSku);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFacturaCompraNoInicializada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFacturaCompraNoInicializada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFacturaCompraElegirProveedorNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFacturaCompraElegirProveedorNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoGeneracionEfectosPagoCancelada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoGeneracionEfectosPagoCancelada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoEfectosPagoGenerados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoEfectosPagoGenerados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SAvisoEfectosPagoNoGenerados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SAvisoEfectosPagoNoGenerados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorGenerarEfectosPagoSinBorrador',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorGenerarEfectosPagoSinBorrador);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEfectoCompraNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEfectoCompraNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaEliminarLineaFacturaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaEliminarLineaFacturaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNoAbierto',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNoAbierto);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNoInicializado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNoInicializado);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorExpandirRecibidosNoActivo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorExpandirRecibidosNoActivo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoTallasPendientesRecibirNoDisponibles',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoTallasPendientesRecibirNoDisponibles);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoPedidoCompraSinPendientesRecibir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoPedidoCompraSinPendientesRecibir);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaGrabarPedidoCompraSinSku',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaGrabarPedidoCompraSinSku);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNecesarioElegirEmpresa',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNecesarioElegirEmpresa);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNecesarioElegirProveedor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNecesarioElegirProveedor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorTallasHorizontalesNecesariasElegirColor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorTallasHorizontalesNecesariasElegirColor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloNoSeleccionadoElegirColorPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloNoSeleccionadoElegirColorPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorArticuloPedidoCompraSinColoresBasicos',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorArticuloPedidoCompraSinColoresBasicos);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaEliminarLineaPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaEliminarLineaPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaAbrirSeriesPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaAbrirSeriesPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNoActivo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNoActivo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorPedidoCompraNoActivoCrearAlbaran',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorPedidoCompraNoActivoCrearAlbaran);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorCrearAlbaranDesdePedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorCrearAlbaranDesdePedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaBorrarKitProveedor',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaBorrarKitProveedor);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorRemesaCompraNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorRemesaCompraNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEliminarRemesaCompraConCargo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEliminarRemesaCompraConCargo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaEliminarRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaEliminarRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoRemesaCompraEliminada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoRemesaCompraEliminada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEliminarRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEliminarRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAnadirEfectosRemesaCompraConCargo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAnadirEfectosRemesaCompraConCargo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEfectosRemesaCompraNoCargados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEfectosRemesaCompraNoCargados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEfectoRemesaCompraNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEfectoRemesaCompraNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorQuitarEfectosRemesaCompraConCargo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorQuitarEfectosRemesaCompraConCargo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SPreguntaQuitarEfectoRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SPreguntaQuitarEfectoRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoEfectoRemesaCompraQuitado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoEfectoRemesaCompraQuitado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorQuitarEfectoRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorQuitarEfectoRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorEfectoRemesaCompraSinPendiente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorEfectoRemesaCompraSinPendiente);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoEfectoPendienteRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoEfectoPendienteRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoEfectoRemesaCompraConciliado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoEfectoRemesaCompraConciliado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorConciliarEfectoRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorConciliarEfectoRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorRemesaCompraSinImportePendiente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorRemesaCompraSinImportePendiente);
  ARegistrar(
    'inLibMsgCompras.' +
    'STextoRemesaCompraPendiente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      STextoRemesaCompraPendiente);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoEfectosRemesaCompraConciliados',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoEfectosRemesaCompraConciliados);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorConciliarRemesaCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorConciliarRemesaCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorBancoPagoNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorBancoPagoNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorTipoDocumentoSesionNoSeleccionado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorTipoDocumentoSesionNoSeleccionado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAlmacenDestinoSesionNoIndicado',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAlmacenDestinoSesionNoIndicado);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorFacturaCompraExportarNoPreparada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorFacturaCompraExportarNoPreparada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionTabLineasCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionTabLineasCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionTabLineasCompraSinConstruir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionTabLineasCompraSinConstruir);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionSeleccioneLineaSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionSeleccioneLineaSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionLineaFotoDetalle',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionLineaFotoDetalle);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionLineaSinFotoProvisional',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionLineaSinFotoProvisional);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionDestinoArticulo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionDestinoArticulo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionDestinoSku',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionDestinoSku);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionDescargarFotosNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionDescargarFotosNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionSinCodigoArticulo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionSinCodigoArticulo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorDescargarFotosArticulo',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorDescargarFotosArticulo);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoFotosArticuloDescargadas',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoFotosArticuloDescargadas);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorLineaSesionAsignarFotoNoSeleccionada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorLineaSesionAsignarFotoNoSeleccionada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SInfoFotoLineaSesionAsignada',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SInfoFotoLineaSesionAsignada);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorAsignarFotoSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorAsignarFotoSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SErrorGuardarFotoSesion',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SErrorGuardarFotoSesion);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionModeloCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionModeloCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionCodigoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionCodigoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionTabLineasDocCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionTabLineasDocCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionTabLineasDocCompraSinConstruir',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionTabLineasDocCompraSinConstruir);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionContextoTallaPedido',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionContextoTallaPedido);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionAlbaranCreadoPedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionAlbaranCreadoPedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionModeloYaEnLinea',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionModeloYaEnLinea);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionCrearAlbaranDesdePedidoCompra',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionCrearAlbaranDesdePedidoCompra);
  ARegistrar(
    'inLibMsgCompras.' +
    'SCaptionCodigoExistente',
    'src/Lib/inLibMsgCompras.pas',
    @inLibMsgCompras.
      SCaptionCodigoExistente);
  ARegistrar(
    'inLibMsgComun.' +
    'SClassRttiNotFnd',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SClassRttiNotFnd);
  ARegistrar(
    'inLibMsgComun.' +
    'SLocateNotFnd',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SLocateNotFnd);
  ARegistrar(
    'inLibMsgComun.' +
    'SResWinFNotFnd',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SResWinFNotFnd);
  ARegistrar(
    'inLibMsgComun.' +
    'SAdvMsg',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAdvMsg);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContextoSesionFormularioNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContextoSesionFormularioNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorServicioAuditoriaDatosNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorServicioAuditoriaDatosNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoSinComandosESCPOSImpresora',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoSinComandosESCPOSImpresora);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorImprimir',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorImprimir);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoSinComandosESCPOSPDF',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoSinComandosESCPOSPDF);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoPDFGuardado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoPDFGuardado);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoPNGGuardado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoPNGGuardado);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoColacionSesion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoColacionSesion);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoTimeoutServidor',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoTimeoutServidor);
  ARegistrar(
    'inLibMsgComun.' +
    'SDetalleErrorMySQL',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDetalleErrorMySQL);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorAbrirConsultaOpe',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorAbrirConsultaOpe);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaCambioCriticoEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaCambioCriticoEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPorcentajeRetencionEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPorcentajeRetencionEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorRetencionesEmpresaConcurrentes',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorRetencionesEmpresaConcurrentes);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorSerieEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorSerieEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorSerieTokenizadaEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorSerieTokenizadaEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorSerieTokenizadaCalendarioNoNatural',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorSerieTokenizadaCalendarioNoNatural);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorIbanEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorIbanEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorRazonSocialEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorRazonSocialEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCabeceraBorradorSinGrabar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCabeceraBorradorSinGrabar);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorServicioConexionesDatosNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorServicioConexionesDatosNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContextoSesionFiltrosNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContextoSesionFiltrosNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDescripcionFormaPago',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDescripcionFormaPago);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContextoSesionModuloDatosNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContextoSesionModuloDatosNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoIva',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoIva);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorGrupoIvaNoExiste',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorGrupoIvaNoExiste);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorRangoFechasIva',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorRangoFechasIva);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDescripcionGrupoIva',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDescripcionGrupoIva);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoGrupoIva',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoGrupoIva);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDosGruposIvaPredeterminados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDosGruposIvaPredeterminados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContextoSesionPerfilesNoConfigurado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContextoSesionPerfilesNoConfigurado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEmpresaSinAlmacenActivo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEmpresaSinAlmacenActivo);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorAlmacenDepositosEmpresaNoEncontrado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorAlmacenDepositosEmpresaNoEncontrado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoEanMinimo7Digitos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoEanMinimo7Digitos);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoEanMinimo12Digitos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoEanMinimo12Digitos);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEjecutorBusquedasNoRegistrado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEjecutorBusquedasNoRegistrado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorHojaCalculoNoActiva',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorHojaCalculoNoActiva);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorControlHojaCalculoObligatorio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorControlHojaCalculoObligatorio);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorGuardarHojaCalculoControlObligatorio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorGuardarHojaCalculoControlObligatorio);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorIbanInvalido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorIbanInvalido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPaisIbanInvalido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPaisIbanInvalido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDigitoControlIbanInvalido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDigitoControlIbanInvalido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorLongitudCuentaBancariaInvalida',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorLongitudCuentaBancariaInvalida);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCuentaBancariaInvalida',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCuentaBancariaInvalida);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDigitoControlCuentaBancaria',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDigitoControlCuentaBancaria);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPaisIbanInvalidoTipos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPaisIbanInvalidoTipos);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDigitoControlIbanInvalidoTipos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDigitoControlIbanInvalidoTipos);
  ARegistrar(
    'inLibMsgComun.' +
    'STextoResetearLayout',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STextoResetearLayout);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoLayoutReseteado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoLayoutReseteado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorAccesoFicheroLog',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorAccesoFicheroLog);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCrearMutexLog',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCrearMutexLog);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPreviewExcelNoRegistrado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPreviewExcelNoRegistrado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorGenerarContadorAutomatico',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorGenerarContadorAutomatico);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNumeroCuentaInvalido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNumeroCuentaInvalido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNifNoValido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNifNoValido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorLetraDniIncorrecta',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorLetraDniIncorrecta);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCrearSeleccionarDocumentoAntesLineas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCrearSeleccionarDocumentoAntesLineas);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCrearSeleccionarDocumentoAntesTallas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCrearSeleccionarDocumentoAntesTallas);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxLabel',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxLabel);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxTabSheet',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxTabSheet);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxDbCheckBox',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxDbCheckBox);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxButton',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxButton);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxGroupBox',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxGroupBox);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxDbRadioGroup',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxDbRadioGroup);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoSpeedButton',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoSpeedButton);
  ARegistrar(
    'inLibMsgComun.' +
    'SDepuracionComponenteNoTcxRadioButton',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDepuracionComponenteNoTcxRadioButton);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorImagenNoExiste',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorImagenNoExiste);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorColorPaletaBusquedaInvalido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorColorPaletaBusquedaInvalido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorOperacionSinBorrador',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorOperacionSinBorrador);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorBorradorNoCerradoFiscalmente',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorBorradorNoCerradoFiscalmente);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaAnularFiscalmenteBorrador',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaAnularFiscalmenteBorrador);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaRectificarBorrador',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaRectificarBorrador);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorOperacionCorreoNoEncontrada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorOperacionCorreoNoEncontrada);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloEnviarDocumentacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloEnviarDocumentacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SSolicitudCorreoElectronico',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SSolicitudCorreoElectronico);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCorreoElectronicoObligatorio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCorreoElectronicoObligatorio);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEnviarCorreoOperacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEnviarCorreoOperacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEfectoConciliado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEfectoConciliado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorConciliarEfecto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorConciliarEfecto);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEfectoNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEfectoNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCarteraEfectosNoAbierta',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCarteraEfectosNoAbierta);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaFusionarEfectos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaFusionarEfectos);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEfectosConciliados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEfectosConciliados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFusionarEfectos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFusionarEfectos);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContadorSerieEmpresa',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContadorSerieEmpresa);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEmpresaCrearSeriesNoSeleccionada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEmpresaCrearSeriesNoSeleccionada);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoSeriesEmpresaCreadas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoSeriesEmpresaCreadas);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEmpresaNoSeleccionada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEmpresaNoSeleccionada);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoInstalacionSifEmpresaDisponible',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoInstalacionSifEmpresaDisponible);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContadorAutomaticoBusqueda',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContadorAutomaticoBusqueda);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoRegistroBusquedaCreado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoRegistroBusquedaCreado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorInsertarRegistroBusqueda',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorInsertarRegistroBusqueda);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoTextoNoEncontrado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoTextoNoEncontrado);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloBusquedaGlobal',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloBusquedaGlobal);
  ARegistrar(
    'inLibMsgComun.' +
    'SSolicitudTextoBusquedaGlobal',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SSolicitudTextoBusquedaGlobal);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoProcesosBusquedaNoEncontrados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoProcesosBusquedaNoEncontrados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDatosCopiarNoDisponibles',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDatosCopiarNoDisponibles);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaCopiarFilasPortapapeles',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaCopiarFilasPortapapeles);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEjecucionProceso',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEjecucionProceso);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorComandoSqlProceso',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorComandoSqlProceso);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorConexionTrabajoNoDisponible',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorConexionTrabajoNoDisponible);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoDatosGuardados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoDatosGuardados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorGrabarDatos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorGrabarDatos);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaGrabarCambiosPendientes',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaGrabarCambiosPendientes);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloMensajeAdvertenciaGen',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloMensajeAdvertenciaGen);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoCambiosGrabados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoCambiosGrabados);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoCambiosCancelados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoCambiosCancelados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorConexionPrincipalNoDisponible',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorConexionPrincipalNoDisponible);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaEliminarRegistro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaEliminarRegistro);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloConfirmarEliminacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloConfirmarEliminacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaEliminarRegistroConHijos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaEliminarRegistroConHijos);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoDesactivarRegistroConHijos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoDesactivarRegistroConHijos);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoDesactivarRegistroSinHijos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoDesactivarRegistroSinHijos);
  ARegistrar(
    'inLibMsgComun.' +
    'SDescripcionHijosGenerica',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SDescripcionHijosGenerica);
  ARegistrar(
    'inLibMsgComun.' +
    'STextoOpcionesBorradoRegistro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STextoOpcionesBorradoRegistro);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroSinCondiciones',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroSinCondiciones);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroActualVacio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroActualVacio);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaSobrescribirFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaSobrescribirFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloSobrescribirFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloSobrescribirFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoFiltroSobrescrito',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoFiltroSobrescrito);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoFiltroGuardado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoFiltroGuardado);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaLimpiarFiltrosAddBlock',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaLimpiarFiltrosAddBlock);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaPrevisualizarAddBlock',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaPrevisualizarAddBlock);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaConfirmarAddBlock',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaConfirmarAddBlock);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCertificadoNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCertificadoNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorEmpleadoEntradaCambioNoIndicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorEmpleadoEntradaCambioNoIndicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorImporteEntradaCambioNoValido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorImporteEntradaCambioNoValido);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloAvisoEntradaCambio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloAvisoEntradaCambio);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDestinoEnvioIncompleto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDestinoEnvioIncompleto);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorSerieBorradorNoSeleccionada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorSerieBorradorNoSeleccionada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFechaBorradorNoIndicada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFechaBorradorNoIndicada);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaEditarCamposExtraInforme',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaEditarCamposExtraInforme);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPrivilegiosBorrarFormato',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPrivilegiosBorrarFormato);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaBorrarFormato',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaBorrarFormato);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaReemplazarInforme',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaReemplazarInforme);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloAdvertenciaInforme',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloAdvertenciaInforme);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroSinCondicionesAplicar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroSinCondicionesAplicar);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroSinCondicionesGuardar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroSinCondicionesGuardar);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoCambiosFiltroGuardados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoCambiosFiltroGuardados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPantallaSinFiltroAplicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPantallaSinFiltroAplicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaReemplazarFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaReemplazarFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloReemplazarFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloReemplazarFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoFiltroReemplazado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoFiltroReemplazado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFiltroPropioDuplicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFiltroPropioDuplicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoCopiaFiltroGuardada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoCopiaFiltroGuardada);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaBorrarFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaBorrarFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloConfirmarBorradoFiltro',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloConfirmarBorradoFiltro);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoFiltroCompartidoGrupo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoFiltroCompartidoGrupo);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoFiltroCompartidoTodos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoFiltroCompartidoTodos);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNombreFiltroNoIndicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNombreFiltroNoIndicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCodigoGuiaNoIndicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCodigoGuiaNoIndicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorTablaExternaGuiaNoSeleccionada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorTablaExternaGuiaNoSeleccionada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCampoMasterGuiaNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCampoMasterGuiaNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCampoDetailGuiaNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCampoDetailGuiaNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoGuiaAnadida',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoGuiaAnadida);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoGuiasEliminarNoEncontradas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoGuiasEliminarNoEncontradas);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaEliminarGuia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaEliminarGuia);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorImporteConciliadoNoValido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorImporteConciliadoNoValido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorImporteConciliadoSuperaPendiente',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorImporteConciliadoSuperaPendiente);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNombreFormatoWizardNoIndicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNombreFormatoWizardNoIndicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNombreFormatoWizardNoModificado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNombreFormatoWizardNoModificado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorDatasetMasterWizardNoSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorDatasetMasterWizardNoSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCamposMasterWizardNoSeleccionados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCamposMasterWizardNoSeleccionados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorTablaExternaWizardNoSeleccionada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorTablaExternaWizardNoSeleccionada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCamposTablaExternaWizardNoSeleccionados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCamposTablaExternaWizardNoSeleccionados);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorSerieDocumentoNoIndicada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorSerieDocumentoNoIndicada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorAlmacenSerieTokenizadaNoIndicado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorAlmacenSerieTokenizadaNoIndicado);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorCajaSerieTokenizadaNoIndicada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorCajaSerieTokenizadaNoIndicada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFechaInicioDocumentoNoIndicada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFechaInicioDocumentoNoIndicada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorFechaFinDocumentoNoIndicada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorFechaFinDocumentoNoIndicada);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorRangoFechasDocumentoNoValido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorRangoFechasDocumentoNoValido);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEmpresaSinCuentasBancarias',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEmpresaSinCuentasBancarias);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCancelandoOperacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCancelandoOperacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionPreparando',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionPreparando);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionVersion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionVersion);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloGuardarExcel',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloGuardarExcel);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFiltroTodosArchivos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFiltroTodosArchivos);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFiltroArchivo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFiltroArchivo);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionLineasSku',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionLineasSku);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionLineasTallasHoriz',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionLineasTallasHoriz);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionLineasDesglose',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionLineasDesglose);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionAnadirDocumentoTrabajo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionAnadirDocumentoTrabajo);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSeleccioneFiltrosBuscar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSeleccioneFiltrosBuscar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionColorObjetivo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionColorObjetivo);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionColorBasico',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionColorBasico);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTextoABuscar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTextoABuscar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionOcultarCriterios',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionOcultarCriterios);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMostrarCriterios',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMostrarCriterios);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSkuEncontrados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSkuEncontrados);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSkuEncontradosLimite',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSkuEncontradosLimite);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFiltrosCargaContraido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFiltrosCargaContraido);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFiltrosCargaExpandido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFiltrosCargaExpandido);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCancelar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCancelar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEstadoInsertando',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEstadoInsertando);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEstadoEditando',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEstadoEditando);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEstadoNavegando',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEstadoNavegando);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEstadoInactivo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEstadoInactivo);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuDeshacer',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuDeshacer);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuRehacer',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuRehacer);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuBorrarLinea',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuBorrarLinea);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuCortar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuCortar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuCopiar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuCopiar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMenuPegar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMenuPegar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCopiarDatos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCopiarDatos);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSinDatosMostrar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSinDatosMostrar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSinDatos',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSinDatos);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionAgregarDocumentoTrabajo',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionAgregarDocumentoTrabajo);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionAceptarF12',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionAceptarF12);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCancelarEsc',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCancelarEsc);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionAceptar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionAceptar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionAplicar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionAplicar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionLimpiar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionLimpiar);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloBusquedaEmpleados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloBusquedaEmpleados);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCondicionesFiltroCompartido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCondicionesFiltroCompartido);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCondicionesFiltroSeleccionado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCondicionesFiltroSeleccionado);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabFechas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabFechas);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFechaInicio',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFechaInicio);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFechaFin',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFechaFin);
  ARegistrar(
    'inLibMsgComun.' +
    'SHintEscribaIntroFiltrar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SHintEscribaIntroFiltrar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMarqueValoresIncluir',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMarqueValoresIncluir);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionMarqueAgrupacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionMarqueAgrupacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSubir',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSubir);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionBajar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionBajar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionNivelFamilia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionNivelFamilia);
  ARegistrar(
    'inLibMsgComun.' +
    'SHintNivelFamilia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SHintNivelFamilia);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabFamilias',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabFamilias);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionDobleClicMarcaFamilia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionDobleClicMarcaFamilia);
  ARegistrar(
    'inLibMsgComun.' +
    'SHintBuscarFamilia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SHintBuscarFamilia);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionExportarExcel',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionExportarExcel);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSalir',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSalir);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionDesde',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionDesde);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionHasta',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionHasta);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionFamilia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionFamilia);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionProveedor',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionProveedor);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTemporada',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTemporada);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionBuscar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionBuscar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionGuiasLigadasFormato',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionGuiasLigadasFormato);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabModoDesglose',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabModoDesglose);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabModoSku',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabModoSku);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabModoTallasHorizBandas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabModoTallasHorizBandas);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTabModoTallasHoriz',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTabModoTallasHoriz);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloGuardarListadoExcel',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloGuardarListadoExcel);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloErrorProducido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloErrorProducido);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionDetalleErrorCabecera',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionDetalleErrorCabecera);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCerrar',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCerrar);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSalirAplicacion',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSalirAplicacion);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCopiarPortapapeles',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCopiarPortapapeles);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEnviarDesarrollador',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEnviarDesarrollador);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionActivarLogCompleto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionActivarLogCompleto);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEnviarCopiaSeguridadError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEnviarCopiaSeguridadError);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloContrasenaCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloContrasenaCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoContrasenaCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoContrasenaCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionContrasenaCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionContrasenaCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionRepetirContrasenaCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionRepetirContrasenaCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContrasenaCopiaErrorVacia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContrasenaCopiaErrorVacia);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContrasenasCopiaErrorNoCoinciden',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContrasenasCopiaErrorNoCoinciden);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionEmailContactoError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionEmailContactoError);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionTelefonoContactoError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionTelefonoContactoError);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionDescripcionError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionDescripcionError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEvidenciasError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEvidenciasError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEvidenciasCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEvidenciasCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoCopiaSeguridadError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoCopiaSeguridadError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoPreparandoCopiaSeguridadError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoPreparandoCopiaSeguridadError);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorPrepararCopiaSeguridadError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorPrepararCopiaSeguridadError);
  ARegistrar(
    'inLibMsgComun.' +
    'SAvisoLogErrorIncompleto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SAvisoLogErrorIncompleto);
  ARegistrar(
    'inLibMsgComun.' +
    'SPreguntaActivarLogCompleto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SPreguntaActivarLogCompleto);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoLogActivadoRepetir',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoLogActivadoRepetir);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoLogErrorCompleto',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoLogErrorCompleto);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorContactoEnvioErrorNoValido',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorContactoEnvioErrorNoValido);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorNoSePudoEnviarError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorNoSePudoEnviarError);
  ARegistrar(
    'inLibMsgComun.' +
    'SErrorRespuestaEnvioError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SErrorRespuestaEnvioError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoErrorEnviado',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoErrorEnviado);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoSeguimientoError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoSeguimientoError);
  ARegistrar(
    'inLibMsgComun.' +
    'SInfoEnviarContrasenaCopiaError',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SInfoEnviarContrasenaCopiaError);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionSinFiltrosGuardados',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionSinFiltrosGuardados);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionGuardarFiltroActual',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionGuardarFiltroActual);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionGestionarCompartirFiltros',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionGestionarCompartirFiltros);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionGuiaTabla',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionGuiaTabla);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionRenombrarColumna',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionRenombrarColumna);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionNuevaGuia',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionNuevaGuia);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloRenombrarColumnas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloRenombrarColumnas);
  ARegistrar(
    'inLibMsgComun.' +
    'SCaptionCargandoDatosEspere',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      SCaptionCargandoDatosEspere);
  ARegistrar(
    'inLibMsgComun.' +
    'STituloSeleccionarColumnas',
    'src/Lib/inLibMsgComun.pas',
    @inLibMsgComun.
      STituloSeleccionarColumnas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorDecryptPassBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorDecryptPassBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorDecryptPass',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorDecryptPass);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorAuthPass',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorAuthPass);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SScriptSuccess',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SScriptSuccess);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SFailLoadScriptBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SFailLoadScriptBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCreateSuccBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCreateSuccBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorCreateBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorCreateBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SBBDDUpdateTo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SBBDDUpdateTo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SNotExistsUpBBDDFile',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SNotExistsUpBBDDFile);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAdviceUpdateBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAdviceUpdateBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SNoConnBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SNoConnBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SConnSuccBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SConnSuccBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SGetPassBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SGetPassBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SConnFailBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SConnFailBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorSentenciaScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorSentenciaScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SSolicitudPassBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SSolicitudPassBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SScriptEjecutado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SScriptEjecutado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SScriptNoEjecutado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SScriptNoEjecutado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionServidorBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionServidorBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorEstructuraBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorEstructuraBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionBBDD',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionBBDD);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorInicioAutomatico',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorInicioAutomatico);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SLicenciaEstablecida',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SLicenciaEstablecida);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SLicenciaNoEstablecidaSinNif',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SLicenciaNoEstablecidaSinNif);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorEstablecerLicencia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorEstablecerLicencia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SModoDemo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SModoDemo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCancelacionSolicitada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCancelacionSolicitada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaCancelarOperacion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaCancelarOperacion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SOperacionCancelada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SOperacionCancelada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCopiaSeguridadGuardada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCopiaSeguridadGuardada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SProgresoGuardandoCopiaTextoPlano',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SProgresoGuardandoCopiaTextoPlano);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SProgresoComprimiendoCopiaZip',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SProgresoComprimiendoCopiaZip);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SProgresoComprimiendoCifrandoCopia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SProgresoComprimiendoCifrandoCopia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorCrearCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorCrearCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionCopiaNoDisponible',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionCopiaNoDisponible);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorFormatoCreacionCopiaNoPermitido',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorFormatoCreacionCopiaNoPermitido);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorFormatoCopiaNoCompatible',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorFormatoCopiaNoCompatible);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorSintaxisComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorSintaxisComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorSintaxisComandoImprimirFacturas',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorSintaxisComandoImprimirFacturas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAyudaComandos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAyudaComandos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorRutaComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorRutaComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorExtensionComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorExtensionComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorClaveComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorClaveComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorInesperadoComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorInesperadoComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPublicarComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPublicarComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorFormatoComandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorFormatoComandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadInicio',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadInicio);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadParametrosValidados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadParametrosValidados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadConexion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadConexion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadConexionPreparada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadConexionPreparada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadDestino',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadDestino);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadGeneracion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadGeneracion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadPublicacion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadPublicacion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoComandoCopiaSeguridadCompletado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoComandoCopiaSeguridadCompletado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SRestauracionCancelada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SRestauracionCancelada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorRestaurarCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorRestaurarCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorContrasenaCopiaVacia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorContrasenaCopiaVacia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorTipoRestauracionNoPermitido',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorTipoRestauracionNoPermitido);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaReemplazarFichero',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaReemplazarFichero);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCopiaSeguridadCancelada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCopiaSeguridadCancelada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCargaScriptCancelada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCargaScriptCancelada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SUsuarioNoExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SUsuarioNoExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SDescripcionParametroIdioma',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SDescripcionParametroIdioma);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorSeleccionIdiomaNoAplicado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorSeleccionIdiomaNoAplicado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorProveedorEdicionParametrosNoConfigurado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorProveedorEdicionParametrosNoConfigurado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorParametrosAplicacionEditablesNoConfigurados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorParametrosAplicacionEditablesNoConfigurados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoParametrosGuardados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoParametrosGuardados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoParametrosRestringidosIgnorados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoParametrosRestringidosIgnorados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoParametrosRestringidosNoGuardados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoParametrosRestringidosNoGuardados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoSinCambiosParametros',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoSinCambiosParametros);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoLayoutGuardado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoLayoutGuardado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaSalirSinGuardar',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaSalirSinGuardar);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoSinUsuariosParametrosGuardados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoSinUsuariosParametrosGuardados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloCambiarUsuario',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloCambiarUsuario);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SSolicitudCambiarUsuario',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SSolicitudCambiarUsuario);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorUsuarioNoEncontrado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorUsuarioNoEncontrado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorContextoInicioSesionNoProporcionado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorContextoInicioSesionNoProporcionado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorParametrosSinEstadoLicencia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorParametrosSinEstadoLicencia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorParametrosAplicacionSinContratoEdicion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorParametrosAplicacionSinContratoEdicion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorServicioConexionesNoDisponible',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorServicioConexionesNoDisponible);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCertificadoQuedaMenosUnDia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCertificadoQuedaMenosUnDia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCertificadoQuedaUnDia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCertificadoQuedaUnDia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCertificadoQuedanDias',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCertificadoQuedanDias);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoCertificadoCaducado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoCertificadoCaducado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoCertificadoProximoCaducar',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoCertificadoProximoCaducar);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoCertificadosCaducidad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoCertificadosCaducidad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoCargaPermisosRestringidos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoCargaPermisosRestringidos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoCopiaSeguridadGuardada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoCopiaSeguridadGuardada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SAvisoRestauracionCancelada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SAvisoRestauracionCancelada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorEjecutarScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorEjecutarScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaSalirAplicacion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaSalirAplicacion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaCopiaSeguridadAntesDDL',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaCopiaSeguridadAntesDDL);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaCopiaAntesRestaurarCifrada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaCopiaAntesRestaurarCifrada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoScriptCancelado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoScriptCancelado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorAbrirDireccion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorAbrirDireccion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDDuplicado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDDuplicado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDCamposObligatorios',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDCamposObligatorios);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDCampoDesconocido',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDCampoDesconocido);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDTablaNoExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDTablaNoExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDSinPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDSinPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDClaveForaneaNoExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDClaveForaneaNoExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDRegistroDependiente',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDRegistroDependiente);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDDatoDemasiadoLargo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDDatoDemasiadoLargo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDCredencialesIncorrectas',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDCredencialesIncorrectas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDConexionServidor',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDConexionServidor);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDConexionPerdida',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDConexionPerdida);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDConexionPerdidaConsulta',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDConexionPerdidaConsulta);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDTimeoutBloqueo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDTimeoutBloqueo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDDeadlock',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDDeadlock);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDTablaYaExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDTablaYaExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDProcedimientoYaExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDProcedimientoYaExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorBBDDGenerico',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorBBDDGenerico);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorNombreUsuario',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorNombreUsuario);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorUsuarioCoincideGrupo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorUsuarioCoincideGrupo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionPrincipalTrabajoNoDisponible',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionPrincipalTrabajoNoDisponible);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorOperacionCanceladaUsuario',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorOperacionCanceladaUsuario);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorRestauracionEstructuraIncompleta',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorRestauracionEstructuraIncompleta);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorNombreBBDDDestinoVacio',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorNombreBBDDDestinoVacio);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorFicheroCopiaNoExiste',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorFicheroCopiaNoExiste);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorDesencriptarCopia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorDesencriptarCopia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorLimitePeticionesCripto',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorLimitePeticionesCripto);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorRestauracionNoFinalizada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorRestauracionNoFinalizada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorDialogoPermisosLayoutNoRegistrado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorDialogoPermisosLayoutNoRegistrado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorNifEmpresaLicenciaNoConfigurado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorNifEmpresaLicenciaNoConfigurado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoLicenciaSinNifEmpresa',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoLicenciaSinNifEmpresa);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorLicenciaNoEncontrada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorLicenciaNoEncontrada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoLicenciaValida',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoLicenciaValida);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorLicenciaNifsNoCoinciden',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorLicenciaNifsNoCoinciden);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorParametrosAplicacionNoProporcionados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorParametrosAplicacionNoProporcionados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorServicioPerfilesNoProporcionado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorServicioPerfilesNoProporcionado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorCargarPerfilParametros',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorCargarPerfilParametros);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionPermisosNoDisponible',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionPermisosNoDisponible);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorConexionBbddConExcepcion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorConexionBbddConExcepcion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorServicioPerfilesUsuarioNoConfigurado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorServicioPerfilesUsuarioNoConfigurado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaIgnorarErrorScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaIgnorarErrorScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorMetadatoSinScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorMetadatoSinScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaIgnorarErrorComandoScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaIgnorarErrorComandoScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPermisoInsertarRegistro',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPermisoInsertarRegistro);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPermisoModificarRegistro',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPermisoModificarRegistro);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPermisoGuardarRegistro',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPermisoGuardarRegistro);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPermisoBorrarRegistro',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPermisoBorrarRegistro);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorNodoPermisosNoSeleccionado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorNodoPermisosNoSeleccionado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorOrigenDestinoPermisosNoSeleccionados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorOrigenDestinoPermisosNoSeleccionados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorOrigenDestinoPermisosIguales',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorOrigenDestinoPermisosIguales);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoModoReemplazarPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoModoReemplazarPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoModoCombinarPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoModoCombinarPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoAlcancePermisosMenu',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoAlcancePermisosMenu);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoAlcanceTodosPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoAlcanceTodosPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SPreguntaCopiarPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SPreguntaCopiarPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoPermisosCopiados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoPermisosCopiados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorContrasenasNoCoinciden',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorContrasenasNoCoinciden);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SInfoLogGuardado',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SInfoLogGuardado);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SErrorPermisoAbrirCajon',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SErrorPermisoAbrirCajon);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloCargarScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloCargarScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloGuardarCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloGuardarCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloCargarCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloCargarCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloRestaurarCopiaEjecutarScript',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloRestaurarCopiaEjecutarScript);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroCopiasSqlEncriptadas',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroCopiasSqlEncriptadas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroCopiasCifradas',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroCopiasCifradas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroCopiasZip',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroCopiasZip);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroArchivosSql',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroArchivosSql);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroCopiasSqlCifradas',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroCopiasSqlCifradas);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroCopiasScriptsCifrados',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroCopiasScriptsCifrados);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionPreparandoCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionPreparandoCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionPreparandoRestauracion',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionPreparandoRestauracion);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloAbrirScriptSql',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloAbrirScriptSql);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroScriptsSql',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroScriptsSql);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionModoCombinarPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionModoCombinarPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionModoReemplazarPermisos',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionModoReemplazarPermisos);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionAvisoSujetoAdministrador',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionAvisoSujetoAdministrador);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloProtegerCopiaSeguridad',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloProtegerCopiaSeguridad);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionCopiaSeCifrara',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionCopiaSeCifrara);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloAbrirCopiaCifrada',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloAbrirCopiaCifrada);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionIntroduzcaContrasenaCopia',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionIntroduzcaContrasenaCopia);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'STituloGuardarLogComo',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      STituloGuardarLogComo);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroArchivosSqlTexto',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroArchivosSqlTexto);
  ARegistrar(
    'inLibMsgConfiguracion.' +
    'SCaptionFiltroArchivosTexto',
    'src/Lib/inLibMsgConfiguracion.pas',
    @inLibMsgConfiguracion.
      SCaptionFiltroArchivosTexto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorLecturasFacturasNoRegistradas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorLecturasFacturasNoRegistradas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorRepositorioFacturaeNoRegistrado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorRepositorioFacturaeNoRegistrado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCliToTbl',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCliToTbl);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SEmpToTbl',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SEmpToTbl);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorEnviarTicketImpresora',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorEnviarTicketImpresora);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoTicketEnviadoImpresora',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoTicketEnviadoImpresora);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoAlbaranFacturado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoAlbaranFacturado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaBorrarClienteConFacturas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaBorrarClienteConFacturas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaBorrarEmpresaConFacturas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaBorrarEmpresaConFacturas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorOperacionSinIvaConCuota',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorOperacionSinIvaConCuota);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCalcularBorradorDetalle',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCalcularBorradorDetalle);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCalculoBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCalculoBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorTipoIvaFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorTipoIvaFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorrarBorradorFase',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorrarBorradorFase);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaBorrarFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaBorrarFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorrarBorradorEfectosCobrados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorrarBorradorEfectosCobrados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorInsertarLineasCabeceraFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorInsertarLineasCabeceraFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorSinGrabarParaLineas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorSinGrabarParaLineas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorSerieFacturaOtraEmpresa',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorSerieFacturaOtraEmpresa);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorRazonSocialEmpresaBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorRazonSocialEmpresaBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorSerieBorradorObligatoria',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorSerieBorradorObligatoria);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFechaBorradorObligatoria',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFechaBorradorObligatoria);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorNifClienteFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorNifClienteFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorNifEmpresaFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorNifEmpresaFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFechaFacturaAnteriorSerie',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFechaFacturaAnteriorSerie);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoFechaBorradorFutura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoFechaBorradorFutura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorAsignarNumeroFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorAsignarNumeroFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoHuecoNumeracionFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoHuecoNumeracionFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCodigoFacturaeFormaPago',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCodigoFacturaeFormaPago);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeFaltaCampo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeFaltaCampo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoNifParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoNifParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoRazonSocialParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoRazonSocialParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoDireccionParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoDireccionParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoCodigoPostalParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoCodigoPostalParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoPoblacionParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoPoblacionParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoProvinciaParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoProvinciaParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorDocumentoFiscalParteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorDocumentoFiscalParteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFaltaCodigoDir3Facturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFaltaCodigoDir3Facturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCodigoDir3LargoFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCodigoDir3LargoFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoEmpresaEmisoraFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoEmpresaEmisoraFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoClienteFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoClienteFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoOficinaContableFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoOficinaContableFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoOrganoGestorFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoOrganoGestorFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoUnidadTramitadoraFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoUnidadTramitadoraFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorNombrePersonaFisicaFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorNombrePersonaFisicaFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorApellidosPersonaFisicaFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorApellidosPersonaFisicaFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCodigoPagoFacturaeInvalido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCodigoPagoFacturaeInvalido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeNoExiste',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeNoExiste);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeTipoVentaInvalido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeTipoVentaInvalido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeNoConsolidada',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeNoConsolidada);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeFechaOficialFaltante',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeFechaOficialFaltante);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorLineaFacturaeSinDescripcion',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorLineaFacturaeSinDescripcion);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorLineaFacturaeCantidadCero',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorLineaFacturaeCantidadCero);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaeSinLineas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaeSinLineas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBasesFacturaeNoCuadran',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBasesFacturaeNoCuadran);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorTotalesFacturaeNoCuadran',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorTotalesFacturaeNoCuadran);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorEmitirFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorEmitirFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCertificadoFacturaeNoConfigurado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCertificadoFacturaeNoConfigurado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorConexionFacturaeNoDisponible',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorConexionFacturaeNoDisponible);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFicheroSalidaFacturaeNoIndicado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFicheroSalidaFacturaeNoIndicado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorPorcentajeIvaFueraRango',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorPorcentajeIvaFueraRango);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorPrecioFacturaNegativo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorPrecioFacturaNegativo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorAbrirImpresoraTicket',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorAbrirImpresoraTicket);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorIniciarDocumentoImpresora',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorIniciarDocumentoImpresora);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorEscribirImpresora',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorEscribirImpresora);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorLimiteDemoFacturas',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorLimiteDemoFacturas);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorPreviewTicketNoRegistrado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorPreviewTicketNoRegistrado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorRecalcularTotalesFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorRecalcularTotalesFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaWebserviceNoExiste',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaWebserviceNoExiste);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFirmaFacturaRaizIncorrecta',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFirmaFacturaRaizIncorrecta);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoRegistroFacturaIndice',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoRegistroFacturaIndice);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SFormatoEtiquetaFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SFormatoEtiquetaFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoFacturaSinPeticionCompletaXml',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoFacturaSinPeticionCompletaXml);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaHashPeticionNoCoincide',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaHashPeticionNoCoincide);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaSinRegistroXmlFirmado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaSinRegistroXmlFirmado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaHashRegistroNoCoincide',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaHashRegistroNoCoincide);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaGuardadaSinFirmaXml',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaGuardadaSinFirmaXml);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaSignatureValueNoCoincide',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaSignatureValueNoCoincide);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STextoFacturacion',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STextoFacturacion);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFicheroFacturacionNoExiste',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFicheroFacturacionNoExiste);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFicheroFacturacionRaizIncorrecta',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFicheroFacturacionRaizIncorrecta);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFicheroFacturacionVacio',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFicheroFacturacionVacio);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorVerificarFacturacion',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorVerificarFacturacion);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaRequisitosFiscalesNoExiste',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaRequisitosFiscalesNoExiste);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorColumnasFirmaFacturacionNoDisponibles',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorColumnasFirmaFacturacionNoDisponibles);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaExtranjeraSinNifIva',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaExtranjeraSinNifIva);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturaSinNifClienteValido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturaSinNifClienteValido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoBorradorFacturaCreado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoBorradorFacturaCreado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCrearBorradorFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCrearBorradorFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaBorrarMovimientosTicketAnulado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaBorrarMovimientosTicketAnulado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaMovimientosRectificativaSustitutiva',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaMovimientosRectificativaSustitutiva);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFacturarTicketRequiereSimplificado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFacturarTicketRequiereSimplificado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoBorradorSustitucionTicketCreado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoBorradorSustitucionTicketCreado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorRectificarRectificativa',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorRectificarRectificativa);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorOperacionSinTicket',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorOperacionSinTicket);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoLimiteRegistrosFacturaSimplificada',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoLimiteRegistrosFacturaSimplificada);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorVentaMayorNoSeleccionado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorVentaMayorNoSeleccionado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorGuardarAntesEmitirEdoc',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorGuardarAntesEmitirEdoc);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorPersonaFisicaEdocSinDatos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorPersonaFisicaEdocSinDatos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoEdocEmitido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoEdocEmitido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaReemplazarCobros',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaReemplazarCobros);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STituloMensajeAdvertencia',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STituloMensajeAdvertencia);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoGeneracionCobrosCancelada',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoGeneracionCobrosCancelada);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoEfectosCobroGenerados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoEfectosCobroGenerados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoEfectosCobroNoGenerados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoEfectosCobroNoGenerados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorGenerarEfectosCobroSinBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorGenerarEfectosCobroSinBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SAvisoBorradorPendienteImpresionFiscal',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SAvisoBorradorPendienteImpresionFiscal);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorGuardarFacturaAntesImprimir',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorGuardarFacturaAntesImprimir);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoEfectoMarcadoDevuelto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoEfectoMarcadoDevuelto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorMarcarEfectoDevuelto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorMarcarEfectoDevuelto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoEfectoMarcadoPendiente',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoEfectoMarcadoPendiente);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorMarcarEfectoPendiente',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorMarcarEfectoPendiente);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorEfectoSinImportePendiente',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorEfectoSinImportePendiente);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorListaNoSeleccionado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorListaNoSeleccionado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorNoCerradoAccionFiscal',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorNoCerradoAccionFiscal);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaAccionFiscalBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaAccionFiscalBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorYaLanzadoFiscalmente',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorYaLanzadoFiscalmente);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorSinLineasLanzar',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorSinLineasLanzar);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorNormalSinNif',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorNormalSinNif);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaLanzarBorradorFiscal',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaLanzarBorradorFiscal);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorConsolidadoNoReabrible',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorConsolidadoNoReabrible);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoBorradorYaEnBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoBorradorYaEnBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaDevolverBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaDevolverBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorAltaAeatAceptadaNoReabrible',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorAltaAeatAceptadaNoReabrible);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorBorradorEnProcesoNoReabrible',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorBorradorEnProcesoNoReabrible);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoBorradorReabierto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoBorradorReabierto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaGrabarFacturaVentaSinSku',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaGrabarFacturaVentaSinSku);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCompletarDatosBorrador',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCompletarDatosBorrador);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorEmpresaProveedorFacturacionNoIndicados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorEmpresaProveedorFacturacionNoIndicados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SPreguntaFacturarTodosAlbaranesListados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SPreguntaFacturarTodosAlbaranesListados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SInfoBorradoresGenerados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SInfoBorradoresGenerados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorClienteFacturarTicketNoExiste',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorClienteFacturarTicketNoExiste);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorRazonSocialFacturarTicketObligatoria',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorRazonSocialFacturarTicketObligatoria);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorDocumentoFiscalFacturarTicketNoValido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorDocumentoFiscalFacturarTicketNoValido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorCrearBorradorFacturarTicket',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorCrearBorradorFacturarTicket);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorFechaTicketSerieNoValida',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorFechaTicketSerieNoValida);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STituloTipoRectificativa',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STituloTipoRectificativa);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionPorDiferencias',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionPorDiferencias);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionSustitutiva',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionSustitutiva);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STituloMovimientosAlmacen',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STituloMovimientosAlmacen);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionEliminarOriginales',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionEliminarOriginales);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionMantenerOriginales',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionMantenerOriginales);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabEfectos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabEfectos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionGenerarEfectos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionGenerarEfectos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionImprimirEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionImprimirEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionEfectoPendiente',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionEfectoPendiente);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionEfectoCobrado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionEfectoCobrado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionEfectoDevuelto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionEfectoDevuelto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColNroBorradorEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColNroBorradorEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColSerieBorradorEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColSerieBorradorEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColTotalEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColTotalEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColEstadoEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColEstadoEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColFechaEmisionEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColFechaEmisionEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColFechaCobroEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColFechaCobroEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColReferenciaEfecto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColReferenciaEfecto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabRecibos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabRecibos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionGenerarRecibos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionGenerarRecibos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionImprimirRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionImprimirRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionReciboEmitido',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionReciboEmitido);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionReciboPagado',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionReciboPagado);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionReciboDevuelto',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionReciboDevuelto);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColNroBorradorRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColNroBorradorRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColSerieBorradorRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColSerieBorradorRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColNroPlazo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColNroPlazo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColTotalRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColTotalRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColEstadoRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColEstadoRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColFechaExpedicionRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColFechaExpedicionRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColFechaPagoRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColFechaPagoRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionColLocalidadExpedicionRecibo',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionColLocalidadExpedicionRecibo);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionEfectosCobroPlural',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionEfectosCobroPlural);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionRecibosPlural',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionRecibosPlural);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabLineasBorradorClasico',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabLineasBorradorClasico);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabLineasBorradorSku',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabLineasBorradorSku);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabLineasBorradorDesglose',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabLineasBorradorDesglose);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionTabLineasBorradorTallasHoriz',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionTabLineasBorradorTallasHoriz);
  ARegistrar(
    'inLibMsgFacturas.' +
    'STituloEmitirEDoc',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      STituloEmitirEDoc);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionFiltroFacturae',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionFiltroFacturae);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionCargandoBorradores',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionCargandoBorradores);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionCargandoBorradoresProgreso',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionCargandoBorradoresProgreso);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionCreandoBorradoresAlbaranes',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionCreandoBorradoresAlbaranes);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionGeneradosBorradores',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionGeneradosBorradores);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionGrupoFecha',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionGrupoFecha);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionFechaDocumento',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionFechaDocumento);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionFechaValor',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionFechaValor);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionFechaVencimiento',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionFechaVencimiento);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionGrupoSituacion',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionGrupoSituacion);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionSituacionPagados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionSituacionPagados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionSituacionImpagados',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionSituacionImpagados);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionSituacionPendientes',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionSituacionPendientes);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionSituacionTodos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionSituacionTodos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionNumEfectoDesde',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionNumEfectoDesde);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionNumEfectoHasta',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionNumEfectoHasta);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionMostrarSoloTotales',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionMostrarSoloTotales);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionCuentaEmpresaPagoEfectos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionCuentaEmpresaPagoEfectos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionCuentaEmpresaCobroRecibos',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionCuentaEmpresaCobroRecibos);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SCaptionHojaFactura',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SCaptionHojaFactura);
  ARegistrar(
    'inLibMsgFacturas.' +
    'SErrorPersistenciaFacturasNoRegistrada',
    'src/Lib/inLibMsgFacturas.pas',
    @inLibMsgFacturas.
      SErrorPersistenciaFacturasNoRegistrada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorDivisaNoEncontrada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorDivisaNoEncontrada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorHttpDivisas',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorHttpDivisas);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorRedDivisas',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorRedDivisas);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorJsonDivisas',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorJsonDivisas);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorPruebaPilaJcl',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorPruebaPilaJcl);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorHttpCripto',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorHttpCripto);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorRedCripto',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorRedCripto);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorJsonCripto',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorJsonCripto);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorRespuestaHttpFactuzamApi',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorRespuestaHttpFactuzamApi);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorFactuzamApiNoConfigurada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorFactuzamApiNoConfigurada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SInfoEventoFactuzamApiRecibido',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SInfoEventoFactuzamApiRecibido);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SInfoConsultaFactuzamApiRealizada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SInfoConsultaFactuzamApiRealizada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SInfoDocumentoFactuzamApiGuardado',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SInfoDocumentoFactuzamApiGuardado);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SInfoDocumentoFactuzamApiDescargado',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SInfoDocumentoFactuzamApiDescargado);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorDescargaTraduccion',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorDescargaTraduccion);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorPaqueteTraduccionInvalido',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorPaqueteTraduccionInvalido);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorConexionTraduccionNoDisponible',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorConexionTraduccionNoDisponible);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorTraduccionTransaccionActiva',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorTraduccionTransaccionActiva);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorTraduccionSinFilas',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorTraduccionSinFilas);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionPreparando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionPreparando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionDescargando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionDescargando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionValidando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionValidando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionEjecutando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionEjecutando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionComprobando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionComprobando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionDisponible',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionDisponible);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionAplicando',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionAplicando);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SProgresoTraduccionCompletada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SProgresoTraduccionCompletada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorRespuestaFormateadorSqlVacia',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorRespuestaFormateadorSqlVacia);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorRespuestaFormateadorSqlInesperada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorRespuestaFormateadorSqlInesperada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorEncolarVentaWebservice',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorEncolarVentaWebservice);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorVentasWsJsonNoRegistrado',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorVentasWsJsonNoRegistrado);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorVentasWsColaNoRegistrada',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorVentasWsColaNoRegistrada);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorApiKeyInstalacionFaltante',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorApiKeyInstalacionFaltante);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SErrorDeclaracionWebserviceOtraVersion',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SErrorDeclaracionWebserviceOtraVersion);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SCaptionConectandoPrestaShop',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SCaptionConectandoPrestaShop);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SCaptionRecuperadosPedidos',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SCaptionRecuperadosPedidos);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SCaptionNoRecuperadosPedidos',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SCaptionNoRecuperadosPedidos);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SCaptionImportandoPedido',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SCaptionImportandoPedido);
  ARegistrar(
    'inLibMsgIntegraciones.' +
    'SCaptionErrorImportandoPedido',
    'src/Lib/inLibMsgIntegraciones.pas',
    @inLibMsgIntegraciones.
      SCaptionErrorImportandoPedido);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRegaloNumero',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRegaloNumero);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFacturaSimplificadaNumero',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFacturaSimplificadaNumero);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOperacionNumero',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOperacionNumero);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCifNif',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCifNif);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTelefono',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTelefono);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEtiquetaOperacionNumero',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEtiquetaOperacionNumero);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFormatoTienda',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFormatoTienda);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCabeceraArticulos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCabeceraArticulos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSuma',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSuma);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDescuento',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDescuento);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketValeRecogido',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketValeRecogido);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketAPagar',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketAPagar);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCambioEfectivo',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCambioEfectivo);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketValeEmitidoFavor',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketValeEmitidoFavor);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCodigoValeEmitido',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCodigoValeEmitido);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCodigoValeEmitidoEspacio',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCodigoValeEmitidoEspacio);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketBaseImponible',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketBaseImponible);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketBaseImponibleReducida',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketBaseImponibleReducida);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalIvaFormato',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalIvaFormato);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketLeAtendio',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketLeAtendio);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketIvaIncluido',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketIvaIncluido);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketGraciasVisita',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketGraciasVisita);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDepositosEntregas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDepositosEntregas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEtiquetaCodigoCliente',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEtiquetaCodigoCliente);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEtiquetaFecha',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEtiquetaFecha);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEtiquetaNumeroOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEtiquetaNumeroOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketValorArticulo',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketValorArticulo);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEntregasCuenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEntregasCuenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCuentaArticulo',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCuentaArticulo);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCuentaInicialArticulo',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCuentaInicialArticulo);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCuentaArticuloPendiente',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCuentaArticuloPendiente);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCuentaInicial',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCuentaInicial);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDevolucionEconomica',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDevolucionEconomica);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalNuevosDepositos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalNuevosDepositos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalDepositosDevueltos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalDepositosDevueltos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketAnticiposEntregadosAhora',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketAnticiposEntregadosAhora);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDevueltoOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDevueltoOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalPagadoDepositos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalPagadoDepositos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketConformeCliente',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketConformeCliente);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketMovimientoDepositosPrestamos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketMovimientoDepositosPrestamos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDevolucionArticulos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDevolucionArticulos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEstadoCuentaDepositos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEstadoCuentaDepositos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFormatoFechaLarga',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFormatoFechaLarga);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEmpresa',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEmpresa);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCliente',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCliente);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFechaHora',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFechaHora);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotal',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotal);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPendiente',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPendiente);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRetiradoEn',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRetiradoEn);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEntregaInicial',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEntregaInicial);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketACuenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketACuenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalPendientePago',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalPendientePago);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEntradaCambio',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEntradaCambio);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketGastoRetiradaCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketGastoRetiradaCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFecha',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFecha);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEmpleado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEmpleado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOperacionAbreviada',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOperacionAbreviada);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketConcepto',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketConcepto);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketImporte',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketImporte);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFirma',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFirma);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSolicitudTraspaso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSolicitudTraspaso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTraspaso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTraspaso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOrigen',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOrigen);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDestino',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDestino);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEstado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEstado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketArticulos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketArticulos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketUnidadesPedidas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketUnidadesPedidas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketUnidades',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketUnidades);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockOrigen',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockOrigen);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockDestino',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockDestino);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockOrigenTrasTraspaso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockOrigenTrasTraspaso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockDestinoTrasTraspaso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockDestinoTrasTraspaso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockOrigenActual',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockOrigenActual);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketStockDestinoActual',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketStockDestinoActual);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCif',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCif);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPrimeraOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPrimeraOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketUltimaOperacion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketUltimaOperacion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOperaciones',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOperaciones);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketUnidadesVenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketUnidadesVenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketLineasArticulos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketLineasArticulos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketBruto',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketBruto);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentasNormales',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentasNormales);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentasPrestamos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentasPrestamos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDevoluciones',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDevoluciones);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalVentas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalVentas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCobros',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCobros);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketValesRecogidos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketValesRecogidos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketValesEmitidos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketValesEmitidos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCobrosClientes',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCobrosClientes);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPendienteCobro',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPendienteCobro);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketIngresosCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketIngresosCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivo',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivo);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoIngresos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoIngresos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoEntradas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoEntradas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoSalidas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoSalidas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoAnterior',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoAnterior);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOtrosIngresos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOtrosIngresos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSaldoRecontar',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSaldoRecontar);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDevolucionesClientes',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDevolucionesClientes);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketNetoArticulos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketNetoArticulos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenNetoSeccion',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenNetoSeccion);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenVentasTemporada',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenVentasTemporada);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFormatoResumenTemporada',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFormatoResumenTemporada);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenVentasEmpleado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenVentasEmpleado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFormatoResumenEmpleado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFormatoResumenEmpleado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenFormaPago',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenFormaPago);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFormatoResumenFormaPago',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFormatoResumenFormaPago);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumenVentasSerie',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumenVentasSerie);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCabeceraSerie',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCabeceraSerie);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCabeceraBaseImponible',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCabeceraBaseImponible);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCabeceraPorcentajeIva',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCabeceraPorcentajeIva);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCabeceraCuota',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCabeceraCuota);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketArqueoCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketArqueoCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPeriodoSeleccionado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPeriodoSeleccionado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDesde',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDesde);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketHasta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketHasta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDuplicado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDuplicado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCierreCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCierreCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPeriodoCerrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPeriodoCerrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketInicio',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketInicio);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketFin',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketFin);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCierrePor',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCierrePor);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVendedor',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVendedor);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketBilletesMonedas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketBilletesMonedas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEfectivoSistema',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEfectivoSistema);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentasSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentasSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEntradasSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEntradasSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketGastosSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketGastosSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketAnteriorSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketAnteriorSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRecuento',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRecuento);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSistemaAbreviado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSistemaAbreviado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRecuentoAbreviado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRecuentoAbreviado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDiferenciaAbreviada',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDiferenciaAbreviada);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalSistema',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalSistema);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalRecontado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalRecontado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDiferencia',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDiferencia);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRetirada',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRetirada);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDestinoSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDestinoSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDejoCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDejoCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketObservaciones',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketObservaciones);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketCambio',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketCambio);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketNumeroFactura',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketNumeroFactura);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOperacionCorta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOperacionCorta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketClienteCorto',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketClienteCorto);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalTraspasoCoste',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalTraspasoCoste);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketEntregadoCuenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketEntregadoCuenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketPendienteSangrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketPendienteSangrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRotuloTraspaso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRotuloTraspaso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRotuloIngreso',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRotuloIngreso);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRotuloGasto',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRotuloGasto);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRotuloDeposito',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRotuloDeposito);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketRotuloVenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketRotuloVenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTraspasosSalientes',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTraspasosSalientes);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketIngresosPorCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketIngresosPorCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketGastosPorCaja',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketGastosPorCaja);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentasCreditoDepositos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentasCreditoDepositos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketVentasFacturadas',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketVentasFacturadas);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTraspasos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTraspasos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSubtotalCoste',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSubtotalCoste);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketIngresos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketIngresos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSubtotal',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSubtotal);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketGastos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketGastos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDepositos',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDepositos);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSubtotalVenta',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSubtotalVenta);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSubtotalCobrado',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSubtotalCobrado);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTotalVentasSinSigno',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTotalVentasSinSigno);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketArqueoCajaHora',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketArqueoCajaHora);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketDel',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketDel);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketAl',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketAl);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketTodasSeries',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketTodasSeries);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSeries',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSeries);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOrdenCronologico',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOrdenCronologico);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketOrdenTipoDocumento',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketOrdenTipoDocumento);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketSinOperaciones',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketSinOperaciones);
  ARegistrar(
    'inLibMsgTickets.' +
    'STicketResumen',
    'src/Lib/inLibMsgTickets.pas',
    @inLibMsgTickets.
      STicketResumen);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaBorrarAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaBorrarAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoAlmacenSalidaAlbaranObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoAlmacenSalidaAlbaranObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCabeceraAlbaranSinGrabar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCabeceraAlbaranSinGrabar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAsignarLineaAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAsignarLineaAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContadorAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContadorAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRazonSocialCliente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRazonSocialCliente);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorTipoDestinoDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorTipoDestinoDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDestinoCompartidoNoExiste',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDestinoCompartidoNoExiste);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDestinoCompartirObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDestinoCompartirObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCompartirDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCompartirDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCabeceraDocumentoTrabajoSinGrabar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCabeceraDocumentoTrabajoSinGrabar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCompartirDocumentoTrabajoConsigoMismo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCompartirDocumentoTrabajoConsigoMismo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBorrarDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBorrarDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCambiarPropietarioDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCambiarPropietarioDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorTituloDocumentoTrabajoObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorTituloDocumentoTrabajoObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEstadoDocumentoTrabajoNoValido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEstadoDocumentoTrabajoNoValido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorModificarDocumentoTrabajoNoPermitido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorModificarDocumentoTrabajoNoPermitido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEnviarDocumentoTrabajoNoPermitido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEnviarDocumentoTrabajoNoPermitido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorArchivarDocumentoTrabajoNoPermitido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorArchivarDocumentoTrabajoNoPermitido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorActualizarEstadoDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorActualizarEstadoDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorActualizarEstadoDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorActualizarEstadoDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaArchivarDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaArchivarDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoDocumentoTrabajoArchivado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoDocumentoTrabajoArchivado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBorrarLineasDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBorrarLineasDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEditarLineasDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEditarLineasDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDejarCompartirDocumentoTrabajoSoloPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDejarCompartirDocumentoTrabajoSoloPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDestinoCompartidoObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDestinoCompartidoObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBorrarEfectoVentaRemesado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBorrarEfectoVentaRemesado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBorrarEfectoVentaCobrado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBorrarEfectoVentaCobrado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFusionarEfectosVentaEstado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFusionarEfectosVentaEstado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFusionarEfectosVentaOrigen',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFusionarEfectosVentaOrigen);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFusionarEfectosVentaSinPendiente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFusionarEfectosVentaSinPendiente);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorOperacionIntracomunitariaClienteNoUE',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorOperacionIntracomunitariaClienteNoUE);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorOperacionExportacionClienteNoExtranjero',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorOperacionExportacionClienteNoExtranjero);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorNifIvaClienteExtranjero',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorNifIvaClienteExtranjero);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRazonSocialClienteBorrador',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRazonSocialClienteBorrador);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorPaisClienteEmpresaBorrador',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorPaisClienteEmpresaBorrador);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaBorrarPedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaBorrarPedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCabeceraPedidoSinGrabar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCabeceraPedidoSinGrabar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAsignarLineaPedido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAsignarLineaPedido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoAlmacenSalidaPedidoObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoAlmacenSalidaPedidoObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoClientePedidoObligatorio',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoClientePedidoObligatorio);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoClientePedidoNoExiste',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoClientePedidoNoExiste);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaVentaNoSeleccionada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaVentaNoSeleccionada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaVentaNoEncontrada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaVentaNoEncontrada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaVentaSinEfectosPendientes',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaVentaSinEfectosPendientes);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorGuardarCodigoAcreedorSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorGuardarCodigoAcreedorSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorGuardarMandatoSepaCliente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorGuardarMandatoSepaCliente);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaCrearDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaCrearDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloAgregarDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloAgregarDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloNuevoDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloNuevoDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SSolicitudTituloDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SSolicitudTituloDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoUnidadAgregadaDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoUnidadAgregadaDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoLineaPedidoTallaNoExiste',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoLineaPedidoTallaNoExiste);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContextoSinIban',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContextoSinIban);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContextoIbanNoValido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContextoIbanNoValido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorNifEmpresaAcreedorSepaNoValido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorNifEmpresaAcreedorSepaNoValido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClienteSinMandatoSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClienteSinMandatoSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'STextoBancoCobroRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STextoBancoCobroRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorConexionGenerarRemesaSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorConexionGenerarRemesaSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorArchivoSalidaSepaNoIndicado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorArchivoSalidaSepaNoIndicado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaSinFechaCobro',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaSinFechaCobro);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBancoCobroRemesaNoEncontrado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBancoCobroRemesaNoEncontrado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBancoCobroSinCodigoAcreedorSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBancoCobroSinCodigoAcreedorSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCodigoAcreedorSepaNoValido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCodigoAcreedorSepaNoValido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectoSinNombreCliente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectoSinNombreCliente);
  ARegistrar(
    'inLibMsgVentas.' +
    'STextoClienteSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STextoClienteSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClienteSinFechaFirmaMandatoSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClienteSinFechaFirmaMandatoSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaAbrirSeriesAlbaranVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaAbrirSeriesAlbaranVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlbaranVentaNoAbierto',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlbaranVentaNoAbierto);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlbaranVentaNoInicializado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlbaranVentaNoInicializado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCrearSeleccionarAlbaranAntesLineas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCrearSeleccionarAlbaranAntesLineas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaEliminarLineaAlbaranVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaEliminarLineaAlbaranVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlbaranVentaSinLineas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlbaranVentaSinLineas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoSeleccionarLineasBorradorAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoSeleccionarLineasBorradorAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoLineasAlbaranConBorrador',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoLineasAlbaranConBorrador);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaGenerarBorradorLineasAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaGenerarBorradorLineasAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaGenerarBorradorTodoAlbaran',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaGenerarBorradorTodoAlbaran);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoAlbaranSinPedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoAlbaranSinPedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoAlbaranSinBorrador',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoAlbaranSinBorrador);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoIbanValidado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoIbanValidado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectosVentaFusionInsuficientes',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectosVentaFusionInsuficientes);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoNoSeleccionadoListado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoNoSeleccionadoListado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinGrabarListado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinGrabarListado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinLineasListado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinLineasListado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoNoSeleccionadoCargar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoNoSeleccionadoCargar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCargarDocumentoTrabajoNoPropietario',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCargarDocumentoTrabajoNoPropietario);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinGrabarCargar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinGrabarCargar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoNoSeleccionadoCompartir',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoNoSeleccionadoCompartir);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoDocumentoTrabajoCompartido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoDocumentoTrabajoCompartido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoDocumentoTrabajoYaCompartido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoDocumentoTrabajoYaCompartido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoNoSeleccionadoEnviar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoNoSeleccionadoEnviar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinGrabarEnviar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinGrabarEnviar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDocumentoTrabajoSinLineasEnviar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDocumentoTrabajoSinLineasEnviar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContadorAlbaranDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContadorAlbaranDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoAlbaranDocumentoTrabajoCreado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoAlbaranDocumentoTrabajoCreado);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloEnviarFacturaVentaDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloEnviarFacturaVentaDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContadorFacturaVentaDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContadorFacturaVentaDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoFacturaVentaDocumentoTrabajoCreada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoFacturaVentaDocumentoTrabajoCreada);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloEnviarPedidoCompraDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloEnviarPedidoCompraDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorContadorPedidoCompraDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorContadorPedidoCompraDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoPedidoCompraDocumentoTrabajoCreado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoPedidoCompraDocumentoTrabajoCreado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEmpresaDocumentoTrabajoNoExiste',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEmpresaDocumentoTrabajoNoExiste);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorVentaTpvNoAbiertaDocumentoTrabajo',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorVentaTpvNoAbiertaDocumentoTrabajo);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoLineasDocumentoTrabajoVolcadasTpv',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoLineasDocumentoTrabajoVolcadasTpv);
  ARegistrar(
    'inLibMsgVentas.' +
    'SAvisoLineasDocumentoTrabajoNoVolcadasTpv',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SAvisoLineasDocumentoTrabajoNoVolcadasTpv);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoImpresionEfectosCobroEnRemesas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoImpresionEfectosCobroEnRemesas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaAbrirSeriesPedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaAbrirSeriesPedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorPedidoVentaNoAbierto',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorPedidoVentaNoAbierto);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClienteNoSeleccionadoPedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClienteNoSeleccionadoPedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClientePedidoVentaNoExiste',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClientePedidoVentaNoExiste);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorPedidoVentaNoInicializado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorPedidoVentaNoInicializado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCrearSeleccionarPedidoAntesLineas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCrearSeleccionarPedidoAntesLineas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaEliminarLineaPedidoVentaConTallas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaEliminarLineaPedidoVentaConTallas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaEliminarLineaPedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaEliminarLineaPedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaMarcarLineasPendientesAlbaranar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaMarcarLineasPendientesAlbaranar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorPedidoVentaSinLineas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorPedidoVentaSinLineas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorPedidoVentaSinCantidadAlbaranar',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorPedidoVentaSinCantidadAlbaranar);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAnadirAlbaranDesdePedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAnadirAlbaranDesdePedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCrearAlbaranDesdePedidoVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCrearAlbaranDesdePedidoVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBancoPagoRemesaNoAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBancoPagoRemesaNoAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoBancoPagoRemesaAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoBancoPagoRemesaAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAsignarBancoPagoRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAsignarBancoPagoRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloFechaCargoRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloFechaCargoRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SSolicitudFechaCargoRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SSolicitudFechaCargoRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoFechaCargoRemesaActualizada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoFechaCargoRemesaActualizada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorActualizarFechaCargoRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorActualizarFechaCargoRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFechaCargoRemesaNoValida',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFechaCargoRemesaNoValida);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEliminarRemesaVentaConCobro',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEliminarRemesaVentaConCobro);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaEliminarRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaEliminarRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoRemesaVentaEliminada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoRemesaVentaEliminada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEliminarRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEliminarRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAnadirEfectosRemesaVentaConCobro',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAnadirEfectosRemesaVentaConCobro);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectosRemesaVentaNoCargados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectosRemesaVentaNoCargados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectoRemesaVentaNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectoRemesaVentaNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorQuitarEfectosRemesaVentaConCobro',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorQuitarEfectosRemesaVentaConCobro);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaQuitarEfectoRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaQuitarEfectoRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoEfectoRemesaVentaQuitado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoEfectoRemesaVentaQuitado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorQuitarEfectoRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorQuitarEfectoRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBancoCobroRemesaNoAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBancoCobroRemesaNoAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectoRemesaVentaSinPendiente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectoRemesaVentaSinPendiente);
  ARegistrar(
    'inLibMsgVentas.' +
    'STextoEfectoPendienteRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STextoEfectoPendienteRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoEfectoRemesaVentaConciliado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoEfectoRemesaVentaConciliado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorConciliarEfectoRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorConciliarEfectoRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaVentaSinImportePendiente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaVentaSinImportePendiente);
  ARegistrar(
    'inLibMsgVentas.' +
    'STextoRemesaVentaPendiente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STextoRemesaVentaPendiente);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoEfectosRemesaVentaConciliados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoEfectosRemesaVentaConciliados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorConciliarRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorConciliarRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBancoCobroNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBancoCobroNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoBancoCobroRemesaAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoBancoCobroRemesaAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAsignarBancoCobroRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAsignarBancoCobroRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloFechaCobroRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloFechaCobroRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SSolicitudFechaCobroRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SSolicitudFechaCobroRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoFechaCobroRemesaActualizada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoFechaCobroRemesaActualizada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorActualizarFechaCobroRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorActualizarFechaCobroRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFechaCobroRemesaNoValida',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFechaCobroRemesaNoValida);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoOrdenSepaRemesaVentaGenerada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoOrdenSepaRemesaVentaGenerada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorGenerarOrdenSepaRemesaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorGenerarOrdenSepaRemesaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDestinoDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDestinoDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlmacenesDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlmacenesDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SPreguntaConfirmarDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SPreguntaConfirmarDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionExcluirSkuDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionExcluirSkuDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoLineasDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoLineasDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorInsertarLineasDocumentoTrabajoAddBlock',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorInsertarLineasDocumentoTrabajoAddBlock);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEmpresaEfectosRemesaNoIndicada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEmpresaEfectosRemesaNoIndicada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoEfectosPendientesRemesaNoEncontrados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoEfectosPendientesRemesaNoEncontrados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorEfectosRemesaNoSeleccionados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorEfectosRemesaNoSeleccionados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorRemesaExistenteNoSeleccionada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorRemesaExistenteNoSeleccionada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoEfectosCargadosRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoEfectosCargadosRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorSerieAlbaranSesionNoIndicada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorSerieAlbaranSesionNoIndicada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorSeriePedidoSesionNoIndicada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorSeriePedidoSesionNoIndicada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoAlbaranesPendientesProveedorNoEncontrados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoAlbaranesPendientesProveedorNoEncontrados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorBorradorAlbaranesExistenteNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorBorradorAlbaranesExistenteNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoAlbaranesGeneradosEnBorrador',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoAlbaranesGeneradosEnBorrador);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDataModuleAlbaranesNoAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDataModuleAlbaranesNoAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlbaranesNoSeleccionados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlbaranesNoSeleccionados);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClienteBorradorNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClienteBorradorNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorDataModulePedidosNoAsignado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorDataModulePedidosNoAsignado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoImportacionPedidosFinalizada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoImportacionPedidosFinalizada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlmacenPedidoNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlmacenPedidoNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SInfoAlbaranesIncorporarNoDisponibles',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SInfoAlbaranesIncorporarNoDisponibles);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorSerieAlbaranPedidoNoIndicada',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorSerieAlbaranPedidoNoIndicada);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlmacenAlbaranNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlmacenAlbaranNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorAlbaranDestinoNoSeleccionado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorAlbaranDestinoNoSeleccionado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorCodigoAcreedorSepaNoIndicado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorCodigoAcreedorSepaNoIndicado);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorLongitudCodigoAcreedorSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorLongitudCodigoAcreedorSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorFormatoCodigoAcreedorSepaNoValido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorFormatoCodigoAcreedorSepaNoValido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorSecuenciaSepaNoValida',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorSecuenciaSepaNoValida);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClientesSinMandatoSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClientesSinMandatoSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorMandatosSepaLongitudNoValida',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorMandatosSepaLongitudNoValida);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorClientesSinFechaFirmaMandatoSepa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorClientesSinFechaFirmaMandatoSepa);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloImpresionEtiquetasDTR',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloImpresionEtiquetasDTR);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionTabLineasPedidoTallas3Filas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionTabLineasPedidoTallas3Filas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionTabTotalesPedido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionTabTotalesPedido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionTabLineasPedidoSku',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionTabLineasPedidoSku);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionTabLineasPedidoDesglose',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionTabLineasPedidoDesglose);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionLineasAnadidasAlbaranPedido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionLineasAnadidasAlbaranPedido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionAlbaranCreadoPedido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionAlbaranCreadoPedido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionCrearRemesa',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionCrearRemesa);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionDocumentoDestino',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionDocumentoDestino);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloAnadirBloqueDTR',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloAnadirBloqueDTR);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionBuscandoAlbaranes',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionBuscandoAlbaranes);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionAlbaranesEncontrados',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionAlbaranesEncontrados);
  ARegistrar(
    'inLibMsgVentas.' +
    'STituloBusquedaClientes',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      STituloBusquedaClientes);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionFiltrarInicioCompras',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionFiltrarInicioCompras);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionSoloArticulosConVentas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionSoloArticulosConVentas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionSoloEmitidas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionSoloEmitidas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionLineasCargadas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionLineasCargadas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionPrimeraVentaVacia',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionPrimeraVentaVacia);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionUltimaVentaVacia',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionUltimaVentaVacia);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionPrimeraVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionPrimeraVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionUltimaVenta',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionUltimaVenta);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionSinVentas',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionSinVentas);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionCrearAlbaranDesdePedido',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionCrearAlbaranDesdePedido);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionCodigoAcreedor',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionCodigoAcreedor);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionSecuencia',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionSecuencia);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionMandatosPorCliente',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionMandatosPorCliente);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionColCodigoMandato',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionColCodigoMandato);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionColClienteMandato',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionColClienteMandato);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionColMandato',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionColMandato);
  ARegistrar(
    'inLibMsgVentas.' +
    'SCaptionColFechaFirmaMandato',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SCaptionColFechaFirmaMandato);
  ARegistrar(
    'inLibMsgVentas.' +
    'SErrorVentasCalendarioNoRegistrado',
    'src/Lib/inLibMsgVentas.pas',
    @inLibMsgVentas.
      SErrorVentasCalendarioNoRegistrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRepositorioExportacionNoVerifactuNoRegistrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRepositorioExportacionNoVerifactuNoRegistrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRespuestaNtpNoValida',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRespuestaNtpNoValida);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoRelojFiscalCorrecto',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoRelojFiscalCorrecto);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRelojSistemaFueraMargenLegal',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRelojSistemaFueraMargenLegal);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorComprobarRelojFiscalNtp',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorComprobarRelojFiscalNtp);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorExportarNoVerifactuSinCertificado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorExportarNoVerifactuSinCertificado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorExportarNoVerifactuSinColumnasEventos',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorExportarNoVerifactuSinColumnasEventos);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorExportarNoVerifactuSinColumnasFacturacion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorExportarNoVerifactuSinColumnasFacturacion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorExportarNoVerifactuRegistrosSinFirma',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorExportarNoVerifactuRegistrosSinFirma);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorConexionExportarNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorConexionExportarNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorArchivoBaseExportacionNoIndicado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorArchivoBaseExportacionNoIndicado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoTipoError',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoTipoError);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoTipoAviso',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoTipoAviso);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SFormatoDetalleVerificacion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SFormatoDetalleVerificacion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorModoExportacionNoCoincide',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorModoExportacionNoCoincide);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorXmlFirmadoNoLegible',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorXmlFirmadoNoLegible);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaEventoRaizIncorrecta',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaEventoRaizIncorrecta);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoFirmadoNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoFirmadoNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaXadesNodoAeatIncorrecto',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaXadesNodoAeatIncorrecto);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaXadesSinCertificado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaXadesSinCertificado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaXadesSinSignedInfo',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaXadesSinSignedInfo);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCanonicalizacionFirmaAeat',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCanonicalizacionFirmaAeat);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorMetodoFirmaNoRsaSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorMetodoFirmaNoRsaSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorReferenciasSignedInfo',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorReferenciasSignedInfo);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorReferenciaDocumentoFirmado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorReferenciaDocumentoFirmado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorTransformacionFirmaEnveloped',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorTransformacionFirmaEnveloped);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDigestRegistroNoSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDigestRegistroNoSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorReferenciaSignedProperties',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorReferenciaSignedProperties);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCanonicalizacionSignedProperties',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCanonicalizacionSignedProperties);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDigestSignedPropertiesNoSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDigestSignedPropertiesNoSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorQualifyingPropertiesXades',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorQualifyingPropertiesXades);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorSignedPropertiesXades',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorSignedPropertiesXades);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorSigningCertificateXades',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorSigningCertificateXades);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorPoliticaFirmaAge',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorPoliticaFirmaAge);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIdentificadorPoliticaAge',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIdentificadorPoliticaAge);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDigestPoliticaAgeNoSha1',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDigestPoliticaAgeNoSha1);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDigestValuePoliticaAge',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDigestValuePoliticaAge);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorUrlPoliticaAge',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorUrlPoliticaAge);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SFormatoEtiquetaEvento',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SFormatoEtiquetaEvento);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoHashPropioNoSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoHashPropioNoSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SAvisoEventoPrimerHashAnteriorNoCero',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SAvisoEventoPrimerHashAnteriorNoCero);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoHashAnteriorNoCoincide',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoHashAnteriorNoCoincide);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoSinRegistroXmlFirmado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoSinRegistroXmlFirmado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoHuellaNoCoincide',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoHuellaNoCoincide);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoFirmaGuardadaSinFirmaXml',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoFirmaGuardadaSinFirmaXml);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoSinFirmaXades',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoSinFirmaXades);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoSignatureValueNoCoincide',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoSignatureValueNoCoincide);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEventoFirmaDigitalNoCoincide',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEventoFirmaDigitalNoCoincide);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFacturaSinFirmaDigitalXades',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFacturaSinFirmaDigitalXades);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoEventos',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoEventos);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFicheroEventosNoExiste',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFicheroEventosNoExiste);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFicheroEventosRaizIncorrecta',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFicheroEventosRaizIncorrecta);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFicheroEventosVacio',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFicheroEventosVacio);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorVerificarEventos',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorVerificarEventos);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoVerificacionCorrecta',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoVerificacionCorrecta);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SFormatoModoActual',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SFormatoModoActual);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SResumenVerificacionNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SResumenVerificacionNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorAbrirProveedorCriptografico',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorAbrirProveedorCriptografico);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCrearHashCriptografico',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCrearHashCriptografico);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCalcularHash',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCalcularHash);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorObtenerTamanoHash',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorObtenerTamanoHash);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorObtenerValorHash',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorObtenerValorHash);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorOperacionCriptografica',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorOperacionCriptografica);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorProveedorCertificadoSinSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorProveedorCertificadoSinSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoCertificadoTodaviaNoValido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoCertificadoTodaviaNoValido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoCertificadoCaducado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoCertificadoCaducado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCertificadoNoVigente',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCertificadoNoVigente);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCertificadoVigenteNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCertificadoVigenteNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCertificadoEmpresaNoConfigurado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCertificadoEmpresaNoConfigurado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCrearHashSha256Firma',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCrearHashSha256Firma);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCargarDatosFirma',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCargarDatosFirma);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCalcularTamanoFirmaSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCalcularTamanoFirmaSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmarSha256',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmarSha256);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCalcularTamanoFirmaNCrypt',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCalcularTamanoFirmaNCrypt);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaNCrypt',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaNCrypt);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorAbrirClavePrivadaCertificado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorAbrirClavePrivadaCertificado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorXmlMalFormadoCanonicalizar',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorXmlMalFormadoCanonicalizar);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorElementoRaizXmlNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorElementoRaizXmlNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNombreNodoRaizNoDeterminado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNombreNodoRaizNoDeterminado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCierreAperturaRaizNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCierreAperturaRaizNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCierreNodoRaizNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCierreNodoRaizNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCierreNodoNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCierreNodoNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifProductorEventoVerifactuInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifProductorEventoVerifactuInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEmpresaEventosVerifactuNoConfigurada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEmpresaEventosVerifactuNoConfigurada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifEmisorEventoNoVerifactuInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifEmisorEventoNoVerifactuInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEmpresaSinNifEmisionFiscal',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEmpresaSinNifEmisionFiscal);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifProductorVerifactuInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifProductorVerifactuInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCertificadoFiscalEmpresaNoUtilizable',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCertificadoFiscalEmpresaNoUtilizable);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaCertificadoNoVerifactuDesactivada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaCertificadoNoVerifactuDesactivada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorCertificadoEventosNoVerifactuNoConfigurado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorCertificadoEventosNoVerifactuNoConfigurado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmarEventoNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmarEventoNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRelojEventoNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRelojEventoNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoRegistroFacturacionNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoRegistroFacturacionNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFirmaRegistroNoVerifactuObligatoria',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFirmaRegistroNoVerifactuObligatoria);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifProductorSoftwareVerifactuInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifProductorSoftwareVerifactuInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifEmisorVerifactuInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifEmisorVerifactuInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFacturaRegistroFiscalNoEncontrada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFacturaRegistroFiscalNoEncontrada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SAvisoQrPngNoGenerado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SAvisoQrPngNoGenerado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorFacturaEnvioVerifactuNoEncontrada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorFacturaEnvioVerifactuNoEncontrada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRespuestaServicioInesperada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRespuestaServicioInesperada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRespuestaHttpAeat',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRespuestaHttpAeat);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorRespuestaRegistroAeat',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorRespuestaRegistroAeat);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEstadoEnvioAeat',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEstadoEnvioAeat);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorServicioInstalacionHttp',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorServicioInstalacionHttp);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorReferenciaGlobalInstalacionFaltante',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorReferenciaGlobalInstalacionFaltante);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorServicioJsonInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorServicioJsonInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorServicioSinNumeroInstalacion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorServicioSinNumeroInstalacion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorServicioSinDatosDeclaracion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorServicioSinDatosDeclaracion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDeclaracionVersionNoSolicitada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDeclaracionVersionNoSolicitada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDeclaracionSifIncorrecto',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDeclaracionSifIncorrecto);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDeclaracionDescargadaVacia',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDeclaracionDescargadaVacia);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorPaginaPublicaHttp',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorPaginaPublicaHttp);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDeclaracionPaginaPublicaOtraVersion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDeclaracionPaginaPublicaOtraVersion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorDeclaracionResponsableNoDisponible',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorDeclaracionResponsableNoDisponible);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEmpresaInstalacionSifNoConfigurada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEmpresaInstalacionSifNoConfigurada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEmpresaSinRazonSocial',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEmpresaSinRazonSocial);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNifEmpresaInstalacionInvalido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNifEmpresaInstalacionInvalido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorEmpresaSinNumeroInstalacionSif',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorEmpresaSinNumeroInstalacionSif);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNumeroInstalacionSifIncorrecto',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNumeroInstalacionSifIncorrecto);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorNumeroInstalacionSinVersion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorNumeroInstalacionSinVersion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorVersionNumeroInstalacionIncorrecta',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorVersionNumeroInstalacionIncorrecta);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoExportacionNoVerifactuGenerada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoExportacionNoVerifactuGenerada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoVerificacionNoVerifactuCorrecta',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoVerificacionNoVerifactuCorrecta);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorVerificacionNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorVerificacionNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAnulacionVerifactuEncolada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAnulacionVerifactuEncolada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAnulacionNoVerifactuRegistrada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAnulacionNoVerifactuRegistrada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAnulacionSinVerifactuRegistrada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAnulacionSinVerifactuRegistrada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAccionFiscalEncolada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAccionFiscalEncolada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAccionFiscalNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAccionFiscalNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoAccionFiscalSinVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoAccionFiscalSinVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaFacturaNoSeleccionada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaFacturaNoSeleccionada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaSoloVentaMayor',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaSoloVentaMayor);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaNoAceptadaConErrores',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaNoAceptadaConErrores);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaSubsanacionActiva',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaSubsanacionActiva);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaMotivoObligatorio',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaMotivoObligatorio);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaClienteObligatorio',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaClienteObligatorio);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaSerieRectificativaObligatoria',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaSerieRectificativaObligatoria);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaFechaRectificativaObligatoria',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaFechaRectificativaObligatoria);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaClienteNoEncontrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaClienteNoEncontrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaClienteSinNif',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaClienteSinNif);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaRectificativaExistente',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaRectificativaExistente);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaCrearRectificativa',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaCrearRectificativa);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaEncolarSubsanacion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaEncolarSubsanacion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorIncidenciaEstadoCambio',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorIncidenciaEstadoCambio);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoIncidenciaSubsanacionEncolada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoIncidenciaSubsanacionEncolada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoIncidenciaRectificativaCreada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoIncidenciaRectificativaCreada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STituloResolverIncidenciaVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STituloResolverIncidenciaVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaSubsanar',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaSubsanar);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaRectificar',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaRectificar);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaCargarCliente',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaCargarCliente);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaResolver',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaResolver);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaCancelar',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaCancelar);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaFactura',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaFactura);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaErrorAeat',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaErrorAeat);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaDecision',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaDecision);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaMotivo',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaMotivo);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaClienteActual',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaClienteActual);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaClienteCorrecto',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaClienteCorrecto);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaSerieRectificativa',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaSerieRectificativa);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STextoIncidenciaFechaRectificativa',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STextoIncidenciaFechaRectificativa);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoBorradorVerifactuPendiente',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoBorradorVerifactuPendiente);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoBorradorNoVerifactuRegistrado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoBorradorNoVerifactuRegistrado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoBorradorSinVerifactuEmitido',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoBorradorSinVerifactuEmitido);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorPrepararImpresionDeclaracionResponsable',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorPrepararImpresionDeclaracionResponsable);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorImprimirDeclaracionResponsable',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorImprimirDeclaracionResponsable);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SInfoNumeroInstalacionSifDisponible',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SInfoNumeroInstalacionSifDisponible);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SErrorGenerarNumeroInstalacionSif',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SErrorGenerarNumeroInstalacionSif);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionNumeroPendiente',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionNumeroPendiente);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionInstalacionSifTitulo',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionInstalacionSifTitulo);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionInstalacionNumeroVersion',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionInstalacionNumeroVersion);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionInstalacionSif',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionInstalacionSif);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionSinEmpresaConfigurada',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionSinEmpresaConfigurada);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionErrorLeerEmpresas',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionErrorLeerEmpresas);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionSolicitandoNumeroServicio',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionSolicitandoNumeroServicio);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'SCaptionNumeroDisponibleGuardado',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      SCaptionNumeroDisponibleGuardado);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STituloGuardarExportacionNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STituloGuardarExportacionNoVerifactu);
  ARegistrar(
    'inLibMsgVerifactu.' +
    'STituloVerificarFicherosNoVerifactu',
    'src/Lib/inLibMsgVerifactu.pas',
    @inLibMsgVerifactu.
      STituloVerificarFicherosNoVerifactu);
{$IF DECLARED(SSelectADate)}
  ARegistrar(
    'Vcl.Consts.' +
    'SSelectADate',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SSelectADate);
{$ENDIF}
{$IF DECLARED(SOpenFileTitle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOpenFileTitle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOpenFileTitle);
{$ENDIF}
{$IF DECLARED(SCantWriteResourceStreamError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCantWriteResourceStreamError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCantWriteResourceStreamError);
{$ENDIF}
{$IF DECLARED(SDuplicateReference)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDuplicateReference',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDuplicateReference);
{$ENDIF}
{$IF DECLARED(SClassMismatch)}
  ARegistrar(
    'Vcl.Consts.' +
    'SClassMismatch',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SClassMismatch);
{$ENDIF}
{$IF DECLARED(SInvalidTabIndex)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidTabIndex',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidTabIndex);
{$ENDIF}
{$IF DECLARED(SInvalidTabPosition)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidTabPosition',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidTabPosition);
{$ENDIF}
{$IF DECLARED(SInvalidTabStyle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidTabStyle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidTabStyle);
{$ENDIF}
{$IF DECLARED(SInvalidBitmap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidBitmap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidBitmap);
{$ENDIF}
{$IF DECLARED(SInvalidIcon)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidIcon',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidIcon);
{$ENDIF}
{$IF DECLARED(SInvalidMetafile)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidMetafile',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidMetafile);
{$ENDIF}
{$IF DECLARED(SInvalidPixelFormat)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidPixelFormat',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidPixelFormat);
{$ENDIF}
{$IF DECLARED(SInvalidImage)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidImage',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidImage);
{$ENDIF}
{$IF DECLARED(SBitmapEmpty)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBitmapEmpty',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBitmapEmpty);
{$ENDIF}
{$IF DECLARED(SScanLine)}
  ARegistrar(
    'Vcl.Consts.' +
    'SScanLine',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SScanLine);
{$ENDIF}
{$IF DECLARED(SChangeIconSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'SChangeIconSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SChangeIconSize);
{$ENDIF}
{$IF DECLARED(SChangeWicSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'SChangeWicSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SChangeWicSize);
{$ENDIF}
{$IF DECLARED(SOleGraphic)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOleGraphic',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOleGraphic);
{$ENDIF}
{$IF DECLARED(SUnknownExtension)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnknownExtension',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnknownExtension);
{$ENDIF}
{$IF DECLARED(SUnknownClipboardFormat)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnknownClipboardFormat',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnknownClipboardFormat);
{$ENDIF}
{$IF DECLARED(SUnknownStreamFormat)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnknownStreamFormat',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnknownStreamFormat);
{$ENDIF}
{$IF DECLARED(SOutOfResources)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutOfResources',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutOfResources);
{$ENDIF}
{$IF DECLARED(SNoCanvasHandle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoCanvasHandle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoCanvasHandle);
{$ENDIF}
{$IF DECLARED(SInvalidTextFormatFlag)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidTextFormatFlag',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidTextFormatFlag);
{$ENDIF}
{$IF DECLARED(SInvalidFrameIndex)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidFrameIndex',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidFrameIndex);
{$ENDIF}
{$IF DECLARED(SInvalidImageSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidImageSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidImageSize);
{$ENDIF}
{$IF DECLARED(STooManyImages)}
  ARegistrar(
    'Vcl.Consts.' +
    'STooManyImages',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STooManyImages);
{$ENDIF}
{$IF DECLARED(SDimsDoNotMatch)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDimsDoNotMatch',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDimsDoNotMatch);
{$ENDIF}
{$IF DECLARED(SInvalidImageList)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidImageList',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidImageList);
{$ENDIF}
{$IF DECLARED(SReplaceImage)}
  ARegistrar(
    'Vcl.Consts.' +
    'SReplaceImage',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SReplaceImage);
{$ENDIF}
{$IF DECLARED(SInsertImage)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInsertImage',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInsertImage);
{$ENDIF}
{$IF DECLARED(SImageIndexError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SImageIndexError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SImageIndexError);
{$ENDIF}
{$IF DECLARED(SImageReadFail)}
  ARegistrar(
    'Vcl.Consts.' +
    'SImageReadFail',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SImageReadFail);
{$ENDIF}
{$IF DECLARED(SImageWriteFail)}
  ARegistrar(
    'Vcl.Consts.' +
    'SImageWriteFail',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SImageWriteFail);
{$ENDIF}
{$IF DECLARED(SWindowDCError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SWindowDCError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SWindowDCError);
{$ENDIF}
{$IF DECLARED(SClientNotSet)}
  ARegistrar(
    'Vcl.Consts.' +
    'SClientNotSet',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SClientNotSet);
{$ENDIF}
{$IF DECLARED(SWindowClass)}
  ARegistrar(
    'Vcl.Consts.' +
    'SWindowClass',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SWindowClass);
{$ENDIF}
{$IF DECLARED(SWindowCreate)}
  ARegistrar(
    'Vcl.Consts.' +
    'SWindowCreate',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SWindowCreate);
{$ENDIF}
{$IF DECLARED(SCannotFocus)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotFocus',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotFocus);
{$ENDIF}
{$IF DECLARED(SParentRequired)}
  ARegistrar(
    'Vcl.Consts.' +
    'SParentRequired',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SParentRequired);
{$ENDIF}
{$IF DECLARED(SControlPath)}
  ARegistrar(
    'Vcl.Consts.' +
    'SControlPath',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SControlPath);
{$ENDIF}
{$IF DECLARED(SParentGivenNotAParent)}
  ARegistrar(
    'Vcl.Consts.' +
    'SParentGivenNotAParent',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SParentGivenNotAParent);
{$ENDIF}
{$IF DECLARED(SMDIChildNotVisible)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMDIChildNotVisible',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMDIChildNotVisible);
{$ENDIF}
{$IF DECLARED(SVisibleChanged)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVisibleChanged',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVisibleChanged);
{$ENDIF}
{$IF DECLARED(SCannotShowModal)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotShowModal',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotShowModal);
{$ENDIF}
{$IF DECLARED(SScrollBarRange)}
  ARegistrar(
    'Vcl.Consts.' +
    'SScrollBarRange',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SScrollBarRange);
{$ENDIF}
{$IF DECLARED(SPropertyOutOfRange)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPropertyOutOfRange',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPropertyOutOfRange);
{$ENDIF}
{$IF DECLARED(SMenuIndexError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMenuIndexError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMenuIndexError);
{$ENDIF}
{$IF DECLARED(SCannotSetCheckState)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotSetCheckState',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotSetCheckState);
{$ENDIF}
{$IF DECLARED(SInvalidCheckState)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCheckState',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCheckState);
{$ENDIF}
{$IF DECLARED(SMenuReinserted)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMenuReinserted',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMenuReinserted);
{$ENDIF}
{$IF DECLARED(SMenuNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMenuNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMenuNotFound);
{$ENDIF}
{$IF DECLARED(SNoTimers)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoTimers',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoTimers);
{$ENDIF}
{$IF DECLARED(SNotPrinting)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNotPrinting',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNotPrinting);
{$ENDIF}
{$IF DECLARED(SPrinting)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPrinting',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPrinting);
{$ENDIF}
{$IF DECLARED(SPrinterIndexError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPrinterIndexError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPrinterIndexError);
{$ENDIF}
{$IF DECLARED(SInvalidPrinter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidPrinter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidPrinter);
{$ENDIF}
{$IF DECLARED(SDeviceOnPort)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDeviceOnPort',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDeviceOnPort);
{$ENDIF}
{$IF DECLARED(SGroupIndexTooLow)}
  ARegistrar(
    'Vcl.Consts.' +
    'SGroupIndexTooLow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SGroupIndexTooLow);
{$ENDIF}
{$IF DECLARED(STwoMDIForms)}
  ARegistrar(
    'Vcl.Consts.' +
    'STwoMDIForms',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STwoMDIForms);
{$ENDIF}
{$IF DECLARED(SNoMDIForm)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoMDIForm',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoMDIForm);
{$ENDIF}
{$IF DECLARED(SImageCanvasNeedsBitmap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SImageCanvasNeedsBitmap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SImageCanvasNeedsBitmap);
{$ENDIF}
{$IF DECLARED(SControlParentSetToSelf)}
  ARegistrar(
    'Vcl.Consts.' +
    'SControlParentSetToSelf',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SControlParentSetToSelf);
{$ENDIF}
{$IF DECLARED(SControlNonMainThreadUsage)}
  ARegistrar(
    'Vcl.Consts.' +
    'SControlNonMainThreadUsage',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SControlNonMainThreadUsage);
{$ENDIF}
{$IF DECLARED(SOKButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOKButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOKButton);
{$ENDIF}
{$IF DECLARED(SCancelButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCancelButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCancelButton);
{$ENDIF}
{$IF DECLARED(SYesButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SYesButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SYesButton);
{$ENDIF}
{$IF DECLARED(SNoButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoButton);
{$ENDIF}
{$IF DECLARED(SHelpButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SHelpButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SHelpButton);
{$ENDIF}
{$IF DECLARED(SCloseButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCloseButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCloseButton);
{$ENDIF}
{$IF DECLARED(SIgnoreButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SIgnoreButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SIgnoreButton);
{$ENDIF}
{$IF DECLARED(SRetryButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SRetryButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SRetryButton);
{$ENDIF}
{$IF DECLARED(SAbortButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAbortButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAbortButton);
{$ENDIF}
{$IF DECLARED(SAllButton)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAllButton',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAllButton);
{$ENDIF}
{$IF DECLARED(SCannotDragForm)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotDragForm',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotDragForm);
{$ENDIF}
{$IF DECLARED(SPutObjectError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPutObjectError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPutObjectError);
{$ENDIF}
{$IF DECLARED(SCardDLLNotLoaded)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCardDLLNotLoaded',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCardDLLNotLoaded);
{$ENDIF}
{$IF DECLARED(SDuplicateCardId)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDuplicateCardId',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDuplicateCardId);
{$ENDIF}
{$IF DECLARED(SDdeErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDdeErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDdeErr);
{$ENDIF}
{$IF DECLARED(SDdeConvErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDdeConvErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDdeConvErr);
{$ENDIF}
{$IF DECLARED(SDdeMemErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDdeMemErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDdeMemErr);
{$ENDIF}
{$IF DECLARED(SDdeNoConnect)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDdeNoConnect',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDdeNoConnect);
{$ENDIF}
{$IF DECLARED(SFB)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFB',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFB);
{$ENDIF}
{$IF DECLARED(SFG)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFG',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFG);
{$ENDIF}
{$IF DECLARED(SBG)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBG',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBG);
{$ENDIF}
{$IF DECLARED(SOldTShape)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOldTShape',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOldTShape);
{$ENDIF}
{$IF DECLARED(SVMetafiles)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVMetafiles',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVMetafiles);
{$ENDIF}
{$IF DECLARED(SVEnhMetafiles)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVEnhMetafiles',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVEnhMetafiles);
{$ENDIF}
{$IF DECLARED(SVIcons)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVIcons',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVIcons);
{$ENDIF}
{$IF DECLARED(SVBitmaps)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVBitmaps',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVBitmaps);
{$ENDIF}
{$IF DECLARED(SVTIFFImages)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVTIFFImages',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVTIFFImages);
{$ENDIF}
{$IF DECLARED(SVJPGImages)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVJPGImages',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVJPGImages);
{$ENDIF}
{$IF DECLARED(SVPNGImages)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVPNGImages',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVPNGImages);
{$ENDIF}
{$IF DECLARED(SVGIFImages)}
  ARegistrar(
    'Vcl.Consts.' +
    'SVGIFImages',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SVGIFImages);
{$ENDIF}
{$IF DECLARED(SGridTooLarge)}
  ARegistrar(
    'Vcl.Consts.' +
    'SGridTooLarge',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SGridTooLarge);
{$ENDIF}
{$IF DECLARED(STooManyDeleted)}
  ARegistrar(
    'Vcl.Consts.' +
    'STooManyDeleted',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STooManyDeleted);
{$ENDIF}
{$IF DECLARED(SIndexOutOfRange)}
  ARegistrar(
    'Vcl.Consts.' +
    'SIndexOutOfRange',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SIndexOutOfRange);
{$ENDIF}
{$IF DECLARED(SFixedColTooBig)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFixedColTooBig',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFixedColTooBig);
{$ENDIF}
{$IF DECLARED(SFixedRowTooBig)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFixedRowTooBig',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFixedRowTooBig);
{$ENDIF}
{$IF DECLARED(SInvalidStringGridOp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidStringGridOp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidStringGridOp);
{$ENDIF}
{$IF DECLARED(SInvalidEnumValue)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidEnumValue',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidEnumValue);
{$ENDIF}
{$IF DECLARED(SInvalidNumber)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidNumber',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidNumber);
{$ENDIF}
{$IF DECLARED(SOutlineIndexError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineIndexError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineIndexError);
{$ENDIF}
{$IF DECLARED(SOutlineExpandError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineExpandError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineExpandError);
{$ENDIF}
{$IF DECLARED(SInvalidCurrentItem)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCurrentItem',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCurrentItem);
{$ENDIF}
{$IF DECLARED(SMaskErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMaskErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMaskErr);
{$ENDIF}
{$IF DECLARED(SMaskEditErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMaskEditErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMaskEditErr);
{$ENDIF}
{$IF DECLARED(SOutlineError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineError);
{$ENDIF}
{$IF DECLARED(SOutlineBadLevel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineBadLevel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineBadLevel);
{$ENDIF}
{$IF DECLARED(SOutlineSelection)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineSelection',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineSelection);
{$ENDIF}
{$IF DECLARED(SOutlineFileLoad)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineFileLoad',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineFileLoad);
{$ENDIF}
{$IF DECLARED(SOutlineLongLine)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineLongLine',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineLongLine);
{$ENDIF}
{$IF DECLARED(SOutlineMaxLevels)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutlineMaxLevels',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutlineMaxLevels);
{$ENDIF}
{$IF DECLARED(SMsgDlgWarning)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgWarning',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgWarning);
{$ENDIF}
{$IF DECLARED(SMsgDlgError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgError);
{$ENDIF}
{$IF DECLARED(SMsgDlgInformation)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgInformation',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgInformation);
{$ENDIF}
{$IF DECLARED(SMsgDlgConfirm)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgConfirm',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgConfirm);
{$ENDIF}
{$IF DECLARED(SMsgDlgYes)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgYes',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgYes);
{$ENDIF}
{$IF DECLARED(SMsgDlgNo)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgNo',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgNo);
{$ENDIF}
{$IF DECLARED(SMsgDlgOK)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgOK',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgOK);
{$ENDIF}
{$IF DECLARED(SMsgDlgCancel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgCancel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgCancel);
{$ENDIF}
{$IF DECLARED(SMsgDlgHelp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgHelp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgHelp);
{$ENDIF}
{$IF DECLARED(SMsgDlgHelpNone)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgHelpNone',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgHelpNone);
{$ENDIF}
{$IF DECLARED(SMsgDlgHelpHelp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgHelpHelp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgHelpHelp);
{$ENDIF}
{$IF DECLARED(SMsgDlgAbort)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgAbort',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgAbort);
{$ENDIF}
{$IF DECLARED(SMsgDlgRetry)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgRetry',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgRetry);
{$ENDIF}
{$IF DECLARED(SMsgDlgIgnore)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgIgnore',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgIgnore);
{$ENDIF}
{$IF DECLARED(SMsgDlgAll)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgAll',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgAll);
{$ENDIF}
{$IF DECLARED(SMsgDlgNoToAll)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgNoToAll',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgNoToAll);
{$ENDIF}
{$IF DECLARED(SMsgDlgYesToAll)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgYesToAll',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgYesToAll);
{$ENDIF}
{$IF DECLARED(SMsgDlgClose)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMsgDlgClose',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMsgDlgClose);
{$ENDIF}
{$IF DECLARED(SmkcBkSp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcBkSp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcBkSp);
{$ENDIF}
{$IF DECLARED(SmkcTab)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcTab',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcTab);
{$ENDIF}
{$IF DECLARED(SmkcEsc)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcEsc',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcEsc);
{$ENDIF}
{$IF DECLARED(SmkcEnter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcEnter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcEnter);
{$ENDIF}
{$IF DECLARED(SmkcSpace)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcSpace',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcSpace);
{$ENDIF}
{$IF DECLARED(SmkcPgUp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcPgUp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcPgUp);
{$ENDIF}
{$IF DECLARED(SmkcPgDn)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcPgDn',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcPgDn);
{$ENDIF}
{$IF DECLARED(SmkcEnd)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcEnd',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcEnd);
{$ENDIF}
{$IF DECLARED(SmkcHome)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcHome',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcHome);
{$ENDIF}
{$IF DECLARED(SmkcLeft)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcLeft',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcLeft);
{$ENDIF}
{$IF DECLARED(SmkcUp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcUp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcUp);
{$ENDIF}
{$IF DECLARED(SmkcRight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcRight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcRight);
{$ENDIF}
{$IF DECLARED(SmkcDown)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcDown',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcDown);
{$ENDIF}
{$IF DECLARED(SmkcIns)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcIns',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcIns);
{$ENDIF}
{$IF DECLARED(SmkcDel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcDel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcDel);
{$ENDIF}
{$IF DECLARED(SmkcShift)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcShift',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcShift);
{$ENDIF}
{$IF DECLARED(SmkcCtrl)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcCtrl',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcCtrl);
{$ENDIF}
{$IF DECLARED(SmkcAlt)}
  ARegistrar(
    'Vcl.Consts.' +
    'SmkcAlt',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SmkcAlt);
{$ENDIF}
{$IF DECLARED(srUnknown)}
  ARegistrar(
    'Vcl.Consts.' +
    'srUnknown',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      srUnknown);
{$ENDIF}
{$IF DECLARED(srNone)}
  ARegistrar(
    'Vcl.Consts.' +
    'srNone',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      srNone);
{$ENDIF}
{$IF DECLARED(SOutOfRange)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOutOfRange',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOutOfRange);
{$ENDIF}
{$IF DECLARED(SDateEncodeError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDateEncodeError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDateEncodeError);
{$ENDIF}
{$IF DECLARED(SDefaultFilter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDefaultFilter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDefaultFilter);
{$ENDIF}
{$IF DECLARED(sAllFilter)}
  ARegistrar(
    'Vcl.Consts.' +
    'sAllFilter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sAllFilter);
{$ENDIF}
{$IF DECLARED(SNoVolumeLabel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoVolumeLabel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoVolumeLabel);
{$ENDIF}
{$IF DECLARED(SInsertLineError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInsertLineError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInsertLineError);
{$ENDIF}
{$IF DECLARED(SConfirmCreateDir)}
  ARegistrar(
    'Vcl.Consts.' +
    'SConfirmCreateDir',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SConfirmCreateDir);
{$ENDIF}
{$IF DECLARED(SSelectDirCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SSelectDirCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SSelectDirCap);
{$ENDIF}
{$IF DECLARED(SDirNameCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDirNameCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDirNameCap);
{$ENDIF}
{$IF DECLARED(SDrivesCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDrivesCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDrivesCap);
{$ENDIF}
{$IF DECLARED(SDirsCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDirsCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDirsCap);
{$ENDIF}
{$IF DECLARED(SFilesCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFilesCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFilesCap);
{$ENDIF}
{$IF DECLARED(SNetworkCap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNetworkCap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNetworkCap);
{$ENDIF}
{$IF DECLARED(SColorPrefix)}
  ARegistrar(
    'Vcl.Consts.' +
    'SColorPrefix',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SColorPrefix);
{$ENDIF}
{$IF DECLARED(SColorTags)}
  ARegistrar(
    'Vcl.Consts.' +
    'SColorTags',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SColorTags);
{$ENDIF}
{$IF DECLARED(SInvalidClipFmt)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidClipFmt',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidClipFmt);
{$ENDIF}
{$IF DECLARED(SIconToClipboard)}
  ARegistrar(
    'Vcl.Consts.' +
    'SIconToClipboard',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SIconToClipboard);
{$ENDIF}
{$IF DECLARED(SCannotOpenClipboard)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotOpenClipboard',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotOpenClipboard);
{$ENDIF}
{$IF DECLARED(SDefault)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDefault',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDefault);
{$ENDIF}
{$IF DECLARED(SInvalidMemoSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidMemoSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidMemoSize);
{$ENDIF}
{$IF DECLARED(SCustomColors)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCustomColors',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCustomColors);
{$ENDIF}
{$IF DECLARED(SInvalidPrinterOp)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidPrinterOp',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidPrinterOp);
{$ENDIF}
{$IF DECLARED(SNoDefaultPrinter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoDefaultPrinter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoDefaultPrinter);
{$ENDIF}
{$IF DECLARED(SIniFileWriteError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SIniFileWriteError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SIniFileWriteError);
{$ENDIF}
{$IF DECLARED(SBitsIndexError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBitsIndexError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBitsIndexError);
{$ENDIF}
{$IF DECLARED(SUntitled)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUntitled',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUntitled);
{$ENDIF}
{$IF DECLARED(SInvalidRegType)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidRegType',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidRegType);
{$ENDIF}
{$IF DECLARED(SUnknownConversion)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnknownConversion',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnknownConversion);
{$ENDIF}
{$IF DECLARED(SDuplicateMenus)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDuplicateMenus',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDuplicateMenus);
{$ENDIF}
{$IF DECLARED(SPictureLabel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPictureLabel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPictureLabel);
{$ENDIF}
{$IF DECLARED(SPictureDesc)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPictureDesc',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPictureDesc);
{$ENDIF}
{$IF DECLARED(SPreviewLabel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPreviewLabel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPreviewLabel);
{$ENDIF}
{$IF DECLARED(SCannotOpenAVI)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotOpenAVI',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotOpenAVI);
{$ENDIF}
{$IF DECLARED(SNotOpenErr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNotOpenErr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNotOpenErr);
{$ENDIF}
{$IF DECLARED(SMPOpenFilter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMPOpenFilter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMPOpenFilter);
{$ENDIF}
{$IF DECLARED(SMCINil)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCINil',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCINil);
{$ENDIF}
{$IF DECLARED(SMCIAVIVideo)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIAVIVideo',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIAVIVideo);
{$ENDIF}
{$IF DECLARED(SMCICDAudio)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCICDAudio',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCICDAudio);
{$ENDIF}
{$IF DECLARED(SMCIDAT)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIDAT',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIDAT);
{$ENDIF}
{$IF DECLARED(SMCIDigitalVideo)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIDigitalVideo',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIDigitalVideo);
{$ENDIF}
{$IF DECLARED(SMCIMMMovie)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIMMMovie',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIMMMovie);
{$ENDIF}
{$IF DECLARED(SMCIOtro)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIOtro',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIOtro);
{$ENDIF}
{$IF DECLARED(SMCIOverlay)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIOverlay',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIOverlay);
{$ENDIF}
{$IF DECLARED(SMCIScanner)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIScanner',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIScanner);
{$ENDIF}
{$IF DECLARED(SMCISequencer)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCISequencer',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCISequencer);
{$ENDIF}
{$IF DECLARED(SMCIVCR)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIVCR',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIVCR);
{$ENDIF}
{$IF DECLARED(SMCIVideodisc)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIVideodisc',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIVideodisc);
{$ENDIF}
{$IF DECLARED(SMCIWaveAudio)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIWaveAudio',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIWaveAudio);
{$ENDIF}
{$IF DECLARED(SMCIUnknownError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMCIUnknownError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMCIUnknownError);
{$ENDIF}
{$IF DECLARED(SBoldItalicFont)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBoldItalicFont',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBoldItalicFont);
{$ENDIF}
{$IF DECLARED(SBoldFont)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBoldFont',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBoldFont);
{$ENDIF}
{$IF DECLARED(SItalicFont)}
  ARegistrar(
    'Vcl.Consts.' +
    'SItalicFont',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SItalicFont);
{$ENDIF}
{$IF DECLARED(SRegularFont)}
  ARegistrar(
    'Vcl.Consts.' +
    'SRegularFont',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SRegularFont);
{$ENDIF}
{$IF DECLARED(SPropertiesVerb)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPropertiesVerb',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPropertiesVerb);
{$ENDIF}
{$IF DECLARED(SServiceFailed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SServiceFailed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SServiceFailed);
{$ENDIF}
{$IF DECLARED(SExecute)}
  ARegistrar(
    'Vcl.Consts.' +
    'SExecute',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SExecute);
{$ENDIF}
{$IF DECLARED(SStart)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStart',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStart);
{$ENDIF}
{$IF DECLARED(SStop)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStop',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStop);
{$ENDIF}
{$IF DECLARED(SPause)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPause',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPause);
{$ENDIF}
{$IF DECLARED(SContinue)}
  ARegistrar(
    'Vcl.Consts.' +
    'SContinue',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SContinue);
{$ENDIF}
{$IF DECLARED(SInterrogate)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInterrogate',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInterrogate);
{$ENDIF}
{$IF DECLARED(SShutdown)}
  ARegistrar(
    'Vcl.Consts.' +
    'SShutdown',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SShutdown);
{$ENDIF}
{$IF DECLARED(SCustomError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCustomError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCustomError);
{$ENDIF}
{$IF DECLARED(SServiceInstallOK)}
  ARegistrar(
    'Vcl.Consts.' +
    'SServiceInstallOK',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SServiceInstallOK);
{$ENDIF}
{$IF DECLARED(SServiceInstallFailed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SServiceInstallFailed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SServiceInstallFailed);
{$ENDIF}
{$IF DECLARED(SServiceUninstallOK)}
  ARegistrar(
    'Vcl.Consts.' +
    'SServiceUninstallOK',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SServiceUninstallOK);
{$ENDIF}
{$IF DECLARED(SServiceUninstallFailed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SServiceUninstallFailed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SServiceUninstallFailed);
{$ENDIF}
{$IF DECLARED(SDockedCtlNeedsName)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDockedCtlNeedsName',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDockedCtlNeedsName);
{$ENDIF}
{$IF DECLARED(SDockTreeRemoveError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDockTreeRemoveError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDockTreeRemoveError);
{$ENDIF}
{$IF DECLARED(SDockZoneNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDockZoneNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDockZoneNotFound);
{$ENDIF}
{$IF DECLARED(SDockZoneHasNoCtl)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDockZoneHasNoCtl',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDockZoneHasNoCtl);
{$ENDIF}
{$IF DECLARED(SDockZoneVersionConflict)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDockZoneVersionConflict',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDockZoneVersionConflict);
{$ENDIF}
{$IF DECLARED(SAllCommands)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAllCommands',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAllCommands);
{$ENDIF}
{$IF DECLARED(SDuplicateItem)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDuplicateItem',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDuplicateItem);
{$ENDIF}
{$IF DECLARED(STextNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'STextNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STextNotFound);
{$ENDIF}
{$IF DECLARED(SBrowserExecError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBrowserExecError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBrowserExecError);
{$ENDIF}
{$IF DECLARED(SColorBoxCustomCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SColorBoxCustomCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SColorBoxCustomCaption);
{$ENDIF}
{$IF DECLARED(SMultiSelectRequired)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMultiSelectRequired',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMultiSelectRequired);
{$ENDIF}
{$IF DECLARED(SPromptArrayTooShort)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPromptArrayTooShort',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPromptArrayTooShort);
{$ENDIF}
{$IF DECLARED(SPromptArrayEmpty)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPromptArrayEmpty',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPromptArrayEmpty);
{$ENDIF}
{$IF DECLARED(SUsername)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUsername',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUsername);
{$ENDIF}
{$IF DECLARED(SPassword)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPassword',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPassword);
{$ENDIF}
{$IF DECLARED(SDomain)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDomain',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDomain);
{$ENDIF}
{$IF DECLARED(SLogin)}
  ARegistrar(
    'Vcl.Consts.' +
    'SLogin',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SLogin);
{$ENDIF}
{$IF DECLARED(SKeyCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SKeyCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SKeyCaption);
{$ENDIF}
{$IF DECLARED(SValueCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SValueCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SValueCaption);
{$ENDIF}
{$IF DECLARED(SKeyConflict)}
  ARegistrar(
    'Vcl.Consts.' +
    'SKeyConflict',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SKeyConflict);
{$ENDIF}
{$IF DECLARED(SKeyNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SKeyNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SKeyNotFound);
{$ENDIF}
{$IF DECLARED(SNoColumnMoving)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoColumnMoving',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoColumnMoving);
{$ENDIF}
{$IF DECLARED(SNoEqualsInKey)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoEqualsInKey',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoEqualsInKey);
{$ENDIF}
{$IF DECLARED(SSendError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SSendError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SSendError);
{$ENDIF}
{$IF DECLARED(SAssignSubItemError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAssignSubItemError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAssignSubItemError);
{$ENDIF}
{$IF DECLARED(SDeleteItemWithSubItems)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDeleteItemWithSubItems',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDeleteItemWithSubItems);
{$ENDIF}
{$IF DECLARED(SDeleteNotAllowed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDeleteNotAllowed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDeleteNotAllowed);
{$ENDIF}
{$IF DECLARED(SMoveNotAllowed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMoveNotAllowed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMoveNotAllowed);
{$ENDIF}
{$IF DECLARED(SMoreButtons)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMoreButtons',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMoreButtons);
{$ENDIF}
{$IF DECLARED(SErrorDownloadingURL)}
  ARegistrar(
    'Vcl.Consts.' +
    'SErrorDownloadingURL',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SErrorDownloadingURL);
{$ENDIF}
{$IF DECLARED(SUrlMonDllMissing)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUrlMonDllMissing',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUrlMonDllMissing);
{$ENDIF}
{$IF DECLARED(SAllActions)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAllActions',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAllActions);
{$ENDIF}
{$IF DECLARED(SNoCategory)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoCategory',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoCategory);
{$ENDIF}
{$IF DECLARED(SExpand)}
  ARegistrar(
    'Vcl.Consts.' +
    'SExpand',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SExpand);
{$ENDIF}
{$IF DECLARED(SErrorSettingPath)}
  ARegistrar(
    'Vcl.Consts.' +
    'SErrorSettingPath',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SErrorSettingPath);
{$ENDIF}
{$IF DECLARED(SLBPutError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SLBPutError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SLBPutError);
{$ENDIF}
{$IF DECLARED(SErrorLoadingFile)}
  ARegistrar(
    'Vcl.Consts.' +
    'SErrorLoadingFile',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SErrorLoadingFile);
{$ENDIF}
{$IF DECLARED(SResetUsageData)}
  ARegistrar(
    'Vcl.Consts.' +
    'SResetUsageData',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SResetUsageData);
{$ENDIF}
{$IF DECLARED(SFileRunDialogTitle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SFileRunDialogTitle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SFileRunDialogTitle);
{$ENDIF}
{$IF DECLARED(SNoName)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoName',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoName);
{$ENDIF}
{$IF DECLARED(SErrorActionManagerNotAssigned)}
  ARegistrar(
    'Vcl.Consts.' +
    'SErrorActionManagerNotAssigned',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SErrorActionManagerNotAssigned);
{$ENDIF}
{$IF DECLARED(SAddRemoveButtons)}
  ARegistrar(
    'Vcl.Consts.' +
    'SAddRemoveButtons',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SAddRemoveButtons);
{$ENDIF}
{$IF DECLARED(SResetActionToolBar)}
  ARegistrar(
    'Vcl.Consts.' +
    'SResetActionToolBar',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SResetActionToolBar);
{$ENDIF}
{$IF DECLARED(SPersonalizar)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPersonalizar',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPersonalizar);
{$ENDIF}
{$IF DECLARED(SSeparator)}
  ARegistrar(
    'Vcl.Consts.' +
    'SSeparator',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SSeparator);
{$ENDIF}
{$IF DECLARED(SCircularReferencesNotAllowed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCircularReferencesNotAllowed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCircularReferencesNotAllowed);
{$ENDIF}
{$IF DECLARED(SCannotHideActionBand)}
  ARegistrar(
    'Vcl.Consts.' +
    'SCannotHideActionBand',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SCannotHideActionBand);
{$ENDIF}
{$IF DECLARED(SErrorSettingCount)}
  ARegistrar(
    'Vcl.Consts.' +
    'SErrorSettingCount',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SErrorSettingCount);
{$ENDIF}
{$IF DECLARED(SListBoxMustBeVirtual)}
  ARegistrar(
    'Vcl.Consts.' +
    'SListBoxMustBeVirtual',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SListBoxMustBeVirtual);
{$ENDIF}
{$IF DECLARED(SUnableToSaveSettings)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnableToSaveSettings',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnableToSaveSettings);
{$ENDIF}
{$IF DECLARED(SRestoreDefaultSchedule)}
  ARegistrar(
    'Vcl.Consts.' +
    'SRestoreDefaultSchedule',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SRestoreDefaultSchedule);
{$ENDIF}
{$IF DECLARED(SNoGetItemEventHandler)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoGetItemEventHandler',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoGetItemEventHandler);
{$ENDIF}
{$IF DECLARED(SInvalidColorMap)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidColorMap',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidColorMap);
{$ENDIF}
{$IF DECLARED(SDuplicateActionBarStyleName)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDuplicateActionBarStyleName',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDuplicateActionBarStyleName);
{$ENDIF}
{$IF DECLARED(SMissingActionBarStyleName)}
  ARegistrar(
    'Vcl.Consts.' +
    'SMissingActionBarStyleName',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SMissingActionBarStyleName);
{$ENDIF}
{$IF DECLARED(SStandardStyleActionBars)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStandardStyleActionBars',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStandardStyleActionBars);
{$ENDIF}
{$IF DECLARED(SXPStyleActionBars)}
  ARegistrar(
    'Vcl.Consts.' +
    'SXPStyleActionBars',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SXPStyleActionBars);
{$ENDIF}
{$IF DECLARED(SActionBarStyleMissing)}
  ARegistrar(
    'Vcl.Consts.' +
    'SActionBarStyleMissing',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SActionBarStyleMissing);
{$ENDIF}
{$IF DECLARED(sParameterCannotBeNil)}
  ARegistrar(
    'Vcl.Consts.' +
    'sParameterCannotBeNil',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sParameterCannotBeNil);
{$ENDIF}
{$IF DECLARED(SInvalidColorString)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidColorString',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidColorString);
{$ENDIF}
{$IF DECLARED(SInvalidColor)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidColor',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidColor);
{$ENDIF}
{$IF DECLARED(SInvalidScaleImagePixelFormat)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidScaleImagePixelFormat',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidScaleImagePixelFormat);
{$ENDIF}
{$IF DECLARED(SInvalidPath)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidPath',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidPath);
{$ENDIF}
{$IF DECLARED(SInvalidPathCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidPathCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidPathCaption);
{$ENDIF}
{$IF DECLARED(SANSIEncoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SANSIEncoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SANSIEncoding);
{$ENDIF}
{$IF DECLARED(SASCIIEncoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SASCIIEncoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SASCIIEncoding);
{$ENDIF}
{$IF DECLARED(SUnicodeEncoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUnicodeEncoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUnicodeEncoding);
{$ENDIF}
{$IF DECLARED(SBigEndianEncoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SBigEndianEncoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SBigEndianEncoding);
{$ENDIF}
{$IF DECLARED(SUTF8Encoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUTF8Encoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUTF8Encoding);
{$ENDIF}
{$IF DECLARED(SUTF7Encoding)}
  ARegistrar(
    'Vcl.Consts.' +
    'SUTF7Encoding',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SUTF7Encoding);
{$ENDIF}
{$IF DECLARED(SEncodingLabel)}
  ARegistrar(
    'Vcl.Consts.' +
    'SEncodingLabel',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SEncodingLabel);
{$ENDIF}
{$IF DECLARED(sCannotAddToEmpty)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCannotAddToEmpty',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCannotAddToEmpty);
{$ENDIF}
{$IF DECLARED(sCannotAddFixedSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCannotAddFixedSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCannotAddFixedSize);
{$ENDIF}
{$IF DECLARED(sInvalidSpan)}
  ARegistrar(
    'Vcl.Consts.' +
    'sInvalidSpan',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sInvalidSpan);
{$ENDIF}
{$IF DECLARED(sInvalidRowIndex)}
  ARegistrar(
    'Vcl.Consts.' +
    'sInvalidRowIndex',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sInvalidRowIndex);
{$ENDIF}
{$IF DECLARED(sInvalidColumnIndex)}
  ARegistrar(
    'Vcl.Consts.' +
    'sInvalidColumnIndex',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sInvalidColumnIndex);
{$ENDIF}
{$IF DECLARED(sInvalidControlItem)}
  ARegistrar(
    'Vcl.Consts.' +
    'sInvalidControlItem',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sInvalidControlItem);
{$ENDIF}
{$IF DECLARED(sCannotDeleteColumn)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCannotDeleteColumn',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCannotDeleteColumn);
{$ENDIF}
{$IF DECLARED(sCannotDeleteRow)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCannotDeleteRow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCannotDeleteRow);
{$ENDIF}
{$IF DECLARED(sCellMember)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellMember',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellMember);
{$ENDIF}
{$IF DECLARED(sCellSizeType)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellSizeType',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellSizeType);
{$ENDIF}
{$IF DECLARED(sCellValue)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellValue',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellValue);
{$ENDIF}
{$IF DECLARED(sCellAutoSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellAutoSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellAutoSize);
{$ENDIF}
{$IF DECLARED(sCellPercentSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellPercentSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellPercentSize);
{$ENDIF}
{$IF DECLARED(sCellAbsoluteSize)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellAbsoluteSize',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellAbsoluteSize);
{$ENDIF}
{$IF DECLARED(sCellColumn)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellColumn',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellColumn);
{$ENDIF}
{$IF DECLARED(sCellRow)}
  ARegistrar(
    'Vcl.Consts.' +
    'sCellRow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sCellRow);
{$ENDIF}
{$IF DECLARED(STrayIconRemoveError)}
  ARegistrar(
    'Vcl.Consts.' +
    'STrayIconRemoveError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STrayIconRemoveError);
{$ENDIF}
{$IF DECLARED(STrayIconCreateError)}
  ARegistrar(
    'Vcl.Consts.' +
    'STrayIconCreateError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STrayIconCreateError);
{$ENDIF}
{$IF DECLARED(SPageControlNotSet)}
  ARegistrar(
    'Vcl.Consts.' +
    'SPageControlNotSet',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SPageControlNotSet);
{$ENDIF}
{$IF DECLARED(SWindowsVistaRequired)}
  ARegistrar(
    'Vcl.Consts.' +
    'SWindowsVistaRequired',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SWindowsVistaRequired);
{$ENDIF}
{$IF DECLARED(SXPThemesRequired)}
  ARegistrar(
    'Vcl.Consts.' +
    'SXPThemesRequired',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SXPThemesRequired);
{$ENDIF}
{$IF DECLARED(STaskDlgButtonCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'STaskDlgButtonCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STaskDlgButtonCaption);
{$ENDIF}
{$IF DECLARED(STaskDlgRadioButtonCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'STaskDlgRadioButtonCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      STaskDlgRadioButtonCaption);
{$ENDIF}
{$IF DECLARED(SInvalidTaskDlgButtonCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidTaskDlgButtonCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidTaskDlgButtonCaption);
{$ENDIF}
{$IF DECLARED(SInvalidCategoryPanelParent)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCategoryPanelParent',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCategoryPanelParent);
{$ENDIF}
{$IF DECLARED(SInvalidCategoryPanelGroupChild)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCategoryPanelGroupChild',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCategoryPanelGroupChild);
{$ENDIF}
{$IF DECLARED(SInvalidCanvasOperation)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCanvasOperation',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCanvasOperation);
{$ENDIF}
{$IF DECLARED(SNoOwner)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoOwner',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoOwner);
{$ENDIF}
{$IF DECLARED(SRequireSameOwner)}
  ARegistrar(
    'Vcl.Consts.' +
    'SRequireSameOwner',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SRequireSameOwner);
{$ENDIF}
{$IF DECLARED(SDirect2DInvalidOwner)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDirect2DInvalidOwner',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDirect2DInvalidOwner);
{$ENDIF}
{$IF DECLARED(SDirect2DInvalidSolidBrush)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDirect2DInvalidSolidBrush',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDirect2DInvalidSolidBrush);
{$ENDIF}
{$IF DECLARED(SDirect2DInvalidBrushStyle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SDirect2DInvalidBrushStyle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SDirect2DInvalidBrushStyle);
{$ENDIF}
{$IF DECLARED(SKeyboardLocaleInfo)}
  ARegistrar(
    'Vcl.Consts.' +
    'SKeyboardLocaleInfo',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SKeyboardLocaleInfo);
{$ENDIF}
{$IF DECLARED(SKeyboardLangChange)}
  ARegistrar(
    'Vcl.Consts.' +
    'SKeyboardLangChange',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SKeyboardLangChange);
{$ENDIF}
{$IF DECLARED(SOlyWinControls)}
  ARegistrar(
    'Vcl.Consts.' +
    'SOlyWinControls',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SOlyWinControls);
{$ENDIF}
{$IF DECLARED(SNoKeyword)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNoKeyword',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNoKeyword);
{$ENDIF}
{$IF DECLARED(SStyleLoadError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleLoadError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleLoadError);
{$ENDIF}
{$IF DECLARED(SStyleLoadErrors)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleLoadErrors',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleLoadErrors);
{$ENDIF}
{$IF DECLARED(SStyleRegisterError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleRegisterError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleRegisterError);
{$ENDIF}
{$IF DECLARED(SStyleClassRegisterError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleClassRegisterError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleClassRegisterError);
{$ENDIF}
{$IF DECLARED(SStyleNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleNotFound);
{$ENDIF}
{$IF DECLARED(SStyleClassNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleClassNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleClassNotFound);
{$ENDIF}
{$IF DECLARED(SStyleInvalidHandle)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleInvalidHandle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleInvalidHandle);
{$ENDIF}
{$IF DECLARED(SStyleFormatError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleFormatError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleFormatError);
{$ENDIF}
{$IF DECLARED(SStyleFileDescription)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleFileDescription',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleFileDescription);
{$ENDIF}
{$IF DECLARED(SStyleHookClassRegistered)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleHookClassRegistered',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleHookClassRegistered);
{$ENDIF}
{$IF DECLARED(SStyleHookClassNotRegistered)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleHookClassNotRegistered',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleHookClassNotRegistered);
{$ENDIF}
{$IF DECLARED(SStyleInvalidParameter)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleInvalidParameter',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleInvalidParameter);
{$ENDIF}
{$IF DECLARED(SStyleHookClassNotFound)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleHookClassNotFound',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleHookClassNotFound);
{$ENDIF}
{$IF DECLARED(SStyleFeatureNotSupported)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleFeatureNotSupported',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleFeatureNotSupported);
{$ENDIF}
{$IF DECLARED(SStyleNotRegistered)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleNotRegistered',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleNotRegistered);
{$ENDIF}
{$IF DECLARED(SStyleUnregisterError)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleUnregisterError',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleUnregisterError);
{$ENDIF}
{$IF DECLARED(SStyleNotRegisteredNoName)}
  ARegistrar(
    'Vcl.Consts.' +
    'SStyleNotRegisteredNoName',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SStyleNotRegisteredNoName);
{$ENDIF}
{$IF DECLARED(SNameBlack)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBlack',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBlack);
{$ENDIF}
{$IF DECLARED(SNameMaroon)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMaroon',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMaroon);
{$ENDIF}
{$IF DECLARED(SNameGreen)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameGreen',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameGreen);
{$ENDIF}
{$IF DECLARED(SNameOlive)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameOlive',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameOlive);
{$ENDIF}
{$IF DECLARED(SNameNavy)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameNavy',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameNavy);
{$ENDIF}
{$IF DECLARED(SNamePurple)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNamePurple',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNamePurple);
{$ENDIF}
{$IF DECLARED(SNameTeal)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameTeal',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameTeal);
{$ENDIF}
{$IF DECLARED(SNameGray)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameGray',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameGray);
{$ENDIF}
{$IF DECLARED(SNameSilver)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameSilver',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameSilver);
{$ENDIF}
{$IF DECLARED(SNameRed)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameRed',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameRed);
{$ENDIF}
{$IF DECLARED(SNameLime)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameLime',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameLime);
{$ENDIF}
{$IF DECLARED(SNameYellow)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameYellow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameYellow);
{$ENDIF}
{$IF DECLARED(SNameBlue)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBlue',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBlue);
{$ENDIF}
{$IF DECLARED(SNameFuchsia)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameFuchsia',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameFuchsia);
{$ENDIF}
{$IF DECLARED(SNameAqua)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameAqua',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameAqua);
{$ENDIF}
{$IF DECLARED(SNameWhite)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameWhite',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameWhite);
{$ENDIF}
{$IF DECLARED(SNameMoneyGreen)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMoneyGreen',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMoneyGreen);
{$ENDIF}
{$IF DECLARED(SNameSkyBlue)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameSkyBlue',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameSkyBlue);
{$ENDIF}
{$IF DECLARED(SNameCream)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameCream',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameCream);
{$ENDIF}
{$IF DECLARED(SNameMedGray)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMedGray',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMedGray);
{$ENDIF}
{$IF DECLARED(SNameActiveBorder)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameActiveBorder',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameActiveBorder);
{$ENDIF}
{$IF DECLARED(SNameActiveCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameActiveCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameActiveCaption);
{$ENDIF}
{$IF DECLARED(SNameAppWorkSpace)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameAppWorkSpace',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameAppWorkSpace);
{$ENDIF}
{$IF DECLARED(SNameBackground)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBackground',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBackground);
{$ENDIF}
{$IF DECLARED(SNameBtnFace)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBtnFace',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBtnFace);
{$ENDIF}
{$IF DECLARED(SNameBtnHighlight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBtnHighlight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBtnHighlight);
{$ENDIF}
{$IF DECLARED(SNameBtnShadow)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBtnShadow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBtnShadow);
{$ENDIF}
{$IF DECLARED(SNameBtnText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameBtnText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameBtnText);
{$ENDIF}
{$IF DECLARED(SNameCaptionText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameCaptionText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameCaptionText);
{$ENDIF}
{$IF DECLARED(SNameDefault)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameDefault',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameDefault);
{$ENDIF}
{$IF DECLARED(SNameGradientActiveCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameGradientActiveCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameGradientActiveCaption);
{$ENDIF}
{$IF DECLARED(SNameGradientInactiveCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameGradientInactiveCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameGradientInactiveCaption);
{$ENDIF}
{$IF DECLARED(SNameGrayText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameGrayText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameGrayText);
{$ENDIF}
{$IF DECLARED(SNameHighlight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameHighlight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameHighlight);
{$ENDIF}
{$IF DECLARED(SNameHighlightText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameHighlightText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameHighlightText);
{$ENDIF}
{$IF DECLARED(SNameHotLight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameHotLight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameHotLight);
{$ENDIF}
{$IF DECLARED(SNameInactiveBorder)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameInactiveBorder',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameInactiveBorder);
{$ENDIF}
{$IF DECLARED(SNameInactiveCaption)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameInactiveCaption',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameInactiveCaption);
{$ENDIF}
{$IF DECLARED(SNameInactiveCaptionText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameInactiveCaptionText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameInactiveCaptionText);
{$ENDIF}
{$IF DECLARED(SNameInfoBk)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameInfoBk',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameInfoBk);
{$ENDIF}
{$IF DECLARED(SNameInfoText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameInfoText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameInfoText);
{$ENDIF}
{$IF DECLARED(SNameMenu)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMenu',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMenu);
{$ENDIF}
{$IF DECLARED(SNameMenuBar)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMenuBar',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMenuBar);
{$ENDIF}
{$IF DECLARED(SNameMenuHighlight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMenuHighlight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMenuHighlight);
{$ENDIF}
{$IF DECLARED(SNameMenuText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameMenuText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameMenuText);
{$ENDIF}
{$IF DECLARED(SNameNone)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameNone',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameNone);
{$ENDIF}
{$IF DECLARED(SNameScrollBar)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameScrollBar',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameScrollBar);
{$ENDIF}
{$IF DECLARED(SName3DDkShadow)}
  ARegistrar(
    'Vcl.Consts.' +
    'SName3DDkShadow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SName3DDkShadow);
{$ENDIF}
{$IF DECLARED(SName3DLight)}
  ARegistrar(
    'Vcl.Consts.' +
    'SName3DLight',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SName3DLight);
{$ENDIF}
{$IF DECLARED(SNameWindow)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameWindow',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameWindow);
{$ENDIF}
{$IF DECLARED(SNameWindowFrame)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameWindowFrame',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameWindowFrame);
{$ENDIF}
{$IF DECLARED(SNameWindowText)}
  ARegistrar(
    'Vcl.Consts.' +
    'SNameWindowText',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SNameWindowText);
{$ENDIF}
{$IF DECLARED(SInvalidBitmapPixelFormat)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidBitmapPixelFormat',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidBitmapPixelFormat);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorGetpsi)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorGetpsi',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorGetpsi);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorInitializepropvar)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorInitializepropvar',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorInitializepropvar);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorSetps)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorSetps',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorSetps);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorCommitps)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorCommitps',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorCommitps);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorSettingarguments)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorSettingarguments',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorSettingarguments);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorSettingpath)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorSettingpath',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorSettingpath);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorSettingicon)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorSettingicon',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorSettingicon);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorAddingtobjarr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorAddingtobjarr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorAddingtobjarr);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorGettingobjarr)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorGettingobjarr',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorGettingobjarr);
{$ENDIF}
{$IF DECLARED(SJumplistsItemErrorNofriendlyname)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemErrorNofriendlyname',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemErrorNofriendlyname);
{$ENDIF}
{$IF DECLARED(SJumplistsItemException)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistsItemException',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistsItemException);
{$ENDIF}
{$IF DECLARED(SJumplistException)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistException',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistException);
{$ENDIF}
{$IF DECLARED(SJumplistErrorBeginlist)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorBeginlist',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorBeginlist);
{$ENDIF}
{$IF DECLARED(SJumplistErrorAppendrc)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorAppendrc',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorAppendrc);
{$ENDIF}
{$IF DECLARED(SJumplistErrorAppendfc)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorAppendfc',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorAppendfc);
{$ENDIF}
{$IF DECLARED(SJumplistErrorAddusertasks)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorAddusertasks',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorAddusertasks);
{$ENDIF}
{$IF DECLARED(SJumplistErrorAddcategory)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorAddcategory',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorAddcategory);
{$ENDIF}
{$IF DECLARED(SJumplistErrorCommitlist)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistErrorCommitlist',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistErrorCommitlist);
{$ENDIF}
{$IF DECLARED(SJumplistExceptionInvalidOS)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistExceptionInvalidOS',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistExceptionInvalidOS);
{$ENDIF}
{$IF DECLARED(sBeginInvokeNoHandle)}
  ARegistrar(
    'Vcl.Consts.' +
    'sBeginInvokeNoHandle',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      sBeginInvokeNoHandle);
{$ENDIF}
{$IF DECLARED(SToggleSwitchCaptionOn)}
  ARegistrar(
    'Vcl.Consts.' +
    'SToggleSwitchCaptionOn',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SToggleSwitchCaptionOn);
{$ENDIF}
{$IF DECLARED(SToggleSwitchCaptionOff)}
  ARegistrar(
    'Vcl.Consts.' +
    'SToggleSwitchCaptionOff',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SToggleSwitchCaptionOff);
{$ENDIF}
{$IF DECLARED(SInvalidRelativePanelControlItem)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidRelativePanelControlItem',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidRelativePanelControlItem);
{$ENDIF}
{$IF DECLARED(SInvalidRelativePanelSibling)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidRelativePanelSibling',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidRelativePanelSibling);
{$ENDIF}
{$IF DECLARED(SInvalidRelativePanelSiblingSelf)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidRelativePanelSiblingSelf',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidRelativePanelSiblingSelf);
{$ENDIF}
{$IF DECLARED(SRelativePanelCircularDependency)}
  ARegistrar(
    'Vcl.Consts.' +
    'SRelativePanelCircularDependency',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SRelativePanelCircularDependency);
{$ENDIF}
{$IF DECLARED(SInRemoteSession)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInRemoteSession',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInRemoteSession);
{$ENDIF}
{$IF DECLARED(SJumplistExceptionAppID)}
  ARegistrar(
    'Vcl.Consts.' +
    'SJumplistExceptionAppID',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SJumplistExceptionAppID);
{$ENDIF}
{$IF DECLARED(SInvalidCardPanelActiveCardIndex)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCardPanelActiveCardIndex',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCardPanelActiveCardIndex);
{$ENDIF}
{$IF DECLARED(SInvalidCardPanelActiveCard)}
  ARegistrar(
    'Vcl.Consts.' +
    'SInvalidCardPanelActiveCard',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SInvalidCardPanelActiveCard);
{$ENDIF}
{$IF DECLARED(SGraphicControlAcceptedOnly)}
  ARegistrar(
    'Vcl.Consts.' +
    'SGraphicControlAcceptedOnly',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SGraphicControlAcceptedOnly);
{$ENDIF}
{$IF DECLARED(SActionManagerNotAssigned)}
  ARegistrar(
    'Vcl.Consts.' +
    'SActionManagerNotAssigned',
    'src/vcl37/Vcl.Consts.pas',
    @Vcl.Consts.
      SActionManagerNotAssigned);
{$ENDIF}
end;
{$WARN SYMBOL_DEPRECATED ON}

end.
