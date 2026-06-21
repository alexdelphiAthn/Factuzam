# efectos_remesas_venta.sql

Instala la cartera de efectos de cobro para Venta Mayor, equivalente a la
funcionalidad de efectos/remesas de Compras pero orientada a clientes.

## Objetos

- `fza_efectos_venta` (`EFV`): vencimientos de cobro generados desde
  `fza_facturas`.
- `fza_remesas_venta` (`REMV`): agrupacion de efectos para remesa de cobro.
- Vistas: `vi_efectos_venta`, `vi_efectos_venta_pendientes`,
  `vi_remesas_venta`.
- Procedimientos:
  - `PRC_EFV_GENERAR_DESDE_FACTURA`
  - `PRC_EFV_CONCILIAR_COBRO`
  - `PRC_REMV_CREAR`
  - `PRC_REMV_ANYADIR_EFECTO`
  - `PRC_REMV_RECALCULAR`

## Uso en la aplicacion

- En Venta Mayor > Borradores, la pestaña 3 muestra efectos para facturas
  normales y mantiene recibos para simplificadas.
- `Generar efectos` crea los vencimientos segun la forma de pago.
- `Cobrado` abre el modal de conciliacion con fecha, importe, tipo y
  referencia.
- Venta Mayor incorpora entradas de menu para `Efectos de cobro`,
  `Remesas de cobro` y `Cargar efectos en remesa`.
