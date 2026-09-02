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
{    resolucion via inLibArticulosValidadorIntf, valores via              }
{    inLibArticulosAtributosIntf, generacion del SKU y consolidacion.     }
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
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Types,
  System.StrUtils, System.Generics.Collections, Data.DB, Uni, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, cxGraphics,
  cxEdit, cxTextEdit, cxButtonEdit, cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibArticulosValidadorIntf, inLibArticulosAtributosIntf,
  inLibAtributosPaleta,
  inLibContextoSesionIntf, inLibGenBusq, inLibLogIntf,
  inLibModoTallasIntf, inLibGridArticulosPersistenciaIntf,
  inLibGridArticulosBusqueda;

function MaximoAtributosVisiblesGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  AMinimoAtributos: Integer = 0): Integer;
procedure SincronizarVisibilidadAtributosGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  const AColumnasAtributo: array of TcxGridDBColumn;
  AMinimoAtributos: Integer = 0;
  AMaximoAtributos: Integer = 5);

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
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    FView: TcxGridDBTableView;
    FCds: TDataSet;
    FCampos: TCamposGridArt;
    FColArticulo: TcxGridDBColumn;
    FColNumeroAtributos: TcxGridDBColumn;
    FColAtributo: array[1..5] of TcxGridDBColumn;
    FValidador: IArticulosValidador;
    FLookup: IArticulosAtributosLookup;
    FBusqueda: TBusquedaGridArticulos;
    FOnResuelto: TArtResueltoEvent;
    // Aviso al host al entrar/salir de un editor in-place del grid.
    // Pensados para Desactivar/RestaurarEnterAsTabTemporal (TfrmBase):
    // sin esto el TJvEnterAsTab convierte el Enter en Tab y no llega ni
    // a la celda de articulo ni a los combos de atributo.
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    // Timer single-shot para abrir la paleta al entrar en una celda de
    // atributo vacia (listbox incrustado, como la caja). Diferimos la
    // apertura fuera del OnEnter: el editor in-place del cxGrid aun no ha
    // terminado de parentar y ClientToScreen lanzaria EInvalidOperation.
    FTimerPopup: TTimer;
    FTimerVisibilidad: TTimer;
    FOrdenPopupPend: Integer;
    FMaximoAtributosVisibles: Integer;
    // True mientras AbrirPaletaOrden esta mostrando el editor/paleta, para que
    // el OnEnter del editor (AtributoEnter) no reprograme otra apertura.
    FEnPaleta: Boolean;
    // Almacen cuyo stock se muestra en el buscador de SKU (lo fija el host;
    // en traspaso, el almacen origen). Vacio = no muestra stock.
    FAlmacenStock: string;
    // El documento admite lineas de articulos fuera del catalogo: una
    // entrada no encontrada se acepta como codigo libre (sin SKU, sin
    // atributos, no mueve stock) en vez de descartarse. Lo activan las
    // facturas de venta mayor; caja y traspasos lo dejan a False.
    FAceptarNoCatalogo: Boolean;
    FAfterOpenOriginal: TDataSetNotifyEvent;
    FAfterPostOriginal: TDataSetNotifyEvent;
    FAfterScrollOriginal: TDataSetNotifyEvent;
    FAfterDeleteOriginal: TDataSetNotifyEvent;
    FAfterCancelOriginal: TDataSetNotifyEvent;
    FAfterRefreshOriginal: TDataSetNotifyEvent;
    FEventosDataSetInstalados: Boolean;
    // OnExit de los editores in-place: reenvia a FOnSalirEdicion.
    procedure EditorSalir(Sender: TObject);
    // Restaura el EnterAsTab al SALIR de las columnas de la
    // controladora: el OnExit del editor in-place no es fiable con
    // AlwaysShowEditor (el host del banco de pruebas lo usa).
    procedure ViewFocusedItemChanged(Sender: TcxCustomGridTableView;
                                     APrevFocusedItem,
                                  AFocusedItem: TcxCustomGridTableItem);
    procedure SetAlmacenStock(const AValue: string);
    procedure SetMaximoAtributosVisibles(AValue: Integer);
    // Si el documento YA tiene una linea con ese SKU cerrado, suma 1
    // a su cantidad y devuelve True (la lectura queda consumida sin
    // crear otra linea igual). La linea en blanco no casa porque su
    // CODIGO_UNIDAD esta vacio.
    function AcumularLineaExistente(const ACodArt, ASku,
                                    ADesc: string): Boolean;
    procedure CrearColumnaArticulo;
    procedure CrearColumnaNumeroAtributos;
    procedure CrearColumnasAtributo;
    procedure RefrescarVisibilidadAtributos(
      AMinimoAtributos: Integer = 0);
    procedure ArmarRefrescoVisibilidad;
    procedure TimerVisibilidadTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure DataSetAfterOpen(DataSet: TDataSet);
    procedure DataSetAfterPost(DataSet: TDataSet);
    procedure DataSetAfterScroll(DataSet: TDataSet);
    procedure DataSetAfterDelete(DataSet: TDataSet);
    procedure DataSetAfterCancel(DataSet: TDataSet);
    procedure DataSetAfterRefresh(DataSet: TDataSet);
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
    // Tras elegir un atributo, si quedan atributos sin rellenar enfoca el
    // siguiente y abre su paleta (no deja pasar a la siguiente fila con el
    // SKU a medias). Devuelve True si quedaba alguno pendiente.
    function AvanzarSiguienteAtributo: Boolean;
    // True si la linea actual aun tiene color/talla por elegir (NUM_ATRIBUTOS
    // > 0 y algun ATTRn_VALOR vacio).
    // Tras resolver un articulo decide el foco como la caja: si faltan
    // atributos salta al primero y abre su paleta; si el SKU ya esta cerrado
    // deja el editor de articulo listo para la siguiente entrada.
    procedure AvanzarTrasResolver;
    procedure DespuesResolverBusqueda;
    procedure AplicarSkuYAvisar;
    function ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
    function GenerarSku: string;
    procedure ActualizarColumnasAtributo(const ACodArt: string);
    procedure AutoCompletarAtributosUnicos(const ACodArt: string);
    procedure RellenarAtributosDesdeSku(const ACodArt, ASku: string);
    function CdsEditando: Boolean;
    procedure LogSes(const ATexto: string);
  public
    constructor Create(AConn: TUniConnection;
      AView: TcxGridDBTableView; ACds: TDataSet;
      const ACampos: TCamposGridArt;
      const AContextoSesion: IContextoSesionAplicacion;
      const ABusquedaVisual: IBusquedaVisual;
      const ABusquedaSkus: IBusquedaSkusTallas;
      const AConsultaArticulos: IConsultaArticulosGrid;
      const AValidador: IArticulosValidador = nil;
      const ALookup: IArticulosAtributosLookup = nil;
      const ARegistroLog: IRegistroLog = nil);
    destructor Destroy; override;
    // Crea la columna de articulo + las 5 columnas de atributo y engancha el
    // OnInitEdit del View. El host anade sus columnas DESPUES sobre el View.
    procedure Construir;
    // Desengancha eventos y temporizadores antes de que el host destruya las
    // columnas con ClearItems. Es idempotente y el modo no se reutiliza.
    procedure Desmontar;
    // Deja el editor de la celda de articulo ABIERTO, listo para teclear o
    // escanear. Imprescindible para el lector: si la celda no esta ya en
    // edicion, la primera tecla abre el editor y las siguientes (muy rapidas)
    // se pierden -> solo se leeria la primera cifra.
    procedure MostrarEditorArticulo;
    // Resuelve una entrada (codigo de articulo, SKU, codigo de barras o ref
    // de proveedor) y rellena la linea. Devuelve False si no se encontro.
    function ResolverEntrada(const AEntrada: string): Boolean;
    // F3 contextual del host: abre la busqueda completa en Articulo o la
    // paleta si el foco esta en una columna de Color/Talla.
    procedure BuscarContextual;
    // Hace visibles las columnas de color/talla de un articulo ya cargado.
    procedure MostrarColumnasAtributosArticulo(const ACodArt: string);
    property OnResuelto: TArtResueltoEvent read FOnResuelto write FOnResuelto;
    // Entrada/salida de edicion in-place (ver comentario de los campos).
    property OnEntrarEdicion: TNotifyEvent read FOnEntrarEdicion
                                           write FOnEntrarEdicion;
    property OnSalirEdicion: TNotifyEvent read FOnSalirEdicion
                                          write FOnSalirEdicion;
    // Almacen para la columna de stock del buscador de SKU (origen). Al
    // cambiarlo se recarga el desplegable de busqueda incremental.
    property AlmacenStock: string read FAlmacenStock write SetAlmacenStock;
    // Admitir codigos fuera de catalogo como linea libre (ver campo).
    property AceptarNoCatalogo: Boolean read FAceptarNoCatalogo
                                        write FAceptarNoCatalogo;
    // Permite que una pantalla limite la presentacion sin alterar el SKU.
    property MaximoAtributosVisibles: Integer
      read FMaximoAtributosVisibles write SetMaximoAtributosVisibles;
  end;

