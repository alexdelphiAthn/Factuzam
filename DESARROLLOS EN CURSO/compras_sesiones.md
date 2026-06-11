# Compras — Sesiones (pre-pedidos / pre-albaranes)

Diseño del módulo de **Sesiones de Compra**: documentos borrador donde el usuario
prepara artículos, atributos, precios y cantidades antes de materializarlos en
las tablas maestras (`fza_articulos`, `fza_articulos_skus`, `fza_articulos_tarifas`,
`fza_codigos_barras`, `fza_articulos_proveedores`) y generar el documento
posterior (pedido y/o albarán de compra).

---

## 1. Principio rector

Una sesión es **puramente borrador**. Mientras el usuario edita:

- **NO** se inserta nada en `fza_articulos`.
- **NO** se generan SKUs en `fza_articulos_skus`.
- **NO** se crean códigos de barras en `fza_codigos_barras`.
- **NO** se enlaza al proveedor en `fza_articulos_proveedores`.
- **NO** se crean ni modifican tarifas en `fza_articulos_tarifas`.
- **NO** se mueve stock ni se crean líneas de pedido/albarán de compra.

Todo vive en las tablas de la sesión (`fza_compras_*`). Sólo cuando el usuario
pulsa **«Crear artículos y documentos»** se materializa:

1. Altas en `fza_articulos` (cabecera de artículo).
2. Vinculación de conjuntos de atributos en `fza_articulos_conjuntos_asign`.
3. Altas de SKUs en `fza_articulos_skus` + `fza_atributos_sku` (valores).
4. Altas de propiedades fijas en `fza_articulos_propiedades`.
5. Generación de EAN13 (uno por SKU) en `fza_codigos_barras` vía `inLibEAN13`.
6. Alta o actualización en `fza_articulos_proveedores` con **precio de coste**
   (último de compra) y referencia del proveedor.
7. Altas en `fza_articulos_tarifas` con el **precio de venta** calculado para
   la tarifa elegida en cabecera de sesión. Ver §2.5 para la fórmula.
8. Generación del documento elegido:
   - **Pedido de compra** → `fza_pedidos_compra` + `fza_pedidos_compra_lineas`
     (sin mover stock, anota cantidades pendientes de recibir en la tabla de stock).
   - **Albarán de compra** → `fza_albaranes_compra` + líneas + movimientos en
     `fza_movimientos_almacen` con entrada por SKU (cantidad pivotada).
   - O **ambos** secuencialmente a través del procedimiento `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`.

La sesión queda **cerrada** con referencia a los documentos generados; no se
puede volver a materializar. Sí se puede **clonar** para arrancar otra sesión.

---

## 2. Conceptos clave

### 2.1 Plantilla de cabecera

En la cabecera de la sesión el usuario decide, **antes de empezar a meter
artículos**:

- **Proveedor**, **familia objetivo**, **almacén destino** (para albarán),
  **moneda**, **tipo de IVA**, **margen por defecto** (% sobre precio compra
  → precio venta sugerido), **tarifa de salida**.
- **Variación a aplicar** (ej: `TC = Tallas y Colores`) y los **conjuntos de
  atributos** (ej: tallas = «42-46 Caballero», colores = «Colores Básicos
  Verano»). Esto fija los ejes de la matriz pivotada y los SKUs que se
  generarán por cada artículo de la sesión.
- **Propiedades comunes** con marcador **fijo / variable**:
  - **Fijo** → todas las líneas heredan ese valor y no se puede cambiar
    (ej: `TEMPORADA = Primavera-Verano 2026`, `MARCA = Acme`).
  - **Variable** → se muestra como columna editable por línea con valor por
    defecto (ej: `MATERIAL` permite valor por defecto «Algodón» pero se
    cambia por línea).

### 2.2 Kits de cantidades

Un **kit** es un patrón de cantidades sobre el atributo que pivota
(ej: tallas). Ejemplos:

| Kit         | 38 | 39 | 40 | 41 | 42 | 43 |
|-------------|----|----|----|----|----|----|
| `CURVA-STD` | 1  | 2  | 3  | 3  | 2  | 1  |
| `CURVA-XL`  | 0  | 1  | 2  | 3  | 3  | 2  |
| `MUESTRA`   | 1  | 1  | 1  | 1  | 1  | 1  |

Los kits se definen a nivel de cabecera de sesión (o se importan de una
biblioteca de kits del proveedor). En la matriz, junto a cada fila (cada
combinación de atributos no-pivotados, p.ej. cada color) hay un botón
**«Aplicar kit»** con selector. Al aplicarlo, las cantidades del kit se
copian sobre la fila respetando la correspondencia talla → valor.

> ✅ Implementado (variante grid inline): la **biblioteca de kits del
> proveedor** vive en `fza_proveedores_kits` / `_det` (sufijos `PRVKIT` /
> `PRVKITD`), se mantiene en la pestaña «Compras» de Proveedores y se
> aplica sobre la línea con foco desde el botón «Aplicar kit» de Líneas o
> desde la pestaña «Proveedor» de la sesión. Detalle en
> `proveedores_compras_defectos.md`.

### 2.3 Matriz pivotada — regla simple

> **El último atributo (mayor `ORDEN_VA` en `fza_variaciones_atributos`)
> pivota como columnas. El resto define filas.**

Para `TC` con orden `CO=20`, `TAL=10` el comportamiento depende del libro de
estilo actual; revisar el orden real en producción. Convención asumida:

- Las **columnas** se construyen a partir del conjunto del atributo de mayor
  orden visual (talla).
- Las **filas** se construyen como el producto cartesiano de los conjuntos
  de los demás atributos (color, y opcionalmente más).
- Cada **celda** = (línea, fila, columna) → `CANTIDAD`.

Si la variación tiene un solo atributo, la matriz se degenera a una fila
única. Si no hay variación (artículo simple), la línea expone únicamente
una cantidad escalar.

### 2.3-bis Multidimensionalidad — variación por línea

Cada **línea** decide su propia variación. La cabecera define un valor por
defecto (típicamente «sistema de tallas» activo de la empresa) y un flag
**ESFIJO** que decide si las líneas pueden cambiarlo:

- Si la variación está **fija** en cabecera, todas las líneas la heredan y
  no se puede cambiar.
- Si está **variable**, en el grid de líneas aparece una columna adicional
  cuyo encabezado se lee del nuevo campo `NOMBRE_VISIBLE_VA` en
  `fza_variaciones_atributos` (ej: «Sistema de tallas», «Paleta»,
  «Duración»…). Cada línea elige conjunto y se redibuja su matriz.

Así una sesión puede mezclar artículos con dimensiones distintas:

| Línea | Tipo      | Eje fila    | Eje pivot           | Comentario               |
|-------|-----------|-------------|---------------------|--------------------------|
| 1     | MATRIZ    | COLOR       | TALLA caballero     | Camiseta                 |
| 2     | MATRIZ    | COLOR       | TALLA niño          | Camiseta infantil        |
| 3     | MATRIZ    | —           | NUMERO calzado      | Botín (sólo un eje)      |
| 4     | ESCALAR   | —           | —                   | Bolso único              |
| 5     | SERVICIO  | —           | —                   | Portes proveedor         |

### 2.3-ter Tipos de línea

`TIPO_LINEA_SESLIN` admite:

