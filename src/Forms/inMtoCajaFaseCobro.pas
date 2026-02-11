unit inMtoCajaFaseCobro;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, Data.DB, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  inLibGlobalVar, system.UITypes,
  cxDropDownEdit, Uni, System.Generics.Collections, Vcl.Menus, inMtoFrmBase,
  MemDS, VirtualTable, inLibFacturas, System.Actions, Vcl.ActnList;
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
    pnlBotones: TPanel;
    pnlDocumento: TPanel;
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
    vrtltbl1: TVirtualTable;
    ActionList1: TActionList;
    actSalir: TAction;
    Panel1: TPanel;
    Panel2: TPanel;
    pnl1: TPanel;
    lblDescuento1: TcxLabel;
    lblDescuento2: TcxLabel;
    lblDescuento: TcxLabel;
    lblSuma: TcxLabel;
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalPagar: TcxCurrencyEdit;
    txtDtoGlobal: TcxCurrencyEdit;
    pnl11: TPanel;
    lblDescuento3: TcxLabel;
    lblSuma1: TcxLabel;
    txtDejarCuenta: TcxCurrencyEdit;
    txtPendienteCuenta: TcxCurrencyEdit;
    pnl111: TPanel;
    lblDescuento31: TcxLabel;
    lblSuma11: TcxLabel;
    txtValeRecogido: TcxCurrencyEdit;
    txtValeEmitido: TcxCurrencyEdit;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    dbmImporte: TcxGridDBColumn;
    cxgrdlvlFormasPago: TcxGridLevel;
    pnlFormasPago: TPanel;
    lblDescuento4: TcxLabel;
    txtPendienteCobro: TcxCurrencyEdit;
    cxLabel3: TcxLabel;
    cxLabel2: TcxLabel;
    txtTotalDtoLineal: TcxCurrencyEdit;
    txtPorcenDtoGlobal: TcxCurrencyEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure dbtvFormasPagoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnESCClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);
  private
    FMemTablePagos: TVirtualTable;
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
//    procedure RecalcularTotales;
    procedure CargarFormasPagoEnGrid;
    procedure ConfigurarTeclasFuncion;
    procedure CalcularDescuentoGlobal;
    procedure RecalcularTotalesEconomicos;
  public
    property ImporteTotal: Currency read FImporteTotal write FImporteTotal;
    property CodigoEmpresa: string read FCodigoEmpresa write FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen write FCodigoAlmacen;
    property CodigoCaja: string read FCodigoCaja write FCodigoCaja;
    property SerieOperacion: string read FSerieOperacion write FSerieOperacion;
    property NumeroOperacion: string read FNumeroOperacion write FNumeroOperacion;
    function ObtenerDatosPagos: TArray<TFormaPagoItem>;
    function ValidarPagos: Boolean;
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
  end;
var
  frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro;
implementation
{$R *.dfm}

procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
begin
  // Configurar tabla en memoria para formas de pago
  FMemTablePagos := TVirtualTable.Create(Self);
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
  // NUEVO CAMPO DE CONTROL (Invisible en el grid, solo para lógica)
  FMemTablePagos.FieldDefs.Add('REQ_REFERENCIA', ftString, 1); // 'S' o 'N'
//  FMemTablePagos.Create;
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

  dbtvFormasPago.OptionsData.Editing := True;
  dbtvFormasPago.OptionsSelection.CellSelect := True; // Para que puedas entrar en la celda

  // 2. BLOQUEAR COLUMNAS QUE NO SE TOCAN
  cxgrdbclmnCodigo.Options.Editing := False;
  cxgrdbclmnCodigo.Options.Focusing := False;
  cxgrdbclmnCodigo.Visible := False;
  dbmDescripcion.Options.Editing := False;
  dbmDescripcion.Options.Focusing := False;

  // 3. ACTIVAR COLUMNA IMPORTE
  dbmImporte.Options.Editing := True;
  dbmImporte.Options.Focusing := True;

end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
begin
// Cargar datos iniciales
  // txtBrutoLineas.Value := FImporteTotal; // <--- COMENTAR O QUITAR ESTO si quieres ver la BASE en lugar del TOTAL en "Bruto"
  // Si no hemos cargado datos enriquecidos (ej. CantidadLineas es 0 o vacío), usamos el comportamiento básico
  if (txtTotalPagar.Value = 0) and (FImporteTotal <> 0) then
     txtTotalPagar.Value := FImporteTotal;
  txtPendienteCobro.Value := FImportePendiente;
  // Configurar serie y número
  cbbSerie1.Text := FSerieOperacion;
  edtNumeroDoc.Text := FNumeroOperacion;
  // Cargar botones de formas de pago
  CargarBotonesFormasPago;
  CargarFormasPagoEnGrid;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarGridFormasPago;
