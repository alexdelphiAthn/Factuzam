{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigMovimientos                                           }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Incorpora el HISTÓRICO de movimientos de almacén del legacy               }
{    (`dbo.ocmovarp`, SQL Server) a `fza_movimientos_almacen` (MariaDB).       }
{                                                                              }
{    Estrategia de coste (decision del usuario): PMP RODANTE por almacen,      }
{    alimentado por los precios reales de las entradas de albaran              }
{    (ocalbproarp.PrecioSIva, sin IVA). Sustituye al PMP del legacy y a la     }
{    salvaguarda del 15%. Reglas:                                              }
{      - Entrada de albaran de compra: coste = precio de su linea; recalcula   }
{        el PMP ponderado: (stock*PMP + uds*precio) / (stock + uds).           }
{      - Entrada de traspaso: arrastra el PMP del almacen ORIGEN.              }
{      - Regularizaciones de entrada y TODAS las salidas: usan el PMP vigente. }
{      - Semilla: hasta el 1er albaran del SKU se valora con el precio de      }
{        ese primer albaran (cte_alb1), para no valorar a coste 0.             }
{    PRECIO_MEDIO_MOV = PMP tras cada movimiento; orden por SKU + NUMERO_MOV.   }
{                                                                              }
{    Impacto en stock (decisión del usuario): los movimientos se migran        }
{    ACTIVOS (ESACTIVO_MOV='S') y RECALCULAN el stock. Tras el volcado se      }
{    reconstruye `fza_articulos_stockactual` por agregación de los            }
{    movimientos activos:                                                      }
{      CANTIDAD_STK        = Σ(entradas) − Σ(salidas)                          }
{      acumuladores _STK   = Σ por subtipo (compra, traspaso, venta, ...)     }
{      PRECIO_MEDIO_STK    = PMP del ÚLTIMO movimiento del SKU (rodante)       }
{      VALOR_TOTAL_STK     = CANTIDAD_STK * PRECIO_MEDIO_STK                    }
{    Importante: el PMP rodante se calcula AQUI (una vez, durante la           }
{    migracion) y NO con SP_RECALCULAR_PMP_LOTE_ALMACEN: asi controlamos el    }
{    arrastre origen->destino en traspasos y la semilla del primer albaran.    }
{    La reconstruccion de stock toma el PMP del ultimo movimiento del SKU.     }
{                                                                              }
{    Como esta migración reconstruye el stock desde el histórico completo,     }
{    es ALTERNATIVA a "Inventario inicial" (inLibMigInventarios): ejecuta      }
{    una u otra, no ambas, para no contar el stock dos veces.                  }
{                                                                              }
{    Resolución de códigos (igual que el resto de mappers):                    }
{      CODIGO_EMP_MOV     = origen.Empresa (entero como texto)                 }
{      CODIGO_ALM_MOV     = Abreviatura del almacén (ocalm), fallback número   }
{      CODIGO_UNIDAD_MOV  = ARTICULO/COLOR/TALLA (mismo patrón que SKUs)       }
{      CODIGO_ART_MOV     = el artículo                                        }
{      NUMERO_MOV         = 'MH' + ocmovarp.Numero a 10 dígitos                }
{                          (prefijo 'MH' = Movimiento Histórico, evita         }
{                           colisión con el contador 'MV' de la app)           }
{                                                                              }
{    Heurísticas (primera versión, afinar con el catálogo real del legacy):    }
{      - Dirección (TIPO_MOV E/S): ocmovarp.Tipo si es 'E'/'S'; si no, signo   }
{        de UnidadesStock; si no, signo de Cantidad. En RP manda Cantidad,     }
{        porque el legacy guarda Tipo='E' aunque sea salida a proveedor.       }
{      - TIPO_DOC_MOV: ocmovarp.TipoDoc pasa tal cual cuando ya coincide con   }
{        el destino (AC/AV/TR/AT/IN/DP/VE/AE/DC); sinónimos frecuentes         }
{        mapeados; RP se importa como DC; desconocido se clasifica por         }
{        dirección (E→IN, S→VE).                                               }
{                                                                              }
{    Reimport por REEMPLAZO: al arrancar borra su volcado 'MH' y recarga;      }
{    el INSERT IGNORE solo cubre duplicados intra-pasada. Stock por UPSERT.    }
{******************************************************************************}
unit inLibMigMovimientos;

interface

uses
  UMigEngine;

procedure MigrarMovimientos(Eng: TMigEngine; var Stats: TMigStats);
// Reconstruye fza_articulos_stockactual agregando TODOS los movimientos
// activos (cantidad neta + acumuladores por subtipo + PMP del ultimo). Se
// exporta para que el inventario inicial — que ahora genera sus propios
// movimientos de regularizacion 'IV' — cuadre el stock con el mismo
// criterio sin duplicar el SQL.
procedure ReconstruirStockDesdeMovimientos(Eng: TMigEngine);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB, Uni;

