{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaOpeComposicion                                       }
{    Tipo:       Factoría                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construye los servicios utilizados por la ventana de operación de caja.  }
{******************************************************************************}
unit inLibCajaOpeComposicion;

interface

uses
  System.Classes, Uni, UniDataCaja,
  inLibParametrosIntf, inLibPermisosIntf,
  inLibContextoSesionIntf, inLibCajaVentaIntf;

function CrearServiciosOperacionCaja(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const AContextoSesion: IContextoSesionAplicacion;
  ADatosCaja: TdmCajaOpe
): TServiciosOperacionCaja;

implementation

uses
  inLibCajaStock,
  inLibCajaDescuentos,
  inLibCajaConsultasRepositorio,
  inLibCajaRectificacion,
  inLibCajaCierreVenta,
  inMtoCajaImpresorVenta,
  inMtoCajaGrabadorVenta;

function CrearServiciosOperacionCaja(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const AContextoSesion: IContextoSesionAplicacion;
  ADatosCaja: TdmCajaOpe
): TServiciosOperacionCaja;
begin
  Result.RepositorioConsultas :=
    TRepositorioConsultasCaja.Create(
      AConexion);
  Result.ServicioRectificacion :=
    TServicioRectificacionCaja.Create(
      Result.RepositorioConsultas);
  Result.PoliticaStock :=
    TPoliticaStockVenta.Create(
      AConexion,
      AParametrosCaja);
  Result.RepartidorDescuento :=
    TRepartidorDescuento.Create;
  Result.Impresor :=
    TImpresorVentaVcl.Create(
      APropietario,
      AParametrosApp,
      AConexion,
      AParametrosCaja,
      APermisos);
  Result.ServicioCierre :=
    TServicioCierreVenta.Create(
      TGrabadorVentaCaja.Create(ADatosCaja),
      Result.Impresor,
      AParametrosCaja,
      AContextoSesion,
      AConexion);
end;

end.
