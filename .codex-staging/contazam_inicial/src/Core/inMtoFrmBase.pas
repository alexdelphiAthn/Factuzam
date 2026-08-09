{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFrmBase                                                  }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Formulario base y frontera común de servicios visuales.                   }
{******************************************************************************}
unit inMtoFrmBase;

interface

uses
  System.Classes, Vcl.Forms, Vcl.ExtCtrls, Uni, inLibConfiguracion,
  cxLocalization, inLibSeguridadIntf, inLibLogIntf;

type
  TfrmBase = class(TForm)
  private
    FConexion: TUniConnection;
    FConfiguracion: TConfiguracionContazam;
    FRegistroLog: IRegistroLogContazam;
    FSeguridad: IServicioSeguridadContazam;
    FTemporizadorBestFit: TTimer;
    FLocalizadorDevExpress: TcxLocalizer;
    procedure AjustarGridsDiferido(Sender: TObject);
    procedure ConfigurarLocalizacionDevExpress;
  protected
    property Conexion: TUniConnection read FConexion;
    property Configuracion: TConfiguracionContazam
      read FConfiguracion;
    property RegistroLog: IRegistroLogContazam read FRegistroLog;
    property Seguridad: IServicioSeguridadContazam read FSeguridad;
    property LocalizadorDevExpress: TcxLocalizer
      read FLocalizadorDevExpress;
    procedure ComprobarInicializacion;
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AsignarRegistroLog(
      const ARegistroLog: IRegistroLogContazam);
    procedure AsignarSeguridad(
      const ASeguridad: IServicioSeguridadContazam);
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); virtual;
  end;

implementation

uses
  System.SysUtils, Vcl.Controls, inLibGridDevExpress;

procedure TfrmBase.AjustarGridsDiferido(Sender: TObject);
begin
  FTemporizadorBestFit.Enabled := False;
  AjustarGridsContazam(Self);
end;

procedure TfrmBase.AsignarRegistroLog(
  const ARegistroLog: IRegistroLogContazam);
begin
  if ARegistroLog = nil then
  begin
    raise EArgumentNilException.Create('ARegistroLog');
  end;
  FRegistroLog := ARegistroLog;
end;

procedure TfrmBase.AsignarSeguridad(
  const ASeguridad: IServicioSeguridadContazam);
begin
  if ASeguridad = nil then
  begin
    raise EArgumentNilException.Create('ASeguridad');
  end;
  FSeguridad := ASeguridad;
end;

procedure TfrmBase.ConfigurarLocalizacionDevExpress;
begin
  FLocalizadorDevExpress.FileName := 'CXLOCALIZATION.res';
  FLocalizadorDevExpress.StorageType := lstResource;
  FLocalizadorDevExpress.Active := True;
  FLocalizadorDevExpress.Locale := 1034;
  FLocalizadorDevExpress.Translate;
end;

constructor TfrmBase.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Position := poScreenCenter;
  Font.Name := 'Lucida Sans';
  Font.Size := 10;
  KeyPreview := True;
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  FLocalizadorDevExpress := TcxLocalizer.Create(Self);
  FLocalizadorDevExpress.Name := 'Localizer1';
  ConfigurarLocalizacionDevExpress;
  FTemporizadorBestFit := TTimer.Create(Self);
  FTemporizadorBestFit.Enabled := False;
  FTemporizadorBestFit.Interval := 20;
  FTemporizadorBestFit.OnTimer := AjustarGridsDiferido;
end;

procedure TfrmBase.ComprobarInicializacion;
begin
  if FConexion = nil then
  begin
    raise EInvalidOpException.Create(
      'La pantalla no tiene una conexión asignada.');
  end;
  if FSeguridad = nil then
  begin
    raise EInvalidOpException.Create(
      'La pantalla no tiene un servicio de seguridad asignado.');
  end;
  if FRegistroLog = nil then
  begin
    raise EInvalidOpException.Create(
      'La pantalla no tiene un registro de actividad asignado.');
  end;
end;

procedure TfrmBase.DoShow;
begin
  inherited;
  FTemporizadorBestFit.Enabled := False;
  FTemporizadorBestFit.Enabled := True;
end;

procedure TfrmBase.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  FConexion := AConexion;
  FConfiguracion := AConfiguracion;
end;

end.

