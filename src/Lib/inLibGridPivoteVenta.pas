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
  System.StrUtils, System.UITypes, System.Generics.Collections, Data.DB, Uni,
  Vcl.Controls, Vcl.Graphics, Vcl.Dialogs, Vcl.ExtCtrls, cxGraphics, cxEdit,
  cxTextEdit, cxCurrencyEdit, cxDataStorage, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView,
  inLibColumnasSkuIntf, inLibGridTallasInline;

type
  TBandaPivoteVenta = (bpvPedida, bpvEntregada);

  TCrearLineaPivoteVentaEvent = procedure(const ACodigoSku: string) of object;
  TBandaPivoteVentaEvent = procedure(ABanda: TBandaPivoteVenta) of object;

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
    FieldCantidadPedida   : string;
    FieldCantidadEntregada: string;
    FieldPrecioBase       : string;
    FieldAlmacen          : string;
    FieldAlmacenMaster    : string;
    MaxColumnas           : Integer;
    OnCrearLineaSku       : TCrearLineaPivoteVentaEvent;
    OnBandaCambiada       : TBandaPivoteVentaEvent;
  end;

function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;

implementation

uses
  inLibArticulosValidador, inLibAtributosPaleta, inLibGlobalVar;

const
  ID_AV_SIN_TALLA = 0;
  ALTURA_FILA_TRES_CANT = 63;
  ANCHO_COLUMNA_TALLA_TRES_CANT = 62;
  ALTO_FUENTE_TALLA_TRES_CANT = -12;
  GROSOR_LINEA_TRES_CANT = 2;

type
  THackWinControl = class(TWinControl);

  TSkuPivoteVentaInfo = record
    ColorAv    : Integer;
    TallaAv    : Integer;
    ColorTexto : string;
    ColorCodigo: string;
    VarSku     : string;
  end;

  TGridPivoteVenta = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig              : TConfigColumnasSku;
    FCfg                 : TGridPivoteVentaConfig;
    FGestor              : TGestorGridTallas;
    FColArticulo         : TcxGridDBColumn;
    FColColor            : TcxGridDBColumn;
    FColumnasTallas      : TArray<TcxGridDBColumn>;
    FPivotLineasRepr     : TList<Integer>;
    FPivotCantPedida     : TDictionary<Int64, Double>;
    FPivotCantEntregada  : TDictionary<Int64, Double>;
    FPivotIdAc           : TDictionary<Integer, Integer>;
    FPivotSinTalla       : TDictionary<Integer, Boolean>;
    FPivotArticulo       : TDictionary<Integer, string>;
    FPivotColorAv        : TDictionary<Integer, Integer>;
    FPivotColorTexto     : TDictionary<Integer, string>;
    FPivotColorCodigo    : TDictionary<Integer, string>;
    FPivotSkuPrefijo     : TDictionary<Integer, string>;
    FPivotVarSku         : TDictionary<Integer, string>;
    FCeldaSku            : TDictionary<Int64, string>;
    FCeldaLinea          : TDictionary<Int64, string>;
    FSkuInfo             : TDictionary<string, TSkuPivoteVentaInfo>;
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
    FBanda               : TBandaPivoteVenta;
    FTimerRecarga        : TTimer;
    FAlturaFilaOriginal  : Integer;
    FAlturaFilaAplicada  : Boolean;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    function CdsLineas: TDataSet;
    function CampoTexto(ADs: TDataSet; const ACampo: string): string;
    function CampoFloat(ADs: TDataSet; const ACampo: string): Double;
    procedure PonerFloat(ADs: TDataSet; const ACampo: string;
                         AValor: Double);
    procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure ArmarRecarga;
    procedure TimerRecargaTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure AplicarAlturaFila;
    procedure RestaurarAlturaFila;
    procedure CrearColumnas;
    procedure CrearGestor;
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
    procedure AplicarVisibilidadTallas;
    procedure ActualizarCaptionsLineaActiva;
    procedure PublicarCantidadesPivot;
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
    procedure ViewFocusedRecordChanged(Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure CustomDrawCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure PintarCeldaTalla3Cantidades(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                APedida, AEntregada: Double);
    procedure DibujarBordeFocused(ACanvas: TcxCanvas; const ARect: TRect);
    procedure CeldaTallaCambiada(Sender: TObject);
    procedure CeldaTallaValidate(Sender: TObject; var DisplayValue: Variant;
                                 var ErrorText: TCaption;
                                 var Error: Boolean);
    procedure AlternarBanda;
    function LocalizarLineaSku(const ASku: string; APrecio: Double;
                               ATienePrecio: Boolean;
                               out ALinea: string): Boolean;
    function ResolverSkuCelda(AKey: Int64; out ASku: string): Boolean;
    function PrefijoSkuTalla(const ASku: string): string;
    function CrearLineaDesdeCelda(AKey: Int64; ACantidad: Double;
                                  out ALineaReal: string): Boolean;
    procedure PersistirCantidadCelda(AKey: Int64; AValor: Double);
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgPivote: TGridPivoteVentaConfig);
    destructor Destroy; override;
    procedure Construir;
    procedure Desmontar;
    procedure MostrarEditor;
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
  FBanda := bpvPedida;
  FPivotLineasRepr    := TList<Integer>.Create;
  FPivotCantPedida    := TDictionary<Int64, Double>.Create;
  FPivotCantEntregada := TDictionary<Int64, Double>.Create;
  FPivotIdAc          := TDictionary<Integer, Integer>.Create;
  FPivotSinTalla      := TDictionary<Integer, Boolean>.Create;
  FPivotArticulo      := TDictionary<Integer, string>.Create;
  FPivotColorAv       := TDictionary<Integer, Integer>.Create;
  FPivotColorTexto    := TDictionary<Integer, string>.Create;
  FPivotColorCodigo   := TDictionary<Integer, string>.Create;
  FPivotSkuPrefijo    := TDictionary<Integer, string>.Create;
  FPivotVarSku        := TDictionary<Integer, string>.Create;
  FCeldaSku           := TDictionary<Int64, string>.Create;
  FCeldaLinea         := TDictionary<Int64, string>.Create;
  FSkuInfo            := TDictionary<string, TSkuPivoteVentaInfo>.Create;
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

