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
  System.SysUtils, System.Classes, System.Variants, System.Types,
  System.StrUtils, System.Generics.Collections, Data.DB, Uni, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, cxGraphics,
  cxEdit, cxTextEdit, cxButtonEdit, cxDropDownEdit,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibArticulosValidador, inLibArticulosAtributosLookup, inLibAtributosPaleta;

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
    // Timer single-shot para abrir la paleta al entrar en una celda de
    // atributo vacia (listbox incrustado, como la caja). Diferimos la
    // apertura fuera del OnEnter: el editor in-place del cxGrid aun no ha
    // terminado de parentar y ClientToScreen lanzaria EInvalidOperation.
    FTimerPopup: TTimer;
    FOrdenPopupPend: Integer;
    // Almacen cuyo stock se muestra en el buscador de SKU (lo fija el host;
    // en traspaso, el almacen origen). Vacio = no muestra stock.
    FAlmacenStock: string;
    procedure CrearColumnaArticulo;
    procedure CrearColumnasAtributo;
    procedure ArticuloValidate(Sender: TObject; var DisplayValue: Variant;
                               var ErrorText: TCaption; var Error: Boolean);
    procedure ArticuloButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
                           ACanvas: TcxCanvas;
                           AViewInfo: TcxGridTableDataCellViewInfo;
                           var ADone: Boolean);
    procedure AtributoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure AtributoEnter(Sender: TObject);
    procedure TimerPopupTimer(Sender: TObject);
    procedure AbrirPaletaOrden(AOrden: Integer);
    procedure AplicarSkuYAvisar;
    function ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
    function GenerarSku: string;
    procedure ActualizarColumnasAtributo(const ACodArt: string);
    procedure AutoCompletarAtributosUnicos(const ACodArt: string);
    procedure RellenarAtributosDesdeSku(const ACodArt, ASku: string);
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
    // Almacen para la columna de stock del buscador de SKU (origen).
    property AlmacenStock: string read FAlmacenStock write FAlmacenStock;
  end;

implementation

uses
  inLibGlobalVar, inLibGenBusq;

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
  FOrdenPopupPend := 0;
  FTimerPopup := TTimer.Create(nil);
  FTimerPopup.Enabled := False;
  FTimerPopup.Interval := 1;
  FTimerPopup.OnTimer := TimerPopupTimer;
end;

destructor TGridArticulosLineas.Destroy;
begin
  FreeAndNil(FTimerPopup);
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
  // Al entrar en una celda de atributo vacia, abre la paleta (listbox de
  // swatches) automaticamente, como la caja. Se engancha en OnInitEdit.
  FView.OnInitEdit := ViewInitEdit;
  // Flujo tipo Excel: Enter pasa a la siguiente celda y al llegar al final
  // de la fila salta a la siguiente; fila nueva siempre visible arriba para
  // poder anyadir tecleando sin botones.
  FView.OptionsBehavior.GoToNextCellOnEnter := True;
  FView.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  FView.NewItemRow.Visible := True;
  FView.NewItemRow.InfoText := 'Teclea aquí un artículo / SKU…';
end;

// Cuando el cxGrid crea el editor in-place de una celda: si es una columna de
// atributo (Tag 1..5) y la celda esta vacia, ponemos OnEnter para abrir la
// paleta sola (el "listbox incrustado"). Si ya tiene valor, no molestamos.
procedure TGridArticulosLineas.ViewInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE: TcxButtonEdit;
begin
  if (AItem = nil) or (AItem.Tag < 1) or (AItem.Tag > 5) then
    Exit;
  if not (AEdit is TcxButtonEdit) then
    Exit;
  BE := TcxButtonEdit(AEdit);
  BE.Tag := AItem.Tag;
  if (not FCds.Active) or FCds.IsEmpty then
    BE.OnEnter := nil
  else if Trim(FCds.FieldByName(FCampos.AttrValor[AItem.Tag]).AsString) = ''
  then
    BE.OnEnter := AtributoEnter
  else
    BE.OnEnter := nil;
end;

// OnEnter single-shot de una celda de atributo vacia: difiere la apertura de
// la paleta (timer 1ms) para que el editor in-place termine de parentar.
procedure TGridArticulosLineas.AtributoEnter(Sender: TObject);
begin
  if not (Sender is TcxButtonEdit) then
    Exit;
  TcxButtonEdit(Sender).OnEnter := nil;
  FOrdenPopupPend := TcxButtonEdit(Sender).Tag;
  FTimerPopup.Enabled := False;
  FTimerPopup.Enabled := True;
end;

