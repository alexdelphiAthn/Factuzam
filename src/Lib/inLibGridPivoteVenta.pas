{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridPivoteVenta                                          }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       07/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modo de grid "Tallas en horizontal" para pedidos de venta.                }
{    No consolida ni des-pivota datos: cada celda apunta a una linea real      }
{    de fza_pedidos_lineas y el pivot solo filtra/publica cantidades sobre     }
{    columnas no-bound.                                                        }
{******************************************************************************}
unit inLibGridPivoteVenta;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.StrUtils, System.UITypes, System.Generics.Collections, Data.DB,
  Datasnap.DBClient, Uni, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs,
  Vcl.ExtCtrls, cxGraphics, cxEdit, cxTextEdit, cxButtonEdit,
  cxCurrencyEdit,
  cxDataStorage, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibColumnasSkuIntf, inLibGridTallasInline;

type
  TBandaPivoteVenta = (bpvPedida, bpvEntregada, bpvPendiente);

  TCrearLineaPivoteVentaEvent = procedure(const ACodigoSku: string) of object;
  TBandaPivoteVentaEvent = procedure(ABanda: TBandaPivoteVenta) of object;

  IPivoteVentaAlbaranar = interface
    ['{8CB98D4C-21BC-47F3-8D83-8E39E876F873}']
    function MarcarTodoAAlbaranar: Integer;
    function VolcarAAlbaranar(ALineas: TList<TPair<string, Currency>>;
                              out AAlmacenComun: string;
                              out AAlmacenUnico: Boolean): Integer;
    procedure LimpiarAAlbaranar;
  end;

  // Borrado del grupo activo del pivote. Una fila del grid en modo tallas
  // horizontales representa un GRUPO articulo+color+precio con varias
  // lineas SKU reales (una por talla): el host debe invocar esto desde su
  // boton "Borrar linea" cuando el modo esta activo, porque un Delete
  // simple sobre el dataset solo elimina la linea representante y el
  // grupo "reaparece" al recargar el pivote con las tallas restantes.
  IPivoteVentaBorrarGrupo = interface
    ['{B3D1C0AA-4F5E-4C2B-9A77-0E61D8A3C512}']
    // Borra TODAS las lineas reales del grupo con foco. Devuelve el
    // numero de lineas borradas (0 si no hay grupo bajo el foco).
    function BorrarGrupoActual: Integer;
  end;

  TGridPivoteVentaConfig = record
    Conexion              : TUniConnection;
    Usuario               : string;
    SourceMaster          : TDataSource;
    SourceLineas          : TDataSource;
    FieldSerieMaster      : string;
    FieldNumeroMaster     : string;
    FieldLinea            : string;
    FieldArt              : string;
    FieldSku              : string;
    FieldDescripcion      : string;
    FieldTipoCantidad     : string;
    FieldCantidadPedida   : string;
    FieldCantidadEntregada: string;
    FieldCantidadAAlbaranar: string;
    FieldPrecioBase       : string;
    FieldAlmacen          : string;
    FieldAlmacenMaster    : string;
    MaxColumnas           : Integer;
    // Documento con UNA sola cantidad por linea (facturas de venta):
    // cada grupo articulo+color+precio pinta UNA fila (banda pedida,
    // rotulada 'Cantidad') en vez de las tres bandas Pedido /
    // A albaranar / Pendiente de pedidos.
    BandaUnica            : Boolean;
    // Rotulo de la banda de servicio ('A albaranar' por defecto;
    // pedidos de compra la rotulan 'A recibir').
    TextoBandaAAlbaranar  : string;
    // Campo de la COPIA VISUAL que recibe la suma de UNIDADES del
    // grupo. Solo aplica con BandaUnica: el importe de la linea
    // representante descuadraba con la suma de las celdas (el importe
    // del documento ya vive en el pie de totales).
    FieldTotalUdsGrupo    : string;
    OnCrearLineaSku       : TCrearLineaPivoteVentaEvent;
    OnBandaCambiada       : TBandaPivoteVentaEvent;
  end;

function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;

implementation

uses
  inLibArticulosAtributosLookup, inLibArticulosValidador,
  inLibAtributosPaleta, inLibGenBusq, inLibGlobalVar, inLibLog;

const
  ID_AV_SIN_TALLA = 0;
  CAMPO_LINEA_VISTA = '__LINEA_VISTA_PV';
  ANCHO_COLUMNA_TALLA_TRES_CANT = 62;

type
  THackWinControl = class(TWinControl);

  TSkuPivoteVentaInfo = record
    ColorAv    : Integer;
    TallaAv    : Integer;
    ColorTexto : string;
    ColorCodigo: string;
    VarSku     : string;
  end;

  TGridPivoteVenta = class(TInterfacedObject, IModoEntradaGrid,
                           IPivoteVentaAlbaranar, IPivoteVentaBorrarGrupo)
  private
    FConfig              : TConfigColumnasSku;
    FCfg                 : TGridPivoteVentaConfig;
    FGestor              : TGestorGridTallas;
    FColLineaVista       : TcxGridDBColumn;
    FColArticulo         : TcxGridDBColumn;
    FColColor            : TcxGridDBColumn;
    FColTipoCantidad     : TcxGridDBColumn;
    FColumnasTallas      : TArray<TcxGridDBColumn>;
    FPivotLineasRepr     : TList<Integer>;
    FLineaBasePivot      : TDictionary<Integer, Integer>;
    FLineaBanda          : TDictionary<Integer, TBandaPivoteVenta>;
    FPivotCantPedida     : TDictionary<Int64, Double>;
    FPivotCantEntregada  : TDictionary<Int64, Double>;
    FPivotCantAAlbaranar : TDictionary<Int64, Double>;
    FPivotUdsGrupo       : TDictionary<Integer, Double>;
    FPivotIdAc           : TDictionary<Integer, Integer>;
    FPivotSinTalla       : TDictionary<Integer, Boolean>;
    FPivotArticulo       : TDictionary<Integer, string>;
    FPivotTipoCantidad   : TDictionary<Integer, string>;
    FPivotColorAv        : TDictionary<Integer, Integer>;
    FPivotColorTexto     : TDictionary<Integer, string>;
    FPivotColorCodigo    : TDictionary<Integer, string>;
    FPivotSkuPrefijo     : TDictionary<Integer, string>;
    FPivotVarSku         : TDictionary<Integer, string>;
    FCeldaSku            : TDictionary<Int64, string>;
    FCeldaLinea          : TDictionary<Int64, string>;
    FCeldaAlmacen        : TDictionary<Int64, string>;
    FSkuInfo             : TDictionary<string, TSkuPivoteVentaInfo>;
    // Conjuntos VIRTUALES (id negativo) por lista de tallas: fallback
    // cuando ningun conjunto real de fza_atributos_conjuntos cubre las
    // tallas de un grupo (articulo dado de alta sin conjunto asignado).
    FConjuntoVirtualIds  : TDictionary<string, Integer>;
    FProxConjuntoVirtual : Integer;
    FCdsVista            : TClientDataSet;
    FDsVista             : TDataSource;
    FDataSourceOrig      : TDataSource;
    // True mientras el View del host apunta a FDsVista. Sin este flag,
    // el destructor tocaba View.DataController con el grid YA destruido
    // (liberacion de la interfaz en CleanupInstance al cerrar el Mto:
    // AV en GetProvider, 08/07/26).
    FVistaDesviada       : Boolean;
    FOnResuelto          : TSkuResueltoEvent;
    FOnEntrarEdicion     : TNotifyEvent;
    FOnSalirEdicion      : TNotifyEvent;
    FOnFilterOrig        : TFilterRecordEvent;
    FAfterPostOrig       : TDataSetNotifyEvent;
    FAfterScrollOrig     : TDataSetNotifyEvent;
    FFilteredOrig        : Boolean;
    FEventosInstalados   : Boolean;
    FActualizandoGrid    : Boolean;
    FGuardandoCantidad   : Boolean;
    FEnRecarga           : Boolean;
    // Tras cada Construir, la PRIMERA publicacion posiciona el grid al
    // principio: el scroll heredado de la presentacion anterior dejaba
    // las primeras filas pivotadas fuera del viewport y parecian
    // "desaparecidas" (pedidos de compra, 09/07/26).
    FScrollInicialPendiente: Boolean;
    // True cuando el usuario CANCELA la paleta de color/talla al meter un
    // articulo con variaciones: ResolverEntrada devuelve False pero el
    // validador no debe rotular "no encontrado".
    FEntradaCancelada    : Boolean;
    FHayTipoCantidadEspecial: Boolean;
    FTimerRecarga        : TTimer;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    function CdsLineas: TDataSet;
    // Posiciona el cursor de ADs en la linea real ALinea probando los
    // formatos de numeracion segun documento: 4 digitos (pedidos
    // '0010'), 3 digitos (facturas '010') y el entero pelado.
    function LocalizarLineaReal(ADs: TDataSet; ALinea: Integer): Boolean;
    function CampoTexto(ADs: TDataSet; const ACampo: string): string;
    function CampoFloat(ADs: TDataSet; const ACampo: string): Double;
    procedure PonerFloat(ADs: TDataSet; const ACampo: string;
                         AValor: Double);
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure VistaBeforeDelete(DataSet: TDataSet);
    // Borra las lineas SKU reales del grupo ALineaBase (sin recargar el
    // pivote). Devuelve el numero de lineas borradas.
    function BorrarLineasGrupo(ALineaBase: Integer): Integer;
    procedure ArmarRecarga;
    procedure TimerRecargaTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure CrearColumnas;
    procedure CrearGestor;
    function EsInsercionVacia(ADs: TDataSet): Boolean;
    procedure PrepararVistaTemporal;
    procedure RestaurarVistaTemporal;
    procedure ReconstruirVistaTemporal;
    procedure CopiarLineaVista(AOrigen: TDataSet; ALineaVista: Integer);
    procedure RecargarYPublicar;
    procedure CargarCachePivot;
    function ObtenerInfoLinea(ADs: TDataSet; out ASku: string;
                              out AInfo: TSkuPivoteVentaInfo): Boolean;
    function ObtenerInfoSku(const ASku: string;
                            out AInfo: TSkuPivoteVentaInfo): Boolean;
    function ResolverSkuDesdeCodigoBarras(
      const ACodigoBarras: string): string;
    function ResolverSkuUnicoArticulo(const ACodigoArticulo: string): string;
    function BuscarConjuntoParaIds(AIds: TList<Integer>): Integer;
    // Fallback de BuscarConjuntoParaIds: fabrica un conjunto VIRTUAL
    // (id negativo, solo en cache del gestor) con las tallas de los
    // SKUs del articulo del grupo — o, si no las hay, con las tallas
    // ATallas del propio grupo — ordenadas por ORDEN_AV.
    function ConjuntoVirtualParaGrupo(ALineaRepr: Integer;
                                      ATallas: TList<Integer>): Integer;
    procedure AplicarVisibilidadTallas;
    procedure AplicarVisibilidadTipoCantidad;
    procedure ColocarBloqueColumnas;
    procedure ActualizarCaptionsLineaActiva;
    procedure PublicarCantidadesPivot;
    function PendienteCelda(AKey: Int64): Double;
    function PendienteBaseCelda(AKey: Int64): Double;
    procedure AjustarAAlbaranarCache;
    function AAlbaranarCelda(AKey: Int64): Double;
    function LineaVistaBanda(ALineaBase: Integer;
                             ABanda: TBandaPivoteVenta): Integer;
    function ObtenerLineaBase(ALinea: Integer): Integer;
    function BandaDesdeLinea(ALinea: Integer): TBandaPivoteVenta;
    function TextoBanda(ABanda: TBandaPivoteVenta): string;
    function EsTipoCantidadPredeterminado(const AValor: string): Boolean;
    function TextoTipoCantidad(ALineaBase: Integer;
                               ABanda: TBandaPivoteVenta): string;
    function ValorCantidadBanda(AKey: Int64;
                                ABanda: TBandaPivoteVenta): Double;
    function BuscarColumnaTallaDesde(ALineaBase, AIndiceInicial: Integer;
                                     out ACol: TcxGridColumn): Boolean;
    function BuscarRecordPorLineaVista(ALineaVista: Integer;
                                       out ARecordIndex: Integer): Boolean;
    function LineaDesdeRecord(ARecord: TcxCustomGridRecord): Integer;
    function TallaAvDesdeColumna(ALinea: Integer; ACol: TcxGridColumn;
                                 out AIdAv: Integer): Boolean;
    function EsColumnaTalla(AItem: TcxCustomGridTableItem): Boolean;
    function ValorEditor(ASender: TObject; AValorFallback: Variant): Double;
    procedure ViewEditing(Sender: TcxCustomGridTableView;
                          AItem: TcxCustomGridTableItem;
                          var AAllow: Boolean);
    procedure EditorSalir(Sender: TObject);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    function GestionarEnterAAlbaranar(Sender: TcxCustomGridTableView;
                                      AItem: TcxCustomGridTableItem): Boolean;
    procedure ViewFocusedRecordChanged(Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure CustomDrawCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure PintarCeldaTallaCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo; AValor: Double;
                ABanda: TBandaPivoteVenta; AMostrarCero: Boolean);
    procedure PintarCeldaTipoCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo);
    procedure ArticuloButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure ArticuloValidate(Sender: TObject; var DisplayValue: Variant;
                               var ErrorText: TCaption;
                               var Error: Boolean);
    procedure CeldaTallaValidate(Sender: TObject; var DisplayValue: Variant;
                                 var ErrorText: TCaption;
                                 var Error: Boolean);
    function LocalizarLineaSku(const ASku: string; APrecio: Double;
                               ATienePrecio: Boolean;
                               out ALinea: string): Boolean;
    function ResolverSkuCelda(AKey: Int64; out ASku: string): Boolean;
    function PrefijoSkuTalla(const ASku: string): string;
    function CrearLineaDesdeCelda(AKey: Int64; ACantidad: Double;
                                   out ALineaReal: string): Boolean;
    procedure PersistirCantidadCelda(AKey: Int64; AValor: Double;
                                     ABanda: TBandaPivoteVenta);
    // Pide color/talla con la paleta de swatches (mismo selector que el
    // modo SKU vertical) y compone el SKU completo ART/COLOR/TALLA.
    // Devuelve '' si el usuario cancela.
    function ElegirSkuConPaleta(const ACodArt: string): string;
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgPivote: TGridPivoteVentaConfig);
    destructor Destroy; override;
    procedure Construir;
    procedure Desmontar;
    procedure MostrarEditor;
    function MarcarTodoAAlbaranar: Integer;
    function VolcarAAlbaranar(ALineas: TList<TPair<string, Currency>>;
                              out AAlmacenComun: string;
                              out AAlmacenUnico: Boolean): Integer;
    procedure LimpiarAAlbaranar;
    function BorrarGrupoActual: Integer;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;
