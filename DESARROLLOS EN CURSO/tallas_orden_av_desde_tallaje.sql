-- =============================================================================
-- Reordena fza_atributos_valores.ORDEN_AV de las TALLAS segun el tallaje
-- =============================================================================
-- Problema:
--   La importacion legacy (inLibMigAtributos.MigrarTallasMaestras) volcaba
--   las tallas con ORDER BY Talla (ALFABETICO) y les asignaba ORDEN_AV
--   10,20,30... en ese orden. Resultado: L=10, M=20, S=30, XL=40... En
--   cambio el tallaje (fza_atributos_conjuntos_det.ORDEN_ACD) si guarda el
--   orden real del legacy (ocgrptalnor.Columna). Como ORDEN_AV es el orden
--   que usan SKUs, dropdowns, inventario y las descripciones
--   (GROUP_CONCAT ... ORDER BY ORDEN_AV), las tallas salian desordenadas
--   aunque el tallaje estuviera bien.
--
-- Solucion:
--   Re-derivar ORDEN_AV de cada talla a partir del orden que ya tiene en
--   los tallajes (ORDEN_ACD). Para cada talla tomamos MIN(ORDEN_ACD) sobre
--   los conjuntos de tipo 'TAL' donde aparece (si esta en varios, gana su
--   primera posicion). Las tallas que no estan en ningun tallaje reciben
--   9000 y caen al final, desempatadas por nombre. Con ROW_NUMBER las
--   renumeramos en saltos de 10 (10,20,30...). Esto deja ORDEN_AV
--   consistente con el tallaje. Mismo criterio que el migrador corregido.
--
--   El fix del migrador arregla las importaciones FUTURAS; este script
--   corrige las BBDD ya migradas (no necesita el SQL Server legacy, todo
--   sale del propio destino).
--
-- Alcance / cuidado:
--   Reescribe ORDEN_AV de TODAS las tallas (ID_VA_AV='TAL'). Si alguien
--   habia ajustado a mano el orden de alguna talla, se recalcula. No toca
--   colores (ID_VA_AV='CO') ni ningun ORDEN_ACD de los tallajes.
--
-- Idempotente: es un UPDATE deterministico, re-ejecutarlo da el mismo
-- resultado. No modifica esquema.
-- =============================================================================
UPDATE fza_atributos_valores av
JOIN (
  SELECT t.ID_AV,
         (ROW_NUMBER() OVER (ORDER BY t.orden_min, t.AV)) * 10 AS nuevo_orden
  FROM (
    SELECT v.ID_AV,
           v.AV,
           COALESCE(
             MIN(CASE WHEN ac.ID_AC IS NOT NULL THEN acd.ORDEN_ACD END),
             9000) AS orden_min
    FROM fza_atributos_valores v
    LEFT JOIN fza_atributos_conjuntos_det acd
           ON acd.ID_AV_ACD = v.ID_AV
    LEFT JOIN fza_atributos_conjuntos ac
           ON ac.ID_AC = acd.ID_AC_ACD
          AND ac.ID_VA_AC = 'TAL'
    WHERE v.ID_VA_AV = 'TAL'
    GROUP BY v.ID_AV, v.AV
  ) t
) x ON x.ID_AV = av.ID_AV
SET av.ORDEN_AV = x.nuevo_orden
WHERE av.ID_VA_AV = 'TAL';
-- Verificacion (descomentar para revisar el resultado):
-- SELECT ID_AV, AV, ORDEN_AV FROM fza_atributos_valores
--  WHERE ID_VA_AV = 'TAL' ORDER BY ORDEN_AV, AV;
