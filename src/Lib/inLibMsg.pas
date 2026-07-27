{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsg                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de UI reutilizables.                                             }
{    Constantes de texto para avisos y errores comunes.                        }
{******************************************************************************}
unit inLibMsg;

interface
var
  SClassRttiNotFnd:string = 'Clase %s no encontrada en rtti. ' +
                            'Hay un error al crear el formulario';
  SLocateNotFnd:string = 'El dato o datos %s no se han encontrado en %s';
  SResWinFNotFnd:string = '%s no encontrada en las tabla del sistema' +
                            ' fza_winforms';
  SCliToTbl:string = 'Cliente: %s pasado correctamente a la tabla de ' +
                     'clientes';
  SEmpToTbl:string = 'Empresa: %s pasada correctamente a la tabla de '+
                     'empresas';
  SErrorDecryptPassBBDD:string = 'Fallo en la lectura y desencriptación' +
                                  ' de password de la Base de Datos.';
  SErrorDecryptPass:string = 'Fallo en la lectura y desencriptación' +
                                  ' de password.';
  SErrorAuthPass:string = 'La contraseña de usuario no es correcta. ';
  SErrorPassMatch:string = 'El password que ha introducido no coincide.';
  SErrorPassMatchBBDD:string = 'El password de la BBDD no coincide.';
  SEnterPassBBDD:string = 'Introduzca el password actual de la BBDD';
  SScriptSuccess:string = 'El script se ejecutó exitosamente.';
  SFailLoadScriptBBDD:string = 'No existe script de creación de BD, ' +
                               'instalación fallida';
  SCreateSuccBBDD:string = 'La Base de Datos se creó exitosamente';
  SErrorCreateBBDD:string = 'No existe una base de datos llamada %s, '  +
                            '¿desea crearla? ';
  SBBDDUpdateTo:string = 'La Base de Datos se actualizó a ';
  SNotExistsUpBBDDFile:string = 'No existe script de actualización %s,'+
                       ' instalación fallida';
  SAdviceUpdateBBDD:string = 'Es necesario actualizar la BBDD' +
                            ' con nuevos cambios,' + sLineBreak +
                            ' ¿desea proceder con el procedimiento' +
                            ' de actualización?';
  SPasswordBBDDChanged:string = 'Password de la BBDD cambiado '+
                                'correctamente.' + sLineBreak +
                                'Anote el password: "%s" en un lugar'+
                                ' seguro para evitar problemas.';
  SWantDefChgBBDD:String= '¿Desea cambiar el password por defecto ' +
                          'de la Base de Datos?';
  SAdvMsg:String = 'Mensaje Advertencia';
  SNoConnBBDD:String = 'No hay conexión con la bbdd';
  SConnSuccBBDD:String = 'La conexión se estableció exitosamente.';
  SGetPassBBDD:string = 'Escriba password de la BBDD';
  SConnFailBBDD:string = 'Conexión fallida. Usuario, password, ' +
                           'host, puerto o Nombre de la BBDD no es válido.';
  SErrorSentenciaScript:string =
    'Ocurrió un error ejecutando la siguiente sentencia:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Deseas ignorar el error y continuar con el script?';
  SSolicitudPassBBDD:string = 'Introduzca password de la BBDD';
  SSolicitudNuevoPassBBDD:string =
    'Introduzca el nuevo password de la BBDD';
  SScriptEjecutado:string = 'El script se ejecutó exitosamente';
  SScriptNoEjecutado:string = 'El script no fue ejecutado';
  SErrorConexionServidorBBDD:string =
    'No se pudo conectar al servidor MySQL/MariaDB:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Revise la configuración pulsando "Configurar BBDD".';
  SErrorEstructuraBBDD:string =
    '%s' + sLineBreak + sLineBreak +
    'Puede usar "Subir script" para crear/actualizar la base de datos, ' +
    'o "Recuperar copia" para restaurar un backup.';
  SErrorConexionBBDD:string =
    'No se pudo conectar a la base de datos "%s":' + sLineBreak + '%s';
  SErrorInicioAutomatico:string =
    'No se pudo completar el inicio automático:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Introduzca sus credenciales manualmente.';
  SLicenciaEstablecida:string =
    'Licencia establecida.' + sLineBreak + sLineBreak +
    'Código: %s' + sLineBreak +
    'NIF de empresa: %d' + sLineBreak +
    'INI: %s' + sLineBreak + sLineBreak + '%s';
  SLicenciaNoEstablecidaSinNif:string =
    'No se ha establecido licencia.' + sLineBreak + sLineBreak +
    'No hay NIF de empresa configurado.' + sLineBreak +
    'Mientras no haya NIF de empresa, no se exigirá licencia.';
  SErrorEstablecerLicencia:string =
    'No se pudo establecer la licencia.' + sLineBreak + sLineBreak + '%s';
  SModoDemo:string = 'Modo DEMO: limitado a %d facturas al día.';
  SCancelacionSolicitada:string =
    'La cancelación ya está solicitada. Espere a que termine la sentencia ' +
    'actual.';
  SPreguntaCancelarOperacion:string =
    'Hay una operación en curso moviendo datos.' + sLineBreak +
    sLineBreak + '¿Desea abandonar la operación en curso?';
  SOperacionCancelada:string = 'Operación cancelada.';
  SCopiaSeguridadGuardada:string =
    'La copia se guardó exitosamente';
  SErrorCrearCopiaSeguridad:string =
    'No se pudo crear la copia de seguridad.' + sLineBreak + '%s';
  SRestauracionCancelada:string =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente restaurada.';
  SErrorRestaurarCopiaSeguridad:string =
    'Hubo problemas al restaurar la copia.' + sLineBreak + '%s';
  SPreguntaReemplazarFichero:string =
    '¿Desea reemplazar el fichero existente?';
  SCopiaSeguridadCancelada:string = 'La copia se canceló';
  SCargaScriptCancelada:string = 'Se canceló la carga del script.';
  SUsuarioNoExiste:string = 'El nombre de usuario no existe';
  // Core
  SErrorContextoSesionFormularioNoConfigurado:string =
    'No se ha configurado el contexto de sesión del formulario.';
  SErrorServicioAuditoriaDatosNoConfigurado:string =
    'No se ha configurado el servicio de auditoría de datos.';
  SErrorProveedorEdicionParametrosNoConfigurado:string =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosAplicacionEditablesNoConfigurados:string =
    'No se han configurado los parámetros de aplicación editables.';
  SInfoParametrosGuardados:string =
    'Se guardaron %d parámetros para: %s';
  SAvisoParametrosRestringidosIgnorados:string =
    'Se ignoraron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SAvisoParametrosRestringidosNoGuardados:string =
    'No se guardaron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SInfoSinCambiosParametros:string =
    'No se detectaron cambios para guardar.';
  SInfoLayoutGuardado:string = 'Layout guardado.';
  SPreguntaSalirSinGuardar:string =
    '¿Seguro que desea salir sin guardar?';
  SAvisoSinUsuariosParametrosGuardados:string =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuario:string = 'Cambiar usuario';
  SSolicitudCambiarUsuario:string =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Introduce el nombre de usuario:';
  SErrorUsuarioNoEncontrado:string = 'Usuario no encontrado: %s';
  SErrorEnviarTicketImpresora:string =
    'No se pudo enviar el ticket a la impresora "%s".' + sLineBreak +
    '%s' + sLineBreak + 'Se abrirá la vista previa.';
  SAvisoSinComandosESCPOSImpresora:string =
    'No hay comandos ESC/POS para enviar a la impresora.';
  SInfoTicketEnviadoImpresora:string =
    'Ticket enviado correctamente a: %s';
  SErrorImprimir:string = 'Error al imprimir: %s';
  SAvisoSinComandosESCPOSPDF:string =
    'No hay comandos ESC/POS para generar el PDF.';
  SInfoPDFGuardado:string = 'PDF guardado en: %s';
  SInfoPNGGuardado:string = 'PNG guardado en: %s';
  SErrorContextoInicioSesionNoProporcionado:string =
    'No se ha proporcionado el contexto de inicio de sesión.';
  SErrorParametrosSinEstadoLicencia:string =
    'Los parámetros no admiten el estado de licencia.';
  SErrorParametrosAplicacionSinContratoEdicion:string =
    'Los parámetros de aplicación no ofrecen el contrato de edición.';
  SErrorParametrosCajaSinContratoEdicion:string =
    'Los parámetros de caja no ofrecen el contrato de edición.';
  SErrorServicioConexionesNoDisponible:string =
    'No está disponible el servicio de conexiones.';
  SCertificadoQuedaMenosUnDia:string = 'queda menos de 1 día';
  SCertificadoQuedaUnDia:string = 'queda 1 día';
  SCertificadoQuedanDias:string = 'quedan %d días';
  SAvisoCertificadoCaducado:string =
    'certificado electrónico caducado el %s.';
  SAvisoCertificadoProximoCaducar:string =
    'certificado electrónico caduca el %s (%s).';
  SAvisoCertificadosCaducidad:string =
    'Atención: hay certificados electrónicos próximos a caducar o ya ' +
    'caducados.' + sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Revise la ficha de empresa y renueve el certificado.';
  SAvisoCargaPermisosRestringidos:string =
    'No se pudieron cargar los permisos.' + sLineBreak +
    'El acceso se ha restringido por seguridad.' + sLineBreak +
    'Revise el registro de la aplicación en:' + sLineBreak + '%s';
  SInfoCopiaSeguridadGuardada:string =
    'La copia se guardó exitosamente.';
  SAvisoRestauracionCancelada:string =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente modificada.';
  SErrorEjecutarScript:string =
    'Hubo problemas al ejecutar el script.' + sLineBreak + '%s';
  SPreguntaSalirAplicacion:string =
    '¿Quiere salir de la aplicación Fzam?';
  SPreguntaCopiaSeguridadAntesDDL:string =
    'ATENCIÓN: El script contiene sentencias DDL (modifican la estructura ' +
    'de la base de datos).' + sLineBreak +
    'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
    'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
    '¿Deseas realizar una copia de seguridad antes de continuar?';
  SInfoScriptCancelado:string =
    'Operación cancelada. El script no se ejecutará.';
  SErrorAbrirDireccion:string =
    'No se ha podido abrir la dirección: %s';
  // DataModules A-C
  SAvisoAlbaranFacturado:string =
    'No se puede borrar el albaran: ya esta facturado. ' +
    'Borra o deshaz primero la factura vinculada.';
  SPreguntaBorrarAlbaran:string =
    '¿Borrar el albaran %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SAvisoAlmacenSalidaAlbaranObligatorio:string =
    'Debe seleccionar el almacén de salida del albarán.';
  SErrorLineaAlbaranSinArticulo:string =
    'La línea del albarán no tiene artículo; no se puede guardar.';
  SErrorCabeceraAlbaranSinGrabar:string =
    'Graba la cabecera del albaran antes de guardar lineas.';
  SErrorAsignarLineaAlbaran:string =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en ' +
    'la base de datos.';
  SErrorContadorAlbaran:string =
    'No se pudo obtener un numero de albaran valido. Revise el contador ' +
    'AV de la serie %s y empresa %s.';
  SAvisoAlmacenDestinoAlbaranCompraObligatorio:string =
    'Debe seleccionar el almacén destino del albarán de compra.';
  SAvisoAlbaranCompraFacturado:string =
    'No se puede borrar el albaran de compra: ya esta facturado. Borra o ' +
    'deshaz primero la factura de compra vinculada.';
  SPreguntaBorrarAlbaranCompra:string =
    '¿Borrar el albaran de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SErrorContadorAlbaranCompra:string =
    'No se pudo obtener un numero de albaran de compra valido. Revise el ' +
    'contador AB de la serie %s y empresa %s.';
  SErrorCodigoSkuCodigoBarrasObligatorio:string =
    'Indique el código de SKU al añadir un nuevo código de barras. Para ' +
    'crear un SKU nuevo use la pestaña SKUs.';
  SErrorCampoCodigoBarrasAusente:string =
    'Falta el campo CODIGO_BARRAS_CB.';
  SErrorCodigoSkuObligatorio:string = 'Indique el código del SKU.';
  SErrorFilaCodigoBarrasInexistente:string =
    'Esta fila no representa un código de barras existente. No hay nada ' +
    'que eliminar.';
  SErrorProveedorPrincipalArticulo:string =
    '%s ya tiene un proveedor principal asociado a este artículo.';
  SErrorDescripcionArticulo:string =
    '%s no es un valor válido para el campo Descripción de Artículos';
  SPreguntaDesactivarTarifaSinPrecio:string =
    'El precio de salida pasa a 0. ¿Desea desactivar la tarifa?';
  SPreguntaActivarTarifaConPrecio:string =
    'El precio de salida es mayor que 0. ¿Desea activar la tarifa?';
  SErrorTarifaFechasConcurrentes:string =
    'No se pueden grabar dos precios para una tarifa activa en fechas ' +
    'concurrentes para el artículo/SKU %s';
  SErrorAtributoBasicoObligatorio:string =
    'Indica el atributo (CO para color, TAL para talla, etc.).';
  SErrorCodigoAtributoBasicoObligatorio:string =
    'El código del atributo básico es obligatorio.';
  SErrorNombreAtributoBasicoObligatorio:string =
    'El nombre del atributo básico es obligatorio.';
  SErrorValorColeccionAtributosObligatorio:string =
    'Selecciona un valor para añadirlo a la colección.';
  SPreguntaBorrarClienteConFacturas:string =
    'El cliente tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SErrorRazonSocialCliente:string =
    '%s no es un valor válido para el campo Razón Social de Cliente';
  SErrorCambiarFormatoSesion:string =
    'No se puede cambiar el formato distribuido de una sesion ya creada. ' +
    'Crea una sesion nueva con el modo deseado.';
  SErrorEmpresaSesionObligatoria:string =
    'Selecciona una empresa antes de grabar la sesion.';
  SErrorSerieSesionObligatoria:string =
    'Teclea una serie antes de grabar la sesion (p.ej. %s-SE-1).';
  SErrorContadorSesion:string =
    'No se pudo obtener el siguiente numero. Revisa que exista una fila ' +
    'en fza_contadores para (TIPO_DOC=SE, EMPRESA=%s, SERIE=%s) o que el ' +
    'SP PRC_GET_NEXT_CONT_FACT_SERIE este disponible.';
  SErrorCodigoSerieEmpresa:string =
    'No se pudo obtener CODIGO_SERIE_EMPSER del contador ES via ' +
    'PRC_GET_NEXT_CONT.';
  SAvisoColacionSesion:string =
    'No se pudo fijar la colación de la sesión: %s';
  SAvisoTimeoutServidor:string =
    'No se pudo establecer el timeout del servidor: %s';
  SErrorBBDDDuplicado:string =
    'Ya existe un registro con ese valor (entrada duplicada).';
  SErrorBBDDCamposObligatorios:string =
    'Hay campos obligatorios sin rellenar.';
  SErrorBBDDCampoDesconocido:string =
    'Campo desconocido en la consulta SQL: %s';
  SErrorBBDDTablaNoExiste:string =
    'La tabla consultada no existe en la base de datos: %s';
  SErrorBBDDSinPermisos:string =
    'No tiene permisos suficientes para realizar esta acción en la base ' +
    'de datos.';
  SErrorBBDDClaveForaneaNoExiste:string =
    'El valor no existe en la tabla relacionada (clave foránea).';
  SErrorBBDDRegistroDependiente:string =
    'No se puede eliminar: existen registros que dependen de este.';
  SErrorBBDDDatoDemasiadoLargo:string =
    'El dato introducido es demasiado largo para el campo.';
  SErrorBBDDCredencialesIncorrectas:string =
    'Acceso denegado: usuario o contraseña incorrectos.';
  SErrorBBDDConexionServidor:string =
    'No se puede conectar al servidor MySQL. Comprueba la red y el puerto.';
  SErrorBBDDConexionPerdida:string =
    'La conexión con el servidor MySQL se ha perdido.';
  SErrorBBDDConexionPerdidaConsulta:string =
    'Se perdió la conexión durante la ejecución de la consulta.';
  SErrorBBDDTimeoutBloqueo:string =
    'El servidor está ocupado (Tiempo de espera de bloqueo). Inténtalo de ' +
    'nuevo.';
  SErrorBBDDDeadlock:string =
    'Se ha producido un bloqueo cruzado (Deadlock). Inténtalo de nuevo.';
  SErrorBBDDTablaYaExiste:string =
    'La tabla o vista ya existe en la base de datos %s';
  SErrorBBDDProcedimientoYaExiste:string =
    'El procedimiento o función ya existe en la base de datos.' +
    sLineBreak + 'Detalle del servidor: %s';
  SErrorBBDDGenerico:string =
    'Error en base de datos [%d]:' + sLineBreak + '%s';
  SDetalleErrorMySQL:string = sLineBreak + '(MySQL %d: %s)';
  SErrorAbrirConsultaOpe:string =
    '[ConsultaOpe] Error abriendo %s: %s';
  // DataModules D-F
  SErrorAlmacenSalidaDevolucionCompra:string =
    'Debe seleccionar el almacen de salida de la devolucion.';
  SAvisoDevolucionCompraFacturada:string =
    'No se puede borrar la devolucion de compra: ya esta facturada. Borra ' +
    'o deshaz primero la factura de compra vinculada.';
  SPreguntaBorrarDevolucionCompra:string =
    '¿Borrar la devolucion de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se revertiran los movimientos de stock.';
  SErrorCabeceraDevolucionCompraSinGrabar:string =
    'Graba la cabecera de la devolucion antes de guardar lineas.';
  SErrorContadorDevolucionCompra:string =
    'No se pudo obtener un numero de devolucion de compra valido. Revise ' +
    'el contador DC de la serie %s y empresa %s.';
  SErrorTipoDestinoDocumentoTrabajo:string =
    'El tipo de destino debe ser USUARIO o GRUPO.';
  SErrorDestinoCompartidoNoExiste:string =
    'El usuario o grupo indicado no existe.';
  SErrorDestinoCompartirObligatorio:string =
    'Indique el usuario o grupo con el que comparte.';
  SErrorCompartirDocumentoTrabajoSoloPropietario:string =
    'Solo el propietario puede compartir el Documento de Trabajo.';
  SErrorCabeceraDocumentoTrabajoSinGrabar:string =
    'Grabe primero la cabecera del Documento de Trabajo.';
  SErrorCompartirDocumentoTrabajoConsigoMismo:string =
    'No es necesario compartir el documento consigo mismo.';
  SErrorBorrarDocumentoTrabajoSoloPropietario:string =
    'Solo el propietario puede borrar un Documento de Trabajo.';
  SErrorCambiarPropietarioDocumentoTrabajo:string =
    'El propietario del Documento de Trabajo no se puede cambiar.';
  SErrorTituloDocumentoTrabajoObligatorio:string =
    'Indique el titulo del Documento de Trabajo.';
  SErrorBorrarLineasDocumentoTrabajoSoloPropietario:string =
    'Solo el propietario puede borrar lineas del Documento de Trabajo.';
  SErrorEditarLineasDocumentoTrabajoSoloPropietario:string =
    'Solo el propietario puede editar lineas del Documento de Trabajo.';
  SErrorArticuloLineaDocumentoTrabajoObligatorio:string =
    'Indique el articulo de la linea.';
  SErrorSkuLineaDocumentoTrabajoObligatorio:string =
    'Indique el SKU/unidad de la linea.';
  SErrorDejarCompartirDocumentoTrabajoSoloPropietario:string =
    'Solo el propietario puede dejar de compartir el Documento de Trabajo.';
  SErrorDestinoCompartidoObligatorio:string =
    'Indique el usuario o grupo con el que se comparte.';
  SErrorBorrarEfectoCompraRemesado:string =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de pago.';
  SErrorBorrarEfectoCompraPagado:string =
    'No se puede borrar el efecto: tiene pago o conciliación registrada.';
  SErrorFusionarEfectosCompraEstado:string =
    'Solo se pueden fusionar efectos pendientes, sin pagos, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosCompraOrigen:string =
    'Solo se pueden fusionar efectos de la misma empresa y proveedor.';
  SErrorFusionarEfectosCompraSinPendiente:string =
    'Los efectos seleccionados no tienen importe pendiente.';
  SErrorBorrarEfectoVentaRemesado:string =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de cobro.';
  SErrorBorrarEfectoVentaCobrado:string =
    'No se puede borrar el efecto: tiene cobro o conciliación registrada.';
  SErrorFusionarEfectosVentaEstado:string =
    'Solo se pueden fusionar efectos pendientes, sin cobros, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosVentaOrigen:string =
    'Solo se pueden fusionar efectos de la misma empresa y cliente.';
  SErrorFusionarEfectosVentaSinPendiente:string =
    'Los efectos seleccionados no tienen importe pendiente.';
  SPreguntaCambioCriticoEmpresa:string =
    'Atención: %s una empresa puede anular la licencia del programa o ' +
    'invalidar el sistema Verifactu existente.' + sLineBreak + sLineBreak +
    'Revise que los datos fiscales, certificados y la instalación SIF ' +
    'siguen siendo correctos.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  SErrorPorcentajeRetencionEmpresa:string =
    '%d no es un valor válido  para %% de Retención';
  SErrorRetencionesEmpresaConcurrentes:string =
    'No se pueden grabar dos porcentajes  activos en la misma fecha para ' +
    'la empresa %s';
  SErrorSerieEmpresa:string =
    '%s no es un valor válido  para serie por Empresa ';
  SErrorIbanEmpresa:string =
    'IBAN no válido para el banco de la empresa: %s';
  SPreguntaBorrarEmpresaConFacturas:string =
    'La empresa tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SErrorRazonSocialEmpresa:string =
    '%s no es un valor de registro válido para el campo Razón Social de ' +
    'Empresa';
  SErrorCodigoEmpresa:string =
    '%s no es un valor de registro válido para el campo Código de Empresa';
  SErrorOperacionIntracomunitariaClienteNoUE:string =
    'La operacion "%s" es intracomunitaria, pero el cliente no es de la UE ' +
    '(pais %s). Corrija el tipo de operacion o el pais del cliente.';
  SErrorOperacionExportacionClienteNoExtranjero:string =
    'La operacion "%s" es exportacion fuera de la UE, pero el cliente es ' +
    'comunitario o nacional. Corrija el tipo o el pais del cliente.';
  SErrorOperacionSinIvaConCuota:string =
    'La operacion no repercute IVA (intracomunitaria, ISP o exportacion), ' +
    'pero la factura tiene IVA (%s). Revise el IVA o el tipo de operacion.';
  SErrorNifIvaClienteExtranjero:string =
    'El cliente es extranjero (pais %s) y Verifactu exige su NIF-IVA. ' +
    'Indique el NIF del cliente.';
  SErrorCalcularBorradorDetalle:string =
    'Error al calcular borrador: %s';
  SErrorCalculoBorrador:string =
    'Error en cálculo de borrador: %s';
  SErrorTipoIvaFactura:string = 'Tipo de Iva incorrecto';
  SErrorBorrarBorradorFase:string =
    'El borrador está en fase %s: ya se ha lanzado a Verifactu y no puede ' +
    'borrarse. Use Anular registro fiscal o emita una rectificativa.';
  SPreguntaBorrarFactura:string =
    '¿Borrar la factura %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas, recibos/efectos y movimientos de stock.';
  SErrorBorrarBorradorEfectosCobrados:string =
    'El borrador tiene efectos de cobro cobrados, conciliados o remesados. ' +
    'No puede borrarse.';
  SErrorInsertarLineasCabeceraFactura:string =
    'No se puede insertar líneas sin grabar primero la cabecera: %s';
  SErrorBorradorSinGrabarParaLineas:string =
    'Debe grabar primero el borrador antes de añadir líneas';
  SErrorSerieFacturaOtraEmpresa:string =
    'Esta serie es usada por otra empresa. Debe cambiar la serie ';
  SErrorRazonSocialClienteBorrador:string =
    'Debe escribir la razón social del cliente del borrador';
  SErrorRazonSocialEmpresaBorrador:string =
    'Debe escribir la razón social de la empresa del borrador';
  SErrorSerieBorradorObligatoria:string =
    'Debe seleccionar una serie del borrador';
  SErrorPaisClienteEmpresaBorrador:string =
    'Debe seleccionar un pais para cliente y empresa.';
  SErrorFechaBorradorObligatoria:string =
    'Debe indicar la fecha del borrador.';
  SErrorNifClienteFactura:string =
    'El NIF/CIF/NIE del cliente no es valido: %s';
  SErrorNifEmpresaFactura:string =
    'El NIF/CIF/NIE de la empresa no es valido: %s';
  SErrorFechaFacturaAnteriorSerie:string =
    'La fecha %s es anterior al ultimo borrador de la serie (%s). La ' +
    'numeracion debe seguir orden cronologico.';
  SAvisoFechaBorradorFutura:string =
    'Aviso: la fecha del borrador es posterior a hoy.';
  SErrorCabeceraBorradorSinGrabar:string =
    'No se ha grabado la cabecera del borrador';
  SErrorAsignarNumeroFactura:string =
    'No se ha podido asignar numero a la factura (serie %s). Revise el ' +
    'contador de la serie.';
  SAvisoHuecoNumeracionFactura:string =
    'Aviso: hay un salto en la numeracion de la serie %s. La ley exige ' +
    'numeracion correlativa: el numero o numeros que falten deben cubrirse.';
  SErrorCerrarFacturaCompraSinLineas:string =
    'No se puede cerrar la factura: no tiene lineas con cantidad mayor que ' +
    '0. Añade lineas antes de cerrar.';
  SErrorBorrarFacturaCompraEfectosPagados:string =
    'No se puede borrar la factura: tiene efectos pagados, remesados o ' +
    'conciliados.';
  SPreguntaBorrarFacturaCompra:string =
    '¿Borrar la factura de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y efectos, y se desmarcaran los albaranes ' +
    'vinculados.';
  SErrorCabeceraFacturaCompraSinGrabar:string =
    'Graba la cabecera de la factura antes de guardar lineas.';
  SErrorContadorFacturaCompra:string =
    'No se pudo obtener un numero de factura de compra valido. Revise el ' +
    'contador FP de la serie %s y empresa %s.';
  SAvisoPropiedadFamiliaDuplicada:string = 'Propiedad Duplicada';
  SErrorNombreFamilia:string =
    '%s no es un valor válido para el campo Nombre de Familias';
  SErrorFamiliaPadreIgualHija:string =
    '%s no puede ser padre e hijo a la vez. Revise campo Familia Padre';
  SErrorServicioConexionesDatosNoConfigurado:string =
    'No se ha configurado el servicio de conexiones de datos.';
  SErrorContextoSesionFiltrosNoConfigurado:string =
    'No se ha configurado el contexto de sesión.';
  SErrorCodigoFacturaeFormaPago:string =
    '%s no es un codigo Facturae valido para el campo Codigo Facturae de ' +
    'Formas de Pago. Use 01..19.';
  SErrorDescripcionFormaPago:string =
    '%s no es un valor válido para el campo Descripción de Formas de Pago';
  // DataModules G-M
  SErrorContextoSesionModuloDatosNoConfigurado:string =
    'No se ha configurado el contexto de sesión del módulo de datos.';
  SErrorSerieInventarioObligatoria:string =
    'No se puede grabar el inventario sin una serie. Selecciona una serie ' +
    'en la cabecera (campo SERIE), o configura una serie por defecto de ' +
    'tipo IN para la empresa en fza_empresas_series.';
  SErrorContadorLineasInventarioNoInstalado:string =
    'No se puede reservar la linea del inventario: falta la columna ' +
    'fza_inventarios.CONTADOR_LINEAS_INV. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\inventarios_contador_lineas.sql.';
  SErrorCabeceraInventarioSinGrabarParaReserva:string =
    'No se puede reservar la linea: graba primero la cabecera del ' +
    'inventario para tener empresa, almacen, serie y numero definitivos.';
  SErrorCabeceraInventarioNoEncontrada:string =
    'No se ha encontrado la cabecera del inventario para reservar la ' +
    'siguiente linea.';
  SErrorActualizarContadorLineasInventario:string =
    'No se ha podido actualizar el contador de lineas del inventario.';
  SErrorEmpresaCabeceraInventarioObligatoria:string =
    'La cabecera del inventario no tiene empresa. Selecciona una empresa ' +
    'antes de anadir lineas.';
  SErrorAlmacenCabeceraInventarioObligatorio:string =
    'La cabecera del inventario no tiene almacen. Selecciona un almacen ' +
    'antes de anadir lineas.';
  SErrorSerieCabeceraInventarioObligatoria:string =
    'La cabecera del inventario no tiene serie. Vuelve a la pestana ' +
    'Cabecera, selecciona una serie y vuelve a intentar grabar la linea.';
  SErrorNumeroCabeceraInventarioObligatorio:string =
    'La cabecera del inventario no tiene numero. Graba primero la cabecera ' +
    'para que el sistema asigne el numero.';
  SErrorAtributoLineaInventarioObligatorio:string =
    'La línea %s del artículo %s requiere %d atributos y el atributo nº %d ' +
    'está sin rellenar. Completa todos los selectores (Color, Talla, …) o ' +
    'elimina la línea.';
  SPreguntaCrearSkuInventario:string =
    'El SKU "%s" no existe en la base de datos.' + sLineBreak + sLineBreak +
    '¿Quieres crearlo automáticamente con los atributos seleccionados y ' +
    'guardar la línea?' + sLineBreak + sLineBreak +
    'Sí: se crea el SKU (fza_articulos_skus + fza_atributos_sku) y se ' +
    'graba la línea.' + sLineBreak +
    'No: no se graba. Cambia los atributos a una combinación válida o ' +
    'pulsa "- Eliminar línea".';
  SErrorSkuInventarioNoExiste:string =
    'SKU "%s" no existe. La línea no se ha grabado. Cambia los atributos o ' +
    'elimina la línea.';
  SErrorEliminarLineasInventarioNoAbierto:string =
    'No se pueden eliminar líneas: el inventario no está ABIERTO';
  SErrorAnadirLineaCabeceraInventario:string =
    'No se puede añadir una línea: la cabecera del inventario no se ha ' +
    'podido grabar.' + sLineBreak + '%s' + sLineBreak +
    'Completa los datos obligatorios de la cabecera y vuelve a intentarlo.';
  SErrorRecalcularInventarioNoAbierto:string =
    'Solo se puede recalcular un inventario en estado ABIERTO';
  SErrorAplicarInventarioNoAbierto:string =
    'Solo se puede aplicar un inventario en estado ABIERTO';
  SErrorAplicarInventarioSinLineas:string =
    'No se puede aplicar un inventario sin líneas. Añade al menos una línea ' +
    'con diferencia de cantidad o de coste antes de regularizar.';
  SErrorEliminarRegularizacionInventarioNoAplicado:string =
    'Solo se puede eliminar la regularización de un inventario APLICADO';
  SErrorCargarArticulosInventarioNoAbierto:string =
    'Solo se pueden cargar artículos en un inventario ABIERTO';
  SErrorCompletarInventarioNoAbierto:string =
    'Solo se puede completar un inventario ABIERTO';
  SErrorArticuloLineaInventarioObligatorio:string =
    'Debe indicar un artículo (la línea actual está vacía).';
  SErrorAnadirSkusInventarioNoAbierto:string =
    'Solo se pueden añadir SKUs en un inventario ABIERTO';
  SErrorValorAtributoSkuInventarioNoEncontrado:string =
    'No se encontró el valor "%s" en el atributo nº %d del artículo %s. ' +
    'No se ha podido crear el SKU %s.';
  SErrorCodigoIva:string =
    '%s no es un valor de registro válido para el campo Código de IVA';
  SErrorGrupoIvaNoExiste:string =
    '%s no es un valor válido o no existe para grupo de IVAS';
  SErrorRangoFechasIva:string =
    'Error de Rango en las fechas. Error en la fecha.O se han establecido ' +
    'dos periodos activos en el mismo periodo para la zona %s';
  SErrorDescripcionGrupoIva:string =
    '%s no es un valor de registro válido para el campo Descripción de ' +
    'Grupos de IVA';
  SErrorCodigoGrupoIva:string =
    '%s no es un valor de registro válido para el campo Código de Grupos ' +
    'de IVA';
  SErrorDosGruposIvaPredeterminados:string =
    'No es posible marcar dos grupos de IVA como Grupo de IVA por Defecto';
  SAvisoEdicionMovimientoAlmacen:string =
    'No se permite %s movimientos de almacén manualmente.' + sLineBreak +
    'Usa el proceso correspondiente (albarán, factura, traspaso, ' +
    'regularización de inventario...).';
  // Resto de DataModules
  SPreguntaBorrarPedidoVenta:string =
    '¿Borrar el pedido de venta %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y se descontara el pendiente de servir en ' +
    'stock.';
  SErrorLineaPedidoSinArticulo:string =
    'La línea del pedido no tiene artículo; no se puede guardar.';
  SErrorCabeceraPedidoSinGrabar:string =
    'Graba la cabecera del pedido antes de guardar lineas.';
  SErrorAsignarLineaPedido:string =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en la ' +
    'base de datos.';
  SAvisoAlmacenSalidaPedidoObligatorio:string =
    'Debe seleccionar el almacén de salida del pedido.';
  SAvisoClientePedidoObligatorio:string =
    'Debe seleccionar un cliente antes de guardar el pedido.';
  SAvisoClientePedidoNoExiste:string =
    'El cliente %s no existe. Seleccione un cliente válido antes de guardar ' +
    'el pedido.';
  SAvisoAlmacenDestinoPedidoCompraObligatorio:string =
    'Debe seleccionar el almacén destino del pedido de compra.';
  SPreguntaBorrarPedidoCompra:string =
    '¿Borrar el pedido de compra %s / %s?' + sLineBreak +
    'Se eliminaran sus lineas y pendientes de recibir.';
  SErrorContadorPedidoCompra:string =
    'No se pudo obtener un numero de pedido de compra valido. Revise el ' +
    'contador PC de la serie %s y empresa %s.';
  SErrorContextoSesionPerfilesNoConfigurado:string =
    'No se ha configurado el contexto de sesión.';
  SErrorProveedorKitsNoSeleccionado:string =
    'Selecciona un proveedor antes de crear kits.';
  SErrorProveedorKitsSinGrabar:string =
    'Graba el proveedor antes de crear kits.';
  SErrorCodigoKitProveedorObligatorio:string =
    'El kit necesita un código (p. ej. CURVA-STD).';
  SErrorNombreKitProveedorObligatorio:string =
    'El kit necesita un nombre.';
  SErrorKitProveedorNoSeleccionadoParaTallas:string =
    'Crea o selecciona un kit antes de añadir tallas.';
  SErrorTallaDestinoKitProveedorObligatoria:string =
    'La fila del kit necesita la talla destino (p. ej. 38, M).';
  SErrorKitProveedorNoSeleccionado:string =
    'Selecciona o crea un kit primero.';
  SErrorSistemaTallasKitProveedorObligatorio:string =
    'El kit no tiene sistema de tallas. Asigna uno en la columna "Sistema ' +
    'tallas" para poder generar sus tallas.';
  SErrorCodigoAutomaticoProveedor:string =
    'No se pudo generar el código automático del proveedor.';
  SErrorOrdenAutomaticoProveedor:string =
    'No se pudo generar el orden automático del proveedor.';
  SErrorRemesaVentaNoSeleccionada:string = 'Selecciona una remesa.';
  SErrorRemesaVentaNoEncontrada:string =
    'No se encuentra la remesa de venta.';
  SErrorRemesaVentaSinEfectosPendientes:string =
    'La remesa no tiene efectos pendientes.';
  SErrorGuardarCodigoAcreedorSepa:string =
    'No se pudo guardar el código acreedor SEPA.';
  SErrorGuardarMandatoSepaCliente:string =
    'No se pudo guardar el mandato SEPA del cliente %s.';
  SErrorNombreSesionCambioTarifaObligatorio:string =
    'El nombre de la sesion es obligatorio.';
  SErrorTarifaDestinoObligatoria:string =
    'La tarifa destino es obligatoria.';
  SErrorNombreUsuario:string =
    '%s no es un valor de registro válido para el campo usuario';
  SErrorUsuarioCoincideGrupo:string =
    'El usuario %s coincide con un grupo del sistema';
  SErrorCodigoAtributoVariacionObligatorio:string =
    'El código del atributo es obligatorio.';
  // Lib A-D
  SErrorConexionPrincipalTrabajoNoDisponible:string =
    'No hay conexión principal para crear una conexión de trabajo.';
  SErrorPrefijoEanSesionLargo:string =
    'PREFIJO_EAN_SES demasiado largo: %s';
  SErrorColorBasicoMaterializacionNoExiste:string =
    'No existe el color básico CODIGO_ATB=%s. Créalo en Mto Atributos ' +
    'Básicos antes de materializar.';
  SErrorAlmacenSesionParaAlbaranCompra:string =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'albaran de compra.';
  SErrorAlmacenSesionParaPedidoCompra:string =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'pedido de compra.';
  SErrorAlmacenSesionParaPendienteRecibir:string =
    'Falta CODIGO_ALM_SES en la cabecera de la sesion para generar el ' +
    'pedido pendiente de recibir.';
  SAvisoSelectorConjuntoFilaNoImplementado:string =
    'El selector de valores del conjunto fila aun no esta implementado.' +
    sLineBreak + sLineBreak +
    'Mientras tanto, en la cabecera deja vacio el campo "Conjunto fila" ' +
    'para teclear los colores libremente.';
  STituloNuevaFilaCompra:string = 'Nueva fila';
  SSolicitudNombreFilaCompra:string =
    'Nombre de la fila (color del proveedor):';
  SAvisoConjuntoPivotCompraObligatorio:string =
    'Selecciona primero un "Conjunto pivot" en la cabecera de la sesion ' +
    'para poder anadirle un valor (talla).';
  SErrorConjuntoPivotCompraNoExiste:string =
    'El conjunto pivot no existe en la BBDD.';
  STituloAnadirValorPivotCompra:string =
    'Anadir talla / valor pivot';
  SSolicitudNombreValorPivotCompra:string =
    'Nombre del valor (ej: XXL, 47):';
  SSolicitudOrdenValorPivotCompra:string =
    'Orden (los SKUs se ordenan por este numero; usa pasos de 10).';
  SErrorDistribuidorTallasNoRegistrado:string =
    'No se ha registrado el distribuidor de tallas por almacén.';
  SErrorInvarianteUnidadesTallas:string =
    'La conversión de tallas alteraría las unidades del documento (%s: ' +
    'antes %.2f, después %.2f). Se deshacen los cambios.';
  SErrorAlmacenDistribucionTallasNoDisponible:string =
    'Formato distribuido: se necesita un almacén por defecto y no hay ' +
    'almacenes activos definidos.';
  SErrorArticuloSkuNoEncontrado:string =
    'Artículo/SKU no encontrado: %s';
  SAvisoArticuloSinAtributos:string =
    'El artículo no tiene atributos definidos: %s';
  SErrorFactoriaTallasHorizontalObligatoria:string =
    'El modo de tallas horizontal requiere su factoria especifica';
  SErrorOperacionCanceladaUsuario:string =
    'Operación cancelada por el usuario.';
  SErrorRestauracionEstructuraIncompleta:string =
    'La restauración terminó, pero la estructura mínima no está completa.' +
    sLineBreak + '%s';
  SErrorNombreBBDDDestinoVacio:string =
    'El nombre de la BBDD de destino está vacío.';
  SErrorFicheroCopiaNoExiste:string =
    'No existe el fichero de copia: %s';
  SErrorDesencriptarCopia:string =
    'No se pudo desencriptar la copia. Revise la contraseña o seleccione ' +
    'un fichero SQL sin cifrar.';
  SErrorAlbaranCompraMovimientosNoEncontrado:string =
    'Albaran de compra %s/%s no encontrado para generar movimientos.';
  SErrorAlbaranCompraMovimientosYaGenerados:string =
    'El albaran %s/%s ya tiene movimientos generados. Revierte antes de ' +
    'volver a generar.';
  SErrorAlbaranCompraSinCantidadParaMovimientos:string =
    'El albaran %s/%s no tiene ninguna linea o celda con cantidad > 0 para ' +
    'generar movimientos.';
  SErrorDivisaNoEncontrada:string =
    'Divisa "%s" no encontrada en el resultado';
  SErrorHttpDivisas:string = 'HTTP %d: %s';
  SErrorRedDivisas:string = 'Error de red: %s';
  SErrorJsonDivisas:string = 'Respuesta JSON inválida';
  SErrorPruebaPilaJcl:string =
    'Prueba forzada con /teststack [%s]: JCL stack trace activo';
  SErrorDevolucionCompraMovimientosNoEncontrada:string =
    'Devolucion de compra %s/%s no encontrada para generar movimientos.';
  SErrorDevolucionCompraMovimientosYaGenerados:string =
    'La devolucion %s/%s ya tiene movimientos generados. Revierte antes ' +
    'de volver a generar.';
  SErrorDevolucionCompraSinCantidadParaMovimientos:string =
    'La devolucion %s/%s no tiene ninguna linea o celda con cantidad > 0 ' +
    'para generar movimientos.';
  SErrorEmpresaSinAlmacenActivo:string =
    'La empresa %s no tiene ningún almacén activo disponible.';
  SErrorAlmacenDepositosEmpresaNoEncontrado:string =
    'No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ' +
    '''DEPÓSITO'') activo para la empresa %s.';
  SErrorLimitePeticionesCripto:string =
    'Rate limit alcanzado (429). Espera un momento.';
  SErrorHttpCripto:string = 'HTTP %d: %s';
  SErrorRedCripto:string = 'Error de red: %s';
  SErrorJsonCripto:string = 'Respuesta JSON inválida';
  SPreguntaCrearDocumentoTrabajo:string =
    'Si = crear un Documento de Trabajo nuevo.' + sLineBreak +
    'No = agregar a uno abierto existente.';
  STituloAgregarDocumentoTrabajo:string =
    'Agregar a Documento de Trabajo';
  STituloNuevoDocumentoTrabajo:string =
    'Nuevo Documento de Trabajo';
  SSolicitudTituloDocumentoTrabajo:string = 'Titulo';
  SErrorArticuloDocumentoTrabajoNoActivo:string =
    'No hay articulo activo para agregar.';
  SErrorArticuloDocumentoTrabajoVariosSkus:string =
    'El articulo tiene varios SKUs. Selecciona una unidad concreta.';
  SInfoUnidadAgregadaDocumentoTrabajo:string =
    'Unidad agregada al Documento de Trabajo.';
  STituloDocumentoTrabajo:string = 'Documento de Trabajo';
  SErrorArticuloNoExiste:string =
    'No existe el artículo "%s"';
  SErrorEntradaArticuloVacia:string = 'Entrada vacía.';
  SErrorCodigoBarrasNoEncontrado:string =
    'No se encontró "%s" como código de barras.';
  SErrorArticuloEntradaNoEncontrado:string =
    'No se encontró "%s" como artículo, SKU, código de barras ni modelo de ' +
    'proveedor.';
  SAvisoArticuloRequiereSku:string =
    'El artículo "%s" tiene SKUs (talla/color). Indica un SKU concreto ' +
    'antes de continuar.';
  SErrorArticuloVariacionSinSkusActivos:string =
    'El artículo "%s" no tiene tallas/colores (SKU) activos para vender.';
  SErrorArticuloSinSkusActivos:string =
    'El artículo "%s" no tiene ninguna unidad (SKU) activa para vender.';
  SErrorSkuNoPerteneceArticulo:string =
    'El SKU "%s" no pertenece a "%s" o no está activo.';
  SErrorSesionCompraNoActiva:string = 'No hay sesion activa.';
  SErrorLineaArticuloSesionNoSeleccionada:string =
    'Selecciona o crea una linea de articulo primero.';
  SErrorLineaSesionSinNumero:string =
    'La linea aun no tiene numero. Graba la sesion primero.';
  SErrorSistemaTallasLineaSesionObligatorio:string =
    'La linea no tiene sistema de tallas. Asignale uno en la columna ' +
    '"Sistema tallas" antes de aplicar el kit.';
  SErrorKitProveedorNoExiste:string =
    'El kit %s no existe para el proveedor %s.';
  SErrorKitSinSistemaTallas:string =
    'El kit %s no tiene sistema de tallas. Asignaselo en Proveedores, ' +
    'pestaña Compras, para poder comprobar que coincide con el de la linea.';
  SErrorTallajeKitNoCoincide:string =
    'El tallaje del kit no coincide con el de la linea: kit = "%s", linea ' +
    '= "%s". Cambia el sistema de tallas de la linea o elige un kit de su ' +
    'mismo tallaje.';
  SErrorGestorTallasNoInicializado:string =
    'Gestor de tallas no inicializado.';
  SErrorKitSinTallasDefinidas:string =
    'El kit %s no tiene tallas definidas. Completalo en Proveedores, ' +
    'pestaña Compras.';
  SAvisoTallasKitSinCorrespondencia:string =
    'Tallas del kit sin correspondencia en el sistema de la linea (no ' +
    'aplicadas): %s';
  SErrorTallasKitSinCorrespondencia:string =
    'Ninguna talla del kit casa con el sistema de tallas de la linea.';
  SErrorSesionIncidenciasSinDetalle:string =
    'Hay incidencias sin detalle.';
  SErrorDataModuleSesionNoInicializado:string =
    'DataModule no inicializado.';
  SErrorSesionNoCerradaParaRevertir:string =
    'La sesion no esta CERRADA, no hay nada que revertir.';
  SErrorRestauracionNoFinalizada:string =
    'La restauración no finalizó correctamente.';
  SErrorCodigoArticuloResolverObligatorio:string =
    'Falta código de artículo.';
  SErrorArticuloResolverNoExiste:string =
    'No existe el artículo "%s".';
  SAvisoArticuloResolverRequiereSku:string =
    'El artículo "%s" tiene SKUs. Indica uno para obtener precio definitivo.';
  STextoLineaIncidenciaSesion:string = 'Linea %d';
  STextoCabeceraIncidenciaSesion:string = 'Cabecera';
  SFormatoIncidenciaSesion:string = '[%s] %s: %s';
  SErrorSesionInactivaIncidencia:string =
    '[CABECERA] No hay sesion activa.';
  STipoIncidenciaCabecera:string = 'CABECERA';
  SErrorEmpresaSesionFaltante:string =
    'Falta CODIGO_EMP_SES (Empresa).';
  SErrorProveedorSesionFaltante:string =
    'Falta CODIGO_PRV_SES (Proveedor).';
  SErrorAlmacenSesionFaltante:string =
    'ESGENERA_ALBARAN=S pero no hay CODIGO_ALM_SES (Almacen).';
  SErrorSesionSinLineas:string = 'La sesion no tiene lineas.';
  STipoIncidenciaDuplicadoInterno:string = 'DUP_INTRA';
  SErrorCodigoDuplicadoInternoSesion:string =
    'Codigo %s repetido dentro de la sesion (primera vez en linea %d). ' +
    'Marca esta linea como REUSAR o cambia el codigo.';
  STipoIncidenciaDuplicado:string = 'DUPLICADO';
  SErrorCodigoDuplicadoSesion:string =
    'Codigo %s ya existe en fza_articulos%s. Decide REUSAR o RENOMBRAR.';
  STextoArticuloInactivoSesion:string = ' (inactivo)';
  STipoIncidenciaCodigo:string = 'CODIGO';
  SErrorLineaSesionSinCodigo:string =
    'La linea no tiene CODIGO_ART_TENTATIVO_SESLIN.';
  STipoIncidenciaDescripcion:string = 'DESCRIPCION';
  SErrorLineaSesionSinDescripcion:string =
    'Linea sin descripcion (codigo %s).';
  STipoIncidenciaCantidades:string = 'CANTIDADES';
  SErrorLineaMatrizSinCantidades:string =
    'Linea MATRIZ sin cantidades por talla (codigo %s - %s).';
  STipoIncidenciaSistemaTallas:string = 'SISTEMA_TALLAS';
  SErrorLineaMatrizSinSistemaTallas:string =
    'Linea MATRIZ sin sistema de tallas (codigo %s).';
  // Lib E-H
  SErrorCodigoEanMinimo7Digitos:string =
    'El código debe tener al menos 7 dígitos para calcular el control.';
  SErrorCodigoBarrasNoNumerico:string =
    'El código de barras contiene caracteres no numéricos.';
  SErrorCodigoEanMinimo12Digitos:string =
    'El código debe tener al menos 12 dígitos para calcular el control.';
  SErrorFacturaeFaltaCampo:string = '- Falta %s.';
  STextoNifParteFacturae:string = 'NIF de %s';
  STextoRazonSocialParteFacturae:string = 'razon social de %s';
  STextoDireccionParteFacturae:string = 'direccion de %s';
  STextoCodigoPostalParteFacturae:string = 'codigo postal de %s';
  STextoPoblacionParteFacturae:string = 'poblacion de %s';
  STextoProvinciaParteFacturae:string = 'provincia de %s';
  SErrorDocumentoFiscalParteFacturae:string = '- %s (%s).';
  SErrorFaltaCodigoDir3Facturae:string =
    '- Falta el codigo DIR3 de %s.';
  SErrorCodigoDir3LargoFacturae:string =
    '- El codigo DIR3 de %s supera 10 caracteres.';
  STextoEmpresaEmisoraFacturae:string = 'empresa emisora';
  STextoClienteFacturae:string = 'cliente';
  STextoOficinaContableFacturae:string = 'la oficina contable';
  STextoOrganoGestorFacturae:string = 'el organo gestor';
  STextoUnidadTramitadoraFacturae:string = 'la unidad tramitadora';
  SErrorNombrePersonaFisicaFacturae:string =
    '- El cliente tiene NIF/NIE de persona física. Rellene el nombre en ' +
    'Parámetros eDoc.';
  SErrorApellidosPersonaFisicaFacturae:string =
    '- El cliente tiene NIF/NIE de persona física. Rellene los apellidos en ' +
    'Parámetros eDoc.';
  SErrorCodigoPagoFacturaeInvalido:string =
    '- El codigo Facturae de la forma de pago debe estar entre 01 y 19.';
  SErrorFacturaeNoExiste:string =
    '- No existe la factura seleccionada.';
  SErrorFacturaeTipoVentaInvalido:string =
    '- El eDoc solo se emite desde venta mayor NORMAL.';
  SErrorFacturaeNoConsolidada:string =
    '- La factura debe estar consolidada antes de emitir eDoc.';
  SErrorFacturaeFechaOficialFaltante:string =
    '- Falta la fecha oficial de la factura.';
  SErrorLineaFacturaeSinDescripcion:string =
    '- La linea %s no tiene descripcion.';
  SErrorLineaFacturaeCantidadCero:string =
    '- La linea %s tiene cantidad cero.';
  SErrorFacturaeSinLineas:string = '- La factura no tiene lineas.';
  SErrorBasesFacturaeNoCuadran:string =
    '- La suma de bases de lineas no cuadra con cabecera.';
  SErrorTotalesFacturaeNoCuadran:string =
    '- Los totales de cabecera no cuadran.';
  SErrorEmitirFacturae:string =
    'No se puede emitir eDoc Facturae:' + sLineBreak + '%s';
  SErrorCertificadoFacturaeNoConfigurado:string =
    'La empresa de la factura no tiene certificado configurado para firmar ' +
    'eDoc Facturae.';
  SErrorConexionFacturaeNoDisponible:string =
    'No hay conexion de base de datos para emitir eDoc.';
  SErrorFicheroSalidaFacturaeNoIndicado:string =
    'No se ha indicado el fichero de salida eDoc.';
  SErrorPorcentajeIvaFueraRango:string =
    'El porcentaje de IVA debe estar entre 0 y 100';
  SErrorPrecioFacturaNegativo:string =
    'Los precios no pueden ser negativos';
  SErrorRespuestaHttpFactuzamApi:string = 'Respuesta HTTP %d';
  SErrorFactuzamApiNoConfigurada:string =
    'La API de Factuzam no está configurada.';
  SInfoEventoFactuzamApiRecibido:string =
    'Evento recibido correctamente.';
  SInfoConsultaFactuzamApiRealizada:string =
    'Consulta realizada correctamente.';
  SInfoDocumentoFactuzamApiGuardado:string =
    'Documento guardado en %s';
  SInfoDocumentoFactuzamApiDescargado:string =
    'Documento descargado.';
  SErrorImportarImagenCodec:string =
    'No se puede importar %s en este equipo: falta el codec "%s".' +
    sLineBreak + sLineBreak +
    'Instálalo gratis desde Microsoft Store y reintenta.' +
    sLineBreak + sLineBreak +
    'Alternativa: guarda la imagen en PNG o JPG y vuelve a subirla.' +
    sLineBreak + sLineBreak +
    'Error original: %s';
  SErrorGuardarFotoSinCodigoArticulo:string =
    'No se puede guardar foto sin codigo de articulo.';
  SErrorFicheroOrigenFotoNoExiste:string =
    'El fichero origen no existe: %s';
  SErrorDirectorioFotosNoConfigurado:string =
    'El parametro appDirFotos no esta configurado.';
  SErrorFotoNoRegistradaParaRotar:string =
    'No hay foto registrada para rotar.';
  SErrorFotoSesionSinSerie:string =
    'Foto de sesion: falta SERIE_SES.';
  SErrorFotoSesionSinNumero:string =
    'Foto de sesion: falta NUMERO_SES.';
  SErrorFotoSesionLineaInvalida:string =
    'Foto de sesion: LINEA debe ser > 0.';
  STextoParametroUrlFotosNube:string =
    '  - URL general del servicio web';
  STextoParametroTokenFotosNube:string =
    '  - API key / token de la instalación';
  STextoParametroReferenciaFotosNube:string =
    '  - Referencia global de la instalación';
  STextoParametroCarpetaFotosNube:string =
    '  - Carpeta de fotos (appDirFotos)';
  SErrorParametrosFotosNubeFaltantes:string =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorFotosNubeHttp:string =
    'El servidor respondió con código %d.';
  SErrorConexionServidorFotosNube:string =
    'No se pudo conectar con el servidor de fotos: %s';
  SErrorAbrirImpresoraTicket:string =
    'No se pudo abrir la impresora: %s';
  SErrorIniciarDocumentoImpresora:string =
    'Error al iniciar documento';
  SErrorEscribirImpresora:string =
    'Error al escribir en impresora';
  SErrorEjecutorBusquedasNoRegistrado:string =
    'No se ha registrado el ejecutor de búsquedas genéricas.';
  SErrorOperacionCajaNoEncontrada:string =
    'No se ha encontrado la operación en la caja especificada.';
  SErrorValoresAtributoNoDefinidos:string =
    'No hay valores definidos para este atributo.';
  SErrorColorCompraNoSeleccionado:string = 'Selecciona un color.';
  SErrorConexionResolverColorCompra:string =
    'No hay conexión para resolver el color.';
  SErrorColorBasicoCompraNoExiste:string =
    'No existe el color básico "%s".';
  SErrorResolverColorCompra:string =
    'No se pudo resolver el color "%s".';
  SErrorArticuloSinSistemaTallasPivote:string =
    '- Articulo SIN sistema de tallas: %s';
  SErrorSistemaTallasSuperaMaximoPivote:string =
    '- Articulo %s: sistema "%s" con %d tallas (maximo %d).';
  SErrorSkuFueraSistemaTallasPivote:string =
    '- SKU %s (art %s): talla "%s" fuera del sistema asignado.';
  SErrorActivarPivoteTallas:string =
    'No se puede activar el modo pivote por tallas:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Se mantiene la vista plana (linea por SKU).';
  SErrorActivarTallasHorizontalesParaColor:string =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorLineaActivaColorNoDisponible:string =
    'No hay una línea activa para cambiar el color.';
  SErrorColorCompraConCantidades:string =
    'El color se elige antes de introducir cantidades. Crea una línea de ' +
    'color nueva para no mezclar tallas.';
  SErrorConsultaLineasCompraNoAbierta:string =
    'No está abierta la consulta de líneas.';
  SErrorLineaActivaColorNoEncontrada:string =
    'No se encontró la línea activa para cambiar el color.';
  SErrorLineaActivaCompraSinArticulo:string =
    'La línea activa no tiene artículo.';
  SPreguntaEliminarLineaTallasVenta:string =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SErrorArticuloSkuNoEncontradoSinDetalle:string =
    'Artículo/SKU no encontrado.';
  SPreguntaEliminarLineaSkuCantidadCero:string =
    'La cantidad queda a cero. ¿Borrar la línea del SKU?';
  SInfoLineaPedidoTallaNoExiste:string =
    'No existe línea de pedido para esa talla.';
  SAvisoSistemaTallasSuperaMaximo:string =
    'El sistema de tallas seleccionado tiene %d valores; el maximo admitido ' +
    'es %d. Elige un sistema con menos tallas o reduce el conjunto antes de ' +
    'usarlo aqui.';
  SErrorHojaCalculoNoActiva:string =
    'No hay hoja activa: llama a NuevaHoja antes de escribir.';
  SErrorControlHojaCalculoObligatorio:string =
    'NuevaHoja requiere un control TdxSpreadSheet.';
  SErrorGuardarHojaCalculoControlObligatorio:string =
    'Guardar requiere un control TdxSpreadSheet, no una vista suelta.';
  // Lib I-P
  SErrorIbanInvalido:string = 'IBAN Inválido';
  SErrorPaisIbanInvalido:string = 'País del IBAN Inválido';
  SErrorDigitoControlIbanInvalido:string =
    'Dígito Control del IBAN Inválido';
  SErrorLongitudCuentaBancariaInvalida:string =
    'Longitud de Número de Cuenta incorrecta';
  SErrorCuentaBancariaInvalida:string =
    'Número de Cuenta incorrecto';
  SErrorDigitoControlCuentaBancaria:string =
    'DC Incorrecto, es %s y debería ser %s';
  SErrorPaisIbanInvalidoTipos:string =
    'Pais del IBAN Inválido';
  SErrorDigitoControlIbanInvalidoTipos:string =
    'Digito Control del IBAN Inválido';
  STextoParametroUrlInventarioNube:string =
    '  - URL general del servicio web';
  STextoParametroTokenInventarioNube:string =
    '  - API key / token de la instalación';
  STextoParametroReferenciaInventarioNube:string =
    '  - Referencia global de la instalación';
  SErrorParametrosInventarioNubeFaltantes:string =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorInventarioNubeHttp:string =
    'El servidor respondió con código %d.';
  SErrorConexionServidorInventarioNube:string =
    'No se pudo conectar con el servidor: %s';
  SErrorInventarioNubeSinIdRecuento:string =
    'El servidor no devolvió id_recuento';
  SErrorDialogoPermisosLayoutNoRegistrado:string =
    'No se ha registrado el diálogo de permisos de layout.';
  STextoResetearLayout:string = 'Resetear Layout';
  SInfoLayoutReseteado:string =
    'Layout reseteado.' + sLineBreak +
    'Se aplicará la próxima vez que abra el formulario.';
  SErrorLimiteDemoFacturas:string =
    'Límite DEMO.' + sLineBreak + sLineBreak +
    'Ya se han emitido %d facturas el día %s.' + sLineBreak +
    'El límite de la copia DEMO es %d facturas al día.';
  SErrorNifEmpresaLicenciaNoConfigurado:string =
    'No hay NIF de empresa configurado.';
  SInfoLicenciaSinNifEmpresa:string =
    'No hay NIF de empresa; no se exige licencia.';
  SErrorLicenciaNoEncontrada:string =
    'No se encontró licencia de aplicación.';
  SInfoLicenciaValida:string =
    'Licencia de aplicación válida.';
  SErrorLicenciaNifsNoCoinciden:string =
    'La licencia de aplicación no coincide con los NIF de empresa ' +
    'configurados.';
  SErrorAccesoFicheroLog:string =
    'No se puede acceder a %s. Faltan permisos.';
  SErrorCrearMutexLog:string = 'Error al crear mutex: %s';
  SErrorParametrosAplicacionNoProporcionados:string =
    'No se han proporcionado los parámetros de aplicación.';
  SErrorRespuestaFormateadorSqlVacia:string =
    'Respuesta vacía del servicio de formateo SQL';
  SErrorRespuestaFormateadorSqlInesperada:string =
    'Respuesta JSON inesperada del formateador SQL';
  SErrorServicioPerfilesNoProporcionado:string =
    'No se ha proporcionado el servicio de perfiles de usuario.';
  SErrorCargarPerfilParametros:string =
    'No se pudo cargar el perfil de parámetros "%s".';
  SErrorPedidoCompraSinPendientesAlmacen:string =
    'No hay lineas pendientes de recibir para el almacen "%s" en el pedido ' +
    '%s/%s.';
  SErrorAlmacenPedidoCompraNoSeleccionado:string =
    'Debes seleccionar un almacen.';
  SErrorPedidoCompraSinCantidadesRecibir:string =
    'No hay cantidades "A recibir" tecleadas para el almacen "%s" en el ' +
    'pedido %s/%s.';
  SErrorContadorAlbaranCompraNoDisponible:string =
    'No se pudo obtener un numero de albaran del contador "AB".';
  SErrorCrearLineasAlbaranCompra:string =
    'No se pudo crear ninguna linea del albaran (lineas origen no ' +
    'encontradas o sin pendiente de recibir).';
  SInfoAlbaranCompraCreado:string =
    'Albaran %s/%s creado correctamente (%d lineas).';
  SErrorAlbaranCompraDestinoNoSeleccionado:string =
    'Debes seleccionar el albaran de destino.';
  SInfoLineasIncorporadasAlbaranCompra:string =
    'Lineas incorporadas al albaran %s/%s.';
  SErrorIncorporarLineasAlbaranCompra:string =
    'No se pudo incorporar ninguna linea (lineas origen no encontradas o ' +
    'sin pendiente de recibir).';
  SInfoLineasIncorporadasAlbaranCompraConCantidad:string =
    'Lineas incorporadas al albaran %s/%s (%d lineas).';
  SErrorConexionPermisosNoDisponible:string =
    'No hay conexión disponible para cargar los permisos.';
  SErrorPreviewExcelNoRegistrado:string =
    'No se ha registrado el previsualizador de hojas de cálculo.';
  SErrorPreviewTicketNoRegistrado:string =
    'No se ha registrado el previsualizador de tickets.';
  // Lib Q-Z
  SErrorRespuestaNtpNoValida:string =
    'sin respuesta NTP valida';
  SInfoRelojFiscalCorrecto:string =
    'Reloj fiscal correcto. Servidor=%s, diferencia=%d s.';
  SErrorRelojSistemaFueraMargenLegal:string =
    'Reloj del sistema fuera de margen legal. Servidor=%s, ' +
    'diferencia=%d s, margen=%d s.';
  SErrorComprobarRelojFiscalNtp:string =
    'No se pudo comprobar el reloj fiscal contra NTP.';
  SErrorContextoSinIban:string = '%s sin IBAN.';
  SErrorContextoIbanNoValido:string =
    '%s con IBAN no válido: %s';
  SErrorNifEmpresaAcreedorSepaNoValido:string =
    'NIF de empresa no válido para acreedor SEPA: %s';
  SErrorClienteSinMandatoSepa:string =
    'Cliente %s sin mandato SEPA.';
  STextoBancoCobroRemesa:string = 'Banco de cobro de la remesa';
  SErrorConexionGenerarRemesaSepa:string =
    'No hay conexión para generar la remesa SEPA.';
  SErrorArchivoSalidaSepaNoIndicado:string =
    'Indica el archivo de salida SEPA.';
  SErrorRemesaSinFechaCobro:string =
    'La remesa no tiene fecha de cobro.';
  SErrorBancoCobroRemesaNoEncontrado:string =
    'No se encuentra el banco de cobro de la remesa.';
  SErrorBancoCobroSinCodigoAcreedorSepa:string =
    'El banco de cobro no tiene código acreedor SEPA.';
  SErrorCodigoAcreedorSepaNoValido:string =
    'Código acreedor SEPA no válido: %s';
  SErrorEfectoSinNombreCliente:string =
    'Efecto sin nombre de cliente.';
  STextoClienteSepa:string = 'Cliente %s';
  SErrorClienteSinFechaFirmaMandatoSepa:string =
    'Cliente %s sin fecha de firma del mandato SEPA.';
  SErrorRecalcularTotalesFactura:string =
    'Error al recalcular totales de la factura: %s';
  SErrorGenerarContadorAutomatico:string =
    'Error al generar contador automático: %s';
  SErrorConexionBbddConExcepcion:string =
    '%s%s Mensaje: %s';
  SErrorNumeroCuentaInvalido:string =
    'Número de Cuenta Inválido';
  SErrorNifNoValido:string = ' NIF No Válido';
  SErrorLetraDniIncorrecta:string =
    'Letra DNI Incorrecta. Correcta %s';
  SErrorServicioPerfilesUsuarioNoConfigurado:string =
    'No se ha configurado el servicio de perfiles de usuario.';
  SErrorCrearSeleccionarDocumentoAntesLineas:string =
    'Crea o selecciona %s antes de añadir lineas.';
  SErrorCrearSeleccionarDocumentoAntesTallas:string =
    'Crea o selecciona %s antes de activar tallas.';
  SErrorArticuloCursoSinSistemaTallas:string =
    'El articulo en curso no tiene sistema de tallas asignado.';
  SErrorAltaSeleccionarArticuloConTallas:string =
    'En alta, selecciona primero un articulo con sistema de tallas.';
  SErrorArticuloSinSistemaTallasCompra:string =
    '- Articulo sin sistema de tallas: %s';
  SErrorActivarTallasHorizontalesCompra:string =
    'No se puede activar tallas en horizontal:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Asigna un sistema de tallas o elimina la linea.';
  SErrorEncolarVentaWebservice:string =
    'No se pudo encolar la venta %s\%s para el webservice.';
  SErrorFacturaWebserviceNoExiste:string =
    'No existe la factura %s\%s para enviarla al webservice.';
  SErrorExportarNoVerifactuSinCertificado:string =
    'No se puede exportar NO VERI*FACTU legal: el modo NO VERI*FACTU ' +
    'exige firma electrónica con certificado oficial.';
  SErrorExportarNoVerifactuSinColumnasEventos:string =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_verifactu_eventos.';
  SErrorExportarNoVerifactuSinColumnasFacturacion:string =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_facturas_consolidaciones.';
  SErrorExportarNoVerifactuRegistrosSinFirma:string =
    'No se puede exportar NO VERI*FACTU legal: %d evento(s) y %d ' +
    'registro(s) de facturación no tienen firma XAdES y datos de ' +
    'certificado.';
  SErrorConexionExportarNoVerifactu:string =
    'No hay conexion para exportar NO VERI*FACTU.';
  SErrorArchivoBaseExportacionNoIndicado:string =
    'No se ha indicado archivo base de exportacion.';
  STextoTipoError:string = 'ERROR';
  STextoTipoAviso:string = 'AVISO';
  SFormatoDetalleVerificacion:string = '%s: %s';
  SErrorModoExportacionNoCoincide:string =
    '%s: ModoVerifactu no coincide con el otro fichero.';
  SErrorXmlFirmadoNoLegible:string =
    '%s: el XML firmado no se puede leer.';
  SErrorFirmaEventoRaizIncorrecta:string =
    '%s: la firma de evento debe envolver RegistroEvento.';
  SErrorEventoFirmadoNoEncontrado:string =
    '%s: falta el nodo Evento firmado.';
  SErrorFirmaFacturaRaizIncorrecta:string =
    '%s: la firma debe envolver RegistroAlta o RegistroAnulacion.';
  SErrorFirmaXadesNodoAeatIncorrecto:string =
    '%s: la firma XAdES no esta en el nodo exigido por AEAT.';
  SErrorFirmaXadesSinCertificado:string =
    '%s: falta certificado X509 en KeyInfo.';
  SErrorFirmaXadesSinSignedInfo:string =
    '%s: falta SignedInfo.';
  SErrorCanonicalizacionFirmaAeat:string =
    '%s: CanonicalizationMethod no coincide con AEAT.';
  SErrorMetodoFirmaNoRsaSha256:string =
    '%s: SignatureMethod debe ser RSA-SHA256.';
  SErrorReferenciasSignedInfo:string =
    '%s: SignedInfo debe tener referencia al documento y a ' +
    'SignedProperties.';
  SErrorReferenciaDocumentoFirmado:string =
    '%s: falta Reference URI vacio al registro firmado.';
  SErrorTransformacionFirmaEnveloped:string =
    '%s: falta transform enveloped-signature.';
  SErrorDigestRegistroNoSha256:string =
    '%s: digest del registro debe ser SHA-256.';
  SErrorReferenciaSignedProperties:string =
    '%s: falta Reference a SignedProperties.';
  SErrorCanonicalizacionSignedProperties:string =
    '%s: SignedProperties no usa canonicalizacion AEAT.';
  SErrorDigestSignedPropertiesNoSha256:string =
    '%s: digest de SignedProperties debe ser SHA-256.';
  SErrorQualifyingPropertiesXades:string =
    '%s: falta QualifyingProperties XAdES.';
  SErrorSignedPropertiesXades:string =
    '%s: falta SignedProperties XAdES.';
  SErrorSigningCertificateXades:string =
    '%s: falta SigningCertificate.';
  SErrorPoliticaFirmaAge:string =
    '%s: falta politica de firma AGE.';
  SErrorIdentificadorPoliticaAge:string =
    '%s: identificador de politica AGE incorrecto.';
  SErrorDigestPoliticaAgeNoSha1:string =
    '%s: digest de politica AGE debe ser SHA-1.';
  SErrorDigestValuePoliticaAge:string =
    '%s: DigestValue de politica AGE incorrecto.';
  SErrorUrlPoliticaAge:string =
    '%s: URL de politica AGE incorrecta.';
  SFormatoEtiquetaEvento:string = 'Evento %s';
  SErrorEventoHashPropioNoSha256:string =
    'Evento %s: HashPropio no es SHA-256 hexadecimal.';
  SAvisoEventoPrimerHashAnteriorNoCero:string =
    'Evento %s: primer HashAnterior no es cero.';
  SErrorEventoHashAnteriorNoCoincide:string =
    'Evento %s: HashAnterior no coincide con el evento anterior.';
  SErrorEventoSinRegistroXmlFirmado:string =
    'Evento %s: falta RegistroXmlFirmado.';
  SErrorEventoHuellaNoCoincide:string =
    'Evento %s: HuellaEvento no coincide con HashPropio.';
  SErrorEventoFirmaGuardadaSinFirmaXml:string =
    'Evento %s: hay FirmaXades pero el XML no contiene firma.';
  SErrorEventoSinFirmaXades:string =
    'Evento %s: falta FirmaXades legal.';
  SErrorEventoSignatureValueNoCoincide:string =
    'Evento %s: SignatureValue no coincide con FirmaXades.';
  SErrorEventoFirmaDigitalNoCoincide:string =
    'Evento %s: FirmaDigital no coincide con FirmaXades.';
  STextoRegistroFacturaIndice:string = 'registro %d';
  SFormatoEtiquetaFactura:string = 'Factura %s';
  SAvisoFacturaSinPeticionCompletaXml:string =
    'Factura %s: no incluye PeticionCompletaXml.';
  SErrorFacturaHashPeticionNoCoincide:string =
    'Factura %s: HashPeticionBase64 no coincide.';
  SErrorFacturaSinRegistroXmlFirmado:string =
    'Factura %s: falta RegistroXmlFirmado.';
  SErrorFacturaHashRegistroNoCoincide:string =
    'Factura %s: HashRegistroXmlBase64 no coincide.';
  SErrorFacturaGuardadaSinFirmaXml:string =
    'Factura %s: hay firma guardada pero el XML no firma.';
  SErrorFacturaSinFirmaDigitalXades:string =
    'Factura %s: falta FirmaDigitalXades legal.';
  SErrorFacturaSignatureValueNoCoincide:string =
    'Factura %s: SignatureValue no coincide.';
  STextoEventos:string = 'Eventos';
  STextoFacturacion:string = 'Facturacion';
  SErrorFicheroEventosNoExiste:string =
    'No existe el fichero de eventos: %s';
  SErrorFicheroEventosRaizIncorrecta:string =
    'El fichero de eventos no tiene la raiz esperada.';
  SErrorFicheroEventosVacio:string =
    'El fichero de eventos no contiene eventos.';
  SErrorFicheroFacturacionNoExiste:string =
    'No existe el fichero de facturacion: %s';
  SErrorFicheroFacturacionRaizIncorrecta:string =
    'El fichero de facturacion no tiene la raiz esperada.';
  SErrorFicheroFacturacionVacio:string =
    'El fichero de facturacion no contiene registros.';
  SErrorVerificarEventos:string =
    'No se pudo verificar eventos: %s';
  SErrorVerificarFacturacion:string =
    'No se pudo verificar facturacion: %s';
  SInfoVerificacionCorrecta:string = 'Verificacion correcta.';
  SFormatoModoActual:string = '%s (modo actual)';
  SResumenVerificacionNoVerifactu:string =
    'Modo: %s' + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Errores: %d' + sLineBreak +
    'Avisos: %d';
  SDepuracionComponenteNoTcxLabel:string =
    '%s is not TcxLabel';
  SDepuracionComponenteNoTcxTabSheet:string =
    '%s is not tcxTabSheet ';
  SDepuracionComponenteNoTcxDbCheckBox:string =
    '%s is not TcxDBCheckBox';
  SDepuracionComponenteNoTcxButton:string =
    '%s is not TcxButton';
  SDepuracionComponenteNoTcxGroupBox:string =
    '%s is not TcxGroupBox';
  SDepuracionComponenteNoTcxDbRadioGroup:string =
    '%s is not TcxDBRadioGroup';
  SDepuracionComponenteNoSpeedButton:string =
    '%s is not TSpeedButton';
  SDepuracionComponenteNoTcxRadioButton:string =
    '%s is not TcxRadioButton';
  SErrorImagenNoExiste:string = 'La imagen no existe';
  SErrorAbrirProveedorCriptografico:string =
    'No se pudo abrir el proveedor criptografico.';
  SErrorCrearHashCriptografico:string =
    'No se pudo crear el hash criptografico.';
  SErrorCalcularHash:string = 'No se pudo calcular el hash.';
  SErrorObtenerTamanoHash:string =
    'No se pudo obtener el tamano del hash.';
  SErrorObtenerValorHash:string =
    'No se pudo obtener el valor del hash.';
  SErrorOperacionCriptografica:string =
    '%s. Codigo: %s. %s';
  SErrorProveedorCertificadoSinSha256:string =
    'El proveedor criptografico del certificado no admite SHA-256 para ' +
    'firma RSA. No se puede generar XAdES rsa-sha256 con ese certificado ' +
    'tal como esta instalado. Reinstala o importa el certificado con un ' +
    'proveedor compatible con SHA-256, como Microsoft Enhanced RSA and ' +
    'AES Cryptographic Provider o Microsoft Software Key Storage ' +
    'Provider. %s';
  STextoCertificadoTodaviaNoValido:string =
    'todavia no es valido';
  STextoCertificadoCaducado:string = 'esta caducado';
  SErrorCertificadoNoVigente:string =
    'El certificado configurado %s. Vigencia: %s - %s. Seleccione un ' +
    'certificado vigente en la ficha de empresa.';
  SErrorCertificadoVigenteNoEncontrado:string =
    'No se encontro en el almacen personal de Windows un certificado ' +
    'vigente que coincida con el numero de serie o titular configurado.';
  SErrorCertificadoEmpresaNoConfigurado:string =
    'No hay un certificado configurado en la ficha de la empresa.';
  SErrorCrearHashSha256Firma:string =
    'No se pudo crear el hash SHA-256 para firmar';
  SErrorCargarDatosFirma:string =
    'No se pudieron cargar los datos a firmar';
  SErrorCalcularTamanoFirmaSha256:string =
    'No se pudo calcular el tamano de la firma SHA-256';
  SErrorFirmarSha256:string = 'No se pudo firmar con SHA-256';
  SErrorCalcularTamanoFirmaNCrypt:string =
    'NCryptSignHash fallo al calcular el tamano de la firma. Codigo: %d';
  SErrorFirmaNCrypt:string =
    'NCryptSignHash fallo al firmar. Codigo: %d';
  SErrorAbrirClavePrivadaCertificado:string =
    'No se pudo abrir la clave privada del certificado';
  SErrorXmlMalFormadoCanonicalizar:string =
    'XML mal formado al canonicalizar.';
  SErrorElementoRaizXmlNoEncontrado:string =
    'No se encontro el elemento raiz del XML.';
  SErrorNombreNodoRaizNoDeterminado:string =
    'No se pudo determinar el nombre del nodo raiz.';
  SErrorCierreAperturaRaizNoEncontrado:string =
    'No se encontro el cierre de la apertura raiz.';
  SErrorCierreNodoRaizNoEncontrado:string =
    'No se encontro el cierre del nodo raiz %s.';
  SErrorCierreNodoNoEncontrado:string =
    'No se encontro el cierre del nodo %s.';
  // Verifactu
  SErrorNifProductorEventoVerifactuInvalido:string =
    'Parámetro appVerifactuSifNif vacío o no válido: "%s".';
  SErrorEmpresaEventosVerifactuNoConfigurada:string =
    'No hay empresa configurada para registrar eventos Verifactu.';
  SErrorNifEmisorEventoNoVerifactuInvalido:string =
    'NIF de la empresa emisora vacío o no válido para firmar eventos ' +
    'NO VERI*FACTU: "%s".';
  SErrorFacturaRequisitosFiscalesNoExiste:string =
    'No existe la factura %s\%s para validar sus requisitos fiscales.';
  SErrorEmpresaSinNifEmisionFiscal:string =
    'La empresa %s no tiene un NIF válido para la emisión fiscal.';
  SErrorNifProductorVerifactuInvalido:string =
    'El parámetro appVerifactuSifNif no contiene un NIF de productor ' +
    'válido.';
  SErrorCertificadoFiscalEmpresaNoUtilizable:string =
    'La empresa %s no dispone de un certificado fiscal utilizable: %s';
  SErrorFirmaCertificadoNoVerifactuDesactivada:string =
    'El modo NO VERI*FACTU exige activar la firma con certificado en ' +
    'appVerifactuFirmaCertificado.';
  SErrorCertificadoEventosNoVerifactuNoConfigurado:string =
    'No hay certificado configurado en Empresas para firmar eventos ' +
    'NO VERI*FACTU.';
  SErrorFirmarEventoNoVerifactu:string =
    'No se pudo firmar el evento NO VERI*FACTU: %s';
  SErrorRelojEventoNoVerifactu:string =
    'No se pudo validar el reloj del evento NO VERI*FACTU: %s';
  SErrorColumnasFirmaFacturacionNoDisponibles:string =
    'Faltan columnas de firma en fza_facturas_consolidaciones. Aplique ' +
    'el script DESARROLLOS EN CURSO\verifactu_registros_firmados.sql.';
  STextoRegistroFacturacionNoVerifactu:string =
    'Registro de facturación NO VERI*FACTU';
  SErrorFirmaRegistroNoVerifactuObligatoria:string =
    'El modo NO VERI*FACTU exige firmar el registro de facturación con ' +
    'certificado oficial.';
  SErrorNifProductorSoftwareVerifactuInvalido:string =
    'Parámetro appVerifactuSifNif (NIF del productor del software) vacío ' +
    'o no válido: "%s". Rellenarlo en Parámetros de aplicación, categoría ' +
    'Verifactu.';
  SErrorFacturaExtranjeraSinNifIva:string =
    'La factura %s %s\%s a cliente extranjero requiere el NIF-IVA del ' +
    'destinatario.';
  SErrorFacturaSinNifClienteValido:string =
    'La factura %s %s\%s requiere un NIF de cliente válido y tiene "%s"';
  SErrorNifEmisorVerifactuInvalido:string =
    'NIF de la empresa emisora vacío o no válido para Verifactu: "%s". ' +
    'Revisar la ficha de la empresa (NIF de 9 caracteres, sin guiones).';
  SErrorFacturaRegistroFiscalNoEncontrada:string =
    'Factura %s\%s no encontrada para el registro fiscal';
  SAvisoQrPngNoGenerado:string =
    '(QR PNG no generado: %s) ';
  SErrorFacturaEnvioVerifactuNoEncontrada:string =
    'Factura %s\%s no encontrada para el envío Verifactu';
  SErrorRespuestaServicioInesperada:string =
    'Respuesta inesperada del servicio';
  SErrorRespuestaHttpAeat:string = 'AEAT HTTP %d: %s';
  SErrorRespuestaRegistroAeat:string = 'AEAT [%s] %s';
  SErrorEstadoEnvioAeat:string = 'EstadoEnvio: %s';
  SErrorServicioInstalacionHttp:string =
    'El servicio respondió con HTTP %d.';
  SErrorReferenciaGlobalInstalacionFaltante:string =
    'Falta la referencia global de la instalación.';
  SErrorApiKeyInstalacionFaltante:string =
    'Falta la API key de la instalación.';
  SErrorServicioJsonInvalido:string =
    'El servicio no devolvió JSON válido.';
  SErrorServicioSinNumeroInstalacion:string =
    'El servicio no devolvió NumeroInstalacion.';
  SErrorServicioSinDatosDeclaracion:string =
    'El servicio no devolvió los datos de la declaración responsable.';
  SErrorDeclaracionVersionNoSolicitada:string =
    'La declaración recibida no corresponde a la versión solicitada.';
  SErrorDeclaracionSifIncorrecto:string =
    'La declaración recibida no corresponde al SIF FZ.';
  SErrorDeclaracionDescargadaVacia:string =
    'La declaración descargada está vacía.';
  SErrorPaginaPublicaHttp:string =
    'La página pública respondió con HTTP %d.';
  SErrorDeclaracionWebserviceOtraVersion:string =
    'El webservice devolvió una declaración de otra versión.';
  SErrorDeclaracionPaginaPublicaOtraVersion:string =
    'La página pública corresponde a otra versión.';
  SErrorDeclaracionResponsableNoDisponible:string =
    'No hay una declaración responsable disponible para la versión %s. ' +
    'Webservice: %s. Caché: %s. Página pública: %s';
  SErrorEmpresaInstalacionSifNoConfigurada:string =
    'No hay empresa configurada para solicitar el número de instalación ' +
    'SIF.';
  SErrorEmpresaSinRazonSocial:string =
    'La empresa no tiene razón social.';
  SErrorNifEmpresaInstalacionInvalido:string =
    'El NIF de la empresa no es válido: "%s".';
  SErrorEmpresaSinNumeroInstalacionSif:string =
    'La empresa %s (%s) no tiene número de instalación SIF. Genéralo desde ' +
    'Archivo > Empresas.';
  SErrorNumeroInstalacionSifIncorrecto:string =
    'El número de instalación SIF de la empresa %s no corresponde al SIF ' +
    'FZ.';
  SErrorNumeroInstalacionSinVersion:string =
    'El número de instalación SIF de la empresa %s no tiene versión ' +
    'asociada. Genéralo de nuevo desde Archivo > Empresas.';
  SErrorVersionNumeroInstalacionIncorrecta:string =
    'El número de instalación SIF de la empresa %s fue generado para la ' +
    'versión %s y la versión actual es %s. Genéralo de nuevo desde ' +
    'Archivo > Empresas.';
  SInfoExportacionNoVerifactuGenerada:string =
    'Exportacion NO VERI*FACTU generada:' + sLineBreak +
    '%s' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Firmas: registros internos XAdES';
  SInfoVerificacionNoVerifactuCorrecta:string =
    'Verificacion NO VERI*FACTU correcta.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  SErrorVerificacionNoVerifactu:string =
    'Verificacion NO VERI*FACTU con errores.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  // Forms A-B
  SPreguntaAbrirSeriesAlbaranVenta:string =
    'No hay series de albaranes de venta mayor (tipo AV) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranVentaNoAbierto:string =
    'No está abierto el albarán de venta.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarAlbaranVentaSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorAlbaranVentaNoInicializado:string =
    'No esta inicializado el albaran.';
  SErrorCrearSeleccionarAlbaranAntesLineas:string =
    'Crea o selecciona un albaran antes de anadir lineas.';
  SPreguntaEliminarLineaAlbaranVenta:string =
    '¿Está seguro de que desea eliminar esta línea?';
  SErrorAlbaranVentaSinLineas:string =
    'El albarán no tiene líneas.';
  SAvisoSeleccionarLineasBorradorAlbaran:string =
    'Seleccione las líneas para crear borrador en la rejilla ' +
    '(Ctrl+click para selección múltiple).';
  SAvisoLineasAlbaranConBorrador:string =
    'Las líneas seleccionadas ya tienen borrador.';
  SPreguntaGenerarBorradorLineasAlbaran:string =
    '¿Generar borrador con %d línea(s) del albarán?';
  SInfoBorradorFacturaCreado:string =
    'Borrador creado: %s / %s';
  SErrorCrearBorradorFactura:string =
    'No se pudo crear el borrador.';
  SPreguntaGenerarBorradorTodoAlbaran:string =
    '¿Crear borrador con todas las líneas pendientes del albarán?';
  SAvisoAlbaranSinPedidoVenta:string =
    'Este albaran no procede de ningun pedido de venta.';
  SAvisoAlbaranSinBorrador:string =
    'Este albaran no tiene borrador creado.';
  SErrorProveedorNoSeleccionadoBuscarArticulos:string =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorAlbaranCompraNoAbierto:string =
    'No está abierto el albarán de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorAlbaranCompraNoInicializado:string =
    'No esta inicializado el albaran de compra.';
  STextoAlbaranCompra:string = 'un albaran';
  SPreguntaAbrirSeriesAlbaranCompra:string =
    'No hay series de albaranes de compra (tipo AB) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranCompraSinImpresionActivo:string =
    'No hay albaran de compra activo que imprimir.';
  SErrorAlbaranCompraNoActivo:string =
    'No hay albaran de compra activo.';
  SPreguntaGrabarAlbaranCompraSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorAlbaranCompraNecesarioElegirEmpresa:string =
    'Crea o selecciona un albarán de compra antes de elegir la empresa.';
  SErrorAlbaranCompraNecesarioElegirProveedor:string =
    'Crea o selecciona un albarán de compra antes de elegir el proveedor.';
  SErrorArticuloNoSeleccionadoElegirColor:string =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloSinColoresBasicosActivos:string =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SAvisoAlbaranCompraSinPedido:string =
    'Este albaran no procede de ningun pedido de compra.';
  SAvisoAlbaranCompraSinFactura:string =
    'Este albaran no tiene factura de compra creada.';
  SPreguntaEliminarLineaAlbaranCompra:string =
    'Esta seguro de que desea eliminar esta linea?';
  SErrorArticuloSinTipoVariacion:string =
    'El artículo debe tener asignado un "Tipo de variación" y estar ' +
    'guardado para poder generar SKUs.';
  SErrorPrecioTarifaNoSeleccionado:string =
    'Selecciona primero un precio de tarifa.';
  SErrorPrecioTarifaNoGuardado:string =
    'Esta fila aún no tiene precio guardado en la tarifa. Pulsa primero ' +
    '"Añadir precio" para crear el registro.';
  SAvisoRevisionArticulo:string = 'Revisión requerida: %s';
  SErrorGuardarPropiedadesArticulo:string =
    'Error al guardar propiedades: %s';
  SErrorGuardarVariacionesArticulo:string =
    'Error al guardar variaciones: %s';
  SPreguntaReconstruirStock:string =
    '¿Desea reconstruir la tabla de stock a partir de los movimientos de ' +
    'almacén? Esta operación borrará el stock actual y lo regenerará.';
  STituloReconstruirStock:string = 'Reconstruir Stock';
  SErrorReconstruirStock:string =
    'Error al reconstruir el stock: %s';
  SInfoStockReconstruido:string = 'Stock reconstruido.';
  SErrorArticuloNoSeleccionadoImprimirEtiquetas:string =
    'Seleccione primero un artículo para imprimir sus etiquetas.';
  SErrorArticuloNoSeleccionadoGenerarCodigos:string =
    'Seleccione o guarde un artículo antes de generar códigos de barras.';
  SErrorArticuloSinSkusActivosGenerarCodigos:string =
    'El artículo no tiene SKUs activos.';
  SPreguntaGenerarCodigosBarras:string =
    '¿Generar códigos de barras pendientes?' + sLineBreak + sLineBreak +
    'Para cada SKU activo:' + sLineBreak +
    '  · Si no tiene principal: se genera un EAN-13 interno (prefijo ' +
    '"%s").' + sLineBreak +
    '  · Si tiene principal pero no fila vacía: se crea una fila vacía ' +
    'para el código del fabricante (a rellenar manualmente).' + sLineBreak +
    '  · Si ya tiene ambos, se respeta.' + sLineBreak + sLineBreak +
    'Pulse Sí para continuar.';
  SInfoGeneracionCodigosBarras:string =
    'Generación finalizada.' + sLineBreak +
    '- EAN-13 internos creados: %d' + sLineBreak +
    '- Filas vacías de fabricante creadas: %d' + sLineBreak +
    '- SKUs ya completos (saltados): %d' + sLineBreak +
    '- Placeholders _FAB_ obsoletos eliminados: %d';
  SErrorArticuloNoSeleccionadoVerificarCodigos:string =
    'Seleccione o guarde un artículo antes de verificar.';
  SErrorDetalleCodigoBarrasInvalido:string =
    '  %s  (SKU %s, Tipo %s, Long %d)';
  SInfoVerificacionCodigosBarrasCorrecta:string =
    'Verificación OK.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- Pendientes (placeholder/vacío): %d';
  SAvisoVerificacionCodigosBarras:string =
    'Verificación con incidencias.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- NO válidos: %d' + sLineBreak +
    '- Pendientes: %d' + sLineBreak +
    'Códigos no válidos:%s';
  SInfoPrecargaArticuloGuardada:string = 'Precarga guardada.';
  STextoAtributoBasicoSinValor:string = '(sin valor)';
  SPreguntaCrearAtributoBasicoSku:string =
    'Este SKU todavia no tiene un atributo basico asignado para este valor.' +
    sLineBreak + sLineBreak +
    'Si       -> Crear basico GLOBAL "%s"' + sLineBreak +
    '            (compartido con otros articulos que usen ese valor)' +
    sLineBreak + sLineBreak +
    'No       -> Crear basico AD-HOC "%s"' + sLineBreak +
    '            (exclusivo de este articulo)' + sLineBreak + sLineBreak +
    'Cancelar -> No crear nada por ahora.';
  STituloCrearAtributoBasico:string =
    'Como crear el atributo basico';
  SErrorSkuColorNoSeleccionado:string =
    'Seleccione un SKU con color para activar o desactivar todos los SKU ' +
    'de ese color.';
  STextoActivarSkusColor:string = 'activar';
  STextoDesactivarSkusColor:string = 'desactivar';
  SPreguntaCambiarActivoSkusColor:string =
    'Va a %s TODOS los SKU del color "%s" de este articulo. Continuar?';
  STextoSkusColorActivados:string = 'activado';
  STextoSkusColorDesactivados:string = 'desactivado';
  SInfoSkusColorActualizados:string =
    '%d SKU del color "%s" se han %s.';
  SErrorColorPaletaBusquedaInvalido:string =
    'Indique un color de paleta válido por código, nombre o HEX (#RRGGBB).';
  // Forms C
  SErrorOperacionSinBorrador:string =
    'La operación seleccionada no tiene borrador.';
  SErrorBorradorNoCerradoFiscalmente:string =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede anular.';
  SPreguntaAnularFiscalmenteBorrador:string =
    '¿Anular fiscalmente el borrador %s\%s?';
  SPreguntaBorrarMovimientosTicketAnulado:string =
    '¿Desea borrar también los movimientos de almacén asociados al ticket ' +
    '%s\%s?' + sLineBreak +
    'Se revertirá el stock de sus líneas.';
  SInfoAnulacionVerifactuEncolada:string =
    'Anulación encolada: el hilo Verifactu la enviará en el próximo ciclo.';
  SInfoAnulacionNoVerifactuRegistrada:string =
    'Anulación registrada y firmada en NO VERI*FACTU.';
  SInfoAnulacionSinVerifactuRegistrada:string =
    'Anulación registrada en modo SIN VERIFACTU.';
  SErrorFacturarTicketRequiereSimplificado:string =
    'Solo se crea un borrador normal desde un borrador SIMPLIFICADO ' +
    '(ticket).';
  SInfoBorradorSustitucionTicketCreado:string =
    'Creado el borrador %s\%s en sustitución del ticket %s\%s en modo ' +
    'fiscal %s (F3).';
  SErrorRectificarRectificativa:string =
    'No se puede rectificar una rectificativa.';
  SPreguntaRectificarBorrador:string =
    'Seleccione cómo rectificar el borrador %s\%s.' + sLineBreak +
    'Por diferencias carga las cantidades en negativo; sustitutiva las ' +
    'carga en positivo.';
  SErrorOperacionCorreoNoEncontrada:string =
    'No se ha encontrado la operación seleccionada.';
  STituloEnviarDocumentacion:string = 'Enviar documentación';
  SSolicitudCorreoElectronico:string = 'Correo electrónico:';
  SErrorCorreoElectronicoObligatorio:string =
    'Indique una dirección de correo electrónico.';
  SErrorEnviarCorreoOperacion:string =
    'No se ha podido enviar el correo.' + sLineBreak + '%s';
  SErrorOperacionSinTicket:string =
    'Esta operación no tiene ticket asociado.';
  SPreguntaBorrarPropiedadPlantillaCompra:string =
    '¿Borrar la propiedad?';
  SPreguntaBorrarKitPlantillaCompra:string = '¿Borrar el kit?';
  SInfoIbanValidado:string = 'IBAN Validado OK';
  SErrorCabeceraSesionAntesLineas:string =
    'Crea y graba la cabecera de la sesion antes de anadir lineas.';
  SErrorSesionSinDocumentosCreados:string =
    'La sesion no tiene documentos creados.';
  SErrorMantenimientoTipoDocumentoNoDisponible:string =
    'No hay mantenimiento disponible para el tipo de documento "%s".';
  SPreguntaAbrirSeriesSesionCompra:string =
    'No hay series de sesiones de compra (tipo SE) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorLineaSesionDescargarFotosNoSeleccionada:string =
    'Selecciona o crea una linea antes de descargar fotos.';
  SErrorLineaSesionSinCodigoArticulo:string =
    'La linea activa no tiene codigo de articulo.';
  SErrorDescargarFotosArticulo:string =
    'No se pudieron descargar las fotos del articulo %s:' + sLineBreak +
    '%s';
  SInfoFotosArticuloDescargadas:string =
    'Descargadas %d foto(s) del articulo %s.';
  SErrorSesionElegirProveedorNoSeleccionada:string =
    'Crea o selecciona una sesion antes de elegir el proveedor.';
  SErrorProveedorSesionSinKits:string =
    'El proveedor de la sesion no tiene kits definidos. Se crean en ' +
    'Proveedores, pestaña Compras.';
  SErrorKitProveedorDesplegableNoSeleccionado:string =
    'Elige un kit del proveedor en el desplegable.';
  SPreguntaBorrarLineaSesionCompra:string =
    'Borrar la linea seleccionada?';
  SErrorLineaSesionAsignarFotoNoSeleccionada:string =
    'Selecciona o crea una linea antes de asignar foto.';
  SInfoFotoLineaSesionAsignada:string =
    'Foto asignada a la linea %d.';
  SErrorAsignarFotoSesion:string = 'No se pudo asignar la foto.';
  SErrorGuardarFotoSesion:string = 'Error guardando foto: %s';
  SErrorSesionYaMaterializada:string =
    'La sesion ya esta cerrada. No se puede materializar dos veces.';
  SInfoDuplicadosSesionMarcadosReusar:string =
    'Se han detectado y marcado %d linea(s) como REUSAR de codigos ' +
    'repetidos dentro de esta sesion (variantes color/SKU del mismo ' +
    'articulo). La materializacion crea el articulo una sola vez.';
  SInfoSesionMaterializadaSinDocumentos:string =
    'Sesion materializada (sin documentos).';
  SErrorSesionNoCerradaParaReversion:string =
    'La sesion no esta CERRADA. Solo se pueden revertir sesiones ' +
    'materializadas.';
  SPreguntaRevertirSesionCompra:string =
    'Se borraran los movimientos de almacen creados por esta sesion y ' +
    'volvera a BORRADOR.' + sLineBreak + sLineBreak +
    'Los articulos / SKUs / codigos de barras se conservan ' +
    '(re-materializar es idempotente).' + sLineBreak + sLineBreak +
    'Continuar?';
  SInfoSesionRevertida:string = 'Sesion revertida. Estado: BORRADOR.';
  SErrorRevertirSesionCompra:string =
    'No se pudo revertir la sesion:' + sLineBreak + '%s';
  SErrorSesionActivaImprimirNoDisponible:string =
    'No hay sesion activa que imprimir.';
  SErrorSistemasTallasSesionNoDisponibles:string =
    'No hay sistemas de tallas activos en fza_atributos_conjuntos ' +
    '(ID_VA_AC=''TAL'').';
  SErrorCambiarSistemaTallasModeloExistente:string =
    'El sistema de tallas no se puede cambiar en un modelo que ya existe: ' +
    'queda fijado al del articulo. Solo puedes anadir colores o tallas ' +
    'nuevos.';
  SErrorLineaSesionAsignarFamiliaNoSeleccionada:string =
    'Anade una linea (o ponte sobre una) para asignarle familia.';
  SErrorColoresBasicosSesionNoDisponibles:string =
    'No hay colores basicos cargados en fza_atributos_basicos para ' +
    'ID_VA=''CO''.';
implementation


end.
