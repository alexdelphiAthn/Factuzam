# Indices de rendimiento

Migracion DDL que anade **catorce indices** sobre **diez tablas** para que el
sistema responda con fluidez al volumen real esperado: **20.000 articulos** y
**4.000 facturas** (con sus correspondientes lineas, SKUs, stock por almacen,
recibos y movimientos asociados).

El dump de referencia `factuzam_original.sql` **no** se toca. El DDL nuevo
vive aislado en `DESARROLLOS EN CURSO/indices_rendimiento.sql` y se aplica por
el cauce habitual a la BBDD existente.

La migracion se construyo en dos rondas:

- **Parte 1: gaps estructurales.** Tablas sin indices secundarios y consultas
  inversas obvias (las "tablas grandes que se filtran por una columna que la
  PK no cubre").
- **Parte 2: gaps detectados al leer cada consulta caliente.** Subconsultas
  correlacionadas, joins de vistas, calculos de arqueo, busqueda unificada
  del TPV. Estos son menos obvios pero estan en el camino caliente de la
  aplicacion.

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

## 2. Gaps cubiertos — Parte 1 (estructurales)

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

## 3. Gaps cubiertos — Parte 2 (lectura del codigo caliente)

Aqui los indices NO se justifican por "tabla sin indices" sino por consultas
concretas del codigo Delphi cuyo plan de ejecucion no encajaba con los
indices existentes. Se incluyen referencias `file:line` para que la
correlacion sea reproducible.

### 3.1 `fza_articulos_proveedores` (sufijo `AP`) — busqueda en TPV

`IDX_AP_REF (REF_PROVEEDOR_AP)`

La vista `vi_caja_busqueda_unificada` (definida en BBDD) incluye una rama
`MODELO_PROV` que filtra `ap.REF_PROVEEDOR_AP = :input` cada vez que en el
TPV se teclea o escanea algo
(`src/Lib/inLibArticulosValidador.pas:171,318`).
No hay indice sobre esa columna y la PK es `(CODIGO_PRV_AP, CODIGO_ART_AP)`,
asi que la lectura del TPV escaneaba **toda la tabla de articulos x
proveedores en cada pulsacion**. Es probablemente el peor gap individual
del sistema para el flujo de venta.

Nota: este indice es independiente del `IDX_AP_ART_PRINC` de la Parte 1.
Ese otro cubre la consulta inversa "que proveedores tiene este articulo";
este nuevo cubre la consulta "que articulo le corresponde a esta
referencia de proveedor".

### 3.2 `fza_articulos_tarifas` (sufijo `ARTTAR`) — bloque tarifa

`IDX_ARTTAR_BUSQ_VIGENTE (CODIGO_ART_ARTTAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, FECHA_DESDE_ARTTAR)`

El modal "Anadir bloque de tarifa copiando precios de otra"
(`src/Modals/inMtoModalAddBlockTarifa.pas:374-385`) construye una
subconsulta correlacionada que se ejecuta **una vez por cada articulo**
del SELECT externo:

```sql
(SELECT t.PRECIO_SALIDA_ARTTAR
   FROM fza_articulos_tarifas t
  WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART
    AND t.CODIGO_TAR_ARTTAR = :tar_orig
    AND t.ESACTIVO_ARTTAR   = 'S'
  ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1)
```

El indice existente `IDX_ART_TARIFAS_BUSQUEDA (art, tar)` cubre el WHERE
basico pero no incluye `ESACTIVO_ARTTAR` ni `FECHA_DESDE_ARTTAR`, por lo
que MariaDB tiene que ordenar las filas resultado en memoria por cada
articulo. Con 20.000 articulos sobre los que iterar, este bloque es
catastrofico sin el indice nuevo.

### 3.3 `fza_empresas_series` (sufijo `EMPSER`) — serie por defecto

`IDX_EMPSER_EMP_TIPO_FECHA (CODIGO_EMP_EMPSER, TIPO_DOC_EMPSER, FECHA_DESDE_EMPSER)`

PK = `CODIGO_SERIE_EMPSER` (una sola columna). La obtencion de la serie
por defecto vive en `src/DataModules/UniDataInventarios.pas:412-429` y
funciones similares de facturas/albaranes/pedidos:

```sql
WHERE CODIGO_EMP_EMPSER = :emp
  AND TIPO_DOC_EMPSER   = :tipo
  AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= NOW())
  AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= NOW())
ORDER BY FECHA_DESDE_EMPSER DESC LIMIT 1
```

Tabla pequena (decenas de filas), pero la consulta se ejecuta en CADA
creacion de documento. Sin indice = full-scan repetido. Con `(emp, tipo,
fecha_desde)` la consulta lee solo las filas del par (empresa, tipo) y
ordena unicamente esas.

### 3.4 `fza_movimientos_almacen` (sufijo `MOV`) — movimientos de un articulo

`IDX_MOV_ART_ALM (CODIGO_ART_MOV, CODIGO_ALM_MOV)`

La tabla ya tiene seis indices, pero ninguno por `CODIGO_ART_MOV` (codigo
del articulo padre). Solo se indexan `CODIGO_UNIDAD_MOV` (SKU concreto) y
`CODIGO_ALM_MOV`. La pantalla de inventario en
`src/DataModules/UniDataInventarios.pas:1213-1221` filtra por articulo
padre + almacen para mostrar el historico de movimientos del articulo:

```sql
WHERE m.CODIGO_ART_MOV = :art AND m.CODIGO_ALM_MOV = :alm
```

Con el volumen historico esperado (muchos miles de movimientos),
esto sin indice escanea por almacen entero. El indice compuesto resuelve
la consulta exacta.

### 3.5 `fza_depositos_cliente` (sufijo `DEP`) — arqueo por rango de fechas

`IDX_DEP_OP_FECHA (CODIGO_EMP_DEP, CODIGO_ALM_DEP, CODIGO_CAJA_DEP, FECHA_CREACION_DEP)`

El calculo del arqueo de caja (`src/Caja/Lib/inLibArqueo.pas:378-383`,
`CalcularDepositos`) suma los prestamos del rango:

```sql
WHERE CODIGO_EMP_DEP  = :emp
  AND CODIGO_ALM_DEP  = :alm
  AND CODIGO_CAJA_DEP = :caja
  AND FECHA_CREACION_DEP BETWEEN :desde AND :hasta
```

Los indices existentes `IDX_DEP_OP_ALTA` y `IDX_DEP_OP_CANCEL` cubren
las 4-columnas (EMP, ALM, CAJA, NUMERO_OPERACION_xxx) pero ninguno
termina en `FECHA_CREACION_DEP`. Para un arqueo de mes completo el plan
acababa escaneando todos los depositos del contexto de caja.

---

## 4. Indices descartados (y por que)

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
- **`fza_caja_operaciones (FECHA_OPERACION_OPCAJA)` solo**: los listados
  globales sin contexto son raros; los seis indices existentes cubren bien
  el flujo cotidiano filtrando primero por (EMP, ALM, CAJA).

---

## 5. Antipatrones de consulta detectados

Al rastrear las consultas calientes aparecieron tres patrones que rompen
el uso de los indices ya existentes. Dos se corrigen en esta misma rama
tocando el codigo Delphi (5.1 y 5.2); el tercero queda como mejora de
segundo orden (5.3).

### 5.1 `DATE(FECHA_OPERACION_OPCAJA)` en consulta de operaciones — CORREGIDO

**Archivo:** `src/DataModules/UniDataConsultaOpe.pas:144`

**Antes:**

```sql
WHERE DATE(o.FECHA_OPERACION_OPCAJA) = :PFECHA
  AND o.CODIGO_EMP_OPCAJA = :PEMP
  ...
```

Aplicar `DATE()` a la columna rompia el uso de
`IDX_OPCAJA_CTX_FECHA (EMP, ALM, CAJA, FECHA_OPERACION_OPCAJA)` porque la
funcion envuelve la columna y MariaDB no puede usar el indice.

**Despues:**

```sql
WHERE o.FECHA_OP_DIA_OPCAJA = :PFECHA
  AND o.CODIGO_EMP_OPCAJA   = :PEMP
  ...
```

El dump ya tenia la columna `FECHA_OP_DIA_OPCAJA` (tipo `date`) con su
indice `IDX_OPCAJA_DIA_CTX (FECHA_OP_DIA_OPCAJA, EMP, ALM, CAJA)`. La
consulta ahora usa exactamente ese indice como cobertura completa.

### 5.2 `DATE(FECHA_EMISION_VL)` y `DATE(FECHA_REDENCION_VL)` en arqueo — CORREGIDO

**Archivo:** `src/Caja/Lib/inLibArqueo.pas:444-445, 468-469`

**Antes:**

```sql
WHERE CODIGO_EMP_EMI_VL = :emp
  AND CODIGO_ALM_EMI_VL = :alm
  AND CODIGO_CAJA_EMI_VL = :caja
  AND DATE(FECHA_EMISION_VL) >= :pFDESDE
  AND DATE(FECHA_EMISION_VL) <= :pFHASTA
```

**Despues** (half-open interval para preservar la semantica "incluye
todo el dia final" incluso con `FECHA_EMISION_VL datetime`):

```sql
WHERE CODIGO_EMP_EMI_VL = :emp
  AND CODIGO_ALM_EMI_VL = :alm
  AND CODIGO_CAJA_EMI_VL = :caja
  AND FECHA_EMISION_VL >= :pFDESDE
  AND FECHA_EMISION_VL <  DATE_ADD(:pFHASTA, INTERVAL 1 DAY)
```

Misma transformacion para `FECHA_REDENCION_VL` en la consulta de vales
recogidos. Quitar `DATE()` permite al optimizador filtrar por el rango
tras aplicar el prefijo del indice `IDX_VALES_EMI_OP` /
`IDX_VALES_RED_OP` (contexto de caja), en lugar de evaluar la funcion
fila a fila.

**Nota sobre el cambio del `<=` por `<`:** la version anterior con
`DATE(...) <= :pFHASTA` traducia, p.ej., `:pFHASTA = '2026-05-19'` en
"incluye todos los vales del 19". Si simplemente se quita el `DATE()`
y se mantiene el `<= :pFHASTA`, MariaDB compara contra `'2026-05-19
00:00:00'` y se pierden todos los vales emitidos a lo largo del 19.
`DATE_ADD(:pFHASTA, INTERVAL 1 DAY)` con `<` (estrictamente menor)
preserva la semantica original sin envolver la columna en funcion.

### 5.3 `(FECHA IS NULL OR FECHA <= NOW())` en obtencion de vigentes

**Archivos:** `src/DataModules/UniDataInventarios.pas:412-429`,
`src/Lib/inLibFacturas.pas:1199-1213`, y similares.

El OR sobre IS NULL limita el uso del indice compuesto cuando la fecha
forma parte del compuesto. La cardinalidad post-filtro previo (empresa,
tipo, articulo) es baja, asi que el impacto es manejable; queda como
mejora de segundo orden cuando se revise la logica de vigencia.

---

## 6. Aplicacion

```sh
mysql -u <user> -p <database> < "DESARROLLOS EN CURSO/indices_rendimiento.sql"
```

La migracion es **idempotente**: cada indice se crea a traves del
procedimiento `PRC_ADD_INDEX_IF_NOT_EXISTS`, que consulta
`information_schema` antes de ejecutar el `ALTER TABLE`. Si el indice ya
existe lo deja igual, sin warnings ni errores.

El procedimiento se crea con el formato canonico del dump
(`-- Procedimiento: ...`, `DELIMITER ;;`, `CREATE  PROCEDURE`, `END ;;`)
y **queda instalado** en la BBDD junto a los demas `PRC_*`, listo para
reutilizarse en futuras migraciones de rendimiento.

### 6.1 Verificacion

Consulta de comprobacion al final del script (comentada). Devuelve los
catorce indices nuevos con su tabla y columnas:

```sql
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
  FROM information_schema.statistics
 WHERE TABLE_SCHEMA = DATABASE()
   AND INDEX_NAME IN (
     'IDX_SKU_ART_ACT','IDX_STK_UNIDAD','IDX_AP_ART_PRINC',
     'IDX_ARTVIN_PADRE','IDX_ARTVIN_HIJO',
     'IDX_REC_ESTADO_VENC','IDX_REC_CLI',
     'IDX_FACLIN_UNIDAD','IDX_ALBLIN_FAC',
     'IDX_AP_REF','IDX_ARTTAR_BUSQ_VIGENTE',
     'IDX_EMPSER_EMP_TIPO_FECHA','IDX_MOV_ART_ALM','IDX_DEP_OP_FECHA'
   )
 GROUP BY TABLE_NAME, INDEX_NAME
 ORDER BY TABLE_NAME, INDEX_NAME;
```

### 6.2 Coste en escritura

Los indices anadidos son ligeros (1-4 columnas pequenas: codigos cortos,
flags, fechas). El impacto en `INSERT`/`UPDATE` es despreciable comparado
con la ganancia en lectura, dada la proporcion lectura/escritura tipica
de un ERP (caja, listados, informes).

El indice mas pesado es `IDX_ARTTAR_BUSQ_VIGENTE` con 4 columnas, pero la
tabla `fza_articulos_tarifas` se escribe poco comparado con las tablas de
operaciones.

---

## 7. Resumen

### 7.1 Parte 1: gaps estructurales

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

### 7.2 Parte 2: gaps detectados en consultas calientes

| #  | Tabla                       | Indice                       | Columnas                                                                       |
|----|-----------------------------|------------------------------|--------------------------------------------------------------------------------|
| 10 | `fza_articulos_proveedores` | `IDX_AP_REF`                 | `(REF_PROVEEDOR_AP)`                                                           |
| 11 | `fza_articulos_tarifas`     | `IDX_ARTTAR_BUSQ_VIGENTE`    | `(CODIGO_ART_ARTTAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, FECHA_DESDE_ARTTAR)`  |
| 12 | `fza_empresas_series`       | `IDX_EMPSER_EMP_TIPO_FECHA`  | `(CODIGO_EMP_EMPSER, TIPO_DOC_EMPSER, FECHA_DESDE_EMPSER)`                     |
| 13 | `fza_movimientos_almacen`   | `IDX_MOV_ART_ALM`            | `(CODIGO_ART_MOV, CODIGO_ALM_MOV)`                                             |
| 14 | `fza_depositos_cliente`     | `IDX_DEP_OP_FECHA`           | `(CODIGO_EMP_DEP, CODIGO_ALM_DEP, CODIGO_CAJA_DEP, FECHA_CREACION_DEP)`        |

### 7.3 Reescrituras en codigo Delphi

| # | Archivo                                       | Patron corregido                                                       | Estado    |
|---|-----------------------------------------------|------------------------------------------------------------------------|-----------|
| A | `src/DataModules/UniDataConsultaOpe.pas:144`  | `DATE(FECHA_OPERACION_OPCAJA)` → `FECHA_OP_DIA_OPCAJA`                 | hecho     |
| B | `src/Caja/Lib/inLibArqueo.pas:444-445, 468-469`    | `DATE(FECHA_EMISION_VL/REDENCION_VL)` → `>= :desde AND < :hasta + 1 d` | hecho     |
| C | `src/DataModules/UniDataInventarios.pas:412`  | `(FECHA IS NULL OR FECHA <= NOW())` → repensar logica vigencia         | pendiente |
