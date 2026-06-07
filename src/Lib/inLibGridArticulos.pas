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
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.Types,
  System.StrUtils, System.Generics.Collections, Data.DB, Uni, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, cxGraphics,
  cxEdit, cxTextEdit, cxButtonEdit, cxDropDownEdit,
  cxEditRepositoryItems, cxDBExtLookupComboBox, cxGrid,
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
    // True mientras AbrirPaletaOrden esta mostrando el editor/paleta, para que
    // el OnEnter del editor (AtributoEnter) no reprograme otra apertura.
    FEnPaleta: Boolean;
    // Almacen cuyo stock se muestra en el buscador de SKU (lo fija el host;
    // en traspaso, el almacen origen). Vacio = no muestra stock.
    FAlmacenStock: string;
    // Busqueda incremental embebida (ExtLookupComboBox) de la columna de
    // articulo: query de SKU + datasource + view en su repositorio + el item
    // de edicion combo. Se crean en runtime (la lib no tiene .dfm).
    FBusqQry: TUniQuery;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    FEditRepo: TcxEditRepository;
    FRepCombo: TcxEditRepositoryExtLookupComboBoxItem;
    // Resolucion diferida al elegir del desplegable (timer 1ms): evita tocar
    // el cds mientras el editor in-place se esta cerrando.
    FTimerResolve: TTimer;
    FSkuPend: string;
    // Lectura con pistola en la celda de articulo: el lector envia STX(#2) +
    // codigo + ETX(#3). Acumulamos el codigo entre ambos y al recibir ETX lo
    // resolvemos (como si llegara un Enter). FEnScanner indica que estamos
    // entre STX y ETX.
    FEnScanner: Boolean;
    FScanBuffer: string;
    procedure CrearLookupBusqueda;
    procedure RecargarBusqueda;
    procedure DispararResolucionScan(const ACodigo: string);
    procedure ArticuloGetProperties(Sender: TcxCustomGridTableItem;
                           ARecord: TcxCustomGridRecord;
                           var AProperties: TcxCustomEditProperties);
    procedure ArticuloKeyPress(Sender: TObject; var Key: Char);
    procedure ComboBusqCloseUp(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    procedure SetAlmacenStock(const AValue: string);
    // Limpia una entrada leida con pistola: el lector envia STX(#2) prefijo y
    // ETX(#3) sufijo (y a veces CR/LF). Se quitan para no ensuciar la
    // resolucion ni el filtrado incremental.
    function LimpiarEntradaScan(const AEntrada: string): string;
    procedure CrearColumnaArticulo;
    procedure CrearColumnasAtributo;
    procedure ArticuloValidate(Sender: TObject; var DisplayValue: Variant;
                               var ErrorText: TCaption; var Error: Boolean);
    procedure ArticuloButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
                           var Key: Word; Shift: TShiftState);
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
                           ACanvas: TcxCanvas;
                           AViewInfo: TcxGridTableDataCellViewInfo;
                           var ADone: Boolean);
    procedure AtributoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure AtributoEnter(Sender: TObject);
    procedure TimerPopupTimer(Sender: TObject);
    procedure AbrirPaletaOrden(AOrden: Integer);
    // Tras elegir un atributo, si quedan atributos sin rellenar enfoca el
    // siguiente y abre su paleta (no deja pasar a la siguiente fila con el
    // SKU a medias). Devuelve True si quedaba alguno pendiente.
    function AvanzarSiguienteAtributo: Boolean;
    // True si la linea actual aun tiene color/talla por elegir (NUM_ATRIBUTOS
    // > 0 y algun ATTRn_VALOR vacio).
    function HayAtributosPendientes: Boolean;
    // Tras resolver un articulo decide el foco como la caja: si faltan
    // atributos salta al primero y abre su paleta; si el SKU ya esta cerrado
    // deja el editor de articulo listo para la siguiente entrada.
    procedure AvanzarTrasResolver;
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
    // Deja el editor de la celda de articulo ABIERTO, listo para teclear o
    // escanear. Imprescindible para el lector: si la celda no esta ya en
    // edicion, la primera tecla abre el editor y las siguientes (muy rapidas)
    // se pierden -> solo se leeria la primera cifra.
    procedure MostrarEditorArticulo;
    // Resuelve una entrada (codigo de articulo, SKU, codigo de barras o ref
    // de proveedor) y rellena la linea. Devuelve False si no se encontro.
    function ResolverEntrada(const AEntrada: string): Boolean;
    property OnResuelto: TArtResueltoEvent read FOnResuelto write FOnResuelto;
    // Almacen para la columna de stock del buscador de SKU (origen). Al
    // cambiarlo se recarga el desplegable de busqueda incremental.
    property AlmacenStock: string read FAlmacenStock write SetAlmacenStock;
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
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
end;