destructor TGridPivoteVenta.Destroy;
begin
  RestaurarEventosDataSet;
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FGestor);
  FreeAndNil(FSkuInfo);
  FreeAndNil(FCeldaLinea);
  FreeAndNil(FCeldaSku);
  FreeAndNil(FPivotVarSku);
  FreeAndNil(FPivotSkuPrefijo);
  FreeAndNil(FPivotColorCodigo);
  FreeAndNil(FPivotColorTexto);
  FreeAndNil(FPivotColorAv);
  FreeAndNil(FPivotArticulo);
  FreeAndNil(FPivotSinTalla);
  FreeAndNil(FPivotIdAc);
  FreeAndNil(FPivotCantEntregada);
  FreeAndNil(FPivotCantPedida);
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

procedure TGridPivoteVenta.FilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
var
  iLinea: Integer;
begin
  Accept := True;
  if Assigned(FOnFilterOrig) then
    FOnFilterOrig(DataSet, Accept);
  if Accept and (FPivotLineasRepr <> nil) then
  begin
    iLinea := StrToIntDef(CampoTexto(DataSet, FCfg.FieldLinea), 0);
    Accept := FPivotLineasRepr.Contains(iLinea);
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
    Ds.OnFilterRecord := FilterRecord;
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
    Ds.Filtered := FFilteredOrig;
    Ds.OnFilterRecord := FOnFilterOrig;
    Ds.AfterPost := FAfterPostOrig;
    Ds.AfterScroll := FAfterScrollOrig;
    FEventosInstalados := False;
  end;
end;

procedure TGridPivoteVenta.AplicarAlturaFila;
begin
  if (FConfig.View <> nil) and (not FAlturaFilaAplicada) then
  begin
    FAlturaFilaOriginal := FConfig.View.OptionsView.DataRowHeight;
    FConfig.View.OptionsView.DataRowHeight := ALTURA_FILA_TRES_CANT;
    FAlturaFilaAplicada := True;
  end;
end;

procedure TGridPivoteVenta.RestaurarAlturaFila;
begin
  if (FConfig.View <> nil) and FAlturaFilaAplicada then
  begin
    FConfig.View.OptionsView.DataRowHeight := FAlturaFilaOriginal;
    FAlturaFilaAplicada := False;
  end;
