# Pruebas — Sesiones de creación de artículos + pedido

Banco de pruebas para iterar variantes de UI sobre el módulo de
**sesiones de compra** (`inMtoComprasSesiones`). Cada prueba reutiliza
las tablas `fza_compras_sesiones*` y el DataModule `TdmComprasSesiones`
ya cableado; sólo cambia la pantalla.

Carpeta: `DESARROLLOS EN CURSO/pruebas_sesiones/`. El código Delphi
(`.pas` / `.dfm`) vive aquí mientras la prueba sea exploratoria; cuando
una variante se ascienda a definitiva, se mueve a `src/Forms/`.

---

## Prueba 01 — Grid plano "todo en una línea" con matriz de tallas debajo

Variante simplificada del Mto de sesiones: una **única pestaña** con la
cabecera arriba (los settings) y un **grid de líneas** con todos los
campos del artículo + la matriz de tallas justo debajo. Pensada para
crear lotes pequeños de artículos nuevos en una sola pasada visual.

### 1. Alcance

- **Sí**: cabecera (settings), grid de líneas, matriz de tallas por
  línea, contador por familia, propuesta automática de PVP al teclear
  coste.
- **No** (fuera de esta prueba, por decisión expresa): kits,
  **propiedades fijas/variables**, generación de pedido/albarán,
  materialización a `fza_articulos`, **códigos de barras**, **fotos**,
  override de precios por SKU.

### 2. Cabecera (settings)

Todos los campos viven en `fza_compras_sesiones` (cabecera ya
existente). Sólo se exponen los necesarios para que la fórmula del PVP
y la generación funcionen:

| Etiqueta UI            | Columna BBDD                | Origen lookup                  |
|------------------------|-----------------------------|--------------------------------|
| Empresa                | `CODIGO_EMP_SES`            | `fza_empresas`                 |
| Proveedor              | `CODIGO_PRV_SES`            | `fza_proveedores`              |
| Tarifa venta           | `CODIGO_TAR_SES`            | `vi_tarifas`                   |
| Margen (%)             | `PORCENTAJE_MARGEN_SES`     | numérico libre                 |
| Múltiplo redondeo      | `MULTIPLO_REDONDEO_SES`     | numérico libre (0 = sin)       |
| Ajuste final           | `AJUSTE_FINAL_SES`          | numérico libre (puede ser <0)  |

Serie + Número se autogeneran en `BeforePost` del DM (mismo flujo que
el Mto principal). Para esta prueba se asume:
- `ESVAR_FIJA_SES = 'N'` (la variación se elige por línea).
- `ID_AC_FILA_SES = NULL` (modo "fila libre" — el color es texto + ATB
  básico por línea).

### 3. Grid de líneas (1 línea = 1 artículo)

Columnas, en orden visual:

| Col                | Origen                                         | Notas                                                          |
|--------------------|------------------------------------------------|----------------------------------------------------------------|
| Familia            | `CODIGO_FAM_SESLIN`                            | F3 abre `TfrmModalSelFamilia`. Al cambiar, copia descripción.  |
| Cód. artículo      | `CODIGO_ART_TENTATIVO_SESLIN`                  | Read-only. Se rellena en `BeforePost` con `FAMILIA + CONTADOR` |
| Modelo prov.       | `REF_PRV_SESLIN`                               | Código del proveedor para la prenda (referencia / modelo).     |
| Descripción        | `DESCRIPCION_SESLIN`                           | Prerellenada con `NOMBRE_FAM_FAM`; editable                    |
| Color              | `COLOR_TEXTO_SESLIN`                           | Texto libre. Atributo no-pivot ("atributo1"). NUEVA columna    |
| Color básico       | `CODIGO_ATB_COLOR_SESLIN`                      | Selector con paleta (mismo combo que `inMtoInventarios`). NUEVA columna |
| Pr. compra         | `PRECIO_COMPRA_SESLIN`                         | Al cambiar, propone Pr. venta vía `CalcularPrecioVenta`        |
| Pr. venta          | `PRECIO_VENTA_SESLIN`                          | Calculado pero override-able                                   |
| Sistema tallas     | `ID_AC_PIVOT_SESLIN`                           | Lookup `fza_atributos_conjuntos`. Al cambiar, recalcula el     |
|                    |                                                | máximo de columnas TALLA y los rótulos                         |
| TALLA 1..N         | (no-bound, cache → `fza_compras_sesiones_celdas`) | N = máximo de valores entre los conjuntos del documento. Rótulos siguen al sistema de la línea con foco. |
| Total tallas       | `TOTAL_UNIDADES_SESLIN`                        | Read-only. Suma de cantidades en celdas (lo refresca el form)  |
| Importe total s/IVA| `TOTAL_LINEA_SESLIN`                           | Read-only. = `TOTAL_UNIDADES × PRECIO_COMPRA`                  |

