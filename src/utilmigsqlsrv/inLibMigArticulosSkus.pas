{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosSkus                                         }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       2.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocartbap` (codigos de barras del legacy) y `dbo.ocartacp`      }
{    (SKUs con stock sin barcode) a:                                           }
{      - fza_articulos_skus   (un registro por art/color/talla)                }
{      - fza_atributos_sku    (link SKU ↔ valor color + SKU ↔ valor talla)    }
{      - fza_codigos_barras   (el barcode con CODIGO_UNIDAD_CB = SKU)         }
{                                                                              }
{    v2.0 — Optimización agresiva para volumenes grandes (cientos de miles    }
{    de barcodes):                                                             }
{      1. Pre-cargo en memoria los catalogos de colores y tallas              }
{         (fza_atributos_valores) en TDictionary<string, Integer>. Adios al   }
{         SELECT por fila.                                                     }
{      2. Pre-cargo en memoria los SKUs, barcodes y enlaces ya existentes      }
{         en destino en TDictionary<string, Boolean>. Pre-check O(1) en       }
{         vez de SELECT 1 por fila.                                            }
{      3. Bulk insert de 5000 filas por sentencia                              }
{         (INSERT IGNORE INTO ... VALUES (...), (...), ...).                  }
{                                                                              }
{    Resultado: pasa de ~3 round-trips por fila a 1 round-trip cada 5000     }
{    filas. Las tablas de tamaño medio (~80k filas) se vuelcan en segundos.  }
{                                                                              }
{    Formato CODIGO_UNIDAD_SKU (mismo patron que demo Factuzam):              }
{      Si hay color y talla:    ARTICULO/COLOR/TALLA                          }
{      Si solo color:           ARTICULO/COLOR                                }
{      Si solo talla:           ARTICULO/TALLA                                }
{      Si ni color ni talla:    ARTICULO                                       }
{                                                                              }
{    CODIGO_VAR_SKU: 'TC' / 'C' / 'T' / '-'                                    }
{******************************************************************************}
unit inLibMigArticulosSkus;

interface

uses
  UMigEngine;

procedure MigrarArticulosSkus(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni;

const
  BATCH_SIZE = 5000;

// =========================================================================
//  Helpers locales
// =========================================================================

// En el legacy '0' y '00' son colores REALES distintos (la BBDD legacy
// no tiene articulos sin color). Solo la cadena vacia se considera
// ausencia de color.
function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// Formato siempre ARTICULO/COLOR/TALLA. Cuando color o talla vienen
// vacios/sentinela usamos un placeholder para que toda linea tenga
// los tres niveles. Asi inventario, SKU, codigos_barras y vistas
// trabajan con cadenas homogeneas.
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

function DeducirCodigoVar(const sColor, sTalla: string): string;
var bC, bT: Boolean;
begin
  bC := not EsColorVacio(sColor);
  bT := not EsTallaVacia(sTalla);
  if bC and bT then Exit('TC');
  if bC        then Exit('C');
  if bT        then Exit('T');
  Result := '-';
end;

// Deduce el tipo de codigo de barras a partir de su longitud:
//   8  -> 'EAN8'   (codigos cortos, comunes en algunos legacy)
//   12 -> 'UPC'    (formato USA)
//   13 -> 'EAN13'  (el europeo estandar)
//   14 -> 'ITF14'  (logistica)
//   resto -> 'OTRO'
function DeducirTipoBarcode(const sBarcode: string): string;
begin
  case Length(Trim(sBarcode)) of
    8:  Result := 'EAN8';
    12: Result := 'UPC';
    13: Result := 'EAN13';
    14: Result := 'ITF14';
  else
    Result := 'OTRO';
  end;
end;

// =========================================================================
//  Carga de catalogos / existentes en memoria (UNA sola query cada uno)
// =========================================================================

procedure CargarMapaAV(Eng: TMigEngine; const sIdVa: string;
                       Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    // ORDER BY ID_AV DESC + AddOrSetValue (gana la ultima fila) => el
    // MIN(ID_AV) queda como canonico, igual que BuscarIdAV. Asi el tag de
    // talla del SKU coincide con el detalle del conjunto aunque el catalogo
    // tenga AV duplicados (mismo texto, distinto ID_AV).
    q.SQL.Text   :=
      'SELECT AV, ID_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :v ' +
      'ORDER BY ID_AV DESC';
    q.ParamByName('v').AsString := sIdVa;
    q.Open;
    while not q.Eof do
    begin
      Mapa.AddOrSetValue(
        UpperCase(Trim(q.FieldByName('AV').AsString)),
        q.FieldByName('ID_AV').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

procedure CargarStringSet(Eng: TMigEngine; const sSql: string;
                          Conjunto: TDictionary<string, Boolean>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := sSql;
    q.Open;
    while not q.Eof do
    begin
      Conjunto.AddOrSetValue(q.Fields[0].AsString, True);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarArticulosSkus(Eng: TMigEngine; var Stats: TMigStats);
const
  // El origen son DOS fuentes UNIDAS:
  //   - ocartbap: filas con barcode. Estas SI generan codigo de
  //     barras en fza_codigos_barras ademas del SKU.
  //   - ocartacp: filas con stock pero sin barcode. Generan SKU
  //     vacio (sin entrada en fza_codigos_barras). Asi el
  //     inventario nunca tiene CODIGO_UNIDAD huerfano.
  // Cuando un (art, color, talla) aparece en ambas tablas, se elige
  // la de ocartbap (que trae barcode). El UNION ALL las pone ambas
  // ordenadas por CodigoBarras vacio al final.
  // ColorSlot: codigo interno de color del proveedor. La fuente canonica es
  // ocartcol.Color; el color de la tabla origen solo se usa como respaldo.
  cSelectSrc =
    'SELECT * FROM (' +
    '  SELECT bap.Articulo, bap.Color, bap.Talla, bap.Cantidad, ' +
    '         bap.CodigoBarras, ' +
    '         CASE ' +
    '           WHEN ac.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '           WHEN bap.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(bap.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(bap.Color))) ' +
    '           ELSE ''0'' ' +
    '         END AS ColorSlot, ' +
    '         1 AS FuentePrior ' +
    '  FROM dbo.ocartbap bap ' +
    '  LEFT JOIN dbo.ocartcol ac ' +
    '         ON ac.Articulo = bap.Articulo ' +
    '        AND ac.Color    = bap.Color ' +
    '  LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    '  WHERE LTRIM(RTRIM(bap.Articulo))     <> '''' ' +
    '    AND LTRIM(RTRIM(bap.CodigoBarras)) <> '''' ' +
    '  UNION ALL ' +
    '  SELECT acp.Articulo, acp.Color, acp.Talla, ' +
    '         1 AS Cantidad, ' +
    '         '''' AS CodigoBarras, ' +
    '         CASE ' +
    '           WHEN ac.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '           WHEN acp.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(acp.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(acp.Color))) ' +
    '           ELSE ''0'' ' +
    '         END AS ColorSlot, ' +
    '         2 AS FuentePrior ' +
    '  FROM dbo.ocartacp acp ' +
    '  LEFT JOIN dbo.ocartcol ac ' +
    '         ON ac.Articulo = acp.Articulo ' +
    '        AND ac.Color    = acp.Color ' +
    '  LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    '  WHERE LTRIM(RTRIM(acp.Articulo)) <> '''' ' +
    ') X ' +
    'ORDER BY Articulo, Color, Talla, FuentePrior, CodigoBarras';
  cColsSkus =
    'CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    'ESACTIVO_SKU, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsAtbSku =
    'CODIGO_UNIDAD_SKU_SA, ID_AV_SA, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsBarras =
    'CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
    'ESPRINCIPAL_CB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                          TUniQuery;
  bulkSkus, bulkAtbSku, bulkCB:  TBulkInsert;
  // Caches en memoria
  oColoresMap:                   TDictionary<string, Integer>;
  oTallasMap:                    TDictionary<string, Integer>;
  oSkusVistos:                   TDictionary<string, Boolean>;
  oBarcodesVistos:               TDictionary<string, Boolean>;
  oSkuAtbVistos:                 TDictionary<string, Boolean>;
  // Variables del bucle
  sArt, sColorRaw, sTalla:       string;
  sDescColor, sBarcode:          string;
  sCodUnidad, sCodVar:           string;
  iIdAvColor, iIdAvTalla:        Integer;
  fCantidad:                     Double;
  sAhora, sUser, sFila, sKey:    string;
  sPrincipal:                    string;
begin
  Eng.Log('  cargando caches en memoria...');
  oColoresMap     := TDictionary<string, Integer>.Create;
  oTallasMap      := TDictionary<string, Integer>.Create;
  oSkusVistos     := TDictionary<string, Boolean>.Create;
  oBarcodesVistos := TDictionary<string, Boolean>.Create;
  oSkuAtbVistos   := TDictionary<string, Boolean>.Create;
  qSrc := nil;
  bulkSkus   := nil;
  bulkAtbSku := nil;
  bulkCB     := nil;
  try
    // Pre-cargar catalogos: una query por cada uno, milisegundos.
    CargarMapaAV(Eng, 'CO',  oColoresMap);
    CargarMapaAV(Eng, 'TAL', oTallasMap);
    Eng.Log('  catalogo: %d colores y %d tallas en cache',
            [oColoresMap.Count, oTallasMap.Count]);

    // Pre-cargar entradas ya existentes para idempotencia O(1).
    CargarStringSet(Eng,
      'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus',
      oSkusVistos);
    CargarStringSet(Eng,
      'SELECT CODIGO_BARRAS_CB FROM fza_codigos_barras',
      oBarcodesVistos);
    CargarStringSet(Eng,
      'SELECT CONCAT(CODIGO_UNIDAD_SKU_SA, ''|'', ID_AV_SA) ' +
      'FROM fza_atributos_sku',
      oSkuAtbVistos);
    Eng.Log('  destino: %d SKUs, %d barcodes y %d enlaces ya en BBDD',
            [oSkusVistos.Count, oBarcodesVistos.Count,
             oSkuAtbVistos.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);

    qSrc       := NuevoQOrigen(Eng, cSelectSrc);
    bulkSkus   := TBulkInsert.Create(Eng.ConDst,
                                      'fza_articulos_skus',
                                      cColsSkus,  BATCH_SIZE);
    bulkAtbSku := TBulkInsert.Create(Eng.ConDst,
                                      'fza_atributos_sku',
                                      cColsAtbSku, BATCH_SIZE);
    bulkCB     := TBulkInsert.Create(Eng.ConDst,
                                      'fza_codigos_barras',
                                      cColsBarras, BATCH_SIZE);

    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM ( ' +
      '  SELECT 1 AS N FROM dbo.ocartbap ' +
      '  WHERE LTRIM(RTRIM(Articulo))     <> '''' ' +
      '    AND LTRIM(RTRIM(CodigoBarras)) <> '''' ' +
      '  UNION ALL ' +
      '  SELECT 1 AS N FROM dbo.ocartacp ' +
      '  WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      ') X'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      // Chequeo de cancelacion cada 1000 filas para no impactar
      // rendimiento (TInterlocked es barato pero acumula).
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en SKUs, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sColorRaw  := Trim(qSrc.FieldByName('Color').AsString);
      sTalla     := Trim(qSrc.FieldByName('Talla').AsString);
      // ColorSlot ya viene normalizado desde SQL con el codigo interno
      // de color del proveedor.
      sDescColor := Trim(qSrc.FieldByName('ColorSlot').AsString);
      sBarcode   := Trim(qSrc.FieldByName('CodigoBarras').AsString);
      fCantidad  := qSrc.FieldByName('Cantidad').AsFloat;

      if sArt = '' then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      if (sDescColor = '') and (sColorRaw <> '') then
        sDescColor := UpperCase(sColorRaw);

      sCodUnidad := ConstruirCodigoUnidad(sArt, sDescColor,
                                           UpperCase(sTalla));
      sCodVar    := DeducirCodigoVar(sDescColor, sTalla);

      // 1. SKU en fza_articulos_skus (si no existe ya)
      if not oSkusVistos.ContainsKey(sCodUnidad) then
      begin
        sFila := Format('%s, %s, %s, ''S'', %s, %s, %s, %s',
          [ValorOrNull(sCodUnidad),
           ValorOrNull(sArt),
           ValorOrNull(sCodVar),
           sAhora, sAhora, sUser, sUser]);
        bulkSkus.Add(sFila);
        oSkusVistos.AddOrSetValue(sCodUnidad, True);
        Inc(Stats.Insertadas);
      end;

      // 2. Enlaces SKU ↔ valor color/talla
      if not EsColorVacio(sDescColor) then
      begin
        if oColoresMap.TryGetValue(UpperCase(sDescColor),
                                    iIdAvColor) then
        begin
          sKey := sCodUnidad + '|' + IntToStr(iIdAvColor);
          if not oSkuAtbVistos.ContainsKey(sKey) then
          begin
            sFila := Format('%s, %d, %s, %s, %s, %s',
              [ValorOrNull(sCodUnidad), iIdAvColor,
               sAhora, sAhora, sUser, sUser]);
            bulkAtbSku.Add(sFila);
            oSkuAtbVistos.AddOrSetValue(sKey, True);
          end;
        end;
      end;
      if not EsTallaVacia(sTalla) then
      begin
        if oTallasMap.TryGetValue(UpperCase(sTalla), iIdAvTalla) then
        begin
          sKey := sCodUnidad + '|' + IntToStr(iIdAvTalla);
          if not oSkuAtbVistos.ContainsKey(sKey) then
          begin
            sFila := Format('%s, %d, %s, %s, %s, %s',
              [ValorOrNull(sCodUnidad), iIdAvTalla,
               sAhora, sAhora, sUser, sUser]);
            bulkAtbSku.Add(sFila);
            oSkuAtbVistos.AddOrSetValue(sKey, True);
          end;
        end;
      end;

      // 3. Barcode (si no existe ya). Tipo deducido por longitud:
      // EAN8, EAN13, UPC, ITF14 segun corresponda.
      if sBarcode <> '' then
      begin
        if not oBarcodesVistos.ContainsKey(sBarcode) then
        begin
          if fCantidad <= 1 then
            sPrincipal := 'S'
          else
            sPrincipal := 'N';
          sFila := Format('%s, %s, %s, %s, %s, %s, %s, %s',
            [ValorOrNull(sBarcode),
             ValorOrNull(sCodUnidad),
             ValorOrNull(DeducirTipoBarcode(sBarcode)),
             '''' + sPrincipal + '''',
             sAhora, sAhora, sUser, sUser]);
          bulkCB.Add(sFila);
          oBarcodesVistos.AddOrSetValue(sBarcode, True);
        end;
      end;

      qSrc.Next;
    end;

    bulkSkus.FlushPendiente;
    bulkAtbSku.FlushPendiente;
    bulkCB.FlushPendiente;
  finally
    bulkCB.Free;
    bulkAtbSku.Free;
    bulkSkus.Free;
    qSrc.Free;
    oSkuAtbVistos.Free;
    oBarcodesVistos.Free;
    oSkusVistos.Free;
    oTallasMap.Free;
    oColoresMap.Free;
  end;
end;

end.
