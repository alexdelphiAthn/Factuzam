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
| Entre fechas · Simplificado  | Existencias iniciales · Entradas · Ventas · Existencias finales                            |
| Entre fechas · Desglosado    | Existencias iniciales · Ent. compra · Alb. entrada · Traspasos (neto) · Depósitos (neto) · Regulariz. · Alb. venta · Ventas · Existencias finales |
| Por acumulados               | Entradas · Ventas · Existencias finales                                                     |

> **Nota (revisión de bandas).** Se eliminó la banda **Salidas**: los
> traspasos se netean (entrada − salida) dentro de **Entradas** y los
> depósitos quedan fuera de la ecuación. En desglosado, `Ent. traspaso` y
> `Ent. depósito` pasan a ser **`Traspasos (neto)`** y **`Depósitos
> (neto)`**, y desaparecen `Sal. traspaso` / `Sal. depósito` (el `Alb.
> venta` sí se mantiene). Balance en todos los modos:
> `Ex.ini + Entradas − Ventas = Ex.final`.

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
| Existencias (ini/fin), Entradas| **Coste = PMP** (precio medio ponderado del stock actual; respaldo: último precio de compra del proveedor principal) |
| Alb. venta (SALALB, desglosado)| **PVP** (tarifa por defecto vigente hoy) — valoración nocional de la salida por albarán de venta |
| **Ventas (VEN)**               | **Precio REAL de venta** (con descuentos, con IVA = `TOTAL_FACLIN`) de `fza_facturas_lineas`, enlazado por SKU/almacén; **no** la tarifa |

`IMPORTE = CANTIDAD · PRECIO` por banda (salvo Ventas, que toma el importe
real facturado). La tarifa se pasa como parámetro (`p_COD_TARIFA`, por
defecto `PVP` vía `appTarifaDefecto`).

#### Totales: existencias finales + ventas

En las líneas de total (resumen por grupo y total general) **no se suman las
bandas** (no tendría sentido mezclar existencias + compras + ventas):

- **Cantidad / Importe** del total = **solo existencias finales** (uds + valor
  a PMP). El SP expone `EXIFIN_CANT` / `EXIFIN_IMP` (= cantidad/valor solo en
  la banda `EXIFIN`, 0 en el resto); el total los suma. Si se filtran las
  bandas y no se incluye existencias finales, el total sale 0.
- **Ventas** (columna aparte) = `VENTAS` del SP (importe real de venta, con
  IVA y descuento de `TOTAL_FACLIN`, solo en la banda `VEN`, 0 en el resto),
  acumulado. En Excel con `=SUM` en vivo; en FastReport con `SUM()`.

Los **totales por banda del artículo** (Excel) sí desglosan cada banda
(existencias, entradas, salidas, ventas) con su propio subtotal.

