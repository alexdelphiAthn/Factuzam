{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAplicacionContazam                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Raíz de composición de conexiones, pantallas y ciclo de aplicación.       }
{******************************************************************************}
unit inLibAplicacionContazam;

interface

uses
  inLibConfiguracion, inLibRegistroPantallas, UniDataConexion,
  inMtoPrincipal, inLibSeguridadIntf, inLibLogIntf;

type
  TAplicacionContazam = class
  private
    FConfiguracion: TConfiguracionContazam;
    FConexion: TdmConexion;
    FRegistro: TRegistroPantallasContazam;
    FRegistroLog: IRegistroLogContazam;
    FSeguridad: IServicioSeguridadContazam;
    FPrincipal: TfrmMtoPrincipal;
    procedure RegistrarPantallas;
  public
    destructor Destroy; override;
    procedure Ejecutar;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, inMtoEmpresas, inMtoEjercicios,
  inMtoPlanContable, inMtoLibroDiario,
  inMtoLibroMayor, inMtoContadores, inMtoImportarFacturas,
  inMtoArchivoDocumental, inMtoListados, inMtoSeguridad,
  UniDataSeguridad, inLibLog, inLibErroresAplicacion;

destructor TAplicacionContazam.Destroy;
begin
  if FRegistroLog <> nil then
  begin
    FRegistroLog.RegistrarInformacion('Cierre de Contazam.');
  end;
  FreeAndNil(FRegistro);
  FSeguridad := nil;
  FreeAndNil(FConexion);
  FRegistroLog := nil;
  inherited;
end;

procedure TAplicacionContazam.Ejecutar;
var
  oGestorErrores: IGestorErroresContazam;
begin
  FRegistroLog := CrearRegistroLogContazam;
  FRegistroLog.RegistrarInformacion('Inicio de Contazam.');
  try
    FConfiguracion := TConfiguracionContazam.Cargar;
    FRegistroLog.RegistrarInformacion(
      'Configuración cargada desde ' +
      FConfiguracion.RutaConfiguracion + '. Servidor=' +
      FConfiguracion.Servidor +
      '; puerto=' + IntToStr(FConfiguracion.Puerto) +
      '; base=' + FConfiguracion.BaseDatos +
      '; empresa=' + FConfiguracion.Empresa +
      '; ejercicio=' + IntToStr(FConfiguracion.Ejercicio) + '.');
    FConexion := TdmConexion.Create(nil, FConfiguracion);
    FRegistroLog.RegistrarInformacion(
      'Conexión establecida con ' + FConfiguracion.BaseDatos + '.');
    FSeguridad := CrearServicioSeguridad(
      FConexion.Conexion,
      FConfiguracion.UsuarioAplicacion);
    FRegistro := TRegistroPantallasContazam.Create;
    RegistrarPantallas;
    Application.CreateForm(TfrmMtoPrincipal, FPrincipal);
    FPrincipal.AsignarSeguridad(FSeguridad);
    FPrincipal.AsignarRegistroLog(FRegistroLog);
    FPrincipal.Inicializar(FConexion.Conexion, FConfiguracion);
    FPrincipal.ConfigurarRegistro(FRegistro);
    Application.Run;
  except
    on E: Exception do
    begin
      FRegistroLog.RegistrarExcepcion('Arranque o ejecución', E);
      oGestorErrores := CrearGestorErroresContazam(FRegistroLog);
      oGestorErrores.Gestionar(Self, E);
      oGestorErrores := nil;
    end;
  end;
end;

procedure TAplicacionContazam.RegistrarPantallas;
begin
  FRegistro.Registrar(PantallaEmpresas, TfrmMtoEmpresas);
  FRegistro.Registrar(PantallaEjercicios, TfrmMtoEjercicios);
  FRegistro.Registrar(
    PantallaPlanContable,
    TfrmMtoPlanContable);
  FRegistro.Registrar(
    PantallaLibroDiario,
    TfrmMtoLibroDiario);
  FRegistro.Registrar(
    PantallaLibroMayor,
    TfrmMtoLibroMayor);
  FRegistro.Registrar(
    PantallaContadores,
    TfrmMtoContadores);
  FRegistro.Registrar(
    PantallaImportarFacturas,
    TfrmMtoImportarFacturas);
  FRegistro.Registrar(
    PantallaArchivoDocumental,
    TfrmMtoArchivoDocumental);
  FRegistro.Registrar(PantallaListados, TfrmMtoListados);
  FRegistro.Registrar(PantallaSeguridad, TfrmMtoSeguridad);
end;

end.