begin
  // Configurar columnas
  cxgrdbclmnCodigo.DataBinding.FieldName := 'CODIGO_FORMAP';
  dbmDescripcion.DataBinding.FieldName := 'DESCRIPCION';
  dbmImporte.DataBinding.FieldName := 'IMPORTE';
  // Agregar columna para divisa/crypto si existe
//  var colDivisa := dbtvFormasPago.CreateColumn;
//  colDivisa.Caption := 'Divisa/Crypto';
//  colDivisa.DataBinding.FieldName := 'CODIGO_DIVISA';
//  colDivisa.Width := 80;
  // Formato de importe
  with (dbmImporte.Properties as TcxCurrencyEditProperties) do
  begin
    DisplayFormat := ',0.00 €';
    Alignment.Horz := taRightJustify;
  end;
  // Configurar vista
  dbtvFormasPago.OptionsView.GroupByBox := False;
//  dbtvFormasPago.OptionsSelection.CellSelect := False;
//  dbtvFormasPago.OptionsData.Editing := False;
//  dbtvFormasPago.OptionsData.Deleting := True;
//  dbtvFormasPago.OptionsData.Inserting := False;
//  dbtvFormasPago.OnKeyDown := dbtvFormasPagoKeyDown;
end;

procedure TfrmMtoCajaFaseCobro.CalcularDescuentoGlobal;
var
  Porcentaje, ImporteDto: Currency;
begin
  // Convertimos el texto del porcentaje a número
  // Usamos TryStrToCurr para evitar errores si el usuario escribe letras
  if not TryStrToCurr(txtPorcenDtoGlobal.Text, Porcentaje) then
    Porcentaje := 0;

  // Calculamos el importe del descuento sobre el Bruto de las líneas
  // Importe = Bruto * (Porcentaje / 100)
  ImporteDto := txtBrutoLineas.Value * (Porcentaje / 100);

  // 1. Escribimos el resultado en el cuadro de importe de descuento
  txtDtoGlobal.Value := ImporteDto;

  // 2. Recalculamos el Total a Pagar
  // Total Pagar = (Bruto - Dto Lineal) - Dto Global
  txtTotalPagar.Value := (txtBrutoLineas.Value - txtTotalDtoLineal.Value) -
                          ImporteDto;

  // 3. Actualizamos lo pendiente de cobro
  RecalcularTotalesEconomicos;
end;

procedure TfrmMtoCajaFaseCobro.CargarBotonesFormasPago;
var
  Query: TUniQuery;
  Btn: TcxButton;
  TopPos, LeftPos, BtnIndex: Integer;
begin
  // Limpiar botones anteriores
  for Btn in FListaBotones do
    Btn.Free;
  FListaBotones.Clear;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := oConn;
    Query.SQL.Add('SELECT CODIGO_FORMAP, DESCRIPCION_FORMAP, ');
    Query.SQL.Add('  TIPO_COMPORTAMIENTO_FORMAP, ES_DEVUELVE_CAMBIO_FORMAP,');
    Query.SQL.Add('  ORDEN_VISUAL_FORMAP');
    Query.SQL.Add('FROM fza_caja_formas_pago');
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
//      case AnsiIndexStr(Query.FieldByName('TIPO_COMPORTAMIENTO_FORMAP').AsString,
//        ['EFECTIVO', 'TARJETA', 'VALE', 'DEUDA']) of
//        0: begin // EFECTIVO
//          Btn.Colors.Default := clYellow;
//          Btn.Colors.Normal := clYellow;
//          Btn.Colors.Hot := $0080FFFF;
//        end;
//        1: begin // TARJETA
//          Btn.Colors.Default := clYellow;
//          Btn.Colors.Normal := clYellow;
//          Btn.Colors.Hot := $0080FFFF;
//        end;
//        2: begin // VALE
//          Btn.Colors.Default := clAqua;
//          Btn.Colors.Normal := clAqua;
//          Btn.Colors.Hot := $00FFFF80;
//        end;
//        3: begin // DEUDA
//          Btn.Colors.Default := clAqua;
//          Btn.Colors.Normal := clAqua;
//          Btn.Colors.Hot := $00FFFF80;
//        end;
//      else
//        Btn.Colors.Default := clSilver;
//        Btn.Colors.Normal := clSilver;
//        Btn.Colors.Hot := clWhite;
//      end;
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

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
var
  PorcentajeMedio : Double;
