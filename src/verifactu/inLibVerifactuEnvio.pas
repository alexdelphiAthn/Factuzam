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
  System.SysUtils, Uni;

type
  // Resultado del envío de un registro de facturación. Los campos calcan
  // las columnas de fza_facturas_consolidaciones para que el worker de la
  // cola persista la respuesta del servicio sin transformaciones.
  TResultadoEnvioVerifactu = record
    Ok:                Boolean;
    MensajeError:      string;
    EstadoRegistro:    string;    // Correcto / AceptadoConErrores
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
function EnviarRegistroFactura(AConn: TUniConnection;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;

// Genera el registro oficial de facturación en local y lo firma XAdES,
// sin llamar al servicio AEAT. El llamador persiste el resultado y avanza
// la cadena si procede (NO VERI*FACTU).
function GenerarRegistroFacturaLocal(AConn: TUniConnection;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string):
                                     TResultadoEnvioVerifactu;

implementation

uses
  System.Classes, System.StrUtils, System.Hash, System.DateUtils,
  System.TimeSpan, System.NetEncoding, System.Net.HttpClient,
  System.Net.URLClient, Data.DB,
  inLibGlobalVar, inLibAppParam, inLibVerifactu, inLibXades;

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
    NifEmisor:       string;
    NombreEmisor:    string;
    FechaFac:        TDateTime;
    FechaExpedicion: string;  // dd-mm-yyyy
    TipoFactura:     string;  // F1 / F2 / R1 / R5
    NifCliente:      string;
    NombreCliente:   string;
    // Factura original rectificada (solo en R1/R5)
    RectSerie:       string;
    RectNumero:      string;
    RectFecha:       string;  // dd-mm-yyyy
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

// Extrae el contenido de la primera etiqueta con ese nombre local,
// tolerando cualquier prefijo de namespace en la respuesta de la AEAT
function ExtraerEtiqueta(const AXml, AEtiqueta: string): string;
var
  iIni, iFin: Integer;
  sApertura:  string;
begin
  Result := '';
  sApertura := AEtiqueta + '>';
  iIni := Pos('<' + sApertura, AXml);
  if iIni > 0 then
    iIni := iIni + Length(sApertura) + 1
  else
  begin
    iIni := Pos(':' + sApertura, AXml);
    if iIni > 0 then
      iIni := iIni + Length(sApertura) + 1;
  end;
  if iIni > 0 then
  begin
    iFin := PosEx('<', AXml, iIni);
    if iFin > iIni then
      Result := Trim(Copy(AXml, iIni, iFin - iIni));
  end;
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
    Qry.SQL.Text :=
      ' SELECT f.NIF_EMPRESA_FAC, f.RAZON_SOCIAL_EMPRESA_FAC, ' +
      '        f.FECHA_FAC, f.TIPO_FAC, f.NIF_CLIENTE_FAC, ' +
      '        f.RAZON_SOCIAL_CLIENTE_FAC, ' +
      '        f.TOTAL_IMPUESTOS_FAC, f.TOTAL_LIQUIDO_FAC, ' +
      '        f.TOTAL_RETENCION_FAC, ' +
      '        f.PORCENTAJE_IVAN_FAC, f.TOTAL_BASEI_IVAN_FAC, ' +
      '        f.TOTAL_IVAN_FAC, f.PORCENTAJE_REN_FAC, f.TOTAL_REN_FAC, ' +
      '        f.PORCENTAJE_IVAR_FAC, f.TOTAL_BASEI_IVAR_FAC, ' +
      '        f.TOTAL_IVAR_FAC, f.PORCENTAJE_RER_FAC, f.TOTAL_RER_FAC, ' +
      '        f.PORCENTAJE_IVAS_FAC, f.TOTAL_BASEI_IVAS_FAC, ' +
      '        f.TOTAL_IVAS_FAC, f.PORCENTAJE_RES_FAC, f.TOTAL_RES_FAC, ' +
      '        f.PORCENTAJE_IVAE_FAC, f.TOTAL_BASEI_IVAE_FAC, ' +
      '        f.TOTAL_IVAE_FAC, ' +
      '        f.TIPO_OPER_VFACTU_FAC, f.CODIGO_PAI_CLIENTE_FAC, ' +
      '        pc.COD_ALPHA2_PAI, pc.ESMIEMBRO_UE_PAI, ' +
      '        vo.CLAVE_REGIMEN_VFO, vo.CALIFICACION_VFO, ' +
      '        vo.OPERACION_EXENTA_VFO, vo.ESREPERCUTE_IVA_VFO, ' +
      '        e.CODIGO_CERTIFICADO_EMP, e.TITULAR_CERTIFICADO_EMP ' +
      ' FROM fza_facturas f ' +
      ' LEFT JOIN fza_empresas e ' +
      '        ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
      ' LEFT JOIN fza_paises pc ' +
      '        ON pc.CODIGO_PAI_PAI = f.CODIGO_PAI_CLIENTE_FAC ' +
      ' LEFT JOIN fza_verifactu_operaciones vo ' +
      '        ON vo.CODIGO_VFO = f.TIPO_OPER_VFACTU_FAC ' +
      ' WHERE f.SERIE_FAC  = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO';
    Qry.ParamByName('SERIE').AsString  := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    // Si la fila de la cola no apunta a una factura real (huérfana,
    // p.ej. 0\0) se devuelve False sin lanzar excepción: el llamador
    // lo deja solo en el log de Verifactu como error de envío y no
    // salta el diálogo de excepción por pantalla.
    Result := not Qry.IsEmpty;
    if Result then
    begin
      ADatos.NifEmisor :=
        NormalizarNifVerifactu(Qry.FieldByName('NIF_EMPRESA_FAC').AsString);
      ADatos.NombreEmisor :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString);
      ADatos.FechaFac        := Qry.FieldByName('FECHA_FAC').AsDateTime;
      ADatos.FechaExpedicion :=
        FormatDateTime('dd-mm-yyyy', ADatos.FechaFac);
      sTipoFac := Qry.FieldByName('TIPO_FAC').AsString;
      ADatos.TipoFactura := TipoFacturaVerifactu(sTipoFac);
      ADatos.RectSerie   := '';
      ADatos.RectNumero  := '';
      ADatos.RectFecha   := '';
      ADatos.NifCliente :=
        NormalizarNifVerifactu(Qry.FieldByName('NIF_CLIENTE_FAC').AsString);
      ADatos.NombreCliente :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
      ADatos.CuotaTotal   :=
        Qry.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
      // ImporteTotal Verifactu = importe BRUTO (base + IVA + recargo), sin
      // descontar el IRPF. Verifactu solo informa a efectos de IVA: la
      // retencion no se comunica ni resta del total (a diferencia del
      // liquido a pagar). Reconstruimos el bruto sumando la retencion al
      // liquido (TOTAL_LIQUIDO_FAC = bases + impuestos - retencion). Asi el
      // total cuadra con la suma del desglose que valida la AEAT.
      ADatos.ImporteTotal :=
        Qry.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency +
        Qry.FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
      ADatos.SerialCert :=
        Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      ADatos.TitularCert :=
        Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
      // Calificacion de la operacion (catalogo) y residencia fiscal del
      // cliente. El cliente es extranjero si su pais no es Espana (724 / ES);
      // en ese caso se identifica por IDOtro (pais + NIF-IVA), no por NIF.
      // OpDefinida = hay tipo asignado y existe en el catalogo (clave regimen
      // no nula tras el LEFT JOIN).
      ADatos.OpDefinida :=
        (Trim(Qry.FieldByName('TIPO_OPER_VFACTU_FAC').AsString) <> '') and
        (not Qry.FieldByName('CLAVE_REGIMEN_VFO').IsNull);
      ADatos.OpClaveRegimen :=
        Trim(Qry.FieldByName('CLAVE_REGIMEN_VFO').AsString);
      ADatos.OpCalificacion :=
        Trim(Qry.FieldByName('CALIFICACION_VFO').AsString);
      ADatos.OpOperExenta :=
        Trim(Qry.FieldByName('OPERACION_EXENTA_VFO').AsString);
      ADatos.OpRepercuteIva :=
        not SameText(Trim(Qry.FieldByName('ESREPERCUTE_IVA_VFO').AsString), 'N');
      ADatos.PaisClienteISO2 :=
        Trim(Qry.FieldByName('COD_ALPHA2_PAI').AsString);
      ADatos.EsClienteUE :=
        SameText(Trim(Qry.FieldByName('ESMIEMBRO_UE_PAI').AsString), 'S');
      ADatos.EsClienteExtr :=
        (ADatos.PaisClienteISO2 <> '') and
        (not SameText(ADatos.PaisClienteISO2, 'ES')) and
        (Trim(Qry.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString) <> '724');
      // Banda N (normal)
      ADatos.Bandas[0].Porcentaje :=
        Qry.FieldByName('PORCENTAJE_IVAN_FAC').AsCurrency;
      ADatos.Bandas[0].Base :=
        Qry.FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
      ADatos.Bandas[0].Cuota := Qry.FieldByName('TOTAL_IVAN_FAC').AsCurrency;
      ADatos.Bandas[0].PorcentajeRe :=
        Qry.FieldByName('PORCENTAJE_REN_FAC').AsCurrency;
      ADatos.Bandas[0].CuotaRe := Qry.FieldByName('TOTAL_REN_FAC').AsCurrency;
      ADatos.Bandas[0].EsExenta := False;
      // Banda R (reducido)
      ADatos.Bandas[1].Porcentaje :=
        Qry.FieldByName('PORCENTAJE_IVAR_FAC').AsCurrency;
      ADatos.Bandas[1].Base :=
        Qry.FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
      ADatos.Bandas[1].Cuota := Qry.FieldByName('TOTAL_IVAR_FAC').AsCurrency;
      ADatos.Bandas[1].PorcentajeRe :=
        Qry.FieldByName('PORCENTAJE_RER_FAC').AsCurrency;
      ADatos.Bandas[1].CuotaRe := Qry.FieldByName('TOTAL_RER_FAC').AsCurrency;
      ADatos.Bandas[1].EsExenta := False;
      // Banda S (superreducido)
      ADatos.Bandas[2].Porcentaje :=
        Qry.FieldByName('PORCENTAJE_IVAS_FAC').AsCurrency;
      ADatos.Bandas[2].Base :=
        Qry.FieldByName('TOTAL_BASEI_IVAS_FAC').AsCurrency;
      ADatos.Bandas[2].Cuota := Qry.FieldByName('TOTAL_IVAS_FAC').AsCurrency;
      ADatos.Bandas[2].PorcentajeRe :=
        Qry.FieldByName('PORCENTAJE_RES_FAC').AsCurrency;
      ADatos.Bandas[2].CuotaRe := Qry.FieldByName('TOTAL_RES_FAC').AsCurrency;
      ADatos.Bandas[2].EsExenta := False;
      // Banda E (exento)
      ADatos.Bandas[3].Porcentaje :=
        Qry.FieldByName('PORCENTAJE_IVAE_FAC').AsCurrency;
      ADatos.Bandas[3].Base :=
        Qry.FieldByName('TOTAL_BASEI_IVAE_FAC').AsCurrency;
      ADatos.Bandas[3].Cuota := Qry.FieldByName('TOTAL_IVAE_FAC').AsCurrency;
      ADatos.Bandas[3].PorcentajeRe := 0;
      ADatos.Bandas[3].CuotaRe      := 0;
      ADatos.Bandas[3].EsExenta     := True;
      // Antecesora (la original de una rectificativa o el ticket
      // sustituido por una F3): primero por el histórico de relaciones
      // (fza_facturas_relaciones, soporta varias rectificaciones de la
      // misma factura) y, si no hay fila, por el enlace ABONO inverso.
      // Decide R1/R5/F3 y aporta FacturasRectificadas / Sustituidas.
      if SameText(sTipoFac, 'RECTIFICATIVA') or
         SameText(sTipoFac, 'NORMAL') then
      begin
        Qry.Close;
        Qry.SQL.Text :=
          ' SELECT o.SERIE_FAC, o.NUMERO_FAC, o.TIPO_FAC, ' +
          '        DATE_FORMAT(o.FECHA_FAC, ''%d-%m-%Y'') AS FECHA_TXT ' +
          ' FROM fza_facturas_relaciones r ' +
          ' JOIN fza_facturas o ' +
          '   ON o.SERIE_FAC  = r.SERIE_FAC_ORIGEN_FACREL ' +
          '  AND o.NUMERO_FAC = r.NUMERO_FAC_ORIGEN_FACREL ' +
          ' WHERE r.SERIE_FAC_FACREL  = :SERIE ' +
          '   AND r.NUMERO_FAC_FACREL = :NUMERO ' +
          ' ORDER BY r.ID_FACREL DESC ' +
          ' LIMIT 1';
        Qry.ParamByName('SERIE').AsString  := ASerie;
        Qry.ParamByName('NUMERO').AsString := ANumero;
        Qry.Open;
        if Qry.IsEmpty then
        begin
          Qry.Close;
          Qry.SQL.Text :=
            ' SELECT SERIE_FAC, NUMERO_FAC, TIPO_FAC, ' +
            '        DATE_FORMAT(FECHA_FAC, ''%d-%m-%Y'') AS FECHA_TXT ' +
            ' FROM fza_facturas ' +
            ' WHERE SERIE_FAC_ABONO_FAC  = :SERIE ' +
            '   AND NUMERO_FAC_ABONO_FAC = :NUMERO ' +
            ' LIMIT 1';
          Qry.ParamByName('SERIE').AsString  := ASerie;
          Qry.ParamByName('NUMERO').AsString := ANumero;
          Qry.Open;
        end;
        if not Qry.IsEmpty then
        begin
          if SameText(sTipoFac, 'RECTIFICATIVA') then
          begin
            if SameText(Qry.FieldByName('TIPO_FAC').AsString,
                        'SIMPLIFICADA') then
              ADatos.TipoFactura := 'R5'
            else
              ADatos.TipoFactura := 'R1';
            ADatos.RectSerie  := Qry.FieldByName('SERIE_FAC').AsString;
            ADatos.RectNumero := Qry.FieldByName('NUMERO_FAC').AsString;
            ADatos.RectFecha  := Qry.FieldByName('FECHA_TXT').AsString;
          end
          else if SameText(Qry.FieldByName('TIPO_FAC').AsString,
                           'SIMPLIFICADA') then
          begin
            // Factura completa emitida en sustitución de un ticket
            ADatos.TipoFactura := 'F3';
            ADatos.RectSerie  := Qry.FieldByName('SERIE_FAC').AsString;
            ADatos.RectNumero := Qry.FieldByName('NUMERO_FAC').AsString;
            ADatos.RectFecha  := Qry.FieldByName('FECHA_TXT').AsString;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

