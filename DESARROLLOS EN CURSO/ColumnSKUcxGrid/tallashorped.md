# tallashorped — Grid especial "Tallas en horizontal" para PEDIDOS DE VENTA

Estado: DISEÑO (pendiente de arrancar). 07/07/2026.

## 1. Objetivo

El modo tallas actual (`mcsTallasInline`, `inLibColumnasSkuModoTallas`)
CONSOLIDA líneas en una fila por artículo+color y guarda cantidades en
`fza_pedidos_celdas`. En pedidos de venta no encaja:

- Cada línea maneja TRES cantidades (pedida / entregada / pendiente) y
  una celda de pivote solo representa una.
- El precio es por SKU/línea; la consolidación pierde o machaca precios
  (mitigado con `ObtenerPrecioSku`, pero el modelo sigue siendo hostil).
- El pedido alimenta el albaraneado línea a línea
  (`LINEA_PED_ALBLIN`): fusionar líneas rompe la trazabilidad.

`tallashorped` replica el modelo de **compras → pedidos**
(`inLibGridPivoteCompra`): las líneas reales quedan SIEMPRE una por SKU
(cada una con su precio y sus cantidades) y el pivote es SOLO
presentación/edición encima del grid.

## 2. Decisiones cerradas (07/07/2026)

1. Formato: igual que compras→pedidos (fila por artículo+color,
   columnas de talla no-bound).
2. Edición en celdas: **pedida Y entregada**.
3. Sustituye al modo `mcsTallasInline` en pedidos de venta (F1 pasa a
   ciclar Desglose → SKU → tallashorped). `fza_pedidos_celdas` deja de
   usarse en ventas (la tabla se conserva; la usan otros documentos).

## 3. Modelo de datos

- **Sin tabla de celdas**: la verdad vive en `fza_pedidos_lineas`, una
  línea por SKU con `CANTIDAD_PEDLIN`, `CANTIDAD_ENTREGADA_PEDLIN`,
  `CANTIDAD_PENDIENTE_PEDLIN`, precio propio y vínculo con albaranes.
- Reutiliza las columnas ya añadidas por `pedidos_columnas_sku.sql`
  (`CODIGO_UNIDAD_PEDLIN`, `ATTR1..5`, `NUM_ATRIBUTOS_PEDLIN`).
- `ID_AC_PIVOT_PEDLIN` queda sin uso en este modo (se mantiene por
  compatibilidad con datos ya pivotados; ver §6 migración).
- **No requiere script SQL nuevo.**

## 4. Arquitectura

Nueva librería `src/Lib/inLibGridPivoteVenta.pas`, clon adaptado de
`inLibGridPivoteCompra` (no se toca la de compras para no arriesgar
producción; si al terminar ambas convergen, se estudia unificar):

- `TGridPivoteVentaConfig` (record): View, SourceMaster, SourceLineas,
  Gestor (`TGestorGridTallas`, se reutiliza tal cual), columnas
  no-bound, nombres de campos PEDLIN, y **dos campos de cantidad**:
  `FieldCantidadPedida` y `FieldCantidadEntregada`.
- `TGridPivoteVenta` (clase): cache de líneas representantes por
  clave artículo+color+**precio** (una fila visual por combinación),
  filtrado en cliente, publicación de cantidades en columnas no-bound,
  sombreado de celdas fuera de conjunto, swatch de color.
- Cada celda de talla mapea a la LÍNEA REAL del SKU correspondiente:
  - Editar **pedida**: si la línea del SKU existe → actualiza
    `CANTIDAD_PEDLIN`; si no existe → la crea (validador + precio de
    tarifa, mismo flujo fiscal que `AplicarArticuloPedido`); si queda a
    0 y sin entregas → pregunta y borra la línea.
  - Editar **entregada**: actualiza `CANTIDAD_ENTREGADA_PEDLIN` con
    tope en la pedida; recalcula `CANTIDAD_PENDIENTE_PEDLIN` y
    `ESENTREGADA_PEDLIN` (la lógica ya vive en el BeforePost del DM).
- Alternancia de banda visible **Pedida / Entregada** (botón o tecla)
  al estilo del intercambio Color↔Almacén de compras; la banda activa
  se indica en el caption de la pestaña. La celda muestra la cantidad
  de la banda activa; tooltip/status con las tres cantidades.
- Se integra como CUARTO implementador de `IModoEntradaGrid`
  (`GetModo` devuelve un nuevo `mcsTallasHorPed` del enum
  `TModoColumnasSku`) para encajar en `ConstruirModoEntrada` sin
  cambiar el contrato del host.

## 5. Comportamiento clave

- **Entrar/salir del modo NO transforma datos** (a diferencia de
  Rederivar/Desmontar del modo actual): solo cambia la presentación.
  Esto elimina toda la clase de bugs de pivote/des-pivote vistos el
  07/07/2026.
- Escaneo/tecleo de SKU: resuelve con `TArticulosValidador`; si la
  línea del SKU existe suma 1 a la pedida; si no, crea línea (precio
  por tarifa). La fila visual se refresca desde el cache.
- Líneas sin talla (artículos sin variación): fila normal con la
  cantidad en su columna clásica, como hace compras.
- Precios distintos del mismo artículo+color: filas visuales
  separadas (el precio forma parte de la clave del cache).

## 6. Integración en inMtoPedidos

1. Enum: añadir `mcsTallasHorPed` a `TModoColumnasSku`
   (`inLibColumnasSkuIntf`); factoría nueva
   `CrearModoEntradaGridPivoteVenta(Cfg, CfgPV)`.
2. `ConstruirModoEntrada`: rama `mcsTallasHorPed` en lugar de
   `mcsTallasInline`; el ciclo F1 pasa a
   Auto → SKU → TallasHorPed → Auto.
3. Retirar `mcsTallasInline` de pedidos (solo de pedidos: DTR lo
   mantiene).
4. **Migración de datos pivotados**: antes de retirar el modo viejo,
   al abrir un pedido con `ID_AC_PIVOT_PEDLIN > 0` o con filas en
   `fza_pedidos_celdas`, ejecutar una vez el des-pivote actual
   (`TModoEntradaTallas.Desmontar`, ya corregido para LINEA varchar)
   para expandir a línea-por-SKU. Dejar log del número de pedidos
   migrados.

## 7. Fases

1. `inLibGridPivoteVenta` con banda única (pedida) en lectura +
   cache/filtrado/columnas. Probar sobre un pedido real.
2. Edición de pedida por celda (crear/actualizar/borrar línea real).
3. Banda entregada: visualización + edición con tope y recálculo.
4. Escaneo dentro del modo (SumarLectura → línea del SKU).
5. Integración F1 + retirada de `mcsTallasInline` en pedidos +
   migración §6.4.
6. Regresión: crear albarán desde pedido con líneas editadas en el
   pivote; totales; Verifactu no afectado (no toca facturas).

## 8. Puntos abiertos

- ¿Indicador visual en celda cuando entregada > 0 con banda pedida
  activa (p.ej. esquina coloreada), para no ocultar información?
- ¿Edición de entregada limitada a usuarios con permiso de albaranear?
- Tope de columnas de talla: heredamos MaxColumnas=20 del gestor.
- Rendimiento con pedidos grandes (cache por artículo+color+precio:
  mismo enfoque que compras, que ya rinde bien).