begin
  if TotalesFactura = nil then Exit;
  FImporteTotal := TotalesFactura.Totales.TotalLiquido;
  FImportePendiente := FImporteTotal;
  txtCantidadLineas.Text := FormatFloat('0.##',
                                        TotalesFactura.Totales.TotalCantidades);
  txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
  txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;
  // Calculamos el porcentaje visual para mostrarlo (10% en tu ejemplo)
  if TotalesFactura.Totales.TotalBruto <> 0 then
  begin
    PorcentajeMedio := (TotalesFactura.Totales.TotalDescuentosLineas /
                        TotalesFactura.Totales.TotalBruto) * 100;
    txtPorcenDtoLineal.Text := FormatFloat('0.## %', PorcentajeMedio);
  end
  else
    txtPorcenDtoLineal.Text := '0';
  // Total Final a Pagar (Líquido)
  txtTotalPagar.Value := FImporteTotal;
  // 3. Actualizar paneles de importes pendientes
  txtPendienteCobro.Value := FImportePendiente;
  // Si usas el panel de "A cuenta"
  txtPendienteCuenta.Value := FImportePendiente;
  // 4. (Opcional) Visualizar Retenciones si el formulario lo soporta
  // Como tu formulario de cobro parece genérico, podrías usar labels existentes
  // o mostrar un mensaje si hay retención para avisar al cajero.
  if TotalesFactura.Totales.TotalRetencion > 0 then
  begin
    // Ejemplo: Si tuvieras un label para avisos o reutilizando uno de descuento
    // lblDescuento.Caption := 'Retención:';
    // txtDtoGlobal.Value := TotalesFactura.Totales.TotalRetencion;
  end;
end;

procedure TfrmMtoCajaFaseCobro.OnBotonFormaPagoClick(Sender: TObject);
var
  Btn: TcxButton;
  CodigoFP, DescripcionFP, TipoFP: string;
  Query: TUniQuery;
  DevuelveCambio, RequiereReferencia: Boolean;
//  FrmEspecializado: TFrmPagoEspecializado;
  Pago: TFormaPagoItem;
begin
  Btn := Sender as TcxButton;
  CodigoFP := Btn.Hint;
  DescripcionFP := Btn.Caption;
  // Consultar datos de la forma de pago
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := oConn;
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
//    FrmEspecializado := TFrmPagoEspecializado.Create(Self);
//    try
//      FrmEspecializado.CodigoFormaPago := CodigoFP;
//      FrmEspecializado.DescripcionFormaPago := DescripcionFP;
//      FrmEspecializado.ImportePendiente := FImportePendiente;
//      FrmEspecializado.RequiereReferencia := RequiereReferencia;
//      if FrmEspecializado.ShowModal = mrOk then
//      begin
//        Pago := FrmEspecializado.ObtenerDatosPago;
//        AgregarFormaPagoCompleja(Pago);
//      end;
//    finally
//      FrmEspecializado.Free;
//    end;
  end;
  RecalcularTotalesEconomicos;
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

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
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
    RecalcularTotalesEconomicos;
  end;
end;

//procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoKeyDown(Sender: TObject; var Key: Word;
//  Shift: TShiftState);
//begin
//  if Key = VK_DELETE then
//    EliminarFormaPagoSeleccionada;
//end;

procedure TfrmMtoCajaFaseCobro.CargarFormasPagoEnGrid;
var
  Qry: TUniQuery;
begin
  // Aseguramos que la tabla de memoria esté limpia y abierta
  if not FMemTablePagos.Active then
    FMemTablePagos.Open;
  FMemTablePagos.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn; // Asumo que oConn está en inLibGlobalVar
    Qry.SQL.Text := 'SELECT CODIGO_FORMAP, DESCRIPCION_FORMAP, TIPO_COMPORTAMIENTO_FORMAP ' +
                    'FROM fza_caja_formas_pago ' +
                    'WHERE ES_ACTIVO_FORMAP = ''S'' ' +
                    'ORDER BY ORDEN_VISUAL_FORMAP';
    Qry.Open;

    while not Qry.Eof do
    begin
      FMemTablePagos.Append;
      FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger := FMemTablePagos.RecordCount + 1;
      FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := Qry.FieldByName('CODIGO_FORMAP').AsString;
      FMemTablePagos.FieldByName('DESCRIPCION').AsString := Qry.FieldByName('DESCRIPCION_FORMAP').AsString;

      // Inicializamos el importe a 0 para que el usuario lo rellene
      // Opcional: Si quieres que "Efectivo" venga pre-rellenado con el total, dímelo y lo ajustamos.
      FMemTablePagos.FieldByName('IMPORTE').AsCurrency := 0;
      FMemTablePagos.FieldByName('CAMBIO').AsCurrency := 0;

      FMemTablePagos.Post;
      Qry.Next;
    end;

    // Posicionamos el cursor en la primera línea (habitualmente Efectivo)
    if not FMemTablePagos.IsEmpty then
      FMemTablePagos.First;

  finally
    Qry.Free;
  end;
