unit inMtoCajaFaseCobro;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, Data.DB, FireDAC.Comp.Client, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxDropDownEdit, Uni, System.Generics.Collections, Vcl.Menus, inMtoFrmBase;
type
  TFormaPagoItem = record
    NumeroLinea: Integer;
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    CodigoDivisa: string;
    RedBlockchain: string;
    FactorCambio: Currency;
    ImporteDivisa: Currency;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
    Referencia: string;
    Observaciones: string;
  end;
  TfrmMtoCajaFaseCobro = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlIzquierdo: TPanel;
    pnlDerecho: TPanel;
    pnlFormasPago: TPanel;
    pnl1: TPanel;
    pnl11: TPanel;
    pnl111: TPanel;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    cxgrdlvlFormasPago: TcxGridLevel;
    pnlBotones: TPanel;
    pnlDocumento: TPanel;
    // Labels y campos del panel superior
    lblSuma: TcxLabel;
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    lblDescuento: TcxLabel;
    txtPorcenDtoGlobal: TcxTextEdit;
    txtDtoGlobal: TcxCurrencyEdit;
    lblDescuento1: TcxLabel;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalDtoLineal: TcxTextEdit;
    lblDescuento2: TcxLabel;
    txtTotalPagar: TcxCurrencyEdit;
    // Panel A CUENTA
    lblSuma1: TcxLabel;
    txtDejarCuenta: TcxCurrencyEdit;
    lblDescuento3: TcxLabel;
    txtPendienteCuenta: TcxCurrencyEdit;
    // Panel VALES
    lblSuma11: TcxLabel;
    txtValeRecogido: TcxCurrencyEdit;
    lblDescuento31: TcxLabel;
    txtValeEmitido: TcxCurrencyEdit;
    // Panel inferior pendiente
    lblDescuento4: TcxLabel;
    txtPendienteCobro: TcxCurrencyEdit;
    // Grid de formas de pago
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    dbmImporte: TcxGridDBColumn;
    dsFormasPago: TDataSource;
    // Botones laterales
    btnSinTicket: TcxButton;
    btnF11: TcxButton;
    btnConTicket: TcxButton;
    btnF12: TcxButton;
    btnSinPrecios: TcxButton;
    btnF10: TcxButton;
    btnDeposito: TcxButton;
    btnF7: TcxButton;
    btnFactura: TcxButton;
    btnF8: TcxButton;
    btnBuscarVale: TcxButton;
    btnF6: TcxButton;
    btnMasDatos: TcxButton;
    btnF2: TcxButton;
    btnBuscarT: TcxButton;
    btnF3: TcxButton;
    btnAtras: TcxButton;
    btnESC: TcxButton;
    // Documento
    lblNumDoc: TcxLabel;
    edtNumeroDoc: TcxTextEdit;
    cbbSerie1: TcxComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure dbtvFormasPagoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FMemTablePagos: TFDMemTable;
    FListaBotones: TList<TcxButton>;
    FImporteTotal: Currency;
    FImportePendiente: Currency;
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FCodigoCaja: string;
    FSerieOperacion: string;
    FNumeroOperacion: string;
    procedure ConfigurarGridFormasPago;
    procedure CargarBotonesFormasPago;
    procedure OnBotonFormaPagoClick(Sender: TObject);
    procedure AgregarFormaPagoSimple(const CodigoFP, DescripcionFP: string;
      DevuelveCambio: Boolean);
    procedure AgregarFormaPagoCompleja(Pago: TFormaPagoItem);
    procedure EliminarFormaPagoSeleccionada;
    procedure RecalcularTotales;
    procedure ConfigurarTeclasFuncion;
  public
    property ImporteTotal: Currency read FImporteTotal write FImporteTotal;
    property CodigoEmpresa: string read FCodigoEmpresa write FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen write FCodigoAlmacen;
    property CodigoCaja: string read FCodigoCaja write FCodigoCaja;
    property SerieOperacion: string read FSerieOperacion write FSerieOperacion;
    property NumeroOperacion: string read FNumeroOperacion write FNumeroOperacion;
    function ObtenerDatosPagos: TArray<TFormaPagoItem>;
    function ValidarPagos: Boolean;
  end;
