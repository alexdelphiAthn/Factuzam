{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgSubsanacionCaja                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mensajes del ajuste de importes de operaciones de caja.                   }
{******************************************************************************}
unit inLibMsgSubsanacionCaja;

interface

resourcestring
  SSubsanacionDescartar = '¿Descartar los cambios de la subsanación?';
  SSubsanacionModo =
    'Subsanación: edite el importe de cada línea. F12 abre el cobro para ' +
    'la forma de pago y el descuento global.';
  SSubsanacionTituloCobro = 'Subsanación: forma de pago y descuento global';
  SSubsanacionCobroExacto =
    'El cobro debe cuadrar con el total, sin cambio, vales ni importes ' +
    'a cuenta.';
  SSubsanacionMotivo = 'Motivo de la corrección';
  SSubsanacionLineasFijas =
    'En Subsanación no se pueden añadir o quitar líneas ni cambiar cantidades.';
  SSubsanacionMotivoObligatorio = 'Indique el motivo de la subsanación.';
  SSubsanacionBoton = 'Subsanar';
  SSubsanacionNoPermitida =
    'Seleccione un ticket vigente para subsanar.';
  SSubsanacionNoPermitidaVerifactu =
    'Modo VERIFACTU: el ticket %s/%s (fase "%s") no se puede subsanar. ' +
    'Sólo se subsanan tickets simplificados enviados y aceptados por la ' +
    'AEAT, sin envíos ni anulaciones pendientes.';
  SSubsanacionNoPermitidaNoVerifactu =
    'Modo NO VERI*FACTU: el ticket %s/%s (fase "%s") no se puede subsanar. ' +
    'Sólo se subsanan tickets simplificados con registro NO VERI*FACTU ' +
    'firmado y vigente.';
  SSubsanacionNoPermitidaSinVerifactu =
    'Modo SIN VeriFactu: el ticket %s/%s (fase "%s") no se puede subsanar. ' +
    'Sólo se subsanan tickets simplificados que no estén anulados, ' +
    'rectificados ni cancelados.';
  SSubsanacionGuardada = 'Subsanación guardada y encolada para VeriFactu.';
  SSubsanacionGuardadaLocal = 'Subsanación guardada.';
  SSubsanacionGuardadaNoVerifactu =
    'Subsanación guardada y registrada en NO VERI*FACTU.';
  SSubsanacionTituloOperacion = 'Subsanación de %s / %s';
  SSubsanacionReimprimir = 'Reimprimir';
  SSubsanacionSinLineas = 'La operación no tiene líneas para subsanar.';
  SSubsanacionCantidadInvalida =
    'La cantidad de la línea %s no es válida.';
  SSubsanacionDecimalesLinea =
    'El importe de la línea %s debe tener como máximo dos decimales.';
  SSubsanacionDecimalesTotal =
    'El importe total debe tener como máximo dos decimales.';
  SSubsanacionCantidadCero =
    'La línea %s no tiene cantidad y su importe debe ser cero.';
  SSubsanacionSignoLinea =
    'El importe de la línea %s debe conservar el signo de su cantidad.';
  SSubsanacionPrecisionLinea =
    'El importe de la línea %s no se puede obtener con un precio de ' +
    'cuatro decimales. Indique otro importe.';
  SSubsanacionTotalInicialCero =
    'No se puede repartir un total cuando el importe actual es cero. ' +
    'Corrija los importes por línea.';
  SSubsanacionSignoTotal =
    'El nuevo total debe conservar el signo del importe actual. ' +
    'Corrija los importes por línea si cambia el saldo de la operación.';
  SSubsanacionDatosNoDisponibles =
    'Las líneas de la operación no están disponibles.';
  SSubsanacionEdicionPendiente =
    'Termine de editar la línea antes de aplicar la subsanación.';
  SSubsanacionIdentificadorLinea =
    'Cada línea debe tener un identificador único y no vacío.';
  SSubsanacionLineasDistintas =
    'Las líneas de la operación han cambiado. Vuelva a cargar la operación.';
  SSubsanacionLineaModificada =
    'La cantidad o el importe de la línea %s ha cambiado. ' +
    'Vuelva a cargar la operación.';
  SSubsanacionPrecisionCantidad =
    'La cantidad de la línea %s tiene una precisión no admitida ' +
    'para subsanar su importe.';

implementation

end.
