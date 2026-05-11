# Compras — Sesiones (pre-pedidos / pre-albaranes)

Diseño del módulo de **Sesiones de Compra**: documentos borrador donde el usuario
prepara artículos, atributos, precios y cantidades antes de materializarlos en
las tablas maestras (`fza_articulos`, `fza_articulos_skus`,
`fza_codigos_barras`, `fza_articulos_proveedores`) y generar el documento
posterior (pedido y/o albarán de compra).

---

## 1. Principio rector

Una sesión es **puramente borrador**. Mientras el usuario edita:

- **NO** se inserta nada en `fza_articulos`.
- **NO** se generan SKUs en `fza_articulos_skus`.
- **NO** se crean códigos de barras en `fza_codigos_barras`.
- **NO** se enlaza al proveedor en `fza_articulos_proveedores`.
- **NO** se mueve stock ni se crean líneas de pedido/albarán de compra.

Todo vive en las tablas de la sesión (`fza_compras_*`). Sólo cuando el usuario
pulsa **«Crear artículos y documentos»** se materializa:

1. Altas en `fza_articulos` (cabecera de artículo).
2. Vinculación de conjuntos de atributos en `fza_articulos_conjuntos_asign`.
3. Altas de SKUs en `fza_articulos_skus` + `fza_atributos_sku` (valores).
4. Altas de propiedades fijas en `fza_articulos_propiedades`.
5. Generación de EAN13 (uno por SKU) en `fza_codigos_barras` vía `inLibEAN13`.
6. Alta o actualización en `fza_articulos_proveedores` con precio último de compra
   y referencia del proveedor.
7. Generación del documento elegido:
   - **Pedido de compra** → `fza_pedidos_compra` + `fza_pedidos_compra_lineas`
     (sin mover stock).
   - **Albarán de compra** → `fza_albaranes_compra` + líneas + movimientos en
     `fza_movimientos_almacen` con entrada por SKU (cantidad pivotada).
   - O **ambos** secuencialmente.

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

### 2.4 Códigos

| Concepto              | Origen                                                 |
|-----------------------|--------------------------------------------------------|
| `CODIGO_ART`          | Tecleado por el usuario. Validación de duplicados en vivo. |
| `CODIGO_UNIDAD_SKU`   | Auto, patrón `{CODIGO_ART}/{VALOR_FILA}/{VALOR_PIVOT}` reutilizando convención existente (ver `fza_articulos_skus`). |
| `CODIGO_BARRAS_CB`    | Auto al materializar, usando `inLibEAN13`. Configurable por sesión: prefijo de empresa + secuencial. |
| `REF_PROVEEDOR_AP`    | Tecleado por el usuario (texto libre) en cabecera o por línea. |

Si el usuario introduce un `CODIGO_ART` que ya existe en `fza_articulos`,
el formulario avisa con un indicador rojo en la línea y ofrece tres
acciones: **reusar** (la sesión enlaza al artículo existente y no lo crea),
**renombrar** o **cancelar la línea**.

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
| `fza_compras_sesiones_celdas`          | `SESCEL`    |
| `fza_pedidos_compra`                   | `PEDC`      |
| `fza_pedidos_compra_lineas`            | `PEDCLIN`   |
| `fza_albaranes_compra`                 | `ALBC`      |
| `fza_albaranes_compra_lineas`          | `ALBCLIN`   |

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
│ Nº  Fecha   Proveedor    Familia  Estado    Líneas  Total compra        │
│ 12  06/05   Acme S.L.    ROPA     BORRADOR     5    1.230,00 €          │
│ 11  29/04   Béta Texti   CALZADO  CERRADA      3      890,00 €          │
│ ...                                                                      │
├──────────────────────────────────────────────────────────────────────────┤
│ Pestañas: [Cabecera] [Plantilla] [Líneas] [Kits] [Materialización] [Log] │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Pestaña «Cabecera»

