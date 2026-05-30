{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridArticulos                                            }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Controladora reutilizable de la operativa de entrada de articulos en un   }
{    grid (cxGridDBTableView + cds): columna de articulo (teclear/escanear +   }
{    buscar), columnas dinamicas de atributos (talla/color) como desplegables, }
{    resolucion via inLibArticulosValidador, valores via                       }
{    inLibArticulosAtributosLookup, generacion del SKU y consolidacion.        }
{                                                                              }
{    La misma logica que el grid de ventas de inMtoCajaOpe, pero desacoplada   }
{    por nombres de campo (TCamposGridArt) para que la usen varios grids       }
{    (caja, traspasos, ...). Cada pantalla anade sus columnas propias (precio  }
{    en venta, coste/stock en traspaso) sobre el mismo View.                   }
{                                                                              }
{    NOTA: el selector de atributo es un desplegable (combo) por simplicidad   }
{    y robustez; el popup de paleta con swatches de la caja se puede anadir    }
{    despues reusando inLibAtributosPaleta.                                    }
{******************************************************************************}
unit inLibGridArticulos;

interface

uses
  System.SysUtils, System.Classes, System.Variants, Data.DB, Uni,
  Vcl.Controls,
  cxEdit, cxTextEdit, cxButtonEdit, cxDropDownEdit,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibArticulosValidador, inLibArticulosAtributosLookup;

type
  // Nombres de los campos del cds que usa la controladora. Cada host los
  // rellena con los suyos (en traspaso: CODIGO_ART, CODIGO_UNIDAD, ...).
  TCamposGridArt = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    NumAtributos: string;
    AttrValor: array[1..5] of string;
    AttrNombre: array[1..5] of string;
  end;

  // Se dispara al resolver una entrada. ACompleto = el SKU esta cerrado
  // (articulo sin variacion, o con todos los atributos elegidos). El host
  // aprovecha para rellenar sus columnas (coste, stock, precio...).
  TArtResueltoEvent = procedure(const ACodArt, ASku, ADescripcion: string;
                                ACompleto: Boolean) of object;

  TGridArticulosLineas = class
  private
    FConn: TUniConnection;
    FView: TcxGridDBTableView;
    FCds: TDataSet;
    FCampos: TCamposGridArt;
    FColArticulo: TcxGridDBColumn;
    FColAtributo: array[1..5] of TcxGridDBColumn;
    FLookup: TArticulosAtributosLookup;
    FOnResuelto: TArtResueltoEvent;
    procedure CrearColumnaArticulo;
    procedure CrearColumnasAtributo;
    procedure ArticuloValidate(Sender: TObject; var DisplayValue: Variant;
                               var ErrorText: TCaption; var Error: Boolean);
    procedure AtributoChange(Sender: TObject);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    function ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
    function GenerarSku: string;
    procedure ActualizarColumnasAtributo(const ACodArt: string);
    function CdsEditando: Boolean;
  public
    constructor Create(AConn: TUniConnection; AView: TcxGridDBTableView;
                       ACds: TDataSet; const ACampos: TCamposGridArt);
    destructor Destroy; override;
    // Crea la columna de articulo + las 5 columnas de atributo y engancha el
    // OnInitEdit del View. El host anade sus columnas DESPUES sobre el View.
    procedure Construir;
    // Resuelve una entrada (codigo de articulo, SKU, codigo de barras o ref
    // de proveedor) y rellena la linea. Devuelve False si no se encontro.
    function ResolverEntrada(const AEntrada: string): Boolean;
    property OnResuelto: TArtResueltoEvent read FOnResuelto write FOnResuelto;
  end;

implementation

uses
  inLibGlobalVar;

constructor TGridArticulosLineas.Create(AConn: TUniConnection;
                                        AView: TcxGridDBTableView;
                                        ACds: TDataSet;
                                        const ACampos: TCamposGridArt);
begin
  inherited Create;
  FConn := AConn;
  FView := AView;
  FCds := ACds;
  FCampos := ACampos;
  FLookup := TArticulosAtributosLookup.Create(AConn);
