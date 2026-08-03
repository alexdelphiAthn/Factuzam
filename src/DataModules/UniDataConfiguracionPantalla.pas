{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConfiguracionPantalla                                 }
{    Tipo:       Adaptador de composición                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       03/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.    }
{                                                                              }
{  Descripción:                                                               }
{    Compone las dependencias estrechas de configuración y auxiliares.        }
{******************************************************************************}
unit UniDataConfiguracionPantalla;

interface

uses
  System.Classes, Uni,
  inLibRepositoriosPantallaIntf,
  inLibArticulosResolverIntf,
  inLibAppParamPersistenciaIntf,
  inLibBusquedaDatosPersistenciaIntf,
  inLibCargaEfectosRemesaPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibDocumentosTrabajo,
  inLibFiltroArticulosPersistenciaIntf,
  inLibGeneracionSkusPersistenciaIntf,
  inLibGuiasPersistenciaIntf,
  inLibMargenPersistenciaIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  inLibSeriesEmpresaPersistenciaIntf;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioAppParam); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioBusquedaDatos;
  out ADocumentos: TRepositoriosDocumentosTrabajo;
  out AResolverArticulos: IArticulosResolver); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeriesEmpresa); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  out AServicios: TServiciosCargaMasivaArticulos); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioMargen); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioCargaEfectosRemesa); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDistribuidor); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioFiltroArticulos); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGeneracionSkus); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDestinosFiltros); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGuias); overload;
procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeleccionBancoEmpresa); overload;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorOrigenComposicionNulo =
    'El origen de composición es nulo';

function CrearRepositoriosArticulos(
  AOrigen: TComponent): IRepositoriosArticulosPantalla;
begin
  if not Assigned(AOrigen) then
    raise EArgumentNilException.Create(SErrorOrigenComposicionNulo);
  Result := ObtenerCompositorArticulosPantalla(AOrigen).
    CrearRepositoriosArticulosPantalla(AOrigen.Name);
end;

function CrearRepositoriosConfiguracion(
  AOrigen: TComponent): IRepositoriosConfiguracionPantalla;
begin
  if not Assigned(AOrigen) then
    raise EArgumentNilException.Create(SErrorOrigenComposicionNulo);
  Result := ObtenerCompositorConfiguracionPantalla(AOrigen).
    CrearRepositoriosConfiguracionPantalla(AOrigen.Name);
end;

function CrearRepositoriosDocumentos(
  AOrigen: TComponent): IRepositoriosDocumentosPantalla;
begin
  if not Assigned(AOrigen) then
    raise EArgumentNilException.Create(SErrorOrigenComposicionNulo);
  Result := ObtenerCompositorDocumentosPantalla(AOrigen).
    CrearRepositoriosDocumentosPantalla(AOrigen.Name);
end;

function CrearRepositoriosRemesas(
  AOrigen: TComponent): IRepositoriosRemesasPantalla;
begin
  if not Assigned(AOrigen) then
    raise EArgumentNilException.Create(SErrorOrigenComposicionNulo);
  Result := ObtenerCompositorRemesasPantalla(AOrigen).
    CrearRepositoriosRemesasPantalla(AOrigen.Name);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioAppParam);
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioAppParam(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioBusquedaDatos;
  out ADocumentos: TRepositoriosDocumentosTrabajo;
  out AResolverArticulos: IArticulosResolver);
var
  oArticulos: IRepositoriosArticulosPantalla;
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioBusquedaDatos(
    AConexion);
  ADocumentos := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositoriosDocumentosTrabajo(AConexion);
  oArticulos := CrearRepositoriosArticulos(AOrigen);
  AResolverArticulos := oArticulos.CrearResolverArticulos(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeriesEmpresa);
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioSeriesEmpresa(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  out AServicios: TServiciosCargaMasivaArticulos);
begin
  AServicios := CrearRepositoriosArticulos(AOrigen).
    CrearServicioCargaMasivaArticulos;
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioMargen);
begin
  ARepositorio := CrearRepositoriosArticulos(AOrigen).
    CrearRepositorioMargen(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioCargaEfectosRemesa);
begin
  ARepositorio := CrearRepositoriosRemesas(AOrigen).
    CrearRepositorioCargaEfectosRemesa(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDistribuidor);
begin
  ARepositorio := CrearRepositoriosArticulos(AOrigen).
    CrearRepositorioDistribuidor(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioFiltroArticulos);
begin
  ARepositorio := CrearRepositoriosArticulos(AOrigen).
    CrearRepositorioFiltroArticulos(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGeneracionSkus);
begin
  ARepositorio := CrearRepositoriosArticulos(AOrigen).
    CrearRepositorioGeneracionSkus(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDestinosFiltros);
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioDestinosFiltros(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGuias);
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioGuias(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeleccionBancoEmpresa);
begin
  ARepositorio := CrearRepositoriosConfiguracion(AOrigen).
    CrearRepositorioSeleccionBancoEmpresa(AConexion);
end;

end.