var
  frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro;
implementation
{$R *.dfm}

procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
begin
  // Configurar tabla en memoria para formas de pago
  FMemTablePagos := TFDMemTable.Create(Self);
  FMemTablePagos.FieldDefs.Add('NUMERO_LINEA', ftInteger);
  FMemTablePagos.FieldDefs.Add('CODIGO_FORMAP', ftString, 10);
  FMemTablePagos.FieldDefs.Add('DESCRIPCION', ftString, 100);
  FMemTablePagos.FieldDefs.Add('CODIGO_DIVISA', ftString, 10);
  FMemTablePagos.FieldDefs.Add('RED_BLOCKCHAIN', ftString, 50);
  FMemTablePagos.FieldDefs.Add('FACTOR_CAMBIO', ftCurrency);
  FMemTablePagos.FieldDefs.Add('IMPORTE_DIVISA', ftCurrency);
  FMemTablePagos.FieldDefs.Add('IMPORTE', ftCurrency);
  FMemTablePagos.FieldDefs.Add('CAMBIO', ftCurrency);
  FMemTablePagos.FieldDefs.Add('REFERENCIA', ftString, 255);
  FMemTablePagos.CreateDataSet;
  FMemTablePagos.Open;
  dsFormasPago.DataSet := FMemTablePagos;
  FListaBotones := TList<TcxButton>.Create;
  ConfigurarGridFormasPago;
  ConfigurarTeclasFuncion;
  FImporteTotal := 0;
  FImportePendiente := 0;
  // Valores por defecto
  txtCantidadLineas.Text := '0';
  txtBrutoLineas.Value := 0;
  txtTotalPagar.Value := 0;
  txtPendienteCobro.Value := 0;
end;
procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
begin
  // Cargar datos iniciales
  txtBrutoLineas.Value := FImporteTotal;
  txtTotalPagar.Value := FImporteTotal;
  txtPendienteCobro.Value := FImporteTotal;
  FImportePendiente := FImporteTotal;
  // Configurar serie y número
  cbbSerie1.Text := FSerieOperacion;
  edtNumeroDoc.Text := FNumeroOperacion;
  // Cargar botones de formas de pago
  CargarBotonesFormasPago;
end;
procedure TfrmMtoCajaFaseCobro.ConfigurarGridFormasPago;
begin
  // Configurar columnas
  cxgrdbclmnCodigo.DataBinding.FieldName := 'CODIGO_FORMAP';
  dbmDescripcion.DataBinding.FieldName := 'DESCRIPCION';
  dbmImporte.DataBinding.FieldName := 'IMPORTE';
  // Agregar columna para divisa/crypto si existe
  var colDivisa := dbtvFormasPago.CreateColumn;
  colDivisa.Caption := 'Divisa/Crypto';
  colDivisa.DataBinding.FieldName := 'CODIGO_DIVISA';
  colDivisa.Width := 80;
  // Formato de importe
  with (dbmImporte.Properties as TcxCurrencyEditProperties) do
  begin
    DisplayFormat := ',0.00 €';
    Alignment.Horz := taRightJustify;
  end;
  // Configurar vista
  dbtvFormasPago.OptionsView.GroupByBox := False;
  dbtvFormasPago.OptionsSelection.CellSelect := False;
  dbtvFormasPago.OptionsData.Editing := False;
  dbtvFormasPago.OptionsData.Deleting := True;
  dbtvFormasPago.OptionsData.Inserting := False;
  dbtvFormasPago.OnKeyDown := dbtvFormasPagoKeyDown;
