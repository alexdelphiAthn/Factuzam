{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgIntegraciones                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de servicios externos, nube y ventas web.                        }
{******************************************************************************}
unit inLibMsgIntegraciones;

interface

resourcestring
  SErrorDivisaNoEncontrada =
    'Divisa "%s" no encontrada en el resultado';
  SErrorHttpDivisas = 'HTTP %d: %s';
  SErrorRedDivisas = 'Error de red: %s';
  SErrorJsonDivisas = 'Respuesta JSON inválida';
  SErrorPruebaPilaJcl =
    'Prueba forzada con /teststack [%s]: JCL stack trace activo';
  SErrorHttpCripto = 'HTTP %d: %s';
  SErrorRedCripto = 'Error de red: %s';
  SErrorJsonCripto = 'Respuesta JSON inválida';
  SErrorRespuestaHttpFactuzamApi = 'Respuesta HTTP %d';
  SErrorFactuzamApiNoConfigurada =
    'La API de Factuzam no está configurada.';
  SInfoEventoFactuzamApiRecibido =
    'Evento recibido correctamente.';
  SInfoConsultaFactuzamApiRealizada =
    'Consulta realizada correctamente.';
  SInfoDocumentoFactuzamApiGuardado =
    'Documento guardado en %s';
  SInfoDocumentoFactuzamApiDescargado =
    'Documento descargado.';
  SErrorDescargaTraduccion =
    'No se pudo descargar la traducción: %s';
  SErrorPaqueteTraduccionInvalido =
    'El paquete de traducción no es válido: %s';
  SErrorConexionTraduccionNoDisponible =
    'No está disponible la conexión para instalar la traducción.';
  SErrorTraduccionTransaccionActiva =
    'No se puede instalar la traducción mientras hay una transacción activa.';
  SErrorTraduccionSinFilas =
    'El paquete no ha instalado ninguna traducción para %s.';
  SProgresoTraduccionPreparando =
    'Preparando la descarga de %s...';
  SProgresoTraduccionDescargando =
    'Descargando el paquete de traducción...';
  SProgresoTraduccionValidando =
    'Validando el manifiesto y las huellas SHA-256...';
  SProgresoTraduccionEjecutando =
    'Ejecutando %s (%d de %d)...';
  SProgresoTraduccionComprobando =
    'Comprobando el catálogo instalado...';
  SProgresoTraduccionDisponible =
    'La traducción ya está descargada y disponible.';
  SProgresoTraduccionAplicando =
    'Aplicando la traducción a la interfaz...';
  SProgresoTraduccionCompletada =
    'Traducción descargada y aplicada correctamente.';
  SErrorRespuestaFormateadorSqlVacia =
    'Respuesta vacía del servicio de formateo SQL';
  SErrorRespuestaFormateadorSqlInesperada =
    'Respuesta JSON inesperada del formateador SQL';
  SErrorEncolarVentaWebservice =
    'No se pudo encolar la venta %s\%s para el webservice.';
  SErrorVentasWsJsonNoRegistrado =
    'El serializador JSON de ventas no está registrado.';
  SErrorVentasWsColaNoRegistrada =
    'La persistencia de la cola de ventas no está registrada.';
  SErrorApiKeyInstalacionFaltante =
    'Falta la API key de la instalación.';
  SErrorDeclaracionWebserviceOtraVersion =
    'El webservice devolvió una declaración de otra versión.';
  // R10 - Importación de pedidos PrestaShop
  SCaptionConectandoPrestaShop = 'Conectando con PrestaShop...';
  SCaptionRecuperadosPedidos = 'Recuperados %d pedidos';
  SCaptionNoRecuperadosPedidos = 'No se pudieron recuperar pedidos';
  SCaptionImportandoPedido = 'Importando %s...';
  SCaptionErrorImportandoPedido = 'Error en %s: %s';
implementation

end.
