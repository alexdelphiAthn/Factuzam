-- Restauracion de emergencia de PS-INS-08.
-- Solo actua si existe la copia logica exacta creada para este caso.
SET @qa_backup := 'codex_qa_ps_ins08_backup_20260814';
SET @qa_backup_ok := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.SCHEMATA
   WHERE SCHEMA_NAME = @qa_backup
);
SET @qa_sql := IF(
  @qa_backup_ok = 1,
  'SELECT ''Copia logica PS-INS-08 localizada'' AS info',
  'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT =
    ''No existe la copia logica PS-INS-08; restauracion cancelada'''
);
PREPARE qa_stmt FROM @qa_sql;
EXECUTE qa_stmt;
DEALLOCATE PREPARE qa_stmt;
SET @qa_cola_total := (SELECT COUNT(*) FROM factuzam.fza_prestashop_cola);
SET @qa_cola_propia := (
  SELECT COUNT(*)
    FROM factuzam.fza_prestashop_cola
   WHERE CODIGO_ART_PSCOLA = 'DEMO-CAMISA'
     AND USUARIO_ALTA = 'CODEX_INS08'
);
SET @qa_sql := IF(
  @qa_cola_total = @qa_cola_propia,
  'SELECT ''Cola PS-INS-08 aislada'' AS info',
  'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT =
    ''La cola contiene filas ajenas a PS-INS-08; restauracion cancelada'''
);
PREPARE qa_stmt FROM @qa_sql;
EXECUTE qa_stmt;
DEALLOCATE PREPARE qa_stmt;
START TRANSACTION;
DELETE FROM factuzam.fza_usuarios_perfiles
 WHERE USUARIO_GRUPO_USUPER = 'Administrador'
   AND KEY_USUPER = 'frmMtoAppParam'
   AND SUBKEY_USUPER IN (
     'appPrestaShopSincronizarStockPrecios',
     'appPrestaShopCrearArticulos',
     'appPrestaShopUrl',
     'appPrestaShopApiKey',
     'appPrestaShopEmpresa',
     'appPrestaShopTarifa',
     'appPrestaShopIdTienda',
     'appPrestaShopSegundosCiclo',
     'appPrestaShopHorasBarrido',
     'appPrestaShopMaxIntentos'
   );
INSERT INTO factuzam.fza_usuarios_perfiles
SELECT *
  FROM codex_qa_ps_ins08_backup_20260814.parametros;
UPDATE factuzam.fza_articulos A
JOIN codex_qa_ps_ins08_backup_20260814.articulo B
  ON B.CODIGO_ART_ART = A.CODIGO_ART_ART
   SET A.ESWEB_ART = B.ESWEB_ART,
       A.INSTANTE_MODIF = B.INSTANTE_MODIF,
       A.USUARIO_MODIF = B.USUARIO_MODIF
 WHERE A.CODIGO_ART_ART = 'DEMO-CAMISA';
DELETE FROM factuzam.fza_prestashop_cola;
INSERT INTO factuzam.fza_prestashop_cola
SELECT *
  FROM codex_qa_ps_ins08_backup_20260814.cola;
COMMIT;
SET @qa_auto := (
  SELECT AUTO_INCREMENT_INICIAL
    FROM codex_qa_ps_ins08_backup_20260814.manifiesto
   WHERE ID = 1
);
SET @qa_sql := CONCAT(
  'ALTER TABLE factuzam.fza_prestashop_cola AUTO_INCREMENT = ',
  CAST(@qa_auto AS CHAR)
);
PREPARE qa_stmt FROM @qa_sql;
EXECUTE qa_stmt;
DEALLOCATE PREPARE qa_stmt;
SELECT
  (SELECT COUNT(*)
     FROM factuzam.fza_usuarios_perfiles
    WHERE USUARIO_GRUPO_USUPER = 'Administrador'
      AND KEY_USUPER = 'frmMtoAppParam'
      AND SUBKEY_USUPER LIKE 'appPrestaShop%') AS PARAMETROS_PRESTA_ADMIN,
  (SELECT ESWEB_ART
     FROM factuzam.fza_articulos
    WHERE CODIGO_ART_ART = 'DEMO-CAMISA') AS ESWEB_DEMO,
  (SELECT COUNT(*)
     FROM factuzam.fza_prestashop_cola) AS FILAS_COLA,
  (SELECT AUTO_INCREMENT
     FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'factuzam'
      AND TABLE_NAME = 'fza_prestashop_cola') AS AUTO_INCREMENT_COLA;
