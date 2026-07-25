{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVerifactuNoVerifactuVerify                               }
{    Tipo:       Libreria                                                       }
{ Version:       1.0.0                                                          }
{   Fecha:       15/06/2026                                                     }
{   Autor:       Alejandro Laorden Hidalgo                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.      }
{                                                                              }
{  Descripcion:                                                                }
{    Verificacion local de ficheros NO VERI*FACTU exportados por Factuzam.      }
{    Comprueba estructura, cadena de eventos, hashes internos y coherencia      }
{    basica de firmas guardadas, sin invocar procesos externos.                 }
{******************************************************************************}
unit inLibVerifactuNoVerifactuVerify;

interface

uses
  System.SysUtils, inLibParametrosIntf;

type
  TResultadoVerificacionNoVerifactu = record
    ArchivoEventos:       string;
    ArchivoFacturacion:   string;
    ModoExportacion:      string;
    Eventos:              Integer;
    RegistrosFacturacion: Integer;
    Errores:              Integer;
    Avisos:               Integer;
    Detalle:              string;
  end;

procedure InferirFicherosNoVerifactu(const AArchivoSeleccionado: string;
                                     out AArchivoEventos,
                                     AArchivoFacturacion: string);
function VerificarFicherosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
function NombreInformeErroresNoVerifactu(const AArchivoSeleccionado: string):
                                      string;
function ResumenVerificacionNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AResultado: TResultadoVerificacionNoVerifactu): string;

implementation

uses
  System.Classes, System.Hash, System.IOUtils, System.NetEncoding,
  System.StrUtils, Xml.XMLDoc, Xml.XMLIntf, inLibVerifactu;

const
  cAlgC14n = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
  cAlgEnveloped = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
  cAlgRsaSha256 = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
  cAlgSha1 = 'http://www.w3.org/2000/09/xmldsig#sha1';
  cAlgSha256 = 'http://www.w3.org/2001/04/xmlenc#sha256';
  cTipoSignedProperties = 'http://uri.etsi.org/01903#SignedProperties';
  cPoliticaAeatId = 'urn:oid:2.16.724.1.3.1.1.2.1.9';
  cPoliticaAeatUrl =
    'https://sede.administracion.gob.es/politica_de_firma_anexo_1.pdf';
  cPoliticaAeatHashSha1 = 'G7roucf600+f03r/o0bAOQ6WAs0=';

function NombreLocal(const ANodeName: string): string;
var
  iPos: Integer;
begin
  Result := ANodeName;
  iPos := Pos(':', Result);
  if iPos > 0 then
    Result := Copy(Result, iPos + 1, MaxInt);
end;

function EsNodo(const ANode: IXMLNode; const ANombreLocal: string): Boolean;
begin
  Result := (ANode <> nil) and SameText(NombreLocal(ANode.NodeName),
                                        ANombreLocal);
end;

function BuscarHijo(const ANode: IXMLNode; const ANombreLocal: string):
  IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo;
      Inc(i);
    end;
  end;
end;

