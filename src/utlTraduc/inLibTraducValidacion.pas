{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraducValidacion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba los marcadores de Format de los textos traducidos.              }
{******************************************************************************}
unit inLibTraducValidacion;

interface

function FirmaMarcadoresFormato(const ATexto: string): string;
function MarcadoresFormatoCompatibles(
  const ATextoOrigen, ATextoDestino: string): Boolean;

implementation

uses
  System.SysUtils;

function EsModificadorMarcador(ACaracter: Char): Boolean;
begin
  Result :=
    CharInSet(ACaracter, ['0'..'9']) or
    CharInSet(ACaracter, [':', '-', '.']);
end;

function EsTipoMarcador(ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    UpCase(ACaracter),
    ['D', 'U', 'E', 'F', 'G', 'N', 'M', 'P', 'S', 'X']);
end;

function FirmaMarcadoresFormato(const ATexto: string): string;
var
  Caracter: Char;
  Indice: Integer;
  PosicionTipo: Integer;
begin
  Result := '';
  Indice := 1;
  while Indice <= Length(ATexto) do
  begin
    if ATexto[Indice] = '%' then
    begin
      if (Indice < Length(ATexto)) and
         (ATexto[Indice + 1] = '%') then
        Inc(Indice, 2)
      else
      begin
        PosicionTipo := Indice + 1;
        while (PosicionTipo <= Length(ATexto)) and
              EsModificadorMarcador(ATexto[PosicionTipo]) do
          Inc(PosicionTipo);
        if (PosicionTipo <= Length(ATexto)) and
           EsTipoMarcador(ATexto[PosicionTipo]) then
        begin
          Caracter := UpCase(ATexto[PosicionTipo]);
          Result := Result + Caracter + ';';
          Indice := PosicionTipo + 1;
        end
        else
          Inc(Indice);
      end;
    end
    else
      Inc(Indice);
  end;
end;

function MarcadoresFormatoCompatibles(
  const ATextoOrigen, ATextoDestino: string): Boolean;
begin
  Result :=
    FirmaMarcadoresFormato(ATextoOrigen) =
    FirmaMarcadoresFormato(ATextoDestino);
end;

end.