begin
  Result := TGridPivoteVenta.Create(AConfig, ACfgPivote);
end;

constructor TGridPivoteVenta.Create(const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FConfig.Modo := mcsTallasHorPed;
  FCfg := ACfgPivote;
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := 20;
  FPivotLineasRepr    := TList<Integer>.Create;
  FLineaBasePivot     := TDictionary<Integer, Integer>.Create;
  FLineaBanda         := TDictionary<Integer, TBandaPivoteVenta>.Create;
  FPivotCantPedida    := TDictionary<Int64, Double>.Create;
  FPivotCantEntregada := TDictionary<Int64, Double>.Create;
  FPivotCantAAlbaranar := TDictionary<Int64, Double>.Create;
  FPivotUdsGrupo      := TDictionary<Integer, Double>.Create;
  FPivotIdAc          := TDictionary<Integer, Integer>.Create;
  FPivotSinTalla      := TDictionary<Integer, Boolean>.Create;
  FPivotArticulo      := TDictionary<Integer, string>.Create;
  FPivotTipoCantidad  := TDictionary<Integer, string>.Create;
  FPivotColorAv       := TDictionary<Integer, Integer>.Create;
  FPivotColorTexto    := TDictionary<Integer, string>.Create;
  FPivotColorCodigo   := TDictionary<Integer, string>.Create;
  FPivotSkuPrefijo    := TDictionary<Integer, string>.Create;
  FPivotVarSku        := TDictionary<Integer, string>.Create;
  FCeldaSku           := TDictionary<Int64, string>.Create;
  FCeldaLinea         := TDictionary<Int64, string>.Create;
  FCeldaAlmacen       := TDictionary<Int64, string>.Create;
  FSkuInfo            := TDictionary<string, TSkuPivoteVentaInfo>.Create;
  FConjuntoVirtualIds := TDictionary<string, Integer>.Create;
  FProxConjuntoVirtual := -1;
  FCdsVista           := TClientDataSet.Create(nil);
  FDsVista            := TDataSource.Create(nil);
  FDsVista.DataSet    := FCdsVista;
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

destructor TGridPivoteVenta.Destroy;
begin
  // Mismo orden que Desmontar: primero los eventos del dataset, luego
  // la vista (el cambio de DataSource dispara First/AfterScroll).
  RestaurarEventosDataSet;
  RestaurarVistaTemporal;
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FDsVista);
  FreeAndNil(FCdsVista);
  FreeAndNil(FGestor);
  FreeAndNil(FConjuntoVirtualIds);
  FreeAndNil(FSkuInfo);
  FreeAndNil(FCeldaAlmacen);
  FreeAndNil(FCeldaLinea);
  FreeAndNil(FCeldaSku);
  FreeAndNil(FPivotVarSku);
  FreeAndNil(FPivotSkuPrefijo);
  FreeAndNil(FPivotColorCodigo);
  FreeAndNil(FPivotColorTexto);
  FreeAndNil(FPivotColorAv);
  FreeAndNil(FPivotTipoCantidad);
  FreeAndNil(FPivotArticulo);
  FreeAndNil(FPivotSinTalla);
  FreeAndNil(FPivotIdAc);
  FreeAndNil(FPivotUdsGrupo);
  FreeAndNil(FPivotCantAAlbaranar);
  FreeAndNil(FPivotCantEntregada);
  FreeAndNil(FPivotCantPedida);
  FreeAndNil(FLineaBanda);
  FreeAndNil(FLineaBasePivot);
  FreeAndNil(FPivotLineasRepr);
  inherited;
end;

function TGridPivoteVenta.GetModo: TModoColumnasSku;
begin
  Result := mcsTallasHorPed;
end;

function TGridPivoteVenta.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

procedure TGridPivoteVenta.SetOnResuelto(const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

function TGridPivoteVenta.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FOnEntrarEdicion;
end;

procedure TGridPivoteVenta.SetOnEntrarEdicion(const AValue: TNotifyEvent);
begin
  FOnEntrarEdicion := AValue;
end;

function TGridPivoteVenta.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FOnSalirEdicion;
end;

procedure TGridPivoteVenta.SetOnSalirEdicion(const AValue: TNotifyEvent);
begin
  FOnSalirEdicion := AValue;
end;

procedure TGridPivoteVenta.SetAlmacenStock(const AValue: string);
begin
  FConfig.AlmacenStock := AValue;
end;

function TGridPivoteVenta.CdsLineas: TDataSet;
begin
  Result := nil;
  if FCfg.SourceLineas <> nil then
    Result := FCfg.SourceLineas.DataSet;
  if Result = nil then
    Result := FConfig.Cds;
end;

function TGridPivoteVenta.LocalizarLineaReal(ADs: TDataSet;
  ALinea: Integer): Boolean;
begin
  Result := False;
  if (ADs <> nil) and ADs.Active and (ALinea > 0) then
  begin
    Result := ADs.Locate(FCfg.FieldLinea, Format('%.4d', [ALinea]), []);
    if not Result then
      Result := ADs.Locate(FCfg.FieldLinea, Format('%.3d', [ALinea]), []);
    if not Result then
      Result := ADs.Locate(FCfg.FieldLinea, IntToStr(ALinea), []);
  end;
end;

function TGridPivoteVenta.CampoTexto(ADs: TDataSet;
  const ACampo: string): string;
var
  Campo: TField;
begin
  Result := '';
  if (ADs <> nil) and (ACampo <> '') then
  begin
    Campo := ADs.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;
end;

function TGridPivoteVenta.CampoFloat(ADs: TDataSet;
  const ACampo: string): Double;
var
  Campo: TField;
begin
  Result := 0;
  if (ADs <> nil) and (ACampo <> '') then
  begin
    Campo := ADs.FindField(ACampo);
    if Campo <> nil then
      Result := Campo.AsFloat;
  end;
end;

procedure TGridPivoteVenta.PonerFloat(ADs: TDataSet; const ACampo: string;
  AValor: Double);
var
  Campo: TField;
begin
  if (ADs <> nil) and (ACampo <> '') then
  begin
    Campo := ADs.FindField(ACampo);
    if (Campo <> nil) and (not Campo.ReadOnly) then
      Campo.AsFloat := AValor;
  end;
end;

procedure TGridPivoteVenta.CdsAfterPost(DataSet: TDataSet);
begin
  if Assigned(FAfterPostOrig) then
    FAfterPostOrig(DataSet);
  if not FEnRecarga then
    ArmarRecarga;
end;

procedure TGridPivoteVenta.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FAfterScrollOrig) then
    FAfterScrollOrig(DataSet);
  ActualizarCaptionsLineaActiva;
end;

procedure TGridPivoteVenta.VistaBeforeDelete(DataSet: TDataSet);
var
  iLineaBase: Integer;
