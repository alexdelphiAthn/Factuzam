# Pedidos de compra: cantidades desorbitadas (10/07/26)

## Síntoma

- Pedido con `Pedida` de cabecera disparada (2.304 con 28 unidades
  reales) y líneas con cantidades absurdas (696, 572, 568, 440).
- Líneas duplicadas por SKU con precio 0 que reaparecen al navegar
  (líneas 0071-0084 del pedido A1/000002, p. ej.).
- Cada click en la ficha añadía ~300 KB de log SQL.
- Los pedidos con líneas sin fusionar no muestran sus tallas en la
  vista por defecto hasta pulsar F1 (la fusión solo corre al entrar al
  grid o con F1, por diseño: mirar no debe escribir).

## Causa

El modo *Tallas horizontal* convierte el documento en cada cambio de
modo: el **des-pivote** (`TModoEntradaTallas.Desmontar`) expande cada
celda de talla a una línea por SKU y borra las celdas; la **fusión**
(`Construir` → `RederivarLineasExistentes`) hace lo contrario. Tres
defectos combinados:

1. `dsTablaGDataChangeHook` reconstruía el modo bandas
   (`mcsTallasHorPed`) en **cada** DataChange de la cabecera, no solo
   al cambiar de pedido. Un Post de la misma cabecera (recalculo de
   totales, `INSTANTE_MODIF`) disparaba rebuild → recálculo → Post →
   rebuild: tormenta de SQL por click.
2. El des-pivote **perdía unidades en silencio**: el paso 1 omite las
   celdas cuyo `ID_AV` ya no existe (JOIN interno a
   `fza_atributos_valores`) y las celdas de líneas inexistentes, pero
   el paso 4 borraba **todas** las celdas del documento igualmente.
3. `RefrescarTotalesTodasLineas` volcaba la suma de celdas sobre
   **cualquier** línea cuyo número coincidiera, incluidas líneas no
   pivotadas con celdas huérfanas heredadas: la cantidad real se
   machacaba con basura y el total de cabecera arrastraba la suma.

Además, las líneas residuo de expansiones rotas quedaron con precio 0
y el precio forma parte de la clave de fusión: nunca vuelven a
fusionar con la línea original y se perpetúan como duplicadas.

### Causa raíz transversal: cruce de LINEA como texto

`LINEA_PEDC_PEDCCEL` es `varchar(4)` pero la aplicación la escribe con
parámetro entero: en la tabla queda `'10'` sin relleno, mientras que
`LINEA_PEDCLIN` va rellena (`'0010'`). Todo SQL que cruce ambas
columnas **como texto** (`C.LINEA... = L.LINEA...`) falla en silencio
para líneas < 1000; solo funcionan las comparaciones contra parámetro
entero (coerción numérica de MariaDB). Consecuencias detectadas:

- `HayLineasSinPivotar` devolvía True SIEMPRE que hubiera líneas con
  SKU → cada entrada al grid reconstruía el documento entero
  (expansión + fusión): los ~400 KB de log SQL por click incluso tras
  arreglar el hook de DataChange.
- Almacenes del pedido, SKUs para etiquetas y expansión de etiquetas
  ignoraban el desglose por celdas.
- En **albaranes de compra** (mismo esquema varchar), los movimientos
  de almacén, el último precio de compra y los costes por SKU
  cruzaban celdas con el mismo fallo: los movimientos salían por la
  cantidad plana de la línea en vez del desglose por talla/almacén.
- En **devoluciones de compra**, ídem (movimientos y borrados por
  grupo).
- Compras por sesiones NO está afectada (`LINEA_SESLIN` y
  `LINEA_SES_SESCEL` son `int`).

Arreglo: todos esos cruces comparan ahora
`CAST(... AS UNSIGNED) = CAST(... AS UNSIGNED)`. Pendiente de decidir
por el usuario: el script histórico 539
(`albaranes_compra_total_unidades`, guardado en
`fza_generador_procesos` dentro de `factuzam_original.sql`) contiene
el mismo `NOT EXISTS` textual; al ejecutarse actualizó
`TOTAL_UNIDADES` también en líneas con celdas (impacto menor: para
las consolidadas `CANTIDAD` ya es su total). `factuzam_original.sql`
no se toca desde esta sesión.

## Arreglo en código

- `inMtoPedidosCompra.pas`: el hook solo reconstruye el modo bandas si
  cambia la clave serie|número (`FPedidoModoActual`).
- `inLibColumnasSkuModoTallas.pas`:
  - Invariante de unidades (`UnidadesDocumento` +
    `ComprobarInvarianteUnidades`): la fusión y el des-pivote comparan
    las unidades del documento antes y después dentro de su
    transacción; si no cuadran, excepción y **rollback** (el host
    degrada a modo SKU con los datos intactos). Ninguna conversión
    puede volver a perder ni duplicar unidades en silencio.
  - `RefrescarTotalesTodasLineas` ignora (y loguea) las celdas cuyo
    número de línea corresponde a una línea sin conjunto pivote.

## Reparación de datos

`pedidos_compra_reparar_cantidades.sql`:

- Bloque 0: diagnóstico (solo lectura) — celdas huérfanas, celdas con
  `ID_AV` inexistente, líneas descuadradas con sus celdas y líneas
  sospechosas de ser residuo (precio 0 conviviendo con la misma
  referencia a precio > 0).
- Bloque 1: borra celdas huérfanas.
- Bloque 2: resincroniza `CANTIDAD_PEDCLIN` / `TOTAL_PEDCLIN` de las
  líneas pivotadas con la suma de sus celdas.
- Las líneas residuo (bloque 0.4) se borran **a mano** desde la ficha
  tras revisarlas: no hay criterio mecánico seguro.
- Tras reparar, abrir cada pedido afectado y Grabar para recalcular
  los totales de cabecera y regenerar `fza_articulos_pdte_recibir`.
