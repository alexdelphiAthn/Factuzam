# Plan técnico: inventarios retroactivos y recálculo futuro del PMP

## 1. Objetivo

Permitir que un inventario contado en un instante determinado se cargue y se
aplique días después sin alterar incorrectamente el stock ni el precio medio
ponderado de los movimientos posteriores.

Al finalizar la aplicación deben cumplirse simultáneamente estas reglas:

1. El stock en el instante del recuento queda fijado a la cantidad física.
2. Los movimientos posteriores al recuento se conservan en orden cronológico.
3. Una salida posterior conserva el PMP vigente inmediatamente antes de ella.
4. Una entrada posterior recalcula el PMP mediante media ponderada.
5. El PMP del inventario es el histórico del recuento, salvo que el usuario
   haya indicado expresamente una nueva valoración.
6. `fza_articulos_stockactual` coincide con el último movimiento recalculado.

## 2. Diagnóstico del comportamiento actual

El procedimiento `SP_RECALCULAR_PMP_LOTE_ALMACEN` ya vuelve a recorrer los
movimientos activos de los SKU afectados, ordenados por fecha, y actualiza el
PMP, el coste de cada movimiento y el stock actual. Por tanto, ya incluye los
movimientos posteriores a un inventario retroactivo.

El defecto está en el punto de partida del recálculo:

- al crear o importar una línea se copia el PMP actual de
  `fza_articulos_stockactual` en `PRECIO_MEDIO_INVLIN` y
  `PRECIO_MEDIO_NUEVO_INVLIN`;
- al aplicar un inventario retroactivo se obtiene correctamente el PMP
  histórico del instante del recuento;
- sin embargo, `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO` solo sustituye
  `PRECIO_MEDIO_NUEVO_INVLIN` cuando vale cero o `NULL`;
- si hubo entradas después del recuento, ese campo puede contener el PMP
  actual, ya ponderado con dichas entradas, y se introduce retroactivamente
  como valoración del inventario;
- el recálculo cronológico procesa después otra vez las entradas posteriores,
  de modo que su efecto económico queda aplicado dos veces.

No se debe resolver suprimiendo el recálculo existente. Hay que distinguir
entre un PMP rellenado automáticamente y una corrección expresa del usuario.

## 3. Decisión de diseño

### 3.1 Indicador explícito de valoración manual

Añadir a `fza_inventarios_lineas` la columna propuesta:

```sql
ESPRECIO_MEDIO_CORREGIDO_INVLIN varchar(1) NOT NULL DEFAULT 'N'
```

Valores:

- `N`: el PMP del inventario se obtiene del histórico en el instante del
  recuento;
- `S`: se conserva `PRECIO_MEDIO_NUEVO_INVLIN` porque el usuario o una
  importación lo ha indicado expresamente.

La columna sigue la convención de booleanos `ES...` y el sufijo `INVLIN`. No se
utilizará el valor cero como indicador de ausencia, porque cero puede ser una
valoración válida elegida por el usuario.

### 3.2 Regla de cálculo del inventario

Por cada línea:

1. Calcular `v_STOCK_HIST` y `v_PMP_HIST` con los movimientos activos hasta
   `FECHA_RECUENTO_INVLIN`.
2. Guardar siempre `v_PMP_HIST` en `PRECIO_MEDIO_INVLIN`.
3. Si `ESPRECIO_MEDIO_CORREGIDO_INVLIN = 'N'`, copiar `v_PMP_HIST` en
   `PRECIO_MEDIO_NUEVO_INVLIN`.
4. Si vale `S`, conservar el PMP nuevo indicado expresamente.
5. Calcular la diferencia de unidades y de coste con esos valores.
6. Generar la salida del stock teórico un segundo antes del recuento y la
   entrada de la cantidad física en el instante del recuento.
7. Recalcular cronológicamente los SKU afectados.

### 3.3 Recálculo futuro

En la primera entrega se mantendrá `SP_RECALCULAR_PMP_LOTE_ALMACEN`, que
recalcula el historial completo de los SKU afectados. Es la opción más segura:
también reconstruye correctamente la semilla anterior al recuento y ya está
optimizada para trabajar en lote.

Como segunda fase, condicionada a mediciones de rendimiento, se podrá crear
`SP_RECALCULAR_PMP_LOTE_DESDE`. Esta versión deberá recibir para cada SKU el
primer instante afectado y:

