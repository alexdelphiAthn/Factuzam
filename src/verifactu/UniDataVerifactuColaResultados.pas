{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaResultados                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de resultados, consolidación y reintentos Verifactu.  }
{******************************************************************************}
unit UniDataVerifactuColaResultados;

interface

uses
  Uni, inLibParametrosIntf, inLibVerifactuEnvio, inLibLogIntf;
type
  TResultadosVerifactuColaUniDAC = class
  public
    class procedure GuardarEnvioOk(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
      const AResultado: TResultadoEnvioVerifactu;
      const ARegistroLog: IRegistroLog); static;
    class procedure GuardarEnvioError(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
      AIntentos: Integer;
      const ARegistroLog: IRegistroLog); static;
  end;
implementation
uses
  System.SysUtils, System.Classes, Data.DB, inLibVerifactu,
  inLibRelojFiscal, inLibVentasWsCola, inLibVerifactuReintentos,
  UniDataVentasWsCola, UniDataVerifactuSubsanacionResultados;
procedure AsignarResultadoComun(AQry: TUniQuery;
  const AResultado: TResultadoEnvioVerifactu);
begin
  AQry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AQry.ParamByName('RESPUESTA').AsString := AResultado.RespuestaCompleta;
  AQry.ParamByName('PETICION').AsString := AResultado.PeticionCompleta;
  AQry.ParamByName('REGISTROXML').AsString := AResultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString := AResultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString := AResultado.HuellaCertificado;
end;
class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioOk(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu;
  const ARegistroLog: IRegistroLog);
var
  Qry:           TUniQuery;
  oPngStream:    TBytesStream;
  sFase:         string;
  sEstadoFaccon: string;
  bInsertarAlta: Boolean;
