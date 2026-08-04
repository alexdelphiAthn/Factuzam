{******************************************************************************}
{  Módulo: UniDataFacturacionOperacionesPeriodoSql                            }
{  Tipo: Catálogo SQL                                                         }
{  Descripción: SQL de facturación periódica de operaciones TPV.              }
{******************************************************************************}
unit UniDataFacturacionOperacionesPeriodoSql;

interface

function SqlCrearTemporalFacturacionPeriodo: string;
function SqlCargarVentasPendientesPeriodo: string;
function SqlCargarTraspasosPendientesPeriodo: string;
function SqlInsertarCabeceraFacturacionPeriodo: string;
function SqlInsertarOperacionesFacturacionPeriodo: string;
function SqlInsertarLineasVentaPeriodo: string;
function SqlInsertarLineasVentaRetiradasPeriodo: string;
function SqlInsertarLineasTraspasoPeriodo: string;
function SqlInsertarLineasTraspasoRetiradasPeriodo: string;
function SqlActualizarTotalesFacturacionPeriodo: string;
function SqlInsertarFacturaTraspasoPeriodo: string;
function SqlInsertarLineasFacturaTraspasoPeriodo: string;
function SqlConsultarInformeFacturacionPeriodo: string;

implementation

uses
  System.SysUtils, System.Classes;

function UnirSql(const ALineas: array of string): string;
var
  i: Integer;
  oLineas: TStringList;
begin
  oLineas := TStringList.Create;
  try
    for i := Low(ALineas) to High(ALineas) do
    begin
      oLineas.Add(ALineas[i]);
    end;
    Result := oLineas.Text;
  finally
    FreeAndNil(oLineas);
  end;
end;

function SqlCrearTemporalFacturacionPeriodo: string;
begin
  Result := UnirSql([
    'CREATE TEMPORARY TABLE IF NOT EXISTS tmp_facturacion_periodo (',
    '  ID_OPCAJA bigint(20) NOT NULL,',
    '  TIPO_FACTURACION varchar(2) NOT NULL,',
    '  CODIGO_EMP_DESTINO varchar(10) NOT NULL DEFAULT '''',',
    '  HUELLA_ORIGEN char(64) NOT NULL,',
    '  ID_CFOP_ANTERIOR bigint(20) NOT NULL DEFAULT 0,',
    '  ID_CFPER_ANTERIOR bigint(20) NOT NULL DEFAULT 0,',
    '  INSTANTE_OPERACION datetime NOT NULL,',
    '  IMPORTE_ORIGEN decimal(19,6) NOT NULL DEFAULT 0,',
    '  PRIMARY KEY (ID_OPCAJA, TIPO_FACTURACION)',
    ') ENGINE=InnoDB'
  ]);
end;

function SqlCargarVentasPendientesPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO tmp_facturacion_periodo (',
    '  ID_OPCAJA, TIPO_FACTURACION, CODIGO_EMP_DESTINO,',
    '  HUELLA_ORIGEN, ID_CFOP_ANTERIOR, ID_CFPER_ANTERIOR,',
    '  INSTANTE_OPERACION, IMPORTE_ORIGEN)',
    'SELECT x.ID_OPCAJA, ''VE'', '''', x.HUELLA_ORIGEN,',
    '       COALESCE(a.ID_CFOP, 0), COALESCE(a.ID_CFPER_CFOP, 0),',
    '       x.FECHA_OPERACION_OPCAJA, x.IMPORTE_TOTAL_OPCAJA',
    '  FROM (',
    '    SELECT o.ID_OPCAJA, o.FECHA_OPERACION_OPCAJA,',
    '           o.IMPORTE_TOTAL_OPCAJA,',
    '           SHA2(CONCAT_WS(''|'', ''VE'', o.ID_OPCAJA,',
    '             DATE_FORMAT(o.FECHA_OPERACION_OPCAJA, ''%Y%m%d%H%i%s''),',
    '             o.IMPORTE_TOTAL_OPCAJA,',
    '             COALESCE((',
    '               SELECT GROUP_CONCAT(CONCAT_WS('':'',',
    '                 fl.LINEA_FACLIN, ' +
    'COALESCE(fl.CODIGO_UNIDAD_FACLIN, ''''),',
    '                 COALESCE(fl.CODIGO_ART_FACLIN, ''''),',
    '                 fl.CANTIDAD_FACLIN,',
    '                 fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN,',
    '                 fl.TOTAL_FACLIN)',
    '                 ORDER BY fl.LINEA_FACLIN SEPARATOR ''|'' )',
    '                 FROM fza_facturas_lineas fl',
    '                WHERE fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA',
    '                  AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA',
    '             ), '''')), 256) AS HUELLA_ORIGEN',
    '      FROM fza_caja_operaciones o',
    '      JOIN fza_facturas f',
    '        ON f.SERIE_FAC = o.SERIE_FAC_OPCAJA',
    '       AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA',
    '       AND f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA',
    '     WHERE o.TIPO_OPERACION_OPCAJA = ''VE''',
    '       AND o.CODIGO_EMP_OPCAJA = :EMPRESA',
    '       AND o.CODIGO_ALM_OPCAJA = :ALMACEN',
    '       AND o.CODIGO_CAJA_OPCAJA = :CAJA',
    '       AND o.FECHA_OPERACION_OPCAJA >= :DESDE',
    '       AND o.FECHA_OPERACION_OPCAJA <',
    '           DATE_ADD(:HASTA, INTERVAL 1 DAY)',
    '       AND COALESCE(TRIM(f.CODIGO_CLI_FAC), '''') = ''''',
    '       AND COALESCE(TRIM(f.RAZON_SOCIAL_CLIENTE_FAC), '''') = ''''',
    '       AND COALESCE(TRIM(f.NIF_CLIENTE_FAC), '''') = ''''',
    '       AND COALESCE(f.FASE_FAC, '''') <> ''CANCELADA''',
    '  ) x',
    '  LEFT JOIN fza_caja_facturacion_operaciones a',
    '    ON a.ID_CFOP = (',
    '      SELECT MAX(ax.ID_CFOP)',
    '        FROM fza_caja_facturacion_operaciones ax',
    '       WHERE ax.ID_OPCAJA_CFOP = x.ID_OPCAJA)',
    ' WHERE a.ID_CFOP IS NULL OR a.HUELLA_ORIGEN_CFOP <> x.HUELLA_ORIGEN'
  ]);
