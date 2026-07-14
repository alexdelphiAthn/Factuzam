{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaFaseCobro                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de la fase de cobro de caja (TPV).                             }
{    Calcula totales, gestiona formas de pago, vales y tickets.                }
{******************************************************************************}
unit inMtoCajaFaseCobro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, Math,
  // Componentes DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxGrid, cxDropDownEdit, dxDateRanges, dxScrollbarAnnotations,
  cxCheckBox,
  // Acceso a Datos y Librerías Propias
  Uni, MemDS, VirtualTable,
  inLibGlobalVar, inMtoFrmBase, inLibFacturas, inLibFaseCobro,
  inMtoCajaReferenciaPago, System.UITypes, dxGDIPlusClasses, cxImage;

type
  TTipoImpresionTicket = (tiConTicket, tiSinTicket, tiTicketRegalo,
                          tiFactura);
  TfrmMtoCajaFaseCobro = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlIzquierdo: TPanel;
    pnlDerecho: TPanel;
    dsFormasPago: TDataSource;
    txtTotalPagar: TcxCurrencyEdit;
    txtPendienteCobro: TcxCurrencyEdit;
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalDtoLineal: TcxCurrencyEdit;
    txtPorcenDtoGlobal: TcxCurrencyEdit;
    txtDtoGlobal: TcxCurrencyEdit;
    lblNumDoc: TcxLabel;
    edtNumeroDoc: TcxTextEdit;
    cbbSERIE_FAC: TcxComboBox;
    pnlCuenta: TPanel;
    lblPendienteCobro: TcxLabel;
    lblImporteACuenta: TcxLabel;
    txtDejarCuenta: TcxCurrencyEdit;
    txtPendienteCuenta: TcxCurrencyEdit;
    pnlCambioVales: TPanel;
    lblValeEmitido: TcxLabel;
    lblValeRecogido: TcxLabel;
    txtValeRecogido: TcxCurrencyEdit;
    txtValeEmitido: TcxCurrencyEdit;
    txtCambio: TcxCurrencyEdit;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    dbmImporte: TcxGridDBColumn;
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
    alFaseCobro: TActionList;
    actSalir: TAction;
    pnlLogoLeft: TPanel;
    pnlContenedor: TPanel;
    pnlTotales: TPanel;
    lblImporteDtoLineal: TcxLabel;
    lblImporteTotalAPagar: TcxLabel;
    lblDescuento: TcxLabel;
    lblSuma: TcxLabel;
    // Edits de Importes
    cxgrdlvlFormasPago: TcxGridLevel;
    // Columnas Grid
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    // Panel Inferior (Totales finales)
    lblPendienteCobroAlt: TcxLabel;
    lblDevolucionCambio: TcxLabel;
    styRepoCobro: TcxStyleRepository;
    styCobroLine: TcxStyle;
    dbtvFormasPagoESDIVISA_FORMA_PAGO_CFP: TcxGridDBColumn;
    dbtvFormasPagoESCRIPTO_FORMA_PAGO_CFP: TcxGridDBColumn;
    dbtvFormasPagoESIMPORTE_DIVISA: TcxGridDBColumn;
    actRellenar: TAction;
    actBuscarVale: TAction;
    actSinTicket: TAction;
    actConTicket: TAction;
    actSinPrecios: TAction;
    actDepositoCliente: TAction;
    actFactura: TAction;
    cxImage1: TcxImage;
    imgEnviarEmail: TImage;
    chkEnviarEmail: TcxCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure btnESCClick(Sender: TObject);
    procedure dbmImporteGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure txtValeEmitidoPropertiesEditValueChanged(Sender: TObject);
    procedure dbtvFormasPagoEditChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure btnBuscarTClick(Sender: TObject);
    procedure btnF3Click(Sender: TObject);
    procedure actRellenarExecute(Sender: TObject);
    procedure btnBuscarValeClick(Sender: TObject);
    procedure btnF6Click(Sender: TObject);
    procedure dbtvFormasPagoEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure actBuscarValeExecute(Sender: TObject);
    procedure btnSinTicketClick(Sender: TObject);
    procedure btnConTicketClick(Sender: TObject);
    procedure btnSinPreciosClick(Sender: TObject);
    procedure btnF7Click(Sender: TObject);
    procedure actSinTicketExecute(Sender: TObject);
    procedure actConTicketExecute(Sender: TObject);
    procedure actSinPreciosExecute(Sender: TObject);
    procedure actDepositoClienteExecute(Sender: TObject);
    procedure btnDepositoClick(Sender: TObject);
    procedure btnFacturaClick(Sender: TObject);
    procedure actFacturaExecute(Sender: TObject);
    procedure chkEnviarEmailPropertiesEditValueChanged(Sender: TObject);
  private
    FTipoImpresion: TTipoImpresionTicket;
    FDatosCobro: TDatosFaseCobro;
    FMemTablePagos: TVirtualTable;
    FActualizandoVale: Boolean;
    FEmailEnvio: string;
    FActualizandoEmail: Boolean;
    function ValidaryConfirmar:boolean;
    function PuedeEmitir(const ASerie: string; AFecha: TDateTime): Boolean;
    function SerieAdmiteFecha(const ASerie: string;
      AFecha: TDateTime): Boolean;
    procedure AvisarSiNumeracionConHuecos(const ASerie: string);
    function NumeroManualIntroducido: string;
    function ValidarHuecoManual(const ASerie, ANumero: string;
      out ANumeroFmt: string): Boolean;
    procedure CargarFormasPago;
    procedure CargarComboSeries;
    procedure AjustarFormatoEditorActivo;
    procedure ActualizarInterfaz;
    procedure ConfigurarTablaVirtual;
    procedure ConfigurarModoDevolucion;
    procedure ConfigurarModoCobroNormal;
    procedure RellenarPendienteEnFormaActual;
    procedure EscribirImporteEnFormaActual(AImporte: Double);
    procedure MemTablePagosAfterPost(DataSet: TDataSet);
    procedure FMemTablePagosBeforePost(DataSet: TDataSet);
    procedure DibujarIconoEmail;
    function GetEnviarEmail: Boolean;
  public
    property DatosCobro: TDatosFaseCobro read FDatosCobro;
    property TipoImpresion: TTipoImpresionTicket read FTipoImpresion;
    property EnviarEmail: Boolean read GetEnviarEmail;
    property EmailEnvio: string read FEmailEnvio;
  public
    FCodigoEmpresa:String;
    FCodigoCliente: String;
    FEmailCliente: String;
    FNifCliente: String;
    FCodigoPaisCliente: String;
    FNombrePaisCliente: String;
    FSerieFactura: String;
    FFechaFactura: TDateTime;
    FNumeroManual: String;
    // 'serie\numero' del ticket rectificado: activa el modo
    // rectificación (series de subtipo RECTIFICATIVA y aviso en caption)
    FRectificaA: String;
    FCodigoAlmacen, FCodigoCaja:String;
    FFecha:TDate;
    FHayLineasDeposito: Boolean;
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
    procedure AlRecalcularDatos(Sender: TObject);
    function AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                  ADatosActuales: TDatosReferencia): Boolean;
  end;

