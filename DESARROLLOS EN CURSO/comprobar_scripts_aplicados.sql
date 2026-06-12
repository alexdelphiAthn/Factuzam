-- Batería de comprobación: ¿qué scripts de DESARROLLOS EN CURSO están
-- aplicados en ESTA base de datos? Ejecutar conectado a la BBDD de
-- trabajo (factuzam). Solo consulta INFORMATION_SCHEMA y catálogos:
-- no modifica nada.
--
-- Salida: una fila por script, con '>>> FALTA <<<' arriba. Cada script
-- de la lista es idempotente: el que falte se lanza tal cual.
--
-- Cubre los scripts de esquema detectables de las últimas tandas
-- (jun-2026). Los scripts solo-datos no se pueden detectar por
-- esquema; ver la lista al final del fichero.
SELECT t.script,
       IF(t.aplicado = 1, 'OK', '>>> FALTA <<<') AS estado,
       t.objeto
  FROM (
    SELECT 10 AS orden, 'verifactu_relaciones.sql' AS script,
           'tabla fza_facturas_relaciones' AS objeto,
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas_relaciones')
           AS aplicado
    UNION ALL
    SELECT 20, 'verifactu_rectificativas.sql',
           'fza_facturas.SERIE_FAC_ABONO_FAC varchar(20)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas'
                     AND COLUMN_NAME = 'SERIE_FAC_ABONO_FAC'
                     AND CHARACTER_MAXIMUM_LENGTH >= 20)
    UNION ALL
    SELECT 30, 'verifactu_menu.sql',
           'fza_winforms VerifactuCola + VerifactuLog',
           (SELECT COUNT(*) FROM fza_winforms
             WHERE CALL_WINF IN ('VerifactuCola', 'VerifactuLog')) = 2
    UNION ALL
    SELECT 40, 'verifactu_cola.sql',
           'tabla fza_verifactu_cola',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_verifactu_cola')
    UNION ALL
    SELECT 50, 'verifactu_cadena.sql',
           'tabla fza_verifactu_cadena',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_verifactu_cadena')
    UNION ALL
    SELECT 60, 'vi_articulos_temporada_nivel_articulo.sql',
           'vi_articulos.TEMPORADA_ART (vista relanzable)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_articulos'
                     AND COLUMN_NAME = 'TEMPORADA_ART')
    UNION ALL
    SELECT 70, 'proveedores_compras_defectos.sql',
           'fza_proveedores.PORCENTAJE_MARGEN_PRV + kits',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_proveedores'
                     AND COLUMN_NAME = 'PORCENTAJE_MARGEN_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_proveedores_kits')
    UNION ALL
    SELECT 80, 'facturas_compra.sql',
           'tabla fza_facturas_compra',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas_compra')
    UNION ALL
    SELECT 90, 'efectos_remesas_compra.sql',
           'tablas fza_efectos_compra / fza_tipos_efecto',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_efectos_compra')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_tipos_efecto')
    UNION ALL
    SELECT 100, 'albaran_compra_deposito.sql',
           'fza_albaranes_compra.ESDEPOSITO_ALBC',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_albaranes_compra'
                     AND COLUMN_NAME = 'ESDEPOSITO_ALBC')
    UNION ALL
    SELECT 110, 'movimientos_ventas_articulos.sql',
           'SP PRC_GET_MOV_VENTAS_ART',
           EXISTS(SELECT 1 FROM information_schema.ROUTINES
                   WHERE ROUTINE_SCHEMA = DATABASE()
                     AND ROUTINE_NAME = 'PRC_GET_MOV_VENTAS_ART')
    UNION ALL
    SELECT 120, 'indices_busqueda_skus.sql',
           'índice fza_codigos_barras.IDX_BARRAS_CB',
           EXISTS(SELECT 1 FROM information_schema.STATISTICS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_codigos_barras'
                     AND INDEX_NAME = 'IDX_BARRAS_CB')
    UNION ALL
    SELECT 130, 'vi_devoluciones_compra_print.sql',
           'vista vi_devoluciones_compra_cab_print',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_devoluciones_compra_cab_print')
    UNION ALL
    SELECT 140, 'vi_articulos_nombre_proveedor.sql',
           'vi_articulos.RAZON_SOCIAL_PRV (vista relanzable)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_articulos'
                     AND COLUMN_NAME = 'RAZON_SOCIAL_PRV')
    UNION ALL
    SELECT 150, 'propiedades_por_unidad.sql',
           'fza_articulos_propiedades.CODIGO_UNIDAD_ARTPROP',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_articulos_propiedades'
                     AND COLUMN_NAME = 'CODIGO_UNIDAD_ARTPROP')
    UNION ALL
    SELECT 160, 'devoluciones_compra.sql',
           'tabla fza_devoluciones_compra',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_devoluciones_compra')
    UNION ALL
    SELECT 170, 'balance_almacen_tallas.sql',
           'SP PRC_GET_BALANCE_ALMACEN_TALLAS',
           EXISTS(SELECT 1 FROM information_schema.ROUTINES
                   WHERE ROUTINE_SCHEMA = DATABASE()
                     AND ROUTINE_NAME = 'PRC_GET_BALANCE_ALMACEN_TALLAS')
    UNION ALL
    SELECT 180, 'balance_almacen_sin_tallas.sql',
           'SP PRC_GET_BALANCE_ALMACEN_SIN_TALLAS',
           EXISTS(SELECT 1 FROM information_schema.ROUTINES
                   WHERE ROUTINE_SCHEMA = DATABASE()
                     AND ROUTINE_NAME =
                         'PRC_GET_BALANCE_ALMACEN_SIN_TALLAS')
    UNION ALL
    SELECT 190, 'columnas_visibles_infgui.sql',
           'fza_informes_guias.COLUMNAS_VISIBLES_INFGUI',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_informes_guias'
                     AND COLUMN_NAME = 'COLUMNAS_VISIBLES_INFGUI')
    UNION ALL
    SELECT 200, 'widen_codigo_infgui.sql',
           'fza_informes_guias.CODIGO_INFGUI varchar(120)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_informes_guias'
                     AND COLUMN_NAME = 'CODIGO_INFGUI'
                     AND CHARACTER_MAXIMUM_LENGTH >= 120)
    UNION ALL
    SELECT 210, 'fza_informes_guias_drop_idx_redundante.sql',
           'sin índice IDX_INFGUI_INFORME (debe NO existir)',
           NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_informes_guias'
                         AND INDEX_NAME = 'IDX_INFGUI_INFORME')
    UNION ALL
    SELECT 220, 'vistas_facturas_por_tipo.sql',
           'vista vi_facturas_simplificadas',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_facturas_simplificadas')
    UNION ALL
    SELECT 230, 'factura_mueve_stock.sql',
           'fza_facturas.ESMUEVE_STOCK_FAC',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas'
                     AND COLUMN_NAME = 'ESMUEVE_STOCK_FAC')
    UNION ALL
    SELECT 240, 'widen_codigo_cli.sql',
           'fza_clientes.CODIGO_CLI_CLI varchar(20)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_clientes'
                     AND COLUMN_NAME = 'CODIGO_CLI_CLI'
                     AND CHARACTER_MAXIMUM_LENGTH >= 20)
    UNION ALL
    SELECT 250, 'widen_linea_invlin.sql',
           'fza_inventarios_lineas.LINEA_INVLIN varchar(8)',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_inventarios_lineas'
                     AND COLUMN_NAME = 'LINEA_INVLIN'
                     AND CHARACTER_MAXIMUM_LENGTH >= 8)
    UNION ALL
    SELECT 260, 'empleados.sql',
           'tabla fza_empleados',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empleados')
    UNION ALL
    SELECT 270, 'empleados_retirar_columnas_usuarios.sql',
           'fza_usuarios sin CODIGO_EMPLEADO_USU (debe NO existir)',
           NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_usuarios'
                         AND COLUMN_NAME = 'CODIGO_EMPLEADO_USU')
  ) t
 ORDER BY t.aplicado, t.orden;
-- Scripts solo-datos, no detectables por esquema. Son idempotentes:
-- si hay duda, relanzarlos no hace daño.
--   reubicar_shortcuts_menu.sql
--   reubicar_shortcuts_facturas.sql
--   migracion_shortcuts_caja_ctrl_shift.sql
--   propiedades_shortcut_ctrl_alt_y.sql
--   familias_asignar_codigo_padre.sql
--   empresas_series_venta.sql
--   clientes_deuda_actual.sql
--   tallas_alinear_skus_conjunto.sql
--   depositos_netear_devoluciones.sql (reemplaza SP existente)
--   pedidos_albaranes_compra_pivote_default_horizontal.sql
--   albc_pivote_tarifa.sql
--   tarifas_limpiar_porcentaje_dto_basura.sql
