{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoDevEx                                         }
{    Tipo:       Librería (adaptador)                                          }
{ Versión:       1.1.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador de IEscritorHojaCalculo sobre DevExpress (TdxSpreadSheet).      }
{    ÚNICA unidad del subsistema que ve tipos Tdx*. Las 4 operaciones de       }
{    bajo nivel (mezclar, escribir, fórmula, cuadro) son métodos de clase      }
{    (fuente única): las usan tanto el puerto como los shims de inLibDevExcel. }
{    v1.1 (Fase 2): añade formato, fondo, borde por lado, tamaño de fuente,    }
{    negrita, ancho de columna, lote y existencia de celda.                    }
{******************************************************************************}
unit inLibHojaCalculoDevEx;

interface

uses
  dxSpreadSheet, dxSpreadSheetCore, Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, cxGraphics,
  System.Classes, Vcl.Graphics, System.Types,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxHashUtils,
  inLibHojaCalculoIntf;

type
  EHojaCalculo = class(Exception);
  // Adaptador DevExpress del puerto de escritura. Envuelve un control
  // TdxSpreadSheet (o una vista de tabla suelta para los shims legacy).
  TEscritorHojaCalculoDevEx = class(TInterfacedObject, IEscritorHojaCalculo,
    ILectorHojaCalculo)
  private
    FControl: TdxSpreadSheet;
    FTabla: TdxSpreadSheetTableView;
    function MapAlineacion(
      AAlineacion: TAlineacionCelda): TdxSpreadSheetDataAlignHorz;
    function MapBorde(AEstilo: TEstiloBorde): TdxSpreadSheetCellBorderStyle;
    procedure AsegurarTabla;
  public
    constructor Create(const AControl: TdxSpreadSheet);
    constructor CreateTabla(const ATabla: TdxSpreadSheetTableView);
    // Operaciones dx de bajo nivel (fuente única). Reciben tipos dx tal cual
    // para que los shims de inLibDevExcel deleguen sin mapeo inverso.
    class procedure MezclarDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol, AColCount, AFilaCount: Integer); static;
    class procedure EscribirCeldaDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol: Integer; const AValor: Variant; ANegrita: Boolean;
      ADxAlineacion: TdxSpreadSheetDataAlignHorz); static;
    class procedure EscribirFormulaDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol: Integer; const AFormula, AFormato: string); static;
    class procedure PintarCuadroDx(const ATabla: TdxSpreadSheetTableView;
      AF1, AC1, AF2, AC2: Integer;
      ADxEstilo: TdxSpreadSheetCellBorderStyle); static;
    // IEscritorHojaCalculo
    procedure NuevaHoja(const ANombre: string);
    procedure IniciarLote;
    procedure FinalizarLote;
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant;
      ANegrita: Boolean = False;
      AAlineacion: TAlineacionCelda = acIzquierda;
      const AFormato: string = '');
    procedure EscribirFormula(AFila, ACol: Integer; const AFormula: string;
      const AFormato: string = '');
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
      AEstilo: TEstiloBorde);
    procedure BordeCelda(AFila, ACol: Integer; ALado: TLadoBorde;
      AEstilo: TEstiloBorde);
    procedure FondoCelda(AFila, ACol: Integer; AColor: Cardinal);
    procedure Negrita(AFila, ACol: Integer; AActivar: Boolean = True);
    procedure TamanoFuente(AFila, ACol: Integer; ATamano: Integer);
    procedure AnchoColumna(ACol: Integer; AAncho: Integer);
    function CeldaExiste(AFila, ACol: Integer): Boolean;
    procedure Guardar(const ARuta: string);
    // ILectorHojaCalculo
    function LeerCelda(AFila, ACol: Integer): Variant;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
  end;

// Escritor ligado al control (crea la hoja con NuevaHoja y permite Guardar).
function CrearEscritorDevEx(
  const AControl: TdxSpreadSheet): IEscritorHojaCalculo;
// Escritor sobre una vista de tabla suelta (sin NuevaHoja ni Guardar).
function CrearEscritorDevExTabla(
  const ATabla: TdxSpreadSheetTableView): IEscritorHojaCalculo;
// Lector sobre la primera hoja de un control ya cargado (sin limpiarlo).
function CrearLectorDevEx(
  const AControl: TdxSpreadSheet): ILectorHojaCalculo;

implementation

uses
  inLibMsgComun;

class procedure TEscritorHojaCalculoDevEx.MezclarDx(
  const ATabla: TdxSpreadSheetTableView;
  AFila, ACol, AColCount, AFilaCount: Integer);
var
  R: TRect;
begin
  // TRect(Left, Top, Right, Bottom) con la esquina final inclusive.
  R.Left := ACol;
  R.Top := AFila;
  R.Right := ACol + AColCount - 1;
  R.Bottom := AFila + AFilaCount - 1;
  ATabla.MergedCells.Add(R);
