{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasInventariosAplicacion                                  }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica la entrada de inventario sin VCL ni datasets.                    }
{******************************************************************************}
unit PruebasInventariosAplicacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInventariosAplicacion = class
  public
    [Test]
    procedure ArticuloDesconocidoNoModificaLaLinea;
    [Test]
    procedure ServicioSeRechazaAntesDeEditar;
    [Test]
    procedure PadreConAtributosExigeSkuEnModoUnificado;
    [Test]
    procedure SkuCargaStockYAtributos;
    [Test]
    procedure ArticuloSimpleCargaStockSinAtributos;
  end;

implementation

uses
  inLibArticulosValidadorIntf,
  inLibInventariosAplicacion,
  inLibInventariosAplicacionIntf;

type
  TValidadorEntradaInventarioFalso = class(
    TInterfacedObject,
    IArticulosValidador)
  private
    FResolucion: TArtResolucionEntrada;
  public
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada, ACodigoSkuPreferido: string):
      TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
  end;

  TOperacionesEntradaInventarioFalsas = class(
    TInterfacedObject,
    IOperacionesEntradaInventario)
  private
    FMuestraAtributos: Boolean;
    FNumeroAtributos: Integer;
    FErrorEdicion: TErrorEntradaInventario;
    FArticulosEscritos: Integer;
    FUnidadesEscritas: Integer;
    FStocksCargados: Integer;
    FAtributosRellenados: Integer;
  public
    function MuestraAtributos: Boolean;
    function ObtenerNumeroAtributos(
      const ACodigoArticulo: string): Integer;
    function AsegurarEdicion: TErrorEntradaInventario;
    procedure EscribirArticulo(
      const ACodigoArticulo, ADescripcion: string);
    procedure ActualizarColumnas(const ACodigoArticulo: string);
    function NumeroAtributosActual: Integer;
    procedure EscribirUnidad(const ACodigoUnidad: string);
    procedure CargarStock(const ACodigoUnidad: string);
    procedure RellenarAtributos(const ACodigoSku: string);
  end;

function ResolucionBase: TArtResolucionEntrada;
begin
  Result.Clear;
  Result.Encontrado := True;
  Result.CodigoArticulo := 'ART1';
  Result.DescripcionArticulo := 'Articulo uno';
  Result.TipoArticulo := 'ESTANDAR';
end;

function TValidadorEntradaInventarioFalso.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TValidadorEntradaInventarioFalso.EsValido(
  const AEntrada: string): Boolean;
begin
  Result := FResolucion.Encontrado;
end;

function TValidadorEntradaInventarioFalso.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FResolucion.CodigoSku <> '';
end;

function TOperacionesEntradaInventarioFalsas.MuestraAtributos: Boolean;
begin
  Result := FMuestraAtributos;
end;

function TOperacionesEntradaInventarioFalsas.ObtenerNumeroAtributos(
  const ACodigoArticulo: string): Integer;
begin
  Result := FNumeroAtributos;
end;

function TOperacionesEntradaInventarioFalsas.AsegurarEdicion:
  TErrorEntradaInventario;
begin
  Result := FErrorEdicion;
end;

procedure TOperacionesEntradaInventarioFalsas.EscribirArticulo(
  const ACodigoArticulo, ADescripcion: string);
begin
  Inc(FArticulosEscritos);
end;

procedure TOperacionesEntradaInventarioFalsas.ActualizarColumnas(
  const ACodigoArticulo: string);
begin
end;

function TOperacionesEntradaInventarioFalsas.NumeroAtributosActual: Integer;
begin
  Result := FNumeroAtributos;
end;

procedure TOperacionesEntradaInventarioFalsas.EscribirUnidad(
  const ACodigoUnidad: string);
begin
  Inc(FUnidadesEscritas);
end;

procedure TOperacionesEntradaInventarioFalsas.CargarStock(
  const ACodigoUnidad: string);
begin
  Inc(FStocksCargados);
end;

procedure TOperacionesEntradaInventarioFalsas.RellenarAtributos(
  const ACodigoSku: string);
begin
  Inc(FAtributosRellenados);
end;

procedure TPruebasInventariosAplicacion.ArticuloDesconocidoNoModificaLaLinea;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion.Clear;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('NO-EXISTE');
  Assert.AreEqual(Ord(eeiArticuloNoEncontrado), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.ServicioSeRechazaAntesDeEditar;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Validador.FResolucion.TipoArticulo := 'SERVICIO';
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiTipoArticuloSinStock), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.
  PadreConAtributosExigeSkuEnModoUnificado;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Operaciones.FNumeroAtributos := 2;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiAtributosRequierenSku), Ord(Resultado.Error));
  Assert.AreEqual(0, Operaciones.FArticulosEscritos);
end;

procedure TPruebasInventariosAplicacion.SkuCargaStockYAtributos;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Validador.FResolucion.CodigoSku := 'SKU1';
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('SKU1');
  Assert.AreEqual(Ord(eeiNinguno), Ord(Resultado.Error));
  Assert.AreEqual('SKU1', Resultado.CodigoUnidad);
  Assert.AreEqual(1, Operaciones.FStocksCargados);
  Assert.AreEqual(1, Operaciones.FAtributosRellenados);
end;

procedure TPruebasInventariosAplicacion.ArticuloSimpleCargaStockSinAtributos;
var
  Aplicacion: IAplicacionEntradaInventario;
  Operaciones: TOperacionesEntradaInventarioFalsas;
  Resultado: TResultadoEntradaInventario;
  Validador: TValidadorEntradaInventarioFalso;
begin
  Validador := TValidadorEntradaInventarioFalso.Create;
  Validador.FResolucion := ResolucionBase;
  Operaciones := TOperacionesEntradaInventarioFalsas.Create;
  Aplicacion := CrearAplicacionEntradaInventario(Validador, Operaciones);
  Resultado := Aplicacion.Procesar('ART1');
  Assert.AreEqual(Ord(eeiNinguno), Ord(Resultado.Error));
  Assert.AreEqual('ART1', Resultado.CodigoUnidad);
  Assert.AreEqual(1, Operaciones.FStocksCargados);
  Assert.AreEqual(0, Operaciones.FAtributosRellenados);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInventariosAplicacion);

end.