function BuscarDescendiente(const ANode: IXMLNode;
                            const ANombreLocal: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo
      else
        Result := BuscarDescendiente(oHijo, ANombreLocal);
      Inc(i);
    end;
  end;
end;

function AtributoNodo(const ANode: IXMLNode;
                      const ANombre: string): string;
var
  oAtributo: IXMLNode;
begin
  Result := '';
  if ANode <> nil then
  begin
    oAtributo := ANode.AttributeNodes.FindNode(ANombre);
    if oAtributo <> nil then
      Result := Trim(oAtributo.Text);
  end;
end;

procedure AgregarDetalle(var AResultado: TResultadoVerificacionNoVerifactu;
                         const ATipo, AMensaje: string); forward;

procedure CapturarModoExportacion(var AResultado:
                                  TResultadoVerificacionNoVerifactu;
                                  const ARaiz: IXMLNode;
                                  const AEtiqueta: string);
var
  sModo: string;
begin
  sModo := UpperCase(Trim(AtributoNodo(ARaiz, 'ModoVerifactu')));
  if sModo <> '' then
  begin
    if AResultado.ModoExportacion = '' then
      AResultado.ModoExportacion := sModo
    else if AResultado.ModoExportacion <> sModo then
      AgregarDetalle(AResultado, 'ERROR',
        AEtiqueta + ': ModoVerifactu no coincide con el otro fichero.');
  end;
end;

function BuscarHijoConAtributo(const ANode: IXMLNode; const ANombreLocal,
                               AAtributo, AValor: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) and
         SameText(AtributoNodo(oHijo, AAtributo), AValor) then
        Result := oHijo;
      Inc(i);
    end;
  end;
end;

function BuscarDescendienteConAtributo(const ANode: IXMLNode;
                                       const ANombreLocal, AAtributo,
                                       AValor: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) and
         SameText(AtributoNodo(oHijo, AAtributo), AValor) then
        Result := oHijo
      else
        Result := BuscarDescendienteConAtributo(oHijo, ANombreLocal,
          AAtributo, AValor);
      Inc(i);
    end;
  end;
end;

function BuscarRuta(const ANode: IXMLNode;
                    const ANombres: array of string): IXMLNode;
var
  i: Integer;
begin
  Result := ANode;
  i := Low(ANombres);
  while (Result <> nil) and (i <= High(ANombres)) do
  begin
    Result := BuscarHijo(Result, ANombres[i]);
    Inc(i);
  end;
end;

function TextoRuta(const ANode: IXMLNode;
                   const ANombres: array of string): string;
var
  oNodo: IXMLNode;
begin
  Result := '';
  oNodo := BuscarRuta(ANode, ANombres);
  if oNodo <> nil then
    Result := Trim(oNodo.Text);
end;

function ContarHijos(const ANode: IXMLNode; const ANombreLocal: string):
  Integer;
var
  i: Integer;
begin
  Result := 0;
  if ANode <> nil then
  begin
    for i := 0 to ANode.ChildNodes.Count - 1 do
      if EsNodo(ANode.ChildNodes[i], ANombreLocal) then
        Inc(Result);
  end;
end;

function TextoHijo(const ANode: IXMLNode; const ANombreLocal: string): string;
var
  oHijo: IXMLNode;
begin
  Result := '';
  oHijo := BuscarHijo(ANode, ANombreLocal);
  if oHijo <> nil then
    Result := Trim(oHijo.Text);
end;

function CargarXmlArchivo(const AArchivo: string): IXMLDocument;
begin
  Result := TXMLDocument.Create(nil);
  Result.LoadFromFile(AArchivo);
  Result.Active := True;
end;

function CargarXmlTexto(const AXml: string; out ADocumento: IXMLDocument):
  Boolean;
begin
  Result := False;
  ADocumento := nil;
  if Trim(AXml) <> '' then
  begin
    try
      ADocumento := TXMLDocument.Create(nil);
      ADocumento.LoadFromXML(AXml);
      ADocumento.Active := True;
      Result := True;
    except
      ADocumento := nil;
    end;
  end;
end;

function TextoEtiquetaXml(const AXml, ANombreLocal: string): string;
var
  oDoc: IXMLDocument;
  oNodo: IXMLNode;
begin
  Result := '';
  if CargarXmlTexto(AXml, oDoc) then
  begin
    oNodo := BuscarDescendiente(oDoc.DocumentElement, ANombreLocal);
    if oNodo <> nil then
      Result := Trim(oNodo.Text);
  end;
end;

function TextoHuellaEventoPropia(const AXml: string): string;
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oEvento: IXMLNode;
  oHuella: IXMLNode;
begin
  Result := '';
  if CargarXmlTexto(AXml, oDoc) then
  begin
    oRaiz := oDoc.DocumentElement;
    if EsNodo(oRaiz, 'RegistroEvento') then
      oEvento := BuscarHijo(oRaiz, 'Evento')
    else if EsNodo(oRaiz, 'Evento') then
      oEvento := oRaiz
    else
      oEvento := nil;
    oHuella := BuscarHijo(oEvento, 'HuellaEvento');
    if oHuella <> nil then
      Result := Trim(oHuella.Text);
  end;
end;

function VerificacionLegalNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AResultado:
                                      TResultadoVerificacionNoVerifactu):
                                      Boolean;
