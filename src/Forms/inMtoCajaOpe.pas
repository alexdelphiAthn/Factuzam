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
  dxScrollbarAnnotations, Data.DB, cxDBData, cxClasses, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems, system.UITypes,
  System.Actions, Vcl.ActnList;

const
  WM_CANCELAR_LINEA = WM_USER + 100;
  WM_SALTAR_ATRIBUTO = WM_USER + 101;
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
  inLibShowMto, inMtoPrincipal,
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
  end;
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
        Result := False;
        Exit;
      end;
    finally
      FreeAndNil(qry);
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
             tvLineasOpe,
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
        tvLineasOpe.Controller.FocusedColumn := tvArticulo;
        tvLineasOpe.Controller.EditingController.ShowEdit;
        if tvLineasOpe.Controller.EditingController.IsEditing then
        begin
          tvLineasOpe.Controller.EditingController.Edit.EditValue :=
                                                                    FScanBuffer;
          tvLineasOpe.Controller.EditingController.Edit.PostEditValue;
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
begin
  var unstrdprcCon := TUniStoredProc.Create(nil);
  try
    unstrdprcCon.Connection := oConn;
    unstrdprcCon.StoredProcName := 'PRC_BUSQUEDA_ARTICULOS';
    unstrdprcCon.PrepareSQL;

    unstrdprcCon.ParamByName('p_tarifa').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    unstrdprcCon.ParamByName('p_almacen').AsString  := FCodigoAlmacen;
    unstrdprcCon.ParamByName('p_fecha').AsDate      := FFecha;
    unstrdprcCon.ParamByName('p_token').AsString    := '';
    unstrdprcCon.ParamByName('p_solostock').AsInteger :=
                       Ord(oCajaParams.GetBool('vgerBusqArtStockOnly',  False));
    unstrdprcCon.ParamByName('p_solotarifa').AsInteger :=
                       Ord(oCajaParams.GetBool('vgerBusqArtTarifaOnly', False));
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Caja',
                                       unstrdprcCon,
                                       'frmMtoArtFacSearch') then
      Result := unstrdprcCon.FieldByName('CODIGO_ART_ART').AsString
    else
      Result := '';
  finally
    FreeAndNil(unstrdprcCon);
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
                 tvLineasOpe,
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
      GridRecalc(nil, tvLineasOpe, DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    FreeAndNil(Validador);
    FreeAndNil(Resolver);
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
    FreeAndNil(Lookup);
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
      Col.PropertiesClass := TcxComboBoxProperties;
      with TcxComboBoxProperties(Col.Properties) do
      begin
        DropDownListStyle := lsFixedList;
        OnEditValueChanged := OnAtributoChanged;
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
  Combo: TcxComboBox;
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
  if (AItem.Tag > 0) and (AEdit is TcxComboBox) then
  begin
    Combo := TcxComboBox(AEdit);
    if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') then
    begin
      if Combo.Properties.Items.Count > 0 then
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
    // HideEdit SOLO aquí, cuando el combo ya está cerrado y tiene valor
    tvLineasOpe.Controller.EditingController.HideEdit(True);
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
          tvLineasOpe.Controller.FocusedColumn := tvArticulo;
          tvLineasOpe.Controller.EditingController.ShowEdit;
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
          tvLineasOpe.Controller.FocusedColumn := tvArticulo;
          tvLineasOpe.Controller.EditingController.ShowEdit;
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
        tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      end
      else
      begin
        // El parámetro indica quedarse: Movemos el foco a la descripción
        tvLineasOpe.Controller.FocusedColumn := tvDescripcion;
      end;

      tvLineasOpe.Controller.EditingController.ShowEdit;
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
  Combo: TcxComboBox;
  OrdenColumna: Integer;
  ArticuloPadre: string;
begin
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) then
  begin
    Combo := TcxComboBox(AEdit);
    Combo.Tag := AItem.Tag;
    Combo.Properties.OnEditValueChanged := OnAtributoChanged;
    Combo.OnEnter := nil;
    OrdenColumna := AItem.Tag;
    if DatosCaja.cdsLineas.Active then
      ArticuloPadre := DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_ART_FACLIN').AsString
    else
      ArticuloPadre := '';
    with TUniQuery.Create(nil) do
    try
      Connection := oConn;
      SQL.Text :=
          '  SELECT DISTINCT V.AV                         '+
          '    FROM fza_atributos_valores V                          '+
          '   INNER JOIN vi_atributos_nombres N                     '+
          '      ON V.ID_VA_AV = N.ID_ATRIBUTO                      '+
          '   INNER JOIN fza_atributos_sku REL                      '+
          '      ON V.ID_AV = REL.ID_AV_SA                 '+
          '   INNER JOIN fza_articulos_skus S                       '+
          '      ON REL.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU      '+
          '     AND S.CODIGO_ART_SKU = N.CODIGO_ART_PADRE_ARTVIN '+
          '   WHERE N.CODIGO_ART_PADRE_ARTVIN = :PADRE               '+
          '     AND N.ORDEN_VISUAL_ATRIBUTO = :ORDEN       '+
          '   ORDER BY V.AV                                   ';
      ParamByName('PADRE').AsString := ArticuloPadre;
      ParamByName('ORDEN').AsInteger := OrdenColumna;
      Open;
      Combo.Properties.Items.BeginUpdate;
      try
        Combo.Properties.Items.Clear;
        while not Eof do
        begin
          Combo.Properties.Items.Add(FieldByName('AV').AsString);
          Next;
        end;
      finally
        Combo.Properties.Items.EndUpdate;
      end;
    finally
      Free;
    end;
    if Combo.Properties.Items.Count > 1 then
    begin
      var ValorActual := Sender.Controller.FocusedRecord.Values[AItem.Index];
      if VarIsNull(ValorActual) or (Trim(VarToStr(ValorActual)) = '') then
      begin
        // CAMBIO 8: ForzarDespliegue usa FInicializandoCombo para no disparar
        // OnAtributoChanged al asignar ItemIndex := 0
        Combo.OnEnter := ForzarDespliegue;
        Combo.ItemIndex := 0;
      end
      else
      begin
        Combo.OnEnter := nil;
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
  Combo: TcxComboBox;
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
       if (CurrentEdit is TcxComboBox) then
       begin
         Combo := TcxComboBox(CurrentEdit);
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
begin
  // --- OPTIMIZACIÓN: Si es el mismo tipo de artículo, no repintamos ---
  if SameText(ArticuloPadre, FUltimoArticuloPadre) then Exit;
  FUltimoArticuloPadre := ArticuloPadre;

  NombresAtributos := TStringList.Create;
  try
    // Solo atacamos la base de datos si hay un artículo real
    if (ArticuloPadre <> '') and (ArticuloPadre <> 'ACUENTA') then
    begin
      datosCaja.qryDefinicionArticulo.Connection := oConn;
      datosCaja.qryDefinicionArticulo.Close;
      datosCaja.qryDefinicionArticulo.SQL.Text :=
      'SELECT DISTINCT  '        +
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
        datosCaja.qryDefinicionArticulo.Next;
      end;
    end;

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
  finally
    FreeAndNil(NombresAtributos);
  end;
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
      formulario.dsTablaG.DataSet.Open;
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

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
begin
  inherited;
  DatosCaja := TdmCajaOpe.Create(Self);
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
begin
  if (Key = VK_F5) then
    btnF5.Click;
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  RestaurarLayoutCaja;
  ActualizarFoco;
end;

// CAMBIO 10: ForzarDespliegue usa FInicializandoCombo para proteger
// OnAtributoChanged
procedure TfrmMtoOpeCaja.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxComboBox;
begin
  if Sender is TcxComboBox then
  begin
    Combo := TcxComboBox(Sender);
    // Asignar ItemIndex protegido para que OnAtributoChanged no recalcule el
    // precio
    // con un SKU incompleto (todavía falta confirmar este atributo)
    FInicializandoCombo := True;
    try
      Combo.ItemIndex := 0;
    finally
      FInicializandoCombo := False;
    end;
    if not Combo.DroppedDown then
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
    Layout.GuardarAlturaPanel('StockPanelHeight', pnlBusqueda);
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
