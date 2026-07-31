{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceSinTallasExcel                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de exportación Excel para el balance de almacén sin tallas.       }
{******************************************************************************}
unit inLibBalanceSinTallasExcel;

interface

uses
  Data.DB, dxSpreadSheet, inLibFotos;

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);

implementation

uses
  inLibBalanceExcelComun;

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeSinTallas);
end;

end.
