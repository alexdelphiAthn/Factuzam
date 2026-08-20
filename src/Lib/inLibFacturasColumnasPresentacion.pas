{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasColumnasPresentacion                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construcción de las columnas propias del detalle de una factura.          }
{******************************************************************************}
unit inLibFacturasColumnasPresentacion;

interface

uses
  Data.DB, cxGridDBTableView, inLibUnidadesMedida;

type
  TConfiguracionColumnasFactura = record
    Vista: TcxGridDBTableView;
    DataSourceIvas: TDataSource;
    Clasico: Boolean;
    Tallas: Boolean;
    Simplificada: Boolean;
    CrearArticulos: Boolean;
    DescripcionAmpliada: Boolean;
    MostrarFechaEntrega: Boolean;
    UnidadesMedida: TUnidadesMedida;
  end;

  TColumnasFactura = record
    Linea: TcxGridDBColumn;
    Articulo: TcxGridDBColumn;
    Sku: TcxGridDBColumn;
    DescripcionVariacion: TcxGridDBColumn;
    CodigoFamilia: TcxGridDBColumn;
    NombreFamilia: TcxGridDBColumn;
    EsProveedorPrincipal: TcxGridDBColumn;
    CodigoProveedor: TcxGridDBColumn;
    RazonSocialProveedor: TcxGridDBColumn;
    PrecioUltimaCompra: TcxGridDBColumn;
    DescripcionArticulo: TcxGridDBColumn;
    TipoCantidad: TcxGridDBColumn;
    Cantidad: TcxGridDBColumn;
    PrecioSalida: TcxGridDBColumn;
    PorcentajeDescuento: TcxGridDBColumn;
    PrecioDescuento: TcxGridDBColumn;
    PrecioVentaSinIva: TcxGridDBColumn;
    ImpuestosIncluidos: TcxGridDBColumn;
    TipoIva: TcxGridDBColumn;
    PorcentajeIva: TcxGridDBColumn;
    PrecioVentaConIva: TcxGridDBColumn;
    TotalConIva: TcxGridDBColumn;
    TotalSinIva: TcxGridDBColumn;
    FechaEntrega: TcxGridDBColumn;
  end;

function CrearColumnasFactura(
  const AConfiguracion: TConfiguracionColumnasFactura
): TColumnasFactura;

implementation

uses
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, cxButtons, cxButtonEdit,
  cxCalendar, cxCheckBox, cxCurrencyEdit, cxCustomData, cxData,
  cxDataStorage, cxDropDownEdit, cxEdit,
  cxGridCustomTableView, cxGridTableView, cxGridDBDataDefinitions,
  cxLookupEdit, cxDBLookupComboBox, cxLookupDBGrid, cxMemo, cxSpinEdit,
  inLibGridCantidad, inLibFormatoMonetario;

function NuevaColumna(
  AVista: TcxGridDBTableView;
  const ATitulo, ACampo: string;
  AAncho: Integer;
  AEditable: Boolean): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn as TcxGridDBColumn;
  Result.Caption := ATitulo;
  Result.DataBinding.FieldName := ACampo;
  Result.Width := AAncho;
  Result.Options.Editing := AEditable;
end;

procedure ConfigurarVisibilidadCreacion(
  var AColumnas: TColumnasFactura;
  AVisible: Boolean);
begin
  AColumnas.CodigoFamilia.Visible := AVisible;
  AColumnas.NombreFamilia.Visible := AVisible;
  AColumnas.EsProveedorPrincipal.Visible := AVisible;
  AColumnas.CodigoProveedor.Visible := AVisible;
  AColumnas.RazonSocialProveedor.Visible := AVisible;
  AColumnas.PrecioUltimaCompra.Visible := AVisible;
end;

procedure CrearColumnasIdentidad(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura;
  out AVendedor: TcxGridDBColumn);
var
  PropiedadesArticulo: TcxButtonEditProperties;
  BotonArticulo: TcxEditButton;
  PropiedadesSku: TcxComboBoxProperties;
