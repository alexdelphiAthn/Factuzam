{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoTallas                                    }
{    Tipo:       Libreria                                                      }
{ Version:       0.3.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo        }
{    TALLAS EN HORIZONTAL (una fila por articulo+color y N columnas de         }
{    cantidad por talla, pivotadas por conjunto).                              }
{                                                                              }
{    Adaptador sobre TGestorGridTallas (inLibGridTallasInline, el pivote       }
{    ya en produccion en compras). CONSOLIDA: cada combinacion                 }
{    articulo+atributos no talla es UNA linea; una lectura con talla           }
{    (SKU/barras) suma +1 en la celda de su talla, como la caja pero en        }
{    horizontal. Las lineas heredadas de otros modos (SKU con talla +          }
{    cantidad) se convierten al construir: cantidad a su celda y               }
{    duplicados fusionados.                                                    }
{                                                                              }
{    REQUISITOS DEL HOST:                                                      }
{      - Tabla de celdas y campos de pivote (TGridTallasConfig).               }
{      - Master y lineas ABIERTOS antes de Construir.                          }
{      - Campos ATTRn definidos si hay atributos no talla (color).             }
{******************************************************************************}
unit inLibColumnasSkuModoTallas;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.StrUtils, System.Generics.Collections,
  Data.DB, Uni, Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.ExtCtrls,
  cxGraphics, cxEdit, cxTextEdit, cxDropDownEdit, cxCurrencyEdit,
  cxDataStorage, cxEditRepositoryItems, cxDBExtLookupComboBox, cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibArticulosValidador,
  inLibArticulosAtributosLookup, inLibAtributosPaleta;

type
  // Valores / nombres de los 5 atributos posibles de una linea.
  TValoresAttrTallas = array[1..5] of string;

  TModoEntradaTallas = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig: TConfigColumnasSku;
    FCfgTallas: TGridTallasConfig;
    FGestor: TGestorGridTallas;
    FLookup: TArticulosAtributosLookup;
    FColArticulo: TcxGridDBColumn;
    // Columnas de atributos NO talla (color, temporada...).
    FColAtributo: array[1..5] of TcxGridDBColumn;
    FOnResuelto: TSkuResueltoEvent;
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    // Busqueda incremental en la celda de articulo: por SKU (que
    // empieza por el codigo de articulo), codigo de barras, modelo /
    // referencia de proveedor y contenido de la descripcion — misma
    // consulta UNION que inLibGridArticulos. Desplegable en runtime +
    // filtro en servidor (top-100) con debounce.
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
    FTimerBusq: TTimer;
    FUltimoFiltro: string;
    // Resolucion diferida del Enter en la celda de articulo.
    FTimerResolve: TTimer;
    // Carga inicial de celdas DIFERIDA (timer 1ms): el host anyade sus
    // columnas DESPUES de Construir y crear columnas en el view resetea
    // los Values[] no-bound; cargando en el siguiente tick, todas las
    // columnas ya existen y las cantidades no se pierden.
    FTimerCarga: TTimer;
    FEntradaPend: string;
    // True si la ultima entrada traia talla (lectura de SKU/barras):
    // el foco vuelve al articulo para encadenar lecturas.
    FUltimaConTalla: Boolean;
    // Guardia de reentrada del modal distribuidor (OnEditing puede
    // dispararse varias veces mientras el modal se abre).
    FDistribAbierto: Boolean;
    // Hook AfterPost del cds (patron de inMtoComprasSesiones): el Post
    // implicito al cambiar de fila re-renderiza el grid y limpia los
    // Values[] no-bound; el hook recarga las celdas. FEnProceso lo
    // silencia durante las conversiones internas (rederivar, desmontar,
    // totales), que postean muchas veces.
    FAfterPostOrig: TDataSetNotifyEvent;
    FAfterScrollOrig: TDataSetNotifyEvent;
    FEnProceso: Boolean;
    // Recarga de celdas DIFERIDA (1ms): post y scroll repintan el grid
    // DESPUES de sus eventos; recargando en el siguiente tick, la
    // recarga siempre es lo ultimo y no la pisa ningun repintado.
    FTimerRecarga: TTimer;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    procedure EditorSalir(Sender: TObject);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    procedure CrearLookupBusqueda;
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    // Limpia el filtro interno del desplegable (IncSearching + Filter
    // del DataController): sin esto la lista se queda "pegada" a la
    // fila autocompletada aunque la query traiga mas filas. Mismo
    // mecanismo que inMtoCajaOpe.tmrBusqTimer.
    procedure LimpiarFiltroDesplegable;
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    // Combo de busqueda SOLO en celda de articulo vacia y enfocada;
    // con articulo resuelto, texto plano (patron del modo SKU).
    procedure ArtGetProperties(Sender: TcxCustomGridTableItem;
                               ARecord: TcxCustomGridRecord;
                             var AProperties: TcxCustomEditProperties);
    procedure ArtChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    procedure TimerCargaTimer(Sender: TObject);
    // Totales de TODAS las lineas desde la tabla de celdas (una sola
    // consulta agrupada). El gestor solo refresca la linea activa.
    procedure RefrescarTotalesTodasLineas;
    procedure EnfocarColumnaPorCampo(const ACampo: string);
    function EsAtributoTalla(const AAtrib: TArticuloAtributo): Boolean;
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
                                     ACanvas: TcxCanvas;
                                AViewInfo: TcxGridTableDataCellViewInfo;
                                     var ADone: Boolean);
    // Trocea un SKU cerrado ART/VAL1/VAL2 en sus valores; nil si el
    // SKU no pertenece al articulo o no tiene variacion.
    function PartesDeSku(const AArt, ASku: string): TArray<string>;
    // Calcula (SIN escribir en el cds) valores y nombres de atributos
    // no talla, el conjunto pivote y el indice del atributo talla.
    // APartes: valores que trajo el SKU (prioridad sobre la paleta).
    procedure CalcularAtributosLinea(const ACodArt: string;
                                     const APartes: TArray<string>;
                                     ASilencioso: Boolean;
                                     out AVal, ANom: TValoresAttrTallas;
                                     out AAcTalla, AOrdenTalla: Integer);
    // Escribe atributos + pivote en la linea actual y rotula/muestra
    // las columnas de atributo usadas.
    procedure EscribirAtributosLinea(const AVal, ANom: TValoresAttrTallas;
                                     AAcTalla: Integer);
    // Localiza la linea existente con mismo articulo, mismo almacen y
    // mismos atributos no talla (consolidacion). Mueve el cursor.
    function LocalizarLineaExistente(const ACodArt, AAlm: string;
                                 const AVal: TValoresAttrTallas): Boolean;
    // ID_AV de la talla AValor del articulo (0 si no existe).
    function IdAvDeTalla(const ACodArt: string; AOrdenTalla: Integer;
                         const AValor: string): Integer;
    // Suma ACant a la celda (linea, almacen, AV) con upsert atomico.
    // AAlm: almacen de la celda ('' fuera del formato distribuido).
    // ARefrescar: recarga la fila enfocada y sus totales (False
    // durante las conversiones masivas).
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACant: Double;
                           const AAlm: string; ARefrescar: Boolean);
    // Lineas heredadas de otros modos: deriva pivote/atributos, vuelca
    // CANTIDAD del SKU con talla a su celda y fusiona duplicadas.
    procedure RederivarLineasExistentes;
    // Fallback de pivote: conjunto global MAS PEQUENYO que contiene
    // todos los AVs de talla del articulo. 0 si ninguno cubre.
    function BuscarConjuntoParaAvs(
      const AAvs: TArray<TArticuloAtributoValor>): Integer;
    // Formato distribuido: bloquea la edicion inline de las celdas de
    // talla y abre el distribuidor (mismo patron que sesiones).
    procedure ViewEditing(Sender: TcxCustomGridTableView;
                          AItem: TcxCustomGridTableItem;
                          var AAllow: Boolean);
    procedure AbrirDistribuidorLinea;
    // En distribuido SIEMPRE hay almacen por defecto: si el documento
    // no lo trae, se toma el primer almacen activo estandar de
    // fza_almacenes (avisando); sin almacenes definidos -> excepcion.
    procedure AsegurarAlmacenDefecto;
    // Al construir, unifica el origen de las cantidades segun el
    // formato: con distribuido, las celdas SIN almacen (tecleadas en
    // modo normal) migran al almacen por defecto del documento; sin
    // distribuido, las celdas por almacen se colapsan a almacen ''.
    // Siempre fusionando cantidades si la celda destino ya existe.
    procedure MigrarCeldasAlmacen;
    procedure CeldaTallaCambiada(Sender: TObject);
    procedure FocoLineaCambiado(Sender: TcxCustomGridTableView;
                                APrevFocusedRecord,
                                AFocusedRecord: TcxCustomGridRecord;
                                ANewItemRecordFocusingChanged: Boolean);
    // Restaura el EnterAsTab al SALIR de la columna del combo: el
    // OnExit del editor in-place no es fiable con AlwaysShowEditor.
    procedure FocoItemCambiado(Sender: TcxCustomGridTableView;
                               APrevFocusedItem,
                               AFocusedItem: TcxCustomGridTableItem);
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure ArmarRecarga;
    procedure TimerRecargaTimer(Sender: TObject);
    // El gestor rotula las columnas sobrantes con el generico
    // 'Talla N': aqui se dejan con un punto — solo se pinta la talla.
    procedure LimpiarCaptionsGenericas;
    procedure PonerCampo(const ANombre, AValor: string);
    // Lectura defensiva de un campo del cds ('' si no definido).
    function LeerCampo(const ANombre: string): string;
    // SKU de una linea: articulo + atributos en su orden, con la talla
    // AtALLA insertada en la posicion AOrdTalla (0-based).
    function ComponerSkuLinea(const AArt: string;
                              const AVal: TValoresAttrTallas;
                              AOrdTalla: Integer;
                              const ATalla: string): string;
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgTallas: TGridTallasConfig);
    destructor Destroy; override;
    procedure Construir;
    // Des-pivote al abandonar el modo: cada celda con cantidad pasa a
    // una linea por SKU (cantidad plana) y se limpian las celdas.
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