end;

class procedure TEscritorHojaCalculoDevEx.EscribirCeldaDx(
  const ATabla: TdxSpreadSheetTableView; AFila, ACol: Integer;
  const AValor: Variant; ANegrita: Boolean;
  ADxAlineacion: TdxSpreadSheetDataAlignHorz);
begin
  with ATabla.CreateCell(AFila, ACol) do
  begin
    AsVariant := AValor;
    if ANegrita then
      Style.Font.Style := [fsBold]
    else
      Style.Font.Style := [];
    Style.AlignHorz := ADxAlineacion;
    Style.AlignVert := ssavCenter;
  end;
end;

class procedure TEscritorHojaCalculoDevEx.EscribirFormulaDx(
  const ATabla: TdxSpreadSheetTableView; AFila, ACol: Integer;
  const AFormula, AFormato: string);
begin
  with ATabla.CreateCell(AFila, ACol) do
  begin
    // SetText(..., True) es crítico para que interprete la fórmula.
    SetText(AFormula, True);
    Style.AlignHorz := ssahRight;
    if AFormato <> '' then
      Style.DataFormat.FormatCode := AFormato;
  end;
end;

class procedure TEscritorHojaCalculoDevEx.PintarCuadroDx(
  const ATabla: TdxSpreadSheetTableView; AF1, AC1, AF2, AC2: Integer;
  ADxEstilo: TdxSpreadSheetCellBorderStyle);
var
  iFila, iCol: Integer;
begin
  // Techo y suelo del cuadro.
  for iCol := AC1 to AC2 do
  begin
    if ATabla.Cells[AF1, iCol] = nil then
      ATabla.CreateCell(AF1, iCol);
    ATabla.Cells[AF1, iCol].Style.Borders[bTop].Style := ADxEstilo;
    if ATabla.Cells[AF2, iCol] = nil then
      ATabla.CreateCell(AF2, iCol);
    ATabla.Cells[AF2, iCol].Style.Borders[bBottom].Style := ADxEstilo;
  end;
  // Paredes izquierda y derecha.
  for iFila := AF1 to AF2 do
  begin
    if ATabla.Cells[iFila, AC1] = nil then
      ATabla.CreateCell(iFila, AC1);
    ATabla.Cells[iFila, AC1].Style.Borders[bLeft].Style := ADxEstilo;
    if ATabla.Cells[iFila, AC2] = nil then
      ATabla.CreateCell(iFila, AC2);
    ATabla.Cells[iFila, AC2].Style.Borders[bRight].Style := ADxEstilo;
  end;
end;

constructor TEscritorHojaCalculoDevEx.Create(const AControl: TdxSpreadSheet);
begin
  inherited Create;
  FControl := AControl;
  // La hoja se crea al llamar a NuevaHoja (patrón de los exportadores).
  FTabla := nil;
end;

constructor TEscritorHojaCalculoDevEx.CreateTabla(
  const ATabla: TdxSpreadSheetTableView);
begin
  inherited Create;
  FControl := nil;
  FTabla := ATabla;
end;

function TEscritorHojaCalculoDevEx.MapAlineacion(
  AAlineacion: TAlineacionCelda): TdxSpreadSheetDataAlignHorz;
begin
  case AAlineacion of
    acCentro:
      Result := ssahCenter;
    acDerecha:
      Result := ssahRight;
  else
    Result := ssahLeft;
  end;
end;

function TEscritorHojaCalculoDevEx.MapBorde(
  AEstilo: TEstiloBorde): TdxSpreadSheetCellBorderStyle;
begin
  case AEstilo of
    ebFino:
      Result := sscbsThin;
    ebMedio:
      Result := sscbsMedium;
    ebGrueso:
      Result := sscbsThick;
  else
    Result := sscbsNone;
  end;
end;

procedure TEscritorHojaCalculoDevEx.AsegurarTabla;
begin
  if FTabla = nil then
    raise EHojaCalculo.Create(SErrorHojaCalculoNoActiva);
end;

procedure TEscritorHojaCalculoDevEx.NuevaHoja(const ANombre: string);
begin
  if FControl = nil then
    raise EHojaCalculo.Create(SErrorControlHojaCalculoObligatorio);
  FControl.ClearAll;
  FTabla := FControl.AddSheet(ANombre, TdxSpreadSheetTableView)
    as TdxSpreadSheetTableView;
end;

procedure TEscritorHojaCalculoDevEx.IniciarLote;
begin
  AsegurarTabla;
  FTabla.BeginUpdate;
end;

procedure TEscritorHojaCalculoDevEx.FinalizarLote;
begin
  AsegurarTabla;
  FTabla.EndUpdate;
end;

procedure TEscritorHojaCalculoDevEx.Escribir(AFila, ACol: Integer;
  const AValor: Variant; ANegrita: Boolean; AAlineacion: TAlineacionCelda;
  const AFormato: string);
