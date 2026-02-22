unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inMtoGenSearch,
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
  private
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
    procedure BuscarEmpleados;
    procedure BuscarClientes;
  public
    DatosCaja: TdmCajaOpe;
//    procedure PrepararValores(AEmpresa, AAlmacen, ACaja: string;
//                              AFecha: TDateTime);
  private
    FScanBuffer: string;
    FLeyendoScanner: Boolean;
    FCodigoEmpresa:String;
    FCodigoAlmacen, FCodigoCaja:String;
    FFecha:TDate;
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
  inMtoCajaMenu, inLibGlobalVar, inMtoCajaFaseCobro, inLibDevExp, inLibtb,
  inLibFacturas, inLibGenBusq;

procedure TfrmMtoOpeCaja.PrepararValores(AEmpresa, AAlmacen, ACaja: string;
                                         AFecha: TDateTime);
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FCodigoCaja    := ACaja;
  FFecha         := AFecha;
  if Assigned(DatosCaja) then
  begin
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime := FFecha;
    AplicarValoresPorDefecto(DatosCaja.cdsCabecera, 'fza_facturas');
    DatosCaja.cdsCabecera.FieldByName('CODIGO_EMPRESA_FACTURA').AsString :=
                                                                 FCodigoEmpresa;
    DatosCaja.cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime := FFecha;
   DatosCaja.cdsCabecera.FieldByName('TIPO_FACTURA').AsString := 'SIMPLIFICADA';

  end;
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

procedure TfrmMtoOpeCaja.txtEntradaArticuloKeyPress(Sender: TObject;
                                                    var Key: Char);
begin
  if Key = #2 then
  begin
    FLeyendoScanner := True;
    FScanBuffer := '';
    Key := #0;
    Exit;
  end;
  if FLeyendoScanner then
  begin
    if Key = #3 then
    begin
      FLeyendoScanner := False;
      Key := #0;
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
begin
  if (DatosCaja.cdsLineas.Active) then
  begin
    if (DatosCaja.cdsLineas.State = dsInsert) then
      DatosCaja.cdsLineas.Cancel
    else if not DatosCaja.cdsLineas.IsEmpty then
      DatosCaja.cdsLineas.Delete;
    GridRecalc(nil,
               cxGrid1DBTableView1,
               DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera,
               ActualizarLabelTotal);
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

function TfrmMtoOpeCaja.BuscarArticulo:String;
begin
  var unqryCon:TUniQuery := TUniQuery.Create(nil);
  try
    unqryCon.Connection := oConn;
    unqryCon.SQL.Text := 'SELECT * ' +
                         '  FROM vi_art_busquedas ' +
                         ' WHERE (codigo_tarifa = :TARIFA' +
                         '    OR codigo_tarifa is null) ' +
                         '   AND FECHA_DESDE_TARIFA < :FECHA ' +
                         '   AND (FECHA_HASTA_TARIFA IS NULL ' +
                         '        OR FECHA_HASTA_TARIFA > :FECHA)';
    unqryCon.ParamByName('TARIFA').AsString :=
                                              DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
    unqryCon.PArambyName('FECHA').AsDateTime := FFecha;
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos en Caja',
                                       unqryCon,
                                       'frmMtoArtFacSearch')
                                     then
      Result := unqryCon.FieldByName('CODIGO_ARTICULO').AsString
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
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACTURA_LINEA').AsString;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    if (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
    begin
      DatosCaja.cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency := 0;
      GridRecalc(nil, cxGrid1DBTableView1, DatosCaja.cdsLineas, DatosCaja.cdsCabecera, ActualizarLabelTotal);
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

procedure TfrmMtoOpeCaja.
                    tvDescuentoMenosPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesEditValueChanged(Sender: TObject);
