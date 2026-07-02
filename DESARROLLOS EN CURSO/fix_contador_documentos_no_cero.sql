-- ============================================================================
-- Evitar documentos con numero 0
-- ============================================================================
-- El SP PRC_GET_NEXT_CONT_FACT_SERIE devuelve el valor anterior de CON.
-- Si una fila de fza_contadores existe con CON = 0, el primer documento
-- queda numerado como 0. Normalizamos los contadores afectados por estas
-- pantallas y blindamos el SP para que nunca reserve valores menores que 1.
-- ============================================================================
UPDATE `fza_contadores`
   SET `CON` = 1,
       `USUARIO_MODIF` = 'SISTEMA'
 WHERE `TIPO_DOC_CON` IN ('AV', 'AB', 'PC', 'FP', 'DC')
   AND `CON` < 1;
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONT_FACT_SERIE`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONT_FACT_SERIE`(
    IN pserie VARCHAR(12),
    IN pTipoDoc VARCHAR(2),
    IN pEMPRESA_CONTADOR VARCHAR(10),
    IN pUSUARIOMODIF VARCHAR(100),
    OUT pcont VARCHAR(12)
)
BEGIN
    DECLARE pNUMDIGIT INT;
    DECLARE v_NextValue BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    ManejoError: BEGIN
        ROLLBACK;
        RESIGNAL;
    END ManejoError;
    START TRANSACTION;
    IF (pEMPRESA_CONTADOR = '' OR pEMPRESA_CONTADOR IS NULL) THEN
        SET pEMPRESA_CONTADOR = '-';
    END IF;
    IF NOT EXISTS (
        SELECT 1
          FROM fza_contadores
         WHERE TIPO_DOC_CON = pTipoDoc
           AND EMPRESA_CON = pEMPRESA_CONTADOR
           AND SERIE_CON = pserie
    ) THEN
        INSERT INTO fza_contadores (
            TIPO_DOC_CON, SERIE_CON, CON, EMPRESA_CON, DEFAULT_CON,
            NUM_DIGITOS_CON, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF
        ) VALUES (
            pTipoDoc, pserie, 1, pEMPRESA_CONTADOR, 'N',
            6, CURRENT_TIMESTAMP, pUSUARIOMODIF, pUSUARIOMODIF
        );
    END IF;
    UPDATE fza_contadores
       SET CON = LAST_INSERT_ID(GREATEST(CON, 1) + 1),
           USUARIO_MODIF = pUSUARIOMODIF
     WHERE SERIE_CON = pserie
       AND EMPRESA_CON = pEMPRESA_CONTADOR
       AND TIPO_DOC_CON = pTipoDoc;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'No se pudo actualizar el contador';
    END IF;
    SET v_NextValue = LAST_INSERT_ID() - 1;
    IF v_NextValue < 1 THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El contador no puede devolver numero 0';
    END IF;
    SELECT NUM_DIGITOS_CON
      INTO pNUMDIGIT
      FROM fza_contadores
     WHERE SERIE_CON = pserie
       AND TIPO_DOC_CON = pTipoDoc
       AND EMPRESA_CON = pEMPRESA_CONTADOR
     LIMIT 1;
    IF (pNUMDIGIT IS NOT NULL AND pNUMDIGIT > 0) THEN
        SET pcont = LPAD(v_NextValue, pNUMDIGIT, '0');
    ELSE
        SET pcont = CAST(v_NextValue AS CHAR);
    END IF;
    COMMIT;
END ;;
DELIMITER ;
