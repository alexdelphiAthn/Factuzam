-- =============================================================================
-- Ejemplo Veri*factu: tabla de facturas estilo Factuzam + cadena de huellas.
-- Subconjunto didactico de fza_facturas (solo lo relevante para Veri*factu)
-- siguiendo LIBRO_DE_ESTILO_BBDD.md. Idempotente (CREATE ... IF NOT EXISTS).
-- =============================================================================

CREATE TABLE IF NOT EXISTS `fza_facturas` (
  `NUMERO_FAC`               varchar(20)   NOT NULL COMMENT 'Numero de documento',
  `SERIE_FAC`                varchar(20)   NOT NULL COMMENT 'Serie de documento',
  `FECHA_FAC`                date          NULL DEFAULT NULL,
  `TIPO_FAC`                 varchar(20)   NULL DEFAULT 'NORMAL' COMMENT 'NORMAL/SIMPLIFICADA/RECTIFICATIVA',
  `FASE_FAC`                 varchar(20)   NULL DEFAULT NULL COMMENT 'Estado Veri*factu: VERIFACTU_PENDIENTE/OK/ERROR/ANULADA',
  `ESCONSOLIDADA_FAC`        char(1)       NOT NULL DEFAULT 'N' COMMENT 'S/N si la factura se ha emitido',
  `CODIGO_EMP_FAC`           varchar(8)    NULL DEFAULT NULL COMMENT 'FK a fza_empresas (emisor)',
  `RAZON_SOCIAL_EMPRESA_FAC` varchar(200)  NULL DEFAULT NULL,
  `NIF_EMPRESA_FAC`          varchar(50)   NULL DEFAULT NULL,
  `CODIGO_CLI_FAC`           varchar(20)   NULL DEFAULT NULL COMMENT 'FK a fza_clientes',
  `RAZON_SOCIAL_CLIENTE_FAC` varchar(200)  NULL DEFAULT NULL,
  `NIF_CLIENTE_FAC`          varchar(50)   NULL DEFAULT NULL,
  `CODIGO_PAI_CLIENTE_FAC`   varchar(3)    NULL DEFAULT '724' COMMENT 'FK a fza_paises (724=Espana)',
  `TIPO_OPER_VFACTU_FAC`     varchar(20)   NULL DEFAULT NULL COMMENT 'Calificacion Veri*factu (NULL=auto)',
  `PORCENTAJE_IVAN_FAC`      decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Normal',
  `TOTAL_BASEI_IVAN_FAC`     decimal(18,6) NULL DEFAULT NULL COMMENT 'Base imponible IVA Normal',
  `TOTAL_IVAN_FAC`           decimal(18,6) NULL DEFAULT NULL COMMENT 'Cuota IVA Normal',
  `PORCENTAJE_IVAR_FAC`      decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Reducido',
  `TOTAL_BASEI_IVAR_FAC`     decimal(18,6) NULL DEFAULT NULL COMMENT 'Base imponible IVA Reducido',
  `TOTAL_IVAR_FAC`           decimal(18,6) NULL DEFAULT NULL COMMENT 'Cuota IVA Reducido',
  `TOTAL_BASES_FAC`          decimal(18,6) NULL DEFAULT NULL COMMENT 'Suma de bases imponibles',
  `TOTAL_IMPUESTOS_FAC`      decimal(18,6) NULL DEFAULT NULL COMMENT 'Suma de cuotas (IVA + RE)',
  `TOTAL_LIQUIDO_FAC`        decimal(18,6) NULL DEFAULT NULL COMMENT 'Total a pagar',
  `SERIE_FAC_ABONO_FAC`      varchar(20)   NULL DEFAULT NULL COMMENT 'Serie de la rectificativa que sustituye a esta',
  `NUMERO_FAC_ABONO_FAC`     varchar(20)   NULL DEFAULT NULL COMMENT 'Numero de la rectificativa que sustituye a esta',
  `XML_FAC`                  text          NULL DEFAULT NULL COMMENT 'XML fiscal firmado del registro',
  `INSTANTE_ALTA`            datetime      NOT NULL,
  `USUARIO_ALTA`             varchar(50)   NOT NULL,
  `INSTANTE_MODIF`           datetime      NULL DEFAULT NULL,
  `USUARIO_MODIF`            varchar(50)   NULL DEFAULT NULL,
  PRIMARY KEY (`NUMERO_FAC`, `SERIE_FAC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

ALTER TABLE `fza_facturas` ADD INDEX `IDX_FAC_EMP`       (`CODIGO_EMP_FAC`);
ALTER TABLE `fza_facturas` ADD INDEX `IDX_FAC_CLI_FECHA` (`CODIGO_CLI_FAC`, `FECHA_FAC`);

-- Cadena de huellas por emisor (un eslabon por NIF). Identica a produccion.
CREATE TABLE IF NOT EXISTS `fza_verifactu_cadena` (
  `NIF_VFCAD`        varchar(50) NOT NULL COMMENT 'NIF del obligado de emision',
  `CONTADOR_VFCAD`   bigint(20)  NOT NULL DEFAULT 0 COMMENT 'Numero de registros aceptados',
  `SERIE_FAC_VFCAD`  varchar(20) NULL DEFAULT NULL COMMENT 'Serie de la ultima factura encadenada',
  `NUMERO_FAC_VFCAD` varchar(20) NULL DEFAULT NULL COMMENT 'Numero de la ultima factura encadenada',
  `FECHA_FAC_VFCAD`  date        NULL DEFAULT NULL COMMENT 'Fecha de expedicion de la ultima factura',
  `HUELLA_VFCAD`     char(64)    NULL DEFAULT NULL COMMENT 'Huella SHA-256 del ultimo registro aceptado',
  `INSTANTE_ALTA`    datetime    NOT NULL,
  `USUARIO_ALTA`     varchar(50) NULL DEFAULT NULL,
  `INSTANTE_MODIF`   datetime    NULL DEFAULT NULL,
  `USUARIO_MODIF`    varchar(50) NULL DEFAULT NULL,
  PRIMARY KEY (`NIF_VFCAD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Datos de demostracion (idempotentes) ----------------------------------------
INSERT INTO `fza_verifactu_cadena`
  (`NIF_VFCAD`, `CONTADOR_VFCAD`, `SERIE_FAC_VFCAD`, `NUMERO_FAC_VFCAD`,
   `FECHA_FAC_VFCAD`, `HUELLA_VFCAD`, `INSTANTE_ALTA`, `USUARIO_ALTA`)
VALUES
  ('45684134Q', 10, '2026.A1', '000153', '2026-06-13',
   'C6F200EC8EFEFE40F7E45994CC2AB320C145781F19F9614228D2525C60417D03',
   NOW(), 'Administrador')
ON DUPLICATE KEY UPDATE `NIF_VFCAD` = `NIF_VFCAD`;

INSERT INTO `fza_facturas`
  (`NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `TIPO_FAC`, `FASE_FAC`,
   `ESCONSOLIDADA_FAC`, `CODIGO_EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC`,
   `NIF_EMPRESA_FAC`, `CODIGO_CLI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`,
   `NIF_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`,
   `PORCENTAJE_IVAN_FAC`, `TOTAL_BASEI_IVAN_FAC`, `TOTAL_IVAN_FAC`,
   `TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `TOTAL_LIQUIDO_FAC`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`)
VALUES
  ('000154', '2026.A1', '2026-06-17', 'NORMAL', 'VERIFACTU_PENDIENTE',
   'S', '1', 'Alejandro Laorden Hidalgo', '45684134Q',
   '1', 'Cliente de Ejemplo, S.A.', '12345678Z', '724',
   21.000000, 100.000000, 21.000000,
   100.000000, 21.000000, 121.000000,
   NOW(), 'Administrador')
ON DUPLICATE KEY UPDATE `NUMERO_FAC` = `NUMERO_FAC`;
