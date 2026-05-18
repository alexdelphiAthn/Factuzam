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
{    Cachea por (ID_VA_ATB, CODIGO_ATB) -> HEX_ATB + NOMBRE_ATB.               }
{    Expone helpers para pintar grids cxGrid (cuadrado / texto).               }
{******************************************************************************}
unit inLibAtributosPaleta;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections, Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  cxGraphics,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, System.UITypes,
  cxImageComboBox;

type
  TInfoBasico = record
    HexColor : string;       // '#RRGGBB' tal y como vino de EXTRA_ATB
    Color    : TColor;       // Convertido a TColor (clNone si no parseable)
    Nombre   : string;       // NOMBRE_ATB
    EsValido : Boolean;      // True si Color es parseable
  end;

const
  // Pixeles horizontales que reserva PintarCeldaConCuadradoColor delante
  // del texto para el swatch (margen + cuadrado + hueco). Se expone para
  // que los consumidores puedan ensanchar las columnas tras un ApplyBestFit
  // que solo mide el texto.
  ANCHO_SWATCH_PX = 20; // MARGEN_IZQ(4) + LADO_CUADRADO(12) + HUECO_TEXTO(4)

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
// Si AViewInfo.Text esta vacio (caso TcxImageComboBox sin match en Items),
// se cae al valor crudo del campo via GridRecord.
function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico): Boolean; overload;
function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico;
                                     const ATexto: string): Boolean; overload;

// Pinta una celda cxGrid coloreando el texto con el color de la paleta.
// Usar dentro de OnCustomDrawCell:
//   if PintarCeldaConTextoColor(ACanvas, AViewInfo, AInfo) then
//     ADone := True;
function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;

// Rellena ADict con NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO para todos los
// atributos del articulo padre. Pensado para grids de stock que no conocen
// a priori el ID_VA de cada columna.
procedure CargarMapaAtributosArticulo(const ACodArt: string;
                                      ADict: TDictionary<string, string>);

// Variante global del anterior: NOMBRE_VA (uppercase) -> ID_ATB_VA para todos
// los atributos definidos en fza_variaciones_atributos. Pensada para grids que
// muestran lineas de articulos distintos (inventario, caja, ...) y necesitan
// un solo diccionario en vez de uno por articulo.
procedure CargarMapaAtributosGlobal(ADict: TDictionary<string, string>);

// Diccionario global cacheado en la propia libreria (carga perezosa). NO
// liberar el resultado — pertenece a la unidad. Pensado para que un form
// que quiera pintar cuadraditos solo tenga que llamar a
// `PintarCeldaSwatchSiAplica` desde su OnCustomDrawCell, sin gestionar
// estado ni inicializaciones.
function ObtenerMapaAtributosGlobal: TDictionary<string, string>;

// Invalida el diccionario global (llamar tras alta/baja en
// fza_variaciones_atributos o tras refrescar la paleta basica).
procedure InvalidarMapaAtributosGlobal;