implementation

uses
  inLibMsgArticulos;

type
  // Acceso a OnExit (protegido en TWinControl) de los editores in-place
  // sin depender de que cada clase cx lo re-publique.
  THackWinCtrl = class(TWinControl);

function MetodosIguales(const AEventoUno,
  AEventoDos: TMethod): Boolean;
begin
  Result := (AEventoUno.Code = AEventoDos.Code) and
            (AEventoUno.Data = AEventoDos.Data);
end;

function EventosDataSetIguales(const AEventoUno,
  AEventoDos: TDataSetNotifyEvent): Boolean;
begin
  Result := MetodosIguales(
    TMethod(AEventoUno), TMethod(AEventoDos));
end;

function MaximoAtributosVisiblesGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  AMinimoAtributos: Integer): Integer;
var
  iAtributos: Integer;
  iRegistro: Integer;
begin
  Result := AMinimoAtributos;
  if Result < 0 then
    Result := 0;
  if Assigned(AVista) and Assigned(AColumnaNumeroAtributos) then
  begin
    for iRegistro := 0 to AVista.DataController.RecordCount - 1 do
    begin
      if TryStrToInt(Trim(VarToStr(
           AVista.DataController.Values[iRegistro,
             AColumnaNumeroAtributos.Index])), iAtributos) and
         (iAtributos > Result) then
        Result := iAtributos;
    end;
  end;
