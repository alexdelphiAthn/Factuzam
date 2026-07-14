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
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, cxGraphics, cxEdit,
  cxTextEdit,
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
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    FAlmacenStock: string;
    // Desplegable de busqueda incremental por CODIGO_UNIDAD_SKU: query +
    // datasource + view en su repositorio + item de edicion combo. Todo en
    // runtime (la lib no tiene .dfm), como inLibGridArticulos.
    FBusqQry: TUniQuery;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    // Columna OCULTA duplicada del SKU que actua de ListFieldItem del
    // combo, con todo el buscado/filtrado desactivado: el lookup no
    // tiene donde morder y no autocompleta ni deja la lista "pegada"
    // (patron inMtoCajaOpe: dbtvBusqINPUT_BUSQUEDA).
    FBusqColInput: TcxGridDBColumn;
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
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    // OnExit del editor in-place de la celda de SKU: avisa al host para
    // restaurar el EnterAsTab que desactivo al entrar.
    procedure EditorSalir(Sender: TObject);
    // Restaura el EnterAsTab al SALIR de la columna del combo: el
    // OnExit del editor in-place no es fiable con AlwaysShowEditor.
    procedure FocoItemCambiado(Sender: TcxCustomGridTableView;
                               APrevFocusedItem,
                               AFocusedItem: TcxCustomGridTableItem);
    procedure CrearLookupBusqueda;
    // Consulta en servidor el top-100 de SKUs cuyo CODIGO_UNIDAD_SKU
    // empieza por ATexto ('' = primeros 100 por codigo).
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    // Limpia el filtro interno del desplegable (IncSearching + Filter
    // del DataController): sin esto la lista se queda "pegada" a la
    // fila autocompletada aunque la query traiga mas filas. Mismo
    // mecanismo que inMtoCajaOpe.tmrBusqTimer.
    procedure LimpiarFiltroDesplegable;
    // Si el documento YA tiene una linea con ese SKU, suma 1 a su
    // cantidad y devuelve True (la lectura queda consumida sin crear
    // otra linea igual).
    function AcumularLineaExistente(const ACodArt, ASku,
                                    ADesc: string): Boolean;
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    procedure SkuChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    // Editor por registro (mismo patron que el desglose): el combo de
    // busqueda incremental SOLO en la celda vacia y enfocada; con SKU
    // ya resuelto, texto plano — un ExtLookup pintaria VACIO cualquier
    // valor que no este en su lista top-100.
    procedure SkuGetProperties(Sender: TcxCustomGridTableItem;
                               ARecord: TcxCustomGridRecord;
                             var AProperties: TcxCustomEditProperties);
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
    procedure SkuGetDisplayText(Sender: TcxCustomGridTableItem;
                                ARecord: TcxCustomGridRecord;
                                var AText: string);
    function ValorRecord(ARecord: TcxCustomGridRecord;
                         const ACampo: string): string;
    function SkuTextoRecord(ARecord: TcxCustomGridRecord): string;
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
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

type
  // Acceso a OnEnter/OnExit (protegidos en TWinControl) de los editores
  // in-place, sin depender de que cada clase cx los re-publique.
  THackWinControl = class(TWinControl);

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
  // Desenganchar los eventos del REPOSITORIO antes de liberar nada:
  // liberar FBusqRepo dispara SetView(nil) en las properties del
  // combo, el editor cacheado del grid sincroniza su texto, salta su
  // Change y SkuChange tocaria FTimerBusq ya liberado (AV nil+$50).
  if FRepCombo <> nil then
  begin
    FRepCombo.Properties.OnChange := nil;
    FRepCombo.Properties.OnInitPopup := nil;
    FRepCombo.Properties.OnCloseUp := nil;
  end;
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

function TModoEntradaSku.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FOnEntrarEdicion;
end;

procedure TModoEntradaSku.SetOnEntrarEdicion(const AValue: TNotifyEvent);
begin
  FOnEntrarEdicion := AValue;
