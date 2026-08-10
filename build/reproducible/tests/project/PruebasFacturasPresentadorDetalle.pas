{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasPresentadorDetalle                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la visibilidad del detalle de factura sin VCL ni BBDD.        }
{******************************************************************************}
unit PruebasFacturasPresentadorDetalle;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasPresentadorDetalle = class
  public
    [Test]
    procedure ModoCreacion_MuestraColumnasDeCreacion;
    [Test]
    procedure SinModoCreacion_OcultaColumnasDeCreacion;
    [Test]
    procedure Sku_SeMuestraSiUnaLineaLoNecesita;
    [Test]
    procedure Sku_SeOcultaSiNingunaLineaLoNecesita;
    [Test]
    procedure Sku_SeMuestraSiempreEnModoCreacion;
    [Test]
    procedure Sku_NoSeTocaConContratoDeEntradaActivo;
    [Test]
    procedure Reaplicar_NoTocaNadaMientrasSeConstruye;
    [Test]
    procedure Reaplicar_AplicaCreacionYSku;
    [Test]
    procedure ModoCreacionSolicitado_CubreCabeceraYCheck;
    [Test]
    procedure Decision_SinConstruirSiempreConstruye;
    [Test]
    procedure Decision_ClasicoNecesarioConContratoReconstruye;
    [Test]
    procedure Decision_ClasicoConstruidoSinNecesitarloReconstruye;
    [Test]
    procedure Decision_ModoTallasSiempreReconstruye;
    [Test]
    procedure Decision_DesgloseSoloDesempaqueta;
    [Test]
    procedure Decision_ModoSkuNoHaceNada;
  end;

implementation

uses
  System.SysUtils, inLibFacturasPresentadorDetalle;

type
  TColumnasDetalleDoble = class(TInterfacedObject, IColumnasDetalleFactura)
  private
    FArticulos: TArray<string>;
    FSkuVisible: Boolean;
    FCreacionVisible: Boolean;
    FVecesCreacion: Integer;
    FVecesSku: Integer;
  public
    constructor Create(const AArticulos: TArray<string>;
      ASkuVisible: Boolean);
    procedure MostrarColumnasCreacion(AVisible: Boolean);
    procedure MostrarColumnaSku(AVisible: Boolean);
    function SkuVisible: Boolean;
    function TotalLineas: Integer;
    function ArticuloLinea(AIndice: Integer): string;
    property CreacionVisible: Boolean read FCreacionVisible;
    property VecesCreacion: Integer read FVecesCreacion;
    property VecesSku: Integer read FVecesSku;
  end;
  TReglaSkuDoble = class(TInterfacedObject, IReglaSkuFactura)
  private
    FConSku: string;
  public
    constructor Create(const AConSku: string);
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
  end;

constructor TColumnasDetalleDoble.Create(
  const AArticulos: TArray<string>; ASkuVisible: Boolean);
begin
  inherited Create;
  FArticulos := AArticulos;
  FSkuVisible := ASkuVisible;
end;

procedure TColumnasDetalleDoble.MostrarColumnasCreacion(AVisible: Boolean);
begin
  FCreacionVisible := AVisible;
  Inc(FVecesCreacion);
end;

procedure TColumnasDetalleDoble.MostrarColumnaSku(AVisible: Boolean);
begin
  FSkuVisible := AVisible;
  Inc(FVecesSku);
end;

function TColumnasDetalleDoble.SkuVisible: Boolean;
begin
  Result := FSkuVisible;
end;

function TColumnasDetalleDoble.TotalLineas: Integer;
begin
  Result := Length(FArticulos);
end;

function TColumnasDetalleDoble.ArticuloLinea(AIndice: Integer): string;
begin
  Result := FArticulos[AIndice];
end;

constructor TReglaSkuDoble.Create(const AConSku: string);
begin
  inherited Create;
  FConSku := AConSku;
end;

function TReglaSkuDoble.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := (FConSku <> '') and SameText(ACodigoArticulo, FConSku);
end;