destructor TGridArticulosLineas.Destroy;
begin
  FreeAndNil(FTimerResolve);
  FreeAndNil(FTimerPopup);
  FreeAndNil(FEditRepo);
  FreeAndNil(FBusqRepo);
  FreeAndNil(FBusqDs);
  FreeAndNil(FBusqQry);
  FreeAndNil(FLookup);
  inherited;
end;

function TGridArticulosLineas.CdsEditando: Boolean;
begin
  Result := FCds.Active and (FCds.State in [dsEdit, dsInsert]);
end;

procedure TGridArticulosLineas.Construir;
begin
  // El desplegable de busqueda incremental debe existir antes de crear la
  // columna de articulo (que engancha su OnGetProperties).
  CrearLookupBusqueda;
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
  // OnEditKeyDown del grid: resuelve el codigo en la celda al pulsar Enter
  // (lector Codigo+CR o tecleo manual). Es el evento fiable para la celda.
  FView.OnEditKeyDown := ViewEditKeyDown;
  // Flujo tipo Excel: Enter pasa a la siguiente celda y al llegar al final
  // de la fila salta a la siguiente. NO usamos NewItemRow: la linea nueva se
  // anyade sola al completar un SKU (lo hace el host en OnResuelto).
  FView.OptionsBehavior.GoToNextCellOnEnter := True;
  FView.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  // dbNavigator pequeno embebido: navegar + insertar + borrar (el resto
  // oculto). Insertar/borrar lineas tambien desde aqui.
  FView.Navigator.Visible := True;
  with FView.Navigator.Buttons do
  begin
    First.Visible := True;
    Prior.Visible := True;
    Next.Visible := True;
    Last.Visible := True;
    Insert.Visible := True;
    Delete.Visible := True;
    PriorPage.Visible := False;
    NextPage.Visible := False;
    Edit.Visible := False;
    Post.Visible := False;
    Cancel.Visible := False;
    Refresh.Visible := False;
    SaveBookmark.Visible := False;
    GotoBookmark.Visible := False;
    Filter.Visible := False;
  end;
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
  // Celda de articulo: enganchamos OnKeyPress para capturar el lector de
  // codigo de barras (STX...ETX) y resolver al recibir ETX.
  if (AItem = FColArticulo) and (AEdit is TcxCustomTextEdit) then
  begin
    TcxCustomTextEdit(AEdit).OnKeyPress := ArticuloKeyPress;
    Exit;
  end;
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
  // Si la paleta ya se esta abriendo (el propio AbrirPaletaOrden ha hecho
  // ShowEdit para posicionarse), no reprogramar otra apertura.
  if FEnPaleta then
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
  // Editor por registro: si la celda esta vacia y enfocada, se usa el
  // ExtLookupComboBox con busqueda incremental; si no, el ButtonEdit de
  // arriba. Mismo patron que inMtoCajaOpe.tvArticuloGetProperties.
  FColArticulo.OnGetProperties := ArticuloGetProperties;
end;

