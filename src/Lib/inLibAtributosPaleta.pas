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
  System.Types, System.Generics.Collections, Data.DB,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  Uni,
  cxGraphics,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, System.UITypes,
  inLibAtributosPaletaIntf;

type
  TInfoBasico = inLibAtributosPaletaIntf.TInfoBasico;

const
  // Pixeles horizontales que reserva PintarCeldaConCuadradoColor delante
  // del texto para el swatch (margen + cuadrado + hueco). Se expone para
  // que los consumidores puedan ensanchar las columnas tras un ApplyBestFit
  // que solo mide el texto. Desglose: 24 geometrico (MARGEN_IZQ 4 +
  // LADO_CUADRADO 16 + HUECO_TEXTO 4) + holgura para que el texto no salga
  // pegado al cuadradito ni recortado (p.ej. "MARRON" en la columna Color).
  ANCHO_SWATCH_PX = 50;

// Invalida la cache (llamar al refrescar fza_atributos_basicos).
procedure InvalidarCachePaleta;
procedure ConfigurarLecturasAtributosPaleta(
  const ALecturas: ILecturasAtributosPaleta);
procedure ConfigurarSelectorAtributoPaleta(
  const ASelector: ISelectorAtributoPaleta);

// Busca por (ID_VA_ATB, CODIGO_ATB). Devuelve True si existe en la paleta
// Y su EXTRA_ATB es un color valido.
function ObtenerInfoBasico(AConexion: TUniConnection;
                           const AIdVA: string;
                           const ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;

// Resuelve el basico asignado a un valor dentro de un articulo concreto.
// Es necesario para codigos de proveedor ambiguos como PALO.
function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
                                   const ACodArt, AIdVA, AValor: string;
                                   out AInfo: TInfoBasico): Boolean;

// Devuelve los codigos basicos de una variacion usados por los SKU activos
// de un articulo, ordenados como la paleta.
function ObtenerBasicosArticulo(AConexion: TUniConnection;
                                const ACodArt, AIdVA: string): TArray<string>;

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
                                     const AInfo: TInfoBasico): Boolean;
                                     overload;
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
procedure CargarMapaAtributosArticulo(AConexion: TUniConnection;
                                      const ACodArt: string;
                                      ADict: TDictionary<string, string>);

// Variante global del anterior: NOMBRE_VA (uppercase) -> ID_ATB_VA para todos
// los atributos definidos en fza_variaciones_atributos. Pensada para grids que
// muestran lineas de articulos distintos (inventario, caja, ...) y necesitan
// un solo diccionario en vez de uno por articulo.
procedure CargarMapaAtributosGlobal(AConexion: TUniConnection;
  ADict: TDictionary<string, string>);

// Diccionario global cacheado en la propia libreria (carga perezosa). NO
// liberar el resultado — pertenece a la unidad. Pensado para que un form
// que quiera pintar cuadraditos solo tenga que llamar a
// `PintarCeldaSwatchSiAplica` desde su OnCustomDrawCell, sin gestionar
// estado ni inicializaciones.
function ObtenerMapaAtributosGlobal(
  AConexion: TUniConnection): TDictionary<string, string>;

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
function PintarCeldaSwatchSiAplica(AConexion: TUniConnection;
                                   ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;

// Variante contextual para documentos de articulos. Resuelve primero la
// asignacion especifica del articulo (color proveedor -> color basico) y usa
// la paleta global solo como fallback. ATexto puede ser un valor o un SKU.
function PintarCeldaSwatchArticuloSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>): Boolean;

