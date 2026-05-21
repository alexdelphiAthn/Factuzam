-- ============================================================================
-- fza_articulos_proveedores — un solo proveedor principal por articulo
--
-- Una version anterior de UpsertArticuloProveedor (en
-- inLibComprasSesionesMaterializar) marcaba ESPROVEEDORPRINCIPAL_AP='S'
-- siempre al insertar la relacion articulo-proveedor desde la
-- materializacion de la sesion. Si el articulo ya tenia otro proveedor
-- principal, acababa con dos filas ='S', y el Mto de Articulos los
-- mostraba como duplicados (vi_articulos filtra por principal y devolvia
-- multiples filas por articulo).
--
-- Este script deja un unico principal por articulo: respeta el primero
-- por INSTANTE_ALTA y degrada el resto a 'N'.
--
-- Idempotente: si tras el fix ya hay un unico principal por articulo,
-- el UPDATE no hace nada (no encuentra duplicados).
-- ============================================================================

UPDATE `fza_articulos_proveedores` AP
   SET AP.`ESPROVEEDORPRINCIPAL_AP` = 'N',
       AP.`INSTANTE_MODIF`          = NOW(),
       AP.`USUARIO_MODIF`           = 'Administrador'
 WHERE AP.`ESPROVEEDORPRINCIPAL_AP` = 'S'
   AND EXISTS (
         SELECT 1
           FROM `fza_articulos_proveedores` AP2
          WHERE AP2.`CODIGO_ART_AP`           = AP.`CODIGO_ART_AP`
            AND AP2.`ESPROVEEDORPRINCIPAL_AP` = 'S'
            AND (AP2.`INSTANTE_ALTA` < AP.`INSTANTE_ALTA`
                 OR (AP2.`INSTANTE_ALTA` = AP.`INSTANTE_ALTA`
                     AND AP2.`CODIGO_PRV_AP` < AP.`CODIGO_PRV_AP`)));