// Crea el desplegable de busqueda incremental (ExtLookupComboBox) en runtime:
// query de SKU + datasource + view en su propio repositorio + item de edicion.
procedure TGridArticulosLineas.CrearLookupBusqueda;
begin
  // 1. Query con la lista de SKU (codigo, descripcion y stock en origen). Se
  //    carga entera; el filtrado mientras tecleas es en cliente
  //    (IncrementalFiltering). El stock depende del almacen (param :ALM).
  //    (El boton buscador lista articulos; aqui en el desplegable, SKU.)
  FBusqQry := TUniQuery.Create(nil);
  FBusqQry.Connection := FConn;
  // Ademas del SKU se traen el/los codigo(s) de barras y la(s) referencia(s)
  // de proveedor del articulo, para poder filtrarlos al teclear (igual que el
  // validador resuelve por barras o modelo de proveedor). El valor elegido
  // sigue siendo el SKU.
  FBusqQry.SQL.Text :=
    'SELECT s.CODIGO_UNIDAD_SKU AS SKU,' +
    '       a.DESCRIPCION_ART AS DESCRIPCION,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT cb.CODIGO_BARRAS_CB' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_codigos_barras cb' +
    '                  WHERE cb.CODIGO_UNIDAD_CB = s.CODIGO_UNIDAD_SKU),' +
    '                '''') AS CODBARRAS,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = s.CODIGO_ART_SKU' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '         AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                  WHERE st.CODIGO_UNIDAD_STK = s.CODIGO_UNIDAD_SKU' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM fza_articulos_skus s' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    ' WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '   AND a.TIPO_ART = ''ESTANDAR''' +
    ' ORDER BY STOCK DESC, s.CODIGO_UNIDAD_SKU';
  FBusqQry.ParamByName('ALM').AsString := FAlmacenStock;
  FBusqDs := TDataSource.Create(nil);
  FBusqDs.DataSet := FBusqQry;
  // 2. View del desplegable, dentro de su repositorio (no en pantalla).
  FBusqRepo := TcxGridViewRepository.Create(nil);
  FBusqView := FBusqRepo.CreateItem(TcxGridDBTableView) as TcxGridDBTableView;
  FBusqView.DataController.DataSource := FBusqDs;
  FBusqView.DataController.KeyFieldNames := 'SKU';
  // GridMode: el view trae las filas bajo demanda (no materializa todo el
  // dataset al abrir), mas agil con muchos SKU.
  FBusqView.DataController.DataModeController.GridMode := True;
  FBusqView.OptionsView.GroupByBox := False;
  FBusqView.OptionsSelection.CellSelect := False;
  FBusqView.OptionsBehavior.IncSearch := False;
  FBusqColSku := FBusqView.CreateColumn;
  FBusqColSku.Caption := 'SKU';
  FBusqColSku.DataBinding.FieldName := 'SKU';
  FBusqColSku.Width := 200;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Descripción';
    DataBinding.FieldName := 'DESCRIPCION';
    Width := 220;
  end;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Cód. barras';
    DataBinding.FieldName := 'CODBARRAS';
    Width := 110;
  end;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Ref. prov.';
    DataBinding.FieldName := 'REFPRV';
    Width := 110;
  end;
  with FBusqView.CreateColumn do
  begin
    Caption := 'Stock';
    DataBinding.FieldName := 'STOCK';
    Width := 60;
  end;
  // 3. Item de edicion ExtLookupComboBox que usa ese view.
  FEditRepo := TcxEditRepository.Create(nil);
  FRepCombo := FEditRepo.CreateItem(TcxEditRepositoryExtLookupComboBoxItem)
                 as TcxEditRepositoryExtLookupComboBoxItem;
  with FRepCombo.Properties do
  begin
    View := FBusqView;
    KeyFieldNames := 'SKU';
    ListFieldItem := FBusqColSku;
    DropDownListStyle := lsEditList;
    IncrementalFiltering := True;
    DropDownRows := 15;
    DropDownAutoWidth := True;
    // NO abrir el desplegable al teclear: si se abre, las teclas siguientes van
    // al edit interno del desplegable y NO a ArticuloKeyPress, y la deteccion
    // del lector (rapidez / STX-ETX) no recibe el codigo. El usuario abre el
    // desplegable con F4 o el boton de busqueda cuando quiera buscar a mano.
    ImmediateDropDownWhenKeyPressed := False;
    OnCloseUp := ComboBusqCloseUp;
    // Boton para el buscador completo (mismo que el ButtonEdit).
    Buttons.Clear;
    with Buttons.Add do
      Kind := bkEllipsis;
    OnButtonClick := ArticuloButtonClick;
  end;
  // No se abre aqui: se abriria con ALM='' (en FormCreate aun no hay almacen)
  // y luego AplicarModo lo reabriria con el almacen real -> doble ejecucion
  // del query (cada una ~1,2 s). Se abre una sola vez en RecargarBusqueda,
  // ya con el almacen fijado.
