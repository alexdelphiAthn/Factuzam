{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompra                                            }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de las operaciones de recepción de pedidos de compra. Mantiene    }
{    las firmas públicas históricas y delega la persistencia mediante         }
{    IPedidosCompra.                                                           }
{******************************************************************************}
unit inLibPedidosCompra;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni, inLibGridPivoteCompra,
  inLibPedidosCompraIntf;

type
  TParametrosRecepcionPedidoCompra =
    inLibPedidosCompraIntf.TParametrosRecepcionPedidoCompra;
  TResultadoRecepcionPedidoCompra =
    inLibPedidosCompraIntf.TResultadoRecepcionPedidoCompra;

// Sincroniza los pendientes de recibir con el estado actual del pedido.
procedure GenerarPdteRecibirDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, AUsuario: string);

// Borra los pendientes del pedido o únicamente los de una línea.
procedure BorrarPdteRecibirDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc: string;
  const ALinea: string = '');

// Crea un albarán con todo lo pendiente del almacén indicado.
function CrearAlbaranDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;

// Crea un albarán con las cantidades explícitas de las celdas.
function CrearAlbaranDesdePedidoConCantidades(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;

// Devuelve la cantidad pendiente total del pedido.
function CalcularPendienteTotal(AConn: TUniConnection;
  const ASeriePedc, ANumPedc: string): Double;

// Incorpora todo lo pendiente a un albarán ya existente.
function IncorporarAlbaranDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;

// Incorpora las cantidades explícitas a un albarán ya existente.
function IncorporarAlbaranDesdePedidoConCantidades(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;

// Ejecuta la recepción completa dentro de una única transacción.
function EjecutarRecepcionPedidoCompra(AConn: TUniConnection;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;

implementation

procedure GenerarPdteRecibirDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, AUsuario: string);
begin
  TFabricaPedidosCompra.Crear(AConn).
    GenerarPdteRecibirDesdePedido(
      ASeriePedc, ANumPedc, AUsuario);
end;

procedure BorrarPdteRecibirDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ALinea: string);
begin
  TFabricaPedidosCompra.Crear(AConn).
    BorrarPdteRecibirDesdePedido(
      ASeriePedc, ANumPedc, ALinea);
end;

function CrearAlbaranDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    CrearAlbaranDesdePedido(
      ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ANumAlbc, AMensaje);
end;

function CrearAlbaranDesdePedidoConCantidades(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    CrearAlbaranDesdePedidoConCantidades(
      ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ACeldas, ANumAlbc, AMensaje);
end;

function CalcularPendienteTotal(AConn: TUniConnection;
  const ASeriePedc, ANumPedc: string): Double;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    CalcularPendienteTotal(ASeriePedc, ANumPedc);
end;

function IncorporarAlbaranDesdePedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    IncorporarAlbaranDesdePedido(
      ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
      AIdPvTemporada, AMensaje);
end;

function IncorporarAlbaranDesdePedidoConCantidades(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    IncorporarAlbaranDesdePedidoConCantidades(
      ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
      AIdPvTemporada, ACeldas, AMensaje);
end;

function EjecutarRecepcionPedidoCompra(AConn: TUniConnection;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Result := TFabricaPedidosCompra.Crear(AConn).
    EjecutarRecepcionPedidoCompra(AParametros, AResultado);
end;

end.