uses
  inLibGlobalVar, inMtoModalDistribuidor;

type
  // Acceso a OnExit (protegido en TWinControl) de los editores in-place.
  THackWinControl = class(TWinControl);

  // Celda con cantidad pendiente de expandir a linea propia al salir
  // del modo tallas (Desmontar). Alm: almacen de la celda (formato
  // distribuido); '' en celdas sin almacen.
  TCeldaExpansion = record
    Linea: Integer;
    Alm: string;
    ValorTalla: string;
    Cant: Double;
  end;

constructor TModoEntradaTallas.Create(const AConfig: TConfigColumnasSku;
                                      const ACfgTallas: TGridTallasConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FCfgTallas := ACfgTallas;
  FLookup := TArticulosAtributosLookup.Create(AConfig.Conexion);
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
  FTimerBusq := TTimer.Create(nil);
  FTimerBusq.Enabled := False;
  FTimerBusq.Interval := 350;
  FTimerBusq.OnTimer := TimerBusqTimer;
  FTimerCarga := TTimer.Create(nil);
  FTimerCarga.Enabled := False;
  FTimerCarga.Interval := 1;
  FTimerCarga.OnTimer := TimerCargaTimer;
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

destructor TModoEntradaTallas.Destroy;
begin
  // Devolver los hooks del cds a su duenyo (solo si los enganchamos).
  if FGestor <> nil then
  begin
    FConfig.Cds.AfterPost := FAfterPostOrig;
    FConfig.Cds.AfterScroll := FAfterScrollOrig;
  end;
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FTimerCarga);
  FreeAndNil(FTimerBusq);
  FreeAndNil(FTimerResolve);
  FreeAndNil(FEditRepo);
  FreeAndNil(FBusqRepo);
  FreeAndNil(FBusqDs);
  FreeAndNil(FBusqQry);
  FreeAndNil(FGestor);
  FreeAndNil(FLookup);
  inherited;
end;

function TModoEntradaTallas.GetModo: TModoColumnasSku;
begin
  Result := mcsTallasInline;
end;

function TModoEntradaTallas.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

procedure TModoEntradaTallas.SetOnResuelto(const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

function TModoEntradaTallas.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FOnEntrarEdicion;
end;

procedure TModoEntradaTallas.SetOnEntrarEdicion(const AValue: TNotifyEvent);
begin
  FOnEntrarEdicion := AValue;
end;

function TModoEntradaTallas.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FOnSalirEdicion;
end;

procedure TModoEntradaTallas.SetOnSalirEdicion(const AValue: TNotifyEvent);
begin
  FOnSalirEdicion := AValue;
end;

procedure TModoEntradaTallas.SetAlmacenStock(const AValue: string);
begin
  // El stock del desplegable de busqueda depende del almacen: se
  // invalida el dataset y la proxima busqueda reconsulta.
  if FConfig.AlmacenStock <> AValue then
  begin
    FConfig.AlmacenStock := AValue;
    FUltimoFiltro := #1;
    if (FBusqQry <> nil) and FBusqQry.Active then
      FBusqQry.Close;
  end;
end;

procedure TModoEntradaTallas.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaTallas.Construir;
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  // El desplegable de busqueda debe existir antes que su columna.
  CrearLookupBusqueda;
  FConfig.View.BeginUpdate;
  try
    FConfig.View.ClearItems;
    // Columna de articulo (bound); la resolucion va por el validador.
    FColArticulo := FConfig.View.CreateColumn;
    FColArticulo.Caption := 'Artículo';
    FColArticulo.DataBinding.FieldName := FConfig.Campos.CodigoArt;
    FColArticulo.Width := 140;
    // Sugerencias incrementales en la celda vacia y enfocada.
    FColArticulo.OnGetProperties := ArtGetProperties;
    // Columnas de atributos no talla (color...), ocultas hasta usarse.
    // Tag negativo para no chocar con las posiciones de talla.
    for i := 1 to 5 do
    begin
      FColAtributo[i] := nil;
      if FConfig.Campos.AttrValor[i] <> '' then
      begin
        FColAtributo[i] := FConfig.View.CreateColumn;
        FColAtributo[i].Tag := -i;
        FColAtributo[i].Caption := '-';
        FColAtributo[i].Visible := False;
        FColAtributo[i].Width := 90;
        FColAtributo[i].Options.Editing := False;
        FColAtributo[i].DataBinding.FieldName :=
          FConfig.Campos.AttrValor[i];
        FColAtributo[i].OnCustomDrawCell := AtributoCustomDrawCell;
      end;
    end;
    // N columnas de talla no-bound: Tag = posicion 1..N del conjunto.
    // MISMO mecanismo que sesiones de compra (CrearColumnasTallas):
    // ValueTypeClass float — sin el, una columna no-bound de un view DB
    // DESCARTA lo tecleado — y editor Currency con formato entero.
    SetLength(FCfgTallas.ColumnasTallas, FCfgTallas.MaxColumnas);
    for i := 1 to FCfgTallas.MaxColumnas do
    begin
      Col := FConfig.View.CreateColumn;
      Col.Tag := i;
      Col.Caption := '·';
      Col.Width := 46;
      Col.Visible := False;
      Col.DataBinding.ValueTypeClass := TcxFloatValueType;
      Col.PropertiesClass := TcxCurrencyEditProperties;
      with TcxCurrencyEditProperties(Col.Properties) do
      begin
        DisplayFormat := '#,##0';
        OnEditValueChanged := CeldaTallaCambiada;
      end;
      FCfgTallas.ColumnasTallas[i - 1] := Col;
    end;
    // Columnas OCULTAS bound a LINEA e ID_AC_PIVOT: el gestor las lee
    // del DataController (GetColumnByFieldName) para cargar las celdas
    // fila a fila. Sin ellas, la carga se salta en silencio.
    with FConfig.View.CreateColumn do
    begin
      DataBinding.FieldName := FCfgTallas.FieldLinea;
      Visible := False;
      Options.Editing := False;
    end;
    with FConfig.View.CreateColumn do
    begin
      DataBinding.FieldName := FCfgTallas.FieldConjuntoPivot;
      Visible := False;
      Options.Editing := False;
    end;
  finally
    FConfig.View.EndUpdate;
  end;
  FConfig.View.OnInitEdit := ViewInitEdit;
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  FConfig.View.OnFocusedRecordChanged := FocoLineaCambiado;
  FConfig.View.OnFocusedItemChanged := FocoItemCambiado;
  // Formato distribuido: la edicion inline de celdas de talla se
  // bloquea y las cantidades entran por el modal distribuidor. El
  // almacen por defecto es OBLIGATORIO en este formato (si el
  // documento no lo trae, se resuelve o se aborta con excepcion).
  if FConfig.Distribuido then
  begin
    AsegurarAlmacenDefecto;
    FConfig.View.OnEditing := ViewEditing;
  end;
  FConfig.View.OptionsBehavior.GoToNextCellOnEnter := True;
  // El Tab (y el Enter convertido por EnterAsTab) avanza ENTRE CELDAS
  // del grid, no al siguiente control del form.
  FConfig.View.OptionsBehavior.FocusCellOnTab := True;
  FConfig.View.OptionsView.ColumnAutoWidth := False;
  FCfgTallas.Conexion := FConfig.Conexion;
  FCfgTallas.Grid := FConfig.View;
  // El gestor antes de la conversion: la conversion persiste celdas.
  FGestor := TGestorGridTallas.Create(FCfgTallas);
  // Hook AfterPost (como sesiones): recarga celdas tras el Post
  // implicito de cambiar de fila. Silenciado hasta acabar la carga
  // diferida (FEnProceso) para no recargar N veces en la conversion.
  FEnProceso := True;
  FAfterPostOrig := FConfig.Cds.AfterPost;
  FConfig.Cds.AfterPost := CdsAfterPost;
  FAfterScrollOrig := FConfig.Cds.AfterScroll;
  FConfig.Cds.AfterScroll := CdsAfterScroll;
  // Lineas heredadas de otros modos / documento reabierto: derivar
  // pivote y atributos, volcar cantidades y fusionar duplicadas.
  RederivarLineasExistentes;
  // Unificar celdas segun el formato (las heredadas se vuelcan a
  // almacen '', por eso la migracion va DESPUES del rederivar).
  MigrarCeldasAlmacen;
  // La carga visual (columnas visibles, cantidades y rotulos) se
  // DIFIERE un tick: el host anyade sus columnas tras Construir y eso
  // resetea los Values[] no-bound del DataController.
  FTimerCarga.Enabled := False;
  FTimerCarga.Enabled := True;
end;

procedure TModoEntradaTallas.RefrescarTotalesTodasLineas;
var
  Qry: TUniQuery;
  ds: TDataSet;
  Tot: TDictionary<Integer, Double>;
  bk: TBookmark;
  iLinea: Integer;
  rTot, rPr: Double;
begin
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) and
     (ds.FindField(FCfgTallas.FieldTotalUds) <> nil) then
  begin
    Tot := TDictionary<Integer, Double>.Create;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN,' +
        ' COALESCE(SUM(' + FCfgTallas.FieldCantidadCel + '), 0)' +
        ' AS TOTAL' +
        ' FROM ' + FCfgTallas.TablaCeldas +
        ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
        ' AND ' + FCfgTallas.FieldNumeroCel + ' = :n' +
        ' GROUP BY ' + FCfgTallas.FieldLineaCel;
      Qry.ParamByName('s').AsString :=
        FCfgTallas.SourceMaster.DataSet.FieldByName(
          FCfgTallas.FieldSerieMaster).AsString;
      Qry.ParamByName('n').AsString :=
        FCfgTallas.SourceMaster.DataSet.FieldByName(
          FCfgTallas.FieldNumeroMaster).AsString;
      Qry.Open;
      while not Qry.Eof do
      begin
        Tot.AddOrSetValue(Qry.FieldByName('LIN').AsInteger,
                          Qry.FieldByName('TOTAL').AsFloat);
        Qry.Next;
      end;
      bk := ds.GetBookmark;
      ds.DisableControls;
      try
        ds.First;
        while not ds.Eof do
        begin
          iLinea := ds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
          rTot := 0;
          Tot.TryGetValue(iLinea, rTot);
          rPr := 0;
          if ds.FindField(FCfgTallas.FieldPrecioBase) <> nil then
            rPr :=
              ds.FieldByName(FCfgTallas.FieldPrecioBase).AsFloat;
          if ds.FieldByName(
               FCfgTallas.FieldTotalUds).AsFloat <> rTot then
          begin
            if not (ds.State in [dsEdit, dsInsert]) then
              ds.Edit;
            ds.FieldByName(FCfgTallas.FieldTotalUds).AsFloat := rTot;
            if ds.FindField(FCfgTallas.FieldTotalLinea) <> nil then
              ds.FieldByName(FCfgTallas.FieldTotalLinea).AsFloat :=
                rTot * rPr;
            ds.Post;
          end;
          ds.Next;
        end;
        if ds.BookmarkValid(bk) then
          ds.GotoBookmark(bk);
      finally
        ds.FreeBookmark(bk);
        ds.EnableControls;
      end;
    finally
      FreeAndNil(Qry);
      FreeAndNil(Tot);
    end;
  end;
