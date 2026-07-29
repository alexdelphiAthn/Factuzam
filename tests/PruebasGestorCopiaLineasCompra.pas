{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorCopiaLineasCompra                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las reglas de copia de líneas de sesiones de compra.           }
{******************************************************************************}
unit PruebasGestorCopiaLineasCompra;

interface

uses
  DUnitX.TestFramework, Datasnap.DBClient,
  inLibGestorCopiaLineasCompra;

type
  [TestFixture]
  TPruebasGestorCopiaLineasCompra = class
  private
    FCabecera: TClientDataSet;
    FLineas: TClientDataSet;
    FGestor: TGestorCopiaLineasCompra;
    FLineaSiguiente: Integer;
    function ObtenerSiguienteLinea(ALineaOrigen: Integer): Integer;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure OtroColor_CopiaPreciosYDejaColorVacio;
    [Test]
    procedure OtroPrecio_CopiaColorYDejaPreciosVacios;
    [Test]
    procedure CopiaPendiente_AplicaDecisionSinConocerFormulario;
  end;

implementation

uses
  System.SysUtils, Data.DB;

procedure TPruebasGestorCopiaLineasCompra.Preparar;
begin
  FCabecera := TClientDataSet.Create(nil);
  FCabecera.FieldDefs.Add('SERIE_SES', ftString, 10);
  FCabecera.FieldDefs.Add('NUMERO_SES', ftString, 10);
  FCabecera.CreateDataSet;
  FCabecera.AppendRecord(['S', '1']);
  FLineas := TClientDataSet.Create(nil);
  FLineas.FieldDefs.Add('LINEA_SESLIN', ftInteger);
  FLineas.FieldDefs.Add('CODIGO_FAM_SESLIN', ftString, 20);
  FLineas.FieldDefs.Add(
    'CODIGO_ART_TENTATIVO_SESLIN', ftString, 20);
  FLineas.FieldDefs.Add('REF_PRV_SESLIN', ftString, 20);
  FLineas.FieldDefs.Add('DESCRIPCION_SESLIN', ftString, 100);
  FLineas.FieldDefs.Add('PRECIO_COMPRA_SESLIN', ftFloat);
  FLineas.FieldDefs.Add('PRECIO_VENTA_SESLIN', ftFloat);
  FLineas.FieldDefs.Add('ID_AC_PIVOT_SESLIN', ftInteger);
  FLineas.FieldDefs.Add('PORCENTAJE_MARGEN_SESLIN', ftFloat);
  FLineas.FieldDefs.Add('TIPO_IVA_SESLIN', ftString, 2);
  FLineas.FieldDefs.Add('COLOR_TEXTO_SESLIN', ftString, 50);
  FLineas.FieldDefs.Add('CODIGO_ATB_COLOR_SESLIN', ftString, 20);
  FLineas.FieldDefs.Add('ESDUPLICADO_SESLIN', ftString, 1);
  FLineas.FieldDefs.Add(
    'ACCION_DUPLICADO_SESLIN', ftString, 20);
  FLineas.FieldDefs.Add(
    'CODIGO_ART_REUSAR_SESLIN', ftString, 20);
  FLineas.CreateDataSet;
  FLineas.Append;
  FLineas.FieldByName('LINEA_SESLIN').AsInteger := 10;
  FLineas.FieldByName('CODIGO_FAM_SESLIN').AsString := 'FAM';
  FLineas.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString := 'ART';
  FLineas.FieldByName('REF_PRV_SESLIN').AsString := 'MOD';
  FLineas.FieldByName('DESCRIPCION_SESLIN').AsString := 'Artículo';
  FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := 12;
  FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := 24;
  FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := 7;
  FLineas.FieldByName(
    'PORCENTAJE_MARGEN_SESLIN').AsFloat := 50;
  FLineas.FieldByName('TIPO_IVA_SESLIN').AsString := 'N';
  FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString := 'Rojo';
  FLineas.FieldByName(
    'CODIGO_ATB_COLOR_SESLIN').AsString := 'ROJO';
  FLineas.Post;
  FLineaSiguiente := 20;
  FGestor := TGestorCopiaLineasCompra.Create(
    FCabecera, FLineas, ObtenerSiguienteLinea);