implementation

{$R *.dfm}

uses inMtoCajaSeleccionVale, inLibCajaParam, inMtoModalSerieFechaFactura,
     UniDataCaja, inLibDocumentoFiscal, inLibCorreoTickets;

procedure TfrmMtoCajaFaseCobro.CargarComboSeries;
var
  qry: TUniQuery;
  sSubtipo: string;
begin
  // En modo rectificación el documento sale con serie rectificativa
  // (subtipo RECTIFICATIVA de fza_empresas_series)
  if FRectificaA <> '' then
    sSubtipo := 'RECTIFICATIVA'
  else
    sSubtipo := 'SIMPLIFICADA';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    // Series propias del almacen/caja y tambien las genericas de la
    // empresa (almacen/caja a NULL), p.ej. la rectificativa R1
    qry.SQL.Text := 'SELECT EMPSER AS SERIE_CON              ' +
                    '  FROM vi_empresas_series                         ' +
                    ' WHERE CODIGO_EMP_EMPSER = :EMPRESA            ' +
                    '   AND (CODIGO_ALM_EMPSER = :ALMACEN            ' +
                    '        OR IFNULL(CODIGO_ALM_EMPSER, '''') = '''') ' +
                    '   AND (CODIGO_CAJA_EMPSER = :CAJA                 ' +
                    '        OR IFNULL(CODIGO_CAJA_EMPSER, '''') = '''') ' +
                    '   AND TIPO_DOC_EMPSER     = ' + QuotedStr('FC')      +
                    '   AND SUBTIPO_EMPSER = ' + QuotedStr(sSubtipo) +
                    '   AND (FECHA_DESDE_EMPSER <= :FECHA               ' +
                    '        AND (FECHA_HASTA_EMPSER >= :FECHA          ' +
                    '             OR FECHA_HASTA_EMPSER IS NULL ))      ';
    qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('CAJA').AsString := FCodigoCaja;
    qry.ParamByName('FECHA').AsDateTime := FFecha;
    qry.Open;
    cbbSERIE_FAC.Properties.Items.BeginUpdate;
    try
      cbbSERIE_FAC.Properties.Items.Clear;
      while not qry.Eof do
      begin
        cbbSERIE_FAC.Properties.Items.Add(qry.FieldByName('SERIE_CON').AsString);
        qry.Next;
      end;
    finally
      cbbSERIE_FAC.Properties.Items.EndUpdate;
    end;
    if cbbSERIE_FAC.Properties.Items.Count > 0 then
    begin
//      SerieDefecto := oCajaParams.GetString('vgerDefSerieCaja', 'T');
//      cbbSERIE_FAC.ItemIndex := cbbSERIE_FAC.Properties.Items.IndexOf(SerieDefecto);
      if cbbSERIE_FAC.ItemIndex = -1 then
        cbbSERIE_FAC.ItemIndex := 0;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnConTicketClick(Sender: TObject);
begin
  if ValidarYConfirmar and PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiConTicket;
    ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnDepositoClick(Sender: TObject);
