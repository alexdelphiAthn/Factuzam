{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgVentas                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de clientes y documentos del circuito de ventas.                 }
{******************************************************************************}
unit inLibMsgVentas;

interface

resourcestring
  SPreguntaBorrarAlbaran =
    '¿Borrar el albaran %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SAvisoAlmacenSalidaAlbaranObligatorio =
    'Debe seleccionar el almacén de salida del albarán.';
  SErrorCabeceraAlbaranSinGrabar =
    'Graba la cabecera del albaran antes de guardar lineas.';
  SErrorAsignarLineaAlbaran =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en ' +
    'la base de datos.';
  SErrorContadorAlbaran =
    'No se pudo obtener un numero de albaran valido. Revise el contador ' +
    'AV de la serie %s y empresa %s.';
  SErrorRazonSocialCliente =
    '%s no es un valor válido para el campo Razón Social de Cliente';
  SErrorTipoDestinoDocumentoTrabajo =
    'El tipo de destino debe ser USUARIO o GRUPO.';
  SErrorDestinoCompartidoNoExiste =
    'El usuario o grupo indicado no existe.';
  SErrorDestinoCompartirObligatorio =
    'Indique el usuario o grupo con el que comparte.';
  SErrorCompartirDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede compartir el Documento de Trabajo.';
  SErrorCabeceraDocumentoTrabajoSinGrabar =
    'Grabe primero la cabecera del Documento de Trabajo.';
  SErrorCompartirDocumentoTrabajoConsigoMismo =
    'No es necesario compartir el documento consigo mismo.';
  SErrorBorrarDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede borrar un Documento de Trabajo.';
  SErrorCambiarPropietarioDocumentoTrabajo =
    'El propietario del Documento de Trabajo no se puede cambiar.';
  SErrorTituloDocumentoTrabajoObligatorio =
    'Indique el titulo del Documento de Trabajo.';
  SErrorEstadoDocumentoTrabajoNoValido =
    'El estado del Documento de Trabajo debe ser CREADO, ENVIADO o ' +
    'ARCHIVADO.';
  SErrorModificarDocumentoTrabajoNoPermitido =
    'Solo se pueden modificar documentos propios en estado CREADO.';
  SErrorEnviarDocumentoTrabajoNoPermitido =
    'Solo se pueden enviar documentos en estado CREADO.';
  SErrorArchivarDocumentoTrabajoNoPermitido =
    'Solo se pueden archivar documentos propios en estado CREADO o ENVIADO.';
  SErrorActualizarEstadoDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede cambiar el estado del Documento de Trabajo.';
  SErrorActualizarEstadoDocumentoTrabajo =
    'No se pudo actualizar el estado del Documento de Trabajo. ' +
    'Actualice la lista y vuelva a intentarlo.';
  SPreguntaArchivarDocumentoTrabajo =
    '¿Archivar el Documento de Trabajo seleccionado?';
  SInfoDocumentoTrabajoArchivado =
    'Documento de Trabajo archivado.';
  SErrorBorrarLineasDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede borrar lineas del Documento de Trabajo.';
  SErrorEditarLineasDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede editar lineas del Documento de Trabajo.';
  SErrorDejarCompartirDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede dejar de compartir el Documento de Trabajo.';
  SErrorDestinoCompartidoObligatorio =
    'Indique el usuario o grupo con el que se comparte.';
  SErrorBorrarEfectoVentaRemesado =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de cobro.';
  SErrorBorrarEfectoVentaCobrado =
    'No se puede borrar el efecto: tiene cobro o conciliación registrada.';
  SErrorFusionarEfectosVentaEstado =
    'Solo se pueden fusionar efectos pendientes, sin cobros, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosVentaOrigen =
    'Solo se pueden fusionar efectos de la misma empresa y cliente.';
  SErrorFusionarEfectosVentaSinPendiente =
    'Los efectos seleccionados no tienen importe pendiente.';
  SErrorOperacionIntracomunitariaClienteNoUE =
    'La operacion "%s" es intracomunitaria, pero el cliente no es de la UE ' +
    '(pais %s). Corrija el tipo de operacion o el pais del cliente.';
  SErrorOperacionExportacionClienteNoExtranjero =
    'La operacion "%s" es exportacion fuera de la UE, pero el cliente es ' +
    'comunitario o nacional. Corrija el tipo o el pais del cliente.';
  SErrorNifIvaClienteExtranjero =
    'El cliente es extranjero (pais %s) y Verifactu exige su NIF-IVA. ' +
    'Indique el NIF del cliente.';
  SErrorRazonSocialClienteBorrador =
    'Debe escribir la razón social del cliente del borrador';
  SErrorPaisClienteEmpresaBorrador =
    'Debe seleccionar un pais para cliente y empresa.';
  SPreguntaBorrarPedidoVenta =
    '¿Borrar el pedido de venta %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se descontara el pendiente de servir en ' +
    'stock.';
  SErrorCabeceraPedidoSinGrabar =
    'Graba la cabecera del pedido antes de guardar lineas.';
  SErrorAsignarLineaPedido =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en la ' +
    'base de datos.';
  SAvisoAlmacenSalidaPedidoObligatorio =
    'Debe seleccionar el almacén de salida del pedido.';
  SAvisoClientePedidoObligatorio =
    'Debe seleccionar un cliente antes de guardar el pedido.';
  SAvisoClientePedidoNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de guardar ' +
    'el pedido.';
  SErrorRemesaVentaNoSeleccionada = 'Selecciona una remesa.';
  SErrorRemesaVentaNoEncontrada =
    'No se encuentra la remesa de venta.';
  SErrorRemesaVentaSinEfectosPendientes =
    'La remesa no tiene efectos pendientes.';
  SErrorGuardarCodigoAcreedorSepa =
    'No se pudo guardar el código acreedor SEPA.';
  SErrorGuardarMandatoSepaCliente =
    'No se pudo guardar el mandato SEPA del cliente %s.';
  SPreguntaCrearDocumentoTrabajo =
    'Si = crear un Documento de Trabajo nuevo.' + sLineBreak +
    'No = agregar a uno abierto existente.';
  STituloAgregarDocumentoTrabajo =
    'Agregar a Documento de Trabajo';
  STituloNuevoDocumentoTrabajo =
    'Nuevo Documento de Trabajo';
  SSolicitudTituloDocumentoTrabajo = 'Titulo';
  SInfoUnidadAgregadaDocumentoTrabajo =
    'Unidad agregada al Documento de Trabajo.';
  STituloDocumentoTrabajo = 'Documento de Trabajo';
  SInfoLineaPedidoTallaNoExiste =
    'No existe línea de pedido para esa talla.';
  SErrorContextoSinIban = '%s sin IBAN.';
  SErrorContextoIbanNoValido =
    '%s con IBAN no válido: %s';
  SErrorNifEmpresaAcreedorSepaNoValido =
    'NIF de empresa no válido para acreedor SEPA: %s';
  SErrorClienteSinMandatoSepa =
    'Cliente %s sin mandato SEPA.';
  STextoBancoCobroRemesa = 'Banco de cobro de la remesa';
  SErrorConexionGenerarRemesaSepa =
    'No hay conexión para generar la remesa SEPA.';
  SErrorArchivoSalidaSepaNoIndicado =
    'Indica el archivo de salida SEPA.';
  SErrorRemesaSinFechaCobro =
    'La remesa no tiene fecha de cobro.';
  SErrorBancoCobroRemesaNoEncontrado =
    'No se encuentra el banco de cobro de la remesa.';
  SErrorBancoCobroSinCodigoAcreedorSepa =
    'El banco de cobro no tiene código acreedor SEPA.';
  SErrorCodigoAcreedorSepaNoValido =
    'Código acreedor SEPA no válido: %s';
  SErrorEfectoSinNombreCliente =
    'Efecto sin nombre de cliente.';
  STextoClienteSepa = 'Cliente %s';
  SErrorClienteSinFechaFirmaMandatoSepa =
    'Cliente %s sin fecha de firma del mandato SEPA.';
  SPreguntaAbrirSeriesAlbaranVenta =
    'No hay series de albaranes de venta mayor (tipo AV) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranVentaNoAbierto =
    'No está abierto el albarán de venta.';
  SErrorAlbaranVentaNoInicializado =
    'No esta inicializado el albaran.';
  SErrorCrearSeleccionarAlbaranAntesLineas =
    'Crea o selecciona un albaran antes de anadir lineas.';
  SPreguntaEliminarLineaAlbaranVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SErrorAlbaranVentaSinLineas =
    'El albarán no tiene líneas.';
  SAvisoSeleccionarLineasBorradorAlbaran =
    'Seleccione las líneas para crear borrador en la rejilla ' +
    '(Ctrl+click para selección múltiple).';
  SAvisoLineasAlbaranConBorrador =
    'Las líneas seleccionadas ya tienen borrador.';
  SPreguntaGenerarBorradorLineasAlbaran =
    '¿Generar borrador con %d línea(s) del albarán?';
  SPreguntaGenerarBorradorTodoAlbaran =
    '¿Crear borrador con todas las líneas pendientes del albarán?';
  SAvisoAlbaranSinPedidoVenta =
    'Este albaran no procede de ningun pedido de venta.';
  SAvisoAlbaranSinBorrador =
    'Este albaran no tiene borrador creado.';
  SInfoIbanValidado = 'IBAN Validado OK';
  SErrorEfectosVentaFusionInsuficientes =
    'Selecciona dos o más efectos imcobrados.';
  SErrorDocumentoTrabajoNoSeleccionadoListado =
    'Seleccione un Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinGrabarListado =
    'Grabe el Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinLineasListado =
    'El Documento de Trabajo no tiene líneas para el listado.';
  SErrorDocumentoTrabajoNoSeleccionadoCargar =
    'Seleccione un Documento de Trabajo antes de cargar.';
  SErrorCargarDocumentoTrabajoNoPropietario =
    'Solo el propietario puede cargar articulos en el documento.';
  SErrorDocumentoTrabajoSinGrabarCargar =
    'Grabe el Documento de Trabajo antes de cargar.';
  STituloCargarOrigenDocumentoTrabajo =
    'Cargar desde documento';
  SCaptionTodosTiposOrigenDocumentoTrabajo = 'Todos';
  SDescripcionTipoOrigenAlbaranVentaDocumentoTrabajo =
    'Albarán de venta';
  SDescripcionTipoOrigenAlbaranCompraDocumentoTrabajo =
    'Albarán de compra';
  SDescripcionTipoOrigenPedidoVentaDocumentoTrabajo =
    'Pedido de venta';
  SDescripcionTipoOrigenPedidoCompraDocumentoTrabajo =
    'Pedido de compra';
  SDescripcionTipoOrigenFacturaVentaDocumentoTrabajo =
    'Factura de venta';
  SDescripcionTipoOrigenFacturaCompraDocumentoTrabajo =
    'Factura de compra';
  SDescripcionTipoOrigenDevolucionCompraDocumentoTrabajo =
    'Devolución a proveedor';
  SDescripcionTipoOrigenVentaTpvDocumentoTrabajo =
    'Venta TPV';
  SDescripcionTipoOrigenTraspasoDocumentoTrabajo =
    'Traspaso';
  SDescripcionTipoOrigenPeticionTraspasoDocumentoTrabajo =
    'Petición de traspaso';
  SDescripcionTipoOrigenSesionCompraDocumentoTrabajo =
    'Sesión de compra';
  SDescripcionTipoOrigenInventarioDocumentoTrabajo =
    'Inventario';
  SDescripcionTipoOrigenSesionTarifasDocumentoTrabajo =
    'Sesión de cambio de tarifas';
  SErrorServicioCargaOrigenDocumentoTrabajo =
    'No está disponible el servicio de carga desde documentos.';
  SErrorOrigenDocumentoTrabajoNoSeleccionado =
    'Seleccione un documento de origen.';
  SInfoDocumentosOrigenDocumentoTrabajoNoEncontrados =
    'No se encontraron documentos con esos filtros entre los últimos ' +
    'documentos mostrados.';
  SInfoCargaOrigenDocumentoTrabajo =
    'Se encontraron %d líneas; se añadieron %d y se omitieron %d.' +
    sLineBreak + 'Unidades añadidas: %.2f.';
  SErrorTipoDocumentoOrigenNoSoportado =
    'El tipo de documento origen "%s" no está soportado.';
  SErrorDocumentoOrigenIncompleto =
    'Indique empresa, tipo, serie y número del documento origen.';
  SErrorDocumentoOrigenNoEncontrado =
    'No existe el documento origen %s %s/%s para la empresa %s.';
  SErrorDocumentoOrigenCancelado =
    'No se puede cargar el documento origen %s %s/%s porque está ' +
    'cancelado.';
  SErrorDocumentoOrigenLineasSinSku =
    'No se puede cargar el documento origen porque hay %d líneas de ' +
    'artículo y cantidad sin un SKU compatible registrado.';
  SErrorCargaDocumentoOrigenIncompleta =
    'No se completó la carga del documento origen: se esperaban %d ' +
    'líneas y se insertaron %d.';
  SErrorEmpresaDocumentoTrabajoOrigenDistinta =
    'El documento de trabajo y el documento origen deben ser de la misma ' +
    'empresa.';
  SErrorDocumentoTrabajoNoSeleccionadoCompartir =
    'Seleccione un Documento de Trabajo antes de compartir.';
  SInfoDocumentoTrabajoCompartido = 'Documento compartido.';
  SInfoDocumentoTrabajoYaCompartido =
    'El Documento de Trabajo ya estaba compartido.';
  SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas =
    'Grabe el Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas =
    'Seleccione un Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoEnviar =
    'Seleccione un Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinGrabarEnviar =
    'Grabe el Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinLineasEnviar =
    'El Documento de Trabajo no tiene lineas que enviar.';
  SErrorContadorAlbaranDocumentoTrabajo =
    'El contador de albaranes no ha devuelto numero para la serie %s.';
  SInfoAlbaranDocumentoTrabajoCreado =
    'Albarán de venta %s/%s creado ABIERTO con %d líneas.' + sLineBreak +
    'Asigna cliente, tarifa y precios en el Mto de albaranes.';
  STituloEnviarFacturaVentaDocumentoTrabajo =
    'Enviar a factura de venta';
  SErrorContadorFacturaVentaDocumentoTrabajo =
    'El contador de facturas de venta no ha devuelto número para la ' +
    'serie %s.';
  SInfoFacturaVentaDocumentoTrabajoCreada =
    'Factura de venta %s/%s creada en BORRADOR con %d líneas.' +
    sLineBreak +
    'Asigna cliente, tarifa, precios e impuestos antes de consolidarla.';
  STituloEnviarPedidoCompraDocumentoTrabajo =
    'Enviar a pedido de compra';
  SErrorContadorPedidoCompraDocumentoTrabajo =
    'El contador de pedidos de compra no ha devuelto número para la ' +
    'serie %s.';
  SInfoPedidoCompraDocumentoTrabajoCreado =
    'Pedido de compra %s/%s creado ABIERTO con %d líneas.' + sLineBreak +
    'Asigna proveedor, precios y condiciones de compra.';
  STituloEnviarAlbaranCompraDocumentoTrabajo =
    'Enviar a albarán de compra';
  SErrorContadorAlbaranCompraDocumentoTrabajo =
    'El contador de albaranes de compra no ha devuelto número para la ' +
    'serie %s.';
  SInfoAlbaranCompraDocumentoTrabajoCreado =
    'Albarán de compra %s/%s creado ABIERTO con %d líneas.' + sLineBreak +
    'Aún no se ha generado la entrada de stock.' + sLineBreak +
    'Asigna proveedor, precios y condiciones antes de guardar el albarán.';
  STituloEnviarDevolucionCompraDocumentoTrabajo =
    'Enviar a devolución a proveedor';
  SErrorContadorDevolucionCompraDocumentoTrabajo =
    'El contador de devoluciones a proveedor no ha devuelto número para ' +
    'la serie %s.';
  SInfoDevolucionCompraDocumentoTrabajoCreada =
    'Devolución a proveedor %s/%s creada ABIERTA con %d líneas.' +
    sLineBreak +
    'Aún no se ha generado la salida de stock.' + sLineBreak +
    'Asigna proveedor, precios y condiciones antes de guardar la devolución.';
  SErrorEmpresaDocumentoTrabajoNoExiste =
    'No existe la empresa %s del Documento de Trabajo.';
  SErrorVentaTpvNoAbiertaDocumentoTrabajo =
    'La venta TPV no está abierta.' + sLineBreak +
    'Abre Caja > Ventas y repite "Enviar a... > Venta TPV" para volcar ' +
    'los SKUs en la operación en curso.';
  SInfoLineasDocumentoTrabajoVolcadasTpv =
    '%d líneas volcadas a la venta TPV.';
  SAvisoLineasDocumentoTrabajoNoVolcadasTpv =
    '%d líneas volcadas a la venta TPV; %d no se han podido resolver ' +
    '(artículo inexistente o descatalogado).';
  SInfoImpresionEfectosCobroEnRemesas =
    'La impresión de efectos de cobro se gestiona desde Remesas de Cobro.';
  SPreguntaAbrirSeriesPedidoVenta =
    'No hay series de pedidos de venta mayor (tipo PE) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoVentaNoAbierto =
    'No está abierto el pedido de venta.';
  SErrorClienteNoSeleccionadoPedidoVenta =
    'Debe seleccionar un cliente antes de añadir líneas.';
  SErrorClientePedidoVentaNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de añadir ' +
    'líneas.';
  SErrorPedidoVentaNoInicializado =
    'No esta inicializado el pedido.';
  SErrorCrearSeleccionarPedidoAntesLineas =
    'Crea o selecciona un pedido antes de anadir lineas.';
  SPreguntaEliminarLineaPedidoVentaConTallas =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SPreguntaEliminarLineaPedidoVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaMarcarLineasPendientesAlbaranar =
    'Marcar todas las líneas pendientes para albaranar?';
  SErrorPedidoVentaSinLineas = 'El pedido no tiene líneas';
  SErrorPedidoVentaSinCantidadAlbaranar =
    'No hay líneas con cantidad a albaranar para crear el albarán.';
  SErrorAnadirAlbaranDesdePedidoVenta =
    'No se pudo anadir al albaran.';
  SErrorCrearAlbaranDesdePedidoVenta =
    'No se pudo crear el albaran.';
  SErrorBancoPagoRemesaNoAsignado =
    'Asigna primero el banco de pago de la remesa.';
  SInfoBancoPagoRemesaAsignado =
    'Banco de pago asignado.';
  SErrorAsignarBancoPagoRemesa =
    'No se pudo asignar el banco de pago.';
  STituloFechaCargoRemesa = 'Fecha de cargo';
  SSolicitudFechaCargoRemesa = 'Fecha de cargo:';
  SInfoFechaCargoRemesaActualizada =
    'Fecha de cargo actualizada.';
  SErrorActualizarFechaCargoRemesa =
    'No se pudo actualizar la fecha de cargo.';
  SErrorFechaCargoRemesaNoValida = 'Fecha no válida.';
  SErrorEliminarRemesaVentaConCobro =
    'No se puede eliminar una remesa con cobro realizado.';
  SPreguntaEliminarRemesaVenta =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaVentaEliminada = 'Remesa eliminada.';
  SErrorEliminarRemesaVenta =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaVentaConCobro =
    'No se pueden añadir efectos a una remesa con cobro realizado.';
  SErrorEfectosRemesaVentaNoCargados =
    'No hay efectos cargados.';
  SErrorEfectoRemesaVentaNoSeleccionado =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaVentaConCobro =
    'No se pueden quitar efectos de una remesa con cobro realizado.';
  SPreguntaQuitarEfectoRemesaVenta =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaVentaQuitado =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaVenta =
    'No se pudo quitar el efecto.';
  SErrorBancoCobroRemesaNoAsignado =
    'Asigna primero el banco de cobro de la remesa.';
  SErrorEfectoRemesaVentaSinPendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaVenta =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaVentaConciliado = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaVenta =
    'No se pudo conciliar el efecto.';
  SErrorRemesaVentaSinImportePendiente =
    'La remesa no tiene importe pendiente.';
  STextoRemesaVentaPendiente = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaVentaConciliados =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaVenta =
    'No se pudo conciliar la remesa.';
  SErrorBancoCobroNoSeleccionado =
    'Selecciona un banco de cobro.';
  SInfoBancoCobroRemesaAsignado =
    'Banco de cobro asignado.';
  SErrorAsignarBancoCobroRemesa =
    'No se pudo asignar el banco de cobro.';
  STituloFechaCobroRemesa = 'Fecha de cobro';
  SSolicitudFechaCobroRemesa = 'Fecha de cobro:';
  SInfoFechaCobroRemesaActualizada =
    'Fecha de cobro actualizada.';
  SErrorActualizarFechaCobroRemesa =
    'No se pudo actualizar la fecha de cobro.';
  SErrorFechaCobroRemesaNoValida = 'Fecha no válida.';
  SInfoOrdenSepaRemesaVentaGenerada =
    'Orden SEPA generada con %d cobro(s).';
  SErrorGenerarOrdenSepaRemesaVenta =
    'No se pudo generar la orden SEPA: %s';
  SErrorDestinoDocumentoTrabajoAddBlock =
    'No se ha recibido el Documento de Trabajo destino.';
  SErrorAlmacenesDocumentoTrabajoAddBlock =
    'Seleccione al menos un almacen para cargar articulos.';
  SPreguntaConfirmarDocumentoTrabajoAddBlock =
    'Se van a cargar %d SKU en el Documento de Trabajo "%s".' +
    sLineBreak +
    'Solo se anadiran los SKU previsualizados que mantengan la reserva ' +
    'configurada en los almacenes de origen.' + sLineBreak +
    'La cantidad a servir no superara el maximo indicado por SKU.' +
    sLineBreak +
    sLineBreak + 'Continuar?';
  SCaptionExcluirSkuDocumentoTrabajoAddBlock =
    'Excluir SKU ya en el documento';
  SInfoLineasDocumentoTrabajoAddBlock =
    '%d lineas anadidas al Documento de Trabajo.';
  SErrorInsertarLineasDocumentoTrabajoAddBlock =
    'Error al insertar lineas del documento: ';
  SErrorEmpresaEfectosRemesaNoIndicada =
    'Indica la empresa.';
  SInfoEfectosPendientesRemesaNoEncontrados =
    'No hay efectos pendientes sin remesar para esa empresa.';
  SErrorEfectosRemesaNoSeleccionados =
    'Marca al menos un efecto (Ctrl/Mayus+clic).';
  SErrorRemesaExistenteNoSeleccionada =
    'Elige la remesa existente.';
  SInfoEfectosCargadosRemesa =
    'Cargados %d efecto(s) en la remesa %s / %s.' + sLineBreak +
    'Omitidos (ya remesados o %s): %d.';
  SErrorSerieAlbaranSesionNoIndicada =
    'Indica la serie del albaran.';
  SErrorSeriePedidoSesionNoIndicada =
    'Indica la serie del pedido.';
  SInfoAlbaranesPendientesProveedorNoEncontrados =
    'No hay albaranes pendientes de crear borrador para ese proveedor.';
  SErrorBorradorAlbaranesExistenteNoSeleccionado =
    'Elige el borrador existente al que incorporar los albaranes.';
  SInfoAlbaranesGeneradosEnBorrador =
    'Generados %d albaran(es) en el borrador %s / %s.' + sLineBreak +
    'Omitidos (ya asociados o incompatibles): %d.';
  SErrorDataModuleAlbaranesNoAsignado =
    'No hay datamodule de albaranes asignado.';
  SErrorAlbaranesNoSeleccionados =
    'No hay albaranes seleccionados.';
  SErrorClienteBorradorNoSeleccionado =
    'Seleccione el cliente del borrador.';
  SErrorDataModulePedidosNoAsignado =
    'No hay datamodule de pedidos asignado.';
  SInfoImportacionPedidosFinalizada =
    'Importación finalizada. Pedidos importados: %d. Errores: %d.';
  SErrorAlmacenPedidoNoSeleccionado =
    'Selecciona un almacen.';
  SInfoAlbaranesIncorporarNoDisponibles =
    'No hay albaranes a los que incorporar; crea uno nuevo.';
  SErrorSerieAlbaranPedidoNoIndicada =
    'Indica la serie del albaran.';
  SErrorAlmacenAlbaranNoSeleccionado =
    'Selecciona un almacen.';
  SErrorAlbaranDestinoNoSeleccionado =
    'Selecciona el albaran al que anadir las lineas.';
  SErrorCodigoAcreedorSepaNoIndicado =
    'Indica el código acreedor SEPA.';
  SErrorLongitudCodigoAcreedorSepa =
    'El código acreedor SEPA no puede superar 35 caracteres.';
  SErrorFormatoCodigoAcreedorSepaNoValido =
    'Código acreedor SEPA no válido. En España debe tener formato ESkkZZZ ' +
    'seguido del NIF.';
  SErrorSecuenciaSepaNoValida =
    'Secuencia SEPA no válida.';
  SErrorClientesSinMandatoSepa =
    'Hay clientes sin mandato SEPA.';
  SErrorMandatosSepaLongitudNoValida =
    'Hay mandatos SEPA de más de 35 caracteres.';
  SErrorClientesSinFechaFirmaMandatoSepa =
    'Hay clientes sin fecha de firma del mandato SEPA.';
  // R04 - Documentos de trabajo
  STituloImpresionEtiquetasDTR =
    'Impresion de Etiquetas de Documento de Trabajo';
  // R07 - Pedidos de venta
  SCaptionTabLineasPedidoTallas3Filas =
    '&1_Líneas [Tallas horiz. 3 filas]';
  SCaptionTabTotalesPedido = '&2_Totales';
  SCaptionTabLineasPedidoSku = '&1_Líneas [SKU]';
  SCaptionTabLineasPedidoDesglose = '&1_Líneas [Desglose]';
  SCaptionLineasAnadidasAlbaranPedido =
    'Lineas anadidas al albaran desde el pedido %s/%s';
  SCaptionAlbaranCreadoPedido =
    'Albaran creado desde el pedido %s/%s';
  // R08 - Remesas de venta
  SCaptionCrearRemesa = 'Crear remesa';
  // R09 - Modales de venta y documentos de trabajo
  SCaptionDocumentoDestino = 'Documento destino: %d - %s';
  STituloAnadirBloqueDTR = 'Anadir Bloque - Documento de Trabajo';
  SCaptionBuscandoAlbaranes = 'Buscando albaranes...';
  SCaptionAlbaranesEncontrados = 'Albaranes encontrados: %d';
  STituloBusquedaClientes = 'Búsqueda de Clientes';
  // R10 - Informes y listados de ventas
  SCaptionFiltrarInicioCompras = 'Calcular entradas desde';
  SCaptionEntradasGlobalesMovimientosVentas = 'Entradas globales';
  SCaptionSoloArticulosConVentas = 'Solo artículos con ventas';
  SCaptionArticuloAgrupacionMovimientosVentas = 'Artículo';
  SCaptionColorAgrupacionMovimientosVentas = 'Color';
  SCaptionTallaAgrupacionMovimientosVentas = 'Talla';
  SCaptionSoloEmitidas = 'Solo emitidas';
  SCaptionLineasCargadas = '%d líneas cargadas';
  SCaptionPrimeraVentaVacia = 'Primera venta: -';
  SCaptionUltimaVentaVacia = 'Última venta: -';
  SCaptionPrimeraVenta = 'Primera venta: %s';
  SCaptionUltimaVenta = 'Última venta: %s';
  SCaptionSinVentas = 'No hay ventas';
  // R11 - Modales de venta: almacén y SEPA
  SCaptionCrearAlbaranDesdePedido = 'Crear albarán desde pedido %s';
  SCaptionCodigoAcreedor = 'Código acreedor';
  SCaptionSecuencia = 'Secuencia';
  SCaptionMandatosPorCliente = 'Mandatos por cliente';
  SCaptionColCodigoMandato = 'Código';
  SCaptionColClienteMandato = 'Cliente';
  SCaptionColMandato = 'Mandato';
  SCaptionColFechaFirmaMandato = 'Fecha firma';
  // Fase 2 - Calendario de ventas tras contrato
  SErrorVentasCalendarioNoRegistrado =
    'El repositorio del calendario de ventas no está registrado.';
  SCaptionConImpuestosMovimientosVentas = 'Precios con impuestos';
  STituloOrdenacionMovimientosVentas = 'Ordenación';
  SCaptionSentidoOrdenMovimientosVentas = ' Dirección ';
  SCaptionPeriodoOrdenMovimientosVentas =
    'Los criterios usan las ventas del periodo seleccionado.';
  SCaptionSeleccioneOrdenMovimientosVentas =
    'Seleccione un criterio de ordenación:';
  SHintOrdenDetalleMovimientosVentas =
    'Ordena cada agrupación por su subtotal y el detalle del último nivel. ' +
    '% vendido es venta sobre compra; % Vtas es sobre la agrupación.';
  SOrdenArticuloDescripcionMovimientosVentas = 'Artículo / descripción';
  SOrdenUnidadesEntradaMovimientosVentas = 'Unidades entrada';
  SOrdenImporteEntradaMovimientosVentas = 'Importe entrada';
  SOrdenUnidadesVentaMovimientosVentas = 'Unidades venta';
  SOrdenImporteVentaMovimientosVentas = 'Importe venta';
  SOrdenImporteCosteMovimientosVentas = 'Importe coste';
  SOrdenBeneficioMovimientosVentas = 'Beneficio';
  SOrdenPorcentajeBeneficioMovimientosVentas = '% beneficio';
  SOrdenVentaEntradaMovimientosVentas = 'Venta - entrada';
  SOrdenPorcentajeVentaEntradaMovimientosVentas = 'Venta / entrada';
  SOrdenMargen1MovimientosVentas = 'Margen 1';
  SOrdenMargen2MovimientosVentas = 'Margen 2';
  SOrdenPorcentajeVendidoMovimientosVentas = '% vendido';
  SOrdenPorcentajeVentasMovimientosVentas = '% Vtas';
  SOrdenAscendenteMovimientosVentas = 'Ascendente';
  SOrdenDescendenteMovimientosVentas = 'Descendente';
  SCaptionSeleccionandoArticuloMovimientosVentas =
    '%s. Seleccionando artículo: %s';
  SCaptionExportandoFilasMovimientosVentas =
    'Exportando fila %s de %s';
implementation

end.