- **MATRIZ** — Línea con matriz pivotada (caso típico ropa o calzado). Genera N SKUs.
- **ESCALAR** — Artículo ESTANDAR sin variación. Cantidad única. Genera 1
  artículo + 1 código de barras sin pasar por SKU.
- **SERVICIO** — `TIPO_ART = SERVICIO`, sin atributos, sin SKU, sin stock.
  Aparece igual en pedido/albarán/factura (portes, aduanas, comisión…).
- **KIT** — Reservado, fuera de MVP.

### 2.4 Códigos

| Concepto              | Origen                                                 |
|-----------------------|--------------------------------------------------------|
| `CODIGO_ART`          | Tecleado por el usuario o **autogenerado a partir de familia** (ver §2.4-bis). Validación de duplicados en vivo. |
| `CODIGO_UNIDAD_SKU`   | Auto, patrón `{CODIGO_ART}/{VALOR_FILA}/{VALOR_PIVOT}` reutilizando convención existente (ver `fza_articulos_skus`). |
| `CODIGO_BARRAS_CB`    | Auto al materializar, usando `inLibEAN13`. Configurable por sesión: prefijo de empresa + secuencial. |
| `REF_PROVEEDOR_AP`    | Tecleado por el usuario (texto libre) en cabecera o por línea. |

Si el usuario introduce un `CODIGO_ART` que ya existe en `fza_articulos`,
el formulario avisa con un indicador rojo en la línea y ofrece tres
acciones: **reusar** (la sesión enlaza al artículo existente y no lo crea),
**renombrar** o **cancelar la línea**.

### 2.4-bis Atajo familia → código autogenerado

Para los clientes que prefieren generar los códigos de artículo desde un
contador por familia, la casilla de código tiene un atajo:

- Si el usuario teclea **exactamente** el `CODIGO_FAM_FAM` de una familia
  activa (`ESACTIVO_FAM = 'S'`) que además tenga el contador habilitado
  (`ESCONTADOR_ART_FAM = 'S'`), al grabar la línea (`BeforePost`) la
  sesión:
  1. Lee `CONTADOR_ART_FAM` y `PAD_ART_FAM` de esa familia.
  2. Calcula `nuevo = CONTADOR_ART_FAM + 1`.
  3. Compone el código: `CODIGO_FAM_FAM + LPAD(nuevo, PAD_ART_FAM, '0')`.
  4. Persiste el nuevo contador en la familia.
  5. Sustituye `CODIGO_ART_TENTATIVO_SESLIN` por el código generado y
     fija `CODIGO_FAM_SESLIN = CODIGO_FAM_FAM` si la línea no la traía.

Ejemplo: tecleando `BOLSOS` con la familia BOLSOS configurada como
`CONTADOR_ART_FAM = 0`, `PAD_ART_FAM = 5`, `ESCONTADOR_ART_FAM = 'S'` →
se genera `BOLSOS00001` y la familia queda en `CONTADOR_ART_FAM = 1`.

Implementación en `inLibComprasSesiones.ResolverCodigoFamilia`. Usa
`SELECT ... FOR UPDATE` sobre la fila de familia para evitar colisiones
si dos usuarios crean líneas a la vez en sesiones distintas.

Si la familia existe pero `ESCONTADOR_ART_FAM <> 'S'`, no se expande y se
deja lo tecleado como código tentativo (probablemente choque con la
familia y el chequeo de duplicados marcará la línea para resolver). La
sesión también funciona si el cliente prefiere teclear códigos manuales
en familias sin contador.

**Coste de cancelar**: el contador se incrementa al grabar la línea, no
al materializar. Si la sesión se anula o la línea se borra, ese código
queda quemado (hueco numérico). Es aceptable a cambio de poder mostrar
el código tentativo desde el primer momento y poder etiquetar/escanear
durante el flujo de pre-pedido.

#### Configuración por familia (pantalla Familias)

En la pestaña «Más Datos» del mantenimiento de Familias hay un GroupBox
**«Autogenerar código de artículo desde esta familia»** con tres
controles:

| Control                  | Campo               | Significado                                          |
|--------------------------|---------------------|------------------------------------------------------|
| `chkEsContadorArtFam`    | `ESCONTADOR_ART_FAM`| Activa/desactiva el atajo en esta familia            |
| `spnContadorArt`         | `CONTADOR_ART_FAM`  | Último número emitido (0 al arrancar)                |
| `spnPadArt`              | `PAD_ART_FAM`       | Nº de dígitos del relleno (default 5, rango 1–12)    |

Etiqueta de ejemplo bajo los controles: «contador 0, dígitos 5 →
próximo código = FAM00001».

Cambio en `UniDataFamilias.dfm`: el `unqryTablaG` ahora consulta
directamente `fza_articulos_familias` (con LEFT JOIN para
`NOMBRE_SUBFAMILIA`) en lugar de la vista `vi_articulos_familias` —
evita modificar la vista para añadir los tres campos nuevos.

#### Tecla F3 sobre la columna «Código artículo»

Para no obligar al usuario a recordar de memoria el código de cada
familia, en la columna `dbcLinCodigoArt` del grid de líneas la tecla
**F3** abre un modal selector jerárquico:

- `inMtoModalSelFamilia` — un `TcxDBTreeList` con todas las familias
  activas, ordenadas por `ORDEN_FAM`, con jerarquía padre/hijo según
  `CODIGO_SUBFAMILIA_FAM`.
- Caja de búsqueda arriba: al teclear, la consulta cambia a búsqueda
  plana por `CODIGO_FAM_FAM LIKE '%xxx%' OR NOMBRE_FAM_FAM LIKE …`.
- Doble click o **Enter** acepta; **ESC** cancela.

Al aceptar, el modal devuelve `CodigoFamilia` y `NombreFamilia`. El form
de la sesión:

1. Pone el dataset de líneas en `Edit` si no lo estaba.
2. Asigna `CODIGO_ART_TENTATIVO_SESLIN := CodigoFamilia`.
3. Si la descripción estaba vacía, la prerellena con `NombreFamilia`
   para que la línea quede identificada hasta que el usuario teclee
   algo más específico.

El `Post` real se produce cuando el usuario se mueve de fila — y en ese
momento el `BeforePost` invoca `ResolverCodigoFamilia` que expande al
código numérico final (`BOLSOS00001`), incrementa el contador y
sustituye el código tentativo.

### 2.4-ter Modelo de proveedor: reusar artículos existentes (filtro incremental)

La sesión sirve tanto para **dar de alta modelos nuevos** como para
**reaprovisionar modelos que ya existen** en la BBDD. El identificador que
maneja el usuario en estos casos es el **modelo del proveedor**
(`REF_PRV_SESLIN`, columna «Modelo prov.»), no el código interno del
artículo — que normalmente desconoce.

#### Desplegable in-cell de búsqueda incremental

La columna «Modelo prov.» (`dbcLinRefPrv`) usa, en celda **vacía y
enfocada**, un `TcxExtLookupComboBox` montado en runtime
(`CrearLookupModelo`, mismo patrón probado de `inLibGridArticulos`):

- `FModeloBusqQry` lista **un modelo por fila** del proveedor de la
  cabecera (`CODIGO_PRV_SES`): `REF_PROVEEDOR_AP`, código de artículo,
  descripción, **sistema de tallas**, **colores ya existentes**
  (`GROUP_CONCAT` de los AV `'CO'` de sus SKUs) y **último precio de
  compra** — para que el usuario vea de un vistazo lo que ya hay.
