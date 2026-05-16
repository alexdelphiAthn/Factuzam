# Atributos básicos en el SKU de artículos

## Idea

Cada **valor de atributo** del SKU (TALLA="XL", COLOR="001 del proveedor",
TEMP="ROJO 003"…) lleva asociado un **atributo básico** que actúa de helper /
equivalente estándar.

**El significado del valor depende del contexto:**
- Una talla XL de bañador puede ser **56 cm** y una XL de camisa **34 cm**.
- El código de color "7" del proveedor A puede ser **BLANCO** y el "7" del
  proveedor B **NEGRO**.

Por eso la correspondencia "valor → atributo básico" se resuelve en
**tres niveles**, de mayor a menor prioridad:

| # | Fuente            | Tabla / columna                                                | Granularidad        |
|---|-------------------|----------------------------------------------------------------|---------------------|
| 1 | Override artículo | `fza_articulos_atributos_basicos.ID_ATB_AAB`                   | (artículo × valor)  |
| 2 | Conjunto          | `fza_atributos_conjuntos_det.ID_ATB_ACD`                       | (conjunto × valor)  |
| 3 | Global            | `fza_atributos_valores.ID_ATB_AV`                              | (valor)             |

La vista `vi_atributos_sku_basico` aplica
`COALESCE(override, conjunto, global)` y expone la columna `FUENTE_ATB`
con `'A'` / `'C'` / `'G'` / `NULL` para indicar de dónde sale el básico.

## Tablas implicadas

```
fza_atributos_basicos              -- catálogo estándar (AZUL CIELO, BAÑO_XL…)
fza_atributos_valores              -- valor; ID_ATB_AV es el fallback global
fza_atributos_conjuntos_det        -- conjunto; ID_ATB_ACD por conjunto
fza_articulos_atributos_basicos    -- override per-artículo (nueva)
fza_atributos_sku                  -- liga SKU ↔ valor (sin cambios)
fza_articulos_skus                 -- cabecera del SKU (sin cambios)
vi_atributos_sku_basico            -- vista que une todo
```

### `fza_atributos_basicos` (catálogo)

| Columna           | Tipo            | Comentario                                  |
|-------------------|-----------------|---------------------------------------------|
| `ID_ATB`          | int             | PK auto-increment                           |
| `ID_VA_ATB`       | varchar(20)     | Atributo de variación (CO, TAL…)            |
| `CODIGO_ATB`      | varchar(30)     | Código estable: `XL`, `BANIO_XL`, `EU42`    |
| `NOMBRE_ATB`      | varchar(100)    | Nombre legible: `BAÑADOR XL`                |
| `DESCRIPCION_ATB` | varchar(255)    | Descripción larga                           |
| `HEX_ATB`         | varchar(7)      | `#RRGGBB` de paleta                         |
| `VALOR_NUM_ATB`   | decimal(12,4)   | 56 cm de bañador, 26.5 cm de calzado…       |
| `UNIDAD_ATB`      | varchar(10)     | `cm`, `mm`, `kg`…                           |
| `ORDEN_ATB`       | int             | Orden de presentación                       |
| `ESACTIVO_ATB`    | char(1)         | `S`/`N`                                     |
| auditoría         |                 | `INSTANTE_*`, `USUARIO_*`                   |

Clave única `(ID_VA_ATB, CODIGO_ATB)` para `ON DUPLICATE KEY`.

### `fza_atributos_valores.ID_ATB_AV` (fallback global)

Default por valor. Se usa cuando el artículo no tiene override y el
conjunto del artículo (si existe) no especifica básico para ese valor.

### `fza_atributos_conjuntos_det.ID_ATB_ACD` (por conjunto)

Aquí se define el significado físico de un valor **dentro del conjunto**.
Dos conjuntos distintos pueden mapear XL a básicos diferentes:

- Conjunto "Tallas Bañador" → XL → `BANIO_XL` (56 cm)
- Conjunto "Tallas Camisa H" → XL → `CAMI_XL` (34 cm cuello)

El artículo asigna su conjunto en `fza_articulos_conjuntos_asign`.

### `fza_articulos_atributos_basicos` (override por artículo — nueva)

```
CODIGO_ART_AAB  varchar(20)   -- FK artículo
ID_AV_AAB       int           -- FK valor
ID_ATB_AAB      int NULL      -- FK básico; NULL = bloqueo
+ auditoría
PRIMARY KEY (CODIGO_ART_AAB, ID_AV_AAB)
```

Sirve para los casos en que dos artículos comparten conjunto pero
necesitan interpretación distinta de un valor concreto: por ejemplo,
proveedor A llama "7" al blanco y proveedor B al negro, los dos en el
mismo conjunto de colores. Cada artículo crea su override.