begin
  inherited;
  btnF7Click(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnFacturaClick(Sender: TObject);
var
  oDatos: TSerieFechaFacturaResult;
begin
  //F8 -> grabar la venta como factura completa (A4), no como ticket
  if FRectificaA <> '' then
    ShowMessage('Una rectificación se cierra como ticket rectificativo,' +
                ' no como borrador normal.')
  else if (Trim(FCodigoCliente) = '') or (Trim(FCodigoCliente) = '0') then
    ShowMessage('Asigne un cliente a la operación para emitir borrador.')
  else if Trim(FNifCliente) = '' then
    ShowMessage('El cliente no tiene NIF: complételo en su ficha para ' +
                'poder emitir borrador normal.')
  else if PaisEsEspana(FCodigoPaisCliente, FNombrePaisCliente) and
          (not DocumentoFiscalValido(FNifCliente)) then
    ShowMessage('El NIF/CIF/NIE del cliente no es valido: ' +
                MensajeDocumentoFiscalInvalido(FNifCliente))
  else if ValidarYConfirmar then
  begin
    // Serie de factura completa (por defecto la del almacén) y fecha
    oDatos := TfrmModalSerieFechaFactura.Ejecutar(Self, FCodigoEmpresa,
                                                  FCodigoAlmacen);
    if oDatos.Aceptado then
    begin
      if SerieAdmiteFecha(oDatos.Serie, oDatos.Fecha) then
      begin
        AvisarSiNumeracionConHuecos(oDatos.Serie);
        FNumeroManual  := '';
        FSerieFactura  := oDatos.Serie;
        FFechaFactura  := oDatos.Fecha;
        FTipoImpresion := tiFactura;
        ModalResult    := mrOk;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.actFacturaExecute(Sender: TObject);
begin
  //F8 -> Factura completa
  btnFacturaClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnSinTicketClick(Sender: TObject);
begin
  if ValidarYConfirmar and PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiSinTicket;
    ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnSinPreciosClick(Sender: TObject);
begin
  if ValidarYConfirmar and PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiTicketRegalo;
    ModalResult := mrOk;
  end;
end;

function TfrmMtoCajaFaseCobro.ValidarYConfirmar: Boolean;
var
  Res: TResultadoValidacion;
begin
  // 1. Si hay un editor inline activo en el grid, forzar que vuelque su valor
  if dbtvFormasPago.Controller.EditingController.IsEditing then
    dbtvFormasPago.Controller.EditingController.HideEdit(True); // True = Post

  // 2. Si el dataset está en edición o inserción, postear
  if FMemTablePagos.State in [dsEdit, dsInsert] then
    FMemTablePagos.Post;

  // 3. Asegurar que los totales reflejan el último cambio
  FDatosCobro.Recalcular;

  // 4. Ahora sí, validar con datos consistentes
  Res := FDatosCobro.ValidarParaCobro;
  if not Res.Valido then
  begin
    MessageDlg(Res.Mensaje, mtError, [mbOK], 0);
    Result := False;
  end
  else
    Result := True;
end;

function TfrmMtoCajaFaseCobro.SerieAdmiteFecha(const ASerie: string;
  AFecha: TDateTime): Boolean;
var
  dUltima: TDateTime;
begin
  // El ticket no puede llevar una fecha anterior a la del ultimo documento
  // ya emitido en la misma serie. Si lo es, se avisa y NO se cierra la fase
  // de cobro, para elegir otra serie sin perder las formas de pago.
  Result := True;
  dUltima := TdmCajaOpe.FechaUltimoTicketSerie(FCodigoEmpresa, ASerie);
  if (dUltima > 0) and (Trunc(AFecha) < Trunc(dUltima)) then
  begin
    Result := False;
    MessageDlg(
      Format('No se puede emitir en la serie "%s".' + sLineBreak +
             'El último ticket de esa serie tiene fecha %s, posterior ' +
             'a la fecha %s.' + sLineBreak +
             'Elija otra serie para emitir con esta fecha.',
             [ASerie,
              FormatDateTime('dd/mm/yyyy', dUltima),
              FormatDateTime('dd/mm/yyyy', AFecha)]),
      mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoCajaFaseCobro.AvisarSiNumeracionConHuecos(
  const ASerie: string);
var
  Qry: TUniQuery;
  iFilas, iMin, iMax: Int64;
begin
  // Aviso (no bloqueante): comprueba que la numeracion de la serie no tenga
  // huecos (que cada numero tenga su anterior). Si faltan numeros no se
  // cumple la correlatividad legal; aqui solo se recuerda al usuario.
  if Trim(ASerie) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := oConn;
      Qry.SQL.Text :=
        'SELECT COUNT(*) AS NFILAS, ' +
        '       MIN(CAST(NUMERO_FAC AS UNSIGNED)) AS NMIN, ' +
        '       MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS NMAX ' +
        '  FROM fza_facturas ' +
        ' WHERE CODIGO_EMP_FAC = :EMP ' +
        '   AND SERIE_FAC      = :SERIE';
      Qry.ParamByName('EMP').AsString   := FCodigoEmpresa;
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.Open;
      iFilas := Qry.FieldByName('NFILAS').AsLargeInt;
      iMin   := Qry.FieldByName('NMIN').AsLargeInt;
      iMax   := Qry.FieldByName('NMAX').AsLargeInt;
      if (iFilas > 0) and (iFilas <> iMax - iMin + 1) then
        MessageDlg(
          Format('La serie "%s" tiene huecos en la numeración: faltan %d ' +
                 'números entre el %d y el %d.' + sLineBreak +
                 'Recuerde que la numeración debe ser correlativa según la ' +
                 'ley.',
                 [ASerie, (iMax - iMin + 1) - iFilas, iMin, iMax]),
          mtWarning, [mbOK], 0);
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TfrmMtoCajaFaseCobro.NumeroManualIntroducido: string;
var
  s: string;
begin
  // Vacio o todo ceros (placeholder '00000000') => numeracion automatica.
  s := Trim(edtNumeroDoc.Text);
  if StrToInt64Def(s, 0) = 0 then
    Result := ''
  else
    Result := s;
end;

function TfrmMtoCajaFaseCobro.ValidarHuecoManual(const ASerie, ANumero: string;
  out ANumeroFmt: string): Boolean;
var
  Qry: TUniQuery;
  iNum, iMin, iMax, iExiste: Int64;
  iLen: Integer;
begin
  // Solo se admite un numero que rellene un hueco real de la serie: que no
  // exista ya y que este entre el minimo y el maximo. Devuelve el numero
  // formateado con los digitos de la serie.
  Result := False;
  ANumeroFmt := '';
  iNum := StrToInt64Def(Trim(ANumero), 0);
  if iNum <= 0 then
    MessageDlg('El número de borrador indicado no es válido.',
      mtError, [mbOK], 0)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := oConn;
      Qry.SQL.Text :=
        'SELECT MIN(CAST(NUMERO_FAC AS UNSIGNED)) AS NMIN, ' +
        '       MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS NMAX, ' +
        '       MAX(LENGTH(NUMERO_FAC))           AS NLEN, ' +
        '       SUM(CASE WHEN CAST(NUMERO_FAC AS UNSIGNED) = :NUM ' +
        '                THEN 1 ELSE 0 END)        AS NEXISTE ' +
        '  FROM fza_facturas ' +
        ' WHERE CODIGO_EMP_FAC = :EMP ' +
        '   AND SERIE_FAC      = :SERIE';
      Qry.ParamByName('NUM').AsLargeInt := iNum;
      Qry.ParamByName('EMP').AsString   := FCodigoEmpresa;
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.Open;
      iMin    := Qry.FieldByName('NMIN').AsLargeInt;
      iMax    := Qry.FieldByName('NMAX').AsLargeInt;
      iLen    := Qry.FieldByName('NLEN').AsInteger;
      iExiste := Qry.FieldByName('NEXISTE').AsLargeInt;
      if iExiste > 0 then
        MessageDlg(Format('El número %d ya existe en la serie "%s".',
          [iNum, ASerie]), mtError, [mbOK], 0)
      else if (iMax <= iMin) or (iNum <= iMin) or (iNum >= iMax) then
        MessageDlg(Format('El número %d no es un hueco de la serie "%s": ' +
          'los huecos están entre el %d y el %d.',
          [iNum, ASerie, iMin, iMax]), mtError, [mbOK], 0)
      else
      begin
        ANumeroFmt := IntToStr(iNum);
        while Length(ANumeroFmt) < iLen do
          ANumeroFmt := '0' + ANumeroFmt;
        Result := True;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TfrmMtoCajaFaseCobro.PuedeEmitir(const ASerie: string;
  AFecha: TDateTime): Boolean;
var
  sManual, sNumeroFmt: string;
begin
  // Decide entre relleno de hueco (numero manual escrito en 'Nº doc. venta')
  // y emision normal con numeracion automatica.
  sManual := NumeroManualIntroducido;
  if sManual <> '' then
  begin
    // Relleno de hueco: validar el numero; no aplica el control de fecha,
    // el documento del hueco lleva su propia fecha (normalmente anterior).
    Result := ValidarHuecoManual(ASerie, sManual, sNumeroFmt);
    if Result then
      FNumeroManual := sNumeroFmt;
  end
  else
  begin
    // Emision normal: control de fecha y aviso (no bloqueante) de huecos.
    FNumeroManual := '';
    Result := SerieAdmiteFecha(ASerie, AFecha);
    if Result then
      AvisarSiNumeracionConHuecos(ASerie);
  end;
end;

function TfrmMtoCajaFaseCobro.AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                     ADatosActuales: TDatosReferencia): Boolean;
var
  DatosRef: TDatosReferencia;
begin
  DatosRef := ADatosActuales;
  Result := TfrmCajaReferenciaPago.Ejecutar(AInfo,
                                            txtPendienteCobro.value,
                                            DatosRef);
end;

procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
begin
  inherited;
  FActualizandoEmail := False;
  FEmailEnvio := '';
  chkEnviarEmail.Checked := False;
  DibujarIconoEmail;
  ConfigurarTablaVirtual;
  FDatosCobro := TDatosFaseCobro.Create(FMemTablePagos);
  FDatosCobro.OnRecalculado := AlRecalcularDatos;
  FDatosCobro.OnRequiereReferencia := AlRequerirReferencia;
//  CargarFormasPago;
  dsFormasPago.DataSet := FMemTablePagos;
  FMemTablePagos.AfterPost := MemTablePagosAfterPost;
  FMemTablePagos.BeforePost := FMemTablePagosBeforePost;
end;

procedure TfrmMtoCajaFaseCobro.DibujarIconoEmail;
var
  Lienzo: TCanvas;
begin
  imgEnviarEmail.Picture.Bitmap.SetSize(24, 18);
  imgEnviarEmail.Picture.Bitmap.PixelFormat := pf32bit;
  imgEnviarEmail.Picture.Bitmap.TransparentColor := clFuchsia;
  imgEnviarEmail.Picture.Bitmap.Transparent := True;
  Lienzo := imgEnviarEmail.Picture.Bitmap.Canvas;
  Lienzo.Brush.Color := clFuchsia;
  Lienzo.FillRect(Rect(0, 0, 24, 18));
  Lienzo.Brush.Style := bsClear;
  Lienzo.Pen.Color := clNavy;
  Lienzo.Pen.Width := 2;
  Lienzo.Rectangle(1, 2, 23, 17);
  Lienzo.MoveTo(2, 3);
  Lienzo.LineTo(12, 11);
  Lienzo.LineTo(22, 3);
  Lienzo.MoveTo(2, 16);
  Lienzo.LineTo(9, 9);
  Lienzo.MoveTo(22, 16);
  Lienzo.LineTo(15, 9);
end;

function TfrmMtoCajaFaseCobro.GetEnviarEmail: Boolean;
begin
  Result := chkEnviarEmail.Checked and (Trim(FEmailEnvio) <> '');
end;

procedure TfrmMtoCajaFaseCobro.chkEnviarEmailPropertiesEditValueChanged(
  Sender: TObject);
var
  sMensaje: string;
  bContinuar: Boolean;
begin
  if not FActualizandoEmail then
  begin
    if chkEnviarEmail.Checked then
    begin
      bContinuar := CorreoTicketsConfigurado(sMensaje);
      if not bContinuar then
        ShowMessage(sMensaje)
      else
      begin
        FEmailEnvio := Trim(FEmailEnvio);
        if FEmailEnvio = '' then
          bContinuar := InputQuery('Enviar documentación',
            'Correo electrónico:', FEmailEnvio);
        if bContinuar and (Trim(FEmailEnvio) = '') then
        begin
          ShowMessage('Indique una dirección de correo electrónico.');
          bContinuar := False;
        end;
      end;
      if not bContinuar then
      begin
        FActualizandoEmail := True;
        try
          chkEnviarEmail.Checked := False;
        finally
          FActualizandoEmail := False;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.FMemTablePagosBeforePost(DataSet: TDataSet);
var
  Importe: Currency;
  EsDivisa, EsCripto: Boolean;
begin
  // Protección: no permitir borrar líneas de vales
  if (DataSet.State = dsEdit) and
     (DataSet.FieldByName('CODIGO_FP_CFP').AsString = 'VALE') then
  begin
    // Si es un vale, solo permitir cambiar el importe a 0 para "desactivarlo"
    // pero mejor aún, impedirlo totalmente
    Exit; // O puedes decidir si permites editar vales o no
  end;

  Importe := DataSet.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
  EsDivisa := DataSet.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S';
  EsCripto := DataSet.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S';
  if Abs(Importe) < 0.01 then
  begin
    DataSet.FieldByName('REFERENCIA').AsString := '';
//    DataSet.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
    DataSet.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;
    DataSet.FieldByName('IMPORTE_DIVISA').AsFloat := 0;
    DataSet.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
    if EsDivisa or EsCripto then
      DataSet.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
  end;
end;

procedure TfrmMtoCajaFaseCobro.MemTablePagosAfterPost(DataSet: TDataSet);
begin
  if Assigned(FDatosCobro) then
    FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDatosCobro) then
    FreeAndNil(FDatosCobro);