- `IncrementalFiltering := True` (sin `ifoUseContainsOperator`) → filtra
  **«empieza por»** mientras se teclea, que es justo lo pedido: los modelos
  cuyo comienzo coincide. La lista está acotada al proveedor por el `:prv`
  del query, que `RecargarModelos` reabre al navegar de sesión o cambiar
  `CODIGO_PRV_SES` (hook `dsTablaGDataChangeHook`).
- `DropDownListStyle = lsEditList`: si lo tecleado **no** es un modelo
  existente, se acepta como texto → la línea es un **alta nueva** normal
  (comportamiento de siempre).

Al elegir un modelo de la lista, `ModeloComboCloseUp` difiere la
resolución (timer 1 ms) y `ModeloTimerResolveTimer` invoca
`ResolverDuplicadoSesion` (rama `REF`) + `AplicarDuplicadoEnLinea`: la
línea queda marcada **`ACCION_DUPLICADO_SESLIN = 'REUSAR'`** apuntando al
artículo existente, con descripción, familia, **sistema de tallas**,
**coste** y **PVP** precargados como referencia.

#### Qué se puede cambiar y qué no al reusar

| Elemento            | Al reusar un modelo existente                                  |
|---------------------|----------------------------------------------------------------|
| Sistema de tallas   | **Fijo** al del artículo. El selector de tallas rechaza el cambio en líneas `REUSAR` (descuadraría los SKUs ya creados). |
| Colores             | Se pueden **añadir nuevos** (color libre y/o color básico nuevo) como líneas adicionales del mismo modelo. |
| Tallas              | Solo se incorporan las **nuevas** del mismo sistema.            |
| Precio de compra    | Se propone el último (`PRECIO_ULT_COMPRA_AP`); editable.       |
| PVP / tarifa        | Se propone el actual de la tarifa de cabecera (`ObtenerPvpArticulo`) como referencia «por si no ha cambiado»; editable. |

#### Materialización aditiva (sin tratamiento especial extra)

Las líneas `REUSAR` ya se materializan de forma **aditiva** con la lógica
existente (`inLibComprasSesionesMaterializar`):

- `InsertarArticulo` **no** se ejecuta (el artículo no se recrea).
- `InsertarSkusYBarras` / `InsertarConjuntosAtributos` usan `INSERT
  IGNORE` → **solo se crean los colores/tallas que antes no existían**;
  los EAN13 solo se generan para SKUs sin código de barras.
- `UpsertArticuloProveedor` actualiza `PRECIO_ULT_COMPRA_AP` (precio de
  compra del documento) y `REF_PROVEEDOR_AP`.
- `UpsertArticuloTarifa` graba el PVP de la línea: si el usuario no tocó
  el valor propuesto, queda igual («no cambia»); si lo editó, actualiza la
  tarifa.

Por eso esta funcionalidad **no requiere cambios de esquema** ni un camino
de materialización aparte: reutiliza la infraestructura `REUSAR` y la
idempotencia de los `INSERT IGNORE` / upserts.

### 2.5 Precio de coste y precio de venta (tarifa)

La sesión maneja **dos precios** por línea:

- **Precio de coste** (`PRECIO_COMPRA_SESLIN`): lo que paga la empresa al
  proveedor. Es el que se materializa en `fza_articulos_proveedores.
  PRECIO_ULT_COMPRA_AP`.
- **Precio de venta** (`PRECIO_VENTA_SESLIN`): lo que se cobrará al cliente,
  bajo la tarifa elegida en cabecera (`CODIGO_TAR_SES`). Se materializa en
  `fza_articulos_tarifas` para el `CODIGO_TAR` correspondiente.

Por defecto ambos precios viven a **nivel de línea** (artículo). Si una
sesión necesita distinguir precio por SKU (por ejemplo XXL vale más), se
usa la tabla auxiliar `fza_compras_sesiones_lineas_skus_precios`
(`SESLINSKU`) que guarda override por combinación pivot/fila — sólo se
escribe cuando el usuario "rompe" el precio por línea para un SKU
concreto.

#### Fórmula de cálculo del precio de venta

Durante la sesión hay un botón **«Calcular venta»** que aplica esta fórmula
a las líneas seleccionadas:

```
precio_base   = precio_coste × PORCENTAJE_MARGEN_SES / 100
precio_redond = redondeo_arriba(precio_base, MULTIPLO_REDONDEO_SES)
precio_venta  = precio_redond − AJUSTE_FINAL_SES
```

Convención del margen (idéntica a `inMtoModalCalcularMargen`): el campo
es un multiplicador × 100. `margen = 100` deja el coste tal cual,
`margen = 120` aplica un +20% (coste × 1,20), `margen = 250` triplica
y medio (coste × 2,50), `margen = 400` cuadruplica.

Parámetros (cabecera de sesión, todos persistentes):

| Campo                       | Significado                                          | Ejemplo |
|-----------------------------|------------------------------------------------------|---------|
| `PORCENTAJE_MARGEN_SES`     | Multiplicador × 100 sobre coste (100 = sin margen, 250 = ×2,50). Default; override por línea | 250.0 |
| `MULTIPLO_REDONDEO_SES`     | Múltiplo al que sube el precio (`0` = sin redondeo) | 0.50    |
| `AJUSTE_FINAL_SES`          | Descuento final que se RESTA del redondeado (positivo para terminar en .99) | 0.01 |
| `ESPRECIOS_SIN_IVA_SES`     | Si los precios introducidos son sin IVA o con IVA    | 'S'     |
| `ESPRECIO_POR_SKU_SES`      | Activa el sub-grid de overrides por SKU              | 'N'     |

Ejemplo: coste 12 € × margen 250 = `12 × 250 / 100 = 30,00` → redondeo
a 1 = 30,00 → ajuste 0,01 (se resta) = **29,99 €**.

La fórmula se aplica al pulsar el botón, no automáticamente al teclear el
coste — así el usuario puede ajustar manualmente sin perder el control. El
`PRECIO_VENTA_SESLIN` queda libre de override una vez calculado.

Si `PORCENTAJE_MARGEN_SESLIN` está informado en la línea, tiene precedencia
sobre `PORCENTAJE_MARGEN_SES` de cabecera.

---

## 3. Esquema de base de datos

### 3.1 Catálogo de nuevos sufijos

| Tabla                                  | Sufijo      |
|----------------------------------------|-------------|
| `fza_compras_sesiones`                 | `SES`       |
| `fza_compras_sesiones_props`           | `SESPROP`   |
| `fza_compras_sesiones_kits`            | `SESKIT`    |
| `fza_compras_sesiones_kits_det`        | `SESKITD`   |
| `fza_compras_sesiones_lineas`          | `SESLIN`    |
| `fza_compras_sesiones_lineas_filas`    | `SESFIL`    |
| `fza_compras_sesiones_lineas_filas_atr`| `SESFILAT`  |
| `fza_compras_sesiones_lineas_props`    | `SESLPROP`  |
| `fza_compras_sesiones_lineas_skus_precios` | `SESLINSKU` |
| `fza_compras_sesiones_documentos`      | `SESDOC`    |
| `fza_compras_sesiones_celdas`          | `SESCEL`    |
| `fza_compras_plantillas`               | `SESPL`     |
| `fza_compras_plantillas_props`         | `SESPLPROP` |
| `fza_compras_plantillas_kits`          | `SESPLKIT`  |
| `fza_compras_plantillas_kits_det`      | `SESPLKITD` |
| `fza_pedidos_compra`                   | `PEDC`      |
| `fza_pedidos_compra_lineas`            | `PEDCLIN`   |
| `fza_albaranes_compra`                 | `ALBC`      |
| `fza_albaranes_compra_lineas`          | `ALBCLIN`   |

