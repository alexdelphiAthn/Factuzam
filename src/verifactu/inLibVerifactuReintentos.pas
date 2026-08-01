{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuReintentos                                      }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas puras de espera y agotamiento de reintentos Verifactu.             }
{******************************************************************************}
unit inLibVerifactuReintentos;
interface
function CalcularEsperaReintentoVerifactu(AIntentos: Integer): Integer;
function CalcularEstadoReintentoVerifactu(
  AIntentos, AMaxIntentos: Integer): string;
implementation
function CalcularEsperaReintentoVerifactu(AIntentos: Integer): Integer;
begin
  if AIntentos > 5 then
    Result := 60 * 32
  else
    Result := 60 * (1 shl AIntentos);
end;
function CalcularEstadoReintentoVerifactu(
  AIntentos, AMaxIntentos: Integer): string;
begin
  if (AIntentos + 1) >= AMaxIntentos then
    Result := 'ERROR'
  else
    Result := 'PENDIENTE';
end;
end.
