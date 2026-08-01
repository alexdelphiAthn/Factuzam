{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTicketsCajaCatalogo                                    }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el catálogo de tickets, resguardos y recordatorios de Caja.      }
{******************************************************************************}
unit PruebasTicketsCajaCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTicketsCajaCatalogo = class
  public
    [Test]
    procedure RegistraQuinceLecturasYUnaComprobacionTecnica;
    [Test]
    procedure CabeceraIncluyeFormatoYVendedor;
    [Test]
    procedure PieTecnicoPermaneceSoloBase;
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
  UniDataTicketsCajaRepositorio;

type
  TCatalogoSqlTicketsCajaFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlTicketsCajaFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlTicketsCajaFijo.Resolver(
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

procedure TPruebasTicketsCajaCatalogo.
  RegistraQuinceLecturasYUnaComprobacionTecnica;
var
  iDefinicion: Integer;
  iLecturasPerfil: Integer;
  iSoloBase: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioTicketsCaja.DefinicionesSql;
  Assert.AreEqual(
    16,
    Integer(Length(oDefiniciones)));
  iLecturasPerfil := 0;
  iSoloBase := 0;
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioTicketsCaja',
      oDefiniciones[iDefinicion].Repositorio);
    if oDefiniciones[iDefinicion].Politica =
       pesPerfilLecturaConFallback then
      Inc(iLecturasPerfil)
    else if oDefiniciones[iDefinicion].Politica = pesSoloBase then
      Inc(iSoloBase);
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iDefinicion]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Inc(iDefinicion);
  end;
  Assert.AreEqual(15, iLecturasPerfil);
  Assert.AreEqual(1, iSoloBase);
end;

procedure TPruebasTicketsCajaCatalogo.
  CabeceraIncluyeFormatoYVendedor;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioTicketsCaja.DefinicionesSql[7];
  Assert.AreEqual(
    'ObtenerCabeceraTicket',
    oDefinicion.Operacion);
  Assert.AreEqual(
    'EMP,ALM,CAJA,OP',
    oDefinicion.Parametros);
  Assert.IsTrue(
    Pos(
      'FORMATO_DOCUMENTO_EMP',
      oDefinicion.CamposResultado) > 0);
  Assert.IsTrue(
    Pos(
      'DIMINUTIVO_TICKET_EMPL',
      oDefinicion.CamposResultado) > 0);
end;

procedure TPruebasTicketsCajaCatalogo.
  PieTecnicoPermaneceSoloBase;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioTicketsCaja.DefinicionesSql[14];
  Assert.AreEqual(
    'ComprobarPieTicketDisponible',
    oDefinicion.Operacion);
  Assert.AreEqual(
    Ord(pesSoloBase),
    Ord(oDefinicion.Politica));
  Assert.IsTrue(
    Pos('INFORMATION_SCHEMA', oDefinicion.SqlBase) > 0);
end;

procedure TPruebasTicketsCajaCatalogo.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioTicketsCaja.DefinicionesSql[0];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT CODIGO_EMP_EMP FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :EMP');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasTicketsCajaCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioTicketsCaja.DefinicionesSql[13];
  oCatalogo := TCatalogoSqlTicketsCajaFijo.Create(
    'SELECT ID_DEPOSITO_DEP FROM perfil WHERE :CLI = :CLI');
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
  TPruebasTicketsCajaCatalogo);

end.
