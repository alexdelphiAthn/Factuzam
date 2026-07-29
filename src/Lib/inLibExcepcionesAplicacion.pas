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
  inLibExcepcionesAplicacionIntf;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion
): IGestorExcepcionesAplicacion;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Clipbrd,
  cxMemo,
  inLibGlobalVar,
  inLibWin,
  inLibLog;

type
  TGestorExcepcionesAplicacion = class(
    TInterfacedObject,
    IGestorExcepcionesAplicacion)
  private
    FContextoSesion: IContextoSesionAplicacion;
    FMemoDetalle: TcxMemo;
    procedure MostrarDetalle(
      const ATexto: string);
    procedure CopiarDetalleClick(
      Sender: TObject);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure Gestionar(
      Sender: TObject;
      E: Exception);
  end;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion
): IGestorExcepcionesAplicacion;
begin
  Result := TGestorExcepcionesAplicacion.Create(
    AContextoSesion);
end;

constructor TGestorExcepcionesAplicacion.Create(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  inherited Create;
  FContextoSesion := AContextoSesion;
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
      Log.LogWarning(
        'AppException ignorado ' +
        '(editor inplace sin Parent): ' +
        E.Message);
    except
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
        Log.LogError(
          'AppException ' +
          E.ClassName +
          ': ' +
          E.Message);
        Log.LogError(
          'AppException detalle:' +
          sLineBreak +
          Detalle);
      except
      end;
      MostrarDetalle(Detalle);
    except
      try
        Application.ShowException(E);
      except
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
    Dialogo.Caption := 'Se ha producido un error';
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
    Cabecera.Caption :=
      '  Detalle completo del error. Usa "Copiar al ' +
      'portapapeles" para pegarlo en un reporte.';
    PanelBotones := TPanel.Create(Dialogo);
    PanelBotones.Parent := Dialogo;
    PanelBotones.Align := alBottom;
    PanelBotones.Height := 48;
    PanelBotones.BevelOuter := bvNone;
    BotonCerrar := TButton.Create(Dialogo);
    BotonCerrar.Parent := PanelBotones;
    BotonCerrar.Caption := 'Cerrar';
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
    BotonCopiar.Caption := 'Copiar al portapapeles';
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
        Log.LogWarning(
          'No se pudo copiar al portapapeles: ' +
          E.Message);
      end;
    end;
  end;
end;

end.
