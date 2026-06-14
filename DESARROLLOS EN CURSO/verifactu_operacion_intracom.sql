-- =============================================================================
-- Catalogo de calificaciones de operacion para Verifactu + columna en facturas
-- =============================================================================
-- Permite calificar una factura de cara a Verifactu cuando NO es una venta
-- interior en regimen general (intracomunitarias, ISP, exportacion, bienes
-- usados...). El catalogo es ABIERTO: el usuario puede anadir nuevos tipos sin
-- recompilar; el envio lee de aqui el mapeo al XML de la AEAT.
--
-- Mapeo por fila:
--   CLAVE_REGIMEN_VFO     ClaveRegimen (01 general, 03 bienes usados/REBU...).
--   CALIFICACION_VFO      CalificacionOperacion (S1/S2/N1/N2) o vacio.
--   OPERACION_EXENTA_VFO  OperacionExenta (E1..E6) o vacio.
--   ESREPERCUTE_IVA_VFO   'S' -> desglose por bandas con tipo y cuota.
--                         'N' -> un unico detalle con la base, sin cuota.
--   AMBITO_VFO            Residencia exigida al cliente, para detectar
--                         incoherencias: NACIONAL, UE, EXTRA_UE o CUALQUIERA.
--
-- CALIFICACION y OPERACION_EXENTA son excluyentes: una operacion exenta lleva
-- OperacionExenta; una sujeta (con o sin ISP) lleva CalificacionOperacion.
--
-- Idempotente: tabla con CREATE TABLE IF NOT EXISTS, columnas con chequeo en
-- INFORMATION_SCHEMA, semilla con INSERT IGNORE (no pisa personalizaciones) y
-- backfill del ambito solo en las filas semilla.
-- =============================================================================
-- 1) Tabla catalogo -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS fza_verifactu_operaciones (
  CODIGO_VFO            varchar(20)  NOT NULL,
  DESCRIPCION_VFO       varchar(100) NULL DEFAULT NULL,
  AYUDA_VFO             varchar(255) NULL DEFAULT NULL,
  CLAVE_REGIMEN_VFO     varchar(2)   NULL DEFAULT '01',
  CALIFICACION_VFO      varchar(2)   NULL DEFAULT NULL,
  OPERACION_EXENTA_VFO  varchar(2)   NULL DEFAULT NULL,
  ESREPERCUTE_IVA_VFO   varchar(1)   NULL DEFAULT 'S',
  AMBITO_VFO            varchar(10)  NULL DEFAULT NULL,
  ORDEN_VFO             int(11)      NULL DEFAULT NULL,
  ESACTIVO_VFO          varchar(1)   NULL DEFAULT 'S',
  INSTANTE_ALTA         datetime     NULL DEFAULT NULL,
  INSTANTE_MODIF        datetime     NULL DEFAULT NULL,
  USUARIO_ALTA          varchar(50)  NULL DEFAULT NULL,
  USUARIO_MODIF         varchar(50)  NULL DEFAULT NULL,
  PRIMARY KEY (CODIGO_VFO)
);
-- 1b) Columna AMBITO_VFO si la tabla ya existia sin ella -----------------------
SET @sExisteAmbito := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_operaciones'
     AND COLUMN_NAME  = 'AMBITO_VFO'
);
SET @sSql := IF(@sExisteAmbito = 0,
  'ALTER TABLE fza_verifactu_operaciones
     ADD COLUMN AMBITO_VFO varchar(10) NULL DEFAULT NULL AFTER ESREPERCUTE_IVA_VFO',
  'SELECT ''AMBITO_VFO ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
-- 2) Semilla de tipos habituales (INSERT IGNORE: no pisa lo ya existente) ------
INSERT IGNORE INTO fza_verifactu_operaciones
  (CODIGO_VFO, DESCRIPCION_VFO, AYUDA_VFO, CLAVE_REGIMEN_VFO,
   CALIFICACION_VFO, OPERACION_EXENTA_VFO, ESREPERCUTE_IVA_VFO, AMBITO_VFO,
   ORDEN_VFO, ESACTIVO_VFO, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('INTERIOR', 'Interior - regimen general',
   'Venta nacional con IVA. Es el comportamiento por defecto.',
   '01', 'S1', NULL, 'S', 'NACIONAL', 10, 'S', NOW(), 'SEED'),
  ('SERVICIO_INTRA', 'Servicio intracomunitario (no sujeto)',
   'Servicio a profesional UE: no sujeto en Espana por localizacion (art. 69), el cliente autoliquida el IVA.',
   '01', 'N2', NULL, 'N', 'UE', 20, 'S', NOW(), 'SEED'),
  ('ENTREGA_INTRA', 'Entrega intracomunitaria de bienes (exenta)',
   'Entrega de bienes a empresa UE, exenta art. 25 LIVA.',
   '01', NULL, 'E5', 'N', 'UE', 30, 'S', NOW(), 'SEED'),
  ('ISP', 'Inversion del sujeto pasivo',
   'El IVA lo autoliquida el destinatario (art. 84). No se repercute cuota.',
   '01', 'S2', NULL, 'N', 'CUALQUIERA', 40, 'S', NOW(), 'SEED'),
  ('EXPORT', 'Exportacion fuera de la UE (exenta)',
   'Entrega de bienes exportados fuera de la UE, exenta art. 21 LIVA. Se asigna sola si el cliente no es de la UE.',
   '01', NULL, 'E2', 'N', 'EXTRA_UE', 50, 'S', NOW(), 'SEED'),
  ('BIENES_USADOS', 'Bienes usados (REBU)',
   'Regimen especial de bienes usados: IVA sobre el margen. Requiere calculo de margen aparte.',
   '03', 'S1', NULL, 'S', 'CUALQUIERA', 60, 'S', NOW(), 'SEED');
-- 2b) Backfill del ambito en filas semilla anteriores sin ambito ---------------
UPDATE fza_verifactu_operaciones SET AMBITO_VFO = 'NACIONAL'
 WHERE CODIGO_VFO = 'INTERIOR' AND AMBITO_VFO IS NULL;