procedure TGridArticulosLineas.TimerPopupTimer(Sender: TObject);
var
  iOrden: Integer;
begin
  FTimerPopup.Enabled := False;
  iOrden := FOrdenPopupPend;
  FOrdenPopupPend := 0;
  if (iOrden >= 1) and (iOrden <= 5) then
    AbrirPaletaOrden(iOrden);
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
    // El boton (ellipsis) abre el buscador de SKU.
    OnButtonClick := ArticuloButtonClick;
  end;
end;

// Click en el boton de la columna de articulo: abre el buscador generico
// (TfrmMtoSearch) con la lista de SKU (codigo, descripcion y stock en el
// almacen origen). Al elegir uno, se resuelve la linea como si se hubiera
// tecleado/escaneado ese SKU.
procedure TGridArticulosLineas.ArticuloButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
var
  Q: TUniQuery;
  sSku: string;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := FConn;
    // SKU activos de articulos de stock; stock = suma de lotes en el almacen
    // origen (0 si no hay o no se fijo almacen).
    Q.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU AS SKU,' +
      '       s.CODIGO_ART_SKU AS ARTICULO,' +
      '       a.DESCRIPCION_ART AS DESCRIPCION,' +
      '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
      '                   FROM fza_articulos_stockactual st' +
      '                  WHERE st.CODIGO_UNIDAD_STK = s.CODIGO_UNIDAD_SKU' +
      '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
      '  FROM fza_articulos_skus s' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
      ' WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
      '   AND a.TIPO_ART = ''ESTANDAR''' +
      ' ORDER BY s.CODIGO_ART_SKU, s.CODIGO_UNIDAD_SKU';
    Q.ParamByName('ALM').AsString := FAlmacenStock;
    Q.Open;
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de SKU', Q,
                                       'frmMtoSkuTraspasoSearch') then
    begin
      sSku := Q.FieldByName('SKU').AsString;
      if ResolverEntrada(sSku) then
        // Refresca la celda desde el cds (descarta el texto del editor).
        if FView.Controller.EditingController.IsEditing then
          try
            FView.Controller.EditingController.HideEdit(False);
          except
            on E: EInvalidOperation do
              ;
          end;
    end;
  finally
    FreeAndNil(Q);
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
    // Boton en la celda que abre la paleta (listbox con swatches), como la
    // caja. No usamos combo: el editor combo in-place del cxGrid se desparenta
    // y lanza EInvalidOperation.
    Col.PropertiesClass := TcxButtonEditProperties;
    with TcxButtonEditProperties(Col.Properties) do
    begin
      ReadOnly := True;
      Buttons.Clear;
      with Buttons.Add do
      begin
        Default := True;
        Kind := bkEllipsis;
      end;
      OnButtonClick := AtributoButtonClick;
    end;
    // Pinta el cuadradito de color en la celda (como caja/inventario).
    Col.OnCustomDrawCell := AtributoCustomDrawCell;
    FColAtributo[i] := Col;
  end;
end;

// Pinta el swatch de color en la celda de atributo si el valor casa con la
// paleta basica. Usa el helper "todo en uno" de inLibAtributosPaleta.
procedure TGridArticulosLineas.AtributoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
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

// Si algun atributo (talla/color) tiene un unico valor en los SKUs del
// articulo, lo fija solo; si con eso quedan todos resueltos, cierra el SKU y
// avisa al host (igual que la caja resuelve un articulo de una sola variante).
procedure TGridArticulosLineas.AutoCompletarAtributosUnicos(
  const ACodArt: string);
var
  i, n: Integer;
  Avs: TArray<TArticuloAtributoValor>;
  sSku: string;
  bTodos: Boolean;
begin
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  if n = 0 then
    Exit;
  bTodos := True;
  for i := 1 to n do
  begin
    if FCds.FieldByName(FCampos.AttrValor[i]).AsString = '' then
    begin
      Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i);
      if Length(Avs) = 1 then
        FCds.FieldByName(FCampos.AttrValor[i]).AsString := Avs[0].Valor
      else
        bTodos := False;
    end;
  end;
  if bTodos then
  begin
    sSku := GenerarSku;
    FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
    if Assigned(FOnResuelto) then
      FOnResuelto(ACodArt, sSku,
                  FCds.FieldByName(FCampos.Descripcion).AsString, True);
  end;
end;

// El SKU es CODIGO_ART/val1/val2...; vuelca val1..valN en ATTRn_VALOR para que
// las columnas de talla/color muestren los valores de un SKU ya cerrado.
procedure TGridArticulosLineas.RellenarAtributosDesdeSku(const ACodArt,
                                                         ASku: string);
