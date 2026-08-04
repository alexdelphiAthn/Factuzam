{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCaja                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de caja (TPV).                                                }
{    Operaciones, pagos, vales, depósitos y generación de facturas desde caja. }
{******************************************************************************}
unit UniDataCaja;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Data.DB, Datasnap.Provider,
  Datasnap.DBClient, Uni, MemDS, DBAccess, system.Math, UniDataGen,
  system.StrUtils, inLibFaseCobro, Windows,
  inLibCajaDatosFactura, inLibCajaTipos, inLibContextoSesionIntf,
  inLibParametrosIntf, inLibTicketsCajaIntf, inLibPreviewTicket;

type
  TTipoRectificativaCaja = inLibCajaTipos.TTipoRectificativaCaja;
  TTratamientoMovimientosRectificativa =
    inLibCajaTipos.TTratamientoMovimientosRectificativa;
  TDatosCabeceraFactura =
    inLibCajaDatosFactura.TDatosCabeceraFactura;

  TDatosLineaFactura = record
    Linea:               string;
    Articulo:            string;
    Sku:                 string;
    Descripcion:         string;
    DescripcionVariacion:string;
    Familia:             string;
    NombreFamilia:       string;
    TipoArticulo:        string;
    TipoCantidad:        string;
    Cantidad:            Double;
    Tarifa:              string;
    EsImpIncl:           string;
    PrecioSalida:        Currency;
    PorcDto:             Double;
    PrecioDto:           Currency;
    PrecioSIva:          Currency;
    PrecioCIva:          Currency;
    TipoIva:             string;
    PorcIva:             Double;
    TotalSIva:           Currency;
    TotalCIva:           Currency;
    Vendedor:            string;
    // campos de depósito
    VieneDeDeposito:     string;   // 'S', 'A', ''
    AccionDeposito:      string;   // 'COBRAR', 'NUEVO_DEP', 'AUMENTAR_DEP', ...
    idDeposito:          string;
    PrecioOriginalDep:   Currency;
    AnticipoPrevio:      Currency;
  end;

type
  TRellenarArticuloEvent  = function(ACodigo: string): Boolean of object;
  TRellenarAtributosEvent = procedure(ASku: string) of object;
  TOnUpdateTotalEvent =
                     procedure(Sender: TObject; NuevoTotal: Currency) of object;
  TRecalcularLineasEvent = procedure of object;

  TdmCajaOpe = class(TDataModule)
    cdsLineas:TClientDataSet;
    cdsCabecera:TClientDataSet;
    DataSetProviderLineas:TDataSetProvider;
    DataSetProviderCabecera:TDataSetProvider;
    dsCabecera:TDataSource;
    dsLineas:TDataSource;
    qryDefinicionArticulo: TUniQuery;
    qryVales: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasAfterInsert(DataSet: TDataSet);
    procedure cdsCabeceraAfterInsert(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FOnRellenarArticulo:  TRellenarArticuloEvent;
    FOnRellenarAtributos: TRellenarAtributosEvent;
    FOnUpdateTotal: TOnUpdateTotalEvent;
    FOnRecalcularLineas: TRecalcularLineasEvent;
    // Serie/numero reales de la ultima factura grabada por
    // GrabarFacturaSimplificada. La cola y la rectificativa Verifactu los
    // necesitan fiables: cdsCabecera puede quedar con SERIE_FAC='0'.
    FUltSerieFacGrabada:  string;
    FUltNumeroFacGrabada: string;
    FContextoSesion: IContextoSesionAplicacion;
    FRepositorioTicketsCaja: TRepositoriosTicketsCaja;
    FPreviewTicket: IPreviewTicket;
    function GetIdentidadSesion: TIdentidadSesion;
    procedure InsertarMovimientoAlmacen(
                          QryTrx:     TUniQuery;
                          ATipoDoc:   string;
                          ASerie:     string;
                          ANro:       string;
                          ALinea:     string;
                          AEmpresa:   string;
                          AAlmacen:   string;
                          ACaja:      string;
                          AAlmacenContra: string; // <--- AÑADIDO AQUÍ
                          ATipoMov:   string;
                          ASku:       string;
                          ACantidad:  Double;
                          ACoste:     Currency;
                          AUsuario:   string;
                          const AAlmacenDoc: string = '';
                          const ANumOperacion: string = '';
                          const ACodCliente:string = '';
                          const ACodArticulo:string='';
                          AFechaMovimiento: TDateTime = 0;
                          const ANumeroMovimiento: string = '');
    procedure InsertarLineaFactura(
                        QryTrx:              TUniQuery;
                        // — identificación —
                        const ASerie:        string;
                        const ANro:          string;
                        const ALinea:        string;   // '0010', '0020'...
                        // — artículo —
                        const AArticulo:     string;
                        const ASku:          string;
                        const ADesc:         string;
                        const ADescVariacion:string;
                        const AFamilia:      string;
                        const ANombreFamilia:string;
                        // 'ESTANDAR', 'SERVICIO', 'KIT'
                        const ATipoArticulo: string;
                        const ATipoCantidad: string;   // 'Uds', 'Kg'...
                        ACantidad:           Double;
                        // — tarifa y precios —
                        const ATarifa:       string;
                        AEsImpIncl:          string;   // 'S'/'N'
                        APrecioSalida:       Currency;
                        APorcDto:            Double;
                        APrecioDto:          Currency;
                        APrecioSIva:         Currency;
                        APrecioCIva:         Currency;
                        const ATipoIva:      string;   // 'N','R','S','E'
                        APorcIva:            Double;
                        ATotalSIva:          Currency;
                        ATotalCIva:          Currency;
                        // — vendedor —
                        const AVendedor:     string;
                        // — caja y trazabilidad —
                        const AEmpresa:      string;
                        const AAlmacen:      string;
                        const ACaja:         string;
                        ANumOperacion:       string;
                        // NUMERO_MOV de fza_movimientos_almacen
                        const ANumMovAlmacen:string;
                        const AUsuario:      string);
    procedure ConfigurarEstructuraLineas;
    procedure ConfigurarEstructuraCabecera;
    function GetTipoIVA(sTipoIVA: string): Currency;
    function CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
//    function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
    procedure CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                        const AEmpresa, ACliente,
                                        AArticulo, ASku, AUsuario: string;
                                        APrecioVenta, AAnticipo: Currency;
                                        const AAlmacenOrigen,
                                              AAlmacenDestino: string;
                                        ACantidad: Double;
                                        ATipoIVA: string;
                                        APorcIVA: Currency;
                                        AEsImpIncl: string;
                                        const ACaja, ANumOperacion: string;
                                        AFechaOperacion: TDateTime;
                                        out IdGenerado:string);
    procedure CerrarDepositoCliente(QryTrx: TUniQuery;
                                    const AIdDeposito, AEmpresa,
                                          AAlmacen, ACaja,
                                          AUsuario: string);
    procedure AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                       const AIdDeposito, AEmpresa,
                                             AAlmacen, ACaja,
                                             AUsuario: string;
                                       ANuevoAbono: Currency);
    procedure InsertarCabeceraFactura(
            QryTrx:          TUniQuery;
            // — identificación —
            const ASerie:    string;
            const ANro:      string;
            AFecha:          TDateTime;
            // 'SIMPLIFICADA', 'NORMAL', 'RECTIFICATIVA'
            const ATipo:     string;
            const AFase:     string;   // 'BORRADOR', 'VERIFACTU_OK', etc.
            // — empresa emisora —
            const AEmpresa,
                  ARazonSocialEmp,
                  ANifEmp,
                  AMovilEmp,
                  AEmailEmp,
                  ADireccion1Emp,
                  ADireccion2Emp,
                  APoblacionEmp,
                  AProvinciaEmp,
                  ACPostalEmp,
                  ACodigoPaisEmp,
                  ANombrePaisEmp: string;
            AEsRetencionesEmp:    string;   // 'S'/'N'
            AGrupoZonaIvaEmp:     string;
            // — cliente —
            const ACliente,
                  ARazonSocialCli,
                  ANifCli,
                  AMovilCli,
                  AEmailCli,
                  ADireccion1Cli,
                  ADireccion2Cli,
                  APoblacionCli,
                  AProvinciaCli,
                  ACPostalCli,
                  ACodigoPaisCli,
                  ANombrePaisCli: string;
            const ACodigoOficinaContable,
                  ACodigoOrganoGestor,
                  ACodigoUnidadTramitadora: string;
            const ACodigoIva,
                  ATarifa:       string;
            AEsIvaRecargo,
            AEsIvaExento,
            AEsImpInclTarifa:    string;   // 'S'/'N'
            // — totales fiscales —
            APorcIvaN,  ATotalIvaN,  APorcReN,  ATotalReN,  ABaseIN:   Currency;
            APorcIvaR,  ATotalIvaR,  APorcReR,  ATotalReR,  ABaseIR:   Currency;
            APorcIvaS,  ATotalIvaS,  APorcReS,  ATotalReS,  ABaseIS:   Currency;
            APorcIvaE,  ATotalIvaE,  APorcReE,  ATotalReE,  ABaseIE:   Currency;
            ATotalBases,
            ATotalImpuestos,
            ATotalRetencion,
            APorcRetencion,
            ATotalLiquido:       Currency;
            const AFormaPago:    string;
            // — referencias —
            const AComentarios:  string;
            const ASeriAbono,
                  ANroAbono:     string;   // solo en rectificativas
            // — caja —
            const AAlmacen,
                  ACaja,
                  ACajero:       string;
            ANumOperacion:       string;
            const AUsuario:      string);
    procedure TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                DineroEntregado: Currency);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const APreviewTicket: IPreviewTicket); reintroduce;
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure AsignarRepositorioTicketsCaja(
      const ARepositorio: TRepositoriosTicketsCaja);
    property IdentidadSesion: TIdentidadSesion read GetIdentidadSesion;
    procedure CargarDepositosCliente(const ACodigoCliente: string);
    function GenerarSkuFinal(ArticuloBase: string): string;
    procedure MarcarValeComoCanjeado(QryTrx:           TUniQuery;
                                     const ACodigoVale: string;
                                     const AEmpresa:    string;
                                     const ACodigoAlmacen: string;
                                     const ACodigoCaja:    string;
                                     const ANumOperacion:  string;
                                     const ASerie:         string;
                                     const ANumFactura:    string;
                                     AImporteRedimido:     Currency);
    function BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                  var LabelDestino: String):Boolean;
    function GetTarifaDefault : string;
    // ATipoFactura: 'SIMPLIFICADA' (ticket) o 'NORMAL' (factura A4 del
    // botón F8). AFechaFactura > 0 sustituye la fecha del documento.
    function GrabarFacturaSimplificada(const AEmpresa,
                                       AAlmacen,
                                       ACaja,
                                       ASerieElegida: string;
                                     DatosCobro: TDatosFaseCobro;
                                     SerieGenerada: string;
                                     out NumeroGenerado: String;
                                     out ValeGenerado:String;
                                     const ATipoFactura: string =
                                                          'SIMPLIFICADA';
                                     AFechaFactura: TDateTime = 0;
                                     AFechaOperacion: TDateTime = 0;
                                     const ANumeroManual: string = '';
                                     ATipoRectificativa:
                                       TTipoRectificativaCaja = trcNinguna;
                                     const ASerieRectificada: string = '';
                                     const ANumeroRectificado: string = '';
                                     ATratamientoMovimientos:
                                       TTratamientoMovimientosRectificativa =
                                         tmrMantenerOriginales;
                                     const AMotivoDevolucion: string = '';
                                     const ASerieOrigenDevolucion:
                                       string = '';
                                     const ANumeroOrigenDevolucion:
                                       string = '';
                                     const AEmpresaOrigenDevolucion:
                                       string = '';
                                     const AAlmacenOrigenDevolucion:
                                       string = ''):
                                       Boolean;
    property OnUpdateTotal: TOnUpdateTotalEvent read FOnUpdateTotal
                                                write FOnUpdateTotal;
    property OnRellenarArticulo:  TRellenarArticuloEvent
                                  read FOnRellenarArticulo
                                  write FOnRellenarArticulo;
    property OnRellenarAtributos: TRellenarAtributosEvent
                                  read FOnRellenarAtributos
                                  write FOnRellenarAtributos;
    property OnRecalcularLineas: TRecalcularLineasEvent
                                 read FOnRecalcularLineas
                                 write FOnRecalcularLineas;
    property UltSerieFacturaGrabada:  string read FUltSerieFacGrabada;
    property UltNumeroFacturaGrabada: string read FUltNumeroFacGrabada;
    function SiguienteOpCaja(AEmpresa,
                             AAlmacen,
                             ACaja,
                             AEmpleado: string): string;
    // Mayor FECHA_FAC ya emitida en la serie (0 si aun no tiene tickets).
    // Soporta el control de fecha por serie (grabacion y fase de cobro).
    class function FechaUltimoTicketSerie(
                            AConexion: TUniConnection;
                            const AEmpresa, ASerie: string): TDateTime;
    procedure InsertarOperacionCaja(
                        QryTrx:          TUniQuery;
                        const AEmpresa:  string;
                        const AAlmacen:  string;
                        const ACaja:     string;
                        ANumOperacion:   string;
                        const ATipoOp:   string;
                        AImporte:        Currency;
                        const AEmpleado: string;
                        AFechaOperacion: TDateTime = 0;
                        const ANroFactura:       string = '';
                        const ASerieFactura:     string = '';
                        const ACliente:          string = '';
                        const AConcepto:         string = '';
                        const ASerieOrigen:      string = '';
                        const ANroOrigen:        string = '';
                        const AMotivoDevolucion: string = '';
                        const AEmpresaContra:    string = '';
                        const AAlmContra:        string = '';
                        const AEsTraspaso:       string = 'N';
                        const AIdDeposito:       string = '');
    procedure InsertarPagoCaja(
                        QryTrx:           TUniQuery;
                        const AEmpresa:   string;
                        const AAlmacen:   string;
                        const ACaja:      string;
                        const ASerie:     string;
                        ANumOperacion:    string;
                        ANumLinea:        Integer;
                        const AFormaP:    string;
                        AImporteEntregado: Currency;
                        AImporteCambio:   Currency;
                        const ADivisa:       string   = '';
                        const ARedBlockchain:string   = '';
                        AFactorCambio:       Double   = 1;
                        AImporteDivisa:      Double   = 0;
                        const AReferencia:   string   = '';
                        const AObservaciones:string   = '');
  end;

  function LeerCabecera(cdsCabecera:TDataset): TDatosCabeceraFactura;
  function LeerLineaActual(cdsLineas:TDataset): TDatosLineaFactura;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses UniDataValoresAutomaticosRepositorio,
     UniDataAlmacenesEmpresaRepositorio,
     inLibDevExp,
     inLibFacturas,
     inLibVerifactu,
     inLibVerifactuCola,
     inLibFaseCobroCalculo,
     inLibEmisionFiscalIntf,
     inLibEmisionFiscal,
     UniDataVerifactuColaRepositorio,
     inLibGenerarTicketBD,
     UniDataTicketsCajaRepositorio,
     UniDataFacturasLecturas,
     inLibDocumentoFiscal,
     inLibLicenciaAplicacion,
     UniDataLicenciaAplicacionRepositorio,
     inLibRectificativas,
     inLibEAN13,
     inLibMsgCaja, inLibMsgFacturas;

{$R *.dfm}

type
  TLineaTraspasoDevolucion = record
    Sku: string;
    Articulo: string;
    Cantidad: Double;
  end;
  TGrabacionFacturaCaja = class
  private
    FDataModule: TdmCajaOpe;
    FServicioEmisionFiscal: IServicioEmisionFiscal;
    FDatosCobro: TDatosFaseCobro;
    FQuery: TUniQuery;
    FCabecera: TDatosCabeceraFactura;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FSerieElegida: string;
    FSerieGenerada: string;
    FTipoFactura: string;
    FNumeroManual: string;
    FSerieRectificada: string;
    FNumeroRectificado: string;
    FFechaFactura: TDateTime;
    FFechaOperacion: TDateTime;
    FTipoRectificativa: TTipoRectificativaCaja;
    FTratamientoMovimientos:
      TTratamientoMovimientosRectificativa;
    FUsuario: string;
    FAlmacenDeposito: string;
    FNumeroFactura: string;
    FNumeroOperacion: string;
    FValeGenerado: string;
    FConceptoOperacion: string;
    FTipoRectificativaFiscal: string;
    FRequiereFactura: Boolean;
    FGenerarMovimientos: Boolean;
    FTransaccionActiva: Boolean;
    FTotalVentasNormales: Currency;
    FTotalDevolucionesNormales: Currency;
    FNumeroLineaPago: Integer;
    // Devoluciones: motivo, ticket de origen y traspaso automático
    FMotivoDevolucion: string;
    FSerieOrigenDevolucion: string;
    FNumeroOrigenDevolucion: string;
    FEmpresaOrigenDevolucion: string;
    FAlmacenOrigenDevolucion: string;
    FLineasTraspasoDev: TArray<TLineaTraspasoDevolucion>;
    procedure CargarContexto;
    function OperacionTieneNovedad: Boolean;
    procedure AtenderOperacionSinNovedad;
    procedure DeterminarSiRequiereFactura;
    procedure ValidarSolicitud;
    procedure AjustarCobroParcial;
    procedure IniciarTransaccion;
    function ObtenerNumeroFactura: string;
    procedure CrearFacturaSiProcede;
    procedure InsertarLineaAnticipo(
      const ALinea: TDatosLineaFactura;
      AImporte: Currency);
    procedure ProcesarAnticipoPrevio(
      const ALinea: TDatosLineaFactura);
    procedure ProcesarNuevoDeposito(
      const ALinea: TDatosLineaFactura);
    procedure ProcesarVenta(
      const ALinea: TDatosLineaFactura);
    procedure ProcesarLineas;
    procedure SincronizarContadorLineas;
    procedure RegistrarTotalesVenta;
    procedure RegistrarFiscalmente;
    procedure RegistrarFormasPago;
    procedure RegistrarValesRecogidos;
    procedure EmitirVale;
    function HayDepositosPendientes: Boolean;
    procedure ConfirmarTransaccion;
    procedure ImprimirDocumentosDeposito;
    procedure LimpiarLineasSinImporte;
    procedure RevertirTransaccion;
    function EsDevolucionOtraTienda: Boolean;
    procedure GenerarCodigoBarrasTicket;
    procedure RegistrarLineaTraspasoDevolucion(
      const ALinea: TDatosLineaFactura);
    function ObtenerSerieDocumentoTraspaso(
      const AEmpresa, AAlmacen, ATipoDoc: string): string;
    function ObtenerCosteMedioSkuAlmacen(
      const ASku, AAlmacen: string): Currency;
    procedure GenerarTraspasoAutomaticoDevolucion;
  public
    constructor Create(
      ADataModule: TdmCajaOpe;
      ADatosCobro: TDatosFaseCobro;
      const AEmpresa, AAlmacen, ACaja, ASerieElegida,
      ASerieGenerada, ATipoFactura: string;
      AFechaFactura, AFechaOperacion: TDateTime;
      const ANumeroManual: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      const ASerieRectificada, ANumeroRectificado: string;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa;
      const AMotivoDevolucion: string = '';
      const ASerieOrigenDevolucion: string = '';
      const ANumeroOrigenDevolucion: string = '';
      const AEmpresaOrigenDevolucion: string = '';
      const AAlmacenOrigenDevolucion: string = '');
    destructor Destroy; override;
    function Ejecutar(
      out ANumeroGenerado, AValeGenerado: string): Boolean;
  end;