begin
  // Delete contra la VISTA temporal (Ctrl+Supr del cxGrid, navigator...):
  // la vista es una copia en memoria, borrar su fila no toca las lineas
  // reales y el grupo "reaparecia" al recargar el pivote. Se redirige al
  // borrado real del grupo completo y se aborta el delete de la copia; la
  // recarga diferida (timer) reconstruye la vista ya sin el grupo.
  iLineaBase := 0;
  if DataSet.FindField(CAMPO_LINEA_VISTA) <> nil then
    iLineaBase := ObtenerLineaBase(
      DataSet.FieldByName(CAMPO_LINEA_VISTA).AsInteger);
  if iLineaBase > 0 then
  begin
    if MessageDlg('¿Está seguro de que desea eliminar esta línea ' +
                  '(todas sus tallas)?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if BorrarLineasGrupo(iLineaBase) > 0 then
        ArmarRecarga;
    end;
  end;
  Abort;
end;

procedure TGridPivoteVenta.ArmarRecarga;
begin
  if FTimerRecarga <> nil then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TGridPivoteVenta.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  RecargarYPublicar;
end;

procedure TGridPivoteVenta.InstalarEventosDataSet;
var
  Ds: TDataSet;
begin
  Ds := CdsLineas;
  if (Ds <> nil) and (not FEventosInstalados) then
  begin
    FOnFilterOrig  := Ds.OnFilterRecord;
    FFilteredOrig  := Ds.Filtered;
    FAfterPostOrig := Ds.AfterPost;
    FAfterScrollOrig := Ds.AfterScroll;
    Ds.AfterPost := CdsAfterPost;
    Ds.AfterScroll := CdsAfterScroll;
    FEventosInstalados := True;
  end;
end;

procedure TGridPivoteVenta.RestaurarEventosDataSet;
var
  Ds: TDataSet;
begin
  Ds := CdsLineas;
  if (Ds <> nil) and FEventosInstalados then
  begin
    // Primero desenganchar los hooks y LUEGO restaurar Filtered: el
    // cambio de filtro refresca el dataset y dispara AfterScroll, que
    // no debe caer ya en los handlers del pivote.
    Ds.OnFilterRecord := FOnFilterOrig;
    Ds.AfterPost := FAfterPostOrig;
    Ds.AfterScroll := FAfterScrollOrig;
    FEventosInstalados := False;
    Ds.Filtered := FFilteredOrig;
  end;
end;

procedure TGridPivoteVenta.CrearColumnas;
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  FConfig.View.BeginUpdate;
  try
    FColLineaVista := FConfig.View.CreateColumn;
    FColLineaVista.DataBinding.FieldName := CAMPO_LINEA_VISTA;
    FColLineaVista.Visible := False;
    FColLineaVista.VisibleForCustomization := False;
    FColArticulo := FConfig.View.CreateColumn;
    FColArticulo.Caption := 'Artículo';
    FColArticulo.DataBinding.FieldName := FConfig.Campos.CodigoArt;
    FColArticulo.Width := 160;
    FColArticulo.Options.Editing := True;
    FColArticulo.PropertiesClass := TcxButtonEditProperties;
    with TcxButtonEditProperties(FColArticulo.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := ArticuloButtonClick;
      OnValidate := ArticuloValidate;
    end;
    FColColor := FConfig.View.CreateColumn;
    FColColor.Caption := 'Color';
    FColColor.Width := 125;
    FColColor.Options.Editing := False;
    FColColor.DataBinding.ValueTypeClass := TcxStringValueType;
    FColTipoCantidad := FConfig.View.CreateColumn;
    FColTipoCantidad.Caption := 'Tipo';
    FColTipoCantidad.Width := 105;
    FColTipoCantidad.Options.Editing := False;
    FColTipoCantidad.DataBinding.ValueTypeClass := TcxStringValueType;
    SetLength(FColumnasTallas, FCfg.MaxColumnas);
    for i := 1 to FCfg.MaxColumnas do
    begin
      Col := FConfig.View.CreateColumn;
      Col.Tag := i;
      Col.Caption := '·';
      Col.Width := ANCHO_COLUMNA_TALLA_TRES_CANT;
      Col.Visible := False;
      Col.DataBinding.ValueTypeClass := TcxFloatValueType;
      Col.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(Col.Properties).DisplayFormat := '#,##0.##';
      TcxCurrencyEditProperties(Col.Properties).
        UseDisplayFormatWhenEditing := True;
      TcxCurrencyEditProperties(Col.Properties).OnValidate :=
        CeldaTallaValidate;
      FColumnasTallas[i - 1] := Col;
    end;
  finally
    FConfig.View.EndUpdate;
  end;
end;

procedure TGridPivoteVenta.CrearGestor;
var
  CfgT: TGridTallasConfig;
begin
  FreeAndNil(FGestor);
  CfgT := Default(TGridTallasConfig);
  CfgT.Conexion := FCfg.Conexion;
  CfgT.Usuario := FCfg.Usuario;
  CfgT.Grid := FConfig.View;
  CfgT.SourceMaster := FCfg.SourceMaster;
  CfgT.SourceLineas := FCfg.SourceLineas;
  CfgT.ColumnasTallas := FColumnasTallas;
  CfgT.FieldSerieMaster := FCfg.FieldSerieMaster;
  CfgT.FieldNumeroMaster := FCfg.FieldNumeroMaster;
  CfgT.FieldLinea := FCfg.FieldLinea;
  CfgT.FieldConjuntoPivot := '';
  CfgT.MaxColumnas := FCfg.MaxColumnas;
  FGestor := TGestorGridTallas.Create(CfgT);
end;

function TGridPivoteVenta.EsInsercionVacia(ADs: TDataSet): Boolean;
begin
  Result := (ADs <> nil) and (ADs.State = dsInsert) and
            (CampoTexto(ADs, FCfg.FieldArt) = '') and
            (CampoTexto(ADs, FCfg.FieldSku) = '') and
            (CampoTexto(ADs, 'CODIGOPRODPS_PEDLIN') = '');
end;

procedure TGridPivoteVenta.PrepararVistaTemporal;
var
  Ds: TDataSet;
  Campo: TField;
  Def: TFieldDef;
  i: Integer;
begin
  Ds := CdsLineas;
  if (Ds <> nil) and (FCdsVista <> nil) then
  begin
    if FCdsVista.Active then
      FCdsVista.Close;
    FCdsVista.FieldDefs.Clear;
    for i := 0 to Ds.Fields.Count - 1 do
    begin
      Campo := Ds.Fields[i];
      if Campo.FieldKind = fkData then
      begin
        Def := FCdsVista.FieldDefs.AddFieldDef;
        Def.Name := Campo.FieldName;
        Def.DataType := Campo.DataType;
        Def.Size := Campo.Size;
        Def.Required := False;
      end;
    end;
    Def := FCdsVista.FieldDefs.AddFieldDef;
    Def.Name := CAMPO_LINEA_VISTA;
    Def.DataType := ftInteger;
    Def.Required := False;
    FCdsVista.CreateDataSet;
    // Intercepta Ctrl+Supr / navigator sobre la vista: redirige al
    // borrado real del grupo (todas las tallas) y aborta el delete de
    // la copia en memoria.
    FCdsVista.BeforeDelete := VistaBeforeDelete;
    if (FConfig.View <> nil) and
       (FConfig.View.DataController.DataSource <> FDsVista) then
    begin
      FDataSourceOrig := FConfig.View.DataController.DataSource;
      FConfig.View.DataController.DataSource := FDsVista;
    end;
    FVistaDesviada := FConfig.View <> nil;
  end;
end;

procedure TGridPivoteVenta.RestaurarVistaTemporal;
begin
  // Solo se toca el View si la vista temporal sigue montada: tras un
  // Desmontar del host no queda nada que restaurar y el destructor no
  // debe dereferenciar un grid posiblemente destruido.
  if FVistaDesviada then
  begin
    try
      if (FConfig.View <> nil) and
         (not (csDestroying in FConfig.View.ComponentState)) then
        FConfig.View.DataController.DataSource := FDataSourceOrig;
    except
      // Cierre defensivo: si DevExpress ya ha destruido el provider,
      // no hay nada que restaurar y no debemos impedir cerrar la ficha.
    end;
    FVistaDesviada := False;
  end;
  FDataSourceOrig := nil;
end;

procedure TGridPivoteVenta.CopiarLineaVista(AOrigen: TDataSet;
  ALineaVista: Integer);
var
  CampoOri, CampoDst: TField;
  i, iBase: Integer;
  rUds: Double;
begin
  if (AOrigen <> nil) and (FCdsVista <> nil) and FCdsVista.Active then
  begin
    FCdsVista.Append;
    for i := 0 to AOrigen.Fields.Count - 1 do
    begin
      CampoOri := AOrigen.Fields[i];
      CampoDst := FCdsVista.FindField(CampoOri.FieldName);
      if (CampoOri.FieldKind = fkData) and (CampoDst <> nil) and
         (not (CampoOri.DataType in [ftBlob, ftGraphic, ftMemo,
                                    ftFmtMemo, ftBytes, ftVarBytes,
                                    ftWideMemo])) then
        CampoDst.Value := CampoOri.Value;
    end;
    CampoDst := FCdsVista.FindField(CAMPO_LINEA_VISTA);
    if CampoDst <> nil then
      CampoDst.AsInteger := ALineaVista;
    // En banda unica, la columna Total del host pasa a UNIDADES del
    // grupo: el importe de la linea representante descuadraba con la
    // suma de las celdas (el importe del documento vive en el pie).
    if FCfg.BandaUnica and (FCfg.FieldTotalUdsGrupo <> '') then
    begin
      CampoDst := FCdsVista.FindField(FCfg.FieldTotalUdsGrupo);
      if CampoDst <> nil then
      begin
        if FLineaBasePivot.TryGetValue(ALineaVista, iBase) and
           FPivotUdsGrupo.TryGetValue(iBase, rUds) then
          CampoDst.AsFloat := rUds
        else
          CampoDst.Clear;
      end;
    end;
    // El numero de linea visible ya viene copiado de la linea BASE
    // real (el Locate previo posiciono en ella): se conserva su
    // formato original en vez de imponer 4 digitos.
    FCdsVista.Post;
  end;
end;

procedure TGridPivoteVenta.ReconstruirVistaTemporal;
var
  Ds: TDataSet;
  Bm: TBookmark;
  iLineaVista, iLineaBase: Integer;
  bFiltrado, bAnadida: Boolean;
begin
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and (FCdsVista <> nil) and
     FCdsVista.Active then
  begin
    FCdsVista.DisableControls;
    try
      FCdsVista.EmptyDataSet;
      if EsInsercionVacia(Ds) or Ds.IsEmpty then
      begin
        FCdsVista.Append;
        if FCdsVista.FindField(CAMPO_LINEA_VISTA) <> nil then
          FCdsVista.FieldByName(CAMPO_LINEA_VISTA).AsInteger := 0;
        if FCdsVista.FindField(FCfg.FieldLinea) <> nil then
          FCdsVista.FieldByName(FCfg.FieldLinea).AsString := '0000';
        FCdsVista.Post;
      end
      else
      begin
        Ds.DisableControls;
        Bm := nil;
        bFiltrado := Ds.Filtered;
        try
          if not Ds.IsEmpty then
            Bm := Ds.GetBookmark;
          Ds.Filtered := False;
          for iLineaVista in FPivotLineasRepr do
          begin
            iLineaBase := ObtenerLineaBase(iLineaVista);
            // El formato del numero de linea depende del documento:
            // sin probar todos, las lineas no se copiaban a la vista
            // temporal y "desaparecian" (facturas '010', 09/07/26).
            bAnadida := LocalizarLineaReal(Ds, iLineaBase);
            // Traza de diagnostico (fase de integracion).
            if Log <> nil then
              Log.LogInfo(Format(
                'PivVenta.Vista: vista=%d base=%d encontrada=%s',
                [iLineaVista, iLineaBase, BoolToStr(bAnadida, True)]));
            if bAnadida then
              CopiarLineaVista(Ds, iLineaVista)
            else if Log <> nil then
              // Error DOCUMENTADO: una fila del pivote se pierde. Sin
              // este aviso la linea "desaparecia" en silencio.
              Log.LogWarning(Format(
                'PivVenta.Vista: linea base %d NO localizada en el ' +
                'dataset (formatos probados: %.4d / %.3d / %d); la ' +
                'fila pivotada %d se OMITE de la vista temporal',
                [iLineaBase, iLineaBase, iLineaBase, iLineaBase,
                 iLineaVista]));
          end;
          if FCdsVista.IsEmpty and (not Ds.IsEmpty) then
            CopiarLineaVista(Ds, 0);
          if (Bm <> nil) and Ds.BookmarkValid(Bm) then
            Ds.GotoBookmark(Bm);
        finally
          Ds.Filtered := bFiltrado;
          Ds.EnableControls;
          if Bm <> nil then
            Ds.FreeBookmark(Bm);
        end;
      end;
    finally
      FCdsVista.EnableControls;
    end;
  end;
end;

procedure TGridPivoteVenta.Construir;
begin
  FScrollInicialPendiente := True;
  CrearColumnas;
  CrearGestor;
  PrepararVistaTemporal;
  FConfig.View.OnEditing := ViewEditing;
  FConfig.View.OnInitEdit := ViewInitEdit;
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  FConfig.View.OnFocusedRecordChanged := ViewFocusedRecordChanged;
  FConfig.View.OnCustomDrawCell := CustomDrawCell;
  InstalarEventosDataSet;
  ArmarRecarga;
end;

procedure TGridPivoteVenta.Desmontar;
begin
  if FConfig.View <> nil then
  begin
    FConfig.View.OnEditing := nil;
    FConfig.View.OnInitEdit := nil;
    FConfig.View.OnEditKeyDown := nil;
    FConfig.View.OnFocusedRecordChanged := nil;
    FConfig.View.OnCustomDrawCell := nil;
  end;
  // Eventos del dataset ANTES de restaurar la vista: el cambio de
  // DataSource recarga el grid (LoadStorage -> First -> AfterScroll) y
  // con CdsAfterScroll aun enganchado se leia un grid a medio cargar
  // (EListError en LineaDesdeRecord al pasar a otro modo, 08/07/26).
  RestaurarEventosDataSet;
  RestaurarVistaTemporal;
end;

procedure TGridPivoteVenta.MostrarEditor;
begin
  if (FConfig.View <> nil) and (FColArticulo <> nil) then
  begin
    RecargarYPublicar;
    if (FConfig.View.DataController <> nil) and
       (FConfig.View.DataController.RecordCount > 0) then
      FConfig.View.DataController.FocusedRecordIndex := 0;
    if Assigned(FConfig.View.Site) and FConfig.View.Site.CanFocus then
      FConfig.View.Site.SetFocus;
    FColArticulo.Focused := True;
    FConfig.View.Controller.FocusedItem := FColArticulo;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        ;
    end;
    if not FConfig.View.Controller.EditingController.IsEditing then
      ArticuloButtonClick(nil, 0);
  end;
end;

function TGridPivoteVenta.ObtenerInfoLinea(ADs: TDataSet; out ASku: string;
  out AInfo: TSkuPivoteVentaInfo): Boolean;
var
  InfoBarras: TSkuPivoteVentaInfo;
  sBarras, sArt, sSkuBarras: string;
  function ProbarSku(const ACandidato: string): Boolean;
  var
    sCand: string;
  begin
    sCand := Trim(ACandidato);
    Result := (sCand <> '') and ObtenerInfoSku(sCand, AInfo);
    if Result then
      ASku := sCand;
  end;
begin
  ASku := '';
  AInfo := Default(TSkuPivoteVentaInfo);
  Result := ProbarSku(CampoTexto(ADs, FCfg.FieldSku));
  if not Result then
    Result := ProbarSku(CampoTexto(ADs, 'CODIGO_UNIDAD_PEDLIN'));
  if not Result then
  begin
    sBarras := CampoTexto(ADs, 'CODBAR_ART_PEDLIN');
    if sBarras <> '' then
    begin
      sSkuBarras := ResolverSkuDesdeCodigoBarras(sBarras);
      if (sSkuBarras <> '') and ObtenerInfoSku(sSkuBarras, InfoBarras) then
      begin
        ASku := sSkuBarras;
        AInfo := InfoBarras;
        Result := True;
      end;
    end;
  end;
  if Result and (AInfo.TallaAv <= 0) then
  begin
    sBarras := CampoTexto(ADs, 'CODBAR_ART_PEDLIN');
    sSkuBarras := ResolverSkuDesdeCodigoBarras(sBarras);
    if (sSkuBarras <> '') and ObtenerInfoSku(sSkuBarras, InfoBarras) and
       (InfoBarras.TallaAv > 0) then
    begin
      ASku := sSkuBarras;
      AInfo := InfoBarras;
    end;
  end;
  if not Result then
    Result := ProbarSku(CampoTexto(ADs, 'CODIGOPRODPS_PEDLIN'));
  if not Result then
  begin
    sArt := CampoTexto(ADs, FCfg.FieldArt);
    if sArt <> '' then
      Result := ProbarSku(ResolverSkuUnicoArticulo(sArt));
  end;
  if (not Result) and (ASku = '') then
  begin
    ASku := CampoTexto(ADs, FCfg.FieldSku);
    if ASku = '' then
      ASku := CampoTexto(ADs, 'CODIGOPRODPS_PEDLIN');
  end;
end;

function TGridPivoteVenta.ObtenerInfoSku(const ASku: string;
  out AInfo: TSkuPivoteVentaInfo): Boolean;
var
  Qry: TUniQuery;
  sSku: string;
begin
  sSku := Trim(ASku);
  AInfo := Default(TSkuPivoteVentaInfo);
  Result := False;
  if sSku <> '' then
  begin
    if FSkuInfo.TryGetValue(UpperCase(sSku), AInfo) then
      Result := True
    else if FCfg.Conexion <> nil then
    begin
      Qry := TUniQuery.Create(nil);
      try
        Qry.Connection := FCfg.Conexion;
        Qry.SQL.Text :=
          'SELECT COALESCE(AVC.ID_AV, 0) AS COLOR_AV, ' +
          '       COALESCE(NULLIF(AVC.AV, ''''), ATBC.NOMBRE_ATB, ' +
          '                '''') AS COLOR_TXT, ' +
          '       COALESCE(ATBC.CODIGO_ATB, '''') AS COLOR_COD, ' +
          '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
          '       COALESCE(SKU0.CODIGO_VAR_SKU, ''TC'') AS VAR_SKU ' +
          '  FROM fza_articulos_skus SKU0 ' +
          '  LEFT JOIN fza_atributos_sku SAC ' +
          '    ON SAC.CODIGO_UNIDAD_SKU_SA = SKU0.CODIGO_UNIDAD_SKU ' +
          '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
          '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
          '                  AND AV.ID_VA_AV = ''CO'') ' +
          '  LEFT JOIN fza_atributos_valores AVC ' +
          '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
          '   AND AVC.ID_VA_AV = ''CO'' ' +
          '  LEFT JOIN fza_atributos_basicos ATBC ' +
          '    ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
          '  LEFT JOIN fza_atributos_sku T ' +
          '    ON T.CODIGO_UNIDAD_SKU_SA = SKU0.CODIGO_UNIDAD_SKU ' +
          '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
          '                WHERE AVT.ID_AV = T.ID_AV_SA ' +
          '                  AND AVT.ID_VA_AV = ''TAL'') ' +
          ' WHERE SKU0.CODIGO_UNIDAD_SKU = :sku ' +
          ' LIMIT 1';
        Qry.ParamByName('sku').AsString := sSku;
        Qry.Open;
        if not Qry.Eof then
        begin
          AInfo.ColorAv := Qry.FieldByName('COLOR_AV').AsInteger;
          AInfo.ColorTexto := Qry.FieldByName('COLOR_TXT').AsString;
          AInfo.ColorCodigo := Qry.FieldByName('COLOR_COD').AsString;
          AInfo.TallaAv := Qry.FieldByName('TALLA_AV').AsInteger;
          AInfo.VarSku := Qry.FieldByName('VAR_SKU').AsString;
          FSkuInfo.AddOrSetValue(UpperCase(sSku), AInfo);
          Result := True;
        end;
      finally
        FreeAndNil(Qry);
      end;
    end;
  end;
end;

function TGridPivoteVenta.ResolverSkuDesdeCodigoBarras(
  const ACodigoBarras: string): string;
var
  Qry: TUniQuery;
  sCodigo: string;
begin
  Result := '';
  sCodigo := Trim(ACodigoBarras);
  if (sCodigo <> '') and (FCfg.Conexion <> nil) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FCfg.Conexion;
      Qry.SQL.Text :=
        'SELECT CODIGO_UNIDAD_CB ' +
        '  FROM fza_codigos_barras ' +
        ' WHERE CODIGO_BARRAS_CB = :cod ' +
        '   AND COALESCE(CODIGO_UNIDAD_CB, '''') <> '''' ' +
        ' LIMIT 1';
      Qry.ParamByName('cod').AsString := sCodigo;
      Qry.Open;
      if not Qry.Eof then
        Result := Qry.FieldByName('CODIGO_UNIDAD_CB').AsString;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TGridPivoteVenta.ResolverSkuUnicoArticulo(
  const ACodigoArticulo: string): string;
var
  Qry: TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArticulo);
  if (sArt <> '') and (FCfg.Conexion <> nil) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FCfg.Conexion;
      Qry.SQL.Text :=
        'SELECT MIN(CODIGO_UNIDAD_SKU) AS SKU, COUNT(*) AS N ' +
        '  FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S''';
      Qry.ParamByName('art').AsString := sArt;
      Qry.Open;
      if (not Qry.Eof) and (Qry.FieldByName('N').AsInteger = 1) then
        Result := Qry.FieldByName('SKU').AsString;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TGridPivoteVenta.BuscarConjuntoParaIds(
  AIds: TList<Integer>): Integer;
var
  Qry: TUniQuery;
  sIds: string;
  i: Integer;
begin
  Result := 0;
  if (AIds <> nil) and (AIds.Count > 0) then
  begin
    sIds := '';
    for i := 0 to AIds.Count - 1 do
    begin
      if sIds <> '' then
        sIds := sIds + ',';
      sIds := sIds + IntToStr(AIds[i]);
    end;
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FCfg.Conexion;
      Qry.SQL.Text :=
        'SELECT d.ID_AC_ACD AS ID_AC ' +
        '  FROM fza_atributos_conjuntos_det d ' +
        ' WHERE d.ID_AV_ACD IN (' + sIds + ') ' +
        ' GROUP BY d.ID_AC_ACD ' +
        ' HAVING COUNT(DISTINCT d.ID_AV_ACD) = ' +
          IntToStr(AIds.Count) +
        ' ORDER BY (SELECT COUNT(*) ' +
        '             FROM fza_atributos_conjuntos_det t ' +
        '            WHERE t.ID_AC_ACD = d.ID_AC_ACD) ' +
        ' LIMIT 1';
      Qry.Open;
      if not Qry.Eof then
        Result := Qry.FieldByName('ID_AC').AsInteger;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TGridPivoteVenta.ConjuntoVirtualParaGrupo(ALineaRepr: Integer;
  ATallas: TList<Integer>): Integer;
var
  Qry: TUniQuery;
  Arr: TArrPosConjunto;
  sArt, sKey, sIds: string;
  i: Integer;
  function TallaEnArr(const AArr: TArrPosConjunto;
                      AIdAv: Integer): Boolean;
  var
    j: Integer;
  begin
    Result := False;
    for j := 0 to High(AArr) do
    begin
      if AArr[j].IdAv = AIdAv then
        Result := True;
    end;
  end;
begin
  // Articulos con tallas sueltas en sus SKUs pero SIN conjunto real que
  // las cubra: sin este fallback las columnas de talla no se pintaban
  // nunca (albaranes de compra, 10/07/26). Se fabrica un conjunto
  // VIRTUAL con las tallas de los SKUs del articulo ordenadas por
  // ORDEN_AV y se siembra en la cache del gestor con id negativo: el
  // id jamas llega a SQL y el resto del pivote lo consume tal cual.
  Result := 0;
  Arr := nil;
  sArt := '';
  FPivotArticulo.TryGetValue(ALineaRepr, sArt);
  if (FCfg.Conexion <> nil) and (FGestor <> nil) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      if sArt <> '' then
      begin
        Qry.Connection := FCfg.Conexion;
        Qry.SQL.Text :=
          'SELECT DISTINCT AV.ID_AV, AV.AV, AV.ORDEN_AV ' +
          '  FROM fza_articulos_skus SK ' +
          '  JOIN fza_atributos_sku SA ' +
          '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
          '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
          ' WHERE SK.CODIGO_ART_SKU = :art ' +
          '   AND AV.ID_VA_AV = ''TAL'' ' +
          ' ORDER BY AV.ORDEN_AV, AV.AV';
        Qry.ParamByName('art').AsString := sArt;
        Qry.Open;
        SetLength(Arr, Qry.RecordCount);
        i := 0;
        while not Qry.Eof do
        begin
          Arr[i].IdAv := Qry.FieldByName('ID_AV').AsInteger;
          Arr[i].Valor := Qry.FieldByName('AV').AsString;
          Inc(i);
          Qry.Next;
        end;
        Qry.Close;
      end;
      // Red de seguridad: tallas del grupo que no salieron por el
      // articulo (articulo de la linea sin SKUs propios, o SKU colgado
      // de otro padre) se anexan al final para que su celda tenga
      // columna donde pintarse.
      if ATallas <> nil then
      begin
        sIds := '';
        for i := 0 to ATallas.Count - 1 do
        begin
          if not TallaEnArr(Arr, ATallas[i]) then
          begin
            if sIds <> '' then
              sIds := sIds + ',';
            sIds := sIds + IntToStr(ATallas[i]);
          end;
        end;
        if sIds <> '' then
        begin
          Qry.Connection := FCfg.Conexion;
          Qry.SQL.Text :=
            'SELECT ID_AV, AV, ORDEN_AV ' +
            '  FROM fza_atributos_valores ' +
            ' WHERE ID_AV IN (' + sIds + ') ' +
            ' ORDER BY ORDEN_AV, AV';
          Qry.Open;
          i := Length(Arr);
          SetLength(Arr, i + Qry.RecordCount);
          while not Qry.Eof do
          begin
            Arr[i].IdAv := Qry.FieldByName('ID_AV').AsInteger;
            Arr[i].Valor := Qry.FieldByName('AV').AsString;
            Inc(i);
            Qry.Next;
          end;
        end;
      end;
    finally
      FreeAndNil(Qry);
    end;
    if Length(Arr) > 0 then
    begin
      // Un id virtual por LISTA de tallas (clave = ids ordenados): dos
      // grupos con las mismas tallas comparten conjunto y captions.
      sKey := '';
      for i := 0 to High(Arr) do
        sKey := sKey + IntToStr(Arr[i].IdAv) + ',';
      if not FConjuntoVirtualIds.TryGetValue(sKey, Result) then
      begin
        Result := FProxConjuntoVirtual;
        Dec(FProxConjuntoVirtual);
        FConjuntoVirtualIds.Add(sKey, Result);
      end;
      // Re-registrar SIEMPRE: CrearGestor recrea el gestor con la
      // cache vacia en cada Construir del modo.
      FGestor.RegistrarConjuntoVirtual(Result, Arr);
      if Log <> nil then
        Log.LogInfo(Format(
          'PivVenta.Cache: conjunto VIRTUAL %d (%d tallas) para ' +
          'art=%s sin conjunto global que las cubra.',
          [Result, Length(Arr), sArt]));
    end;
  end;
end;

procedure TGridPivoteVenta.CargarCachePivot;
var
  Ds: TDataSet;
  Bm: TBookmark;
  DictRepr: TDictionary<string, Integer>;
  DictTallas: TObjectDictionary<Integer, TList<Integer>>;
  ParTallas: TPair<Integer, TList<Integer>>;
  Info: TSkuPivoteVentaInfo;
  sArt, sSku, sKey, sLinea, sPrefijo, sVarSku, sTipoCantidad: string;
  iLinea, iLineaRepr, iAc, iMaxBandas: Integer;
  rPedida, rEntregada, rAAlbaranar, rPrecio, rUds: Double;
  iKeyPivot: Int64;
  bFiltrado: Boolean;
begin
  FPivotLineasRepr.Clear;
  FLineaBasePivot.Clear;
  FLineaBanda.Clear;
  FPivotCantPedida.Clear;
  FPivotCantEntregada.Clear;
  FPivotCantAAlbaranar.Clear;
  FPivotUdsGrupo.Clear;
  FPivotIdAc.Clear;
  FPivotSinTalla.Clear;
  FPivotArticulo.Clear;
  FPivotTipoCantidad.Clear;
  FPivotColorAv.Clear;
  FPivotColorTexto.Clear;
  FPivotColorCodigo.Clear;
  FPivotSkuPrefijo.Clear;
  FPivotVarSku.Clear;
  FCeldaSku.Clear;
  FCeldaLinea.Clear;
  FCeldaAlmacen.Clear;
  FHayTipoCantidadEspecial := False;
  // Bandas visuales por grupo: 3 en pedidos (Pedido / A albaranar /
  // Pendiente), 1 en documentos de cantidad unica (BandaUnica).
  iMaxBandas := 3;
  if FCfg.BandaUnica then
    iMaxBandas := 1;
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and (not Ds.IsEmpty) and
     (not EsInsercionVacia(Ds)) then
  begin
    DictRepr := TDictionary<string, Integer>.Create;
    DictTallas := TObjectDictionary<Integer, TList<Integer>>.Create(
      [doOwnsValues]);
    Bm := Ds.GetBookmark;
    bFiltrado := Ds.Filtered;
    FEnRecarga := True;
    Ds.DisableControls;
    try
      Ds.Filtered := False;
      Ds.First;
      while not Ds.Eof do
      begin
        sArt := CampoTexto(Ds, FCfg.FieldArt);
        sLinea := CampoTexto(Ds, FCfg.FieldLinea);
        iLinea := StrToIntDef(sLinea, 0);
        rPrecio := CampoFloat(Ds, FCfg.FieldPrecioBase);
        if (sArt <> '') and (iLinea > 0) then
        begin
          ObtenerInfoLinea(Ds, sSku, Info);
          sTipoCantidad := CampoTexto(Ds, FCfg.FieldTipoCantidad);
          if sTipoCantidad = '' then
            sTipoCantidad := 'Uds';
          if not EsTipoCantidadPredeterminado(sTipoCantidad) then
            FHayTipoCantidadEspecial := True;
          sKey := sArt + '|' + IntToStr(Info.ColorAv) + '|' +
            FloatToStrF(rPrecio, ffGeneral, 15, 4);
          // Linea SIN talla resoluble: fila propia. Si fusionaran por
          // articulo+color+precio, varias lineas sin SKU del mismo
          // articulo se machacarian entre si en la celda 'Cantidad'
          // (solo se veia la ultima, pedidos de compra 09/07/26).
          if Info.TallaAv <= 0 then
            sKey := sKey + '|L' + sLinea;
          if not DictRepr.TryGetValue(sKey, iLineaRepr) then
          begin
            iLineaRepr := iLinea;
            DictRepr.Add(sKey, iLineaRepr);
            // Traza de diagnostico (fase de integracion).
            if Log <> nil then
              Log.LogInfo(Format(
                'PivVenta.Cache: repr=%d art=%s tallaAv=%d sku=%s',
                [iLineaRepr, sArt, Info.TallaAv, sSku]));
            FPivotArticulo.AddOrSetValue(iLineaRepr, sArt);
            FPivotTipoCantidad.AddOrSetValue(iLineaRepr, sTipoCantidad);
            FPivotColorAv.AddOrSetValue(iLineaRepr, Info.ColorAv);
            FPivotColorTexto.AddOrSetValue(iLineaRepr, Info.ColorTexto);
            FPivotColorCodigo.AddOrSetValue(iLineaRepr, Info.ColorCodigo);
            sPrefijo := PrefijoSkuTalla(sSku);
            if sPrefijo = '' then
              sPrefijo := sArt;
            FPivotSkuPrefijo.AddOrSetValue(iLineaRepr, sPrefijo);
            sVarSku := Info.VarSku;
            if sVarSku = '' then
              sVarSku := 'TC';
            FPivotVarSku.AddOrSetValue(iLineaRepr, sVarSku);
            DictTallas.Add(iLineaRepr, TList<Integer>.Create);
            FPivotLineasRepr.Add(LineaVistaBanda(iLineaRepr, bpvPedida));
            FLineaBasePivot.AddOrSetValue(
              LineaVistaBanda(iLineaRepr, bpvPedida), iLineaRepr);
            FLineaBanda.AddOrSetValue(
              LineaVistaBanda(iLineaRepr, bpvPedida), bpvPedida);
            if iMaxBandas >= 2 then
            begin
              FPivotLineasRepr.Add(
                LineaVistaBanda(iLineaRepr, bpvEntregada));
              FLineaBasePivot.AddOrSetValue(
                LineaVistaBanda(iLineaRepr, bpvEntregada), iLineaRepr);
              FLineaBanda.AddOrSetValue(
                LineaVistaBanda(iLineaRepr, bpvEntregada), bpvEntregada);
            end;
            if iMaxBandas >= 3 then
            begin
              FPivotLineasRepr.Add(
                LineaVistaBanda(iLineaRepr, bpvPendiente));
              FLineaBasePivot.AddOrSetValue(
                LineaVistaBanda(iLineaRepr, bpvPendiente), iLineaRepr);
              FLineaBanda.AddOrSetValue(
                LineaVistaBanda(iLineaRepr, bpvPendiente), bpvPendiente);
            end;
          end;
          if not EsTipoCantidadPredeterminado(sTipoCantidad) then
            FPivotTipoCantidad.AddOrSetValue(iLineaRepr, sTipoCantidad);
          rPedida := CampoFloat(Ds, FCfg.FieldCantidadPedida);
          rEntregada := CampoFloat(Ds, FCfg.FieldCantidadEntregada);
          rAAlbaranar := CampoFloat(Ds, FCfg.FieldCantidadAAlbaranar);
          // Suma de unidades del grupo para la columna Total de la
          // vista en documentos de banda unica.
          if not FPivotUdsGrupo.TryGetValue(iLineaRepr, rUds) then
            rUds := 0;
          FPivotUdsGrupo.AddOrSetValue(iLineaRepr, rUds + rPedida);
          if Info.TallaAv > 0 then
          begin
            if not DictTallas[iLineaRepr].Contains(Info.TallaAv) then
              DictTallas[iLineaRepr].Add(Info.TallaAv);
            iKeyPivot := Int64(iLineaRepr) * 100000 + Info.TallaAv;
            FPivotCantPedida.AddOrSetValue(iKeyPivot, rPedida);
            FPivotCantEntregada.AddOrSetValue(iKeyPivot, rEntregada);
            FPivotCantAAlbaranar.AddOrSetValue(iKeyPivot, rAAlbaranar);
            FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
            FCeldaLinea.AddOrSetValue(iKeyPivot, sLinea);
            FCeldaAlmacen.AddOrSetValue(iKeyPivot,
              CampoTexto(Ds, FCfg.FieldAlmacen));
          end
          else
          begin
            FPivotSinTalla.AddOrSetValue(iLineaRepr, True);
            iKeyPivot := Int64(iLineaRepr) * 100000 + ID_AV_SIN_TALLA;
            FPivotCantPedida.AddOrSetValue(iKeyPivot, rPedida);
            FPivotCantEntregada.AddOrSetValue(iKeyPivot, rEntregada);
            FPivotCantAAlbaranar.AddOrSetValue(iKeyPivot, rAAlbaranar);
            FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
            FCeldaLinea.AddOrSetValue(iKeyPivot, sLinea);
            FCeldaAlmacen.AddOrSetValue(iKeyPivot,
              CampoTexto(Ds, FCfg.FieldAlmacen));
          end;
        end;
        Ds.Next;
      end;
      for ParTallas in DictTallas do
      begin
        iAc := BuscarConjuntoParaIds(ParTallas.Value);
        // Sin conjunto real que cubra las tallas del grupo (articulo
        // sin conjunto asignado): conjunto VIRTUAL con las tallas de
        // los SKUs del articulo. Sin el, las columnas de talla no se
        // pintaban nunca (albaranes de compra, 10/07/26).
        if (iAc = 0) and (ParTallas.Value.Count > 0) then
          iAc := ConjuntoVirtualParaGrupo(ParTallas.Key, ParTallas.Value);
        if iAc <> 0 then
          FPivotIdAc.AddOrSetValue(ParTallas.Key, iAc)
        else if (ParTallas.Value.Count > 0) and (Log <> nil) then
        begin
          // Error DOCUMENTADO: sin conjunto (ni real ni virtual) que
          // cubra las tallas del grupo, sus celdas no tienen columna
          // donde pintarse.
          sArt := '';
          FPivotArticulo.TryGetValue(ParTallas.Key, sArt);
          Log.LogWarning(Format(
            'PivVenta.Cache: NINGUN conjunto global cubre las %d ' +
            'tallas del grupo repr=%d (art=%s); sus cantidades no se ' +
            'pintaran en columnas de talla. Revisar ' +
            'fza_atributos_conjuntos / fza_atributos_sku del articulo.',
            [ParTallas.Value.Count, ParTallas.Key, sArt]));
        end;
      end;
      if Ds.BookmarkValid(Bm) then
        Ds.GotoBookmark(Bm);
      Ds.Filtered := bFiltrado;
    finally
      Ds.EnableControls;
      Ds.FreeBookmark(Bm);
      FEnRecarga := False;
      FreeAndNil(DictTallas);
      FreeAndNil(DictRepr);
    end;
    AjustarAAlbaranarCache;
  end;
end;

procedure TGridPivoteVenta.AplicarVisibilidadTipoCantidad;
begin
  if FColTipoCantidad <> nil then
  begin
    if FCfg.BandaUnica then
      FColTipoCantidad.Visible := FHayTipoCantidadEspecial
    else
      FColTipoCantidad.Visible := True;
    FColTipoCantidad.VisibleForCustomization :=
      FColTipoCantidad.Visible;
  end;
end;

procedure TGridPivoteVenta.AplicarVisibilidadTallas;
var
  Par: TPair<Integer, Integer>;
  Arr: TArrPosConjunto;
  i: Integer;
  iMax: Integer;
begin
  iMax := 0;
  for Par in FPivotIdAc do
  begin
    Arr := FGestor.GetPosicionesConjunto(Par.Value);
    if Length(Arr) > iMax then
      iMax := Length(Arr);
  end;
  if FPivotSinTalla.Count > 0 then
  begin
    if iMax < 1 then
      iMax := 1;
  end;
  if iMax > FCfg.MaxColumnas then
    iMax := FCfg.MaxColumnas;
  for i := 0 to High(FColumnasTallas) do
  begin
    FColumnasTallas[i].Visible := i < iMax;
    if not FColumnasTallas[i].Visible then
      FColumnasTallas[i].Caption := '·';
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TGridPivoteVenta.ColocarBloqueColumnas;
var
  i, iBase, iDestino: Integer;
  bColocado: Boolean;
begin
  // El bloque de entrada del pivote (LineaVista oculta, Articulo, Color,
  // Tipo y tallas) va SIEMPRE delante de las columnas del documento,
  // justo detras del Nro de linea del host (Index 0). Se reaplica en
  // cada recarga: es idempotente y corrige cualquier recolocacion
  // externa (perfiles de usuario, reconstrucciones del host, 09/07/26).
  if (FConfig.View <> nil) and (FColLineaVista <> nil) and
     (FColArticulo <> nil) and (FColColor <> nil) and
     (FColTipoCantidad <> nil) then
  begin
    iBase := 1;
    if FConfig.View.ColumnCount <= 1 then
      iBase := 0;
    bColocado := (FColLineaVista.Index = iBase) and
                 (FColArticulo.Index = iBase + 1) and
                 (FColColor.Index = iBase + 2) and
                 (FColTipoCantidad.Index = iBase + 3);
    if bColocado then
    begin
      for i := 0 to High(FColumnasTallas) do
        if (FColumnasTallas[i] <> nil) and
           (FColumnasTallas[i].Index <> iBase + 4 + i) then
          bColocado := False;
    end;
    if not bColocado then
    begin
      FConfig.View.BeginUpdate;
      try
        // Asignacion en orden de destino ascendente: cada Index inserta
        // la columna en su posicion final y desplaza el resto.
        iDestino := iBase;
        FColLineaVista.Index := iDestino;
        Inc(iDestino);
        FColArticulo.Index := iDestino;
        Inc(iDestino);
        FColColor.Index := iDestino;
        Inc(iDestino);
        FColTipoCantidad.Index := iDestino;
        Inc(iDestino);
        for i := 0 to High(FColumnasTallas) do
        begin
          if FColumnasTallas[i] <> nil then
          begin
            FColumnasTallas[i].Index := iDestino;
            Inc(iDestino);
          end;
        end;
      finally
        FConfig.View.EndUpdate;
      end;
    end;
  end;
end;

procedure TGridPivoteVenta.ActualizarCaptionsLineaActiva;
var
  iLinea, iLineaVista, iAc, i: Integer;
  Arr: TArrPosConjunto;
begin
  iLinea := 0;
  iLineaVista := 0;
  if (FConfig.View <> nil) and (FConfig.View.Controller <> nil) then
    iLineaVista := LineaDesdeRecord(FConfig.View.Controller.FocusedRecord);
  iLinea := ObtenerLineaBase(iLineaVista);
  iAc := 0;
  if iLinea > 0 then
    FPivotIdAc.TryGetValue(iLinea, iAc);
  // <> 0 y no > 0: los conjuntos VIRTUALES llevan id negativo y sus
  // captions se resuelven desde la cache del gestor igual que los
  // reales (sin esto, las columnas salian visibles pero rotuladas '·').
  if iAc <> 0 then
    Arr := FGestor.GetPosicionesConjunto(iAc)
  else
    Arr := nil;
  for i := 0 to High(FColumnasTallas) do
  begin
    if FColumnasTallas[i].Visible then
    begin
      if i < Length(Arr) then
        FColumnasTallas[i].Caption := Arr[i].Valor
      else if (i = 0) and FPivotSinTalla.ContainsKey(iLinea) then
        FColumnasTallas[i].Caption := 'Cantidad'
      else
        FColumnasTallas[i].Caption := '·';
    end;
  end;
end;

function TGridPivoteVenta.PendienteBaseCelda(AKey: Int64): Double;
var
  rPedida, rEntregada: Double;
begin
  rPedida := 0;
  rEntregada := 0;
  FPivotCantPedida.TryGetValue(AKey, rPedida);
  FPivotCantEntregada.TryGetValue(AKey, rEntregada);
  Result := rPedida - rEntregada;
  if Result < 0 then
    Result := 0;
end;

function TGridPivoteVenta.PendienteCelda(AKey: Int64): Double;
begin
  Result := PendienteBaseCelda(AKey) - AAlbaranarCelda(AKey);
  if Result < 0 then
    Result := 0;
end;

function TGridPivoteVenta.AAlbaranarCelda(AKey: Int64): Double;
begin
  Result := 0;
  FPivotCantAAlbaranar.TryGetValue(AKey, Result);
end;

function TGridPivoteVenta.LineaVistaBanda(ALineaBase: Integer;
  ABanda: TBandaPivoteVenta): Integer;
begin
  Result := (ALineaBase * 10) + Ord(ABanda);
end;

procedure TGridPivoteVenta.AjustarAAlbaranarCache;
var
  Borrar: TList<Int64>;
  Cambiar: TDictionary<Int64, Double>;
  Par: TPair<Int64, Double>;
  iKey: Int64;
  rMax, rValor: Double;
begin
  Borrar := TList<Int64>.Create;
  Cambiar := TDictionary<Int64, Double>.Create;
  try
    for Par in FPivotCantAAlbaranar do
    begin
      if not FCeldaLinea.ContainsKey(Par.Key) then
        Borrar.Add(Par.Key)
      else
      begin
        rMax := PendienteBaseCelda(Par.Key);
        rValor := Par.Value;
        if rValor > rMax then
          rValor := rMax;
        if rValor <= 0 then
          Borrar.Add(Par.Key)
        else if Abs(rValor - Par.Value) > 0.000001 then
          Cambiar.AddOrSetValue(Par.Key, rValor);
      end;
    end;
    for iKey in Borrar do
      FPivotCantAAlbaranar.Remove(iKey);
    for Par in Cambiar do
      FPivotCantAAlbaranar.AddOrSetValue(Par.Key, Par.Value);
  finally
    FreeAndNil(Cambiar);
    FreeAndNil(Borrar);
  end;
end;

function TGridPivoteVenta.ObtenerLineaBase(ALinea: Integer): Integer;
begin
  if not FLineaBasePivot.TryGetValue(ALinea, Result) then
    Result := ALinea;
end;

function TGridPivoteVenta.BandaDesdeLinea(
  ALinea: Integer): TBandaPivoteVenta;
begin
  if not FLineaBanda.TryGetValue(ALinea, Result) then
    Result := bpvPedida;
end;

function TGridPivoteVenta.TextoBanda(
  ABanda: TBandaPivoteVenta): string;
begin
  if FCfg.BandaUnica then
    Result := 'Cantidad'
  else
    case ABanda of
      bpvPedida:
        Result := 'Pedido';
      bpvEntregada:
        begin
          Result := FCfg.TextoBandaAAlbaranar;
          if Result = '' then
            Result := 'A albaranar';
        end;
    else
      Result := 'Pendiente';
    end;
end;

function TGridPivoteVenta.EsTipoCantidadPredeterminado(
  const AValor: string): Boolean;
var
  sValor: string;
begin
  sValor := Trim(AValor);
  Result := (sValor = '') or SameText(sValor, 'Uds') or
            SameText(sValor, 'Ud') or SameText(sValor, 'Unidad') or
            SameText(sValor, 'Unidades') or SameText(sValor, 'Cantidad');
end;

function TGridPivoteVenta.TextoTipoCantidad(ALineaBase: Integer;
  ABanda: TBandaPivoteVenta): string;
var
  sTipoCantidad: string;
begin
  if not FPivotTipoCantidad.TryGetValue(ALineaBase, sTipoCantidad) then
    sTipoCantidad := 'Uds';
  if FCfg.BandaUnica then
    Result := sTipoCantidad
  else
  begin
    Result := TextoBanda(ABanda);
    if not EsTipoCantidadPredeterminado(sTipoCantidad) then
      Result := Result + ' - ' + sTipoCantidad;
  end;
end;

function TGridPivoteVenta.ValorCantidadBanda(AKey: Int64;
  ABanda: TBandaPivoteVenta): Double;
begin
  Result := 0;
  case ABanda of
    bpvPedida:
      FPivotCantPedida.TryGetValue(AKey, Result);
    bpvEntregada:
      Result := AAlbaranarCelda(AKey);
  else
    Result := PendienteCelda(AKey);
  end;
end;

function TGridPivoteVenta.BuscarColumnaTallaDesde(ALineaBase,
  AIndiceInicial: Integer; out ACol: TcxGridColumn): Boolean;
var
  i, iIdAv: Integer;
begin
  Result := False;
  ACol := nil;
  i := AIndiceInicial;
  if i < 0 then
    i := 0;
  while (not Result) and (i <= High(FColumnasTallas)) do
  begin
    if (FColumnasTallas[i] <> nil) and FColumnasTallas[i].Visible and
       TallaAvDesdeColumna(ALineaBase, FColumnasTallas[i], iIdAv) then
    begin
      ACol := FColumnasTallas[i];
      Result := True;
    end;
    Inc(i);
  end;
end;

function TGridPivoteVenta.BuscarRecordPorLineaVista(ALineaVista: Integer;
  out ARecordIndex: Integer): Boolean;
var
  ColLinea: TcxGridColumn;
  i, iLinea: Integer;
  vLinea: Variant;
begin
  Result := False;
  ARecordIndex := -1;
  ColLinea := nil;
  if FConfig.View <> nil then
  begin
    ColLinea := FConfig.View.GetColumnByFieldName(CAMPO_LINEA_VISTA);
    if ColLinea = nil then
      ColLinea := FConfig.View.GetColumnByFieldName(FCfg.FieldLinea);
  end;
  if ColLinea <> nil then
  begin
    i := 0;
    while (not Result) and
          (i < FConfig.View.DataController.RecordCount) do
    begin
      vLinea := FConfig.View.DataController.Values[i, ColLinea.Index];
      iLinea := StrToIntDef(VarToStr(vLinea), 0);
      if iLinea = ALineaVista then
      begin
        ARecordIndex := i;
        Result := True;
      end;
      Inc(i);
    end;
  end;
end;

procedure TGridPivoteVenta.PublicarCantidadesPivot;
var
  ColLinea: TcxGridColumn;
  vLinea: Variant;
  iLinea, iLineaVista, iAc, recIdx, i, iKey: Integer;
  iKeyPivot: Int64;
  rCant: Double;
  Arr: TArrPosConjunto;
  Banda: TBandaPivoteVenta;
begin
  if (FConfig.View <> nil) and (not FActualizandoGrid) then
  begin
    ColLinea := FConfig.View.GetColumnByFieldName(CAMPO_LINEA_VISTA);
    if ColLinea = nil then
      ColLinea := FConfig.View.GetColumnByFieldName(FCfg.FieldLinea);
    if ColLinea <> nil then
    begin
      FActualizandoGrid := True;
      FConfig.View.DataController.BeginUpdate;
      try
        for recIdx := 0 to FConfig.View.DataController.RecordCount - 1 do
        begin
          vLinea := FConfig.View.DataController.Values[recIdx,
                                                       ColLinea.Index];
          iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
          iLinea := ObtenerLineaBase(iLineaVista);
          if iLinea > 0 then
          begin
            Banda := BandaDesdeLinea(iLineaVista);
            FConfig.View.DataController.Values[recIdx,
              FColTipoCantidad.Index] := TextoTipoCantidad(iLinea, Banda);
            for i := 0 to High(FColumnasTallas) do
            begin
              if FColumnasTallas[i].Visible then
                FConfig.View.DataController.Values[recIdx,
                  FColumnasTallas[i].Index] := Null;
            end;
            if FPivotColorTexto.ContainsKey(iLinea) then
              FConfig.View.DataController.Values[recIdx, FColColor.Index] :=
                FPivotColorTexto[iLinea];
            if FPivotSinTalla.ContainsKey(iLinea) then
            begin
              iKeyPivot := Int64(iLinea) * 100000 + ID_AV_SIN_TALLA;
              rCant := ValorCantidadBanda(iKeyPivot, Banda);
              if rCant <> 0 then
                FConfig.View.DataController.Values[recIdx,
                  FColumnasTallas[0].Index] := rCant
              else
                FConfig.View.DataController.Values[recIdx,
                  FColumnasTallas[0].Index] := Null;
            end
            else if FPivotIdAc.TryGetValue(iLinea, iAc) then
            begin
              Arr := FGestor.GetPosicionesConjunto(iAc);
              for i := 0 to High(Arr) do
              begin
                if i >= Length(FColumnasTallas) then
                  Break;
                iKey := Arr[i].IdAv;
                iKeyPivot := Int64(iLinea) * 100000 + iKey;
                rCant := ValorCantidadBanda(iKeyPivot, Banda);
                if rCant <> 0 then
                  FConfig.View.DataController.Values[recIdx,
                    FColumnasTallas[i].Index] := rCant
                else
                  FConfig.View.DataController.Values[recIdx,
                    FColumnasTallas[i].Index] := Null;
              end;
            end;
          end;
        end;
      finally
        FConfig.View.DataController.EndUpdate;
        FActualizandoGrid := False;
      end;
    end;
  end;
end;

procedure TGridPivoteVenta.RecargarYPublicar;
var
  Ds: TDataSet;
begin
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active then
  begin
    CargarCachePivot;
    ReconstruirVistaTemporal;
    AplicarVisibilidadTipoCantidad;
    AplicarVisibilidadTallas;
    ColocarBloqueColumnas;
    PublicarCantidadesPivot;
    // Traza de diagnostico (fase de integracion): si el CDS de la
    // vista tiene mas filas de las que el grid publica, hay un filtro
    // o una sincronizacion comiendose filas a nivel de view.
    if Log <> nil then
      Log.LogInfo(Format(
        'PivVenta.Publicar: filasVista=%d filasGrid=%d filtroView="%s"',
        [FCdsVista.RecordCount,
         FConfig.View.DataController.RecordCount,
         FConfig.View.DataController.Filter.FilterText]));
    // Primera publicacion tras Construir: arrancar viendo el grid
    // desde la primera fila (el scroll heredado ocultaba las primeras
    // filas pivotadas y parecian perdidas).
    if FScrollInicialPendiente and
       (FConfig.View.DataController.RecordCount > 0) then
    begin
      FScrollInicialPendiente := False;
      FConfig.View.DataController.FocusedRecordIndex := 0;
      FConfig.View.Controller.TopRecordIndex := 0;
    end;
  end;
end;

function TGridPivoteVenta.LineaDesdeRecord(
  ARecord: TcxCustomGridRecord): Integer;
var
  ColLinea: TcxGridColumn;
  vLinea: Variant;
begin
  Result := 0;
  if (ARecord <> nil) and (FConfig.View <> nil) then
  begin
    try
      ColLinea := FConfig.View.GetColumnByFieldName(CAMPO_LINEA_VISTA);
      if ColLinea = nil then
        ColLinea := FConfig.View.GetColumnByFieldName(FCfg.FieldLinea);
    except
      ColLinea := nil;
    end;
    if ColLinea <> nil then
    begin
      try
        vLinea := ARecord.Values[ColLinea.Index];
        Result := StrToIntDef(VarToStr(vLinea), 0);
      except
        Result := 0;
      end;
    end;
  end;
end;

function TGridPivoteVenta.EsColumnaTalla(
  AItem: TcxCustomGridTableItem): Boolean;
begin
  Result := (AItem <> nil) and (AItem.Tag >= 1) and
            (AItem.Tag <= Length(FColumnasTallas)) and
            (FColumnasTallas[AItem.Tag - 1] = AItem);
end;

function TGridPivoteVenta.TallaAvDesdeColumna(ALinea: Integer;
  ACol: TcxGridColumn; out AIdAv: Integer): Boolean;
var
  iAc, iLineaBase: Integer;
  Arr: TArrPosConjunto;
begin
  Result := False;
  AIdAv := 0;
  iLineaBase := ObtenerLineaBase(ALinea);
  if (iLineaBase > 0) and (ACol <> nil) and EsColumnaTalla(ACol) then
  begin
    if FPivotSinTalla.ContainsKey(iLineaBase) then
    begin
      Result := ACol.Tag = 1;
      if Result then
        AIdAv := ID_AV_SIN_TALLA;
    end
    else if FPivotIdAc.TryGetValue(iLineaBase, iAc) then
    begin
      Arr := FGestor.GetPosicionesConjunto(iAc);
      Result := ACol.Tag <= Length(Arr);
      if Result then
        AIdAv := Arr[ACol.Tag - 1].IdAv;
    end;
  end;
end;

function TGridPivoteVenta.ValorEditor(ASender: TObject;
  AValorFallback: Variant): Double;
var
  vValor: Variant;
begin
  Result := 0;
  vValor := AValorFallback;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor)) and
     (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditingValue;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor)) and
     (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditValue;
  if not (VarIsNull(vValor) or VarIsEmpty(vValor) or VarIsClear(vValor)) then
  begin
    if VarIsNumeric(vValor) then
      Result := vValor
    else
      Result := StrToFloatDef(VarToStr(vValor), 0);
  end;
end;

procedure TGridPivoteVenta.ViewEditing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  iLinea, iIdAv: Integer;
begin
  if EsColumnaTalla(AItem) then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := TallaAvDesdeColumna(iLinea, TcxGridColumn(AItem), iIdAv);
  end
  else if AItem = FColArticulo then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := (iLinea = 0) or (BandaDesdeLinea(iLinea) = bpvPedida);
  end;
end;

procedure TGridPivoteVenta.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TGridPivoteVenta.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
var
  Rec: TcxCustomGridRecord;
  iLinea, iLineaBase, iIdAv: Integer;
  iKey: Int64;
  Banda: TBandaPivoteVenta;
  rValor: Double;
begin
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(AEdit);
  if EsColumnaTalla(AItem) and (Sender <> nil) and (AEdit <> nil) then
  begin
    Rec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(Rec);
    iLineaBase := ObtenerLineaBase(iLinea);
    Banda := BandaDesdeLinea(iLinea);
    if TallaAvDesdeColumna(iLineaBase, TcxGridColumn(AItem), iIdAv) then
    begin
      iKey := Int64(iLineaBase) * 100000 + iIdAv;
      rValor := ValorCantidadBanda(iKey, Banda);
      if Abs(rValor) > 0.000001 then
        AEdit.EditValue := rValor
      else
        AEdit.EditValue := Null;
    end;
  end;
  if AEdit is TWinControl then
    THackWinControl(AEdit).OnExit := EditorSalir;
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

procedure TGridPivoteVenta.ViewEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  sEntrada: string;
begin
  if (AItem = FColArticulo) and
     ((Key = VK_F3) or ((Key = VK_RETURN) and (ssCtrl in Shift))) then
  begin
    Key := 0;
    ArticuloButtonClick(AEdit, 0);
  end
  else if (Key = VK_RETURN) and GestionarEnterAAlbaranar(Sender, AItem) then
    Key := 0
  else if (Key = VK_RETURN) and (AItem = FColArticulo) then
  begin
    sEntrada := Trim(VarToStr(AEdit.EditingValue));
    if sEntrada <> '' then
      Sender.Controller.EditingController.HideEdit(True);
    Key := 0;
  end;
end;

function TGridPivoteVenta.GestionarEnterAAlbaranar(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem): Boolean;
var
  ColDest: TcxGridColumn;
  ColLinea: TcxGridColumn;
  Rec: TcxCustomGridRecord;
  iLinea, iLineaBase, iLineaVistaDest, iTagDest: Integer;
  iRecAct, iRecDest, iRec, iLineaVista, iLineaBaseDest: Integer;
  vLinea: Variant;
  bHayDestino: Boolean;
begin
  Result := False;
  bHayDestino := False;
  iLineaVistaDest := 0;
  iTagDest := 0;
  if (Sender <> nil) and EsColumnaTalla(AItem) then
  begin
    Rec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(Rec);
    iLineaBase := ObtenerLineaBase(iLinea);
    if (iLineaBase > 0) and (BandaDesdeLinea(iLinea) = bpvEntregada) then
    begin
      Result := True;
      if BuscarColumnaTallaDesde(iLineaBase,
         TcxGridColumn(AItem).Tag, ColDest) then
      begin
        iLineaVistaDest := iLinea;
        iTagDest := ColDest.Tag;
        bHayDestino := True;
      end
      else
      begin
        ColLinea := FConfig.View.GetColumnByFieldName(CAMPO_LINEA_VISTA);
        if ColLinea = nil then
          ColLinea := FConfig.View.GetColumnByFieldName(FCfg.FieldLinea);
        if ColLinea <> nil then
        begin
          iRecAct := Sender.DataController.FocusedRecordIndex;
          iRec := iRecAct + 1;
          while (not bHayDestino) and
                (iRec < Sender.DataController.RecordCount) do
          begin
            vLinea := Sender.DataController.Values[iRec, ColLinea.Index];
            iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
            iLineaBaseDest := ObtenerLineaBase(iLineaVista);
            if (iLineaBaseDest > 0) and
               (BandaDesdeLinea(iLineaVista) = bpvEntregada) and
               BuscarColumnaTallaDesde(iLineaBaseDest, 0, ColDest) then
            begin
              iLineaVistaDest := iLineaVista;
              iTagDest := ColDest.Tag;
              bHayDestino := True;
            end;
            Inc(iRec);
          end;
        end;
      end;
      if Sender.Controller.EditingController.IsEditing then
        Sender.Controller.EditingController.HideEdit(True);
      if bHayDestino and
         BuscarRecordPorLineaVista(iLineaVistaDest, iRecDest) then
      begin
        Sender.DataController.FocusedRecordIndex := iRecDest;
        if (iTagDest > 0) and (iTagDest <= Length(FColumnasTallas)) then
        begin
          Sender.Controller.FocusedItem := FColumnasTallas[iTagDest - 1];
          try
            Sender.Controller.EditingController.ShowEdit;
          except
            on E: EInvalidOperation do
              ;
          end;
        end;
      end;
    end;
  end;
end;

procedure TGridPivoteVenta.ViewFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var
  Ds: TDataSet;
  iLineaVista, iLineaBase: Integer;
begin
  if not FActualizandoGrid then
  begin
    iLineaVista := LineaDesdeRecord(AFocusedRecord);
    iLineaBase := ObtenerLineaBase(iLineaVista);
    Ds := CdsLineas;
    LocalizarLineaReal(Ds, iLineaBase);
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TGridPivoteVenta.CustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  Col: TcxGridColumn;
  iLinea, iLineaBase, iIdAv: Integer;
  iKey: Int64;
  rValor, rPedida: Double;
  Banda: TBandaPivoteVenta;
  sArt, sColorCodigo, sColorTexto, sValorColor: string;
begin
  ADone := False;
  if (AViewInfo.Item is TcxGridColumn) and
     (AViewInfo.GridRecord <> nil) then
  begin
    Col := TcxGridColumn(AViewInfo.Item);
    iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
    iLineaBase := ObtenerLineaBase(iLinea);
    if Col = FColTipoCantidad then
    begin
      PintarCeldaTipoCantidad(ACanvas, AViewInfo);
      ADone := True;
    end
    else if Col = FColColor then
    begin
      sColorCodigo := '';
      sColorTexto := '';
      sArt := '';
      FPivotArticulo.TryGetValue(iLineaBase, sArt);
      FPivotColorCodigo.TryGetValue(iLineaBase, sColorCodigo);
      FPivotColorTexto.TryGetValue(iLineaBase, sColorTexto);
      sValorColor := sColorTexto;
      if sValorColor = '' then
        sValorColor := sColorCodigo;
      if PintarCeldaSwatchArticuloSiAplica(
           ACanvas, AViewInfo, sArt, sValorColor, nil) then
        ADone := True;
    end
    else if EsColumnaTalla(Col) then
    begin
      if TallaAvDesdeColumna(iLineaBase, Col, iIdAv) then
      begin
        Banda := BandaDesdeLinea(iLinea);
        iKey := Int64(iLineaBase) * 100000 + iIdAv;
        rValor := ValorCantidadBanda(iKey, Banda);
        rPedida := 0;
        FPivotCantPedida.TryGetValue(iKey, rPedida);
        PintarCeldaTallaCantidad(ACanvas, AViewInfo, rValor, Banda,
                                 rPedida > 0);
        ADone := True;
      end
      else
      begin
        ACanvas.Brush.Color := $00E8E8E8;
        ACanvas.FillRect(AViewInfo.Bounds);
        ADone := True;
      end;
    end;
  end;
end;

procedure TGridPivoteVenta.PintarCeldaTallaCantidad(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; AValor: Double;
  ABanda: TBandaPivoteVenta; AMostrarCero: Boolean);
var
  RectTexto: TRect;
  sTexto: string;
begin
  if Abs(AValor) > 0.000001 then
    sTexto := FormatFloat('#,##0.##', AValor)
  else if (ABanda <> bpvPedida) and AMostrarCero then
    sTexto := '0'
  else
    sTexto := '';
  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(AViewInfo.Bounds);
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  if AViewInfo.GridRecord.Selected then
    ACanvas.Font.Color := AViewInfo.Params.TextColor
  else
  begin
    case ABanda of
      bpvEntregada:
        ACanvas.Font.Color := clGreen;
      bpvPendiente:
        ACanvas.Font.Color := clBlue;
    else
      ACanvas.Font.Color := clWindowText;
    end;
  end;
  if ABanda <> bpvPedida then
    ACanvas.Font.Style := [fsBold];
  RectTexto := AViewInfo.Bounds;
  InflateRect(RectTexto, -4, 0);
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto), RectTexto,
           DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TGridPivoteVenta.PintarCeldaTipoCantidad(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo);
