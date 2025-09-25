unit UFactura;

interface

uses
  System.Generics.Collections, System.SysUtils, System.Math;

const
//linea de factura
  fnrofaclin:string = 'NRO_FACTURA_LINEA';
  fserielin:string = 'SERIE_FACTURA_LINEA';
  //constantes para linea de factura
  fnrolin:string = 'LINEA_FACTURA_LINEA';
  fcodart:string = 'CODIGO_ARTICULO_FACTURA_LINEA';
  fcodfam:string = 'CODIGO_FAMILIA_FACTURA_LINEA';
  fnomfam:string = 'NOMBRE_FAMILIA_FACTURA_LINEA';
  ffechentr:string = 'FECHA_ENTREGA_FACTURA_LINEA';
  ftipocant:string = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA';
  fimpcl:string = 'ESIMP_INCL_TARIFA_FACTURA_LINEA';
  ftipiva:string = 'TIPOIVA_ARTICULO_FACTURA_LINEA';
  fdescripcion:string = 'DESCRIPCION_ARTICULO_FACTURA_LINEA';
  fcodtariflin:string = 'CODIGO_TARIFA_FACTURA_LINEA';
  fcant:string = 'CANTIDAD_FACTURA_LINEA';
  fpreciosal:string = 'PRECIOSALIDA_FACTURA_LINEA';
  fpordto:string = 'PORCEN_DTO_FACTURA_LINEA';
  fdto:string = 'PRECIO_DTO_FACTURA_LINEA';
  fpresiva:string = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA';
  fporiva:string = 'PORCEN_IVA_FACTURA_LINEA';
  fpreciva:string = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA';
  ftotciva:string = 'TOTAL_FACTURA_LINEA';
  ftotsiva:string = 'TOTAL_FACTURASIVA_LINEA';
  //factura
    // Constantes para los datos del vendedor (empresa)
  fEmailCliente: string = 'EMAIL_CLIENTE_FACTURA';
  fNifEmpresa: string = 'NIF_EMPRESA_FACTURA';
  fRazonSocialEmpresa: string = 'RAZONSOCIAL_EMPRESA_FACTURA';
  fDireccion1Empresa: string = 'DIRECCION1_EMPRESA_FACTURA';
  fDireccion2Empresa: string = 'DIRECCION2_EMPRESA_FACTURA';
  fCPostalEmpresa: string = 'CPOSTAL_EMPRESA_FACTURA';
  fPoblacionEmpresa: string = 'POBLACION_EMPRESA_FACTURA';
  fProvinciaEmpresa: string = 'PROVINCIA_EMPRESA_FACTURA';
  fPaisEmpresa: string = 'PAIS_EMPRESA_FACTURA';
  fMovilEmpresa: string = 'MOVIL_EMPRESA_FACTURA';
  fEmailEmpresa: string = 'EMAIL_EMPRESA_FACTURA';
  // Constantes para los datos del comprador (cliente)
  fNifCliente: string = 'NIF_CLIENTE_FACTURA';
  fRazonSocialCliente: string = 'RAZONSOCIAL_CLIENTE_FACTURA';
  fDireccion1Cliente: string = 'DIRECCION1_CLIENTE_FACTURA';
  fDireccion2Cliente: string = 'DIRECCION2_CLIENTE_FACTURA';
  fCPostalCliente: string = 'CPOSTAL_CLIENTE_FACTURA';
  fPoblacionCliente: string = 'POBLACION_CLIENTE_FACTURA';
  fProvinciaCliente: string = 'PROVINCIA_CLIENTE_FACTURA';
  fPaisCliente: string = 'PAIS_CLIENTE_FACTURA';
  fMovilCliente: string = 'MOVIL_CLIENTE_FACTURA';

  ffechfac:string = 'FECHA_FACTURA';
  fnrofac:string = 'NRO_FACTURA';
  fseriefac:string = 'SERIE_FACTURA';
  fcodemp:string = 'CODIGO_EMPRESA_FACTURA';
  fcodcli:string = 'CODIGO_CLIENTE_FACTURA';
  fporivan:string = 'PORCEN_IVAN_FACTURA';
  ftotivan:string = 'TOTAL_IVAN_FACTURA';
  fporren:string = 'PORCEN_REN_FACTURA';
  ftotren:string = 'TOTAL_REN_FACTURA';
  ftotbasen:string = 'TOTAL_BASEI_IVAN_FACTURA';
  fporivar:string = 'PORCEN_IVAR_FACTURA';
  ftotivar:string = 'TOTAL_IVAR_FACTURA';
  fporrer:string = 'PORCEN_RER_FACTURA';
  ftotrer:string = 'TOTAL_RER_FACTURA';
  ftotbaser:string = 'TOTAL_BASEI_IVAR_FACTURA';
  fporivas:string = 'PORCEN_IVAS_FACTURA';
  ftotivas:string = 'TOTAL_IVAS_FACTURA';
  fporres:string = 'PORCEN_RES_FACTURA';
  ftotres:string = 'TOTAL_RES_FACTURA';
  ftotbases:string = 'TOTAL_BASEI_IVAS_FACTURA';
  fporivae:string = 'PORCEN_IVAE_FACTURA';
  ftotivae:string = 'TOTAL_IVAE_FACTURA';
  fporree:string = 'PORCEN_REE_FACTURA';
  ftotree:string = 'TOTAL_REE_FACTURA';
  ftotbasee:string = 'TOTAL_BASEI_IVAE_FACTURA';
  ftotallifac:string = 'TOTAL_LIQUIDO_FACTURA';
  fporirpf:string = 'PORCEN_RETENCION_FACTURA';
  ftotirpf:string = 'TOTAL_RETENCION_FACTURA';
  ftotimp:string = 'TOTAL_IMPUESTOS_FACTURA';
  ftotbasefac:string = 'TOTAL_BASES_FACTURA';

