{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosGeneralesPantalla                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Repositorios por capacidades generales de una pantalla.                  }
{******************************************************************************}
unit UniDataRepositoriosGeneralesPantalla;

interface

uses
  Uni, inLibRepositoriosPantallaIntf, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibLogIntf,
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosPropiedadesPersistenciaIntf,
  inLibStockConsultaPersistenciaIntf, inLibImpresionPersistenciaIntf,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibAppParamPersistenciaIntf, inLibBusquedaDatosPersistenciaIntf,
  inLibGeneracionSkusPersistenciaIntf, inLibDistribuidorPersistenciaIntf,
  inLibMargenPersistenciaIntf, inLibDestinosFiltrosPersistenciaIntf,
  inLibFiltroArticulosPersistenciaIntf, inLibGuiasPersistenciaIntf,
  inLibDestinoEnvioPersistenciaIntf, inLibSeleccionFamiliaPersistenciaIntf,
  inLibSerieFechaFacturaPersistenciaIntf,
  inLibSeleccionAlmacenPersistenciaIntf,
  inLibFacturacionAlbaranesFechasPersistenciaIntf,
  inLibFacturacionAlbaranesCompraPersistenciaIntf,
  inLibFacturacionTicketPersistenciaIntf,
  inLibCargaEfectosRemesaPersistenciaIntf,
  inLibConsultaFacturasOperacionesPersistenciaIntf,
  inLibOperacionesCajaSkuPersistenciaIntf,
  inLibVentasCalendarioIntf, inLibEmisionFiscalIntf,
  inLibEntradaAlbaranVentaPersistenciaIntf, inLibColumnasSkuIntf,
  inLibClientesPersistenciaIntf,
  inLibListadoVentasPersistenciaIntf,
  inLibSeriesEmpresaPersistenciaIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf, inLibDocumentosTrabajo;

