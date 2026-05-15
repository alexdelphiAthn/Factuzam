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
  System.Classes, System.Generics.Collections, Vcl.Graphics, inMtoGenSearch,
  system.Math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, cxDBData, cxClasses, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems, system.UITypes,
  System.Actions, Vcl.ActnList, Vcl.ImgList, cxImageComboBox;

const
  WM_CANCELAR_LINEA = WM_USER + 100;
  WM_SALTAR_ATRIBUTO = WM_USER + 101;
type
  TfrmMtoOpeCaja = class(TForm)
    pnlUp1: TPanel;
    pnlCli1: TPanel;
    lblFecha: TcxLabel;
    Panel1: TPanel;
    btnF12: TcxButton;
    btnF3: TcxButton;
    btnF6: TcxButton;
    btnF5: TcxButton;
    btnF7: TcxButton;
    cxLabel1: TcxLabel;
    cxLabel2: TcxLabel;
    cxLabel3: TcxLabel;
    cxLabel4: TcxLabel;
    cxLabel5: TcxLabel;
    Panel2: TPanel;
    cxGrid1: TcxGrid;
    cxGrid1DBTableView1: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
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
    cxLabel6: TcxLabel;
    lblNombreEmpleado: TcxLabel;
    cxLabel8: TcxLabel;
    btnCodigoCliente: TcxButtonEdit;
    lblNombreCliente: TcxLabel;
    Timer1: TTimer;
    dsLineas: TDataSource;
    jvntrstb1: TJvEnterAsTab;
    lblFechaCaja: TcxLabel;
    btnCodigoEmpleado: TcxButtonEdit;
    lblTarifa: TcxLabel;
    lblInstrucciones: TcxLabel;
    pnl1: TPanel;
    cxgrdStock: TcxGrid;
    dbtvStock: TcxGridDBTableView;
    cxgrdlvl1: TcxGridLevel;
    dsStock: TDataSource;
    cxspltr1: TcxSplitter;
    cxstylrpstry: TcxStyleRepository;
    cxstyl: TcxStyle;
    cxstyl1: TcxStyle;
    tmrBusq: TTimer;
    dsBusq: TDataSource;
    qryBusq: TUniQuery;
    tvrBusq: TcxGridViewRepository;
    dbtvBusqDBTableView1: TcxGridDBTableView;
    cxstyl2: TcxStyle;
    cxgrdbclmnBusqDBTableView1INPUT_BUSQUEDA: TcxGridDBColumn;
    cxgrdbclmnBusqDBTableView1CODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnBusqDBTableView1DESCRIPCION_ARTICULO: TcxGridDBColumn;
    edtrepArticulo: TcxEditRepository;
    repSoloTexto: TcxEditRepositoryTextItem;
    repComboBox: TcxEditRepositoryExtLookupComboBoxItem;
    btnF61: TcxButton;
    lbl1: TcxLabel;
    actlst1: TActionList;
    actBuscarEmpleados: TAction;
    actSalir: TAction;
    actEliminarLinea: TAction;
    actCobro: TAction;
    btnF2: TcxButton;
    cxLabel7: TcxLabel;
    actCargarCta: TAction;
    actGuardarLayout: TAction;
    actAbrirArticulos: TAction;
    procedure actAbrirArticulosExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnF5Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClientePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure FormShow(Sender: TObject);
    procedure txtEntradaArticuloKeyPress(Sender: TObject; var Key: Char);
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
    procedure cxGrid1DBTableView1CustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure cxGrid1DBTableView1GetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
    procedure dbtvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure dbtvStockGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
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
    procedure ForzarDespliegue(Sender: TObject);
    procedure ConstruirColumnasDinamicas;
    procedure RellenarAtributosDesdeSku(Sku: string);
    procedure ActualizarColumnasDinamicas(ArticuloPadre: string);
    procedure PoblarItemsAtributoCol(Tag: Integer;
                                     const ArticuloPadre: string);
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
    procedure ComboAtributoCloseUp(Sender: TObject);
  public
    DatosCaja: TdmCajaOpe;
  private
    FScanBuffer: string;
    FLeyendoScanner: Boolean;
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
    // ID_VA (variacion: 'CO', 'TAL'...) por cada columna dinamica (tag 1..5).
    // Se rellena en ActualizarColumnasDinamicas y se consulta al pintar el
    // cuadrado de color en OnCustomDrawCell.
    FIdVariacionPorTag: array[1..5] of string;
    // NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO del articulo cuyo stock
    // estamos visualizando en dbtvStock. Se rellena en ConsultarStock.
    FAtributosStock: TDictionary<string, string>;
    // Un TImageList por columna dinamica con los swatches de color de los
    // valores que el desplegable va a mostrar. Asociado en OnInitEdit.
    FImagesPorTag    : array[1..5] of TImageList;
    // Diccionario uppercase(AV) -> ImageIndex por columna, para asignar el
    // icono correcto a cada item del desplegable.
    FAvToIndexPorTag : array[1..5] of TDictionary<string, Integer>;
  private
    FNumeroCajaActual: Integer;
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
  inMtoCajaFaseCobro, inLibDevExp, inLibtb,
  inLibFacturas, inLibGenBusq, inLibCajaParam, inLibGenerarTicket,
  inMtoModalGenImpSave, inLibLayoutForm,
  inLibArticulosValidador, inLibArticulosResolver,
  inLibArticulosAtributosLookup,
  inLibAtributosPaleta,
  inLibShowMto, inMtoPrincipal,
  System.StrUtils;

procedure TfrmMtoOpeCaja.ActualizarFoco;
begin
  if btnCodigoEmpleado.Text = '' then
  begin
    if btnCodigoEmpleado.CanFocus then
      btnCodigoEmpleado.SetFocus;
  end
  else if cxGrid1.CanFocus then
  begin
    cxGrid1.SetFocus;
  end;
end;

procedure TfrmMtoOpeCaja.ComboAtributoCloseUp(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_SALTAR_ATRIBUTO, 0, 0);
end;

