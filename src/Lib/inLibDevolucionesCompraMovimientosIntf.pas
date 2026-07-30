{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevolucionesCompraMovimientosIntf                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de los movimientos de almacén de devoluciones de compra y su       }
{    fábrica registrable.                                                      }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientosIntf;

interface

uses
  Uni;
type
  IMovimientosDevolucionCompra = interface
    ['{5BB360D5-6E2D-4424-BC35-56B61CB1AE29}']
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
  end;
  TFabricaCrearMovimientosDevolucionCompra = function(
    AConexion: TUniConnection): IMovimientosDevolucionCompra;
  // Registro de la implementación de persistencia. La unidad UniData*
  // se registra en su initialization; el dominio no la conoce.
  TFabricaMovimientosDevolucionCompra = class
  private
    class var FFabrica: TFabricaCrearMovimientosDevolucionCompra;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearMovimientosDevolucionCompra);
    class function Crear(
      AConexion: TUniConnection): IMovimientosDevolucionCompra;
  end;

implementation

uses
  System.SysUtils, inLibMsgCompras;

class procedure TFabricaMovimientosDevolucionCompra.Registrar(
  AFabrica: TFabricaCrearMovimientosDevolucionCompra);
begin
  FFabrica := AFabrica;
end;

class function TFabricaMovimientosDevolucionCompra.Crear(
  AConexion: TUniConnection): IMovimientosDevolucionCompra;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(SErrorMovimientosDevolucionCompraNoRegistrados);
  Result := FFabrica(AConexion);
end;

end.
