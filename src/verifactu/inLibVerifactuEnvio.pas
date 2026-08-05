{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuEnvio                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente de envío de registros de facturación a la AEAT (Verifactu).       }
{    Compone el XML de alta/anulación con su huella SHA-256 encadenada         }
{    (fza_verifactu_cadena) y lo remite por SOAP con el certificado de la      }
{    empresa emisora (almacén de Windows, CODIGO_CERTIFICADO_EMP).             }
{******************************************************************************}
unit inLibVerifactuEnvio;

interface

uses
  System.SysUtils, Uni, inLibParametrosIntf;

type
  // Resultado del envío de un registro de facturación. Los campos calcan
  // las columnas de fza_facturas_consolidaciones para que el worker de la
  // cola persista la respuesta del servicio sin transformaciones.
  TResultadoEnvioVerifactu = record
    Ok:                Boolean;
    MensajeError:      string;
    EstadoRegistro:    string;    // Correcto / AceptadoConErrores
    CodigoError:       string;    // Código de validación del registro
    DescripcionError:  string;    // Descripción de validación del registro
    EsperaSegundos:    Integer;   // TiempoEsperaEnvio devuelto por AEAT
    RequestId:         string;    // CSV del envío aceptado
    QueueId:           Integer;   // lo rellena la cola con su ID
    IssuerIrsId:       string;    // NIF del emisor
    IssuedTime:        TDateTime; // instante de aceptación
    FechaExpedicion:   string;    // dd-mm-yyyy de la factura
    ChainNumber:       string;    // nº de eslabón de la cadena
    ChainHash:         string;    // huella del registro enviado
    VerifactuUrl:      string;    // URL de cotejo del QR
    QRCodeBase64:      string;    // QRCODE_BASE64_FACCON (PNG en base64)
    QRCodePng:         TBytes;    // QRCODE_PNG_FACCON (PNG binario)
    RegistroXmlFirmado:string;    // XML fiscal: firmado XAdES o XML base
    FirmaDigital:      string;    // SignatureValue XAdES o SHA-256
    SerieCertificado:  string;    // Serie del certificado firmante
    TitularCertificado:string;    // Titular del certificado firmante
    HuellaCertificado: string;    // SHA1 del certificado firmante
    PeticionCompleta:  string;    // XML SOAP enviado
    RespuestaCompleta: string;    // XML SOAP recibido
  end;

// True: el cliente AEAT está integrado y la cola puede reclamar filas
function EnvioVerifactuDisponible: Boolean;