end;

function TModoEntradaSku.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FOnSalirEdicion;
end;

procedure TModoEntradaSku.SetOnSalirEdicion(const AValue: TNotifyEvent);
begin
  FOnSalirEdicion := AValue;
end;

procedure TModoEntradaSku.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaSku.FocoItemCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo esta desactivado MIENTRAS la celda del combo
  // tiene el foco; al pasar a otra columna se restaura.
  if (APrevFocusedItem = FColSku) and
     Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
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

procedure TModoEntradaSku.Desmontar;
begin
  // Sin estado externo que convertir: las lineas del cds YA son la
  // representacion por SKU.
end;

procedure TModoEntradaSku.Construir;
var
  i: Integer;
  procedure CrearColumnaOculta(const ACampo: string);
  var
    Col: TcxGridDBColumn;
  begin
    if (ACampo <> '') and (FConfig.Cds <> nil) and
       (FConfig.Cds.FindField(ACampo) <> nil) then
    begin
      Col := FConfig.View.CreateColumn;
      Col.DataBinding.FieldName := ACampo;
      Col.Visible := False;
      Col.VisibleForCustomization := False;
    end;
  end;
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
    FColSku.OnGetProperties := SkuGetProperties;
    // Swatch del color en la celda (ultimo segmento tras '/'), mismo
    // helper que caja e inventarios.
    FColSku.OnCustomDrawCell := SkuCustomDrawCell;
    // Articulos sin variaciones no tienen SKU: fallback al articulo.
    FColSku.OnGetDisplayText := SkuGetDisplayText;
    CrearColumnaOculta(FConfig.Campos.CodigoArt);
    for i := 1 to 5 do
      CrearColumnaOculta(FConfig.Campos.AttrValor[i]);
  finally
    FConfig.View.EndUpdate;
  end;
  FConfig.View.OnInitEdit := ViewInitEdit;
  // Enter en la celda de SKU resuelve la entrada (tecleo o lector
  // Codigo+CR). Es el evento fiable para la celda del grid.
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  FConfig.View.OnFocusedItemChanged := FocoItemCambiado;
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
  // Sin sincronizar el cursor del dataset con la fila enfocada del
  // desplegable (como dbtvBusq de caja).
  FBusqView.DataController.DataModeController.SyncMode := False;
  FBusqView.OptionsView.GroupByBox := False;
  FBusqView.OptionsSelection.CellSelect := False;
  FBusqView.OptionsBehavior.IncSearch := False;
  FBusqColSku := FBusqView.CreateColumn;
  FBusqColSku.Caption := 'SKU';
  FBusqColSku.DataBinding.FieldName := 'SKU';
  FBusqColSku.Width := 220;
  FBusqColInput := FBusqView.CreateColumn;
  FBusqColInput.DataBinding.FieldName := 'INPUT_BUSQUEDA';
  FBusqColInput.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(FBusqColInput.Properties).IncrementalSearch :=
    False;
  FBusqColInput.Visible := False;
  FBusqColInput.Options.Filtering := False;
  FBusqColInput.Options.FilteringPopup := False;
  FBusqColInput.Options.IncSearch := False;
  FBusqColInput.Options.Grouping := False;
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
    ListFieldItem := FBusqColInput;
    DropDownListStyle := lsEditList;
    AutoSearchOnPopup := False;
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
    // En el repositorio: con AlwaysShowEditor, el hook por editor de
    // InitEdit cae en un clon muerto de las properties.
    OnChange := SkuChange;
  end;
end;

