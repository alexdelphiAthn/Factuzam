{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgFacturas                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de facturación, borradores, rectificación y tickets.             }
{******************************************************************************}
unit inLibMsgFacturas;

interface

resourcestring
  SErrorLecturasFacturasNoRegistradas =
    'No se ha registrado el repositorio de lecturas de facturas.';
  SErrorRepositorioFacturaeNoRegistrado =
    'No se ha registrado el repositorio de Facturae.';
  SCliToTbl = 'Cliente: %s pasado correctamente a la tabla de ' +
                     'clientes';
  SEmpToTbl = 'Empresa: %s pasada correctamente a la tabla de '+
                     'empresas';
  SErrorEnviarTicketImpresora =
    'No se pudo enviar el ticket a la impresora "%s".' + sLineBreak +
    '%s' + sLineBreak + 'Se abrirá la vista previa.';
  SInfoTicketEnviadoImpresora =
    'Ticket enviado correctamente a: %s';
  SAvisoAlbaranFacturado =
    'No se puede borrar el albaran: ya esta facturado. ' +
    'Borra o deshaz primero la factura vinculada.';
  SPreguntaBorrarClienteConFacturas =
    'El cliente tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SPreguntaBorrarEmpresaConFacturas =
    'La empresa tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SErrorOperacionSinIvaConCuota =
    'La operacion no repercute IVA (intracomunitaria, ISP o exportacion), ' +
    'pero la factura tiene IVA (%s). Revise el IVA o el tipo de operacion.';
  SErrorCalcularBorradorDetalle =
    'Error al calcular borrador: %s';
  SErrorCalculoBorrador =
    'Error en cálculo de borrador: %s';
  SErrorTipoIvaFactura = 'Tipo de Iva incorrecto';
  SErrorBorrarBorradorFase =
    'El borrador está en fase %s: ya se ha lanzado a Verifactu y no puede ' +
    'borrarse. Use Anular registro fiscal o emita una rectificativa.';
  SPreguntaBorrarFactura =
    '¿Borrar la factura %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas, recibos/efectos y movimientos de stock.';
  SErrorBorrarBorradorEfectosCobrados =
    'El borrador tiene efectos de cobro cobrados, conciliados o remesados. ' +
    'No puede borrarse.';
  SErrorInsertarLineasCabeceraFactura =
    'No se puede insertar líneas sin grabar primero la cabecera: %s';
  SErrorBorradorSinGrabarParaLineas =
    'Debe grabar primero el borrador antes de añadir líneas';
  SErrorSerieFacturaOtraEmpresa =
    'Esta serie es usada por otra empresa. Debe cambiar la serie ';
  SErrorRazonSocialEmpresaBorrador =
    'Debe escribir la razón social de la empresa del borrador';
  SErrorSerieBorradorObligatoria =
    'Debe seleccionar una serie del borrador';
  SErrorFechaBorradorObligatoria =
    'Debe indicar la fecha del borrador.';
  SErrorNifClienteFactura =
    'El NIF/CIF/NIE del cliente no es valido: %s';
  SErrorNifEmpresaFactura =
    'El NIF/CIF/NIE de la empresa no es valido: %s';
  SErrorFechaFacturaAnteriorSerie =
    'La fecha %s es anterior al ultimo borrador de la serie (%s). La ' +
    'numeracion debe seguir orden cronologico.';
  SAvisoFechaBorradorFutura =
    'Aviso: la fecha del borrador es posterior a hoy.';
  SErrorAsignarNumeroFactura =
    'No se ha podido asignar numero a la factura (serie %s). Revise el ' +
    'contador de la serie.';
  SAvisoHuecoNumeracionFactura =
    'Aviso: hay un salto en la numeracion de la serie %s. La ley exige ' +
    'numeracion correlativa: el numero o numeros que falten deben cubrirse.';
  SErrorCodigoFacturaeFormaPago =
    '%s no es un codigo Facturae valido para el campo Codigo Facturae de ' +
    'Formas de Pago. Use 01..19.';
  SErrorFacturaeFaltaCampo = '- Falta %s.';
  STextoNifParteFacturae = 'NIF de %s';
  STextoRazonSocialParteFacturae = 'razon social de %s';
  STextoDireccionParteFacturae = 'direccion de %s';
  STextoCodigoPostalParteFacturae = 'codigo postal de %s';
  STextoPoblacionParteFacturae = 'poblacion de %s';
  STextoProvinciaParteFacturae = 'provincia de %s';
  SErrorDocumentoFiscalParteFacturae = '- %s (%s).';
  SErrorFaltaCodigoDir3Facturae =
    '- Falta el codigo DIR3 de %s.';
  SErrorCodigoDir3LargoFacturae =
    '- El codigo DIR3 de %s supera 10 caracteres.';
  STextoEmpresaEmisoraFacturae = 'empresa emisora';
  STextoClienteFacturae = 'cliente';
  STextoOficinaContableFacturae = 'la oficina contable';
  STextoOrganoGestorFacturae = 'el organo gestor';
  STextoUnidadTramitadoraFacturae = 'la unidad tramitadora';
  SErrorNombrePersonaFisicaFacturae =
    '- El cliente tiene NIF/NIE de persona física. Rellene el nombre en ' +
    'Parámetros eDoc.';
  SErrorApellidosPersonaFisicaFacturae =
    '- El cliente tiene NIF/NIE de persona física. Rellene los apellidos en ' +
    'Parámetros eDoc.';
  SErrorCodigoPagoFacturaeInvalido =
    '- El codigo Facturae de la forma de pago debe estar entre 01 y 19.';
  SErrorFacturaeNoExiste =
    '- No existe la factura seleccionada.';
  SErrorFacturaeTipoVentaInvalido =
    '- El eDoc solo se emite desde venta mayor NORMAL.';
  SErrorFacturaeNoConsolidada =
    '- La factura debe estar consolidada antes de emitir eDoc.';
  SErrorFacturaeFechaOficialFaltante =
    '- Falta la fecha oficial de la factura.';
  SErrorLineaFacturaeSinDescripcion =
    '- La linea %s no tiene descripcion.';
  SErrorLineaFacturaeCantidadCero =
    '- La linea %s tiene cantidad cero.';
  SErrorFacturaeSinLineas = '- La factura no tiene lineas.';
  SErrorBasesFacturaeNoCuadran =
    '- La suma de bases de lineas no cuadra con cabecera.';
  SErrorTotalesFacturaeNoCuadran =
    '- Los totales de cabecera no cuadran.';
  SErrorEmitirFacturae =
    'No se puede emitir eDoc Facturae:' + sLineBreak + '%s';
  SErrorCertificadoFacturaeNoConfigurado =
    'La empresa de la factura no tiene certificado configurado para firmar ' +
    'eDoc Facturae.';
  SErrorConexionFacturaeNoDisponible =
    'No hay conexion de base de datos para emitir eDoc.';
  SErrorFicheroSalidaFacturaeNoIndicado =
    'No se ha indicado el fichero de salida eDoc.';
  SErrorPorcentajeIvaFueraRango =
    'El porcentaje de IVA debe estar entre 0 y 100';
  SErrorPrecioFacturaNegativo =
    'Los precios no pueden ser negativos';
  SErrorAbrirImpresoraTicket =
    'No se pudo abrir la impresora: %s';
  SErrorIniciarDocumentoImpresora =
    'Error al iniciar documento';
  SErrorEscribirImpresora =
    'Error al escribir en impresora';
  SErrorLimiteDemoFacturas =
    'Límite DEMO.' + sLineBreak + sLineBreak +
    'Ya se han emitido %d facturas el día %s.' + sLineBreak +
    'El límite de la copia DEMO es %d facturas al día.';
  SErrorPreviewTicketNoRegistrado =
    'No se ha registrado el previsualizador de tickets.';
  SErrorRecalcularTotalesFactura =
    'Error al recalcular totales de la factura: %s';
  SErrorFacturaWebserviceNoExiste =
    'No existe la factura %s\%s para enviarla al webservice.';
  SErrorFirmaFacturaRaizIncorrecta =
    '%s: la firma debe envolver RegistroAlta o RegistroAnulacion.';
  STextoRegistroFacturaIndice = 'registro %d';
  SFormatoEtiquetaFactura = 'Factura %s';
  SAvisoFacturaSinPeticionCompletaXml =
    'Factura %s: no incluye PeticionCompletaXml.';
  SErrorFacturaHashPeticionNoCoincide =
    'Factura %s: HashPeticionBase64 no coincide.';
  SErrorFacturaSinRegistroXmlFirmado =
    'Factura %s: falta RegistroXmlFirmado.';
  SErrorFacturaHashRegistroNoCoincide =
    'Factura %s: HashRegistroXmlBase64 no coincide.';
  SErrorFacturaGuardadaSinFirmaXml =
    'Factura %s: hay firma guardada pero el XML no firma.';
  SErrorFacturaSignatureValueNoCoincide =
    'Factura %s: SignatureValue no coincide.';
  STextoFacturacion = 'Facturacion';
  SErrorFicheroFacturacionNoExiste =
    'No existe el fichero de facturacion: %s';
  SErrorFicheroFacturacionRaizIncorrecta =
    'El fichero de facturacion no tiene la raiz esperada.';
  SErrorFicheroFacturacionVacio =
    'El fichero de facturacion no contiene registros.';
  SErrorVerificarFacturacion =
    'No se pudo verificar facturacion: %s';
  SErrorFacturaRequisitosFiscalesNoExiste =
    'No existe la factura %s\%s para validar sus requisitos fiscales.';
  SErrorColumnasFirmaFacturacionNoDisponibles =
    'Faltan columnas de firma en fza_facturas_consolidaciones. Aplique ' +
    'el script DESARROLLOS EN CURSO\verifactu_registros_firmados.sql.';
  SErrorFacturaExtranjeraSinNifIva =
    'La factura %s %s\%s a cliente extranjero requiere el NIF-IVA del ' +
    'destinatario.';
  SErrorFacturaSinNifClienteValido =
    'La factura %s %s\%s requiere un NIF de cliente válido y tiene "%s"';
  SInfoBorradorFacturaCreado =
    'Borrador creado: %s / %s';
  SErrorCrearBorradorFactura =
    'No se pudo crear el borrador.';
  SPreguntaBorrarMovimientosTicketAnulado =
    '¿Desea borrar también los movimientos de almacén asociados al ticket ' +
    '%s\%s?' + sLineBreak +
    'Se revertirá el stock de sus líneas.';
  SPreguntaMovimientosRectificativaSustitutiva =
    '¿Qué desea hacer con los movimientos de almacén de la factura ' +
    'original %s\%s?' + sLineBreak + sLineBreak +
    'Eliminar originales: se revierte su stock y se generan los ' +
    'movimientos de la nueva rectificativa.' + sLineBreak +
    'Mantener originales: se conserva el stock actual y la nueva ' +
    'rectificativa no genera movimientos adicionales.';
  SErrorFacturarTicketRequiereSimplificado =
    'Solo se crea un borrador normal desde un borrador SIMPLIFICADO ' +
    '(ticket).';
  SInfoBorradorSustitucionTicketCreado =
    'Creado el borrador %s\%s en sustitución del ticket %s\%s en modo ' +
    'fiscal %s (F3).';
  SErrorRectificarRectificativa =
    'No se puede rectificar una rectificativa.';
  SErrorOperacionSinTicket =
    'Esta operación no tiene ticket asociado.';
  SAvisoLimiteRegistrosFacturaSimplificada =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorBorradorVentaMayorNoSeleccionado =
    'Seleccione un borrador de venta mayor.';
  SErrorGuardarAntesEmitirEdoc =
    'Guarde los cambios antes de emitir el eDoc.';
  SErrorPersonaFisicaEdocSinDatos =
    'El cliente tiene NIF/NIE de persona física.' + sLineBreak +
    'Rellene nombre y apellidos en Parámetros eDoc antes de emitir.';
  SInfoEdocEmitido =
    'eDoc emitido correctamente:' + sLineBreak + '%s';
  SPreguntaReemplazarCobros =
    'Hay %s creados, ¿desea reemplazarlos?';
  STituloMensajeAdvertencia = 'Mensaje Advertencia';
  SInfoGeneracionCobrosCancelada =
    'Generación de %s cancelada.';
  SInfoEfectosCobroGenerados =
    'Generados %d efecto(s) de cobro.';
  SAvisoEfectosCobroNoGenerados =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga efectos cobrados o remesados.';
  SErrorGenerarEfectosCobroSinBorrador =
    'No hay borrador activo o no se pudieron generar efectos.';
  SAvisoBorradorPendienteImpresionFiscal =
    'El borrador está pendiente: use el botón Consolidar antes de ' +
    'imprimirlo en este modo fiscal.';
  SErrorGuardarFacturaAntesImprimir =
    'No se pudo guardar la factura antes de imprimir: %s';
  SErrorFacturasFiltradasVacias =
    'No hay facturas en el resultado filtrado.';
  SErrorCambiosPendientesProcesarFiltradas =
    'Guarde o cancele los cambios de la factura antes de procesar ' +
    'el resultado filtrado.';
  SErrorServicioLoteImpresionFacturas =
    'No está disponible el servicio de impresión por lotes.';
  SErrorLoteImpresionFacturas =
    'La impresión por lotes se detuvo tras enviar %d de %d facturas.' +
    sLineBreak + '%s';
  SInfoLoteImpresionFacturas =
    'Impresión por lotes finalizada.' + sLineBreak +
    'Facturas enviadas: %d.' + sLineBreak +
    'Omitidas por no estar consolidadas: %d.';
  SErrorGuardarTrabajoLote =
    'No se pudo generar trabajo_lote.txt: %s';
  SInfoTrabajoLoteGuardado =
    'Resultado guardado en:' + sLineBreak + '%s';
  SInfoEfectoMarcadoDevuelto =
    'Efecto marcado como devuelto.';
  SErrorMarcarEfectoDevuelto =
    'No se pudo marcar el efecto como devuelto.';
  SInfoEfectoMarcadoPendiente =
    'Efecto marcado como pendiente.';
  SErrorMarcarEfectoPendiente =
    'No se pudo marcar el efecto como pendiente.';
  SErrorEfectoSinImportePendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  SErrorBorradorListaNoSeleccionado =
    'Seleccione un borrador en la lista.';
  SErrorBorradorNoCerradoAccionFiscal =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede %s.';
  SPreguntaAccionFiscalBorrador =
    '¿%s fiscalmente el borrador %s\%s?';
  SErrorBorradorYaLanzadoFiscalmente =
    'El borrador %s\%s ya se lanzó fiscalmente (fase %s).';
  SErrorBorradorSinLineasLanzar =
    'El borrador no tiene líneas: no se puede lanzar.';
  SErrorBorradorNormalSinNif =
    'Un borrador NORMAL necesita el NIF del cliente para el registro ' +
    'fiscal. Complete los datos del cliente.';
  SPreguntaLanzarBorradorFiscal =
    '¿Lanzar fiscalmente el borrador %s\%s? Dejará de estar en borrador y ' +
    'de ser editable.';
  SErrorBorradorConsolidadoNoReabrible =
    'El borrador %s\%s ya está consolidado en la AEAT: no puede volver a ' +
    'borrador. Use Anular fiscal o emita una rectificativa.';
  SInfoBorradorYaEnBorrador =
    'El borrador ya está en BORRADOR.';
  SPreguntaDevolverBorrador =
    '¿Devolver a BORRADOR el documento %s\%s y anular su envío pendiente ' +
    'a la AEAT?';
  SErrorAltaAeatAceptadaNoReabrible =
    'El alta ya fue aceptada por la AEAT: no se puede volver a borrador. ' +
    'Use Anular fiscal o emita una rectificativa.';
  SErrorBorradorEnProcesoNoReabrible =
    'El hilo Verifactu está enviando este borrador ahora mismo. Espere unos ' +
    'segundos y vuelva a intentarlo.';
  SInfoBorradorReabierto =
    'Borrador %s\%s de nuevo en BORRADOR. Corrija los datos (si el error ' +
    'es de la empresa, arréglelo en Empresas y use "Dar de Alta o ' +
    'Actualizar Empresa" en la pestaña Datos Empresa Emisora para ' +
    'refrescar la copia del borrador) y pulse Consolidar para relanzarla.';
  SPreguntaGrabarFacturaVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorCompletarDatosBorrador =
    'Debe completar los datos del borrador: %s';
  SErrorEmpresaProveedorFacturacionNoIndicados =
    'Indica empresa y proveedor.';
  SPreguntaFacturarTodosAlbaranesListados =
    'No has marcado albaranes (Ctrl/Mayus+clic para elegir).' + sLineBreak +
    'Crear borrador con TODOS los listados?';
  SInfoBorradoresGenerados =
    'Proceso finalizado. Borradores generados: %d.';
  SErrorClienteFacturarTicketNoExiste =
    'El cliente seleccionado no existe.';
  SErrorRazonSocialFacturarTicketObligatoria =
    'La F3 necesita la razon social del cliente.';
  SErrorDocumentoFiscalFacturarTicketNoValido =
    'El NIF/CIF/NIE del cliente no es valido: ';
  SErrorCrearBorradorFacturarTicket =
    'No se pudo crear el borrador: ticket o cliente no encontrados.';
  SErrorFechaTicketSerieNoValida =
    'No se puede grabar el ticket en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha de ' +
    'caja %s.' + sLineBreak +
    'Cambie la serie para emitir un ticket con esta fecha.';
  // R03 - Diálogos de rectificativa en consulta de operaciones
  STituloTipoRectificativa = 'Tipo de rectificativa';
  SCaptionPorDiferencias = 'Por diferencias';
  SCaptionSustitutiva = 'Sustitutiva';
  STituloMovimientosAlmacen = 'Movimientos de almacén';
  SCaptionEliminarOriginales = 'Eliminar originales';
  SCaptionMantenerOriginales = 'Mantener originales';
  // R05 - Terminología efectos/recibos y pestañas de borrador
  SCaptionTabEfectos = '&3_Efectos';
  SCaptionGenerarEfectos = 'Generar efectos';
  SCaptionImprimirEfecto = 'Imprimir efecto';
  SCaptionEfectoPendiente = '&Pendiente';
  SCaptionEfectoCobrado = '&Cobrado';
  SCaptionEfectoDevuelto = '&Devuelto';
  SCaptionColNroBorradorEfecto = 'Nro Borrador Efecto';
  SCaptionColSerieBorradorEfecto = 'Serie Borrador Efecto';
  SCaptionColEfecto = 'Efecto';
  SCaptionColTotalEfecto = 'Total efecto';
  SCaptionColEstadoEfecto = 'Estado efecto';
  SCaptionColFechaEmisionEfecto = 'Fecha emisión efecto';
  SCaptionColFechaCobroEfecto = 'Fecha cobro';
  SCaptionColReferenciaEfecto = 'Referencia';
  SCaptionTabRecibos = '&3_Recibos';
  SCaptionGenerarRecibos = 'Generar &Recibo/s';
  SCaptionImprimirRecibo = 'Imprimir &Recibo';
  SCaptionReciboEmitido = '&Emitido';
  SCaptionReciboPagado = '&Pagado';
  SCaptionReciboDevuelto = '&Devuelto';
  SCaptionColNroBorradorRecibo = 'Nro Borrador Recibo';
  SCaptionColSerieBorradorRecibo = 'Serie Borrador Recibo';
  SCaptionColNroPlazo = 'Nro Plazo';
  SCaptionColTotalRecibo = 'Total Recibo';
  SCaptionColEstadoRecibo = 'Estado Recibo';
  SCaptionColFechaExpedicionRecibo = 'Fecha Expedición Recibo';
  SCaptionColFechaPagoRecibo = 'Fecha Pago Recibo';
  SCaptionColLocalidadExpedicionRecibo = 'Localidad Expedición';
  SCaptionEfectosCobroPlural = 'efectos de cobro';
  SCaptionRecibosPlural = 'recibos';
  SCaptionTabLineasBorradorClasico = '&1_Lineas de Borrador [Clásico]';
  SCaptionTabLineasBorradorSku = '&1_Lineas de Borrador [SKU]';
  SCaptionTabLineasBorradorDesglose =
    '&1_Lineas de Borrador [Desglose]';
  SCaptionTabLineasBorradorTallasHoriz =
    '&1_Lineas de Borrador [Tallas horiz.]';
  STituloEmitirEDoc = 'Emitir eDoc';
  SCaptionFiltroFacturae =
    'Facturae firmado (*.xsig)|*.xsig|XML (*.xml)|*.xml';
  SCaptionCargandoBorradores = 'Cargando borradores...';
  SCaptionCargandoBorradoresProgreso = 'Cargando borradores: %s / %s';
  // R09 - Facturación de albaranes por fechas
  SCaptionCreandoBorradoresAlbaranes =
    'Creando borradores de %d albaranes...';
  SCaptionGeneradosBorradores = 'Generados %d borradores';
  // R10 - Informe de efectos de pago
  SCaptionGrupoFecha = ' Fecha ';
  SCaptionFechaDocumento = 'Documento';
  SCaptionFechaValor = 'Valor';
  SCaptionFechaVencimiento = 'Vencimiento';
  SCaptionGrupoSituacion = ' Situación ';
  SCaptionSituacionPagados = 'Pagados';
  SCaptionSituacionImpagados = 'Impagados';
  SCaptionSituacionPendientes = 'Pendientes';
  SCaptionSituacionTodos = 'Todos';
  SCaptionNumEfectoDesde = 'Nº efecto desde:';
  SCaptionNumEfectoHasta = 'Nº efecto hasta:';
  SCaptionMostrarSoloTotales = 'Mostrar sólo totales';
  // R11 - Selección de banco de empresa
  SCaptionCuentaEmpresaPagoEfectos =
    'Cuenta de la empresa para el PAGO (cargo) de los efectos:';
  SCaptionCuentaEmpresaCobroRecibos =
    'Cuenta de la empresa para el COBRO (ingreso) de los recibos:';
  // R15 - Exportación de factura a Excel
  SCaptionHojaFactura = 'Factura %s';
  // Fase 2 - Persistencia de operaciones de facturas tras contrato
  SErrorPersistenciaFacturasNoRegistrada =
    'La persistencia de operaciones de facturas no está registrada.';
implementation

end.