var
  sResto: string;
  Partes: TArray<string>;
  i: Integer;
begin
  if (ASku = '') or (not StartsText(ACodArt + '/', ASku)) then
    Exit;
  sResto := Copy(ASku, Length(ACodArt) + 2, MaxInt);
  Partes := sResto.Split(['/']);
  for i := 0 to High(Partes) do
    if i < 5 then
      FCds.FieldByName(FCampos.AttrValor[i + 1]).AsString := Partes[i];
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
  // Muestra SIEMPRE las columnas de talla/color del articulo (aunque el SKU
  // venga ya cerrado, para que el usuario vea color/talla).
  ActualizarColumnasAtributo(sCodArt);
  if bCompleto then
  begin
    FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
    RellenarAtributosDesdeSku(sCodArt, sSku);
    if Assigned(FOnResuelto) then
      FOnResuelto(sCodArt, sSku, sDesc, True);
  end
  else
  begin
    FCds.FieldByName(FCampos.CodigoUnidad).AsString := sCodArt;
    AutoCompletarAtributosUnicos(sCodArt);
  end;
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

procedure TGridArticulosLineas.AplicarSkuYAvisar;
var
  sSku, sCodArt, sDesc: string;
  n: Integer;
  bCompleto: Boolean;
begin
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

// Click en el boton de una columna de atributo: abre la paleta (listbox con
// swatches) con los AV validos del articulo y aplica el elegido. Mismo flujo
// que inMtoCajaOpe.tvLineasOpeAvButtonClick (sin combo in-place, que se
// desparenta y lanza EInvalidOperation).
procedure TGridArticulosLineas.AtributoButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
var
  Col: TcxGridColumn;
begin
  Col := FView.Controller.FocusedColumn;
  if Col = nil then
    Exit;
  if (Col.Tag >= 1) and (Col.Tag <= 5) then
    AbrirPaletaOrden(Col.Tag);
end;

// Abre la paleta (listbox de swatches) con los AV validos del atributo AOrden
// del articulo de la linea y aplica el elegido. La usan tanto el click en el
// boton (ellipsis) como la apertura automatica al entrar en la celda vacia.
procedure TGridArticulosLineas.AbrirPaletaOrden(AOrden: Integer);
var
  Edit: TcxCustomEdit;
  i, ScrX, ScrY, WidHint: Integer;
  sArtPadre, sAvActual, sNombreAtb, sIdVa, sAvNuevo: string;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
begin
  if (AOrden < 1) or (AOrden > 5) then
    Exit;
  if (not FCds.Active) or FCds.IsEmpty then
    Exit;
  sArtPadre := FCds.FieldByName(FCampos.CodigoArt).AsString;
  sAvActual := FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString;
  sNombreAtb := FCds.FieldByName(FCampos.AttrNombre[AOrden]).AsString;
  Avs := FLookup.ObtenerAvsEnSkus(sArtPadre, AOrden);
  if Length(Avs) = 0 then
  begin
    ShowMessage('No hay valores definidos para este atributo.');
    Exit;
  end;
  SetLength(AvsStr, Length(Avs));
  for i := 0 to High(Avs) do
    AvsStr[i] := Avs[i].Valor;
  sIdVa := '';
  Mapa := ObtenerMapaAtributosGlobal;
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(sNombreAtb)), sIdVa);
  // Posicion bajo el editor in-place; si aun no esta parentado, auto-centrar
  // (evita EInvalidOperation en ClientToScreen).
  ScrX := -1;
  ScrY := -1;
  WidHint := 120;
  Edit := nil;
  if FView.Controller.EditingController.IsEditing then
    Edit := FView.Controller.EditingController.Edit;
  if (Edit <> nil) and Edit.HasParent then
    try
      ScrX := Edit.ClientToScreen(Point(0, Edit.Height)).X;
      ScrY := Edit.ClientToScreen(Point(0, Edit.Height)).Y;
      WidHint := Edit.Width;
    except
      on E: EInvalidOperation do
      begin
        ScrX := -1;
        ScrY := -1;
        WidHint := 120;
      end;
    end;
  if not SeleccionarAvConPaleta(sIdVa, AvsStr, sAvActual, sAvNuevo,
                                ScrX, ScrY, WidHint) then
    Exit;
  if FCds.State = dsBrowse then
    FCds.Edit;
  if FCds.State in [dsEdit, dsInsert] then
  begin
    FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString := sAvNuevo;
    AplicarSkuYAvisar;
  end;
end;

end.
