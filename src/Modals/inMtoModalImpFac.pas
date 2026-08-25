{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpFac                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de facturas.                                           }
{    Hereda del modal generico de impresion y prepara la consulta.             }
{******************************************************************************}
unit inMtoModalImpFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxClass,
  frxExportBaseDialog, frxExportPDF, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, Vcl.ComCtrls, dxCore, cxDateUtils,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxRadioGroup, cxGroupBox, cxLabel,
  cxTextEdit, UniDataFacturas, DB, frxExportXLSX, MemDS,
  DBAccess, Uni, frxDesgn, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  dxSkinsCore, dxSkinBlue, JvComponentBase, JvEnterTab, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue,   dxSpreadSheet, dxSpreadSheetCore,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxHashUtils, inLibDevExcel, System.Actions, Vcl.ActnList,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, frxSmartMemo,
  inLibInformeFacturaPersistenciaIntf, inLibComandoImprimirFacturas,
  cxCheckBox;

type
  TEnviarCorreoFactura = reference to function(
    const ARutaPdf, AEmail: string;
    out AMensaje: string): Boolean;
  TEjecutarLoteFacturas = reference to function(
    const AReferencias: TReferenciasComandoFactura;
    const AFormato: string;
    AEnviarEmail: Boolean): Boolean;
  TObtenerLoteFacturas = reference to function:
    TReferenciasComandoFactura;

const
  WM_INICIAR_ENVIO_EMAIL_FACTURA = WM_APP + $461;