begin
  AColumnas.Linea := NuevaColumna(
    AConfiguracion.Vista,
    'Nro Linea',
    'LINEA_FACLIN',
    60,
    False);
  AVendedor := nil;
  if AConfiguracion.Simplificada then
    AVendedor := NuevaColumna(
      AConfiguracion.Vista,
      'Vendedor',
      'CODIGO_VENDEDOR_FACLIN',
      90,
      False);
  if AConfiguracion.Clasico then
  begin
    AColumnas.Articulo := NuevaColumna(
      AConfiguracion.Vista,
      'Código Artículo',
      'CODIGO_ART_FACLIN',
      152,
      True);
    AColumnas.Articulo.PropertiesClass := TcxButtonEditProperties;
    PropiedadesArticulo :=
      TcxButtonEditProperties(AColumnas.Articulo.Properties);
    PropiedadesArticulo.Buttons.Clear;
    BotonArticulo := PropiedadesArticulo.Buttons.Add;
    BotonArticulo.Default := True;
    BotonArticulo.Kind := bkEllipsis;
    AColumnas.Sku := NuevaColumna(
      AConfiguracion.Vista,
      'SKU',
      'CODIGO_UNIDAD_FACLIN',
      180,
      True);
    AColumnas.Sku.Visible := False;
    AColumnas.Sku.PropertiesClass := TcxComboBoxProperties;
    PropiedadesSku := TcxComboBoxProperties(AColumnas.Sku.Properties);
    PropiedadesSku.ImmediatePost := True;
    PropiedadesSku.PostPopupValueOnTab := True;
  end;
  AColumnas.DescripcionVariacion := NuevaColumna(
    AConfiguracion.Vista,
    'Variación',
    'DESCRIPCION_VARIACION_FACLIN',
    140,
    False);
  AColumnas.DescripcionVariacion.Visible := False;
end;