end;

function SqlCargarTraspasosPendientesPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO tmp_facturacion_periodo (',
    '  ID_OPCAJA, TIPO_FACTURACION, CODIGO_EMP_DESTINO,',
    '  HUELLA_ORIGEN, ID_CFOP_ANTERIOR, ID_CFPER_ANTERIOR,',
    '  INSTANTE_OPERACION, IMPORTE_ORIGEN)',
    'SELECT x.ID_OPCAJA, ''TA'', x.CODIGO_EMP_DESTINO,',
    '       x.HUELLA_ORIGEN, COALESCE(a.ID_CFOP, 0),',
    '       COALESCE(a.ID_CFPER_CFOP, 0),',
    '       x.FECHA_OPERACION_OPCAJA, x.IMPORTE_TOTAL_OPCAJA',
    '  FROM (',
    '    SELECT o.ID_OPCAJA, o.CODIGO_EMP_CONTRA_OPCAJA',
    '             AS CODIGO_EMP_DESTINO,',
    '           o.FECHA_OPERACION_OPCAJA, o.IMPORTE_TOTAL_OPCAJA,',
    '           SHA2(CONCAT_WS(''|'', ''TA'', o.ID_OPCAJA,',
    '             o.CODIGO_EMP_CONTRA_OPCAJA,',
    '             DATE_FORMAT(o.FECHA_OPERACION_OPCAJA, ''%Y%m%d%H%i%s''),',
    '             o.IMPORTE_TOTAL_OPCAJA,',
    '             COALESCE((',
    '               SELECT GROUP_CONCAT(CONCAT_WS('':'', m.NUMERO_MOV,',
    '                 m.LINEA_MOV, m.CODIGO_ART_MOV,',
    '                 m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV,',
    '                 m.PRECIO_COSTE_UNITARIO_MOV, m.TOTAL_COSTE_MOV)',
    '                 ORDER BY m.LINEA_MOV, m.NUMERO_MOV SEPARATOR ''|'')',
    '                 FROM fza_movimientos_almacen m',
    '                WHERE m.TIPO_DOC_MOV IN (''TA'', ''AT'')',
    '                  AND m.TIPO_MOV = ''S''',
    '                  AND COALESCE(m.ESACTIVO_MOV, ''S'') = ''S''',
    '                  AND m.SERIE_DOC_MOV = o.SERIE_FAC_OPCAJA',
    '                  AND m.NUMERO_DOC_MOV = o.NUMERO_FAC_OPCAJA',
    '                  AND m.CODIGO_EMP_MOV = o.CODIGO_EMP_OPCAJA',
    '                  AND m.CODIGO_ALM_MOV = o.CODIGO_ALM_OPCAJA',
    '             ), '''')), 256) AS HUELLA_ORIGEN',
    '      FROM fza_caja_operaciones o',
    '     WHERE o.TIPO_OPERACION_OPCAJA IN (''TA'', ''AT'')',
    '       AND o.CODIGO_EMP_OPCAJA = :EMPRESA',
    '       AND o.CODIGO_ALM_OPCAJA = :ALMACEN',
    '       AND o.CODIGO_CAJA_OPCAJA = :CAJA',
    '       AND o.FECHA_OPERACION_OPCAJA >= :DESDE',
    '       AND o.FECHA_OPERACION_OPCAJA <',
    '           DATE_ADD(:HASTA, INTERVAL 1 DAY)',
    '       AND COALESCE(TRIM(o.CODIGO_EMP_CONTRA_OPCAJA), '''') <> ''''',
    '       AND o.CODIGO_EMP_CONTRA_OPCAJA <> o.CODIGO_EMP_OPCAJA',
    '  ) x',
    '  LEFT JOIN fza_caja_facturacion_operaciones a',
    '    ON a.ID_CFOP = (',
    '      SELECT MAX(ax.ID_CFOP)',
    '        FROM fza_caja_facturacion_operaciones ax',
    '       WHERE ax.ID_OPCAJA_CFOP = x.ID_OPCAJA)',
    ' WHERE a.ID_CFOP IS NULL OR a.HUELLA_ORIGEN_CFOP <> x.HUELLA_ORIGEN'
  ]);
end;

function SqlInsertarCabeceraFacturacionPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturaciones_periodo (',
    '  CLAVE_DOCUMENTO_CFPER, TIPO_OPERACION_CFPER,',
    '  CODIGO_EMP_ORIGEN_CFPER, CODIGO_EMP_DESTINO_CFPER,',
    '  CODIGO_ALM_CFPER, CODIGO_CAJA_CFPER, FECHA_DESDE_CFPER,',
    '  FECHA_HASTA_CFPER, FECHA_DOCUMENTO_CFPER,',
    '  ESTADO_PROCESO_CFPER, ESTADO_FISCAL_CFPER, ESAJUSTE_CFPER,',
    '  ID_CFPER_ORIGEN_CFPER, INSTANTE_ALTA, INSTANTE_MODIF,',
    '  USUARIO_ALTA, USUARIO_MODIF)',
    'VALUES (UUID(), :TIPO, :EMPRESA, NULLIF(:DESTINO, ''''),',
    '  :ALMACEN, :CAJA, :DESDE, :HASTA, :FECHA_DOCUMENTO,',
    '  ''PROCESANDO'', :ESTADO_FISCAL, :ESAJUSTE,',
    '  NULLIF(:ID_ORIGEN, 0), NOW(), NOW(), :USUARIO, :USUARIO)'
  ]);
