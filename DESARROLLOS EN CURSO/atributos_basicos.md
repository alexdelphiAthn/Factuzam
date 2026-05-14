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
ID_ATB_AAB      int           -- FK básico
+ auditoría
PRIMARY KEY (CODIGO_ART_AAB, ID_AV_AAB)
```

Sirve para los casos en que dos artículos comparten conjunto pero
necesitan interpretación distinta de un valor concreto: por ejemplo,
proveedor A llama "7" al blanco y proveedor B al negro, los dos en el
mismo conjunto de colores. Cada artículo crea su override.

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
    ve básicos de color, TAL sólo tallas).
  - `OnEditValueChanged` **escribe en `fza_articulos_atributos_basicos`**:
    UPSERT del override por artículo si se elige un básico, DELETE de
    la fila si se vacía (vuelve a caer al conjunto o al global).
  - La columna "Paleta" pinta el color real con `OnCustomDrawCell` y su
    botón `[...]` (o doble-clic) abre `TColorDialog` para editar
    `HEX_ATB` directamente en `fza_atributos_basicos`.

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

## Estilo

Nuevo sufijo registrado en `LIBRO_DE_ESTILO_BBDD.md`:

| Tabla                                | Sufijo |
|--------------------------------------|--------|
| `fza_articulos_atributos_basicos`    | `AAB`  |
