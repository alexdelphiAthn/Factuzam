{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteVentaPresentacion                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presentación del pivote de venta (fascículo V4 del anexo SRP):            }
{    TClientDataSet temporal, columnas DevExpress, dibujo, edición, foco,      }
{    temporizador de recarga e instalación/restauración de eventos del         }
{    dataset. Conoce VCL y DevExpress; recibe el modelo y callbacks            }
{    tipados. No contiene SQL ni recalcula reglas del pivote.                  }
{******************************************************************************}
unit inLibGridPivoteVentaPresentacion;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.UITypes, Data.DB, Uni,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  cxGraphics, cxEdit, cxTextEdit, cxButtonEdit, cxCurrencyEdit,
  cxDataStorage, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView,
  inLibPivoteVentaCalculo, inLibPivoteVentaIntf,
  inLibPivoteVentaModelo, inLibGridPivoteVentaVista;

type
  // Configuración visual del pivote: vista, datasets y campos del host.
  TConfigPresentacionPivoteVenta = record
    Conexion          : TUniConnection;
    View              : TcxGridDBTableView;
    SourceLineas      : TDataSource;
    CdsFallback       : TDataSet;
    CampoArticuloHost : string;
    FieldLinea        : string;
    FieldArt          : string;
    FieldSku          : string;
    FieldTotalUdsGrupo: string;
    MaxColumnas       : Integer;
    BandaUnica        : Boolean;
  end;
  // Callbacks tipados hacia el coordinador: la presentación no decide
  // reglas ni persiste cantidades.
  TCallbacksPresentacionPivoteVenta = record
    AlRecargar             : TNotifyEvent;
    AlEditarCantidad       : procedure(AClave: Int64; AValor: Double;
                               ABanda: TBandaPivoteVenta) of object;
    AlResolverEntradaEditor: function(const AEntrada: string;
                               out ATextoLinea: string;
                               out ACancelada: Boolean)
                               : Boolean of object;
    AlBuscarArticulo       : function: Boolean of object;
    AlBorrarGrupo          : function(ALineaBase: Integer)
                               : Integer of object;
    AlLineaFocada          : procedure(ALineaBase: Integer) of object;
    AlEntrarEdicion        : TNotifyEvent;
    AlSalirEdicion         : TNotifyEvent;
    AlLogInfo              : TLogPivoteVentaEvent;
    AlLogWarning           : TLogPivoteVentaEvent;
  end;
  // Eventos originales del dataset del host, para restaurarlos.
  TEventosDataSetPivote = record
    OnFilterOrig  : TFilterRecordEvent;
    AfterPostOrig : TDataSetNotifyEvent;
    AfterScrollOrig: TDataSetNotifyEvent;
    FilteredOrig  : Boolean;
    Instalados    : Boolean;
  end;
  TPresentacionPivoteVenta = class
  private
    FCfg                : TConfigPresentacionPivoteVenta;
    FCall               : TCallbacksPresentacionPivoteVenta;
    FModelo             : TModeloPivoteVenta;
    FColLineaVista      : TcxGridDBColumn;
    FColArticulo        : TcxGridDBColumn;
    FColColor           : TcxGridDBColumn;
    FColTipoCantidad    : TcxGridDBColumn;
    FColumnasTallas     : TArray<TcxGridDBColumn>;
    FVista              : TVistaPivoteVenta;
    FEventosDs          : TEventosDataSetPivote;
    FActualizandoGrid   : Boolean;
    FRecargaSuspendida  : Boolean;
    FEdicionSuspendida  : Boolean;
    // Tras Montar, la primera publicación vuelve al inicio para que el
    // scroll heredado no oculte filas pivotadas.
    FScrollInicialPendiente: Boolean;
    FTimerRecarga       : TTimer;
    function CdsLineas: TDataSet;
    procedure TimerRecargaTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure CrearColumnas;
    procedure AplicarVisibilidadTallas;
    procedure AplicarVisibilidadTipoCantidad;
    procedure ColocarBloqueColumnas;
    procedure ActualizarCaptionsLineaActiva;
    function LineaDesdeRecord(ARecord: TcxCustomGridRecord): Integer;
    function EsColumnaTalla(AItem: TcxCustomGridTableItem): Boolean;
    function TallaAvDesdeColumna(ALinea: Integer; ACol: TcxGridColumn;
                                 out AIdAv: Integer): Boolean;
    function BuscarColumnaTallaDesde(ALineaBase,
      AIndiceInicial: Integer; out ACol: TcxGridColumn): Boolean;
    function BuscarRecordPorLineaVista(ALineaVista: Integer;
                                       out ARecordIndex: Integer)
                                       : Boolean;
    function ValorEditor(ASender: TObject;
                         AValorFallback: Variant): Double;
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
                                      AItem: TcxCustomGridTableItem)
                                      : Boolean;
    procedure ViewFocusedRecordChanged(Sender: TcxCustomGridTableView;
                APrevFocusedRecord,
                AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure CustomDrawCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure PintarCeldaTallaCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                AValor: Double; ABanda: TBandaPivoteVenta;
                AMostrarCero: Boolean);
    procedure PintarCeldaTipoCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo);
    procedure ArticuloButtonClick(Sender: TObject;
                                  AButtonIndex: Integer);
    procedure ArticuloValidate(Sender: TObject;
                               var DisplayValue: Variant;
                               var ErrorText: TCaption;
                               var Error: Boolean);
    procedure CeldaTallaValidate(Sender: TObject;
                                 var DisplayValue: Variant;
                                 var ErrorText: TCaption;
                                 var Error: Boolean);
  public
    constructor Create(const ACfg: TConfigPresentacionPivoteVenta;
                       const ACallbacks
                         : TCallbacksPresentacionPivoteVenta;
                       AModelo: TModeloPivoteVenta);
    destructor Destroy; override;
    procedure Montar;
    procedure Desmontar;
    procedure ArmarRecarga;
    // Reconstruye la vista temporal y publica el estado del modelo.
    procedure PublicarTodo;
    procedure PublicarCantidadesPivot;
    // Enfoca la columna de artículo y abre su editor; devuelve si el
    // editor quedó realmente en edición.
    function EnfocarEditorArticulo: Boolean;
    // Línea base del grupo con foco (0 si no hay grupo bajo el foco).
    function LineaBaseFocada: Integer;
    function EsInsercionVacia(ADs: TDataSet): Boolean;
    procedure RefrescarSite;
    property RecargaSuspendida: Boolean read FRecargaSuspendida
                                        write FRecargaSuspendida;
    property EdicionSuspendida: Boolean read FEdicionSuspendida
                                        write FEdicionSuspendida;
  end;