end;

// (Re)abre el desplegable con el stock del almacen actual. Se llama al fijar
// el almacen (SetAlmacenStock) y al cambiar de modo, una sola vez con el
// almacen real.
procedure TGridArticulosLineas.RecargarBusqueda;
begin
  if FBusqQry = nil then
    Exit;
  if FBusqQry.Active then
    FBusqQry.Close;
  FBusqQry.ParamByName('ALM').AsString := FAlmacenStock;
  FBusqQry.Open;
end;

procedure TGridArticulosLineas.SetAlmacenStock(const AValue: string);
begin
  // Recarga si cambia el almacen O si el query aun no se ha abierto (la
  // primera vez: en CrearLookupBusqueda ya no se abre, para no ejecutarlo
  // con almacen vacio).
  if (FAlmacenStock = AValue) and (FBusqQry <> nil) and FBusqQry.Active then
    Exit;
  FAlmacenStock := AValue;
  RecargarBusqueda;
end;

// Editor por registro: celda vacia y enfocada -> ExtLookupComboBox (busqueda
// incremental); en otro caso, el ButtonEdit por defecto de la columna.
procedure TGridArticulosLineas.ArticuloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vVal: Variant;
  bVacia, bEnfocada: Boolean;
begin
  if (ARecord = nil) or (FRepCombo = nil) then
    Exit;
  vVal := ARecord.Values[Sender.Index];
  bVacia := VarIsNull(vVal) or (Trim(VarToStr(vVal)) = '');
  bEnfocada := (FView.Controller.FocusedRecord = ARecord) and
               (FView.Controller.FocusedItem = Sender);
  if bVacia and bEnfocada then
    AProperties := FRepCombo.Properties;
end;

// Lector de codigo de barras en la celda de articulo: el lector manda STX(#2)
// + codigo + ETX(#3). Capturamos el codigo entre ambos (sin dejar que esos
// controles entren en el editor) y al recibir ETX lo resolvemos como si
// llegara un Enter (via FTimerResolve). Mismo patron que inMtoCajaOpe.
procedure TGridArticulosLineas.DispararResolucionScan(const ACodigo: string);
begin
  // Resuelve lo leido de forma diferida (timer 1ms), como hace el desplegable,
  // para no reestructurar el cds dentro del propio evento de teclado.
  FSkuPend := Trim(ACodigo);
  if FSkuPend <> '' then
  begin
    FTimerResolve.Enabled := False;
    FTimerResolve.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.ArticuloKeyPress(Sender: TObject;
                                                var Key: Char);
begin
  // Lector con framing STX/ETX: acumulamos el codigo entre STX(#2) y ETX(#3)
  // y al recibir ETX lo resolvemos. Los lectores que envian Codigo+CR (sin
  // framing) se resuelven en ViewEditKeyDown al recibir el Enter (VK_RETURN),
  // que es el evento que SI llega de forma fiable a la celda del grid.
  if Key = #2 then
  begin
    FEnScanner := True;
    FScanBuffer := '';
    Key := #0;
  end
  else if FEnScanner then
  begin
    if Key = #3 then
    begin
      FEnScanner := False;
      Key := #0;
      DispararResolucionScan(FScanBuffer);
      FScanBuffer := '';
    end
    else
    begin
      FScanBuffer := FScanBuffer + Key;
      Key := #0;
    end;
  end;
end;

