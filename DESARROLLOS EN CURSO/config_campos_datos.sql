-- =====================================================================
-- Script: config_campos_datos.sql
-- Objetivo: poblar fza_config_campos con títulos visuales y anchos
--           por defecto para los campos más habituales.
-- Idempotente: INSERT IGNORE no machaca filas existentes.
-- =====================================================================

-- -----------------------------------------------------------------
-- Artículos (ampliar los 8 que ya existen)
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_articulos', 'ORDEN_ART',          'Orden',              60,  0, 'S'),
  ('fza_articulos', 'ESTRAZABLE_ART',     'Trazable',           70,  9, 'S'),
  ('fza_articulos', 'TIPO_VARIACION_ART', 'Tipo Variación',    100, 10, 'S'),
  ('fza_articulos', 'CODIGO_FAM_ART',     'Familia',           100, 11, 'S'),
  ('fza_articulos', 'INSTANTE_ALTA',      'Fecha Alta',        130, 90, 'N'),
  ('fza_articulos', 'INSTANTE_MODIF',     'Última Modif.',     130, 91, 'N'),
  ('fza_articulos', 'USUARIO_ALTA',       'Usu. Alta',         100, 92, 'N'),
  ('fza_articulos', 'USUARIO_MODIF',      'Usu. Modif.',       100, 93, 'N');

-- Campos de vistas de artículos (vi_articulos)
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('vi_articulos', 'CODIGO_ART_ART',        'Código',           120,  1, 'S'),
  ('vi_articulos', 'DESCRIPCION_ART',       'Descripción',      300,  2, 'S'),
  ('vi_articulos', 'ESACTIVO_ART',          'Activo',            50,  3, 'S'),
  ('vi_articulos', 'CODIGO_FAM_ART',        'Familia',          100,  4, 'S'),
  ('vi_articulos', 'DESCRIPCION_FAM',       'Desc. Familia',    150,  5, 'S'),
  ('vi_articulos', 'NOMBRE_FAM_FAM',        'Nombre Familia',   150,  6, 'N'),
  ('vi_articulos', 'TIPO_IVA_ART',          '% IVA',             60,  7, 'S'),
  ('vi_articulos', 'NOMBRE_TIPO_IVA_IVATIP','Tipo IVA',         100,  8, 'N'),
  ('vi_articulos', 'TIPO_CANTIDAD_ART',     'Unidad Medida',     80,  9, 'S'),
  ('vi_articulos', 'ESVARIACION_ART',       'Tiene Tallas/Col',  90, 10, 'S'),
  ('vi_articulos', 'TIPO_ART',              'Tipo',              80, 11, 'N'),
  ('vi_articulos', 'TIPO_VARIACION_ART',    'Tipo Variación',   100, 12, 'N'),
  ('vi_articulos', 'ESACTIVO_FIJO_ART',     'Activo Fijo',       70, 13, 'N'),
  ('vi_articulos', 'CODIGO_PRV_AP',         'Cód. Proveedor',   100, 14, 'N'),
  ('vi_articulos', 'RAZON_SOCIAL_PRV',      'Proveedor',        200, 15, 'S'),
  ('vi_articulos', 'NOMBRE_PRV',            'Nombre Proveedor', 150, 16, 'N'),
  ('vi_articulos', 'REF_PROVEEDOR',         'Ref. Proveedor',   120, 17, 'S'),
  ('vi_articulos', 'TEMPORADA_ART',         'Temporada',        130, 18, 'S'),
  ('vi_articulos', 'INSTANTE_ALTA',         'Fecha Alta',       130, 90, 'N'),
  ('vi_articulos', 'INSTANTE_MODIF',        'Última Modif.',    130, 91, 'N'),
  ('vi_articulos', 'USUARIO_ALTA',          'Usu. Alta',        100, 92, 'N'),
  ('vi_articulos', 'USUARIO_MODIF',         'Usu. Modif.',      100, 93, 'N');