1. calcular stock y PMP inmediatamente anteriores al corte;
2. recalcular únicamente movimientos iguales o posteriores al corte;
3. aplicar un orden total y determinista por `FECHA_MOV`, `INSTANTE_ALTA` y
   `NUMERO_MOV`;
4. recalcular los acumulados de `fza_articulos_stockactual` sobre el historial
   completo, aunque el PMP se recorra solo desde el corte;
5. dejar a cero los SKU sin movimientos activos.

La versión desde fecha no sustituirá al recálculo completo hasta demostrar en
pruebas que produce exactamente los mismos resultados.

### 3.4 Alcance por documento

El motor genérico no actúa directamente sobre las tablas de documentos. Cada
servicio que inserta, modifica, anula o borra filas de
`fza_movimientos_almacen` debe registrar las claves afectadas y llamar al
recálculo dentro de la misma transacción.

| Documento u operación | Tipo de movimiento | Actuación |
|---|---|---|
| Inventario | `IN`, salida más entrada | Fijar cantidad y PMP en el instante del recuento y recalcular cada SKU desde la menor fecha de recuento. |
| Albarán de compra | `AC`, entrada | Si se intercala en el historial, recalcular desde `FECHA_ALBC`. Al modificar o borrar, registrar las claves y fechas anteriores antes de revertir. |
| Devolución de compra | `DC`, salida | Recalcular desde la fecha de devolución cuando sea retroactiva o cambien fecha, cantidad, SKU, almacén o estado. |
| Albarán de venta | `AV`, salida | Revalorar la salida y todos los movimientos posteriores cuando se intercale, modifique, anule o borre. |
| Venta de caja o factura que mueve stock | `VE` o `FC`, normalmente salida | Recalcular cuando la operación se introduzca con fecha anterior o se corrija. Respetar la deduplicación existente entre venta de caja y factura para no generar stock dos veces. |
| Traspaso | `TR`, `TA` o `AT`, salida y entrada | Recalcular primero el almacén de origen, propagar a la entrada el coste de salida ya corregido y recalcular después el almacén de destino. |
| Depósito o préstamo | `DP`, entrada o salida | Recalcular cada almacén y SKU afectado desde la fecha de la operación. Si el flujo se materializa actualmente como `TR`, aplicar la regla de traspasos. |
| Importación, migración o mantenimiento de movimientos | Cualquier tipo | Agrupar por almacén y SKU y recalcular desde el movimiento más antiguo insertado o alterado. |

`AE` no se considera un documento activo distinto. Es el código de «albarán de
entrada» del sistema legacy y el migrador lo convierte en `AC`, albarán de
compra, al llevarlo a Factuzam. El motor genérico seguirá siendo capaz de
recalcular filas históricas `AE` que ya existan en alguna instalación, y los
informes o acumuladores podrán mantener su compatibilidad, pero no se añadirá
ningún punto de integración nuevo que genere movimientos `AE`.

No llaman al motor por sí mismos los documentos que no crean movimientos de
almacén:

- pedidos de compra y de venta;
- facturas de compra, porque el stock se recibe mediante el albarán de compra;
- presupuestos, solicitudes y documentos pendientes;
- una factura de venta que reutiliza movimientos ya creados por caja o por un
  albarán, mientras no los modifique.

La regla de activación no es «fecha anterior a hoy». Para cada combinación de
almacén y SKU se debe comprobar si el movimiento nuevo queda antes de otro
movimiento ya existente. Si queda al final del historial puede mantenerse el
camino incremental; si se intercala, se invoca el recálculo desde el primer
instante afectado.

Una modificación debe considerar los valores anteriores y los nuevos:

- cambio de fecha: recalcular desde la menor fecha;
- cambio de SKU o almacén: recalcular tanto la clave anterior como la nueva;
- cambio de cantidad, coste, dirección o estado activo: recalcular desde la
  fecha original;
- borrado o anulación: capturar clave y fecha antes de eliminar o desactivar;
- documento con varias líneas: agrupar en lote y conservar la menor fecha por
  almacén y SKU.

El albarán de compra requiere además corregir sus datos derivados de «última
compra». Deben seleccionarse por la mayor fecha documental válida, no por el
último documento grabado, para que un albarán retroactivo no sustituya el
precio de compra más reciente.