```
┌── Datos generales ─────────────────────────────────────────────────────┐
│ Serie: [SES ▼]  Nº: [auto] Fecha: [06/05/2026] Estado: BORRADOR        │
│ Empresa: [01 — Mi Empresa S.L.        ▼]                                │
│ Proveedor: [010 — Acme Textiles, S.A. ▼]  Ref. prov.: [PO-2026-04]      │
│ Almacén destino albarán: [GEN ▼]   Moneda: [EUR ▼]                      │
│ Comentarios: [____________________________________________________]    │
└────────────────────────────────────────────────────────────────────────┘
┌── Plantilla precios e impuestos ───────────────────────────────────────┐
│ Tipo IVA defecto: [N — 21% ▼]                                          │
│ Margen comercial defecto: [55 ] %    Tarifa salida: [PUBLICO ▼]        │
│ ☑ Precios introducidos sin IVA      ☐ Aplicar redondeo a venta         │
└────────────────────────────────────────────────────────────────────────┘
┌── Plantilla variaciones ───────────────────────────────────────────────┐
│ Variación a usar: [TC — Talla y Color ▼]                               │
│ Atributo PIVOT (columnas): TALLA (autodetectado por orden)             │
│ Conjunto de TALLAS:  [42-46 Caballero ▼]                               │
│ Atributo FILA: COLOR                                                    │
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
│ [+ Añadir línea] [Duplicar] [Borrar línea]                              │
├──────────────────────────────────────────────────────────────────────────┤
│ Lin  CodigoArt        Descripción         Familia  Ref.Prov  PrCompra   │
│  1   CAMI-AC-26      Camiseta Acme '26    ROPA    AC-T-001    4,80 €    │
│  2   POLO-AC-26  ⚠   Polo Acme '26        ROPA    AC-P-001    6,20 €    │
│  3   SUDA-AC-26      Sudadera Acme '26    ROPA    AC-S-001   11,30 €    │
└──────────────────────────────────────────────────────────────────────────┘
   ⚠ = código duplicado, ofrece acción
```

Detalle de la línea seleccionada (matriz):

```
┌── Línea 1: CAMI-AC-26 — Camiseta Acme '26 ─────────────────────────────┐
│ Material: [Algodón ▼] (variable)                                        │
│ Tipo IVA: [N — 21% ▼] (heredado)                                        │
│ Pr.compra: [4,80] €  Margen: [55] %  Pr.venta: [16,55] € (IVA incl.)   │
│ Kit a aplicar: [CURVA-STD ▼] [Aplicar a fila] [Aplicar a todas]         │
├─────────────────────────────────────────────────────────────────────────┤
│ Color\Talla      42    43    44    45    46    Total      Kit          │
│ NEGRO             1     2     3     2     1      9       [▼][Aplicar]  │
│ BLANCO            0     1     2     1     0      4       [▼][Aplicar]  │
│ AZUL              1     2     3     2     1      9       [▼][Aplicar]  │
│ [+ Añadir color]                                                        │
│ TOTAL líneas:    2     5     8     5     2     22                       │
└─────────────────────────────────────────────────────────────────────────┘
```

Los `+ Añadir color` abren un dropdown con los valores del conjunto de
colores que aún no estén en filas. Los `+ Añadir línea` abren la edición
de cabecera de línea con código tentativo.

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
   (`fza_contadores` con `TIPO_DOC = SESCOMPRA`). El pedido/albarán
   resultantes consumen los suyos respectivos.

---

## 8. Preguntas abiertas / decisiones pendientes

1. **Multivariación**: el diseño asume una variación por sesión. ¿Necesita
   permitir una sesión con varias variaciones distintas (artículos de
   ropa + artículos sin tallas en el mismo PO)? Si sí, una línea puede
   tener su propio `TIPO_VAR_SESLIN` y degenerar a escalar. Está
   contemplado en el DDL pero hay que pulir la UI.

2. **Precio por talla**: ¿hay casos donde el precio de compra varía por
   talla (XXL más caro)? Si sí, hay que mover `PRECIO_COMPRA` de la línea
   a la celda y propagarse al SKU vía `fza_articulos_proveedores` por SKU
   (no existe hoy; obligaría a denormalizar o crear una tabla `_SKUS`).

3. **Costes accesorios** (portes, aduanas) que se prorratean entre líneas:
   ¿se gestionan aquí o en el albarán/factura posterior?

4. **Borradores compartidos**: ¿una sesión la edita un único usuario o
   permitimos edición concurrente con check-out? Lo simple es lock de
   sesión por usuario; aviso si otro intenta abrirla.

5. **Importación**: ¿hay que admitir CSV/Excel del proveedor para
   precargar la sesión? Es un buen segundo hito, no bloquea el MVP.

6. **Plantilla de propiedades fijas guardada**: ¿el usuario quiere poder
   guardar la configuración de cabecera + plantilla como «plantilla
   reutilizable» y aplicarla a nuevas sesiones?

---

## 9. Hito de implementación sugerido

1. **MVP** — Sesión + matriz pivotada + materialización a artículos/SKUs/EAN13.
   Sin pedido/albarán (eso es manual después).
2. **Hito 2** — Kits de cantidades + plantilla de propiedades fijas/variables.
3. **Hito 3** — Generación automática de pedido de compra.
4. **Hito 4** — Generación automática de albarán + movimiento de stock.
5. **Hito 5** — Importación CSV proveedor + plantillas guardadas.
