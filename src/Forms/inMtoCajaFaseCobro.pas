unit inMtoCajaFaseCobro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  System.Generics.Collections, Data.DB,
  // Componentes DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxGrid,
  // Componentes de Acceso a Datos
  Uni, MemDS, VirtualTable,
  // Unidades Propias
  inLibGlobalVar, inMtoFrmBase, inLibFacturas, dxDateRanges,
  dxScrollbarAnnotations, cxDropDownEdit;

type
  TFormaPagoItem = record
    NumeroLinea: Integer;
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    CodigoDivisa: string;
    RedBlockchain: string;
    FactorCambio: Currency;
    ImporteDivisa: Currency;
    ImporteEntregado: Currency; // Lo que entrega el cliente
    ImporteCambio: Currency;    // El cambio generado (si aplica)
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

    // Botones laterales (Actions)
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

    // Cabecera Documento
    lblNumDoc: TcxLabel;
    edtNumeroDoc: TcxTextEdit;
    cbbSerie1: TcxComboBox;

    // Utilidades
    vrtltbl1: TVirtualTable;
    ActionList1: TActionList;
    actSalir: TAction;
    pnlLogoLeft: TPanel;
    Panel2: TPanel;
    pnl1: TPanel;
    lblDescuento1: TcxLabel;
    lblDescuento2: TcxLabel;
    lblDescuento: TcxLabel;
    lblSuma: TcxLabel;

    // Edits de Importes
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalDtoLineal: TcxCurrencyEdit;

    txtPorcenDtoGlobal: TcxCurrencyEdit;
    txtDtoGlobal: TcxCurrencyEdit;

    txtTotalPagar: TcxCurrencyEdit; // Total Final (Debe ser pagado)

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

    // Grid y Panel Pago
    pnlFormasPago: TPanel;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    cxgrdlvlFormasPago: TcxGridLevel;

    // Columnas Grid
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    dbmImporte: TcxGridDBColumn; // Importe entregado

    // Panel Inferior (Totales finales)
    lblDescuento4: TcxLabel;
    txtPendienteCobro: TcxCurrencyEdit; // Lo que falta por pagar
    cxLabel3: TcxLabel; // NUEVO SUGERIDO: Para mostrar el cambio

    cxLabel2: TcxLabel;
    cxLabel1: TcxLabel;
    txtCambio: TcxCurrencyEdit;
    cxStyleRepository1: TcxStyleRepository;
    cxStyle1: TcxStyle;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnESCClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);

    // Eventos de cálculo
    procedure txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);

  private
    FMemTablePagos: TVirtualTable;
    FImporteTotalInicial: Currency; // Total Factura Original

    // Datos Contexto
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FCodigoCaja: string;
    FSerieOperacion: string;
    FNumeroOperacion: string;

    procedure ConfigurarGridFormasPago;
    procedure CargarFormasPagoEnGrid;
    procedure ConfigurarTeclasFuncion;

    // Lógica Matemática Central
    procedure CalcularTotales;

  public
    // Propiedades para pasar datos desde fuera
    property CodigoEmpresa: string read FCodigoEmpresa write FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen write FCodigoAlmacen;
    property CodigoCaja: string read FCodigoCaja write FCodigoCaja;
    property SerieOperacion: string read FSerieOperacion write FSerieOperacion;
    property NumeroOperacion: string read FNumeroOperacion write FNumeroOperacion;

    // Métodos Públicos
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
    function ObtenerDatosPagos: TArray<TFormaPagoItem>;
    function ValidarPagos: Boolean;
  end;

var
  frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro;

implementation

{$R *.dfm}

{ TfrmMtoCajaFaseCobro }

procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
begin
  inherited; // Importante si heredas de TfrmBase

  // 1. Configurar tabla en memoria (VirtualTable)
  FMemTablePagos := TVirtualTable.Create(Self);
  with FMemTablePagos.FieldDefs do
  begin
    Add('NUMERO_LINEA', ftInteger);
    Add('CODIGO_FORMAP', ftString, 10);
    Add('DESCRIPCION', ftString, 100);
    Add('TIPO_COMPORTAMIENTO', ftString, 20); // EFECTIVO, TARJETA, ETC
    Add('ES_DEVUELVE_CAMBIO', ftString, 1);   // S/N
    Add('IMPORTE_ENTREGADO', ftCurrency);     // Lo que escribe el usuario
    Add('IMPORTE_CAMBIO', ftCurrency);        // Calculado internamente (visual)

    // Campos extra para pagos complejos (Divisas, Crypto, Referencias)
    Add('CODIGO_DIVISA', ftString, 10);
    Add('RED_BLOCKCHAIN', ftString, 50);
    Add('FACTOR_CAMBIO', ftCurrency);
    Add('IMPORTE_DIVISA', ftCurrency);
    Add('REFERENCIA', ftString, 255);
  end;

  FMemTablePagos.Open;
  dsFormasPago.DataSet := FMemTablePagos;

  // 2. Configurar Interfaz Inicial
  ConfigurarGridFormasPago;
  ConfigurarTeclasFuncion;

  // Valores por defecto seguros
  FImporteTotalInicial := 0;
  txtCantidadLineas.Text := '0';
  txtBrutoLineas.Value := 0;
  txtTotalPagar.Value := 0;
  txtPendienteCobro.Value := 0;

  // Si tienes un campo txtCambio, inicialízalo
  if Assigned(txtCambio) then txtCambio.Value := 0;
end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
begin
  inherited;

  // Mostrar datos de cabecera
  cbbSerie1.Text := FSerieOperacion;
  edtNumeroDoc.Text := FNumeroOperacion;

  // Cargar las formas de pago disponibles en el grid
  CargarFormasPagoEnGrid;

  // Primer cálculo para dejar todo cuadrado
  CalcularTotales;

  // Poner el foco en el grid (en el importe de la primera línea, usualmente Efectivo)
  if cxgrdFormasPago.CanFocus then
  begin
    cxgrdFormasPago.SetFocus;
    if dbtvFormasPago.Controller.SelectedRecordCount > 0 then
      dbtvFormasPago.Controller.FocusedColumn := dbmImporte;
  end;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarGridFormasPago;
begin
  // Asignar campos a columnas
  cxgrdbclmnCodigo.DataBinding.FieldName := 'CODIGO_FORMAP';
  dbmDescripcion.DataBinding.FieldName := 'DESCRIPCION';
  dbmImporte.DataBinding.FieldName := 'IMPORTE_ENTREGADO';

  // Formato visual de moneda
  with (dbmImporte.Properties as TcxCurrencyEditProperties) do
  begin
    DisplayFormat := ',0.00 €';
    Alignment.Horz := taRightJustify;
    Nullable := False;
  end;

  // Configurar comportamiento del Grid
  dbtvFormasPago.OptionsView.GroupByBox := False;
  dbtvFormasPago.OptionsView.ColumnAutoWidth := True;

  // Edición: Bloquear todo excepto el importe
  cxgrdbclmnCodigo.Options.Editing := False;
  cxgrdbclmnCodigo.Options.Focusing := False;
  cxgrdbclmnCodigo.Visible := False; // Ocultar código si no es necesario

  dbmDescripcion.Options.Editing := False;
  dbmDescripcion.Options.Focusing := False;

  dbmImporte.Options.Editing := True;
  dbmImporte.Options.Focusing := True;

  // Navegación fluida (Enter pasa a la siguiente fila)
  dbtvFormasPago.OptionsBehavior.GoToNextCellOnEnter := True;
  dbtvFormasPago.OptionsBehavior.FocusFirstCellOnNewRecord := True;
end;

procedure TfrmMtoCajaFaseCobro.CargarFormasPagoEnGrid;
var
  Qry: TUniQuery;
begin
  if not FMemTablePagos.Active then FMemTablePagos.Open;
  FMemTablePagos.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text := 'SELECT CODIGO_FORMAP, DESCRIPCION_FORMAP, ' +
                    '       TIPO_COMPORTAMIENTO_FORMAP, ES_DEVUELVE_CAMBIO_FORMAP ' +
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
      FMemTablePagos.FieldByName('TIPO_COMPORTAMIENTO').AsString := Qry.FieldByName('TIPO_COMPORTAMIENTO_FORMAP').AsString;
      FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO').AsString := Qry.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString;

      // Inicializar en 0
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := 0;
      FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;

      // Valores por defecto para campos técnicos
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;

      FMemTablePagos.Post;
      Qry.Next;
    end;

    // Posicionar cursor al inicio
    if not FMemTablePagos.IsEmpty then FMemTablePagos.First;

  finally
    Qry.Free;
  end;
end;

