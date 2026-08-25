{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoErroresEnvios                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historial y comunicación de los errores enviados al soporte.             }
{******************************************************************************}
unit inMtoErroresEnvios;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Data.DB,
  cxButtons,
  cxClasses,
  cxControls,
  cxDBEdit,
  cxCustomData,
  cxData,
  cxDataStorage,
  cxDBData,
  cxEdit,
  cxFilter,
  cxGraphics,
  cxGrid,
  cxGridCustomTableView,
  cxGridCustomView,
  cxGridDBTableView,
  cxGridLevel,
  cxGridTableView,
  cxLookAndFeels,
  cxLookAndFeelPainters,
  cxLabel,
  cxMemo,
  cxNavigator,
  cxPC,
  cxStyles,
  cxTextEdit,
  dxDateRanges,
  dxScrollbarAnnotations,
  dxSkinsCore,
  dxSkinsDefaultPainters,
  inMtoGen,
  UniDataErroresEnvios;

type
  TfrmMtoErroresEnvios = class(TfrmMtoGen)
    colId: TcxGridDBColumn;
    colReferencia: TcxGridDBColumn;
    colUsuario: TcxGridDBColumn;
    colInstanteError: TcxGridDBColumn;
    colEstado: TcxGridDBColumn;
    colCodigoHttp: TcxGridDBColumn;
    colClaseError: TcxGridDBColumn;
    colMensajeError: TcxGridDBColumn;
    colComentarioTecnico: TcxGridDBColumn;
    colInstanteConsulta: TcxGridDBColumn;
    colEstadoScript: TcxGridDBColumn;
    colEstadoEjecutable: TcxGridDBColumn;
    btnActualizarEstado: TcxButton;
    btnEnviarComentario: TcxButton;
    btnAbrirSeguimiento: TcxButton;
    btnEjecutarScript: TcxButton;
    btnInstalarActualizacion: TcxButton;
    pnlFichaCabecera: TPanel;
    lblReferencia: TcxLabel;
    txtReferencia: TcxDBTextEdit;
    lblEstado: TcxLabel;
    txtEstado: TcxDBTextEdit;
    lblFechaError: TcxLabel;
    txtFechaError: TcxDBTextEdit;
    lblUsuarioError: TcxLabel;
    txtUsuarioError: TcxDBTextEdit;
    lblUltimaConsulta: TcxLabel;
    txtUltimaConsulta: TcxDBTextEdit;
    lblResultadoConsulta: TcxLabel;
    txtResultadoConsulta: TcxDBTextEdit;
    lblEstadoSincronizacion: TcxLabel;
    pcFichaError: TcxPageControl;
    tsComunicacion: TcxTabSheet;
    pnlAccionesComunicacion: TPanel;
    btnFichaActualizar: TcxButton;
    btnFichaResponder: TcxButton;
    btnFichaAbrirSeguimiento: TcxButton;
    memComunicaciones: TcxDBMemo;
    tsDetalleTecnico: TcxTabSheet;
    pnlMensajeError: TPanel;
    lblMensajeError: TcxLabel;
    memMensajeError: TcxDBMemo;
    memDetalleError: TcxDBMemo;
    tsScript: TcxTabSheet;
    pnlCabeceraScript: TPanel;
    lblEstadoScript: TcxLabel;
    txtEstadoScript: TcxDBTextEdit;
    lblDescripcionScript: TcxLabel;
    txtDescripcionScript: TcxDBTextEdit;
    lblHashScript: TcxLabel;
    txtHashScript: TcxDBTextEdit;
    memScript: TcxDBMemo;
    pnlAccionScript: TPanel;
    btnFichaEjecutarScript: TcxButton;
    tsActualizacion: TcxTabSheet;
    pnlCabeceraEjecutable: TPanel;
    lblEstadoEjecutable: TcxLabel;
    txtEstadoEjecutable: TcxDBTextEdit;
    lblVersionEjecutable: TcxLabel;
    txtVersionEjecutable: TcxDBTextEdit;
    lblNombreEjecutable: TcxLabel;
    txtNombreEjecutable: TcxDBTextEdit;
    lblTamanoEjecutable: TcxLabel;
    txtTamanoEjecutable: TcxDBTextEdit;
    pnlDetalleEjecutable: TPanel;
    lblDescripcionEjecutable: TcxLabel;
    memDescripcionEjecutable: TcxDBMemo;
    lblUrlEjecutable: TcxLabel;
    txtUrlEjecutable: TcxDBTextEdit;
    lblHashEjecutable: TcxLabel;
    txtHashEjecutable: TcxDBTextEdit;
    pnlAccionEjecutable: TPanel;
    btnFichaInstalarActualizacion: TcxButton;
    procedure btnActualizarEstadoClick(Sender: TObject);
    procedure btnEnviarComentarioClick(Sender: TObject);
    procedure btnAbrirSeguimientoClick(Sender: TObject);
    procedure btnEjecutarScriptClick(Sender: TObject);
    procedure btnInstalarActualizacionClick(Sender: TObject);
    procedure tsFichaDetalleShow(Sender: TObject);
  private
    FSincronizando: Boolean;
    dmmErroresEnvios: TdmErroresEnvios;
    function CampoTexto(const ANombre: string): string;
    function HayRegistroActual(AMostrarAviso: Boolean = True): Boolean;
    procedure ActualizarAccionesFicha;
    procedure SincronizarFicha(AMostrarResultado: Boolean);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  Winapi.ShellAPI,
  System.UITypes,
  inLibActualizacionSoporte,
  inLibAnfitrionMtoIntf,
  inLibSeguimientoErrores,
  inMtoModalMensajeTexto;

