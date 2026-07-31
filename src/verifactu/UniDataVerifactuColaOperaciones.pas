{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaOperaciones                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operaciones fiscales UniDAC sin envío a AEAT: registro NO VERI*FACTU,     }
{    rectificativas, relaciones y reversión de movimientos.                    }
{******************************************************************************}
unit UniDataVerifactuColaOperaciones;

interface

uses
  Uni, inLibParametrosIntf, inLibEmisionFiscalIntf;
type
  TOperacionesVerifactuColaUniDAC = class
  public
    // Genera y guarda el registro de facturación firmado sin enviarlo a
    // AEAT. Es el camino NO VERI*FACTU y debe ejecutarse al crear la
    // factura. AQryTrx participa en la transacción de la grabación.
    class procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AQryTrx: TUniQuery;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean); static;
    // Marca una factura recién abonada como RECTIFICATIVA, la enlaza con
    // la original (columnas ABONO) y delega el alta fiscal en el servicio
    // de emisión inyectado. La llama el modal de Rectificar de Facturas.
    class procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect, ATipoRectificativa: string;
      ABorrarMovimientosOriginales: Boolean); static;
    // Histórico N:1 de rectificaciones/sustituciones
    // (fza_facturas_relaciones): cada hija guarda su factura de origen
    class procedure RegistrarRelacionFactura(
      AConn: TUniConnection;
      const AUsuario, ASerie, ANumero,
      ASerieOrigen, ANumeroOrigen, ATipoRelacion: string); static;
    // Revierte los movimientos vinculados a una factura de caja (VE) o
    // creada desde el mantenimiento (FC). El SP mantiene stock y
    // acumulados.
    class procedure BorrarMovimientosFactura(
      AQry: TUniQuery;
      const ASerie, ANumero: string); static;
  end;
function ObtenerEstadoRegistroNoVerifactu(
  const ATipoOperacion: string): string;
implementation

uses
  System.SysUtils, System.Classes, Data.DB, inLibLog, inLibMsgFacturas,
  inLibMsgVerifactu, inLibVerifactu, inLibVerifactuEnvio, inLibRelojFiscal,
  inLibVentasWsCola, UniDataVentasWsCola;
function ObtenerEstadoRegistroNoVerifactu(
  const ATipoOperacion: string): string;
begin
  if ATipoOperacion = 'ANULACION' then
    Result := 'NOVERIF_ANULADO'
  else if ATipoOperacion = 'SUBSANACION' then
    Result := 'NOVERIF_SUBSANADO'
  else
    Result := 'NOVERIF_REGISTRADO';
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
procedure RegistrarIncidenciaNoVerifactuSeguro(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const AUsuario: string;
  ATipoEvento: Integer;
  const ADescripcion, AMensaje, ASerie, ANumero: string);
begin
  try
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      ATipoEvento, ADescripcion, AMensaje, ASerie, ANumero);
  except
    on E: Exception do
    begin
      Log.LogError('No se pudo registrar la incidencia NO VERI*FACTU: ' +
                   E.Message);
    end;
  end;
end;
procedure ActualizarCadenaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_verifactu_cadena ' +
    ' SET CONTADOR_VFCAD = :CONTADOR, ' +
    '     SERIE_FAC_VFCAD  = :SERIE, ' +
    '     NUMERO_FAC_VFCAD = :NUMERO, ' +
    '     FECHA_FAC_VFCAD  = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
    '     HUELLA_VFCAD = :HUELLA, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE NIF_VFCAD = :NIF';
  AQry.ParamByName('CONTADOR').AsString := AResultado.ChainNumber;
  AQry.ParamByName('SERIE').AsString    := ASerie;
  AQry.ParamByName('NUMERO').AsString   := ANumero;
  AQry.ParamByName('FECHA').AsString    := AResultado.FechaExpedicion;
  AQry.ParamByName('HUELLA').AsString   := AResultado.ChainHash;
  AQry.ParamByName('USUARIO').AsString  := AUsuario;
  AQry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
  AQry.Execute;
