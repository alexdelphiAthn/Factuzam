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

  [TestFixture]
  TPruebasStockConsultaCoincidencias = class
  public
    [Test]
    procedure CargarDeduplicaPorArticuloYConservaElPrimerSku;
    [Test]
    procedure TextoVisibleOmiteLosTramosVacios;
    [Test]
    procedure FilasDesplegableSeLimitaAQuince;
    [Test]
    procedure AnchoDesplegableSeAjustaAlMinimoYAlMaximo;
    [Test]
    procedure IndiceFueraDeRangoDevuelveVacio;
  end;

  [TestFixture]
  TPruebasStockConsultaHistorial = class
  public
    [Test]
    procedure RegistrarIgnoraVaciosYRepeticiones;
    [Test]
    procedure NavegarAtrasYAdelanteRecorreLaSecuencia;
    [Test]
    procedure RegistrarTrasVolverAtrasTruncaLaRamaFutura;
    [Test]
    procedure MoviendoImpideRegistrarLaNavegacion;
  end;

  [TestFixture]
  TPruebasStockConsultaEstadoVista = class
  public
    [Test]
    procedure GuardasImpidenReentrarEnLaResolucionDeEntrada;
    [Test]
    procedure ClaveUnidadColorCombinaArticuloYColor;
    [Test]
    procedure LimpiarDejaLaVistaSinArticulo;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosValidadorIntf,
  inLibStockConsultaEntrada,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaPresentacionCoincidencias,
  inLibStockConsultaPresentacionHistorial,
  inLibStockConsultaPresentacionVista;

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

function CoincidenciaCompleta(
  const ACodigoArticulo, ACodigoSku, ADescripcion, AProveedor,
        AReferencia: string): TCoincidenciaEntradaStock;
begin
  Result := Default(TCoincidenciaEntradaStock);
  Result.CodigoArticulo := ACodigoArticulo;
  Result.CodigoSku := ACodigoSku;
  Result.Descripcion := ADescripcion;
  Result.Proveedor := AProveedor;
  Result.ReferenciaProveedor := AReferencia;
end;

procedure TPruebasStockConsultaCoincidencias.
  CargarDeduplicaPorArticuloYConservaElPrimerSku;
var
  Entradas: TCoincidenciasEntradaStock;
  Lista: TCoincidenciasArticuloStock;
begin
  Entradas := [
    Coincidencia('ART1', 'SKU1'),
    Coincidencia('ART1', 'SKU2'),
    Coincidencia('ART2', 'SKU3')];
  Lista := TCoincidenciasArticuloStock.Create;
  try
    Lista.Cargar(Entradas);
    Assert.AreEqual(2, Lista.Cuenta);
    Assert.AreEqual('ART1', Lista.Codigos[0]);
    Assert.AreEqual('SKU1', Lista.Skus[0]);
    Assert.AreEqual('ART2', Lista.Codigos[1]);
    Assert.AreEqual('SKU3', Lista.Skus[1]);
  finally
    Lista.Free;
  end;
end;

procedure TPruebasStockConsultaCoincidencias.
  TextoVisibleOmiteLosTramosVacios;
begin
  Assert.AreEqual(
    'ART1 / SKU1 - Camiseta - Prov (ref. R1)',
    DescribirCoincidenciaStock(
      CoincidenciaCompleta('ART1', 'SKU1', 'Camiseta', 'Prov', 'R1')));
  Assert.AreEqual(
    'ART1 - Camiseta',
    DescribirCoincidenciaStock(
      CoincidenciaCompleta('ART1', '', 'Camiseta', '', '')));
end;

procedure TPruebasStockConsultaCoincidencias.
  FilasDesplegableSeLimitaAQuince;
var
  Entradas: TCoincidenciasEntradaStock;
  i: Integer;
  Lista: TCoincidenciasArticuloStock;
begin
  SetLength(Entradas, 20);
  for i := 0 to High(Entradas) do
    Entradas[i] := Coincidencia('ART' + IntToStr(i), '');
  Lista := TCoincidenciasArticuloStock.Create;
  try
    Lista.Cargar(Entradas);
    Assert.AreEqual(20, Lista.Cuenta);
    Assert.AreEqual(15, Lista.FilasDesplegable);
  finally
    Lista.Free;
  end;
end;

procedure TPruebasStockConsultaCoincidencias.
  AnchoDesplegableSeAjustaAlMinimoYAlMaximo;
begin
  Assert.AreEqual(620, AnchoDesplegableCoincidencias(900, 100));
  Assert.AreEqual(300, AnchoDesplegableCoincidencias(300, 100));
  Assert.AreEqual(100, AnchoDesplegableCoincidencias(40, 100));
end;

procedure TPruebasStockConsultaCoincidencias.
  IndiceFueraDeRangoDevuelveVacio;
var
  Entradas: TCoincidenciasEntradaStock;
  Lista: TCoincidenciasArticuloStock;
begin
  Entradas := [Coincidencia('ART1', 'SKU1')];
  Lista := TCoincidenciasArticuloStock.Create;
  try
    Lista.Cargar(Entradas);
    Assert.IsFalse(Lista.EsIndiceValido(-1));
    Assert.IsFalse(Lista.EsIndiceValido(1));
    Assert.AreEqual('', Lista.Codigos[5]);
  finally
    Lista.Free;
  end;
