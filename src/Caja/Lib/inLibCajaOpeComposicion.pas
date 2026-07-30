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
  Uni, inLibParametrosIntf,
  inLibContextoSesionIntf, inLibCatalogoSqlIntf,
  inLibCajaVentaIntf;

function CrearServiciosOperacionCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AGrabador: IGrabadorVentaCaja;
  const ACatalogoSql: ICatalogoSql = nil;
  const AIncidenciasSql: IRegistroIncidenciasSql = nil
): TServiciosOperacionCaja;

implementation

uses
  inLibCajaStock,
  inLibCajaDescuentos,
  UniDataCajaConsultasRepositorio,
  inLibCajaRectificacion,
  inLibCajaCierreVenta;

function CrearServiciosOperacionCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AGrabador: IGrabadorVentaCaja;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql
): TServiciosOperacionCaja;
begin
  Result.RepositorioConsultas :=
    TRepositorioConsultasCaja.Create(
      AConexion,
      ACatalogoSql,
      AIncidenciasSql);
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
