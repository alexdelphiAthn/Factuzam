{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgComun                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes compartidos por infraestructura y varios dominios.               }
{******************************************************************************}
unit inLibMsgComun;

interface

resourcestring
  SClassRttiNotFnd = 'Clase %s no encontrada en rtti. ' +
                            'Hay un error al crear el formulario';
  SLocateNotFnd = 'El dato o datos %s no se han encontrado en %s';
  SResWinFNotFnd = '%s no encontrada en las tabla del sistema' +
                            ' fza_winforms';
  SAdvMsg = 'Mensaje Advertencia';
  SErrorContextoSesionFormularioNoConfigurado =
    'No se ha configurado el contexto de sesión del formulario.';
  SErrorServicioAuditoriaDatosNoConfigurado =
    'No se ha configurado el servicio de auditoría de datos.';
  SAvisoSinComandosESCPOSImpresora =
    'No hay comandos ESC/POS para enviar a la impresora.';
  SErrorImprimir = 'Error al imprimir: %s';
  SAvisoSinComandosESCPOSPDF =
    'No hay comandos ESC/POS para generar el PDF.';
  SInfoPDFGuardado = 'PDF guardado en: %s';
  SInfoPNGGuardado = 'PNG guardado en: %s';
  SAvisoColacionSesion =
    'No se pudo fijar la colación de la sesión: %s';
  SAvisoTimeoutServidor =
    'No se pudo establecer el timeout del servidor: %s';
  SDetalleErrorMySQL = sLineBreak + '(MySQL %d: %s)';
  SErrorAbrirConsultaOpe =
    '[ConsultaOpe] Error abriendo %s: %s';
  SPreguntaCambioCriticoEmpresa =
    'Atención: %s una empresa puede anular la licencia del programa o ' +
    'invalidar el sistema Verifactu existente.' + sLineBreak + sLineBreak +
    'Revise que los datos fiscales, certificados y la instalación SIF ' +
    'siguen siendo correctos.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  SErrorPorcentajeRetencionEmpresa =
    '%d no es un valor válido  para %% de Retención';
  SErrorRetencionesEmpresaConcurrentes =
    'No se pueden grabar dos porcentajes  activos en la misma fecha para ' +
    'la empresa %s';
  SErrorSerieEmpresa =
    '%s no es un valor válido  para serie por Empresa ';
  SErrorIbanEmpresa =
    'IBAN no válido para el banco de la empresa: %s';
  SErrorRazonSocialEmpresa =
    '%s no es un valor de registro válido para el campo Razón Social de ' +
    'Empresa';
  SErrorCodigoEmpresa =
    '%s no es un valor de registro válido para el campo Código de Empresa';
  SErrorCabeceraBorradorSinGrabar =
    'No se ha grabado la cabecera del borrador';
  SErrorServicioConexionesDatosNoConfigurado =
    'No se ha configurado el servicio de conexiones de datos.';
  SErrorContextoSesionFiltrosNoConfigurado =
    'No se ha configurado el contexto de sesión.';
  SErrorDescripcionFormaPago =
    '%s no es un valor válido para el campo Descripción de Formas de Pago';
  SErrorContextoSesionModuloDatosNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de datos.';
  SErrorCodigoIva =
    '%s no es un valor de registro válido para el campo Código de IVA';
  SErrorGrupoIvaNoExiste =
    '%s no es un valor válido o no existe para grupo de IVAS';
  SErrorRangoFechasIva =
    'Error de Rango en las fechas. Error en la fecha.O se han establecido ' +
    'dos periodos activos en el mismo periodo para la zona %s';
  SErrorDescripcionGrupoIva =
    '%s no es un valor de registro válido para el campo Descripción de ' +
    'Grupos de IVA';
  SErrorCodigoGrupoIva =
    '%s no es un valor de registro válido para el campo Código de Grupos ' +
    'de IVA';
  SErrorDosGruposIvaPredeterminados =
    'No es posible marcar dos grupos de IVA como Grupo de IVA por Defecto';
  SErrorContextoSesionPerfilesNoConfigurado =
    'No se ha configurado el contexto de sesión.';
  SErrorEmpresaSinAlmacenActivo =
    'La empresa %s no tiene ningún almacén activo disponible.';
  SErrorAlmacenDepositosEmpresaNoEncontrado =
    'No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ' +
    '''DEPÓSITO'') activo para la empresa %s.';
  SErrorCodigoEanMinimo7Digitos =
    'El código debe tener al menos 7 dígitos para calcular el control.';
  SErrorCodigoEanMinimo12Digitos =
    'El código debe tener al menos 12 dígitos para calcular el control.';
  SErrorEjecutorBusquedasNoRegistrado =
    'No se ha registrado el ejecutor de búsquedas genéricas.';
  SErrorHojaCalculoNoActiva =
    'No hay hoja activa: llama a NuevaHoja antes de escribir.';
  SErrorControlHojaCalculoObligatorio =
    'NuevaHoja requiere un control TdxSpreadSheet.';
  SErrorGuardarHojaCalculoControlObligatorio =
    'Guardar requiere un control TdxSpreadSheet, no una vista suelta.';
  SErrorIbanInvalido = 'IBAN Inválido';
  SErrorPaisIbanInvalido = 'País del IBAN Inválido';
  SErrorDigitoControlIbanInvalido =
    'Dígito Control del IBAN Inválido';
  SErrorLongitudCuentaBancariaInvalida =
    'Longitud de Número de Cuenta incorrecta';
  SErrorCuentaBancariaInvalida =
    'Número de Cuenta incorrecto';
  SErrorDigitoControlCuentaBancaria =
    'DC Incorrecto, es %s y debería ser %s';
  SErrorPaisIbanInvalidoTipos =
    'Pais del IBAN Inválido';
  SErrorDigitoControlIbanInvalidoTipos =
    'Digito Control del IBAN Inválido';
  STextoResetearLayout = 'Resetear Layout';
  SInfoLayoutReseteado =
    'Layout reseteado.' + sLineBreak +
    'Se aplicará la próxima vez que abra el formulario.';
  SErrorAccesoFicheroLog =
    'No se puede acceder a %s. Faltan permisos.';
  SErrorCrearMutexLog = 'Error al crear mutex: %s';
  SErrorPreviewExcelNoRegistrado =
    'No se ha registrado el previsualizador de hojas de cálculo.';
  SErrorGenerarContadorAutomatico =
    'Error al generar contador automático: %s';
  SErrorNumeroCuentaInvalido =
    'Número de Cuenta Inválido';
  SErrorNifNoValido = ' NIF No Válido';
  SErrorLetraDniIncorrecta =
    'Letra DNI Incorrecta. Correcta %s';
  SErrorCrearSeleccionarDocumentoAntesLineas =
    'Crea o selecciona %s antes de añadir lineas.';
  SErrorCrearSeleccionarDocumentoAntesTallas =
    'Crea o selecciona %s antes de activar tallas.';
  SDepuracionComponenteNoTcxLabel =
    '%s is not TcxLabel';
  SDepuracionComponenteNoTcxTabSheet =
    '%s is not tcxTabSheet ';
  SDepuracionComponenteNoTcxDbCheckBox =
    '%s is not TcxDBCheckBox';
  SDepuracionComponenteNoTcxButton =
    '%s is not TcxButton';
  SDepuracionComponenteNoTcxGroupBox =
    '%s is not TcxGroupBox';
  SDepuracionComponenteNoTcxDbRadioGroup =
    '%s is not TcxDBRadioGroup';
  SDepuracionComponenteNoSpeedButton =
    '%s is not TSpeedButton';
  SDepuracionComponenteNoTcxRadioButton =
    '%s is not TcxRadioButton';
  SErrorImagenNoExiste = 'La imagen no existe';
  SErrorColorPaletaBusquedaInvalido =
    'Indique un color de paleta válido por código, nombre o HEX (#RRGGBB).';
  SErrorOperacionSinBorrador =
    'La operación seleccionada no tiene borrador.';
  SErrorBorradorNoCerradoFiscalmente =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede anular.';
  SPreguntaAnularFiscalmenteBorrador =
    '¿Anular fiscalmente el borrador %s\%s?';
  SPreguntaRectificarBorrador =
    'Seleccione cómo rectificar el borrador %s\%s.' + sLineBreak +
    'Por diferencias carga las cantidades en negativo; sustitutiva las ' +
    'carga en positivo.';
  SErrorOperacionCorreoNoEncontrada =
    'No se ha encontrado la operación seleccionada.';
  STituloEnviarDocumentacion = 'Enviar documentación';
  SSolicitudCorreoElectronico = 'Correo electrónico:';
  SErrorCorreoElectronicoObligatorio =
    'Indique una dirección de correo electrónico.';
  SErrorEnviarCorreoOperacion =
    'No se ha podido enviar el correo.' + sLineBreak + '%s';
  SInfoEfectoConciliado = 'Efecto conciliado.';
  SErrorConciliarEfecto = 'No se pudo conciliar el efecto.';
  SErrorEfectoNoSeleccionado =
    'Selecciona un efecto en la rejilla.';
  SErrorCarteraEfectosNoAbierta =
    'No hay cartera de efectos abierta.';
  SPreguntaFusionarEfectos =
    '¿Fusionar los efectos seleccionados en un único efecto pendiente?';
  SInfoEfectosConciliados = 'Efectos conciliados en %s.';
  SErrorFusionarEfectos =
    'No se pudieron fusionar los efectos.';
  SErrorContadorSerieEmpresa =
    'No se pudo obtener el siguiente codigo del contador "ES" para la ' +
    'nueva serie.';
  SErrorEmpresaCrearSeriesNoSeleccionada =
    'Selecciona una empresa antes de crear sus series.';
  SInfoSeriesEmpresaCreadas =
    'Creadas %d series. Omitidas %d ya existentes.';
  SErrorEmpresaNoSeleccionada = 'No hay empresa seleccionada.';
  SInfoInstalacionSifEmpresaDisponible =
    'Número de instalación SIF disponible para %s:' + sLineBreak + '%s';
  SErrorContadorAutomaticoBusqueda =
    'No se pudo obtener el contador automático.';
  SInfoRegistroBusquedaCreado =
    'Registro %s creado correctamente.';
  SErrorInsertarRegistroBusqueda =
    'Error al insertar (se ha cancelado la operación): %s';
  SInfoTextoNoEncontrado = 'Texto no encontrado.';
  STituloBusquedaGlobal = 'Búsqueda Global';
  SSolicitudTextoBusquedaGlobal =
    'Introduce el texto a buscar en todos los procesos:';
  SInfoProcesosBusquedaNoEncontrados =
    'No se encontraron procesos que contengan: %s';
  SErrorDatosCopiarNoDisponibles = 'No hay datos que copiar.';
  SPreguntaCopiarFilasPortapapeles =
    'Vas a copiar %d filas al portapapeles. ¿Continuar?';
  SErrorEjecucionProceso = 'Error en ejecución: %s';
  SErrorComandoSqlProceso = 'Error en comando SQL: %s';
  SErrorConexionTrabajoNoDisponible =
    'No está disponible la conexión de trabajo.';
  SInfoDatosGuardados = 'Datos guardados correctamente';
  SErrorGrabarDatos = 'Error al grabar: %s';
  SPreguntaGrabarCambiosPendientes =
    'Hay datos no grabados. ¿Desea grabar los cambios?';
  STituloMensajeAdvertenciaGen = 'Mensaje de Advertencia';
  SInfoCambiosGrabados = 'Cambios grabados';
  SInfoCambiosCancelados = 'Cambios revertidos/cancelados';
  SErrorConexionPrincipalNoDisponible =
    'No está disponible la conexión principal.';
  SPreguntaEliminarRegistro =
    '¿Estás seguro de que deseas eliminar este registro?';
  STituloConfirmarEliminacion = 'Confirmar eliminación';
  SPreguntaEliminarRegistroConHijos =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo: se rompera la relacion con' + sLineBreak +
    'los registros hijos.' + sLineBreak + sLineBreak +
    '¿Deseas eliminarlo de todas formas?';
  SAvisoDesactivarRegistroConHijos =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo. Te sugerimos DESACTIVARLO' + sLineBreak +
    'para conservar el historico.';
  SAvisoDesactivarRegistroSinHijos =
    'Este registro puede DESACTIVARSE en lugar de eliminarse' + sLineBreak +
    'para conservar el historico.';
  SDescripcionHijosGenerica = 'registros asociados';
  STextoOpcionesBorradoRegistro =
    sLineBreak + sLineBreak +
    'Sí       = Desactivar (recomendado)' + sLineBreak +
    'No       = Eliminar definitivamente' + sLineBreak +
    'Cancelar = No hacer nada';
  SErrorFiltroSinCondiciones =
    'El filtro seleccionado no tiene condiciones guardadas.';
  SErrorFiltroActualVacio =
    'No hay ningun filtro aplicado en la lista para guardar.';
  SPreguntaSobrescribirFiltro =
    'Ya existe un filtro propio con ese nombre. Desea sobrescribirlo?';
  STituloSobrescribirFiltro = 'Sobrescribir filtro';
  SInfoFiltroSobrescrito = 'Filtro sobrescrito correctamente.';
  SInfoFiltroGuardado = 'Filtro guardado correctamente.';
  SPreguntaLimpiarFiltrosAddBlock =
    'Limpiar todos los filtros?';
  SPreguntaPrevisualizarAddBlock =
    'No has previsualizado. Previsualizar ahora?';
  SPreguntaConfirmarAddBlock =
    'Se van a insertar %d articulos. Continuar?';
  SErrorCertificadoNoSeleccionado =
    'Seleccione un certificado.';
  SErrorEmpleadoEntradaCambioNoIndicado =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteEntradaCambioNoValido =
    'Introduzca un importe mayor que cero.';
  STituloAvisoEntradaCambio =
    'Aviso';
  SErrorDestinoEnvioIncompleto =
    'Almacén, serie y número son obligatorios.';
  SErrorSerieBorradorNoSeleccionada =
    'Seleccione la serie del borrador.';
  SErrorFechaBorradorNoIndicada =
    'Indique la fecha del borrador.';
  SPreguntaEditarCamposExtraInforme =
    '¿Desea añadir o editar campos extra del informe provenientes de otras ' +
    'tablas o vistas externas?';
  SErrorPrivilegiosBorrarFormato =
    'No tiene privilegios suficientes para borrar el formato de %s. ' +
    'Consulte con el Administrador';
  SPreguntaBorrarFormato =
    '¿Está seguro de borrar el formato?';
  SPreguntaReemplazarInforme =
    'El informe ya existe. ¿Desea reemplazar el informe?';
  STituloAdvertenciaInforme =
    'Mensaje Advertencia';
  SErrorFiltroNoSeleccionado =
    'Seleccione un filtro de la lista.';
  SErrorFiltroSinCondicionesAplicar =
    'El filtro no tiene condiciones para aplicar.';
  SErrorFiltroSinCondicionesGuardar =
    'El filtro no tiene condiciones para guardar.';
  SInfoCambiosFiltroGuardados =
    'Cambios del filtro guardados correctamente.';
  SErrorPantallaSinFiltroAplicado =
    'La pantalla no tiene ningún filtro aplicado.';
  SPreguntaReemplazarFiltro =
    'Filtro guardado actualmente:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Se reemplazará por el filtro actual de la pantalla:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloReemplazarFiltro =
    'Reemplazar filtro';
  SInfoFiltroReemplazado =
    'Filtro reemplazado correctamente.';
  SErrorFiltroPropioDuplicado =
    'Ya existe un filtro propio con ese nombre. Indique un nombre diferente.';
  SInfoCopiaFiltroGuardada =
    'Copia del filtro guardada correctamente.';
  SPreguntaBorrarFiltro =
    '¿Borrar el filtro seleccionado?';
  STituloConfirmarBorradoFiltro =
    'Confirmar borrado';
  SInfoFiltroCompartidoGrupo =
    'Filtro compartido con tu grupo (%s).';
  SInfoFiltroCompartidoTodos =
    'Filtro compartido con todos los usuarios.';
  SErrorNombreFiltroNoIndicado =
    'Indique un nombre para el filtro.';
  SErrorCodigoGuiaNoIndicado =
    'Escribe un código para la guía.';
  SErrorTablaExternaGuiaNoSeleccionada =
    'Selecciona una tabla externa.';
  SErrorCampoMasterGuiaNoSeleccionado =
    'Selecciona el campo master.';
  SErrorCampoDetailGuiaNoSeleccionado =
    'Selecciona el campo detail (de la tabla).';
  SInfoGuiaAnadida =
    'Guía "%s" añadida: %s.%s → %s';
  SInfoGuiasEliminarNoEncontradas =
    'No hay guías para eliminar.';
  SPreguntaEliminarGuia =
    '¿Eliminar la guía "%s"?';
  SErrorImporteConciliadoNoValido =
    'El importe conciliado debe ser mayor que 0.';
  SErrorImporteConciliadoSuperaPendiente =
    'El importe no puede superar el pendiente.';
  SErrorNombreFormatoWizardNoIndicado =
    'Indique un nombre para el formato.';
  SErrorNombreFormatoWizardNoModificado =
    'Escriba un nombre nuevo para el formato.';
  SErrorDatasetMasterWizardNoSeleccionado =
    '1) Selecciona el dataset master (cabecera o detalle) en la lista de la ' +
    'izquierda.';
  SErrorCamposMasterWizardNoSeleccionados =
    '2) Marca al menos un campo del master (Master fields).';
  SErrorTablaExternaWizardNoSeleccionada =
    '3) Selecciona la tabla o vista externa que quieres ligar.';
  SErrorCamposTablaExternaWizardNoSeleccionados =
    '4) Selecciona el campo (o campos) de la tabla externa que se cruzan con ' +
    'el master. Para seleccionar varios usa Ctrl o Mayus; el orden de ' +
    'seleccion determina el pareo con los Master fields (k=1,2,...).';
  SErrorSerieDocumentoNoIndicada =
    'Introduzca la serie.';
  SErrorFechaInicioDocumentoNoIndicada =
    'Introduzca la fecha de inicio.';
  SErrorFechaFinDocumentoNoIndicada =
    'Introduzca la fecha de fin.';
  SErrorRangoFechasDocumentoNoValido =
    'La fecha de fin no puede ser anterior al inicio.';
  SInfoEmpresaSinCuentasBancarias =
    'La empresa no tiene cuentas bancarias activas. El documento se ' +
    'generará sin banco de empresa asignado.';
implementation

end.