**Semántica de `ID_ATB_AAB`:**

| Estado de la fila              | Significado                                     |
|--------------------------------|-------------------------------------------------|
| No existe                       | "Heredar" — la vista resuelve por conjunto o global |
| `ID_ATB_AAB IS NOT NULL`        | Override real con ese básico                    |
| `ID_ATB_AAB IS NULL`            | **Bloqueo**: este artículo declara explícitamente "no quiero básico aquí" aunque el conjunto/global lo tengan |

La vista usa `CASE WHEN aab.CODIGO_ART_AAB IS NOT NULL THEN aab.ID_ATB_AAB ...` en vez de `COALESCE` para que la simple existencia de la fila gane (incluso con valor NULL = bloqueo).

### Vista `vi_atributos_sku_basico`

```sql
SELECT CODIGO_ART_SKU,  CODIGO_UNIDAD_SKU, CODIGO_VAR_SKU,
       ID_AV, ID_VA_AV, NOMBRE_ATRIBUTO, ORDEN_ATRIBUTO,
       VALOR_AV, DESCRIPCION_AV,
       ID_AC,                       -- conjunto del artículo (si lo tiene)
       ID_ATB_OVERRIDE, ID_ATB_CONJUNTO, ID_ATB_GLOBAL,
       COALESCE(ID_ATB_OVERRIDE, ID_ATB_CONJUNTO, ID_ATB_GLOBAL) AS ID_ATB_AV,
       FUENTE_ATB,                  -- 'A' / 'C' / 'G' / NULL
       CODIGO_ATB, NOMBRE_ATB, DESCRIPCION_ATB,
       HEX_ATB, VALOR_NUM_ATB, UNIDAD_ATB,
       ETIQUETA_BASICO              -- texto helper listo para mostrar
```

`ETIQUETA_BASICO` consolida:
- Si hay medida numérica → `"47 cm"`, `"26.5 cm"`
- Si hay HEX           → `"AZUL CIELO #87CEEB"`
- Si no                → `NOMBRE_ATB` a secas

## Donde se mantiene cada cosa

| Quiero…                                | Voy a…                                         |
|----------------------------------------|------------------------------------------------|
| Crear / editar un atributo básico      | **Atributos básicos** (Ctrl+Alt+B)             |
| Definir XL en *este* conjunto          | **Colecciones de Atributos** (Ctrl+Alt+S), pestaña *Valores*, columna *Atributo básico* |
| Default global de un valor             | El catálogo de valores (todavía sin UI propia) |
| Override específico para un artículo   | **Artículos** (Ctrl+A), pestaña *2_SKUs*, rejilla de atributos del SKU activo |

## UI

### Formulario nuevo: *Atributos básicos*

`Ctrl+Alt+B`, `inMtoAtributosBasicos`, data module `UniDataAtributosBasicos`.

Grid principal con columnas: ID, Atributo (lookup CO/TAL/…), Código, Nombre,
Descripción, Paleta (pintada con `OnCustomDrawCell` mostrando el color
real + HEX), Valor numérico, Unidad, Orden, Activo.

Ficha con los mismos campos + botón `[...]` en HEX que abre `TColorDialog`.

### *Colecciones de Atributos* — pestaña *Valores*

Nueva columna **Atributo básico** editable como `TcxLookupComboBox`
enlazado al catálogo. Aquí se define, por ejemplo, que en el conjunto
"Tallas Bañador" la talla XL → básico BANIO_XL.

### *Artículos* — pestaña *2_SKUs*

- Cuadrícula superior de SKUs (200 px, splitter horizontal). Las
  columnas *Precio Últ Compra* y *Fecha Últ Compra* se ocultan
  automáticamente cuando ningún SKU del artículo tiene coste asignado.
