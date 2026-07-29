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
  TDefinicionSql = record
    Repositorio: string;
    Operacion: string;
    SqlBase: string;
    Parametros: string;
    TipoSentencia: TTipoSentenciaSql;
    Version: Integer;
  end;
  TSqlResuelto = record
    Texto: string;
    ClavePerfil: string;
    MotivoSqlBase: string;
    Origen: TOrigenSql;
  end;
  TResultadoValidacionSql = record
    EsValido: Boolean;
    Mensaje: string;
    Huella: string;
  end;
  TDefinicionesSql = array of TDefinicionSql;
  ICatalogoSql = interface
    ['{E433B667-26D4-48F8-A16C-DCC47279640A}']
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros: string;
  ATipoSentencia: TTipoSentenciaSql;
  AVersion: Integer = 1): TDefinicionSql;
function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string = ''): TSqlResuelto;

implementation

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros: string;
  ATipoSentencia: TTipoSentenciaSql;
  AVersion: Integer): TDefinicionSql;
begin
  Result.Repositorio := ARepositorio;
  Result.Operacion := AOperacion;
  Result.SqlBase := ASqlBase;
  Result.Parametros := AParametros;
  Result.TipoSentencia := ATipoSentencia;
  Result.Version := AVersion;
end;

function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
begin
  Result := 'SQL__' + ADefinicion.Repositorio + '__' +
    ADefinicion.Operacion;
end;

function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string): TSqlResuelto;
begin
  Result.Texto := ADefinicion.SqlBase;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := AMotivo;
  Result.Origen := osBase;
end;

end.