end;

procedure SincronizarVisibilidadAtributosGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  const AColumnasAtributo: array of TcxGridDBColumn;
  AMinimoAtributos: Integer;
  AMaximoAtributos: Integer);
var
  iColumna: Integer;
  iMaximo: Integer;
begin
  if Assigned(AVista) then
  begin
    iMaximo := MaximoAtributosVisiblesGrid(
      AVista, AColumnaNumeroAtributos, AMinimoAtributos);
    if AMaximoAtributos < 0 then
      iMaximo := 0
    else if iMaximo > AMaximoAtributos then
      iMaximo := AMaximoAtributos;
    AVista.BeginUpdate;
    try
      for iColumna := Low(AColumnasAtributo) to
        High(AColumnasAtributo) do
        if Assigned(AColumnasAtributo[iColumna]) then
          AColumnasAtributo[iColumna].Visible :=
            iColumna - Low(AColumnasAtributo) + 1 <= iMaximo;
    finally
      AVista.EndUpdate;
    end;
  end;
end;

constructor TGridArticulosLineas.Create(
  AConn: TUniConnection; AView: TcxGridDBTableView;
  ACds: TDataSet;
  const ACampos: TCamposGridArt;
  const AContextoSesion: IContextoSesionAplicacion;
  const ABusquedaVisual: IBusquedaVisual;
  const ABusquedaSkus: IBusquedaSkusTallas;
  const AConsultaArticulos: IConsultaArticulosGrid;
  const AValidador: IArticulosValidador;
  const ALookup: IArticulosAtributosLookup;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FConn := AConn;
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
  FView := AView;
  FCds := ACds;
  FCampos := ACampos;
  FValidador := AValidador;
  if not Assigned(FValidador) then
    raise Exception.Create(SErrorValidadorArticulosNoInyectado);
  FLookup := ALookup;
  if not Assigned(FLookup) then
    raise Exception.Create(SErrorLookupAtributosNoInyectado);
  FOrdenPopupPend := 0;
  FMaximoAtributosVisibles := 5;
  FTimerPopup := TTimer.Create(nil);
  FTimerPopup.Enabled := False;
  FTimerPopup.Interval := 1;
  FTimerPopup.OnTimer := TimerPopupTimer;
  FTimerVisibilidad := TTimer.Create(nil);
  FTimerVisibilidad.Enabled := False;
  FTimerVisibilidad.Interval := 1;
  FTimerVisibilidad.OnTimer := TimerVisibilidadTimer;
  FBusqueda := TBusquedaGridArticulos.Create(
    FView, FCds, FCampos.CodigoArt, ABusquedaVisual,
    ABusquedaSkus, AConsultaArticulos, FRegistroLog,
    ResolverEntrada, DespuesResolverBusqueda,
    AbrirPaletaOrden, LogSes);
end;

procedure TGridArticulosLineas.LogSes(const ATexto: string);
begin
  if Assigned(FContextoSesion) then
    FContextoSesion.LogSesion(ATexto);
end;

destructor TGridArticulosLineas.Destroy;
begin
  Desmontar;
  FreeAndNil(FTimerVisibilidad);
  FreeAndNil(FTimerPopup);
  FValidador := nil;
  FLookup := nil;
  inherited;
end;

function TGridArticulosLineas.CdsEditando: Boolean;
begin
  Result := FCds.Active and (FCds.State in [dsEdit, dsInsert]);
end;

procedure TGridArticulosLineas.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TGridArticulosLineas.ViewFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo permanece desactivado mientras el foco esta en
  // una columna de la controladora (articulo o atributos).
  if (APrevFocusedItem <> nil) and
     ((APrevFocusedItem = FColArticulo) or
      ((APrevFocusedItem.Tag >= 1) and
       (APrevFocusedItem.Tag <= 5))) and
     Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TGridArticulosLineas.ArmarRefrescoVisibilidad;
begin
  if Assigned(FTimerVisibilidad) then
  begin
    FTimerVisibilidad.Enabled := False;
    FTimerVisibilidad.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.TimerVisibilidadTimer(Sender: TObject);
begin
  FTimerVisibilidad.Enabled := False;
  RefrescarVisibilidadAtributos;
end;

procedure TGridArticulosLineas.DataSetAfterOpen(DataSet: TDataSet);
begin
  if Assigned(FAfterOpenOriginal) then
    FAfterOpenOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterPost(DataSet: TDataSet);
begin
  if Assigned(FAfterPostOriginal) then
    FAfterPostOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FAfterScrollOriginal) then
    FAfterScrollOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterDelete(DataSet: TDataSet);
