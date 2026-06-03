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

-- -----------------------------------------------------------------
-- Almacenes
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_almacenes', 'CODIGO_ALM_ALM',     'Código',          100,  1, 'S'),
  ('fza_almacenes', 'CODIGO_EMP_ALM',     'Empresa',          80,  2, 'S'),
  ('fza_almacenes', 'ESACTIVO_ALM',       'Activo',            50,  3, 'S'),
  ('fza_almacenes', 'NOMBRE_ALM_ALM',     'Nombre',          200,  4, 'S'),
  ('fza_almacenes', 'CODIGO_PADRE_ALM',   'Almacén Padre',   100,  5, 'N'),
  ('fza_almacenes', 'ESFISICO_ALM',       'Físico',            50,  6, 'N'),
  ('fza_almacenes', 'TIPO_USO_ALM',       'Tipo Uso',          80,  7, 'N'),
  ('fza_almacenes', 'DIRECCION_ALM',      'Dirección',        200,  8, 'N'),
  ('fza_almacenes', 'POBLACION_ALM',      'Población',        150,  9, 'N'),
  ('fza_almacenes', 'PROVINCIA_ALM',      'Provincia',        120, 10, 'N'),
  ('fza_almacenes', 'CODIGO_POSTAL_ALM',  'C.P.',              70, 11, 'N'),
  ('fza_almacenes', 'TELEFONO_ALM',       'Teléfono',         120, 12, 'N'),
  ('fza_almacenes', 'EMAIL_ALM',          'Email',            200, 13, 'N'),
  ('fza_almacenes', 'CODIGO_CLI_ALM',     'Cód. Cliente',    100, 14, 'N'),
  ('fza_almacenes', 'ORDEN_ALM',          'Orden',             60, 15, 'N');

-- -----------------------------------------------------------------
-- Almacenes - Cajas
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_almacenes_cajas', 'CODIGO_ALM_ALMCAJ',   'Almacén',      100, 1, 'S'),
  ('fza_almacenes_cajas', 'CODIGO_CAJA_ALMCAJ',  'Caja',         100, 2, 'S'),
  ('fza_almacenes_cajas', 'DESCRIPCION_ALMCAJ',  'Descripción',  250, 3, 'S');

-- -----------------------------------------------------------------
-- Tarifas
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_tarifas', 'CODIGO_TAR_ARTTAR',            'Código',              100,  1, 'S'),
  ('fza_tarifas', 'ESACTIVO_ARTTAR',              'Activo',               50,  2, 'S'),
  ('fza_tarifas', 'ORDEN_TAR',                    'Orden',                60,  3, 'N'),
  ('fza_tarifas', 'NOMBRE_TAR_TAR',               'Nombre',              200,  4, 'S'),
  ('fza_tarifas', 'ESIMP_INCL_TAR',               'Imp. Incluidos',       90,  5, 'S'),
  ('fza_tarifas', 'PORCENTAJE_MARGEN_TAR',        '% Margen',             80,  6, 'N'),
  ('fza_tarifas', 'VALOR_MULTIPLO_AJUSTE_TAR',    'Múltiplo Ajuste',      90,  7, 'N'),
  ('fza_tarifas', 'VALOR_MENOS_AJUSTE_TAR',       'Menos Ajuste',         90,  8, 'N');

-- -----------------------------------------------------------------
-- Formas de pago
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_formas_pago', 'CODIGO_FP_FP',                           'Código',            100,  1, 'S'),
  ('fza_formas_pago', 'ESACTIVO_FORMA_PAGO_FP',                 'Activo',             50,  2, 'S'),
  ('fza_formas_pago', 'ORDEN_FORMA_PAGO_FP',                    'Orden',              60,  3, 'N'),
  ('fza_formas_pago', 'DESCRIPCION_FORMA_PAGO_FP',              'Descripción',       250,  4, 'S'),
  ('fza_formas_pago', 'N_PLAZOS_FORMA_PAGO_FP',                 'Nº Plazos',          80,  5, 'S'),
  ('fza_formas_pago', 'N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP',      'Días entre plazos',  90,  6, 'S'),
  ('fza_formas_pago', 'PORCENTAJE_ANTICIPO_FORMA_PAGO_FP',      '% Anticipo',         80,  7, 'N'),
  ('fza_formas_pago', 'ESVERBANCOEMPRESA_FORMA_PAGO_FP',        'Ver Banco Emp.',     90,  8, 'N'),
  ('fza_formas_pago', 'ESCONTADO_FORMA_PAGO_FP',                'Contado',            60,  9, 'S'),
  ('fza_formas_pago', 'ESDEFAULT_FORMA_PAGO_FP',                'Por Defecto',        70, 10, 'N');