procedure TModoEntradaSku.AbrirBusquedaFiltrada(const ATexto: string);
const
  SQL_BASE =
    'SELECT s.CODIGO_UNIDAD_SKU AS SKU,' +
    '       s.CODIGO_UNIDAD_SKU AS INPUT_BUSQUEDA,' +
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
  if FBusqQry <> nil then
  begin
    // Siempre: aunque la query ya este abierta con el mismo filtro,
    // el desplegable puede tener filtro interno pegado (autocompletado).
    LimpiarFiltroDesplegable;
    // Reabre solo si cambia el texto o el dataset esta invalidado
    // (cambio de almacen / primera vez).
    if not (FBusqQry.Active and (FUltimoFiltro = ATexto)) then
    begin
      Screen.Cursor := crHourGlass;
      FBusqView.BeginUpdate;
      try
        // Desenganchar la vista mientras se recambia la query evita
        // que reaplique su filtro sobre el dataset a medio abrir.
        FBusqView.DataController.DataSource := nil;
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
        FBusqView.DataController.DataSource := FBusqDs;
        FBusqView.DataController.Refresh;
      finally
        FBusqView.EndUpdate;
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TModoEntradaSku.LimpiarFiltroDesplegable;
begin
  if FBusqView <> nil then
  begin
    FBusqView.BeginUpdate;
    try
      FBusqView.Controller.IncSearchingText := '';
      FBusqView.DataController.Filter.Clear;
      FBusqView.DataController.Filter.Active := False;
      FBusqView.DataController.Filter.AutoDataSetFilter := False;
      // RESET imprescindible: sin Refresh la vista sigue mostrando el
      // conjunto filtrado viejo aunque el filtro ya este vacio (caja
      // lo hace en repComboBoxPropertiesInitPopup).
      FBusqView.DataController.Refresh;
    finally
      FBusqView.EndUpdate;
    end;
  end;
end;

