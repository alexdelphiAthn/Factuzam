-- Anyade ESFORMATO_DISTRIBUIDO_SES a vi_compras_sesiones_cab_print.
-- Necesario para que la plantilla de impresion pueda mostrar la columna
-- 'Almacen' SOLO cuando la sesion sea distribuida. CREATE OR REPLACE,
-- script idempotente.

CREATE OR REPLACE VIEW `vi_compras_sesiones_cab_print` AS
SELECT
  ses.`SERIE_SES`,
  ses.`NUMERO_SES`,
  ses.`FECHA_SES`,
  ses.`ESTADO_SES`,
  ses.`REF_PRV_SES`,
  ses.`COMENTARIOS_SES`,
  ses.`PORCENTAJE_MARGEN_SES`,
  ses.`MULTIPLO_REDONDEO_SES`,
  ses.`AJUSTE_FINAL_SES`,
  ses.`MONEDA_SES`,
  ses.`TIPO_IVA_SES`,
  ses.`CODIGO_IVA_SES`,
  ses.`ESVARIOS_TIPOS_IVA_SES`,
  ses.`ESIVA_RECARGO_COMPRAS_SES`,
  ses.`PORCENTAJE_IVAN_SES`,
  ses.`TOTAL_BASEI_IVAN_SES`,
  ses.`TOTAL_IVAN_SES`,
  ses.`PORCENTAJE_REN_SES`,
  ses.`TOTAL_REN_SES`,
  ses.`PORCENTAJE_IVAR_SES`,
  ses.`TOTAL_BASEI_IVAR_SES`,
  ses.`TOTAL_IVAR_SES`,
  ses.`PORCENTAJE_RER_SES`,
  ses.`TOTAL_RER_SES`,
  ses.`PORCENTAJE_IVAS_SES`,
  ses.`TOTAL_BASEI_IVAS_SES`,
  ses.`TOTAL_IVAS_SES`,
  ses.`PORCENTAJE_RES_SES`,
  ses.`TOTAL_RES_SES`,
  ses.`PORCENTAJE_IVAE_SES`,
  ses.`TOTAL_BASEI_IVAE_SES`,
  ses.`TOTAL_IVAE_SES`,
  ses.`PORCENTAJE_REE_SES`,
  ses.`TOTAL_REE_SES`,
  ses.`PORCENTAJE_RETENCION_SES`,
  ses.`TOTAL_RETENCION_SES`,
  ses.`TOTAL_BRUTO_SES`,
  ses.`TOTAL_BASES_SES`,
  ses.`TOTAL_IMPUESTOS_SES`,
  ses.`TOTAL_SES`,
  ses.`TOTAL_LIQUIDO_SES`,
  ses.`ESFORMATO_DISTRIBUIDO_SES`,
  ses.`CODIGO_EMP_SES`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  ses.`CODIGO_PRV_SES`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  ses.`CODIGO_TAR_SES`,
  ses.`CODIGO_FAM_SES`,
  ses.`CODIGO_ALM_SES`,
  ses.`INSTANTE_ALTA`,
  ses.`USUARIO_ALTA`,
  (SELECT COALESCE(SUM(`TOTAL_UNIDADES_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_LINEA_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `NUM_LINEAS_SES`
FROM `fza_compras_sesiones` ses
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = ses.`CODIGO_EMP_SES`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = ses.`CODIGO_PRV_SES`;
