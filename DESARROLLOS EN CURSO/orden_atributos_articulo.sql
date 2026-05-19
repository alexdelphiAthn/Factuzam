-- ============================================================================
--  Orden por artículo de los atributos de variación (Generar SKUs)
-- ----------------------------------------------------------------------------
--  Concepto:
--    El orden en que se concatenan los atributos al formar el código de un
--    SKU ("DEMO-CAMISA/ROJO/L") venía dado SOLO por el orden global
--    fza_variaciones_atributos.ORDEN_VA, compartido por todos los artículos
--    que usan la misma variación.
--
--    Esta ampliación añade un orden por ARTÍCULO en
--    fza_articulos_conjuntos_asign.ORDEN_ACA, de modo que cada artículo
--    pueda decidir si su Color va antes o después de la Talla sin alterar
--    el orden global ni afectar a otros artículos.
--
--  Resolución en la ventana "Generar SKUs":
--    COALESCE(NULLIF(aca.ORDEN_ACA, 0), va.ORDEN_VA)
--    → 0 = "usar ORDEN_VA global", cualquier otro valor = override.
--
--  Sentinel ID_AC_ACA = 0:
--    Para guardar un orden cuando el artículo aún no tiene conjunto
--    asignado para ese atributo se crea una fila placeholder con
--    ID_AC_ACA = 0 (ya hay precedente: el chequeo `<= 0` en el modal lo
--    trata como "sin conjunto"). Al asignar luego un conjunto real con
--    UpsertConjunto (ON DUPLICATE KEY UPDATE de ID_AC_ACA), ese campo
--    pasa a tener el ID real y ORDEN_ACA se preserva.
--
--  Idempotente. Sólo añade columna si no existe (MySQL 8.0.29+).
-- ============================================================================

ALTER TABLE `fza_articulos_conjuntos_asign`
  ADD COLUMN IF NOT EXISTS `ORDEN_ACA` int(11) NOT NULL DEFAULT 0
        COMMENT 'Orden del atributo dentro del SKU para este artículo. '
                '0 = usar fza_variaciones_atributos.ORDEN_VA global.'
        AFTER `ID_VA_ACA`;
