-- Reemplazar PRC_FNC_GET_NEXT_LINEA_FACTURA para que sea resiliente
-- a contadores desincronizados. Usa MAX real de líneas como respaldo.
DROP PROCEDURE IF EXISTS `PRC_FNC_GET_NEXT_LINEA_FACTURA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FNC_GET_NEXT_LINEA_FACTURA`(
    IN  `pnumfac` VARCHAR(12),
    IN  `pserie`  VARCHAR(12),
    OUT `presul`  VARCHAR(3)
)
BEGIN
    DECLARE v_MaxReal   BIGINT DEFAULT 0;
    DECLARE v_Contador  BIGINT DEFAULT 0;
    DECLARE v_Next      BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    blk: BEGIN
        ROLLBACK;
        RESIGNAL;
    END blk;
    START TRANSACTION;
    -- Máximo real de las líneas existentes en la factura
    SELECT COALESCE(MAX(CAST(LINEA_FACLIN AS UNSIGNED)), 0)
      INTO v_MaxReal
      FROM fza_facturas_lineas
     WHERE NUMERO_FAC_FACLIN = pnumfac
       AND SERIE_FAC_FACLIN  = pserie;
    -- Contador almacenado en la cabecera (con bloqueo de fila)
    SELECT COALESCE(CAST(CONTADOR_LINEAS_FAC AS UNSIGNED), 0)
      INTO v_Contador
      FROM fza_facturas
     WHERE NUMERO_FAC = pnumfac
       AND SERIE_FAC  = pserie
       FOR UPDATE;
    -- Usar el mayor de ambos + 10
    SET v_Next = GREATEST(v_MaxReal, v_Contador) + 10;
    -- Actualizar el contador en la cabecera
    UPDATE fza_facturas
       SET CONTADOR_LINEAS_FAC = LPAD(v_Next, 3, '0')
     WHERE NUMERO_FAC = pnumfac
       AND SERIE_FAC  = pserie;
    IF ROW_COUNT() > 0 THEN
        SET presul = LPAD(v_Next, 3, '0');
    ELSE
        SET presul = '010';
    END IF;
    COMMIT;
END ;;
DELIMITER ;
-- Reparar contadores desincronizados en facturas existentes
UPDATE fza_facturas f
   SET CONTADOR_LINEAS_FAC = (
       SELECT LPAD(COALESCE(MAX(CAST(l.LINEA_FACLIN AS UNSIGNED)), 0) + 10, 3, '0')
         FROM fza_facturas_lineas l
        WHERE l.NUMERO_FAC_FACLIN = f.NUMERO_FAC
          AND l.SERIE_FAC_FACLIN  = f.SERIE_FAC
   )
 WHERE CONTADOR_LINEAS_FAC IS NULL
    OR CONTADOR_LINEAS_FAC = ''
    OR CONTADOR_LINEAS_FAC = '0'
    OR CAST(CONTADOR_LINEAS_FAC AS UNSIGNED) < (
       SELECT COALESCE(MAX(CAST(l2.LINEA_FACLIN AS UNSIGNED)), 0)
         FROM fza_facturas_lineas l2
        WHERE l2.NUMERO_FAC_FACLIN = f.NUMERO_FAC
          AND l2.SERIE_FAC_FACLIN  = f.SERIE_FAC
   );