end;

procedure TPruebasGestorCopiaLineasCompra.Limpiar;
begin
  FreeAndNil(FGestor);
  FreeAndNil(FLineas);
  FreeAndNil(FCabecera);
end;

function TPruebasGestorCopiaLineasCompra.ObtenerSiguienteLinea(
  ALineaOrigen: Integer): Integer;
begin
  Assert.AreEqual(10, ALineaOrigen);
  Result := FLineaSiguiente;
end;

procedure TPruebasGestorCopiaLineasCompra.
  OtroColor_CopiaPreciosYDejaColorVacio;
var
  oResultado: TResultadoCopiaLineaCompra;
begin
  oResultado := FGestor.DuplicarLineaActual(mclOtroColor);
  Assert.IsTrue(oResultado.Aplicada);
  Assert.AreEqual(10, oResultado.LineaOrigen);
  Assert.AreEqual(15, oResultado.LineaDestino);
  Assert.AreEqual(7, oResultado.IdConjuntoPivot);
  Assert.IsTrue(oResultado.CopiarCantidades);
  Assert.AreEqual(12.0,
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat, 0.001);
  Assert.AreEqual(24.0,
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat, 0.001);
  Assert.AreEqual('',
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString);
  Assert.AreEqual('',
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString);
  Assert.AreEqual('S',
    FLineas.FieldByName('ESDUPLICADO_SESLIN').AsString);
  Assert.AreEqual('REUSAR',
    FLineas.FieldByName('ACCION_DUPLICADO_SESLIN').AsString);
  Assert.AreEqual('ART',
    FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString);
end;

procedure TPruebasGestorCopiaLineasCompra.
  OtroPrecio_CopiaColorYDejaPreciosVacios;
var
  oResultado: TResultadoCopiaLineaCompra;
begin
  oResultado := FGestor.DuplicarLineaActual(mclOtroPrecio);
  Assert.IsTrue(oResultado.Aplicada);
  Assert.IsFalse(oResultado.CopiarCantidades);
  Assert.AreEqual('Rojo',
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString);
  Assert.AreEqual('ROJO',
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString);
  Assert.AreEqual(0.0,
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat, 0.001);
  Assert.AreEqual(0.0,
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat, 0.001);
end;

procedure TPruebasGestorCopiaLineasCompra.
  CopiaPendiente_AplicaDecisionSinConocerFormulario;
var
  oResultado: TResultadoCopiaLineaCompra;
begin
  FGestor.PrepararCopiaPendiente(
    'MOD', 5, 'Azul', 'AZUL', 35);
  Assert.IsTrue(FGestor.HayCopiaPendiente);
  Assert.AreEqual('MOD', FGestor.ModeloPendiente);
  Assert.AreEqual(5, FGestor.LineaOrigenPendiente);
  oResultado := FGestor.AplicarCopiaPendiente(mclOtroPrecio);
  Assert.IsTrue(oResultado.Aplicada);
  Assert.AreEqual(5, oResultado.LineaOrigen);
  Assert.AreEqual(10, oResultado.LineaDestino);
  Assert.IsFalse(oResultado.CopiarCantidades);
  Assert.AreEqual('Azul',
    FLineas.FieldByName('COLOR_TEXTO_SESLIN').AsString);
  Assert.AreEqual('AZUL',
    FLineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString);
  Assert.AreEqual(35.0,
    FLineas.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat, 0.001);
  Assert.AreEqual(0.0,
    FLineas.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat, 0.001);
  Assert.AreEqual(0.0,
    FLineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat, 0.001);
  FGestor.DescartarCopiaPendiente;
  Assert.IsFalse(FGestor.HayCopiaPendiente);
end;

end.
