{******************************************************************************}
{                                                                              }
{  Módulo:       inLibErroresHttp                                              }
{    Tipo:       Librería                                                      }
{                                                                              }
{  Descripción:                                                                }
{    Clasifica fallos temporales del transporte HTTP sin confundirlos con      }
{    errores de certificado, URI, configuración o respuestas del servidor.    }
{******************************************************************************}
unit inLibErroresHttp;

interface

uses
  System.SysUtils;

type
  EConexionHttpTemporal = class(Exception);

function EsFalloTemporalTransporteHttp(
  const AError: Exception): Boolean;

implementation

uses
  System.Net.HttpClient;

const
  // WinHTTP no expone el código nativo en las excepciones de la RTL;
  // lo incorpora de forma estable entre paréntesis en el mensaje.
  CErrorWinHttpTimeout = '(12002)';
  CErrorWinHttpNombreNoResuelto = '(12007)';
  CErrorWinHttpNoPuedeConectar = '(12029)';
  CErrorWinHttpConexionInterrumpida = '(12030)';

function EsFalloTemporalTransporteHttp(
  const AError: Exception): Boolean;
var
  oErrorBase: Exception;
begin
  Result := Assigned(AError);
  if Result then
  begin
    oErrorBase := AError.BaseException;
    // Las clases por sí solas son demasiado amplias: por ejemplo,
    // ENetHTTPClientException también puede representar un fallo TLS.
    // Se aceptan solo las causas propias de una caída de conectividad.
    Result := ((oErrorBase is ENetHTTPClientException) or
               (oErrorBase is ENetHTTPResponseException)) and
              ((Pos(CErrorWinHttpTimeout, oErrorBase.Message) > 0) or
               (Pos(CErrorWinHttpNombreNoResuelto,
                    oErrorBase.Message) > 0) or
               (Pos(CErrorWinHttpNoPuedeConectar,
                    oErrorBase.Message) > 0) or
               (Pos(CErrorWinHttpConexionInterrumpida,
                    oErrorBase.Message) > 0));
  end;
end;

end.
