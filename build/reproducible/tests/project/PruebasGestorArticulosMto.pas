{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorArticulosMto                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del gestor de artículo, foto y stock de mantenimientos.           }
{******************************************************************************}
unit PruebasGestorArticulosMto;

interface

uses
  Data.DB, Datasnap.DBClient, DUnitX.TestFramework,
  inLibGestorArticulosMto;

type
  [TestFixture]
  TPruebasGestorArticulosMto = class
  private
    FDataSet: TClientDataSet;
    FDataSource: TDataSource;
    FGestor: TGestorArticulosMto;
    FFotoVisible: Boolean;
    FResoluciones: Integer;
    FOcultaciones: Integer;
    FMuestrasFoto: Integer;
    FVinculaciones: Integer;
    FDataSourcesVinculados: Integer;
    FConsultasStock: Integer;
    FUltimoArt: string;
    FUltimoSku: string;
    procedure ResolverActivo(
      out ACodArt, ACodSku: string);
    function ObtenerDataSources: TArray<TDataSource>;
    function FotoVisible: Boolean;
    procedure OcultarFoto;
    procedure MostrarFoto(
      const ACodArt, ACodSku: string);
    procedure VincularFoto(
      const ADataSources: TArray<TDataSource>);
    procedure MostrarStock(
      const ACodArt, ACodSku: string);
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure ResolverPorDefecto_LeeCamposCanonicos;
    [Test]
    procedure DataSourcesPorDefecto_DevuelvePrincipal;
    [Test]
    procedure FotoVisible_OcultaSinResolver;
    [Test]
    procedure FotoOculta_MuestraYVincula;
    [Test]
    procedure ArticuloVacio_NoMuestraFoto;
    [Test]
    procedure ConsultaStock_PropagaArticuloSku;
    [Test]
    procedure DesvincularFoto_UsaListaVacia;
  end;

implementation

uses
  System.SysUtils;

procedure TPruebasGestorArticulosMto.Preparar;
begin
  FDataSet := TClientDataSet.Create(nil);
  FDataSet.FieldDefs.Add(
    'CODIGO_ART_FACLIN', ftString, 20);
  FDataSet.FieldDefs.Add(
    'CODIGO_UNIDAD_FACLIN', ftString, 40);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord(['ART-1', 'ART-1/ROJO/L']);
  FDataSource := TDataSource.Create(nil);
  FDataSource.DataSet := FDataSet;
  FFotoVisible := False;
  FResoluciones := 0;
  FOcultaciones := 0;
  FMuestrasFoto := 0;
  FVinculaciones := 0;
  FDataSourcesVinculados := -1;
  FConsultasStock := 0;
  FUltimoArt := '';
  FUltimoSku := '';
  FGestor := TGestorArticulosMto.Create(
    FDataSource, ResolverActivo,
    ObtenerDataSources, FotoVisible,
    OcultarFoto, MostrarFoto,
    VincularFoto, MostrarStock);
end;

procedure TPruebasGestorArticulosMto.Limpiar;
begin
  FreeAndNil(FGestor);
  FreeAndNil(FDataSource);
  FreeAndNil(FDataSet);
end;

procedure TPruebasGestorArticulosMto.ResolverActivo(
  out ACodArt, ACodSku: string);
begin
  Inc(FResoluciones);
  FGestor.ResolverPorDefecto(
    ACodArt, ACodSku);
end;

function TPruebasGestorArticulosMto.ObtenerDataSources:
  TArray<TDataSource>;
begin
  Result := FGestor.DataSourcesPorDefecto;
end;

function TPruebasGestorArticulosMto.FotoVisible: Boolean;
begin
  Result := FFotoVisible;
end;

procedure TPruebasGestorArticulosMto.OcultarFoto;
begin
  Inc(FOcultaciones);
end;

procedure TPruebasGestorArticulosMto.MostrarFoto(
  const ACodArt, ACodSku: string);
begin
  Inc(FMuestrasFoto);
  FUltimoArt := ACodArt;
  FUltimoSku := ACodSku;
end;

procedure TPruebasGestorArticulosMto.VincularFoto(
  const ADataSources: TArray<TDataSource>);
begin
  Inc(FVinculaciones);
  FDataSourcesVinculados := Length(ADataSources);
end;

procedure TPruebasGestorArticulosMto.MostrarStock(
  const ACodArt, ACodSku: string);
begin
  Inc(FConsultasStock);
  FUltimoArt := ACodArt;
  FUltimoSku := ACodSku;
end;

procedure TPruebasGestorArticulosMto.
  ResolverPorDefecto_LeeCamposCanonicos;
var
  sArt: string;
  sSku: string;
begin
  FGestor.ResolverPorDefecto(sArt, sSku);
  Assert.AreEqual('ART-1', sArt);
  Assert.AreEqual('ART-1/ROJO/L', sSku);
end;

procedure TPruebasGestorArticulosMto.
  DataSourcesPorDefecto_DevuelvePrincipal;
var
  aDataSources: TArray<TDataSource>;
begin
  aDataSources := FGestor.DataSourcesPorDefecto;
  Assert.AreEqual(
    1, Integer(Length(aDataSources)));
  Assert.IsTrue(aDataSources[0] = FDataSource);
end;

procedure TPruebasGestorArticulosMto.
  FotoVisible_OcultaSinResolver;
begin
  FFotoVisible := True;
  FGestor.AlternarFoto;
  Assert.AreEqual(1, FOcultaciones);
  Assert.AreEqual(0, FResoluciones);
  Assert.AreEqual(0, FMuestrasFoto);
  Assert.AreEqual(0, FVinculaciones);
end;

procedure TPruebasGestorArticulosMto.
  FotoOculta_MuestraYVincula;
begin
  FGestor.AlternarFoto;
  Assert.AreEqual(1, FResoluciones);
  Assert.AreEqual(1, FMuestrasFoto);
  Assert.AreEqual(1, FVinculaciones);
  Assert.AreEqual(1, FDataSourcesVinculados);
  Assert.AreEqual('ART-1', FUltimoArt);
  Assert.AreEqual('ART-1/ROJO/L', FUltimoSku);
end;

procedure TPruebasGestorArticulosMto.
  ArticuloVacio_NoMuestraFoto;
begin
  FDataSet.Edit;
  FDataSet.FieldByName(
    'CODIGO_ART_FACLIN').Clear;
  FDataSet.Post;
  FGestor.AlternarFoto;
  Assert.AreEqual(1, FResoluciones);
  Assert.AreEqual(0, FMuestrasFoto);
  Assert.AreEqual(0, FVinculaciones);
end;

procedure TPruebasGestorArticulosMto.
  ConsultaStock_PropagaArticuloSku;
begin
  FGestor.ConsultarStock;
  Assert.AreEqual(1, FResoluciones);
  Assert.AreEqual(1, FConsultasStock);
  Assert.AreEqual('ART-1', FUltimoArt);
  Assert.AreEqual('ART-1/ROJO/L', FUltimoSku);
end;

procedure TPruebasGestorArticulosMto.
  DesvincularFoto_UsaListaVacia;
begin
  FGestor.DesvincularFoto;
  Assert.AreEqual(1, FVinculaciones);
  Assert.AreEqual(0, FDataSourcesVinculados);
end;

end.
