-- =====================================================================
-- Script: informes_guias.sql
-- Objetivo: crear la tabla fza_informes_guias que permite enganchar a
--           cualquier informe FastReport columnas o tablas adicionales
--           (datasets auxiliares estilo MasterSource/MasterFields/
--           DetailFields de UniDAC) sin recompilar el ejecutable.
--
-- Diseño detallado en
--   DESARROLLOS EN CURSO/informes_guias_ampliacion_runtime.md
-- =====================================================================

DROP TABLE IF EXISTS `fza_informes_guias`;
CREATE TABLE `fza_informes_guias` (
  -- Identificador logico de la guia. Se usa como UserName del
  -- TfrxDBDataset creado en runtime, asi que tiene que ser un
  -- identificador valido en FastReport (letras, digitos, _; comienza
  -- por letra). No es unico global: el mismo codigo puede reutilizarse
  -- en distintos (INFORME_INFGUI, FORMATO_INFGUI).
  `CODIGO_INFGUI`           varchar(40)  NOT NULL,

  -- Self.Name del TfrmPrint para el que aplica esta guia. Ejemplo:
  -- 'frmPrintFac', 'frmPrintEtiqArt', 'frmPrintSesion'. Equivale al
  -- KEY_USUPER que usa fza_usuarios_perfiles para persistir layouts.
  `INFORME_INFGUI`          varchar(100) NOT NULL,

  -- Formato concreto del .frx editado al que se cuelga la guia.
  -- Coincide con VALUE_USUPER de fza_usuarios_perfiles (el nombre que
  -- el usuario eligio al guardar el formato). Cadena vacia '' = guia
  -- "global", aplica a todas las variantes del informe (incluyendo
  -- 'Predeterminado'). Permite combinar:
  --   * Guias transversales: FORMATO_INFGUI = ''
  --   * Guias atadas al .frx editado: FORMATO_INFGUI = 'Factura A4 VIP'
  `FORMATO_INFGUI`          varchar(200) NOT NULL DEFAULT '',

  -- UserName del TfrxDBDataset master del informe sobre el que se cuelga
  -- la guia. Ej. 'fxdsPrintFac', 'EtiquetasArt', 'Sesiones', 'Recibos'.
  `DATASET_MASTER_INFGUI`   varchar(100) NOT NULL,

  -- Tipo de origen de datos del detalle:
  --   'TABLA' -> usa TABLA_INFGUI tal cual, MasterSource/MasterFields
  --              hacen el filtrado a nivel UniDAC.
  --   'SQL'   -> usa SQL_INFGUI como consulta libre, con parametros
  --              que coinciden con DETAIL_FIELDS_INFGUI.
  `TIPO_INFGUI`             varchar(10)  NOT NULL,

  `TABLA_INFGUI`            varchar(60)  DEFAULT NULL,
  `SQL_INFGUI`              text         DEFAULT NULL,

  -- Pares de campos master/detail separados por ';'. Mismo formato y
  -- semantica que TUniQuery.MasterFields / DetailFields.
  -- Ejemplos:
  --   MASTER_FIELDS_INFGUI = 'CODIGO_CLI_FAC'   DETAIL = 'CODIGO_CLI'
  --   MASTER_FIELDS_INFGUI = 'NUMERO_FAC;SERIE_FAC'
  --   DETAIL_FIELDS_INFGUI = 'NUMERO_FAC_REC;SERIE_FAC_REC'
  `MASTER_FIELDS_INFGUI`    varchar(200) NOT NULL,
  `DETAIL_FIELDS_INFGUI`    varchar(200) NOT NULL,

  `ORDEN_INFGUI`            int(11)      NOT NULL DEFAULT 0,
  `ESACTIVO_INFGUI`         varchar(1)   NOT NULL DEFAULT 'S',

  `INSTANTE_ALTA`           datetime     NOT NULL,
  `USUARIO_ALTA`            varchar(50)  NOT NULL,
  `INSTANTE_MODIF`          datetime     DEFAULT NULL,
  `USUARIO_MODIF`           varchar(50)  DEFAULT NULL,

  PRIMARY KEY (`INFORME_INFGUI`,`FORMATO_INFGUI`,`CODIGO_INFGUI`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

ALTER TABLE `fza_informes_guias`
  ADD INDEX `IDX_INFGUI_INFORME` (`INFORME_INFGUI`,`FORMATO_INFGUI`);


-- =====================================================================
-- Datos de ejemplo (descomentar si se quieren cargar al desplegar).
-- Util para smoke test del boton "Guias" en el modal generico.
-- =====================================================================

-- INSERT INTO `fza_informes_guias` (
--   `CODIGO_INFGUI`, `INFORME_INFGUI`, `DATASET_MASTER_INFGUI`,
--   `TIPO_INFGUI`, `TABLA_INFGUI`, `SQL_INFGUI`,
--   `MASTER_FIELDS_INFGUI`, `DETAIL_FIELDS_INFGUI`,
--   `ORDEN_INFGUI`, `ESACTIVO_INFGUI`,
--   `INSTANTE_ALTA`, `USUARIO_ALTA`
-- ) VALUES
--   ('ClienteFac', 'frmPrintFac', 'Facturas',
--    'TABLA', 'fza_clientes', NULL,
--    'CODIGO_CLI_FAC', 'CODIGO_CLI',
--    1, 'S',
--    NOW(), 'Admin'),
--   ('ProvArt', 'frmPrintEtiqArt', 'EtiquetasArt',
--    'TABLA', 'fza_proveedores', NULL,
--    'CODIGO_PRV_PRV', 'CODIGO_PRV_PRV',
--    1, 'S',
--    NOW(), 'Admin');
