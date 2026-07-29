{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasComposicion                                      }
{    Tipo:       Factoría                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construye los servicios de factura en el límite de composición.           }
{******************************************************************************}
unit inLibFacturasComposicion;

interface

uses
  Uni, inLibFacturasServiciosIntf;

function CrearServiciosFactura(
  AConexion: TUniConnection): TServiciosFactura;

implementation

uses
  inLibFacturasRepositorio,
  inLibFacturasValidacionFiscal,
  inLibFacturasCalculo,
  inLibFacturasBorrado,
  inLibFacturasEfectos;

function CrearServiciosFactura(
  AConexion: TUniConnection): TServiciosFactura;
var
  Repositorio: IRepositorioFacturas;
begin
  Repositorio := TRepositorioFacturas.Create(AConexion);
  Result.Repositorio := Repositorio;
  Result.ValidadorFiscal :=
    TValidadorFiscalFactura.Create(Repositorio);
  Result.Calculador := TCalculadorFactura.Create(AConexion);
  Result.Borrado := TServicioBorradoFactura.Create(AConexion);
  Result.Efectos := TServicioEfectosFactura.Create(AConexion);
end;

end.