end;

procedure TModoEntradaTallas.TimerCargaTimer(Sender: TObject);
begin
  FTimerCarga.Enabled := False;
  if FGestor <> nil then
  begin
    FGestor.RecalcularMaxColumnas;
    // Totales ANTES de cargar celdas: escribirlos mueve el cursor y
    // repinta filas, lo que limpiaria los Values[] no-bound.
    RefrescarTotalesTodasLineas;
    // Reposicionar TAMBIEN antes de cargar: el scroll del First
    // resetea los Values[] no-bound igual que el EnableControls. El
    // foco tras construir suele quedar en la linea en blanco (pivote
    // 0) y los rotulos se quedarian en el generico 'Talla N'.
    if FConfig.Cds.FieldByName(
         FCfgTallas.FieldConjuntoPivot).AsInteger = 0 then
      FConfig.Cds.First;
    // La carga de celdas, SIEMPRE lo ultimo que toca el grid.
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
    // Conversion terminada: a partir de aqui el hook AfterPost recarga
    // las celdas tras cada Post del usuario.
    FEnProceso := False;
  end;
end;

procedure TModoEntradaTallas.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  // EnterAsTab SOLO se desactiva en la celda de articulo (su Enter
  // resuelve la entrada). En las celdas de talla se deja ACTIVO: el
  // Enter actua como Tab y avanza de talla en talla mientras cada
  // salida de celda persiste su cantidad — igual que en sesiones de
  // compra (ActivarEnterComoTab).
  if AItem = FColArticulo then
  begin
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinControl(AEdit).OnExit := EditorSalir;
    // Sugerencias en vivo: cada tecleo rearma el debounce que abre el
    // desplegable filtrado (articulo/SKU/barras/ref proveedor).
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := ArtChange;
    LogSes('ModoTallas.InitEdit articulo: editor=' + AEdit.ClassName);
  end;
end;

