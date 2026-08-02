{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExcepcionesAplicacion                                    }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registra y presenta las excepciones globales de la aplicación.            }
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
  inLibMsgComun,
  Winapi.Windows,
  System.SysUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Clipbrd,
  cxMemo,
  inLibGlobalVar,
  inLibWin;

type
  TGestorExcepcionesAplicacion = class(
    TInterfacedObject,
    IGestorExcepcionesAplicacion)
  private
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    FMemoDetalle: TcxMemo;
    procedure MostrarDetalle(
      const ATexto: string);
    procedure CopiarDetalleClick(
      Sender: TObject);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const ARegistroLog: IRegistroLog);
    procedure Gestionar(
      Sender: TObject;
      E: Exception);
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
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
end;

procedure TGestorExcepcionesAplicacion.Gestionar(
  Sender: TObject;
  E: Exception);
var
  Detalle: string;
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  if EsRuidoEditorInplace(E) then
  begin
    try
      FRegistroLog.RegistrarAviso(
        'AppException ignorado ' +
        '(editor inplace sin Parent): ' +
        E.Message);
    except
      // Ultimo recurso: si el log falla, que lo vea DebugView.
      on EFalloLog: Exception do
        OutputDebugString(PChar(
          'Factuzam: fallo al registrar AppException: ' +
          EFalloLog.Message));
    end;
  end
  else
  begin
    try
      Identidad := FContextoSesion.Identidad;
      Ubicacion := FContextoSesion.Ubicacion;
      Detalle := ConstruirDetalleExcepcionAplicacion(
        Sender,
        E,
        Identidad,
        Ubicacion,
        oAppName,
        oVersion,
        GetComputerName,
        Now,
        ExceptAddr);
      try
        FRegistroLog.RegistrarError(
          'AppException ' +
          E.ClassName +
          ': ' +
          E.Message);
        FRegistroLog.RegistrarError(
          'AppException detalle:' +
          sLineBreak +
          Detalle);
      except
        // Ultimo recurso: si el log falla, que lo vea DebugView.
        on EFalloLog: Exception do
          OutputDebugString(PChar(
            'Factuzam: fallo al registrar AppException: ' +
            EFalloLog.Message));
      end;
      MostrarDetalle(Detalle);
    except
      try
        Application.ShowException(E);
      except
        // Ultimo recurso: ni el dialogo estandar pudo mostrarse.
        on EFalloUI: Exception do
          OutputDebugString(PChar(
            'Factuzam: fallo al mostrar AppException: ' +
            EFalloUI.Message));
      end;
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.MostrarDetalle(
  const ATexto: string);
var
  Dialogo: TForm;
  PanelBotones: TPanel;
  BotonCopiar: TButton;
  BotonCerrar: TButton;
  Cabecera: TLabel;
begin
  Dialogo := TForm.Create(nil);
  try
    Dialogo.Caption := STituloErrorProducido;
    Dialogo.Position := poScreenCenter;
    Dialogo.Width := 760;
    Dialogo.Height := 520;
    Dialogo.BorderStyle := bsSizeable;
    Dialogo.BorderIcons := [biSystemMenu];
    Dialogo.KeyPreview := True;
    Cabecera := TLabel.Create(Dialogo);
    Cabecera.Parent := Dialogo;
    Cabecera.Align := alTop;
    Cabecera.AutoSize := False;
    Cabecera.Height := 28;
    Cabecera.Layout := tlCenter;
    Cabecera.Caption := SCaptionDetalleErrorCabecera;
    PanelBotones := TPanel.Create(Dialogo);
    PanelBotones.Parent := Dialogo;
    PanelBotones.Align := alBottom;
    PanelBotones.Height := 48;
    PanelBotones.BevelOuter := bvNone;
    BotonCerrar := TButton.Create(Dialogo);
    BotonCerrar.Parent := PanelBotones;
    BotonCerrar.Caption := SCaptionCerrar;
    BotonCerrar.Width := 100;
    BotonCerrar.Height := 32;
    BotonCerrar.Top := 8;
    BotonCerrar.Anchors := [akRight, akTop];
    BotonCerrar.Left :=
      PanelBotones.ClientWidth -
      BotonCerrar.Width -
      12;
    BotonCerrar.ModalResult := mrOk;
    BotonCerrar.Default := True;
    BotonCerrar.Cancel := True;
    BotonCopiar := TButton.Create(Dialogo);
    BotonCopiar.Parent := PanelBotones;
    BotonCopiar.Caption := SCaptionCopiarPortapapeles;
    BotonCopiar.Width := 190;
    BotonCopiar.Height := 32;
    BotonCopiar.Top := 8;
    BotonCopiar.Anchors := [akRight, akTop];
    BotonCopiar.Left :=
      BotonCerrar.Left -
      BotonCopiar.Width -
      8;
    BotonCopiar.OnClick := CopiarDetalleClick;
    FMemoDetalle := TcxMemo.Create(Dialogo);
    FMemoDetalle.Parent := Dialogo;
    FMemoDetalle.Align := alClient;
    FMemoDetalle.Properties.ReadOnly := True;
    FMemoDetalle.Properties.ScrollBars := ssBoth;
    FMemoDetalle.Properties.WordWrap := False;
    FMemoDetalle.Style.Font.Name := 'Consolas';
    FMemoDetalle.Style.Font.Size := 9;
    FMemoDetalle.Text := ATexto;
    Dialogo.ActiveControl := BotonCerrar;
    Dialogo.ShowModal;
  finally
    FMemoDetalle := nil;
    Dialogo.Free;
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
      begin
        FRegistroLog.RegistrarAviso(
          'No se pudo copiar al portapapeles: ' +
          E.Message);
      end;
    end;
  end;
end;

end.
