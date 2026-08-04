{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaStockRepositorio                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de las lecturas de stock usadas por Caja.                }
{******************************************************************************}
unit UniDataCajaStockRepositorio;

interface

uses
  Uni,
  inLibCajaStockPersistenciaIntf;

function CrearCajaStockRepositorio(
  AConexion: TUniConnection): ICajaStockPersistencia;

implementation

uses
  System.SysUtils,
  Data.DB;

type
  TCajaStockRepositorio = class(
    TInterfacedObject,
    ICajaStockPersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerEstadoSku(
      const ACodigoSku: string): TEstadoSkuCajaStock;
    function ObtenerCantidadDisponible(
      const ACodigoSku, ACodigoAlmacen: string): Double;
  end;

function CrearCajaStockRepositorio(
  AConexion: TUniConnection): ICajaStockPersistencia;
begin
  Result := TCajaStockRepositorio.Create(AConexion);
end;

constructor TCajaStockRepositorio.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TCajaStockRepositorio.ObtenerEstadoSku(
  const ACodigoSku: string): TEstadoSkuCajaStock;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TEstadoSkuCajaStock);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ESACTIVO_SKU ' +
      '  FROM fza_articulos_skus ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result.Existe := not oConsulta.IsEmpty;
    if Result.Existe then
    begin
      Result.Activo :=
        oConsulta.FieldByName('ESACTIVO_SKU').AsString = 'S';
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCajaStockRepositorio.ObtenerCantidadDisponible(
  const ACodigoSku, ACodigoAlmacen: string): Double;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if Trim(ACodigoAlmacen) <> '' then
    begin
      oConsulta.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU ' +
        '   AND CODIGO_ALM_STK = :ALMACEN';
      oConsulta.ParamByName('ALMACEN').AsString := ACodigoAlmacen;
    end
    else
    begin
      oConsulta.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU';
    end;
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsFloat;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
