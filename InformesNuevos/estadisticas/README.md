# Estadísticas / aceleración de informes — módulo aislado

Lab tratado **como un programa distinto**: namespace propio en BBDD
(`vi_estadisticas_*` para vistas, `fzaest_*` para tablas de prueba), su propia
carpeta, y solo se injerta en Factuzam cuando se acepte.

## Reglas acordadas

- Sobre el esquema real `fza_*`: **solo vistas nuevas, NINGÚN cambio**
  (ni tablas, ni columnas, ni índices).
- Para **probar** pre-agregados sí se pueden crear tablas, pero con **prefijo
  propio `fzaest_`** para no mezclarlas con `fza_`. Son desechables (un DROP
  deja la BBDD igual).

## Modelo de dimensiones (importante)

- **Almacén**: `CODIGO_ALMACEN_MOV` (mov) / `CODIGO_ALM_FACLIN` (línea venta).
- **Familia**: `fza_articulos.CODIGO_FAM_ART` (nivel artículo).
- **Temporada**: NO es columna de `fza_articulos`. Es la **propiedad
  'TEMPORADA'** (`fza_propiedades`, `NIVEL_PROP = 'COLOR'` → **2º nivel**),
  con valores en `fza_articulos_propiedades` según `CODIGO_UNIDAD_ARTPROP`:
  - `''` → valor a nivel **artículo**
  - `ART/COLOR` → valor a nivel **color** (¡la temporada puede variar por
    color!)
  - `ART/COLOR/TALLA` → valor a nivel sku
  Se resuelve por la clave de color derivada del SKU
  (`SUBSTRING_INDEX(sku,'/',2)`), con **fallback** a nivel artículo. **No** se
  usa `vi_articulos`: colapsa temporada a un único valor por artículo (y
  multiplicaría filas si hay temporada por color).

## Ficheros

### `vistas_estadisticas.sql` (solo lectura sobre `fza_*`)

| Vista                              | Para qué                          |
|------------------------------------|-----------------------------------|
| `vi_propiedad_temporada`           | Resolver temporada (artículo/color)|
| `vi_estadisticas_movimientos_dia`  | Agregado diario de movimientos    |
| `vi_estadisticas_ventas_dia`       | Agregado diario de ventas (líneas)|
| `vi_estadisticas_dia`              | Unión de ambas (1 fila por grano) |
| `vi_estadisticas_temporadas`       | Lista de temporadas para el combo |

### `fzaest_experimental.sql` (tablas de prueba `fzaest_`)

- `fzaest_estadisticas_dia`: tabla de acumulado diario (mismo grano/medidas
  que `vi_estadisticas_dia`).
- `fzaest_recalcular_rango(pD1, pD2)`: recálculo incremental por rango
  (`DELETE` + `INSERT ... SELECT FROM vi_estadisticas_dia`), tolera
  correcciones retroactivas y reclasificaciones.

## Qué aporta (y qué NO) una vista

- **Aporta**: encapsula joins y reglas (temporada por color, ventas a nivel
  línea, activos) en un contrato estable.
- **NO aporta**: no materializa. Además, una vista con `GROUP BY` no empuja el
  filtro de fecha antes de agregar (TEMPTABLE), por lo que para el **panel en
  vivo** conviene seguir filtrando por fecha sobre las tablas base (como hace
  el `.pas`). Las vistas valen para encapsular y para alimentar `fzaest_`.

## Cómo decidir si compensa el pre-agregado

1. Cargar `vistas_estadisticas.sql`.
2. (Opcional) Cargar `fzaest_experimental.sql` y
   `CALL fzaest_recalcular_rango('2020-01-01', CURDATE());`.
3. Comparar tiempos del MISMO rango largo: en vivo (tablas base / vista) vs
   `fzaest_estadisticas_dia`. Si el pre-agregado gana claramente y el caso lo
   pide (años / muchos usuarios), se propone integrarlo; si no, se queda solo
   en vistas + índices existentes.