implementation

uses
  inLibAtributosPaleta, inLibMsgArticulos;

const
  ANCHO_COLUMNA_TALLA_TRES_CANT = 62;

type
  THackWinControl = class(TWinControl);

constructor TPresentacionPivoteVenta.Create(
  const ACfg: TConfigPresentacionPivoteVenta;
  const ACallbacks: TCallbacksPresentacionPivoteVenta;
  AModelo: TModeloPivoteVenta);
var
  oCfgVista: TConfigVistaPivoteVenta;
begin
  inherited Create;
  FCfg := ACfg;
  FCall := ACallbacks;
  FModelo := AModelo;
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := 20;
  oCfgVista := Default(TConfigVistaPivoteVenta);
  oCfgVista.View := FCfg.View;
  oCfgVista.SourceLineas := FCfg.SourceLineas;
  oCfgVista.CdsFallback := FCfg.CdsFallback;
  oCfgVista.FieldLinea := FCfg.FieldLinea;
  oCfgVista.FieldArt := FCfg.FieldArt;
  oCfgVista.FieldSku := FCfg.FieldSku;
  oCfgVista.FieldTotalUdsGrupo := FCfg.FieldTotalUdsGrupo;
  oCfgVista.BandaUnica := FCfg.BandaUnica;
  oCfgVista.AlLogWarning := FCall.AlLogWarning;
  // El delete redirigido de la vista rearma la recarga diferida.
  FVista := TVistaPivoteVenta.Create(oCfgVista, AModelo,
    FCall.AlBorrarGrupo, ArmarRecarga);
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

destructor TPresentacionPivoteVenta.Destroy;
begin
  // Mismo orden que Desmontar: primero los eventos del dataset, luego
  // la vista (el cambio de DataSource dispara First/AfterScroll).
  RestaurarEventosDataSet;
  FreeAndNil(FVista);
  FreeAndNil(FTimerRecarga);
  inherited;
end;

function TPresentacionPivoteVenta.CdsLineas: TDataSet;
begin
  Result := nil;
  if FCfg.SourceLineas <> nil then
    Result := FCfg.SourceLineas.DataSet;
  if Result = nil then
    Result := FCfg.CdsFallback;
end;

procedure TPresentacionPivoteVenta.Montar;
begin
  FScrollInicialPendiente := True;
  CrearColumnas;
  FVista.Preparar;
  FCfg.View.OnEditing := ViewEditing;
  FCfg.View.OnInitEdit := ViewInitEdit;
  FCfg.View.OnEditKeyDown := ViewEditKeyDown;
  FCfg.View.OnFocusedRecordChanged := ViewFocusedRecordChanged;
  FCfg.View.OnCustomDrawCell := CustomDrawCell;
  InstalarEventosDataSet;
  ArmarRecarga;