end;

destructor TGridArticulosLineas.Destroy;
begin
  FreeAndNil(FLookup);
  inherited;
end;

function TGridArticulosLineas.CdsEditando: Boolean;
begin
  Result := FCds.Active and (FCds.State in [dsEdit, dsInsert]);
end;

procedure TGridArticulosLineas.Construir;
begin
  FView.BeginUpdate;
  try
    FView.ClearItems;
    CrearColumnaArticulo;
    CrearColumnasAtributo;
  finally
    FView.EndUpdate;
  end;
  FView.OnInitEdit := ViewInitEdit;
end;

procedure TGridArticulosLineas.CrearColumnaArticulo;
begin
  FColArticulo := FView.CreateColumn;
  FColArticulo.Caption := 'Artículo / SKU';
  FColArticulo.DataBinding.FieldName := FCampos.CodigoArt;
  FColArticulo.Width := 220;
  FColArticulo.PropertiesClass := TcxButtonEditProperties;
  with TcxButtonEditProperties(FColArticulo.Properties) do
  begin
    Buttons.Clear;
    with Buttons.Add do
      Kind := bkEllipsis;
    OnValidate := ArticuloValidate;
  end;
end;

procedure TGridArticulosLineas.CrearColumnasAtributo;
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  for i := 1 to 5 do
  begin
    Col := FView.CreateColumn;
    Col.Name := 'colAtributoDyn' + IntToStr(i);
    Col.Tag := i;
    Col.DataBinding.FieldName := FCampos.AttrValor[i];
    Col.Caption := '-';
    Col.Visible := False;
    Col.Width := 90;
    Col.PropertiesClass := TcxComboBoxProperties;
    with TcxComboBoxProperties(Col.Properties) do
    begin
      DropDownListStyle := lsFixedList;
      OnChange := AtributoChange;
    end;
    FColAtributo[i] := Col;
  end;
end;

function TGridArticulosLineas.ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
begin
  if (ATag >= 1) and (ATag <= 5) then
    Result := FColAtributo[ATag]
  else
    Result := nil;
end;

function TGridArticulosLineas.GenerarSku: string;
var
  i, n: Integer;
  sValor: string;
begin
  Result := FCds.FieldByName(FCampos.CodigoArt).AsString;
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  for i := 1 to n do
  begin
    sValor := FCds.FieldByName(FCampos.AttrValor[i]).AsString;
    if sValor <> '' then
      Result := Result + '/' + sValor;
  end;
end;

// Muestra/oculta las columnas de atributo segun la variacion del articulo y
// fija NUM_ATRIBUTOS + los nombres. Los valores del desplegable se cargan por
// fila en ViewInitEdit.
procedure TGridArticulosLineas.ActualizarColumnasAtributo(const ACodArt: string);
var
  Atribs: TArray<TArticuloAtributo>;
  i: Integer;
  Col: TcxGridDBColumn;
begin
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  if CdsEditando then
    FCds.FieldByName(FCampos.NumAtributos).AsInteger := Length(Atribs);
  FView.BeginUpdate;
  try
    for i := 1 to 5 do
    begin
      Col := ColumnaPorTag(i);
      if Col <> nil then
      begin
        if i <= Length(Atribs) then
        begin
          Col.Caption := Atribs[i - 1].NombreAtributo;
          Col.Visible := True;
          Col.Options.Editing := True;
          if CdsEditando then
            FCds.FieldByName(FCampos.AttrNombre[i]).AsString :=
              Atribs[i - 1].NombreAtributo;
        end
        else
        begin
          Col.Visible := False;
          if CdsEditando then
          begin
            FCds.FieldByName(FCampos.AttrNombre[i]).AsString := '';
            FCds.FieldByName(FCampos.AttrValor[i]).AsString := '';
          end;
        end;
      end;
    end;
  finally
    FView.EndUpdate;
  end;
end;

function TGridArticulosLineas.ResolverEntrada(const AEntrada: string): Boolean;
var
  Val: TArticulosValidador;
  R: TArtResolucionEntrada;
  sCodArt, sSku, sDesc: string;
  bCompleto: Boolean;