-- -----------------------------------------------------------------
-- Tipos de IVA
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_ivas_tipos', 'CODIGO_ABREVIATURA_IVA_IVATIP', 'Código',     80, 1, 'S'),
  ('fza_ivas_tipos', 'NOMBRE_TIPO_IVA_IVATIP',        'Nombre',    200, 2, 'S');

-- -----------------------------------------------------------------
-- Usuarios
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_usuarios', 'USUARIO_USU',           'Usuario',           150,  1, 'S'),
  ('fza_usuarios', 'GRUPO_USU',             'Grupo',             120,  2, 'S'),
  ('fza_usuarios', 'ESACTIVO_USU',          'Activo',             50,  3, 'S'),
  ('fza_usuarios', 'EMPRESA_DEFECTO_USU',   'Empresa Def.',       80,  4, 'S'),
  ('fza_usuarios', 'ALMACEN_DEFECTO_USU',   'Almacén Def.',       80,  5, 'N'),
  ('fza_usuarios', 'CAJA_DEFECTO_USU',      'Caja Def.',          80,  6, 'N'),
  ('fza_usuarios', 'ULTIMO_LOGIN_USU',      'Último Login',      130,  7, 'N');

-- -----------------------------------------------------------------
-- Grupos de usuarios
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_usuarios_grupos', 'GRUPO_USUGRP',                 'Grupo',            150, 1, 'S'),
  ('fza_usuarios_grupos', 'ESGRUPOADMINISTRADOR_USUGRP',  'Administrador',     90, 2, 'S');

-- -----------------------------------------------------------------
-- Países
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_paises', 'CODIGO_PAI_PAI',   'Código',         60,  1, 'S'),
  ('fza_paises', 'COD_ALPHA2_PAI',   'Alpha-2',         60,  2, 'S'),
  ('fza_paises', 'COD_ALPHA3_PAI',   'Alpha-3',         60,  3, 'N'),
  ('fza_paises', 'NOMBRE_SPA_PAI',   'País (ES)',      200,  4, 'S'),
  ('fza_paises', 'NOMBRE_ENG_PAI',   'País (EN)',      200,  5, 'N'),
  ('fza_paises', 'ESMIEMBRO_UE_PAI', 'UE',               40,  6, 'S'),
  ('fza_paises', 'ORDEN_PAI',        'Orden',            60,  7, 'N');

-- -----------------------------------------------------------------
-- Variaciones (tallas/colores)
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_variaciones', 'CODIGO_VAR',   'Código',      80, 1, 'S'),
  ('fza_variaciones', 'NOMBRE_VAR',   'Nombre',     200, 2, 'S'),
  ('fza_variaciones', 'ESACTIVO_VAR', 'Activo',       50, 3, 'S'),
  ('fza_variaciones', 'ORDEN_VAR',    'Orden',        60, 4, 'N');

-- -----------------------------------------------------------------
-- Propiedades
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_propiedades', 'CODIGO_PROP_ARTPROP', 'Código',        100, 1, 'S'),
  ('fza_propiedades', 'NOMBRE_PROP_PROP',    'Nombre',        200, 2, 'S'),
  ('fza_propiedades', 'TIPO_VALOR_PROP',     'Tipo Valor',    100, 3, 'S'),
  ('fza_propiedades', 'ESACTIVO_PROP',       'Activo',         50, 4, 'S');

-- -----------------------------------------------------------------
-- Depósitos de cliente
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_depositos_cliente', 'ID_DEPOSITO_DEP',          'ID Depósito',        100,  1, 'S'),
  ('fza_depositos_cliente', 'CODIGO_EMP_DEP',           'Empresa',             80,  2, 'S'),
  ('fza_depositos_cliente', 'CODIGO_CLI_DEP',           'Cliente',            100,  3, 'S'),
  ('fza_depositos_cliente', 'CODIGO_ART_DEP',           'Artículo',           120,  4, 'S'),
  ('fza_depositos_cliente', 'CODIGO_UNIDAD_DEP',        'SKU',                150,  5, 'S'),
  ('fza_depositos_cliente', 'CODIGO_ALM_DEP',           'Almacén',             80,  6, 'S'),
  ('fza_depositos_cliente', 'PRECIO_VENTA_DEP',         'Precio Venta',       100,  7, 'S'),
  ('fza_depositos_cliente', 'IMPORTE_ANTICIPO_DEP',     'Anticipo',           100,  8, 'S'),
  ('fza_depositos_cliente', 'ESTADO_DEP',               'Estado',              80,  9, 'S'),
  ('fza_depositos_cliente', 'FECHA_CREACION_DEP',       'Fecha Creación',    100, 10, 'S'),
  ('fza_depositos_cliente', 'FECHA_ENTREGA_DEP',        'Fecha Entrega',     100, 11, 'N'),
  ('fza_depositos_cliente', 'CANTIDAD_PENDIENTE_DEP',   'Cant. Pendiente',    90, 12, 'N'),
  ('fza_depositos_cliente', 'TIPO_IVA_DEP',             'Tipo IVA',            60, 13, 'N'),
  ('fza_depositos_cliente', 'PORCENTAJE_IVA_DEP',       '% IVA',               60, 14, 'N');