end;

procedure TPresentacionPivoteVenta.Desmontar;
begin
  if FCfg.View <> nil then
  begin
    FCfg.View.OnEditing := nil;
    FCfg.View.OnInitEdit := nil;
    FCfg.View.OnEditKeyDown := nil;
    FCfg.View.OnFocusedRecordChanged := nil;
    FCfg.View.OnCustomDrawCell := nil;
  end;
  // Eventos del dataset ANTES de restaurar la vista: el cambio de
  // DataSource recarga el grid (First -> AfterScroll) y con
  // CdsAfterScroll aún enganchado se leía un grid a medio cargar
  // (EListError al pasar a otro modo, 08/07/26).
  RestaurarEventosDataSet;
  FVista.Restaurar;
end;

procedure TPresentacionPivoteVenta.ArmarRecarga;
begin
  if FTimerRecarga <> nil then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TPresentacionPivoteVenta.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  if Assigned(FCall.AlRecargar) then
    FCall.AlRecargar(Self);
end;

procedure TPresentacionPivoteVenta.InstalarEventosDataSet;
var
  oDs: TDataSet;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and (not FEventosDs.Instalados) then
  begin
    FEventosDs.OnFilterOrig := oDs.OnFilterRecord;
    FEventosDs.FilteredOrig := oDs.Filtered;
    FEventosDs.AfterPostOrig := oDs.AfterPost;
    FEventosDs.AfterScrollOrig := oDs.AfterScroll;
    oDs.AfterPost := CdsAfterPost;
    oDs.AfterScroll := CdsAfterScroll;
    FEventosDs.Instalados := True;
  end;
end;

procedure TPresentacionPivoteVenta.RestaurarEventosDataSet;
var
  oDs: TDataSet;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and FEventosDs.Instalados then
  begin
    // Primero desenganchar los hooks y LUEGO restaurar Filtered: el
    // cambio de filtro refresca el dataset y dispara AfterScroll, que
    // no debe caer ya en los handlers del pivote.
    oDs.OnFilterRecord := FEventosDs.OnFilterOrig;
    oDs.AfterPost := FEventosDs.AfterPostOrig;
    oDs.AfterScroll := FEventosDs.AfterScrollOrig;
    FEventosDs.Instalados := False;
    oDs.Filtered := FEventosDs.FilteredOrig;
  end;
end;

procedure TPresentacionPivoteVenta.CdsAfterPost(DataSet: TDataSet);
begin
  if Assigned(FEventosDs.AfterPostOrig) then
    FEventosDs.AfterPostOrig(DataSet);
  if not FRecargaSuspendida then
    ArmarRecarga;
end;

procedure TPresentacionPivoteVenta.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FEventosDs.AfterScrollOrig) then
    FEventosDs.AfterScrollOrig(DataSet);
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.CrearColumnas;
var
  i: Integer;
  oCol: TcxGridDBColumn;
begin
  FCfg.View.BeginUpdate;
  try
    FColLineaVista := FCfg.View.CreateColumn;
    FColLineaVista.DataBinding.FieldName := CAMPO_LINEA_VISTA_PIVOTE;
    FColLineaVista.Visible := False;
    FColLineaVista.VisibleForCustomization := False;
    FColArticulo := FCfg.View.CreateColumn;
    FColArticulo.Caption := 'Artículo';
    FColArticulo.DataBinding.FieldName := FCfg.CampoArticuloHost;
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
    FColColor := FCfg.View.CreateColumn;
    FColColor.Caption := 'Color';
    FColColor.Width := 125;
    FColColor.Options.Editing := False;
    FColColor.DataBinding.ValueTypeClass := TcxStringValueType;
    FColTipoCantidad := FCfg.View.CreateColumn;
    FColTipoCantidad.Caption := 'Tipo';
    FColTipoCantidad.Width := 105;
    FColTipoCantidad.Options.Editing := False;
    FColTipoCantidad.DataBinding.ValueTypeClass := TcxStringValueType;
    SetLength(FColumnasTallas, FCfg.MaxColumnas);
    for i := 1 to FCfg.MaxColumnas do
    begin
      oCol := FCfg.View.CreateColumn;
      oCol.Tag := i;
      oCol.Caption := '·';
      oCol.Width := ANCHO_COLUMNA_TALLA_TRES_CANT;
      oCol.Visible := False;
      oCol.DataBinding.ValueTypeClass := TcxFloatValueType;
      oCol.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(oCol.Properties).DisplayFormat :=
        '#,##0.##';
      TcxCurrencyEditProperties(oCol.Properties).
        UseDisplayFormatWhenEditing := True;
      TcxCurrencyEditProperties(oCol.Properties).OnValidate :=
        CeldaTallaValidate;
      FColumnasTallas[i - 1] := oCol;
    end;
  finally
    FCfg.View.EndUpdate;
  end;