end;

procedure TGridPivoteVenta.CrearColumnas;
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  FConfig.View.BeginUpdate;
  try
    FColArticulo := FConfig.View.CreateColumn;
    FColArticulo.Caption := 'Artículo';
    FColArticulo.DataBinding.FieldName := FConfig.Campos.CodigoArt;
    FColArticulo.Width := 130;
    FColArticulo.Options.Editing := True;
    FColColor := FConfig.View.CreateColumn;
    FColColor.Caption := 'Color';
    FColColor.Width := 95;
    FColColor.Options.Editing := False;
    FColColor.DataBinding.ValueTypeClass := TcxStringValueType;
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
      TcxCurrencyEditProperties(Col.Properties).OnEditValueChanged :=
        CeldaTallaCambiada;
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

procedure TGridPivoteVenta.Construir;
begin
  CrearColumnas;
  CrearGestor;
  AplicarAlturaFila;
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
  RestaurarAlturaFila;
  if FConfig.View <> nil then
  begin
    FConfig.View.OnEditing := nil;
    FConfig.View.OnInitEdit := nil;
    FConfig.View.OnEditKeyDown := nil;
    FConfig.View.OnFocusedRecordChanged := nil;
    FConfig.View.OnCustomDrawCell := nil;
  end;
  RestaurarEventosDataSet;
end;

procedure TGridPivoteVenta.MostrarEditor;
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

procedure TGridPivoteVenta.CargarCachePivot;
var
  Ds: TDataSet;
  Bm: TBookmark;
  DictRepr: TDictionary<string, Integer>;
  DictTallas: TObjectDictionary<Integer, TList<Integer>>;
  ParTallas: TPair<Integer, TList<Integer>>;
  Info: TSkuPivoteVentaInfo;
  sArt, sSku, sKey, sLinea, sPrefijo, sVarSku: string;
  iLinea, iLineaRepr, iAc: Integer;
  rPedida, rEntregada, rPrecio: Double;
  iKeyPivot: Int64;
  bFiltrado: Boolean;
begin
  FPivotLineasRepr.Clear;
  FPivotCantPedida.Clear;
  FPivotCantEntregada.Clear;
  FPivotIdAc.Clear;
  FPivotSinTalla.Clear;
  FPivotArticulo.Clear;
  FPivotColorAv.Clear;
  FPivotColorTexto.Clear;
  FPivotColorCodigo.Clear;
  FPivotSkuPrefijo.Clear;
  FPivotVarSku.Clear;
  FCeldaSku.Clear;
  FCeldaLinea.Clear;
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and (not Ds.IsEmpty) then
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
          sKey := sArt + '|' + IntToStr(Info.ColorAv) + '|' +
            FloatToStrF(rPrecio, ffGeneral, 15, 4);
          if not DictRepr.TryGetValue(sKey, iLineaRepr) then
          begin
            iLineaRepr := iLinea;
            DictRepr.Add(sKey, iLineaRepr);
            FPivotLineasRepr.Add(iLineaRepr);
            FPivotArticulo.AddOrSetValue(iLineaRepr, sArt);
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
          end;
          rPedida := CampoFloat(Ds, FCfg.FieldCantidadPedida);
          rEntregada := CampoFloat(Ds, FCfg.FieldCantidadEntregada);
          if Info.TallaAv > 0 then
          begin
            if not DictTallas[iLineaRepr].Contains(Info.TallaAv) then
              DictTallas[iLineaRepr].Add(Info.TallaAv);
            iKeyPivot := Int64(iLineaRepr) * 100000 + Info.TallaAv;
            FPivotCantPedida.AddOrSetValue(iKeyPivot, rPedida);
            FPivotCantEntregada.AddOrSetValue(iKeyPivot, rEntregada);
            FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
            FCeldaLinea.AddOrSetValue(iKeyPivot, sLinea);
          end
          else
          begin
            FPivotSinTalla.AddOrSetValue(iLineaRepr, True);
            iKeyPivot := Int64(iLineaRepr) * 100000 + ID_AV_SIN_TALLA;
            FPivotCantPedida.AddOrSetValue(iKeyPivot, rPedida);
            FPivotCantEntregada.AddOrSetValue(iKeyPivot, rEntregada);
            FCeldaSku.AddOrSetValue(iKeyPivot, sSku);
            FCeldaLinea.AddOrSetValue(iKeyPivot, sLinea);
          end;
        end;
        Ds.Next;
      end;
      for ParTallas in DictTallas do
      begin
        iAc := BuscarConjuntoParaIds(ParTallas.Value);
        if iAc > 0 then
          FPivotIdAc.AddOrSetValue(ParTallas.Key, iAc);
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

