unit inLibCertificates;

interface

uses

System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, System.Types,
  Winapi.Windows, system.StrUtils, Winapi.Messages, cxListView;

const
  COLUMNA_CER_NROSERIE = 4;
  COLUMNA_CER_FECHAHASTA = 3;
  COLUMNA_CER_EMISOR = 2;
  COLUMNA_CER_NOMBRE = 1;
  COLUMNA_CER_TITULAR = 0;
  CRYPT32 = 'crypt32.dll';
  // Constantes necesarias
  X509_ASN_ENCODING = $00000001;
  PKCS_7_ASN_ENCODING = $00010000;
  szOID_ENHANCED_KEY_USAGE = '2.5.29.37';
  CERT_FIND_PROP_ONLY_ENHKEY_USAGE_FLAG = 1;
  CERT_FIND_EXT_ONLY_ENHKEY_USAGE_FLAG = 2;
  CERT_FIND_NO_ENHKEY_USAGE_FLAG = 4;
  CERT_FIND_OR_ENHKEY_USAGE_FLAG = 8;
  CERT_FIND_VALID_ENHKEY_USAGE_FLAG = $20;
  CERT_STORE_PROV_SYSTEM = 10;
  CERT_X500_NAME_STR = 3;
  CERT_NAME_STR_NO_QUOTING_FLAG = $10;
  CERT_SIMPLE_NAME_STR = 1;
  CERT_NAME_STR_SEMICOLON_FLAG = 1;
  CERT_OID_NAME_STR = 2;
  CERT_NAME_STR_CRLF_FLAG = 2;
  CERT_NAME_STR_NO_PLUS_FLAG = 32;
  CERT_NAME_STR_REVERSE_FLAG = 4;
  CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG = 65536;
  CERT_NAME_STR_ENABLE_PUNYCODE_FLAG = 131072;
  CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG = 262144;
    // OIDs de políticas para certificados de e-factura
  CRYPT_DECODE_ALLOC_FLAG = $8000;
  CRYPT_DECODE_NOCOPY_FLAG = $1;
  function CertNameToStrA(dwCertEncodingType: DWORD;
                          pName: PCERT_NAME_BLOB;
                          dwStrType: DWORD;
                          psz: LPSTR;
                          csz: DWORD): DWORD;
                          stdcall; external CRYPT32;