end;
procedure PrepararActualizacionAnulacionNoVerifactu(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_facturas_consolidaciones ' +
    ' SET CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
    '     CHAIN_HASH_FACCON = :CHAINHASH, ' +
    '     ISSUER_IRS_ID_CONSOLIDACION_FACCON = :ISSUERID, ' +
    '     ISSUED_TIME_FACCON = :ISSUEDTIME, ' +
    '     FECHA_PROCESAMIENTO_FACCON = NOW(), ' +
    '     ESTADO_FACCON = :ESTADO, ' +
    '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
    '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
    '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
    '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
    '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT ' +
    ' WHERE SERIE_FAC_FACCON = :SERIE ' +
    '   AND NUMERO_FAC_FACCON = :NUMERO';
end;
procedure PrepararAltaConsolidacionNoVerifactu(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' INSERT INTO fza_facturas_consolidaciones ' +
    ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
    '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
    '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
    '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
    '  QRCODE_PNG_FACCON, ' +
    '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
    '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
    '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
    '  HUELLA_CERTIFICADO_FACCON) ' +
    ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
    '        :ISSUERID, :ISSUEDTIME, :CHAINNUM, :CHAINHASH, ' +
    '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), :QRPNG, ' +
    '        NOW(), :ESTADO, :REGISTROXML, :FIRMA, :SERIECERT, ' +
    '        :TITULARCERT, :HUELLACERT ' +
    ' FROM fza_facturas_consolidaciones ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_FACCON = VALUES(ESTADO_FACCON), ' +
    '  CHAIN_NUMBER_FACCON = VALUES(CHAIN_NUMBER_FACCON), ' +
    '  CHAIN_HASH_FACCON = VALUES(CHAIN_HASH_FACCON), ' +
    '  VERIFACTU_URL_FACCON = VALUES(VERIFACTU_URL_FACCON), ' +
    '  QRCODE_BASE64_FACCON = VALUES(QRCODE_BASE64_FACCON), ' +
    '  QRCODE_PNG_FACCON = VALUES(QRCODE_PNG_FACCON), ' +
    '  REGISTRO_XML_FACCON = VALUES(REGISTRO_XML_FACCON), ' +
    '  FIRMA_DIGITAL_FACCON = VALUES(FIRMA_DIGITAL_FACCON), ' +
    '  SERIE_CERTIFICADO_FACCON = VALUES(SERIE_CERTIFICADO_FACCON), ' +
    '  TITULAR_CERTIFICADO_FACCON = ' +
    '    VALUES(TITULAR_CERTIFICADO_FACCON), ' +
    '  HUELLA_CERTIFICADO_FACCON = ' +
    '    VALUES(HUELLA_CERTIFICADO_FACCON)';
end;
procedure AsignarParametrosConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  oPngStream: TBytesStream;
begin
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.ParamByName('ISSUERID').AsString := AResultado.IssuerIrsId;
  AQry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
  AQry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime;
  AQry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AQry.ParamByName('ESTADO').AsString :=
    ObtenerEstadoRegistroNoVerifactu(ATipoOperacion);
  if ATipoOperacion <> 'ANULACION' then
  begin
    AQry.ParamByName('URL').AsString      := AResultado.VerifactuUrl;
    AQry.ParamByName('QRBASE64').AsString := AResultado.QRCodeBase64;
    AQry.ParamByName('QRPNG').DataType    := ftBlob;
    if Length(AResultado.QRCodePng) > 0 then
    begin
      oPngStream := TBytesStream.Create(AResultado.QRCodePng);
      try
        AQry.ParamByName('QRPNG').LoadFromStream(oPngStream, ftBlob);
      finally
        FreeAndNil(oPngStream);
      end;
    end
    else
      AQry.ParamByName('QRPNG').Clear;
  end;
  AQry.ParamByName('REGISTROXML').AsString :=
    AResultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString :=
    AResultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString :=
    AResultado.HuellaCertificado;
end;
procedure GuardarConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
  if ATipoOperacion = 'ANULACION' then
    PrepararActualizacionAnulacionNoVerifactu(AQry)
  else
    PrepararAltaConsolidacionNoVerifactu(AQry);
  AsignarParametrosConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  AQry.Execute;
end;
procedure MarcarFacturaRegistradaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  if ATipoOperacion = 'ANULACION' then
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuAnulada
  else
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuOk;
  AQry.ParamByName('USUARIO').AsString := AUsuario;
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.Execute;
end;
procedure GuardarRegistroNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu;
  ABorrarMovimientos: Boolean);
begin
  if not ColumnasFirmaFacturacionDisponibles(AQry.Connection) then
    raise Exception.Create(
      SErrorColumnasFirmaFacturacionNoDisponibles);
  ActualizarCadenaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, AResultado);
  GuardarConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  MarcarFacturaRegistradaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, ATipoOperacion);
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      AQry, ASerie, ANumero);
end;
// ===========================================================================
//   TOperacionesVerifactuColaUniDAC — operaciones sin envío
// ===========================================================================
class procedure TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
  AQry: TUniQuery;
  const ASerie, ANumero: string);
