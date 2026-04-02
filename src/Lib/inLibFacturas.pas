unit inLibFacturas;

interface

uses
  Uni, System.StrUtils, System.SysUtils, System.Classes, Data.DB, System.Math,
  Datasnap.DBClient, Datasnap.Provider, inLibGlobalVar;

const
  fnrofaclin = 'NRO_FACTURA_LINEA';
  fserielin = 'SERIE_FACTURA_LINEA';
  fnrolin = 'LINEA_FACTURA_LINEA';
  fescon = 'ESCONSOLIDADA_FACTURA';
  fcodart = 'CODIGO_ARTICULO_FACTURA_LINEA';
  fdesart = 'DESCRIPCION_ARTICULO_FACTURA_LINEA';
  fcodprov = 'CODIGO_PROVEEDOR_FACTURA_LINEA';
  frazprov = 'RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA';
  fpprov = 'ESPROVEEDORPRINCIPAL_FACTURA_LINEA';
  fcodfam = 'CODIGO_FAMILIA_FACTURA_LINEA';
  fnomfam = 'NOMBRE_FAMILIA_FACTURA_LINEA';
  ffechentr = 'FECHA_ENTREGA_FACTURA_LINEA';
  ftipocant = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA';
  fimpcl = 'ESIMP_INCL_TARIFA_FACTURA_LINEA';
  ftipiva = 'TIPOIVA_ARTICULO_FACTURA_LINEA';
  fdescripcion = 'DESCRIPCION_ARTICULO_FACTURA_LINEA';
  fcodtariflin = 'CODIGO_TARIFA_FACTURA_LINEA';
  fcant = 'CANTIDAD_FACTURA_LINEA';
  fpreciosal = 'PRECIOSALIDA_FACTURA_LINEA';
  fprecultc = 'PRECIO_ULT_COMPRA_FACTURA_LINEA';
  fpordto = 'PORCEN_DTO_FACTURA_LINEA';
  fdto = 'PRECIO_DTO_FACTURA_LINEA';
  fpresiva = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA';
  fporiva = 'PORCEN_IVA_FACTURA_LINEA';
  fpreciva = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA';
  ftotciva = 'TOTAL_FACTURA_LINEA';
  ftotsiva = 'TOTAL_FACTURASIVA_LINEA';

  ffechfac = 'FECHA_FACTURA';
  fnrofac = 'NRO_FACTURA';
  fseriefac = 'SERIE_FACTURA';
  fcodemp = 'CODIGO_EMPRESA_FACTURA';
  fcodcli = 'CODIGO_CLIENTE_FACTURA';
  factfij = 'ESVENTA_ACTIVO_FIJO_FACTURA';
  fcreart = 'ESCREARARTICULOS_FACTURA';
  fporivan = 'PORCEN_IVAN_FACTURA';
  ftotivan = 'TOTAL_IVAN_FACTURA';
  fporren = 'PORCEN_REN_FACTURA';
  ftotren = 'TOTAL_REN_FACTURA';
  ftotbasen = 'TOTAL_BASEI_IVAN_FACTURA';
  fporivar = 'PORCEN_IVAR_FACTURA';
  ftotivar = 'TOTAL_IVAR_FACTURA';
  fporrer = 'PORCEN_RER_FACTURA';
  ftotrer = 'TOTAL_RER_FACTURA';
  ftotbaser = 'TOTAL_BASEI_IVAR_FACTURA';
  fporivas = 'PORCEN_IVAS_FACTURA';
  ftotivas = 'TOTAL_IVAS_FACTURA';
  fporres = 'PORCEN_RES_FACTURA';
  ftotres = 'TOTAL_RES_FACTURA';
  ftotbases = 'TOTAL_BASEI_IVAS_FACTURA';
  fporivae = 'PORCEN_IVAE_FACTURA';
  ftotivae = 'TOTAL_IVAE_FACTURA';
  fporree = 'PORCEN_REE_FACTURA';
  ftotree = 'TOTAL_REE_FACTURA';
  ftotbasee = 'TOTAL_BASEI_IVAE_FACTURA';
  ftotallifac = 'TOTAL_LIQUIDO_FACTURA';
  fporirpf = 'PORCEN_RETENCION_FACTURA';
  ftotirpf = 'TOTAL_RETENCION_FACTURA';
  ftotimp = 'TOTAL_IMPUESTOS_FACTURA';
  ftotbasefac = 'TOTAL_BASES_FACTURA';

