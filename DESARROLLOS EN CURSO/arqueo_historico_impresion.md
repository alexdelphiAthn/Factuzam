# Histórico de Arqueos: duplicados en caja + informe A4 horizontal

Habilita la pantalla de histórico de arqueos en dos sitios:

1. **En caja (TPV)** — dentro del modal de arqueo (F11): una pantalla nueva que
   lista los cierres ya grabados de esa caja y permite **reemitir un DUPLICADO**
   del ticket de arqueo o del justificante de cierre en la impresora de tickets.
2. **En «Caja → Histórico de Arqueos»** (mantenimiento admin): un botón que
   emite un **informe A4 horizontal** (FastReport) con los principales números,
   editable por el usuario con el diseñador y guardable como formato propio.

No toca el esquema: reutiliza `fza_caja_arqueos` (cabecera) y
`fza_caja_arqueos_recuento` (detalle por forma de pago). **No hay SQL nuevo.**

---

## 1. Caja (TPV): duplicados del ticket / cierre

### Flujo

```
inMtoCajaMenu (F11 Arqueo)
   └── TfrmModalArqueo (inMtoModalArqueo)
         └── botón «Histórico (F8)» ──> TfrmModalArqueosHistCaja.Ejecutar(
                                           Self, FConn, FEmpresa, FAlmacen, FCaja)
               ├── lista fza_caja_arqueos de esa Empresa/Almacén/Caja
               ├── F2 / «Duplicado ticket»  ──> TArqueoTicket.ImprimirDesdeHistorico
               └── F3 / «Duplicado cierre»   ──> TArqueoTicket.ImprimirCierreDesdeHistorico
```

### Archivos

| Archivo | Cambio |
|---|---|
| `src/Caja/Modals/inMtoModalArqueosHistCaja.pas` + `.dfm` | **Nuevo.** Pantalla TPV de histórico (grid + botones). Patrón `class procedure Ejecutar(...)` y teclado F2/F3/ESC como el resto de modales de caja. |
| `src/Caja/Lib/inLibArqueoTicket.pas` | `Imprimir` e `ImprimirCierre` admiten `ADuplicado` (imprime banda `*** DUPLICADO ***`). Nuevos `ImprimirDesdeHistorico` (recalcula la tira, marcada) e `ImprimirCierreDesdeHistorico` (reconstruye el cierre desde BBDD sin recalcular). |
| `src/Caja/Modals/inMtoModalArqueo.pas` + `.dfm` | Botón `btnHistorico` + acción `actHistorico` (F8) que abre la pantalla de histórico. |
| `fzam.dpr` | Registra `inMtoModalArqueosHistCaja`. |

### Notas de diseño

- **Duplicado ticket**: usa `TArqueoTicket.Imprimir` recalculando en vivo el
  rango del arqueo (las operaciones del rango son inmutables tras el cierre),
  marcado como DUPLICADO.
- **Duplicado cierre**: reconstruye `TArqueoCaja` + líneas de recuento +
  totales/retirada/dejo/desglose desde `fza_caja_arqueos` y
  `fza_caja_arqueos_recuento` y llama a `ImprimirCierre(..., ADuplicado=True)`.
  No recalcula: reimprime exactamente lo que se grabó.
- Las columnas del cierre añadidas por `arqueo_recuento.sql`
  (`TOTAL_RECUENTO_ARQ`, `IMPORTE_RETIRADA_ARQ`, `DESGLOSE_BILLETES_ARQ`…) se
  leen con `FindField` para tolerar BBDD sin esa migración aplicada.
- Sale por `oNomImpresoraCaja`; si es `DEBUG` / vacío, abre el visor.

---

## 2. Admin: informe A4 horizontal (FastReport)

### Flujo

```
Menú «Caja → Histórico de Arqueos» (Ctrl+Alt+A)
   └── TfrmMtoCajaArqueosHist (inMtoCajaArqueosHist)
         └── botón «Imprimir Informe A4» ──> TfrmPrintArqueos.Create(Application).ShowModal
               └── TfrmPrintArqueos (inMtoModalImpArqueos : TfrmPrint)
                     ├── empresa (fija, del usuario) + almacen / caja con
                     │     boton '...' → TfrmMtoModalCajDef (vi_cajasdef)
                     ├── dteDesde / dteHasta: rango de fechas a imprimir
                     │     (por defecto: primer dia del mes en curso → hoy)
                     ├── preparar_consulta → unqryArqueosPrint (filtra por
                     │     CODIGO_EMP/ALM/CAJA_ARQ + FECHA_DESDE_ARQ BETWEEN)
                     └── frxReportOrigen: A4 apaisado (poLandscape) con los
                         principales números (código, fechas, total ventas,
                         efectivo caja, recuento, diferencia).
```

