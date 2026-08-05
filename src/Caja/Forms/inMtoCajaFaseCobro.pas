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
  VirtualTable,
  inMtoFrmBase, inLibFacturas, inLibFaseCobro, inLibCajaTipos,
  inLibFaseCobroPersistenciaIntf,
  inMtoCajaReferenciaPago, System.UITypes, dxGDIPlusClasses, cxImage,
  inLibInformesCajaPersistenciaIntf, inLibCajaPantallaInyeccion;

type
  TTipoImpresionTicket = inLibCajaTipos.TTipoImpresionVenta;
  TEntradaFaseCobro = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    Fecha: TDateTime;
    CodigoCliente: string;
    EmailCliente: string;
    NifCliente: string;
    CodigoPaisCliente: string;
    NombrePaisCliente: string;
    RectificaA: string;
    HayLineasDeposito: Boolean;
  end;
  TResultadoFaseCobro = record
    TipoImpresion: TTipoImpresionTicket;
    SerieDocumento: string;
    SerieFactura: string;
    FechaFactura: TDateTime;
    NumeroManual: string;
    DatosCobro: TDatosFaseCobro;
  end;
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
    FRepositorioPersistencia: IRepositorioFaseCobro;
    FRepositorioVales: IRepositorioInformesCaja;
    FMemTablePagos: TVirtualTable;
    FActualizandoVale: Boolean;
    FEmailEnvio: string;
    FActualizandoEmail: Boolean;
    FCodigoEmpresa: string;
    FCodigoCliente: string;
    FEmailCliente: string;
    FNifCliente: string;
    FCodigoPaisCliente: string;
    FNombrePaisCliente: string;
    FSerieFactura: string;
    FFechaFactura: TDateTime;
    FNumeroManual: string;
    FRectificaA: string;
    FCodigoAlmacen: string;
    FCodigoCaja: string;
    FFecha: TDate;
    FHayLineasDeposito: Boolean;
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
    constructor Create(
      AOwner: TComponent;
      const ADependencias: TDependenciasFaseCobro); reintroduce;
      overload;
    property DatosCobro: TDatosFaseCobro read FDatosCobro;
    property TipoImpresion: TTipoImpresionTicket read FTipoImpresion;
    property EnviarEmail: Boolean read GetEnviarEmail;
    property EmailEnvio: string read FEmailEnvio;
    procedure Configurar(const AEntrada: TEntradaFaseCobro);
    function ObtenerResultado: TResultadoFaseCobro;
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
    procedure AlRecalcularDatos(Sender: TObject);
    function AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                  ADatosActuales: TDatosReferencia): Boolean;
  end;

implementation

{$R *.dfm}

uses inMtoCajaSeleccionVale, inMtoModalSerieFechaFactura,
     UniDataCaja, inLibDocumentoFiscal, inLibCorreoTickets, inLibMsgCaja;

constructor TfrmMtoCajaFaseCobro.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasFaseCobro);
begin
  ADependencias.Validar;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FRepositorioVales := ADependencias.Vales;
  inherited Create(AOwner);
end;

procedure TfrmMtoCajaFaseCobro.Configurar(
  const AEntrada: TEntradaFaseCobro);
begin
  FCodigoEmpresa := AEntrada.CodigoEmpresa;
  FCodigoAlmacen := AEntrada.CodigoAlmacen;
  FCodigoCaja := AEntrada.CodigoCaja;
  FFecha := AEntrada.Fecha;
  FCodigoCliente := AEntrada.CodigoCliente;
  FEmailCliente := AEntrada.EmailCliente;
  FNifCliente := AEntrada.NifCliente;
  FCodigoPaisCliente := AEntrada.CodigoPaisCliente;
  FNombrePaisCliente := AEntrada.NombrePaisCliente;
  FRectificaA := AEntrada.RectificaA;
  FHayLineasDeposito := AEntrada.HayLineasDeposito;
end;

function TfrmMtoCajaFaseCobro.ObtenerResultado:
  TResultadoFaseCobro;
begin
  Result := Default(TResultadoFaseCobro);
  Result.TipoImpresion := FTipoImpresion;
  Result.SerieDocumento := cbbSERIE_FAC.Text;
  Result.SerieFactura := FSerieFactura;
  Result.FechaFactura := FFechaFactura;
  Result.NumeroManual := FNumeroManual;
  Result.DatosCobro := FDatosCobro;
end;