var
  b: TRect;
  rectTexto: TRect;
  iFontHeight: Integer;
  cFontColor: TColor;
  fsFontStyle: TFontStyles;
  iLinea: Integer;
  Banda: TBandaPivoteVenta;
  sTexto: string;
begin
  iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
  Banda := BandaDesdeLinea(iLinea);
  sTexto := TextoTipoCantidad(ObtenerLineaBase(iLinea), Banda);
  case Banda of
    bpvEntregada:
      ACanvas.Brush.Color := $00E0FFE0;
    bpvPendiente:
      ACanvas.Brush.Color := $00C4E1FF;
  else
    ACanvas.Brush.Color := $00F6F1E8;
  end;
  ACanvas.FillRect(AViewInfo.Bounds);
  b := AViewInfo.Bounds;
  rectTexto := Rect(b.Left + 4, b.Top, b.Right - 2, b.Bottom);
  InflateRect(rectTexto, 0, -1);
  iFontHeight := ACanvas.Font.Height;
  cFontColor := ACanvas.Font.Color;
  fsFontStyle := ACanvas.Font.Style;
  try
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Style := [fsBold];
    case Banda of
      bpvEntregada:
        ACanvas.Font.Color := clGreen;
      bpvPendiente:
        ACanvas.Font.Color := clBlue;
    else
      ACanvas.Font.Color := clWindowText;
    end;
    DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto), rectTexto,
             DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  finally
    ACanvas.Font.Height := iFontHeight;
    ACanvas.Font.Color := cFontColor;
    ACanvas.Font.Style := fsFontStyle;
  end;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TGridPivoteVenta.ArticuloButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Q: TUniQuery;
  sArt: string;
