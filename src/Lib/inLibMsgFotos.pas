{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgFotos                                               }
{    Tipo:       Recursos de texto                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes, captions y ayudas del subsistema de fotografías.               }
{******************************************************************************}
unit inLibMsgFotos;

interface

resourcestring
  SErrorFotoNoRegistradaParaPredeterminar =
    'No hay foto registrada para marcar como predeterminada.';
  SErrorFotoSeleccionadaCambio =
    'La foto seleccionada ha cambiado; actualiza la galería e inténtalo ' +
    'de nuevo.';
  SErrorGaleriaFotosCambio =
    'La galería de fotos ha cambiado; actualízala e inténtalo de nuevo.';
  SHintMostrarControlesFoto =
    'Mostrar u ocultar controles (F11)';
  SHintBajarFotosServidor =
    'Bajar fotos del servidor';
  SHintFotoPredeterminada =
    'Establecer esta foto como predeterminada';
  SHintFotoAnterior =
    'Foto anterior';
  SHintFotoSiguiente =
    'Foto siguiente';
  SHintAnadirFoto =
    'Añadir foto';
  SHintCambiarFotoArticulo =
    'Sustituir la foto principal del artículo';
  SHintCambiarFotoNivel =
    'Sustituir la foto principal del nivel seleccionado';
  SHintCambiarFotoLinea =
    'Cambiar la foto de la línea';
  SHintQuitarFoto =
    'Quitar la foto visible';
  SHintRotarFotoIzquierda =
    'Rotar la foto visible a la izquierda';
  SHintRotarFotoDerecha =
    'Rotar la foto visible a la derecha';
  SHintGuardarLayoutFoto =
    'Guardar posición, tamaño y resolución';
  SCaptionGaleriaConFotos =
    '%s — Foto %d/%d';
  SCaptionGaleriaSinFotos =
    '%s — Sin fotos';
  SCaptionFotoSesion =
    'Sesión %s/%s · línea %d · %s';
  STituloLayoutFotoArticulo =
    'Foto del artículo / SKU';

implementation

end.