> Cambio adicional a tabla existente: se añade `NOMBRE_VISIBLE_VA` en
> `fza_variaciones_atributos` para parametrizar la etiqueta del eje en la
> UI («Sistema de tallas» para `TAL`, «Paleta» para `CO`, etc.).

Los sufijos `PEDC`, `ALBC` se definen aquí pero su detalle queda fuera del
alcance de este diseño (objetivo del módulo Compras-Documentos posterior).
Lo que sí necesita esta sesión es **saber qué documento generó** para
referenciar la conversión.

### 3.2 DDL

Ver `compras_sesiones.sql` adjunto. Resumen de tablas y su rol:

#### `fza_compras_sesiones` — Cabecera

Una fila por sesión. Identifica proveedor, familia objetivo, plantilla de
variación, conjuntos de atributos elegidos para pivotar, propiedades fijas
comunes (denormalizadas opcionalmente para reportes), almacén destino,
moneda, IVA por defecto, margen por defecto, estado (`BORRADOR`,
`CERRADA`, `ANULADA`), referencias a los documentos generados al
materializar.

Parámetros de fórmula de precio venta (ver §2.5 y §11.1):

- `MULTIPLO_REDONDEO_SES decimal(19,6)` — múltiplo al que sube el precio
  venta calculado; `0` = sin redondeo.
- `AJUSTE_FINAL_SES decimal(19,6)` — descuento final que se RESTA al
  precio redondeado; típicamente 0.01 para acabar en .99.
- `ESPRECIO_POR_SKU_SES char(1)` — `'S'` activa el sub-grid de precios
  por SKU (`fza_compras_sesiones_lineas_skus_precios`).

#### `fza_compras_sesiones_props` — Propiedades de cabecera

Una fila por cada propiedad de la familia que aparece en la sesión.
Incluye flag `ESFIJO_SESPROP` (`S` = fijo, `N` = variable con default) y
`VALOR_DEFECTO_SESPROP` / `ID_PV_DEFECTO_SESPROP`. Las propiedades fijas
se materializan en `fza_articulos_propiedades` para cada artículo creado.

#### `fza_compras_sesiones_kits` + `_det` — Kits de cantidades

Cabecera del kit (nombre, descripción, atributo destino, sesión a la que
pertenece) y detalle con `VALOR_DESTINO_SESKITD` (ej: «38», «M») y
`CANTIDAD_SESKITD`. Pueden vivir a nivel de sesión o promoverse a
biblioteca global del proveedor (campo `CODIGO_PRV_SESKIT` opcional para
plantillas reutilizables).

#### `fza_compras_sesiones_lineas` — Línea / artículo

Una fila por artículo en la sesión. Contiene:

- `CODIGO_ART_TENTATIVO_SESLIN` (lo tecleado, antes de validar).
- `ESDUPLICADO_SESLIN` y `ACCION_DUPLICADO_SESLIN` (reusar / renombrar).
- Descripción, familia (heredada o overrideada).
- Precio de compra, % margen, precio venta sugerido, IVA.
- Ref del proveedor (`REF_PRV_SESLIN`).
- Conjunto de tallas y conjunto de colores **override** opcional sobre la
  cabecera (por si una línea concreta no usa los conjuntos por defecto).

#### `fza_compras_sesiones_lineas_filas` + `_atr` — Filas de la matriz

`fza_compras_sesiones_lineas_filas` define una fila lógica de la matriz
por línea (orden de presentación). `_atr` guarda los valores de atributos
no-pivotados que distinguen esa fila (ej: fila 1 → CO=NEGRO; fila 2 →
CO=ROJO). En el caso típico ropa hay un único atributo agrupador (color),
pero la estructura admite N atributos para futuros casos (color+temporada,
etc.).

#### `fza_compras_sesiones_celdas` — Cantidades

Una fila por celda activa de la matriz. Clave compuesta:
`(ID_LIN, ID_FIL, VALOR_PIVOT)` → `CANTIDAD`. Las celdas con cantidad 0 se
borran al guardar (no se persiste vacío) para no generar SKUs inútiles
al materializar.

#### `fza_compras_sesiones_lineas_props` — Override de propiedades variables

Cuando una propiedad de cabecera es variable, esta tabla guarda el valor
concreto de esa línea. Si está vacía, se usa el `VALOR_DEFECTO_SESPROP`
de cabecera.

#### `fza_compras_sesiones_lineas_skus_precios` — Override de precio por SKU

Sufijo `SESLINSKU`. Una fila por SKU concreto al que el usuario haya
puesto un precio distinto al de la línea. PK:
`(SERIE, NUMERO, LINEA, ID_FILA, ID_AV_PIVOT)`. Sólo aparece en el
sub-grid de precios SKU cuando `ESPRECIO_POR_SKU_SES = 'S'` en cabecera.

- `PRECIO_COMPRA_SESLINSKU` (decimal(19,6) NULL) — override del coste para
  este SKU; `NULL` = hereda de `PRECIO_COMPRA_SESLIN`.
- `PRECIO_VENTA_SESLINSKU` (decimal(19,6) NULL) — override del precio
  venta; `NULL` = hereda de `PRECIO_VENTA_SESLIN`.

La materialización debe usar `COALESCE(override, linea)` para resolver el
precio efectivo al insertar en `fza_articulos_proveedores` y
`fza_articulos_tarifas`. Ver §11.5.

---

## 4. Layout de formularios

Tres formularios principales y un par de modales auxiliares. Todos heredan
de `TfrmMtoGen` (patrón existente, ver `inMtoPedidos.pas`/`dfm`).

### 4.1 `TfrmMtoComprasSesiones` (lista + ficha)

Estructura idéntica a `TfrmMtoPedidos`: rejilla superior con sesiones
existentes (filtros por estado, proveedor, rango fechas) y `PageControl`
inferior con pestañas de la sesión seleccionada.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ [Nuevo] [Borrar] [Grabar] [Cerrar] [Anular] [Clonar] [Crear artículos…]  │
├──────────────────────────────────────────────────────────────────────────┤
│ Nº  Fecha   Proveedor    Familia  Estado    Líneas  Total compra         │
│ 12  06/05   Acme S.L.    ROPA     BORRADOR     5    1.230,00 €           │
│ 11  29/04   Béta Texti   CALZADO  CERRADA      3      890,00 €           │
│ ...                                                                      │
├──────────────────────────────────────────────────────────────────────────┤
│ Pestañas: [Cabecera] [Plantilla] [Líneas] [Kits] [Materialización] [Log] │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Pestaña «Cabecera»