type
  CERT_NAME_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;

  CRYPT_INTEGER_BLOB = CERT_NAME_BLOB;
  CRYPT_BIT_BLOB = record
    cbData: DWORD;
    pbData: PByte;
    cUnusedBits: DWORD;
  end;

  CRYPT_ALGORITHM_IDENTIFIER = record
    pszObjId: LPSTR;
    Parameters: CERT_NAME_BLOB;
  end;

  CERT_PUBLIC_KEY_INFO = record
    Algorithm: CRYPT_ALGORITHM_IDENTIFIER;
    PublicKey: CRYPT_BIT_BLOB;
  end;

  CERT_EXTENSION = record
    pszObjId: LPSTR;
    fCritical: BOOL;
    Value: CERT_NAME_BLOB;
  end;
  PCERT_EXTENSION = ^CERT_EXTENSION;
  {$ALIGN ON}
  HCRYPTPROV_LEGACY = ULONG_PTR;
  HCRYPTPROV = ULONG_PTR;
  HCERTSTORE = THandle;
  PCCERT_CONTEXT = ^CERT_CONTEXT;
  {$ALIGN 4}
  CERT_CONTEXT = record
    dwCertEncodingType: DWORD;
    pbCertEncoded: PBYTE;
    cbCertEncoded: DWORD;
    pCertInfo: PCERT_INFO;
    hCertStore: HCERTSTORE;
  end;
  PCERT_PUBLIC_KEY_INFO = ^CERT_PUBLIC_KEY_INFO;
  PCERT_INFO = ^CERT_INFO;
  CERT_INFO = record
    dwVersion: DWORD;
    SerialNumber: CRYPT_INTEGER_BLOB;
    SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER;
    Issuer: CERT_NAME_BLOB;
    NotBefore: FILETIME;
    NotAfter: FILETIME;
    Subject: CERT_NAME_BLOB;
    SubjectPublicKeyInfo: CERT_PUBLIC_KEY_INFO;
    IssuerUniqueId: CRYPT_BIT_BLOB;
    SubjectUniqueId: CRYPT_BIT_BLOB;
    cExtension: DWORD;
    rgExtension: PCERT_EXTENSION;
  end;
  PCERT_ENHKEY_USAGE = ^CERT_ENHKEY_USAGE;
  CERT_ENHKEY_USAGE = record
    cUsageIdentifier: DWORD;
    rgpszUsageIdentifier: ^LPSTR;
  end;

  //procedure InitializeControls;
  procedure LoadCerts(lvCertificates:TcxListView);
  function GetCertName(pName: PCERT_NAME_BLOB): string;
  function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
  function GetCertificateName(pName: PCERT_NAME_BLOB): string;
  function IsCertificateValid(CertContext: PCCERT_CONTEXT): Boolean;
  function IsEFacturaCertificate(CertContext: PCCERT_CONTEXT): Boolean;
  //function GetSelectedSerialNumber: string;
  //function GetSelectedCertificate: Integer;
  function GetCertificateType(const Issuer: string): string;
  function ExtractCertificateName(const Description: string): string; //
  procedure AddCertificate(lvCertificates:TcxListView;const Subject, Issuer,
                           SerialNumber: string;
                           ValidFrom, ValidTo: TDateTime);
  function CertGetEnhancedKeyUsage(
                                    pCertContext: PCCERT_CONTEXT;
                                    dwFlags: DWORD;
                                    pUsage: PCERT_ENHKEY_USAGE;
                                    pcbUsage: PDWORD):
                                    BOOL; stdcall; external CRYPT32;
  function CertCloseStore(hCertStore: HCERTSTORE;
	  					  dwFlags: DWORD): BOOL;
						  stdcall; external CRYPT32;
  function CertEnumCertificatesInStore(hCertStore: HCERTSTORE;
                                       pPrevCertContext: PCCERT_CONTEXT):
                                       PCCERT_CONTEXT;
                                       stdcall; external CRYPT32;
  function CertOpenSystemStoreA(hprov: HCRYPTPROV_LEGACY;
                                szSubsystemProtocol: LPCSTR):HCERTSTORE;
                                stdcall; external 'crypt32.dll';
  function CertNameToStr(dwCertEncodingType: DWORD;
                         pName: PCERT_NAME_BLOB;
                         dwStrType: DWORD;
                         psz: PWideChar;
                         csz: DWORD): DWORD;
                         stdcall; external 'crypt32.dll';

implementation

function ExtractCertificateName(const Description: string): string;
var
  Parts: TArray<string>;
  I: Integer;
begin
  Result := '';
  // Para certificado de Representación
  if ContainsText(Description, 'O=') then
  begin
    Parts := Description.Split([',']);
    for I := 0 to Length(Parts) - 1 do
    begin
      if Parts[I].Contains('O=') then
      begin
        Result := Copy(Parts[I], 3, Length(Parts[I])); // Elimina 'O='
        Break;
      end;
    end;
  end
  // Para certificado Nominal
  else if ContainsText(Description, 'CN=') then
  begin
    Parts := Description.Split([',']);
    for I := 0 to Length(Parts) - 1 do
    begin
      if Parts[I].Contains('CN=') then
      begin
        Result := Copy(Parts[I], 4, Length(Parts[I])); // Elimina 'CN='
        Break;
      end;
    end;
  end;
end;

function GetCertificateType(const Issuer: string): string;
begin
  if ContainsText(Issuer, 'AC Representación') then
    Result := 'Representación FNMT'
  else if ContainsText(Issuer, 'AC FNMT Usuarios') then
    Result := 'Nominal FNMT'
  else
    Result := 'Otro';
end;

//function TfrmCertificateSelector.GetSelectedSerialNumber: string;
//begin
//  Result := '';
//  if lvCertificates.Selected <> nil then
//    Result := lvCertificates.Selected.SubItems[COLUMNA_NROSERIE];
//end;

function IsCertificateValid(CertContext: PCCERT_CONTEXT): Boolean;
var
  CurrentTime, NotBefore, NotAfter: TFileTime;
begin
  Result := False;

  // Obtener la hora actual en formato FileTime
  GetSystemTimeAsFileTime(CurrentTime);

  // Obtener las fechas de validez del certificado
  NotBefore := CertContext^.pCertInfo^.NotBefore;
  NotAfter := CertContext^.pCertInfo^.NotAfter;

  // Comparar las fechas
  // CompareFileTime devuelve:
  // -1 si el primer parámetro es menor que el segundo
  //  0 si son iguales
  //  1 si el primer parámetro es mayor que el segundo
  Result := (CompareFileTime(CurrentTime, NotBefore) >= 0) and
            (CompareFileTime(CurrentTime, NotAfter) <= 0);