end;
procedure TfrmMtoCajaFaseCobro.CargarBotonesFormasPago;
var
  Query: TFDQuery;
  Btn: TcxButton;
  TopPos, LeftPos, BtnIndex: Integer;
begin
  // Limpiar botones anteriores
  for Btn in FListaBotones do
    Btn.Free;
  FListaBotones.Clear;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := DMConexion.ConexionMySQL;
    Query.SQL.Add('SELECT CODIGO_FORMAP, DESCRIPCION_FORMAP, ');
    Query.SQL.Add('  TIPO_COMPORTAMIENTO_FORMAP, ES_DEVUELVE_CAMBIO_FORMAP,');
    Query.SQL.Add('  ORDEN_VISUAL_FORMAP');
    Query.SQL.Add('FROM fza_formas_pago');
    Query.SQL.Add('WHERE ES_ACTIVO_FORMAP = ''S''');
    Query.SQL.Add('ORDER BY ORDEN_VISUAL_FORMAP');
    Query.Open;
    BtnIndex := 0;
    TopPos := 70; // Debajo de los 3 botones principales
    while not Query.Eof do
    begin
      // Calcular posición (3 botones por fila)
      LeftPos := 40 + (BtnIndex mod 3) * 120;
      if (BtnIndex > 0) and (BtnIndex mod 3 = 0) then
        TopPos := TopPos + 45;
      // Crear botón
      Btn := TcxButton.Create(pnlFormasPago);
      Btn.Parent := pnlFormasPago;
      Btn.Left := LeftPos;
      Btn.Top := TopPos;
      Btn.Width := 110;
      Btn.Height := 40;
      Btn.Caption := Query.FieldByName('DESCRIPCION_FORMAP').AsString;
      Btn.Tag := BtnIndex;
      Btn.Hint := Query.FieldByName('CODIGO_FORMAP').AsString;
      Btn.OnClick := OnBotonFormaPagoClick;
      // Colores según tipo
      case AnsiIndexStr(Query.FieldByName('TIPO_COMPORTAMIENTO_FORMAP').AsString,
        ['EFECTIVO', 'TARJETA', 'VALE', 'DEUDA']) of
        0: begin // EFECTIVO
          Btn.Colors.Default := clYellow;
          Btn.Colors.Normal := clYellow;
          Btn.Colors.Hot := $0080FFFF;
        end;
        1: begin // TARJETA
          Btn.Colors.Default := clYellow;
          Btn.Colors.Normal := clYellow;
          Btn.Colors.Hot := $0080FFFF;
        end;
        2: begin // VALE
          Btn.Colors.Default := clAqua;
          Btn.Colors.Normal := clAqua;
          Btn.Colors.Hot := $00FFFF80;
        end;
        3: begin // DEUDA
          Btn.Colors.Default := clAqua;
          Btn.Colors.Normal := clAqua;
          Btn.Colors.Hot := $00FFFF80;
        end;
      else
        Btn.Colors.Default := clSilver;
        Btn.Colors.Normal := clSilver;
        Btn.Colors.Hot := clWhite;
      end;
      Btn.LookAndFeel.Kind := lfUltraFlat;
      Btn.Font.Style := [fsBold];
      FListaBotones.Add(Btn);
      Inc(BtnIndex);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;
procedure TfrmMtoCajaFaseCobro.OnBotonFormaPagoClick(Sender: TObject);
var
  Btn: TcxButton;
  CodigoFP, DescripcionFP, TipoFP: string;
  Query: TFDQuery;
  DevuelveCambio, RequiereReferencia: Boolean;
  FrmEspecializado: TFrmPagoEspecializado;
  Pago: TFormaPagoItem;