begin
  if FCfg.Conexion <> nil then
  begin
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := FCfg.Conexion;
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
        '                     ON sk.CODIGO_UNIDAD_SKU = ' +
        '                        st.CODIGO_UNIDAD_STK' +
        '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
        '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
        '  FROM fza_articulos a' +
        ' WHERE a.ESACTIVO_ART = ''S''' +
        '   AND a.TIPO_ART = ''ESTANDAR''' +
        ' ORDER BY STOCK DESC, a.CODIGO_ART_ART';
      Q.ParamByName('ALM').AsString := FConfig.AlmacenStock;
      Q.Open;
      if TBusquedaUtils.EjecutarBusqueda('Búsqueda de artículos', Q,
                                         'frmMtoArtTraspasoSearch') then
      begin
        sArt := Q.FieldByName('ARTICULO').AsString;
        if ResolverEntrada(sArt) and
           FConfig.View.Controller.EditingController.IsEditing then
          try
            FConfig.View.Controller.EditingController.HideEdit(False);
          except
            on E: EInvalidOperation do
              ;
          end;
      end;
    finally
      FreeAndNil(Q);
    end;
  end;
end;

procedure TGridPivoteVenta.ArticuloValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sEntrada: string;
begin
  if not (Error or FActualizandoGrid or FGuardandoCantidad) then
  begin
    sEntrada := Trim(VarToStr(DisplayValue));
    if sEntrada <> '' then
    begin
      Error := not ResolverEntrada(sEntrada);
      if Error and FEntradaCancelada then
      begin
        // Paleta de color/talla cancelada por el usuario: descartar la
        // entrada sin rotular "no encontrado".
        Error := False;
        DisplayValue := CampoTexto(CdsLineas, FCfg.FieldArt);
      end
      else if not Error then
        DisplayValue := CampoTexto(CdsLineas, FCfg.FieldArt);
    end;
    if Error then
      ErrorText := 'Artículo/SKU no encontrado.';
  end;