begin
  if Assigned(FAfterDeleteOriginal) then
    FAfterDeleteOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterCancel(DataSet: TDataSet);
begin
  if Assigned(FAfterCancelOriginal) then
    FAfterCancelOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterRefresh(DataSet: TDataSet);
begin
  if Assigned(FAfterRefreshOriginal) then
    FAfterRefreshOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.InstalarEventosDataSet;
begin
  if Assigned(FCds) and not FEventosDataSetInstalados then
  begin
    FAfterOpenOriginal := FCds.AfterOpen;
    FAfterPostOriginal := FCds.AfterPost;
    FAfterScrollOriginal := FCds.AfterScroll;
    FAfterDeleteOriginal := FCds.AfterDelete;
    FAfterCancelOriginal := FCds.AfterCancel;
    FAfterRefreshOriginal := FCds.AfterRefresh;
    FCds.AfterOpen := DataSetAfterOpen;
    FCds.AfterPost := DataSetAfterPost;
    FCds.AfterScroll := DataSetAfterScroll;
    FCds.AfterDelete := DataSetAfterDelete;
    FCds.AfterCancel := DataSetAfterCancel;
    FCds.AfterRefresh := DataSetAfterRefresh;
    FEventosDataSetInstalados := True;
  end;
end;

procedure TGridArticulosLineas.RestaurarEventosDataSet;
var
  oEvento: TDataSetNotifyEvent;
begin
  if Assigned(FCds) and FEventosDataSetInstalados then
  begin
    oEvento := DataSetAfterOpen;
    if EventosDataSetIguales(FCds.AfterOpen, oEvento) then
      FCds.AfterOpen := FAfterOpenOriginal;
    oEvento := DataSetAfterPost;
    if EventosDataSetIguales(FCds.AfterPost, oEvento) then
      FCds.AfterPost := FAfterPostOriginal;
    oEvento := DataSetAfterScroll;
    if EventosDataSetIguales(FCds.AfterScroll, oEvento) then
      FCds.AfterScroll := FAfterScrollOriginal;
    oEvento := DataSetAfterDelete;
    if EventosDataSetIguales(FCds.AfterDelete, oEvento) then
      FCds.AfterDelete := FAfterDeleteOriginal;
    oEvento := DataSetAfterCancel;
    if EventosDataSetIguales(FCds.AfterCancel, oEvento) then
      FCds.AfterCancel := FAfterCancelOriginal;
    oEvento := DataSetAfterRefresh;
    if EventosDataSetIguales(FCds.AfterRefresh, oEvento) then
      FCds.AfterRefresh := FAfterRefreshOriginal;
    FAfterOpenOriginal := nil;
    FAfterPostOriginal := nil;
    FAfterScrollOriginal := nil;
    FAfterDeleteOriginal := nil;
    FAfterCancelOriginal := nil;
    FAfterRefreshOriginal := nil;
    FEventosDataSetInstalados := False;
  end;
end;

procedure TGridArticulosLineas.Desmontar;
var
  iAtributo: Integer;
  oEditKeyDown: TcxGridEditKeyEvent;
  oFocusedItemChanged: TcxGridFocusedItemChangedEvent;
  oGetProperties: TcxGridGetPropertiesEvent;
  oInitEdit: TcxGridInitEditEvent;
