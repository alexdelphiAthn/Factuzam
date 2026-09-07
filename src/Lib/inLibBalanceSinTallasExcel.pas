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
  Data.DB, dxSpreadSheet, inLibFotos, inLibBalanceExcelComun;

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos); overload;
// Con aviso de avance (fila procesada y total) para la ventana de espera.
procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos;
  const AProgreso: TProgresoBalanceExcel); overload;

implementation

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeSinTallas);
end;

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos;
  const AProgreso: TProgresoBalanceExcel);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeSinTallas,
    AProgreso);
end;

end.