// Busca un basico para `ATexto` probando cada ID_VA presente en `ADict`. Si
// el texto contiene '/', tambien prueba con el ultimo segmento tras la barra.
// Devuelve True en el primer match valido.
function BuscarInfoBasicoEnArticulo(AConexion: TUniConnection;
                                    const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;

// Igual que BuscarInfoBasicoEnArticulo, dando prioridad a las asignaciones
// particulares del articulo antes de consultar el basico global del AV.
function BuscarInfoBasicoEnArticuloContextual(
  AConexion: TUniConnection;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>;
  out AInfo: TInfoBasico): Boolean;

// Recorre los valores de AColumn buscando textos que casen con la paleta
// basica del articulo (via `ADict`). Si encuentra al menos uno, ensancha la
// columna en ANCHO_SWATCH_PX para que el cuadradito de color no recorte el
// texto tras un ApplyBestFit (que solo mide caracteres). Devuelve True si
// se aplico el ensanche.
function AjustarAnchoColumnaParaSwatch(AConexion: TUniConnection;
                                       AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;

// Limpia AImages y la rellena con un swatch (cuadrado) por cada AV de
// `AAvs` (CODIGO_ATB esperado). El swatch se genera SOLO si existe en la
// paleta basica para (AIdVa, AV). El dict AAvToImageIndex queda con
// uppercase(AV) -> ImageIndex; los AV sin color en paleta no aparecen.
procedure RellenarImageListPaleta(AConexion: TUniConnection;
                                  AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string,
                                  Integer>);

// Pinta un cuadradito de color en ABmp (lo redimensiona a ALado x ALado).
// Devuelve True si pinto algo (AInfo valido); False si no, y deja ABmp sin
// tocar. Util para glyphs de botones / iconos pequenyos.
function PintarSwatchEnBitmap(ABmp: TBitmap; const AInfo: TInfoBasico;
                              ALado: Integer = 14): Boolean;

// Muestra un dropdown sin marco con un TListBox owner-drawn que pinta el
// cuadradito de paleta basica al lado de cada AV. Pensado para imitar un
// combo desde una celda de cxGrid: pasa AScreenLeft/AScreenTop = pos en
// pantalla justo debajo del editor, y AWidthHint = ancho del editor (se
// expande si los AVs no caben). Un click selecciona y cierra; Esc o click
// fuera cancelan. Si AScreenLeft/Top son negativos, sale centrado.
function SeleccionarAvConPaleta(AConexion: TUniConnection;
                                const AIdVa: string;
                                const AAvs: array of string;
                                const AValorActual: string;
                                out AValor: string;
                                AScreenLeft: Integer = -1;
                                AScreenTop: Integer = -1;
                                AWidthHint: Integer = 120;
                                const ACodArt: string = ''): Boolean;

implementation

var
  GCache        : TDictionary<string, TInfoBasico>;
  GCacheArticulo: TDictionary<string, TInfoBasico>;
  GCacheCargado : Boolean;
  // Mapa NOMBRE_VA -> ID_ATB_VA global (todas las variaciones del sistema),
  // cacheado para los grids que no tienen un articulo padre concreto
  // (inventario, caja, ...). Carga perezosa via ObtenerMapaAtributosGlobal.
  GMapaGlobal        : TDictionary<string, string>;
  GMapaGlobalCargado : Boolean;
  GLecturasPersistencia: ILecturasAtributosPaleta;
  GSelectorPresentacion: ISelectorAtributoPaleta;

procedure ConfigurarLecturasAtributosPaleta(
  const ALecturas: ILecturasAtributosPaleta);
begin
  GLecturasPersistencia := ALecturas;
  InvalidarCachePaleta;
  InvalidarMapaAtributosGlobal;
end;

procedure ConfigurarSelectorAtributoPaleta(
  const ASelector: ISelectorAtributoPaleta);
begin
  GSelectorPresentacion := ASelector;
end;

function ClaveCache(const AIdVA, ACodigoATB: string): string;
begin
  Result := UpperCase(Trim(AIdVA)) + '|' + UpperCase(Trim(ACodigoATB));
end;

function ClaveCacheArticulo(const ACodArt, AIdVA, AValor: string): string;
begin
  Result := UpperCase(Trim(ACodArt)) + '|' + UpperCase(Trim(AIdVA)) + '|' +
    UpperCase(Trim(AValor));
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
    if TryStrToInt('$' + Copy(s, 2, 2), r) and
       TryStrToInt('$' + Copy(s, 4, 2), g) and
       TryStrToInt('$' + Copy(s, 6, 2), b) then
      Result := RGB(r, g, b);
  end
  else if (Length(s) = 4) and (s[1] = '#') then
  begin
    if TryStrToInt('$' + s[2] + s[2], r) and
       TryStrToInt('$' + s[3] + s[3], g) and
       TryStrToInt('$' + s[4] + s[4], b) then
      Result := RGB(r, g, b);
  end;
end;

procedure CargarCache(AConexion: TUniConnection;
  const ALecturas: ILecturasAtributosPaleta);
var
  Entrada: TEntradaCacheBasico;
  Entradas: TArray<TEntradaCacheBasico>;
begin
  GCache.Clear;
  GCacheCargado := False;
  if (AConexion <> nil) and (ALecturas <> nil) then
  begin
    Entradas := ALecturas.ListarEntradasCache(AConexion);
    for Entrada in Entradas do
    begin
      if Entrada.Info.EsValido then
      begin
        GCache.AddOrSetValue(
          ClaveCache(Entrada.IdVariacion, Entrada.Codigo),
          Entrada.Info);
        if Trim(Entrada.Nombre) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Nombre),
            Entrada.Info);
        if Trim(Entrada.Valor) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Valor),
            Entrada.Info);
        if Trim(Entrada.Descripcion) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Descripcion),
            Entrada.Info);
      end;
    end;
    GCacheCargado := True;
  end;