```
┌── Datos generales ─────────────────────────────────────────────────────┐
│ Serie: [SES ▼]  Nº: [auto] Fecha: [06/05/2026] Estado: BORRADOR        │
│ Empresa: [01 — Mi Empresa S.L.        ▼]                               │
│ Proveedor: [010      ...]  Ref. prov.: [PO-2026-04]                    │
│ 010 - Acme Textiles, S.A.  (Acme)                                      │
│ Almacén destino albarán: [GEN ▼]   Moneda: [EUR ▼]                     │
│ Comentarios: [____________________________________________________]    │
└────────────────────────────────────────────────────────────────────────┘
┌── Plantilla precios e impuestos ───────────────────────────────────────┐
│ Tipo IVA defecto: [N — 21% ▼]                                          │
│ Margen comercial defecto: [55 ] %    Tarifa salida: [PUBLICO ▼]        │
│ ☑ Precios introducidos sin IVA      ☐ Aplicar redondeo a venta       │
│ Mult.redondeo: [0,50]   Ajuste final: [-0,01]                          │
│ ☐ Permitir precio distinto por SKU (talla×color)                      │
└────────────────────────────────────────────────────────────────────────┘
┌── Plantilla variaciones ───────────────────────────────────────────────┐
│ Variación a usar: [TC — Talla y Color ▼]                               │
│ Atributo PIVOT (columnas): TALLA (autodetectado por orden)             │
│ Conjunto de TALLAS:  [42-46 Caballero ▼]                               │
│ Atributo FILA: COLOR                                                   │
│ Conjunto de COLORES: [Colores Básicos Verano ▼]                        │
│ [Vista previa matriz]                                                  │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Pestaña «Plantilla»  (propiedades fijas/variables y kits)

```
┌── Propiedades de la familia (ROPA) ────────────────────────────────────┐
│ Propiedad        Tipo    Fijo  Valor por defecto                       │
│ MARCA            LISTA    [✓]  [Acme            ▼]                     │
│ TEMPORADA        LISTA    [✓]  [Primavera-Verano 2026 ▼]               │
│ GENERO           LISTA    [✓]  [Caballero       ▼]                     │
│ MATERIAL         LISTA    [ ]  [Algodón         ▼]  ← editable por línea│
│ COMPOSICION      TEXTO    [ ]  [____________________]                  │
│ ORIGEN           TEXTO    [ ]  [_________________]                     │
│ ES_ECO           BOOL     [ ]  [N ▼]                                   │
└────────────────────────────────────────────────────────────────────────┘
┌── Kits de cantidades ──────────────────────────────────────────────────┐
│ [+ Nuevo kit] [Importar de proveedor] [Eliminar]                       │
│  Kit         42  43  44  45  46                                        │
│  CURVA-STD   1   2   3   2   1                                         │
│  MUESTRA     1   1   1   1   1                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.4 Pestaña «Líneas» — matriz pivotada

Cabecera de líneas (grid):

```
┌──────────────────────────────────────────────────────────────────────────┐
│ [+ Añadir] [Duplicar] [Borrar] [Resolver duplicado…] [Calcular venta]   │
├──────────────────────────────────────────────────────────────────────────┤
│ Lin  CodigoArt        Descripción         Familia  Ref.Prov  PrCompra   │
│  1   CAMI-AC-26      Camiseta Acme '26    ROPA    AC-T-001    4,80 €    │
│  2   POLO-AC-26  ⚠   Polo Acme '26        ROPA    AC-P-001    6,20 €    │
│  3   SUDA-AC-26      Sudadera Acme '26    ROPA    AC-S-001   11,30 €    │
└──────────────────────────────────────────────────────────────────────────┘
   ⚠ = código duplicado, ofrece acción
   [Calcular venta] aplica la fórmula §2.5 a la línea actual, o a todas
     las líneas seleccionadas si el grid tiene multi-selección.
```

Detalle de la línea seleccionada (matriz):

```
┌── Línea 1: CAMI-AC-26 — Camiseta Acme '26 ─────────────────────────────┐
│ Material: [Algodón ▼] (variable)                                        │
│ Tipo IVA: [N — 21% ▼] (heredado)                                        │
│ Pr.compra: [4,80] €  Margen: [55] %  Pr.venta: [7,49] € (IVA incl.)    │
│ Almacén editando: [GEN — Almacén Central ▼] (las celdas vacías usan el │
│                                              almacén de cabecera)       │
│ Kit a aplicar: [CURVA-STD ▼] [Aplicar a fila] [Aplicar a todas]         │
├─────────────────────────────────────────────────────────────────────────┤
│ Color\Talla      42    43    44    45    46    Total      Kit          │
│ NEGRO             1     2     3     2     1      9       [▼][Aplicar]  │
│ BLANCO            0     1     2     1     0      4       [▼][Aplicar]  │
│ AZUL              1     2     3     2     1      9       [▼][Aplicar]  │
│ [+ Añadir color]                                                        │
│ TOTAL líneas:    2     5     8     5     2     22                       │
├─── Precios por SKU (override; sólo si está activo en cabecera) ────────┤
│ Color    Talla  Pr.compra  Pr.venta                                    │
│ NEGRO    42        4,80      7,49                                       │
│ NEGRO    46        5,20      8,49   ← override sólo para 46             │
│ BLANCO   42        4,80      7,49                                       │
│ ...                                                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

Los `+ Añadir color` abren un dropdown con los valores del conjunto de
colores que aún no estén en filas. Los `+ Añadir línea` abren la edición
de cabecera de línea con código tentativo.

El sub-grid **Precios por SKU** aparece sólo si `ESPRECIO_POR_SKU_SES = 'S'`
en cabecera. Lista todas las combinaciones (fila, pivot) existentes en la
matriz; precios vacíos = hereda de la línea; tecleando `0` vuelve a
heredar. Edición directa con persistencia automática en
`fza_compras_sesiones_lineas_skus_precios`.

### 4.5 Pestaña «Materialización»

Resumen de lo que se va a crear cuando se pulse el botón:

```
┌─ Al pulsar «Crear artículos y documentos» ────────────────────────────┐
│ ► 3 artículos nuevos en fza_articulos                                  │
│ ► 27 SKUs en fza_articulos_skus                                        │
│ ► 27 EAN13 en fza_codigos_barras (prefijo 841 + secuencial)            │
│ ► 3 propiedades fijas por artículo (MARCA, TEMPORADA, GENERO)           │
│ ► 1 enlace artículo↔proveedor en fza_articulos_proveedores              │
│                                                                         │
│ Documento a generar:                                                    │
│   ☑ Pedido de compra (no mueve stock)                                   │
│   ☑ Albarán de compra (entra stock en GEN)                              │
│                                                                         │
│ Conflictos detectados: 1                                                │
│   ⚠ Línea 2 «POLO-AC-26» ya existe → acción: [reusar ▼]                 │
│                                                                         │
│            [Validar todo]   [Crear artículos y documentos]              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.6 Pestaña «Log»

Tras materializar, muestra el log de la operación: qué se creó, IDs
asignados, EAN13 generados, número del pedido y/o albarán resultantes,
errores si los hubo.

---

## 5. Workflow del usuario

```
1. Nuevo
   ↓
2. Cabecera: rellenar proveedor, familia, variación, conjuntos.
   ↓
3. Plantilla: marcar propiedades fijas/variables, definir kits.
   ↓
4. Líneas: ir tecleando códigos de artículo y rellenando matrices.
            (puede aplicar kit a una fila o a todas las del artículo)
            (puede duplicar línea para artículos similares)
   ↓
5. Validar duplicados y resolver acciones de cada línea conflictiva.
   ↓
6. Pestaña Materialización: elegir generar pedido y/o albarán.
   ↓
7. Pulsar «Crear artículos y documentos».
   ↓
8. Sesión queda CERRADA con referencias a los documentos creados.
```

En cualquier punto antes del paso 7 la sesión puede:

- Guardarse y reanudar después (estado `BORRADOR`).
- Anularse (estado `ANULADA`, no materializa).
- Clonarse para hacer una variante (nueva sesión `BORRADOR`).

