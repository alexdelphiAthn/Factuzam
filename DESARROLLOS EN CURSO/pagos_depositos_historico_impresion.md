# Histórico de Pagos y de Depósitos: informes A4 horizontales

Réplica del informe de arqueos / operaciones para dos pantallas más, con los
mismos filtros (empresa fija del usuario, almacén / caja con botón `...` sobre
`vi_cajasdef`, y rango de fechas por defecto del primer día del mes en curso a
hoy).

No tocan el esquema base. **Único cambio de esquema: la vista `vi_caja_pagos`**
(ver más abajo), en script idempotente aparte.

---

## Pagos de caja

```
Menú «Caja → Histórico de Pagos»
   └── TfrmMtoCajaPagosHist (inMtoCajaPagosHist)
         └── botón «Imprimir Informe A4» ──> TfrmPrintPagos.ShowModal
               └── inMtoModalImpPagos : TfrmPrint
                     └── preparar_consulta → vi_caja_pagos, filtrado por
                         CODIGO_EMP/ALM/CAJA_PAGO + DATE(FECHA_PAGO) BETWEEN
```

`fza_caja_pagos` **no tiene columna de fecha propia** (solo `INSTANTE_ALTA`, el
instante de grabación). Por eso se lee de la vista **`vi_caja_pagos`**
(`DESARROLLOS EN CURSO/vista_caja_pagos.sql`), que añade `FECHA_PAGO`: la fecha
de la operación de caja asociada (`fza_caja_operaciones`) o, si no se localiza,
`INSTANTE_ALTA`. La fecha se resuelve con subconsulta `MIN` (no JOIN) para no
multiplicar filas si una operación tiene varias líneas.

Columnas del informe: serie, operación, línea, fecha, forma de pago, divisa,
importe entregado, importe cambio, referencia.

> **Aplicar en BBDD existentes:** ejecutar `vista_caja_pagos.sql` (idempotente,
> `CREATE OR REPLACE VIEW`). Sin la vista, el informe de pagos no abre.

---

## Depósitos de clientes

```
Menú «… → Depósitos de Cliente»
   └── TfrmMtoDepositosCliente (inMtoDepositosCliente)
         └── botón «Imprimir Informe A4» ──> TfrmPrintDepositos.ShowModal
               └── inMtoModalImpDepositos : TfrmPrint
                     └── preparar_consulta → fza_depositos_cliente, filtrado
                         por CODIGO_EMP/ALM/CAJA_DEP + DATE(FECHA_CREACION_DEP)
```

`fza_depositos_cliente` sí tiene fecha propia (`FECHA_CREACION_DEP`) y columnas
de empresa / almacén / caja, así que no necesita vista.

Columnas del informe: id depósito, fecha, cliente, artículo (SKU), precio
venta, anticipo, estado, nº operación.

> **Nota:** `CODIGO_ALM_DEP` / `CODIGO_CAJA_DEP` admiten NULL. El filtro exacto
> por almacén / caja deja fuera depósitos sin caja asignada (no debería haberlos
> en depósitos creados desde TPV). Si hiciera falta incluirlos, habría que
> relajar el filtro.

---

## Archivos

| Archivo | Cambio |
|---|---|
| `src/Caja/Modals/inMtoModalImpPagos.pas` + `.dfm` | **Nuevo.** Descendiente de `TfrmPrint`, autocontenido. Lee `vi_caja_pagos`. |
| `src/Caja/Modals/inMtoModalImpDepositos.pas` + `.dfm` | **Nuevo.** Descendiente de `TfrmPrint`, autocontenido. Lee `fza_depositos_cliente`. |
| `src/Caja/Forms/inMtoCajaPagosHist.pas` + `.dfm` | Botón `btnImprimirInforme`. |
| `src/Forms/inMtoDepositosCliente.pas` + `.dfm` | Botón `btnImprimirInforme`. |
| `DESARROLLOS EN CURSO/vista_caja_pagos.sql` | **Nuevo.** Crea `vi_caja_pagos` (idempotente). |
| `fzam.dpr` | Registra los dos modales. |