end;

function SqlInsertarOperacionesFacturacionPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturacion_operaciones (',
    '  ID_CFPER_CFOP, ID_OPCAJA_CFOP, ID_CFOP_ORIGEN_CFOP,',
    '  TIPO_APUNTE_CFOP, HUELLA_ORIGEN_CFOP,',
    '  CLAVE_IDEMPOTENCIA_CFOP, INSTANTE_OPERACION_CFOP,',
    '  IMPORTE_ORIGEN_CFOP, IMPORTE_DOCUMENTO_CFOP,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT :ID_DOCUMENTO, t.ID_OPCAJA, NULLIF(t.ID_CFOP_ANTERIOR, 0),',
    '       IF(t.ID_CFOP_ANTERIOR = 0, ''ALTA'', ''AJUSTE''),',
    '       t.HUELLA_ORIGEN,',
    '       SHA2(CONCAT_WS(''|'', t.TIPO_FACTURACION, t.ID_OPCAJA,',
    '         t.ID_CFOP_ANTERIOR, t.HUELLA_ORIGEN), 256),',
    '       t.INSTANTE_OPERACION, t.IMPORTE_ORIGEN, 0,',
    '       NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM tmp_facturacion_periodo t',
    ' WHERE t.TIPO_FACTURACION = :TIPO',
    '   AND t.CODIGO_EMP_DESTINO = :DESTINO',
    '   AND t.ID_CFPER_ANTERIOR = :ID_ORIGEN'
  ]);
end;

function SqlInsertarLineasVentaPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturacion_lineas (',
    '  ID_CFOP_CFLIN, CLAVE_LINEA_ORIGEN_CFLIN, LINEA_ORIGEN_CFLIN,',
    '  CODIGO_ART_CFLIN, CODIGO_UNIDAD_CFLIN, DESCRIPCION_CFLIN,',
    '  CANTIDAD_ORIGEN_CFLIN, CANTIDAD_DOCUMENTO_CFLIN,',
    '  PRECIO_UNITARIO_BASE_CFLIN, TIPO_IVA_CFLIN,',
    '  PORCENTAJE_IVA_CFLIN, TOTAL_ORIGEN_BASE_CFLIN,',
    '  TOTAL_ORIGEN_IVA_CFLIN, TOTAL_ORIGEN_CFLIN,',
    '  TOTAL_BASE_CFLIN, TOTAL_IVA_CFLIN, TOTAL_LINEA_CFLIN,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT n.ID_CFOP,',
    '       CONCAT_WS(''|'', fl.LINEA_FACLIN, fl.CODIGO_UNIDAD_FACLIN),',
    '       fl.LINEA_FACLIN, fl.CODIGO_ART_FACLIN,',
    '       fl.CODIGO_UNIDAD_FACLIN, fl.DESCRIPCION_ARTICULO_FACLIN,',
    '       fl.CANTIDAD_FACLIN,',
    '       fl.CANTIDAD_FACLIN - COALESCE(p.CANTIDAD_ORIGEN_CFLIN, 0),',
    '       COALESCE(fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, 0),',
    '       ''NA'', 0, COALESCE(fl.TOTAL_FACLIN, 0), 0,',
    '       COALESCE(fl.TOTAL_FACLIN, 0),',
    '       COALESCE(fl.TOTAL_FACLIN, 0) -',
    '         COALESCE(p.TOTAL_ORIGEN_CFLIN, 0), 0,',
    '       COALESCE(fl.TOTAL_FACLIN, 0) -',
    '         COALESCE(p.TOTAL_ORIGEN_CFLIN, 0),',
    '       NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturacion_operaciones n',
    '  JOIN fza_caja_operaciones o ON o.ID_OPCAJA = n.ID_OPCAJA_CFOP',
    '  JOIN fza_facturas_lineas fl',
    '    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA',
    '   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA',
    '  LEFT JOIN fza_caja_facturacion_lineas p',
    '    ON p.ID_CFOP_CFLIN = n.ID_CFOP_ORIGEN_CFOP',
    '   AND p.CLAVE_LINEA_ORIGEN_CFLIN =',
    '       CONCAT_WS(''|'', fl.LINEA_FACLIN, fl.CODIGO_UNIDAD_FACLIN)',
    ' WHERE n.ID_CFPER_CFOP = :ID_DOCUMENTO'
  ]);