type
  TTipoIVA = (tivaNormal, tivaReducido, tivaSuperReducido, tivaExento);

  TTotalesIVA = record
    BaseImponible: Currency;
    PorcentajeIVA: Currency;
    ImporteIVA: Currency;
    PorcentajeRE: Currency;
    ImporteRE: Currency;
  end;

  TTotalesFactura = record
    BaseNormal,
    BaseReducida,
    BaseSuper,
    BaseExenta: Currency;
    CuotaIVANormal,
    CuotaIVAReducida,
    CuotaIVASuper,
    CuotaIVAExenta: Currency;
    CuotaRENormal,
    CuotaREReducida,
    CuotaRESuper,
    CuotaREExenta: Currency;
    TotalBases: Currency;
    TotalImpuestos: Currency;
    TotalRetencion: Currency;
    TotalLiquido: Currency;
    TotalIVANormal: Currency;
    TotalIVAReducido: Currency;
    TotalIVASuperReducido: Currency;
    TotalIVAExento: Currency;
    TotalREcargo: Currency;
    TotalCantidades:Currency;
    IVAN: TTotalesIVA;
    IVAR: TTotalesIVA;
    IVAS: TTotalesIVA;
    IVAE: TTotalesIVA;

    TotalBruto: Currency;
    TotalDescuentosLineas: Currency;
  end;

  TConfiguracionFactura = record
    EsFacturaSimplificada: Boolean;
    EsRegimenAgricolaEmpresa: Boolean;
    EsRegimenAgricolaCliente: Boolean;
    EsIntracomunitario: Boolean;
    EsVentaActivoFijo: Boolean;
    AplicaRecargo: Boolean;
    AplicaRetencionesCliente: Boolean;
    AplicaRetencionesEmpresa: Boolean;
    IVAExento: Boolean;
    IRPFImpuestoIncluido: Boolean;
    IVARecargo: Boolean;
  end;

  TPorcentajesImpuestos = record
    IVANormal: Currency;
    IVAReducido: Currency;
    IVASuperReducido: Currency;
    IVAExento: Currency;
    REcNormal: Currency;
    REcReducido: Currency;
    REcSuperReducido: Currency;
    REcExento: Currency;
  end;

  TFacturaTotales = class;

  TLinFac = class
  private
    _unqryLin: TDataset;
    _unqryFac: TDataset;
    _sImpcl: string;
    _sTipIva: string;
    _sNumLin: String;
    _dPrecioSal: currency;
    _dPorDto: currency;
    _dDto: currency;
    _dPreSiva: currency;
    _dPreCiva: currency;
    _dPoriva: currency;
    _dCant: currency;
    _dTotCiva: currency;
    _dTotSiva: currency;
    _dPorIvaN: currency;
    _dPorIvaR: currency;
    _dPorIvaS: currency;
    _dPorIvaE: currency;
    _sMensajeError: string;
    function GetPrecioSal: Currency;
    procedure SetPrecioSal(const Value: Currency);
    function GetPorDto: Currency;
    procedure SetPorDto(const Value: Currency);
    function GetDto: Currency;
    procedure SetDto(const Value: Currency);
    function GetPreSiva: Currency;
    procedure SetPreSiva(const Value: Currency);
    function GetPreCiva: Currency;
    procedure SetPreCiva(const Value: Currency);
    function GetCant: Currency;
    procedure SetCant(const Value: Currency);
    function GetPorIva: Currency;
    procedure SetPorIva(const Value: Currency);
    function GetTotCiva: Currency;
    procedure SetTotCiva(const Value: Currency);
    function GetTotSiva: Currency;
    procedure SetTotSiva(const Value: Currency);
    function GetImpcl: String;
    procedure SetImpcl(const Value: String);
    function GetTipoIVa: String;
    procedure SetTipoIva(const Value: String);

  public
    Property PrecioSal: Currency read GetPrecioSal write SetPrecioSal;
    Property PorDto: Currency read GetPorDto write SetPorDto;
    Property Dto: Currency read GetDto write SetDto;
    Property PorIva: Currency read GetPorIva write SetPorIva;
    Property TipoIva: String read GetTipoIVa write SetTipoIva;
    Property PreSiva: Currency read GetPreSiva write SetPreSiva;
    Property PreCiva: Currency read GetPreCiva write SetPreCiva;
    Property Cant: Currency read GetCant write SetCant;
    Property TotCiva: Currency read GetTotCiva write SetTotCiva;
    Property TotSiva: Currency read GetTotSiva write SetTotSiva;
    Property Impcl: String read GetImpcl write SetImpcl;
    Property MensajeError: String read _sMensajeError;

  public
    constructor Create(unqryLin: TDataset); overload;
    constructor Create(unqryLin, unqryFac: TDataset;
                       bCalcularFactura:boolean = false); overload;
    destructor Destroy; override;
    procedure CopyToDataSetLin;
    procedure CopyToDataSetFac;
    procedure CopyToObjectLin;
    procedure CopyToObjectFac;
    procedure SetInit(unqryLin: TDataset);
    procedure CalcularLinea;
    function ValidarDatos: Boolean;
    function EsDevolucion: Boolean;
  end;

  TFacturaTotales = class
  private
    _unqryFac: TDataset;
    _unqryLineas: TDataset;
    _totales: TTotalesFactura;
    _configuracion: TConfiguracionFactura;
    _porcentajes: TPorcentajesImpuestos;
    _dPorRetencion: Currency;
    _fechaFactura: TDateTime;
    _codigoEmpresa: string;
    _grupoZonaIVA: string;
    _codigoIVA: string;
    _mensajeError: string;
    _LineaenEdicion:TLinFac;
    procedure InicializarTotales;
    procedure InicializarConfiguracion;
    procedure LeerDatosFactura;
    procedure LeerPorcentajesDesdeFactura;
    procedure AplicarReglas;
    procedure RecorrerYCalcularLineasConClientDataSet;
    procedure AcumularTotalesPorTipoIVA(linea: TLinFac);
    procedure CalcularTotalesGenerales;
    procedure CalcularRetenciones;
    procedure ValidarConfiguracion;
    procedure VerificarYCompletarDatosEmpresa;
    procedure CargarConfiguracionIVA(sGrupoZona: string);
    procedure VerificarYCompletarDatosCliente;
    function ObtenerPorcentajePorTipo(tipo: string): Currency;
    function ObtenerPorcentajeREPorTipo(tipo: string): Currency;
    function BuscarPorcenRetencion(CodEmpresa: string): Currency;
    function BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
  public
    FTieneLineasNegativas:Boolean;
    constructor Create(unqryFac: TDataset;
                       unqryLineas: TDataset;
                       LineaEnEdicion:TLinFac = nil);
    destructor Destroy; override;
    function ProcesarFacturaCompleta: Boolean;
    procedure CalcularTotalesFactura;
    procedure ActualizarTotalesEnDataSet;
    function ValidarFactura: Boolean;
    property Totales: TTotalesFactura read _totales;
    property Configuracion: TConfiguracionFactura read _configuracion;
    property Porcentajes: TPorcentajesImpuestos read _porcentajes;
    property PorcentajeRetencion: Currency read _dPorRetencion write _dPorRetencion;
    property MensajeError: string read _mensajeError;
  end;
  function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;


implementation

function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

{ TLinFac - Implementación completa }

constructor TLinFac.Create(unqryLin: TDataset);
begin
  inherited Create;
  _unqryLin := unqryLin;
  Self.CopyToObjectLin;
end;

constructor TLinFac.Create(unqryLin, unqryFac: TDataset;
                           bCalcularFactura:boolean = false);
begin
  inherited Create;
  _unqryLin := unqryLin;
  _unqryFac := unqryFac;
  _sMensajeError := '';
  Self.CopyToObjectLin;
  Self.CopyToObjectFac;
end;

destructor TLinFac.Destroy;
begin
  if ValidarDatos then
  begin
    Self.CopyToDataSetLin;
  end;
  inherited Destroy;
end;

function TLinFac.ValidarDatos: Boolean;
begin
  Result := True;
  _sMensajeError := '';
  if (_dPorIva < 0) or (_dPorIva > 100) then
  begin
    _sMensajeError := 'El porcentaje de IVA debe estar entre 0 y 100';
    raise Exception.Create(_sMensajeError);
    Result := False;
    Exit;
  end;
  if (_dPreSiva < 0) or (_dPreCiva < 0) then
  begin
    _sMensajeError := 'Los precios no pueden ser negativos';
    raise Exception.Create(_sMensajeError);
    Result := False;
    Exit;
  end;
end;

function TLinFac.EsDevolucion: Boolean;
begin
  Result := _dCant < 0;
end;

procedure TLinFac.CalcularLinea;
begin
  if not ValidarDatos then
    raise Exception.Create(_sMensajeError);
  if (SameText(_sImpcl, 'S')) then
  begin
    if (_dPorIva = 0) then
      _dPreSiva := _dPreCiva
    else
      _dPreSiva := _dPreCiva / (1 + _dPorIva/100);
    _dTotSiva := _dPreSiva * _dCant;
    _dTotCiva := _dPreCiva * _dCant;
    if (_dPrecioSal <> 0) then
    begin
      _dDto := _dPrecioSal - _dPreCiva;
      if _dPrecioSal <> 0 then
        _dPorDto := (_dDto / _dPrecioSal) * 100
      else
        _dPorDto := 0;
    end;
  end
  else
  begin
    _dPreCiva := _dPreSiva * (1 + _dPorIva/100);
    _dTotCiva := _dPreCiva * _dCant;
    _dTotSiva := _dPreSiva * _dCant;
    if (_dPrecioSal <> 0) then
    begin
      _dDto := _dPrecioSal - _dPreSiva;
      if _dPrecioSal <> 0 then
        _dPorDto := (_dDto / _dPrecioSal) * 100
      else
        _dPorDto := 0;
    end;
  end;
end;

