{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceTallasExcel                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel (dxSpreadSheet) del balance de almacén por tallas,    }
{    con un formato parecido al informe: agrupado por familia y artículo, con  }
{    las tallas como columnas (T01..T14) y una fila por color/banda. Al cerrar  }
{    cada artículo se emite una fila de TOTAL por banda (suma de colores).     }
{    Consume directamente el resultado del SP PRC_GET_BALANCE_ALMACEN_TALLAS    }
{    (el mismo dataset filtrado que alimenta el informe; respeta por tanto el  }
{    filtrado de bandas, almacenes, familias, proveedores y temporadas).       }
{                                                                              }
{    Se rellena una hoja del TdxSpreadSheet que se le pasa; el guardado a      }
{    .xlsx y la previsualización los hace TfrmMtoPreviewExcel (igual patrón    }
{    que la exportación de inventario, inLibInventarioExcel).                  }
{******************************************************************************}
unit inLibBalanceTallasExcel;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, Data.DB, cxGraphics, Vcl.Graphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);

implementation

type
  // Acumulador de totales de una banda dentro de un artículo (suma de
  // colores). El precio es constante por banda (coste o PVP del artículo).
  TBandaTot = class
  public
    Etiqueta: string;
    Precio  : Double;
    Cantidad: Double;
    Importe : Double;
    T       : array[1..14] of Double;
  end;

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
  CL_TOTALES  = $00F2F2F2;          // gris muy claro (fila de totales)

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c: Integer;
  sFamAct, sArtAct, sFam, sArt: string;
  dictBandas : TObjectDictionary<string, TBandaTot>;
  ordenBandas: TStringList;

  // Escribe un número; si AOcultarCero y vale 0, deja la celda vacía
  // (replica el HideZeros del informe para no llenar de ceros).
  procedure EscNum(ACol: Integer; AVal: Double; const AFmt: string;
                   AOcultarCero: Boolean);
  begin
    if (not AOcultarCero) or (AVal <> 0) then
    begin
      W(Sheet, iRow, ACol, AVal, False, ssahRight);
      Sheet.Cells[iRow, ACol].Style.DataFormat.FormatCode := AFmt;
    end;
  end;

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

  // Suma la fila actual (un color) al acumulador de su banda.
  procedure AcumularBanda;
  var
    cod: string;
    bt : TBandaTot;
    k  : Integer;
  begin
    cod := QDatos.FieldByName('BANDA').AsString;
    if not dictBandas.TryGetValue(cod, bt) then
    begin
      bt := TBandaTot.Create;
      bt.Etiqueta := QDatos.FieldByName('ETIQUETA_BANDA').AsString;
      bt.Precio   := QDatos.FieldByName('PRECIO').AsFloat;
      dictBandas.Add(cod, bt);
      ordenBandas.Add(cod);
    end;
    for k := 1 to N_TALLAS do
      bt.T[k] := bt.T[k] + QDatos.FieldByName(Format('T%.2d', [k])).AsFloat;
    bt.Cantidad := bt.Cantidad + QDatos.FieldByName('CANTIDAD').AsFloat;
    bt.Importe  := bt.Importe  + QDatos.FieldByName('IMPORTE').AsFloat;
  end;

  // Emite una fila de TOTAL por banda (en el orden en que aparecieron) y
  // vacía el acumulador para el siguiente artículo.
  procedure EmitirTotalesArticulo;
  var
    i, k: Integer;
    bt  : TBandaTot;
  begin
    for i := 0 to ordenBandas.Count - 1 do
    begin
      bt := dictBandas[ordenBandas[i]];
      W(Sheet, iRow, COL_BANDA, bt.Etiqueta, True, ssahLeft);
      W(Sheet, iRow, COL_COLOR, 'TOTAL', True, ssahLeft);
      for k := 1 to N_TALLAS do
        EscNum(COL_T1 + k - 1, bt.T[k], FMT_NUM, True);
      EscNum(COL_CDAD,    bt.Cantidad, FMT_NUM, True);
      EscNum(COL_PRECIO,  bt.Precio,   FMT_EUR, False);
      EscNum(COL_IMPORTE, bt.Importe,  FMT_EUR, False);
      for c := 0 to COL_MAX do
        if Sheet.Cells[iRow, c] <> nil then
        begin
          Sheet.Cells[iRow, c].Style.Font.Style := [fsBold];
          Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := CL_TOTALES;
          Sheet.Cells[iRow, c].Style.Borders[bTop].Style := sscbsThin;
        end;
      Inc(iRow);
    end;
    Inc(iRow);   // fila en blanco de separación
    dictBandas.Clear;
    ordenBandas.Clear;
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Balance',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  dictBandas  := TObjectDictionary<string, TBandaTot>.Create([doOwnsValues]);
  ordenBandas := TStringList.Create;
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'BALANCE DE ALMAC'#201'N POR TALLAS', True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 14;
    Inc(iRow, 2);
    sFamAct := #1;   // fuerza el primer salto de familia/artículo
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
          // Cambio de artículo: cerrar el anterior con sus totales por banda.
          if (sArt <> sArtAct) and (sArtAct <> #1) then
            EmitirTotalesArticulo;
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
          // Fila de banda (detalle por color) + acumular para los totales.
          W(Sheet, iRow, COL_BANDA,
            QDatos.FieldByName('ETIQUETA_BANDA').AsString);
          W(Sheet, iRow, COL_COLOR, QDatos.FieldByName('COLOR').AsString);
          for c := 1 to N_TALLAS do
            EscNum(COL_T1 + c - 1,
              QDatos.FieldByName(Format('T%.2d', [c])).AsFloat, FMT_NUM, True);
          EscNum(COL_CDAD,    QDatos.FieldByName('CANTIDAD').AsFloat, FMT_NUM, True);
          EscNum(COL_PRECIO,  QDatos.FieldByName('PRECIO').AsFloat,   FMT_EUR, False);
          EscNum(COL_IMPORTE, QDatos.FieldByName('IMPORTE').AsFloat,  FMT_EUR, False);
          AcumularBanda;
          Inc(iRow);
          QDatos.Next;
        end;
        // Totales del último artículo.
        if sArtAct <> #1 then
          EmitirTotalesArticulo;
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
    FreeAndNil(ordenBandas);
    FreeAndNil(dictBandas);
  end;
end;

end.
