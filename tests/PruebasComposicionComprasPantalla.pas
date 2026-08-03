{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComposicionComprasPantalla                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza los límites transaccionales de las pantallas de compras.      }
{******************************************************************************}
unit PruebasComposicionComprasPantalla;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComposicionComprasPantalla = class
  public
    [Test]
    procedure RecepcionCreacion_RechazoRevierte;
    [Test]
    procedure RecepcionCreacion_ExcepcionRevierte;
    [Test]
    procedure RecepcionCreacion_ExitoConfirma;
    [Test]
    procedure RecepcionIncorporacion_RechazoRevierte;
    [Test]
    procedure RecepcionIncorporacion_ExcepcionRevierte;
    [Test]
    procedure RecepcionIncorporacion_ExitoConfirma;
    [Test]
    procedure DevolucionStock_RechazoRevierte;
    [Test]
    procedure DevolucionStock_ExcepcionRevierte;
    [Test]
    procedure DevolucionStock_ExitoConfirma;
    [Test]
    procedure Recepcion_TransaccionActivaNoAdministra;
    [Test]
    procedure DevolucionStock_TransaccionActivaNoAdministra;
  end;

implementation

uses
  System.SysUtils,
  inLibComprasPantallaIntf,
  inLibComprasPantallaTransaccion,
  inLibDevolucionesCompraStock,
  inLibPedidosCompraIntf;

type
  TComportamientoColaborador = (
    ccExito,
    ccRechazo,
    ccExcepcion);

  EExcepcionColaboradorCompras = class(Exception);

  TUnidadTrabajoComprasFalsa = class(
    TInterfacedObject,
    IUnidadTrabajoComprasPantalla)
  private
    FActiva: Boolean;
    FConfirmaciones: Integer;
    FInicios: Integer;
    FReversiones: Integer;
  public
    constructor Create(AActiva: Boolean);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
    property Activa: Boolean read FActiva;
    property Confirmaciones: Integer read FConfirmaciones;
    property Inicios: Integer read FInicios;
    property Reversiones: Integer read FReversiones;
  end;

  TRecepcionPedidoCompraFalsa = class(
    TInterfacedObject,
    IRecepcionPedidoCompra)
  private
    FComportamiento: TComportamientoColaborador;
    FLlamadas: Integer;
    FUltimaIncorporacion: Boolean;
  public
    constructor Create(AComportamiento: TComportamientoColaborador);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
    property Llamadas: Integer read FLlamadas;
    property UltimaIncorporacion: Boolean read FUltimaIncorporacion;
  end;

  TStockDevolucionCompraFalso = class(
    TInterfacedObject,
    IPersistenciaStockDevolucionCompra)
  private
    FComportamiento: TComportamientoColaborador;
    FLlamadas: Integer;
  public
    constructor Create(AComportamiento: TComportamientoColaborador);
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
    property Llamadas: Integer read FLlamadas;
  end;

constructor TUnidadTrabajoComprasFalsa.Create(AActiva: Boolean);
begin
  inherited Create;
  FActiva := AActiva;
end;

function TUnidadTrabajoComprasFalsa.EstaActiva: Boolean;
begin
  Result := FActiva;
end;

procedure TUnidadTrabajoComprasFalsa.Iniciar;
begin
  Inc(FInicios);
  FActiva := True;
end;

procedure TUnidadTrabajoComprasFalsa.Confirmar;
begin
  Inc(FConfirmaciones);
  FActiva := False;
end;

procedure TUnidadTrabajoComprasFalsa.Revertir;
begin
  Inc(FReversiones);
  FActiva := False;
end;

constructor TRecepcionPedidoCompraFalsa.Create(
  AComportamiento: TComportamientoColaborador);
begin
  inherited Create;
  FComportamiento := AComportamiento;
end;

function TRecepcionPedidoCompraFalsa.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Inc(FLlamadas);
  FUltimaIncorporacion := AParametros.Incorporar;
  AResultado := Default(TResultadoRecepcionPedidoCompra);
  if FComportamiento = ccExcepcion then
    raise EExcepcionColaboradorCompras.Create(
      'Error simulado en la recepción de compra');
  Result := FComportamiento = ccExito;
  if Result then
  begin
    AResultado.SerieAlbaran := 'AC';
    AResultado.NumeroAlbaran := '1';
  end
  else
    AResultado.Mensaje := 'Recepción rechazada';
end;

constructor TStockDevolucionCompraFalso.Create(
  AComportamiento: TComportamientoColaborador);
begin
  inherited Create;
  FComportamiento := AComportamiento;
end;

function TStockDevolucionCompraFalso.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  Result := esdcDisponible;
end;

function TStockDevolucionCompraFalso.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
begin
  Inc(FLlamadas);
  ALineas := 0;
  AEstado := esdcSinStock;
  if FComportamiento = ccExcepcion then
    raise EExcepcionColaboradorCompras.Create(
      'Error simulado en la devolución de stock');
  Result := FComportamiento = ccExito;
  if Result then
  begin
    ALineas := 3;
    AEstado := esdcDisponible;
  end;
end;

procedure PrepararRecepcion(
  AComportamiento: TComportamientoColaborador;
  ATransaccionActiva: Boolean;
  out AUnidad: TUnidadTrabajoComprasFalsa;
  out ARecepcion: TRecepcionPedidoCompraFalsa;
  out AProtegida: IRecepcionPedidoCompra);
