{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaPantallaHistoricos                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta la transacción UniDAC usada al guardar perfiles de históricos.    }
{******************************************************************************}
unit UniDataCajaPantallaHistoricos;

interface

uses
  Uni,
  inLibPerfilesUsuarioIntf,
  inLibCajaPantallaHistoricosIntf;

function CrearGrabadorPerfilesHistoricoCaja(
  AConexion: TUniConnection;
  const AEscritor: IEscritorPerfilesUsuario
): IGrabadorPerfilesHistoricoCaja;

implementation

uses
  System.SysUtils,
  inLibCajaPantallaHistoricos;

type
  TUnidadTrabajoPerfilesCajaUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoPerfilesCaja)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

resourcestring
  SErrorConexionPerfilesHistoricoCajaNoAsignada =
    'La conexión para grabar perfiles de históricos no está asignada.';

constructor TUnidadTrabajoPerfilesCajaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise Exception.Create(SErrorConexionPerfilesHistoricoCajaNoAsignada);
  FConexion := AConexion;
end;

destructor TUnidadTrabajoPerfilesCajaUniDAC.Destroy;
begin
  FConexion := nil;
  inherited;
end;

procedure TUnidadTrabajoPerfilesCajaUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoPerfilesCajaUniDAC.Confirmar;
begin
  FConexion.Commit;
end;

procedure TUnidadTrabajoPerfilesCajaUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

function CrearGrabadorPerfilesHistoricoCaja(
  AConexion: TUniConnection;
  const AEscritor: IEscritorPerfilesUsuario
): IGrabadorPerfilesHistoricoCaja;
var
  oUnidadTrabajo: IUnidadTrabajoPerfilesCaja;
begin
  oUnidadTrabajo := TUnidadTrabajoPerfilesCajaUniDAC.Create(AConexion);
  Result := TGrabadorPerfilesHistoricoCaja.Create(
    oUnidadTrabajo,
    AEscritor);
end;

end.
