# Indices de rendimiento

Migracion DDL que anade nueve indices sobre siete tablas para que el sistema
responda con fluidez al volumen real esperado: **20.000 articulos** y
**4.000 facturas** (con sus correspondientes lineas, SKUs, stock por almacen,
recibos y movimientos asociados).

El dump de referencia `factuzam_original.sql` **no** se toca. El DDL nuevo
vive aislado en `DESARROLLOS EN CURSO/indices_rendimiento.sql` y se aplica por
el cauce habitual a la BBDD existente.

---

## 1. Metodologia

Para detectar cada gap se cruzaron dos fuentes:

1. **Esquema actual** (`factuzam_original.sql`): se extrajo el catalogo completo
   de PRIMARY KEY e `ALTER TABLE ... ADD INDEX` ya definidos. Hay 107 indices
   antes de esta migracion.
2. **Codigo Delphi** (`src/`): se recorrieron las consultas SQL embebidas en los
   `DataModules/`, `Forms/`, `Modals/` y las vistas declaradas en
   `src/utilnormbbdd/factuzam_original.sql`, anotando para cada tabla critica
   las columnas que aparecen en `WHERE`, `JOIN ... ON`, `ORDER BY` y `GROUP BY`.

Un indice candidato entra en esta migracion si:

- Soporta un patron de consulta recurrente del codigo,
- y la PK existente no puede atenderlo (porque la columna que filtra no es la
  primera del compuesto, o es una tabla sin indices secundarios).

Indices que ya estaban cubiertos por la PK como prefijo (por ejemplo, filtrar
`fza_atributos_sku` por `CODIGO_UNIDAD_SKU_SA` solo) se han descartado.

---

## 2. Gaps cubiertos

Cada bloque indica el escenario que dejaba de hacer full-scan al aplicar el
indice. Sufijo de tabla segun §2 del libro de estilo de BBDD.

### 2.1 `fza_articulos_skus` (sufijo `SKU`)

`IDX_SKU_ART_ACT (CODIGO_ART_SKU, ESACTIVO_SKU)`

La unica clave era la PK `CODIGO_UNIDAD_SKU`. Pero los SKUs se consultan
masivamente "por su articulo padre" en tres caminos calientes:

- Vistas: `vi_articulos_skus_extendida`, `vi_caja_busqueda_unificada`,
  `vi_articulos_tarifas`.
- Pantalla maestro de articulos al cargar variantes
  (`inMtoArticulos.pas:1425, 1590`).
- Caja al desplegar tallas/colores al teclear el codigo padre
  (`inMtoCajaOpe.pas:1565, 1933`).

El indice compuesto cubre tambien el filtro `ESACTIVO_SKU = 'S'`, presente en
casi todas esas consultas. Para 20k articulos con varias variantes cada uno
(~50k-80k SKUs estimados) elimina un full-scan que ocurre en cada venta.

### 2.2 `fza_articulos_stockactual` (sufijo `STK`)

`IDX_STK_UNIDAD (CODIGO_UNIDAD_STK)`

PK = `(CODIGO_ALM_STK, CODIGO_UNIDAD_STK, LOTE_STK)`. Cuando una consulta no
sabe el almacen (porque quiere el stock TOTAL de un SKU sumando todos los
almacenes), la PK no la atiende: hay que escanear toda la tabla.

Llamadas afectadas: `inMtoCajaOpe.pas:453` (tooltip de stock en caja),
`UniDataArticulos.pas:850` (etiquetas con stock), `UniDataInventarios.pas:917`
y la subconsulta agregada `SUM(CANTIDAD_STK) GROUP BY CODIGO_UNIDAD_STK` que
forma parte de `vi_articulos_skus_extendida` (esta ultima es la que mas duele:
la vista la usa cualquier listado de articulos en pantalla).

### 2.3 `fza_articulos_proveedores` (sufijo `AP`)

`IDX_AP_ART_PRINC (CODIGO_ART_AP, ESPROVEEDORPRINCIPAL_AP)`

PK = `(CODIGO_PRV_AP, CODIGO_ART_AP)`. La consulta inversa "que proveedores
suministran este articulo" aparece en `UniDataArticulos.pas:391` y en *todas*
las vistas que enriquecen el listado de articulos con el proveedor principal:
`vi_articulos`, `vi_articulos_list`, `vi_art_busquedas`, `vi_articulos_tarifas`,
`vi_proveedores_articulos`. Esto significa que el listado de articulos en
pantalla -el del Mto principal- hacia un full-scan de la tabla de articulos x
proveedores. El indice compuesto cubre tambien el filtro habitual
`ESPROVEEDORPRINCIPAL_AP = 'S'`.

### 2.4 `fza_articulos_vinculos` (sufijo `ARTVIN`)

- `IDX_ARTVIN_PADRE (CODIGO_ART_PADRE_ARTVIN)`
- `IDX_ARTVIN_HIJO (CODIGO_ART_HIJO_ARTVIN)`

Solo tenia la PK autonumerica `ID_ARTVIN`, sin indice por padre ni hijo. Lista
de materiales (BOM) y consulta inversa "donde se usa este componente"
escanean toda la tabla. Con kits y articulos compuestos en uso, conviene
indexar las dos direcciones del grafo.

### 2.5 `fza_recibos` (sufijo `REC`)

- `IDX_REC_ESTADO_VENC (ESTADO_RECIBO_REC, FECHA_VENCIMIENTO_RECIBO_REC)`
- `IDX_REC_CLI (CODIGO_CLI_REC)`

