-- =============================================================================
-- Proveedores: defectos para Sesiones de Compra (margen, tallas) + kits
-- =============================================================================
-- El proveedor pasa a almacenar el valor que las Sesiones de Compra
-- (inMtoComprasSesiones) copian a la cabecera al seleccionarlo:
--
--   1. PORCENTAJE_MARGEN_PRV  -> PORCENTAJE_MARGEN_SES (margen comercial).
--
-- Ademas se crea la biblioteca de KITS del proveedor: patrones de cantidades
-- por talla (CURVA-STD: 38=1, 39=2, 40=3...). Cada kit lleva su propio
-- sistema de tallas (ID_AC_TALLAS_PRVKIT); el boton "Anadir todas" del
-- mantenimiento vuelca las tallas de ese sistema con cantidad 0 para que el
-- usuario solo rellene cantidades. Estando sobre una linea de la sesion,
-- "Aplicar kit" exige que el tallaje del kit COINCIDA con el de la linea
-- (si no, advertencia y no se aplica) y copia las cantidades a las celdas
-- de talla casando VALOR_DESTINO_PRVKITD contra los valores del sistema.
-- Es el equivalente persistente y por-proveedor de los kits de sesion
-- (fza_compras_sesiones_kits, sufijo SESKIT) descritos en
-- compras_sesiones.md §2.2.
--
-- Sufijos nuevos (registrados en LIBRO_DE_ESTILO_BBDD.md §2):
--   fza_proveedores_kits     -> PRVKIT
--   fza_proveedores_kits_det -> PRVKITD
--
-- Idempotente: columna via INFORMATION_SCHEMA, tablas via IF NOT EXISTS.
-- NO tocar factuzam_original.sql (regla del repo); este script se aplica
-- por separado a las BBDD existentes.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna nueva en fza_proveedores (margen comercial por defecto)
-- ---------------------------------------------------------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_proveedores'
     AND COLUMN_NAME  = 'PORCENTAJE_MARGEN_PRV'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_proveedores
     ADD COLUMN PORCENTAJE_MARGEN_PRV decimal(7,4) NULL DEFAULT NULL
       COMMENT ''Margen comercial defecto: se copia a PORCENTAJE_MARGEN_SES''
     AFTER IBAN_PRV',
  'SELECT ''PORCENTAJE_MARGEN_PRV ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Kits del proveedor (cabecera + detalle)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_proveedores_kits` (
  `CODIGO_PRV_PRVKIT`     varchar(20)   NOT NULL
                            COMMENT 'FK logica a fza_proveedores',
  `CODIGO_PRVKIT`         varchar(20)   NOT NULL
                            COMMENT 'CURVA-STD, MUESTRA, etc.',
  `NOMBRE_PRVKIT`         varchar(100)  NOT NULL,
  `DESCRIPCION_PRVKIT`    varchar(255)  DEFAULT NULL,
  `ID_AC_TALLAS_PRVKIT`   int(11)       DEFAULT NULL
                            COMMENT 'FK logica fza_atributos_conjuntos: sistema de tallas del kit. Al aplicar debe coincidir con el de la linea (ID_AC_PIVOT_SESLIN) o se advierte y no se aplica',
  `ORDEN_PRVKIT`          int(11)       NOT NULL DEFAULT 0,
  `INSTANTE_ALTA`         datetime      NOT NULL,
  `USUARIO_ALTA`          varchar(50)   NOT NULL,
  `INSTANTE_MODIF`        datetime      DEFAULT NULL,
  `USUARIO_MODIF`         varchar(50)   DEFAULT NULL,
  PRIMARY KEY (`CODIGO_PRV_PRVKIT`, `CODIGO_PRVKIT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_proveedores_kits_det` (
  `CODIGO_PRV_PRVKITD`    varchar(20)   NOT NULL,
  `CODIGO_PRVKIT_PRVKITD` varchar(20)   NOT NULL,
  `VALOR_DESTINO_PRVKITD` varchar(50)   NOT NULL
                            COMMENT 'Valor de la talla destino: "38", "M", etc. Se casa contra fza_atributos_valores.AV del sistema de la linea',
  `CANTIDAD_PRVKITD`      decimal(19,6) NOT NULL DEFAULT 0,
  `ORDEN_PRVKITD`         int(11)       NOT NULL DEFAULT 0,
  `INSTANTE_ALTA`         datetime      NOT NULL,
  `USUARIO_ALTA`          varchar(50)   NOT NULL,
  `INSTANTE_MODIF`        datetime      DEFAULT NULL,
  `USUARIO_MODIF`         varchar(50)   DEFAULT NULL,
  PRIMARY KEY (`CODIGO_PRV_PRVKITD`, `CODIGO_PRVKIT_PRVKITD`,
               `VALOR_DESTINO_PRVKITD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