constructor TdmCajaOpe.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket);
var
  ProveedorContexto: IProveedorContextoSesion;
begin
  if not Assigned(AParametrosApp) then
    raise Exception.Create(SErrorParametrosAplicacionCajaNoConfigurados);
  if not Assigned(AParametrosCaja) then
    raise Exception.Create(SErrorParametrosModuloCajaNoConfigurados);
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FPreviewTicket := APreviewTicket;
  FRepositorioTicketsCaja :=
    CrearRepositoriosTicketsCaja(AConexion);
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, ProveedorContexto) then
    FContextoSesion := ProveedorContexto.ContextoSesion;
  inherited Create(AOwner);
end;

procedure TdmCajaOpe.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TdmCajaOpe.AsignarRepositorioTicketsCaja(
  const ARepositorio: TRepositoriosTicketsCaja);
begin
  if Assigned(ARepositorio.Tickets) and
     Assigned(ARepositorio.Resguardos) and
     Assigned(ARepositorio.Recordatorios) then
    FRepositorioTicketsCaja := ARepositorio;
end;

function TdmCajaOpe.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function LeerCabecera(cdsCabecera:TDataset): TDatosCabeceraFactura;
begin
  Result := inLibCajaDatosFactura.LeerCabeceraFactura(cdsCabecera);
end;

function LeerLineaActual(cdsLineas:TDataset): TDatosLineaFactura;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := cdsLineas.FieldByName(ANombre);
  end;
