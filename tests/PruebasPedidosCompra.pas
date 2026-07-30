{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPedidosCompra                                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de pedidos de compra mediante una fábrica          }
{    falsa, sin acceso a BBDD.                                                 }
{******************************************************************************}
unit PruebasPedidosCompra;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPedidosCompra = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure Pendientes_DeleganEnElServicioRegistrado;
    [Test]
    procedure Crear_DeleganLasDosVariantes;
    [Test]
    procedure CalcularPendiente_DelegaYDevuelveElResultado;
    [Test]
    procedure Incorporar_DeleganLasDosVariantes;
    [Test]
    procedure EjecutarRecepcion_DelegaParametrosYResultado;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibGridPivoteCompra,
  inLibPedidosCompraIntf, inLibPedidosCompra,
  UniDataPedidosCompraOperaciones;

type
  TOperacionPedidoCompraFalsa = (
    opcfNinguna,
    opcfGenerarPendientes,
    opcfBorrarPendientes,
    opcfCrear,
    opcfCrearConCantidades,
    opcfCalcularPendiente,
    opcfIncorporar,
    opcfIncorporarConCantidades,
    opcfEjecutarRecepcion);
  TPedidosCompraFalso = class(TInterfacedObject, IPedidosCompra)
  public
    Almacen: string;
    CantidadCeldas: Integer;
    Fecha: TDateTime;
    Linea: string;
    Numero: string;
    NumeroAlbaran: string;
    Operacion: TOperacionPedidoCompraFalsa;
    Referencia: string;
    Serie: string;
    SerieAlbaran: string;
    Temporada: Integer;
    Usuario: string;
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

var
  oServicioFalso: IPedidosCompra;
  oFalso: TPedidosCompraFalso;

procedure TPedidosCompraFalso.GenerarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, AUsuario: string);
begin
  Operacion := opcfGenerarPendientes;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Usuario := AUsuario;
end;

procedure TPedidosCompraFalso.BorrarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, ALinea: string);
begin
  Operacion := opcfBorrarPendientes;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Linea := ALinea;
end;

function TPedidosCompraFalso.CrearAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Operacion := opcfCrear;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbc;
  Usuario := AUsuario;
  Referencia := ARefPrv;
  Fecha := AFechaRecepcion;
  Temporada := AIdPvTemporada;
  ANumAlbc := '1001';
  AMensaje := 'CREADO';
  Result := True;
end;

function TPedidosCompraFalso.CrearAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Operacion := opcfCrearConCantidades;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbc;
  Usuario := AUsuario;
  Referencia := ARefPrv;
  Fecha := AFechaRecepcion;
  Temporada := AIdPvTemporada;
  CantidadCeldas := Length(ACeldas);
  ANumAlbc := '1002';
  AMensaje := 'CREADO CON CANTIDADES';
  Result := True;
end;

function TPedidosCompraFalso.CalcularPendienteTotal(
  const ASeriePedc, ANumPedc: string): Double;
begin
  Operacion := opcfCalcularPendiente;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Result := 12.5;
end;

function TPedidosCompraFalso.IncorporarAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Operacion := opcfIncorporar;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbcDestino;
  NumeroAlbaran := ANumAlbcDestino;
  Usuario := AUsuario;
  Temporada := AIdPvTemporada;
  AMensaje := 'INCORPORADO';
  Result := True;
end;

function TPedidosCompraFalso.
  IncorporarAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Operacion := opcfIncorporarConCantidades;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbcDestino;
  NumeroAlbaran := ANumAlbcDestino;
  Usuario := AUsuario;
  Temporada := AIdPvTemporada;
  CantidadCeldas := Length(ACeldas);
  AMensaje := 'INCORPORADO CON CANTIDADES';
  Result := True;
end;

function TPedidosCompraFalso.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Operacion := opcfEjecutarRecepcion;
  Serie := AParametros.SeriePedido;
  Numero := AParametros.NumeroPedido;
  Almacen := AParametros.CodigoAlmacen;
  SerieAlbaran := AParametros.SerieAlbaran;
  Usuario := AParametros.Usuario;
  Temporada := AParametros.IdPvTemporada;
  CantidadCeldas := Length(AParametros.Celdas);
  AResultado.SerieAlbaran := 'AR';
  AResultado.NumeroAlbaran := '2001';
  AResultado.Mensaje := 'RECIBIDO';
  Result := True;
end;

function FabricaFalsa(
  AConexion: TUniConnection): IPedidosCompra;
begin
  Result := oServicioFalso;
end;

procedure PrepararFabricaFalsa;
begin
  oFalso := TPedidosCompraFalso.Create;
  oServicioFalso := oFalso;
  TFabricaPedidosCompra.Registrar(FabricaFalsa);
end;

procedure TPruebasPedidosCompra.Liberar;
begin
  TFabricaPedidosCompra.Registrar(CrearPedidosCompraUniDAC);
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasPedidosCompra.
  Pendientes_DeleganEnElServicioRegistrado;
