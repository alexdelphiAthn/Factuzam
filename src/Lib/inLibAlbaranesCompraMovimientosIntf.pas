{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAlbaranesCompraMovimientosIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de los movimientos de almacén de albaranes de compra y su          }
{    fábrica registrable (mismo patrón que TFabricaModoTallas).                }
{******************************************************************************}
unit inLibAlbaranesCompraMovimientosIntf;

interface

uses
  Uni;
type
  IMovimientosAlbaranCompra = interface
    ['{35493A2B-EDAC-40C3-9F26-1E9F5BA677D3}']
    procedure GenerarDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
    procedure RevertirDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
  end;
  TFabricaCrearMovimientosAlbaranCompra = function(
    AConexion: TUniConnection): IMovimientosAlbaranCompra;
  // Registro de la implementación de persistencia. La unidad UniData*
  // se registra en su initialization; el dominio no la conoce.
  TFabricaMovimientosAlbaranCompra = class
  private
    class var FFabrica: TFabricaCrearMovimientosAlbaranCompra;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearMovimientosAlbaranCompra);
    class function Crear(
      AConexion: TUniConnection): IMovimientosAlbaranCompra;
  end;
implementation

uses
  System.SysUtils, inLibMsgCompras;
class procedure TFabricaMovimientosAlbaranCompra.Registrar(
  AFabrica: TFabricaCrearMovimientosAlbaranCompra);
begin
  FFabrica := AFabrica;
end;
class function TFabricaMovimientosAlbaranCompra.Crear(
  AConexion: TUniConnection): IMovimientosAlbaranCompra;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(SErrorMovimientosAlbaranCompraNoRegistrados);
  Result := FFabrica(AConexion);
end;
end.
