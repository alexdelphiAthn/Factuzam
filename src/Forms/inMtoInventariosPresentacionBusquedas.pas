{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosPresentacionBusquedas                         }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Dialogos de busqueda de articulo y SKU del mantenimiento de               }
{    inventarios. Recibe el puerto de datos ya abierto: no crea consultas,     }
{    no escribe SQL y no conserva el formulario.                               }
{******************************************************************************}
unit inMtoInventariosPresentacionBusquedas;

interface

uses
  Vcl.Forms,
  inLibGenBusq,
  inLibInventariosAplicacionIntf;

function BuscarArticuloInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  AFormularioPadre: TCustomForm): string;
function BuscarSkuInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoAlmacen: string;
  AFormularioPadre: TCustomForm): string;

implementation

uses
  Data.DB;

// Fija DisplayLabel y formato de un campo para que la grilla generica
// muestre cabeceras legibles sin layout guardado.
procedure ConfigurarCampoBusqueda(
  ACampo: TField; const AEtiqueta, AFormato: string);
begin
  if ACampo <> nil then
  begin
    ACampo.DisplayLabel := AEtiqueta;
    if AFormato <> '' then
    begin
      if ACampo is TFloatField then
        TFloatField(ACampo).DisplayFormat := AFormato
      else if ACampo is TBCDField then
        TBCDField(ACampo).DisplayFormat := AFormato
      else if ACampo is TSQLTimeStampField then
        TSQLTimeStampField(ACampo).DisplayFormat := AFormato;
    end;
  end;
end;

function BuscarArticuloInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  AFormularioPadre: TCustomForm): string;
var
  oResultado: IResultadoConsultaInventario;
  oDatos: TDataSet;
begin
  Result := '';
  oResultado := ABusquedas.ConsultarArticulos;
  oDatos := oResultado.DataSet;
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_ART_ART'),
    'Código', '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_ART'),
    'Descripción', '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_FAM'),
    'Familia', '');
  ConfigurarCampoBusqueda(oDatos.FindField('TEMPORADA'),
    'Temporada', '');
  ConfigurarCampoBusqueda(oDatos.FindField('RAZON_SOCIAL_PROVEEDOR'),
    'Proveedor', '');
  ConfigurarCampoBusqueda(oDatos.FindField('REF_PROVEEDOR'),
    'Ref. proveedor', '');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_ULT_COMPRA'),
    'P. compra', '#,##0.00 €');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_FINAL_ARTTAR'),
    'P. venta', '#,##0.00 €');
  ConfigurarCampoBusqueda(oDatos.FindField('TIPO_CANTIDAD_ART'),
    'Tipo cant.', '');
  if ABusquedaVisual.EjecutarBusquedaDataSet(
       'Búsqueda de Artículos', oDatos, 'frmMtoArtInvSearch',
       AFormularioPadre) then
    Result := oDatos.FieldByName('CODIGO_ART_ART').AsString;
end;

function BuscarSkuInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoAlmacen: string;
  AFormularioPadre: TCustomForm): string;
var
  oResultado: IResultadoConsultaInventario;
  oDatos: TDataSet;
begin
  Result := '';
  oResultado := ABusquedas.ConsultarSkus(ACodigoAlmacen);
  oDatos := oResultado.DataSet;
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_UNIDAD_SKU'),
    'SKU', '');
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_ART_SKU'),
    'Artículo', '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_ART'),
    'Descripción', '');
  ConfigurarCampoBusqueda(oDatos.FindField('ATRIBUTOS'),
    'Atributos', '');
  ConfigurarCampoBusqueda(oDatos.FindField('CANTIDAD_STK'),
    'Stock', '#,##0.00');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_MEDIO_STK'),
    'PMP', '#,##0.0000');
  if ABusquedaVisual.EjecutarBusquedaDataSet(
       'Búsqueda de SKUs', oDatos, 'frmMtoInvSkuSearch',
       AFormularioPadre) then
    Result := oDatos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
end;

end.
