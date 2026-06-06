-- =============================================================================
-- Vistas de mantenimiento: ordenar por la columna ORDEN del usuario
-- =============================================================================
-- Varias vistas `vi_*` que alimentan combos/rejillas de mantenimientos exponen
-- la columna de orden visual que el usuario fija en cada ficha (ORDEN_xxx) pero
-- NO ordenaban por ella: el consumidor las leia con `SELECT * FROM vista` sin
-- ORDER BY propio, por lo que salian en orden arbitrario. Aqui se recrean
-- anadiendo el ORDER BY por su columna ORDEN, para que respeten el orden del
-- usuario alla donde se consuman sin ordenacion externa.
--
-- Todas son vistas de tablas de referencia pequenas (formas de pago,
-- variaciones, familias, empresas), por lo que el ORDER BY no penaliza como en
-- las vistas con joins grandes que se filtran como subconsulta (ver el
-- antecedente fix_vi_atributos_nombres_sin_orderby.sql, donde se quito el
-- ORDER BY a proposito). Cuando el consumidor pone su propio ORDER BY externo
-- (p.ej. el buscador hace ORDER BY por nombre), ese prevalece sobre el de la
-- vista, asi que esos casos no cambian.
--
-- vi_proveedores se ordena en su propio script (vi_proveedores_nombre.sql) para
-- no duplicar la definicion ni pelearse por cual CREATE OR REPLACE gana.
--
-- Vistas que NO se tocan a proposito (exponen ORDEN pero se filtran por
-- articulo contra tablas grandes -> el ORDER BY las materializaria entera;
-- el cliente ya ordena con su propio LIMIT/ORDER BY): vi_atributos_nombres,
-- vi_atributos_sku_basico, vi_articulos_conjuntos_slots,
-- vi_articulos_propiedades_slots.
--
-- Idempotente: CREATE OR REPLACE VIEW reescribe la definicion sin error al
-- repetir. No se toca factuzam_original.sql.
-- =============================================================================

-- 1. vi_formapago -> ORDEN_FORMA_PAGO_FP
--    Combo/rejilla de formas de pago (UniDataFormasdePago, UniDataFacturas,
--    UniDataClientes) hacen `SELECT * FROM vi_formapago` sin ORDER BY propio.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_formapago` AS
SELECT `fza_formas_pago`.`CODIGO_FP_FP`                      AS `CODIGO_FP_FP`,
       `fza_formas_pago`.`ESACTIVO_FORMA_PAGO_FP`            AS `ESACTIVO_FORMA_PAGO_FP`,
       `fza_formas_pago`.`ORDEN_FORMA_PAGO_FP`               AS `ORDEN_FORMA_PAGO_FP`,
       `fza_formas_pago`.`DESCRIPCION_FORMA_PAGO_FP`         AS `DESCRIPCION_FORMA_PAGO_FP`,
       `fza_formas_pago`.`N_PLAZOS_FORMA_PAGO_FP`            AS `N_PLAZOS_FORMA_PAGO_FP`,
       `fza_formas_pago`.`N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP` AS `N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP`,
       `fza_formas_pago`.`PORCENTAJE_ANTICIPO_FORMA_PAGO_FP` AS `PORCENTAJE_ANTICIPO_FORMA_PAGO_FP`,
       `fza_formas_pago`.`ESVERBANCOEMPRESA_FORMA_PAGO_FP`   AS `ESVERBANCOEMPRESA_FORMA_PAGO_FP`,
       `fza_formas_pago`.`ESDEFAULT_FORMA_PAGO_FP`           AS `ESDEFAULT_FORMA_PAGO_FP`,
       `fza_formas_pago`.`INSTANTE_MODIF`                    AS `INSTANTE_MODIF`,
       `fza_formas_pago`.`INSTANTE_ALTA`                     AS `INSTANTE_ALTA`,
       `fza_formas_pago`.`USUARIO_ALTA`                      AS `USUARIO_ALTA`,
       `fza_formas_pago`.`USUARIO_MODIF`                     AS `USUARIO_MODIF`
  FROM `fza_formas_pago`
 ORDER BY `fza_formas_pago`.`ORDEN_FORMA_PAGO_FP`;

-- 2. vi_variaciones -> ORDEN_VAR
--    Lookup de variaciones (UniDataArticulos) lee `FROM vi_variaciones` sin
--    ORDER BY propio.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_variaciones` AS
SELECT `fza_variaciones`.`CODIGO_VAR`     AS `CODIGO_VAR`,
       `fza_variaciones`.`NOMBRE_VAR`     AS `NOMBRE_VAR`,
       `fza_variaciones`.`ESACTIVO_VAR`   AS `ESACTIVO_VAR`,
       `fza_variaciones`.`ORDEN_VAR`      AS `ORDEN_VAR`,
       `fza_variaciones`.`INSTANTE_MODIF` AS `INSTANTE_MODIF`,
       `fza_variaciones`.`INSTANTE_ALTA`  AS `INSTANTE_ALTA`,
       `fza_variaciones`.`USUARIO_ALTA`   AS `USUARIO_ALTA`,
       `fza_variaciones`.`USUARIO_MODIF`  AS `USUARIO_MODIF`
  FROM `fza_variaciones`
 ORDER BY `fza_variaciones`.`ORDEN_VAR`;

