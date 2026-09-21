{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgDistribucionTiendas                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mensajes de la distribución entre tiendas y de las propuestas de          }
{    traspaso.                                                                 }
{******************************************************************************}
unit inLibMsgDistribucionTiendas;

interface

resourcestring
  // --- Persistencia ---------------------------------------------------------
  SErrorDocumentoDistribucionNoExiste =
    'No existe el documento de trabajo %d.';
  SErrorPropuestaTraspasoNoExiste =
    'No existe la propuesta de traspaso %d.';
  SErrorDistribucionTiendasDesactualizada =
    'Alguna propuesta de este documento se ha confirmado mientras se ' +
    'editaba la distribución. Cierre la ventana y vuelva a abrirla para ' +
    'ver el reparto actualizado; los cambios sin guardar se perderán.';
  SErrorSkuDistribucionFueraDocumento =
    'La unidad %s ya no está en el documento de trabajo.';
  SErrorPropuestaTraspasoNoPendiente =
    'La propuesta de traspaso %d ya no está pendiente o no corresponde ' +
    'al origen %s y al destino %s.';
  SErrorPropuestaTraspasoSinCaja =
    'El almacén %s no tiene ninguna caja asignada: confirme la propuesta ' +
    'desde Traspasos de caja en ese almacén.';
  SErrorPropuestaTraspasoSinLineas =
    'La propuesta de traspaso %d no tiene unidades que traspasar.';

  // --- Ventana de distribución ---------------------------------------------
  STituloDistribucionTiendas = 'Distribución entre almacenes';
  STituloDistribucionTiendasDocumento =
    'Distribución entre almacenes - %s';
  SCaptionOrigenAutomaticoDistribucion =
    'Automático: el que más unidades tenga';
  SFormatoAlmacenDistribucion = '%s - %s';
  SCaptionColArticuloDistribucion = 'Artículo';
  SCaptionColDescripcionDistribucion = 'Descripción';
  SCaptionColColorDistribucion = 'Color';
  SCaptionColUnidadesDistribucion = 'Unidades';
  SCaptionColRepartidasDistribucion = 'Repartidas';
  SCaptionColPorRepartirDistribucion = 'Por repartir';
  SCaptionColAlmacenDistribucion = 'Almacén';
  SCaptionColNombreAlmacenDistribucion = 'Nombre';
  SCaptionColTotalDistribucion = 'Total';
  SCaptionColSinTallaDistribucion = 'Uds.';
  SAvisoDistribucionSinUnidades =
    'No quedaban unidades suficientes: se han asignado %s.';
  SAvisoDistribucionSueloConfirmado =
    'Esa tienda ya tiene %s unidades traspasadas: no se puede bajar de ahí.';
  SAvisoDistribucionEsOrigen =
    'Ese almacén es origen de la talla: muestra lo que le queda.';
  SAvisoDistribucionOrigenExcedido =
    'El documento tiene ahora menos unidades de las que ya se habían ' +
    'repartido. Las celdas en negativo indican dónde sobra reparto.';
  SInfoDistribucionSinLineas =
    'El documento de trabajo no tiene unidades con talla y almacén para ' +
    'repartir.';
  SInfoDistribucionGuardada =
    'Reparto guardado: %d propuestas de traspaso pendientes.';
  SInfoRepartoAutomaticoHecho =
    'Reparto automático: %s unidades asignadas.';
  SInfoRepartoAutomaticoNada =
    'El reparto automático no ha encontrado unidades que asignar con ' +
    'esos parámetros.';
  SPreguntaGuardarDistribucion =
    'Hay cambios sin guardar en el reparto. ¿Desea guardarlos?';
  SPreguntaVaciarDistribucion =
    '¿Desea quitar todo el reparto pendiente? Lo ya confirmado se conserva.';

  // --- Propuestas -----------------------------------------------------------
  SCaptionColNumeroPropuesta = 'Propuesta';
  SCaptionColFechaPropuesta = 'Fecha';
  SCaptionColDocumentoPropuesta = 'Documento de trabajo';
  SCaptionColOrigenPropuesta = 'Origen';
  SCaptionColDestinoPropuesta = 'Destino';
  SCaptionColUnidadesPropuesta = 'Unidades';
  SCaptionColEstadoPropuesta = 'Estado';
  SCaptionColTraspasoPropuesta = 'Traspaso';
  SCaptionColOperacionPropuesta = 'Operación';
  STextoEstadoPropuestaPendiente = 'Pendiente';
  STextoEstadoPropuestaConfirmada = 'Confirmada';
  SFormatoTraspasoPropuesta = '%s %s/%s';
  SInfoSeleccionarPropuesta =
    'Seleccione una propuesta de traspaso.';
  SInfoPropuestaYaConfirmada =
    'La propuesta %d ya está confirmada.';
  SPreguntaConfirmarPropuesta =
    'Se va a traspasar la propuesta %d: %s unidades de %s a %s. ' +
    'El traspaso mueve el stock y no se puede deshacer desde aquí. ' +
    '¿Desea continuar?';
  SPreguntaConfirmarTodasPropuestas =
    'Se van a traspasar las %d propuestas pendientes de este documento. ' +
    'Los traspasos mueven el stock y no se pueden deshacer desde aquí. ' +
    '¿Desea continuar?';
  SInfoPropuestaConfirmada =
    'Propuesta %d confirmada: traspaso %s %s/%s.';
  SInfoPropuestasConfirmadas =
    'Propuestas confirmadas: %d de %d.';
  SErrorPropuestaNoConfirmada =
    'La propuesta %d no se ha podido confirmar: %s';
  SPreguntaEliminarPropuesta =
    '¿Desea eliminar la propuesta pendiente %d?';
  SInfoNoHayPropuestasPendientes =
    'No hay propuestas pendientes.';
  SInfoNoHayPropuestasPendientesOrigen =
    'No hay propuestas de traspaso pendientes con origen en %s.';
  STituloSeleccionPropuestaTraspaso =
    'Confirmar propuesta de traspaso - origen %s';
  SCaptionConfirmarPropuesta = 'Confirmar propuesta';
  SInfoPropuestaCargadaEnTraspaso =
    'Propuesta %d cargada con destino %s. Revise las unidades y grabe el ' +
    'traspaso para confirmarla.';

  // --- Documento de trabajo y albarán de compra -----------------------------
  STituloDocumentoDistribucionAlbaran = 'Distribución albarán %s/%s';
  SErrorAlbaranCompraSinGrabarDistribuir =
    'Grabe el albarán de compra antes de distribuirlo.';
  SErrorAlbaranCompraSinLineasDistribuir =
    'El albarán de compra no tiene líneas con artículo y cantidad que ' +
    'distribuir.';
  STituloElegirDocumentoDistribucion =
    'Documento de trabajo que se va a distribuir';

  // --- Reparto automático ---------------------------------------------------
  STituloRepartoAutomatico = 'Reparto automático';
  SCaptionCriterioOrdenAlmacen = 'En ronda, por orden de almacén';
  SCaptionCriterioMenorStock = 'Primero la tienda con menos existencias';

  // --- Informe --------------------------------------------------------------
  STituloInformePropuestaTraspaso = 'Propuesta de traspaso';
  SFormatoNumeroInformePropuesta = 'Propuesta nº %d';
  SFormatoOrigenInformePropuesta = 'Origen: %s';
  SFormatoDestinoInformePropuesta = 'Destino: %s';
  SFormatoDocumentoInformePropuesta = 'Documento de trabajo %d - %s';
  SFormatoEstadoInformePropuesta = 'Estado: %s';
  SCaptionColTallasInformePropuesta = 'Tallas (talla: unidades)';
  SCaptionTotalInformePropuesta = 'Total unidades';
  SFormatoTallaInformePropuesta = '%s: %s';
  SNombreArchivoPropuestasTraspaso = 'Propuestas_traspaso_%d';

implementation

end.