begin
  Result := False;
  if Trim(AEntrada) = '' then
    Exit;
  Val := TArticulosValidador.Create(FConn);
  try
    R := Val.Resolver(Trim(AEntrada));
  finally
    FreeAndNil(Val);
  end;
  if not R.Encontrado then
    Exit;
  sCodArt := R.CodigoArticulo;
  sSku := R.CodigoSku;
  sDesc := R.DescripcionArticulo;
  // Completo = la entrada ya trajo un SKU cerrado (no requiere elegir talla).
  bCompleto := (sSku <> '') and (not R.RequiereSku);
  if not CdsEditando then
    FCds.Edit;
  FCds.FieldByName(FCampos.CodigoArt).AsString := sCodArt;
  FCds.FieldByName(FCampos.Descripcion).AsString := sDesc;
  if bCompleto then
    FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku
  else
    FCds.FieldByName(FCampos.CodigoUnidad).AsString := sCodArt;
  // Columnas de talla/color segun el articulo
  ActualizarColumnasAtributo(sCodArt);
  if Assigned(FOnResuelto) then
    FOnResuelto(sCodArt, FCds.FieldByName(FCampos.CodigoUnidad).AsString,
                sDesc, bCompleto);
  Result := True;
end;

procedure TGridArticulosLineas.ArticuloValidate(Sender: TObject;
                                  var DisplayValue: Variant;
                                  var ErrorText: TCaption; var Error: Boolean);
begin
  // Al resolver, dejamos en la celda el codigo de articulo (padre) resuelto,
  // para que el editor no vuelva a volcar lo tecleado (p.ej. un codigo barras).
  if ResolverEntrada(VarToStr(DisplayValue)) then
    DisplayValue := FCds.FieldByName(FCampos.CodigoArt).AsString;
end;

procedure TGridArticulosLineas.AtributoChange(Sender: TObject);
var
  Edit: TcxCustomEdit;
  sSku, sCodArt, sDesc: string;
  n: Integer;
  bCompleto: Boolean;
begin
  Edit := Sender as TcxCustomEdit;
  if not CdsEditando then
    Exit;
  Edit.PostEditValue;
  sCodArt := FCds.FieldByName(FCampos.CodigoArt).AsString;
  sDesc := FCds.FieldByName(FCampos.Descripcion).AsString;
  sSku := GenerarSku;
  FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
  // Completo cuando el SKU lleva tantos '/' como atributos requeridos.
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  bCompleto := (n > 0) and
    (Length(sSku) - Length(StringReplace(sSku, '/', '', [rfReplaceAll])) >= n);
  if Assigned(FOnResuelto) then
    FOnResuelto(sCodArt, sSku, sDesc, bCompleto);
end;

// Carga, por fila, los valores del desplegable de cada columna de atributo
// con los AV validos del articulo de esa fila.
procedure TGridArticulosLineas.ViewInitEdit(Sender: TcxCustomGridTableView;
                                            AItem: TcxCustomGridTableItem;
                                            AEdit: TcxCustomEdit);
var
  iTag: Integer;
  sCodArt: string;
  Avs: TArray<TArticuloAtributoValor>;
  Combo: TcxComboBox;
  j: Integer;
begin
  iTag := AItem.Tag;
  if (iTag < 1) or (iTag > 5) then
    Exit;
  if not (AEdit is TcxComboBox) then
    Exit;
  Combo := TcxComboBox(AEdit);
  Combo.Properties.Items.Clear;
  sCodArt := FCds.FieldByName(FCampos.CodigoArt).AsString;
  if sCodArt = '' then
    Exit;
  // Solo los AV que el articulo tiene en sus SKUs (orden visual = iTag), para
  // que el desplegable no muestre colores/tallas de otros articulos y el SKU
  // generado cuadre contra uno real.
  Avs := FLookup.ObtenerAvsEnSkus(sCodArt, iTag);
  for j := 0 to High(Avs) do
    Combo.Properties.Items.Add(Avs[j].Valor);
end;

end.
