{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasValidacionTallasCompra                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de configuración y reglas puras de tallas en compras.             }
{******************************************************************************}
unit PruebasValidacionTallasCompra;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasValidacionTallasCompra = class
  private
    FAseguramientos: Integer;
    FValidaciones: Integer;
    function ValidarPivote(var AMensaje: string): Boolean;
    procedure AsegurarCabecera;
  public
    [Test]
    procedure Configuracion_GeneraCamposDocumento;
    [Test]
    procedure Linea_DetectaArticuloYSistemaTallas;
    [Test]
    procedure Persistencia_PublicaCabeceraYSincronizaLinea;
    [Test]
    procedure PersistenciaVenta_RecreaLineaVacia;
    [Test]
    procedure TallasHorizontal_UsaLecturasInyectadas;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibDocumento, inLibDocumentoIntf,
  inLibValidacionDocumento,
  inLibValidacionDocumentoLecturasIntf;

type
  TLecturasValidacionDocumentoPrueba = class(
    TInterfacedObject,
    IValidacionDocumentoLecturas)
  private
    FArticulos: TArray<string>;
  public
    constructor Create(const AArticulos: TArray<string>);
    function ListarArticulosSinSistemaTallas(
      const AConfiguracion: TConfiguracionDocumento;
      const ASerie, ANumero: string): TArray<string>;
  end;

constructor TLecturasValidacionDocumentoPrueba.Create(
  const AArticulos: TArray<string>);
begin
  inherited Create;
  FArticulos := Copy(AArticulos);
end;

function TLecturasValidacionDocumentoPrueba.
  ListarArticulosSinSistemaTallas(
  const AConfiguracion: TConfiguracionDocumento;
  const ASerie, ANumero: string): TArray<string>;
begin
  Result := Copy(FArticulos);
end;

procedure TPruebasValidacionTallasCompra.AsegurarCabecera;
begin
  Inc(FAseguramientos);
end;

function TPruebasValidacionTallasCompra.ValidarPivote(
  var AMensaje: string): Boolean;
begin
  Inc(FValidaciones);
  Result := True;
end;

function ConfiguracionPedido: TConfiguracionDocumento;
begin
  Result := CrearConfiguracionDocumento(tdPedido, sdCompra);
  Result.MensajeCabeceraNoDisponible :=
    'Debe existir la cabecera del pedido.';
  Result.DocumentoConArticulo := 'un pedido';
  Result.CampoEstadoCabecera := Result.CampoPivoteCabecera;
  Result.ValorEstadoCabecera := 'N';
  Result.CancelarLineaSoloSinNumero := True;
end;

procedure TPruebasValidacionTallasCompra.
  Configuracion_GeneraCamposDocumento;
var
  oConfiguracion: TConfiguracionDocumento;
begin
  oConfiguracion := ConfiguracionPedido;
  Assert.AreEqual('SERIE_PEDC',
    oConfiguracion.CampoSerieCabecera);
  Assert.AreEqual('NUMERO_PEDC_PEDCLIN',
    oConfiguracion.CampoNumeroLinea);
  Assert.AreEqual('ESPIVOTE_HORIZONTAL_PEDC',
    oConfiguracion.CampoPivoteCabecera);
  Assert.AreEqual('CODIGO_ART_PEDCLIN',
    oConfiguracion.CampoArticuloLinea);
  Assert.AreEqual('ID_AC_PIVOT_PEDCLIN',
    oConfiguracion.CampoPivoteLinea);
end;

procedure TPruebasValidacionTallasCompra.
  Linea_DetectaArticuloYSistemaTallas;
var
  oConfiguracion: TConfiguracionDocumento;
  oDataSet: TClientDataSet;
begin
  oConfiguracion := ConfiguracionPedido;
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add(
      oConfiguracion.CampoArticuloLinea, ftString, 20);
    oDataSet.FieldDefs.Add(
      oConfiguracion.CampoUnidadLinea, ftString, 20);
    oDataSet.FieldDefs.Add(
      oConfiguracion.CampoPivoteLinea, ftInteger);
    oDataSet.CreateDataSet;
    oDataSet.Append;
    Assert.IsTrue(LineaCompraVacia(
      oDataSet, oConfiguracion));
    Assert.IsFalse(LineaCompraTieneArticulo(
      oDataSet, oConfiguracion));
    Assert.IsFalse(LineaCompraTieneSistemaTallas(
      oDataSet, oConfiguracion));
    oDataSet.FieldByName(
      oConfiguracion.CampoUnidadLinea).AsString := ' SKU1 ';
    Assert.IsFalse(LineaCompraVacia(
      oDataSet, oConfiguracion));
    Assert.IsTrue(LineaCompraTieneArticulo(
      oDataSet, oConfiguracion));
    oDataSet.FieldByName(
      oConfiguracion.CampoPivoteLinea).AsInteger := 12;
    Assert.IsTrue(LineaCompraTieneSistemaTallas(
      oDataSet, oConfiguracion));
  finally
    oDataSet.Free;
  end;
end;

procedure TPruebasValidacionTallasCompra.
  Persistencia_PublicaCabeceraYSincronizaLinea;
var
  oCabecera: TClientDataSet;
  oConfiguracion: TConfiguracionDocumento;
  oLineas: TClientDataSet;
