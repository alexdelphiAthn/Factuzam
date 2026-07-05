{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoSku                                       }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo SKU    }
{    (articulo/color/talla en UNA columna). Una unica columna bound a          }
{    CODIGO_UNIDAD con:                                                        }
{                                                                              }
{      - Busqueda incremental por CODIGO_UNIDAD_SKU: ExtLookupComboBox en      }
{        runtime + consulta en servidor (top-100 por prefijo) + debounce,      }
{        mismo patron que inLibGridArticulos.CrearLookupBusqueda.              }
{      - Si la entrada resuelve a un padre con variaciones, pide color y       }
{        talla con la paleta de swatches (inLibAtributosPaleta), el mismo      }
{        desarrollo que usan caja e inventarios, y compone el SKU              }
{        ART/COLOR/TALLA.                                                      }
{      - Swatch de color en la celda del SKU via PintarCeldaSwatchSiAplica     }
{        (prueba con el ultimo segmento tras '/').                             }
{******************************************************************************}
unit inLibColumnasSkuModoSku;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Types, System.Generics.Collections, Data.DB, Uni, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, cxGraphics, cxEdit, cxTextEdit,
  cxDropDownEdit, cxEditRepositoryItems, cxDBExtLookupComboBox, cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibColumnasSkuIntf, inLibArticulosValidador,
  inLibArticulosAtributosLookup, inLibAtributosPaleta;

type
  TModoEntradaSku = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig: TConfigColumnasSku;
    FColSku: TcxGridDBColumn;
    FLookup: TArticulosAtributosLookup;
    FOnResuelto: TSkuResueltoEvent;
    FAlmacenStock: string;
    // Desplegable de busqueda incremental por CODIGO_UNIDAD_SKU: query +
    // datasource + view en su repositorio + item de edicion combo. Todo en
    // runtime (la lib no tiene .dfm), como inLibGridArticulos.
    FBusqQry: TUniQuery;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    FEditRepo: TcxEditRepository;
    FRepCombo: TcxEditRepositoryExtLookupComboBoxItem;
    // Debounce del tecleo (como el tmrBusq de inMtoCajaOpe) y resolucion
    // diferida (no tocar el cds mientras el editor in-place se cierra).
    FTimerBusq: TTimer;
    FTimerResolve: TTimer;
    FSkuPend: string;
    FUltimoFiltro: string;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    procedure SetAlmacenStock(const AValue: string);
    procedure CrearLookupBusqueda;
    // Consulta en servidor el top-100 de SKUs cuyo CODIGO_UNIDAD_SKU
    // empieza por ATexto ('' = primeros 100 por codigo).
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    procedure SkuChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    procedure SkuCustomDrawCell(Sender: TcxCustomGridTableView;
                                ACanvas: TcxCanvas;
                                AViewInfo: TcxGridTableDataCellViewInfo;
                                var ADone: Boolean);
    // Pide color/talla con la paleta de swatches y compone ART/VAL1/VAL2.
    // Devuelve '' si el usuario cancela o no hay valores.
    function ElegirSkuConPaleta(const ACodArt: string): string;
    procedure DispararResolucion(const AEntrada: string);
    function LimpiarEntrada(const AEntrada: string): string;
    procedure PonerCampo(const ANombre, AValor: string);
    procedure EscribirLinea(const ACodArt, ASku, ADescripcion: string);
  public
    constructor Create(const AConfig: TConfigColumnasSku);
    destructor Destroy; override;
    procedure Construir;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

constructor TModoEntradaSku.Create(const AConfig: TConfigColumnasSku);
begin
  inherited Create;
  FConfig := AConfig;
  FAlmacenStock := AConfig.AlmacenStock;
  FLookup := TArticulosAtributosLookup.Create(AConfig.Conexion);
  FTimerBusq := TTimer.Create(nil);
  FTimerBusq.Enabled := False;
  FTimerBusq.Interval := 350;
  FTimerBusq.OnTimer := TimerBusqTimer;
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
end;

destructor TModoEntradaSku.Destroy;
begin
  FreeAndNil(FTimerResolve);
  FreeAndNil(FTimerBusq);
  FreeAndNil(FEditRepo);
  FreeAndNil(FBusqRepo);
  FreeAndNil(FBusqDs);
  FreeAndNil(FBusqQry);
  FreeAndNil(FLookup);
  inherited;
end;

function TModoEntradaSku.GetModo: TModoColumnasSku;
begin
  Result := mcsSku;
end;

function TModoEntradaSku.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

