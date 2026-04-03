unit UniDataCaja;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Data.DB, Datasnap.Provider,
  Datasnap.DBClient, Uni, MemDS, DBAccess, system.Math, UniDataGen,
  inLibGlobalVar, system.StrUtils, inLibFaseCobro, Windows;

type
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
    // campos de depósito
    VieneDeDeposito:     string;   // 'S', 'A', ''
    AccionDeposito:      string;   // 'COBRAR', 'NUEVO_DEP', 'AUMENTAR_DEP', 'CANCELAR'
    PrecioOriginalDep:   Currency;
    AnticipoPrevio:      Currency;
  end;

type
  TRellenarArticuloEvent  = function(ACodigo: string): Boolean of object;
  TRellenarAtributosEvent = procedure(ASku: string) of object;
  TOnUpdateTotalEvent =
                     procedure(Sender: TObject; NuevoTotal: Currency) of object;
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
    FOnRellenarArticulo:  TRellenarArticuloEvent;
    FOnRellenarAtributos: TRellenarAtributosEvent;
    FOnUpdateTotal: TOnUpdateTotalEvent;
    function SiguienteOpCaja(AEmpresa,
                             AAlmacen,
                             ACaja,
                             AEmpleado:string): string;
    procedure InsertarMovimientoAlmacen(QryTrx:     TUniQuery;
                          ATipoDoc:   string;  // 'VE', 'TR'
                          ASerie:     string;  // serie factura/doc origen
                          ANro:       string;  // número doc origen
                          ALinea:     string;  // línea doc origen
                          AEmpresa:   string;
                          AAlmacen:   string;  // almacén que mueve
                          AAlmContra: string;  // almacén destino (solo traspasos)
                          ATipoMov:   string;  // 'E' o 'S'
                          AArticulo:  string;
                          ASku:       string;
                          ADesc:      string;
                          ACantidad:  Double;
                          ACoste:     Currency; // 0 en salidas y traspasos
                          ACliente:   string;
                          AUsuario:   string);
    procedure InsertarOperacionCaja(
                        QryTrx:          TUniQuery;
                        const AEmpresa:  string;
                        const AAlmacen:  string;
                        const ACaja:     string;
                        ANumOperacion:   string;
                        const ATipoOp:   string;   // 'VE','VL','AL','CB','EC','GC','TR','AT'
                        AImporte:        Currency; // negativo en VL y AT
                        const AEmpleado: string;
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
                        const AEsTraspaso:       string = 'N');
    procedure InsertarPagoCaja(
                        QryTrx:           TUniQuery;
                        const AEmpresa:   string;
                        const AAlmacen:   string;
                        const ACaja:      string;
                        const ASerie:     string;    // serie de la operación de caja
                        ANumOperacion:    string;
                        ANumLinea:        Integer;   // 1, 2, 3... por forma de pago
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
                        const AAlmacen:      string;
                        const ACaja:         string;
                        ANumOperacion:       string;
                        const ANumMovAlmacen:string;   // NUMERO_MOV de fza_movimientos_almacen
                        const AUsuario:      string);
    procedure ConfigurarEstructuraLineas;
    procedure ConfigurarEstructuraCabecera;
    function GetTipoIVA(sTipoIVA: string): Currency;
    function CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
    function EmitirNuevoVale(const AEmpresa, AAlmacen, ACaja: string;
                             ANumOperacion: string;
                             ASerieFactura, ANumFactura: string;
                             AImporte: Currency): string;
    function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
    procedure CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                        const AEmpresa, ACliente,
                                        AArticulo, ASku, AUsuario: string;
                                        APrecioVenta, AAnticipo: Currency;
                                        const AAlmacenOrigen,
                                              AAlmacenDestino: string;
                                        ACantidad: Double;
                                        ATipoIVA: string;
                                        APorcIVA: Currency;
                                        AEsImpIncl: string);
    procedure CerrarDepositoCliente(QryTrx: TUniQuery;
                                    const ACliente, ASku, AUsuario: string);
    procedure AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                       const ACliente, ASku, AUsuario: string;
                                       ANuevoAbono: Currency);
    procedure AnularDepositoCliente(QryTrx:           TUniQuery;
                                    const ACliente:    string;
                                    const ASku:        string;
                                    const AUsuario:    string;
                                    const AAlmacenTienda:   string;
                                    const AAlmacenDeposito: string;
                                    const AEmpresa:    string;
                                    const AArticulo:   string;
                                    out   ImporteADevolver: Currency;
                                    ACantidad: Double);
    procedure InsertarCabeceraFactura(
            QryTrx:          TUniQuery;
            // — identificación —
            const ASerie:    string;
            const ANro:      string;
            AFecha:          TDateTime;
            const ATipo:     string;   // 'SIMPLIFICADA', 'NORMAL', 'RECTIFICATIVA'
            const AFase:     string;   // 'BORRADOR', 'ONLINE', etc.
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
    function LeerCabecera: TDatosCabeceraFactura;
    function LeerLineaActual: TDatosLineaFactura;
    procedure TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                DineroEntregado: Currency);
  public
    procedure CargarDepositosCliente(const ACodigoCliente: string);
    function GenerarSkuFinal(ArticuloBase: string): string;
    procedure MarcarValeComoCanjeado(const ACodigoVale: string;
                                 ACodigoCaja: string;
                                 ACodigoAlmacen: string;
                                 ANumOperacion: string;
                                 ASerie: string;
                                 ANumFactura: String);
    function BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                  var LabelDestino: String):Boolean;
    function GetTarifaDefault : string;
    function GrabarFacturaSimplificada(const AEmpresa, AAlmacen, ACaja, ASerieElegida: string;
                                     DatosCobro: TDatosFaseCobro;
                                     out SerieGenerada: string;
                                     out NumeroGenerado: String;
                                     out ValeGenerado:String): Boolean;
//    procedure CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//    procedure CalcularTotalesCabecera;
    property OnUpdateTotal: TOnUpdateTotalEvent read FOnUpdateTotal
                                                write FOnUpdateTotal;
    property OnRellenarArticulo:  TRellenarArticuloEvent
                                  read FOnRellenarArticulo
                                  write FOnRellenarArticulo;
    property OnRellenarAtributos: TRellenarAtributosEvent
                                  read FOnRellenarAtributos
                                  write FOnRellenarAtributos;
  end;

var
  dmCajaOpe: TdmCajaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibtb, inMtoCajaOpe, inLibDevExp, inLibFacturas;

{$R *.dfm}

