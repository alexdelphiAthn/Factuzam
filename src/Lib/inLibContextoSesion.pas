{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContextoSesion                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación sincronizada del contexto de sesión de la aplicación.      }
{******************************************************************************}
unit inLibContextoSesion;

interface

uses
  System.SyncObjs,
  inLibContextoSesionIntf;

type
  TContextoSesionAplicacion = class(
    TInterfacedObject,
    IContextoSesionAplicacion,
    IGestorContextoSesion
  )
  private
    FBloqueo: TCriticalSection;
    FIdentidad: TIdentidadSesion;
    FUbicacion: TUbicacionSesion;
  protected
    function GetIdentidad: TIdentidadSesion;
    function GetUbicacion: TUbicacionSesion;
    property Identidad: TIdentidadSesion read GetIdentidad;
    property Ubicacion: TUbicacionSesion read GetUbicacion;
  public
    constructor Create(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion
    );
    destructor Destroy; override;
    procedure EstablecerIdentidad(
      const AIdentidad: TIdentidadSesion
    ); virtual;
    procedure CambiarUbicacion(
      const AUbicacion: TUbicacionSesion
    ); virtual;
  end;

implementation

constructor TContextoSesionAplicacion.Create(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
  FIdentidad := AIdentidad;
  FUbicacion := AUbicacion;
end;

destructor TContextoSesionAplicacion.Destroy;
begin
  FBloqueo.Free;
  inherited;
end;

function TContextoSesionAplicacion.GetIdentidad: TIdentidadSesion;
begin
  FBloqueo.Acquire;
  try
    Result := FIdentidad;
  finally
    FBloqueo.Release;
  end;
end;

function TContextoSesionAplicacion.GetUbicacion: TUbicacionSesion;
begin
  FBloqueo.Acquire;
  try
    Result := FUbicacion;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.EstablecerIdentidad(
  const AIdentidad: TIdentidadSesion);
begin
  FBloqueo.Acquire;
  try
    FIdentidad := AIdentidad;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.CambiarUbicacion(
  const AUbicacion: TUbicacionSesion);
begin
  FBloqueo.Acquire;
  try
    FUbicacion := AUbicacion;
  finally
    FBloqueo.Release;
  end;
end;

end.