end;

procedure TfrmMtoCajaFaseCobro.CargarFormasPago;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := '  SELECT * ' +
                    '    FROM fza_caja_formas_pago ' +
                    '   WHERE ESACTIVO_FORMA_PAGO_CFP = ''S'' ' +
                    'ORDER BY ORDEN_VISUAL_FORMA_PAGO_CFP';
    qry.Open;

    with FMemTablePagos do
    begin
      if Active then Close;
      FieldDefs.Clear;
      Fields.Clear;
      // Copiar FieldDefs desde la query
      FieldDefs.Assign(qry.FieldDefs);
      // Añadir campos extra que no vienen de BD
      FieldDefs.Add('FACTOR_CAMBIO',      ftCurrency);
      FieldDefs.Add('ESIMPORTE_DIVISA',   ftString, 1);
      FieldDefs.Add('REFERENCIA',         ftString, 255);
      FieldDefs.Add('IMPORTE_ENTREGADO',  ftFloat);
      FieldDefs.Add('IMPORTE_DIVISA',     ftFloat);
      FieldDefs.Add('IMPORTE_CAMBIO',     ftCurrency);
      FieldDefs.Add('CODIGO_DIVISA',      ftString, 6);
      Open;
      // Ahora cargar los datos desde la query
      DisableControls;
      try
        qry.First;
        while not qry.Eof do
        begin
          Append;
          // Copiar campos que existen en ambos
          var i: Integer;
          for i := 0 to qry.FieldCount - 1 do
          begin
            var F := FindField(qry.Fields[i].FieldName);
            if Assigned(F) and not qry.Fields[i].IsNull then
              F.Value := qry.Fields[i].Value;
          end;
          // Valores por defecto para campos extra
          FieldByName('FACTOR_CAMBIO').AsCurrency    := 1;
          FieldByName('ESIMPORTE_DIVISA').AsString   := 'S';
          FieldByName('REFERENCIA').AsString         := '';
          FieldByName('IMPORTE_ENTREGADO').AsFloat   := 0;
          FieldByName('IMPORTE_DIVISA').AsFloat      := 0;
          FieldByName('IMPORTE_CAMBIO').AsCurrency   := 0;
          FieldByName('CODIGO_DIVISA').AsString      := 'EUR';
          Post;
          qry.Next;
        end;
        First;
      finally
        EnableControls;
      end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaFaseCobro.RellenarPendienteEnFormaActual;