type
  TCurrencyField = record
  private
    FValue: Double;
    function FormatValue(Decimals: Integer): string;
    function RoundValue(Value: Double; Decimals: Integer): Double;
  public
    constructor Create(AValue: Double);
    //function AsCurr(Decimals: Integer = 2): string; overload;
    function AsCur(DecimalPlaces: Integer = 2;
                              DecimalSeparator: Char = '.';
                              CurrencySymbol: string = '';
                              ThousandSeparator: Char = #0
                              ): string;
    function AsFloat(Decimals: Integer = -1): Double;
  end;

  TPartyData = record
    TaxIdentificationNumber: string;
    PartyName: string;
    Address: string;
    PostCode: string;
    Town: string;
    Province: string;
    CountryCode: string;
  end;
  TLineaFactura = class
  public
    NroFacturaLinea: string;
    SerieFacturaLinea: string;
    LineaFacturaLinea: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Cantidad: Double;
    PrecioUnitario: Double;
    TotalLinea: Double;
    PorcentajeIVA: Double;
    PorcentajeRE: Double;
    TipoIVA: string; //'N' para normal, 'R' para reducido,
                     //'S' para superreducido, 'E' para exento

  end;
  (* Para una correcta encapsulación, hay que crear una segunda propiedad
  TFactura = class
  private
    FPorcenIvaN: TCurrencyField;
    // ... otros campos privados ...
  public
    property PorcenIvaN: Double read GetPorcenIVAN write SetPorcenIVAN;
    property PorcenIvaNField: TCurrencyField read FPorcenIvaN;
    // ... otras propiedades ...
  end;
*)
  TFactura = class
  private
    FLineas: TObjectList<TLineaFactura>;
  public
    Seller: TPartyData;
    Buyer: TPartyData;
    NroFactura: string;
    SerieFactura: string;
    FechaFactura: TDateTime;
    CodigoCliente: string;
    RazonSocialCliente: string;
    NIFCliente: string;
  public
    // IVA Normal
    FPorcenIvaN: TCurrencyField;
    FTotalIvaN: TCurrencyField;
    FPorcenReN: TCurrencyField;
    FTotalReN: TCurrencyField;
    FTotalBaseiIvaN: TCurrencyField;
