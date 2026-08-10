{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasVerificacionXadesNoVerifactu                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza las causas de rechazo del perfil XAdES NO VERI*FACTU.         }
{******************************************************************************}
unit PruebasVerificacionXadesNoVerifactu;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasVerificacionXadesNoVerifactu = class
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Liberar;
    [Test]
    procedure XmlVacio_DevuelveCausaTipadaYMensajeOriginal;
    [Test]
    procedure XmlMalFormado_DevuelveCausaTipada;
    [Test]
    procedure PerfilFacturaCompleto_EsValido;
    [Test]
    procedure PerfilEventoCompleto_EsValido;
    [Test]
    procedure EventoSinEnvoltura_ConservaOrdenDeCausas;
    [Test]
    procedure FirmaVacia_DevuelveAusenciasTipadas;
    [Test]
    procedure MetodoFirmaIncorrecto_IdentificaLaCausa;
  end;

implementation

uses
  System.SysUtils, Winapi.ActiveX,
  inLibVerificacionXadesNoVerifactu;

const
  cCanonicalizacion =
    'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
  cFirmaRsaSha256 =
    'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
  cDigestSha256 = 'http://www.w3.org/2001/04/xmlenc#sha256';
  cDigestSha1 = 'http://www.w3.org/2000/09/xmldsig#sha1';
  cTransformacionEnveloped =
    'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
  cTipoSignedProperties = 'http://uri.etsi.org/01903#SignedProperties';
  cPoliticaId = 'urn:oid:2.16.724.1.3.1.1.2.1.9';
  cPoliticaHash = 'G7roucf600+f03r/o0bAOQ6WAs0=';
  cPoliticaUrl =
    'https://sede.administracion.gob.es/politica_de_firma_anexo_1.pdf';
  cFirmaValida =
    '<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ' +
    'xmlns:xades="http://uri.etsi.org/01903/v1.3.2#">' +
    '<ds:SignedInfo>' +
    '<ds:CanonicalizationMethod Algorithm="' + cCanonicalizacion + '"/>' +
    '<ds:SignatureMethod Algorithm="' + cFirmaRsaSha256 + '"/>' +
    '<ds:Reference URI="">' +
    '<ds:Transforms><ds:Transform Algorithm="' +
    cTransformacionEnveloped + '"/></ds:Transforms>' +
    '<ds:DigestMethod Algorithm="' + cDigestSha256 + '"/>' +
    '</ds:Reference>' +
    '<ds:Reference URI="#props" Type="' + cTipoSignedProperties + '">' +
    '<ds:Transforms><ds:Transform Algorithm="' + cCanonicalizacion +
    '"/></ds:Transforms>' +
    '<ds:DigestMethod Algorithm="' + cDigestSha256 + '"/>' +
    '</ds:Reference>' +
    '</ds:SignedInfo>' +
    '<ds:KeyInfo><ds:X509Data><ds:X509Certificate>CERT' +
    '</ds:X509Certificate></ds:X509Data></ds:KeyInfo>' +
    '<ds:Object><xades:QualifyingProperties>' +
    '<xades:SignedProperties Id="props">' +
    '<xades:SignedSignatureProperties>' +
    '<xades:SigningCertificate>CERT</xades:SigningCertificate>' +
    '<xades:SignaturePolicyIdentifier><xades:SignaturePolicyId>' +
    '<xades:SigPolicyId><xades:Identifier>' + cPoliticaId +
    '</xades:Identifier></xades:SigPolicyId>' +
    '<xades:SigPolicyHash><ds:DigestMethod Algorithm="' + cDigestSha1 +
    '"/><ds:DigestValue>' + cPoliticaHash + '</ds:DigestValue>' +
    '</xades:SigPolicyHash>' +
    '<xades:SigPolicyQualifiers><xades:SigPolicyQualifier>' +
    '<xades:SPURI>' + cPoliticaUrl + '</xades:SPURI>' +
    '</xades:SigPolicyQualifier></xades:SigPolicyQualifiers>' +
    '</xades:SignaturePolicyId></xades:SignaturePolicyIdentifier>' +
    '</xades:SignedSignatureProperties></xades:SignedProperties>' +
    '</xades:QualifyingProperties></ds:Object></ds:Signature>';

