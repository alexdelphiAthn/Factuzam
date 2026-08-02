{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataEntradaAlbaranVentaRepositorio                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Lecturas UniDAC para la entrada de articulos en albaranes de venta.      }
{******************************************************************************}
unit UniDataEntradaAlbaranVentaRepositorio;

interface

uses
  Uni, inLibEntradaAlbaranVentaPersistenciaIntf;

function CrearRepositorioEntradaAlbaranVentaUniDAC(
  AConexion: TUniConnection): IRepositorioEntradaAlbaranVenta;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_ARTICULOS =
    'SELECT * ' +
    'FROM vi_art_busquedas ' +
    'WHERE (CODIGO_TAR_ARTTAR = :tarifa ' +
    'OR CODIGO_TAR_ARTTAR IS NULL) ' +
    'AND FECHA_DESDE_ARTTAR < :fecha ' +
    'AND (FECHA_HASTA_ARTTAR IS NULL ' +
    'OR FECHA_HASTA_ARTTAR > :fecha)';
  SQL_SKUS =
    'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
    'GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
    'AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
    'FROM fza_articulos_skus SK ' +
    'LEFT JOIN fza_atributos_sku SA ' +
    'ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    'LEFT JOIN fza_atributos_valores AV ' +
    'ON AV.ID_AV = SA.ID_AV_SA ' +
    'LEFT JOIN fza_variaciones_atributos VA ' +
    'ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
    'AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
    'WHERE SK.CODIGO_ART_SKU = :art ' +
    'AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
    'GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
    'ORDER BY SK.CODIGO_UNIDAD_SKU';
  SQL_CONFIGURACION_ARTICULO =
    'SELECT a.ESTRAZABLE_ART, a.ESVARIACION_ART, ' +
    '(SELECT COUNT(*) ' +
    'FROM fza_articulos_skus sk ' +
    'WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
    'AND COALESCE(sk.ESACTIVO_SKU, ''S'') = ''S'') AS NUM_SKUS ' +
    'FROM fza_articulos a ' +
    'WHERE a.CODIGO_ART_ART = :art';

type
  TConsultaEntradaAlbaranVentaUniDAC = class(
    TInterfacedObject,
    IConsultaEntradaAlbaranVenta)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioEntradaAlbaranVentaUniDAC = class(
    TInterfacedObject,
    IRepositorioEntradaAlbaranVenta)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarArticulos(
      const ATarifa: string;
      AFecha: TDateTime): IConsultaEntradaAlbaranVenta;
    function ConsultarSkus(
      const ACodigoArticulo: string): IConsultaEntradaAlbaranVenta;
    function LeerConfiguracionArticulo(
      const ACodigoArticulo: string): TConfiguracionArticuloAlbaranVenta;
  end;

constructor TConsultaEntradaAlbaranVentaUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaEntradaAlbaranVentaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaEntradaAlbaranVentaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioEntradaAlbaranVentaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioEntradaAlbaranVentaUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioEntradaAlbaranVentaUniDAC.ConsultarArticulos(
  const ATarifa: string;
  AFecha: TDateTime): IConsultaEntradaAlbaranVenta;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_ARTICULOS;
    Consulta.ParamByName('tarifa').AsString := ATarifa;
    Consulta.ParamByName('fecha').AsDateTime := AFecha;
    Consulta.Open;
    Result := TConsultaEntradaAlbaranVentaUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioEntradaAlbaranVentaUniDAC.ConsultarSkus(
  const ACodigoArticulo: string): IConsultaEntradaAlbaranVenta;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_SKUS;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.Open;
    Result := TConsultaEntradaAlbaranVentaUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioEntradaAlbaranVentaUniDAC.LeerConfiguracionArticulo(
  const ACodigoArticulo: string): TConfiguracionArticuloAlbaranVenta;
var
  Consulta: TUniQuery;
begin
  Result := Default(TConfiguracionArticuloAlbaranVenta);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_CONFIGURACION_ARTICULO;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      Result.EsTrazable :=
        Consulta.FieldByName('ESTRAZABLE_ART').AsString = 'S';
      Result.EsVariacion :=
        Consulta.FieldByName('ESVARIACION_ART').AsString = 'S';
      Result.NumeroSkus := Consulta.FieldByName('NUM_SKUS').AsInteger;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioEntradaAlbaranVentaUniDAC(
  AConexion: TUniConnection): IRepositorioEntradaAlbaranVenta;
begin
  Result := TRepositorioEntradaAlbaranVentaUniDAC.Create(AConexion);
end;

end.