procedure TfrmMtoOpeCaja.WMSaltarAtributo(var Msg: TMessage);
begin
  if (cxGrid1DBTableView1.Controller.EditingController <> nil) and
     (cxGrid1DBTableView1.Controller.EditingController.IsEditing) then
  begin
    PostMessage(cxGrid1DBTableView1.Controller.EditingController.Edit.Handle,
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
    if (cxGrid1DBTableView1.Controller.EditingController <> nil) and
       cxGrid1DBTableView1.Controller.EditingController.IsEditing then
    begin
      cxGrid1DBTableView1.Controller.EditingController.HideEdit(True);
    end;
    // 2. Vaciar las líneas de la venta anterior
// if (DatosCaja.cdsLineas.Active) and (DatosCaja.cdsLineas.RecordCount > 0)
// then
//    begin
//      DatosCaja.cdsLineas.EmptyDataSet;
//    end;
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
    cxGrid1DBTableView1.DataController.Refresh;
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
  View: TcxGridDBTableView;
  I:Integer;
begin
  View := dbtvStock;
  View.BeginUpdate;
  if (CodigoInput <> '') then
  begin
    with DatosCaja.qryStock do
    begin
      Close;
      View.ClearItems;
      Connection := inLibGlobalVar.oConn;
      ParamByName('ARTICULO').AsString := CodigoInput;
      Open;
      if not IsEmpty then
      begin
        View.DataController.CreateAllItems;
        for I := 0 to View.ColumnCount - 1 do
        begin
          if (I = 0) or (I = 1) then
            View.Columns[I].HeaderAlignmentHorz := taLeftJustify
          else
            View.Columns[I].HeaderAlignmentHorz := taRightJustify;
        end;
      end;
    end;
    View.EndUpdate;
    if DatosCaja.qryStock.Active and not DatosCaja.qryStock.IsEmpty then
    begin
      try
        View.ApplyBestFit;
      except
      end;
    end;
    // Cargamos el mapa NOMBRE_ATRIBUTO -> ID_VA del articulo para que el
    // OnCustomDrawCell sepa con que ID_VA buscar en la paleta de basicos.
    CargarMapaAtributosArticulo(CodigoInput, FAtributosStock);
  end
  else
    FAtributosStock.Clear;
end;

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
        ' WHERE CODIGO_UNIDAD_SKU = :sku';
      qry.ParamByName('sku').AsString := SkuLimpio;
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
      qry.Free;
    end;
  end;

  if oCajaParams.GetBool('vgerChkStockOnly', False) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      if Trim(FCodigoAlmacen) <> '' then
      begin
        qry.SQL.Text :=
          'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
          '  FROM fza_articulos_stockactual ' +
          ' WHERE CODIGO_UNIDAD_STK = :sku ' +
          '   AND CODIGO_ALM_STK    = :alm';
        qry.ParamByName('sku').AsString := SkuLimpio;
        qry.ParamByName('alm').AsString := FCodigoAlmacen;
      end
      else
      begin
        qry.SQL.Text :=
          'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
          '  FROM fza_articulos_stockactual ' +
          ' WHERE CODIGO_UNIDAD_STK = :sku';
        qry.ParamByName('sku').AsString := SkuLimpio;
      end;
      qry.Open;
      Cantidad := qry.FieldByName('QTY').AsFloat;
      if Cantidad <= 0 then
      begin
        MensajeStock := oCajaParams.GetString('vgerAvisoStockWarning',
          'Artículo sin stock. Compruebe stock en almacén.');
        ShowMessage(MensajeStock);
        Result := False;
        Exit;
      end;
    finally
      qry.Free;
    end;
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

  dbtvStock.ClearItems;
  GridRecalc(nil,
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.txtEntradaArticuloKeyPress(Sender: TObject;
                                                    var Key: Char);
begin
  if Key = #2 then
  begin
    FLeyendoScanner := True;
    FScanBuffer := '';
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
      if Trim(FScanBuffer) <> '' then
      begin
        tmrBusq.Enabled := False;
        cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
        cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
        if cxGrid1DBTableView1.Controller.EditingController.IsEditing then
        begin
          cxGrid1DBTableView1.Controller.EditingController.Edit.EditValue :=
                                                                    FScanBuffer;
          cxGrid1DBTableView1.Controller.EditingController.Edit.PostEditValue;
        end;
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
               cxGrid1DBTableView1,
               DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera,
               ActualizarLabelTotal);
    AsegurarLineaNueva;
  end;
end;

procedure TfrmMtoOpeCaja.tmrBusqTimer(Sender: TObject);
var
  EditActivo: TcxCustomEdit;
  TextoBusqueda: string;
begin
  tmrBusq.Enabled := False;
  dbtvBusqDBTableView1.BeginUpdate;
  try
    dbtvBusqDBTableView1.DataController.DataSource := nil;
    dbtvBusqDBTableView1.DataController.Filter.Clear;
    dbtvBusqDBTableView1.DataController.Filter.Active := False;
    dbtvBusqDBTableView1.Controller.IncSearchingText := '';
    if cxGrid1DBTableView1.Controller.EditingController.IsEditing then
    begin
      EditActivo := cxGrid1DBTableView1.Controller.EditingController.Edit;
      if EditActivo <> nil then
      begin
        if EditActivo is TcxCustomTextEdit then
           TextoBusqueda := TcxCustomTextEdit(EditActivo).Text
        else
           TextoBusqueda := VarToStr(EditActivo.EditingValue);
        if TcxCustomTextEdit(EditActivo).SelLength > 0 then
            TextoBusqueda := Copy(TcxCustomTextEdit(EditActivo).Text, 1,
                                  TcxCustomTextEdit(EditActivo).SelStart)
         else
            TextoBusqueda := TcxCustomTextEdit(EditActivo).Text;
        TextoBusqueda := Trim(TextoBusqueda);
        if Length(TextoBusqueda) >= 1 then
        begin
          qryBusq.Connection := oConn;
          qryBusq.Close;
          qryBusq.ParamByName('TOKEN').AsString := '%' + TextoBusqueda + '%';
          qryBusq.Open;
          dbtvBusqDBTableView1.DataController.DataSource := dsBusq;
          dbtvBusqDBTableView1.DataController.Refresh;
        end;
      end;
    end;
  finally
    dbtvBusqDBTableView1.EndUpdate;
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
  if (ARecord = nil) or (cxGrid1DBTableView1.Controller = nil) then
    Exit;
  ValorActual := ARecord.Values[Sender.Index];
  if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
  begin
    AProperties := repSoloTexto.Properties;
    Exit;
  end;
  EsLaCeldaFocale := (cxGrid1DBTableView1.Controller.FocusedRecord = ARecord)
                     and
                     (cxGrid1DBTableView1.Controller.FocusedItem = Sender);
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
begin
  var unqryCon := TUniQuery.Create(nil);
  try
    unqryCon.Connection := oConn;
    unqryCon.SQL.Text :=
      'CALL PRC_BUSQUEDA_ARTICULOS(' +
      '                            :p_tarifa,'   +
      '                            :p_almacen,'  +
      '                            :p_fecha,'    +
      '                            :p_token,'    +
      '                            :p_solostock,' +
      '                            :p_solotarifa)';

    unqryCon.ParamByName('p_tarifa').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    unqryCon.ParamByName('p_almacen').AsString  := FCodigoAlmacen;
    unqryCon.ParamByName('p_fecha').AsDate      := FFecha;
    unqryCon.ParamByName('p_token').AsString    := '';   // sin filtro inicial
    unqryCon.ParamByName('p_solostock').AsInteger :=
                       Ord(oCajaParams.GetBool('vgerBusqArtStockOnly',  False));
    unqryCon.ParamByName('p_solotarifa').AsInteger :=
                       Ord(oCajaParams.GetBool('vgerBusqArtTarifaOnly', False));
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Caja',
                                       unqryCon,
                                       'frmMtoArtFacSearch') then
      Result := unqryCon.FieldByName('CODIGO_ART_ART').AsString
    else
      Result := '';
  finally
    unqryCon.Free;
  end;
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodigoInput: string;
  CodigoPadre: string;
  SkuDetectado: string;
  NumAtributos: Integer;