#### 3.1 Contador por familia

Al pulsar F3 (o introducir un `CODIGO_FAM` reconocido) en la columna
Familia, el `BeforePost` invoca `inLibComprasSesiones.ResolverCodigoFamilia`,
que:

1. Verifica que la familia exista y tenga `ESCONTADOR_ART_FAM = 'S'`.
2. Bloquea la fila (`SELECT … FOR UPDATE`) e incrementa
   `CONTADOR_ART_FAM`.
3. Compone `CODIGO_ART = CODIGO_FAM + LPAD(CONTADOR, PAD_ART_FAM, '0')`.
4. Sustituye `CODIGO_ART_TENTATIVO_SESLIN` por el código generado.

Si la familia no autogenera, lo tecleado queda como código tentativo.

#### 3.2 Propuesta automática de PVP

Cuando el usuario cambia `PRECIO_COMPRA_SESLIN` en una línea, el form
calcula y persiste `PRECIO_VENTA_SESLIN` aplicando la fórmula ya
existente (`inLibComprasSesiones.CalcularPrecioVenta`):

```
base   = coste × (1 + margen / 100)            -- margen de cabecera
venta  = ceil(base / múltiplo) × múltiplo + ajuste
```

El margen por línea puede sobreescribir el de cabecera vía
`PORCENTAJE_MARGEN_SESLIN` (no expuesto en esta prueba; queda para
una iteración posterior). El usuario puede a su vez editar
`PRECIO_VENTA_SESLIN` para fijar manualmente.

### 4. Matriz de tallas (debajo del grid)

Al cambiar la línea activa o al elegir un `ID_AC_PIVOT_SESLIN`, se
reconstruye la matriz usando `TGestorMatrizCompras` (la misma del Mto
real). Para esta prueba la matriz es **una sola fila** (un color por
línea), por lo que se ve como una tira horizontal:

```
┌──────────────────────────────────────────────────────────┐
│ Color/Atributo │ 38 │ 39 │ 40 │ 41 │ 42 │ Total │ Kit    │
│ (etiqueta)     │  1 │  2 │  3 │  2 │  1 │   9   │ [...]  │
└──────────────────────────────────────────────────────────┘
```

La etiqueta de la fila se rellena con `COLOR_TEXTO_SESLIN` si el
usuario ya lo ha tecleado; si no, queda en blanco.

Las cantidades se persisten en `fza_compras_sesiones_celdas` vía
`OnCantidadChange` del propio gestor (upsert/delete sobre `SESCEL`).

### 5. Modelo de datos — qué cambia

#### 5.1 Tabla `fza_compras_sesiones_lineas`

Dos columnas nuevas en SESLIN para almacenar el "atributo no-pivot"
de cada línea de forma plana (en la prueba se cubre el caso de
**color** pero el patrón es genérico — se puede replicar para MATERIAL,
TEMPORADA, etc. con un nuevo par TEXTO+ATB o moviéndolo a una tabla
hija si el número crece).

```sql
ALTER TABLE fza_compras_sesiones_lineas
  ADD COLUMN COLOR_TEXTO_SESLIN       varchar(100) DEFAULT NULL,
  ADD COLUMN CODIGO_ATB_COLOR_SESLIN  varchar(100) DEFAULT NULL;
```

Se almacena `CODIGO_ATB` (varchar) en vez de `ID_ATB` (int) para que el
selector reutilizado de inventarios (`SeleccionarAvConPaleta` de
`inLibAtributosPaleta`) opere directamente: ese picker trabaja con
códigos de la paleta básica (`NEGRO`, `AZUL`, `AZUL_MARINO`…) y la
caché resuelve el HEX por `(ID_VA_ATB='CO', CODIGO_ATB)`.

