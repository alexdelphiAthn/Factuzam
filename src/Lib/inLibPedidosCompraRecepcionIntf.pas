{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraRecepcionIntf                               }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto para ejecutar una recepción completa de pedido de compra.          }
{******************************************************************************}
unit inLibPedidosCompraRecepcionIntf;
interface
uses
  inLibGridPivoteCompraTipos;
type
  TParametrosRecepcionPedidoCompra = record
    SeriePedido: string;
    NumeroPedido: string;
    CodigoAlmacen: string;
    SerieAlbaran: string;
    SerieAlbaranDestino: string;
    NumeroAlbaranDestino: string;
    Usuario: string;
    ReferenciaProveedor: string;
    FechaRecepcion: TDateTime;
    IdPvTemporada: Integer;
    Incorporar: Boolean;
    Celdas: TArray<TCeldaARecibir>;
  end;
  TResultadoRecepcionPedidoCompra = record
    SerieAlbaran: string;
    NumeroAlbaran: string;
    Mensaje: string;
  end;
  IRecepcionPedidoCompra = interface
    ['{15EC0714-1FBD-4D5F-A954-E4367F6285E7}']
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;
implementation
end.
