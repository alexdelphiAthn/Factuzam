{******************************************************************************}
{                                                                              }
{  Módulo:       inLibErroresAplicacion                                        }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Captura y presenta errores locales sin transmitir información.            }
{******************************************************************************}
unit inLibErroresAplicacion;

interface

uses
  System.SysUtils, inLibLogIntf;

type
  IGestorErroresContazam = interface
    ['{5FB5C1AF-B7CC-4667-830F-14D745E1270D}']
    procedure Gestionar(Sender: TObject; E: Exception);
  end;

function CrearGestorErroresContazam(
  const ARegistroLog: IRegistroLogContazam
): IGestorErroresContazam;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.Classes, Vcl.Clipbrd,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TfrmErrorContazam = class(TForm)
  private
    FArchivoLog: string;
    FDetalle: string;
    FMemoDetalle: TMemo;
    procedure AbrirLogClick(Sender: TObject);
    procedure CopiarClick(Sender: TObject);
  public
    constructor Create(
      AOwner: TComponent;
      const ADetalle, AArchivoLog: string); reintroduce;
  end;

  TGestorErroresContazam = class(
    TInterfacedObject,
    IGestorErroresContazam)
  private
    FMostrandoError: Boolean;
    FRegistroLog: IRegistroLogContazam;
    function ConstruirDetalle(Sender: TObject; E: Exception): string;
    procedure MostrarError(const ADetalle: string);
    procedure RegistrarSeguro(E: Exception; const ADetalle: string);
  public
    constructor Create(const ARegistroLog: IRegistroLogContazam);
    procedure Gestionar(Sender: TObject; E: Exception);
  end;

function CrearGestorErroresContazam(
  const ARegistroLog: IRegistroLogContazam
): IGestorErroresContazam;
begin
  Result := TGestorErroresContazam.Create(ARegistroLog);
end;

procedure TfrmErrorContazam.AbrirLogClick(Sender: TObject);
begin
  ShellExecute(
    Handle,
    'open',
    PChar(ExtractFilePath(FArchivoLog)),
    nil,
    nil,
    SW_SHOWNORMAL);
end;

procedure TfrmErrorContazam.CopiarClick(Sender: TObject);
begin
  Clipboard.AsText := FDetalle;
end;

constructor TfrmErrorContazam.Create(
  AOwner: TComponent;
  const ADetalle, AArchivoLog: string);
var
  oBotonAbrir: TButton;
  oBotonCerrar: TButton;
  oBotonCopiar: TButton;
  oExplicacion: TLabel;
begin
  inherited CreateNew(AOwner);
  FArchivoLog := AArchivoLog;
  FDetalle := ADetalle;
  Caption := 'Error de Contazam';
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  ClientWidth := 720;
  ClientHeight := 460;
  Font.Name := 'Lucida Sans';
  Font.Size := 10;
  oExplicacion := TLabel.Create(Self);
  oExplicacion.Parent := Self;
  oExplicacion.SetBounds(20, 18, 680, 42);
  oExplicacion.AutoSize := False;
  oExplicacion.WordWrap := True;
  oExplicacion.Caption :=
    'Se ha producido un error. El detalle se ha guardado localmente ' +
    'en el archivo de log indicado abajo.';
  FMemoDetalle := TMemo.Create(Self);
  FMemoDetalle.Parent := Self;
  FMemoDetalle.SetBounds(20, 68, 680, 330);
  FMemoDetalle.ReadOnly := True;
  FMemoDetalle.ScrollBars := ssBoth;
  FMemoDetalle.WordWrap := False;
  FMemoDetalle.Lines.Text := ADetalle;
  oBotonCopiar := TButton.Create(Self);
  oBotonCopiar.Parent := Self;
  oBotonCopiar.SetBounds(20, 414, 150, 32);
  oBotonCopiar.Caption := 'Copiar detalle';
  oBotonCopiar.OnClick := CopiarClick;
  oBotonAbrir := TButton.Create(Self);
  oBotonAbrir.Parent := Self;
  oBotonAbrir.SetBounds(184, 414, 190, 32);
  oBotonAbrir.Caption := 'Abrir carpeta del log';
  oBotonAbrir.OnClick := AbrirLogClick;
  oBotonCerrar := TButton.Create(Self);
  oBotonCerrar.Parent := Self;
  oBotonCerrar.SetBounds(550, 414, 150, 32);
  oBotonCerrar.Caption := 'Cerrar';
  oBotonCerrar.Default := True;
  oBotonCerrar.Cancel := True;
  oBotonCerrar.ModalResult := mrClose;
