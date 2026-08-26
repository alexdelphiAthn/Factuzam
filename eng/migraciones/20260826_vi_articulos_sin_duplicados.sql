-- Garantiza una sola fila por articulo en vi_articulos.
--
-- La propiedad TEMPORADA puede existir en tres niveles:
--   * articulo: CODIGO_UNIDAD_ARTPROP = ''
--   * color:    ARTICULO/COLOR
--   * SKU:      ARTICULO/COLOR/TALLA
--
-- La vista historica no filtraba el nivel y cada temporada de color/SKU
-- multiplicaba la fila del articulo en Archivo > Articulos.

CREATE OR REPLACE ALGORITHM=UNDEFINED
SQL SECURITY DEFINER
VIEW `vi_articulos` AS
SELECT
  art.`CODIGO_ART_ART`,
  art.`ESACTIVO_ART`,
  art.`ESWEB_ART`,
  art.`ORDEN_ART`,
  art.`DESCRIPCION_ART`,
  art.`ESVARIACION_ART`,
  art.`ESTRAZABLE_ART`,
  art.`TIPO_ART`,
  art.`TIPO_VARIACION_ART`,
  art.`CODIGO_FAM_ART`,
  fam.`DESCRIPCION_FAM`,
  fam.`NOMBRE_FAM_FAM`,
  art.`TIPO_IVA_ART`,
  iva.`NOMBRE_TIPO_IVA_IVATIP`,
  art.`ESACTIVO_FIJO_ART`,
  art.`TIPO_CANTIDAD_ART`,
  ap.`CODIGO_PRV_AP`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`NOMBRE_PRV`,
  ap.`REF_PROVEEDOR_AP` AS `REF_PROVEEDOR`,
  COALESCE(pv.`PV`, atemp.`VALOR_LIBRE_ARTPROP`) AS `TEMPORADA_ART`,
  art.`INSTANTE_MODIF`,
  art.`INSTANTE_ALTA`,
  art.`USUARIO_ALTA`,
  art.`USUARIO_MODIF`
FROM `fza_articulos` art
LEFT JOIN `fza_articulos_familias` fam
  ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
LEFT JOIN `fza_articulos_proveedores` ap
  ON ap.`CODIGO_ART_AP` = art.`CODIGO_ART_ART`
 AND ap.`ESPROVEEDORPRINCIPAL_AP` = 'S'
LEFT JOIN `fza_proveedores` prv
  ON prv.`CODIGO_PRV_PRV` = ap.`CODIGO_PRV_AP`
LEFT JOIN `fza_ivas_tipos` iva
  ON iva.`CODIGO_ABREVIATURA_IVA_IVATIP` = art.`TIPO_IVA_ART`
LEFT JOIN `fza_articulos_propiedades` atemp
  ON atemp.`CODIGO_ART_ART` = art.`CODIGO_ART_ART`
 AND atemp.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
 AND atemp.`CODIGO_UNIDAD_ARTPROP` = ''
LEFT JOIN `fza_propiedades_valores` pv
  ON pv.`ID_PV_ARTPROP` = atemp.`ID_PV_ARTPROP`
ORDER BY art.`ORDEN_ART`;