UPDATE fza_verifactu_operaciones SET AMBITO_VFO = 'UE'
 WHERE CODIGO_VFO IN ('SERVICIO_INTRA', 'ENTREGA_INTRA') AND AMBITO_VFO IS NULL;
UPDATE fza_verifactu_operaciones SET AMBITO_VFO = 'CUALQUIERA'
 WHERE CODIGO_VFO IN ('ISP', 'BIENES_USADOS') AND AMBITO_VFO IS NULL;
UPDATE fza_verifactu_operaciones SET AMBITO_VFO = 'EXTRA_UE'
 WHERE CODIGO_VFO = 'EXPORT' AND AMBITO_VFO IS NULL;
-- 3) Columna en fza_facturas (FK logica al catalogo) --------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'TIPO_OPER_VFACTU_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN TIPO_OPER_VFACTU_FAC varchar(20) NULL DEFAULT NULL
       COMMENT ''Calificacion Verifactu: CODIGO_VFO de fza_verifactu_operaciones (NULL=auto)''
     AFTER ESINTRACOMUNITARIO_CLIENTE_FAC',
  'SELECT ''TIPO_OPER_VFACTU_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
-- 4) Recrear las vistas de facturas -------------------------------------------
-- vi_facturas usa SELECT fza_facturas.*, que MariaDB expande a columnas fijas
-- al crear la vista. Hay que recrearla para que TIPO_OPER_VFACTU_FAC quede
-- expuesta al formulario (que enlaza el combo a ese campo). Idempotente.
CREATE OR REPLACE VIEW vi_facturas AS
  SELECT fza_facturas.*,
         fza_formas_pago.DESCRIPCION_FORMA_PAGO_FP AS DESCRIPCION_FORMA_PAGO_FP
    FROM fza_facturas
    LEFT JOIN fza_formas_pago
         ON fza_facturas.FORMA_PAGO_FAC = fza_formas_pago.CODIGO_FP_FP
   ORDER BY fza_facturas.FECHA_FAC DESC;
CREATE OR REPLACE VIEW vi_facturas_normales AS
  SELECT * FROM vi_facturas WHERE TIPO_FAC = 'NORMAL';
CREATE OR REPLACE VIEW vi_facturas_simplificadas AS
  SELECT * FROM vi_facturas WHERE TIPO_FAC = 'SIMPLIFICADA';
