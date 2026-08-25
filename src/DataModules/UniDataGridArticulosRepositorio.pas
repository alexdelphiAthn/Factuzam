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
    '       COALESCE(NULLIF(f.DESCRIPCION_FAM, ''''),' +
    '                NULLIF(f.NOMBRE_FAM_FAM, ''''),' +
    '                a.CODIGO_FAM_ART, '''') AS FAMILIA,' +
    '       COALESCE(pv.PV, artprop.VALOR_LIBRE_ARTPROP, '''')' +
    '         AS TEMPORADA,' +
    '       COALESCE((SELECT COALESCE(' +
    '                            NULLIF(p.RAZON_SOCIAL_PRV, ''''),' +
    '                            NULLIF(p.NOMBRE_PRV, ''''),' +
    '                            ap_prv.CODIGO_PRV_AP)' +
    '                   FROM fza_articulos_proveedores ap_prv' +
    '                   LEFT JOIN fza_proveedores p' +
    '                     ON p.CODIGO_PRV_PRV = ap_prv.CODIGO_PRV_AP' +
    '                  WHERE ap_prv.CODIGO_ART_AP = a.CODIGO_ART_ART' +
    '                    AND ap_prv.ESPROVEEDORPRINCIPAL_AP = ''S''' +
    '                  ORDER BY ap_prv.CODIGO_PRV_AP' +
    '                  LIMIT 1), '''') AS PROVEEDOR,' +
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
    '  LEFT JOIN fza_articulos_familias f' +
    '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART' +
    '  LEFT JOIN fza_articulos_propiedades artprop' +
    '    ON artprop.CODIGO_ART_ART = a.CODIGO_ART_ART' +
    '   AND artprop.CODIGO_PROP_ARTPROP = ''TEMPORADA''' +
    '   AND artprop.CODIGO_UNIDAD_ARTPROP = ''''' +
    '  LEFT JOIN fza_propiedades_valores pv' +
    '    ON pv.ID_PV_ARTPROP = artprop.ID_PV_ARTPROP' +
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
  procedure EtiquetarCampo(
    const ANombreCampo, AEtiqueta: string);
  var
    Campo: TField;
  begin
    Campo := FConsulta.FindField(ANombreCampo);
    if Campo <> nil then
      Campo.DisplayLabel := AEtiqueta;
  end;
begin
  FConsulta.Close;
  FConsulta.ParamByName('ALM').AsString := Trim(AAlmacenStock);
  FConsulta.Open;
  EtiquetarCampo('ARTICULO', 'Código');
  EtiquetarCampo('DESCRIPCION', 'Descripción');
  EtiquetarCampo('FAMILIA', 'Familia');
  EtiquetarCampo('TEMPORADA', 'Temporada');
  EtiquetarCampo('PROVEEDOR', 'Proveedor');
  EtiquetarCampo('REFPRV', 'Ref. proveedor');
  EtiquetarCampo('STOCK', 'Stock');
end;

function CrearConsultaArticulosGridUniDAC(
  AConexion: TUniConnection): IConsultaArticulosGrid;
begin
  Result := TConsultaArticulosGridUniDAC.Create(AConexion);
end;

end.