procedure TModoEntradaSku.SetOnResuelto(const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

procedure TModoEntradaSku.SetAlmacenStock(const AValue: string);
begin
  // El stock del desplegable depende del almacen: invalida el dataset y
  // la proxima busqueda reconsulta.
  if FAlmacenStock <> AValue then
  begin
    FAlmacenStock := AValue;
    if (FBusqQry <> nil) and FBusqQry.Active then
      FBusqQry.Close;
  end;
end;

procedure TModoEntradaSku.Construir;
begin
  // El desplegable debe existir antes de crear la columna que lo usa.
  CrearLookupBusqueda;
  FConfig.View.BeginUpdate;
  try
    FConfig.View.ClearItems;
    FColSku := FConfig.View.CreateColumn;
    FColSku.Caption := 'SKU (Art/Color/Talla)';
    FColSku.DataBinding.FieldName := FConfig.Campos.CodigoUnidad;
    FColSku.Width := 260;
    FColSku.RepositoryItem := FRepCombo;
    // Swatch del color en la celda (ultimo segmento tras '/'), mismo
    // helper que caja e inventarios.
    FColSku.OnCustomDrawCell := SkuCustomDrawCell;
  finally
    FConfig.View.EndUpdate;
  end;
  FConfig.View.OnInitEdit := ViewInitEdit;
  // Enter en la celda de SKU resuelve la entrada (tecleo o lector
  // Codigo+CR). Es el evento fiable para la celda del grid.
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  FConfig.View.OptionsBehavior.GoToNextCellOnEnter := True;
  FConfig.View.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  FConfig.View.OptionsView.ColumnAutoWidth := True;
  FConfig.View.OptionsView.NoDataToDisplayInfoText := 'No hay artículos';
end;

procedure TModoEntradaSku.CrearLookupBusqueda;
begin
  // 1. Query del desplegable. Filtrado EN SERVIDOR: cada tecleo (con
  //    debounce) consulta el top-100 cuyo CODIGO_UNIDAD_SKU empieza por lo
  //    tecleado. Precargar el catalogo entero es inviable con cientos de
  //    miles de SKU (vease inLibGridArticulos.CrearLookupBusqueda).
  FBusqQry := TUniQuery.Create(nil);
  FBusqQry.Connection := FConfig.Conexion;
  FBusqDs := TDataSource.Create(nil);
  FBusqDs.DataSet := FBusqQry;
  // 2. View del desplegable, en su repositorio (no en pantalla).
  FBusqRepo := TcxGridViewRepository.Create(nil);
  FBusqView := FBusqRepo.CreateItem(TcxGridDBTableView)
                 as TcxGridDBTableView;
  FBusqView.DataController.DataSource := FBusqDs;
  FBusqView.DataController.KeyFieldNames := 'SKU';
  FBusqView.DataController.DataModeController.GridMode := True;
  FBusqView.OptionsView.GroupByBox := False;
  FBusqView.OptionsSelection.CellSelect := False;
  FBusqView.OptionsBehavior.IncSearch := False;
  FBusqColSku := FBusqView.CreateColumn;
  FBusqColSku.Caption := 'SKU';
  FBusqColSku.DataBinding.FieldName := 'SKU';
  FBusqColSku.Width := 220;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Descripción';
    DataBinding.FieldName := 'DESCRIPCION';
    Width := 240;
  end;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Stock';
    DataBinding.FieldName := 'STOCK';
    Width := 60;
  end;
  // 3. Item de edicion ExtLookupComboBox sobre ese view.
  FEditRepo := TcxEditRepository.Create(nil);
  FRepCombo := FEditRepo.CreateItem(TcxEditRepositoryExtLookupComboBoxItem)
                 as TcxEditRepositoryExtLookupComboBoxItem;
  with FRepCombo.Properties do
  begin
    View := FBusqView;
    KeyFieldNames := 'SKU';
    ListFieldItem := FBusqColSku;
    DropDownListStyle := lsEditList;
    // El dataset ya trae solo coincidencias (filtro en servidor); el
    // filtro incremental cliente se desactiva.
    IncrementalFiltering := False;
    DropDownRows := 15;
    DropDownAutoWidth := True;
    // No abrir al teclear: el desplegable se abre por debounce o F4;
    // si se abriera, las teclas irian al edit del dropdown.
    ImmediateDropDownWhenKeyPressed := False;
    OnInitPopup := ComboBusqInitPopup;
    OnCloseUp := ComboBusqCloseUp;
  end;
end;

procedure TModoEntradaSku.AbrirBusquedaFiltrada(const ATexto: string);
const
  SQL_BASE =
    'SELECT s.CODIGO_UNIDAD_SKU AS SKU,' +
    '       a.DESCRIPCION_ART AS DESCRIPCION,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                  WHERE st.CODIGO_UNIDAD_STK = s.CODIGO_UNIDAD_SKU' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM fza_articulos_skus s' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    ' WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '   AND a.TIPO_ART = ''ESTANDAR''';
  SQL_FILTRO = ' AND s.CODIGO_UNIDAD_SKU LIKE :PREF';
  SQL_ORDEN = ' ORDER BY s.CODIGO_UNIDAD_SKU LIMIT 100';
begin
  // Reabre solo si cambia el texto o el dataset esta invalidado (cambio
  // de almacen / primera vez).
  if (FBusqQry <> nil) and
     not (FBusqQry.Active and (FUltimoFiltro = ATexto)) then
  begin
    Screen.Cursor := crHourGlass;
    try
      if FBusqQry.Active then
        FBusqQry.Close;
      if ATexto = '' then
        FBusqQry.SQL.Text := SQL_BASE + SQL_ORDEN
      else
      begin
        FBusqQry.SQL.Text := SQL_BASE + SQL_FILTRO + SQL_ORDEN;
        FBusqQry.ParamByName('PREF').AsString := ATexto + '%';
      end;
      FBusqQry.ParamByName('ALM').AsString := FAlmacenStock;
      FBusqQry.Open;
      FUltimoFiltro := ATexto;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

// Despliegue del combo (F4 / boton / debounce): consulta con el texto que
// haya en el editor ('' = top-100 por codigo).
procedure TModoEntradaSku.ComboBusqInitPopup(Sender: TObject);
var
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxExtLookupComboBox then
    sTexto := Trim(VarToStr(TcxExtLookupComboBox(Sender).EditingValue));
  AbrirBusquedaFiltrada(sTexto);
end;

// Al cerrar el desplegable con seleccion: resuelve el SKU elegido de forma
// diferida (timer 1ms) para no tocar el cds mientras el editor se cierra.
procedure TModoEntradaSku.ComboBusqCloseUp(Sender: TObject);
begin
  if Sender is TcxCustomEdit then
    DispararResolucion(VarToStr(TcxCustomEdit(Sender).EditValue));
end;

// OnChange del editor de la celda de SKU: rearma el debounce que abrira el
// desplegable filtrado por lo tecleado.
procedure TModoEntradaSku.SkuChange(Sender: TObject);
begin
  FTimerBusq.Enabled := False;
  FTimerBusq.Enabled := True;
end;

// Al saltar el debounce consulta lo tecleado y abre el desplegable. Minimo
// 2 caracteres: el prefijo de SKU acota rapido (empieza por el articulo).
procedure TModoEntradaSku.TimerBusqTimer(Sender: TObject);
var
  Edit: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  FTimerBusq.Enabled := False;
  if FConfig.View.Controller.EditingController.IsEditing then
  begin
    Edit := FConfig.View.Controller.EditingController.Edit;
    if Edit is TcxExtLookupComboBox then
    begin
      Combo := TcxExtLookupComboBox(Edit);
      sTexto := Trim(VarToStr(Combo.EditingValue));
      if Length(sTexto) >= 2 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TModoEntradaSku.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  // Sugerencias en vivo al teclear en la celda de SKU (debounce).
  if (AItem = FColSku) and (AEdit is TcxCustomTextEdit) then
    TcxCustomTextEdit(AEdit).Properties.OnChange := SkuChange;
end;

procedure TModoEntradaSku.ViewEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  sEntrada: string;
begin
  if (AItem = FColSku) and (Key = VK_RETURN) then
  begin
    // Si el desplegable esta abierto lo cerramos (selecciona la fila)
    // para que el Enter no quede consumido en el dropdown.
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      sEntrada := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      Key := 0;
      DispararResolucion(sEntrada);
    end;
  end;
end;

procedure TModoEntradaSku.SkuCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TModoEntradaSku.DispararResolucion(const AEntrada: string);
begin
  FSkuPend := Trim(AEntrada);
  if FSkuPend <> '' then
  begin
    FTimerResolve.Enabled := False;
    FTimerResolve.Enabled := True;
  end;
end;

procedure TModoEntradaSku.TimerResolveTimer(Sender: TObject);
var
  sEntrada: string;
begin
  FTimerResolve.Enabled := False;
  sEntrada := FSkuPend;
  FSkuPend := '';
  if sEntrada <> '' then
  begin
    if ResolverEntrada(sEntrada) then
    begin
      // Cierra el editor para que la celda muestre el SKU resuelto
      // (descarta el texto crudo tecleado/escaneado).
      if FConfig.View.Controller.EditingController.IsEditing then
        try
          FConfig.View.Controller.EditingController.HideEdit(False);
        except
          on E: EInvalidOperation do
            ;
        end;
      MostrarEditor;
    end;
  end;
end;

procedure TModoEntradaSku.MostrarEditor;
begin
  // Deja el editor de SKU abierto: si la celda no esta en edicion, la
  // primera tecla del lector abre el editor y las siguientes se pierden.
  if (FConfig.View <> nil) and (FColSku <> nil) then
  begin
    FColSku.Focused := True;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        ;
    end;
  end;
end;

function TModoEntradaSku.LimpiarEntrada(const AEntrada: string): string;
var
  i: Integer;
  c: Char;
begin
  // Quita STX(#2)/ETX(#3)/CR/LF que mete el lector de codigo de barras.
  Result := '';
  for i := 1 to Length(AEntrada) do
  begin
    c := AEntrada[i];
    if (c <> #2) and (c <> #3) and (c <> #13) and (c <> #10) then
      Result := Result + c;
  end;
  Result := Trim(Result);
end;

procedure TModoEntradaSku.PonerCampo(const ANombre, AValor: string);
var
  Campo: TField;
begin
  // Solo escribe si el documento definio el campo y existe en el cds.
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;
end;

procedure TModoEntradaSku.EscribirLinea(const ACodArt, ASku,
                                        ADescripcion: string);
begin
  if not (FConfig.Cds.State in [dsEdit, dsInsert]) then
    FConfig.Cds.Edit;
  PonerCampo(FConfig.Campos.CodigoUnidad, ASku);
  PonerCampo(FConfig.Campos.CodigoArt, ACodArt);
  PonerCampo(FConfig.Campos.Descripcion, ADescripcion);
end;

function TModoEntradaSku.ElegirSkuConPaleta(const ACodArt: string): string;
var
  Atribs: TArray<TArticuloAtributo>;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
  sIdVa, sAvNuevo: string;
  i, j: Integer;
  bCancelado: Boolean;
begin
  Result := '';
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  if Length(Atribs) = 0 then
    ShowMessage('El artículo no tiene atributos definidos: ' + ACodArt)
  else
  begin
    Result := ACodArt;
    bCancelado := False;
    i := 0;
    while (i < Length(Atribs)) and (not bCancelado) do
    begin
      // Solo AVs presentes en SKUs del articulo (no todo el conjunto).
      Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
      if Length(Avs) = 0 then
        bCancelado := True
      else if Length(Avs) = 1 then
        // Valor unico: se fija solo, como AutoCompletarAtributosUnicos.
        Result := Result + '/' + Avs[0].Valor
      else
      begin
        SetLength(AvsStr, Length(Avs));
        for j := 0 to High(Avs) do
          AvsStr[j] := Avs[j].Valor;
        sIdVa := '';
        Mapa := ObtenerMapaAtributosGlobal;
        if Mapa <> nil then
          Mapa.TryGetValue(UpperCase(Trim(Atribs[i].NombreAtributo)),
                           sIdVa);
        // Paleta de swatches (desarrollo ya hecho, mismo selector que
        // caja/inventarios). Auto-centrada (-1,-1).
        if SeleccionarAvConPaleta(sIdVa, AvsStr, '', sAvNuevo,
                                  -1, -1, 160) then
          Result := Result + '/' + sAvNuevo
        else
          bCancelado := True;
      end;
      Inc(i);
    end;
    if bCancelado then
      Result := '';
  end;
end;

function TModoEntradaSku.ResolverEntrada(const AEntrada: string): Boolean;
var
  Val: TArticulosValidador;
  R: TArtResolucionEntrada;
  sEntrada, sSku: string;
begin
  Result := False;
  sEntrada := LimpiarEntrada(AEntrada);
  if sEntrada <> '' then
  begin
    Val := TArticulosValidador.Create(FConfig.Conexion);
    try
      R := Val.Resolver(sEntrada);
    finally
      FreeAndNil(Val);
    end;
    if R.Encontrado then
    begin
      sSku := R.CodigoSku;
      if R.RequiereSku then
        // Coincidio el padre y tiene variaciones: pedir color/talla con
        // la paleta y componer el SKU completo.
        sSku := ElegirSkuConPaleta(R.CodigoArticulo)
      else if sSku = '' then
        // Articulo sin SKUs: la unidad es el propio codigo de articulo.
        sSku := R.CodigoArticulo;
      if sSku <> '' then
      begin
        EscribirLinea(R.CodigoArticulo, sSku, R.DescripcionArticulo);
        if Assigned(FOnResuelto) then
          FOnResuelto(R.CodigoArticulo, sSku, R.DescripcionArticulo,
                      True);
        Result := True;
      end;
    end;
  end;
end;

end.
