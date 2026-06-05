{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceSinTallasExcel                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel (dxSpreadSheet) del balance de almacén SIN tallas.    }
{    Variante vertical del export por tallas: agrupado por familia y artículo, }
{    con una fila por color/banda y columnas Concepto / Color / Cantidad /     }
{    Precio / Importe (sin las columnas de talla). Al cerrar cada artículo     }
{    emite una fila TOTAL por banda con FÓRMULAS =SUM(...) sobre las filas de  }
{    detalle. Incrusta la foto del artículo en un hueco a la derecha.          }
{                                                                              }
{    Si el SP devuelve agrupaciones (GRUPO1..GRUPO3), dibuja una cabecera por  }
{    grupo y una línea de resumen (TOTAL del grupo, =SUM de cantidad e         }
{    importe) en cada corte, con el mismo criterio que el informe FastReport.  }
{                                                                              }
{    Consume el resultado de PRC_GET_BALANCE_ALMACEN_SIN_TALLAS (mismo dataset }
{    filtrado que alimenta el informe).                                        }
{******************************************************************************}
unit inLibBalanceSinTallasExcel;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, Data.DB, cxGraphics, Vcl.Graphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetContainers,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  dxGDIPlusClasses, dxSmartImage, inLibDevExcel, inLibFotos;

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
                                        const QDatos: TDataSet);

implementation

type
  // Acumulador de una banda dentro de un artículo: rótulo, precio (constante
  // por banda) y filas de detalle (un color cada una) para las fórmulas de
  // total con =SUM(celdas).
  TBandaTot = class
  public
    Etiqueta: string;
    Precio  : Double;
    Filas   : TList<Integer>;
    constructor Create;
    destructor Destroy; override;
  end;

const
  COL_BANDA   = 0;
  COL_COLOR   = 1;
  COL_CDAD    = 2;
  COL_PRECIO  = 3;
  COL_IMPORTE = 4;
  COL_VENTAS  = 5;                 // ventas reales (importe real de venta)
  COL_MAX     = COL_VENTAS;        // 5
  COL_FOTO    = COL_VENTAS + 2;    // 7: hueco a la derecha del dato
  FOTO_W      = 110;                // ancho fijo de la columna de la foto (px)
  FOTO_H_MAX  = 170;                // alto máximo de la fila de la foto (px)
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  FMT_NUM_HZ  = '#,##0;-#,##0;';
  FMT_EUR_HZ  = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_FAMILIA  = $00D9D9D9;
  CL_TOTALES  = $00F2F2F2;
  CL_GRUPO_H  = $00EED7BD;
  CL_GRUPO_T  = $00F7EBDD;
  N_NIVELES   = 3;

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

