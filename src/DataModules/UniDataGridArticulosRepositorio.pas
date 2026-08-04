{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGridArticulosRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de artículos del buscador completo del grid reutilizable.        }
{******************************************************************************}
unit UniDataGridArticulosRepositorio;

interface

uses
  Uni,
  inLibGridArticulosPersistenciaIntf;

function CrearConsultaArticulosGridUniDAC(
  AConexion: TUniConnection): IConsultaArticulosGrid;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_ARTICULOS_GRID =
    'SELECT a.CODIGO_ART_ART AS ARTICULO,' +
    '       a.DESCRIPCION_ART AS DESCRIPCION,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '         AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                   JOIN fza_articulos_skus sk' +
    '                     ON sk.CODIGO_UNIDAD_SKU = st.CODIGO_UNIDAD_STK' +
    '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM fza_articulos a' +
    ' WHERE a.ESACTIVO_ART = ''S'' AND a.TIPO_ART = ''ESTANDAR''' +
    ' ORDER BY STOCK DESC, a.CODIGO_ART_ART';

type
  TConsultaArticulosGridUniDAC = class(
    TInterfacedObject,
    IConsultaArticulosGrid)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function DataSet: TDataSet;
    procedure Aplicar(const AAlmacenStock: string);
  end;

constructor TConsultaArticulosGridUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
  FConsulta.SQL.Text := SQL_ARTICULOS_GRID;
end;

destructor TConsultaArticulosGridUniDAC.Destroy;
begin
  FConsulta.Free;
  inherited;
end;

function TConsultaArticulosGridUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

procedure TConsultaArticulosGridUniDAC.Aplicar(
  const AAlmacenStock: string);
begin
  FConsulta.Close;
  FConsulta.ParamByName('ALM').AsString := Trim(AAlmacenStock);
  FConsulta.Open;
end;

function CrearConsultaArticulosGridUniDAC(
  AConexion: TUniConnection): IConsultaArticulosGrid;
begin
  Result := TConsultaArticulosGridUniDAC.Create(AConexion);
end;

end.