// Despliegue del combo (F4 / boton / debounce): consulta con el texto que
// haya en el editor ('' = top-100 por codigo).
procedure TModoEntradaSku.ComboBusqInitPopup(Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    // Si el combo autocompleto, lo tecleado es lo previo a la seleccion.
    sTexto := Combo.Text;
    if Combo.SelLength > 0 then
      sTexto := Copy(sTexto, 1, Combo.SelStart);
    sTexto := Trim(sTexto);
  end;
  // Con el desplegable abierto el Enter debe llegar al combo, no ser Tab.
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
  AbrirBusquedaFiltrada(sTexto);
end;

// Al cerrar el desplegable con seleccion: resuelve el SKU elegido de forma
// diferida (timer 1ms) para no tocar el cds mientras el editor se cierra.
procedure TModoEntradaSku.ComboBusqCloseUp(Sender: TObject);
var
  Edit: TcxCustomEdit;
  sEntrada: string;
begin
  LimpiarFiltroDesplegable;
  // NO se restaura aqui el EnterAsTab: el foco sigue en la celda de
  // SKU y el siguiente Enter debe llegar al grid (mismo arreglo que
  // inLibGridArticulos). Restauran EditorSalir / FocoItemCambiado.
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    sEntrada := Trim(VarToStr(Edit.EditValue));
    // Codigo tecleado SIN coincidencias en el desplegable: EditValue
    // queda vacio (el lookup solo lo rellena al elegir de la lista) y
    // la entrada vive en el texto libre del combo. Sin este rescate,
    // cerrar el desplegable vacio descartaba el codigo en silencio y
    // los articulos fuera de catalogo no se podian teclear.
    if (sEntrada = '') and (Edit is TcxCustomTextEdit) and
       (FBusqQry <> nil) and FBusqQry.Active and FBusqQry.IsEmpty then
      sEntrada := Trim(TcxCustomTextEdit(Edit).Text);
    DispararResolucion(sEntrada);
  end;
end;

// OnChange del editor de la celda de SKU: rearma el debounce que abrira el
// desplegable filtrado por lo tecleado.
procedure TModoEntradaSku.SkuChange(Sender: TObject);
begin
  // Guarda: el Change puede saltar en plena destruccion del modo.
  if FTimerBusq <> nil then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end;
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
      // Text, no EditingValue (el texto libre no llega alli); y si el
      // combo autocompleto, lo tecleado es lo previo a la seleccion.
      sTexto := Combo.Text;
      if Combo.SelLength > 0 then
        sTexto := Copy(sTexto, 1, Combo.SelStart);
      sTexto := Trim(sTexto);
      if Length(sTexto) >= 2 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TModoEntradaSku.SkuGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vVal: Variant;
  bVacia, bEnfocada: Boolean;
begin
  if (ARecord <> nil) and (FRepCombo <> nil) then
  begin
    vVal := ARecord.Values[Sender.Index];
    bVacia := VarIsNull(vVal) or (Trim(VarToStr(vVal)) = '');
    bEnfocada :=
      (FConfig.View.Controller.FocusedRecord = ARecord) and
      (FConfig.View.Controller.FocusedItem = Sender);
    if bVacia and bEnfocada then
      AProperties := FRepCombo.Properties;
  end;
end;

procedure TModoEntradaSku.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  if AItem = FColSku then
  begin
    // Sugerencias en vivo al teclear en la celda de SKU (debounce).
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := SkuChange;
    // EnterAsTab fuera mientras se edita la celda: el host engancha
    // Desactivar/Restaurar en OnEntrarEdicion / OnSalirEdicion.
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinControl(AEdit).OnExit := EditorSalir;
  end;
end;

procedure TModoEntradaSku.ViewEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  sEntrada: string;
begin
  // F3 en la celda de SKU: despliega la busqueda incremental filtrada
  // por lo tecleado (mismo gesto de lookup que el resto de Factuzam).
  if (AItem = FColSku) and (Key = VK_F3) then
  begin
    Key := 0;
    if AEdit is TcxCustomDropDownEdit then
      TcxCustomDropDownEdit(AEdit).DroppedDown := True;
  end
  // Teclas de texto en la celda de SKU: rearman el debounce de la
  // busqueda incremental. El OnChange del lookup NO es fiable (deja
  // de disparar tras el primer autocompletado); el KeyDown del grid
  // llega SIEMPRE, tecla a tecla.
  else if (AItem = FColSku) and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end
  else if (AItem = FColSku) and
          ((Key = VK_RETURN) or (Key = VK_TAB)) then
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
      // El Enter se consume (la resolucion recoloca el foco); el Tab
      // sigue su curso y avanza de celda con la entrada ya en curso.
      if Key = VK_RETURN then
        Key := 0;
      DispararResolucion(sEntrada);
    end;
  end;
end;

// Articulo sin variaciones: no tiene SKU (CODIGO_UNIDAD vacio) y la
// celda quedaba en blanco, dejando la linea sin identificar en el modo
// SKU. Se muestra el codigo de articulo como texto de la celda.
procedure TModoEntradaSku.SkuGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if (Trim(AText) = '') and (ARecord <> nil) then
    AText := ValorRecord(ARecord, FConfig.Campos.CodigoArt);
end;

procedure TModoEntradaSku.SkuCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  R: TRect;
  sArticulo, sTexto: string;
begin
  sTexto := SkuTextoRecord(AViewInfo.GridRecord);
  if sTexto = '' then
    sTexto := AViewInfo.Text;
  sArticulo := ValorRecord(AViewInfo.GridRecord,
                           FConfig.Campos.CodigoArt);
  if PintarCeldaSwatchArticuloSiAplica(
       ACanvas, AViewInfo, sArticulo, sTexto, nil) then
    ADone := True;
  if (not ADone) and (sTexto <> '') and (sTexto <> AViewInfo.Text) then
  begin
    ACanvas.Brush.Color := AViewInfo.Params.Color;
    ACanvas.FillRect(AViewInfo.Bounds);
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    R := AViewInfo.Bounds;
    Inc(R.Left, 4);
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(sTexto, R,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    ACanvas.Brush.Style := bsSolid;
    ADone := True;
  end;
end;

function TModoEntradaSku.ValorRecord(ARecord: TcxCustomGridRecord;
  const ACampo: string): string;
var
  Col: TcxGridColumn;
  vValor: Variant;
begin
  Result := '';
  if (ARecord <> nil) and (FConfig.View <> nil) and (ACampo <> '') then
  begin
    try
      Col := FConfig.View.GetColumnByFieldName(ACampo);
    except
      Col := nil;
    end;
    if Col <> nil then
    begin
      try
        vValor := ARecord.Values[Col.Index];
        if not (VarIsNull(vValor) or VarIsEmpty(vValor) or
                VarIsClear(vValor)) then
          Result := Trim(VarToStr(vValor));
      except
        Result := '';
      end;
    end;
  end;
end;

function TModoEntradaSku.SkuTextoRecord(
  ARecord: TcxCustomGridRecord): string;
var
  i: Integer;
  sArt, sUnidad, sValor: string;
  bTieneAtributos: Boolean;
begin
  sUnidad := ValorRecord(ARecord, FConfig.Campos.CodigoUnidad);
  Result := sUnidad;
  if Pos('/', Result) <= 0 then
  begin
    sArt := ValorRecord(ARecord, FConfig.Campos.CodigoArt);
    if sArt = '' then
      sArt := sUnidad;
    bTieneAtributos := False;
    if sArt <> '' then
    begin
      Result := sArt;
      for i := 1 to 5 do
      begin
        sValor := ValorRecord(ARecord, FConfig.Campos.AttrValor[i]);
        if sValor <> '' then
        begin
          Result := Result + '/' + sValor;
          bTieneAtributos := True;
        end;
      end;
      if not bTieneAtributos then
        Result := sUnidad;
    end;
  end;
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
      // Resuelto: restaura el EnterAsTab (si el foco vuelve a la
      // celda del combo, InitEdit lo desactiva de nuevo).
      if Assigned(FOnSalirEdicion) then
        FOnSalirEdicion(nil);
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
        // SKU repetido (p.ej. segunda lectura de pistola): acumular
        // cantidad en la linea que ya lo tiene, no duplicar linea.
        if AcumularLineaExistente(R.CodigoArticulo, sSku,
                                  R.DescripcionArticulo) then
          Result := True
        else
        begin
          EscribirLinea(R.CodigoArticulo, sSku, R.DescripcionArticulo);
          if Assigned(FOnResuelto) then
            FOnResuelto(R.CodigoArticulo, sSku, R.DescripcionArticulo,
                        True);
          Result := True;
        end;
      end;
    end
    else if FConfig.AceptarNoCatalogo then
    begin
      // Codigo fuera de catalogo: el documento lo admite como linea
      // libre (sin SKU: no mueve stock). El host completa fiscalidad,
      // descripcion y precios en su OnResuelto.
      EscribirLinea(sEntrada, '', '');
      if Assigned(FOnResuelto) then
        FOnResuelto(sEntrada, '', '', True);
      Result := True;
    end;
  end;
end;

function TModoEntradaSku.AcumularLineaExistente(const ACodArt, ASku,
  ADesc: string): Boolean;
var
  ds: TDataSet;
begin
  Result := False;
  ds := FConfig.Cds;
  if (FConfig.Campos.Cantidad <> '') and
     (ds.FindField(FConfig.Campos.Cantidad) <> nil) then
  begin
    // Soltar la edicion de la linea actual (en blanco o a medias)
    // antes de mover el cursor a la linea destino.
    if ds.State in [dsEdit, dsInsert] then
      ds.Cancel;
    if ds.Locate(FConfig.Campos.CodigoUnidad, ASku,
                 [loCaseInsensitive]) then
    begin
      ds.Edit;
      ds.FieldByName(FConfig.Campos.Cantidad).AsFloat :=
        ds.FieldByName(FConfig.Campos.Cantidad).AsFloat + 1;
      ds.Post;
      if Assigned(FOnResuelto) then
        FOnResuelto(ACodArt, ASku, ADesc, True);
      Result := True;
    end;
  end;
end;

end.