// -----------------------------------------------------------------------------
// LÓGICA DE CÁLCULO CENTRALIZADA (CORAZÓN DEL FORMULARIO)
// -----------------------------------------------------------------------------
procedure TfrmMtoCajaFaseCobro.CalcularTotales;
var
  cBruto, cDtoLineal, cBaseImp, cImpDtoGlobal, cTotalAPagar: Currency;
  cTotalEntregado, cPendiente, cCambio: Currency;
  bookmark: TBookmark;
begin
  // 1. Obtener Base: Bruto - Descuentos de Línea
  cBruto := txtBrutoLineas.Value;
  cDtoLineal := txtTotalDtoLineal.Value;
  cBaseImp := cBruto - cDtoLineal;

  // 2. Calcular Descuento Global (si aplica)
  if txtPorcenDtoGlobal.Value <> 0 then
    cImpDtoGlobal := cBaseImp * (txtPorcenDtoGlobal.Value / 100)
  else
    cImpDtoGlobal := txtDtoGlobal.Value; // Por si se metió el importe a mano

  // Actualizar UI del descuento global calculado
  // Evitamos disparar eventos recursivos si el valor es el mismo
  if txtDtoGlobal.Value <> cImpDtoGlobal then
     txtDtoGlobal.Value := cImpDtoGlobal;

  // 3. Total Final a Pagar
  cTotalAPagar := cBaseImp - cImpDtoGlobal;
  txtTotalPagar.Value := cTotalAPagar;

  // 4. Sumar lo que el usuario ha introducido en el Grid
  cTotalEntregado := 0;

  // Guardamos posición del dataset para no perder el foco visual
  FMemTablePagos.DisableControls;
  try
    bookmark := FMemTablePagos.GetBookmark;
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      cTotalEntregado := cTotalEntregado + FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
      FMemTablePagos.Next;
    end;
    if FMemTablePagos.BookmarkValid(bookmark) then
      FMemTablePagos.GotoBookmark(bookmark);
  finally
    FMemTablePagos.FreeBookmark(bookmark);
    FMemTablePagos.EnableControls;
  end;

  // 5. Calcular Pendiente y Cambio
  cPendiente := 0;
  cCambio := 0;

  if cTotalEntregado >= cTotalAPagar then
  begin
    // Se ha cubierto el total
    cPendiente := 0;
    cCambio := cTotalEntregado - cTotalAPagar;
  end
  else
  begin
    // Falta dinero
    cPendiente := cTotalAPagar - cTotalEntregado;
    cCambio := 0;
  end;

  // 6. Actualizar UI final
  txtPendienteCobro.Value := cPendiente;
  txtPendienteCuenta.Value := cPendiente;

  if Assigned(txtCambio) then
    txtCambio.Value := cCambio;
  if cPendiente > 0 then
  begin
    btnF12.Enabled := True;
    btnConTicket.Enabled := True;
  end
  else
  begin
    btnF12.Enabled := False;
    btnConTicket.Enabled := False;
  end;
end;

procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
begin
  // Al cambiar el porcentaje, recalcular todo
  CalcularTotales;
end;

procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(Sender: TObject);
begin
  // IMPORTANTE: Forzar el post de datos editados para que el cálculo vea los nuevos valores
  dbtvFormasPago.DataController.Post;
  CalcularTotales;
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
var
  PorcentajeMedio: Double;
begin
  if TotalesFactura = nil then Exit;

  FImporteTotalInicial := TotalesFactura.Totales.TotalLiquido;

  // Cargar campos visuales
  txtCantidadLineas.Text := FormatFloat('0.##', TotalesFactura.Totales.TotalCantidades);
  txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
  txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;

  // Calcular % visual informativo de los descuentos de línea
  if TotalesFactura.Totales.TotalBruto <> 0 then
  begin
    PorcentajeMedio := (TotalesFactura.Totales.TotalDescuentosLineas / TotalesFactura.Totales.TotalBruto) * 100;
    txtPorcenDtoLineal.Text := FormatFloat('0.## %', PorcentajeMedio);
  end
  else
    txtPorcenDtoLineal.Text := '0 %';

  // Inicializar Totales
  CalcularTotales;
end;

function TfrmMtoCajaFaseCobro.ValidarPagos: Boolean;
var
  TotalEntregado: Currency;