procedure TGridPivoteVenta.ActualizarCaptionsLineaActiva;
var
  Ds: TDataSet;
  iLinea, iAc, i: Integer;
  Arr: TArrPosConjunto;
begin
  iLinea := 0;
  Ds := CdsLineas;
  if (Ds <> nil) and Ds.Active and (not Ds.IsEmpty) then
    iLinea := StrToIntDef(CampoTexto(Ds, FCfg.FieldLinea), 0);
  iAc := 0;
  if iLinea > 0 then
    FPivotIdAc.TryGetValue(iLinea, iAc);
  if iAc > 0 then
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

procedure TGridPivoteVenta.PublicarCantidadesPivot;
var
  ColLinea: TcxGridColumn;
  vLinea: Variant;
  iLinea, iAc, recIdx, i, iKey: Integer;
  iKeyPivot: Int64;
  rCant: Double;
  Arr: TArrPosConjunto;
begin
  if (FConfig.View <> nil) and (not FActualizandoGrid) then
  begin
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
          iLinea := StrToIntDef(VarToStr(vLinea), 0);
          if iLinea > 0 then
          begin
            if FPivotColorTexto.ContainsKey(iLinea) then
              FConfig.View.DataController.Values[recIdx, FColColor.Index] :=
                FPivotColorTexto[iLinea];
            if FPivotSinTalla.ContainsKey(iLinea) then
            begin
              iKeyPivot := Int64(iLinea) * 100000 + ID_AV_SIN_TALLA;
              rCant := 0;
              if FBanda = bpvPedida then
                FPivotCantPedida.TryGetValue(iKeyPivot, rCant)
              else
                FPivotCantEntregada.TryGetValue(iKeyPivot, rCant);
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
                rCant := 0;
                if FBanda = bpvPedida then
                  FPivotCantPedida.TryGetValue(iKeyPivot, rCant)
                else
                  FPivotCantEntregada.TryGetValue(iKeyPivot, rCant);
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
    Ds.Filtered := True;
    AplicarVisibilidadTallas;
    PublicarCantidadesPivot;
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
  iAc: Integer;
  Arr: TArrPosConjunto;
begin
  Result := False;
  AIdAv := 0;
  if (ALinea > 0) and (ACol <> nil) and EsColumnaTalla(ACol) then
  begin
    if FPivotSinTalla.ContainsKey(ALinea) then
    begin
      Result := ACol.Tag = 1;
      if Result then
        AIdAv := ID_AV_SIN_TALLA;
    end
    else if FPivotIdAc.TryGetValue(ALinea, iAc) then
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
  end;
end;

procedure TGridPivoteVenta.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TGridPivoteVenta.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(AEdit);
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
  if (Key = VK_F2) and (ssCtrl in Shift) then
  begin
    AlternarBanda;
    Key := 0;
  end
  else if (Key = VK_RETURN) and (AItem = FColArticulo) then
  begin
    sEntrada := Trim(VarToStr(AEdit.EditingValue));
    if sEntrada = '' then
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      ResolverEntrada(sEntrada);
      Key := 0;
    end;
  end;
end;

procedure TGridPivoteVenta.ViewFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  ActualizarCaptionsLineaActiva;
end;

procedure TGridPivoteVenta.CustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  Col: TcxGridColumn;
  iLinea, iIdAv: Integer;
  iKey: Int64;
  rPedida, rEntregada: Double;
  Info: TInfoBasico;
  sColorCodigo, sColorTexto: string;