end;

procedure TGridPivoteVenta.CeldaTallaValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Rec: TcxCustomGridRecord;
  Col: TcxGridColumn;
  iLinea, iLineaBase, iIdAv: Integer;
  iKey: Int64;
  Banda: TBandaPivoteVenta;
begin
  if not (Error or FActualizandoGrid or FGuardandoCantidad) then
  begin
    Rec := FConfig.View.Controller.FocusedRecord;
    if FConfig.View.Controller.FocusedItem is TcxGridColumn then
      Col := TcxGridColumn(FConfig.View.Controller.FocusedItem)
    else
      Col := nil;
    iLinea := LineaDesdeRecord(Rec);
    iLineaBase := ObtenerLineaBase(iLinea);
    Banda := BandaDesdeLinea(iLinea);
    if (Col <> nil) and TallaAvDesdeColumna(iLineaBase, Col, iIdAv) then
    begin
      iKey := Int64(iLineaBase) * 100000 + iIdAv;
      PersistirCantidadCelda(iKey, ValorEditor(Sender, DisplayValue),
                             Banda);
    end;
  end;
end;

function TGridPivoteVenta.LocalizarLineaSku(const ASku: string;
  APrecio: Double; ATienePrecio: Boolean; out ALinea: string): Boolean;
var
  Ds: TDataSet;
  Bm: TBookmark;
  bFiltrado: Boolean;
  rPrecioLin: Double;
  sSkuLin: string;
  Info: TSkuPivoteVentaInfo;
