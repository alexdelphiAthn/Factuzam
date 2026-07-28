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
  inLibContextoSesionIntf, inLibParametrosIntf;

type
  TTipoRectificativaCaja = (trcNinguna, trcDiferencias, trcSustitutiva);
  TTratamientoMovimientosRectificativa = (
    tmrMantenerOriginales,
    tmrReemplazarOriginales);

  TDatosCabeceraFactura = record
    // identificación
    Fecha:               TDateTime;
    CodigoCliente:       string;
    // empresa
    RazonSocialEmp:      string;
    NifEmp:              string;
    MovilEmp:            string;
    EmailEmp:            string;
    Direccion1Emp:       string;
    Direccion2Emp:       string;
    PoblacionEmp:        string;
    ProvinciaEmp:        string;
    CPostalEmp:          string;
    CodigoPaisEmp:       string;
    NombrePaisEmp:       string;
    EsRetencionesEmp:    string;
    GrupoZonaIvaEmp:     string;
    // cliente
    RazonSocialCli:      string;
    NifCli:              string;
    MovilCli:            string;
    EmailCli:            string;
    Direccion1Cli:       string;
    Direccion2Cli:       string;
    PoblacionCli:        string;
    ProvinciaCli:        string;
    CPostalCli:          string;
    CodigoPaisCli:       string;
    NombrePaisCli:       string;
    CodigoOficinaContable: string;
    CodigoOrganoGestor:  string;
    CodigoUnidadTramitadora: string;
    CodigoIva:           string;
    Tarifa:              string;
    EsIvaRecargo:        string;
    EsIvaExento:         string;
    EsImpInclTarifa:     string;
    // totales IVA Normal
    PorcIvaN:            Currency;
    TotalIvaN:           Currency;
    PorcReN:             Currency;
    TotalReN:            Currency;
    BaseIN:              Currency;
    // totales IVA Reducido
    PorcIvaR:            Currency;
    TotalIvaR:           Currency;
    PorcReR:             Currency;
    TotalReR:            Currency;
    BaseIR:              Currency;
    // totales IVA Superreducido
    PorcIvaS:            Currency;
    TotalIvaS:           Currency;
    PorcReS:             Currency;
    TotalReS:            Currency;
    BaseIS:              Currency;
    // totales IVA Exento
    PorcIvaE:            Currency;
    TotalIvaE:           Currency;
    PorcReE:             Currency;
    TotalReE:            Currency;
    BaseIE:              Currency;
    // totales generales
    TotalBases:          Currency;
    TotalImpuestos:      Currency;
    TotalRetencion:      Currency;
    PorcRetencion:       Currency;
    TotalLiquido:        Currency;
    // resto
    FormaPago:           string;
    Comentarios:         string;
  end;

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
    qryStock: TUniQuery;
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
                                    const ACliente, ASku, AUsuario: string;
                                    out AIdDeposito: string);
    procedure AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                       const ACliente, ASku, AUsuario: string;
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
      const AParametrosCaja: IParametrosCaja); reintroduce;
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
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
                                         tmrMantenerOriginales):
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

var
  dmCajaOpe: TdmCajaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibValoresAutomaticos,
     inLibData,
     inLibDevExp,
     inLibFacturas,
     inLibVerifactu,
     inLibVerifactuCola,
     inLibGenerarTicketBD,
     inLibDocumentoFiscal,
     inLibLicenciaAplicacion,
     inLibRectificativas,
     inLibMsg;

{$R *.dfm}

constructor TdmCajaOpe.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja);
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

function TdmCajaOpe.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function LeerCabecera(cdsCabecera:TDataset): TDatosCabeceraFactura;
begin
  with cdsCabecera do
  begin
    Result.Fecha           := FieldByName('FECHA_FAC').AsDateTime;
    Result.CodigoCliente   := FieldByName('CODIGO_CLI_FAC').AsString;
    Result.RazonSocialEmp  := FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString;
    Result.NifEmp          := FieldByName('NIF_EMPRESA_FAC').AsString;
    Result.MovilEmp        := FieldByName('MOVIL_EMPRESA_FAC').AsString;
    Result.EmailEmp        := FieldByName('EMAIL_EMPRESA_FAC').AsString;
    Result.Direccion1Emp   := FieldByName('DIRECCION1_EMPRESA_FAC').AsString;
    Result.Direccion2Emp   := FieldByName('DIRECCION2_EMPRESA_FAC').AsString;
    Result.PoblacionEmp    := FieldByName('POBLACION_EMPRESA_FAC').AsString;
    Result.ProvinciaEmp    := FieldByName('PROVINCIA_EMPRESA_FAC').AsString;
    Result.CPostalEmp      := FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString;
    Result.CodigoPaisEmp   := FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString;
    Result.NombrePaisEmp   := FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString;
    Result.EsRetencionesEmp:= FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString;
    Result.GrupoZonaIvaEmp :=
      FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
    Result.RazonSocialCli  := FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString;
    Result.NifCli          := FieldByName('NIF_CLIENTE_FAC').AsString;
    Result.MovilCli        := FieldByName('MOVIL_CLIENTE_FAC').AsString;
    Result.EmailCli        := FieldByName('EMAIL_CLIENTE_FAC').AsString;
    Result.Direccion1Cli   := FieldByName('DIRECCION1_CLIENTE_FAC').AsString;
    Result.Direccion2Cli   := FieldByName('DIRECCION2_CLIENTE_FAC').AsString;
    Result.PoblacionCli    := FieldByName('POBLACION_CLIENTE_FAC').AsString;
    Result.ProvinciaCli    := FieldByName('PROVINCIA_CLIENTE_FAC').AsString;
    Result.CPostalCli      := FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString;
    Result.CodigoPaisCli   := FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString;
    Result.NombrePaisCli   := FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString;
    if FindField('CODIGO_OFICINA_CONTABLE_FAC') <> nil then
      Result.CodigoOficinaContable :=
        FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString;
    if FindField('CODIGO_ORGANO_GESTOR_FAC') <> nil then
      Result.CodigoOrganoGestor :=
        FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString;
    if FindField('CODIGO_UNIDAD_TRAMITADORA_FAC') <> nil then
      Result.CodigoUnidadTramitadora :=
        FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString;
    Result.CodigoIva       := FieldByName('CODIGO_IVA_FAC').AsString;
    Result.Tarifa := FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    Result.EsIvaRecargo    := FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString;
    Result.EsIvaExento     := FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString;
    Result.EsImpInclTarifa :=
      FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
    Result.PorcIvaN        := FieldByName('PORCENTAJE_IVAN_FAC').AsCurrency;
    Result.TotalIvaN       := FieldByName('TOTAL_IVAN_FAC').AsCurrency;
    Result.PorcReN         := FieldByName('PORCENTAJE_REN_FAC').AsCurrency;
    Result.TotalReN        := FieldByName('TOTAL_REN_FAC').AsCurrency;
    Result.BaseIN          := FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
    Result.PorcIvaR        := FieldByName('PORCENTAJE_IVAR_FAC').AsCurrency;
    Result.TotalIvaR       := FieldByName('TOTAL_IVAR_FAC').AsCurrency;
    Result.PorcReR         := FieldByName('PORCENTAJE_RER_FAC').AsCurrency;
    Result.TotalReR        := FieldByName('TOTAL_RER_FAC').AsCurrency;
    Result.BaseIR          := FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
    Result.PorcIvaS        := FieldByName('PORCENTAJE_IVAS_FAC').AsCurrency;
    Result.TotalIvaS       := FieldByName('TOTAL_IVAS_FAC').AsCurrency;
    Result.PorcReS         := FieldByName('PORCENTAJE_RES_FAC').AsCurrency;
    Result.TotalReS        := FieldByName('TOTAL_RES_FAC').AsCurrency;
    Result.BaseIS          := FieldByName('TOTAL_BASEI_IVAS_FAC').AsCurrency;
    Result.PorcIvaE        := FieldByName('PORCENTAJE_IVAE_FAC').AsCurrency;
    Result.TotalIvaE       := FieldByName('TOTAL_IVAE_FAC').AsCurrency;
    Result.PorcReE         := FieldByName('PORCENTAJE_REE_FAC').AsCurrency;
    Result.TotalReE        := FieldByName('TOTAL_REE_FAC').AsCurrency;
    Result.BaseIE          := FieldByName('TOTAL_BASEI_IVAE_FAC').AsCurrency;
    Result.TotalBases      := FieldByName('TOTAL_BASES_FAC').AsCurrency;
    Result.TotalImpuestos  := FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
    Result.TotalRetencion  := FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
    Result.PorcRetencion := FieldByName('PORCENTAJE_RETENCION_FAC').AsCurrency;
    Result.TotalLiquido    := FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
    Result.FormaPago       := FieldByName('FORMA_PAGO_FAC').AsString;
    Result.Comentarios     := FieldByName('COMENTARIOS_FAC').AsString;
  end;
