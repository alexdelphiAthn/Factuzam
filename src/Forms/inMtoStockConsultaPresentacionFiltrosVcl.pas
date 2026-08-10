{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionFiltrosVcl                      }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Carga y lee los filtros de almacenes y colores de la consulta de stock.   }
{    Recibe los controles y el catalogo; nunca el formulario.                  }
{******************************************************************************}
unit inMtoStockConsultaPresentacionFiltrosVcl;

interface

uses
  inLibStockConsultaPersistenciaIntf,
  cxListBox;

type
  TPresentadorFiltrosListaStock = class
  private
    FListaAlmacenes: TcxListBox;
    FListaColores: TcxListBox;
    FCatalogos: ILectorCatalogosStockConsulta;
  public
    constructor Create(
      AListaAlmacenes: TcxListBox;
      AListaColores: TcxListBox;
      const ACatalogos: ILectorCatalogosStockConsulta);
    procedure CargarAlmacenes;
    procedure CargarColores(
      const ACodigoArticulo, ACodigoSku: string);
    function AlmacenesSeleccionados: TArray<string>;
    function ColoresSeleccionados: TArray<string>;
  end;

function EsTipoAlmacenSeleccionadoPorDefecto(
  const ATipoUso: string): Boolean;
function ExtraerCodigoAlmacenFiltro(
  const ATexto: string): string;
function DebeSeleccionarColorFiltro(
  AFiltrarPorSku, AEsColorSku: Boolean): Boolean;

implementation

uses
  System.SysUtils,
  Data.DB;

const
  CAMPO_ALMACEN_CODIGO = 'CODIGO_ALM_ALM';
  CAMPO_ALMACEN_NOMBRE = 'NOMBRE_ALM_ALM';
  CAMPO_ALMACEN_TIPO_USO = 'TIPO_USO_ALM';
  CAMPO_COLOR_AV = 'AV';
  CAMPO_ES_COLOR_SKU = 'ES_COLOR_SKU';
  SEPARADOR_ALMACEN = ' - ';

resourcestring
  SErrorListaAlmacenesStockNoDisponible =
    'No se proporciono la lista de almacenes de la consulta de stock.';
  SErrorListaColoresStockNoDisponible =
    'No se proporciono la lista de colores de la consulta de stock.';
  SErrorCatalogoFiltrosStockNoDisponible =
    'No se proporciono el catalogo de filtros de la consulta de stock.';

function EsTipoAlmacenSeleccionadoPorDefecto(
  const ATipoUso: string): Boolean;
begin
  Result := (ATipoUso = 'ESTANDAR') or
    (ATipoUso = 'ESTANDARD');
end;

function ExtraerCodigoAlmacenFiltro(
  const ATexto: string): string;
var
  PosicionSeparador: Integer;
begin
  PosicionSeparador := Pos(SEPARADOR_ALMACEN, ATexto);
  if PosicionSeparador > 0 then
    Result := Copy(ATexto, 1, PosicionSeparador - 1)
  else
    Result := ATexto;
end;

function DebeSeleccionarColorFiltro(
  AFiltrarPorSku, AEsColorSku: Boolean): Boolean;
begin
  Result := (not AFiltrarPorSku) or AEsColorSku;
end;

constructor TPresentadorFiltrosListaStock.Create(
  AListaAlmacenes: TcxListBox;
  AListaColores: TcxListBox;
  const ACatalogos: ILectorCatalogosStockConsulta);
begin
  inherited Create;
  if AListaAlmacenes = nil then
    raise EArgumentNilException.Create(
      SErrorListaAlmacenesStockNoDisponible);
  if AListaColores = nil then
    raise EArgumentNilException.Create(
      SErrorListaColoresStockNoDisponible);
  if not Assigned(ACatalogos) then
    raise EArgumentNilException.Create(
      SErrorCatalogoFiltrosStockNoDisponible);
  FListaAlmacenes := AListaAlmacenes;
  FListaColores := AListaColores;
  FCatalogos := ACatalogos;
end;

procedure TPresentadorFiltrosListaStock.CargarAlmacenes;
var
  Item: Integer;
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  FListaAlmacenes.Items.Clear;
  Resultado := FCatalogos.ConsultarAlmacenes;
  Datos := Resultado.DataSet;
  try
    while not Datos.Eof do
    begin
      Item := FListaAlmacenes.Items.Add(
        Datos.FieldByName(CAMPO_ALMACEN_CODIGO).AsString +
        SEPARADOR_ALMACEN +
        Datos.FieldByName(CAMPO_ALMACEN_NOMBRE).AsString);
      FListaAlmacenes.Selected[Item] :=
        EsTipoAlmacenSeleccionadoPorDefecto(
          Datos.FieldByName(CAMPO_ALMACEN_TIPO_USO).AsString);
      Datos.Next;
    end;
  finally
    Resultado := nil;
  end;
end;

procedure TPresentadorFiltrosListaStock.CargarColores(
  const ACodigoArticulo, ACodigoSku: string);
var
  Indice: Integer;
  Item: Integer;
  FiltrarPorSku: Boolean;
  EsColorSku: Boolean;
  ColorSkuEncontrado: Boolean;
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  FListaColores.Items.Clear;
  if Trim(ACodigoArticulo) <> '' then
  begin
    FiltrarPorSku := Trim(ACodigoSku) <> '';
    ColorSkuEncontrado := False;
    Resultado := FCatalogos.ConsultarColores(
      ACodigoArticulo,
      ACodigoSku);
    Datos := Resultado.DataSet;
    try
      while not Datos.Eof do
      begin
        Item := FListaColores.Items.Add(
          Datos.FieldByName(CAMPO_COLOR_AV).AsString);
        EsColorSku := FiltrarPorSku and
          (Datos.FieldByName(CAMPO_ES_COLOR_SKU).AsInteger = 1);
        FListaColores.Selected[Item] :=
          DebeSeleccionarColorFiltro(FiltrarPorSku, EsColorSku);
        if EsColorSku then
          ColorSkuEncontrado := True;
        Datos.Next;
      end;
      if FiltrarPorSku and (not ColorSkuEncontrado) then
      begin
        for Indice := 0 to FListaColores.Items.Count - 1 do
          FListaColores.Selected[Indice] := True;
      end;
    finally
      Resultado := nil;
    end;
  end;
end;

function TPresentadorFiltrosListaStock.AlmacenesSeleccionados:
  TArray<string>;
var
  Indice: Integer;
begin
  SetLength(Result, 0);
  for Indice := 0 to FListaAlmacenes.Items.Count - 1 do
  begin
    if FListaAlmacenes.Selected[Indice] then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := ExtraerCodigoAlmacenFiltro(
        FListaAlmacenes.Items[Indice]);
    end;
  end;
end;

function TPresentadorFiltrosListaStock.ColoresSeleccionados:
  TArray<string>;
var
  Indice: Integer;
begin
  SetLength(Result, 0);
  for Indice := 0 to FListaColores.Items.Count - 1 do
  begin
    if FListaColores.Selected[Indice] then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FListaColores.Items[Indice];
    end;
  end;
end;

end.
