{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataVentasPantallaComposicion                              }
{    Tipo:       Composicion                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Compone cada pantalla de ventas con capacidades estrechas.                }
{******************************************************************************}
unit UniDataVentasPantallaComposicion;

interface

uses
  System.Classes, Uni,
  inLibContextoSesionIntf,
  inLibParametrosIntf,
  inLibRepositoriosPantallaIntf,
  inLibVentasPantallaIntf,
  UniDataPedidos;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoAlbaranesVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  ADataModule: TdmPedidos;
  out AContexto: TContextoPedidosVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  out AContexto: TContextoClientesVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  out AContexto: TContextoFacturasSimplificadasVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoDestinoEnvioVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto:
    TContextoFacturacionAlbaranesFechasVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto:
    TContextoFacturacionAlbaranesCompraVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionTicketVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSerieFechaFacturaVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionFamiliaVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionAlmacenVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoListadoVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoImpresionVentasPantalla); overload;

implementation

uses
  System.SysUtils,
  inLibVentasPantallaCrearAlbaran,
  UniDataVentasPantallaPedidos,
  UniDataVentasPantallaFacturasSimplificadas;

procedure ComprobarOrigen(AOrigen: TComponent);
begin
  if not Assigned(AOrigen) then
    raise EArgumentNilException.Create('AOrigen');
end;

function CrearRepositoriosArticulos(
  AOrigen: TComponent): IRepositoriosArticulosPantalla;
begin
  ComprobarOrigen(AOrigen);
  Result := ObtenerCompositorArticulosPantalla(AOrigen).
    CrearRepositoriosArticulosPantalla(AOrigen.Name);
end;

function CrearRepositoriosDocumentos(
  AOrigen: TComponent): IRepositoriosDocumentosPantalla;
begin
  ComprobarOrigen(AOrigen);
  Result := ObtenerCompositorDocumentosPantalla(AOrigen).
    CrearRepositoriosDocumentosPantalla(AOrigen.Name);
end;

function CrearRepositoriosVentas(
  AOrigen: TComponent): IRepositoriosVentasPantalla;
begin
  ComprobarOrigen(AOrigen);
  Result := ObtenerCompositorVentasPantalla(AOrigen).
    CrearRepositoriosVentasPantalla(AOrigen.Name);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoAlbaranesVentasPantalla);
var
  oArticulos: IRepositoriosArticulosPantalla;
  oVentas: IRepositoriosVentasPantalla;
begin
  oArticulos := CrearRepositoriosArticulos(AOrigen);
  oVentas := CrearRepositoriosVentas(AOrigen);
  AContexto := Default(TContextoAlbaranesVentasPantalla);
  AContexto.ResolverArticulos :=
    oArticulos.CrearResolverArticulos(AConexion);
  AContexto.ValidadorArticulos :=
    oArticulos.CrearValidadorArticulos(AConexion);
  AContexto.AtributosArticulos :=
    oArticulos.CrearLookupAtributosArticulos(AConexion);
  AContexto.ColumnasSku := oVentas.CrearServiciosColumnasSku;
  AContexto.EntradaArticulos :=
    oVentas.CrearRepositorioEntradaAlbaranVenta;
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  ADataModule: TdmPedidos;
  out AContexto: TContextoPedidosVentasPantalla);
var
  oArticulos: IRepositoriosArticulosPantalla;
  oVentas: IRepositoriosVentasPantalla;
begin
  oArticulos := CrearRepositoriosArticulos(AOrigen);
  oVentas := CrearRepositoriosVentas(AOrigen);
  AContexto := Default(TContextoPedidosVentasPantalla);
  AContexto.ResolverArticulos :=
    oArticulos.CrearResolverArticulos(AConexion);
  AContexto.ValidadorArticulos :=
    oArticulos.CrearValidadorArticulos(AConexion);
  AContexto.AtributosArticulos :=
    oArticulos.CrearLookupAtributosArticulos(AConexion);
  AContexto.ColumnasSku := oVentas.CrearServiciosColumnasSku;
  AContexto.EntradaArticulos :=
    oVentas.CrearRepositorioEntradaAlbaranVenta;
  AContexto.CrearAlbaran := TCasoUsoCrearAlbaranPedido.Create(
    CrearRepositorioCreacionAlbaranPedidoUniDAC(ADataModule));
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  out AContexto: TContextoClientesVentasPantalla);
begin
  AContexto := Default(TContextoClientesVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositoriosVentas(AOrigen).CrearRepositorioClientes;
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  out AContexto: TContextoFacturasSimplificadasVentasPantalla);
begin
  ComprobarOrigen(AOrigen);
  AContexto := Default(TContextoFacturasSimplificadasVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioFacturasSimplificadasPantallaUniDAC(
      AConexion,
      AListado,
      AContextoSesion,
      AParametrosApp);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoDestinoEnvioVentasPantalla);
begin
  AContexto := Default(TContextoDestinoEnvioVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioDestinoEnvio(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionAlbaranesFechasVentasPantalla);
begin
  AContexto := Default(
    TContextoFacturacionAlbaranesFechasVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioFacturacionAlbaranesFechas(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionAlbaranesCompraVentasPantalla);
begin
  AContexto := Default(
    TContextoFacturacionAlbaranesCompraVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioFacturacionAlbaranesCompra(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionTicketVentasPantalla);
var
  oDocumentos: IRepositoriosDocumentosPantalla;
begin
  oDocumentos := CrearRepositoriosDocumentos(AOrigen);
  AContexto := Default(TContextoFacturacionTicketVentasPantalla);
  AContexto.Series :=
    oDocumentos.CrearRepositorioSerieFechaFactura(AConexion);
  AContexto.Facturacion :=
    oDocumentos.CrearServicioFacturacionTicket(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSerieFechaFacturaVentasPantalla);
begin
  AContexto := Default(TContextoSerieFechaFacturaVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioSerieFechaFactura(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionFamiliaVentasPantalla);
begin
  AContexto := Default(TContextoSeleccionFamiliaVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioSeleccionFamilia(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionAlmacenVentasPantalla);
begin
  AContexto := Default(TContextoSeleccionAlmacenVentasPantalla);
  AContexto.Repositorio := CrearRepositoriosDocumentos(AOrigen).
    CrearRepositorioSeleccionAlmacen(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoListadoVentasPantalla);
var
  oArticulos: IRepositoriosArticulosPantalla;
  oDocumentos: IRepositoriosDocumentosPantalla;
  oVentas: IRepositoriosVentasPantalla;
begin
  oArticulos := CrearRepositoriosArticulos(AOrigen);
  oDocumentos := CrearRepositoriosDocumentos(AOrigen);
  oVentas := CrearRepositoriosVentas(AOrigen);
  AContexto := Default(TContextoListadoVentasPantalla);
  AContexto.Listado := oVentas.CrearRepositorioListadoVentas;
  AContexto.DocumentosTrabajo :=
    oDocumentos.CrearRepositoriosDocumentosTrabajo(AConexion);
  AContexto.ResolverArticulos :=
    oArticulos.CrearResolverArticulos(AConexion);
end;

procedure CrearContextoVentasPantalla(
  AOrigen: TComponent;
  AConexion: TUniConnection;
  out AContexto: TContextoImpresionVentasPantalla);
begin
  AContexto := Default(TContextoImpresionVentasPantalla);
  AContexto.Persistencia := CrearRepositoriosDocumentos(AOrigen).
    CrearServiciosPersistenciaImpresion(AConexion);
end;

end.
