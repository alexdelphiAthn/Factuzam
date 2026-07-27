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
implementation


end.
