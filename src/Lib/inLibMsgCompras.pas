{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgCompras                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de proveedores y documentos del circuito de compras.             }
{******************************************************************************}
unit inLibMsgCompras;

interface

resourcestring
  SErrorPersistenciaGridPivoteCompraNoRegistrada =
    'No se ha registrado la persistencia del pivote de compra.';
  SAvisoAlmacenDestinoAlbaranCompraObligatorio =
    'Debe seleccionar el almacén destino del albarán de compra.';
  SAvisoAlbaranCompraFacturado =
    'No se puede borrar el albaran de compra: ya esta facturado. Borra o ' +
    'deshaz primero la factura de compra vinculada.';
  SPreguntaBorrarAlbaranCompra =
    '¿Borrar el albaran de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SErrorContadorAlbaranCompra =
    'No se pudo obtener un numero de albaran de compra valido. Revise el ' +
    'contador AB de la serie %s y empresa %s.';
  SErrorCambiarFormatoSesion =
    'No se puede cambiar el formato distribuido de una sesion ya creada. ' +
    'Crea una sesion nueva con el modo deseado.';
  SErrorEmpresaSesionObligatoria =
    'Selecciona una empresa antes de grabar la sesion.';
  SErrorSerieSesionObligatoria =
    'Teclea una serie antes de grabar la sesion (p.ej. %s-SE-1).';
  SErrorContadorSesion =
    'No se pudo obtener el siguiente numero. Revisa que exista una fila ' +
    'en fza_contadores para (TIPO_DOC=SE, EMPRESA=%s, SERIE=%s) o que el ' +
    'SP PRC_GET_NEXT_CONT_FACT_SERIE este disponible.';
  SErrorCodigoSerieEmpresa =
    'No se pudo obtener CODIGO_SERIE_EMPSER del contador ES via ' +
    'PRC_GET_NEXT_CONT.';
  SErrorAlmacenSalidaDevolucionCompra =
    'Debe seleccionar el almacen de salida de la devolucion.';
  SAvisoDevolucionCompraFacturada =
    'No se puede borrar la devolucion de compra: ya esta facturada. Borra ' +
    'o deshaz primero la factura de compra vinculada.';
  SPreguntaBorrarDevolucionCompra =
    '¿Borrar la devolucion de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SErrorCabeceraDevolucionCompraSinGrabar =
    'Graba la cabecera de la devolucion antes de guardar lineas.';
  SErrorContadorDevolucionCompra =
    'No se pudo obtener un numero de devolucion de compra valido. Revise ' +
    'el contador DC de la serie %s y empresa %s.';
  SErrorBorrarEfectoCompraRemesado =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de pago.';
  SErrorBorrarEfectoCompraPagado =
    'No se puede borrar el efecto: tiene pago o conciliación registrada.';
  SErrorFusionarEfectosCompraEstado =
    'Solo se pueden fusionar efectos pendientes, sin pagos, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosCompraOrigen =
    'Solo se pueden fusionar efectos de la misma empresa y proveedor.';
  SErrorFusionarEfectosCompraSinPendiente =
    'Los efectos seleccionados no tienen importe pendiente.';
  SErrorCerrarFacturaCompraSinLineas =
    'No se puede cerrar la factura: no tiene lineas con cantidad mayor que ' +
    '0. Añade lineas antes de cerrar.';
  SErrorBorrarFacturaCompraEfectosPagados =
    'No se puede borrar la factura: tiene efectos pagados, remesados o ' +
    'conciliados.';
  SPreguntaBorrarFacturaCompra =
    '¿Borrar la factura de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y efectos, y se desmarcaran los albaranes ' +
    'vinculados.';
  SErrorCabeceraFacturaCompraSinGrabar =
    'Graba la cabecera de la factura antes de guardar lineas.';
  SErrorContadorFacturaCompra =
    'No se pudo obtener un numero de factura de compra valido. Revise el ' +
    'contador FP de la serie %s y empresa %s.';
  SAvisoAlmacenDestinoPedidoCompraObligatorio =
    'Debe seleccionar el almacén destino del pedido de compra.';
  SPreguntaBorrarPedidoCompra =
    '¿Borrar el pedido de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y pendientes de recibir.';
  SErrorContadorPedidoCompra =
    'No se pudo obtener un numero de pedido de compra valido. Revise el ' +
    'contador PC de la serie %s y empresa %s.';
  SErrorProveedorKitsNoSeleccionado =
    'Selecciona un proveedor antes de crear kits.';
  SErrorProveedorKitsSinGrabar =
    'Graba el proveedor antes de crear kits.';
  SErrorCodigoKitProveedorObligatorio =
    'El kit necesita un código (p. ej. CURVA-STD).';
  SErrorNombreKitProveedorObligatorio =
    'El kit necesita un nombre.';
  SErrorKitProveedorNoSeleccionadoParaTallas =
    'Crea o selecciona un kit antes de añadir tallas.';
  SErrorTallaDestinoKitProveedorObligatoria =
    'La fila del kit necesita la talla destino (p. ej. 38, M).';
  SErrorKitProveedorNoSeleccionado =
    'Selecciona o crea un kit primero.';
  SErrorSistemaTallasKitProveedorObligatorio =
    'El kit no tiene sistema de tallas. Asigna uno en la columna "Sistema ' +
    'tallas" para poder generar sus tallas.';
  SErrorCodigoAutomaticoProveedor =
    'No se pudo generar el código automático del proveedor.';
  SErrorOrdenAutomaticoProveedor =
    'No se pudo generar el orden automático del proveedor.';
  SErrorPrefijoEanSesionLargo =
    'PREFIJO_EAN_SES demasiado largo: %s';
  SErrorColorBasicoMaterializacionNoExiste =
    'No existe el color básico CODIGO_ATB=%s. Créalo en Mto Atributos ' +
    'Básicos antes de materializar.';
  SErrorAlmacenSesionParaAlbaranCompra =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'albaran de compra.';
  SErrorAlmacenSesionParaPedidoCompra =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'pedido de compra.';
  SErrorAlmacenSesionParaPendienteRecibir =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'pedido pendiente de recibir.';
  SAvisoSelectorConjuntoFilaNoImplementado =
    'El selector de valores del conjunto fila aun no esta implementado.' +
    sLineBreak + sLineBreak +
    'Mientras tanto, en la cabecera deja vacio el campo "Conjunto fila" ' +
    'para teclear los colores libremente.';
  STituloNuevaFilaCompra = 'Nueva fila';
  SSolicitudNombreFilaCompra =
    'Nombre de la fila (color del proveedor):';
  SAvisoConjuntoPivotCompraObligatorio =
    'Selecciona primero un "Conjunto pivot" en la cabecera de la sesion ' +
    'para poder anadirle un valor (talla).';
  SErrorConjuntoPivotCompraNoExiste =
    'El conjunto pivot no existe en la BBDD.';
  STituloAnadirValorPivotCompra =
    'Anadir talla / valor pivot';
  SSolicitudNombreValorPivotCompra =
    'Nombre del valor (ej: XXL, 47):';
  SSolicitudOrdenValorPivotCompra =
    'Orden (los SKUs se ordenan por este numero; usa pasos de 10).';
  SErrorAlbaranCompraMovimientosNoEncontrado =
    'Albaran de compra %s/%s no encontrado para generar movimientos.';
  SErrorAlbaranCompraMovimientosYaGenerados =
    'El albaran %s/%s ya tiene movimientos generados. Revierte antes de ' +
    'volver a generar.';
  SErrorAlbaranCompraSinCantidadParaMovimientos =
    'El albaran %s/%s no tiene ninguna linea o celda con cantidad > 0 para ' +
    'generar movimientos.';
  SErrorMovimientosAlbaranCompraNoRegistrados =
    'La persistencia de movimientos de albaranes de compra no esta ' +
    'registrada.';
  SErrorPedidosCompraNoRegistrados =
    'La persistencia de pedidos de compra no esta registrada.';
  SErrorMovimientosDevolucionCompraNoRegistrados =
    'La persistencia de movimientos de devoluciones de compra no esta ' +
    'registrada.';
  SErrorDevolucionCompraMovimientosNoEncontrada =
    'Devolucion de compra %s/%s no encontrada para generar movimientos.';
  SErrorDevolucionCompraMovimientosYaGenerados =
    'La devolucion %s/%s ya tiene movimientos generados. Revierte antes ' +
    'de volver a generar.';
  SErrorDevolucionCompraSinCantidadParaMovimientos =
    'La devolucion %s/%s no tiene ninguna linea o celda con cantidad > 0 ' +
    'para generar movimientos.';
  SErrorSesionCompraNoActiva = 'No hay sesion activa.';
  SErrorLineaSesionSinNumero =
    'La linea aun no tiene numero. Graba la sesion primero.';
  SErrorSistemaTallasLineaSesionObligatorio =
    'La linea no tiene sistema de tallas. Asignale uno en la columna ' +
    '"Sistema tallas" antes de aplicar el kit.';
  SErrorKitProveedorNoExiste =
    'El kit %s no existe para el proveedor %s.';
  SErrorKitSinSistemaTallas =
    'El kit %s no tiene sistema de tallas. Asignaselo en Proveedores, ' +
    'pestaña Compras, para poder comprobar que coincide con el de la linea.';
  SErrorTallajeKitNoCoincide =
    'El tallaje del kit no coincide con el de la linea: kit = "%s", linea ' +
    '= "%s". Cambia el sistema de tallas de la linea o elige un kit de su ' +
    'mismo tallaje.';
  SErrorGestorTallasNoInicializado =
    'Gestor de tallas no inicializado.';
  SErrorKitSinTallasDefinidas =
    'El kit %s no tiene tallas definidas. Completalo en Proveedores, ' +
    'pestaña Compras.';
  SAvisoTallasKitSinCorrespondencia =
    'Tallas del kit sin correspondencia en el sistema de la linea (no ' +
    'aplicadas): %s';
  SErrorTallasKitSinCorrespondencia =
    'Ninguna talla del kit casa con el sistema de tallas de la linea.';
  SErrorSesionIncidenciasSinDetalle =
    'Hay incidencias sin detalle.';
  SErrorDataModuleSesionNoInicializado =
    'DataModule no inicializado.';
  SErrorSesionNoCerradaParaRevertir =
    'La sesion no esta CERRADA, no hay nada que revertir.';
  STextoLineaIncidenciaSesion = 'Linea %d';
  STextoCabeceraIncidenciaSesion = 'Cabecera';
  SFormatoIncidenciaSesion = '[%s] %s: %s';
  SErrorSesionInactivaIncidencia =
    '[CABECERA] No hay sesion activa.';
  STipoIncidenciaCabecera = 'CABECERA';
  SErrorEmpresaSesionFaltante =
    'Falta CODIGO_EMP_SES (Empresa).';
  SErrorProveedorSesionFaltante =
    'Falta CODIGO_PRV_SES (Proveedor).';
  SErrorAlmacenSesionFaltante =
    'ESGENERA_ALBARAN=S pero no hay CODIGO_ALM_SES (Almacen).';
  SErrorSesionSinLineas = 'La sesion no tiene lineas.';
  STipoIncidenciaDuplicadoInterno = 'DUP_INTRA';
  SErrorCodigoDuplicadoInternoSesion =
    'Codigo %s repetido dentro de la sesion (primera vez en linea %d). ' +
    'Marca esta linea como REUSAR o cambia el codigo.';
  STipoIncidenciaDuplicado = 'DUPLICADO';
  SErrorCodigoDuplicadoSesion =
    'Codigo %s ya existe en fza_articulos%s. Decide REUSAR o RENOMBRAR.';
  STipoIncidenciaCodigo = 'CODIGO';
  SErrorLineaSesionSinCodigo =
    'La linea no tiene CODIGO_ART_TENTATIVO_SESLIN.';
  STipoIncidenciaDescripcion = 'DESCRIPCION';
  SErrorLineaSesionSinDescripcion =
    'Linea sin descripcion (codigo %s).';
  STipoIncidenciaCantidades = 'CANTIDADES';
  SErrorLineaMatrizSinCantidades =
    'Linea MATRIZ sin cantidades por talla (codigo %s - %s).';
  STipoIncidenciaSistemaTallas = 'SISTEMA_TALLAS';
  SErrorLineaMatrizSinSistemaTallas =
    'Linea MATRIZ sin sistema de tallas (codigo %s).';
  SErrorColorCompraNoSeleccionado = 'Selecciona un color.';
  SErrorConexionResolverColorCompra =
    'No hay conexión para resolver el color.';
  SErrorColorBasicoCompraNoExiste =
    'No existe el color básico "%s".';
  SErrorResolverColorCompra =
    'No se pudo resolver el color "%s".';
  SErrorSistemaTallasSuperaMaximoPivote =
    '- Articulo %s: sistema "%s" con %d tallas (maximo %d).';
  SErrorActivarPivoteTallas =
    'No se puede activar el modo pivote por tallas:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Se mantiene la vista plana (linea por SKU).';
  SErrorActivarTallasHorizontalesParaColor =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorLineaActivaColorNoDisponible =
    'No hay una línea activa para cambiar el color.';
  SErrorColorCompraConCantidades =
    'El color se elige antes de introducir cantidades. Crea una línea de ' +
    'color nueva para no mezclar tallas.';
  SErrorConsultaLineasCompraNoAbierta =
    'No está abierta la consulta de líneas.';
  SErrorLineaActivaColorNoEncontrada =
    'No se encontró la línea activa para cambiar el color.';
  SErrorLineaActivaCompraSinArticulo =
    'La línea activa no tiene artículo.';
  SErrorPedidoCompraSinPendientesAlmacen =
    'No hay lineas pendientes de recibir para el almacen "%s" en el pedido ' +
    '%s/%s.';
  SErrorAlmacenPedidoCompraNoSeleccionado =
    'Debes seleccionar un almacen.';
  SErrorPedidoCompraSinCantidadesRecibir =
    'No hay cantidades "A recibir" tecleadas para el almacen "%s" en el ' +
    'pedido %s/%s.';
  SErrorContadorAlbaranCompraNoDisponible =
    'No se pudo obtener un numero de albaran del contador "AB".';
  SErrorCrearLineasAlbaranCompra =
    'No se pudo crear ninguna linea del albaran (lineas origen no ' +
    'encontradas o sin pendiente de recibir).';
  SInfoAlbaranCompraCreado =
    'Albaran %s/%s creado correctamente (%d lineas).';
  SErrorAlbaranCompraDestinoNoSeleccionado =
    'Debes seleccionar el albaran de destino.';
  SInfoLineasIncorporadasAlbaranCompra =
    'Lineas incorporadas al albaran %s/%s.';
  SErrorIncorporarLineasAlbaranCompra =
    'No se pudo incorporar ninguna linea (lineas origen no encontradas o ' +
    'sin pendiente de recibir).';
  SInfoLineasIncorporadasAlbaranCompraConCantidad =
    'Lineas incorporadas al albaran %s/%s (%d lineas).';
  SErrorArticuloSinSistemaTallasCompra =
    '- Articulo sin sistema de tallas: %s';
  SErrorActivarTallasHorizontalesCompra =
    'No se puede activar tallas en horizontal:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Asigna un sistema de tallas o elimina la linea.';
  SErrorAlbaranCompraNoAbierto =
    'No está abierto el albarán de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorAlbaranCompraNoInicializado =
    'No esta inicializado el albaran de compra.';
  STextoAlbaranCompra = 'un albaran';
  SPreguntaAbrirSeriesAlbaranCompra =
    'No hay series de albaranes de compra (tipo AB) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranCompraSinImpresionActivo =
    'No hay albaran de compra activo que imprimir.';
  SErrorAlbaranCompraNoActivo =
    'No hay albaran de compra activo.';
  SPreguntaGrabarAlbaranCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorAlbaranCompraNecesarioElegirEmpresa =
    'Crea o selecciona un albarán de compra antes de elegir la empresa.';
  SErrorAlbaranCompraNecesarioElegirProveedor =
    'Crea o selecciona un albarán de compra antes de elegir el proveedor.';
  SAvisoAlbaranCompraSinPedido =
    'Este albaran no procede de ningun pedido de compra.';
  SAvisoAlbaranCompraSinFactura =
    'Este albaran no tiene factura de compra creada.';
  SPreguntaEliminarLineaAlbaranCompra =
    'Esta seguro de que desea eliminar esta linea?';
  SPreguntaBorrarPropiedadPlantillaCompra =
    '¿Borrar la propiedad?';
  SPreguntaBorrarKitPlantillaCompra = '¿Borrar el kit?';
  SErrorCabeceraSesionAntesLineas =
    'Crea y graba la cabecera de la sesion antes de anadir lineas.';
  SErrorSesionSinDocumentosCreados =
    'La sesion no tiene documentos creados.';
  SErrorMantenimientoTipoDocumentoNoDisponible =
    'No hay mantenimiento disponible para el tipo de documento "%s".';
  SPreguntaAbrirSeriesSesionCompra =
    'No hay series de sesiones de compra (tipo SE) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorSesionElegirProveedorNoSeleccionada =
    'Crea o selecciona una sesion antes de elegir el proveedor.';
  SErrorProveedorSesionSinKits =
    'El proveedor de la sesion no tiene kits definidos. Se crean en ' +
    'Proveedores, pestaña Compras.';
  SErrorKitProveedorDesplegableNoSeleccionado =
    'Elige un kit del proveedor en el desplegable.';
  SPreguntaBorrarLineaSesionCompra =
    'Borrar la linea seleccionada?';
  SErrorSesionYaMaterializada =
    'La sesion ya esta cerrada. No se puede materializar dos veces.';
  SInfoDuplicadosSesionMarcadosReusar =
    'Se han detectado y marcado %d linea(s) como REUSAR de codigos ' +
    'repetidos dentro de esta sesion (variantes color/SKU del mismo ' +
    'articulo). La materializacion crea el articulo una sola vez.';
  SInfoSesionMaterializadaSinDocumentos =
    'Sesion materializada (sin documentos).';
  SErrorSesionNoCerradaParaReversion =
    'La sesion no esta CERRADA. Solo se pueden revertir sesiones ' +
    'materializadas.';
  SErrorReversionSesionConIncidencias =
    'No se puede revertir la sesion porque sus documentos tienen ' +
    'dependencias:' + sLineBreak + '%s' + sLineBreak +
    'No se ha modificado ningun dato.';
  SIncidenciaReversionFacturaCompra =
    '- El albaran de compra %s esta incluido en la factura de compra %s.';
  SIncidenciaReversionSalidaPosterior =
    '- El albaran de compra %s tiene una venta u otra salida posterior ' +
    'que afecta al stock: %s.';
  SIncidenciaReversionPedidoRecibido =
    '- El pedido de compra %s ya fue recibido o tiene un albaran ' +
    'dependiente: %s.';
  SIncidenciaReversionTipoDocumento =
    '- La sesion contiene un documento de tipo no soportado: %s %s.';
  SIncidenciaReversionDocumentoIncompleto =
    '- La sesion contiene una referencia %s incompleta (serie "%s", ' +
    'numero "%s").';
  SIncidenciaReversionReferenciaSinMapa =
    '- La referencia %s %s de la cabecera no aparece en el mapa de ' +
    'documentos de la sesion.';
  SIncidenciaReversionDocumentoCompartido =
    '- El documento %s %s tambien esta vinculado a la sesion %s.';
  SPreguntaRevertirSesionCompra =
    'Se borraran los pedidos, albaranes y movimientos de almacen creados ' +
    'por esta sesion, que volvera a BORRADOR.' + sLineBreak + sLineBreak +
    'La operacion se bloqueara si esos documentos estan facturados, si ' +
    'el pedido ya fue recibido o si hay ventas u otras salidas ' +
    'posteriores de stock.' +
    sLineBreak + sLineBreak +
    'Los articulos / SKUs / codigos de barras se conservan ' +
    '(re-materializar es idempotente).' + sLineBreak + sLineBreak +
    'Continuar?';
  SInfoSesionRevertida = 'Sesion revertida. Estado: BORRADOR.';
  SErrorRevertirSesionCompra =
    'No se pudo revertir la sesion:' + sLineBreak + '%s';
  SErrorSesionActivaImprimirNoDisponible =
    'No hay sesion activa que imprimir.';
  SErrorSistemasTallasSesionNoDisponibles =
    'No hay sistemas de tallas activos en fza_atributos_conjuntos ' +
    '(ID_VA_AC=''TAL'').';
  SErrorCambiarSistemaTallasModeloExistente =
    'El sistema de tallas no se puede cambiar en un modelo que ya existe: ' +
    'queda fijado al del articulo. Solo puedes anadir colores o tallas ' +
    'nuevos.';
  SErrorColoresBasicosSesionNoDisponibles =
    'No hay colores basicos cargados en fza_atributos_basicos para ' +
    'ID_VA=''CO''.';
  SErrorEfectosCompraFusionInsuficientes =
    'Selecciona dos o más efectos impagados.';
  SPreguntaAbrirSeriesDevolucionCompra =
    'No hay series de devoluciones a proveedor (tipo DC) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorLineaColorDevolucionNoEncontrada =
    'No se ha encontrado ninguna linea de ese color.';
  SErrorDevolucionCompraSinImpresionActiva =
    'No hay devolucion de compra activo que imprimir.';
  SErrorDevolucionCompraNoActiva =
    'No hay devolucion de compra activo.';
  SErrorProveedorDevolucionFilaNoSeleccionado =
    'Selecciona un proveedor antes de devolver la fila.';
  SErrorAlmacenDevolucionFilaNoSeleccionado =
    'Selecciona el almacen de salida antes de devolver el stock.';
  SErrorColorDevolucionFilaNoSeleccionado =
    'Selecciona el color de la fila antes de devolver su stock.';
  SPreguntaGrabarDevolucionCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorDevolucionCompraNoAbierta =
    'No está abierta la devolución de compra.';
  SErrorDevolucionCompraElegirEmpresaNoSeleccionada =
    'Crea o selecciona una devolución de compra antes de elegir la empresa.';
  SErrorDevolucionCompraElegirProveedorNoSeleccionada =
    'Crea o selecciona una devolución de compra antes de elegir el ' +
    'proveedor.';
  SPreguntaEliminarLineaDevolucionCompra =
    'Esta seguro de que desea eliminar esta linea?';
  SPreguntaAbrirSeriesFacturaCompra =
    'No hay series de facturas de compra (tipo FP) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorFacturaCompraNoAbierta =
    'No está abierta la factura de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorFacturaCompraSinImpresionActiva =
    'No hay factura de compra activa que imprimir.';
  SAvisoEtiquetasBorradorCompraPendientes =
    'Etiquetas de borrador de compra: pendiente (hito de informes).';
  SPreguntaGrabarFacturaCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorFacturaCompraNoInicializada =
    'No esta inicializada la factura de compra.';
  SErrorFacturaCompraElegirProveedorNoSeleccionada =
    'Crea o selecciona una factura de compra antes de elegir el proveedor.';
  SInfoGeneracionEfectosPagoCancelada =
    'Generación de efectos cancelada.';
  SInfoEfectosPagoGenerados =
    'Generados %d efecto(s) de pago.';
  SAvisoEfectosPagoNoGenerados =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga ya efectos pagados o remesados.';
  SErrorGenerarEfectosPagoSinBorrador =
    'No hay borrador activo (o hubo un error al generar).';
  SErrorEfectoCompraNoSeleccionado =
    'Selecciona un efecto en la rejilla de la pestana Efectos.';
  SPreguntaEliminarLineaFacturaCompra =
    'Esta seguro de que desea eliminar esta linea?';
  SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorPedidoCompraNoAbierto =
    'No está abierto el pedido de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorPedidoCompraNoInicializado =
    'No esta inicializado el pedido de compra.';
  STextoPedidoCompra = 'un pedido';
  SErrorExpandirRecibidosNoActivo =
    'Activa "Expandir recibidos" antes de usar este atajo.';
  SInfoTallasPendientesRecibirNoDisponibles =
    'No hay tallas pendientes de recibir en la fila activa.';
  SInfoPedidoCompraSinPendientesRecibir =
    'No hay nada pendiente de recibir en el pedido.';
  SPreguntaGrabarPedidoCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorPedidoCompraNecesarioElegirEmpresa =
    'Crea o selecciona un pedido de compra antes de elegir la empresa.';
  SErrorPedidoCompraNecesarioElegirProveedor =
    'Crea o selecciona un pedido de compra antes de elegir el proveedor.';
  SErrorTallasHorizontalesNecesariasElegirColor =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorArticuloNoSeleccionadoElegirColorPedidoCompra =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloPedidoCompraSinColoresBasicos =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SPreguntaEliminarLineaPedidoCompra =
    'Esta seguro de que desea eliminar esta linea?';
  SPreguntaAbrirSeriesPedidoCompra =
    'No hay series de pedidos de compra (tipo PC) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoCompraNoActivo =
    'No hay pedido de compra activo.';
  SErrorPedidoCompraNoActivoCrearAlbaran =
    'No hay pedido activo del que crear albaran.';
  SErrorCrearAlbaranDesdePedidoCompra =
    'Error al crear el albaran: %s';
  SPreguntaBorrarKitProveedor =
    '¿Borrar el kit seleccionado y todas sus tallas?';
  SErrorRemesaCompraNoSeleccionada = 'Selecciona una remesa.';
  SErrorEliminarRemesaCompraConCargo =
    'No se puede eliminar una remesa con cargo realizado.';
  SPreguntaEliminarRemesaCompra =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaCompraEliminada = 'Remesa eliminada.';
  SErrorEliminarRemesaCompra =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaCompraConCargo =
    'No se pueden añadir efectos a una remesa con cargo realizado.';
  SErrorEfectosRemesaCompraNoCargados =
    'No hay efectos cargados.';
  SErrorEfectoRemesaCompraNoSeleccionado =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaCompraConCargo =
    'No se pueden quitar efectos de una remesa con cargo realizado.';
  SPreguntaQuitarEfectoRemesaCompra =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaCompraQuitado =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaCompra =
    'No se pudo quitar el efecto.';
  SErrorEfectoRemesaCompraSinPendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaCompra =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaCompraConciliado = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaCompra =
    'No se pudo conciliar el efecto.';
  SErrorRemesaCompraSinImportePendiente =
    'La remesa no tiene importe pendiente.';
  STextoRemesaCompraPendiente = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaCompraConciliados =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaCompra =
    'No se pudo conciliar la remesa.';
  SErrorBancoPagoNoSeleccionado =
    'Selecciona un banco de pago.';
  SErrorTipoDocumentoSesionNoSeleccionado =
    'Marca al menos uno: Albaran y/o Pedido.';
  SErrorAlmacenDestinoSesionNoIndicado =
    'Indica un almacen destino.';
  SErrorFacturaCompraExportarNoPreparada =
    'No hay factura de compra preparada para exportar.';
  // R02 - Pestaña de líneas de documentos de compra
  SCaptionTabLineasCompra = '&1_Líneas';
  // Conserva el espacio final: distingue el modo sin construir
  SCaptionTabLineasCompraSinConstruir = '&1_Líneas ';
  // R03 - Sesiones de compra: foto provisional y modal de modelo
  SCaptionSeleccioneLineaSesion =
    'Seleccione una línea de la sesión.';
  SCaptionLineaFotoDetalle = 'Línea %d · %s · %s';
  SCaptionLineaSinFotoProvisional =
    'Línea %d · sin foto provisional';
  SCaptionDestinoArticulo = 'artículo';
  SCaptionDestinoSku = 'SKU %s';
  SErrorLineaSesionDescargarFotosNoSeleccionada =
    'Selecciona o crea una linea antes de descargar fotos.';
  SErrorLineaSesionSinCodigoArticulo =
    'La linea activa no tiene codigo de articulo.';
  SErrorDescargarFotosArticulo =
    'No se pudieron descargar las fotos del articulo %s:' + sLineBreak +
    '%s';
  SInfoFotosArticuloDescargadas =
    'Descargadas %d foto(s) del articulo %s.';
  SErrorLineaSesionAsignarFotoNoSeleccionada =
    'Selecciona o crea una linea antes de asignar foto.';
  SInfoFotoLineaSesionAsignada =
    'Foto asignada a la linea %d.';
  SErrorAsignarFotoSesion = 'No se pudo asignar la foto.';
  SErrorGuardarFotoSesion = 'Error guardando foto: %s';
  SCaptionModeloCompra = 'Modelo';
  SCaptionCodigoCompra = 'Codigo';
  // R05 - Pestaña de líneas de documentos de compra sin acelerador
  SCaptionTabLineasDocCompra = 'Líneas';
  // Conserva el espacio final: distingue el modo sin construir
  SCaptionTabLineasDocCompraSinConstruir = 'Líneas ';
  // R07 - Pedidos de compra
  SCaptionContextoTallaPedido =
    'Talla %s    Pedido: %.0f    Recibido: %.0f';
  SCaptionAlbaranCreadoPedidoCompra =
    'Albaran creado desde el pedido %s/%s';
  // R11 - Modales de sesiones de compra y recepción
  SCaptionModeloYaEnLinea =
    'El modelo %s ya está en la línea %d de esta sesión. ' +
    '¿Qué quieres hacer?';
  SCaptionCrearAlbaranDesdePedidoCompra =
    'Crear albarán desde pedido %s';
  SCaptionCodigoExistente = 'Código existente: %s';
implementation

end.
