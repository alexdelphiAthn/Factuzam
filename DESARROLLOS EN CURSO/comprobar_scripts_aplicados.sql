-- Batería de comprobación: ¿qué scripts de DESARROLLOS EN CURSO están
-- aplicados en ESTA base de datos? Ejecutar conectado a la BBDD de
-- trabajo (factuzam). Solo consulta INFORMATION_SCHEMA y catálogos:
-- no modifica nada.
--
-- Salida: una fila por script, con '>>> FALTA <<<' arriba. Cada script
-- de la lista es idempotente: el que falte se lanza tal cual, en el orden
-- mostrado por orden_aplicacion.
--
-- Cubre los scripts de esquema detectables de las últimas tandas
-- (jun/jul-2026). Los scripts solo-datos no se pueden detectar por
-- esquema; ver la lista al final del fichero.
SELECT t.orden AS orden_aplicacion,
       t.script,
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
    SELECT 85, 'facturas_compra_temporada.sql',
           'fza_facturas_compra.ID_PV_TEMPORADA_FACC',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas_compra'
                     AND COLUMN_NAME = 'ID_PV_TEMPORADA_FACC')
    UNION ALL
    SELECT 87, 'vi_facturas_compra_print.sql',
           'vista vi_facturas_compra_cab_print',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_facturas_compra_cab_print')
    UNION ALL
    SELECT 90, 'efectos_remesas_compra.sql',
           'fza_efectos_compra + remesas + vistas actualizadas',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_efectos_compra')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_tipos_efecto')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_remesas_compra')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_efectos_compra'
                         AND COLUMN_NAME = 'REFERENCIA_DOCUMENTO_EFEC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_efectos_compra'
                         AND COLUMN_NAME = 'CODIGO_EMPBAN_EFEC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_efectos_compra'
                         AND COLUMN_NAME = 'DESCRIPCION_TEFE_VIEW_EFEC')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_EFEC_GENERAR_DESDE_FACTURA')
    UNION ALL
    SELECT 91, 'efectos_remesas_venta.sql',
           'fza_efectos_venta + remesas de cobro + vistas/SP',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_efectos_venta')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_remesas_venta')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_efectos_venta')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_remesas_venta')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_EFV_GENERAR_DESDE_FACTURA')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_REMV_CREAR')
    UNION ALL
    SELECT 92, 'bancos_catalogo.sql',
           'tabla fza_bancos',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_bancos')
    UNION ALL
    SELECT 94, 'bancos_empresa.sql',
           'fza_empresas_bancos + vi_empresas_bancos + columnas de banco',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas_bancos')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_empresas_bancos')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_efectos_compra'
                         AND COLUMN_NAME = 'CODIGO_EMPBAN_EFEC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_efectos_compra'
                         AND COLUMN_NAME = 'IBAN_EMP_EFEC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_recibos'
                         AND COLUMN_NAME = 'CODIGO_EMPBAN_REC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_recibos'
                         AND COLUMN_NAME = 'IBAN_EMP_REC')
    UNION ALL
    SELECT 96, 'clientes_banco_cobro_defecto.sql',
           'fza_clientes.CODIGO_EMPBAN_CLI',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_clientes'
                     AND COLUMN_NAME = 'CODIGO_EMPBAN_CLI')
    UNION ALL
    SELECT 98, 'proveedores_pagos_defecto.sql',
           'fza_proveedores.CODIGO_FP_PRV / CODIGO_EMPBAN_PRV',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_proveedores'
                     AND COLUMN_NAME = 'CODIGO_FP_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_proveedores'
                         AND COLUMN_NAME = 'CODIGO_EMPBAN_PRV')
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
    UNION ALL
    SELECT 275, 'empleados_ampliar_ocemp.sql',
           'fza_empleados con datos legacy de ocemp',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empleados'
                     AND COLUMN_NAME = 'BIC_EMPL')
    UNION ALL
    SELECT 278, 'recuento_inventarios_factuzam.sql',
           'fza_inventarios recuento remoto + tabla INVREC',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_inventarios_recuentos')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_inventarios'
                         AND COLUMN_NAME = 'ESRECUENTO_REMOTO_INV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_inventarios'
                         AND COLUMN_NAME = 'INSTANTE_ENVIO_RECUENTO_INV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_inventarios'
                         AND COLUMN_NAME = 'INSTANTE_RECOGIDA_RECUENTO_INV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_inventarios'
                         AND COLUMN_NAME = 'ID_RECUENTO_REMOTO_INV')
    UNION ALL
    SELECT 280, 'sku_descripcion_color.sql',
           'fza_articulos_atributos_basicos.DESCRIPCION_AAB + vista',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_articulos_atributos_basicos'
                     AND COLUMN_NAME = 'DESCRIPCION_AAB')
    UNION ALL
    SELECT 290, 'documentos_trabajo.sql',
           'tablas documentos de trabajo + menú',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_documentos_trabajo')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_documentos_trabajo_lineas')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME =
                             'fza_documentos_trabajo_compartidos')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_documentos_trabajo'
                         AND COLUMN_NAME = 'TITULO_DTR')
           AND EXISTS(SELECT 1 FROM fza_winforms
                       WHERE CALL_WINF = 'DocumentosTrabajo')
    UNION ALL
    SELECT 300, 'compras_sesiones_totales_iva.sql',
           'sesiones compra con desglose IVA y total líquido',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas'
                     AND COLUMN_NAME = 'ESIVA_RECARGO_COMPRAS_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_proveedores'
                         AND COLUMN_NAME = 'ESVARIOS_TIPOS_IVA_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_compras_sesiones'
                         AND COLUMN_NAME = 'CODIGO_IVA_SES')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_compras_sesiones'
                         AND COLUMN_NAME = 'ESIVA_RECARGO_COMPRAS_SES')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_compras_sesiones'
                         AND COLUMN_NAME = 'TOTAL_LIQUIDO_SES')
    UNION ALL
    SELECT 310, 'vi_compras_sesiones_cab_print_formato.sql',
           'vi_compras_sesiones_cab_print.ESFORMATO_DISTRIBUIDO_SES',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_compras_sesiones_cab_print'
                     AND COLUMN_NAME = 'ESFORMATO_DISTRIBUIDO_SES')
    UNION ALL
    SELECT 320, 'vi_albaranes_compra_print.sql',
           'vistas print albaranes compra cab/lin/guias',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_albaranes_compra_cab_print')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes_compra_lin_print')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes_compra_guias_print')
    UNION ALL
    SELECT 330, 'vi_empresas_recargo_compras.sql',
           'vi_empresas.ESIVA_RECARGO_COMPRAS_EMP',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas'
                     AND COLUMN_NAME = 'ESIVA_RECARGO_COMPRAS_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_empresas'
                         AND COLUMN_NAME = 'ESIVA_RECARGO_COMPRAS_EMP')
    UNION ALL
    SELECT 340, 'formato_documentos_empresa.sql',
           'FORMATO_DOCUMENTO_EMP + DOCUMENTO_FORMATO en prints',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas'
                     AND COLUMN_NAME = 'FORMATO_DOCUMENTO_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_FORMATO_DOCUMENTO')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_facturas_print'
                         AND COLUMN_NAME = 'DOCUMENTO_FORMATO')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_compras_sesiones_cab_print'
                         AND COLUMN_NAME = 'DOCUMENTO_FORMATO')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes_compra_cab_print'
                         AND COLUMN_NAME = 'DOCUMENTO_FORMATO')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_devoluciones_compra_cab_print'
                         AND COLUMN_NAME = 'DOCUMENTO_FORMATO')
    UNION ALL
    SELECT 350, 'sepa_remesas_venta_datos.sql',
           'datos SEPA en bancos, clientes y remesas venta',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas_bancos'
                     AND COLUMN_NAME = 'CODIGO_ACREEDOR_SEPA_EMPBAN')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_clientes'
                         AND COLUMN_NAME = 'ID_MANDATO_SEPA_CLI')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_clientes'
                         AND COLUMN_NAME = 'FECHA_FIRMA_MANDATO_SEPA_CLI')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_remesas_venta'
                         AND COLUMN_NAME = 'TIPO_SECUENCIA_SEPA_REMV')
    UNION ALL
    -- La version vigente del script NO usa CONVERT (anulaba los indices
    -- y bloqueaba la caja): se comprueba la rama MODELO_PROV y la
    -- colacion spanish de los literales, sin exigir CONVERT/USING.
    SELECT 360, 'vi_caja_busqueda_unificada_colaciones.sql',
           'vi_caja_busqueda_unificada colacion spanish y MODELO_PROV',
           EXISTS(SELECT 1 FROM information_schema.VIEWS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_caja_busqueda_unificada'
                     AND UPPER(VIEW_DEFINITION) LIKE '%MODELO_PROV%'
                     AND UPPER(VIEW_DEFINITION) LIKE '%REF_PROVEEDOR_AP%'
                     AND VIEW_DEFINITION LIKE '%utf8mb4_spanish_ci%')
    UNION ALL
    SELECT 370, 'verifactu_numero_instalacion_empresa.sql',
           'datos instalación Verifactu en empresa',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_empresas'
                     AND COLUMN_NAME = 'NUMERO_INSTALACION_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_empresas'
                         AND COLUMN_NAME = 'VERSION_INSTALACION_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_empresas'
                         AND COLUMN_NAME = 'CODIGO_SIF_INSTALACION_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_empresas'
                         AND COLUMN_NAME = 'INSTANTE_INSTALACION_EMP')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_empresas'
                         AND COLUMN_NAME = 'NUMERO_INSTALACION_EMP')
    UNION ALL
    SELECT 380, 'compras_sesiones_forma_pago.sql',
           'fza_compras_sesiones.FORMA_PAGO_SES + vista',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_compras_sesiones'
                     AND COLUMN_NAME = 'FORMA_PAGO_SES')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_compras_sesiones'
                         AND COLUMN_NAME = 'FORMA_PAGO_SES')
    UNION ALL
    SELECT 390, 'facturas_lineas_indice_movimiento.sql',
           'índice fza_facturas_lineas.IDX_FACLIN_NUMMOV',
           EXISTS(SELECT 1 FROM information_schema.STATISTICS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_facturas_lineas'
                     AND INDEX_NAME = 'IDX_FACLIN_NUMMOV')
    UNION ALL
    SELECT 400, 'proveedores_iva_exento_intracomunitario.sql',
           'IVA exento intracomunitario en compras',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_proveedores'
                     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_compras_sesiones'
                         AND COLUMN_NAME =
                             'ESIVA_EXENTO_INTRACOMUNITARIO_SES')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra'
                         AND COLUMN_NAME =
                             'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_compra'
                         AND COLUMN_NAME =
                             'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_facturas_compra'
                         AND COLUMN_NAME =
                             'ESIVA_EXENTO_INTRACOMUNITARIO_FACC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_devoluciones_compra'
                         AND COLUMN_NAME =
                             'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC')
    UNION ALL
    SELECT 410, 'descuentos_globales_compra.sql',
           'descuentos globales compra + SP factura compra',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_compras_sesiones'
                     AND COLUMN_NAME = 'PORCENTAJE_DTO_COMERCIAL_SES')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra'
                         AND COLUMN_NAME = 'TOTAL_DTO_FINANCIERO_PEDC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_compra'
                         AND COLUMN_NAME = 'TOTAL_DTO_FINANCIERO_ALBC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_devoluciones_compra'
                         AND COLUMN_NAME = 'TOTAL_DTO_FINANCIERO_DEVC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_facturas_compra'
                         AND COLUMN_NAME = 'TOTAL_DTO_FINANCIERO_FACC')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_FACC_RECALCULAR_TOTALES')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME =
                             'PRC_FACC_ACTUALIZAR_DTOS_ALBARANES')
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_FACC_FACTURAR_ALBARAN')
    UNION ALL
    SELECT 420, 'recepcion_tope_compras.sql',
           'fecha tope recepción en sesiones/pedidos y vistas',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_compras_sesiones'
                     AND COLUMN_NAME = 'FECHA_TOPE_RECEPCION_SES')
           AND EXISTS(SELECT 1 FROM information_schema.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_compras_sesiones'
                         AND INDEX_NAME = 'IDX_SES_FECHA_TOPE_RECEPCION')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra'
                         AND COLUMN_NAME = 'FECHA_TOPE_RECEPCION_PEDC')
           AND EXISTS(SELECT 1 FROM information_schema.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra'
                         AND INDEX_NAME = 'IDX_PEDC_FECHA_TOPE_RECEPCION')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_pedidos_compra'
                         AND COLUMN_NAME =
                             'CANTIDAD_PENDIENTE_RECEPCION_PEDC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes_compra'
                         AND COLUMN_NAME = 'FECHA_TOPE_RECEPCION_ALBC')
    UNION ALL
    SELECT 430, 'quitar_esdefault_tar.sql',
           'fza_tarifas y vistas sin ESDEFAULT_TAR',
           NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_tarifas'
                         AND COLUMN_NAME = 'ESDEFAULT_TAR')
           AND NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS
                           WHERE TABLE_SCHEMA = DATABASE()
                             AND TABLE_NAME = 'vi_tarifas'
                             AND COLUMN_NAME = 'ESDEFAULT_TAR')
           AND NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS
                           WHERE TABLE_SCHEMA = DATABASE()
                             AND TABLE_NAME = 'vi_articulos_tarifas'
                             AND COLUMN_NAME = 'ESDEFAULT_TAR')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_tarifas')
    UNION ALL
    SELECT 440, 'vi_art_busquedas_ref_proveedor.sql',
           'vi_art_busquedas.REF_PROVEEDOR',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'vi_art_busquedas'
                     AND COLUMN_NAME = 'REF_PROVEEDOR')
    UNION ALL
    SELECT 445, 'proveedores_pais_combo.sql',
           'fza_proveedores.CODIGO_PAI_PRV + vistas',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_proveedores'
                     AND COLUMN_NAME = 'CODIGO_PAI_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_proveedores'
                         AND COLUMN_NAME = 'CODIGO_PAI_PRV')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_proveedores_busquedas'
                         AND COLUMN_NAME = 'CODIGO_PAI_PRV')
    UNION ALL
    SELECT 450, 'filtros_guardados.sql',
           'tablas fza_filtros_guardados / compartidos',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_filtros_guardados')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME =
                             'fza_filtros_guardados_compartidos')
    UNION ALL
    SELECT 460, 'pedidos_compra.sql',
           'pedidos compra cab/lin/celdas + vista + menú',
           EXISTS(SELECT 1 FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_pedidos_compra')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra_lineas')
           AND EXISTS(SELECT 1 FROM information_schema.TABLES
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra_celdas')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra_lineas'
                         AND COLUMN_NAME = 'COLOR_TEXTO_PEDCLIN')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_pedidos_compra'
                         AND COLUMN_NAME = 'NOMBRE_PRV_PEDC')
           AND EXISTS(SELECT 1 FROM fza_winforms
                       WHERE CALL_WINF = 'PedidosCompra')
    UNION ALL
    SELECT 470, 'albc_pivote_tarifa.sql',
           'albarán compra con pivote horizontal y tarifa',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_albaranes_compra'
                     AND COLUMN_NAME = 'ESPIVOTE_HORIZONTAL_ALBC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_compra'
                         AND COLUMN_NAME = 'CODIGO_TAR_ALBC')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes_compra'
                         AND COLUMN_NAME = 'CODIGO_TAR_ALBC')
    UNION ALL
    SELECT 480, 'pivote_compras_default_vertical_alta.sql',
           'pivote compra con default vertical en altas',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_pedidos_compra'
                     AND COLUMN_NAME = 'ESPIVOTE_HORIZONTAL_PEDC'
                     AND COALESCE(COLUMN_DEFAULT, '') IN ('N', '''N'''))
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_compra'
                         AND COLUMN_NAME = 'ESPIVOTE_HORIZONTAL_ALBC'
                         AND COALESCE(COLUMN_DEFAULT, '') IN ('N', '''N'''))
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_facturas_compra'
                         AND COLUMN_NAME = 'ESPIVOTE_HORIZONTAL_FACC'
                         AND COALESCE(COLUMN_DEFAULT, '') IN ('N', '''N'''))
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_devoluciones_compra'
                         AND COLUMN_NAME = 'ESPIVOTE_HORIZONTAL_DEVC'
                         AND COALESCE(COLUMN_DEFAULT, '') IN ('N', '''N'''))
    UNION ALL
    SELECT 490, 'fix_contador_documentos_no_cero.sql',
           'PRC_GET_NEXT_CONT_FACT_SERIE blindado contra número 0',
           EXISTS(SELECT 1 FROM information_schema.ROUTINES
                   WHERE ROUTINE_SCHEMA = DATABASE()
                     AND ROUTINE_NAME = 'PRC_GET_NEXT_CONT_FACT_SERIE'
                     AND ROUTINE_DEFINITION LIKE '%GREATEST(CON, 1)%'
                     AND ROUTINE_DEFINITION LIKE
                         '%El contador no puede devolver numero 0%')
    UNION ALL
    SELECT 500, 'lineas_documentos_varchar4_contador.sql',
           'líneas documento varchar(4) + SP pedido a albarán',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_pedidos_lineas'
                     AND COLUMN_NAME = 'LINEA_PEDLIN'
                     AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_lineas'
                         AND COLUMN_NAME = 'LINEA_ALBLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_lineas'
                         AND COLUMN_NAME = 'LINEA_PED_ALBLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos_compra_lineas'
                         AND COLUMN_NAME = 'LINEA_PEDCLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes_compra_lineas'
                         AND COLUMN_NAME = 'LINEA_ALBCLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_devoluciones_compra_lineas'
                         AND COLUMN_NAME = 'LINEA_DEVCLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_facturas_compra_lineas'
                         AND COLUMN_NAME = 'LINEA_FACCLIN'
                         AND CHARACTER_MAXIMUM_LENGTH >= 4)
           AND EXISTS(SELECT 1 FROM information_schema.ROUTINES
                       WHERE ROUTINE_SCHEMA = DATABASE()
                         AND ROUTINE_NAME = 'PRC_PED_CREAR_ALBARAN_LINEA')
    UNION ALL
    SELECT 510, 'albaranes_venta_almacen_cabecera.sql',
           'fza_albaranes.CODIGO_ALM_ALB + vista',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_albaranes'
                     AND COLUMN_NAME = 'CODIGO_ALM_ALB')
           AND EXISTS(SELECT 1 FROM information_schema.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_albaranes'
                         AND INDEX_NAME = 'IDX_ALB_ALMACEN')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_albaranes'
                         AND COLUMN_NAME = 'NOMBRE_ALM_ALB')
    UNION ALL
    SELECT 520, 'pedidos_venta_almacen_cabecera.sql',
           'fza_pedidos.CODIGO_ALM_PED + vista',
           EXISTS(SELECT 1 FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'fza_pedidos'
                     AND COLUMN_NAME = 'CODIGO_ALM_PED')
           AND EXISTS(SELECT 1 FROM information_schema.STATISTICS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'fza_pedidos'
                         AND INDEX_NAME = 'IDX_PED_ALMACEN')
           AND EXISTS(SELECT 1 FROM information_schema.COLUMNS
                       WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = 'vi_pedidos'
                         AND COLUMN_NAME = 'NOMBRE_ALM_PED')
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
--   tarifas_limpiar_porcentaje_dto_basura.sql
--   compras_sesiones_recalcular_totales.sql
--   facturas_simplificadas_cabecera_empresa.sql
--   quitar_tarifa_defecto_duplicada.sql
--   articulos_precarga_sin_stock.sql
--   movimientos_albaranes_fecha_documento.sql