type
  TRepositoriosGeneralesPantallaUniDAC = class(
    TInterfacedObject,
    IRepositoriosArticulosPantalla,
    IRepositoriosConfiguracionPantalla,
    IRepositoriosDocumentosPantalla,
    IRepositoriosRemesasPantalla,
    IRepositoriosOperacionesPantalla,
    IRepositoriosVentasPantalla)
  private
    FConexionPrincipal: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FRegistroLog: IRegistroLog;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function Conexion(AConexion: TUniConnection): TUniConnection;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const ARegistroLog: IRegistroLog;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
    function CrearResolverArticulos(
      AConexion: TUniConnection = nil): IArticulosResolver;
    function CrearValidadorArticulos(
      AConexion: TUniConnection = nil): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection = nil): IArticulosAtributosLookup;
    function CrearServiciosPropiedadesArticulo(
      AConexion: TUniConnection = nil): TServiciosPropiedadesArticulo;
    function CrearServiciosStockConsulta(
      AConexion: TUniConnection = nil): TServiciosStockConsulta;
    function CrearRepositorioGeneracionSkus(
      AConexion: TUniConnection = nil): IRepositorioGeneracionSkus;
    function CrearRepositorioDistribuidor(
      AConexion: TUniConnection = nil): IRepositorioDistribuidor;
    function CrearRepositorioMargen(
      AConexion: TUniConnection = nil): IRepositorioMargen;
    function CrearRepositorioFiltroArticulos(
      AConexion: TUniConnection = nil): IRepositorioFiltroArticulos;
    function CrearServicioCargaMasivaArticulos:
      TServiciosCargaMasivaArticulos;
    function CrearRepositorioAppParam(
      AConexion: TUniConnection = nil): IRepositorioAppParam;
    function CrearRepositorioBusquedaDatos(
      AConexion: TUniConnection = nil): IRepositorioBusquedaDatos;
    function CrearRepositorioDestinosFiltros(
      AConexion: TUniConnection = nil): IRepositorioDestinosFiltros;
    function CrearRepositorioGuias(
      AConexion: TUniConnection = nil): IRepositorioGuias;
    function CrearRepositorioSeriesEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeriesEmpresa;
    function CrearRepositorioSeleccionBancoEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeleccionBancoEmpresa;
    function CrearServiciosPersistenciaImpresion(
      AConexion: TUniConnection = nil): TServiciosPersistenciaImpresion;
    function CrearServiciosPersistenciaDevolucionCompra(
      AConexion: TUniConnection = nil
    ): TServiciosPersistenciaDevolucionCompra;
    function CrearRepositorioDestinoEnvio(
      AConexion: TUniConnection = nil): IRepositorioDestinoEnvio;
    function CrearRepositorioSeleccionFamilia(
      AConexion: TUniConnection = nil): IRepositorioSeleccionFamilia;
    function CrearRepositorioSerieFechaFactura(
      AConexion: TUniConnection = nil): IRepositorioSerieFechaFactura;
    function CrearRepositorioSeleccionAlmacen(
      AConexion: TUniConnection = nil): IRepositorioSeleccionAlmacen;
    function CrearRepositorioFacturacionAlbaranesFechas(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesFechas;
    function CrearRepositorioFacturacionAlbaranesCompra(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesCompra;
    function CrearServicioFacturacionTicket(
      AConexion: TUniConnection = nil): IServicioFacturacionTicket;
    function CrearRepositoriosDocumentosTrabajo(
      AConexion: TUniConnection = nil): TRepositoriosDocumentosTrabajo;
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection = nil): IRepositorioCargaEfectosRemesa;
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
    function CrearRepositorioEntradaAlbaranVenta:
      IRepositorioEntradaAlbaranVenta;
    function CrearServiciosColumnasSku: TServiciosColumnasSku;
    function CrearRepositorioClientes: IRepositorioClientes;
    function CrearRepositorioListadoVentas: IRepositorioListadoVentas;
  end;

implementation

uses
  UniDataArticulosResolverRepositorio,
  UniDataArticulosValidadorRepositorio,
  UniDataArticulosAtributosRepositorio,
  UniDataArticulosPropiedadesRepositorio,
  UniDataStockConsultaRepositorio, UniDataImpresionRepositorio,
  UniDataDevolucionesCompraRepositorio, UniDataAppParamRepositorio,
  UniDataBusquedaDatosRepositorio, UniDataGeneracionSkusRepositorio,
  UniDataDistribuidorRepositorio, UniDataMargenRepositorio,
  UniDataDestinosFiltrosRepositorio, UniDataFiltroArticulosRepositorio,
  UniDataGuiasRepositorio, UniDataDestinoEnvioRepositorio,
  UniDataSeleccionFamiliaRepositorio,
  UniDataSerieFechaFacturaRepositorio,
  UniDataSeleccionAlmacenRepositorio,
  UniDataFacturacionAlbaranesFechasRepositorio,
  UniDataFacturacionAlbaranesCompraRepositorio,
  UniDataFacturacionTicketRepositorio,
  UniDataCargaEfectosRemesaRepositorio,
  UniDataConsultaFacturasOperacionesRepositorio,
  UniDataOperacionesCajaSkuRepositorio,
  UniDataVentasCalendario,
  UniDataEntradaAlbaranVentaRepositorio,
  UniDataColumnasSkuServicios,
  UniDataClientesRepositorio,
  UniDataListadoVentasRepositorio,
  UniDataSeriesEmpresaRepositorio,
  UniDataSeleccionBancoEmpresaRepositorio,
  UniDataCargaMasivaArticulosRepositorio,
  UniDataVerifactuColaRepositorio,
  inLibEmisionFiscal, inLibVerifactuColaIntf,
  UniDataDocumentosTrabajoRepositorio;

constructor TRepositoriosGeneralesPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexionPrincipal := AConexionPrincipal;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FRegistroLog := ARegistroLog;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

destructor TRepositoriosGeneralesPantallaUniDAC.Destroy;
begin
  FIncidenciasSql := nil;
  FCatalogoSql := nil;
  FRegistroLog := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FConexionPrincipal := nil;
  inherited;
end;

function TRepositoriosGeneralesPantallaUniDAC.Conexion(
  AConexion: TUniConnection): TUniConnection;
begin
  Result := AConexion;
  if not Assigned(Result) then
    Result := FConexionPrincipal;
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearResolverArticulos(
  AConexion: TUniConnection): IArticulosResolver;
begin
  Result := TRepositorioArticulosResolver.Create(
    Conexion(AConexion), FParametrosCaja, FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearValidadorArticulos(
  AConexion: TUniConnection): IArticulosValidador;
begin
  Result := TRepositorioArticulosValidador.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearLookupAtributosArticulos(
  AConexion: TUniConnection): IArticulosAtributosLookup;
begin
  Result := TRepositorioArticulosAtributos.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearServiciosPropiedadesArticulo(
  AConexion: TUniConnection): TServiciosPropiedadesArticulo;
begin
  Result := CrearServiciosPropiedadesArticuloUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearServiciosStockConsulta(
  AConexion: TUniConnection): TServiciosStockConsulta;
begin
  Result := CrearServiciosStockConsultaUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioGeneracionSkus(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;
begin
  Result := CrearRepositorioGeneracionSkusUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioDistribuidor(
  AConexion: TUniConnection): IRepositorioDistribuidor;
begin
  Result := CrearRepositorioDistribuidorUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioMargen(
  AConexion: TUniConnection): IRepositorioMargen;
begin
  Result := CrearRepositorioMargenUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioFiltroArticulos(
  AConexion: TUniConnection): IRepositorioFiltroArticulos;
begin
  Result := CrearRepositorioFiltroArticulosUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearServicioCargaMasivaArticulos: TServiciosCargaMasivaArticulos;
begin
  Result := CrearServicioCargaMasivaArticulosUniDAC(FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioAppParam(
  AConexion: TUniConnection): IRepositorioAppParam;
begin
  Result := CrearRepositorioAppParamUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioBusquedaDatos(
  AConexion: TUniConnection): IRepositorioBusquedaDatos;
begin
  Result := CrearRepositorioBusquedaDatosUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioDestinosFiltros(
  AConexion: TUniConnection): IRepositorioDestinosFiltros;
begin
  Result := CrearRepositorioDestinosFiltrosUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioGuias(
  AConexion: TUniConnection): IRepositorioGuias;
begin
  Result := CrearRepositorioGuiasUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioSeriesEmpresa(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;
begin
  Result := CrearRepositorioSeriesEmpresaUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearServiciosPersistenciaImpresion(
  AConexion: TUniConnection): TServiciosPersistenciaImpresion;
begin
  Result := CrearServiciosPersistenciaImpresionUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearServiciosPersistenciaDevolucionCompra(
  AConexion: TUniConnection): TServiciosPersistenciaDevolucionCompra;
begin
  Result := CrearServiciosPersistenciaDevolucionCompraUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioDestinoEnvio(
  AConexion: TUniConnection): IRepositorioDestinoEnvio;
begin
  Result := CrearRepositorioDestinoEnvioUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioSeleccionFamilia(
  AConexion: TUniConnection): IRepositorioSeleccionFamilia;
begin
  Result := CrearRepositorioSeleccionFamiliaUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioSerieFechaFactura(
  AConexion: TUniConnection): IRepositorioSerieFechaFactura;
begin
  Result := CrearRepositorioSerieFechaFacturaUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioSeleccionAlmacen(
  AConexion: TUniConnection): IRepositorioSeleccionAlmacen;
begin
  Result := CrearRepositorioSeleccionAlmacenUniDAC(Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioFacturacionAlbaranesFechas(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
begin
  Result := CrearRepositorioFacturacionAlbaranesFechasUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioFacturacionAlbaranesCompra(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;
begin
  Result := CrearRepositorioFacturacionAlbaranesCompraUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearServicioFacturacionTicket(
  AConexion: TUniConnection): IServicioFacturacionTicket;
var
  oCola: IServicioVerifactuCola;
  oConexion: TUniConnection;
  oEmision: IServicioEmisionFiscal;
begin
  oConexion := Conexion(AConexion);
  oCola := CrearServicioVerifactuColaUniDAC(oConexion, FRegistroLog);
  oEmision := inLibEmisionFiscal.CrearServicioEmisionFiscal(
    FParametrosApp, FParametrosCaja, oConexion, oCola);
  Result := CrearServicioFacturacionTicketUniDAC(
    oConexion, FParametrosApp, oEmision, oCola);
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
begin
  Result :=
    UniDataDocumentosTrabajoRepositorio.CrearRepositoriosDocumentosTrabajo(
      Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioCargaEfectosRemesa(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
begin
  Result := CrearRepositorioCargaEfectosRemesaUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioConsultaFacturas:
  IRepositorioConsultaFacturasOperaciones;
begin
  Result := CrearRepositorioConsultaFacturasOperacionesUniDAC(
    FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioVentasCalendario: IRepositorioVentasCalendario;
begin
  Result := CrearRepositorioVentasCalendarioUniDAC(FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearServicioEmisionFiscal:
  IServicioEmisionFiscal;
var
  Cola: IServicioVerifactuCola;
begin
  Cola := CrearServicioVerifactuColaUniDAC(
    FConexionPrincipal,
    FRegistroLog);
  Result := inLibEmisionFiscal.CrearServicioEmisionFiscal(
    FParametrosApp,
    FParametrosCaja,
    FConexionPrincipal,
    Cola);
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioOperacionesCajaSku(
  AConexion: TUniConnection): IRepositorioOperacionesCajaSku;
begin
  Result := CrearRepositorioOperacionesCajaSkuUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioSeleccionBancoEmpresa(
  AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;
begin
  Result := CrearRepositorioSeleccionBancoEmpresaUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosGeneralesPantallaUniDAC.
  CrearRepositorioEntradaAlbaranVenta: IRepositorioEntradaAlbaranVenta;
begin
  Result := CrearRepositorioEntradaAlbaranVentaUniDAC(FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearServiciosColumnasSku:
  TServiciosColumnasSku;
begin
  Result := CrearServiciosColumnasSkuUniDAC(FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioClientes:
  IRepositorioClientes;
begin
  Result := CrearRepositorioClientesUniDAC(FConexionPrincipal);
end;

function TRepositoriosGeneralesPantallaUniDAC.CrearRepositorioListadoVentas:
  IRepositorioListadoVentas;
begin
  Result := CrearRepositorioListadoVentasUniDAC(FConexionPrincipal);
end;

end.
