{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraRecepcion                                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordinación transaccional de la recepción de pedidos de compra.         }
{******************************************************************************}
unit UniDataPedidosCompraRecepcion;

interface

uses
  Uni, inLibPedidosCompraIntf;

function CrearRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IRecepcionPedidoCompra;

implementation

uses
  UniDataPedidosCompraCreacionAlbaran,
  UniDataPedidosCompraIncorporacionAlbaran;

type
  TRecepcionPedidoCompraUniDAC = class(
    TInterfacedObject, IRecepcionPedidoCompra)
  private
    FConexion     : TUniConnection;
    FCreacion     : ICreacionAlbaranPedidoCompra;
    FIncorporacion: IIncorporacionAlbaranPedidoCompra;
  public
    constructor Create(AConexion: TUniConnection);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;

constructor TRecepcionPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FCreacion := CrearCreacionAlbaranPedidoCompraUniDAC(AConexion);
  FIncorporacion :=
    CrearIncorporacionAlbaranPedidoCompraUniDAC(AConexion);
end;

function TRecepcionPedidoCompraUniDAC.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
var
  bTransaccionPropia: Boolean;
  bUsarCeldas       : Boolean;
begin
  AResultado.SerieAlbaran := '';
  AResultado.NumeroAlbaran := '';
  AResultado.Mensaje := '';
  bUsarCeldas := Length(AParametros.Celdas) > 0;
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    if AParametros.Incorporar then
    begin
      AResultado.SerieAlbaran := AParametros.SerieAlbaranDestino;
      AResultado.NumeroAlbaran := AParametros.NumeroAlbaranDestino;
      if bUsarCeldas then
        Result := FIncorporacion.
          IncorporarAlbaranDesdePedidoConCantidades(
            AParametros.SeriePedido,
            AParametros.NumeroPedido,
            AParametros.CodigoAlmacen,
            AParametros.SerieAlbaranDestino,
            AParametros.NumeroAlbaranDestino,
            AParametros.Usuario,
            AParametros.IdPvTemporada,
            AParametros.Celdas,
            AResultado.Mensaje)
      else
        Result := FIncorporacion.IncorporarAlbaranDesdePedido(
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaranDestino,
          AParametros.NumeroAlbaranDestino,
          AParametros.Usuario,
          AParametros.IdPvTemporada,
          AResultado.Mensaje);
    end
    else
    begin
      AResultado.SerieAlbaran := AParametros.SerieAlbaran;
      if bUsarCeldas then
        Result := FCreacion.CrearAlbaranDesdePedidoConCantidades(
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaran,
          AParametros.Usuario,
          AParametros.ReferenciaProveedor,
          AParametros.FechaRecepcion,
          AParametros.IdPvTemporada,
          AParametros.Celdas,
          AResultado.NumeroAlbaran,
          AResultado.Mensaje)
      else
        Result := FCreacion.CrearAlbaranDesdePedido(
          AParametros.SeriePedido,
          AParametros.NumeroPedido,
          AParametros.CodigoAlmacen,
          AParametros.SerieAlbaran,
          AParametros.Usuario,
          AParametros.ReferenciaProveedor,
          AParametros.FechaRecepcion,
          AParametros.IdPvTemporada,
          AResultado.NumeroAlbaran,
          AResultado.Mensaje);
    end;
    if Result then
    begin
      if bTransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    end
    else if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
  except
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function CrearRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IRecepcionPedidoCompra;
begin
  Result := TRecepcionPedidoCompraUniDAC.Create(AConexion);
end;

end.
