{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpe                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de caja: introduccion de lineas de venta.                       }
{    Captura articulos, atributos y descuentos del ticket actual.              }
{******************************************************************************}
unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inMtoGenSearch, system.Math, inMtoFrmBase,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, Data.FmtBcd, Data.SqlTimSt, cxDBData,
  cxClasses, cxGridCustomTableView, system.types,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems, system.UITypes,
  System.Actions, Vcl.ActnList, Vcl.Imaging.PngImage, inLibFotos,
  System.Generics.Collections, System.Diagnostics, cxLocalization;

const
  WM_CANCELAR_LINEA = WM_USER + 100;
  WM_SALTAR_ATRIBUTO = WM_USER + 101;
  // Diferimos FinalizarUltimoAtributo / avance de columna fuera del
  // OnButtonClick del TcxButtonEdit. Si los ejecutamos en linea, cxGrid
  // sigue manteniendo referencia al editor inplace que acaba de procesar
  // el popup; cuando FinalizarUltimoAtributo lanza el ShowMessage de
  // "no hay stock" y luego dispara DataChange via EnableControls/Append,
  // el editor inplace se desparenta y salta EInvalidOperation. Con
  // PostMessage el click handler retorna, cxGrid limpia su estado y
  // luego procesamos.
  WM_FINALIZAR_ATRIB_CAJA = WM_USER + 102;
  WM_AVANZAR_ATRIB_CAJA   = WM_USER + 103;
  // Diferimos tambien la apertura del popup desde el OnEnter del
  // TcxButtonEdit. Cuando WMAvanzarAtribCaja salta de Color a Talla,
  // ShowEdit -> InitEdit -> OnEnter ocurren en cadena en el mismo
  // callstack; el editor inplace de la talla aun no esta del todo
  // colocado y ClientToScreen pide Handle -> Parent -> EInvalidOperation.
  // Con PostMessage, OnEnter retorna, cxGrid termina de parentar, y solo
  // entonces abrimos el popup.
  WM_ABRIR_POPUP_AV       = WM_USER + 104;
  // Lectura con pistola (STX...ETX): diferimos el alta de la linea fuera del
  // OnKeyPress del editor in-place. Si resolviesemos y reestructurasemos el
  // dataset dentro del propio KeyPress, cxGrid mantiene la referencia al
  // editor que esta procesando la tecla y Append/HideEdit lo desparentan
  // (EInvalidOperation). Con PostMessage el KeyPress retorna, cxGrid limpia
  // su estado y solo entonces procesamos el codigo leido.
  WM_PROCESAR_SCANNER     = WM_USER + 105;
