{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAtributosPaleta                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lookup de la paleta de atributos básicos (fza_atributos_basicos).         }
{    Cachea por (ID_VA_ATB, CODIGO_ATB) -> EXTRA_ATB (#HEX) + NOMBRE_ATB.      }
{    Expone helpers para pintar grids cxGrid (cuadrado de color y texto).      }
{******************************************************************************}
unit inLibAtributosPaleta;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  System.Generics.Collections, Vcl.Graphics,
  cxGraphics,
  cxGridTableView;

type
  TInfoBasico = record
    HexColor : string;       // '#RRGGBB' tal y como vino de EXTRA_ATB
    Color    : TColor;       // Convertido a TColor (clNone si no parseable)
    Nombre   : string;       // NOMBRE_ATB
    EsValido : Boolean;      // True si Color es parseable
  end;

// Invalida la cache (llamar al refrescar fza_atributos_basicos).
procedure InvalidarCachePaleta;

// Busca por (ID_VA_ATB, CODIGO_ATB). Devuelve True si existe en la paleta
// Y su EXTRA_ATB es un color valido.
function ObtenerInfoBasico(const AIdVA: string;
                           const ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;

// Convierte '#RRGGBB' o '#RGB' a TColor. Devuelve clNone si no parseable.
function HexToColor(const AHex: string): TColor;

// Pinta una celda cxGrid con un cuadrado de color delante del texto.
// Usar dentro de OnCustomDrawCell:
//   if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, AInfo) then
//     ADone := True;
// El cuadrado se dibuja a la izquierda y el texto desplazado a la derecha.
function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico): Boolean;

// Pinta una celda cxGrid coloreando el texto con el color de la paleta.
// Usar dentro de OnCustomDrawCell:
//   if PintarCeldaConTextoColor(ACanvas, AViewInfo, AInfo) then
//     ADone := True;
function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;

implementation

uses
  Uni, inLibGlobalVar;

var
  GCache        : TDictionary<string, TInfoBasico>;
  GCacheCargado : Boolean;

function ClaveCache(const AIdVA, ACodigoATB: string): string;
begin
  Result := UpperCase(Trim(AIdVA)) + '|' + UpperCase(Trim(ACodigoATB));
end;

function HexToColor(const AHex: string): TColor;
var
  s : string;
  r, g, b : Integer;
begin
  Result := clNone;
  s := Trim(AHex);
  if (Length(s) = 7) and (s[1] = '#') then
  begin
    if not TryStrToInt('$' + Copy(s, 2, 2), r) then Exit;
    if not TryStrToInt('$' + Copy(s, 4, 2), g) then Exit;
    if not TryStrToInt('$' + Copy(s, 6, 2), b) then Exit;
    Result := RGB(r, g, b);
  end
  else if (Length(s) = 4) and (s[1] = '#') then
  begin
    if not TryStrToInt('$' + s[2] + s[2], r) then Exit;
    if not TryStrToInt('$' + s[3] + s[3], g) then Exit;
    if not TryStrToInt('$' + s[4] + s[4], b) then Exit;
    Result := RGB(r, g, b);
  end;
end;

procedure CargarCache;
var
  q    : TUniQuery;
  Info : TInfoBasico;
begin
  GCache.Clear;
  GCacheCargado := False;
  if oConn = nil then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, EXTRA_ATB '   +
      '  FROM fza_atributos_basicos '                          +
      ' WHERE ESACTIVO_ATB = ''S'' '                           +
      '   AND EXTRA_ATB IS NOT NULL '                          +
      '   AND EXTRA_ATB <> '''' ';
    q.Open;
    while not q.Eof do
    begin
      Info := Default(TInfoBasico);
      Info.HexColor := q.FieldByName('EXTRA_ATB').AsString;
      Info.Color    := HexToColor(Info.HexColor);
      Info.Nombre   := q.FieldByName('NOMBRE_ATB').AsString;
      Info.EsValido := Info.Color <> clNone;
      if Info.EsValido then
        GCache.AddOrSetValue(
          ClaveCache(q.FieldByName('ID_VA_ATB').AsString,
                     q.FieldByName('CODIGO_ATB').AsString),
          Info);
      q.Next;
    end;
    GCacheCargado := True;
  finally
    q.Free;
  end;
end;

procedure InvalidarCachePaleta;
begin
  if GCache <> nil then
    GCache.Clear;
  GCacheCargado := False;
end;

function ObtenerInfoBasico(const AIdVA, ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if (Trim(AIdVA) = '') or (Trim(ACodigoATB) = '') then Exit;
  if not GCacheCargado then
    CargarCache;
  if not GCacheCargado then Exit;
  if GCache.TryGetValue(ClaveCache(AIdVA, ACodigoATB), AInfo) then
    Result := AInfo.EsValido;
end;

function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico): Boolean;
const
  LADO_CUADRADO = 10;
  MARGEN_IZQ    = 4;
  HUECO_TEXTO   = 4;
var
  Bounds, Cuadrado, TxtRect : TRect;
  Texto : string;
  Alto, TopY : Integer;
begin
  Result := False;
  if (ACanvas = nil) or (AViewInfo = nil) or not AInfo.EsValido then Exit;

  Bounds := AViewInfo.Bounds;
  Texto  := AViewInfo.Text;

  // Fondo de la celda con el color "natural" (selección/foco respetado por Params)
  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(Bounds);

  // Cuadrado de color centrado verticalmente
  Alto := Bounds.Bottom - Bounds.Top;
  if Alto > LADO_CUADRADO then
    TopY := Bounds.Top + (Alto - LADO_CUADRADO) div 2
  else
    TopY := Bounds.Top;
  Cuadrado := Rect(Bounds.Left + MARGEN_IZQ,
                   TopY,
                   Bounds.Left + MARGEN_IZQ + LADO_CUADRADO,
                   TopY + LADO_CUADRADO);
  ACanvas.Brush.Color := AInfo.Color;
  ACanvas.FillRect(Cuadrado);
  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := 1;
  ACanvas.FrameRect(Cuadrado);

  // Texto desplazado a la derecha del cuadrado
  TxtRect := Bounds;
  TxtRect.Left := Cuadrado.Right + HUECO_TEXTO;
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  ACanvas.Font.Color := AViewInfo.Params.TextColor;
  ACanvas.Brush.Style := bsClear;
  ACanvas.DrawText(Texto, TxtRect,
                   DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
  ACanvas.Brush.Style := bsSolid;

  Result := True;
end;

function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;
var
  Bounds, TxtRect : TRect;
  Texto : string;
begin
  Result := False;
  if (ACanvas = nil) or (AViewInfo = nil) or not AInfo.EsValido then Exit;

  Bounds := AViewInfo.Bounds;
  Texto  := AViewInfo.Text;

  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(Bounds);

  TxtRect := Bounds;
  Inc(TxtRect.Left, 4);
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  ACanvas.Font.Color := AInfo.Color;
  ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  ACanvas.Brush.Style := bsClear;
  ACanvas.DrawText(Texto, TxtRect,
                   DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
  ACanvas.Brush.Style := bsSolid;

  Result := True;
end;

initialization
  GCache        := TDictionary<string, TInfoBasico>.Create;
  GCacheCargado := False;

finalization
  GCache.Free;

end.