procedure TfrmMtoCajaFaseCobro.CargarComboSeries;
var
  Solicitud: TSolicitudSeriesFaseCobro;
  Series: TSeriesFaseCobro;
  sSerie: string;
begin
  Solicitud.CodigoEmpresa := FCodigoEmpresa;
  Solicitud.CodigoAlmacen := FCodigoAlmacen;
  Solicitud.CodigoCaja := FCodigoCaja;
  Solicitud.Fecha := FFecha;
  if FRectificaA <> '' then
  begin
    Solicitud.Subtipo := 'RECTIFICATIVA';
  end
  else
  begin
    Solicitud.Subtipo := 'SIMPLIFICADA';
  end;
  Series := FRepositorioPersistencia.ListarSeries(Solicitud);
  cbbSERIE_FAC.Properties.Items.BeginUpdate;
  try
    cbbSERIE_FAC.Properties.Items.Clear;
    for sSerie in Series do
    begin
      cbbSERIE_FAC.Properties.Items.Add(sSerie);
    end;
  finally
    cbbSERIE_FAC.Properties.Items.EndUpdate;
  end;
  if (cbbSERIE_FAC.Properties.Items.Count > 0) and
     (cbbSERIE_FAC.ItemIndex = -1) then
  begin
    cbbSERIE_FAC.ItemIndex := 0;
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
    ShowMessage(SErrorRectificacionCajaNoAdmiteBorrador)
  else if (Trim(FCodigoCliente) = '') or (Trim(FCodigoCliente) = '0') then
    ShowMessage(SErrorClienteBorradorCajaNoAsignado)
  else if Trim(FNifCliente) = '' then
    ShowMessage(SErrorNifClienteBorradorCajaNoIndicado)
  else if PaisEsEspana(FCodigoPaisCliente, FNombrePaisCliente) and
          (not DocumentoFiscalValido(FNifCliente)) then
    ShowMessage(SErrorDocumentoFiscalClienteCajaNoValido +
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
  dUltima := TdmCajaOpe.FechaUltimoTicketSerie(
    ConexionPrincipal,
    FCodigoEmpresa,
    ASerie);
  if (dUltima > 0) and (Trunc(AFecha) < Trunc(dUltima)) then
  begin
    Result := False;
    MessageDlg(
      Format(SErrorFechaSerieEmisionCajaNoValida,
             [ASerie,
              FormatDateTime('dd/mm/yyyy', dUltima),
              FormatDateTime('dd/mm/yyyy', AFecha)]),
      mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoCajaFaseCobro.AvisarSiNumeracionConHuecos(
  const ASerie: string);
var
  Resumen: TResumenNumeracionFaseCobro;
begin
  if (Trim(ASerie) <> '') and
     ParametrosCaja.GetBool('vgerAvisoHuecosNumeracion', True) then
  begin
    Resumen := FRepositorioPersistencia.ObtenerResumenNumeracion(
      FCodigoEmpresa,
      ASerie,
      0);
    if (Resumen.Filas > 0) and
       (Resumen.Filas <> Resumen.Maximo - Resumen.Minimo + 1) then
    begin
      MessageDlg(
        Format(
          SAvisoHuecosNumeracionSerieCaja,
          [
            ASerie,
            (Resumen.Maximo - Resumen.Minimo + 1) - Resumen.Filas,
            Resumen.Minimo,
            Resumen.Maximo
          ]),
        mtWarning,
        [mbOK],
        0);
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

function TfrmMtoCajaFaseCobro.ValidarHuecoManual(
  const ASerie, ANumero: string;
  out ANumeroFmt: string
): Boolean;
var
  Resumen: TResumenNumeracionFaseCobro;
  iNumero: Int64;
begin
  Result := False;
  ANumeroFmt := '';
  iNumero := StrToInt64Def(Trim(ANumero), 0);
  if iNumero <= 0 then
  begin
    MessageDlg(
      SErrorNumeroBorradorCajaNoValido,
      mtError,
      [mbOK],
      0);
  end
  else
  begin
    Resumen := FRepositorioPersistencia.ObtenerResumenNumeracion(
      FCodigoEmpresa,
      ASerie,
      iNumero);
    if Resumen.ExistentesNumero > 0 then
    begin
      MessageDlg(
        Format(
          SErrorNumeroBorradorCajaExistente,
          [iNumero, ASerie]),
        mtError,
        [mbOK],
        0);
    end
    else if (Resumen.Maximo <= Resumen.Minimo) or
            (iNumero <= Resumen.Minimo) or
            (iNumero >= Resumen.Maximo) then
    begin
      MessageDlg(
        Format(
          SErrorNumeroBorradorCajaNoEsHueco,
          [iNumero, ASerie, Resumen.Minimo, Resumen.Maximo]),
        mtError,
        [mbOK],
        0);
    end
    else
    begin
      ANumeroFmt := IntToStr(iNumero);
      while Length(ANumeroFmt) < Resumen.Longitud do
      begin
        ANumeroFmt := '0' + ANumeroFmt;
      end;
      Result := True;
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
var
  Dependencias: TDependenciasFaseCobro;
begin
  inherited;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.Vales := FRepositorioVales;
  Dependencias.Validar;
  FActualizandoEmail := False;
  FEmailEnvio := '';
  chkEnviarEmail.Checked := False;
  DibujarIconoEmail;
  ConfigurarTablaVirtual;
  FDatosCobro := TDatosFaseCobro.Create(
    FRepositorioPersistencia,
    FMemTablePagos);
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
      bContinuar := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
      if not bContinuar then
        ShowMessage(sMensaje)
      else
      begin
        FEmailEnvio := Trim(FEmailEnvio);
        if FEmailEnvio = '' then
          bContinuar := InputQuery(STituloEnviarDocumentacionCaja,
            SSolicitudCorreoDocumentacionCaja, FEmailEnvio);
        if bContinuar and (Trim(FEmailEnvio) = '') then
        begin
          ShowMessage(SErrorCorreoDocumentacionCajaNoIndicado);
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
  if not ((DataSet.State = dsEdit) and
     (DataSet.FieldByName('CODIGO_FP_CFP').AsString = 'VALE')) then
  begin
    Importe := DataSet.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
    EsDivisa :=
      DataSet.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S';
    EsCripto :=
      DataSet.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S';
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
  FRepositorioVales := nil;
  FRepositorioPersistencia := nil;
end;

procedure TfrmMtoCajaFaseCobro.CargarFormasPago;
var
  Resultado: IResultadoConsultaFaseCobro;
  oFormasPago: TDataSet;
  iCampo: Integer;
  oCampoDestino: TField;
begin
  Resultado := FRepositorioPersistencia.ConsultarFormasPago;
  oFormasPago := Resultado.DataSet;
  if FMemTablePagos.Active then
  begin
    FMemTablePagos.Close;
  end;
  FMemTablePagos.FieldDefs.Clear;
  FMemTablePagos.Fields.Clear;
  FMemTablePagos.FieldDefs.Assign(oFormasPago.FieldDefs);
  FMemTablePagos.FieldDefs.Add('FACTOR_CAMBIO', ftCurrency);
  FMemTablePagos.FieldDefs.Add('ESIMPORTE_DIVISA', ftString, 1);
  FMemTablePagos.FieldDefs.Add('REFERENCIA', ftString, 255);
  FMemTablePagos.FieldDefs.Add('IMPORTE_ENTREGADO', ftFloat);
  FMemTablePagos.FieldDefs.Add('IMPORTE_DIVISA', ftFloat);
  FMemTablePagos.FieldDefs.Add('IMPORTE_CAMBIO', ftCurrency);
  FMemTablePagos.FieldDefs.Add('CODIGO_DIVISA', ftString, 6);
  FMemTablePagos.Open;
  FMemTablePagos.DisableControls;
  try
    oFormasPago.First;
    while not oFormasPago.Eof do
    begin
      FMemTablePagos.Append;
      for iCampo := 0 to oFormasPago.FieldCount - 1 do
      begin
        oCampoDestino := FMemTablePagos.FindField(
          oFormasPago.Fields[iCampo].FieldName);
        if Assigned(oCampoDestino) and
           not oFormasPago.Fields[iCampo].IsNull then
        begin
          oCampoDestino.Value := oFormasPago.Fields[iCampo].Value;
        end;
      end;
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;
      FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
      FMemTablePagos.FieldByName('REFERENCIA').AsString := '';
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat := 0;
      FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
      FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
      FMemTablePagos.Post;
      oFormasPago.Next;
    end;
    FMemTablePagos.First;
  finally
    FMemTablePagos.EnableControls;
  end;
end;
procedure TfrmMtoCajaFaseCobro.RellenarPendienteEnFormaActual;
var
  Pendiente: Currency;
begin
  if FMemTablePagos.Active and not FMemTablePagos.IsEmpty then
  begin
    if FDatosCobro.EsDevolucionEconomica then
      Pendiente := FDatosCobro.ImporteDevolucionPendiente
    else
      Pendiente := FDatosCobro.ImportePendiente;
    if Pendiente > 0.01 then
    begin
      if FDatosCobro.EsDevolucionEconomica then
        EscribirImporteEnFormaActual(-Pendiente)
      else
        EscribirImporteEnFormaActual(Pendiente);
    end;
  end;
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
  if Abs(ImporteActual) >= 0.0000000001 then
  begin
    if FDatosCobro.EsDevolucionEconomica then
    begin
      FDatosCobro.Recalcular;
      EscribirImporteEnFormaActual(-Abs(ImporteActual));
    end
    else
      EscribirImporteEnFormaActual(ImporteActual);
  end;
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
  if Assigned(ActiveEdit) and (ActiveEdit is TcxCurrencyEdit) then
  begin
    EditProps := TcxCurrencyEditProperties(
      TcxCurrencyEdit(ActiveEdit).ActiveProperties);
    if EsCripto then
    begin
      EditProps.DecimalPlaces := 9;
      EditProps.DisplayFormat := '#,##0.#########';
      EditProps.EditFormat := '#########0.#########';
    end
    else if EsDivisa then
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00';
      EditProps.EditFormat := ',0.00';
    end
    else
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00 €';
      EditProps.EditFormat := ',0.00 €';
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
begin
  inherited;
  if AItem = dbmImporte then
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
  if RecordIndex >= 0 then
  begin
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
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura:
                                                       TFacturaTotales);
begin
  if TotalesFactura <> nil then
  begin
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
  var PermiteCredito :=
    ParametrosCaja.GetBool('vgerVentasCredito', True) and
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
  lblPendienteCobroAlt.Caption := SCaptionPendienteDevolver;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarModoCobroNormal;
begin
  // Si hay líneas de depósito, el descuento global no está permitido
  if FHayLineasDeposito then
  begin
    txtPorcenDtoGlobal.Enabled := False;
    txtPorcenDtoGlobal.Value   := 0;
    // Opcional: tooltip explicativo
    txtPorcenDtoGlobal.Hint    := SHintSinDescuentoGlobalDeposito;
    txtPorcenDtoGlobal.ShowHint := True;
  end
  else
    txtPorcenDtoGlobal.Enabled :=
      ParametrosCaja.GetBool('vgerDescuentos', True);

  txtValeEmitido.Properties.ReadOnly := True;
  txtValeEmitido.Style.Color := clWhite;
  lblPendienteCobroAlt.Caption := SCaptionPendienteCobro;
end;

procedure TfrmMtoCajaFaseCobro.txtValeEmitidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  if FDatosCobro.EsDevolucionEconomica and not FActualizandoVale then
  begin
    FActualizandoVale := True;
    try
      FDatosCobro.EmitirVale(txtValeEmitido.Value);
    finally
      FActualizandoVale := False;
    end;
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
    ShowMessage(SErrorCreditoClienteCajaNoPermitido);
  end
  else if (FDatosCobro.ImportePendiente <= 0) and
          (not FDatosCobro.EsDevolucionEconomica) and
          (FDatosCobro.ImporteTotalPagar > 0) then
  begin
    ShowMessage(SErrorImporteCreditoCajaNoPendiente);
  end
  else
  begin
    Res := FDatosCobro.EstablecerDejarEnCuenta(
      FDatosCobro.ImportePendiente);
    if not Res.Valido then
      ShowMessage(Res.Mensaje)
    else
    begin
      ActualizarInterfaz;
      btnConTicketClick(Sender);
    end;
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
  if TfrmMtoCajaSeleccionVale.Ejecutar(
    FRepositorioVales,
    ValeSeleccionado) then
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
  Cliente: TClienteFaseCobro;
begin
  inherited;
  FEmailEnvio := Trim(FEmailCliente);
  // Modo rectificación: número de la factura rectificada a la vista
  if FRectificaA <> '' then
    Caption := Caption + '  -  RECTIFICA al borrador ' + FRectificaA;
  if Trim(FCodigoCliente) <> '' then
  begin
    if FRepositorioPersistencia.ObtenerCliente(
         FCodigoCliente,
         Cliente) then
    begin
      if FEmailEnvio = '' then
      begin
        FEmailEnvio := Trim(Cliente.Email);
      end;
      FDatosCobro.EstablecerCliente(
        FCodigoCliente,
        Cliente.Nombre,
        Cliente.PermiteDeuda,
        Cliente.LimiteCredito,
        0);
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
