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
{    Conexión oConn, usuario actual y parametrización en memoria.              }
{******************************************************************************}
unit inLibGlobalVar;

interface

uses Uni,
     UniDataPerfiles,
     UniDataConn,cxMemo, inMtoPrincipal,
     inLibInformesGuiasCache,
     inLibConfigCampos;
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
  odmPerfiles    :TdmPerfiles;
  oInfGuiasCache :TInformesGuiasCache;
  oConn          :TUniConnection;
  odmConn        :TdmConn;
  oMemoSQL   :TcxMemo;
  ofrmMto2   :TfrmMtoPrincipal;
  oNomImpresoraCaja:String;
  oUser      :String;
  oGroup     :String;
  orootGroup :String;
  oEmpresa   :String;
  oAlmacen   :String;
  oCaja      :String;
  oAppName   :String;
  oVersion   :String;
  oAll       :string;
  oLogSesion :TLogSesionProc;

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
  oVersion         := '1.0.15.202606050020.alpha';
  oUser            := 'No definido';
  oGroup           := 'No definido';
  oNomImpresoraCaja:='';
  orootGroup       := 'N';
  odmPerfiles      := nil;
  oInfGuiasCache   := nil;
  odmConn          := nil;
  oConn            := nil;
  oAll             := 'Todos';
  oLogSesion       := nil;
end.