begin
  ADone := False;
  if (AViewInfo.Item is TcxGridColumn) and
     (AViewInfo.GridRecord <> nil) then
  begin
    Col := TcxGridColumn(AViewInfo.Item);
    iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
    if Col = FColColor then
    begin
      sColorCodigo := '';
      sColorTexto := '';
      FPivotColorCodigo.TryGetValue(iLinea, sColorCodigo);
      FPivotColorTexto.TryGetValue(iLinea, sColorTexto);
      if (sColorCodigo <> '') and
         ObtenerInfoBasico('CO', sColorCodigo, Info) and
         PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info,
                                     sColorTexto) then
        ADone := True;
    end
    else if EsColumnaTalla(Col) then
    begin
      if TallaAvDesdeColumna(iLinea, Col, iIdAv) then
      begin
        iKey := Int64(iLinea) * 100000 + iIdAv;
        rPedida := 0;
        rEntregada := 0;
        FPivotCantPedida.TryGetValue(iKey, rPedida);
        FPivotCantEntregada.TryGetValue(iKey, rEntregada);
        PintarCeldaTalla3Cantidades(ACanvas, AViewInfo,
                                    rPedida, rEntregada);
      end
      else
      begin
        ACanvas.Brush.Color := $00E8E8E8;
        ACanvas.FillRect(AViewInfo.Bounds);
      end;
      ADone := True;
    end;
  end;
end;

procedure TGridPivoteVenta.PintarCeldaTalla3Cantidades(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; APedida,
  AEntregada: Double);
var
  b: TRect;
  hSeg, top2, top3: Integer;
  rect1, rect2, rect3: TRect;
  iFontHeight: Integer;
  cFontColor: TColor;
  fsFontStyle: TFontStyles;
  cPenColor: TColor;
  psPenStyle: TPenStyle;
  iPenWidth: Integer;
  rPendiente: Double;
  sPedida, sEntregada, sPendiente: string;
