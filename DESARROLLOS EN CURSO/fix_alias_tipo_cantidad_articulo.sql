-- ============================================================================
--  Fix typo alias TIPO_CATNTIDAD_ARTICULO -> TIPO_CANTIDAD_ARTICULO
-- ----------------------------------------------------------------------------
--  La vista vi_proveedores_articulos exponia la columna real
--  TIPO_CANTIDAD_ART bajo un alias con typo: TIPO_CATNTIDAD_ARTICULO.
--  El binding del Mto de Proveedores (inMtoProveedores.dfm/.pas) viajaba
--  fiel al alias con typo, segun §1.5 del libro de estilo Delphi
--  ("los nombres SQL viajan tal cual").
--
--  Tras arreglar el codigo (cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO +
--  DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO'), la vista tambien
--  debe reflejar el alias sin typo para que el binding encuentre la
--  columna en tiempo de ejecucion.
--
--  Cambia solo el alias (AS); la columna real TIPO_CANTIDAD_ART en
--  fza_articulos no se toca.
--
--  Idempotente: re-crea la vista de cero.
-- ============================================================================

DROP VIEW IF EXISTS `vi_proveedores_articulos`;

CREATE ALGORITHM=UNDEFINED VIEW `vi_proveedores_articulos` AS
SELECT
  `fza_articulos_proveedores`.`CODIGO_PRV_AP`           AS `CODIGO_PRV_PRV`,
  `fza_articulos_proveedores`.`CODIGO_ART_AP`           AS `CODIGO_ART_ART`,
  `vi_articulos`.`DESCRIPCION_ART`                      AS `DESCRIPCION_ART`,
  `vi_articulos`.`CODIGO_FAM_ART`                       AS `CODIGO_FAM_FAM`,
  `vi_articulos`.`DESCRIPCION_FAM`                      AS `DESCRIPCION_FAM`,
  `vi_articulos`.`TIPO_CANTIDAD_ART`                    AS `TIPO_CANTIDAD_ARTICULO`,
  `vi_articulos`.`ESACTIVO_FIJO_ART`                    AS `ESACTIVO_FIJO_ART`,
  `fza_articulos_proveedores`.`PRECIO_ULT_COMPRA_AP`    AS `PRECIO_ULT_COMPRA`,
  `fza_articulos_proveedores`.`FECHA_VALIDEZ_AP`        AS `FECHA_VALIDEZ`,
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_AP` AS `ESPROVEEDORPRINCIPAL`,
  `fza_articulos_proveedores`.`INSTANTE_MODIF`          AS `INSTANTE_MODIF`,
  `fza_articulos_proveedores`.`INSTANTE_ALTA`           AS `INSTANTE_ALTA`,
  `fza_articulos_proveedores`.`USUARIO_ALTA`            AS `USUARIO_ALTA`,
  `fza_articulos_proveedores`.`USUARIO_MODIF`           AS `USUARIO_MODIF`
FROM `fza_articulos_proveedores`
LEFT JOIN `vi_articulos`
  ON `fza_articulos_proveedores`.`CODIGO_ART_AP` = `vi_articulos`.`CODIGO_ART_ART`;

-- Verificacion (opcional, ejecutar despues):
-- SHOW CREATE VIEW vi_proveedores_articulos\G
-- SELECT TIPO_CANTIDAD_ARTICULO FROM vi_proveedores_articulos LIMIT 1;