procedure CrearColumnasCatalogo(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
begin
  AColumnas.CodigoFamilia := NuevaColumna(
    AConfiguracion.Vista,
    'Código Familia',
    'CODIGO_FAM_FACLIN',
    153,
    True);
  AColumnas.NombreFamilia := NuevaColumna(
    AConfiguracion.Vista,
    'Nombre Familia',
    'NOMBRE_FAM_FACLIN',
    245,
    True);
  AColumnas.EsProveedorPrincipal := NuevaColumna(
    AConfiguracion.Vista,
    'Proveedor Principal',
    'ESPROVEEDORPRINCIPAL_FACLIN',
    172,
    True);
  AColumnas.EsProveedorPrincipal.PropertiesClass :=
    TcxCheckBoxProperties;
  AColumnas.CodigoProveedor := NuevaColumna(
    AConfiguracion.Vista,
    'Código Proveedor',
    'CODIGO_PRV_FACLIN',
    163,
    True);
  AColumnas.RazonSocialProveedor := NuevaColumna(
    AConfiguracion.Vista,
    'Razón Social Proveedor',
    'RAZON_SOCIAL_PROVEEDOR_FACLIN',
    200,
    True);
  AColumnas.PrecioUltimaCompra := NuevaColumna(
    AConfiguracion.Vista,
    'Precio Coste',
    'PRECIO_ULT_COMPRA_FACLIN',
    100,
    True);
  AColumnas.PrecioUltimaCompra.PropertiesClass :=
    TcxCurrencyEditProperties;
  ConfigurarVisibilidadCreacion(
    AColumnas,
    AConfiguracion.Clasico and AConfiguracion.CrearArticulos);
end;

procedure CrearColumnasDescripcionCantidad(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesDescripcion: TcxMemoProperties;
begin
  AColumnas.DescripcionArticulo := NuevaColumna(
    AConfiguracion.Vista,
    'Descripción',
    'DESCRIPCION_ARTICULO_FACLIN',
    300,
    True);
  if AConfiguracion.DescripcionAmpliada then
  begin
    AColumnas.DescripcionArticulo.PropertiesClass := TcxMemoProperties;
    PropiedadesDescripcion := TcxMemoProperties(
      AColumnas.DescripcionArticulo.Properties);
    PropiedadesDescripcion.VisibleLineCount := 3;
    PropiedadesDescripcion.MaxLength := 1000;
    PropiedadesDescripcion.ScrollBars := ssBoth;
  end;
  if not AConfiguracion.Tallas then
  begin
    AColumnas.TipoCantidad := NuevaColumna(
      AConfiguracion.Vista,
      '',
      'TIPO_CANTIDAD_ARTICULO_FACLIN',
      20,
      False);
    AColumnas.TipoCantidad.Visible := False;
    AColumnas.TipoCantidad.VisibleForCustomization := False;
    AColumnas.Cantidad := NuevaColumna(
      AConfiguracion.Vista,
      'Cantidad',
      'CANTIDAD_FACLIN',
      90,
      True);
    AColumnas.Cantidad.PropertiesClass := TcxSpinEditProperties;
    VincularCantidadGrid(
      AColumnas.Cantidad,
      AColumnas.TipoCantidad,
      AConfiguracion.UnidadesMedida);
  end;
end;

procedure CrearColumnasPrecios(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesDescuento: TcxSpinEditProperties;
  PropiedadesImpuestos: TcxCheckBoxProperties;
begin
  AColumnas.PrecioSalida := NuevaColumna(
    AConfiguracion.Vista,
    'Precio Salida',
    'PRECIO_SALIDA_FACLIN',
    100,
    True);
  AColumnas.PrecioSalida.PropertiesClass := TcxCurrencyEditProperties;
  AColumnas.PorcentajeDescuento := NuevaColumna(
    AConfiguracion.Vista,
    '% Dto',
    'PORCENTAJE_DTO_FACLIN',
    80,
    True);
  AColumnas.PorcentajeDescuento.PropertiesClass :=
    TcxSpinEditProperties;
  PropiedadesDescuento := TcxSpinEditProperties(
    AColumnas.PorcentajeDescuento.Properties);
  PropiedadesDescuento.DisplayFormat := '0.00 %';
  PropiedadesDescuento.EditFormat := '0.00 %';
  PropiedadesDescuento.MaxValue := 100;
  AColumnas.PrecioDescuento := NuevaColumna(
    AConfiguracion.Vista,
    'Menos Dto',
    'PRECIO_DTO_FACLIN',
    90,
    True);
  AColumnas.PrecioDescuento.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.PrecioVentaSinIva := NuevaColumna(
    AConfiguracion.Vista,
    'Precio Ud. sin IVA',
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN',
    120,
    True);
  AColumnas.PrecioVentaSinIva.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.ImpuestosIncluidos := NuevaColumna(
    AConfiguracion.Vista,
    'ImpIncl',
    'ESIMP_INCL_TARIFA_FACLIN',
    79,
    True);
  AColumnas.ImpuestosIncluidos.Visible := False;
  AColumnas.ImpuestosIncluidos.PropertiesClass :=
    TcxCheckBoxProperties;
  PropiedadesImpuestos := TcxCheckBoxProperties(
    AColumnas.ImpuestosIncluidos.Properties);
  PropiedadesImpuestos.ReadOnly := True;
  PropiedadesImpuestos.ValueChecked := 'S';
  PropiedadesImpuestos.ValueUnchecked := 'N';
end;

procedure CrearColumnasImpuestos(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesTipoIva: TcxLookupComboBoxProperties;
  ColumnaTipoIva: TcxLookupDBGridColumn;
  PropiedadesPorcentaje: TcxSpinEditProperties;
begin
  AColumnas.TipoIva := NuevaColumna(
    AConfiguracion.Vista,
    'Tipo de IVA',
    'TIPO_IVA_ARTICULO_FACLIN',
    109,
    True);
  AColumnas.TipoIva.PropertiesClass := TcxLookupComboBoxProperties;
  PropiedadesTipoIva :=
    TcxLookupComboBoxProperties(AColumnas.TipoIva.Properties);
  PropiedadesTipoIva.DropDownListStyle := lsFixedList;
  PropiedadesTipoIva.KeyFieldNames := 'CODIGO_ABREVIATURA_IVA_IVATIP';
  ColumnaTipoIva := PropiedadesTipoIva.ListColumns.Add;
  ColumnaTipoIva.Caption := 'Tipo de IVA';
  ColumnaTipoIva.FieldName := 'NOMBRE_TIPO_IVA_IVATIP';
  PropiedadesTipoIva.ListOptions.ShowHeader := False;
  PropiedadesTipoIva.ListSource := AConfiguracion.DataSourceIvas;
  AColumnas.PorcentajeIva := NuevaColumna(
    AConfiguracion.Vista,
    '% IVA',
    'PORCENTAJE_IVA_FACLIN',
    79,
    True);
  AColumnas.PorcentajeIva.PropertiesClass := TcxSpinEditProperties;
  PropiedadesPorcentaje :=
    TcxSpinEditProperties(AColumnas.PorcentajeIva.Properties);
  PropiedadesPorcentaje.DisplayFormat := '0.00 %';
  PropiedadesPorcentaje.EditFormat := '0.00 %';
  AColumnas.PrecioVentaConIva := NuevaColumna(
    AConfiguracion.Vista,
    'Precio Ud. con IVA',
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN',
    120,
    True);
  AColumnas.PrecioVentaConIva.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.TotalConIva := NuevaColumna(
    AConfiguracion.Vista,
    'Total con IVA',
    'TOTAL_FACLIN',
    120,
    False);
  AColumnas.TotalConIva.PropertiesClass := TcxCurrencyEditProperties;
  AColumnas.TotalSinIva := NuevaColumna(
    AConfiguracion.Vista,
    'Total Sin IVA',
    'TOTAL_FAC_SIVA_FACLIN',
    125,
    True);
  AColumnas.TotalSinIva.PropertiesClass := TcxCurrencyEditProperties;
end;

procedure CrearColumnaFecha(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesFecha: TcxDateEditProperties;
begin
  AColumnas.FechaEntrega := NuevaColumna(
    AConfiguracion.Vista,
    'Fecha Entrega',
    'FECHA_ENTREGA_FACLIN',
    100,
    True);
  AColumnas.FechaEntrega.PropertiesClass := TcxDateEditProperties;
  PropiedadesFecha :=
    TcxDateEditProperties(AColumnas.FechaEntrega.Properties);
  PropiedadesFecha.DateButtons := [btnClear, btnToday];
  PropiedadesFecha.DisplayFormat := 'dd/mm/yyyy';
  PropiedadesFecha.EditFormat := 'dd/mm/yyyy';
  AColumnas.FechaEntrega.Visible :=
    AConfiguracion.MostrarFechaEntrega;
end;

procedure CrearSumarios(
  const AConfiguracion: TConfiguracionColumnasFactura;
  const AColumnas: TColumnasFactura);
var
  Resumen: TcxDataSummary;
  Sumario: TcxGridDBTableSummaryItem;
begin
  Resumen := AConfiguracion.Vista.DataController.Summary;
  Resumen.BeginUpdate;
  try
    Resumen.FooterSummaryItems.Clear;
    Sumario := TcxGridDBTableSummaryItem(
      Resumen.FooterSummaryItems.Add);
    Sumario.Kind := skSum;
    Sumario.Format := '##,##.00 ' + #8364;
    Sumario.Column := AColumnas.TotalConIva;
    if AColumnas.Cantidad <> nil then
    begin
      Sumario := TcxGridDBTableSummaryItem(
        Resumen.FooterSummaryItems.Add);
      Sumario.Kind := skSum;
      Sumario.Format := '#,##.00';
      Sumario.Column := AColumnas.Cantidad;
    end;
    Sumario := TcxGridDBTableSummaryItem(
      Resumen.FooterSummaryItems.Add);
    Sumario.Kind := skSum;
    Sumario.Format := '##,##.00 ' + #8364;
    Sumario.Column := AColumnas.TotalSinIva;
  finally
    Resumen.EndUpdate;
  end;
end;

function CrearColumnasFactura(
  const AConfiguracion: TConfiguracionColumnasFactura
): TColumnasFactura;
var
  Vendedor: TcxGridDBColumn;
begin
  Result := Default(TColumnasFactura);
  CrearColumnasIdentidad(AConfiguracion, Result, Vendedor);
  CrearColumnasCatalogo(AConfiguracion, Result);
  CrearColumnasDescripcionCantidad(AConfiguracion, Result);
  CrearColumnasPrecios(AConfiguracion, Result);
  CrearColumnasImpuestos(AConfiguracion, Result);
  CrearColumnaFecha(AConfiguracion, Result);
  CrearSumarios(AConfiguracion, Result);
  Result.Linea.Index := 0;
  if Assigned(Vendedor) then
    Vendedor.Index := 1;
  FormatearColumnaMonetaria(Result.PrecioUltimaCompra);
  FormatearColumnaMonetaria(Result.PrecioSalida);
  FormatearColumnaMonetaria(Result.PrecioDescuento);
  FormatearColumnaMonetaria(Result.PrecioVentaSinIva);
  FormatearColumnaMonetaria(Result.PrecioVentaConIva);
  FormatearColumnaMonetaria(Result.TotalConIva);
  FormatearColumnaMonetaria(Result.TotalSinIva);
end;

end.
