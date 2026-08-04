{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasPantallaComposicion                            }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Único punto de composición de servicios para documentos de compra.      }
{******************************************************************************}
unit UniDataComprasPantallaComposicion;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibComprasPantallaIntf,
  inLibRepositoriosPantallaIntf;

type
  TTipoComposicionComprasPantalla = (
    tccAlbaran,
    tccFactura,
    tccPedido,
    tccDevolucion,
    tccDocumentosTrabajo,
    tccPlantillas);

  TEntradaComposicionComprasPantalla = record
    Tipo: TTipoComposicionComprasPantalla;
    Conexion: TUniConnection;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    MaestroPlantillas: TDataSource;
  end;

function ComponerComprasPantalla(
  AOrigen: TComponent;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;

implementation

uses
  System.SysUtils,
  inLibAplicacionArticuloCompra,
  inLibArticulosResolverIntf,
  inLibComprasPantallaArticuloDevolucion,
  inLibComprasPantallaTransaccion,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDocumentosTrabajo,
  UniDataAplicacionArticuloCompra,
  UniDataBusquedasCompraRepositorio,
  UniDataComprasPantallaPersistencia,
  UniDataDevolucionesCompraRepositorio,
  UniDataDocumentosTrabajoRepositorio,
  UniDataPedidosCompraRecepcion;

procedure ComprobarEntrada(
  AOrigen: TComponent;
  const AEntrada: TEntradaComposicionComprasPantalla);
begin
  if AEntrada.Conexion = nil then
    raise EArgumentNilException.Create('AEntrada.Conexion');
  if (AEntrada.Tipo <> tccPlantillas) and (AOrigen = nil) then
    raise EArgumentNilException.Create('AOrigen');
end;

function CrearServiciosArticuloDocumento(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosDocumentoCompraPantalla;
var
  oResolver: IArticulosResolver;
begin
  Result := Default(TServiciosDocumentoCompraPantalla);
  Result.ValidadorArticulos := AArticulos.CrearValidadorArticulos(
    AEntrada.Conexion);
  oResolver := AArticulos.CrearResolverArticulos(
    AEntrada.Conexion);
  Result.LookupAtributos :=
    AArticulos.CrearLookupAtributosArticulos(AEntrada.Conexion);
  Result.AplicacionArticulo := CrearAplicacionArticuloCompra(
    CrearRepositorioLecturasArticuloCompraUniDAC(
      AEntrada.Conexion,
      Result.ValidadorArticulos,
      oResolver),
    CrearPuertoLineaArticuloCompraUniDAC(
      AEntrada.Conexion,
      AEntrada.Cabecera,
      AEntrada.Lineas));
  Result.BusquedasArticulos := CrearBusquedasCompraPersistenciaUniDAC(
    AEntrada.Conexion);
end;

procedure AsignarBusquedas(
  AConexion: TUniConnection;
  out AEmpresas: IBusquedaEmpresasComprasPantalla;
  out AProveedores: IBusquedaProveedoresComprasPantalla);
begin
  CrearBusquedasComprasPantallaUniDAC(
    AConexion,
    AEmpresas,
    AProveedores);
end;

function ComponerAlbaran(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.Documento := CrearServiciosArticuloDocumento(AArticulos, AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    Result.Documento.BusquedaEmpresas,
    Result.Documento.BusquedaProveedores);
end;

function ComponerFactura(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
var
  oEmpresas: IBusquedaEmpresasComprasPantalla;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.Documento := CrearServiciosArticuloDocumento(AArticulos, AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    oEmpresas,
    Result.Documento.BusquedaProveedores);
end;

function ComponerPedido(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.Pedido.Documento := CrearServiciosArticuloDocumento(
    AArticulos,
    AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    Result.Pedido.Documento.BusquedaEmpresas,
    Result.Pedido.Documento.BusquedaProveedores);
  Result.Pedido.Recepcion := ProtegerRecepcionPedidoCompra(
    CrearRecepcionPedidoCompraUniDAC(AEntrada.Conexion),
    CrearUnidadTrabajoComprasPantallaUniDAC(AEntrada.Conexion));
  Result.Pedido.Consultas := CrearConsultasPedidoCompraPantallaUniDAC(
    AEntrada.Conexion);
end;

function ComponerDevolucion(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
var
  oResolver: IArticulosResolver;
  oPersistencia: TServiciosPersistenciaDevolucionCompra;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.Devolucion.ValidadorArticulos :=
    AArticulos.CrearValidadorArticulos(AEntrada.Conexion);
  Result.Devolucion.LookupAtributos :=
    AArticulos.CrearLookupAtributosArticulos(AEntrada.Conexion);
  oResolver := AArticulos.CrearResolverArticulos(
    AEntrada.Conexion);
  oPersistencia := CrearServiciosPersistenciaDevolucionCompraUniDAC(
    AEntrada.Conexion);
  Result.Devolucion.Datos := oPersistencia.Datos;
  Result.Devolucion.Stock := ProtegerStockDevolucionCompra(
    oPersistencia.Stock,
    CrearUnidadTrabajoComprasPantallaUniDAC(AEntrada.Conexion));
  Result.Devolucion.AplicacionArticulo :=
    CrearAplicacionArticuloDevolucionCompra(
      Result.Devolucion.ValidadorArticulos,
      oResolver,
      Result.Devolucion.Datos);
  Result.Devolucion.BusquedasArticulos :=
    CrearBusquedasCompraPersistenciaUniDAC(AEntrada.Conexion);
  AsignarBusquedas(
    AEntrada.Conexion,
    Result.Devolucion.BusquedaEmpresas,
    Result.Devolucion.BusquedaProveedores);
end;

function ComponerDocumentosTrabajo(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
var
  oRepositorios: TRepositoriosDocumentosTrabajo;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.DocumentosTrabajo.ValidadorArticulos :=
    AArticulos.CrearValidadorArticulos(AEntrada.Conexion);
  Result.DocumentosTrabajo.LookupAtributos :=
    AArticulos.CrearLookupAtributosArticulos(AEntrada.Conexion);
  oRepositorios := CrearRepositoriosDocumentosTrabajo(AEntrada.Conexion);
  Result.DocumentosTrabajo.Lecturas := oRepositorios.Lecturas;
  Result.DocumentosTrabajo.Materializacion :=
    oRepositorios.Materializacion;
end;

function ComponerPlantillas(
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
begin
  Result := Default(TServiciosComprasPantalla);
  Result.Plantillas := CrearPersistenciaPlantillasCompraPantallaUniDAC(
    AEntrada.Conexion,
    AEntrada.MaestroPlantillas);
end;

function ComponerComprasPantalla(
  AOrigen: TComponent;
  const AEntrada: TEntradaComposicionComprasPantalla):
  TServiciosComprasPantalla;
var
  oArticulos: IRepositoriosArticulosPantalla;
begin
  ComprobarEntrada(AOrigen, AEntrada);
  oArticulos := nil;
  if AEntrada.Tipo <> tccPlantillas then
    oArticulos := ObtenerCompositorArticulosPantalla(AOrigen).
      CrearRepositoriosArticulosPantalla(AOrigen.Name);
  case AEntrada.Tipo of
    tccAlbaran:
      Result := ComponerAlbaran(oArticulos, AEntrada);
    tccFactura:
      Result := ComponerFactura(oArticulos, AEntrada);
    tccPedido:
      Result := ComponerPedido(oArticulos, AEntrada);
    tccDevolucion:
      Result := ComponerDevolucion(oArticulos, AEntrada);
    tccDocumentosTrabajo:
      Result := ComponerDocumentosTrabajo(oArticulos, AEntrada);
    tccPlantillas:
      Result := ComponerPlantillas(AEntrada);
  else
    raise EArgumentOutOfRangeException.Create('AEntrada.Tipo');
  end;
end;

end.