var
  Pendiente: Currency;
begin
  if not (FMemTablePagos.Active and not FMemTablePagos.IsEmpty) then
    Exit;
  if FDatosCobro.EsDevolucionEconomica then
    Pendiente := FDatosCobro.ImporteDevolucionPendiente
  else
    Pendiente := FDatosCobro.ImportePendiente;
  if Pendiente <= 0.01 then Exit;
  if FDatosCobro.EsDevolucionEconomica then
    EscribirImporteEnFormaActual(-Pendiente)
  else
    EscribirImporteEnFormaActual(Pendiente);
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarTablaVirtual;
begin
  FMemTablePagos := TVirtualTable.Create(Self);
end;

procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(
  Sender: TObject);
var
  ImporteActual: Double;
  v: Variant;
begin
  ImporteActual := 0;
  if Sender is TcxCurrencyEdit then
  begin
    v := TcxCurrencyEdit(Sender).EditingValue;
    if not (VarIsNull(v) or VarIsEmpty(v)) then
      ImporteActual := Double(v);
  end
  else if Sender is TcxCustomEdit then
  begin
    TcxCustomEdit(Sender).PostEditValue;
    ImporteActual := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;
  end;
  if Abs(ImporteActual) < 0.0000000001 then
    Exit;
  if FDatosCobro.EsDevolucionEconomica then
  begin
    FDatosCobro.Recalcular; // actualiza pendiente antes de abrir diálogo
    EscribirImporteEnFormaActual(-Abs(ImporteActual));
  end
  else
    EscribirImporteEnFormaActual(ImporteActual);