---

## 6. Archivos a crear o modificar

### Nuevos

| Archivo                                                 | Rol                                      |
|---------------------------------------------------------|------------------------------------------|
| `src/Forms/inMtoComprasSesiones.pas` + `.dfm`           | Formulario principal de sesiones.        |
| `src/Forms/inMtoComprasKits.pas` + `.dfm`               | Mantenimiento biblioteca de kits.        |
| `src/DataModules/UniDataComprasSesiones.pas` + `.dfm`   | DataModule con UniQueries y triggers.    |
| `src/Modals/inMtoModalSesionMaterializar.pas` + `.dfm`  | Diálogo de confirmación + opciones.      |
| `src/Modals/inMtoModalSesionDuplicado.pas` + `.dfm`     | Resolver código duplicado por línea.     |
| `src/Modals/inMtoModalSelFamilia.pas` + `.dfm`          | Selector jerárquico de familia (F3 sobre código artículo). |
| `src/Lib/inLibComprasSesiones.pas`                      | Lógica matriz pivotada (similar a `inLibArticulosVariaciones`) + materialización. |
| `src/Lib/inLibComprasSesionesMaterializar.pas`          | Transacción de materialización.          |
| `DESARROLLOS EN CURSO/compras_sesiones.sql`             | DDL del esquema.                          |

### Modificados

| Archivo                                | Cambio                                                          |
|----------------------------------------|-----------------------------------------------------------------|
| `fzam.dpr`                             | Registrar nuevas units.                                          |
| `LIBRO_DE_ESTILO_BBDD.md`              | Añadir sufijos `SES`, `SESPROP`, `SESLIN`, `SESCEL`, etc.       |
| `src/Core/inMtoPrincipal.pas`/`dfm`    | Entrada de menú: Compras → Sesiones de Compra / Kits.            |
| `src/utilnormbbdd/UNormalizerEngine.pas` | Registrar sufijos nuevos en `InitDefaults`.                    |
| `src/Forms/inMtoFamilias.pas`          | Posible botón «Ver sesiones» para esta familia.                  |

---

## 7. Reglas de negocio críticas

1. **Atomicidad de la materialización**: todo el proceso del paso 7 corre
   dentro de una única transacción. Si falla un solo SKU, se hace rollback
   completo y la sesión sigue en `BORRADOR`. El log de error queda en
   `fza_compras_sesiones.MENSAJE_ERROR_SES`.

2. **Recuperación de duplicados**: el chequeo de duplicados se hace al
   teclear (validación tipo `IsValid`) y de nuevo al validar antes de
   materializar. No basta con confiar en el primero: el catálogo puede
   haber cambiado mientras la sesión estaba abierta.

3. **Idempotencia del EAN13**: el generador `inLibEAN13` debe llamarse
   dentro de la transacción y reservar el siguiente secuencial con un
   `SELECT … FOR UPDATE` sobre `fza_contadores` para evitar colisiones
   entre dos sesiones materializándose en paralelo.

4. **No tocar tablas maestras en borrador**: ningún trigger ni
   procedimiento debe insertar en `fza_articulos`, `fza_articulos_skus`,
   `fza_codigos_barras` o `fza_articulos_proveedores` desde tablas
   `fza_compras_sesiones*`. Toda la materialización es código Delphi
   explícito (`inLibComprasSesionesMaterializar`).

5. **Stock**: si se genera albarán de compra, los movimientos se aplican
   con la cantidad agregada por SKU (suma de celdas de cada SKU si hay
   varias filas que cuadran a la misma combinación, aunque no debería
   ocurrir con el modelo planteado). Si se genera sólo pedido, no se
   toca stock.

6. **Numeración**: las sesiones consumen un contador propio
   (`fza_contadores` con `TIPO_DOC_CON = 'SE'`, varchar(2)). El pedido/albarán
   resultantes consumen los suyos respectivos.

---

## 8. Decisiones cerradas

1. **Multivariación**: ✅ **variación por línea**. La cabecera fija un
   defecto («sistema de tallas» activo, etc.). Si la variación está
   marcada como **variable**, cada línea elige conjunto pivot y se
   redibuja su matriz. Una sesión puede mezclar artículos con
   dimensiones distintas + escalares + servicios.

2. **Precio por talla**: ✅ **precio único por línea**. `PRECIO_COMPRA`
   vive en la línea, no en la celda.

3. **Costes accesorios** (portes, aduanas): ✅ **dentro de la sesión** como
   líneas tipo **SERVICIO** sin atributos. Se materializan al pedido /
   albarán / factura sin afectar al precio de los artículos.

4. **Concurrencia**: ✅ **sin lock**. Se detecta conflicto comparando
   `INSTANTE_MODIF` al guardar. Si dos usuarios graban encima, el segundo
   recibe aviso y elige reabrir o forzar.

5. **Importación CSV/Excel**: ⏳ **fuera del MVP**. Hito posterior.

6. **Plantillas de cabecera**: ✅ **plantillas globales con nombre**. Botón
   «Guardar como plantilla» almacena cabecera + propiedades + kits en
   `fza_compras_plantillas` (cab) + `_props` + `_kits[_det]`. Al crear
   sesión nueva: «Nueva desde plantilla…».

7. **Nombre visible del eje pivot**: ✅ **campo `NOMBRE_VISIBLE_VA`** en
   `fza_variaciones_atributos`. Cada atributo de variación define cómo
   se llama en la UI («Sistema de tallas» para `TAL`, «Paleta» para
   `CO`…).

8. **Tipos de línea soportados** en MVP: ✅ **MATRIZ, ESCALAR, SERVICIO**.
   Kit/Pack queda para hito posterior.

---

## 9. Hito de implementación sugerido

1. **MVP** — Sesión + matriz pivotada + materialización a artículos/SKUs/EAN13.
   Sin pedido/albarán (eso es manual después).
2. **Hito 2** — Kits de cantidades + plantilla de propiedades fijas/variables.
3. **Hito 3** — Multi-almacén en la matriz (✅ implementado).
4. **Hito 4** — Fórmula precio venta + override por SKU (✅ implementado;
   §11). Pendiente sólo drenar el override al materializar (§11.5).
5. **Hito 5** — Generación automática de pedido de compra (uno por sesión).
6. **Hito 6** — Generación automática de N albaranes + movimientos de stock,
   uno por almacén con cantidad > 0.
7. **Hito 7** — Importación CSV proveedor + plantillas guardadas.

---

## 10. Multi-almacén en la matriz

### 10.1 Modelo

Cada **celda** de la matriz lleva ahora una cuarta dimensión: `CODIGO_ALM_SESCEL`.
La clave primaria de `fza_compras_sesiones_celdas` pasa a ser
`(SERIE, NUMERO, LINEA, ID_FILA, ID_AV_PIVOT, CODIGO_ALM)`. Una misma combinación
talla×color puede tener cantidades distintas en almacenes distintos.

`CODIGO_ALM_SES` de la cabecera sigue siendo el **almacén por defecto**: si una
celda se guarda con `CODIGO_ALM_SESCEL = ''` se interpreta como "el de cabecera"
en consultas y materialización.

### 10.2 UI

Encima de la matriz aparece un nuevo selector **«Almacén editando»** (`cbbAlmacenMatriz`):
- Al cargar la línea por primera vez se inicializa con `CODIGO_ALM_SES` de cabecera.
- Cambiar la selección redibuja la matriz mostrando solo las cantidades de ese almacén.
- Al introducir una cantidad, se persiste con `CODIGO_ALM_SESCEL = <almacén actual>`.