begin
  if Assigned(FTimerPopup) then
    FTimerPopup.Enabled := False;
  if Assigned(FTimerVisibilidad) then
    FTimerVisibilidad.Enabled := False;
  FOrdenPopupPend := 0;
  if Assigned(FView) then
  begin
    if Assigned(FView.Controller.EditingController) and
       FView.Controller.EditingController.IsEditing then
    begin
      try
        FView.Controller.EditingController.HideEdit(False);
      except
        on E: Exception do
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarAviso(
              'GridArticulos.Desmontar: HideEdit ignorado: ' +
              E.Message);
      end;
    end;
    oInitEdit := ViewInitEdit;
    if MetodosIguales(
         TMethod(FView.OnInitEdit), TMethod(oInitEdit)) then
      FView.OnInitEdit := nil;
    oFocusedItemChanged := ViewFocusedItemChanged;
    if MetodosIguales(TMethod(FView.OnFocusedItemChanged),
         TMethod(oFocusedItemChanged)) then
      FView.OnFocusedItemChanged := nil;
    if Assigned(FBusqueda) then
    begin
      oEditKeyDown := FBusqueda.ViewEditKeyDown;
      if MetodosIguales(TMethod(FView.OnEditKeyDown),
           TMethod(oEditKeyDown)) then
        FView.OnEditKeyDown := nil;
    end;
  end;
  if Assigned(FColArticulo) then
  begin
    if Assigned(FBusqueda) then
    begin
      oGetProperties := FBusqueda.ArticuloGetProperties;
      if MetodosIguales(TMethod(FColArticulo.OnGetProperties),
           TMethod(oGetProperties)) then
        FColArticulo.OnGetProperties := nil;
    end;
    if FColArticulo.Properties is TcxButtonEditProperties then
    begin
      TcxButtonEditProperties(
        FColArticulo.Properties).OnButtonClick := nil;
      TcxButtonEditProperties(
        FColArticulo.Properties).OnValidate := nil;
    end;
  end;
  for iAtributo := Low(FColAtributo) to High(FColAtributo) do
  begin
    if Assigned(FColAtributo[iAtributo]) then
    begin
      FColAtributo[iAtributo].OnCustomDrawCell := nil;
      if FColAtributo[iAtributo].Properties is
         TcxButtonEditProperties then
        TcxButtonEditProperties(
          FColAtributo[iAtributo].Properties).OnButtonClick := nil;
    end;
  end;
  RestaurarEventosDataSet;
  FreeAndNil(FBusqueda);
  FColArticulo := nil;
  FColNumeroAtributos := nil;
  for iAtributo := Low(FColAtributo) to High(FColAtributo) do
    FColAtributo[iAtributo] := nil;
  FCds := nil;
  FView := nil;
  FOnResuelto := nil;
  FOnEntrarEdicion := nil;
  FOnSalirEdicion := nil;
end;

procedure TGridArticulosLineas.RefrescarVisibilidadAtributos(
  AMinimoAtributos: Integer);
begin
  SincronizarVisibilidadAtributosGrid(
    FView,
    FColNumeroAtributos,
    FColAtributo,
    AMinimoAtributos,
    FMaximoAtributosVisibles);
end;

procedure TGridArticulosLineas.SetMaximoAtributosVisibles(
  AValue: Integer);
begin
  if AValue < 0 then
    FMaximoAtributosVisibles := 0
  else if AValue > 5 then
    FMaximoAtributosVisibles := 5
  else
    FMaximoAtributosVisibles := AValue;
  RefrescarVisibilidadAtributos;
end;

procedure TGridArticulosLineas.Construir;
begin
  FView.BeginUpdate;
  try
    FView.ClearItems;
    CrearColumnaArticulo;
    CrearColumnaNumeroAtributos;
    CrearColumnasAtributo;
  finally
    FView.EndUpdate;
  end;
  RefrescarVisibilidadAtributos;
  InstalarEventosDataSet;
  // Al entrar en una celda de atributo vacia, abre la paleta (listbox de
  // swatches) automaticamente, como la caja. Se engancha en OnInitEdit.
  FView.OnInitEdit := ViewInitEdit;
  // OnEditKeyDown del grid: resuelve el codigo en la celda al pulsar Enter
  // (lector Codigo+CR o tecleo manual). Es el evento fiable para la celda.
  FView.OnEditKeyDown := FBusqueda.ViewEditKeyDown;
  // Restauracion del EnterAsTab al abandonar las columnas propias.
  FView.OnFocusedItemChanged := ViewFocusedItemChanged;
  // Flujo tipo Excel: Enter pasa a la siguiente celda y al llegar al final
  // de la fila salta a la siguiente. NO usamos NewItemRow: la linea nueva se
  // anyade sola al completar un SKU (lo hace el host en OnResuelto).
  FView.OptionsBehavior.GoToNextCellOnEnter := True;
  FView.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  // Mismos parametros de comportamiento/vista que el grid de ventas de
  // inMtoCajaOpe (tvLineasOpe): el ciclo de foco vuelve a la primera celda de
  // la fila siguiente, las columnas reparten el ancho del grid y se muestra un
  // aviso cuando no hay articulos.
  FView.OptionsBehavior.FocusCellOnCycle := True;
  FView.OptionsView.ColumnAutoWidth := True;
  FView.OptionsView.NoDataToDisplayInfoText :=
    SCaptionSinArticulos;
  // Navegador pequeño embebido: navegar + añadir al final + borrar.
  FView.Navigator.Visible := True;
  FView.Navigator.Buttons.First.Visible := True;
  FView.Navigator.Buttons.Prior.Visible := True;
  FView.Navigator.Buttons.Next.Visible := True;
  FView.Navigator.Buttons.Last.Visible := True;
  FView.Navigator.Buttons.Insert.Visible := False;
  FView.Navigator.Buttons.Append.Visible := True;
  FView.Navigator.Buttons.Delete.Visible := True;
  FView.Navigator.Buttons.PriorPage.Visible := False;
  FView.Navigator.Buttons.NextPage.Visible := False;
  FView.Navigator.Buttons.Edit.Visible := False;
  FView.Navigator.Buttons.Post.Visible := False;
  FView.Navigator.Buttons.Cancel.Visible := False;
  FView.Navigator.Buttons.Refresh.Visible := False;
  FView.Navigator.Buttons.SaveBookmark.Visible := False;
  FView.Navigator.Buttons.GotoBookmark.Visible := False;
  FView.Navigator.Buttons.Filter.Visible := False;
