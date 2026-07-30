{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosResolverCatalogo                              }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el contrato SQL-2.1 del resolver de artículos sin BBDD.          }
{******************************************************************************}
unit PruebasArticulosResolverCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosResolverCatalogo = class
  public
    [Test]
    procedure Definiciones_SonDiezLecturasValidas;
    [Test]
    procedure ListarSkus_UsaContratoEstructuralFijo;
    [Test]
    procedure PerfilSinCamposObligatorios_ResuelveSqlBase;
    [Test]
    procedure FalloDeEjecucion_ReintentaSqlBaseSinBbdd;
    [Test]
    procedure VentanaDescuento_RespetaCotasAbiertas;
  end;

implementation

uses
  System.SysUtils,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlValidacion,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlEjecucion,
  inLibPerfilesUsuarioIntf,
  inLibArticulosResolverIntf,
  UniDataArticulosResolverRepositorio;

type
  TCatalogoSqlArticuloFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlArticuloFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlArticuloFijo.Resolver(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
begin
  Result.Texto := FSqlPerfil;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := '';
  Result.Origen := osPerfil;
  Result.Politica := ADefinicion.Politica;
end;

procedure TPruebasArticulosResolverCatalogo.
  Definiciones_SonDiezLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioArticulosResolver.DefinicionesSql;
  Assert.AreEqual(
    10,
    Integer(Length(oDefiniciones)));
  for iDefinicion := 0 to High(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioArticulosResolver',
      oDefiniciones[iDefinicion].Repositorio);
    Assert.AreEqual(
      Ord(tssSelect),
      Ord(oDefiniciones[iDefinicion].TipoSentencia));
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(oDefiniciones[iDefinicion].Politica));
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iDefinicion]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
  end;
end;

procedure TPruebasArticulosResolverCatalogo.
  ListarSkus_UsaContratoEstructuralFijo;
var
  oDefinicion: TDefinicionSql;
  oDefiniciones: TDefinicionesSql;
begin
  oDefiniciones :=
    TRepositorioArticulosResolver.DefinicionesSql;
  oDefinicion := oDefiniciones[9];
  Assert.AreEqual('ListarSkus', oDefinicion.Operacion);
  Assert.AreEqual('art,incluir', oDefinicion.Parametros);
  Assert.IsTrue(
    Pos(':incluir', oDefinicion.SqlBase) > 0);
  Assert.IsTrue(
    Pos('ESACTIVO_SKU', oDefinicion.SqlBase) > 0);
end;

procedure TPruebasArticulosResolverCatalogo.
  PerfilSinCamposObligatorios_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oDefiniciones: TDefinicionesSql;
  oPerfil: TProfileDicc;
  oResultado: TSqlResuelto;
  oValor: TDictValue;
begin
  oDefiniciones :=
    TRepositorioArticulosResolver.DefinicionesSql;
  oDefinicion := oDefiniciones[2];
  oPerfil := TProfileDicc.Create;
  try
    oValor.sValue := 'S;V=1';
    oValor.sValueText :=
      'SELECT CODIGO_TAR_ARTTAR ' +
      'FROM fza_articulos_tarifas ' +
      'WHERE CODIGO_ART_ARTTAR = :art ' +
      'AND CODIGO_UNIDAD_ARTTAR = :sku ' +
      'AND CODIGO_TAR_ARTTAR = :tar ' +
      'AND :fec = :fec';
    oPerfil.Add(
      ClavePerfilSql(oDefinicion),
      oValor);
    oCatalogo := TCatalogoSqlPerfiles.Create(
      oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(Ord(osBase), Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasArticulosResolverCatalogo.
  FalloDeEjecucion_ReintentaSqlBaseSinBbdd;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oDefiniciones: TDefinicionesSql;
begin
  iIntentos := 0;
  oDefiniciones :=
    TRepositorioArticulosResolver.DefinicionesSql;
  oDefinicion := oDefiniciones[1];
  oCatalogo := TCatalogoSqlArticuloFijo.Create(
    'SELECT CODIGO_UNIDAD_SKU ' +
    'FROM perfil_articulos WHERE CODIGO_ART_SKU = :art');
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    oCatalogo,
    procedure(const ASql: string)
    begin
      Inc(iIntentos);
      if ASql <> oDefinicion.SqlBase then
        raise Exception.Create(
          'Fallo simulado del perfil');
    end);
  Assert.AreEqual(2, iIntentos);
end;

procedure TPruebasArticulosResolverCatalogo.
  VentanaDescuento_RespetaCotasAbiertas;
var
  dDia: TDateTime;
begin
  dDia := EncodeDate(2026, 7, 30);
  Assert.IsTrue(
    DescuentoEnVentana(dDia, 0, 0));
  Assert.IsTrue(
    DescuentoEnVentana(
      dDia,
      EncodeDate(2026, 7, 1),
      EncodeDate(2026, 7, 30)));
  Assert.IsFalse(
    DescuentoEnVentana(
      dDia,
      EncodeDate(2026, 7, 31),
      0));
  Assert.IsFalse(
    DescuentoEnVentana(
      dDia,
      0,
      EncodeDate(2026, 7, 29)));
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasArticulosResolverCatalogo);

end.
