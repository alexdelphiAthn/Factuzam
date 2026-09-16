{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgPersistenciaSubsanacionCaja                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mensajes de validación y guardado de subsanaciones de caja.               }
{******************************************************************************}
unit inLibMsgPersistenciaSubsanacionCaja;

interface

resourcestring
  SSubsanacionSinPermiso =
    'No dispone de permiso para modificar los cobros de caja.';
  SSubsanacionIdentidadInvalida =
    'Seleccione una operación con factura, empresa, almacén y caja.';
  SSubsanacionFacturaNoVigente =
    'Sólo se pueden subsanar tickets emitidos y vigentes de esta operación.';
  SSubsanacionRegistroNoAceptado =
    'El ticket debe tener un registro aceptado en VeriFactu y no tener ' +
    'envíos o anulaciones pendientes.';
  SSubsanacionOperacionCompleja =
    'Esta subsanación admite ventas simples sin depósitos, devoluciones, ' +
    'vales, deuda ni recibos asociados.';
  SSubsanacionPagoUnico =
    'Esta subsanación requiere un único cobro en euros, sin compensaciones.';
  SSubsanacionDescuadreOriginal =
    'Los importes del ticket, sus líneas, la operación y el cobro no ' +
    'coinciden. Revise la operación antes de subsanar.';
  SSubsanacionArqueoCerrado =
    'La operación pertenece a un arqueo cerrado y no se puede subsanar.';
  SSubsanacionDatosFiscales =
    'El ticket requiere revisar sus datos fiscales antes de subsanar ' +
    'los importes de caja.';
  SSubsanacionConflicto =
    'La operación ha cambiado desde que se abrió. Vuelva a cargarla.';
  SSubsanacionMotivoObligatorio =
    'Indique el motivo de la subsanación, con un máximo de 500 caracteres.';
  SSubsanacionMedioInvalido =
    'Seleccione una forma de pago activa en euros, sin vales ni deuda.';
  SSubsanacionReferenciaInvalida =
    'La forma de pago requiere referencia o supera los 100 caracteres.';
  SSubsanacionSinCambios =
    'No se han modificado los importes ni la forma de pago.';
  SSubsanacionTotalInvalido =
    'El importe corregido de esta venta no puede ser negativo.';
  SSubsanacionTransaccionActiva =
    'Finalice la operación pendiente antes de guardar la subsanación.';
  SSubsanacionEsquemaPendiente =
    'Falta instalar la actualización 20260916_caja_subsanaciones.sql.';
  SSubsanacionCalculoInvalido =
    'No se ha podido cuadrar el importe corregido con los impuestos ' +
    'originales del ticket: %s';
  SSubsanacionTotalFiscalDistinto =
    'el total fiscal no coincide con el importe solicitado';
  SSubsanacionLineaIntactaDistinta =
    'el recálculo cambiaría otra línea que no se ha corregido';

implementation

end.