procedure TModoEntradaTallas.ArtGetProperties(
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

procedure TModoEntradaTallas.ArtChange(Sender: TObject);
begin
  FTimerBusq.Enabled := False;
  FTimerBusq.Enabled := True;
end;

procedure TModoEntradaTallas.TimerBusqTimer(Sender: TObject);
var
  Edit: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  FTimerBusq.Enabled := False;
  if not FConfig.View.Controller.EditingController.IsEditing then
    LogSes('ModoTallas.Busq: sin editor activo')
  else
  begin
    Edit := FConfig.View.Controller.EditingController.Edit;
    if not (Edit is TcxExtLookupComboBox) then
      LogSes('ModoTallas.Busq: editor no es combo (' +
             Edit.ClassName + ')')
    else
    begin
      Combo := TcxExtLookupComboBox(Edit);
      // Text, no EditingValue (el texto libre no llega alli); y si el
      // combo autocompleto, lo tecleado es lo previo a la seleccion.
      sTexto := Combo.Text;
      if Combo.SelLength > 0 then
        sTexto := Copy(sTexto, 1, Combo.SelStart);
      sTexto := Trim(sTexto);
      LogSes('ModoTallas.Busq: texto="' + sTexto + '"');
      if Length(sTexto) >= 3 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        LogSes(Format('ModoTallas.Busq: %d coincidencias',
                      [FBusqQry.RecordCount]));
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.CrearLookupBusqueda;
begin
  if FBusqQry = nil then
  begin
    FBusqQry := TUniQuery.Create(nil);
    FBusqQry.Connection := FConfig.Conexion;
    FBusqDs := TDataSource.Create(nil);
    FBusqDs.DataSet := FBusqQry;
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
    FBusqColSku.Width := 200;
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
    FEditRepo := TcxEditRepository.Create(nil);
    FRepCombo := FEditRepo.CreateItem(
                   TcxEditRepositoryExtLookupComboBoxItem)
                   as TcxEditRepositoryExtLookupComboBoxItem;
    with FRepCombo.Properties do
    begin
      View := FBusqView;
      KeyFieldNames := 'SKU';
      ListFieldItem := FBusqColInput;
      DropDownListStyle := lsEditList;
      IncrementalFiltering := False;
      AutoSearchOnPopup := False;
      DropDownRows := 15;
      DropDownAutoWidth := True;
      ImmediateDropDownWhenKeyPressed := False;
      OnInitPopup := ComboBusqInitPopup;
      OnCloseUp := ComboBusqCloseUp;
      // En el repositorio: los clones de properties heredan el evento
      // (el hook por editor se pierde con AlwaysShowEditor).
      OnChange := ArtChange;
    end;
  end;
end;

// Consulta UNION de inLibGridArticulos: prefijo en SKU (que empieza
// por el codigo de articulo), codigo de barras y referencia / modelo
// de proveedor, y contenido en la descripcion. Barras, referencias y
// stock se calculan solo para las <=100 filas devueltas.
procedure TModoEntradaTallas.AbrirBusquedaFiltrada(const ATexto: string);
const
  SQL_CABECERA =
    'SELECT x.SKU,' +
    '       x.SKU AS INPUT_BUSQUEDA,' +
    '       x.DESCRIPCION,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT cb.CODIGO_BARRAS_CB' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_codigos_barras cb' +
    '                  WHERE cb.CODIGO_UNIDAD_CB = x.SKU), '''')' +
    '         AS CODBARRAS,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = x.ART' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '         AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                  WHERE st.CODIGO_UNIDAD_STK = x.SKU' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM ';
  SQL_SIN_FILTRO =
    '(SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '        a.DESCRIPCION_ART AS DESCRIPCION' +
    '   FROM fza_articulos_skus s' +
    '   JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '  WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '    AND a.TIPO_ART = ''ESTANDAR''' +
    '  ORDER BY s.CODIGO_UNIDAD_SKU LIMIT 100) x';
  SQL_CON_FILTRO =
    '((SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '         a.DESCRIPCION_ART AS DESCRIPCION' +
    '    FROM fza_articulos_skus s' +
    '    JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '   WHERE s.CODIGO_UNIDAD_SKU LIKE :TPREF' +
    '     AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '     AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos a' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '    WHERE a.DESCRIPCION_ART LIKE :TDESC' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_codigos_barras cb' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE cb.CODIGO_BARRAS_CB LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos_proveedores ap' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = ap.CODIGO_ART_AP' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE ap.REF_PROVEEDOR_AP LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    ' ) x';
  SQL_ORDEN = ' ORDER BY STOCK DESC, x.SKU LIMIT 100';
begin
  if FBusqQry <> nil then
  begin
    // Siempre: aunque la query ya este abierta con el mismo filtro,
    // el desplegable puede tener filtro interno pegado (autocompletado).
    LimpiarFiltroDesplegable;
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
          FBusqQry.SQL.Text := SQL_CABECERA + SQL_SIN_FILTRO + SQL_ORDEN
        else
        begin
          FBusqQry.SQL.Text := SQL_CABECERA + SQL_CON_FILTRO + SQL_ORDEN;
          FBusqQry.ParamByName('TPREF').AsString := ATexto + '%';
          FBusqQry.ParamByName('TDESC').AsString := '%' + ATexto + '%';
        end;
        FBusqQry.ParamByName('ALM').AsString :=
          Trim(FConfig.AlmacenStock);
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

procedure TModoEntradaTallas.LimpiarFiltroDesplegable;
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

procedure TModoEntradaTallas.ComboBusqInitPopup(Sender: TObject);
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
  // Con el desplegable abierto, el Enter elige fila (no Tab).
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
  AbrirBusquedaFiltrada(sTexto);
end;

procedure TModoEntradaTallas.ComboBusqCloseUp(Sender: TObject);
begin
  LimpiarFiltroDesplegable;
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
  // Resolver el SKU elegido de forma diferida (mismo timer que el
  // Enter): consolida la linea y suma la talla en su celda.
  if Sender is TcxCustomEdit then
  begin
    FEntradaPend := Trim(VarToStr(TcxCustomEdit(Sender).EditValue));
    if FEntradaPend <> '' then
    begin
      FTimerResolve.Enabled := False;
      FTimerResolve.Enabled := True;
    end;
  end;
end;

procedure TModoEntradaTallas.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  // F3 en la celda de articulo: despliega la busqueda incremental
  // filtrada por lo tecleado.
  if (AItem = FColArticulo) and (Key = VK_F3) then
  begin
    Key := 0;
    if AEdit is TcxCustomDropDownEdit then
      TcxCustomDropDownEdit(AEdit).DroppedDown := True;
  end
  // Teclas de texto en la celda de articulo: rearman el debounce de
  // la busqueda incremental. El OnChange del lookup NO es fiable
  // (deja de disparar tras el primer autocompletado); el KeyDown del
  // grid llega SIEMPRE, tecla a tecla.
  else if (AItem = FColArticulo) and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end
  // Enter en la celda de articulo (tecleo o lector Codigo+CR).
  else if (AItem = FColArticulo) and (Key = VK_RETURN) then
  begin
    // Si el desplegable esta abierto, cerrarlo elige la fila y el
    // Enter no se queda consumido en el dropdown.
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
      LogSes('ModoTallas.EditKeyDown: Enter con "' + sEntrada + '"');
      FEntradaPend := sEntrada;
      FTimerResolve.Enabled := False;
      FTimerResolve.Enabled := True;
    end;
  end;
end;

procedure TModoEntradaTallas.EnfocarColumnaPorCampo(
  const ACampo: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  if ACampo <> '' then
    for i := 0 to FConfig.View.ColumnCount - 1 do
    begin
      Col := FConfig.View.Columns[i];
      if SameText(Col.DataBinding.FieldName, ACampo) then
        Col.Focused := True;
    end;
end;

procedure TModoEntradaTallas.TimerResolveTimer(Sender: TObject);
var
  sEntrada: string;
  iAc: Integer;
begin
  FTimerResolve.Enabled := False;
  sEntrada := FEntradaPend;
  FEntradaPend := '';
  if sEntrada <> '' then
  begin
    if ResolverEntrada(sEntrada) then
    begin
      if FConfig.View.Controller.EditingController.IsEditing then
        try
          FConfig.View.Controller.EditingController.HideEdit(False);
        except
          on E: EInvalidOperation do
            ;
        end;
      // Resuelto y editor cerrado: se restaura el EnterAsTab (si el
      // foco vuelve a la celda del combo, InitEdit lo desactiva).
      if Assigned(FOnSalirEdicion) then
        FOnSalirEdicion(nil);
      if FUltimaConTalla then
      begin
        // Lectura con talla (SKU/barras): la cantidad ya se sumo en su
        // celda. Volvemos a la linea en blanco (si la hay) y dejamos
        // el editor de articulo listo para encadenar lecturas.
        FConfig.Cds.Locate(FConfig.Campos.CodigoArt, '', []);
        MostrarEditor;
      end
      else
      begin
        // Sin talla en la entrada: si la linea tiene sistema, foco a
        // la primera celda de talla; si no (servicios, gastos...), a
        // la columna de cantidad del documento.
        iAc := 0;
        if FConfig.Cds.FindField(FCfgTallas.FieldConjuntoPivot) <> nil
        then
          iAc := FConfig.Cds.FieldByName(
                   FCfgTallas.FieldConjuntoPivot).AsInteger;
        if (iAc > 0) and (Length(FCfgTallas.ColumnasTallas) > 0) and
           (FCfgTallas.ColumnasTallas[0] <> nil) and
           FCfgTallas.ColumnasTallas[0].Visible then
          FCfgTallas.ColumnasTallas[0].Focused := True
        else
          EnfocarColumnaPorCampo(FConfig.Campos.Cantidad);
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.AsegurarAlmacenDefecto;
var
  Qry: TUniQuery;
begin
  if Trim(FConfig.AlmacenStock) = '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      // Mismo criterio de almacenes que el distribuidor.
      Qry.SQL.Text :=
        'SELECT CODIGO_ALM_ALM FROM fza_almacenes' +
        ' WHERE ESACTIVO_ALM = ''S''' +
        '   AND TIPO_USO_ALM IN (''ESTANDAR'', ''ESTANDARD'')' +
        ' ORDER BY CODIGO_ALM_ALM LIMIT 1';
      Qry.Open;
      if Qry.Eof then
        raise Exception.Create(
          'Formato distribuido: se necesita un almacén por defecto ' +
          'y no hay almacenes activos definidos.');
      FConfig.AlmacenStock := Qry.Fields[0].AsString;
      LogSes('ModoTallas: sin almacen por defecto; se asume "' +
             FConfig.AlmacenStock + '" (primer almacen activo)');
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TModoEntradaTallas.MigrarCeldasAlmacen;
var
  Qry, QIns: TUniQuery;
  dsM: TDataSet;
  sAlmDef, sSerie, sNumero: string;
  iMigradas: Integer;
begin
  if FCfgTallas.FieldAlmacenCel <> '' then
  begin
    sAlmDef := Trim(FConfig.AlmacenStock);
    if FConfig.Distribuido and (sAlmDef = '') then
      // No deberia ocurrir (AsegurarAlmacenDefecto corre antes); se
      // deja tal cual y el grid seguira mostrando la suma correcta.
      LogSes('ModoTallas.MigrarCeldas: sin almacen por defecto; las ' +
             'celdas sin almacen no se migran')
    else
    begin
      dsM := FCfgTallas.SourceMaster.DataSet;
      sSerie := dsM.FieldByName(FCfgTallas.FieldSerieMaster).AsString;
      sNumero :=
        dsM.FieldByName(FCfgTallas.FieldNumeroMaster).AsString;
      Qry := TUniQuery.Create(nil);
      QIns := TUniQuery.Create(nil);
      try
        Qry.Connection := FConfig.Conexion;
        QIns.Connection := FConfig.Conexion;
        // Celdas ORIGEN a migrar. Nota: nada de INSERT..SELECT sobre
        // la misma tabla — el ON DUPLICATE sobre la columna cantidad
        // resulta ambiguo en MariaDB (#23000). Se leen las celdas y
        // se upsertea fila a fila con parametros, como el gestor.
        if FConfig.Distribuido then
          // Tecleadas en modo normal: almacen '' -> almacen defecto.
          Qry.SQL.Text :=
            'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN, ' +
            FCfgTallas.FieldFilaCel + ' AS FILA, ' +
            FCfgTallas.FieldAvPivotCel + ' AS IDAV, ' +
            FCfgTallas.FieldCantidadCel + ' AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas +
            ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
            ' AND ' + FCfgTallas.FieldNumeroCel + ' = :n' +
            ' AND ' + FCfgTallas.FieldAlmacenCel + ' = '''''
        else
          // Vuelta a formato normal: colapsar almacenes en ''.
          Qry.SQL.Text :=
            'SELECT ' + FCfgTallas.FieldLineaCel + ' AS LIN, ' +
            FCfgTallas.FieldFilaCel + ' AS FILA, ' +
            FCfgTallas.FieldAvPivotCel + ' AS IDAV, ' +
            'SUM(' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas +
            ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
            ' AND ' + FCfgTallas.FieldNumeroCel + ' = :n' +
            ' AND ' + FCfgTallas.FieldAlmacenCel + ' <> ''''' +
            ' GROUP BY ' + FCfgTallas.FieldLineaCel + ', ' +
            FCfgTallas.FieldFilaCel + ', ' +
            FCfgTallas.FieldAvPivotCel;
        Qry.ParamByName('s').AsString := sSerie;
        Qry.ParamByName('n').AsString := sNumero;
        Qry.Open;
        // Upsert por parametros: cantidad destino = existente + origen.
        QIns.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          FCfgTallas.FieldNumeroCel + ', ' +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAlmacenCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, :n, :l, :f, :a, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
        iMigradas := 0;
        while not Qry.Eof do
        begin
          QIns.ParamByName('s').AsString := sSerie;
          QIns.ParamByName('n').AsString := sNumero;
          QIns.ParamByName('l').AsInteger :=
            Qry.FieldByName('LIN').AsInteger;
          QIns.ParamByName('f').AsInteger :=
            Qry.FieldByName('FILA').AsInteger;
          if FConfig.Distribuido then
            QIns.ParamByName('a').AsString := sAlmDef
          else
            QIns.ParamByName('a').AsString := '';
          QIns.ParamByName('p').AsInteger :=
            Qry.FieldByName('IDAV').AsInteger;
          QIns.ParamByName('c').AsFloat :=
            Qry.FieldByName('CANT').AsFloat;
          QIns.ParamByName('u').AsString := FCfgTallas.Usuario;
          QIns.ExecSQL;
          Inc(iMigradas);
          Qry.Next;
        end;
        Qry.Close;
        if iMigradas > 0 then
        begin
          LogSes(Format('ModoTallas.MigrarCeldas: %d celdas ' +
                        'unificadas (distribuido=%s)',
                        [iMigradas,
                         BoolToStr(FConfig.Distribuido, True)]));
          // Origen migrado: fuera las celdas del formato anterior.
          if FConfig.Distribuido then
            QIns.SQL.Text :=
              'DELETE FROM ' + FCfgTallas.TablaCeldas +
              ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
              ' AND ' + FCfgTallas.FieldNumeroCel + ' = :n' +
              ' AND ' + FCfgTallas.FieldAlmacenCel + ' = '''''
          else
            QIns.SQL.Text :=
              'DELETE FROM ' + FCfgTallas.TablaCeldas +
              ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
              ' AND ' + FCfgTallas.FieldNumeroCel + ' = :n' +
              ' AND ' + FCfgTallas.FieldAlmacenCel + ' <> ''''';
          QIns.ParamByName('s').AsString := sSerie;
          QIns.ParamByName('n').AsString := sNumero;
          QIns.ExecSQL;
        end;
      finally
        FreeAndNil(QIns);
        FreeAndNil(Qry);
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.ViewEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // Celdas de talla en distribuido: sin edicion inline; el reparto por
  // almacen entra por el distribuidor. El grid muestra la SUMA (la
  // carga del gestor agrupa por talla sin filtrar almacen).
  if (AItem <> nil) and (AItem.Tag >= 1) and
     (AItem.Tag <= FCfgTallas.MaxColumnas) then
  begin
    AAllow := False;
    if not FDistribAbierto then
      AbrirDistribuidorLinea;
  end;
end;

procedure TModoEntradaTallas.AbrirDistribuidorLinea;
var
  Modal: TfrmModalDistribuidor;
  dsM: TDataSet;
  iLinea, iAc, idxRec: Integer;
begin
  iLinea :=
    FConfig.Cds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
  iAc :=
    FConfig.Cds.FieldByName(FCfgTallas.FieldConjuntoPivot).AsInteger;
  if (iLinea > 0) and (iAc > 0) and (FGestor <> nil) then
  begin
    if FConfig.Cds.State in [dsEdit, dsInsert] then
      FConfig.Cds.Post;
    dsM := FCfgTallas.SourceMaster.DataSet;
    FDistribAbierto := True;
    Modal := TfrmModalDistribuidor.Create(Application);
    // Sin el caFree heredado: liberamos a mano en el finally.
    Modal.OnClose := nil;
    try
      // El distribuidor de sesiones, redirigido a la tabla de celdas
      // de ESTE documento (parametrizacion nueva del modal).
      Modal.ConfigurarCeldas(FCfgTallas.TablaCeldas,
                             FCfgTallas.FieldSerieCel,
                             FCfgTallas.FieldNumeroCel,
                             FCfgTallas.FieldLineaCel,
                             FCfgTallas.FieldFilaCel,
                             FCfgTallas.FieldAlmacenCel,
                             FCfgTallas.FieldAvPivotCel,
                             FCfgTallas.FieldCantidadCel);
      Modal.Preparar(FConfig.Conexion, FCfgTallas.Usuario,
                     dsM.FieldByName(
                       FCfgTallas.FieldSerieMaster).AsString,
                     dsM.FieldByName(
                       FCfgTallas.FieldNumeroMaster).AsString,
                     iLinea, iAc);
      Modal.ShowModal;
      if Modal.Confirmado then
      begin
        // Mismo orden que PersistirCeldaActiva: totales de la linea y
        // recarga de sus celdas, con la carga como ultimo toque.
        FGestor.RefrescarTotalesLineaActual;
        idxRec := FCfgTallas.Grid.Controller.FocusedRecordIndex;
        if idxRec >= 0 then
          FGestor.CargarCantidadesUnaLinea(idxRec, iLinea);
        if Assigned(FCfgTallas.Grid.Site) then
          FCfgTallas.Grid.Site.Invalidate;
      end;
    finally
      FreeAndNil(Modal);
      FDistribAbierto := False;
    end;
  end;
end;

procedure TModoEntradaTallas.CeldaTallaCambiada(Sender: TObject);
begin
  if FGestor <> nil then
    FGestor.PersistirCeldaActiva(Sender);
end;

procedure TModoEntradaTallas.FocoItemCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo esta desactivado MIENTRAS la celda del combo
  // (articulo) tiene el foco; al pasar a cualquier otra columna se
  // restaura y el Enter vuelve a cambiar de control.
  if (APrevFocusedItem = FColArticulo) and
     Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaTallas.FocoLineaCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if FGestor <> nil then
  begin
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

procedure TModoEntradaTallas.LimpiarCaptionsGenericas;
var
  i: Integer;
begin
  // Solo se pinta la TALLA en el caption: las columnas que exceden el
  // conjunto de la linea activa (el gestor las rotula 'Talla N')
  // quedan con un punto neutro.
  for i := 0 to High(FCfgTallas.ColumnasTallas) do
  begin
    if (FCfgTallas.ColumnasTallas[i] <> nil) and
       StartsText('Talla ', FCfgTallas.ColumnasTallas[i].Caption) then
      FCfgTallas.ColumnasTallas[i].Caption := '·';
  end;
end;

procedure TModoEntradaTallas.CdsAfterPost(DataSet: TDataSet);
begin
  if Assigned(FAfterPostOrig) then
    FAfterPostOrig(DataSet);
  // Post (implicito al cambiar de fila o del usuario): el re-render
  // posterior limpia los Values[] no-bound. Recarga diferida.
  ArmarRecarga;
end;

procedure TModoEntradaTallas.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FAfterScrollOrig) then
    FAfterScrollOrig(DataSet);
  // La navegacion tambien puede repintar y limpiar los Values[].
  ArmarRecarga;
end;

procedure TModoEntradaTallas.ArmarRecarga;
begin
  if (FGestor <> nil) and (not FEnProceso) then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TModoEntradaTallas.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  if (FGestor <> nil) and (not FEnProceso) then
  begin
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

function TModoEntradaTallas.LeerCampo(const ANombre: string): string;
var
  Campo: TField;
begin
  Result := '';
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Result := Campo.AsString;
  end;
end;

function TModoEntradaTallas.ComponerSkuLinea(const AArt: string;
  const AVal: TValoresAttrTallas; AOrdTalla: Integer;
  const ATalla: string): string;
var
  i: Integer;
begin
  Result := AArt;
  for i := 1 to 5 do
  begin
    if (i - 1) = AOrdTalla then
      Result := Result + '/' + ATalla
    else if AVal[i] <> '' then
      Result := Result + '/' + AVal[i];
  end;
end;

procedure TModoEntradaTallas.Desmontar;
var
  ds: TDataSet;
  EnProcesoPrevio: Boolean;
  Qry: TUniQuery;
  Celdas: TList<TCeldaExpansion>;
  Cel: TCeldaExpansion;
  OrdPorArt: TDictionary<string, Integer>;
  NomPorArt: TDictionary<string, string>;
  Atribs: TArray<TArticuloAtributo>;
  Vals, Noms: TValoresAttrTallas;
  sArt, sDesc, sAlm, sAlmCel, sSku, sNomTalla: string;
  rPrecio: Double;
  i, idx, iMaxLinea, iOrdT, iLineaAct, iAtrs: Integer;
  bPrimera, bLineaOk: Boolean;
begin
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active then
  begin
    // La expansion postea muchas filas: silenciar el hook AfterPost
    // mientras dura (se restaura al final).
    EnProcesoPrevio := FEnProceso;
    FEnProceso := True;
    Celdas := TList<TCeldaExpansion>.Create;
    OrdPorArt := TDictionary<string, Integer>.Create;
    NomPorArt := TDictionary<string, string>.Create;
    try
      // 1. Celdas con cantidad del documento, con el VALOR de la talla
      //    resuelto (JOIN a fza_atributos_valores).
      Qry := TUniQuery.Create(nil);
      try
        Qry.Connection := FConfig.Conexion;
        // Con almacen por celda, el desglose es por talla Y almacen:
        // la distribucion PERSISTE al salir del modo (una linea por
        // SKU y almacen). Sin campo de almacen, solo por talla.
        if FCfgTallas.FieldAlmacenCel <> '' then
          Qry.SQL.Text :=
            'SELECT c.' + FCfgTallas.FieldLineaCel + ' AS LIN,' +
            ' c.' + FCfgTallas.FieldAlmacenCel + ' AS ALMC,' +
            ' AV.AV AS VALOR,' +
            ' SUM(c.' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas + ' c' +
            ' JOIN fza_atributos_valores AV' +
            '   ON AV.ID_AV = c.' + FCfgTallas.FieldAvPivotCel +
            ' WHERE c.' + FCfgTallas.FieldSerieCel + ' = :s' +
            '   AND c.' + FCfgTallas.FieldNumeroCel + ' = :n' +
            ' GROUP BY c.' + FCfgTallas.FieldLineaCel + ', c.' +
            FCfgTallas.FieldAlmacenCel + ', AV.AV' +
            ' HAVING SUM(c.' + FCfgTallas.FieldCantidadCel +
            ') > 0' +
            ' ORDER BY LIN, ALMC, VALOR'
        else
          Qry.SQL.Text :=
            'SELECT c.' + FCfgTallas.FieldLineaCel + ' AS LIN,' +
            ' '''' AS ALMC,' +
            ' AV.AV AS VALOR,' +
            ' SUM(c.' + FCfgTallas.FieldCantidadCel + ') AS CANT' +
            ' FROM ' + FCfgTallas.TablaCeldas + ' c' +
            ' JOIN fza_atributos_valores AV' +
            '   ON AV.ID_AV = c.' + FCfgTallas.FieldAvPivotCel +
            ' WHERE c.' + FCfgTallas.FieldSerieCel + ' = :s' +
            '   AND c.' + FCfgTallas.FieldNumeroCel + ' = :n' +
            ' GROUP BY c.' + FCfgTallas.FieldLineaCel + ', AV.AV' +
            ' HAVING SUM(c.' + FCfgTallas.FieldCantidadCel +
            ') > 0' +
            ' ORDER BY LIN, VALOR';
        Qry.ParamByName('s').AsString :=
          FCfgTallas.SourceMaster.DataSet.FieldByName(
            FCfgTallas.FieldSerieMaster).AsString;
        Qry.ParamByName('n').AsString :=
          FCfgTallas.SourceMaster.DataSet.FieldByName(
            FCfgTallas.FieldNumeroMaster).AsString;
        Qry.Open;
        while not Qry.Eof do
        begin
          Cel.Linea := Qry.FieldByName('LIN').AsInteger;
          Cel.Alm := Trim(Qry.FieldByName('ALMC').AsString);
          Cel.ValorTalla := Trim(Qry.FieldByName('VALOR').AsString);
          Cel.Cant := Qry.FieldByName('CANT').AsFloat;
          Celdas.Add(Cel);
          Qry.Next;
        end;
      finally
        FreeAndNil(Qry);
      end;
      if Celdas.Count > 0 then
      begin
        // 2. Numeracion para las lineas nuevas: max LINEA actual.
        iMaxLinea := 0;
        ds.First;
        while not ds.Eof do
        begin
          if ds.FieldByName(
               FCfgTallas.FieldLinea).AsInteger > iMaxLinea then
            iMaxLinea :=
              ds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
          ds.Next;
        end;
        // 3. Por cada grupo de celdas de una linea: la primera celda
        //    ACTUALIZA la propia linea (SKU con talla + cantidad); el
        //    resto crea lineas nuevas copiando articulo y atributos.
        iLineaAct := 0;
        iOrdT := -1;
        bPrimera := False;
        bLineaOk := False;
        for idx := 0 to Celdas.Count - 1 do
        begin
          Cel := Celdas[idx];
          if Cel.Linea <> iLineaAct then
          begin
            iLineaAct := Cel.Linea;
            bPrimera := True;
            bLineaOk :=
              ds.Locate(FCfgTallas.FieldLinea, Cel.Linea, []);
            if bLineaOk then
            begin
              sArt := Trim(ds.FieldByName(
                        FConfig.Campos.CodigoArt).AsString);
              sDesc := LeerCampo(FConfig.Campos.Descripcion);
              sAlm := LeerCampo(FConfig.Campos.Almacen);
              // Precio base de la linea origen: las lineas nuevas de
              // la expansion lo heredan (sin el, Total linea = 0).
              rPrecio := 0;
              if (FCfgTallas.FieldPrecioBase <> '') and
                 (ds.FindField(FCfgTallas.FieldPrecioBase) <> nil)
              then
                rPrecio := ds.FieldByName(
                  FCfgTallas.FieldPrecioBase).AsFloat;
              for i := 1 to 5 do
              begin
                Vals[i] := LeerCampo(FConfig.Campos.AttrValor[i]);
                Noms[i] := LeerCampo(FConfig.Campos.AttrNombre[i]);
              end;
              if not OrdPorArt.TryGetValue(sArt, iOrdT) then
              begin
                iOrdT := -1;
                sNomTalla := '';
                Atribs := FLookup.ObtenerAtributos(sArt);
                for i := 0 to High(Atribs) do
                  if EsAtributoTalla(Atribs[i]) then
                  begin
                    iOrdT := i;
                    sNomTalla := Atribs[i].NombreAtributo;
                  end;
                OrdPorArt.Add(sArt, iOrdT);
                NomPorArt.Add(sArt, sNomTalla);
              end
              else
                NomPorArt.TryGetValue(sArt, sNomTalla);
            end;
          end;
          if bLineaOk then
          begin
            sSku := ComponerSkuLinea(sArt, Vals, iOrdT,
                                     Cel.ValorTalla);
            // Almacen de la PARTIDA: el de su celda (formato
            // distribuido); fallback al de la linea origen. Asi la
            // distribucion por almacen PERSISTE al salir del modo.
            if Cel.Alm <> '' then
              sAlmCel := Cel.Alm
            else
              sAlmCel := sAlm;
            if bPrimera then
            begin
              // La propia linea pasa a ser el primer SKU. La talla se
              // vuelca TAMBIEN a su hueco de atributo: es lo que pinta
              // la columna Talla del modo desglose.
              if not (ds.State in [dsEdit, dsInsert]) then
                ds.Edit;
              PonerCampo(FConfig.Campos.CodigoUnidad, sSku);
              PonerCampo(FConfig.Campos.Almacen, sAlmCel);
              if (iOrdT >= 0) and (iOrdT < 5) then
              begin
                PonerCampo(FConfig.Campos.AttrValor[iOrdT + 1],
                           Cel.ValorTalla);
                PonerCampo(FConfig.Campos.AttrNombre[iOrdT + 1],
                           sNomTalla);
              end;
              iAtrs := 0;
              for i := 1 to 5 do
                if Noms[i] <> '' then
                  Inc(iAtrs);
              if iOrdT >= 0 then
                Inc(iAtrs);
              PonerCampo(FConfig.Campos.NumAtributos,
                         IntToStr(iAtrs));
              if ds.FindField(FConfig.Campos.Cantidad) <> nil then
                ds.FieldByName(
                  FConfig.Campos.Cantidad).AsFloat := Cel.Cant;
              ds.FieldByName(
                FCfgTallas.FieldConjuntoPivot).AsInteger := 0;
              ds.Post;
              bPrimera := False;
            end
            else
            begin
              // Linea nueva para cada talla adicional con cantidad.
              Inc(iMaxLinea);
              ds.Append;
              ds.FieldByName(
                FCfgTallas.FieldLinea).AsInteger := iMaxLinea;
              PonerCampo(FConfig.Campos.CodigoArt, sArt);
              PonerCampo(FConfig.Campos.Descripcion, sDesc);
              PonerCampo(FConfig.Campos.Almacen, sAlmCel);
              PonerCampo(FConfig.Campos.CodigoUnidad, sSku);
              if (FCfgTallas.FieldPrecioBase <> '') and
                 (ds.FindField(FCfgTallas.FieldPrecioBase) <> nil)
              then
                ds.FieldByName(
                  FCfgTallas.FieldPrecioBase).AsFloat := rPrecio;
              iAtrs := 0;
              for i := 1 to 5 do
              begin
                PonerCampo(FConfig.Campos.AttrValor[i], Vals[i]);
                PonerCampo(FConfig.Campos.AttrNombre[i], Noms[i]);
                if Noms[i] <> '' then
                  Inc(iAtrs);
              end;
              // Talla en su hueco de atributo (columna Talla del
              // desglose), ademas de en el SKU.
              if (iOrdT >= 0) and (iOrdT < 5) then
              begin
                PonerCampo(FConfig.Campos.AttrValor[iOrdT + 1],
                           Cel.ValorTalla);
                PonerCampo(FConfig.Campos.AttrNombre[iOrdT + 1],
                           sNomTalla);
              end;
              if iOrdT >= 0 then
                Inc(iAtrs);
              PonerCampo(FConfig.Campos.NumAtributos,
                         IntToStr(iAtrs));
              if ds.FindField(FConfig.Campos.Cantidad) <> nil then
                ds.FieldByName(
                  FConfig.Campos.Cantidad).AsFloat := Cel.Cant;
              ds.FieldByName(
                FCfgTallas.FieldConjuntoPivot).AsInteger := 0;
              ds.Post;
            end;
          end;
        end;
        // 4. Celdas transferidas: se limpian del documento.
        Qry := TUniQuery.Create(nil);
        try
          Qry.Connection := FConfig.Conexion;
          Qry.SQL.Text :=
            'DELETE FROM ' + FCfgTallas.TablaCeldas +
            ' WHERE ' + FCfgTallas.FieldSerieCel + ' = :s' +
            '   AND ' + FCfgTallas.FieldNumeroCel + ' = :n';
          Qry.ParamByName('s').AsString :=
            FCfgTallas.SourceMaster.DataSet.FieldByName(
              FCfgTallas.FieldSerieMaster).AsString;
          Qry.ParamByName('n').AsString :=
            FCfgTallas.SourceMaster.DataSet.FieldByName(
              FCfgTallas.FieldNumeroMaster).AsString;
          Qry.ExecSQL;
        finally
          FreeAndNil(Qry);
        end;
        LogSes(Format(
          'ModoTallas.Desmontar: %d celdas expandidas a lineas',
          [Celdas.Count]));
      end;
    finally
      FEnProceso := EnProcesoPrevio;
      FreeAndNil(NomPorArt);
      FreeAndNil(OrdPorArt);
      FreeAndNil(Celdas);
    end;
  end;
end;

procedure TModoEntradaTallas.PonerCampo(const ANombre, AValor: string);
var
  Campo: TField;
begin
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;
end;

function TModoEntradaTallas.EsAtributoTalla(
  const AAtrib: TArticuloAtributo): Boolean;
begin
  // Por nombre (Talla...) o por id (TAL): el nombre puede venir nulo.
  Result := ContainsText(AAtrib.NombreAtributo, 'TALLA') or
            StartsText('TAL', AAtrib.IdAtributo);
end;

procedure TModoEntradaTallas.AtributoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
end;

function TModoEntradaTallas.PartesDeSku(const AArt,
                                        ASku: string): TArray<string>;
begin
  Result := nil;
  if (ASku <> '') and StartsText(AArt + '/', ASku) then
    Result := Copy(ASku, Length(AArt) + 2, MaxInt).Split(['/']);
end;

function TModoEntradaTallas.BuscarConjuntoParaAvs(
  const AAvs: TArray<TArticuloAtributoValor>): Integer;
var
  Qry: TUniQuery;
  sIds: string;
  i: Integer;
begin
  Result := 0;
  if Length(AAvs) > 0 then
  begin
    // Lista IN de enteros construida en memoria (IdValor es Integer).
    sIds := '';
    for i := 0 to High(AAvs) do
    begin
      if sIds <> '' then
        sIds := sIds + ',';
      sIds := sIds + IntToStr(AAvs[i].IdValor);
    end;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      Qry.SQL.Text :=
        'SELECT d.ID_AC_ACD AS ID_AC' +
        '  FROM fza_atributos_conjuntos_det d' +
        ' WHERE d.ID_AV_ACD IN (' + sIds + ')' +
        ' GROUP BY d.ID_AC_ACD' +
        ' HAVING COUNT(DISTINCT d.ID_AV_ACD) = ' +
                IntToStr(Length(AAvs)) +
        ' ORDER BY (SELECT COUNT(*)' +
        '             FROM fza_atributos_conjuntos_det t' +
        '            WHERE t.ID_AC_ACD = d.ID_AC_ACD)' +
        ' LIMIT 1';
      Qry.Open;
      if not Qry.Eof then
        Result := Qry.Fields[0].AsInteger;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TModoEntradaTallas.CalcularAtributosLinea(const ACodArt: string;
  const APartes: TArray<string>; ASilencioso: Boolean;
  out AVal, ANom: TValoresAttrTallas; out AAcTalla, AOrdenTalla: Integer);
var
  Atribs: TArray<TArticuloAtributo>;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
  sIdVa, sAvNuevo: string;
  i, j: Integer;
begin
  for i := 1 to 5 do
  begin
    AVal[i] := '';
    ANom[i] := '';
  end;
  AAcTalla := 0;
  AOrdenTalla := -1;
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  for i := 0 to High(Atribs) do
  begin
    if EsAtributoTalla(Atribs[i]) then
    begin
      AOrdenTalla := i;
      // Pivote = conjunto asignado al articulo; fallback: el conjunto
      // global mas pequenyo que cubre las tallas de sus SKUs.
      AAcTalla := Atribs[i].IdConjunto;
      if AAcTalla = 0 then
      begin
        Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        AAcTalla := BuscarConjuntoParaAvs(Avs);
      end;
    end
    else
    begin
      sAvNuevo := '';
      // Prioridad 1: el valor vino en el SKU leido.
      if (i <= High(APartes)) and (Trim(APartes[i]) <> '') then
        sAvNuevo := Trim(APartes[i])
      else
      begin
        // Prioridad 2: unico valor posible se fija solo; si hay
        // varios y no vamos en silencio, paleta de swatches.
        Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        if Length(Avs) = 1 then
          sAvNuevo := Avs[0].Valor
        else if (Length(Avs) > 1) and (not ASilencioso) then
        begin
          SetLength(AvsStr, Length(Avs));
          for j := 0 to High(Avs) do
            AvsStr[j] := Avs[j].Valor;
          sIdVa := '';
          Mapa := ObtenerMapaAtributosGlobal;
          if Mapa <> nil then
            Mapa.TryGetValue(UpperCase(Trim(Atribs[i].NombreAtributo)),
                             sIdVa);
          if not SeleccionarAvConPaleta(sIdVa, AvsStr, '', sAvNuevo,
                                        -1, -1, 160) then
            sAvNuevo := '';
        end;
      end;
      if i < 5 then
      begin
        AVal[i + 1] := sAvNuevo;
        ANom[i + 1] := Atribs[i].NombreAtributo;
      end;
    end;
  end;
end;

procedure TModoEntradaTallas.EscribirAtributosLinea(const AVal,
  ANom: TValoresAttrTallas; AAcTalla: Integer);
var
  i, iAncho: Integer;
begin
  for i := 1 to 5 do
  begin
    PonerCampo(FConfig.Campos.AttrValor[i], AVal[i]);
    PonerCampo(FConfig.Campos.AttrNombre[i], ANom[i]);
    if (FColAtributo[i] <> nil) and (ANom[i] <> '') then
    begin
      FColAtributo[i].Caption := ANom[i];
      FColAtributo[i].Visible := True;
      // Ancho SOLO creciente para que el valor quepa con su swatch.
      // BestFit no sirve aqui: mide sin el cuadrado del custom draw
      // y con el grid a medio pintar ENCOGE la columna. 44 = swatch
      // (18) + separacion (6) + margenes de celda (10) + aire (10).
      iAncho := cxTextWidth(TcxGrid(FConfig.View.Control).Font,
                            AVal[i]) + 44;
      if FColAtributo[i].Width < iAncho then
        FColAtributo[i].Width := iAncho;
    end;
  end;
  if FConfig.Cds.FindField(FCfgTallas.FieldConjuntoPivot) <> nil then
    FConfig.Cds.FieldByName(FCfgTallas.FieldConjuntoPivot).AsInteger :=
      AAcTalla;
end;

function TModoEntradaTallas.LocalizarLineaExistente(const ACodArt,
  AAlm: string; const AVal: TValoresAttrTallas): Boolean;
var
  sCampos: string;
  vVals: Variant;
  i, n: Integer;
begin
  // Clave de consolidacion: articulo + almacen de la linea + valores
  // de atributos no talla. En DISTRIBUIDO el almacen NO forma parte
  // de la clave: la linea es unica por articulo+color y el reparto
  // por almacen vive en las celdas (modelo sesiones).
  sCampos := FConfig.Campos.CodigoArt;
  n := 1;
  if (FConfig.Campos.Almacen <> '') and
     (not FConfig.Distribuido) then
    Inc(n);
  for i := 1 to 5 do
    if FConfig.Campos.AttrValor[i] <> '' then
      Inc(n);
  vVals := VarArrayCreate([0, n - 1], varVariant);
  vVals[0] := ACodArt;
  n := 1;
  if (FConfig.Campos.Almacen <> '') and
     (not FConfig.Distribuido) then
  begin
    sCampos := sCampos + ';' + FConfig.Campos.Almacen;
    vVals[n] := AAlm;
    Inc(n);
  end;
  for i := 1 to 5 do
    if FConfig.Campos.AttrValor[i] <> '' then
    begin
      sCampos := sCampos + ';' + FConfig.Campos.AttrValor[i];
      vVals[n] := AVal[i];
      Inc(n);
    end;
  Result := FConfig.Cds.Locate(sCampos, vVals, []);
end;

function TModoEntradaTallas.IdAvDeTalla(const ACodArt: string;
  AOrdenTalla: Integer; const AValor: string): Integer;
var
  Avs: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  Result := 0;
  if (AOrdenTalla >= 0) and (AValor <> '') then
  begin
    Avs := FLookup.ObtenerAvsEnSkus(ACodArt, AOrdenTalla + 1);
    for i := 0 to High(Avs) do
      if SameText(Avs[i].Valor, AValor) then
        Result := Avs[i].IdValor;
  end;
end;

procedure TModoEntradaTallas.SumarEnCelda(ALinea, AIdAv: Integer;
  ACant: Double; const AAlm: string; ARefrescar: Boolean);
var
  Qry: TUniQuery;
  dsM: TDataSet;
  idxRec: Integer;
begin
  LogSes(Format('ModoTallas.SumarEnCelda: linea=%d idAv=%d alm="%s" +%g',
                [ALinea, AIdAv, AAlm, ACant]));
  if (ALinea > 0) and (AIdAv > 0) and (FGestor <> nil) then
  begin
    // Upsert ATOMICO (cantidad = cantidad + :c), respetando el almacen
    // de la celda cuando el documento lo usa (formato distribuido).
    dsM := FCfgTallas.SourceMaster.DataSet;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConfig.Conexion;
      if FCfgTallas.FieldAlmacenCel <> '' then
      begin
        Qry.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          FCfgTallas.FieldNumeroCel + ', ' +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAlmacenCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, :n, :l, :f, :a, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
        Qry.ParamByName('a').AsString := AAlm;
      end
      else
        Qry.SQL.Text :=
          'INSERT INTO ' + FCfgTallas.TablaCeldas + ' (' +
          FCfgTallas.FieldSerieCel + ', ' +
          FCfgTallas.FieldNumeroCel + ', ' +
          FCfgTallas.FieldLineaCel + ', ' +
          FCfgTallas.FieldFilaCel + ', ' +
          FCfgTallas.FieldAvPivotCel + ', ' +
          FCfgTallas.FieldCantidadCel + ',' +
          ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
          ' USUARIO_MODIF)' +
          ' VALUES (:s, :n, :l, :f, :p, :c,' +
          ' NOW(), :u, NOW(), :u)' +
          ' ON DUPLICATE KEY UPDATE ' +
          FCfgTallas.FieldCantidadCel + ' = ' +
          FCfgTallas.FieldCantidadCel + ' + :c,' +
          ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      Qry.ParamByName('s').AsString :=
        dsM.FieldByName(FCfgTallas.FieldSerieMaster).AsString;
      Qry.ParamByName('n').AsString :=
        dsM.FieldByName(FCfgTallas.FieldNumeroMaster).AsString;
      Qry.ParamByName('l').AsInteger := ALinea;
      Qry.ParamByName('f').AsInteger := FCfgTallas.IdFilaFijo;
      Qry.ParamByName('p').AsInteger := AIdAv;
      Qry.ParamByName('c').AsFloat := ACant;
      Qry.ParamByName('u').AsString := FCfgTallas.Usuario;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
    if ARefrescar then
    begin
      idxRec := FCfgTallas.Grid.Controller.FocusedRecordIndex;
      if idxRec >= 0 then
        FGestor.CargarCantidadesUnaLinea(idxRec, ALinea);
      FGestor.RefrescarTotalesLineaActual;
    end;
  end;
end;

procedure TModoEntradaTallas.RederivarLineasExistentes;
var
  ds: TDataSet;
  Dict: TDictionary<string, Integer>;
  Val, Nom: TValoresAttrTallas;
  Partes: TArray<string>;
  sArt, sSku, sTallaVal, sClave, sAlmLin, sAlmCel: string;
  iAc, iOrdT, idAv, iLinea, iLineaMaster, i, iPos: Integer;
  rCant: Double;
  CampoCant: TField;
  EvBorrado: TDataSetNotifyEvent;
  bBorrada: Boolean;
begin
  ds := FConfig.Cds;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
  begin
    Dict := TDictionary<string, Integer>.Create;
    ds.DisableControls;
    try
      // Recorrido por RecNo, NO con while-not-Eof: al borrar el ULTIMO
      // registro el cursor cae en el anterior (no en Eof) y el bucle
      // reprocesaria lineas ya vistas, que estarian en el diccionario
      // como maestras de si mismas y se borrarian como "duplicadas"
      // (borrado total del documento).
      iPos := 1;
      while iPos <= ds.RecordCount do
      begin
        ds.RecNo := iPos;
        bBorrada := False;
        sArt := Trim(ds.FieldByName(FConfig.Campos.CodigoArt).AsString);
        if sArt <> '' then
        begin
          // Valores heredados: SKU con talla + CANTIDAD del otro modo.
          sSku :=
            Trim(ds.FieldByName(FConfig.Campos.CodigoUnidad).AsString);
          Partes := PartesDeSku(sArt, sSku);
          // Silencioso: sin paleta durante la conversion masiva.
          CalcularAtributosLinea(sArt, Partes, True, Val, Nom,
                                 iAc, iOrdT);
          sTallaVal := '';
          if (iOrdT >= 0) and (iOrdT <= High(Partes)) then
            sTallaVal := Trim(Partes[iOrdT]);
          idAv := IdAvDeTalla(sArt, iOrdT, sTallaVal);
          rCant := 0;
          CampoCant := ds.FindField(FConfig.Campos.Cantidad);
          if CampoCant <> nil then
            rCant := CampoCant.AsFloat;
          // Almacen EFECTIVO de la linea (fallback de cabecera, como
          // albaranes): las lineas sin almacen asumen el del documento
          // y asi fusionan con las que ya lo llevan puesto.
          sAlmLin := '';
          if (FConfig.Campos.Almacen <> '') and
             (ds.FindField(FConfig.Campos.Almacen) <> nil) then
          begin
            sAlmLin := Trim(
              ds.FieldByName(FConfig.Campos.Almacen).AsString);
            if sAlmLin = '' then
              sAlmLin := Trim(FConfig.AlmacenStock);
          end;
          // En DISTRIBUIDO el almacen vive en las CELDAS (modelo
          // sesiones): la linea es unica por articulo+color y las
          // lineas por almacen FUSIONAN, yendo cada cantidad a la
          // celda de su almacen. Sin distribuido, una linea por
          // almacen (modelo albaranes).
          if FConfig.Distribuido then
            sClave := sArt + '|'
          else
            sClave := sArt + '|' + UpperCase(sAlmLin);
          for i := 1 to 5 do
            sClave := sClave + '|' + UpperCase(Val[i]);
          // Destino de las cantidades heredadas: en distribuido, el
          // almacen efectivo de la linea; si no, celda sin almacen.
          if FConfig.Distribuido then
            sAlmCel := sAlmLin
          else
            sAlmCel := '';
          if Dict.TryGetValue(sClave, iLineaMaster) then
          begin
            // Duplicada (mismo articulo+color): su cantidad se vuelca
            // a la celda de talla de la linea maestra y se elimina.
            if (idAv > 0) and (rCant > 0) then
              SumarEnCelda(iLineaMaster, idAv, rCant, sAlmCel,
                           False);
            LogSes(Format('ModoTallas.Rederivar: BORRA linea=%d ' +
                   '(dup de %d) art=%s clave=%s',
                   [ds.FieldByName(FCfgTallas.FieldLinea).AsInteger,
                    iLineaMaster, sArt, sClave]));
            // Borrado PROGRAMATICO de la fusion: sin el guardian de
            // confirmacion que TfrmMtoGen engancha en BeforeDelete del
            // dataset principal (preguntaria al usuario por cada
            // duplicada durante Construir).
            EvBorrado := ds.BeforeDelete;
            ds.BeforeDelete := nil;
            try
              ds.Delete;
            finally
              ds.BeforeDelete := EvBorrado;
            end;
            bBorrada := True;
          end
          else
          begin
            iLinea :=
              ds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
            Dict.Add(sClave, iLinea);
            LogSes(Format('ModoTallas.Rederivar: MASTER linea=%d ' +
                   'art=%s clave=%s', [iLinea, sArt, sClave]));
            if not (ds.State in [dsEdit, dsInsert]) then
              ds.Edit;
            // Persistir el almacen efectivo en la linea (el fallback
            // de cabecera deja de ser implicito). En distribuido la
            // linea es multi-almacen: queda el del documento.
            if FConfig.Distribuido then
              PonerCampo(FConfig.Campos.Almacen,
                         Trim(FConfig.AlmacenStock))
            else
              PonerCampo(FConfig.Campos.Almacen, sAlmLin);
            EscribirAtributosLinea(Val, Nom, iAc);
            // La cantidad del SKU con talla pasa a su celda; la
            // columna Cantidad queda para lineas sin tallas.
            if (idAv > 0) and (rCant > 0) and (CampoCant <> nil) then
              CampoCant.AsFloat := 0;
            ds.Post;
            if (idAv > 0) and (rCant > 0) then
              SumarEnCelda(iLinea, idAv, rCant, sAlmCel, False);
          end;
        end;
        // Tras un Delete NO se avanza: el registro iPos ya es otro.
        if not bBorrada then
          Inc(iPos);
      end;
      ds.First;
    finally
      FreeAndNil(Dict);
      ds.EnableControls;
    end;
  end;
end;

procedure TModoEntradaTallas.MostrarEditor;
begin
  if (FConfig.View <> nil) and (FColArticulo <> nil) then
  begin
    FColArticulo.Focused := True;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        ;
    end;
  end;
end;

function TModoEntradaTallas.ResolverEntrada(
  const AEntrada: string): Boolean;
var
  Val: TArticulosValidador;
  R: TArtResolucionEntrada;
  Vals, Noms: TValoresAttrTallas;
  Partes: TArray<string>;
  sTallaVal, sAlm: string;
  iAcTalla, iOrdT, idAv, iLinea: Integer;
begin
  Result := False;
  FUltimaConTalla := False;
  if Trim(AEntrada) <> '' then
  begin
    Val := TArticulosValidador.Create(FConfig.Conexion);
    try
      R := Val.Resolver(Trim(AEntrada));
    finally
      FreeAndNil(Val);
    end;
    LogSes(Format('ModoTallas.Resolver: "%s" encontrado=%s sku="%s"',
                  [Trim(AEntrada), BoolToStr(R.Encontrado, True),
                   R.CodigoSku]));
    if R.Encontrado then
    begin
      // Si la entrada trajo un SKU cerrado (barras / SKU completo),
      // sus valores mandan: color de la linea y talla de la celda.
      Partes := PartesDeSku(R.CodigoArticulo, R.CodigoSku);
      CalcularAtributosLinea(R.CodigoArticulo, Partes, False,
                             Vals, Noms, iAcTalla, iOrdT);
      sTallaVal := '';
      if (iOrdT >= 0) and (iOrdT <= High(Partes)) then
        sTallaVal := Trim(Partes[iOrdT]);
      LogSes(Format(
        'ModoTallas.Resolver: pivote=%d ordTalla=%d talla="%s"',
        [iAcTalla, iOrdT, sTallaVal]));
      // Almacen destino = el de la linea donde se tecleo (default: el
      // del documento, puesto al crear la linea en blanco). Se captura
      // ANTES del Cancel, que descartaria un cambio a medio editar.
      sAlm := '';
      if (FConfig.Campos.Almacen <> '') and
         (FConfig.Cds.FindField(FConfig.Campos.Almacen) <> nil) then
      begin
        sAlm := Trim(FConfig.Cds.FieldByName(
                  FConfig.Campos.Almacen).AsString);
        // Fallback de cabecera (como albaranes de compra): la linea
        // sin almacen asume el almacen por defecto del documento.
        if sAlm = '' then
          sAlm := Trim(FConfig.AlmacenStock);
      end;
      // CONSOLIDACION: una linea por articulo+almacen+atributos no
      // talla. La fila donde se tecleo (normalmente la vacia) se
      // descarta si ya existe linea para esa combinacion.
      if FConfig.Cds.State in [dsEdit, dsInsert] then
        FConfig.Cds.Cancel;
      if LocalizarLineaExistente(R.CodigoArticulo, sAlm, Vals) then
        LogSes(Format('ModoTallas.Resolver: consolidada en linea %d ' +
               'alm="%s"',
               [FConfig.Cds.FieldByName(
                  FCfgTallas.FieldLinea).AsInteger, sAlm]))
      else
      begin
        LogSes('ModoTallas.Resolver: linea nueva alm="' + sAlm + '"');
        FConfig.Cds.Edit;
        PonerCampo(FConfig.Campos.CodigoArt, R.CodigoArticulo);
        PonerCampo(FConfig.Campos.Descripcion, R.DescripcionArticulo);
        PonerCampo(FConfig.Campos.Almacen, sAlm);
        EscribirAtributosLinea(Vals, Noms, iAcTalla);
      end;
      if FConfig.Cds.State in [dsEdit, dsInsert] then
        FConfig.Cds.Post;
      // Lectura con talla: +1 en la celda de esa talla (como caja).
      // En formato distribuido NO se suma en linea: el reparto por
      // almacen entra por el distribuidor (como sesiones).
      if sTallaVal <> '' then
      begin
        if FConfig.Distribuido then
          LogSes('ModoTallas.Resolver: distribuido, cantidades via ' +
                 'distribuidor')
        else
        begin
          idAv := IdAvDeTalla(R.CodigoArticulo, iOrdT, sTallaVal);
          iLinea :=
            FConfig.Cds.FieldByName(FCfgTallas.FieldLinea).AsInteger;
          if idAv > 0 then
          begin
            SumarEnCelda(iLinea, idAv, 1, '', True);
            FUltimaConTalla := True;
          end;
        end;
      end;
      // Tope de tallas (20): si el sistema excede MaxColumnas el
      // gestor avisa y limpia el pivot (no pasa a horizontal).
      if FGestor <> nil then
      begin
        if FGestor.ValidarSistemaSeleccionado then
        begin
          FGestor.RecalcularMaxColumnas;
          FGestor.ActualizarCaptionsLineaActiva;
        end;
      end;
      if Assigned(FOnResuelto) then
      begin
        if R.CodigoSku <> '' then
          FOnResuelto(R.CodigoArticulo, R.CodigoSku,
                      R.DescripcionArticulo, True)
        else
          FOnResuelto(R.CodigoArticulo, R.CodigoArticulo,
                      R.DescripcionArticulo, True);
      end;
      Result := True;
    end
    else
      // Feedback como el desglose: sin aviso parecia que el Enter no
      // hacia nada cuando la entrada no existe (SKU no dado de alta).
      ShowMessage('Artículo/SKU no encontrado: ' + Trim(AEntrada));
  end;
end;

end.
