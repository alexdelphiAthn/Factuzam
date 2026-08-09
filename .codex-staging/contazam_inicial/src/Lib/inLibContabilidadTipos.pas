{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContabilidadTipos                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Tipos de dominio estables para asientos e importaciones.                  }
{******************************************************************************}
unit inLibContabilidadTipos;

interface

type
  TLineaAsiento = record
    Cuenta: string;
    Concepto: string;
    Debe: Currency;
    Haber: Currency;
  end;

  TEstadoValidacionAsiento = (
    evaValido,
    evaSinLineasSuficientes,
    evaCuentaVacia,
    evaImporteInvalido,
    evaDescuadrado,
    evaDocumentoNoArchivado
  );

  TResultadoValidacionAsiento = record
    Estado: TEstadoValidacionAsiento;
    Mensaje: string;
    TotalDebe: Currency;
    TotalHaber: Currency;
    function EsValido: Boolean;
  end;

  TResultadoImportacionFacturas = record
    Importadas: Integer;
    Omitidas: Integer;
  end;

implementation

function TResultadoValidacionAsiento.EsValido: Boolean;
begin
  Result := Estado = evaValido;
end;

end.