### Filtro: empresa / almacén / caja + rango de fechas

El modal pide, en la zona libre a la izquierda de los botones:

- **Empresa**: fija, la del usuario (`oEmpresa`), en un `TcxTextEdit` de solo
  lectura. No se permite cambiarla (requisito: «empresas no hace falta»).
- **Almacén** y **Caja**: `TcxButtonEdit` con botón `...` que abre el selector
  estándar `TfrmMtoModalCajDef` (vista `vi_cajasdef`) **acotado a la empresa
  del usuario**; de la fila elegida se toman almacén y caja. Por defecto traen
  `oAlmacen` / `oCaja`.
- **Fecha inicio** / **Fecha fin**: `TcxDateEdit` (`dteDesde` / `dteHasta`).

Los valores por defecto (rango primer día del mes en curso → hoy, y
empresa/almacén/caja activos `oEmpresa` / `oAlmacen` / `oCaja`) se fijan en
`DoShow` la primera vez, sin pisar lo que elija el usuario en el ciclo
Hide/Show de los botones del padre. `preparar_consulta` filtra
`fza_caja_arqueos` por `CODIGO_EMP_ARQ` / `CODIGO_ALM_ARQ` / `CODIGO_CAJA_ARQ`
(los tres exactos) y por `FECHA_DESDE_ARQ BETWEEN :pDESDE AND :pHASTA`
(columna `DATE`, inclusivo). Todos los botones del padre (Vista Preliminar /
PDF / Imprimir / Excel) aplican estos filtros porque pasan por
`preparar_consulta`.

### Archivos

| Archivo | Cambio |
|---|---|
| `src/Caja/Modals/inMtoModalImpArqueos.pas` + `.dfm` | **Nuevo.** Descendiente de `TfrmPrint` (base FastReport de `inMtoModalGenImp`). **Autocontenido**: `unqryArqueosPrint` + `dsArqueosPrint` + `fxdsArqueos` (`UserName='Arqueos'`) viven en el propio form (sin data module externo). Informe en `poLandscape`. |
| `src/Caja/Forms/inMtoCajaArqueosHist.pas` + `.dfm` | Botón `btnImprimirInforme` que abre el modal de impresión. |
| `fzam.dpr` | Registra `inMtoModalImpArqueos`. |

### Por qué autocontenido

Los `.dfm` de la app referencian data modules globales por nombre
(`dmXxx.fxds…`) que en este proyecto **no** se declaran como variable global
(se crean bajo demanda en `ShowMto`). Para evitar referencias cruzadas frágiles,
el modulo de impresión lleva su propio `TfrxDBDataset` local: las memos del
informe apuntan a `fxdsArqueos` (mismo form), y `RebindReportDataSetsByDataModule`
no es necesario.

### Editar / guardar formato (importante)

`TfrmPrint` solo previsualiza/imprime cuando hay un **formato seleccionado**
(igual que el resto de informes del proyecto, que comparten esta base). En la
primera vez, el usuario entra por **Editar** → asistente → crea un formato →
el diseñador abre el diseño base (`frxReportOrigen`, A4 apaisado) → lo retoca y
lo **guarda**. A partir de ahí Vista Preliminar / PDF / Imprimir usan ese
formato. Es justo el flujo de «toquetear el informe en FastReport».

> El diseño base de `frxReportOrigen` es deliberadamente sencillo (cabecera +
> banda de cabecera de columnas + `MasterData` + pie). Pensado para que el
> usuario lo amplíe (más columnas, totales, logo de empresa…) desde el
> diseñador.

---

## 3. Estado / pendientes

- El informe A4 trae 7 columnas (código, desde, hasta, total ventas, efectivo
  caja, recuento, diferencia). Ampliar columnas/orden/totales se hace desde el
  diseñador FastReport y se guarda como formato.
- Posible mejora futura: sembrar un formato `Predeterminado` (fila en
  `fza_usuarios_perfiles` con BLOB vacío) para que el informe imprima de fábrica
  sin pasar antes por Editar.
- El duplicado del ticket de arqueo recalcula en vivo; si en el futuro se quiere
  un duplicado byte-a-byte del original, habría que guardar el documento emitido.
