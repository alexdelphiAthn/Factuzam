{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos del catálogo de SQL sustituible mediante perfiles.              }
{******************************************************************************}
unit inLibCatalogoSqlIntf;

interface

const
  CLAVE_PERFIL_CATALOGO_SQL = 'SQL_REPOSITORIOS';

type
  TTipoSentenciaSql = (
    tssSelect,
    tssInsert,
    tssUpdate,
    tssDelete,
    tssCall);
  TOrigenSql = (
    osBase,
    osPerfil);
  TPoliticaEjecucionSql = (
    pesSoloBase,
    pesPerfilLecturaConFallback,
    pesPerfilEscrituraTransaccional);
  TDefinicionSql = record
    Repositorio: string;
    Operacion: string;
    SqlBase: string;
    Parametros: string;
    CamposResultado: string;
    TipoSentencia: TTipoSentenciaSql;
    Politica: TPoliticaEjecucionSql;
    Version: Integer;
  end;
  TSqlResuelto = record
    Texto: string;
    ClavePerfil: string;
    MotivoSqlBase: string;
    Origen: TOrigenSql;
    Politica: TPoliticaEjecucionSql;
  end;
  TResultadoValidacionSql = record
    EsValido: Boolean;
    Mensaje: string;
    Huella: string;
  end;
  TDefinicionesSql = array of TDefinicionSql;
  TProcedimientoEjecutarSql = reference to procedure(
    const ASql: string);
  ICatalogoSql = interface
    ['{E433B667-26D4-48F8-A16C-DCC47279640A}']
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;
  IRegistroDefinicionesSql = interface
    ['{798B2939-93D6-42C9-A76B-5D3BDF3A37D2}']
    function Cantidad: Integer;
    function ObtenerDefiniciones: TDefinicionesSql;
  end;
  IRegistroIncidenciasSql = interface
    ['{4AE44E47-9BB6-43B6-A1E0-90097656C290}']
    procedure Registrar(
      const AClavePerfil, ACausa: string);
    function ObtenerUltimaCausa(
      const AClavePerfil: string): string;
  end;

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros, ACamposResultado: string;
  ATipoSentencia: TTipoSentenciaSql;
  APolitica: TPoliticaEjecucionSql;
  AVersion: Integer = 1): TDefinicionSql;
function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
function NombrePoliticaEjecucionSql(
  APolitica: TPoliticaEjecucionSql): string;
function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string = ''): TSqlResuelto;

implementation

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros, ACamposResultado: string;
  ATipoSentencia: TTipoSentenciaSql;
  APolitica: TPoliticaEjecucionSql;
  AVersion: Integer): TDefinicionSql;
begin
  Result.Repositorio := ARepositorio;
  Result.Operacion := AOperacion;
  Result.SqlBase := ASqlBase;
  Result.Parametros := AParametros;
  Result.CamposResultado := ACamposResultado;
  Result.TipoSentencia := ATipoSentencia;
  Result.Politica := APolitica;
  Result.Version := AVersion;
end;

function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
begin
  Result := 'SQL__' + ADefinicion.Repositorio + '__' +
    ADefinicion.Operacion;
end;

function NombrePoliticaEjecucionSql(
  APolitica: TPoliticaEjecucionSql): string;
begin
  case APolitica of
    pesSoloBase:
      Result := 'SOLO_BASE';
    pesPerfilLecturaConFallback:
      Result := 'PERFIL_LECTURA_FALLBACK';
    pesPerfilEscrituraTransaccional:
      Result := 'PERFIL_ESCRITURA_TRANSACCIONAL';
  else
    Result := '';
  end;
end;

function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string): TSqlResuelto;
begin
  Result.Texto := ADefinicion.SqlBase;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := AMotivo;
  Result.Origen := osBase;
  Result.Politica := ADefinicion.Politica;
end;

end.