begin
  // Se ejecuta DENTRO de la transacción abierta por ProcesarFila
  if ATipoOperacion = 'ANULACION' then
    sFase := cFaseFacturaVerifactuAnulada
  else
    sFase := cFaseFacturaVerifactuOk;
  if SameText(AResultado.EstadoRegistro, 'AceptadoConErrores') then
    sEstadoFaccon := 'VERIFACTU_ACEPT_ERR'
  else if ATipoOperacion = 'SUBSANACION' then
    sEstadoFaccon := 'VERIFACTU_SUBSANADO'
  else if SameText(AResultado.EstadoRegistro, 'Duplicado') then
    sEstadoFaccon := 'VERIFACTU_DUPLICADO'
  else
    sEstadoFaccon := 'VERIFACTU_PROCESADO';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    // Avanzar la cadena de huellas del emisor (fila bloqueada con
    // FOR UPDATE desde EnviarRegistroFactura)
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cadena ' +
      ' SET CONTADOR_VFCAD = :CONTADOR, SERIE_FAC_VFCAD = :SERIE, ' +
      '     NUMERO_FAC_VFCAD = :NUMERO, ' +
      '     FECHA_FAC_VFCAD = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
      '     HUELLA_VFCAD = :HUELLA, INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF = :USUARIO ' +
      ' WHERE NIF_VFCAD = :NIF';
    Qry.ParamByName('CONTADOR').AsString := AResultado.ChainNumber;
    Qry.ParamByName('SERIE').AsString    := ASerie;
    Qry.ParamByName('NUMERO').AsString   := ANumero;
    Qry.ParamByName('FECHA').AsString    := AResultado.FechaExpedicion;
    Qry.ParamByName('HUELLA').AsString   := AResultado.ChainHash;
    Qry.ParamByName('USUARIO').AsString  := AUsuario;
    Qry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
    Qry.Execute;
    bInsertarAlta := (ATipoOperacion <> 'ANULACION');
    if ATipoOperacion = 'ANULACION' then
    begin
      // La anulación actualiza la consolidación del alta (UK_FACTURA)
      Qry.SQL.Text :=
        ' UPDATE fza_facturas_consolidaciones ' +
        ' SET QUEUE_ID_CANCEL_FACCON = :IDCOLA, ' +
        '     ESTADO_FACCON = ''VERIFACTU_ANULADO'', ' +
        '     CHAIN_NUMBER_FACCON = :CHAINNUM, CHAIN_HASH_FACCON = :CHAINHASH, '
          +
        '     RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
        '     PETICION_COMPLETA_FACCON = :PETICION, ' +
        '     REGISTRO_XML_FACCON = :REGISTROXML, FIRMA_DIGITAL_FACCON = ' +
        ':FIRMA, ' +
        '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
        '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
        '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
        '     FECHA_PROCESAMIENTO_FACCON = NOW() ' +
        ' WHERE SERIE_FAC_FACCON  = :SERIE ' +
        '   AND NUMERO_FAC_FACCON = :NUMERO';
      Qry.ParamByName('IDCOLA').AsLargeInt  := AIdCola;
      AsignarResultadoComun(Qry, AResultado);
      Qry.ParamByName('SERIE').AsString  := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Execute;
    end;
    if ATipoOperacion = 'SUBSANACION' then
    begin
      GuardarResultadoSubsanacion(
        AConexion,
        AIdCola,
        ASerie,
        ANumero,
        AUsuario,
        sEstadoFaccon,
        AResultado);
      bInsertarAlta := False;
    end;
    if bInsertarAlta then
    begin
      // Consolidación del alta: misma estructura que usa OdaVeriFactu
      Qry.SQL.Text :=
        ' INSERT INTO fza_facturas_consolidaciones ' +
        ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
        '  REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, ' +
        '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
        '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
        '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
        '  QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
        '  CODIGO_ERROR_AEAT_FACCON, ' +
        '  DESCRIPCION_ERROR_AEAT_FACCON, ' +
        '  RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON, ' +
        '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
        '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
        '  HUELLA_CERTIFICADO_FACCON) ' +
        ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
        '        NULLIF(:REQUESTID, ''''), :IDCOLA, ' +
        '        NULLIF(:ISSUERID, ''''), :ISSUEDTIME, ' +
        '        NULLIF(:CHAINNUM, ''''), NULLIF(:CHAINHASH, ''''), ' +
        '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), ' +
        '        :QRPNG, NOW(), :ESTADO, NULLIF(:CODERROR, ''''), ' +
        '        NULLIF(:DESCERROR, ''''), NULLIF(:RESPUESTA, ''''), ' +
        '        NULLIF(:PETICION, ''''), :REGISTROXML, :FIRMA, ' +
        '        :SERIECERT, :TITULARCERT, :HUELLACERT ' +
        ' FROM fza_facturas_consolidaciones';
      Qry.ParamByName('SERIE').AsString     := ASerie;
      Qry.ParamByName('NUMERO').AsString    := ANumero;
      Qry.ParamByName('REQUESTID').AsString := AResultado.RequestId;
      Qry.ParamByName('IDCOLA').AsLargeInt  := AIdCola;
      Qry.ParamByName('ISSUERID').AsString  := AResultado.IssuerIrsId;
      Qry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
      if AResultado.IssuedTime > 0 then
        Qry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime
      else
        Qry.ParamByName('ISSUEDTIME').Clear;
      Qry.ParamByName('URL').AsString       := AResultado.VerifactuUrl;
      Qry.ParamByName('QRBASE64').AsString  := AResultado.QRCodeBase64;
      Qry.ParamByName('QRPNG').DataType     := ftBlob;
      if Length(AResultado.QRCodePng) > 0 then
      begin
        oPngStream := TBytesStream.Create(AResultado.QRCodePng);
        try
          Qry.ParamByName('QRPNG').LoadFromStream(oPngStream, ftBlob);
        finally
          FreeAndNil(oPngStream);
        end;
      end
      else
        Qry.ParamByName('QRPNG').Clear;
      Qry.ParamByName('ESTADO').AsString    := sEstadoFaccon;
      AsignarResultadoComun(Qry, AResultado);
      Qry.ParamByName('CODERROR').AsString := AResultado.CodigoError;
      Qry.ParamByName('DESCERROR').AsString := AResultado.DescripcionError;
      Qry.Execute;
    end;
    // Estado fiscal de la factura
    Qry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET ESCONSOLIDADA_FAC = ''S'', INSTANTECONSO_FAC = NOW(), ' +
      '     FASE_FAC = :FASE, INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF = :USUARIO ' +
      ' WHERE SERIE_FAC  = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('FASE').AsString    := sFase;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('SERIE').AsString   := ASerie;
    Qry.ParamByName('NUMERO').AsString  := ANumero;
    Qry.Execute;
    // Los movimientos se revierten al solicitar la anulación. No se repite
    // aquí para evitar una segunda actualización del stock.
    // Cola: fila enviada. El mensaje informativo se conserva cuando la
    // AEAT acepta con errores.
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''ENVIADA'', INSTANTE_ENVIO_VFCOLA = NOW(), ' +
      '     MENSAJE_ERROR_VFCOLA = NULLIF(:MENSAJE, ''''), ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    Qry.ParamByName('MENSAJE').AsString := AResultado.MensajeError;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
    cEventoVerifactuEnvioOk,
    'Registro de facturación (' + ATipoOperacion + ') aceptado por la ' +
    'AEAT (' + AResultado.EstadoRegistro + ')',
    'CSV: ' + AResultado.RequestId, ASerie, ANumero);
  TVentasWsCola.RegistrarEventoSeguro(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(AConexion),
    AUsuario,
    'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
end;
class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioError(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
  AIntentos: Integer;
  const ARegistroLog: IRegistroLog);
var
  Qry:          TUniQuery;
  iMaxIntentos: Integer;
  iEspera:      Integer;
  sEstado:      string;
begin
  iMaxIntentos := AParametrosApp.GetInt('appVerifactuMaxIntentos', 10);
  iEspera := CalcularEsperaReintentoVerifactu(AIntentos);
  sEstado := CalcularEstadoReintentoVerifactu(
    AIntentos,
    iMaxIntentos);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = :ESTADO, ' +
      '     CONTADOR_INTENTOS_VFCOLA = CONTADOR_INTENTOS_VFCOLA + 1, ' +
      '     INSTANTE_PROXIMO_INTENTO_VFCOLA = ' +
      '       DATE_ADD(NOW(), INTERVAL :ESPERA SECOND), ' +
      '     MENSAJE_ERROR_VFCOLA = :MENSAJE, ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    Qry.ParamByName('ESTADO').AsString  := sEstado;
    Qry.ParamByName('ESPERA').AsInteger := iEspera;
    Qry.ParamByName('MENSAJE').AsString := AMensaje;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    if sEstado = 'ERROR' then
    begin
      // Reintentos agotados: se refleja en la fase fiscal de la factura
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = :FASE, INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('FASE').AsString := cFaseFacturaVerifactuError;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('NUMERO').AsString  := ANumero;
      Qry.Execute;
    end;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
    cEventoVerifactuEnvioError,
    'Error de envío Verifactu (intento ' + IntToStr(AIntentos + 1) +
    '): ' + AMensaje, '', ASerie, ANumero);
  TVentasWsCola.RegistrarEventoSeguro(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(AConexion),
    AUsuario,
    'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
end;
end.
