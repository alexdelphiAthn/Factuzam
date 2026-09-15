{******************************************************************************}
{                                                                              }
{                         Módulo: inLibMsgPresupuestos                         }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibMsgPresupuestos;

interface

resourcestring
  SErrorPresupuestoVentaNoAbierto =
    'No está abierto el presupuesto de venta.';
  SErrorPresupuestoVentaNoInicializado =
    'No está inicializado el presupuesto.';
  SErrorArticuloNoSeleccionadoBuscarSkusPresupuestoVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorCrearSeleccionarPresupuestoAntesLineas =
    'Crea o selecciona un presupuesto antes de añadir líneas.';
  SPreguntaAbrirSeriesPresupuestoVenta =
    'No hay series de presupuestos de venta mayor (tipo PV) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SPreguntaEliminarLineaPresupuestoVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaGrabarPresupuestoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SAvisoAlmacenSalidaPresupuestoObligatorio =
    'Debe seleccionar el almacén de salida del presupuesto.';
  SErrorAsignarLineaPresupuesto =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en ' +
    'la base de datos.';
  SErrorCabeceraPresupuestoSinGrabar =
    'Graba la cabecera del presupuesto antes de guardar líneas.';
  SErrorContadorPresupuesto =
    'No se pudo obtener un número de presupuesto válido. Revise el ' +
    'contador PV de la serie %s y empresa %s.';
  SErrorLineaPresupuestoSinArticulo =
    'La línea del presupuesto no tiene artículo; no se puede guardar.';

  STituloBuscarArticulosLineasPresupuesto =
    'Búsqueda de Artículos en Líneas de Presupuesto';
  STituloBuscarSkusPresupuesto = 'SKUs del artículo %s';
  STituloBuscarEmpresasPresupuesto = 'Búsqueda de Empresas en Presupuestos';
  STituloBuscarClientesPresupuesto = 'Búsqueda de Clientes en Presupuestos';

  // Traducciones de inventarios y documentos (D34).
  SCaptionLineaPresupuesto =
    'Línea';
  SCaptionDescripcionPresupuesto =
    'Descripción';
  SCaptionCantidadPresupuesto =
    'Cantidad';
  SCaptionPrecioSinIvaPresupuesto =
    'PVP S/IVA';
  SCaptionPrecioConIvaPresupuesto =
    'PVP C/IVA';
  SCaptionTarifaPresupuesto =
    'Tarifa';
  SCaptionImpuestosIncluidosPresupuesto =
    'Imp. incl.';
  SCaptionTotalPresupuesto =
    'Total';
  SCaptionAlmacenPresupuesto =
    'Almacén';
  SCaptionLotePresupuesto =
    'Lote';
  SCaptionCaducidadPresupuesto =
    'F. Caducidad';
  SCaptionPasarPresupuestoFactura =
    'Pasar a factura';
  SCaptionPasarPresupuestoAlbaran =
    'Pasar a albarán';
  SCaptionPasarPresupuestoPedido =
    'Pasar a pedido';
  SErrorSeleccionePresupuesto =
    'Seleccione un presupuesto.';
  SErrorPresupuestoNoExiste =
    'El presupuesto ya no existe.';
  SErrorSerieDestinoPresupuesto =
    'Configure una serie %s para la empresa %s en Empresas > Series.';
  SErrorDestinoPresupuestoNoCreado =
    'No se ha creado el documento de destino.';
  SErrorOperacionPendientePresupuesto =
    'Termine la operación pendiente antes de convertir.';
  SErrorConsultaPresupuestoNoDisponible =
    'Falta la consulta %s.';
  SErrorPresupuestoConvertidoSoloLectura =
    'El presupuesto convertido se conserva como documento de origen.';
  SErrorDocumentoImpresionNoExiste =
    'El documento que desea imprimir no existe.';

  SInformeFechaDocumento =
    'Fecha: [Cabecera."FECHA"]';
  SInformeArticuloDocumento =
    'Artículo / Descripción / Variante';
  SInformeCantidadDocumento =
    'Cantidad';
  SInformePrecioDocumento =
    'Precio';
  SInformeIvaDocumento =
    'IVA %';
  SInformeImporteDocumento =
    'Importe';
  SInformeBaseDocumento =
    'Base: [FormatFloat(''0.00'', <Cabecera."BASES">)]';
  SInformeImpuestosDocumento =
    'Impuestos: [FormatFloat(''0.00'', <Cabecera."IMPUESTOS">)]';
  SInformeRetencionDocumento =
    'Retención: [FormatFloat(''0.00'', <Cabecera."RETENCION">)]';
  SInformeTotalDocumento =
    'TOTAL: [FormatFloat(''0.00'', <Cabecera."TOTAL">)]';
  SInformeFormaPagoDocumento =
    'Forma de pago: [Cabecera."FORMA_PAGO"]';
  SInformePaginaDocumento =
    'Página [Page#] de [TotalPages#]';
  STituloImprimirDocumento =
    'Imprimir %s';
  SNombrePresupuestoVenta =
    'Presupuesto de venta';
  SNombrePedidoVenta =
    'Pedido de venta';
  SNombrePedidoCompra =
    'Pedido de compra';
  SNombreAlbaranVenta =
    'Albarán de venta';
  SNombreAlbaranCompra =
    'Albarán de compra';

implementation

end.