end;

procedure TPresentacionPivoteVenta.AplicarVisibilidadTipoCantidad;
begin
  if FColTipoCantidad <> nil then
  begin
    if FCfg.BandaUnica then
      FColTipoCantidad.Visible := FModelo.HayTipoCantidadEspecial
    else
      FColTipoCantidad.Visible := True;
    FColTipoCantidad.VisibleForCustomization :=
      FColTipoCantidad.Visible;
  end;
end;

procedure TPresentacionPivoteVenta.AplicarVisibilidadTallas;
var
  i, iMax: Integer;
begin
  iMax := FModelo.MaxPosicionesVisibles(FCfg.MaxColumnas);
  for i := 0 to High(FColumnasTallas) do
  begin
    FColumnasTallas[i].Visible := i < iMax;
    if not FColumnasTallas[i].Visible then
      FColumnasTallas[i].Caption := '·';
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.ColocarBloqueColumnas;
var
  i, iBase, iDestino: Integer;
  bColocado: Boolean;
begin
  // El bloque de entrada del pivote va SIEMPRE delante de las columnas
  // del documento, justo detrás del Nro de línea del host (Index 0).
  // Idempotente: corrige recolocaciones externas (perfiles, 09/07/26).
  if (FCfg.View <> nil) and (FColLineaVista <> nil) and
     (FColArticulo <> nil) and (FColColor <> nil) and
     (FColTipoCantidad <> nil) then
  begin
    iBase := 1;
    if FCfg.View.ColumnCount <= 1 then
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
      FCfg.View.BeginUpdate;
      try
        // Asignación en orden de destino ascendente: cada Index
        // inserta la columna en su posición final.
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
        FCfg.View.EndUpdate;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.ActualizarCaptionsLineaActiva;
var
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
  iLinea, iLineaVista, i: Integer;
begin
  iLineaVista := 0;
  if (FCfg.View <> nil) and (FCfg.View.Controller <> nil) then
    iLineaVista := LineaDesdeRecord(FCfg.View.Controller.FocusedRecord);
  iLinea := FModelo.ObtenerLineaBase(iLineaVista);
  aPosiciones := nil;
  oGrupo := Default(TGrupoPivoteVenta);
  if iLinea > 0 then
    FModelo.Grupo(iLinea, oGrupo);
  // <> 0 y no > 0: los conjuntos VIRTUALES llevan id negativo y sus
  // captions se resuelven desde la misma caché que los reales.
  if oGrupo.IdAc <> 0 then
    aPosiciones := FModelo.PosicionesConjunto(oGrupo.IdAc);
  for i := 0 to High(FColumnasTallas) do
  begin
    if FColumnasTallas[i].Visible then
    begin
      if i < Length(aPosiciones) then
        FColumnasTallas[i].Caption := aPosiciones[i].Valor
      else if (i = 0) and oGrupo.SinTalla then
        FColumnasTallas[i].Caption := 'Cantidad'
      else
        FColumnasTallas[i].Caption := '·';
    end;
  end;
end;

procedure TPresentacionPivoteVenta.PublicarCantidadesPivot;
var
  oColLinea: TcxGridColumn;
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
  vLinea: Variant;
  iLinea, iLineaVista, recIdx, i: Integer;
  iClave: Int64;
  rCant: Double;
  oBanda: TBandaPivoteVenta;
