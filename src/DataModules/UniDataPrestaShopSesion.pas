{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopSesion                                     }
{    Tipo:       Composición de persistencia                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Crea una sesión de cola PrestaShop con una conexión UniDAC propia para    }
{    el trabajo en segundo plano.                                              }
{******************************************************************************}
unit UniDataPrestaShopSesion;

interface

uses
  inLibConexionesIntf, inLibPrestaShopColaIntf;

function CrearFabricaSesionPrestaShopColaUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionPrestaShopCola;

implementation

uses
  System.SysUtils, Uni, UniDataPrestaShopCola;

type
  TSesionPrestaShopColaUniDAC = class(
    TInterfacedObject,
    ISesionPrestaShopCola)
  private
    FConexion: TUniConnection;
    FRepositorio: IRepositorioPrestaShopCola;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function GetRepositorio: IRepositorioPrestaShopCola;
  end;

  TFabricaSesionPrestaShopColaUniDAC = class(
    TInterfacedObject,
    IFabricaSesionPrestaShopCola)
  private
    FConexiones: IServicioConexiones;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function CrearSesion: ISesionPrestaShopCola;
  end;

constructor TSesionPrestaShopColaUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexion := AConexiones.CrearConexion(nil, uctSegundoPlano);
  FRepositorio := CrearRepositorioPrestaShopColaUniDAC(FConexion);
end;

destructor TSesionPrestaShopColaUniDAC.Destroy;
begin
  FRepositorio := nil;
  FreeAndNil(FConexion);
  inherited;
end;

function TSesionPrestaShopColaUniDAC.GetRepositorio:
  IRepositorioPrestaShopCola;
begin
  Result := FRepositorio;
end;

constructor TFabricaSesionPrestaShopColaUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexiones := AConexiones;
end;

destructor TFabricaSesionPrestaShopColaUniDAC.Destroy;
begin
  FConexiones := nil;
  inherited;
end;

function TFabricaSesionPrestaShopColaUniDAC.CrearSesion:
  ISesionPrestaShopCola;
begin
  Result := TSesionPrestaShopColaUniDAC.Create(FConexiones);
end;

function CrearFabricaSesionPrestaShopColaUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionPrestaShopCola;
begin
  Result := TFabricaSesionPrestaShopColaUniDAC.Create(AConexiones);
end;

end.
