{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArqueoCatalogo                                        }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica las definiciones del read model de cálculo de arqueo.            }
{******************************************************************************}
unit PruebasArqueoCatalogo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArqueoCatalogo = class
  public
    [Test]
    procedure RegistraDiezLecturasValidas;
    [Test]
    procedure ComprobacionEsquema_UsaSoloSqlBase;
    [Test]
    procedure Operaciones_DeclaraContratoCompleto;
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
  UniDataArqueoRepositorio;

type
  TCatalogoSqlArqueoFijo = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FSqlPerfil: string;
  public
    constructor Create(const ASqlPerfil: string);
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

constructor TCatalogoSqlArqueoFijo.Create(
  const ASqlPerfil: string);
begin
  inherited Create;
  FSqlPerfil := ASqlPerfil;
end;

function TCatalogoSqlArqueoFijo.Resolver(
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

procedure TPruebasArqueoCatalogo.
  RegistraDiezLecturasValidas;
var
  iDefinicion: Integer;
  oDefiniciones: TDefinicionesSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefiniciones :=
    TRepositorioArqueoCaja.DefinicionesSql;
  Assert.AreEqual(
    10,
    Integer(Length(oDefiniciones)));
  iDefinicion := 0;
  while iDefinicion < Length(oDefiniciones) do
  begin
    Assert.AreEqual(
      'RepositorioArqueoCaja',
      oDefiniciones[iDefinicion].Repositorio);
    Assert.AreEqual(
      Ord(tssSelect),
      Ord(oDefiniciones[iDefinicion].TipoSentencia));
    oValidacion := ValidarDefinicionSql(
      oDefiniciones[iDefinicion]);
    Assert.IsTrue(
      oValidacion.EsValido,
      oValidacion.Mensaje);
    Inc(iDefinicion);
  end;
end;

procedure TPruebasArqueoCatalogo.
  ComprobacionEsquema_UsaSoloSqlBase;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoCaja.DefinicionesSql[8];
  Assert.AreEqual(
    'ComprobarEfectivoAnterior',
    oDefinicion.Operacion);
  Assert.AreEqual(
    Ord(pesSoloBase),
    Ord(oDefinicion.Politica));
  Assert.IsTrue(
    Pos('INFORMATION_SCHEMA.COLUMNS',
      UpperCase(oDefinicion.SqlBase)) > 0);
end;

procedure TPruebasArqueoCatalogo.
  Operaciones_DeclaraContratoCompleto;
var
  oDefinicion: TDefinicionSql;
begin
  oDefinicion :=
    TRepositorioArqueoCaja.DefinicionesSql[2];
  Assert.AreEqual(
    'CalcularOperaciones',
    oDefinicion.Operacion);
  Assert.AreEqual(
    'NETO,V_NORMALES,V_DEVOL,ENTRADAS,SALIDAS',
    oDefinicion.CamposResultado);
  Assert.IsTrue(
    Pos('pTIPO_DE', oDefinicion.Parametros) > 0);
  Assert.AreEqual(
    Ord(pesPerfilLecturaConFallback),
    Ord(oDefinicion.Politica));
end;

procedure TPruebasArqueoCatalogo.
  PerfilSinCampos_ResuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion :=
    TRepositorioArqueoCaja.DefinicionesSql[3];
  oCatalogo := CrearCatalogoConPerfil(
    oDefinicion,
    'SELECT 0 AS OTRO FROM fza_depositos_cliente ' +
    'WHERE :pEMPRESA = :pEMPRESA AND :pALMACEN = :pALMACEN ' +
    'AND :pCAJA = :pCAJA AND :pFDESDE = :pFDESDE ' +
    'AND :pFHASTA = :pFHASTA');
  oResultado := oCatalogo.Resolver(
    oDefinicion);
  Assert.AreEqual(
    Ord(osBase),
    Ord(oResultado.Origen));
  Assert.AreEqual(
    oDefinicion.SqlBase,
    oResultado.Texto);
end;

procedure TPruebasArqueoCatalogo.
  FalloDeEjecucion_ReintentaSqlBase;
var
  iIntentos: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iIntentos := 0;
  oDefinicion :=
    TRepositorioArqueoCaja.DefinicionesSql[9];
  oCatalogo := TCatalogoSqlArqueoFijo.Create(
    'SELECT EFECTIVO_DEJADO_CAJA_ARQ FROM perfil ' +
    'WHERE :pEMPRESA = :pEMPRESA AND :pALMACEN = :pALMACEN ' +
    'AND :pCAJA = :pCAJA AND :pFDESDE = :pFDESDE');
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
    TPruebasArqueoCatalogo);

end.