> Ventas reales por periodo: entre fechas se filtra por `FECHA_FAC`; en
> acumulados se suma el histórico de facturas. Las unidades de la banda
> Ventas siguen siendo las del movimiento; el importe sale de las líneas de
> factura (facturas/tickets VE/FC). Albaranes de venta no facturados no
> tienen precio de línea (no suman ingreso real).

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
     p_ARTICULOS,   -- CSV de códigos de artículo; '' = todos
     p_COD_TARIFA,  -- '' = 'PVP'
     p_DESGLOSADO,  -- 'S'/'N' (solo 'F')
     p_BANDAS,      -- CSV de códigos de banda; '' = todas
     p_NIVEL1,      -- 1er nivel de agrupación: PRV/FAM/TMP/ALM/'' (ver §3.1)
     p_NIVEL2,      -- 2º nivel de agrupación
     p_NIVEL3,      -- 3er nivel de agrupación
     p_NIVEL_FAM    -- nivel del árbol de familias al agrupar por FAM
);                  --   (1 = raíz; <1 o NULL = familia hoja del artículo)
```

`p_BANDAS` limita qué bandas salen (códigos `EXIINI`, `ENT`, `VEN`,
`EXIFIN` y, en desglosado, `ENTCMP`/`ENTALB`/`ENTTRA`/`ENTDEP`/`ENTREG`/
`SALALB`). Vacío = todas las de la configuración de modo/detalle. Se
aplica con un `DELETE` final sobre las bandas no elegidas.

Todos los filtros multi-valor son CSV y se resuelven con `FIND_IN_SET`. Las
familias se expanden a su descendencia con un CTE recursivo sobre
`CODIGO_PADRE_FAM` (elegir una padre arrastra sus hijas). Proveedores filtra
por `fza_articulos_proveedores`; temporadas por la propiedad de artículo
`TEMPORADA` (`fza_articulos_propiedades` → `fza_propiedades_valores.PV`).
**Artículos** (`p_ARTICULOS`) restringe el informe a una lista concreta de
códigos de artículo (`FIND_IN_SET` sobre `CODIGO_ART_ART`).

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
| `CODIGO_ALM`,`NOMBRE_ALM`       | Almacén (solo informativo si no se agrupa por ALM) |
| `GRUPO1_COD`,`GRUPO1_ETIQ` … `GRUPO3_*` | Agrupaciones configurables (ver §3.1)      |

Orden de salida: `GRUPO1_COD, GRUPO2_COD, GRUPO3_COD, ORDEN_FAM, CODIGO_FAM,
CODIGO_ART_ART, ORDEN_COLOR, COLOR, ORDEN_BANDA`.

---

## 3.1 Agrupaciones con resumen por grupo

`p_NIVEL1/2/3` definen una **jerarquía de agrupación** configurable y
**reordenable**, con una **línea de resumen (grand total) por grupo**. Cada
nivel puede ser:

| Código | Agrupa por                                                        |
|--------|-------------------------------------------------------------------|
| `PRV`  | Proveedor principal del artículo (`fza_articulos_proveedores`)    |
| `FAM`  | Familia (al nivel del árbol que indique `p_NIVEL_FAM`)            |
| `TMP`  | Temporada (propiedad `TEMPORADA`)                                |
| `ALM`  | Almacén                                                           |
| `''`   | Nivel inactivo                                                    |

El **orden importa**: `NIVEL1` es el grupo más externo. Ej. `PRV,FAM` agrupa
por proveedor y, dentro de cada proveedor, por familia; el nivel de artículo
queda siempre al final (el detalle). El SP añade `GRUPOn_COD` (para el corte
y el orden) y `GRUPOn_ETIQ` (etiqueta "Proveedor: …" / "Familia: …" / etc.) y
**ordena** por los `GRUPOn_COD`. Los niveles inactivos devuelven `''` en
ambas columnas y el cliente no dibuja banda a ese nivel.

- **Resumen por grupo**: una sola línea por corte de grupo con la **suma de
  cantidad e importe de todas las filas** del grupo (el "grand total"). En
  FastReport son `SUM()` con reinicio por grupo; en Excel son `=SUM()` en
  vivo sobre las filas de detalle. Nota: al sumar todas las bandas, la cifra
  es un total bruto; si se quiere el total de una sola banda (p. ej. solo
  existencias finales), filtrar por esa banda en la pestaña Bandas.
- **Nivel de familia** (`p_NIVEL_FAM`): si el árbol de familias tiene
  padres-hijos, permite agrupar por la familia **raíz** (1), un nivel
  intermedio (2, 3…) o la familia **hoja** del artículo (<1 / NULL). Se
  resuelve construyendo el camino raíz→familia con un CTE recursivo y
  tomando el código del nivel pedido (`tmp_bat_fam_grp`).
- **Grano por almacén**: si **algún** nivel es `ALM`, los cálculos (stock y
  movimientos) se **desglosan por almacén** (`tmp_bat_base` lleva
  `CODIGO_ALM`). Si **no** se agrupa por almacén, se agregan todos los
  almacenes filtrados en uno (comportamiento clásico). El desglose se hace
  con un `UNION ALL` de stock + movimientos por `(unidad, almacén)`.

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
ReportTitle       "Balance de almacén por tallas"  + filtros (fechas/almacén)
GroupHeader[G1]   [GRUPO1_ETIQ]            (Condition = GRUPO1_COD)
GroupHeader[G2]     [GRUPO2_ETIQ]          (Condition = GRUPO2_COD)
GroupHeader[G3]       [GRUPO3_ETIQ]        (Condition = GRUPO3_COD)
GroupHeader[FAM]  FAMILIA  <CODIGO_FAM>  <DESCRIPCION_FAM>
GroupHeader[ART]  ARTÍCULO <CODIGO_ART_ART> <DESCRIPCION_ART> <REF_PRV>
                  + cabecera de tallas: [ETIQ_T01]..[ETIQ_T14]  Cdad Precio Importe
                  + PictureView "foto300"   (foto del artículo, automática)
MasterData[BANDA] [ETIQUETA_BANDA] [COLOR] [T01]..[T14] [CANTIDAD] [PRECIO] [IMPORTE]
GroupFooter[ART]  (vacío, alto 2; estructural, ver abajo)
GroupFooter[FAM]  (vacío, alto 2; estructural)
GroupFooter[G3]   TOT. [GRUPO3_ETIQ]   SUM(CANTIDAD)  SUM(IMPORTE)
GroupFooter[G2]   TOT. [GRUPO2_ETIQ]   SUM(CANTIDAD)  SUM(IMPORTE)
GroupFooter[G1]   TOT. [GRUPO1_ETIQ]   SUM(CANTIDAD)  SUM(IMPORTE)
PageFooter        Página x de y  ·  Impreso el …
```

