# Histórico de Operaciones de Caja: informe A4 horizontal

Añade en «Caja → Histórico de Operaciones» un botón que emite un **informe A4
horizontal** (FastReport) con las operaciones del TPV, filtradas por
empresa / almacén / caja y rango de fechas. Réplica del informe de arqueos
(`inMtoModalImpArqueos`), reutilizando la misma base FastReport y el mismo
patrón de filtros.

No toca el esquema: lee `fza_caja_operaciones`. **No hay SQL nuevo.**

---

## Flujo

```
Menú «Caja → Histórico de Operaciones»
   └── TfrmMtoCajaOperacionesHist (inMtoCajaOperacionesHist)
         └── botón «Imprimir Informe A4» ──> TfrmPrintOperaciones.Create(Application).ShowModal
               └── TfrmPrintOperaciones (inMtoModalImpOperaciones : TfrmPrint)
                     ├── empresa (fija, del usuario) + almacen / caja con
                     │     boton '...' → TfrmMtoModalCajDef (vi_cajasdef)
                     ├── dteDesde / dteHasta: rango de fechas a imprimir
                     │     (por defecto: primer dia del mes en curso → hoy)
                     ├── preparar_consulta → unqryOperacionesPrint (filtra por
                     │     CODIGO_EMP/ALM/CAJA_OPCAJA + DATE(FECHA_OPERACION))
                     └── frxReportOrigen: A4 apaisado (poLandscape) con
                         operación, fecha, tipo, cliente, serie/nº factura,
                         concepto e importe.
```

---

## Archivos

| Archivo | Cambio |
|---|---|
| `src/Caja/Modals/inMtoModalImpOperaciones.pas` + `.dfm` | **Nuevo.** Descendiente de `TfrmPrint`. **Autocontenido**: `unqryOperacionesPrint` + `dsOperacionesPrint` + `fxdsOperaciones` (`UserName='Operaciones'`) viven en el propio form. Informe en `poLandscape`. |
| `src/Caja/Forms/inMtoCajaOperacionesHist.pas` + `.dfm` | Botón `btnImprimirInforme` que abre el modal de impresión. |
| `fzam.dpr` | Registra `inMtoModalImpOperaciones`. |

---

## Filtro: empresa / almacén / caja + rango de fechas

Idéntico al de arqueos:

- **Empresa**: fija, la del usuario (`oEmpresa`), en un `TcxTextEdit` de solo
  lectura.
- **Almacén** y **Caja**: `TcxButtonEdit` con botón `...` que abre el selector
  estándar `TfrmMtoModalCajDef` (vista `vi_cajasdef`) **acotado a la empresa
  del usuario**; de la fila elegida se toman almacén y caja. Por defecto traen
  `oAlmacen` / `oCaja`. El modal es `fsStayOnTop`, así que se oculta
  (`Self.Hide` / `Self.Show`) mientras el selector está visible para que no
  salga por detrás.
- **Fecha inicio** / **Fecha fin**: `TcxDateEdit` (`dteDesde` / `dteHasta`),
  por defecto del primer día del mes en curso a hoy.

`preparar_consulta` filtra `fza_caja_operaciones` por `CODIGO_EMP_OPCAJA` /
`CODIGO_ALM_OPCAJA` / `CODIGO_CAJA_OPCAJA` y por el rango de fechas. Como
`FECHA_OPERACION_OPCAJA` es **datetime**, el rango se aplica sobre
`DATE(FECHA_OPERACION_OPCAJA) BETWEEN :pDESDE AND :pHASTA` para que sea
inclusivo por día (incluye toda la jornada de la fecha fin). Todos los botones
del padre (Vista Preliminar / PDF / Imprimir / Excel) aplican el filtro porque
pasan por `preparar_consulta`.

---

## Editar / guardar formato

Igual que el resto de informes del proyecto: la primera vez el usuario entra
por **Editar** → asistente → crea un formato → el diseñador abre el diseño base
(`frxReportOrigen`, A4 apaisado) → lo retoca y lo guarda. A partir de ahí Vista
Preliminar / PDF / Imprimir usan ese formato. El diseño base trae 8 columnas
(operación, fecha, tipo, cliente, serie, factura, concepto, importe); ampliar
columnas / totales / agrupar por tipo se hace desde el diseñador FastReport.
