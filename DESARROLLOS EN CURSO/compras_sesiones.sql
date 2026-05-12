-- ============================================================================
-- Módulo Compras — Sesiones (pre-pedidos / pre-albaranes)
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
--
-- Principio: nada de lo que vive en estas tablas se materializa en las tablas
-- maestras (fza_articulos, fza_articulos_skus, fza_codigos_barras,
-- fza_articulos_proveedores) hasta que el usuario pulsa explícitamente
-- "Crear artículos y documentos". Toda materialización es código Delphi
-- explícito, en una sola transacción.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- IDEMPOTENCIA
-- ---------------------------------------------------------------------------
-- Este script se puede ejecutar tantas veces como haga falta:
--   - CREATE TABLE … IF NOT EXISTS para todas las tablas.
--   - CREATE OR REPLACE VIEW para las vistas.
--   - El ALTER TABLE de la sección 0 se envuelve en un bloque dinámico
--     que comprueba INFORMATION_SCHEMA antes de añadir la columna.
--
-- Los datos de configuración (contadores, fza_winforms, etiquetas
-- NOMBRE_VISIBLE_VA) viven en compras_sesiones_datos.sql.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 0. Cambio a tabla existente: nombre visible del atributo de variación
-- ---------------------------------------------------------------------------
-- Permite que la UI etiquete el eje pivot con un nombre parametrizable
-- (ej. "Sistema de tallas", "Paleta", "Duración"...) en lugar de un literal
-- hardcoded. Aplica a toda la app, no sólo a las sesiones de compra.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_variaciones_atributos'
     AND COLUMN_NAME  = 'NOMBRE_VISIBLE_VA'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_variaciones_atributos` '
  'ADD COLUMN `NOMBRE_VISIBLE_VA` varchar(50) DEFAULT NULL '
  'COMMENT ''Etiqueta a mostrar en formularios cuando este atributo pivota''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 0-bis. Numero de digitos de relleno por familia para autogenerar codigos
-- ---------------------------------------------------------------------------
-- Cuando el usuario teclea en la sesion el codigo de una familia (ej.
-- "BOLSOS") con ESCONTADOR_ART_FAM='S' y CONTADOR_ART_FAM > 0, la sesion
-- expande automaticamente al siguiente codigo:
--   <CODIGO_FAM_FAM> + RIGHT('00000' + CAST(CONTADOR_ART_FAM AS CHAR), PAD)
-- y se incrementa el contador.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_familias'
     AND COLUMN_NAME  = 'PAD_ART_FAM'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_articulos_familias` '
  'ADD COLUMN `PAD_ART_FAM` int(11) NOT NULL DEFAULT 5 '
  'COMMENT ''Numero de digitos del relleno cuando se autogenera codigo articulo desde familia''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Inicializar valores en familias ya existentes (las columnas son NULLABLE
-- en bases antiguas; el DEFAULT solo aplica a filas nuevas). Los TcxDBSpinEdit
-- no permiten editar campos NULL con MinValue>0, asi que ponemos defaults.
UPDATE `fza_articulos_familias`
   SET `CONTADOR_ART_FAM` = 0
 WHERE `CONTADOR_ART_FAM` IS NULL;

UPDATE `fza_articulos_familias`
   SET `PAD_ART_FAM` = 5
 WHERE `PAD_ART_FAM` IS NULL OR `PAD_ART_FAM` = 0;

UPDATE `fza_articulos_familias`
   SET `ESCONTADOR_ART_FAM` = 'N'
 WHERE `ESCONTADOR_ART_FAM` IS NULL OR `ESCONTADOR_ART_FAM` = '';

-- Migración idempotente para la cabecera: añadir parámetros de fórmula
-- de precio venta (MULTIPLO_REDONDEO, AJUSTE_FINAL) si la tabla ya existe
-- sin ellos. La definición del CREATE TABLE más abajo los incluye.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones'
     AND COLUMN_NAME  = 'MULTIPLO_REDONDEO_SES'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones` '
  'ADD COLUMN `MULTIPLO_REDONDEO_SES` decimal(19,6) NOT NULL DEFAULT 0 '
  '  AFTER `ESREDONDEO_VENTA_SES`, '
  'ADD COLUMN `AJUSTE_FINAL_SES` decimal(19,6) NOT NULL DEFAULT 0 '
  '  AFTER `MULTIPLO_REDONDEO_SES`, '
  'ADD COLUMN `ESPRECIO_POR_SKU_SES` char(1) NOT NULL DEFAULT ''N'' '
  '  AFTER `AJUSTE_FINAL_SES`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migracion auxiliar: si la tabla ya tenia MULTIPLO/AJUSTE pero no
-- ESPRECIO_POR_SKU_SES (caso intermedio), anadirla suelta.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones'
     AND COLUMN_NAME  = 'ESPRECIO_POR_SKU_SES'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones` '
  'ADD COLUMN `ESPRECIO_POR_SKU_SES` char(1) NOT NULL DEFAULT ''N''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migracion para soporte de eje fila como texto libre del proveedor (§12):