// IVA Reducido
    FPorcenIvaR: TCurrencyField;
    FTotalIvaR: TCurrencyField;
    FPorcenReR: TCurrencyField;
    FTotalReR: TCurrencyField;
    FTotalBaseiIvaR: TCurrencyField;
// IVA Superreducido
    FPorcenIvaS: TCurrencyField;
    FTotalIvaS: TCurrencyField;
    FPorcenReS: TCurrencyField;
    FTotalReS: TCurrencyField;
    FTotalBaseiIvaS: TCurrencyField;
// IVA Exento
    FPorcenIvaE: TCurrencyField;
    FTotalIvaE: TCurrencyField;
    FPorcenReE: TCurrencyField;
    FTotalReE: TCurrencyField;
    FTotalBaseiIvaE: TCurrencyField;
//Totales
    FTotalBases: TCurrencyField;
    FTotalImpuestos: TCurrencyField;
    FPorcenRetencion: TCurrencyField;
    FTotalRetencion: TCurrencyField;
    FTotalFactura: TCurrencyField;
    function GetPorcenIVAN: Double;
    function GetPorcenReN: Double;
    function GetTotalBaseiIvaN: Double;
    function GetTotalIvaN: Double;
    function GetTotalReN: Double;
    procedure SetPorcenIVAN(const Value: Double);
    procedure SetTotalIvaN(const Value: Double);
    function GetPorcenIvaR: Double;
    function GetPorcenReR: Double;
    function GetTotalBaseiIvaR: Double;
    function GetTotalIvaR: Double;
    function GetTotalReR: Double;
    procedure SetPorcenIvaR(const Value: Double);
    procedure SetPorcenReR(const Value: Double);
    procedure SetTotalBaseiIvaR(const Value: Double);
    procedure SetTotalIvaR(const Value: Double);
    procedure SetTotalReR(const Value: Double);
    function GetPorcenIvaS: Double;
    function GetPorcenReS: Double;
    function GetTotalBaseiIvaS: Double;
    function GetTotalIvaS: Double;
    function GetTotalReS: Double;
    procedure SetPorcenIvaS(const Value: Double);
    procedure SetPorcenReS(const Value: Double);
    procedure SetTotalBaseiIvaS(const Value: Double);
    procedure SetTotalIvaS(const Value: Double);
    procedure SetTotalReS(const Value: Double);
    procedure SetPorcenReN(const Value: Double);
    procedure SetTotalBaseiIvaN(const Value: Double);
    procedure SetTotalReN(const Value: Double);
    function GetPorcenIvaE: Double;
    function GetPorcenReE: Double;
    function GetTotalBaseiIvaE: Double;
    function GetTotalIvaE: Double;
    function GetTotalReE: Double;
    procedure SetPorcenIvaE(const Value: Double);
    procedure SetPorcenReE(const Value: Double);
    procedure SetTotalBaseiIvaE(const Value: Double);
    procedure SetTotalIvaE(const Value: Double);
    procedure SetTotalReE(const Value: Double);
    function GetPorcenRetencion: Double;
    function GetTotalBases: Double;
    function GetTotalFactura: Double;
    function GetTotalImpuestos: Double;
    function GetTotalRetencion: Double;
    procedure SetPorcenRetencion(const Value: Double);
    procedure SetTotalBases(const Value: Double);
    procedure SetTotalFactura(const Value: Double);
    procedure SetTotalImpuestos(const Value: Double);
    procedure SetTotalRetencion(const Value: Double);
   public
    // IVA Normal
    property PorcenIvaN: Double read GetPorcenIVAN write SetPorcenIVAN;
    property TotalIvaN: Double read GetTotalIvaN write SetTotalIvaN;
    property PorcenReN: Double read GetPorcenReN write SetPorcenReN;
    property TotalReN: Double read GetTotalReN write SetTotalReN;
    property TotalBaseiIvaN: Double read GetTotalBaseiIvaN
                                                        write SetTotalBaseiIvaN;
