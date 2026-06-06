-- =============================================================================
-- Vistas de atributos/slots: anadir ORDER BY por la columna ORDEN
-- =============================================================================
-- DECISION EXPLICITA (con coste de rendimiento asumido):
-- Estas 4 vistas exponen una columna de orden visual del usuario pero se
-- filtran por articulo contra tablas grandes (fza_articulos_skus ~435k filas).
-- Un ORDER BY en el cuerpo de la vista la vuelve NO mergeable: MariaDB la
-- materializa entera antes de aplicar el WHERE externo. Justo por eso se le
-- habia quitado el ORDER BY a vi_atributos_nombres en su dia (ver
-- fix_vi_atributos_nombres_sin_orderby.sql, que midio >6 s por llamada). Aqui
-- se reintroduce el ORDER BY por peticion expresa, aceptando ese coste. Si en
-- el futuro vuelve a pesar, este script es el unico punto a revertir.
--
-- Tecnica: en lugar de reescribir a mano la definicion (una de ellas es un
-- UNION ALL de ~120 lineas que vive en sku_atributos_huerfanos.sql), se lee la
-- definicion ACTUAL de cada vista desde INFORMATION_SCHEMA.VIEWS y se recrea
-- con el ORDER BY anadido al final. Asi no se duplica la definicion ni se corre
-- riesgo de que se quede desincronizada con el script que la crea.
--
-- El ORDER BY usa los NOMBRES DE COLUMNA DE SALIDA (no alias de tabla) para que
-- funcione igual en vistas con UNION que sin el.
--
-- Indices: no se crean. Las uniones de estas vistas van por las PRIMARY KEY de
-- las tablas implicadas (p.ej. fza_variaciones_atributos PK (ID_VAR_VA,
-- ID_ATB_VA), fza_familias_atributos PK (CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP)),
-- asi que el join ya esta indexado. El coste que introduce el ORDER BY es la
-- materializacion + filesort del resultado combinado, que ningun indice sobre
-- las tablas base puede evitar (es inherente a la vista no mergeable). Por eso
-- un indice nuevo no aportaria nada aqui.
--
-- Idempotente: solo recrea la vista si su definicion actual aun NO contiene
-- ORDER BY. Ninguna de estas 4 lo lleva de forma nativa, asi que el guardado
-- por 'ORDER BY' es fiable. CREATE OR REPLACE no toca factuzam_original.sql.
-- =============================================================================

-- 1) vi_atributos_nombres -> ORDEN_VISUAL_ATRIBUTO (por articulo padre).
SET @v   := 'vi_atributos_nombres';
SET @ob  := ' ORDER BY `CODIGO_ART_PADRE_ARTVIN`, `ORDEN_VISUAL_ATRIBUTO`';
SET @def := (SELECT VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @v);
SET @sql := IF(@def IS NULL OR LOCATE('ORDER BY', UPPER(@def)) > 0,
  CONCAT('SELECT ''', @v, ': no existe o ya ordena, se omite'' AS info'),
  CONCAT('CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `', @v, '` AS ', @def, @ob));
PREPARE st FROM @sql;
EXECUTE st;
DEALLOCATE PREPARE st;

-- 2) vi_atributos_sku_basico -> ORDEN_ATRIBUTO (por unidad/SKU). UNION ALL.
SET @v   := 'vi_atributos_sku_basico';
SET @ob  := ' ORDER BY `CODIGO_UNIDAD_SKU`, `ORDEN_ATRIBUTO`, `ID_VA_AV`';
SET @def := (SELECT VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @v);
SET @sql := IF(@def IS NULL OR LOCATE('ORDER BY', UPPER(@def)) > 0,
  CONCAT('SELECT ''', @v, ': no existe o ya ordena, se omite'' AS info'),
  CONCAT('CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `', @v, '` AS ', @def, @ob));
PREPARE st FROM @sql;
EXECUTE st;
DEALLOCATE PREPARE st;

-- 3) vi_articulos_conjuntos_slots -> ORDEN_ATRIBUTO (por articulo).
SET @v   := 'vi_articulos_conjuntos_slots';
SET @ob  := ' ORDER BY `CODIGO_ART_ACA`, `ORDEN_ATRIBUTO`';
SET @def := (SELECT VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @v);
SET @sql := IF(@def IS NULL OR LOCATE('ORDER BY', UPPER(@def)) > 0,
  CONCAT('SELECT ''', @v, ': no existe o ya ordena, se omite'' AS info'),
  CONCAT('CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `', @v, '` AS ', @def, @ob));
PREPARE st FROM @sql;
EXECUTE st;
DEALLOCATE PREPARE st;

-- 4) vi_articulos_propiedades_slots -> ORDEN_MOSTRAR_FA (por articulo).
SET @v   := 'vi_articulos_propiedades_slots';
SET @ob  := ' ORDER BY `CODIGO_ART_ART`, `ORDEN_MOSTRAR_FA`';
SET @def := (SELECT VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @v);
SET @sql := IF(@def IS NULL OR LOCATE('ORDER BY', UPPER(@def)) > 0,
  CONCAT('SELECT ''', @v, ': no existe o ya ordena, se omite'' AS info'),
  CONCAT('CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `', @v, '` AS ', @def, @ob));
PREPARE st FROM @sql;
EXECUTE st;
DEALLOCATE PREPARE st;