{$R *.dfm}

resourcestring
  SErrorEnvioErrorNoSeleccionado = 'Seleccione un envío de error.';
  SInfoSeguimientoEnvioErrorActualizado =
    'Estado, mensajes y propuestas actualizados.';
  STituloComentarioEnvioError =
    'Comentario para el desarrollador o técnico';
  SErrorComentarioEnvioErrorVacio = 'Escriba un comentario.';
  SInfoComentarioEnvioErrorEnviado =
    'Comentario enviado correctamente.';
  SInfoEnlaceSeguimientoEnvioErrorNoDisponible =
    'Este envío no dispone de un enlace de seguimiento.';
  SInfoScriptSoporteNoPendiente =
    'No hay un script pendiente o aún no se ha sincronizado.';
  SDetalleScriptSoporte =
    'Descripción:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'SHA-256:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Script SQL:' + sLineBreak + '%s';
  SPreguntaEjecutarScriptSoporte =
    '¿Desea crear una copia de seguridad y ejecutar este script?';
  SErrorServicioCopiaSeguridadNoDisponible =
    'No está disponible el servicio de copia de seguridad.';
  SInfoScriptSoporteEjecutado = 'Script ejecutado correctamente.';
  SInfoActualizacionSoporteNoPendiente =
    'No hay una actualización pendiente o aún no se ha sincronizado.';
  SDetalleActualizacionSoporte =
    'Versión: %s' + sLineBreak + 'Descripción:' + sLineBreak + '%s' +
    sLineBreak + sLineBreak + 'Tamaño: %s bytes' + sLineBreak +
    'SHA-256:' + sLineBreak + '%s';
  SPreguntaInstalarActualizacionSoporte =
    '¿Desea instalar esta actualización y reiniciar Factuzam?';

procedure TfrmMtoErroresEnvios.CrearTablaPrincipal;
begin
  inherited;
  dmmErroresEnvios := tdmDataModule as TdmErroresEnvios;
  dmmErroresEnvios.ConfigurarVisibilidad(
    IdentidadSesion.Usuario,
    IdentidadSesion.EsAdministrador);
  pkFieldName := 'ID_ERENV';
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.ShortCut := 0;
  actInsertarRegistro.OnExecute := nil;
  actEliminarRegistro.ShortCut := 0;
  actEliminarRegistro.OnExecute := nil;
end;

procedure TfrmMtoErroresEnvios.ResetForm;
begin
  inherited;
end;

function TfrmMtoErroresEnvios.HayRegistroActual(
  AMostrarAviso: Boolean): Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty;
  if not Result and AMostrarAviso then
    MessageDlg(
      SErrorEnvioErrorNoSeleccionado,
      mtInformation,
      [mbOk],
      0);
end;

function TfrmMtoErroresEnvios.CampoTexto(
  const ANombre: string): string;
begin
  Result := '';
  if HayRegistroActual(False) then
    Result := dsTablaG.DataSet.FieldByName(ANombre).AsString;
end;

procedure TfrmMtoErroresEnvios.ActualizarAccionesFicha;
var
  bEjecutablePendiente: Boolean;
  bScriptPendiente: Boolean;