begin
  if AResultado.ModoExportacion <> '' then
    Result := AResultado.ModoExportacion = cModoVerifactuNoVerifactu
  else
    Result := NoVerifactuActivo(AParametrosApp);
end;

function TipoIncidenciaFirmaLegal(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  const AResultado:
                                  TResultadoVerificacionNoVerifactu): string;
begin
  if VerificacionLegalNoVerifactu(AParametrosApp, AResultado) then
    Result := 'ERROR'
  else
    Result := 'AVISO';
end;

function Sha256HexMayus(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(AValor));
end;

function HexABytes(const AHex: string): TBytes;
var
  i: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for i := 0 to Length(Result) - 1 do
    Result[i] := StrToIntDef('$' + Copy(AHex, (i * 2) + 1, 2), 0);
end;

function Sha256Base64(const AValor: string): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(
    HexABytes(THashSHA2.GetHashString(AValor)));
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function EsHashSha256(const AValor: string): Boolean;
var
  i: Integer;
  sValor: string;
begin
  sValor := UpperCase(Trim(AValor));
  Result := Length(sValor) = 64;
  i := 1;
  while Result and (i <= Length(sValor)) do
  begin
    Result := CharInSet(sValor[i], ['0'..'9', 'A'..'F']);
    Inc(i);
  end;
end;

function HayFirmaXml(const AXml: string): Boolean;
begin
  Result := (Pos('<ds:Signature', AXml) > 0) or
            (Pos('<Signature', AXml) > 0);
end;

procedure AgregarDetalle(var AResultado: TResultadoVerificacionNoVerifactu;
                         const ATipo, AMensaje: string);
begin
  if AResultado.Detalle <> '' then
    AResultado.Detalle := AResultado.Detalle + sLineBreak;
  AResultado.Detalle := AResultado.Detalle + ATipo + ': ' + AMensaje;
  if SameText(ATipo, 'ERROR') then
    Inc(AResultado.Errores)
  else
    Inc(AResultado.Avisos);
end;