begin
  if (FCfg.View <> nil) and (not FActualizandoGrid) then
  begin
    oColLinea :=
      FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
    if oColLinea = nil then
      oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
    if oColLinea <> nil then
    begin
      FActualizandoGrid := True;
      FCfg.View.DataController.BeginUpdate;
      try
        for recIdx := 0 to
          FCfg.View.DataController.RecordCount - 1 do
        begin
          vLinea := FCfg.View.DataController.Values[recIdx,
                                                    oColLinea.Index];
          iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
          iLinea := FModelo.ObtenerLineaBase(iLineaVista);
          if iLinea > 0 then
          begin
            oBanda := FModelo.BandaDesdeLinea(iLineaVista);
            FCfg.View.DataController.Values[recIdx,
              FColTipoCantidad.Index] :=
                FModelo.TextoTipoCantidad(iLinea, oBanda);
            for i := 0 to High(FColumnasTallas) do
            begin
              if FColumnasTallas[i].Visible then
                FCfg.View.DataController.Values[recIdx,
                  FColumnasTallas[i].Index] := Null;
            end;
            if FModelo.Grupo(iLinea, oGrupo) then
            begin
              FCfg.View.DataController.Values[recIdx,
                FColColor.Index] := oGrupo.ColorTexto;
              if oGrupo.SinTalla then
              begin
                iClave := ClaveCeldaPivoteVenta(iLinea,
                  ID_AV_SIN_TALLA_PIVOTE);
                rCant := FModelo.ValorCantidadBanda(iClave, oBanda);
                if rCant <> 0 then
                  FCfg.View.DataController.Values[recIdx,
                    FColumnasTallas[0].Index] := rCant
                else
                  FCfg.View.DataController.Values[recIdx,
                    FColumnasTallas[0].Index] := Null;
              end
              else if oGrupo.IdAc <> 0 then
              begin
                aPosiciones :=
                  FModelo.PosicionesConjunto(oGrupo.IdAc);
                for i := 0 to High(aPosiciones) do
                begin
                  if i < Length(FColumnasTallas) then
                  begin
                    iClave := ClaveCeldaPivoteVenta(iLinea,
                      aPosiciones[i].IdAv);
                    rCant := FModelo.ValorCantidadBanda(iClave,
                                                        oBanda);
                    if rCant <> 0 then
                      FCfg.View.DataController.Values[recIdx,
                        FColumnasTallas[i].Index] := rCant
                    else
                      FCfg.View.DataController.Values[recIdx,
                        FColumnasTallas[i].Index] := Null;
                  end;
                end;
              end;
            end;
          end;
        end;
      finally
        FCfg.View.DataController.EndUpdate;
        FActualizandoGrid := False;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.PublicarTodo;
begin
  FVista.Reconstruir;
  AplicarVisibilidadTipoCantidad;
  AplicarVisibilidadTallas;
  ColocarBloqueColumnas;
  PublicarCantidadesPivot;
  // Traza de diagnóstico: si el CDS de la vista tiene más filas de las
  // que el grid publica, un filtro se está comiendo filas del view.
  if Assigned(FCall.AlLogInfo) and (FCfg.View <> nil) then
    FCall.AlLogInfo(Format(
      'PivVenta.Publicar: filasVista=%d filasGrid=%d filtroView="%s"',
      [FVista.FilasVista,
       FCfg.View.DataController.RecordCount,
       FCfg.View.DataController.Filter.FilterText]));
  // Primera publicación tras Montar: arrancar viendo el grid desde la
  // primera fila (el scroll heredado ocultaba filas pivotadas).
  if FScrollInicialPendiente and (FCfg.View <> nil) and
     (FCfg.View.DataController.RecordCount > 0) then
  begin
    FScrollInicialPendiente := False;
    FCfg.View.DataController.FocusedRecordIndex := 0;
    FCfg.View.Controller.TopRecordIndex := 0;
  end;
end;

function TPresentacionPivoteVenta.EnfocarEditorArticulo: Boolean;
begin
  Result := False;
  if (FCfg.View <> nil) and (FColArticulo <> nil) then
  begin
    if (FCfg.View.DataController <> nil) and
       (FCfg.View.DataController.RecordCount > 0) then
      FCfg.View.DataController.FocusedRecordIndex := 0;
    if Assigned(FCfg.View.Site) and FCfg.View.Site.CanFocus then
      FCfg.View.Site.SetFocus;
    FColArticulo.Focused := True;
    FCfg.View.Controller.FocusedItem := FColArticulo;
    try
      FCfg.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        FCall.AlLogWarning(
          'PivotePresentacion.EnfocarEditorArticulo: ShowEdit ' +
          'ignorado: ' + E.Message);
    end;
    Result := FCfg.View.Controller.EditingController.IsEditing;
  end;
end;

function TPresentacionPivoteVenta.EsInsercionVacia(
  ADs: TDataSet): Boolean;
begin
  Result := FVista.EsInsercionVacia(ADs);
end;

function TPresentacionPivoteVenta.LineaBaseFocada: Integer;
begin
  Result := 0;
  if (FCfg.View <> nil) and (FCfg.View.Controller <> nil) then
    Result := FModelo.ObtenerLineaBase(
      LineaDesdeRecord(FCfg.View.Controller.FocusedRecord));
end;

procedure TPresentacionPivoteVenta.RefrescarSite;
begin
  if (FCfg.View <> nil) and Assigned(FCfg.View.Site) then
    FCfg.View.Site.Invalidate;
end;

function TPresentacionPivoteVenta.LineaDesdeRecord(
  ARecord: TcxCustomGridRecord): Integer;
