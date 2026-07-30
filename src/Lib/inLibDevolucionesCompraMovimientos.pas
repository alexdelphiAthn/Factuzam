{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDevolucionesCompraMovimientos                            }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fachada sin SQL para generar y revertir movimientos de almacen de         }
{    devoluciones de compra. El adaptador UniDAC se registra en la fabrica     }
{    del contrato.                                                             }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientos;

interface

uses
  Uni;

// Genera movimientos de salida (TIPO_DOC_MOV='DC', TIPO_MOV='S') para
// todas las celdas con cantidad > 0 de la devolucion, o para sus lineas.
procedure GenerarMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                               const ASerieDevc, ANumDevc,
                                                     AUsuario: string);

// Revierte los movimientos de la devolucion y recalcula el stock/PMP de
// los SKU afectados. Es idempotente si no existen movimientos.
procedure RevertirMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                                const ASerieDevc, ANumDevc,
                                                      AUsuario: string);

implementation

uses
  inLibDevolucionesCompraMovimientosIntf;

procedure GenerarMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                               const ASerieDevc, ANumDevc,
                                                     AUsuario: string);
begin
  TFabricaMovimientosDevolucionCompra.Crear(AConn).GenerarDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

procedure RevertirMovimientosDesdeDevolucionCompra(AConn: TUniConnection;
                                                const ASerieDevc, ANumDevc,
                                                      AUsuario: string);
begin
  TFabricaMovimientosDevolucionCompra.Crear(AConn).RevertirDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

end.
