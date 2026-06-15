{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFacturae                                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       15/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Generacion de eDoc Facturae 3.2.2 para facturas de venta mayor. Valida    }
{    datos minimos, firma XAdES con la politica Facturae y guarda el XML       }
{    firmado en fichero y en fza_facturas.XML_FAC.                             }
{******************************************************************************}
unit inLibFacturae;

interface

uses
  System.SysUtils, Uni;

type
  TFacturaeResultado = record
    Archivo: string;
    NumeroSerieCertificado: string;
    TitularCertificado: string;
    HuellaSha1Certificado: string;
  end;

function NombreArchivoFacturae(const ASerie, ANumero: string): string;
function EmitirFacturae(AConn: TUniConnection;
                        const ASerie, ANumero, AArchivo: string):
                        TFacturaeResultado;

implementation

uses
  System.Classes, System.IOUtils, System.Math, System.StrUtils, Data.DB,
  DBAccess, inLibDocumentoFiscal, inLibGlobalVar, inLibXades;

const
  cNsFacturae =
    'http://www.facturae.gob.es/formato/Versiones/Facturaev3_2_2.xml';
  cVersionFacturae = '3.2.2';
  cDir3RespaldoOficina = 'L01070184';
  cDir3RespaldoOrgano = 'L01070184';
  cDir3RespaldoUnidad = 'L01070184';

function Xml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function DecimalFacturae(AValor: Double;
                         ADecimales: Integer = 2): string;
var
  oFormato: TFormatSettings;
  sMascara: string;
begin
  oFormato := TFormatSettings.Create('en-US');
  if ADecimales = 6 then
    sMascara := '0.000000'
  else
    sMascara := '0.00';
  Result := FormatFloat(sMascara, AValor, oFormato);
end;

