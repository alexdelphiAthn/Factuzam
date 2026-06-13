# Descripción del color por-artículo + activar/desactivar SKU por color

Dos mejoras sobre la **ficha SKU del artículo** (pestaña `2_SKUs` de
`inMtoArticulos`), pedidas para gestionar el color desde el propio artículo.

## 1. Descripción del color (por artículo)

El panel inferior "Atributos del SKU + Atributo básico (helper)" muestra ahora
**tres campos** por fila de color:

| Campo | Columna grid | Origen |
|---|---|---|
| Color proveedor | `VALOR_AV` | `fza_atributos_valores.AV` (texto saneado del proveedor) |
| Color básico | `ID_ATB_AV` | básico resuelto (override art. → conjunto → global) |
| Descripción del color | `DESCRIPCION_AAB` | **nuevo**, por artículo |

`DESCRIPCION_AAB` es `varchar(255) NULL` y vive en
**`fza_articulos_atributos_basicos`** (la tabla puente artículo↔valor, PK
`CODIGO_ART_AAB` + `ID_AV_AAB`). Por eso la descripción es **distinta para cada
artículo** aunque el color (AV) o el básico (ATB) se compartan: el catálogo
global (`fza_atributos_basicos.DESCRIPCION_ATB`) sigue siendo compartido y no se
toca.

### Persistencia (Delphi)
`tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged` hace UPSERT
sobre `fza_articulos_atributos_basicos`. Si la fila override aún no existe, la
crea **sembrando `ID_ATB_AAB` con el básico ya resuelto** (`ID_ATB_AV` de la
vista) para que añadir una descripción NO altere el color mostrado (una fila con
`ID_ATB_AAB` NULL significaría "bloqueo / sin básico"). El `ON DUPLICATE KEY
UPDATE` toca solo `DESCRIPCION_AAB`, así que descripción y básico se editan de
forma independiente.

## 2. Activar / desactivar SKU por color

- **Un SKU suelto**: ya existía (casilla `Activo` = `ESACTIVO_SKU` en el grid de
  SKUs).
- **Todos los SKU de un color** (nuevo): dos vías que comparten lógica —
  - menú botón derecho sobre el panel de atributos, y
  - botón lateral "Activar/Desact. color" (despliega el mismo menú).
  
  Resuelve el color del SKU seleccionado (fila `CO` del detalle) y lanza
  `TdmArticulos.ActualizarSkusColorActivo`, que hace un `UPDATE
  fza_articulos_skus SET ESACTIVO_SKU=...` filtrando por color a través de
  `vi_atributos_sku_basico`. La subconsulta se envuelve en una tabla derivada
  para sortear el error 1093 de MariaDB (leer y actualizar la misma tabla). No
  hay cambio de esquema para esto.

## Esquema (`sku_descripcion_color.sql`)
- Añade `DESCRIPCION_AAB` a `fza_articulos_atributos_basicos` (idempotente vía
  `INFORMATION_SCHEMA`).
- Recrea `vi_atributos_sku_basico` (DROP + CREATE) añadiendo `DESCRIPCION_AAB`
  como último campo (real → `aab.DESCRIPCION_AAB`; virtual → `NULL`).
- No se toca `factuzam_original.sql` (regla 1).

## Pendiente / a vigilar
- No se ha podido compilar Delphi en el entorno; conviene un *build* en el IDE
  de `inMtoArticulos` y `UniDataArticulos`.
- Aplicar `sku_descripcion_color.sql` a las BBDD existentes antes de abrir la
  ficha (si no, el grid no encontrará la columna `DESCRIPCION_AAB`).
