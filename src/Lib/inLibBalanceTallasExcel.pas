{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceTallasExcel                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel (dxSpreadSheet) del balance de almacén por tallas,    }
{    con un formato parecido al informe: agrupado por familia y artículo, con  }
{    las tallas como columnas (T01..T14) y una fila por color/banda. Al cerrar  }
{    cada artículo se emite una fila de TOTAL por banda, calculada con         }
{    FÓRMULAS de Excel (=SUM(...)) sobre las filas de detalle (no números      }
{    fijos), de modo que recalculan si se editan las celdas. Se incrusta       }
{    además la foto 300px del artículo a la derecha del bloque.                }
{                                                                              }
{    Consume directamente el resultado del SP PRC_GET_BALANCE_ALMACEN_TALLAS    }
{    (mismo dataset filtrado que alimenta el informe; respeta el filtrado de   }
{    bandas, almacenes, familias, proveedores y temporadas).                   }
{******************************************************************************}
unit inLibBalanceTallasExcel;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, Data.DB, cxGraphics, Vcl.Graphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetContainers,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel, inLibFotos;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);

implementation

type
  // Acumulador de una banda dentro de un artículo: el rótulo, el precio
  // (constante por banda) y los índices de las filas de detalle (un color
  // cada una) para construir las fórmulas de total con =SUM(celdas).
  TBandaTot = class
  public
    Etiqueta: string;
    Precio  : Double;
    Filas   : TList<Integer>;
    constructor Create;
    destructor Destroy; override;
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
  COL_FOTO    = COL_IMPORTE + 2;    // 20: zona libre a la derecha del dato
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  // Formatos que ocultan el cero (sección de cero vacía), para que las
  // fórmulas de total no muestren 0 (como el HideZeros del informe).
  FMT_NUM_HZ  = '#,##0;-#,##0;';
  FMT_EUR_HZ  = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_FAMILIA  = $00D9D9D9;
  CL_TOTALES  = $00F2F2F2;

constructor TBandaTot.Create;
begin
  inherited Create;
  Filas := TList<Integer>.Create;
end;

destructor TBandaTot.Destroy;
begin
  Filas.Free;
  inherited Destroy;
end;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
                                     const QDatos: TDataSet);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c: Integer;
  sFamAct, sArtAct, sFam, sArt: string;
  dictBandas : TObjectDictionary<string, TBandaTot>;
  ordenBandas: TStringList;

  procedure EscNum(ACol: Integer; AVal: Double; const AFmt: string;
                   AOcultarCero: Boolean);
  begin
    if (not AOcultarCero) or (AVal <> 0) then
    begin
      W(Sheet, iRow, ACol, AVal, False, ssahRight);
      Sheet.Cells[iRow, ACol].Style.DataFormat.FormatCode := AFmt;
    end;
  end;

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

  // Incrusta la foto 300px del artículo en la zona libre de la derecha,
  // empezando en la misma fila del artículo (catTwoCell para ajustar el
  // tamaño al bloque de celdas). Si no hay foto, no hace nada.
  procedure IncrustarFoto(const ACodArt: string; AFilaArt: Integer);
  var
    info : TFotoInfo;
    sRuta: string;
    Pic  : TdxSpreadSheetPictureContainer;
  begin
    if oFotos <> nil then
    begin
      info  := oFotos.Resolver(ACodArt, '');
      sRuta := oFotos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        Pic := Sheet.Containers.AddImage(sRuta);
        Pic.AnchorType := catTwoCell;
        Pic.AnchorPoint1.Cell := Sheet.CreateCell(AFilaArt, COL_FOTO);
        Pic.AnchorPoint2.Cell := Sheet.CreateCell(AFilaArt + 6, COL_FOTO + 2);
      end;
    end;
  end;

  // Suma la fila actual (un color) al acumulador de su banda.
  procedure AcumularBanda;
  var
    cod: string;
    bt : TBandaTot;
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
    bt.Filas.Add(iRow);   // fila de detalle de este color
  end;

  // Construye '=SUM(celda1,celda2,...)' para una columna sobre las filas de
  // detalle de la banda. Las celdas vacías (ceros omitidos) suman 0.
  function SumaFormula(AFilas: TList<Integer>; ACol: Integer): string;
  var
    j: Integer;
    s: string;
  begin
    s := '';
    for j := 0 to AFilas.Count - 1 do
    begin
      if s <> '' then
        s := s + ',';
      s := s + GetRef(AFilas[j], ACol);
    end;
    Result := '=SUM(' + s + ')';
  end;

  // Emite una fila de TOTAL por banda (con fórmulas) y vacía el acumulador.
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
        WFormula(Sheet, iRow, COL_T1 + k - 1,
          SumaFormula(bt.Filas, COL_T1 + k - 1), FMT_NUM_HZ);
      WFormula(Sheet, iRow, COL_CDAD, SumaFormula(bt.Filas, COL_CDAD), FMT_NUM_HZ);
      W(Sheet, iRow, COL_PRECIO, bt.Precio, False, ssahRight);
      Sheet.Cells[iRow, COL_PRECIO].Style.DataFormat.FormatCode := FMT_EUR;
      WFormula(Sheet, iRow, COL_IMPORTE,
        SumaFormula(bt.Filas, COL_IMPORTE), FMT_EUR_HZ);
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
            sArtAct := #1;
          end;
          // Salto de artículo: cabecera + foto + cabecera de tallas.
          if sArt <> sArtAct then
          begin
            W(Sheet, iRow, 0, 'ART'#205'CULO  ' + sArt + '  ' +
              QDatos.FieldByName('DESCRIPCION_ART').AsString, True);
            if QDatos.FindField('REF_PRV') <> nil then
              W(Sheet, iRow, COL_IMPORTE,
                QDatos.FieldByName('REF_PRV').AsString, False, ssahRight);
            IncrustarFoto(sArt, iRow);
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