end;

function SqlInsertarLineasVentaRetiradasPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturacion_lineas (',
    '  ID_CFOP_CFLIN, CLAVE_LINEA_ORIGEN_CFLIN, LINEA_ORIGEN_CFLIN,',
    '  CODIGO_ART_CFLIN, CODIGO_UNIDAD_CFLIN, DESCRIPCION_CFLIN,',
    '  CANTIDAD_ORIGEN_CFLIN, CANTIDAD_DOCUMENTO_CFLIN,',
    '  PRECIO_UNITARIO_BASE_CFLIN, TIPO_IVA_CFLIN,',
    '  PORCENTAJE_IVA_CFLIN, TOTAL_ORIGEN_BASE_CFLIN,',
    '  TOTAL_ORIGEN_IVA_CFLIN, TOTAL_ORIGEN_CFLIN,',
    '  TOTAL_BASE_CFLIN, TOTAL_IVA_CFLIN, TOTAL_LINEA_CFLIN,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT n.ID_CFOP, p.CLAVE_LINEA_ORIGEN_CFLIN,',
    '       p.LINEA_ORIGEN_CFLIN, p.CODIGO_ART_CFLIN,',
    '       p.CODIGO_UNIDAD_CFLIN, p.DESCRIPCION_CFLIN, 0,',
    '       -p.CANTIDAD_ORIGEN_CFLIN, p.PRECIO_UNITARIO_BASE_CFLIN,',
    '       ''NA'', 0, 0, 0, 0, -p.TOTAL_ORIGEN_CFLIN, 0,',
    '       -p.TOTAL_ORIGEN_CFLIN, NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturacion_operaciones n',
    '  JOIN fza_caja_facturacion_lineas p',
    '    ON p.ID_CFOP_CFLIN = n.ID_CFOP_ORIGEN_CFOP',
    '  JOIN fza_caja_operaciones o ON o.ID_OPCAJA = n.ID_OPCAJA_CFOP',
    '  LEFT JOIN fza_facturas_lineas fl',
    '    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA',
    '   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA',
    '   AND CONCAT_WS(''|'', fl.LINEA_FACLIN, fl.CODIGO_UNIDAD_FACLIN) =',
    '       p.CLAVE_LINEA_ORIGEN_CFLIN',
    ' WHERE n.ID_CFPER_CFOP = :ID_DOCUMENTO',
    '   AND fl.LINEA_FACLIN IS NULL'
  ]);
end;

function SqlInsertarLineasTraspasoPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturacion_lineas (',
    '  ID_CFOP_CFLIN, CLAVE_LINEA_ORIGEN_CFLIN, LINEA_ORIGEN_CFLIN,',
    '  NUMERO_MOV_ORIGEN_CFLIN, CODIGO_ART_CFLIN,',
    '  CODIGO_UNIDAD_CFLIN, DESCRIPCION_CFLIN,',
    '  CANTIDAD_ORIGEN_CFLIN, CANTIDAD_DOCUMENTO_CFLIN,',
    '  PRECIO_UNITARIO_BASE_CFLIN, TIPO_IVA_CFLIN,',
    '  PORCENTAJE_IVA_CFLIN, TOTAL_ORIGEN_BASE_CFLIN,',
    '  TOTAL_ORIGEN_IVA_CFLIN, TOTAL_ORIGEN_CFLIN,',
    '  TOTAL_BASE_CFLIN, TOTAL_IVA_CFLIN, TOTAL_LINEA_CFLIN,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT n.ID_CFOP, m.NUMERO_MOV, m.LINEA_MOV, m.NUMERO_MOV,',
    '       m.CODIGO_ART_MOV, m.CODIGO_UNIDAD_MOV,',
    '       COALESCE(NULLIF(m.DESCRIPCION_ARTICULO_MOV, ''''),',
    '                a.DESCRIPCION_ART),',
    '       m.CANTIDAD_MOV,',
    '       m.CANTIDAD_MOV - COALESCE(p.CANTIDAD_ORIGEN_CFLIN, 0),',
    '       COALESCE(NULLIF(m.PRECIO_COSTE_UNITARIO_MOV, 0),',
    '                m.PRECIO_MEDIO_MOV, 0),',
    '       COALESCE(NULLIF(UPPER(a.TIPO_IVA_ART), ''''), ''N''),',
    '       COALESCE(CASE UPPER(COALESCE(a.TIPO_IVA_ART, ''N''))',
    '         WHEN ''R'' THEN v.PORCENTAJE_REDUCIDO_IVA',
    '         WHEN ''S'' THEN v.PORCENTAJE_SUPERREDUCIDO_IVA',
    '         WHEN ''E'' THEN v.PORCENTAJE_EXENTO_IVA',
    '         ELSE v.PORCENTAJE_NORMAL_IVA END, 0),',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0),',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0) *',
    '         COALESCE(CASE UPPER(COALESCE(a.TIPO_IVA_ART, ''N''))',
    '           WHEN ''R'' THEN v.PORCENTAJE_REDUCIDO_IVA',
    '           WHEN ''S'' THEN v.PORCENTAJE_SUPERREDUCIDO_IVA',
    '           WHEN ''E'' THEN v.PORCENTAJE_EXENTO_IVA',
    '           ELSE v.PORCENTAJE_NORMAL_IVA END, 0) / 100,',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0) * (1 +',
    '         COALESCE(CASE UPPER(COALESCE(a.TIPO_IVA_ART, ''N''))',
    '           WHEN ''R'' THEN v.PORCENTAJE_REDUCIDO_IVA',
    '           WHEN ''S'' THEN v.PORCENTAJE_SUPERREDUCIDO_IVA',
    '           WHEN ''E'' THEN v.PORCENTAJE_EXENTO_IVA',
    '           ELSE v.PORCENTAJE_NORMAL_IVA END, 0) / 100),',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0) -',
    '         COALESCE(p.TOTAL_ORIGEN_BASE_CFLIN, 0),',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0) *',
    '         COALESCE(CASE UPPER(COALESCE(a.TIPO_IVA_ART, ''N''))',
    '           WHEN ''R'' THEN v.PORCENTAJE_REDUCIDO_IVA',
    '           WHEN ''S'' THEN v.PORCENTAJE_SUPERREDUCIDO_IVA',
    '           WHEN ''E'' THEN v.PORCENTAJE_EXENTO_IVA',
    '           ELSE v.PORCENTAJE_NORMAL_IVA END, 0) / 100 -',
    '         COALESCE(p.TOTAL_ORIGEN_IVA_CFLIN, 0),',
    '       COALESCE(m.TOTAL_COSTE_MOV, 0) * (1 +',
    '         COALESCE(CASE UPPER(COALESCE(a.TIPO_IVA_ART, ''N''))',
    '           WHEN ''R'' THEN v.PORCENTAJE_REDUCIDO_IVA',
    '           WHEN ''S'' THEN v.PORCENTAJE_SUPERREDUCIDO_IVA',
    '           WHEN ''E'' THEN v.PORCENTAJE_EXENTO_IVA',
    '           ELSE v.PORCENTAJE_NORMAL_IVA END, 0) / 100) -',
    '         COALESCE(p.TOTAL_ORIGEN_CFLIN, 0),',
    '       NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturacion_operaciones n',
    '  JOIN fza_caja_operaciones o ON o.ID_OPCAJA = n.ID_OPCAJA_CFOP',
    '  JOIN fza_movimientos_almacen m',
    '    ON m.SERIE_DOC_MOV = o.SERIE_FAC_OPCAJA',
    '   AND m.NUMERO_DOC_MOV = o.NUMERO_FAC_OPCAJA',
    '   AND m.CODIGO_EMP_MOV = o.CODIGO_EMP_OPCAJA',
    '   AND m.CODIGO_ALM_MOV = o.CODIGO_ALM_OPCAJA',
    '   AND m.TIPO_DOC_MOV IN (''TA'', ''AT'')',
    '   AND m.TIPO_MOV = ''S''',
    '   AND COALESCE(m.ESACTIVO_MOV, ''S'') = ''S''',
    '  LEFT JOIN fza_articulos a ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV',
    '  JOIN fza_empresas e ON e.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA',
    '  LEFT JOIN fza_ivas v ON v.CODIGO_IVA = (',
    '    SELECT vx.CODIGO_IVA FROM fza_ivas vx',
    '     WHERE vx.GRUPO_ZONA_IVA = e.GRUPO_ZONA_IVA_EMP',
    '       AND vx.FECHA_DESDE_IVA <= :FECHA_DOCUMENTO',
    '       AND (vx.FECHA_HASTA_IVA IS NULL',
    '            OR vx.FECHA_HASTA_IVA >= :FECHA_DOCUMENTO)',
    '     ORDER BY vx.FECHA_DESDE_IVA DESC LIMIT 1)',
    '  LEFT JOIN fza_caja_facturacion_lineas p',
    '    ON p.ID_CFOP_CFLIN = n.ID_CFOP_ORIGEN_CFOP',
    '   AND p.CLAVE_LINEA_ORIGEN_CFLIN = m.NUMERO_MOV',
    ' WHERE n.ID_CFPER_CFOP = :ID_DOCUMENTO'
  ]);
end;

