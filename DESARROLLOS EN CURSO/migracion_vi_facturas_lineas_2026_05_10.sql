-- ============================================================================
-- Migración: amplía vi_facturas_lineas para exponer CODIGO_UNIDAD_FACLIN y
--            DESCRIPCION_VARIACION_FACLIN, que ya existen en
--            fza_facturas_lineas pero la vista actual no devolvía.
-- Fecha:   2026-05-10
-- Rama:    claude/shared-pricing-library-mMIpo
--
-- Aplica este script DESPUÉS de actualizar el ejecutable a la versión que
-- añade la columna SKU al grid de facturas (inMtoFacturas) y migra el handler
-- de búsqueda a inLibArticulosValidador / inLibArticulosResolver.
--
-- Sin esta migración, las nuevas columnas SKU y "Variación" del grid quedan
-- vacías porque la vista no entrega los campos. La tabla base no cambia: caja
-- y pedidos ya escriben CODIGO_UNIDAD_FACLIN tal cual.
-- ============================================================================

START TRANSACTION;

DROP VIEW IF EXISTS `vi_facturas_lineas`;

CREATE ALGORITHM=UNDEFINED VIEW `vi_facturas_lineas` AS
SELECT
    `fza_facturas_lineas`.`NUMERO_FAC_FACLIN`              AS `NUMERO_FAC_FACLIN`,
    `fza_facturas_lineas`.`SERIE_FAC_FACLIN`               AS `SERIE_FAC_FACLIN`,
    `fza_facturas_lineas`.`LINEA_FACLIN`                   AS `LINEA_FACLIN`,
    `fza_facturas_lineas`.`CODIGO_ART_FACLIN`              AS `CODIGO_ART_FACLIN`,
    `fza_facturas_lineas`.`CODIGO_UNIDAD_FACLIN`           AS `CODIGO_UNIDAD_FACLIN`,
    `fza_facturas_lineas`.`DESCRIPCION_VARIACION_FACLIN`   AS `DESCRIPCION_VARIACION_FACLIN`,
    `fza_facturas_lineas`.`CODIGO_FAM_FACLIN`              AS `CODIGO_FAM_FACLIN`,
    `fza_facturas_lineas`.`NOMBRE_FAM_FACLIN`              AS `NOMBRE_FAM_FACLIN`,
    `fza_facturas_lineas`.`ESPROVEEDORPRINCIPAL_FACLIN`    AS `ESPROVEEDORPRINCIPAL_FACLIN`,
    `fza_facturas_lineas`.`CODIGO_PRV_FACLIN`              AS `CODIGO_PRV_FACLIN`,
    `fza_facturas_lineas`.`RAZON_SOCIAL_PROVEEDOR_FACLIN`  AS `RAZON_SOCIAL_PROVEEDOR_FACLIN`,
    `fza_facturas_lineas`.`PRECIO_ULT_COMPRA_FACLIN`       AS `PRECIO_ULT_COMPRA_FACLIN`,
    `fza_facturas_lineas`.`FECHA_ENTREGA_FACLIN`           AS `FECHA_ENTREGA_FACLIN`,
    `fza_facturas_lineas`.`TIPO_CANTIDAD_ARTICULO_FACLIN`  AS `TIPO_CANTIDAD_ARTICULO_FACLIN`,
    `fza_facturas_lineas`.`ESIMP_INCL_TARIFA_FACLIN`       AS `ESIMP_INCL_TARIFA_FACLIN`,
    `fza_facturas_lineas`.`TIPO_IVA_ARTICULO_FACLIN`       AS `TIPO_IVA_ARTICULO_FACLIN`,
    `fza_facturas_lineas`.`DESCRIPCION_ARTICULO_FACLIN`    AS `DESCRIPCION_ARTICULO_FACLIN`,
    `fza_facturas_lineas`.`CODIGO_TAR_FACLIN`              AS `CODIGO_TAR_FACLIN`,
    `fza_facturas_lineas`.`CANTIDAD_FACLIN`                AS `CANTIDAD_FACLIN`,
    `fza_facturas_lineas`.`PRECIO_SALIDA_FACLIN`           AS `PRECIO_SALIDA_FACLIN`,
    `fza_facturas_lineas`.`PORCENTAJE_DTO_FACLIN`          AS `PORCENTAJE_DTO_FACLIN`,
    `fza_facturas_lineas`.`PRECIO_DTO_FACLIN`              AS `PRECIO_DTO_FACLIN`,
    `fza_facturas_lineas`.`PRECIO_VENTA_SIVA_ARTICULO_FACLIN` AS `PRECIO_VENTA_SIVA_ARTICULO_FACLIN`,
    `fza_facturas_lineas`.`PORCENTAJE_IVA_FACLIN`          AS `PORCENTAJE_IVA_FACLIN`,
    `fza_facturas_lineas`.`PRECIO_VENTA_CIVA_ARTICULO_FACLIN` AS `PRECIO_VENTA_CIVA_ARTICULO_FACLIN`,
    `fza_facturas_lineas`.`TOTAL_FACLIN`                   AS `TOTAL_FACLIN`,
    `fza_facturas_lineas`.`TOTAL_FAC_SIVA_FACLIN`          AS `TOTAL_FAC_SIVA_FACLIN`,
    `fza_facturas_lineas`.`INSTANTE_MODIF`                 AS `INSTANTE_MODIF`,
    `fza_facturas_lineas`.`INSTANTE_ALTA`                  AS `INSTANTE_ALTA`,
    `fza_facturas_lineas`.`USUARIO_ALTA`                   AS `USUARIO_ALTA`,
    `fza_facturas_lineas`.`USUARIO_MODIF`                  AS `USUARIO_MODIF`
FROM `fza_facturas_lineas`;

-- Comprobación rápida
SELECT COLUMN_NAME
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'vi_facturas_lineas'
   AND COLUMN_NAME IN ('CODIGO_UNIDAD_FACLIN', 'DESCRIPCION_VARIACION_FACLIN');

COMMIT;