end;

procedure InvalidarCachePaleta;
begin
  if GCache <> nil then
    GCache.Clear;
  if GCacheArticulo <> nil then
    GCacheArticulo.Clear;
  GCacheCargado := False;
end;

function ObtenerBasicosArticulo(AConexion: TUniConnection;
  const ACodArt, AIdVA: string): TArray<string>;
begin
  Result := nil;
  if (GLecturasPersistencia <> nil) and (Trim(ACodArt) <> '') then
    Result := GLecturasPersistencia.ObtenerBasicosArticulo(
      AConexion,
      ACodArt,
      AIdVA);
end;

function ObtenerInfoBasico(AConexion: TUniConnection;
                           const AIdVA, ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if (Trim(AIdVA) <> '') and (Trim(ACodigoATB) <> '') then
  begin
    if not GCacheCargado then
      CargarCache(AConexion, GLecturasPersistencia);
    if GCacheCargado and
       GCache.TryGetValue(ClaveCache(AIdVA, ACodigoATB), AInfo) then
      Result := AInfo.EsValido;
  end;
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
  LADO_CUADRADO = 16;
  MARGEN_IZQ    = 4;
  HUECO_TEXTO   = 4;
  // OJO: si tocas alguno de estos tres, revisa ANCHO_SWATCH_PX en la
  // interface (debe ser >= MARGEN_IZQ + LADO_CUADRADO + HUECO_TEXTO, mas la
  // holgura que se quiera dar al texto a la derecha del cuadradito).
var
  Bounds, Cuadrado, TxtRect : TRect;
  Texto : string;
  Alto, TopY : Integer;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) and AInfo.EsValido then
  begin
  Bounds := AViewInfo.Bounds;
  if ATexto <> '' then
    Texto := ATexto
  else
    Texto := AViewInfo.Text;
  if (Texto = '') and (AViewInfo.GridRecord <> nil) then
    Texto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);

  // Fondo de la celda con el color natural (selección/foco respetado por
  // Params)
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
end;

function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;
var
  Bounds, TxtRect : TRect;
  Texto : string;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) and AInfo.EsValido then
  begin
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
end;

procedure CargarMapaAtributosArticulo(AConexion: TUniConnection;
                                      const ACodArt: string;
                                      ADict: TDictionary<string, string>);
begin
  if GLecturasPersistencia <> nil then
    GLecturasPersistencia.CargarMapaArticulo(AConexion, ACodArt, ADict);
end;

procedure CargarMapaAtributosGlobal(AConexion: TUniConnection;
                                    ADict: TDictionary<string, string>);
begin
  if GLecturasPersistencia <> nil then
    GLecturasPersistencia.CargarMapaGlobal(AConexion, ADict);
end;

function ObtenerMapaAtributosGlobal(
  AConexion: TUniConnection): TDictionary<string, string>;
begin
  if GMapaGlobal = nil then
    GMapaGlobal := TDictionary<string, string>.Create;
  if not GMapaGlobalCargado then
  begin
    CargarMapaAtributosGlobal(AConexion, GMapaGlobal);
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

function PintarCeldaSwatchSiAplica(AConexion: TUniConnection;
                                   ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;
var
  Dict   : TDictionary<string, string>;
  Info   : TInfoBasico;
  sTexto : string;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) then
  begin
    sTexto := AViewInfo.Text;
    if (sTexto = '') and
       (AViewInfo.GridRecord <> nil) and
       (AViewInfo.Item <> nil) then
      sTexto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);
    if ADict <> nil then
      Dict := ADict
    else
      Dict := ObtenerMapaAtributosGlobal(AConexion);
    if (Dict <> nil) and (Dict.Count > 0) and
       BuscarInfoBasicoEnArticulo(AConexion, sTexto, Dict, Info) then
      Result := PintarCeldaConCuadradoColor(
        ACanvas, AViewInfo, Info, sTexto);
  end;