begin
  rPendiente := APedida - AEntregada;
  if rPendiente < 0 then
    rPendiente := 0;
  if (APedida <> 0) or (AEntregada <> 0) or (rPendiente <> 0) then
  begin
    sPedida := IntToStr(Round(APedida));
    sEntregada := IntToStr(Round(AEntregada));
    sPendiente := IntToStr(Round(rPendiente));
  end
  else
  begin
    sPedida := '';
    sEntregada := '';
    sPendiente := '';
  end;
  ACanvas.Brush.Color := clWindow;
  ACanvas.FillRect(AViewInfo.Bounds);
  b := AViewInfo.Bounds;
  hSeg := (b.Bottom - b.Top) div 3;
  top2 := b.Top + hSeg;
  top3 := b.Top + 2 * hSeg;
  rect1 := Rect(b.Left, b.Top, b.Right, top2);
  rect2 := Rect(b.Left, top2, b.Right, top3);
  rect3 := Rect(b.Left, top3, b.Right, b.Bottom);
  InflateRect(rect1, -1, -1);
  InflateRect(rect2, -1, -1);
  InflateRect(rect3, -1, -1);
  iFontHeight := ACanvas.Font.Height;
  cFontColor := ACanvas.Font.Color;
  fsFontStyle := ACanvas.Font.Style;
  try
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Height := ALTO_FUENTE_TALLA_TRES_CANT;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := clWindowText;
    DrawText(ACanvas.Handle, PChar(sPedida), Length(sPedida), rect1,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    ACanvas.Font.Color := clGreen;
    ACanvas.Font.Style := [fsBold];
    DrawText(ACanvas.Handle, PChar(sEntregada), Length(sEntregada), rect2,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    ACanvas.Font.Color := clBlue;
    ACanvas.Font.Style := [fsBold];
    DrawText(ACanvas.Handle, PChar(sPendiente), Length(sPendiente), rect3,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  finally
    ACanvas.Font.Height := iFontHeight;
    ACanvas.Font.Color := cFontColor;
    ACanvas.Font.Style := fsFontStyle;
  end;
  cPenColor := ACanvas.Pen.Color;
  psPenStyle := ACanvas.Pen.Style;
  iPenWidth := ACanvas.Pen.Width;
  ACanvas.Pen.Color := clSilver;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := GROSOR_LINEA_TRES_CANT;
  try
    ACanvas.MoveTo(b.Left, top2);
    ACanvas.LineTo(b.Right, top2);
    ACanvas.MoveTo(b.Left, top3);
    ACanvas.LineTo(b.Right, top3);
  finally
    ACanvas.Pen.Color := cPenColor;
    ACanvas.Pen.Style := psPenStyle;
    ACanvas.Pen.Width := iPenWidth;
  end;
  ACanvas.Brush.Style := bsSolid;
  if (FConfig.View <> nil) and
     (FConfig.View.Controller.FocusedRecord = AViewInfo.GridRecord) and
     (FConfig.View.Controller.FocusedItem = AViewInfo.Item) then
    DibujarBordeFocused(ACanvas, AViewInfo.Bounds);
end;

procedure TGridPivoteVenta.DibujarBordeFocused(ACanvas: TcxCanvas;
  const ARect: TRect);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := clNavy;
  ACanvas.Pen.Width := 2;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Rectangle(ARect.Left + 1, ARect.Top + 1,
                    ARect.Right - 1, ARect.Bottom - 1);
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TGridPivoteVenta.CeldaTallaCambiada(Sender: TObject);
var
  Rec: TcxCustomGridRecord;
  Col: TcxGridColumn;
  iLinea, iIdAv: Integer;
  iKey: Int64;
  rValor: Double;
begin
  if not (FActualizandoGrid or FGuardandoCantidad) then
  begin
    Rec := FConfig.View.Controller.FocusedRecord;
    Col := FConfig.View.Controller.FocusedColumn;
    iLinea := LineaDesdeRecord(Rec);
    if TallaAvDesdeColumna(iLinea, Col, iIdAv) then
    begin
      iKey := Int64(iLinea) * 100000 + iIdAv;
      rValor := ValorEditor(Sender, Null);
      if FBanda = bpvPedida then
        FPivotCantPedida.AddOrSetValue(iKey, rValor)
      else
        FPivotCantEntregada.AddOrSetValue(iKey, rValor);
    end;
  end;
end;

procedure TGridPivoteVenta.CeldaTallaValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Rec: TcxCustomGridRecord;
  Col: TcxGridColumn;
  iLinea, iIdAv: Integer;
  iKey: Int64;
begin
  if not (Error or FActualizandoGrid or FGuardandoCantidad) then
  begin
    Rec := FConfig.View.Controller.FocusedRecord;
    Col := FConfig.View.Controller.FocusedColumn;
    iLinea := LineaDesdeRecord(Rec);
    if TallaAvDesdeColumna(iLinea, Col, iIdAv) then
    begin
      iKey := Int64(iLinea) * 100000 + iIdAv;
      PersistirCantidadCelda(iKey, ValorEditor(Sender, DisplayValue));
    end;
  end;
end;

procedure TGridPivoteVenta.AlternarBanda;
begin
  if FBanda = bpvPedida then
    FBanda := bpvEntregada
  else
    FBanda := bpvPedida;
  if Assigned(FCfg.OnBandaCambiada) then
    FCfg.OnBandaCambiada(FBanda);
  PublicarCantidadesPivot;
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
  AValor: Double);
var
  Ds: TDataSet;
  sLineaReal: string;
  sLineaFoco: string;
  rPedida, rEntregada: Double;
  bFiltrado, bBorrar: Boolean;
begin
  if not FGuardandoCantidad then
  begin
    Ds := CdsLineas;
    sLineaFoco := Format('%.4d', [Integer(AKey div 100000)]);
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
            if FBanda = bpvPedida then
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
            else
            begin
              if AValor > rPedida then
              begin
                MessageBeep(MB_ICONWARNING);
                AValor := rPedida;
              end;
              if not (Ds.State in dsEditModes) then
                Ds.Edit;
              PonerFloat(Ds, FCfg.FieldCantidadEntregada, AValor);
              Ds.Post;
            end;
          end;
          Ds.Filtered := bFiltrado;
          if sLineaFoco <> '' then
            Ds.Locate(FCfg.FieldLinea, sLineaFoco, []);
        finally
          Ds.EnableControls;
        end;
      end
      else if FBanda = bpvPedida then
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

function TGridPivoteVenta.ResolverEntrada(const AEntrada: string): Boolean;
var
  Validador: TArticulosValidador;
  Res: TArtResolucionEntrada;
  sSku, sLinea: string;
  rPrecio: Double;
  bPrecio: Boolean;
  Ds: TDataSet;
begin
  Result := False;
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
