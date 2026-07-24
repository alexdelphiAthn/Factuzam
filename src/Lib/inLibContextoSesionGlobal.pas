{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContextoSesionGlobal                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador temporal entre el contexto de sesión y las variables globales.  }
{******************************************************************************}
unit inLibContextoSesionGlobal;

interface

uses
  inLibContextoSesion,
  inLibContextoSesionIntf;

type
  TContextoSesionGlobal = class(TContextoSesionAplicacion)
  private
    procedure SincronizarGlobales;
  public
    constructor Create(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion
    );
    procedure EstablecerIdentidad(
      const AIdentidad: TIdentidadSesion
    ); override;
    procedure CambiarUbicacion(
      const AUbicacion: TUbicacionSesion
    ); override;
  end;

implementation

uses
  inLibGlobalVar;

constructor TContextoSesionGlobal.Create(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  inherited Create(AIdentidad, AUbicacion);
  SincronizarGlobales;
end;

procedure TContextoSesionGlobal.SincronizarGlobales;
var
  IdentidadActual: TIdentidadSesion;
  UbicacionActual: TUbicacionSesion;
begin
  IdentidadActual := Identidad;
  UbicacionActual := Ubicacion;
  oUser := IdentidadActual.Usuario;
  oGroup := IdentidadActual.Grupo;
  oRootGroup := IdentidadActual.GrupoRaiz;
  oEmpresa := UbicacionActual.Empresa;
  oAlmacen := UbicacionActual.Almacen;
  oCaja := UbicacionActual.Caja;
end;

procedure TContextoSesionGlobal.EstablecerIdentidad(
  const AIdentidad: TIdentidadSesion);
begin
  inherited EstablecerIdentidad(AIdentidad);
  SincronizarGlobales;
end;

procedure TContextoSesionGlobal.CambiarUbicacion(
  const AUbicacion: TUbicacionSesion);
begin
  inherited CambiarUbicacion(AUbicacion);
  SincronizarGlobales;
end;

end.