begin
  Result := False;
  ALinea := '';
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and (Trim(ASku) <> '') then
  begin
    Bm := Ds.GetBookmark;
    bFiltrado := Ds.Filtered;
    Ds.DisableControls;
    try
      Ds.Filtered := False;
      Ds.First;
      while not Ds.Eof do
      begin
        ObtenerInfoLinea(Ds, sSkuLin, Info);
        if SameText(sSkuLin, Trim(ASku)) then
        begin
          rPrecioLin := CampoFloat(Ds, FCfg.FieldPrecioBase);
          Result := (not ATienePrecio) or
                    (Abs(rPrecioLin - APrecio) < 0.005);
          if Result then
          begin
            ALinea := CampoTexto(Ds, FCfg.FieldLinea);
            Break;
          end;
        end;
        Ds.Next;
      end;
      if (not Result) and Ds.BookmarkValid(Bm) then
        Ds.GotoBookmark(Bm);
      Ds.Filtered := bFiltrado;
    finally
      Ds.EnableControls;
      Ds.FreeBookmark(Bm);
    end;
  end;
end;

function TGridPivoteVenta.PrefijoSkuTalla(const ASku: string): string;
var
  iPos: Integer;
begin
  Result := '';
  iPos := LastDelimiter('/', ASku);
  if iPos > 1 then
    Result := Copy(ASku, 1, iPos - 1);
end;

function TGridPivoteVenta.ResolverSkuCelda(AKey: Int64;
  out ASku: string): Boolean;
var
  Qry: TUniQuery;
  iLineaRepr, iTallaAv, iColorAv: Integer;
  sArt, sPrefijo, sTalla, sVarSku: string;
begin
  ASku := '';
  Result := FCeldaSku.TryGetValue(AKey, ASku) and (Trim(ASku) <> '');
  if (not Result) and (FCfg.Conexion <> nil) then
  begin
    iLineaRepr := Integer(AKey div 100000);
    iTallaAv := Integer(AKey mod 100000);
    FPivotArticulo.TryGetValue(iLineaRepr, sArt);
    FPivotColorAv.TryGetValue(iLineaRepr, iColorAv);
    if (sArt <> '') and (iTallaAv > 0) then
    begin
      Qry := TUniQuery.Create(nil);
      try
        Qry.Connection := FCfg.Conexion;
        Qry.SQL.Text :=
          'SELECT sk.CODIGO_UNIDAD_SKU ' +
          '  FROM fza_articulos_skus sk ' +
          ' WHERE sk.CODIGO_ART_SKU = :art ' +
          '   AND sk.ESACTIVO_SKU = ''S'' ' +
          '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
          '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
          '                      sk.CODIGO_UNIDAD_SKU ' +
          '                  AND sa.ID_AV_SA = :talla) ';
        if iColorAv > 0 then
          Qry.SQL.Text := Qry.SQL.Text +
            '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
            '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
            '                      sk.CODIGO_UNIDAD_SKU ' +
            '                  AND sa.ID_AV_SA = :color) ';
        Qry.SQL.Text := Qry.SQL.Text + ' LIMIT 1';
        Qry.ParamByName('art').AsString := sArt;
        Qry.ParamByName('talla').AsInteger := iTallaAv;
        if iColorAv > 0 then
          Qry.ParamByName('color').AsInteger := iColorAv;
        Qry.Open;
        if not Qry.Eof then
          ASku := Qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        Result := Trim(ASku) <> '';
        if not Result then
        begin
          Qry.Close;
          Qry.SQL.Text :=
            'SELECT AV FROM fza_atributos_valores ' +
            ' WHERE ID_AV = :talla LIMIT 1';
          Qry.ParamByName('talla').AsInteger := iTallaAv;
          Qry.Open;
          if not Qry.Eof then
            sTalla := Qry.FieldByName('AV').AsString;
          FPivotSkuPrefijo.TryGetValue(iLineaRepr, sPrefijo);
          FPivotVarSku.TryGetValue(iLineaRepr, sVarSku);
          if sVarSku = '' then
            sVarSku := 'TC';
          if (sPrefijo <> '') and (Trim(sTalla) <> '') then
          begin
            ASku := sPrefijo + '/' + sTalla;
            Qry.Close;
            Qry.SQL.Text :=
              'INSERT IGNORE INTO fza_articulos_skus ' +
              '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
              '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
              '   INSTANTE_MODIF, USUARIO_MODIF) ' +
              'VALUES (:sku, :art, :varsku, ''S'', NOW(), :u, NOW(), :u)';
            Qry.ParamByName('sku').AsString := ASku;
            Qry.ParamByName('art').AsString := sArt;
            Qry.ParamByName('varsku').AsString := sVarSku;
            Qry.ParamByName('u').AsString := FCfg.Usuario;
            Qry.ExecSQL;
            if iColorAv > 0 then
            begin
              Qry.SQL.Text :=
                'INSERT IGNORE INTO fza_atributos_sku ' +
                '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
                '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
                'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
              Qry.ParamByName('sku').AsString := ASku;
              Qry.ParamByName('av').AsInteger := iColorAv;
              Qry.ParamByName('u').AsString := FCfg.Usuario;
              Qry.ExecSQL;
            end;
            Qry.SQL.Text :=
              'INSERT IGNORE INTO fza_atributos_sku ' +
              '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
              '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
              'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
            Qry.ParamByName('sku').AsString := ASku;
            Qry.ParamByName('av').AsInteger := iTallaAv;
            Qry.ParamByName('u').AsString := FCfg.Usuario;
            Qry.ExecSQL;
            Result := True;
          end;
        end;
      finally
        FreeAndNil(Qry);
      end;
    end;
  end;
end;

function TGridPivoteVenta.CrearLineaDesdeCelda(AKey: Int64;
  ACantidad: Double; out ALineaReal: string): Boolean;
var
  Ds: TDataSet;
  sSku: string;
  bFiltrado: Boolean;