begin
  Btn := Sender as TcxButton;
  CodigoFP := Btn.Hint;
  DescripcionFP := Btn.Caption;
  // Consultar datos de la forma de pago
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := DMConexion.ConexionMySQL;
    Query.SQL.Add('SELECT TIPO_COMPORTAMIENTO_FORMAP, ES_DEVUELVE_CAMBIO_FORMAP,');
    Query.SQL.Add('  ES_REQ_REFERENCIA_FORMAP');
    Query.SQL.Add('FROM fza_formas_pago');
    Query.SQL.Add('WHERE CODIGO_FORMAP = :CODIGO');
    Query.ParamByName('CODIGO').AsString := CodigoFP;
    Query.Open;
    if Query.IsEmpty then
      Exit;
    TipoFP := Query.FieldByName('TIPO_COMPORTAMIENTO_FORMAP').AsString;
    DevuelveCambio := Query.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString = 'S';
    RequiereReferencia := Query.FieldByName('ES_REQ_REFERENCIA_FORMAP').AsString = 'S';
  finally
    Query.Free;
  end;
  // Si es una forma de pago simple (efectivo, tarjeta básica)
  if (not RequiereReferencia) and (CodigoFP <> 'CRYPTO') and (CodigoFP <> 'DIVISA') then
  begin
    AgregarFormaPagoSimple(CodigoFP, DescripcionFP, DevuelveCambio);
  end
  else
  begin
    // Abrir formulario especializado para divisas, crypto, o formas complejas
    FrmEspecializado := TFrmPagoEspecializado.Create(Self);
    try
      FrmEspecializado.CodigoFormaPago := CodigoFP;
      FrmEspecializado.DescripcionFormaPago := DescripcionFP;
      FrmEspecializado.ImportePendiente := FImportePendiente;
      FrmEspecializado.RequiereReferencia := RequiereReferencia;
      if FrmEspecializado.ShowModal = mrOk then
      begin
        Pago := FrmEspecializado.ObtenerDatosPago;
        AgregarFormaPagoCompleja(Pago);
      end;
    finally
      FrmEspecializado.Free;
    end;
  end;
  RecalcularTotales;
end;
procedure TfrmMtoCajaFaseCobro.AgregarFormaPagoSimple(const CodigoFP, DescripcionFP: string;
  DevuelveCambio: Boolean);
var
  Importe: string;
  ImporteNum: Currency;
begin
  // Solicitar importe
  Importe := FormatFloat('0.00', FImportePendiente);
  if not InputQuery('Importe', 'Ingrese el importe:', Importe) then
    Exit;
  if not TryStrToCurr(Importe, ImporteNum) then
  begin
    ShowMessage('Importe inválido');
    Exit;
  end;
  if ImporteNum <= 0 then
  begin
    ShowMessage('El importe debe ser mayor a cero');
    Exit;
  end;
  // Agregar al grid
  FMemTablePagos.Append;
  FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger := FMemTablePagos.RecordCount + 1;
  FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := CodigoFP;
  FMemTablePagos.FieldByName('DESCRIPCION').AsString := DescripcionFP;
  FMemTablePagos.FieldByName('IMPORTE').AsCurrency := ImporteNum;
  FMemTablePagos.FieldByName('CAMBIO').AsCurrency := 0;
  // Si devuelve cambio y se entregó más, calcularlo
  if DevuelveCambio and (ImporteNum > FImportePendiente) then
    FMemTablePagos.FieldByName('CAMBIO').AsCurrency := ImporteNum - FImportePendiente;
  FMemTablePagos.Post;
end;
procedure TfrmMtoCajaFaseCobro.AgregarFormaPagoCompleja(Pago: TFormaPagoItem);
begin
  FMemTablePagos.Append;
  FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger := FMemTablePagos.RecordCount + 1;
  FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := Pago.CodigoFormaPago;
  FMemTablePagos.FieldByName('DESCRIPCION').AsString := Pago.DescripcionFormaPago;
  FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := Pago.CodigoDivisa;
  FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString := Pago.RedBlockchain;
  FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := Pago.FactorCambio;
  FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := Pago.ImporteDivisa;
  FMemTablePagos.FieldByName('IMPORTE').AsCurrency := Pago.ImporteEntregado;
  FMemTablePagos.FieldByName('CAMBIO').AsCurrency := Pago.ImporteCambio;
  FMemTablePagos.FieldByName('REFERENCIA').AsString := Pago.Referencia;
  FMemTablePagos.Post;
