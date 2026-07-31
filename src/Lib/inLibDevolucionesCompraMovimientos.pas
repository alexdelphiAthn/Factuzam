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
{    devoluciones de compra con la persistencia inyectada.                     }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientos;

interface

uses
  inLibDevolucionesCompraMovimientosIntf;

// Genera movimientos de salida (TIPO_DOC_MOV='DC', TIPO_MOV='S') para
// todas las celdas con cantidad > 0 de la devolucion, o para sus lineas.
procedure GenerarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);

// Revierte los movimientos de la devolucion y recalcula el stock/PMP de
// los SKU afectados. Es idempotente si no existen movimientos.
procedure RevertirMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);

implementation

procedure GenerarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  AMovimientos.GenerarDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

procedure RevertirMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  AMovimientos.RevertirDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

end.
