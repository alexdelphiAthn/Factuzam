# Balance de almacén por tallas (informe horizontal con foto)

Informe horizontal (A4 apaisado) que reproduce el "Balance de almacén
por tallas" de OdaGest+ (ver mock `balance_almacen_con_tallas_oda.pdf`),
añadiendo la **foto** del artículo. Agrupado por familia → artículo, con
las tallas como columnas y los colores/estados como bandas (filas).

Estado: **Implementado** (pendiente de compilar/ajustar en el IDE). Están
creados: la capa de datos (`balance_almacen_tallas.sql`), el modal
`inMtoModalImpBalanceTallas` (`.pas`/`.dfm` con plantilla FastReport y el
`TfrxPictureView` `foto300`), la entrada de menú **Almacén → Informes →
"Balance de Almacén Horizontal"** y el registro en `fzam.dpr`/`fzam.dproj`.
Falta aplicar el SQL a las BBDD y, opcionalmente, refinar la maqueta en el
diseñador (ver §7).

---

## 1. Qué pide el usuario

> "Un balance de almacén con tallas en horizontal con foto. Entre fechas
> o por acumulados. Si es entre fechas las bandas son Existencias
> iniciales, Entradas, Salidas, Ventas, Existencias finales (modo
> simplificado). Consultar la pantalla de Control + U para el modo
> desglosado. Si es por acumulados sale sólo Entradas, Salidas, Ventas,
> Existencias finales."

Dos ejes de configuración:

| Eje              | Valores                                                       |
|------------------|---------------------------------------------------------------|
| **Modo**         | `F` entre fechas · `A` por acumulados                         |
| **Detalle** (`F`)| Simplificado · Desglosado (subtipos de la consulta Ctrl+U)    |

### Bandas por configuración

| Configuración                | Bandas (de arriba a abajo)                                                                 |
|------------------------------|--------------------------------------------------------------------------------------------|
| Entre fechas · Simplificado  | Existencias iniciales · Entradas · Salidas · Ventas · Existencias finales                  |
| Entre fechas · Desglosado    | Existencias iniciales · Ent. compra · Alb. entrada · Ent. traspaso · Ent. depósito · Regulariz. · Sal. traspaso · Sal. depósito · Alb. venta · Ventas · Existencias finales |
| Por acumulados               | Entradas · Salidas · Ventas · Existencias finales                                          |

El modo **desglosado** reutiliza exactamente los subtipos de
`TfrmStockConsulta` (Ctrl+U, `inMtoStockConsulta.pas`): compra (`AC`),
albarán de entrada (`AE`), traspaso (`TR`/`AT`), depósito (`DP`),
regularización (`IN`), albarán de venta (`AV`) y venta (`VE`/`FC`).

Por acumulados no hay "existencias iniciales": el acumulado de
`fza_articulos_stockactual` es "desde siempre".

---

## 2. Origen de datos y valoración

- **Modo `A` (acumulados)**: lee los acumulados denormalizados de
  `fza_articulos_stockactual` (`CANTIDAD_ENT_*_STK` / `CANTIDAD_SAL_*_STK`,
  ver `stocks_acumulados.sql`) y `CANTIDAD_STK` para las existencias
  finales.
- **Modo `F` (entre fechas)**: agrega `fza_movimientos_almacen` del
  periodo (`DATE(FECHA_MOV) BETWEEN desde AND hasta`, `ESACTIVO_MOV='S'`).
  Las existencias a una fecha se **reconstruyen** partiendo del stock
  actual y restando los movimientos firmados posteriores a esa fecha:
  - `EXI_INI = CANTIDAD_STK_hoy − Σ(signo·cantidad)` de movimientos con
    `FECHA_MOV >= desde`.
  - `EXI_FIN = CANTIDAD_STK_hoy − Σ(signo·cantidad)` de movimientos con
    `FECHA_MOV > hasta`.
  - signo = `+1` si `TIPO_MOV='E'`, `−1` si `TIPO_MOV='S'`.

  Esto es exacto siempre que **todo** cambio de stock pase por
  `fza_movimientos_almacen` (es la vía oficial; ver
  `stocks_sps_movimientos.sql`).

- **Ventas**: entre fechas = salidas con `TIPO_DOC_MOV IN ('VE','FC','AV')`.
  En desglosado, la banda "Ventas" es solo `VE`/`FC` y `AV` va aparte
  como "Alb. venta" (igual que Ctrl+U). En acumulados, ventas =
  `CANTIDAD_SAL_VENTA_STK + CANTIDAD_SAL_ALBVENTA_STK`.

### Valoración (columnas Precio / Importe)