Para ver simultáneamente todas las capas: la pestaña Materialización tiene un
resumen agregado por almacén (vista `VI_SES_RESUMEN_ALMACEN`) y el grid de preview
ordena por almacén → línea → fila → pivot.

### 10.3 Materialización

- **SKUs y EAN13** siguen siendo a nivel de **artículo** (no por almacén). El query
  hace `GROUP BY (linea, fila, pivot)` para no duplicar SKUs ni quemar EAN13s.
- **`CODIGO_ALM_SES` en cabecera es opcional** — sólo sirve como almacén por
  defecto sugerido al rellenar nuevas celdas y como fallback para celdas con
  `CODIGO_ALM_SESCEL` vacío. La sesión funciona sin él si todas las celdas
  llevan su propio almacén.
- **Pedidos de compra** (cuando `ESGENERA_PEDIDO_SES = 'S'`): **N pedidos**,
  uno por cada `CODIGO_ALM` con cantidad > 0. Cada pedido lleva las líneas
  con la cantidad de ese almacén concreto y se enlaza al proveedor común.
- **Albaranes de compra** (cuando `ESGENERA_ALBARAN_SES = 'S'`): **N albaranes**,
  uno por cada `CODIGO_ALM` con cantidad > 0. Cada albarán mueve solo su stock
  al almacén correspondiente.
- **Tabla nueva `fza_compras_sesiones_documentos`** (sufijo `SESDOC`): enumera
  todos los documentos materializados por la sesión, con `TIPO_DOC_SESDOC ∈
  {'PEDC','ALBC'}`, `CODIGO_ALM_SESDOC`, `SERIE_SESDOC` y `NUMERO_SESDOC`. La
  cabecera mantiene `SERIE_PEDC_SES`/`NUMERO_PEDC_SES` y `SERIE_ALBC_SES`/
  `NUMERO_ALBC_SES` como referencia al **primero** de cada tipo para listados
  rápidos; la lista completa vive en esa tabla.

### 10.4 Limitaciones

- El kit "aplicar a fila" / "aplicar a todas" sólo afecta a la capa de almacén
  actualmente visible. Si quieres replicar el kit a todos los almacenes habría
  que añadir un botón «Aplicar a todos los almacenes».

> ✅ Resuelto en la variante grid inline para los **kits del proveedor**:
> en sesiones de formato distribuido «Aplicar kit» abre el distribuidor en
> modo kit, con botones Aplicar/Limpiar por almacén y «Aplicar kit en todos
> los almacenes». Ver `proveedores_compras_defectos.md` §3.5.

---

## 11. Cálculo de precio venta + override por SKU

### 11.1 Parámetros de cabecera (persistentes)

| Campo                       | Tipo SQL          | Default | UI                                |
|-----------------------------|-------------------|---------|-----------------------------------|
| `MULTIPLO_REDONDEO_SES`     | `decimal(19,6)`   | `0`     | `spnMultiploRedondeo` (incremento 0,05) |
| `AJUSTE_FINAL_SES`          | `decimal(19,6)`   | `0`     | `spnAjusteFinal` (acepta negativos) |
| `ESPRECIO_POR_SKU_SES`      | `char(1)` (S/N)   | `'N'`   | `chkPrecioPorSku` en gbPrecios     |

Migración idempotente para BBDDs ya creadas: bloques `INFORMATION_SCHEMA`
en `compras_sesiones.sql` que añaden las columnas sólo si no existen.

### 11.2 Fórmula

Implementada en `inLibComprasSesiones.CalcularPrecioVenta`:

```pascal
function CalcularPrecioVenta(ACoste, AMargenPct,
                             AMultiplo, AAjuste: Double): Double;
begin
  rBase := ACoste * (1 + AMargenPct / 100);
  if AMultiplo > 0 then
    Result := Ceil(rBase / AMultiplo) * AMultiplo
  else
    Result := rBase;
  Result := Result + AAjuste;
  if Result < 0 then Result := 0;
end;
```

- Margen efectivo: si `PORCENTAJE_MARGEN_SESLIN` está informado, tiene
  precedencia sobre `PORCENTAJE_MARGEN_SES` de cabecera.
- Si `MULTIPLO_REDONDEO_SES = 0`, no se aplica redondeo (sólo el ajuste).
- Si el resultado sale negativo, se clava a 0.

### 11.3 Botón «Calcular venta» en la pestaña Líneas

Vive en `pnlLineasBotones`, junto a los botones de línea. Comportamiento:

| `tvLineas.Controller.SelectedRecordCount` | Acción                                                   |
|-------------------------------------------|----------------------------------------------------------|
| `0` o `1`                                 | Aplica la fórmula a la línea con foco (`unqrySesionLin`) |
| `> 1`                                     | Itera por todas las líneas seleccionadas en el grid       |

Implementación:
- `inLibComprasSesiones.CalcularPrecioVentaLinea(ADM, AUsuario, ALinea)` →
  UPDATE de `PRECIO_VENTA_SESLIN` para una línea.
- `inLibComprasSesiones.CalcularPrecioVentaLineas(ADM, AUsuario, ALineas)` →
  loop sobre el array + refresh final.

El usuario puede después seguir editando `PRECIO_VENTA_SESLIN` manualmente
en el grid; la fórmula no se vuelve a aplicar hasta que pulse el botón.

### 11.4 Sub-grid de precios por SKU

Aparece debajo de la matriz cuando `chkPrecioPorSku` está marcado, separado
de la matriz por un `TcxSplitter` para que el usuario regule espacio.

**Tabla**: `fza_compras_sesiones_lineas_skus_precios` (sufijo `SESLINSKU`).
PK: `(SERIE, NUMERO, LINEA, ID_FILA, ID_AV_PIVOT)`. Sólo se escribe cuando
el usuario rompe el precio para un SKU concreto.

**Query del sub-grid** (`unqryLineaSkusPrecios`):

```sql
SELECT C.ID_FILA_SES_SESCEL  AS ID_FILA,
       C.ID_AV_PIVOT_SESCEL  AS ID_AV_PIVOT,
       AVP.AV                AS VAL_PIVOT,
       (...GROUP_CONCAT de valores fila...) AS VAL_FILA,
       P.PRECIO_COMPRA_SESLINSKU,
       P.PRECIO_VENTA_SESLINSKU
  FROM fza_compras_sesiones_celdas C
  JOIN fza_atributos_valores AVP ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL
  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ON ...
 WHERE C.SERIE/NUMERO/LINEA = sesión + línea actual
 GROUP BY C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL
```

El JOIN trae todas las combinaciones existentes en la matriz; los precios
que no tienen override aparecen `NULL`.

**Edición**: las dos columnas de precio tienen
`Properties.OnEditValueChanged = dbcPreciosSkuPrecioXxx...EditValueChanged`.
El handler hace un upsert manual (no usa el dataset directamente porque la
query es un JOIN):

```pascal
INSERT INTO fza_compras_sesiones_lineas_skus_precios
  (..., PRECIO_*_SESLINSKU, INSTANTE_ALTA, USUARIO_ALTA, ...)
VALUES (..., :v, NOW(), :u, ...)
ON DUPLICATE KEY UPDATE
  PRECIO_*_SESLINSKU = :v, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u
```

