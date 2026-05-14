# Atributos básicos en el SKU de artículos

## Idea

Cada **valor de atributo** de un SKU (TALLA="XL", COLOR="001 del proveedor",
TEMP="ROJO 003"…) lleva ahora asociado un **atributo básico** que actúa de
helper / equivalente estándar.

| Atributo del SKU              | Atributo básico (helper)                    |
|-------------------------------|---------------------------------------------|
| TALLA = `XL`                  | TALLA XL = **47 cm** de pecho               |
| COLOR = `001` (ref proveedor) | COLOR = **AZUL CIELO**, paleta **#87CEEB**  |
| COLOR = `REF-AB12`            | COLOR = **ROJO**, paleta **#FF0000**        |
| TALLA = `42` (calzado)        | EU 42 = **26.5 cm** de plantilla            |

El valor "concreto" (lo que cambia entre proveedores, refs internas, códigos
de fabricante…) no se toca: se le **enlaza** con el atributo básico
correspondiente para que el usuario sepa, de un vistazo, qué representa
realmente.

## Tablas implicadas

```
fza_atributos_basicos         -- catálogo estándar de atributos básicos
fza_atributos_valores         -- recibe nueva FK ID_ATB_AV → ATB
fza_atributos_sku             -- (sin cambios) liga SKU ↔ valor
fza_articulos_skus            -- (sin cambios) cabecera del SKU
vi_atributos_sku_basico       -- vista que une SKU + valor + básico
```

### `fza_atributos_basicos`

| Columna           | Tipo            | Comentario                                  |
|-------------------|-----------------|---------------------------------------------|
| `ID_ATB`          | int             | PK auto-increment                           |
| `ID_VA_ATB`       | varchar(20)     | Atributo de variación (CO, TAL…)            |
| `CODIGO_ATB`      | varchar(30)     | Código estable: `XL`, `AZUL_CIELO`, `EU42`  |
| `NOMBRE_ATB`      | varchar(100)    | Nombre legible: `AZUL CIELO`                |
| `DESCRIPCION_ATB` | varchar(255)    | Descripción larga                           |
| `HEX_ATB`         | varchar(7)      | `#RRGGBB` de paleta                         |
| `VALOR_NUM_ATB`   | decimal(12,4)   | 47 cm de talla, 26.5 cm de calzado…         |
| `UNIDAD_ATB`      | varchar(10)     | `cm`, `mm`, `kg`…                           |
| `ORDEN_ATB`       | int             | Orden de presentación                       |
| `ESACTIVO_ATB`    | char(1)         | `S`/`N`                                     |
| `INSTANTE_*`,     | timestamp       | Auditoría estándar                          |
| `USUARIO_*`       | varchar(100)    |                                             |

Clave única `(ID_VA_ATB, CODIGO_ATB)` para que `ON DUPLICATE KEY` funcione
en la carga.

### `fza_atributos_valores`

Nueva columna:

| Columna     | Tipo  | Comentario                                                  |
|-------------|-------|-------------------------------------------------------------|
| `ID_ATB_AV` | int   | FK lógica → `fza_atributos_basicos.ID_ATB`. NULL = sin enlace |

Con esto, el valor concreto **"001"** del proveedor X queda enlazado al
atributo básico **AZUL_CIELO**. Otros proveedores con su propio código
para el mismo color (REF-44, COD-002…) apuntan al mismo `ID_ATB`.

### Vista `vi_atributos_sku_basico`

Devuelve, una fila por (SKU × atributo del SKU):

```sql
CODIGO_ART_SKU,  CODIGO_UNIDAD_SKU, CODIGO_VAR_SKU,
ID_AV, ID_VA_AV, NOMBRE_ATRIBUTO, ORDEN_ATRIBUTO,
VALOR_AV, DESCRIPCION_AV,
ID_ATB_AV, CODIGO_ATB, NOMBRE_ATB, DESCRIPCION_ATB,
HEX_ATB, VALOR_NUM_ATB, UNIDAD_ATB,
ETIQUETA_BASICO       -- texto helper listo para mostrar
```

`ETIQUETA_BASICO` consolida en una sola cadena lo más útil:

- Si hay medida numérica → `"47 cm"`, `"26.5 cm"`
- Si hay HEX           → `"AZUL CIELO #87CEEB"`
- Si no                → `NOMBRE_ATB` a secas

## Cambios en el cliente Delphi

### `UniDataArticulos`

`unqryDetallesAtributos` deja de ser editable contra
`fza_articulos_variaciones_def` (no se usaba) y pasa a leer `vi_atributos_sku_basico`. Master-detail por `CODIGO_ART_ART`/`CODIGO_ART_SKU`,
de modo que en el formulario sólo aparecen los SKUs del artículo abierto.
Se abre en `DataModuleCreate` junto a los demás.

