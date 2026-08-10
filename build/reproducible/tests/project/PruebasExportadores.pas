{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasExportadores                                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Pruebas del cálculo tabular de exportaciones y de su presentador neutro. }
{******************************************************************************}
unit PruebasExportadores;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasExportadores = class
  public
    [Test]
    procedure SinFilas_NoGeneraDetalleNiTotal;
    [Test]
    procedure UnaFila_GeneraDetalleTotalYFormatos;
    [Test]
    procedure MuchasFilas_AcumulaElTotalGeneral;
    [Test]
    procedure CamposNulos_NoGeneranNumerosDeDetalle;
    [Test]
    procedure Tallas_CalculaLimitesYColumnasSinDevExpress;
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  Data.DB, Datasnap.DBClient,
  inLibHojaCalculoIntf, inLibMovVentasArtExcel,
  inLibExportacionCompraModelo;

type
  TDobleHojaCalculo = class(
    TInterfacedObject, IEscritorHojaCalculo, IFormateadorHojaCalculo)
  private
    FValores: TDictionary<string, Variant>;
    FFormatos: TDictionary<string, string>;
    function Clave(AFila, AColumna: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure NuevaHoja(const ANombre: string);
    procedure IniciarLote;
    procedure FinalizarLote;
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant);
    procedure EscribirFormula(AFila, ACol: Integer;
      const AFormula: string);
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);
    function CeldaExiste(AFila, ACol: Integer): Boolean;
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
      AEstilo: TEstiloBorde);
    procedure BordeCelda(AFila, ACol: Integer; ALado: TLadoBorde;
      AEstilo: TEstiloBorde);
    procedure FondoCelda(AFila, ACol: Integer; AColor: Cardinal);
    procedure Negrita(AFila, ACol: Integer;
      AActivar: Boolean = True);
    procedure TamanoFuente(AFila, ACol: Integer; ATamano: Integer);
    procedure AnchoColumna(ACol: Integer; AAncho: Integer);
    procedure Alinear(AFila, ACol: Integer;
      AAlineacion: TAlineacionCelda);
    procedure AplicarFormato(AFila, ACol: Integer;
      const AFormato: string);
    function Formato(AFila, AColumna: Integer): string;
    function TieneCelda(AFila, AColumna: Integer): Boolean;
    function Valor(AFila, AColumna: Integer): Variant;
  end;

constructor TDobleHojaCalculo.Create;
begin
  inherited Create;
  FValores := TDictionary<string, Variant>.Create;
  FFormatos := TDictionary<string, string>.Create;
end;

destructor TDobleHojaCalculo.Destroy;
begin
  FreeAndNil(FFormatos);
  FreeAndNil(FValores);
  inherited;
end;

function TDobleHojaCalculo.Clave(AFila, AColumna: Integer): string;
begin
  Result := IntToStr(AFila) + ':' + IntToStr(AColumna);
end;

procedure TDobleHojaCalculo.NuevaHoja(const ANombre: string);
begin
  FValores.Clear;
  FFormatos.Clear;
end;

procedure TDobleHojaCalculo.IniciarLote;
begin
end;

procedure TDobleHojaCalculo.FinalizarLote;
begin
end;

procedure TDobleHojaCalculo.Escribir(AFila, ACol: Integer;
  const AValor: Variant);
begin
  FValores.AddOrSetValue(Clave(AFila, ACol), AValor);
end;

procedure TDobleHojaCalculo.EscribirFormula(AFila, ACol: Integer;
  const AFormula: string);
begin
  FValores.AddOrSetValue(Clave(AFila, ACol), AFormula);
end;

procedure TDobleHojaCalculo.Combinar(
  AFila, ACol, ANumFilas, ANumCols: Integer);
begin
end;

function TDobleHojaCalculo.CeldaExiste(AFila, ACol: Integer): Boolean;
begin
  Result := FValores.ContainsKey(Clave(AFila, ACol));
end;

procedure TDobleHojaCalculo.DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
  AEstilo: TEstiloBorde);
begin
end;

procedure TDobleHojaCalculo.BordeCelda(AFila, ACol: Integer;
  ALado: TLadoBorde; AEstilo: TEstiloBorde);
begin
end;

procedure TDobleHojaCalculo.FondoCelda(AFila, ACol: Integer;
  AColor: Cardinal);
begin
end;

procedure TDobleHojaCalculo.Negrita(AFila, ACol: Integer;
  AActivar: Boolean);
begin
end;

procedure TDobleHojaCalculo.TamanoFuente(
  AFila, ACol, ATamano: Integer);
