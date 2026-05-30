-- ============================================================================
-- Recuento de inventarios con app — cambios de esquema en Factuzam (MariaDB)
-- ============================================================================
-- NO se toca factuzam_original.sql. Este script es idempotente y re-ejecutable.
--   * Tabla nueva fza_inventarios_recuentos (sufijo INVREC): una fila por
--     escaneo recogido del servidor, para conservar el origen del recuento
--     (qué leyó el móvil, cuándo, quién y con qué terminal).
--   * Columnas de ciclo en fza_inventarios para seguir el envío/recogida.
--
-- PK de INVREC: contador propio ID_INVREC (clave estrecha) para no arrastrar
-- la clave del inventario (empresa+almacén+serie+número) ni el UUID por los
-- índices secundarios. UUID_INVREC va como UNIQUE: lo genera la app, identifica
-- cada escaneo y da idempotencia al recoger dos veces. La clave del inventario
-- va indexada (IDX_INVREC_DOC) para consultar y sumar por documento.
--
-- CANTIDAD_FISICA_INVLIN sigue siendo la suma por SKU (se ingiere igual que el
-- import de Excel, vía CargarDesdeListaSkus); INVREC es el detalle por lectura.
--
-- PENDIENTE (cambio de código, no SQL): registrar el sufijo INVREC en
-- UNormalizerEngine.pas (InitDefaults -> AddSuf('fza_inventarios_recuentos',
-- 'INVREC')) y en el catálogo del LIBRO_DE_ESTILO_BBDD.md §2.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `fza_inventarios_recuentos` (
  `ID_INVREC`                bigint        NOT NULL AUTO_INCREMENT,
  `UUID_INVREC`              varchar(36)   NOT NULL,
  `CODIGO_EMP_INVREC`        varchar(10)   NOT NULL,
  `CODIGO_ALM_INVREC`        varchar(10)   NOT NULL,
  `SERIE_INV_INVREC`         varchar(20)   NOT NULL,
  `NUMERO_INV_INVREC`        varchar(20)   NOT NULL,
  `CODIGO_ART_INVREC`        varchar(20)   DEFAULT NULL,
  `CODIGO_UNIDAD_INVREC`     varchar(50)   DEFAULT NULL,
  `CODIGO_BARRAS_INVREC`     varchar(50)   DEFAULT NULL,
  `CANTIDAD_INVREC`          decimal(19,6) NOT NULL DEFAULT 1.000000,
  `LOTE_INVREC`              varchar(50)   DEFAULT '',
  `FECHA_CADUCIDAD_INVREC`   date          DEFAULT NULL,
  `INSTANTE_RECUENTO_INVREC` datetime      NOT NULL,
  `OPERARIO_INVREC`          varchar(100)  DEFAULT NULL,
  `DISPOSITIVO_INVREC`       varchar(100)  DEFAULT NULL,
  `ZONA_INVREC`              varchar(100)  DEFAULT NULL,
  `ESANULADO_INVREC`         char(1)       NOT NULL DEFAULT 'N',
  `INSTANTE_ALTA`            datetime      NOT NULL,
  `USUARIO_ALTA`             varchar(100)  NOT NULL,
  `INSTANTE_MODIF`           datetime      DEFAULT NULL,
  `USUARIO_MODIF`            varchar(100)  DEFAULT NULL,
  PRIMARY KEY (`ID_INVREC`),
  UNIQUE KEY `UQ_INVREC_UUID` (`UUID_INVREC`),
  KEY `IDX_INVREC_DOC` (`CODIGO_EMP_INVREC`,`CODIGO_ALM_INVREC`,
                        `SERIE_INV_INVREC`,`NUMERO_INV_INVREC`),
  KEY `IDX_INVREC_UNIDAD` (`CODIGO_UNIDAD_INVREC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- Marcadores de ciclo en fza_inventarios (ADD COLUMN IF NOT EXISTS, MariaDB).
-- ESTADO_INV se queda ABIERTO mientras está fuera contándose; al recoger se
-- rellenan físicas y el usuario aplica como hoy (regularización sin cambios).
-- ----------------------------------------------------------------------------
ALTER TABLE `fza_inventarios`
  ADD COLUMN IF NOT EXISTS `ESRECUENTO_REMOTO_INV`
      char(1) NOT NULL DEFAULT 'N',
  ADD COLUMN IF NOT EXISTS `INSTANTE_ENVIO_RECUENTO_INV`
      datetime DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `INSTANTE_RECOGIDA_RECUENTO_INV`
      datetime DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `ID_RECUENTO_REMOTO_INV`
      varchar(40) DEFAULT NULL;