end;

procedure TfrmMtoCajaFaseCobro.AjustarFormatoEditorActivo;
var
  EsCripto, EsDivisa: Boolean;
  EditProps: TcxCurrencyEditProperties;
  ActiveEdit: TcxCustomEdit;
begin
  EsCripto :=
    (FMemTablePagos.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S');
  EsDivisa :=
    (FMemTablePagos.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S');
  ActiveEdit := dbtvFormasPago.Controller.EditingController.Edit;
  if not Assigned(ActiveEdit) then Exit;
  if not (ActiveEdit is TcxCurrencyEdit) then Exit;
  EditProps := TcxCurrencyEditProperties(
                 TcxCurrencyEdit(ActiveEdit).ActiveProperties);
  if EsCripto then
  begin
    EditProps.DecimalPlaces := 9;
    EditProps.DisplayFormat := '#,##0.#########';
    EditProps.EditFormat    := '#########0.#########';
  end
  else
    if EsDivisa then
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00';
      EditProps.EditFormat    := ',0.00';
    end
    else
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00 €';
      EditProps.EditFormat    := ',0.00 €';
    end;
end;

procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
begin
  inherited;
  if AItem <> dbmImporte then
    Exit;
  AjustarFormatoEditorActivo;
end;

procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString = 'VALE' then
    AAllow := False;
end;

procedure TfrmMtoCajaFaseCobro.EscribirImporteEnFormaActual(AImporte: Double);
var
  fp: TFormaPagoInfo;
  dr: TDatosReferencia;
  EsDivisa, EsCripto: Boolean;
begin
  EsDivisa :=
    FMemTablePagos.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S';
  EsCripto  :=
    FMemTablePagos.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S';
  fp.Codigo := FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
  fp.Descripcion :=
    FMemTablePagos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString;
  fp.RequiereReferencia :=
          FMemTablePagos.FieldByName(
            'ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString = 'S';
  dr.Init;
  dr.EsDivisa  := EsDivisa;
  dr.EsCripto  := EsCripto;
  dr.Pendiente := txtPendienteCobro.Value;
  if EsDivisa or EsCripto or fp.RequiereReferencia then
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.Post;
    if TfrmCajaReferenciaPago.Ejecutar(fp, Abs(AImporte), dr) then
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := dr.Referencia;
      if EsDivisa then
      begin
        FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    :=
                                                               dr.ImporteDivisa;
        FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency  :=
                                                                dr.FactorCambio;
        FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
        FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat :=
                                                                dr.ImporteEuros;
      end;
      FMemTablePagos.Post;
    end
    else
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := '';
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    := 0;
      FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
      FMemTablePagos.Post;
    end;
  end
  else
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
    FMemTablePagos.Post;
  end;
  FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.dbmImporteGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
var
  EsDivisa: Boolean;
  Importe: Currency;
  RecordIndex: Integer;
  IdxDivisa, IdxCripto, IdxImporte, IdxEsDivisa: Integer;
  vImporte, vEsDivisa: Variant;
begin
  RecordIndex := ARecord.RecordIndex;
  if RecordIndex < 0 then Exit;
  var DC := dbtvFormasPago.DataController;
  IdxDivisa  := DC.GetItemByFieldName('ESDIVISA_FORMA_PAGO_CFP').Index;
  IdxCripto  := DC.GetItemByFieldName('ESCRIPTO_FORMA_PAGO_CFP').Index;
  IdxImporte := DC.GetItemByFieldName('IMPORTE_ENTREGADO').Index;
  IdxEsDivisa := DC.GetItemByFieldName('ESIMPORTE_DIVISA').Index;
  EsDivisa :=
    (VarToStr(DC.Values[RecordIndex, IdxDivisa]) = 'S') or
    (VarToStr(DC.Values[RecordIndex, IdxCripto]) = 'S');
  if EsDivisa then
  begin
    vImporte := DC.Values[RecordIndex, IdxImporte];
    if VarIsNull(vImporte) or VarIsEmpty(vImporte) then
      Importe := 0
    else
      Importe := Currency(vImporte);
    vEsDivisa := DC.Values[RecordIndex, IdxEsDivisa];
    if VarIsNull(vEsDivisa) or VarIsEmpty(vEsDivisa) then
    begin
      AText := ''
    end
    else
    begin
      if Importe > 0 then
        AText := FormatFloat('#,##0.000000000', Importe);
      if (vEsDivisa = 'N') then
        AText := FormatCurr(',0.00 €', Importe);
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura:
                                                       TFacturaTotales);
begin
if TotalesFactura = nil then Exit;
  FDatosCobro.CargarDatosFactura(TotalesFactura);
  txtCantidadLineas.Text := FormatFloat('0.##',
                                        TotalesFactura.Totales.TotalCantidades);
  txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
  txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;
  if TotalesFactura.Totales.TotalBruto <> 0 then
    txtPorcenDtoLineal.Text := FormatFloat('0.## %',
                             (TotalesFactura.Totales.TotalDescuentosLineas /
                              TotalesFactura.Totales.TotalBruto) * 100)
  else
    txtPorcenDtoLineal.Text := '0 %';
  FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.AlRecalcularDatos(Sender: TObject);
var
  EsTotal0: Boolean;
begin
  txtDtoGlobal.Value    := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value   := FDatosCobro.ImporteTotalPagar;
  txtCambio.Value       := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value := FDatosCobro.ImporteValeRecogido;
  FActualizandoVale := True;
  try
    txtValeEmitido.Value := FDatosCobro.ImporteValeEmitido;
  finally
    FActualizandoVale := False;
  end;
  EsTotal0 := (Abs(FDatosCobro.ImporteTotalPagar) < 0.01);
  if FDatosCobro.EsDevolucionEconomica then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnBuscarVale.Enabled := false;
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnBuscarVale.Enabled := (FDatosCobro.ImportePendiente > 0.01)
       and not EsTotal0;
  end;
  btnF6.Enabled := btnBuscarVale.Enabled;
  btnBuscarT.Enabled := (txtPendienteCobro.Value > 0.01) and not EsTotal0;
  btnF3.Enabled      := btnBuscarT.Enabled;
  btnF12.Enabled := btnConTicket.Enabled;
  btnF11.Enabled := btnSinTicket.Enabled;
  btnF10.Enabled := btnSinPrecios.Enabled;
end;

procedure TfrmMtoCajaFaseCobro.ActualizarInterfaz;
begin
  txtDtoGlobal.Value      := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value     := FDatosCobro.ImporteTotalPagar;
  txtCambio.Value         := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value   := FDatosCobro.ImporteValeRecogido;
  txtValeEmitido.Value    := FDatosCobro.ImporteValeEmitido;
  if FDatosCobro.EsDevolucionEconomica then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01);
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled := (FDatosCobro.ImportePendiente <= 0.01);
  end;
  btnF12.Enabled := btnConTicket.Enabled;
  if FDatosCobro.EsDevolucionEconomica then
    ConfigurarModoDevolucion
  else
    ConfigurarModoCobroNormal;
  var PermiteCredito := oCajaParams.GetBool('vgerVentasCredito', True) and
                     FDatosCobro.HayCliente and FDatosCobro.PermiteDeuda and
                     FDatosCobro.PuedeDejarEnCuenta;
  if Assigned(btnDeposito) then
    btnDeposito.Enabled := PermiteCredito;
  btnF7.Enabled := PermiteCredito;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarModoDevolucion;
begin
  txtPorcenDtoGlobal.Enabled := False;
  txtValeEmitido.Properties.ReadOnly := False;
  txtValeEmitido.Style.Color := clWindow;
  lblPendienteCobroAlt.Caption := 'Pendiente de devolver';
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarModoCobroNormal;
begin
  // Si hay líneas de depósito, el descuento global no está permitido
  if FHayLineasDeposito then
  begin
    txtPorcenDtoGlobal.Enabled := False;
    txtPorcenDtoGlobal.Value   := 0;
    // Opcional: tooltip explicativo
    txtPorcenDtoGlobal.Hint    :=
      'No se puede aplicar descuento global con líneas de depósito';
    txtPorcenDtoGlobal.ShowHint := True;
  end
  else
    txtPorcenDtoGlobal.Enabled := oCajaParams.GetBool('vgerDescuentos', True);

  txtValeEmitido.Properties.ReadOnly := True;
  txtValeEmitido.Style.Color := clWhite;
  lblPendienteCobroAlt.Caption := 'Pendiente de cobro';
end;

procedure TfrmMtoCajaFaseCobro.txtValeEmitidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FDatosCobro.EsDevolucionEconomica then Exit;
  if FActualizandoVale then Exit;
  FActualizandoVale := True;
  try
    FDatosCobro.EmitirVale(txtValeEmitido.Value);
  finally
    FActualizandoVale := False;
  end;
end;


procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnF3Click(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.btnF6Click(Sender: TObject);
begin
  inherited;
  btnBuscarValeClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnF7Click(Sender: TObject);
var
  Res: TResultadoValidacion;
begin
  inherited;
  // 1. Validar que tenemos un cliente válido y con permisos para dejar a deber
  if not FDatosCobro.PuedeDejarEnCuenta then
  begin
    ShowMessage('Operación denegada: Este cliente no tiene crédito permitido.');
    Exit;
  end;
  // 2. Comprobar que realmente hay algo que prestar
  if (FDatosCobro.ImportePendiente <= 0) and
     (not FDatosCobro.EsDevolucionEconomica) and
     (FDatosCobro.ImporteTotalPagar > 0) then
  begin
    ShowMessage('No hay importe pendiente para pasar a crédito.');
    Exit;
  end;
  // 3. Aplicar TODO el total pendiente a la cuenta del cliente
  Res := FDatosCobro.EstablecerDejarEnCuenta(FDatosCobro.ImportePendiente);
  if not Res.Valido then
  begin
    // Muestra el error de la librería (ej: "Límite de crédito excedido...")
    ShowMessage(Res.Mensaje);
  end
  else
  begin
    // 4. Éxito: Reflejar en la interfaz visual para que se vea el cuadre
    ActualizarInterfaz;
    btnConTicketClick(Sender);
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMtoCajaFaseCobro.btnBuscarTClick(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.btnBuscarValeClick(Sender: TObject);
var
  ValeSeleccionado: TValeSeleccionado;
  PendienteActual, Exceso: Currency;
begin
  inherited;
  if TfrmMtoCajaSeleccionVale.Ejecutar(ValeSeleccionado) then
  begin
    // 1. Averiguamos cuánto se debe antes de aplicar el vale
    if FDatosCobro.EsDevolucionEconomica then
      PendienteActual := FDatosCobro.ImporteDevolucionPendiente
    else
      PendienteActual := FDatosCobro.ImportePendiente;
    // 2. Calculamos si el vale es mayor que la deuda
    Exceso := 0;
    if ValeSeleccionado.Importe > PendienteActual then
      Exceso := ValeSeleccionado.Importe - PendienteActual;
    // 3. Registramos siempre el vale recogido por su TOTAL
    FDatosCobro.RegistrarValeRecogido(
      ValeSeleccionado.CodigoVale,
      ValeSeleccionado.Importe
    );
    // 4. Si ha sobrado dinero, generamos automáticamente un vale emitido
    if Exceso > 0 then
    begin
      FDatosCobro.EmitirVale(Exceso);
    end;
    // 5. Recalcular refrescará la interfaz y los totales
    FDatosCobro.Recalcular;
  end;
end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
var
  qryCli: TUniQuery;
  PermiteDeuda: Boolean;
  LimiteCredito, DeudaActual: Currency;
  NomCliente: string;
begin
  inherited;
  FEmailEnvio := Trim(FEmailCliente);
  // Modo rectificación: número de la factura rectificada a la vista
  if FRectificaA <> '' then
    Caption := Caption + '  -  RECTIFICA al borrador ' + FRectificaA;
  if Trim(FCodigoCliente) <> '' then
  begin
    qryCli := TUniQuery.Create(nil);
    try
      qryCli.Connection := inLibGlobalVar.oConn;
      qryCli.SQL.Text := 'SELECT RAZON_SOCIAL_CLI, EMAIL_CLI, ' +
                         '       ESPERMITE_DEUDA_CLI, ' +
                         '       TOTAL_LIMITE_CREDITO_CLI, ' +
                         '       TOTAL_DEUDA_CLI ' +
                         '  FROM fza_clientes ' +
                         ' WHERE CODIGO_CLI_CLI = :COD LIMIT 1';
      qryCli.ParamByName('COD').AsString := FCodigoCliente;
      qryCli.Open;
      if not qryCli.IsEmpty then
      begin
        NomCliente := qryCli.FieldByName('RAZON_SOCIAL_CLI').AsString;
        if FEmailEnvio = '' then
          FEmailEnvio := Trim(qryCli.FieldByName('EMAIL_CLI').AsString);
        PermiteDeuda :=
          (qryCli.FieldByName('ESPERMITE_DEUDA_CLI').AsString = 'S');
        LimiteCredito :=
          qryCli.FieldByName('TOTAL_LIMITE_CREDITO_CLI').AsCurrency;
        DeudaActual := 0;
        FDatosCobro.EstablecerCliente(FCodigoCliente,
                                      NomCliente,
                                      PermiteDeuda,
                                      LimiteCredito,
                                      DeudaActual);
      end;
    finally
      FreeAndNil(qryCli);
    end;
  end;
  CargarComboSeries;
  CargarFormasPago;
  ActualizarInterfaz;
  if cxgrdFormasPago.CanFocus then
  begin
    cxgrdFormasPago.SetFocus;
    if dbtvFormasPago.Controller.SelectedRecordCount > 0 then
      dbtvFormasPago.Controller.FocusedColumn := dbmImporte;
  end;
end;

procedure TfrmMtoCajaFaseCobro.actRellenarExecute(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.actBuscarValeExecute(Sender: TObject);
begin
  inherited;
  btnBuscarValeClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actConTicketExecute(Sender: TObject);
begin
  inherited;
  btnConTicketClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actDepositoClienteExecute(Sender: TObject);
begin
  inherited;
  btnDepositoClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSinPreciosExecute(Sender: TObject);
begin
  inherited;
  btnSinPreciosClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSinTicketExecute(Sender: TObject);
begin
  inherited;
  btnSinTicketClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
begin
  if (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    Edit.PostEditValue;
  end;
  FDatosCobro.AplicarDescuentoGlobal(txtPorcenDtoGlobal.Value);
  FDatosCobro.Recalcular;
end;

end.