begin
end;

procedure TDobleHojaCalculo.AnchoColumna(ACol, AAncho: Integer);
begin
end;

procedure TDobleHojaCalculo.Alinear(AFila, ACol: Integer;
  AAlineacion: TAlineacionCelda);
begin
end;

procedure TDobleHojaCalculo.AplicarFormato(AFila, ACol: Integer;
  const AFormato: string);
begin
  FFormatos.AddOrSetValue(Clave(AFila, ACol), AFormato);
end;

function TDobleHojaCalculo.Formato(AFila, AColumna: Integer): string;
begin
  Result := '';
  FFormatos.TryGetValue(Clave(AFila, AColumna), Result);
end;

function TDobleHojaCalculo.TieneCelda(
  AFila, AColumna: Integer): Boolean;
begin
  Result := FValores.ContainsKey(Clave(AFila, AColumna));
end;

function TDobleHojaCalculo.Valor(AFila, AColumna: Integer): Variant;
begin
  Result := Null;
  FValores.TryGetValue(Clave(AFila, AColumna), Result);
end;

function CrearDatosVentas: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('CODIGO_ART_ART', ftString, 20);
  Result.FieldDefs.Add('DESCRIPCION_ART', ftString, 80);
  Result.FieldDefs.Add('UNI_ENT_TOT', ftFloat);
  Result.FieldDefs.Add('IMP_ENT_TOT', ftFloat);
  Result.FieldDefs.Add('UDS_VENTA', ftFloat);
  Result.FieldDefs.Add('IMP_VENTA', ftFloat);
  Result.FieldDefs.Add('IMP_COSTE', ftFloat);
  Result.FieldDefs.Add('BENEFICIO', ftFloat);
  Result.FieldDefs.Add('PCT_BNFCO', ftFloat);
  Result.FieldDefs.Add('VENTA_ENT', ftFloat);
  Result.FieldDefs.Add('VENT_ENT', ftFloat);
  Result.FieldDefs.Add('MARGEN1', ftFloat);
  Result.FieldDefs.Add('MARGEN2', ftFloat);
  Result.FieldDefs.Add('PCT_VDTO', ftFloat);
  Result.FieldDefs.Add('PCT_VLAST', ftFloat);
  Result.CreateDataSet;
end;

procedure AgregarFilaVenta(ADataSet: TClientDataSet;
  const ACodigo: string; AFactor: Double; AConNulos: Boolean = False);
begin
  ADataSet.Append;
  ADataSet.FieldByName('CODIGO_ART_ART').AsString := ACodigo;
  if not AConNulos then
  begin
    ADataSet.FieldByName('DESCRIPCION_ART').AsString :=
      'Articulo ' + ACodigo;
    ADataSet.FieldByName('UNI_ENT_TOT').AsFloat := 10 * AFactor;
    ADataSet.FieldByName('IMP_ENT_TOT').AsFloat := 100 * AFactor;
    ADataSet.FieldByName('UDS_VENTA').AsFloat := 5 * AFactor;
    ADataSet.FieldByName('IMP_VENTA').AsFloat := 80 * AFactor;
    ADataSet.FieldByName('IMP_COSTE').AsFloat := 40 * AFactor;
    ADataSet.FieldByName('BENEFICIO').AsFloat := 40 * AFactor;
    ADataSet.FieldByName('PCT_BNFCO').AsFloat := 100;
    ADataSet.FieldByName('VENTA_ENT').AsFloat := -20 * AFactor;
    ADataSet.FieldByName('VENT_ENT').AsFloat := -20;
    ADataSet.FieldByName('MARGEN1').AsFloat := 50;
    ADataSet.FieldByName('MARGEN2').AsFloat := -25;
    ADataSet.FieldByName('PCT_VDTO').AsFloat := 50;
    ADataSet.FieldByName('PCT_VLAST').AsFloat := 80;
  end;
  ADataSet.Post;
end;

procedure EjecutarExportacion(ADataSet: TClientDataSet;
  out ADoble: TDobleHojaCalculo;
  out AEscritor: IEscritorHojaCalculo;
  out AFormateador: IFormateadorHojaCalculo);
begin
  ADoble := TDobleHojaCalculo.Create;
  AEscritor := ADoble;
  AFormateador := ADoble;
  ExportarMovVentasArtExcel(AEscritor, AFormateador, ADataSet);
end;

procedure TPruebasExportadores.SinFilas_NoGeneraDetalleNiTotal;
var
  oDataSet: TClientDataSet;
  oDoble: TDobleHojaCalculo;
  oEscritor: IEscritorHojaCalculo;
  oFormateador: IFormateadorHojaCalculo;
