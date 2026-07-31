{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBusquedasCompra                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas y ejecución común de las búsquedas de artículos de proveedor   }
{    y SKUs usadas por los documentos de compra.                              }
{******************************************************************************}
unit inLibBusquedasCompra;

interface

uses
  Data.DB, Uni, Vcl.Forms, inLibGenBusq;

function SqlBusquedaArticulosProveedorCompra: string;
function SqlBusquedaSkuCompra: string;
function ValorTextoDataSetCompra(ADataSet: TDataSet;
  const ACampo: string): string;
function BuscarArticuloProveedorCompra(
  AConexion: TUniConnection; const ABusquedaVisual: IBusquedaVisual;
  const ACodigoProveedor, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
function BuscarSkuArticuloCompra(
  AConexion: TUniConnection; const ABusquedaVisual: IBusquedaVisual;
  const ACodigoArticulo, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;

implementation

uses
  System.SysUtils;

function SqlBusquedaArticulosProveedorCompra: string;
begin
  Result :=
    'SELECT art.CODIGO_ART_ART, art.ESACTIVO_ART, art.ORDEN_ART, ' +
    '       art.DESCRIPCION_ART, art.CODIGO_FAM_ART, ' +
    '       fam.DESCRIPCION_FAM, art.TIPO_IVA_ART, ' +
    '       iva.NOMBRE_TIPO_IVA_IVATIP, art.TIPO_CANTIDAD_ART, ' +
    '       ap.CODIGO_PRV_AP, prv.RAZON_SOCIAL_PRV, ' +
    '       prv.NOMBRE_PRV, ' +
    '       ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
    '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP ' +
    '  FROM fza_articulos_proveedores ap ' +
    '  JOIN fza_articulos art ' +
    '    ON art.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
    '  LEFT JOIN fza_articulos_familias fam ' +
    '    ON fam.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_ivas_tipos iva ' +
    '    ON iva.CODIGO_ABREVIATURA_IVA_IVATIP = art.TIPO_IVA_ART ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    ' WHERE ap.CODIGO_PRV_AP = :prv ' +
    '   AND COALESCE(art.ESACTIVO_ART, ''S'') = ''S'' ' +
    ' ORDER BY art.ORDEN_ART, art.CODIGO_ART_ART';
end;

function SqlBusquedaSkuCompra: string;
begin
  Result :=
    'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
    '       GROUP_CONCAT(AV.AV ORDER BY ' +
    '       COALESCE(VA.ORDEN_VA, 999), ' +
    '       AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
    '  FROM fza_articulos_skus SK ' +
    '  LEFT JOIN fza_atributos_sku SA ' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '  LEFT JOIN fza_atributos_valores AV ' +
    '    ON AV.ID_AV = SA.ID_AV_SA ' +
    '  LEFT JOIN fza_variaciones_atributos VA ' +
    '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
    '   AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
    ' WHERE SK.CODIGO_ART_SKU = :art ' +
    '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
    ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
    ' ORDER BY SK.CODIGO_UNIDAD_SKU';
end;

function ValorTextoDataSetCompra(ADataSet: TDataSet;
  const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active and
     not ADataSet.IsEmpty then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) then
      Result := Trim(oCampo.AsString);
  end;
end;

function BuscarArticuloProveedorCompra(
  AConexion: TUniConnection; const ABusquedaVisual: IBusquedaVisual;
  const ACodigoProveedor, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
var
  oConsulta: TUniQuery;
  sProveedor: string;
begin
  Result := '';
  sProveedor := Trim(ACodigoProveedor);
  if Assigned(AConexion) and (sProveedor <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SqlBusquedaArticulosProveedorCompra;
      oConsulta.ParamByName('prv').AsString := sProveedor;
      if ABusquedaVisual.EjecutarBusqueda(
        AConexion, ACaption, oConsulta, ANombreFormulario,
        AFormularioPadre) and
         Assigned(oConsulta.FindField('CODIGO_ART_ART')) then
        Result :=
          oConsulta.FieldByName('CODIGO_ART_ART').AsString;
    finally
      oConsulta.Free;
    end;
  end;
end;

function BuscarSkuArticuloCompra(
  AConexion: TUniConnection; const ABusquedaVisual: IBusquedaVisual;
  const ACodigoArticulo, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
var
  oConsulta: TUniQuery;
  sArticulo: string;
begin
  Result := '';
  sArticulo := Trim(ACodigoArticulo);
  if Assigned(AConexion) and (sArticulo <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SqlBusquedaSkuCompra;
      oConsulta.ParamByName('art').AsString := sArticulo;
      if ABusquedaVisual.EjecutarBusqueda(
        AConexion, ACaption, oConsulta, ANombreFormulario,
        AFormularioPadre) and
         Assigned(oConsulta.FindField('CODIGO_UNIDAD_SKU')) then
        Result :=
          oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      oConsulta.Free;
    end;
  end;
end;

end.
