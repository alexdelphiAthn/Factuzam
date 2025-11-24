{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
implementation


end.
