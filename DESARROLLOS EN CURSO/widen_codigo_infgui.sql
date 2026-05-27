-- Ampliar CODIGO_INFGUI de varchar(40) a varchar(120)
-- El formato automático MASTER.TABLA.DETAIL puede superar los 40 chars
SET @col_exists = (
  SELECT DATA_TYPE
    FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_informes_guias'
     AND COLUMN_NAME  = 'CODIGO_INFGUI'
);
SET @do_alter = IF(@col_exists IS NOT NULL
  AND (SELECT CHARACTER_MAXIMUM_LENGTH
         FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'fza_informes_guias'
          AND COLUMN_NAME  = 'CODIGO_INFGUI') < 120,
  'ALTER TABLE fza_informes_guias MODIFY CODIGO_INFGUI varchar(120) NOT NULL',
  'SELECT ''CODIGO_INFGUI ya tiene 120+ chars o no existe''');
PREPARE stmt FROM @do_alter;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
