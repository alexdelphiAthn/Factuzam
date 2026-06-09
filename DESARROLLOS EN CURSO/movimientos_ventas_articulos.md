# Movimientos de ventas por artículos y fechas (ranking de ventas)

Informe horizontal (A4 apaisado) que reproduce el "Ranking de ventas por
múltiples agrupaciones" de OdaGest+: **una fila por artículo** (o por
artículo + almacén si se agrupa por almacén) con las magnitudes de compra
(entradas) y venta del periodo y **dos márgenes**. Reutiliza el mismo
estilo de filtrado que el balance de almacén con tallas (almacenes /
familias / proveedores / temporadas / artículos / fechas + agrupaciones)
añadiendo una fecha extra: **Inicio compras**.

Estado: **Implementado** (pendiente de compilar/ajustar en el IDE).
Creados: la capa de datos (`movimientos_ventas_articulos.sql`), el modal
`inMtoModalImpMovVentasArt` (`.pas`/`.dfm` con plantilla FastReport y
`foto300`), la exportación a Excel (`inLibMovVentasArtExcel`), la entrada
de menú **Almacén → Informes → "Movimientos de ventas por artículos y
fechas"** y el registro en `fzam.dpr`/`fzam.dproj`. Falta aplicar el SQL a
las BBDD y refinar la maqueta en el diseñador.

---

## 1. Qué pide el usuario

> "Un informe nuevo en almacén: movimientos de ventas por artículos y
> fechas. Mismo formato de filtrado que el balance de almacén con tallas.
> Hay una fecha más: fecha de compras. El informe presenta dos márgenes:
> Margen 1 (margen de lo vendido) y Margen 2 (margen contando el stock
> actual como gasto)."

Decisiones confirmadas con el usuario:

| Tema           | Decisión                                                          |
|----------------|-------------------------------------------------------------------|
| Margen 1       | `BENEFICIO / IMP_VENTA * 100` (margen sobre LO VENDIDO)           |
| Margen 2       | `(IMP_VENTA − IMP_ENT_TOT) / IMP_VENTA * 100` (todo lo comprado como gasto) |
| Inicio compras | Restringe los artículos: solo los de **1ª compra ≥ esa fecha**    |
| Columnas       | Set completo de las fotos del legacy                              |
| Entregable     | SP + modal FastReport (con foto) + Excel + menú                  |

> **Por qué Margen 2 usa todo lo comprado y no el stock actual:** el stock
> no vendido = comprado − vendido. Restar el coste de TODO lo comprado
> (`IMP_ENT_TOT`) equivale a contar el stock actual (lo no vendido) como
> gasto, que es justo lo pedido ("el stock actual como gasto"). Además
> evita depender del stock vivo, que cambia tras la fecha del informe.

---

## 2. Fechas, origen de datos y columnas

### Fechas

- **Desde / Hasta**: periodo de **ventas** (por fecha de factura).
- **Inicio compras**: filtra QUÉ artículos salen — solo los que tienen su
  **primera compra** (movimiento de compra `AC`, entrada) igual o posterior
  a esta fecha. Como el filtro es sobre la primera compra, TODAS las
  compras del artículo caen dentro de la ventana, así que el total de
  entradas no necesita recorte adicional. En el modal es opcional (un check
  lo activa); desactivado = sin filtro (todos los artículos con actividad).

### Origen de datos

- **Entradas (compras)**: `fza_movimientos_almacen` con `TIPO_MOV='E'` y
  `TIPO_DOC_MOV='AC'`. Unidades = `SUM(CANTIDAD_MOV)`; coste =
  `SUM(TOTAL_COSTE_MOV)` (coste real capturado en la compra).
- **Ventas**: `fza_facturas_lineas` por fecha de factura. Uds =
  `SUM(CANTIDAD_FACLIN)`; importe = `SUM(TOTAL_FACLIN)` (venta real, con
  descuento y con IVA).
- **Coste de lo vendido**: `UDS_VENTA · PMP` (coste medio ponderado del
  stock actual; respaldo: último precio de compra del proveedor principal).
  Misma valoración que el balance de almacén.

### Columnas (una fila por artículo)

| Columna       | Fórmula                                                      |
|---------------|-------------------------------------------------------------|
| `UNI_ENT_TOT` | unidades compradas                                          |
| `IMP_ENT_TOT` | coste comprado (`SUM(TOTAL_COSTE_MOV)`)                     |
| `UDS_VENTA`   | unidades vendidas en el periodo                            |
| `IMP_VENTA`   | venta real (con dto, con IVA)                              |
| `IMP_COSTE`   | `UDS_VENTA · PMP` (coste de lo vendido)                    |
| `BENEFICIO`   | `IMP_VENTA − IMP_COSTE`                                    |
| `PCT_BNFCO`   | `BENEFICIO / IMP_COSTE · 100` (beneficio **sobre coste**)  |
| `VENTA_ENT`   | `IMP_VENTA − IMP_ENT_TOT` (venta menos lo comprado)       |
| `VENT_ENT`    | `VENTA_ENT / IMP_ENT_TOT · 100` (**sobre lo comprado**)    |
| `MARGEN1`     | `BENEFICIO / IMP_VENTA · 100` (margen de lo vendido)       |
| `MARGEN2`     | `VENTA_ENT / IMP_VENTA · 100` (todo lo comprado como gasto) |
| `PCT_VDTO`    | `UDS_VENTA / UNI_ENT_TOT · 100` (% unidades vendidas)      |
| `PCT_VLAST`   | `IMP_VENTA / IMP_ENT_TOT · 100` (% venta sobre compra)     |