var
  oColLinea: TcxGridColumn;
  vLinea: Variant;
begin
  Result := 0;
  if (ARecord <> nil) and (FCfg.View <> nil) then
  begin
    try
      oColLinea :=
        FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
      if oColLinea = nil then
        oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
    except
      oColLinea := nil;
    end;
    if oColLinea <> nil then
    begin
      try
        vLinea := ARecord.Values[oColLinea.Index];
        Result := StrToIntDef(VarToStr(vLinea), 0);
      except
        Result := 0;
      end;
    end;
  end;
end;

function TPresentacionPivoteVenta.EsColumnaTalla(
  AItem: TcxCustomGridTableItem): Boolean;
begin
  Result := (AItem <> nil) and (AItem.Tag >= 1) and
            (AItem.Tag <= Length(FColumnasTallas)) and
            (FColumnasTallas[AItem.Tag - 1] = AItem);
end;

function TPresentacionPivoteVenta.TallaAvDesdeColumna(ALinea: Integer;
  ACol: TcxGridColumn; out AIdAv: Integer): Boolean;
begin
  Result := False;
  AIdAv := 0;
  if (ACol <> nil) and EsColumnaTalla(ACol) then
    Result := FModelo.TallaAvEnPosicion(
      FModelo.ObtenerLineaBase(ALinea), ACol.Tag, AIdAv);
end;