function TdmCajaOpe.LeerCabecera: TDatosCabeceraFactura;
begin
  with cdsCabecera do
  begin
    Result.Fecha           := FieldByName('FECHA_FACTURA').AsDateTime;
    Result.CodigoCliente   := FieldByName('CODIGO_CLIENTE_FACTURA').AsString;
    Result.RazonSocialEmp  := FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString;
    Result.NifEmp          := FieldByName('NIF_EMPRESA_FACTURA').AsString;
    Result.MovilEmp        := FieldByName('MOVIL_EMPRESA_FACTURA').AsString;
    Result.EmailEmp        := FieldByName('EMAIL_EMPRESA_FACTURA').AsString;
    Result.Direccion1Emp   := FieldByName('DIRECCION1_EMPRESA_FACTURA').AsString;
    Result.Direccion2Emp   := FieldByName('DIRECCION2_EMPRESA_FACTURA').AsString;
    Result.PoblacionEmp    := FieldByName('POBLACION_EMPRESA_FACTURA').AsString;
    Result.ProvinciaEmp    := FieldByName('PROVINCIA_EMPRESA_FACTURA').AsString;
    Result.CPostalEmp      := FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString;
    Result.CodigoPaisEmp   := FieldByName('CODIGO_PAIS_EMPRESA_FACTURA').AsString;
    Result.NombrePaisEmp   := FieldByName('NOMBRE_PAIS_EMPRESA_FACTURA').AsString;
    Result.EsRetencionesEmp:= FieldByName('ESRETENCIONES_EMPRESA_FACTURA').AsString;
    Result.GrupoZonaIvaEmp := FieldByName('GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString;
    Result.RazonSocialCli  := FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString;
    Result.NifCli          := FieldByName('NIF_CLIENTE_FACTURA').AsString;
    Result.MovilCli        := FieldByName('MOVIL_CLIENTE_FACTURA').AsString;
    Result.EmailCli        := FieldByName('EMAIL_CLIENTE_FACTURA').AsString;
    Result.Direccion1Cli   := FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString;
    Result.Direccion2Cli   := FieldByName('DIRECCION2_CLIENTE_FACTURA').AsString;
    Result.PoblacionCli    := FieldByName('POBLACION_CLIENTE_FACTURA').AsString;
    Result.ProvinciaCli    := FieldByName('PROVINCIA_CLIENTE_FACTURA').AsString;
    Result.CPostalCli      := FieldByName('CPOSTAL_CLIENTE_FACTURA').AsString;
    Result.CodigoPaisCli   := FieldByName('CODIGO_PAIS_CLIENTE_FACTURA').AsString;
    Result.NombrePaisCli   := FieldByName('NOMBRE_PAIS_CLIENTE_FACTURA').AsString;
    Result.CodigoIva       := FieldByName('CODIGO_IVA_FACTURA').AsString;
    Result.Tarifa          := FieldByName('TARIFA_ARTICULO_CLIENTE_FACTURA').AsString;
    Result.EsIvaRecargo    := FieldByName('ESIVA_RECARGO_CLIENTE_FACTURA').AsString;
    Result.EsIvaExento     := FieldByName('ESIVA_EXENTO_CLIENTE_FACTURA').AsString;
    Result.EsImpInclTarifa := FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FACTURA').AsString;
    Result.PorcIvaN        := FieldByName('PORCEN_IVAN_FACTURA').AsCurrency;
    Result.TotalIvaN       := FieldByName('TOTAL_IVAN_FACTURA').AsCurrency;
    Result.PorcReN         := FieldByName('PORCEN_REN_FACTURA').AsCurrency;
    Result.TotalReN        := FieldByName('TOTAL_REN_FACTURA').AsCurrency;
    Result.BaseIN          := FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsCurrency;
    Result.PorcIvaR        := FieldByName('PORCEN_IVAR_FACTURA').AsCurrency;
    Result.TotalIvaR       := FieldByName('TOTAL_IVAR_FACTURA').AsCurrency;
    Result.PorcReR         := FieldByName('PORCEN_RER_FACTURA').AsCurrency;
    Result.TotalReR        := FieldByName('TOTAL_RER_FACTURA').AsCurrency;
    Result.BaseIR          := FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsCurrency;
    Result.PorcIvaS        := FieldByName('PORCEN_IVAS_FACTURA').AsCurrency;
    Result.TotalIvaS       := FieldByName('TOTAL_IVAS_FACTURA').AsCurrency;
    Result.PorcReS         := FieldByName('PORCEN_RES_FACTURA').AsCurrency;
    Result.TotalReS        := FieldByName('TOTAL_RES_FACTURA').AsCurrency;
    Result.BaseIS          := FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsCurrency;
    Result.PorcIvaE        := FieldByName('PORCEN_IVAE_FACTURA').AsCurrency;
    Result.TotalIvaE       := FieldByName('TOTAL_IVAE_FACTURA').AsCurrency;
    Result.PorcReE         := FieldByName('PORCEN_REE_FACTURA').AsCurrency;
    Result.TotalReE        := FieldByName('TOTAL_REE_FACTURA').AsCurrency;
    Result.BaseIE          := FieldByName('TOTAL_BASEI_IVAE_FACTURA').AsCurrency;
    Result.TotalBases      := FieldByName('TOTAL_BASES_FACTURA').AsCurrency;
    Result.TotalImpuestos  := FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency;
    Result.TotalRetencion  := FieldByName('TOTAL_RETENCION_FACTURA').AsCurrency;
    Result.PorcRetencion   := FieldByName('PORCEN_RETENCION_FACTURA').AsCurrency;
    Result.TotalLiquido    := FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency;
    Result.FormaPago       := FieldByName('FORMA_PAGO_FACTURA').AsString;
    Result.Comentarios     := FieldByName('COMENTARIOS_FACTURA').AsString;
  end;
end;

function TdmCajaOpe.LeerLineaActual: TDatosLineaFactura;
begin
  with cdsLineas do
  begin
    Result.Linea               := FieldByName('LINEA_FACTURA_LINEA').AsString;
    Result.Articulo            := FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString;
    Result.Sku                 := FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;
    Result.Descripcion         := FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
    // Result.DescripcionVariacion:= FieldByName('DESCRIPCION_VARIACION_FACTURA_LINEA').AsString;
    Result.Familia             := FieldByName('CODIGO_FAMILIA_FACTURA_LINEA').AsString;
    Result.NombreFamilia       := FieldByName('NOMBRE_FAMILIA_FACTURA_LINEA').AsString;
    Result.TipoArticulo        := FieldByName('TIPO_ARTICULO_FACTURA_LINEA').AsString;
    Result.TipoCantidad        := FieldByName('TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA').AsString;
    Result.Cantidad            := FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat;
    Result.Tarifa              := FieldByName('CODIGO_TARIFA_FACTURA_LINEA').AsString;
    Result.EsImpIncl           := FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString;
    Result.PrecioSalida        := FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
    Result.PorcDto             := FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
    Result.PrecioDto           := FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency;
    Result.PrecioSIva          := FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
    Result.PrecioCIva          := FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
    Result.TipoIva             := FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
    Result.PorcIva             := FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat;
    Result.TotalSIva           := FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
    Result.TotalCIva           := FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
    Result.VieneDeDeposito     := FieldByName('VIENE_DE_DEPOSITO').AsString;
    Result.AccionDeposito      := FieldByName('ACCION_DEPOSITO').AsString;
    Result.PrecioOriginalDep   := FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
    Result.AnticipoPrevio      := FieldByName('ANTICIPO_PREVIO').AsCurrency;
  end;
end;

// =============================================================================
// MÓDULO: GESTIÓN DE CUENTAS Y DEPÓSITOS DE CLIENTES
// =============================================================================
procedure TdmCajaOpe.CargarDepositosCliente(const ACodigoCliente: string);
var
  QryDep: TUniQuery;
  Sku, Articulo: string;
  PrecioOriginal, AnticipoDado: Currency;
  CantidadPendiente: Double;
  TipoIVA, EsImpIncl: string;
  PorcIVA: Currency;
begin
  QryDep := TUniQuery.Create(nil);
  try
    QryDep.Connection := inLibGlobalVar.oConn;
    QryDep.SQL.Text :=
      'SELECT CODIGO_ARTICULO_DEP, ' +
      '       CODIGO_UNIDAD_DEP, ' +
      '       CANTIDAD_PENDIENTE_DEP, ' +
      '       PRECIO_VENTA_DEP, ' +
      '       IMPORTE_ANTICIPO_DEP,' +
      '       TIPO_IVA_DEP, ' +
      '       PORCEN_IVA_DEP, ' +
      '       ESIMP_INCL_DEP ' +
      '  FROM fza_depositos_cliente ' +
      ' WHERE CODIGO_CLIENTE_DEP = :CLI ' +
      '   AND ESTADO_DEP = ''PENDIENTE''';
    QryDep.ParamByName('CLI').AsString := ACodigoCliente;
    QryDep.Open;
    if QryDep.IsEmpty then
      Exit;
    cdsLineas.DisableControls;
    try
      while not QryDep.Eof do
      begin
        Articulo          := QryDep.FieldByName('CODIGO_ARTICULO_DEP').AsString;
        Sku               := QryDep.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        CantidadPendiente := QryDep.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
        PrecioOriginal    := QryDep.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        AnticipoDado      := QryDep.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
        TipoIVA           := QryDep.FieldByName('TIPO_IVA_DEP').AsString;
        PorcIVA           := QryDep.FieldByName('PORCEN_IVA_DEP').AsCurrency;
        EsImpIncl         := QryDep.FieldByName('ESIMP_INCL_DEP').AsString;
        // ── LÍNEA 1: LA PRENDA ───────────────────────────────────────────────
        cdsLineas.Append;
        // 1a. Rellenar descripción y atributos dinámicos desde la BD
        //     usando el callback del Form (si está asignado)
        if Assigned(FOnRellenarArticulo) then
          FOnRellenarArticulo(Sku);   // rellena desc, tipo, código padre, ATTRx
        // 1b. Ahora sobreescribimos con los datos reales del depósito,
        //     que tienen prioridad sobre lo que haya devuelto la tarifa
        cdsLineas.Edit;
        cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString  := Articulo;
        cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString    := Sku;
        cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat          := CantidadPendiente;
        cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString              := 'S';
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString                := 'COBRAR';
        cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := TipoIVA;
        cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency     := PorcIVA;
        cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString:= EsImpIncl;
        // Precio del depósito manda siempre
        cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := PrecioOriginal;
        cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency := PrecioOriginal;
        if PorcIVA = 0 then
          cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency := PrecioOriginal
        else
          cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
            PrecioOriginal / (1 + (PorcIVA / 100));
        cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat    := 0;
        cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency := 0;
        cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency :=
          PrecioOriginal * CantidadPendiente;
        cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency :=
          cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency
          * CantidadPendiente;
        cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency := AnticipoDado;
        // 1c. Rellenar valores de atributos si el SKU los contiene
        if Assigned(FOnRellenarAtributos) and (Pos('/', Sku) > 0) then
          FOnRellenarAtributos(Sku);
        cdsLineas.Post;
        // ── LÍNEA 2: ABONO DEL ANTICIPO (negativo) ───────────────────────────
        if AnticipoDado > 0 then
        begin
          var AnticipoSinIVA: Currency;
          if PorcIVA = 0 then
            AnticipoSinIVA := AnticipoDado
          else
            AnticipoSinIVA := AnticipoDado / (1 + (PorcIVA / 100));
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString  := 'ANTICIPO';
          cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString    := 'ANTICIPO';
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString :=
            'Abono anticipo ' + Sku;
          cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString              := 'A';
          cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat          := -1;
          cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := TipoIVA;
          cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency     := PorcIVA;
          cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString:= EsImpIncl;
          cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := AnticipoDado;
          cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency := AnticipoDado;
          cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency := AnticipoSinIVA;
          cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency          := -AnticipoDado;
          cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency      := -AnticipoSinIVA;
          cdsLineas.Post;
        end;
        QryDep.Next;
      end;
    finally
      cdsLineas.EnableControls;
    end;
    GridRecalc(nil,
               (Owner as TfrmMtoOpeCaja).cxGrid1DBTableView1,
               cdsLineas,
               cdsCabecera,
               OnUpdateTotal);
  finally
    QryDep.Free;
  end;
end;
//procedure TdmCajaOpe.AnularDepositoCliente(QryTrx: TUniQuery; const ASku, AUsuario,
//                                           AAlmacenTienda, AAlmacenDeposito: string;
//                                           out ImporteADevolver: Currency;
//                                           ACantidad: Double);
//begin
//  ImporteADevolver := 0;
//  // 1. Averiguar cuánto dinero tenía entregado a cuenta esta prenda
//  QryTrx.SQL.Text :=
//    'SELECT IMPORTE_ANTICIPO_DEP FROM fza_depositos_cliente ' +
//    ' WHERE CODIGO_UNIDAD_DEP = :SKU AND ESTADO_DEP = ''PENDIENTE''';
//  QryTrx.ParamByName('SKU').AsString := ASku;
//  QryTrx.Open;
//  if not QryTrx.IsEmpty then
//    ImporteADevolver := QryTrx.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
//  QryTrx.Close;
//  // 2. Marcar el depósito como cancelado
//  QryTrx.SQL.Text :=
//    'UPDATE fza_depositos_cliente ' +
//    '   SET ESTADO_DEP = ''CANCELADO'', ' +
//    '       USUARIOMODIF = :USUARIO ' +
//    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
//    '   AND ESTADO_DEP = ''PENDIENTE''';
//  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
//  QryTrx.ParamByName('SKU').AsString := ASku;
//  QryTrx.Execute;
//  // 3. Devolver el stock a la tienda (Salida de Depósito, Entrada a Tienda)
//  QryTrx.SQL.Text :=
//    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
//    'VALUES (:ALMDEP, :SKU, ''S'', :CANT, :FECHA)';
//  QryTrx.ParamByName('ALMDEP').AsString := AAlmacenDeposito;
//  QryTrx.ParamByName('SKU').AsString := ASku;
//  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
//  QryTrx.ParamByName('FECHA').AsDateTime := Now;
//  QryTrx.Execute;
//  QryTrx.SQL.Text :=
//    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
//    'VALUES (:ALMTIENDA, :SKU, ''E'', :CANT, :FECHA)';
//  QryTrx.ParamByName('ALMTIENDA').AsString := AAlmacenTienda;
//  QryTrx.ParamByName('SKU').AsString := ASku;
//  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
//  QryTrx.ParamByName('FECHA').AsDateTime := Now;
//  QryTrx.Execute;
//end;

procedure TdmCajaOpe.CerrarDepositoCliente(QryTrx: TUniQuery;
                                           const ACliente, ASku, AUsuario: string);
begin
  // Llamamos al SP para forzar el estado a CERRADO. El anticipo no se incrementa (0).
  QryTrx.SQL.Text := 'CALL PRC_FZA_DEPOSITOS_UPDATE(:SKU, :CLI, :ESTADO, :INC_ANTICIPO, :USUARIO)';

  QryTrx.ParamByName('SKU').AsString          := ASku;
  QryTrx.ParamByName('CLI').AsString          := ACliente;
  QryTrx.ParamByName('ESTADO').AsString       := 'CERRADO';
  QryTrx.ParamByName('INC_ANTICIPO').AsCurrency := 0;
  QryTrx.ParamByName('USUARIO').AsString      := AUsuario;

  QryTrx.Execute;
end;

procedure TdmCajaOpe.AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                              const ACliente, ASku, AUsuario: string;
                                              ANuevoAbono: Currency);
begin
  if ANuevoAbono <= 0 then Exit;

  // Llamamos al SP pasando NULL al estado (se queda PENDIENTE) y pasamos el incremento.
  QryTrx.SQL.Text := 'CALL PRC_FZA_DEPOSITOS_UPDATE(:SKU, :CLI, :ESTADO, :INC_ANTICIPO, :USUARIO)';

  QryTrx.ParamByName('SKU').AsString          := ASku;
  QryTrx.ParamByName('CLI').AsString          := ACliente;
  QryTrx.ParamByName('ESTADO').Clear; // Enviamos NULL para que el SP respete el estado actual
  QryTrx.ParamByName('INC_ANTICIPO').AsCurrency := ANuevoAbono;
  QryTrx.ParamByName('USUARIO').AsString      := AUsuario;

  QryTrx.Execute;
end;