| Banda                          | Precio unitario        |
|--------------------------------|------------------------|
| Existencias (ini/fin), Entradas| **Coste** (precio medio ponderado del stock actual; respaldo: último precio de compra del proveedor principal) |
| Salidas, Ventas                | **PVP** (tarifa por defecto vigente hoy) |

`IMPORTE = CANTIDAD · PRECIO` por banda. Coincide con el mock: ent. a
coste (12,00), sal./ventas a PVP (39,95). La tarifa se pasa como
parámetro (`p_COD_TARIFA`, por defecto `PVP` vía `appTarifaDefecto`).

> Simplificación asumida: las entradas y existencias se valoran al coste
> medio **actual** del artículo, no al coste histórico de cada
> movimiento. Si se quisiera el coste exacto del periodo habría que
> arrastrar `TOTAL_COSTE_MOV` por banda (ampliación futura).

---

## 3. Contrato de datos: `PRC_GET_BALANCE_ALMACEN_TALLAS`

```
CALL PRC_GET_BALANCE_ALMACEN_TALLAS(
     p_MODO,        -- 'F' entre fechas | 'A' acumulados
     p_DESDE,       -- DATE inclusive (solo 'F')
     p_HASTA,       -- DATE inclusive (solo 'F')
     p_ALMACENES,   -- CSV "01,50" o '' = todos los almacenes activos
     p_FAMILIAS,    -- CSV; '' = todas. Una familia padre incluye sus hijas
     p_PROVEEDORES, -- CSV de códigos de proveedor; '' = todos
     p_TEMPORADAS,  -- CSV de valores de temporada; '' = todas
     p_COD_TARIFA,  -- '' = 'PVP'
     p_DESGLOSADO,  -- 'S'/'N' (solo 'F')
     p_BANDAS       -- CSV de códigos de banda; '' = todas
);
```

`p_BANDAS` limita qué bandas salen (códigos `EXIINI`, `ENT`, `SAL`, `VEN`,
`EXIFIN` y, en desglosado, `ENTCMP`/`ENTALB`/`ENTTRA`/`ENTDEP`/`ENTREG`/
`SALTRA`/`SALDEP`/`SALALB`). Vacío = todas las de la configuración de
modo/detalle. Se aplica con un `DELETE` final sobre las bandas no elegidas.

Todos los filtros multi-valor son CSV y se resuelven con `FIND_IN_SET`. Las
familias se expanden a su descendencia con un CTE recursivo sobre
`CODIGO_PADRE_FAM` (elegir una padre arrastra sus hijas). Proveedores filtra
por `fza_articulos_proveedores`; temporadas por la propiedad de artículo
`TEMPORADA` (`fza_articulos_propiedades` → `fza_propiedades_valores.PV`).

Devuelve **una fila por (artículo, color, banda)**, ya pivotada por talla.
Columnas del resultado (las consume el `TfrxDBDataset` del informe):

| Columna                         | Uso en el informe                                  |
|---------------------------------|----------------------------------------------------|
| `ORDEN_FAM`,`CODIGO_FAM`,`DESCRIPCION_FAM` | Grupo de familia                        |
| `CODIGO_ART_ART`                | Grupo de artículo **y resolución de foto** (nombre canónico que `EngancharFotosEnReport` reconoce) |
| `DESCRIPCION_ART`,`REF_PRV`     | Cabecera del artículo                              |
| `COSTE_ART`,`PVP_ART`           | Informativos (coste / PVP del artículo)            |
| `ORDEN_COLOR`,`COLOR`,`COLOR_HEX`| Etiqueta de color de la banda (+ swatch opcional) |
| `ORDEN_BANDA`,`BANDA`,`ETIQUETA_BANDA`,`ES_COSTE` | Identidad y orden de la banda     |
| `ETIQ_T01..ETIQ_T14`            | Rótulos de cabecera de talla (XS, S, M… / 34, 36…) |
| `T01..T14`                      | Cantidades por talla (posicional, ver §4)          |
| `CANTIDAD`,`PRECIO`,`IMPORTE`   | Totales de la banda (Cdad. / Precio / Importe)     |

Orden de salida: `ORDEN_FAM, CODIGO_FAM, CODIGO_ART_ART, ORDEN_COLOR,
COLOR, ORDEN_BANDA`.

---

## 4. Pivote posicional de tallas (T01..T14)

Igual criterio que `vi_compras_sesiones_lin_print` y
`TfrmStockConsulta.TallasArticulo`:

1. Cada artículo tiene un **conjunto pivote** = el atributo no-color
   asignado en `fza_articulos_conjuntos_asign` (`ID_VA_ACA <> 'CO'`).