begin
  oConfiguracion := ConfiguracionPedido;
  oCabecera := TClientDataSet.Create(nil);
  oLineas := TClientDataSet.Create(nil);
  try
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoSerieCabecera, ftString, 10);
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoNumeroCabecera, ftString, 10);
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoPivoteCabecera, ftString, 1);
    oCabecera.CreateDataSet;
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoSerieLinea, ftString, 10);
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoNumeroLinea, ftString, 10);
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoArticuloLinea, ftString, 20);
    oLineas.CreateDataSet;
    oCabecera.Append;
    oCabecera.FieldByName(
      oConfiguracion.CampoSerieCabecera).AsString := 'P';
    oCabecera.FieldByName(
      oConfiguracion.CampoNumeroCabecera).AsString := '0';
    AsegurarCabeceraPersistidaCompra(
      oCabecera, nil, oConfiguracion, nil);
    Assert.IsTrue(oCabecera.State = dsBrowse);
    Assert.AreEqual('N', oCabecera.FieldByName(
      oConfiguracion.CampoPivoteCabecera).AsString);
    oCabecera.Edit;
    oCabecera.FieldByName(
      oConfiguracion.CampoNumeroCabecera).AsString := '15';
    oLineas.Append;
    oLineas.FieldByName(
      oConfiguracion.CampoArticuloLinea).AsString := 'ART1';
    AsegurarCabeceraPersistidaCompra(
      oCabecera, oLineas, oConfiguracion, nil);
    Assert.AreEqual('P', oLineas.FieldByName(
      oConfiguracion.CampoSerieLinea).AsString);
    Assert.AreEqual('15', oLineas.FieldByName(
      oConfiguracion.CampoNumeroLinea).AsString);
    Assert.IsTrue(oLineas.State = dsInsert);
  finally
    oLineas.Free;
    oCabecera.Free;
  end;
end;

procedure TPruebasValidacionTallasCompra.
  PersistenciaVenta_RecreaLineaVacia;
var
  oCabecera: TClientDataSet;
  oConfiguracion: TConfiguracionDocumento;
  oLineas: TClientDataSet;
begin
  oConfiguracion := CrearConfiguracionDocumento(
    tdPedido,
    sdVenta);
  oConfiguracion.MensajeCabeceraNoDisponible :=
    'Debe existir la cabecera.';
  oConfiguracion.CampoProductoLinea :=
    'CODIGOPRODPS_PEDLIN';
  oConfiguracion.RecrearLineaVacia := True;
  oCabecera := TClientDataSet.Create(nil);
  oLineas := TClientDataSet.Create(nil);
  try
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoSerieCabecera, ftString, 10);
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoNumeroCabecera, ftString, 10);
    oCabecera.CreateDataSet;
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoSerieLinea, ftString, 10);
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoNumeroLinea, ftString, 10);
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoArticuloLinea, ftString, 20);
    oLineas.FieldDefs.Add(
      oConfiguracion.CampoProductoLinea, ftString, 20);
    oLineas.CreateDataSet;
    oCabecera.Append;
    oCabecera.FieldByName(
      oConfiguracion.CampoSerieCabecera).AsString := 'V';
    oCabecera.FieldByName(
      oConfiguracion.CampoNumeroCabecera).AsString := '15';
    oLineas.Append;
    AsegurarCabeceraPersistidaDocumento(
      oCabecera, oLineas, oConfiguracion, nil);
    Assert.IsTrue(oCabecera.State = dsBrowse);
    Assert.IsTrue(oLineas.State = dsInsert);
    Assert.AreEqual('', oLineas.FieldByName(
      oConfiguracion.CampoProductoLinea).AsString);
  finally
    oLineas.Free;
    oCabecera.Free;
  end;
end;

procedure TPruebasValidacionTallasCompra.
  TallasHorizontal_UsaLecturasInyectadas;
var
  oCabecera: TClientDataSet;
  oConfiguracion: TConfiguracionDocumento;
  oLecturas: IValidacionDocumentoLecturas;
  sMensaje: string;
begin
  FAseguramientos := 0;
  FValidaciones := 0;
  oConfiguracion := ConfiguracionPedido;
  oCabecera := TClientDataSet.Create(nil);
  try
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoSerieCabecera, ftString, 10);
    oCabecera.FieldDefs.Add(
      oConfiguracion.CampoNumeroCabecera, ftString, 10);
    oCabecera.CreateDataSet;
    oCabecera.AppendRecord(['P', '15']);
    oLecturas := TLecturasValidacionDocumentoPrueba.Create(['ART1']);
    Assert.IsFalse(PuedeActivarTallasHorizontalCompra(
      oCabecera, nil, oLecturas, oConfiguracion,
      AsegurarCabecera, ValidarPivote, sMensaje));
    Assert.IsTrue(Pos('ART1', sMensaje) > 0);
    Assert.AreEqual(0, FValidaciones);
    oLecturas := TLecturasValidacionDocumentoPrueba.Create([]);
    Assert.IsTrue(PuedeActivarTallasHorizontalCompra(
      oCabecera, nil, oLecturas, oConfiguracion,
      AsegurarCabecera, ValidarPivote, sMensaje));
    Assert.AreEqual(1, FValidaciones);
    Assert.AreEqual(0, FAseguramientos);
  finally
    oCabecera.Free;
  end;
end;

end.