function SqlInsertarLineasTraspasoRetiradasPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_caja_facturacion_lineas (',
    '  ID_CFOP_CFLIN, CLAVE_LINEA_ORIGEN_CFLIN, LINEA_ORIGEN_CFLIN,',
    '  NUMERO_MOV_ORIGEN_CFLIN, CODIGO_ART_CFLIN,',
    '  CODIGO_UNIDAD_CFLIN, DESCRIPCION_CFLIN,',
    '  CANTIDAD_ORIGEN_CFLIN, CANTIDAD_DOCUMENTO_CFLIN,',
    '  PRECIO_UNITARIO_BASE_CFLIN, TIPO_IVA_CFLIN,',
    '  PORCENTAJE_IVA_CFLIN, TOTAL_ORIGEN_BASE_CFLIN,',
    '  TOTAL_ORIGEN_IVA_CFLIN, TOTAL_ORIGEN_CFLIN,',
    '  TOTAL_BASE_CFLIN, TOTAL_IVA_CFLIN, TOTAL_LINEA_CFLIN,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT n.ID_CFOP, p.CLAVE_LINEA_ORIGEN_CFLIN,',
    '       p.LINEA_ORIGEN_CFLIN, p.NUMERO_MOV_ORIGEN_CFLIN,',
    '       p.CODIGO_ART_CFLIN, p.CODIGO_UNIDAD_CFLIN,',
    '       p.DESCRIPCION_CFLIN, 0, -p.CANTIDAD_ORIGEN_CFLIN,',
    '       p.PRECIO_UNITARIO_BASE_CFLIN, p.TIPO_IVA_CFLIN,',
    '       p.PORCENTAJE_IVA_CFLIN, 0, 0, 0,',
    '       -p.TOTAL_ORIGEN_BASE_CFLIN,',
    '       -p.TOTAL_ORIGEN_IVA_CFLIN, -p.TOTAL_ORIGEN_CFLIN,',
    '       NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturacion_operaciones n',
    '  JOIN fza_caja_facturacion_lineas p',
    '    ON p.ID_CFOP_CFLIN = n.ID_CFOP_ORIGEN_CFOP',
    '  LEFT JOIN fza_movimientos_almacen m',
    '    ON m.NUMERO_MOV = p.NUMERO_MOV_ORIGEN_CFLIN',
    '   AND m.TIPO_MOV = ''S''',
    '   AND COALESCE(m.ESACTIVO_MOV, ''S'') = ''S''',
    ' WHERE n.ID_CFPER_CFOP = :ID_DOCUMENTO',
    '   AND m.NUMERO_MOV IS NULL'
  ]);
end;

function SqlActualizarTotalesFacturacionPeriodo: string;
begin
  Result := UnirSql([
    'UPDATE fza_caja_facturaciones_periodo d',
    '  JOIN (',
    '    SELECT o.ID_CFPER_CFOP, SUM(l.TOTAL_BASE_CFLIN) AS BASE,',
    '           SUM(l.TOTAL_IVA_CFLIN) AS IVA,',
    '           SUM(l.TOTAL_LINEA_CFLIN) AS TOTAL',
    '      FROM fza_caja_facturacion_operaciones o',
    '      JOIN fza_caja_facturacion_lineas l',
    '        ON l.ID_CFOP_CFLIN = o.ID_CFOP',
    '     WHERE o.ID_CFPER_CFOP = :ID_DOCUMENTO',
    '     GROUP BY o.ID_CFPER_CFOP',
    '  ) t ON t.ID_CFPER_CFOP = d.ID_CFPER',
    '   SET d.TOTAL_BASE_CFPER = t.BASE, d.TOTAL_IVA_CFPER = t.IVA,',
    '       d.TOTAL_DOCUMENTO_CFPER = t.TOTAL,',
    '       d.INSTANTE_MODIF = NOW(), d.USUARIO_MODIF = :USUARIO',
    ' WHERE d.ID_CFPER = :ID_DOCUMENTO'
  ]);
end;

function SqlInsertarFacturaTraspasoPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_facturas (',
    '  NUMERO_FAC, SERIE_FAC, FECHA_FAC, ESCONSOLIDADA_FAC,',
    '  TIPO_FAC, FASE_FAC, ESMUEVE_STOCK_FAC,',
    '  TIPO_RECTIFICATIVA_FAC, TIPO_FACTURA_VERIFACTU_FAC,',
    '  CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC,',
    '  MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC,',
    '  DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC,',
    '  PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC,',
    '  NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC,',
    '  ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC,',
    '  ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC,',
    '  CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC,',
    '  MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC,',
    '  DIRECCION2_CLIENTE_FAC, POBLACION_CLIENTE_FAC,',
    '  PROVINCIA_CLIENTE_FAC, CODIGO_PAI_CLIENTE_FAC,',
    '  NOMBRE_PAI_CLIENTE_FAC, CODIGO_POSTAL_CLIENTE_FAC,',
    '  ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC,',
    '  ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC,',
    '  ESRETENCIONES_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC,',
    '  ESINTRACOMUNITARIO_CLIENTE_FAC, ESIRPF_IMP_INCL_ZONA_IVA_FAC,',
    '  ESAPLICA_RE_ZONA_IVA_FAC, ESIVAAGRICOLA_ZONA_IVA_FAC,',
    '  PALABRA_REPORTS_ZONA_IVA_FAC, CODIGO_IVA_FAC,',
    '  ESVENTA_ACTIVO_FIJO_FAC, PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC,',
    '  TOTAL_BASEI_IVAN_FAC, PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC,',
    '  TOTAL_BASEI_IVAR_FAC, PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC,',
    '  TOTAL_BASEI_IVAS_FAC, PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC,',
    '  TOTAL_BASEI_IVAE_FAC, TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC,',
    '  FORMA_PAGO_FAC, PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC,',
    '  TOTAL_LIQUIDO_FAC, COMENTARIOS_FAC, CONTADOR_LINEAS_FAC,',
    '  CODIGO_ALM_FAC, INSTANTE_ALTA, INSTANTE_MODIF,',
    '  USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT :NUMERO, :SERIE, d.FECHA_DOCUMENTO_CFPER, ''N'',',
    '       IF(d.ESAJUSTE_CFPER = ''S'', ''RECTIFICATIVA'', ''NORMAL''),',
    '       ''BORRADOR'', ''N'',',
    '       IF(d.ESAJUSTE_CFPER = ''S'', ''I'', NULL),',
    '       IF(d.ESAJUSTE_CFPER = ''S'', ''R1'', NULL),',
    '       e.CODIGO_EMP_EMP, e.RAZON_SOCIAL_EMP, e.NIF_EMP,',
    '       e.MOVIL_EMP, e.EMAIL_EMP, e.DIRECCION1_EMP, e.DIRECCION2_EMP,',
    '       e.POBLACION_EMP, e.PROVINCIA_EMP, e.CODIGO_PAI_EMP,',
    '       e.NOMBRE_PAI_EMP, e.CODIGO_POSTAL_EMP, e.ESRETENCIONES_EMP,',
    '       e.GRUPO_ZONA_IVA_EMP, e.ESREGIMENESPECIALAGRICOLA_EMP,',
    '       de.CODIGO_EMP_EMP, de.RAZON_SOCIAL_EMP, de.NIF_EMP,',
    '       de.MOVIL_EMP, de.EMAIL_EMP, de.DIRECCION1_EMP,',
    '       de.DIRECCION2_EMP, de.POBLACION_EMP, de.PROVINCIA_EMP,',
    '       de.CODIGO_PAI_EMP, de.NOMBRE_PAI_EMP, de.CODIGO_POSTAL_EMP,',
    '       ''N'', ''N'', ''N'', ''N'', ''N'', ''N'', ''N'', ''S'', ''N'',',
    '       ''IVA'', v.CODIGO_IVA, ''N'',',
    '       COALESCE(v.PORCENTAJE_NORMAL_IVA, 0),',
    '       t.IVA_N, t.BASE_N, COALESCE(v.PORCENTAJE_REDUCIDO_IVA, 0),',
    '       t.IVA_R, t.BASE_R, COALESCE(v.PORCENTAJE_SUPERREDUCIDO_IVA, 0),',
    '       t.IVA_S, t.BASE_S, COALESCE(v.PORCENTAJE_EXENTO_IVA, 0),',
    '       t.IVA_E, t.BASE_E, t.BASE_TOTAL, t.IVA_TOTAL, ''CONTADO'',',
    '       0, 0, t.TOTAL,',
    '       CONCAT(''Facturación de operaciones TA. Documento interno '',',
    '              d.ID_CFPER), LPAD(t.LINEAS * 10, 8, ''0''),',
    '       d.CODIGO_ALM_CFPER, NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturaciones_periodo d',
    '  JOIN fza_empresas e',
    '    ON e.CODIGO_EMP_EMP = d.CODIGO_EMP_ORIGEN_CFPER',
    '  JOIN fza_empresas de',
    '    ON de.CODIGO_EMP_EMP = d.CODIGO_EMP_DESTINO_CFPER',
    '  LEFT JOIN fza_ivas v ON v.CODIGO_IVA = (',
    '    SELECT vx.CODIGO_IVA FROM fza_ivas vx',
    '     WHERE vx.GRUPO_ZONA_IVA = e.GRUPO_ZONA_IVA_EMP',
    '       AND vx.FECHA_DESDE_IVA <= d.FECHA_DOCUMENTO_CFPER',
    '       AND (vx.FECHA_HASTA_IVA IS NULL',
    '            OR vx.FECHA_HASTA_IVA >= d.FECHA_DOCUMENTO_CFPER)',
    '     ORDER BY vx.FECHA_DESDE_IVA DESC LIMIT 1)',
    '  JOIN (',
    '    SELECT o.ID_CFPER_CFOP, COUNT(*) AS LINEAS,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''N''',
    '          THEN l.TOTAL_BASE_CFLIN ELSE 0 END) AS BASE_N,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''N''',
    '          THEN l.TOTAL_IVA_CFLIN ELSE 0 END) AS IVA_N,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''R''',
    '          THEN l.TOTAL_BASE_CFLIN ELSE 0 END) AS BASE_R,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''R''',
    '          THEN l.TOTAL_IVA_CFLIN ELSE 0 END) AS IVA_R,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''S''',
    '          THEN l.TOTAL_BASE_CFLIN ELSE 0 END) AS BASE_S,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''S''',
    '          THEN l.TOTAL_IVA_CFLIN ELSE 0 END) AS IVA_S,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''E''',
    '          THEN l.TOTAL_BASE_CFLIN ELSE 0 END) AS BASE_E,',
    '      SUM(CASE WHEN l.TIPO_IVA_CFLIN = ''E''',
    '          THEN l.TOTAL_IVA_CFLIN ELSE 0 END) AS IVA_E,',
    '      SUM(l.TOTAL_BASE_CFLIN) AS BASE_TOTAL,',
    '      SUM(l.TOTAL_IVA_CFLIN) AS IVA_TOTAL,',
    '      SUM(l.TOTAL_LINEA_CFLIN) AS TOTAL',
    '      FROM fza_caja_facturacion_operaciones o',
    '      JOIN fza_caja_facturacion_lineas l',
    '        ON l.ID_CFOP_CFLIN = o.ID_CFOP',
    '     WHERE o.ID_CFPER_CFOP = :ID_DOCUMENTO',
    '     GROUP BY o.ID_CFPER_CFOP',
    '  ) t ON t.ID_CFPER_CFOP = d.ID_CFPER',
    ' WHERE d.ID_CFPER = :ID_DOCUMENTO'
  ]);
end;