-- -----------------------------------------------------------------
-- Facturas - Líneas
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_facturas_lineas', 'NUMERO_FAC_FACLIN',                  'Nº Factura',         100,  1, 'S'),
  ('fza_facturas_lineas', 'SERIE_FAC_FACLIN',                   'Serie',               80,  2, 'S'),
  ('fza_facturas_lineas', 'LINEA_FACLIN',                       'Línea',               60,  3, 'S'),
  ('fza_facturas_lineas', 'CODIGO_ART_FACLIN',                  'Artículo',           120,  4, 'S'),
  ('fza_facturas_lineas', 'CODIGO_UNIDAD_FACLIN',               'SKU',                150,  5, 'S'),
  ('fza_facturas_lineas', 'DESCRIPCION_ARTICULO_FACLIN',        'Descripción',        250,  6, 'S'),
  ('fza_facturas_lineas', 'CANTIDAD_FACLIN',                    'Cantidad',            70,  7, 'S'),
  ('fza_facturas_lineas', 'PRECIO_SALIDA_FACLIN',               'Precio Salida',      100,  8, 'S'),
  ('fza_facturas_lineas', 'PORCENTAJE_DTO_FACLIN',              '% Dto.',              60,  9, 'S'),
  ('fza_facturas_lineas', 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN',  'PVP s/IVA',          100, 10, 'S'),
  ('fza_facturas_lineas', 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN',  'PVP c/IVA',          100, 11, 'S'),
  ('fza_facturas_lineas', 'TIPO_IVA_ARTICULO_FACLIN',           'Tipo IVA',            60, 12, 'N'),
  ('fza_facturas_lineas', 'PORCENTAJE_IVA_FACLIN',              '% IVA',               60, 13, 'N'),
  ('fza_facturas_lineas', 'TOTAL_FACLIN',                       'Total',              100, 14, 'S');

-- -----------------------------------------------------------------
-- Movimientos de almacén
-- -----------------------------------------------------------------
INSERT IGNORE INTO fza_config_campos
  (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
VALUES
  ('fza_movimientos_almacen', 'NUMERO_MOV',                    'Nº Mov.',            80,  1, 'S'),
  ('fza_movimientos_almacen', 'TIPO_DOC_MOV',                  'Tipo Doc.',           70,  2, 'S'),
  ('fza_movimientos_almacen', 'SERIE_DOC_MOV',                 'Serie',               80,  3, 'S'),
  ('fza_movimientos_almacen', 'NUMERO_DOC_MOV',                'Nº Doc.',            100,  4, 'S'),
  ('fza_movimientos_almacen', 'LINEA_MOV',                     'Línea',               60,  5, 'N'),
  ('fza_movimientos_almacen', 'CODIGO_EMP_MOV',                'Empresa',             80,  6, 'S'),
  ('fza_movimientos_almacen', 'CODIGO_ALM_MOV',                'Almacén',             80,  7, 'S'),
  ('fza_movimientos_almacen', 'FECHA_MOV',                     'Fecha',               90,  8, 'S'),
  ('fza_movimientos_almacen', 'CODIGO_ART_MOV',                'Artículo',           120,  9, 'S'),
  ('fza_movimientos_almacen', 'CODIGO_UNIDAD_MOV',             'SKU',                150, 10, 'S'),
  ('fza_movimientos_almacen', 'DESCRIPCION_ARTICULO_MOV',      'Descripción',        250, 11, 'S'),
  ('fza_movimientos_almacen', 'TIPO_MOV',                      'Tipo',                80, 12, 'S'),
  ('fza_movimientos_almacen', 'CANTIDAD_MOV',                  'Cantidad',            70, 13, 'S'),
  ('fza_movimientos_almacen', 'PRECIO_COSTE_UNITARIO_MOV',     'Coste Unit.',        100, 14, 'N'),
  ('fza_movimientos_almacen', 'TOTAL_COSTE_MOV',               'Total Coste',        100, 15, 'N'),
  ('fza_movimientos_almacen', 'PRECIO_MEDIO_MOV',              'Precio Medio',       100, 16, 'N'),
  ('fza_movimientos_almacen', 'CODIGO_CLI_MOV',                'Cliente',            100, 17, 'N'),
  ('fza_movimientos_almacen', 'CODIGO_PRV_MOV',                'Proveedor',          100, 18, 'N'),
  ('fza_movimientos_almacen', 'ESACTIVO_MOV',                  'Activo',              50, 19, 'N');
