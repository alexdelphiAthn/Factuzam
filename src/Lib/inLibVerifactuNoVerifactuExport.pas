{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVerifactuNoVerifactuExport                               }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       15/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exportacion local de registros NO VERI*FACTU: eventos y facturacion.      }
{    Empaqueta los XML oficiales firmados al crear cada registro.              }
{******************************************************************************}
unit inLibVerifactuNoVerifactuExport;

interface

uses
  System.SysUtils, Uni;

type
  TResultadoExportacionNoVerifactu = record
    ArchivoEventos:     string;
    ArchivoFacturacion: string;
    Eventos:            Integer;
    RegistrosFactura:   Integer;
    TitularCertificado: string;
    SerieCertificado:   string;
  end;

function ExportarRegistrosNoVerifactu(AConn: TUniConnection;
                                      const AUsuario: string;
                                      const AArchivoBase: string):
                                      TResultadoExportacionNoVerifactu;

implementation

uses
  System.Classes, System.IOUtils, System.Hash, System.NetEncoding, Data.DB,
  DBAccess, inLibGlobalVar, inLibVerifactu;

const
  cNsFactuzamNoVerifactu = 'urn:factuzam:no-verifactu:v1';

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function ValorCampo(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsString;
end;

function ValorFechaIso(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', oCampo.AsDateTime);
end;

function CDataXml(const AValor: string): string;
begin
  Result := '<![CDATA[' +
            StringReplace(AValor, ']]>', ']]]]><![CDATA[>',
                          [rfReplaceAll]) +
            ']]>';
end;

procedure AgregarEtiqueta(ASb: TStringBuilder; const ANombre,
                          AValor: string);
begin
  ASb.Append('<fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
  ASb.Append(EscaparXml(AValor));
  ASb.Append('</fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
end;

procedure AgregarEtiquetaCData(ASb: TStringBuilder; const ANombre,
                               AValor: string);
begin
  ASb.Append('<fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
  ASb.Append(CDataXml(AValor));
  ASb.Append('</fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
end;

function Sha256Base64(const AValor: string): string;
var
  aHash: TBytes;
  sHex: string;
  i: Integer;
begin
  sHex := THashSHA2.GetHashString(AValor);
  SetLength(aHash, Length(sHex) div 2);
  for i := 0 to Length(aHash) - 1 do
    aHash[i] := StrToIntDef('$' + Copy(sHex, (i * 2) + 1, 2), 0);
  Result := TNetEncoding.Base64.EncodeBytesToString(aHash);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function FechaHoraExportacion: string;
begin
  Result := FormatDateTime('yyyymmdd_hhnnss', Now);
end;

function FechaHoraIsoAhora: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now);
end;

function ColumnasFirmaEventosDisponibles(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_verifactu_eventos'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_LOG'', ' +
      '       ''FIRMA_XADES_LOG'', ''SERIE_CERTIFICADO_LOG'', ' +
      '       ''TITULAR_CERTIFICADO_LOG'', ''HUELLA_CERTIFICADO_LOG'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;

function ColumnasFirmaFacturacionDisponibles(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_facturas_consolidaciones'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_FACCON'', ' +
      '       ''FIRMA_DIGITAL_FACCON'', ''SERIE_CERTIFICADO_FACCON'', ' +
      '       ''TITULAR_CERTIFICADO_FACCON'', ' +
      '       ''HUELLA_CERTIFICADO_FACCON'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;

function ContarEventosSinFirma(AConn: TUniConnection): Integer;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM fza_verifactu_eventos ' +
      ' WHERE IFNULL(REGISTRO_XML_LOG, '''') = '''' ' +
      '    OR IFNULL(FIRMA_DIGITAL_LOG, '''') = '''' ' +
      '    OR IFNULL(FIRMA_XADES_LOG, '''') = '''' ' +
      '    OR IFNULL(SERIE_CERTIFICADO_LOG, '''') = '''' ' +
      '    OR IFNULL(TITULAR_CERTIFICADO_LOG, '''') = '''' ' +
      '    OR IFNULL(HUELLA_CERTIFICADO_LOG, '''') = '''' ';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Qry);
  end;
end;

function ContarFacturasSinFirma(AConn: TUniConnection): Integer;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM fza_facturas_consolidaciones ' +
      ' WHERE IFNULL(REGISTRO_XML_FACCON, '''') = '''' ' +
      '    OR IFNULL(FIRMA_DIGITAL_FACCON, '''') = '''' ' +
      '    OR IFNULL(SERIE_CERTIFICADO_FACCON, '''') = '''' ' +
      '    OR IFNULL(TITULAR_CERTIFICADO_FACCON, '''') = '''' ' +
      '    OR IFNULL(HUELLA_CERTIFICADO_FACCON, '''') = '''' ';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure RegistrarIncidenciaExportacionSeguro(AConn: TUniConnection;
                                               const AUsuario: string;
                                               const AMensaje: string);
begin
  try
    RegistrarEventoVerifactu(AConn, AUsuario,
      cEventoNoVerifactuIncidenciaCert,
      'Exportación NO VERI*FACTU bloqueada', AMensaje);
  except
    on E: Exception do
    begin
      // La incidencia principal ya queda en el error que se muestra.
    end;
  end;
end;

procedure ValidarExportacionLegalNoVerifactu(AConn: TUniConnection;
                                             const AUsuario: string);
var
  iEventos:  Integer;
  iFacturas: Integer;
  sError:    string;
begin
  if NoVerifactuActivo then
  begin
    sError := '';
    if not VerifactuFirmaCertificado then
      sError := 'No se puede exportar NO VERI*FACTU legal: el modo ' +
        'NO VERI*FACTU exige firma electrónica con certificado oficial.'
    else if not ColumnasFirmaEventosDisponibles(AConn) then
      sError := 'No se puede exportar NO VERI*FACTU legal: faltan ' +
        'columnas de firma en fza_verifactu_eventos.'
    else if not ColumnasFirmaFacturacionDisponibles(AConn) then
      sError := 'No se puede exportar NO VERI*FACTU legal: faltan ' +
        'columnas de firma en fza_facturas_consolidaciones.'
    else
    begin
      iEventos := ContarEventosSinFirma(AConn);
      iFacturas := ContarFacturasSinFirma(AConn);
      if (iEventos > 0) or (iFacturas > 0) then
        sError := Format('No se puede exportar NO VERI*FACTU legal: ' +
          '%d evento(s) y %d registro(s) de facturación no tienen firma ' +
          'XAdES y datos de certificado.', [iEventos, iFacturas]);
    end;
    if sError <> '' then
    begin
      RegistrarIncidenciaExportacionSeguro(AConn, AUsuario, sError);
      raise Exception.Create(sError);
    end;
  end;
end;

function ConstruirXmlEventos(AConn: TUniConnection;
                             const AUsuario: string;
                             out ATotal: Integer):
  string;
var
  Qry: TUniQuery;
  Sb: TStringBuilder;
begin
  ATotal := 0;
  Sb := TStringBuilder.Create;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT ID_LOG, TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, ' +
      '        VERSION_LOG, DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, ' +
      '        HASH_ANTERIOR_LOG, HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, ' +
      '        SERIE_FAC_LOG, NUMERO_FAC_LOG, REGISTRO_XML_LOG, ' +
      '        FIRMA_XADES_LOG, SERIE_CERTIFICADO_LOG, ' +
      '        TITULAR_CERTIFICADO_LOG, HUELLA_CERTIFICADO_LOG ' +
      ' FROM fza_verifactu_eventos ' +
      ' ORDER BY ID_LOG';
    Qry.Open;
    Sb.Append('<?xml version="1.0" encoding="UTF-8"?>');
    Sb.Append('<fz:RegistroEventosNoVerifactu xmlns:fz="');
    Sb.Append(cNsFactuzamNoVerifactu);
    Sb.Append('" Generado="');
    Sb.Append(EscaparXml(FechaHoraIsoAhora));
    Sb.Append('" VersionFactuzam="');
    Sb.Append(EscaparXml(oVersion));
    Sb.Append('" UsuarioExportacion="');
    Sb.Append(EscaparXml(AUsuario));
    Sb.Append('" ModoVerifactu="');
    Sb.Append(EscaparXml(ModoVerifactuTexto));
    Sb.Append('">');
    while not Qry.Eof do
    begin
      Inc(ATotal);
      Sb.Append('<fz:Evento>');
      AgregarEtiqueta(Sb, 'Id', ValorCampo(Qry, 'ID_LOG'));
      AgregarEtiqueta(Sb, 'Instante',
                      ValorFechaIso(Qry, 'TIMESTAMP_LOG'));
      AgregarEtiqueta(Sb, 'Tipo', ValorCampo(Qry, 'TIPO_EVENTO_LOG'));
      AgregarEtiqueta(Sb, 'Usuario', ValorCampo(Qry, 'USUARIO_LOG'));
      AgregarEtiqueta(Sb, 'Version', ValorCampo(Qry, 'VERSION_LOG'));
      AgregarEtiquetaCData(Sb, 'Descripcion',
                           ValorCampo(Qry, 'DESCRIPCION_LOG'));
      AgregarEtiquetaCData(Sb, 'DatosAdicionales',
                           ValorCampo(Qry, 'DATOS_ADICIONALES_LOG'));
      AgregarEtiqueta(Sb, 'SerieFactura',
                      ValorCampo(Qry, 'SERIE_FAC_LOG'));
      AgregarEtiqueta(Sb, 'NumeroFactura',
                      ValorCampo(Qry, 'NUMERO_FAC_LOG'));
      AgregarEtiqueta(Sb, 'HashAnterior',
                      ValorCampo(Qry, 'HASH_ANTERIOR_LOG'));
      AgregarEtiqueta(Sb, 'HashPropio',
                      ValorCampo(Qry, 'HASH_PROPIO_LOG'));
      AgregarEtiqueta(Sb, 'FirmaDigital',
                      ValorCampo(Qry, 'FIRMA_DIGITAL_LOG'));
      AgregarEtiquetaCData(Sb, 'RegistroXmlFirmado',
                           ValorCampo(Qry, 'REGISTRO_XML_LOG'));
      AgregarEtiquetaCData(Sb, 'FirmaXades',
                           ValorCampo(Qry, 'FIRMA_XADES_LOG'));
      AgregarEtiqueta(Sb, 'SerieCertificado',
                      ValorCampo(Qry, 'SERIE_CERTIFICADO_LOG'));
      AgregarEtiqueta(Sb, 'TitularCertificado',
                      ValorCampo(Qry, 'TITULAR_CERTIFICADO_LOG'));
      AgregarEtiqueta(Sb, 'HuellaCertificado',
                      ValorCampo(Qry, 'HUELLA_CERTIFICADO_LOG'));
      Sb.Append('</fz:Evento>');
      Qry.Next;
    end;
    Sb.Append('</fz:RegistroEventosNoVerifactu>');
    Result := Sb.ToString;
  finally
    FreeAndNil(Qry);
    FreeAndNil(Sb);
  end;
end;

function ConstruirXmlFacturacion(AConn: TUniConnection;
                                 const AUsuario: string;
                                 out ATotal: Integer):
  string;
var
  Qry: TUniQuery;
  Sb: TStringBuilder;
  sPeticion: string;
  sRegistroXml: string;
begin
  ATotal := 0;
  Sb := TStringBuilder.Create;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT fc.ID_FACCON, fc.SERIE_FAC_FACCON, fc.NUMERO_FAC_FACCON, ' +
      '        fc.REQUEST_ID_CONSOLIDACION_FACCON, ' +
      '        fc.QUEUE_ID_CONSOLIDACION_FACCON, ' +
      '        fc.QUEUE_ID_CANCEL_FACCON, ' +
      '        fc.ISSUER_IRS_ID_CONSOLIDACION_FACCON, ' +
      '        fc.ISSUED_TIME_FACCON, fc.CHAIN_NUMBER_FACCON, ' +
      '        fc.CHAIN_HASH_FACCON, fc.FECHA_PROCESAMIENTO_FACCON, ' +
      '        fc.ESTADO_FACCON, fc.PETICION_COMPLETA_FACCON, ' +
      '        fc.REGISTRO_XML_FACCON, fc.FIRMA_DIGITAL_FACCON, ' +
      '        fc.SERIE_CERTIFICADO_FACCON, ' +
      '        fc.TITULAR_CERTIFICADO_FACCON, ' +
      '        fc.HUELLA_CERTIFICADO_FACCON, ' +
      '        f.FECHA_FAC, f.TIPO_FAC, f.NIF_EMPRESA_FAC, ' +
      '        f.RAZON_SOCIAL_EMPRESA_FAC, f.NIF_CLIENTE_FAC, ' +
      '        f.RAZON_SOCIAL_CLIENTE_FAC, f.TOTAL_LIQUIDO_FAC, ' +
      '        f.TOTAL_IMPUESTOS_FAC ' +
      ' FROM fza_facturas_consolidaciones fc ' +
      ' LEFT JOIN fza_facturas f ' +
      '        ON f.SERIE_FAC = fc.SERIE_FAC_FACCON ' +
      '       AND f.NUMERO_FAC = fc.NUMERO_FAC_FACCON ' +
      ' ORDER BY fc.ID_FACCON';
    Qry.Open;
    Sb.Append('<?xml version="1.0" encoding="UTF-8"?>');
    Sb.Append('<fz:RegistroFacturacionNoVerifactu xmlns:fz="');
    Sb.Append(cNsFactuzamNoVerifactu);
    Sb.Append('" Generado="');
    Sb.Append(EscaparXml(FechaHoraIsoAhora));
    Sb.Append('" VersionFactuzam="');
    Sb.Append(EscaparXml(oVersion));
    Sb.Append('" UsuarioExportacion="');
    Sb.Append(EscaparXml(AUsuario));
    Sb.Append('" ModoVerifactu="');
    Sb.Append(EscaparXml(ModoVerifactuTexto));
    Sb.Append('">');
    while not Qry.Eof do
    begin
      Inc(ATotal);
      sPeticion := ValorCampo(Qry, 'PETICION_COMPLETA_FACCON');
      sRegistroXml := ValorCampo(Qry, 'REGISTRO_XML_FACCON');
      Sb.Append('<fz:RegistroFactura>');
      AgregarEtiqueta(Sb, 'Id', ValorCampo(Qry, 'ID_FACCON'));
      AgregarEtiqueta(Sb, 'Serie', ValorCampo(Qry, 'SERIE_FAC_FACCON'));
      AgregarEtiqueta(Sb, 'Numero',
                      ValorCampo(Qry, 'NUMERO_FAC_FACCON'));
      AgregarEtiqueta(Sb, 'Estado', ValorCampo(Qry, 'ESTADO_FACCON'));
      AgregarEtiqueta(Sb, 'FechaFactura', ValorFechaIso(Qry, 'FECHA_FAC'));
      AgregarEtiqueta(Sb, 'TipoFactura', ValorCampo(Qry, 'TIPO_FAC'));
      AgregarEtiqueta(Sb, 'NifEmisor',
                      ValorCampo(Qry, 'NIF_EMPRESA_FAC'));
      AgregarEtiqueta(Sb, 'NombreEmisor',
                      ValorCampo(Qry, 'RAZON_SOCIAL_EMPRESA_FAC'));
      AgregarEtiqueta(Sb, 'NifCliente',
                      ValorCampo(Qry, 'NIF_CLIENTE_FAC'));
      AgregarEtiqueta(Sb, 'NombreCliente',
                      ValorCampo(Qry, 'RAZON_SOCIAL_CLIENTE_FAC'));
      AgregarEtiqueta(Sb, 'TotalLiquido',
                      ValorCampo(Qry, 'TOTAL_LIQUIDO_FAC'));
      AgregarEtiqueta(Sb, 'TotalImpuestos',
                      ValorCampo(Qry, 'TOTAL_IMPUESTOS_FAC'));
      AgregarEtiqueta(Sb, 'NifCadena',
                      ValorCampo(Qry,
                                 'ISSUER_IRS_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'FechaEmisionRegistro',
                      ValorFechaIso(Qry, 'ISSUED_TIME_FACCON'));
      AgregarEtiqueta(Sb, 'FechaProceso',
                      ValorFechaIso(Qry,
                                    'FECHA_PROCESAMIENTO_FACCON'));
      AgregarEtiqueta(Sb, 'NumeroCadena',
                      ValorCampo(Qry, 'CHAIN_NUMBER_FACCON'));
      AgregarEtiqueta(Sb, 'HashCadena',
                      ValorCampo(Qry, 'CHAIN_HASH_FACCON'));
      AgregarEtiqueta(Sb, 'IdColaAlta',
                      ValorCampo(Qry, 'QUEUE_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'IdColaAnulacion',
                      ValorCampo(Qry, 'QUEUE_ID_CANCEL_FACCON'));
      AgregarEtiqueta(Sb, 'RequestId',
                      ValorCampo(Qry,
                                 'REQUEST_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'HashPeticionBase64', Sha256Base64(sPeticion));
      AgregarEtiqueta(Sb, 'HashRegistroXmlBase64',
                      Sha256Base64(sRegistroXml));
      AgregarEtiquetaCData(Sb, 'RegistroXmlFirmado', sRegistroXml);
      AgregarEtiquetaCData(Sb, 'FirmaDigitalXades',
                           ValorCampo(Qry, 'FIRMA_DIGITAL_FACCON'));
      AgregarEtiqueta(Sb, 'SerieCertificado',
                      ValorCampo(Qry, 'SERIE_CERTIFICADO_FACCON'));
      AgregarEtiqueta(Sb, 'TitularCertificado',
                      ValorCampo(Qry, 'TITULAR_CERTIFICADO_FACCON'));
      AgregarEtiqueta(Sb, 'HuellaCertificado',
                      ValorCampo(Qry, 'HUELLA_CERTIFICADO_FACCON'));
      if sPeticion <> '' then
        AgregarEtiquetaCData(Sb, 'PeticionCompletaXml', sPeticion)
      else
        AgregarEtiqueta(Sb, 'Aviso',
                        'Registro sin PETICION_COMPLETA_FACCON guardada');
      Sb.Append('</fz:RegistroFactura>');
      Qry.Next;
    end;
    Sb.Append('</fz:RegistroFacturacionNoVerifactu>');
    Result := Sb.ToString;
  finally
    FreeAndNil(Qry);
    FreeAndNil(Sb);
  end;
end;

function NombreArchivoConSufijo(const AArchivoBase, ASufijo: string):
  string;
var
  sDirectorio: string;
  sNombre: string;
begin
  sDirectorio := TPath.GetDirectoryName(AArchivoBase);
  sNombre := TPath.GetFileNameWithoutExtension(AArchivoBase);
  if sNombre = '' then
    sNombre := 'NoVerifactu_' + FechaHoraExportacion;
  Result := TPath.Combine(sDirectorio, sNombre + ASufijo + '.xml');
end;

procedure GuardarTextoUtf8(const AArchivo, ATexto: string);
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AArchivo));
  TFile.WriteAllText(AArchivo, ATexto, TEncoding.UTF8);
end;

function ExportarRegistrosNoVerifactu(AConn: TUniConnection;
                                      const AUsuario: string;
                                      const AArchivoBase: string):
                                      TResultadoExportacionNoVerifactu;
var
  sXmlEventos: string;
  sXmlFacturacion: string;
begin
  if AConn = nil then
    raise Exception.Create('No hay conexion para exportar NO VERI*FACTU.');
  if Trim(AArchivoBase) = '' then
    raise Exception.Create('No se ha indicado archivo base de exportacion.');
  ValidarExportacionLegalNoVerifactu(AConn, AUsuario);
  Result.TitularCertificado := '';
  Result.SerieCertificado := '';
  Result.ArchivoEventos := NombreArchivoConSufijo(AArchivoBase, '_eventos');
  Result.ArchivoFacturacion := NombreArchivoConSufijo(AArchivoBase,
                                                       '_facturacion');
  RegistrarEventoVerifactu(AConn, AUsuario,
    cEventoNoVerifactuExportFact,
    'Exportación de registros de facturación NO VERI*FACTU',
    Result.ArchivoFacturacion);
  RegistrarEventoVerifactu(AConn, AUsuario,
    cEventoNoVerifactuExportEventos,
    'Exportación de registros de eventos NO VERI*FACTU',
    Result.ArchivoEventos);
  sXmlEventos := ConstruirXmlEventos(AConn, AUsuario, Result.Eventos);
  sXmlFacturacion := ConstruirXmlFacturacion(AConn, AUsuario,
    Result.RegistrosFactura);
  GuardarTextoUtf8(Result.ArchivoEventos, sXmlEventos);
  GuardarTextoUtf8(Result.ArchivoFacturacion, sXmlFacturacion);
end;

end.
