{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDiag                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
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
{******************************************************************************}
unit inLibDiag;

interface

procedure ProbarStackTrace;

implementation

uses
  System.SysUtils;

// Tres niveles encadenados para que la pila no quede plana.
procedure LanzarExcepcionProfunda;
begin
  raise Exception.Create
    ('Prueba forzada con /teststack: verificación de JCL stack trace');
end;

procedure CapaIntermedia;
begin
  LanzarExcepcionProfunda;
end;

procedure CapaSuperficial;
begin
  CapaIntermedia;
end;

procedure ProbarStackTrace;
begin
  CapaSuperficial;
end;

end.
