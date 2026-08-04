{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuSubsanacionResultados                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Conserva el alta original y persiste la respuesta de subsanación.         }
{******************************************************************************}
unit UniDataVerifactuSubsanacionResultados;
interface
uses
  Uni,
  inLibVerifactuEnvio;
procedure GuardarResultadoSubsanacion(
  AConexion: TUniConnection;
  AIdCola: Int64;
  const ASerie, ANumero, AUsuario, AEstado: string;
  const AResultado: TResultadoEnvioVerifactu);
implementation
uses
  System.SysUtils,
  inLibMsgVerifactu;
procedure GuardarResultadoSubsanacion(
  AConexion: TUniConnection;
  AIdCola: Int64;
  const ASerie, ANumero, AUsuario, AEstado: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    // La primera respuesta queda congelada antes de guardar la subsanación.
    Qry.SQL.Text :=
      ' UPDATE fza_facturas_consolidaciones ' +
      ' SET ESTADO_ORIGINAL_FACCON = ' +
      '       IFNULL(ESTADO_ORIGINAL_FACCON, ESTADO_FACCON), ' +
      '     REQUEST_ID_ORIGINAL_FACCON = ' +
      '       IFNULL(REQUEST_ID_ORIGINAL_FACCON, ' +
      '              REQUEST_ID_CONSOLIDACION_FACCON), ' +
      '     CHAIN_NUMBER_ORIGINAL_FACCON = ' +
      '       IFNULL(CHAIN_NUMBER_ORIGINAL_FACCON, CHAIN_NUMBER_FACCON), ' +
      '     CHAIN_HASH_ORIGINAL_FACCON = ' +
      '       IFNULL(CHAIN_HASH_ORIGINAL_FACCON, CHAIN_HASH_FACCON), ' +
      '     CODIGO_ERROR_ORIGINAL_FACCON = ' +
      '       IFNULL(CODIGO_ERROR_ORIGINAL_FACCON, ' +
      '              CODIGO_ERROR_AEAT_FACCON), ' +
      '     DESCRIPCION_ERROR_ORIGINAL_FACCON = ' +
      '       IFNULL(DESCRIPCION_ERROR_ORIGINAL_FACCON, ' +
      '              DESCRIPCION_ERROR_AEAT_FACCON), ' +
      '     RESPUESTA_ORIGINAL_FACCON = ' +
      '       IFNULL(RESPUESTA_ORIGINAL_FACCON, ' +
      '              RESPUESTA_COMPLETA_FACCON), ' +
      '     PETICION_ORIGINAL_FACCON = ' +
      '       IFNULL(PETICION_ORIGINAL_FACCON, ' +
      '              PETICION_COMPLETA_FACCON), ' +
      '     REGISTRO_XML_ORIGINAL_FACCON = ' +
      '       IFNULL(REGISTRO_XML_ORIGINAL_FACCON, REGISTRO_XML_FACCON), ' +
      '     FIRMA_DIGITAL_ORIGINAL_FACCON = ' +
      '       IFNULL(FIRMA_DIGITAL_ORIGINAL_FACCON, ' +
      '              FIRMA_DIGITAL_FACCON), ' +
      '     SERIE_CERTIFICADO_ORIGINAL_FACCON = ' +
      '       IFNULL(SERIE_CERTIFICADO_ORIGINAL_FACCON, ' +
      '              SERIE_CERTIFICADO_FACCON), ' +
      '     TITULAR_CERTIFICADO_ORIGINAL_FACCON = ' +
      '       IFNULL(TITULAR_CERTIFICADO_ORIGINAL_FACCON, ' +
      '              TITULAR_CERTIFICADO_FACCON), ' +
      '     HUELLA_CERTIFICADO_ORIGINAL_FACCON = ' +
      '       IFNULL(HUELLA_CERTIFICADO_ORIGINAL_FACCON, ' +
      '              HUELLA_CERTIFICADO_FACCON), ' +
      '     REQUEST_ID_CONSOLIDACION_FACCON = ' +
      '       IFNULL(NULLIF(:REQUESTID, ''''), ' +
      '              REQUEST_ID_CONSOLIDACION_FACCON), ' +
      '     CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
      '     CHAIN_HASH_FACCON = :CHAINHASH, ' +
      '     ESTADO_FACCON = :ESTADO, ' +
      '     CODIGO_ERROR_AEAT_FACCON = NULLIF(:CODERROR, ''''), ' +
      '     DESCRIPCION_ERROR_AEAT_FACCON = NULLIF(:DESCERROR, ''''), ' +
      '     RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
      '     PETICION_COMPLETA_FACCON = :PETICION, ' +
      '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
      '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
      '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
      '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
      '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
      '     MOTIVO_SUBSANACION_FACCON = ' +
      '       (SELECT q.MOTIVO_VFCOLA ' +
      '          FROM fza_verifactu_cola q ' +
      '         WHERE q.ID_VFCOLA = :IDCOLA), ' +
      '     INSTANTE_SUBSANACION_FACCON = NOW(), ' +
      '     USUARIO_SUBSANACION_FACCON = :USUARIO, ' +
      '     FECHA_PROCESAMIENTO_FACCON = NOW() ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO ' +
      '   AND ESTADO_FACCON = ''VERIFACTU_ACEPT_ERR''';
    Qry.ParamByName('REQUESTID').AsString := AResultado.RequestId;
    Qry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
    Qry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
    Qry.ParamByName('CODERROR').AsString := AResultado.CodigoError;
    Qry.ParamByName('DESCERROR').AsString := AResultado.DescripcionError;
    Qry.ParamByName('RESPUESTA').AsString := AResultado.RespuestaCompleta;
    Qry.ParamByName('PETICION').AsString := AResultado.PeticionCompleta;
    Qry.ParamByName('REGISTROXML').AsString := AResultado.RegistroXmlFirmado;
    Qry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
    Qry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
    Qry.ParamByName('TITULARCERT').AsString := AResultado.TitularCertificado;
    Qry.ParamByName('HUELLACERT').AsString := AResultado.HuellaCertificado;
    Qry.ParamByName('IDCOLA').AsLargeInt := AIdCola;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.ParamByName('ESTADO').AsString := AEstado;
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Execute;
    if Qry.RowsAffected = 0 then
      raise Exception.Create(SErrorIncidenciaEstadoCambio);
  finally
    FreeAndNil(Qry);
  end;
end;
end.