### `inMtoArticulos` — pestaña *2_SKUs*

La pestaña se parte en dos:

- Arriba (200 px): la cuadrícula original de SKUs (alta/baja, precio
  última compra, fecha…). Las columnas *Precio Últ Compra* y *Fecha Últ
  Compra* se ocultan automáticamente cuando ningún SKU tiene un coste
  asignado, evitando ruido visual cuando los costes viven sólo a nivel
  del artículo padre (`ActualizarVisibilidadColumnaSku`).
- `TcxSplitter` para redimensionar.
- Abajo (alClient): nueva cuadrícula `cxgrdSkuAtributosBasicos` con la
  información helper. **Solo muestra los atributos del SKU activo**: el
  master-source de `unqryDetallesAtributos` es `dsSkus` con
  `MasterFields = DetailFields = CODIGO_UNIDAD_SKU`, así que al cambiar
  de SKU en la rejilla superior, el detalle se refiltra solo.

  | Columna       | Origen                                  |
  |---------------|-----------------------------------------|
  | Atributo      | `ID_VA_AV`                              |
  | Nombre atrib. | `NOMBRE_ATRIBUTO`                       |
  | Valor         | `VALOR_AV`                              |
  | **Básico**    | `ID_ATB_AV` (editable, lookup combo)    |
  | Nombre básico | `NOMBRE_ATB`                            |
  | **Paleta**    | `HEX_ATB` (button-edit + color picker)  |
  | Valor básico  | `VALOR_NUM_ATB`                         |
  | Unidad        | `UNIDAD_ATB`                            |
  | Equivalencia  | `ETIQUETA_BASICO`                       |

#### Edición del atributo básico

La columna **Básico** es un `TcxLookupComboBox` enlazado a
`unqryAtributosBasicosLookup` (catálogo completo de
`fza_atributos_basicos`). Antes de abrir el desplegable,
`OnInitPopup` aplica `Filter = "ID_VA_ATB = '<atributo de la fila>'"` para
que un atributo CO sólo vea atributos básicos de color, un atributo TAL
sólo tallas, etc.

`OnEditValueChanged` lanza inmediatamente un
`UPDATE fza_atributos_valores SET ID_ATB_AV = :ATB WHERE ID_AV = :AV` y
hace `Refresh` de la vista para repintar HEX, valor numérico y
equivalencia. La vista subyacente (`vi_atributos_sku_basico`) sería
read-only para el framework: se evita el error abortando el Post estándar
desde `unqryDetallesAtributosBeforePost`.

#### Selector de paleta

La columna **Paleta** es un button-edit con `[...]`. Al pulsar el botón
(o hacer doble-clic en la celda) se abre un `TColorDialog` precargado
con el HEX actual. Si la fila aún no tiene atributo básico asignado se
avisa al usuario. Al aceptar:

```sql
UPDATE fza_atributos_basicos
   SET HEX_ATB = '#RRGGBB', USUARIO_MODIF = :USR
 WHERE ID_ATB = :ID
```

y se refresca tanto la vista del detalle como el lookup (para que la
nueva paleta aparezca al elegir el mismo básico desde otra fila).

La columna sigue dibujándose con `OnCustomDrawCell`: cuadrado relleno
con el color real, HEX rotulado en blanco o negro según luminancia.

## Script de actualización

`DESARROLLOS EN CURSO/atributos_basicos.sql`:

1. `ALTER TABLE fza_atributos_basicos ADD COLUMN ...` (idempotente con
   `IF NOT EXISTS`).
2. `ALTER TABLE fza_atributos_valores ADD COLUMN ID_ATB_AV` + índice.
3. Carga del catálogo base (colores con HEX, tallas ropa con cm, tallas
   calzado EU 37-44).
4. `UPDATE` heurístico que enlaza los valores existentes con el atributo
   básico que les corresponde por nombre.
5. `CREATE VIEW vi_atributos_sku_basico`.

Re-ejecutable sin riesgo: las ALTER usan `IF NOT EXISTS`, los INSERT
usan `ON DUPLICATE KEY UPDATE` y el UPDATE de enlace sólo toca filas
con `ID_ATB_AV IS NULL`.

## Cómo extenderlo

- **Más atributos básicos**: insertar filas en `fza_atributos_basicos`
  con su `ID_VA_ATB` correspondiente (CO, TAL, TEMP, MATERIAL…).
- **Reasignar un valor concreto**: editar `ID_ATB_AV` del valor en
  `fza_atributos_valores` (mantenimiento existente).
- **Mostrar la paleta en otros formularios**: reusar la vista
  `vi_atributos_sku_basico` filtrando por `CODIGO_UNIDAD_SKU` y reutilizar
  `tvSkuAtributosBasicosHEX_ATBCustomDrawCell` como referencia para
  pintar HEX en otras rejillas.