procedure TGridArticulosLineas.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  s: string;
begin
  // Igual que caja (cxGrid1DBTableView1EditKeyDown): el Enter del lector
  // (Codigo+CR) o del usuario en la celda de articulo resuelve el codigo que
  // hay en el editor. Este evento del grid SI recibe el Enter aunque el editor
  // sea un ExtLookupComboBox.
  if (AItem = FColArticulo) and (Key = VK_RETURN) then
  begin
    // Si el desplegable esta abierto, lo cerramos (selecciona la fila) para que
    // el Enter no se quede "consumido" en el dropdown.
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      s := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      s := Trim(VarToStr(AEdit.EditValue));
    if s <> '' then
    begin
      Key := 0;
      DispararResolucionScan(s);
    end;
  end;
end;

// Al cerrar el desplegable con una seleccion: resolvemos el articulo elegido
// (ResolverEntrada acepta articulo o SKU). Se difiere (timer 1ms) para no
// tocar el cds mientras el editor se cierra.
procedure TGridArticulosLineas.ComboBusqCloseUp(Sender: TObject);
begin
  if not (Sender is TcxCustomEdit) then
    Exit;
  FSkuPend := VarToStr(TcxCustomEdit(Sender).EditValue);
  if Trim(FSkuPend) <> '' then
  begin
    FTimerResolve.Enabled := False;
    FTimerResolve.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.TimerResolveTimer(Sender: TObject);
var
  sSku: string;
begin
  FTimerResolve.Enabled := False;
  sSku := FSkuPend;
  FSkuPend := '';
  if Trim(sSku) = '' then
    Exit;
  if ResolverEntrada(sSku) then
  begin
    // Cierra el editor para que la celda muestre lo resuelto (descarta el
    // texto crudo escaneado/elegido que quedo en el editor).
    if FView.Controller.EditingController.IsEditing then
      try
        FView.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          ;
      end;
    // Igual que la caja: si el articulo necesita color/talla, saltamos a la
    // primera columna de atributo y abrimos su paleta; si el SKU ya quedo
    // cerrado, dejamos el editor de articulo listo para encadenar lecturas sin
    // perder la primera cifra de la siguiente.
    AvanzarTrasResolver;
  end;
end;

procedure TGridArticulosLineas.MostrarEditorArticulo;
begin
  // El foco del control del grid lo da quien llama (form: FGrid.SetFocus, o
  // estamos ya dentro del flujo de edicion del grid). Aqui solo enfocamos la
  // columna de articulo y abrimos su editor in-place.
  if (FView <> nil) and (FColArticulo <> nil) then
  begin
    FColArticulo.Focused := True;
    try
      FView.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        ;
    end;
  end;
end;

// True si la linea actual aun tiene atributos (color/talla) por elegir. Lo usa
// AvanzarTrasResolver para decidir si abrir la paleta o pasar a la siguiente
// entrada de articulo.
function TGridArticulosLineas.HayAtributosPendientes: Boolean;
var
  i, n: Integer;
begin
  Result := False;
  if FCds.Active and (not FCds.IsEmpty) then
  begin
    n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
    i := 1;
    while (i <= n) and (not Result) do
    begin
      if Trim(FCds.FieldByName(FCampos.AttrValor[i]).AsString) = '' then
        Result := True;
      Inc(i);
    end;
  end;
end;

// Tras resolver un articulo decide el foco igual que la caja: si la linea aun
// necesita color/talla, salta a la primera columna de atributo pendiente y abre
// su paleta; si el SKU ya quedo cerrado, deja el editor de articulo listo para
// la siguiente entrada.
procedure TGridArticulosLineas.AvanzarTrasResolver;
begin
  if HayAtributosPendientes then
    AvanzarSiguienteAtributo
  else
    MostrarEditorArticulo;
end;

// Click en el boton de la columna de articulo: abre el buscador generico
// (TfrmMtoSearch) con la lista de ARTICULOS (codigo, descripcion y stock en
// el almacen origen). Al elegir uno, se resuelve la linea como si se hubiera
// tecleado el articulo (color/talla se eligen luego con la paleta).
procedure TGridArticulosLineas.ArticuloButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
var
  Q: TUniQuery;
  sArt: string;
