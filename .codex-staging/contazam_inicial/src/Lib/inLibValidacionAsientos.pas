{******************************************************************************}
{                                                                              }
{  Módulo:       inLibValidacionAsientos                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas puras para validar el equilibrio de un asiento contable.           }
{******************************************************************************}
unit inLibValidacionAsientos;

interface

uses
  inLibContabilidadTipos;

type
  TValidadorAsientos = class
  public
    class function Validar(
      const ALineas: TArray<TLineaAsiento>):
      TResultadoValidacionAsiento; static;
  end;

implementation

uses
  System.SysUtils, System.Math;

class function TValidadorAsientos.Validar(
  const ALineas: TArray<TLineaAsiento>):
  TResultadoValidacionAsiento;
var
  oLinea: TLineaAsiento;
  bSeguir: Boolean;
begin
  Result := Default(TResultadoValidacionAsiento);
  Result.Estado := evaSinLineasSuficientes;
  Result.Mensaje := 'El asiento necesita al menos dos apuntes.';
  bSeguir := Length(ALineas) >= 2;
  if bSeguir then
  begin
    Result.Estado := evaValido;
    Result.Mensaje := '';
    for oLinea in ALineas do
    begin
      if Trim(oLinea.Cuenta) = '' then
      begin
        Result.Estado := evaCuentaVacia;
        Result.Mensaje := 'Todos los apuntes necesitan una cuenta.';
        bSeguir := False;
      end;
      if bSeguir and
         (((oLinea.Debe > 0) and (oLinea.Haber > 0)) or
          ((oLinea.Debe <= 0) and (oLinea.Haber <= 0))) then
      begin
        Result.Estado := evaImporteInvalido;
        Result.Mensaje :=
          'Cada apunte debe tener importe solo en Debe o en Haber.';
        bSeguir := False;
      end;
      if bSeguir then
      begin
        Result.TotalDebe := Result.TotalDebe + oLinea.Debe;
        Result.TotalHaber := Result.TotalHaber + oLinea.Haber;
      end;
    end;
    if bSeguir and
       (not SameValue(Result.TotalDebe, Result.TotalHaber, 0.005)) then
    begin
      Result.Estado := evaDescuadrado;
      Result.Mensaje := Format(
        'El asiento está descuadrado. Debe %.2f / Haber %.2f.',
        [Result.TotalDebe, Result.TotalHaber]);
    end;
  end;
end;

end.