procedure VerificarPerfilXadesNoVerifactu(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          const AXml, AEtiqueta: string;
                                          AEsEvento: Boolean;
                                          var AResultado:
                                          TResultadoVerificacionNoVerifactu);
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oNodoFirmado: IXMLNode;
  oFirma: IXMLNode;
  oSignedInfo: IXMLNode;
  oMetodo: IXMLNode;
  oReferenciaDocumento: IXMLNode;
  oReferenciaPropiedades: IXMLNode;
  oDigestMethod: IXMLNode;
  oPropiedades: IXMLNode;
  oPolitica: IXMLNode;
  sRaiz: string;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  if not CargarXmlTexto(AXml, oDoc) then
  begin
    AgregarDetalle(AResultado, sTipoFirma,
      AEtiqueta + ': el XML firmado no se puede leer.');
  end
  else
  begin
    oRaiz := oDoc.DocumentElement;
    sRaiz := NombreLocal(oRaiz.NodeName);
    oNodoFirmado := oRaiz;
    if AEsEvento then
    begin
      if not SameText(sRaiz, 'RegistroEvento') then
        AgregarDetalle(AResultado, sTipoFirma,
          AEtiqueta + ': la firma de evento debe envolver RegistroEvento.');
      oNodoFirmado := BuscarHijo(oRaiz, 'Evento');
      if oNodoFirmado = nil then
        AgregarDetalle(AResultado, sTipoFirma,
          AEtiqueta + ': falta el nodo Evento firmado.');
    end
    else if (not SameText(sRaiz, 'RegistroAlta')) and
            (not SameText(sRaiz, 'RegistroAnulacion')) then
      AgregarDetalle(AResultado, sTipoFirma,
        AEtiqueta + ': la firma debe envolver RegistroAlta o ' +
        'RegistroAnulacion.');
    oFirma := BuscarHijo(oNodoFirmado, 'Signature');
    if oFirma = nil then
      AgregarDetalle(AResultado, sTipoFirma,
        AEtiqueta + ': la firma XAdES no esta en el nodo exigido por AEAT.')
    else
    begin
      if BuscarDescendiente(oFirma, 'X509Certificate') = nil then
        AgregarDetalle(AResultado, sTipoFirma,
          AEtiqueta + ': falta certificado X509 en KeyInfo.');
      oSignedInfo := BuscarHijo(oFirma, 'SignedInfo');
      if oSignedInfo = nil then
        AgregarDetalle(AResultado, sTipoFirma,
          AEtiqueta + ': falta SignedInfo.')
      else
      begin
        oMetodo := BuscarHijo(oSignedInfo, 'CanonicalizationMethod');
        if AtributoNodo(oMetodo, 'Algorithm') <> cAlgC14n then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': CanonicalizationMethod no coincide con AEAT.');
        oMetodo := BuscarHijo(oSignedInfo, 'SignatureMethod');
        if AtributoNodo(oMetodo, 'Algorithm') <> cAlgRsaSha256 then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': SignatureMethod debe ser RSA-SHA256.');
        if ContarHijos(oSignedInfo, 'Reference') <> 2 then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': SignedInfo debe tener referencia al documento y ' +
            'a SignedProperties.');
        oReferenciaDocumento := BuscarHijoConAtributo(oSignedInfo,
          'Reference', 'URI', '');
        if oReferenciaDocumento = nil then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': falta Reference URI vacio al registro firmado.')
        else
        begin
          if BuscarDescendienteConAtributo(oReferenciaDocumento, 'Transform',
             'Algorithm', cAlgEnveloped) = nil then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': falta transform enveloped-signature.');
          oDigestMethod := BuscarDescendiente(oReferenciaDocumento,
            'DigestMethod');
          if AtributoNodo(oDigestMethod, 'Algorithm') <> cAlgSha256 then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': digest del registro debe ser SHA-256.');
        end;
        oReferenciaPropiedades := BuscarHijoConAtributo(oSignedInfo,
          'Reference', 'Type', cTipoSignedProperties);
        if oReferenciaPropiedades = nil then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': falta Reference a SignedProperties.')
        else
        begin
          if BuscarDescendienteConAtributo(oReferenciaPropiedades,
             'Transform', 'Algorithm', cAlgC14n) = nil then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': SignedProperties no usa canonicalizacion AEAT.');
          oDigestMethod := BuscarDescendiente(oReferenciaPropiedades,
            'DigestMethod');
          if AtributoNodo(oDigestMethod, 'Algorithm') <> cAlgSha256 then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': digest de SignedProperties debe ser SHA-256.');
        end;
      end;
      oPropiedades := BuscarDescendiente(oFirma, 'QualifyingProperties');
      if oPropiedades = nil then
        AgregarDetalle(AResultado, sTipoFirma,
          AEtiqueta + ': falta QualifyingProperties XAdES.')
      else
      begin
        if BuscarDescendiente(oPropiedades, 'SignedProperties') = nil then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': falta SignedProperties XAdES.');
        if BuscarDescendiente(oPropiedades, 'SigningCertificate') = nil then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': falta SigningCertificate.');
        oPolitica := BuscarRuta(oPropiedades,
          ['SignedProperties', 'SignedSignatureProperties',
           'SignaturePolicyIdentifier', 'SignaturePolicyId']);
        if oPolitica = nil then
          AgregarDetalle(AResultado, sTipoFirma,
            AEtiqueta + ': falta politica de firma AGE.')
        else
        begin
          if TextoRuta(oPolitica, ['SigPolicyId', 'Identifier']) <>
             cPoliticaAeatId then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': identificador de politica AGE incorrecto.');
          oDigestMethod := BuscarRuta(oPolitica,
            ['SigPolicyHash', 'DigestMethod']);
          if AtributoNodo(oDigestMethod, 'Algorithm') <> cAlgSha1 then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': digest de politica AGE debe ser SHA-1.');
          if TextoRuta(oPolitica, ['SigPolicyHash', 'DigestValue']) <>
             cPoliticaAeatHashSha1 then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': DigestValue de politica AGE incorrecto.');
          if TextoRuta(oPolitica, ['SigPolicyQualifiers',
             'SigPolicyQualifier', 'SPURI']) <> cPoliticaAeatUrl then
            AgregarDetalle(AResultado, sTipoFirma,
              AEtiqueta + ': URL de politica AGE incorrecta.');
        end;
      end;
    end;
  end;