-- 3. vi_articulos_familias -> ORDEN_FAM
--    Autojoin para resolver el nombre de la subfamilia. Se cualifica ORDEN_FAM
--    con la tabla base porque el alias fza_articulos_familias2 tiene la misma
--    columna.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_articulos_familias` AS
SELECT `fza_articulos_familias`.`CODIGO_FAM_FAM`        AS `CODIGO_FAM_FAM`,
       `fza_articulos_familias`.`ESACTIVO_FAM`          AS `ESACTIVO_FAM`,
       `fza_articulos_familias`.`ORDEN_FAM`             AS `ORDEN_FAM`,
       `fza_articulos_familias`.`ESDEFAULT_FAM`         AS `ESDEFAULT_FAM`,
       `fza_articulos_familias`.`CODIGO_SUBFAMILIA_FAM` AS `CODIGO_SUBFAMILIA_FAM`,
       `fza_articulos_familias2`.`NOMBRE_FAM_FAM`       AS `NOMBRE_SUBFAMILIA`,
       `fza_articulos_familias`.`NOMBRE_FAM_FAM`        AS `NOMBRE_FAM_FAM`,
       `fza_articulos_familias`.`DESCRIPCION_FAM`       AS `DESCRIPCION_FAM`,
       `fza_articulos_familias`.`INSTANTE_MODIF`        AS `INSTANTE_MODIF`,
       `fza_articulos_familias`.`INSTANTE_ALTA`         AS `INSTANTE_ALTA`,
       `fza_articulos_familias`.`USUARIO_ALTA`          AS `USUARIO_ALTA`,
       `fza_articulos_familias`.`USUARIO_MODIF`         AS `USUARIO_MODIF`
  FROM (`fza_articulos_familias`
        LEFT JOIN `fza_articulos_familias` `fza_articulos_familias2`
          ON (`fza_articulos_familias`.`CODIGO_SUBFAMILIA_FAM` = `fza_articulos_familias2`.`CODIGO_FAM_FAM`))
 ORDER BY `fza_articulos_familias`.`ORDEN_FAM`;

-- 4. vi_empresas -> ORDEN_EMP
--    El grid de empresas ya ordena en cliente (UniDataEmpresas: ORDER BY
--    orden_emp); se ordena tambien la vista por coherencia y para el resto de
--    consumidores de solo lectura.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empresas` AS
SELECT `fza_empresas`.`CODIGO_EMP_EMP`                AS `CODIGO_EMP_EMP`,
       `fza_empresas`.`ORDEN_EMP`                     AS `ORDEN_EMP`,
       `fza_empresas`.`ESACTIVO_EMP`                  AS `ESACTIVO_EMP`,
       `fza_empresas`.`RAZON_SOCIAL_EMP`              AS `RAZON_SOCIAL_EMP`,
       `fza_empresas`.`NIF_EMP`                       AS `NIF_EMP`,
       `fza_empresas`.`MOVIL_EMP`                     AS `MOVIL_EMP`,
       `fza_empresas`.`EMAIL_EMP`                     AS `EMAIL_EMP`,
       `fza_empresas`.`DIRECCION1_EMP`                AS `DIRECCION1_EMP`,
       `fza_empresas`.`DIRECCION2_EMP`                AS `DIRECCION2_EMP`,
       `fza_empresas`.`CODIGO_POSTAL_EMP`             AS `CODIGO_POSTAL_EMP`,
       `fza_empresas`.`POBLACION_EMP`                 AS `POBLACION_EMP`,
       `fza_empresas`.`PROVINCIA_EMP`                 AS `PROVINCIA_EMP`,
       `fza_empresas`.`NOMBRE_PAI_EMP`                AS `NOMBRE_PAI_EMP`,
       `fza_empresas`.`CODIGO_PAI_EMP`                AS `CODIGO_PAI_EMP`,
       `fza_empresas`.`IBAN_EMP`                      AS `IBAN_EMP`,
       `fza_empresas`.`GRUPO_ZONA_IVA_EMP`            AS `GRUPO_ZONA_IVA_EMP`,
       `fza_ivas_grupos`.`DESCRIPCION_IVA_IVAGRP`     AS `DESCRIPCION_IVA_IVAGRP`,
       `fza_empresas`.`ESRETENCIONES_EMP`             AS `ESRETENCIONES_EMP`,
       `fza_empresas`.`ESREGIMENESPECIALAGRICOLA_EMP` AS `ESREGIMENESPECIALAGRICOLA_EMP`,
       `fza_empresas`.`TEXTO_LEGAL_FACTURA_EMP`       AS `TEXTO_LEGAL_FACTURA_EMP`,
       `fza_empresas`.`CODIGO_CERTIFICADO_EMP`        AS `CODIGO_CERTIFICADO_EMP`,
       `fza_empresas`.`TITULAR_CERTIFICADO_EMP`       AS `TITULAR_CERTIFICADO_EMP`,
       `fza_empresas`.`TIPO_CERTIFICADO_EMP`          AS `TIPO_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_DESDE_CERTIFICADO_EMP`   AS `FECHA_DESDE_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_HASTA_CERTIFICADO_EMP`   AS `FECHA_HASTA_CERTIFICADO_EMP`,
       `fza_empresas`.`INSTANTE_MODIF`                AS `INSTANTE_MODIF`,
       `fza_empresas`.`INSTANTE_ALTA`                 AS `INSTANTE_ALTA`,
       `fza_empresas`.`USUARIO_ALTA`                  AS `USUARIO_ALTA`,
       `fza_empresas`.`USUARIO_MODIF`                 AS `USUARIO_MODIF`
  FROM (`fza_empresas`
        LEFT JOIN `fza_ivas_grupos`
          ON (`fza_empresas`.`GRUPO_ZONA_IVA_EMP` = `fza_ivas_grupos`.`IVA_IVAGRP`))
 ORDER BY `fza_empresas`.`ORDEN_EMP`;
