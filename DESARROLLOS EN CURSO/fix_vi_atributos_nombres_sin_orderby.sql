-- ============================================================================
-- Fix vi_atributos_nombres: quitar ORDER BY + DISTINCT del cuerpo de la vista
-- ============================================================================
-- La definicion original (volcada en factuzam_original.sql) era:
--
--   CREATE ALGORITHM=UNDEFINED VIEW vi_atributos_nombres AS
--     SELECT DISTINCT
--       ask.CODIGO_ART_SKU AS CODIGO_ART_PADRE_ARTVIN,
--       vat.ID_ATB_VA      AS ID_ATRIBUTO,
--       vat.NOMBRE_VA      AS NOMBRE_ATRIBUTO,
--       vat.ORDEN_VA       AS ORDEN_VISUAL_ATRIBUTO
--     FROM fza_articulos_skus ask
--     JOIN fza_variaciones_atributos vat ON vat.ID_VAR_VA = ask.CODIGO_VAR_SKU
--     ORDER BY ask.CODIGO_ART_SKU, vat.ORDEN_VA;
--
-- El ORDER BY (y en menor medida el DISTINCT) fuerza al optimizador de MariaDB
-- a materializar TODA la vista antes de aplicar el WHERE externo, en lugar de
-- empujar el predicado a fza_articulos_skus.CODIGO_ART_SKU (que esta indexado
-- por IDX_SKU_ART_ACT). Un EXPLAIN sobre la definicion mostraba
--
--     ask  type=ALL  rows=434996  Extra="Using where; Using join buffer (BNL)"
--
-- y la SQL del inMtoInventarios.unqryDefinicionArticulo tardaba >6 s por
-- llamada (se llama 1-2 veces al elegir un articulo, total ~13 s).
--
-- Quitando ORDER BY + DISTINCT:
--   * El ORDER BY del cliente (LIMIT 5) sigue funcionando porque cada query
--     externa ya lo pone (ver unqryDefinicionArticulo en
--     UniDataInventarios.dfm).
--   * El DISTINCT del cliente tambien sigue presente cuando hace falta.
--   * La vista pasa a ser "merge-able": MariaDB la trata como una subquery
--     transparente y empuja el WHERE hasta CODIGO_ART_SKU.
--
-- Idempotente: ALTER VIEW (CREATE OR REPLACE) sustituye la definicion
-- existente sin tocar dependencias.
-- ============================================================================

CREATE OR REPLACE VIEW vi_atributos_nombres AS
SELECT
  ask.CODIGO_ART_SKU AS CODIGO_ART_PADRE_ARTVIN,
  vat.ID_ATB_VA      AS ID_ATRIBUTO,
  vat.NOMBRE_VA      AS NOMBRE_ATRIBUTO,
  vat.ORDEN_VA       AS ORDEN_VISUAL_ATRIBUTO
FROM fza_articulos_skus ask
JOIN fza_variaciones_atributos vat
  ON vat.ID_VAR_VA = ask.CODIGO_VAR_SKU;
