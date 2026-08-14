{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraFlujoTransaccion                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta una conexión UniDAC al contrato de unidad de trabajo.             }
{******************************************************************************}
unit UniDataPedidosCompraFlujoTransaccion;

interface

uses
  Uni,
  inLibPedidosCompraPresentacionOperacion;

function CrearUnidadTrabajoRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoRecepcionPedidoCompra;

implementation

uses
  System.SysUtils,
  inLibPrestaShopColaSenal;

type
  TUnidadTrabajoRecepcionPedidoCompraUniDAC = class(
    TInterfacedObject, IUnidadTrabajoRecepcionPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

constructor TUnidadTrabajoRecepcionPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TUnidadTrabajoRecepcionPedidoCompraUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Confirmar;
begin
  FConexion.Commit;
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

function CrearUnidadTrabajoRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoRecepcionPedidoCompra;
begin
  Result := TUnidadTrabajoRecepcionPedidoCompraUniDAC.Create(AConexion);
end;

end.