begin
  CodigoInput := VarToStr(DisplayValue);
  if RellenarDatosArticuloEnDataset(CodigoInput) then
  begin
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
      Abort;
    end;
    if (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
    begin
      DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
      GridRecalc(nil,
                 cxGrid1DBTableView1,
                 DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera,
                 ActualizarLabelTotal);
    end;
    if ConsolidarSiExiste(SkuDetectado) then
    begin
       DatosCaja.cdsLineas.Cancel;
       DatosCaja.cdsLineas.Append;
       DisplayValue := null;
       Error := False;
       Abort;
    end;
    tmrBusq.Enabled := False;
    if (CodigoPadre <> '') and (CodigoPadre <> CodigoInput) then
    begin
       DisplayValue := CodigoPadre;
       qryBusq.Connection := oConn;
       if qryBusq.Active then qryBusq.Close;
         qryBusq.ParamByName('TOKEN').AsString := CodigoPadre;
       qryBusq.Open;
    end;
    ActualizarColumnasDinamicas(CodigoPadre);
    if (Trim(SkuDetectado) <> '') and (NumAtributos > 0) then
    begin
       RellenarAtributosDesdeSku(SkuDetectado);
    end;
    Error := False;
  end
  else
  begin
    Error := True;
    ErrorText := 'ARTÍCULO NO ENCONTRADO O DESCATALOGADO';
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
             cxGrid1DBTableView1,
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
             cxGrid1DBTableView1,
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
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvTotalPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             cxGrid1DBTableView1,
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
begin
  Result := False;
  CodigoLimpio := UpperCase(Trim(Codigo));
  if CodigoLimpio = '' then Exit;

  Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  Resolver  := TArticulosResolver.Create(inLibGlobalVar.oConn);
  try
    Resolucion := Validador.Resolver(CodigoLimpio);
    if not Resolucion.Encontrado then
      Exit;

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
          ConsultarStock(Resolucion.CodigoSku);
        DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
                                                Resolucion.CodigoSku;
        RecalcularPrecioDesdeSku(Resolucion.CodigoSku);
        Result := True;
      end
      else if Resolucion.RequiereSku then
      begin
        // Padre con varios SKUs: se mostrarán talla/color al usuario. La
        // línea queda con descripción/IVA/% dto del padre, pero sin precio
        // definitivo hasta que se elija el SKU.
        if not FActualizandoDepositos then
          ConsultarStock(Resolucion.CodigoArticulo);
        DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
                                                Resolucion.CodigoArticulo;
        if not FActualizandoDepositos then
        begin
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo, '',
                                          CodTarifa, FechaTicket);
          // ResolverDatos no calcula precio cuando hay >1 SKU sin elegir;
          // pedimos el del padre explícitamente para arrastrar IVA y %dto.
          var Precio := Resolver.ResolverPrecio(Resolucion.CodigoArticulo, '',
                                                CodTarifa, FechaTicket);
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
      end;
    finally
      DatosCaja.cdsLineas.EnableControls;
    end;
    if Result and (not FActualizandoDepositos) then
      GridRecalc(nil, cxGrid1DBTableView1, DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    Validador.Free;
    Resolver.Free;
  end;
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

    GridRecalc(nil, cxGrid1DBTableView1, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    Resolver.Free;
  end;
end;

procedure TfrmMtoOpeCaja.RellenarAtributosDesdeSku(Sku: string);
var
  Lookup  : TArticulosAtributosLookup;
  Valores : TArray<TArticuloAtributoValor>;
  V       : TArticuloAtributoValor;
  i       : Integer;
begin
  if Trim(Sku) = '' then Exit;
  Lookup := TArticulosAtributosLookup.Create(inLibGlobalVar.oConn);
  try
    Valores := Lookup.ObtenerAtributosDeSku(Sku);
    if Length(Valores) = 0 then Exit;

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
    Lookup.Free;
  end;
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
                   cxGrid1DBTableView1,
                   DatosCaja.cdsLineas,
                   DatosCaja.cdsCabecera,
                   ActualizarLabelTotal);
        Result := True;
        Break;
      end;
      Clon.Next;
    end;
  finally
    Clon.Free;
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
  cxGrid1DBTableView1.BeginUpdate;
  try
    for i := 1 to MaxAtributos do
    begin
      Col := cxGrid1DBTableView1.CreateColumn;
      Col.Name := 'tvAtributoDyn' + IntToStr(i);
      Col.Tag := i;
      Col.DataBinding.FieldName := 'ATTR' + IntToStr(i) + '_VALOR';
      Col.Caption := '-';
      Col.Visible := False;
      Col.Width := 80;
      // TcxImageComboBoxProperties para que el desplegable pinte un swatch
      // delante del texto (imagen del ImageList de su columna).
      Col.PropertiesClass := TcxImageComboBoxProperties;
      with TcxImageComboBoxProperties(Col.Properties) do
      begin
        DropDownListStyle := lsFixedList;
        Images := FImagesPorTag[i];
        OnEditValueChanged := OnAtributoChanged;
      end;
      Col.Index := IndiceBase + i;
    end;
  finally
    cxGrid1DBTableView1.EndUpdate;
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
        DatosCaja.cdsLineas.Cancel;
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
  Combo: TcxImageComboBox;
  NumAtributos: Integer;
  PrimeraColAtributo: TcxGridDBColumn;
  SkuNuevo, ValorActual: string;
  EstabaInsertando: Boolean;
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
         cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
       end
       else
       begin
         cxGrid1DBTableView1.Controller.FocusedColumn := tvDescripcion;
       end;
       cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
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
         cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
       end
       else
       begin
         // Comportamiento alternativo: Quedarse en la línea y pasar a
         // Descripción
         cxGrid1DBTableView1.Controller.FocusedColumn := tvDescripcion;
       end;
       cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
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
         cxGrid1DBTableView1.Controller.FocusedColumn := PrimeraColAtributo;
         cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
         Key := 0;
         Exit;
       end;
    end;
  end;
  if (AItem.Tag > 0) and (AEdit is TcxImageComboBox) then
  begin
    // Dentro de cxGrid1DBTableView1EditKeyDown, justo despues del begin
    // del if (AItem.Tag > 0) and (AEdit is TcxImageComboBox) then ...
//    ShowMessage('EditKeyDown llamado. Key=' + IntToStr(Key) +
//            ' Items=' + IntToStr(Combo.Properties.Items.Count) +
//            ' ItemIndex=' + IntToStr(Combo.ItemIndex) +
//            ' DroppedDown=' + BoolToStr(Combo.DroppedDown, True));
    Combo := TcxImageComboBox(AEdit);
    // CONSULTAR Items via la columna, no via Combo.Properties: en esta version
    // de DevExpress, acceder a Combo.Properties recien instanciado puede
    // producir AV (Self nil al descender la cadena de inherited).
    var ColItems: Integer := 0;
    if AItem is TcxGridDBColumn then
    begin
      var ColProps := TcxGridDBColumn(AItem).Properties;
      if ColProps is TcxImageComboBoxProperties then
        ColItems := TcxImageComboBoxProperties(ColProps).Items.Count;
    end;
    // Enter sobre celda vacia (y dropdown cerrado): abrimos el desplegable
    // via F4 (atajo Windows). Lo intentamos tambien con DroppedDown := True
    // por compatibilidad, ignorando excepciones.
    if (Key = VK_RETURN)
       and not Combo.DroppedDown
       and (ColItems > 0)
       and (Combo.ItemIndex = -1)
       and (Trim(VarToStr(Combo.EditValue)) = '') then
    begin
      try
        Combo.DroppedDown := True;
      except
        // F4 abajo cubre el caso
      end;
      if not Combo.DroppedDown then
      begin
        PostMessage(Combo.Handle, WM_KEYDOWN, VK_F4, 0);
        PostMessage(Combo.Handle, WM_KEYUP,   VK_F4, 0);
      end;
      Key := 0;
      Exit;
    end;
    if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') then
    begin
      if ColItems > 0 then
        Combo.ItemIndex := 0;
    end;
    // Si estaba desplegado, solo cerrarlo y salir
    // El usuario tendrá que pulsar Enter de nuevo para confirmar
    // NO: esto es exactamente el doble Enter que queremos evitar
    // En cambio: cerrarlo y continuar SIN Exit
    if Combo.DroppedDown then
      Combo.DroppedDown := False;
    Combo.PostEditValue;
    if (VarIsNull(Combo.EditValue)) or
       (Trim(VarToStr(Combo.EditValue)) = '') then
    begin
       Key := 0;
       Exit;
    end;
    NumAtributos := FNumAtributosActual;
    // HideEdit SOLO aquí, cuando el combo ya está cerrado y tiene valor
    cxGrid1DBTableView1.Controller.EditingController.HideEdit(True);
    // CAMBIO 5: Usar FNumAtributosActual en lugar de leer del dataset
    NumAtributos := FNumAtributosActual;
    if (AItem.Tag = NumAtributos) then
    begin
      if FProcesandoAtributo then
      begin
        Key := 0;
        Exit;
      end;
      FProcesandoAtributo := True;
      DatosCaja.cdsLineas.DisableControls;
      try
        EstabaInsertando := (DatosCaja.cdsLineas.State = dsInsert);
        SkuNuevo := DatosCaja.GenerarSkuFinal(DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_ART_FACLIN').AsString);
        if not (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
          DatosCaja.cdsLineas.Edit;
        DatosCaja.cdsLineas.FieldByName(
                             'CODIGO_UNIDAD_FACLIN').AsString := SkuNuevo;

        if EstabaInsertando and ConsolidarSiExiste(SkuNuevo) then
        begin
          if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
            DatosCaja.cdsLineas.Cancel;
          if not DatosCaja.cdsLineas.IsEmpty then
            if DatosCaja.cdsLineas.FieldByName(
                       'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo then
              DatosCaja.cdsLineas.Delete;
          DatosCaja.cdsLineas.EnableControls;  // Antes del Append
          DatosCaja.cdsLineas.Append;
          cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
          cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
          Key := 0;
          Exit;
        end;

        // Validación parametrizada del SKU compuesto por talla/color. Si el
        // SKU no existe en fza_articulos_skus o no tiene stock (según
        // parámetros), descartamos la línea y dejamos una nueva preparada.
        if not ValidarSkuParaVenta(SkuNuevo) then
        begin
          if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
            DatosCaja.cdsLineas.Cancel;
          if not DatosCaja.cdsLineas.IsEmpty
             and (DatosCaja.cdsLineas.FieldByName(
                          'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
            DatosCaja.cdsLineas.Delete;
          DatosCaja.cdsLineas.EnableControls;
          dbtvStock.ClearItems;
          DatosCaja.cdsLineas.Append;
          cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
          cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
          Key := 0;
          Exit;
        end;

        RecalcularPrecioDesdeSku(SkuNuevo);
        ConsultarStock(SkuNuevo);

      finally
        FProcesandoAtributo := False;
        DatosCaja.cdsLineas.EnableControls;  // Restaurar siempre
      end;
      if oCajaParams.GetBool('vgerMoverLineaIdentif', True) then
      begin
        // El parámetro indica avanzar: Guardamos y preparamos nueva línea
        if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
          DatosCaja.cdsLineas.Post;

        DatosCaja.cdsLineas.Append;
        cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
      end
      else
      begin
        // El parámetro indica quedarse: Movemos el foco a la descripción
        cxGrid1DBTableView1.Controller.FocusedColumn := tvDescripcion;
      end;

      cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
      Key := 0;
    end; // Fin del if (AItem.Tag = NumAtributos)
  end;
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
  Combo: TcxImageComboBox;
  Col: TcxGridDBColumn;
  ColProps: TcxImageComboBoxProperties;
  CodArt: string;
  ColItems: Integer;
begin
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) and (AItem is TcxGridDBColumn) then
  begin
    Combo := TcxImageComboBox(AEdit);
    Combo.Tag := AItem.Tag;
    Combo.OnEnter := nil;
    // Acceder a Properties via la columna (no via el editor). En esta version
    // de DevExpress, el editor recien creado puede no resolver Combo.Properties
    // sin AV. La columna ya tiene Properties asignadas desde
    // ConstruirColumnasDinamicas.
    Col := TcxGridDBColumn(AItem);
    if not (Col.Properties is TcxImageComboBoxProperties) then Exit;
    ColProps := TcxImageComboBoxProperties(Col.Properties);
    ColProps.OnEditValueChanged := OnAtributoChanged;

    // Repoblamos Items SIEMPRE al entrar a la celda. La optimizacion previa
    // (solo si Items.Count = 0) dependia de leer Combo.Properties que AV-ea,
    // dejando Items vacios. Coste: 1 query al cambiar de celda; aceptable.
    if DatosCaja.cdsLineas.Active then
      CodArt := DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_ART_FACLIN').AsString
    else
      CodArt := '';
    if CodArt <> '' then
      PoblarItemsAtributoCol(AItem.Tag, CodArt);
    ColItems := ColProps.Items.Count;

    // Nada de auto-seleccion (ItemIndex := 0 disparaba OnAtributoChanged sin
    // proteccion y bloqueaba el form). Si la celda esta vacia, cableamos
    // OnEnter por si la version dispara el evento al recibir foco; ademas,
    // EditKeyDown abrira el dropdown si el usuario pulsa Enter.
    if ColItems > 0 then
    begin
      var ValorActual := Sender.Controller.FocusedRecord.Values[AItem.Index];
      if VarIsNull(ValorActual) or (Trim(VarToStr(ValorActual)) = '') then
        Combo.OnEnter := ForzarDespliegue
      else
        Combo.OnEnter := nil;
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
    cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
    cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
  end;
  jvntrstb1.EnterAsTab := False;
end;

procedure TfrmMtoOpeCaja.cxGrid1Exit(Sender: TObject);
begin
  jvntrstb1.EnterAsTab := True;
end;

procedure TfrmMtoOpeCaja.actBuscarEmpleadosExecute(Sender: TObject);
var
  LCtrl: TWinControl;
  CodigoBuscado: string;
  CurrentItem: TcxCustomGridTableItem;
  CurrentEdit: TcxCustomEdit;
  Combo: TcxImageComboBox;
begin
  if cxGrid1DBTableView1.Controller.FocusedItem <> nil then
  if (cxGrid1DBTableView1.Controller.FocusedItem.Tag > 0) then
  begin
    CurrentItem := cxGrid1DBTableView1.Controller.FocusedItem;
    if dsLineas.DataSet.State = dsBrowse then
      dsLineas.DataSet.Edit;
    if not cxGrid1DBTableView1.Controller.EditingController.IsEditing then
    begin
      cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
    end;
    if cxGrid1DBTableView1.Controller.EditingController.IsEditing then
     begin
       CurrentEdit := cxGrid1DBTableView1.Controller.EditingController.Edit;
       if (CurrentEdit is TcxImageComboBox) then
       begin
         Combo := TcxImageComboBox(CurrentEdit);
         if Combo.Properties.Items.Count > 1 then
         begin
           if not Combo.DroppedDown then
             Combo.DroppedDown := True;
           Exit;
         end;
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
        cxGrid1.SetFocus;
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
            cxGrid1DBTableView1.Controller.FocusedColumn := PrimeraCol;
            cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
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
            cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
            cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
          end
          else
          begin
            // Si el parámetro está desactivado, el cajero decide. Lo normal es
            // dejarle en CANTIDAD_ARTVIN.
            // (Cambia 'tvCantidad' por el nombre real de tu columna de
            // cantidad_artvin)
            // cxGrid1DBTableView1.Controller.FocusedColumn := tvCantidad;
            // cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
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
    Layout.RestaurarAlturaPanel('StockPanelHeight', pnl1, 30);
    Layout.RestaurarGrid('Lineas', cxGrid1DBTableView1);
  finally
    Layout.Free;
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
  IdsVariaciones: TStringList;
begin
  // --- OPTIMIZACIÓN: Si es el mismo tipo de artículo, no repintamos ---
  if SameText(ArticuloPadre, FUltimoArticuloPadre) then Exit;
  FUltimoArticuloPadre := ArticuloPadre;

  NombresAtributos := TStringList.Create;
  IdsVariaciones  := TStringList.Create;
  try
    // Solo atacamos la base de datos si hay un artículo real
    if (ArticuloPadre <> '') and (ArticuloPadre <> 'ACUENTA') then
    begin
      datosCaja.qryDefinicionArticulo.Connection := oConn;
      datosCaja.qryDefinicionArticulo.Close;
      datosCaja.qryDefinicionArticulo.SQL.Text :=
      'SELECT DISTINCT  '        +
      '      N.ID_ATRIBUTO, '+
      '      N.NOMBRE_ATRIBUTO, '+
      '      N.ORDEN_VISUAL_ATRIBUTO      '+
      ' FROM fza_articulos_skus SKU '+
      ' JOIN fza_atributos_sku AT '+
      '   ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_UNIDAD_SKU_SA '+
      ' JOIN fza_atributos_valores V '+
      '   ON AT.ID_AV_SA = V.ID_AV'+
      ' JOIN vi_atributos_nombres N '+
      '   ON V.ID_VA_AV = N.ID_ATRIBUTO '+
      'WHERE SKU.CODIGO_ART_SKU = :ARTICULO '+
      'ORDER BY N.ORDEN_VISUAL_ATRIBUTO '+
      'LIMIT 5';
      datosCaja.qryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
        ArticuloPadre;
      datosCaja.qryDefinicionArticulo.Open;
      while not datosCaja.qryDefinicionArticulo.Eof do
      begin
        NombresAtributos.Add(datosCaja.qryDefinicionArticulo.FieldByName(
          'NOMBRE_ATRIBUTO').AsString);
        IdsVariaciones.Add(datosCaja.qryDefinicionArticulo.FieldByName(
          'ID_ATRIBUTO').AsString);
        datosCaja.qryDefinicionArticulo.Next;
      end;
    end;

    FNumAtributosActual := NombresAtributos.Count;

    // Solo tocamos la memoria del dataset si estamos escaneando algo nuevo
    if DatosCaja.cdsLineas.Active
       and (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
      DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := NombresAtributos.Count;

    cxGrid1DBTableView1.BeginUpdate;
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
            FIdVariacionPorTag[i] := IdsVariaciones[i-1];
            if DatosCaja.cdsLineas.Active
               and (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
              DatosCaja.cdsLineas.FieldByName('ATTR' + IntToStr(
                i) + '_NOMBRE').AsString := NombresAtributos[i-1];
            // Items + swatches deben estar listos AHORA: el cell display de
            // TcxImageComboBox necesita que Items contenga el valor del campo
            // para encontrar su Description y pintarlo. Si solo los rellenamos
            // en OnInitEdit, al salir del editor el combo no encuentra el item
            // y la celda se queda en blanco.
            PoblarItemsAtributoCol(i, ArticuloPadre);
          end
          else
          begin
            Col.Visible := False;
            Col.Options.Editing := False;
            Col.Caption := '-';
            FIdVariacionPorTag[i] := '';
            PoblarItemsAtributoCol(i, '');
          end;
        end;
      end;
    finally
      cxGrid1DBTableView1.EndUpdate;
    end;
  finally
    NombresAtributos.Free;
    IdsVariaciones.Free;
  end;
//  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.PoblarItemsAtributoCol(Tag: Integer;
                                                const ArticuloPadre: string);
var
  Col  : TcxGridDBColumn;
  Avs  : TList<string>;
  Av, IdVa : string;
  Item : TcxImageComboBoxItem;
  Idx  : Integer;
begin
  Col := ObtenerColumnaPorTag(Tag);
  if (Col = nil)
     or not (Col.Properties is TcxImageComboBoxProperties) then Exit;
  IdVa := FIdVariacionPorTag[Tag];
  Avs := TList<string>.Create;
  try
    if (ArticuloPadre <> '') and (ArticuloPadre <> 'ACUENTA') then
    begin
      with TUniQuery.Create(nil) do
      try
        Connection := oConn;
        SQL.Text :=
          '  SELECT DISTINCT V.AV                                         '+
          '    FROM fza_atributos_valores V                               '+
          '   INNER JOIN vi_atributos_nombres N                           '+
          '      ON V.ID_VA_AV = N.ID_ATRIBUTO                            '+
          '   INNER JOIN fza_atributos_sku REL                            '+
          '      ON V.ID_AV = REL.ID_AV_SA                                '+
          '   INNER JOIN fza_articulos_skus S                             '+
          '      ON REL.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU        '+
          '     AND S.CODIGO_ART_SKU = N.CODIGO_ART_PADRE_ARTVIN          '+
          '   WHERE N.CODIGO_ART_PADRE_ARTVIN = :PADRE                    '+
          '     AND N.ORDEN_VISUAL_ATRIBUTO   = :ORDEN                    '+
          '   ORDER BY V.AV                                               ';
        ParamByName('PADRE').AsString := ArticuloPadre;
        ParamByName('ORDEN').AsInteger := Tag;
        Open;
        while not Eof do
        begin
          Avs.Add(FieldByName('AV').AsString);
          Next;
        end;
      finally
        Free;
      end;
    end;
    RellenarImageListPaleta(FImagesPorTag[Tag], IdVa,
                            Avs.ToArray, FAvToIndexPorTag[Tag]);
    with TcxImageComboBoxProperties(Col.Properties) do
    begin
      Items.BeginUpdate;
      try
        Items.Clear;
        for Av in Avs do
        begin
          Item := TcxImageComboBoxItem(Items.Add);
          Item.Description := Av;
          Item.Value       := Av;
          if FAvToIndexPorTag[Tag].TryGetValue(UpperCase(Trim(Av)), Idx) then
            Item.ImageIndex := Idx
          else
            Item.ImageIndex := -1;
        end;
      finally
        Items.EndUpdate;
      end;
    end;
  finally
    Avs.Free;
  end;
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
          cxGrid1DBTableView1.BeginUpdate;
          FActualizandoDepositos := True;
          try
            if oCajaParams.GetBool('vgerAutoLoadDepositos', False) then
              DatosCaja.CargarDepositosCliente(sCodigo);
          finally
            cxGrid1DBTableView1.EndUpdate;
            FActualizandoDepositos := False;
          end;
        end;
      end;
    finally
      unqry.Free;
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
    cxGrid1DBTableView1.DataController.UpdateItems(False);

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
      Totales.Free;
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
    if cxGrid1.CanFocus then
      cxGrid1.SetFocus;
    cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
//    cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
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
      formulario.dsTablaG.DataSet.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
      if formulario.sFicha = 'S' then
      begin
        btnCodigoCliente.Text := unqryClientes.FieldByName('Código').AsString;
        if btnCodigoCliente.ValidateEdit(True) then
        begin
          cxGrid1.SetFocus;
        end;
      end;
    finally
      formulario.dsTablaG.DataSet.Close;
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
    qry.SQL.Text := 'SELECT CODIGO_EMPLEADO_USU, DIMINUTIVO_TICKET_USU ' +
                    '  FROM fza_usuarios ' +
                    ' WHERE ESACTIVO_USU = ''S'' ' +
                    '   AND CODIGO_EMPLEADO_USU IS NOT NULL ';
    if Trim(sCodigo) <> '' then
    begin
      qry.SQL.Add(
        'AND (CODIGO_EMPLEADO_USU LIKE :TOKEN OR DIMINUTIVO_TICKET_USU LIKE ' +
        ':TOKEN) ');
      qry.ParamByName('TOKEN').AsString := '%' + sCodigo + '%';
    end;
    qry.SQL.Add('ORDER BY CODIGO_EMPLEADO_USU ASC LIMIT 1');
    qry.Open;
    if not qry.IsEmpty then
    begin
      sCodigo := qry.FieldByName('CODIGO_EMPLEADO_USU').AsString;
      sNomEmpleado := qry.FieldByName('DIMINUTIVO_TICKET_USU').AsString;
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
    qry.Free;
  end;
//  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
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
  SerieGenerada: string;
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
//  if DatosCaja.cdsLineas.IsEmpty then
//  begin
//    ShowMessage('No hay líneas en la venta para cobrar.');
//    Exit;
//  end;
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
                                              frmFaseCobro.cbbSerie1.Text,
                                              frmFaseCobro.DatosCobro,
                                              frmFaseCobro.cbbSerie1.Text,
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
      frmFaseCobro.Free;
    ObjTotales.Free;
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
  if (cxGrid1DBTableView1.Controller.EditingController <> nil) and
     cxGrid1DBTableView1.Controller.EditingController.IsEditing then
  begin
    cxGrid1DBTableView1.Controller.EditingController.HideEdit(False);
  end;
  // 2. Cancelar línea a medias si la hubiera
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
    DatosCaja.cdsLineas.Cancel;
  // 3. Limpieza y carga de depósitos de forma silenciosa
  DatosCaja.cdsLineas.DisableControls;
  cxGrid1DBTableView1.BeginUpdate;
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
    cxGrid1DBTableView1.EndUpdate;
    FActualizandoDepositos := False;
  end;
  cxGrid1DBTableView1.DataController.UpdateItems(False);
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
    Totales.Free;
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
  unqryEmpleados.Connection := oConn;
  unqryEmpleados.SQL.Text := 'SELECT CODIGO_EMPLEADO_USU ' +
                                                    'as `Código de Empleado`,' +
                             '       DIMINUTIVO_TICKET_USU ' +
                                                     'as `Nombre de Empleado`' +
                             '  FROM fza_usuarios ' +
                             ' WHERE ESACTIVO_USU =' +QuotedStr('S') +
                             '   AND CODIGO_EMPLEADO_USU IS NOT NULL' +
                             ' ORDER BY CODIGO_EMPLEADO_USU ';
  formulario := TfrmMtoSearch.Create(nil);
  formulario.Name := 'frmMtoEmpCajSearch';
  formulario.Caption := 'Búsqueda de Empleados en Caja';
  try
    formulario.dsTablaG.DataSet := unqryEmpleados;
    formulario.dsTablaG.DataSet.Open;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
  finally
      inherited;
      if formulario.sFicha = 'S' then
      begin
        btnCodigoEmpleado.Text := unqryEmpleados.Fields[0].AsString;
        if btnCodigoEmpleado.ValidateEdit(True) then
        begin
          btnCodigoCliente.SetFocus;
        end;
      end;
      formulario.dsTablaG.DataSet.Close;
      FreeAndNil(unqryEmpleados);
      FreeAndNil(formulario);
  end;
end;

procedure TfrmMtoOpeCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMtoOpeCaja.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  FAtributosStock.Free;
  for i := 1 to 5 do
  begin
    FAvToIndexPorTag[i].Free;
    // FImagesPorTag[i] tiene Owner=Self, lo libera la VCL al destruir el form.
  end;
end;

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  DatosCaja := TdmCajaOpe.Create(Self);
  FAtributosStock := TDictionary<string, string>.Create;
  for i := 1 to 5 do
  begin
    FImagesPorTag[i]    := TImageList.Create(Self);
    FAvToIndexPorTag[i] := TDictionary<string, Integer>.Create;
  end;
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := DatosCaja.qryStock;
  ConstruirColumnasDinamicas;
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
  DatosCaja.OnRellenarArticulo  := RellenarDatosArticuloEnDataset;
  DatosCaja.OnRellenarAtributos := RellenarAtributosDesdeSku;
  tvEmpleado.Visible      := oCajaParams.GetBool('vgerShowEmpleadoLinea', True);
  var PermiteDescuentos := oCajaParams.GetBool('vgerDescuentos', True);
  tvDescuento.Options.Editing := PermiteDescuentos;
  tvDescuentoMenos.Options.Editing := PermiteDescuentos;
  with dbtvBusqDBTableView1.DataController do
  begin
    DataModeController.GridMode := True;
    DataModeController.SyncMode := False;
    Filter.AutoDataSetFilter := False;
    Options := Options - [dcoImmediatePost, dcoGroupsAlwaysExpanded];
  end;
  with dbtvBusqDBTableView1.OptionsBehavior do
  begin
    IncSearch := False;
    IncSearchItem := nil;
  end;
  repSoloTexto.Properties.OnValidate := tvArticuloPropertiesValidate;
  repComboBox.Properties.OnCloseUp   := tvArticuloPropertiesCloseUp;
end;

procedure TfrmMtoOpeCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F5) then
    btnF5.Click;
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
//var
//  sCodEmpleado: string;
//begin
//  // Tarifa por defecto en cabecera
//  if DatosCaja.cdsCabecera.State = dsBrowse then
//    DatosCaja.cdsCabecera.Edit;
//  DatosCaja.cdsCabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
//    oCajaParams.GetString('vgerDefTarifa', 'PVP');
//  lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
//                         'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
//
//  // Empleado por defecto
//  if oCajaParams.GetBool('vgerFillEmpleadoDefecto', False) then
//  begin
//    sCodEmpleado := oCajaParams.GetString('vgerCodEmpleadoDefecto', '');
//    if sCodEmpleado <> '' then
//    begin
//      btnCodigoEmpleado.Text := sCodEmpleado;
//      btnCodigoEmpleado.ValidateEdit(True);
//      btnCodigoCliente.SetFocus;
//      Exit;
//    end;
//  end;
//   btnCodigoEmpleado.SetFocus;
begin
  RestaurarLayoutCaja;
  ActualizarFoco;
end;

// Solo abre el desplegable; nunca tocar ItemIndex aqui (eso disparaba
// OnAtributoChanged sin contexto y bloqueaba el form).
procedure TfrmMtoOpeCaja.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxImageComboBox;
begin
  if Sender is TcxImageComboBox then
  begin
    Combo := TcxImageComboBox(Sender);
    if (Combo.Properties.Items.Count > 0) and not Combo.DroppedDown then
      Combo.DroppedDown := True;
    Combo.OnEnter := nil;
  end;
end;

procedure TfrmMtoOpeCaja.GuardarLayoutCaja;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(Self.Name);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('StockPanelHeight', pnl1);
    Layout.GuardarGrid('Lineas', cxGrid1DBTableView1);
    if Layout.PreguntarYGrabar('Personalización Caja') then
      ShowMessage('Layout guardado.');
  finally
    Layout.Free;
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
  for i:= 0 to cxGrid1DBTableView1.ColumnCount - 1 do
    if (cxGrid1DBTableView1.Columns[i].Tag = NumColumn) then
    begin
      Result := (cxGrid1DBTableView1.Columns[i] as TcxGridDBColumn);
      Exit;
    end;
end;

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  lblFechaCaja.Caption := FormatDateTime('hh:nn:ss dddd d mmmm yyyy', Now);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1CustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  IdVa, Texto : string;
  Info        : TInfoBasico;
  Val : Variant;
begin
  if (AViewInfo = nil) or (AViewInfo.Item = nil) then Exit;
  // Solo las columnas dinamicas de atributos (Tag 1..5) llevan cuadrado.
  if (AViewInfo.Item.Tag < 1) or (AViewInfo.Item.Tag > 5) then Exit;
  IdVa := FIdVariacionPorTag[AViewInfo.Item.Tag];
  if IdVa = '' then Exit;
  // Leemos el valor crudo del registro, no AViewInfo.Text: TcxImageComboBox
  // calcula Text matcheando Items, y si por timing aun no estan poblados Text
  // sale vacio y nos perdemos el repintado.
  if AViewInfo.GridRecord = nil then Exit;
  Val := AViewInfo.GridRecord.Values[AViewInfo.Item.Index];
  if VarIsNull(Val) then Exit;
  Texto := Trim(VarToStr(Val));
  if Texto = '' then Exit;
  if ObtenerInfoBasico(IdVa, Texto, Info) then
    if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, Texto) then
      ADone := True;
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1GetCellHint(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
var
  IdVa, Texto : string;
  Info        : TInfoBasico;
begin
  if (ACellViewInfo = nil) or (ACellViewInfo.Item = nil) then Exit;
  if (ACellViewInfo.Item.Tag < 1) or (ACellViewInfo.Item.Tag > 5) then Exit;
  IdVa := FIdVariacionPorTag[ACellViewInfo.Item.Tag];
  if IdVa = '' then Exit;
  Texto := Trim(ACellViewInfo.Text);
  if Texto = '' then Exit;
  if ObtenerInfoBasico(IdVa, Texto, Info) then
    AHintText := Info.Nombre;
end;

procedure TfrmMtoOpeCaja.dbtvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Info : TInfoBasico;
begin
  if (AViewInfo = nil) or (FAtributosStock = nil) then Exit;
  if FAtributosStock.Count = 0 then Exit;
  if BuscarInfoBasicoEnArticulo(AViewInfo.Text, FAtributosStock, Info) then
    if PintarCeldaConTextoColor(ACanvas, AViewInfo, Info) then
      ADone := True;
end;

procedure TfrmMtoOpeCaja.dbtvStockGetCellHint(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
var
  Info : TInfoBasico;
begin
  if (ACellViewInfo = nil) or (FAtributosStock = nil) then Exit;
  if FAtributosStock.Count = 0 then Exit;
  if BuscarInfoBasicoEnArticulo(ACellViewInfo.Text, FAtributosStock, Info) then
    AHintText := Info.Nombre;
end;

end.
