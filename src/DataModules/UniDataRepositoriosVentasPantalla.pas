{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosVentasPantalla                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de ventas requeridos por las pantallas.                       }
{******************************************************************************}
unit UniDataRepositoriosVentasPantalla;

interface

uses
  inLibRepositoriosPantallaIntf,
  inLibEntradaAlbaranVentaPersistenciaIntf, inLibColumnasSkuIntf,
  inLibClientesPersistenciaIntf, inLibListadoVentasPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  TRepositoriosVentasPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosVentasPantalla)
  public
    function CrearRepositorioEntradaAlbaranVenta:
      IRepositorioEntradaAlbaranVenta;
    function CrearServiciosColumnasSku: TServiciosColumnasSku;
    function CrearRepositorioClientes: IRepositorioClientes;
    function CrearRepositorioListadoVentas: IRepositorioListadoVentas;
  end;

implementation

uses
  UniDataEntradaAlbaranVentaRepositorio, UniDataColumnasSkuServicios,
  UniDataClientesRepositorio, UniDataListadoVentasRepositorio;

function TRepositoriosVentasPantallaUniDAC.
  CrearRepositorioEntradaAlbaranVenta: IRepositorioEntradaAlbaranVenta;
begin
  Result := CrearRepositorioEntradaAlbaranVentaUniDAC(FConexionPrincipal);
end;

function TRepositoriosVentasPantallaUniDAC.CrearServiciosColumnasSku:
  TServiciosColumnasSku;
begin
  Result := CrearServiciosColumnasSkuUniDAC(FConexionPrincipal);
end;

function TRepositoriosVentasPantallaUniDAC.CrearRepositorioClientes:
  IRepositorioClientes;
begin
  Result := CrearRepositorioClientesUniDAC(FConexionPrincipal);
end;

function TRepositoriosVentasPantallaUniDAC.CrearRepositorioListadoVentas:
  IRepositorioListadoVentas;
begin
  Result := CrearRepositorioListadoVentasUniDAC(FConexionPrincipal);
end;

end.
