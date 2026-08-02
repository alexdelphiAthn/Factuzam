{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRepositoriosPantallaIntf                                }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Contexto de adaptadores de persistencia disponible para una pantalla.    }
{******************************************************************************}
unit inLibRepositoriosPantallaIntf;

interface

uses
  Data.DB, Uni, inLibCatalogoSqlIntf, inLibArticulosResolverIntf,
  inLibParametrosIntf, inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf, inLibLogIntf, inLibPreviewTicket,
  inLibArticulosValidadorIntf, inLibArticulosAtributosIntf,
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
  inLibCargaMasivaArticulosPersistenciaIntf, inLibDocumentosTrabajo,
  inLibCajasDefectoPersistenciaIntf, inLibFaseCobroPersistenciaIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf, inLibCajaVentaIntf,
  inLibTraspasoOpePersistenciaIntf, inLibModalArqueoPersistenciaIntf,
  inLibInformesCajaPersistenciaIntf, inLibGastoCajaPersistenciaIntf,
  inLibEntradaCambioPersistenciaIntf, inLibGenerarTicketIntf,
  inLibTraspasoTicketIntf, inLibArqueoIntf, inLibArqueoPersistencia,
  inLibArqueoTicketIntf, inLibTiraCajaTicketIntf,
  inLibTicketsCajaIntf;

type
  IRepositoriosArticulosPantalla = interface
    ['{41046501-116D-42EF-B24D-E64A811DA5D8}']
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
  end;

  IRepositoriosConfiguracionPantalla = interface
    ['{51902F28-F05D-4855-AB2D-16EF80EB0384}']
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
  end;

  IRepositoriosDocumentosPantalla = interface
    ['{62FEB439-E697-482A-9A0B-D986CE865B48}']
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
  end;

  IRepositoriosCajaPantalla = interface
    ['{6348B7FD-E5FE-48AC-85CB-7B85AD979A44}']
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil): IArqueoPersistencia;
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
  end;

  IRepositoriosRemesasPantalla = interface
    ['{24B93D18-5C59-4DC4-B9C2-911F88A849A5}']
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection = nil): IRepositorioCargaEfectosRemesa;
  end;

  IRepositoriosOperacionesPantalla = interface
    ['{AF97D4E0-A6D6-49C8-9070-1763E7BF95B1}']
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
  end;

  IRepositoriosVentasPantalla = interface
    ['{4CBCCABC-3FBC-4D4D-B9CC-37E7F592D9A4}']
    function CrearRepositorioEntradaAlbaranVenta:
      IRepositorioEntradaAlbaranVenta;
    function CrearServiciosColumnasSku: TServiciosColumnasSku;
    function CrearRepositorioClientes: IRepositorioClientes;
    function CrearRepositorioListadoVentas: IRepositorioListadoVentas;
  end;

  IRepositoriosTicketsCajaPantalla = interface
    ['{E2452458-D235-4816-9EEE-40FF9C4E3826}']
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

  IContextoRepositoriosPantalla = interface
    ['{0F2AFBE9-AE28-4DD0-BC28-AD45C3A14965}']
    function CatalogoSql: ICatalogoSql;
    function IncidenciasSql: IRegistroIncidenciasSql;
    function Articulos: IRepositoriosArticulosPantalla;
    function Configuracion: IRepositoriosConfiguracionPantalla;
    function Documentos: IRepositoriosDocumentosPantalla;
    function Remesas: IRepositoriosRemesasPantalla;
    function Operaciones: IRepositoriosOperacionesPantalla;
    function Ventas: IRepositoriosVentasPantalla;
    function Caja: IRepositoriosCajaPantalla;
    function TicketsCaja: IRepositoriosTicketsCajaPantalla;
  end;

  IProveedorContextoRepositoriosPantalla = interface
    ['{C7AF93C9-861B-4486-8BA3-F46B65FC20FA}']
    function GetContextoRepositoriosPantalla:
      IContextoRepositoriosPantalla;
    property ContextoRepositoriosPantalla: IContextoRepositoriosPantalla
      read GetContextoRepositoriosPantalla;
  end;

  IFabricaContextosRepositoriosPantalla = interface
    ['{A710190E-74AF-4B57-B259-97B3C688BB20}']
    function Crear(
      const ANombrePantalla: string;
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const APerfilesLectura: ILectorPerfilesUsuario;
      const APerfilesEscritura: IEscritorPerfilesUsuario;
      const ARegistroLog: IRegistroLog;
      const APreviewTicket: IPreviewTicket
    ): IContextoRepositoriosPantalla;
  end;

  IProveedorFabricaContextosRepositoriosPantalla = interface
    ['{5CC18BC6-B146-47A6-90EC-B505231F2571}']
    function GetFabricaContextosRepositoriosPantalla:
      IFabricaContextosRepositoriosPantalla;
    property FabricaContextosRepositoriosPantalla:
      IFabricaContextosRepositoriosPantalla
      read GetFabricaContextosRepositoriosPantalla;
  end;

implementation

end.
