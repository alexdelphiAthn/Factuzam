{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuEnvio                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Punto de integración con el cliente de envío de registros de              }
{    facturación a la AEAT (librerías OdaVeriFactu). Mientras no esté          }
{    integrado, el envío se declara no disponible y la cola se acumula.        }
{******************************************************************************}
unit inLibVerifactuEnvio;

interface

uses
  System.SysUtils, Uni;

type
  // Resultado del envío de un registro de facturación. Los campos calcan
  // las columnas de fza_facturas_consolidaciones para que el worker de la
  // cola persista la respuesta del servicio sin transformaciones.
  TResultadoEnvioVerifactu = record
    Ok:                Boolean;
    MensajeError:      string;
    RequestId:         string;    // REQUEST_ID_CONSOLIDACION_FACCON
    QueueId:           Integer;   // QUEUE_ID_CONSOLIDACION_FACCON
    IssuerIrsId:       string;    // ISSUER_IRS_ID_CONSOLIDACION_FACCON
    IssuedTime:        TDateTime; // ISSUED_TIME_FACCON
    ChainNumber:       string;    // CHAIN_NUMBER_FACCON
    ChainHash:         string;    // CHAIN_HASH_FACCON
    VerifactuUrl:      string;    // VERIFACTU_URL_FACCON
    QRCodeBase64:      string;    // QRCODE_BASE64_FACCON
    PeticionCompleta:  string;    // PETICION_COMPLETA_FACCON
    RespuestaCompleta: string;    // RESPUESTA_COMPLETA_FACCON
  end;

// True cuando el cliente AEAT está integrado y configurado. Mientras sea
// False el hilo de la cola no reclama filas: quedan en PENDIENTE.
function EnvioVerifactuDisponible: Boolean;

// Envía a la AEAT el registro de facturación de la factura indicada.
// ATipoOperacion: 'ALTA' o 'ANULACION'.
function EnviarRegistroFactura(AConn: TUniConnection;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;

implementation

// ===========================================================================
//   PUNTO DE INTEGRACIÓN ODAVERIFACTU
//   Aquí se enchufan las librerías de OdaVeriFactu: construcción del XML
//   del registro de facturación (alta/anulación), huella SHA-256
//   encadenada, firma y transporte SOAP con certificado hacia los
//   endpoints de la AEAT (PRE/PRO según inLibVerifactu.VerifactuEntorno).
//   El identificador serie+número del registro debe componerse con
//   inLibVerifactu.ComponerNumSerieFactura para coincidir con el QR.
// ===========================================================================

function EnvioVerifactuDisponible: Boolean;
begin
  Result := False;
end;

function EnviarRegistroFactura(AConn: TUniConnection;
                               const ASerie, ANumero, ATipoOperacion: string)
                               : TResultadoEnvioVerifactu;
begin
  Result.Ok           := False;
  Result.QueueId      := 0;
  Result.IssuedTime   := 0;
  Result.MensajeError :=
    'Cliente de envío Verifactu no integrado (librerías OdaVeriFactu)';
end;

end.