end;

procedure TfrmMtoCajaFaseCobro.RecalcularTotalesEconomicos;
var
  cBruto, cDtoLineal, cBaseDescuento: Currency;
  cPorcenGlobal, cImpDtoGlobal: Currency;
  cTotalPagar, cPagado, cPendiente: Currency;
begin
  // 1. Obtener valores base
  cBruto := txtBrutoLineas.Value;       // 150.00
  cDtoLineal := txtTotalDtoLineal.Value; // 15.00

  // 2. Calcular la base sobre la que aplica el descuento global
  // Normalmente: Bruto - Descuentos de línea ya aplicados
  cBaseDescuento := cBruto - cDtoLineal; // 135.00

  // 3. Calcular Descuento Global (Sincronización)
  // Usamos el Porcentaje escrito para calcular el Importe exacto
  cPorcenGlobal := txtPorcenDtoGlobal.Value;
  cImpDtoGlobal := cBaseDescuento * (cPorcenGlobal / 100);

  // Escribimos el importe calculado en su caja correspondiente
  txtDtoGlobal.Value := cImpDtoGlobal;

  // 4. Calcular Total Final
  cTotalPagar := cBaseDescuento - cImpDtoGlobal;
  txtTotalPagar.Value := cTotalPagar;

  // 5. Calcular Pendiente (Total Pagar - Lo que ya hayan entregado)
  // Sumamos lo que hay en la grilla de pagos (si existe)
  cPagado := 0;
  if not FMemTablePagos.IsEmpty then
  begin
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      cPagado := cPagado + FMemTablePagos.FieldByName('IMPORTE').AsCurrency;
      FMemTablePagos.Next;
    end;
  end;

  cPendiente := cTotalPagar - cPagado;

  // Actualizar paneles de pendiente
  txtPendienteCobro.Value := cPendiente;
  txtPendienteCuenta.Value := cPendiente; // Si usas este panel

  // (Opcional) Actualizar el label grande de abajo si tienes uno
  // lblPendienteGigante.Caption := FormatFloat(',0.00 €', cPendiente);
end;

//procedure TfrmMtoCajaFaseCobro.RecalcularTotales;
//var
//  TotalPagado: Currency;
//begin
//  TotalPagado := 0;
//  FMemTablePagos.First;
//  while not FMemTablePagos.Eof do
//  begin
//    TotalPagado := TotalPagado + FMemTablePagos.FieldByName('IMPORTE').AsCurrency;
//    FMemTablePagos.Next;
//  end;
//  FImportePendiente := FImporteTotal - TotalPagado;
//  // Actualizar pantalla
//  txtPendienteCobro.Value := FImportePendiente;
//  txtPendienteCuenta.Value := FImportePendiente;
//  // Si ya está todo pagado, cerrar automáticamente
//  if FImportePendiente <= 0 then
//  begin
//    if MessageDlg('Cobro completado. ¿Desea finalizar?',
//      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
//      ModalResult := mrOk;
//  end;
//end;

procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesEditValueChanged(
  Sender: TObject);
var
  Porcentaje: Double;
  ImporteDto: Currency;
  BaseImponible: Currency;
begin
  // 1. Obtenemos el valor limpio (el componente ignora el % automáticamente)
  Porcentaje := txtPorcenDtoGlobal.Value;

  // Evitamos errores si está vacío
  if Porcentaje = 0 then
  begin
    txtDtoGlobal.Value := 0;
    // Restaurar total original (Bruto - Dto Lineal)
    txtTotalPagar.Value := txtBrutoLineas.Value - txtTotalDtoLineal.Value;
    RecalcularTotalesEconomicos;
    Exit;
  end;

  // 2. Definimos sobre qué base aplicamos el descuento
  // (Generalmente es sobre el Bruto - Descuentos de línea)
  BaseImponible := txtBrutoLineas.Value - txtTotalDtoLineal.Value;

  // 3. Calculamos el importe
  ImporteDto := BaseImponible * (Porcentaje / 100);

  // 4. Asignamos el resultado al campo de Importe (en Euros)
  // Nota: Asegúrate que txtDtoGlobal también sea un cxCurrencyEdit para evitar conversiones
  txtDtoGlobal.Value := ImporteDto;

  // 5. Calculamos el Total Final
  txtTotalPagar.Value := BaseImponible - ImporteDto;

  // 6. Actualizamos restas pendientes
  RecalcularTotalesEconomicos;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarTeclasFuncion;
begin
  KeyPreview := True;
end;

procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  RecalcularTotalesEconomicos;
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
  if MessageDlg('¿Desea cancelar el cobro?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    ModalResult := mrCancel;
end;

procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
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