// Asegura la fila de cadena del emisor y la bloquea (FOR UPDATE) dentro
// de la transacción del llamador: nadie más encadena hasta el commit
procedure ObtenerCadenaParaEnvio(AConn: TUniConnection;
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
    Qry.ParamByName('USUARIO').AsString := oUser;
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

function ConstruirSistemaInformatico(AConn: TUniConnection): string;
var
  Qry:          TUniQuery;
  sMultiOT:     string;
  sNombre:      string;
  sNif:         string;
  sInstalacion: string;
begin
  sNombre := oAppParams.GetString('appVerifactuSifNombreRazon',
                                  'Alejandro Laorden Hidalgo');
  // La AEAT responde un 1100 genérico ('NIF') si el NIF del productor
  // va vacío o mal formado: se valida aquí con un mensaje claro
  sNif := NormalizarNifVerifactu(
            oAppParams.GetString('appVerifactuSifNif', ''));
  if Length(sNif) <> 9 then
    raise Exception.Create('Parámetro appVerifactuSifNif (NIF del ' +
      'productor del software) vacío o no válido: "' + sNif + '". ' +
      'Rellenarlo en Parámetros de aplicación, categoría Verifactu.');
  sInstalacion := oAppParams.GetString('appVerifactuIdInstalacion', '1');
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
    '<sum1:TipoUsoPosibleSoloVerifactu>S' +
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

function ConstruirRegistroAlta(const ADatos: TDatosFacturaRegistro;
                               const ASerie, ANumero: string;
                               const ACadena: TCadenaAnterior;
                               const ASif, AFhGen: string;
                               ASubsanacion: Boolean;
                               out AHuella: string): string;
var
  sNumSerie:      string;
  sCuota:         string;
  sImporte:       string;
  sSubsanacion:   string;
  sRectificativa: string;
  sRectificadas:  string;
  sSustituidas:   string;
  sDestinatarios: string;
  sDescripcion:   string;
  sIdType:        string;
begin
  sNumSerie := ComponerNumSerieFactura(ASerie, ANumero);
  sCuota    := FormatearImporteVerifactu(ADatos.CuotaTotal);
  sImporte  := FormatearImporteVerifactu(ADatos.ImporteTotal);
  sDescripcion := oAppParams.GetString('appVerifactuDescripcionOpe',
                                       'Venta');
  // Huella del registro de alta según la especificación técnica de la
  // AEAT (TipoHuella 01 = SHA-256, hexadecimal en mayúsculas)
  AHuella := UpperCase(THashSHA2.GetHashString(
    'IDEmisorFactura=' + ADatos.NifEmisor +
    '&NumSerieFactura=' + sNumSerie +
    '&FechaExpedicionFactura=' + ADatos.FechaExpedicion +
    '&TipoFactura=' + ADatos.TipoFactura +
    '&CuotaTotal=' + sCuota +
    '&ImporteTotal=' + sImporte +
    '&Huella=' + ACadena.Huella +
    '&FechaHoraHusoGenRegistro=' + AFhGen));
  // Subsanación: reenvío de un registro ya remitido para corregirlo
  if ASubsanacion then
    sSubsanacion := '<sum1:Subsanacion>S</sum1:Subsanacion>'
  else
    sSubsanacion := '';
  if Copy(ADatos.TipoFactura, 1, 1) = 'R' then
    sRectificativa :=
      '<sum1:TipoRectificativa>I</sum1:TipoRectificativa>'
  else
    sRectificativa := '';
  // Referencia a la factura original rectificada (si se conoce)
  if (Copy(ADatos.TipoFactura, 1, 1) = 'R') and
     (ADatos.RectNumero <> '') then
    sRectificadas := '<sum1:FacturasRectificadas>' +
      '<sum1:IDFacturaRectificada>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(ADatos.NifEmisor) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(ComponerNumSerieFactura(ADatos.RectSerie,
                                         ADatos.RectNumero)) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + ADatos.RectFecha +
      '</sum1:FechaExpedicionFactura>' +
      '</sum1:IDFacturaRectificada></sum1:FacturasRectificadas>'
  else
    sRectificadas := '';
  // Referencia al ticket sustituido (factura F3)
  if (ADatos.TipoFactura = 'F3') and (ADatos.RectNumero <> '') then
    sSustituidas := '<sum1:FacturasSustituidas>' +
      '<sum1:IDFacturaSustituida>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(ADatos.NifEmisor) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(ComponerNumSerieFactura(ADatos.RectSerie,
                                         ADatos.RectNumero)) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + ADatos.RectFecha +
      '</sum1:FechaExpedicionFactura>' +
      '</sum1:IDFacturaSustituida></sum1:FacturasSustituidas>'
  else
    sSustituidas := '';
  // Las completas (F1, F3) y las rectificativas de completas (R1)
  // exigen identificar al destinatario
  if MatchText(ADatos.TipoFactura, ['F1', 'R1', 'F3']) then
  begin
    if ADatos.EsClienteExtr then
    begin
      // Destinatario extranjero: se identifica por IDOtro (pais + NIF-IVA),
      // no por NIF espanol. IDType 02 = NIF-IVA (operador UE); 04 = documento
      // oficial expedido por el pais de residencia (resto del mundo). No se
      // exige el NIF de 9 caracteres, pero si que haya identificacion.
      if Trim(ADatos.NifCliente) = '' then
        raise Exception.Create('La factura ' + ADatos.TipoFactura + ' ' +
          ASerie + '\' + ANumero + ' a cliente extranjero requiere el ' +
          'NIF-IVA del destinatario.');
      if ADatos.EsClienteUE then
        sIdType := '02'
      else
        sIdType := '04';
      sDestinatarios := '<sum1:Destinatarios><sum1:IDDestinatario>' +
        '<sum1:NombreRazon>' + EscaparXml(ADatos.NombreCliente) +
        '</sum1:NombreRazon>' +
        '<sum1:IDOtro>' +
        '<sum1:CodigoPais>' + EscaparXml(ADatos.PaisClienteISO2) +
        '</sum1:CodigoPais>' +
        '<sum1:IDType>' + sIdType + '</sum1:IDType>' +
        '<sum1:ID>' + EscaparXml(ADatos.NifCliente) + '</sum1:ID>' +
        '</sum1:IDOtro>' +
        '</sum1:IDDestinatario></sum1:Destinatarios>';
    end
    else
    begin
      if Length(ADatos.NifCliente) <> 9 then
        raise Exception.Create('La factura ' + ADatos.TipoFactura + ' ' +
          ASerie + '\' + ANumero + ' requiere un NIF de cliente válido y ' +
          'tiene "' + ADatos.NifCliente + '"');
      sDestinatarios := '<sum1:Destinatarios><sum1:IDDestinatario>' +
        '<sum1:NombreRazon>' + EscaparXml(ADatos.NombreCliente) +
        '</sum1:NombreRazon>' +
        '<sum1:NIF>' + EscaparXml(ADatos.NifCliente) + '</sum1:NIF>' +
        '</sum1:IDDestinatario></sum1:Destinatarios>';
    end;
  end
  else
    sDestinatarios := '';
  Result :=
    '<sum1:RegistroAlta>' +
    '<sum1:IDVersion>1.0</sum1:IDVersion>' +
    '<sum1:IDFactura>' +
    '<sum1:IDEmisorFactura>' + EscaparXml(ADatos.NifEmisor) +
    '</sum1:IDEmisorFactura>' +
    '<sum1:NumSerieFactura>' + EscaparXml(sNumSerie) +
    '</sum1:NumSerieFactura>' +
    '<sum1:FechaExpedicionFactura>' + ADatos.FechaExpedicion +
    '</sum1:FechaExpedicionFactura>' +
    '</sum1:IDFactura>' +
    '<sum1:NombreRazonEmisor>' + EscaparXml(ADatos.NombreEmisor) +
    '</sum1:NombreRazonEmisor>' +
    sSubsanacion +
    '<sum1:TipoFactura>' + ADatos.TipoFactura + '</sum1:TipoFactura>' +
    sRectificativa +
    sRectificadas +
    sSustituidas +
    '<sum1:DescripcionOperacion>' + EscaparXml(sDescripcion) +
    '</sum1:DescripcionOperacion>' +
    sDestinatarios +
    '<sum1:Desglose>' + ConstruirDesglose(ADatos) + '</sum1:Desglose>' +
    '<sum1:CuotaTotal>' + sCuota + '</sum1:CuotaTotal>' +
    '<sum1:ImporteTotal>' + sImporte + '</sum1:ImporteTotal>' +
    ConstruirEncadenamiento(ADatos.NifEmisor, ACadena) +
    ASif +
    '<sum1:FechaHoraHusoGenRegistro>' + AFhGen +
    '</sum1:FechaHoraHusoGenRegistro>' +
    '<sum1:TipoHuella>01</sum1:TipoHuella>' +
    '<sum1:Huella>' + AHuella + '</sum1:Huella>' +
    '</sum1:RegistroAlta>';
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
  oOpciones := OpcionesXadesBase('FZ-FACTURA-' + AHuella);
  oOpciones.UriDocumentoVacia := True;
  oOpciones.IdNodoFirmado := '';
  oOpciones.FirmaSilenciosa := False;
  Result := FirmarXmlXadesEnveloped(sXml, ASerial, ATitular, oOpciones,
                                    ADatosCert);
  AFirmaDigital := ExtraerEtiquetaXmlLocal(Result, 'ds:SignatureValue');
