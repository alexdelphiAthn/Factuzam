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
| Descripción        | `DESCRIPCION_SESLIN`                           | Prerellenada con `NOMBRE_FAM_FAM`; editable                    |
| Color              | `COLOR_TEXTO_SESLIN`                           | Texto libre. Atributo no-pivot ("atributo1"). NUEVA columna    |
| Color básico       | `CODIGO_ATB_COLOR_SESLIN`                      | Selector con paleta (mismo combo que `inMtoInventarios`). NUEVA columna |
| Pr. compra         | `PRECIO_COMPRA_SESLIN`                         | Al cambiar, propone Pr. venta vía `CalcularPrecioVenta`        |
| Pr. venta          | `PRECIO_VENTA_SESLIN`                          | Calculado pero override-able                                   |
| Sistema tallas     | `ID_AC_PIVOT_SESLIN`                           | Lookup `fza_atributos_conjuntos`. Al cambiar, reconstruye matriz |
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

#### 5.2 SESFIL — auto-creación de una fila por línea

El motor de la matriz (`TGestorMatrizCompras`) lee filas de
`fza_compras_sesiones_lineas_filas`. Para que la matriz se pueda
editar, la prueba crea automáticamente **una fila SESFIL con
`ID_FILA_SESFIL = 1`** por cada línea de sesión, en el momento de
elegir el `ID_AC_PIVOT_SESLIN` (o de obtener foco la línea si ya tiene
pivot). `ETIQUETA_TEXTO_SESFIL` se mantiene sincronizada con
`COLOR_TEXTO_SESLIN` para que la etiqueta de la fila en la matriz
muestre lo que el usuario tecleó.

No hace falta `_filas_atr` porque el atributo libre + ATB básico ya
viven en SESLIN (denormalizados para esta prueba).

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
4. Botón [+ Línea]: añade fila al grid; el form crea una SESFIL.
   ↓
5. En la fila:
   - Tecla F3 en Familia → modal selector → BOLSOS → contador → BOLSOS00001
   - Descripción se prerellena con «Bolsos y Mochilas»; se edita
   - Tecleas Color = «AZUL TURQUESA PROV-XYZ»
   - Color básico (lookup) = AZUL
   - Pr. compra = 4,80 → se propone Pr. venta = 7,49 (vía fórmula)
   - Sistema tallas = «42-46 Caballero» → matriz dibuja 5 columnas
   ↓
6. En la matriz: tecleas cantidades 1,2,3,2,1.
   Total tallas y Importe total se refrescan en la fila del grid.
   ↓
7. Repites pasos 4-6 para más artículos. Grabar.
```

### 9. Decisiones cerradas sobre edición de tallas (objetivo final)

Estado **objetivo** de la Prueba 01 — el que vale como definición de
hecho:

- **Edición INLINE** en la propia línea del artículo. No hay matriz
  debajo del grid: las cantidades se teclean directamente en cada celda
  de talla, dentro de la fila del artículo.
- **Número de columnas de talla = máximo** de valores entre todos los
  sistemas de tallas usados por alguna línea de la sesión. Recalculado
  al cambiar conjunto en cualquier línea.
- Las líneas con conjuntos más cortos tienen **columnas en blanco** al
  final de las tallas (no rotuladas, no editables).
- **Captions dinámicas**: cuando el foco está sobre una línea, los
  rótulos de las columnas de talla se actualizan al sistema de esa
  línea. Si hay dos líneas con sistemas distintos y muevo el foco, los
  rótulos cambian al tallaje de la línea activa.

### 10. Estado actual del código (V1, en commit)

El código publicado en esta carpeta implementa todo el diseño SALVO la
edición inline de tallas. Las cantidades se editan en una tira
(matriz) dibujada **debajo** del grid mediante
`TGestorMatrizCompras` — un patrón ya probado en el Mto real. Sirve
como banco de pruebas funcional del modelo de datos y de los demás
flujos (familia → contador, PVP propuesto, paleta de colores básicos,
sistema de tallas por línea).

El siguiente paso (V1.1) es sustituir esa tira por las columnas inline
descritas en §9. Implementación prevista:

1. Quitar `pnlMatrizCab`, `sbMatriz` y la liberación de
   `FGestorMatriz` del form.
2. Añadir 12 columnas no-bound a `tvLineas`
   (`PropertiesClassName='TcxCurrencyEditProperties'`,
   `DataBinding.ValueType='Float'`, `Tag=1..12`).
3. Cachear las posiciones del conjunto pivot de cada línea
   (`TDictionary<ID_AC, TArray<ID_AV>>`) y poblar las celdas no-bound
   vía `tvLineas.DataController.Values[record, col]` a partir de
   `fza_compras_sesiones_celdas`.
4. Recalcular el máximo de valores entre todos los conjuntos referenciados
   en la sesión y mostrar/ocultar columnas según ese máximo.
5. Captions: actualizar al cambiar el foco de fila
   (`OnFocusedRecordChanged`) leyendo el conjunto de la línea actual.
6. Edición: `Properties.OnEditValueChanged` de cada columna persiste a
   `fza_compras_sesiones_celdas` con el mismo upsert que ya hace
   `TGestorMatrizCompras.OnCantidadChange`.

Sin foto, sin código de barras, sin propiedades de familia
(fijas/variables) — a propósito; el Mto real cubre todos esos casos.
Esta prueba se centra en el flujo «coste + tallas → artículos».
- Sin materialización: la sesión vive en `BORRADOR`. Promoverla a
  pedido/albarán es el flujo del Mto real, no de esta prueba.
- Sin foto, sin código de barras, sin propiedades de familia
  (fijas/variables) — a propósito; el Mto real cubre todos esos casos.
  Esta prueba se centra en el flujo «coste + tallas → artículos».