begin
  Result := False;
  ALineaReal := '';
  Ds := CdsLineas;
  if (ACantidad > 0) and (Ds <> nil) and Ds.Active and
     ResolverSkuCelda(AKey, sSku) then
  begin
    bFiltrado := Ds.Filtered;
    Ds.DisableControls;
    FGuardandoCantidad := True;
    try
      Ds.Filtered := False;
      Ds.Append;
      try
        if Assigned(FCfg.OnCrearLineaSku) then
          FCfg.OnCrearLineaSku(sSku);
        if not (Ds.State in dsEditModes) then
          Ds.Edit;
        PonerFloat(Ds, FCfg.FieldCantidadPedida, ACantidad);
        PonerFloat(Ds, FCfg.FieldCantidadEntregada, 0);
        PonerFloat(Ds, FCfg.FieldCantidadAAlbaranar, 0);
        Ds.Post;
        ALineaReal := CampoTexto(Ds, FCfg.FieldLinea);
        Result := ALineaReal <> '';
      except
        if Ds.State in dsEditModes then
          Ds.Cancel;
        raise;
      end;
      Ds.Filtered := bFiltrado;
    finally
      FGuardandoCantidad := False;
      Ds.EnableControls;
    end;
  end;
end;

procedure TGridPivoteVenta.PersistirCantidadCelda(AKey: Int64;
  AValor: Double; ABanda: TBandaPivoteVenta);
var
  Ds: TDataSet;
  sLineaReal: string;
  iLineaFoco: Integer;
  rPedida, rEntregada, rPendBase: Double;
  bFiltrado, bBorrar: Boolean;
begin
  if not FGuardandoCantidad then
  begin
    Ds := CdsLineas;
    iLineaFoco := Integer(AKey div 100000);
    FGuardandoCantidad := True;
    try
      if FCeldaLinea.TryGetValue(AKey, sLineaReal) then
      begin
        bFiltrado := Ds.Filtered;
        Ds.DisableControls;
        try
          Ds.Filtered := False;
          if Ds.Locate(FCfg.FieldLinea, sLineaReal, []) then
          begin
            rPedida := CampoFloat(Ds, FCfg.FieldCantidadPedida);
            rEntregada := CampoFloat(Ds, FCfg.FieldCantidadEntregada);
            if ABanda = bpvPedida then
            begin
              bBorrar := (AValor <= 0) and (rEntregada <= 0);
              if bBorrar then
                bBorrar := MessageDlg(
                  'La cantidad queda a cero. ¿Borrar la línea del SKU?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes;
              if bBorrar then
                Ds.Delete
              else
              begin
                if not (Ds.State in dsEditModes) then
                  Ds.Edit;
                PonerFloat(Ds, FCfg.FieldCantidadPedida, AValor);
                if rEntregada > AValor then
                  PonerFloat(Ds, FCfg.FieldCantidadEntregada, AValor);
                Ds.Post;
              end;
            end
            else if ABanda = bpvEntregada then
            begin
              if AValor < 0 then
                AValor := 0;
              rPendBase := rPedida - rEntregada;
              if rPendBase < 0 then
                rPendBase := 0;
              if AValor > rPendBase then
              begin
                MessageBeep(MB_ICONWARNING);
                AValor := rPendBase;
              end;
              if not (Ds.State in dsEditModes) then
                Ds.Edit;
              PonerFloat(Ds, FCfg.FieldCantidadAAlbaranar, AValor);
              Ds.Post;
            end
            else
            begin
              if AValor < 0 then
                AValor := 0;
              rPendBase := rPedida - rEntregada;
              if rPendBase < 0 then
                rPendBase := 0;
              if AValor > rPendBase then
              begin
                MessageBeep(MB_ICONWARNING);
                AValor := rPendBase;
              end;
              if not (Ds.State in dsEditModes) then
                Ds.Edit;
              PonerFloat(Ds, FCfg.FieldCantidadAAlbaranar,
                         rPendBase - AValor);
              Ds.Post;
            end;
          end;
          Ds.Filtered := bFiltrado;
          LocalizarLineaReal(Ds, iLineaFoco);
        finally
          Ds.EnableControls;
        end;
      end
      else if ABanda = bpvPedida then
        CrearLineaDesdeCelda(AKey, AValor, sLineaReal)
      else
        MessageDlg('No existe línea de pedido para esa talla.',
                  mtInformation, [mbOk], 0);
    finally
      FGuardandoCantidad := False;
    end;
    RecargarYPublicar;
  end;
end;

function TGridPivoteVenta.BorrarLineasGrupo(ALineaBase: Integer): Integer;
var
  Ds: TDataSet;
  Par: TPair<Int64, string>;
  Lineas: TList<string>;
  sLinea: string;
  bFiltrado: Boolean;
begin
  Result := 0;
  Ds := CdsLineas;
  if (Ds = nil) or (not Ds.Active) or (ALineaBase <= 0) then
    Exit;
  // Lineas reales del grupo: una por talla (o la unica "sin talla").
  Lineas := TList<string>.Create;
  try
    for Par in FCeldaLinea do
      if Integer(Par.Key div 100000) = ALineaBase then
        if not Lineas.Contains(Par.Value) then
          Lineas.Add(Par.Value);
    if Lineas.Count = 0 then
      Exit;
    // Soltar la insercion vacia auto-anadida (o cualquier edicion a
    // medias) antes de mover el cursor por el dataset real.
    if Ds.State in dsEditModes then
      Ds.Cancel;
    bFiltrado := Ds.Filtered;
    Ds.DisableControls;
    FGuardandoCantidad := True;
    try
      Ds.Filtered := False;
      for sLinea in Lineas do
        if Ds.Locate(FCfg.FieldLinea, sLinea, []) then
        begin
          // Delete linea a linea (NO SQL directo): el BeforeDelete del
          // data module ajusta el stock pendiente de servir por linea.
          Ds.Delete;
          Inc(Result);
        end;
      Ds.Filtered := bFiltrado;
    finally
      FGuardandoCantidad := False;
      Ds.EnableControls;
    end;
  finally
    FreeAndNil(Lineas);
  end;
end;

function TGridPivoteVenta.BorrarGrupoActual: Integer;
begin
  Result := BorrarLineasGrupo(ObtenerLineaBase(
    LineaDesdeRecord(FConfig.View.Controller.FocusedRecord)));
  if Result > 0 then
    RecargarYPublicar;
end;

function TGridPivoteVenta.MarcarTodoAAlbaranar: Integer;
var
  Ds: TDataSet;
  Par: TPair<Int64, Double>;
  rPend, rPedida, rEntregada: Double;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  Result := 0;
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and
     (Ds.FindField(FCfg.FieldCantidadAAlbaranar) <> nil) then
  begin
    if Ds.State in dsEditModes then
      Ds.Post;
    bFiltrado := Ds.Filtered;
    sLineaFoco := CampoTexto(Ds, FCfg.FieldLinea);
    Ds.DisableControls;
    try
      Ds.Filtered := False;
      Ds.First;
      while not Ds.Eof do
      begin
        rPedida := CampoFloat(Ds, FCfg.FieldCantidadPedida);
        rEntregada := CampoFloat(Ds, FCfg.FieldCantidadEntregada);
        rPend := rPedida - rEntregada;
        if rPend < 0 then
          rPend := 0;
        if not (Ds.State in dsEditModes) then
          Ds.Edit;
        PonerFloat(Ds, FCfg.FieldCantidadAAlbaranar, rPend);
        Ds.Post;
        if rPend > 0 then
          Inc(Result);
        Ds.Next;
      end;
      Ds.Filtered := bFiltrado;
      if sLineaFoco <> '' then
        Ds.Locate(FCfg.FieldLinea, sLineaFoco, []);
    finally
      Ds.EnableControls;
    end;
    RecargarYPublicar;
  end
  else
  begin
    for Par in FPivotCantPedida do
    begin
      rPend := PendienteBaseCelda(Par.Key);
      if rPend > 0 then
      begin
        FPivotCantAAlbaranar.AddOrSetValue(Par.Key, rPend);
        Inc(Result);
      end;
    end;
    PublicarCantidadesPivot;
  end;
  if (FConfig.View <> nil) and Assigned(FConfig.View.Site) then
    FConfig.View.Site.Invalidate;
end;

function TGridPivoteVenta.VolcarAAlbaranar(
  ALineas: TList<TPair<string, Currency>>;
  out AAlmacenComun: string; out AAlmacenUnico: Boolean): Integer;
var
  Par: TPair<Int64, Double>;
  Lin: TPair<string, Currency>;
  sLinea, sAlm: string;
  rAAlbaranar, rEntregada: Double;
  bAlmInit: Boolean;
begin
  Result := 0;
  AAlmacenComun := '';
  AAlmacenUnico := True;
  bAlmInit := False;
  if ALineas <> nil then
  begin
    for Par in FPivotCantPedida do
    begin
      rAAlbaranar := AAlbaranarCelda(Par.Key);
      if (rAAlbaranar > 0) and FCeldaLinea.TryGetValue(Par.Key, sLinea) then
      begin
        rEntregada := 0;
        FPivotCantEntregada.TryGetValue(Par.Key, rEntregada);
        Lin.Key := sLinea;
        Lin.Value := rEntregada + rAAlbaranar;
        ALineas.Add(Lin);
        sAlm := '';
        FCeldaAlmacen.TryGetValue(Par.Key, sAlm);
        if not bAlmInit then
        begin
          AAlmacenComun := sAlm;
          bAlmInit := True;
        end
        else if sAlm <> AAlmacenComun then
          AAlmacenUnico := False;
        Inc(Result);
      end;
    end;
  end;
end;

procedure TGridPivoteVenta.LimpiarAAlbaranar;
var
  Ds: TDataSet;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  FPivotCantAAlbaranar.Clear;
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and
     (Ds.FindField(FCfg.FieldCantidadAAlbaranar) <> nil) then
  begin
    if Ds.State in dsEditModes then
      Ds.Post;
    bFiltrado := Ds.Filtered;
    sLineaFoco := CampoTexto(Ds, FCfg.FieldLinea);
    Ds.DisableControls;
    try
      Ds.Filtered := False;
      Ds.First;
      while not Ds.Eof do
      begin
        if CampoFloat(Ds, FCfg.FieldCantidadAAlbaranar) <> 0 then
        begin
          if not (Ds.State in dsEditModes) then
            Ds.Edit;
          PonerFloat(Ds, FCfg.FieldCantidadAAlbaranar, 0);
          Ds.Post;
        end;
        Ds.Next;
      end;
      Ds.Filtered := bFiltrado;
      if sLineaFoco <> '' then
        Ds.Locate(FCfg.FieldLinea, sLineaFoco, []);
    finally
      Ds.EnableControls;
    end;
    RecargarYPublicar;
  end
  else
    PublicarCantidadesPivot;
  if (FConfig.View <> nil) and Assigned(FConfig.View.Site) then
    FConfig.View.Site.Invalidate;
end;

function TGridPivoteVenta.ElegirSkuConPaleta(const ACodArt: string): string;
var
  Lookup: TArticulosAtributosLookup;
  Atribs: TArray<TArticuloAtributo>;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
  sIdVa, sAvNuevo: string;
  i, j: Integer;
  bCancelado: Boolean;
begin
  // Mismo flujo que TModoEntradaSku.ElegirSkuConPaleta (modo vertical):
  // un selector por atributo (Color, Talla, ...); si el articulo solo
  // referencia un AV en sus SKUs, se fija solo sin preguntar.
  Result := '';
  Lookup := TArticulosAtributosLookup.Create(FCfg.Conexion);
  try
    Atribs := Lookup.ObtenerAtributos(ACodArt);
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
        Avs := Lookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        if Length(Avs) = 0 then
          bCancelado := True
        else if Length(Avs) = 1 then
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
          // Paleta de swatches auto-centrada (-1,-1), como caja e
          // inventarios.
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
  finally
    FreeAndNil(Lookup);
  end;
end;

function TGridPivoteVenta.ResolverEntrada(const AEntrada: string): Boolean;
var
  Validador: TArticulosValidador;
  Res: TArtResolucionEntrada;
  sSku, sLinea: string;
  rPrecio: Double;
  bPrecio: Boolean;
  Ds: TDataSet;
  bLineaVacia: Boolean;
begin
  Result := False;
  FEntradaCancelada := False;
  if Trim(AEntrada) <> '' then
  begin
    Validador := TArticulosValidador.Create(FCfg.Conexion);
    try
      Res := Validador.Resolver(Trim(AEntrada));
    finally
      FreeAndNil(Validador);
    end;
    if Res.Encontrado then
    begin
      sSku := Res.CodigoSku;
      if (sSku = '') and Res.RequiereSku then
      begin
        // Coincidio el articulo padre y tiene variaciones: pedir COLOR
        // (y talla) con la paleta y componer el SKU completo. Antes se
        // seguia con el codigo pelado y la linea nacia sin color.
        sSku := ElegirSkuConPaleta(Res.CodigoArticulo);
        if sSku = '' then
        begin
          FEntradaCancelada := True;
          Exit;
        end;
      end;
      if sSku = '' then
        sSku := Res.CodigoArticulo;
      rPrecio := 0;
      bPrecio := False;
      if Assigned(FConfig.ObtenerPrecioSku) then
      begin
        rPrecio := FConfig.ObtenerPrecioSku(Res.CodigoArticulo, sSku);
        bPrecio := True;
      end;
      Ds := CdsLineas;
      if LocalizarLineaSku(sSku, rPrecio, bPrecio, sLinea) then
      begin
        Ds.Filtered := False;
        if not (Ds.State in dsEditModes) then
          Ds.Edit;
        PonerFloat(Ds, FCfg.FieldCantidadPedida,
          CampoFloat(Ds, FCfg.FieldCantidadPedida) + 1);
        Ds.Post;
      end
      else
      begin
        if Assigned(FCfg.OnCrearLineaSku) then
        begin
          if Ds.Filtered then
            Ds.Filtered := False;
          bLineaVacia := (Ds.State = dsInsert) and
            (CampoTexto(Ds, FCfg.FieldArt) = '') and
            (CampoTexto(Ds, FCfg.FieldSku) = '');
          if not bLineaVacia then
            Ds.Append;
          FCfg.OnCrearLineaSku(sSku);
          if Ds.State in dsEditModes then
            Ds.Post;
        end;
      end;
      RecargarYPublicar;
      Result := True;
    end
    else
      ShowMessage('Artículo/SKU no encontrado: ' + Trim(AEntrada));
  end;
end;

end.