end;

procedure TGridArticulosLineas.MostrarColumnasAtributosArticulo(
  const ACodArt: string);
begin
  if Trim(ACodArt) <> '' then
    ActualizarColumnasAtributo(ACodArt);
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
  // Al abrir un editor de las columnas de esta controladora (articulo o
  // atributo), avisa al host para que desactive su EnterAsTab; se
  // restaura via OnExit del editor (EditorSalir).
  if (AItem = FColArticulo) or
     ((AItem <> nil) and (AItem.Tag >= 1) and (AItem.Tag <= 5)) then
  begin
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinCtrl(AEdit).OnExit := EditorSalir;
  end;
  // Celda de articulo: enganchamos OnKeyPress para capturar el lector de
  // codigo de barras (STX...ETX) y resolver al recibir ETX.
  if (AItem = FColArticulo) and (AEdit is TcxCustomTextEdit) then
  begin
    LogSes('GridArt.InitEdit articulo: editor=' + AEdit.ClassName);
    FBusqueda.ConfigurarEditorArticulo(TcxCustomTextEdit(AEdit));
    // Sugerencias en vivo: al teclear se rearma el debounce que abre el
    // desplegable filtrado (igual que inMtoCajaOpe). El lector (STX/ETX)
    // consume sus teclas en ArticuloKeyPress, asi que no dispara el OnChange.
  end
  else if (AItem <> nil) and (AItem.Tag >= 1) and
          (AItem.Tag <= 5) and (AEdit is TcxButtonEdit) then
  begin
    BE := TcxButtonEdit(AEdit);
    BE.Tag := AItem.Tag;
    if (not FCds.Active) or FCds.IsEmpty then
      BE.OnEnter := nil
    else if Trim(
      FCds.FieldByName(FCampos.AttrValor[AItem.Tag]).AsString) = '' then
      BE.OnEnter := AtributoEnter
    else
      BE.OnEnter := nil;
  end;
end;

// OnEnter single-shot de una celda de atributo vacia: difiere la apertura de
// la paleta (timer 1ms) para que el editor in-place termine de parentar.
procedure TGridArticulosLineas.AtributoEnter(Sender: TObject);
begin
  if (Sender is TcxButtonEdit) and not FEnPaleta then
  begin
    TcxButtonEdit(Sender).OnEnter := nil;
    FOrdenPopupPend := TcxButtonEdit(Sender).Tag;
    FTimerPopup.Enabled := False;
    FTimerPopup.Enabled := True;
  end;
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
var
  Propiedades: TcxButtonEditProperties;
  Boton: TcxEditButton;
begin
  FColArticulo := FView.CreateColumn;
  FColArticulo.Caption := SCaptionColArticuloSku;
  FColArticulo.DataBinding.FieldName := FCampos.CodigoArt;
  FColArticulo.Width := 220;
  FColArticulo.PropertiesClass := TcxButtonEditProperties;
  Propiedades := TcxButtonEditProperties(FColArticulo.Properties);
  Propiedades.Buttons.Clear;
  Boton := Propiedades.Buttons.Add;
  Boton.Default := True;
  Boton.Kind := bkEllipsis;
  // Las lineas ya resueltas no se editan encima: se borra la linea o se usa
  // el boton. Las lineas nuevas usan el combo editable por OnGetProperties.
  Propiedades.ReadOnly := True;
  Propiedades.OnValidate := FBusqueda.ArticuloValidate;
  // El boton (ellipsis) abre el buscador de SKU.
  Propiedades.OnButtonClick := FBusqueda.ArticuloButtonClick;
  // Editor por registro: si la celda esta vacia y enfocada, se usa el
  // ExtLookupComboBox con busqueda incremental; si no, el ButtonEdit de
  // arriba. Mismo patron que inMtoCajaOpe.tvArticuloGetProperties.
  FBusqueda.ConfigurarColumna(FColArticulo);
end;

procedure TGridArticulosLineas.SetAlmacenStock(const AValue: string);
begin
  if FAlmacenStock <> AValue then
  begin
    FAlmacenStock := AValue;
    FBusqueda.SetAlmacenStock(AValue);
  end;
end;

procedure TGridArticulosLineas.MostrarEditorArticulo;
begin
  FBusqueda.MostrarEditorArticulo;
end;

procedure TGridArticulosLineas.BuscarContextual;
var
  Columna: TcxGridColumn;
begin
  Columna := FView.Controller.FocusedColumn;
  if Assigned(Columna) and (Columna.Tag >= 1) and
     (Columna.Tag <= 5) then
    AbrirPaletaOrden(Columna.Tag)
  else
    FBusqueda.BuscarArticulo;
end;

