-- ============================================================================
-- Tarifas: condición tipada para aplicar descuentos por propiedad LISTA.
-- Fecha: 2026-08-25
--
-- Semántica:
--   * Sin fila en fza_tarifas_descuento_condiciones = TODOS.
--   * SOLO_SI: aplica si el valor efectivo está entre los seleccionados.
--   * TODOS_EXCEPTO: aplica si existe valor efectivo y no está seleccionado.
--   * Sin valor efectivo: NO_APLICAR en ambos modos condicionales.
--
-- El valor efectivo se resuelve con prioridad SKU > COLOR > ARTICULO.
-- La aplicación valida además que la propiedad esté activa, sea LISTA y que
-- todos los ID_PV seleccionados pertenezcan a ella.
--
-- Idempotente: las tablas se crean únicamente si todavía no existen.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `fza_tarifas_descuento_condiciones` (
  `CODIGO_TAR_TARDCO` varchar(10) COLLATE utf8mb4_spanish_ci NOT NULL,
  `MODO_TARDCO` varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_PROP_TARDCO` varchar(20) COLLATE utf8mb4_spanish_ci DEFAULT NULL,
  `POLITICA_SIN_VALOR_TARDCO` varchar(20)
    COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'NO_APLICAR',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp()
    ON UPDATE current_timestamp(),
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT current_timestamp(),
  `USUARIO_ALTA` varchar(100) COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIO_MODIF` varchar(100) COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_TAR_TARDCO`),
  KEY `IDX_TARDCO_PROPIEDAD` (`CODIGO_PROP_TARDCO`),
  CONSTRAINT `FK_TARDCO_TARIFA`
    FOREIGN KEY (`CODIGO_TAR_TARDCO`)
    REFERENCES `fza_tarifas` (`CODIGO_TAR_ARTTAR`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `FK_TARDCO_PROPIEDAD`
    FOREIGN KEY (`CODIGO_PROP_TARDCO`)
    REFERENCES `fza_propiedades` (`CODIGO_PROP_ARTPROP`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `CHK_TARDCO_MODO`
    CHECK (`MODO_TARDCO` IN ('TODOS', 'SOLO_SI', 'TODOS_EXCEPTO')),
  CONSTRAINT `CHK_TARDCO_POLITICA`
    CHECK (`POLITICA_SIN_VALOR_TARDCO` = 'NO_APLICAR'),
  CONSTRAINT `CHK_TARDCO_CONFIGURACION`
    CHECK ((`MODO_TARDCO` = 'TODOS' AND `CODIGO_PROP_TARDCO` IS NULL)
        OR (`MODO_TARDCO` IN ('SOLO_SI', 'TODOS_EXCEPTO')
            AND `CODIGO_PROP_TARDCO` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS `fza_tarifas_descuento_valores` (
  `CODIGO_TAR_TARDVA` varchar(10) COLLATE utf8mb4_spanish_ci NOT NULL,
  `ID_PV_TARDVA` int(11) NOT NULL,
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp()
    ON UPDATE current_timestamp(),
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT current_timestamp(),
  `USUARIO_ALTA` varchar(100) COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIO_MODIF` varchar(100) COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_TAR_TARDVA`, `ID_PV_TARDVA`),
  KEY `IDX_TARDVA_VALOR` (`ID_PV_TARDVA`),
  CONSTRAINT `FK_TARDVA_CONDICION`
    FOREIGN KEY (`CODIGO_TAR_TARDVA`)
    REFERENCES `fza_tarifas_descuento_condiciones` (`CODIGO_TAR_TARDCO`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `FK_TARDVA_VALOR`
    FOREIGN KEY (`ID_PV_TARDVA`)
    REFERENCES `fza_propiedades_valores` (`ID_PV_ARTPROP`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Verificación rápida de estructura y política.
SELECT TABLE_NAME
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME IN (
     'fza_tarifas_descuento_condiciones',
     'fza_tarifas_descuento_valores')
 ORDER BY TABLE_NAME;
