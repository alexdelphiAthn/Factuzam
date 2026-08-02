{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasStockConsultaEntrada                                   }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica la entrada de consulta de stock sin VCL ni datasets.             }
{******************************************************************************}
unit PruebasStockConsultaEntrada;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasStockConsultaEntrada = class
  public
    [Test]
    procedure TextoVacioLimpiaElArticulo;
    [Test]
    procedure TextoDesconocidoAvisaYConservaLaEntrada;
    [Test]
    procedure UnArticuloAplicaLaPrimeraCoincidencia;
    [Test]
    procedure VariosArticulosMuestranSelector;
    [Test]
    procedure CodigoBarrasResueltoAplicaArticuloYSku;
  end;

implementation

uses
  inLibArticulosValidadorIntf,
  inLibStockConsultaEntrada,
  inLibStockConsultaEntradaIntf;

type
  TDobleEntradaStock = class(
    TInterfacedObject,
    IRepositorioEntradaStock,
    IArticulosValidador,
    IVistaEntradaStock)
  private
    FCoincidencias: TCoincidenciasEntradaStock;
    FResolucion: TArtResolucionEntrada;
    FAplicaciones: Integer;
    FSelectores: Integer;
    FErroresTexto: Integer;
    FErroresBarras: Integer;
    FArticuloAplicado: string;
    FSkuAplicado: string;
  public
    function ResolverTexto(
      const AEntrada: string): TCoincidenciasEntradaStock;
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
    procedure AplicarArticulo(
      const ACodigoArticulo, ACodigoSku: string);
    procedure MostrarCoincidencias(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string);
    procedure MostrarTextoNoEncontrado(const AEntrada: string);
    procedure MostrarCodigoBarrasNoEncontrado(const ACodigo: string);
  end;

function Coincidencia(
  const ACodigoArticulo, ACodigoSku: string): TCoincidenciaEntradaStock;
begin
  Result := Default(TCoincidenciaEntradaStock);
  Result.CodigoArticulo := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
end;

function TDobleEntradaStock.ResolverTexto(
  const AEntrada: string): TCoincidenciasEntradaStock;
begin
  Result := FCoincidencias;
end;

function TDobleEntradaStock.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TDobleEntradaStock.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TDobleEntradaStock.ResolverConSku(
  const AEntrada, ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := FResolucion;
end;

function TDobleEntradaStock.EsValido(const AEntrada: string): Boolean;
begin
  Result := FResolucion.Encontrado;
end;

function TDobleEntradaStock.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FResolucion.CodigoSku <> '';
end;

procedure TDobleEntradaStock.AplicarArticulo(
  const ACodigoArticulo, ACodigoSku: string);
begin
  Inc(FAplicaciones);
  FArticuloAplicado := ACodigoArticulo;
  FSkuAplicado := ACodigoSku;
end;

procedure TDobleEntradaStock.MostrarCoincidencias(
  const ACoincidencias: TCoincidenciasEntradaStock;
  const AEntrada: string);
begin
  Inc(FSelectores);
end;

procedure TDobleEntradaStock.MostrarTextoNoEncontrado(
  const AEntrada: string);
begin
  Inc(FErroresTexto);
end;

procedure TDobleEntradaStock.MostrarCodigoBarrasNoEncontrado(
  const ACodigo: string);
begin
  Inc(FErroresBarras);
end;

procedure TPruebasStockConsultaEntrada.TextoVacioLimpiaElArticulo;
var
  Aplicacion: IAplicacionEntradaStock;
  Doble: TDobleEntradaStock;
begin
  Doble := TDobleEntradaStock.Create;
  Aplicacion := CrearAplicacionEntradaStock(Doble, Doble, Doble);
  Aplicacion.ProcesarTexto('  ', 'ART1', True);
  Assert.AreEqual(1, Doble.FAplicaciones);
  Assert.AreEqual('', Doble.FArticuloAplicado);
end;

procedure TPruebasStockConsultaEntrada.
  TextoDesconocidoAvisaYConservaLaEntrada;
var
  Aplicacion: IAplicacionEntradaStock;
  Doble: TDobleEntradaStock;
begin
  Doble := TDobleEntradaStock.Create;
  Aplicacion := CrearAplicacionEntradaStock(Doble, Doble, Doble);
  Aplicacion.ProcesarTexto('REF-1', 'ART0', True);
  Assert.AreEqual(1, Doble.FErroresTexto);
  Assert.AreEqual('REF-1', Doble.FArticuloAplicado);
end;

procedure TPruebasStockConsultaEntrada.
  UnArticuloAplicaLaPrimeraCoincidencia;
var
  Aplicacion: IAplicacionEntradaStock;
  Doble: TDobleEntradaStock;
begin
  Doble := TDobleEntradaStock.Create;
  Doble.FCoincidencias := [
    Coincidencia('ART1', 'SKU1'),
    Coincidencia('ART1', 'SKU2')];
  Aplicacion := CrearAplicacionEntradaStock(Doble, Doble, Doble);
  Aplicacion.ProcesarTexto('REF-1', '', True);
  Assert.AreEqual(1, Doble.FAplicaciones);
  Assert.AreEqual('ART1', Doble.FArticuloAplicado);
  Assert.AreEqual('SKU1', Doble.FSkuAplicado);
  Assert.AreEqual(0, Doble.FSelectores);
end;

procedure TPruebasStockConsultaEntrada.VariosArticulosMuestranSelector;
var
  Aplicacion: IAplicacionEntradaStock;
  Doble: TDobleEntradaStock;
begin
  Doble := TDobleEntradaStock.Create;
  Doble.FCoincidencias := [
    Coincidencia('ART1', ''),
    Coincidencia('ART2', '')];
  Aplicacion := CrearAplicacionEntradaStock(Doble, Doble, Doble);
  Aplicacion.ProcesarTexto('REF', '', True);
  Assert.AreEqual(0, Doble.FAplicaciones);
  Assert.AreEqual(1, Doble.FSelectores);
end;

procedure TPruebasStockConsultaEntrada.
  CodigoBarrasResueltoAplicaArticuloYSku;
var
  Aplicacion: IAplicacionEntradaStock;
  Doble: TDobleEntradaStock;
begin
  Doble := TDobleEntradaStock.Create;
  Doble.FResolucion.Clear;
  Doble.FResolucion.Encontrado := True;
  Doble.FResolucion.CodigoArticulo := 'ART1';
  Doble.FResolucion.CodigoSku := 'SKU1';
  Aplicacion := CrearAplicacionEntradaStock(Doble, Doble, Doble);
  Aplicacion.ProcesarCodigoBarras('8400001');
  Assert.AreEqual('ART1', Doble.FArticuloAplicado);
  Assert.AreEqual('SKU1', Doble.FSkuAplicado);
  Assert.AreEqual(0, Doble.FErroresBarras);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaEntrada);

end.
