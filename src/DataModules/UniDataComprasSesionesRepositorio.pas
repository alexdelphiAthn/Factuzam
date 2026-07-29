{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesRepositorio                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de sesiones de compra con SQL configurable.           }
{******************************************************************************}
unit UniDataComprasSesionesRepositorio;

interface

uses
  Uni, inLibCatalogoSqlIntf, inLibComprasSesionesIntf;

type
  TRepositorioComprasSesiones = class(
    TInterfacedObject,
    IRepositorioComprasSesiones)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    function EjecutarObtenerSiguienteLinea(
      const ASql, ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function EjecutarConsultarCantidadesLinea(
      const ASql, ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ResolverSql(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
    procedure RegistrarFallback(
      const ADefinicion: TDefinicionSql;
      const AError: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
  end;

implementation

uses
  System.SysUtils, inLibLog;

const
  SQL_SIGUIENTE_LINEA =
    'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND LINEA_SESLIN > :l';
  SQL_CANTIDADES_LINEA =
    'SELECT ID_AV_PIVOT_SESCEL, ' +
    '       SUM(CANTIDAD_SESCEL) AS TOTAL ' +
    '  FROM fza_compras_sesiones_celdas ' +
    ' WHERE SERIE_SES_SESCEL = :s ' +
    '   AND NUMERO_SES_SESCEL = :n ' +
    '   AND LINEA_SES_SESCEL = :l ' +
    ' GROUP BY ID_AV_PIVOT_SESCEL';

function DefinicionSiguienteLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerSiguienteLinea',
    SQL_SIGUIENTE_LINEA,
    's,n,l',
    tssSelect);
end;

function DefinicionCantidadesLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarCantidadesLinea',
    SQL_CANTIDADES_LINEA,
    's,n,l',
    tssSelect);
end;

constructor TRepositorioComprasSesiones.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
end;

class function TRepositorioComprasSesiones.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 2);
  Result[0] := DefinicionSiguienteLinea;
  Result[1] := DefinicionCantidadesLinea;
end;

function TRepositorioComprasSesiones.ResolverSql(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
begin
  Result := ResolverSqlBase(ADefinicion);
  if Assigned(FCatalogoSql) then
    Result := FCatalogoSql.Resolver(ADefinicion);
  if Result.MotivoSqlBase <> '' then
    Log.LogError(Format(
      'SQL de perfil descartado. Clave=%s. Se usa SQL base. Motivo=%s',
      [Result.ClavePerfil, Result.MotivoSqlBase]));
end;

procedure TRepositorioComprasSesiones.RegistrarFallback(
  const ADefinicion: TDefinicionSql;
  const AError: string);
begin
  Log.LogError(Format(
    'SQL de perfil fallido. Clave=%s. Se reintenta con SQL base. Error=%s',
    [ClavePerfilSql(ADefinicion), AError]));
end;

function TRepositorioComprasSesiones.EjecutarObtenerSiguienteLinea(
  const ASql, ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALineaActual;
    oConsulta.Open;
    if not oConsulta.FieldByName('SIGUIENTE').IsNull then
      Result := oConsulta.FieldByName(
        'SIGUIENTE').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarConsultarCantidadesLinea(
  const ASql, ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].IdValorPivot :=
        oConsulta.FieldByName(
          'ID_AV_PIVOT_SESCEL').AsInteger;
      Result[iIndice].Cantidad :=
        oConsulta.FieldByName('TOTAL').AsFloat;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.ObtenerSiguienteLinea(
  const ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oDefinicion: TDefinicionSql;
  oSql: TSqlResuelto;
begin
  oDefinicion := DefinicionSiguienteLinea;
  oSql := ResolverSql(oDefinicion);
  try
    Result := EjecutarObtenerSiguienteLinea(
      oSql.Texto, ASerie, ANumero, ALineaActual);
  except
    on E: Exception do
    begin
      if oSql.Origen = osPerfil then
      begin
        RegistrarFallback(oDefinicion, E.Message);
        Result := EjecutarObtenerSiguienteLinea(
          oDefinicion.SqlBase,
          ASerie,
          ANumero,
          ALineaActual);
      end
      else
        raise;
    end;
  end;
end;

function TRepositorioComprasSesiones.ConsultarCantidadesLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  oDefinicion: TDefinicionSql;
  oSql: TSqlResuelto;
begin
  oDefinicion := DefinicionCantidadesLinea;
  oSql := ResolverSql(oDefinicion);
  try
    Result := EjecutarConsultarCantidadesLinea(
      oSql.Texto, ASerie, ANumero, ALinea);
  except
    on E: Exception do
    begin
      if oSql.Origen = osPerfil then
      begin
        RegistrarFallback(oDefinicion, E.Message);
        Result := EjecutarConsultarCantidadesLinea(
          oDefinicion.SqlBase,
          ASerie,
          ANumero,
          ALinea);
      end
      else
        raise;
    end;
  end;
end;

end.
