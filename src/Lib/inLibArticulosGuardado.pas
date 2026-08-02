{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosGuardado                                        }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina las capacidades que deben persistirse al grabar un articulo.     }
{******************************************************************************}
unit inLibArticulosGuardado;

interface

uses
  inLibArticulosGuardadoIntf;

function CrearAplicacionGuardadoArticulo(
  const AOperaciones: IOperacionesGuardadoArticulo):
  IAplicacionGuardadoArticulo;

implementation

uses
  System.SysUtils;

type
  TAplicacionGuardadoArticulo = class(
    TInterfacedObject,
    IAplicacionGuardadoArticulo)
  private
    FOperaciones: IOperacionesGuardadoArticulo;
  public
    constructor Create(
      const AOperaciones: IOperacionesGuardadoArticulo);
    function Ejecutar: TResultadoGuardadoArticulo;
  end;

constructor TAplicacionGuardadoArticulo.Create(
  const AOperaciones: IOperacionesGuardadoArticulo);
begin
  inherited Create;
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  FOperaciones := AOperaciones;
end;

function TAplicacionGuardadoArticulo.Ejecutar:
  TResultadoGuardadoArticulo;
var
  sMensaje: string;
begin
  Result := Default(TResultadoGuardadoArticulo);
  sMensaje := FOperaciones.ValidarPropiedades;
  if sMensaje <> '' then
  begin
    Result.Error := egaRevisionPropiedades;
    Result.Mensaje := sMensaje;
  end;
  if Result.Error = egaNinguno then
  begin
    if not FOperaciones.GuardarPropiedades(sMensaje) then
    begin
      Result.Error := egaGuardadoPropiedades;
      Result.Mensaje := sMensaje;
    end;
  end;
  if Result.Error = egaNinguno then
    FOperaciones.GuardarEdicionesPendientes;
  if Result.Error = egaNinguno then
  begin
    if not FOperaciones.GuardarVariaciones(sMensaje) then
    begin
      Result.Error := egaGuardadoVariaciones;
      Result.Mensaje := sMensaje;
    end;
  end;
end;

function CrearAplicacionGuardadoArticulo(
  const AOperaciones: IOperacionesGuardadoArticulo):
  IAplicacionGuardadoArticulo;
begin
  Result := TAplicacionGuardadoArticulo.Create(AOperaciones);
end;

end.