begin
  PrepararFabricaFalsa;
  GenerarPdteRecibirDesdePedido(nil, 'PC', '1', 'PRUEBAS');
  Assert.AreEqual(opcfGenerarPendientes, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('1', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
  BorrarPdteRecibirDesdePedido(nil, 'PC', '2', '0010');
  Assert.AreEqual(opcfBorrarPendientes, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('2', oFalso.Numero);
  Assert.AreEqual('0010', oFalso.Linea);
end;

procedure TPruebasPedidosCompra.Crear_DeleganLasDosVariantes;
var
  Celdas: TArray<TCeldaARecibir>;
  Mensaje: string;
  NumeroAlbaran: string;
begin
  PrepararFabricaFalsa;
  Assert.IsTrue(CrearAlbaranDesdePedido(
    nil, 'PC', '3', 'A1', 'AC', 'PRUEBAS', 'REF-1',
    EncodeDate(2026, 7, 30), 17, NumeroAlbaran, Mensaje));
  Assert.AreEqual(opcfCrear, oFalso.Operacion);
  Assert.AreEqual('A1', oFalso.Almacen);
  Assert.AreEqual('AC', oFalso.SerieAlbaran);
  Assert.AreEqual('REF-1', oFalso.Referencia);
  Assert.AreEqual(17, oFalso.Temporada);
  Assert.AreEqual('1001', NumeroAlbaran);
  Assert.AreEqual('CREADO', Mensaje);
  SetLength(Celdas, 1);
  Celdas[0].LineaPedido := '0010';
  Celdas[0].CodigoSku := 'SKU-1';
  Celdas[0].CodigoAlmacen := 'A1';
  Celdas[0].Cantidad := 2;
  Assert.IsTrue(CrearAlbaranDesdePedidoConCantidades(
    nil, 'PC', '4', 'A1', 'AC', 'PRUEBAS', 'REF-2',
    EncodeDate(2026, 7, 31), 18, Celdas,
    NumeroAlbaran, Mensaje));
  Assert.AreEqual(opcfCrearConCantidades, oFalso.Operacion);
  Assert.AreEqual(1, oFalso.CantidadCeldas);
  Assert.AreEqual('1002', NumeroAlbaran);
  Assert.AreEqual('CREADO CON CANTIDADES', Mensaje);
end;

procedure TPruebasPedidosCompra.
  CalcularPendiente_DelegaYDevuelveElResultado;
begin
  PrepararFabricaFalsa;
  Assert.AreEqual(12.5,
    CalcularPendienteTotal(nil, 'PC', '5'), 0.000001);
  Assert.AreEqual(opcfCalcularPendiente, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('5', oFalso.Numero);
end;

procedure TPruebasPedidosCompra.Incorporar_DeleganLasDosVariantes;
var
  Celdas: TArray<TCeldaARecibir>;
  Mensaje: string;
begin
  PrepararFabricaFalsa;
  Assert.IsTrue(IncorporarAlbaranDesdePedido(
    nil, 'PC', '6', 'A2', 'AC', '3001', 'PRUEBAS',
    19, Mensaje));
  Assert.AreEqual(opcfIncorporar, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.SerieAlbaran);
  Assert.AreEqual('3001', oFalso.NumeroAlbaran);
  Assert.AreEqual('INCORPORADO', Mensaje);
  SetLength(Celdas, 2);
  Assert.IsTrue(IncorporarAlbaranDesdePedidoConCantidades(
    nil, 'PC', '7', 'A2', 'AC', '3002', 'PRUEBAS',
    20, Celdas, Mensaje));
  Assert.AreEqual(
    opcfIncorporarConCantidades, oFalso.Operacion);
  Assert.AreEqual(2, oFalso.CantidadCeldas);
  Assert.AreEqual('INCORPORADO CON CANTIDADES', Mensaje);
end;

procedure TPruebasPedidosCompra.
  EjecutarRecepcion_DelegaParametrosYResultado;
var
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararFabricaFalsa;
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '8';
  Parametros.CodigoAlmacen := 'A3';
  Parametros.SerieAlbaran := 'AC';
  Parametros.Usuario := 'PRUEBAS';
  Parametros.IdPvTemporada := 21;
  SetLength(Parametros.Celdas, 1);
  Assert.IsTrue(EjecutarRecepcionPedidoCompra(
    nil, Parametros, Resultado));
  Assert.AreEqual(opcfEjecutarRecepcion, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('8', oFalso.Numero);
  Assert.AreEqual('A3', oFalso.Almacen);
  Assert.AreEqual(21, oFalso.Temporada);
  Assert.AreEqual(1, oFalso.CantidadCeldas);
  Assert.AreEqual('AR', Resultado.SerieAlbaran);
  Assert.AreEqual('2001', Resultado.NumeroAlbaran);
  Assert.AreEqual('RECIBIDO', Resultado.Mensaje);
end;

procedure TPruebasPedidosCompra.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaPedidosCompra.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      CalcularPendienteTotal(nil, 'PC', '9');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPedidosCompra);

end.
