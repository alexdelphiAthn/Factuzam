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
  System.Types, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  Uni,
  cxGraphics,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, System.UITypes;

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
  // que solo mide el texto. Desglose: 20 geometrico (MARGEN_IZQ 4 +
  // LADO_CUADRADO 12 + HUECO_TEXTO 4) + holgura para que el texto no salga
  // pegado al cuadradito ni recortado (p.ej. "MARRON" en la columna Color).
  ANCHO_SWATCH_PX = 50;

// Invalida la cache (llamar al refrescar fza_atributos_basicos).
procedure InvalidarCachePaleta;

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
  AConexion: TUniConnection; ACanvas: TcxCanvas;
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
  AConexion: TUniConnection; const ACodArt, ATexto: string;
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
                                  AAvToImageIndex: TDictionary<string, Integer>);

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

uses
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  // Form auxiliar (no en interface) usado solo por SeleccionarAvConPaleta.
  // Se muestra como un dropdown sin marco: posicionado a las coordenadas
  // recibidas (justo debajo del editor), ancho calculado segun el AV mas
  // largo, alto = items * 22 con tope. Un click selecciona+cierra; Esc o
  // click fuera cancelan.
  TfrmSelPalAvAux = class(TForm)
  private
    FConexion  : TUniConnection;
    FListBox  : TListBox;
    FIdVa     : string;
    FAvs      : TArray<string>;
    FShown    : Boolean;
    FInfoArticulo: TDictionary<string, TInfoBasico>;
    procedure CargarPaletaArticulo(const ACodArt, AIdVa: string);
    procedure ListBoxDrawItem(Control: TWinControl; Index: Integer;
                              ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxMouseDown(Sender: TObject; Button: TMouseButton;
                               Shift: TShiftState; X, Y: Integer);
    procedure ListBoxKeyDown(Sender: TObject;
                             var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor CreateConOpciones(AConexion: TUniConnection;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  const AValorActual: string;
                                  AScreenLeft, AScreenTop, AWidthHint: Integer;
                                  const ACodArt: string);
    destructor Destroy; override;
  end;

var
  GCache        : TDictionary<string, TInfoBasico>;
  GCacheArticulo: TDictionary<string, TInfoBasico>;
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

procedure CargarCache(AConexion: TUniConnection);
var
  q    : TUniQuery;
  Info : TInfoBasico;
  sIdVa, sCod, sNom, sAv, sDesc: string;
begin
  GCache.Clear;
  GCacheCargado := False;
  if AConexion = nil then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    // Hacemos JOIN con fza_atributos_valores para cachear también los textos reales (AV y DESCRIPCION)
    // que los usuarios han escrito libremente y que son los que viajan en los SKUs de los Grids.
    q.SQL.Text :=
      'SELECT B.ID_VA_ATB, ' +
      '       B.CODIGO_ATB, B.NOMBRE_ATB, B.HEX_ATB, V.AV, V.DESCRIPCION_AV ' +
      '  FROM fza_atributos_basicos B ' +
      '  LEFT JOIN fza_atributos_valores V ON V.ID_ATB_AV = B.ID_ATB ' +
      ' WHERE B.ESACTIVO_ATB = ''S'' ' +
      '   AND B.HEX_ATB IS NOT NULL ' +
      '   AND B.HEX_ATB <> '''' ';
    q.Open;
    while not q.Eof do
    begin
      Info := Default(TInfoBasico);
      Info.HexColor := q.FieldByName('HEX_ATB').AsString;
      Info.Color    := HexToColor(Info.HexColor);
      Info.Nombre   := q.FieldByName('NOMBRE_ATB').AsString;
      Info.EsValido := Info.Color <> clNone;

      if Info.EsValido then
      begin
        sIdVa := q.FieldByName('ID_VA_ATB').AsString;
        sCod  := q.FieldByName('CODIGO_ATB').AsString;
        sNom  := q.FieldByName('NOMBRE_ATB').AsString;
        sAv   := q.FieldByName('AV').AsString;
        sDesc := q.FieldByName('DESCRIPCION_AV').AsString;
        // Cacheamos por el Código del color básico (ej. "01")
        GCache.AddOrSetValue(ClaveCache(sIdVa, sCod), Info);
        // Cacheamos por el Nombre del color básico (ej. "Rojo Básico")
        if Trim(sNom) <> '' then
          GCache.AddOrSetValue(ClaveCache(sIdVa, sNom), Info);
        // Cacheamos por el Valor/Token del proveedor que compone el SKU (ej. "ROJO-FUEGO")
        if Trim(sAv) <> '' then
          GCache.AddOrSetValue(ClaveCache(sIdVa, sAv), Info);
        // Cacheamos por el texto libre exacto por si un grid lo muestra crudo (ej. "Rojo Fuego")
        if Trim(sDesc) <> '' then
          GCache.AddOrSetValue(ClaveCache(sIdVa, sDesc), Info);
      end;
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
  if GCacheArticulo <> nil then
    GCacheArticulo.Clear;
  GCacheCargado := False;
end;

function ObtenerInfoBasico(AConexion: TUniConnection;
                           const AIdVA, ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if (Trim(AIdVA) = '') or (Trim(ACodigoATB) = '') then Exit;
  if not GCacheCargado then
    CargarCache(AConexion);
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
  // OJO: si tocas alguno de estos tres, revisa ANCHO_SWATCH_PX en la
  // interface (debe ser >= MARGEN_IZQ + LADO_CUADRADO + HUECO_TEXTO, mas la
  // holgura que se quiera dar al texto a la derecha del cuadradito).
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

procedure CargarMapaAtributosArticulo(AConexion: TUniConnection;
                                      const ACodArt: string;
                                      ADict: TDictionary<string, string>);
var
  q : TUniQuery;
begin
  if ADict = nil then Exit;
  ADict.Clear;
  if (Trim(ACodArt) = '') or (AConexion = nil) then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
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

procedure CargarMapaAtributosGlobal(AConexion: TUniConnection;
                                    ADict: TDictionary<string, string>);
var
  q : TUniQuery;
  Nombre : string;
begin
  if ADict = nil then Exit;
  ADict.Clear;
  if AConexion = nil then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
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
  if (ACanvas = nil) or (AViewInfo = nil) then Exit;
  // Rescatar el texto de forma segura
  sTexto := AViewInfo.Text;
  if (sTexto = '') and
     (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item <> nil) then
    sTexto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);
  if ADict <> nil then
    Dict := ADict
  else
    Dict := ObtenerMapaAtributosGlobal(AConexion);
  if (Dict = nil) or (Dict.Count = 0) then Exit;
  if not BuscarInfoBasicoEnArticulo(AConexion, sTexto, Dict, Info) then Exit;
  // Pasamos sTexto explicitly a la función de pintado
  Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, sTexto);
end;

function PintarCeldaSwatchArticuloSiAplica(
  AConexion: TUniConnection; ACanvas: TcxCanvas;
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
     BuscarInfoBasicoEnArticuloContextual(AConexion, ACodArt, sTexto, Dict,
       Info) then
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
  if ADict = nil then Exit;
  Texto := Trim(ATexto);
  if Texto = '' then Exit;

  // 1) Probamos con el texto entero
  for IdVa in ADict.Values do
    if ObtenerInfoBasico(AConexion, IdVa, Texto, AInfo) then
      Exit(True);

  // 2) Si el texto es un SKU compuesto (ej: ART/COLOR/TALLA),
  // extraemos CADA segmento y lo comprobamos.
  if Pos('/', Texto) > 0 then
  begin
    Segmentos := Texto.Split(['/']);
    // Empezamos desde el final hacia el principio, pero ahora
    // revisamos todos (el color suele estar en el medio).
    for i := High(Segmentos) downto 0 do
    begin
      Segmento := Trim(Segmentos[i]);
      if Segmento <> '' then
      begin
        for IdVa in ADict.Values do
          if ObtenerInfoBasico(AConexion, IdVa, Segmento, AInfo) then
            Exit(True);
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
  if (AColumn = nil) or (ADict = nil) or (ADict.Count = 0) then Exit;
  Tabla := AColumn.GridView as TcxCustomGridTableView;
  if (Tabla = nil) or (Tabla.DataController = nil) then Exit;
  n := Tabla.DataController.RecordCount;
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    v := Tabla.DataController.Values[i, AColumn.Index];
    if VarIsNull(v) or VarIsClear(v) then Continue;
    if BuscarInfoBasicoEnArticulo(AConexion, VarToStr(v), ADict, Info) then
    begin
      AColumn.Width := AColumn.Width + ANCHO_SWATCH_PX;
      Exit(True);
    end;
  end;
end;

procedure RellenarImageListPaleta(AConexion: TUniConnection;
                                  AImages: TCustomImageList;
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
      if not ObtenerInfoBasico(AConexion, AIdVa, Av, Info) then Continue;

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

function PintarSwatchEnBitmap(ABmp: TBitmap; const AInfo: TInfoBasico;
                              ALado: Integer): Boolean;
begin
  Result := False;
  if (ABmp = nil) or (not AInfo.EsValido) or (ALado < 4) then Exit;
  ABmp.PixelFormat := pf24bit;
  ABmp.SetSize(ALado, ALado);
  ABmp.Canvas.Brush.Style := bsSolid;
  ABmp.Canvas.Brush.Color := AInfo.Color;
  ABmp.Canvas.FillRect(System.Types.Rect(0, 0, ALado, ALado));
  ABmp.Canvas.Brush.Style := bsClear;
  ABmp.Canvas.Pen.Color   := clBlack;
  ABmp.Canvas.Pen.Width   := 1;
  ABmp.Canvas.Rectangle(0, 0, ALado, ALado);
  Result := True;
end;

{ TfrmSelPalAvAux }

procedure TfrmSelPalAvAux.CargarPaletaArticulo(const ACodArt,
  AIdVa: string);
var
  q: TUniQuery;
  Info: TInfoBasico;
  sAv: string;
begin
  if Trim(ACodArt) <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      q.SQL.Text :=
        'SELECT av.AV, b.NOMBRE_ATB, b.HEX_ATB ' +
        '  FROM fza_articulos_atributos_basicos aab ' +
        '  JOIN fza_atributos_valores av ON av.ID_AV = aab.ID_AV_AAB ' +
        '  JOIN fza_atributos_basicos b ON b.ID_ATB = aab.ID_ATB_AAB ' +
        ' WHERE aab.CODIGO_ART_AAB = :art ' +
        '   AND (:idva = '''' OR av.ID_VA_AV = :idva) ' +
        '   AND b.ESACTIVO_ATB = ''S'' ' +
        '   AND b.HEX_ATB IS NOT NULL ' +
        '   AND b.HEX_ATB <> ''''';
      q.ParamByName('art').AsString := ACodArt;
      q.ParamByName('idva').AsString := AIdVa;
      q.Open;
      while not q.Eof do
      begin
        Info := Default(TInfoBasico);
        Info.HexColor := q.FieldByName('HEX_ATB').AsString;
        Info.Color := HexToColor(Info.HexColor);
        Info.Nombre := q.FieldByName('NOMBRE_ATB').AsString;
        Info.EsValido := Info.Color <> clNone;
        sAv := UpperCase(Trim(q.FieldByName('AV').AsString));
        if Info.EsValido and (sAv <> '') then
          FInfoArticulo.AddOrSetValue(sAv, Info);
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function BuscarInfoBasicoEnArticuloContextual(
  AConexion: TUniConnection; const ACodArt, ATexto: string;
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
          Result := ObtenerInfoBasicoArticulo(AConexion, ACodArt, IdVa,
            AValor, AInfo);
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
      Result := BuscarInfoBasicoEnArticulo(AConexion, Texto, ADict, AInfo);
  end;
end;

function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
  const ACodArt, AIdVA, AValor: string;
  out AInfo: TInfoBasico): Boolean;
var
  q: TUniQuery;
  sClave: string;
begin
  AInfo := Default(TInfoBasico);
  Result := False;
  sClave := ClaveCacheArticulo(ACodArt, AIdVA, AValor);
  if (Trim(ACodArt) <> '') and (Trim(AValor) <> '') then
  begin
    if GCacheArticulo.TryGetValue(sClave, AInfo) then
      Result := AInfo.EsValido
    else
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := AConexion;
        q.SQL.Text :=
          'SELECT b.NOMBRE_ATB, b.HEX_ATB ' +
          '  FROM fza_articulos_atributos_basicos aab ' +
          '  JOIN fza_atributos_valores av ON av.ID_AV = aab.ID_AV_AAB ' +
          '  JOIN fza_atributos_basicos b ON b.ID_ATB = aab.ID_ATB_AAB ' +
          ' WHERE aab.CODIGO_ART_AAB = :art ' +
          '   AND av.AV = :av ' +
          '   AND (:idva = '''' OR av.ID_VA_AV = :idva) ' +
          '   AND b.ESACTIVO_ATB = ''S'' ' +
          '   AND b.HEX_ATB IS NOT NULL ' +
          '   AND b.HEX_ATB <> '''' ' +
          ' LIMIT 1';
        q.ParamByName('art').AsString := ACodArt;
        q.ParamByName('av').AsString := AValor;
        q.ParamByName('idva').AsString := AIdVA;
        q.Open;
        if not q.IsEmpty then
        begin
          AInfo.HexColor := q.FieldByName('HEX_ATB').AsString;
          AInfo.Color := HexToColor(AInfo.HexColor);
          AInfo.Nombre := q.FieldByName('NOMBRE_ATB').AsString;
          AInfo.EsValido := AInfo.Color <> clNone;
        end;
        GCacheArticulo.AddOrSetValue(sClave, AInfo);
        Result := AInfo.EsValido;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

constructor TfrmSelPalAvAux.CreateConOpciones(AConexion: TUniConnection;
                                              const AIdVa: string;
                                              const AAvs: array of string;
                                              const AValorActual: string;
                                              AScreenLeft, AScreenTop,
                                              AWidthHint: Integer;
                                              const ACodArt: string);
const
  ALTO_FILA   = 22;
  ANCHO_MIN   = 80;
  ALTO_MAX    = 360;
  EXTRA_W     = 32;  // swatch(12) + margenes + scrollbar margin
  PADD_LISTB  = 4;   // border interno del listbox
var
  i, idxSel, MaxTextW, W, H : Integer;
  Bmp : TBitmap;
begin
  inherited CreateNew(nil);
  FConexion := AConexion;

  // Anclar explicitamente el popup al form activo (Caja / Inventarios)
  // como PopupParent. Sin esto el ShowModal de un form sin borde reasigna
  // el owner del HWND a Application.Handle y, al cerrarse (clic en una
  // opcion o FormDeactivate por clic fuera), la VCL devuelve el foco al
  // Application.MainForm trayendo el Principal al frente y hundiendo la
  // cadena Caja -> CajaMenu detras. Visualmente desaparece la Caja y solo
  // queda el desplegable de colores sobre el menu principal.
  //
  // pmExplicit con PopupParent capturado en el constructor es mas fiable
  // que pmAuto porque congela el padre al instante en que se invoca, no
  // al mostrar el modal (cuando la activacion podria haber bailado).
  if Screen.ActiveForm <> nil then
  begin
    Self.PopupParent := Screen.ActiveForm;
    Self.PopupMode   := pmExplicit;
  end
  else
    Self.PopupMode := pmAuto;

  BorderStyle := bsNone;
  Position    := poDesigned;
  Caption     := '';
  KeyPreview  := True;
  FShown      := False;
  OnShow       := FormShow;
  OnDeactivate := FormDeactivate;
  OnKeyDown    := FormKeyDown;

  FIdVa := AIdVa;
  FInfoArticulo := TDictionary<string, TInfoBasico>.Create;
  CargarPaletaArticulo(ACodArt, AIdVa);
  SetLength(FAvs, Length(AAvs));
  for i := 0 to High(AAvs) do
    FAvs[i] := AAvs[i];

  FListBox := TListBox.Create(Self);
  FListBox.Parent      := Self;
  FListBox.Align       := alClient;
  FListBox.Style       := lbOwnerDrawFixed;
  FListBox.BorderStyle := bsSingle;
  FListBox.ItemHeight  := ALTO_FILA;
  FListBox.OnDrawItem  := ListBoxDrawItem;
  FListBox.OnMouseDown := ListBoxMouseDown;
  FListBox.OnKeyDown   := ListBoxKeyDown;

  idxSel := -1;
  for i := 0 to High(AAvs) do
  begin
    FListBox.Items.Add(AAvs[i]);
    if (idxSel < 0) and SameText(AAvs[i], AValorActual) then
      idxSel := i;
  end;
  if (idxSel < 0) and (FListBox.Items.Count > 0) then
    idxSel := 0;
  if idxSel >= 0 then
    FListBox.ItemIndex := idxSel;
  ActiveControl := FListBox;

  // Ancho segun el AV mas largo
  MaxTextW := 0;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Self.Font);
    for i := 0 to High(AAvs) do
    begin
      W := Bmp.Canvas.TextWidth(AAvs[i]);
      if W > MaxTextW then MaxTextW := W;
    end;
  finally
    Bmp.Free;
  end;
  W := MaxTextW + EXTRA_W;
  if W < AWidthHint then W := AWidthHint;
  if W < ANCHO_MIN  then W := ANCHO_MIN;
  Width := W;

  // Alto adaptado, con tope
  H := Length(AAvs) * ALTO_FILA + PADD_LISTB;
  if H > ALTO_MAX then H := ALTO_MAX;
  Height := H;

  if (AScreenLeft >= 0) and (AScreenTop >= 0) then
  begin
    Left := AScreenLeft;
    Top  := AScreenTop;
  end
  else
    Position := poScreenCenter;
end;

destructor TfrmSelPalAvAux.Destroy;
begin
  FreeAndNil(FInfoArticulo);
  inherited Destroy;
end;

procedure TfrmSelPalAvAux.ListBoxDrawItem(Control: TWinControl; Index: Integer;
                                          ARect: TRect; State: TOwnerDrawState);
const
  LADO        = 12;
  MARGEN_IZQ  = 8;
  HUECO_TEXTO = 8;
var
  LB        : TListBox;
  Av        : string;
  Info      : TInfoBasico;
  Cuadrado  : TRect;
  TextRect  : TRect;
  Alto, Top : Integer;
  HayColor  : Boolean;
begin
  LB := Control as TListBox;
  if (Index < 0) or (Index >= LB.Items.Count) then Exit;
  Av := LB.Items[Index];

  // Fondo (respeta seleccion)
  if odSelected in State then
    LB.Canvas.Brush.Color := clHighlight
  else
    LB.Canvas.Brush.Color := clWindow;
  LB.Canvas.FillRect(ARect);

  HayColor := False;
  if FInfoArticulo <> nil then
    HayColor := FInfoArticulo.TryGetValue(UpperCase(Trim(Av)), Info);
  // Si FIdVa esta vacio o no casa, probamos contra el mapa global (mismo
  // fallback que usa el browse via BuscarInfoBasicoEnArticulo).
  if (not HayColor) and (Trim(FIdVa) <> '') then
    HayColor := ObtenerInfoBasico(FConexion, FIdVa, Av, Info);
  if not HayColor then
    HayColor := BuscarInfoBasicoEnArticulo(FConexion, Av,
      ObtenerMapaAtributosGlobal(FConexion), Info);

  if HayColor then
  begin
    Alto := ARect.Bottom - ARect.Top;
    if Alto > LADO then
      Top := ARect.Top + (Alto - LADO) div 2
    else
      Top := ARect.Top;
    Cuadrado := System.Types.Rect(ARect.Left + MARGEN_IZQ, Top,
                                  ARect.Left + MARGEN_IZQ + LADO,
                                  Top + LADO);
    LB.Canvas.Brush.Style := bsSolid;
    LB.Canvas.Brush.Color := Info.Color;
    LB.Canvas.FillRect(Cuadrado);
    LB.Canvas.Brush.Style := bsClear;
    LB.Canvas.Pen.Color   := clBlack;
    LB.Canvas.Pen.Width   := 1;
    LB.Canvas.Rectangle(Cuadrado);
    LB.Canvas.Brush.Style := bsSolid;
    TextRect := System.Types.Rect(Cuadrado.Right + HUECO_TEXTO, ARect.Top,
                                  ARect.Right, ARect.Bottom);
  end
  else
    TextRect := System.Types.Rect(ARect.Left + MARGEN_IZQ, ARect.Top,
                                  ARect.Right, ARect.Bottom);

  if odSelected in State then
    LB.Canvas.Font.Color := clHighlightText
  else
    LB.Canvas.Font.Color := clWindowText;
  LB.Canvas.Brush.Style := bsClear;
  Winapi.Windows.DrawText(LB.Canvas.Handle, PChar(Av), -1, TextRect,
                          DT_SINGLELINE or DT_VCENTER or DT_LEFT or
                          DT_END_ELLIPSIS);
  LB.Canvas.Brush.Style := bsSolid;

  if odFocused in State then
    LB.Canvas.DrawFocusRect(ARect);
end;

procedure TfrmSelPalAvAux.ListBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  if Button <> mbLeft then Exit;
  Idx := FListBox.ItemAtPos(System.Types.Point(X, Y), True);
  if Idx >= 0 then
  begin
    FListBox.ItemIndex := Idx;
    ModalResult := mrOk;
  end;
end;

procedure TfrmSelPalAvAux.ListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (FListBox.ItemIndex >= 0) then
  begin
    ModalResult := mrOk;
    Key := 0;
  end;
end;

procedure TfrmSelPalAvAux.FormShow(Sender: TObject);
begin
  FShown := True;
end;

procedure TfrmSelPalAvAux.FormDeactivate(Sender: TObject);
begin
  // Click fuera del popup -> cancela (como un combo). Guardamos con FShown
  // para que esto no dispare durante la creacion/animacion inicial.
  if FShown and (ModalResult = mrNone) then
    ModalResult := mrCancel;
end;

procedure TfrmSelPalAvAux.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
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
var
  F : TfrmSelPalAvAux;
begin
  AValor := '';
  Result := False;
  if Length(AAvs) = 0 then Exit;
  F := TfrmSelPalAvAux.CreateConOpciones(AConexion, AIdVa, AAvs, AValorActual,
    AScreenLeft, AScreenTop, AWidthHint, ACodArt);
  try
    if F.ShowModal = mrOk then
    begin
      if (F.FListBox.ItemIndex >= 0) and
         (F.FListBox.ItemIndex < Length(F.FAvs)) then
      begin
        AValor := F.FAvs[F.FListBox.ItemIndex];
        Result := True;
      end;
    end;
  finally
    F.Free;
  end;
end;

initialization
  GCache             := TDictionary<string, TInfoBasico>.Create;
  GCacheArticulo     := TDictionary<string, TInfoBasico>.Create;
  GCacheCargado      := False;
  GMapaGlobal        := nil;
  GMapaGlobalCargado := False;

finalization
  FreeAndNil(GCache);
  FreeAndNil(GCacheArticulo);
  FreeAndNil(GMapaGlobal);

end.
