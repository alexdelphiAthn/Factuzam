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
{    Estrategia de coste (decisión del usuario): se CONSERVA el PMP del        }
{    propio movimiento origen, con salvaguarda contra los albaranes de         }
{    entrada.                                                                   }
{      ocmovarp.PrecioMedio → PRECIO_MEDIO_MOV                                 }
{      ocmovarp.PrecioCoste → PRECIO_COSTE_UNITARIO_MOV (fallback PrecioMedio) }
{    SALVAGUARDA 15%: si el coste del movimiento se desvía MÁS DE UN 15% del   }
{    precio real del ÚLTIMO albarán de entrada del artículo (ocalbproarp,      }
{    PrecioSIva sin IVA), se considera poco fiable el dato del legacy y se     }
{    toma el coste del albarán para esa fila (coste y PMP). Si no hay albarán  }
{    de referencia (precio > 0) se conserva el dato del movimiento.           }
{                                                                              }
{    Impacto en stock (decisión del usuario): los movimientos se migran        }
{    ACTIVOS (ESACTIVO_MOV='S') y RECALCULAN el stock. Tras el volcado se      }
{    reconstruye `fza_articulos_stockactual` por agregación de los            }
{    movimientos activos:                                                      }
{      CANTIDAD_STK        = Σ(entradas) − Σ(salidas)                          }
{      acumuladores _STK   = Σ por subtipo (compra, traspaso, venta, ...)     }
{      PRECIO_MEDIO_STK    = PMP del ÚLTIMO movimiento del SKU (legacy)        }
{      VALOR_TOTAL_STK     = CANTIDAD_STK * PRECIO_MEDIO_STK                    }
{    Importante: NO se usa SP_RECALCULAR_PMP_LOTE_ALMACEN porque ese SP        }
{    DERIVA el PMP del coste de las entradas y SOBRESCRIBE PRECIO_MEDIO_MOV    }
{    fila a fila — destruiría el PMP que aquí queremos conservar. Por eso la   }
{    reconstrucción de stock es propia y respeta el PMP del legacy.            }
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
{        de UnidadesStock; si no, signo de Cantidad.                           }
{      - TIPO_DOC_MOV: ocmovarp.TipoDoc pasa tal cual cuando ya coincide con   }
{        el destino (AC/AV/TR/AT/IN/DP/VE/AE); sinónimos frecuentes mapeados;  }
{        desconocido se clasifica por dirección (E→IN, S→VE).                  }
{                                                                              }
{    Idempotente: PK NUMERO_MOV + INSERT IGNORE en el bulk. La reconstrucción  }
{    de stock es determinista (recalcula desde cero por UPSERT), re-ejecutable.}
{******************************************************************************}
unit inLibMigMovimientos;

interface

uses
  UMigEngine;