type
  TfrmMtoOpeCaja = class(TfrmBase)
    pnlUp: TPanel;
    pnlCli: TPanel;
    lblFecha: TcxLabel;
    pnlAccionesIzq: TPanel;
    btnF12: TcxButton;
    btnF3: TcxButton;
    btnF6: TcxButton;
    btnF5: TcxButton;
    btnF7: TcxButton;
    lblCobro: TcxLabel;
    lblBuscar: TcxLabel;
    lblTextoTarifa: TcxLabel;
    lblIndIVA: TcxLabel;
    lblOtro: TcxLabel;
    pnlAccionesDer: TPanel;
    cxgrdLineasOpe: TcxGrid;
    tvLineasOpe: TcxGridDBTableView;
    cxgrdlvlLineasOpe: TcxGridLevel;
    tvEmpleado: TcxGridDBColumn;
    tvArticulo: TcxGridDBColumn;
    tvDescripcion: TcxGridDBColumn;
    tvUds: TcxGridDBColumn;
    tvPrecioUni: TcxGridDBColumn;
    tvDescuento: TcxGridDBColumn;
    tvDescuentoMenos: TcxGridDBColumn;
    tvTotal: TcxGridDBColumn;
    lblTotal: TcxLabel;
    btnF8: TcxButton;
    lblEliminar: TcxLabel;
    lblNombreEmpleado: TcxLabel;
    lblCliente: TcxLabel;
    btnCodigoCliente: TcxButtonEdit;
    lblNombreCliente: TcxLabel;
    tmrReloj: TTimer;
    dsLineas: TDataSource;
    jvEnterTab: TJvEnterAsTab;
    lblFechaCaja: TcxLabel;
    btnCodigoEmpleado: TcxButtonEdit;
    lblTarifa: TcxLabel;
    lblInstrucciones: TcxLabel;
    pnlBusqueda: TPanel;
    cxgrdStock: TcxGrid;
    dbtvStock: TcxGridDBTableView;
    cxgrdlvlBusqueda: TcxGridLevel;
    dsStock: TDataSource;
    pnlFotoStock: TPanel;
    imgFotoStock: TImage;
    splFotoStock: TcxSplitter;
    splOpe: TcxSplitter;
    cxstylrpstry: TcxStyleRepository;
    styPrincipal: TcxStyle;
    styImporte: TcxStyle;
    tmrBusq: TTimer;
    dsBusq: TDataSource;
    qryBusq: TUniQuery;
    tvrBusq: TcxGridViewRepository;
    dbtvBusq: TcxGridDBTableView;
    styCabecera: TcxStyle;
    dbtvBusqINPUT_BUSQUEDA: TcxGridDBColumn;
    dbtvBusqCODIGO_ARTICULO: TcxGridDBColumn;
    dbtvBusqDESCRIPCION_ARTICULO: TcxGridDBColumn;
    dbtvBusqTEMPORADA: TcxGridDBColumn;
    dbtvBusqPROVEEDOR: TcxGridDBColumn;
    edtrepArticulo: TcxEditRepository;
    repSoloTexto: TcxEditRepositoryTextItem;
    repComboBox: TcxEditRepositoryExtLookupComboBoxItem;
    btnF61: TcxButton;
    lblBusqTick: TcxLabel;
    alCajaOpe: TActionList;
    actBuscarEmpleados: TAction;
    actSalir: TAction;
    actEliminarLinea: TAction;
    actCobro: TAction;
    btnF2: TcxButton;
    lblCargarCta: TcxLabel;
    actCargarCta: TAction;
    actGuardarLayout: TAction;
    actAbrirArticulos: TAction;
    actConsultaStock: TAction;
    pnlTotal: TPanel;
    pnlBotones: TPanel;
    procedure actAbrirArticulosExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnF5Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClientePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cxGrid1Enter(Sender: TObject);
    procedure tvArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClienteExit(Sender: TObject);
    procedure btnCodigoEmpleadoExit(Sender: TObject);
    procedure cxGrid1DBTableView1InitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure cxGrid1DBTableView1EditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
      Shift: TShiftState);
    procedure OnAtributoChanged(Sender: TObject);
    procedure cxGrid1Exit(Sender: TObject);
    procedure tvUdsPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoMenosPropertiesEditValueChanged(Sender: TObject);
    procedure tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
    procedure cxGrid1DBTableView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tmrBusqTimer(Sender: TObject);
    procedure tvArticuloGetProperties(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AProperties: TcxCustomEditProperties);
    procedure repComboBoxPropertiesInitPopup(Sender: TObject);
    procedure tvArticuloPropertiesCloseUp(Sender: TObject);
    procedure cxGrid1DBTableView1CanFocusRecord(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; var AAllow: Boolean);
    procedure tvTotalPropertiesEditValueChanged(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure actBuscarEmpleadosExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actEliminarLineaExecute(Sender: TObject);
    procedure actCobroExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvArticuloPropertiesChange(Sender: TObject);
    procedure cxGrid1DBTableView1Editing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvUdsPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure cxGrid1DBTableView1MouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnF2Click(Sender: TObject);
    procedure actCargarCtaExecute(Sender: TObject);
    procedure cxGrid1DBTableView1FocusedRecordChanged(
      Sender: TcxCustomGridTableView; APrevFocusedRecord,
      AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure tvLineasOpeCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure dbtvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    procedure GuardarLayoutCaja;
    procedure RestaurarLayoutCaja;
    procedure CargarDepositosF2;
    procedure AsegurarLineaNueva;
    procedure ActualizarFoco;
    function BuscarArticulo:String;
    procedure WMCancelarLinea(var Msg: TMessage); message WM_CANCELAR_LINEA;
    function ConsolidarSiExiste(SkuBuscado: string): Boolean;
//    procedure ForzarDespliegue(Sender: TObject);
    procedure ConstruirColumnasDinamicas;
    procedure RellenarAtributosDesdeSku(Sku: string);
    procedure ActualizarColumnasDinamicas(ArticuloPadre: string);
    function ObtenerColumnaPorTag(NumColumn:Integer):TcxGridDBColumn;
    function RellenarDatosArticuloEnDataset(Codigo: string): Boolean;
    procedure RecalcularPrecioDesdeSku(sSKU:string);
    procedure ActualizarLabelTotal(Sender: TObject; NuevoTotal: Currency);
    procedure ConsultarStock(const CodigoInput: string);
    function  ValidarSkuParaVenta(const SkuFinal: string): Boolean;
    procedure EliminarLineaPorValidacion;
    procedure BuscarEmpleados;
    procedure BuscarClientes;
    function HayLineasConDeposito: Boolean;
    procedure RepartirDescuentoGlobalLinea(ImporteDescuentoGlobal: Currency);
    procedure WMSaltarAtributo(var Msg: TMessage); message WM_SALTAR_ATRIBUTO;
    procedure DsLineasDataChange(Sender: TObject; Field: TField);
    procedure RefrescarFotoStock;
    procedure tvLineasOpeAvButtonClick(Sender: TObject;
                                       AButtonIndex: Integer);
    procedure AbrirPopupAvEnEntrada(Sender: TObject);
    procedure CargarAvsValidos(const ACodArt: string;
                               AOrden: Integer;
                               var AAvs: TArray<string>);
    procedure RegistrarValorAtributo(AOrden: Integer;
                                     const AvNuevo: string);
    procedure FinalizarUltimoAtributo;
    procedure WMFinalizarAtribCaja(var Msg: TMessage);
                                       message WM_FINALIZAR_ATRIB_CAJA;
    procedure WMAvanzarAtribCaja(var Msg: TMessage);
                                       message WM_AVANZAR_ATRIB_CAJA;
    procedure WMAbrirPopupAv(var Msg: TMessage);
                                       message WM_ABRIR_POPUP_AV;
    procedure WMProcesarScanner(var Msg: TMessage);
                                       message WM_PROCESAR_SCANNER;
    procedure ProcesarLecturaScanner(const ACodigo: string);
//    procedure LogPerfCaja(const AContexto, ADetalles: string);
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
  public
    DatosCaja: TdmCajaOpe;
  private
    FScanBuffer: string;
    FLeyendoScanner: Boolean;
    // Activo mientras resolvemos una lectura con pistola: fuerza a
    // RellenarDatosArticuloEnDataset a buscar SOLO en codigos de barras.
    FResolviendoPorScanner: Boolean;
    // Codigo leido pendiente de procesar (lo consume WMProcesarScanner).
    FCodigoScanPend: string;
    // Detector de lectura por VELOCIDAD de tecleo (codigo de barras + CR sin
    // STX/ETX): el lector teclea en rafaga. FScanVelBuffer acumula los
    // caracteres rapidos y consecutivos, FScanVelTick guarda el instante de la
    // ultima tecla y FScanVelComido marca que el Enter ya se consumio en
    // FormKeyDown (para tragar su #13 en FormKeyPress).
    FScanVelBuffer: string;
    FScanVelTick: Cardinal;
    FScanVelComido: Boolean;
    FValidandoCliente: Boolean;
    FCodigoEmpresa:String;
    FCodigoAlmacen, FCodigoCaja:String;
    FFecha:TDate;
    // CAMBIO 1: Variables de control para evitar re-entradas y bucles
    // Guarda el nº de atributos aunque el dataset haga Post
    FNumAtributosActual: Integer;
    // Evita re-entrada en el bloque del último atributo
    FProcesandoAtributo: Boolean;
    // Evita que ForzarDespliegue dispare OnAtributoChanged
    FInicializandoCombo: Boolean;
    FUltimoArticuloPadre: string;
    FActualizandoDepositos: Boolean;
    // Motivo por el que RellenarDatosArticuloEnDataset rechazó el último
    // artículo (existe y activo, pero sin SKU vendible). Lo consume el
    // validador de caja para dar un mensaje exacto en vez del genérico
    // "no encontrado o descatalogado".
    FMotivoRechazoArticulo: string;
  private
    FNumeroCajaActual: Integer;
    // Bitmap reusable para pintar el cuadradito del color actual en el boton
    // del editor de atributos (Color, Talla, ...). Se redimensiona a 14x14
    // en cada InitEdit.
    FBmpSwatchBoton: TBitmap;
    // Stopwatch para medir el tiempo total desde que se valida el codigo de
    // articulo hasta que el popup de seleccion de AV se abre. Se arranca
    // en tvArticuloPropertiesValidate y se cierra en WMAbrirPopupAv.
    FswArtAPopup: TStopwatch;
    const MAX_CAJAS = 5;
  public
    procedure PrepararValores(AEmpresa, AAlmacen, ACaja: string;
                              AFecha: TDateTime);
    function IntentarCerrar:Boolean;
    property NumeroCajaActual: Integer read FNumeroCajaActual
                                       write FNumeroCajaActual;
  end;

var
  frmMtoOpeCaja: TfrmMtoOpeCaja;

implementation

{$R *.dfm}

uses
  inMtoCajaMenu,
  inLibGlobalVar,
  inLibUser,
  inLibLog,
  inMtoCajaFaseCobro, inLibDevExp, inLibtb,
  inLibFacturas, inLibGenBusq, inLibCajaParam, inLibGenerarTicket,
  inMtoModalGenImpSave, inLibLayoutForm,
  inLibArticulosValidador, inLibArticulosResolver,
  inLibArticulosAtributosLookup,
  inLibAtributosPaleta,
  inLibShowMto, inMtoPrincipal,
  inMtoStockConsulta,
  System.StrUtils;

procedure TfrmMtoOpeCaja.ActualizarFoco;
begin
  if btnCodigoEmpleado.Text = '' then
  begin
    if btnCodigoEmpleado.CanFocus then
      btnCodigoEmpleado.SetFocus;
  end
  else if cxgrdLineasOpe.CanFocus then
  begin
    cxgrdLineasOpe.SetFocus;
  end;
end;

procedure TfrmMtoOpeCaja.WMSaltarAtributo(var Msg: TMessage);
begin
  if (tvLineasOpe.Controller.EditingController <> nil) and
     (tvLineasOpe.Controller.EditingController.IsEditing) then
  begin
    PostMessage(tvLineasOpe.Controller.EditingController.Edit.Handle,
                WM_KEYDOWN,
                VK_RETURN, 0);
  end;
end;

procedure TfrmMtoOpeCaja.PrepararValores(AEmpresa, AAlmacen, ACaja: string;
                                         AFecha: TDateTime);
var
  EmpleadoAnterior, NombreEmpleadoAnterior: string;
  sCodEmpleadoDefecto: string;
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FCodigoCaja    := ACaja;
  FFecha         := AFecha;

  if Assigned(DatosCaja) then
  begin
    // 1. Guardar el empleado actual antes de vaciar
    EmpleadoAnterior := '';
    NombreEmpleadoAnterior := '';
    if DatosCaja.cdsCabecera.Active and not DatosCaja.cdsCabecera.IsEmpty then
    begin
      EmpleadoAnterior :=
            DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
      NombreEmpleadoAnterior := lblNombreEmpleado.Caption;
    end;
    if (tvLineasOpe.Controller.EditingController <> nil) and
       tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      tvLineasOpe.Controller.EditingController.HideEdit(True);
    end;
    // 2. Vaciar las líneas de la venta anterior
    if DatosCaja.cdsLineas.Active then
    begin
      DatosCaja.cdsLineas.DisableControls;
      try
        // --- CLAVE: Limpia el "Delta" (registros fantasma pendientes) ---
        DatosCaja.cdsLineas.CancelUpdates;

        if DatosCaja.cdsLineas.RecordCount > 0 then
          DatosCaja.cdsLineas.EmptyDataSet;
      finally
        DatosCaja.cdsLineas.EnableControls;
      end;
    end;
    tvLineasOpe.DataController.Refresh;
    // 3. Vaciar la cabecera anterior y crear un registro nuevo
    if DatosCaja.cdsCabecera.Active then
    begin
      DatosCaja.cdsCabecera.CancelUpdates;
      DatosCaja.cdsCabecera.EmptyDataSet;
      DatosCaja.cdsCabecera.Append;
    end;
    lblNombreCliente.Caption := '';
    btnCodigoCliente.Text := '';
    // 4. Aplicar valores base
    DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime := FFecha;
    AplicarValoresPorDefecto(DatosCaja.cdsCabecera, 'fza_facturas');
    DatosCaja.cdsCabecera.FieldByName('CODIGO_EMP_FAC').AsString :=
      FCodigoEmpresa;
    DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime := FFecha;
    DatosCaja.cdsCabecera.FieldByName('TIPO_FAC').AsString := 'SIMPLIFICADA';
    // --- 5. EVALUACIÓN DE PARÁMETROS DE INICIO ---
    // A) Tarifa por defecto (como tenías en FormShow)
    DatosCaja.cdsCabecera.FieldByName(
                                  'TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
                                  oCajaParams.GetString('vgerDefTarifa', 'PVP');
    lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    // B) Empleado: Mantenemos el anterior, o buscamos el parámetro por defecto
    if EmpleadoAnterior <> '' then
    begin
      DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
                                                               EmpleadoAnterior;
      btnCodigoEmpleado.Text := EmpleadoAnterior;
      lblNombreEmpleado.Caption := NombreEmpleadoAnterior;
    end
    else if oCajaParams.GetBool('vgerFillEmpleadoDefecto', False) then
    begin
      sCodEmpleadoDefecto := oCajaParams.GetString('vgerCodEmpleadoDefecto',
                                                   '');
      if sCodEmpleadoDefecto <> '' then
      begin
        btnCodigoEmpleado.Text := sCodEmpleadoDefecto;
        btnCodigoEmpleado.ValidateEdit(True);
      end;
    end;
  end;
  dbtvStock.ClearItems;
  lblNombreCliente.Caption := 'VENTA CONTADO';
  btnCodigoCliente.Text := '';
  lblTotal.Caption := 'Total 0,00 €';
  if Self.Visible then
    ActualizarFoco;
end;

procedure TfrmMtoOpeCaja.ConsultarStock(const CodigoInput: string);
var
  View   : TcxGridDBTableView;
  I      : Integer;
  Mapa   : TDictionary<string, string>;
  sw, swSP, swBuild, swFit : TStopwatch;
  msSP, msBuild, msFit : Int64;
begin
  if CodigoInput = '' then Exit;
  sw := TStopwatch.StartNew;
  msSP := 0; msBuild := 0; msFit := 0;
  View := dbtvStock;
  View.BeginUpdate;
  try
    with DatosCaja.qryStock do
    begin
      Close;
      View.ClearItems;
      Connection := inLibGlobalVar.oConn;
      ParamByName('ARTICULO').AsString := CodigoInput;
      swSP := TStopwatch.StartNew;
      Open;
      msSP := swSP.ElapsedMilliseconds;
      if not IsEmpty then
      begin
        swBuild := TStopwatch.StartNew;
        View.DataController.CreateAllItems;
        for I := 0 to View.ColumnCount - 1 do
        begin
          if (I = 0) or (I = 1) then
            View.Columns[I].HeaderAlignmentHorz := taLeftJustify
          else
            View.Columns[I].HeaderAlignmentHorz := taRightJustify;
        end;
        msBuild := swBuild.ElapsedMilliseconds;
      end;
    end;
  finally
    View.EndUpdate;
  end;
  if DatosCaja.qryStock.Active and not DatosCaja.qryStock.IsEmpty then
  begin
    View.BeginUpdate;
    try
      swFit := TStopwatch.StartNew;
      try
        View.ApplyBestFit;
      except
      end;
      // ApplyBestFit solo mide texto: si la celda de la PRIMERA columna
      // (Codigo, donde dibujamos el swatch en dbtvStockCustomDrawCell)
      // tiene match en la paleta basica, le sumamos ANCHO_SWATCH_PX para
      // que el cuadradito no recorte el codigo. El resto de columnas
      // (talla pivotada, total) no llevan swatch -> no las tocamos.
      Mapa := ObtenerMapaAtributosGlobal;
      if (Mapa <> nil) and (Mapa.Count > 0) and (View.ColumnCount > 0) then
        AjustarAnchoColumnaParaSwatch(View.Columns[0], Mapa);
      msFit := swFit.ElapsedMilliseconds;
    finally
      View.EndUpdate;
    end;
  end;
//  LogPerfCaja('CajaOpe.ConsultarStock',
//    Format('art=%s | SP=%d | Build=%d | Fit=%d | cols=%d | total=%d ms',
//           [CodigoInput, msSP, msBuild, msFit, View.ColumnCount,
//            sw.ElapsedMilliseconds]));
end;

procedure TfrmMtoOpeCaja.tvLineasOpeCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // Pinta el cuadradito de la paleta basica al lado del valor de atributo
  // (Color = MALVA, Talla = 48, ...) en las celdas de las lineas de venta.
  // Mismo helper que usa inMtoInventarios.
  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TfrmMtoOpeCaja.dbtvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // Solo pintamos swatch en la primera columna (Codigo "CODART/COLOR").
  // Las columnas pivotadas de talla traen cantidades y no queremos
  // cuadradito al lado de cada numero — basta con la del codigo.
  if (AViewInfo = nil) or (AViewInfo.Item = nil) then Exit;
  if AViewInfo.Item.VisibleIndex <> 0 then Exit;
  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
end;

//procedure TfrmMtoOpeCaja.LogPerfCaja(const AContexto, ADetalles: string);
//begin
//  // Replica el formato '-- PERF -- HH:NN:SS.zzz [PERF:ctx] det' que ya se
//  // usa para articulos. Escribe directamente al cxMemo de SQL para que
//  // aparezca intercalado con las trazas de UniSQLMonitor, y al log si
//  // esta activo.
////  if Assigned(oMemoSQL) then
////    oMemoSQL.Lines.Add(
////      Format('-- PERF -- %s  [PERF:%s] %s',
////             [FormatDateTime('hh:nn:ss.zzz', Now), AContexto, ADetalles]));
////  try
////    inLibLog.Log.LogInfo(
////      Format('[PERF:%s] %s', [AContexto, ADetalles]));
////  except
////    // inLibLog puede no estar inicializado en sesiones cortas; no rompemos.
////  end;
//end;

function TfrmMtoOpeCaja.ValidarSkuParaVenta(const SkuFinal: string): Boolean;
var
  qry: TUniQuery;
  Cantidad: Double;
  MensajeStock: string;
  SkuLimpio: string;
begin
  Result := True;
  SkuLimpio := Trim(SkuFinal);
  if SkuLimpio = '' then Exit;

  if oCajaParams.GetBool('vgerChkExistOnly', True) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text :=
        'SELECT ESACTIVO_SKU FROM fza_articulos_skus ' +
        ' WHERE CODIGO_UNIDAD_SKU = :SKU';
      qry.ParamByName('SKU').AsString := SkuLimpio;
      qry.Open;
      if qry.IsEmpty then
      begin
        ShowMessage('El SKU "' + SkuLimpio + '" no existe en ' +
                    'fza_articulos_skus. No se puede vender.');
        Result := False;
        Exit;
      end;
      if qry.FieldByName('ESACTIVO_SKU').AsString <> 'S' then
      begin
        ShowMessage('El SKU "' + SkuLimpio + '" no está activo. ' +
                    'No se puede vender.');
        Result := False;
        Exit;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;

  // Comprobar stock: si vgerChkStockOnly=True bloquea la venta;
  // si es False, avisa pero deja continuar
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    if Trim(FCodigoAlmacen) <> '' then
    begin
      qry.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU ' +
        '   AND CODIGO_ALM_STK    = :ALM';
      qry.ParamByName('SKU').AsString := SkuLimpio;
      qry.ParamByName('ALM').AsString := FCodigoAlmacen;
    end
    else
    begin
      qry.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU';
      qry.ParamByName('SKU').AsString := SkuLimpio;
    end;
    qry.Open;
    Cantidad := qry.FieldByName('QTY').AsFloat;
    if Cantidad <= 0 then
    begin
      MensajeStock := oCajaParams.GetString('vgerAvisoStockWarning',
        'Artículo sin stock. Compruebe stock en almacén.');
      ShowMessage(MensajeStock);
      // Si vgerChkStockOnly=True, bloquear la venta
      if oCajaParams.GetBool('vgerChkStockOnly', False) then
      begin
        Result := False;
        Exit;
      end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoOpeCaja.EliminarLineaPorValidacion;
begin
  if not Assigned(DatosCaja) then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;

  if DatosCaja.cdsLineas.State = dsInsert then
    DatosCaja.cdsLineas.Cancel
  else if DatosCaja.cdsLineas.State = dsEdit then
  begin
    DatosCaja.cdsLineas.Cancel;
    if not DatosCaja.cdsLineas.IsEmpty then
      DatosCaja.cdsLineas.Delete;
  end;

  //dbtvStock.ClearItems;
  GridRecalc(nil,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  AsegurarLineaNueva;
end;

// Hook de lectura con pistola a nivel de FORMULARIO (KeyPreview heredado de
// TfrmBase = True): da igual que control tenga el foco. Hay DOS detectores:
//   1) Trama STX(#2)+codigo+ETX(#3): el lector envuelve el codigo. Acumulamos
//      entre STX y ETX consumiendo las teclas (no ensucian el control).
//   2) Por VELOCIDAD de tecleo (codigo de barras + CR, sin STX/ETX): el lector
//      teclea en rafaga. Aqui solo acumulamos la rafaga con su cadencia; la
//      decision (rafaga + Enter) se toma en FormKeyDown, para adelantarse al
//      editor del grid y a jvEnterTab.
procedure TfrmMtoOpeCaja.FormKeyPress(Sender: TObject; var Key: Char);
var
  ahora, delta: Cardinal;
begin
  if Key = #2 then
  begin
    FLeyendoScanner := True;
    FScanBuffer := '';
    FScanVelBuffer := '';
    tmrBusq.Enabled := False;
    Key := #0;
    Exit;
  end;
  if FLeyendoScanner then
  begin
    if (Key = #3) then
    begin
      tmrBusq.Enabled := False;
      FLeyendoScanner := False;
      Key := #0;
      // Diferimos la resolucion y el alta de linea: dentro del propio
      // KeyPress no podemos reestructurar el dataset (cxGrid aun referencia
      // el editor in-place). Guardamos el codigo y lo procesa
      // WMProcesarScanner cuando el KeyPress haya retornado.
      if Trim(FScanBuffer) <> '' then
      begin
        FCodigoScanPend := Trim(FScanBuffer);
        PostMessage(Handle, WM_PROCESAR_SCANNER, 0, 0);
      end;
      FScanBuffer := '';
    end
    else
    begin
      FScanBuffer := FScanBuffer + Key;
      Key := #0;
    end;
    Exit;
  end;
  // --- Detector 2: acumulacion por velocidad de tecleo ----------------------
  if not oCajaParams.GetBool('vgerScanVelActivo', True) then
    Exit;
  ahora := GetTickCount;
  delta := ahora - FScanVelTick;
  FScanVelTick := ahora;
  // El #13 del Enter ya consumido en FormKeyDown: lo tragamos para que no
  // llegue al control enfocado.
  if FScanVelComido and (Key = #13) then
  begin
    FScanVelComido := False;
    Key := #0;
    Exit;
  end;
  // El buffer SOLO crece con caracteres imprimibles rapidos y consecutivos
  // (firma del lector). Cualquier caracter lento o de control lo reinicia, asi
  // que el tecleo humano nunca acumula longitud.
  if Key >= ' ' then
  begin
    if delta <= Cardinal(oCajaParams.GetInt('vgerScanVelMs', 40)) then
      FScanVelBuffer := FScanVelBuffer + Key
    else
      FScanVelBuffer := Key;
  end
  else
    FScanVelBuffer := '';
end;

procedure TfrmMtoOpeCaja.WMProcesarScanner(var Msg: TMessage);
begin
  if FCodigoScanPend <> '' then
  begin
    ProcesarLecturaScanner(FCodigoScanPend);
    FCodigoScanPend := '';
  end;
end;

// Procesa un codigo leido con pistola desde cualquier punto del formulario:
// lo resuelve SOLO contra codigos de barras y, si es vendible, da de alta la
// linea de venta automaticamente y deja una nueva linea lista para el
// siguiente escaneo. El alta de linea es SIEMPRE, con independencia del
// parametro vgerMoverLineaIdentif (que solo gobierna la entrada manual).
// Unica precondicion: el vendedor (cajero) debe estar dado de alta.
procedure TfrmMtoOpeCaja.ProcesarLecturaScanner(const ACodigo: string);
var
  Validador  : TArticulosValidador;
  Resolucion : TArtResolucionEntrada;
  sSku       : string;
begin
  if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active then
  begin
    // Precondicion: sin vendedor dado de alta no se admiten lecturas.
    if Trim(DatosCaja.cdsCabecera.FieldByName(
                                       'CODIGO_CAJERO_FAC').AsString) = '' then
    begin
      ShowMessage('Da de alta el vendedor antes de leer artículos.');
      if btnCodigoEmpleado.CanFocus then
        btnCodigoEmpleado.SetFocus;
    end
    else
    begin
      tmrBusq.Enabled := False;
      // Cerramos el editor in-place (si lo hubiera) sin volcar su contenido.
      if tvLineasOpe.Controller.EditingController.IsEditing then
        tvLineasOpe.Controller.EditingController.HideEdit(False);
      // CLAVE: resolvemos el codigo SOLO contra codigos de barras ANTES de
      // crear/rellenar ninguna linea. Asi decidimos si hay que consolidar (el
      // SKU ya esta en el ticket) sin haber grabado todavia una linea de
      // trabajo, que es justo lo que generaba el duplicado.
      Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
      try
        Resolucion := Validador.ResolverCodigoBarras(ACodigo);
      finally
        FreeAndNil(Validador);
      end;
      sSku := Resolucion.CodigoSku;
      if not Resolucion.Encontrado then
        ShowMessage('Código de barras no encontrado: ' + ACodigo)
      else if (Trim(sSku) <> '') and not ValidarSkuParaVenta(sSku) then
      begin
        // SKU no vendible (inactivo o sin stock con bloqueo): ValidarSku ya
        // mostro el motivo. No añadimos ni tocamos ninguna linea.
      end
      else
      begin
        // Garantizamos una linea de trabajo VACIA en insercion, sin pisar
        // lineas ya confirmadas (la lectura puede llegar con el foco en
        // cualquier control). Esa linea vacia no comparte SKU, asi que no
        // interfiere en la deteccion de duplicados.
        if DatosCaja.cdsLineas.State = dsInsert then
        begin
          if Trim(DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString) <> '' then
          begin
            DatosCaja.cdsLineas.Post;
            DatosCaja.cdsLineas.Append;
          end;
        end
        else
        begin
          if DatosCaja.cdsLineas.State = dsEdit then
            DatosCaja.cdsLineas.Post;
          DatosCaja.cdsLineas.Append;
        end;
        // ¿El SKU ya esta en el ticket? -> sumamos cantidad en esa linea y NO
        // creamos otra. ConsolidarSiExiste se encarga de cancelar/recolocar la
        // linea de trabajo vacia (su recalculo interno la trata como insert
        // vacio). Si no esta -> rellenamos la linea de trabajo y la grabamos.
        if (Trim(sSku) <> '') and ConsolidarSiExiste(sSku) then
        begin
          // Consolidado: nada mas que hacer; la unidad ya se sumo.
        end
        else
        begin
          FResolviendoPorScanner := True;
          try
            RellenarDatosArticuloEnDataset(ACodigo);
          finally
            FResolviendoPorScanner := False;
          end;
          if (Trim(sSku) <> '') and (sSku <> Resolucion.CodigoArticulo) then
            RellenarAtributosDesdeSku(sSku);
          if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
            DatosCaja.cdsLineas.Post;
          GridRecalc(nil,
                     tvLineasOpe,
                     DatosCaja.cdsLineas,
                     DatosCaja.cdsCabecera,
                     ActualizarLabelTotal);
        end;
      end;
      // Dejamos una linea editable y el foco en la celda de articulo de la
      // rejilla, lista para encadenar lecturas venga de donde venga el foco.
      AsegurarLineaNueva;
      tvLineasOpe.Controller.EditingController.ShowEdit;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.WMCancelarLinea(var Msg: TMessage);
var
  VieneDeDep: string;
begin
  if (DatosCaja.cdsLineas.Active) then
  begin
    // NUEVO: Bloqueo de borrado por atajo
    if not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep :=
        DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
      begin
        ShowMessage(
          'No se puede cancelar o eliminar una línea vinculada a un depósito.');
        Exit;
      end;
    end;
    if (DatosCaja.cdsLineas.State = dsInsert) then
      DatosCaja.cdsLineas.Cancel
    else if not DatosCaja.cdsLineas.IsEmpty then
      DatosCaja.cdsLineas.Delete;

    GridRecalc(nil,
               tvLineasOpe,
               DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera,
               ActualizarLabelTotal);
    AsegurarLineaNueva;
  end;
end;

procedure TfrmMtoOpeCaja.tmrBusqTimer(Sender: TObject);
var
  EditActivo: TcxCustomEdit;
  TextEdit: TcxCustomTextEdit;
  TextoBusqueda: string;
begin
  tmrBusq.Enabled := False;
  EditActivo := nil;
  dbtvBusq.BeginUpdate;
  try
    dbtvBusq.DataController.DataSource := nil;
    dbtvBusq.DataController.Filter.Clear;
    dbtvBusq.DataController.Filter.Active := False;
    dbtvBusq.Controller.IncSearchingText := '';
    if tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      EditActivo := tvLineasOpe.Controller.EditingController.Edit;
      if EditActivo <> nil then
      begin
        // Cuando el timer dispara, el editor activo puede no ser el de
        // tvArticulo (el usuario pudo moverse a otra celda durante los
        // 500ms de debounce). Solo casteamos a TcxCustomTextEdit si el
        // editor realmente lo es; en otro caso usamos EditingValue.
        // Esto evita el EInvalidCast cuando el editor activo no es de
        // tipo texto (p.ej. TcxButtonEdit de columnas de atributo).
        if EditActivo is TcxCustomTextEdit then
        begin
          TextEdit := TcxCustomTextEdit(EditActivo);
          if TextEdit.SelLength > 0 then
            TextoBusqueda := Copy(TextEdit.Text, 1, TextEdit.SelStart)
          else
            TextoBusqueda := TextEdit.Text;
        end
        else
          TextoBusqueda := VarToStr(EditActivo.EditingValue);
        TextoBusqueda := Trim(TextoBusqueda);
        if Length(TextoBusqueda) >= 1 then
        begin
          qryBusq.Connection := oConn;
          qryBusq.Close;
          qryBusq.ParamByName('TARIFA').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
          qryBusq.ParamByName('FECHA_TARIFA').AsDate :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                                       'FECHA_FAC').AsDateTime;
          qryBusq.ParamByName('TOKEN').AsString := '%' + TextoBusqueda + '%';
          qryBusq.Open;
          // Diagnostico: registramos el resultado de la busqueda incremental
          // para saber si la vista vi_art_busquedas devuelve filas. El log SQL
          // estandar marca filas=- en queries con LIMIT, asi que aqui lo
          // contamos explicitamente. Si filas=0, el problema es de datos (la
          // vista no devuelve nada para esa TARIFA/FECHA) y no del UI.
          try
            inLibLog.Log.LogInfo(Format('qryBusq.Open: TARIFA="%s" ' +
              'FECHA_TARIFA="%s" TOKEN="%s" IsEmpty=%s RecordCount=%d',
              [qryBusq.ParamByName('TARIFA').AsString,
               DateToStr(qryBusq.ParamByName('FECHA_TARIFA').AsDate),
               qryBusq.ParamByName('TOKEN').AsString,
               BoolToStr(qryBusq.IsEmpty, True),
               qryBusq.RecordCount]));
            // Volcamos los primeros 5 codigos para verificar que la vista
            // realmente devuelve algo aprovechable (no nulls, codigos validos)
            if not qryBusq.IsEmpty then
            begin
              qryBusq.First;
              while (not qryBusq.Eof) and (qryBusq.RecNo <= 5) do
              begin
                inLibLog.Log.LogInfo(Format('qryBusq fila %d: cod="%s" desc="%s"',
                  [qryBusq.RecNo,
                   qryBusq.FieldByName('CODIGO_PADRE').AsString,
                   qryBusq.FieldByName('DESCRIPCION_ART').AsString]));
                qryBusq.Next;
              end;
              qryBusq.First;
            end;
          except
            on E: Exception do
              inLibLog.Log.LogWarning('qryBusq diagnostico: ' +
                                      E.ClassName + ' ' + E.Message);
          end;
          dbtvBusq.DataController.DataSource := dsBusq;
          dbtvBusq.DataController.Refresh;
        end;
      end;
    end;
  finally
    dbtvBusq.EndUpdate;
  end;
  if (EditActivo is TcxExtLookupComboBox) then
    begin
       if not TcxExtLookupComboBox(EditActivo).DroppedDown then
       begin
          if not qryBusq.IsEmpty then
             TcxExtLookupComboBox(EditActivo).DroppedDown := True;
       end
       else
       begin
          TcxExtLookupComboBox(EditActivo).Properties.DropDownRows := 15;
       end;
    end;
end;

procedure TfrmMtoOpeCaja.tvArticuloGetProperties(Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord; var AProperties: TcxCustomEditProperties);
var
  EsLaCeldaFocale: Boolean;
  ValorActual: Variant;
begin
  if (ARecord = nil) or (tvLineasOpe.Controller = nil) then
    Exit;
  ValorActual := ARecord.Values[Sender.Index];
  if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
  begin
    AProperties := repSoloTexto.Properties;
    Exit;
  end;
  EsLaCeldaFocale := (tvLineasOpe.Controller.FocusedRecord = ARecord)
                     and
                     (tvLineasOpe.Controller.FocusedItem = Sender);
  if EsLaCeldaFocale then
    AProperties := repComboBox.Properties
  else
    AProperties := repSoloTexto.Properties;
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesChange(Sender: TObject);
begin
  if not FLeyendoScanner then
  begin
    tmrBusq.Enabled := False;
    tmrBusq.Enabled := True;
  end;
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesCloseUp(Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    if Combo.Properties.View is TcxGridDBTableView then
    begin
      with TcxGridDBTableView(Combo.Properties.View) do
      begin
        BeginUpdate;
        try
          Controller.IncSearchingText := '';
          DataController.Filter.Clear;
          DataController.Filter.Active := False;
        finally
          EndUpdate;
        end;
      end;
    end;
  end;
end;

function TfrmMtoOpeCaja.BuscarArticulo: String;
  // Helper: ajusta DisplayLabel y, si procede, DisplayFormat de un campo.
  // El cast depende del TField concreto (TFloatField / TFMTBCDField /
  // TDateField / TSQLTimeStampField segun como UniDAC mapea la columna).
  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then Exit;
    if ALabel <> '' then
      F.DisplayLabel := ALabel;
    if AFormat = '' then Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TFMTBCDField then
      TFMTBCDField(F).DisplayFormat := AFormat
    else if F is TDateField then
      TDateField(F).DisplayFormat := AFormat
    else if F is TDateTimeField then
      TDateTimeField(F).DisplayFormat := AFormat
    else if F is TSQLTimeStampField then
      TSQLTimeStampField(F).DisplayFormat := AFormat;
  end;
begin
  // Popup de busqueda de articulos lanzado desde F3 en caja. Antes
  // llamabamos a PRC_BUSQUEDA_ARTICULOS (TUniStoredProc); ahora atacamos
  // vi_art_busquedas directamente como TUniQuery parametrizado por
  // tarifa y fecha (mismo criterio de vigencia que el desplegable inline
  // qryBusq). Anadimos columnas Temporada (LEFT JOIN
  // fza_articulos_propiedades + fza_propiedades_valores con
  // CODIGO_PROP_ARTPROP = 'TEMPORADA') y Proveedor (RAZON_SOCIAL_PROVEEDOR
  // ya en la vista). Configuramos DisplayLabel/DisplayFormat por campo
  // para que la grilla salga legible aunque no haya layout guardado en
  // fza_usuarios_perfiles para frmMtoArtFacSearch; si hay layout,
  // PonerAnchosTitulos lo sobrepone (vease inLibDevExp).
  var unqryBusq := TUniQuery.Create(nil);
  try
    unqryBusq.Connection := oConn;
    unqryBusq.SQL.Text :=
      'SELECT'                                                      + sLineBreak +
      '    v.CODIGO_ART_ART,'                                       + sLineBreak +
      '    v.DESCRIPCION_ART,'                                      + sLineBreak +
      '    v.DESCRIPCION_FAM,'                                      + sLineBreak +
      '    pv.PV                       AS TEMPORADA,'               + sLineBreak +
      '    v.RAZON_SOCIAL_PROVEEDOR,'                               + sLineBreak +
      '    v.CODIGO_TAR_ARTTAR,'                                    + sLineBreak +
      '    v.NOMBRE_TAR_TAR,'                                       + sLineBreak +
      '    v.PRECIO_FINAL_ARTTAR,'                                  + sLineBreak +
      '    v.FECHA_DESDE_ARTTAR,'                                   + sLineBreak +
      '    v.FECHA_HASTA_ARTTAR'                                    + sLineBreak +
      'FROM vi_art_busquedas v'                                     + sLineBreak +
      'LEFT JOIN fza_articulos_propiedades ap'                      + sLineBreak +
      '       ON ap.CODIGO_ART_ART = v.CODIGO_ART_ART'              + sLineBreak +
      '      AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'''            + sLineBreak +
      'LEFT JOIN fza_propiedades_valores pv'                        + sLineBreak +
      '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'               + sLineBreak +
      'WHERE (v.CODIGO_TAR_ARTTAR = :TARIFA'                        + sLineBreak +
      '       OR v.CODIGO_TAR_ARTTAR IS NULL)'                      + sLineBreak +
      '  AND (v.FECHA_DESDE_ARTTAR IS NULL'                         + sLineBreak +
      '       OR v.FECHA_DESDE_ARTTAR <= :FECHA_TARIFA)'            + sLineBreak +
      '  AND (v.FECHA_HASTA_ARTTAR IS NULL'                         + sLineBreak +
      '       OR v.FECHA_HASTA_ARTTAR >= :FECHA_TARIFA)'            + sLineBreak +
      'ORDER BY v.CODIGO_ART_ART';

    unqryBusq.ParamByName('TARIFA').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    unqryBusq.ParamByName('FECHA_TARIFA').AsDate :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                                       'FECHA_FAC').AsDateTime;

    // Abrimos aqui (en vez de dejar que lo haga EjecutarBusqueda) para
    // tener acceso a los TField y poder fijar DisplayLabel / DisplayFormat
    // antes de que cxGrdDBTabPrin.DataController.CreateAllItems cree las
    // columnas en TfrmMtoSearch.CrearTablaPrincipal.
    unqryBusq.Open;
    ConfigCampo(unqryBusq.FindField('CODIGO_ART_ART'),
                'Código',                '');
    ConfigCampo(unqryBusq.FindField('DESCRIPCION_ART'),
                'Descripción',           '');
    ConfigCampo(unqryBusq.FindField('DESCRIPCION_FAM'),
                'Familia',               '');
    ConfigCampo(unqryBusq.FindField('TEMPORADA'),
                'Temporada',             '');
    ConfigCampo(unqryBusq.FindField('RAZON_SOCIAL_PROVEEDOR'),
                'Proveedor',             '');
    ConfigCampo(unqryBusq.FindField('CODIGO_TAR_ARTTAR'),
                'Tarifa',                '');
    ConfigCampo(unqryBusq.FindField('NOMBRE_TAR_TAR'),
                'Nombre tarifa',         '');
    ConfigCampo(unqryBusq.FindField('PRECIO_FINAL_ARTTAR'),
                'Precio',                '#,##0.00 €');
    ConfigCampo(unqryBusq.FindField('FECHA_DESDE_ARTTAR'),
                'Desde',                 'dd/mm/yyyy');
    ConfigCampo(unqryBusq.FindField('FECHA_HASTA_ARTTAR'),
                'Hasta',                 'dd/mm/yyyy');

    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Caja',
                                       unqryBusq,
                                       'frmMtoArtFacSearch',
                                       Self) then
      Result := unqryBusq.FieldByName('CODIGO_ART_ART').AsString
    else
      Result := '';
  finally
    FreeAndNil(unqryBusq);
  end;
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodigoInput: string;
  CodigoPadre: string;
  SkuDetectado: string;
  NumAtributos: Integer;
  sw, swStep: TStopwatch;
  msRellenar, msConsolidar, msBusq, msColumnas, msAtribs: Int64;
begin
  // Arrancamos el cronometro global art -> primer popup para diagnosticar
  // donde se va el tiempo entre Enter en el codigo y la salida del primer
  // desplegable de atributo (lo cierra WMAbrirPopupAv).
  FswArtAPopup := TStopwatch.StartNew;
  sw := TStopwatch.StartNew;
  msRellenar := 0; msConsolidar := 0; msBusq := 0;
  msColumnas := 0; msAtribs := 0;
  CodigoInput := VarToStr(DisplayValue);
  swStep := TStopwatch.StartNew;
  if RellenarDatosArticuloEnDataset(CodigoInput) then
  begin
    msRellenar := swStep.ElapsedMilliseconds;
    CodigoPadre  := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    // Validación parametrizada: SKU debe existir en fza_articulos_skus y, si
    // procede, tener stock. Se ejecuta sólo cuando el SKU ya está definido
    // (no es el padre a la espera de talla/color).
    if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodigoPadre) and
       not ValidarSkuParaVenta(SkuDetectado) then
    begin
      EliminarLineaPorValidacion;
      DisplayValue := null;
      Error := False;
//      LogPerfCaja('CajaOpe.ArticuloValidate',
//        Format('art=%s | Rellenar=%d | -> EliminarLineaPorValidacion | total=%d ms',
//               [CodigoInput, msRellenar, sw.ElapsedMilliseconds]));
      Abort;
    end;
    if (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
    begin
      DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
      GridRecalc(nil,
                 tvLineasOpe,
                 DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera,
                 ActualizarLabelTotal);
    end;
    swStep := TStopwatch.StartNew;
    if ConsolidarSiExiste(SkuDetectado) then
    begin
       msConsolidar := swStep.ElapsedMilliseconds;
       // RellenarDatosArticuloEnDataset ya CONFIRMA (Post) la linea de trabajo
       // en su recalculo fiscal interno, asi que un Cancel no la elimina: si
       // tras cancelar sigue ahi y es el mismo SKU recien consolidado, la
       // BORRAMOS para no dejar duplicado (mismo patron que
       // FinalizarUltimoAtributo).
       if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
       if not DatosCaja.cdsLineas.IsEmpty then
         if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
              = SkuDetectado then
           DatosCaja.cdsLineas.Delete;
       DatosCaja.cdsLineas.Append;
       DisplayValue := null;
       Error := False;
//       LogPerfCaja('CajaOpe.ArticuloValidate',
//         Format('art=%s | Rellenar=%d | Consolidar=%d | -> consolidado | total=%d ms',
//                [CodigoInput, msRellenar, msConsolidar,
//                 sw.ElapsedMilliseconds]));
       Abort;
    end;
    msConsolidar := swStep.ElapsedMilliseconds;
    tmrBusq.Enabled := False;
    if (CodigoPadre <> '') and (CodigoPadre <> CodigoInput) then
    begin
       DisplayValue := CodigoPadre;
       qryBusq.Connection := oConn;
       if qryBusq.Active then qryBusq.Close;
       qryBusq.ParamByName('TARIFA').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
       qryBusq.ParamByName('FECHA_TARIFA').AsDate :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                                       'FECHA_FAC').AsDateTime;
       qryBusq.ParamByName('TOKEN').AsString := CodigoPadre;
       swStep := TStopwatch.StartNew;
       qryBusq.Open;
       msBusq := swStep.ElapsedMilliseconds;
    end;
    swStep := TStopwatch.StartNew;
    ActualizarColumnasDinamicas(CodigoPadre);
    msColumnas := swStep.ElapsedMilliseconds;
    // Solo desglosamos atributos si SkuDetectado es un SKU real (distinto
    // del padre). Si SkuDetectado == CodigoPadre estamos a la espera de
    // que el usuario elija talla/color: la query no encontraria nada y
    // gastariamos un round-trip a BBDD para nada.
    if (Trim(SkuDetectado) <> '') and (NumAtributos > 0)
       and (SkuDetectado <> CodigoPadre) then
    begin
       swStep := TStopwatch.StartNew;
       RellenarAtributosDesdeSku(SkuDetectado);
       msAtribs := swStep.ElapsedMilliseconds;
    end;
    Error := False;
//    LogPerfCaja('CajaOpe.ArticuloValidate',
//      Format('art=%s | Rellenar=%d | Consolidar=%d | qryBusq=%d | Columnas=%d | Atribs=%d | total=%d ms',
//             [CodigoInput, msRellenar, msConsolidar, msBusq,
//              msColumnas, msAtribs, sw.ElapsedMilliseconds]));
  end
  else
  begin
    msRellenar := swStep.ElapsedMilliseconds;
    Error := True;
    if FMotivoRechazoArticulo <> '' then
      ErrorText := FMotivoRechazoArticulo
    else
      ErrorText := 'ARTÍCULO NO ENCONTRADO O DESCATALOGADO';
//    LogPerfCaja('CajaOpe.ArticuloValidate',
//      Format('art=%s | NO ENCONTRADO | Rellenar=%d | total=%d ms',
//             [CodigoInput, msRellenar, sw.ElapsedMilliseconds]));
  end;
end;

procedure TfrmMtoOpeCaja.tvDescuentoMenosPropertiesEditValueChanged(
  Sender: TObject);
begin
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;

  GridRecalc(Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesEditValueChanged(Sender: TObject);
begin
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;

  GridRecalc(Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
begin
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;

  GridRecalc(Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvTotalPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  VieneDeDep: string;
  CantOriginal, NuevaCant: Double;
begin
  if (DatosCaja = nil) or not DatosCaja.cdsLineas.Active then
    Exit;
  VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
  if VieneDeDep = 'S' then
  begin
    // Convertimos de forma segura el valor tecleado a float
    NuevaCant := StrToFloatDef(VarToStrDef(DisplayValue, '0'), 0);
    CantOriginal := DatosCaja.cdsLineas.FieldByName(
                                              'CANTIDAD_FACLIN').AsFloat;
    // Verificamos que la magnitud sea idéntica (solo permite cambiar signo)
    if Abs(NuevaCant) <> Abs(CantOriginal) then
    begin
      Error := True;
      ErrorText := 'En artículos de depósito solo está permitido cambiar el ' +
                   'signo de la cantidad_artvin.';
    end
    else
    begin
      Error := False;

      // NUEVA LÓGICA: Si cambia a negativo, es una CANCELACIÓN
      if NuevaCant < 0 then
      begin
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString :=
                                                                     'CANCELAR';
        // Ponemos el precio a 0 para no devolver el dinero de la prenda
        DatosCaja.cdsLineas.FieldByName(
                                  'PRECIO_SALIDA_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                                       'PORCENTAJE_DTO_FACLIN').AsFloat := 0;
        DatosCaja.cdsLineas.FieldByName(
                                    'PRECIO_DTO_FACLIN').AsCurrency := 0;
      end
      else
      begin
        // Si lo vuelve a poner en positivo, restauramos la acción y su precio
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'COBRAR';
        DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
          DatosCaja.cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
      end;
    end;
  end;
end;

function TfrmMtoOpeCaja.RellenarDatosArticuloEnDataset(Codigo: string): Boolean;
var
  CodigoLimpio  : string;
  Validador     : TArticulosValidador;
  Resolver      : TArticulosResolver;
  Resolucion    : TArtResolucionEntrada;
  Datos         : TArticuloDatos;
  CodTarifa     : string;
  FechaTicket   : TDateTime;
  sw, swStep    : TStopwatch;
  msResolver, msStock, msPrecio, msResolverDatos: Int64;
begin
  Result := False;
  FMotivoRechazoArticulo := '';
  CodigoLimpio := UpperCase(Trim(Codigo));
  if CodigoLimpio = '' then Exit;
  sw := TStopwatch.StartNew;
  msResolver := 0; msStock := 0; msPrecio := 0; msResolverDatos := 0;

  Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  Resolver  := TArticulosResolver.Create(inLibGlobalVar.oConn);
  try
    swStep := TStopwatch.StartNew;
    // Si la entrada viene de la pistola (STX...ETX), resolvemos UNICAMENTE
    // contra codigos de barras; en cualquier otro caso, busqueda unificada.
    if FResolviendoPorScanner then
      Resolucion := Validador.ResolverCodigoBarras(CodigoLimpio)
    else
      Resolucion := Validador.Resolver(CodigoLimpio);
    msResolver := swStep.ElapsedMilliseconds;
    if not Resolucion.Encontrado then
    begin
//      LogPerfCaja('CajaOpe.RellenarArt',
//        Format('cod=%s | Resolver=%d | NO ENCONTRADO | total=%d ms',
//               [CodigoLimpio, msResolver, sw.ElapsedMilliseconds]));
      Exit;
    end;

    CodTarifa   := DatosCaja.cdsCabecera.FieldByName(
                                          'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    FechaTicket := DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime;

    DatosCaja.cdsLineas.DisableControls;
    try
      if DatosCaja.cdsLineas.State = dsBrowse then DatosCaja.cdsLineas.Edit;
      DatosCaja.cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
                                                Resolucion.DescripcionArticulo;
      DatosCaja.cdsLineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString :=
                                                Resolucion.TipoArticulo;
      DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
                                                Resolucion.CodigoArticulo;
      DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger
                                                := Resolucion.NumAtributosReq;

      if Resolucion.CodigoSku <> '' then
      begin
        // SKU resuelto (uno único, o detectado por la vista de búsqueda).
        if not FActualizandoDepositos then
        begin
          swStep := TStopwatch.StartNew;
          ConsultarStock(Resolucion.CodigoSku);
          msStock := swStep.ElapsedMilliseconds;
        end;
        DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
                                                Resolucion.CodigoSku;
        swStep := TStopwatch.StartNew;
        RecalcularPrecioDesdeSku(Resolucion.CodigoSku);
        msPrecio := swStep.ElapsedMilliseconds;
        Result := True;
      end
      else if Resolucion.RequiereSku then
      begin
        // Padre con varios SKUs: se mostrarán talla/color al usuario. La
        // línea queda con descripción/IVA/% dto del padre, pero sin precio
        // definitivo hasta que se elija el SKU.
        if not FActualizandoDepositos then
        begin
          swStep := TStopwatch.StartNew;
          ConsultarStock(Resolucion.CodigoArticulo);
          msStock := swStep.ElapsedMilliseconds;
        end;
        DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
                                                Resolucion.CodigoArticulo;
        if not FActualizandoDepositos then
        begin
          swStep := TStopwatch.StartNew;
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo, '',
                                          CodTarifa, FechaTicket);
          // ResolverDatos no calcula precio cuando hay >1 SKU sin elegir;
          // pedimos el del padre explícitamente para arrastrar IVA y %dto.
          var Precio := Resolver.ResolverPrecio(Resolucion.CodigoArticulo, '',
                                                CodTarifa, FechaTicket);
          msResolverDatos := swStep.ElapsedMilliseconds;
          DatosCaja.cdsLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString
                                                := Datos.TipoIVA;
          DatosCaja.cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString
                                                := IfThen(Precio.EsImpIncl,
                                                          'S',
                                                          'N');
          DatosCaja.cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat
                                                := Precio.PorcentajeDto;
          DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
            0;
          DatosCaja.cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
          DatosCaja.cdsLineas.FieldByName(
                            'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
          DatosCaja.cdsLineas.FieldByName(
                            'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
          DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsCurrency := 1;
        end;
        Result := True;
      end
      else
      begin
        // Artículo localizado y activo, pero sin SKU vendible (p. ej. una
        // variación que se quedó sin tallas/colores). Guardamos el motivo
        // para que el validador de caja muestre un mensaje exacto en vez
        // del genérico "no encontrado o descatalogado".
        FMotivoRechazoArticulo := Resolucion.Mensaje;
      end;
    finally
      DatosCaja.cdsLineas.EnableControls;
    end;
    if Result and (not FActualizandoDepositos) then
      GridRecalc(nil, tvLineasOpe, DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    FreeAndNil(Validador);
    FreeAndNil(Resolver);
  end;
//  LogPerfCaja('CajaOpe.RellenarArt',
//    Format('cod=%s | Resolver=%d | Stock=%d | Precio=%d | ResolverDatos=%d | total=%d ms',
//           [CodigoLimpio, msResolver, msStock, msPrecio, msResolverDatos,
//            sw.ElapsedMilliseconds]));
end;

procedure TfrmMtoOpeCaja.repComboBoxPropertiesInitPopup(Sender: TObject);
var
  View: TcxGridDBTableView;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    if TcxExtLookupComboBox(Sender).Properties.View is TcxGridDBTableView then
    begin
       View := TcxGridDBTableView(TcxExtLookupComboBox(Sender).Properties.View);
       View.BeginUpdate;
       try
         View.Controller.IncSearchingText := '';
         View.DataController.Filter.Clear;
         View.DataController.Filter.Active := False;
         View.DataController.Filter.AutoDataSetFilter := False;
         View.DataController.Refresh;
       finally
         View.EndUpdate;
       end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.RecalcularPrecioDesdeSku(sSKU: string);
var
  Resolver     : TArticulosResolver;
  Precio       : TArticuloPrecio;
  CodTarifa    : string;
  CodArt       : string;
  FechaFactura : TDateTime;
begin
  if Trim(sSKU) = '' then Exit;
  CodTarifa    := DatosCaja.cdsCabecera.FieldByName(
                                       'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  FechaFactura := DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime;
  CodArt       := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;

  Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
  try
    Precio := Resolver.ResolverPrecio(CodArt, sSKU, CodTarifa, FechaFactura);
    if not Precio.TieneRegistro then Exit;

    DatosCaja.cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
                                                IfThen(Precio.EsImpIncl,
                                                       'S',
                                                       'N');
    DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
                                                Precio.PrecioSalida;
    DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsCurrency := 1;
    DatosCaja.cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
                                                Precio.PorcentajeDto;

    DatosCaja.cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                          'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;

    GridRecalc(nil, tvLineasOpe, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    FreeAndNil(Resolver);
  end;
end;

procedure TfrmMtoOpeCaja.RellenarAtributosDesdeSku(Sku: string);
var
  Lookup  : TArticulosAtributosLookup;
  Valores : TArray<TArticuloAtributoValor>;
  V       : TArticuloAtributoValor;
  i       : Integer;
  sw, swQry : TStopwatch;
  msQry   : Int64;
begin
  if Trim(Sku) = '' then Exit;
  sw := TStopwatch.StartNew;
  Lookup := TArticulosAtributosLookup.Create(inLibGlobalVar.oConn);
  try
    swQry := TStopwatch.StartNew;
    Valores := Lookup.ObtenerAtributosDeSku(Sku);
    msQry := swQry.ElapsedMilliseconds;
    if Length(Valores) = 0 then
    begin
//      LogPerfCaja('CajaOpe.RellenarAtribsDesdeSku',
//        Format('sku=%s | Qry=%d | sin valores | total=%d ms',
//               [Sku, msQry, sw.ElapsedMilliseconds]));
      Exit;
    end;

    if not (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
      DatosCaja.cdsLineas.Edit;

    for V in Valores do
    begin
      i := V.Orden;
      if (i >= 1) and (i <= 5) then
        DatosCaja.cdsLineas.FieldByName('ATTR' + IntToStr(
          i) + '_VALOR').AsString
                                                                       := V.Valor;
    end;
  finally
    FreeAndNil(Lookup);
  end;
//  LogPerfCaja('CajaOpe.RellenarAtribsDesdeSku',
//    Format('sku=%s | Qry=%d | total=%d ms',
//           [Sku, msQry, sw.ElapsedMilliseconds]));
end;

function TfrmMtoOpeCaja.ConsolidarSiExiste(SkuBuscado: string): Boolean;
var
  Clon: TClientDataSet;
  OldQty: Double;
  VieneDeDep: string;
begin
  Result := False;
  if Trim(SkuBuscado) = '' then Exit;
  Clon := TClientDataSet.Create(nil);
  try
    Clon.CloneCursor(DatosCaja.cdsLineas, True);
    Clon.First;
    while not Clon.Eof do
    begin
      VieneDeDep := Clon.FieldByName('VIENE_DE_DEPOSITO').AsString;

      // Solo consolidamos líneas de venta normal.
      // Las líneas de depósito ('S' = prenda apartada, 'A' = abono)
      // NO se consolidan: representan operaciones distintas aunque
      // compartan SKU con un artículo que el cliente se lleva ahora.
      if (VieneDeDep <> 'S') and (VieneDeDep <> 'A') and
         (Clon.FieldByName('CODIGO_UNIDAD_FACLIN').AsString = SkuBuscado)
         and (Clon.RecNo <> DatosCaja.cdsLineas.RecNo) then
      begin
        OldQty := Clon.FieldByName('CANTIDAD_FACLIN').AsFloat;
        Clon.Edit;
        Clon.FieldByName('CANTIDAD_FACLIN').AsFloat := OldQty + 1;
        dsLineas.DataSet.DisableControls;
        Clon.Post;
        dsLineas.DataSet.EnableControls;
        GridRecalc(nil,
                   tvLineasOpe,
                   DatosCaja.cdsLineas,
                   DatosCaja.cdsCabecera,
                   ActualizarLabelTotal);
        Result := True;
        Break;
      end;
      Clon.Next;
    end;
  finally
    FreeAndNil(Clon);
  end;
end;

procedure TfrmMtoOpeCaja.ConstruirColumnasDinamicas;
var
  i: Integer;
  Col: TcxGridDBColumn;
  MaxAtributos: Integer;
  IndiceBase:Integer;
begin
  MaxAtributos := 5;
  IndiceBase := tvArticulo.Index;
  tvLineasOpe.BeginUpdate;
  try
    for i := 1 to MaxAtributos do
    begin
      Col := tvLineasOpe.CreateColumn;
      Col.Name := 'tvAtributoDyn' + IntToStr(i);
      Col.Tag := i;
      Col.DataBinding.FieldName := 'ATTR' + IntToStr(i) + '_VALOR';
      Col.Caption := '-';
      Col.Visible := False;
      Col.Width := 80;
      // TcxButtonEdit con un boton bkEllipsis (que cambiamos a bkGlyph en
      // InitEdit cuando el AV actual tiene swatch en la paleta basica). El
      // click abre SeleccionarAvConPaleta — mismo patron que inMtoInventarios.
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
        OnButtonClick := tvLineasOpeAvButtonClick;
      end;
      Col.Index := IndiceBase + i;
    end;
  finally
    tvLineasOpe.EndUpdate;
  end;
end;

// CAMBIO 2: OnAtributoChanged sale inmediatamente si estamos inicializando el
// combo
procedure TfrmMtoOpeCaja.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  SkuNuevo: string;
begin
  // Si ForzarDespliegue está asignando ItemIndex := 0, no procesamos
  if FInicializandoCombo then Exit;
  Edit := Sender as TcxCustomEdit;
  if not DatosCaja.cdsLineas.Active then Exit;
  Edit.PostEditValue;
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
     SkuNuevo := DatosCaja.GenerarSkuFinal(
        DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_ART_FACLIN').AsString
     );
     DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
                                                                       SkuNuevo;
     var NumAtributosRequeridos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
     var NumSeparadores := 0;
     for var i := 1 to Length(SkuNuevo) do
     begin
        if SkuNuevo[i] = '/' then
           Inc(NumSeparadores);
     end;
     if NumSeparadores = NumAtributosRequeridos then
       RecalcularPrecioDesdeSku(SkuNuevo);
  end;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1CanFocusRecord(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  var AAllow: Boolean);
var
  CodArticulo, SkuActual: string;
begin
  if (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
    end
    else
    begin
      SkuActual := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
      if SkuActual = '' then
         SkuActual := CodArticulo;
      if ConsolidarSiExiste(SkuActual) then
      begin
        // La linea de trabajo ya puede estar grabada: Cancel no la quita.
        // Si tras cancelar sigue ahi con el mismo SKU consolidado, la
        // borramos para no duplicar (mismo patron que en Validate).
        if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Cancel;
        if not DatosCaja.cdsLineas.IsEmpty then
          if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
               = SkuActual then
            DatosCaja.cdsLineas.Delete;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1Editing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if (DatosCaja <> nil) and
     DatosCaja.cdsLineas.Active and
     not DatosCaja.cdsLineas.IsEmpty then
  begin
    // Si la línea es la prenda base del depósito
    if DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
    begin
      // Solo permitimos editar la columna de CANTIDAD_ARTVIN/Unidades
      if AItem <> tvUds then
        AAllow := False;
    end
    // Si la línea es el abono (anticipo de dinero, marcado con 'A' según tu
    //UniDataCaja)
    else if DatosCaja.cdsLineas.FieldByName(
      'VIENE_DE_DEPOSITO').AsString = 'A' then
    begin
      // No permitimos tocar absolutamente nada de la línea del abono
      AAllow := False;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1EditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  NumAtributos: Integer;
  PrimeraColAtributo: TcxGridDBColumn;
  ValorActual: string;
begin
  if (AItem = tvArticulo) and
     not (Key in [VK_RETURN, VK_ESCAPE, VK_UP, VK_DOWN, VK_TAB, VK_LEFT,
                  VK_RIGHT, VK_F1..VK_F12]) then
  begin
    tmrBusq.Enabled := False;
    tmrBusq.Enabled := True;
  end;
  if (Key = VK_UP) and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      Key := 0;
      Exit;
    end;
  end;
  if (Key <> VK_RETURN) then
    Exit;
  if (AItem = tvArticulo) then
  begin
    tmrBusq.Enabled := False;
    // Doble Enter en la columna Articulo: el TcxExtLookupComboBox tiene
    // ImmediateDropDownWhenActivated=True, asi que cuando el usuario
    // teclea el codigo el dropdown queda abierto. El primer Enter cierra
    // el dropdown internamente (selecciona la fila resaltada) y se
    // "consume" sin que PostEditValue dispare Validate; hace falta un
    // segundo Enter para confirmar. Lo cerramos aqui explicitamente para
    // que el flujo siga en el mismo handler: DroppedDown:=False, luego
    // PostEditValue -> Validate -> avance de foco, todo en un solo Enter.
    if (AEdit is TcxCustomDropDownEdit)
       and TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      ValorActual := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      ValorActual := Trim(VarToStr(AEdit.EditValue));
    if ValorActual = '' then
    begin
      var sCodigo := BuscarArticulo;
      if sCodigo <> '' then
      begin
        AEdit.EditValue := sCodigo;
        if not RellenarDatosArticuloEnDataset(sCodigo) then
        begin
          if FMotivoRechazoArticulo <> '' then
            ShowMessage(FMotivoRechazoArticulo)
          else
            ShowMessage('Artículo no encontrado');
          Key := 0;
          Exit;
        end;
      end
      else
      begin
        Key := 0;
        Exit;
      end;
    end;
    AEdit.PostEditValue;
    if DatosCaja.cdsLineas.State = dsBrowse then
      DatosCaja.cdsLineas.Edit;
    var CodArticuloActual := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    ActualizarColumnasDinamicas(CodArticuloActual);
    // CAMBIO 3: Usar FNumAtributosActual en lugar de leer del dataset
    NumAtributos := FNumAtributosActual;
    var SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
    // Validación parametrizada del SKU resuelto (también protege la rama de
    // BuscarArticulo, que no pasa por tvArticuloPropertiesValidate).
    if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodArticuloActual) and
       not ValidarSkuParaVenta(SkuDetectado) then
    begin
      EliminarLineaPorValidacion;
      Key := 0;
      Exit;
    end;
    if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodArticuloActual) then
    begin
       RellenarAtributosDesdeSku(SkuDetectado);
       if oCajaParams.GetBool('vgerMoverLineaIdentif', True) then
       begin
         if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
           DatosCaja.cdsLineas.Post;
         DatosCaja.cdsLineas.Append;
         tvLineasOpe.Controller.FocusedColumn := tvArticulo;
       end
       else
       begin
         tvLineasOpe.Controller.FocusedColumn := tvDescripcion;
       end;
       tvLineasOpe.Controller.EditingController.ShowEdit;
       Key := 0;
       Exit;
    end;
    if (NumAtributos = 0) then
    begin
       // Verificamos el parámetro para saber a dónde saltar
       if oCajaParams.GetBool('vgerMoverLineaIdentif', True) then
       begin
         // Comportamiento habitual: Guardar, nueva línea y foco a Artículo
         DatosCaja.cdsLineas.Post;
         DatosCaja.cdsLineas.Append;
         tvLineasOpe.Controller.FocusedColumn := tvArticulo;
       end
       else
       begin
         // Comportamiento alternativo: Quedarse en la línea y pasar a
         // Descripción
         tvLineasOpe.Controller.FocusedColumn := tvDescripcion;
       end;
       tvLineasOpe.Controller.EditingController.ShowEdit;
       Key := 0;
       Exit;
    end
    else if (NumAtributos > 0) then
    begin
       if Trim(SkuDetectado) <> '' then
          RellenarAtributosDesdeSku(SkuDetectado);
       PrimeraColAtributo := ObtenerColumnaPorTag(1);
       if PrimeraColAtributo <> nil then
       begin
         PrimeraColAtributo.Visible := True;
         tvLineasOpe.Controller.FocusedColumn := PrimeraColAtributo;
         tvLineasOpe.Controller.EditingController.ShowEdit;
         Key := 0;
         Exit;
       end;
    end;
  end;
  // Atributos dinamicos (Color, Talla, ...) ya no usan TcxComboBox: el
  // popup SeleccionarAvConPaleta se abre desde OnButtonClick del TcxButtonEdit
  // y la logica del ultimo atributo (validar SKU, consultar stock, avanzar
  // foco) vive en FinalizarUltimoAtributo, invocado desde RegistrarValorAtributo.
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1FocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  sCodPadre, sSku, VieneDeDep: string;
  EsDeposito: boolean;
begin
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;
  if FActualizandoDepositos then Exit;
  if AFocusedRecord = nil then Exit;

  VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
  // Deshabilitar F3 y F8 (eliminar) visualmente en líneas de depósito
  EsDeposito := (VieneDeDep = 'S') or (VieneDeDep = 'A');
  btnF3.Enabled := not EsDeposito;
  btnF8.Enabled := not EsDeposito;
  sCodPadre := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
  sSku      := DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;

  if sCodPadre <> '' then
    ActualizarColumnasDinamicas(sCodPadre);

  if (Pos('/', sSku) > 0) and
     (Trim(DatosCaja.cdsLineas.FieldByName('ATTR1_VALOR').AsString) = '') then
    RellenarAtributosDesdeSku(sSku);
end;


procedure TfrmMtoOpeCaja.cxGrid1DBTableView1InitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE        : TcxButtonEdit;
  AvActual  : string;
  NombreAtb : string;
  IdVa      : string;
  Mapa      : TDictionary<string, string>;
  Info      : TInfoBasico;
  Btn       : TcxEditButton;
begin
  // Columnas de atributo dinamico (Color, Talla, ...). Mismo patron que
  // inMtoInventarios:
  //   (1) Si el AV actual tiene color en la paleta basica, el boton muestra
  //       un glyph con el cuadradito; si no, vuelve a bkEllipsis.
  //   (2) Si la celda esta vacia, OnEnter dispara el popup automaticamente
  //       (sustituye al antiguo Combo.DroppedDown via ForzarDespliegue).
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) then
  begin
    if AEdit is TcxButtonEdit then
    begin
      BE := TcxButtonEdit(AEdit);
      BE.Tag := AItem.Tag;
      if BE.Properties.Buttons.Count > 0 then
      begin
        Btn := BE.Properties.Buttons[0];

        AvActual  := '';
        NombreAtb := '';
        if DatosCaja.cdsLineas.Active
           and (not DatosCaja.cdsLineas.IsEmpty) then
        begin
          AvActual  := DatosCaja.cdsLineas.FieldByName(
                         'ATTR' + IntToStr(AItem.Tag) + '_VALOR').AsString;
          NombreAtb := DatosCaja.cdsLineas.FieldByName(
                         'ATTR' + IntToStr(AItem.Tag) + '_NOMBRE').AsString;
        end;

        IdVa := '';
        Mapa := ObtenerMapaAtributosGlobal;
        if Mapa <> nil then
          Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

        Info := Default(TInfoBasico);
        if (IdVa <> '') and (Trim(AvActual) <> '') then
          ObtenerInfoBasico(IdVa, AvActual, Info);

        if Info.EsValido and
           PintarSwatchEnBitmap(FBmpSwatchBoton, Info, 14) then
        begin
          Btn.Glyph.Assign(FBmpSwatchBoton);
          Btn.Kind := bkGlyph;
        end
        else
          Btn.Kind := bkEllipsis;

        if Trim(AvActual) = '' then
          BE.OnEnter := AbrirPopupAvEnEntrada
        else
          BE.OnEnter := nil;
      end;
    end;
  end;
  if AItem = tvArticulo then
  begin
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange :=
                                                     tvArticuloPropertiesChange;
    var ValorActual :=
                    AItem.GridView.Controller.FocusedRecord.Values[AItem.Index];
    if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
    begin
       if AEdit is TcxCustomTextEdit then
       begin
          TcxCustomTextEdit(AEdit).Text := VarToStr(ValorActual);
          TcxCustomTextEdit(AEdit).SelectAll;
       end;
    end
    else
    begin
       if qryBusq.Active then
          qryBusq.Close;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1KeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) then
  begin
    if DatosCaja.cdsLineas.State = dsInsert then
    begin
      DatosCaja.cdsLineas.Cancel;
      Key := 0;
      Exit;
    end;
    if DatosCaja.cdsLineas.RecordCount > 0 then
    begin
      if MessageDlg('Hay líneas en la venta actual.' + sLineBreak +
                    '¿Desea CANCELAR LA VENTA y salir?',
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        Close;
      end;
    end
    else
    begin
      Close;
    end;
    Key := 0;
  end;
  if (Key = VK_UP) and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      Key := 0;
      Exit;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Solo actuamos si el clic es con el botón izquierdo
  if Button = mbLeft then
    AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.cxGrid1Enter(Sender: TObject);
begin
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.State = dsBrowse then
  begin
    DatosCaja.cdsLineas.Append;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
  jvEnterTab.EnterAsTab := False;
end;

procedure TfrmMtoOpeCaja.cxGrid1Exit(Sender: TObject);
begin
  jvEnterTab.EnterAsTab := True;
end;

procedure TfrmMtoOpeCaja.actBuscarEmpleadosExecute(Sender: TObject);
var
  LCtrl: TWinControl;
  CodigoBuscado: string;
  CurrentEdit: TcxCustomEdit;
begin
  if tvLineasOpe.Controller.FocusedItem <> nil then
  if (tvLineasOpe.Controller.FocusedItem.Tag > 0) then
  begin
    if dsLineas.DataSet.State = dsBrowse then
      dsLineas.DataSet.Edit;
    if not tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      tvLineasOpe.Controller.EditingController.ShowEdit;
    end;
    if tvLineasOpe.Controller.EditingController.IsEditing then
     begin
       CurrentEdit := tvLineasOpe.Controller.EditingController.Edit;
       // F3 sobre una columna de atributo (Color, Talla, ...) abre el popup
       // SeleccionarAvConPaleta directamente, equivalente al antiguo
       // Combo.DroppedDown := True.
       if (CurrentEdit is TcxButtonEdit) then
       begin
         tvLineasOpeAvButtonClick(CurrentEdit, 0);
         Exit;
       end;
    end;
  end;
  LCtrl := Screen.ActiveControl;
  if (LCtrl = btnCodigoEmpleado) or (LCtrl.Parent = btnCodigoEmpleado) then
  begin
    BuscarEmpleados;
  end
  else if (LCtrl = btnCodigoCliente) or (LCtrl.Parent = btnCodigoCliente) then
  begin
    BuscarClientes;
  end
  else
  begin
    if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
    begin
      var VieneDeDep :=
                  DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
        Exit;
    end;
    CodigoBuscado := BuscarArticulo;
    if CodigoBuscado <> '' then
    begin
      if DatosCaja.cdsLineas.State = dsBrowse then
      begin
        if DatosCaja.cdsLineas.IsEmpty then
          DatosCaja.cdsLineas.Append
        else
          DatosCaja.cdsLineas.Edit;
      end;
      if RellenarDatosArticuloEnDataset(CodigoBuscado) then
      begin
        var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
        var SkuDetectado := DatosCaja.cdsLineas.FieldByName(
               'CODIGO_UNIDAD_FACLIN').AsString; // <-- Rescatamos el SKU
        // Validación parametrizada del SKU resuelto en la búsqueda. Si el SKU
        // no existe o no tiene stock (según parámetros), descartamos la línea.
        if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodArticulo) and
           not ValidarSkuParaVenta(SkuDetectado) then
        begin
          EliminarLineaPorValidacion;
          Exit;
        end;
        ActualizarColumnasDinamicas(CodArticulo);
        var NumAtributos := FNumAtributosActual;
        if (Trim(SkuDetectado) <> '') and (NumAtributos > 0) then
        begin
           RellenarAtributosDesdeSku(SkuDetectado);
        end;
        cxgrdLineasOpe.SetFocus;
        // Comprobamos si es un SKU completo (el código de unidad es distinto al
        // padre)
        var EsSkuCompleto := (Trim(SkuDetectado) <> '')
           and (SkuDetectado <> CodArticulo);
        // Supongamos que lees tu parámetro global así (ajusta el nombre a tu
        // variable real)
        var AutoPasarLinea := oCajaParams.GetBool('vgerMoverLineaIdentif',
                                                  False);
        // Si necesita atributos Y NO ES un SKU ya cerrado, nos paramos en la
        // columna de atributos
        if (NumAtributos > 0) and not EsSkuCompleto then
        begin
          var PrimeraCol := ObtenerColumnaPorTag(1);
          if PrimeraCol <> nil then
          begin
            PrimeraCol.Visible := True;
            tvLineasOpe.Controller.FocusedColumn := PrimeraCol;
            tvLineasOpe.Controller.EditingController.ShowEdit;
          end;
        end
        else
        begin
          // El artículo ya está completo (sea simple o un SKU cerrado)
          if AutoPasarLinea then
          begin
            // Forzamos el guardado de la línea actual (si está en edición) para
            // evitar que se pierda
            if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
              DatosCaja.cdsLineas.Post;

            // Creamos línea nueva y ponemos el foco en el buscador de artículos
            DatosCaja.cdsLineas.Append;
            tvLineasOpe.Controller.FocusedColumn := tvArticulo;
            tvLineasOpe.Controller.EditingController.ShowEdit;
          end
          else
          begin
            // Si el parámetro está desactivado, el cajero decide. Lo normal es
            // dejarle en CANTIDAD_ARTVIN.
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.actCargarCtaExecute(Sender: TObject);
begin
  btnF2Click(Sender);
end;

procedure TfrmMtoOpeCaja.actCobroExecute(Sender: TObject);
begin
  btnF12Click(Sender);
end;

procedure TfrmMtoOpeCaja.actEliminarLineaExecute(Sender: TObject);
var
  VieneDeDep: string;
begin
  // NUEVO: Bloqueo de borrado
  if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
  begin
    VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
    if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
    begin
      ShowMessage(
        'No se puede eliminar una línea vinculada a un depósito.' + sLineBreak +
                  'Cambie la cantidad_artvin a negativo si necesita ' +
                  'revertirla.');
      Exit;
    end;
  end;

  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    DatosCaja.cdsLineas.Cancel
  else
    if DatosCaja.cdsLineas.State in [dsBrowse] then
      DatosCaja.cdsLineas.Delete;
  AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayoutCaja;
end;

procedure TfrmMtoOpeCaja.actAbrirArticulosExecute(Sender: TObject);
var
  sCodArt: string;
begin
  sCodArt := '';
  if Assigned(DatosCaja) and
     Assigned(DatosCaja.cdsLineas) and
     DatosCaja.cdsLineas.Active then
    sCodArt := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
  ShowMto(frmMtoPrincipal, 'Articulos', sCodArt);
end;

procedure TfrmMtoOpeCaja.RestaurarLayoutCaja;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(Self.Name);
  try
    if not Layout.Disponible then Exit;
    Layout.RestaurarGeometria(Self);
    Layout.RestaurarAlturaPanel('StockPanelHeight', pnlBusqueda, 30);
    Layout.RestaurarAnchoPanel('FotoStockWidth',   pnlFotoStock, 50);
    Layout.RestaurarGrid('Lineas', tvLineasOpe);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoOpeCaja.actSalirExecute(Sender: TObject);
begin
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
  begin
    if MessageDlg('Hay una venta en curso.' + sLineBreak +
                  '¿Desea BORRAR LA VENTA y salir?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
      Close;
    end;
  end
  else
  begin
    Close;
  end;
end;

procedure TfrmMtoOpeCaja.ActualizarColumnasDinamicas(ArticuloPadre: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
  NombresAtributos: TStringList;
  sw, swQry, swUI: TStopwatch;
  msQry, msUI: Int64;
  Cacheado: Boolean;
begin
  sw := TStopwatch.StartNew;
  msQry := 0; msUI := 0;
  // --- OPTIMIZACIÓN: Si es el mismo tipo de artículo, no repintamos ---
  Cacheado := SameText(ArticuloPadre, FUltimoArticuloPadre);
  if Cacheado then
  begin
//    LogPerfCaja('CajaOpe.ActualizarColumnas',
//      Format('art=%s | cache hit | total=%d ms',
//             [ArticuloPadre, sw.ElapsedMilliseconds]));
    Exit;
  end;
  FUltimoArticuloPadre := ArticuloPadre;

  NombresAtributos := TStringList.Create;
  try
    // Solo atacamos la base de datos si hay un artículo real
    if (ArticuloPadre <> '') and (ArticuloPadre <> 'ACUENTA') then
    begin
      datosCaja.qryDefinicionArticulo.Connection := oConn;
      datosCaja.qryDefinicionArticulo.Close;
      // ANTES: 4-way join sobre fza_articulos_skus -> fza_atributos_sku ->
      //        fza_atributos_valores -> vi_atributos_nombres con DISTINCT.
      //        Medido: 9.6 s en MariaDB con datos reales — el cuello del
      //        flujo "Enter del codigo -> primer popup". La vista
      //        vi_atributos_nombres por dentro hace un join + distinct
      //        y al envolverla aqui en otro JOIN+DISTINCT, el optimizador
      //        no la materializa.
      // AHORA: lookup directo fza_articulos -> fza_variaciones_atributos
      //        via TIPO_VARIACION_ART (que ya tiene indice). Es PK seek
      //        sobre articulos y PK seek sobre variaciones_atributos.
      //        Para un articulo con variacion TC, devuelve 2 filas
      //        (Color, Talla). Para un articulo sin variacion, 0 filas.
      datosCaja.qryDefinicionArticulo.SQL.Text :=
      'SELECT vat.NOMBRE_VA      AS NOMBRE_ATRIBUTO,    ' +
      '       vat.ORDEN_VA       AS ORDEN_VISUAL_ATRIBUTO ' +
      '  FROM fza_articulos a                            ' +
      '  JOIN fza_variaciones_atributos vat              ' +
      '    ON vat.ID_VAR_VA = a.TIPO_VARIACION_ART       ' +
      ' WHERE a.CODIGO_ART_ART = :ARTICULO               ' +
      ' ORDER BY vat.ORDEN_VA                            ' +
      ' LIMIT 5';
      datosCaja.qryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
        ArticuloPadre;
      swQry := TStopwatch.StartNew;
      datosCaja.qryDefinicionArticulo.Open;
      msQry := swQry.ElapsedMilliseconds;
      while not datosCaja.qryDefinicionArticulo.Eof do
      begin
        NombresAtributos.Add(datosCaja.qryDefinicionArticulo.FieldByName(
          'NOMBRE_ATRIBUTO').AsString);
        datosCaja.qryDefinicionArticulo.Next;
      end;
    end;
    swUI := TStopwatch.StartNew;

    FNumAtributosActual := NombresAtributos.Count;

    // Solo tocamos la memoria del dataset si estamos escaneando algo nuevo
    if DatosCaja.cdsLineas.Active
       and (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
      DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := NombresAtributos.Count;

    tvLineasOpe.BeginUpdate;
    try
      for i := 1 to 5 do
      begin
        Col := ObtenerColumnaPorTag(i);
        if (Col <> nil) then
        begin
          if i <= NombresAtributos.Count then
          begin
            Col.Caption := NombresAtributos[i-1];
            Col.Visible := True;
            Col.Options.Editing := True;
            if DatosCaja.cdsLineas.Active
               and (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
              DatosCaja.cdsLineas.FieldByName('ATTR' + IntToStr(
                i) + '_NOMBRE').AsString := NombresAtributos[i-1];
          end
          else
          begin
            Col.Visible := False;
            Col.Options.Editing := False;
            Col.Caption := '-';
          end;
        end;
      end;
    finally
      tvLineasOpe.EndUpdate;
    end;
    msUI := swUI.ElapsedMilliseconds;
  finally
    FreeAndNil(NombresAtributos);
  end;
//  LogPerfCaja('CajaOpe.ActualizarColumnas',
//    Format('art=%s | Qry=%d | UI=%d | total=%d ms',
//           [ArticuloPadre, msQry, msUI, sw.ElapsedMilliseconds]));
//  tvLineasOpe.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.ActualizarLabelTotal(Sender: TObject;
  NuevoTotal: Currency);
begin
  lblTotal.Caption := Format('Total %m', [NuevoTotal]);
end;

procedure TfrmMtoOpeCaja.btnCodigoClienteExit(Sender: TObject);
var
  Edit: TcxCustomEdit;
begin
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    if Edit.EditModified then
    begin
      Edit.ValidateEdit(True);
      Edit.EditModified := False;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomCliente: string;
  sCodigo: string;
  Totales: TFacturaTotales;
begin
  if FValidandoCliente then
    Exit;
  FValidandoCliente := True;
  try
  // =======================================================================
  // 1. LIMPIEZA INCONDICIONAL DE DEPÓSITOS DEL CLIENTE ANTERIOR
  // =======================================================================
  if DatosCaja.cdsLineas.Active then
  begin
    // Si hay una línea a medio meter, la cancelamos para evitar Abort en
    // BeforePost
    if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if Trim(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString) = '' then
        DatosCaja.cdsLineas.Cancel
      else
        DatosCaja.cdsLineas.Post;
    end;
    DatosCaja.cdsLineas.DisableControls;
    try
      DatosCaja.cdsLineas.First;
      while not DatosCaja.cdsLineas.Eof do
      begin
        if (DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S')
           or
           (DatosCaja.cdsLineas.FieldByName(
             'VIENE_DE_DEPOSITO').AsString = 'A') then
        begin
          DatosCaja.cdsLineas.Delete;
        end
        else
        begin
          DatosCaja.cdsLineas.Next;
        end;
      end;
    finally
      DatosCaja.cdsLineas.EnableControls;
    end;
  end;
  // =======================================================================
  // 2. BÚSQUEDA Y ASIGNACIÓN DEL NUEVO CLIENTE
  // =======================================================================
  sCodigo := VarToStr(DisplayValue);

  if Trim(sCodigo) = '' then
  begin
    lblNombreCliente.Caption := 'VENTA CONTADO';
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString := '';
    DatosCaja.cdsCabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
      DatosCaja.GetTarifaDefault;
    DatosCaja.cdsCabecera.FieldByName(
      'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString := 'S';
    lblTarifa.Caption :=
      DatosCaja.cdsCabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    Error := False;
  end
  else
  begin
    var unqry := TUniQuery.Create(nil);
    try
      unqry.Connection := oConn;
      unqry.SQL.Text := 'SELECT RAZON_SOCIAL_CLI, ' +
                        '       TARIFA_ARTICULO_CLI, ' +
                        '       ESPERMITE_DEUDA_CLI ' +
                        '  FROM fza_clientes ' +
                        ' WHERE CODIGO_CLI_CLI = :COD';
      unqry.ParamByName('COD').AsString := sCodigo;
      unqry.Open;
      if not unqry.IsEmpty then
      begin
        DatosCaja.cdsCabecera.Edit;
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString := sCodigo;
        sNomCliente := unqry.FieldByName('RAZON_SOCIAL_CLI').AsString;
        DatosCaja.cdsCabecera.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_FAC').AsString := unqry.FieldByName(
            'TARIFA_ARTICULO_CLI').AsString;
        lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
        // Si es un cliente con depósitos, los cargamos
        if SameText(unqry.FieldByName('ESPERMITE_DEUDA_CLI').AsString, 'S') then
        begin
          tvLineasOpe.BeginUpdate;
          FActualizandoDepositos := True;
          try
            if oCajaParams.GetBool('vgerAutoLoadDepositos', False) then
              DatosCaja.CargarDepositosCliente(sCodigo);
          finally
            tvLineasOpe.EndUpdate;
            FActualizandoDepositos := False;
          end;
        end;
      end;
    finally
      FreeAndNil(unqry);
    end;
    if sNomCliente = '' then
    begin
      Error := True;
      ErrorText := 'El código de cliente no existe.';
    end
    else
    begin
      Error := False;
      lblNombreCliente.Caption := sNomCliente;
      ErrorText := '';
    end;
  end;
  // =======================================================================
  // 3. PROTECCIÓN CONTRA DATASET VACÍO Y RECÁLCULO FINAL
  // =======================================================================
  if DatosCaja.cdsLineas.Active then
  begin
    tvLineasOpe.DataController.UpdateItems(False);

    // 2º Ponemos el foco en la línea nueva
    AsegurarLineaNueva;

    // 3º Como paso final absoluto, pisamos la etiqueta leyendo la memoria
    // contable
    Totales := TFacturaTotales.Create(DatosCaja.cdsCabecera,
                                      DatosCaja.cdsLineas);
    try
      Totales.ProcesarFacturaCompleta;
      ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
    finally
      FreeAndNil(Totales);
    end;
  end;
  finally
    FValidandoCliente := False;
  end;
end;

procedure TfrmMtoOpeCaja.AsegurarLineaNueva;
begin
  if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active then
  begin
    // 1. Si no hay líneas en absoluto, insertamos una.
    if DatosCaja.cdsLineas.IsEmpty then
    begin
      DatosCaja.cdsLineas.Append;
    end
    // 2. Si ya hay líneas, verificamos que no estemos YA insertando una nueva
    else if not (DatosCaja.cdsLineas.State = dsInsert) then
    begin
      // Solo añadimos si la línea actual tiene un código de artículo.
      // Así evitamos crear líneas en blanco repetidas si hacen varios clics.
      if Trim(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString) <> '' then
      begin
        DatosCaja.cdsLineas.Append;
      end;
    end;
    // 3. Forzamos el foco visual a la celda del Artículo, lista para escanear
    if cxgrdLineasOpe.CanFocus then
      cxgrdLineasOpe.SetFocus;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
//    tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoExit(Sender: TObject);
begin
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).ValidateEdit(True);
end;

procedure TfrmMtoOpeCaja.BuscarClientes;
var
  formulario: TfrmMtoSearch;
  unqryClientes: TUniQuery;
begin
  unqryClientes := TUniQuery.Create(nil);
  try
    unqryClientes.Connection := oConn;
unqryClientes.SQL.Text := 'SELECT CODIGO_CLI_CLI as `Código`, ' +
                          '   RAZON_SOCIAL_CLI as `Razón Social`, ' +
                          '   NIF_CLI as `NIF Cliente`, ' +
                          '   MOVIL_CLI as `Teléfono Cliente`, ' +
                          '   ESPERMITE_DEUDA_CLI as `Cuenta Crédito`, ' +
                       '   TOTAL_LIMITE_CREDITO_CLI as `Límite Crédito`, ' +
                          '   TOTAL_DEUDA_CLI as `Deuda Usada` ' +
                          '  FROM fza_clientes ' +
                          ' WHERE ESACTIVO_CLI = ' + QuotedStr('S') +
                          ' ORDER BY RAZON_SOCIAL_CLI';
    formulario := TfrmMtoSearch.Create(nil);
    try
      formulario.Name := 'frmMtoCliSearch';
      formulario.Caption := 'Búsqueda de Clientes';
      formulario.dsTablaG.DataSet := unqryClientes;
      unqryClientes.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
      if formulario.sFicha = 'S' then
      begin
        btnCodigoCliente.Text := unqryClientes.FieldByName('Código').AsString;
        if btnCodigoCliente.ValidateEdit(True) then
        begin
          cxgrdLineasOpe.SetFocus;
        end;
      end;
    finally
      FreeAndNil(formulario);
    end;
  finally
    FreeAndNil(unqryClientes);
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomEmpleado: string;
  sCodigo: string;
  qry: TUniQuery;
begin
  sCodigo := VarToStr(DisplayValue);
  if (Trim(sCodigo) <> '') and DatosCaja.BuscarYMostrarNombre('EMPLEADOS',
    sCodigo,
    sNomEmpleado) then
  begin
    Error := False;
    lblNombreEmpleado.Caption := sNomEmpleado;
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString := sCodigo;
    ErrorText := '';
    DisplayValue := sCodigo;
    Exit;
  end;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'SELECT CODIGO_EMPL, DIMINUTIVO_TICKET_EMPL ' +
                    '  FROM fza_empleados ' +
                    ' WHERE ESACTIVO_EMPL = ''S'' ' +
                    '   AND CODIGO_EMPL IS NOT NULL ';
    if Trim(sCodigo) <> '' then
    begin
      qry.SQL.Add(
        'AND (CODIGO_EMPL LIKE :TOKEN OR DIMINUTIVO_TICKET_EMPL LIKE ' +
        ':TOKEN) ');
      qry.ParamByName('TOKEN').AsString := '%' + sCodigo + '%';
    end;
    qry.SQL.Add('ORDER BY CODIGO_EMPL ASC LIMIT 1');
    qry.Open;
    if not qry.IsEmpty then
    begin
      sCodigo := qry.FieldByName('CODIGO_EMPL').AsString;
      sNomEmpleado := qry.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString;
      DisplayValue := sCodigo;
      lblNombreEmpleado.Caption := sNomEmpleado;
      DatosCaja.cdsCabecera.Edit;
      DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
        sCodigo;
      Error := False;
      ErrorText := '';
    end
    else
    begin
      Error := True;
      ErrorText := 'No se encontró ningún empleado válido.';
      lblNombreEmpleado.Caption := '';
    end;
  finally
    FreeAndNil(qry);
  end;
//  tvLineasOpe.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.RepartirDescuentoGlobalLinea(
  ImporteDescuentoGlobal: Currency);
var
  TotalBrutoVenta: Currency;
  Proporcion: Double;
  DescuentoAplicarLinea: Currency;
  DescuentoAcumulado: Currency;
  CANTIDAD_ARTVIN: Double;
  PrecioSalida: Currency;
  DescuentoUnitario: Currency;
  Bkm: TBookmark;
begin
  if ImporteDescuentoGlobal = 0 then Exit;

  // 1. Calcular el Total Bruto sumando el importe de todas las líneas
  TotalBrutoVenta := 0;
  DatosCaja.cdsLineas.DisableControls;
  Bkm := DatosCaja.cdsLineas.GetBookmark;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      TotalBrutoVenta := TotalBrutoVenta +
        (DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat *
         DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency);
      DatosCaja.cdsLineas.Next;
    end;

    if TotalBrutoVenta = 0 then Exit; // Evitar división por cero

    // 2. Repartir el descuento línea a línea utilizando los campos reales
    DescuentoAcumulado := 0;
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      DatosCaja.cdsLineas.Edit;

      CANTIDAD_ARTVIN :=
        DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
      if CANTIDAD_ARTVIN = 0 then CANTIDAD_ARTVIN := 1; // Protección matemática

      PrecioSalida :=
        DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency;

      // Calculamos el % de peso de esta línea sobre el total del ticket
      Proporcion := (CANTIDAD_ARTVIN * PrecioSalida) / TotalBrutoVenta;

      // Asignamos el descuento total que le toca a esta fila
      // (Si es la última línea, le damos el resto para que cuadre exactamente
      // al céntimo)
      DatosCaja.cdsLineas.Next;
      if DatosCaja.cdsLineas.Eof then
        DescuentoAplicarLinea := ImporteDescuentoGlobal - DescuentoAcumulado
      else
        DescuentoAplicarLinea :=
          SimpleRoundTo(ImporteDescuentoGlobal * Proporcion, -2);

      DatosCaja.cdsLineas.Prior; // Volvemos a la línea actual

      // --- LÓGICA DE CAMPOS REALES DE LA BASE DE DATOS ---
      DescuentoUnitario := DescuentoAplicarLinea / CANTIDAD_ARTVIN;

      // 1. Guardar el nuevo Precio con Descuento Unitario (PRECIO_DTO_FACLIN)
      DatosCaja.cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency :=
        PrecioSalida - DescuentoUnitario;

      // 2. Calcular y guardar el Porcentaje de descuento exacto
      // (PORCENTAJE_DTO_FACLIN)
      if PrecioSalida <> 0 then
        DatosCaja.cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
          SimpleRoundTo((DescuentoUnitario / PrecioSalida) * 100, -2)
      else
        DatosCaja.cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;

      DescuentoAcumulado := DescuentoAcumulado + DescuentoAplicarLinea;

      DatosCaja.cdsLineas.Post;
      DatosCaja.cdsLineas.Next;
    end;
  finally
    if DatosCaja.cdsLineas.BookmarkValid(Bkm) then
      DatosCaja.cdsLineas.GotoBookmark(Bkm);
    DatosCaja.cdsLineas.FreeBookmark(Bkm);
    DatosCaja.cdsLineas.EnableControls;
  end;
end;

function TfrmMtoOpeCaja.HayLineasConDeposito: Boolean;
var
  Bkm: TBookmark;
  VieneDeDep: string;
begin
  Result := False;
  DatosCaja.cdsLineas.DisableControls;
  Bkm := DatosCaja.cdsLineas.GetBookmark;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      VieneDeDep :=
        DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
      begin
        Result := True;
        Break;
      end;
      DatosCaja.cdsLineas.Next;
    end;
  finally
    if DatosCaja.cdsLineas.BookmarkValid(Bkm) then
      DatosCaja.cdsLineas.GotoBookmark(Bkm);
    DatosCaja.cdsLineas.FreeBookmark(Bkm);
    DatosCaja.cdsLineas.EnableControls;
  end;
end;

procedure TfrmMtoOpeCaja.btnF12Click(Sender: TObject);
var
  frmFaseCobro: TfrmMtoCajaFaseCobro;
  ObjTotales: TFacturaTotales;
  NumeroGenerado: string;
  CodigoValeGenerado: string;
begin
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
  begin
    if DatosCaja.cdsLineas.State = dsInsert then
    begin
      if Trim(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString) = '' then
      begin
        DatosCaja.cdsLineas.Cancel;
      end
      else
      begin
        DatosCaja.cdsLineas.Post;
      end;
    end
    else
    begin
      DatosCaja.cdsLineas.Post;
    end;
  end;
  frmFaseCobro := nil;
  try
    ObjTotales := TFacturaTotales.Create(DatosCaja.cdsCabecera,
                                         DatosCaja.cdsLineas);
    ObjTotales.ProcesarFacturaCompleta;
    frmFaseCobro := TfrmMtoCajaFaseCobro.Create(Self);
    frmFaseCobro.CargarDatosDesdeFactura(ObjTotales);
    frmFaseCobro.FHayLineasDeposito := HayLineasConDeposito;
    frmFaseCobro.FCodigoEmpresa := FCodigoEmpresa;
    frmFaseCobro.FCodigoAlmacen := FCodigoAlmacen;
    frmFaseCobro.FCodigoCaja := FCodigoCaja;
    frmFaseCobro.FFecha := FFecha;
    frmFaseCobro.FCodigoCliente :=
           DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString;
    if frmFaseCobro.ShowModal = mrOk then
    begin
       if frmFaseCobro.DatosCobro.ImporteDescuentoGlobal > 0 then
       begin
         // Repartimos el importe del descuento entre todas las líneas
         RepartirDescuentoGlobalLinea(
                                frmFaseCobro.DatosCobro.ImporteDescuentoGlobal);
         ObjTotales.ProcesarFacturaCompleta;
       end;
       if DatosCaja.GrabarFacturaSimplificada(FCodigoEmpresa,
                                              FCodigoAlmacen,
                                              FCodigoCaja,
                                              frmFaseCobro.cbbSERIE_FAC.Text,
                                              frmFaseCobro.DatosCobro,
                                              frmFaseCobro.cbbSERIE_FAC.Text,
                                              NumeroGenerado,
                                              CodigoValeGenerado) then
       begin
         case frmFaseCobro.TipoImpresion of
           tiConTicket: ImprimirT(FCodigoEmpresa,
                                  FCodigoAlmacen,
                                  FCodigoCaja,
                                  NumeroGenerado,
                                  frmFaseCobro.DatosCobro,
                                  oNomImpresoraCaja);
           tiTicketRegalo:
             ;
           tiSinTicket:
             ;
         end;
         if CodigoValeGenerado <> '' then
         begin
           // ImprimirTicketVale(CodigoValeGenerado,
           // frmFaseCobro.DatosCobro.ImporteValeEmitido);
           // ShowMessage('Entregue el vale generado al cliente: ' +
           // CodigoValeGenerado);
         end;
         // 4. Limpiar la interfaz y los datasets para el siguiente cliente
         PrepararValores(FCodigoEmpresa, FCodigoAlmacen, FCodigoCaja, Now);
       end;
    end;
  finally
    if Assigned(frmFaseCobro) then
      FreeAndNil(frmFaseCobro);
    FreeAndNil(ObjTotales);
  end;
end;

procedure TfrmMtoOpeCaja.CargarDepositosF2;
var
  sCodigoCliente: string;
  Totales: TFacturaTotales;
begin
  sCodigoCliente :=
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  if (Trim(sCodigoCliente) = '') or (Trim(sCodigoCliente) = '0') then
  begin
    ShowMessage('Debe seleccionar un cliente para cargar sus depósitos.');
    Exit;
  end;

  // 1. Matar la edición activa limpiamente (Evita el error de
  // Artículo no encontrado en la línea en blanco)
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
  begin
    tvLineasOpe.Controller.EditingController.HideEdit(False);
  end;
  // 2. Cancelar línea a medias si la hubiera
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
    DatosCaja.cdsLineas.Cancel;
  // 3. Limpieza y carga de depósitos de forma silenciosa
  DatosCaja.cdsLineas.DisableControls;
  tvLineasOpe.BeginUpdate;
  FActualizandoDepositos := True;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      if (DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S')
                                                                              or
         (DatosCaja.cdsLineas.FieldByName(
                                       'VIENE_DE_DEPOSITO').AsString = 'A') then
        DatosCaja.cdsLineas.Delete
      else
        DatosCaja.cdsLineas.Next;
    end;
    DatosCaja.CargarDepositosCliente(sCodigoCliente);
  finally
    DatosCaja.cdsLineas.EnableControls;
    tvLineasOpe.EndUpdate;
    FActualizandoDepositos := False;
  end;
  tvLineasOpe.DataController.UpdateItems(False);
  // 5. Preparamos la línea en blanco para seguir escaneando (ahora ya no rompe
  // la caché)
  AsegurarLineaNueva;
  // 6. Calculamos el total SIEMPRE AL FINAL, forzando la lectura de memoria
  // interna
  Totales := TFacturaTotales.Create(DatosCaja.cdsCabecera, DatosCaja.cdsLineas);
  try
    Totales.ProcesarFacturaCompleta;
    ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TfrmMtoOpeCaja.btnF2Click(Sender: TObject);
begin
  CargarDepositosF2;
end;

procedure TfrmMtoOpeCaja.btnF5Click(Sender: TObject);
var
  i: Integer;
  NextIndex: Integer;
  TargetForm: TfrmMtoOpeCaja;
  Found: Boolean;
  const MAX_OPERACIONES = 5;
begin
  NextIndex := Self.Tag + 1;
  if NextIndex > MAX_OPERACIONES then
    NextIndex := 1;
  Found := False;
  TargetForm := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[i] is TfrmMtoOpeCaja then
    begin
      if Screen.Forms[i].Tag = NextIndex then
      begin
        TargetForm := TfrmMtoOpeCaja(Screen.Forms[i]);
        Found := True;
        Break;
      end;
    end;
  end;
  if Found then
  begin
    TargetForm.Show;
    TargetForm.BringToFront;
    if TargetForm.WindowState = wsMinimized then
      TargetForm.WindowState := wsNormal;
  end
  else
  begin
    TargetForm := TfrmMtoOpeCaja.Create(Application);
    TargetForm.PopupParent := Self.PopupParent;
    TargetForm.Tag := NextIndex;
    TargetForm.Caption := Format('Operación %d - (Caja Real %s)',
                                 [NextIndex, Self.FCodigoCaja]);
    TargetForm.PrepararValores(Self.FCodigoEmpresa,
                               Self.FCodigoAlmacen,
                               Self.FCodigoCaja,
                               Self.FFecha);
    TargetForm.Show;
  end;
  Self.Hide;
end;

procedure TfrmMtoOpeCaja.BuscarEmpleados;
var
  formulario : TfrmMtoSearch;
  unqryEmpleados:TUniQuery;
begin
  unqryEmpleados := TUniQuery.Create(nil);
  try
    unqryEmpleados.Connection := oConn;
    unqryEmpleados.SQL.Text := 'SELECT CODIGO_EMPL ' +
                                                    'as `Código de Empleado`,' +
                               '       DIMINUTIVO_TICKET_EMPL ' +
                                                     'as `Nombre de Empleado`' +
                               '  FROM fza_empleados ' +
                               ' WHERE ESACTIVO_EMPL =' +QuotedStr('S') +
                               '   AND CODIGO_EMPL IS NOT NULL' +
                               ' ORDER BY CODIGO_EMPL ';
    formulario := TfrmMtoSearch.Create(nil);
    try
      formulario.Name := 'frmMtoEmpCajSearch';
      formulario.Caption := 'Búsqueda de Empleados en Caja';
      formulario.dsTablaG.DataSet := unqryEmpleados;
      unqryEmpleados.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
      if formulario.sFicha = 'S' then
      begin
        btnCodigoEmpleado.Text := unqryEmpleados.Fields[0].AsString;
        if btnCodigoEmpleado.ValidateEdit(True) then
        begin
          btnCodigoCliente.SetFocus;
        end;
      end;
    finally
      FreeAndNil(formulario);
    end;
  finally
    FreeAndNil(unqryEmpleados);
  end;
end;

procedure TfrmMtoOpeCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMtoOpeCaja.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBmpSwatchBoton);
end;

// Carga en imgFotoStock la foto a 300 px del articulo / SKU de la
// linea activa. Lo invoca DsLineasDataChange al cambiar de registro.
procedure TfrmMtoOpeCaja.RefrescarFotoStock;
var
  sArt : string;
  sSku : string;
  info : TFotoInfo;
  sRuta: string;
  png  : TPngImage;
begin
  if not Assigned(imgFotoStock) then Exit;
  imgFotoStock.Picture.Assign(nil);
  if not Assigned(dsLineas) then Exit;
  LeerArtSkuDeDataSet(dsLineas.DataSet, sArt, sSku);
  if sArt = '' then Exit;
  info  := oFotos.Resolver(sArt, sSku);
  sRuta := oFotos.RutaFoto(info, frPx300);
  if sRuta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(sRuta);
    imgFotoStock.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

procedure TfrmMtoOpeCaja.DsLineasDataChange(Sender: TObject; Field: TField);
begin
  // Solo refrescamos cuando cambia el registro activo (Field = nil),
  // no en cada cambio de columna.
  if Field = nil then
    RefrescarFotoStock;
end;

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
begin
  inherited;
  FBmpSwatchBoton := TBitmap.Create;
  // FswArtAPopup es un record (TStopwatch) — se inicializa a cero por
  // defecto, IsRunning sera False hasta que se arranque en
  // tvArticuloPropertiesValidate.
  DatosCaja := TdmCajaOpe.Create(Self);
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := DatosCaja.qryStock;
  dsLineas.OnDataChange := DsLineasDataChange;
  ConstruirColumnasDinamicas;
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
  DatosCaja.OnRellenarArticulo  := RellenarDatosArticuloEnDataset;
  DatosCaja.OnRellenarAtributos := RellenarAtributosDesdeSku;
  tvEmpleado.Visible      := oCajaParams.GetBool('vgerShowEmpleadoLinea', True);
  var PermiteDescuentos := oCajaParams.GetBool('vgerDescuentos', True);
  tvDescuento.Options.Editing := PermiteDescuentos;
  tvDescuentoMenos.Options.Editing := PermiteDescuentos;
  // El Total tambien es editable y, al bajarlo, aplica un descuento
  // implicito (GridRecalc recalcula % y Menos a partir del total). Si no
  // se permiten descuentos hay que bloquearlo igual que % y Menos; de lo
  // contrario seria una via para saltarse el control editando el total.
  tvTotal.Options.Editing := PermiteDescuentos;
  // El Precio unitario es la otra via: bajarlo reduce el importe (un
  // descuento de facto). Con descuentos denegados, el precio de tarifa
  // queda intocable.
  tvPrecioUni.Options.Editing := PermiteDescuentos;
  with dbtvBusq.DataController do
  begin
    DataModeController.GridMode := True;
    DataModeController.SyncMode := False;
    Filter.AutoDataSetFilter := False;
    Options := Options - [dcoImmediatePost, dcoGroupsAlwaysExpanded];
  end;
  with dbtvBusq.OptionsBehavior do
  begin
    IncSearch := False;
    IncSearchItem := nil;
  end;
  repSoloTexto.Properties.OnValidate := tvArticuloPropertiesValidate;
  repComboBox.Properties.OnCloseUp   := tvArticuloPropertiesCloseUp;
end;

procedure TfrmMtoOpeCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  delta: Cardinal;
begin
  // Reseteamos el flag de "Enter ya consumido" en cada pulsacion; solo lo
  // dejamos activo de forma transitoria entre el VK_RETURN consumido y su #13
  // de KeyPress. Asi nunca queda obsoleto y se traga un Enter manual posterior.
  FScanVelComido := False;
  if (Key = VK_F5) then
    btnF5.Click;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    ResetearLayout(Self.Name);
    Key := 0;
  end;
  // Cierre del detector 2 (codigo de barras + CR por velocidad de tecleo). Lo
  // resolvemos en KeyDown (no en KeyPress) para adelantarnos al editor del grid
  // (que procesa VK_RETURN) y a jvEnterTab (Enter->Tab): el FormKeyDown con
  // KeyPreview corre antes que ambos. Si el buffer es una rafaga del lector y
  // el Enter llega igual de rapido, lo tratamos como lectura y lo encaminamos
  // al mismo procesado que la trama STX/ETX.
  if (Key = VK_RETURN) and oCajaParams.GetBool('vgerScanVelActivo', True) then
  begin
    delta := GetTickCount - FScanVelTick;
    if (Length(FScanVelBuffer) >=
                              oCajaParams.GetInt('vgerScanMinLong', 4)) and
       (delta <= Cardinal(oCajaParams.GetInt('vgerScanVelMs', 40))) then
    begin
      FCodigoScanPend := Trim(FScanVelBuffer);
      FScanVelBuffer  := '';
      FScanVelComido  := True;  // tragaremos el #13 que vendra por KeyPress
      Key := 0;                 // ni el grid ni jvEnterTab procesan este Enter
      PostMessage(Handle, WM_PROCESAR_SCANNER, 0, 0);
    end;
  end;
end;

// Ctrl+U: consulta de stock del articulo de la linea que se esta metiendo.
// Lee el (articulo, sku) de la linea enfocada con el mismo helper que usan
// los mantenimientos via TfrmMtoGen.ResolverArtSkuActivo (CODIGO_ART_FACLIN
// y CODIGO_UNIDAD_FACLIN estan entre sus alias). Si la linea aun no tiene
// articulo resuelto, abre la consulta vacia con su buscador.
procedure TfrmMtoOpeCaja.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  // Articulo/sku de la linea de caja en foco (vacio si aun no hay).
  ACodArt := '';
  ACodSku := '';
  if Assigned(DatosCaja) and Assigned(DatosCaja.cdsLineas) then
    inLibFotos.LeerArtSkuDeDataSet(DatosCaja.cdsLineas, ACodArt, ACodSku);
end;

procedure TfrmMtoOpeCaja.actConsultaStockExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  ResolverArtSkuStock(sArt, sSku);
  inMtoStockConsulta.MostrarStockConsulta(Self, sArt, sSku);
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  RestaurarLayoutCaja;
  ActualizarFoco;
end;

// ForzarDespliegue queda como stub porque sigue en la declaracion privada;
// el OnEnter de TcxButtonEdit ahora apunta a AbrirPopupAvEnEntrada que
// abre el popup SeleccionarAvConPaleta directamente (mismo patron que
// inMtoInventarios).
//procedure TfrmMtoOpeCaja.ForzarDespliegue(Sender: TObject);
//begin
//  // Sin uso: el flujo de seleccion de atributos pasa por
//  // AbrirPopupAvEnEntrada + tvLineasOpeAvButtonClick.
//end;

procedure TfrmMtoOpeCaja.AbrirPopupAvEnEntrada(Sender: TObject);
var
  BE: TcxCustomEdit;
begin
  // OnEnter single-shot: cuando el usuario entra en una celda Color/Talla
  // vacia, disparamos el popup automaticamente (sustituye a la antigua
  // ForzarDespliegue que desplegaba el TcxComboBox).
  //
  // No abrimos el popup en linea: cuando WMAvanzarAtribCaja salta de Color
  // a Talla, ShowEdit/InitEdit/OnEnter encadenan en el mismo callstack y
  // el TcxButtonEdit recien creado para Talla aun no ha terminado de
  // parentar; ClientToScreen dentro de tvLineasOpeAvButtonClick pediria
  // Handle -> Parent -> EInvalidOperation. PostMessage hace que el handler
  // retorne y cxGrid acabe la colocacion antes de abrir el popup.
  if not (Sender is TcxCustomEdit) then Exit;
  BE := TcxCustomEdit(Sender);
  BE.OnEnter := nil;
  PostMessage(Self.Handle, WM_ABRIR_POPUP_AV, 0, 0);
end;

procedure TfrmMtoOpeCaja.WMAbrirPopupAv(var Msg: TMessage);
var
  CurrentEdit: TcxCustomEdit;
  msTotal: Int64;
begin
  // Disparado por AbrirPopupAvEnEntrada via PostMessage. Para entonces
  // cxGrid ya termino de parentar el TcxButtonEdit, asi que podemos
  // llamar al click handler con el editor actual.
  // Si FswArtAPopup esta en marcha, registramos el tiempo total desde
  // tvArticuloPropertiesValidate hasta aqui — es lo que el usuario
  // percibe como "demora entre Enter del codigo y desplegable".
  if FswArtAPopup.IsRunning then
  begin
    msTotal := FswArtAPopup.ElapsedMilliseconds;
    FswArtAPopup.Stop;
//    LogPerfCaja('CajaOpe.Art2Popup',
//      Format('total Enter->popup=%d ms', [msTotal]));
  end;
  if not tvLineasOpe.Controller.EditingController.IsEditing then Exit;
  CurrentEdit := tvLineasOpe.Controller.EditingController.Edit;
  if (CurrentEdit is TcxButtonEdit)
     and (CurrentEdit.Tag >= 1) and (CurrentEdit.Tag <= 5) then
    tvLineasOpeAvButtonClick(CurrentEdit, 0);
end;

procedure TfrmMtoOpeCaja.CargarAvsValidos(const ACodArt: string;
  AOrden: Integer; var AAvs: TArray<string>);
var
  Lookup : TArticulosAtributosLookup;
  Vals   : TArray<TArticuloAtributoValor>;
  i      : Integer;
begin
  // Devuelve los AV (BLANCO, MALVA, 42, 44, ...) que el articulo tiene
  // referenciados en alguno de sus SKUs para la columna `AOrden`. Mismo
  // metodo que usa inMtoInventarios: ordena por ORDEN_AV para que tallas
  // S/M/L/XL salgan correctamente.
  SetLength(AAvs, 0);
  if Trim(ACodArt) = '' then Exit;
  if (AOrden < 1) or (AOrden > 5) then Exit;
  Lookup := TArticulosAtributosLookup.Create(oConn);
  try
    Vals := Lookup.ObtenerAvsEnSkus(ACodArt, AOrden);
  finally
    FreeAndNil(Lookup);
  end;
  SetLength(AAvs, Length(Vals));
  for i := 0 to High(Vals) do
    AAvs[i] := Vals[i].Valor;
end;

procedure TfrmMtoOpeCaja.RegistrarValorAtributo(AOrden: Integer;
                                                 const AvNuevo: string);
var
  SkuNuevo: string;
  NumAtributosRequeridos, NumSeparadores, i: Integer;
begin
  // Aplica el AV elegido por el usuario en el popup al campo ATTRn_VALOR
  // y recalcula el SKU final (CODIGO_UNIDAD_FACLIN). Si el SKU queda
  // completo, dispara el recalculo de precio. La finalizacion de la linea
  // (validar SKU, consultar stock, avanzar foco) se hace fuera para no
  // mover el foco con el editor todavia activo: ver tvLineasOpeAvButtonClick.
  // Sustituye al antiguo OnAtributoChanged del TcxComboBox.
  if (AOrden < 1) or (AOrden > 5) then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;
  if DatosCaja.cdsLineas.State = dsBrowse then
    DatosCaja.cdsLineas.Edit;
  if not (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  DatosCaja.cdsLineas.FieldByName(
    'ATTR' + IntToStr(AOrden) + '_VALOR').AsString := AvNuevo;

  SkuNuevo := DatosCaja.GenerarSkuFinal(
                DatosCaja.cdsLineas.FieldByName(
                  'CODIGO_ART_FACLIN').AsString);
  if Trim(SkuNuevo) = '' then
    SkuNuevo := DatosCaja.cdsLineas.FieldByName(
                  'CODIGO_ART_FACLIN').AsString;
  DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := SkuNuevo;

  NumAtributosRequeridos := DatosCaja.cdsLineas.FieldByName(
                              'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  NumSeparadores := 0;
  for i := 1 to Length(SkuNuevo) do
    if SkuNuevo[i] = '/' then Inc(NumSeparadores);

  if (NumAtributosRequeridos > 0)
     and (NumSeparadores = NumAtributosRequeridos) then
    RecalcularPrecioDesdeSku(SkuNuevo);
end;

procedure TfrmMtoOpeCaja.FinalizarUltimoAtributo;
var
  SkuNuevo : string;
  EstabaInsertando : Boolean;
begin
  // Logica que antes vivia inline en cxGrid1DBTableView1EditKeyDown cuando
  // se confirmaba el ultimo atributo de la linea. Encapsulada para poder
  // invocarla desde tvLineasOpeAvButtonClick (popup) sin duplicar codigo.
  if FProcesandoAtributo then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;

  // Defensivo: aseguramos que no queda un inplace editor activo antes de
  // empezar a hacer Cancel/Append. Los broadcasts del data link (sobre
  // todo tras el ShowMessage de "no hay stock") intentarian refrescar el
  // TcxButtonEdit y, si cxGrid ya lo desparento, salta EInvalidOperation.
  // HideEdit(False): no intentamos PostEditValue, los campos ya estan
  // escritos por RegistrarValorAtributo.
  if tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(False);

  FProcesandoAtributo := True;
  DatosCaja.cdsLineas.DisableControls;
  try
    EstabaInsertando := (DatosCaja.cdsLineas.State = dsInsert);
    SkuNuevo := DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_UNIDAD_FACLIN').AsString;

    if EstabaInsertando and ConsolidarSiExiste(SkuNuevo) then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      if not DatosCaja.cdsLineas.IsEmpty then
        if DatosCaja.cdsLineas.FieldByName(
                   'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo then
          DatosCaja.cdsLineas.Delete;
      DatosCaja.cdsLineas.EnableControls;
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
      Exit;
    end;

    if not ValidarSkuParaVenta(SkuNuevo) then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      if not DatosCaja.cdsLineas.IsEmpty
         and (DatosCaja.cdsLineas.FieldByName(
                      'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
        DatosCaja.cdsLineas.Delete;
      DatosCaja.cdsLineas.EnableControls;
      //dbtvStock.ClearItems;
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
      Exit;
    end;

    ConsultarStock(SkuNuevo);
  finally
    FProcesandoAtributo := False;
    DatosCaja.cdsLineas.EnableControls;
  end;

  if oCajaParams.GetBool('vgerMoverLineaIdentif', True) then
  begin
    if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
      DatosCaja.cdsLineas.Post;
    DatosCaja.cdsLineas.Append;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
  end
  else
    tvLineasOpe.Controller.FocusedColumn := tvDescripcion;

  tvLineasOpe.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoOpeCaja.tvLineasOpeAvButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
var
  Col       : TcxGridColumn;
  Orden     : Integer;
  ArtPadre  : string;
  AvActual  : string;
  NombreAtb : string;
  IdVa      : string;
  AvNuevo   : string;
  Avs       : TArray<string>;
  Mapa      : TDictionary<string, string>;
  EditCtrl  : TWinControl;
  ScrPt     : TPoint;
  WidHint   : Integer;
  sw, swAvs : TStopwatch;
  msAvs     : Int64;
begin
  // Click en el boton de una columna de atributo (Color, Talla, ...): abre
  // el popup SeleccionarAvConPaleta con cuadraditos de paleta. Mismo flujo
  // que inMtoInventarios.tvLineasSkuPropertiesButtonClick.
  sw := TStopwatch.StartNew;
  msAvs := 0;
  Col := tvLineasOpe.Controller.FocusedColumn;
  if Col = nil then Exit;
  Orden := Col.Tag;
  if (Orden < 1) or (Orden > 5) then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;

  ArtPadre  := DatosCaja.cdsLineas.FieldByName(
                 'CODIGO_ART_FACLIN').AsString;
  AvActual  := DatosCaja.cdsLineas.FieldByName(
                 'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
  NombreAtb := DatosCaja.cdsLineas.FieldByName(
                 'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;

  swAvs := TStopwatch.StartNew;
  CargarAvsValidos(ArtPadre, Orden, Avs);
  msAvs := swAvs.ElapsedMilliseconds;
  if Length(Avs) = 0 then
  begin
    ShowMessage('No hay valores definidos para este atributo.');
//    LogPerfCaja('CajaOpe.AvButtonClick',
//      Format('art=%s orden=%d | Avs=%d | sin valores | total=%d ms',
//             [ArtPadre, Orden, msAvs, sw.ElapsedMilliseconds]));
    Exit;
  end;

  IdVa := '';
  Mapa := ObtenerMapaAtributosGlobal;
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

  // Posicion del popup justo debajo del editor. SeleccionarAvConPaleta
  // acepta (-1, -1) para auto-centrar; lo usamos como fallback. cxGrid
  // mantiene los TcxButtonEdit en un pool y a veces el editor inplace que
  // recibimos en Sender (sea via OnButtonClick, OnEnter via
  // AbrirPopupAvEnEntrada, o F3 via actBuscarEmpleadosExecute) llega sin
  // Parent en la pasada — ClientToScreen pide Handle, Handle pide Parent
  // y salta EInvalidOperation. Comprobamos HasParent y, por si hay carrera
  // entre el check y la llamada, envolvemos en try/except.
  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 120;
  if (Sender is TWinControl) and TWinControl(Sender).HasParent then
  begin
    EditCtrl := TWinControl(Sender);
    try
      ScrPt   := EditCtrl.ClientToScreen(Point(0, EditCtrl.Height));
      WidHint := EditCtrl.Width;
    except
      on E: EInvalidOperation do
      begin
        ScrPt.X := -1;
        ScrPt.Y := -1;
        WidHint := 120;
      end;
    end;
  end;

  if not SeleccionarAvConPaleta(IdVa, Avs, AvActual, AvNuevo,
                                 ScrPt.X, ScrPt.Y, WidHint) then
    Exit;

  RegistrarValorAtributo(Orden, AvNuevo);

  // Reflejamos el AV nuevo en el editor para que el usuario lo vea sin
  // tener que esperar a que se reabra la celda. Solo si Sender sigue
  // parentado: durante el modal SeleccionarAvConPaleta cxGrid puede
  // haberle quitado el Parent al editor inplace (perdida de foco) y un
  // EditValue := X sobre un control sin parent dispara EInvalidOperation
  // 'no tiene ventana principal'.
  if (Sender is TcxCustomEdit) and TWinControl(Sender).HasParent then
  begin
    try
      TcxCustomEdit(Sender).EditValue := AvNuevo;
    except
      on E: EInvalidOperation do
        // Defensivo: si cxGrid desparenta el editor entre el HasParent
        // de arriba y el set EditValue, seguimos sin pintar — el data
        // link ya tiene el valor via RegistrarValorAtributo.
        ;
    end;
  end;

  // Cerramos el editor inplace ANTES de tocar cdsLineas / cambiar foco. Usamos
  // HideEdit(False) porque RegistrarValorAtributo ya escribio el campo: pedir
  // PostEditValue (HideEdit(True)) sobre un editor que cxGrid pudo
  // desparentar durante el popup vuelve a disparar EInvalidOperation.
  if tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(False);

  // Diferimos via PostMessage para soltar el callstack del OnButtonClick.
  // Asi cxGrid termina de limpiar el editor inplace (que ya HideEdit'amos)
  // antes de que FinalizarUltimoAtributo abra el ShowMessage de "no hay
  // stock" o haga Cancel/Append. Si lo hacemos en linea, los DataChange
  // del EnableControls/Append intentan refrescar el TcxButtonEdit que
  // cxGrid todavia tiene en su pool con Parent = nil -> EInvalidOperation.
  if (Orden = FNumAtributosActual) and (FNumAtributosActual > 0) then
    PostMessage(Self.Handle, WM_FINALIZAR_ATRIB_CAJA, 0, 0)
  else
    PostMessage(Self.Handle, WM_AVANZAR_ATRIB_CAJA, Orden + 1, 0);

//  LogPerfCaja('CajaOpe.AvButtonClick',
//    Format('art=%s orden=%d AvNuevo=%s | Avs=%d | total=%d ms',
//           [ArtPadre, Orden, AvNuevo, msAvs, sw.ElapsedMilliseconds]));
end;

procedure TfrmMtoOpeCaja.WMFinalizarAtribCaja(var Msg: TMessage);
begin
  // Ejecuta FinalizarUltimoAtributo fuera del callstack del OnButtonClick
  // del TcxButtonEdit. Ver tvLineasOpeAvButtonClick para el motivo.
  FinalizarUltimoAtributo;
end;

procedure TfrmMtoOpeCaja.WMAvanzarAtribCaja(var Msg: TMessage);
var
  SigCol : TcxGridDBColumn;
  sw : TStopwatch;
begin
  // Avanza el foco a la siguiente columna de atributo. Diferido por la
  // misma razon que WMFinalizarAtribCaja.
  sw := TStopwatch.StartNew;
  SigCol := ObtenerColumnaPorTag(Msg.WParam);
  if (SigCol <> nil) and SigCol.Visible then
  begin
    tvLineasOpe.Controller.FocusedColumn := SigCol;
    tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
//  LogPerfCaja('CajaOpe.AvanzarAtrib',
//    Format('tag=%d | total=%d ms',
//           [Integer(Msg.WParam), sw.ElapsedMilliseconds]));
end;

procedure TfrmMtoOpeCaja.GuardarLayoutCaja;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(Self.Name);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('StockPanelHeight', pnlBusqueda);
    Layout.GuardarAnchoPanel('FotoStockWidth',    pnlFotoStock);
    Layout.GuardarGrid('Lineas', tvLineasOpe);
    if Layout.PreguntarYGrabar('Personalización Caja') then
      ShowMessage('Layout guardado.');
  finally
    FreeAndNil(Layout);
  end;
end;

function TfrmMtoOpeCaja.IntentarCerrar: Boolean;
begin
  Result := True;
  if (csDestroying in ComponentState) then Exit;
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
  begin
    if not Visible then
    begin
      Show;
      BringToFront;
    end;
    if MessageDlg(
      Format('La Operación %d tiene artículos pendientes.' + sLineBreak +
                         '¿Desea ELIMINARLA y cerrar?', [Self.Tag]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      Close;
    end
    else
    begin
      Result := False;
    end;
  end
  else
  begin
    Close;
  end;
end;

function TfrmMtoOpeCaja.ObtenerColumnaPorTag(
  NumColumn: Integer): TcxGridDBColumn;
var
  i:Integer;
begin
  Result := nil;
  for i:= 0 to tvLineasOpe.ColumnCount - 1 do
    if (tvLineasOpe.Columns[i].Tag = NumColumn) then
    begin
      Result := (tvLineasOpe.Columns[i] as TcxGridDBColumn);
      Exit;
    end;
end;

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  lblFechaCaja.Caption := FormatDateTime('hh:nn:ss dddd d mmmm yyyy', Now);
end;

end.
