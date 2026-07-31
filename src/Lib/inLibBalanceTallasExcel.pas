{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceTallasExcel                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.4.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de exportación Excel para el balance de almacén por tallas.       }
{******************************************************************************}
unit inLibBalanceTallasExcel;

interface

uses
  Data.DB, dxSpreadSheet, inLibFotos;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);

implementation

uses
  inLibBalanceExcelComun;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeConTallas);
end;

end.