procedure MigrarMovimientos(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
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

// Dirección del movimiento. Preferimos el flag Tipo del origen cuando es
// explícito ('E'/'S'); si no, el signo de las unidades de stock; como
// último recurso, el signo de Cantidad. Por defecto entrada.
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
  or (d = 'IN') or (d = 'DP') or (d = 'VE') or (d = 'AE') then
    Result := d
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
  // 2) PMP actual = PMP del último movimiento del SKU (orden por fecha y,
  //    a igualdad, por NUMERO_MOV). La clave compuesta evita funciones
  //    ventana para máxima compatibilidad. VALOR_TOTAL = cantidad * PMP.
  cPmpUltimo =
    'UPDATE fza_articulos_stockactual s ' +
    'JOIN ( ' +
    '   SELECT x.CODIGO_ALM_MOV AS alm, x.CODIGO_UNIDAD_MOV AS sku, ' +
    '          x.PRECIO_MEDIO_MOV AS pmp ' +
    '   FROM fza_movimientos_almacen x ' +
    '   JOIN ( ' +
    '       SELECT CODIGO_ALM_MOV AS alm, CODIGO_UNIDAD_MOV AS sku, ' +
    '              MAX(CONCAT( ' +
    '                 DATE_FORMAT(COALESCE(FECHA_MOV, ''1900-01-01''), ' +
    '                             ''%Y%m%d%H%i%s''), ' +
    '                 LPAD(NUMERO_MOV, 20, ''0''))) AS clave ' +
    '       FROM fza_movimientos_almacen ' +
    '       WHERE ESACTIVO_MOV=''S'' ' +
    '       GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV) mx ' +
    '     ON mx.alm = x.CODIGO_ALM_MOV AND mx.sku = x.CODIGO_UNIDAD_MOV ' +
    '    AND CONCAT( ' +
    '          DATE_FORMAT(COALESCE(x.FECHA_MOV, ''1900-01-01''), ' +
    '                      ''%Y%m%d%H%i%s''), ' +
    '          LPAD(x.NUMERO_MOV, 20, ''0'')) = mx.clave ' +
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
  // y contra-almacén (destino del traspaso). Excluimos movimientos
  // anulados (Invalido='S').
  cSelectSrc =
    // Precomputamos el coste del ÚLTIMO albarán de entrada por artículo
    // (PrecioSIva, sin IVA) con ROW_NUMBER(): se calcula una sola vez y
    // luego se cruza por LEFT JOIN. Mismo patrón que
    // inLibMigArticulosProveedores. Sirve de referencia para la
    // salvaguarda del 15%.
    'WITH cte_alb AS ( ' +
    '  SELECT alp.Articulo, alp.PrecioSIva, ' +
    '         ROW_NUMBER() OVER ( ' +
    '           PARTITION BY alp.Articulo ' +
    '           ORDER BY cab.Fecha DESC) AS rn ' +
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
    '       m.EmpresaDes, m.AlmacenDes, ' +
    '       m.Articulo, m.Color, m.Talla, ' +
    '       ISNULL(m.Cantidad, 0)      AS Cantidad, ' +
    '       ISNULL(m.UnidadesStock, 0) AS UnidadesStock, ' +
    '       ISNULL(m.Tipo, '''')    AS Tipo, ' +
    '       ISNULL(m.TipoDoc, '''') AS TipoDoc, ' +
    '       ISNULL(m.PrecioMedioSIva, 0) AS PrecioMedioSIva, ' +
    '       m.FechaOpe, m.Fecha, ' +
    '       ISNULL(m.Serie, '''') AS Serie, m.NroDoc, ' +
    '       ISNULL(m.Cliente, '''') AS Cliente, ' +
    '       ISNULL(m.NroCaja, 0) AS NroCaja, opc.Operacion AS OpeCaja, ' +
    '       CASE ' +
    '         WHEN c.Descripcion IS NULL ' +
    '           OR LTRIM(RTRIM(c.Descripcion)) = '''' ' +
    '           OR UPPER(LTRIM(RTRIM(c.Descripcion))) = ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(m.Color))) ' +
    '         ELSE UPPER(LTRIM(RTRIM(c.Descripcion))) ' +
    '       END AS DescColor, ' +
    '       ISNULL(ulc.PrecioSIva, 0) AS PrecioUltAlbaran, ' +
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
    'LEFT JOIN cte_alb ulc ON ulc.Articulo = m.Articulo AND ulc.rn = 1 ' +
    'LEFT JOIN cte_op opc ON opc.Empresa = m.Empresa ' +
    '                    AND opc.Caja = m.NroCaja ' +
    '                    AND opc.TipoDoc = m.TipoDoc ' +
    '                    AND opc.Ejercicio = m.Ejercicio ' +
    '                    AND opc.Serie = m.Serie ' +
    '                    AND opc.NroDoc = m.NroDoc ' +
    'WHERE LTRIM(RTRIM(m.Articulo)) <> '''' ' +
    '  AND ISNULL(m.Invalido, ''N'') <> ''S'' ' +
    'ORDER BY m.Empresa, m.Almacen, m.Articulo, m.Color, m.Talla, ' +
    '         m.FechaOpe, m.Numero';
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
  fRefAlb:                        Double;
  iAlmDes, iCorregidos:           Integer;
begin
  fs := TFormatSettings.Create('en-US');
  iCorregidos := 0;
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
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND ISNULL(Invalido, ''N'') <> ''S'''));
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
      sTipoMov   := DeducirTipoMov(sTipoRaw, fUnidades, fCantidad);
      sTipoDoc   := MapearTipoDoc(qSrc.FieldByName('TipoDoc').AsString,
                                  sTipoMov);
      // Cantidad que afecta a stock: preferimos UnidadesStock; si es 0,
      // caemos a Cantidad. Guardamos el valor absoluto (la dirección la
      // marca TIPO_MOV).
      fEfect := fUnidades;
      if fEfect = 0 then
        fEfect := fCantidad;
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
        // PMP/coste SIN IVA: usamos PrecioMedioSIva (no PrecioMedio, que
        // en el legacy viene CON IVA) para cuadrar con las columnas de
        // coste de Factuzam y con ocalbproarp.PrecioSIva. El coste por
        // fila arranca igual al PMP conservado.
        fPmp   := qSrc.FieldByName('PrecioMedioSIva').AsFloat;
        fCoste := fPmp;
        // Salvaguarda 15%: si el PMP (sin IVA) se aleja más de un 15% del
        // precio real (sin IVA) del último albarán de entrada, damos por
        // poco fiable el dato del legacy y tomamos el del albarán (coste y
        // PMP). Cubre además el caso de PMP 0 con albarán conocido.
        fRefAlb := qSrc.FieldByName('PrecioUltAlbaran').AsFloat;
        if (fRefAlb > 0) and (Abs(fPmp - fRefAlb) > 0.15 * fRefAlb) then
        begin
          fPmp   := fRefAlb;
          fCoste := fRefAlb;
          Inc(iCorregidos);
        end;
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
    if iCorregidos > 0 then
      Eng.Log('  coste tomado del ultimo albaran (desvio >15%%) en %d ' +
              'movimientos', [iCorregidos]);
    // Stock activo: reconstruimos stockactual desde el histórico volcado.
    if not Eng.IsCancelado then
      ReconstruirStockDesdeMovimientos(Eng);
  finally
    bulk.Free;
    qSrc.Free;
  end;
end;

end.