const
  BATCH_SIZE = 5000;
  // Prefijo del NUMERO_MOV migrado. 'MH' = Movimiento Histórico. Mantiene
  // los movimientos del legacy separados de los que genere la app con su
  // contador 'MV' (numéricos), evitando colisiones de PK.
  PREFIJO_NUM = 'MH';

// =========================================================================
//  Helpers locales (mismo criterio que inLibMigArticulosSkus / Inventarios)
// =========================================================================

// '0' y '00' son colores REALES en el legacy. Solo la cadena vacía se
// considera ausencia de color.
function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

// Literal SQL de texto que SIEMPRE va entrecomillado (incluso vacío). Para
// columnas NOT NULL que admiten cadena vacía pero no NULL (SERIE_DOC_MOV,
// NUMERO_DOC_MOV, LINEA_MOV). ValorOrNull no sirve: convertiría '' en NULL.
function Txt(const s: string): string;
begin
  Result := '''' + EscaparSQL(s) + '''';
end;

function EsTallaVacia(const s: string): Boolean;
var
  u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// Formato siempre ARTICULO/COLOR/TALLA con placeholders (0 / UNI) cuando
// faltan. Idéntico al de SKUs e Inventarios para que el movimiento
// referencie el mismo CODIGO_UNIDAD que ya migró el dominio de SKUs.
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var
  sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then
    sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then
    sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

// Una fecha es "real" si no es el cero de SQL Server. El proveedor OLE DB
// materializa las fechas vacías de datetime/smalldatetime como 1900-01-01,
// que IsNull NO detecta; sin este filtro FECHA_MOV salía siempre 01/01/1900
// cuando el legacy traía la fecha preferida a cero.
function FechaReal(const dt: TDateTime): Boolean;
begin
  Result := dt > EncodeDate(1900, 1, 2);
end;

// Dirección del movimiento para documentos que NO son traspaso. El flag Tipo
// del legacy es fiable aqui ('S' en ventas/albaranes de salida, 'E' en
// albaranes de entrada); si no es explicito, caemos al signo de las unidades
// de stock y por ultimo al de Cantidad. Por defecto entrada.
// OJO traspasos (TR/AT): aqui Tipo viene 'E' en las DOS patas y TipoMov trae
// 'SE', asi que NO sirven; su sentido se decide por estructura en el bucle
// (almacen del movimiento == almacen destino -> entrada; si no, salida).
function DeducirTipoMov(const sTipo: string;
                        fUnidades, fCantidad: Double): string;
var
  u: string;
begin
  u := UpperCase(Trim(sTipo));
  if u = 'E' then
    Result := 'E'
  else if u = 'S' then
    Result := 'S'
  else if fUnidades > 0 then
    Result := 'E'
  else if fUnidades < 0 then
    Result := 'S'
  else if fCantidad < 0 then
    Result := 'S'
  else
    Result := 'E';
end;

function DeducirTipoMovDocumento(const sTipoDoc, sTipo: string;
                                 fUnidades, fCantidad: Double): string;
var
  d: string;
begin
  d := UpperCase(Trim(sTipoDoc));
  if d = 'RP' then
  begin
    // RP = devolucion a proveedor. El Tipo legacy suele venir 'E';
    // la direccion real esta en el signo de Cantidad.
    if fCantidad < 0 then
      Result := 'S'
    else if fCantidad > 0 then
      Result := 'E'
    else if fUnidades < 0 then
      Result := 'S'
    else if fUnidades > 0 then
      Result := 'E'
    else
      Result := DeducirTipoMov(sTipo, fUnidades, fCantidad);
  end
  else
    Result := DeducirTipoMov(sTipo, fUnidades, fCantidad);
end;

// Mapeo del tipo de documento del legacy al del destino. Los códigos que ya
// coinciden con el destino (y alimentan acumuladores de stockactual) pasan
// tal cual. Se reconocen sinónimos frecuentes. Lo desconocido se clasifica
// por dirección: entrada → 'IN' (regularización), salida → 'VE' (venta).
// HEURÍSTICA: revisar contra el catálogo real de TipoDoc del cliente.
function MapearTipoDoc(const sTipoDoc, sTipoMov: string): string;
var
  d: string;
begin
  d := UpperCase(Trim(sTipoDoc));
  if (d = 'AC') or (d = 'AV') or (d = 'TR') or (d = 'AT')
  or (d = 'IN') or (d = 'DP') or (d = 'VE') or (d = 'AE')
  or (d = 'DC') then
    Result := d
  else if d = 'RP' then
    Result := 'DC'
  else if (d = 'FC') or (d = 'FV') or (d = 'TK') or (d = 'TP') then
    Result := 'VE'
  else if (d = 'FP') or (d = 'AP') then
    Result := 'AC'
  else if (d = 'RG') or (d = 'RI') then
    Result := 'IN'
  else if sTipoMov = 'E' then
    Result := 'IN'
  else
    Result := 'VE';
