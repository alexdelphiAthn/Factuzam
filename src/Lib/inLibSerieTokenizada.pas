{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSerieTokenizada                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tokens de las series de empresa por calendario natural:                   }
{    yyyy = año (2026), yy = año con dos cifras (26), q = trimestre,           }
{    mm = mes y dd = día. Distingue mayúsculas, como el SQL de las vistas      }
{    (vi_empresas_series) y de la búsqueda de series en facturas.              }
{******************************************************************************}
unit inLibSerieTokenizada;

interface

const
  TOKEN_SERIE_EJERCICIO = 'yyyy';
  TOKEN_SERIE_EJERCICIO_CORTO = 'yy';
  TOKEN_SERIE_TRIMESTRE = 'q';
  TOKEN_SERIE_MES = 'mm';
  TOKEN_SERIE_DIA = 'dd';

// Al menos un token, ninguno repetido y sin mezclar yyyy con yy.
function EsSerieTokenizadaValida(const ASerieTokenizada: string): Boolean;
function ResolverSerieTokenizada(
  const ASerieTokenizada: string; AFecha: TDateTime): string;

implementation

uses
  System.SysUtils, inLibCadenas;

function EsSerieTokenizadaValida(const ASerieTokenizada: string): Boolean;
var
  iDias: Integer;
  iEjercicios: Integer;
  iEjerciciosCortos: Integer;
  iMeses: Integer;
  iTrimestres: Integer;
begin
  iEjercicios := ContarOcurrenciasAnsi(
    ASerieTokenizada, TOKEN_SERIE_EJERCICIO);
  // yy se cuenta fuera de los yyyy, que lo contienen
  iEjerciciosCortos := ContarOcurrenciasAnsi(
    StringReplace(ASerieTokenizada, TOKEN_SERIE_EJERCICIO, '',
      [rfReplaceAll]),
    TOKEN_SERIE_EJERCICIO_CORTO);
  iTrimestres := ContarOcurrenciasAnsi(
    ASerieTokenizada, TOKEN_SERIE_TRIMESTRE);
  iMeses := ContarOcurrenciasAnsi(ASerieTokenizada, TOKEN_SERIE_MES);
  iDias := ContarOcurrenciasAnsi(ASerieTokenizada, TOKEN_SERIE_DIA);
  Result := (iEjercicios + iEjerciciosCortos <= 1) and
            (iTrimestres <= 1) and
            (iMeses <= 1) and
            (iDias <= 1) and
            (iEjercicios + iEjerciciosCortos + iTrimestres + iMeses +
             iDias > 0);
end;

function ResolverSerieTokenizada(
  const ASerieTokenizada: string; AFecha: TDateTime): string;
var
  iAnio: Word;
  iDia: Word;
  iMes: Word;
begin
  DecodeDate(AFecha, iAnio, iMes, iDia);
  // yyyy antes que yy: el año de cuatro cifras ya no deja ninguna "yy"
  Result := StringReplace(
    ASerieTokenizada,
    TOKEN_SERIE_EJERCICIO,
    Format('%.4d', [iAnio]),
    [rfReplaceAll]);
  Result := StringReplace(
    Result,
    TOKEN_SERIE_EJERCICIO_CORTO,
    Format('%.2d', [iAnio mod 100]),
    [rfReplaceAll]);
  Result := StringReplace(
    Result,
    TOKEN_SERIE_MES,
    Format('%.2d', [iMes]),
    [rfReplaceAll]);
  Result := StringReplace(
    Result,
    TOKEN_SERIE_DIA,
    Format('%.2d', [iDia]),
    [rfReplaceAll]);
  Result := StringReplace(
    Result,
    TOKEN_SERIE_TRIMESTRE,
    IntToStr(((iMes - 1) div 3) + 1),
    [rfReplaceAll]);
end;

end.
