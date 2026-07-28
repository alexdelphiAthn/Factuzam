{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasValoresAutomaticos                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de series y valores automáticos sin acceso a la BBDD.             }
{******************************************************************************}
unit PruebasValoresAutomaticos;

interface

uses
  Data.DB, Datasnap.DBClient,
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasValoresAutomaticos = class
  private
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure SeriePropia_SinDatosNoConsulta;
    [Test]
    procedure SerieDefecto_SinDatosNoConsulta;
    [Test]
    procedure CargarSeries_SinDatosLimpiaLista;
    [Test]
    procedure AsignarValor_ConvierteTipos;
    [Test]
    procedure AsignarValor_CampoInexistenteNoAltera;
    [Test]
    procedure AsignarValor_InvalidoUsaCero;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  inLibValoresAutomaticos, inLibtb;

const
  MARGEN = 0.0001;

procedure TPruebasValoresAutomaticos.Preparar;
begin
  FDataSet := TClientDataSet.Create(nil);
  FDataSet.FieldDefs.Add(
    'CODIGO', ftString, 20);
  FDataSet.FieldDefs.Add(
    'ENTERO', ftInteger);
  FDataSet.FieldDefs.Add(
    'DECIMAL', ftFloat);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord([
    'INICIAL',
    1,
    1.0]);
end;

procedure TPruebasValoresAutomaticos.Limpiar;
begin
  FreeAndNil(FDataSet);
end;

procedure TPruebasValoresAutomaticos.
  SeriePropia_SinDatosNoConsulta;
begin
  Assert.AreEqual(
    '',
    inLibValoresAutomaticos.
      ObtenerSeriePropiaAlmacen(
        nil, '', 'AV', 'A1'));
  Assert.AreEqual(
    '',
    inLibtb.ObtenerSeriePropiaAlmacen(
      nil, 'EMP', 'AV', ''));
end;

procedure TPruebasValoresAutomaticos.
  SerieDefecto_SinDatosNoConsulta;
begin
  Assert.AreEqual(
    '',
    inLibValoresAutomaticos.ObtenerSerieDefecto(
      nil, '', 'AV'));
  Assert.AreEqual(
    '',
    inLibtb.ObtenerSerieDefecto(
      nil, 'EMP', ''));
end;

procedure TPruebasValoresAutomaticos.
  CargarSeries_SinDatosLimpiaLista;
var
  oElementos: TStringList;
begin
  oElementos := TStringList.Create;
  try
    oElementos.Add('ANTERIOR');
    inLibValoresAutomaticos.CargarSeriesEmpresa(
      nil, '', 'AV', oElementos);
    Assert.AreEqual(0, oElementos.Count);
    oElementos.Add('ANTERIOR');
    inLibtb.CargarSeriesEmpresa(
      nil, 'EMP', '', oElementos);
    Assert.AreEqual(0, oElementos.Count);
  finally
    FreeAndNil(oElementos);
  end;
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_ConvierteTipos;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'CODIGO', 'NUEVO', 'STRING');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'ENTERO', '25', 'INTEGER');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DECIMAL', '12', 'FLOAT');
  Assert.AreEqual(
    'NUEVO',
    FDataSet.FieldByName(
      'CODIGO').AsString);
  Assert.AreEqual(
    25,
    FDataSet.FieldByName(
      'ENTERO').AsInteger);
  Assert.AreEqual(
    Double(12),
    FDataSet.FieldByName(
      'DECIMAL').AsFloat,
    MARGEN);
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_CampoInexistenteNoAltera;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DESCONOCIDO', 'OTRO', 'STRING');
  Assert.AreEqual(
    'INICIAL',
    FDataSet.FieldByName(
      'CODIGO').AsString);
end;

procedure TPruebasValoresAutomaticos.
  AsignarValor_InvalidoUsaCero;
begin
  FDataSet.Edit;
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'ENTERO', 'NO_NUMERO', 'INTEGER');
  inLibValoresAutomaticos.AsignarValorPorDefecto(
    FDataSet, 'DECIMAL', 'NO_NUMERO', 'FLOAT');
  Assert.AreEqual(
    0,
    FDataSet.FieldByName(
      'ENTERO').AsInteger);
  Assert.AreEqual(
    Double(0),
    FDataSet.FieldByName(
      'DECIMAL').AsFloat,
    MARGEN);
end;

end.
