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
  SPreguntaMovimientosRectificativaSustitutiva:string =
    '¿Qué desea hacer con los movimientos de almacén de la factura ' +
    'original %s\%s?' + sLineBreak + sLineBreak +
    'Eliminar originales: se revierte su stock y se generan los ' +
    'movimientos de la nueva rectificativa.' + sLineBreak +
    'Mantener originales: se conserva el stock actual y la nueva ' +
    'rectificativa no genera movimientos adicionales.';
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
  // Forms D-E
  SInfoEfectoConciliado:string = 'Efecto conciliado.';
  SErrorConciliarEfecto:string = 'No se pudo conciliar el efecto.';
  SErrorEfectoNoSeleccionado:string =
    'Selecciona un efecto en la rejilla.';
  SErrorCarteraEfectosNoAbierta:string =
    'No hay cartera de efectos abierta.';
  SErrorEfectosCompraFusionInsuficientes:string =
    'Selecciona dos o más efectos impagados.';
  SErrorEfectosVentaFusionInsuficientes:string =
    'Selecciona dos o más efectos imcobrados.';
  SPreguntaFusionarEfectos:string =
    '¿Fusionar los efectos seleccionados en un único efecto pendiente?';
  SInfoEfectosConciliados:string = 'Efectos conciliados en %s.';
  SErrorFusionarEfectos:string =
    'No se pudieron fusionar los efectos.';
  SErrorContadorSerieEmpresa:string =
    'No se pudo obtener el siguiente codigo del contador "ES" para la ' +
    'nueva serie.';
  SErrorEmpresaCrearSeriesNoSeleccionada:string =
    'Selecciona una empresa antes de crear sus series.';
  SInfoSeriesEmpresaCreadas:string =
    'Creadas %d series. Omitidas %d ya existentes.';
  SErrorEmpresaNoSeleccionada:string = 'No hay empresa seleccionada.';
  SInfoInstalacionSifEmpresaDisponible:string =
    'Número de instalación SIF disponible para %s:' + sLineBreak + '%s';
  SErrorDocumentoTrabajoNoSeleccionadoListado:string =
    'Seleccione un Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinGrabarListado:string =
    'Grabe el Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinLineasListado:string =
    'El Documento de Trabajo no tiene líneas para el listado.';
  SErrorDocumentoTrabajoNoSeleccionadoCargar:string =
    'Seleccione un Documento de Trabajo antes de cargar.';
  SErrorCargarDocumentoTrabajoNoPropietario:string =
    'Solo el propietario puede cargar articulos en el documento.';
  SErrorDocumentoTrabajoSinGrabarCargar:string =
    'Grabe el Documento de Trabajo antes de cargar.';
  SErrorDocumentoTrabajoNoSeleccionadoCompartir:string =
    'Seleccione un Documento de Trabajo antes de compartir.';
  SInfoDocumentoTrabajoCompartido:string = 'Documento compartido.';
  SInfoDocumentoTrabajoYaCompartido:string =
    'El Documento de Trabajo ya estaba compartido.';
  SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas:string =
    'Grabe el Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas:string =
    'Seleccione un Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoEnviar:string =
    'Seleccione un Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinGrabarEnviar:string =
    'Grabe el Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinLineasEnviar:string =
    'El Documento de Trabajo no tiene lineas que enviar.';
  SErrorContadorAlbaranDocumentoTrabajo:string =
    'El contador de albaranes no ha devuelto numero para la serie %s.';
  SInfoAlbaranDocumentoTrabajoCreado:string =
    'Albarán de venta %s/%s creado ABIERTO con %d líneas.' + sLineBreak +
    'Asigna cliente, tarifa y precios en el Mto de albaranes.';
  SErrorVentaTpvNoAbiertaDocumentoTrabajo:string =
    'La venta TPV no está abierta.' + sLineBreak +
    'Abre Caja > Ventas y repite "Enviar a... > Venta TPV" para volcar ' +
    'los SKUs en la operación en curso.';
  SInfoLineasDocumentoTrabajoVolcadasTpv:string =
    '%d líneas volcadas a la venta TPV.';
  SAvisoLineasDocumentoTrabajoNoVolcadasTpv:string =
    '%d líneas volcadas a la venta TPV; %d no se han podido resolver ' +
    '(artículo inexistente o descatalogado).';
  SErrorContadorInventarioDocumentoTrabajo:string =
    'El contador de inventarios no ha devuelto numero para la serie %s.';
  SInfoInventarioDocumentoTrabajoCreado:string =
    'Inventario %s/%s creado en almacén %s con %d líneas del documento.' +
    sLineBreak +
    'Abre Inventarios y usa "Recalcular teórico/PMP" para fijar teóricos ' +
    'y costes.';
  SInfoCambioTarifasDocumentoTrabajoCreado:string =
    'Sesión de cambio de tarifas %d creada en BORRADOR con los artículos ' +
    'del documento.' + sLineBreak +
    'Abre "Cambios de tarifa" para elegir tarifas, regla de cálculo y ' +
    'aplicar.';
  SPreguntaAbrirSeriesDevolucionCompra:string =
    'No hay series de devoluciones a proveedor (tipo DC) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorLineaColorDevolucionNoEncontrada:string =
    'No se ha encontrado ninguna linea de ese color.';
  SErrorDevolucionCompraSinImpresionActiva:string =
    'No hay devolucion de compra activo que imprimir.';
  SErrorDevolucionCompraNoActiva:string =
    'No hay devolucion de compra activo.';
  SErrorProveedorDevolucionFilaNoSeleccionado:string =
    'Selecciona un proveedor antes de devolver la fila.';
  SErrorAlmacenDevolucionFilaNoSeleccionado:string =
    'Selecciona el almacen de salida antes de devolver el stock.';
  SErrorFilaDevolucionStockNoSeleccionada:string =
    'Selecciona una fila antes de devolver su stock.';
  SErrorArticuloDevolucionFilaNoSeleccionado:string =
    'Selecciona un articulo en la fila antes de devolver su stock.';
  SErrorColorDevolucionFilaNoSeleccionado:string =
    'Selecciona el color de la fila antes de devolver su stock.';
  SErrorStockDevolucionFilaNoDisponible:string =
    'No hay stock positivo para el articulo/color de la fila en el almacen ' +
    'de salida.';
  SPreguntaPrepararStockFilaDevolucion:string =
    'Esto sustituira las cantidades de la fila actual por el stock positivo ' +
    'de ese articulo/color en el almacen de salida. Continuar?';
  SInfoStockFilaDevolucionPreparado:string =
    'Se han preparado %d lineas de la fila con el stock actual.';
  SPreguntaGrabarDevolucionCompraSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion:string =
    'Selecciona un proveedor antes de buscar articulos.';
  SErrorDevolucionCompraNoAbierta:string =
    'No está abierta la devolución de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusDevolucion:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorDevolucionCompraElegirEmpresaNoSeleccionada:string =
    'Crea o selecciona una devolución de compra antes de elegir la empresa.';
  SErrorDevolucionCompraElegirProveedorNoSeleccionada:string =
    'Crea o selecciona una devolución de compra antes de elegir el ' +
    'proveedor.';
  SPreguntaEliminarLineaDevolucionCompra:string =
    'Esta seguro de que desea eliminar esta linea?';
  // Forms F
  SErrorFotoArticuloNoActivoDescargar:string =
    'No hay articulo activo para descargar fotos.';
  SErrorFotoArticuloNoActivo:string = 'No hay artículo activo.';
  SErrorGuardarFotoArticulo:string =
    'No se pudo guardar la foto: %s';
  SErrorFotoSkuNoActivo:string =
    'No hay SKU activo. Usa "Cambiar foto del artículo".';
  SErrorNivelAtributosFotoNoSeleccionado:string =
    'No hay nivel de atributos seleccionado en el combo.';
  SPreguntaEliminarFotoActual:string = '¿Eliminar la foto actual?';
  SAvisoLimiteRegistrosFacturaSimplificada:string =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorBorradorVentaMayorNoSeleccionado:string =
    'Seleccione un borrador de venta mayor.';
  SErrorGuardarAntesEmitirEdoc:string =
    'Guarde los cambios antes de emitir el eDoc.';
  SErrorPersonaFisicaEdocSinDatos:string =
    'El cliente tiene NIF/NIE de persona física.' + sLineBreak +
    'Rellene nombre y apellidos en Parámetros eDoc antes de emitir.';
  SInfoEdocEmitido:string =
    'eDoc emitido correctamente:' + sLineBreak + '%s';
  SPreguntaAbrirSeriesFacturaCompra:string =
    'No hay series de facturas de compra (tipo FP) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra:string =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorFacturaCompraNoAbierta:string =
    'No está abierta la factura de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorFacturaCompraSinImpresionActiva:string =
    'No hay factura de compra activa que imprimir.';
  SAvisoEtiquetasBorradorCompraPendientes:string =
    'Etiquetas de borrador de compra: pendiente (hito de informes).';
  SPreguntaGrabarFacturaCompraSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorFacturaCompraNoInicializada:string =
    'No esta inicializada la factura de compra.';
  SErrorFacturaCompraElegirProveedorNoSeleccionada:string =
    'Crea o selecciona una factura de compra antes de elegir el proveedor.';
  SInfoGeneracionEfectosPagoCancelada:string =
    'Generación de efectos cancelada.';
  SInfoEfectosPagoGenerados:string =
    'Generados %d efecto(s) de pago.';
  SAvisoEfectosPagoNoGenerados:string =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga ya efectos pagados o remesados.';
  SErrorGenerarEfectosPagoSinBorrador:string =
    'No hay borrador activo (o hubo un error al generar).';
  SErrorEfectoCompraNoSeleccionado:string =
    'Selecciona un efecto en la rejilla de la pestana Efectos.';
  SPreguntaEliminarLineaFacturaCompra:string =
    'Esta seguro de que desea eliminar esta linea?';
  SInfoImpresionEfectosCobroEnRemesas:string =
    'La impresión de efectos de cobro se gestiona desde Remesas de Cobro.';
  SPreguntaReemplazarCobros:string =
    'Hay %s creados, ¿desea reemplazarlos?';
  STituloMensajeAdvertencia:string = 'Mensaje Advertencia';
  SInfoGeneracionCobrosCancelada:string =
    'Generación de %s cancelada.';
  SInfoEfectosCobroGenerados:string =
    'Generados %d efecto(s) de cobro.';
  SAvisoEfectosCobroNoGenerados:string =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga efectos cobrados o remesados.';
  SErrorGenerarEfectosCobroSinBorrador:string =
    'No hay borrador activo o no se pudieron generar efectos.';
  SAvisoBorradorPendienteImpresionFiscal:string =
    'El borrador está pendiente: use el botón Consolidar antes de ' +
    'imprimirlo en este modo fiscal.';
  SErrorGuardarFacturaAntesImprimir:string =
    'No se pudo guardar la factura antes de imprimir: %s';
  SInfoEfectoMarcadoDevuelto:string =
    'Efecto marcado como devuelto.';
  SErrorMarcarEfectoDevuelto:string =
    'No se pudo marcar el efecto como devuelto.';
  SInfoEfectoMarcadoPendiente:string =
    'Efecto marcado como pendiente.';
  SErrorMarcarEfectoPendiente:string =
    'No se pudo marcar el efecto como pendiente.';
  SErrorEfectoSinImportePendiente:string =
    'El efecto seleccionado no tiene importe pendiente.';
  SErrorTarifaSeleccionadaNoEncontrada:string =
    'No se encontró la tarifa seleccionada';
  SErrorBorradorListaNoSeleccionado:string =
    'Seleccione un borrador en la lista.';
  SErrorBorradorNoCerradoAccionFiscal:string =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede %s.';
  SPreguntaAccionFiscalBorrador:string =
    '¿%s fiscalmente el borrador %s\%s?';
  SInfoAccionFiscalEncolada:string =
    '%s encolada: el hilo Verifactu la enviará en el próximo ciclo. Puede ' +
    'seguirla en la columna "Cola Verifactu" y en Verifactu - Cola de ' +
    'Envíos.';
  SInfoAccionFiscalNoVerifactu:string =
    '%s registrada y firmada en NO VERI*FACTU.';
  SInfoAccionFiscalSinVerifactu:string =
    '%s registrada en modo SIN VERIFACTU.';
  SErrorBorradorYaLanzadoFiscalmente:string =
    'El borrador %s\%s ya se lanzó fiscalmente (fase %s).';
  SErrorBorradorSinLineasLanzar:string =
    'El borrador no tiene líneas: no se puede lanzar.';
  SErrorBorradorNormalSinNif:string =
    'Un borrador NORMAL necesita el NIF del cliente para el registro ' +
    'fiscal. Complete los datos del cliente.';
  SPreguntaLanzarBorradorFiscal:string =
    '¿Lanzar fiscalmente el borrador %s\%s? Dejará de estar en borrador y ' +
    'de ser editable.';
  SInfoBorradorVerifactuPendiente:string =
    'Borrador %s\%s en VERIFACTU_PENDIENTE: el QR ya puede imprimirse y ' +
    'el envío a la AEAT queda en la cola Verifactu.';
  SInfoBorradorNoVerifactuRegistrado:string =
    'Borrador %s\%s registrado y firmado en NO VERI*FACTU.';
  SInfoBorradorSinVerifactuEmitido:string =
    'Borrador %s\%s emitido en modo SIN VERIFACTU.';
  SErrorBorradorConsolidadoNoReabrible:string =
    'El borrador %s\%s ya está consolidado en la AEAT: no puede volver a ' +
    'borrador. Use Anular fiscal o emita una rectificativa.';
  SInfoBorradorYaEnBorrador:string =
    'El borrador ya está en BORRADOR.';
  SPreguntaDevolverBorrador:string =
    '¿Devolver a BORRADOR el documento %s\%s y anular su envío pendiente ' +
    'a la AEAT?';
  SErrorAltaAeatAceptadaNoReabrible:string =
    'El alta ya fue aceptada por la AEAT: no se puede volver a borrador. ' +
    'Use Anular fiscal o emita una rectificativa.';
  SErrorBorradorEnProcesoNoReabrible:string =
    'El hilo Verifactu está enviando este borrador ahora mismo. Espere unos ' +
    'segundos y vuelva a intentarlo.';
  SInfoBorradorReabierto:string =
    'Borrador %s\%s de nuevo en BORRADOR. Corrija los datos (si el error ' +
    'es de la empresa, arréglelo en Empresas y use "Dar de Alta o ' +
    'Actualizar Empresa" en la pestaña Datos Empresa Emisora para ' +
    'refrescar la copia del borrador) y pulse Consolidar para relanzarla.';
  SPreguntaGrabarFacturaVentaSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorCompletarDatosBorrador:string =
    'Debe completar los datos del borrador: %s';
  // Forms G-I
  SErrorContadorAutomaticoBusqueda:string =
    'No se pudo obtener el contador automático.';
  SInfoRegistroBusquedaCreado:string =
    'Registro %s creado correctamente.';
  SErrorInsertarRegistroBusqueda:string =
    'Error al insertar (se ha cancelado la operación): %s';
  SInfoTextoNoEncontrado:string = 'Texto no encontrado.';
  STituloBusquedaGlobal:string = 'Búsqueda Global';
  SSolicitudTextoBusquedaGlobal:string =
    'Introduce el texto a buscar en todos los procesos:';
  SInfoProcesosBusquedaNoEncontrados:string =
    'No se encontraron procesos que contengan: %s';
  SPreguntaIgnorarErrorScript:string =
    'Ocurrió un error ejecutando el script.' + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorMetadatoSinScript:string =
    'No hay estructura o script disponible para este metadato.';
  SErrorDatosCopiarNoDisponibles:string = 'No hay datos que copiar.';
  SPreguntaCopiarFilasPortapapeles:string =
    'Vas a copiar %d filas al portapapeles. ¿Continuar?';
  SPreguntaIgnorarErrorComandoScript:string =
    'Ocurrió un error ejecutando %s.' + sLineBreak +
    'Detalle: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorEjecucionProceso:string = 'Error en ejecución: %s';
  SErrorComandoSqlProceso:string = 'Error en comando SQL: %s';
  SErrorConexionTrabajoNoDisponible:string =
    'No está disponible la conexión de trabajo.';
  SInfoDatosGuardados:string = 'Datos guardados correctamente';
  SErrorGrabarDatos:string = 'Error al grabar: %s';
  SPreguntaGrabarCambiosPendientes:string =
    'Hay datos no grabados. ¿Desea grabar los cambios?';
  STituloMensajeAdvertenciaGen:string = 'Mensaje de Advertencia';
  SInfoCambiosGrabados:string = 'Cambios grabados';
  SInfoCambiosCancelados:string = 'Cambios revertidos/cancelados';
  SErrorConexionPrincipalNoDisponible:string =
    'No está disponible la conexión principal.';
  SErrorPermisoInsertarRegistro:string =
    'No tienes permiso para insertar registros en esta pantalla.';
  SErrorPermisoModificarRegistro:string =
    'No tienes permiso para modificar registros en esta pantalla.';
  SErrorPermisoGuardarRegistro:string =
    'No tienes permiso para guardar este registro.';
  SErrorPermisoBorrarRegistro:string =
    'No tienes permiso para borrar registros en esta pantalla.';
  SPreguntaEliminarRegistro:string =
    '¿Estás seguro de que deseas eliminar este registro?';
  STituloConfirmarEliminacion:string = 'Confirmar eliminación';
  SPreguntaEliminarRegistroConHijos:string =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo: se rompera la relacion con' + sLineBreak +
    'los registros hijos.' + sLineBreak + sLineBreak +
    '¿Deseas eliminarlo de todas formas?';
  SAvisoDesactivarRegistroConHijos:string =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo. Te sugerimos DESACTIVARLO' + sLineBreak +
    'para conservar el historico.';
  SAvisoDesactivarRegistroSinHijos:string =
    'Este registro puede DESACTIVARSE en lugar de eliminarse' + sLineBreak +
    'para conservar el historico.';
  SDescripcionHijosGenerica:string = 'registros asociados';
  STextoOpcionesBorradoRegistro:string =
    sLineBreak + sLineBreak +
    'Sí       = Desactivar (recomendado)' + sLineBreak +
    'No       = Eliminar definitivamente' + sLineBreak +
    'Cancelar = No hacer nada';
  SErrorFiltroSinCondiciones:string =
    'El filtro seleccionado no tiene condiciones guardadas.';
  SErrorFiltroActualVacio:string =
    'No hay ningun filtro aplicado en la lista para guardar.';
  SPreguntaSobrescribirFiltro:string =
    'Ya existe un filtro propio con ese nombre. Desea sobrescribirlo?';
  STituloSobrescribirFiltro:string = 'Sobrescribir filtro';
  SInfoFiltroSobrescrito:string = 'Filtro sobrescrito correctamente.';
  SInfoFiltroGuardado:string = 'Filtro guardado correctamente.';
  SErrorArticuloInventarioNoExiste:string = 'El artículo no existe';
  SErrorLineasInventarioNoAbiertas:string =
    'No hay líneas de inventario abiertas.';
  SErrorLineaInventarioNoEditable:string =
    'No se ha podido poner la línea en edición.';
  SErrorArticuloInventarioNoEncontrado:string =
    'No se ha encontrado ningún artículo con ese código, SKU o código de ' +
    'barras';
  SErrorArticuloInventarioTipoSinStock:string =
    'El artículo %s es de tipo "%s" y no controla stock; no se puede ' +
    'inventariar.';
  SErrorArticuloInventarioAtributosSinSku:string =
    'El artículo %s tiene atributos. En modo SKU introduce un SKU completo ' +
    'o activa "Ver atributos en columnas".';
  SInfoLineasCsvInventarioLeidas:string =
    'Leidas %d lineas del CSV.';
  SErrorMigracionRecuentoInventariosNoAplicada:string =
    'La base de datos no tiene aplicada la migración de recuento remoto de ' +
    'inventarios. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\recuento_inventarios_factuzam.sql.';
  SErrorGrabarCabeceraInventarioAutomaticamente:string =
    'No se ha podido grabar automaticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestana Cabecera y vuelve a intentar anadir ' +
    'la linea.';
  SErrorGrabarCabeceraInventarioAutomaticamenteDetalle:string =
    'No se ha podido grabar automáticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestaña Cabecera y vuelve a entrar en ' +
    'Detalle.';
  SErrorInventarioNoAbiertoEditar:string =
    'El inventario no está ABIERTO. No se puede editar.';
  SPreguntaRecalcularInventario:string =
    'Esto recalculará las cantidades teóricas y precios medios de todas ' +
    'las líneas a partir del Kardex actual.' + sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRecalculoInventario:string =
    'Recálculo completado correctamente.';
  SPreguntaAplicarInventario:string =
    'Esto aplicará el inventario y generará movimientos de regularización' +
    sLineBreak +
    'en el Kardex. La operación NO se podrá deshacer fácilmente.' +
    sLineBreak + sLineBreak +
    '¿Aplicar el inventario?';
  SErrorAplicarInventario:string =
    'No se puede aplicar el inventario:' + sLineBreak + '%s';
  SErrorAplicacionInventario:string =
    'Error al aplicar el inventario:' + sLineBreak + '%s';
  SErrorRefrescarInventarioAplicado:string =
    'El inventario se aplico, pero fallo el refresco:' + sLineBreak + '%s';
  SInfoInventarioAplicado:string = 'Inventario aplicado correctamente.';
  SErrorInventarioNoSeleccionadoAnadirLineas:string =
    'No hay ningún inventario seleccionado todavía. Crea uno o selecciónalo ' +
    'en la lista antes de añadir líneas.';
  SErrorAnadirLineasInventarioEstado:string =
    'No se pueden añadir líneas: el inventario está en estado "%s" (solo ' +
    'se pueden editar inventarios ABIERTOS).';
  SErrorLineaInventarioNoSeleccionadaParaSkus:string =
    'Sitúate sobre una línea con artículo para añadir sus SKUs.';
  SErrorLineaInventarioSinArticulo:string =
    'La línea actual no tiene artículo asignado.';
  SErrorAnadirSkusInventario:string =
    'Error al añadir SKUs: %s';
  SInfoSinSkusAnadidosInventario:string =
    'No se ha añadido ningún SKU. El artículo %s no tiene movimientos en ' +
    'este almacén o todos sus SKUs ya están en el inventario.';
  SInfoSkusAnadidosInventario:string =
    'Añadidos %d SKUs del artículo %s.';
  SPreguntaEliminarLineaInventario:string =
    '¿Eliminar la línea seleccionada?';
  SErrorEliminarRegularizacionInventarioEstado:string =
    'Solo puedes eliminar la regularización de un inventario APLICADO.';
  SPreguntaEliminarRegularizacionInventario:string =
    'Esto BORRARÁ todos los movimientos generados por este inventario,' +
    sLineBreak +
    'devolverá el inventario al estado ABIERTO y recalculará el Kardex.' +
    sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRegularizacionInventarioEliminada:string =
    'Regularización eliminada. El inventario vuelve a estar ABIERTO.';
  SErrorInventarioNoActivo:string = 'No hay inventario activo.';
  SErrorInventarioDebeEstarAbierto:string =
    'El inventario debe estar ABIERTO.';
  SErrorFamiliaInventarioNoSeleccionada:string =
    'Selecciona primero una familia.';
  SPreguntaCargarFamiliaInventario:string =
    '¿Cargar todos los SKUs de la familia "%s" al inventario?';
  SErrorProveedorInventarioNoSeleccionado:string =
    'Selecciona primero un proveedor.';
  SPreguntaCargarProveedorInventario:string =
    '¿Cargar todos los SKUs del proveedor "%s" al inventario?';
  SPreguntaCompletarInventario:string =
    'Esto añadirá al inventario todos los SKUs con stock que NO ' +
    sLineBreak +
    'estén ya en el inventario, con cantidad física = 0.' + sLineBreak +
    sLineBreak +
    'Útil para detectar artículos que faltó contar.' + sLineBreak +
    sLineBreak + '¿Continuar?';
  SPreguntaCargarTodoInventario:string =
    'Esto cargará TODOS los SKUs con stock al inventario, ' + sLineBreak +
    'con cantidad física = teórica. ¿Continuar?';
  SErrorInventarioNoSeleccionado:string =
    'Selecciona primero un inventario.';
  SPreguntaGuardarInventarioEnEdicion:string =
    'El inventario esta en edicion. Guardar antes?';
  SPreguntaRecalcularTrasCargarBloqueInventario:string =
    'Se anadieron %d lineas (%d articulos distintos).' + sLineBreak +
    '?Quieres calcular ahora las cantidades teoricas y PMP?';
  SErrorArchivoImportacionInventarioNoExiste:string =
    'El archivo no existe.';
  SErrorImportacionInventarioSinDatos:string =
    'No se encontraron datos para importar.';
  SInfoImportacionInventario:string =
    '%s' + sLineBreak + '%d actualizados, %d nuevos insertados.';
  SErrorEnviarRecuentoInventarioNoAbierto:string =
    'Solo se puede enviar a recuento un inventario ABIERTO.';
  SPreguntaEnviarRecuentoInventario:string =
    'Se enviará este inventario al servidor para recontarlo con la app. ' +
    '¿Continuar?';
  SInfoInventarioEnviadoRecuento:string =
    'Inventario enviado a recuento (referencia %d).';
  SErrorEnviarRecuentoInventario:string = 'No se pudo enviar: %s';
  SErrorInventarioNoEnviadoRecuento:string =
    'Este inventario no se ha enviado a recuento todavía.';
  SErrorRecogerRecuentoInventarioNoAbierto:string =
    'Solo se puede recoger sobre un inventario ABIERTO.';
  SInfoRecuentoInventarioRecogido:string =
    'Recuento recogido: %d lecturas, %d SKUs. Revisa las físicas y APLICA ' +
    'cuando quieras.';
  SErrorRecogerRecuentoInventario:string = 'No se pudo recoger: %s';
  // Forms J-P
  SAvisoLimiteRegistrosMovimientosAlmacen:string =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SPreguntaAbrirSeriesPedidoVenta:string =
    'No hay series de pedidos de venta mayor (tipo PE) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoVentaNoAbierto:string =
    'No está abierto el pedido de venta.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarPedidoVentaSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorClienteNoSeleccionadoPedidoVenta:string =
    'Debe seleccionar un cliente antes de añadir líneas.';
  SErrorClientePedidoVentaNoExiste:string =
    'El cliente %s no existe. Seleccione un cliente válido antes de añadir ' +
    'líneas.';
  SErrorPedidoVentaNoInicializado:string =
    'No esta inicializado el pedido.';
  SErrorCrearSeleccionarPedidoAntesLineas:string =
    'Crea o selecciona un pedido antes de anadir lineas.';
  SPreguntaEliminarLineaPedidoVentaConTallas:string =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SPreguntaEliminarLineaPedidoVenta:string =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaMarcarLineasPendientesAlbaranar:string =
    'Marcar todas las líneas pendientes para albaranar?';
  SErrorPedidoVentaSinLineas:string = 'El pedido no tiene líneas';
  SPreguntaCrearAlbaranPedidoVentaSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado y no ' +
    'moverán stock. ¿Crear el albarán de todas formas?';
  SErrorPedidoVentaSinCantidadAlbaranar:string =
    'No hay líneas con cantidad a albaranar para crear el albarán.';
  SErrorAnadirAlbaranDesdePedidoVenta:string =
    'No se pudo anadir al albaran.';
  SErrorCrearAlbaranDesdePedidoVenta:string =
    'No se pudo crear el albaran.';
  SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra:string =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorPedidoCompraNoAbierto:string =
    'No está abierto el pedido de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra:string =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorPedidoCompraNoInicializado:string =
    'No esta inicializado el pedido de compra.';
  STextoPedidoCompra:string = 'un pedido';
  SErrorExpandirRecibidosNoActivo:string =
    'Activa "Expandir recibidos" antes de usar este atajo.';
  SInfoTallasPendientesRecibirNoDisponibles:string =
    'No hay tallas pendientes de recibir en la fila activa.';
  SInfoPedidoCompraSinPendientesRecibir:string =
    'No hay nada pendiente de recibir en el pedido.';
  SPreguntaGrabarPedidoCompraSinSku:string =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorPedidoCompraNecesarioElegirEmpresa:string =
    'Crea o selecciona un pedido de compra antes de elegir la empresa.';
  SErrorPedidoCompraNecesarioElegirProveedor:string =
    'Crea o selecciona un pedido de compra antes de elegir el proveedor.';
  SErrorTallasHorizontalesNecesariasElegirColor:string =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorArticuloNoSeleccionadoElegirColorPedidoCompra:string =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloPedidoCompraSinColoresBasicos:string =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SPreguntaEliminarLineaPedidoCompra:string =
    'Esta seguro de que desea eliminar esta linea?';
  SPreguntaAbrirSeriesPedidoCompra:string =
    'No hay series de pedidos de compra (tipo PC) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoCompraNoActivo:string =
    'No hay pedido de compra activo.';
  SErrorPedidoCompraNoActivoCrearAlbaran:string =
    'No hay pedido activo del que crear albaran.';
  SErrorCrearAlbaranDesdePedidoCompra:string =
    'Error al crear el albaran: %s';
  SErrorNodoPermisosNoSeleccionado:string =
    'Selecciona primero un nodo del arbol.';
  SErrorOrigenDestinoPermisosNoSeleccionados:string =
    'Selecciona un origen y un destino.';
  SErrorOrigenDestinoPermisosIguales:string =
    'El origen y el destino no pueden ser el mismo.';
  SInfoModoReemplazarPermisos:string =
    'Se reemplazaran todos los permisos del destino.';
  SInfoModoCombinarPermisos:string =
    'Se agregaran o actualizaran los permisos en el destino.';
  SInfoAlcancePermisosMenu:string =
    'Alcance: solo permisos de menu.';
  SInfoAlcanceTodosPermisos:string =
    'Alcance: todos los permisos.';
  SPreguntaCopiarPermisos:string =
    'Copiar permisos de "%s" a "%s"?' + sLineBreak +
    '%s' + sLineBreak + '%s';
  SInfoPermisosCopiados:string =
    '%d permisos copiados de "%s" a "%s".';
  SPreguntaBorrarKitProveedor:string =
    '¿Borrar el kit seleccionado y todas sus tallas?';
  // Forms Q-Z
  SErrorRemesaCompraNoSeleccionada:string = 'Selecciona una remesa.';
  SErrorEliminarRemesaCompraConCargo:string =
    'No se puede eliminar una remesa con cargo realizado.';
  SPreguntaEliminarRemesaCompra:string =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaCompraEliminada:string = 'Remesa eliminada.';
  SErrorEliminarRemesaCompra:string =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaCompraConCargo:string =
    'No se pueden añadir efectos a una remesa con cargo realizado.';
  SErrorEfectosRemesaCompraNoCargados:string =
    'No hay efectos cargados.';
  SErrorEfectoRemesaCompraNoSeleccionado:string =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaCompraConCargo:string =
    'No se pueden quitar efectos de una remesa con cargo realizado.';
  SPreguntaQuitarEfectoRemesaCompra:string =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaCompraQuitado:string =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaCompra:string =
    'No se pudo quitar el efecto.';
  SErrorBancoPagoRemesaNoAsignado:string =
    'Asigna primero el banco de pago de la remesa.';
  SErrorEfectoRemesaCompraSinPendiente:string =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaCompra:string =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaCompraConciliado:string = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaCompra:string =
    'No se pudo conciliar el efecto.';
  SErrorRemesaCompraSinImportePendiente:string =
    'La remesa no tiene importe pendiente.';
  STextoRemesaCompraPendiente:string = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaCompraConciliados:string =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaCompra:string =
    'No se pudo conciliar la remesa.';
  SErrorBancoPagoNoSeleccionado:string =
    'Selecciona un banco de pago.';
  SInfoBancoPagoRemesaAsignado:string =
    'Banco de pago asignado.';
  SErrorAsignarBancoPagoRemesa:string =
    'No se pudo asignar el banco de pago.';
  STituloFechaCargoRemesa:string = 'Fecha de cargo';
  SSolicitudFechaCargoRemesa:string = 'Fecha de cargo:';
  SInfoFechaCargoRemesaActualizada:string =
    'Fecha de cargo actualizada.';
  SErrorActualizarFechaCargoRemesa:string =
    'No se pudo actualizar la fecha de cargo.';
  SErrorFechaCargoRemesaNoValida:string = 'Fecha no válida.';
  SErrorEliminarRemesaVentaConCobro:string =
    'No se puede eliminar una remesa con cobro realizado.';
  SPreguntaEliminarRemesaVenta:string =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaVentaEliminada:string = 'Remesa eliminada.';
  SErrorEliminarRemesaVenta:string =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaVentaConCobro:string =
    'No se pueden añadir efectos a una remesa con cobro realizado.';
  SErrorEfectosRemesaVentaNoCargados:string =
    'No hay efectos cargados.';
  SErrorEfectoRemesaVentaNoSeleccionado:string =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaVentaConCobro:string =
    'No se pueden quitar efectos de una remesa con cobro realizado.';
  SPreguntaQuitarEfectoRemesaVenta:string =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaVentaQuitado:string =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaVenta:string =
    'No se pudo quitar el efecto.';
  SErrorBancoCobroRemesaNoAsignado:string =
    'Asigna primero el banco de cobro de la remesa.';
  SErrorEfectoRemesaVentaSinPendiente:string =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaVenta:string =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaVentaConciliado:string = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaVenta:string =
    'No se pudo conciliar el efecto.';
  SErrorRemesaVentaSinImportePendiente:string =
    'La remesa no tiene importe pendiente.';
  STextoRemesaVentaPendiente:string = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaVentaConciliados:string =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaVenta:string =
    'No se pudo conciliar la remesa.';
  SErrorBancoCobroNoSeleccionado:string =
    'Selecciona un banco de cobro.';
  SInfoBancoCobroRemesaAsignado:string =
    'Banco de cobro asignado.';
  SErrorAsignarBancoCobroRemesa:string =
    'No se pudo asignar el banco de cobro.';
  STituloFechaCobroRemesa:string = 'Fecha de cobro';
  SSolicitudFechaCobroRemesa:string = 'Fecha de cobro:';
  SInfoFechaCobroRemesaActualizada:string =
    'Fecha de cobro actualizada.';
  SErrorActualizarFechaCobroRemesa:string =
    'No se pudo actualizar la fecha de cobro.';
  SErrorFechaCobroRemesaNoValida:string = 'Fecha no válida.';
  SInfoOrdenSepaRemesaVentaGenerada:string =
    'Orden SEPA generada con %d cobro(s).';
  SErrorGenerarOrdenSepaRemesaVenta:string =
    'No se pudo generar la orden SEPA: %s';
  SErrorCodigoBarrasStockNoEncontrado:string =
    'Código de barras no encontrado: %s';
  SErrorEntradaStockNoEncontrada:string =
    'No se encontró "%s" como artículo, SKU, código de barras ni referencia ' +
    'de proveedor.';
  SErrorSkuCeldaStockNoEncontrado:string =
    'No se ha encontrado un SKU activo para la celda seleccionada.';
  SErrorCeldaStockVariosSkus:string =
    'La celda seleccionada coincide con varios SKUs. Acote color, talla o ' +
    'almacen antes de agregarla.';
  SErrorArticuloStockNoSeleccionadoOperaciones:string =
    'Seleccione primero un artículo.';
  SErrorCeldaTallaStockNoSeleccionada:string =
    'Seleccione una celda de talla.';
  SErrorColumnaTallaStockNoSeleccionada:string =
    'Seleccione una columna de talla.';
  SErrorFilaStockNoIdentificada:string =
    'No se ha podido identificar la fila seleccionada.';
  SErrorColorStockNoUnico:string =
    'Seleccione un único color o cambie a la vista Por colores.';
  SErrorTallaStockVariosSkus:string =
    'La talla seleccionada corresponde a varios SKU. Seleccione un único ' +
    'color o use la vista Por colores.';
  STituloOperacionesCajaStock:string = 'Operaciones de caja';
  SErrorArticuloStockNoSeleccionadoDocumento:string =
    'Seleccione primero un articulo.';
  SErrorEstadoStockNoEsExistencias:string =
    'Cambie el estado a Existencias para agregar stock disponible.';
  SErrorCeldaStockNoSeleccionada:string =
    'Seleccione una celda de stock.';
  SErrorCeldaCantidadStockNoSeleccionada:string =
    'Seleccione una celda de cantidad.';
  SErrorFilaExistenciasStockNoSeleccionada:string =
    'Seleccione la fila de Existencias para agregar stock disponible.';
  SErrorColumnaStockDocumentoNoSeleccionada:string =
    'Seleccione una columna de talla o una columna Total sin tallas.';
  SErrorGrupoFilaStockNoLeido:string =
    'No se ha podido leer el grupo de la fila.';
  SErrorAlmacenStockNoUnico:string =
    'Seleccione un solo almacen para agregar una unidad concreta.';
  SErrorColorStockUnidadNoUnico:string =
    'Seleccione un solo color para agregar una unidad concreta.';
  STituloConsultaStock:string = 'Consulta de stock';
  SErrorArticuloStockNoSeleccionadoFotos:string =
    'Seleccione primero un artículo.';
  SInfoArticulosRelacionadosStockNoDisponibles:string =
    'No hay otros artículos con stock para este filtrado.';
  SErrorTarifaNoSeleccionada:string =
    'Selecciona primero una tarifa.';
  SPreguntaGuardarTarifaAntesContinuar:string =
    'La tarifa actual esta en edicion. Guardar antes de continuar?';
  SErrorSesionTarifaNoSeleccionada:string =
    'Selecciona o crea primero una sesion.';
  SInfoLineasSesionTarifaRecalculadas:string =
    '%d lineas recalculadas.';
  SErrorCalcularSesionTarifa:string =
    'No se pudo calcular la sesion: %s';
  SPreguntaAplicarSesionTarifa:string =
    '%d lineas recalculadas. Aplicar las lineas marcadas a la tarifa ' +
    'destino?';
  SErrorAplicarSesionTarifa:string =
    'No se pudo aplicar la sesion: %s';
  SInfoLineasSesionTarifaAplicadas:string =
    '%d lineas aplicadas.';
  // Modals A-F
  SPreguntaLimpiarFiltrosAddBlock:string =
    'Limpiar todos los filtros?';
  SErrorAlmacenesSoloStockAddBlock:string =
    'Has activado "Solo con stock" pero no hay almacenes seleccionados en ' +
    'la pestana Almacenes.';
  SPreguntaPrevisualizarAddBlock:string =
    'No has previsualizado. Previsualizar ahora?';
  SInfoArticulosYaCargadosAddBlock:string =
    'Todos los articulos del filtro ya estan cargados. Nada que insertar.';
  SPreguntaConfirmarAddBlock:string =
    'Se van a insertar %d articulos. Continuar?';
  SInfoArticulosAnadidosAddBlock:string =
    '%d articulos anadidos correctamente.';
  SErrorDestinoDocumentoTrabajoAddBlock:string =
    'No se ha recibido el Documento de Trabajo destino.';
  SErrorAlmacenesDocumentoTrabajoAddBlock:string =
    'Seleccione al menos un almacen para cargar articulos.';
  SPreguntaConfirmarDocumentoTrabajoAddBlock:string =
    'Se van a cargar %d articulos en el Documento de Trabajo "%s".' +
    sLineBreak +
    'Se anadira una linea por cada SKU con stock positivo en los almacenes ' +
    'seleccionados.' + sLineBreak +
    'La cantidad operativa de cada linea sera 1.' + sLineBreak +
    sLineBreak + 'Continuar?';
  SInfoLineasDocumentoTrabajoAddBlock:string =
    '%d lineas anadidas al Documento de Trabajo.';
  SErrorInsertarLineasDocumentoTrabajoAddBlock:string =
    'Error al insertar lineas del documento: ';
  SErrorDestinoInventarioAddBlock:string =
    'No se ha recibido la clave del inventario destino.';
  SPreguntaConfirmarInventarioAddBlock:string =
    'Se van a anadir %d articulos al inventario %s/%s/%s/%s.' + sLineBreak +
    'Cada articulo generara una linea por cada SKU con stock>0.' + sLineBreak +
    'Las cantidades teoricas se calcularan despues con "Recalcular ' +
    'teorico/PMP".' + sLineBreak + sLineBreak + 'Continuar?';
  SInfoLineasInventarioAddBlock:string =
    '%d lineas anadidas al inventario.' + sLineBreak +
    'Recuerda pulsar "Recalcular teorico/PMP" para rellenar las cantidades.';
  SErrorInsertarLineasInventarioAddBlock:string =
    'Error al insertar lineas de inventario: ';
  SErrorTarifaDestinoAddBlockNoSeleccionada:string =
    'Selecciona la tarifa destino antes de previsualizar.';
  SErrorTarifaOrigenAddBlockNoSeleccionada:string =
    'Selecciona la tarifa origen para copiar precios.';
  SErrorTarifasAddBlockCoincidentes:string =
    'La tarifa origen no puede ser la misma que la tarifa destino.';
  SErrorMultiploAjusteAddBlockNoValido:string =
    'El multiplo del ajuste debe ser mayor que 0.';
  SPreguntaConfirmarTarifaAddBlock:string =
    'Se van a insertar %d articulos en la tarifa "%s". Continuar?';
  SInfoArticulosTarifaAddBlockAnadidos:string =
    '%d articulos anadidos a la tarifa correctamente.';
  SErrorInsertarTarifaAddBlock:string =
    'Error al insertar: ';
  SPreguntaQuitarPropiedadArticulo:string =
    '¿Quitar la propiedad "%s" de este artículo?';
  SErrorArticuloNoGuardadoValoresColor:string =
    'Primero guarde el artículo antes de fijar valores por color.';
  SErrorArticuloNoGuardadoAnadirPropiedades:string =
    'Primero guarde el artículo antes de añadir propiedades.';
  SErrorPropiedadObligatoriaFamilia:string =
    'La propiedad "%s" es obligatoria para esta familia.';
  SErrorPrecioCosteMargenNoValido:string =
    'El precio de coste debe ser mayor que cero.';
  SErrorMargenNoValido:string =
    'El margen debe ser mayor que cero.';
  SErrorAjusteMargenNoValido:string =
    'El ajuste no puede ser negativo.';
  SErrorGuardarCambiosMargen:string =
    'No se han podido guardar los cambios: ';
  SErrorProveedorPrincipalCosteNoAsignado:string =
    'El artículo no tiene un proveedor marcado como principal. Asigna uno ' +
    'en la pestaña Proveedores antes de guardar el coste.';
  SErrorEmpresaEfectosRemesaNoIndicada:string =
    'Indica la empresa.';
  SInfoEfectosPendientesRemesaNoEncontrados:string =
    'No hay efectos pendientes sin remesar para esa empresa.';
  SErrorEfectosRemesaNoSeleccionados:string =
    'Marca al menos un efecto (Ctrl/Mayus+clic).';
  SErrorRemesaExistenteNoSeleccionada:string =
    'Elige la remesa existente.';
  SInfoEfectosCargadosRemesa:string =
    'Cargados %d efecto(s) en la remesa %s / %s.' + sLineBreak +
    'Omitidos (ya remesados o %s): %d.';
  SPreguntaConfirmarCargaSesionTarifa:string =
    'Se van a cargar %d articulos en la sesion. Continuar?';
  SInfoArticulosCargadosSesionTarifa:string =
    '%d articulos cargados en la sesion.';
  SErrorCargarSesionTarifa:string =
    'Error al cargar la sesion: ';
  SErrorTipoDocumentoSesionNoSeleccionado:string =
    'Marca al menos uno: Albaran y/o Pedido.';
  SErrorSerieAlbaranSesionNoIndicada:string =
    'Indica la serie del albaran.';
  SErrorSeriePedidoSesionNoIndicada:string =
    'Indica la serie del pedido.';
  SErrorAlmacenDestinoSesionNoIndicado:string =
    'Indica un almacen destino.';
  SErrorCertificadoNoSeleccionado:string =
    'Seleccione un certificado.';
  SErrorEmpleadoEntradaCambioNoIndicado:string =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteEntradaCambioNoValido:string =
    'Introduzca un importe mayor que cero.';
  STituloAvisoEntradaCambio:string =
    'Aviso';
  SErrorDestinoEnvioIncompleto:string =
    'Almacén, serie y número son obligatorios.';
  SErrorTarifaEtiquetasNoSeleccionada:string =
    'Seleccione una tarifa antes de imprimir.';
  SInfoLayoutEtiquetasGuardado:string =
    'Layout guardado.';
  SErrorEmpresaProveedorFacturacionNoIndicados:string =
    'Indica empresa y proveedor.';
  SInfoAlbaranesPendientesProveedorNoEncontrados:string =
    'No hay albaranes pendientes de crear borrador para ese proveedor.';
  SPreguntaFacturarTodosAlbaranesListados:string =
    'No has marcado albaranes (Ctrl/Mayus+clic para elegir).' + sLineBreak +
    'Crear borrador con TODOS los listados?';
  SErrorBorradorAlbaranesExistenteNoSeleccionado:string =
    'Elige el borrador existente al que incorporar los albaranes.';
  SInfoAlbaranesGeneradosEnBorrador:string =
    'Generados %d albaran(es) en el borrador %s / %s.' + sLineBreak +
    'Omitidos (ya asociados o incompatibles): %d.';
  SErrorDataModuleAlbaranesNoAsignado:string =
    'No hay datamodule de albaranes asignado.';
  SErrorAlbaranesNoSeleccionados:string =
    'No hay albaranes seleccionados.';
  SInfoBorradoresGenerados:string =
    'Proceso finalizado. Borradores generados: %d.';
  SErrorClienteBorradorNoSeleccionado:string =
    'Seleccione el cliente del borrador.';
  SErrorSerieBorradorNoSeleccionada:string =
    'Seleccione la serie del borrador.';
  SErrorFechaBorradorNoIndicada:string =
    'Indique la fecha del borrador.';
  SErrorClienteFacturarTicketNoExiste:string =
    'El cliente seleccionado no existe.';
  SErrorRazonSocialFacturarTicketObligatoria:string =
    'La F3 necesita la razon social del cliente.';
  SErrorDocumentoFiscalFacturarTicketNoValido:string =
    'El NIF/CIF/NIE del cliente no es valido: ';
  SErrorCrearBorradorFacturarTicket:string =
    'No se pudo crear el borrador: ticket o cliente no encontrados.';
  SPreguntaSuperarLimiteCargaArticulos:string =
    'Aún se cargarán %d artículos, por encima del límite recomendado de %d.' +
    sLineBreak + 'La carga puede tardar. ¿Continuar igualmente?';
  // Modals G-M
  SErrorDimensionesSkuNoDefinidas:string =
    'No hay dimensiones definidas para este tipo de variación.';
  SErrorValoresSkuNoSeleccionados:string =
    'No has marcado ningún valor para generar SKUs.';
  SErrorValoresDimensionesSkuIncompletos:string =
    'Debes marcar al menos un valor en cada dimensión del artículo.' +
    sLineBreak + 'Falta marcar valores en: %s';
  SInfoCombinacionesSkuGeneradas:string =
    '¡Combinaciones generadas con éxito!';
  STituloAnadirValorSku:string =
    'Añadir nuevo valor';
  SSolicitudNombreValorSku:string =
    'Introduce el nombre del nuevo atributo (Ej: XXL, Turquesa):';
  SSolicitudOrdenNuevoValorSku:string =
    'Introduce el ORDEN (Ej: 10, 20, 30...).' + sLineBreak + sLineBreak +
    'ATENCIÓN: El orden asignado será global y afectará a todos los ' +
    'artículos que usen este valor en el futuro.';
  SPreguntaGuardarValorSkuGlobal:string =
    'Va a utilizar el valor "%s".' + sLineBreak + sLineBreak +
    '¿Desea guardarlo de forma permanente en el conjunto global "%s" para ' +
    'que aparezca disponible siempre para otros artículos?' + sLineBreak +
    sLineBreak + '[SÍ] -> Añadir al conjunto global' + sLineBreak +
    '[NO] -> Usar SOLO ESTA VEZ para generar el SKU (no se guarda en el ' +
    'conjunto)';
  SPreguntaUsarValorSkuTemporal:string =
    'El artículo no tiene un conjunto global asignado.' + sLineBreak +
    sLineBreak + 'El valor "%s" se utilizará SOLO ESTA VEZ para generar el ' +
    'SKU de este artículo, pero no se guardará en ninguna lista de ' +
    'conjuntos.' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloCambiarOrdenValorSku:string =
    'Cambiar orden del valor';
  SSolicitudOrdenValorSku:string =
    'Orden de "%s" (número entero, los más bajos van primero y prevalence ' +
    'el orden del sistema):';
  SErrorOrdenValorSkuNoValido:string =
    'Por favor, introduce un número entero válido, (mayor o igual a 0).';
  SPreguntaCambiarOrdenValorSkuGlobal:string =
    'Este valor proviene de un sistema de colores o atributos (%s).' +
    sLineBreak + sLineBreak +
    'ATENCIÓN: Este cambio implica un cambio que puede afectar a otros ' +
    'artículos que compartan este sistema.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  STituloCambiarOrdenAtributoSku:string =
    'Cambiar orden';
  SSolicitudOrdenAtributoSku:string =
    'Orden de "%s" dentro del SKU (número entero, los más bajos van ' +
    'primero):';
  SErrorOrdenAtributoSkuNoValido:string =
    'Introduce un número entero mayor que 0.';
  SPreguntaEditarCamposExtraInforme:string =
    '¿Desea añadir o editar campos extra del informe provenientes de otras ' +
    'tablas o vistas externas?';
  SErrorPrivilegiosBorrarFormato:string =
    'No tiene privilegios suficientes para borrar el formato de %s. ' +
    'Consulte con el Administrador';
  SPreguntaBorrarFormato:string =
    '¿Está seguro de borrar el formato?';
  SPreguntaReemplazarInforme:string =
    'El informe ya existe. ¿Desea reemplazar el informe?';
  STituloAdvertenciaInforme:string =
    'Mensaje Advertencia';
  SErrorContrasenasNoCoinciden:string =
    'Las contraseñas no coinciden';
  SErrorFiltroNoSeleccionado:string =
    'Seleccione un filtro de la lista.';
  SErrorFiltroSinCondicionesAplicar:string =
    'El filtro no tiene condiciones para aplicar.';
  SErrorFiltroSinCondicionesGuardar:string =
    'El filtro no tiene condiciones para guardar.';
  SInfoCambiosFiltroGuardados:string =
    'Cambios del filtro guardados correctamente.';
  SErrorPantallaSinFiltroAplicado:string =
    'La pantalla no tiene ningún filtro aplicado.';
  SPreguntaReemplazarFiltro:string =
    'Filtro guardado actualmente:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Se reemplazará por el filtro actual de la pantalla:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloReemplazarFiltro:string =
    'Reemplazar filtro';
  SInfoFiltroReemplazado:string =
    'Filtro reemplazado correctamente.';
  SErrorFiltroPropioDuplicado:string =
    'Ya existe un filtro propio con ese nombre. Indique un nombre diferente.';
  SInfoCopiaFiltroGuardada:string =
    'Copia del filtro guardada correctamente.';
  SPreguntaBorrarFiltro:string =
    '¿Borrar el filtro seleccionado?';
  STituloConfirmarBorradoFiltro:string =
    'Confirmar borrado';
  SInfoFiltroCompartidoGrupo:string =
    'Filtro compartido con tu grupo (%s).';
  SInfoFiltroCompartidoTodos:string =
    'Filtro compartido con todos los usuarios.';
  SErrorNombreFiltroNoIndicado:string =
    'Indique un nombre para el filtro.';
  SErrorCodigoGuiaNoIndicado:string =
    'Escribe un código para la guía.';
  SErrorTablaExternaGuiaNoSeleccionada:string =
    'Selecciona una tabla externa.';
  SErrorCampoMasterGuiaNoSeleccionado:string =
    'Selecciona el campo master.';
  SErrorCampoDetailGuiaNoSeleccionado:string =
    'Selecciona el campo detail (de la tabla).';
  SInfoGuiaAnadida:string =
    'Guía "%s" añadida: %s.%s → %s';
  SInfoGuiasEliminarNoEncontradas:string =
    'No hay guías para eliminar.';
  SPreguntaEliminarGuia:string =
    '¿Eliminar la guía "%s"?';
  SErrorFacturaCompraExportarNoPreparada:string =
    'No hay factura de compra preparada para exportar.';
  SErrorDataModulePedidosNoAsignado:string =
    'No hay datamodule de pedidos asignado.';
  SInfoImportacionPedidosFinalizada:string =
    'Importación finalizada. Pedidos importados: %d. Errores: %d.';
  // Modals N-Z
  SErrorConexionOperacionesCajaSkuNoDisponible:string =
    'No hay una conexión disponible para la consulta.';
  SErrorImporteConciliadoNoValido:string =
    'El importe conciliado debe ser mayor que 0.';
  SErrorImporteConciliadoSuperaPendiente:string =
    'El importe no puede superar el pendiente.';
  SErrorNombreFormatoWizardNoIndicado:string =
    'Indique un nombre para el formato.';
  SErrorNombreFormatoWizardNoModificado:string =
    'Escriba un nombre nuevo para el formato.';
  SErrorDatasetMasterWizardNoSeleccionado:string =
    '1) Selecciona el dataset master (cabecera o detalle) en la lista de la ' +
    'izquierda.';
  SErrorCamposMasterWizardNoSeleccionados:string =
    '2) Marca al menos un campo del master (Master fields).';
  SErrorTablaExternaWizardNoSeleccionada:string =
    '3) Selecciona la tabla o vista externa que quieres ligar.';
  SErrorCamposTablaExternaWizardNoSeleccionados:string =
    '4) Selecciona el campo (o campos) de la tabla externa que se cruzan con ' +
    'el master. Para seleccionar varios usa Ctrl o Mayus; el orden de ' +
    'seleccion determina el pareo con los Master fields (k=1,2,...).';
  SErrorPrepararImpresionDeclaracionResponsable:string =
    'No se pudo preparar el documento de impresión.';
  SErrorImprimirDeclaracionResponsable:string =
    'No se pudo imprimir la declaración responsable:' + sLineBreak;
  SInfoNumeroInstalacionSifDisponible:string =
    'Número de instalación SIF disponible: ';
  SErrorGenerarNumeroInstalacionSif:string =
    'No se pudo generar el número de instalación SIF:' + sLineBreak;
  SErrorSerieDocumentoNoIndicada:string =
    'Introduzca la serie.';
  SErrorFechaInicioDocumentoNoIndicada:string =
    'Introduzca la fecha de inicio.';
  SErrorFechaFinDocumentoNoIndicada:string =
    'Introduzca la fecha de fin.';
  SErrorRangoFechasDocumentoNoValido:string =
    'La fecha de fin no puede ser anterior al inicio.';
  SInfoEmpresaSinCuentasBancarias:string =
    'La empresa no tiene cuentas bancarias activas. El documento se ' +
    'generará sin banco de empresa asignado.';
  SErrorAlmacenPedidoNoSeleccionado:string =
    'Selecciona un almacen.';
  SInfoAlbaranesIncorporarNoDisponibles:string =
    'No hay albaranes a los que incorporar; crea uno nuevo.';
  SErrorSerieAlbaranPedidoNoIndicada:string =
    'Indica la serie del albaran.';
  SInfoLogGuardado:string =
    'Log guardado en %s';
  SErrorAlmacenAlbaranNoSeleccionado:string =
    'Selecciona un almacen.';
  SErrorAlbaranDestinoNoSeleccionado:string =
    'Selecciona el albaran al que anadir las lineas.';
  SErrorCodigoAcreedorSepaNoIndicado:string =
    'Indica el código acreedor SEPA.';
  SErrorLongitudCodigoAcreedorSepa:string =
    'El código acreedor SEPA no puede superar 35 caracteres.';
  SErrorFormatoCodigoAcreedorSepaNoValido:string =
    'Código acreedor SEPA no válido. En España debe tener formato ESkkZZZ ' +
    'seguido del NIF.';
  SErrorSecuenciaSepaNoValida:string =
    'Secuencia SEPA no válida.';
  SErrorClientesSinMandatoSepa:string =
    'Hay clientes sin mandato SEPA.';
  SErrorMandatosSepaLongitudNoValida:string =
    'Hay mandatos SEPA de más de 35 caracteres.';
  SErrorClientesSinFechaFirmaMandatoSepa:string =
    'Hay clientes sin fecha de firma del mandato SEPA.';
  // Caja: DataModules y Lib
  SErrorCodigoFormaPagoCajaObligatorio:string =
    'El Código de la Forma de Pago es obligatorio';
  SErrorDescripcionFormaPagoCajaObligatoria:string =
    'La Descripción de la Forma de Pago es obligatoria';
  SErrorParametrosAplicacionCajaNoConfigurados:string =
    'No se han configurado los parámetros de aplicación.';
  SErrorParametrosModuloCajaNoConfigurados:string =
    'No se han configurado los parámetros del módulo de caja.';
  SErrorContextoSesionCajaNoConfigurado:string =
    'No se ha configurado el contexto de sesión del módulo de caja.';
  SErrorOperacionCajaSinLineas:string =
    'No se puede grabar una operación sin líneas.';
  SErrorRazonSocialClienteFacturaCajaObligatoria:string =
    'La factura normal necesita la razon social del cliente.';
  SErrorDocumentoFiscalClienteCajaNoValido:string =
    'El NIF/CIF/NIE del cliente no es valido: ';
  SErrorDocumentoFiscalEmpresaCajaNoValido:string =
    'El NIF/CIF/NIE de la empresa no es valido: ';
  SErrorFechaTicketSerieNoValida:string =
    'No se puede grabar el ticket en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha de ' +
    'caja %s.' + sLineBreak +
    'Cambie la serie para emitir un ticket con esta fecha.';
  SErrorCuadreCobroParcialCaja:string =
    'No se pudo cuadrar tras cobro parcial.';
  SErrorFacturaRectificativaCajaSinOriginal:string =
    'La rectificativa no tiene factura original asociada.';
  SErrorGuardarTicketCaja:string =
    'Error al guardar el ticket. No se ha registrado la operación.' +
    sLineBreak + 'Motivo: %s';
  SErrorCuadrarFacturaCaja:string =
    'Error al cuadrar la factura: %s';
  SErrorRedimirValeCaja:string =
    'No se pudo redimir el vale "%s". Filas afectadas: %d. Posibles causas: ' +
    'el vale no existe, ya fue redimido, esta caducado o anulado.';
  SErrorContextoSesionTraspasoNoConfigurado:string =
    'No se ha configurado el contexto de sesión del módulo de traspasos.';
  SErrorSkuTraspasoIncompleto:string =
    'El artículo "%s" no tiene el SKU completo (elige color/talla). SKU: "%s"';
  SErrorArticuloSkuTraspasoNoCoincide:string =
    'La línea del artículo "%s" no corresponde al SKU "%s" (artículo real ' +
    '"%s"). Borra la línea y vuelve a introducirlo.';
  SErrorStockTraspasoInsuficiente:string =
    'No hay stock suficiente en el almacén origen (%s):' + sLineBreak + '%s';
  SErrorLineasTraspasoNoDisponibles:string =
    'No hay líneas que traspasar.';
  SErrorAlmacenDestinoTraspasoNoSeleccionado:string =
    'Selecciona el almacén destino.';
  SErrorAlmacenesTraspasoCoincidentes:string =
    'Origen y destino no pueden ser el mismo almacén.';
  SErrorLineasSolicitudTraspasoNoDisponibles:string =
    'No hay líneas que solicitar.';
  SErrorAlmacenOrigenSolicitudNoSeleccionado:string =
    'Selecciona el almacén al que solicitas.';
  SErrorSolicitudTraspasoMismoAlmacen:string =
    'No puedes solicitarte a ti mismo.';
  SErrorSolicitudTraspasoNoCargada:string =
    'No hay solicitud cargada que denegar.';
  SErrorPermisoAbrirCajon:string =
    'No tiene permiso para abrir el cajón.';
  SErrorImpresoraTicketsCajaNoConfigurada:string =
    'No hay impresora de tickets configurada en parámetros ' +
    '(vgerDefPrinter); no se puede abrir el cajón.';
  SErrorContextoImpresoraCajaNoProporcionado:string =
    'No se ha proporcionado el contexto para la impresora de caja.';
  // Caja: Forms A-M
  SErrorReferenciaPagoCajaNoIndicada:string =
    'Debe introducir la referencia del pago.';
  SErrorFactorCambioCajaNoValido:string =
    'El factor de cambio debe ser mayor que cero.';
  SErrorHashBlockchainCajaNoIndicado:string =
    'Debe introducir el hash de la transacción blockchain.';
  SErrorValeCajaNoSeleccionado:string =
    'No hay ningún vale seleccionado.';
  SErrorPinValeCajaNoIndicado:string =
    'Introduzca el PIN de seguridad del vale para poder canjearlo.';
  SErrorPinValeCajaIncorrecto:string =
    'El PIN de seguridad no es correcto.' + sLineBreak +
    'Verifique el código que aparece en el vale físico.';
  SErrorProveedorParametrosCajaNoConfigurado:string =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosCajaEditablesNoConfigurados:string =
    'No se han configurado los parámetros de caja editables.';
  SInfoLayoutCajaGuardado:string =
    'Layout guardado.';
  SInfoParametrosCajaGuardados:string =
    'Se han guardado %d parámetros correctamente para: %s';
  SInfoParametrosCajaSinCambios:string =
    'No se han detectado cambios para guardar.';
  SPreguntaSalirParametrosCajaSinGuardar:string =
    '¿Está seguro de que desea salir sin guardar?';
  SInfoUsuariosParametrosCajaNoEncontrados:string =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuarioParametrosCaja:string =
    'Cambiar usuario';
  SSolicitudCambiarUsuarioParametrosCaja:string =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Introduce el nombre de usuario:';
  SErrorUsuarioParametrosCajaNoEncontrado:string =
    'Usuario no encontrado: %s';
  SInfoPrecargaCajaGuardada:string =
    'Precarga guardada.';
  SErrorAsignarUbicacionCaja:string =
    'Error al asignar Empresa Almacén Caja';
  STituloHoraCaja:string =
    'Hora de caja';
  SSolicitudHoraCaja:string =
    'Hora (HH:MM)';
  SErrorHoraCajaNoValida:string =
    'Hora no válida. Use HH:MM.';
  SErrorUbicacionCajaBuscarOperacionesNoAsignada:string =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'buscar operaciones.';
  SErrorUbicacionCajaArqueoNoAsignada:string =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer arqueo.';
  SErrorUbicacionCajaTraspasoNoAsignada:string =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer traspasos.';
  SErrorRectificacionCajaNoAdmiteBorrador:string =
    'Una rectificación se cierra como ticket rectificativo, no como ' +
    'borrador normal.';
  SErrorClienteBorradorCajaNoAsignado:string =
    'Asigne un cliente a la operación para emitir borrador.';
  SErrorNifClienteBorradorCajaNoIndicado:string =
    'El cliente no tiene NIF: complételo en su ficha para poder emitir ' +
    'borrador normal.';
  SErrorFechaSerieEmisionCajaNoValida:string =
    'No se puede emitir en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha ' +
    '%s.' + sLineBreak + 'Elija otra serie para emitir con esta fecha.';
  SAvisoHuecosNumeracionSerieCaja:string =
    'La serie "%s" tiene huecos en la numeración: faltan %d números entre ' +
    'el %d y el %d.' + sLineBreak +
    'Recuerde que la numeración debe ser correlativa según la ley.';
  SErrorNumeroBorradorCajaNoValido:string =
    'El número de borrador indicado no es válido.';
  SErrorNumeroBorradorCajaExistente:string =
    'El número %d ya existe en la serie "%s".';
  SErrorNumeroBorradorCajaNoEsHueco:string =
    'El número %d no es un hueco de la serie "%s": los huecos están entre ' +
    'el %d y el %d.';
  STituloEnviarDocumentacionCaja:string =
    'Enviar documentación';
  SSolicitudCorreoDocumentacionCaja:string =
    'Correo electrónico:';
  SErrorCorreoDocumentacionCajaNoIndicado:string =
    'Indique una dirección de correo electrónico.';
  SErrorCreditoClienteCajaNoPermitido:string =
    'Operación denegada: Este cliente no tiene crédito permitido.';
  SErrorImporteCreditoCajaNoPendiente:string =
    'No hay importe pendiente para pasar a crédito.';
  SAvisoLimiteOperacionesCaja:string =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorOperacionCajaExportarNoSeleccionada:string =
    'No hay ninguna operación seleccionada para exportar.';
  SErrorSkuVentaCajaNoExiste:string =
    'El SKU "%s" no existe en fza_articulos_skus. No se puede vender.';
  SErrorSkuVentaCajaNoActivo:string =
    'El SKU "%s" no está activo. No se puede vender.';
  SErrorArticuloVentaCajaSinStock:string =
    'Artículo sin stock. Compruebe stock en almacén.';
  SErrorVendedorCajaNoAsignado:string =
    'Da de alta el vendedor antes de leer artículos.';
  SErrorCodigoBarrasVentaCajaNoEncontrado:string =
    'Código de barras no encontrado: %s';
  SErrorLineaDepositoCajaNoCancelable:string =
    'No se puede cancelar o eliminar una línea vinculada a un depósito.';
  SErrorArticuloVentaCajaNoEncontrado:string =
    'Artículo no encontrado';
  SPreguntaCancelarVentaCaja:string =
    'Hay líneas en la venta actual.' + sLineBreak +
    '¿Desea CANCELAR LA VENTA y salir?';
  SErrorLineaDepositoCajaNoEliminable:string =
    'No se puede eliminar una línea vinculada a un depósito.' + sLineBreak +
    'Cambie la cantidad a negativo si necesita revertirla.';
  SPreguntaBorrarVentaCaja:string =
    'Hay una venta en curso.' + sLineBreak +
    '¿Desea BORRAR LA VENTA y salir?';
  SInfoValeCajaEntregar:string =
    'Entregue el vale al cliente: %s';
  SErrorCorreoOperacionCajaNoEnviado:string =
    'La operación se ha guardado correctamente, pero no se ha podido enviar ' +
    'el correo.' + sLineBreak + '%s';
  SErrorTipoRectificativaCajaNoIndicado:string =
    'Debe indicar el tipo de rectificativa.';
  SErrorBorradorRectificarCajaNoEncontrado:string =
    'No se encontró el borrador %s\%s a rectificar.';
  SErrorClienteDepositosCajaNoSeleccionado:string =
    'Debe seleccionar un cliente para cargar sus depósitos.';
  SErrorValoresAtributoCajaNoDefinidos:string =
    'No hay valores definidos para este atributo.';
  SPreguntaEliminarOperacionCajaPendiente:string =
    'La Operación %d tiene artículos pendientes.' + sLineBreak +
    '¿Desea ELIMINARLA y cerrar?';
  SErrorArticuloCajaNoEncontradoDescatalogado:string =
    'ARTÍCULO NO ENCONTRADO O DESCATALOGADO';
  SErrorCantidadArticuloDepositoCajaNoValida:string =
    'En artículos de depósito solo está permitido cambiar el signo de la ' +
    'cantidad.';
  SErrorCodigoClienteCajaNoExiste:string =
    'El código de cliente no existe.';
  SErrorEmpleadoCajaNoEncontrado:string =
    'No se encontró ningún empleado válido.';
  // Caja: Forms N-Z
  SErrorSolicitudesTraspasoPendientesNoEncontradas:string =
    'No hay solicitudes pendientes de atender.';
  SErrorCargarSolicitudTraspaso:string =
    'No se pudo cargar la solicitud.';
  SErrorSolicitudTraspasoCerrarNoCargada:string =
    'Trae primero una solicitud (F8) para cerrarla.';
  SPreguntaCerrarSolicitudTraspaso:string =
    '¿Cerrar la solicitud dejando las líneas sin servir como no atendidas?';
  SInfoSolicitudTraspasoCerrada:string =
    'Solicitud cerrada.';
  SErrorDenegarSolicitudTraspasoModoNoValido:string =
    'Denegar solo aplica al atender una solicitud.';
  SErrorSolicitudTraspasoDenegarNoCargada:string =
    'Trae primero una solicitud (F8) para denegarla.';
  STituloDenegarSolicitudTraspaso:string =
    'Denegar petición';
  SSolicitudMotivoRechazoTraspaso:string =
    'Motivo del rechazo (lo verá quien la pidió):';
  SErrorMotivoDenegacionTraspasoNoIndicado:string =
    'Debes indicar un motivo para denegar.';
  SInfoPeticionTraspasoDenegada:string =
    'Petición denegada (DENEGADO TOTAL).';
  SInfoSolicitudTraspasoEnviada:string =
    'Solicitud %s/%s enviada.';
  SErrorEmpleadoTraspasoNoIndicado:string =
    'Indica el empleado responsable del traspaso.';
  SErrorEmpleadoTraspasoNoEncontrado:string =
    'Empleado no encontrado: %s';
  SErrorSolicitudTraspasoAtenderNoCargada:string =
    'Carga primero una solicitud (botón Cargar solicitud).';
  SErrorMotivoLineasTraspasoNoIndicado:string =
    'Indica el motivo en las líneas que deniegas (las que sirves a 0).';
  SInfoSolicitudTraspasoAtendida:string =
    'Solicitud atendida. Traspaso %s grabado.';
  SPreguntaDenegarPeticionTraspasoCompleta:string =
    'No has marcado nada para servir. ¿Denegar toda la petición?';
  SInfoTraspasoGrabado:string =
    'Traspaso %s grabado correctamente.';
  // Caja: Modals
  SErrorEmpleadoGastoCajaNoIndicado:string =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteGastoCajaNoValido:string =
    'Introduzca un importe mayor que cero.';
  STituloAvisoCaja:string =
    'Aviso';
  SErrorArqueoCajaNoSeleccionado:string =
    'Seleccione un arqueo del listado.';
  SErrorPermisoResumenArqueoCaja:string =
    'No tiene permiso para consultar el resumen del arqueo.';
  SInfoOperacionesFacturadasArqueoCajaNoEncontradas:string =
    'No hay operaciones facturadas en el rango seleccionado.';
  STituloTiraCaja:string =
    'Tira de Caja';
  SErrorVendedorArqueoCajaNoIndicado:string =
    'Debe indicar el número de empleado de caja del vendedor que realiza el ' +
    'cierre.';
  STituloVendedorArqueoCajaObligatorio:string =
    'Vendedor obligatorio';
  SErrorVendedorArqueoCajaNoValido:string =
    'El número de empleado indicado no existe o no está activo.';
  STituloVendedorArqueoCajaNoValido:string =
    'Vendedor no válido';
  SErrorArqueoCajaDuplicado:string =
    'Ya existe un cierre que solapa este rango y caja. No se permite doble ' +
    'cierre.';
  STituloArqueoCajaDuplicado:string =
    'Arqueo duplicado';
  SErrorRecuentoArqueoCajaNoDisponible:string =
    'No hay datos de recuento. Pulse Recalcular primero.';
  SPreguntaGrabarArqueoCaja:string =
    'Se va a grabar el arqueo con los importes recontados.' + sLineBreak +
    'Periodo: %s - %s' + sLineBreak +
    'Las operaciones del rango quedarán marcadas.' + sLineBreak +
    sLineBreak + '¿Desea continuar?';
  STituloConfirmarArqueoCaja:string =
    'Confirmar Arqueo';
implementation


end.