end;

procedure VerificarEvento(
                          const AParametrosApp: IParametrosAplicacion;
                          const AEvento: IXMLNode; AIndice: Integer;
                          var AHashAnteriorEsperado: string;
                          var AResultado:
                          TResultadoVerificacionNoVerifactu);
var
  sId: string;
  sHashAnterior: string;
  sHashPropio: string;
  sFirmaDigital: string;
  sRegistroXml: string;
  sFirmaXades: string;
  sHuellaXml: string;
  sSignatureValue: string;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  sId := TextoHijo(AEvento, 'Id');
  sHashAnterior := UpperCase(TextoHijo(AEvento, 'HashAnterior'));
  sHashPropio := UpperCase(TextoHijo(AEvento, 'HashPropio'));
  sFirmaDigital := UpperCase(TextoHijo(AEvento, 'FirmaDigital'));
  sRegistroXml := TextoHijo(AEvento, 'RegistroXmlFirmado');
  sFirmaXades := TextoHijo(AEvento, 'FirmaXades');
  if not EsHashSha256(sHashPropio) then
    AgregarDetalle(AResultado, 'ERROR',
      'Evento ' + sId + ': HashPropio no es SHA-256 hexadecimal.');
  if AIndice = 1 then
  begin
    if (sHashAnterior <> '') and
       (sHashAnterior <> StringOfChar('0', 64)) then
      AgregarDetalle(AResultado, 'AVISO',
        'Evento ' + sId + ': primer HashAnterior no es cero.');
  end
  else if sHashAnterior <> AHashAnteriorEsperado then
    AgregarDetalle(AResultado, 'ERROR',
      'Evento ' + sId + ': HashAnterior no coincide con el evento anterior.');
  if Trim(sRegistroXml) = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      'Evento ' + sId + ': falta RegistroXmlFirmado.')
  else
  begin
    sHuellaXml := UpperCase(TextoHuellaEventoPropia(sRegistroXml));
    if (sHuellaXml <> '') and (sHuellaXml <> sHashPropio) then
      AgregarDetalle(AResultado, 'ERROR',
        'Evento ' + sId + ': HuellaEvento no coincide con HashPropio.');
    if (sFirmaXades <> '') and (not HayFirmaXml(sRegistroXml)) then
      AgregarDetalle(AResultado, sTipoFirma,
        'Evento ' + sId + ': hay FirmaXades pero el XML no contiene firma.');
    if sFirmaXades = '' then
      AgregarDetalle(AResultado, sTipoFirma,
        'Evento ' + sId + ': falta FirmaXades legal.')
    else
    begin
      sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
      if (sSignatureValue <> '') and (sSignatureValue <> sFirmaXades) then
        AgregarDetalle(AResultado, 'ERROR',
          'Evento ' + sId + ': SignatureValue no coincide con FirmaXades.');
      if (sFirmaDigital <> '') and
         (sFirmaDigital <> Sha256HexMayus(sFirmaXades)) then
        AgregarDetalle(AResultado, 'ERROR',
          'Evento ' + sId + ': FirmaDigital no coincide con FirmaXades.');
      VerificarPerfilXadesNoVerifactu(AParametrosApp, sRegistroXml,
        'Evento ' + sId, True, AResultado);
    end;
  end;
  AHashAnteriorEsperado := sHashPropio;
end;

procedure VerificarRegistroFactura(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   const ARegistro: IXMLNode; AIndice:
                                   Integer; var AResultado:
                                   TResultadoVerificacionNoVerifactu);
