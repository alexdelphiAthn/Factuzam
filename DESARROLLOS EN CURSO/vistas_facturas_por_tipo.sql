-- =============================================================================
-- Vistas especializadas por TIPO_FAC
-- =============================================================================
-- Cada pantalla descendiente de TfrmMtoFacturasBase consulta su propia
-- vista: el filtrado por TIPO_FAC lo hace el motor de BD, no el form.
--
-- - vi_facturas_normales:       solo facturas TIPO_FAC = 'NORMAL'
--                               (pantalla 'Facturas' en Venta Mayor)
-- - vi_facturas_simplificadas:  solo facturas TIPO_FAC = 'SIMPLIFICADA'
--                               (pantalla en Caja, commit 3)
--
-- Heredan toda la salida de vi_facturas (que ya incluye join con
-- fza_formas_pago y los totales), asi que cualquier cambio de columnas
-- en vi_facturas se propaga automaticamente a ambas. Idempotente.
-- =============================================================================

CREATE OR REPLACE VIEW vi_facturas_normales AS
SELECT * FROM vi_facturas WHERE TIPO_FAC = 'NORMAL';

CREATE OR REPLACE VIEW vi_facturas_simplificadas AS
SELECT * FROM vi_facturas WHERE TIPO_FAC = 'SIMPLIFICADA';