begin
  oDataSet := CrearDatosVentas;
  try
    EjecutarExportacion(
      oDataSet, oDoble, oEscritor, oFormateador);
    Assert.IsTrue(oDoble.TieneCelda(1, 0));
    Assert.IsTrue(oDoble.TieneCelda(3, 0));
    Assert.IsFalse(oDoble.TieneCelda(4, 0));
  finally
    oFormateador := nil;
    oEscritor := nil;
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasExportadores.UnaFila_GeneraDetalleTotalYFormatos;
var
  oDataSet: TClientDataSet;
  oDoble: TDobleHojaCalculo;
  oEscritor: IEscritorHojaCalculo;
  oFormateador: IFormateadorHojaCalculo;
begin
  oDataSet := CrearDatosVentas;
  try
    AgregarFilaVenta(oDataSet, 'ART-1', 1);
    EjecutarExportacion(
      oDataSet, oDoble, oEscritor, oFormateador);
    Assert.AreEqual('ART-1  Articulo ART-1',
      VarToStr(oDoble.Valor(4, 0)));
    Assert.AreEqual('TOTAL GENERAL', VarToStr(oDoble.Valor(5, 0)));
    Assert.AreEqual('#,##0.00', oDoble.Formato(4, 4));
    Assert.AreEqual('#,##0.0', oDoble.Formato(4, 7));
  finally
    oFormateador := nil;
    oEscritor := nil;
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasExportadores.MuchasFilas_AcumulaElTotalGeneral;
var
  oDataSet: TClientDataSet;
  oDoble: TDobleHojaCalculo;
  oEscritor: IEscritorHojaCalculo;
  oFormateador: IFormateadorHojaCalculo;
  iFila: Integer;
begin
  oDataSet := CrearDatosVentas;
  try
    for iFila := 1 to 25 do
      AgregarFilaVenta(oDataSet, 'ART-' + IntToStr(iFila), iFila);
    EjecutarExportacion(
      oDataSet, oDoble, oEscritor, oFormateador);
    Assert.AreEqual('TOTAL GENERAL', VarToStr(oDoble.Valor(29, 0)));
    Assert.AreEqual(3250.0,
      VarAsType(oDoble.Valor(29, 1), varDouble), 0.001);
  finally
    oFormateador := nil;
    oEscritor := nil;
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasExportadores.CamposNulos_NoGeneranNumerosDeDetalle;
var
  oDataSet: TClientDataSet;
  oDoble: TDobleHojaCalculo;
  oEscritor: IEscritorHojaCalculo;
  oFormateador: IFormateadorHojaCalculo;
begin
  oDataSet := CrearDatosVentas;
  try
    AgregarFilaVenta(oDataSet, 'NULO', 0, True);
    EjecutarExportacion(
      oDataSet, oDoble, oEscritor, oFormateador);
    Assert.AreEqual('NULO  ', VarToStr(oDoble.Valor(4, 0)));
    Assert.IsFalse(oDoble.TieneCelda(4, 1));
    Assert.IsTrue(oDoble.TieneCelda(5, 1));
  finally
    oFormateador := nil;
    oEscritor := nil;
    FreeAndNil(oDataSet);
  end;
end;

procedure TPruebasExportadores.
  Tallas_CalculaLimitesYColumnasSinDevExpress;
var
  aTallas: TArray<string>;
  oColumnas: TColumnasCompraHorizontal;
begin
  SetLength(aTallas, MAX_TALLAS_EXPORTACION_COMPRA);
  Assert.AreEqual(0, UltimaTallaInformada(aTallas));
  aTallas[0] := '36';
  aTallas[19] := '55';
  Assert.AreEqual(20, UltimaTallaInformada(aTallas));
  Assert.AreEqual(10, NormalizarNumeroTallasCompra(0));
  Assert.AreEqual(20, NormalizarNumeroTallasCompra(30));
  oColumnas := CalcularColumnasCompraHorizontal(0, True);
  Assert.AreEqual(7, oColumnas.PrimeraTalla);
  Assert.AreEqual(17, oColumnas.Unidades);
  Assert.AreEqual(18, oColumnas.Importe);
  oColumnas := CalcularColumnasCompraHorizontal(20, False);
  Assert.AreEqual(-1, oColumnas.PrecioVenta);
  Assert.AreEqual(6, oColumnas.PrimeraTalla);
  Assert.AreEqual(26, oColumnas.Unidades);
  Assert.AreEqual(27, oColumnas.Importe);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasExportadores);

end.