-- anade ETIQUETA_TEXTO_SESFIL a fza_compras_sesiones_lineas_filas si no
-- existe. En modo texto libre _filas_atr queda vacia y la etiqueta de la
-- fila se lee de esta columna.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_lineas_filas'
     AND COLUMN_NAME  = 'ETIQUETA_TEXTO_SESFIL'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_lineas_filas` '
  'ADD COLUMN `ETIQUETA_TEXTO_SESFIL` varchar(100) DEFAULT NULL '
  '  COMMENT ''Etiqueta libre tecleada por el usuario cuando la sesion '
  'usa eje fila libre (ID_AC_FILA_SES IS NULL). Si esta NULL la etiqueta '
  'viene de _filas_atr (modo conjunto).'' '
  '  AFTER `ORDEN_SESFIL`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 1. Cabecera de sesión
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones` (
  `SERIE_SES`                   varchar(12)   NOT NULL,
  `NUMERO_SES`                  varchar(12)   NOT NULL,
  `FECHA_SES`                   date          NOT NULL,
  `ESTADO_SES`                  varchar(10)   NOT NULL DEFAULT 'BORRADOR'
                                  COMMENT 'BORRADOR | CERRADA | ANULADA',
  `CODIGO_EMP_SES`              varchar(20)   NOT NULL,
  `CODIGO_PRV_SES`              varchar(20)   NOT NULL,
  `REF_PRV_SES`                 varchar(100)  DEFAULT NULL
                                  COMMENT 'Referencia del proveedor (PO ext.)',
  `CODIGO_FAM_SES`              varchar(20)   DEFAULT NULL
                                  COMMENT 'Familia objetivo de los artículos a crear',
  `CODIGO_ALM_SES`              varchar(10)   DEFAULT NULL
                                  COMMENT 'Almacén destino si se materializa albarán',
  `MONEDA_SES`                  varchar(5)    NOT NULL DEFAULT 'EUR',
  `TIPO_IVA_SES`                varchar(2)    NOT NULL DEFAULT 'N',
  `PORCENTAJE_MARGEN_SES`       decimal(7,4)  DEFAULT NULL
                                  COMMENT '% margen comercial por defecto',
  `CODIGO_TAR_SES`              varchar(20)   DEFAULT NULL
                                  COMMENT 'Tarifa de salida sugerida',
  `ESPRECIOS_SIN_IVA_SES`       char(1)       NOT NULL DEFAULT 'S',
  `ESREDONDEO_VENTA_SES`        char(1)       NOT NULL DEFAULT 'N',
  `MULTIPLO_REDONDEO_SES`       decimal(19,6) NOT NULL DEFAULT 0
                                  COMMENT 'Multiplo al que sube el precio venta calculado. 0 = sin redondeo.',
  `AJUSTE_FINAL_SES`            decimal(19,6) NOT NULL DEFAULT 0
                                  COMMENT 'Sumando final tras el redondeo. Negativo para acabar en .99, .95, etc.',
  `ESPRECIO_POR_SKU_SES`        char(1)       NOT NULL DEFAULT 'N'
                                  COMMENT 'S=permite override de precio compra/venta por cada SKU (fza_compras_sesiones_lineas_skus_precios).',

  -- Variación POR DEFECTO. Cada línea puede sobreescribirla si ESVAR_FIJA_SES='N'.
  `CODIGO_VAR_SES`              varchar(20)   DEFAULT NULL
                                  COMMENT 'FK fza_variaciones — TC, TEMP, etc. (defecto)',
  `ID_VA_PIVOT_SES`             varchar(20)   DEFAULT NULL
                                  COMMENT 'Atributo cuyos valores pivotan a columnas (defecto)',
  `ID_AC_PIVOT_SES`             int(11)       DEFAULT NULL
                                  COMMENT 'FK fza_atributos_conjuntos para el eje pivot (defecto)',
  `ID_VA_FILA_SES`              varchar(20)   DEFAULT NULL
                                  COMMENT 'Atributo cuyos valores generan filas (defecto)',
  `ID_AC_FILA_SES`              int(11)       DEFAULT NULL
                                  COMMENT 'FK fza_atributos_conjuntos para el eje fila (defecto)',
  `ESVAR_FIJA_SES`              char(1)       NOT NULL DEFAULT 'N'
                                  COMMENT 'S=todas las líneas obligadas a usar la var por defecto. N=cada línea decide.',

  -- Prefijo y contador para EAN13 al materializar
  `PREFIJO_EAN_SES`             varchar(7)    DEFAULT NULL
                                  COMMENT 'Prefijo EAN13 (ej 841xxxx) — null = usa global',

  -- Materialización
  `INSTANTE_MATERIALIZA_SES`    datetime      DEFAULT NULL,
  `USUARIO_MATERIALIZA_SES`     varchar(50)   DEFAULT NULL,
  `ESGENERA_PEDIDO_SES`         char(1)       NOT NULL DEFAULT 'N',
  `ESGENERA_ALBARAN_SES`        char(1)       NOT NULL DEFAULT 'N',
  `SERIE_PEDC_SES`              varchar(12)   DEFAULT NULL
                                  COMMENT 'FK al pedido de compra generado',
  `NUMERO_PEDC_SES`             varchar(12)   DEFAULT NULL,
  `SERIE_ALBC_SES`              varchar(12)   DEFAULT NULL
                                  COMMENT 'FK al albarán de compra generado',
  `NUMERO_ALBC_SES`             varchar(12)   DEFAULT NULL,
  `MENSAJE_ERROR_SES`           varchar(2000) DEFAULT NULL,

  `COMENTARIOS_SES`             varchar(1000) DEFAULT NULL,

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,
  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`SERIE_SES`, `NUMERO_SES`),
  INDEX `IDX_SES_PRV_FECHA` (`CODIGO_PRV_SES`, `FECHA_SES`),
  INDEX `IDX_SES_ESTADO`    (`ESTADO_SES`),
  INDEX `IDX_SES_FAM`       (`CODIGO_FAM_SES`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 2. Propiedades de cabecera (fijas / variables)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_props` (
  `SERIE_SES_SESPROP`           varchar(12)   NOT NULL,
  `NUMERO_SES_SESPROP`          varchar(12)   NOT NULL,
  `CODIGO_PROP_SESPROP`         varchar(20)   NOT NULL
                                  COMMENT 'FK fza_propiedades',
  `ESFIJO_SESPROP`              char(1)       NOT NULL DEFAULT 'N'
                                  COMMENT 'S=todas las líneas heredan obligatoriamente',
  `ID_PV_DEFECTO_SESPROP`       int(11)       DEFAULT NULL
                                  COMMENT 'Si tipo LISTA, FK fza_propiedades_valores',
  `VALOR_DEFECTO_SESPROP`       varchar(255)  DEFAULT NULL
                                  COMMENT 'Si tipo TEXTO/NUMERO/BOOL',
  `ORDEN_SESPROP`               int(11)       NOT NULL DEFAULT 0,

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,

  PRIMARY KEY (`SERIE_SES_SESPROP`, `NUMERO_SES_SESPROP`, `CODIGO_PROP_SESPROP`),
  INDEX `IDX_SESPROP_PROP` (`CODIGO_PROP_SESPROP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 3. Kits de cantidades (cabecera + detalle)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_kits` (
  `SERIE_SES_SESKIT`            varchar(12)   NOT NULL,
  `NUMERO_SES_SESKIT`           varchar(12)   NOT NULL,
  `CODIGO_SESKIT`               varchar(20)   NOT NULL
                                  COMMENT 'CURVA-STD, MUESTRA, etc.',
  `NOMBRE_SESKIT`               varchar(100)  NOT NULL,
  `DESCRIPCION_SESKIT`          varchar(255)  DEFAULT NULL,
  `ID_VA_DESTINO_SESKIT`        varchar(20)   NOT NULL
                                  COMMENT 'Atributo destino del kit, normalmente el pivot (TAL)',
  `CODIGO_PRV_SESKIT`           varchar(20)   DEFAULT NULL
                                  COMMENT 'Si el kit nace de plantilla del proveedor',
  `ORDEN_SESKIT`                int(11)       NOT NULL DEFAULT 0,

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,
  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`SERIE_SES_SESKIT`, `NUMERO_SES_SESKIT`, `CODIGO_SESKIT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_kits_det` (
  `SERIE_SES_SESKITD`           varchar(12)   NOT NULL,
  `NUMERO_SES_SESKITD`          varchar(12)   NOT NULL,
  `CODIGO_SESKIT_SESKITD`       varchar(20)   NOT NULL,
  `VALOR_DESTINO_SESKITD`       varchar(50)   NOT NULL
                                  COMMENT 'Valor del atributo destino: "38", "M", etc.',
  `CANTIDAD_SESKITD`            decimal(19,6) NOT NULL DEFAULT 0,
  `ORDEN_SESKITD`               int(11)       NOT NULL DEFAULT 0,

  PRIMARY KEY (`SERIE_SES_SESKITD`, `NUMERO_SES_SESKITD`,
               `CODIGO_SESKIT_SESKITD`, `VALOR_DESTINO_SESKITD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 4. Líneas (un artículo tentativo cada una)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_lineas` (
  `SERIE_SES_SESLIN`            varchar(12)   NOT NULL,
  `NUMERO_SES_SESLIN`           varchar(12)   NOT NULL,
  `LINEA_SESLIN`                int(11)       NOT NULL,

  -- Artículo tentativo
  `CODIGO_ART_TENTATIVO_SESLIN` varchar(20)   NOT NULL
                                  COMMENT 'Lo que el usuario teclea; se valida contra fza_articulos',
  `DESCRIPCION_SESLIN`          varchar(1000) NOT NULL,
  `CODIGO_FAM_SESLIN`           varchar(20)   DEFAULT NULL
                                  COMMENT 'Override sobre la familia de cabecera; null = hereda',
  `TIPO_LINEA_SESLIN`           varchar(10)   NOT NULL DEFAULT 'MATRIZ'
                                  COMMENT 'MATRIZ | ESCALAR | SERVICIO | KIT',
  `TIPO_ART_SESLIN`             varchar(10)   NOT NULL DEFAULT 'ESTANDAR'
                                  COMMENT 'Derivado de TIPO_LINEA: SERVICIO=>SERVICIO, KIT=>KIT, resto=>ESTANDAR',
  `TIPO_IVA_SESLIN`             varchar(2)    DEFAULT NULL
                                  COMMENT 'Override sobre cabecera',
  `TIPO_CANTIDAD_SESLIN`        varchar(20)   NOT NULL DEFAULT 'Uds',
  `ESTRAZABLE_SESLIN`           char(1)       NOT NULL DEFAULT 'N',

  -- Override de variación por línea (sólo aplica si ESVAR_FIJA_SES='N' en cabecera)
  `CODIGO_VAR_SESLIN`           varchar(20)   DEFAULT NULL
                                  COMMENT 'Override sobre cabecera, null = hereda',
  `ID_VA_PIVOT_SESLIN`          varchar(20)   DEFAULT NULL,
  `ID_AC_PIVOT_SESLIN`          int(11)       DEFAULT NULL,
  `ID_VA_FILA_SESLIN`           varchar(20)   DEFAULT NULL,
  `ID_AC_FILA_SESLIN`           int(11)       DEFAULT NULL,

  -- Cantidad escalar (sólo para TIPO_LINEA = ESCALAR o SERVICIO)
  `CANTIDAD_ESCALAR_SESLIN`     decimal(19,6) DEFAULT NULL,

  -- Conflicto con artículo existente
  `ESDUPLICADO_SESLIN`          char(1)       NOT NULL DEFAULT 'N',
  `ACCION_DUPLICADO_SESLIN`     varchar(10)   DEFAULT NULL
                                  COMMENT 'REUSAR | RENOMBRAR | NULL',
  `CODIGO_ART_REUSAR_SESLIN`    varchar(20)   DEFAULT NULL
                                  COMMENT 'Si ACCION=REUSAR, código del artículo a reutilizar',

  -- Precios
  `PRECIO_COMPRA_SESLIN`        decimal(19,6) NOT NULL DEFAULT 0,
  `PORCENTAJE_MARGEN_SESLIN`    decimal(7,4)  DEFAULT NULL,
  `PRECIO_VENTA_SESLIN`         decimal(19,6) DEFAULT NULL
                                  COMMENT 'Calculado pero override-able',
  `REF_PRV_SESLIN`              varchar(100)  DEFAULT NULL,

  -- Calculado
  `TOTAL_UNIDADES_SESLIN`       decimal(19,6) NOT NULL DEFAULT 0
                                  COMMENT 'Suma de celdas (read-only, lo refresca el form)',
  `TOTAL_LINEA_SESLIN`          decimal(19,6) NOT NULL DEFAULT 0
                                  COMMENT 'TOTAL_UNIDADES * PRECIO_COMPRA',

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,
  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`SERIE_SES_SESLIN`, `NUMERO_SES_SESLIN`, `LINEA_SESLIN`),
  INDEX `IDX_SESLIN_ART_TENT` (`CODIGO_ART_TENTATIVO_SESLIN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 5. Filas de la matriz por línea (combinación de atributos no-pivot)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_lineas_filas` (
  `SERIE_SES_SESFIL`            varchar(12)   NOT NULL,
  `NUMERO_SES_SESFIL`           varchar(12)   NOT NULL,
  `LINEA_SES_SESFIL`            int(11)       NOT NULL,
  `ID_FILA_SESFIL`              int(11)       NOT NULL
                                  COMMENT 'Numerador 1..N dentro de la línea',
  `ORDEN_SESFIL`                int(11)       NOT NULL DEFAULT 0,
  `ETIQUETA_TEXTO_SESFIL`       varchar(100)  DEFAULT NULL
                                  COMMENT 'Etiqueta libre tecleada por el usuario cuando la sesión usa eje fila libre (ID_AC_FILA_SES IS NULL). En modo conjunto la etiqueta viene de _filas_atr.',

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,

  PRIMARY KEY (`SERIE_SES_SESFIL`, `NUMERO_SES_SESFIL`,
               `LINEA_SES_SESFIL`, `ID_FILA_SESFIL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Valores de atributo que distinguen cada fila (uno o varios).
-- Caso típico: una sola entrada por fila: ID_VA = 'CO', VALOR = 'NEGRO'.
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_lineas_filas_atr` (
  `SERIE_SES_SESFILAT`          varchar(12)   NOT NULL,
  `NUMERO_SES_SESFILAT`         varchar(12)   NOT NULL,
  `LINEA_SES_SESFILAT`          int(11)       NOT NULL,
  `ID_FILA_SESFILAT`            int(11)       NOT NULL,
  `ID_VA_SESFILAT`              varchar(20)   NOT NULL
                                  COMMENT 'Atributo: CO, MAT, TEMP...',
  `ID_AV_SESFILAT`              int(11)       NOT NULL
                                  COMMENT 'FK fza_atributos_valores',

  PRIMARY KEY (`SERIE_SES_SESFILAT`, `NUMERO_SES_SESFILAT`,
               `LINEA_SES_SESFILAT`, `ID_FILA_SESFILAT`, `ID_VA_SESFILAT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 6. Celdas de la matriz: cantidad por (línea, fila, valor pivot, almacén)
-- ---------------------------------------------------------------------------
-- La dimensión de almacén permite que una misma sesión genere varios
-- albaranes de compra (uno por almacén destino) sin perder la trazabilidad
-- talla×color por almacén. El pedido de compra al proveedor sigue siendo
-- único — agrega cantidades de todos los almacenes por SKU.
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_celdas` (
  `SERIE_SES_SESCEL`            varchar(12)   NOT NULL,
  `NUMERO_SES_SESCEL`           varchar(12)   NOT NULL,
  `LINEA_SES_SESCEL`            int(11)       NOT NULL,
  `ID_FILA_SES_SESCEL`          int(11)       NOT NULL,
  `ID_AV_PIVOT_SESCEL`          int(11)       NOT NULL
                                  COMMENT 'FK fza_atributos_valores del eje pivot (TALLA)',
  `CODIGO_ALM_SESCEL`           varchar(10)   NOT NULL DEFAULT ''
                                  COMMENT 'Almacén destino (FK fza_almacenes). '''' = usa el de cabecera al materializar.',
  `CANTIDAD_SESCEL`             decimal(19,6) NOT NULL,

  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`SERIE_SES_SESCEL`, `NUMERO_SES_SESCEL`,
               `LINEA_SES_SESCEL`, `ID_FILA_SES_SESCEL`,
               `ID_AV_PIVOT_SESCEL`, `CODIGO_ALM_SESCEL`),
  INDEX `IDX_SESCEL_AV_PIVOT` (`ID_AV_PIVOT_SESCEL`),
  INDEX `IDX_SESCEL_ALM`      (`CODIGO_ALM_SESCEL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Migración idempotente: añadir CODIGO_ALM_SESCEL en bases que ya tienen
-- la tabla creada con el PK antiguo. Si la columna ya existe, no toca nada.
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_celdas'
     AND COLUMN_NAME  = 'CODIGO_ALM_SESCEL'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_celdas` '
  'ADD COLUMN `CODIGO_ALM_SESCEL` varchar(10) NOT NULL DEFAULT '''' '
  '  AFTER `ID_AV_PIVOT_SESCEL`, '
  'DROP PRIMARY KEY, '
  'ADD PRIMARY KEY (`SERIE_SES_SESCEL`, `NUMERO_SES_SESCEL`, '
  '                 `LINEA_SES_SESCEL`, `ID_FILA_SES_SESCEL`, '
  '                 `ID_AV_PIVOT_SESCEL`, `CODIGO_ALM_SESCEL`), '
  'ADD INDEX `IDX_SESCEL_ALM` (`CODIGO_ALM_SESCEL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 7. Override de propiedades variables por línea
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_lineas_props` (
  `SERIE_SES_SESLPROP`          varchar(12)   NOT NULL,
  `NUMERO_SES_SESLPROP`         varchar(12)   NOT NULL,
  `LINEA_SES_SESLPROP`          int(11)       NOT NULL,
  `CODIGO_PROP_SESLPROP`        varchar(20)   NOT NULL,
  `ID_PV_SESLPROP`              int(11)       DEFAULT NULL,
  `VALOR_LIBRE_SESLPROP`        varchar(255)  DEFAULT NULL,

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,

  PRIMARY KEY (`SERIE_SES_SESLPROP`, `NUMERO_SES_SESLPROP`,
               `LINEA_SES_SESLPROP`, `CODIGO_PROP_SESLPROP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 7-bis. Override de precio por SKU (coste y venta)
-- ---------------------------------------------------------------------------
-- Cuando una linea necesita precio distinto en una talla/color concretos,
-- aqui se sobreescribe. Si no hay fila para un SKU, se usan los precios
-- de la linea (PRECIO_COMPRA_SESLIN / PRECIO_VENTA_SESLIN).
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_lineas_skus_precios` (
  `SERIE_SES_SESLINSKU`         varchar(12)   NOT NULL,
  `NUMERO_SES_SESLINSKU`        varchar(12)   NOT NULL,
  `LINEA_SES_SESLINSKU`         int(11)       NOT NULL,
  `ID_FILA_SES_SESLINSKU`       int(11)       NOT NULL,
  `ID_AV_PIVOT_SESLINSKU`       int(11)       NOT NULL,
  `PRECIO_COMPRA_SESLINSKU`     decimal(19,6) DEFAULT NULL
                                  COMMENT 'Override del precio de coste para este SKU. NULL = hereda de la linea.',
  `PRECIO_VENTA_SESLINSKU`      decimal(19,6) DEFAULT NULL
                                  COMMENT 'Override del precio de venta para este SKU. NULL = hereda de la linea.',

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,
  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`SERIE_SES_SESLINSKU`, `NUMERO_SES_SESLINSKU`,
               `LINEA_SES_SESLINSKU`, `ID_FILA_SES_SESLINSKU`,
               `ID_AV_PIVOT_SESLINSKU`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 7-ter. Documentos materializados por la sesion (N pedidos + N albaranes)
-- ---------------------------------------------------------------------------
-- La sesion puede generar varios documentos al materializarse, uno por
-- almacen con cantidad > 0 (tanto pedidos como albaranes). La cabecera
-- guarda SERIE_PEDC_SES/NUMERO_PEDC_SES y SERIE_ALBC_SES/NUMERO_ALBC_SES
-- como referencia al primero de cada tipo (util para listados rapidos).
-- Esta tabla guarda la lista completa.
CREATE TABLE IF NOT EXISTS `fza_compras_sesiones_documentos` (
  `SERIE_SES_SESDOC`            varchar(12)   NOT NULL,
  `NUMERO_SES_SESDOC`           varchar(12)   NOT NULL,
  `TIPO_DOC_SESDOC`             varchar(4)    NOT NULL
                                  COMMENT 'PEDC = pedido de compra, ALBC = albaran de compra',
  `CODIGO_ALM_SESDOC`           varchar(10)   NOT NULL
                                  COMMENT 'Almacen al que aplica este documento',
  `SERIE_SESDOC`                varchar(12)   NOT NULL
                                  COMMENT 'Serie del documento generado (fza_pedidos_compra / _albaranes)',
  `NUMERO_SESDOC`               varchar(12)   NOT NULL
                                  COMMENT 'Numero del documento generado',

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,

  PRIMARY KEY (`SERIE_SES_SESDOC`, `NUMERO_SES_SESDOC`,
               `TIPO_DOC_SESDOC`, `CODIGO_ALM_SESDOC`),
  INDEX `IDX_SESDOC_DOC` (`TIPO_DOC_SESDOC`, `SERIE_SESDOC`, `NUMERO_SESDOC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 8. Vistas auxiliares para el formulario
-- ---------------------------------------------------------------------------

-- Resumen de cada sesión: nº de líneas, nº de SKUs potenciales, total.
CREATE OR REPLACE VIEW `VI_SES_RESUMEN` AS
SELECT
  S.`SERIE_SES`,
  S.`NUMERO_SES`,
  S.`FECHA_SES`,
  S.`CODIGO_PRV_SES`,
  S.`CODIGO_FAM_SES`,
  S.`ESTADO_SES`,
  (SELECT COUNT(*) FROM `fza_compras_sesiones_lineas` L
    WHERE L.`SERIE_SES_SESLIN`  = S.`SERIE_SES`
      AND L.`NUMERO_SES_SESLIN` = S.`NUMERO_SES`) AS NUM_LINEAS,
  (SELECT COUNT(*) FROM `fza_compras_sesiones_celdas` C
    WHERE C.`SERIE_SES_SESCEL`  = S.`SERIE_SES`
      AND C.`NUMERO_SES_SESCEL` = S.`NUMERO_SES`
      AND C.`CANTIDAD_SESCEL`   > 0) AS NUM_SKUS_POTENCIALES,
  (SELECT IFNULL(SUM(L.`TOTAL_LINEA_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` L
    WHERE L.`SERIE_SES_SESLIN`  = S.`SERIE_SES`
      AND L.`NUMERO_SES_SESLIN` = S.`NUMERO_SES`) AS TOTAL_COMPRA
FROM `fza_compras_sesiones` S;

-- Detalle "explotado" para previsualizar qué SKUs se materializarán.
-- Incluye el almacén destino (resuelto a cabecera si la celda lo tiene vacío).
CREATE OR REPLACE VIEW `VI_SES_PREVIEW_SKUS` AS
SELECT
  L.`SERIE_SES_SESLIN`           AS SERIE,
  L.`NUMERO_SES_SESLIN`          AS NUMERO,
  L.`LINEA_SESLIN`               AS LINEA,
  L.`CODIGO_ART_TENTATIVO_SESLIN` AS CODIGO_ART,
  L.`DESCRIPCION_SESLIN`         AS DESCRIPCION,
  C.`ID_FILA_SES_SESCEL`         AS ID_FILA,
  C.`ID_AV_PIVOT_SESCEL`         AS ID_AV_PIVOT,
  AVP.`AV`                       AS VALOR_PIVOT,
  IF(C.`CODIGO_ALM_SESCEL` = '', S.`CODIGO_ALM_SES`, C.`CODIGO_ALM_SESCEL`)
                                 AS CODIGO_ALM,
  C.`CANTIDAD_SESCEL`            AS CANTIDAD,
  L.`PRECIO_COMPRA_SESLIN`       AS PRECIO_COMPRA,
  L.`PRECIO_VENTA_SESLIN`        AS PRECIO_VENTA
FROM `fza_compras_sesiones_lineas`   L
JOIN `fza_compras_sesiones`          S
  ON S.`SERIE_SES`         = L.`SERIE_SES_SESLIN`
 AND S.`NUMERO_SES`        = L.`NUMERO_SES_SESLIN`
JOIN `fza_compras_sesiones_celdas`   C
  ON C.`SERIE_SES_SESCEL`  = L.`SERIE_SES_SESLIN`
 AND C.`NUMERO_SES_SESCEL` = L.`NUMERO_SES_SESLIN`
 AND C.`LINEA_SES_SESCEL`  = L.`LINEA_SESLIN`
JOIN `fza_atributos_valores`         AVP
  ON AVP.`ID_AV`           = C.`ID_AV_PIVOT_SESCEL`
WHERE C.`CANTIDAD_SESCEL`  > 0;

-- Resumen agregado por almacén para la pestaña Materialización.
CREATE OR REPLACE VIEW `VI_SES_RESUMEN_ALMACEN` AS
SELECT
  C.`SERIE_SES_SESCEL`           AS SERIE,
  C.`NUMERO_SES_SESCEL`          AS NUMERO,
  IF(C.`CODIGO_ALM_SESCEL` = '', S.`CODIGO_ALM_SES`, C.`CODIGO_ALM_SESCEL`)
                                 AS CODIGO_ALM,
  COUNT(*)                       AS NUM_SKUS,
  SUM(C.`CANTIDAD_SESCEL`)       AS UNIDADES_TOTAL
FROM `fza_compras_sesiones_celdas` C
JOIN `fza_compras_sesiones`        S
  ON S.`SERIE_SES`         = C.`SERIE_SES_SESCEL`
 AND S.`NUMERO_SES`        = C.`NUMERO_SES_SESCEL`
WHERE C.`CANTIDAD_SESCEL`  > 0
GROUP BY C.`SERIE_SES_SESCEL`, C.`NUMERO_SES_SESCEL`,
         IF(C.`CODIGO_ALM_SESCEL` = '', S.`CODIGO_ALM_SES`, C.`CODIGO_ALM_SESCEL`);

-- ---------------------------------------------------------------------------
-- 8-bis. Plantillas globales de cabecera (reutilizables al crear sesión)
-- ---------------------------------------------------------------------------
-- Permite guardar una configuración de cabecera + propiedades + kits con un
-- nombre y reutilizarla al crear sesiones nuevas. Sufijos: SESPL / SESPLPROP /
-- SESPLKIT / SESPLKITD.

CREATE TABLE IF NOT EXISTS `fza_compras_plantillas` (
  `CODIGO_SESPL`                varchar(20)   NOT NULL,
  `NOMBRE_SESPL`                varchar(100)  NOT NULL,
  `DESCRIPCION_SESPL`           varchar(255)  DEFAULT NULL,
  `CODIGO_PRV_SESPL`            varchar(20)   DEFAULT NULL
                                  COMMENT 'Plantilla específica de proveedor; null = global',
  `CODIGO_FAM_SESPL`            varchar(20)   DEFAULT NULL,
  `TIPO_IVA_SESPL`              varchar(2)    DEFAULT NULL,
  `PORCENTAJE_MARGEN_SESPL`     decimal(7,4)  DEFAULT NULL,
  `CODIGO_TAR_SESPL`            varchar(20)   DEFAULT NULL,
  `CODIGO_VAR_SESPL`            varchar(20)   DEFAULT NULL,
  `ID_VA_PIVOT_SESPL`           varchar(20)   DEFAULT NULL,
  `ID_AC_PIVOT_SESPL`           int(11)       DEFAULT NULL,
  `ID_VA_FILA_SESPL`            varchar(20)   DEFAULT NULL,
  `ID_AC_FILA_SESPL`            int(11)       DEFAULT NULL,
  `ESVAR_FIJA_SESPL`            char(1)       NOT NULL DEFAULT 'N',
  `ESACTIVA_SESPL`              char(1)       NOT NULL DEFAULT 'S',

  `INSTANTE_ALTA`               datetime      NOT NULL,
  `USUARIO_ALTA`                varchar(50)   NOT NULL,
  `INSTANTE_MODIF`              datetime      DEFAULT NULL,
  `USUARIO_MODIF`               varchar(50)   DEFAULT NULL,

  PRIMARY KEY (`CODIGO_SESPL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_compras_plantillas_props` (
  `CODIGO_SESPL_SESPLPROP`      varchar(20)   NOT NULL,
  `CODIGO_PROP_SESPLPROP`       varchar(20)   NOT NULL,
  `ESFIJO_SESPLPROP`            char(1)       NOT NULL DEFAULT 'N',
  `ID_PV_DEFECTO_SESPLPROP`     int(11)       DEFAULT NULL,
  `VALOR_DEFECTO_SESPLPROP`     varchar(255)  DEFAULT NULL,
  `ORDEN_SESPLPROP`             int(11)       NOT NULL DEFAULT 0,

  PRIMARY KEY (`CODIGO_SESPL_SESPLPROP`, `CODIGO_PROP_SESPLPROP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_compras_plantillas_kits` (
  `CODIGO_SESPL_SESPLKIT`       varchar(20)   NOT NULL,
  `CODIGO_SESPLKIT`             varchar(20)   NOT NULL,
  `NOMBRE_SESPLKIT`             varchar(100)  NOT NULL,
  `ID_VA_DESTINO_SESPLKIT`      varchar(20)   NOT NULL,
  `ORDEN_SESPLKIT`              int(11)       NOT NULL DEFAULT 0,

  PRIMARY KEY (`CODIGO_SESPL_SESPLKIT`, `CODIGO_SESPLKIT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_compras_plantillas_kits_det` (
  `CODIGO_SESPL_SESPLKITD`      varchar(20)   NOT NULL,
  `CODIGO_SESPLKIT_SESPLKITD`   varchar(20)   NOT NULL,
  `VALOR_DESTINO_SESPLKITD`     varchar(50)   NOT NULL,
  `CANTIDAD_SESPLKITD`          decimal(19,6) NOT NULL DEFAULT 0,
  `ORDEN_SESPLKITD`             int(11)       NOT NULL DEFAULT 0,

  PRIMARY KEY (`CODIGO_SESPL_SESPLKITD`,
               `CODIGO_SESPLKIT_SESPLKITD`,
               `VALOR_DESTINO_SESPLKITD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------------
-- 9. Contador propio
-- ---------------------------------------------------------------------------
-- Inserción esperada en fza_contadores para numerar sesiones:
--
-- INSERT INTO fza_contadores (CODIGO_CON, TIPO_DOC_CON, ULTIMO_CON, ...)
-- VALUES ('SESCOMPRA', 'SESCOMPRA', 0, ...);
--
-- Y otro para el prefijo EAN13 si la sesión no define uno propio.

-- ---------------------------------------------------------------------------
-- 10. NOTAS sobre la materialización
-- ---------------------------------------------------------------------------
-- Estas tablas NO tienen triggers que toquen fza_articulos*, fza_codigos_barras
-- ni fza_articulos_proveedores. La materialización es un procedimiento Delphi
-- ubicado en `src/Lib/inLibComprasSesionesMaterializar.pas` que dentro de una
-- única TUniTransaction:
--
--   1. Verifica conflictos contra fza_articulos.
--   2. Para cada línea no marcada como REUSAR:
--        INSERT INTO fza_articulos (...)
--        INSERT INTO fza_articulos_conjuntos_asign (...)   (pivot + fila)
--        Para cada propiedad fija de cabecera y variable de línea:
--           INSERT INTO fza_articulos_propiedades (...)
--   3. Para cada celda con CANTIDAD > 0:
--        INSERT INTO fza_articulos_skus (...)
--        INSERT INTO fza_atributos_sku (...)   (uno por atributo de fila + pivot)
--        INSERT INTO fza_codigos_barras (CODIGO_BARRAS_CB generado por inLibEAN13)
--   4. Upsert en fza_articulos_proveedores con precio último y ref.
--   5. Si ESGENERA_PEDIDO_SES = 'S':
--        INSERT en fza_pedidos_compra + lineas (uno por SKU * cantidad agregada).
--   6. Si ESGENERA_ALBARAN_SES = 'S':
--        INSERT en fza_albaranes_compra + lineas + fza_movimientos_almacen.
--   7. UPDATE fza_compras_sesiones SET ESTADO_SES='CERRADA',
--          referencia_pedido, referencia_albaran, instante/usuario_materializa.
--
-- Cualquier fallo → ROLLBACK. La sesión sigue en BORRADOR con
-- MENSAJE_ERROR_SES poblado.
