{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgConfiguracion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de configuración, seguridad, permisos y conexiones.              }
{******************************************************************************}
unit inLibMsgConfiguracion;

interface

resourcestring
  SErrorDecryptPassBBDD = 'Fallo en la lectura y desencriptación' +
                                  ' de password de la Base de Datos.';
  SErrorDecryptPass = 'Fallo en la lectura y desencriptación' +
                                  ' de password.';
  SErrorAuthPass = 'La contraseña de usuario no es correcta. ';
  SScriptSuccess = 'El script se ejecutó exitosamente.';
  SFailLoadScriptBBDD = 'No existe script de creación de BD, ' +
                               'instalación fallida';
  SCreateSuccBBDD = 'La Base de Datos se creó exitosamente';
  SErrorCreateBBDD = 'No existe una base de datos llamada %s, '  +
                            '¿desea crearla? ';
  SBBDDUpdateTo = 'La Base de Datos se actualizó a ';
  SNotExistsUpBBDDFile = 'No existe script de actualización %s,'+
                       ' instalación fallida';
  SAdviceUpdateBBDD = 'Es necesario actualizar la BBDD' +
                            ' con nuevos cambios,' + sLineBreak +
                            ' ¿desea proceder con el procedimiento' +
                            ' de actualización?';
  SNoConnBBDD = 'No hay conexión con la bbdd';
  SConnSuccBBDD = 'La conexión se estableció exitosamente.';
  SGetPassBBDD = 'Escriba password de la BBDD';
  SConnFailBBDD = 'Conexión fallida. Usuario, password, ' +
                           'host, puerto o Nombre de la BBDD no es válido.';
  SErrorSentenciaScript =
    'Ocurrió un error ejecutando la siguiente sentencia:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Deseas ignorar el error y continuar con el script?';
  SSolicitudPassBBDD = 'Introduzca password de la BBDD';
  SScriptEjecutado = 'El script se ejecutó exitosamente';
  SScriptNoEjecutado = 'El script no fue ejecutado';
  SErrorConexionServidorBBDD =
    'No se pudo conectar al servidor MySQL/MariaDB:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Revise la configuración pulsando "Configurar BBDD".';
  SErrorEstructuraBBDD =
    '%s' + sLineBreak + sLineBreak +
    'Puede usar "Subir script" para crear/actualizar la base de datos, ' +
    'o "Recuperar copia" para restaurar un backup.';
  SErrorConexionBBDD =
    'No se pudo conectar a la base de datos "%s":' + sLineBreak + '%s';
  SErrorInicioAutomatico =
    'No se pudo completar el inicio automático:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Introduzca sus credenciales manualmente.';
  SLicenciaEstablecida =
    'Licencia establecida.' + sLineBreak + sLineBreak +
    'Código: %s' + sLineBreak +
    'NIF de empresa: %d' + sLineBreak +
    'INI: %s' + sLineBreak + sLineBreak + '%s';
  SLicenciaNoEstablecidaSinNif =
    'No se ha establecido licencia.' + sLineBreak + sLineBreak +
    'No hay NIF de empresa configurado.' + sLineBreak +
    'Mientras no haya NIF de empresa, no se exigirá licencia.';
  SErrorEstablecerLicencia =
    'No se pudo establecer la licencia.' + sLineBreak + sLineBreak + '%s';
  SModoDemo = 'Modo DEMO: limitado a %d facturas al día.';
  SCancelacionSolicitada =
    'La cancelación ya está solicitada. Espere a que termine la sentencia ' +
    'actual.';
  SPreguntaCancelarOperacion =
    'Hay una operación en curso moviendo datos.' + sLineBreak +
    sLineBreak + '¿Desea abandonar la operación en curso?';
  SOperacionCancelada = 'Operación cancelada.';
  SCopiaSeguridadGuardada =
    'La copia se guardó exitosamente';
  SErrorCrearCopiaSeguridad =
    'No se pudo crear la copia de seguridad.' + sLineBreak + '%s';
  SErrorSintaxisComandoCopiaSeguridad =
    'Uso: fzam.exe /copiaseguridad "<ruta>.crypt" ["contraseña"].';
  SErrorRutaComandoCopiaSeguridad =
    'La ruta de la copia de seguridad no es válida.';
  SErrorExtensionComandoCopiaSeguridad =
    'El destino de la copia debe tener extensión .crypt.';
  SErrorClaveComandoCopiaSeguridad =
    'La contraseña cifrada de la copia no es válida.';
  SErrorConexionComandoCopiaSeguridad =
    'No se pudo preparar la conexión para la copia: %s';
  SErrorPublicarComandoCopiaSeguridad =
    'No se pudo guardar la copia en su destino: %s';
  SInfoComandoCopiaSeguridadCompletado =
    'Copia de seguridad completada: %s';
  SRestauracionCancelada =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente restaurada.';
  SErrorRestaurarCopiaSeguridad =
    'Hubo problemas al restaurar la copia.' + sLineBreak + '%s';
  SErrorContrasenaCopiaVacia =
    'La contraseña de la copia no puede estar vacía.';
  SErrorTipoRestauracionNoPermitido =
    'Los usuarios no administradores sólo pueden restaurar copias o ' +
    'scripts cifrados (*.crypt).';
  SPreguntaReemplazarFichero =
    '¿Desea reemplazar el fichero existente?';
  SCopiaSeguridadCancelada = 'La copia se canceló';
  SCargaScriptCancelada = 'Se canceló la carga del script.';
  SUsuarioNoExiste = 'El nombre de usuario no existe';
  SDescripcionParametroIdioma =
    'Idioma de la interfaz (es-ES, en-GB, ca-ES o zh-CN; ' +
    'qps-ploc para pruebas)';
  SErrorSeleccionIdiomaNoAplicado =
    'No se pudo aplicar el idioma %s:' + sLineBreak + '%s';
  SErrorProveedorEdicionParametrosNoConfigurado =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosAplicacionEditablesNoConfigurados =
    'No se han configurado los parámetros de aplicación editables.';
  SInfoParametrosGuardados =
    'Se guardaron %d parámetros para: %s';
  SAvisoParametrosRestringidosIgnorados =
    'Se ignoraron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SAvisoParametrosRestringidosNoGuardados =
    'No se guardaron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SInfoSinCambiosParametros =
    'No se detectaron cambios para guardar.';
  SInfoLayoutGuardado = 'Layout guardado.';
  SPreguntaSalirSinGuardar =
    '¿Seguro que desea salir sin guardar?';
  SAvisoSinUsuariosParametrosGuardados =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuario = 'Cambiar usuario';
  SSolicitudCambiarUsuario =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Introduce el nombre de usuario:';
  SErrorUsuarioNoEncontrado = 'Usuario no encontrado: %s';
  SErrorContextoInicioSesionNoProporcionado =
    'No se ha proporcionado el contexto de inicio de sesión.';
  SErrorParametrosSinEstadoLicencia =
    'Los parámetros no admiten el estado de licencia.';
  SErrorParametrosAplicacionSinContratoEdicion =
    'Los parámetros de aplicación no ofrecen el contrato de edición.';
  SErrorServicioConexionesNoDisponible =
    'No está disponible el servicio de conexiones.';
  SCertificadoQuedaMenosUnDia = 'queda menos de 1 día';
  SCertificadoQuedaUnDia = 'queda 1 día';
  SCertificadoQuedanDias = 'quedan %d días';
  SAvisoCertificadoCaducado =
    'certificado electrónico caducado el %s.';
  SAvisoCertificadoProximoCaducar =
    'certificado electrónico caduca el %s (%s).';
  SAvisoCertificadosCaducidad =
    'Atención: hay certificados electrónicos próximos a caducar o ya ' +
    'caducados.' + sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Revise la ficha de empresa y renueve el certificado.';
  SAvisoCargaPermisosRestringidos =
    'No se pudieron cargar los permisos.' + sLineBreak +
    'El acceso se ha restringido por seguridad.' + sLineBreak +
    'Revise el registro de la aplicación en:' + sLineBreak + '%s';
  SInfoCopiaSeguridadGuardada =
    'La copia se guardó exitosamente.';
  SAvisoRestauracionCancelada =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente modificada.';
  SErrorEjecutarScript =
    'Hubo problemas al ejecutar el script.' + sLineBreak + '%s';
  SPreguntaSalirAplicacion =
    '¿Quiere salir de la aplicación Fzam?';
  SPreguntaCopiaSeguridadAntesDDL =
    'ATENCIÓN: El script contiene sentencias DDL (modifican la estructura ' +
    'de la base de datos).' + sLineBreak +
    'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
    'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
    '¿Deseas realizar una copia de seguridad antes de continuar?';
  SPreguntaCopiaAntesRestaurarCifrada =
    'La copia cifrada puede reemplazar datos y estructura de la base de ' +
    'datos.' + sLineBreak + sLineBreak +
    '¿Deseas realizar una copia de seguridad antes de continuar?';
  SInfoScriptCancelado =
    'Operación cancelada. El script no se ejecutará.';
  SErrorAbrirDireccion =
    'No se ha podido abrir la dirección: %s';
  SErrorBBDDDuplicado =
    'Ya existe un registro con ese valor (entrada duplicada).';
  SErrorBBDDCamposObligatorios =
    'Hay campos obligatorios sin rellenar.';
  SErrorBBDDCampoDesconocido =
    'Campo desconocido en la consulta SQL: %s';
  SErrorBBDDTablaNoExiste =
    'La tabla consultada no existe en la base de datos: %s';
  SErrorBBDDSinPermisos =
    'No tiene permisos suficientes para realizar esta acción en la base ' +
    'de datos.';
  SErrorBBDDClaveForaneaNoExiste =
    'El valor no existe en la tabla relacionada (clave foránea).';
  SErrorBBDDRegistroDependiente =
    'No se puede eliminar: existen registros que dependen de este.';
  SErrorBBDDDatoDemasiadoLargo =
    'El dato introducido es demasiado largo para el campo.';
  SErrorBBDDCredencialesIncorrectas =
    'Acceso denegado: usuario o contraseña incorrectos.';
  SErrorBBDDConexionServidor =
    'No se puede conectar al servidor MySQL. Comprueba la red y el puerto.';
  SErrorBBDDConexionPerdida =
    'La conexión con el servidor MySQL se ha perdido.';
  SErrorBBDDConexionPerdidaConsulta =
    'Se perdió la conexión durante la ejecución de la consulta.';
  SErrorBBDDTimeoutBloqueo =
    'El servidor está ocupado (Tiempo de espera de bloqueo). Inténtalo de ' +
    'nuevo.';
  SErrorBBDDDeadlock =
    'Se ha producido un bloqueo cruzado (Deadlock). Inténtalo de nuevo.';
  SErrorBBDDTablaYaExiste =
    'La tabla o vista ya existe en la base de datos %s';
  SErrorBBDDProcedimientoYaExiste =
    'El procedimiento o función ya existe en la base de datos.' +
    sLineBreak + 'Detalle del servidor: %s';
  SErrorBBDDGenerico =
    'Error en base de datos [%d]:' + sLineBreak + '%s';
  SErrorNombreUsuario =
    '%s no es un valor de registro válido para el campo usuario';
  SErrorUsuarioCoincideGrupo =
    'El usuario %s coincide con un grupo del sistema';
  SErrorConexionPrincipalTrabajoNoDisponible =
    'No hay conexión principal para crear una conexión de trabajo.';
  SErrorOperacionCanceladaUsuario =
    'Operación cancelada por el usuario.';
  SErrorRestauracionEstructuraIncompleta =
    'La restauración terminó, pero la estructura mínima no está completa.' +
    sLineBreak + '%s';
  SErrorNombreBBDDDestinoVacio =
    'El nombre de la BBDD de destino está vacío.';
  SErrorFicheroCopiaNoExiste =
    'No existe el fichero de copia: %s';
  SErrorDesencriptarCopia =
    'No se pudo desencriptar la copia. Revise la contraseña o seleccione ' +
    'un fichero SQL sin cifrar.';
  SErrorLimitePeticionesCripto =
    'Rate limit alcanzado (429). Espera un momento.';
  SErrorRestauracionNoFinalizada =
    'La restauración no finalizó correctamente.';
  SErrorDialogoPermisosLayoutNoRegistrado =
    'No se ha registrado el diálogo de permisos de layout.';
  SErrorNifEmpresaLicenciaNoConfigurado =
    'No hay NIF de empresa configurado.';
  SInfoLicenciaSinNifEmpresa =
    'No hay NIF de empresa; no se exige licencia.';
  SErrorLicenciaNoEncontrada =
    'No se encontró licencia de aplicación.';
  SInfoLicenciaValida =
    'Licencia de aplicación válida.';
  SErrorLicenciaNifsNoCoinciden =
    'La licencia de aplicación no coincide con los NIF de empresa ' +
    'configurados.';
  SErrorParametrosAplicacionNoProporcionados =
    'No se han proporcionado los parámetros de aplicación.';
  SErrorServicioPerfilesNoProporcionado =
    'No se ha proporcionado el servicio de perfiles de usuario.';
  SErrorCargarPerfilParametros =
    'No se pudo cargar el perfil de parámetros "%s".';
  SErrorConexionPermisosNoDisponible =
    'No hay conexión disponible para cargar los permisos.';
  SErrorConexionBbddConExcepcion =
    '%s%s Mensaje: %s';
  SErrorServicioPerfilesUsuarioNoConfigurado =
    'No se ha configurado el servicio de perfiles de usuario.';
  SPreguntaIgnorarErrorScript =
    'Ocurrió un error ejecutando el script.' + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorMetadatoSinScript =
    'No hay estructura o script disponible para este metadato.';
  SPreguntaIgnorarErrorComandoScript =
    'Ocurrió un error ejecutando %s.' + sLineBreak +
    'Detalle: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorPermisoInsertarRegistro =
    'No tienes permiso para insertar registros en esta pantalla.';
  SErrorPermisoModificarRegistro =
    'No tienes permiso para modificar registros en esta pantalla.';
  SErrorPermisoGuardarRegistro =
    'No tienes permiso para guardar este registro.';
  SErrorPermisoBorrarRegistro =
    'No tienes permiso para borrar registros en esta pantalla.';
  SErrorNodoPermisosNoSeleccionado =
    'Selecciona primero un nodo del arbol.';
  SErrorOrigenDestinoPermisosNoSeleccionados =
    'Selecciona un origen y un destino.';
  SErrorOrigenDestinoPermisosIguales =
    'El origen y el destino no pueden ser el mismo.';
  SInfoModoReemplazarPermisos =
    'Se reemplazaran todos los permisos del destino.';
  SInfoModoCombinarPermisos =
    'Se agregaran o actualizaran los permisos en el destino.';
  SInfoAlcancePermisosMenu =
    'Alcance: solo permisos de menu.';
  SInfoAlcanceTodosPermisos =
    'Alcance: todos los permisos.';
  SPreguntaCopiarPermisos =
    'Copiar permisos de "%s" a "%s"?' + sLineBreak +
    '%s' + sLineBreak + '%s';
  SInfoPermisosCopiados =
    '%d permisos copiados de "%s" a "%s".';
  SErrorContrasenasNoCoinciden =
    'Las contraseñas no coinciden';
  SInfoLogGuardado =
    'Log guardado en %s';
  SErrorPermisoAbrirCajon =
    'No tiene permiso para abrir el cajón.';
  // R01 - Diálogos de copias de seguridad y scripts
  STituloCargarScript = 'Cargar script';
  STituloGuardarCopiaSeguridad = 'Guardar copia de seguridad';
  STituloCargarCopiaSeguridad = 'Cargar copia de seguridad';
  STituloRestaurarCopiaEjecutarScript =
    'Restaurar copia o ejecutar script';
  SCaptionFiltroCopiasSqlEncriptadas = 'Copias SQL o encriptadas';
  SCaptionFiltroCopiasCifradas = 'Copias cifradas';
  SCaptionFiltroArchivosSql = 'Archivos SQL';
  SCaptionFiltroCopiasSqlCifradas = 'Copias SQL o cifradas';
  SCaptionFiltroCopiasScriptsCifrados =
    'Copias o scripts cifrados';
  SCaptionPreparandoCopiaSeguridad =
    'Preparando copia de seguridad...';
  SCaptionPreparandoRestauracion = 'Preparando restauración...';
  // R06 - Generador de procesos
  STituloAbrirScriptSql = 'Abrir Script SQL';
  SCaptionFiltroScriptsSql =
    'Scripts SQL (*.sql)|*.sql|Archivos de texto (*.txt)|*.txt|' +
    'Todos los archivos (*.*)|*.*';
  // R07 - Árbol de permisos
  SCaptionModoCombinarPermisos = 'Combinar (agregar y actualizar)';
  SCaptionModoReemplazarPermisos = 'Reemplazar todos los del destino';
  SCaptionAvisoSujetoAdministrador =
    'Aviso: este sujeto es administrador; en ejecucion tiene TODOS los ' +
    'permisos, se marque lo que se marque aqui.';
  // R09 - Contraseña de copias de seguridad
  STituloProtegerCopiaSeguridad = 'Proteger copia de seguridad';
  SCaptionCopiaSeCifrara =
    'La copia se cifrará. Guarde esta contraseña: será necesaria ' +
    'para restaurarla.';
  STituloAbrirCopiaCifrada = 'Abrir copia cifrada';
  SCaptionIntroduzcaContrasenaCopia =
    'Introduzca la contraseña con la que se protegió la copia.';
  // R11 - Log de scripts
  STituloGuardarLogComo = 'Guardar log como...';
  SCaptionFiltroArchivosSqlTexto =
    'Archivos SQL (*.sql)|*.sql|Archivos de texto (*.txt)|*.txt|' +
    'Todos los archivos (*.*)|*.*';
  SCaptionFiltroArchivosTexto =
    'Archivos de texto (*.txt)|*.txt|Todos los archivos (*.*)|*.*';
implementation

end.
