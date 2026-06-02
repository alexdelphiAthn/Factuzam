{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceTallasExcel                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel (dxSpreadSheet) del balance de almacén por tallas,    }
{    con un formato parecido al informe: agrupado por familia y artículo, con  }
{    las tallas como columnas (T01..T14) y una fila por color/banda. Consume   }
{    directamente el resultado del SP PRC_GET_BALANCE_ALMACEN_TALLAS (el mismo  }
{    dataset que alimenta el informe FastReport).                              }
{                                                                              }
{    Se rellena una hoja del TdxSpreadSheet que se le pasa; el guardado a      }
{    .xlsx y la previsualización los hace TfrmMtoPreviewExcel (igual patrón    }
{    que la exportación de inventario, inLibInventarioExcel).                  }
{******************************************************************************}
unit inLibBalanceTallasExcel;

interface

uses
  System.SysUtils, System.Variants, System.Classes, Data.DB,
  cxGraphics, Vcl.Graphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);

implementation

const
  N_TALLAS    = 14;
  COL_BANDA   = 0;
  COL_COLOR   = 1;
  COL_T1      = 2;                  // T01..T14 -> columnas 2..15
  COL_CDAD    = COL_T1 + N_TALLAS;  // 16
  COL_PRECIO  = COL_CDAD + 1;       // 17
  COL_IMPORTE = COL_CDAD + 2;       // 18
  COL_MAX     = COL_IMPORTE;        // 18
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  CL_CABECERA = $00EEEEEE;          // gris claro (cabecera de tallas)
  CL_FAMILIA  = $00D9D9D9;          // gris (familia)

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c: Integer;
  sFamAct, sArtAct, sFam, sArt: string;

  // Cabecera de tallas del artículo en curso (rótulos ETIQ_T01..ETIQ_T14).
  procedure CabeceraTallas;
  var
    k: Integer;
  begin
    W(Sheet, iRow, COL_COLOR, 'Color', True, ssahLeft);
    for k := 1 to N_TALLAS do
      W(Sheet, iRow, COL_T1 + k - 1,
        QDatos.FieldByName(Format('ETIQ_T%.2d', [k])).AsString, True, ssahCenter);
    W(Sheet, iRow, COL_CDAD,    'Cdad.',   True, ssahRight);
    W(Sheet, iRow, COL_PRECIO,  'Precio',  True, ssahRight);
    W(Sheet, iRow, COL_IMPORTE, 'Importe', True, ssahRight);
    for c := 0 to COL_MAX do
      if Sheet.Cells[iRow, c] <> nil then
      begin
        Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := CL_CABECERA;
        Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
      end;
  end;

  // Escribe un número; si AOcultarCero y vale 0, deja la celda vacía
  // (replica el HideZeros del informe para que no se vea ruido de ceros).
  procedure EscNum(ACol: Integer; AVal: Double; const AFmt: string;
                   AOcultarCero: Boolean);
  begin
    if (not AOcultarCero) or (AVal <> 0) then
    begin
      W(Sheet, iRow, ACol, AVal, False, ssahRight);
      Sheet.Cells[iRow, ACol].Style.DataFormat.FormatCode := AFmt;
    end;
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Balance',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'BALANCE DE ALMAC'#201'N POR TALLAS', True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 14;
    Inc(iRow, 2);
    // Forzar el primer salto de familia/artículo.
    sFamAct := #1;
    sArtAct := #1;
    if (QDatos <> nil) and QDatos.Active and (not QDatos.IsEmpty) then
    begin
      QDatos.DisableControls;
      try
        QDatos.First;
        while not QDatos.Eof do
        begin
          sFam := QDatos.FieldByName('CODIGO_FAM').AsString;
          sArt := QDatos.FieldByName('CODIGO_ART_ART').AsString;
          // Salto de familia.
          if sFam <> sFamAct then
          begin
            W(Sheet, iRow, 0, 'FAMILIA  ' + sFam + '  ' +
              QDatos.FieldByName('DESCRIPCION_FAM').AsString, True);
            for c := 0 to COL_MAX do
              if Sheet.Cells[iRow, c] <> nil then
                Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := CL_FAMILIA;
            Inc(iRow);
            sFamAct := sFam;
            sArtAct := #1;   // fuerza cabecera de artículo dentro de la familia
          end;
          // Salto de artículo: cabecera del artículo + cabecera de tallas.
          if sArt <> sArtAct then
          begin
            W(Sheet, iRow, 0, 'ART'#205'CULO  ' + sArt + '  ' +
              QDatos.FieldByName('DESCRIPCION_ART').AsString, True);
            if QDatos.FindField('REF_PRV') <> nil then
              W(Sheet, iRow, COL_IMPORTE,
                QDatos.FieldByName('REF_PRV').AsString, False, ssahRight);
            Inc(iRow);
            CabeceraTallas;
            Inc(iRow);
            sArtAct := sArt;
          end;
          // Fila de banda (color + tallas + totales de la banda).
          W(Sheet, iRow, COL_BANDA,
            QDatos.FieldByName('ETIQUETA_BANDA').AsString);
          W(Sheet, iRow, COL_COLOR, QDatos.FieldByName('COLOR').AsString);
          for c := 1 to N_TALLAS do
            EscNum(COL_T1 + c - 1,
              QDatos.FieldByName(Format('T%.2d', [c])).AsFloat, FMT_NUM, True);
          EscNum(COL_CDAD,    QDatos.FieldByName('CANTIDAD').AsFloat, FMT_NUM, True);
          EscNum(COL_PRECIO,  QDatos.FieldByName('PRECIO').AsFloat,   FMT_EUR, False);
          EscNum(COL_IMPORTE, QDatos.FieldByName('IMPORTE').AsFloat,  FMT_EUR, False);
          Inc(iRow);
          QDatos.Next;
        end;
      finally
        QDatos.EnableControls;
      end;
    end;
    // Anchos de columna.
    Sheet.Columns[COL_BANDA].Size  := 120;
    Sheet.Columns[COL_COLOR].Size  := 90;
    for c := 0 to N_TALLAS - 1 do
      Sheet.Columns[COL_T1 + c].Size := 42;
    Sheet.Columns[COL_CDAD].Size    := 60;
    Sheet.Columns[COL_PRECIO].Size  := 70;
    Sheet.Columns[COL_IMPORTE].Size := 80;
  finally
    Sheet.EndUpdate;
  end;
end;

end.