procedure ExportarBalanceSinTallasExcel(ASheetControl: TdxSpreadSheet;
                                        const QDatos: TDataSet);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c: Integer;
  sFamAct, sArtAct, sFam, sArt: string;
  dictBandas : TObjectDictionary<string, TBandaTot>;
  ordenBandas: TStringList;
  dictFotos  : TDictionary<string, TFotoInfo>;   // foto por artículo (1 query)
  slCod      : TStringList;
  grpCods    : array[1..N_NIVELES] of string;
  grpEtqs    : array[1..N_NIVELES] of string;
  grpUsado   : array[1..N_NIVELES] of Boolean;
  grpFilas   : array[1..N_NIVELES] of TList<Integer>;
  grpExifCant: array[1..N_NIVELES] of Double;   // existencias finales (uds) por grupo
  grpExifImp : array[1..N_NIVELES] of Double;   // existencias finales (valor) por grupo
  ventasFila, exifCantFila, exifImpFila: Double; // valores de la fila actual
  totExifCant, totExifImp, totVentas: Double;   // acumulados del total general
  lvl, nivelCambio: Integer;

  procedure EscNum(ACol: Integer; AVal: Double; const AFmt: string;
                   AOcultarCero: Boolean);
  begin
    if (not AOcultarCero) or (AVal <> 0) then
    begin
      W(Sheet, iRow, ACol, AVal, False, ssahRight);
      Sheet.Cells[iRow, ACol].Style.DataFormat.FormatCode := AFmt;
    end;
  end;

  procedure CabeceraConceptos;
  var
    cc: Integer;
  begin
    W(Sheet, iRow, COL_BANDA,    'Concepto', True, ssahLeft);
    W(Sheet, iRow, COL_COLOR,    'Color',    True, ssahLeft);
    W(Sheet, iRow, COL_CDAD,     'Cantidad', True, ssahRight);
    W(Sheet, iRow, COL_PRECIO,   'Precio',   True, ssahRight);
    W(Sheet, iRow, COL_IMPORTE,  'Importe',  True, ssahRight);
    W(Sheet, iRow, COL_VENTAS,   'Ventas',   True, ssahRight);
    for cc := 0 to COL_MAX do
      if Sheet.Cells[iRow, cc] <> nil then
      begin
        Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := CL_CABECERA;
        Sheet.Cells[iRow, cc].Style.Borders[bBottom].Style := sscbsThin;
      end;
  end;

  // Incrusta la foto del artículo en el hueco de la derecha, con el ancho de
  // columna fijo y el alto de fila según el aspecto (para no deformar).
  procedure IncrustarFoto(const ACodArt: string; AFilaArt: Integer);
  var
    info : TFotoInfo;
    sRuta: string;
    img  : TdxSmartImage;
    Pic  : TdxSpreadSheetPictureContainer;
    iAlto: Integer;
  begin
    if (dictFotos <> nil) and dictFotos.TryGetValue(ACodArt, info) and
       info.Encontrada then
    begin
      sRuta := oFotos.RutaFoto(info, frPx300);
      if (sRuta <> '') and FileExists(sRuta) then
      begin
        img := TdxSmartImage.Create;
        try
          img.LoadFromFile(sRuta);
          Pic := Sheet.Containers.Add(TdxSpreadSheetPictureContainer)
                   as TdxSpreadSheetPictureContainer;
          Pic.Picture.Image := img;
          Pic.AnchorType := catTwoCell;
          Pic.AnchorPoint1.Cell := Sheet.CreateCell(AFilaArt, COL_FOTO);
          Pic.AnchorPoint2.Cell := Sheet.CreateCell(AFilaArt + 1, COL_FOTO + 1);
          if (img.Width > 0) and (img.Height > 0) then
          begin
            Sheet.Columns[COL_FOTO].Size := FOTO_W;
            iAlto := Round(FOTO_W * img.Height / img.Width);
            if iAlto > FOTO_H_MAX then
              iAlto := FOTO_H_MAX;
            if iAlto < 1 then
              iAlto := 1;
            Sheet.Rows[AFilaArt].Size := iAlto;
          end;
        finally
          img.Free;
        end;
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
    bt.Filas.Add(iRow);
  end;

  // '=SUM(celda1,celda2,...)' para una columna sobre las filas de detalle.
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

  // Fila de TOTAL por banda (con fórmulas) y vacía el acumulador.
  procedure EmitirTotalesArticulo;
  var
    i, cc: Integer;
    bt  : TBandaTot;
  begin
    for i := 0 to ordenBandas.Count - 1 do
    begin
      bt := dictBandas[ordenBandas[i]];
      W(Sheet, iRow, COL_BANDA, bt.Etiqueta, True, ssahLeft);
      W(Sheet, iRow, COL_COLOR, 'TOTAL', True, ssahLeft);
      WFormula(Sheet, iRow, COL_CDAD, SumaFormula(bt.Filas, COL_CDAD), FMT_NUM_HZ);
      W(Sheet, iRow, COL_PRECIO, bt.Precio, False, ssahRight);
      Sheet.Cells[iRow, COL_PRECIO].Style.DataFormat.FormatCode := FMT_EUR;
      WFormula(Sheet, iRow, COL_IMPORTE,
        SumaFormula(bt.Filas, COL_IMPORTE), FMT_EUR_HZ);
      WFormula(Sheet, iRow, COL_VENTAS,
        SumaFormula(bt.Filas, COL_VENTAS), FMT_EUR_HZ);
      for cc := 0 to COL_MAX do
        if Sheet.Cells[iRow, cc] <> nil then
        begin
          Sheet.Cells[iRow, cc].Style.Font.Style := [fsBold];
          Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := CL_TOTALES;
          Sheet.Cells[iRow, cc].Style.Borders[bTop].Style := sscbsThin;
        end;
      Inc(iRow);
    end;
    Inc(iRow);   // fila en blanco de separación
    dictBandas.Clear;
    ordenBandas.Clear;
  end;

  // Valor de un campo de grupo (defensivo: '' si el SP no expone la columna).
  function CampoStr(const AName: string): string;
  var
    fld: TField;
  begin
    fld := QDatos.FindField(AName);
    if fld <> nil then
      Result := fld.AsString
    else
      Result := '';
  end;

  // Cabecera de un nivel de grupo (sangrada por nivel). Reinicia sus filas.
  procedure AbrirGrupo(ANivel: Integer);
  var
    cc: Integer;
  begin
    if grpUsado[ANivel] then
    begin
      W(Sheet, iRow, 0, StringOfChar(' ', (ANivel - 1) * 2) + grpEtqs[ANivel],
        True, ssahLeft);
      Sheet.Cells[iRow, 0].Style.Font.Size := 12;
      for cc := 0 to COL_MAX do
        if Sheet.Cells[iRow, cc] <> nil then
        begin
          Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := CL_GRUPO_H;
          Sheet.Cells[iRow, cc].Style.Borders[bBottom].Style := sscbsThin;
        end;
      Inc(iRow);
    end;
    grpFilas[ANivel].Clear;
    grpExifCant[ANivel] := 0;
    grpExifImp[ANivel]  := 0;
  end;

  // Resumen (grand total) de un nivel: una línea con la suma de cantidad e
  // importe de TODAS las filas de detalle del grupo (=SUM en vivo).
  procedure EmitirResumenGrupo(ANivel: Integer);
  var
    cc: Integer;
  begin
    if grpUsado[ANivel] and (grpFilas[ANivel].Count > 0) then
    begin
      W(Sheet, iRow, 0, 'TOTAL ' + grpEtqs[ANivel], True, ssahLeft);
      // Cantidad/Importe del total = SOLO existencias finales (stock); las
      // ventas van aparte en su columna.
      EscNum(COL_CDAD,    grpExifCant[ANivel], FMT_NUM_HZ, False);
      EscNum(COL_IMPORTE, grpExifImp[ANivel],  FMT_EUR_HZ, False);
      WFormula(Sheet, iRow, COL_VENTAS,
        SumaFormula(grpFilas[ANivel], COL_VENTAS), FMT_EUR_HZ);
      for cc := 0 to COL_MAX do
        if Sheet.Cells[iRow, cc] <> nil then
        begin
          Sheet.Cells[iRow, cc].Style.Font.Style := [fsBold];
          Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := CL_GRUPO_T;
          Sheet.Cells[iRow, cc].Style.Borders[bTop].Style := sscbsThin;
        end;
      Inc(iRow);
    end;
    grpFilas[ANivel].Clear;
    grpExifCant[ANivel] := 0;
    grpExifImp[ANivel]  := 0;
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Balance',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  dictBandas  := TObjectDictionary<string, TBandaTot>.Create([doOwnsValues]);
  ordenBandas := TStringList.Create;
  for lvl := 1 to N_NIVELES do
  begin
    grpFilas[lvl] := TList<Integer>.Create;
    grpCods[lvl]  := #1;
    grpEtqs[lvl]  := '';
    grpUsado[lvl] := False;
    grpExifCant[lvl] := 0;
    grpExifImp[lvl]  := 0;
  end;
  totExifCant := 0;
  totExifImp := 0;
  totVentas := 0;
  // Pre-carga de fotos a nivel artículo en UNA consulta (evita el N+1).
  dictFotos := nil;
  if (QDatos <> nil) and QDatos.Active and (not QDatos.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      QDatos.DisableControls;
      try
        QDatos.First;
        while not QDatos.Eof do
        begin
          slCod.Add(QDatos.FieldByName('CODIGO_ART_ART').AsString);
          QDatos.Next;
        end;
      finally
        QDatos.EnableControls;
      end;
      dictFotos := oFotos.ResolverArticulosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'BALANCE DE ALMACEN SIN TALLAS', True);
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
          // Agrupaciones: detectar el nivel de corte, cerrar y abrir grupos.
          grpUsado[1] := CampoStr('GRUPO1_ETIQ') <> '';
          grpUsado[2] := CampoStr('GRUPO2_ETIQ') <> '';
          grpUsado[3] := CampoStr('GRUPO3_ETIQ') <> '';
          nivelCambio := N_NIVELES + 1;
          for lvl := 1 to N_NIVELES do
            if (nivelCambio > N_NIVELES) and grpUsado[lvl] and
               (CampoStr(Format('GRUPO%d_COD', [lvl])) <> grpCods[lvl]) then
              nivelCambio := lvl;
          if nivelCambio <= N_NIVELES then
          begin
            if grpCods[1] <> #1 then
              for lvl := N_NIVELES downto nivelCambio do
                EmitirResumenGrupo(lvl);
            for lvl := nivelCambio to N_NIVELES do
            begin
              grpCods[lvl] := CampoStr(Format('GRUPO%d_COD', [lvl]));
              grpEtqs[lvl] := CampoStr(Format('GRUPO%d_ETIQ', [lvl]));
              AbrirGrupo(lvl);
            end;
            sFamAct := #1;
            sArtAct := #1;
          end;
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
          // Salto de artículo: cabecera + foto + cabecera de columnas.
          if sArt <> sArtAct then
          begin
            W(Sheet, iRow, 0, 'ARTICULO  ' + sArt + '  ' +
              QDatos.FieldByName('DESCRIPCION_ART').AsString, True);
            if QDatos.FindField('REF_PRV') <> nil then
              W(Sheet, iRow, COL_IMPORTE,
                QDatos.FieldByName('REF_PRV').AsString, False, ssahRight);
            IncrustarFoto(sArt, iRow);
            Inc(iRow);
            CabeceraConceptos;
            Inc(iRow);
            sArtAct := sArt;
          end;
          // Fila de detalle (color/banda) + acumular para los totales.
          W(Sheet, iRow, COL_BANDA,
            QDatos.FieldByName('ETIQUETA_BANDA').AsString);
          W(Sheet, iRow, COL_COLOR, QDatos.FieldByName('COLOR').AsString);
          EscNum(COL_CDAD,    QDatos.FieldByName('CANTIDAD').AsFloat, FMT_NUM, True);
          EscNum(COL_PRECIO,  QDatos.FieldByName('PRECIO').AsFloat,   FMT_EUR, False);
          EscNum(COL_IMPORTE, QDatos.FieldByName('IMPORTE').AsFloat,  FMT_EUR, False);
          // Ventas reales: solo <> 0 en la banda de ventas. Se escribe en el
          // detalle (oculta el cero) para sumarlas con =SUM en los totales de
          // artículo, grupo y total general.
          ventasFila := QDatos.FieldByName('VENTAS').AsFloat;
          EscNum(COL_VENTAS, ventasFila, FMT_EUR, True);
          AcumularBanda;
          // Totales por grupo / general: SOLO existencias finales (uds + valor)
          // y ventas. EXIFIN_CANT/IMP solo son <> 0 en la banda de exist. fin.
          exifCantFila := QDatos.FieldByName('EXIFIN_CANT').AsFloat;
          exifImpFila  := QDatos.FieldByName('EXIFIN_IMP').AsFloat;
          totExifCant := totExifCant + exifCantFila;
          totExifImp  := totExifImp + exifImpFila;
          totVentas   := totVentas + ventasFila;
          for lvl := 1 to N_NIVELES do
            if grpUsado[lvl] then
            begin
              grpFilas[lvl].Add(iRow);
              grpExifCant[lvl] := grpExifCant[lvl] + exifCantFila;
              grpExifImp[lvl]  := grpExifImp[lvl] + exifImpFila;
            end;
          Inc(iRow);
          QDatos.Next;
        end;
        if sArtAct <> #1 then
          EmitirTotalesArticulo;
        if grpCods[1] <> #1 then
          for lvl := N_NIVELES downto 1 do
            EmitirResumenGrupo(lvl);
        // Total general (cantidad, importe y ventas).
        W(Sheet, iRow, 0, 'TOTAL GENERAL', True, ssahLeft);
        EscNum(COL_CDAD,     totExifCant, FMT_NUM_HZ, False);
        EscNum(COL_IMPORTE,  totExifImp,  FMT_EUR_HZ, False);
        EscNum(COL_VENTAS,   totVentas,   FMT_EUR_HZ, False);
        for c := 0 to COL_MAX do
          if Sheet.Cells[iRow, c] <> nil then
          begin
            Sheet.Cells[iRow, c].Style.Font.Style := [fsBold];
            Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := CL_GRUPO_H;
            Sheet.Cells[iRow, c].Style.Borders[bTop].Style := sscbsThin;
            Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
          end;
        Inc(iRow);
      finally
        QDatos.EnableControls;
      end;
    end;
    // Anchos de columna.
    Sheet.Columns[COL_BANDA].Size   := 140;
    Sheet.Columns[COL_COLOR].Size   := 120;
    Sheet.Columns[COL_CDAD].Size     := 70;
    Sheet.Columns[COL_PRECIO].Size   := 75;
    Sheet.Columns[COL_IMPORTE].Size  := 90;
    Sheet.Columns[COL_VENTAS].Size := 90;
  finally
    Sheet.EndUpdate;
    FreeAndNil(ordenBandas);
    FreeAndNil(dictBandas);
    FreeAndNil(dictFotos);
    for lvl := 1 to N_NIVELES do
      FreeAndNil(grpFilas[lvl]);
  end;
end;

end.