begin
  // Si se pulso el "..." estando en el desplegable incremental
  // (ExtLookupComboBox), su lista queda desplegada detras del buscador. La
  // cerramos antes para no tener los dos buscadores a la vez.
  if Sender is TcxExtLookupComboBox then
    TcxExtLookupComboBox(Sender).DroppedDown := False;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := FConn;
    // Articulos (no SKU, como inMtoCajaOpe). Stock = suma de los SKUs del
    // articulo en el almacen origen (0 si no hay o no se fijo almacen).
    Q.SQL.Text :=
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
    Q.ParamByName('ALM').AsString := FAlmacenStock;
    Q.Open;
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de artículos', Q,
                                       'frmMtoArtTraspasoSearch') then
    begin
      sArt := Q.FieldByName('ARTICULO').AsString;
      if ResolverEntrada(sArt) then
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

function TGridArticulosLineas.LimpiarEntradaScan(
  const AEntrada: string): string;
var
  i: Integer;
  c: Char;
begin
  // El lector envia STX(#2) + codigo + ETX(#3), a veces con CR/LF. Quitamos
  // esos controles y recortamos espacios; el codigo en si queda intacto.
  Result := '';
  for i := 1 to Length(AEntrada) do
  begin
    c := AEntrada[i];
    if (c <> #2) and (c <> #3) and (c <> #13) and (c <> #10) then
      Result := Result + c;
  end;
  Result := Trim(Result);
end;

function TGridArticulosLineas.ResolverEntrada(const AEntrada: string): Boolean;
var
  Val: TArticulosValidador;
  R: TArtResolucionEntrada;
  sCodArt, sSku, sDesc, sEntrada: string;
  bCompleto: Boolean;
begin
  Result := False;
  // Quita STX/ETX/CR/LF que mete el lector de codigo de barras.
  sEntrada := LimpiarEntradaScan(AEntrada);
  if sEntrada = '' then
    Exit;
  Val := TArticulosValidador.Create(FConn);
  try
    R := Val.Resolver(sEntrada);
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
  Col: TcxGridDBColumn;
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
  // Asegura el editor in-place visible en la celda del atributo para situar la
  // paleta justo debajo. La apertura automatica (al avanzar desde el atributo
  // anterior) solo enfoca la columna, sin abrir editor, y entonces la paleta
  // salia centrada/lejos. Forzamos FocusedColumn + ShowEdit; FEnPaleta evita
  // que el OnEnter del editor (AtributoEnter) reprograme otra apertura.
  FEnPaleta := True;
  try
    Col := ColumnaPorTag(AOrden);
    if (Col <> nil) and (FView.Controller.FocusedColumn <> Col) then
      FView.Controller.FocusedColumn := Col;
    if not FView.Controller.EditingController.IsEditing then
      try
        FView.Controller.EditingController.ShowEdit;
      except
        // Si aun no puede parentarse el editor, seguimos: se auto-centrara.
      end;
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
      // Si quedan atributos por elegir, salta al siguiente y abre su paleta;
      // asi no se pasa a la siguiente fila con el SKU incompleto. Si ya estan
      // todos (SKU cerrado y el host anyadio una linea nueva), deja el editor
      // de articulo abierto para encadenar la siguiente entrada, como en caja.
      if not AvanzarSiguienteAtributo then
        MostrarEditorArticulo;
    end;
  finally
    FEnPaleta := False;
  end;
end;

function TGridArticulosLineas.AvanzarSiguienteAtributo: Boolean;
var
  i, n: Integer;
  Col: TcxGridDBColumn;
begin
  Result := False;
  if (not FCds.Active) or FCds.IsEmpty then
    Exit;
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  for i := 1 to n do
  begin
    if Trim(FCds.FieldByName(FCampos.AttrValor[i]).AsString) = '' then
    begin
      Col := ColumnaPorTag(i);
      if (Col <> nil) and Col.Visible then
      begin
        FView.Controller.FocusedColumn := Col;
        // Diferimos abrir la paleta (timer 1ms): la modal anterior aun se
        // esta cerrando y el editor de la nueva celda no esta parentado.
        FOrdenPopupPend := i;
        FTimerPopup.Enabled := False;
        FTimerPopup.Enabled := True;
        Result := True;
      end;
      Break;
    end;
  end;
end;

end.