var
  sSerie: string;
  sNumero: string;
  sEtiqueta: string;
  sPeticion: string;
  sRegistroXml: string;
  sHashPeticion: string;
  sHashRegistro: string;
  sFirma: string;
  sSignatureValue: string;
  sTipoFirma: string;
begin
  sTipoFirma := TipoIncidenciaFirmaLegal(AParametrosApp, AResultado);
  sSerie := TextoHijo(ARegistro, 'Serie');
  sNumero := TextoHijo(ARegistro, 'Numero');
  sEtiqueta := sSerie + '/' + sNumero;
  if Trim(sEtiqueta) = '/' then
    sEtiqueta := 'registro ' + IntToStr(AIndice);
  sPeticion := TextoHijo(ARegistro, 'PeticionCompletaXml');
  sRegistroXml := TextoHijo(ARegistro, 'RegistroXmlFirmado');
  sHashPeticion := TextoHijo(ARegistro, 'HashPeticionBase64');
  sHashRegistro := TextoHijo(ARegistro, 'HashRegistroXmlBase64');
  sFirma := TextoHijo(ARegistro, 'FirmaDigitalXades');
  if sPeticion = '' then
    AgregarDetalle(AResultado, 'AVISO',
      'Factura ' + sEtiqueta + ': no incluye PeticionCompletaXml.')
  else if sHashPeticion <> Sha256Base64(sPeticion) then
    AgregarDetalle(AResultado, 'ERROR',
      'Factura ' + sEtiqueta + ': HashPeticionBase64 no coincide.');
  if sRegistroXml = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      'Factura ' + sEtiqueta + ': falta RegistroXmlFirmado.')
  else if sHashRegistro <> Sha256Base64(sRegistroXml) then
    AgregarDetalle(AResultado, 'ERROR',
      'Factura ' + sEtiqueta + ': HashRegistroXmlBase64 no coincide.');
  if (sFirma <> '') and (not HayFirmaXml(sRegistroXml)) then
    AgregarDetalle(AResultado, sTipoFirma,
      'Factura ' + sEtiqueta + ': hay firma guardada pero el XML no firma.');
  if sFirma = '' then
    AgregarDetalle(AResultado, sTipoFirma,
      'Factura ' + sEtiqueta + ': falta FirmaDigitalXades legal.')
  else
  begin
    sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
    if (sSignatureValue <> '') and (sSignatureValue <> sFirma) then
      AgregarDetalle(AResultado, 'ERROR',
        'Factura ' + sEtiqueta + ': SignatureValue no coincide.');
    VerificarPerfilXadesNoVerifactu(AParametrosApp, sRegistroXml,
      'Factura ' + sEtiqueta, False, AResultado);
  end;
end;

procedure VerificarArchivoEventos(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  var AResultado:
                                  TResultadoVerificacionNoVerifactu);
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oNodo: IXMLNode;
  sHashAnterior: string;
  i: Integer;
begin
  if not TFile.Exists(AResultado.ArchivoEventos) then
    AgregarDetalle(AResultado, 'ERROR',
      'No existe el fichero de eventos: ' + AResultado.ArchivoEventos)
  else
  begin
    oDoc := CargarXmlArchivo(AResultado.ArchivoEventos);
    oRaiz := oDoc.DocumentElement;
    CapturarModoExportacion(AResultado, oRaiz, 'Eventos');
    if not EsNodo(oRaiz, 'RegistroEventosNoVerifactu') then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de eventos no tiene la raiz esperada.');
    sHashAnterior := '';
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'Evento') then
      begin
        Inc(AResultado.Eventos);
        VerificarEvento(AParametrosApp, oNodo, AResultado.Eventos,
          sHashAnterior, AResultado);
      end;
    end;
    if AResultado.Eventos = 0 then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de eventos no contiene eventos.');
  end;
end;

procedure VerificarArchivoFacturacion(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      var AResultado:
                                      TResultadoVerificacionNoVerifactu);
