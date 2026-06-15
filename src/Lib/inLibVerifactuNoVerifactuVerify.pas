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
  System.SysUtils;

type
  TResultadoVerificacionNoVerifactu = record
    ArchivoEventos:       string;
    ArchivoFacturacion:   string;
    Eventos:              Integer;
    RegistrosFacturacion: Integer;
    Errores:              Integer;
    Avisos:               Integer;
    Detalle:              string;
  end;

procedure InferirFicherosNoVerifactu(const AArchivoSeleccionado: string;
                                     out AArchivoEventos,
                                     AArchivoFacturacion: string);
function VerificarFicherosNoVerifactu(const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
function NombreInformeErroresNoVerifactu(const AArchivoSeleccionado: string):
                                      string;
function ResumenVerificacionNoVerifactu(
  const AResultado: TResultadoVerificacionNoVerifactu): string;

implementation

uses
  System.Classes, System.Hash, System.IOUtils, System.NetEncoding,
  System.StrUtils, Xml.XMLDoc, Xml.XMLIntf;

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

procedure VerificarEvento(const AEvento: IXMLNode; AIndice: Integer;
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
begin
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
    AgregarDetalle(AResultado, 'ERROR',
      'Evento ' + sId + ': falta RegistroXmlFirmado.')
  else
  begin
    sHuellaXml := UpperCase(TextoEtiquetaXml(sRegistroXml, 'HuellaEvento'));
    if (sHuellaXml <> '') and (sHuellaXml <> sHashPropio) then
      AgregarDetalle(AResultado, 'ERROR',
        'Evento ' + sId + ': HuellaEvento no coincide con HashPropio.');
    if (sFirmaXades <> '') and (not HayFirmaXml(sRegistroXml)) then
      AgregarDetalle(AResultado, 'ERROR',
        'Evento ' + sId + ': hay FirmaXades pero el XML no contiene firma.');
    if sFirmaXades <> '' then
    begin
      sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
      if (sSignatureValue <> '') and (sSignatureValue <> sFirmaXades) then
        AgregarDetalle(AResultado, 'ERROR',
          'Evento ' + sId + ': SignatureValue no coincide con FirmaXades.');
      if (sFirmaDigital <> '') and
         (sFirmaDigital <> Sha256HexMayus(sFirmaXades)) then
        AgregarDetalle(AResultado, 'ERROR',
          'Evento ' + sId + ': FirmaDigital no coincide con FirmaXades.');
    end
    else if (sFirmaDigital <> '') and (sFirmaDigital <> sHashPropio) then
      AgregarDetalle(AResultado, 'ERROR',
        'Evento ' + sId + ': FirmaDigital no coincide con HashPropio.');
  end;
  AHashAnteriorEsperado := sHashPropio;
end;

procedure VerificarRegistroFactura(const ARegistro: IXMLNode; AIndice:
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
begin
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
    AgregarDetalle(AResultado, 'ERROR',
      'Factura ' + sEtiqueta + ': falta RegistroXmlFirmado.')
  else if sHashRegistro <> Sha256Base64(sRegistroXml) then
    AgregarDetalle(AResultado, 'ERROR',
      'Factura ' + sEtiqueta + ': HashRegistroXmlBase64 no coincide.');
  if (sFirma <> '') and (not HayFirmaXml(sRegistroXml)) then
    AgregarDetalle(AResultado, 'ERROR',
      'Factura ' + sEtiqueta + ': hay firma guardada pero el XML no firma.');
  if sFirma <> '' then
  begin
    sSignatureValue := TextoEtiquetaXml(sRegistroXml, 'SignatureValue');
    if (sSignatureValue <> '') and (sSignatureValue <> sFirma) then
      AgregarDetalle(AResultado, 'ERROR',
        'Factura ' + sEtiqueta + ': SignatureValue no coincide.');
  end;
end;

procedure VerificarArchivoEventos(var AResultado:
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
    if not EsNodo(oRaiz, 'RegistroEventosNoVerifactu') then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de eventos no tiene la raiz esperada.');
    if BuscarHijo(oRaiz, 'Signature') = nil then
      AgregarDetalle(AResultado, 'AVISO',
        'El fichero de eventos no contiene firma XAdES de exportacion.');
    sHashAnterior := '';
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'Evento') then
      begin
        Inc(AResultado.Eventos);
        VerificarEvento(oNodo, AResultado.Eventos, sHashAnterior,
                        AResultado);
      end;
    end;
    if AResultado.Eventos = 0 then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de eventos no contiene eventos.');
  end;
end;

procedure VerificarArchivoFacturacion(var AResultado:
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
    if not EsNodo(oRaiz, 'RegistroFacturacionNoVerifactu') then
      AgregarDetalle(AResultado, 'ERROR',
        'El fichero de facturacion no tiene la raiz esperada.');
    if BuscarHijo(oRaiz, 'Signature') = nil then
      AgregarDetalle(AResultado, 'AVISO',
        'El fichero de facturacion no contiene firma XAdES de exportacion.');
    for i := 0 to oRaiz.ChildNodes.Count - 1 do
    begin
      oNodo := oRaiz.ChildNodes[i];
      if EsNodo(oNodo, 'RegistroFactura') then
      begin
        Inc(AResultado.RegistrosFacturacion);
        VerificarRegistroFactura(oNodo, AResultado.RegistrosFacturacion,
                                 AResultado);
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

function VerificarFicherosNoVerifactu(const AArchivoEventos,
                                      AArchivoFacturacion: string):
                                      TResultadoVerificacionNoVerifactu;
begin
  Result.ArchivoEventos := AArchivoEventos;
  Result.ArchivoFacturacion := AArchivoFacturacion;
  Result.Eventos := 0;
  Result.RegistrosFacturacion := 0;
  Result.Errores := 0;
  Result.Avisos := 0;
  Result.Detalle := '';
  try
    VerificarArchivoEventos(Result);
  except
    on E: Exception do
      AgregarDetalle(Result, 'ERROR',
        'No se pudo verificar eventos: ' + E.Message);
  end;
  try
    VerificarArchivoFacturacion(Result);
  except
    on E: Exception do
      AgregarDetalle(Result, 'ERROR',
        'No se pudo verificar facturacion: ' + E.Message);
  end;
  if Result.Detalle = '' then
    Result.Detalle := 'Verificacion correcta.';
end;

function ResumenVerificacionNoVerifactu(
  const AResultado: TResultadoVerificacionNoVerifactu): string;
begin
  Result :=
    'Eventos: ' + IntToStr(AResultado.Eventos) + sLineBreak +
    'Registros de facturacion: ' +
    IntToStr(AResultado.RegistrosFacturacion) + sLineBreak +
    'Errores: ' + IntToStr(AResultado.Errores) + sLineBreak +
    'Avisos: ' + IntToStr(AResultado.Avisos);
end;

end.