begin
  GridRecalc(Sender,
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
begin
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

function TfrmMtoOpeCaja.RellenarDatosArticuloEnDataset(Codigo: string): Boolean;
var
  Qry: TUniQuery;
  CodigoLimpio, SkuDetectado, CodigoPadre: string;
  sql: TUniQuery;
begin
  Result := False;
  CodigoLimpio := UpperCase(Trim(Codigo));
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := 'SELECT * ' +
                    '  FROM vi_caja_busqueda_unificada ' +
                    ' WHERE (INPUT_BUSQUEDA = :COD) ' +
                    '    OR (CODIGO_SKU = :COD) ' +
                    '    OR (CODIGO_PADRE = :COD) ' +
                    ' LIMIT 1';
    Qry.ParamByName('COD').AsString := CodigoLimpio;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      SkuDetectado := Qry.FieldByName('CODIGO_SKU').AsString;
      CodigoPadre := Qry.FieldByName('CODIGO_PADRE').AsString;
      with DatosCaja.cdsLineas do
      begin
        if State = dsBrowse then Edit;
        FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString :=
                               Qry.FieldByName('DESCRIPCION_ARTICULO').AsString;
        FieldByName('TIPO_ARTICULO_FACTURA_LINEA').AsString :=
                                      Qry.FieldByName('TIPO_ARTICULO').AsString;
        FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString := CodigoPadre;
      end;
      if SkuDetectado <> '' then
      begin
        ConsultarStock(SkuDetectado);
        DatosCaja.cdsLineas.FieldByName(
                        'CODIGO_UNIDAD_FACTURA_LINEA').AsString := SkuDetectado;
        RecalcularPrecioDesdeSku(SkuDetectado);
        Result := True;
      end
      else if CodigoPadre <> '' then
      begin
        ConsultarStock(CodigoPadre);
        DatosCaja.cdsLineas.FieldByName(
                         'CODIGO_UNIDAD_FACTURA_LINEA').AsString := CodigoPadre;
        sql := TUniQuery.Create(nil);
        try
          sql.Connection := oConn;
          sql.SQL.Text := 'SELECT PRECIOSALIDA_TARIFA, ' +
                          '       ESIMP_INCL_TARIFA, ' +
                          '       TIPO_IVA_ARTICULO, ' +
                          '       PORCEN_DTO_TARIFA, ' +
                          '       NUM_ATRIBUTOS_REQ    ' +
                          '  FROM vi_articulos_tarifas ' +
                          ' WHERE CODIGO_TARIFA = :CODTARIFA ' +
                          '   AND CODIGO_ARTICULO_TARIFA = :CODIGOARTICULO ' +
                          ' LIMIT 1';
          sql.ParamByName('CODTARIFA').AsString :=
               DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
          sql.ParamByName('CODIGOARTICULO').AsString := CodigoPadre;
          sql.Open;
          if not sql.IsEmpty then
          begin
             var NumAtributosReq :=
                                 sql.FieldByName('NUM_ATRIBUTOS_REQ').AsInteger;
             DatosCaja.cdsLineas.FieldByName(
                                 'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger :=
                                                                NumAtributosReq;
             DatosCaja.cdsLineas.FieldByName(
                                  'TIPOIVA_ARTICULO_FACTURA_LINEA').AsString :=
                                  sql.FieldByName('TIPO_IVA_ARTICULO').AsString;
             DatosCaja.cdsLineas.FieldByName(
                                  'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString :=
                                  sql.FieldByName('ESIMP_INCL_TARIFA').AsString;
              if NumAtributosReq = 0 then
                DatosCaja.cdsLineas.FieldByName(
                                     'PRECIOSALIDA_FACTURA_LINEA').AsCurrency :=
                              sql.FieldByName('PRECIOSALIDA_TARIFA').AsCurrency;
             if not sql.FieldByName('PORCEN_DTO_TARIFA').IsNull then
                DatosCaja.cdsLineas.FieldByName(
                                          'PORCEN_DTO_FACTURA_LINEA').AsFloat :=
                                   sql.FieldByName('PORCEN_DTO_TARIFA').AsFloat;
          end
          else
          begin
             DatosCaja.cdsLineas.FieldByName(
                                  'PRECIOSALIDA_FACTURA_LINEA').AsCurrency := 0;
          end;
          DatosCaja.cdsLineas.FieldByName(
                                      'CANTIDAD_FACTURA_LINEA').AsCurrency := 1;
          GridRecalc(nil,
                     cxGrid1DBTableView1,
                     DatosCaja.cdsLineas,
                     DatosCaja.cdsCabecera,
                     ActualizarLabelTotal);
        finally
          sql.Free;
        end;
        Result := True;
      end;
    end;
  finally
    Qry.Free;
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
  qry: TUniQuery;
  CodTarifa: string;
begin
  if Trim(sSKU) = '' then Exit;
  CodTarifa := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'SELECT * ' +
                    '  FROM vi_caja_tarifa_sku_articulos ' +
                    ' WHERE CODIGO_TARIFA = :TARIFA ' +
                    '   AND CODIGO_UNIDAD_TARIFA = :SKU ' +
                    ' LIMIT 1';
    qry.ParamByName('TARIFA').AsString := CodTarifa;
    qry.ParamByName('SKU').AsString := sSKU;
    qry.Open;
    if not qry.IsEmpty then
    begin
      DatosCaja.cdsLineas.FieldByName(
                                  'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString :=
                                qry.FieldByName('ESIMP_INCL_TARIFA').AsString;
      DatosCaja.cdsLineas.FieldByName(
                                     'PRECIOSALIDA_FACTURA_LINEA').AsCurrency :=
                             qry.FieldByName('PRECIOSALIDA_TARIFA').AsCurrency;
      DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsCurrency := 1;
      GridRecalc(nil,
             cxGrid1DBTableView1,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal );
    end;
  finally
    qry.Free;
  end;
end;

procedure TfrmMtoOpeCaja.RellenarAtributosDesdeSku(Sku: string);
var
  Qry: TUniQuery;
  i: Integer;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text := 'SELECT DISTINCT N.ORDEN_VISUAL_ATRIBUTO, ' +
                    '                V.VALOR_AV ' +
                    '  FROM fza_atributos_sku REL ' +
                    '  JOIN fza_atributos_valores V ' +
                    '    ON REL.ID_VALOR_SA = V.ID_VALOR_AV ' +
                    '  JOIN vi_atributos_nombres N ' +
                    '    ON V.ID_VA_AV = N.ID_ATRIBUTO ' +
                    ' WHERE REL.CODIGO_UNIDAD_SA = :SKU ' +
                    ' ORDER BY N.ORDEN_VISUAL_ATRIBUTO';
    Qry.ParamByName('SKU').AsString := Sku;
    Qry.Open;
    DatosCaja.cdsLineas.Edit;
    var NumAtributosReq :=
      DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    while (not Qry.Eof) do
    begin
      i := Qry.FieldByName('ORDEN_VISUAL_ATRIBUTO').AsInteger;
      if (i >= 1) and (i <= NumAtributosReq) then
        DatosCaja.cdsLineas.FieldByName('ATTR' + IntToStr(i) +
                     '_VALOR').AsString := Qry.FieldByName('VALOR_AV').AsString;
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TfrmMtoOpeCaja.ConsolidarSiExiste(SkuBuscado: string): Boolean;
var
  Clon: TClientDataSet;
  OldQty, NewQty: Double;
  OldTotal, OldBase: Currency;
  Factor: Double;
begin
  Result := False;
  if Trim(SkuBuscado) = '' then Exit;
  Clon := TClientDataSet.Create(nil);
  try
    Clon.CloneCursor(DatosCaja.cdsLineas, True);
    Clon.First;
    while not Clon.Eof do
    begin
      if (Clon.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString = SkuBuscado)
         and (Clon.RecNo <> DatosCaja.cdsLineas.RecNo) then
      begin
        Clon.Edit;
        OldQty := Clon.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat;
        OldTotal := Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
        OldBase  := Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
        NewQty := OldQty + 1;
        Clon.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat := NewQty;
        if OldQty <> 0 then
        begin
          Factor := NewQty / OldQty;
          Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency :=
                                                              OldTotal * Factor;
          Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency :=
                                                               OldBase * Factor;
        end
        else
        begin
          Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency :=
                Clon.FieldByName(
                 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency * NewQty;
          Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency :=
                Clon.FieldByName(
                 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency * NewQty;
        end;
        Clon.Post;
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
      Col.PropertiesClass := TcxComboBoxProperties;
      with TcxComboBoxProperties(Col.Properties) do
      begin
        DropDownListStyle := lsFixedList;
        ImmediatePost := True;
        OnEditValueChanged := OnAtributoChanged;
      end;
      Col.Index := IndiceBase + i;
    end;
  finally
    cxGrid1DBTableView1.EndUpdate;
  end;
end;

procedure TfrmMtoOpeCaja.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  SkuNuevo: string;
begin
  Edit := Sender as TcxCustomEdit;
  if not DatosCaja.cdsLineas.Active then Exit;
  Edit.PostEditValue;
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
     SkuNuevo := DatosCaja.GenerarSkuFinal(
        DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_ARTICULO_FACTURA_LINEA').AsString
     );
     DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString :=
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
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
    end
    else
    begin
      SkuActual := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACTURA_LINEA').AsString;
      if SkuActual = '' then
         SkuActual := CodArticulo;
      if ConsolidarSiExiste(SkuActual) then
      begin
        DatosCaja.cdsLineas.Cancel;
      end;
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
    tmrBusq.Enabled := False; // Reset
    tmrBusq.Enabled := True;  // Start (Cuenta atrás de 500ms)
  end;
  if (Key = VK_UP) and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      Key := 0;
      Exit;
    end
    else
    begin
      try
        DatosCaja.cdsLineas.Post;
      except
        Key := 0;
        raise;
      end;
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
    AEdit.PostEditValue; // Guardamos valor
  if DatosCaja.cdsLineas.State = dsBrowse then
    DatosCaja.cdsLineas.Edit;
    var CodArticuloActual := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    ActualizarColumnasDinamicas(CodArticuloActual);
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    var SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACTURA_LINEA').AsString;
    if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodArticuloActual) then
    begin
       RellenarAtributosDesdeSku(SkuDetectado);
       DatosCaja.cdsLineas.Post;
       DatosCaja.cdsLineas.Append;
       cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
       cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
       Key := 0;
       Exit;
    end;
    if (NumAtributos = 0) then
    begin
       DatosCaja.cdsLineas.Post;
       DatosCaja.cdsLineas.Append;
       cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
       cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
       Key := 0;
       Exit; // SALIR
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
         Exit; // SALIR
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
    Combo.PostEditValue;
    if (VarIsNull(Combo.EditValue)) or
       (Trim(VarToStr(Combo.EditValue)) = '') then
    begin
       Key := 0;
       Exit;
    end;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    if (AItem.Tag = NumAtributos) then
    begin
       EstabaInsertando := (DatosCaja.cdsLineas.State = dsInsert);
       SkuNuevo := DatosCaja.GenerarSkuFinal( DatosCaja.cdsLineas.FieldByName(
                                     'CODIGO_ARTICULO_FACTURA_LINEA').AsString);
       if not (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
        begin
          DatosCaja.cdsLineas.Edit;
        end;
       DatosCaja.cdsLineas.FieldByName(
                            'CODIGO_UNIDAD_FACTURA_LINEA').AsString := SkuNuevo;
       RecalcularPrecioDesdeSku(SkuNuevo);
       ConsultarStock(SkuNuevo);
       if EstabaInsertando and ConsolidarSiExiste(SkuNuevo) then
       begin
          DatosCaja.cdsLineas.Cancel;
          DatosCaja.cdsLineas.Append;
          cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
          cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
          Key := 0;
          Exit;
       end;
       if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Post;
       if EstabaInsertando then
       begin
          DatosCaja.cdsLineas.Append;
          cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
       end
       else
       begin
          cxGrid1DBTableView1.Controller.FocusedColumn := tvDescripcion;
       end;
       cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
       Key := 0;
    end;
  end;
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
                                       'CODIGO_ARTICULO_FACTURA_LINEA').AsString
    else
      ArticuloPadre := '';
    with TUniQuery.Create(nil) do
    try
      Connection := oConn;
      SQL.Text :=
          '  SELECT DISTINCT V.VALOR_AV                         '+
          '    FROM fza_atributos_valores V                          '+
          '   INNER JOIN vi_atributos_nombres N                     '+
          '      ON V.ID_VA_AV = N.ID_ATRIBUTO                      '+
          '   INNER JOIN fza_atributos_sku REL                      '+
          '      ON V.ID_VALOR_AV = REL.ID_VALOR_SA                 '+
          '   INNER JOIN fza_articulos_skus S                       '+
          '      ON REL.CODIGO_UNIDAD_SA = S.CODIGO_UNIDAD_SKU      '+
          '     AND S.CODIGO_ARTICULO_SKU = N.CODIGO_ARTICULO_PADRE '+
          '   WHERE N.CODIGO_ARTICULO_PADRE = :PADRE               '+
          '     AND N.ORDEN_VISUAL_ATRIBUTO = :ORDEN       '+
          '   ORDER BY V.VALOR_AV                                   ';
      ParamByName('PADRE').AsString := ArticuloPadre;
      ParamByName('ORDEN').AsInteger := OrdenColumna;
      Open;
      Combo.Properties.Items.BeginUpdate;
      try
        Combo.Properties.Items.Clear;
        while not Eof do
        begin
          Combo.Properties.Items.Add(FieldByName('VALOR_AV').AsString);
          Next;
        end;
      finally
        Combo.Properties.Items.EndUpdate;
      end;
    finally
      Free;
    end;
    if Combo.Properties.Items.Count = 1 then
    begin
      Combo.ItemIndex := 0;
      Combo.DroppedDown := False;
    end
    else if Combo.Properties.Items.Count > 1 then
    begin
      Combo.OnEnter := ForzarDespliegue;
      Combo.ItemIndex := 0;
      Combo.DroppedDown := True;
    end;
  end;
if AItem = tvArticulo then
  begin
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
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      Key := 0;
      Exit;
    end
    else
    begin
      try
        DatosCaja.cdsLineas.Post;
      except
        Key := 0;
        raise;
      end;
    end;
  end;
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
begin
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
    // ⭐ Por defecto → Buscar Artículo
    CodigoBuscado := BuscarArticulo;

    if CodigoBuscado <> '' then
    begin
      // Asegurar que hay línea activa
      if DatosCaja.cdsLineas.State = dsBrowse then
      begin
        if DatosCaja.cdsLineas.IsEmpty then
          DatosCaja.cdsLineas.Append
        else
          DatosCaja.cdsLineas.Edit;
      end;

      // Rellenar datos
      if RellenarDatosArticuloEnDataset(CodigoBuscado) then
      begin
        var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                'CODIGO_ARTICULO_FACTURA_LINEA').AsString;

        ActualizarColumnasDinamicas(CodArticulo);

        var NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;

        cxGrid1.SetFocus;

        if NumAtributos > 0 then
        begin
          // Ir al primer atributo
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
          // Nueva línea
          DatosCaja.cdsLineas.Post;
          DatosCaja.cdsLineas.Append;
          cxGrid1DBTableView1.Controller.FocusedColumn := tvArticulo;
          cxGrid1DBTableView1.Controller.EditingController.ShowEdit;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.actCobroExecute(Sender: TObject);
begin
  btnF12Click(Sender);
end;

procedure TfrmMtoOpeCaja.actEliminarLineaExecute(Sender: TObject);
begin
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    DatosCaja.cdsLineas.Cancel
  else
    if DatosCaja.cdsLineas.State in [dsBrowse] then
      DatosCaja.cdsLineas.Delete;
end;

procedure TfrmMtoOpeCaja.actSalirExecute(Sender: TObject);
begin
  // Verificamos si el dataset está activo y tiene líneas (venta en curso)
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
  begin
    // HAY DATOS: Preguntamos confirmación
    if MessageDlg('Hay una venta en curso.' + sLineBreak +
                  '¿Desea BORRAR LA VENTA y salir?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      // Si el usuario dice SÍ, cancelamos cualquier edición pendiente para limpiar y cerramos
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;

      Close;
    end;
    // Si dice NO, la acción termina y no hace nada (se queda en la venta)
  end
  else
  begin
    // NO HAY DATOS: Cerramos directamente
    Close;
  end;
end;

procedure TfrmMtoOpeCaja.ActualizarColumnasDinamicas(ArticuloPadre: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
  NombresAtributos: TStringList;
begin
  if ArticuloPadre = '' then Exit;
  NombresAtributos := TStringList.Create;
  try
    datosCaja.qryDefinicionArticulo.Connection := oConn;
    datosCaja.qryDefinicionArticulo.Close;
    datosCaja.qryDefinicionArticulo.SQL.Text :=
    'SELECT DISTINCT  '        +
    '      N.NOMBRE_ATRIBUTO, '+
    '      N.ORDEN_VISUAL_ATRIBUTO      '+
    ' FROM fza_articulos_skus SKU '+
    ' JOIN fza_atributos_sku AT '+
    '   ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_UNIDAD_SA '+
    ' JOIN fza_atributos_valores V '+
    '   ON AT.ID_VALOR_SA = V.ID_VALOR_AV'+
    ' JOIN vi_atributos_nombres N '+
    '   ON V.ID_VA_AV = N.ID_ATRIBUTO '+
    'WHERE SKU.CODIGO_ARTICULO_SKU = :ARTICULO '+
    'ORDER BY N.ORDEN_VISUAL_ATRIBUTO '+
    'LIMIT 5';
    datosCaja.qryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
                                                                  ArticuloPadre;
    datosCaja.qryDefinicionArticulo.Open;
    while not datosCaja.qryDefinicionArticulo.Eof do
    begin
      NombresAtributos.Add(
       datosCaja.qryDefinicionArticulo.FieldByName('NOMBRE_ATRIBUTO').AsString);
      datosCaja.qryDefinicionArticulo.Next;
    end;
    if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      DatosCaja.cdsLineas.FieldByName(
         'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := NombresAtributos.Count;
    end
    else
    begin
      DatosCaja.cdsLineas.Edit;
      DatosCaja.cdsLineas.FieldByName(
         'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := NombresAtributos.Count;
    end;
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
            if datosCaja.cdsLineas.State in [dsEdit, dsInsert] then
              datosCaja.cdsLineas.FieldByName('ATTR' +
                     IntToStr(i) + '_NOMBRE').AsString := NombresAtributos[i-1];
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
      cxGrid1DBTableView1.EndUpdate;
    end;
  finally
    NombresAtributos.Free;
  end;
  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.ActualizarLabelTotal(Sender: TObject;
  NuevoTotal: Currency);
begin
  lblTotal.Caption := Format('Total %m', [NuevoTotal]);
end;

procedure TfrmMtoOpeCaja.btnCodigoClienteExit(Sender: TObject);
begin
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).ValidateEdit(True);
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomCliente: string;
  sCodigo: string;
begin
  sCodigo := VarToStr(DisplayValue);
  if Trim(sCodigo) = '' then
  begin
    lblNombreCliente.Caption := 'VENTA CONTADO';
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName(
                                  'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString :=
                                                     DatosCaja.GetTarifaDefault;
    DatosCaja.cdsCabecera.FieldByName(
                                'ESIMP_INCL_TARIFA_CLIENTE_FACTURA').AsString :=
                                                                            'S';
//    DatosCaja.cdsCabecera.FieldByName(
//                                'CODIGO_FORMA_PAGO_CLIENTE').AsString := 'CAJA';
    lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
    Error := False;
    Exit;
  end
  else
  begin
    var unqry := TUniQuery.Create(nil);
    try
      unqry.Connection := oConn;
      unqry.SQL.Text := 'SELECT RAZONSOCIAL_CLIENTE, ' +
                        '       TARIFA_ARTICULO_CLIENTE ' +
                        '  FROM fza_clientes ' +
                        ' WHERE CODIGO_CLIENTE = :COD';
      unqry.ParamByName('COD').AsString := sCodigo;
      unqry.Open;
      if not unqry.IsEmpty then
      begin
        DatosCaja.cdsCabecera.Edit;
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CLIENTE_FACTURA').AsString :=
                                                          btnCodigoCliente.Text;
        sNomCliente := unqry.FieldByName('RAZONSOCIAL_CLIENTE').AsString;
        DatosCaja.cdsCabecera.FieldByName(
                                  'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString :=
                          unqry.FieldByName('TARIFA_ARTICULO_CLIENTE').AsString;
        lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
      end;
    finally
      unqry.Free;
    end;
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
    unqryClientes.SQL.Text := 'SELECT CODIGO_CLIENTE as `Código`, ' +
                              '       RAZONSOCIAL_CLIENTE as `Razón Social`, ' +
                              '       NIF_CLIENTE as `NIF Cliente`, ' +
                              '       MOVIL_CLIENTE as `Teléfono Cliente`' +
                              '  FROM fza_clientes ' +
                              ' WHERE ACTIVO_CLIENTE = ' + QuotedStr('S') +
                              ' ORDER BY RAZONSOCIAL_CLIENTE';
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

//procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
//  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
//var
//  sNomEmpleado: string;
//  sCodigo: string;
//begin
//  sCodigo := VarToStr(DisplayValue);
//  if Trim(sCodigo) = '' then
//  begin
//    lblNombreEmpleado.Caption := '';
//    Error := True;
//    ErrorText := 'Debe haber un empleado en la venta';
//    Exit;
//  end;
//  if not DatosCaja.BuscarYMostrarNombre('EMPLEADOS', sCodigo, sNomEmpleado) then
//  begin
//    Error := True;
//    ErrorText := 'El código de empleado no existe.';
//    lblNombreEmpleado.Caption := '';
//  end
//  else
//  begin
//    Error := False; // Permite salir
//    lblNombreEmpleado.Caption := sNomEmpleado;
//    DatosCaja.cdsCabecera.Edit;
//    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString :=
//                                                         btnCodigoEmpleado.Text;
//    ErrorText := '';
//  end;
//  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
//end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomEmpleado: string;
  sCodigo: string;
  qry: TUniQuery;
begin
  sCodigo := VarToStr(DisplayValue);

  // 1. PRIMER INTENTO: Búsqueda exacta (Lógica original)
  // Si el usuario escribió un código correcto, usamos la función existente.
  if (Trim(sCodigo) <> '') and DatosCaja.BuscarYMostrarNombre('EMPLEADOS', sCodigo, sNomEmpleado) then
  begin
    Error := False;
    lblNombreEmpleado.Caption := sNomEmpleado;
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString := sCodigo;
    ErrorText := '';

    // Forzamos que se muestre el valor correctamente formateado
    DisplayValue := sCodigo;
    Exit;
  end;

  // 2. SEGUNDO INTENTO: Auto-seleccionar el primer empleado coincidente o el primero de la lista
  // Si llegamos aquí, el código no existe o está vacío. Vamos a buscar el "primero".
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn; // Usamos la conexión global definida en tu unit
    qry.SQL.Text := 'SELECT CODIGO_EMPLEADO_USUARIO, DIMINUTIVO_TICKET_USUARIO ' +
                    '  FROM fza_usuarios ' +
                    ' WHERE ACTIVO_USUARIO = ''S'' ' +
                    '   AND CODIGO_EMPLEADO_USUARIO IS NOT NULL ';

    // Si el usuario escribió algo parcial (ej: "JU"), buscamos parecidos.
    // Si está vacío, simplemente traerá el primero de toda la tabla.
    if Trim(sCodigo) <> '' then
    begin
      qry.SQL.Add('AND (CODIGO_EMPLEADO_USUARIO LIKE :TOKEN OR DIMINUTIVO_TICKET_USUARIO LIKE :TOKEN) ');
      qry.ParamByName('TOKEN').AsString := '%' + sCodigo + '%';
    end;

    // Ordenamos para asegurar que siempre salga "el primero" consistentemente
    qry.SQL.Add('ORDER BY CODIGO_EMPLEADO_USUARIO ASC LIMIT 1');

    qry.Open;

    if not qry.IsEmpty then
    begin
      // ¡ÉXITO! Encontramos un candidato
      sCodigo := qry.FieldByName('CODIGO_EMPLEADO_USUARIO').AsString;
      sNomEmpleado := qry.FieldByName('DIMINUTIVO_TICKET_USUARIO').AsString;

      // CAMBIAMOS el valor que el usuario escribió por el código real encontrado
      DisplayValue := sCodigo;

      // Actualizamos UI y Dataset
      lblNombreEmpleado.Caption := sNomEmpleado;
      DatosCaja.cdsCabecera.Edit;
      DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString := sCodigo;

      // IMPORTANTE: Decimos que NO hay error para que el foco pueda saltar al siguiente control
      Error := False;
      ErrorText := '';
    end
    else
    begin
      // FALLO TOTAL: No hay empleados en la BD o el filtro no trajo nada
      Error := True;
      ErrorText := 'No se encontró ningún empleado válido.';
      lblNombreEmpleado.Caption := '';
    end;

  finally
    qry.Free;
  end;

  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.btnF12Click(Sender: TObject);
var
  frmFaseCobro: TfrmMtoCajaFaseCobro;
  ObjTotales: TFacturaTotales;
begin
  // 1. GESTIÓN DE LÍNEA EN BLANCO O EDICIÓN PENDIENTE
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
  begin
    if DatosCaja.cdsLineas.State = dsInsert then
    begin
      if Trim(DatosCaja.cdsLineas.FieldByName(
                            'CODIGO_ARTICULO_FACTURA_LINEA').AsString) = '' then
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
  // 2. VALIDAR QUE HAYA ALGO QUE COBRAR
  if DatosCaja.cdsLineas.IsEmpty then
  begin
    ShowMessage('No hay líneas en la venta para cobrar.');
    Exit;
  end;
  frmFaseCobro := nil;
  try
    ObjTotales := TFacturaTotales.Create(DatosCaja.cdsCabecera,
                                          DatosCaja.cdsLineas);
    ObjTotales.ProcesarFacturaCompleta;

    frmFaseCobro := TfrmMtoCajaFaseCobro.Create(Self);

    frmFaseCobro.CargarDatosDesdeFactura(ObjTotales); // <--- NUEVA LLAMADA

      // Pasamos datos de cabecera estándar
  //    frmFaseCobro.SerieOperacion := DatosCaja.cdsCabecera.FieldByName('SERIE_FACTURA').AsString;
  //    frmFaseCobro.NumeroOperacion := DatosCaja.cdsCabecera.FieldByName('NRO_FACTURA').AsString;

    if frmFaseCobro.ShowModal = mrOk then
    begin
       // Procesar cobro...
    end;
  finally
    frmFaseCobro.Free;
    ObjTotales.Free;
  end;
end;

procedure TfrmMtoOpeCaja.btnF5Click(Sender: TObject);
var
  i: Integer;
  NextIndex: Integer;
  TargetForm: TfrmMtoOpeCaja;
  Found: Boolean;
  const MAX_OPERACIONES = 5; // Configura aquí tu límite
begin
  // 1. Calculamos cuál es el siguiente número de operación (Ticket)
  // Usamos 'Self.Tag' para guardar si somos la 1, la 2, etc.
  NextIndex := Self.Tag + 1;

  if NextIndex > MAX_OPERACIONES then
    NextIndex := 1; // Vuelta a empezar

  // 2. Buscamos si esa operación YA está abierta en memoria
  Found := False;
  TargetForm := nil;

  for i := 0 to Screen.FormCount - 1 do
  begin
    // Buscamos formularios de esta misma clase
    if Screen.Forms[i] is TfrmMtoOpeCaja then
    begin
      // Comprobamos si tiene el número que buscamos
      if Screen.Forms[i].Tag = NextIndex then
      begin
        TargetForm := TfrmMtoOpeCaja(Screen.Forms[i]);
        Found := True;
        Break;
      end;
    end;
  end;

  // 3. Si existe la traemos al frente, si no, la creamos
  if Found then
  begin
    TargetForm.Show;
    TargetForm.BringToFront;
    if TargetForm.WindowState = wsMinimized then
      TargetForm.WindowState := wsNormal;
  end
  else
  begin
    // CREAMOS UNA NUEVA INSTANCIA
    TargetForm := TfrmMtoOpeCaja.Create(Application);

    // Le asignamos su número de operación
    TargetForm.Tag := NextIndex;

    // Actualizamos el Caption para que el usuario sepa dónde está
    // Mantenemos el número de caja real (FCodigoCaja) fijo, pero cambiamos el número visual
    TargetForm.Caption := Format('Operación %d - (Caja Real %s)', [NextIndex, Self.FCodigoCaja]);

    // Pasamos los MISMOS datos de conexión de la caja actual (Empresa, Almacén, Caja)
    TargetForm.PrepararValores(Self.FCodigoEmpresa,
                               Self.FCodigoAlmacen,
                               Self.FCodigoCaja, // <--- OJO: La caja física NO cambia
                               Self.FFecha);

    TargetForm.Show;
  end;

  // 4. Ocultamos la actual para dar efecto de "cambio de canal"
  // No hacemos Close porque perderíamos la venta a medio hacer si volvemos a pasar por aquí.
  Self.Hide;
end;

procedure TfrmMtoOpeCaja.BuscarEmpleados;
var
  formulario : TfrmMtoSearch;
  unqryEmpleados:TUniQuery;
begin
  unqryEmpleados := TUniQuery.Create(nil);
  unqryEmpleados.Connection := oConn;
  unqryEmpleados.SQL.Text := 'SELECT CODIGO_EMPLEADO_USUARIO ' +
                                                    'as `Código de Empleado`,' +
                             '       DIMINUTIVO_TICKET_USUARIO ' +
                                                     'as `Nombre de Empleado`' +
                             '  FROM fza_usuarios ' +
                             ' WHERE ACTIVO_USUARIO =' +QuotedStr('S') +
                             '   AND CODIGO_EMPLEADO_USUARIO IS NOT NULL' +
                             ' ORDER BY CODIGO_EMPLEADO_USUARIO ';
  formulario := TfrmMtoSearch.Create(nil);
  formulario.Name := 'frmMtoEmpCajSearch';
  formulario.Caption := 'Búsqueda de Empleados en Caja';
  try
    formulario.dsTablaG.DataSet := unqryEmpleados;
    formulario.dsTablaG.DataSet.Open;
    formulario.ProcesarPerfiles;  //debe ir después de abrir el dataset
    formulario.ShowModal;
  finally
      inherited;
      if formulario.sFicha = 'S' then
      begin
        btnCodigoEmpleado.Text :=
                 unqryEmpleados.Fields[0].AsString;
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
  DatosCaja := TdmCajaOpe.Create(Self);
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := DatosCaja.qryStock;
  ConstruirColumnasDinamicas;
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
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
  repComboBox.Properties.OnCloseUp := tvArticuloPropertiesCloseUp;
end;

procedure TfrmMtoOpeCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if (Key = VK_F5) then
    btnF5.Click;
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  btnCodigoEmpleado.SetFocus;
end;

procedure TfrmMtoOpeCaja.ForzarDespliegue(Sender: TObject);
begin
  if Sender is TcxComboBox then
    TcxComboBox(Sender).DroppedDown := True;
end;

function TfrmMtoOpeCaja.IntentarCerrar: Boolean;
begin
  Result := True; // Por defecto asumimos que se puede cerrar
  // 1. Si el formulario ya se está destruyendo, no hacemos nada
  if (csDestroying in ComponentState) then Exit;
  // 2. Verificamos si hay datos en la venta
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
  begin
    // IMPORTANTE: Como con F5 ocultamos la ventana (Hide),
    // hay que mostrarla para que el usuario vea qué operación le pide confirmar.
    if not Visible then
    begin
      Show;
      BringToFront;
    end;
    // 3. Preguntamos
    if MessageDlg(Format('La Operación %d tiene artículos pendientes.' + sLineBreak +
                         '¿Desea ELIMINARLA y cerrar?', [Self.Tag]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      // Limpiamos cambios pendientes
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      Close; // Esto destruirá el formulario si Action = caFree en OnClose
    end
    else
    begin
      Result := False; // El usuario dijo NO, abortamos el cierre general
    end;
  end
  else
  begin
    // Si está vacía, cerramos directamente sin preguntar
    Close;
  end;
end;

function TfrmMtoOpeCaja.
                      ObtenerColumnaPorTag(NumColumn: Integer): TcxGridDBColumn;
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
  lblFechaCaja.Caption := FormatDateTime( 'hh:nn:ss dddd d mmmm yyyy', Now);
end;

end.