end;

function GetCertificateName(pName: PCERT_NAME_BLOB): string;
var
  dwStrLen: DWORD;
  pwszNameString: PAnsiChar;
begin
  Result := '';

  // First call to get required buffer size
  dwStrLen := CertNameToStrA( X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                              // Explicit typecast to ensure compatibility
                              PCERT_NAME_BLOB(pName),
                              CERT_X500_NAME_STR,
                              nil,
                              0);
  if (dwStrLen > 0) then
  begin
    // Allocate buffer
    GetMem(pwszNameString, dwStrLen);
    try
      // Second call to get actual name
      if CertNameToStrA(
        X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
        PCERT_NAME_BLOB(pName),  // Explicit typecast
        CERT_X500_NAME_STR,
        pwszNameString,
        dwStrLen) > 0 then
      begin
        Result := string(pwszNameString);
      end;
    finally
      FreeMem(pwszNameString);
    end;
  end;
end;

function GetCertName(pName: PCERT_NAME_BLOB): string;
var
  pcbStrLen: DWORD;
  pwszStr: PWideChar;
begin
  Result := '';
  // Obtener longitud necesaria
  pcbStrLen := CertNameToStr(X509_ASN_ENCODING,
                             pName,
                             CERT_X500_NAME_STR,
                             nil,
                             0);
  if (pcbStrLen > 1) then
  begin
    // Asignar buffer
    GetMem(pwszStr, pcbStrLen * 2);
    try
      // Obtener nombre
      if CertNameToStr(X509_ASN_ENCODING,
                       pName,
                       CERT_X500_NAME_STR,
                       pwszStr, pcbStrLen) > 1 then
        Result := pwszStr;
    finally
      FreeMem(pwszStr);
    end;
  end;
end;

function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
var
  SystemTime: TSystemTime;