Idempotente: en `pruebas_sesiones.sql` se envuelve en bloques
`INFORMATION_SCHEMA` (mismo patrón que `compras_sesiones.sql`).

#### 5.2 SESFIL no se usa en esta prueba

La prueba inline edita cantidades directamente en
`fza_compras_sesiones_celdas` con `ID_FILA_SES_SESCEL = 1` fijo (una
fila lógica por línea — no hay sub-grid color×color). No se inserta
nada en `fza_compras_sesiones_lineas_filas` ni en `_filas_atr`: el
atributo libre + el ATB básico ya viven denormalizados en SESLIN
(`COLOR_TEXTO_SESLIN` y `CODIGO_ATB_COLOR_SESLIN`).

Si la prueba se promueve a Mto real, la materialización tendrá que
generar las filas SESFIL/SESFILAT correspondientes a partir de SESLIN
para que el flujo de `fza_articulos_skus` siga el patrón habitual.

#### 5.3 Genericidad — pensando en más atributos

El par `COLOR_TEXTO_SESLIN + ID_ATB_COLOR_SESLIN` es el atributo
no-pivot principal. Si en el futuro se quieren manejar más
(MATERIAL+ATB, TEMPORADA+ATB, …) sin migrar de modelo:

- **Opción rápida**: añadir más pares de columnas a SESLIN
  (`MATERIAL_TEXTO_SESLIN`, `ID_ATB_MATERIAL_SESLIN`, etc.).
- **Opción correcta**: migrar el par a una tabla hija
  `fza_compras_sesiones_lineas_atrib` con (`ID_VA`, `ID_ATB`, `TEXTO`),
  PK por (SERIE,NUMERO,LINEA,ID_VA). Esta es la dirección que toma el
  schema final si se promueve la prueba.

### 6. Reuso de código (lo que la prueba **no** reinventa)

| Pieza ya existente                                         | Uso en la prueba                              |
|------------------------------------------------------------|-----------------------------------------------|
| `TdmComprasSesiones`                                       | DM completo: cabecera, líneas, celdas, lookups|
| `inLibComprasSesiones.ResolverCodigoFamilia`               | Atajo familia → código autogenerado           |
| `inLibComprasSesiones.CalcularPrecioVenta`                 | Propuesta de PVP al cambiar coste             |
| `inLibComprasSesiones.TGestorMatrizCompras`                | Render dinámico de la matriz                  |
| `inLibAtributosPaleta.SeleccionarAvConPaleta`              | Selector dropdown con swatch (mismo que inventarios) |
| `inLibAtributosPaleta.ObtenerInfoBasico` + `PintarSwatchEnBitmap` | Glyph del botón con el cuadradito del color actual |
| `inLibAtributosPaleta.PintarCeldaConCuadradoColor`         | Custom-draw de la celda Color básico          |
| `TfrmModalSelFamilia`                                      | Picker jerárquico con F3                      |
| `fza_winforms`                                             | Mapeo form↔DM (entrada nueva «PruebaSesionGrid») |

### 7. Ficheros de la prueba

```
DESARROLLOS EN CURSO/pruebas_sesiones/
├── pruebas_sesiones.md          ← este documento
├── pruebas_sesiones.sql         ← ALTERs idempotentes + winform
├── inMtoPruebaSesionGrid.pas    ← TfrmMtoPruebaSesionGrid
└── inMtoPruebaSesionGrid.dfm
```

Registrado en `fzam.dpr` con el path largo
`'DESARROLLOS EN CURSO\pruebas_sesiones\inMtoPruebaSesionGrid.pas'`. El
DM lo aporta `UniDataComprasSesiones` (ya en el dpr).

### 8. Flujo del usuario

