{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsJsonIntf                                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto del serializador JSON de ventas para el webservice y su fábrica    }
{    registrable.                                                              }
{******************************************************************************}
unit inLibVentasWsJsonIntf;

interface

uses
  Uni, inLibParametrosIntf;

type
  IVentasWsJson = interface
    ['{39BA2674-37D2-4593-AC18-973117DB37F0}']
    function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string;
  end;
  TFabricaCrearVentasWsJson = function(
    AConexion: TUniConnection): IVentasWsJson;
  // El adaptador UniData* registra la implementación en initialization.
  TFabricaVentasWsJson = class
  private
    class var FFabrica: TFabricaCrearVentasWsJson;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearVentasWsJson);
    class function Crear(
      AConexion: TUniConnection): IVentasWsJson;
  end;

implementation

uses
  System.SysUtils, inLibMsgIntegraciones;

class procedure TFabricaVentasWsJson.Registrar(
  AFabrica: TFabricaCrearVentasWsJson);
begin
  FFabrica := AFabrica;
end;

class function TFabricaVentasWsJson.Crear(
  AConexion: TUniConnection): IVentasWsJson;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(SErrorVentasWsJsonNoRegistrado);
  Result := FFabrica(AConexion);
end;

end.