function TPresentacionPivoteVenta.BuscarColumnaTallaDesde(ALineaBase,
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
       FModelo.TallaAvEnPosicion(ALineaBase,
                                 FColumnasTallas[i].Tag, iIdAv) then
    begin
      ACol := FColumnasTallas[i];
      Result := True;
    end;
    Inc(i);
  end;
end;

function TPresentacionPivoteVenta.BuscarRecordPorLineaVista(
  ALineaVista: Integer; out ARecordIndex: Integer): Boolean;
var
  oColLinea: TcxGridColumn;
  i, iLinea: Integer;
  vLinea: Variant;
begin
  Result := False;
  ARecordIndex := -1;
  oColLinea := nil;
  if FCfg.View <> nil then
  begin
    oColLinea :=
      FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
    if oColLinea = nil then
      oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
  end;
  if oColLinea <> nil then
  begin
    i := 0;
    while (not Result) and
          (i < FCfg.View.DataController.RecordCount) do
    begin
      vLinea := FCfg.View.DataController.Values[i, oColLinea.Index];
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

function TPresentacionPivoteVenta.ValorEditor(ASender: TObject;
  AValorFallback: Variant): Double;
var
  vValor: Variant;
begin
  Result := 0;
  vValor := AValorFallback;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or
      VarIsClear(vValor)) and (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditingValue;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or
      VarIsClear(vValor)) and (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditValue;
  if not (VarIsNull(vValor) or VarIsEmpty(vValor) or
          VarIsClear(vValor)) then
  begin
    if VarIsNumeric(vValor) then
      Result := vValor
    else
      Result := StrToFloatDef(VarToStr(vValor), 0);
  end;
end;

procedure TPresentacionPivoteVenta.ViewEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iLinea, iIdAv: Integer;
begin
  if EsColumnaTalla(AItem) then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := TallaAvDesdeColumna(iLinea, TcxGridColumn(AItem),
                                  iIdAv);
  end
  else if AItem = FColArticulo then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := (iLinea = 0) or
              (FModelo.BandaDesdeLinea(iLinea) = bpvPedida);
  end;
end;

procedure TPresentacionPivoteVenta.EditorSalir(Sender: TObject);
begin
  if Assigned(FCall.AlSalirEdicion) then
    FCall.AlSalirEdicion(Sender);
end;

procedure TPresentacionPivoteVenta.ViewInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  oRec: TcxCustomGridRecord;
  iLinea, iLineaBase, iIdAv: Integer;
  iClave: Int64;
  oBanda: TBandaPivoteVenta;
  rValor: Double;
begin
  if Assigned(FCall.AlEntrarEdicion) then
    FCall.AlEntrarEdicion(AEdit);
  if EsColumnaTalla(AItem) and (Sender <> nil) and (AEdit <> nil) then
  begin
    oRec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    oBanda := FModelo.BandaDesdeLinea(iLinea);
    if FModelo.TallaAvEnPosicion(iLineaBase,
         TcxGridColumn(AItem).Tag, iIdAv) then
    begin
      iClave := ClaveCeldaPivoteVenta(iLineaBase, iIdAv);
      rValor := FModelo.ValorCantidadBanda(iClave, oBanda);
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

procedure TPresentacionPivoteVenta.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  if (AItem = FColArticulo) and
     ((Key = VK_F3) or
      ((Key = VK_RETURN) and (ssCtrl in Shift))) then
  begin
    Key := 0;
    ArticuloButtonClick(AEdit, 0);
  end
  else if (Key = VK_RETURN) and
          GestionarEnterAAlbaranar(Sender, AItem) then
    Key := 0
  else if (Key = VK_RETURN) and (AItem = FColArticulo) then
  begin
    sEntrada := Trim(VarToStr(AEdit.EditingValue));
    if sEntrada <> '' then
      Sender.Controller.EditingController.HideEdit(True);
    Key := 0;
  end;
end;

function TPresentacionPivoteVenta.GestionarEnterAAlbaranar(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem): Boolean;
var
  oColDest, oColLinea: TcxGridColumn;
  oRec: TcxCustomGridRecord;
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
    oRec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    if (iLineaBase > 0) and
       (FModelo.BandaDesdeLinea(iLinea) = bpvEntregada) then
    begin
      Result := True;
      if BuscarColumnaTallaDesde(iLineaBase,
           TcxGridColumn(AItem).Tag, oColDest) then
      begin
        iLineaVistaDest := iLinea;
        iTagDest := oColDest.Tag;
        bHayDestino := True;
      end
      else
      begin
        oColLinea :=
          FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
        if oColLinea = nil then
          oColLinea :=
            FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
        if oColLinea <> nil then
        begin
          iRecAct := Sender.DataController.FocusedRecordIndex;
          iRec := iRecAct + 1;
          while (not bHayDestino) and
                (iRec < Sender.DataController.RecordCount) do
          begin
            vLinea := Sender.DataController.Values[iRec,
                                                   oColLinea.Index];
            iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
            iLineaBaseDest := FModelo.ObtenerLineaBase(iLineaVista);
            if (iLineaBaseDest > 0) and
               (FModelo.BandaDesdeLinea(iLineaVista) =
                bpvEntregada) and
               BuscarColumnaTallaDesde(iLineaBaseDest, 0,
                                       oColDest) then
            begin
              iLineaVistaDest := iLineaVista;
              iTagDest := oColDest.Tag;
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
        if (iTagDest > 0) and
           (iTagDest <= Length(FColumnasTallas)) then
        begin
          Sender.Controller.FocusedItem :=
            FColumnasTallas[iTagDest - 1];
          try
            Sender.Controller.EditingController.ShowEdit;
          except
            on E: EInvalidOperation do
              // Ruido del editor inplace; queda en el log.
              FCall.AlLogWarning(
                'PivotePresentacion.GestionarEnterAAlbaranar: ' +
                'ShowEdit ignorado: ' + E.Message);
          end;
        end;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.ViewFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var
  iLineaVista: Integer;
begin
  if not FActualizandoGrid then
  begin
    iLineaVista := LineaDesdeRecord(AFocusedRecord);
    if Assigned(FCall.AlLineaFocada) then
      FCall.AlLineaFocada(FModelo.ObtenerLineaBase(iLineaVista));
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.CustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oCol: TcxGridColumn;
  oGrupo: TGrupoPivoteVenta;
  oCelda: TCeldaPivoteVenta;
  iLinea, iLineaBase, iIdAv: Integer;
  iClave: Int64;
  rValor: Double;
  oBanda: TBandaPivoteVenta;
  sValorColor: string;
begin
  ADone := False;
  if (AViewInfo.Item is TcxGridColumn) and
     (AViewInfo.GridRecord <> nil) then
  begin
    oCol := TcxGridColumn(AViewInfo.Item);
    iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    if oCol = FColTipoCantidad then
    begin
      PintarCeldaTipoCantidad(ACanvas, AViewInfo);
      ADone := True;
    end
    else if oCol = FColColor then
    begin
      FModelo.Grupo(iLineaBase, oGrupo);
      sValorColor := oGrupo.ColorTexto;
      if sValorColor = '' then
        sValorColor := oGrupo.ColorCodigo;
      if PintarCeldaSwatchArticuloSiAplica(
           FCfg.Conexion, ACanvas, AViewInfo, oGrupo.Articulo,
           sValorColor, nil) then
        ADone := True;
    end
    else if EsColumnaTalla(oCol) then
    begin
      if TallaAvDesdeColumna(iLineaBase, oCol, iIdAv) then
      begin
        oBanda := FModelo.BandaDesdeLinea(iLinea);
        iClave := ClaveCeldaPivoteVenta(iLineaBase, iIdAv);
        rValor := FModelo.ValorCantidadBanda(iClave, oBanda);
        FModelo.Celda(iClave, oCelda);
        PintarCeldaTallaCantidad(ACanvas, AViewInfo, rValor, oBanda,
                                 oCelda.Pedida > 0);
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

procedure TPresentacionPivoteVenta.PintarCeldaTallaCantidad(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  AValor: Double; ABanda: TBandaPivoteVenta; AMostrarCero: Boolean);
var
  oRectTexto: TRect;
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
  oRectTexto := AViewInfo.Bounds;
  InflateRect(oRectTexto, -4, 0);
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto), oRectTexto,
           DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteVenta.PintarCeldaTipoCantidad(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo);