- Cuadrícula inferior "Atributos del SKU + Atributo básico (helper)"
  que sigue al SKU activo (`MasterFields = CODIGO_UNIDAD_SKU` contra
  `dsSkus`).

  | Columna       | Origen                                  |
  |---------------|-----------------------------------------|
  | Atributo      | `ID_VA_AV`                              |
  | Nombre atrib. | `NOMBRE_ATRIBUTO`                       |
  | Valor         | `VALOR_AV`                              |
  | **Básico**    | `ID_ATB_AV` (editable lookup)           |
  | Nombre básico | `NOMBRE_ATB`                            |
  | **Paleta**    | `HEX_ATB` (button-edit + color picker)  |
  | Valor básico  | `VALOR_NUM_ATB`                         |
  | Unidad        | `UNIDAD_ATB`                            |
  | Equivalencia  | `ETIQUETA_BASICO`                       |
  | Fuente        | `FUENTE_ATB` (Artículo/Conjunto/Global) |

  - `OnInitPopup` filtra el lookup por `ID_VA_ATB` (un atributo CO sólo
    ve básicos de color, TAL sólo tallas). **`OnCloseUp` limpia el
    filtro** al cerrar el desplegable: si quedara puesto, la grilla
    no podría resolver `CODIGO_ATB` de las filas con otro `ID_VA_ATB`
    y la columna "Básico" saldría vacía para esas filas.
  - `OnValidate` del combo: si el usuario teclea un texto (`BONIATO`)
    que no matchea ningún básico, busca match exacto por
    `CODIGO_ATB` o `NOMBRE_ATB` y, si no existe, lanza
    `PreguntarAmbitoBasico` para crear el básico al vuelo y enlazarlo.
    Requiere `Properties.DropDownListStyle = lsEditList` en el column
    para que el `TcxLookupComboBox` acepte tecleo libre (sin esta
    propiedad el editor rechaza caracteres que no matchean la lista).
  - `OnEditValueChanged` **siempre hace UPSERT en
    `fza_articulos_atributos_basicos`**: con `ID_ATB_AAB = X` cuando se
    elige un básico, con `ID_ATB_AAB = NULL` cuando se vacía la celda
    (bloqueo explícito: la fila existe pero declara "sin básico para
    este artículo"). Para volver a heredar del conjunto/global hay que
    borrar la fila a mano (futura acción dedicada).
  - **Nombre básico, Valor básico y Unidad** también son editables y
    persisten en `fza_atributos_basicos` (afecta a todos los usos del
    mismo básico).
  - La columna "Paleta" pinta el color real con `OnCustomDrawCell` y su
    botón `[...]` (o doble-clic) abre `TColorDialog` para editar
    `HEX_ATB` directamente en `fza_atributos_basicos`.

### Convención de visualización para atributos con paleta

Reglas para cualquier grid que muestre `HEX_ATB` (o un color hex
asociado a un atributo / SKU):

- **En la celda del grid**: sólo el cuadrado de color de la paleta
  (pintado con `OnCustomDrawCell`). Sin texto encima.
- **En el hint de la celda**: el valor HEX (`#RRGGBB`) y, si procede,
  el `NOMBRE_ATB` del básico. El hint se engancha al evento de hint
  de celda del view (donde la versión de cxGrid lo permita; si no,
  vía `Application.OnShowHint`).

Esto evita ensuciar el grid con texto que cambia de color de fuente
según luminancia, y deja el HEX accesible al pasar el ratón sin
ocupar espacio visual.

## SKUs huérfanos: filas virtuales y materialización lazy

Un SKU "huérfano" es uno que existe en `fza_articulos_skus` pero **no
tiene filas en `fza_atributos_sku`** (la tabla puente SA que liga el
SKU a sus valores de atributo). Ocurre cuando el SKU se crea por SQL,
import, migración manual… El INNER JOIN original de
`vi_atributos_sku_basico` los dejaba fuera y la rejilla "Atributos del
SKU + Atributo básico (helper)" salía vacía → el usuario no tenía
forma de asignarles color/talla básica desde la UI sin tocar SQL.

### Vista: `UNION ALL` con filas virtuales

`vi_atributos_sku_basico` añade un segundo bloque (`UNION ALL`) con
filas **virtuales** para cada atributo de la variación que no tenga
su SA correspondiente:

```sql
SELECT
  sku.CODIGO_ART_SKU, sku.CODIGO_UNIDAD_SKU, sku.CODIGO_VAR_SKU,
  NULL                  AS ID_AV,            -- marcador de fila virtual
  va.ID_ATB_VA          AS ID_VA_AV,
  va.NOMBRE_VA          AS NOMBRE_ATRIBUTO,
  va.ORDEN_VA           AS ORDEN_ATRIBUTO,
  SUBSTRING_INDEX(
    SUBSTRING_INDEX(
      SUBSTRING(sku.CODIGO_UNIDAD_SKU,
                CHAR_LENGTH(sku.CODIGO_ART_SKU) + 2),
      '/', va.ORDEN_VA),
    '/', -1)            AS VALOR_AV,         -- parse por posición ORDEN_VA
  NULL, NULL, NULL, NULL, NULL, NULL,
  NULL                  AS FUENTE_ATB,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM fza_articulos_skus sku
JOIN fza_variaciones_atributos va ON va.ID_VAR_VA = sku.CODIGO_VAR_SKU
WHERE sku.CODIGO_UNIDAD_SKU LIKE CONCAT(sku.CODIGO_ART_SKU, '/%')
  AND NOT EXISTS (
        SELECT 1 FROM fza_atributos_sku sa
        JOIN fza_atributos_valores v ON v.ID_AV = sa.ID_AV_SA
        WHERE sa.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU
          AND v.ID_VA_AV              = va.ID_ATB_VA);
```

La condición `LIKE CONCAT(...)` defiende contra códigos que no siguen
la convención `<ARTICULO>/<VAL1>/<VAL2>/…`. `ID_AV IS NULL` marca la
fila como virtual: la columna "Básico", "Nombre básico", "Paleta",
"Fuente"… salen vacías, sólo se ve el `NOMBRE_ATRIBUTO` y `VALOR_AV`
derivado del código.

### Materialización lazy: `AsegurarFilaSA`

Las filas virtuales son **sólo informativas**. La primera vez que el
usuario edita el básico de una fila virtual, `AsegurarFilaSA`:

1. Busca o crea el `ID_AV` en `fza_atributos_valores` (par
   `ID_VA_AV + AV`).
2. `INSERT IGNORE INTO fza_atributos_sku` con el bridge
   SKU ↔ AV.
3. Devuelve el `ID_AV` real para que el llamante pueda colgar el
   básico del artículo.

Se invoca desde:
- `AsegurarBasicoFilaActual` (al editar Nombre / Paleta / Valor /
  Unidad).
- `tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged` (al
  cambiar el lookup "Básico").

Tras la materialización, en el siguiente `ds.Refresh` la fila pasa de
la rama virtual del `UNION` a la rama real (con `ID_AV` poblado).

### Diálogo Global / Ad-hoc / Cancelar

Al crear un básico nuevo desde el helper (vía
`AsegurarBasicoFilaActual` o vía `OnValidate` del combo),
`PreguntarAmbitoBasico` muestra un `MessageBox` con tres opciones:

| Botón     | Resultado                                                          |
|-----------|--------------------------------------------------------------------|
| Sí        | `abGlobal` → `CODIGO_ATB = <valor_av>` (compartido entre artículos)|
| No        | `abAdHoc`  → `CODIGO_ATB = AD_<articulo>_<valor_av>` (exclusivo)   |
| Cancelar  | `abCancelar` → no se crea nada, la edición se descarta             |

Antes de esto, `AsegurarBasicoFilaActual` siempre creaba con prefijo
`AD_<articulo>_`, lo que dejaba al usuario sin forma de crear básicos
compartidos directamente desde el SKU.

## Script de actualización

`DESARROLLOS EN CURSO/atributos_basicos.sql`:

1. `ALTER TABLE fza_atributos_basicos` añade `DESCRIPCION_ATB`,
   `HEX_ATB`, `VALOR_NUM_ATB`, `UNIDAD_ATB` y auditoría
   (`IF NOT EXISTS`).
2. `ALTER TABLE fza_atributos_valores ADD COLUMN ID_ATB_AV` (fallback
   global).
3. `ALTER TABLE fza_atributos_conjuntos_det ADD COLUMN ID_ATB_ACD`
   (por conjunto).
4. `CREATE TABLE IF NOT EXISTS fza_articulos_atributos_basicos`
   (override por artículo).
5. Catálogo demo en `fza_atributos_basicos`:
   - Colores con HEX
   - Tallajes "Ropa Standard" S-XXXL con pecho cm
   - Tallajes "Bañador" S-XXL con cintura cm (XL=56)
   - Tallajes "Camisa Hombre" S-XL con cuello cm (XL=34)
   - Tallajes calzado EU 37-44 con cm de plantilla
6. Heurística de enlace inicial del fallback global para colores
   conocidos.
7. Migración del fallback global a los detalles de conjunto existentes.
8. `CREATE VIEW vi_atributos_sku_basico` con la resolución 3 niveles
   y `FUENTE_ATB`.
9. Registro de `AtributosBasicos` en `fza_winforms` con shortcut
   `Ctrl+Alt+B`.

Idempotente: `IF NOT EXISTS`, `ON DUPLICATE KEY UPDATE` y `UPDATE …
WHERE col IS NULL` permiten re-ejecutarlo sin riesgo.

> No tocamos `factuzam_original.sql`: el script lo aplica encima.

`DESARROLLOS EN CURSO/sku_atributos_huerfanos.sql`: recrea
`vi_atributos_sku_basico` con el `UNION ALL` que añade filas virtuales
para SKUs sin SA. Idempotente (`DROP VIEW IF EXISTS` + `CREATE VIEW`).
Se ejecuta encima del script anterior, no lo sustituye.

## Estilo

Nuevo sufijo registrado en `LIBRO_DE_ESTILO_BBDD.md`:

| Tabla                                | Sufijo |
|--------------------------------------|--------|
| `fza_articulos_atributos_basicos`    | `AAB`  |