```
1. Menú → Compras → Sesiones → Prueba grid (Ctrl+Shift+S).
   ↓
2. Tab Lista: ver sesiones existentes o pulsar [+] para nueva.
   ↓
3. Tab Ficha: rellenar Empresa, Proveedor, Tarifa, Margen,
              Múltiplo, Ajuste. Grabar.
   ↓
4. Botón [+ Línea]: añade fila al grid de artículos.
   ↓
5. En la fila:
   - Tecla F3 en Familia → modal selector → BOLSOS → contador → BOLSOS00001
   - Descripción se prerellena con «Bolsos y Mochilas»; se edita
   - Tecleas Color = «AZUL TURQUESA PROV-XYZ»
   - Color básico → selector paleta (mismo de inventarios) = AZUL
   - Pr. compra = 4,80 → se propone Pr. venta = 7,49 (vía fórmula)
   - Sistema tallas = «42-46 Caballero» → la fila despliega 5 columnas
     TALLA con rótulos 42, 43, 44, 45, 46.
   ↓
6. En la propia fila tecleas las cantidades 1, 2, 3, 2, 1 en cada
   columna TALLA. Total tallas e Importe s/IVA se refrescan.
   ↓
7. Repites pasos 4-6 para más artículos. Si una línea nueva usa un
   conjunto con más tallas, el grid amplía sus columnas TALLA; las
   líneas anteriores con conjuntos más cortos quedan con celdas en
   blanco al final. Grabar.
```

### 9. Edición inline de tallas

- **Edición INLINE** en la propia línea del artículo. No hay matriz
  debajo del grid: las cantidades se teclean directamente en cada celda
  de talla, dentro de la fila del artículo.
- **Número de columnas de talla = máximo** de valores entre todos los
  sistemas de tallas referenciados por alguna línea de la sesión.
  Recalculado al cambiar el conjunto pivot en cualquier línea.
- Las líneas con conjuntos más cortos tienen **columnas en blanco** al
  final de las tallas (no rotuladas, no editables).
- **Captions dinámicas**: cuando el foco está sobre una línea, los
  rótulos de las columnas de talla se actualizan al sistema de esa
  línea. Si hay dos líneas con sistemas distintos y muevo el foco, los
  rótulos cambian al tallaje de la línea activa.

### 10. Cómo está implementada la edición inline

Las columnas de talla son **no-bound**
(`DataBinding.ValueTypeClass = TcxFloatValueType`, sin `FieldName`).
El valor vive en `tvLineas.DataController.Values[record, col]` y se
sincroniza con `fza_compras_sesiones_celdas`:

- **Lectura** (`CargarCantidadesTodasLineas` /
  `CargarCantidadesUnaLinea`): al abrir la sesión, recorre las celdas
  existentes en BBDD y las publica en las columnas no-bound por
  posición — la posición se calcula desde el conjunto pivot de la
  línea (`fza_atributos_conjuntos_det` ordenado por `ORDEN_ACD`).
- **Escritura** (`TallaCellEditValueChanged`): cuando el usuario teclea
  en una celda, leemos `LINEA_SESLIN` + `ID_AC_PIVOT_SESLIN`,
  resolvemos el `ID_AV` por posición (`Tag` de la columna) y
  persistimos vía upsert SQL (`INSERT … ON DUPLICATE KEY UPDATE`).
- **Caché** (`FConjuntoPos: TDictionary<ID_AC, TArrPosConjunto>`):
  cachea las posiciones por conjunto para no reconsultar
  `fza_atributos_conjuntos_det` en cada edición.
- **Máximo de columnas visibles** (`MaxLongConjuntosSesion`): consulta
  los `ID_AC_PIVOT_SESLIN` distintos de la sesión, mira el tamaño de
  cada conjunto y devuelve el máximo. `RecalcularColumnasTallasDocumento`
  muestra ese número de columnas y oculta el resto.

Las 15 columnas TALLA se crean en runtime (`CrearColumnasTallas`) entre
`dbcLinTallas` (sistema) y `dbcLinTotalTallas` para mantener el orden
visual del usuario.

### 11. Limitaciones reconocidas

- Sin materialización: la sesión vive en `BORRADOR`. Promoverla a
  pedido/albarán es el flujo del Mto real, no de esta prueba.
- Sin foto, sin código de barras, sin propiedades de familia
  (fijas/variables) — a propósito; el Mto real cubre todos esos casos.
  Esta prueba se centra en el flujo «coste + tallas → artículos».