-- -----------------------------------------------------------------
-- Proveedores
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_proveedores', 'CODIGO_PRV_PRV',          'Código',             100,  1, 'S'),
  ('fza_proveedores', 'ESACTIVO_PRV',            'Activo',              50,  2, 'S'),
  ('fza_proveedores', 'ORDEN_PRV',               'Orden',               60,  3, 'N'),
  ('fza_proveedores', 'RAZON_SOCIAL_PRV',        'Razón Social',       250,  4, 'S'),
  ('fza_proveedores', 'NOMBRE_PRV',              'Nombre',             200,  5, 'S'),
  ('fza_proveedores', 'NIF_PRV',                 'NIF',                100,  6, 'S'),
  ('fza_proveedores', 'TELEFONO_PRV',            'Teléfono',           120,  7, 'S'),
  ('fza_proveedores', 'MOVIL_PRV',               'Móvil',             120,  8, 'S'),
  ('fza_proveedores', 'EMAIL_PRV',               'Email',              200,  9, 'S'),
  ('fza_proveedores', 'CONTACTO_PRV',            'Contacto',           150, 10, 'S'),
  ('fza_proveedores', 'TELEFONO_CONTACTO_PRV',   'Tfno. Contacto',    120, 11, 'N'),
  ('fza_proveedores', 'DIRECCION1_PRV',          'Dirección',          200, 12, 'N'),
  ('fza_proveedores', 'DIRECCION2_PRV',          'Dirección 2',       200, 13, 'N'),
  ('fza_proveedores', 'POBLACION_PRV',           'Población',         150, 14, 'N'),
  ('fza_proveedores', 'PROVINCIA_PRV',           'Provincia',          120, 15, 'N'),
  ('fza_proveedores', 'CODIGO_POSTAL_PRV',       'C.P.',                70, 16, 'N'),
  ('fza_proveedores', 'PAIS_PRV',                'País',              120, 17, 'N'),
  ('fza_proveedores', 'REFERENCIA_PRV',          'Referencia',         120, 18, 'N'),
  ('fza_proveedores', 'IBAN_PRV',                'IBAN',               200, 19, 'N'),
  ('fza_proveedores', 'OBSERVACIONES_PRV',       'Observaciones',     250, 20, 'N'),
  ('fza_proveedores', 'INSTANTE_ALTA',           'Fecha Alta',        130, 90, 'N'),
  ('fza_proveedores', 'INSTANTE_MODIF',          'Última Modif.',     130, 91, 'N'),
  ('fza_proveedores', 'USUARIO_ALTA',            'Usu. Alta',         100, 92, 'N'),
  ('fza_proveedores', 'USUARIO_MODIF',           'Usu. Modif.',       100, 93, 'N');

-- -----------------------------------------------------------------
-- Clientes
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_clientes', 'CODIGO_CLI_CLI',              'Código',             100,  1, 'S'),
  ('fza_clientes', 'ESACTIVO_CLI',                'Activo',              50,  2, 'S'),
  ('fza_clientes', 'ORDEN_CLI',                   'Orden',               60,  3, 'N'),
  ('fza_clientes', 'RAZON_SOCIAL_CLI',            'Razón Social',       250,  4, 'S'),
  ('fza_clientes', 'NIF_CLI',                     'NIF',                100,  5, 'S'),
  ('fza_clientes', 'TELEFONO_CLI',                'Teléfono',           120,  6, 'S'),
  ('fza_clientes', 'MOVIL_CLI',                   'Móvil',             120,  7, 'S'),
  ('fza_clientes', 'EMAIL_CLI',                   'Email',              200,  8, 'S'),
  ('fza_clientes', 'CONTACTO_CLI',                'Contacto',           150,  9, 'N'),
  ('fza_clientes', 'TELEFONO_CONTACTO_CLI',       'Tfno. Contacto',    120, 10, 'N'),
  ('fza_clientes', 'DIRECCION1_CLI',              'Dirección',          200, 11, 'N'),
  ('fza_clientes', 'DIRECCION2_CLI',              'Dirección 2',       200, 12, 'N'),
  ('fza_clientes', 'POBLACION_CLI',               'Población',         150, 13, 'N'),
  ('fza_clientes', 'PROVINCIA_CLI',               'Provincia',          120, 14, 'N'),
  ('fza_clientes', 'CODIGO_POSTAL_CLI',           'C.P.',                70, 15, 'N'),
  ('fza_clientes', 'CODIGO_PAI_CLI',              'Cód. País',          60, 16, 'N'),
  ('fza_clientes', 'NOMBRE_PAI_CLI',              'País',              120, 17, 'N'),
  ('fza_clientes', 'REFERENCIA_CLI',              'Referencia',         120, 18, 'N'),
  ('fza_clientes', 'IBAN_CLI',                    'IBAN',               200, 19, 'N'),
  ('fza_clientes', 'CODIGO_FP_CLI',               'Forma Pago',         80, 20, 'N'),
  ('fza_clientes', 'TARIFA_ARTICULO_CLI',         'Tarifa',              80, 21, 'N'),
  ('fza_clientes', 'SERIE_CON_CLI',               'Serie',               80, 22, 'N'),
  ('fza_clientes', 'ESIVA_RECARGO_CLI',           'RE',                  40, 23, 'N'),
  ('fza_clientes', 'ESIVA_EXENTO_CLI',            'IVA Exento',          70, 24, 'N'),
  ('fza_clientes', 'ESINTRACOMUNITARIO_CLI',      'Intracom.',           70, 25, 'N'),
  ('fza_clientes', 'TOTAL_LIMITE_CREDITO_CLI',    'Lím. Crédito',      100, 26, 'N'),
  ('fza_clientes', 'TOTAL_DEUDA_CLI',             'Deuda',              100, 27, 'N'),
  ('fza_clientes', 'OBSERVACIONES_CLI',           'Observaciones',     250, 28, 'N'),
  ('fza_clientes', 'INSTANTE_ALTA',               'Fecha Alta',        130, 90, 'N'),
  ('fza_clientes', 'INSTANTE_MODIF',              'Última Modif.',     130, 91, 'N'),
  ('fza_clientes', 'USUARIO_ALTA',                'Usu. Alta',         100, 92, 'N'),
  ('fza_clientes', 'USUARIO_MODIF',               'Usu. Modif.',       100, 93, 'N');

