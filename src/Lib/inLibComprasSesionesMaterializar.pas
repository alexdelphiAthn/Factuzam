{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesMaterializar                              }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Casos de uso de materialización sobre un repositorio inyectado.           }
{******************************************************************************}
unit inLibComprasSesionesMaterializar;

interface

uses
  inLibComprasSesionesIntf;

function SanearColorSku(
  const ATexto: string): string;
function EjecutarMaterializacionSesion(
  const ARepositorio: IRepositorioComprasSesiones;
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
function RevertirMaterializacion(
  const ARepositorio: IRepositorioComprasSesiones;
  const AUsuario: string;
  out AMensajeError: string): Boolean;

implementation

uses
  System.SysUtils,
  inLibComprasSesionesReglas;

function SanearColorSku(
  const ATexto: string): string;
begin
  Result := inLibComprasSesionesReglas.SanearColorSku(ATexto);
end;

function EjecutarMaterializacionSesion(
  const ARepositorio: IRepositorioComprasSesiones;
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  Result := ARepositorio.EjecutarMaterializacion(
    AParametros,
    AResultado);
end;

function RevertirMaterializacion(
  const ARepositorio: IRepositorioComprasSesiones;
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  Result := ARepositorio.RevertirMaterializacion(
    Trim(AUsuario),
    AMensajeError);
end;

end.
