{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDevolucionesCompraMovimientos                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada de movimientos de devoluciones de compra           }
{    mediante una dependencia falsa inyectada, sin BBDD.                      }
{******************************************************************************}
unit PruebasDevolucionesCompraMovimientos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDevolucionesCompraMovimientos = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure Generar_DelegaEnElServicioInyectado;
    [Test]
    procedure Revertir_DelegaEnElServicioInyectado;
    [Test]
    procedure PrepararStock_CancelacionNoEscribe;
    [Test]
    procedure PrepararStock_CantidadParcialInformaLineas;
    [Test]
    procedure PrepararStock_RechazoConservaMotivo;
    [Test]
    procedure PrepararStock_FalloSePropaga;
    [Test]
    procedure Movimientos_ExitoConfirmaTransaccionPropia;
    [Test]
    procedure Movimientos_FalloRevierteTransaccionPropia;
  end;

implementation

uses
  System.SysUtils,
  inLibDevolucionesCompraMovimientosIntf,
  inLibDevolucionesCompraMovimientos,
  inLibDevolucionesCompraStock,
  inLibDevolucionesCompraPresentacionFlujo;

type
  TOperacionMovimientosFalsa = (
    omfNinguna,
    omfGenerar,
    omfRevertir);
  TMovimientosDevolucionCompraFalso = class(
    TInterfacedObject,
    IMovimientosDevolucionCompra)
  public
    FallarGeneracion: Boolean;
    Numero: string;
    Operacion: TOperacionMovimientosFalsa;
    Serie: string;
    Usuario: string;
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure SincronizarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string;
      AGenerar: Boolean);
  end;

  TStockDevolucionCompraFalso = class(
    TInterfacedObject,
    IPersistenciaStockDevolucionCompra)
  public
    EstadoConsulta: TEstadoStockDevolucionCompra;
    EstadoResultado: TEstadoStockDevolucionCompra;
    Fallar: Boolean;
    LineasResultado: Integer;
    Llamadas: Integer;
    Resultado: Boolean;
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;

  TUnidadTrabajoMovimientosFalsa = class(
    TInterfacedObject,
    IUnidadTrabajoMovimientosDevolucionCompra)
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

var
  oServicioFalso: IMovimientosDevolucionCompra;
  oFalso: TMovimientosDevolucionCompraFalso;

procedure TMovimientosDevolucionCompraFalso.GenerarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  Operacion := omfGenerar;
  Serie := ASerieDevc;
  Numero := ANumDevc;
  Usuario := AUsuario;
  if FallarGeneracion then
    raise Exception.Create('Fallo simulado al generar movimientos');
end;

procedure TMovimientosDevolucionCompraFalso.RevertirDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  Operacion := omfRevertir;
  Serie := ASerieDevc;
  Numero := ANumDevc;
  Usuario := AUsuario;
end;

procedure TMovimientosDevolucionCompraFalso.SincronizarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string;
  AGenerar: Boolean);
begin
  RevertirDesdeDevolucion(ASerieDevc, ANumDevc, AUsuario);
  if AGenerar then
    GenerarDesdeDevolucion(ASerieDevc, ANumDevc, AUsuario);
end;

function TStockDevolucionCompraFalso.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  Result := EstadoConsulta;
end;

function TStockDevolucionCompraFalso.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
begin
  Inc(Llamadas);
  if Fallar then
    raise Exception.Create('Fallo simulado al preparar stock');
  ALineas := LineasResultado;
  AEstado := EstadoResultado;
  Result := Resultado;
end;

function TUnidadTrabajoMovimientosFalsa.EstaActiva: Boolean;
begin
  Result := Activa;
end;

procedure TUnidadTrabajoMovimientosFalsa.Iniciar;
begin
  Inc(Inicios);
  Activa := True;
end;

procedure TUnidadTrabajoMovimientosFalsa.Confirmar;
begin
  Inc(Confirmaciones);
  Activa := False;
end;

procedure TUnidadTrabajoMovimientosFalsa.Revertir;
begin
  Inc(Reversiones);
  Activa := False;
end;

procedure PrepararServicioFalso;
begin
  oFalso := TMovimientosDevolucionCompraFalso.Create;
  oServicioFalso := oFalso;
end;