begin
  bScriptPendiente := HayRegistroActual(False) and
    SameText(CampoTexto('ESTADO_SCRIPT_ERENV'), 'PROPUESTO') and
    (Trim(CampoTexto('SCRIPT_SQL_ERENV')) <> '');
  bEjecutablePendiente := HayRegistroActual(False) and
    SameText(CampoTexto('ESTADO_EJECUTABLE_ERENV'), 'PROPUESTO') and
    (Trim(CampoTexto('URL_EJECUTABLE_ERENV')) <> '');
  btnEjecutarScript.Enabled := bScriptPendiente;
  btnFichaEjecutarScript.Enabled := bScriptPendiente;
  btnInstalarActualizacion.Enabled := bEjecutablePendiente;
  btnFichaInstalarActualizacion.Enabled := bEjecutablePendiente;
end;

procedure TfrmMtoErroresEnvios.SincronizarFicha(
  AMostrarResultado: Boolean);
var
  CursorAnterior: TCursor;
  sError: string;
begin
  if not FSincronizando and Assigned(dmmErroresEnvios) and
     HayRegistroActual(False) then
  begin
    FSincronizando := True;
    CursorAnterior := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    lblEstadoSincronizacion.Caption :=
      'Consultando mensajes y propuestas del soporte...';
    lblEstadoSincronizacion.Style.TextColor := clNavy;
    lblEstadoSincronizacion.Repaint;
    try
      if dmmErroresEnvios.ActualizarActual(sError) then
      begin
        lblEstadoSincronizacion.Caption :=
          'Seguimiento actualizado dentro de Factuzam.';
        lblEstadoSincronizacion.Style.TextColor := clGreen;
        if AMostrarResultado then
          MessageDlg(
            SInfoSeguimientoEnvioErrorActualizado,
            mtInformation,
            [mbOk],
            0);
      end
      else
      begin
        lblEstadoSincronizacion.Caption :=
          'No se pudo actualizar: ' + sError;
        lblEstadoSincronizacion.Style.TextColor := clRed;
        if AMostrarResultado then
          MessageDlg(sError, mtError, [mbOk], 0);
      end;
    finally
      ActualizarAccionesFicha;
      Screen.Cursor := CursorAnterior;
      FSincronizando := False;
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.tsFichaDetalleShow(Sender: TObject);
begin
  inherited tsFichaShow(Sender);
  SincronizarFicha(False);
end;

procedure TfrmMtoErroresEnvios.btnActualizarEstadoClick(
  Sender: TObject);
begin
  if HayRegistroActual then
    SincronizarFicha(True);
end;

procedure TfrmMtoErroresEnvios.btnEnviarComentarioClick(
  Sender: TObject);
var
  sError: string;
  sMensaje: string;