// IVA Reducido
    property PorcenIvaR: Double read GetPorcenIvaR write SetPorcenIvaR;
    property TotalIvaR: Double read GetTotalIvaR write SetTotalIvaR;
    property PorcenReR: Double read GetPorcenReR write SetPorcenReR;
    property TotalReR: Double read GetTotalReR write SetTotalReR;
    property TotalBaseiIvaR: Double read GetTotalBaseiIvaR
                                                        write SetTotalBaseiIvaR;
// IVA Superreducido
    property PorcenIvaS: Double read GetPorcenIvaS write SetPorcenIvaS;
    property TotalIvaS: Double read GetTotalIvaS write SetTotalIvaS;
    property PorcenReS: Double read GetPorcenReS write SetPorcenReS;
    property TotalReS: Double read GetTotalReS write SetTotalReS;
    property TotalBaseiIvaS: Double read GetTotalBaseiIvaS
                                                        write SetTotalBaseiIvaS;
// IVA Exento
    property PorcenIvaE: Double read GetPorcenIvaE write SetPorcenIvaE;
    property TotalIvaE: Double read GetTotalIvaE write SetTotalIvaE;
    property PorcenReE: Double read GetPorcenReE write SetPorcenReE;
    property TotalReE: Double read GetTotalReE write SetTotalReE;
    property TotalBaseiIvaE: Double read GetTotalBaseiIvaE
                                                        write SetTotalBaseiIvaE;
//Totales
    property TotalBases: Double read GetTotalBases write SetTotalBases;
    property TotalImpuestos: Double read GetTotalImpuestos
                                                        write SetTotalImpuestos;
    property PorcenRetencion: Double read GetPorcenRetencion
                                                       write SetPorcenRetencion;
    property TotalRetencion: Double read GetTotalRetencion
                                                        write SetTotalRetencion;
    property TotalFactura: Double read GetTotalFactura
                                                          write SetTotalFactura;

    constructor Create;
    destructor Destroy; override;
    function AgregarLinea: TLineaFactura;
    property Lineas: TObjectList<TLineaFactura> read FLineas;
  end;

implementation

{ TCurrencyField }

constructor TCurrencyField.Create(AValue: Double);
begin
  FValue := AValue;
end;

function TCurrencyField.FormatValue(Decimals: Integer): string;
var
  FormatSettings: TFormatSettings;
  FormatString: string;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';
  //FormatSettings.ThousandSeparator := '';
  FormatString := '0.' + StringOfChar('0', Decimals);
  Result := FormatFloat(FormatString,
                        RoundValue(FValue, Decimals),
                        FormatSettings);
end;

function TCurrencyField.RoundValue(Value: Double; Decimals: Integer): Double;
var
  Factor, Fraction: Double;
  IntPart: Int64;
begin
  if Decimals < 0 then
    Exit(Value);
  Factor := Power(10, Decimals);
  Value := Value * Factor;
  // Separar la parte entera y la fracción
  IntPart := Trunc(Value);
  Fraction := Frac(Value);
  // Manejar el caso especial de .5
  if SameValue(Fraction, 0.5) then
    Result := (IntPart + 1) / Factor
  else
    Result := Round(Value) / Factor;
end;

function TCurrencyField.AsCur(DecimalPlaces: Integer; DecimalSeparator:Char;
   CurrencySymbol: string; ThousandSeparator: Char): string;
