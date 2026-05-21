-- ============================================================================
-- Compras / sesiones — auto-resolver duplicados como REUSAR
-- (extension: articulos existentes pero inactivos)
--
-- compras_sesiones_fix_reusar.sql cubrio solo lineas cuyo articulo
-- existe y esta activo. Lineas que apuntan a articulos existentes pero
-- ESACTIVO_ART='N' quedaron sin resolver porque ValidarSesion las
-- bloquea igualmente. Aqui marcamos REUSAR tambien para inactivos sin
-- tocar fza_articulos.ESACTIVO_ART (la decision de reactivar el
-- articulo se deja al usuario, fuera del flujo de la sesion).
--
-- Idempotente: solo actua sobre lineas con accion vacia.
-- Solo sesiones en BORRADOR.
-- ============================================================================

UPDATE `fza_compras_sesiones_lineas` L
  JOIN `fza_compras_sesiones`   S
    ON S.`SERIE_SES`  = L.`SERIE_SES_SESLIN`
   AND S.`NUMERO_SES` = L.`NUMERO_SES_SESLIN`
  JOIN `fza_articulos`          A
    ON A.`CODIGO_ART_ART` = L.`CODIGO_ART_TENTATIVO_SESLIN`
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