-- -----------------------------------------------------------------
-- Facturas (campos principales)
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_facturas', 'NUMERO_FAC',                  'Número',            100,  1, 'S'),
  ('fza_facturas', 'SERIE_FAC',                   'Serie',              80,  2, 'S'),
  ('fza_facturas', 'FECHA_FAC',                   'Fecha',              90,  3, 'S'),
  ('fza_facturas', 'TIPO_FAC',                    'Tipo',               90,  4, 'S'),
  ('fza_facturas', 'FASE_FAC',                    'Fase',               90,  5, 'S'),
  ('fza_facturas', 'ESCONSOLIDADA_FAC',           'Consolidada',        70,  6, 'S'),
  ('fza_facturas', 'CODIGO_EMP_FAC',              'Empresa',            80,  7, 'S'),
  ('fza_facturas', 'CODIGO_CLI_FAC',              'Cód. Cliente',      100,  8, 'S'),
  ('fza_facturas', 'RAZON_SOCIAL_CLIENTE_FAC',    'Cliente',           250,  9, 'S'),
  ('fza_facturas', 'NIF_CLIENTE_FAC',             'NIF Cliente',       100, 10, 'S'),
  ('fza_facturas', 'FORMA_PAGO_FAC',              'Forma Pago',        120, 11, 'S'),
  ('fza_facturas', 'TOTAL_BASES_FAC',             'Base Imponible',    100, 12, 'S'),
  ('fza_facturas', 'TOTAL_IMPUESTOS_FAC',         'Impuestos',         100, 13, 'S'),
  ('fza_facturas', 'TOTAL_RETENCION_FAC',         'Retención',         100, 14, 'N'),
  ('fza_facturas', 'TOTAL_LIQUIDO_FAC',           'Total',             100, 15, 'S'),
  ('fza_facturas', 'TARIFA_ARTICULO_CLIENTE_FAC', 'Tarifa',             80, 16, 'N'),
  ('fza_facturas', 'INSTANTECONSO_FAC',           'Fecha Consol.',     130, 17, 'N'),
  ('fza_facturas', 'INSTANTE_ALTA',               'Fecha Alta',        130, 90, 'N'),
  ('fza_facturas', 'INSTANTE_MODIF',              'Última Modif.',     130, 91, 'N'),
  ('fza_facturas', 'USUARIO_ALTA',                'Usu. Alta',         100, 92, 'N'),
  ('fza_facturas', 'USUARIO_MODIF',               'Usu. Modif.',       100, 93, 'N');

-- -----------------------------------------------------------------
-- Familias
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_articulos_familias', 'CODIGO_FAM_FAM',   'Código',           100,  1, 'S'),
  ('fza_articulos_familias', 'DESCRIPCION_FAM',  'Descripción',      250,  2, 'S'),
  ('fza_articulos_familias', 'NOMBRE_FAM_FAM',   'Nombre',           200,  3, 'S'),
  ('fza_articulos_familias', 'ESACTIVO_FAM',     'Activo',            50,  4, 'S');

-- -----------------------------------------------------------------
-- Campos comunes (auditoría) - sin tabla, fallback genérico
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('*', 'INSTANTE_ALTA',   'Fecha Alta',     130, 90, 'N'),
  ('*', 'INSTANTE_MODIF',  'Última Modif.',  130, 91, 'N'),
  ('*', 'USUARIO_ALTA',    'Usu. Alta',      100, 92, 'N'),
  ('*', 'USUARIO_MODIF',   'Usu. Modif.',    100, 93, 'N');