begin
  FileTimeToSystemTime(FileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

function IsEFacturaCertificate(CertContext: PCCERT_CONTEXT): Boolean;
var
  Issuer: string;
begin
  Result := False;
  // Obtener el Issuer del certificado
  Issuer := GetCertificateName(@CertContext^.pCertInfo^.Issuer);
  // Verificar si es un certificado FNMT válido para e-factura
  Result := (ContainsText(Issuer, 'AC Representación') or
            (ContainsText(Issuer, 'AC FNMT Usuarios')));
end;

procedure LoadCerts(lvCertificates:TcxListView);
var
  Store: HCERTSTORE;
  CertContext: PCCERT_CONTEXT;
  Subject, Issuer: string;
  ValidFrom, ValidTo: TDateTime;
  SerialNumber: string;
  I: Integer;
begin
  lvCertificates.Items.Clear;
  Store := CertOpenSystemStoreA(0, PAnsiChar('MY'));
  if Store <> 0 then
  try
    CertContext := nil;
    repeat
      CertContext := CertEnumCertificatesInStore(Store, CertContext);
      if ((CertContext <> nil)
          and (IsCertificateValid(CertContext))
          and (IsEFacturaCertificate(CertContext))) then
      begin
        // Use the corrected GetCertificateName function
        Subject := GetCertificateName(@CertContext^.pCertInfo^.Subject);
        Issuer := GetCertificateName(@CertContext^.pCertInfo^.Issuer);

        ValidFrom := FileTimeToDateTime(CertContext^.pCertInfo^.NotBefore);
        ValidTo := FileTimeToDateTime(CertContext^.pCertInfo^.NotAfter);

        SerialNumber := '';
        for I := 0 to CertContext^.pCertInfo^.SerialNumber.cbData - 1 do
          SerialNumber := SerialNumber +
            IntToHex(PByte(CertContext^.pCertInfo^.SerialNumber.pbData)[I], 2);

        AddCertificate(lvCertificates, Subject, Issuer, SerialNumber,
                       ValidFrom, ValidTo);
      end;
    until CertContext = nil;
  finally
    CertCloseStore(Store, 0);
  end;
end;
//
//procedure TfrmCertificateSelector.lvCertificatesDblClick(Sender: TObject);
//begin
//  btnOkClick(Sender);
//end;

//procedure TfrmCertificateSelector.InitializeControls;
//begin
//  with lvCertificates do
//  begin
//    ViewStyle := vsReport;
//    with Columns.Add do
//    begin
//      Caption := 'Tipo';
//      Width := 100;
//    end;
//    with Columns.Add do
//    begin
//      Caption := 'Titular/Empresa';
//      Width := 250;
//    end;
//    with Columns.Add do
//    begin
//      Caption := 'Nombre';
//      Width := 250;
//    end;
//    with Columns.Add do
//    begin
//      Caption := 'Emisor';
//      Width := 200;
//    end;
//    with Columns.Add do
//    begin
//      Caption := 'Válido hasta';
//      Width := 120;
//    end;
//    with Columns.Add do
//    begin
//      Caption := 'Número Serie';
//      Width := 150;
//    end;
//  end;
//end;

//function TfrmCertificateSelector.GetSelectedCertificate: Integer;
//begin
//  if lvCertificates.Selected <> nil then
//    Result := lvCertificates.Selected.Index
//  else
//    Result := -1;
//end;

procedure AddCertificate(lvCertificates:TcxListView;const Subject, Issuer,
  SerialNumber: string; ValidFrom, ValidTo: TDateTime);
var
  Item: TListItem;
  CertType:string;
  NameCer:string;
begin
  Item := lvCertificates.Items.Add;
  CertType := GetCertificateType(Issuer);
  Item.Caption := CertType;
  NameCer := ExtractCertificateName(Subject);
  Item.SubItems.Add(NameCer);
  Item.SubItems.Add(Subject);
  Item.SubItems.Add(Issuer);
  Item.SubItems.Add(DateTimeToStr(ValidTo));
  Item.SubItems.Add(SerialNumber);
end;
(*uses
  SBXMLAdESIntf, SBXMLAdES, SBXMLSec, SBX509, SBUtils, SBConstants;
procedure FirmarFacturaE(const ArchivoXMLEntrada, ArchivoXMLSalida, NumeroSerieCertificado: string);
var
  Signer: TElXAdESSigner;
  Cert: TElX509Certificate;
  CertManager: TElX509CertificateStore;
begin
  Signer := TElXAdESSigner.Create(nil);
  CertManager := TElX509CertificateStore.Create(nil);
  try
    // Configurar el almacén de certificados para buscar por número de serie
    CertManager.Open(SB_CERT_STORE_SYSTEM);
    // Buscar el certificado por número de serie
    Cert := CertManager.FindCertificateBySerialNumber(NumeroSerieCertificado);
    if not Assigned(Cert) then
      raise Exception.Create('No se pudo encontrar el certificado con número de serie: ' + NumeroSerieCertificado);
    // Configurar el firmante
    Signer.SigningCertificate := Cert;
    // Importante: Usar el formato XAdES-EPES para Facturae
    Signer.XAdESVersion := xav_XAdES_EPES;
    // Política de firma para Facturae (ajustar según versión requerida)
    Signer.PolicyID := 'http://www.facturae.es/politica_de_firma_formato_facturae/politica_de_firma_formato_facturae_v3_1.pdf';
    Signer.PolicyDescription := 'Política de Firma Facturae v3.1';
    Signer.PolicyDigestAlgorithm := SB_ALGORITHM_DIGEST_SHA1;
    // Hash de la política - deberás usar el valor correcto para la versión específica
    Signer.PolicyDigestValue := 'Hm7xQrCkuY3sXqMD4RUZjlyhTTk=';
    // Configurar el elemento a firmar (toda la factura)
    Signer.InputFile := ArchivoXMLEntrada;
    Signer.OutputFile := ArchivoXMLSalida;
    // Configurar la ubicación de la firma en el documento
    Signer.SignatureType := xst_Enveloped;
    // Para Facturae, se suele firmar el nodo raíz
    Signer.SigningElementID := ''; // Vacío para firmar el documento completo
    // Incluir información del firmante y timestamp
    Signer.IncludeSigningTime := True;
    Signer.IncludeSignerRole := True;
    Signer.SignerRole := 'supplier'; // Para Facturae
    // Ejecutar la firma
    Signer.Sign();
    ShowMessage('Documento firmado correctamente');
  finally
    Cert.Free;
    CertManager.Free;
    Signer.Free;
  end;
end;*)

end.