var
  oBounds, oRectTexto: TRect;
  iFontHeight: Integer;
  cFontColor: TColor;
  fsFontStyle: TFontStyles;
  iLinea: Integer;
  oBanda: TBandaPivoteVenta;
  sTexto: string;
begin
  iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
  oBanda := FModelo.BandaDesdeLinea(iLinea);
  sTexto := FModelo.TextoTipoCantidad(
    FModelo.ObtenerLineaBase(iLinea), oBanda);
  case oBanda of
    bpvEntregada:
      ACanvas.Brush.Color := $00E0FFE0;
    bpvPendiente:
      ACanvas.Brush.Color := $00C4E1FF;
  else
    ACanvas.Brush.Color := $00F6F1E8;
  end;
  ACanvas.FillRect(AViewInfo.Bounds);
  oBounds := AViewInfo.Bounds;
  oRectTexto := Rect(oBounds.Left + 4, oBounds.Top,
                     oBounds.Right - 2, oBounds.Bottom);
  InflateRect(oRectTexto, 0, -1);
  iFontHeight := ACanvas.Font.Height;
  cFontColor := ACanvas.Font.Color;
  fsFontStyle := ACanvas.Font.Style;
  try
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Style := [fsBold];
    case oBanda of
      bpvEntregada:
        ACanvas.Font.Color := clGreen;
      bpvPendiente:
        ACanvas.Font.Color := clBlue;
    else
      ACanvas.Font.Color := clWindowText;
    end;
    DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto),
             oRectTexto, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  finally
    ACanvas.Font.Height := iFontHeight;
    ACanvas.Font.Color := cFontColor;
    ACanvas.Font.Style := fsFontStyle;
  end;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteVenta.ArticuloButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(FCall.AlBuscarArticulo) then
  begin
    if FCall.AlBuscarArticulo() and
       FCfg.View.Controller.EditingController.IsEditing then
      try
        FCfg.View.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          // Ruido del editor inplace; queda en el log.
          FCall.AlLogWarning(
            'PivotePresentacion.ArticuloButtonClick: HideEdit ' +
            'ignorado: ' + E.Message);
      end;
  end;
end;

procedure TPresentacionPivoteVenta.ArticuloValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sEntrada, sTextoLinea: string;
  bCancelada: Boolean;
begin
  if not (Error or FActualizandoGrid or FEdicionSuspendida) then
  begin
    sEntrada := Trim(VarToStr(DisplayValue));
    if (sEntrada <> '') and
       Assigned(FCall.AlResolverEntradaEditor) then
    begin
      Error := not FCall.AlResolverEntradaEditor(sEntrada,
                 sTextoLinea, bCancelada);
      if Error and bCancelada then
      begin
        // Paleta de color/talla cancelada por el usuario: descartar
        // la entrada sin rotular "no encontrado".
        Error := False;
        DisplayValue := sTextoLinea;
      end
      else if not Error then
        DisplayValue := sTextoLinea;
    end;
    if Error then
      ErrorText := SErrorArticuloSkuNoEncontradoSinDetalle;
  end;
end;

procedure TPresentacionPivoteVenta.CeldaTallaValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  oRec: TcxCustomGridRecord;
  oCol: TcxGridColumn;
  iLinea, iLineaBase, iIdAv: Integer;
  oBanda: TBandaPivoteVenta;
begin
  if not (Error or FActualizandoGrid or FEdicionSuspendida) then
  begin
    oRec := FCfg.View.Controller.FocusedRecord;
    if FCfg.View.Controller.FocusedItem is TcxGridColumn then
      oCol := TcxGridColumn(FCfg.View.Controller.FocusedItem)
    else
      oCol := nil;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    oBanda := FModelo.BandaDesdeLinea(iLinea);
    if (oCol <> nil) and
       FModelo.TallaAvEnPosicion(iLineaBase, oCol.Tag, iIdAv) and
       Assigned(FCall.AlEditarCantidad) then
      FCall.AlEditarCantidad(
        ClaveCeldaPivoteVenta(iLineaBase, iIdAv),
        ValorEditor(Sender, DisplayValue), oBanda);
  end;
end;

end.
