{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgArticulos                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de artículos, atributos, tarifas, inventario y stock.            }
{******************************************************************************}
unit inLibMsgArticulos;

interface

resourcestring
  SErrorLineaAlbaranSinArticulo =
    'La línea del albarán no tiene artículo; no se puede guardar.';
  SErrorCodigoSkuCodigoBarrasObligatorio =
    'Indique el código de SKU al añadir un nuevo código de barras. Para ' +
    'crear un SKU nuevo use la pestaña SKUs.';
  SErrorCampoCodigoBarrasAusente =
    'Falta el campo CODIGO_BARRAS_CB.';
  SErrorCodigoSkuObligatorio = 'Indique el código del SKU.';
  SErrorFilaCodigoBarrasInexistente =
    'Esta fila no representa un código de barras existente. No hay nada ' +
    'que eliminar.';
  SErrorProveedorPrincipalArticulo =
    '%s ya tiene un proveedor principal asociado a este artículo.';
  SErrorDescripcionArticulo =
    '%s no es un valor válido para el campo Descripción de Artículos';
  SErrorPermisoCambiarMarcaWebArticulo =
    'No tiene permiso para activar o desactivar la marca En web del ' +
    'artículo.';
  SPreguntaDesactivarArticuloPrestaShop =
    'El artículo "%s" dejará de sincronizarse con PrestaShop.' +
    sLineBreak + sLineBreak +
    '¿Desea desactivarlo también en la tienda web?' + sLineBreak +
    'Sí: se desactiva en PrestaShop y deja de mostrarse en la web.' +
    sLineBreak +
    'No: solo deja de sincronizarse; el artículo permanece como esté.' +
    sLineBreak +
    'Cancelar: no se guarda el cambio.';
  SPreguntaDesactivarTarifaSinPrecio =
    'El precio de salida pasa a 0. ¿Desea desactivar la tarifa?';
  SPreguntaActivarTarifaConPrecio =
    'El precio de salida es mayor que 0. ¿Desea activar la tarifa?';
  SErrorTarifaFechasConcurrentes =
    'No se pueden grabar dos precios para una tarifa activa en fechas ' +
    'concurrentes para el artículo/SKU %s';
  SErrorAtributoBasicoObligatorio =
    'Indica el atributo (CO para color, TAL para talla, etc.).';
  SErrorCodigoAtributoBasicoObligatorio =
    'El código del atributo básico es obligatorio.';
  SErrorNombreAtributoBasicoObligatorio =
    'El nombre del atributo básico es obligatorio.';
  SErrorValorColeccionAtributosObligatorio =
    'Selecciona un valor para añadirlo a la colección.';
  SErrorArticuloLineaDocumentoTrabajoObligatorio =
    'Indique el articulo de la linea.';
  SErrorSkuLineaDocumentoTrabajoObligatorio =
    'Indique el SKU/unidad de la linea.';
  SAvisoPropiedadFamiliaDuplicada = 'Propiedad Duplicada';
  SErrorNombreFamilia =
    '%s no es un valor válido para el campo Nombre de Familias';
  SErrorFamiliaPadreIgualHija =
    '%s no puede ser padre e hijo a la vez. Revise campo Familia Padre';
  SErrorSerieInventarioObligatoria =
    'No se puede grabar el inventario sin una serie. Selecciona una serie ' +
    'en la cabecera (campo SERIE), o configura una serie por defecto de ' +
    'tipo IN para la empresa en fza_empresas_series.';
  SErrorContadorLineasInventarioNoInstalado =
    'No se puede reservar la linea del inventario: falta la columna ' +
    'fza_inventarios.CONTADOR_LINEAS_INV. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\inventarios_contador_lineas.sql.';
  SErrorCabeceraInventarioSinGrabarParaReserva =
    'No se puede reservar la linea: graba primero la cabecera del ' +
    'inventario para tener empresa, almacen, serie y numero definitivos.';
  SErrorCabeceraInventarioNoEncontrada =
    'No se ha encontrado la cabecera del inventario para reservar la ' +
    'siguiente linea.';
  SErrorActualizarContadorLineasInventario =
    'No se ha podido actualizar el contador de lineas del inventario.';
  SErrorEmpresaCabeceraInventarioObligatoria =
    'La cabecera del inventario no tiene empresa. Selecciona una empresa ' +
    'antes de anadir lineas.';
  SErrorAlmacenCabeceraInventarioObligatorio =
    'La cabecera del inventario no tiene almacen. Selecciona un almacen ' +
    'antes de anadir lineas.';
  SErrorSerieCabeceraInventarioObligatoria =
    'La cabecera del inventario no tiene serie. Vuelve a la pestana ' +
    'Cabecera, selecciona una serie y vuelve a intentar grabar la linea.';
  SErrorNumeroCabeceraInventarioObligatorio =
    'La cabecera del inventario no tiene numero. Graba primero la cabecera ' +
    'para que el sistema asigne el numero.';
  SErrorAtributoLineaInventarioObligatorio =
    'La línea %s del artículo %s requiere %d atributos y el atributo nº %d ' +
    'está sin rellenar. Completa todos los selectores (Color, Talla, …) o ' +
    'elimina la línea.';
  SPreguntaCrearSkuInventario =
    'El SKU "%s" no existe en la base de datos.' + sLineBreak + sLineBreak +
    '¿Quieres crearlo automáticamente con los atributos seleccionados y ' +
    'guardar la línea?' + sLineBreak + sLineBreak +
    'Sí: se crea el SKU (fza_articulos_skus + fza_atributos_sku) y se ' +
    'graba la línea.' + sLineBreak +
    'No: no se graba. Cambia los atributos a una combinación válida o ' +
    'pulsa "- Eliminar línea".';
  SErrorSkuInventarioNoExiste =
    'SKU "%s" no existe. La línea no se ha grabado. Cambia los atributos o ' +
    'elimina la línea.';
  SErrorEliminarLineasInventarioNoAbierto =
    'No se pueden eliminar líneas: el inventario no está ABIERTO';
  SErrorAnadirLineaCabeceraInventario =
    'No se puede añadir una línea: la cabecera del inventario no se ha ' +
    'podido grabar.' + sLineBreak + '%s' + sLineBreak +
    'Completa los datos obligatorios de la cabecera y vuelve a intentarlo.';
  SErrorRecalcularInventarioNoAbierto =
    'Solo se puede recalcular un inventario en estado ABIERTO';
  SErrorAplicarInventarioNoAbierto =
    'Solo se puede aplicar un inventario en estado ABIERTO';
  SErrorAplicarInventarioSinLineas =
    'No se puede aplicar un inventario sin líneas. Añade al menos una línea ' +
    'con diferencia de cantidad o de coste antes de regularizar.';
  SErrorEliminarRegularizacionInventarioNoAplicado =
    'Solo se puede eliminar la regularización de un inventario APLICADO';
  SErrorCargarArticulosInventarioNoAbierto =
    'Solo se pueden cargar artículos en un inventario ABIERTO';
  SErrorCompletarInventarioNoAbierto =
    'Solo se puede completar un inventario ABIERTO';
  SErrorArticuloLineaInventarioObligatorio =
    'Debe indicar un artículo (la línea actual está vacía).';
  SErrorAnadirSkusInventarioNoAbierto =
    'Solo se pueden añadir SKUs en un inventario ABIERTO';
  SErrorValorAtributoSkuInventarioNoEncontrado =
    'No se encontró el valor "%s" en el atributo nº %d del artículo %s. ' +
    'No se ha podido crear el SKU %s.';
  SAvisoEdicionMovimientoAlmacen =
    'No se permite %s movimientos de almacén manualmente.' + sLineBreak +
    'Usa el proceso correspondiente (albarán, factura, traspaso, ' +
    'regularización de inventario...).';
  SErrorLineaPedidoSinArticulo =
    'La línea del pedido no tiene artículo; no se puede guardar.';
  SErrorNombreSesionCambioTarifaObligatorio =
    'El nombre de la sesion es obligatorio.';
  SErrorTarifaDestinoObligatoria =
    'La tarifa destino es obligatoria.';
  SErrorCodigoAtributoVariacionObligatorio =
    'El código del atributo es obligatorio.';
  SErrorDistribuidorTallasNoRegistrado =
    'No se ha registrado el distribuidor de tallas por almacén.';
  SErrorPersistenciaTallasNoRegistrada =
    'No se ha registrado la persistencia del modo de tallas.';
  SErrorArticulosVariacionesNoRegistradas =
    'No se ha registrado la implementación de variaciones de artículos.';
  SErrorPersistenciaFotosNoRegistrada =
    'No se ha registrado la persistencia del subsistema de fotos.';
  // La libreria ya no construye repositorios: la raiz de composicion
  // (TfrmBase.CrearValidadorArticulos / CrearLookupAtributosArticulos)
  // debe rellenar la configuracion antes de crear el modo de entrada.
  SErrorValidadorArticulosNoInyectado =
    'No se ha inyectado el validador de artículos en la configuración.';
  SErrorLookupAtributosNoInyectado =
    'No se ha inyectado el lookup de atributos en la configuración.';
  SErrorInvarianteUnidadesTallas =
    'La conversión de tallas alteraría las unidades del documento (%s: ' +
    'antes %.2f, después %.2f). Se deshacen los cambios.';
  SErrorAlmacenDistribucionTallasNoDisponible =
    'Formato distribuido: se necesita un almacén por defecto y no hay ' +
    'almacenes activos definidos.';
  SErrorArticuloSkuNoEncontrado =
    'Artículo/SKU no encontrado: %s';
  SAvisoArticuloSinAtributos =
    'El artículo no tiene atributos definidos: %s';
  SErrorFactoriaTallasHorizontalObligatoria =
    'El modo de tallas horizontal requiere su factoria especifica';
  SErrorArticuloDocumentoTrabajoNoActivo =
    'No hay articulo activo para agregar.';
  SErrorArticuloDocumentoTrabajoVariosSkus =
    'El articulo tiene varios SKUs. Selecciona una unidad concreta.';
  SErrorArticuloNoExiste =
    'No existe el artículo "%s"';
  SErrorEntradaArticuloVacia = 'Entrada vacía.';
  SErrorCodigoBarrasNoEncontrado =
    'No se encontró "%s" como código de barras.';
  SErrorArticuloEntradaNoEncontrado =
    'No se encontró "%s" como artículo, SKU, código de barras ni modelo de ' +
    'proveedor.';
  SAvisoArticuloRequiereSku =
    'El artículo "%s" tiene SKUs (talla/color). Indica un SKU concreto ' +
    'antes de continuar.';
  SErrorArticuloVariacionSinSkusActivos =
    'El artículo "%s" no tiene tallas/colores (SKU) activos para vender.';
  SErrorArticuloSinSkusActivos =
    'El artículo "%s" no tiene ninguna unidad (SKU) activa para vender.';
  SErrorSkuNoPerteneceArticulo =
    'El SKU "%s" no pertenece a "%s" o no está activo.';
  SErrorLineaArticuloSesionNoSeleccionada =
    'Selecciona o crea una linea de articulo primero.';
  SErrorCodigoArticuloResolverObligatorio =
    'Falta código de artículo.';
  SErrorArticuloResolverNoExiste =
    'No existe el artículo "%s".';
  SAvisoArticuloResolverRequiereSku =
    'El artículo "%s" tiene SKUs. Indica uno para obtener precio definitivo.';
  STextoArticuloInactivoSesion = ' (inactivo)';
  SErrorCodigoBarrasNoNumerico =
    'El código de barras contiene caracteres no numéricos.';
  SErrorImportarImagenCodec =
    'No se puede importar %s en este equipo: falta el codec "%s".' +
    sLineBreak + sLineBreak +
    'Instálalo gratis desde Microsoft Store y reintenta.' +
    sLineBreak + sLineBreak +
    'Alternativa: guarda la imagen en PNG o JPG y vuelve a subirla.' +
    sLineBreak + sLineBreak +
    'Error original: %s';
  SErrorGuardarFotoSinCodigoArticulo =
    'No se puede guardar foto sin codigo de articulo.';
  SErrorFicheroOrigenFotoNoExiste =
    'El fichero origen no existe: %s';
  SErrorDirectorioFotosNoConfigurado =
    'El parametro appDirFotos no esta configurado.';
  SErrorFotoNoRegistradaParaRotar =
    'No hay foto registrada para rotar.';
  SErrorFotoSesionSinSerie =
    'Foto de sesion: falta SERIE_SES.';
  SErrorFotoSesionSinNumero =
    'Foto de sesion: falta NUMERO_SES.';
  SErrorFotoSesionLineaInvalida =
    'Foto de sesion: LINEA debe ser > 0.';
  STextoParametroUrlFotosNube =
    '  - URL general del servicio web';
  STextoParametroTokenFotosNube =
    '  - API key / token de la instalación';
  STextoParametroReferenciaFotosNube =
    '  - Referencia global de la instalación';
  STextoParametroCarpetaFotosNube =
    '  - Carpeta de fotos (appDirFotos)';
  SErrorParametrosFotosNubeFaltantes =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorFotosNubeHttp =
    'El servidor respondió con código %d.';
  SErrorConexionServidorFotosNube =
    'No se pudo conectar con el servidor de fotos: %s';
  SErrorValoresAtributoNoDefinidos =
    'No hay valores definidos para este atributo.';
  SErrorArticuloSinSistemaTallasPivote =
    '- Articulo SIN sistema de tallas: %s';
  SErrorSkuFueraSistemaTallasPivote =
    '- SKU %s (art %s): talla "%s" fuera del sistema asignado.';
  SPreguntaEliminarLineaTallasVenta =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SErrorArticuloSkuNoEncontradoSinDetalle =
    'Artículo/SKU no encontrado.';
  SPreguntaEliminarLineaSkuCantidadCero =
    'La cantidad queda a cero. ¿Borrar la línea del SKU?';
  SAvisoSistemaTallasSuperaMaximo =
    'El sistema de tallas seleccionado tiene %d valores; el maximo admitido ' +
    'es %d. Elige un sistema con menos tallas o reduce el conjunto antes de ' +
    'usarlo aqui.';
  STextoParametroUrlInventarioNube =
    '  - URL general del servicio web';
  STextoParametroTokenInventarioNube =
    '  - API key / token de la instalación';
  STextoParametroReferenciaInventarioNube =
    '  - Referencia global de la instalación';
  SErrorParametrosInventarioNubeFaltantes =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorInventarioNubeHttp =
    'El servidor respondió con código %d.';
  SErrorConexionServidorInventarioNube =
    'No se pudo conectar con el servidor: %s';
  SErrorInventarioNubeSinIdRecuento =
    'El servidor no devolvió id_recuento';
  SErrorArticuloCursoSinSistemaTallas =
    'El articulo en curso no tiene sistema de tallas asignado.';
  SErrorAltaSeleccionarArticuloConTallas =
    'En alta, selecciona primero un articulo con sistema de tallas.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarAlbaranVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorProveedorNoSeleccionadoBuscarArticulos =
    'Selecciona un proveedor antes de buscar artículos.';
  SAvisoArticuloCreadoOtroProveedor =
    'Este artículo se creó con otro proveedor';
  SErrorArticuloNoSeleccionadoElegirColor =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloSinColoresBasicosActivos =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SErrorArticuloSinTipoVariacion =
    'El artículo debe tener asignado un "Tipo de variación" y estar ' +
    'guardado para poder generar SKUs.';
  SErrorPrecioTarifaNoSeleccionado =
    'Selecciona primero un precio de tarifa.';
  SErrorPrecioTarifaNoGuardado =
    'Esta fila aún no tiene precio guardado en la tarifa. Pulsa primero ' +
    '"Añadir precio" para crear el registro.';
  SAvisoRevisionArticulo = 'Revisión requerida: %s';
  SErrorGuardarPropiedadesArticulo =
    'Error al guardar propiedades: %s';
  SErrorGuardarVariacionesArticulo =
    'Error al guardar variaciones: %s';
  SPreguntaReconstruirStock =
    '¿Desea reconstruir la tabla de stock a partir de los movimientos de ' +
    'almacén? Esta operación borrará el stock actual y lo regenerará.';
  STituloReconstruirStock = 'Reconstruir Stock';
  SErrorReconstruirStock =
    'Error al reconstruir el stock: %s';
  SInfoStockReconstruido = 'Stock reconstruido.';
  SErrorArticuloNoSeleccionadoImprimirEtiquetas =
    'Seleccione primero un artículo para imprimir sus etiquetas.';
  SErrorArticuloNoSeleccionadoGenerarCodigos =
    'Seleccione o guarde un artículo antes de generar códigos de barras.';
  SErrorArticuloSinSkusActivosGenerarCodigos =
    'El artículo no tiene SKUs activos.';
  SPreguntaGenerarCodigosBarras =
    '¿Generar códigos de barras pendientes?' + sLineBreak + sLineBreak +
    'Para cada SKU activo:' + sLineBreak +
    '  · Si no tiene principal: se genera un EAN-13 interno (prefijo ' +
    '"%s").' + sLineBreak +
    '  · Si tiene principal pero no fila vacía: se crea una fila vacía ' +
    'para el código del fabricante (a rellenar manualmente).' + sLineBreak +
    '  · Si ya tiene ambos, se respeta.' + sLineBreak + sLineBreak +
    'Pulse Sí para continuar.';
  SInfoGeneracionCodigosBarras =
    'Generación finalizada.' + sLineBreak +
    '- EAN-13 internos creados: %d' + sLineBreak +
    '- Filas vacías de fabricante creadas: %d' + sLineBreak +
    '- SKUs ya completos (saltados): %d' + sLineBreak +
    '- Placeholders _FAB_ obsoletos eliminados: %d';
  SErrorArticuloNoSeleccionadoVerificarCodigos =
    'Seleccione o guarde un artículo antes de verificar.';
  SErrorDetalleCodigoBarrasInvalido =
    '  %s  (SKU %s, Tipo %s, Long %d)';
  SInfoVerificacionCodigosBarrasCorrecta =
    'Verificación OK.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- Pendientes (placeholder/vacío): %d';
  SAvisoVerificacionCodigosBarras =
    'Verificación con incidencias.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- NO válidos: %d' + sLineBreak +
    '- Pendientes: %d' + sLineBreak +
    'Códigos no válidos:%s';
  SInfoPrecargaArticuloGuardada = 'Precarga guardada.';
  STextoAtributoBasicoSinValor = '(sin valor)';
  SPreguntaCrearAtributoBasicoSku =
    'Este SKU todavia no tiene un atributo basico asignado para este valor.' +
    sLineBreak + sLineBreak +
    'Si       -> Crear basico GLOBAL "%s"' + sLineBreak +
    '            (compartido con otros articulos que usen ese valor)' +
    sLineBreak + sLineBreak +
    'No       -> Crear basico AD-HOC "%s"' + sLineBreak +
    '            (exclusivo de este articulo)' + sLineBreak + sLineBreak +
    'Cancelar -> No crear nada por ahora.';
  STituloCrearAtributoBasico =
    'Como crear el atributo basico';
  SErrorSkuColorNoSeleccionado =
    'Seleccione un SKU con color para activar o desactivar todos los SKU ' +
    'de ese color.';
  STextoActivarSkusColor = 'activar';
  STextoDesactivarSkusColor = 'desactivar';
  SPreguntaCambiarActivoSkusColor =
    'Va a %s TODOS los SKU del color "%s" de este articulo. Continuar?';
  STextoSkusColorActivados = 'activado';
  STextoSkusColorDesactivados = 'desactivado';
  SInfoSkusColorActualizados =
    '%d SKU del color "%s" se han %s.';
  SErrorLineaSesionAsignarFamiliaNoSeleccionada =
    'Anade una linea (o ponte sobre una) para asignarle familia.';
  SErrorContadorInventarioDocumentoTrabajo =
    'El contador de inventarios no ha devuelto numero para la serie %s.';
  SInfoInventarioDocumentoTrabajoCreado =
    'Inventario %s/%s creado en almacén %s con %d líneas del documento.' +
    sLineBreak +
    'Abre Inventarios y usa "Recalcular teórico/PMP" para fijar teóricos ' +
    'y costes.';
  SInfoCambioTarifasDocumentoTrabajoCreado =
    'Sesión de cambio de tarifas %d creada en BORRADOR con los artículos ' +
    'del documento.' + sLineBreak +
    'Abre "Cambios de tarifa" para elegir tarifas, regla de cálculo y ' +
    'aplicar.';
  SErrorFilaDevolucionStockNoSeleccionada =
    'Selecciona una fila antes de devolver su stock.';
  SErrorArticuloDevolucionFilaNoSeleccionado =
    'Selecciona un articulo en la fila antes de devolver su stock.';
  SErrorStockDevolucionFilaNoDisponible =
    'No hay stock positivo para el articulo/color de la fila en el almacen ' +
    'de salida.';
  SPreguntaPrepararStockFilaDevolucion =
    'Esto sustituira las cantidades de la fila actual por el stock positivo ' +
    'de ese articulo/color en el almacen de salida. Continuar?';
  SInfoStockFilaDevolucionPreparado =
    'Se han preparado %d lineas de la fila con el stock actual.';
  SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion =
    'Selecciona un proveedor antes de buscar articulos.';
  SErrorArticuloNoSeleccionadoBuscarSkusDevolucion =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorFotoArticuloNoActivoDescargar =
    'No hay articulo activo para descargar fotos.';
  SErrorFotoArticuloNoActivo = 'No hay artículo activo.';
  SErrorGuardarFotoArticulo =
    'No se pudo guardar la foto: %s';
  SErrorFotoSkuNoActivo =
    'No hay SKU activo. Usa "Cambiar foto del artículo".';
  SErrorNivelAtributosFotoNoSeleccionado =
    'No hay nivel de atributos seleccionado en el combo.';
  SPreguntaEliminarFotoActual = '¿Eliminar la foto actual?';
  SErrorTarifaSeleccionadaNoEncontrada =
    'No se encontró la tarifa seleccionada';
  SErrorArticuloInventarioNoExiste = 'El artículo no existe';
  SErrorLineasInventarioNoAbiertas =
    'No hay líneas de inventario abiertas.';
  SErrorLineaInventarioNoEditable =
    'No se ha podido poner la línea en edición.';
  SErrorArticuloInventarioNoEncontrado =
    'No se ha encontrado ningún artículo con ese código, SKU o código de ' +
    'barras';
  SErrorArticuloInventarioTipoSinStock =
    'El artículo %s es de tipo "%s" y no controla stock; no se puede ' +
    'inventariar.';
  SErrorArticuloInventarioAtributosSinSku =
    'El artículo %s tiene atributos. En modo SKU introduce un SKU completo ' +
    'o activa "Ver atributos en columnas".';
  SInfoLineasCsvInventarioLeidas =
    'Leidas %d lineas del CSV.';
  SErrorMigracionRecuentoInventariosNoAplicada =
    'La base de datos no tiene aplicada la migración de recuento remoto de ' +
    'inventarios. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\recuento_inventarios_factuzam.sql.';
  SErrorGrabarCabeceraInventarioAutomaticamente =
    'No se ha podido grabar automaticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestana Cabecera y vuelve a intentar anadir ' +
    'la linea.';
  SErrorGrabarCabeceraInventarioAutomaticamenteDetalle =
    'No se ha podido grabar automáticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestaña Cabecera y vuelve a entrar en ' +
    'Detalle.';
  SErrorInventarioNoAbiertoEditar =
    'El inventario no está ABIERTO. No se puede editar.';
  SPreguntaRecalcularInventario =
    'Esto recalculará las cantidades teóricas y precios medios de todas ' +
    'las líneas a partir del Kardex actual.' + sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRecalculoInventario =
    'Recálculo completado correctamente.';
  SPreguntaAplicarInventario =
    'Esto aplicará el inventario y generará movimientos de regularización' +
    sLineBreak +
    'en el Kardex. La operación NO se podrá deshacer fácilmente.' +
    sLineBreak + sLineBreak +
    '¿Aplicar el inventario?';
  SErrorAplicarInventario =
    'No se puede aplicar el inventario:' + sLineBreak + '%s';
  SErrorAplicacionInventario =
    'Error al aplicar el inventario:' + sLineBreak + '%s';
  SErrorRefrescarInventarioAplicado =
    'El inventario se aplico, pero fallo el refresco:' + sLineBreak + '%s';
  SInfoInventarioAplicado = 'Inventario aplicado correctamente.';
  SErrorInventarioNoSeleccionadoAnadirLineas =
    'No hay ningún inventario seleccionado todavía. Crea uno o selecciónalo ' +
    'en la lista antes de añadir líneas.';
  SErrorAnadirLineasInventarioEstado =
    'No se pueden añadir líneas: el inventario está en estado "%s" (solo ' +
    'se pueden editar inventarios ABIERTOS).';
  SErrorLineaInventarioNoSeleccionadaParaSkus =
    'Sitúate sobre una línea con artículo para añadir sus SKUs.';
  SErrorLineaInventarioSinArticulo =
    'La línea actual no tiene artículo asignado.';
  SErrorAnadirSkusInventario =
    'Error al añadir SKUs: %s';
  SInfoSinSkusAnadidosInventario =
    'No se ha añadido ningún SKU. El artículo %s no tiene movimientos en ' +
    'este almacén o todos sus SKUs ya están en el inventario.';
  SInfoSkusAnadidosInventario =
    'Añadidos %d SKUs del artículo %s.';
  SPreguntaEliminarLineaInventario =
    '¿Eliminar la línea seleccionada?';
  SErrorEliminarRegularizacionInventarioEstado =
    'Solo puedes eliminar la regularización de un inventario APLICADO.';
  SPreguntaEliminarRegularizacionInventario =
    'Esto BORRARÁ todos los movimientos generados por este inventario,' +
    sLineBreak +
    'devolverá el inventario al estado ABIERTO y recalculará el Kardex.' +
    sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRegularizacionInventarioEliminada =
    'Regularización eliminada. El inventario vuelve a estar ABIERTO.';
  SErrorInventarioNoActivo = 'No hay inventario activo.';
  SErrorInventarioDebeEstarAbierto =
    'El inventario debe estar ABIERTO.';
  SErrorFamiliaInventarioNoSeleccionada =
    'Selecciona primero una familia.';
  SPreguntaCargarFamiliaInventario =
    '¿Cargar todos los SKUs de la familia "%s" al inventario?';
  SErrorProveedorInventarioNoSeleccionado =
    'Selecciona primero un proveedor.';
  SPreguntaCargarProveedorInventario =
    '¿Cargar todos los SKUs del proveedor "%s" al inventario?';
  SPreguntaCompletarInventario =
    'Esto añadirá al inventario todos los SKUs con stock que NO ' +
    sLineBreak +
    'estén ya en el inventario, con cantidad física = 0.' + sLineBreak +
    sLineBreak +
    'Útil para detectar artículos que faltó contar.' + sLineBreak +
    sLineBreak + '¿Continuar?';
  SPreguntaCargarTodoInventario =
    'Esto cargará TODOS los SKUs con stock al inventario, ' + sLineBreak +
    'con cantidad física = teórica. ¿Continuar?';
  SErrorInventarioNoSeleccionado =
    'Selecciona primero un inventario.';
  SPreguntaGuardarInventarioEnEdicion =
    'El inventario esta en edicion. Guardar antes?';
  SPreguntaRecalcularTrasCargarBloqueInventario =
    'Se anadieron %d lineas (%d articulos distintos).' + sLineBreak +
    '?Quieres calcular ahora las cantidades teoricas y PMP?';
  SErrorArchivoImportacionInventarioNoExiste =
    'El archivo no existe.';
  SErrorImportacionInventarioSinDatos =
    'No se encontraron datos para importar.';
  SErrorImportacionInventarioYaIniciada =
    'Ya hay una importación de inventario en curso.';
  SErrorAplicarImportacionInventario =
    'No se pudieron aplicar %d cambios de la importación del inventario.';
  STituloIncidenciasImportacionInventario =
    'Incidencias en la importación del inventario';
  STextoIncidenciasImportacionInventario =
    'No se ha importado ninguna línea. Corrige estas incidencias en el ' +
    'archivo y vuelve a intentarlo:';
  SFormatoIncidenciaCantidadImportacionInventario =
    'Fila %d | SKU: "%s" | Cantidad: "%s" | Debe ser un número válido ' +
    'mayor o igual que cero.';
  SFormatoIncidenciaPmpNuevoImportacionInventario =
    'Fila %d | SKU: "%s" | PMP nuevo: "%s" | Debe ser un número válido ' +
    'mayor o igual que cero.';
  SFormatoIncidenciaFechaRecuentoImportacionInventario =
    'Fila %d | SKU: "%s" | Fecha y hora de recuento: "%s" | Debe ser ' +
    'una fecha y hora válidas.';
  SFormatoIncidenciaLineaImportacionInventario =
    'Línea "%s" | SKU: "%s" | No coincide con una línea del inventario ' +
    'actual.';
  SIncidenciaIdentidadExcelIncompleta =
    'Excel | Identidad incompleta | Debe incluir Empresa, Almacén, Serie y ' +
    'Número con valor. No se admiten archivos antiguos sin esa cabecera.';
  SIncidenciaIdentidadExcelContradictoria =
    'Excel | Identidad contradictoria | Hay datos de Empresa, Almacén, ' +
    'Serie o Número repetidos con valores distintos.';
  SFormatoIncidenciaInventarioExcelDistinto =
    'Excel | Inventario distinto | Archivo: Empresa "%s", Almacén "%s", ' +
    'Serie "%s", Número "%s" | Inventario abierto: Empresa "%s", ' +
    'Almacén "%s", Serie "%s", Número "%s".';
  STextoSkusNoCargadosImportacionInventario =
    'No se pudieron cargar estos SKU:';
  STituloFechaHoraRecuentoInventario =
    'Fecha y hora del recuento';
  STextoFechaHoraRecuentoInventario =
    'El Excel no incluye la fecha y hora de recuento para todas las ' +
    'líneas. Indica el instante que se aplicará solo a las líneas sin ' +
    'ese dato.';
  SErrorFechaHoraRecuentoInventarioNoIndicada =
    'Indica una fecha y hora de recuento válidas.';
  SEtiquetaFechaHoraRecuentoInventario =
    'Fecha y hora de recuento:';
  STextoAceptarFechaHoraRecuentoInventario = 'Aceptar';
  STextoCancelarFechaHoraRecuentoInventario = 'Cancelar';
  SErrorRecuentoInventarioSinInstanteSku =
    'El servidor no ha devuelto una fecha y hora válida para el SKU "%s".';
  SErrorSkuRecuentoInventarioNoExiste =
    'El SKU "%s" leído por el móvil no existe en Factuzam. No se ha ' +
    'importado el recuento.';
  SErrorRespuestaRecuentoInventarioIncoherente =
    'El servidor ha devuelto lecturas incompletas, con una fecha u hora no ' +
    'válida, o cantidades que no coinciden. No se ha importado el recuento.';
  SInfoImportacionInventario =
    '%s' + sLineBreak + '%d actualizados, %d nuevos insertados.';
  SErrorEnviarRecuentoInventarioNoAbierto =
    'Solo se puede enviar a recuento un inventario ABIERTO.';
  SPreguntaEnviarRecuentoInventario =
    'Se enviará este inventario al servidor para recontarlo con la app. ' +
    '¿Continuar?';
  SInfoInventarioEnviadoRecuento =
    'Inventario enviado a recuento (referencia %d).';
  SErrorEnviarRecuentoInventario = 'No se pudo enviar: %s';
  SErrorInventarioNoEnviadoRecuento =
    'Este inventario no se ha enviado a recuento todavía.';
  SErrorRecogerRecuentoInventarioNoAbierto =
    'Solo se puede recoger sobre un inventario ABIERTO.';
  SInfoRecuentoInventarioRecogido =
    'Recuento recogido: %d lecturas, %d SKUs. Revisa las físicas y APLICA ' +
    'cuando quieras.';
  SErrorRecogerRecuentoInventario = 'No se pudo recoger: %s';
  SCaptionRevalorizarPmpInventario = 'Valorar';
  SHintRevalorizarPmpInventario =
    'Simula y prepara una apreciación o depreciación porcentual del PMP. ' +
    'Atajo: Ctrl+Mayús+R.';
  STituloRevalorizacionInventario =
    'Apreciación/depreciación del inventario';
  STextoRevalorizacionInventario =
    'Selecciona las líneas y simula el cambio antes de prepararlo. Se usa ' +
    'el PMP guardado en el inventario y se comprueba de nuevo contra el ' +
    'Kardex al confirmar. La vista previa no aplica la valoración; las ' +
    'existencias solo cambiarán al pulsar Regularizar.';
  SFormatoIdentificacionRevalorizacionInventario =
    'Inventario %s / %s / %s / %s';
  SCaptionOperacionRevalorizacionInventario = 'Operación';
  SCaptionApreciarInventario = 'Apreciar';
  SCaptionDepreciarInventario = 'Depreciar';
  SCaptionPorcentajeRevalorizacionInventario = 'Porcentaje:';
  SCaptionSimularRevalorizacionInventario = 'Simular';
  SCaptionSeleccionarTodoRevalorizacionInventario =
    'Seleccionar visibles';
  SCaptionSeleccionarNingunoRevalorizacionInventario =
    'Quitar toda la selección';
  SCaptionPrepararPmpRevalorizacionInventario = 'Preparar PMP simulados';
  SInfoSimulacionPendienteRevalorizacionInventario =
    'Pulsa Simular para actualizar la vista previa.';
  SCaptionColAplicarRevalorizacionInventario = 'Aplicar';
  SCaptionColLineaRevalorizacionInventario = 'Línea';
  SCaptionColCantidadTeoricaRevalorizacionInventario = 'Uds. anteriores';
  SCaptionColCantidadFisicaRevalorizacionInventario = 'Uds. finales';
  SCaptionColPmpAnteriorRevalorizacionInventario = 'PMP anterior';
  SCaptionColPmpSimuladoRevalorizacionInventario = 'PMP simulado';
  SCaptionColValorAnteriorRevalorizacionInventario = 'Valor anterior';
  SCaptionColValorSimuladoRevalorizacionInventario = 'Valor simulado';
  SCaptionColDiferenciaRevalorizacionInventario = 'Diferencia';
  SFormatoLineasRevalorizacionInventario = 'Líneas seleccionadas: %d';
  SCaptionTotalAnteriorRevalorizacionInventario = 'Total anterior:';
  SCaptionTotalSimuladoRevalorizacionInventario = 'Total simulado:';
  SCaptionTotalDiferenciaRevalorizacionInventario = 'Diferencia total:';
  SAvisoDiferenciasUnidadesRevalorizacionInventario =
    '%d líneas también tienen diferencias entre unidades anteriores y ' +
    'finales; la diferencia económica incluye ambos efectos.';
  SAvisoPmpCorregidosRevalorizacionInventario =
    '%d líneas ya tenían un PMP corregido manualmente; se sustituirá por ' +
    'el PMP de esta simulación.';
  SErrorPorcentajeRevalorizacionInventario =
    'Indica un porcentaje mayor que cero. En una depreciación no puede ' +
    'superar el 100 %.';
  SErrorSeleccionRevalorizacionInventario =
    'Selecciona al menos una línea para realizar la simulación.';
  SErrorLineaRevalorizacionInventarioNoEncontrada =
    'La línea %s ya no existe en el inventario.';
  SErrorDatosRevalorizacionInventarioCambiados =
    'Los datos de la línea %s han cambiado desde la simulación. Vuelve a ' +
    'pulsar Valorar para calcularla con las cifras actuales.';
  SErrorAplicarRevalorizacionInventario =
    'No se pudo preparar la apreciación/depreciación:' + sLineBreak + '%s';
  SInfoRevalorizacionInventarioPreparada =
    'Se han preparado %d PMP nuevos con las cifras comprobadas. Revisa el ' +
    'resultado y pulsa Regularizar para trasladarlos al Kardex.';
  SAvisoLimiteRegistrosMovimientosAlmacen =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarPedidoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SPreguntaCrearAlbaranPedidoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado y no ' +
    'moverán stock. ¿Crear el albarán de todas formas?';
  SErrorCodigoBarrasStockNoEncontrado =
    'Código de barras no encontrado: %s';
  SErrorEntradaStockNoEncontrada =
    'No se encontró "%s" como artículo, SKU, código de barras ni referencia ' +
    'de proveedor.';
  SErrorSkuCeldaStockNoEncontrado =
    'No se ha encontrado un SKU activo para la celda seleccionada.';
  SErrorCeldaStockVariosSkus =
    'La celda seleccionada coincide con varios SKUs. Acote color, talla o ' +
    'almacen antes de agregarla.';
  SErrorArticuloStockNoSeleccionadoOperaciones =
    'Seleccione primero un artículo.';
  SErrorCeldaTallaStockNoSeleccionada =
    'Seleccione una celda de talla.';
  SErrorColumnaTallaStockNoSeleccionada =
    'Seleccione una columna de talla.';
  SErrorFilaStockNoIdentificada =
    'No se ha podido identificar la fila seleccionada.';
  SErrorColorStockNoUnico =
    'Seleccione un único color o cambie a la vista Por colores.';
  SErrorTallaStockVariosSkus =
    'La talla seleccionada corresponde a varios SKU. Seleccione un único ' +
    'color o use la vista Por colores.';
  SErrorArticuloStockNoSeleccionadoDocumento =
    'Seleccione primero un articulo.';
  SErrorEstadoStockNoEsExistencias =
    'Cambie el estado a Existencias para agregar stock disponible.';
  SErrorCeldaStockNoSeleccionada =
    'Seleccione una celda de stock.';
  SErrorCeldaCantidadStockNoSeleccionada =
    'Seleccione una celda de cantidad.';
  SErrorFilaExistenciasStockNoSeleccionada =
    'Seleccione la fila de Existencias para agregar stock disponible.';
  SErrorColumnaStockDocumentoNoSeleccionada =
    'Seleccione una columna de talla o una columna Total sin tallas.';
  SErrorGrupoFilaStockNoLeido =
    'No se ha podido leer el grupo de la fila.';
  SErrorAlmacenStockNoUnico =
    'Seleccione un solo almacen para agregar una unidad concreta.';
  SErrorColorStockUnidadNoUnico =
    'Seleccione un solo color para agregar una unidad concreta.';
  STituloConsultaStock = 'Consulta de stock';
  SErrorArticuloStockNoSeleccionadoFotos =
    'Seleccione primero un artículo.';
  SInfoArticulosRelacionadosStockNoDisponibles =
    'No hay otros artículos con stock para este filtrado.';
  SErrorTarifaNoSeleccionada =
    'Selecciona primero una tarifa.';
  SPreguntaGuardarTarifaAntesContinuar =
    'La tarifa actual esta en edicion. Guardar antes de continuar?';
  SErrorSesionTarifaNoSeleccionada =
    'Selecciona o crea primero una sesion.';
  SInfoLineasSesionTarifaRecalculadas =
    '%d lineas recalculadas.';
  SErrorCalcularSesionTarifa =
    'No se pudo calcular la sesion: %s';
  SPreguntaAplicarSesionTarifa =
    '%d lineas recalculadas. Aplicar las lineas marcadas a la tarifa ' +
    'destino?';
  SErrorAplicarSesionTarifa =
    'No se pudo aplicar la sesion: %s';
  SInfoLineasSesionTarifaAplicadas =
    '%d lineas aplicadas.';
  SErrorAlmacenesSoloStockAddBlock =
    'Has activado "Solo con stock" pero no hay almacenes seleccionados en ' +
    'la pestana Almacenes.';
  SErrorAlmacenesVentasAddBlock =
    'Selecciona al menos un almacen de ventas para aplicar los filtros ' +
    'de ventas o de stock destino.';
  SInfoArticulosYaCargadosAddBlock =
    'Todos los articulos del filtro ya estan cargados. Nada que insertar.';
  SInfoArticulosAnadidosAddBlock =
    '%d articulos anadidos correctamente.';
  SErrorDestinoInventarioAddBlock =
    'No se ha recibido la clave del inventario destino.';
  SPreguntaConfirmarInventarioAddBlock =
    'Se van a anadir %d articulos al inventario %s/%s/%s/%s.' + sLineBreak +
    'Cada articulo generara una linea por cada SKU con stock>0.' + sLineBreak +
    'Las cantidades teoricas se calcularan despues con "Recalcular ' +
    'teorico/PMP".' + sLineBreak + sLineBreak + 'Continuar?';
  SInfoLineasInventarioAddBlock =
    '%d lineas anadidas al inventario.' + sLineBreak +
    'Recuerda pulsar "Recalcular teorico/PMP" para rellenar las cantidades.';
  SErrorInsertarLineasInventarioAddBlock =
    'Error al insertar lineas de inventario: ';
  SErrorTarifaDestinoAddBlockNoSeleccionada =
    'Selecciona la tarifa destino antes de previsualizar.';
  SErrorTarifaOrigenAddBlockNoSeleccionada =
    'Selecciona la tarifa origen para copiar precios.';
  SErrorTarifasAddBlockCoincidentes =
    'La tarifa origen no puede ser la misma que la tarifa destino.';
  SErrorMultiploAjusteAddBlockNoValido =
    'El multiplo del ajuste debe ser mayor que 0.';
  SPreguntaConfirmarTarifaAddBlock =
    'Se van a insertar %d articulos en la tarifa "%s". Continuar?';
  SInfoArticulosTarifaAddBlockAnadidos =
    '%d articulos anadidos a la tarifa correctamente.';
  SErrorInsertarTarifaAddBlock =
    'Error al insertar: ';
  SPreguntaQuitarPropiedadArticulo =
    '¿Quitar la propiedad "%s" de este artículo?';
  SErrorArticuloNoGuardadoValoresColor =
    'Primero guarde el artículo antes de fijar valores por color.';
  SErrorArticuloNoGuardadoAnadirPropiedades =
    'Primero guarde el artículo antes de añadir propiedades.';
  SErrorPropiedadObligatoriaFamilia =
    'La propiedad "%s" es obligatoria para esta familia.';
  SErrorPrecioCosteMargenNoValido =
    'El precio de coste debe ser mayor que cero.';
  SErrorMargenNoValido =
    'El margen debe ser mayor que cero.';
  SErrorAjusteMargenNoValido =
    'El ajuste no puede ser negativo.';
  SErrorGuardarCambiosMargen =
    'No se han podido guardar los cambios: ';
  SErrorProveedorPrincipalCosteNoAsignado =
    'El artículo no tiene un proveedor marcado como principal. Asigna uno ' +
    'en la pestaña Proveedores antes de guardar el coste.';
  SPreguntaConfirmarCargaSesionTarifa =
    'Se van a cargar %d articulos en la sesion. Continuar?';
  SInfoArticulosCargadosSesionTarifa =
    '%d articulos cargados en la sesion.';
  SErrorCargarSesionTarifa =
    'Error al cargar la sesion: ';
  SErrorTarifaEtiquetasNoSeleccionada =
    'Seleccione una tarifa antes de imprimir.';
  SInfoLayoutEtiquetasGuardado =
    'Layout guardado.';
  SPreguntaSuperarLimiteCargaArticulos =
    'Aún se cargarán %d artículos, por encima del límite recomendado de %d.' +
    sLineBreak + 'La carga puede tardar. ¿Continuar igualmente?';
  SErrorDimensionesSkuNoDefinidas =
    'No hay dimensiones definidas para este tipo de variación.';
  SErrorValoresSkuNoSeleccionados =
    'No has marcado ningún valor para generar SKUs.';
  SErrorValoresDimensionesSkuIncompletos =
    'Debes marcar al menos un valor en cada dimensión del artículo.' +
    sLineBreak + 'Falta marcar valores en: %s';
  SInfoCombinacionesSkuGeneradas =
    '¡Combinaciones generadas con éxito!';
  STituloAnadirValorSku =
    'Añadir nuevo valor';
  SSolicitudNombreValorSku =
    'Introduce el nombre del nuevo atributo (Ej: XXL, Turquesa):';
  SSolicitudOrdenNuevoValorSku =
    'Introduce el ORDEN (Ej: 10, 20, 30...).' + sLineBreak + sLineBreak +
    'ATENCIÓN: El orden asignado será global y afectará a todos los ' +
    'artículos que usen este valor en el futuro.';
  SPreguntaGuardarValorSkuGlobal =
    'Va a utilizar el valor "%s".' + sLineBreak + sLineBreak +
    '¿Desea guardarlo de forma permanente en el conjunto global "%s" para ' +
    'que aparezca disponible siempre para otros artículos?' + sLineBreak +
    sLineBreak + '[SÍ] -> Añadir al conjunto global' + sLineBreak +
    '[NO] -> Usar SOLO ESTA VEZ para generar el SKU (no se guarda en el ' +
    'conjunto)';
  SPreguntaUsarValorSkuTemporal =
    'El artículo no tiene un conjunto global asignado.' + sLineBreak +
    sLineBreak + 'El valor "%s" se utilizará SOLO ESTA VEZ para generar el ' +
    'SKU de este artículo, pero no se guardará en ninguna lista de ' +
    'conjuntos.' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloCambiarOrdenValorSku =
    'Cambiar orden del valor';
  SSolicitudOrdenValorSku =
    'Orden de "%s" (número entero, los más bajos van primero y prevalence ' +
    'el orden del sistema):';
  SErrorOrdenValorSkuNoValido =
    'Por favor, introduce un número entero válido, (mayor o igual a 0).';
  SPreguntaCambiarOrdenValorSkuGlobal =
    'Este valor proviene de un sistema de colores o atributos (%s).' +
    sLineBreak + sLineBreak +
    'ATENCIÓN: Este cambio implica un cambio que puede afectar a otros ' +
    'artículos que compartan este sistema.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  STituloCambiarOrdenAtributoSku =
    'Cambiar orden';
  SSolicitudOrdenAtributoSku =
    'Orden de "%s" dentro del SKU (número entero, los más bajos van ' +
    'primero):';
  SErrorOrdenAtributoSkuNoValido =
    'Introduce un número entero mayor que 0.';
  // R02 - Textos de controles de artículos en ejecución
  STituloSeleccionTarifasArticulo =
    'Seleccione Tarifas a incorporar al artículo';
  SCaptionAnadirPropiedad = '+ Añadir propiedad';
  SCaptionTipoVariacion = 'Tipo de variación: ';
  SCaptionNombreOrden = '%s, orden %s';
  // R05 - Visor de fotos de artículo
  SCaptionControlesExpandido = '▲ Controles';
  SCaptionControlesContraido = '▼ Controles';
  SCaptionFotoDelSku = 'Foto del SKU: %s';
  SCaptionFotoHeredadaGrupo = 'Foto heredada del grupo: %s';
  SCaptionFotoHeredadaArticulo = 'Foto heredada del artículo: %s';
  SCaptionSinFotoPara = 'Sin foto para %s%s';
  // R06 - Inventarios
  SCaptionTabDetalleInventarioSku =
    '&1. Detalle del inventario [SKU]';
  SCaptionTabDetalleInventarioDesglose =
    '&1. Detalle del inventario [Desglose]';
  SCaptionAtributoN = 'Atributo %d';
  // R08 - Consulta de stock y tarifas
  SCaptionModoSimplificado = 'Simplificado';
  SCaptionModoDesglosado = 'Desglosado';
  SHintCoincidenciasPara = 'Coincidencias para %s';
  SHintArticuloAnterior = 'Artículo anterior';
  SHintArticuloSiguiente = 'Artículo siguiente';
  SCaptionFotosMismaFamilia = 'Fotos misma familia';
  SCaptionFotosMismoProveedor = 'Fotos mismo proveedor';
  SCaptionFotosMismaTemporada = 'Fotos misma temporada';
  SCaptionColoresTallas = 'Colores: %s' + sLineBreak + 'Tallas: %s';
  SCaptionColColor = 'Color';
  SCaptionColAlmacen = 'Almacén';
  SCaptionColEstado = 'Estado';
  SCaptionColTotal = 'Total';
  SCaptionSesionesCambiosTarifa = 'Sesiones cambios tarifa';
  SCaptionRedondearHaciaArriba = 'Redondear hacia arriba';
  SCaptionCargarArticulos = 'Cargar articulos';
  SCaptionCalcularLineas = 'Calcular lineas';
  SCaptionAplicarTarifa = 'Aplicar tarifa';
  SCaptionRefrescar = 'Refrescar';
  SCaptionTabLineasTarifa = 'Lineas';
  // R09 - Modales de artículos, bloques y filtros
  SCaptionCeroArticulos = '0 articulos';
  SCaptionNumSeleccionados = '(%d sel.)';
  SCaptionSinAlmacenesSeleccionados = 'No hay almacenes seleccionados';
  SCaptionAlmacenesSeleccionados = '%d almacen(es) seleccionados';
  SCaptionArticulosCoincidenFiltro =
    '%d articulos coinciden con el filtro';
  SCaptionInventarioDestino = 'Inventario destino: %s / %s / %s / %s';
  STituloAnadirBloqueInventario =
    'A~adir Bloque - Carga masiva en Inventario';
  STituloAnadirBloqueTarifa = 'A~adir Bloque - Carga masiva en Tarifa';
  SHintQuitarPropiedad = 'Quitar propiedad %s';
  SCaptionPorColorSku = 'Por color/SKU…';
  SCaptionPorColor = 'Por color…';
  SHintFijarPropiedadPorColorSku = 'Fijar %s por color/SKU';
  SCaptionSinColoresSkuDefinidos =
    'El artículo no tiene colores/SKU definidos aún.';
  STituloCargarArticulosSesionTarifas =
    'Cargar articulos en sesion de tarifas';
  SCaptionDistribucionKit = 'Distribucion almacen / talla  -  Kit %s';
  SCaptionColKit = 'Kit %s';
  SCaptionDocumentoEtiqueta = 'Documento:';
  SCaptionCalcularNumero = 'Calcular nº';
  SCaptionSeCargaranArticulos =
    'Se cargarán %d artículos (límite %d).';
  SCaptionDemasiadosArticulosFiltro =
    'Hay demasiados artículos para cargarlos de golpe (más de %d). ' +
    'Marque temporada y/o proveedor para acotar la carga; pulse ' +
    '"Calcular nº" para ver cuántos quedarían. "Aceptar" carga la ' +
    'selección; "Cancelar" carga el filtro por defecto.';
  // R10 - Informes de balance
  SCaptionGrupoModo = ' Modo ';
  SCaptionModoEntreFechas = 'Entre fechas';
  SCaptionModoPorAcumulados = 'Por acumulados';
  SCaptionGrupoDetalle = ' Detalle ';
  // R15 - Librerías de grids y columnas
  SCaptionTipoVariacionDetalle = 'Tipo de variación: %s — %s';
  SCaptionColSkuArtColorTalla = 'SKU (Art/Color/Talla)';
  SCaptionColSku = 'SKU';
  SCaptionColArticulo = 'Artículo';
  SCaptionColArticuloSku = 'Artículo / SKU';
  SCaptionColTipoCantidad = 'Tipo';
  SCaptionColCantidad = 'Cantidad';
  SCaptionColTallaN = 'Talla %d';
  SCaptionColDescripcion = 'Descripción';
  SCaptionColCodigoBarras = 'Cód. barras';
  SCaptionColRefProveedor = 'Ref. prov.';
  SCaptionColStock = 'Stock';
  SCaptionSinArticulos = 'No hay artículos';
  // R07 - Movimientos de almacén
  SCaptionCargandoMovimientos = 'Cargando movimientos...';
  SCaptionCargandoMovimientosProgreso =
    'Cargando movimientos: %s / %s';
implementation

end.