## 4. Cambios previstos

### 4.1 Script SQL idempotente

Crear `DESARROLLOS EN CURSO/inventarios_retroactivos_pmp.sql` con estas
responsabilidades:

1. Comprobar en `INFORMATION_SCHEMA.COLUMNS` si existe
   `ESPRECIO_MEDIO_CORREGIDO_INVLIN` antes de añadirla.
2. Inicializar las líneas abiertas existentes:
   - `S` cuando el PMP nuevo difiera del PMP anterior, porque existe una
     corrección material;
   - `N` cuando ambos valores coincidan.
3. Recrear de forma idempotente
   `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO`.
4. Recrear `PRC_FZA_INVENTARIOS_APLICAR` para leer y respetar el indicador.
5. Recrear `SP_RECALCULAR_PMP_LOTE_ALMACEN` únicamente si se incorporan en el
   mismo cambio el orden determinista o correcciones necesarias para el nuevo
   contrato.
6. No modificar `factuzam_original.sql`.

El filtro de empresa de los movimientos se revisará antes de codificar. El
procedimiento recibe `p_EMPRESA`, pero el recálculo actual selecciona por
almacén y SKU. No debe añadirse un filtro sin confirmar primero si los códigos
de almacén son globales o dependen de la empresa.

### 4.2 Aplicación Delphi

Actualizar los puntos de entrada de inventarios:

- `inLibInventariosEntradaDataSet.pas`: el llenado automático deja
  `ESPRECIO_MEDIO_CORREGIDO_INVLIN = 'N'`;
- `inLibInventariosAplicacion.pas`: una importación con PMP informado escribe
  el valor y marca el indicador como `S`; CSV o recuentos sin PMP lo dejan en
  `N`;
- `UniDataInventarios.pas/.dfm`: incorporar el campo al `TClientDataSet`, al
  SQL de actualización y a los valores por defecto;
- `inMtoInventarios.pas/.dfm` y la presentación dinámica: mostrar una columna
  booleana «PMP corregido» o una acción equivalente. Editar manualmente «PMP
  nuevo» debe marcarla como `S`; desmarcarla debe restaurar el modo automático;
- recuento remoto: la hora del último escaneo se conserva y el PMP queda en
  modo automático salvo que el origen transmita expresamente una valoración;
- exportación e importación Excel: conservar la distinción entre PMP presente
  y ausente mediante el indicador ya disponible `TienePmp`.

No se añadirá una columna visual independiente si la experiencia resulta más
clara con una acción «Usar PMP histórico». La decisión debe mantener visible
para el usuario si el precio es automático o corregido.

### 4.3 Atomicidad

Revisar la frontera transaccional entre
`PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO` y
`PRC_FZA_INVENTARIOS_APLICAR`. Actualmente el primer procedimiento abre y
cierra su propia transacción antes de que el segundo empiece la aplicación.

La solución final debe evitar que un error deje las líneas recalculadas pero
el inventario sin aplicar. Opciones a validar:

- extraer el cálculo a un procedimiento interno sin `COMMIT` y mantener dos
  envoltorios transaccionales;
- o ejecutar la actualización histórica dentro de la misma transacción de
  aplicación.

El botón independiente «Recalcular» debe seguir funcionando de manera
atómica.

## 5. Orden de implementación

### Fase 1. Caracterización

1. Preparar un escenario reproducible con un SKU, stock y PMP conocidos.
2. Registrar un recuento histórico.
3. Añadir después una venta y una compra a distinto coste.
4. Reproducir y documentar el PMP incorrecto actual.
5. Guardar consultas de línea base para movimientos y stock actual.

### Fase 2. Semántica del PMP del inventario

1. Crear el script idempotente de la columna y la migración de datos abiertos.
2. Adaptar los procedimientos de actualización y aplicación.
3. Adaptar todos los caminos Delphi que crean o importan líneas.
4. Añadir la indicación visible de PMP automático o corregido.
5. Mantener compatibilidad de lectura con inventarios ya aplicados.

### Fase 3. Recálculo y atomicidad

1. Confirmar que el procedimiento en lote procesa todos los movimientos
   posteriores al recuento.