function SqlInsertarLineasFacturaTraspasoPeriodo: string;
begin
  Result := UnirSql([
    'INSERT INTO fza_facturas_lineas (',
    '  NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN,',
    '  LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN,',
    '  TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN,',
    '  DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN,',
    '  TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN,',
    '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN,',
    '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN,',
    '  TOTAL_FAC_SIVA_FACLIN, CODIGO_ALM_FACLIN,',
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)',
    'SELECT :NUMERO, :SERIE, d.CODIGO_EMP_ORIGEN_CFPER,',
    '       LPAD(ROW_NUMBER() OVER (ORDER BY o.ID_CFOP, l.ID_CFLIN) * 10,',
    '            4, ''0''), l.CODIGO_ART_CFLIN, l.CODIGO_UNIDAD_CFLIN,',
    '       ''Uds'', l.CANTIDAD_DOCUMENTO_CFLIN, l.DESCRIPCION_CFLIN,',
    '       ''N'', l.TIPO_IVA_CFLIN, l.PORCENTAJE_IVA_CFLIN,',
    '       l.PRECIO_UNITARIO_BASE_CFLIN,',
    '       l.PRECIO_UNITARIO_BASE_CFLIN *',
    '         (1 + l.PORCENTAJE_IVA_CFLIN / 100),',
    '       l.TOTAL_LINEA_CFLIN, l.TOTAL_BASE_CFLIN,',
    '       d.CODIGO_ALM_CFPER, NOW(), NOW(), :USUARIO, :USUARIO',
    '  FROM fza_caja_facturaciones_periodo d',
    '  JOIN fza_caja_facturacion_operaciones o',
    '    ON o.ID_CFPER_CFOP = d.ID_CFPER',
    '  JOIN fza_caja_facturacion_lineas l ON l.ID_CFOP_CFLIN = o.ID_CFOP',
    ' WHERE d.ID_CFPER = :ID_DOCUMENTO',
    '   AND ABS(l.TOTAL_LINEA_CFLIN) > 0.000001',
    ' ORDER BY o.ID_CFOP, l.ID_CFLIN'
  ]);
end;

function SqlConsultarInformeFacturacionPeriodo: string;
begin
  Result := UnirSql([
    'SELECT CAST(d.ID_CFPER AS CHAR) AS CLAVE_DOCUMENTO,',
    '       CONCAT(IF(d.TIPO_OPERACION_CFPER = ''VE'',',
    '         ''PROFORMA INTERNA '', ''FACTURA ''),',
    '         d.SERIE_DOCUMENTO_CFPER, ''/'',',
    '         d.NUMERO_DOCUMENTO_CFPER) AS DOCUMENTO,',
    '       d.FECHA_DOCUMENTO_CFPER AS FECHA_DOCUMENTO,',
    '       d.TIPO_OPERACION_CFPER AS TIPO_OPERACION,',
    '       d.ESTADO_PROCESO_CFPER AS ESTADO_PROCESO,',
    '       IF(d.TIPO_OPERACION_CFPER = ''VE'', ''NO APLICA'',',
    '          COALESCE(f.FASE_FAC, d.ESTADO_FISCAL_CFPER))',
    '          AS ESTADO_FISCAL,',
    '       d.ESAJUSTE_CFPER AS ES_AJUSTE,',
    '       l.ID_CFLIN AS LINEA_DOCUMENTO, l.CODIGO_ART_CFLIN AS ARTICULO,',
    '       l.CODIGO_UNIDAD_CFLIN AS SKU, l.DESCRIPCION_CFLIN AS DESCRIPCION,',
    '       l.CANTIDAD_DOCUMENTO_CFLIN AS CANTIDAD,',
    '       l.PRECIO_UNITARIO_BASE_CFLIN AS PRECIO_BASE,',
    '       l.PORCENTAJE_IVA_CFLIN AS PORCENTAJE_IVA,',
    '       l.TOTAL_BASE_CFLIN AS TOTAL_BASE,',
    '       l.TOTAL_IVA_CFLIN AS TOTAL_IVA,',
    '       l.TOTAL_LINEA_CFLIN AS TOTAL_LINEA',
    '  FROM fza_caja_facturaciones_periodo d',
    '  JOIN fza_caja_facturacion_operaciones o',
    '    ON o.ID_CFPER_CFOP = d.ID_CFPER',
    '  JOIN fza_caja_facturacion_lineas l ON l.ID_CFOP_CFLIN = o.ID_CFOP',
    '  LEFT JOIN fza_facturas f',
    '    ON f.SERIE_FAC = d.SERIE_DOCUMENTO_CFPER',
    '   AND f.NUMERO_FAC = d.NUMERO_DOCUMENTO_CFPER',
    ' WHERE d.CODIGO_EMP_ORIGEN_CFPER = :EMPRESA',
    '   AND d.CODIGO_ALM_CFPER = :ALMACEN',
    '   AND d.CODIGO_CAJA_CFPER = :CAJA',
    '   AND d.FECHA_DOCUMENTO_CFPER >= :DESDE',
    '   AND d.FECHA_DOCUMENTO_CFPER < DATE_ADD(:HASTA, INTERVAL 1 DAY)',
    '   AND d.ESTADO_PROCESO_CFPER = ''COMPLETADO''',
    '   AND (ABS(l.TOTAL_LINEA_CFLIN) > 0.000001',
    '        OR ABS(l.CANTIDAD_DOCUMENTO_CFLIN) > 0.000001)',
    ' ORDER BY d.FECHA_DOCUMENTO_CFPER, d.ID_CFPER, l.ID_CFLIN'
  ]);
end;

end.