end;

// =========================================================================
//  Reconstrucción de stockactual desde los movimientos activos
// =========================================================================

// Recalcula fza_articulos_stockactual a partir de TODO el histórico activo
// de movimientos. Cantidad y acumuladores por agregación; el PMP actual se
// toma del último movimiento de cada SKU (PMP legacy conservado). Dos
// sentencias set-based, sin tablas temporales, idempotentes.
procedure ReconstruirStockDesdeMovimientos(Eng: TMigEngine);
const
  // 1) Cantidad neta + acumuladores por subtipo. La clasificación replica
  //    la de PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT para que stockactual quede
  //    coherente con lo que calcularía la app.
  cAgregado =
    'INSERT INTO fza_articulos_stockactual ' +
    '  (CODIGO_ALM_STK, CODIGO_UNIDAD_STK, LOTE_STK, ' +
    '   CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF, ' +
    '   CANTIDAD_ENT_COMPRA_STK, ' +
    '   CANTIDAD_ENT_TRASPASO_STK, CANTIDAD_SAL_TRASPASO_STK, ' +
    '   CANTIDAD_ENT_DEPOSITO_STK, CANTIDAD_SAL_DEPOSITO_STK, ' +
    '   CANTIDAD_SAL_VENTA_STK, CANTIDAD_ENT_REGULAR_STK, ' +
    '   CANTIDAD_SAL_ALBVENTA_STK, CANTIDAD_ENT_ALBENTRADA_STK) ' +
    'SELECT g.alm, g.sku, '''', ' +
    '       g.cant, 0, 0, NOW(), ' +
    '       g.ent_compra, ' +
    '       g.ent_traspaso, g.sal_traspaso, ' +
    '       g.ent_deposito, g.sal_deposito, ' +
    '       g.sal_venta, g.ent_regular, ' +
    '       g.sal_albventa, g.ent_albentrada ' +
    'FROM ( ' +
    '   SELECT CODIGO_ALM_MOV AS alm, CODIGO_UNIDAD_MOV AS sku, ' +
    '     SUM(IF(TIPO_MOV=''E'', CANTIDAD_MOV, -CANTIDAD_MOV)) AS cant, ' +
    '     SUM(IF(TIPO_DOC_MOV=''AC'' AND TIPO_MOV=''E'', ' +
    '            CANTIDAD_MOV, 0)) AS ent_compra, ' +
    '     SUM(IF(TIPO_DOC_MOV IN (''TR'',''AT'') AND TIPO_MOV=''E'', ' +
    '            CANTIDAD_MOV, 0)) AS ent_traspaso, ' +
    '     SUM(IF(TIPO_DOC_MOV IN (''TR'',''AT'') AND TIPO_MOV=''S'', ' +
    '            CANTIDAD_MOV, 0)) AS sal_traspaso, ' +
    '     SUM(IF(TIPO_DOC_MOV=''DP'' AND TIPO_MOV=''E'', ' +
    '            CANTIDAD_MOV, 0)) AS ent_deposito, ' +
    '     SUM(IF(TIPO_DOC_MOV=''DP'' AND TIPO_MOV=''S'', ' +
    '            CANTIDAD_MOV, 0)) AS sal_deposito, ' +
    '     SUM(IF(TIPO_DOC_MOV=''VE'' AND TIPO_MOV=''S'', ' +
    '            CANTIDAD_MOV, 0)) AS sal_venta, ' +
    '     SUM(IF(TIPO_DOC_MOV=''IN'' AND TIPO_MOV=''E'', ' +
    '            CANTIDAD_MOV, 0)) AS ent_regular, ' +
    '     SUM(IF(TIPO_DOC_MOV=''AV'' AND TIPO_MOV=''S'', ' +
    '            CANTIDAD_MOV, 0)) AS sal_albventa, ' +
    '     SUM(IF(TIPO_DOC_MOV=''AE'' AND TIPO_MOV=''E'', ' +
    '            CANTIDAD_MOV, 0)) AS ent_albentrada ' +
    '   FROM fza_movimientos_almacen ' +
    '   WHERE ESACTIVO_MOV=''S'' ' +
    '   GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV) g ' +
    'ON DUPLICATE KEY UPDATE ' +
    '   CANTIDAD_STK = VALUES(CANTIDAD_STK), ' +
    '   CANTIDAD_ENT_COMPRA_STK   = VALUES(CANTIDAD_ENT_COMPRA_STK), ' +
    '   CANTIDAD_ENT_TRASPASO_STK = VALUES(CANTIDAD_ENT_TRASPASO_STK), ' +
    '   CANTIDAD_SAL_TRASPASO_STK = VALUES(CANTIDAD_SAL_TRASPASO_STK), ' +
    '   CANTIDAD_ENT_DEPOSITO_STK = VALUES(CANTIDAD_ENT_DEPOSITO_STK), ' +
    '   CANTIDAD_SAL_DEPOSITO_STK = VALUES(CANTIDAD_SAL_DEPOSITO_STK), ' +
    '   CANTIDAD_SAL_VENTA_STK    = VALUES(CANTIDAD_SAL_VENTA_STK), ' +
    '   CANTIDAD_ENT_REGULAR_STK  = VALUES(CANTIDAD_ENT_REGULAR_STK), ' +
    '   CANTIDAD_SAL_ALBVENTA_STK = VALUES(CANTIDAD_SAL_ALBVENTA_STK), ' +
    '   CANTIDAD_ENT_ALBENTRADA_STK = VALUES(CANTIDAD_ENT_ALBENTRADA_STK), ' +
    '   INSTANTE_MODIF = NOW()';
  // 2) PMP actual = PMP del ULTIMO movimiento del SKU por NUMERO_MOV (mismo
  //    orden cronológico que el cálculo rodante). NUMERO_MOV ('MH'+10 díg.)
  //    es de ancho fijo, así que MAX() ya da el último. VALOR_TOTAL=cant*PMP.
  cPmpUltimo =
    'UPDATE fza_articulos_stockactual s ' +
    'JOIN ( ' +
    '   SELECT x.CODIGO_ALM_MOV AS alm, x.CODIGO_UNIDAD_MOV AS sku, ' +
    '          x.PRECIO_MEDIO_MOV AS pmp ' +
    '   FROM fza_movimientos_almacen x ' +
    '   JOIN ( ' +
    '       SELECT CODIGO_ALM_MOV AS alm, CODIGO_UNIDAD_MOV AS sku, ' +
    '              MAX(NUMERO_MOV) AS clave ' +
    '       FROM fza_movimientos_almacen ' +
    '       WHERE ESACTIVO_MOV=''S'' ' +
    '       GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV) mx ' +
    '     ON mx.alm = x.CODIGO_ALM_MOV AND mx.sku = x.CODIGO_UNIDAD_MOV ' +
    '    AND x.NUMERO_MOV = mx.clave ' +
    '   WHERE x.ESACTIVO_MOV=''S'') last ' +
    '  ON last.alm = s.CODIGO_ALM_STK AND last.sku = s.CODIGO_UNIDAD_STK ' +
    'SET s.PRECIO_MEDIO_STK = last.pmp, ' +
    '    s.VALOR_TOTAL_STK  = IF(s.CANTIDAD_STK > 0, ' +
    '                            s.CANTIDAD_STK * last.pmp, 0), ' +
    '    s.INSTANTE_MODIF   = NOW()';
begin
  // Dos sentencias set-based sobre TODO el histórico activo (1,6M+ filas):
  // pueden tardar. Logueamos cada fase para que se vea el avance aunque la
  // barra de filas ya esté al 100%.
  Eng.Log('  stockactual 1/2: agregando cantidades y acumuladores ' +
          'por SKU/almacen...');
  EjecutarSQL(Eng, cAgregado);
  Eng.Log('  stockactual 2/2: fijando PMP del ultimo movimiento de ' +
          'cada SKU...');
  EjecutarSQL(Eng, cPmpUltimo);
  Eng.Log('  stockactual reconstruido (cantidad + acumuladores + PMP).');
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarMovimientos(Eng: TMigEngine; var Stats: TMigStats);
const
  // Resolvemos el slot de color (Descripcion canónica o código legacy) con
  // el mismo CASE que SKUs/Inventarios, y la abreviatura de almacén origen
  // y contra-almacén (destino del traspaso). Importamos TODOS los
  // movimientos, incluidos los anulados (Invalido='S'): el legacy a veces
  // anula una pata del traspaso y excluirla descuadraba el stock.
  cSelectSrc =
    // PMP rodante por almacen alimentado por los precios reales de los
    // albaranes de entrada (ocalbproarp.PrecioSIva, sin IVA). Dos CTEs:
    //  - cte_alblin: precio de la LINEA de albaran (por documento+sku), para
    //    poner el coste exacto a cada entrada de albaran.
    //  - cte_alb1: precio del PRIMER albaran de cada sku (semilla para los
    //    movimientos anteriores al primer albaran).
    'WITH cte_alblin AS ( ' +
    '  SELECT Empresa, Ejercicio, Serie, NroAlbaran, ' +
    '         Articulo, Color, Talla, AVG(PrecioSIva) AS Precio ' +
    '  FROM dbo.ocalbproarp ' +
    '  WHERE ISNULL(PrecioSIva, 0) > 0 ' +
    '  GROUP BY Empresa, Ejercicio, Serie, NroAlbaran, ' +
    '           Articulo, Color, Talla ' +
    '), ' +
    'cte_alb1 AS ( ' +
    '  SELECT alp.Articulo, alp.Color, alp.Talla, alp.PrecioSIva, ' +
    '         ROW_NUMBER() OVER ( ' +
    '           PARTITION BY alp.Articulo, alp.Color, alp.Talla ' +
    '           ORDER BY cab.Fecha ASC, alp.NroAlbaran ASC) AS rn ' +
    '  FROM dbo.ocalbproarp alp ' +
    '  INNER JOIN dbo.ocalbpro cab ' +
    '          ON cab.Empresa    = alp.Empresa ' +
    '         AND cab.Ejercicio  = alp.Ejercicio ' +
    '         AND cab.Serie      = alp.Serie ' +
    '         AND cab.NroAlbaran = alp.NroAlbaran ' +
    '  WHERE ISNULL(alp.PrecioSIva, 0) > 0 ' +
    '), ' +
    // Mapa (documento de caja) -> Operacion: recupera la Operacion de occaj
    // por la identidad del documento (Empresa, Caja, TipoDoc, Ejercicio,
    // Serie, NroDoc). Se agrega una sola vez y MIN garantiza una fila por
    // clave, asi el LEFT JOIN no multiplica filas de movimiento.
    'cte_op AS ( ' +
    '  SELECT Empresa, Caja, TipoDoc, Ejercicio, Serie, NroDoc, ' +
    '         MIN(Operacion) AS Operacion ' +
    '  FROM dbo.occaj ' +
    '  GROUP BY Empresa, Caja, TipoDoc, Ejercicio, Serie, NroDoc ' +
    ') ' +
    'SELECT m.Numero, m.Empresa, m.Almacen, ' +
    '       ISNULL(alm.Abreviatura, '''')    AS AbreviaturaAlm, ' +
    '       ISNULL(almdes.Abreviatura, '''') AS AbreviaturaAlmDes, ' +
    '       m.EmpresaDes, m.AlmacenDes, m.AlmacenOri, ' +
    '       m.Articulo, m.Color, m.Talla, ' +
    '       ISNULL(m.Cantidad, 0)      AS Cantidad, ' +
    '       ISNULL(m.UnidadesStock, 0) AS UnidadesStock, ' +
    '       ISNULL(m.Tipo, '''')    AS Tipo, ' +
    '       ISNULL(m.TipoMov, '''') AS TipoMov, ' +
    '       ISNULL(m.TipoDoc, '''') AS TipoDoc, ' +
    '       ISNULL(m.PrecioMedioSIva, 0) AS PrecioMedioSIva, ' +
    '       m.FechaOpe, m.Fecha, ' +
    '       ISNULL(m.Serie, '''') AS Serie, m.NroDoc, ' +
    '       ISNULL(m.Cliente, '''') AS Cliente, ' +
    '       ISNULL(m.NroCaja, 0) AS NroCaja, opc.Operacion AS OpeCaja, ' +
    '       CASE ' +
    '         WHEN m.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(m.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(m.Color))) ' +
    '         WHEN c.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(c.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(c.Descripcion))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor, ' +
    '       ISNULL(alb.Precio, 0)      AS PrecioAlbaranLinea, ' +
    '       ISNULL(seed.PrecioSIva, 0) AS SeedPrecio, ' +
    '       ISNULL(almori.Abreviatura, '''') AS AbreviaturaAlmOri, ' +
    '       ISNULL(art.DescripcionLarga, ' +
    '              ISNULL(art.DescripcionCorta, '''')) AS DescArt ' +
    'FROM dbo.ocmovarp m ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = m.Empresa ' +
    '                       AND alm.Almacen = m.Almacen ' +
    'LEFT JOIN dbo.ocalm almdes ON almdes.Empresa = m.EmpresaDes ' +
    '                          AND almdes.Almacen = m.AlmacenDes ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = m.Articulo ' +
    '                         AND ac.Color    = m.Color ' +
    'LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    'LEFT JOIN dbo.ocartp art ON art.Articulo = m.Articulo ' +
    'LEFT JOIN cte_alblin alb ON alb.Empresa = m.Empresa ' +
    '                        AND alb.Ejercicio = m.Ejercicio ' +
    '                        AND alb.Serie = m.Serie ' +
    '                        AND alb.NroAlbaran = m.NroDoc ' +
    '                        AND alb.Articulo = m.Articulo ' +
    '                        AND alb.Color = m.Color ' +
    '                        AND alb.Talla = m.Talla ' +
    'LEFT JOIN cte_alb1 seed ON seed.Articulo = m.Articulo ' +
    '                       AND seed.Color = m.Color ' +
    '                       AND seed.Talla = m.Talla AND seed.rn = 1 ' +
    'LEFT JOIN dbo.ocalm almori ON almori.Empresa = m.Empresa ' +
    '                          AND almori.Almacen = m.AlmacenOri ' +
    'LEFT JOIN cte_op opc ON opc.Empresa = m.Empresa ' +
    '                    AND opc.Caja = m.NroCaja ' +
    '                    AND opc.TipoDoc = m.TipoDoc ' +
    '                    AND opc.Ejercicio = m.Ejercicio ' +
    '                    AND opc.Serie = m.Serie ' +
    '                    AND opc.NroDoc = m.NroDoc ' +
    'WHERE LTRIM(RTRIM(m.Articulo)) <> '''' ' +
    'ORDER BY m.Empresa, m.Articulo, DescColor, m.Talla, m.Numero';
  cCols =
    'NUMERO_MOV, TIPO_DOC_MOV, SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV, ' +
    'CODIGO_EMP_MOV, CODIGO_ALM_MOV, FECHA_MOV, CODIGO_ART_MOV, ' +
    'CODIGO_UNIDAD_MOV, DESCRIPCION_ARTICULO_MOV, TIPO_MOV, CANTIDAD_MOV, ' +
    'PRECIO_COSTE_UNITARIO_MOV, TOTAL_COSTE_MOV, PRECIO_MEDIO_MOV, ' +
    'CODIGO_ALM_CONTRA_MOV, CODIGO_CLI_MOV, ESACTIVO_MOV, ' +
    'CODIGO_ALM_DOC_MOV, CODIGO_CAJA_DOC_MOV, NUMERO_OPERACION_DOC_MOV, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                           TUniQuery;
  bulk:                           TBulkInsert;
  fs:                             TFormatSettings;
  sAhora, sUser:                  string;
  sArt, sDescColor, sDesc:        string;
  sCodUnidad, sEmp, sAlm:         string;
  sTipoRaw, sTipoMov, sTipoDoc:   string;
  sSerie, sNroDoc, sCliente:      string;
  sContra, sFechaSql, sFila:      string;
  sCajaDoc, sNumOpDoc:            string;
  fUnidades, fCantidad, fEfect:   Double;
  fCantMov, fCoste, fPmp, fTotal: Double;
  fPmpAlm, fSeed, fPrecAlb:       Double;
  fStkAlm, fValAlm, fStkOri, fValOri: Double;
  iAlmDes:                        Integer;
  sSkuKey, sSkuActual, sAlmOri:   string;
  oStock, oValor:                 TDictionary<string, Double>;
begin
  fs := TFormatSettings.Create('en-US');
  oStock := TDictionary<string, Double>.Create;
  oValor := TDictionary<string, Double>.Create;
  sSkuActual := '';
  // Reimport limpio: esto es un volcado COMPLETO del historico y el bulk usa
  // INSERT IGNORE (no actualiza filas ya existentes). Antes de recargar
  // borramos lo que crea ESTA migracion (prefijo 'MH'), para que los cambios
  // de cada pasada (sentido E/S, enlace de caja...) se apliquen de verdad sin
  // tener que vaciar la tabla a mano. No toca los 'MV' que genere la app.
  Eng.Log('  movimientos: limpiando volcado historico anterior (MH*)...');
  EjecutarSQL(Eng,
    'DELETE FROM fza_movimientos_almacen WHERE NUMERO_MOV LIKE ''MH%''');
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  // Streaming: ocmovarp puede tener cientos de miles de filas; no las
  // cacheamos en memoria (lectura hacia delante).
  qSrc.UniDirectional := True;
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_movimientos_almacen',
                             cCols, BATCH_SIZE);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocmovarp ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      // Chequeo de cancelación periódico (volúmenes potencialmente
      // grandes: el histórico puede tener cientos de miles de filas).
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Movimientos, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      sDesc      := Trim(qSrc.FieldByName('DescArt').AsString);
      sTipoRaw   := Trim(qSrc.FieldByName('Tipo').AsString);
      fUnidades  := qSrc.FieldByName('UnidadesStock').AsFloat;
      fCantidad  := qSrc.FieldByName('Cantidad').AsFloat;
      sTipoMov   := DeducirTipoMovDocumento(
                      qSrc.FieldByName('TipoDoc').AsString, sTipoRaw,
                      fUnidades, fCantidad);
      sTipoDoc   := MapearTipoDoc(qSrc.FieldByName('TipoDoc').AsString,
                                  sTipoMov);
      // Traspaso: el legacy marca las DOS patas igual (Tipo='E', TipoMov='SE')
      // y NO distingue el sentido en esos flags. El legacy YA trae dos filas
      // (una por almacen), asi que no hay que duplicar: basta etiquetar cada
      // una. La direccion real esta en la estructura: la pata cuyo almacen es
      // el DESTINO del traspaso es la ENTRADA; la del ORIGEN es la SALIDA. Asi
      // el origen se descuenta y el stock cuadra (antes ambas salian 'E',
      // inflaban el origen y el ticket de traspaso -filtra TIPO_MOV='S'-
      // quedaba vacio). El signo de Cantidad (+entra/-sale) corrobora;
      // UnidadesStock no vale (viene 0 en la salida).
      if (UpperCase(Trim(qSrc.FieldByName('TipoMov').AsString)) = 'SE')
      or (sTipoDoc = 'TR') or (sTipoDoc = 'AT') then
      begin
        iAlmDes := qSrc.FieldByName('AlmacenDes').AsInteger;
        if iAlmDes > 0 then
        begin
          if qSrc.FieldByName('Almacen').AsInteger = iAlmDes then
            sTipoMov := 'E'
          else
            sTipoMov := 'S';
        end;
      end;
      // Cantidad que afecta a stock: la Cantidad del documento es la fuente
      // fiable (unidades reales del albaran/ticket). UnidadesStock del legacy
      // viene inconsistente (a veces 2-3 en ventas de 1 ud, o 1 en entradas
      // de 2 uds), asi que solo la usamos de respaldo si Cantidad es 0.
      // Guardamos el valor absoluto (la direccion la marca TIPO_MOV).
      fEfect := fCantidad;
      if fEfect = 0 then
        fEfect := fUnidades;
      fCantMov := Abs(fEfect);
      // Movimiento sin impacto de stock (0 unidades): no aporta nada al
      // histórico de stock — lo saltamos para no ensuciar.
      if fCantMov = 0 then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
      end
      else
      begin
        sEmp := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
        sAlm := UpperCase(Trim(
                  qSrc.FieldByName('AbreviaturaAlm').AsString));
        if sAlm = '' then
          sAlm := IntToStr(qSrc.FieldByName('Almacen').AsInteger);
        sCodUnidad := ConstruirCodigoUnidad(sArt, sDescColor,
                        Trim(qSrc.FieldByName('Talla').AsString));
        // Contra-almacén solo tiene sentido en traspasos.
        sContra := '';
        if (sTipoDoc = 'TR') or (sTipoDoc = 'AT') then
        begin
          sContra := UpperCase(Trim(
                       qSrc.FieldByName('AbreviaturaAlmDes').AsString));
          if sContra = '' then
          begin
            iAlmDes := qSrc.FieldByName('AlmacenDes').AsInteger;
            if iAlmDes > 0 then
              sContra := IntToStr(iAlmDes);
          end;
        end;
        // === PMP rodante por almacen (coste SIN IVA) ===
        // Al cambiar de SKU reiniciamos el estado por almacen y leemos la
        // semilla (precio del PRIMER albaran del SKU) para valorar los
        // movimientos anteriores al primer albaran.
        sSkuKey := sEmp + '|' + sArt + '|' + sDescColor + '|' +
                   Trim(qSrc.FieldByName('Talla').AsString);
        if sSkuKey <> sSkuActual then
        begin
          oStock.Clear;
          oValor.Clear;
          sSkuActual := sSkuKey;
          fSeed := qSrc.FieldByName('SeedPrecio').AsFloat;
        end;
        // PMP vigente del almacen del movimiento (semilla si aun sin stock).
        if not oStock.TryGetValue(sAlm, fStkAlm) then
          fStkAlm := 0;
        if not oValor.TryGetValue(sAlm, fValAlm) then
          fValAlm := 0;
        if fStkAlm > 0 then
          fPmpAlm := fValAlm / fStkAlm
        else
          fPmpAlm := fSeed;
        // Coste de la fila segun el tipo de movimiento:
        fPrecAlb := qSrc.FieldByName('PrecioAlbaranLinea').AsFloat;
        if (sTipoMov = 'E') and (fPrecAlb > 0)
        and (sTipoDoc <> 'TR') and (sTipoDoc <> 'AT') then
          // Entrada que casa con una linea de albaran: su precio real.
          fCoste := fPrecAlb
        else if (sTipoMov = 'E')
        and ((sTipoDoc = 'TR') or (sTipoDoc = 'AT')) then
        begin
          // Entrada de traspaso: arrastra el PMP del almacen ORIGEN.
          sAlmOri := UpperCase(Trim(
                       qSrc.FieldByName('AbreviaturaAlmOri').AsString));
          if sAlmOri = '' then
            sAlmOri := IntToStr(qSrc.FieldByName('AlmacenOri').AsInteger);
          if not oStock.TryGetValue(sAlmOri, fStkOri) then
            fStkOri := 0;
          if not oValor.TryGetValue(sAlmOri, fValOri) then
            fValOri := 0;
          if fStkOri > 0 then
            fCoste := fValOri / fStkOri
          else
            fCoste := fSeed;
        end
        else
          // Regularizaciones de entrada y TODAS las salidas: PMP vigente.
          fCoste := fPmpAlm;
        // Actualizamos stock y valor del almacen del movimiento.
        if sTipoMov = 'E' then
        begin
          fValAlm := fValAlm + fCantMov * fCoste;
          fStkAlm := fStkAlm + fCantMov;
        end
        else
        begin
          fValAlm := fValAlm - fCantMov * fCoste;
          fStkAlm := fStkAlm - fCantMov;
        end;
        oStock.AddOrSetValue(sAlm, fStkAlm);
        oValor.AddOrSetValue(sAlm, fValAlm);
        // PMP tras el movimiento (si el stock queda <=0, mantenemos el ult.).
        if fStkAlm > 0 then
          fPmp := fValAlm / fStkAlm
        else
          fPmp := fPmpAlm;
        fTotal := fCantMov * fCoste;
        // FECHA_MOV: primera fecha REAL entre Fecha y FechaOpe. El legacy
        // suele traer FechaOpe a 1900-01-01 (cero de SQL Server) en los
        // movimientos, y eso IsNull no lo detecta: antes FECHA_MOV salía
        // siempre 01/01/1900. Preferimos Fecha (fecha del documento) y
        // caemos a FechaOpe; si ninguna es válida, NULL.
        sFechaSql := 'NULL';
        if FechaReal(qSrc.FieldByName('Fecha').AsDateTime) then
          sFechaSql := DateTimeASQL(qSrc.FieldByName('Fecha').AsDateTime)
        else if FechaReal(qSrc.FieldByName('FechaOpe').AsDateTime) then
          sFechaSql := DateTimeASQL(
                         qSrc.FieldByName('FechaOpe').AsDateTime);
        sSerie   := Trim(qSrc.FieldByName('Serie').AsString);
        sNroDoc  := Trim(qSrc.FieldByName('NroDoc').AsString);
        sCliente := Trim(qSrc.FieldByName('Cliente').AsString);
        // Enlace con la operacion de caja que genero el movimiento. Si el
        // documento casa con una operacion de occaj rellenamos caja y numero
        // de operacion (8 digitos, igual que NUMERO_OPERACION_OPCAJA); si no,
        // el movimiento no es de caja y queda sin enlace (NULL).
        sCajaDoc  := 'NULL';
        sNumOpDoc := 'NULL';
        if not qSrc.FieldByName('OpeCaja').IsNull then
        begin
          sCajaDoc  := ValorOrNull(
                         IntToStr(qSrc.FieldByName('NroCaja').AsInteger));
          sNumOpDoc := ValorOrNull(Format('%.8d',
                         [qSrc.FieldByName('OpeCaja').AsInteger]));
        end;
        // 26 columnas en cCols. ESACTIVO_MOV es literal 'S'.
        sFila := Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, ''S'', %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(PREFIJO_NUM + Format('%.10d',
             [qSrc.FieldByName('Numero').AsInteger])),   // NUMERO_MOV
           ValorOrNull(sTipoDoc),                        // TIPO_DOC_MOV
           Txt(sSerie),                                  // SERIE_DOC_MOV
           Txt(sNroDoc),                                 // NUMERO_DOC_MOV
           Txt('0001'),                                  // LINEA_MOV
           ValorOrNull(sEmp),                            // CODIGO_EMP_MOV
           ValorOrNull(sAlm),                            // CODIGO_ALM_MOV
           sFechaSql,                                    // FECHA_MOV
           ValorOrNull(sArt),                            // CODIGO_ART_MOV
           ValorOrNull(sCodUnidad),                      // CODIGO_UNIDAD_MOV
           ValorOrNull(sDesc),                           // DESCRIPCION_...
           ValorOrNull(sTipoMov),                        // TIPO_MOV
           FloatToStr(fCantMov, fs),                     // CANTIDAD_MOV
           FloatToStr(fCoste, fs),                       // PRECIO_COSTE_...
           FloatToStr(fTotal, fs),                       // TOTAL_COSTE_MOV
           FloatToStr(fPmp, fs),                         // PRECIO_MEDIO_MOV
           ValorOrNull(sContra),                         // CODIGO_ALM_CONTRA
           ValorOrNull(sCliente),                        // CODIGO_CLI_MOV
                                                         // 'S' ESACTIVO_MOV
           ValorOrNull(sAlm),                            // CODIGO_ALM_DOC_MOV
           sCajaDoc,                                     // CODIGO_CAJA_DOC_MOV
           sNumOpDoc,                                    // NUMERO_OPERACION_DOC
           sAhora, sAhora,                               // INSTANTE_ALTA/MODIF
           sUser, sUser]);                               // USUARIO_ALTA/MODIF
        try
          bulk.Add(sFila);
          Inc(Stats.Insertadas);
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('movimiento', sCodUnidad, E.Message,
              Format('emp=%s alm=%s num=%d',
                [sEmp, sAlm, qSrc.FieldByName('Numero').AsInteger]),
              'el movimiento requiere que el SKU y el almacen ya esten ' +
              'migrados — corre antes Almacenes y SKUs');
            raise;
          end;
        end;
        qSrc.Next;
      end;
    end;
    bulk.FlushPendiente;
    // Stock activo: reconstruimos stockactual desde el histórico volcado.
    if not Eng.IsCancelado then
      ReconstruirStockDesdeMovimientos(Eng);
  finally
    bulk.Free;
    qSrc.Free;
    oStock.Free;
    oValor.Free;
  end;
end;

end.
