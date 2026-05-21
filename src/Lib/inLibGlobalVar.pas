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
     UniDataConn,cxMemo, inMtoPrincipal;
//type
// TUpdateTotalEvent = procedure(Sender: TObject; NuevoTotal: Currency) of
// object;

var
  odmPerfiles:TdmPerfiles;
  oConn      :TUniConnection;
  odmConn    :TdmConn;
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

implementation

initialization
  oAppName         := 'Fzam';
  oVersion         := '1.0.15.202605210120.alpha';
  oUser            := 'No definido';
  oGroup           := 'No definido';
  oNomImpresoraCaja:='';
  orootGroup       := 'N';
  odmPerfiles      := nil;
  odmConn          := nil;
  oConn            := nil;
  oAll             := 'Todos';
end.
