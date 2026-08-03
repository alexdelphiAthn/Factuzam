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
  System.Classes, Data.DB, Uni, inLibCatalogoSqlIntf,
  inLibArticulosResolverIntf,
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
  TServiciosSqlPantalla = record
    Catalogo: ICatalogoSql;
    Incidencias: IRegistroIncidenciasSql;
  end;

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

  ICompositorSqlPantalla = interface
    ['{1D93D3B8-B5B4-43F0-B926-A78AE4F9C81F}']
    function CrearServiciosSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
  end;

  ICompositorArticulosPantalla = interface
    ['{F689479E-9EB6-478D-BB50-4F28518A25B0}']
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
  end;

  ICompositorConfiguracionPantalla = interface
    ['{AA5843CE-CB1A-47A8-A713-BECE1B091DE0}']
    function CrearRepositoriosConfiguracionPantalla(
      const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
  end;

  ICompositorDocumentosPantalla = interface
    ['{C770140A-2594-481E-879A-74DF701D7F8E}']
    function CrearRepositoriosDocumentosPantalla(
      const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
  end;

  ICompositorRemesasPantalla = interface
    ['{8F31BA0C-1F56-4C90-892B-7A0D51F78633}']
    function CrearRepositoriosRemesasPantalla(
      const ANombrePantalla: string): IRepositoriosRemesasPantalla;
  end;

  ICompositorOperacionesPantalla = interface
    ['{0B3BFAD5-4AE2-41D0-B117-3C09E44C877B}']
    function CrearRepositoriosOperacionesPantalla(
      const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
  end;

  ICompositorVentasPantalla = interface
    ['{5EE952E8-B49D-41CF-A3D5-1B3DE68D1C02}']
    function CrearRepositoriosVentasPantalla(
      const ANombrePantalla: string): IRepositoriosVentasPantalla;
  end;

  ICompositorCajaPantalla = interface
    ['{17713D3B-9423-41E4-B09E-C07D55CE4E91}']
    function CrearRepositoriosCajaPantalla(
      const ANombrePantalla: string): IRepositoriosCajaPantalla;
  end;

  ICompositorTicketsCajaPantalla = interface
    ['{49518DD8-2C20-44EE-A6B5-5E63219518D3}']
    function CrearRepositoriosTicketsCajaPantalla(
      const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
  end;

function ObtenerCompositorSqlPantalla(
  AOrigen: TComponent): ICompositorSqlPantalla;
function ObtenerCompositorArticulosPantalla(
  AOrigen: TComponent): ICompositorArticulosPantalla;
function ObtenerCompositorConfiguracionPantalla(
  AOrigen: TComponent): ICompositorConfiguracionPantalla;
function ObtenerCompositorDocumentosPantalla(
  AOrigen: TComponent): ICompositorDocumentosPantalla;
function ObtenerCompositorRemesasPantalla(
  AOrigen: TComponent): ICompositorRemesasPantalla;
function ObtenerCompositorOperacionesPantalla(
  AOrigen: TComponent): ICompositorOperacionesPantalla;
function ObtenerCompositorVentasPantalla(
  AOrigen: TComponent): ICompositorVentasPantalla;
function ObtenerCompositorCajaPantalla(
  AOrigen: TComponent): ICompositorCajaPantalla;
function ObtenerCompositorTicketsCajaPantalla(
  AOrigen: TComponent): ICompositorTicketsCajaPantalla;

implementation

uses
  System.SysUtils, Vcl.Forms;

resourcestring
  SErrorCompositorPantallaNoDisponible =
    'La raíz de composición no publica la capacidad solicitada.';

function BuscarCompositor(
  AOrigen: TComponent;
  const AIdInterfaz: TGUID): IInterface;
var
  oActual: TComponent;
begin
  Result := nil;
  oActual := AOrigen;
  while Assigned(oActual) and not Assigned(Result) do
  begin
    oActual.GetInterface(AIdInterfaz, Result);
    oActual := oActual.Owner;
  end;
  if not Assigned(Result) and Assigned(Application.MainForm) then
    Application.MainForm.GetInterface(AIdInterfaz, Result);
  if not Assigned(Result) then
    raise EInvalidOpException.Create(
      SErrorCompositorPantallaNoDisponible);
end;

function ObtenerCompositorSqlPantalla(
  AOrigen: TComponent): ICompositorSqlPantalla;
begin
  Result := BuscarCompositor(
    AOrigen, ICompositorSqlPantalla) as ICompositorSqlPantalla;
end;

function ObtenerCompositorArticulosPantalla(
  AOrigen: TComponent): ICompositorArticulosPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorArticulosPantalla) as ICompositorArticulosPantalla;
end;

function ObtenerCompositorConfiguracionPantalla(
  AOrigen: TComponent): ICompositorConfiguracionPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorConfiguracionPantalla) as ICompositorConfiguracionPantalla;
end;

function ObtenerCompositorDocumentosPantalla(
  AOrigen: TComponent): ICompositorDocumentosPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorDocumentosPantalla) as ICompositorDocumentosPantalla;
end;

function ObtenerCompositorRemesasPantalla(
  AOrigen: TComponent): ICompositorRemesasPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorRemesasPantalla) as ICompositorRemesasPantalla;
end;

function ObtenerCompositorOperacionesPantalla(
  AOrigen: TComponent): ICompositorOperacionesPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorOperacionesPantalla) as ICompositorOperacionesPantalla;
end;

function ObtenerCompositorVentasPantalla(
  AOrigen: TComponent): ICompositorVentasPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorVentasPantalla) as ICompositorVentasPantalla;
end;

function ObtenerCompositorCajaPantalla(
  AOrigen: TComponent): ICompositorCajaPantalla;
begin
  Result := BuscarCompositor(
    AOrigen, ICompositorCajaPantalla) as ICompositorCajaPantalla;
end;

function ObtenerCompositorTicketsCajaPantalla(
  AOrigen: TComponent): ICompositorTicketsCajaPantalla;
begin
  Result := BuscarCompositor(
    AOrigen,
    ICompositorTicketsCajaPantalla) as ICompositorTicketsCajaPantalla;
end;

end.