begin
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'VE';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'UPDATE fza_facturas_lineas ' +
      '   SET NUMERO_MOV_FACLIN = NULL ' +
      ' WHERE SERIE_FAC_FACLIN = :s ' +
      '   AND NUMERO_FAC_FACLIN = :n';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'FC';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AQryTrx: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
var
  oResultado: TResultadoEnvioVerifactu;
begin
  try
    ValidarRequisitosFiscalesEmision(AParametrosApp, AQryTrx.Connection,
      ASerie, ANumero);
    ExigirRelojFiscal(AParametrosApp,
      STextoRegistroFacturacionNoVerifactu);
    if not VerifactuFirmaCertificado(AParametrosApp) then
      raise Exception.Create(SErrorFirmaRegistroNoVerifactuObligatoria);
    oResultado := GenerarRegistroFacturaLocal(AParametrosApp,
      AQryTrx.Connection, AUsuario, ASerie, ANumero, ATipoOperacion);
    if not oResultado.Ok then
      raise Exception.Create(oResultado.MensajeError);
    GuardarRegistroNoVerifactu(AQryTrx, AUsuario, ASerie, ANumero,
      ATipoOperacion, oResultado, ABorrarMovimientos);
    RegistrarEventoVerifactu(AParametrosApp, AQryTrx.Connection, AUsuario,
      cEventoVerifactuInfo,
      'Registro de facturación NO VERI*FACTU registrado', ATipoOperacion,
      ASerie, ANumero);
    TVentasWsCola.RegistrarFactura(
      AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(AQryTrx.Connection),
      AQryTrx, AUsuario, ASerie, ANumero, ATipoOperacion);
  except
    on E: Exception do
    begin
      if Pos('reloj', LowerCase(E.Message)) > 0 then
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaReloj,
          'Incidencia de reloj NO VERI*FACTU', E.Message, ASerie, ANumero)
      else
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaCert,
          'Incidencia de certificado NO VERI*FACTU', E.Message,
          ASerie, ANumero);
      raise;
    end;
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
var
  Qry: TUniQuery;
  sComentario: string;
  sTipoRectificativa: string;
  Solicitud: TSolicitudEmisionFiscal;
