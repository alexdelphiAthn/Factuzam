# Inventarios retroactivos y recálculo cronológico de stock/PMP

## Estado

Implementado el 4 de agosto de 2026. El cambio se entrega mediante
`inventarios_retroactivos_pmp.sql`; no modifica `factuzam_original.sql`.

## Regla de negocio

Un inventario es un cierre físico en el instante del recuento. Si después se
graba, modifica o anula un albarán o devolución con fecha anterior:

1. se reconstruye stock y PMP desde el primer instante afectado;
2. la salida de regularización del inventario se ajusta al stock que existe
   inmediatamente antes del recuento;
3. la entrada del inventario conserva la cantidad física contada;
4. los movimientos posteriores se vuelven a valorar cronológicamente.

Por tanto, el documento retroactivo modifica la regularización, pero no el
recuento. Factuzam conserva fecha y hora en `FECHA_MOV` y usa como desempate
`INSTANTE_ALTA` y `NUMERO_MOV`.

El PMP del recuento es el histórico calculado en ese instante, salvo que
`ESPRECIO_MEDIO_CORREGIDO_INVLIN = 'S'`. En ese caso se conserva exactamente
el PMP manual, incluido cero.

## Motor genérico

El contrato temporal agrupa por almacén y SKU la fecha mínima afectada. El
motor obtiene la semilla anterior, ordena el tramo por `FECHA_MOV`,
`INSTANTE_ALTA` y `NUMERO_MOV`, y actualiza:

- cantidad, PMP y coste de cada movimiento futuro;
- cantidad, PMP, valor total y acumuladores de
  `fza_articulos_stockactual`;
- datos teóricos y económicos de las líneas de inventario afectadas.

Los traspasos `TR`, `TA` y `AT` se calculan primero en origen. El coste de la
salida corregida se propaga a la entrada y después se recalcula el almacén de
destino. El procedimiento itera hasta cerrar todas las dependencias.

El motor expone envoltorios por movimiento, documento y operación. Las
inserciones, modificaciones, anulaciones y eliminaciones capturan siempre la
clave y fecha originales antes de cambiar la fila.

## Documentos y puntos de integración

| Flujo activo | Código | Actuación |
|---|---|---|
| Inventario | `IN` | Aplica atómicamente el par salida/entrada y recalcula desde un segundo antes del recuento. Mantiene el par incluso con cantidad cero. |
| Albarán de compra | `AC` | Fecha el lote con `FECHA_ALBC`, recalcula el documento y evita que una compra retroactiva sustituya los datos de última compra posteriores. |
| Devolución de compra | `DC` | Usa `FECHA_DEVC` y recalcula todas sus salidas. |
| Albarán de venta | `AV` | Fecha y recalcula el lote generado; las reversiones pasan por el borrado genérico. |
| Factura o venta de caja con stock | `FC` / `VE` | Recalcula una vez por documento u operación después de generar todas las líneas. |
| Traspaso manual o automático | `TR` / `TA` / `AT` | Incluye ambos almacenes y propaga el coste de origen a destino. |
| Depósito y escritor genérico | `DP` y otros | Recalcula por operación o por el movimiento insertado. |

Pedidos, presupuestos y facturas de compra no llaman al motor porque no crean
movimientos de almacén. Una factura que solo referencia movimientos ya
existentes tampoco los duplica.

`AE` queda únicamente como compatibilidad histórica de acumuladores. El
migrador legacy sigue convirtiendo `AE` a `AC`; no existe ningún flujo nuevo
que genere `AE`.

## Compatibilidad de inventarios anteriores

La migración completa de forma idempotente la pata que falte en inventarios
aplicados antiguos. Esto cubre, entre otros, el caso histórico de stock teórico
cero que solo guardaba la entrada física. Las líneas de diferencia cero que
una versión antigua eliminó no contienen ya cantidad ni instante de recuento y
no se pueden reconstruir automáticamente sin recuperar una copia o volver a
introducir el recuento.

Los identificadores de las dos patas nuevas usan un hash determinista de
empresa, almacén, serie, número y línea. Así no colisionan aunque el número del
inventario o la línea ocupen su longitud máxima.

## Atomicidad

Calcular líneas, crear las dos patas, recalcular movimientos futuros y cambiar
el estado a `APLICADO` forman una sola transacción. El recálculo independiente
y la eliminación de la regularización tienen sus propios envoltorios
transaccionales. Cualquier excepción revierte el bloque completo.

## Despliegue

1. Hacer copia de seguridad de la base de datos.
2. Ejecutar `inventarios_retroactivos_pmp.sql` una vez. Es idempotente y puede
   repetirse de forma segura.
3. Desplegar la aplicación compilada con el nuevo campo de inventario.
4. Ejecutar `pruebas_inventarios_retroactivos_pmp.sql` en una base de pruebas.

El script añade la columna de modo idempotente, amplía `LINEA_MOV` a diez
caracteres, completa pares históricos y recrea todos los procedimientos del
contrato. La columna es aditiva y no debe eliminarse en un rollback; una
retirada física requeriría copia y confirmación expresa.

## Cobertura verificada

La batería SQL comprueba:

- recuento físico y venta posterior;
- `AC` y `DC` anteriores al recuento, que modifican la regularización sin
  modificar lo contado;
- PMP histórico automático y PMP manual;
- propagación de coste entre ambos almacenes de un traspaso;
- compatibilidad de un inventario antiguo que solo tenía la pata de entrada;
- reejecución idempotente de la migración.

La aplicación y DUnitX se verifican en Release para Win32 y Win64.