procedure TLinFac.CopyToDataSetLin;
begin
  if not Assigned(_unqryLin) then
    Exit;
  with _unqryLin do
  begin
    if State = dsBrowse then Edit;
    FieldByName(fcant).AsFloat := _dCant;
    FieldByName(fpreciosal).AsFloat := _dPrecioSal;
    FieldByName(fPorDto).AsFloat := _dPorDto;
    FieldByName(fDto).AsFloat := _dDto;
    FieldByName(fImpcl).AsString := _sImpcl;
    FieldByName(fTipIVa).AsString := _sTipIva;
    FieldByName(fPorIva).AsFloat := _dPorIVa;
    FieldByName(fPreSiva).AsFloat := _dPreSiva;
    FieldByName(fPreCiva).AsFloat := _dPreCiva;
    FieldByName(fTotCiva).AsFloat := _dTotCiva;
    FieldByName(fTotSiva).AsFloat := _dTotSiva;
  end;
end;

procedure TLinFac.CopyToDataSetFac;
begin
  // Implementar si es necesario para actualizar campos de la factura
end;

procedure TLinFac.CopyToObjectLin;
begin
  with _unqryLin do
  begin
    _sNumLin := FieldByName(fnrolin).AsString;
    _dCant := FieldByName(fcant).AsFloat;
    if FieldByName(fImpcl).AsString = '' then
      _sImpcl := 'S'
    else
      _sImpcl := FieldByName(fImpcl).AsString;
    _sTipIVA := FieldByName(fTipIva).AsString;
    _dPorIVa := FieldByName(fPorIva).AsFloat;
    _dPrecioSal := FieldByName(fpreciosal).AsFloat;
    _dPorDto := FieldByName(fPorDto).AsFloat;
    _dDto := FieldByName(fDto).AsFloat;
    _dPreSiva := FieldByName(fPreSiva).AsFloat;
    _dPreCiva := FieldByName(fPreCiva).AsFloat;
    _dTotCiva := FieldByName(fTotCiva).AsFloat;
    _dTotSiva := FieldByName(fTotSiva).AsFloat;
  end;
end;

procedure TLinFac.CopyToObjectFac;
begin
  //if not Assigned(_unqryFac) then Exit;
  with _unqryFac do
  begin
    _dPorIvaN := FieldByName(fPorIvaN).AsFloat;
    _dPorIvaR := FieldByName(fPorIVAR).AsFloat;
    _dPorIvaS := FieldByName(fPorIVAS).AsFloat;
    _dPorIVAE := FieldByName(fPorIVAE).AsFloat;
  end;
end;

procedure TLinFac.SetInit(unqryLin: TDataset);
begin
  _unqryLin := unqryLin;
end;

// Getters y Setters
function TLinFac.GetCant: Currency;
begin
  Result := _dCant;
end;

procedure TLinFac.SetCant(const Value: Currency);
begin
  _dCant := Value;
  if _dPreSiva <> 0 then
    _dTotSiva := _dCant * _dPreSiva;
  if _dPreCiva <> 0 then
    _dTotCiva := _dCant * _dPreCiva;
end;

function TLinFac.GetDto: Currency;
begin
  Result := _dDto;
end;

procedure TLinFac.SetDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dDto := Value;
  if (_dPrecioSal <> 0) then
  begin
    _dPorDto := (_dDto / _dPrecioSal) * 100;
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetImpcl: String;
begin
  Result := _sImpcl;
end;

procedure TLinFac.SetImpcl(const Value: String);
begin
  _sImpcl := Value;
end;

function TLinFac.GetPorDto: Currency;
begin
  Result := _dPorDto;
end;

procedure TLinFac.SetPorDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dPorDto := Value;
  if _dPrecioSal <> 0 then
  begin
    _dDto := _dPrecioSal * (_dPorDto / 100);
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetPorIva: Currency;
begin
  Result := _dPorIva;
end;

procedure TLinFac.SetPorIva(const Value: Currency);
begin
  _dPorIVa := Value;
end;

function TLinFac.GetPrecioSal: Currency;
begin
  Result := _dPrecioSal;
end;

procedure TLinFac.SetPrecioSal(const Value: Currency);
var
  dPrecioFinal: Currency;
begin
  _dPrecioSal := Value;
  SetPorDto(_dPorDto);   //recalculo el dto
  dPrecioFinal := _dPrecioSal - _dDto;
  if SameText(Impcl, 'S') then
  begin
    SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
  end
  else
  begin
    SetPreSiva(dPrecioFinal);
  end;
end;

function TLinFac.GetPreCiva: Currency;
begin
  Result := _dPreCiva;
end;