// Tras resolver un articulo decide el foco igual que la caja: si la linea aun
// necesita color/talla, salta a la primera columna de atributo pendiente y abre
// su paleta; si el SKU ya quedo cerrado, deja el editor de articulo listo para
// la siguiente entrada.
procedure TGridArticulosLineas.AvanzarTrasResolver;
var
  bPendiente: Boolean;
  iOrden, iTotal: Integer;
begin
  bPendiente := False;
  iOrden := 1;
  iTotal := 0;
  if FCds.Active and not FCds.IsEmpty then
    iTotal := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  while (iOrden <= iTotal) and not bPendiente do
  begin
    bPendiente := Trim(FCds.FieldByName(
      FCampos.AttrValor[iOrden]).AsString) = '';
    Inc(iOrden);
  end;
  if bPendiente then
    AvanzarSiguienteAtributo
  else
    MostrarEditorArticulo;
end;

procedure TGridArticulosLineas.DespuesResolverBusqueda;
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(nil);
  AvanzarTrasResolver;
end;

procedure TGridArticulosLineas.CrearColumnaNumeroAtributos;
begin
  FColNumeroAtributos := FView.CreateColumn;
  FColNumeroAtributos.Name := 'colNumeroAtributosDyn';
  FColNumeroAtributos.DataBinding.FieldName := FCampos.NumAtributos;
  FColNumeroAtributos.Visible := False;
  FColNumeroAtributos.VisibleForCustomization := False;
  FColNumeroAtributos.Options.Editing := False;
end;

procedure TGridArticulosLineas.CrearColumnasAtributo;
var
  i: Integer;
  Col: TcxGridDBColumn;
  Propiedades: TcxButtonEditProperties;
  Boton: TcxEditButton;
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
    Propiedades := TcxButtonEditProperties(Col.Properties);
    Propiedades.ReadOnly := True;
    Propiedades.Buttons.Clear;
    Boton := Propiedades.Buttons.Add;
    Boton.Default := True;
    Boton.Kind := bkEllipsis;
    Propiedades.OnButtonClick := AtributoButtonClick;
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
var
  ColArticulo: TcxGridDBColumn;
  sArticulo, sTexto: string;
begin
  sArticulo := '';
  sTexto := '';
  if (AViewInfo <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    ColArticulo := FView.GetColumnByFieldName(FCampos.CodigoArt);
    if ColArticulo <> nil then
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[ColArticulo.Index]);
    sTexto := AViewInfo.Text;
  end;
  if PintarCeldaSwatchArticuloSiAplica(
       FConn, ACanvas, AViewInfo, sArticulo, sTexto, nil) then
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

// Actualiza la variacion de la linea y sincroniza la visibilidad con el
// maximo de atributos usado por TODO el documento. Una linea simple no puede
// ocultar las columnas que necesitan otras lineas.
procedure TGridArticulosLineas.ActualizarColumnasAtributo(
  const ACodArt: string);
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
          Col.Options.Editing := True;
          if CdsEditando then
            FCds.FieldByName(FCampos.AttrNombre[i]).AsString :=
              Atribs[i - 1].NombreAtributo;
        end
        else
        begin
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
  RefrescarVisibilidadAtributos(Length(Atribs));
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
  if n > 0 then
  begin
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
  if (ASku <> '') and StartsText(ACodArt + '/', ASku) then
  begin
    sResto := Copy(ASku, Length(ACodArt) + 2, MaxInt);
    Partes := sResto.Split(['/']);
    for i := 0 to High(Partes) do
    begin
      if i < 5 then
        FCds.FieldByName(FCampos.AttrValor[i + 1]).AsString := Partes[i];
    end;
  end;
end;

function TGridArticulosLineas.ResolverEntrada(const AEntrada: string): Boolean;
var
  R: TArtResolucionEntrada;
  sCodArt, sSku, sDesc, sEntrada: string;
  bCompleto: Boolean;
  i: Integer;
begin
  Result := False;
  // Quita STX/ETX/CR/LF que mete el lector de codigo de barras.
  sEntrada := FBusqueda.LimpiarEntrada(AEntrada);
  if sEntrada <> '' then
  begin
    R := FValidador.Resolver(sEntrada);
    if not R.Encontrado then
    begin
      // Codigo fuera de catalogo: se admite como linea libre si procede.
      if FAceptarNoCatalogo then
      begin
        if not CdsEditando then
          FCds.Edit;
        FCds.FieldByName(FCampos.CodigoArt).AsString := sEntrada;
        FCds.FieldByName(FCampos.CodigoUnidad).AsString := '';
        FCds.FieldByName(FCampos.Descripcion).AsString := '';
        ActualizarColumnasAtributo(sEntrada);
        if Assigned(FOnResuelto) then
          FOnResuelto(sEntrada, '', '', True);
        Result := True;
      end;
    end
    else
    begin
      sCodArt := R.CodigoArticulo;
      sSku := R.CodigoSku;
      sDesc := R.DescripcionArticulo;
      bCompleto := (sSku <> '') and (not R.RequiereSku);
      if bCompleto and AcumularLineaExistente(sCodArt, sSku, sDesc) then
        Result := True
      else
      begin
        if not CdsEditando then
          FCds.Edit;
        if not SameText(
          Trim(FCds.FieldByName(FCampos.CodigoArt).AsString),
          sCodArt) then
        begin
          for i := 1 to 5 do
            FCds.FieldByName(FCampos.AttrValor[i]).AsString := '';
        end;
        FCds.FieldByName(FCampos.CodigoArt).AsString := sCodArt;
        FCds.FieldByName(FCampos.Descripcion).AsString := sDesc;
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
    end;
  end;
