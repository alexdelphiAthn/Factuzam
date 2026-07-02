-- ==========================================================================
-- Script: quitar_tarifa_defecto_duplicada.sql
-- Fecha:  2026-07-02
-- Desc:   Deja UNA sola definición de la tarifa por defecto del sistema:
--         el parámetro de caja 'vgerDefTarifa' (Parámetros de Caja >
--         Configuración de Caja, formulario frmMtoCajaParam).
--
--         Elimina de fza_usuarios_perfiles los valores guardados de los
--         parámetros de aplicación ya retirados del código:
--           - appTarifaDefecto  (Valores por defecto, frmMtoAppParam)
--           - appTarifaDefault  (Ventas, frmMtoAppParam; nunca se leía)
--
--         En código (inLibAppParam) ya no se registran, así que si no se
--         borran aparecerían como huérfanos. Idempotente.
--
--         NOTA: el flag ESDEFAULT_TAR de fza_tarifas se elimina con el
--         script anterior 'quitar_esdefault_tar.sql' (2026-05-25).
--         Ejecutarlo antes si la BBDD aún tiene esa columna.
-- ==========================================================================

-- 1. Borrar los valores guardados de los parámetros retirados
--    (cualquier usuario/grupo)
DELETE FROM fza_usuarios_perfiles
 WHERE KEY_USUPER = 'frmMtoAppParam'
   AND SUBKEY_USUPER IN ('appTarifaDefecto', 'appTarifaDefault');

-- 2. Garantizar que exista el parámetro de caja para 'Todos' con el valor
--    que tuviera el antiguo appTarifaDefecto no es necesario: vgerDefTarifa
--    ya existe (PVP por defecto en código). Si en alguna instalación la
--    tarifa por defecto NO era PVP, fijarla manualmente en
--    Parámetros de Caja o con:
--
--    INSERT INTO fza_usuarios_perfiles
--      (USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER,
--       INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)
--    VALUES
--      ('Todos', 'frmMtoCajaParam', 'vgerDefTarifa', 'XXX',
--       NOW(), 'Administrador', 'Administrador')
--    ON DUPLICATE KEY UPDATE VALUE_USUPER = VALUES(VALUE_USUPER);
