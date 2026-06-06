-- ============================================================================
--  Fix caption 'CANTIDAD_ARTVIN' -> 'Cantidad' en personalizaciones de rejilla
-- ----------------------------------------------------------------------------
--  Durante el renombrado de columnas (src/utilnormbbdd/cambios3) la regla
--  'CANTIDAD' -> 'CANTIDAD_ARTVIN' (sufijo de fza_articulos_vinculos, la
--  unica tabla con una columna 'CANTIDAD' a secas) se aplico de mas y dejo
--  ese literal pegado como TEXTO de caption en sitios que pertenecen a otra
--  tabla (lineas de factura -> FACLIN, movimientos -> MOV, etc.).
--
--  IMPORTANTE: al abrir un formulario, inLibDevExp restaura el layout de la
--  rejilla con prioridad  perfil de usuario > fza_config_campos > DFM. El
--  caption que ve el usuario vive en fza_usuarios_perfiles (SUBKEY_USUPER
--  = 'tvXxx_COLUMNA_Caption', valor en VALUE_USUPER) y PISA al DFM. Por eso
--  recompilar no cambia lo que se ve: hay que corregir la BBDD.
--
--  Un unico UPDATE con REPLACE sobre la subcadena cubre todas las variantes
--  ('CANTIDAD_ARTVIN', 'Tipo CANTIDAD_ARTVIN', 'Tipo de CANTIDAD_ARTVIN'...)
--  y todos los usuarios/formularios de la BBDD, no solo los del dump modelo.
--
--  Idempotente: re-ejecutable. Tras la primera pasada ya no queda la
--  subcadena 'CANTIDAD_ARTVIN' y el WHERE no machea ninguna fila.
-- ============================================================================
UPDATE fza_usuarios_perfiles
   SET VALUE_USUPER = REPLACE(VALUE_USUPER, 'CANTIDAD_ARTVIN', 'Cantidad')
 WHERE SUBKEY_USUPER LIKE '%Caption'
   AND VALUE_USUPER  LIKE '%CANTIDAD_ARTVIN%';
-- Verificacion (opcional, ejecutar despues): no debe devolver filas.
-- SELECT KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER
--   FROM fza_usuarios_perfiles
--  WHERE VALUE_USUPER LIKE '%CANTIDAD_ARTVIN%';
