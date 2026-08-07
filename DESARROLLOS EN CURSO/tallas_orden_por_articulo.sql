-- SPDX-License-Identifier: MPL-2.0
-- Conserva el orden de las tallas de cada articulo procedente de
-- dbo.ocarttal.Orden. Es idempotente y no altera las asignaciones existentes.

ALTER TABLE `fza_articulos_atributos_basicos`
  ADD COLUMN IF NOT EXISTS `ORDEN_AAB` int(11) NULL DEFAULT NULL
    COMMENT 'Orden del valor dentro del articulo; en tallas procede de ocarttal.Orden.'
    AFTER `DESCRIPCION_AAB`;

-- Fallback razonable hasta volver a ejecutar la migracion articulos_tallas.
-- Esa migracion sustituye este valor global por el Orden exacto de ocarttal.
UPDATE `fza_articulos_atributos_basicos` aab
JOIN `fza_atributos_valores` av ON av.ID_AV = aab.ID_AV_AAB
   SET aab.ORDEN_AAB = av.ORDEN_AV
 WHERE av.ID_VA_AV = 'TAL'
   AND aab.ORDEN_AAB IS NULL;
