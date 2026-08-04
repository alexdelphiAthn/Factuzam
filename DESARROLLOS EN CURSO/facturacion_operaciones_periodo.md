# Facturación por periodo de operaciones TPV

La opción procesa las operaciones del TPV comprendidas entre dos fechas,
ambas inclusive, para la empresa, almacén y caja activos.

- `VE`: sólo ventas a contado sin cliente fiscal. Generan una proforma
  interna `PI`, sin asiento en `fza_facturas`, IVA fiscal ni VeriFactu.
- `TA` y el código histórico `AT`: generan una factura fiscal normal entre
  la empresa origen y la empresa destino. El coste capturado por el
  traspaso es la base neta; el IVA se obtiene del tipo del artículo y de la
  zona fiscal de la empresa origen.
- Las operaciones nuevas se agrupan por tipo y empresa destino. Una
  modificación posterior se agrupa por el documento anterior y genera un
  documento de diferencias. En TA el documento de diferencias es una
  rectificativa incremental relacionada con la factura anterior.

`fza_caja_facturaciones_periodo` conserva el documento y sus estados de
proceso. `fza_caja_facturacion_operaciones` encadena las versiones de cada
operación. `fza_caja_facturacion_lineas` conserva tanto el snapshot actual
como el delta incorporado al documento. La clave idempotente incluye la
versión anterior; por ello una reejecución idéntica no duplica documentos y
el ciclo de cambios A→B→A sí genera el ajuste correspondiente.

El informe usa una clave de documento inequívoca y muestra una banda
visible con documento y fecha antes de cada grupo de artículos.
