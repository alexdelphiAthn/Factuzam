-- =============================================================================
-- Fix CONTADOR_LINEAS_SES en fza_compras_sesiones
-- =============================================================================
-- Sincroniza el contador de lineas de la cabecera con la ultima LINEA real
-- almacenada en fza_compras_sesiones_lineas. Repara sesiones donde el
-- contador quedo por debajo del MAX(LINEA_SESLIN) por desync master/detail.
--
-- Caso clasico que dejaba el contador colgado:
--   1. Master cargado con CONTADOR=110, max LINEA=110.
--   2. Add -> AfterInsert pone CONTADOR=120 (memoria) y LINEA=120 (memoria).
--   3. Navegacion -> detail.Post implicito persiste LINEA=120 en BD.
--   4. Usuario cancela el master -> CONTADOR rollback a 110 (BD), pero
--      linea 120 sigue persistida.
--   5. Siguiente Add reasignaba CONTADOR+10=120 -> colision con PK
--      (SERIE_SES_SESLIN, NUMERO_SES_SESLIN, LINEA_SESLIN).
--
-- El nuevo helper inLibContadorLineas.GetSiguienteLineaDoc hace el UPDATE
-- atomico contra BD, asi que el problema no puede repetirse para nuevas
-- sesiones. Este script repara las que ya quedaron con el contador
-- desincronizado en su momento.
--
-- Idempotente: se puede ejecutar varias veces sin efectos secundarios.
-- =============================================================================

UPDATE fza_compras_sesiones AS S
   JOIN (
       SELECT SERIE_SES_SESLIN,
              NUMERO_SES_SESLIN,
              MAX(LINEA_SESLIN) AS ULTIMA_LINEA
         FROM fza_compras_sesiones_lineas
        GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN
   ) AS L
     ON L.SERIE_SES_SESLIN  = S.SERIE_SES
    AND L.NUMERO_SES_SESLIN = S.NUMERO_SES
  SET S.CONTADOR_LINEAS_SES = L.ULTIMA_LINEA
WHERE S.CONTADOR_LINEAS_SES IS NULL
   OR S.CONTADOR_LINEAS_SES < L.ULTIMA_LINEA;