// Envía a la AEAT el registro de facturación de la factura indicada.
// ATipoOperacion: 'ALTA' o 'ANULACION'. DEBE llamarse dentro de una
// transacción de AConn: deja bloqueada (FOR UPDATE) la fila de
// fza_verifactu_cadena del emisor hasta el commit/rollback del llamador,
// serializando así el encadenamiento entre puestos.
function EnviarRegistroFactura(
                               const AParametrosApp: IParametrosAplicacion;
                               AConn: TUniConnection;
                               const AUsuario: string;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;

// Genera el registro oficial de facturación en local y lo firma XAdES,
// sin llamar al servicio AEAT. El llamador persiste el resultado y avanza
// la cadena si procede (NO VERI*FACTU).
function GenerarRegistroFacturaLocal(
                                     const AParametrosApp:
                                     IParametrosAplicacion;
                                     AConn: TUniConnection;
                                     const AUsuario: string;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string):
                                     TResultadoEnvioVerifactu;

implementation

uses
  System.Classes, System.StrUtils, System.Hash, System.DateUtils,
  System.TimeSpan, System.NetEncoding, System.Net.HttpClient,
  System.Net.URLClient, Data.DB,
  inLibGlobalVar, inLibVerifactu, inLibVerifactuInstalacion,
  inLibMsgFacturas, inLibMsgVerifactu, inLibXades,
  inLibVerifactuConstruccionEnvio;

const
  // Endpoints oficiales del servicio SOAP de Verifactu. Con certificado
  // de sello cambiar a www10/prewww10 en los parámetros de aplicación.
  cVerifactuUrlEnvioPre =
    'https://prewww1.aeat.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/' +
    'VerifactuSOAP';
  cVerifactuUrlEnvioPro =
    'https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/' +
    'SistemaFacturacion/VerifactuSOAP';
  // Espacios de nombres de los esquemas SuministroLR / SuministroInformacion
  cNsSoap = 'http://schemas.xmlsoap.org/soap/envelope/';
  cNsLR =
    'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/tike/cont/ws/SuministroLR.xsd';
  cNsInf =
    'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/tike/cont/ws/SuministroInformacion.xsd';
  cNsDsig = 'http://www.w3.org/2000/09/xmldsig#';

type
  TBandaIva = record
    Porcentaje:   Currency;
    Base:         Currency;
    Cuota:        Currency;
    PorcentajeRe: Currency;
    CuotaRe:      Currency;
    EsExenta:     Boolean;
  end;

  // Datos de la factura y de su emisor para componer el registro
  TDatosFacturaRegistro = record
    CodigoEmpresa:    string;
    NifEmisor:       string;
    NombreEmisor:    string;
    NumeroInstalacion:string;
    VersionInstalacion:string;
    CodigoSifInstalacion:string;
    FechaFac:        TDateTime;
    FechaExpedicion: string;  // dd-mm-yyyy
    TipoFactura:     string;  // F1 / F2 / R1 / R5
    TipoFacturaRectificativa: string; // R1..R5 explícito de la factura
    NifCliente:      string;
    NombreCliente:   string;
    // Factura original rectificada (solo en R1/R5)
    TipoRectificativa: string;  // I = diferencias; S = sustitutiva
    RectSerie:       string;
    RectNumero:      string;
    RectFecha:       string;  // dd-mm-yyyy
    RectBase:        Currency;
    RectCuota:       Currency;
    RectCuotaRe:     Currency;
    TieneImporteRectificacion: Boolean;
    CuotaTotal:      Currency;
    ImporteTotal:    Currency;
    SerialCert:      string;
    TitularCert:     string;
    // Calificacion de la operacion (catalogo fza_verifactu_operaciones)
    OpDefinida:      Boolean;  // hay tipo de operacion asignado en el catalogo
    OpClaveRegimen:  string;   // ClaveRegimen Verifactu (01, 03...)
    OpCalificacion:  string;   // CalificacionOperacion (S1/S2/N1/N2) o ''
    OpOperExenta:    string;   // OperacionExenta (E1..E6) o ''
    OpRepercuteIva:  Boolean;  // True desglose por bandas; False base sin cuota
    PaisClienteISO2: string;   // COD_ALPHA2 del pais del cliente (ES, FR...)
    EsClienteUE:     Boolean;  // el pais del cliente es miembro de la UE
    EsClienteExtr:   Boolean;  // el cliente reside fuera de Espana
    Bandas:          array[0..3] of TBandaIva;
  end;

  // Eslabón anterior de la cadena de huellas del emisor
  TCadenaAnterior = record
    Contador: Int64;
    Serie:    string;
    Numero:   string;
    Fecha:    string;  // dd-mm-yyyy
    Huella:   string;
  end;

  // Selección del certificado de cliente en la negociación TLS. Busca
  // por nº de serie (CODIGO_CERTIFICADO_EMP, en su orden de bytes o el
  // inverso) y si no, por titular dentro del Subject.
  TSelectorCertificado = class
  private
    FSerial:  string;
    FTitular: string;
  public
    constructor Create(const ASerial, ATitular: string);
    procedure Seleccionar(const Sender: TObject;
                          const ARequest: TURLRequest;
                          const ACertificateList: TCertificateList;
                          var AnIndex: Integer);
  end;

function EnvioVerifactuDisponible: Boolean;
begin
  Result := True;
end;

// ===========================================================================
//   Helpers de formato
// ===========================================================================

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor,  '&', '&amp;',  [rfReplaceAll]);
  Result := StringReplace(Result,  '<', '&lt;',   [rfReplaceAll]);
  Result := StringReplace(Result,  '>', '&gt;',   [rfReplaceAll]);
  Result := StringReplace(Result,  '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

// Instante de generación con huso horario (yyyy-mm-ddThh:nn:ss+hh:mm)
function FechaHoraHusoGen(ADt: TDateTime): string;
var
  oDesfase: TTimeSpan;
  sSigno:   string;
begin
  oDesfase := TTimeZone.Local.GetUtcOffset(ADt);
  if oDesfase.Ticks < 0 then
    sSigno := '-'
  else
    sSigno := '+';
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', ADt) + sSigno +
            Format('%.2d:%.2d', [Abs(oDesfase.Hours),
                                 Abs(oDesfase.Minutes)]);
end;

function TipoFacturaVerifactu(const ATipoFac: string): string;
begin
  if SameText(ATipoFac, 'SIMPLIFICADA') then
    Result := 'F2'
  else if SameText(ATipoFac, 'RECTIFICATIVA') then
    Result := 'R5'
  else
    Result := 'F1';
end;

// ===========================================================================
//   Selección de certificado
// ===========================================================================

function NormalizarSerieCert(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, ':', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
end;

// El nº de serie se guardó byte a byte desde el blob de crypt32
// (inLibCertificates.LoadCerts); según la capa que lo lea puede venir
// con los bytes en orden inverso, así que se compara en ambos sentidos
function InvertirBytesHex(const AHex: string): string;
var
  iPos: Integer;
begin
  Result := '';
  iPos := Length(AHex) - 1;
  while iPos >= 1 do
  begin
    Result := Result + Copy(AHex, iPos, 2);
    Dec(iPos, 2);
  end;
end;

constructor TSelectorCertificado.Create(const ASerial, ATitular: string);
begin
  inherited Create;
  FSerial  := ASerial;
  FTitular := ATitular;
end;

procedure TSelectorCertificado.Seleccionar(const Sender: TObject;
                                           const ARequest: TURLRequest;
                                           const ACertificateList:
                                                 TCertificateList;
                                           var AnIndex: Integer);
var
  i:         Integer;
  sBuscada:  string;
  sSerie:    string;
begin
  AnIndex := -1;
  sBuscada := NormalizarSerieCert(FSerial);
  if sBuscada <> '' then
  begin
    for i := 0 to ACertificateList.Count - 1 do
    begin
      sSerie := NormalizarSerieCert(ACertificateList[i].SerialNum);
      if (sSerie = sBuscada) or (sSerie = InvertirBytesHex(sBuscada)) then
      begin
        AnIndex := i;
        Break;
      end;
    end;
  end;
  if (AnIndex < 0) and (Trim(FTitular) <> '') then
  begin
    for i := 0 to ACertificateList.Count - 1 do
    begin
      if ContainsText(ACertificateList[i].Subject, Trim(FTitular)) then
      begin
        AnIndex := i;
        Break;
      end;
    end;
  end;
  // Último recurso: si solo se ofrece un certificado se usa ese
  if (AnIndex < 0) and (ACertificateList.Count = 1) then
    AnIndex := 0;
end;

// ===========================================================================
//   Carga de datos: factura, certificado de la empresa y cadena
// ===========================================================================

procedure ConfigurarConsultaFactura(
  AQry: TUniQuery;
  const ASerie, ANumero: string);
begin
  AQry.SQL.Text :=
    ' SELECT f.CODIGO_EMP_FAC, f.NIF_EMPRESA_FAC, ' +
    '        f.RAZON_SOCIAL_EMPRESA_FAC, ' +
    '        f.FECHA_FAC, f.TIPO_FAC, f.TIPO_RECTIFICATIVA_FAC, ' +
    '        f.TIPO_FACTURA_VERIFACTU_FAC, ' +
    '        f.NIF_CLIENTE_FAC, f.RAZON_SOCIAL_CLIENTE_FAC, ' +
    '        f.TOTAL_IMPUESTOS_FAC, f.TOTAL_LIQUIDO_FAC, ' +
    '        f.TOTAL_RETENCION_FAC, ' +
    '        f.PORCENTAJE_IVAN_FAC, f.TOTAL_BASEI_IVAN_FAC, ' +
    '        f.TOTAL_IVAN_FAC, f.PORCENTAJE_REN_FAC, f.TOTAL_REN_FAC, ' +
    '        f.PORCENTAJE_IVAR_FAC, f.TOTAL_BASEI_IVAR_FAC, ' +
    '        f.TOTAL_IVAR_FAC, f.PORCENTAJE_RER_FAC, f.TOTAL_RER_FAC, ' +
    '        f.PORCENTAJE_IVAS_FAC, f.TOTAL_BASEI_IVAS_FAC, ' +
    '        f.TOTAL_IVAS_FAC, f.PORCENTAJE_RES_FAC, f.TOTAL_RES_FAC, ' +
    '        f.PORCENTAJE_IVAE_FAC, f.TOTAL_BASEI_IVAE_FAC, ' +
    '        f.TOTAL_IVAE_FAC, f.TIPO_OPER_VFACTU_FAC, ' +
    '        f.CODIGO_PAI_CLIENTE_FAC, pc.COD_ALPHA2_PAI, ' +
    '        pc.ESMIEMBRO_UE_PAI, vo.CLAVE_REGIMEN_VFO, ' +
    '        vo.CALIFICACION_VFO, vo.OPERACION_EXENTA_VFO, ' +
    '        vo.ESREPERCUTE_IVA_VFO, e.CODIGO_CERTIFICADO_EMP, ' +
    '        e.TITULAR_CERTIFICADO_EMP, e.NUMERO_INSTALACION_EMP, ' +
    '        e.VERSION_INSTALACION_EMP, e.CODIGO_SIF_INSTALACION_EMP ' +
    ' FROM fza_facturas f ' +
    ' LEFT JOIN fza_empresas e ' +
    '        ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
    ' LEFT JOIN fza_paises pc ' +
    '        ON pc.CODIGO_PAI_PAI = f.CODIGO_PAI_CLIENTE_FAC ' +
    ' LEFT JOIN fza_verifactu_operaciones vo ' +
    '        ON vo.CODIGO_VFO = f.TIPO_OPER_VFACTU_FAC ' +
    ' WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO';
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
end;

procedure InicializarRectificacion(var ADatos: TDatosFacturaRegistro);
begin
  ADatos.TipoFacturaRectificativa := '';
  ADatos.TipoRectificativa := '';
  ADatos.RectSerie := '';
  ADatos.RectNumero := '';
  ADatos.RectFecha := '';
  ADatos.RectBase := 0;
  ADatos.RectCuota := 0;
  ADatos.RectCuotaRe := 0;
  ADatos.TieneImporteRectificacion := False;
end;

procedure CargarIdentificacionFactura(
  AQry: TUniQuery;
  const ATipoFactura: string;
  var ADatos: TDatosFacturaRegistro);
begin
  ADatos.CodigoEmpresa :=
    Trim(AQry.FieldByName('CODIGO_EMP_FAC').AsString);
  ADatos.NifEmisor := NormalizarNifVerifactu(
    AQry.FieldByName('NIF_EMPRESA_FAC').AsString);
  ADatos.NombreEmisor :=
    Trim(AQry.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString);
  ADatos.NumeroInstalacion :=
    Trim(AQry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
  ADatos.VersionInstalacion :=
    Trim(AQry.FieldByName('VERSION_INSTALACION_EMP').AsString);
  ADatos.CodigoSifInstalacion :=
    Trim(AQry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
  ADatos.FechaFac := AQry.FieldByName('FECHA_FAC').AsDateTime;
  ADatos.FechaExpedicion :=
    FormatDateTime('dd-mm-yyyy', ADatos.FechaFac);
  ADatos.TipoFactura := TipoFacturaVerifactu(ATipoFactura);
  InicializarRectificacion(ADatos);
  if SameText(ATipoFactura, 'RECTIFICATIVA') then
  begin
    ADatos.TipoFacturaRectificativa := UpperCase(Trim(
      AQry.FieldByName('TIPO_FACTURA_VERIFACTU_FAC').AsString));
    if (ADatos.TipoFacturaRectificativa <> '') and
       (not MatchText(ADatos.TipoFacturaRectificativa,
         ['R1', 'R2', 'R3', 'R4', 'R5'])) then
      raise Exception.Create(
        'El tipo VERI*FACTU de la rectificativa no es válido.');
    ADatos.TipoRectificativa := UpperCase(Trim(
      AQry.FieldByName('TIPO_RECTIFICATIVA_FAC').AsString));
    if ADatos.TipoRectificativa = '' then
      ADatos.TipoRectificativa := 'I';
    if (ADatos.TipoRectificativa <> 'I') and
       (ADatos.TipoRectificativa <> 'S') then
      raise Exception.Create(
        'El tipo fiscal de rectificativa debe ser I o S.');
  end;
  ADatos.NifCliente := NormalizarNifVerifactu(
    AQry.FieldByName('NIF_CLIENTE_FAC').AsString);
  ADatos.NombreCliente :=
    Trim(AQry.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
end;

procedure CargarImportesYCertificado(
  AQry: TUniQuery;
  var ADatos: TDatosFacturaRegistro);
begin
  ADatos.CuotaTotal :=
    AQry.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
  // Verifactu comunica el bruto de IVA, antes de descontar la retención.
  ADatos.ImporteTotal :=
    AQry.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency +
    AQry.FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
  ADatos.SerialCert :=
    Trim(AQry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
  ADatos.TitularCert :=
    Trim(AQry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
end;

procedure CargarOperacionFiscal(
  AQry: TUniQuery;
  var ADatos: TDatosFacturaRegistro);
begin
  ADatos.OpDefinida :=
    (Trim(AQry.FieldByName('TIPO_OPER_VFACTU_FAC').AsString) <> '') and
    (not AQry.FieldByName('CLAVE_REGIMEN_VFO').IsNull);
  ADatos.OpClaveRegimen :=
    Trim(AQry.FieldByName('CLAVE_REGIMEN_VFO').AsString);
  ADatos.OpCalificacion :=
    Trim(AQry.FieldByName('CALIFICACION_VFO').AsString);
  ADatos.OpOperExenta :=
    Trim(AQry.FieldByName('OPERACION_EXENTA_VFO').AsString);
  ADatos.OpRepercuteIva := not SameText(
    Trim(AQry.FieldByName('ESREPERCUTE_IVA_VFO').AsString), 'N');
  ADatos.PaisClienteISO2 :=
    Trim(AQry.FieldByName('COD_ALPHA2_PAI').AsString);
  ADatos.EsClienteUE := SameText(
    Trim(AQry.FieldByName('ESMIEMBRO_UE_PAI').AsString), 'S');
  ADatos.EsClienteExtr := (ADatos.PaisClienteISO2 <> '') and
    (not SameText(ADatos.PaisClienteISO2, 'ES')) and
    (Trim(AQry.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString) <> '724');
end;

procedure CargarBandasIva(
  AQry: TUniQuery;
  var ADatos: TDatosFacturaRegistro);
begin
  ADatos.Bandas[0].Porcentaje :=
    AQry.FieldByName('PORCENTAJE_IVAN_FAC').AsCurrency;
  ADatos.Bandas[0].Base :=
    AQry.FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
  ADatos.Bandas[0].Cuota :=
    AQry.FieldByName('TOTAL_IVAN_FAC').AsCurrency;
  ADatos.Bandas[0].PorcentajeRe :=
    AQry.FieldByName('PORCENTAJE_REN_FAC').AsCurrency;
  ADatos.Bandas[0].CuotaRe :=
    AQry.FieldByName('TOTAL_REN_FAC').AsCurrency;
  ADatos.Bandas[0].EsExenta := False;
  ADatos.Bandas[1].Porcentaje :=
    AQry.FieldByName('PORCENTAJE_IVAR_FAC').AsCurrency;
  ADatos.Bandas[1].Base :=
    AQry.FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
  ADatos.Bandas[1].Cuota :=
    AQry.FieldByName('TOTAL_IVAR_FAC').AsCurrency;
  ADatos.Bandas[1].PorcentajeRe :=
    AQry.FieldByName('PORCENTAJE_RER_FAC').AsCurrency;
  ADatos.Bandas[1].CuotaRe :=
    AQry.FieldByName('TOTAL_RER_FAC').AsCurrency;
  ADatos.Bandas[1].EsExenta := False;
  ADatos.Bandas[2].Porcentaje :=
    AQry.FieldByName('PORCENTAJE_IVAS_FAC').AsCurrency;
  ADatos.Bandas[2].Base :=
    AQry.FieldByName('TOTAL_BASEI_IVAS_FAC').AsCurrency;
  ADatos.Bandas[2].Cuota :=
    AQry.FieldByName('TOTAL_IVAS_FAC').AsCurrency;
  ADatos.Bandas[2].PorcentajeRe :=
    AQry.FieldByName('PORCENTAJE_RES_FAC').AsCurrency;
  ADatos.Bandas[2].CuotaRe :=
    AQry.FieldByName('TOTAL_RES_FAC').AsCurrency;
  ADatos.Bandas[2].EsExenta := False;
  ADatos.Bandas[3].Porcentaje :=
    AQry.FieldByName('PORCENTAJE_IVAE_FAC').AsCurrency;
  ADatos.Bandas[3].Base :=
    AQry.FieldByName('TOTAL_BASEI_IVAE_FAC').AsCurrency;
  ADatos.Bandas[3].Cuota :=
    AQry.FieldByName('TOTAL_IVAE_FAC').AsCurrency;
  ADatos.Bandas[3].PorcentajeRe := 0;
  ADatos.Bandas[3].CuotaRe := 0;
  ADatos.Bandas[3].EsExenta := True;
end;

procedure ConfigurarConsultaAntecesoraRelacion(
  AQry: TUniQuery;
  const ASerie, ANumero: string);
begin
  AQry.Close;
  AQry.SQL.Text :=
    ' SELECT o.SERIE_FAC, o.NUMERO_FAC, o.TIPO_FAC, ' +
    '        DATE_FORMAT(o.FECHA_FAC, ''%d-%m-%Y'') AS FECHA_TXT, ' +
    '        COALESCE(o.TOTAL_BASES_FAC, 0) AS BASE_RECT, ' +
    '        COALESCE(o.TOTAL_IVAN_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_IVAR_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_IVAS_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_IVAE_FAC, 0) AS CUOTA_RECT, ' +
    '        COALESCE(o.TOTAL_REN_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_RER_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_RES_FAC, 0) + ' +
    '        COALESCE(o.TOTAL_REE_FAC, 0) AS CUOTA_RE_RECT ' +
    ' FROM fza_facturas_relaciones r ' +
    ' JOIN fza_facturas o ' +
    '   ON o.SERIE_FAC = r.SERIE_FAC_ORIGEN_FACREL ' +
    '  AND o.NUMERO_FAC = r.NUMERO_FAC_ORIGEN_FACREL ' +
    ' WHERE r.SERIE_FAC_FACREL = :SERIE ' +
    '   AND r.NUMERO_FAC_FACREL = :NUMERO ' +
    ' ORDER BY r.ID_FACREL DESC LIMIT 1';
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
end;

procedure ConfigurarConsultaAntecesoraAbono(
  AQry: TUniQuery;
  const ASerie, ANumero: string);
begin
  AQry.Close;
  AQry.SQL.Text :=
    ' SELECT SERIE_FAC, NUMERO_FAC, TIPO_FAC, ' +
    '        DATE_FORMAT(FECHA_FAC, ''%d-%m-%Y'') AS FECHA_TXT, ' +
    '        COALESCE(TOTAL_BASES_FAC, 0) AS BASE_RECT, ' +
    '        COALESCE(TOTAL_IVAN_FAC, 0) + ' +
    '        COALESCE(TOTAL_IVAR_FAC, 0) + ' +
    '        COALESCE(TOTAL_IVAS_FAC, 0) + ' +
    '        COALESCE(TOTAL_IVAE_FAC, 0) AS CUOTA_RECT, ' +
    '        COALESCE(TOTAL_REN_FAC, 0) + ' +
    '        COALESCE(TOTAL_RER_FAC, 0) + ' +
    '        COALESCE(TOTAL_RES_FAC, 0) + ' +
    '        COALESCE(TOTAL_REE_FAC, 0) AS CUOTA_RE_RECT ' +
    ' FROM fza_facturas ' +
    ' WHERE SERIE_FAC_ABONO_FAC = :SERIE ' +
    '   AND NUMERO_FAC_ABONO_FAC = :NUMERO LIMIT 1';
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
end;

procedure AplicarAntecesora(
  AQry: TUniQuery;
  const ATipoFactura: string;
  var ADatos: TDatosFacturaRegistro);
begin
  if SameText(ATipoFactura, 'RECTIFICATIVA') then
  begin
    if ADatos.TipoFacturaRectificativa <> '' then
      ADatos.TipoFactura := ADatos.TipoFacturaRectificativa
    else if SameText(
      AQry.FieldByName('TIPO_FAC').AsString, 'SIMPLIFICADA') then
      ADatos.TipoFactura := 'R5'
    else
      ADatos.TipoFactura := 'R1';
    ADatos.RectSerie := AQry.FieldByName('SERIE_FAC').AsString;
    ADatos.RectNumero := AQry.FieldByName('NUMERO_FAC').AsString;
    ADatos.RectFecha := AQry.FieldByName('FECHA_TXT').AsString;
    ADatos.RectBase := AQry.FieldByName('BASE_RECT').AsCurrency;
    ADatos.RectCuota := AQry.FieldByName('CUOTA_RECT').AsCurrency;
    ADatos.RectCuotaRe := AQry.FieldByName('CUOTA_RE_RECT').AsCurrency;
    ADatos.TieneImporteRectificacion := True;
  end
  else if SameText(
    AQry.FieldByName('TIPO_FAC').AsString, 'SIMPLIFICADA') then
  begin
    ADatos.TipoFactura := 'F3';
    ADatos.RectSerie := AQry.FieldByName('SERIE_FAC').AsString;
    ADatos.RectNumero := AQry.FieldByName('NUMERO_FAC').AsString;
    ADatos.RectFecha := AQry.FieldByName('FECHA_TXT').AsString;
  end;
end;

procedure CargarAntecesora(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoFactura: string;
  var ADatos: TDatosFacturaRegistro);
begin
  if SameText(ATipoFactura, 'RECTIFICATIVA') or
     SameText(ATipoFactura, 'NORMAL') then
  begin
    ConfigurarConsultaAntecesoraRelacion(AQry, ASerie, ANumero);
    AQry.Open;
    if AQry.IsEmpty then
    begin
      ConfigurarConsultaAntecesoraAbono(AQry, ASerie, ANumero);
      AQry.Open;
    end;
    if not AQry.IsEmpty then
      AplicarAntecesora(AQry, ATipoFactura, ADatos);
  end;
end;

function CargarDatosFactura(AConn: TUniConnection;
                            const ASerie, ANumero: string;
                            out ADatos: TDatosFacturaRegistro): Boolean;
var
  Qry:      TUniQuery;
  sTipoFac: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    ConfigurarConsultaFactura(Qry, ASerie, ANumero);
    Qry.Open;
    // Si la fila de la cola no apunta a una factura real (huérfana,
    // p.ej. 0\0) se devuelve False sin lanzar excepción: el llamador
    // lo deja solo en el log de Verifactu como error de envío y no
    // salta el diálogo de excepción por pantalla.
    Result := not Qry.IsEmpty;
    if Result then
    begin
      sTipoFac := Qry.FieldByName('TIPO_FAC').AsString;
      CargarIdentificacionFactura(Qry, sTipoFac, ADatos);
      CargarImportesYCertificado(Qry, ADatos);
      CargarOperacionFiscal(Qry, ADatos);
      CargarBandasIva(Qry, ADatos);
      CargarAntecesora(Qry, ASerie, ANumero, sTipoFac, ADatos);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

// Asegura la fila de cadena del emisor y la bloquea (FOR UPDATE) dentro
// de la transacción del llamador: nadie más encadena hasta el commit
procedure ObtenerCadenaParaEnvio(AConn: TUniConnection;
                                 const AUsuario: string;
                                 const ANif: string;
                                 out ACadena: TCadenaAnterior);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' INSERT IGNORE INTO fza_verifactu_cadena ' +
      ' (NIF_VFCAD, CONTADOR_VFCAD, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:NIF, 0, NOW(), :USUARIO)';
    Qry.ParamByName('NIF').AsString     := ANif;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.Execute;
    Qry.SQL.Text :=
      ' SELECT CONTADOR_VFCAD, SERIE_FAC_VFCAD, NUMERO_FAC_VFCAD, ' +
      '        DATE_FORMAT(FECHA_FAC_VFCAD, ''%d-%m-%Y'') AS FECHA_TXT, ' +
      '        HUELLA_VFCAD ' +
      ' FROM fza_verifactu_cadena ' +
      ' WHERE NIF_VFCAD = :NIF ' +
      ' FOR UPDATE';
    Qry.ParamByName('NIF').AsString := ANif;
    Qry.Open;
    ACadena.Contador := Qry.FieldByName('CONTADOR_VFCAD').AsLargeInt;
    ACadena.Serie    := Qry.FieldByName('SERIE_FAC_VFCAD').AsString;
    ACadena.Numero   := Qry.FieldByName('NUMERO_FAC_VFCAD').AsString;
    ACadena.Fecha    := Qry.FieldByName('FECHA_TXT').AsString;
    ACadena.Huella   := Trim(Qry.FieldByName('HUELLA_VFCAD').AsString);
  finally
    FreeAndNil(Qry);
  end;
end;

// ===========================================================================
//   Composición del XML del registro
// ===========================================================================

function ConstruirEncadenamiento(const ANif: string;
                                 const ACadena: TCadenaAnterior): string;
begin
  if ACadena.Huella = '' then
    Result := '<sum1:Encadenamiento>' +
              '<sum1:PrimerRegistro>S</sum1:PrimerRegistro>' +
              '</sum1:Encadenamiento>'
  else
    Result := '<sum1:Encadenamiento><sum1:RegistroAnterior>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(ANif) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(ComponerNumSerieFactura(ACadena.Serie, ACadena.Numero)) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + ACadena.Fecha +
      '</sum1:FechaExpedicionFactura>' +
      '<sum1:Huella>' + ACadena.Huella + '</sum1:Huella>' +
      '</sum1:RegistroAnterior></sum1:Encadenamiento>';
end;

function ConstruirSistemaInformatico(
                                     const AParametrosApp:
                                     IParametrosAplicacion;
                                     AConn: TUniConnection;
                                     const ADatos: TDatosFacturaRegistro):
                                     string;
var
  Qry:          TUniQuery;
  sMultiOT:     string;
  sNombre:      string;
  sNif:         string;
  sInstalacion: string;
begin
  sNombre := AParametrosApp.GetString('appVerifactuSifNombreRazon',
                                      'Alejandro Laorden Hidalgo');
  // La AEAT responde un 1100 genérico ('NIF') si el NIF del productor
  // va vacío o mal formado: se valida aquí con un mensaje claro
  sNif := NormalizarNifVerifactu(
            AParametrosApp.GetString('appVerifactuSifNif', ''));
  if Length(sNif) <> 9 then
    raise Exception.CreateFmt(SErrorNifProductorSoftwareVerifactuInvalido,
      [sNif]);
  ValidarInstalacionSif(ADatos.NumeroInstalacion,
                        ADatos.VersionInstalacion,
                        ADatos.CodigoSifInstalacion,
                        ADatos.NombreEmisor,
                        ADatos.NifEmisor);
  sInstalacion := ADatos.NumeroInstalacion;
  // Varios obligados tributarios si hay más de una empresa activa
  sMultiOT := 'N';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ' SELECT COUNT(*) ' +
                    ' FROM fza_empresas ' +
                    ' WHERE ESACTIVO_EMP = ''S''';
    Qry.Open;
    if Qry.Fields[0].AsInteger > 1 then
      sMultiOT := 'S';
  finally
    FreeAndNil(Qry);
  end;
  Result :=
    '<sum1:SistemaInformatico>' +
    '<sum1:NombreRazon>' + EscaparXml(sNombre) + '</sum1:NombreRazon>' +
    '<sum1:NIF>' + EscaparXml(sNif) + '</sum1:NIF>' +
    '<sum1:NombreSistemaInformatico>Factuzam' +
    '</sum1:NombreSistemaInformatico>' +
    '<sum1:IdSistemaInformatico>FZ</sum1:IdSistemaInformatico>' +
    '<sum1:Version>' + EscaparXml(oVersion) + '</sum1:Version>' +
    '<sum1:NumeroInstalacion>' + EscaparXml(sInstalacion) +
    '</sum1:NumeroInstalacion>' +
    '<sum1:TipoUsoPosibleSoloVerifactu>N' +
    '</sum1:TipoUsoPosibleSoloVerifactu>' +
    '<sum1:TipoUsoPosibleMultiOT>S</sum1:TipoUsoPosibleMultiOT>' +
    '<sum1:IndicadorMultiplesOT>' + sMultiOT +
    '</sum1:IndicadorMultiplesOT>' +
    '</sum1:SistemaInformatico>';
end;

function ConstruirDesglose(const ADatos: TDatosFacturaRegistro): string;
var
  i:          Integer;
  sDet:       string;
  sClaveReg:  string;
  sCalif:     string;
  sExenta:    string;
  sCalifBnd:  string;
  bRepercute: Boolean;
  dBaseTot:   Currency;
begin
  Result := '';
  // Parametros de la operacion segun el catalogo (fza_verifactu_operaciones).
  // Por defecto: regimen general 01, sujeta S1, con IVA repercutido. Si el
  // usuario asigno un tipo, se toma su mapeo. Si no asigno tipo pero el cliente
  // esta fuera de la UE, se aplica exportacion (E2) de forma automatica.
  sClaveReg  := '01';
  sCalif     := '';
  sExenta    := '';
  bRepercute := True;
  if ADatos.OpDefinida then
  begin
    if ADatos.OpClaveRegimen <> '' then
      sClaveReg := ADatos.OpClaveRegimen;
    sCalif     := ADatos.OpCalificacion;
    sExenta    := ADatos.OpOperExenta;
    bRepercute := ADatos.OpRepercuteIva;
  end
  else if ADatos.EsClienteExtr and (not ADatos.EsClienteUE) then
  begin
    sExenta    := 'E2';
    bRepercute := False;
  end;
  if not bRepercute then
  begin
    // Un unico DetalleDesglose con la base total, sin tipo ni cuota: el IVA lo
    // autoliquida el destinatario (calificacion N1/N2/S2) o la operacion esta
    // exenta (OperacionExenta E2..E6). Si no hay codigo, exenta E1 por defecto.
    dBaseTot := 0;
    for i := Low(ADatos.Bandas) to High(ADatos.Bandas) do
      dBaseTot := dBaseTot + ADatos.Bandas[i].Base;
    if sExenta <> '' then
      sDet := '<sum1:OperacionExenta>' + sExenta + '</sum1:OperacionExenta>'
    else if sCalif <> '' then
      sDet := '<sum1:CalificacionOperacion>' + sCalif +
              '</sum1:CalificacionOperacion>'
    else
      sDet := '<sum1:OperacionExenta>E1</sum1:OperacionExenta>';
    Result :=
      '<sum1:DetalleDesglose>' +
      '<sum1:Impuesto>01</sum1:Impuesto>' +
      '<sum1:ClaveRegimen>' + sClaveReg + '</sum1:ClaveRegimen>' +
      sDet +
      '<sum1:BaseImponibleOimporteNoSujeto>' +
      FormatearImporteVerifactu(dBaseTot) +
      '</sum1:BaseImponibleOimporteNoSujeto>' +
      '</sum1:DetalleDesglose>';
  end
  else
  begin
    // Operacion con IVA repercutido: desglose por bandas. La calificacion de
    // las bandas sujetas sale del catalogo (S1 por defecto); la banda exenta
    // mantiene su exencion nacional E1. La clave de regimen tambien es la del
    // catalogo (p.ej. 03 para bienes usados).
    if sCalif <> '' then
      sCalifBnd := sCalif
    else
      sCalifBnd := 'S1';
    for i := Low(ADatos.Bandas) to High(ADatos.Bandas) do
    begin
      if (Abs(ADatos.Bandas[i].Base) > 0.001) or
         (Abs(ADatos.Bandas[i].Cuota) > 0.001) then
      begin
        sDet := '<sum1:Impuesto>01</sum1:Impuesto>' +
                '<sum1:ClaveRegimen>' + sClaveReg + '</sum1:ClaveRegimen>';
        if ADatos.Bandas[i].EsExenta then
        begin
          // Exenta: motivo E1 por defecto (art. 20 LIVA)
          sDet := sDet +
            '<sum1:OperacionExenta>E1</sum1:OperacionExenta>' +
            '<sum1:BaseImponibleOimporteNoSujeto>' +
            FormatearImporteVerifactu(ADatos.Bandas[i].Base) +
            '</sum1:BaseImponibleOimporteNoSujeto>';
        end
        else
        begin
          sDet := sDet +
            '<sum1:CalificacionOperacion>' + sCalifBnd +
            '</sum1:CalificacionOperacion>' +
            '<sum1:TipoImpositivo>' +
            FormatearImporteVerifactu(ADatos.Bandas[i].Porcentaje) +
            '</sum1:TipoImpositivo>' +
            '<sum1:BaseImponibleOimporteNoSujeto>' +
            FormatearImporteVerifactu(ADatos.Bandas[i].Base) +
            '</sum1:BaseImponibleOimporteNoSujeto>' +
            '<sum1:CuotaRepercutida>' +
            FormatearImporteVerifactu(ADatos.Bandas[i].Cuota) +
            '</sum1:CuotaRepercutida>';
          if Abs(ADatos.Bandas[i].CuotaRe) > 0.001 then
            sDet := sDet +
              '<sum1:TipoRecargoEquivalencia>' +
              FormatearImporteVerifactu(ADatos.Bandas[i].PorcentajeRe) +
              '</sum1:TipoRecargoEquivalencia>' +
              '<sum1:CuotaRecargoEquivalencia>' +
              FormatearImporteVerifactu(ADatos.Bandas[i].CuotaRe) +
              '</sum1:CuotaRecargoEquivalencia>';
        end;
        Result := Result + '<sum1:DetalleDesglose>' + sDet +
                  '</sum1:DetalleDesglose>';
      end;
    end;
  end;
  // Ticket a total cero: desglose minimo para cumplir el esquema
  if Result = '' then
    Result := '<sum1:DetalleDesglose>' +
      '<sum1:Impuesto>01</sum1:Impuesto>' +
      '<sum1:ClaveRegimen>01</sum1:ClaveRegimen>' +
      '<sum1:CalificacionOperacion>S1</sum1:CalificacionOperacion>' +
      '<sum1:TipoImpositivo>0.00</sum1:TipoImpositivo>' +
      '<sum1:BaseImponibleOimporteNoSujeto>0.00' +
      '</sum1:BaseImponibleOimporteNoSujeto>' +
      '<sum1:CuotaRepercutida>0.00</sum1:CuotaRepercutida>' +
      '</sum1:DetalleDesglose>';
end;

function ConstruirRegistroAlta(
                               const AParametrosApp: IParametrosAplicacion;
                               const ADatos: TDatosFacturaRegistro;
                               const ASerie, ANumero: string;
                               const ACadena: TCadenaAnterior;
                               const ASif, AFhGen: string;
                               ASubsanacion: Boolean;
                               out AHuella: string): string;
var
  oEntrada: TEntradaConstruccionRegistroAlta;
  oResultado: TResultadoConstruccionRegistroAlta;
begin
  oEntrada := Default(TEntradaConstruccionRegistroAlta);
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.NumSerieFactura := ComponerNumSerieFactura(ASerie, ANumero);
  oEntrada.NifEmisor := ADatos.NifEmisor;
  oEntrada.NombreEmisor := ADatos.NombreEmisor;
  oEntrada.FechaExpedicion := ADatos.FechaExpedicion;
  oEntrada.TipoFactura := ADatos.TipoFactura;
  oEntrada.TipoRectificativa := ADatos.TipoRectificativa;
  oEntrada.RectNumero := ADatos.RectNumero;
  oEntrada.RectNumSerieFactura := ComponerNumSerieFactura(
    ADatos.RectSerie, ADatos.RectNumero);
  oEntrada.RectFecha := ADatos.RectFecha;
  oEntrada.RectBase := FormatearImporteVerifactu(ADatos.RectBase);
  oEntrada.RectCuota := FormatearImporteVerifactu(ADatos.RectCuota);
  oEntrada.RectCuotaRe := FormatearImporteVerifactu(ADatos.RectCuotaRe);
  oEntrada.TieneRectCuotaRe := Abs(ADatos.RectCuotaRe) > 0.001;
  oEntrada.TieneImporteRectificacion :=
    ADatos.TieneImporteRectificacion;
  oEntrada.NifCliente := ADatos.NifCliente;
  oEntrada.NombreCliente := ADatos.NombreCliente;
  oEntrada.PaisClienteISO2 := ADatos.PaisClienteISO2;
  oEntrada.EsClienteUE := ADatos.EsClienteUE;
  oEntrada.EsClienteExtr := ADatos.EsClienteExtr;
  oEntrada.CuotaTotal := FormatearImporteVerifactu(ADatos.CuotaTotal);
  oEntrada.ImporteTotal := FormatearImporteVerifactu(
    ADatos.ImporteTotal);
  oEntrada.CadenaNumSerieFactura := ComponerNumSerieFactura(
    ACadena.Serie, ACadena.Numero);
  oEntrada.CadenaFecha := ACadena.Fecha;
  oEntrada.HuellaAnterior := ACadena.Huella;
  oEntrada.FechaHoraHuso := AFhGen;
  oEntrada.SistemaInformaticoXml := ASif;
  oEntrada.DesgloseXml := ConstruirDesglose(ADatos);
  oEntrada.DescripcionOperacion := AParametrosApp.GetString(
    'appVerifactuDescripcionOpe', 'Venta');
  oEntrada.EsSubsanacion := ASubsanacion;
  oResultado := ConstruirRegistroAltaVerifactu(oEntrada);
  AHuella := oResultado.Huella;
  Result := oResultado.Xml;
end;

function ConstruirRegistroAnulacion(const ADatos: TDatosFacturaRegistro;
                                    const ASerie, ANumero: string;
                                    const ACadena: TCadenaAnterior;
                                    const ASif, AFhGen: string;
                                    out AHuella: string): string;
var
  sNumSerie: string;
begin
  sNumSerie := ComponerNumSerieFactura(ASerie, ANumero);
  // Huella del registro de anulación según especificación AEAT
  AHuella := UpperCase(THashSHA2.GetHashString(
    'IDEmisorFacturaAnulada=' + ADatos.NifEmisor +
    '&NumSerieFacturaAnulada=' + sNumSerie +
    '&FechaExpedicionFacturaAnulada=' + ADatos.FechaExpedicion +
    '&Huella=' + ACadena.Huella +
    '&FechaHoraHusoGenRegistro=' + AFhGen));
  Result :=
    '<sum1:RegistroAnulacion>' +
    '<sum1:IDVersion>1.0</sum1:IDVersion>' +
    '<sum1:IDFactura>' +
    '<sum1:IDEmisorFacturaAnulada>' + EscaparXml(ADatos.NifEmisor) +
    '</sum1:IDEmisorFacturaAnulada>' +
    '<sum1:NumSerieFacturaAnulada>' + EscaparXml(sNumSerie) +
    '</sum1:NumSerieFacturaAnulada>' +
    '<sum1:FechaExpedicionFacturaAnulada>' + ADatos.FechaExpedicion +
    '</sum1:FechaExpedicionFacturaAnulada>' +
    '</sum1:IDFactura>' +
    ConstruirEncadenamiento(ADatos.NifEmisor, ACadena) +
    ASif +
    '<sum1:FechaHoraHusoGenRegistro>' + AFhGen +
    '</sum1:FechaHoraHusoGenRegistro>' +
    '<sum1:TipoHuella>01</sum1:TipoHuella>' +
    '<sum1:Huella>' + AHuella + '</sum1:Huella>' +
    '</sum1:RegistroAnulacion>';
end;

function EnvolverSoap(const ADatos: TDatosFacturaRegistro;
                      const ARegistro: string): string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<soapenv:Envelope xmlns:soapenv="' + cNsSoap + '" ' +
    'xmlns:sum="' + cNsLR + '" xmlns:sum1="' + cNsInf + '">' +
    '<soapenv:Header/><soapenv:Body>' +
    '<sum:RegFactuSistemaFacturacion>' +
    '<sum:Cabecera><sum1:ObligadoEmision>' +
    '<sum1:NombreRazon>' + EscaparXml(ADatos.NombreEmisor) +
    '</sum1:NombreRazon>' +
    '<sum1:NIF>' + EscaparXml(ADatos.NifEmisor) + '</sum1:NIF>' +
    '</sum1:ObligadoEmision></sum:Cabecera>' +
    '<sum:RegistroFactura>' + ARegistro + '</sum:RegistroFactura>' +
    '</sum:RegFactuSistemaFacturacion>' +
    '</soapenv:Body></soapenv:Envelope>';
end;

function ExtraerEtiquetaXmlLocal(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
  iFin: Integer;
  sApertura: string;
  sCierre: string;
begin
  Result := '';
  sApertura := '<' + AEtiqueta + '>';
  sCierre := '</' + AEtiqueta + '>';
  iIni := Pos(sApertura, AXml);
  if iIni > 0 then
  begin
    iIni := iIni + Length(sApertura);
    iFin := PosEx(sCierre, AXml, iIni);
    if iFin > iIni then
      Result := Copy(AXml, iIni, iFin - iIni);
  end;
end;

function RegistroConNamespaces(const ARegistro, ARaiz: string): string;
var
  sApertura: string;
  sNuevaApertura: string;
begin
  sApertura := '<sum1:' + ARaiz + '>';
  sNuevaApertura := '<sum1:' + ARaiz + ' xmlns:sum1="' + cNsInf +
                    '" xmlns:ds="' + cNsDsig + '">';
  Result := StringReplace(ARegistro, sApertura, sNuevaApertura, []);
  Result := '<?xml version="1.0" encoding="UTF-8"?>' + Result;
end;

function RaizRegistroFacturacion(const ATipoOperacion: string): string;
begin
  if ATipoOperacion = 'ANULACION' then
    Result := 'RegistroAnulacion'
  else
    Result := 'RegistroAlta';
end;

function XmlRegistroFacturacionLocal(const ARegistro,
                                     ATipoOperacion: string): string;
begin
  Result := RegistroConNamespaces(ARegistro,
                                  RaizRegistroFacturacion(ATipoOperacion));
end;

function FirmarRegistroFacturacion(const ARegistro, ATipoOperacion,
                                   AHuella, ASerial, ATitular: string;
                                   out ADatosCert: TXadesDatosCertificado;
                                   out AFirmaDigital: string): string;
var
  oOpciones: TXadesOpciones;
  sXml: string;
begin
  sXml := XmlRegistroFacturacionLocal(ARegistro, ATipoOperacion);
  oOpciones := OpcionesXadesNoVerifactu('FZ-FACTURA-' + AHuella);
  oOpciones.FirmaSilenciosa := False;
  Result := FirmarXmlXadesEnveloped(sXml, ASerial, ATitular, oOpciones,
                                    ADatosCert);
  AFirmaDigital := ExtraerEtiquetaXmlLocal(Result, 'ds:SignatureValue');
end;

// ===========================================================================
//   Transporte HTTP con certificado de cliente
// ===========================================================================

function UrlEnvio(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if VerifactuEntorno(AParametrosApp) = 'PRO' then
    Result := AParametrosApp.GetString('appVerifactuUrlEnvioPro',
                                       cVerifactuUrlEnvioPro)
  else
    Result := AParametrosApp.GetString('appVerifactuUrlEnvioPre',
                                       cVerifactuUrlEnvioPre);
end;

procedure EnviarHttp(const AUrl, APeticion: string;
                     const ASerialCert, ATitularCert: string;
                     out AStatus: Integer; out ARespuesta: string);
var
  oHttp:     THTTPClient;
  oSelector: TSelectorCertificado;
  oCuerpo:   TStringStream;
  oResp:     IHTTPResponse;
begin
  oHttp     := THTTPClient.Create;
  oSelector := TSelectorCertificado.Create(ASerialCert, ATitularCert);
  oCuerpo   := TStringStream.Create(APeticion, TEncoding.UTF8);
  try
    oHttp.ConnectionTimeout := 30000;
    oHttp.ResponseTimeout   := 90000;
    oHttp.OnNeedClientCertificate := oSelector.Seleccionar;
    oResp := oHttp.Post(AUrl, oCuerpo, nil,
      [TNetHeader.Create('Content-Type', 'text/xml; charset=utf-8'),
       TNetHeader.Create('SOAPAction', '""')]);
    AStatus    := oResp.StatusCode;
    ARespuesta := oResp.ContentAsString(TEncoding.UTF8);
  finally
    FreeAndNil(oCuerpo);
    FreeAndNil(oSelector);
    FreeAndNil(oHttp);
  end;
end;

// ===========================================================================
//   API pública
// ===========================================================================

procedure InicializarResultadoEnvio(var AResultado: TResultadoEnvioVerifactu);
begin
  AResultado.Ok             := False;
  AResultado.QueueId        := 0;
  AResultado.IssuedTime     := 0;
  AResultado.EsperaSegundos := 0;
  AResultado.MensajeError   := '';
  AResultado.EstadoRegistro := '';
  AResultado.CodigoError    := '';
  AResultado.DescripcionError := '';
  AResultado.RequestId      := '';
  AResultado.IssuerIrsId    := '';
  AResultado.FechaExpedicion := '';
  AResultado.ChainNumber    := '';
  AResultado.ChainHash      := '';
  AResultado.VerifactuUrl   := '';
  AResultado.QRCodeBase64   := '';
  SetLength(AResultado.QRCodePng, 0);
  AResultado.RegistroXmlFirmado := '';
  AResultado.FirmaDigital := '';
  AResultado.SerieCertificado := '';
  AResultado.TitularCertificado := '';
  AResultado.HuellaCertificado := '';
  AResultado.PeticionCompleta := '';
  AResultado.RespuestaCompleta := '';
end;

function ConstruirRegistroFactura(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  AConn: TUniConnection;
                                  const AUsuario: string;
                                  const ASerie, ANumero,
                                  ATipoOperacion: string;
                                  out ADatos: TDatosFacturaRegistro;
                                  out ACadena: TCadenaAnterior;
                                  out ARegistro, AHuella: string):
                                  Boolean;
var
  sFhGen: string;
  sSif:   string;
begin
  Result := CargarDatosFactura(AConn, ASerie, ANumero, ADatos);
  if Result then
  begin
    if Length(ADatos.NifEmisor) <> 9 then
      raise Exception.CreateFmt(SErrorNifEmisorVerifactuInvalido,
        [ADatos.NifEmisor]);
    ObtenerCadenaParaEnvio(AConn, AUsuario, ADatos.NifEmisor, ACadena);
    sFhGen := FechaHoraHusoGen(Now);
    sSif   := ConstruirSistemaInformatico(AParametrosApp, AConn, ADatos);
    if ATipoOperacion = 'ANULACION' then
      ARegistro := ConstruirRegistroAnulacion(ADatos, ASerie, ANumero,
                                              ACadena, sSif, sFhGen,
                                              AHuella)
    else
      ARegistro := ConstruirRegistroAlta(AParametrosApp, ADatos,
                                         ASerie, ANumero,
                                         ACadena, sSif, sFhGen,
                                         ATipoOperacion = 'SUBSANACION',
                                         AHuella);
  end;
end;

function GenerarRegistroFacturaLocal(
                                     const AParametrosApp:
                                     IParametrosAplicacion;
                                     AConn: TUniConnection;
                                     const AUsuario: string;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string):
                                     TResultadoEnvioVerifactu;
var
  oDatos:     TDatosFacturaRegistro;
  oCadena:    TCadenaAnterior;
  oDatosCert: TXadesDatosCertificado;
  oB64:       TBase64Encoding;
  sRegistro:  string;
  sHuella:    string;
begin
  InicializarResultadoEnvio(Result);
  if not ConstruirRegistroFactura(AParametrosApp, AConn, AUsuario,
                                  ASerie, ANumero,
                                  ATipoOperacion, oDatos, oCadena,
                                  sRegistro, sHuella) then
    Result.MensajeError := Format(SErrorFacturaRegistroFiscalNoEncontrada,
      [ASerie, ANumero])
  else
  begin
    Result.Ok := True;
    Result.EstadoRegistro := 'REGISTRADO';
    Result.IssuerIrsId := oDatos.NifEmisor;
    Result.IssuedTime := Now;
    Result.FechaExpedicion := oDatos.FechaExpedicion;
    Result.ChainNumber := IntToStr(oCadena.Contador + 1);
    Result.ChainHash := sHuella;
    if VerifactuFirmaCertificado(AParametrosApp) then
    begin
      Result.RegistroXmlFirmado := FirmarRegistroFacturacion(
        sRegistro, ATipoOperacion, sHuella, oDatos.SerialCert,
        oDatos.TitularCert, oDatosCert, Result.FirmaDigital);
      Result.SerieCertificado := oDatosCert.NumeroSerie;
      Result.TitularCertificado := oDatosCert.Titular;
      Result.HuellaCertificado := oDatosCert.HuellaSha1;
    end
    else
    begin
      Result.RegistroXmlFirmado := XmlRegistroFacturacionLocal(
        sRegistro, ATipoOperacion);
      Result.FirmaDigital := sHuella;
    end;
    if ATipoOperacion <> 'ANULACION' then
    begin
      Result.VerifactuUrl := ConstruirUrlQR(AParametrosApp,
                                            oDatos.NifEmisor, ASerie,
                                            ANumero, oDatos.FechaFac,
                                            oDatos.ImporteTotal);
      try
        Result.QRCodePng := GenerarQRPngVerifactu(Result.VerifactuUrl);
        if Length(Result.QRCodePng) > 0 then
        begin
          oB64 := TBase64Encoding.Create(0);
          try
            Result.QRCodeBase64 := oB64.EncodeBytesToString(
                                      Result.QRCodePng);
          finally
            FreeAndNil(oB64);
          end;
        end;
      except
        on E: Exception do
          Result.MensajeError := Format(SAvisoQrPngNoGenerado,
            [E.Message]);
      end;
    end;
  end;
end;

procedure PrepararRegistroFirmado(
  const AParametrosApp: IParametrosAplicacion;
  const ADatos: TDatosFacturaRegistro;
  const ARegistro, ATipoOperacion, AHuella: string;
  var AResultado: TResultadoEnvioVerifactu);
var
  oDatosCert: TXadesDatosCertificado;
begin
  if VerifactuFirmaCertificado(AParametrosApp) then
  begin
    AResultado.RegistroXmlFirmado := FirmarRegistroFacturacion(
      ARegistro, ATipoOperacion, AHuella, ADatos.SerialCert,
      ADatos.TitularCert, oDatosCert, AResultado.FirmaDigital);
    AResultado.SerieCertificado := oDatosCert.NumeroSerie;
    AResultado.TitularCertificado := oDatosCert.Titular;
    AResultado.HuellaCertificado := oDatosCert.HuellaSha1;
  end
  else
  begin
    AResultado.RegistroXmlFirmado := XmlRegistroFacturacionLocal(
      ARegistro, ATipoOperacion);
    AResultado.FirmaDigital := AHuella;
  end;
end;

procedure GenerarQrResultadoEnvio(
  const AParametrosApp: IParametrosAplicacion;
  const ADatos: TDatosFacturaRegistro;
  const ASerie, ANumero: string;
  var AResultado: TResultadoEnvioVerifactu);
var
  oB64: TBase64Encoding;
begin
  AResultado.VerifactuUrl := ConstruirUrlQR(AParametrosApp,
    ADatos.NifEmisor, ASerie, ANumero, ADatos.FechaFac,
    ADatos.ImporteTotal);
  try
    AResultado.QRCodePng := GenerarQRPngVerifactu(
      AResultado.VerifactuUrl);
    if Length(AResultado.QRCodePng) > 0 then
    begin
      oB64 := TBase64Encoding.Create(0);
      try
        AResultado.QRCodeBase64 := oB64.EncodeBytesToString(
          AResultado.QRCodePng);
      finally
        FreeAndNil(oB64);
      end;
    end;
  except
    on E: Exception do
      AResultado.MensajeError := Format(SAvisoQrPngNoGenerado,
        [E.Message]);
  end;
end;

procedure CompletarResultadoAceptado(
  const AParametrosApp: IParametrosAplicacion;
  const ADatos: TDatosFacturaRegistro;
  const ACadena: TCadenaAnterior;
  const ASerie, ANumero, ATipoOperacion, AHuella: string;
  const ARespuesta: TInterpretacionRespuestaAeat;
  var AResultado: TResultadoEnvioVerifactu);
begin
  AResultado.Ok := True;
  if ARespuesta.Duplicado then
    AResultado.EstadoRegistro := 'Duplicado'
  else
    AResultado.EstadoRegistro := ARespuesta.EstadoRegistro;
  AResultado.RequestId := ARespuesta.Csv;
  AResultado.IssuerIrsId := ADatos.NifEmisor;
  AResultado.IssuedTime := Now;
  AResultado.FechaExpedicion := ADatos.FechaExpedicion;
  AResultado.ChainNumber := IntToStr(ACadena.Contador + 1);
  AResultado.ChainHash := AHuella;
  if ATipoOperacion <> 'ANULACION' then
    GenerarQrResultadoEnvio(AParametrosApp, ADatos, ASerie, ANumero,
                            AResultado);
  if ARespuesta.Duplicado or
     SameText(ARespuesta.EstadoRegistro, 'AceptadoConErrores') then
    AResultado.MensajeError := Trim(AResultado.MensajeError +
      Format(SErrorRespuestaRegistroAeat,
        [ARespuesta.CodigoError, ARespuesta.DescripcionError]));
end;

procedure AplicarRespuestaAeat(
  const AParametrosApp: IParametrosAplicacion;
  const ADatos: TDatosFacturaRegistro;
  const ACadena: TCadenaAnterior;
  const ASerie, ANumero, ATipoOperacion, AHuella: string;
  AEstadoHttp: Integer;
  const ACuerpo: string;
  var AResultado: TResultadoEnvioVerifactu);
var
  oRespuesta: TInterpretacionRespuestaAeat;
  sDescripcion: string;
begin
  oRespuesta := InterpretarRespuestaAeat(AEstadoHttp, ACuerpo);
  if not oRespuesta.EsHttpCorrecto then
  begin
    sDescripcion := oRespuesta.DescripcionError;
    if sDescripcion = '' then
      sDescripcion := SErrorRespuestaServicioInesperada;
    AResultado.MensajeError := Format(SErrorRespuestaHttpAeat,
      [AEstadoHttp, sDescripcion]);
  end
  else
  begin
    AResultado.CodigoError := oRespuesta.CodigoError;
    AResultado.DescripcionError := oRespuesta.DescripcionError;
    AResultado.EsperaSegundos := oRespuesta.EsperaSegundos;
    if oRespuesta.Aceptado then
      CompletarResultadoAceptado(AParametrosApp, ADatos, ACadena,
        ASerie, ANumero, ATipoOperacion, AHuella, oRespuesta, AResultado)
    else
    begin
      sDescripcion := oRespuesta.DescripcionError;
      if (oRespuesta.CodigoError = '') and (sDescripcion = '') then
        sDescripcion := Format(SErrorEstadoEnvioAeat,
          [oRespuesta.EstadoEnvio]);
      AResultado.MensajeError := Trim(Format(SErrorRespuestaRegistroAeat,
        [oRespuesta.CodigoError, sDescripcion]));
    end;
  end;
end;

function EnviarRegistroFactura(
                               const AParametrosApp: IParametrosAplicacion;
                               AConn: TUniConnection;
                               const AUsuario: string;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;
var
  oDatos: TDatosFacturaRegistro;
  oCadena: TCadenaAnterior;
  sHuella: string;
  sRegistro: string;
  iEstadoHttp: Integer;
  sCuerpo: string;
begin
  InicializarResultadoEnvio(Result);
  if ConstruirRegistroFactura(AParametrosApp, AConn, AUsuario,
      ASerie, ANumero, ATipoOperacion, oDatos, oCadena,
      sRegistro, sHuella) then
  begin
    PrepararRegistroFirmado(AParametrosApp, oDatos, sRegistro,
                            ATipoOperacion, sHuella, Result);
    Result.PeticionCompleta := EnvolverSoap(oDatos, sRegistro);
    EnviarHttp(UrlEnvio(AParametrosApp), Result.PeticionCompleta,
      oDatos.SerialCert, oDatos.TitularCert, iEstadoHttp, sCuerpo);
    Result.RespuestaCompleta := sCuerpo;
    AplicarRespuestaAeat(AParametrosApp, oDatos, oCadena,
      ASerie, ANumero, ATipoOperacion, sHuella, iEstadoHttp,
      sCuerpo, Result);
  end
  else
    Result.MensajeError := Format(SErrorFacturaEnvioVerifactuNoEncontrada,
      [ASerie, ANumero]);
end;

end.
