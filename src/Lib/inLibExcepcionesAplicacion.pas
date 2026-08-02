{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExcepcionesAplicacion                                    }
{    Tipo:       Servicio                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registra, presenta y permite enviar las excepciones de la aplicación.     }
{******************************************************************************}
unit inLibExcepcionesAplicacion;

interface

uses
  inLibContextoSesionIntf,
  inLibExcepcionesAplicacionIntf,
  inLibLogIntf;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog
): IGestorExcepcionesAplicacion;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.UITypes,
  Vcl.Clipbrd,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  cxButtons,
  cxCheckBox,
  cxLabel,
  cxMemo,
  cxTextEdit,
  inLibEnvioErroresIntf,
  inLibGlobalVar,
  inLibMsgComun,
  inLibWin;

type
  TGestorExcepcionesAplicacion = class(
    TInterfacedObject,
    IGestorExcepcionesAplicacion)
  private
    FBotonActivarLog: TcxButton;
    FBotonEnviar: TcxButton;
    FChkEnviarCopia: TcxCheckBox;
    FContextoSesion: IContextoSesionAplicacion;
    FDialogo: TForm;
    FEdtEmail: TcxTextEdit;
    FEdtTelefono: TcxTextEdit;
    FEvidencia: TEvidenciaError;
    FLblEvidencias: TcxLabel;
    FLblEstadoLog: TcxLabel;
    FMemoDescripcion: TcxMemo;
    FMemoDetalle: TcxMemo;
    FRegistroLog: IRegistroLog;
    FServicioEnvioErrores: IServicioEnvioErrores;
    function ConstruirDetalle(Sender: TObject;
      E: Exception): string;
    procedure ActivarLogClick(Sender: TObject);
    procedure ActualizarEstadoLog;
    procedure ConfigurarDialogo;
    procedure CopiaSeguridadCambio(Sender: TObject);
    procedure CopiarDetalleClick(Sender: TObject);
    procedure CrearMemoDetalle(const ATexto: string);
    procedure CrearPanelBotones;
    procedure CrearPanelContacto;
    procedure EnviarDesarrolladorClick(Sender: TObject);
    procedure MostrarDetalle(const ATexto: string);
    procedure MostrarFallback(E: Exception);
    procedure PrepararEvidencia(E: Exception;
      const ADetalle: string);
    function PrepararCopiaSeguridad: Boolean;
    function PreguntarActivacionLog: Boolean;
    procedure RegistrarDetalleSeguro(E: Exception;
      const ADetalle: string);
    procedure RegistrarRuidoSeguro(E: Exception);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const ARegistroLog: IRegistroLog);
    procedure Gestionar(Sender: TObject; E: Exception);
    procedure AsignarServicioEnvioErrores(
      const AServicio: IServicioEnvioErrores);
  end;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog
): IGestorExcepcionesAplicacion;
begin
  Result := TGestorExcepcionesAplicacion.Create(
    AContextoSesion,
    ARegistroLog);
end;

constructor TGestorExcepcionesAplicacion.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
end;

procedure TGestorExcepcionesAplicacion.AsignarServicioEnvioErrores(
  const AServicio: IServicioEnvioErrores);
begin
  FServicioEnvioErrores := AServicio;
end;

function TGestorExcepcionesAplicacion.ConstruirDetalle(
  Sender: TObject;
  E: Exception): string;
begin
  Result := ConstruirDetalleExcepcionAplicacion(
    Sender,
    E,
    FContextoSesion.Identidad,
    FContextoSesion.Ubicacion,
    oAppName,
    oVersion,
    GetComputerName,
    Now,
    ExceptAddr);
end;

procedure TGestorExcepcionesAplicacion.RegistrarRuidoSeguro(
  E: Exception);