> **CONFIRMAR**: las columnas auxiliares `VENT_ENT`, `PCT_VDTO` y
> `PCT_VLAST` (en las fotos: VentEnt%, % V.dto, % Vlast) se han definido con
> el criterio anterior — simétrico al bloque BENEFICIO/%Bnf/Margen1 — porque
> el legacy no documenta su fórmula exacta. Si el cliente las quiere de otra
> forma, se ajustan **solo en el SELECT final del SP** (un único sitio).

### Totales por grupo / general

Las magnitudes base (unidades e importes) **se suman**; los porcentajes y
márgenes **se recalculan** a partir de esas sumas (no se promedian ni se
suman porcentajes). En FastReport los porcentajes de los pies usan
`IIF(SUM(<base>)<>0, SUM(<num>)/SUM(<den>)*100, 0)`; en Excel se calculan en
código sobre las sumas acumuladas por grupo.

---

## 3. Contrato de datos: `PRC_GET_MOV_VENTAS_ART`

```
CALL PRC_GET_MOV_VENTAS_ART(
     p_DESDE,          -- inicio periodo de VENTAS (DATE)
     p_HASTA,          -- fin periodo de VENTAS (DATE)
     p_INICIO_COMPRAS, -- 1a compra del artículo >= esta fecha (NULL = sin filtro)
     p_ALMACENES,      -- CSV; '' = todos los activos
     p_FAMILIAS,       -- CSV; '' = todas (una padre incluye su descendencia)
     p_PROVEEDORES,    -- CSV; '' = todos
     p_TEMPORADAS,     -- CSV; '' = todas
     p_ARTICULOS,      -- CSV; '' = todos
     p_NIVEL1,         -- 1er nivel de agrupación: PRV/FAM/TMP/ALM/''
     p_NIVEL2,         -- 2o nivel
     p_NIVEL3,         -- 3er nivel
     p_NIVEL_FAM       -- nivel del árbol de familias al agrupar por FAM
);
```

Devuelve una fila por artículo (o artículo+almacén si algún nivel es `ALM`)
con las columnas de §2 más `CODIGO_ART_ART` (resolución de foto),
`DESCRIPCION_ART`, `CODIGO_FAM`/`DESCRIPCION_FAM`, `CODIGO_ALM`/`NOMBRE_ALM`,
`REF_PRV`, `COSTE_ART`, `PVP_ART` y `GRUPO1_COD/ETIQ`..`GRUPO3_COD/ETIQ`.
Las agrupaciones funcionan igual que en el balance (mismo CTE de familias,
mismo criterio PRV/FAM/TMP/ALM, resumen por corte de grupo). Idempotente:
`DROP` + `CREATE` del procedimiento, sin tocar esquema.

---

## 4. Formulario y maqueta

- `inMtoModalImpMovVentasArt` hereda de `TfrmPrintMultiFiltro` (mismas
  pestañas de filtro que el balance). Solo añade el control **Inicio
  compras** (check + fecha) sobre la pestaña Fechas y la pestaña
  **Agrupaciones** (`ALM`/`PRV`/`FAM`/`TMP` reordenables + nivel de familia).
- Maqueta FastReport (A4 apaisado): ReportTitle, PageHeader (cabecera de
  columnas), GroupHeader `G1/G2/G3` (agrupaciones, se ocultan los niveles
  inactivos en `ReportBeforePrint`), MasterData (una fila por artículo con
  `foto300` + las 13 columnas), GroupFooter `G3/G2/G1` y ReportSummary con
  los totales (sumas + porcentajes recalculados), PageFooter.
- **Foto**: un `TfrxPictureView` `foto300` en la MasterData; el base
  (`EngancharFotosEnReport`) la resuelve por `CODIGO_ART_ART`. El modal
  precarga las fotos en lote (sin N+1) y limpia la caché en el `destructor`.
- **Excel**: el botón Excel del base se redirige a
  `ExportarMovVentasArtExcel` (`inLibMovVentasArtExcel`), que vuelca el
  resultado del SP en una hoja `dxSpreadSheet` con el mismo layout y los
  mismos cortes de grupo, y lo muestra en `TfrmMtoPreviewExcel`.

---

## 5. Pendiente

1. Aplicar `movimientos_ventas_articulos.sql` a las BBDD existentes (crea el
   SP; no toca esquema). Idempotente.
2. Compilar `fzam.dproj` en el IDE y verificar el modal y la plantilla
   (posiciones de columnas en apaisado, cortes de grupo, ocultado de
   niveles inactivos). La plantilla se editó en el `.dfm` sin diseñador
   delante: conviene revisarla.
3. Confirmar las fórmulas de `VENT_ENT` / `PCT_VDTO` / `PCT_VLAST` (§2).
4. (Opcional) Gatear la entrada de menú por permisos, como el balance.

---

## 6. Archivos

- `movimientos_ventas_articulos.sql` — SP `PRC_GET_MOV_VENTAS_ART`
  (idempotente, no toca esquema).
- `movimientos_ventas_articulos.md` — este documento.
- `src/Modals/inMtoModalImpMovVentasArt.pas` / `.dfm` — modal de impresión
  (FastReport) con la plantilla y `foto300`; hereda de `TfrmPrintMultiFiltro`.
- `src/Lib/inLibMovVentasArtExcel.pas` — exportación a Excel.
- `src/Core/inMtoPrincipal.pas` / `.dfm` — entrada de menú Almacén →
  Informes → "Movimientos de ventas por artículos y fechas".
- `fzam.dpr` / `fzam.dproj` — registro de las unidades.