2. Añadir un desempate determinista para fechas iguales y auditorías nulas.
3. Unificar la transacción del cálculo histórico, la regularización, el
   recálculo futuro y el cambio de estado a `APLICADO`.
4. Verificar que un error revierte movimientos, líneas, stock actual y estado.

### Fase 4. Optimización desde fecha

1. Medir el recálculo completo con volúmenes reales.
2. Implementar la variante desde fecha solo si el tiempo de respuesta lo
   justifica.
3. Ejecutar ambas variantes sobre copias idénticas y comparar todas las
   columnas económicas y de stock.
4. Mantener el procedimiento completo como referencia y mecanismo de
   reparación.

## 6. Plan de pruebas

Crear una carpeta específica, por ejemplo
`DESARROLLOS EN CURSO/pruebas_inventarios_retroactivos_pmp/`, con preparación,
verificaciones y limpieza controlada.

Casos mínimos:

1. Inventario aplicado inmediatamente y sin movimientos posteriores.
2. Inventario aplicado tres días después con solo ventas posteriores.
3. Inventario aplicado tres días después con una entrada al mismo coste.
4. Inventario aplicado tres días después con una entrada a coste distinto.
5. Venta, entrada, devolución y traspaso posteriores combinados.
6. PMP histórico fraccionario para evitar regresiones por redondeo.
7. Stock contado igual a cero.
8. Stock histórico cero o negativo antes de una entrada.
9. Corrección manual de PMP distinta del histórico.
10. Corrección manual de PMP a cero.
11. Importación Excel con PMP y sin PMP.
12. Recuento remoto con hora exacta y movimientos del mismo día.
13. Varios SKU y dos almacenes sin contaminación cruzada.
14. Movimientos con la misma `FECHA_MOV` y `INSTANTE_ALTA` nulo.
15. Excepción forzada durante la aplicación para verificar el `ROLLBACK`.
16. Reejecución del script de migración para comprobar su idempotencia.

Para cada caso se comprobará:

- stock y PMP inmediatamente antes del recuento;
- par de movimientos de inventario y su orden;
- PMP y `TOTAL_COSTE_MOV` de cada movimiento posterior;
- cantidad, PMP, valor y acumulados en `fza_articulos_stockactual`;
- estado y totales del inventario;
- ausencia de cambios en otros almacenes y SKU.

## 7. Criterios de aceptación

La solución se considerará terminada cuando:

1. Un inventario cargado tres días después deja el stock actual igual a la
   cantidad contada más el neto de movimientos posteriores.
2. Las ventas posteriores no modifican el PMP y quedan valoradas al PMP
   vigente en su instante.
3. Las entradas posteriores ponderan una sola vez su coste.
4. Sin corrección manual, el PMP del recuento coincide con el PMP histórico.
5. Con corrección manual, se respeta exactamente el valor indicado, incluido
   cero.
6. El recálculo repetido produce el mismo resultado.
7. Una excepción no deja efectos parciales.
8. Las pruebas existentes de costes, inventarios y stock siguen pasando.
9. El tiempo de aplicación se mantiene dentro del umbral que se acuerde con
   una carga representativa.

## 8. Despliegue y rollback

Orden de despliegue:

1. Copia de seguridad y captura de `SHOW CREATE PROCEDURE` de los
   procedimientos afectados.
2. Ejecutar el script idempotente de base de datos.
3. Verificar columna, procedimientos y migración de inventarios abiertos.
4. Desplegar la aplicación Delphi compatible con el nuevo indicador.
5. Ejecutar la batería rápida de aceptación en una base de pruebas.
6. Activar en producción y revisar los primeros inventarios retroactivos.

Rollback seguro:

- restaurar los procedimientos anteriores y la versión anterior de la
  aplicación;
- conservar la columna aditiva, aunque quede sin uso, para no perder la
  intención de valoración ya registrada;
- no eliminar la columna automáticamente. Un rollback físico con `DROP`
  requerirá confirmación expresa y copia previa de sus valores.

## 9. Entregables previstos

1. `inventarios_retroactivos_pmp.sql`, idempotente.
2. Cambios Delphi en entrada, importación, datos y presentación.
3. Batería SQL reproducible y documento de resultados.
4. Script o instrucciones de rollback lógico.
5. Medición comparativa del recálculo completo y, si procede, desde fecha.