- Si el usuario teclea `0`, el upsert pone `NULL` (vuelve a heredar el
  precio de la línea).
- Si el sub-grid no tiene fila para un SKU, esa combinación hereda al 100%.

### 11.5 Materialización (pendiente)

Cuando se conecte la generación real de documentos, `InsertarSkusYBarras`
debe hacer `LEFT JOIN` a `fza_compras_sesiones_lineas_skus_precios` y usar:

```sql
COALESCE(P.PRECIO_COMPRA_SESLINSKU, L.PRECIO_COMPRA_SESLIN) AS COSTE,
COALESCE(P.PRECIO_VENTA_SESLINSKU,  L.PRECIO_VENTA_SESLIN)  AS VENTA
```

para escribir en `fza_articulos_proveedores.PRECIO_ULT_COMPRA_AP` y
`fza_articulos_tarifas.PRECIO_FINAL_ARTTAR` por SKU. Por ahora el modelo de
datos guarda toda la información; el paso de "drenar" el override al
materializar queda como TODO.

---

## 12. Eje fila como texto libre del proveedor

### 12.1 Motivación

Las paletas de colores de un proveedor pueden ser muy grandes (100+ tonos)
y cambian por colección/temporada. Obligar al usuario a definir antes un
`fza_atributos_conjuntos` con todos esos colores es engorroso y a menudo
contraproducente: muchas veces el cliente no quiere catalogarlos a futuro,
solo quiere etiquetar la compra con los nombres que viene en la factura
del proveedor («Verde Pino», «Rojo Carmín 87», etc.).

La sesión permite por eso un **modo texto libre** para el eje fila: el
usuario no elige conjunto y va tecleando los nombres de fila uno a uno.

### 12.2 Activación

- **Modo conjunto** (clásico): `ID_AC_FILA_SES` lleva valor (FK a
  `fza_atributos_conjuntos`). El picker «+ Añadir color» ofrece los
  valores del conjunto aún no usados.
- **Modo texto libre**: `ID_AC_FILA_SES` está `NULL` en cabecera. El picker
  «+ Añadir color» abre un `InputQuery` donde el usuario teclea el nombre.

La detección se hace en `TGestorMatrizCompras.AddFila` leyendo
`unqryTablaG.ID_AC_FILA_SES`. Más adelante puede refinarse para que cada
línea decida (vía `ID_AC_FILA_SESLIN`), pero el MVP usa solo la cabecera.

### 12.3 Modelo

Se añade una columna al detalle de filas:

| Tabla                                  | Columna                       | Tipo            | Cuándo se rellena                     |
|----------------------------------------|-------------------------------|-----------------|---------------------------------------|
| `fza_compras_sesiones_lineas_filas`    | `ETIQUETA_TEXTO_SESFIL`       | `varchar(100)`  | Solo en modo texto libre              |

- En **modo conjunto**: `ETIQUETA_TEXTO_SESFIL` queda `NULL` y los valores
  de fila viven en `fza_compras_sesiones_lineas_filas_atr` (`ID_AV_SESFILAT`).
- En **modo texto libre**: `ETIQUETA_TEXTO_SESFIL` lleva el texto tecleado
  y `_filas_atr` queda vacía para esa fila.

Migración idempotente en `compras_sesiones.sql` para añadir la columna en
BBDDs ya creadas.

### 12.4 UI

- **Cabecera**: el `lblConjFila` ya documenta «(vacío = texto libre)». No
  hay checkbox extra: dejar el combo vacío activa el modo.
- **Matriz** — botón **«+ Fila»**:
  - Modo conjunto → picker de valores del conjunto pivot/fila (TODO,
    actualmente muestra un `MessageDlg` explicativo).
  - Modo texto libre → `InputQuery('Nombre de la fila',...)`. El usuario
    no introduce orden; el sistema asigna `ORDEN_SESFIL = max + 10`
    (10, 20, 30…) para que el SKU se ordene correctamente y queden huecos
    si después se quiere reordenar.

### 12.4-bis Añadir valor pivot (talla) sobre el conjunto

A diferencia del eje fila, el pivot **debe** estar respaldado por un
conjunto (`ID_AC_PIVOT_SES`) porque los SKUs catalogados se ordenan por
`fza_atributos_valores.ORDEN_AV` y el comparador debe ser global. Para
permitir que el usuario añada en caliente una talla que no estaba en la
paleta del proveedor, hay un botón **«+ Talla / valor pivot»** en la
matriz que abre el flujo:

1. `InputQuery` pide el nombre del valor (ej: «XXL», «47»).
2. `InputQuery` pide el orden (sugerido: `max(ORDEN_ACD)+10` del conjunto
   activo).
3. Si el valor no existe en `fza_atributos_valores` para el atributo del
   conjunto pivot, se inserta con su `ORDEN_AV`.
4. Se inserta (con `INSERT IGNORE`) la fila en
   `fza_atributos_conjuntos_det` para enlazar el AV al conjunto activo
   con el orden indicado.
5. Se reconstruye la matriz: la talla aparece como nueva columna.

El patrón replica `inMtoModalGenerarSKUs.btnAddValueClick` (pantalla de
generación de SKUs que ya usa la misma lógica «si no existe, lo creo, y
lo engancho al conjunto»). El valor queda disponible en futuras sesiones
porque vive en el conjunto global, no solo en esta sesión.

Implementación en `TGestorMatrizCompras.AddColumna` (`inLibComprasSesiones`).

### 12.5 Carga de etiqueta

`TGestorMatrizCompras.CargarFilasDesdeBBDD` ya hace `SELECT *` sobre
`_filas`, así que el campo nuevo llega solo. Cuando el join contra
`_filas_atr` no devuelve ningún valor, se usa `ETIQUETA_TEXTO_SESFIL`
como etiqueta de la fila.

### 12.6 Materialización (pendiente)

Cuando se conecte la generación real de SKUs, cada fila con
`ETIQUETA_TEXTO_SESFIL` no-nula deberá:

1. Localizar la variación efectiva de la línea (cabecera o
   `ID_AC_FILA_SESLIN` si la línea la sobreescribe) y su atributo fila
   (típicamente `CO`).
2. Buscar en `fza_atributos_valores` un AV con ese texto bajo el atributo;
   si no existe, **crearlo** (incrementando contador `AV`).
3. Usar ese `ID_AV` para componer el SKU como en modo conjunto.
4. Opcionalmente, crear/actualizar un `fza_atributos_conjuntos` con sufijo
   del proveedor (ej: «Colores Acme PV-26») que agrupe esos valores nuevos
   para reusarlos en sesiones futuras del mismo proveedor.

Por simplicidad, el MVP de materialización puede no crear el conjunto y
limitarse a registrar los `fza_atributos_valores`. El usuario podrá
construir el conjunto manualmente en el mantenimiento de atributos si lo
desea.

---

## Navegación a documentos creados (junio 2026)

El caption del botón «Ir a documento» de la pestaña Documentos prometía
F12, pero ese atajo lo captura `actGrabarRegistro` (grabar dataset) del
Mto base y nunca llegaba al botón. Se retira el F12 del caption y se
añade un botón en el lateral derecho, **«Ir a Ped / Alb»**
(`btnIrPedAlb`), que navega al documento seleccionado en la pestaña
Documentos desde cualquier pestaña. `btnIrADocClick` ahora también
resuelve `PEDC` → Mto de Pedidos de Compra (antes solo `ALBC`).
