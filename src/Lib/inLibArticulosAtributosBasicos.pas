{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosAtributosBasicos                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de composición de códigos para atributos básicos globales o       }
{    exclusivos de un artículo.                                                }
{******************************************************************************}
unit inLibArticulosAtributosBasicos;

interface

type
  TAmbitoCodigoAtributoBasico = (
    acabGlobal,
    acabAdHoc);

function ComponerCodigoAtributoBasico(
  AAmbito: TAmbitoCodigoAtributoBasico;
  const ACodigoArticulo, ANombre: string): string;

implementation

uses
  System.SysUtils;

function ComponerCodigoAtributoBasico(
  AAmbito: TAmbitoCodigoAtributoBasico;
  const ACodigoArticulo, ANombre: string): string;
const
  MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO = 100;
var
  sNombreNormalizado: string;
begin
  sNombreNormalizado := StringReplace(
    ANombre, ' ', '_', [rfReplaceAll]);
  if AAmbito = acabAdHoc then
    Result := Format(
      'AD_%s_%s', [ACodigoArticulo, sNombreNormalizado])
  else
    Result := sNombreNormalizado;
  if Length(Result) > MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO then
    Result := Copy(Result, 1, MAX_LONGITUD_CODIGO_ATRIBUTO_BASICO);
end;

end.