end;

function LeerLineaActual(cdsLineas:TDataset): TDatosLineaFactura;
begin
  with cdsLineas do
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
begin
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
        '   AND d.ESTADO_DEP = ''PENDIENTE''';
    QryDep.ParamByName('CLI').AsString := ACodigoCliente;
    QryDep.Open;
    if QryDep.IsEmpty then Exit;
    cdsLineas.DisableControls;
    try
      while not QryDep.Eof do
      begin
        IdDeposito        := QryDep.FieldByName('ID_DEPOSITO_DEP').AsString;
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
        FechaCreacion     := QryDep.FieldByName('FECHA_CREACION_DEP').AsDateTime;
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
    // Recalculo UNA SOLA VEZ al final, fuera del bucle.
    if Assigned(FOnRecalcularLineas) then
      FOnRecalcularLineas;
  finally
    FreeAndNil(QryDep);
  end;
end;

procedure TdmCajaOpe.CerrarDepositoCliente(QryTrx: TUniQuery;
                                           const ACliente,
                                                 ASku,
                                                 AUsuario: string;
                                           out AIdDeposito:string);
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := QryTrx.Connection;
    SpTrx.StoredProcName := 'PRC_FZA_DEPOSITOS_UPDATE';
    SpTrx.PrepareSQL;
    SpTrx.ParamByName('SKU').AsString          := ASku;
    SpTrx.ParamByName('CLI').AsString          := ACliente;
    SpTrx.ParamByName('ESTADO').AsString       := 'CERRADO';
    SpTrx.ParamByName('INC_ANTICIPO').AsCurrency := 0;
    SpTrx.ParamByName('USUARIO').AsString      := AUsuario;
    SpTrx.Execute;
    AIdDeposito := SpTrx.ParamByName('P_ID_DEPOSITO').AsString;
  finally
    FreeAndNil(SpTrx);
  end;

end;

