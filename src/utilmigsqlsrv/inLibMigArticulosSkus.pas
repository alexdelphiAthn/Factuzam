{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosSkus                                         }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocartbap` (codigos de barras del legacy) a:                    }
{      - fza_articulos_skus  (un registro por combinacion art/color/talla)     }
{      - fza_atributos_sku   (enlace SKU ↔ valor color + SKU ↔ valor talla)   }
{      - fza_codigos_barras  (el barcode en si, con CODIGO_UNIDAD_CB=SKU)     }
{                                                                              }
{    `ocartbap` es la fuente correcta de SKUs reales — solo existen las        }
{    combinaciones que el cliente realmente vende (con barcode asignado).     }
{    Las generaciones cartesianas de ocartcol × ocarttal pueden incluir        }
{    falsos positivos.                                                         }
{                                                                              }
{    Formato CODIGO_UNIDAD_SKU (mismo patron que demo Factuzam):              }
{      Si hay color y talla:    ARTICULO/COLOR/TALLA                          }
{      Si solo color:           ARTICULO/COLOR                                }
{      Si solo talla:           ARTICULO/TALLA                                }
{      Si ni color ni talla:    ARTICULO                                       }
{    Donde COLOR es la descripcion canonica del color basico (via JOIN a      }
{    occolor) y TALLA es el texto literal de ocartbap.Talla. Sentinel "0"     }
{    y "INDEFINIDO" se consideran "sin valor".                                }
{                                                                              }
{    CODIGO_VAR_SKU:                                                          }
{      - 'TC' si hay color y talla                                            }
{      - 'C'  solo color                                                      }
{      - 'T'  solo talla                                                      }
{      - '-'  ninguno                                                         }
{                                                                              }
{    Idempotente: comprueba si el SKU o el barcode ya existen antes de        }
{    insertar.                                                                 }
{******************************************************************************}
unit inLibMigArticulosSkus;

interface

uses
  UMigEngine;

procedure MigrarArticulosSkus(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// =========================================================================
//  Helpers locales
// =========================================================================

// Devuelve True si el color del origen representa "sin color".
function EsColorVacio(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'INDEFINIDO') or (u = '00');
end;

// Devuelve True si la talla representa "sin talla" (UNI = unica = sin
// variacion en muchos legacy).
function EsTallaVacia(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// Construye el CODIGO_UNIDAD_SKU a partir de las piezas, omitiendo
// las dimensiones "vacias".
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
begin
  Result := sArt;
  if not EsColorVacio(sColor) then Result := Result + '/' + sColor;
  if not EsTallaVacia(sTalla) then Result := Result + '/' + sTalla;
end;

// Deduce CODIGO_VAR_SKU: 'TC' / 'C' / 'T' / '-'
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

// Inserta una fila en fza_articulos_skus si no existe.
function InsertarSku(Eng: TMigEngine; const sCodUnidad, sCodArt,
                     sCodVar: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = :u';
    qChk.ParamByName('u').AsString := sCodUnidad;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_articulos_skus (' +
        'CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
        'ESACTIVO_SKU, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:u, :a, :v, ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('u').AsString := sCodUnidad;
    qIns.ParamByName('a').AsString := sCodArt;
    qIns.ParamByName('v').AsString := sCodVar;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Inserta el enlace SKU ↔ valor atributo si no existe.
procedure EnlazarSkuAtributo(Eng: TMigEngine;
                              const sCodUnidad: string; iIdAv: Integer);
var qChk, qIns: TUniQuery;
begin
  if iIdAv <= 0 then Exit;
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_atributos_sku ' +
      'WHERE CODIGO_UNIDAD_SKU_SA = :u AND ID_AV_SA = :v';
    qChk.ParamByName('u').AsString  := sCodUnidad;
    qChk.ParamByName('v').AsInteger := iIdAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit;
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_atributos_sku (' +
        'CODIGO_UNIDAD_SKU_SA, ID_AV_SA, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:u, :v, :ia, :im, :ua, :um)';
    qIns.ParamByName('u').AsString    := sCodUnidad;
    qIns.ParamByName('v').AsInteger   := iIdAv;
    qIns.ParamByName('ia').AsDateTime := Now;
    qIns.ParamByName('im').AsDateTime := Now;
    qIns.ParamByName('ua').AsString   := Eng.Usuario;
    qIns.ParamByName('um').AsString   := Eng.Usuario;
    qIns.ExecSQL;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Inserta un barcode en fza_codigos_barras si no existe ya.
function InsertarBarcode(Eng: TMigEngine; const sBarcode,
                          sCodUnidad: string;
                          bPrincipal: Boolean): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_codigos_barras ' +
      'WHERE CODIGO_BARRAS_CB = :b';
    qChk.ParamByName('b').AsString := sBarcode;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_codigos_barras (' +
        'CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
        'ESPRINCIPAL_CB, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:b, :u, ''EAN13'', :p, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('b').AsString := sBarcode;
    qIns.ParamByName('u').AsString := sCodUnidad;
    if bPrincipal then
      qIns.ParamByName('p').AsString := 'S'
    else
      qIns.ParamByName('p').AsString := 'N';
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarArticulosSkus(Eng: TMigEngine; var Stats: TMigStats);
const
  // Resolvemos el nombre canonico del color en el SQL (JOIN a occolor)
  // para que sea consistente con el catalogo de fza_atributos_valores.
  cSelectSrc =
    'SELECT bap.Articulo, bap.Color, bap.Talla, bap.Cantidad, ' +
    '       bap.CodigoBarras, ' +
    '       ISNULL(c.Descripcion, bap.Color) AS DescColor ' +
    'FROM dbo.ocartbap bap ' +
    // bap.Color es el codigo local; occolor.ColorBasico es el FK al
    // canonico. Si en bap.Color viene el ColorBasico directo el JOIN
    // matchea, si viene la version local quedaria NULL → fallback.
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = bap.Articulo ' +
    '                         AND ac.Color    = bap.Color ' +
    'LEFT JOIN dbo.occolor  c  ON c.ColorBasico = ac.ColorBasico ' +
    'WHERE LTRIM(RTRIM(bap.Articulo))     <> '''' ' +
    '  AND LTRIM(RTRIM(bap.CodigoBarras)) <> '''' ' +
    'ORDER BY bap.Articulo, bap.Color, bap.Talla, bap.CodigoBarras';
var
  qSrc:                    TUniQuery;
  sArt, sColorRaw, sTalla: string;
  sDescColor, sBarcode:    string;
  sCodUnidad, sCodVar:     string;
  iIdAvColor, iIdAvTalla:  Integer;
  fCantidad:               Double;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartbap ' +
      'WHERE LTRIM(RTRIM(Articulo))     <> '''' ' +
      '  AND LTRIM(RTRIM(CodigoBarras)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sColorRaw  := Trim(qSrc.FieldByName('Color').AsString);
      sTalla     := Trim(qSrc.FieldByName('Talla').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      sBarcode   := Trim(qSrc.FieldByName('CodigoBarras').AsString);
      fCantidad  := qSrc.FieldByName('Cantidad').AsFloat;

      if (sArt = '') or (sBarcode = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      // Si no resolvimos color en occolor (no estaba en ocartcol) y el
      // sColorRaw no es un sentinel, lo usamos tal cual.
      if (sDescColor = '') and not EsColorVacio(sColorRaw) then
        sDescColor := sColorRaw;

      sCodUnidad := ConstruirCodigoUnidad(sArt, UpperCase(sDescColor),
                                           UpperCase(sTalla));
      sCodVar    := DeducirCodigoVar(sDescColor, sTalla);

      // 1. Crear (o saltar) la fila en fza_articulos_skus
      if InsertarSku(Eng, sCodUnidad, sArt, sCodVar) then
        Inc(Stats.Insertadas)
      else
        Inc(Stats.Saltadas);

      // 2. Enlazar el SKU con los valores de atributo (si los tiene)
      if not EsColorVacio(sDescColor) then
      begin
        iIdAvColor := BuscarIdAV(Eng, 'CO', UpperCase(sDescColor));
        EnlazarSkuAtributo(Eng, sCodUnidad, iIdAvColor);
      end;
      if not EsTallaVacia(sTalla) then
      begin
        iIdAvTalla := BuscarIdAV(Eng, 'TAL', UpperCase(sTalla));
        EnlazarSkuAtributo(Eng, sCodUnidad, iIdAvTalla);
      end;

      // 3. Insertar el barcode. Como ocartbap puede tener varios
      //    barcodes por SKU (Cantidad distinta), el primero detectado
      //    (Cantidad=1) lo marcamos principal; el resto secundarios.
      try
        InsertarBarcode(Eng, sBarcode, sCodUnidad, fCantidad <= 1);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('barcode', sBarcode, E.Message,
            sCodUnidad, '');
        end;
      end;

      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

end.