function XmlFacturaValida: string;
begin
  Result := '<RegistroAlta>' + cFirmaValida + '</RegistroAlta>';
end;

function XmlEventoValido: string;
begin
  Result := '<RegistroEvento><Evento>' + cFirmaValida +
    '</Evento></RegistroEvento>';
end;

procedure ComprobarCausa(
  const AResultado: TResultadoPerfilXadesNoVerifactu;
  AIndice: Integer;
  ACausa: TCausaRechazoXadesNoVerifactu);
begin
  Assert.AreEqual(Ord(ACausa), Ord(AResultado.Causas[AIndice]));
end;

procedure TPruebasVerificacionXadesNoVerifactu.Preparar;
begin
  CoInitialize(nil);
end;

procedure TPruebasVerificacionXadesNoVerifactu.Liberar;
begin
  CoUninitialize;
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  XmlVacio_DevuelveCausaTipadaYMensajeOriginal;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
  sMensaje: string;
begin
  oResultado := VerificarPerfilXadesNoVerifactu('', False);
  Assert.AreEqual(1, Integer(Length(oResultado.Causas)));
  ComprobarCausa(oResultado, 0, crxXmlNoLegible);
  sMensaje := MensajeRechazoXadesNoVerifactu(
    oResultado.Causas[0], 'Factura A/1');
  Assert.AreEqual(
    'Factura A/1: el XML firmado no se puede leer.', sMensaje);
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  XmlMalFormado_DevuelveCausaTipada;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
begin
  oResultado := VerificarPerfilXadesNoVerifactu('<RegistroAlta>', False);
  Assert.AreEqual(1, Integer(Length(oResultado.Causas)));
  Assert.IsTrue(oResultado.Contiene(crxXmlNoLegible));
  Assert.IsFalse(oResultado.EsValido);
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  PerfilFacturaCompleto_EsValido;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
begin
  oResultado := VerificarPerfilXadesNoVerifactu(XmlFacturaValida, False);
  Assert.IsTrue(oResultado.EsValido);
  Assert.AreEqual(0, Integer(Length(oResultado.Causas)));
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  PerfilEventoCompleto_EsValido;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
begin
  oResultado := VerificarPerfilXadesNoVerifactu(XmlEventoValido, True);
  Assert.IsTrue(oResultado.EsValido);
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  EventoSinEnvoltura_ConservaOrdenDeCausas;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
begin
  oResultado := VerificarPerfilXadesNoVerifactu('<Evento/>', True);
  Assert.AreEqual(3, Integer(Length(oResultado.Causas)));
  ComprobarCausa(oResultado, 0, crxRaizEventoIncorrecta);
  ComprobarCausa(oResultado, 1, crxEventoFirmadoAusente);
  ComprobarCausa(oResultado, 2, crxFirmaAusente);
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  FirmaVacia_DevuelveAusenciasTipadas;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
begin
  oResultado := VerificarPerfilXadesNoVerifactu(
    '<RegistroAlta><Signature/></RegistroAlta>', False);
  Assert.AreEqual(3, Integer(Length(oResultado.Causas)));
  ComprobarCausa(oResultado, 0, crxCertificadoAusente);
  ComprobarCausa(oResultado, 1, crxSignedInfoAusente);
  ComprobarCausa(oResultado, 2, crxQualifyingPropertiesAusente);
end;

procedure TPruebasVerificacionXadesNoVerifactu.
  MetodoFirmaIncorrecto_IdentificaLaCausa;
var
  oResultado: TResultadoPerfilXadesNoVerifactu;
  sXml: string;
begin
  sXml := StringReplace(XmlFacturaValida, cFirmaRsaSha256,
    'urn:algoritmo-incorrecto', []);
  oResultado := VerificarPerfilXadesNoVerifactu(sXml, False);
  Assert.AreEqual(1, Integer(Length(oResultado.Causas)));
  ComprobarCausa(oResultado, 0, crxMetodoFirmaIncorrecto);
  Assert.AreEqual(
    'Factura A/1: SignatureMethod debe ser RSA-SHA256.',
    MensajeRechazoXadesNoVerifactu(
      oResultado.Causas[0], 'Factura A/1'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasVerificacionXadesNoVerifactu);

end.
