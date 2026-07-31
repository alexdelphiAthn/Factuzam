{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesComposicion                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone el caso de uso de sesiones con sus adaptadores UniDAC.            }
{******************************************************************************}
unit UniDataComprasSesionesComposicion;

interface

uses
  Uni,
  inLibFotos,
  inLibCatalogoSqlIntf,
  inLibComprasSesiones,
  UniDataComprasSesiones;

function CrearServicioComprasSesiones(
  AConexion: TUniConnection;
  ADataModule: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql):
  TServicioComprasSesiones;

implementation

uses
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesionesMaterializar,
  UniDataComprasSesionesMaterializacionRepositorio,
  UniDataComprasSesionesRepositorio,
  UniDataComprasSesionesUnidadTrabajo;

function CrearServicioComprasSesiones(
  AConexion: TUniConnection;
  ADataModule: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql):
  TServicioComprasSesiones;
var
  oAdaptadorLecturas:
    TRepositorioLecturasMaterializacionComprasSesiones;
  oLecturasMaterializacion:
    TServiciosLecturasMaterializacion;
  oMaterializacion:
    IPersistenciaMaterializacionComprasSesiones;
  oRepositorioSesiones:
    IRepositorioComprasSesiones;
  oReversion:
    IPersistenciaReversionComprasSesiones;
  oUnidadTrabajo:
    IUnidadTrabajoMaterializacion;
begin
  oRepositorioSesiones :=
    TRepositorioComprasSesiones.Create(
      AConexion,
      ADataModule,
      ACatalogoSql,
      AIncidenciasSql);
  oLecturasMaterializacion :=
    Default(TServiciosLecturasMaterializacion);
  oAdaptadorLecturas :=
    TRepositorioLecturasMaterializacionComprasSesiones.Create(
      AConexion, ACatalogoSql, AIncidenciasSql);
  oLecturasMaterializacion.Articulos := oAdaptadorLecturas;
  oLecturasMaterializacion.Albaranes.Articulos := oAdaptadorLecturas;
  oLecturasMaterializacion.Albaranes.Documentos := oAdaptadorLecturas;
  oLecturasMaterializacion.Estado := oAdaptadorLecturas;
  oLecturasMaterializacion.Pedidos.Articulos := oAdaptadorLecturas;
  oLecturasMaterializacion.Pedidos.Documentos := oAdaptadorLecturas;
  oLecturasMaterializacion.Pedidos.Pendientes := oAdaptadorLecturas;
  oLecturasMaterializacion.Reversion := oAdaptadorLecturas;
  oMaterializacion :=
    TPersistenciaMaterializacionComprasSesiones.Create(
      ADataModule,
      AFotos,
      oLecturasMaterializacion,
      oRepositorioSesiones);
  oReversion := oMaterializacion as
    IPersistenciaReversionComprasSesiones;
  oUnidadTrabajo :=
    TUnidadTrabajoMaterializacionUniDAC.Create(
      AConexion);
  Result := TServicioComprasSesiones.Create(
    oRepositorioSesiones,
    oMaterializacion,
    oReversion,
    oUnidadTrabajo);
end;

end.
