{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGlobalVar                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Estado global del programa.                                               }
{    UI compartida y parametrización en memoria.                               }
{******************************************************************************}
unit inLibGlobalVar;

interface

uses cxMemo, inMtoPrincipal,
     inLibInformesGuiasCache,
     inLibLicenciaAplicacion;
//type
// TUpdateTotalEvent = procedure(Sender: TObject; NuevoTotal: Currency) of
// object;

type
  // Callback de log para depurar el flujo de Sesiones de Compra
  // (alta de linea, posts, persistir celda, crear articulos...). El form
  // de sesiones asigna aqui un metodo que vuelca al memo de su pestania
  // 'Log' y lo nilea al cerrarse. Cualquier punto del DM o de la lib
  // puede llamar a LogSes(...) sin tener que conocer al form.
  TLogSesionProc = procedure(const S: string) of object;

var
  oInfGuiasCache :TInformesGuiasCache;
  oMemoSQL   :TcxMemo;
  ofrmMto2   :TfrmMtoPrincipal;
  oNomImpresoraCaja:String;
  oAppName   :String;
  oVersion   :String;
  oAll       :string;
  oLogSesion :TLogSesionProc;
  oLicenciaAplicacionComprobada :Boolean;
  oLicenciaAplicacionBBDD       :String;
  oLicenciaAplicacionEstado     :TEstadoLicenciaAplicacion;
  oLicenciaAplicacionMensaje    :String;
  // Se pone a True cuando la ventana principal empieza a cerrarse. Las
  // tareas en segundo plano (TTask de los mantenimientos) lo consultan para
  // no arrancar trabajo nuevo ni tocar formularios que se estan destruyendo
  // durante el apagado.
  oCerrandoApp :Boolean;

// Helper: emite un mensaje al log de sesiones si esta enganchado. No-op
// si nadie tiene un memo activo.
procedure LogSes(const S: string);

implementation

procedure LogSes(const S: string);
begin
  if Assigned(oLogSesion) then
    oLogSesion(S);
end;

initialization
  oAppName         := 'Fzam';
  oVersion         := '1.0.15.202606260100.alpha';
  oNomImpresoraCaja:='';
  oInfGuiasCache   := nil;
  oAll             := 'Todos';
  oLogSesion       := nil;
  oLicenciaAplicacionComprobada := False;
  oLicenciaAplicacionBBDD := '';
  oLicenciaAplicacionEstado := elaInvalida;
  oLicenciaAplicacionMensaje := '';
  oCerrandoApp     := False;
end.