var
  FormatSettings: TFormatSettings;
  FormatString, FormattedValue: string;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := DecimalSeparator;
    // Usar el separador de miles solo si se especifica
  if (ThousandSeparator <> #0) then
  begin
    FormatSettings.ThousandSeparator := ThousandSeparator;
    FormatString := '#,##0' + DecimalSeparator + StringOfChar('0',
                                                                DecimalPlaces);
  end
  else
  begin
    FormatString := '0.' + StringOfChar('0', DecimalPlaces);
  end;
  FormattedValue := FormatFloat(FormatString,
                        RoundValue(FValue, DecimalPlaces),
                        FormatSettings);
  if CurrencySymbol <> '' then
    FormattedValue := FormattedValue + ' ' + CurrencySymbol;
  Result := FormattedValue;
end;

//function TCurrencyField.AsCurr(Decimals: Integer = 2): string;
//begin
//  Result := FormatValue(Decimals);
//end;

function TCurrencyField.AsFloat(Decimals:Integer = -1): Double;
begin
  if Decimals >= 0 then
    Result := RoundValue(FValue, Decimals)
  else
    Result := FValue;
end;

constructor TFactura.Create;
begin
  inherited;
  FLineas := TObjectList<TLineaFactura>.Create(True);  // True para ownership

  FTotalFactura := TCurrencyField.Create(0);
  FTotalBases  := TCurrencyField.Create(0);
  FTotalImpuestos := TCurrencyField.Create(0);
  FPorcenRetencion := TCurrencyField.Create(0);
  FTotalRetencion := TCurrencyField.Create(0);
  FTotalFactura := TCurrencyField.Create(0);
  FPorcenIvaE:= TCurrencyField.Create(0);
  FTotalIvaE:= TCurrencyField.Create(0);
  FPorcenReE:= TCurrencyField.Create(0);
  FTotalReE:= TCurrencyField.Create(0);
  FTotalBaseiIvaE:= TCurrencyField.Create(0);
  FPorcenIvaS:= TCurrencyField.Create(0);
  FTotalIvaS:= TCurrencyField.Create(0);
  FPorcenReS:= TCurrencyField.Create(0);
  FTotalReS:= TCurrencyField.Create(0);
  FTotalBaseiIvaS:= TCurrencyField.Create(0);
  FPorcenIvaN:= TCurrencyField.Create(0);
  FTotalIvaN:= TCurrencyField.Create(0);
  FPorcenReN:= TCurrencyField.Create(0);
  FTotalReN:= TCurrencyField.Create(0);
  FTotalBaseiIvaN:= TCurrencyField.Create(0);
end;

destructor TFactura.Destroy;
begin
  FLineas.Free;
  inherited;
end;

function TFactura.GetPorcenIvaE: Double;
begin
  Result := FPorcenIVAE.FValue;
end;

function TFactura.GetPorcenIVAN: Double;
begin
  Result := FPorcenIVAN.FValue;
end;

function TFactura.GetPorcenIvaR: Double;
begin
  Result := FPorcenIVAR.FValue;
end;

function TFactura.GetPorcenIvaS: Double;
begin
  Result := FPorcenIVaS.FValue;
end;

function TFactura.GetPorcenReE: Double;
begin
  Result := FPorcenReE.FValue;
end;

function TFactura.GetPorcenReN: Double;
begin
  Result := FPorcenReN.FValue;
end;

function TFactura.GetPorcenReR: Double;
begin
  Result := FPorcenReR.FValue;
end;

function TFactura.GetPorcenReS: Double;
begin
  Result := FPorcenRes.FValue;
end;

function TFactura.GetPorcenRetencion: Double;
begin
  Result := FPorcenRetencion.FValue;
end;

function TFactura.GetTotalBaseiIvaE: Double;
begin
  Result := FTotalBaseiIvaE.FValue;
end;

function TFactura.GetTotalBaseiIvaN: Double;
begin
  Result := FTotalBaseiIvaN.FValue;
end;

function TFactura.GetTotalBaseiIvaR: Double;
begin
  Result := FTotalBaseiIVAR.FValue;
end;

function TFactura.GetTotalBaseiIvaS: Double;
begin
  Result := FTotalBaseiIvaS.FValue;
end;

function TFactura.GetTotalBases: Double;
begin
  Result := FTotalBases.FValue;
end;

function TFactura.GetTotalFactura: Double;
begin
  Result := FTotalFactura.FValue;
end;

function TFactura.GetTotalImpuestos: Double;
begin
  Result := FtotalImpuestos.FValue;
end;

function TFactura.GetTotalIvaE: Double;
begin
  Result := FTotalIVAE.FValue;
end;

function TFactura.GetTotalIvaN: Double;
begin
  Result := FTotalIVaN.FValue;
end;

function TFactura.GetTotalIvaR: Double;
begin
  Result := FTotalIVAr.FValue;
end;

function TFactura.GetTotalIvaS: Double;
begin
  Result := FtotalIvaS.FValue;
end;

function TFactura.GetTotalReE: Double;
begin
  Result := FTotalReE.FValue;
end;

function TFactura.GetTotalReN: Double;
begin
  Result := FTotalReN.FValue;
end;

function TFactura.GetTotalReR: Double;
begin
  Result := FtotalRer.FValue;
end;

function TFactura.GetTotalReS: Double;
begin
  Result := FTotalRes.FValue;
end;

function TFactura.GetTotalRetencion: Double;
begin
  Result := FTotalRetencion.FValue;
end;

procedure TFactura.SetPorcenIvaE(const Value: Double);
begin
  FPorcenIVAE.FValue := Value;
end;

procedure TFactura.SetPorcenIVAN(const Value: Double);
begin
  FPorcenIVAN.FValue := Value;
end;

procedure TFactura.SetPorcenIvaR(const Value: Double);
begin
  FPorcenIVAr.FValue := Value;
end;

procedure TFactura.SetPorcenIvaS(const Value: Double);
begin
  FPorcenIVAS.FValue := Value;
end;

procedure TFactura.SetPorcenReE(const Value: Double);
begin
  FPorcenREE.FValue := Value;
end;

procedure TFactura.SetPorcenReN(const Value: Double);
begin
  FPorcenREN.FValue := Value;
end;

procedure TFactura.SetPorcenReR(const Value: Double);
begin
  FPorcenRer.FValue := Value;
end;

procedure TFactura.SetPorcenReS(const Value: Double);
begin
  FPorcenRes.FValue := Value;
end;

procedure TFactura.SetPorcenRetencion(const Value: Double);
begin
  FPorcenRetencion.FValue := Value;
end;

procedure TFactura.SetTotalBaseiIvaE(const Value: Double);
begin
  FTotalBaseiIVAE.FValue := VAlue;
end;

procedure TFactura.SetTotalBaseiIvaN(const Value: Double);
begin
  FTotalBaseiIvaN.FValue := Value;
end;

procedure TFactura.SetTotalBaseiIvaR(const Value: Double);
begin
  FTotalBaseiIvaR.FValue := Value;
end;

procedure TFactura.SetTotalBaseiIvaS(const Value: Double);
begin
  FTotalBaseiIVAS.FValue := Value;
end;

procedure TFactura.SetTotalBases(const Value: Double);
begin
  FTotalBases.FValue := VAlue;
end;

procedure TFactura.SetTotalFactura(const Value: Double);
begin
  FTotalFactura.FValue := Value;
end;

procedure TFactura.SetTotalImpuestos(const Value: Double);
begin
  FtotalImpuestos.FValue := VAlue;
end;

procedure TFactura.SetTotalIvaE(const Value: Double);
begin
  FTotalIVAE.FValue := VAlue;
end;

procedure TFactura.SetTotalIvaN(const Value: Double);
begin
  FTotalIVAN.FValue := Value;
end;

procedure TFactura.SetTotalIvaR(const Value: Double);
begin
  FTotalIvar.FValue := Value;
end;

procedure TFactura.SetTotalIvaS(const Value: Double);
begin
  FTotalIVAS.FValue := Value;
end;

procedure TFactura.SetTotalReE(const Value: Double);
begin
  FTotalREE.FValue := Value;
end;

procedure TFactura.SetTotalReN(const Value: Double);
begin
  FTotalReN.FValue := Value;
end;

procedure TFactura.SetTotalReR(const Value: Double);
begin
  FtotalRer.FValue := Value;
end;

procedure TFactura.SetTotalReS(const Value: Double);
begin
  FTotalReS.FValue := Value;
end;

procedure TFactura.SetTotalRetencion(const Value: Double);
begin
  FTotalRetencion.FValue := Value;
end;

function TFactura.AgregarLinea: TLineaFactura;
begin
  Result := TLineaFactura.Create;
  FLineas.Add(Result);
end;


end.