Tabla sin ningun indice secundario. La cartera de cobros (recibos pendientes
ordenados por vencimiento) y el extracto por cliente eran scans completos.
Con 4.000 facturas se generan facilmente entre 6.000 y 20.000 recibos segun
forma de pago: ya merece la pena cubrir ambos accesos.

### 2.6 `fza_facturas_lineas` (sufijo `FACLIN`)

`IDX_FACLIN_UNIDAD (CODIGO_UNIDAD_FACLIN)`

Ya existia indice por `CODIGO_ART_FACLIN` (articulo padre) pero no por
`CODIGO_UNIDAD_FACLIN` (SKU concreto). Los informes de "que talla/color se ha
vendido" iteran linea a linea sin indice; con ~10 lineas por factura y
4k facturas, son ~40.000 filas a escanear cada vez.

### 2.7 `fza_albaranes_lineas` (sufijo `ALBLIN`)

`IDX_ALBLIN_FAC (SERIE_FAC_ALBLIN, NUMERO_FAC_ALBLIN)`

Las lineas de albaran ya tenian indices por articulo y por pedido origen, pero
no por factura destino. Al abrir una factura procedente de varios albaranes,
resolver "que lineas de albaran originaron esta factura" implicaba full-scan.

---

## 3. Indices descartados (y por que)

Para no inflar el indice y mantener su mantenimiento al minimo, se descartaron:

- **`fza_atributos_sku` por `CODIGO_UNIDAD_SKU_SA`**: la PK
  `(CODIGO_UNIDAD_SKU_SA, ID_AV_SA)` ya soporta esta busqueda como prefijo.
- **`fza_articulos.ESACTIVO_ART` solo**: baja selectividad (la mayoria de
  articulos estan activos). El combinado `(CODIGO_FAM_ART, ESACTIVO_ART)` ya
  cubre los filtros por familia que son los recurrentes.
- **`fza_facturas.TIPO_FAC`** y **`ESCONSOLIDADA_FAC`** solos: muy baja
  cardinalidad. Si se necesita, se cubrira en una segunda fase como parte de
  un indice compuesto con `FECHA_FAC`.
- **`fza_codigos_barras` como UNIQUE**: requiere validar que no hay
  duplicados en datos reales antes de promover el indice a UNIQUE; queda
  como ticket aparte.

---

## 4. Aplicacion

```sh
mysql -u <user> -p <database> < "DESARROLLOS EN CURSO/indices_rendimiento.sql"
```

La migracion es **idempotente**: cada indice se crea con un procedimiento
auxiliar (`sp_add_index_if_not_exists`) que consulta `information_schema`
antes de ejecutar el `ALTER TABLE`. Si el indice ya existe lo deja igual, sin
warnings ni errores. El procedimiento se elimina al final.

### 4.1 Verificacion

Consulta de comprobacion al final del script (comentada). Devuelve los nueve
indices nuevos con su tabla y columnas:

```sql
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
  FROM information_schema.statistics
 WHERE TABLE_SCHEMA = DATABASE()
   AND INDEX_NAME IN (
     'IDX_SKU_ART_ACT','IDX_STK_UNIDAD','IDX_AP_ART_PRINC',
     'IDX_ARTVIN_PADRE','IDX_ARTVIN_HIJO',
     'IDX_REC_ESTADO_VENC','IDX_REC_CLI',
     'IDX_FACLIN_UNIDAD','IDX_ALBLIN_FAC'
   )
 GROUP BY TABLE_NAME, INDEX_NAME
 ORDER BY TABLE_NAME, INDEX_NAME;
```

### 4.2 Coste en escritura

Los indices anadidos son ligeros (1-2 columnas pequenas: codigos cortos,
flags, fechas). El impacto en `INSERT`/`UPDATE` es despreciable comparado
con la ganancia en lectura, dada la proporcion lectura/escritura tipica
de un ERP (caja, listados, informes).

---

## 5. Resumen

| # | Tabla                      | Indice                  | Columnas                                            |
|---|----------------------------|-------------------------|-----------------------------------------------------|
| 1 | `fza_articulos_skus`       | `IDX_SKU_ART_ACT`       | `(CODIGO_ART_SKU, ESACTIVO_SKU)`                    |
| 2 | `fza_articulos_stockactual`| `IDX_STK_UNIDAD`        | `(CODIGO_UNIDAD_STK)`                               |
| 3 | `fza_articulos_proveedores`| `IDX_AP_ART_PRINC`      | `(CODIGO_ART_AP, ESPROVEEDORPRINCIPAL_AP)`          |
| 4 | `fza_articulos_vinculos`   | `IDX_ARTVIN_PADRE`      | `(CODIGO_ART_PADRE_ARTVIN)`                         |
| 5 | `fza_articulos_vinculos`   | `IDX_ARTVIN_HIJO`       | `(CODIGO_ART_HIJO_ARTVIN)`                          |
| 6 | `fza_recibos`              | `IDX_REC_ESTADO_VENC`   | `(ESTADO_RECIBO_REC, FECHA_VENCIMIENTO_RECIBO_REC)` |
| 7 | `fza_recibos`              | `IDX_REC_CLI`           | `(CODIGO_CLI_REC)`                                  |
| 8 | `fza_facturas_lineas`      | `IDX_FACLIN_UNIDAD`     | `(CODIGO_UNIDAD_FACLIN)`                            |
| 9 | `fza_albaranes_lineas`     | `IDX_ALBLIN_FAC`        | `(SERIE_FAC_ALBLIN, NUMERO_FAC_ALBLIN)`             |