procedure TPruebasFacturasPresentadorDetalle.
  ModoCreacion_MuestraColumnasDeCreacion;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create(''));
  try
    Presentador.SincronizarColumnasCreacion(True);
    Assert.IsTrue(Columnas.CreacionVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  SinModoCreacion_OcultaColumnasDeCreacion;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create(''));
  try
    Presentador.SincronizarColumnasCreacion(False);
    Assert.IsFalse(Columnas.CreacionVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  Sku_SeMuestraSiUnaLineaLoNecesita;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1', 'A2', 'A3'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create('A3'));
  try
    Presentador.SincronizarColumnaSku(
      CrearSituacionDetalleFactura(False, False, False));
    Assert.IsTrue(Columnas.SkuVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  Sku_SeOcultaSiNingunaLineaLoNecesita;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1', 'A2'], True);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create('OTRO'));
  try
    Presentador.SincronizarColumnaSku(
      CrearSituacionDetalleFactura(False, False, False));
    Assert.IsFalse(Columnas.SkuVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  Sku_SeMuestraSiempreEnModoCreacion;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create([], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create(''));
  try
    Presentador.SincronizarColumnaSku(
      CrearSituacionDetalleFactura(True, False, False));
    Assert.IsTrue(Columnas.SkuVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  Sku_NoSeTocaConContratoDeEntradaActivo;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create('A1'));
  try
    Presentador.SincronizarColumnaSku(
      CrearSituacionDetalleFactura(True, True, False));
    Assert.AreEqual(0, Columnas.VecesSku);
    Assert.IsFalse(Columnas.SkuVisible);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  Reaplicar_NoTocaNadaMientrasSeConstruye;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create('A1'));
  try
    Presentador.Reaplicar(
      CrearSituacionDetalleFactura(True, False, True));
    Assert.AreEqual(0, Columnas.VecesCreacion);
    Assert.AreEqual(0, Columnas.VecesSku);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.Reaplicar_AplicaCreacionYSku;
var
  Columnas: TColumnasDetalleDoble;
  Presentador: TPresentadorDetalleFactura;
begin
  Columnas := TColumnasDetalleDoble.Create(['A1'], False);
  Presentador := TPresentadorDetalleFactura.Create(
    Columnas, TReglaSkuDoble.Create('A1'));
  try
    Presentador.Reaplicar(
      CrearSituacionDetalleFactura(False, False, False));
    Assert.AreEqual(1, Columnas.VecesCreacion);
    Assert.IsFalse(Columnas.CreacionVisible);
    Assert.IsTrue(Columnas.SkuVisible);
    Assert.IsFalse(Presentador.Reaplicando);
  finally
    Presentador.Free;
  end;
end;

procedure TPruebasFacturasPresentadorDetalle.
  ModoCreacionSolicitado_CubreCabeceraYCheck;
begin
  Assert.IsFalse(ModoCreacionFacturaSolicitado(False, False));
  Assert.IsTrue(ModoCreacionFacturaSolicitado(True, False));
  Assert.IsTrue(ModoCreacionFacturaSolicitado(False, True));
  Assert.IsTrue(ModoCreacionFacturaSolicitado(True, True));
end;

procedure TPruebasFacturasPresentadorDetalle.
  Decision_SinConstruirSiempreConstruye;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := False;
  Assert.AreEqual(
    Ord(dmefConstruir),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

procedure TPruebasFacturasPresentadorDetalle.
  Decision_ClasicoNecesarioConContratoReconstruye;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := True;
  Situacion.ClasicoNecesario := True;
  Situacion.ContratoActivo := True;
  Assert.AreEqual(
    Ord(dmefConstruir),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

procedure TPruebasFacturasPresentadorDetalle.
  Decision_ClasicoConstruidoSinNecesitarloReconstruye;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := True;
  Situacion.ClasicoNecesario := False;
  Situacion.ContratoActivo := False;
  Assert.AreEqual(
    Ord(dmefConstruir),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

procedure TPruebasFacturasPresentadorDetalle.
  Decision_ModoTallasSiempreReconstruye;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := True;
  Situacion.ClasicoNecesario := False;
  Situacion.ContratoActivo := True;
  Situacion.ModoTallas := True;
  Assert.AreEqual(
    Ord(dmefConstruir),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

procedure TPruebasFacturasPresentadorDetalle.
  Decision_DesgloseSoloDesempaqueta;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := True;
  Situacion.ClasicoNecesario := False;
  Situacion.ContratoActivo := True;
  Situacion.ModoTallas := False;
  Situacion.ModoSku := False;
  Assert.AreEqual(
    Ord(dmefDesempaquetar),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

procedure TPruebasFacturasPresentadorDetalle.Decision_ModoSkuNoHaceNada;
var
  Situacion: TSituacionModoEntradaFactura;
begin
  Situacion := Default(TSituacionModoEntradaFactura);
  Situacion.Construido := True;
  Situacion.ClasicoNecesario := False;
  Situacion.ContratoActivo := True;
  Situacion.ModoTallas := False;
  Situacion.ModoSku := True;
  Assert.AreEqual(
    Ord(dmefNinguna),
    Ord(DecidirModoEntradaFactura(Situacion)));
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasFacturasPresentadorDetalle);

end.
