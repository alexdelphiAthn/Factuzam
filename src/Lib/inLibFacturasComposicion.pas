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
  Uni, inLibCatalogoSqlIntf,
  inLibFacturasServiciosIntf,
  inLibParametrosIntf;

function CrearServiciosFactura(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const ACatalogoSql: ICatalogoSql = nil;
  const AIncidenciasSql: IRegistroIncidenciasSql = nil
): TServiciosFactura;

implementation

uses
  UniDataFacturasRepositorio,
  UniDataArticulosResolverRepositorio,
  inLibFacturasValidacionFiscal,
  inLibFacturasCalculo,
  inLibFacturasBorrado,
  inLibFacturasEfectos;

function CrearServiciosFactura(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql
): TServiciosFactura;
var
  oRepositorio: IRepositorioFacturas;
begin
  oRepositorio := TRepositorioFacturas.Create(
    AConexion,
    ACatalogoSql,
    AIncidenciasSql);
  Result.Repositorio := oRepositorio;
  Result.ArticulosResolver :=
    TRepositorioArticulosResolver.Create(
      AConexion,
      AParametrosCaja,
      ACatalogoSql,
      AIncidenciasSql);
  Result.ValidadorFiscal :=
    TValidadorFiscalFactura.Create(oRepositorio);
  Result.Calculador := TCalculadorFactura.Create(AConexion);
  Result.Borrado := TServicioBorradoFactura.Create(AConexion);
  Result.Efectos := TServicioEfectosFactura.Create(AConexion);
end;

end.
