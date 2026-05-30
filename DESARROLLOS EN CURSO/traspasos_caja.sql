-- ============================================================================
-- Traspasos en caja — solicitudes de traspaso entre almacenes
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
-- (detalle funcional en DESARROLLOS EN CURSO/traspasos_caja.md).
--
-- Crea las dos tablas del CICLO DE SOLICITUDES (petición -> atención):
--   fza_traspasos_solicitudes         (cabecera, sufijo TRSOL)
--   fza_traspasos_solicitudes_lineas  (líneas,   sufijo TRSOLLIN)
--
-- El TRASPASO EJECUTADO no necesita tablas nuevas: se graba en
-- fza_caja_operaciones (TIPO_OPERACION_OPCAJA TR/AT) + fza_movimientos_almacen
-- (par S+E). Estas tablas sólo guardan la PETICIÓN pendiente y su estado.
--
-- IDEMPOTENCIA: CREATE TABLE IF NOT EXISTS, NO destructivo. A diferencia del
-- patrón DROP+CREATE (válido sólo para tablas sin datos, p.ej. arqueo_caja.sql),
-- aquí se conservan las solicitudes ya grabadas al reejecutar el script. Los
-- índices van inline en el CREATE para no duplicarse en reejecución.
--
-- PENDIENTE al integrar (LIBRO_DE_ESTILO_BBDD.md §2 y §8): registrar los
-- sufijos TRSOL / TRSOLLIN en el catálogo del libro de estilo y en
-- UNormalizerEngine.pas (InitDefaults).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Cabecera de la solicitud (TRSOL)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_traspasos_solicitudes` (
  `NUMERO_TRSOL`             varchar(20)   NOT NULL,
  `SERIE_TRSOL`              varchar(20)   NOT NULL,
  `FECHA_TRSOL`              date          NULL DEFAULT NULL,
  `ESTADO_TRSOL`             varchar(20)   NOT NULL DEFAULT 'PENDIENTE'
      COMMENT 'PENDIENTE, PARCIAL, ATENDIDA, RECHAZADA, CANCELADA',
  `CODIGO_EMP_TRSOL`         varchar(20)   NOT NULL
      COMMENT 'Empresa solicitante (la del almacén destino)',
  `CODIGO_ALM_ORIGEN_TRSOL`  varchar(10)   NOT NULL
      COMMENT 'Almacén al que se pide = origen del futuro traspaso',
  `CODIGO_ALM_DESTINO_TRSOL` varchar(10)   NOT NULL
      COMMENT 'Almacén que pide = propio = destino del futuro traspaso',
  `CODIGO_EMP_CONTRA_TRSOL`  varchar(20)   NULL DEFAULT NULL
      COMMENT 'Empresa del almacén origen si difiere (traspaso entre empresas)',
  `CODIGO_CAJA_TRSOL`        varchar(10)   NULL DEFAULT NULL
      COMMENT 'Caja desde la que se originó la solicitud',
  `CODIGO_EMPLEADO_TRSOL`    varchar(20)   NULL DEFAULT NULL,
  `OBSERVACIONES_TRSOL`      varchar(1000) NULL DEFAULT '',
  `INSTANTE_MODIF`           timestamp     NOT NULL
      DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA`            timestamp     NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`             varchar(100)  NOT NULL,
  `USUARIO_MODIF`            varchar(100)  NOT NULL,
  PRIMARY KEY (`NUMERO_TRSOL`,`SERIE_TRSOL`),
  INDEX `IDX_TRSOL_ESTADO`  (`ESTADO_TRSOL`),
  INDEX `IDX_TRSOL_ORIGEN`  (`CODIGO_ALM_ORIGEN_TRSOL`,`ESTADO_TRSOL`),
  INDEX `IDX_TRSOL_DESTINO` (`CODIGO_ALM_DESTINO_TRSOL`,`ESTADO_TRSOL`),
  INDEX `IDX_TRSOL_EMP`     (`CODIGO_EMP_TRSOL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- Líneas de la solicitud (TRSOLLIN)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_traspasos_solicitudes_lineas` (
  `NUMERO_TRSOL_TRSOLLIN`         varchar(20)   NOT NULL,
  `SERIE_TRSOL_TRSOLLIN`          varchar(20)   NOT NULL,
  `LINEA_TRSOLLIN`                varchar(4)    NOT NULL,
  `CODIGO_ART_TRSOLLIN`           varchar(20)   NULL DEFAULT NULL
      COMMENT 'Código padre del artículo',
  `CODIGO_UNIDAD_TRSOLLIN`        varchar(50)   NOT NULL
      COMMENT 'SKU solicitado',
  `DESCRIPCION_ARTICULO_TRSOLLIN` varchar(100)  NULL DEFAULT NULL,
  `CANTIDAD_PEDIDA_TRSOLLIN`      decimal(19,6) NOT NULL DEFAULT '0.000000',
  `CANTIDAD_SERVIDA_TRSOLLIN`     decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Unidades ya atendidas (para estado PARCIAL)',
  `ESATENDIDA_TRSOLLIN`           varchar(1)    NOT NULL DEFAULT 'N',
  `INSTANTE_MODIF`                timestamp     NOT NULL
      DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA`                 timestamp     NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`                  varchar(100)  NOT NULL,
  `USUARIO_MODIF`                 varchar(100)  NOT NULL,
  PRIMARY KEY (`NUMERO_TRSOL_TRSOLLIN`,`SERIE_TRSOL_TRSOLLIN`,`LINEA_TRSOLLIN`),
  INDEX `IDX_TRSOLLIN_SKU` (`CODIGO_UNIDAD_TRSOLLIN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- Contador global de solicitudes de traspaso (TIPO_DOC = 'TS')
-- Lo consume inLibtb.ObtenerSiguienteContador('TS') (SP PRC_GET_NEXT_CONT).
-- Idempotente: sólo se siembra si no existe ya la fila global ('TS','-','-').
-- ----------------------------------------------------------------------------
INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`,
   `ESACTIVO_CON`, `DEFAULT_CON`, `INSTANTE_ALTA`, `USUARIO_ALTA`,
   `USUARIO_MODIF`)
SELECT 'TS', '-', '-', 0, 10, 'S', 'S', NOW(), 'SISTEMA', 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'TS'
      AND `EMPRESA_CON` = '-'
      AND `SERIE_CON` = '-');

