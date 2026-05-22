-- ============================================================================
-- Compras / sesiones — auto-resolver duplicados como REUSAR
--
-- Para sesiones en BORRADOR cuyas lineas tienen ESDUPLICADO_SESLIN='S'
-- (codigo de articulo tentativo coincide con un fza_articulos existente)
-- pero no tienen ACCION_DUPLICADO_SESLIN resuelta, marcamos REUSAR por
-- defecto apuntando al articulo existente.
--
-- Es lo que hace ahora el BeforePost del Mto para lineas nuevas; este
-- script es la migracion para datos ya grabados antes del fix.
--
-- Es seguro re-ejecutarlo: solo actua sobre lineas con accion vacia.
-- Solo toca sesiones en BORRADOR (las CERRADA / ANULADA no se tocan).
-- ============================================================================

UPDATE `fza_compras_sesiones_lineas` L
  JOIN `fza_compras_sesiones`   S
    ON S.`SERIE_SES`  = L.`SERIE_SES_SESLIN`
   AND S.`NUMERO_SES` = L.`NUMERO_SES_SESLIN`
  JOIN `fza_articulos`          A
    ON A.`CODIGO_ART_ART` = L.`CODIGO_ART_TENTATIVO_SESLIN`
   AND A.`ESACTIVO_ART`   = 'S'
   SET L.`ACCION_DUPLICADO_SESLIN`  = 'REUSAR',
       L.`CODIGO_ART_REUSAR_SESLIN` = L.`CODIGO_ART_TENTATIVO_SESLIN`,
       L.`ESDUPLICADO_SESLIN`       = 'S',
       L.`INSTANTE_MODIF`           = NOW(),
       L.`USUARIO_MODIF`            = COALESCE(L.`USUARIO_MODIF`,
                                                'Administrador')
 WHERE S.`ESTADO_SES` = 'BORRADOR'
   AND L.`ESDUPLICADO_SESLIN`       = 'S'
   AND (L.`ACCION_DUPLICADO_SESLIN` IS NULL
        OR TRIM(L.`ACCION_DUPLICADO_SESLIN`) = '');