type
  TfrmPrintFac = class(TfrmPrint)
    edtNroFac: TcxTextEdit;
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbProcesarFiltrados: TcxRadioButton;
    chkEnviarEmail: TcxCheckBox;
    procedure rbProcesarFiltradosClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject); override;
    procedure btnImprimirClick(Sender: TObject); override;
    procedure btnExcelClick(Sender: TObject);
    procedure chkEnviarEmailPropertiesEditValueChanged(Sender: TObject);
  private
    FPreparadorInforme: IPreparadorInformeFactura;
    FObtenerReferenciasFiltradas: TObtenerLoteFacturas;
    FExportarLotePdf: TEjecutarLoteFacturas;
    FImprimirLote: TEjecutarLoteFacturas;
    FEmailInicial: string;
    FEmailEnvio: string;
    FEnviarCorreo: TEnviarCorreoFactura;
    FActualizandoEmail: Boolean;
    FEnvioEmailPendiente: Boolean;
    FProcesandoEnvioEmail: Boolean;
    procedure AplicarModoSeleccionado;
    procedure ActualizarDisponibilidadCorreo;
    procedure BloquearAccionesCorreo;
    procedure DesmarcarEnvioEmail;
    function SolicitarEmailIndividual: Boolean;
    function ValidarConfiguracionCorreo: Boolean;
    procedure IniciarEnvioEmail;
    procedure EjecutarEnvioEmailConfigurado;
    procedure EnviarPdfPorCorreo(const ARutaPdf: string);
    procedure EnviarCorreoIndividualPreparado;
    function IntentarEliminarPdfTemporal(
      const ARutaPdf: string;
      out ADetalle: string): Boolean;
    procedure NotificarPdfTemporalNoEliminado(
      const ARutaPdf, ADetalle: string);
    procedure EliminarPdfTemporalSeguro(const ARutaPdf: string);
    procedure WMIniciarEnvioEmailFactura(
      var Message: TMessage); message WM_INICIAR_ENVIO_EMAIL_FACTURA;
    function PrepararLote(
      const AAccion: TEjecutarLoteFacturas;
      AEnviarEmail: Boolean): Boolean;
    function IntentarObtenerReferenciasLote(
      out AReferencias: TReferenciasComandoFactura): Boolean;
  protected
    function TraducirContenidoInforme: Boolean; override;
    procedure PdfExportado(const ARuta: string); override;
    procedure ReportBeforePrintFactura(
      Component: TfrxReportComponent);
  public
    class procedure ArchivarFacturaConsolidada(
      ADataModule: TdmFacturas;
      const ASerie, ANumero: string); static;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    procedure ConfigurarDataModule(ADataModule: TdmFacturas);
    procedure ConfigurarNombrePDF;
    procedure ConfigurarLote(
      APuedeUsarActual: Boolean;
      const AObtenerFiltradas: TObtenerLoteFacturas;
      const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
    procedure ConfigurarCorreo(
      const AEmailInicial: string;
      const AEnviarCorreo: TEnviarCorreoFactura);
    function ObtenerNombreFactura(ADataSet: TDataSet): string;
    procedure AplicarSkuDescripcionReport(AReport: TfrxReport);
  public
    dmFac: TdmFacturas;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  inMtoPreviewExcel, inLibFacturaExcel, inLibVerifactu,
  inLibFormatoDocumento, inLibVentasWsCola, inLibFacturaPdfBlob,
  inLibDir, inLibFacturasPersistenciaIntf,
  UniDataFacturasOperaciones, UniDataVentasWsCola,
  UniDataInformeFacturaRepositorio, inLibMsgFacturas,
  inLibCorreoTickets, inLibCorreoValidacion;

resourcestring
  STituloEnviarFacturaCorreo = 'Enviar factura por correo electrónico';
  SSolicitudEmailFactura = 'Correo electrónico:';
  SBotonConfirmarEnvioFactura = 'Confirmar envío';
  SBotonCancelarEnvioFactura = 'Cancelar';
  SErrorEmailFacturaVacio =
    'Indique una dirección de correo electrónico.';
  SErrorEmailFacturaInvalido =
    'La dirección de correo electrónico no es válida.';
  SErrorServicioCorreoFacturaNoDisponible =
    'No está disponible el servicio de envío de facturas por correo.';
  SInfoFacturaEnviadaCorreo =
    'Factura enviada por correo electrónico a %s.';
  SErrorFacturaNoEnviadaCorreo =
    'No se pudo enviar la factura por correo electrónico.';
  SErrorPdfTemporalCorreoFactura =
    'No se pudo generar el PDF temporal para enviar la factura por ' +
    'correo electrónico.';
  SAvisoPdfTemporalCorreoNoEliminado =
    'No se pudo eliminar el PDF temporal usado para el correo: %s';

procedure InformarFalloSecundarioEnDepurador(
  const AContexto: PChar;
  E: Exception);
begin
  try
    OutputDebugString(PChar(
      string(AContexto) + ': ' + E.ClassName + ': ' + E.Message));
  except
    OutputDebugString(AContexto);
  end;
end;

type
  TfrmConfirmarCorreoFactura = class(TForm)
  private
    FEmail: TEdit;
    procedure ConfirmarClick(Sender: TObject);
    function EmailPuedeConfirmarse: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function Ejecutar(
      const AEmailInicial: string;
      out AEmail: string): Boolean;
  end;

{ TfrmConfirmarCorreoFactura }

constructor TfrmConfirmarCorreoFactura.Create(AOwner: TComponent);
var
  BotonCancelar: TButton;
  BotonConfirmar: TButton;
  EtiquetaEmail: TLabel;
begin
  inherited CreateNew(AOwner);
  BorderIcons := [biSystemMenu];
  BorderStyle := bsDialog;
  Caption := STituloEnviarFacturaCorreo;
  ClientHeight := 132;
  ClientWidth := 424;
  Font.Assign(Screen.MessageFont);
  Position := poOwnerFormCenter;
  if AOwner is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(AOwner);
  end;

  EtiquetaEmail := TLabel.Create(Self);
  EtiquetaEmail.Parent := Self;
  EtiquetaEmail.Caption := SSolicitudEmailFactura;
  EtiquetaEmail.SetBounds(16, 14, 392, 20);

  FEmail := TEdit.Create(Self);
  FEmail.Parent := Self;
  FEmail.SetBounds(16, 36, 392, 25);
  FEmail.Anchors := [akLeft, akTop, akRight];

  BotonConfirmar := TButton.Create(Self);
  BotonConfirmar.Parent := Self;
  BotonConfirmar.Caption := SBotonConfirmarEnvioFactura;
  BotonConfirmar.Default := True;
  BotonConfirmar.SetBounds(136, 84, 144, 30);
  BotonConfirmar.OnClick := ConfirmarClick;

  BotonCancelar := TButton.Create(Self);
  BotonCancelar.Parent := Self;
  BotonCancelar.Cancel := True;
  BotonCancelar.Caption := SBotonCancelarEnvioFactura;
  BotonCancelar.ModalResult := mrCancel;
  BotonCancelar.SetBounds(288, 84, 120, 30);
end;

procedure TfrmConfirmarCorreoFactura.ConfirmarClick(Sender: TObject);
begin
  if EmailPuedeConfirmarse then
    ModalResult := mrOk;
end;

function TfrmConfirmarCorreoFactura.EmailPuedeConfirmarse: Boolean;
begin
  Result := Trim(FEmail.Text) <> '';
  if not Result then
  begin
    ShowMessage(SErrorEmailFacturaVacio);
    FEmail.SetFocus;
  end
  else
  begin
    Result := EmailDocumentoValido(FEmail.Text);
    if not Result then
    begin
      ShowMessage(SErrorEmailFacturaInvalido);
      FEmail.SetFocus;
    end;
  end;
end;

function TfrmConfirmarCorreoFactura.Ejecutar(
  const AEmailInicial: string;
  out AEmail: string): Boolean;
begin
  FEmail.Text := AEmailInicial;
  ActiveControl := FEmail;
  FEmail.SelectAll;
  Result := ShowModal = mrOk;
  if Result then
    AEmail := Trim(FEmail.Text)
  else
    AEmail := '';
end;

{ TfrmPrintFac }

procedure TfrmPrintFac.ConfigurarDataModule(ADataModule: TdmFacturas);
begin
  dmFac := ADataModule;
  if dmFac <> nil then
  begin
    // Se enlaza tambien la plantilla origen antes de cualquier AssignAll.
    // Asi, tanto el formato predeterminado como los formatos guardados se
    // cargan dentro del ambito local del data module de esta instancia.
    RebindReportDataSetsByDataModule(frxReportOrigen, dmFac);
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  end;
end;

procedure TfrmPrintFac.ConfigurarCorreo(
  const AEmailInicial: string;
  const AEnviarCorreo: TEnviarCorreoFactura);
begin
  FEmailInicial := Trim(AEmailInicial);
  FEmailEnvio := '';
  FEnviarCorreo := AEnviarCorreo;
  ActualizarDisponibilidadCorreo;
end;

procedure TfrmPrintFac.ActualizarDisponibilidadCorreo;
var
  bCorreoLoteDisponible: Boolean;
  bCorreoModoDisponible: Boolean;
begin
  bCorreoLoteDisponible :=
    Assigned(FObtenerReferenciasFiltradas) and
    Assigned(FExportarLotePdf);
  chkEnviarEmail.Visible :=
    Assigned(FEnviarCorreo) or bCorreoLoteDisponible;
  if rbActual.Checked then
    bCorreoModoDisponible := Assigned(FEnviarCorreo)
  else
    bCorreoModoDisponible := bCorreoLoteDisponible;
  chkEnviarEmail.Enabled := bCorreoModoDisponible;
  if not bCorreoModoDisponible then
    DesmarcarEnvioEmail;
end;

procedure TfrmPrintFac.DesmarcarEnvioEmail;
begin
  FEmailEnvio := '';
  FActualizandoEmail := True;
  try
    chkEnviarEmail.Checked := False;
  finally
    FActualizandoEmail := False;
  end;
end;

procedure TfrmPrintFac.BloquearAccionesCorreo;
begin
  chkEnviarEmail.Enabled := False;
  btnPDF.Enabled := False;
  btnImprimir.Enabled := False;
  btnVistaPreliminar.Enabled := False;
  btnEditar.Enabled := False;
  btnExcel.Enabled := False;
end;

function TfrmPrintFac.SolicitarEmailIndividual: Boolean;
var
  Formulario: TfrmConfirmarCorreoFactura;
  sEmail: string;
begin
  Formulario := TfrmConfirmarCorreoFactura.Create(Self);
  try
    Result := Formulario.Ejecutar(FEmailInicial, sEmail);
  finally
    Formulario.Free;
  end;
  if Result then
    FEmailEnvio := sEmail
  else
    DesmarcarEnvioEmail;
end;

procedure TfrmPrintFac.chkEnviarEmailPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FActualizandoEmail then
  begin
    if not chkEnviarEmail.Checked then
    begin
      FEnvioEmailPendiente := False;
      FEmailEnvio := ''
    end
    else if not FEnvioEmailPendiente and not FProcesandoEnvioEmail then
    begin
      FEnvioEmailPendiente := True;
      BloquearAccionesCorreo;
      if not Winapi.Windows.PostMessage(
        Handle,
        WM_INICIAR_ENVIO_EMAIL_FACTURA,
        0,
        0) then
      begin
        FEnvioEmailPendiente := False;
        DesmarcarEnvioEmail;
        AplicarModoSeleccionado;
      end;
    end;
  end;
end;

procedure TfrmPrintFac.WMIniciarEnvioEmailFactura(
  var Message: TMessage);
begin
  FEnvioEmailPendiente := False;
  if chkEnviarEmail.Checked then
    IniciarEnvioEmail
  else
    AplicarModoSeleccionado;
  Message.Result := 0;
end;

function TfrmPrintFac.ValidarConfiguracionCorreo: Boolean;
var
  sMensaje: string;
begin
  Result := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
  if not Result then
    ShowMessage(sMensaje)
  else if rbActual.Checked and not Assigned(FEnviarCorreo) then
  begin
    ShowMessage(SErrorServicioCorreoFacturaNoDisponible);
    Result := False;
  end;
end;

procedure TfrmPrintFac.IniciarEnvioEmail;
begin
  if chkEnviarEmail.Checked and not FProcesandoEnvioEmail then
  begin
    FProcesandoEnvioEmail := True;
    BloquearAccionesCorreo;
    try
      try
        if ValidarConfiguracionCorreo then
          EjecutarEnvioEmailConfigurado;
      except
        on E: Exception do
          MessageDlg(
            SErrorFacturaNoEnviadaCorreo + sLineBreak +
            E.ClassName + ': ' + E.Message,
            mtError,
            [mbOK],
            0);
      end;
    finally
      // La casilla actúa como iniciador, no como opción pendiente. También
      // se limpia tras error o cancelación para que reintentar sea marcarla.
      DesmarcarEnvioEmail;
      FProcesandoEnvioEmail := False;
      AplicarModoSeleccionado;
    end;
  end;
end;

procedure TfrmPrintFac.EjecutarEnvioEmailConfigurado;
begin
  if rbProcesarFiltrados.Checked then
  begin
    // En lote se reutiliza el flujo PDF completo: selección forzada de
    // formato, carpeta, envío por factura y TXT final. El destinatario
    // procede de cada snapshot y nunca se solicita un correo común.
    if PrepararLote(FExportarLotePdf, True) then
      ModalResult := mrOk;
  end
  else
  begin
    // Mismo comienzo que el botón PDF, pero el fichero es temporal: el
    // usuario elige la plantilla y después confirma el destinatario.
    preparar_consulta;
    Consultar_Formularios(True);
    if FormatoElegido <> '' then
    begin
      if SolicitarEmailIndividual then
        EnviarCorreoIndividualPreparado;
    end;
  end;
end;

procedure TfrmPrintFac.EnviarPdfPorCorreo(const ARutaPdf: string);
var
  bEnviado: Boolean;
  bPuedeEnviar: Boolean;
  sMensaje: string;
begin
  bPuedeEnviar := chkEnviarEmail.Checked and rbActual.Checked and
    Assigned(FEnviarCorreo) and (Trim(ARutaPdf) <> '');
  if bPuedeEnviar then
  begin
    bEnviado := False;
    sMensaje := '';
    try
      bEnviado := FEnviarCorreo(
        ARutaPdf,
        FEmailEnvio,
        sMensaje);
    except
      on E: Exception do
        sMensaje := E.ClassName + ': ' + E.Message;
    end;
    if bEnviado then
    begin
      if Trim(sMensaje) = '' then
        sMensaje := Format(SInfoFacturaEnviadaCorreo, [FEmailEnvio]);
      MessageDlg(sMensaje, mtInformation, [mbOK], 0);
    end
    else
    begin
      if Trim(sMensaje) = '' then
        sMensaje := SErrorFacturaNoEnviadaCorreo
      else
        sMensaje := SErrorFacturaNoEnviadaCorreo + sLineBreak + sMensaje;
      MessageDlg(sMensaje, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmPrintFac.EnviarCorreoIndividualPreparado;
var
  sRutaPdf: string;
begin
  sRutaPdf := Trim(TPath.Combine(
    TPath.GetTempPath,
    TPath.ChangeExtension(TPath.GetRandomFileName, '.pdf')));
  try
    try
      if ExportarPdfPreparado(sRutaPdf, False) then
        EnviarPdfPorCorreo(sRutaPdf)
      else
        MessageDlg(
          SErrorPdfTemporalCorreoFactura,
          mtError,
          [mbOK],
          0);
    except
      on E: Exception do
        MessageDlg(
          SErrorPdfTemporalCorreoFactura + sLineBreak +
          E.ClassName + ': ' + E.Message,
          mtError,
          [mbOK],
          0);
    end;
  finally
    EliminarPdfTemporalSeguro(sRutaPdf);
  end;
end;

function TfrmPrintFac.IntentarEliminarPdfTemporal(
  const ARutaPdf: string;
  out ADetalle: string): Boolean;
var
  iError: Cardinal;
begin
  ADetalle := '';
  try
    Result := not FileExists(ARutaPdf);
    if not Result then
    begin
      SetLastError(ERROR_SUCCESS);
      Result := System.SysUtils.DeleteFile(ARutaPdf);
      if not Result then
      begin
        iError := GetLastError;
        // Si otro proceso terminó de borrarlo entre FileExists y DeleteFile,
        // la limpieza también se considera completada.
        Result := not FileExists(ARutaPdf);
        if not Result and (iError <> ERROR_SUCCESS) then
          ADetalle := SysErrorMessage(iError);
      end;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      ADetalle := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

procedure TfrmPrintFac.NotificarPdfTemporalNoEliminado(
  const ARutaPdf, ADetalle: string);
var
  sMensaje: string;
begin
  sMensaje := Format(SAvisoPdfTemporalCorreoNoEliminado, [ARutaPdf]);
  if Trim(ADetalle) <> '' then
    sMensaje := sMensaje + sLineBreak + ADetalle;
  try
    if Assigned(RegistroLog) then
      RegistroLog.RegistrarAviso(sMensaje);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoModalImpFac.NotificarPdfTemporalNoEliminado.Log', E);
  end;
  MessageDlg(sMensaje, mtWarning, [mbOK], 0);
end;

procedure TfrmPrintFac.EliminarPdfTemporalSeguro(const ARutaPdf: string);
var
  sDetalle: string;
  sRutaPdf: string;
begin
  sRutaPdf := Trim(ARutaPdf);
  if sRutaPdf <> '' then
  begin
    if not IntentarEliminarPdfTemporal(sRutaPdf, sDetalle) then
      NotificarPdfTemporalNoEliminado(sRutaPdf, sDetalle);
  end;
end;

function TfrmPrintFac.TraducirContenidoInforme: Boolean;
begin
  // Las facturas de venta son documentos fiscales para el mercado español.
  Result := False;
end;

class procedure TfrmPrintFac.ArchivarFacturaConsolidada(
  ADataModule: TdmFacturas;
  const ASerie, ANumero: string);
var
  Formulario: TfrmPrintFac;
  sRutaPdf: string;
begin
  Formulario := TfrmPrintFac.Create(Application);
  try
    Formulario.edtSerie.Text := ASerie;
    Formulario.edtNroFac.Text := ANumero;
    Formulario.dmFac := ADataModule;
    Formulario.Consultar_Formularios;
    sRutaPdf := GetUserFolderTickets + 'Factura_' +
      FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.pdf';
    if Formulario.ExportarPdfActual(sRutaPdf) then
      System.SysUtils.DeleteFile(sRutaPdf);
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  NombreSugerido: string;
begin
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    NombreSugerido := ObtenerNombreFactura(dmFac.unqryTablaG);
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName := NombreSugerido;
    try
      ExportarFacturaADevExpress(
        ParametrosApp, RegistroLog, ConexionPrincipal,
        fPreview.dxSpreadSheet1,
        dmFac.unqryTablaG,
        dmFac.unqryLinFac);
    finally
      Screen.Cursor := crDefault;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
end;

procedure TfrmPrintFac.AfterReportLoaded;
var
  oGrupoOperacion: TfrxComponent;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  oGrupoOperacion := frxrprt1.FindObject('GroupHeaderOperacionCaja');
  if oGrupoOperacion is TfrxGroupHeader then
  begin
    // Un formato guardado puede conservar una definicion antigua del
    // dataset. Evitamos que FastReport evalue un campo inexistente y solo
    // activamos la agrupacion cuando la consulta abierta expone el ID.
    TfrxGroupHeader(oGrupoOperacion).Condition := '0';
    TfrxGroupHeader(oGrupoOperacion).Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active and
       (dmFac.unqryLinFacPrint.FindField(
          'ID_OPERACION_CAJA_FACTURA') <> nil) then
    begin
      TfrxGroupHeader(oGrupoOperacion).Condition :=
        'Lineas Facturas."ID_OPERACION_CAJA_FACTURA"';
      TfrxGroupHeader(oGrupoOperacion).Visible := True;
    end;
  end;
  AplicarSkuDescripcionReport(frxrprt1);
  // Solo ajusta el título por tipo (FACTURA / FACTURA SIMPLIFICADA /
  // FACTURA RECTIFICATIVA). NO se inyecta ni se mueve ninguna banda:
  // el A4 conserva su layout original. El QR del A4 se replanteará en
  // limpio; el QR del Excel (que sí funciona) no se toca.
  if (dmFac <> nil) and dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
    AplicarVerifactuEnReportDirecto(ParametrosApp, frxrprt1,
      dmFac.unqryFacPrint);
  frxrprt1.OnBeforePrint := ReportBeforePrintFactura;
end;

procedure TfrmPrintFac.ReportBeforePrintFactura(
  Component: TfrxReportComponent);
var
  oCampo: TField;
begin
  ReportBeforePrintConQR(Component);
  if (Component <> nil) and
     SameText(Component.Name, 'GroupHeaderOperacionCaja') then
  begin
    Component.Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active then
    begin
      oCampo := dmFac.unqryLinFacPrint.FindField('ESFACTURA_TA_CAJA');
      if oCampo <> nil then
        Component.Visible := SameText(oCampo.AsString, 'S');
    end;
  end;
end;

procedure TfrmPrintFac.AplicarSkuDescripcionReport(AReport: TfrxReport);
var
  oComponente: TfrxComponent;
  oMemo: TfrxMemoView;
begin
  if (AReport <> nil) and (dmFac <> nil) then
  begin
    oComponente :=
      AReport.FindObject('LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA');
    if oComponente is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oComponente);
      oMemo.DataField := 'DESCRIPCION_PRINT_FACLIN';
      oMemo.DataSet := dmFac.fxdstPrintLinFac;
      oMemo.DataSetName := 'Lineas Facturas';
      oMemo.Memo.Text := '[Lineas Facturas."DESCRIPCION_PRINT_FACLIN"]';
    end;
  end;
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := '';
  if (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    frxpdfxprtPedWeb.FileName :=
      ObtenerNombreFactura(dmFac.unqryFacPrint);
  end;
end;

procedure TfrmPrintFac.ConfigurarLote(
  APuedeUsarActual: Boolean;
  const AObtenerFiltradas: TObtenerLoteFacturas;
  const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
begin
  FObtenerReferenciasFiltradas := AObtenerFiltradas;
  FExportarLotePdf := AExportarPdf;
  FImprimirLote := AImprimir;
  rbActual.Enabled := APuedeUsarActual;
  rbProcesarFiltrados.Enabled := Assigned(FObtenerReferenciasFiltradas);
  if rbActual.Enabled then
    rbActual.Checked := True
  else if rbProcesarFiltrados.Enabled then
    rbProcesarFiltrados.Checked := True;
  ActualizarDisponibilidadCorreo;
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.AplicarModoSeleccionado;
var
  bActual: Boolean;
begin
  bActual := rbActual.Checked;
  btnPDF.Enabled := True;
  btnImprimir.Enabled := True;
  btnVistaPreliminar.Enabled := bActual;
  btnEditar.Enabled := bActual;
  btnExcel.Enabled := bActual;
  ActualizarDisponibilidadCorreo;
  if not bActual then
    FEmailEnvio := '';
end;

function TfrmPrintFac.IntentarObtenerReferenciasLote(
  out AReferencias: TReferenciasComandoFactura): Boolean;
begin
  AReferencias := nil;
  try
    if Assigned(FObtenerReferenciasFiltradas) then
      AReferencias := FObtenerReferenciasFiltradas();
    Result := True;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Result := False;
    end;
  end;
end;

function TfrmPrintFac.PrepararLote(
  const AAccion: TEjecutarLoteFacturas;
  AEnviarEmail: Boolean): Boolean;
var
  bPreparado: Boolean;
  oReferencias: TReferenciasComandoFactura;
begin
  oReferencias := nil;
  bPreparado := Assigned(AAccion);
  if not bPreparado then
    ShowMessage(SErrorServicioLoteImpresionFacturas);
  if bPreparado then
  begin
    Consultar_Formularios(True);
    bPreparado := FormatoElegido <> '';
  end;
  if bPreparado then
    bPreparado := IntentarObtenerReferenciasLote(oReferencias);
  if bPreparado then
  begin
    bPreparado := Length(oReferencias) <> 0;
    if not bPreparado then
      ShowMessage(SErrorFacturasFiltradasVacias);
  end;
  Result := bPreparado;
  if bPreparado then
    Result := AAccion(
      oReferencias,
      FormatoElegido,
      AEnviarEmail);
end;

procedure TfrmPrintFac.btnPDFClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FExportarLotePdf, False) then
      ModalResult := mrOk;
  end
  else
    inherited btnPDFClick(Sender);
end;

procedure TfrmPrintFac.btnImprimirClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FImprimirLote, False) then
      ModalResult := mrOk;
  end
  else
    inherited btnImprimirClick(Sender);
end;

procedure TfrmPrintFac.PdfExportado(const ARuta: string);
var
  sSerie:  string;
  sNumero: string;
  sFase:   string;
  bLanzada: Boolean;
  oRepositorioPdf: IRepositorioPdfFactura;
begin
  inherited;
  if (Trim(ARuta) <> '') and (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    sSerie  := dmFac.unqryFacPrint.FieldByName('SERIE_FAC').AsString;
    sNumero := dmFac.unqryFacPrint.FieldByName('NUMERO_FAC').AsString;
    TVentasWsCola.AdjuntarFacturaPdfSeguro(
      ParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(ConexionPrincipal),
      IdentidadSesion.Usuario,
      sSerie, sNumero, ARuta, RegistroLog);
    // Archivado en fza_facturas.PDF_FAC: solo el PDF de UNA factura
    // (rbActual; un rango de fechas mezcla varias en un fichero) y solo
    // si ya salio de borrador (en modo SIN se imprimen borradores)
    sFase := dmFac.unqryFacPrint.FieldByName('FASE_FAC').AsString;
    bLanzada :=
      (dmFac.unqryFacPrint.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S')
      or ((sFase <> '') and (not SameText(sFase, 'BORRADOR')));
    if rbActual.Checked and bLanzada then
    begin
      oRepositorioPdf :=
        CrearPersistenciaFacturasUniDAC(ConexionPrincipal).Pdf;
      GuardarPdfFacturaEnBlob(oRepositorioPdf, ContextoSesion,
        sSerie, sNumero, ARuta, FormatoElegido, RegistroLog);
    end;
  end;
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet): string;
var
  iCaracter: Integer;
  RazonSocialCorta: string;
  sDocumento: string;
  sFecha: string;
  TotalFormateado: string;
begin
  RazonSocialCorta := Copy(ADataSet.FieldByName(
                                'RAZON_SOCIAL_CLIENTE_FAC').AsString, 1, 12);
  RazonSocialCorta := StringReplace(RazonSocialCorta, ' ', '', [rfReplaceAll]);
  if not ADataSet.FieldByName('FECHA_FAC').IsNull then
    sFecha := FormatDateTime('dd_mm', ADataSet.FieldByName(
                                                    'FECHA_FAC').AsDateTime)
  else
    sFecha := '00_00';
  TotalFormateado := FormatFloat('0.00', ADataSet.FieldByName(
                                              'TOTAL_LIQUIDO_FAC').AsFloat);
  TotalFormateado := StringReplace(TotalFormateado, ',', '_', [rfReplaceAll]);
  TotalFormateado := StringReplace(TotalFormateado, '.', '_', [rfReplaceAll]);
  sDocumento := FormatearDocumentoDataSet(
    ADataSet,
    'SERIE_FAC',
    'NUMERO_FAC');
  sDocumento := StringReplace(sDocumento, '\', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '/', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '.', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ':', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '*', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '?', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '[', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ']', '_', [rfReplaceAll]);
  Result := sFecha + '_' + sDocumento + '_' + RazonSocialCorta + '_' +
                          TotalFormateado;
  iCaracter := 1;
  while iCaracter <= Length(Result) do
  begin
    if CharInSet(Result[iCaracter],
      [#0..#31, '<', '>', ':', '"', '/', '\', '|', '?', '*']) then
    begin
      Result[iCaracter] := '_';
    end;
    Inc(iCaracter);
  end;
end;

procedure TfrmPrintFac.preparar_consulta;
var
  criterios: TCriteriosInformeFactura;
begin
  criterios := Default(TCriteriosInformeFactura);
  criterios.FacturaActual := True;
  criterios.Serie := edtSerie.Text;
  criterios.Numero := edtNroFac.Text;
  if FPreparadorInforme = nil then
    FPreparadorInforme := CrearPreparadorInformeFacturaUniDAC(
      dmFac.unqryFacPrint,
      dmFac.unqryLinFacPrint);
  FPreparadorInforme.Preparar(criterios);
  // FieldDefs era una fotografia de diseno. La consulta de impresion
  // incorpora campos calculados, por lo que FastReport debe reconstruir
  // su catalogo desde los TField reales despues de cada apertura.
  dmFac.fxdstPrintLinFac.ResetFieldDefs;
  dmFac.fxdsPrintFac.UpdateBounds;
  dmFac.fxdstPrintLinFac.UpdateBounds;
  ConfigurarNombrePDF;
end;

procedure TfrmPrintFac.rbActualClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.rbProcesarFiltradosClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

end.