end;

// ===========================================================================
//   Transporte HTTP con certificado de cliente
// ===========================================================================

function UrlEnvio: string;
begin
  if VerifactuEntorno = 'PRO' then
    Result := oAppParams.GetString('appVerifactuUrlEnvioPro',
                                   cVerifactuUrlEnvioPro)
  else
    Result := oAppParams.GetString('appVerifactuUrlEnvioPre',
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

function ConstruirRegistroFactura(AConn: TUniConnection;
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
      raise Exception.Create('NIF de la empresa emisora vacío o no ' +
        'válido para Verifactu: "' + ADatos.NifEmisor + '". Revisar la ' +
        'ficha de la empresa (NIF de 9 caracteres, sin guiones).');
    ObtenerCadenaParaEnvio(AConn, ADatos.NifEmisor, ACadena);
    sFhGen := FechaHoraHusoGen(Now);
    sSif   := ConstruirSistemaInformatico(AConn);
    if ATipoOperacion = 'ANULACION' then
      ARegistro := ConstruirRegistroAnulacion(ADatos, ASerie, ANumero,
                                              ACadena, sSif, sFhGen,
                                              AHuella)
    else
      ARegistro := ConstruirRegistroAlta(ADatos, ASerie, ANumero,
                                         ACadena, sSif, sFhGen,
                                         ATipoOperacion = 'SUBSANACION',
                                         AHuella);
  end;
end;

function GenerarRegistroFacturaLocal(AConn: TUniConnection;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string):
                                     TResultadoEnvioVerifactu;
var
  oDatos:     TDatosFacturaRegistro;
  oCadena:    TCadenaAnterior;
  oDatosCert: TXadesDatosCertificado;
  sRegistro:  string;
  sHuella:    string;
begin
  InicializarResultadoEnvio(Result);
  if not ConstruirRegistroFactura(AConn, ASerie, ANumero, ATipoOperacion,
                                  oDatos, oCadena, sRegistro, sHuella) then
    Result.MensajeError := 'Factura ' + ASerie + '\' + ANumero +
                           ' no encontrada para el registro fiscal'
  else
  begin
    Result.Ok := True;
    Result.EstadoRegistro := 'REGISTRADO';
    Result.IssuerIrsId := oDatos.NifEmisor;
    Result.IssuedTime := Now;
    Result.FechaExpedicion := oDatos.FechaExpedicion;
    Result.ChainNumber := IntToStr(oCadena.Contador + 1);
    Result.ChainHash := sHuella;
    if VerifactuFirmaCertificado then
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
  end;
end;

function EnviarRegistroFactura(AConn: TUniConnection;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;
var
  oDatos:          TDatosFacturaRegistro;
  oCadena:         TCadenaAnterior;
  oDatosCert:      TXadesDatosCertificado;
  oB64:            TBase64Encoding;
  sHuella:         string;
  sRegistro:       string;
  iStatus:         Integer;
  sCuerpo:         string;
  sEstadoEnvio:    string;
  sEstadoRegistro: string;
  sCodigoErr:      string;
  sDescErr:        string;
  bDuplicado:      Boolean;
  bAceptado:       Boolean;
begin
  InicializarResultadoEnvio(Result);
  if not ConstruirRegistroFactura(AConn, ASerie, ANumero, ATipoOperacion,
                                  oDatos, oCadena, sRegistro, sHuella) then
    // Fila de la cola sin factura real (huérfana, p.ej. 0\0): no se
    // lanza excepción; se devuelve el error para que la cola lo deje
    // únicamente en el log de Verifactu (RegistrarEventoVerifactu).
    Result.MensajeError := 'Factura ' + ASerie + '\' + ANumero +
                           ' no encontrada para el envío Verifactu'
  else
  begin
    if VerifactuFirmaCertificado then
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
    Result.PeticionCompleta := EnvolverSoap(oDatos, sRegistro);
    EnviarHttp(UrlEnvio, Result.PeticionCompleta,
               oDatos.SerialCert, oDatos.TitularCert, iStatus, sCuerpo);
    Result.RespuestaCompleta := sCuerpo;
    if iStatus <> 200 then
    begin
      sDescErr := ExtraerEtiqueta(sCuerpo, 'faultstring');
      if sDescErr = '' then
        sDescErr := 'Respuesta inesperada del servicio';
      Result.MensajeError := 'AEAT HTTP ' + IntToStr(iStatus) + ': ' +
                             sDescErr;
    end
    else
    begin
      sEstadoEnvio    := ExtraerEtiqueta(sCuerpo, 'EstadoEnvio');
      sEstadoRegistro := ExtraerEtiqueta(sCuerpo, 'EstadoRegistro');
      sCodigoErr      := ExtraerEtiqueta(sCuerpo, 'CodigoErrorRegistro');
      sDescErr        := ExtraerEtiqueta(sCuerpo, 'DescripcionErrorRegistro');
      Result.EsperaSegundos :=
        StrToIntDef(ExtraerEtiqueta(sCuerpo, 'TiempoEsperaEnvio'), 0);
      // Si no viene línea de respuesta, manda el estado global del envío
      if sEstadoRegistro = '' then
        sEstadoRegistro := sEstadoEnvio;
      // Registro duplicado: la AEAT ya lo tiene registrado (p.ej. un
      // reintento tras aceptar y fallar la persistencia local). Se da
      // por aceptado para consolidar y cerrar la fila de la cola.
      bDuplicado := (sCodigoErr = '3000') or
                    ContainsText(sDescErr, 'duplicado');
      bAceptado := SameText(sEstadoEnvio, 'Correcto') or
                   SameText(sEstadoRegistro, 'Correcto') or
                   SameText(sEstadoRegistro, 'AceptadoConErrores') or
                   bDuplicado;
      if bAceptado then
      begin
        Result.Ok := True;
        if bDuplicado then
          Result.EstadoRegistro := 'Duplicado'
        else
          Result.EstadoRegistro := sEstadoRegistro;
        Result.RequestId       := ExtraerEtiqueta(sCuerpo, 'CSV');
        Result.IssuerIrsId     := oDatos.NifEmisor;
        Result.IssuedTime      := Now;
        Result.FechaExpedicion := oDatos.FechaExpedicion;
        Result.ChainNumber     := IntToStr(oCadena.Contador + 1);
        Result.ChainHash       := sHuella;
        if ATipoOperacion <> 'ANULACION' then
        begin
          Result.VerifactuUrl := ConstruirUrlQR(oDatos.NifEmisor, ASerie,
                                                ANumero, oDatos.FechaFac,
                                                oDatos.ImporteTotal);
          // QR de la consolidación (PNG y base64). Si fallara, no tumba
          // el envío: queda constancia en el mensaje informativo.
          try
            Result.QRCodePng := GenerarQRPngVerifactu(Result.VerifactuUrl);
            if Length(Result.QRCodePng) > 0 then
            begin
              oB64 := TBase64Encoding.Create(0);
              try
                Result.QRCodeBase64 :=
                  oB64.EncodeBytesToString(Result.QRCodePng);
              finally
                FreeAndNil(oB64);
              end;
            end;
          except
            on E: Exception do
              Result.MensajeError := '(QR PNG no generado: ' +
                                     E.Message + ') ';
          end;
        end;
        if bDuplicado or
           SameText(sEstadoRegistro, 'AceptadoConErrores') then
          Result.MensajeError := Trim(Result.MensajeError + 'AEAT [' +
                                      sCodigoErr + '] ' + sDescErr);
      end
      else
      begin
        if (sCodigoErr = '') and (sDescErr = '') then
          sDescErr := 'EstadoEnvio: ' + sEstadoEnvio;
        Result.MensajeError := Trim('AEAT [' + sCodigoErr + '] ' + sDescErr);
      end;
    end;
  end;
end;

end.
