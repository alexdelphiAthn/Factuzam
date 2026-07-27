{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRectificativas                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas SQL compartidas para facturas rectificativas.                      }
{******************************************************************************}
unit inLibRectificativas;

interface

function SQLExcluirSimplificadaSustituida(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
function DebeGenerarMovimientosRectificativa(
  const ATipoRectificativa: string;
  AReemplazarMovimientosOriginales: Boolean): Boolean;

implementation

uses
  System.SysUtils;

function DebeGenerarMovimientosRectificativa(
  const ATipoRectificativa: string;
  AReemplazarMovimientosOriginales: Boolean): Boolean;
begin
  Result := (not SameText(Trim(ATipoRectificativa), 'S')) or
    AReemplazarMovimientosOriginales;
end;

function SQLExcluirSimplificadaSustituida(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
begin
  // La original deja de intervenir cuando existe una rectificativa S.
  Result :=
    ' AND NOT EXISTS (' +
    ' SELECT 1 ' +
    ' FROM fza_facturas fo ' +
    ' JOIN fza_facturas_relaciones fr ' +
    '   ON fr.SERIE_FAC_ORIGEN_FACREL = fo.SERIE_FAC ' +
    '  AND fr.NUMERO_FAC_ORIGEN_FACREL = fo.NUMERO_FAC ' +
    ' JOIN fza_facturas fs ' +
    '   ON fs.CODIGO_EMP_FAC = fo.CODIGO_EMP_FAC ' +
    '  AND fs.SERIE_FAC = fr.SERIE_FAC_FACREL ' +
    '  AND fs.NUMERO_FAC = fr.NUMERO_FAC_FACREL ' +
    ' WHERE fo.CODIGO_EMP_FAC = ' + ACampoEmpresa +
    '   AND fo.SERIE_FAC = ' + ACampoSerie +
    '   AND fo.NUMERO_FAC = ' + ACampoNumero +
    '   AND fo.TIPO_FAC = ''SIMPLIFICADA'' ' +
    '   AND fo.FASE_FAC = ''RECTIFICADA'' ' +
    '   AND fr.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
    '   AND fs.TIPO_RECTIFICATIVA_FAC = ''S'' ' +
    ' ) ';
end;

end.