end;
procedure TfrmMtoCajaFaseCobro.EliminarFormaPagoSeleccionada;
begin
  if FMemTablePagos.IsEmpty then
    Exit;
  if MessageDlg('¿Eliminar la forma de pago seleccionada?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FMemTablePagos.Delete;
    RecalcularTotales;
  end;
end;
procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then
    EliminarFormaPagoSeleccionada;
end;
procedure TfrmMtoCajaFaseCobro.RecalcularTotales;
var
  TotalPagado: Currency;
begin
  TotalPagado := 0;
  FMemTablePagos.First;
  while not FMemTablePagos.Eof do
  begin
    TotalPagado := TotalPagado + FMemTablePagos.FieldByName('IMPORTE').AsCurrency;
    FMemTablePagos.Next;
  end;
  FImportePendiente := FImporteTotal - TotalPagado;
  // Actualizar pantalla
  txtPendienteCobro.Value := FImportePendiente;
  txtPendienteCuenta.Value := FImportePendiente;
  // Si ya está todo pagado, cerrar automáticamente
  if FImportePendiente <= 0 then
  begin
    if MessageDlg('Cobro completado. ¿Desea finalizar?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ModalResult := mrOk;
  end;
end;
procedure TfrmMtoCajaFaseCobro.ConfigurarTeclasFuncion;
begin
  KeyPreview := True;
end;
procedure TfrmMtoCajaFaseCobro.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2: btnMasDatos.Click;
    VK_F3: btnBuscarT.Click;
    VK_F6: btnBuscarVale.Click;
    VK_F7: btnDeposito.Click;
    VK_F8: btnFactura.Click;
    VK_F10: btnSinPrecios.Click;
    VK_F11: btnSinTicket.Click;
    VK_F12: btnConTicket.Click;
    VK_ESCAPE: btnAtras.Click;
  end;
end;
procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  if MessageDlg('¿Desea cancelar el cobro?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ModalResult := mrCancel;
end;
function TfrmMtoCajaFaseCobro.ValidarPagos: Boolean;
begin
  Result := False;
  if FMemTablePagos.RecordCount = 0 then
  begin
    ShowMessage('Debe ingresar al menos una forma de pago.');
    Exit;
  end;
  if FImportePendiente > 0 then
  begin
    if MessageDlg(
      Format('Aún queda pendiente: %.2f €' + #13#10 + '¿Desea continuar dejando el saldo pendiente?',
        [FImportePendiente]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;
  Result := True;
end;
function TfrmMtoCajaFaseCobro.ObtenerDatosPagos: TArray<TFormaPagoItem>;
var
  Lista: TList<TFormaPagoItem>;
  Item: TFormaPagoItem;
begin
  Lista := TList<TFormaPagoItem>.Create;
  try
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      Item.NumeroLinea := FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger;
      Item.CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
      Item.DescripcionFormaPago := FMemTablePagos.FieldByName('DESCRIPCION').AsString;
      Item.CodigoDivisa := FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
      Item.RedBlockchain := FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString;
      Item.FactorCambio := FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency;
      Item.ImporteDivisa := FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency;
      Item.ImporteEntregado := FMemTablePagos.FieldByName('IMPORTE').AsCurrency;
      Item.ImporteCambio := FMemTablePagos.FieldByName('CAMBIO').AsCurrency;
      Item.Referencia := FMemTablePagos.FieldByName('REFERENCIA').AsString;
      Lista.Add(Item);
      FMemTablePagos.Next;
    end;
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;
end.