begin
  Result := False;

  // Asegurar cálculos frescos
  CalcularTotales;

  // 1. Verificar si hay deuda pendiente
  if txtPendienteCobro.Value > 0.01 then // Margen de 1 céntimo por redondeos
  begin
    if MessageDlg(Format('El cobro no está completo.' + sLineBreak +
                         'Pendiente: %m' + sLineBreak +
                         '¿Desea dejarlo como Pendiente/Deuda?', [txtPendienteCobro.Value]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      Exit;

    // Aquí podrías agregar lógica para generar automáticamente una línea de "DEUDA"
    // por el restante si tu lógica de negocio lo requiere.
  end;

  // 2. Verificar que haya algo "movido" (no guardar ticket con todo a 0 si no es deuda)
  TotalEntregado := 0;
  FMemTablePagos.First;
  while not FMemTablePagos.Eof do
  begin
    TotalEntregado := TotalEntregado + FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
    FMemTablePagos.Next;
  end;

  if (TotalEntregado = 0) and (txtPendienteCobro.Value = 0) and (txtTotalPagar.Value > 0) then
  begin
    ShowMessage('No se ha indicado ningún pago.');
    Exit;
  end;

  Result := True;
end;

function TfrmMtoCajaFaseCobro.ObtenerDatosPagos: TArray<TFormaPagoItem>;
var
  Lista: TList<TFormaPagoItem>;
  Item: TFormaPagoItem;
  TotalPagar, TotalEntregado, RestanteParaCambio: Currency;
  EsEfectivo: Boolean;
begin
  // Lógica inteligente para distribuir el Cambio solo en las líneas que lo permiten
  CalcularTotales;
  TotalPagar := txtTotalPagar.Value;

  // Si hay cambio, calcular cuánto sobra
  if Assigned(txtCambio) then
    RestanteParaCambio := txtCambio.Value
  else
    RestanteParaCambio := 0;

  Lista := TList<TFormaPagoItem>.Create;
  try
    FMemTablePagos.DisableControls;
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      // Solo procesamos líneas con importe > 0
      if FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency > 0 then
      begin
        Item.NumeroLinea := FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger;
        Item.CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
        Item.DescripcionFormaPago := FMemTablePagos.FieldByName('DESCRIPCION').AsString;
        Item.CodigoDivisa := FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
        Item.RedBlockchain := FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString;
        Item.FactorCambio := FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency;

        Item.ImporteEntregado := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;

        // Calcular Cambio Específico para SQL (fza_caja_pagos.IMPORTE_CAMBIO_PAGO)
        Item.ImporteCambio := 0;
        EsEfectivo := FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO').AsString = 'S';

        if (RestanteParaCambio > 0) and EsEfectivo then
        begin
          // Asignamos el cambio a esta línea de efectivo
          Item.ImporteCambio := RestanteParaCambio;
          RestanteParaCambio := 0; // Ya hemos asignado todo el cambio
        end;

        Item.Referencia := FMemTablePagos.FieldByName('REFERENCIA').AsString;

        Lista.Add(Item);
      end;
      FMemTablePagos.Next;
    end;
    Result := Lista.ToArray;
  finally
    FMemTablePagos.EnableControls;
    Lista.Free;
  end;
end;

// -----------------------------------------------------------------------------
// EVENTOS DE TECLADO Y BOTONES DE NAVEGACIÓN
// -----------------------------------------------------------------------------

procedure TfrmMtoCajaFaseCobro.ConfigurarTeclasFuncion;
begin
  KeyPreview := True; // Permite al formulario capturar teclas antes que los controles
end;

procedure TfrmMtoCajaFaseCobro.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2: if btnMasDatos.Enabled then btnMasDatos.Click;
    VK_F3: if btnBuscarT.Enabled then btnBuscarT.Click;
    VK_F6: if btnBuscarVale.Enabled then btnBuscarVale.Click;
    VK_F7: if btnDeposito.Enabled then btnDeposito.Click;
    VK_F8: if btnFactura.Enabled then btnFactura.Click;
    VK_F10: if btnSinPrecios.Enabled then btnSinPrecios.Click;
    VK_F11: if btnSinTicket.Enabled then btnSinTicket.Click;
    VK_F12: if btnConTicket.Enabled then btnConTicket.Click;
    VK_ESCAPE: btnAtras.Click;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  if MessageDlg('¿Desea cancelar el proceso de cobro?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ModalResult := mrCancel;
end;

procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  btnAtrasClick(Sender);
end;

end.
