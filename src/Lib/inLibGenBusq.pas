{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenBusq                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lanzamiento genérico de formularios de búsqueda.                          }
{    Devuelve el dataset o el valor seleccionado por el usuario.               }
{******************************************************************************}
unit inLibGenBusq;

interface

uses
  Forms, Uni, DBAccess;

type
  TEjecutorBusqueda = class
  public
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption: string;
                                    ADataSet: TCustomDADataSet;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload; virtual; abstract;
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption, ASql,
                                          ACampoResultado: string;
                                    out AValorDevuelto: string;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload; virtual; abstract;
  end;

  TClaseEjecutorBusqueda = class of TEjecutorBusqueda;

  TBusquedaUtils = class
  private
    class var FClaseEjecutor: TClaseEjecutorBusqueda;
  public
    class procedure RegistrarEjecutor(AClase: TClaseEjecutorBusqueda);
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption: string;
                                    ADataSet: TCustomDADataSet;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload;
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption, ASql,
                                          ACampoResultado: string;
                                    out AValorDevuelto: string;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload;
  end;

implementation

uses
  SysUtils, inLibMsgComun;

class procedure TBusquedaUtils.RegistrarEjecutor(
  AClase: TClaseEjecutorBusqueda);
begin
  FClaseEjecutor := AClase;
end;

class function TBusquedaUtils.EjecutarBusqueda(AConexion: TUniConnection;
  const ACaption: string; ADataSet: TCustomDADataSet; const AName: string;
  AParentForm: TCustomForm): Boolean;
begin
  if not Assigned(FClaseEjecutor) then
    raise Exception.Create(SErrorEjecutorBusquedasNoRegistrado);
  Result := FClaseEjecutor.EjecutarBusqueda(
    AConexion, ACaption, ADataSet, AName, AParentForm);
end;

class function TBusquedaUtils.EjecutarBusqueda(AConexion: TUniConnection;
  const ACaption, ASql, ACampoResultado: string;
  out AValorDevuelto: string; const AName: string;
  AParentForm: TCustomForm): Boolean;
begin
  if not Assigned(FClaseEjecutor) then
    raise Exception.Create(SErrorEjecutorBusquedasNoRegistrado);
  Result := FClaseEjecutor.EjecutarBusqueda(
    AConexion, ACaption, ASql, ACampoResultado, AValorDevuelto, AName,
    AParentForm);
end;

end.
