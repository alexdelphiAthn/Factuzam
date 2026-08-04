-- =============================================================================
-- Acceso concurrente a fza_contadores sin estado de sesion del conector
-- =============================================================================
-- PRC_GET_NEXT_CONTADOR es la API unica. Los dos procedimientos antiguos se
-- mantienen como adaptadores para no romper de golpe sus consumidores.
-- =============================================================================

DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONT`;
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONT_FACT_SERIE`;
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONTADOR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONTADOR`(
  IN pTipoDoc varchar(2)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pEmpresa varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pSerie varchar(12)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pUsuario varchar(100)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT pContador varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  DECLARE vContador bigint DEFAULT NULL;
  DECLARE vNumeroDigitos int DEFAULT NULL;
  DECLARE vTransaccionPropia varchar(1) DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF vTransaccionPropia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  SET pEmpresa = COALESCE(NULLIF(TRIM(pEmpresa), ''), '-');
  SET pSerie = COALESCE(NULLIF(TRIM(pSerie), ''), '-');
  SET pContador = NULL;
  IF @@in_transaction = 0 THEN
    SET vTransaccionPropia = 'S';
    START TRANSACTION;
  END IF;
  SELECT GREATEST(`CON`, 1), `NUM_DIGITOS_CON`
    INTO vContador, vNumeroDigitos
    FROM `fza_contadores`
   WHERE `TIPO_DOC_CON` = pTipoDoc
     AND `EMPRESA_CON` = pEmpresa
     AND `SERIE_CON` = pSerie
     AND `ESACTIVO_CON` = 'S'
   FOR UPDATE;
  IF vContador IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El contador solicitado no existe o esta inactivo';
  END IF;
  IF vNumeroDigitos > 20 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El contador supera los 20 digitos admitidos';
  END IF;
  UPDATE `fza_contadores`
     SET `CON` = vContador + 1,
         `USUARIO_MODIF` = pUsuario
   WHERE `TIPO_DOC_CON` = pTipoDoc
     AND `EMPRESA_CON` = pEmpresa
     AND `SERIE_CON` = pSerie;
  IF vNumeroDigitos > 0 THEN
    SET pContador = LPAD(vContador, vNumeroDigitos, '0');
  ELSE
    SET pContador = CAST(vContador AS char);
  END IF;
  IF vTransaccionPropia = 'S' THEN
    COMMIT;
  END IF;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONT`(
  IN pTipoDoc varchar(2)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pUSUARIO_MODIF varchar(100)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT pcont varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  DECLARE vSerie varchar(12) DEFAULT NULL;
  INSERT IGNORE INTO `fza_contadores` (
    `TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
    `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
    `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`
  ) VALUES (
    pTipoDoc, '-', '-', 1, 3, 'S', 'S',
    CURRENT_TIMESTAMP, pUSUARIO_MODIF, pUSUARIO_MODIF
  );
  SELECT `SERIE_CON`
    INTO vSerie
    FROM `fza_contadores`
   WHERE `TIPO_DOC_CON` = pTipoDoc
     AND `EMPRESA_CON` = '-'
     AND `DEFAULT_CON` = 'S'
     AND `ESACTIVO_CON` = 'S'
   ORDER BY `SERIE_CON`
   LIMIT 1;
  IF vSerie IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No existe un contador por defecto activo';
  END IF;
  CALL `PRC_GET_NEXT_CONTADOR`(
    pTipoDoc, '-', vSerie, pUSUARIO_MODIF, pcont);
END ;;
DELIMITER ;

DELIMITER ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONT_FACT_SERIE`(
  IN pserie varchar(12)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pTipoDoc varchar(2)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pEMPRESA_CONTADOR varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN pUSUARIOMODIF varchar(100)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT pcont varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  SET pEMPRESA_CONTADOR = COALESCE(
    NULLIF(TRIM(pEMPRESA_CONTADOR), ''), '-');
  SET pserie = COALESCE(NULLIF(TRIM(pserie), ''), '-');
  INSERT IGNORE INTO `fza_contadores` (
    `TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
    `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
    `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`
  ) VALUES (
    pTipoDoc, pEMPRESA_CONTADOR, pserie, 1, 6, 'S', 'N',
    CURRENT_TIMESTAMP, pUSUARIOMODIF, pUSUARIOMODIF
  );
  CALL `PRC_GET_NEXT_CONTADOR`(
    pTipoDoc, pEMPRESA_CONTADOR, pserie, pUSUARIOMODIF, pcont);
END ;;
DELIMITER ;
