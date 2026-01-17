unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, cxDBData, cxClasses, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems;

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
//    procedure tvArticuloGetDisplayText(Sender: TcxCustomGridTableItem;
//      ARecord: TcxCustomGridRecord; var AText: string);
  private
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
  public
    DatosCaja: TdmCajaOpe;
  private
    FScanBuffer: string;
    FLeyendoScanner: Boolean;
  end;

var
  frmMtoOpeCaja: TfrmMtoOpeCaja;

implementation
{$R *.dfm}

uses
  inMtoCajaMenu, inLibGlobalVar;

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
    DatosCaja.CalcularTotalesCabecera;
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

//procedure TfrmMtoOpeCaja.tvArticuloGetDisplayText(
//  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
//  var AText: string);
//begin
//  if ARecord <> nil then
//    AText := VarToStr(ARecord.Values[Sender.Index]);
//end;

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

procedure TfrmMtoOpeCaja.tvArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodigoInput, ValorSeleccionado: string;
  CodigoPadre: string;
  SkuDetectado: string;
  NumAtributos: Integer;
begin
  CodigoInput := VarToStr(DisplayValue);
  if Trim(CodigoInput) = '' then
  begin
    if MessageDlg('No ha indicado ningún artículo.' + sLineBreak +
                  '¿Desea ELIMINAR esta línea?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
       Error := False;
       DisplayValue := '';
       PostMessage(Self.Handle, WM_CANCELAR_LINEA, 0, 0);
    end
    else
    begin
       Error := True;
       ErrorText := 'El código de artículo es obligatorio.';
    end;
    Exit;
  end;
  if RellenarDatosArticuloEnDataset(CodigoInput) then
  begin
    CodigoPadre  := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACTURA_LINEA').AsString;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
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
var
  Precio, NuevoDescuento, NuevoPorcen: Currency;
begin
  TcxCustomEdit(Sender).PostEditValue;
  Precio := DatosCaja.cdsLineas.FieldByName(
                                       'PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
  NuevoDescuento := DatosCaja.cdsLineas.FieldByName(
                                         'PRECIO_DTO_FACTURA_LINEA').AsCurrency;
  if Precio <> 0 then
    NuevoPorcen := (NuevoDescuento * 100) / Precio
  else
    NuevoPorcen := 0;
  DatosCaja.cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat :=
                                                                    NuevoPorcen;
  DatosCaja.CalcularTotalesLinea
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesEditValueChanged(Sender: TObject);
begin
  TcxCustomEdit(Sender).PostEditValue;
  DatosCaja.CalcularTotalesLinea;
end;

procedure TfrmMtoOpeCaja.tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
begin
  TcxCustomEdit(Sender).PostEditValue;
  DatosCaja.CalcularTotalesLinea;
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesEditValueChanged(Sender: TObject);
begin
  TcxCustomEdit(Sender).PostEditValue;
  DatosCaja.CalcularTotalesLinea;
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
                          '       PORCEN_DTO_TARIFA ' +
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
             DatosCaja.cdsLineas.FieldByName(
                                  'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString :=
                                  sql.FieldByName('ESIMP_INCL_TARIFA').AsString;
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
          DatosCaja.CalcularTotalesLinea;
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
//    DatosCaja.cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency :=
//                             qry.FieldByName('PORCEN_IVA_TARIFA').AsCurrency;
      DatosCaja.CalcularTotalesLinea;
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
    i:=1;
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
        DatosCaja.CalcularTotalesCabecera;
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
  SkuNuevo: string;
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
        DatosCaja.cdsCabecera.FieldByName(
                                     'RAZONSOCIAL_CLIENTE_FACTURA').AsString :=
                              unqry.FieldByName('RAZONSOCIAL_CLIENTE').AsString;
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
    lblNombreCliente.Caption := 'CLIENTE NO EXISTE';
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

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomEmpleado: string;
  sCodigo: string;
begin
  sCodigo := VarToStr(DisplayValue);
  if Trim(sCodigo) = '' then
  begin
    lblNombreEmpleado.Caption := '';
    Error := True;
    ErrorText := 'Debe haber un empleado en la venta'; // Mensaje al usuario
    Exit;
  end;
  if not DatosCaja.BuscarYMostrarNombre('EMPLEADOS', sCodigo, sNomEmpleado) then
  begin
    Error := True;
    ErrorText := 'El código de empleado no existe.';
    lblNombreEmpleado.Caption := '';
  end
  else
  begin
    Error := False; // Permite salir
    lblNombreEmpleado.Caption := sNomEmpleado;
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString :=
                                                         btnCodigoEmpleado.Text;
    ErrorText := '';
  end;
  cxGrid1DBTableView1.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.btnF5Click(Sender: TObject);
var
  NuevaVenta: TfrmMtoOpeCaja;
begin
  NuevaVenta := TfrmMtoOpeCaja.Create(Application);
  NuevaVenta.Show;
end;

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
begin
  DatosCaja := TdmCajaOpe.Create(Self);
  DatosCaja.uConexion := oConn;
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := DatosCaja.qryStock;
  ConstruirColumnasDinamicas;
  DatosCaja.cdsCabecera.Edit;
  DatosCaja.cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime :=
                                                       frmMtoMenuCaja.FechaCaja;
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
  case Key of
    VK_F5: btnF5.Click;
  end;
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

function TfrmMtoOpeCaja.
                      ObtenerColumnaPorTag(NumColumn: Integer): TcxGridDBColumn;
var
  Column : TcxGridDBColumn;
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