procedure TLinFac.SetPreCiva(const Value: Currency);
begin
  _dPreCiva := Value;
  _dPreSiva := _dPreCiva / (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotCiva := _dCant * _dPreCiva;
    _dTotSiva := _dCant * _dPreSiva;
  end;
end;

function TLinFac.GetPreSiva: Currency;
begin
  Result := _dPreSiva;
end;

procedure TLinFac.SetPreSiva(const Value: Currency);
begin
  _dPreSiva := Value;
  _dPreCiva := _dPreSiva * (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotSiva := _dCant * _dPreSiva;
    _dTotCiva := _dCant * _dPreCiva;
  end;
end;

function TLinFac.GetTipoIVa: String;
begin
  Result := _sTipIva;
end;

procedure TLinFac.SetTipoIva(const Value: String);
var
  dPorcen: Currency;
begin
  _sTipIVa := Value;
  dPorcen := 0;
  if Assigned(_unqryFac) then
  begin
    with _unqryFac do
    begin
      case IndexStr(_sTipIVA, ['N', 'R', 'S', 'E']) of
        0: if FindField(fPorIvaN) <> nil then
             dPorcen := FieldByName(fPorIvaN).AsCurrency;
        1: if FindField(fPorIVAR) <> nil then
             dPorcen := FieldByName(fPorIVAR).AsCurrency;
        2: if FindField(fPorIVAS) <> nil then
             dPorcen := FieldByName(fPorIVAS).AsCurrency;
        3: if FindField(fPorIVAE) <> nil then
             dPorcen := FieldByName(fPorIVAE).AsCurrency;
      end;
    end;
  end;
  Self.PorIva := dPorcen;
end;

function TLinFac.GetTotCiva: Currency;
begin
  Result := _dTotCiva;
end;

procedure TLinFac.SetTotCiva(const Value: Currency);
begin
  _dTotCiva := Value;
end;

function TLinFac.GetTotSiva: Currency;
begin
  Result := _dTotSiva;
end;

procedure TLinFac.SetTotSiva(const Value: Currency);
begin
  _dTotSiva := Value;
end;

{ TFacturaTotales - Implementación completa }

constructor TFacturaTotales.Create(unqryFac: TDataset;
                                   unqryLineas: TDataset;
                                   LineaEnEdicion:TLinFac = nil);
begin
  inherited Create;
  _unqryFac := unqryFac;
  _unqryLineas := unqryLineas;
  _LineaEnEdicion := LineaEnEdicion;
  //_unqryLineasTemp := nil;
  _dPorRetencion := 0;
  _mensajeError := '';
  //_lineaEnEdicion := '';
  // _excluirLineaEnEdicion := False;

  InicializarTotales;
  InicializarConfiguracion;

  //ProcesarFacturaCompleta;
end;

destructor TFacturaTotales.Destroy;
begin
  // LiberarDatasetTemporal;
  inherited Destroy;
end;

procedure TFacturaTotales.InicializarTotales;
begin
  FillChar(_totales, SizeOf(_totales), 0);
end;

procedure TFacturaTotales.InicializarConfiguracion;
begin
  FillChar(_configuracion, SizeOf(_configuracion), 0);
  FillChar(_porcentajes, SizeOf(_porcentajes), 0);
  _grupoZonaIVA := '';
  _codigoIVA := '';
  _codigoEmpresa := '';
  _fechaFactura := 0;
  _mensajeError := '';
end;

procedure TFacturaTotales.LeerDatosFactura;
begin
  with _unqryFac do
  begin
    _fechaFactura      := FieldByName('FECHA_FACTURA').AsDateTime;
    _codigoEmpresa := FieldByName('CODIGO_EMPRESA_FACTURA').AsString;
    _configuracion.EsFacturaSimplificada :=
                 SameText(FieldByName('TIPO_FACTURA').AsString, 'SIMPLIFICADA');
    VerificarYCompletarDatosEmpresa;
    VerificarYCompletarDatosCliente;
    _configuracion.EsRegimenAgricolaEmpresa :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA').AsString = 'S');
    _configuracion.EsRegimenAgricolaCliente :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA').AsString = 'S');
    _configuracion.EsIntracomunitario       :=
             (FieldByName('ESINTRACOMUNITARIO_CLIENTE_FACTURA').AsString = 'S');
    _configuracion.EsVentaActivoFijo        :=
                    (FieldByName('ESVENTA_ACTIVO_FIJO_FACTURA').AsString = 'S');
    _configuracion.AplicaRetencionesCliente :=
                  (FieldByName('ESRETENCIONES_CLIENTE_FACTURA').AsString = 'S');
    _configuracion.AplicaRetencionesEmpresa :=
                  (FieldByName('ESRETENCIONES_EMPRESA_FACTURA').AsString = 'S');
    _configuracion.IVAExento  :=
                   (FieldByName('ESIVA_EXENTO_CLIENTE_FACTURA').AsString = 'S');
    _configuracion.IVARecargo :=
                  (FieldByName('ESIVA_RECARGO_CLIENTE_FACTURA').AsString = 'S');
    if FindField('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA') <> nil then
       _configuracion.IRPFImpuestoIncluido :=
                (FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA').AsString = 'S')
    else
       _configuracion.IRPFImpuestoIncluido := False;
    if SameText(FindField('ESAPLICA_RE_ZONA_IVA_FACTURA').AsString, 'N') then
       _configuracion.AplicaRecargo := false;
    _grupoZonaIVA := FieldByName('GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString;
    _CodigoIVA    := FieldByName('CODIGO_IVA_FACTURA').AsString;
    _dPorRetencion := FieldByName('PORCEN_RETENCION_FACTURA').AsFloat;
  end;
  LeerPorcentajesDesdeFactura;
end;

procedure TFacturaTotales.LeerPorcentajesDesdeFactura;
begin
  if not Assigned(_unqryFac) or not _unqryFac.Active then
    Exit;
  with _unqryFac do
  begin
    _porcentajes.IVANormal := FieldByName('PORCEN_IVAN_FACTURA').AsFloat;
    _porcentajes.IVAReducido := FieldByName('PORCEN_IVAR_FACTURA').AsFloat;
    _porcentajes.IVASuperReducido := FieldByName('PORCEN_IVAS_FACTURA').AsFloat;
    _porcentajes.IVAExento := FieldByName('PORCEN_IVAE_FACTURA').AsFloat;
    // Leer recargos de equivalencia
    _porcentajes.REcNormal := FieldByName('PORCEN_REN_FACTURA').AsFloat;
    _porcentajes.REcReducido := FieldByName('PORCEN_RER_FACTURA').AsFloat;
    _porcentajes.REcSuperReducido := FieldByName('PORCEN_RES_FACTURA').AsFloat;
    _porcentajes.REcExento := FieldByName('PORCEN_REE_FACTURA').AsFloat;
  end;
end;

procedure TFacturaTotales.CargarConfiguracionIVA(sGrupoZona: string);
var
  Qry: TUniQuery;
begin
  if sGrupoZona = '' then Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := 'SELECT * FROM vi_ivas ' +
                    ' WHERE GRUPO_ZONA_IVA = :grupo ' +
                    '   AND FECHA_DESDE_IVA <= :fecha ' +
                    '   AND (FECHA_HASTA_IVA >= :fecha OR FECHA_HASTA_IVA IS NULL)';
    Qry.ParamByName('grupo').AsString := sGrupoZona;
    Qry.ParamByName('fecha').AsDateTime := _fechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if _unqryFac.State = dsBrowse then _unqryFac.Edit;
      // Asignación al DataSet de la Factura (Persistencia)
      _unqryFac.FieldByName('PORCEN_IVAN_FACTURA').AsFloat := Qry.FieldByName('PORCENNORMAL_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_REN_FACTURA').AsFloat  := Qry.FieldByName('PORCENNORMAL_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_IVAR_FACTURA').AsFloat := Qry.FieldByName('PORCENREDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_RER_FACTURA').AsFloat  := Qry.FieldByName('PORCENREDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_IVAS_FACTURA').AsFloat := Qry.FieldByName('PORCENSUPERREDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_RES_FACTURA').AsFloat  := Qry.FieldByName('PORCENSUPERREDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_IVAE_FACTURA').AsFloat := Qry.FieldByName('PORCENEXENTO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCEN_REE_FACTURA').AsFloat  := Qry.FieldByName('PORCENEXENTO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA').AsString := Qry.FieldByName('ESIRPF_IMP_INCL_ZONA_IVA').AsString;
      _unqryFac.FieldByName('ESAPLICA_RE_ZONA_IVA_FACTURA').AsString     := Qry.FieldByName('ESAPLICA_RE_ZONA_IVA').AsString;
      _unqryFac.FieldByName('CODIGO_IVA_FACTURA').AsString               := Qry.FieldByName('CODIGO_IVA').AsString;
      _unqryFac.FieldByName('ESIVAAGRICOLA_ZONA_IVA_FACTURA').AsString   := Qry.FieldByName('ESIVAAGRICOLA_ZONA_IVA').AsString;
      // Actualizar también la estructura interna de trabajo (_configuracion y _porcentajes)
      _configuracion.AplicaRecargo        := (Qry.FieldByName('ESAPLICA_RE_ZONA_IVA').AsString = 'S');
      _configuracion.IRPFImpuestoIncluido := (Qry.FieldByName('ESIRPF_IMP_INCL_ZONA_IVA').AsString = 'S');
      _grupoZonaIVA                       := sGrupoZona;
      _codigoIVA                          := Qry.FieldByName('CODIGO_IVA').AsString;
      LeerPorcentajesDesdeFactura; // Sincroniza _porcentajes con los nuevos valores del DataSet
    end;
  finally
    Qry.Free;
  end;
end;

procedure TFacturaTotales.AplicarReglas;
begin
  // 1. Régimen Especial Agrícola Empresa
  if _configuracion.EsRegimenAgricolaEmpresa then
  begin
    _configuracion.AplicaRetencionesEmpresa := True;
    // OJO: En el SQL esto se refiere a "ESAPLICA_RE_ZONA_IVA",
    // asegúrate de estar usando el campo correcto de tu configuración.
    // Si tu variable IVARecargo es la del Cliente, quizás necesites otra variable
    // para la Zona, o si usas esta para todo, ponla a False.
    _configuracion.IVARecargo := False;
    // Buscar IVA específico para agricultura
    // Llamamos a la función auxiliar que busca en la BD
    if BuscarDatosIVAAgricola(_codigoEmpresa) then
    begin
       // Si encuentra datos, la función BuscarDatosIVAAgricola
       // ya habrá actualizado la variable _porcentajes y _totales.GrupoZonaIVA
    end;
  end;
  // 2. Intracomunitario
  if _configuracion.EsIntracomunitario then
  begin
    _configuracion.IVAExento := True;
    _configuracion.AplicaRetencionesCliente := False;
    _configuracion.EsRegimenAgricolaCliente := False;
  end;
  // 3. Venta Activo Fijo + REAGP Empresa
  if ((_configuracion.EsVentaActivoFijo) and
      (_configuracion.EsRegimenAgricolaEmpresa)) then
  begin
    _configuracion.IVAExento := True;
  end;
  // 4. REAGP Empresa + REAGP Cliente
  if ((_configuracion.EsRegimenAgricolaEmpresa) and
      (_configuracion.EsRegimenAgricolaCliente)) then
  begin
    _configuracion.AplicaRetencionesCliente := True;
    _configuracion.IVAExento := True;
  end;
  // 5. REAGP Empresa + Cliente Normal sin retenciones
  if _configuracion.EsRegimenAgricolaEmpresa and
     not _configuracion.EsRegimenAgricolaCliente and
     not _configuracion.AplicaRetencionesCliente then
  begin
    _configuracion.IVAExento := True;
  end;
  // 6. Aplicar la lógica de Exención (Sustituye a //AplicarIVAExento)
  // Esto replica la parte del SQL: IF (pIVA_EXENTO = 'S') THEN SET pPORCENN = pPORCENE...
  if _configuracion.IVAExento then
  begin
    // Unificamos todos los tipos de IVA al porcentaje de Exento (normalmente 0)
    _porcentajes.IVANormal        := _porcentajes.IVAExento;
    _porcentajes.IVAReducido      := _porcentajes.IVAExento;
    _porcentajes.IVASuperReducido := _porcentajes.IVAExento;
    // Anulamos cualquier Recargo de Equivalencia
    _porcentajes.REcNormal        := 0;
    _porcentajes.REcReducido      := 0;
    _porcentajes.REcSuperReducido := 0;
    _porcentajes.REcExento        := 0;
  end;
end;

//procedure TFacturaTotales.AplicarReglas;
//begin
//  // Aplicar reglas de negocio según configuración
//
//  // Régimen Especial Agrícola Empresa-
//  if _configuracion.EsRegimenAgricolaEmpresa then
//  begin
//    _configuracion.AplicaRetencionesEmpresa := True;
//    _configuracion.AplicaRecargo := False;
//    // Buscar IVA específico para agricultura
//    //BuscarIVAAgricola;
//  end;
//
//  // Intracomunitario
//  if _configuracion.EsIntracomunitario then
//  begin
//    _configuracion.IVAExento := True;
//    _configuracion.AplicaRetencionesCliente := False;
//    _configuracion.EsRegimenAgricolaCliente := False;
//  end;
//
//  // Venta Activo Fijo + REAGP
//  if ((_configuracion.EsVentaActivoFijo) and
//      (_configuracion.EsRegimenAgricolaEmpresa)) then
//  begin
//    _configuracion.IVAExento := True;
//  end;
//
//  // REAGP Empresa + REAGP Cliente
//  if ((_configuracion.EsRegimenAgricolaEmpresa) and
//      (_configuracion.EsRegimenAgricolaCliente)) then
//  begin
//    _configuracion.AplicaRetencionesCliente := True;
//    _configuracion.IVAExento := True;
//  end;
//
//  // REAGP Empresa + Cliente Normal sin retenciones
//  if _configuracion.EsRegimenAgricolaEmpresa and
//     not _configuracion.EsRegimenAgricolaCliente and
//     not _configuracion.AplicaRetencionesCliente then
//  begin
//    _configuracion.IVAExento := True;
//  end;
//  // REAGP Empresa + Cliente Normal con retenciones
//  if ((_configuracion.EsRegimenAgricolaEmpresa) and
//      (not _configuracion.EsRegimenAgricolaCliente) and
//      (_configuracion.AplicaRetencionesCliente)) then
//  begin
//    // Aplicar IVA normal, no exento
//    // No cambiar configuración de IVA
//  end;
//  // Aplicar IVA Exento si es necesario
//  if _configuracion.IVAExento then
//  begin
//     //AplicarIVAExento;
//  end;
//end;

function TFacturaTotales.ObtenerPorcentajePorTipo(tipo: string): Currency;
begin
  case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
    0: Result := _porcentajes.IVANormal;
    1: Result := _porcentajes.IVAReducido;
    2: Result := _porcentajes.IVASuperReducido;
    3: Result := _porcentajes.IVAExento;
  else
    Result := _porcentajes.IVANormal;
  end;
end;

function TFacturaTotales.ObtenerPorcentajeREPorTipo(tipo: string): Currency;
var
  sNif, sRazon, sDir: string;
  tieneDatosMinimos: Boolean;
begin
  // Primero verificamos los datos mínimos del cliente
  sNif   := Trim(_unqryFac.FieldByName('NIF_CLIENTE_FACTURA').AsString);
  sRazon := Trim(_unqryFac.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString);
  sDir   := Trim(_unqryFac.FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString);
  tieneDatosMinimos := (sNif <> '') and (sRazon <> '') and (sDir <> '');
  // Si es Simplificada O no tiene datos mínimos O no aplica recargo por config: devolvemos 0
  if _configuracion.EsFacturaSimplificada or
     (not tieneDatosMinimos) or
     not (_configuracion.AplicaRecargo and _configuracion.IVARecargo) then
  begin
    Result := 0;
  end
  else
  begin
    case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
      0: Result := _porcentajes.REcNormal;
      1: Result := _porcentajes.REcReducido;
      2: Result := _porcentajes.REcSuperReducido;
      3: Result := _porcentajes.REcExento;
    else
      Result := 0;
    end;
  end;
end;

function TFacturaTotales.ProcesarFacturaCompleta: Boolean;
begin
//  Result := False;
  _mensajeError := '';
  try
    // Leer configuración de la factura
    LeerDatosFactura;
    // Aplicar reglas de negocio
    AplicarReglas;
    // Validar configuración
    ValidarConfiguracion;
    // Procesar líneas y calcular totales
    RecorrerYCalcularLineasConClientDataSet;
    CalcularTotalesFactura;
    // Actualizar en la base de datos
    if _unqryFac.State <> dsEdit then
      _unqryFac.Edit;
    ActualizarTotalesEnDataSet;
    Result := True;
  except
    on E: Exception do
    begin
      _mensajeError := E.Message;
      Result := False;
    end;
  end;
end;

procedure TFacturaTotales.AcumularTotalesPorTipoIVA(linea: TLinFac);
var
  porcentajeIVA, porcentajeRE: Currency;
  baseImponible, importeIVA, importeRE: Currency;
  totalLineaCIVA: Currency;
begin
  // 1. Calcular base imponible y total de la línea forzando el redondeo a 2 decimales
  baseImponible := SimpleRoundTo(linea.TotSiva, -2);
  totalLineaCIVA := SimpleRoundTo(linea.TotCiva, -2);
  // Obtener porcentajes según el tipo de IVA
  porcentajeIVA := ObtenerPorcentajePorTipo(linea.TipoIva);
  porcentajeRE := ObtenerPorcentajeREPorTipo(linea.TipoIva);
  // 2. Calcular importes aplicando la regla contable de diferencia si tiene IVA incluido
  if SameText(linea.Impcl, 'S') then
  begin
    importeIVA := totalLineaCIVA - baseImponible;
    importeRE := SimpleRoundTo(baseImponible * (porcentajeRE / 100), -2);
  end
  else
  begin
    importeIVA := SimpleRoundTo(baseImponible * (porcentajeIVA / 100), -2);
    importeRE := SimpleRoundTo(baseImponible * (porcentajeRE / 100), -2);
  end;
  if linea._dCant < 0 then
    Self.FTieneLineasNegativas := True;
  _totales.TotalCantidades := _totales.TotalCantidades + linea.Cant;
  _totales.TotalBruto := _totales.TotalBruto + (linea.PrecioSal * linea.Cant);
  _totales.TotalDescuentosLineas := _totales.TotalDescuentosLineas +
                                    (linea.Dto * linea.Cant);
  case IndexStr(linea.TipoIva, ['N', 'R', 'S', 'E']) of
    0: // IVA Normal
      begin
        _totales.IVAN.BaseImponible := _totales.IVAN.BaseImponible + baseImponible;
        _totales.IVAN.PorcentajeIVA := porcentajeIVA;
        _totales.IVAN.PorcentajeRE := porcentajeRE;
        _totales.IVAN.ImporteIVA := _totales.IVAN.ImporteIVA + importeIVA;
        _totales.IVAN.ImporteRE := _totales.IVAN.ImporteRE + importeRE;
      end;
    1: // IVA Reducido
      begin
        _totales.IVAR.BaseImponible := _totales.IVAR.BaseImponible + baseImponible;
        _totales.IVAR.PorcentajeIVA := porcentajeIVA;
        _totales.IVAR.PorcentajeRE := porcentajeRE;
        _totales.IVAR.ImporteIVA := _totales.IVAR.ImporteIVA + importeIVA;
        _totales.IVAR.ImporteRE := _totales.IVAR.ImporteRE + importeRE;
      end;
    2: // IVA SuperReducido
      begin
        _totales.IVAS.BaseImponible := _totales.IVAS.BaseImponible + baseImponible;
        _totales.IVAS.PorcentajeIVA := porcentajeIVA;
        _totales.IVAS.PorcentajeRE := porcentajeRE;
        _totales.IVAS.ImporteIVA := _totales.IVAS.ImporteIVA + importeIVA;
        _totales.IVAS.ImporteRE := _totales.IVAS.ImporteRE + importeRE;
      end;
    3: // IVA Exento
      begin
        _totales.IVAE.BaseImponible := _totales.IVAE.BaseImponible + baseImponible;
        _totales.IVAE.PorcentajeIVA := porcentajeIVA;
        _totales.IVAE.PorcentajeRE := porcentajeRE;
        _totales.IVAE.ImporteIVA := _totales.IVAE.ImporteIVA + importeIVA;
        _totales.IVAE.ImporteRE := _totales.IVAE.ImporteRE + importeRE;
      end;
  end;
end;

procedure TFacturaTotales.CalcularTotalesGenerales;
begin
  _totales.TotalBases := _totales.IVAN.BaseImponible +
                         _totales.IVAR.BaseImponible +
                         _totales.IVAS.BaseImponible +
                         _totales.IVAE.BaseImponible;
  _totales.TotalIVANormal := _totales.IVAN.ImporteIVA;
  _totales.TotalIVAReducido := _totales.IVAR.ImporteIVA;
  _totales.TotalIVASuperReducido := _totales.IVAS.ImporteIVA;
  _totales.TotalIVAExento := _totales.IVAE.ImporteIVA;
  _totales.TotalREcargo := _totales.IVAN.ImporteRE + _totales.IVAR.ImporteRE +
                          _totales.IVAS.ImporteRE + _totales.IVAE.ImporteRE;
  _totales.TotalImpuestos := _totales.TotalIVANormal +
                             _totales.TotalIVAReducido +
                             _totales.TotalIVASuperReducido +
                             _totales.TotalIVAExento +
                             _totales.TotalREcargo;
end;

procedure TFacturaTotales.CalcularRetenciones;
var
  baseCalculo: Currency;
  sNif, sRazon, sDir: string;
  tieneDatosMinimos: Boolean;
begin
  if _configuracion.EsFacturaSimplificada then
  begin
    _totales.TotalRetencion := 0;
    Exit;
  end;
  sNif   := Trim(_unqryFac.FieldByName('NIF_CLIENTE_FACTURA').AsString);
  sRazon := Trim(_unqryFac.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString);
  sDir   := Trim(_unqryFac.FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString);
  tieneDatosMinimos := (sNif <> '') and (sRazon <> '') and (sDir <> '');
  if not tieneDatosMinimos then
  begin
    _totales.TotalRetencion := 0;
    // _mensajeError := 'Cliente no cualificado: faltan datos fiscales.
    //                   IRPF no aplicado.';
    Exit;
  end;
  if not (_configuracion.AplicaRetencionesCliente and
          _configuracion.AplicaRetencionesEmpresa) then
  begin
    _totales.TotalRetencion := 0;
    Exit;
  end;
  if (_configuracion.EsVentaActivoFijo and
      _configuracion.EsRegimenAgricolaEmpresa) then
  begin
    _dPorRetencion := 0;
    _totales.TotalRetencion := 0;
    Exit;
  end;
  if (_dPorRetencion = 0) and (_configuracion.AplicaRetencionesCliente and
          _configuracion.AplicaRetencionesEmpresa) then
  begin
    _dPorRetencion := BuscarPorcenRetencion(_codigoEmpresa);
  end;
  if _configuracion.IRPFImpuestoIncluido then
    baseCalculo := _totales.TotalBases + _totales.TotalImpuestos
  else
    baseCalculo := _totales.TotalBases;
  _totales.TotalRetencion := baseCalculo * (_dPorRetencion / 100);
end;

procedure TFacturaTotales.CalcularTotalesFactura;
begin
  CalcularTotalesGenerales;
  CalcularRetenciones;
  _totales.TotalLiquido := _totales.TotalBases +
                           _totales.TotalImpuestos -
                           _totales.TotalRetencion;
end;

procedure TFacturaTotales.ActualizarTotalesEnDataSet;
begin
  with _unqryFac do
  begin
    if State = dsBrowse then Edit;
    // Bases imponibles
    FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsFloat :=
                                         _totales.IVAN.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsFloat :=
                                         _totales.IVAR.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsFloat :=
                                         _totales.IVAS.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAE_FACTURA').AsFloat :=
                                         _totales.IVAE.BaseImponible;
    FieldByName('TOTAL_BASES_FACTURA').AsFloat := _totales.TotalBases;
    // Importes de IVA
    FieldByName('TOTAL_IVAN_FACTURA').AsFloat := _totales.TotalIVANormal;
    FieldByName('TOTAL_IVAR_FACTURA').AsFloat := _totales.TotalIVAReducido;
    FieldByName('TOTAL_IVAS_FACTURA').AsFloat :=
                                            _totales.TotalIVASuperReducido;
    FieldByName('TOTAL_IVAE_FACTURA').AsFloat := _totales.TotalIVAExento;
    // Importes de Recargo Equivalencia
    FieldByName('TOTAL_REN_FACTURA').AsFloat := _totales.IVAN.ImporteRE;
    FieldByName('TOTAL_RER_FACTURA').AsFloat := _totales.IVAR.ImporteRE;
    FieldByName('TOTAL_RES_FACTURA').AsFloat := _totales.IVAS.ImporteRE;
    FieldByName('TOTAL_REE_FACTURA').AsFloat := _totales.IVAE.ImporteRE;
    // Totales generales
    FieldByName('TOTAL_IMPUESTOS_FACTURA').AsFloat := _totales.TotalImpuestos;
    FieldByName('TOTAL_RETENCION_FACTURA').AsFloat := _totales.TotalRetencion;
    FieldByName('PORCEN_RETENCION_FACTURA').AsFloat := _dPorRetencion;
    FieldByName('TOTAL_LIQUIDO_FACTURA').AsFloat := _totales.TotalLiquido;
    // Actualizar configuración aplicada
    FieldByName('ESIVA_EXENTO_CLIENTE_FACTURA').AsString :=
      IfThen(_configuracion.IVAExento, 'S', 'N');
    FieldByName('ESRETENCIONES_CLIENTE_FACTURA').AsString :=
      IfThen(_configuracion.AplicaRetencionesCliente, 'S', 'N');
    FieldByName('ESRETENCIONES_EMPRESA_FACTURA').AsString :=
      IfThen(_configuracion.AplicaRetencionesEmpresa, 'S', 'N');
    FieldByName('ESIVA_RECARGO_CLIENTE_FACTURA').AsString :=
      IfThen(_configuracion.AplicaRecargo, 'S', 'N');
    // Actualizar porcentajes aplicados
    FieldByName('PORCEN_IVAN_FACTURA').AsFloat := _porcentajes.IVANormal;
    FieldByName('PORCEN_IVAR_FACTURA').AsFloat := _porcentajes.IVAReducido;
    FieldByName('PORCEN_IVAS_FACTURA').AsFloat :=
                                              _porcentajes.IVASuperReducido;
    FieldByName('PORCEN_IVAE_FACTURA').AsFloat := _porcentajes.IVAExento;
  end;
end;

//function TFacturaTotales.ConvertirTipoIVA(tipo: string): TTipoIVA;
//begin
//  case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
//    0: Result := tivaNormal;
//    1: Result := tivaReducido;
//    2: Result := tivaSuperReducido;
//    3: Result := tivaExento;
//  else
//    Result := tivaNormal;
//  end;
//end;

procedure TFacturaTotales.ValidarConfiguracion;
begin
//  if _fechaFactura = 0 then
//    raise Exception.Create('La fecha de la factura es requerida');
//
//  if _codigoEmpresa = '' then
//    raise Exception.Create('El código de empresa es requerido');
//
//  if not Assigned(_unqryLineas) or not _unqryLineas.Active then
//    raise Exception.Create('El dataset de líneas debe estar activo');
//
//  if not Assigned(_unqryFac) or not _unqryFac.Active then
//    raise Exception.Create('El dataset de factura debe estar activo');
end;

function TFacturaTotales.ValidarFactura: Boolean;
begin
  Result := True;
  _mensajeError := '';
  try
    ValidarConfiguracion;
  except
    on E: Exception do
    begin
      _mensajeError := E.Message;
      Result := False;
    end;
  end;
end;

procedure TFacturaTotales.RecorrerYCalcularLineasConClientDataSet;
var
  lineaActual: TLinFac;
  bookmark: TBookmark;
  sLinea:String;
begin
  sLinea := _unqryLineas.FieldByName(fnrolin).AsString;
  _unqryLineas.DisableControls;
  bookmark := _unqryLineas.GetBookmark;
  try
    if ((_unqryLineas.State = dsEdit) or (_unqryLineas.State = dsInsert)) then
      _unqryLineas.Post;
    _unqryLineas.First;
    while not _unqryLineas.Eof do
    begin
      lineaActual := TLinFac.Create(_unqryLineas, _unqryFac, False);
      if _configuracion.IVAExento then
        lineaActual.TipoIva := 'E';
      lineaActual.PorIva := ObtenerPorcentajePorTipo(lineaActual.TipoIva);
      lineaActual.CalcularLinea;
      AcumularTotalesPorTipoIVA(lineaActual);
      lineaActual.Free;
      _unqryLineas.Next;
    end;
  finally
    _unqryLineas.EnableControls;
    _unqryLineas.GotoBookmark(bookmark);
    _unqryLineas.FreeBookmark(bookmark);
  end;
end;

function TFacturaTotales.BuscarPorcenRetencion(CodEmpresa: string): Currency;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := 'SELECT PORCENRETENCION_RETENCION ' +
                    '  FROM fza_empresas_retenciones ' +
                    ' WHERE CODIGO_EMPRESA_RETENCION = :EMP ' +
                    '   AND FECHA_DESDE_RETENCION <= :FECHA ' +
                    '   AND (FECHA_HASTA_RETENCION >= :FECHA ' +
                    '        OR FECHA_HASTA_RETENCION IS NULL) ' +
                    ' ORDER BY FECHA_DESDE_RETENCION DESC LIMIT 1';
    Qry.ParamByName('EMP').AsString := CodEmpresa;
    Qry.ParamByName('FECHA').AsDateTime := _FechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsCurrency;
  finally
    Qry.Free;
  end;
end;

function TFacturaTotales.BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := 'SELECT GRUPO_ZONA_IVA, CODIGO_IVA, ' +
                    '       PORCENNORMAL_IVA, PORCENEXENTO_IVA, ' +
                    '       PORCENREDUCIDO_IVA, PORCENSUPERREDUCIDO_IVA ' +
                    '  FROM vi_ivas_empresa ' +
                    ' WHERE ESIVAAGRICOLA_ZONA_IVA = ''S'' ' +
                    '   AND CODIGO_EMPRESA = :EMP ' +
                    '   AND FECHA_DESDE_IVA <= :FECHA ' +
                    '   AND (   FECHA_HASTA_IVA IS NULL ' +
                    '        OR FECHA_HASTA_IVA >= :FECHA)';
    Qry.ParamByName('EMP').AsString := CodEmpresa;
    Qry.ParamByName('FECHA').AsDateTime := _FechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      _GrupoZonaIVA := Qry.FieldByName('GRUPO_ZONA_IVA').AsString;
      _CodigoIVA    := Qry.FieldByName('CODIGO_IVA').AsString;
      _porcentajes.IVANormal := Qry.FieldByName('PORCENNORMAL_IVA').AsCurrency;
      _porcentajes.IVAExento := Qry.FieldByName('PORCENEXENTO_IVA').AsCurrency;
      _porcentajes.IVAReducido :=
                               Qry.FieldByName('PORCENREDUCIDO_IVA').AsCurrency;
      _porcentajes.IVASuperReducido :=
                          Qry.FieldByName('PORCENSUPERREDUCIDO_IVA').AsCurrency;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosCliente;
var
  Qry: TUniQuery;
  sCodCli: string;
begin
  sCodCli := _unqryFac.FieldByName('CODIGO_CLIENTE_FACTURA').AsString;
  if (sCodCli = '') or
     (sCodCli = '0') or
     (sCodCli = 'VENTA CONTADO') or //no hay cliente
     (_unqryFac.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString <> '') then
    Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := '    SELECT * ' +
                    '      FROM fza_clientes ' +
                    ' LEFT JOIN fza_tarifas ' +
                    '        ON fza_clientes.TARIFA_ARTICULO_CLIENTE = ' +
                    '           fza_tarifas.CODIGO_TARIFA ' +
                    '     WHERE CODIGO_CLIENTE = :cliente';
    Qry.ParamByName('cliente').AsString := sCodCli;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if (_unqryFac.State = dsBrowse) then
        _unqryFac.Edit;
      _unqryFac.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString :=
                                Qry.FieldByName('RAZONSOCIAL_CLIENTE').AsString;
      _unqryFac.FieldByName('NIF_CLIENTE_FACTURA').AsString         :=
                                        Qry.FieldByName('NIF_CLIENTE').AsString;
      _unqryFac.FieldByName('MOVIL_CLIENTE_FACTURA').AsString       :=
                                      Qry.FieldByName('MOVIL_CLIENTE').AsString;
      _unqryFac.FieldByName('EMAIL_CLIENTE_FACTURA').AsString       :=
                                      Qry.FieldByName('EMAIL_CLIENTE').AsString;
      _unqryFac.FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString  :=
                                 Qry.FieldByName('DIRECCION1_CLIENTE').AsString;
      _unqryFac.FieldByName('DIRECCION2_CLIENTE_FACTURA').AsString  :=
                                 Qry.FieldByName('DIRECCION2_CLIENTE').AsString;
      _unqryFac.FieldByName('POBLACION_CLIENTE_FACTURA').AsString   :=
                                  Qry.FieldByName('POBLACION_CLIENTE').AsString;
      _unqryFac.FieldByName('PROVINCIA_CLIENTE_FACTURA').AsString   :=
                                  Qry.FieldByName('PROVINCIA_CLIENTE').AsString;
      _unqryFac.FieldByName('CPOSTAL_CLIENTE_FACTURA').AsString     :=
                                    Qry.FieldByName('CPOSTAL_CLIENTE').AsString;
      _unqryFac.FieldByName('NOMBRE_PAIS_CLIENTE_FACTURA').AsString :=
                                Qry.FieldByName('NOMBRE_PAIS_CLIENTE').AsString;
      _unqryFac.FieldByName('CODIGO_PAIS_CLIENTE_FACTURA').AsString :=
                                Qry.FieldByName('CODIGO_PAIS_CLIENTE').AsString;
      _unqryFac.FieldByName('ESIVA_RECARGO_CLIENTE_FACTURA').AsString :=
                              Qry.FieldByName('ESIVA_RECARGO_CLIENTE').AsString;
      _unqryFac.FieldByName('ESIVA_EXENTO_CLIENTE_FACTURA').AsString  :=
                               Qry.FieldByName('ESIVA_EXENTO_CLIENTE').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_CLIENTE').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_CLIENTE_FACTURA').AsString :=
                              Qry.FieldByName('ESRETENCIONES_CLIENTE').AsString;
      _unqryFac.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FACTURA').AsString :=
                         Qry.FieldByName('ESINTRACOMUNITARIO_CLIENTE').AsString;
      _unqryFac.FieldByName('FORMA_PAGO_FACTURA').AsString :=
                          Qry.FieldByName('CODIGO_FORMA_PAGO_CLIENTE').AsString;
      _unqryFac.FieldByName('TARIFA_ARTICULO_CLIENTE_FACTURA').AsString :=
                            Qry.FieldByName('TARIFA_ARTICULO_CLIENTE').AsString;
      if Qry.FindField('ESIMP_INCL_TARIFA').AsString <> '' then
        _unqryFac.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FACTURA').AsString :=
                                    Qry.FindField('ESIMP_INCL_TARIFA').AsString;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosEmpresa;
var
  Qry: TUniQuery;
begin
  if (_unqryFac.FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString <> '') then
    Exit;
  if _codigoEmpresa = '' then
    Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMPRESA = :empresa';
    Qry.ParamByName('empresa').AsString := _codigoEmpresa;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if (_unqryFac.State = dsBrowse) then
        _unqryFac.Edit;
      _unqryFac.FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString :=
                                Qry.FieldByName('RAZONSOCIAL_EMPRESA').AsString;
      _unqryFac.FieldByName('NIF_EMPRESA_FACTURA').AsString         :=
                                        Qry.FieldByName('NIF_EMPRESA').AsString;
      _unqryFac.FieldByName('MOVIL_EMPRESA_FACTURA').AsString       :=
                                      Qry.FieldByName('MOVIL_EMPRESA').AsString;
      _unqryFac.FieldByName('EMAIL_EMPRESA_FACTURA').AsString       :=
                                      Qry.FieldByName('EMAIL_EMPRESA').AsString;
      _unqryFac.FieldByName('DIRECCION1_EMPRESA_FACTURA').AsString  :=
                                 Qry.FieldByName('DIRECCION1_EMPRESA').AsString;
      _unqryFac.FieldByName('DIRECCION2_EMPRESA_FACTURA').AsString  :=
                                 Qry.FieldByName('DIRECCION2_EMPRESA').AsString;
      _unqryFac.FieldByName('POBLACION_EMPRESA_FACTURA').AsString   :=
                                  Qry.FieldByName('POBLACION_EMPRESA').AsString;
      _unqryFac.FieldByName('PROVINCIA_EMPRESA_FACTURA').AsString   :=
                                  Qry.FieldByName('PROVINCIA_EMPRESA').AsString;
      _unqryFac.FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString     :=
                                    Qry.FieldByName('CPOSTAL_EMPRESA').AsString;
      _unqryFac.FieldByName('NOMBRE_PAIS_EMPRESA_FACTURA').AsString :=
                                Qry.FieldByName('NOMBRE_PAIS_EMPRESA').AsString;
      _unqryFac.FieldByName('CODIGO_PAIS_EMPRESA_FACTURA').AsString :=
                                Qry.FieldByName('CODIGO_PAIS_EMPRESA').AsString;
      _unqryFac.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString :=
                             Qry.FieldByName('GRUPO_ZONA_IVA_EMPRESA').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_EMPRESA_FACTURA').AsString :=
                              Qry.FieldByName('ESRETENCIONES_EMPRESA').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_EMPRESA').AsString;
      _unqryFac.FieldByName('TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA').AsString :=
                        Qry.FieldByName('TEXTO_LEGAL_FACTURA_EMPRESA').AsString;
      var sGrupo := _unqryFac.FieldByName(
                                     'GRUPO_ZONA_IVA_EMPRESA_FACTURA').AsString;
      CargarConfiguracionIVA(sGrupo);
    end;
  finally
    Qry.Free;
  end;
end;
end.