begin
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  sTipoRectificativa := UpperCase(Trim(ATipoRectificativa));
  if (sTipoRectificativa <> 'I') and
     (sTipoRectificativa <> 'S') then
    raise Exception.Create(
      'El tipo fiscal de rectificativa debe ser I o S.');
  if sTipoRectificativa = 'S' then
    sComentario := ' ESTA FACTURA RECTIFICA POR SUSTITUCIÓN A LA '
  else
    sComentario := ' ESTA FACTURA RECTIFICA POR DIFERENCIAS A LA ';
  // Guarda: una rectificativa sin serie/numero validos (p.ej. '0'/'0' por
  // una cabecera de caja que no se vuelca) encolaria un registro fantasma
  // que la AEAT rechaza y rompe el enlace ABONO de la original. Se deja
  // constancia en el log y no se toca nada mas.
  if (Trim(ASerieRect) = '') or (Trim(ASerieRect) = '0') or
     (Trim(ANumeroRect) = '') or (Trim(ANumeroRect) = '0') then
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      cEventoVerifactuEnvioError,
      'Rectificativa de ' + ASerieOriginal + '\' + ANumeroOriginal +
      ' NO encolada: la factura rectificativa carece de serie/numero ' +
      'validos (recibido ' + ASerieRect + '\' + ANumeroRect + ')', '',
      ASerieOriginal, ANumeroOriginal)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      // Rectificativa: tipo y fase propios, sin enlace ABONO heredado de
      // la copia del SP, y comentario con la factura que rectifica
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET TIPO_FAC = ''RECTIFICATIVA'', ' +
        '     TIPO_RECTIFICATIVA_FAC = :TIPORECT, ' +
        '     FASE_FAC = ''BORRADOR'', ' +
        '     SERIE_FAC_ABONO_FAC  = NULL, ' +
        '     NUMERO_FAC_ABONO_FAC = NULL, ' +
        '     COMENTARIOS_FAC = TRIM(CONCAT(IFNULL(COMENTARIOS_FAC, ' +
        '         ''''), :COMENTARIO)), ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('COMENTARIO').AsString :=
        sComentario + ASerieOriginal + '\' + ANumeroOriginal;
      Qry.ParamByName('TIPORECT').AsString := sTipoRectificativa;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.ParamByName('SERIE').AsString   := ASerieRect;
      Qry.ParamByName('NUMERO').AsString  := ANumeroRect;
      Qry.Execute;
      // La factura ORIGINAL pasa a fase RECTIFICADA y guarda en sus
      // columnas ABONO la rectificativa que la anula
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = ''RECTIFICADA'', ' +
        '     SERIE_FAC_ABONO_FAC  = :SERIERECT, ' +
        '     NUMERO_FAC_ABONO_FAC = :NUMERORECT, ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIERECT').AsString  := ASerieRect;
      Qry.ParamByName('NUMERORECT').AsString := ANumeroRect;
      Qry.ParamByName('USUARIO').AsString    := AUsuario;
      Qry.ParamByName('SERIE').AsString      := ASerieOriginal;
      Qry.ParamByName('NUMERO').AsString     := ANumeroOriginal;
      Qry.Execute;
      // Histórico N:1: cada rectificativa conserva su propio enlace
      // aunque la original se rectifique varias veces
      RegistrarRelacionFactura(AConn, AUsuario, ASerieRect, ANumeroRect,
        ASerieOriginal, ANumeroOriginal, 'RECTIFICA');
      if sTipoRectificativa = 'S' then
      begin
        BorrarMovimientosFactura(Qry, ASerieOriginal, ANumeroOriginal);
      end;
      Solicitud := TSolicitudEmisionFiscal.ParaAlta(
        ASerieRect,
        ANumeroRect,
        AUsuario,
        'Rectificativa de ' + ASerieOriginal + '\' + ANumeroOriginal +
        ' tipo ' + sTipoRectificativa +
        ' encolada desde Facturas');
      AServicioEmision.Emitir(Solicitud);
      // El webservice conserva el histórico, pero deja la original fuera
      // de las ventas activas cuando la rectificación es sustitutiva.
      if sTipoRectificativa = 'S' then
      begin
        TVentasWsCola.RegistrarFactura(
          AParametrosCaja,
          CrearRepositorioVentasWsColaUniDAC(Qry.Connection),
          Qry, AUsuario, ASerieOriginal, ANumeroOriginal,
          'SUSTITUCION');
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.RegistrarRelacionFactura(
  AConn: TUniConnection;
  const AUsuario, ASerie, ANumero,
  ASerieOrigen, ANumeroOrigen, ATipoRelacion: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' INSERT INTO fza_facturas_relaciones ' +
      ' (SERIE_FAC_FACREL, NUMERO_FAC_FACREL, ' +
      '  SERIE_FAC_ORIGEN_FACREL, NUMERO_FAC_ORIGEN_FACREL, ' +
      '  TIPO_RELACION_FACREL, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:SERIE, :NUMERO, :SERIEORIG, :NUMEROORIG, :TIPO, ' +
      '         NOW(), :USUARIO) ' +
      ' ON DUPLICATE KEY UPDATE ' +
      '  SERIE_FAC_ORIGEN_FACREL  = :SERIEORIG, ' +
      '  NUMERO_FAC_ORIGEN_FACREL = :NUMEROORIG, ' +
      '  INSTANTE_MODIF = NOW(), ' +
      '  USUARIO_MODIF  = :USUARIO';
    Qry.ParamByName('SERIE').AsString      := ASerie;
    Qry.ParamByName('NUMERO').AsString     := ANumero;
    Qry.ParamByName('SERIEORIG').AsString  := ASerieOrigen;
    Qry.ParamByName('NUMEROORIG').AsString := ANumeroOrigen;
    Qry.ParamByName('TIPO').AsString       := ATipoRelacion;
    Qry.ParamByName('USUARIO').AsString    := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;
end.