end;

procedure TPruebasStockConsultaHistorial.
  RegistrarIgnoraVaciosYRepeticiones;
var
  Historial: THistorialArticulosStock;
begin
  Historial := THistorialArticulosStock.Create;
  try
    Historial.Registrar('   ');
    Historial.Registrar('ART1');
    Historial.Registrar('art1');
    Assert.AreEqual(1, Historial.Cuenta);
    Assert.AreEqual(0, Historial.Posicion);
    Assert.IsFalse(Historial.PuedeAnterior);
    Assert.IsFalse(Historial.PuedeSiguiente);
  finally
    Historial.Free;
  end;
end;

procedure TPruebasStockConsultaHistorial.
  NavegarAtrasYAdelanteRecorreLaSecuencia;
var
  Historial: THistorialArticulosStock;
begin
  Historial := THistorialArticulosStock.Create;
  try
    Historial.Registrar('ART1');
    Historial.Registrar('ART2');
    Historial.Registrar('ART3');
    Assert.AreEqual('ART2', Historial.Anterior);
    Assert.AreEqual('ART1', Historial.Anterior);
    Assert.IsFalse(Historial.PuedeAnterior);
    Assert.AreEqual('', Historial.Anterior);
    Assert.AreEqual('ART2', Historial.Siguiente);
    Assert.AreEqual('ART3', Historial.Siguiente);
    Assert.IsFalse(Historial.PuedeSiguiente);
  finally
    Historial.Free;
  end;
end;

procedure TPruebasStockConsultaHistorial.
  RegistrarTrasVolverAtrasTruncaLaRamaFutura;
var
  Historial: THistorialArticulosStock;
begin
  Historial := THistorialArticulosStock.Create;
  try
    Historial.Registrar('ART1');
    Historial.Registrar('ART2');
    Historial.Registrar('ART3');
    Historial.Anterior;
    Historial.Anterior;
    Historial.Registrar('ART9');
    Assert.AreEqual(2, Historial.Cuenta);
    Assert.AreEqual('ART9', Historial.Actual);
    Assert.IsFalse(Historial.PuedeSiguiente);
  finally
    Historial.Free;
  end;
end;

procedure TPruebasStockConsultaHistorial.
  MoviendoImpideRegistrarLaNavegacion;
var
  Historial: THistorialArticulosStock;
begin
  Historial := THistorialArticulosStock.Create;
  try
    Historial.Registrar('ART1');
    Historial.Registrar('ART2');
    Historial.Anterior;
    Historial.Moviendo := True;
    Historial.Registrar('ART1');
    Historial.Moviendo := False;
    Assert.AreEqual(2, Historial.Cuenta);
    Assert.AreEqual(0, Historial.Posicion);
  finally
    Historial.Free;
  end;
end;

procedure TPruebasStockConsultaEstadoVista.
  GuardasImpidenReentrarEnLaResolucionDeEntrada;
var
  Vista: TEstadoVistaStockConsulta;
begin
  Vista := Default(TEstadoVistaStockConsulta);
  Assert.IsTrue(Vista.AdmiteResolverEntrada);
  Assert.IsTrue(Vista.AdmiteCambioTextoArticulo);
  Assert.IsTrue(Vista.AdmiteSeleccionCoincidencia);
  Assert.IsTrue(Vista.AdmiteCambioVista);
  Vista.ActualizandoArticulo := True;
  Assert.IsFalse(Vista.AdmiteResolverEntrada);
  Assert.IsFalse(Vista.AdmiteCambioTextoArticulo);
  Assert.IsTrue(Vista.AdmiteSeleccionCoincidencia);
  Vista.ActualizandoArticulo := False;
  Vista.ResolviendoEntrada := True;
  Assert.IsFalse(Vista.AdmiteResolverEntrada);
  Assert.IsFalse(Vista.AdmiteSeleccionCoincidencia);
  Vista.SilenciandoCambioVista := True;
  Assert.IsFalse(Vista.AdmiteCambioVista);
end;

procedure TPruebasStockConsultaEstadoVista.
  ClaveUnidadColorCombinaArticuloYColor;
var
  Vista: TEstadoVistaStockConsulta;
begin
  Vista := Default(TEstadoVistaStockConsulta);
  Vista.FijarArticulo('ART1', 'ART1/AZ/M');
  Assert.IsTrue(Vista.HayArticulo);
  Assert.AreEqual('ART1/AZ', Vista.ClaveUnidadColor('AZ'));
end;

procedure TPruebasStockConsultaEstadoVista.LimpiarDejaLaVistaSinArticulo;
var
  Vista: TEstadoVistaStockConsulta;
begin
  Vista := Default(TEstadoVistaStockConsulta);
  Vista.FijarArticulo('ART1', 'SKU1');
  Vista.ResolviendoEntrada := True;
  Vista.Limpiar;
  Assert.IsFalse(Vista.HayArticulo);
  Assert.AreEqual('', Vista.CodigoSku);
  Assert.IsTrue(Vista.AdmiteResolverEntrada);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaEntrada);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaCoincidencias);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaHistorial);
  TDUnitX.RegisterTestFixture(TPruebasStockConsultaEstadoVista);

end.