var
  oDoc: IXMLDocument;
  oRaiz: IXMLNode;
  oNodo: IXMLNode;
  i: Integer;
begin
  if not TFile.Exists(AResultado.ArchivoFacturacion) then
    AgregarDetalle(AResultado, 'ERROR',
      'No existe el fichero de facturacion: ' +
      AResultado.ArchivoFacturacion)
  else
  begin
    oDoc := CargarXmlArchivo(AResultado.ArchivoFacturacion);
    oRaiz := oDoc.DocumentElement;
    CapturarModoExportacion(AResultado, oRaiz, 'Facturacion');
    if not EsNodo(oRaiz, 'RegistroFacturacionNoVerifactu') then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de facturacion no tiene la raiz esperada.');
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'RegistroFactura') then
      begin
        Inc(AResultado.RegistrosFacturacion);
        VerificarRegistroFactura(AParametrosApp, oNodo,
          AResultado.RegistrosFacturacion, AResultado);
      end;
    end;
    if AResultado.RegistrosFacturacion = 0 then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de facturacion no contiene registros.');
  end;
end;

procedure InferirFicherosNoVerifactu(const AArchivoSeleccionado: string;
                                     out AArchivoEventos,
                                     AArchivoFacturacion: string);
var
  sDir: string;
  sNombre: string;
  sBase: string;
begin
  sDir := TPath.GetDirectoryName(AArchivoSeleccionado);
  sNombre := TPath.GetFileNameWithoutExtension(AArchivoSeleccionado);
  if EndsText('_eventos', sNombre) then
    sBase := Copy(sNombre, 1, Length(sNombre) - Length('_eventos'))
  else if EndsText('_facturacion', sNombre) then
    sBase := Copy(sNombre, 1, Length(sNombre) - Length('_facturacion'))
  else
    sBase := sNombre;
  AArchivoEventos := TPath.Combine(sDir, sBase + '_eventos.xml');
  AArchivoFacturacion := TPath.Combine(sDir, sBase + '_facturacion.xml');
end;

function NombreInformeErroresNoVerifactu(const AArchivoSeleccionado: string):
  string;
var
  sDir: string;
  sNombre: string;
begin
  sDir := TPath.GetDirectoryName(AArchivoSeleccionado);
  sNombre := TPath.GetFileName(AArchivoSeleccionado);
  Result := TPath.Combine(sDir, 'errores_' + sNombre + '.txt');
end;

function VerificarFicherosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
begin
  Result.ArchivoEventos := AArchivoEventos;
  Result.ArchivoFacturacion := AArchivoFacturacion;
  Result.ModoExportacion := '';
  Result.Eventos := 0;
  Result.RegistrosFacturacion := 0;
  Result.Errores := 0;
  Result.Avisos := 0;
  Result.Detalle := '';
  try
    VerificarArchivoEventos(AParametrosApp, Result);
  except
    on E: Exception do
      AgregarDetalle(Result, 'ERROR',
        'No se pudo verificar eventos: ' + E.Message);
  end;
  try
    VerificarArchivoFacturacion(AParametrosApp, Result);
  except
    on E: Exception do
      AgregarDetalle(Result, 'ERROR',
        'No se pudo verificar facturacion: ' + E.Message);
  end;
  if Result.Detalle = '' then
    Result.Detalle := 'Verificacion correcta.';
end;

function ResumenVerificacionNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AResultado: TResultadoVerificacionNoVerifactu): string;
var
  sModo: string;
begin
  sModo := AResultado.ModoExportacion;
  if sModo = '' then
    sModo := ModoVerifactuTexto(AParametrosApp) + ' (modo actual)';
  Result :=
    'Modo: ' + sModo + sLineBreak +
    'Eventos: ' + IntToStr(AResultado.Eventos) + sLineBreak +
    'Registros de facturacion: ' +
    IntToStr(AResultado.RegistrosFacturacion) + sLineBreak +
    'Errores: ' + IntToStr(AResultado.Errores) + sLineBreak +
    'Avisos: ' + IntToStr(AResultado.Avisos);
end;

end.
