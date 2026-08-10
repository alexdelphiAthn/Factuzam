{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTiraCajaTicketCatalogo                                }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el catálogo de lecturas de la tira de Caja.                     }
{******************************************************************************}
unit PruebasTiraCajaTicketCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTiraCajaTicketCatalogo = class
  public
    [Test]
    procedure RegistraSieteLecturasValidas;
    [Test]
    procedure Operaciones_UsaFiltrosEstables;
    [Test]
    procedure Detalles_SeCompartenEntreTicketYExcel;
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
  UniDataTiraCajaTicketRepositorio;

type
  TCatalogoSqlTiraCajaFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlTiraCajaFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlTiraCajaFijo.Resolver(
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

procedure TPruebasTiraCajaTicketCatalogo.
  RegistraSieteLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioTiraCajaTicket.DefinicionesSql;
  Assert.AreEqual(
    7,
    Integer(Length(oDefiniciones)));
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioTiraCajaTicket',
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

procedure TPruebasTiraCajaTicketCatalogo.
  Operaciones_UsaFiltrosEstables;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioTiraCajaTicket.DefinicionesSql[5];
  Assert.AreEqual(
    'ListarOperaciones',
    oDefinicion.Operacion);
  Assert.IsTrue(
    Pos('pTODAS_SERIES', oDefinicion.Parametros) > 0);
  Assert.IsTrue(
    Pos(':pTODAS_SERIES', oDefinicion.SqlBase) > 0);
  Assert.IsTrue(
    Pos(':pCRONOLOGICO', oDefinicion.SqlBase) > 0);
  Assert.IsTrue(
    Pos('FORMATO_DOCUMENTO_EMP',
      oDefinicion.CamposResultado) > 0);
end;

procedure TPruebasTiraCajaTicketCatalogo.
  Detalles_SeCompartenEntreTicketYExcel;
var
  oDefiniciones: TDefinicionesSql;
begin
  oDefiniciones :=
    TRepositorioTiraCajaTicket.DefinicionesSql;
  Assert.AreEqual(
    'ListarLineasVenta',
    oDefiniciones[1].Operacion);
  Assert.AreEqual(
    'ListarLineasTraspaso',
    oDefiniciones[3].Operacion);
  Assert.AreEqual(
    'ListarDepositos',
    oDefiniciones[4].Operacion);
end;

procedure TPruebasTiraCajaTicketCatalogo.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioTiraCajaTicket.DefinicionesSql[0];
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

procedure TPruebasTiraCajaTicketCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioTiraCajaTicket.DefinicionesSql[6];
  oCatalogo := TCatalogoSqlTiraCajaFijo.Create(
    'SELECT SERIE FROM perfil ' +
    'WHERE :pEMP = :pEMP AND :pALM = :pALM ' +
    'AND :pCAJA = :pCAJA AND :pFDESDE = :pFDESDE ' +
    'AND :pFHASTA = :pFHASTA');
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
    TPruebasTiraCajaTicketCatalogo);

end.