procedure TdmCajaOpe.TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                       DineroEntregado: Currency);
var
  TotalLinea, DineroDisponible: Currency;
  VieneDeDep, AccionDep: string;

  procedure EliminarLineaAbono(const ASkuLinea: string);
  var
    Bkm: TBookmark;
  begin
    Bkm := (cdsLineas as TClientDataSet).GetBookmark;
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if (cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'A') and
         (cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString =
          'Abono anticipo ' + ASkuLinea) then
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
    SkuLinea, TipoIVALinea, EsImpInclLinea: string;
    PorcIVALinea: Currency;
    DineroReal: Currency;
  begin
    TotalLinea     := cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
    AnticipoPrevio := cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
    SkuLinea       := cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;
    TipoIVALinea   := cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
    PorcIVALinea   := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency;
    EsImpInclLinea := cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString;
    DineroReal := DineroDisponible + AnticipoPrevio;
    if DineroReal >= TotalLinea then
    begin
      // ── PAGO TOTAL ───────────────────────────────────────────────────────
      // La línea de abono ya está en el grid, se queda porque el cliente
      // recoge la prenda
      DineroDisponible := DineroDisponible - (TotalLinea - AnticipoPrevio);
      cdsLineas.Next;
    end
    else
    begin
      // ── PAGO PARCIAL ─────────────────────────────────────────────────────
      cdsLineas.Edit;
      // Si viene de depósito existente → AUMENTAR_DEP
      // Si es prenda nueva de hoy     → NUEVO_DEP
      if cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'AUMENTAR_DEP'
      else
        cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'NUEVO_DEP';
      cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency := TotalLinea;
      cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency :=
                                                               DineroDisponible;
      cdsLineas.FieldByName(
                        'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                                               DineroDisponible;
      if PorcIVALinea = 0 then
        cdsLineas.FieldByName(
          'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                                                DineroDisponible
      else
        cdsLineas.FieldByName(
          'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
            DineroDisponible / (1 + (PorcIVALinea / 100));
      cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat         := 1;
      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat       := 0;
      cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency    := 0;
      cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency         :=
                                                               DineroDisponible;
      cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency     :=
                                                          cdsLineas.FieldByName(
                          'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
      cdsLineas.Post;
      // Eliminar la línea de abono porque el cliente no recoge la prenda
      EliminarLineaAbono(SkuLinea);
      DineroDisponible := 0;
      cdsLineas.Next;
    end;
  end;
begin
  DineroDisponible := DineroEntregado;
  cdsLineas.DisableControls;
  try
    // =========================================================================
    // PASO 0: Sumar SOLO abonos de devoluciones reales, no anticipos de depósit
    // =========================================================================
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if (cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency < 0) and
         (cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString <> 'A') then
        DineroDisponible := DineroDisponible -
                        cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
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
         (cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency > 0) then
      begin
        if DineroDisponible > 0 then
          ProcesarLinea
        else
        begin
          // Sin dinero: eliminar prenda y su abono del grid
          var SkuEliminar := cdsLineas.FieldByName(
                               'CODIGO_UNIDAD_FACTURA_LINEA').AsString;
          cdsLineas.Delete;
          EliminarLineaAbono(SkuEliminar);
        end;
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
         (AccionDep = 'COBRAR') and
         (cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency > 0) then
      begin
        if DineroDisponible > 0 then
          ProcesarLinea
        else
        begin
          // Sin dinero pero la prenda se aparta → NUEVO_DEP con anticipo 0
          cdsLineas.Edit;
          cdsLineas.FieldByName('ACCION_DEPOSITO').AsString      := 'NUEVO_DEP';
          cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency    :=
            cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
          cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := 0;
          cdsLineas.FieldByName(
                     'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency := 0;
          cdsLineas.FieldByName(
                     'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency := 0;
          cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency          := 0;
          cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency      := 0;
          cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat        := 0;
          cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency     := 0;
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

// =============================================================================
// ARCHIVO: UniDataCaja_GrabarFactura_v2.pas
//
// Contiene los métodos nuevos/modificados de TdmCajaOpe:
//   - InsertarMovimientoAlmacen  (nuevo — auxiliar centralizado)
//   - AnularDepositoCliente      (firma ampliada con AEmpresa + AArticulo)
//   - CrearNuevoDepositoCliente  (usa InsertarMovimientoAlmacen)
//   - GrabarFacturaSimplificada  (usa InsertarMovimientoAlmacen en todos los
//                                 casos)
//
// Cambios respecto a la versión anterior:
//   1. Los INSERTs en fza_movimientos_almacen ahora incluyen todos los campos
//      obligatorios: NUMERO_MOV, TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV,
//      LINEA_MOV, CODIGO_EMPRESA_MOV, CODIGO_ARTICULO_MOV,
//      DESCRIPCION_ARTICULO_MOV, CODIGO_ALMACEN_CONTRA_MOV,
//      CODIGO_CLIENTE_MOV, USUARIOALTA, USUARIOMODIF, INSTANTEALTA.
//   2. NUMERO_MOV se genera mediante ObtenerSiguienteContador('MV') de inLibtb.
//      El procedure PRC_GET_NEXT_CONT crea el contador 'MV' automáticamente
//      en fza_contadores si no existe todavía.
//   3. PRECIO_COSTE_UNITARIO_MOV se envía a 0 en salidas y traspasos internos.
//      El trigger TRG_MOVIMIENTOS_BI (v2) lo resuelve tomando el PMP vigente.
//   4. AnularDepositoCliente recibe AEmpresa y AArticulo para poder completar
//      los movimientos de traspaso con todos los campos.
// =============================================================================
// -----------------------------------------------------------------------------
// NUEVO MÉTODO AUXILIAR — añadir a la sección private de TdmCajaOpe
// -----------------------------------------------------------------------------

procedure TdmCajaOpe.InsertarMovimientoAlmacen(
                          QryTrx:     TUniQuery;
                          ATipoDoc:   string;   // 'VE' venta, 'TR' traspaso
                          ASerie:     string;   // serie doc origen
                          ANro:       string;   // número doc origen
                          ALinea:     string;   // línea doc origen
                          AEmpresa:   string;
                          AAlmacen:   string;   // almacén que ejecuta el mov.
                          AAlmContra: string;   // almacén destino (solo tras)
                          ATipoMov:   string;   // 'E' entrada  /  'S' salida
                          AArticulo:  string;   // código artículo padre
                          ASku:       string;   // código unidad / SKU
                          ADesc:      string;   // descripción
                          ACantidad:  Double;   // siempre positivo;
                          ACoste:     Currency; // 0 en salidas y traspasos
                          ACliente:   string;   // código cliente
                          AUsuario:   string);
begin
  // Llamada al Procedimiento Almacenado
  QryTrx.SQL.Text :=
    'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(' +
    '  :NUMOV, :TIPODOC, :SERIE, :NRO, :LINEA,' +
    '  :EMP, :ALM, :SKU, :ART,' +
    '  :ALMCONTRA, :CLI, :PROV,' +
    '  :TIPOMOV, :CANT, :PRECIOMEDIO, :TOTALCOSTE, :USUARIO' +
    ')';
  QryTrx.ParamByName('NUMOV').AsString       := ObtenerSiguienteContador('MV');
  QryTrx.ParamByName('TIPODOC').AsString     := ATipoDoc;
  QryTrx.ParamByName('SERIE').AsString       := ASerie;
  QryTrx.ParamByName('NRO').AsString         := ANro;
  QryTrx.ParamByName('LINEA').AsString       := ALinea;
  QryTrx.ParamByName('EMP').AsString         := AEmpresa;
  QryTrx.ParamByName('ALM').AsString         := AAlmacen;
  QryTrx.ParamByName('SKU').AsString         := ASku;
  QryTrx.ParamByName('ART').AsString         := AArticulo;
  // Tratamiento de nulos para IDs vacíos
  if AAlmContra = '' then
    QryTrx.ParamByName('ALMCONTRA').Clear
  else
    QryTrx.ParamByName('ALMCONTRA').AsString := AAlmContra;
  if ACliente = '' then
    QryTrx.ParamByName('CLI').Clear
  else
    QryTrx.ParamByName('CLI').AsString       := ACliente;
  // El SP requiere Proveedor,
  // pero no está en los parámetros de la función Delphi.
  // Lo enviamos como NULL por defecto.
  QryTrx.ParamByName('PROV').Clear;
  QryTrx.ParamByName('TIPOMOV').AsString     := ATipoMov;
  QryTrx.ParamByName('CANT').AsFloat         := Abs(ACantidad);
  // Costes enviados desde la App (el SP los ignorará si es salida 'S')
  QryTrx.ParamByName('PRECIOMEDIO').AsCurrency := ACoste;
  QryTrx.ParamByName('TOTALCOSTE').AsCurrency  := ACoste * Abs(ACantidad);
  QryTrx.ParamByName('USUARIO').AsString     := AUsuario;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.AnularDepositoCliente(QryTrx:           TUniQuery;
                                           const Acliente:    string;
                                           const ASku:        string;
                                           const AUsuario:    string;
                                           const AAlmacenTienda:   string;
                                           const AAlmacenDeposito: string;
                                           const AEmpresa:    string;
                                           const AArticulo:   string;
                                           out   ImporteADevolver: Currency;
                                           ACantidad: Double);
begin
  ImporteADevolver := 0;
  QryTrx.SQL.Text :=
    'SELECT IMPORTE_ANTICIPO_DEP ' +
    '  FROM fza_depositos_cliente ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
    '   AND CODIGO_CLIENTE_DEP = :CLIENTE ' +
    '   AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('CLIENTE').AsString := ACliente;
  QryTrx.Open;
  if not QryTrx.IsEmpty then
    ImporteADevolver := QryTrx.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
  QryTrx.Close;
  // 2. Marcar depósito como cancelado
  QryTrx.SQL.Text :=
    'UPDATE fza_depositos_cliente ' +
    '   SET ESTADO_DEP   = ''CANCELADO'', ' +
    '       USUARIOMODIF = :USUARIO ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
    '   AND CODIGO_CLIENTE_DEP = :CLIENTE ' +
    '   AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
  QryTrx.ParamByName('SKU').AsString     := ASku;
  QryTrx.ParamByName('CLIENTE').AsString     := ACliente;
  QryTrx.Execute;
  // 3. Traspaso de stock: Salida del almacén depósito → Entrada a tienda
  //    Coste = 0 en ambos lados: el trigger TRG_MOVIMIENTOS_BI (v2) toma el
  //    PMP vigente.
  // 3a. Salida del almacén depósito
  InsertarMovimientoAlmacen(
    QryTrx,
    'TR',                  // traspaso interno
    '', '', '0001',        // sin doc factura asociado
    AEmpresa,
    AAlmacenDeposito,      // almacén que pierde stock
    AAlmacenTienda,        // almacén que recibe stock
    'S',
    AArticulo, ASku, '',
    ACantidad,
    0,                     // salida → trigger usa PMP vigente
    '', AUsuario);
  // 3b. Entrada al almacén tienda
  InsertarMovimientoAlmacen(
    QryTrx,
    'TR',
    '', '', '0002',
    AEmpresa,
    AAlmacenTienda,        // almacén que recibe stock
    AAlmacenDeposito,      // almacén de procedencia
    'E',
    AArticulo, ASku, '',
    ACantidad,
    0,              // entrada sin coste → trigger toma PMP del almacén depósito
    '', AUsuario);
end;
// -----------------------------------------------------------------------------
// MODIFICADO: CrearNuevoDepositoCliente
// Sustituye los dos INSERTs incompletos por InsertarMovimientoAlmacen.
// -----------------------------------------------------------------------------
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
                                               AEsImpIncl:        string);
var
  NuevoIdDep: string;
begin
  // 1. Traspaso de stock: Salida de tienda → Entrada al almacén depósito
  // 1a. Salida de tienda
  InsertarMovimientoAlmacen(QryTrx,
                            'TR',
                            '',
                            '',
                            '0001',
                            AEmpresa,
                            AAlmacenOrigen,
                            AAlmacenDestino,
                            'S',
                            AArticulo,
                            ASku,
                            '',
                            ACantidad,
                            0,
                            ACliente,
                            AUsuario);

  // 1b. Entrada al almacén depósito
  InsertarMovimientoAlmacen(QryTrx,
                            'TR',
                            '',
                            '',
                            '0002',
                            AEmpresa,
                            AAlmacenDestino,
                            AAlmacenOrigen,
                            'E',
                            AArticulo,
                            ASku,
                            '',
                            ACantidad,
                            0,
                            ACliente,
                            AUsuario);

  // 2. Generar ID único para el depósito (lógica original)
  NuevoIdDep := 'DP' + FormatDateTime('yymmddhhnnsszzz', Now) +
                RightStr(ASku, 3);  // máx 20 chars
  NuevoIdDep := Copy(NuevoIdDep, 1, 20); // Aseguramos longitud máxima

  // 3. Crear registro de depósito llamando al Procedimiento Almacenado
  QryTrx.SQL.Text :=
    'CALL PRC_FZA_DEPOSITOS_INSERT(' +
    '  :ID_DEP, :EMP, :ALM_DEP, :CLI, :ART, :SKU, :PRECIO, :CANTIDAD, :ANTICIPO,' + // <-- Añadido :ALM_DEP
    '  :TIPOIVA, :PORCIVA, :IMPINCL, :USUARIO' +
    ')';

  QryTrx.ParamByName('ID_DEP').AsString     := NuevoIdDep;
  QryTrx.ParamByName('EMP').AsString        := AEmpresa;
  QryTrx.ParamByName('CLI').AsString        := ACliente;
  QryTrx.ParamByName('ART').AsString        := AArticulo;
  QryTrx.ParamByName('SKU').AsString        := ASku;
  QryTrx.ParamByName('PRECIO').AsCurrency   := APrecioVenta;
  QryTrx.ParamByName('ALM_DEP').AsString    := AAlmacenDestino;
  QryTrx.ParamByName('CANTIDAD').AsFloat    := ACantidad;
  QryTrx.ParamByName('ANTICIPO').AsCurrency := AAnticipo;
  QryTrx.ParamByName('TIPOIVA').AsString    := ATipoIVA;
  QryTrx.ParamByName('PORCIVA').AsCurrency  := APorcIVA;
  QryTrx.ParamByName('IMPINCL').AsString    := AEsImpIncl;
  QryTrx.ParamByName('USUARIO').AsString    := AUsuario;
  QryTrx.Execute;
end;

// =============================================================================
// ARCHIVO: UniDataCaja_GrabarFactura_v5.pas  — VERSIÓN FINAL
//
// GrabarFacturaSimplificada integra todos los procedimientos auxiliares:
//
//   InsertarCabeceraFactura    fza_facturas
//   InsertarLineaFactura       fza_facturas_lineas
//   InsertarOperacionCaja      fza_caja_operaciones
//   InsertarPagoCaja           fza_caja_pagos
//   InsertarMovimientoAlmacen  fza_movimientos_almacen
//
function TdmCajaOpe.GrabarFacturaSimplificada(
                          const AEmpresa,
                                AAlmacen,
                                ACaja,
                                ASerieElegida: string;
                          DatosCobro:          TDatosFaseCobro;
                          out SerieGenerada:   string;
                          out NumeroGenerado:  string;
                          out ValeGenerado:    string): Boolean;
var
  QryTrx:              TUniQuery;
  uspQryTrx:           TUniStoredProc;
  Cab:                 TDatosCabeceraFactura;
  Lin:                 TDatosLineaFactura;
  NumOperacionVE:      String;
  TotalFactura,
  DineroDisponible,
  ImporteDevuelto:     Currency;
  AlmacenDeposito,
  AlmacenOrigenSalida,
  TipoMov,
  NumMovGenerado:      string;
  UsuarioCaja:         string;
  NumLineaPago:        Integer;
  RequiereFactura:     Boolean;

  // ---------------------------------------------------------------------------
  // Inserta línea fiscal de anticipo (Solo si hay factura)
  // ---------------------------------------------------------------------------
  procedure InsertarLineaAnticipo(const Lin: TDatosLineaFactura; AImporte: Currency);
  var
    PrecioBase: Currency;
  begin
    if not RequiereFactura then Exit; // Candado de seguridad

    if Lin.PorcIva = 0 then
      PrecioBase := AImporte
    else
      PrecioBase := AImporte / (1 + Lin.PorcIva / 100);

    InsertarLineaFactura(
      QryTrx, SerieGenerada, NumeroGenerado,
      Lin.Linea, 'ANTICIPO', 'ANTICIPO',
      'Anticipo ' + Lin.Descripcion, '', '', '', 'SERVICIO', 'Uds',
      1, '', 'S', PrecioBase, 0, 0, PrecioBase, AImporte,
      Lin.TipoIva, Lin.PorcIva, PrecioBase, AImporte,
      UsuarioCaja, AAlmacen, ACaja, NumOperacionVE, '', UsuarioCaja);
  end;

begin
  Result         := False;
  SerieGenerada  := ASerieElegida;
  NumeroGenerado := '0';
  ValeGenerado   := '';
  NumLineaPago   := 0;
  UsuarioCaja     := cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString;
  // Generamos el número global de caja que agrupará toda la operación
//  NumOperacionVE := sOpeCaja;
  AlmacenDeposito := ObtenerAlmacenDepositoEmpresa(AEmpresa);
  if cdsCabecera.State in [dsEdit, dsInsert] then cdsCabecera.Post;
  if cdsLineas.State   in [dsEdit, dsInsert] then cdsLineas.Post;
  if cdsLineas.IsEmpty then
    raise Exception.Create('No se puede grabar una operación sin líneas.');
  if DatosCobro.ImporteEntregado < cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency then
  begin
    //es una operación de préstamo
    TransformarLineasParaCobroParcial(cdsLineas, DatosCobro.ImporteEntregado);
    if not CuadrarFacturaEnMemoria(cdsCabecera, cdsLineas) then
      raise Exception.Create('No se pudo cuadrar tras cobro parcial.');
  end;
  Cab          := LeerCabecera;
  TotalFactura := DatosCobro.ImporteEntregado;
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
      if (Accion = '') or (Accion = 'COBRAR') or (Accion = 'CANCELAR') then
      begin
        RequiereFactura := True;
        Break;
      end;
      if (Accion = 'NUEVO_DEP') or (Accion = 'AUMENTAR_DEP') then
      begin
        if DatosCobro.ImporteEntregado > 0.001 then
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
  // =======================================================================
  // INICIO DE LA TRANSACCIÓN GLOBAL EN BASE DE DATOS
  // =======================================================================
  inLibGlobalVar.oConn.StartTransaction;
  var sOpeCaja := SiguienteOpCaja(AEmpresa, AAlmacen, ACaja, UsuarioCaja);
  NumOperacionVE := sOpeCaja;
  NumeroGenerado := sOpeCaja;
  QryTrx := TUniQuery.Create(nil);
  try try
    QryTrx.Connection := inLibGlobalVar.oConn;
    // =======================================================================
    // PASO 1 Y 3: NÚMERO Y CABECERA (SOLO SI REQUIERE FACTURA)
    // =======================================================================
    if RequiereFactura then
    begin
      uspQryTrx := TUniStoredProc.Create(nil);
      try
        uspQryTrx.Connection := inLibGlobalVar.oConn;
        uspQryTrx.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
        uspQryTrx.Prepare;
        uspQryTrx.ParamByName('pserie').AsString   := SerieGenerada;
        uspQryTrx.ParamByName('pTipoDoc').AsString := 'FC';
        uspQryTrx.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
        uspQryTrx.ParamByName('pUSUARIOMODIF').AsString := UsuarioCaja;
        uspQryTrx.Execute;
        NumeroGenerado := uspQryTrx.ParamByName('pcont').AsString;
      finally
        uspQryTrx.Free;
      end;
      InsertarCabeceraFactura(
        QryTrx, SerieGenerada, NumeroGenerado, Cab.Fecha, 'SIMPLIFICADA', 'BORRADOR',
        AEmpresa, Cab.RazonSocialEmp, Cab.NifEmp, Cab.MovilEmp, Cab.EmailEmp,
        Cab.Direccion1Emp, Cab.Direccion2Emp, Cab.PoblacionEmp, Cab.ProvinciaEmp,
        Cab.CPostalEmp, Cab.CodigoPaisEmp, Cab.NombrePaisEmp, Cab.EsRetencionesEmp,
        Cab.GrupoZonaIvaEmp, Cab.CodigoCliente, Cab.RazonSocialCli, Cab.NifCli,
        Cab.MovilCli, Cab.EmailCli, Cab.Direccion1Cli, Cab.Direccion2Cli,
        Cab.PoblacionCli, Cab.ProvinciaCli, Cab.CPostalCli, Cab.CodigoPaisCli,
        Cab.NombrePaisCli, Cab.CodigoIva, Cab.Tarifa, Cab.EsIvaRecargo,
        Cab.EsIvaExento, Cab.EsImpInclTarifa,
        Cab.PorcIvaN, Cab.TotalIvaN, Cab.PorcReN, Cab.TotalReN, Cab.BaseIN,
        Cab.PorcIvaR, Cab.TotalIvaR, Cab.PorcReR, Cab.TotalReR, Cab.BaseIR,
        Cab.PorcIvaS, Cab.TotalIvaS, Cab.PorcReS, Cab.TotalReS, Cab.BaseIS,
        Cab.PorcIvaE, Cab.TotalIvaE, Cab.PorcReE, Cab.TotalReE, Cab.BaseIE,
        Cab.TotalBases, Cab.TotalImpuestos, Cab.TotalRetencion, Cab.PorcRetencion,
        Cab.TotalLiquido, Cab.FormaPago, Cab.Comentarios, '', '',
        AAlmacen, ACaja, UsuarioCaja, NumOperacionVE, UsuarioCaja);
    end
    else
    begin
      SerieGenerada := '';
      NumeroGenerado := '0';
    end;
    // =======================================================================
    // PASO 4: LÍNEAS
    // =======================================================================
    cdsLineas.DisableControls;
    try
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        Lin := LeerLineaActual;

        // -------------------------------------------------------------------
        // CASO A: ABONO DE ANTICIPO PREVIO
        // -------------------------------------------------------------------
        if Lin.VieneDeDeposito = 'A' then
        begin
          if RequiereFactura then
            InsertarLineaFactura(
              QryTrx, SerieGenerada, NumeroGenerado, Lin.Linea, Lin.Articulo, Lin.Sku,
              Lin.Descripcion, Lin.DescripcionVariacion, Lin.Familia, Lin.NombreFamilia,
              Lin.TipoArticulo, Lin.TipoCantidad, Lin.Cantidad, Lin.Tarifa, Lin.EsImpIncl,
              Lin.PrecioSalida, Lin.PorcDto, Lin.PrecioDto, Lin.PrecioSIva, Lin.PrecioCIva,
              Lin.TipoIva, Lin.PorcIva, Lin.TotalSIva, Lin.TotalCIva, UsuarioCaja,
              AAlmacen, ACaja, NumOperacionVE, '', UsuarioCaja);
          cdsLineas.Next;
          Continue;
        end;

        // -------------------------------------------------------------------
        // CASO B: CANCELACIÓN DE DEPÓSITO
        // -------------------------------------------------------------------
        if Lin.AccionDeposito = 'CANCELAR' then
        begin
          if RequiereFactura then
            InsertarLineaFactura(
              QryTrx, SerieGenerada, NumeroGenerado, Lin.Linea, Lin.Articulo, Lin.Sku,
              'Devolución anticipo ' + Lin.Descripcion, '', Lin.Familia, Lin.NombreFamilia,
              Lin.TipoArticulo, Lin.TipoCantidad, Lin.Cantidad, Lin.Tarifa, Lin.EsImpIncl,
              Lin.PrecioSalida, Lin.PorcDto, Lin.PrecioDto, Lin.PrecioSIva, Lin.PrecioCIva,
              Lin.TipoIva, Lin.PorcIva, Lin.TotalSIva, Lin.TotalCIva, UsuarioCaja,
              AAlmacen, ACaja, NumOperacionVE, '', UsuarioCaja);

          AnularDepositoCliente(
            QryTrx, CAB.CodigoCliente, Lin.Sku, UsuarioCaja, AAlmacen, AlmacenDeposito,
            AEmpresa, Lin.Articulo, ImporteDevuelto, Abs(Lin.Cantidad));

          if ImporteDevuelto > 0 then
            InsertarOperacionCaja(
              QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'DV', -ImporteDevuelto,
              UsuarioCaja, NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
              'Devolución anticipo: ' + Lin.Descripcion, SerieGenerada, NumeroGenerado);

          cdsLineas.Next;
          Continue;
        end;

        // -------------------------------------------------------------------
        // CASO C: NUEVO DEPÓSITO O AUMENTO DE ANTICIPO
        // -------------------------------------------------------------------
        if (Lin.AccionDeposito = 'NUEVO_DEP') or (Lin.AccionDeposito = 'AUMENTAR_DEP') then
        begin
          if Lin.TotalCIva > 0 then InsertarLineaAnticipo(Lin, Lin.TotalCIva);

          if Lin.AccionDeposito = 'AUMENTAR_DEP' then
          begin
            AumentarAnticipoDeposito(QryTrx, Cab.CodigoCliente, Lin.Sku, UsuarioCaja, Lin.TotalCIva);
            if Lin.TotalCIva > 0 then
              InsertarOperacionCaja(
                QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'CB', Lin.TotalCIva,
                UsuarioCaja, NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
                'Cobro a cuenta: ' + Lin.Descripcion);
          end
          else  // NUEVO_DEP
          begin
            CrearNuevoDepositoCliente(
              QryTrx, AEmpresa, Cab.CodigoCliente, Lin.Articulo, Lin.Sku, UsuarioCaja,
              Lin.PrecioOriginalDep, Lin.TotalCIva, AAlmacen, AlmacenDeposito,
              Lin.Cantidad, Lin.TipoIva, Lin.PorcIva, Lin.EsImpIncl);
            InsertarOperacionCaja(
              QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'DE', Lin.TotalCIva,
              UsuarioCaja, NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
              'Depósito: ' + Lin.Descripcion);
          end;
          cdsLineas.Next;
          Continue;
        end;
        // -------------------------------------------------------------------
        // CASO D: VENTA NORMAL O COBRO TOTAL DE DEPÓSITO EXISTENTE
        // -------------------------------------------------------------------
        if Lin.TipoArticulo = 'ESTANDAR' then
          NumMovGenerado := ObtenerSiguienteContador('MV')
        else
          NumMovGenerado := '';
        if Lin.VieneDeDeposito = 'S' then
        begin
          AlmacenOrigenSalida := cdsLineas.FieldByName('ALMACEN_ORIGEN_DEP_LINEA').AsString;
          CerrarDepositoCliente(QryTrx, Cab.CodigoCliente, Lin.Sku, UsuarioCaja);
          InsertarOperacionCaja(
            QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'DE', -Lin.PrecioOriginalDep,
            UsuarioCaja, NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
            'Cierre depósito: ' + Lin.Descripcion);
          InsertarOperacionCaja(
            QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VE', Lin.TotalCIva,
            UsuarioCaja, NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
            'Entrega depósito: ' + Lin.Descripcion);
        end
        else
          AlmacenOrigenSalida := AAlmacen;
        if Lin.Cantidad < 0 then
          TipoMov := 'E'
        else
          TipoMov := 'S';
        if RequiereFactura then
        begin
          InsertarLineaFactura(
            QryTrx, SerieGenerada, NumeroGenerado, Lin.Linea, Lin.Articulo, Lin.Sku,
            Lin.Descripcion, Lin.DescripcionVariacion, Lin.Familia, Lin.NombreFamilia,
            Lin.TipoArticulo, Lin.TipoCantidad, Lin.Cantidad, Lin.Tarifa, Lin.EsImpIncl,
            Lin.PrecioSalida, Lin.PorcDto, Lin.PrecioDto, Lin.PrecioSIva, Lin.PrecioCIva,
            Lin.TipoIva, Lin.PorcIva, Lin.TotalSIva, Lin.TotalCIva, UsuarioCaja,
            AAlmacen, ACaja, NumOperacionVE, NumMovGenerado, UsuarioCaja);
        end;
        // Pero el movimiento de almacén (fza_movimientos_almacen) se hace SIEMPRE
        if Lin.TipoArticulo = 'ESTANDAR' then
          InsertarMovimientoAlmacen(
            QryTrx, 'VE', SerieGenerada, NumeroGenerado, Lin.Linea,
            AEmpresa, AlmacenOrigenSalida, '', TipoMov, Lin.Articulo, Lin.Sku, Lin.Descripcion,
            Lin.Cantidad, 0, Cab.CodigoCliente, UsuarioCaja);
        cdsLineas.Next;
      end;
    finally
      cdsLineas.EnableControls;
    end;

    // =======================================================================
    // PASO 5: FORMAS DE PAGO (Se ejecuta siempre que haya importe)
    // =======================================================================
    NumLineaPago := 0;
    DatosCobro.MemTablePagos.First;
    while not DatosCobro.MemTablePagos.Eof do
    begin
      var CodigoFP  := DatosCobro.MemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
      var ImporteFP := DatosCobro.MemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;
      if Abs(ImporteFP) > 0.001 then
      begin
        Inc(NumLineaPago);
        InsertarPagoCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, SerieGenerada, NumOperacionVE, NumLineaPago,
          CodigoFP, ImporteFP, DatosCobro.MemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency);
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
          QryTrx, AEmpresa, AAlmacen, ACaja, SerieGenerada, NumOperacionVE, NumLineaPago,
          'VALE', DatosCobro.ValesRecogidos[i].ImporteAplicado, 0);

        InsertarOperacionCaja(
          QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VR',
          DatosCobro.ValesRecogidos[i].ImporteAplicado, UsuarioCaja,
          NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
          'Vale canjeado: ' + DatosCobro.ValesRecogidos[i].CodigoVale);
      end;
      MarcarValeComoCanjeado(
        DatosCobro.ValesRecogidos[i].CodigoVale, ACaja, AAlmacen, NumOperacionVE,
        SerieGenerada, NumeroGenerado);
    end;

    if DatosCobro.ImporteValeEmitido > 0 then
    begin
      ValeGenerado := EmitirNuevoVale(
        AEmpresa, AAlmacen, ACaja, NumOperacionVE, SerieGenerada, NumeroGenerado,
        DatosCobro.ImporteValeEmitido);

      InsertarOperacionCaja(
        QryTrx, AEmpresa, AAlmacen, ACaja, sOpeCaja, 'VL',
        -DatosCobro.ImporteValeEmitido, UsuarioCaja,
        NumeroGenerado, SerieGenerada, Cab.CodigoCliente,
        'Vale emitido: ' + ValeGenerado);
    end;

    // =======================================================================
    // PASO 7: ALBARÁN DE DEPÓSITO
    // =======================================================================
    var TieneDepositosPendientes := False;
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      var Accion := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;
      if (Accion = 'NUEVO_DEP') or (Accion = 'AUMENTAR_DEP') then
      begin
        TieneDepositosPendientes := True;
        Break;
      end;
      cdsLineas.Next;
    end;

    if TieneDepositosPendientes then
    begin
      QryTrx.SQL.Text :=
        'SELECT d.CODIGO_UNIDAD_DEP, d.CODIGO_ARTICULO_DEP, a.DESCRIPCION_ARTICULO, ' +
        '       d.PRECIO_VENTA_DEP, d.IMPORTE_ANTICIPO_DEP, ' +
        '       d.PRECIO_VENTA_DEP - d.IMPORTE_ANTICIPO_DEP AS PENDIENTE ' +
        '  FROM fza_depositos_cliente d ' +
        '  JOIN fza_articulos a ON a.CODIGO_ARTICULO = d.CODIGO_ARTICULO_DEP ' +
        ' WHERE d.CODIGO_CLIENTE_DEP = :CLI ' +
        '   AND d.ESTADO_DEP = ''PENDIENTE'' ' +
        ' ORDER BY d.INSTANTEALTA';
      QryTrx.ParamByName('CLI').AsString := Cab.CodigoCliente;
      QryTrx.Open;
      // TODO: ImprimirAlbaranDeposito(QryTrx, Cab.CodigoCliente, ACaja);
      QryTrx.Close;
    end;
    // =======================================================================
    // CONFIRMAR
    // =======================================================================
    inLibGlobalVar.oConn.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      inLibGlobalVar.oConn.Rollback;
      raise Exception.Create(
        'Error al guardar el ticket. No se ha registrado la operación.' +
        sLineBreak + 'Motivo: ' + E.Message);
    end;
  end;
  finally
    QryTrx.Free;
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
//     COMMENT 'VE=Venta, DE=Nuevo depósito, CB=Cobro a cuenta, DV=Devolución anticipo, VL=Vale emitido, VR=Vale recogido, AL=Albarán, EC=Entrada efectivo, GC=Gasto efectivo, TR=Traspaso almacén, AT=Traspaso empresa';

function TdmCajaOpe.CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
var
  CalculadorFiscal: TFacturaTotales;
begin
  Result := False;
  // Instanciamos tu clase pasándole los datasets de la caja
  CalculadorFiscal := TFacturaTotales.Create(dsCabecera, dsLineas);
  try
    // ProcesarFacturaCompleta se encarga de leer configuración, recorrer líneas y sumarizar
    Result := CalculadorFiscal.ProcesarFacturaCompleta;
    if not Result then
      raise Exception.Create('Error al cuadrar la factura: ' + CalculadorFiscal.MensajeError);
  finally
    CalculadorFiscal.Free;
  end;
end;

function TdmCajaOpe.EmitirNuevoVale(const AEmpresa, AAlmacen, ACaja: string;
                                    ANumOperacion: string;
                                    ASerieFactura, ANumFactura: string;
                                    AImporte: Currency): string;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := inLibGlobalVar.oConn;
    // =======================================================================
    // 1. OBTENER EL CÓDIGO FORMATEADO DESDE EL NUEVO PROCEDURE
    // =======================================================================
    qry.SQL.Text := 'CALL PRC_GENERAR_CODIGO_VALE(:pEmp, :pAlm, :pCaja, :pOp, :pUsu, :pCodigo)';
    qry.ParamByName('pEmp').AsString   := AEmpresa;
    qry.ParamByName('pAlm').AsString   := AAlmacen;
    qry.ParamByName('pCaja').AsString  := ACaja;
    qry.ParamByName('pOp').AsString   := ANumOperacion;
    // Le pasamos el nombre del cajero. Si quieres puedes leerlo del cdsCabecera:
    // cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString
    qry.ParamByName('pUsu').AsString   := oUser;
    // Parámetro de salida (OUT) para recoger el código generado (VARCHAR 100)
    qry.ParamByName('pCodigo').ParamType := ptOutput;
    qry.ParamByName('pCodigo').DataType  := ftString;
    qry.ParamByName('pCodigo').Size      := 100;
    qry.Execute;
    Result := qry.ParamByName('pCodigo').AsString;
    // =======================================================================
    // 2. INSERTAR EL NUEVO VALE EN LA BASE DE DATOS
    // =======================================================================
    qry.SQL.Text :=
      'INSERT INTO fza_caja_vales ' +
      '(CODIGO_VL, IMPORTE_VL, FECHA_EMISION_VL, ESTADO_VL, ' +
      ' CODIGO_CAJA_EMISION_VL, CODIGO_ALMACEN_EMISION_VL, ' +
      ' NUMERO_OPERACION_EMISION_VL, SERIE_FACTURA_EMISION_VL, NRO_FACTURA_EMISION_VL) ' +
      'VALUES ' +
      '(:COD, :IMPORTE, :FECHA, ''PENDIENTE'', ' +
      ' :CAJA, :ALMACEN, :NUMOP, :SERIE, :NUMFAC)';
    qry.ParamByName('COD').AsString        := Result;
    qry.ParamByName('IMPORTE').AsCurrency  := AImporte;
    qry.ParamByName('FECHA').AsDateTime    := Now;
    qry.ParamByName('CAJA').AsString       := ACaja;
    qry.ParamByName('ALMACEN').AsString    := AAlmacen;
    qry.ParamByName('NUMOP').AsString     := ANumOperacion;
    qry.ParamByName('SERIE').AsString      := ASerieFactura;
    qry.ParamByName('NUMFAC').AsString     := ANumFactura;
    qry.Execute;
  finally
    qry.Free;
  end;
end;

procedure TdmCajaOpe.InsertarPagoCaja(
                        QryTrx:           TUniQuery;
                        const AEmpresa:   string;
                        const AAlmacen:   string;
                        const ACaja:      string;
                        const ASerie:     string;    // serie de la operación de caja
                        ANumOperacion:    string;
                        ANumLinea:        Integer;   // 1, 2, 3... por forma de pago
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
    '  CODIGO_EMPRESA_PAGO,' +
    '  CODIGO_ALMACEN_PAGO,' +
    '  CODIGO_CAJA_PAGO,' +
    '  SERIE_OPERACION_PAGO,' +
    '  NUMERO_OPERACION_PAGO,' +
    '  NUMERO_LINEA_PAGO,' +
    '  CODIGO_FORMAP,' +
    '  IMPORTE_ENTREGADO_PAGO,' +
    '  IMPORTE_CAMBIO_PAGO,' +
    '  CODIGO_DIVISA_PAGO,' +
    '  RED_BLOCKCHAIN,' +
    '  FACTOR_CAMBIO_PAGO,' +
    '  IMPORTE_DIVISA_PAGO,' +
    '  REFERENCIA_PAGO,' +
    '  OBSERVACIONES_PAGO,' +
    '  USUARIOALTA, INSTANTEALTA) ' +
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
  QryTrx.ParamByName('USUARIO').AsString   := inLibGlobalVar.oUser;
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
    SpTrx.Connection := oConn;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    // 1. Creación y asignación explícita de parámetros IN
    SpTrx.Params.CreateParam(ftString, 'pEmpresa', ptInput).AsString := AEmpresa;
    SpTrx.Params.CreateParam(ftString, 'pAlmacen', ptInput).AsString := AAlmacen;
    SpTrx.Params.CreateParam(ftString, 'pCaja',    ptInput).AsString := ACaja;
    SpTrx.Params.CreateParam(ftString, 'pUsuario', ptInput).AsString := AEmpleado;
    // 2. Creación explícita de parámetros OUT
    SpTrx.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
    SpTrx.Params.CreateParam(ftString, 'pcont',  ptOutput).Size := 20;
    // 3. Preparar el SP en el motor de base de datos
    SpTrx.Prepare;
    // 4. Ejecutar
    SpTrx.Execute;
    // SerieOperacion := SpTrx.ParamByName('pSerie').AsString;  // misma en todas las llamadas
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    // Al liberar el componente también se hace el UnPrepare automáticamente
    SpTrx.Free;
  end;
end;

procedure TdmCajaOpe.InsertarOperacionCaja(
                        QryTrx:          TUniQuery;
                        const AEmpresa:  string;
                        const AAlmacen:  string;
                        const ACaja:     string;
                        ANumOperacion:   string;
                        const ATipoOp:   string;   // 'VE','VL','AL','CB','EC','GC','TR','AT'
                        AImporte:        Currency; // negativo en VL y AT
                        const AEmpleado: string;
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
                        const AEsTraspaso:       string = 'N');
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMPRESA_OPCAJA,' +
    '  CODIGO_ALMACEN_OPCAJA,' +
    '  CODIGO_CAJA_OPCAJA,' +
    '  NUMERO_OPERACION_OPCAJA,' +
    '  TIPO_OPERACION_OPCAJA,' +
    '  IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA,' +
    '  CODIGO_EMPLEADO_OPCAJA,' +
    '  NRO_FACTURA_OPCAJA,' +
    '  SERIE_FACTURA_OPCAJA,' +
    '  CODIGO_CLIENTE_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA,' +
    '  SERIE_REF_ORIGEN_OPCAJA,' +
    '  NUMERO_REF_ORIGEN_OPCAJA,' +
    '  MOTIVO_DEVOLUCION_OPCAJA,' +
    '  CODIGO_EMPRESA_CONTRA_OPCAJA,' +
    '  CODIGO_ALMACEN_CONTRA_OPCAJA,' +
    '  ES_TRASPASO_OPCAJA,' +
    '  ESTADO_DEVOLUCION_OPCAJA,' +
    '  USUARIOALTA, USUARIOMODIF, INSTANTEALTA) ' +
    'VALUES (' +
    '  :EMP,' +
    '  :ALM,' +
    '  :CAJA,' +
    '  :NUMOP,' +
    '  :TIPOOP,' +
    '  :IMPORTE,' +
    '  NOW(),' +
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
    '  ''N'',' +            // ESTADO_DEVOLUCION_OPCAJA: N por defecto, se actualiza en abonos
    '  :USUARIO, :USUARIO, NOW())';

  QryTrx.ParamByName('EMP').AsString      := AEmpresa;
  QryTrx.ParamByName('ALM').AsString      := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString     := ACaja;
  QryTrx.ParamByName('NUMOP').AsString    := ANumOperacion;
  QryTrx.ParamByName('TIPOOP').AsString   := ATipoOp;
  QryTrx.ParamByName('IMPORTE').AsCurrency:= AImporte;
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
  QryTrx.ParamByName('USUARIO').AsString  := inLibGlobalVar.oUser;
  QryTrx.Execute;
end;

function TdmCajaOpe.ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
var
  QryAlm: TUniQuery;
begin
  Result := '';
  QryAlm := TUniQuery.Create(nil);
  try
    // Usamos la conexión global del sistema
    QryAlm.Connection := inLibGlobalVar.oConn;
    QryAlm.SQL.Text :=
      'SELECT CODIGO_ALMACEN_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE CODIGO_EMPRESA_ALM = :EMP ' +
      '   AND ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''DEPÓSITO'' ' + // <-- Usando tu flag real
      ' LIMIT 1';
    QryAlm.ParamByName('EMP').AsString := AEmpresa;
    QryAlm.Open;
    if not QryAlm.IsEmpty then
      Result := QryAlm.FieldByName('CODIGO_ALMACEN_ALM').AsString
    else
      // Lanzamos excepción para que la transacción de caja se detenga si hay un error de configuración
      raise Exception.Create('No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ''DEPÓSITO'') activo para la empresa ' + AEmpresa + '.');
  finally
    QryAlm.Free;
  end;
end;

//procedure TdmCajaOpe.CalcularTotalesCabecera;
//var
//  Clon: TClientDataSet;
//  TotalLiquido, TotalBase, TotalImpuestos: Currency;
//  EstaEditando: Boolean;
//  RecNoActivo: Integer;
//begin
//  TotalLiquido := 0;
//  TotalBase := 0;
//  if cdsLineas.Active then
//  begin
//    RecNoActivo := cdsLineas.RecNo;
//    EstaEditando := (cdsLineas.State in [dsEdit, dsInsert]);
//    Clon := TClientDataSet.Create(nil);
//    try
//      Clon.CloneCursor(cdsLineas, True);
//      Clon.DisableControls;
//      Clon.First;
//      while not Clon.Eof do
//      begin
//        if EstaEditando and (Clon.RecNo = RecNoActivo) then
//        begin
//          TotalLiquido := TotalLiquido +
//		                cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase    := TotalBase    +
//		            cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end
//        else
//        begin
//          TotalLiquido := TotalLiquido +
//		                     Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase := TotalBase +
//		                 Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end;
//        Clon.Next;
//      end;
//    finally
//      Clon.EnableControls;
//      Clon.Free;
//    end;
//  end;
//  TotalImpuestos := TotalLiquido - TotalBase;
//  cdsCabecera.Edit;
//  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := TotalBase;
//  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency :=
//                                                                 TotalImpuestos;
//  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := TotalLiquido;
//  cdsCabecera.Post;
//  if Assigned(FOnUpdateTotal) then
//    FOnUpdateTotal(Self, TotalLiquido);
//end;

//procedure TdmCajaOpe.CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//var
//  PrecioUnitario, Cantidad, PorcenDto, PorcenIVA: Currency;
//  TotalBruto, MontoDescuentoTotal, TotalNeto: Currency;
//  TotalBase, TotalImpuestos: Currency;
//  EsImpuestosIncluidos: Boolean;
//begin
//  if not cdsLineas.Active then Exit;
//  if cdsLineas.State = dsBrowse then cdsLineas.Edit;
//  Cantidad := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsCurrency;
//  PrecioUnitario := cdsLineas.FieldByName(
//                                       'PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
//  PorcenIVA := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency;
//  EsImpuestosIncluidos := (cdsLineas.FieldByName(
//                             'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString = 'S');
//  TotalBruto := RoundTo(PrecioUnitario * Cantidad, -2);
//  if MantenerImporteDto then
//  begin
//    MontoDescuentoTotal := cdsLineas.FieldByName(
//                                         'PRECIO_DTO_FACTURA_LINEA').AsCurrency;
//    if TotalBruto <> 0 then
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat :=
//                                        (MontoDescuentoTotal * 100) / TotalBruto
//    else
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat := 0;
//  end
//  else
//  begin
//    // MODO B: Cambio normal. El % manda.
//    PorcenDto := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
//    // Calculamos el descuento sobre el Total Bruto
//    MontoDescuentoTotal := RoundTo(TotalBruto * (PorcenDto / 100), -2);
//    cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency := MontoDescuentoTotal;
//  end;
//  // 4. Aplicar el Descuento (Resta Global)
//  // Aquí está la corrección: TotalBruto - DescuentoTotal
//  TotalNeto := TotalBruto - MontoDescuentoTotal;
//  // 5. Desglose de Impuestos
//  if EsImpuestosIncluidos then
//  begin
//    // Si el precio incluye IVA, TotalNeto es el Total a Pagar
//    // Desglosamos hacia atrás
//    if (1 + (PorcenIVA / 100)) <> 0 then
//      TotalBase := RoundTo(TotalNeto / (1 + (PorcenIVA / 100)), -2)
//    else
//      TotalBase := TotalNeto;
//    // El total final es lo que dio la resta
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalNeto;
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//  end
//  else
//  begin
//    // Si el precio NO incluye IVA, TotalNeto es la Base Imponible Total
//    TotalBase := TotalNeto;
//    TotalImpuestos := RoundTo(TotalBase * (PorcenIVA / 100), -2);
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalBase + TotalImpuestos;
//  end;
//  CalcularTotalesCabecera;
//end;

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
    SQLStr := 'SELECT DIMINUTIVO_TICKET_USUARIO ' +
              '  FROM fza_usuarios ' +
              ' WHERE CODIGO_EMPLEADO_USUARIO = :COD';
    FieldToGet := 'DIMINUTIVO_TICKET_USUARIO';
  end
  else if TipoEntidad = 'CLIENTES' then
  begin
    SQLStr := 'SELECT RAZONSOCIAL_CLIENTE ' +
              '  FROM fza_clientes ' +
              ' WHERE CODIGO_CLIENTE = :COD';
    FieldToGet := 'RAZONSOCIAL_CLIENTE';
  end
  else
    Exit;
  unqry := TUniQuery.Create(nil);
  try
    unqry.Connection := oConn;
    unqry.SQL.Text := SQLStr;
    unqry.ParamByName('COD').AsString := Codigo;
    unqry.Open;
    if not unqry.IsEmpty then
    begin
      LabelDestino := unqry.FieldByName(FieldToGet).AsString;
      Result := True;
    end;
  finally
    unqry.Free;
  end;
end;

function TdmCajaOpe.GenerarSkuFinal(ArticuloBase: string): string;
var
  i: Integer;
  ValorAttr: string;
  SkuBuilder: string;
  NumAttr:Integer;
begin
  NumAttr := cdsLineas.FieldByName(
                         'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
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
  var sql := TUniQuery.Create(nil);
  try
    sql.Connection := oConn;
    sql.SQL.Text := 'SELECT CODIGO_TARIFA ' +
                    ' FROM fza_tarifas ' +
                    'WHERE ESDEFAULT_TARIFA = ' + QuotedStr('S') +
                    ' LIMIT 1 ' ;
    sql.Open;
    Result := sql.FieldByName('CODIGO_TARIFA').AsString;
    sql.Close;
  finally
    FreeAndNil(sql);
  end;
end;

//procedure TdmCajaOpe.InicializarNuevaFactura(const ASerieFactura,
//                                                   ANroFactura: string);
//begin
//  // Limpiar datos anteriores
//  if cdsLineas.Active then cdsLineas.EmptyDataSet;
//  if cdsCabecera.Active then cdsCabecera.EmptyDataSet;
//  // Crear nuevo registro de cabecera
//  cdsCabecera.Append;
////  cdsCabecera.FieldByName('SERIE_FACTURA').AsString := ASerieFactura;
////  cdsCabecera.FieldByName('NRO_FACTURA').AsString := ANroFactura;
////  cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime := Date;
////  cdsCabecera.FieldByName('ESCONSOLIDADA_FACTURA').AsString := 'N';
////
////  cdsCabecera.FieldByName('FASE_FACTURA').AsString := 'BORRADOR';
////  cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := 0;
////  cdsCabecera.FieldByName('INSTANTEALTA').AsDateTime := Now;
////  cdsCabecera.FieldByName('USUARIOALTA').AsString := 'SISTEMA';
////  // Inicializar totales a 0
////  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := 0;
////  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency := 0;
////  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := 0;
//
//  cdsCabecera.Post;
//end;

procedure TdmCajaOpe.cdsCabeceraAfterInsert(DataSet: TDataSet);
begin
  AplicarValoresPorDefecto(cdsCabecera, 'fza_facturas');
  cdsCabecera.FieldByName('SERIE_FACTURA').AsString := '0';
  cdsCabecera.FieldByName('TIPO_FACTURA').AsString := 'SIMPLIFICADA';
end;

procedure TdmCajaOpe.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  GridRecalc(nil,
             (Owner as TfrmMtoOpeCaja).cxGrid1DBTableView1,
             cdsLineas,
             cdsCabecera,
             OnUpdateTotal);
end;

procedure TdmCajaOpe.cdsLineasAfterInsert(DataSet: TDataSet);
var
  NuevoNumero: Integer;
begin
  with cdsLineas do
  begin
    AplicarValoresPorDefecto(cdsLineas, 'fza_facturas_lineas');
    FieldByName('SERIE_FACTURA_LINEA').AsString := '0';
    FieldByName('NRO_FACTURA_LINEA').AsString := '0';
    NuevoNumero := cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger
                                                                          + 10 ;
    cdsCabecera.Edit;
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := NuevoNumero;
    FieldByName('LINEA_FACTURA_LINEA').AsString :=
                                                  Format('%.4d', [NuevoNumero]);
    FieldByName('CODIGO_VENDEDOR_FACTURA_LINEA').AsString :=
                      cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString;
    FindField('PORCEN_IVA_FACTURA_LINEA').AsCurrency := GetTipoIVA(
          FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString);
  end;
end;

function TdmCajaOpe.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  with cdsCabecera do
  begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCEN_IVAN_FACTURA').AsCurrency;
    1: fPorcen := FindField('PORCEN_IVAR_FACTURA').AsCurrency;
    2: fPorcen := FindField('PORCEN_IVAS_FACTURA').AsCurrency;
    3: fPorcen := FindField('PORCEN_IVAE_FACTURA').AsCurrency;
    else
    begin
      fPorcen := FindField('PORCEN_IVAN_FACTURA').AsCurrency;
      cdsLineas.FindField('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := 'N';
    end;
  end;
  end;
  Result := fPorcen;
end;

procedure TdmCajaOpe.cdsLineasAfterPost(DataSet: TDataSet);
begin
//         GridRecalc(nil,
//             (Owner as TfrmMtoOpeCaja).cxGrid1DBTableView1,
//             cdsLineas,
//             cdsCabecera,
//             OnUpdateTotal);
end;

procedure TdmCajaOpe.cdsLineasBeforePost(DataSet: TDataSet);
var
  Requeridos: Integer;
  SkuActual: string;
begin
  // 1. Validar descripción
  if DataSet.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString = '' then
    Abort;
  // 2. Si no requiere atributos, OK
  Requeridos := DataSet.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  if Requeridos = 0 then
    Exit;
  // 3. Si requiere atributos pero el SKU no tiene "/" → ABORTAR
  SkuActual := Trim(DataSet.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString);
  if Pos('/', SkuActual) = 0 then
    Abort; // No permite grabar hasta que se complete el SKU
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  with cdsCabecera.FieldDefs do
  begin
    Add('SERIE_FACTURA', ftString, 20, True);
    Add('NRO_FACTURA', ftString, 20, True);
    Add('FECHA_FACTURA', ftDate, 0);
    Add('ESCONSOLIDADA_FACTURA', ftString, 1);
    Add('INSTANTECONSO_FACTURA', ftDateTime, 0);
    Add('TIPO_FACTURA', ftString, 20); // NORMAL, SIMPLIFICADA...
    Add('FASE_FACTURA', ftString, 20); // BORRADOR, ONLINE...
    Add('CODIGO_EMPRESA_FACTURA', ftString, 8);
    Add('RAZONSOCIAL_EMPRESA_FACTURA', ftString, 200);
    Add('NIF_EMPRESA_FACTURA', ftString, 50);
    Add('MOVIL_EMPRESA_FACTURA', ftString, 40);
    Add('EMAIL_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION1_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION2_EMPRESA_FACTURA', ftString, 200);
    Add('POBLACION_EMPRESA_FACTURA', ftString, 200);
    Add('PROVINCIA_EMPRESA_FACTURA', ftString, 200);
    Add('CODIGO_PAIS_EMPRESA_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_EMPRESA_FACTURA', ftString, 150);
    Add('CPOSTAL_EMPRESA_FACTURA', ftString, 15);
    Add('ESRETENCIONES_EMPRESA_FACTURA', ftString, 1);
    Add('GRUPO_ZONA_IVA_EMPRESA_FACTURA', ftString, 10);
    Add('ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA', ftString, 1);
    Add('CODIGO_CLIENTE_FACTURA', ftString, 10);
    Add('RAZONSOCIAL_CLIENTE_FACTURA', ftString, 200);
    Add('NIF_CLIENTE_FACTURA', ftString, 50);
    Add('MOVIL_CLIENTE_FACTURA', ftString, 40);
    Add('EMAIL_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION1_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION2_CLIENTE_FACTURA', ftString, 200);
    Add('POBLACION_CLIENTE_FACTURA', ftString, 200);
    Add('PROVINCIA_CLIENTE_FACTURA', ftString, 200);
    Add('CPOSTAL_CLIENTE_FACTURA', ftString, 15);
    Add('CODIGO_PAIS_CLIENTE_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_CLIENTE_FACTURA', ftString, 150);
    Add('CODIGO_CAJERO_FACTURA', ftString, 20);
    Add('CODIGO_IVA_FACTURA', ftString, 20);
    Add('ESIVA_RECARGO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIVA_EXENTO_CLIENTE_FACTURA', ftString, 1);
    Add('ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA', ftString, 1);
    Add('ESRETENCIONES_CLIENTE_FACTURA', ftString, 1);
    Add('TARIFA_ARTICULO_CLIENTE_FACTURA', ftString, 10);
    Add('ESIMP_INCL_TARIFA_CLIENTE_FACTURA', ftString, 1);
    Add('ESINTRACOMUNITARIO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESAPLICA_RE_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESIVAAGRICOLA_ZONA_IVA_FACTURA', ftString, 1);
    Add('PALABRA_REPORTS_ZONA_IVA_FACTURA', ftString, 10);
    Add('ESVENTA_ACTIVO_FIJO_FACTURA', ftString, 1);
    Add('PORCEN_IVAN_FACTURA', ftFloat, 0);
    Add('TOTAL_IVAN_FACTURA', ftCurrency, 0);
    Add('PORCEN_REN_FACTURA', ftFloat, 0);
    Add('TOTAL_REN_FACTURA', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAN_FACTURA', ftCurrency, 0);
    Add('PORCEN_IVAR_FACTURA', ftFloat, 0);
    Add('TOTAL_IVAR_FACTURA', ftCurrency, 0);
    Add('PORCEN_RER_FACTURA', ftFloat, 0);
    Add('TOTAL_RER_FACTURA', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAR_FACTURA', ftCurrency, 0);
    Add('PORCEN_IVAS_FACTURA', ftFloat, 0);
    Add('TOTAL_IVAS_FACTURA', ftCurrency, 0);
    Add('PORCEN_RES_FACTURA', ftFloat, 0);
    Add('TOTAL_RES_FACTURA', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAS_FACTURA', ftCurrency, 0);
    Add('PORCEN_IVAE_FACTURA', ftFloat, 0);
    Add('TOTAL_IVAE_FACTURA', ftCurrency, 0);
    Add('PORCEN_REE_FACTURA', ftFloat, 0);
    Add('TOTAL_REE_FACTURA', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAE_FACTURA', ftCurrency, 0);
    Add('TOTAL_BASES_FACTURA', ftCurrency, 0);
    Add('TOTAL_IMPUESTOS_FACTURA', ftCurrency, 0);
    Add('PORCEN_RETENCION_FACTURA', ftFloat, 0);
    Add('TOTAL_RETENCION_FACTURA', ftCurrency, 0);
    Add('TOTAL_LIQUIDO_FACTURA', ftCurrency, 0); // Lo que paga el cliente
    Add('FORMA_PAGO_FACTURA', ftString, 200);
    Add('NRO_FACTURA_ABONO_FACTURA', ftString, 8);
    Add('SERIE_FACTURA_ABONO_FACTURA', ftString, 8);
    Add('TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA', ftString, 1000);
    Add('TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA', ftString, 1000);
    Add('COMENTARIOS_FACTURA', ftString, 1000);
    Add('XML_FACTURA', ftMemo, 0); // Para VeriFactu
    Add('DOCUMENTO_FACTURA', ftBlob, 0);
    Add('CONTADOR_LINEAS_FACTURA', ftString, 8);
    Add('ESCREARARTICULOS_FACTURA', ftString, 1);
    Add('ESDESCRIPCIONES_AMP_FACTURA', ftString, 1);
    Add('ESFECHADEENTREGA_FACTURA', ftString, 1);
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;
  with cdsCabecera.IndexDefs.AddIndexDef do
  begin
    Name := 'PK_CABECERA';
    Fields := 'SERIE_FACTURA;NRO_FACTURA';
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
    Add('PRECIO_ORIGINAL_DEP', ftCurrency);
    Add('ACCION_DEPOSITO', ftString, 15); // Valores: 'COBRAR' o 'CANCELAR'
    Add('ANTICIPO_PREVIO', ftCurrency);   // Memoria del dinero adelantado
    // -- CLAVES DE ENLACE CON CABECERA (Foreign Keys) --
    Add('SERIE_FACTURA_LINEA', ftString, 20, True);
    Add('NRO_FACTURA_LINEA', ftString, 20, True);
    Add('LINEA_FACTURA_LINEA', ftString, 4, True);
    Add('CODIGO_VENDEDOR_FACTURA_LINEA', ftString, 20);
    // -- DATOS DEL ARTÍCULO (PADRE) --
    Add('CODIGO_ARTICULO_FACTURA_LINEA', ftString, 50);
    Add('CODIGO_FAMILIA_FACTURA_LINEA', ftString, 20);
    Add('NOMBRE_FAMILIA_FACTURA_LINEA', ftString, 200);
    Add('DESCRIPCION_ARTICULO_FACTURA_LINEA', ftString, 100);
    // El SKU exacto que descuenta stock (ej: ZAP-OXFORD/42/NEGRO)
    Add('CODIGO_UNIDAD_FACTURA_LINEA', ftString, 50);
    Add('TIPO_ARTICULO_FACTURA_LINEA', ftString, 10); // 'ESTANDAR' o 'SERVICIO'
    Add('NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger, 0);
    for var I := 1 to 5 do
    begin
      Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 50);
      Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 50);
    end;
    // DATOS DE TRAZABILIDAD (Si el artículo lo requiere)
    Add('LOTE_FACTURA_LINEA', ftString, 50);
    Add('FECHA_CADUCIDAD_FACTURA_LINEA', ftDate, 0);
    Add('PRECIO_ULT_COMPRA_FACTURA_LINEA', ftBCD, 0);
    Add('CODIGO_PROVEEDOR_FACTURA_LINEA', ftString, 20);
    Add('RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA', ftString, 200);
    Add('ESPROVEEDORPRINCIPAL_FACTURA_LINEA', ftString, 1);
    Add('FECHA_ENTREGA_FACTURA_LINEA', ftDateTime, 0);
    // -- CANTIDADES Y TARIFAS --
    Add('TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA', ftString, 20); // 'Uds', 'Kg'
    Add('ESIMP_INCL_TARIFA_FACTURA_LINEA', ftString, 1);
    Add('CODIGO_TARIFA_FACTURA_LINEA', ftString, 10);
    // IMPORTANTE: ftBCD maneja bien los decimales de MySQL (Decimal 19,6)
    Add('CANTIDAD_FACTURA_LINEA', ftFloat, 0);
    // -- PRECIOS Y DESCUENTOS --
    Add('PRECIOSALIDA_FACTURA_LINEA', ftCurrency, 0);
    Add('PORCEN_DTO_FACTURA_LINEA', ftFloat, 0);
    Add('PRECIO_DTO_FACTURA_LINEA', ftFloat, 0);
    // -- IMPORTES Y TOTALES --
    Add('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA', ftCurrency, 0);
    Add('TIPOIVA_ARTICULO_FACTURA_LINEA', ftString, 2);
    Add('PORCEN_IVA_FACTURA_LINEA', ftFloat, 0);
    Add('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA', ftCurrency, 0);
    Add('TOTAL_FACTURA_LINEA', ftCurrency, 0);
    Add('TOTAL_FACTURASIVA_LINEA', ftCurrency, 0);
    // -- CAMPOS DE AUDITORÍA --
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;
  with cdsLineas.IndexDefs.AddIndexDef do
  begin
    Name := 'PRIMARY_KEY';
    Fields := 'SERIE_FACTURA_LINEA;NRO_FACTURA_LINEA;LINEA_FACTURA_LINEA';
    Options := [ixPrimary, ixUnique];
  end;
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := oConn;
  qryVales.Connection := oConn;
  qryStock.Connection := oConn;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

procedure TdmCajaOpe.MarcarValeComoCanjeado(const ACodigoVale: string;
                                 ACodigoCaja: string;
                                 ACodigoAlmacen: string;
                                 ANumOperacion: string;
                                 ASerie: string;
                                 ANumFactura: String);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'UPDATE fza_caja_vales ' +
      '   SET ESTADO_VL = ''CANJEADO'', ' +
      '       FECHA_CANJE_VL = NOW(), ' +
      '       CODIGO_CAJA_CANJE_VL = :caja, ' +
      '       CODIGO_ALMACEN_CANJE_VL = :almacen, ' +
      '       NUMERO_OPERACION_CANJE_VL = :numop, ' +
      '       SERIE_FACTURA_CANJE_VL = :serie, ' +
      '       NRO_FACTURA_CANJE_VL = :numfac ' +
      ' WHERE CODIGO_VL = :codigo ' +
      '   AND ESTADO_VL = ''PENDIENTE''';
    qry.ParamByName('codigo').AsString := ACodigoVale;
    qry.ParamByName('caja').AsString := ACodigoCaja;
    qry.ParamByName('almacen').AsString := ACodigoAlmacen;
    qry.ParamByName('numop').AsString := ANumOperacion;
    qry.ParamByName('serie').AsString := ASerie;
    qry.ParamByName('numfac').AsString := ANumFactura;
    qry.ExecSQL;
  finally
    qry.Free;
  end;
end;

procedure TdmCajaOpe.InsertarCabeceraFactura(
            QryTrx:          TUniQuery;
            // — identificación —
            const ASerie:    string;
            const ANro:      string;
            AFecha:          TDateTime;
            const ATipo:     string;   // 'SIMPLIFICADA', 'NORMAL', 'RECTIFICATIVA'
            const AFase:     string;   // 'BORRADOR', 'ONLINE', etc.
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
            ANumOperacion:       String;
            const AUsuario:      string);
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_facturas (' +
    '  SERIE_FACTURA, NRO_FACTURA, FECHA_FACTURA,' +
    '  TIPO_FACTURA, FASE_FACTURA,' +
    '  CODIGO_EMPRESA_FACTURA, RAZONSOCIAL_EMPRESA_FACTURA, NIF_EMPRESA_FACTURA,' +
    '  MOVIL_EMPRESA_FACTURA, EMAIL_EMPRESA_FACTURA,' +
    '  DIRECCION1_EMPRESA_FACTURA, DIRECCION2_EMPRESA_FACTURA,' +
    '  POBLACION_EMPRESA_FACTURA, PROVINCIA_EMPRESA_FACTURA,' +
    '  CPOSTAL_EMPRESA_FACTURA, CODIGO_PAIS_EMPRESA_FACTURA, NOMBRE_PAIS_EMPRESA_FACTURA,' +
    '  ESRETENCIONES_EMPRESA_FACTURA, GRUPO_ZONA_IVA_EMPRESA_FACTURA,' +
    '  CODIGO_CLIENTE_FACTURA, RAZONSOCIAL_CLIENTE_FACTURA, NIF_CLIENTE_FACTURA,' +
    '  MOVIL_CLIENTE_FACTURA, EMAIL_CLIENTE_FACTURA,' +
    '  DIRECCION1_CLIENTE_FACTURA, DIRECCION2_CLIENTE_FACTURA,' +
    '  POBLACION_CLIENTE_FACTURA, PROVINCIA_CLIENTE_FACTURA,' +
    '  CPOSTAL_CLIENTE_FACTURA, CODIGO_PAIS_CLIENTE_FACTURA, NOMBRE_PAIS_CLIENTE_FACTURA,' +
    '  CODIGO_IVA_FACTURA, TARIFA_ARTICULO_CLIENTE_FACTURA,' +
    '  ESIVA_RECARGO_CLIENTE_FACTURA, ESIVA_EXENTO_CLIENTE_FACTURA,' +
    '  ESIMP_INCL_TARIFA_CLIENTE_FACTURA,' +
    '  PORCEN_IVAN_FACTURA, TOTAL_IVAN_FACTURA, PORCEN_REN_FACTURA, TOTAL_REN_FACTURA, TOTAL_BASEI_IVAN_FACTURA,' +
    '  PORCEN_IVAR_FACTURA, TOTAL_IVAR_FACTURA, PORCEN_RER_FACTURA, TOTAL_RER_FACTURA, TOTAL_BASEI_IVAR_FACTURA,' +
    '  PORCEN_IVAS_FACTURA, TOTAL_IVAS_FACTURA, PORCEN_RES_FACTURA, TOTAL_RES_FACTURA, TOTAL_BASEI_IVAS_FACTURA,' +
    '  PORCEN_IVAE_FACTURA, TOTAL_IVAE_FACTURA, PORCEN_REE_FACTURA, TOTAL_REE_FACTURA, TOTAL_BASEI_IVAE_FACTURA,' +
    '  TOTAL_BASES_FACTURA, TOTAL_IMPUESTOS_FACTURA,' +
    '  PORCEN_RETENCION_FACTURA, TOTAL_RETENCION_FACTURA,' +
    '  TOTAL_LIQUIDO_FACTURA,' +
    '  FORMA_PAGO_FACTURA,' +
    '  COMENTARIOS_FACTURA,' +
    '  SERIE_FACTURA_ABONO_FACTURA, NRO_FACTURA_ABONO_FACTURA,' +
    '  CODIGO_ALMACEN_FACTURA, CODIGO_CAJA_FACTURA,' +
    '  CODIGO_CAJERO_FACTURA, NUMERO_OPERACION_FACTURA,' +
    '  USUARIOALTA, USUARIOMODIF, INSTANTEALTA) ' +
    'VALUES (' +
    '  :SERIE, :NRO, :FECHA,' +
    '  :TIPO, :FASE,' +
    '  :EMP, :RSEMP, :NIFEMP,' +
    '  NULLIF(:MOVILEMP,  ''''), NULLIF(:EMAILEMP, ''''),' +
    '  NULLIF(:DIR1EMP,   ''''), NULLIF(:DIR2EMP,  ''''),' +
    '  NULLIF(:POBLEMP,   ''''), NULLIF(:PROVEMP,  ''''),' +
    '  NULLIF(:CPEMP,     ''''), :PAISEMP, NULLIF(:NPAISEMP, ''''),' +
    '  :RETREMP, NULLIF(:GRUPOIVAEMP, ''''),' +
    '  NULLIF(:CLI,       ''''), NULLIF(:RSCLI,    ''''), NULLIF(:NIFCLI,   ''''),' +
    '  NULLIF(:MOVILCLI,  ''''), NULLIF(:EMAILCLI, ''''),' +
    '  NULLIF(:DIR1CLI,   ''''), NULLIF(:DIR2CLI,  ''''),' +
    '  NULLIF(:POBLCLI,   ''''), NULLIF(:PROVCLI,  ''''),' +
    '  NULLIF(:CPCLI,     ''''), :PAISCLI, NULLIF(:NPAISCLI, ''''),' +
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
            const AAlmacen:      string;
            const ACaja:         string;
            ANumOperacion:       string;
            const ANumMovAlmacen:string;   // NUMERO_MOV de fza_movimientos_almacen
            const AUsuario:      string);
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_facturas_lineas (' +
    '  SERIE_FACTURA_LINEA, NRO_FACTURA_LINEA, LINEA_FACTURA_LINEA,' +
    '  CODIGO_ARTICULO_FACTURA_LINEA, CODIGO_UNIDAD_FACTURA_LINEA,' +
    '  DESCRIPCION_ARTICULO_FACTURA_LINEA, ' + //DESCRIPCION_VARIACION_FACTURA_LINEA,' +
    '  CODIGO_FAMILIA_FACTURA_LINEA, NOMBRE_FAMILIA_FACTURA_LINEA,' +
    '  TIPO_ARTICULO_FACTURA_LINEA, TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA,' +
    '  CANTIDAD_FACTURA_LINEA,' +
    '  CODIGO_TARIFA_FACTURA_LINEA, ESIMP_INCL_TARIFA_FACTURA_LINEA,' +
    '  PRECIOSALIDA_FACTURA_LINEA,' +
    '  PORCEN_DTO_FACTURA_LINEA, PRECIO_DTO_FACTURA_LINEA,' +
    '  PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA,' +
    '  PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA,' +
    '  TIPOIVA_ARTICULO_FACTURA_LINEA, PORCEN_IVA_FACTURA_LINEA,' +
    '  TOTAL_FACTURASIVA_LINEA, TOTAL_FACTURA_LINEA,' +
    '  CODIGO_VENDEDOR_FACTURA_LINEA,' +
    '  CODIGO_ALMACEN_FACTURA_LINEA, CODIGO_CAJA_FACTURA_LINEA,' +
    '  NUMERO_OPERACION_FACTURA_LIENA,' +   // sic — typo en el nombre de columna de la BD
    '  NUMERO_MOV_FACTURA_LINEA,' +
    '  USUARIOALTA, USUARIOMODIF, INSTANTEALTA) ' +
    'VALUES (' +
    '  :SERIE, :NRO, :LINEA,' +
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
