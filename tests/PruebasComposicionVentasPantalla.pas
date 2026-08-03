{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasComposicionVentasPantalla                              }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Caracteriza la preparacion y creacion de albaranes desde pedidos sin      }
{    formularios, datasets ni conexion real.                                   }
{******************************************************************************}
unit PruebasComposicionVentasPantalla;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPreparacionAlbaranPedido = class
  public
    [Test]
    procedure SinCantidadesNoPreparaEntregas;
    [Test]
    procedure SumaLoPendienteALoEntregado;
    [Test]
    procedure AlmacenComunQuedaComoDefecto;
    [Test]
    procedure AlmacenesDistintosObliganAElegir;
  end;

  [TestFixture]
  TPruebasCreacionAlbaranPedido = class
  public
    [Test]
    procedure CasoUsoDelegaLaSolicitudCompleta;
    [Test]
    procedure CasoUsoConservaElFalloDelRepositorio;
  end;

implementation

uses
  inLibVentasPantallaCrearAlbaran;

type
  TRepositorioCreacionAlbaranFalso = class(
    TInterfacedObject,
    IRepositorioCreacionAlbaranPedido)
  private
    FSolicitud: TSolicitudCreacionAlbaranPedido;
    FResultado: TResultadoCreacionAlbaranPedido;
    FLlamadas: Integer;
  public
    function Crear(
      const ASolicitud: TSolicitudCreacionAlbaranPedido):
      TResultadoCreacionAlbaranPedido;
  end;

function CrearLinea(
  const ALinea, AAlmacen: string;
  AEntregada, AAAlbaranar: Currency): TLineaPedidoParaAlbaran;
begin
  Result := Default(TLineaPedidoParaAlbaran);
  Result.Linea := ALinea;
  Result.CodigoAlmacen := AAlmacen;
  Result.CantidadEntregada := AEntregada;
  Result.CantidadAAlbaranar := AAAlbaranar;
end;

function TRepositorioCreacionAlbaranFalso.Crear(
  const ASolicitud: TSolicitudCreacionAlbaranPedido):
  TResultadoCreacionAlbaranPedido;
begin
  Inc(FLlamadas);
  FSolicitud := ASolicitud;
  Result := FResultado;
end;

procedure TPruebasPreparacionAlbaranPedido.
  SinCantidadesNoPreparaEntregas;
var
  oResultado: TPreparacionAlbaranPedido;
begin
  oResultado := TPreparadorAlbaranPedido.Preparar([
    CrearLinea('1', 'A1', 2, 0),
    CrearLinea('2', 'A1', 1, -1)]);
  Assert.AreEqual<NativeInt>(0, Length(oResultado.Entregas));
  Assert.IsFalse(oResultado.TieneEntregas);
  Assert.AreEqual('', oResultado.AlmacenDefecto);
end;

procedure TPruebasPreparacionAlbaranPedido.
  SumaLoPendienteALoEntregado;
var
  oResultado: TPreparacionAlbaranPedido;
begin
  oResultado := TPreparadorAlbaranPedido.Preparar([
    CrearLinea('7', 'A1', 2, 1.5)]);
  Assert.AreEqual<NativeInt>(1, Length(oResultado.Entregas));
  Assert.AreEqual('7', oResultado.Entregas[0].Linea);
  Assert.AreEqual<Currency>(3.5,
    oResultado.Entregas[0].CantidadTotalEntregada);
end;

procedure TPruebasPreparacionAlbaranPedido.
  AlmacenComunQuedaComoDefecto;
var
  oResultado: TPreparacionAlbaranPedido;
begin
  oResultado := TPreparadorAlbaranPedido.Preparar([
    CrearLinea('1', 'A1', 0, 1),
    CrearLinea('2', 'A1', 0, 2)]);
  Assert.IsTrue(oResultado.EsAlmacenUnico);
  Assert.AreEqual('A1', oResultado.AlmacenComun);
  Assert.AreEqual('A1', oResultado.AlmacenDefecto);
end;

procedure TPruebasPreparacionAlbaranPedido.
  AlmacenesDistintosObliganAElegir;
var
  oResultado: TPreparacionAlbaranPedido;
begin
  oResultado := TPreparadorAlbaranPedido.Preparar([
    CrearLinea('1', 'A1', 0, 1),
    CrearLinea('2', 'A2', 0, 2)]);
  Assert.IsFalse(oResultado.EsAlmacenUnico);
  Assert.AreEqual('', oResultado.AlmacenDefecto);
end;

procedure TPruebasCreacionAlbaranPedido.
  CasoUsoDelegaLaSolicitudCompleta;
var
  oCasoUso: ICasoUsoCrearAlbaranPedido;
  oDoble: TRepositorioCreacionAlbaranFalso;
  oSolicitud: TSolicitudCreacionAlbaranPedido;
  oResultado: TResultadoCreacionAlbaranPedido;
begin
  oDoble := TRepositorioCreacionAlbaranFalso.Create;
  oDoble.FResultado.Creado := True;
  oDoble.FResultado.Serie := 'A';
  oDoble.FResultado.Numero := '15';
  oCasoUso := TCasoUsoCrearAlbaranPedido.Create(oDoble);
  oSolicitud := Default(TSolicitudCreacionAlbaranPedido);
  oSolicitud.SeriePedido := 'P';
  oSolicitud.NumeroPedido := '8';
  oSolicitud.CodigoAlmacen := 'A1';
  oSolicitud.EsAlbaranExistente := True;
  oSolicitud.SerieAlbaranExistente := 'A';
  oSolicitud.NumeroAlbaranExistente := '12';
  oSolicitud.Entregas := [
    Default(TEntregaAlbaranPedido)];
  oSolicitud.Entregas[0].Linea := '3';
  oSolicitud.Entregas[0].CantidadTotalEntregada := 4;
  oResultado := oCasoUso.Ejecutar(oSolicitud);
  Assert.AreEqual(1, oDoble.FLlamadas);
  Assert.AreEqual('P', oDoble.FSolicitud.SeriePedido);
  Assert.AreEqual('12',
    oDoble.FSolicitud.NumeroAlbaranExistente);
  Assert.AreEqual<Currency>(4,
    oDoble.FSolicitud.Entregas[0].CantidadTotalEntregada);
  Assert.IsTrue(oResultado.Creado);
  Assert.AreEqual('15', oResultado.Numero);
end;

procedure TPruebasCreacionAlbaranPedido.
  CasoUsoConservaElFalloDelRepositorio;
var
  oCasoUso: ICasoUsoCrearAlbaranPedido;
  oDoble: TRepositorioCreacionAlbaranFalso;
  oSolicitud: TSolicitudCreacionAlbaranPedido;
  oResultado: TResultadoCreacionAlbaranPedido;
begin
  oDoble := TRepositorioCreacionAlbaranFalso.Create;
  oDoble.FResultado.Creado := False;
  oCasoUso := TCasoUsoCrearAlbaranPedido.Create(oDoble);
  oSolicitud := Default(TSolicitudCreacionAlbaranPedido);
  oResultado := oCasoUso.Ejecutar(oSolicitud);
  Assert.IsFalse(oResultado.Creado);
  Assert.AreEqual(1, oDoble.FLlamadas);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPreparacionAlbaranPedido);
  TDUnitX.RegisterTestFixture(TPruebasCreacionAlbaranPedido);

end.
