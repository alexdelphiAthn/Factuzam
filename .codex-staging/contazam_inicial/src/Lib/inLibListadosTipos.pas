{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListadosTipos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Tipos estables y títulos de los listados contables básicos.              }
{******************************************************************************}
unit inLibListadosTipos;

interface

type
  TTipoListadoContable = (
    tlBalanceSumasSaldos,
    tlLibroDiario,
    tlLibroMayor,
    tlAsientosBorrador,
    tlArchivoDocumental
  );

function TituloListado(
  ATipo: TTipoListadoContable): string;
function RecursoListado(
  ATipo: TTipoListadoContable): string;

implementation

function RecursoListado(
  ATipo: TTipoListadoContable): string;
begin
  case ATipo of
    tlBalanceSumasSaldos:
      Result := 'LISTADO_BALANCE';
    tlLibroDiario:
      Result := 'LISTADO_DIARIO';
    tlLibroMayor:
      Result := 'LISTADO_MAYOR';
    tlAsientosBorrador:
      Result := 'LISTADO_BORRADORES';
    tlArchivoDocumental:
      Result := 'LISTADO_DOCUMENTOS';
  else
    Result := 'LISTADOS';
  end;
end;

function TituloListado(
  ATipo: TTipoListadoContable): string;
begin
  case ATipo of
    tlBalanceSumasSaldos:
      Result := 'Balance de sumas y saldos';
    tlLibroDiario:
      Result := 'Libro diario';
    tlLibroMayor:
      Result := 'Libro mayor';
    tlAsientosBorrador:
      Result := 'Asientos pendientes y borradores';
    tlArchivoDocumental:
      Result := 'Archivo documental y referencias PDF';
  else
    Result := 'Listado contable';
  end;
end;

end.