Notas de implementación de las agrupaciones en FastReport:

- Las bandas `G1/G2/G3` (cabecera y pie) existen siempre en la plantilla; los
  niveles **inactivos** se ocultan en runtime: `TfrmPrintBalanceTallas`
  engancha `frxrprt1.OnBeforePrint` con un handler que (a) encadena el refresco
  de la foto del base (`oFotos.HandlerReportBeforePrint`) y (b) pone
  `Visible := (GRUPOn_ETIQ <> '')` en cada banda `GroupHeaderG#/GroupFooterG#`.
- Los `SUM()` de los pies se reinician por grupo automáticamente (agregado en
  GroupFooter).
- **La familia NO agrupa por sí sola**: el handler oculta siempre
  `GroupHeaderFam`/`GroupFooterFam` (`Visible := False`). Solo se agrupa por
  familia si se elige FAM en la pestaña Agrupaciones (sale como "Familia: …").
  El árbol de grupos de FastReport mantiene la familia como nivel (sigue
  ordenando), pero invisible.
- **Pies estructurales ART/FAM**: FastReport empareja los GroupFooter con los
  GroupHeader por anidamiento, de dentro hacia fuera. Como los grupos (de fuera
  a dentro) son G1, G2, G3, FAM, ART, para que los pies de G3/G2/G1 emparejen
  con su grupo hace falta que existan también los pies de ART y FAM (si no, los
  3 pies caerían sobre ART/FAM/G3). Por eso hay un `GroupFooterArt` y un
  `GroupFooterFam` vacíos (alto 2) antes de los de grupo. Cuando se añadan los
  subtotales por banda del artículo (TOT.ART, §7) se rellenará el pie de ART.
- **Verificar en el diseñador**: estas bandas se añadieron editando la
  plantilla `.dfm` sin diseñador delante; conviene abrir el informe y
  comprobar posiciones, el emparejado de pies y el corte de grupos.

Notas de plantilla:

- **Foto**: basta un `TfrxPictureView` llamado **`foto300`** en el
  GroupHeader de artículo. `TfrmPrint.AfterReportLoaded` engancha
  `EngancharFotosEnReport` (`inLibFotos`), que en cada iteración resuelve
  la foto leyendo `CODIGO_ART_ART` de la banda. Sin código extra. (Usar
  `foto600` o `fotoReal` para más resolución.)
  - **Sin N+1**: `AfterReportLoaded` del modal llama a
    `oFotos.PrecargarFotosLote` con los códigos del resultado (UNA consulta);
    `oFotos.Resolver(art, '')` toma la foto de esa caché y no hace un `SELECT`
    por artículo. El modal vacía la caché en su `destructor`
    (`oFotos.LimpiarPrecargaFotos`).
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
- **Almacenes**, **Familias**, **Proveedores**, **Temporadas**, **Artículos**:
  un `TcxCheckListBox` de multi-selección cada una, **con cuadro de búsqueda**
  encima (filtra las filas visibles; las marcas se conservan aunque la
  búsqueda las oculte, porque el código marcado se guarda aparte). Convención:
  sin nada marcado = todos. `EditValueFormat = cvfStatesString` para no topar
  en 64 ítems. **Proveedores** lista solo los que tienen artículos.

Expone a los descendientes: `CSVAlmacenes`, `CSVFamilias`, `CSVProveedores`,
`CSVTemporadas`, `CSVArticulos`, `FechaDesde`, `FechaHasta`, y (protegido)
`TabFechas` / `DteDesde` / `DteHasta` para añadir controles propios.

- **Agrupaciones** (reutilizable): `CrearTabAgrupacion(caption, codigos,
  etiquetas, conNivelFamilia)` crea una pestaña con un checklist de
  dimensiones **reordenable** (botones Subir/Bajar) y, opcional, un spin de
  **nivel de familia**. `NivelesAgrupacion` devuelve los códigos marcados en
  el orden elegido (el 1º = grupo más externo); `NivelFamilia` da el valor del
  spin. Pensado para que cualquier informo de este estilo añada agrupaciones
  sin recodificar la mecánica.