2. Las tallas del conjunto (`fza_atributos_conjuntos_det`, orden
   `ORDEN_ACD`) ocupan las posiciones **1..14** (`ROW_NUMBER()`).
3. Respaldo para artículos sin asignación: tallas presentes en sus SKUs,
   ordenadas por `ORDEN_AV`.
4. Cada SKU se mapea a su posición por la talla; las cantidades caen en
   `T01..T14` con `SUM(CASE WHEN POSICION=k …)`.

Límite: **14 tallas** por artículo (cubre el tallaje numérico 34–60 y el
alfa XS–5XL del mock). Si un conjunto tuviera más, las sobrantes no se
muestran (igual que la rejilla fija de OdaGest).

El rótulo de cada columna (`ETIQ_T0x`) viaja en cada fila para que la
cabecera del grupo de artículo lo pinte (el tallaje cambia por artículo).

---

## 5. Maqueta del informe (estructura de bandas FastReport)

```
ReportTitle      "Balance de almacén por tallas"  + filtros (fechas/almacén)
GroupHeader[FAM] FAMILIA  <CODIGO_FAM>  <DESCRIPCION_FAM>
GroupHeader[ART] ARTÍCULO <CODIGO_ART_ART> <DESCRIPCION_ART> <REF_PRV>
                 + cabecera de tallas: [ETIQ_T01]..[ETIQ_T14]  Cdad Precio Importe
                 + PictureView "foto300"   (foto del artículo, automática)
MasterData[BANDA] [ETIQUETA_BANDA] [COLOR] [T01]..[T14] [CANTIDAD] [PRECIO] [IMPORTE]
GroupFooter[ART] TOT.ART por banda: SUM([T01])..SUM([T14]) agrupado por BANDA
GroupFooter[FAM] TOT.NIV. <familia>
ReportSummary    TOT.GRP.
```

Notas de plantilla:

- **Foto**: basta un `TfrxPictureView` llamado **`foto300`** en el
  GroupHeader de artículo. `TfrmPrint.AfterReportLoaded` engancha
  `EngancharFotosEnReport` (`inLibFotos`), que en cada iteración resuelve
  la foto leyendo `CODIGO_ART_ART` de la banda. Sin código extra. (Usar
  `foto600` o `fotoReal` para más resolución.)
- **Cabecera de tallas por artículo**: como el tallaje cambia por
  artículo, los rótulos `[ETIQ_T01]..[ETIQ_T14]` van en el GroupHeader de
  artículo (no en PageHeader).
- **Subtotales por banda** (las filas `ent./sal./ex.fin.` sin color del
  mock): en el GroupFooter de artículo, una fila por banda con
  `SUM(<DS>."T01")…` Se consigue con un GroupFooter agrupado también por
  `BANDA`, o con memos de agregado condicionados por `ORDEN_BANDA`.
- **Swatch de color**: opcional, usar `COLOR_HEX` para pintar un
  cuadradito (igual que la leyenda de Ctrl+U).
- El informe base se diseña en el IDE (FastReport) y queda **embebido en
  el `.dfm`** como `frxReportOrigen` (mismo patrón que
  `inMtoModalEtiqArt.dfm`, que ya lleva un `foto300`). Los formatos
  propios del usuario se guardan como BLOB en `fza_usuarios_perfiles`.

---

## 6. Formulario base `TfrmPrintMultiFiltro` + modal del balance

### 6.1 Base reutilizable `inMtoModalImpMultiFiltro`

`TfrmPrintMultiFiltro` hereda de `TfrmPrint` y, al mostrarse, construye **por
código** un `TcxPageControl` con una pestaña por filtro, según el conjunto
que devuelva `FiltrosUsados` (por defecto todas):

- **Fechas**: rango desde / hasta.
- **Almacenes**, **Familias**, **Proveedores**, **Temporadas**: un
  `TcxCheckListBox` de multi-selección cada una. Convención: sin nada
  marcado = todos.

Expone a los descendientes: `CSVAlmacenes`, `CSVFamilias`, `CSVProveedores`,
`CSVTemporadas`, `FechaDesde`, `FechaHasta`, y (protegido) `TabFechas` /
`DteDesde` / `DteHasta` para añadir controles propios.

La UI se crea por código (no por DFM) a propósito: los informes que hereden
no rehacen la herencia visual, solo añaden su informe y, si procede,
controles sobre la pestaña Fechas. Es la pieza pensada para "más informes de
este estilo".

### 6.2 Modal `inMtoModalImpBalanceTallas`

Hereda de `TfrmPrintMultiFiltro`. Solo aporta:

- `FiltrosUsados` = las cinco pestañas.
- Los radios **Modo** (Entre fechas / Por acumulados) y **Detalle**
  (Simplificado / Desglosado), creados por código sobre `TabFechas`; en
  acumulados se inhabilitan fechas y detalle.
- Una pestaña **Bandas** (vía `CrearTabChecklist` del base) con las bandas
  que se pueden mostrar; se rellena según modo/detalle (las bandas cambian)
  y se refresca al cambiarlos. Sin marcar nada = todas. Se pasa como
  `p_BANDAS`.
- `preparar_consulta`: arma el `CALL PRC_GET_BALANCE_ALMACEN_TALLAS(...)` con
  los cuatro CSV del base + fechas + modo/detalle.
- `AfterReportLoaded`: enlaza `fxdsBalance.DataSet := unqryBalancePrint` (la
  foto necesita el `DataSet` directo, ver §5) y registra el dataset.
- En su `.dfm`: la plantilla FastReport (con `foto300`) + `unqryBalancePrint`
  + `fxdsBalance`. Sin controles de filtro (los pone el base).
- **Excel**: redirige el botón Excel del base (que exporta el FastReport a
  XLSX, farragoso) a una exportación propia `ExportarBalanceTallasExcel`
  (`inLibBalanceTallasExcel`), que vuelca el resultado del SP en una hoja
  `dxSpreadSheet` con el mismo layout que el informe (familia → artículo →
  tallas en columnas → bandas en filas) y la muestra en `TfrmMtoPreviewExcel`
  para guardar a `.xlsx`.

> En el `.dfm` de `inMtoModalImpBalanceTallas` se deja un `CALL` de diseño
> con literales (9 argumentos) en el `SQL.Text` de `unqryBalancePrint` para
> que el diseñador FastReport vea los campos; `preparar_consulta` lo
> sustituye en runtime por la versión con parámetros.

---

## 7. Pendiente

Ya hecho: SP, modal `inMtoModalImpBalanceTallas` (`.pas`/`.dfm` con
plantilla y `foto300`), entrada de menú Almacén → Informes, registro en
`fzam.dpr`/`fzam.dproj` y el fallback en
`inLibFotos.ObtenerDataSetDeBandaPadre` para que la foto se resuelva en
cabeceras de grupo (no solo en bandas de datos). El selector de almacén
admite uno o varios (lista CSV; el SP filtra con `FIND_IN_SET`).

Queda:

1. Aplicar `balance_almacen_tallas.sql` a las BBDD existentes (crea el SP;
   no toca esquema). Idempotente.
2. Compilar `fzam.dproj` en el IDE y verificar el modal y la plantilla.
3. (Opcional) Refinar la maqueta en el diseñador FastReport: subtotales
   por banda (TOT.ART), TOT.NIV. por familia, swatch de color con
   `COLOR_HEX` y ajuste fino de anchos de columna.
4. (Opcional) Gatear por permisos: la entrada de menú se lanza directa
   (siempre visible). Si se quiere ocultar por permiso, registrar el ítem
   en el sistema de ventanas (`oFzaWinf`) o añadir un `TienePermiso` en
   `mnuBalanceAlmacenHorizontalClick`.
5. Verificar que los SPs de reversión decrementan los acumulados (ya
   anotado como pendiente en `stocks_acumulados.md`) para que el modo
   acumulados cuadre con el de fechas.

---

## 8. Archivos

- `balance_almacen_tallas.sql` — SP `PRC_GET_BALANCE_ALMACEN_TALLAS`
  (idempotente, no toca esquema).
- `balance_almacen_tallas.md` — este documento.
- `src/Modals/inMtoModalImpMultiFiltro.pas` / `.dfm` — formulario BASE
  reutilizable con las pestañas de filtros múltiples (almacenes, familias,
  proveedores, temporadas, fechas) construidas por código.
- `src/Modals/inMtoModalImpBalanceTallas.pas` / `.dfm` — modal de
  impresión (FastReport) con la plantilla base y `foto300`; hereda del base.
- `src/Lib/inLibBalanceTallasExcel.pas` — exportación a Excel
  (`dxSpreadSheet`) con el mismo layout que el informe; la lanza el botón
  Excel del modal a través de `TfrmMtoPreviewExcel`.
- `src/Core/inMtoPrincipal.pas` / `.dfm` — entrada de menú Almacén →
  Informes → "Balance de Almacén Horizontal".
- `src/Lib/inLibFotos.pas` — fallback de foto en cabeceras de grupo.
- `fzam.dpr` / `fzam.dproj` — registro de la unidad.
- Mock de referencia: `balance_almacen_con_tallas_oda.pdf` (OdaGest+).
