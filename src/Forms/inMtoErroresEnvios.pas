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
  cxNavigator,
  cxStyles,
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
    procedure btnActualizarEstadoClick(Sender: TObject);
    procedure btnEnviarComentarioClick(Sender: TObject);
    procedure btnAbrirSeguimientoClick(Sender: TObject);
    procedure btnEjecutarScriptClick(Sender: TObject);
    procedure btnInstalarActualizacionClick(Sender: TObject);
  private
    dmmErroresEnvios: TdmErroresEnvios;
    function CampoTexto(const ANombre: string): string;
    function HayRegistroActual: Boolean;
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

function TfrmMtoErroresEnvios.HayRegistroActual: Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty;
  if not Result then
    MessageDlg(
      'Seleccione un envío de error.',
      mtInformation,
      [mbOk],
      0);
end;

function TfrmMtoErroresEnvios.CampoTexto(
  const ANombre: string): string;
begin
  Result := '';
  if HayRegistroActual then
    Result := dsTablaG.DataSet.FieldByName(ANombre).AsString;
end;

procedure TfrmMtoErroresEnvios.btnActualizarEstadoClick(
  Sender: TObject);
var
  sError: string;
begin
  if HayRegistroActual then
  begin
    if dmmErroresEnvios.ActualizarActual(sError) then
      MessageDlg(
        'Estado y comunicaciones actualizados.',
        mtInformation,
        [mbOk],
        0)
    else
      MessageDlg(sError, mtError, [mbOk], 0);
  end;
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
    if InputQuery(
      'Enviar comentario',
      'Comentario para el desarrollador o técnico:',
      sMensaje) then
    begin
      if Trim(sMensaje) = '' then
        MessageDlg('Escriba un comentario.', mtWarning, [mbOk], 0)
      else if dmmErroresEnvios.EnviarComentarioActual(
                sMensaje,
                sError) then
        MessageDlg(
          'Comentario enviado correctamente.',
          mtInformation,
          [mbOk],
          0)
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
        'Este envío no dispone de un enlace de seguimiento.',
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
        'No hay un script pendiente o aún no se ha sincronizado.',
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := 'Descripción:' + sLineBreak + sDescripcion +
        sLineBreak + sLineBreak + 'SHA-256:' + sLineBreak + sHash +
        sLineBreak + sLineBreak + 'Script SQL:' + sLineBreak + sSql;
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg(
           '¿Desea crear una copia de seguridad y ejecutar este script?',
           mtWarning,
           [mbYes, mbNo],
           0) = mrYes then
      begin
        if not Supports(
                 Owner,
                 IAnfitrionMantenimiento,
                 Anfitrion) then
          MessageDlg(
            'No está disponible el servicio de copia de seguridad.',
            mtError,
            [mbOk],
            0)
        else if Anfitrion.CrearCopiaPreviaScriptSoporte then
        begin
          if dmmErroresEnvios.EjecutarScriptActual(sError) then
          begin
            if sError = '' then
              MessageDlg(
                'Script ejecutado correctamente.',
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
        'No hay una actualización pendiente o aún no se ha sincronizado.',
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := 'Versión: ' + sVersion + sLineBreak +
        'Descripción:' + sLineBreak + sDescripcion +
        sLineBreak + sLineBreak + 'Tamaño: ' +
        FormatFloat('#,##0', iBytes) + ' bytes' +
        sLineBreak + 'SHA-256:' + sLineBreak + sHash;
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg(
           '¿Desea instalar esta actualización y reiniciar Factuzam?',
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