end;

function TGestorErroresContazam.ConstruirDetalle(
  Sender: TObject;
  E: Exception): string;
var
  oFormulario: TCustomForm;
  oInterna: Exception;
  sEmisor: string;
  sFormulario: string;
begin
  sEmisor := '(no disponible)';
  if Sender <> nil then
  begin
    sEmisor := Sender.ClassName;
  end;
  sFormulario := '(ninguno)';
  oFormulario := Screen.ActiveCustomForm;
  if oFormulario <> nil then
  begin
    sFormulario := oFormulario.ClassName + ' - ' + oFormulario.Caption;
  end;
  Result :=
    'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
    sLineBreak + 'Aplicación: Contazam 1.0.0' +
    sLineBreak + 'Ejecutable: ' + ParamStr(0) +
    sLineBreak + 'Equipo: ' + GetEnvironmentVariable('COMPUTERNAME') +
    sLineBreak + 'Usuario Windows: ' +
      GetEnvironmentVariable('USERNAME') +
    sLineBreak + 'Proceso: ' + IntToStr(GetCurrentProcessId) +
    sLineBreak + 'Hilo: ' + IntToStr(GetCurrentThreadId) +
    sLineBreak + 'Emisor: ' + sEmisor +
    sLineBreak + 'Formulario activo: ' + sFormulario +
    sLineBreak + 'Clase: ' + E.ClassName +
    sLineBreak + 'Mensaje: ' + E.Message;
  if E.StackTrace <> '' then
  begin
    Result := Result + sLineBreak + 'Pila:' + sLineBreak + E.StackTrace;
  end;
  oInterna := E.InnerException;
  while oInterna <> nil do
  begin
    Result := Result + sLineBreak + 'Causa: ' +
      oInterna.ClassName + ': ' + oInterna.Message;
    oInterna := oInterna.InnerException;
  end;
  Result := Result + sLineBreak + 'Log: ' + FRegistroLog.RutaArchivo;
end;

constructor TGestorErroresContazam.Create(
  const ARegistroLog: IRegistroLogContazam);
begin
  inherited Create;
  if ARegistroLog = nil then
  begin
    raise EArgumentNilException.Create('ARegistroLog');
  end;
  FRegistroLog := ARegistroLog;
end;

procedure TGestorErroresContazam.Gestionar(
  Sender: TObject;
  E: Exception);
var
  sDetalle: string;
begin
  if not FMostrandoError then
  begin
    FMostrandoError := True;
    try
      try
        sDetalle := ConstruirDetalle(Sender, E);
        RegistrarSeguro(E, sDetalle);
        MostrarError(sDetalle);
      except
        on EFalloGestor: Exception do
        begin
          OutputDebugString(PChar(
            'Contazam: fallo al gestionar AppException: ' +
            EFalloGestor.Message));
          Application.ShowException(E);
        end;
      end;
    finally
      FMostrandoError := False;
    end;
  end;
end;

procedure TGestorErroresContazam.MostrarError(const ADetalle: string);
var
  oDialogo: TfrmErrorContazam;
begin
  oDialogo := TfrmErrorContazam.Create(
    Application,
    ADetalle,
    FRegistroLog.RutaArchivo);
  try
    oDialogo.ShowModal;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TGestorErroresContazam.RegistrarSeguro(
  E: Exception;
  const ADetalle: string);
begin
  try
    FRegistroLog.RegistrarExcepcion('AppException', E);
    FRegistroLog.RegistrarError(
      'AppException detalle:' + sLineBreak + ADetalle);
  except
    on EFalloLog: Exception do
    begin
      OutputDebugString(PChar(
        'Contazam: fallo al registrar AppException: ' +
        EFalloLog.Message));
    end;
  end;
end;

end.
