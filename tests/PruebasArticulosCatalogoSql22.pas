{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosCatalogoSql22                                 }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica los contratos SQL-2.2 de validación y atributos.                 }
{******************************************************************************}
unit PruebasArticulosCatalogoSql22;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosCatalogoSql22 = class
  public
    [Test]
    procedure Validador_RegistraSieteLecturasValidas;
    [Test]
    procedure Atributos_RegistraSieteLecturasValidas;
    [Test]
    procedure ResolverEntrada_UsaParametroEstructural;
    [Test]
    procedure PerfilValido_SeComparteSinClaveDePantalla;
    [Test]
    procedure PerfilSinCampos_ResuelveSqlBase;
    [Test]
    procedure FalloDeEjecucion_ReintentaSqlBase;
  end;

implementation

uses
  System.SysUtils,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlValidacion,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlEjecucion,
  inLibPerfilesUsuarioIntf,
  UniDataArticulosValidadorRepositorio,
  UniDataArticulosAtributosRepositorio;

type
  TCatalogoSqlFijo22 = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlFijo22.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlFijo22.Resolver(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
begin
  Result.Texto := FSqlPerfil;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := '';
  Result.Origen := osPerfil;
  Result.Politica := ADefinicion.Politica;
end;

procedure ValidarDefiniciones(
  const ARepositorio: string;
  const ADefiniciones: TDefinicionesSql);
var
  iDefinicion: Integer;
  oValidacion: TResultadoValidacionSql;
begin
  Assert.AreEqual(
    7,
    Integer(Length(ADefiniciones)));
  for iDefinicion := 0 to High(ADefiniciones) do
  begin
    Assert.AreEqual(
      ARepositorio,
      ADefiniciones[iDefinicion].Repositorio);
    Assert.AreEqual(
      Ord(tssSelect),
      Ord(ADefiniciones[iDefinicion].TipoSentencia));
    Assert.AreEqual(
      Ord(pesPerfilLecturaConFallback),
      Ord(ADefiniciones[iDefinicion].Politica));
    oValidacion := ValidarDefinicionSql(
      ADefiniciones[iDefinicion]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
  end;
end;

function CrearCatalogoConPerfil(
  const ADefinicion: TDefinicionSql;
  const ASql: string): ICatalogoSql;
var
  oPerfil: TProfileDicc;
  oValor: TDictValue;
begin
  oValor.sValue := 'S;V=1';
  oValor.sValueText := ASql;
  oPerfil := TProfileDicc.Create;
  try
    oPerfil.Add(
      ClavePerfilSql(ADefinicion),
      oValor);
    Result := TCatalogoSqlPerfiles.Create(
      oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
end;

procedure TPruebasArticulosCatalogoSql22.
  Validador_RegistraSieteLecturasValidas;
begin
  ValidarDefiniciones(
    'RepositorioArticulosValidador',
    TRepositorioArticulosValidador.DefinicionesSql);
end;

procedure TPruebasArticulosCatalogoSql22.
  Atributos_RegistraSieteLecturasValidas;
begin
  ValidarDefiniciones(
    'RepositorioArticulosAtributos',
    TRepositorioArticulosAtributos.DefinicionesSql);
end;

procedure TPruebasArticulosCatalogoSql22.
  ResolverEntrada_UsaParametroEstructural;
var
  oDefiniciones: TDefinicionesSql;
begin
  oDefiniciones :=
    TRepositorioArticulosValidador.DefinicionesSql;
  Assert.AreEqual(
    'ResolverEntrada',
    oDefiniciones[5].Operacion);
  Assert.AreEqual(
    'inp,solo',
    oDefiniciones[5].Parametros);
  Assert.IsTrue(
    Pos(':solo', oDefiniciones[5].SqlBase) > 0);
  Assert.IsFalse(
    Pos('+ sFiltroTipo', oDefiniciones[5].SqlBase) > 0);
end;

procedure TPruebasArticulosCatalogoSql22.
  PerfilValido_SeComparteSinClaveDePantalla;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
  sSqlPerfil: string;
begin
  oDefinicion :=
    TRepositorioArticulosValidador.DefinicionesSql[0];
  sSqlPerfil :=
    'SELECT COUNT(*) AS N ' +
    'FROM vi_caja_busqueda_unificada ' +
    'WHERE INPUT_BUSQUEDA = :inp AND :solo = :solo';
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    sSqlPerfil);
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osPerfil),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    'SQL__RepositorioArticulosValidador__ContarCoincidencias',
    oResultado.ClavePerfil);
end;

procedure TPruebasArticulosCatalogoSql22.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioArticulosAtributos.DefinicionesSql[3];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT ID_ATB_VA FROM fza_variaciones_atributos ' +
    'WHERE :art = :art');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasArticulosCatalogoSql22.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioArticulosAtributos.DefinicionesSql[6];
  oCatalogo := TCatalogoSqlFijo22.Create(
    'SELECT ID_AV, AV, DESCRIPCION_AV, ORDEN_AV, ESACTIVO_AV ' +
    'FROM perfil WHERE :padre = :padre AND :orden = :orden');
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

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasArticulosCatalogoSql22);

end.
