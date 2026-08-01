{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsSesion                                         }
{    Tipo:       Composición de persistencia                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea una sesión VentasWs de segundo plano y conserva la conexión UniDAC   }
{    como detalle privado durante la vida del repositorio y el serializador.   }
{******************************************************************************}
unit UniDataVentasWsSesion;

interface

uses
  inLibConexionesIntf, inLibVentasWsColaIntf;

function CrearFabricaSesionVentasWsUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionVentasWs;

implementation

uses
  System.SysUtils, Uni, inLibVentasWsJsonIntf,
  UniDataVentasWsCola, UniDataVentasWsJson;

type
  TSesionVentasWsUniDAC = class(TInterfacedObject, ISesionVentasWs)
  private
    FConexion: TUniConnection;
    FRepositorio: IRepositorioVentasWsCola;
    FJson: IVentasWsJson;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function GetRepositorio: IRepositorioVentasWsCola;
    function GetJson: IVentasWsJson;
  end;
  TFabricaSesionVentasWsUniDAC = class(
    TInterfacedObject,
    IFabricaSesionVentasWs)
  private
    FConexiones: IServicioConexiones;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function CrearSesion: ISesionVentasWs;
  end;

constructor TSesionVentasWsUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexion := AConexiones.CrearConexion(nil, uctSegundoPlano);
  FRepositorio := CrearRepositorioVentasWsColaUniDAC(FConexion);
  FJson := CrearVentasWsJsonUniDAC(FConexion);
end;

destructor TSesionVentasWsUniDAC.Destroy;
begin
  FJson := nil;
  FRepositorio := nil;
  FreeAndNil(FConexion);
  inherited;
end;

function TSesionVentasWsUniDAC.GetRepositorio:
  IRepositorioVentasWsCola;
begin
  Result := FRepositorio;
end;

function TSesionVentasWsUniDAC.GetJson: IVentasWsJson;
begin
  Result := FJson;
end;

constructor TFabricaSesionVentasWsUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexiones := AConexiones;
end;

destructor TFabricaSesionVentasWsUniDAC.Destroy;
begin
  FConexiones := nil;
  inherited;
end;

function TFabricaSesionVentasWsUniDAC.CrearSesion: ISesionVentasWs;
begin
  Result := TSesionVentasWsUniDAC.Create(FConexiones);
end;

function CrearFabricaSesionVentasWsUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionVentasWs;
begin
  Result := TFabricaSesionVentasWsUniDAC.Create(AConexiones);
end;

end.