begin
  Result.Linea               := FieldByName('LINEA_FACLIN').AsString;
    Result.Articulo            := FieldByName('CODIGO_ART_FACLIN').AsString;
    Result.Sku                 := FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
    Result.Descripcion := FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
    // Result.DescripcionVariacion:=
    // FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString;
    Result.Familia             := FieldByName('CODIGO_FAM_FACLIN').AsString;
    Result.NombreFamilia       := FieldByName('NOMBRE_FAM_FACLIN').AsString;
    Result.TipoArticulo        := FieldByName('TIPO_ARTICULO_FACLIN').AsString;
    Result.TipoCantidad        :=
      FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
    Result.Cantidad            := FieldByName('CANTIDAD_FACLIN').AsFloat;
    Result.Tarifa              := FieldByName('CODIGO_TAR_FACLIN').AsString;
    Result.EsImpIncl := FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString;
    Result.PrecioSalida := FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency;
    Result.PorcDto             := FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat;
    Result.PrecioDto           := FieldByName('PRECIO_DTO_FACLIN').AsCurrency;
    Result.PrecioSIva          :=
      FieldByName('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency;
    Result.PrecioCIva          :=
      FieldByName('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency;
    Result.TipoIva := FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString;
    Result.PorcIva             := FieldByName('PORCENTAJE_IVA_FACLIN').AsFloat;
    Result.TotalSIva := FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency;
    Result.TotalCIva           := FieldByName('TOTAL_FACLIN').AsCurrency;
    Result.Vendedor := FieldByName('CODIGO_VENDEDOR_FACLIN').AsString;
    Result.VieneDeDeposito     := FieldByName('VIENE_DE_DEPOSITO').AsString;
    Result.AccionDeposito      := FieldByName('ACCION_DEPOSITO').AsString;
    Result.PrecioOriginalDep   := FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
    Result.AnticipoPrevio      := FieldByName('ANTICIPO_PREVIO').AsCurrency;
  Result.IdDeposito          := FieldByName('ID_DEPOSITO_DEP').AsString;
end;

// =============================================================================
// MÓDULO: GESTIÓN DE CUENTAS Y DEPÓSITOS DE CLIENTES
// =============================================================================
procedure TdmCajaOpe.CargarDepositosCliente(const ACodigoCliente: string);
var
  QryDep: TUniQuery;
  Sku, Articulo, IdDeposito: string;
  PrecioOriginal, AnticipoDado, AnticipoSinIVA: Currency;
  CantidadPendiente: Double;
  TipoIVA, EsImpIncl, Descripcion: string;
  PorcIVA: Currency;
  FechaCreacion: TDateTime;
  Ubicacion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  Ubicacion := FContextoSesion.Ubicacion;
  QryDep := TUniQuery.Create(nil);
  try
    QryDep.Connection := FConexion;
    QryDep.SQL.Text :=
        'SELECT d.ID_DEPOSITO_DEP, '           +
        '       d.CODIGO_ART_DEP, '       +
        '       d.CODIGO_UNIDAD_DEP, '         +
        '       d.CANTIDAD_PENDIENTE_DEP, '    +
        '       d.PRECIO_VENTA_DEP, '          +
        '       d.IMPORTE_ANTICIPO_DEP, '      +
        '       d.TIPO_IVA_DEP, '              +
        '       d.PORCENTAJE_IVA_DEP, '            +
        '       d.ESIMP_INCL_DEP, '            +
        '       d.FECHA_CREACION_DEP, '        +
        '       a.DESCRIPCION_ART '       +  // <-- join directo
        '  FROM fza_depositos_cliente d '      +
        '  LEFT JOIN fza_articulos a '         +
        '    ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
        ' WHERE d.CODIGO_CLI_DEP = :CLI '  +
        '   AND d.CODIGO_EMP_DEP = :EMPRESA ' +
        '   AND d.CODIGO_ALM_DEP = :ALMACEN ' +
        '   AND d.CODIGO_CAJA_DEP = :CAJA ' +
        '   AND d.ESTADO_DEP = ''PENDIENTE''';
    QryDep.ParamByName('CLI').AsString := ACodigoCliente;
    QryDep.ParamByName('EMPRESA').AsString := Ubicacion.Empresa;
    QryDep.ParamByName('ALMACEN').AsString := Ubicacion.Almacen;
    QryDep.ParamByName('CAJA').AsString := Ubicacion.Caja;
    QryDep.Open;
    if not QryDep.IsEmpty then
    begin
      cdsLineas.DisableControls;
      try
        while not QryDep.Eof do
        begin
          IdDeposito := QryDep.FieldByName('ID_DEPOSITO_DEP').AsString;
        Articulo          := QryDep.FieldByName('CODIGO_ART_DEP').AsString;
        Sku               := QryDep.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        CantidadPendiente :=
          QryDep.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
        PrecioOriginal    := QryDep.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        AnticipoDado := QryDep.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
        TipoIVA           := QryDep.FieldByName('TIPO_IVA_DEP').AsString;
        PorcIVA := QryDep.FieldByName('PORCENTAJE_IVA_DEP').AsCurrency;
        EsImpIncl         := QryDep.FieldByName('ESIMP_INCL_DEP').AsString;
        Descripcion       := QryDep.FieldByName('DESCRIPCION_ART').AsString;
        FechaCreacion := QryDep.FieldByName('FECHA_CREACION_DEP').AsDateTime;
        // ── LÍNEA 1: LA PRENDA ───────────────────────────────────────────
        // *** SIN FOnRellenarArticulo ni FOnRellenarAtributos ***
        // Todo viene del SELECT, cero queries adicionales por fila
        cdsLineas.Append;
        cdsLineas.FieldByName('ID_DEPOSITO_DEP').AsString := IdDeposito;
        cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString      := Articulo;
        cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString        := Sku;
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
          Descripcion;
        cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := CantidadPendiente;
        cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString := 'S';
        cdsLineas.FieldByName('FECHA_DEPOSITO_DEP').AsString :=
          FormatDateTime('dd/mm/yyyy hh:nn', FechaCreacion);
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'COBRAR';
        cdsLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString := TipoIVA;
        cdsLineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency := PorcIVA;
        cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString := EsImpIncl;
        cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency        :=
          PrecioOriginal;
        cdsLineas.FieldByName('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency :=
          PrecioOriginal;
        if PorcIVA = 0 then
          cdsLineas.FieldByName(
            'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := PrecioOriginal
        else
          cdsLineas.FieldByName(
            'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
            PrecioOriginal / (1 + (PorcIVA / 100));
        cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat            := 0;
        cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency         := 0;
        cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency              :=
          PrecioOriginal * CantidadPendiente;
        cdsLineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency          :=
        cdsLineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency * CantidadPendiente;
        cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency              :=
          PrecioOriginal;
        cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency := AnticipoDado;
        cdsLineas.Post;
        // ── LÍNEA 2: ABONO DEL ANTICIPO (negativo) ───────────────────────
        if AnticipoDado > 0 then
        begin
          if PorcIVA = 0 then
            AnticipoSinIVA := AnticipoDado
          else
            AnticipoSinIVA := AnticipoDado / (1 + (PorcIVA / 100));
          cdsLineas.Append;
          cdsLineas.FieldByName('ID_DEPOSITO_DEP').AsString := IdDeposito;
          cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString := 'ACUENTA';
          cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := 'ACUENTA';
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString       :=
            'Abono a cuenta ' + Sku;
          cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString := 'A';
          cdsLineas.FieldByName('FECHA_DEPOSITO_DEP').AsString :=
            FormatDateTime('dd/mm/yyyy hh:nn', FechaCreacion);
          cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := -1;
          cdsLineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString := 'SERVICIO';
          cdsLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString := TipoIVA;
          cdsLineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency := PorcIVA;
          cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString          :=
            EsImpIncl;
          cdsLineas.FieldByName(
            'PRECIO_SALIDA_FACLIN').AsCurrency              := AnticipoDado;
          cdsLineas.FieldByName(
            'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := AnticipoDado;
          cdsLineas.FieldByName(
            'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := AnticipoSinIVA;
          cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency := -AnticipoDado;
          cdsLineas.FieldByName(
            'TOTAL_FAC_SIVA_FACLIN').AsCurrency := -AnticipoSinIVA;
          cdsLineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString     :=
            'Uds';
          cdsLineas.Post;
        end;
          QryDep.Next;
        end;
      finally
        cdsLineas.EnableControls;
      end;
      // Recalculo una sola vez al final, fuera del bucle.
      if Assigned(FOnRecalcularLineas) then
        FOnRecalcularLineas;
    end;
  finally
    FreeAndNil(QryDep);
  end;
end;

procedure TdmCajaOpe.CerrarDepositoCliente(QryTrx: TUniQuery;
                                           const AIdDeposito,
                                                 AEmpresa,
                                                 AAlmacen,
                                                 ACaja,
                                                 AUsuario: string);
var
  Consulta: TUniQuery;
  Cliente: string;
  DeudaAnterior: Currency;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := QryTrx.Connection;
    Consulta.SQL.Text :=
      'SELECT CODIGO_CLI_DEP, ' +
      '       (PRECIO_VENTA_DEP * ' +
      '        COALESCE(CANTIDAD_PENDIENTE_DEP, 1)) - ' +
      '       COALESCE(IMPORTE_ANTICIPO_DEP, 0) AS DEUDA_ANTERIOR ' +
      'FROM fza_depositos_cliente ' +
      'WHERE ID_DEPOSITO_DEP = :ID ' +
      'AND CODIGO_EMP_DEP = :EMPRESA ' +
      'AND CODIGO_ALM_DEP = :ALMACEN ' +
      'AND CODIGO_CAJA_DEP = :CAJA ' +
      'AND ESTADO_DEP = ''PENDIENTE'' ' +
      'FOR UPDATE';
    Consulta.ParamByName('ID').AsString := AIdDeposito;
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      Cliente := Consulta.FieldByName('CODIGO_CLI_DEP').AsString;
      DeudaAnterior :=
        Consulta.FieldByName('DEUDA_ANTERIOR').AsCurrency;
      Consulta.Close;
      Consulta.SQL.Text :=
        'UPDATE fza_depositos_cliente ' +
        'SET ESTADO_DEP = ''CERRADO'', ' +
        '    USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE ID_DEPOSITO_DEP = :ID ' +
        'AND CODIGO_EMP_DEP = :EMPRESA ' +
        'AND CODIGO_ALM_DEP = :ALMACEN ' +
        'AND CODIGO_CAJA_DEP = :CAJA ' +
        'AND ESTADO_DEP = ''PENDIENTE''';
      Consulta.ParamByName('USUARIO').AsString := AUsuario;
      Consulta.ParamByName('ID').AsString := AIdDeposito;
      Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
      Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
      Consulta.ParamByName('CAJA').AsString := ACaja;
      Consulta.Execute;
      Consulta.SQL.Text :=
        'UPDATE fza_clientes ' +
        'SET TOTAL_DEUDA_CLI = COALESCE(TOTAL_DEUDA_CLI, 0) - :DEUDA ' +
        'WHERE CODIGO_CLI_CLI = :CLIENTE';
      Consulta.ParamByName('DEUDA').AsCurrency := DeudaAnterior;
      Consulta.ParamByName('CLIENTE').AsString := Cliente;
      Consulta.Execute;
    end
    else
      raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  finally
    FreeAndNil(Consulta);
  end;
end;

function LeerLineasCobroParcial(
  ALineas: TDataSet): TArray<TLineaCobroParcial>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  ALineas.First;
  while not ALineas.Eof do
  begin
    i := Length(Result);
    SetLength(Result, i + 1);
    Result[i].IdDeposito :=
      ALineas.FieldByName('ID_DEPOSITO_DEP').AsString;
    Result[i].VieneDeDeposito :=
      ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
    Result[i].AccionDeposito :=
      ALineas.FieldByName('ACCION_DEPOSITO').AsString;
    Result[i].Descripcion :=
      ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
    Result[i].Total :=
      ALineas.FieldByName('TOTAL_FACLIN').AsCurrency;
    Result[i].AnticipoPrevio :=
      ALineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
    Result[i].PorcentajeIva :=
      ALineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency;
    ALineas.Next;
  end;
end;

procedure EscribirLineaCobroParcial(
  ALineas: TDataSet;
  const ALinea: TLineaCobroParcial);
begin
  ALineas.Edit;
  ALineas.FieldByName('ACCION_DEPOSITO').AsString :=
    ALinea.AccionDeposito;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    ALinea.Descripcion;
  ALineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency :=
    ALinea.PrecioOriginal;
  ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
    ALinea.PrecioSalida;
  ALineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency :=
    ALinea.PrecioConIva;
  ALineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
    ALinea.PrecioSinIva;
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 1;
  ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
  ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('TOTAL_FACLIN').AsCurrency := ALinea.Total;
  ALineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency :=
    ALinea.TotalSinIva;
  ALineas.Post;
end;

procedure AplicarLineasCobroParcial(
  ADataSet: TDataSet;
  const ALineas: TArray<TLineaCobroParcial>);
var
  i: Integer;
begin
  i := 0;
  ADataSet.First;
  while (not ADataSet.Eof) and (i <= High(ALineas)) do
  begin
    if ALineas[i].Eliminar then
      ADataSet.Delete
    else
    begin
      if ALineas[i].Modificada then
        EscribirLineaCobroParcial(ADataSet, ALineas[i]);
      ADataSet.Next;
    end;
    Inc(i);
  end;
end;

procedure TdmCajaOpe.TransformarLineasParaCobroParcial(
  cdsLineas: TDataSet;
  DineroEntregado: Currency);
var
  oLineas: TArray<TLineaCobroParcial>;
begin
  cdsLineas.DisableControls;
  try
    oLineas := LeerLineasCobroParcial(cdsLineas);
    TCalculadorCobroParcial.Transformar(oLineas, DineroEntregado);
    AplicarLineasCobroParcial(cdsLineas, oLineas);
  finally
    cdsLineas.EnableControls;
  end;
end;

function FechaCajaConHora(AFechaCaja: TDateTime): TDateTime;
begin
  if AFechaCaja > 0 then
    Result := AFechaCaja
  else
    Result := Now;
end;

procedure TdmCajaOpe.InsertarMovimientoAlmacen(
                          QryTrx:     TUniQuery;
                          ATipoDoc:   string;
                          ASerie:     string;
                          ANro:       string;
                          ALinea:     string;
                          AEmpresa:   string;
                          AAlmacen:   string;
                          ACaja:      string;
                          AAlmacenContra: string; // <--- AÑADIDO AQUÍ
                          ATipoMov:   string;
                          ASku:       string;
                          ACantidad:  Double;
                          ACoste:     Currency;
                          AUsuario:   string;
                          const AAlmacenDoc: string = '';
                          const ANumOperacion: string = '';
                          const ACodCliente:string = '';
                          const ACodArticulo:string='';
                          AFechaMovimiento: TDateTime = 0;
                          const ANumeroMovimiento: string = '');
var
  uspMov: TUniStoredProc;
  QryFecha: TUniQuery;
  sNumeroMov: string;
begin
  sNumeroMov := Trim(ANumeroMovimiento);
  if sNumeroMov = '' then
    sNumeroMov := ObtenerSiguienteContador(
      FConexion,
      'MV',
      IdentidadSesion.Usuario);
  uspMov := TUniStoredProc.Create(nil);
  try
    uspMov.Connection := QryTrx.Connection;
    uspMov.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    uspMov.Prepare;
    uspMov.ParamByName('p_NUMERO_MOV').AsString              := sNumeroMov;
    uspMov.ParamByName('p_TIPO_DOC_MOV').AsString            := ATipoDoc;
    uspMov.ParamByName('p_SERIE_DOC_MOV').AsString           := ASerie;
    uspMov.ParamByName('p_NRO_DOC_MOV').AsString             := ANro;
    uspMov.ParamByName('p_LINEA_MOV').AsString               := ALinea;
    uspMov.ParamByName('p_CODIGO_EMPRESA_MOV').AsString      := AEmpresa;
    uspMov.ParamByName('p_CODIGO_ALMACEN_MOV').AsString      := AAlmacen;
    uspMov.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString     := ACaja;
    if Trim(AAlmacenContra) = '' then
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
    else
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
                                                                 AAlmacenContra;
    uspMov.ParamByName('p_CODIGO_UNIDAD_MOV').AsString       := ASku;
    uspMov.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString     := ATipoMov;
    uspMov.ParamByName('p_CANTIDAD_MOV').AsFloat             := Abs(ACantidad);
    uspMov.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency      := ACoste;
    uspMov.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency       :=
                                                        ACoste * Abs(ACantidad);
    uspMov.ParamByName('p_USUARIO').AsString                 := AUsuario;
    uspMov.ParamByName('p_ALMACEN_DOC').AsString             := AAlmacenDoc;
    uspMov.ParamByName('p_NUMOP_DOC').AsString               := ANumOperacion;
    uspMov.ParamByName('p_CODCLIENTE').AsString              := ACodCliente;
    uspMov.ParamByName('p_CODARTICULO').AsString             := ACodArticulo;
    uspMov.Execute;
    if AFechaMovimiento > 0 then
    begin
      QryFecha := TUniQuery.Create(nil);
      try
        QryFecha.Connection := QryTrx.Connection;
        QryFecha.SQL.Text :=
          'UPDATE fza_movimientos_almacen ' +
          '   SET FECHA_MOV = :FECHA ' +
          ' WHERE NUMERO_MOV = :NUMERO';
        QryFecha.ParamByName('FECHA').AsDateTime :=
          FechaCajaConHora(AFechaMovimiento);
        QryFecha.ParamByName('NUMERO').AsString := sNumeroMov;
        QryFecha.Execute;
      finally
        FreeAndNil(QryFecha);
      end;
    end;
  finally
    FreeAndNil(uspMov);
  end;
end;

procedure TdmCajaOpe.AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                              const AIdDeposito,
                                                    AEmpresa,
                                                    AAlmacen,
                                                    ACaja,
                                                    AUsuario: string;
                                              ANuevoAbono: Currency);
var
  Consulta: TUniQuery;
  Cliente: string;
begin
  if ANuevoAbono > 0 then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := QryTrx.Connection;
      Consulta.SQL.Text :=
        'SELECT CODIGO_CLI_DEP ' +
        'FROM fza_depositos_cliente ' +
        'WHERE ID_DEPOSITO_DEP = :ID ' +
        'AND CODIGO_EMP_DEP = :EMPRESA ' +
        'AND CODIGO_ALM_DEP = :ALMACEN ' +
        'AND CODIGO_CAJA_DEP = :CAJA ' +
        'AND ESTADO_DEP = ''PENDIENTE'' ' +
        'FOR UPDATE';
      Consulta.ParamByName('ID').AsString := AIdDeposito;
      Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
      Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
      Consulta.ParamByName('CAJA').AsString := ACaja;
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        Cliente := Consulta.FieldByName('CODIGO_CLI_DEP').AsString;
        Consulta.Close;
        Consulta.SQL.Text :=
          'UPDATE fza_depositos_cliente ' +
          'SET IMPORTE_ANTICIPO_DEP = ' +
          '    COALESCE(IMPORTE_ANTICIPO_DEP, 0) + :ABONO, ' +
          '    USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
          'WHERE ID_DEPOSITO_DEP = :ID ' +
          'AND CODIGO_EMP_DEP = :EMPRESA ' +
          'AND CODIGO_ALM_DEP = :ALMACEN ' +
          'AND CODIGO_CAJA_DEP = :CAJA ' +
          'AND ESTADO_DEP = ''PENDIENTE''';
        Consulta.ParamByName('ABONO').AsCurrency := ANuevoAbono;
        Consulta.ParamByName('USUARIO').AsString := AUsuario;
        Consulta.ParamByName('ID').AsString := AIdDeposito;
        Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
        Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
        Consulta.ParamByName('CAJA').AsString := ACaja;
        Consulta.Execute;
        Consulta.SQL.Text :=
          'UPDATE fza_clientes ' +
          'SET TOTAL_DEUDA_CLI = COALESCE(TOTAL_DEUDA_CLI, 0) - :ABONO ' +
          'WHERE CODIGO_CLI_CLI = :CLIENTE';
        Consulta.ParamByName('ABONO').AsCurrency := ANuevoAbono;
        Consulta.ParamByName('CLIENTE').AsString := Cliente;
        Consulta.Execute;
      end
      else
        raise Exception.Create(SErrorOperacionCajaNoEncontrada);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TdmCajaOpe.CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                               const AEmpresa,
                                                     ACliente,
                                                     AArticulo,
                                                     ASku,
                                                     AUsuario:    string;
                                               APrecioVenta,
                                               AAnticipo:         Currency;
                                               const AAlmacenOrigen,
                                                     AAlmacenDestino: string;
                                               ACantidad:         Double;
                                               ATipoIVA:          string;
                                               APorcIVA:          Currency;
                                               AEsImpIncl:        string;
                                               const ACaja,
                                               ANumOperacion: string;
                                               AFechaOperacion: TDateTime;
                                               out IdGenerado:string);
var
  NuevoIdDep: string;
  uspDep: TUniStoredProc;
begin
  InsertarMovimientoAlmacen(QryTrx,
                            'TR',
                            '',
                            '',
                            '0001',
                            AEmpresa,
                            AAlmacenOrigen,
                            ACaja,
                            AAlmacenDestino,
                            'S',
                            ASku,
                            ACantidad,
                            0,
                            AUsuario,
                            AAlmacenOrigen,
                            ANumOperacion,
                            ACliente,
                            AArticulo,
                            AFechaOperacion);
  // 1b. Entrada al almacén depósito
  InsertarMovimientoAlmacen(QryTrx,
                            'TR',
                            '',
                            '',
                            '0002',
                            AEmpresa,
                            AAlmacenDestino,
                            ACaja,
                            AAlmacenOrigen,
                            'E',
                            ASku,
                            ACantidad,
                            0,
                            AUsuario,
                            AAlmacenOrigen,
                            ANumOperacion,
                            ACliente,
                            AArticulo,
                            AFechaOperacion);
  // 2. Generar ID único para el depósito (lógica original)
  NuevoIdDep := 'DP' + FormatDateTime('yymmddhhnnsszzz', Now) +
                RightStr(ASku, 3);  // máx 20 chars
  NuevoIdDep := Copy(NuevoIdDep, 1, 20); // Aseguramos longitud máxima
  IdGenerado := NuevoIdDep;
  uspDep := TUniStoredProc.Create(nil);
  try
    // Enganchamos el SP a la misma conexión/transacción que traemos
    uspDep.Connection := QryTrx.Connection;
    uspDep.StoredProcName := 'PRC_FZA_DEPOSITOS_INSERT';
    uspDep.Prepare; // Descarga la estructura de parámetros del servidor
    // Asignamos los parámetros (OJO: Nombres idénticos a los del SP en MySQL)
    uspDep.ParamByName('p_ID_DEP').AsString     := NuevoIdDep;
    uspDep.ParamByName('p_EMP').AsString        := AEmpresa;
    uspDep.ParamByName('p_ALM_DEP').AsString    := AAlmacenOrigen;
    uspDep.ParamByName('p_CLI').AsString        := ACliente;
    uspDep.ParamByName('p_ART').AsString        := AArticulo;
    uspDep.ParamByName('p_SKU').AsString        := ASku;
    uspDep.ParamByName('p_PRECIO').AsCurrency   := APrecioVenta;
    uspDep.ParamByName('p_CANTIDAD').AsFloat    := ACantidad;
    uspDep.ParamByName('p_ANTICIPO').AsCurrency := AAnticipo;
    uspDep.ParamByName('p_TIPOIVA').AsString    := ATipoIVA;
    uspDep.ParamByName('p_PORCIVA').AsCurrency  := APorcIVA;
    uspDep.ParamByName('p_IMPINCL').AsString    := AEsImpIncl;
    uspDep.ParamByName('p_CAJA').AsString       := ACaja;
    uspDep.ParamByName('p_NUMOP').AsString      := ANumOperacion;
    uspDep.ParamByName('p_USUARIO').AsString    := AUsuario;
    uspDep.Execute;
  finally
    FreeAndNil(uspDep);
  end;
end;

class function TdmCajaOpe.FechaUltimoTicketSerie(
                          AConexion: TUniConnection;
                          const AEmpresa, ASerie: string): TDateTime;
var
  Qry: TUniQuery;
begin
  // Devuelve la mayor fecha de documento ya grabada en la serie indicada.
  // Si la serie todavia no tiene tickets devuelve 0 (no hay restriccion).
  Result := 0;
  if Trim(ASerie) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConexion;
      Qry.SQL.Text :=
        'SELECT MAX(FECHA_FAC) AS ULTIMA_FECHA ' +
        '  FROM fza_facturas ' +
        ' WHERE CODIGO_EMP_FAC = :EMP ' +
        '   AND SERIE_FAC      = :SERIE';
      Qry.ParamByName('EMP').AsString   := AEmpresa;
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.Open;
      if not Qry.Fields[0].IsNull then
        Result := Qry.Fields[0].AsDateTime;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

constructor TGrabacionFacturaCaja.Create(
  ADataModule: TdmCajaOpe;
  ADatosCobro: TDatosFaseCobro;
  const AEmpresa, AAlmacen, ACaja, ASerieElegida,
  ASerieGenerada, ATipoFactura: string;
  AFechaFactura, AFechaOperacion: TDateTime;
  const ANumeroManual: string;
  ATipoRectificativa: TTipoRectificativaCaja;
  const ASerieRectificada, ANumeroRectificado: string;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa;
  const AMotivoDevolucion: string = '';
  const ASerieOrigenDevolucion: string = '';
  const ANumeroOrigenDevolucion: string = '';
  const AEmpresaOrigenDevolucion: string = '';
  const AAlmacenOrigenDevolucion: string = '');
begin
  inherited Create;
  FDataModule := ADataModule;
  FServicioEmisionFiscal := CrearServicioEmisionFiscal(
    FDataModule.FParametrosApp,
    FDataModule.FParametrosCaja,
    FDataModule.FConexion,
    CrearServicioVerifactuColaUniDAC(FDataModule.FConexion));
  FDatosCobro := ADatosCobro;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FSerieElegida := ASerieElegida;
  FSerieGenerada := ASerieGenerada;
  FTipoFactura := ATipoFactura;
  FFechaFactura := AFechaFactura;
  FFechaOperacion := FechaCajaConHora(AFechaOperacion);
  FNumeroManual := ANumeroManual;
  FTipoRectificativa := ATipoRectificativa;
  FSerieRectificada := ASerieRectificada;
  FNumeroRectificado := ANumeroRectificado;
  FTratamientoMovimientos := ATratamientoMovimientos;
  FMotivoDevolucion := AMotivoDevolucion;
  FSerieOrigenDevolucion := ASerieOrigenDevolucion;
  FNumeroOrigenDevolucion := ANumeroOrigenDevolucion;
  FEmpresaOrigenDevolucion := AEmpresaOrigenDevolucion;
  FAlmacenOrigenDevolucion := AAlmacenOrigenDevolucion;
  SetLength(FLineasTraspasoDev, 0);
end;

destructor TGrabacionFacturaCaja.Destroy;
begin
  FServicioEmisionFiscal := nil;
  FreeAndNil(FQuery);
  inherited;
end;

procedure TGrabacionFacturaCaja.CargarContexto;
begin
  FNumeroFactura := '0';
  FNumeroOperacion := '';
  FValeGenerado := '';
  FDataModule.FUltSerieFacGrabada := '';
  FDataModule.FUltNumeroFacGrabada := '';
  FUsuario := FDataModule.cdsCabecera.FieldByName(
    'CODIGO_CAJERO_FAC').AsString;
  case FTipoRectificativa of
    trcDiferencias:
      begin
        FConceptoOperacion := 'Rectificativa por diferencias';
        FTipoRectificativaFiscal := 'I';
      end;
    trcSustitutiva:
      begin
        FConceptoOperacion := 'Rectificativa sustitutiva';
        FTipoRectificativaFiscal := 'S';
      end;
  else
    begin
      FConceptoOperacion := '';
      FTipoRectificativaFiscal := '';
    end;
  end;
  FGenerarMovimientos := DebeGenerarMovimientosRectificativa(
    FTipoRectificativaFiscal,
    FTratamientoMovimientos = tmrReemplazarOriginales);
  if (FConceptoOperacion <> '') and
     (Trim(FSerieRectificada) <> '') and
     (Trim(FNumeroRectificado) <> '') then
    FConceptoOperacion := FConceptoOperacion + ' de ' +
      FSerieRectificada + '\' + FNumeroRectificado;
  FAlmacenDeposito := ObtenerAlmacenDepositoEmpresa(
    FDataModule.FConexion, FEmpresa);
  if FDataModule.cdsCabecera.State in [dsEdit, dsInsert] then
    FDataModule.cdsCabecera.Post;
  if FDataModule.cdsLineas.State in [dsEdit, dsInsert] then
    FDataModule.cdsLineas.Post;
  if FDataModule.cdsLineas.IsEmpty then
    raise Exception.Create(SErrorOperacionCajaSinLineas);
  FCabecera := LeerCabecera(FDataModule.cdsCabecera);
  if FFechaFactura > 0 then
    FCabecera.Fecha := FFechaFactura;
end;

function TGrabacionFacturaCaja.OperacionTieneNovedad: Boolean;
var
  sAccion: string;
begin
  Result := False;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while (not FDataModule.cdsLineas.Eof) and (not Result) do
    begin
      sAccion := Trim(FDataModule.cdsLineas.FieldByName(
        'ACCION_DEPOSITO').AsString);
      Result :=
        (FDatosCobro.ImporteEntregado > 0) or
        FDatosCobro.EsDevolucionEconomica or
        FDatosCobro.TieneArticulosDevueltos or
        (FDatosCobro.ImporteValeEmitido > 0) or
        (sAccion = 'CANCELAR') or
        (sAccion = 'NUEVO_DEP');
      if not Result then
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.AtenderOperacionSinNovedad;
begin
  ImprimirRecordatorio(
    FDataModule.FPreviewTicket,
    FDataModule.FRepositorioTicketsCaja.Recordatorios,
    FDataModule.FContextoSesion.Ubicacion.Empresa,
    FCabecera.CodigoCliente,
    FDataModule.FParametrosCaja.ImpresoraCaja);
end;

procedure TGrabacionFacturaCaja.DeterminarSiRequiereFactura;
var
  sAccion: string;
  dTotalLiquido: Currency;
begin
  FRequiereFactura := False;
  dTotalLiquido := FDataModule.cdsCabecera.FieldByName(
    'TOTAL_LIQUIDO_FAC').AsCurrency;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while (not FDataModule.cdsLineas.Eof) and
          (not FRequiereFactura) do
    begin
      sAccion := Trim(FDataModule.cdsLineas.FieldByName(
        'ACCION_DEPOSITO').AsString);
      FRequiereFactura :=
        (sAccion = '') or
        (sAccion = 'COBRAR') or
        ((sAccion = 'CANCELAR') and (dTotalLiquido <> 0)) or
        (((sAccion = 'NUEVO_DEP') or
          (sAccion = 'AUMENTAR_DEP')) and
         (dTotalLiquido > 0.001));
      if not FRequiereFactura then
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
  FDatosCobro.FRequiereFactura := FRequiereFactura;
end;

procedure TGrabacionFacturaCaja.ValidarSolicitud;
var
  dUltimaFechaSerie: TDateTime;
begin
  if FRequiereFactura and SameText(FTipoFactura, 'NORMAL') then
  begin
    if Trim(FCabecera.RazonSocialCli) = '' then
      raise Exception.Create(
        SErrorRazonSocialClienteFacturaCajaObligatoria);
    if PaisEsEspana(
         FCabecera.CodigoPaisCli, FCabecera.NombrePaisCli) and
       (not DocumentoFiscalValido(FCabecera.NifCli)) then
      raise Exception.Create(
        SErrorDocumentoFiscalClienteCajaNoValido +
        MensajeDocumentoFiscalInvalido(FCabecera.NifCli));
    if PaisEsEspana(
         FCabecera.CodigoPaisEmp, FCabecera.NombrePaisEmp) and
       (not DocumentoFiscalValido(FCabecera.NifEmp)) then
      raise Exception.Create(
        SErrorDocumentoFiscalEmpresaCajaNoValido +
        MensajeDocumentoFiscalInvalido(FCabecera.NifEmp));
  end;
  if FRequiereFactura and (FNumeroManual = '') then
  begin
    dUltimaFechaSerie := TdmCajaOpe.FechaUltimoTicketSerie(
      FDataModule.FConexion, FEmpresa, FSerieElegida);
    if (dUltimaFechaSerie > 0) and
       (Trunc(FCabecera.Fecha) < Trunc(dUltimaFechaSerie)) then
      raise Exception.CreateFmt(
        SErrorFechaTicketSerieNoValida,
        [FSerieElegida,
         FormatDateTime('dd/mm/yyyy', dUltimaFechaSerie),
         FormatDateTime('dd/mm/yyyy', FCabecera.Fecha)]);
  end;
  if FRequiereFactura and
     FDataModule.FParametrosApp.Licencia.Comprobada then
    ValidarLimiteDemoFacturas(
      FDataModule.FConexion,
      FDataModule.FParametrosApp.Licencia.Estado,
      FCabecera.Fecha);
end;

procedure TGrabacionFacturaCaja.AjustarCobroParcial;
begin
  if FDatosCobro.ImporteEntregado <
     FDataModule.cdsCabecera.FieldByName(
       'TOTAL_LIQUIDO_FAC').AsCurrency then
  begin
    FDataModule.TransformarLineasParaCobroParcial(
      FDataModule.cdsLineas, FDatosCobro.ImporteEntregado);
    if not FDataModule.CuadrarFacturaEnMemoria(
      FDataModule.cdsCabecera, FDataModule.cdsLineas) then
      raise Exception.Create(SErrorCuadreCobroParcialCaja);
    FCabecera := LeerCabecera(FDataModule.cdsCabecera);
    if FFechaFactura > 0 then
      FCabecera.Fecha := FFechaFactura;
  end;
end;

procedure TGrabacionFacturaCaja.IniciarTransaccion;
begin
  FDataModule.FConexion.StartTransaction;
  FTransaccionActiva := True;
  FNumeroOperacion := FDataModule.SiguienteOpCaja(
    FEmpresa, FAlmacen, FCaja, FUsuario);
  FQuery := TUniQuery.Create(nil);
  FQuery.Connection := FDataModule.FConexion;
end;

function TGrabacionFacturaCaja.ObtenerNumeroFactura: string;
var
  oStoredProc: TUniStoredProc;
begin
  if FNumeroManual <> '' then
    Result := FNumeroManual
  else
  begin
    oStoredProc := TUniStoredProc.Create(nil);
    try
      oStoredProc.Connection := FDataModule.FConexion;
      oStoredProc.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      oStoredProc.Prepare;
      oStoredProc.ParamByName('pserie').AsString := FSerieGenerada;
      oStoredProc.ParamByName('pTipoDoc').AsString := 'FC';
      oStoredProc.ParamByName(
        'pEMPRESA_CONTADOR').AsString := FEmpresa;
      oStoredProc.ParamByName(
        'pUSUARIOMODIF').AsString := FUsuario;
      oStoredProc.Execute;
      Result := oStoredProc.ParamByName('pcont').AsString;
    finally
      FreeAndNil(oStoredProc);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.CrearFacturaSiProcede;
begin
  if FRequiereFactura then
  begin
    FNumeroFactura := ObtenerNumeroFactura;
    FDatosCobro.TotalesFactura.Cabecera.Edit;
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'SERIE_FAC').AsString := FSerieElegida;
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'NUMERO_FAC').AsString := FNumeroFactura;
    FDatosCobro.TotalesFactura.Cabecera.Post;
    FDataModule.InsertarCabeceraFactura(
      FQuery, FSerieGenerada, FNumeroFactura, FCabecera.Fecha,
      FTipoFactura, 'BORRADOR', FEmpresa, FCabecera.RazonSocialEmp,
      FCabecera.NifEmp, FCabecera.MovilEmp, FCabecera.EmailEmp,
      FCabecera.Direccion1Emp, FCabecera.Direccion2Emp,
      FCabecera.PoblacionEmp, FCabecera.ProvinciaEmp,
      FCabecera.CPostalEmp, FCabecera.CodigoPaisEmp,
      FCabecera.NombrePaisEmp, FCabecera.EsRetencionesEmp,
      FCabecera.GrupoZonaIvaEmp, FCabecera.CodigoCliente,
      FCabecera.RazonSocialCli, FCabecera.NifCli,
      FCabecera.MovilCli, FCabecera.EmailCli,
      FCabecera.Direccion1Cli, FCabecera.Direccion2Cli,
      FCabecera.PoblacionCli, FCabecera.ProvinciaCli,
      FCabecera.CPostalCli, FCabecera.CodigoPaisCli,
      FCabecera.NombrePaisCli, FCabecera.CodigoOficinaContable,
      FCabecera.CodigoOrganoGestor,
      FCabecera.CodigoUnidadTramitadora, FCabecera.CodigoIva,
      FCabecera.Tarifa, FCabecera.EsIvaRecargo,
      FCabecera.EsIvaExento, FCabecera.EsImpInclTarifa,
      FCabecera.PorcIvaN, FCabecera.TotalIvaN,
      FCabecera.PorcReN, FCabecera.TotalReN, FCabecera.BaseIN,
      FCabecera.PorcIvaR, FCabecera.TotalIvaR,
      FCabecera.PorcReR, FCabecera.TotalReR, FCabecera.BaseIR,
      FCabecera.PorcIvaS, FCabecera.TotalIvaS,
      FCabecera.PorcReS, FCabecera.TotalReS, FCabecera.BaseIS,
      FCabecera.PorcIvaE, FCabecera.TotalIvaE,
      FCabecera.PorcReE, FCabecera.TotalReE, FCabecera.BaseIE,
      FCabecera.TotalBases, FCabecera.TotalImpuestos,
      FCabecera.TotalRetencion, FCabecera.PorcRetencion,
      FCabecera.TotalLiquido, FCabecera.FormaPago,
      FCabecera.Comentarios, '', '', FAlmacen, FCaja, FUsuario,
      FNumeroOperacion, FUsuario);
    GenerarCodigoBarrasTicket;
    FDataModule.FUltSerieFacGrabada := FSerieGenerada;
    FDataModule.FUltNumeroFacGrabada := FNumeroFactura;
  end
  else
  begin
    FSerieGenerada := '';
    FNumeroFactura := '0';
  end;
end;

procedure TGrabacionFacturaCaja.InsertarLineaAnticipo(
  const ALinea: TDatosLineaFactura;
  AImporte: Currency);
var
  dPrecioBase: Currency;
begin
  if FRequiereFactura then
  begin
    if ALinea.PorcIva = 0 then
      dPrecioBase := AImporte
    else
      dPrecioBase := AImporte / (1 + ALinea.PorcIva / 100);
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura,
      ALinea.Linea, 'ANTICIPO', 'ANTICIPO',
      ALinea.Descripcion, '', '', '', 'SERVICIO', 'Uds',
      1, '', 'S', dPrecioBase, 0, 0, dPrecioBase, AImporte,
      ALinea.TipoIva, ALinea.PorcIva, dPrecioBase, AImporte,
      ALinea.Vendedor, FEmpresa, FAlmacen, FCaja,
      FNumeroOperacion, '', FUsuario);
  end;
end;

procedure TGrabacionFacturaCaja.ProcesarAnticipoPrevio(
  const ALinea: TDatosLineaFactura);
begin
  if FRequiereFactura and (Abs(ALinea.TotalCIva) > 0.001) then
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura, ALinea.Linea,
      ALinea.Articulo, ALinea.Sku, ALinea.Descripcion,
      ALinea.DescripcionVariacion, ALinea.Familia,
      ALinea.NombreFamilia, ALinea.TipoArticulo,
      ALinea.TipoCantidad, ALinea.Cantidad, ALinea.Tarifa,
      ALinea.EsImpIncl, ALinea.PrecioSalida, ALinea.PorcDto,
      ALinea.PrecioDto, ALinea.PrecioSIva, ALinea.PrecioCIva,
      ALinea.TipoIva, ALinea.PorcIva, ALinea.TotalSIva,
      ALinea.TotalCIva, ALinea.Vendedor, FEmpresa, FAlmacen,
      FCaja, FNumeroOperacion, '', FUsuario);
  if Abs(ALinea.TotalCIva) > 0.001 then
    FDataModule.InsertarOperacionCaja(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion, 'CB',
      ALinea.TotalCIva, FUsuario, FFechaOperacion, FNumeroFactura,
      FSerieGenerada, FCabecera.CodigoCliente,
      'Consumo de anticipo: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', ALinea.IdDeposito);
end;

procedure TGrabacionFacturaCaja.ProcesarNuevoDeposito(
  const ALinea: TDatosLineaFactura);
var
  sIdDeposito: string;
begin
  if ALinea.TotalCIva > 0 then
    InsertarLineaAnticipo(ALinea, ALinea.TotalCIva);
  if ALinea.AccionDeposito = 'AUMENTAR_DEP' then
  begin
    FDataModule.AumentarAnticipoDeposito(
      FQuery, ALinea.IdDeposito, FEmpresa, FAlmacen,
      FCaja, FUsuario, ALinea.TotalCIva);
    if ALinea.TotalCIva > 0 then
      FDataModule.InsertarOperacionCaja(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'CB', ALinea.TotalCIva, FUsuario, FFechaOperacion,
        FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
        'Cobro a cuenta: ' + ALinea.Descripcion,
        '', '', '', '', '', 'N', ALinea.IdDeposito);
  end
  else
  begin
    sIdDeposito := '';
    FDataModule.CrearNuevoDepositoCliente(
      FQuery, FEmpresa, FCabecera.CodigoCliente,
      ALinea.Articulo, ALinea.Sku, FUsuario,
      ALinea.PrecioOriginalDep, ALinea.TotalCIva,
      FAlmacen, FAlmacenDeposito, ALinea.Cantidad,
      ALinea.TipoIva, ALinea.PorcIva, ALinea.EsImpIncl,
      FCaja, FNumeroOperacion, FFechaOperacion, sIdDeposito);
    FDataModule.InsertarOperacionCaja(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'DE', ALinea.TotalCIva, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
  end;
end;

procedure TGrabacionFacturaCaja.ProcesarVenta(
  const ALinea: TDatosLineaFactura);
var
  sAlmacenOrigen: string;
  sEmpresaMovimiento: string;
  sTipoMovimiento: string;
  sNumeroMovimiento: string;
  sIdDeposito: string;
  dImporteCierre: Currency;
begin
  if (ALinea.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos then
    sNumeroMovimiento := ObtenerSiguienteContador(
      FDataModule.FConexion, 'MV', FUsuario)
  else
    sNumeroMovimiento := '';
  if ALinea.VieneDeDeposito = 'S' then
  begin
    sIdDeposito := ALinea.IdDeposito;
    sAlmacenOrigen := FAlmacenDeposito;
    FDataModule.CerrarDepositoCliente(
      FQuery, sIdDeposito, FEmpresa, FAlmacen,
      FCaja, FUsuario);
    dImporteCierre := ALinea.PrecioOriginalDep;
    if dImporteCierre = 0 then
      dImporteCierre := ALinea.TotalCIva;
    FDataModule.InsertarOperacionCaja(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'DE', -dImporteCierre, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Cierre depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
    FDataModule.InsertarOperacionCaja(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'VE', ALinea.TotalCIva, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Venta depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
  end
  else
  begin
    sAlmacenOrigen := FAlmacen;
    if ALinea.TotalCIva > 0 then
      FTotalVentasNormales :=
        FTotalVentasNormales + ALinea.TotalCIva
    else
      FTotalDevolucionesNormales :=
        FTotalDevolucionesNormales + Abs(ALinea.TotalCIva);
  end;
  if ALinea.Cantidad < 0 then
    sTipoMovimiento := 'E'
  else
    sTipoMovimiento := 'S';
  // Devolución de ticket de OTRA tienda: la entrada de stock se hace en
  // el almacén de origen del ticket y luego el traspaso automático la
  // lleva al almacén actual (GenerarTraspasoAutomaticoDevolucion).
  sEmpresaMovimiento := FEmpresa;
  if (ALinea.Cantidad < 0) and
     (ALinea.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos and
     EsDevolucionOtraTienda then
  begin
    sAlmacenOrigen := FAlmacenOrigenDevolucion;
    if Trim(FEmpresaOrigenDevolucion) <> '' then
      sEmpresaMovimiento := FEmpresaOrigenDevolucion;
    RegistrarLineaTraspasoDevolucion(ALinea);
  end;
  if FRequiereFactura and (Abs(ALinea.TotalCIva) > 0.001) then
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura, ALinea.Linea,
      ALinea.Articulo, ALinea.Sku, ALinea.Descripcion,
      ALinea.DescripcionVariacion, ALinea.Familia,
      ALinea.NombreFamilia, ALinea.TipoArticulo,
      ALinea.TipoCantidad, ALinea.Cantidad, ALinea.Tarifa,
      ALinea.EsImpIncl, ALinea.PrecioSalida, ALinea.PorcDto,
      ALinea.PrecioDto, ALinea.PrecioSIva, ALinea.PrecioCIva,
      ALinea.TipoIva, ALinea.PorcIva, ALinea.TotalSIva,
      ALinea.TotalCIva, ALinea.Vendedor, FEmpresa, FAlmacen,
      FCaja, FNumeroOperacion, sNumeroMovimiento, FUsuario);
  if (ALinea.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos then
    FDataModule.InsertarMovimientoAlmacen(
      FQuery, 'VE', FSerieGenerada, FNumeroFactura,
      ALinea.Linea, sEmpresaMovimiento, sAlmacenOrigen, FCaja, '',
      sTipoMovimiento, ALinea.Sku, ALinea.Cantidad, 0,
      FUsuario, FAlmacen, FNumeroOperacion,
      FCabecera.CodigoCliente, ALinea.Articulo,
      FFechaOperacion, sNumeroMovimiento);
end;

procedure TGrabacionFacturaCaja.ProcesarLineas;
var
  Linea: TDatosLineaFactura;
begin
  FTotalVentasNormales := 0;
  FTotalDevolucionesNormales := 0;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while not FDataModule.cdsLineas.Eof do
    begin
      Linea := LeerLineaActual(FDataModule.cdsLineas);
      Linea.Vendedor := Trim(Linea.Vendedor);
      if Linea.Vendedor = '' then
        Linea.Vendedor := FUsuario;
      if Linea.VieneDeDeposito = 'A' then
        ProcesarAnticipoPrevio(Linea)
      else if (Linea.AccionDeposito = 'NUEVO_DEP') or
              (Linea.AccionDeposito = 'AUMENTAR_DEP') then
        ProcesarNuevoDeposito(Linea)
      else
        ProcesarVenta(Linea);
      FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.SincronizarContadorLineas;
begin
  if FRequiereFactura then
  begin
    FQuery.SQL.Text :=
      'UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = (' +
      '  SELECT LPAD(IFNULL(MAX(CAST(LINEA_FACLIN AS UNSIGNED)),0),' +
      '              3,''0'') ' +
      '    FROM fza_facturas_lineas ' +
      '   WHERE NUMERO_FAC_FACLIN = :pnumfac ' +
      '     AND SERIE_FAC_FACLIN = :pserie' +
      ') WHERE NUMERO_FAC = :pnumfac AND SERIE_FAC = :pserie';
    FQuery.ParamByName('pnumfac').AsString := FNumeroFactura;
    FQuery.ParamByName('pserie').AsString := FSerieGenerada;
    FQuery.Execute;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarTotalesVenta;
var
  sSerieRefDevolucion: string;
  sNumeroRefDevolucion: string;
begin
  if FRequiereFactura then
  begin
    if FTotalVentasNormales > 0 then
    begin
      if FTipoRectificativa = trcNinguna then
        FConceptoOperacion := 'Venta';
      FDataModule.InsertarOperacionCaja(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'VE', FTotalVentasNormales, FUsuario, FFechaOperacion,
        FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
        FConceptoOperacion, FSerieRectificada, FNumeroRectificado);
    end;
    if FTotalDevolucionesNormales > 0 then
    begin
      if FTipoRectificativa = trcNinguna then
        FConceptoOperacion := 'Devolución de Venta';
      // Referencia al ticket de origen: la rectificada si la hay y,
      // si no, el origen elegido en el selector de devoluciones.
      sSerieRefDevolucion := FSerieRectificada;
      sNumeroRefDevolucion := FNumeroRectificado;
      if Trim(sSerieRefDevolucion) = '' then
      begin
        sSerieRefDevolucion := FSerieOrigenDevolucion;
        sNumeroRefDevolucion := FNumeroOrigenDevolucion;
      end;
      FDataModule.InsertarOperacionCaja(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'DV', -FTotalDevolucionesNormales, FUsuario,
        FFechaOperacion, FNumeroFactura, FSerieGenerada,
        FCabecera.CodigoCliente, FConceptoOperacion,
        sSerieRefDevolucion, sNumeroRefDevolucion,
        FMotivoDevolucion);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarFiscalmente;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  if FRequiereFactura then
  begin
    if SameText(FTipoFactura, 'RECTIFICATIVA') then
    begin
      if (Trim(FSerieRectificada) = '') or
         (Trim(FNumeroRectificado) = '') then
        raise Exception.Create(
          SErrorFacturaRectificativaCajaSinOriginal);
      TVerifactuCola.EncolarRectificativa(
        FDataModule.FParametrosApp,
        FDataModule.FParametrosCaja,
        CrearServicioVerifactuColaUniDAC(FDataModule.FConexion),
        FServicioEmisionFiscal,
        FDataModule.IdentidadSesion.Usuario,
        FSerieRectificada, FNumeroRectificado,
        FSerieGenerada, FNumeroFactura,
        FTipoRectificativaFiscal,
        FTratamientoMovimientos = tmrReemplazarOriginales);
    end
    else
    begin
      Solicitud := TSolicitudEmisionFiscal.ParaAlta(
        FSerieGenerada,
        FNumeroFactura,
        FDataModule.IdentidadSesion.Usuario,
        '',
        False);
      FServicioEmisionFiscal.Emitir(Solicitud);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarFormasPago;
var
  sCodigoFormaPago: string;
  sDivisa: string;
  sReferencia: string;
  dImporte: Double;
  dFactor: Double;
  dImporteDivisa: Double;
begin
  FNumeroLineaPago := 0;
  FDatosCobro.MemTablePagos.First;
  while not FDatosCobro.MemTablePagos.Eof do
  begin
    sCodigoFormaPago := FDatosCobro.MemTablePagos.FieldByName(
      'CODIGO_FP_CFP').AsString;
    dImporte := FDatosCobro.MemTablePagos.FieldByName(
      'IMPORTE_ENTREGADO').AsFloat;
    if (Abs(dImporte) > 0.001) and
       (sCodigoFormaPago <> 'VALE') then
    begin
      Inc(FNumeroLineaPago);
      sDivisa := FDatosCobro.MemTablePagos.FieldByName(
        'CODIGO_DIVISA').AsString;
      dFactor := FDatosCobro.MemTablePagos.FieldByName(
        'FACTOR_CAMBIO').AsFloat;
      dImporteDivisa := FDatosCobro.MemTablePagos.FieldByName(
        'IMPORTE_DIVISA').AsFloat;
      sReferencia := FDatosCobro.MemTablePagos.FieldByName(
        'REFERENCIA').AsString;
      FDataModule.InsertarPagoCaja(
        FQuery, FEmpresa, FAlmacen, FCaja,
        FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
        sCodigoFormaPago, dImporte,
        FDatosCobro.MemTablePagos.FieldByName(
          'IMPORTE_CAMBIO').AsCurrency,
        sDivisa, '', dFactor, dImporteDivisa, sReferencia);
    end;
    FDatosCobro.MemTablePagos.Next;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarValesRecogidos;
var
  iVale: Integer;
begin
  if FDatosCobro.ValesRecogidos <> nil then
  begin
    for iVale := 0 to FDatosCobro.ValesRecogidos.Count - 1 do
    begin
      if Abs(
        FDatosCobro.ValesRecogidos[iVale].ImporteAplicado) > 0.001 then
      begin
        Inc(FNumeroLineaPago);
        FDataModule.InsertarPagoCaja(
          FQuery, FEmpresa, FAlmacen, FCaja,
          FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
          'VALE',
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado,
          0, '', '', 1, 0,
          FDatosCobro.ValesRecogidos[iVale].CodigoVale);
        FDataModule.InsertarOperacionCaja(
          FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
          'VR',
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado,
          FUsuario, FFechaOperacion, FNumeroFactura,
          FSerieGenerada, FCabecera.CodigoCliente,
          'Vale canjeado: ' +
          FDatosCobro.ValesRecogidos[iVale].CodigoVale);
        FDataModule.MarcarValeComoCanjeado(
          FQuery,
          FDatosCobro.ValesRecogidos[iVale].CodigoVale,
          FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
          FSerieGenerada, FNumeroFactura,
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado);
      end;
    end;
  end;
end;

procedure TGrabacionFacturaCaja.EmitirVale;
var
  sCodigoVale: string;
  bTieneCaducidad: Boolean;
begin
  if FDatosCobro.ImporteValeEmitido > 0.001 then
  begin
    sCodigoVale := Format(
      'VALE_%s_%s_%s_%s',
      [FEmpresa, FAlmacen, FCaja, FNumeroOperacion]);
    bTieneCaducidad := FDataModule.FParametrosCaja.GetBool(
      'vgerCaducidadDefVale', False);
    FQuery.SQL.Text :=
      'INSERT INTO fza_caja_vales (' +
      '  CODIGO_VL, ESTADO_VL, IMPORTE_NOMINAL_VL,' +
      '  FECHA_EMISION_VL, FECHA_CADUCIDAD_VL,' +
      '  CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL,' +
      '  CODIGO_CAJA_EMI_VL, NUMERO_OPERACION_EMI_VL,' +
      '  SERIE_FAC_EMI_VL, NUMERO_FAC_EMI_VL,' +
      '  CODIGO_CLI_VL, USUARIO_ALTA, USUARIO_MODIF,' +
      '  INSTANTE_ALTA) VALUES (' +
      '  :CODIGO, ''PENDIENTE'', :IMPORTE, :FEMISION,' +
      '  :FCADUCIDAD, :EMP, :ALM, :CAJA, :NUMOPE,' +
      '  :SERIE, :NUMFAC, :CLIENTE, :USUARIO,' +
      '  :USUARIO, NOW())';
    FQuery.ParamByName('CODIGO').AsString := sCodigoVale;
    FQuery.ParamByName('IMPORTE').AsCurrency :=
      FDatosCobro.ImporteValeEmitido;
    FQuery.ParamByName('FEMISION').AsDateTime := FFechaOperacion;
    if bTieneCaducidad then
      FQuery.ParamByName('FCADUCIDAD').AsDateTime :=
        FFechaOperacion +
        FDataModule.FParametrosCaja.GetInt(
          'vgerDiasCaducidadVale', 365)
    else
      FQuery.ParamByName('FCADUCIDAD').Clear;
    FQuery.ParamByName('EMP').AsString := FEmpresa;
    FQuery.ParamByName('ALM').AsString := FAlmacen;
    FQuery.ParamByName('CAJA').AsString := FCaja;
    FQuery.ParamByName('NUMOPE').AsString := FNumeroOperacion;
    FQuery.ParamByName('SERIE').AsString := FSerieGenerada;
    FQuery.ParamByName('NUMFAC').AsString := FNumeroFactura;
    FQuery.ParamByName('CLIENTE').AsString :=
      FCabecera.CodigoCliente;
    FQuery.ParamByName('USUARIO').AsString := FUsuario;
    FQuery.Execute;
    Inc(FNumeroLineaPago);
    FDataModule.InsertarPagoCaja(
      FQuery, FEmpresa, FAlmacen, FCaja,
      FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
      'VALE', -FDatosCobro.ImporteValeEmitido, 0,
      '', '', 1, 0, sCodigoVale);
    FDataModule.InsertarOperacionCaja(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'VL', -FDatosCobro.ImporteValeEmitido, FUsuario,
      FFechaOperacion, FNumeroFactura, FSerieGenerada,
      FCabecera.CodigoCliente, 'Vale emitido: ' + sCodigoVale);
    FValeGenerado := sCodigoVale;
  end;
end;

function TGrabacionFacturaCaja.HayDepositosPendientes: Boolean;
var
  sAccion: string;
begin
  Result := False;
  FDataModule.cdsLineas.First;
  while (not FDataModule.cdsLineas.Eof) and (not Result) do
  begin
    sAccion := FDataModule.cdsLineas.FieldByName(
      'ACCION_DEPOSITO').AsString;
    Result :=
      (sAccion = 'NUEVO_DEP') or
      (sAccion = 'AUMENTAR_DEP') or
      (sAccion = 'CANCELAR');
    if not Result then
      FDataModule.cdsLineas.Next;
  end;
end;

procedure TGrabacionFacturaCaja.ConfirmarTransaccion;
begin
  FDataModule.FConexion.Commit;
  FTransaccionActiva := False;
end;

procedure TGrabacionFacturaCaja.ImprimirDocumentosDeposito;
begin
  if HayDepositosPendientes and (FNumeroOperacion <> '') then
  begin
    ImprimirResguardoDeposito(
      FDataModule.FPreviewTicket,
      FDataModule.FRepositorioTicketsCaja.Resguardos,
      FEmpresa,
      FAlmacen,
      FCaja,
      FNumeroOperacion,
      FDataModule.FParametrosCaja.ImpresoraCaja);
    ImprimirRecordatorio(
      FDataModule.FPreviewTicket,
      FDataModule.FRepositorioTicketsCaja.Recordatorios,
      FDataModule.FContextoSesion.Ubicacion.Empresa,
      FCabecera.CodigoCliente,
      FDataModule.FParametrosCaja.ImpresoraCaja);
  end;
end;

procedure TGrabacionFacturaCaja.LimpiarLineasSinImporte;
begin
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while not FDataModule.cdsLineas.Eof do
    begin
      if Abs(FDataModule.cdsLineas.FieldByName(
        'TOTAL_FACLIN').AsCurrency) < 0.001 then
        FDataModule.cdsLineas.Delete
      else
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.RevertirTransaccion;
begin
  if FTransaccionActiva and
     FDataModule.FConexion.InTransaction then
    FDataModule.FConexion.Rollback;
  FTransaccionActiva := False;
end;

function TGrabacionFacturaCaja.Ejecutar(
  out ANumeroGenerado, AValeGenerado: string): Boolean;
begin
  ANumeroGenerado := '';
  AValeGenerado := '';
  CargarContexto;
  if OperacionTieneNovedad then
  begin
    DeterminarSiRequiereFactura;
    ValidarSolicitud;
    AjustarCobroParcial;
    try
      IniciarTransaccion;
      CrearFacturaSiProcede;
      ProcesarLineas;
      SincronizarContadorLineas;
      RegistrarTotalesVenta;
      GenerarTraspasoAutomaticoDevolucion;
      RegistrarFiscalmente;
      RegistrarFormasPago;
      RegistrarValesRecogidos;
      EmitirVale;
      ConfirmarTransaccion;
      ImprimirDocumentosDeposito;
      LimpiarLineasSinImporte;
      Result := True;
    except
      on E: Exception do
      begin
        RevertirTransaccion;
        raise Exception.CreateFmt(
          SErrorGuardarTicketCaja, [E.Message]);
      end;
    end;
  end
  else
  begin
    AtenderOperacionSinNovedad;
    Result := True;
  end;
  ANumeroGenerado := FNumeroOperacion;
  AValeGenerado := FValeGenerado;
end;

function TGrabacionFacturaCaja.EsDevolucionOtraTienda: Boolean;
begin
  Result :=
    (Trim(FAlmacenOrigenDevolucion) <> '') and
    (not SameText(FAlmacenOrigenDevolucion, FAlmacen));
end;

procedure TGrabacionFacturaCaja.GenerarCodigoBarrasTicket;
const
  cPrefijoTicket = '29';
  cDigitosContador = 10;
var
  sContador: string;
  sBase: string;
begin
  // EAN-13 del ticket: prefijo 29 (uso interno de tienda) + contador
  // global 'TK' de 10 dígitos + dígito de control. Mismo patrón que los
  // códigos de artículo (prefijo 21, contador 'BA'). Si la columna aún
  // no existe (script codigo_barras_ticket.sql sin aplicar), se omite.
  FQuery.SQL.Text :=
    'SELECT COUNT(*) AS N ' +
    '  FROM INFORMATION_SCHEMA.COLUMNS ' +
    ' WHERE TABLE_SCHEMA = DATABASE() ' +
    '   AND TABLE_NAME = ''fza_facturas'' ' +
    '   AND COLUMN_NAME = ''CODIGO_BARRAS_FAC''';
  FQuery.Open;
  if FQuery.FieldByName('N').AsInteger > 0 then
  begin
    FQuery.Close;
    sContador := ObtenerSiguienteContador(
      FDataModule.FConexion, 'TK', FUsuario);
    if Length(sContador) > cDigitosContador then
      sContador := Copy(
        sContador,
        Length(sContador) - cDigitosContador + 1,
        cDigitosContador)
    else
      sContador := StringOfChar(
        '0', cDigitosContador - Length(sContador)) + sContador;
    sBase := cPrefijoTicket + sContador;
    FQuery.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET CODIGO_BARRAS_FAC = :CODIGO ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    FQuery.ParamByName('CODIGO').AsString :=
      sBase + CalcularDigitoEAN13(sBase);
    FQuery.ParamByName('SERIE').AsString := FSerieGenerada;
    FQuery.ParamByName('NUMERO').AsString := FNumeroFactura;
    FQuery.Execute;
  end
  else
    FQuery.Close;
end;

procedure TGrabacionFacturaCaja.RegistrarLineaTraspasoDevolucion(
  const ALinea: TDatosLineaFactura);
var
  iIndice: Integer;
begin
  iIndice := Length(FLineasTraspasoDev);
  SetLength(FLineasTraspasoDev, iIndice + 1);
  FLineasTraspasoDev[iIndice].Sku := ALinea.Sku;
  FLineasTraspasoDev[iIndice].Articulo := ALinea.Articulo;
  FLineasTraspasoDev[iIndice].Cantidad := Abs(ALinea.Cantidad);
end;

function TGrabacionFacturaCaja.ObtenerSerieDocumentoTraspaso(
  const AEmpresa, AAlmacen, ATipoDoc: string): string;
var
  Qry: TUniQuery;
begin
  // Serie configurada para el tipo de documento (prefiere la de la
  // caja / almacén); fallback: el propio tipo de documento. Espejo de
  // TdmTraspaso.ObtenerSerieDocumento.
  Result := ATipoDoc;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FDataModule.FConexion;
    Qry.SQL.Text :=
      'SELECT EMPSER FROM vi_empresas_series' +
      ' WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIPO' +
      '   AND (CODIGO_ALM_EMPSER = :ALM OR CODIGO_ALM_EMPSER IS NULL' +
      '        OR CODIGO_ALM_EMPSER = '''')' +
      '   AND (CODIGO_CAJA_EMPSER = :CAJA OR CODIGO_CAJA_EMPSER IS NULL' +
      '        OR CODIGO_CAJA_EMPSER = '''')' +
      ' ORDER BY (CODIGO_CAJA_EMPSER = :CAJA) DESC,' +
      '          (CODIGO_ALM_EMPSER = :ALM) DESC LIMIT 1';
    Qry.ParamByName('EMP').AsString := AEmpresa;
    Qry.ParamByName('TIPO').AsString := ATipoDoc;
    Qry.ParamByName('ALM').AsString := AAlmacen;
    Qry.ParamByName('CAJA').AsString := FCaja;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('EMPSER').AsString;
  finally
    FreeAndNil(Qry);
  end;
end;

function TGrabacionFacturaCaja.ObtenerCosteMedioSkuAlmacen(
  const ASku, AAlmacen: string): Currency;
var
  Qry: TUniQuery;
begin
  // PMP almacenado del SKU en el almacén (espejo de
  // TdmTraspaso.ObtenerCosteMedio): media ponderada por cantidad y, si
  // no hay stock pero hay PMP guardado, se toma ese (MAX).
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FDataModule.FConexion;
    Qry.SQL.Text :=
      'SELECT CASE WHEN SUM(CANTIDAD_STK) > 0' +
      '            THEN SUM(PRECIO_MEDIO_STK * CANTIDAD_STK)' +
      '                 / SUM(CANTIDAD_STK)' +
      '            ELSE MAX(PRECIO_MEDIO_STK) END AS PMP ' +
      '  FROM fza_articulos_stockactual ' +
      ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
    Qry.ParamByName('ALM').AsString := AAlmacen;
    Qry.ParamByName('SKU').AsString := ASku;
    Qry.Open;
    Result := Qry.FieldByName('PMP').AsCurrency;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TGrabacionFacturaCaja.GenerarTraspasoAutomaticoDevolucion;
var
  oStoredProc: TUniStoredProc;
  sTipoDoc: string;
  sSerieDoc: string;
  sNumeroDoc: string;
  sNumOperacion: string;
  sLinea: string;
  sEmpresaOrigen: string;
  sEmpContra: string;
  cCoste: Currency;
  cTotal: Currency;
  i: Integer;
  iLinea: Integer;
begin
  // Devolución de un ticket de OTRA tienda: la entrada de la devolución
  // se hizo en el almacén de origen (ProcesarVenta) y aquí se genera el
  // traspaso automático origen -> almacén actual, dentro de la misma
  // transacción, para que el stock quede donde está físicamente.
  if (Length(FLineasTraspasoDev) > 0) and EsDevolucionOtraTienda then
  begin
    sEmpresaOrigen := Trim(FEmpresaOrigenDevolucion);
    if sEmpresaOrigen = '' then
      sEmpresaOrigen := FEmpresa;
    // TR = misma empresa; TA = entre empresas distintas
    if SameText(sEmpresaOrigen, FEmpresa) then
    begin
      sTipoDoc := 'TR';
      sEmpContra := '';
    end
    else
    begin
      sTipoDoc := 'TA';
      sEmpContra := FEmpresa;
    end;
    sSerieDoc := ObtenerSerieDocumentoTraspaso(
      sEmpresaOrigen, FAlmacenOrigenDevolucion, sTipoDoc);
    oStoredProc := TUniStoredProc.Create(nil);
    try
      oStoredProc.Connection := FDataModule.FConexion;
      oStoredProc.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      oStoredProc.Prepare;
      oStoredProc.ParamByName('pserie').AsString := sSerieDoc;
      oStoredProc.ParamByName('pTipoDoc').AsString := sTipoDoc;
      oStoredProc.ParamByName(
        'pEMPRESA_CONTADOR').AsString := sEmpresaOrigen;
      oStoredProc.ParamByName('pUSUARIOMODIF').AsString := FUsuario;
      oStoredProc.Execute;
      sNumeroDoc := oStoredProc.ParamByName('pcont').AsString;
    finally
      FreeAndNil(oStoredProc);
    end;
    sNumOperacion := FDataModule.SiguienteOpCaja(
      sEmpresaOrigen, FAlmacenOrigenDevolucion, FCaja, FUsuario);
    cTotal := 0;
    iLinea := 0;
    for i := 0 to High(FLineasTraspasoDev) do
    begin
      iLinea := iLinea + 10;
      sLinea := Format('%.4d', [iLinea]);
      cCoste := ObtenerCosteMedioSkuAlmacen(
        FLineasTraspasoDev[i].Sku, FAlmacenOrigenDevolucion);
      // Salida del almacén de origen del ticket hacia el actual
      FDataModule.InsertarMovimientoAlmacen(
        FQuery, sTipoDoc, sSerieDoc, sNumeroDoc, sLinea,
        sEmpresaOrigen, FAlmacenOrigenDevolucion, FCaja, FAlmacen,
        'S', FLineasTraspasoDev[i].Sku,
        FLineasTraspasoDev[i].Cantidad, cCoste, FUsuario,
        FAlmacenOrigenDevolucion, sNumOperacion, '',
        FLineasTraspasoDev[i].Articulo, FFechaOperacion);
      // Entrada en el almacén donde se hace la devolución
      FDataModule.InsertarMovimientoAlmacen(
        FQuery, sTipoDoc, sSerieDoc, sNumeroDoc, sLinea,
        FEmpresa, FAlmacen, FCaja, FAlmacenOrigenDevolucion,
        'E', FLineasTraspasoDev[i].Sku,
        FLineasTraspasoDev[i].Cantidad, cCoste, FUsuario,
        FAlmacenOrigenDevolucion, sNumOperacion, '',
        FLineasTraspasoDev[i].Articulo, FFechaOperacion);
      cTotal := cTotal + cCoste * FLineasTraspasoDev[i].Cantidad;
    end;
    // Operación del traspaso: registrada en el origen con contra el
    // almacén actual (misma convención que el traspaso manual F3)
    FDataModule.InsertarOperacionCaja(
      FQuery, sEmpresaOrigen, FAlmacenOrigenDevolucion, FCaja,
      sNumOperacion, sTipoDoc, cTotal, FUsuario, FFechaOperacion,
      sNumeroDoc, sSerieDoc, '',
      'Traspaso automático por devolución a ' + FAlmacen,
      FSerieOrigenDevolucion, FNumeroOrigenDevolucion, '',
      sEmpContra, FAlmacen, 'S');
  end;
end;

function TdmCajaOpe.GrabarFacturaSimplificada(
  const AEmpresa, AAlmacen, ACaja, ASerieElegida: string;
  DatosCobro: TDatosFaseCobro;
  SerieGenerada: string;
  out NumeroGenerado: string;
  out ValeGenerado: string;
  const ATipoFactura: string = 'SIMPLIFICADA';
  AFechaFactura: TDateTime = 0;
  AFechaOperacion: TDateTime = 0;
  const ANumeroManual: string = '';
  ATipoRectificativa:
    TTipoRectificativaCaja = trcNinguna;
  const ASerieRectificada: string = '';
  const ANumeroRectificado: string = '';
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa =
      tmrMantenerOriginales;
  const AMotivoDevolucion: string = '';
  const ASerieOrigenDevolucion: string = '';
  const ANumeroOrigenDevolucion: string = '';
  const AEmpresaOrigenDevolucion: string = '';
  const AAlmacenOrigenDevolucion: string = ''): Boolean;
var
  Grabacion: TGrabacionFacturaCaja;
begin
  Grabacion := TGrabacionFacturaCaja.Create(
    Self, DatosCobro, AEmpresa, AAlmacen, ACaja,
    ASerieElegida, SerieGenerada, ATipoFactura,
    AFechaFactura, AFechaOperacion, ANumeroManual,
    ATipoRectificativa, ASerieRectificada,
    ANumeroRectificado, ATratamientoMovimientos,
    AMotivoDevolucion, ASerieOrigenDevolucion,
    ANumeroOrigenDevolucion, AEmpresaOrigenDevolucion,
    AAlmacenOrigenDevolucion);
  try
    Result := Grabacion.Ejecutar(
      NumeroGenerado, ValeGenerado);
  finally
    FreeAndNil(Grabacion);
  end;
end;

// =============================================================================
// ALTER TABLE — actualizar el COMMENT del campo con todos los tipos vigentes
// Ejecutar en la BD una sola vez.
// =============================================================================
//
// ALTER TABLE fza_caja_operaciones
//   MODIFY COLUMN `TIPO_OPERACION_OPCAJA` varchar(2)
//     CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL
// COMMENT 'VE=Venta, DE=Nuevo depósito, CB=Cobro a cuenta, DV=Devolución
// anticipo, VL=Vale emitido, VR=Vale recogido, AL=Albarán, EC=Entrada efectivo,
// GC=Gasto efectivo, TR=Traspaso almacén, AT=Traspaso empresa';

function TdmCajaOpe.CuadrarFacturaEnMemoria(dsCabecera,
                                            dsLineas: TDataSet): Boolean;
var
  CalculadorFiscal: TFacturaTotales;
begin
  // Instanciamos tu clase pasándole los datasets de la caja
  CalculadorFiscal := TFacturaTotales.Create(
    FConexion,
    CrearRepositorioLecturasFacturaUniDAC(FConexion),
    dsCabecera,
    dsLineas);
  try
    // ProcesarFacturaCompleta se encarga de leer configuración, recorrer líneas
    // y sumarizar
    Result := CalculadorFiscal.ProcesarFacturaCompleta;
    if not Result then
      raise Exception.CreateFmt(SErrorCuadrarFacturaCaja,
                                [CalculadorFiscal.MensajeError]);
  finally
    FreeAndNil(CalculadorFiscal);
  end;
end;

procedure TdmCajaOpe.InsertarPagoCaja(
                        QryTrx:           TUniQuery;
                        const AEmpresa:   string;
                        const AAlmacen:   string;
                        const ACaja:      string;
                        // serie de la operación de caja
                        const ASerie:     string;
                        ANumOperacion:    string;
                        // 1, 2, 3... por forma de pago
                        ANumLinea:        Integer;
                        const AFormaP:    string;    // FK a fza_formas_pago
                        AImporteEntregado: Currency;
                        AImporteCambio:   Currency;  // 0 si no hay cambio
                        // — opcionales —
                        const ADivisa:       string   = '';
                        const ARedBlockchain:string   = '';
                        AFactorCambio:       Double   = 1;
                        AImporteDivisa:      Double   = 0;
                        const AReferencia:   string   = '';
                        const AObservaciones:string   = '');
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_pagos (' +
    '  CODIGO_EMP_PAGO,' +
    '  CODIGO_ALM_PAGO,' +
    '  CODIGO_CAJA_PAGO,' +
    '  SERIE_OPERACION_PAGO,' +
    '  NUMERO_OPERACION_PAGO,' +
    '  NUMERO_LINEA_PAGO,' +
    '  CODIGO_FP_CFP,' +
    '  IMPORTE_ENTREGADO_PAGO,' +
    '  IMPORTE_CAMBIO_PAGO,' +
    '  CODIGO_DIVISA_PAGO,' +
    '  RED_BLOCKCHAIN_PAGO,' +
    '  FACTOR_CAMBIO_PAGO,' +
    '  IMPORTE_DIVISA_PAGO,' +
    '  REFERENCIA_FACPAG,' +
    '  OBSERVACIONES_PAGO,' +
    '  USUARIO_ALTA, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :EMP,' +
    '  :ALM,' +
    '  :CAJA,' +
    '  :SERIE,' +
    '  :NUMOP,' +
    '  :LINEA,' +
    '  :FORMAP,' +
    '  :IMPORTE,' +
    '  :CAMBIO,' +
    '  NULLIF(:DIVISA,      ''''),' +
    '  NULLIF(:BLOCKCHAIN,  ''''),' +
    '  :FACTORCAMBIO,' +
    '  :IMPORTEDIVISA,' +
    '  NULLIF(:REFERENCIA,  ''''),' +
    '  NULLIF(:OBS,         ''''),' +
    '  :USUARIO, NOW())';
  QryTrx.ParamByName('EMP').AsString       := AEmpresa;
  QryTrx.ParamByName('ALM').AsString       := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString      := ACaja;
  QryTrx.ParamByName('SERIE').AsString     := ASerie;
  QryTrx.ParamByName('NUMOP').AsString     := ANumOperacion;
  QryTrx.ParamByName('LINEA').AsInteger    := ANumLinea;
  QryTrx.ParamByName('FORMAP').AsString    := AFormaP;
  QryTrx.ParamByName('IMPORTE').AsCurrency := AImporteEntregado;
  QryTrx.ParamByName('CAMBIO').AsCurrency  := AImporteCambio;
  QryTrx.ParamByName('DIVISA').AsString    := ADivisa;
  QryTrx.ParamByName('BLOCKCHAIN').AsString:= ARedBlockchain;
  QryTrx.ParamByName('FACTORCAMBIO').AsFloat  := AFactorCambio;
  QryTrx.ParamByName('IMPORTEDIVISA').AsFloat := AImporteDivisa;
  QryTrx.ParamByName('REFERENCIA').AsString:= AReferencia;
  QryTrx.ParamByName('OBS').AsString       := AObservaciones;
  QryTrx.ParamByName('USUARIO').AsString   := IdentidadSesion.Usuario;
  QryTrx.Execute;
end;

function TdmCajaOpe.SiguienteOpCaja(AEmpresa,
                                      AAlmacen,
                                      ACaja,
                                      AEmpleado: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := FConexion;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    // 1. Creación y asignación explícita de parámetros IN
    SpTrx.Params.CreateParam(ftString,
                             'pEmpresa',
                             ptInput).AsString := AEmpresa;
    SpTrx.Params.CreateParam(ftString,
                             'pAlmacen',
                             ptInput).AsString := AAlmacen;
    SpTrx.Params.CreateParam(ftString, 'pCaja',    ptInput).AsString := ACaja;
    SpTrx.Params.CreateParam(ftString,
                             'pUsuario',
                             ptInput).AsString := AEmpleado;
    // 2. Creación explícita de parámetros OUT
    SpTrx.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
    SpTrx.Params.CreateParam(ftString, 'pcont',  ptOutput).Size := 20;
    // 3. Preparar el SP en el motor de base de datos
    SpTrx.Prepare;
    // 4. Ejecutar
    SpTrx.Execute;
    // SerieOperacion := SpTrx.ParamByName('pSerie').AsString; // misma en todas
    // las llamadas
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    // Al liberar el componente también se hace el UnPrepare automáticamente
    FreeAndNil(SpTrx);
  end;
end;

procedure TdmCajaOpe.InsertarOperacionCaja(
                        QryTrx:          TUniQuery;
                        const AEmpresa:  string;
                        const AAlmacen:  string;
                        const ACaja:     string;
                        ANumOperacion:   string;
                        // 'VE','VL','AL','CB','EC','GC','TR','AT'
                        const ATipoOp:   string;
                        AImporte:        Currency; // negativo en VL y AT
                        const AEmpleado: string;
                        AFechaOperacion: TDateTime = 0;
                        // — opcionales —
                        const ANroFactura:       string = '';
                        const ASerieFactura:     string = '';
                        const ACliente:          string = '';
                        const AConcepto:         string = '';
                        const ASerieOrigen:      string = '';
                        const ANroOrigen:        string = '';
                        const AMotivoDevolucion: string = '';
                        const AEmpresaContra:    string = '';
                        const AAlmContra:        string = '';
                        const AEsTraspaso:       string = 'N';
                        const AIdDeposito:       string = '');
var
  dtFechaOperacion: TDateTime;
begin
  dtFechaOperacion := FechaCajaConHora(AFechaOperacion);
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMP_OPCAJA,' +
    '  CODIGO_ALM_OPCAJA,' +
    '  CODIGO_CAJA_OPCAJA,' +
    '  NUMERO_OPERACION_OPCAJA,' +
    '  TIPO_OPERACION_OPCAJA,' +
    '  IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA,' +
    '  FECHA_OP_DIA_OPCAJA,' +
    '  CODIGO_EMPLEADO_OPCAJA,' +
    '  NUMERO_FAC_OPCAJA,' +
    '  SERIE_FAC_OPCAJA,' +
    '  CODIGO_CLI_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA,' +
    '  SERIE_REF_ORIGEN_OPCAJA,' +
    '  NUMERO_REF_ORIGEN_OPCAJA,' +
    '  MOTIVO_DEVOLUCION_OPCAJA,' +
    '  CODIGO_EMP_CONTRA_OPCAJA,' +
    '  CODIGO_ALM_CONTRA_OPCAJA,' +
    '  ESTRASPASO_OPCAJA,' +
    '  ESTADO_DEVOLUCION_OPCAJA,' +
    '  ID_DEPOSITO_OPCAJA,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :EMP,' +
    '  :ALM,' +
    '  :CAJA,' +
    '  :NUMOP,' +
    '  :TIPOOP,' +
    '  :IMPORTE,' +
    '  :FECHAOP,' +
    '  :FECHADIA,' +
    '  :EMPLEADO,' +
    '  NULLIF(:NROFAC,    ''''),' +
    '  NULLIF(:SERIEFAC,  ''''),' +
    '  NULLIF(:CLI,       ''''),' +
    '  NULLIF(:CONCEPTO,  ''''),' +
    '  NULLIF(:SERIEORIG, ''''),' +
    '  NULLIF(:NROORIG,   ''''),' +
    '  NULLIF(:MOTIVO,    ''''),' +
    '  NULLIF(:EMPCONTRA, ''''),' +
    '  NULLIF(:ALMCONTRA, ''''),' +
    '  :ESTRASPASO,' +
    '  ''N'',' +
    '  :DEP, ' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('EMP').AsString      := AEmpresa;
  QryTrx.ParamByName('ALM').AsString      := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString     := ACaja;
  QryTrx.ParamByName('NUMOP').AsString    := ANumOperacion;
  QryTrx.ParamByName('TIPOOP').AsString   := ATipoOp;
  QryTrx.ParamByName('IMPORTE').AsCurrency:= AImporte;
  QryTrx.ParamByName('FECHAOP').AsDateTime := dtFechaOperacion;
  QryTrx.ParamByName('FECHADIA').AsDateTime := Trunc(dtFechaOperacion);
  QryTrx.ParamByName('EMPLEADO').AsString := AEmpleado;
  QryTrx.ParamByName('NROFAC').AsString   := ANroFactura;
  QryTrx.ParamByName('SERIEFAC').AsString := ASerieFactura;
  QryTrx.ParamByName('CLI').AsString      := ACliente;
  QryTrx.ParamByName('CONCEPTO').AsString := AConcepto;
  QryTrx.ParamByName('SERIEORIG').AsString:= ASerieOrigen;
  QryTrx.ParamByName('NROORIG').AsString  := ANroOrigen;
  QryTrx.ParamByName('MOTIVO').AsString   := AMotivoDevolucion;
  QryTrx.ParamByName('EMPCONTRA').AsString:= AEmpresaContra;
  QryTrx.ParamByName('ALMCONTRA').AsString:= AAlmContra;
  QryTrx.ParamByName('ESTRASPASO').AsString := AEsTraspaso;
  QryTrx.ParamByName('USUARIO').AsString  := IdentidadSesion.Usuario;
  QryTrx.ParamByName('DEP').AsString  := AIdDeposito;
  QryTrx.Execute;
end;

function TdmCajaOpe.BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                         var LabelDestino: String): Boolean;
var
  unqry: TUniQuery;
  FieldToGet: string;
  SQLStr: string;
begin
  LabelDestino := '';
  Result := False;
  if Trim(Codigo) <> '' then
  begin
    SQLStr := '';
    if TipoEntidad = 'EMPLEADOS' then
    begin
      SQLStr := 'SELECT DIMINUTIVO_TICKET_EMPL ' +
                '  FROM fza_empleados ' +
                ' WHERE CODIGO_EMPL = :COD';
      FieldToGet := 'DIMINUTIVO_TICKET_EMPL';
    end
    else if TipoEntidad = 'CLIENTES' then
    begin
      SQLStr := 'SELECT RAZON_SOCIAL_CLI ' +
                '  FROM fza_clientes ' +
                ' WHERE CODIGO_CLI_CLI = :COD';
      FieldToGet := 'RAZON_SOCIAL_CLI';
    end;
    if SQLStr <> '' then
    begin
      unqry := TUniQuery.Create(nil);
      try
        unqry.Connection := FConexion;
        unqry.SQL.Text := SQLStr;
        unqry.ParamByName('COD').AsString := Codigo;
        unqry.Open;
        if not unqry.IsEmpty then
        begin
          LabelDestino := unqry.FieldByName(FieldToGet).AsString;
          Result := True;
        end;
      finally
        FreeAndNil(unqry);
      end;
    end;
  end;
end;

function TdmCajaOpe.GenerarSkuFinal(ArticuloBase: string): string;
var
  i: Integer;
  ValorAttr: string;
  SkuBuilder: string;
  NumAttr:Integer;
begin
  NumAttr := cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  SkuBuilder := ArticuloBase;
  for i := 1 to NumAttr do
  begin
    ValorAttr := cdsLineas.FieldByName('ATTR' + IntToStr(i) +
                                                           '_VALOR').AsString;
    if ValorAttr <> '' then
       SkuBuilder := SkuBuilder + '/' + ValorAttr;
  end;
  Result := SkuBuilder;
end;

function TdmCajaOpe.GetTarifaDefault: string;
begin
  Result := FParametrosCaja.TarifaDefecto;
end;

procedure TdmCajaOpe.cdsCabeceraAfterInsert(DataSet: TDataSet);
begin
  AplicarValoresPorDefecto(FConexion, cdsCabecera, 'fza_facturas');
  cdsCabecera.FieldByName('SERIE_FAC').AsString := '0';
  cdsCabecera.FieldByName('TIPO_FAC').AsString := 'SIMPLIFICADA';
end;

procedure TdmCajaOpe.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  if not DataSet.ControlsDisabled then
  begin
    if Assigned(FOnRecalcularLineas) then
      FOnRecalcularLineas;
  end;
end;

procedure TdmCajaOpe.cdsLineasAfterInsert(DataSet: TDataSet);
var
  NuevoNumero: Integer;
begin
  if not DataSet.ControlsDisabled then
    AplicarValoresPorDefecto(
      FConexion,
      cdsLineas,
      'fza_facturas_lineas');
  cdsLineas.FieldByName('SERIE_FAC_FACLIN').AsString := '0';
  cdsLineas.FieldByName('NUMERO_FAC_FACLIN').AsString := '0';
  NuevoNumero :=
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger + 10;
  cdsCabecera.Edit;
  cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger :=
    NuevoNumero;
  cdsLineas.FieldByName('LINEA_FACLIN').AsString :=
    Format('%.4d', [NuevoNumero]);
  cdsLineas.FieldByName('CODIGO_VENDEDOR_FACLIN').AsString :=
    cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
  cdsLineas.FindField('PORCENTAJE_IVA_FACLIN').AsCurrency :=
    GetTipoIVA(
      cdsLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
end;

function TdmCajaOpe.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      fPorcen := cdsCabecera.FindField(
        'PORCENTAJE_IVAN_FAC').AsCurrency;
      cdsLineas.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
  end;
  Result := fPorcen;
end;

procedure TdmCajaOpe.cdsLineasAfterPost(DataSet: TDataSet);
begin
if not DataSet.ControlsDisabled then
  begin
    // 1. Desenganchamos el evento para evitar el bucle infinito
    cdsLineas.AfterPost := nil;
    try
      if Assigned(FOnRecalcularLineas) then
        FOnRecalcularLineas;
    finally
      // 2. Lo volvemos a enganchar al terminar
      cdsLineas.AfterPost := cdsLineasAfterPost;
    end;
  end;
end;

procedure TdmCajaOpe.cdsLineasBeforePost(DataSet: TDataSet);
var
  Requeridos: Integer;
  SkuActual: string;
begin
  if DataSet.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString = '' then
    Abort;
  Requeridos :=
    DataSet.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  if Requeridos > 0 then
  begin
    SkuActual := Trim(
      DataSet.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
    if Pos('/', SkuActual) = 0 then
      Abort;
  end;
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
var
  Indice: TIndexDef;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsCabecera.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  Add('SERIE_FAC', ftString, 20, True);
    Add('NUMERO_FAC', ftString, 20, True);
    Add('FECHA_FAC', ftDate, 0);
    Add('ESCONSOLIDADA_FAC', ftString, 1);
    Add('INSTANTECONSO_FAC', ftDateTime, 0);
    Add('TIPO_FAC', ftString, 20); // NORMAL, SIMPLIFICADA...
    Add('FASE_FAC', ftString, 20); // BORRADOR, VERIFACTU_OK...
    Add('CODIGO_EMP_FAC', ftString, 8);
    Add('RAZON_SOCIAL_EMPRESA_FAC', ftString, 200);
    Add('NIF_EMPRESA_FAC', ftString, 50);
    Add('MOVIL_EMPRESA_FAC', ftString, 40);
    Add('EMAIL_EMPRESA_FAC', ftString, 200);
    Add('DIRECCION1_EMPRESA_FAC', ftString, 200);
    Add('DIRECCION2_EMPRESA_FAC', ftString, 200);
    Add('POBLACION_EMPRESA_FAC', ftString, 200);
    Add('PROVINCIA_EMPRESA_FAC', ftString, 200);
    Add('CODIGO_PAI_EMPRESA_FAC', ftString, 3);
    Add('NOMBRE_PAI_EMPRESA_FAC', ftString, 150);
    Add('CODIGO_POSTAL_EMPRESA_FAC', ftString, 15);
    Add('ESRETENCIONES_EMPRESA_FAC', ftString, 1);
    Add('GRUPO_ZONA_IVA_EMPRESA_FAC', ftString, 10);
    Add('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC', ftString, 1);
    Add('CODIGO_CLI_FAC', ftString, 10);
    Add('RAZON_SOCIAL_CLIENTE_FAC', ftString, 200);
    Add('NIF_CLIENTE_FAC', ftString, 50);
    Add('MOVIL_CLIENTE_FAC', ftString, 40);
    Add('EMAIL_CLIENTE_FAC', ftString, 200);
    Add('DIRECCION1_CLIENTE_FAC', ftString, 200);
    Add('DIRECCION2_CLIENTE_FAC', ftString, 200);
    Add('POBLACION_CLIENTE_FAC', ftString, 200);
    Add('PROVINCIA_CLIENTE_FAC', ftString, 200);
    Add('CODIGO_POSTAL_CLIENTE_FAC', ftString, 15);
    Add('CODIGO_PAI_CLIENTE_FAC', ftString, 3);
    Add('NOMBRE_PAI_CLIENTE_FAC', ftString, 150);
    Add('CODIGO_OFICINA_CONTABLE_FAC', ftString, 10);
    Add('CODIGO_ORGANO_GESTOR_FAC', ftString, 10);
    Add('CODIGO_UNIDAD_TRAMITADORA_FAC', ftString, 10);
    Add('CODIGO_CAJERO_FAC', ftString, 20);
    Add('CODIGO_IVA_FAC', ftString, 20);
    Add('ESIVA_RECARGO_CLIENTE_FAC', ftString, 1);
    Add('ESIVA_EXENTO_CLIENTE_FAC', ftString, 1);
    Add('ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC', ftString, 1);
    Add('ESRETENCIONES_CLIENTE_FAC', ftString, 1);
    Add('TARIFA_ARTICULO_CLIENTE_FAC', ftString, 10);
    Add('ESIMP_INCL_TARIFA_CLIENTE_FAC', ftString, 1);
    Add('ESINTRACOMUNITARIO_CLIENTE_FAC', ftString, 1);
    Add('ESIRPF_IMP_INCL_ZONA_IVA_FAC', ftString, 1);
    Add('ESAPLICA_RE_ZONA_IVA_FAC', ftString, 1);
    Add('ESIVAAGRICOLA_ZONA_IVA_FAC', ftString, 1);
    Add('PALABRA_REPORTS_ZONA_IVA_FAC', ftString, 10);
    Add('ESVENTA_ACTIVO_FIJO_FAC', ftString, 1);
    Add('PORCENTAJE_IVAN_FAC', ftFloat, 0);
    Add('TOTAL_IVAN_FAC', ftCurrency, 0);
    Add('PORCENTAJE_REN_FAC', ftFloat, 0);
    Add('TOTAL_REN_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAN_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAR_FAC', ftFloat, 0);
    Add('TOTAL_IVAR_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RER_FAC', ftFloat, 0);
    Add('TOTAL_RER_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAR_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAS_FAC', ftFloat, 0);
    Add('TOTAL_IVAS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RES_FAC', ftFloat, 0);
    Add('TOTAL_RES_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAE_FAC', ftFloat, 0);
    Add('TOTAL_IVAE_FAC', ftCurrency, 0);
    Add('PORCENTAJE_REE_FAC', ftFloat, 0);
    Add('TOTAL_REE_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAE_FAC', ftCurrency, 0);
    Add('TOTAL_BASES_FAC', ftCurrency, 0);
    Add('TOTAL_IMPUESTOS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RETENCION_FAC', ftFloat, 0);
    Add('TOTAL_RETENCION_FAC', ftCurrency, 0);
    Add('TOTAL_LIQUIDO_FAC', ftCurrency, 0); // Lo que paga el cliente
    Add('FORMA_PAGO_FAC', ftString, 200);
    Add('NUMERO_FAC_ABONO_FAC', ftString, 8);
    Add('SERIE_FAC_ABONO_FAC', ftString, 8);
    Add('TEXTO_LEGAL_CLIENTE_FAC', ftString, 1000);
    Add('TEXTO_LEGAL_EMPRESA_FAC', ftString, 1000);
    Add('COMENTARIOS_FAC', ftString, 1000);
    Add('XML_FAC', ftMemo, 0); // Para VeriFactu
    Add('DOCUMENTO_FAC', ftBlob, 0);
    Add('CONTADOR_LINEAS_FAC', ftString, 8);
    Add('ESCREARARTICULOS_FAC', ftString, 1);
    Add('ESDESCRIPCIONES_AMP_FAC', ftString, 1);
    Add('ESFECHADEENTREGA_FAC', ftString, 1);
    Add('INSTANTE_MODIF', ftDateTime, 0);
    Add('INSTANTE_ALTA', ftDateTime, 0);
    Add('USUARIO_ALTA', ftString, 100);
  Add('USUARIO_MODIF', ftString, 100);
  Indice := cdsCabecera.IndexDefs.AddIndexDef;
  Indice.Name := 'PK_CABECERA';
  Indice.Fields := 'SERIE_FAC;NUMERO_FAC';
  Indice.Options := [ixPrimary, ixUnique];
  cdsCabecera.CreateDataSet;
end;

procedure TdmCajaOpe.ConfigurarEstructuraLineas;
var
  Indice: TIndexDef;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsLineas.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  Add('VIENE_DE_DEPOSITO', ftString, 1);
    Add('ID_DEPOSITO_DEP', ftString, 20);
    Add('PRECIO_ORIGINAL_DEP', ftCurrency);
    Add('ACCION_DEPOSITO', ftString, 15); // Valores: 'COBRAR' o 'CANCELAR'
    Add('ANTICIPO_PREVIO', ftCurrency);   // Memoria del dinero adelantado
    // Fecha y hora de la operacion del deposito (F2 cuenta cliente), ya
    // formateada para mostrarse tal cual en el grid.
    Add('FECHA_DEPOSITO_DEP', ftString, 20);
    // -- CLAVES DE ENLACE CON CABECERA (Foreign Keys) --
    Add('SERIE_FAC_FACLIN', ftString, 20, True);
    Add('NUMERO_FAC_FACLIN', ftString, 20, True);
    Add('LINEA_FACLIN', ftString, 4, True);
    Add('CODIGO_VENDEDOR_FACLIN', ftString, 20);
    // -- DATOS DEL ARTÍCULO (PADRE) --
    Add('CODIGO_ART_FACLIN', ftString, 50);
    Add('CODIGO_FAM_FACLIN', ftString, 20);
    Add('NOMBRE_FAM_FACLIN', ftString, 200);
    Add('DESCRIPCION_ARTICULO_FACLIN', ftString, 100);
    // El SKU exacto que descuenta stock (ej: ZAP-OXFORD/42/NEGRO)
    Add('CODIGO_UNIDAD_FACLIN', ftString, 50);
    Add('TIPO_ARTICULO_FACLIN', ftString, 10); // 'ESTANDAR' o 'SERVICIO'
    Add('NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger, 0);
    for var I := 1 to 5 do
    begin
      Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 50);
      Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 50);
    end;
    // DATOS DE TRAZABILIDAD (Si el artículo lo requiere)
    Add('LOTE_FACLIN', ftString, 50);
    Add('FECHA_CADUCIDAD_FACLIN', ftDate, 0);
    Add('PRECIO_ULT_COMPRA_FACLIN', ftBCD, 0);
    Add('CODIGO_PRV_FACLIN', ftString, 20);
    Add('RAZON_SOCIAL_PROVEEDOR_FACLIN', ftString, 200);
    Add('ESPROVEEDORPRINCIPAL_FACLIN', ftString, 1);
    Add('FECHA_ENTREGA_FACLIN', ftDateTime, 0);
    // -- CANTIDADES Y TARIFAS --
    Add('TIPO_CANTIDAD_ARTICULO_FACLIN', ftString, 20); // 'Uds', 'Kg'
    Add('ESIMP_INCL_TARIFA_FACLIN', ftString, 1);
    Add('CODIGO_TAR_FACLIN', ftString, 10);
    Add('CANTIDAD_FACLIN', ftFloat, 0);
    // -- PRECIOS Y DESCUENTOS --
    Add('PRECIO_SALIDA_FACLIN', ftCurrency, 0);
    Add('PORCENTAJE_DTO_FACLIN', ftFloat, 0);
    Add('PRECIO_DTO_FACLIN', ftFloat, 0);
    // -- IMPORTES Y TOTALES --
    Add('PRECIO_VENTA_SIVA_ARTICULO_FACLIN', ftCurrency, 0);
    Add('TIPO_IVA_ARTICULO_FACLIN', ftString, 2);
    Add('PORCENTAJE_IVA_FACLIN', ftFloat, 0);
    Add('PRECIO_VENTA_CIVA_ARTICULO_FACLIN', ftCurrency, 0);
    Add('TOTAL_FACLIN', ftCurrency, 0);
    Add('TOTAL_FAC_SIVA_FACLIN', ftCurrency, 0);
    // -- CAMPOS DE AUDITORÍA --
    Add('INSTANTE_MODIF', ftDateTime, 0);
    Add('INSTANTE_ALTA', ftDateTime, 0);
    Add('USUARIO_ALTA', ftString, 100);
  Add('USUARIO_MODIF', ftString, 100);
  Indice := cdsLineas.IndexDefs.AddIndexDef;
  Indice.Name := 'PRIMARY_KEY';
  Indice.Fields :=
    'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN;LINEA_FACLIN';
  Indice.Options := [ixPrimary, ixUnique];
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := FConexion;
  qryVales.Connection := FConexion;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

procedure TdmCajaOpe.MarcarValeComoCanjeado(QryTrx: TUniQuery;
                                            const ACodigoVale: string;
                                            const AEmpresa: string;
                                            const ACodigoAlmacen: string;
                                            const ACodigoCaja: string;
                                            const ANumOperacion: string;
                                            const ASerie: string;
                                            const ANumFactura: string;
                                            AImporteRedimido: Currency);
var
  FilasAfectadas: Integer;
begin
  QryTrx.SQL.Text :=
    'UPDATE fza_caja_vales ' +
    '   SET ESTADO_VL               = ''REDIMIDO'', ' +
    '       FECHA_REDENCION_VL      = NOW(), ' +
    '       IMPORTE_REDIMIDO_VL     = :importe, ' +
    '       CODIGO_EMP_RED_VL       = :empresa, ' +
    '       CODIGO_ALM_RED_VL       = :almacen, ' +
    '       CODIGO_CAJA_RED_VL      = :caja, ' +
    '       NUMERO_OPERACION_RED_VL = :numop, ' +
    '       SERIE_FAC_RED_VL        = NULLIF(:serie, ''''), ' +
    '       NUMERO_FAC_RED_VL       = NULLIF(:numfac, ''''), ' +
    '       USUARIO_MODIF           = :usuario, ' +
    '       INSTANTE_MODIF          = NOW() ' +
    ' WHERE CODIGO_VL = :codigo ' +
    '   AND ESTADO_VL = ''PENDIENTE''';
  QryTrx.ParamByName('codigo').AsString    := ACodigoVale;
  QryTrx.ParamByName('importe').AsCurrency := AImporteRedimido;
  QryTrx.ParamByName('empresa').AsString   := AEmpresa;
  QryTrx.ParamByName('almacen').AsString   := ACodigoAlmacen;
  QryTrx.ParamByName('caja').AsString      := ACodigoCaja;
  QryTrx.ParamByName('numop').AsString     := ANumOperacion;
  QryTrx.ParamByName('serie').AsString     := ASerie;
  QryTrx.ParamByName('numfac').AsString    := ANumFactura;
  QryTrx.ParamByName('usuario').AsString   := IdentidadSesion.Usuario;
  QryTrx.Execute;
  // Validar que se haya marcado realmente el vale.
  // Si RowsAffected = 0, el vale no existe, ya estaba redimido, o el codigo
  // venia mal. En cualquier caso, abortamos la transaccion completa.
  FilasAfectadas := QryTrx.RowsAffected;
  if FilasAfectadas <> 1 then
    raise Exception.CreateFmt(
      SErrorRedimirValeCaja,
      [ACodigoVale, FilasAfectadas]);
end;

procedure ConfigurarSqlInsertarCabeceraFacturaCaja(AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_facturas (' +
    '  SERIE_FAC, NUMERO_FAC, FECHA_FAC,' +
    '  TIPO_FAC, FASE_FAC,' +
    '  CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC,' +
    '  MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC,' +
    '  DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC,' +
    '  POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC,' +
    '  CODIGO_POSTAL_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC,' +
    '  ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC,' +
    '  CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC,' +
    '  MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC,' +
    '  DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC,' +
    '  POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC,' +
    '  CODIGO_POSTAL_CLIENTE_FAC, CODIGO_PAI_CLIENTE_FAC, ' +
    'NOMBRE_PAI_CLIENTE_FAC,' +
    '  CODIGO_OFICINA_CONTABLE_FAC, CODIGO_ORGANO_GESTOR_FAC, ' +
    'CODIGO_UNIDAD_TRAMITADORA_FAC,' +
    '  CODIGO_IVA_FAC, TARIFA_ARTICULO_CLIENTE_FAC,' +
    '  ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC,' +
    '  ESIMP_INCL_TARIFA_CLIENTE_FAC,' +
    '  PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, ' +
    'TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC,' +
    '  PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC,' +
    '  PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
    'TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC,' +
    '  PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, ' +
    'TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC,' +
    '  TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC,' +
    '  PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC,' +
    '  TOTAL_LIQUIDO_FAC,' +
    '  FORMA_PAGO_FAC,' +
    '  COMENTARIOS_FAC,' +
    '  SERIE_FAC_ABONO_FAC, NUMERO_FAC_ABONO_FAC,' +
    '  CODIGO_ALM_FAC, CODIGO_CAJA_FAC,' +
    '  CODIGO_CAJERO_FAC, NUMERO_OPERACION_FAC,' +
    '  ESCREARARTICULOS_FAC, ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :SERIE, :NRO, :FECHA,' +
    '  :TIPO, :FASE,' +
    '  :EMP, :RSEMP, :NIFEMP,' +
    '  NULLIF(:MOVILEMP,  ''''), NULLIF(:EMAILEMP, ''''),' +
    '  NULLIF(:DIR1EMP,   ''''), NULLIF(:DIR2EMP,  ''''),' +
    '  NULLIF(:POBLEMP,   ''''), NULLIF(:PROVEMP,  ''''),' +
    '  NULLIF(:CPEMP,     ''''), :PAISEMP, NULLIF(:NPAISEMP, ''''),' +
    '  :RETREMP, NULLIF(:GRUPOIVAEMP, ''''),' +
    '  NULLIF(:CLI,       ''''), NULLIF(:RSCLI,    ''''), NULLIF(:NIFCLI,   ' +
    '''''),' +
    '  NULLIF(:MOVILCLI,  ''''), NULLIF(:EMAILCLI, ''''),' +
    '  NULLIF(:DIR1CLI,   ''''), NULLIF(:DIR2CLI,  ''''),' +
    '  NULLIF(:POBLCLI,   ''''), NULLIF(:PROVCLI,  ''''),' +
    '  NULLIF(:CPCLI,     ''''), :PAISCLI, NULLIF(:NPAISCLI, ''''),' +
    '  NULLIF(:DIR3OFICINA, ''''), NULLIF(:DIR3ORGANO, ''''), ' +
    'NULLIF(:DIR3UNIDAD, ''''),' +
    '  NULLIF(:CODIGOIVA, ''''), NULLIF(:TARIFA,   ''''),' +
    '  :ESRECARGO, :ESEXENTO,' +
    '  :ESIMPINCL,' +
    '  :PIVAN,  :TIVAN,  :PREN,  :TREN,  :BASEIN,' +
    '  :PIVAR,  :TIVAR,  :PRER,  :TRER,  :BASEIR,' +
    '  :PIVAS,  :TIVAS,  :PRES,  :TRES,  :BASEIS,' +
    '  :PIVAE,  :TIVAE,  :PREE,  :TREE,  :BASEIE,' +
    '  :TBASES, :TIMPS,' +
    '  :PRETENC, :TRETENC,' +
    '  :TLIQUIDO,' +
    '  NULLIF(:FORMAP,  ''''),' +
    '  NULLIF(:COMENT,  ''''),' +
    '  NULLIF(:SERIEABO, ''''), NULLIF(:NROABO, ''''),' +
    '  NULLIF(:ALM,  ''''), NULLIF(:CAJA,  ''''),' +
    '  NULLIF(:CAJERO, ''''), NULLIF(:NUMOP, ''''),' +
    '  ''N'', ''N'', ''N'',' +
    '  :USUARIO, :USUARIO, NOW())';
end;

procedure TdmCajaOpe.InsertarCabeceraFactura(
            QryTrx:          TUniQuery;
            // — identificación —
            const ASerie:    string;
            const ANro:      string;
            AFecha:          TDateTime;
            const ATipo:     string;
            const AFase:     string;
            // — empresa emisora —
            const AEmpresa,
                  ARazonSocialEmp,
                  ANifEmp,
                  AMovilEmp,
                  AEmailEmp,
                  ADireccion1Emp,
                  ADireccion2Emp,
                  APoblacionEmp,
                  AProvinciaEmp,
                  ACPostalEmp,
                  ACodigoPaisEmp,
                  ANombrePaisEmp: string;
            AEsRetencionesEmp:    string;   // 'S'/'N'
            AGrupoZonaIvaEmp:     string;
            // — cliente —
            const ACliente,
                  ARazonSocialCli,
                  ANifCli,
                  AMovilCli,
                  AEmailCli,
                  ADireccion1Cli,
                  ADireccion2Cli,
                  APoblacionCli,
                  AProvinciaCli,
                  ACPostalCli,
                  ACodigoPaisCli,
                  ANombrePaisCli: string;
            const ACodigoOficinaContable,
                  ACodigoOrganoGestor,
                  ACodigoUnidadTramitadora: string;
            const ACodigoIva,
                  ATarifa:       string;
            AEsIvaRecargo,
            AEsIvaExento,
            AEsImpInclTarifa:    string;   // 'S'/'N'
            // — totales fiscales —
            APorcIvaN,  ATotalIvaN,  APorcReN,  ATotalReN,  ABaseIN:   Currency;
            APorcIvaR,  ATotalIvaR,  APorcReR,  ATotalReR,  ABaseIR:   Currency;
            APorcIvaS,  ATotalIvaS,  APorcReS,  ATotalReS,  ABaseIS:   Currency;
            APorcIvaE,  ATotalIvaE,  APorcReE,  ATotalReE,  ABaseIE:   Currency;
            ATotalBases,
            ATotalImpuestos,
            ATotalRetencion,
            APorcRetencion,
            ATotalLiquido:       Currency;
            const AFormaPago:    string;
            // — referencias —
            const AComentarios:  string;
            const ASeriAbono,
                  ANroAbono:     string;
            // — caja —
            const AAlmacen,
                  ACaja,
                  ACajero:       string;
            ANumOperacion:       String;
            const AUsuario:      string);
begin
  ConfigurarSqlInsertarCabeceraFacturaCaja(QryTrx);

  // — identificación —
  QryTrx.ParamByName('SERIE').AsString    := ASerie;
  QryTrx.ParamByName('NRO').AsString      := ANro;
  QryTrx.ParamByName('FECHA').AsDate      := AFecha;
  QryTrx.ParamByName('TIPO').AsString     := ATipo;
  QryTrx.ParamByName('FASE').AsString     := AFase;
  // — empresa —
  QryTrx.ParamByName('EMP').AsString      := AEmpresa;
  QryTrx.ParamByName('RSEMP').AsString    := ARazonSocialEmp;
  QryTrx.ParamByName('NIFEMP').AsString   := ANifEmp;
  QryTrx.ParamByName('MOVILEMP').AsString := AMovilEmp;
  QryTrx.ParamByName('EMAILEMP').AsString := AEmailEmp;
  QryTrx.ParamByName('DIR1EMP').AsString  := ADireccion1Emp;
  QryTrx.ParamByName('DIR2EMP').AsString  := ADireccion2Emp;
  QryTrx.ParamByName('POBLEMP').AsString  := APoblacionEmp;
  QryTrx.ParamByName('PROVEMP').AsString  := AProvinciaEmp;
  QryTrx.ParamByName('CPEMP').AsString    := ACPostalEmp;
  QryTrx.ParamByName('PAISEMP').AsString  := ACodigoPaisEmp;
  QryTrx.ParamByName('NPAISEMP').AsString := ANombrePaisEmp;
  QryTrx.ParamByName('RETREMP').AsString  := AEsRetencionesEmp;
  QryTrx.ParamByName('GRUPOIVAEMP').AsString := AGrupoZonaIvaEmp;
  // — cliente —
  QryTrx.ParamByName('CLI').AsString      := ACliente;
  QryTrx.ParamByName('RSCLI').AsString    := ARazonSocialCli;
  QryTrx.ParamByName('NIFCLI').AsString   := ANifCli;
  QryTrx.ParamByName('MOVILCLI').AsString := AMovilCli;
  QryTrx.ParamByName('EMAILCLI').AsString := AEmailCli;
  QryTrx.ParamByName('DIR1CLI').AsString  := ADireccion1Cli;
  QryTrx.ParamByName('DIR2CLI').AsString  := ADireccion2Cli;
  QryTrx.ParamByName('POBLCLI').AsString  := APoblacionCli;
  QryTrx.ParamByName('PROVCLI').AsString  := AProvinciaCli;
  QryTrx.ParamByName('CPCLI').AsString    := ACPostalCli;
  QryTrx.ParamByName('PAISCLI').AsString  := ACodigoPaisCli;
  QryTrx.ParamByName('NPAISCLI').AsString := ANombrePaisCli;
  QryTrx.ParamByName('DIR3OFICINA').AsString := ACodigoOficinaContable;
  QryTrx.ParamByName('DIR3ORGANO').AsString := ACodigoOrganoGestor;
  QryTrx.ParamByName('DIR3UNIDAD').AsString := ACodigoUnidadTramitadora;
  QryTrx.ParamByName('CODIGOIVA').AsString:= ACodigoIva;
  QryTrx.ParamByName('TARIFA').AsString   := ATarifa;
  QryTrx.ParamByName('ESRECARGO').AsString:= AEsIvaRecargo;
  QryTrx.ParamByName('ESEXENTO').AsString := AEsIvaExento;
  QryTrx.ParamByName('ESIMPINCL').AsString:= AEsImpInclTarifa;
  // — totales —
  QryTrx.ParamByName('PIVAN').AsCurrency  := APorcIvaN;
  QryTrx.ParamByName('TIVAN').AsCurrency  := ATotalIvaN;
  QryTrx.ParamByName('PREN').AsCurrency   := APorcReN;
  QryTrx.ParamByName('TREN').AsCurrency   := ATotalReN;
  QryTrx.ParamByName('BASEIN').AsCurrency := ABaseIN;
  QryTrx.ParamByName('PIVAR').AsCurrency  := APorcIvaR;
  QryTrx.ParamByName('TIVAR').AsCurrency  := ATotalIvaR;
  QryTrx.ParamByName('PRER').AsCurrency   := APorcReR;
  QryTrx.ParamByName('TRER').AsCurrency   := ATotalReR;
  QryTrx.ParamByName('BASEIR').AsCurrency := ABaseIR;
  QryTrx.ParamByName('PIVAS').AsCurrency  := APorcIvaS;
  QryTrx.ParamByName('TIVAS').AsCurrency  := ATotalIvaS;
  QryTrx.ParamByName('PRES').AsCurrency   := APorcReS;
  QryTrx.ParamByName('TRES').AsCurrency   := ATotalReS;
  QryTrx.ParamByName('BASEIS').AsCurrency := ABaseIS;
  QryTrx.ParamByName('PIVAE').AsCurrency  := APorcIvaE;
  QryTrx.ParamByName('TIVAE').AsCurrency  := ATotalIvaE;
  QryTrx.ParamByName('PREE').AsCurrency   := APorcReE;
  QryTrx.ParamByName('TREE').AsCurrency   := ATotalReE;
  QryTrx.ParamByName('BASEIE').AsCurrency := ABaseIE;
  QryTrx.ParamByName('TBASES').AsCurrency := ATotalBases;
  QryTrx.ParamByName('TIMPS').AsCurrency  := ATotalImpuestos;
  QryTrx.ParamByName('PRETENC').AsCurrency:= APorcRetencion;
  QryTrx.ParamByName('TRETENC').AsCurrency:= ATotalRetencion;
  QryTrx.ParamByName('TLIQUIDO').AsCurrency:= ATotalLiquido;
  // — referencias y caja —
  QryTrx.ParamByName('FORMAP').AsString   := AFormaPago;
  QryTrx.ParamByName('COMENT').AsString   := AComentarios;
  QryTrx.ParamByName('SERIEABO').AsString := ASeriAbono;
  QryTrx.ParamByName('NROABO').AsString   := ANroAbono;
  QryTrx.ParamByName('ALM').AsString      := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString     := ACaja;
  QryTrx.ParamByName('CAJERO').AsString   := ACajero;
  QryTrx.ParamByName('NUMOP').AsString   := ANumOperacion;
  QryTrx.ParamByName('USUARIO').AsString  := AUsuario;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.InsertarLineaFactura(
            QryTrx:              TUniQuery;
            // — identificación —
            const ASerie:        string;
            const ANro:          string;
            const ALinea:        string;   // '0010', '0020'...
            // — artículo —
            const AArticulo:     string;
            const ASku:          string;
            const ADesc:         string;
            const ADescVariacion:string;
            const AFamilia:      string;
            const ANombreFamilia:string;
            const ATipoArticulo: string;   // 'ESTANDAR', 'SERVICIO', 'KIT'
            const ATipoCantidad: string;   // 'Uds', 'Kg'...
            ACantidad:           Double;
            // — tarifa y precios —
            const ATarifa:       string;
            AEsImpIncl:          string;   // 'S'/'N'
            APrecioSalida:       Currency;
            APorcDto:            Double;
            APrecioDto:          Currency;
            APrecioSIva:         Currency;
            APrecioCIva:         Currency;
            const ATipoIva:      string;   // 'N','R','S','E'
            APorcIva:            Double;
            ATotalSIva:          Currency;
            ATotalCIva:          Currency;
            // — vendedor —
            const AVendedor:     string;
            // — caja y trazabilidad —
            const AEmpresa:      string;
            const AAlmacen:      string;
            const ACaja:         string;
            ANumOperacion:       string;
            // NUMERO_MOV de fza_movimientos_almacen
            const ANumMovAlmacen:string;
            const AUsuario:      string);
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_facturas_lineas (' +
    '  SERIE_FAC_FACLIN, NUMERO_FAC_FACLIN, LINEA_FACLIN,' +
    '  CODIGO_EMP_FACLIN, ' +
    '  CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN,' +
    '  DESCRIPCION_ARTICULO_FACLIN, ' + //DESCRIPCION_VARIACION_FACLIN,' +
    '  CODIGO_FAM_FACLIN, NOMBRE_FAM_FACLIN,' +
    '  TIPO_ARTICULO_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN,' +
    '  CANTIDAD_FACLIN,' +
    '  CODIGO_TAR_FACLIN, ESIMP_INCL_TARIFA_FACLIN,' +
    '  PRECIO_SALIDA_FACLIN,' +
    '  PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN,' +
    '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN,' +
    '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN,' +
    '  TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN,' +
    '  TOTAL_FAC_SIVA_FACLIN, TOTAL_FACLIN,' +
    '  CODIGO_VENDEDOR_FACLIN,' +
    '  CODIGO_ALM_FACLIN, CODIGO_CAJA_FACLIN,' +
    '  NUMERO_OPERACION_FACLIN,' +
    '  NUMERO_MOV_FACLIN,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :SERIE, :NRO, :LINEA,' +
    '  :EMP, ' +
    '  NULLIF(:ART,   ''''), NULLIF(:SKU,    ''''),' +
    '  NULLIF(:DESC,  ''''),' + //NULLIF(:DESCVAR,''''),' +
    '  NULLIF(:FAM,   ''''), NULLIF(:NOMFAM, ''''),' +
    '  :TIPOART, :TIPOCANT,' +
    '  :CANT,' +
    '  NULLIF(:TARIFA,    ''''), :ESIMPINCL,' +
    '  :PRECSALIDA,' +
    '  :PORCDTO, :PRECDTO,' +
    '  :PRECSIVA,' +
    '  :PRECCIVA,' +
    '  :TIPOIVA, :PORCIVA,' +
    '  :TOTALSIVA, :TOTALCIVA,' +
    '  NULLIF(:VENDEDOR,  ''''),' +
    '  NULLIF(:ALM,       ''''), NULLIF(:CAJA, ''''),' +
    '  NULLIF(:NUMOP, ''''),' +
    '  NULLIF(:NUMMOV,    ''''),' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('SERIE').AsString    := ASerie;
  QryTrx.ParamByName('NRO').AsString      := ANro;
  QryTrx.ParamByName('LINEA').AsString    := ALinea;
  QryTrx.ParamByName('EMP').AsString      := AEmpresa;
  QryTrx.ParamByName('ART').AsString      := AArticulo;
  QryTrx.ParamByName('SKU').AsString      := ASku;
  QryTrx.ParamByName('DESC').AsString     := ADesc;
//  QryTrx.ParamByName('DESCVAR').AsString  := ADescVariacion;
  QryTrx.ParamByName('FAM').AsString      := AFamilia;
  QryTrx.ParamByName('NOMFAM').AsString   := ANombreFamilia;
  QryTrx.ParamByName('TIPOART').AsString  := ATipoArticulo;
  QryTrx.ParamByName('TIPOCANT').AsString := ATipoCantidad;
  QryTrx.ParamByName('CANT').AsFloat      := ACantidad;
  QryTrx.ParamByName('TARIFA').AsString   := ATarifa;
  QryTrx.ParamByName('ESIMPINCL').AsString:= AEsImpIncl;
  QryTrx.ParamByName('PRECSALIDA').AsCurrency := APrecioSalida;
  QryTrx.ParamByName('PORCDTO').AsFloat   := APorcDto;
  QryTrx.ParamByName('PRECDTO').AsCurrency:= APrecioDto;
  QryTrx.ParamByName('PRECSIVA').AsCurrency := APrecioSIva;
  QryTrx.ParamByName('PRECCIVA').AsCurrency := APrecioCIva;
  QryTrx.ParamByName('TIPOIVA').AsString  := ATipoIva;
  QryTrx.ParamByName('PORCIVA').AsFloat   := APorcIva;
  QryTrx.ParamByName('TOTALSIVA').AsCurrency := ATotalSIva;
  QryTrx.ParamByName('TOTALCIVA').AsCurrency := ATotalCIva;
  QryTrx.ParamByName('VENDEDOR').AsString := AVendedor;
  QryTrx.ParamByName('ALM').AsString      := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString     := ACaja;
  QryTrx.ParamByName('NUMOP').AsString   := ANumOperacion;
  QryTrx.ParamByName('NUMMOV').AsString   := ANumMovAlmacen;
  QryTrx.ParamByName('USUARIO').AsString  := AUsuario;
  QryTrx.Execute;
end;

end.
