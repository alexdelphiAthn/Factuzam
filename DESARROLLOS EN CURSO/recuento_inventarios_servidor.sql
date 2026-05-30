-- ============================================================================
-- Servidor puente de recuentos (MySQL en DreamHost) — esquema
-- ============================================================================
-- BBDD INDEPENDIENTE del Factuzam (p.ej. `factuzam_recuentos`). Es la base que
-- usa el API PHP como buzón entre Factuzam y la app de mano. NO sigue el libro
-- de estilo de Factuzam (sufijos `fza_`/`_TABLA`): ese gobierna la MariaDB de
-- Factuzam, no este puente. Convención propia: prefijo `inv_` + snake_case.
--
-- Idempotente: CREATE TABLE IF NOT EXISTS. Re-ejecutable sin efectos.
-- Motor InnoDB + utf8mb4 (igual que Factuzam). FKs con ON DELETE CASCADE de
-- catálogo y eventos hacia su recuento.
--
-- Modelo:
--   inv_recuentos     una sesión de recuento. origen=FACTUZAM (plantilla
--                     enviada, modo DIRIGIDO) u origen=APP (recuento LIBRE de
--                     un almacén, opciones 1/2 del menú).
--   inv_catalogo      líneas de la plantilla (solo recuentos DIRIGIDO): SKU,
--                     código de barras, descripción, teórica. Lo usa la app
--                     para resolver escaneos y dar feedback.
--   inv_eventos       el "evento por escaneo": una fila por lectura, con su
--                     día/hora. Idempotente por uuid_evento.
--   inv_almacenes     lista de almacenes que Factuzam sincroniza, para que la
--                     app ofrezca el selector de almacén en recuento libre.
--   inv_dispositivos  terminales/operarios dados de alta, con su token.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- inv_recuentos: cabecera de la sesión de recuento
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inv_recuentos (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  carpeta_cliente   VARCHAR(80)  NOT NULL,                 -- tenant (igual fotos)
  origen            ENUM('FACTUZAM','APP') NOT NULL,       -- quién lo creó
  modo              ENUM('DIRIGIDO','LIBRE') NOT NULL DEFAULT 'DIRIGIDO',
  tipo              ENUM('RECUENTO','TRASPASO') NOT NULL DEFAULT 'RECUENTO',
  codigo_emp        VARCHAR(10)  NULL,                     -- clave fza_inventarios
  codigo_alm        VARCHAR(10)  NOT NULL,                 -- almacén (origen)
  codigo_alm_destino VARCHAR(10) NULL,                     -- destino (TRASPASO)
  serie             VARCHAR(20)  NULL,                     -- solo DIRIGIDO
  numero            VARCHAR(20)  NULL,                     -- solo DIRIGIDO
  descripcion       VARCHAR(200) NULL,
  estado            ENUM('PENDIENTE','EN_RECUENTO','RECONTADO',
                         'RECOGIDO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
  dispositivo_origen VARCHAR(100) NULL,                    -- terminal en LIBRE
  usuario_envio     VARCHAR(100) NULL,                     -- usuario Factuzam
  instante_envio    DATETIME NULL,                         -- alta DIRIGIDO
  instante_recogida DATETIME NULL,                         -- cuando Factuzam recoge
  instante_alta     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  instante_modif    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  -- Para DIRIGIDO: upsert por la clave del inventario. En LIBRE serie/numero
  -- van NULL y MySQL admite varios NULL, así que no colisionan.
  UNIQUE KEY uq_recuento_doc
    (carpeta_cliente, codigo_emp, codigo_alm, serie, numero),
  KEY idx_recuento_estado (carpeta_cliente, estado),
  KEY idx_recuento_alm (carpeta_cliente, codigo_alm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- inv_catalogo: líneas de la plantilla (recuentos DIRIGIDO). Un SKU puede
-- tener varias filas (varios códigos de barras).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inv_catalogo (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_recuento      BIGINT UNSIGNED NOT NULL,
  codigo_articulo  VARCHAR(20)  NOT NULL,
  codigo_unidad    VARCHAR(50)  NOT NULL,                  -- SKU
  descripcion      VARCHAR(200) NULL,
  codigo_barras    VARCHAR(50)  NULL,                      -- una fila por código
  cantidad_teorica DECIMAL(19,6) NULL,                     -- NULL si recuento ciego
  estrazable       CHAR(1) NOT NULL DEFAULT 'N',           -- pedir lote/caducidad
  PRIMARY KEY (id),
  KEY idx_cat_recuento (id_recuento),
  KEY idx_cat_barras (id_recuento, codigo_barras),
  KEY idx_cat_sku (id_recuento, codigo_unidad),
  CONSTRAINT fk_cat_recuento FOREIGN KEY (id_recuento)
    REFERENCES inv_recuentos (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- inv_eventos: una fila por escaneo (la "unidad de recuento" con su día/hora).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inv_eventos (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_recuento       BIGINT UNSIGNED NOT NULL,
  uuid_evento       CHAR(36) NOT NULL,                     -- idempotencia (app)
  codigo_barras     VARCHAR(50) NULL,                      -- código crudo leído
  codigo_articulo   VARCHAR(20) NULL,                      -- resuelto por la app
  codigo_unidad     VARCHAR(50) NULL,                      -- SKU resuelto
  cantidad          DECIMAL(19,6) NOT NULL DEFAULT 1,
  lote              VARCHAR(50) NULL,
  fecha_caducidad   DATE NULL,
  instante_recuento DATETIME NOT NULL,                     -- día/hora de la lectura
  operario          VARCHAR(100) NULL,
  dispositivo       VARCHAR(100) NULL,
  zona              VARCHAR(100) NULL,                      -- pasillo/ubicación
  anulado           CHAR(1) NOT NULL DEFAULT 'N',
  instante_recibido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_evento_uuid (uuid_evento),                 -- dedupe reenvíos
  KEY idx_evt_recuento (id_recuento, id),                  -- cursor incremental
  KEY idx_evt_sku (id_recuento, codigo_unidad),
  CONSTRAINT fk_evt_recuento FOREIGN KEY (id_recuento)
    REFERENCES inv_recuentos (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- inv_almacenes: lista de almacenes sincronizada por Factuzam, para el selector
-- de almacén de la app en recuento libre (opciones 1/2 del menú).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inv_almacenes (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  carpeta_cliente VARCHAR(80)  NOT NULL,
  codigo_emp      VARCHAR(10)  NOT NULL,
  codigo_alm      VARCHAR(10)  NOT NULL,
  nombre          VARCHAR(100) NULL,
  esactivo        CHAR(1) NOT NULL DEFAULT 'S',
  instante_modif  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                          ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_alm (carpeta_cliente, codigo_emp, codigo_alm),
  KEY idx_alm_cliente (carpeta_cliente, esactivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- inv_dispositivos: terminales/operarios con su token de acceso.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inv_dispositivos (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  carpeta_cliente VARCHAR(80)  NOT NULL,
  nombre          VARCHAR(100) NOT NULL,
  operario        VARCHAR(100) NULL,
  token           CHAR(64) NOT NULL,
  esactivo        CHAR(1) NOT NULL DEFAULT 'S',
  esadmin         CHAR(1) NOT NULL DEFAULT 'N',           -- reservado: limitar
                                                          -- 'finalizar' a supervisores
  instante_alta   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_disp_token (token),
  KEY idx_disp_cliente (carpeta_cliente, esactivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
