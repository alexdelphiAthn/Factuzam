-- ============================================================================
--  Fix caption 'CANTIDAD_ARTVIN' -> 'Cantidad' en personalizaciones de rejilla
-- ----------------------------------------------------------------------------
--  Durante el renombrado de columnas (src/utilnormbbdd/cambios3) la regla
--  'CANTIDAD' -> 'CANTIDAD_ARTVIN' (sufijo de fza_articulos_vinculos, la
--  unica tabla con una columna 'CANTIDAD' a secas) se aplico de mas y dejo
--  ese literal pegado como TEXTO de caption en sitios que pertenecen a otra
--  tabla (lineas de factura -> FACLIN, movimientos -> MOV, etc.).
--
--  El binding por DataBinding.FieldName es correcto (CANTIDAD_FACLIN,
--  CANTIDAD_MOV...); lo unico erroneo es el Caption visible al usuario.
--  En el codigo (.dfm/.pas) ya se corrige; aqui se arreglan las copias que
--  cada usuario tiene persistidas en fza_usuarios_perfiles (las rejillas
--  guardan su layout: Caption, Width, Index, Visible... por SUBKEY_USUPER).
--
--  Se filtra por el VALUE erroneo y por SUBKEY terminada en 'Caption' para
--  no tocar nada mas. Cubre a todos los usuarios/formularios de la BBDD,
--  no solo los del dump modelo.
--
--  Idempotente: re-ejecutable. Tras la primera pasada el VALUE ya es
--  'Cantidad' y el WHERE no machea ninguna fila.
-- ============================================================================
UPDATE fza_usuarios_perfiles
   SET VALUE_USUPER = 'Cantidad'
 WHERE VALUE_USUPER = 'CANTIDAD_ARTVIN'
   AND SUBKEY_USUPER LIKE '%Caption';
UPDATE fza_usuarios_perfiles
   SET VALUE_USUPER = 'Tipo Cantidad'
 WHERE VALUE_USUPER = 'Tipo CANTIDAD_ARTVIN'
   AND SUBKEY_USUPER LIKE '%Caption';
UPDATE fza_usuarios_perfiles
   SET VALUE_USUPER = 'Tipo de Cantidad'
 WHERE VALUE_USUPER = 'Tipo de CANTIDAD_ARTVIN'
   AND SUBKEY_USUPER LIKE '%Caption';
-- Verificacion (opcional, ejecutar despues): no debe devolver filas.
-- SELECT KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER
--   FROM fza_usuarios_perfiles
--  WHERE VALUE_USUPER LIKE '%CANTIDAD_ARTVIN%';
