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
{    Caracteriza la fachada de pedidos mediante una dependencia falsa         }
{    inyectada, sin acceso a BBDD.                                             }
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
    procedure Pendientes_DeleganEnElServicioInyectado;
    [Test]
    procedure Crear_DeleganLasDosVariantes;
    [Test]
    procedure CalcularPendiente_DelegaYDevuelveElResultado;
    [Test]
    procedure Incorporar_DeleganLasDosVariantes;
    [Test]
    procedure EjecutarRecepcion_DelegaParametrosYResultado;
    [Test]
    procedure Pendientes_AdmiteContratoEstrecho;
    [Test]
    procedure EjecutarRecepcion_AdmiteContratoEstrecho;
    [Test]
    procedure Operacion_CantidadesParcialesConfirma;
    [Test]
    procedure Operacion_CanceladaRevierte;
    [Test]
    procedure Operacion_FalloRevierteYPropaga;
    [Test]
    procedure Presentacion_CanceladaNoEjecutaRecepcion;
  end;

implementation

uses
  System.SysUtils, inLibGridPivoteCompraTipos,
  inLibPedidosCompraIntf, inLibPedidosCompra,
  inLibPedidosCompraPresentacionOperacion,
  inLibPedidosCompraPresentacionRecepcion;

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
  TPedidosCompraFalso = class(
    TInterfacedObject,
    IPedidosCompra,
    IPedidosCompraPendientes,
    ICreacionAlbaranPedidoCompra,
    IIncorporacionAlbaranPedidoCompra,
    IRecepcionPedidoCompra)
  public
    Almacen: string;
    CantidadCeldas: Integer;
    CantidadPrimeraCelda: Double;
    CompletarOperacion: Boolean;
    Fecha: TDateTime;
    Linea: string;
    Numero: string;
    NumeroAlbaran: string;
    Operacion: TOperacionPedidoCompraFalsa;
    ProvocarFallo: Boolean;
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
  TUnidadTrabajoRecepcionFalsa = class(
    TInterfacedObject, IUnidadTrabajoRecepcionPedidoCompra)
  public
    Activa: Boolean;
    Confirmaciones: Integer;
    Inicios: Integer;
    Reversiones: Integer;
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  TSeleccionCantidadesRecepcionFalsa = class(
    TInterfacedObject, ISeleccionCantidadesRecepcionPedidoCompra)
  public
    Limpiadas: Integer;
    Recogidas: Integer;
    function PrimerAlmacen(AUsarCampo: Boolean): string;
    function Recoger(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean): TArray<TCeldaARecibir>;
    procedure Limpiar(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean);
    function Total(AUsarCampo: Boolean): Double;
    function RellenarTodo(AUsarCampo: Boolean): Integer;
    procedure LimitarCampo(Sender: TObject);
    procedure LimitarVertical(Sender: TObject);
  end;
  TVisualizacionRecepcionFalsa = class(
    TInterfacedObject, IVisualizacionRecepcionPedidoCompra)
  public
    Aceptar: Boolean;
    Avisos: Integer;
    Errores: Integer;
    Presentaciones: Integer;
    function Solicitar(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      Boolean;
    procedure MostrarAviso(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure PresentarRecepcion(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  end;

var
  oServicioFalso: IPedidosCompra;
  oPendientesFalso: IPedidosCompraPendientes;
  oRecepcionFalsa: IRecepcionPedidoCompra;
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
  if ProvocarFallo then
    raise Exception.Create('FALLO DE CREACIÓN');
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
  Result := CompletarOperacion;
end;

function TPedidosCompraFalso.CrearAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  if ProvocarFallo then
    raise Exception.Create('FALLO DE CREACIÓN');
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
  if CantidadCeldas > 0 then
    CantidadPrimeraCelda := ACeldas[0].Cantidad;
  ANumAlbc := '1002';
  AMensaje := 'CREADO CON CANTIDADES';
  Result := CompletarOperacion;
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
  if ProvocarFallo then
    raise Exception.Create('FALLO DE INCORPORACIÓN');
  Operacion := opcfIncorporar;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbcDestino;
  NumeroAlbaran := ANumAlbcDestino;
  Usuario := AUsuario;
  Temporada := AIdPvTemporada;
  AMensaje := 'INCORPORADO';
  Result := CompletarOperacion;
end;

function TPedidosCompraFalso.
  IncorporarAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  if ProvocarFallo then
    raise Exception.Create('FALLO DE INCORPORACIÓN');
  Operacion := opcfIncorporarConCantidades;
  Serie := ASeriePedc;
  Numero := ANumPedc;
  Almacen := ACodigoAlm;
  SerieAlbaran := ASerieAlbcDestino;
  NumeroAlbaran := ANumAlbcDestino;
  Usuario := AUsuario;
  Temporada := AIdPvTemporada;
  CantidadCeldas := Length(ACeldas);
  if CantidadCeldas > 0 then
    CantidadPrimeraCelda := ACeldas[0].Cantidad;
  AMensaje := 'INCORPORADO CON CANTIDADES';
  Result := CompletarOperacion;
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

function TUnidadTrabajoRecepcionFalsa.EstaActiva: Boolean;
begin
  Result := Activa;
end;

procedure TUnidadTrabajoRecepcionFalsa.Iniciar;
begin
  Activa := True;
  Inc(Inicios);
end;

procedure TUnidadTrabajoRecepcionFalsa.Confirmar;
begin
  Activa := False;
  Inc(Confirmaciones);
end;

procedure TUnidadTrabajoRecepcionFalsa.Revertir;
begin
  Activa := False;
  Inc(Reversiones);
end;

function TSeleccionCantidadesRecepcionFalsa.PrimerAlmacen(
  AUsarCampo: Boolean): string;
begin
  Result := 'A1';
end;

function TSeleccionCantidadesRecepcionFalsa.Recoger(
  const ACodigoAlmacen: string;
  AUsarCampo: Boolean): TArray<TCeldaARecibir>;
begin
  Inc(Recogidas);
  Result := nil;
end;

procedure TSeleccionCantidadesRecepcionFalsa.Limpiar(
  const ACodigoAlmacen: string;
  AUsarCampo: Boolean);
begin
  Inc(Limpiadas);
end;

function TSeleccionCantidadesRecepcionFalsa.Total(
  AUsarCampo: Boolean): Double;
begin
  Result := 0;
end;

function TSeleccionCantidadesRecepcionFalsa.RellenarTodo(
  AUsarCampo: Boolean): Integer;
begin
  Result := 0;
end;

procedure TSeleccionCantidadesRecepcionFalsa.LimitarCampo(
  Sender: TObject);
begin
end;

procedure TSeleccionCantidadesRecepcionFalsa.LimitarVertical(
  Sender: TObject);
begin
end;

function TVisualizacionRecepcionFalsa.Solicitar(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
  Boolean;
begin
  ASolicitud := Default(TSolicitudPresentacionRecepcionPedidoCompra);
  ASolicitud.CodigoAlmacen := AEntrada.AlmacenSugerido;
  Result := Aceptar;
end;

procedure TVisualizacionRecepcionFalsa.MostrarAviso(
  const AMensaje: string);
begin
  Inc(Avisos);
end;

procedure TVisualizacionRecepcionFalsa.MostrarError(
  const AMensaje: string);
begin
  Inc(Errores);
end;

procedure TVisualizacionRecepcionFalsa.PresentarRecepcion(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
  const AResultado: TResultadoRecepcionPedidoCompra);
begin
  Inc(Presentaciones);
end;

procedure PrepararServicioFalso;
begin
  oFalso := TPedidosCompraFalso.Create;
  oFalso.CompletarOperacion := True;
  oServicioFalso := oFalso;
  oPendientesFalso := oFalso;
  oRecepcionFalsa := oFalso;
end;

procedure TPruebasPedidosCompra.Liberar;
begin
  oServicioFalso := nil;
  oPendientesFalso := nil;
  oRecepcionFalsa := nil;
  oFalso := nil;
end;

procedure TPruebasPedidosCompra.
  Pendientes_DeleganEnElServicioInyectado;
begin
  PrepararServicioFalso;
  GenerarPdteRecibirDesdePedido(
    oServicioFalso, 'PC', '1', 'PRUEBAS');
  Assert.AreEqual(opcfGenerarPendientes, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('1', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
  BorrarPdteRecibirDesdePedido(
    oServicioFalso, 'PC', '2', '0010');
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
  PrepararServicioFalso;
  Assert.IsTrue(CrearAlbaranDesdePedido(
    oServicioFalso, 'PC', '3', 'A1', 'AC', 'PRUEBAS', 'REF-1',
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
    oServicioFalso, 'PC', '4', 'A1', 'AC', 'PRUEBAS', 'REF-2',
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
  PrepararServicioFalso;
  Assert.AreEqual(12.5,
    CalcularPendienteTotal(oServicioFalso, 'PC', '5'), 0.000001);
  Assert.AreEqual(opcfCalcularPendiente, oFalso.Operacion);
  Assert.AreEqual('PC', oFalso.Serie);
  Assert.AreEqual('5', oFalso.Numero);
end;

procedure TPruebasPedidosCompra.Incorporar_DeleganLasDosVariantes;
var
  Celdas: TArray<TCeldaARecibir>;
  Mensaje: string;
begin
  PrepararServicioFalso;
  Assert.IsTrue(IncorporarAlbaranDesdePedido(
    oServicioFalso, 'PC', '6', 'A2', 'AC', '3001', 'PRUEBAS',
    19, Mensaje));
  Assert.AreEqual(opcfIncorporar, oFalso.Operacion);
  Assert.AreEqual('AC', oFalso.SerieAlbaran);
  Assert.AreEqual('3001', oFalso.NumeroAlbaran);
  Assert.AreEqual('INCORPORADO', Mensaje);
  SetLength(Celdas, 2);
  Assert.IsTrue(IncorporarAlbaranDesdePedidoConCantidades(
    oServicioFalso, 'PC', '7', 'A2', 'AC', '3002', 'PRUEBAS',
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
  PrepararServicioFalso;
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '8';
  Parametros.CodigoAlmacen := 'A3';
  Parametros.SerieAlbaran := 'AC';
  Parametros.Usuario := 'PRUEBAS';
  Parametros.IdPvTemporada := 21;
  SetLength(Parametros.Celdas, 1);
  Assert.IsTrue(EjecutarRecepcionPedidoCompra(
    oServicioFalso, Parametros, Resultado));
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

procedure TPruebasPedidosCompra.Pendientes_AdmiteContratoEstrecho;
begin
  PrepararServicioFalso;
  oPendientesFalso.GenerarPdteRecibirDesdePedido(
    'PC', '9', 'PRUEBAS');
  Assert.AreEqual(opcfGenerarPendientes, oFalso.Operacion);
  Assert.AreEqual('9', oFalso.Numero);
end;

procedure TPruebasPedidosCompra.
  EjecutarRecepcion_AdmiteContratoEstrecho;
var
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararServicioFalso;
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '10';
  Parametros.CodigoAlmacen := 'A4';
  Assert.IsTrue(oRecepcionFalsa.EjecutarRecepcionPedidoCompra(
    Parametros, Resultado));
  Assert.AreEqual(opcfEjecutarRecepcion, oFalso.Operacion);
  Assert.AreEqual('10', oFalso.Numero);
end;

procedure TPruebasPedidosCompra.Operacion_CantidadesParcialesConfirma;
var
  Creacion: ICreacionAlbaranPedidoCompra;
  Incorporacion: IIncorporacionAlbaranPedidoCompra;
  Unidad: IUnidadTrabajoRecepcionPedidoCompra;
  Operacion: IRecepcionPedidoCompra;
  UnidadFalsa: TUnidadTrabajoRecepcionFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararServicioFalso;
  Creacion := oFalso;
  Incorporacion := oFalso;
  UnidadFalsa := TUnidadTrabajoRecepcionFalsa.Create;
  Unidad := UnidadFalsa;
  Operacion := CrearOperacionRecepcionPedidoCompra(
    Creacion, Incorporacion, Unidad);
  Parametros := Default(TParametrosRecepcionPedidoCompra);
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '11';
  Parametros.CodigoAlmacen := 'A1';
  Parametros.SerieAlbaran := 'AC';
  SetLength(Parametros.Celdas, 1);
  Parametros.Celdas[0].LineaPedido := '0010';
  Parametros.Celdas[0].CodigoAlmacen := 'A1';
  Parametros.Celdas[0].Cantidad := 2.5;
  Assert.IsTrue(Operacion.EjecutarRecepcionPedidoCompra(
    Parametros, Resultado));
  Assert.AreEqual(opcfCrearConCantidades, oFalso.Operacion);
  Assert.AreEqual(2.5, oFalso.CantidadPrimeraCelda, 0.000001);
  Assert.AreEqual(1, UnidadFalsa.Inicios);
  Assert.AreEqual(1, UnidadFalsa.Confirmaciones);
  Assert.AreEqual(0, UnidadFalsa.Reversiones);
end;

procedure TPruebasPedidosCompra.Operacion_CanceladaRevierte;
var
  Creacion: ICreacionAlbaranPedidoCompra;
  Incorporacion: IIncorporacionAlbaranPedidoCompra;
  Unidad: IUnidadTrabajoRecepcionPedidoCompra;
  Operacion: IRecepcionPedidoCompra;
  UnidadFalsa: TUnidadTrabajoRecepcionFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararServicioFalso;
  oFalso.CompletarOperacion := False;
  Creacion := oFalso;
  Incorporacion := oFalso;
  UnidadFalsa := TUnidadTrabajoRecepcionFalsa.Create;
  Unidad := UnidadFalsa;
  Operacion := CrearOperacionRecepcionPedidoCompra(
    Creacion, Incorporacion, Unidad);
  Parametros := Default(TParametrosRecepcionPedidoCompra);
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '12';
  Parametros.CodigoAlmacen := 'A1';
  Parametros.SerieAlbaran := 'AC';
  Assert.IsFalse(Operacion.EjecutarRecepcionPedidoCompra(
    Parametros, Resultado));
  Assert.AreEqual(1, UnidadFalsa.Inicios);
  Assert.AreEqual(0, UnidadFalsa.Confirmaciones);
  Assert.AreEqual(1, UnidadFalsa.Reversiones);
end;

procedure TPruebasPedidosCompra.Operacion_FalloRevierteYPropaga;
var
  Creacion: ICreacionAlbaranPedidoCompra;
  Incorporacion: IIncorporacionAlbaranPedidoCompra;
  Unidad: IUnidadTrabajoRecepcionPedidoCompra;
  Operacion: IRecepcionPedidoCompra;
  UnidadFalsa: TUnidadTrabajoRecepcionFalsa;
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  PrepararServicioFalso;
  oFalso.ProvocarFallo := True;
  Creacion := oFalso;
  Incorporacion := oFalso;
  UnidadFalsa := TUnidadTrabajoRecepcionFalsa.Create;
  Unidad := UnidadFalsa;
  Operacion := CrearOperacionRecepcionPedidoCompra(
    Creacion, Incorporacion, Unidad);
  Parametros := Default(TParametrosRecepcionPedidoCompra);
  Parametros.SeriePedido := 'PC';
  Parametros.NumeroPedido := '13';
  Parametros.CodigoAlmacen := 'A1';
  Parametros.SerieAlbaran := 'AC';
  Assert.WillRaise(
    procedure
    begin
      Operacion.EjecutarRecepcionPedidoCompra(
        Parametros, Resultado);
    end,
    Exception);
  Assert.AreEqual(1, UnidadFalsa.Inicios);
  Assert.AreEqual(0, UnidadFalsa.Confirmaciones);
  Assert.AreEqual(1, UnidadFalsa.Reversiones);
end;

procedure TPruebasPedidosCompra.
  Presentacion_CanceladaNoEjecutaRecepcion;
var
  Seleccion: ISeleccionCantidadesRecepcionPedidoCompra;
  Visualizacion: IVisualizacionRecepcionPedidoCompra;
  SeleccionFalsa: TSeleccionCantidadesRecepcionFalsa;
  VisualizacionFalsa: TVisualizacionRecepcionFalsa;
  Flujo: TFlujoPresentacionRecepcionPedidoCompra;
  Entrada: TEntradaPresentacionRecepcionPedidoCompra;
begin
  PrepararServicioFalso;
  SeleccionFalsa := TSeleccionCantidadesRecepcionFalsa.Create;
  Seleccion := SeleccionFalsa;
  VisualizacionFalsa := TVisualizacionRecepcionFalsa.Create;
  VisualizacionFalsa.Aceptar := False;
  Visualizacion := VisualizacionFalsa;
  Flujo := TFlujoPresentacionRecepcionPedidoCompra.Create(
    oRecepcionFalsa, Seleccion, Visualizacion);
  try
    Entrada := Default(TEntradaPresentacionRecepcionPedidoCompra);
    Entrada.SeriePedido := 'PC';
    Entrada.NumeroPedido := '14';
    Flujo.Ejecutar(Entrada);
    Assert.AreEqual(opcfNinguna, oFalso.Operacion);
    Assert.AreEqual(0, SeleccionFalsa.Recogidas);
    Assert.AreEqual(0, SeleccionFalsa.Limpiadas);
    Assert.AreEqual(0, VisualizacionFalsa.Presentaciones);
  finally
    FreeAndNil(Flujo);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPedidosCompra);

end.