begin
  try
    FRegistroLog.RegistrarAviso(
      'AppException ignorado (editor inplace sin Parent): ' +
      E.Message);
  except
    on EFalloLog: Exception do
      OutputDebugString(PChar(
        'Factuzam: fallo al registrar AppException: ' +
        EFalloLog.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.RegistrarDetalleSeguro(
  E: Exception;
  const ADetalle: string);
begin
  try
    FRegistroLog.RegistrarError(
      'AppException ' + E.ClassName + ': ' + E.Message);
    FRegistroLog.RegistrarError(
      'AppException detalle:' + sLineBreak + ADetalle);
  except
    on EFalloLog: Exception do
      OutputDebugString(PChar(
        'Factuzam: fallo al registrar AppException: ' +
        EFalloLog.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.PrepararEvidencia(
  E: Exception;
  const ADetalle: string);
begin
  FEvidencia := Default(TEvidenciaError);
  if Assigned(FServicioEnvioErrores) then
  begin
    FEvidencia := FServicioEnvioErrores.Preparar(
      E.ClassName,
      E.Message,
      ADetalle);
  end;
end;

procedure TGestorExcepcionesAplicacion.Gestionar(
  Sender: TObject;
  E: Exception);
var
  sDetalle: string;
begin
  if EsRuidoEditorInplace(E) then
    RegistrarRuidoSeguro(E)
  else
  begin
    try
      sDetalle := ConstruirDetalle(Sender, E);
      RegistrarDetalleSeguro(E, sDetalle);
      PrepararEvidencia(E, sDetalle);
      MostrarDetalle(sDetalle);
    except
      MostrarFallback(E);
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.MostrarFallback(E: Exception);
begin
  try
    Application.ShowException(E);
  except
    on EFalloUI: Exception do
      OutputDebugString(PChar(
        'Factuzam: fallo al mostrar AppException: ' +
        EFalloUI.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.ConfigurarDialogo;
begin
  FDialogo.Caption := STituloErrorProducido;
  FDialogo.Position := poScreenCenter;
  FDialogo.Width := 860;
  FDialogo.Height := 744;
  FDialogo.BorderStyle := bsSizeable;
  FDialogo.BorderIcons := [biSystemMenu];
  FDialogo.KeyPreview := True;
end;

procedure ConfigurarEtiqueta(
  AEtiqueta: TcxLabel;
  AParent: TWinControl;
  ALeft, ATop, AWidth, AHeight: Integer;
  const ACaption: string);
begin
  AEtiqueta.Parent := AParent;
  AEtiqueta.Left := ALeft;
  AEtiqueta.Top := ATop;
  AEtiqueta.Width := AWidth;
  AEtiqueta.Height := AHeight;
  AEtiqueta.AutoSize := False;
  AEtiqueta.Properties.WordWrap := True;
  AEtiqueta.Caption := ACaption;
end;

function SolicitarContrasenaCopia(
  AOwner: TCustomForm;
  out AContrasena: string): Boolean;
var
  BotonAceptar: TcxButton;
  BotonCancelar: TcxButton;
  Dialogo: TForm;
  EdtConfirmacion: TcxTextEdit;
  EdtContrasena: TcxTextEdit;
  LabelConfirmacion: TcxLabel;
  LabelContrasena: TcxLabel;
  LabelExplicacion: TcxLabel;
  bTerminar: Boolean;
  iResultado: Integer;
begin
  Result := False;
  AContrasena := '';
  Dialogo := TForm.Create(AOwner);
  try
    Dialogo.Caption := STituloContrasenaCopiaError;
    Dialogo.Position := poOwnerFormCenter;
    Dialogo.BorderIcons := [];
    Dialogo.BorderStyle := bsDialog;
    Dialogo.ClientWidth := 520;
    Dialogo.ClientHeight := 224;
    LabelExplicacion := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelExplicacion,
      Dialogo,
      24,
      16,
      472,
      48,
      SInfoContrasenaCopiaError);
    LabelContrasena := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelContrasena,
      Dialogo,
      24,
      77,
      144,
      24,
      SCaptionContrasenaCopiaError);
    EdtContrasena := TcxTextEdit.Create(Dialogo);
    EdtContrasena.Parent := Dialogo;
    EdtContrasena.SetBounds(176, 75, 320, 26);
    EdtContrasena.Properties.EchoMode := eemPassword;
    EdtContrasena.Properties.PasswordChar := #9679;
    LabelConfirmacion := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelConfirmacion,
      Dialogo,
      24,
      117,
      144,
      24,
      SCaptionRepetirContrasenaCopiaError);
    EdtConfirmacion := TcxTextEdit.Create(Dialogo);
    EdtConfirmacion.Parent := Dialogo;
    EdtConfirmacion.SetBounds(176, 115, 320, 26);
    EdtConfirmacion.Properties.EchoMode := eemPassword;
    EdtConfirmacion.Properties.PasswordChar := #9679;
    BotonCancelar := TcxButton.Create(Dialogo);
    BotonCancelar.Parent := Dialogo;
    BotonCancelar.SetBounds(152, 171, 160, 32);
    BotonCancelar.Caption := SCaptionCancelar;
    BotonCancelar.Cancel := True;
    BotonCancelar.ModalResult := mrCancel;
    BotonAceptar := TcxButton.Create(Dialogo);
    BotonAceptar.Parent := Dialogo;
    BotonAceptar.SetBounds(328, 171, 168, 32);
    BotonAceptar.Caption := SCaptionAceptar;
    BotonAceptar.Default := True;
    BotonAceptar.ModalResult := mrOk;
    Dialogo.ActiveControl := EdtContrasena;
    bTerminar := False;
    while not bTerminar do
    begin
      iResultado := Dialogo.ShowModal;
      if iResultado <> mrOk then
        bTerminar := True
      else if Trim(EdtContrasena.Text) = '' then
      begin
        MessageDlg(
          SErrorContrasenaCopiaErrorVacia,
          mtWarning,
          [mbOk],
          0);
        EdtContrasena.SetFocus;
      end
      else if EdtContrasena.Text <> EdtConfirmacion.Text then
      begin
        MessageDlg(
          SErrorContrasenasCopiaErrorNoCoinciden,
          mtWarning,
          [mbOk],
          0);
        EdtConfirmacion.SetFocus;
      end
      else
      begin
        AContrasena := EdtContrasena.Text;
        Result := True;
        bTerminar := True;
      end;
    end;
    EdtContrasena.Text := '';
    EdtConfirmacion.Text := '';
  finally
    FreeAndNil(Dialogo);
  end;
end;

procedure TGestorExcepcionesAplicacion.CrearPanelContacto;
var
  LabelDescripcion: TcxLabel;
  LabelEmail: TcxLabel;
  LabelTelefono: TcxLabel;
  Panel: TPanel;
begin
  Panel := TPanel.Create(FDialogo);
  Panel.Parent := FDialogo;
  Panel.Align := alTop;
  Panel.Height := 234;
  Panel.BevelOuter := bvNone;
  FLblEvidencias := TcxLabel.Create(FDialogo);
  ConfigurarEtiqueta(
    FLblEvidencias,
    Panel,
    12,
    8,
    820,
    42,
    SCaptionDetalleErrorCabecera + ' ' + SInfoEvidenciasError);
  LabelEmail := TcxLabel.Create(FDialogo);
  ConfigurarEtiqueta(
    LabelEmail,
    Panel,
    12,
    56,
    125,
    24,
    SCaptionEmailContactoError);
  FEdtEmail := TcxTextEdit.Create(FDialogo);
  FEdtEmail.Parent := Panel;
  FEdtEmail.SetBounds(140, 54, 290, 26);
  LabelTelefono := TcxLabel.Create(FDialogo);
  ConfigurarEtiqueta(
    LabelTelefono,
    Panel,
    450,
    56,
    150,
    24,
    SCaptionTelefonoContactoError);
  FEdtTelefono := TcxTextEdit.Create(FDialogo);
  FEdtTelefono.Parent := Panel;
  FEdtTelefono.SetBounds(600, 54, 232, 26);
  LabelDescripcion := TcxLabel.Create(FDialogo);
  ConfigurarEtiqueta(
    LabelDescripcion,
    Panel,
    12,
    88,
    820,
    24,
    SCaptionDescripcionError);
  FMemoDescripcion := TcxMemo.Create(FDialogo);
  FMemoDescripcion.Parent := Panel;
  FMemoDescripcion.SetBounds(12, 112, 820, 48);
  FMemoDescripcion.Anchors := [akLeft, akTop, akRight];
  FChkEnviarCopia := TcxCheckBox.Create(FDialogo);
  FChkEnviarCopia.Parent := Panel;
  FChkEnviarCopia.SetBounds(12, 164, 820, 24);
  FChkEnviarCopia.Caption := SCaptionEnviarCopiaSeguridadError;
  FChkEnviarCopia.Enabled := Assigned(FServicioEnvioErrores);
  FChkEnviarCopia.OnClick := CopiaSeguridadCambio;
  FLblEstadoLog := TcxLabel.Create(FDialogo);
  ConfigurarEtiqueta(
    FLblEstadoLog,
    Panel,
    12,
    190,
    820,
    38,
    '');
  ActualizarEstadoLog;
end;

procedure TGestorExcepcionesAplicacion.CopiaSeguridadCambio(
  Sender: TObject);
begin
  if FChkEnviarCopia.Checked then
  begin
    FLblEvidencias.Caption := SInfoEvidenciasCopiaError;
    FLblEstadoLog.Caption := SInfoCopiaSeguridadError;
    FLblEstadoLog.Style.TextColor := clNavy;
    if Assigned(FBotonActivarLog) then
      FBotonActivarLog.Visible := False;
  end
  else
  begin
    if Assigned(FServicioEnvioErrores) then
      FServicioEnvioErrores.DescartarCopiaSeguridad(FEvidencia);
    FLblEvidencias.Caption := SCaptionDetalleErrorCabecera + ' ' +
      SInfoEvidenciasError;
    ActualizarEstadoLog;
    if Assigned(FBotonActivarLog) then
    begin
      FBotonActivarLog.Visible :=
        Assigned(FServicioEnvioErrores) and
        not FEvidencia.Log.Completo;
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.ActualizarEstadoLog;
begin
  if not Assigned(FServicioEnvioErrores) then
  begin
    FLblEstadoLog.Caption := SErrorNoSePudoEnviarError;
    FLblEstadoLog.Style.TextColor := clMaroon;
  end
  else if FEvidencia.Log.Completo then
  begin
    FLblEstadoLog.Caption := SInfoLogErrorCompleto;
    FLblEstadoLog.Style.TextColor := clGreen;
  end
  else
  begin
    FLblEstadoLog.Caption := SAvisoLogErrorIncompleto;
    FLblEstadoLog.Style.TextColor := clMaroon;
  end;
end;

procedure TGestorExcepcionesAplicacion.CrearPanelBotones;
var
  BotonCerrar: TcxButton;
  BotonCopiar: TcxButton;
  Panel: TPanel;
begin
  Panel := TPanel.Create(FDialogo);
  Panel.Parent := FDialogo;
  Panel.Align := alBottom;
  Panel.Height := 52;
  Panel.BevelOuter := bvNone;
  BotonCerrar := TcxButton.Create(FDialogo);
  BotonCerrar.Parent := Panel;
  BotonCerrar.SetBounds(732, 8, 100, 32);
  BotonCerrar.Anchors := [akRight, akTop];
  BotonCerrar.Caption := SCaptionCerrar;
  BotonCerrar.ModalResult := mrOk;
  BotonCerrar.Default := True;
  BotonCerrar.Cancel := True;
  BotonCopiar := TcxButton.Create(FDialogo);
  BotonCopiar.Parent := Panel;
  BotonCopiar.SetBounds(534, 8, 190, 32);
  BotonCopiar.Anchors := [akRight, akTop];
  BotonCopiar.Caption := SCaptionCopiarPortapapeles;
  BotonCopiar.OnClick := CopiarDetalleClick;
  FBotonEnviar := TcxButton.Create(FDialogo);
  FBotonEnviar.Parent := Panel;
  FBotonEnviar.SetBounds(356, 8, 170, 32);
  FBotonEnviar.Anchors := [akRight, akTop];
  FBotonEnviar.Caption := SCaptionEnviarDesarrollador;
  FBotonEnviar.Enabled := Assigned(FServicioEnvioErrores);
  FBotonEnviar.OnClick := EnviarDesarrolladorClick;
  FBotonActivarLog := TcxButton.Create(FDialogo);
  FBotonActivarLog.Parent := Panel;
  FBotonActivarLog.SetBounds(12, 8, 180, 32);
  FBotonActivarLog.Caption := SCaptionActivarLogCompleto;
  FBotonActivarLog.Visible :=
    Assigned(FServicioEnvioErrores) and
    not FEvidencia.Log.Completo;
  FBotonActivarLog.OnClick := ActivarLogClick;
  FDialogo.ActiveControl := BotonCerrar;
end;

procedure TGestorExcepcionesAplicacion.CrearMemoDetalle(
  const ATexto: string);
begin
  FMemoDetalle := TcxMemo.Create(FDialogo);
  FMemoDetalle.Parent := FDialogo;
  FMemoDetalle.Align := alClient;
  FMemoDetalle.Properties.ReadOnly := True;
  FMemoDetalle.Properties.ScrollBars := ssBoth;
  FMemoDetalle.Properties.WordWrap := False;
  FMemoDetalle.Style.Font.Name := 'Consolas';
  FMemoDetalle.Style.Font.Size := 9;
  FMemoDetalle.Text := ATexto;
end;

procedure TGestorExcepcionesAplicacion.MostrarDetalle(
  const ATexto: string);
begin
  FDialogo := TForm.Create(nil);
  try
    ConfigurarDialogo;
    CrearPanelContacto;
    CrearPanelBotones;
    CrearMemoDetalle(ATexto);
    FDialogo.ShowModal;
  finally
    if Assigned(FServicioEnvioErrores) then
      FServicioEnvioErrores.Limpiar(FEvidencia);
    FBotonActivarLog := nil;
    FBotonEnviar := nil;
    FChkEnviarCopia := nil;
    FEdtEmail := nil;
    FEdtTelefono := nil;
    FLblEvidencias := nil;
    FLblEstadoLog := nil;
    FMemoDescripcion := nil;
    FMemoDetalle := nil;
    FreeAndNil(FDialogo);
  end;
end;

function TGestorExcepcionesAplicacion.PreguntarActivacionLog:
  Boolean;
begin
  Result := True;
  if Assigned(FServicioEnvioErrores) and
     not FEvidencia.Log.Completo then
  begin
    if MessageDlg(
         SPreguntaActivarLogCompleto,
         mtConfirmation,
         [mbYes, mbNo],
         0) = mrYes then
    begin
      ActivarLogClick(nil);
      Result := False;
    end;
  end;
end;

function TGestorExcepcionesAplicacion.PrepararCopiaSeguridad:
  Boolean;
var
  sContrasena: string;
  sError: string;
begin
  Result := FileExists(FEvidencia.RutaCopiaSeguridad);
  sContrasena := '';
  if not Result then
  begin
    Screen.Cursor := crDefault;
    Result := SolicitarContrasenaCopia(
      FDialogo,
      sContrasena);
    if Result then
    begin
      Screen.Cursor := crHourGlass;
      FLblEstadoLog.Caption := SInfoPreparandoCopiaSeguridadError;
      FLblEstadoLog.Style.TextColor := clNavy;
      FLblEstadoLog.Repaint;
      Result := FServicioEnvioErrores.PrepararCopiaSeguridad(
        FEvidencia,
        sContrasena,
        sError);
      if not Result then
      begin
        Screen.Cursor := crDefault;
        MessageDlg(
          Format(SErrorPrepararCopiaSeguridadError, [sError]),
          mtError,
          [mbOk],
          0);
      end;
      CopiaSeguridadCambio(nil);
    end;
  end;
  sContrasena := '';
end;

procedure TGestorExcepcionesAplicacion.ActivarLogClick(
  Sender: TObject);
begin
  if Assigned(FServicioEnvioErrores) then
  begin
    FServicioEnvioErrores.ActivarDiagnosticoCompleto;
    FLblEstadoLog.Caption := SInfoLogActivadoRepetir;
    FLblEstadoLog.Style.TextColor := clGreen;
    FBotonActivarLog.Enabled := False;
  end;
end;

procedure TGestorExcepcionesAplicacion.EnviarDesarrolladorClick(
  Sender: TObject);
var
  bContinuar: Boolean;
  bEnviarCopia: Boolean;
  Contacto: TContactoError;
  Resultado: TResultadoEnvioError;
  sMensaje: string;
begin
  Contacto.Email := Trim(FEdtEmail.Text);
  Contacto.Telefono := Trim(FEdtTelefono.Text);
  Contacto.Descripcion := FMemoDescripcion.Text;
  if not EmailSoporteValido(Contacto.Email) or
     not TelefonoSoporteValido(Contacto.Telefono) then
  begin
    MessageDlg(
      SErrorContactoEnvioErrorNoValido,
      mtWarning,
      [mbOk],
      0);
  end
  else
  begin
    bEnviarCopia := FChkEnviarCopia.Checked;
    if bEnviarCopia then
      bContinuar := True
    else
      bContinuar := PreguntarActivacionLog;
    if bContinuar then
    begin
      FBotonEnviar.Enabled := False;
      Screen.Cursor := crHourGlass;
      try
        if bEnviarCopia then
          bContinuar := PrepararCopiaSeguridad;
        if bContinuar then
        begin
          Resultado := FServicioEnvioErrores.Enviar(
            FEvidencia,
            Contacto);
        end;
      finally
        Screen.Cursor := crDefault;
      end;
      if bContinuar then
      begin
        sMensaje := Resultado.Mensaje;
        if Resultado.Ok then
        begin
          sMensaje := Format(
            SInfoErrorEnviado,
            [Resultado.Referencia]);
          if Resultado.UrlSeguimiento <> '' then
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(
                SInfoSeguimientoError,
                [Resultado.UrlSeguimiento]);
          end;
          if bEnviarCopia then
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(
                SInfoEnviarContrasenaCopiaError,
                [Resultado.Referencia]);
          end;
          FMemoDetalle.Lines.Insert(0, sMensaje + sLineBreak);
          FRegistroLog.RegistrarInformacion(sMensaje);
          MessageDlg(sMensaje, mtInformation, [mbOk], 0);
        end
        else
        begin
          FBotonEnviar.Enabled := True;
          FRegistroLog.RegistrarAviso(
            'No se pudo enviar AppException: ' + sMensaje);
          MessageDlg(sMensaje, mtError, [mbOk], 0);
        end;
      end;
      if not bContinuar then
        FBotonEnviar.Enabled := True;
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.CopiarDetalleClick(
  Sender: TObject);
begin
  if Assigned(FMemoDetalle) then
  begin
    try
      Clipboard.AsText := FMemoDetalle.Text;
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'No se pudo copiar al portapapeles: ' + E.Message);
    end;
  end;
end;

end.
