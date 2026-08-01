{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArqueoTicketCatalogo                                  }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el catálogo de lecturas de presentación del arqueo.             }
{******************************************************************************}
unit PruebasArqueoTicketCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArqueoTicketCatalogo = class
  public
    [Test]
    procedure RegistraOnceLecturasValidas;
    [Test]
    procedure ResumenSeccion_UsaProfundidadParametrizada;
    [Test]
    procedure CierreHistorico_DeclaraCamposNucleo;
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
  UniDataArqueoTicketRepositorio;

type
  TCatalogoSqlArqueoTicketFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlArqueoTicketFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlArqueoTicketFijo.Resolver(
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

procedure TPruebasArqueoTicketCatalogo.
  RegistraOnceLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioArqueoTicket.DefinicionesSql;
  Assert.AreEqual(
    11,
    Integer(Length(oDefiniciones)));
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioArqueoTicket',
      oDefiniciones[iDefinicion].Repositorio);
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

procedure TPruebasArqueoTicketCatalogo.
  ResumenSeccion_UsaProfundidadParametrizada;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[3];
  Assert.AreEqual(
    'ListarResumenSeccion',
    oDefinicion.Operacion);
  Assert.IsTrue(
    Pos('pNIVELES', oDefinicion.Parametros) > 0);
  Assert.IsTrue(
    Pos(':pNIVELES', oDefinicion.SqlBase) > 0);
  Assert.AreEqual(
    'FAMILIA,UDS,NETO',
    oDefinicion.CamposResultado);
end;

procedure TPruebasArqueoTicketCatalogo.
  CierreHistorico_DeclaraCamposNucleo;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[9];
  Assert.AreEqual(
    'ObtenerCierreHistorico',
    oDefinicion.Operacion);
  Assert.IsTrue(
    Pos(
      'TOTAL_EFECTIVO_CAJA_ARQ',
      oDefinicion.CamposResultado) > 0);
  Assert.IsTrue(
    Pos(
      'NOMBRE_VENDEDOR',
      oDefinicion.CamposResultado) > 0);
end;

procedure TPruebasArqueoTicketCatalogo.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[0];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT NIF_EMP FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :pEMPRESA');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasArqueoTicketCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioArqueoTicket.DefinicionesSql[8];
  oCatalogo := TCatalogoSqlArqueoTicketFijo.Create(
    'SELECT CODIGO_EMP_ARQ, CODIGO_ALM_ARQ, CODIGO_CAJA_ARQ, ' +
    'FECHA_DESDE_ARQ, FECHA_HASTA_ARQ FROM perfil ' +
    'WHERE :pARQ = :pARQ AND :pEMP = :pEMP ' +
    'AND :pALM = :pALM AND :pCAJA = :pCAJA');
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
    TPruebasArqueoTicketCatalogo);

end.
