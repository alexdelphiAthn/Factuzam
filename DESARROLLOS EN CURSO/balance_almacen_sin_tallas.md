# Balance de almacén sin tallas (informe vertical con foto)

Variante **vertical** del balance por tallas (ver
`balance_almacen_tallas.md`). Muestra lo mismo —existencias, entradas,
salidas, ventas, existencias finales, con valoración— pero **sin pivotar
por talla**: una fila por **(artículo, color, banda)** con columnas
Concepto / Color / Cantidad / Precio / Importe. Mantiene la **foto** del
artículo (hueco a la derecha de la cabecera de artículo).

Motivo: el informe horizontal solo incluye artículos "tallables" (con
conjunto pivote de tallas o tallas en sus SKUs); un artículo sin tallas no
se puede pintar en horizontal y queda fuera. Este informe **cubre todo el
catálogo**.

Estado: **Implementado** (pendiente de compilar/ajustar en el IDE). Rama
de desarrollo separada: `claude/balance-almacen-sin-tallas` (parte de
`claude/inspiring-carson-i3tZS` porque reutiliza la pestaña de
Agrupaciones del formulario base).

---

## 1. Qué reutiliza del balance por tallas

Todo el "armazón" es común (mismo formulario base `TfrmPrintMultiFiltro`):

- **Filtros** en pestañas: almacén, familias (padre→hijas), proveedor,
  temporada (todos multi-selección con buscador), y fechas.
- **Modos**: entre fechas (`F`) / por acumulados (`A`); **detalle**
  simplificado / desglosado (subtipos Ctrl+U).
- **Bandas**: pestaña para elegir qué bandas salen.
- **Agrupaciones**: pestaña reordenable (Almacén / Proveedor / Familia /
  Temporada) + nivel de familia, con **resumen (grand total) por grupo**
  (suma de cantidad e importe de todas las filas del grupo).
- **Valoración**: entradas/existencias (ini/fin) a **PMP**; salidas a PVP;
  **ventas al precio REAL** (con descuentos, con IVA) de `fza_facturas_lineas`.
- **Ganancia** (margen) en las líneas de total (resumen por grupo + total
  general): `ventas reales − uds. facturadas · PMP`. Ver
  `balance_almacen_tallas.md §2`.
- **Excel** y **FastReport**, con foto y ocultado de niveles de grupo
  inactivos (mismo `ReportBeforePrint` que el horizontal).

La diferencia está solo en el **grano** y el **layout**: aquí no hay
posición/columna de talla; se agrupa por (artículo, color) y se listan las
bandas como filas.

---

## 2. Diferencias con el balance por tallas

| Aspecto              | Por tallas (horizontal)            | Sin tallas (vertical)                 |
|----------------------|------------------------------------|---------------------------------------|
| Orientación          | A4 apaisado                        | A4 vertical                           |
| Grano                | (artículo, color, talla, banda)    | (artículo, color, banda)              |
| Columnas de medida   | T01..T14 + Cdad/Precio/Importe     | Cantidad / Precio / Importe           |
| Artículos incluidos  | Solo tallables                     | **Todos** (con cualquier SKU)         |
| SP                   | `PRC_GET_BALANCE_ALMACEN_TALLAS`   | `PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`  |
| Filas a cero         | Se muestran                        | Se **descartan** (artículo+color sin existencias ni movimientos), para no inundar con catálogo inactivo |

El SP sin tallas es el mismo cálculo de medidas (acumulados / reconstrucción
entre fechas con `UNION ALL` de stock + movimientos por unidad/almacén) pero
agrupando por `(artículo, almacén, color)` en vez de añadir la posición de
talla. Salida: las mismas columnas que el horizontal **menos** `T01..T14` y
`ETIQ_T*`, más `GRUPO1..3_COD/ETIQ`, `CODIGO_ALM`, `NOMBRE_ALM` y la foto vía
`CODIGO_ART_ART`.

---

## 3. Contrato del SP

Parámetros **idénticos** a `PRC_GET_BALANCE_ALMACEN_TALLAS` (14): `p_MODO,
p_DESDE, p_HASTA, p_ALMACENES, p_FAMILIAS, p_PROVEEDORES, p_TEMPORADAS,
p_COD_TARIFA, p_DESGLOSADO, p_BANDAS, p_NIVEL1, p_NIVEL2, p_NIVEL3,
p_NIVEL_FAM`. Ver `balance_almacen_tallas.md §3 / §3.1` para el detalle de
filtros, bandas y agrupaciones.

Salida: una fila por (artículo, color, banda) con `CANTIDAD`, `PRECIO`,
`IMPORTE` (sin columnas de talla).

---

## 4. Maqueta FastReport (vertical)

```
ReportTitle       "Balance de almacén sin tallas"
GroupHeader[G1/2/3]  [GRUPOn_ETIQ]                (niveles de agrupación)
GroupHeader[FAM]  FAMILIA <CODIGO_FAM> <DESCRIPCION_FAM>
GroupHeader[ART]  ARTÍCULO <cod> <desc> <REF_PRV>  + foto300 (hueco dcha.)
                  cabecera: Concepto | Color | Cantidad | Precio | Importe
MasterData[BANDA] [ETIQUETA_BANDA] [COLOR] [CANTIDAD] [PRECIO] [IMPORTE]
GroupFooter[ART/FAM]  (vacíos, estructurales)
GroupFooter[G3/G2/G1] TOT. [GRUPOn_ETIQ]  SUM(CANTIDAD)  SUM(IMPORTE)
PageFooter        Página x de y · Impreso el …
```

Mismas notas que el horizontal (ver `balance_almacen_tallas.md §5`): los
pies estructurales ART/FAM existen para que los pies de grupo emparejen
bien, y los niveles inactivos se ocultan en runtime. **Conviene revisar la
maqueta en el diseñador** (se editó el `.dfm` sin diseñador delante).

---

## 5. Archivos

- `balance_almacen_sin_tallas.sql` — SP `PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`
  (idempotente, no toca esquema). **Aplicar a cada BBDD** antes de usar el
  informe.
- `src/Modals/inMtoModalImpBalanceSinTallas.pas` / `.dfm` — modal vertical;
  hereda de `TfrmPrintMultiFiltro`.
- `src/Lib/inLibBalanceSinTallasExcel.pas` — exportación a Excel.
- `src/Core/inMtoPrincipal.pas` / `.dfm` — entrada de menú Almacén →
  Informes → "Balance de Almacén sin tallas".
- `fzam.dpr` / `fzam.dproj` — registro de las unidades nuevas.
