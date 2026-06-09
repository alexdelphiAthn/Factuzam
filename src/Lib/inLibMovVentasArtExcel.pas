{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMovVentasArtExcel                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel (dxSpreadSheet) del informe "Movimientos de ventas    }
{    por artículos y fechas". Una fila por artículo con las magnitudes de      }
{    compra y venta del periodo y los dos márgenes. Si el SP devuelve          }
{    agrupaciones (GRUPO1..GRUPO3), dibuja una cabecera por grupo y una línea  }
{    de TOTAL por corte (sumas de las magnitudes base y porcentajes/márgenes   }
{    recalculados a partir de esas sumas, no sumando porcentajes).             }
{                                                                              }
{    Consume el resultado de PRC_GET_MOV_VENTAS_ART (mismo dataset filtrado    }
{    que alimenta el informe FastReport).                                      }
{******************************************************************************}
unit inLibMovVentasArtExcel;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, Data.DB, cxGraphics, Vcl.Graphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetContainers,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  dxGDIPlusClasses, dxSmartImage, inLibDevExcel;

procedure ExportarMovVentasArtExcel(ASheetControl: TdxSpreadSheet;
                                    const QDatos: TDataSet);

implementation

const
  COL_ART     = 0;                 // artículo (código + descripción)
  COL_UNIENT  = 1;
  COL_IMPENT  = 2;
  COL_UDSVTA  = 3;
  COL_IMPVTA  = 4;
  COL_IMPCOS  = 5;
  COL_BENEF   = 6;
  COL_PCTBNF  = 7;
  COL_VTAENT  = 8;
  COL_VENTENT = 9;
  COL_MARG1   = 10;
  COL_MARG2   = 11;
  COL_PCTVDTO = 12;
  COL_PCTVLAST = 13;
  COL_MAX     = COL_PCTVLAST;      // 13
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  FMT_PCT     = '#,##0.0';
  FMT_NUM_HZ  = '#,##0;-#,##0;';
  FMT_EUR_HZ  = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_TOTALES  = $00F2F2F2;
  CL_GRUPO_H  = $00EED7BD;
  CL_GRUPO_T  = $00F7EBDD;
  N_NIVELES   = 3;

type
  // Acumulador de las magnitudes BASE (sumables) de un grupo / total. Los
  // porcentajes y márgenes se derivan de estas sumas, no se acumulan.
  TAcum = record
    UniEnt : Double;
    ImpEnt : Double;
    UdsVta : Double;
    ImpVta : Double;
    ImpCos : Double;
    Benef  : Double;
    VtaEnt : Double;
    procedure Reset;
    procedure Add(const Q: TDataSet);
  end;

procedure TAcum.Reset;
begin
  UniEnt := 0; ImpEnt := 0; UdsVta := 0; ImpVta := 0;
  ImpCos := 0; Benef := 0; VtaEnt := 0;
end;

procedure TAcum.Add(const Q: TDataSet);
begin
  UniEnt := UniEnt + Q.FieldByName('UNI_ENT_TOT').AsFloat;
  ImpEnt := ImpEnt + Q.FieldByName('IMP_ENT_TOT').AsFloat;
  UdsVta := UdsVta + Q.FieldByName('UDS_VENTA').AsFloat;
  ImpVta := ImpVta + Q.FieldByName('IMP_VENTA').AsFloat;
  ImpCos := ImpCos + Q.FieldByName('IMP_COSTE').AsFloat;
  Benef  := Benef  + Q.FieldByName('BENEFICIO').AsFloat;
  VtaEnt := VtaEnt + Q.FieldByName('VENTA_ENT').AsFloat;
end;

procedure ExportarMovVentasArtExcel(ASheetControl: TdxSpreadSheet;
                                    const QDatos: TDataSet);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c, lvl, nivelCambio: Integer;
  grpCods : array[1..N_NIVELES] of string;
  grpEtqs : array[1..N_NIVELES] of string;
  grpUsado: array[1..N_NIVELES] of Boolean;
  grpAcum : array[1..N_NIVELES] of TAcum;
  totAcum : TAcum;

  procedure EscNum(ACol: Integer; AVal: Double; const AFmt: string;
                   AOcultarCero: Boolean);
  begin
    if (not AOcultarCero) or (AVal <> 0) then
    begin
      W(Sheet, iRow, ACol, AVal, False, ssahRight);
      Sheet.Cells[iRow, ACol].Style.DataFormat.FormatCode := AFmt;
    end;
  end;

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

  // Cabecera de columnas (se repite por grupo / al inicio).
  procedure CabeceraColumnas;
  var
    cc: Integer;
  begin
    W(Sheet, iRow, COL_ART,      'Art' + #237 + 'culo', True, ssahLeft);
    W(Sheet, iRow, COL_UNIENT,   'Uni.Ent.', True, ssahRight);
    W(Sheet, iRow, COL_IMPENT,   'Imp.Ent.', True, ssahRight);
    W(Sheet, iRow, COL_UDSVTA,   'Uds Vta',  True, ssahRight);
    W(Sheet, iRow, COL_IMPVTA,   'Imp Venta', True, ssahRight);
    W(Sheet, iRow, COL_IMPCOS,   'Imp Coste', True, ssahRight);
    W(Sheet, iRow, COL_BENEF,    'Beneficio', True, ssahRight);
    W(Sheet, iRow, COL_PCTBNF,   '% Bnf', True, ssahRight);
    W(Sheet, iRow, COL_VTAENT,   'Venta-Ent', True, ssahRight);
    W(Sheet, iRow, COL_VENTENT,  'VentEnt%', True, ssahRight);
    W(Sheet, iRow, COL_MARG1,    'Margen 1', True, ssahRight);
    W(Sheet, iRow, COL_MARG2,    'Margen 2', True, ssahRight);
    W(Sheet, iRow, COL_PCTVDTO,  '% V.dto', True, ssahRight);
    W(Sheet, iRow, COL_PCTVLAST, '% Vlast', True, ssahRight);
    for cc := 0 to COL_MAX do
      if Sheet.Cells[iRow, cc] <> nil then
      begin
        Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := CL_CABECERA;
        Sheet.Cells[iRow, cc].Style.Borders[bBottom].Style := sscbsThin;
      end;
  end;

  // Escribe una fila de totales (sumas base + porcentajes recalculados).
  procedure EscribirTotales(const A: TAcum; const ALabel: string;
                            AColorFondo: TColor);
  var
    cc: Integer;
  begin
    W(Sheet, iRow, COL_ART, ALabel, True, ssahLeft);
    EscNum(COL_UNIENT, A.UniEnt, FMT_NUM_HZ, False);
    EscNum(COL_IMPENT, A.ImpEnt, FMT_EUR_HZ, False);
    EscNum(COL_UDSVTA, A.UdsVta, FMT_NUM_HZ, False);
    EscNum(COL_IMPVTA, A.ImpVta, FMT_EUR_HZ, False);
    EscNum(COL_IMPCOS, A.ImpCos, FMT_EUR_HZ, False);
    EscNum(COL_BENEF,  A.Benef,  FMT_EUR_HZ, False);
    if A.ImpCos <> 0 then
      EscNum(COL_PCTBNF, A.Benef / A.ImpCos * 100, FMT_PCT, False);
    EscNum(COL_VTAENT, A.VtaEnt, FMT_EUR_HZ, False);
    if A.ImpEnt <> 0 then
      EscNum(COL_VENTENT, A.VtaEnt / A.ImpEnt * 100, FMT_PCT, False);
    if A.ImpVta <> 0 then
    begin
      EscNum(COL_MARG1, A.Benef / A.ImpVta * 100, FMT_PCT, False);
      EscNum(COL_MARG2, A.VtaEnt / A.ImpVta * 100, FMT_PCT, False);
    end;
    if A.UniEnt <> 0 then
      EscNum(COL_PCTVDTO, A.UdsVta / A.UniEnt * 100, FMT_PCT, False);
    if A.ImpEnt <> 0 then
      EscNum(COL_PCTVLAST, A.ImpVta / A.ImpEnt * 100, FMT_PCT, False);
    for cc := 0 to COL_MAX do
      if Sheet.Cells[iRow, cc] <> nil then
      begin
        Sheet.Cells[iRow, cc].Style.Font.Style := [fsBold];
        Sheet.Cells[iRow, cc].Style.Brush.BackgroundColor := AColorFondo;
        Sheet.Cells[iRow, cc].Style.Borders[bTop].Style := sscbsThin;
      end;
    Inc(iRow);
  end;

  // Cabecera de un nivel de grupo (sangrada). Reinicia su acumulador.
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
      CabeceraColumnas;
      Inc(iRow);
    end;
    grpAcum[ANivel].Reset;
  end;

  procedure EmitirResumenGrupo(ANivel: Integer);
  begin
    if grpUsado[ANivel] then
      EscribirTotales(grpAcum[ANivel], 'TOTAL ' + grpEtqs[ANivel], CL_GRUPO_T);
    grpAcum[ANivel].Reset;
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Ventas',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  for lvl := 1 to N_NIVELES do
  begin
    grpCods[lvl]  := #1;
    grpEtqs[lvl]  := '';
    grpUsado[lvl] := False;
    grpAcum[lvl].Reset;
  end;
  totAcum.Reset;
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'MOVIMIENTOS DE VENTAS POR ARTICULOS Y FECHAS', True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 14;
    Inc(iRow, 2);
    CabeceraColumnas;
    Inc(iRow);
    if (QDatos <> nil) and QDatos.Active and (not QDatos.IsEmpty) then
    begin
      QDatos.DisableControls;
      try
        QDatos.First;
        while not QDatos.Eof do
        begin
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
          end;
          // Fila de detalle del artículo (código + descripción + magnitudes).
          W(Sheet, iRow, COL_ART,
            QDatos.FieldByName('CODIGO_ART_ART').AsString + '  ' +
            QDatos.FieldByName('DESCRIPCION_ART').AsString);
          EscNum(COL_UNIENT,  QDatos.FieldByName('UNI_ENT_TOT').AsFloat, FMT_NUM, True);
          EscNum(COL_IMPENT,  QDatos.FieldByName('IMP_ENT_TOT').AsFloat, FMT_EUR, True);
          EscNum(COL_UDSVTA,  QDatos.FieldByName('UDS_VENTA').AsFloat,   FMT_NUM, True);
          EscNum(COL_IMPVTA,  QDatos.FieldByName('IMP_VENTA').AsFloat,   FMT_EUR, True);
          EscNum(COL_IMPCOS,  QDatos.FieldByName('IMP_COSTE').AsFloat,   FMT_EUR, True);
          EscNum(COL_BENEF,   QDatos.FieldByName('BENEFICIO').AsFloat,   FMT_EUR, True);
          EscNum(COL_PCTBNF,  QDatos.FieldByName('PCT_BNFCO').AsFloat,   FMT_PCT, True);
          EscNum(COL_VTAENT,  QDatos.FieldByName('VENTA_ENT').AsFloat,   FMT_EUR, True);
          EscNum(COL_VENTENT, QDatos.FieldByName('VENT_ENT').AsFloat,    FMT_PCT, True);
          EscNum(COL_MARG1,   QDatos.FieldByName('MARGEN1').AsFloat,     FMT_PCT, True);
          EscNum(COL_MARG2,   QDatos.FieldByName('MARGEN2').AsFloat,     FMT_PCT, True);
          EscNum(COL_PCTVDTO, QDatos.FieldByName('PCT_VDTO').AsFloat,    FMT_PCT, True);
          EscNum(COL_PCTVLAST, QDatos.FieldByName('PCT_VLAST').AsFloat,  FMT_PCT, True);
          totAcum.Add(QDatos);
          for lvl := 1 to N_NIVELES do
            if grpUsado[lvl] then
              grpAcum[lvl].Add(QDatos);
          Inc(iRow);
          QDatos.Next;
        end;
        if grpCods[1] <> #1 then
          for lvl := N_NIVELES downto 1 do
            EmitirResumenGrupo(lvl);
        // Total general.
        EscribirTotales(totAcum, 'TOTAL GENERAL', CL_GRUPO_H);
        Sheet.Cells[iRow - 1, 0].Style.Borders[bBottom].Style := sscbsThin;
      finally
        QDatos.EnableControls;
      end;
    end;
    // Anchos de columna.
    Sheet.Columns[COL_ART].Size := 240;
    for c := COL_UNIENT to COL_MAX do
      Sheet.Columns[c].Size := 72;
  finally
    Sheet.EndUpdate;
  end;
end;

end.
