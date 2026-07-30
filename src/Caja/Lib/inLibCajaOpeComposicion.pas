{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaOpeComposicion                                       }
{    Tipo:       Factoría                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ensambla los servicios de la ventana de operación de caja.              }
{                                                                              }
{    El repositorio de consultas llega YA CONSTRUIDO desde la raíz de         }
{    composición: esta unidad no conoce UniData*, que es la dirección         }
{    prohibida por LIBRO_DE_ESTILO_DELPHI.md 14.1.                            }
{******************************************************************************}
unit inLibCajaOpeComposicion;

interface

uses
  Uni, inLibParametrosIntf,
  inLibContextoSesionIntf,
  inLibCajaVentaIntf;

function CrearServiciosOperacionCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AGrabador: IGrabadorVentaCaja;
  const ARepositorioConsultas: IRepositorioConsultasCaja
): TServiciosOperacionCaja;

implementation

uses
  inLibCajaStock,
  inLibCajaDescuentos,
  inLibCajaRectificacion,
  inLibCajaCierreVenta;

function CrearServiciosOperacionCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AGrabador: IGrabadorVentaCaja;
  const ARepositorioConsultas: IRepositorioConsultasCaja
): TServiciosOperacionCaja;
begin
  Result.RepositorioConsultas := ARepositorioConsultas;
  Result.ServicioRectificacion :=
    TServicioRectificacionCaja.Create(
      Result.RepositorioConsultas);
  Result.PoliticaStock :=
    TPoliticaStockVenta.Create(
      AConexion,
      AParametrosCaja);
  Result.RepartidorDescuento :=
    TRepartidorDescuento.Create;
  Result.Impresor := AImpresor;
  Result.ServicioCierre :=
    TServicioCierreVenta.Create(
      AGrabador,
      Result.Impresor,
      AParametrosCaja,
      AContextoSesion,
      AConexion);
end;

end.