procedure TPruebasDevolucionesCompraMovimientos.Liberar;
begin
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Generar_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  GenerarMovimientosDesdeDevolucionCompra(
    oServicioFalso,
    'DC',
    '77',
    'PRUEBAS');
  Assert.AreEqual(omfGenerar, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('77', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Revertir_DelegaEnElServicioInyectado;
begin
  PrepararServicioFalso;
  RevertirMovimientosDesdeDevolucionCompra(
    oServicioFalso,
    'DC',
    '78',
    'PRUEBAS');
  Assert.AreEqual(omfRevertir, oFalso.Operacion);
  Assert.AreEqual('DC', oFalso.Serie);
  Assert.AreEqual('78', oFalso.Numero);
  Assert.AreEqual('PRUEBAS', oFalso.Usuario);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  PrepararStock_CancelacionNoEscribe;
var
  oFalsoStock: TStockDevolucionCompraFalso;
  oStock: IPersistenciaStockDevolucionCompra;
  oParametros: TParametrosStockDevolucionCompra;
  oResultado: TResultadoPreparacionStockDevolucion;
begin
  oFalsoStock := TStockDevolucionCompraFalso.Create;
  oStock := oFalsoStock;
  oParametros := Default(TParametrosStockDevolucionCompra);
  oResultado := EjecutarPreparacionStockDevolucion(
    oStock,
    oParametros,
    False);
  Assert.AreEqual(Ord(epsdCancelada), Ord(oResultado.Estado));
  Assert.AreEqual(0, oFalsoStock.Llamadas);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  PrepararStock_CantidadParcialInformaLineas;
var
  oFalsoStock: TStockDevolucionCompraFalso;
  oStock: IPersistenciaStockDevolucionCompra;
  oParametros: TParametrosStockDevolucionCompra;
  oResultado: TResultadoPreparacionStockDevolucion;
begin
  oFalsoStock := TStockDevolucionCompraFalso.Create;
  oStock := oFalsoStock;
  oFalsoStock.Resultado := True;
  oFalsoStock.LineasResultado := 2;
  oFalsoStock.EstadoResultado := esdcDisponible;
  oParametros := Default(TParametrosStockDevolucionCompra);
  oResultado := EjecutarPreparacionStockDevolucion(
    oStock,
    oParametros,
    True);
  Assert.AreEqual(Ord(epsdCompletada), Ord(oResultado.Estado));
  Assert.AreEqual(2, oResultado.Lineas);
  Assert.AreEqual(1, oFalsoStock.Llamadas);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  PrepararStock_RechazoConservaMotivo;
var
  oFalsoStock: TStockDevolucionCompraFalso;
  oStock: IPersistenciaStockDevolucionCompra;
  oParametros: TParametrosStockDevolucionCompra;
  oResultado: TResultadoPreparacionStockDevolucion;
begin
  oFalsoStock := TStockDevolucionCompraFalso.Create;
  oStock := oFalsoStock;
  oFalsoStock.EstadoResultado := esdcSinStock;
  oParametros := Default(TParametrosStockDevolucionCompra);
  oResultado := EjecutarPreparacionStockDevolucion(
    oStock,
    oParametros,
    True);
  Assert.AreEqual(Ord(epsdRechazada), Ord(oResultado.Estado));
  Assert.AreEqual(Ord(esdcSinStock), Ord(oResultado.Motivo));
  Assert.AreEqual(1, oFalsoStock.Llamadas);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  PrepararStock_FalloSePropaga;
var
  oFalsoStock: TStockDevolucionCompraFalso;
  oStock: IPersistenciaStockDevolucionCompra;
  oParametros: TParametrosStockDevolucionCompra;
begin
  oFalsoStock := TStockDevolucionCompraFalso.Create;
  oStock := oFalsoStock;
  oFalsoStock.Fallar := True;
  oParametros := Default(TParametrosStockDevolucionCompra);
  Assert.WillRaise(
    procedure
    begin
      EjecutarPreparacionStockDevolucion(
        oStock,
        oParametros,
        True);
    end,
    Exception);
  Assert.AreEqual(1, oFalsoStock.Llamadas);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Movimientos_ExitoConfirmaTransaccionPropia;
var
  oFalsoMovimientos: TMovimientosDevolucionCompraFalso;
  oMovimientos: IMovimientosDevolucionCompra;
  oProtegidos: IMovimientosDevolucionCompra;
  oUnidad: TUnidadTrabajoMovimientosFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosDevolucionCompra;
begin
  oFalsoMovimientos := TMovimientosDevolucionCompraFalso.Create;
  oMovimientos := oFalsoMovimientos;
  oUnidad := TUnidadTrabajoMovimientosFalsa.Create;
  oUnidadInterfaz := oUnidad;
  oProtegidos := ProtegerMovimientosDevolucionCompra(
    oMovimientos,
    oUnidadInterfaz);
  oProtegidos.GenerarDesdeDevolucion('DC', '81', 'PRUEBAS');
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(1, oUnidad.Confirmaciones);
  Assert.AreEqual(0, oUnidad.Reversiones);
end;

procedure TPruebasDevolucionesCompraMovimientos.
  Movimientos_FalloRevierteTransaccionPropia;
var
  oFalsoMovimientos: TMovimientosDevolucionCompraFalso;
  oMovimientos: IMovimientosDevolucionCompra;
  oProtegidos: IMovimientosDevolucionCompra;
  oUnidad: TUnidadTrabajoMovimientosFalsa;
  oUnidadInterfaz: IUnidadTrabajoMovimientosDevolucionCompra;
begin
  oFalsoMovimientos := TMovimientosDevolucionCompraFalso.Create;
  oFalsoMovimientos.FallarGeneracion := True;
  oMovimientos := oFalsoMovimientos;
  oUnidad := TUnidadTrabajoMovimientosFalsa.Create;
  oUnidadInterfaz := oUnidad;
  oProtegidos := ProtegerMovimientosDevolucionCompra(
    oMovimientos,
    oUnidadInterfaz);
  Assert.WillRaise(
    procedure
    begin
      oProtegidos.SincronizarDesdeDevolucion(
        'DC', '82', 'PRUEBAS', True);
    end,
    Exception);
  Assert.AreEqual(1, oUnidad.Inicios);
  Assert.AreEqual(0, oUnidad.Confirmaciones);
  Assert.AreEqual(1, oUnidad.Reversiones);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasDevolucionesCompraMovimientos);

end.