begin
  if HayRegistroActual then
  begin
    sMensaje := '';
    if TfrmModalMensajeTexto.Solicitar(
         Self,
         STituloComentarioEnvioError,
         sMensaje) then
    begin
      if Trim(sMensaje) = '' then
        MessageDlg(SErrorComentarioEnvioErrorVacio,
          mtWarning, [mbOk], 0)
      else if dmmErroresEnvios.EnviarComentarioActual(
                sMensaje,
                sError) then
      begin
        lblEstadoSincronizacion.Caption :=
          'Comentario enviado y conversación actualizada.';
        lblEstadoSincronizacion.Style.TextColor := clGreen;
        MessageDlg(
          SInfoComentarioEnvioErrorEnviado,
          mtInformation,
          [mbOk],
          0);
      end
      else
        MessageDlg(sError, mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.btnAbrirSeguimientoClick(
  Sender: TObject);
var
  sUrl: string;
begin
  if HayRegistroActual then
  begin
    sUrl := CampoTexto('URL_SEGUIMIENTO_ERENV');
    if Trim(sUrl) <> '' then
      ShellExecute(Handle, 'open', PChar(sUrl), nil, nil, SW_SHOWNORMAL)
    else
      MessageDlg(
        SInfoEnlaceSeguimientoEnvioErrorNoDisponible,
        mtInformation,
        [mbOk],
        0);
  end;
end;

procedure TfrmMtoErroresEnvios.btnEjecutarScriptClick(
  Sender: TObject);
var
  Anfitrion: IAnfitrionMantenimiento;
  iId: Int64;
  sDescripcion: string;
  sError: string;
  sEstado: string;
  sHash: string;
  sSql: string;
  sTexto: string;
begin
  if HayRegistroActual then
  begin
    iId := dsTablaG.DataSet.FieldByName(
      'ID_SCRIPT_REMOTO_ERENV').AsLargeInt;
    sSql := CampoTexto('SCRIPT_SQL_ERENV');
    sDescripcion := CampoTexto('DESCRIPCION_SCRIPT_ERENV');
    sEstado := CampoTexto('ESTADO_SCRIPT_ERENV');
    sHash := CampoTexto('SHA256_SCRIPT_ERENV');
    if (iId <= 0) or (Trim(sSql) = '') or
       not SameText(sEstado, 'PROPUESTO') then
      MessageDlg(
        SInfoScriptSoporteNoPendiente,
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := Format(SDetalleScriptSoporte,
        [sDescripcion, sHash, sSql]);
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg(
           SPreguntaEjecutarScriptSoporte,
           mtWarning,
           [mbYes, mbNo],
           0) = mrYes then
      begin
        Anfitrion := FAnfitrionMto;
        if not Assigned(Anfitrion) then
          MessageDlg(
            SErrorServicioCopiaSeguridadNoDisponible,
            mtError,
            [mbOk],
            0)
        else if Anfitrion.CrearCopiaPreviaScriptSoporte then
        begin
          if dmmErroresEnvios.EjecutarScriptActual(sError) then
          begin
            ActualizarAccionesFicha;
            if sError = '' then
              MessageDlg(
                SInfoScriptSoporteEjecutado,
                mtInformation,
                [mbOk],
                0)
            else
              MessageDlg(sError, mtWarning, [mbOk], 0);
          end
          else
            MessageDlg(sError, mtError, [mbOk], 0);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.btnInstalarActualizacionClick(
  Sender: TObject);
var
  iBytes: Int64;
  iId: Int64;
  sAnterior: string;
  sDescripcion: string;
  sError: string;
  sEstado: string;
  sHash: string;
  sNotificacion: string;
  sTexto: string;
  sUrl: string;
  sVersion: string;
begin
  if HayRegistroActual then
  begin
    iId := dsTablaG.DataSet.FieldByName(
      'ID_EJECUTABLE_REMOTO_ERENV').AsLargeInt;
    sUrl := CampoTexto('URL_EJECUTABLE_ERENV');
    sDescripcion := CampoTexto('DESCRIPCION_EJECUTABLE_ERENV');
    sVersion := CampoTexto('VERSION_EJECUTABLE_ERENV');
    sEstado := CampoTexto('ESTADO_EJECUTABLE_ERENV');
    sHash := CampoTexto('SHA256_EJECUTABLE_ERENV');
    iBytes := dsTablaG.DataSet.FieldByName(
      'CANTIDAD_BYTES_EJECUTABLE_ERENV').AsLargeInt;
    if (iId <= 0) or (Trim(sUrl) = '') or
       not SameText(sEstado, 'PROPUESTO') then
      MessageDlg(
        SInfoActualizacionSoporteNoPendiente,
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := Format(SDetalleActualizacionSoporte,
        [sVersion, sDescripcion, FormatFloat('#,##0', iBytes), sHash]);
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg(
           SPreguntaInstalarActualizacionSoporte,
           mtWarning,
           [mbYes, mbNo],
           0) = mrYes then
      begin
        if InstalarActualizacionSoporte(
             sUrl,
             sHash,
             iBytes,
             sAnterior,
             sError) then
        begin
          NotificarResultadoEjecutableError(
            CampoTexto('URL_SERVICIO_ERENV'),
            CampoTexto('REFERENCIA_ERENV'),
            CampoTexto('TOKEN_SEGUIMIENTO_ERENV'),
            iId,
            'INSTALADO',
            'Actualización aceptada; Factuzam se está reiniciando.',
            sNotificacion);
          Application.Terminate;
        end
        else
        begin
          NotificarResultadoEjecutableError(
            CampoTexto('URL_SERVICIO_ERENV'),
            CampoTexto('REFERENCIA_ERENV'),
            CampoTexto('TOKEN_SEGUIMIENTO_ERENV'),
            iId,
            'ERROR',
            sError,
            sNotificacion);
          MessageDlg(sError, mtError, [mbOk], 0);
        end;
      end;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoErroresEnvios);

end.
