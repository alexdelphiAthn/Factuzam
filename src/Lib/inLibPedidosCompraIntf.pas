{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de las operaciones de recepción de pedidos de compra y su          }
{    fábrica registrable.                                                      }
{******************************************************************************}
unit inLibPedidosCompraIntf;

interface

uses
  Uni, inLibGridPivoteCompra;

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
  IPedidosCompra = interface
    ['{1312567D-13D8-43B2-944F-3515347A25EF}']
    procedure GenerarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc, AUsuario: string);
    procedure BorrarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc: string;
      const ALinea: string = '');
    function CrearAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      out ANumAlbc, AMensaje: string): Boolean;
    function CrearAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out ANumAlbc, AMensaje: string): Boolean;
    function CalcularPendienteTotal(
      const ASeriePedc, ANumPedc: string): Double;
    function IncorporarAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      out AMensaje: string): Boolean;
    function IncorporarAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out AMensaje: string): Boolean;
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;
  TFabricaCrearPedidosCompra = function(
    AConexion: TUniConnection): IPedidosCompra;
  // El adaptador UniData* registra la persistencia en su initialization.
  TFabricaPedidosCompra = class
  private
    class var FFabrica: TFabricaCrearPedidosCompra;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearPedidosCompra);
    class function Crear(
      AConexion: TUniConnection): IPedidosCompra;
  end;

implementation

uses
  System.SysUtils, inLibMsgCompras;

class procedure TFabricaPedidosCompra.Registrar(
  AFabrica: TFabricaCrearPedidosCompra);
begin
  FFabrica := AFabrica;
end;

class function TFabricaPedidosCompra.Crear(
  AConexion: TUniConnection): IPedidosCompra;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(SErrorPedidosCompraNoRegistrados);
  Result := FFabrica(AConexion);
end;

end.
