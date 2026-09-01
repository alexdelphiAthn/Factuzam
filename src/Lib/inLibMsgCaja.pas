{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgCaja                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes del subsistema de caja, arqueos y traspasos.                     }
{******************************************************************************}
unit inLibMsgCaja;

interface

resourcestring
  SErrorParametrosCajaSinContratoEdicion =
    'Los parámetros de caja no ofrecen el contrato de edición.';
  SErrorOperacionCajaNoEncontrada =
    'No se ha encontrado la operación en la caja especificada.';
  STituloOperacionesCajaStock = 'Operaciones de caja';
  SErrorConexionOperacionesCajaSkuNoDisponible =
    'No hay una conexión disponible para la consulta.';
  SErrorCodigoFormaPagoCajaObligatorio =
    'El Código de la Forma de Pago es obligatorio';
  SErrorDescripcionFormaPagoCajaObligatoria =
    'La Descripción de la Forma de Pago es obligatoria';
  SErrorParametrosAplicacionCajaNoConfigurados =
    'No se han configurado los parámetros de aplicación.';
  SErrorParametrosModuloCajaNoConfigurados =
    'No se han configurado los parámetros del módulo de caja.';
  SErrorContextoSesionCajaNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de caja.';
  SErrorOperacionCajaSinLineas =
    'No se puede grabar una operación sin líneas.';
  SErrorCambioIvaSoloArticuloInmaterial =
    'Seleccione una línea de artículo inmaterial para cambiar su IVA.';
  SErrorRazonSocialClienteFacturaCajaObligatoria =
    'La factura normal necesita la razon social del cliente.';
  SErrorDocumentoFiscalClienteCajaNoValido =
    'El NIF/CIF/NIE del cliente no es valido: ';
  SErrorDocumentoFiscalEmpresaCajaNoValido =
    'El NIF/CIF/NIE de la empresa no es valido: ';
  SErrorCuadreCobroParcialCaja =
    'No se pudo cuadrar tras cobro parcial.';
  SErrorFacturaRectificativaCajaSinOriginal =
    'La rectificativa no tiene factura original asociada.';
  SErrorGuardarTicketCaja =
    'Error al guardar el ticket. No se ha registrado la operación.' +
    sLineBreak + 'Motivo: %s';
  SErrorCuadrarFacturaCaja =
    'Error al cuadrar la factura: %s';
  SErrorRedimirValeCaja =
    'No se pudo redimir el vale "%s". Filas afectadas: %d. Posibles causas: ' +
    'el vale no existe, ya fue redimido, esta caducado o anulado.';
  SErrorContextoSesionTraspasoNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de traspasos.';
  SErrorSkuTraspasoIncompleto =
    'El artículo "%s" no tiene el SKU completo (elige color/talla). SKU: "%s"';
  SErrorSkuTraspasoNoDisponible =
    'El SKU "%s" del artículo "%s" no existe o está inactivo. Revisa el ' +
    'catálogo o, si procede de una solicitud, deniega la línea.';
  SErrorArticuloSkuTraspasoNoCoincide =
    'La línea del artículo "%s" no corresponde al SKU "%s" (artículo real ' +
    '"%s"). Borra la línea y vuelve a introducirlo.';
  SErrorStockTraspasoInsuficiente =
    'No hay stock suficiente en el almacén origen (%s):' + sLineBreak + '%s';
  SErrorLineasTraspasoNoDisponibles =
    'No hay líneas que traspasar.';
  SErrorAlmacenDestinoTraspasoNoSeleccionado =
    'Selecciona el almacén destino.';
  SErrorAlmacenesTraspasoCoincidentes =
    'Origen y destino no pueden ser el mismo almacén.';
  SErrorAlmacenOrigenReposicionNoSeleccionado =
    'Selecciona el almacén origen de la reposición.';
  SErrorRangoVentasReposicionNoValido =
    'El intervalo de ventas debe tener fecha y hora válidas y el inicio ' +
    'debe ser anterior al final.';
  SErrorVentasReposicionNoCargadas =
    'Carga primero las ventas de la reposición.';
  SErrorLineasSolicitudTraspasoNoDisponibles =
    'No hay líneas que solicitar.';
  SErrorAlmacenOrigenSolicitudNoSeleccionado =
    'Selecciona el almacén al que solicitas.';
  SErrorSolicitudTraspasoMismoAlmacen =
    'No puedes solicitarte a ti mismo.';
  SErrorSolicitudTraspasoNoCargada =
    'No hay solicitud cargada que denegar.';
  SErrorLineaSolicitudTraspasoNoActualizada =
    'No se ha podido actualizar la línea "%s" de la solicitud %s/%s.';
  SErrorImpresoraTicketsCajaNoConfigurada =
    'No hay impresora de tickets configurada en parámetros ' +
    '(vgerDefPrinter); no se puede abrir el cajón.';
  SErrorContextoImpresoraCajaNoProporcionado =
    'No se ha proporcionado el contexto para la impresora de caja.';
  SErrorReferenciaPagoCajaNoIndicada =
    'Debe introducir la referencia del pago.';
  SErrorFactorCambioCajaNoValido =
    'El factor de cambio debe ser mayor que cero.';
  SErrorHashBlockchainCajaNoIndicado =
    'Debe introducir el hash de la transacción blockchain.';
  SErrorValeCajaNoSeleccionado =
    'No hay ningún vale seleccionado.';
  SErrorPinValeCajaNoIndicado =
    'Introduzca el PIN de seguridad del vale para poder canjearlo.';
  SErrorPinValeCajaIncorrecto =
    'El PIN de seguridad no es correcto.' + sLineBreak +
    'Verifique el código que aparece en el vale físico.';
  SErrorProveedorParametrosCajaNoConfigurado =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosCajaEditablesNoConfigurados =
    'No se han configurado los parámetros de caja editables.';
  SInfoLayoutCajaGuardado =
    'Layout guardado.';
  SInfoParametrosCajaGuardados =
    'Se han guardado %d parámetros correctamente para: %s';
  SInfoParametrosCajaSinCambios =
    'No se han detectado cambios para guardar.';
  SPreguntaSalirParametrosCajaSinGuardar =
    '¿Está seguro de que desea salir sin guardar?';
  SInfoUsuariosParametrosCajaNoEncontrados =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuarioParametrosCaja =
    'Cambiar usuario';
  SSolicitudCambiarUsuarioParametrosCaja =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Introduce el nombre de usuario:';
  SErrorUsuarioParametrosCajaNoEncontrado =
    'Usuario no encontrado: %s';
  SInfoPrecargaCajaGuardada =
    'Precarga guardada.';
  SErrorAsignarUbicacionCaja =
    'Error al asignar Empresa Almacén Caja';
  STituloHoraCaja =
    'Hora de caja';
  SSolicitudHoraCaja =
    'Hora (HH:MM)';
  SErrorHoraCajaNoValida =
    'Hora no válida. Use HH:MM.';
  SErrorUbicacionCajaBuscarOperacionesNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'buscar operaciones.';
  SErrorUbicacionCajaArqueoNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer arqueo.';
  SErrorUbicacionCajaTraspasoNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer traspasos.';
  SErrorRectificacionCajaNoAdmiteBorrador =
    'Una rectificación se cierra como ticket rectificativo, no como ' +
    'borrador normal.';
  SErrorClienteBorradorCajaNoAsignado =
    'Asigne un cliente a la operación para emitir borrador.';
  SErrorNifClienteBorradorCajaNoIndicado =
    'El cliente no tiene NIF: complételo en su ficha para poder emitir ' +
    'borrador normal.';
  SErrorFechaSerieEmisionCajaNoValida =
    'No se puede emitir en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha ' +
    '%s.' + sLineBreak + 'Elija otra serie para emitir con esta fecha.';
  SAvisoHuecosNumeracionSerieCaja =
    'La serie "%s" tiene huecos en la numeración: faltan %d números entre ' +
    'el %d y el %d.' + sLineBreak +
    'Recuerde que la numeración debe ser correlativa según la ley.';
  SErrorNumeroBorradorCajaNoValido =
    'El número de borrador indicado no es válido.';
  SErrorNumeroBorradorCajaExistente =
    'El número %d ya existe en la serie "%s".';
  SErrorNumeroBorradorCajaNoEsHueco =
    'El número %d no es un hueco de la serie "%s": los huecos están entre ' +
    'el %d y el %d.';
  STituloEnviarDocumentacionCaja =
    'Enviar documentación';
  SSolicitudCorreoDocumentacionCaja =
    'Correo electrónico:';
  SErrorCorreoDocumentacionCajaNoIndicado =
    'Indique una dirección de correo electrónico.';
  SErrorCreditoClienteCajaNoPermitido =
    'Operación denegada: Este cliente no tiene crédito permitido.';
  SErrorImporteCreditoCajaNoPendiente =
    'No hay importe pendiente para pasar a crédito.';
  SAvisoLimiteOperacionesCaja =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorOperacionCajaExportarNoSeleccionada =
    'No hay ninguna operación seleccionada para exportar.';
  SErrorSkuVentaCajaNoExiste =
    'El SKU "%s" no existe en fza_articulos_skus. No se puede vender.';
  SErrorSkuVentaCajaNoActivo =
    'El SKU "%s" no está activo. No se puede vender.';
  SErrorArticuloVentaCajaSinStock =
    'Artículo sin stock. Compruebe stock en almacén.';
  SErrorVendedorCajaNoAsignado =
    'Da de alta el vendedor antes de leer artículos.';
  SErrorCodigoBarrasVentaCajaNoEncontrado =
    'Código de barras no encontrado: %s';
  SErrorLineaDepositoCajaNoCancelable =
    'No se puede cancelar o eliminar una línea vinculada a un depósito.';
  SErrorArticuloVentaCajaNoEncontrado =
    'Artículo no encontrado';
  SPreguntaCancelarVentaCaja =
    'Hay líneas en la venta actual.' + sLineBreak +
    '¿Desea CANCELAR LA VENTA y salir?';
  SErrorLineaDepositoCajaNoEliminable =
    'No se puede eliminar una línea vinculada a un depósito.' + sLineBreak +
    'Cambie la cantidad a negativo si necesita revertirla.';
  SPreguntaBorrarVentaCaja =
    'Hay una venta en curso.' + sLineBreak +
    '¿Desea BORRAR LA VENTA y salir?';
  SInfoValeCajaEntregar =
    'Entregue el vale al cliente: %s';
  SErrorCorreoOperacionCajaNoEnviado =
    'La operación se ha guardado correctamente, pero no se ha podido enviar ' +
    'el correo.' + sLineBreak + '%s';
  SErrorTipoRectificativaCajaNoIndicado =
    'Debe indicar el tipo de rectificativa.';
  SErrorBorradorRectificarCajaNoEncontrado =
    'No se encontró el borrador %s\%s a rectificar.';
  SErrorClienteDepositosCajaNoSeleccionado =
    'Debe seleccionar un cliente para cargar sus depósitos.';
  SErrorValoresAtributoCajaNoDefinidos =
    'No hay valores definidos para este atributo.';
  SPreguntaEliminarOperacionCajaPendiente =
    'La Operación %d tiene artículos pendientes.' + sLineBreak +
    '¿Desea ELIMINARLA y cerrar?';
  SErrorArticuloCajaNoEncontradoDescatalogado =
    'ARTÍCULO NO ENCONTRADO O DESCATALOGADO';
  SErrorCantidadArticuloDepositoCajaNoValida =
    'En artículos de depósito solo está permitido cambiar el signo de la ' +
    'cantidad.';
  SErrorCodigoClienteCajaNoExiste =
    'El código de cliente no existe.';
  SErrorEmpleadoCajaNoEncontrado =
    'No se encontró ningún empleado válido.';
  SErrorSolicitudesTraspasoPendientesNoEncontradas =
    'No hay solicitudes pendientes de atender.';
  SErrorCargarSolicitudTraspaso =
    'No se pudo cargar la solicitud.';
  SErrorSolicitudTraspasoCerrarNoCargada =
    'Trae primero una solicitud (F7) para cerrarla.';
  SPreguntaCerrarSolicitudTraspaso =
    '¿Cerrar la solicitud dejando las líneas sin servir como no atendidas?';
  SInfoSolicitudTraspasoCerrada =
    'Solicitud cerrada.';
  SErrorDenegarSolicitudTraspasoModoNoValido =
    'Denegar solo aplica al atender una solicitud.';
  SErrorSolicitudTraspasoDenegarNoCargada =
    'Trae primero una solicitud (F7) para denegarla.';
  STituloDenegarSolicitudTraspaso =
    'Denegar petición';
  SSolicitudMotivoRechazoTraspaso =
    'Motivo del rechazo (lo verá quien la pidió):';
  SErrorMotivoDenegacionTraspasoNoIndicado =
    'Debes indicar un motivo para denegar.';
  SInfoPeticionTraspasoDenegada =
    'Petición denegada (DENEGADO TOTAL).';
  SInfoSolicitudTraspasoEnviada =
    'Solicitud %s/%s enviada.';
  SErrorEmpleadoTraspasoNoIndicado =
    'Indica el empleado responsable del traspaso.';
  SErrorEmpleadoTraspasoNoEncontrado =
    'Empleado no encontrado: %s';
  SErrorSolicitudTraspasoAtenderNoCargada =
    'Carga primero una solicitud (botón Cargar solicitud).';
  SErrorMotivoLineasTraspasoNoIndicado =
    'Indica el motivo en las líneas que deniegas (las que sirves a 0).';
  SInfoSolicitudTraspasoAtendida =
    'Solicitud atendida. Traspaso %s grabado.';
  SPreguntaDenegarPeticionTraspasoCompleta =
    'No has marcado nada para servir. ¿Denegar toda la petición?';
  SInfoTraspasoGrabado =
    'Traspaso %s grabado correctamente.';
  SInfoVentasReposicionNoEncontradas =
    'No hay ventas en el intervalo indicado.';
  SInfoReposicionAutoEmitida =
    'Reposición automática %s/%s emitida.';
  SErrorEmpleadoGastoCajaNoIndicado =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteGastoCajaNoValido =
    'Introduzca un importe mayor que cero.';
  STituloAvisoCaja =
    'Aviso';
  SErrorArqueoCajaNoSeleccionado =
    'Seleccione un arqueo del listado.';
  SErrorPermisoResumenArqueoCaja =
    'No tiene permiso para consultar el resumen del arqueo.';
  SInfoOperacionesFacturadasArqueoCajaNoEncontradas =
    'No hay operaciones facturadas en el rango seleccionado.';
  STituloTiraCaja =
    'Tira de Caja';
  SErrorVendedorArqueoCajaNoIndicado =
    'Debe indicar el número de empleado de caja del vendedor que realiza el ' +
    'cierre.';
  STituloVendedorArqueoCajaObligatorio =
    'Vendedor obligatorio';
  SErrorVendedorArqueoCajaNoValido =
    'El número de empleado indicado no existe o no está activo.';
  STituloVendedorArqueoCajaNoValido =
    'Vendedor no válido';
  SErrorArqueoCajaDuplicado =
    'Ya existe un cierre que solapa este rango y caja. No se permite doble ' +
    'cierre.';
  STituloArqueoCajaDuplicado =
    'Arqueo duplicado';
  SErrorRecuentoArqueoCajaNoDisponible =
    'No hay datos de recuento. Pulse Recalcular primero.';
  SErrorRestanteArqueoCajaNoValido =
    'Debe usted meter el recuento válido para que el restante sea válido';
  SPreguntaGrabarArqueoCaja =
    'Se va a grabar el arqueo con los importes recontados.' + sLineBreak +
    'Periodo: %s - %s' + sLineBreak +
    'Las operaciones del rango quedarán marcadas.' + sLineBreak +
    sLineBreak + '¿Desea continuar?';
  STituloConfirmarArqueoCaja =
    'Confirmar Arqueo';
  SPreguntaImprimirJustificanteCierreCaja =
    '¿Desea imprimir el justificante de cierre?';
  STituloJustificanteCierreCaja =
    'Justificante de cierre';
  // R03 - Título de operación de caja real
  STituloOperacionCajaReal = 'Operación - (Caja Real %s)';
  // R11 - Operaciones de caja por SKU
  SCaptionUnaOperacion = '1 operación';
  SCaptionNumOperaciones = '%d operaciones';
  // R12 - Formularios de caja en ejecución
  SCaptionPendienteDevolver = 'Pendiente de devolver';
  SHintSinDescuentoGlobalDeposito =
    'No se puede aplicar descuento global con líneas de depósito';
  SCaptionPendienteCobro = 'Pendiente de cobro';
  SCaptionEmpresaAlmacenCaja = 'Empresa %s - Almacén %s - Caja %s';
  STituloOperacionNCajaReal = 'Operación %d - (Caja Real %s)';
  STituloTraspasosAlmacenCaja = 'Traspasos - (Almacén %s · Caja %s)';
  SCaptionVentaContado = 'VENTA CONTADO';
  SCaptionTotalCero = 'Total 0,00 €';
  SCaptionTotalImporte = 'Total %m';
  SCaptionRectificativaTipo = 'RECTIFICATIVA' + sLineBreak + '%s';
  STituloBusquedaEmpleadosCaja = 'Búsqueda de Empleados en Caja';
  SCaptionCargandoOperaciones = 'Cargando operaciones...';
  SCaptionCargandoOperacionesProgreso =
    'Cargando operaciones: %s / %s';
  SCaptionIrABorrador = 'Ir a borrador';
  SHintIrABorrador = 'Ir a borrador (%s)';
  SCaptionTabBorrador = 'Borrador';
  SCaptionEquivalenciaEurDivisa = '1 EUR = %.9n %s';
  SCaptionEquivalenciaDivisaEur = '1 %s = %.2n EUR';
  SCaptionColCodigoVale = 'Código Vale';
  SCaptionColEstadoVale = 'Estado';
  SCaptionColImporteVale = 'Importe';
  SCaptionColFechaEmisionVale = 'Fecha emisión';
  SCaptionColCaducidadVale = 'Caducidad';
  SCaptionColObservacionesVale = 'Observaciones';
  // R13 - Traspasos entre almacenes
  SCaptionModoReposiciones = 'F5 Reposiciones';
  SCaptionVentasDesdeReposicion = 'VENTAS DESDE';
  SCaptionVentasHastaReposicion = 'VENTAS HASTA';
  SCaptionCargarVentasReposicion = 'Cargar ventas';
  SCaptionColDescripcionTraspaso = 'Descripción';
  SCaptionColUdsTraspaso = 'Uds';
  SCaptionColAPedirReposicion = 'A pedir';
  SCaptionColCosteTraspaso = 'Coste';
  SCaptionColStockDestinoTraspaso = 'Stock Destino';
  SCaptionColStockOrigenTraspaso = 'Stock Origen';
  SCaptionColPedidasTraspaso = 'Pedidas';
  SCaptionColMotivoRechazoTraspaso = 'Motivo rechazo';
  SCaptionColSirvoTraspaso = 'Sirvo';
  SCaptionAlmacenOrigen = 'ALMACÉN ORIGEN';
  SCaptionAlmacenDestino = 'ALMACÉN DESTINO';
  SCaptionF12ConTicket = 'F12 Con ticket';
  SCaptionF12EnviarSolicitud = 'F12 Enviar solicitud';
  SCaptionF12ServirConTicket = 'F12 Servir con ticket';
  SCaptionF12EmitirReposicion = 'F12 Emitir reposición';
  SCaptionImporteTraspaso = 'Importe traspaso: %m';
  STituloSolicitudesPendientesAtender =
    'Solicitudes pendientes de atender';
  SCaptionColNumeroSolicitud = 'Número';
  SCaptionColSerieSolicitud = 'Serie';
  SCaptionColFechaSolicitud = 'Fecha / hora';
  SCaptionColPideAlmacen = 'Pide (almacén)';
  SCaptionColEstadoSolicitud = 'Estado';
  SCaptionColLineasSolicitud = 'Líneas';
  SCaptionAtender = 'Atender';
  SCaptionNoAtender = 'No atender';
  SCaptionImprimir = 'Imprimir';
  SCaptionEmpleadoNoEncontrado = '(no encontrado)';
  SCaptionSinStock = 'Sin stock';
  // R14 - Modales de caja: arqueo, gastos y tira
  SCaptionImporteEur = '%s EUR';
  SCaptionDesgloseEfectivo =
    'Efectivo sist. = ventas (%s) + entradas (%s) ' +
    #8722' gastos (%s) + anterior (%s)';
  STituloHistoricoArqueosCaja = 'Histórico de Arqueos · Caja %s';
  SCaptionRetirarSobranteRecuento = 'Retirar sobrante del recuento';
  SCaptionTpvRestringido = 'TPV restringido:';
  STituloTiraCajaNumero = 'Tira de Caja · Caja %s';
  SCaptionTodasLasSeries = '(todas las series)';
  SCaptionImprimirQrNoDisponible =
    'Imprimir QR Verifactu (no disponible)';
  // R15 - Devoluciones por ticket (F4), motivo y traspaso automático
  SErrorMotivoDevolucionCajaObligatorio =
    'Indique el motivo de la devolución.';
  SErrorTicketDevolucionCajaNoEncontrado =
    'No se ha encontrado ningún ticket con esos datos.';
  SErrorTicketDevolucionCajaEsRectificativa =
    'El documento localizado es una rectificativa. ' +
    'Localice el ticket de venta original.';
  SErrorTicketDevolucionCajaDatosOperacion =
    'Indique empresa, almacén, caja y número de operación.';
  SErrorTicketDevolucionCajaDatosDocumento =
    'Indique la serie y el número del documento.';
  SErrorTicketDevolucionCajaSinSeleccion =
    'Localice primero un ticket válido.';
  SInfoTicketDevolucionCajaLocalizado =
    'Ticket %s\%s — %s — Tienda %s — Total %s €';
  SInfoVentasOrigenSkuCaja =
    'Ventas de los últimos 12 meses que contienen "%s". ' +
    'Elija el ticket de origen o cancele para devolver sin origen.';
  SErrorVentaOrigenCajaSinSeleccion =
    'Seleccione una venta de la lista o cancele.';
  SErrorDevolucionTicketOperacionEnCurso =
    'Termine o cancele la operación en curso antes de cargar ' +
    'una devolución por ticket.';
  SAvisoDevolucionTicketOtraEmpresa =
    'El ticket es de otra empresa: la devolución se grabará como ' +
    'devolución con referencia al ticket de origen, sin ' +
    'rectificativa fiscal.';
  SCaptionDevolucionTicketDe =
    '  —  DEVOLUCIÓN de %s\%s (Tienda %s)';
  SErrorEncolarCierreVentasWs =
    'No se pudo encolar el cierre de caja %s para su publicación web.';
  SErrorRepositorioVentasWsNoAsignado =
    'La publicación web está activa, pero no se asignó su repositorio.';
implementation

end.