// Helper "todo en uno" para usar desde OnCustomDrawCell. Busca un match en
// la paleta (usando ADict, o el diccionario global si ADict es nil) y, si
// procede, pinta la celda con cuadradito + texto. Devuelve True si pinto
// (el llamante debe poner ADone := True).
//
// Uso tipico (diccionario global):
//   procedure TfrmX.tvFooCustomDrawCell(Sender; ACanvas; AViewInfo; var ADone);
//   begin
//     if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
//       ADone := True;
//   end;
function PintarCeldaSwatchSiAplica(ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;

// Busca un basico para `ATexto` probando cada ID_VA presente en `ADict`. Si
// el texto contiene '/', tambien prueba con el ultimo segmento tras la barra.
// Devuelve True en el primer match valido.
function BuscarInfoBasicoEnArticulo(const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;

// Recorre los valores de AColumn buscando textos que casen con la paleta
// basica del articulo (via `ADict`). Si encuentra al menos uno, ensancha la
// columna en ANCHO_SWATCH_PX para que el cuadradito de color no recorte el
// texto tras un ApplyBestFit (que solo mide caracteres). Devuelve True si
// se aplico el ensanche.
function AjustarAnchoColumnaParaSwatch(AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;

// Limpia AImages y la rellena con un swatch (cuadrado) por cada AV de
// `AAvs` (CODIGO_ATB esperado). El swatch se genera SOLO si existe en la
// paleta basica para (AIdVa, AV). El dict AAvToImageIndex queda con
// uppercase(AV) -> ImageIndex; los AV sin color en paleta no aparecen.
procedure RellenarImageListPaleta(AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string, Integer>);

// Configura un TcxImageComboBoxProperties para mostrar cada AV con su
// cuadradito (si esta en la paleta). Hace dos cosas:
//   1) Rellena AImages con un swatch por AV con color en paleta.
//   2) Vuelca los Items con Description=Value=AV e ImageIndex=swatch
//      (-1 si el AV no esta en la paleta — se muestra solo texto).
// El llamante solo tiene que tener un TImageList preparado y los AVs.
procedure ConfigurarImageComboConPaleta(AProps : TcxImageComboBoxProperties;
                                        AImages: TCustomImageList;
                                        const AIdVa: string;
                                        const AAvs : array of string);

implementation

uses
  Uni, inLibGlobalVar;

var
  GCache        : TDictionary<string, TInfoBasico>;
  GCacheCargado : Boolean;
  // Mapa NOMBRE_VA -> ID_ATB_VA global (todas las variaciones del sistema),
  // cacheado para los grids que no tienen un articulo padre concreto
  // (inventario, caja, ...). Carga perezosa via ObtenerMapaAtributosGlobal.
  GMapaGlobal        : TDictionary<string, string>;
  GMapaGlobalCargado : Boolean;

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
      'SELECT ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, HEX_ATB '     +
      '  FROM fza_atributos_basicos '                          +
      ' WHERE ESACTIVO_ATB = ''S'' '                           +
      '   AND HEX_ATB IS NOT NULL '                            +
      '   AND HEX_ATB <> '''' ';
    q.Open;
    while not q.Eof do
    begin
      Info := Default(TInfoBasico);
      Info.HexColor := q.FieldByName('HEX_ATB').AsString;
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
    FreeAndNil(q);
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
begin
  Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, AInfo, '');
end;

function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico;
                                     const ATexto: string): Boolean;
const
  LADO_CUADRADO = 12;
  MARGEN_IZQ    = 4;
  HUECO_TEXTO   = 4;
  // OJO: si tocas alguno de estos tres, actualiza ANCHO_SWATCH_PX en la
  // interface (debe ser MARGEN_IZQ + LADO_CUADRADO + HUECO_TEXTO).
var
  Bounds, Cuadrado, TxtRect : TRect;
  Texto : string;
  Alto, TopY : Integer;
begin
  Result := False;
  if (ACanvas = nil) or (AViewInfo = nil) or not AInfo.EsValido then Exit;

  Bounds := AViewInfo.Bounds;
  if ATexto <> '' then
    Texto := ATexto
  else
    Texto := AViewInfo.Text;
  if (Texto = '') and (AViewInfo.GridRecord <> nil) then
    Texto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);

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
  // Relleno con el color de la paleta
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AInfo.Color;
  ACanvas.FillRect(Cuadrado);
  // Borde fino negro. Usamos Rectangle con bsClear: FrameRect dibuja el
  // contorno con el brush (no con el pen), asi que para colores claros
  // como BLANCO el borde queda invisible.
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color   := clBlack;
  ACanvas.Pen.Width   := 1;
  ACanvas.Rectangle(Cuadrado);
  ACanvas.Brush.Style := bsSolid;

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

procedure CargarMapaAtributosArticulo(const ACodArt: string;
                                      ADict: TDictionary<string, string>);
var
  q : TUniQuery;
begin
  if ADict = nil then Exit;
  ADict.Clear;
  if (Trim(ACodArt) = '') or (oConn = nil) then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT DISTINCT ID_ATRIBUTO, NOMBRE_ATRIBUTO '          +
      '  FROM vi_atributos_nombres '                           +
      ' WHERE CODIGO_ART_PADRE_ARTVIN = :ART ';
    q.ParamByName('ART').AsString := ACodArt;
    q.Open;
    while not q.Eof do
    begin
      ADict.AddOrSetValue(
        UpperCase(Trim(q.FieldByName('NOMBRE_ATRIBUTO').AsString)),
        q.FieldByName('ID_ATRIBUTO').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure CargarMapaAtributosGlobal(ADict: TDictionary<string, string>);
var
  q : TUniQuery;
  Nombre : string;
begin
  if ADict = nil then Exit;
  ADict.Clear;
  if oConn = nil then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT ID_ATB_VA, COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE_VA ' +
      '  FROM fza_variaciones_atributos';
    q.Open;
    while not q.Eof do
    begin
      Nombre := UpperCase(Trim(q.FieldByName('NOMBRE_VA').AsString));
      if Nombre <> '' then
        ADict.AddOrSetValue(Nombre, q.FieldByName('ID_ATB_VA').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function ObtenerMapaAtributosGlobal: TDictionary<string, string>;
begin
  if GMapaGlobal = nil then
    GMapaGlobal := TDictionary<string, string>.Create;
  if not GMapaGlobalCargado then
  begin
    CargarMapaAtributosGlobal(GMapaGlobal);
    GMapaGlobalCargado := True;
  end;
  Result := GMapaGlobal;
end;

procedure InvalidarMapaAtributosGlobal;
begin
  if GMapaGlobal <> nil then
    GMapaGlobal.Clear;
  GMapaGlobalCargado := False;
end;

function PintarCeldaSwatchSiAplica(ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;
var
  Dict : TDictionary<string, string>;
  Info : TInfoBasico;
begin
  Result := False;
  if (ACanvas = nil) or (AViewInfo = nil) then Exit;
  if ADict <> nil then
    Dict := ADict
  else
    Dict := ObtenerMapaAtributosGlobal;
  if (Dict = nil) or (Dict.Count = 0) then Exit;
  if not BuscarInfoBasicoEnArticulo(AViewInfo.Text, Dict, Info) then Exit;
  Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info);
end;

function BuscarInfoBasicoEnArticulo(const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;
var
  Texto, Sufijo, IdVa : string;
  PosBarra : Integer;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if ADict = nil then Exit;
  Texto := Trim(ATexto);
  if Texto = '' then Exit;
  // 1) Probamos con el texto entero
  for IdVa in ADict.Values do
    if ObtenerInfoBasico(IdVa, Texto, AInfo) then
      Exit(True);
  // 2) Si hay '/' probamos con el ultimo segmento (caja: "CODART/COLOR")
  PosBarra := LastDelimiter('/', Texto);
  if PosBarra > 0 then
  begin
    Sufijo := Trim(Copy(Texto, PosBarra + 1, MaxInt));
    if (Sufijo <> '') and (Sufijo <> Texto) then
      for IdVa in ADict.Values do
        if ObtenerInfoBasico(IdVa, Sufijo, AInfo) then
          Exit(True);
  end;
end;

function AjustarAnchoColumnaParaSwatch(AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;
var
  Tabla : TcxCustomGridTableView;
  i, n  : Integer;
  v     : Variant;
  Info  : TInfoBasico;
begin
  Result := False;
  if (AColumn = nil) or (ADict = nil) or (ADict.Count = 0) then Exit;
  Tabla := AColumn.GridView as TcxCustomGridTableView;
  if (Tabla = nil) or (Tabla.DataController = nil) then Exit;
  n := Tabla.DataController.RecordCount;
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    v := Tabla.DataController.Values[i, AColumn.Index];
    if VarIsNull(v) or VarIsClear(v) then Continue;
    if BuscarInfoBasicoEnArticulo(VarToStr(v), ADict, Info) then
    begin
      AColumn.Width := AColumn.Width + ANCHO_SWATCH_PX;
      Exit(True);
    end;
  end;
end;

procedure RellenarImageListPaleta(AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string, Integer>);
const
  LADO = 14;
var
  i, Idx : Integer;
  Av, Clave : string;
  Info : TInfoBasico;
  Bmp : TBitmap;
begin
  if AImages = nil then Exit;
  AImages.Clear;
  if AAvToImageIndex <> nil then
    AAvToImageIndex.Clear;
  if (Trim(AIdVa) = '') or (Length(AAvs) = 0) then Exit;

  // El tamano de los iconos del ImageList tiene que coincidir con el lado del
  // swatch para que DevExpress los pinte sin escalar.
  AImages.Width  := LADO;
  AImages.Height := LADO;

  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(LADO, LADO);
    for i := 0 to High(AAvs) do
    begin
      Av := AAvs[i];
      if not ObtenerInfoBasico(AIdVa, Av, Info) then Continue;

      Bmp.Canvas.Brush.Style := bsSolid;
      Bmp.Canvas.Brush.Color := Info.Color;
      Bmp.Canvas.FillRect(Rect(0, 0, LADO, LADO));
      Bmp.Canvas.Brush.Style := bsClear;
      Bmp.Canvas.Pen.Color   := clBlack;
      Bmp.Canvas.Pen.Width   := 1;
      Bmp.Canvas.Rectangle(0, 0, LADO, LADO);

      Idx := AImages.Add(Bmp, nil);
      if (Idx >= 0) and (AAvToImageIndex <> nil) then
      begin
        Clave := UpperCase(Trim(Av));
        AAvToImageIndex.AddOrSetValue(Clave, Idx);
      end;
    end;
  finally
    FreeAndNil(Bmp);
  end;
end;

procedure ConfigurarImageComboConPaleta(AProps : TcxImageComboBoxProperties;
                                        AImages: TCustomImageList;
                                        const AIdVa: string;
                                        const AAvs : array of string);
var
  AvToIdx : TDictionary<string, Integer>;
  i, Idx  : Integer;
  Av, Clave : string;
  Item    : TcxImageComboBoxItem;
begin
  if AProps = nil then Exit;
  AProps.Items.BeginUpdate;
  try
    AProps.Items.Clear;
    AProps.Images := AImages;
    AvToIdx := TDictionary<string, Integer>.Create;
    try
      RellenarImageListPaleta(AImages, AIdVa, AAvs, AvToIdx);
      for i := 0 to High(AAvs) do
      begin
        Av := AAvs[i];
        Item := AProps.Items.Add;
        Item.Description := Av;
        Item.Value       := Av;
        Clave := UpperCase(Trim(Av));
        if AvToIdx.TryGetValue(Clave, Idx) then
          Item.ImageIndex := Idx
        else
          Item.ImageIndex := -1;
      end;
    finally
      FreeAndNil(AvToIdx);
    end;
  finally
    AProps.Items.EndUpdate;
  end;
end;

initialization
  GCache             := TDictionary<string, TInfoBasico>.Create;
  GCacheCargado      := False;
  GMapaGlobal        := nil;
  GMapaGlobalCargado := False;

finalization
  FreeAndNil(GCache);
  FreeAndNil(GMapaGlobal);

end.
