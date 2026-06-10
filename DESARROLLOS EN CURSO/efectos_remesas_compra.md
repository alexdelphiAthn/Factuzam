# Efectos de pago, histórico de pagos y remesas (hito 1: BBDD)

Segundo eslabón de **cuentas a pagar**, después de `facturas_compra.md`:

```
factura de compra ──(genera)──► efectos (vencimientos de pago, con fecha)
       │                               │
       │                     histórico de pagos (varios pagos por efecto, con fecha)
       └───────────────────────► remesa (agrupa efectos para pago en banco)
```

Ámbito **compra / pago** (proveedor). El cobro a cliente (efectos de cobro,
remesas de cobro) sería el espejo simétrico y queda fuera de esta entrega.

Solo esquema de BBDD (`efectos_remesas_compra.sql`, idempotente). Espejo
MariaDB del legacy `ocefepro` / `occobpro` / `ocrempro` / `octipefe`
(carpeta `migracion/`), acotado al lado de pago.

---

## Tablas y sufijos

Registrados en `LIBRO_DE_ESTILO_BBDD.md §2` y en
`UNormalizerEngine.pas / InitDefaults`:

- `fza_tipos_efecto`         → `TEFE`    — catálogo (CONTADO, TRANSFERENCIA,
  RECIBO, PAGARE, CONFIRMING). `ESDOMICILIADO_TEFE` / `ESREMESABLE_TEFE`
  marcan si se paga por banco y si puede ir en remesa. Se siembra idempotente.
- `fza_efectos_compra`       → `EFEC`    — **un efecto por plazo** de la
  factura. Clave `(SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC)`. Lleva
  `FECHA_VENCIMIENTO_EFEC` (la fecha clave del control contable),
  `IMPORTE_EFEC` / `IMPORTE_PAGADO_EFEC` / `IMPORTE_PENDIENTE_EFEC`,
  `ESTADO_EFEC` (PENDIENTE, PARCIAL, PAGADO, REMESADO, DEVUELTO, ANULADO) y
  el enlace a remesa `SERIE_REMC_EFEC` / `NUMERO_REMC_EFEC`.
- `fza_efectos_compra_pagos` → `EFECPAG` — **HISTÓRICO de pagos con fecha**.
  Clave `(...EFEC, NUMERO_PAGO_EFECPAG)`: varios pagos por efecto ⇒ pagos
  parciales y trazabilidad. `FECHA_EFECPAG`, `IMPORTE_EFECPAG`,
  `REFERENCIA_EFECPAG`, `ESCONCILIADO_EFECPAG`.
- `fza_remesas_compra`       → `REMC`    — remesa que **agrupa efectos**.
  Documento propio numerado con el tipo `'RP'` (REMESA DE PAGOS).
  `TIPO_REMC`/`NORMA_REMC` (norma SEPA), cuenta de cargo de la empresa,
  `CONTADOR_EFECTOS_REMC`, `TOTAL_REMC`, `FECHA_CARGO_REMC`.

Vistas: `vi_efectos_compra` (efecto + factura + proveedor + tipo),
`vi_efectos_compra_pendientes` (cartera viva por vencimiento),
`vi_remesas_compra`.

---

## Flujo y procedimientos

1. **Generar efectos** — `PRC_EFEC_GENERAR_DESDE_FACTURA(pSerie, pNumero,
   pUsuario, OUT pResultado)`. Lee la forma de pago de la factura
   (`N_PLAZOS_FORMA_PAGO_FP`, `N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP`,
   `ESCONTADO_FORMA_PAGO_FP`) y reparte `TOTAL_LIQUIDO_FACC` en N efectos;
   el último absorbe el redondeo. `FECHA_VENCIMIENTO = FECHA_FACC + i·días`.
   **No regenera** si ya hay efectos pagados/remesados (aborta con 0 para no
   destruir el histórico). `pResultado` = nº de efectos generados.

2. **Registrar un pago** — `PRC_EFEC_REGISTRAR_PAGO(pSerie, pNumero, pNumEfec,
   pFecha, pImporte, pTipo, pReferencia, pEntidad, pUsuario, OUT pResultado)`.
   Inserta una fila en el histórico (`NUMERO_PAGO` autoincremental por
   efecto), acumula `IMPORTE_PAGADO_EFEC`, recalcula `IMPORTE_PENDIENTE_EFEC`
   y pone el efecto en `PARCIAL` o `PAGADO`. Permite **pagos parciales**.

3. **Agrupar en remesa**:
   - `PRC_REMC_CREAR(pEmpresa, pIban, pUsuario, OUT pSerie, OUT pNumero)` crea
     una remesa vacía numerada con `'RP'`.
   - `PRC_REMC_ANYADIR_EFECTO(pSerieRem, pNumRem, pSerieFac, pNumFac,
     pNumEfec, pUsuario, OUT pResultado)` enlaza un efecto (lo marca
     `REMESADO`) y recalcula la remesa. No re-remesa un efecto ya remesado o
     pagado.
   - `PRC_REMC_RECALCULAR(pSerie, pNumero)` recuenta efectos e importe.

---

## Pendiente / hitos siguientes

1. **Mtos Delphi** `inMtoEfectosCompra` / `inMtoRemesasCompra` (+ datamodules)
   heredando de `TfrmMtoGen`, y el registro `fza_winforms` correspondiente
   (no se registra aquí: las units aún no existen).
2. **Cartera de pagos**: pantalla sobre `vi_efectos_compra_pendientes`
   filtrable por vencimiento/proveedor, con acción "Pagar" →
   `PRC_EFEC_REGISTRAR_PAGO` y "Remesar" → `PRC_REMC_ANYADIR_EFECTO`.
3. **Generación del fichero SEPA** (cuaderno 34 de pagos) desde la remesa
   (`ARCHIVO_REMC`).
4. **Tipo de efecto por defecto** configurable por forma de pago (hoy el SP
   usa CONTADO/RECIBO según `ESCONTADO`); falta tratar el anticipo
   (`PORCENTAJE_ANTICIPO_FORMA_PAGO_FP`).
5. **Enlace contable** y conciliación bancaria (`ESCONCILIADO_EFECPAG`).
6. **Espejo de cobro** a cliente (efectos/remesas de cobro) si se quiere
   simetría con ventas.

---

## Notas de ejecución

- Ejecutar **después** de `facturas_compra.sql` (depende de
  `fza_facturas_compra` y de `PRC_FNC_GET_NEXT_NRO_DOC`).
- **Idempotente** (`INFORMATION_SCHEMA`, `DROP ... IF EXISTS`,
  `INSERT ... WHERE NOT EXISTS`). Requiere cliente **`DELIMITER`-aware**.
- Las stored procedures **no se han probado contra una BBDD viva** en esta
  entrega: validar con datos reales antes de cablear los Mtos.
- **No** toca `factuzam_original.sql`.