procedure TdmCajaOpe.TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                     DineroEntregado: Currency);
var
  TotalLinea, DineroDisponible: Currency;
  VieneDeDep, AccionDep: string;
  AnticipoRecuperado: Currency;

  procedure EliminarLineaAbono(const AIdDeposito: string);
  var
    Bkm: TBookmark;
  begin
    if Trim(AIdDeposito) = '' then Exit;
    Bkm := (cdsLineas as TClientDataSet).GetBookmark;
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if (cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'A') and
         (cdsLineas.FieldByName('ID_DEPOSITO_DEP').AsString = AIdDeposito) then
      begin
        cdsLineas.Delete;
        Break;
      end;
      cdsLineas.Next;
    end;
    if (cdsLineas as TClientDataSet).BookmarkValid(Bkm) then
      (cdsLineas as TClientDataSet).GotoBookmark(Bkm);
    (cdsLineas as TClientDataSet).FreeBookmark(Bkm);
  end;

  procedure ProcesarLinea;
  var
    AnticipoPrevio: Currency;
    SkuLinea, TipoIVALinea, EsImpInclLinea, IdDepLinea: string;
    PorcIVALinea: Currency;
    DineroReal: Currency;
  begin
    IdDepLinea     := cdsLineas.FieldByName('ID_DEPOSITO_DEP').AsString;
    TotalLinea     := cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
    AnticipoPrevio := cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
    SkuLinea       := cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
    TipoIVALinea   := cdsLineas.FieldByName(
                                     'TIPO_IVA_ARTICULO_FACLIN').AsString;
    PorcIVALinea   := cdsLineas.FieldByName(
                                         'PORCENTAJE_IVA_FACLIN').AsCurrency;
    EsImpInclLinea := cdsLineas.FieldByName(
                                    'ESIMP_INCL_TARIFA_FACLIN').AsString;
    DineroReal := DineroDisponible + AnticipoPrevio;
    if DineroReal >= TotalLinea then
    begin
      DineroDisponible := DineroDisponible - (TotalLinea - AnticipoPrevio);
      cdsLineas.Next;
    end
    else
    begin
      cdsLineas.Edit;
      if cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'AUMENTAR_DEP'
      else
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'NUEVO_DEP';
      var sDesc :=
           cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
      if Pos('Abono ', sDesc) <> 1 then
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
                                                      'Abono a cuenta ' + sDesc;
      cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency := TotalLinea;
      cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
                                                               DineroDisponible;
      cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := DineroDisponible;
      if PorcIVALinea = 0 then
        cdsLineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
                                                                DineroDisponible
      else
        cdsLineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
            DineroDisponible / (1 + (PorcIVALinea / 100));

      cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat         := 1;
      cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat       := 0;
      cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency    := 0;
      cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency         :=
                                                               DineroDisponible;
      cdsLineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency     :=
          cdsLineas.FieldByName(
                          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency;
      cdsLineas.Post;
      EliminarLineaAbono(IdDepLinea);
      DineroDisponible := 0;
      cdsLineas.Next;
    end;
  end;

begin
  DineroDisponible := DineroEntregado;
  cdsLineas.DisableControls;
  try
    // =========================================================================
    // PASO 0: Sumar SOLO abonos de devoluciones reales
    // =========================================================================
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if (cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency < 0) and
         (cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString <> 'A') then
        DineroDisponible := DineroDisponible -
                        cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
      cdsLineas.Next;
    end;
    // =========================================================================
    // PASO 0.5: Cancelaciones explícitas de la interfaz
    // =========================================================================
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      VieneDeDep := cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      AccionDep  := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;
      if (VieneDeDep = 'S') and (AccionDep = 'CANCELAR') then
      begin
        AnticipoRecuperado :=
          cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
        if AnticipoRecuperado > 0 then
          DineroDisponible := DineroDisponible + AnticipoRecuperado;
      end;
      cdsLineas.Next;
    end;
    // =========================================================================
    // PASO 1: Prioridad absoluta — depósitos existentes del cliente
    // =========================================================================
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      VieneDeDep := cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      AccionDep  := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;

      if (VieneDeDep = 'S') and (AccionDep = 'COBRAR') and
         (cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency > 0) then
      begin
        ProcesarLinea;
      end
      else
        cdsLineas.Next;
    end;
    // =========================================================================
    // PASO 2: Prendas nuevas de hoy
    // =========================================================================
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      VieneDeDep := cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      AccionDep  := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;
      if (VieneDeDep <> 'S') and (VieneDeDep <> 'A') and
           ((AccionDep = 'COBRAR') or (AccionDep = '')) and
           (cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency > 0) then
      begin
        if DineroDisponible > 0 then
          ProcesarLinea
        else
        begin
          // Sin dinero pero la prenda se aparta → NUEVO_DEP con anticipo 0
          cdsLineas.Edit;
          cdsLineas.FieldByName('ACCION_DEPOSITO').AsString      := 'NUEVO_DEP';
          cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency    :=
                        cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
          cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency   := 0;
          cdsLineas.FieldByName(
            'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
          cdsLineas.FieldByName(
            'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
          cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency          := 0;
          cdsLineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency      := 0;
          cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat        := 0;
          cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency     := 0;
          cdsLineas.Post;
          cdsLineas.Next;
        end;
      end
      else
        cdsLineas.Next;
    end;
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
                                              const ACliente,
                                                    ASku,
                                                    AUsuario: string;
                                              ANuevoAbono: Currency);
var
  SpTrx:TUniStoredProc;
begin
  if ANuevoAbono <= 0 then Exit;
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := QryTrx.Connection;
    SpTrx.StoredProcName := 'PRC_FZA_DEPOSITOS_UPDATE';
    SpTrx.PrepareSQL;
    SpTrx.ParamByName('SKU').AsString            := ASku;
    SpTrx.ParamByName('CLI').AsString            := ACliente;
    SpTrx.ParamByName('ESTADO').Clear;
    SpTrx.ParamByName('INC_ANTICIPO').AsCurrency := ANuevoAbono;
    SpTrx.ParamByName('USUARIO').AsString        := AUsuario;
    SpTrx.Execute;
  finally
    FreeAndNil(SpTrx);
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

function TdmCajaOpe.GrabarFacturaSimplificada(
                          const AEmpresa,
                                AAlmacen,
                                ACaja,
                                ASerieElegida: string;
                          DatosCobro:          TDatosFaseCobro;
                          SerieGenerada:   string;
                          out NumeroGenerado:  string;
                          out ValeGenerado:    string;
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
                              tmrMantenerOriginales): Boolean;
var
  QryTrx:              TUniQuery;
  uspQryTrx:           TUniStoredProc;
  Cab:                 TDatosCabeceraFactura;
  Lin:                 TDatosLineaFactura;
  NumOperacionVE:      String;
  TotalFactura:        Currency;
  AlmacenDeposito,
  AlmacenOrigenSalida,
  TipoMov,
  NumMovGenerado:      string;
  NumFactura:          string;
  UsuarioCaja:         string;
  NumLineaPago:        Integer;
  RequiereFactura:     Boolean;
  TieneDepositosPendientes:boolean;
  TotalVentasNormales, TotalDevolucionesNormales: Currency;
  FechaOperacion: TDateTime;
  sConceptoOperacion: string;
  sTipoRectificativaFiscal: string;
  bGenerarMovimientos: Boolean;
  // ---------------------------------------------------------------------------
  // Inserta línea fiscal de anticipo (Solo si hay factura)
  // ---------------------------------------------------------------------------
procedure InsertarLineaAnticipo(const Lin: TDatosLineaFactura;
                                  AImporte: Currency);
  var
    PrecioBase: Currency;
  begin
    if not RequiereFactura then
      Exit;
    if Lin.PorcIva = 0 then
      PrecioBase := AImporte
    else
      PrecioBase := AImporte / (1 + Lin.PorcIva / 100);
    InsertarLineaFactura(
      QryTrx, SerieGenerada, NumFactura,
      Lin.Linea, 'ANTICIPO', 'ANTICIPO',
      Lin.Descripcion, '', '', '', 'SERVICIO', 'Uds',
      1, '', 'S', PrecioBase, 0, 0, PrecioBase, AImporte,
      Lin.TipoIva, Lin.PorcIva, PrecioBase, AImporte,
      Lin.Vendedor, AEmpresa, AAlmacen, ACaja, NumOperacionVE, '', UsuarioCaja);
  end;

begin
  SerieGenerada  := ASerieElegida;
  NumFactura  := '0';
  FUltSerieFacGrabada  := '';
  FUltNumeroFacGrabada := '';
  ValeGenerado   := '';
  FechaOperacion := FechaCajaConHora(AFechaOperacion);
  UsuarioCaja     := cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
  case ATipoRectificativa of
    trcDiferencias:
      begin
        sConceptoOperacion := 'Rectificativa por diferencias';
        sTipoRectificativaFiscal := 'I';
      end;
    trcSustitutiva:
      begin
        sConceptoOperacion := 'Rectificativa sustitutiva';
        sTipoRectificativaFiscal := 'S';
      end;
  else
    begin
      sConceptoOperacion := '';
      sTipoRectificativaFiscal := '';
    end;
  end;
  bGenerarMovimientos := DebeGenerarMovimientosRectificativa(
    sTipoRectificativaFiscal,
    ATratamientoMovimientos = tmrReemplazarOriginales);
  if (sConceptoOperacion <> '') and
     (Trim(ASerieRectificada) <> '') and
     (Trim(ANumeroRectificado) <> '') then
    sConceptoOperacion := sConceptoOperacion + ' de ' +
      ASerieRectificada + '\' + ANumeroRectificado;
  // Generamos el número global de caja que agrupará toda la operación
  AlmacenDeposito := ObtenerAlmacenDepositoEmpresa(FConexion, AEmpresa);
  if cdsCabecera.State in [dsEdit, dsInsert] then cdsCabecera.Post;
  if cdsLineas.State   in [dsEdit, dsInsert] then cdsLineas.Post;
  if cdsLineas.IsEmpty then
    raise Exception.Create(SErrorOperacionCajaSinLineas);
  Cab          := LeerCabecera(cdsCabecera);
  // Factura completa desde F8: fecha elegida en el modal de fase cobro
  if AFechaFactura > 0 then
    Cab.Fecha := AFechaFactura;
  TotalFactura := DatosCobro.ImporteEntregado;
  // =======================================================================
  // 0. FILTRO DE NOVEDAD (Cero novedad = cero operaciones en BD)
  // =======================================================================
  var HayNovedad := False;

  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      var sAccion := Trim(cdsLineas.FieldByName('ACCION_DEPOSITO').AsString);
      // Novedad tambien cuando hay devolucion (total negativo o
      // lineas devueltas) o se emite un vale como reembolso: en esos
      // casos el cliente no entrega dinero (ImporteEntregado = 0) y
      // sin esto la operacion se descartaba sin grabar.
      if (DatosCobro.ImporteEntregado > 0) or
         DatosCobro.EsDevolucionEconomica or
         DatosCobro.TieneArticulosDevueltos or
         (DatosCobro.ImporteValeEmitido > 0) or
         (sAccion = 'CANCELAR') or
         (sAccion = 'NUEVO_DEP') then
      begin
        HayNovedad := True;
        Break;
      end;
      cdsLineas.Next;
    end;
  finally
    cdsLineas.EnableControls;
  end;
  if not HayNovedad then
  begin
    ImprimirRecordatorio(FConexion, FContextoSesion.Ubicacion.Empresa,
      Cab.CodigoCliente,
      FParametrosCaja.ImpresoraCaja);
    Result := True;
    Exit;
  end;
  // =======================================================================
  // PASO 0.5: DETERMINAR SI REQUIERE FACTURA (TICKET)
  // =======================================================================
  RequiereFactura := False;
  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      var Accion := Trim(cdsLineas.FieldByName('ACCION_DEPOSITO').AsString);
      if (Accion = '') or (Accion = 'COBRAR') then
      begin
        RequiereFactura := True;
        Break;
      end;
      if (Accion = 'CANCELAR') then
      begin
        if cdsCabecera.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency <> 0 then
        begin
          RequiereFactura := True;
          Break;
        end;
      end;
      if (Accion = 'NUEVO_DEP') or (Accion = 'AUMENTAR_DEP') then
      begin
        if cdsCabecera.FieldByName(
                                'TOTAL_LIQUIDO_FAC').AsCurrency > 0.001 then
        begin
          RequiereFactura := True;
          Break;
        end;
      end;
      cdsLineas.Next;
    end;
  finally
    cdsLineas.EnableControls;
  end;
  DatosCobro.FRequiereFactura := RequiereFactura;
  if RequiereFactura and SameText(ATipoFactura, 'NORMAL') then
  begin
    if Trim(Cab.RazonSocialCli) = '' then
      raise Exception.Create(SErrorRazonSocialClienteFacturaCajaObligatoria);
    if PaisEsEspana(Cab.CodigoPaisCli, Cab.NombrePaisCli) and
       (not DocumentoFiscalValido(Cab.NifCli)) then
      raise Exception.Create(SErrorDocumentoFiscalClienteCajaNoValido +
        MensajeDocumentoFiscalInvalido(Cab.NifCli));
    if PaisEsEspana(Cab.CodigoPaisEmp, Cab.NombrePaisEmp) and
       (not DocumentoFiscalValido(Cab.NifEmp)) then
      raise Exception.Create(SErrorDocumentoFiscalEmpresaCajaNoValido +
        MensajeDocumentoFiscalInvalido(Cab.NifEmp));
  end;
  // =======================================================================
  // CONTROL DE FECHA POR SERIE (correlatividad temporal)
  // El ticket no puede llevar una fecha anterior a la del ultimo ticket ya
  // emitido en la misma serie. Si la fecha de caja es menor se aborta la
  // venta antes de abrir transaccion (sin consumir numeracion) y se avisa
  // sugiriendo cambiar de serie. No aplica a operaciones sin factura.
  // =======================================================================
  if RequiereFactura and (ANumeroManual = '') then
  begin
    var dUltimaFechaSerie := FechaUltimoTicketSerie(
      FConexion,
      AEmpresa,
      ASerieElegida);
    if (dUltimaFechaSerie > 0) and
       (Trunc(Cab.Fecha) < Trunc(dUltimaFechaSerie)) then
      raise Exception.CreateFmt(
        SErrorFechaTicketSerieNoValida,
        [ASerieElegida,
         FormatDateTime('dd/mm/yyyy', dUltimaFechaSerie),
         FormatDateTime('dd/mm/yyyy', Cab.Fecha)]);
  end;
  if RequiereFactura and FParametrosApp.Licencia.Comprobada then
    ValidarLimiteDemoFacturas(FConexion,
                              FParametrosApp.Licencia.Estado,
                              Cab.Fecha);
  if DatosCobro.ImporteEntregado <
                cdsCabecera.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency then
  begin
    TransformarLineasParaCobroParcial(cdsLineas, DatosCobro.ImporteEntregado);
    if not CuadrarFacturaEnMemoria(cdsCabecera, cdsLineas) then
      raise Exception.Create(SErrorCuadreCobroParcialCaja);
    Cab := LeerCabecera(cdsCabecera);
    if AFechaFactura > 0 then
      Cab.Fecha := AFechaFactura;
  end;
  // =======================================================================
  // INICIO DE LA TRANSACCIÓN GLOBAL EN BASE DE DATOS
  // =======================================================================
  FConexion.StartTransaction;
  var sOpeCaja := SiguienteOpCaja(AEmpresa, AAlmacen, ACaja, UsuarioCaja);
  NumOperacionVE := sOpeCaja;
  NumeroGenerado := sOpeCaja;
  QryTrx := TUniQuery.Create(nil);
  try try
    QryTrx.Connection := FConexion;
    // =======================================================================
    // PASO 1 Y 3: NÚMERO Y CABECERA (SOLO SI REQUIERE FACTURA)
    // =======================================================================
    if RequiereFactura then
    begin
      if ANumeroManual <> '' then
        // Relleno de hueco: el usuario indica el numero. No se llama al
        // contador (PRC_GET_NEXT_CONT_FACT_SERIE) ni se avanza la serie.
        NumFactura := ANumeroManual
      else
      begin
        uspQryTrx := TUniStoredProc.Create(nil);
        try
          uspQryTrx.Connection := FConexion;
          uspQryTrx.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
          uspQryTrx.Prepare;
          uspQryTrx.ParamByName('pserie').AsString   := SerieGenerada;
          uspQryTrx.ParamByName('pTipoDoc').AsString := 'FC';
          uspQryTrx.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
          uspQryTrx.ParamByName('pUSUARIOMODIF').AsString := UsuarioCaja;
          uspQryTrx.Execute;
          NumFactura := uspQryTrx.ParamByName('pcont').AsString;
        finally
          FreeAndNil(uspQryTrx);
        end;
      end;
      DatosCobro.TotalesFactura.Cabecera.Edit;
      DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                    'SERIE_FAC').AsString := ASerieElegida;
      DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                    'NUMERO_FAC').AsString := NumFactura;
      DatosCobro.TotalesFactura.Cabecera.Post;
      InsertarCabeceraFactura(
        QryTrx, SerieGenerada, NumFactura, Cab.Fecha, ATipoFactura,
        'BORRADOR', AEmpresa, Cab.RazonSocialEmp, Cab.NifEmp, Cab.MovilEmp,
        Cab.EmailEmp,Cab.Direccion1Emp, Cab.Direccion2Emp, Cab.PoblacionEmp,
        Cab.ProvinciaEmp, Cab.CPostalEmp, Cab.CodigoPaisEmp, Cab.NombrePaisEmp,
        Cab.EsRetencionesEmp, Cab.GrupoZonaIvaEmp, Cab.CodigoCliente,
        Cab.RazonSocialCli, Cab.NifCli, Cab.MovilCli, Cab.EmailCli,
        Cab.Direccion1Cli, Cab.Direccion2Cli,
        Cab.PoblacionCli, Cab.ProvinciaCli, Cab.CPostalCli, Cab.CodigoPaisCli,
        Cab.NombrePaisCli, Cab.CodigoOficinaContable, Cab.CodigoOrganoGestor,
        Cab.CodigoUnidadTramitadora, Cab.CodigoIva, Cab.Tarifa,
        Cab.EsIvaRecargo, Cab.EsIvaExento, Cab.EsImpInclTarifa,
        Cab.PorcIvaN, Cab.TotalIvaN, Cab.PorcReN, Cab.TotalReN, Cab.BaseIN,
        Cab.PorcIvaR, Cab.TotalIvaR, Cab.PorcReR, Cab.TotalReR, Cab.BaseIR,
        Cab.PorcIvaS, Cab.TotalIvaS, Cab.PorcReS, Cab.TotalReS, Cab.BaseIS,
        Cab.PorcIvaE, Cab.TotalIvaE, Cab.PorcReE, Cab.TotalReE, Cab.BaseIE,
        Cab.TotalBases, Cab.TotalImpuestos, Cab.TotalRetencion,
        Cab.PorcRetencion, Cab.TotalLiquido, Cab.FormaPago, Cab.Comentarios,
        '', '', AAlmacen, ACaja, UsuarioCaja, NumOperacionVE, UsuarioCaja);
      // Serie/numero reales de la factura recien creada, para que la cola
      // y la rectificativa Verifactu no dependan de cdsCabecera (queda '0')
      FUltSerieFacGrabada  := SerieGenerada;
      FUltNumeroFacGrabada := NumFactura;
    end
    else
    begin
      SerieGenerada := '';
      NumFactura := '0';
    end;
    TotalVentasNormales := 0;
    TotalDevolucionesNormales := 0;
    // =======================================================================
    // PASO 4: LÍNEAS
    // =======================================================================
    cdsLineas.DisableControls;
    try
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        Lin := LeerLineaActual(cdsLineas);
        Lin.Vendedor := Trim(Lin.Vendedor);
        if Lin.Vendedor = '' then
          Lin.Vendedor := UsuarioCaja;
        // -------------------------------------------------------------------
        // CASO A: ABONO DE ANTICIPO PREVIO
        // -------------------------------------------------------------------
        if Lin.VieneDeDeposito = 'A' then
        begin
          if RequiereFactura and (Abs(Lin.TotalCIva) > 0.001) then
            InsertarLineaFactura(
              QryTrx, SerieGenerada, NumFactura, Lin.Linea, Lin.Articulo,
              Lin.Sku, Lin.Descripcion, Lin.DescripcionVariacion, Lin.Familia,
              Lin.NombreFamilia, Lin.TipoArticulo, Lin.TipoCantidad,
              Lin.Cantidad, Lin.Tarifa, Lin.EsImpIncl, Lin.PrecioSalida,
              Lin.PorcDto, Lin.PrecioDto, Lin.PrecioSIva, Lin.PrecioCIva,
              Lin.TipoIva, Lin.PorcIva, Lin.TotalSIva, Lin.TotalCIva,
              Lin.Vendedor, AEmpresa, AAlmacen, ACaja, NumOperacionVE, '',
              UsuarioCaja);
          if Abs(Lin.TotalCIva) > 0.001 then
            InsertarOperacionCaja(
              QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'CB',
              Lin.TotalCIva, UsuarioCaja, FechaOperacion, NumFactura,
              SerieGenerada,
              Cab.CodigoCliente, 'Consumo de anticipo: ' + Lin.Descripcion,
              '', '', '', '', '', 'N', Lin.idDeposito);
          cdsLineas.Next;
          Continue;
        end;
        // -------------------------------------------------------------------
        // CASO C: NUEVO DEPÓSITO O AUMENTO DE ANTICIPO
        // -------------------------------------------------------------------
        if (Lin.AccionDeposito = 'NUEVO_DEP') or
           (Lin.AccionDeposito = 'AUMENTAR_DEP') then
        begin
          if Lin.TotalCIva > 0 then
            InsertarLineaAnticipo(Lin, Lin.TotalCIva);
          if Lin.AccionDeposito = 'AUMENTAR_DEP' then
          begin
            AumentarAnticipoDeposito(QryTrx, Cab.CodigoCliente,
                                     Lin.Sku, UsuarioCaja, Lin.TotalCIva);
            if Lin.TotalCIva > 0 then
              InsertarOperacionCaja(
                QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'CB',
                Lin.TotalCIva, UsuarioCaja, FechaOperacion, NumFactura,
                SerieGenerada,
                Cab.CodigoCliente, 'Cobro a cuenta: ' + Lin.Descripcion,
                '', '', '', '', '', 'N', lin.idDeposito);
          end
          else
          begin
            var IdDepGenerado:String := '';
            CrearNuevoDepositoCliente(
              QryTrx, AEmpresa, Cab.CodigoCliente, Lin.Articulo, Lin.Sku,
              UsuarioCaja,
              Lin.PrecioOriginalDep, Lin.TotalCIva, AAlmacen, AlmacenDeposito,
              Lin.Cantidad, Lin.TipoIva, Lin.PorcIva, Lin.EsImpIncl,
              ACaja,
              sOpeCaja, FechaOperacion, IdDepGenerado);
            InsertarOperacionCaja(
              QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'DE', Lin.TotalCIva,
              UsuarioCaja, FechaOperacion, NumFactura, SerieGenerada,
              Cab.CodigoCliente,
              'Depósito: ' + Lin.Descripcion,
              '', '', '', '', '', 'N',
              IdDepGenerado);
          end;
          cdsLineas.Next;
          Continue;
        end;
        // -------------------------------------------------------------------
        // CASO D: VENTA NORMAL O COBRO TOTAL DE DEPÓSITO EXISTENTE
        // -------------------------------------------------------------------
        if (Lin.TipoArticulo = 'ESTANDAR') and bGenerarMovimientos then
          NumMovGenerado := ObtenerSiguienteContador(
            FConexion,
            'MV',
            IdentidadSesion.Usuario)
        else
          NumMovGenerado := '';
        if Lin.VieneDeDeposito = 'S' then
        begin
          var idDep:String := '';
          AlmacenOrigenSalida := AlmacenDeposito;
          CerrarDepositoCliente(QryTrx, Cab.CodigoCliente, Lin.Sku,
                                UsuarioCaja, idDep);
          // ¡CORRECCIÓN! Usar Lin.TotalCIva si PrecioOriginalDep venía a cero
          var ImporteCierreDE := Lin.PrecioOriginalDep;
          if ImporteCierreDE = 0 then ImporteCierreDE := Lin.TotalCIva;
          InsertarOperacionCaja(QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja,
            'DE', -ImporteCierreDE, UsuarioCaja, FechaOperacion, NumFactura,
            SerieGenerada, Cab.CodigoCliente, 'Cierre depósito: ' +
            Lin.Descripcion, '', '', '', '', '', 'N', idDep);
          InsertarOperacionCaja(
            QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VE', Lin.TotalCIva,
            UsuarioCaja, FechaOperacion, NumFactura, SerieGenerada,
            Cab.CodigoCliente,
            'Venta depósito: ' + Lin.Descripcion,
            '', '', '', '', '', 'N', idDep);
        end
        else
        begin
          AlmacenOrigenSalida := AAlmacen;
          if Lin.TotalCIva > 0 then
            TotalVentasNormales := TotalVentasNormales + Lin.TotalCIva
          else
            TotalDevolucionesNormales :=
              TotalDevolucionesNormales + Abs(Lin.TotalCIva);
        end;
        if Lin.Cantidad < 0 then
          TipoMov := 'E'
        else
          TipoMov := 'S';
        if RequiereFactura and (Abs(Lin.TotalCIva) > 0.001) then
        begin
          InsertarLineaFactura(
            QryTrx, SerieGenerada, NumFactura, Lin.Linea, Lin.Articulo,
            Lin.Sku, Lin.Descripcion, Lin.DescripcionVariacion, Lin.Familia,
            Lin.NombreFamilia, Lin.TipoArticulo, Lin.TipoCantidad,
            Lin.Cantidad,
            Lin.Tarifa, Lin.EsImpIncl, Lin.PrecioSalida, Lin.PorcDto,
            Lin.PrecioDto, Lin.PrecioSIva, Lin.PrecioCIva, Lin.TipoIva,
            Lin.PorcIva, Lin.TotalSIva, Lin.TotalCIva, Lin.Vendedor, AEmpresa,
            AAlmacen, ACaja, NumOperacionVE, NumMovGenerado, UsuarioCaja);
        end;
        if (Lin.TipoArticulo = 'ESTANDAR') and bGenerarMovimientos then
          InsertarMovimientoAlmacen(
            QryTrx, 'VE', SerieGenerada, NumFactura, Lin.Linea,
            AEmpresa, AlmacenOrigenSalida, ACaja, '', TipoMov, Lin.Sku,
            Lin.Cantidad, 0, UsuarioCaja, AAlmacen, NumOperacionVE,
            Cab.CodigoCliente, Lin.Articulo, FechaOperacion,
            NumMovGenerado);
        cdsLineas.Next;
      end;
    finally
      cdsLineas.EnableControls;
    end;
    // =======================================================================
    // PASO 4.1: SINCRONIZAR CONTADOR_LINEAS_FAC CON LA ULTIMA LINEA INSERTADA
    // El INSERT de cabecera no lo escribe, asi que al reabrir la factura
    // desde inMtoFacturasBase el calculo del siguiente nro de linea arrancaria
    // desde 0 y chocaria con la PK '...-010'.
    // =======================================================================
    if RequiereFactura then
    begin
      QryTrx.SQL.Text :=
        'UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = (' +
        '  SELECT LPAD(IFNULL(MAX(CAST(LINEA_FACLIN AS UNSIGNED)),0),3,''0'')' +
        '    FROM fza_facturas_lineas' +
        '   WHERE NUMERO_FAC_FACLIN = :pnumfac' +
        '     AND SERIE_FAC_FACLIN  = :pserie' +
        ') WHERE NUMERO_FAC = :pnumfac AND SERIE_FAC = :pserie';
      QryTrx.ParamByName('pnumfac').AsString := NumFactura;
      QryTrx.ParamByName('pserie').AsString  := SerieGenerada;
      QryTrx.Execute;
    end;
    // =======================================================================
    // PASO 4.5: REGISTRAR EL TOTAL DE LA VENTA NORMAL EN CAJA
    // =======================================================================
    if RequiereFactura then
    begin
      // Solo registra operación si realmente hubo alguna venta de tienda normal
      if TotalVentasNormales > 0 then
      begin
        if ATipoRectificativa = trcNinguna then
          sConceptoOperacion := 'Venta';
        InsertarOperacionCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VE',
          TotalVentasNormales, UsuarioCaja, FechaOperacion, NumFactura,
          SerieGenerada,
          Cab.CodigoCliente, sConceptoOperacion, ASerieRectificada,
          ANumeroRectificado);
      end;
      if TotalDevolucionesNormales > 0 then
      begin
        if ATipoRectificativa = trcNinguna then
          sConceptoOperacion := 'Devolución de Venta';
        InsertarOperacionCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'DV',
          -TotalDevolucionesNormales, UsuarioCaja, FechaOperacion, NumFactura,
          SerieGenerada,
          Cab.CodigoCliente, sConceptoOperacion, ASerieRectificada,
          ANumeroRectificado);
      end;
    end;
    // =======================================================================
    // PASO 4.6: REGISTRO FISCAL
    // Dentro de la transacción: la factura nace con su registro fiscal.
    // El modo fiscal decide si se encola en AEAT, se registra localmente
    // como NO VERI*FACTU o se marca como SIN VERIFACTU.
    // =======================================================================
    if RequiereFactura then
    begin
      if SameText(ATipoFactura, 'RECTIFICATIVA') then
      begin
        if (Trim(ASerieRectificada) = '') or
           (Trim(ANumeroRectificado) = '') then
          raise Exception.Create(SErrorFacturaRectificativaCajaSinOriginal);
        TVerifactuCola.EncolarRectificativa(
          FParametrosApp,
          FParametrosCaja,
          FConexion,
          IdentidadSesion.Usuario,
          ASerieRectificada,
          ANumeroRectificado,
          SerieGenerada,
          NumFactura,
          sTipoRectificativaFiscal,
          ATratamientoMovimientos = tmrReemplazarOriginales);
      end
      else
      begin
        case ModoVerifactu(FParametrosApp) of
          mvVerifactu:
            TVerifactuCola.EncolarFactura(FParametrosApp, FParametrosCaja,
              QryTrx, IdentidadSesion.Usuario, SerieGenerada, NumFactura);
          mvNoVerifactu:
            TVerifactuCola.RegistrarFacturaNoVerifactu(FParametrosApp,
              FParametrosCaja, QryTrx, IdentidadSesion.Usuario,
              SerieGenerada, NumFactura);
        else
          TVerifactuCola.MarcarFacturaSinVerifactu(FParametrosApp,
            FParametrosCaja, QryTrx, IdentidadSesion.Usuario,
            SerieGenerada, NumFactura);
        end;
      end;
    end;
    // =======================================================================
    // PASO 5: FORMAS DE PAGO (Se ejecuta siempre que haya importe)
    // Las lineas con CODIGO_FP_CFP='VALE' se omiten aqui: las inserta PASO 6
    // junto con la operacion 'VR' y la marca de redimido en fza_caja_vales,
    // garantizando que la REFERENCIA al codigo de vale quede registrada.
    // =======================================================================
    NumLineaPago := 0;
    DatosCobro.MemTablePagos.First;
    while not DatosCobro.MemTablePagos.Eof do
    begin
      var CodigoFP  :=
        DatosCobro.MemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
      var ImporteFP :=
        DatosCobro.MemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;
      if (Abs(ImporteFP) > 0.001) and (CodigoFP <> 'VALE') then
      begin
        Inc(NumLineaPago);
        // La referencia (código de bono, autorización de tarjeta, TxID…) y
        // los datos de divisa se capturan en memoria durante la fase de cobro
        // (inLibFaseCobro). Hay que pasarlos aquí o no llegan a la BD y el
        // histórico de pagos los muestra vacíos.
        var DivisaFP  :=
          DatosCobro.MemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
        var FactorFP  :=
          DatosCobro.MemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat;
        var ImpDivFP  :=
          DatosCobro.MemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat;
        var ReferenFP :=
          DatosCobro.MemTablePagos.FieldByName('REFERENCIA').AsString;
        InsertarPagoCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, SerieGenerada, NumOperacionVE,
          NumLineaPago,
          CodigoFP, ImporteFP,
          DatosCobro.MemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency,
          DivisaFP, '', FactorFP, ImpDivFP, ReferenFP);
      end;
      DatosCobro.MemTablePagos.Next;
    end;
    // =======================================================================
    // PASO 6: VALES
    // =======================================================================
    if DatosCobro.ValesRecogidos <> nil then
    for var i := 0 to DatosCobro.ValesRecogidos.Count - 1 do
    begin
      if Abs(DatosCobro.ValesRecogidos[i].ImporteAplicado) > 0.001 then
      begin
        Inc(NumLineaPago);
        InsertarPagoCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, SerieGenerada, NumOperacionVE,
          NumLineaPago,
          'VALE', DatosCobro.ValesRecogidos[i].ImporteAplicado, 0,
          '', '', 1, 0,
          DatosCobro.ValesRecogidos[i].CodigoVale);   // <-- referencia al vale
        InsertarOperacionCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VR',
          DatosCobro.ValesRecogidos[i].ImporteAplicado, UsuarioCaja,
          FechaOperacion, NumFactura, SerieGenerada, Cab.CodigoCliente,
          'Vale canjeado: ' + DatosCobro.ValesRecogidos[i].CodigoVale);
        // Marcar el vale como redimido. La nueva firma recibe QryTrx para
        // unirse a la transaccion, ademas del importe y la empresa.
        MarcarValeComoCanjeado(
          QryTrx,
          DatosCobro.ValesRecogidos[i].CodigoVale,
          AEmpresa, AAlmacen, ACaja, NumOperacionVE,
          SerieGenerada, NumFactura,
          DatosCobro.ValesRecogidos[i].ImporteAplicado);
      end;
    end;
    // =======================================================================
    // PASO 6.5: VALE EMITIDO
    // La fase de cobro puede emitir un vale como reembolso de una
    // devolucion o como cambio entregado en vale. Hay que crearlo en
    // fza_caja_vales para que exista, se pueda canjear y lo sume el
    // arqueo (que lee IMPORTE_NOMINAL_VL de esa tabla), y registrar la
    // operacion de caja 'VL'. Sin esto el vale no se materializaba.
    // =======================================================================
    if DatosCobro.ImporteValeEmitido > 0.001 then
    begin
      var CodigoValeEmi := Format('VALE_%s_%s_%s_%s',
        [AEmpresa, AAlmacen, ACaja, NumOperacionVE]);
      var TieneCaducidadVale :=
        FParametrosCaja.GetBool('vgerCaducidadDefVale', False);
      QryTrx.SQL.Text :=
        'INSERT INTO fza_caja_vales (' +
        '  CODIGO_VL, ESTADO_VL, IMPORTE_NOMINAL_VL,' +
        '  FECHA_EMISION_VL, FECHA_CADUCIDAD_VL,' +
        '  CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL, CODIGO_CAJA_EMI_VL,' +
        '  NUMERO_OPERACION_EMI_VL, SERIE_FAC_EMI_VL, NUMERO_FAC_EMI_VL,' +
        '  CODIGO_CLI_VL, USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (' +
        '  :CODIGO, ''PENDIENTE'', :IMPORTE,' +
        '  :FEMISION, :FCADUCIDAD,' +
        '  :EMP, :ALM, :CAJA,' +
        '  :NUMOPE, :SERIE, :NUMFAC,' +
        '  :CLIENTE, :USUARIO, :USUARIO, NOW())';
      QryTrx.ParamByName('CODIGO').AsString    := CodigoValeEmi;
      QryTrx.ParamByName('IMPORTE').AsCurrency :=
        DatosCobro.ImporteValeEmitido;
      QryTrx.ParamByName('FEMISION').AsDateTime := FechaOperacion;
      if TieneCaducidadVale then
        QryTrx.ParamByName('FCADUCIDAD').AsDateTime :=
          FechaOperacion +
          FParametrosCaja.GetInt('vgerDiasCaducidadVale', 365)
      else
        QryTrx.ParamByName('FCADUCIDAD').Clear;
      QryTrx.ParamByName('EMP').AsString     := AEmpresa;
      QryTrx.ParamByName('ALM').AsString     := AAlmacen;
      QryTrx.ParamByName('CAJA').AsString    := ACaja;
      QryTrx.ParamByName('NUMOPE').AsString  := NumOperacionVE;
      QryTrx.ParamByName('SERIE').AsString   := SerieGenerada;
      QryTrx.ParamByName('NUMFAC').AsString  := NumFactura;
      QryTrx.ParamByName('CLIENTE').AsString := Cab.CodigoCliente;
      QryTrx.ParamByName('USUARIO').AsString := UsuarioCaja;
      QryTrx.Execute;
      // Linea de pago que refleja el reembolso entregado como vale,
      // en negativo y con el codigo del vale como referencia (igual
      // que un vale recogido deja su linea de pago).
      Inc(NumLineaPago);
      InsertarPagoCaja(
        QryTrx, AEmpresa, AAlmacen, ACaja, SerieGenerada, NumOperacionVE,
        NumLineaPago, 'VALE', -DatosCobro.ImporteValeEmitido, 0,
        '', '', 1, 0, CodigoValeEmi);
      InsertarOperacionCaja(
        QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VL',
        -DatosCobro.ImporteValeEmitido, UsuarioCaja,
        FechaOperacion, NumFactura, SerieGenerada, Cab.CodigoCliente,
        'Vale emitido: ' + CodigoValeEmi);
      ValeGenerado := CodigoValeEmi;
    end;
    // =======================================================================
    // PASO 7: ALBARÁN DE DEPÓSITO
    // =======================================================================
    TieneDepositosPendientes := False;
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      var Accion := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;
      if (Accion = 'NUEVO_DEP') or
         (Accion = 'AUMENTAR_DEP') or
         (Accion='CANCELAR') then
      begin
        TieneDepositosPendientes := True;
        Break;
      end;
      cdsLineas.Next;
    end;
    // =======================================================================
    // CONFIRMAR
    // =======================================================================
    FConexion.Commit;
    if TieneDepositosPendientes and (sOpeCaja <> '') then
    begin
      ImprimirResguardoDeposito(FConexion,
                                AEmpresa,
                                AAlmacen,
                                ACaja,
                                sOpeCaja,
                                FParametrosCaja.ImpresoraCaja);
      ImprimirRecordatorio(FConexion, FContextoSesion.Ubicacion.Empresa,
        Cab.CodigoCliente,
        FParametrosCaja.ImpresoraCaja);
    end;
    try
      cdsLineas.DisableControls;
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        if (Abs(cdsLineas.FieldByName(
                                'TOTAL_FACLIN').AsCurrency)) < 0.001 then
          cdsLineas.Delete
        else
          cdsLineas.Next;
      end;
    finally
      cdsLineas.EnableControls;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      FConexion.Rollback;
      raise Exception.CreateFmt(SErrorGuardarTicketCaja, [E.Message]);
    end;
  end;
  finally
    FreeAndNil(QryTrx);
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
  if Trim(Codigo) = '' then
    Exit;
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
  end
  else
    Exit;
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
  with cdsLineas do
  begin
    if not DataSet.ControlsDisabled then
      AplicarValoresPorDefecto(
        FConexion,
        cdsLineas,
        'fza_facturas_lineas');
    FieldByName('SERIE_FAC_FACLIN').AsString := '0';
    FieldByName('NUMERO_FAC_FACLIN').AsString := '0';
    NuevoNumero := cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger
                                                                          + 10 ;
    cdsCabecera.Edit;
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger := NuevoNumero;
    FieldByName('LINEA_FACLIN').AsString :=
                                                  Format('%.4d', [NuevoNumero]);
    FieldByName('CODIGO_VENDEDOR_FACLIN').AsString :=
                      cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
    FindField('PORCENTAJE_IVA_FACLIN').AsCurrency := GetTipoIVA(
          FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
  end;
end;

function TdmCajaOpe.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  with cdsCabecera do
  begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := FindField('PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := FindField('PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := FindField('PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      fPorcen := FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
      cdsLineas.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
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
  if Requeridos = 0 then
    Exit;
  SkuActual := Trim(DataSet.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
  if Pos('/', SkuActual) = 0 then
    Abort;
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  with cdsCabecera.FieldDefs do
  begin
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
  end;
  with cdsCabecera.IndexDefs.AddIndexDef do
  begin
    Name := 'PK_CABECERA';
    Fields := 'SERIE_FAC;NUMERO_FAC';
    Options := [ixPrimary, ixUnique];
  end;
  cdsCabecera.CreateDataSet;
end;

procedure TdmCajaOpe.ConfigurarEstructuraLineas;
begin
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  with cdsLineas.FieldDefs do
  begin
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
  end;
  with cdsLineas.IndexDefs.AddIndexDef do
  begin
    Name := 'PRIMARY_KEY';
    Fields := 'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN;LINEA_FACLIN';
    Options := [ixPrimary, ixUnique];
  end;
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := FConexion;
  qryVales.Connection := FConexion;
  qryStock.Connection := FConexion;
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
  QryTrx.SQL.Text :=
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