end;

function TGridArticulosLineas.AcumularLineaExistente(const ACodArt,
  ASku, ADesc: string): Boolean;
begin
  Result := False;
  if (FCampos.Cantidad <> '') and
     (FCds.FindField(FCampos.Cantidad) <> nil) then
  begin
    // Soltar la edicion de la linea actual (en blanco o a medias)
    // antes de mover el cursor a la linea destino.
    if CdsEditando then
      FCds.Cancel;
    if FCds.Locate(FCampos.CodigoUnidad, ASku, [loCaseInsensitive]) then
    begin
      FCds.Edit;
      FCds.FieldByName(FCampos.Cantidad).AsFloat :=
        FCds.FieldByName(FCampos.Cantidad).AsFloat + 1;
      FCds.Post;
      if Assigned(FOnResuelto) then
        FOnResuelto(ACodArt, ASku, ADesc, True);
      Result := True;
    end;
  end;
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
  if (Col <> nil) and (Col.Tag >= 1) and (Col.Tag <= 5) then
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
  if (AOrden >= 1) and (AOrden <= 5) and
     FCds.Active and not FCds.IsEmpty then
  begin
    sArtPadre := FCds.FieldByName(FCampos.CodigoArt).AsString;
    sAvActual := FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString;
    sNombreAtb := FCds.FieldByName(FCampos.AttrNombre[AOrden]).AsString;
    Avs := FLookup.ObtenerAvsEnSkus(sArtPadre, AOrden);
    if Length(Avs) = 0 then
      ShowMessage(SErrorValoresAtributoNoDefinidos)
    else
    begin
      SetLength(AvsStr, Length(Avs));
      for i := 0 to High(Avs) do
        AvsStr[i] := Avs[i].Valor;
      sIdVa := '';
      Mapa := ObtenerMapaAtributosGlobal(FConn);
      if Mapa <> nil then
        Mapa.TryGetValue(UpperCase(Trim(sNombreAtb)), sIdVa);
      FEnPaleta := True;
      try
        Col := ColumnaPorTag(AOrden);
        if (Col <> nil) and (FView.Controller.FocusedColumn <> Col) then
          FView.Controller.FocusedColumn := Col;
        if not FView.Controller.EditingController.IsEditing then
        begin
          try
            FView.Controller.EditingController.ShowEdit;
          except
            on E: Exception do
            begin
              if Assigned(FRegistroLog) then
                FRegistroLog.RegistrarAviso(
                  'GridArticulos.AbrirPaletaOrden: ShowEdit ignorado: ' +
                  E.Message);
            end;
          end;
        end;
        ScrX := -1;
        ScrY := -1;
        WidHint := 120;
        Edit := nil;
        if FView.Controller.EditingController.IsEditing then
          Edit := FView.Controller.EditingController.Edit;
        if (Edit <> nil) and Edit.HasParent then
        begin
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
        end;
        if SeleccionarAvConPaleta(
          FConn, sIdVa, AvsStr, sAvActual, sAvNuevo,
          ScrX, ScrY, WidHint) then
        begin
          if FCds.State = dsBrowse then
            FCds.Edit;
          if FCds.State in [dsEdit, dsInsert] then
          begin
            FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString :=
              sAvNuevo;
            AplicarSkuYAvisar;
            if not AvanzarSiguienteAtributo then
              MostrarEditorArticulo;
          end;
        end;
      finally
        FEnPaleta := False;
      end;
    end;
  end;
end;

function TGridArticulosLineas.AvanzarSiguienteAtributo: Boolean;
var
  i, n: Integer;
  Col: TcxGridDBColumn;
begin
  Result := False;
  if FCds.Active and not FCds.IsEmpty then
  begin
    n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
    for i := 1 to n do
    begin
      if Trim(FCds.FieldByName(FCampos.AttrValor[i]).AsString) = '' then
      begin
        Col := ColumnaPorTag(i);
        if Col <> nil then
        begin
          if not Col.Visible then
            Col.Visible := True;
          FView.Controller.FocusedColumn := Col;
          FOrdenPopupPend := i;
          FTimerPopup.Enabled := False;
          FTimerPopup.Enabled := True;
          Result := True;
        end;
        Break;
      end;
    end;
  end;
end;

end.