var
  oRecepcion: IRecepcionPedidoCompra;
  oUnidad: IUnidadTrabajoComprasPantalla;
begin
  AUnidad := TUnidadTrabajoComprasFalsa.Create(ATransaccionActiva);
  oUnidad := AUnidad;
  ARecepcion := TRecepcionPedidoCompraFalsa.Create(AComportamiento);
  oRecepcion := ARecepcion;
  AProtegida := ProtegerRecepcionPedidoCompra(oRecepcion, oUnidad);
end;

procedure PrepararStock(
  AComportamiento: TComportamientoColaborador;
  ATransaccionActiva: Boolean;
  out AUnidad: TUnidadTrabajoComprasFalsa;
  out AStock: TStockDevolucionCompraFalso;
  out AProtegido: IPersistenciaStockDevolucionCompra);
var
  oStock: IPersistenciaStockDevolucionCompra;
  oUnidad: IUnidadTrabajoComprasPantalla;
begin
  AUnidad := TUnidadTrabajoComprasFalsa.Create(ATransaccionActiva);
  oUnidad := AUnidad;
  AStock := TStockDevolucionCompraFalso.Create(AComportamiento);
  oStock := AStock;
  AProtegido := ProtegerStockDevolucionCompra(oStock, oUnidad);
end;

function CrearParametrosRecepcion(
  AIncorporar: Boolean): TParametrosRecepcionPedidoCompra;
begin
  Result := Default(TParametrosRecepcionPedidoCompra);
  Result.Incorporar := AIncorporar;
end;

procedure ComprobarTransaccion(
  AUnidad: TUnidadTrabajoComprasFalsa;
  AInicios, AConfirmaciones, AReversiones: Integer);
begin
  Assert.AreEqual(AInicios, AUnidad.Inicios);
  Assert.AreEqual(AConfirmaciones, AUnidad.Confirmaciones);
  Assert.AreEqual(AReversiones, AUnidad.Reversiones);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_RechazoRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccRechazo, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsFalse(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_ExcepcionRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccExcepcion, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.WillRaise(
    procedure
    begin
      oProtegida.EjecutarRecepcionPedidoCompra(Parametros, Resultado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionCreacion_ExitoConfirma;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsFalse(oColaborador.UltimaIncorporacion);
  Assert.AreEqual('1', Resultado.NumeroAlbaran);
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_RechazoRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccRechazo, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.IsFalse(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_ExcepcionRevierte;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(
    ccExcepcion, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.WillRaise(
    procedure
    begin
      oProtegida.EjecutarRecepcionPedidoCompra(Parametros, Resultado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  RecepcionIncorporacion_ExitoConfirma;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, False, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(True);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oColaborador.UltimaIncorporacion);
  Assert.AreEqual('1', Resultado.NumeroAlbaran);
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_RechazoRevierte;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccRechazo, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.IsFalse(oProtegido.DevolverTodoStock(
    Parametros,
    Lineas,
    Estado));
  Assert.AreEqual(1, oColaborador.Llamadas);
  Assert.AreEqual(0, Lineas);
  Assert.AreEqual(Ord(esdcSinStock), Ord(Estado));
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_ExcepcionRevierte;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccExcepcion, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.WillRaise(
    procedure
    begin
      oProtegido.DevolverTodoStock(Parametros, Lineas, Estado);
    end,
    EExcepcionColaboradorCompras);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 1, 0, 1);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_ExitoConfirma;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(ccExito, False, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.IsTrue(oProtegido.DevolverTodoStock(
    Parametros,
    Lineas,
    Estado));
  Assert.AreEqual(1, oColaborador.Llamadas);
  Assert.AreEqual(3, Lineas);
  Assert.AreEqual(Ord(esdcDisponible), Ord(Estado));
  ComprobarTransaccion(oUnidad, 1, 1, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  Recepcion_TransaccionActivaNoAdministra;
var
  oColaborador: TRecepcionPedidoCompraFalsa;
  oProtegida: IRecepcionPedidoCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararRecepcion(ccExito, True, oUnidad, oColaborador, oProtegida);
  Parametros := CrearParametrosRecepcion(False);
  Assert.IsTrue(oProtegida.EjecutarRecepcionPedidoCompra(
    Parametros,
    Resultado));
  Assert.IsTrue(oUnidad.Activa);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 0, 0, 0);
end;

procedure TPruebasComposicionComprasPantalla.
  DevolucionStock_TransaccionActivaNoAdministra;
var
  oColaborador: TStockDevolucionCompraFalso;
  oProtegido: IPersistenciaStockDevolucionCompra;
  oUnidad: TUnidadTrabajoComprasFalsa;
  Estado: TEstadoStockDevolucionCompra;
  Lineas: Integer;
  Parametros: TParametrosStockDevolucionCompra;
begin
  PrepararStock(
    ccExcepcion, True, oUnidad, oColaborador, oProtegido);
  Parametros := Default(TParametrosStockDevolucionCompra);
  Assert.WillRaise(
    procedure
    begin
      oProtegido.DevolverTodoStock(Parametros, Lineas, Estado);
    end,
    EExcepcionColaboradorCompras);
  Assert.IsTrue(oUnidad.Activa);
  Assert.AreEqual(1, oColaborador.Llamadas);
  ComprobarTransaccion(oUnidad, 0, 0, 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComposicionComprasPantalla);

end.