begin
  AsegurarTabla;
  EscribirCeldaDx(FTabla, AFila, ACol, AValor, ANegrita,
    MapAlineacion(AAlineacion));
  if AFormato <> '' then
    FTabla.Cells[AFila, ACol].Style.DataFormat.FormatCode := AFormato;
end;

procedure TEscritorHojaCalculoDevEx.EscribirFormula(AFila, ACol: Integer;
  const AFormula: string; const AFormato: string);
begin
  AsegurarTabla;
  EscribirFormulaDx(FTabla, AFila, ACol, AFormula, AFormato);
end;

procedure TEscritorHojaCalculoDevEx.Combinar(AFila, ACol, ANumFilas,
  ANumCols: Integer);
begin
  AsegurarTabla;
  MezclarDx(FTabla, AFila, ACol, ANumCols, ANumFilas);
end;

procedure TEscritorHojaCalculoDevEx.DibujarCuadro(AF1, AC1, AF2,
  AC2: Integer; AEstilo: TEstiloBorde);
begin
  AsegurarTabla;
  PintarCuadroDx(FTabla, AF1, AC1, AF2, AC2, MapBorde(AEstilo));
end;

procedure TEscritorHojaCalculoDevEx.BordeCelda(AFila, ACol: Integer;
  ALado: TLadoBorde; AEstilo: TEstiloBorde);
var
  oBorde: TcxBorder;
begin
  AsegurarTabla;
  case ALado of
    lbSuperior:
      oBorde := bTop;
    lbInferior:
      oBorde := bBottom;
    lbIzquierdo:
      oBorde := bLeft;
  else
    oBorde := bRight;
  end;
  FTabla.CreateCell(AFila, ACol).Style.Borders[oBorde].Style :=
    MapBorde(AEstilo);
end;

procedure TEscritorHojaCalculoDevEx.FondoCelda(AFila, ACol: Integer;
  AColor: Cardinal);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.Brush.BackgroundColor :=
    TdxAlphaColor(AColor);
end;

procedure TEscritorHojaCalculoDevEx.Negrita(AFila, ACol: Integer;
  AActivar: Boolean);
begin
  AsegurarTabla;
  if AActivar then
    FTabla.CreateCell(AFila, ACol).Style.Font.Style := [fsBold]
  else
    FTabla.CreateCell(AFila, ACol).Style.Font.Style := [];
end;

procedure TEscritorHojaCalculoDevEx.TamanoFuente(AFila, ACol: Integer;
  ATamano: Integer);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.Font.Size := ATamano;
end;

procedure TEscritorHojaCalculoDevEx.AnchoColumna(ACol: Integer;
  AAncho: Integer);
begin
  AsegurarTabla;
  FTabla.Columns[ACol].Size := AAncho;
end;

function TEscritorHojaCalculoDevEx.CeldaExiste(AFila, ACol: Integer): Boolean;
begin
  AsegurarTabla;
  Result := FTabla.Cells[AFila, ACol] <> nil;
end;

procedure TEscritorHojaCalculoDevEx.Guardar(const ARuta: string);
begin
  if FControl = nil then
    raise EHojaCalculo.Create(
      SErrorGuardarHojaCalculoControlObligatorio);
  FControl.SaveToFile(ARuta);
end;

function TEscritorHojaCalculoDevEx.LeerCelda(AFila, ACol: Integer): Variant;
begin
  Result := Null;
  if (FTabla <> nil) and (FTabla.Cells[AFila, ACol] <> nil) then
    Result := FTabla.Cells[AFila, ACol].AsVariant;
end;

function TEscritorHojaCalculoDevEx.UltimaFila: Integer;
begin
  if FTabla = nil then
    Result := -1
  else
    Result := FTabla.Dimensions.Bottom;
end;

function TEscritorHojaCalculoDevEx.UltimaColumna: Integer;
begin
  if FTabla = nil then
    Result := -1
  else
    Result := FTabla.Dimensions.Right;
end;

function CrearEscritorDevEx(
  const AControl: TdxSpreadSheet): IEscritorHojaCalculo;
begin
  Result := TEscritorHojaCalculoDevEx.Create(AControl);
end;

function CrearEscritorDevExTabla(
  const ATabla: TdxSpreadSheetTableView): IEscritorHojaCalculo;
begin
  Result := TEscritorHojaCalculoDevEx.CreateTabla(ATabla);
end;

function CrearLectorDevEx(
  const AControl: TdxSpreadSheet): ILectorHojaCalculo;
var
  oTabla: TdxSpreadSheetTableView;
begin
  oTabla := nil;
  if AControl.SheetCount > 0 then
    oTabla := AControl.Sheets[0] as TdxSpreadSheetTableView;
  Result := TEscritorHojaCalculoDevEx.CreateTabla(oTabla);
end;

end.
