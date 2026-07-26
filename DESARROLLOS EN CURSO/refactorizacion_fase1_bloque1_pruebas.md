# Plan de pruebas — Fase 1, bloque 1 (pasos 1.4 y 1.1)

Cambios cubiertos:

- **1.4** El fallo del cálculo de totales ya no se silencia: `inLibtb.ActualizarLineaFacturaGen`
  aborta la edición con excepción si `ProcesarFacturaCompleta` devuelve `False`, y
  `inLibFacturas` registra la causa original (clase + mensaje) en el log.
- **1.1** El borrado de factura es atómico: transacción abierta en `BeforeDelete`,
  `Commit` en `AfterDelete` (nuevo handler `unqryTablaGAfterDeleteTx`), `Rollback` en
  `OnDeleteError` (nuevo `unqryTablaGDeleteErrorTx`) o en el `except` del propio
  `BeforeDelete`. Los dos `with … Free` sin protección pasaron a `try/finally`
  con `FreeAndNil`.

**TODO en BBDD DE PRUEBAS.** Ninguna prueba de este plan se ejecuta contra producción.
Requisito previo: compilar sin errores ni hints nuevos.

---

## Bloque A — Recalculo de totales (1.4)

| # | Prueba | Resultado esperado |
|---|---|---|
| A1 | Factura normal: editar cantidad y precio en varias líneas, grabar | Totales correctos, sin cambio de comportamiento |
| A2 | Cambiar el % de descuento de una línea y comprobar el total en pantalla | El evento de actualización del total sigue refrescando el pie |
| A3 | **Fallo provocado**: en BBDD de pruebas, poner a NULL los porcentajes de IVA de la cabecera de una factura borrador (`UPDATE fza_facturas SET PORCENTAJE_IVAN_FAC = NULL WHERE …`) u otra corrupción que haga fallar el cálculo; editar una línea | Aparece el error "Error al recalcular totales de la factura: …", la edición NO se graba, y el log (`inLibLog`) contiene la entrada `TFacturaTotales.ProcesarFacturaCompleta (EClase): mensaje` |
| A4 | Tras cancelar el error de A3, corregir el dato y volver a editar | El flujo se recupera sin reiniciar la aplicación |
| A5 | Ticket de caja (usa la misma cadena de cálculo) | Venta normal sin cambios |

Atención especial en A3: antes del cambio la línea se grababa con totales
obsoletos sin avisar; el nuevo comportamiento (excepción visible) es el objetivo
de la prueba, no un fallo.

## Bloque B — Borrado atómico de factura (1.1)

Preparación: factura borrador con 3+ líneas, recibos/efectos generados y
movimientos de stock (marcar ESMUEVE_STOCK o usar simplificada consolidada y
devuelta a borrador según el flujo habitual). Anotar antes de cada prueba:

```sql
SELECT COUNT(*) FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN=? AND NUMERO_FAC_FACLIN=?;
SELECT COUNT(*) FROM fza_recibos        WHERE SERIE_FAC_REC=?    AND NUMERO_FAC_REC=?;
SELECT COUNT(*) FROM fza_efectos_venta  WHERE SERIE_FAC_EFV=?    AND NUMERO_FAC_EFV=?;
SELECT COUNT(*) FROM fza_movimientos_almacen WHERE …;   -- según claves de movimiento
```

| # | Prueba | Resultado esperado |
|---|---|---|
| B1 | Borrado normal: confirmar el diálogo | Cabecera, líneas, recibos, efectos y movimientos desaparecen; los SELECT devuelven 0 |
| B2 | Responder "No" al diálogo de confirmación | No se borra NADA (los Abort previos a la transacción siguen funcionando) |
| B3 | Factura en fase distinta de BORRADOR | Mensaje de Verifactu y no se borra nada |
| B4 | Factura con efectos cobrados/remesados | Mensaje "No puede borrarse" y no se borra nada (este Abort ocurre ya dentro de la transacción: verificar con los SELECT que efectos y líneas siguen intactos) |
| B5 | **Fallo provocado a mitad**: en BBDD de pruebas, `RENAME TABLE fza_recibos TO fza_recibos_x;` y borrar una factura | Error visible; los SELECT muestran la factura ÍNTEGRA (líneas y efectos incluidos — antes del cambio quedaban borrados). Restaurar con `RENAME TABLE fza_recibos_x TO fza_recibos;` |
| B6 | **Fallo en la cabecera**: bloquear la fila de cabecera desde otra sesión MySQL (`START TRANSACTION; SELECT … FOR UPDATE;`) con `innodb_lock_wait_timeout` bajo, y borrar desde la app | Error de lock; al liberar, la factura sigue completa (rollback vía `OnDeleteError`) |
| B7 | Borrar dos facturas seguidas en la misma sesión | Ambas se borran; sin errores de "transacción ya activa" (el flag `FTransBorradoPropia` se resetea) |
| B8 | Verificación de no-regresión: crear factura nueva después de un borrado | Numeración y grabación normales |

## Bloque C — Regresión mínima

| # | Prueba | Resultado esperado |
|---|---|---|
| C1 | Consolidar una factura con movimiento de stock | Igual que antes (la generación de movimientos NO se ha tocado en este bloque; va en el 1.2) |
| C2 | Imprimir factura | Sin cambios |

## Criterio de salida

A1–A5 y B1–B8 al 100%. En especial B5: es la prueba que justifica todo el bloque.
Si B5 falla (se pierden líneas con la factura viva), revisar que `unqryTablaG`
tiene `AfterDelete`/`OnDeleteError` asignados (se cablean en `DataModuleCreate`,
líneas ~1040) y que la conexión del dataset es `ConexionPrincipal`.

Siguiente bloque de la Fase 1 tras validar este: 1.3 (transacción en
`CrearAlbaranDesdePedido`) y después 1.2 + 1.6 (movimientos de almacén + índice
único, con su propia prueba de concurrencia).
