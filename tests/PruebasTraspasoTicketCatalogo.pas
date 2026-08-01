{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTraspasoTicketCatalogo                                }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el contrato SQL del repositorio de tickets de traspaso.          }
{******************************************************************************}
unit PruebasTraspasoTicketCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTraspasoTicketCatalogo = class
  public
    [Test]
    procedure RegistraCincoLecturasValidas;
    [Test]
    procedure Stock_ExponeAliasEstable;
    [Test]
    procedure PerfilValido_UsaClaveCompartida;
    [Test]
    procedure PerfilSinCampoObligatorio_ResuelveSqlBase;
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
  UniDataTraspasoTicketRepositorio;

type
  TCatalogoSqlTraspasoFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlTraspasoFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlTraspasoFijo.Resolver(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
begin
  Result.Texto := FSqlPerfil;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := '';
  Result.Origen := osPerfil;
  Result.Politica := ADefinicion.Politica;
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

procedure TPruebasTraspasoTicketCatalogo.
  RegistraCincoLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioTraspasoTicket.DefinicionesSql;
  Assert.AreEqual(
    5,
    Integer(Length(oDefiniciones)));
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioTraspasoTicket',
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
    Inc(iDefinicion);
  end;
end;

procedure TPruebasTraspasoTicketCatalogo.
  Stock_ExponeAliasEstable;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioTraspasoTicket.DefinicionesSql[2];
  Assert.AreEqual(
    'ObtenerStock',
    oDefinicion.Operacion);
  Assert.AreEqual(
    'ALM,SKU',
    oDefinicion.Parametros);
  Assert.AreEqual(
    'STOCK',
    oDefinicion.CamposResultado);
  Assert.IsTrue(
    Pos(' AS STOCK', UpperCase(oDefinicion.SqlBase)) > 0);
end;

procedure TPruebasTraspasoTicketCatalogo.
  PerfilValido_UsaClaveCompartida;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioTraspasoTicket.DefinicionesSql[2];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT 0 AS STOCK FROM fza_articulos_stockactual ' +
    'WHERE :ALM = :ALM AND :SKU = :SKU');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osPerfil),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    'SQL__RepositorioTraspasoTicket__ObtenerStock',
    oResultado.ClavePerfil);
end;

procedure TPruebasTraspasoTicketCatalogo.
  PerfilSinCampoObligatorio_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioTraspasoTicket.DefinicionesSql[2];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT 0 AS OTRO FROM fza_articulos_stockactual ' +
    'WHERE :ALM = :ALM AND :SKU = :SKU');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasTraspasoTicketCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioTraspasoTicket.DefinicionesSql[4];
  oCatalogo := TCatalogoSqlTraspasoFijo.Create(
    'SELECT CODIGO_UNIDAD_MOV, CANTIDAD_MOV, ' +
    'DESCRIPCION FROM perfil WHERE :EMP = :EMP ' +
    'AND :ALM = :ALM AND :CAJA = :CAJA AND :NUMOP = :NUMOP');
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
  Assert.AreEqual(
    2,
    iIntentos);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasTraspasoTicketCatalogo);

end.