end;

function PintarCeldaSwatchArticuloSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>): Boolean;
var
  Dict: TDictionary<string, string>;
  Info: TInfoBasico;
  sTexto: string;
begin
  Result := False;
  sTexto := ATexto;
  if (sTexto = '') and (AViewInfo <> nil) then
    sTexto := AViewInfo.Text;
  if ADict <> nil then
    Dict := ADict
  else
    Dict := ObtenerMapaAtributosGlobal(AConexion);
  if (ACanvas <> nil) and (AViewInfo <> nil) and
     (Dict <> nil) and (Dict.Count > 0) and
     BuscarInfoBasicoEnArticuloContextual(
       AConexion, ACodArt, sTexto, Dict, Info) then
    Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, sTexto);
end;

function BuscarInfoBasicoEnArticulo(AConexion: TUniConnection;
                                    const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;
var
  Texto, IdVa, Segmento: string;
  Segmentos: TArray<string>;
  i: Integer;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if ADict <> nil then
  begin
    Texto := Trim(ATexto);
    if Texto <> '' then
    begin
      for IdVa in ADict.Values do
      begin
        if not Result then
          Result := ObtenerInfoBasico(AConexion, IdVa, Texto, AInfo);
      end;
      if not Result and (Pos('/', Texto) > 0) then
      begin
        Segmentos := Texto.Split(['/']);
        for i := High(Segmentos) downto 0 do
        begin
          if not Result then
          begin
            Segmento := Trim(Segmentos[i]);
            if Segmento <> '' then
            begin
              for IdVa in ADict.Values do
              begin
                if not Result then
                  Result := ObtenerInfoBasico(
                    AConexion, IdVa, Segmento, AInfo);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function AjustarAnchoColumnaParaSwatch(AConexion: TUniConnection;
                                       AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;
var
  Tabla : TcxCustomGridTableView;
  i, n  : Integer;
  v     : Variant;
  Info  : TInfoBasico;
begin
  Result := False;
  if (AColumn <> nil) and (ADict <> nil) and (ADict.Count > 0) then
  begin
    Tabla := AColumn.GridView as TcxCustomGridTableView;
    if (Tabla <> nil) and (Tabla.DataController <> nil) then
    begin
      n := Tabla.DataController.RecordCount;
      if n > 0 then
      begin
        for i := 0 to n - 1 do
        begin
          if not Result then
          begin
            v := Tabla.DataController.Values[i, AColumn.Index];
            if not VarIsNull(v) and not VarIsClear(v) and
               BuscarInfoBasicoEnArticulo(
                 AConexion, VarToStr(v), ADict, Info) then
            begin
              AColumn.Width := AColumn.Width + ANCHO_SWATCH_PX;
              Result := True;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure RellenarImageListPaleta(AConexion: TUniConnection;
                                  AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string,
                                  Integer>);
const
  LADO = 14;
var
  i, Idx : Integer;
  Av, Clave : string;
  Info : TInfoBasico;
  Bmp : TBitmap;
begin
  if AImages <> nil then
  begin
    AImages.Clear;
    if AAvToImageIndex <> nil then
      AAvToImageIndex.Clear;
    if (Trim(AIdVa) <> '') and (Length(AAvs) > 0) then
    begin
      AImages.Width := LADO;
      AImages.Height := LADO;
      Bmp := TBitmap.Create;
      try
        Bmp.PixelFormat := pf24bit;
        Bmp.SetSize(LADO, LADO);
        for i := 0 to High(AAvs) do
        begin
          Av := AAvs[i];
          if ObtenerInfoBasico(AConexion, AIdVa, Av, Info) then
          begin
            Bmp.Canvas.Brush.Style := bsSolid;
            Bmp.Canvas.Brush.Color := Info.Color;
            Bmp.Canvas.FillRect(Rect(0, 0, LADO, LADO));
            Bmp.Canvas.Brush.Style := bsClear;
            Bmp.Canvas.Pen.Color := clBlack;
            Bmp.Canvas.Pen.Width := 1;
            Bmp.Canvas.Rectangle(0, 0, LADO, LADO);
            Idx := AImages.Add(Bmp, nil);
            if (Idx >= 0) and (AAvToImageIndex <> nil) then
            begin
              Clave := UpperCase(Trim(Av));
              AAvToImageIndex.AddOrSetValue(Clave, Idx);
            end;
          end;
        end;
      finally
        FreeAndNil(Bmp);
      end;
    end;
  end;
end;

function PintarSwatchEnBitmap(ABmp: TBitmap; const AInfo: TInfoBasico;
                              ALado: Integer): Boolean;
begin
  Result := False;
  if (ABmp <> nil) and AInfo.EsValido and (ALado >= 4) then
  begin
    ABmp.PixelFormat := pf24bit;
    ABmp.SetSize(ALado, ALado);
    ABmp.Canvas.Brush.Style := bsSolid;
    ABmp.Canvas.Brush.Color := AInfo.Color;
    ABmp.Canvas.FillRect(System.Types.Rect(0, 0, ALado, ALado));
    ABmp.Canvas.Brush.Style := bsClear;
    ABmp.Canvas.Pen.Color := clBlack;
    ABmp.Canvas.Pen.Width := 1;
    ABmp.Canvas.Rectangle(0, 0, ALado, ALado);
    Result := True;
  end;
end;

function BuscarInfoBasicoEnArticuloContextual(
  AConexion: TUniConnection;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>;
  out AInfo: TInfoBasico): Boolean;
var
  Texto, Segmento: string;
  Segmentos: TArray<string>;
  i: Integer;

  function ProbarValorArticulo(const AValor: string): Boolean;
  var
    IdVa: string;
  begin
    Result := False;
    if (Trim(ACodArt) <> '') and (Trim(AValor) <> '') then
      for IdVa in ADict.Values do
        if not Result then
          Result := ObtenerInfoBasicoArticulo(
            AConexion, ACodArt, IdVa, AValor, AInfo);
  end;

begin
  AInfo := Default(TInfoBasico);
  Result := False;
  Texto := Trim(ATexto);
  if (ADict <> nil) and (Texto <> '') then
  begin
    Result := ProbarValorArticulo(Texto);
    if (not Result) and (Pos('/', Texto) > 0) then
    begin
      Segmentos := Texto.Split(['/']);
      i := High(Segmentos);
      while (i >= 0) and (not Result) do
      begin
        Segmento := Trim(Segmentos[i]);
        Result := ProbarValorArticulo(Segmento);
        Dec(i);
      end;
    end;
    if not Result then
      Result := BuscarInfoBasicoEnArticulo(
        AConexion, Texto, ADict, AInfo);
  end;
end;

function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
  const ACodArt, AIdVA, AValor: string;
  out AInfo: TInfoBasico): Boolean;
var
  sClave: string;
begin
  AInfo := Default(TInfoBasico);
  Result := False;
  sClave := ClaveCacheArticulo(ACodArt, AIdVA, AValor);
  if (Trim(ACodArt) <> '') and (Trim(AValor) <> '') then
  begin
    if GCacheArticulo.TryGetValue(sClave, AInfo) then
      Result := AInfo.EsValido
    else if GLecturasPersistencia <> nil then
    begin
      Result := GLecturasPersistencia.ObtenerInfoBasicoArticulo(
        AConexion,
        ACodArt,
        AIdVA,
        AValor,
        AInfo);
      GCacheArticulo.AddOrSetValue(sClave, AInfo);
    end;
  end;
end;

function SeleccionarAvConPaleta(AConexion: TUniConnection;
                                const AIdVa: string;
                                const AAvs: array of string;
                                const AValorActual: string;
                                out AValor: string;
                                AScreenLeft, AScreenTop,
                                AWidthHint: Integer;
                                const ACodArt: string): Boolean;
begin
  AValor := '';
  Result := False;
  if (Length(AAvs) > 0) and
     (GSelectorPresentacion <> nil) then
    Result := GSelectorPresentacion.Seleccionar(
      AConexion,
      GLecturasPersistencia,
      AIdVa,
      AAvs,
      AValorActual,
      AValor,
      AScreenLeft,
      AScreenTop,
      AWidthHint,
      ACodArt);
end;

initialization
  GCache             := TDictionary<string, TInfoBasico>.Create;
  GCacheArticulo     := TDictionary<string, TInfoBasico>.Create;
  GCacheCargado      := False;
  GMapaGlobal        := nil;
  GMapaGlobalCargado := False;

finalization
  GSelectorPresentacion := nil;
  GLecturasPersistencia := nil;
  FreeAndNil(GCache);
  FreeAndNil(GCacheArticulo);
  FreeAndNil(GMapaGlobal);

end.