function CampoStr(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := Trim(oCampo.AsString);
end;

function CampoDir3Facturae(ADataSet: TDataSet; const ACampo,
                           ADefecto: string): string;
begin
  Result := CampoStr(ADataSet, ACampo);
  if (Result = '') and
     SameText(ACampo, 'CODIGO_OFICINA_CONTABLE_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_OFICINA_CONTABLE_CLI');
  if (Result = '') and
     SameText(ACampo, 'CODIGO_ORGANO_GESTOR_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_ORGANO_GESTOR_CLI');
  if (Result = '') and
     SameText(ACampo, 'CODIGO_UNIDAD_TRAMITADORA_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_UNIDAD_TRAMITADORA_CLI');
  if Result = '' then
    Result := ADefecto;
end;

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsFloat;
end;

function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsDateTime;
end;

procedure Linea(ASb: TStringBuilder; ANivel: Integer; const ATexto: string);
begin
  ASb.Append(StringOfChar(' ', ANivel * 2));
  ASb.AppendLine(ATexto);
end;

procedure Nodo(ASb: TStringBuilder; ANivel: Integer;
               const ANombre, AValor: string);
begin
  Linea(ASb, ANivel, '<' + ANombre + '>' + Xml(AValor) + '</' +
    ANombre + '>');
end;

function NormalizarNamespacesFacturae(const AXml: string): string;
begin
  Result := StringReplace(AXml, '<fe:', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '</fe:', '</', [rfReplaceAll]);
  Result := StringReplace(Result, '<Facturae xmlns:fe=',
    '<fe:Facturae xmlns:fe=', []);
  Result := StringReplace(Result, '</Facturae>', '</fe:Facturae>', []);
end;

function NormalizarNif(const AValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := UpCase(AValor[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9']) then
      Result := Result + c;
  end;
end;

function CodigoPaisFacturae(const ACodigo, ANombre: string): string;
var
  sCodigo: string;
  sNombre: string;
begin
  sCodigo := UpperCase(Trim(ACodigo));
  sNombre := UpperCase(Trim(ANombre));
  if (sCodigo = '') or (sCodigo = 'ES') or (sCodigo = '724') or
     SameText(sNombre, 'ESPAÑA') or SameText(sNombre, 'ESPANA') then
    Result := 'ESP'
  else if Length(sCodigo) = 3 then
    Result := sCodigo
  else
    Result := 'ESP';
end;

function EsPersonaJuridica(const ANif: string): Boolean;
var
  sNif: string;
begin
  sNif := NormalizarNif(ANif);
  Result := False;
  if sNif <> '' then
    Result := CharInSet(sNif[1],
      ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'N',
       'P', 'Q', 'R', 'S', 'U', 'V', 'W']);
end;

procedure SepararNombrePersona(const ARazonSocial: string;
                               out ANombre, AApellidos: string);
var
  iPos: Integer;
  sTexto: string;
begin
  sTexto := Trim(ARazonSocial);
  iPos := Pos(' ', sTexto);
  if iPos > 0 then
  begin
    ANombre := Copy(sTexto, 1, iPos - 1);
    AApellidos := Trim(Copy(sTexto, iPos + 1, MaxInt));
  end
  else
  begin
    ANombre := sTexto;
    AApellidos := '.';
  end;
end;

function NombreArchivoFacturae(const ASerie, ANumero: string): string;
var
  i: Integer;
  sBase: string;
  c: Char;
begin
  Result := 'eDoc_';
  sBase := ASerie + '_' + ANumero;
  for i := 1 to Length(sBase) do
  begin
    c := sBase[i];
    if CharInSet(c, ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + c
    else
      Result := Result + '_';
  end;
  Result := Result + '.xsig';
end;

function IdFacturaeSeguro(const ASerie, ANumero: string): string;
var
  i: Integer;
  sBase: string;
  c: Char;
begin
  Result := 'FZ-FACTURAE';
  sBase := ASerie + '-' + ANumero;
  for i := 1 to Length(sBase) do
  begin
    c := UpCase(sBase[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9', '-']) then
      Result := Result + '-' + c;
  end;
end;

function BaseLinea(ALinea: TDataSet): Double;
var
  dBase: Double;
begin
  dBase := CampoFloat(ALinea, 'TOTAL_FAC_SIVA_FACLIN');
  if Abs(dBase) <= 0.000001 then
    dBase := CampoFloat(ALinea, 'CANTIDAD_FACLIN') *
      CampoFloat(ALinea, 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN');
  Result := dBase;
end;

function RecargoActivo(ACabecera: TDataSet; const ACampoTotal,
                       ACampoPorcentaje: string): Double;
begin
  Result := 0;
  if Abs(CampoFloat(ACabecera, ACampoTotal)) > 0.000001 then
    Result := CampoFloat(ACabecera, ACampoPorcentaje);
end;

function RecargoPorIva(ACabecera: TDataSet; APorcentajeIva: Double): Double;
begin
  Result := 0;
  if Abs(APorcentajeIva -
     CampoFloat(ACabecera, 'PORCENTAJE_IVAN_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_REN_FAC',
      'PORCENTAJE_REN_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAR_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_RER_FAC',
      'PORCENTAJE_RER_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAS_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_RES_FAC',
      'PORCENTAJE_RES_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAE_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_REE_FAC',
      'PORCENTAJE_REE_FAC');
end;

procedure AnadirDireccion(ASb: TStringBuilder; ANivel: Integer;
                          const APais, ADireccion, ACp, APoblacion,
                          AProvincia: string);
begin
  if APais = 'ESP' then
  begin
    Linea(ASb, ANivel, '<fe:AddressInSpain>');
    Nodo(ASb, ANivel + 1, 'fe:Address', ADireccion);
    Nodo(ASb, ANivel + 1, 'fe:PostCode', ACp);
    Nodo(ASb, ANivel + 1, 'fe:Town', APoblacion);
    Nodo(ASb, ANivel + 1, 'fe:Province', AProvincia);
    Nodo(ASb, ANivel + 1, 'fe:CountryCode', APais);
    Linea(ASb, ANivel, '</fe:AddressInSpain>');
  end
  else
  begin
    Linea(ASb, ANivel, '<fe:OverseasAddress>');
    Nodo(ASb, ANivel + 1, 'fe:Address', ADireccion);
    Nodo(ASb, ANivel + 1, 'fe:PostCodeAndTown',
      Trim(ACp + ' ' + APoblacion));
    Nodo(ASb, ANivel + 1, 'fe:Province', AProvincia);
    Nodo(ASb, ANivel + 1, 'fe:CountryCode', APais);
    Linea(ASb, ANivel, '</fe:OverseasAddress>');
  end;
end;

procedure AnadirCentroAdministrativo(ASb: TStringBuilder; const ACodigo,
                                     ARol, ANombre, APais, ADireccion, ACp,
                                     APoblacion, AProvincia: string);
begin
  Linea(ASb, 4, '<fe:AdministrativeCentre>');
  Nodo(ASb, 5, 'fe:CentreCode', ACodigo);
  Nodo(ASb, 5, 'fe:RoleTypeCode', ARol);
  Nodo(ASb, 5, 'fe:Name', ANombre);
  AnadirDireccion(ASb, 5, APais, ADireccion, ACp, APoblacion, AProvincia);
  Linea(ASb, 4, '</fe:AdministrativeCentre>');
end;

procedure AnadirCentrosAdministrativos(ASb: TStringBuilder;
                                       const AOficina, AOrgano, AUnidad,
                                       APais, ADireccion, ACp, APoblacion,
                                       AProvincia: string);
begin
  if (Trim(AOficina) <> '') and (Trim(AOrgano) <> '') and
     (Trim(AUnidad) <> '') then
  begin
    Linea(ASb, 3, '<fe:AdministrativeCentres>');
    AnadirCentroAdministrativo(ASb, AOficina, '01', 'Oficina contable',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    AnadirCentroAdministrativo(ASb, AOrgano, '02', 'Organo gestor',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    AnadirCentroAdministrativo(ASb, AUnidad, '03', 'Unidad tramitadora',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:AdministrativeCentres>');
  end;
end;

procedure AnadirParte(ASb: TStringBuilder; const ANodo, ANif, ARazonSocial,
                      ADireccion, ACp, APoblacion, AProvincia,
                      APais, AOficina, AOrgano, AUnidad: string);
var
  sNombre: string;
  sApellidos: string;
  bJuridica: Boolean;
begin
  bJuridica := EsPersonaJuridica(ANif);
  Linea(ASb, 2, '<fe:' + ANodo + '>');
  Linea(ASb, 3, '<fe:TaxIdentification>');
  if bJuridica then
    Nodo(ASb, 4, 'fe:PersonTypeCode', 'J')
  else
    Nodo(ASb, 4, 'fe:PersonTypeCode', 'F');
  Nodo(ASb, 4, 'fe:ResidenceTypeCode', 'R');
  Nodo(ASb, 4, 'fe:TaxIdentificationNumber', NormalizarNif(ANif));
  Linea(ASb, 3, '</fe:TaxIdentification>');
  AnadirCentrosAdministrativos(ASb, AOficina, AOrgano, AUnidad, APais,
    ADireccion, ACp, APoblacion, AProvincia);
  if bJuridica then
  begin
    Linea(ASb, 3, '<fe:LegalEntity>');
    Nodo(ASb, 4, 'fe:CorporateName', ARazonSocial);
    AnadirDireccion(ASb, 4, APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:LegalEntity>');
  end
  else
  begin
    SepararNombrePersona(ARazonSocial, sNombre, sApellidos);
    Linea(ASb, 3, '<fe:Individual>');
    Nodo(ASb, 4, 'fe:Name', sNombre);
    Nodo(ASb, 4, 'fe:FirstSurname', sApellidos);
    AnadirDireccion(ASb, 4, APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:Individual>');
  end;
  Linea(ASb, 2, '</fe:' + ANodo + '>');
end;

procedure AnadirImpuesto(ASb: TStringBuilder; ANivel: Integer;
                         APorcentajeIva, ABase, AImporteIva,
                         APorcentajeRe, AImporteRe: Double);
begin
  Linea(ASb, ANivel, '<fe:Tax>');
  Nodo(ASb, ANivel + 1, 'fe:TaxTypeCode', '01');
  Nodo(ASb, ANivel + 1, 'fe:TaxRate',
    DecimalFacturae(APorcentajeIva));
  Linea(ASb, ANivel + 1, '<fe:TaxableBase>');
  Nodo(ASb, ANivel + 2, 'fe:TotalAmount', DecimalFacturae(ABase));
  Linea(ASb, ANivel + 1, '</fe:TaxableBase>');
  Linea(ASb, ANivel + 1, '<fe:TaxAmount>');
  Nodo(ASb, ANivel + 2, 'fe:TotalAmount',
    DecimalFacturae(AImporteIva));
  Linea(ASb, ANivel + 1, '</fe:TaxAmount>');
  if (Abs(APorcentajeRe) > 0.000001) and
     (Abs(AImporteRe) > 0.000001) then
  begin
    Nodo(ASb, ANivel + 1, 'fe:EquivalenceSurcharge',
      DecimalFacturae(APorcentajeRe));
    Linea(ASb, ANivel + 1, '<fe:EquivalenceSurchargeAmount>');
    Nodo(ASb, ANivel + 2, 'fe:TotalAmount',
      DecimalFacturae(AImporteRe));
    Linea(ASb, ANivel + 1, '</fe:EquivalenceSurchargeAmount>');
  end;
  Linea(ASb, ANivel, '</fe:Tax>');
end;

procedure AnadirImpuestoCabecera(ASb: TStringBuilder; ACabecera: TDataSet;
                                 const ACampoBase, ACampoPorIva,
                                 ACampoIva, ACampoPorRe,
                                 ACampoRe: string;
                                 var AContador: Integer);
var
  dBase: Double;
  dIva: Double;
  dRe: Double;
begin
  dBase := CampoFloat(ACabecera, ACampoBase);
  dIva := CampoFloat(ACabecera, ACampoIva);
  dRe := CampoFloat(ACabecera, ACampoRe);
  if (Abs(dBase) > 0.000001) or (Abs(dIva) > 0.000001) or
     (Abs(dRe) > 0.000001) then
  begin
    Inc(AContador);
    AnadirImpuesto(ASb, 5, CampoFloat(ACabecera, ACampoPorIva), dBase,
      dIva, CampoFloat(ACabecera, ACampoPorRe), dRe);
  end;
end;

procedure ValidarObligatorio(AErrores: TStrings; const ATexto,
                             AValor: string);
begin
  if Trim(AValor) = '' then
    AErrores.Add('- Falta ' + ATexto + '.');
end;

procedure ValidarParte(AErrores: TStrings; const ATexto, ANif, ARazon,
                       ADireccion, ACp, APoblacion, AProvincia,
                       APais: string);
begin
  ValidarObligatorio(AErrores, 'NIF de ' + ATexto, ANif);
  ValidarObligatorio(AErrores, 'razon social de ' + ATexto, ARazon);
  ValidarObligatorio(AErrores, 'direccion de ' + ATexto, ADireccion);
  ValidarObligatorio(AErrores, 'codigo postal de ' + ATexto, ACp);
  ValidarObligatorio(AErrores, 'poblacion de ' + ATexto, APoblacion);
  ValidarObligatorio(AErrores, 'provincia de ' + ATexto, AProvincia);
  if (APais = 'ESP') and (Trim(ANif) <> '') and
     (not DocumentoFiscalValido(ANif)) then
    AErrores.Add('- ' + MensajeDocumentoFiscalInvalido(ANif) + ' (' +
      ATexto + ').');
end;

procedure ValidarCodigoDir3(AErrores: TStrings; const ATexto,
                            ACodigo: string);
begin
  if Trim(ACodigo) = '' then
    AErrores.Add('- Falta el codigo DIR3 de ' + ATexto + '.')
  else if Length(Trim(ACodigo)) > 10 then
    AErrores.Add('- El codigo DIR3 de ' + ATexto +
      ' supera 10 caracteres.');
end;

procedure ValidarDir3Facturae(AErrores: TStrings; ACabecera: TDataSet);
begin
  ValidarCodigoDir3(AErrores, 'la oficina contable',
    CampoDir3Facturae(ACabecera, 'CODIGO_OFICINA_CONTABLE_FAC',
      cDir3RespaldoOficina));
  ValidarCodigoDir3(AErrores, 'el organo gestor',
    CampoDir3Facturae(ACabecera, 'CODIGO_ORGANO_GESTOR_FAC',
      cDir3RespaldoOrgano));
  ValidarCodigoDir3(AErrores, 'la unidad tramitadora',
    CampoDir3Facturae(ACabecera, 'CODIGO_UNIDAD_TRAMITADORA_FAC',
      cDir3RespaldoUnidad));
end;

procedure ValidarFactura(ACabecera, ALineas: TDataSet);
var
  oErrores: TStringList;
  iLineas: Integer;
  dBaseLineas: Double;
  dBaseLinea: Double;
begin
  oErrores := TStringList.Create;
  try
    if ACabecera.IsEmpty then
      oErrores.Add('- No existe la factura seleccionada.');
    if not SameText(CampoStr(ACabecera, 'TIPO_FAC'), 'NORMAL') then
      oErrores.Add('- El eDoc solo se emite desde venta mayor NORMAL.');
    if CampoStr(ACabecera, 'ESCONSOLIDADA_FAC') <> 'S' then
      oErrores.Add('- La factura debe estar consolidada antes de emitir eDoc.');
    if CampoFecha(ACabecera, 'FECHA_FAC') <= 0 then
      oErrores.Add('- Falta la fecha oficial de la factura.');
    ValidarParte(oErrores, 'empresa emisora',
      CampoStr(ACabecera, 'NIF_EMPRESA_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_EMPRESA_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'POBLACION_EMPRESA_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_EMPRESA_FAC'),
      CodigoPaisFacturae(CampoStr(ACabecera, 'CODIGO_PAI_EMPRESA_FAC'),
                         CampoStr(ACabecera, 'NOMBRE_PAI_EMPRESA_FAC')));
    ValidarParte(oErrores, 'cliente',
      CampoStr(ACabecera, 'NIF_CLIENTE_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_CLIENTE_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'POBLACION_CLIENTE_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_CLIENTE_FAC'),
      CodigoPaisFacturae(CampoStr(ACabecera, 'CODIGO_PAI_CLIENTE_FAC'),
                         CampoStr(ACabecera, 'NOMBRE_PAI_CLIENTE_FAC')));
    ValidarDir3Facturae(oErrores, ACabecera);
    iLineas := 0;
    dBaseLineas := 0;
    ALineas.First;
    while not ALineas.Eof do
    begin
      Inc(iLineas);
      dBaseLinea := BaseLinea(ALineas);
      dBaseLineas := dBaseLineas + dBaseLinea;
      if Trim(CampoStr(ALineas, 'DESCRIPCION_ARTICULO_FACLIN')) = '' then
        oErrores.Add('- La linea ' + CampoStr(ALineas, 'LINEA_FACLIN') +
          ' no tiene descripcion.');
      if Abs(CampoFloat(ALineas, 'CANTIDAD_FACLIN')) <= 0.000001 then
        oErrores.Add('- La linea ' + CampoStr(ALineas, 'LINEA_FACLIN') +
          ' tiene cantidad cero.');
      ALineas.Next;
    end;
    if iLineas = 0 then
      oErrores.Add('- La factura no tiene lineas.');
    if Abs(dBaseLineas - CampoFloat(ACabecera, 'TOTAL_BASES_FAC')) > 0.05 then
      oErrores.Add('- La suma de bases de lineas no cuadra con cabecera.');
    if Abs(CampoFloat(ACabecera, 'TOTAL_BASES_FAC') +
       CampoFloat(ACabecera, 'TOTAL_IMPUESTOS_FAC') -
       CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC') -
       CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')) > 0.05 then
      oErrores.Add('- Los totales de cabecera no cuadran.');
    ALineas.First;
    if oErrores.Count > 0 then
      raise Exception.Create('No se puede emitir eDoc Facturae:' +
        sLineBreak + oErrores.Text);
  finally
    FreeAndNil(oErrores);
  end;
end;

procedure CargarCertificadoEmpresa(AConn: TUniConnection;
                                   const ACodigoEmpresa: string;
                                   out ASerial, ATitular: string);
var
  Qry: TUniQuery;
begin
  ASerial := '';
  ATitular := '';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT CODIGO_CERTIFICADO_EMP, TITULAR_CERTIFICADO_EMP ' +
      ' FROM fza_empresas ' +
      ' WHERE CODIGO_EMP_EMP = :EMP ' +
      ' LIMIT 1';
    Qry.ParamByName('EMP').AsString := ACodigoEmpresa;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      ASerial := Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      ATitular := Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    end;
  finally
    FreeAndNil(Qry);
  end;
  if (ASerial = '') and (ATitular = '') then
    raise Exception.Create('La empresa de la factura no tiene certificado ' +
      'configurado para firmar eDoc Facturae.');
end;

function ConstruirXmlFacturae(ACabecera, ALineas: TDataSet): string;
var
  SB: TStringBuilder;
  iImpuestos: Integer;
  dBase: Double;
  dIva: Double;
  dRe: Double;
  dPorIva: Double;
  dPorRe: Double;
  sPaisEmp: string;
  sPaisCli: string;
begin
  SB := TStringBuilder.Create;
  try
    sPaisEmp := CodigoPaisFacturae(CampoStr(ACabecera,
      'CODIGO_PAI_EMPRESA_FAC'), CampoStr(ACabecera,
      'NOMBRE_PAI_EMPRESA_FAC'));
    sPaisCli := CodigoPaisFacturae(CampoStr(ACabecera,
      'CODIGO_PAI_CLIENTE_FAC'), CampoStr(ACabecera,
      'NOMBRE_PAI_CLIENTE_FAC'));
    SB.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
    Linea(SB, 0, '<fe:Facturae xmlns:fe="' + cNsFacturae + '">');
    Linea(SB, 1, '<fe:FileHeader>');
    Nodo(SB, 2, 'fe:SchemaVersion', cVersionFacturae);
    Nodo(SB, 2, 'fe:Modality', 'I');
    Nodo(SB, 2, 'fe:InvoiceIssuerType', 'EM');
    Linea(SB, 2, '<fe:Batch>');
    Nodo(SB, 3, 'fe:BatchIdentifier',
      NormalizarNif(CampoStr(ACabecera, 'NIF_EMPRESA_FAC')) + '-' +
      CampoStr(ACabecera, 'SERIE_FAC') + '-' +
      CampoStr(ACabecera, 'NUMERO_FAC'));
    Nodo(SB, 3, 'fe:InvoicesCount', '1');
    Linea(SB, 3, '<fe:TotalInvoicesAmount>');
    Nodo(SB, 4, 'fe:TotalAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Linea(SB, 3, '</fe:TotalInvoicesAmount>');
    Linea(SB, 3, '<fe:TotalOutstandingAmount>');
    Nodo(SB, 4, 'fe:TotalAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Linea(SB, 3, '</fe:TotalOutstandingAmount>');
    Linea(SB, 3, '<fe:TotalExecutableAmount>');
    Nodo(SB, 4, 'fe:TotalAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Linea(SB, 3, '</fe:TotalExecutableAmount>');
    Nodo(SB, 3, 'fe:InvoiceCurrencyCode', 'EUR');
    Linea(SB, 2, '</fe:Batch>');
    Linea(SB, 1, '</fe:FileHeader>');
    Linea(SB, 1, '<fe:Parties>');
    AnadirParte(SB, 'SellerParty',
      CampoStr(ACabecera, 'NIF_EMPRESA_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_EMPRESA_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'POBLACION_EMPRESA_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_EMPRESA_FAC'), sPaisEmp, '', '', '');
    AnadirParte(SB, 'BuyerParty',
      CampoStr(ACabecera, 'NIF_CLIENTE_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_CLIENTE_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'POBLACION_CLIENTE_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_CLIENTE_FAC'), sPaisCli,
      CampoDir3Facturae(ACabecera, 'CODIGO_OFICINA_CONTABLE_FAC',
        cDir3RespaldoOficina),
      CampoDir3Facturae(ACabecera, 'CODIGO_ORGANO_GESTOR_FAC',
        cDir3RespaldoOrgano),
      CampoDir3Facturae(ACabecera, 'CODIGO_UNIDAD_TRAMITADORA_FAC',
        cDir3RespaldoUnidad));
    Linea(SB, 1, '</fe:Parties>');
    Linea(SB, 1, '<fe:Invoices>');
    Linea(SB, 2, '<fe:Invoice>');
    Linea(SB, 3, '<fe:InvoiceHeader>');
    Nodo(SB, 4, 'fe:InvoiceNumber',
      CampoStr(ACabecera, 'NUMERO_FAC'));
    Nodo(SB, 4, 'fe:InvoiceSeriesCode',
      CampoStr(ACabecera, 'SERIE_FAC'));
    Nodo(SB, 4, 'fe:InvoiceDocumentType', 'FC');
    Nodo(SB, 4, 'fe:InvoiceClass', 'OO');
    Linea(SB, 3, '</fe:InvoiceHeader>');
    Linea(SB, 3, '<fe:InvoiceIssueData>');
    Nodo(SB, 4, 'fe:IssueDate',
      FormatDateTime('yyyy-mm-dd', CampoFecha(ACabecera, 'FECHA_FAC')));
    Nodo(SB, 4, 'fe:InvoiceCurrencyCode', 'EUR');
    Nodo(SB, 4, 'fe:TaxCurrencyCode', 'EUR');
    Nodo(SB, 4, 'fe:LanguageName', 'es');
    Linea(SB, 3, '</fe:InvoiceIssueData>');
    Linea(SB, 3, '<fe:TaxesOutputs>');
    iImpuestos := 0;
    AnadirImpuestoCabecera(SB, ACabecera, 'TOTAL_BASEI_IVAN_FAC',
      'PORCENTAJE_IVAN_FAC', 'TOTAL_IVAN_FAC', 'PORCENTAJE_REN_FAC',
      'TOTAL_REN_FAC', iImpuestos);
    AnadirImpuestoCabecera(SB, ACabecera, 'TOTAL_BASEI_IVAR_FAC',
      'PORCENTAJE_IVAR_FAC', 'TOTAL_IVAR_FAC', 'PORCENTAJE_RER_FAC',
      'TOTAL_RER_FAC', iImpuestos);
    AnadirImpuestoCabecera(SB, ACabecera, 'TOTAL_BASEI_IVAS_FAC',
      'PORCENTAJE_IVAS_FAC', 'TOTAL_IVAS_FAC', 'PORCENTAJE_RES_FAC',
      'TOTAL_RES_FAC', iImpuestos);
    AnadirImpuestoCabecera(SB, ACabecera, 'TOTAL_BASEI_IVAE_FAC',
      'PORCENTAJE_IVAE_FAC', 'TOTAL_IVAE_FAC', 'PORCENTAJE_REE_FAC',
      'TOTAL_REE_FAC', iImpuestos);
    if iImpuestos = 0 then
      AnadirImpuesto(SB, 5, 0, CampoFloat(ACabecera, 'TOTAL_BASES_FAC'),
        0, 0, 0);
    Linea(SB, 3, '</fe:TaxesOutputs>');
    if Abs(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')) > 0.000001 then
    begin
      Linea(SB, 3, '<fe:TaxesWithheld>');
      Linea(SB, 4, '<fe:Tax>');
      Nodo(SB, 5, 'fe:TaxTypeCode', '04');
      Nodo(SB, 5, 'fe:TaxRate',
        DecimalFacturae(CampoFloat(ACabecera, 'PORCENTAJE_RETENCION_FAC')));
      Linea(SB, 5, '<fe:TaxableBase>');
      Nodo(SB, 6, 'fe:TotalAmount',
        DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
      Linea(SB, 5, '</fe:TaxableBase>');
      Linea(SB, 5, '<fe:TaxAmount>');
      Nodo(SB, 6, 'fe:TotalAmount',
        DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')));
      Linea(SB, 5, '</fe:TaxAmount>');
      Linea(SB, 4, '</fe:Tax>');
      Linea(SB, 3, '</fe:TaxesWithheld>');
    end;
    Linea(SB, 3, '<fe:InvoiceTotals>');
    Nodo(SB, 4, 'fe:TotalGrossAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
    Nodo(SB, 4, 'fe:TotalGrossAmountBeforeTaxes',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
    Nodo(SB, 4, 'fe:TotalTaxOutputs',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_IMPUESTOS_FAC')));
    Nodo(SB, 4, 'fe:TotalTaxesWithheld',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')));
    Nodo(SB, 4, 'fe:InvoiceTotal',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Nodo(SB, 4, 'fe:TotalOutstandingAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Nodo(SB, 4, 'fe:TotalExecutableAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
    Linea(SB, 3, '</fe:InvoiceTotals>');
    Linea(SB, 3, '<fe:Items>');
    ALineas.First;
    while not ALineas.Eof do
    begin
      dBase := BaseLinea(ALineas);
      dPorIva := CampoFloat(ALineas, 'PORCENTAJE_IVA_FACLIN');
      dPorRe := RecargoPorIva(ACabecera, dPorIva);
      dIva := RoundTo(dBase * dPorIva / 100, -2);
      dRe := RoundTo(dBase * dPorRe / 100, -2);
      Linea(SB, 4, '<fe:InvoiceLine>');
      Nodo(SB, 5, 'fe:ItemDescription',
        CampoStr(ALineas, 'DESCRIPCION_ARTICULO_FACLIN'));
      Nodo(SB, 5, 'fe:Quantity',
        DecimalFacturae(CampoFloat(ALineas, 'CANTIDAD_FACLIN'), 6));
      Nodo(SB, 5, 'fe:UnitOfMeasure', '01');
      Nodo(SB, 5, 'fe:UnitPriceWithoutTax',
        DecimalFacturae(CampoFloat(ALineas,
        'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'), 6));
      Nodo(SB, 5, 'fe:TotalCost', DecimalFacturae(dBase));
      Nodo(SB, 5, 'fe:GrossAmount', DecimalFacturae(dBase));
      Linea(SB, 5, '<fe:TaxesOutputs>');
      AnadirImpuesto(SB, 6, dPorIva, dBase, dIva, dPorRe, dRe);
      Linea(SB, 5, '</fe:TaxesOutputs>');
      Linea(SB, 4, '</fe:InvoiceLine>');
      ALineas.Next;
    end;
    Linea(SB, 3, '</fe:Items>');
    Linea(SB, 2, '</fe:Invoice>');
    Linea(SB, 1, '</fe:Invoices>');
    Linea(SB, 0, '</fe:Facturae>');
    Result := NormalizarNamespacesFacturae(SB.ToString);
  finally
    FreeAndNil(SB);
  end;
end;

procedure GuardarXmlFactura(AConn: TUniConnection; const ASerie, ANumero,
                            AXml: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET XML_FAC = :XML_FAC, USUARIO_MODIF = :USUARIO_MODIF ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('XML_FAC').DataType := ftMemo;
    Qry.ParamByName('XML_FAC').AsString := AXml;
    Qry.ParamByName('USUARIO_MODIF').AsString := oUser;
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

function ColumnaExiste(AConn: TUniConnection; const ATabla,
                       ACampo: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS TOTAL ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      ' AND TABLE_NAME = :TABLA ' +
      ' AND COLUMN_NAME = :CAMPO ';
    Qry.ParamByName('TABLA').AsString := ATabla;
    Qry.ParamByName('CAMPO').AsString := ACampo;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('TOTAL').AsInteger > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

function ColumnasDir3Disponibles(AConn: TUniConnection;
                                 const ATabla, ASufijo: string): Boolean;
begin
  Result := ColumnaExiste(AConn, ATabla,
    'CODIGO_OFICINA_CONTABLE_' + ASufijo);
  if Result then
    Result := ColumnaExiste(AConn, ATabla,
      'CODIGO_ORGANO_GESTOR_' + ASufijo);
  if Result then
    Result := ColumnaExiste(AConn, ATabla,
      'CODIGO_UNIDAD_TRAMITADORA_' + ASufijo);
end;

function SqlCabeceraFacturae(AConn: TUniConnection): string;
var
  bDir3Factura: Boolean;
  bDir3Cliente: Boolean;
begin
  bDir3Factura := ColumnasDir3Disponibles(AConn, 'fza_facturas', 'FAC');
  bDir3Cliente := ColumnasDir3Disponibles(AConn, 'fza_clientes', 'CLI');
  Result := ' SELECT f.* ';
  if bDir3Cliente then
  begin
    Result := Result +
      ', cli.CODIGO_OFICINA_CONTABLE_CLI AS CODIGO_OFICINA_CONTABLE_CLI ' +
      ', cli.CODIGO_ORGANO_GESTOR_CLI AS CODIGO_ORGANO_GESTOR_CLI ' +
      ', cli.CODIGO_UNIDAD_TRAMITADORA_CLI AS CODIGO_UNIDAD_TRAMITADORA_CLI ';
  end;
  if (not bDir3Factura) and bDir3Cliente then
  begin
    Result := Result +
      ', cli.CODIGO_OFICINA_CONTABLE_CLI AS CODIGO_OFICINA_CONTABLE_FAC ' +
      ', cli.CODIGO_ORGANO_GESTOR_CLI AS CODIGO_ORGANO_GESTOR_FAC ' +
      ', cli.CODIGO_UNIDAD_TRAMITADORA_CLI AS CODIGO_UNIDAD_TRAMITADORA_FAC ';
  end
  else if not bDir3Factura then
  begin
    Result := Result +
      ', '''' AS CODIGO_OFICINA_CONTABLE_FAC ' +
      ', '''' AS CODIGO_ORGANO_GESTOR_FAC ' +
      ', '''' AS CODIGO_UNIDAD_TRAMITADORA_FAC ';
  end;
  Result := Result + ' FROM fza_facturas f ';
  if bDir3Cliente then
  begin
    Result := Result +
      ' LEFT JOIN fza_clientes cli ' +
      ' ON cli.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC ';
  end;
  Result := Result +
    ' WHERE f.SERIE_FAC = :SERIE ' +
    ' AND f.NUMERO_FAC = :NUMERO ';
end;

function EmitirFacturae(AConn: TUniConnection;
                        const ASerie, ANumero, AArchivo: string):
                        TFacturaeResultado;
var
  QryCab: TUniQuery;
  QryLin: TUniQuery;
  DatosCert: TXadesDatosCertificado;
  Opciones: TXadesOpciones;
  sSerial: string;
  sTitular: string;
  sXmlBase: string;
  sXmlFirmado: string;
  sCarpeta: string;
begin
  if AConn = nil then
    raise Exception.Create('No hay conexion de base de datos para emitir eDoc.');
  if Trim(AArchivo) = '' then
    raise Exception.Create('No se ha indicado el fichero de salida eDoc.');
  QryCab := TUniQuery.Create(nil);
  QryLin := TUniQuery.Create(nil);
  try
    QryCab.Connection := AConn;
    QryCab.SQL.Text := SqlCabeceraFacturae(AConn);
    QryCab.ParamByName('SERIE').AsString := ASerie;
    QryCab.ParamByName('NUMERO').AsString := ANumero;
    QryCab.Open;
    QryLin.Connection := AConn;
    QryLin.SQL.Text :=
      ' SELECT * ' +
      ' FROM fza_facturas_lineas ' +
      ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
      '   AND NUMERO_FAC_FACLIN = :NUMERO ' +
      ' ORDER BY LINEA_FACLIN';
    QryLin.ParamByName('SERIE').AsString := ASerie;
    QryLin.ParamByName('NUMERO').AsString := ANumero;
    QryLin.Open;
    ValidarFactura(QryCab, QryLin);
    CargarCertificadoEmpresa(AConn,
      CampoStr(QryCab, 'CODIGO_EMP_FAC'), sSerial, sTitular);
    sXmlBase := ConstruirXmlFacturae(QryCab, QryLin);
    Opciones := OpcionesXadesFacturae(IdFacturaeSeguro(ASerie, ANumero));
    sXmlFirmado := FirmarXmlXadesEnveloped(sXmlBase, sSerial, sTitular,
      Opciones, DatosCert);
    sCarpeta := ExtractFileDir(AArchivo);
    if (sCarpeta <> '') and (not TDirectory.Exists(sCarpeta)) then
      TDirectory.CreateDirectory(sCarpeta);
    TFile.WriteAllText(AArchivo, sXmlFirmado, TEncoding.UTF8);
    GuardarXmlFactura(AConn, ASerie, ANumero, sXmlFirmado);
    Result.Archivo := AArchivo;
    Result.NumeroSerieCertificado := DatosCert.NumeroSerie;
    Result.TitularCertificado := DatosCert.Titular;
    Result.HuellaSha1Certificado := DatosCert.HuellaSha1;
  finally
    FreeAndNil(QryLin);
    FreeAndNil(QryCab);
  end;
end;

end.