La UI se crea por código (no por DFM) a propósito: los informes que hereden
no rehacen la herencia visual, solo añaden su informe y, si procede,
controles sobre la pestaña Fechas. Es la pieza pensada para "más informes de
este estilo".

### 6.2 Modal `inMtoModalImpBalanceTallas`

Hereda de `TfrmPrintMultiFiltro`. Solo aporta:

- `FiltrosUsados` = las seis pestañas (incluida la nueva de Artículos).
- Los radios **Modo** (Entre fechas / Por acumulados) y **Detalle**
  (Simplificado / Desglosado), creados por código sobre `TabFechas`; en
  acumulados se inhabilitan fechas y detalle.
- Una pestaña **Bandas** (vía `CrearTabChecklist` del base) con las bandas
  que se pueden mostrar; se rellena según modo/detalle (las bandas cambian)
  y se refresca al cambiarlos. Sin marcar nada = todas. Se pasa como
  `p_BANDAS`.
- Una pestaña **Agrupaciones** (vía `CrearTabAgrupacion` del base) con las
  dimensiones `ALM`/`PRV`/`FAM`/`TMP` reordenables + spin de nivel de familia.
  Se mapea a `p_NIVEL1/2/3` (códigos marcados en orden) y `p_NIVEL_FAM`.
- `preparar_consulta`: arma el `CALL PRC_GET_BALANCE_ALMACEN_TALLAS(...)` con
  los cinco CSV del base + fechas + modo/detalle + bandas + agrupaciones.
- `AfterReportLoaded`: además de enlazar el dataset, sustituye
  `frxrprt1.OnBeforePrint` por `ReportBeforePrint` (fotos + ocultar niveles
  de grupo inactivos, ver §5).
- `AfterReportLoaded`: enlaza `fxdsBalance.DataSet := unqryBalancePrint` (la
  foto necesita el `DataSet` directo, ver §5) y registra el dataset.
- En su `.dfm`: la plantilla FastReport (con `foto300`) + `unqryBalancePrint`
  + `fxdsBalance`. Sin controles de filtro (los pone el base).
- **Excel**: redirige el botón Excel del base (que exporta el FastReport a
  XLSX, farragoso) a una exportación propia `ExportarBalanceTallasExcel`
  (`inLibBalanceTallasExcel`), que vuelca el resultado del SP en una hoja
  `dxSpreadSheet` con el mismo layout que el informe (familia → artículo →
  tallas en columnas → bandas en filas) y la muestra en `TfrmMtoPreviewExcel`
  para guardar a `.xlsx`. Al cerrar cada artículo emite una fila **TOTAL por
  banda** con **fórmulas** `=SUM(...)` sobre las filas de detalle
  (recalculables, no números fijos). Además **incrusta la foto 300px** del
  artículo, anclada a la celda del artículo (ancho de columna fijo y alto de fila según el aspecto, para no deformar), vía
  `Sheet.Containers.Add(TdxSpreadSheetPictureContainer)` + `Picture.Image`
  (un `TdxSmartImage` de `dxSmartImage` / `dxGDIPlusClasses`). Como usa el dataset del SP ya
  filtrado, respeta el filtrado de bandas (y de almacenes/familias/
  proveedores/temporadas). Si hay **agrupaciones**, dibuja una **cabecera**
  por grupo (`GRUPOn_ETIQ`, sangrada por nivel) y una **línea de resumen**
  (TOTAL del grupo con `=SUM()` de cantidad e importe sobre las filas de
  detalle del grupo), con el mismo corte que el informe.

> En el `.dfm` de `inMtoModalImpBalanceTallas` se deja un `CALL` de diseño
> con literales (14 argumentos) en el `SQL.Text` de `unqryBalancePrint` para
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
3. Verificar en el diseñador FastReport las bandas de grupo nuevas
   (`G1/G2/G3` cabecera y pie) y el ocultado de niveles inactivos
   (`ReportBeforePrint`): el alta de bandas se hizo editando la plantilla
   embebida en el `.dfm` sin compilador/diseñador delante, así que conviene
   abrir el informe y revisar posiciones, anchos y el corte de grupos.
   (Opcional) subtotales por banda dentro del artículo (TOT.ART) y swatch de
   color con `COLOR_HEX`.
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
