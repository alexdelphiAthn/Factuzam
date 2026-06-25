-- =============================================================================
-- Sincroniza cabeceras de facturas simplificadas con fza_empresas
-- =============================================================================
-- Actualiza los datos del emisor guardados en fza_facturas para todas las
-- facturas simplificadas, tomando el contenido actual de fza_empresas segun
-- CODIGO_EMP_FAC = CODIGO_EMP_EMP.
-- No toca datos de cliente, totales, fechas, serie, numero ni estados
-- Verifactu. Las facturas sin empresa coincidente se listan, pero no se
-- actualizan.
--
-- Idempotente: solo actualiza cabeceras donde algun dato de empresa difiere.
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_fac_simplif_emp_cab;

CREATE TEMPORARY TABLE tmp_fac_simplif_emp_cab AS
SELECT fac.NUMERO_FAC,
       fac.SERIE_FAC
  FROM fza_facturas AS fac
  JOIN fza_empresas AS emp
    ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC
 WHERE fac.TIPO_FAC = 'SIMPLIFICADA'
   AND (
       NOT (fac.RAZON_SOCIAL_EMPRESA_FAC <=>
            emp.RAZON_SOCIAL_EMP)
    OR NOT (fac.NIF_EMPRESA_FAC <=>
            emp.NIF_EMP)
    OR NOT (fac.MOVIL_EMPRESA_FAC <=>
            emp.MOVIL_EMP)
    OR NOT (fac.EMAIL_EMPRESA_FAC <=>
            emp.EMAIL_EMP)
    OR NOT (fac.DIRECCION1_EMPRESA_FAC <=>
            emp.DIRECCION1_EMP)
    OR NOT (fac.DIRECCION2_EMPRESA_FAC <=>
            emp.DIRECCION2_EMP)
    OR NOT (fac.POBLACION_EMPRESA_FAC <=>
            emp.POBLACION_EMP)
    OR NOT (fac.PROVINCIA_EMPRESA_FAC <=>
            emp.PROVINCIA_EMP)
    OR NOT (fac.CODIGO_PAI_EMPRESA_FAC <=>
            emp.CODIGO_PAI_EMP)
    OR NOT (fac.NOMBRE_PAI_EMPRESA_FAC <=>
            emp.NOMBRE_PAI_EMP)
    OR NOT (fac.CODIGO_POSTAL_EMPRESA_FAC <=>
            emp.CODIGO_POSTAL_EMP)
    OR NOT (fac.ESRETENCIONES_EMPRESA_FAC <=>
            emp.ESRETENCIONES_EMP)
    OR NOT (fac.GRUPO_ZONA_IVA_EMPRESA_FAC <=>
            emp.GRUPO_ZONA_IVA_EMP)
    OR NOT (fac.ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC <=>
            emp.ESREGIMENESPECIALAGRICOLA_EMP)
    OR NOT (fac.TEXTO_LEGAL_EMPRESA_FAC <=>
            emp.TEXTO_LEGAL_FACTURA_EMP)
   );

SELECT COUNT(*) AS CABECERAS_SIMPLIFICADAS_A_ACTUALIZAR
  FROM tmp_fac_simplif_emp_cab;

SELECT fac.NUMERO_FAC,
       fac.SERIE_FAC,
       fac.CODIGO_EMP_FAC
  FROM fza_facturas AS fac
  LEFT JOIN fza_empresas AS emp
    ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC
 WHERE fac.TIPO_FAC = 'SIMPLIFICADA'
   AND emp.CODIGO_EMP_EMP IS NULL;

START TRANSACTION;

UPDATE fza_facturas AS fac
  JOIN tmp_fac_simplif_emp_cab AS tmp
    ON tmp.NUMERO_FAC = fac.NUMERO_FAC
   AND tmp.SERIE_FAC  = fac.SERIE_FAC
  JOIN fza_empresas AS emp
    ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC
   SET fac.RAZON_SOCIAL_EMPRESA_FAC =
       emp.RAZON_SOCIAL_EMP,
       fac.NIF_EMPRESA_FAC =
       emp.NIF_EMP,
       fac.MOVIL_EMPRESA_FAC =
       emp.MOVIL_EMP,
       fac.EMAIL_EMPRESA_FAC =
       emp.EMAIL_EMP,
       fac.DIRECCION1_EMPRESA_FAC =
       emp.DIRECCION1_EMP,
       fac.DIRECCION2_EMPRESA_FAC =
       emp.DIRECCION2_EMP,
       fac.POBLACION_EMPRESA_FAC =
       emp.POBLACION_EMP,
       fac.PROVINCIA_EMPRESA_FAC =
       emp.PROVINCIA_EMP,
       fac.CODIGO_PAI_EMPRESA_FAC =
       emp.CODIGO_PAI_EMP,
       fac.NOMBRE_PAI_EMPRESA_FAC =
       emp.NOMBRE_PAI_EMP,
       fac.CODIGO_POSTAL_EMPRESA_FAC =
       emp.CODIGO_POSTAL_EMP,
       fac.ESRETENCIONES_EMPRESA_FAC =
       emp.ESRETENCIONES_EMP,
       fac.GRUPO_ZONA_IVA_EMPRESA_FAC =
       emp.GRUPO_ZONA_IVA_EMP,
       fac.ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC =
       emp.ESREGIMENESPECIALAGRICOLA_EMP,
       fac.TEXTO_LEGAL_EMPRESA_FAC =
       emp.TEXTO_LEGAL_FACTURA_EMP,
       fac.USUARIO_MODIF =
       'SCRIPT';

SELECT ROW_COUNT() AS CABECERAS_SIMPLIFICADAS_ACTUALIZADAS;

COMMIT;

DROP TEMPORARY TABLE IF EXISTS tmp_fac_simplif_emp_cab;
