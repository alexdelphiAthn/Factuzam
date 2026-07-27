{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDiag                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.1                                                         }
{   Fecha:       24/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de diagnóstico para verificar el cableado de manejo            }
{    de excepciones (JCL stack trace + AppException + log + modal).            }
{                                                                              }
{    Uso: arrancar fzam.exe con el switch /teststack. Tras el                  }
{    arranque del form principal se encola una excepción de prueba             }
{    con varios niveles de llamada para que el stack tenga frames              }
{    visibles y se distinga si JCL está rellenando E.StackTrace.               }
{                                                                              }
{    Directivas locales: forzamos sin optimización, con stack frames           }
{    y sin inlining para que cada capa intermedia aparezca como                }
{    frame propio en el volcado de pila (de lo contrario el                    }
{    compilador colapsa las llamadas triviales).                               }
{******************************************************************************}
unit inLibDiag;

{$O-}
{$STACKFRAMES ON}
{$INLINE OFF}

interface

procedure ProbarStackTrace;

implementation

uses
  System.SysUtils, inLibMsg;

// Cada capa concatena su nombre a la traza para que el compilador
// no pueda colapsar la llamada (tail call) ni inlinearla. Así
// el stack trace muestra los 4 frames de la cadena.

procedure LanzarExcepcionProfunda(const ATraza: string);
begin
  raise Exception.CreateFmt(SErrorPruebaPilaJcl, [ATraza]);
end;

procedure CapaProfunda(const ATraza: string);
begin
  LanzarExcepcionProfunda(ATraza + ' -> profunda');
end;

procedure CapaMedia(const ATraza: string);
begin
  CapaProfunda(ATraza + ' -> media');
end;

procedure CapaSuperficial(const ATraza: string);
begin
  CapaMedia(ATraza + ' -> superficial');
end;

procedure ProbarStackTrace;
begin
  CapaSuperficial('arranque');
end;

end.
