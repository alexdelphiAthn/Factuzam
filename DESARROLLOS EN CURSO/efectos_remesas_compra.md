# Efectos de pago, conciliación y remesas

Segundo eslabón de **cuentas a pagar**, después de `facturas_compra.md`:

```
factura de compra ──(genera)──► efectos (vencimientos / pagos)
                                      │
                                      └── remesa (agrupa efectos para banco)
```

Ámbito **compra / pago** (proveedor). El cobro a cliente (efectos de cobro,
remesas de cobro) sería el espejo simétrico y queda fuera de esta entrega.

El esquema vive en `efectos_remesas_compra.sql` (idempotente) y la migración
de datos queda cableada en `src/utilmigsqlsrv/inLibMigEfectosCompra.pas`.
Espejo MariaDB del legacy `ocefepro` / `occobpro` / `ocrempro` / `octipefe`
(carpeta `migracion/`), acotado al lado de pago. `occobpro` se agrega sobre
el propio efecto; ya no existe una tabla hija de pagos por efecto.

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
  `ESTADO_EFEC` (PENDIENTE, PAGADO, REMESADO, DEVUELTO, ANULADO,
  CONCILIADO), datos de conciliación (`TIPO_PAGO_EFEC`,
  `REFERENCIA_PAGO_EFEC`, `ENTIDAD_PAGO_EFEC`, `ESCONCILIADO_EFEC`) y el
  enlace a remesa `SERIE_REMC_EFEC` / `NUMERO_REMC_EFEC`. Si un pago es
  parcial, el efecto se divide en dos: uno `PAGADO` por el importe
  conciliado y otro pendiente por el resto. Si varios impagados se fusionan,
  los efectos origen quedan `CONCILIADO`, con pendiente 0 y con
  `REFERENCIA_DOCUMENTO_EFEC` apuntando al efecto resumen. El resumen queda
  como único efecto pendiente real y se localiza también por
  `SERIE_FACC_CONCILIACION_EFEC`, `NUMERO_FACC_CONCILIACION_EFEC` y
  `NUMERO_EFEC_CONCILIACION_EFEC`.
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

2. **Conciliar un pago** — `PRC_EFEC_CONCILIAR_PAGO(pSerie, pNumero,
   pNumEfec, pFecha, pImporte, pTipo, pReferencia, pEntidad, pUsuario,
   OUT pResultado)`. Actualiza el propio efecto. Si `pImporte` cubre todo el
   pendiente, el efecto queda `PAGADO`. Si es parcial, el efecto original queda
   `PAGADO` por el importe conciliado y se crea un nuevo efecto con el resto
   pendiente. No hay tabla de pagos de efectos.

3. **Fusionar impagados** — desde `inMtoEfectosCompra` se pueden seleccionar
   varios efectos pendientes del mismo proveedor y empresa. La operación crea
   un nuevo efecto resumen con la suma pendiente y referencia documental
   `CONC <serie>/<numero>/<efecto>`. Los origenes quedan `CONCILIADO` con esa
   referencia del documento y con enlace al efecto resumen.

4. **Agrupar en remesa**:
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
   filtrable por vencimiento/proveedor, con acción "Conciliar" →
   `PRC_EFEC_CONCILIAR_PAGO` y "Remesar" → `PRC_REMC_ANYADIR_EFECTO`.
3. **Generación del fichero SEPA** (cuaderno 34 de pagos) desde la remesa
   (`ARCHIVO_REMC`).
4. **Tipo de efecto por defecto** configurable por forma de pago (hoy el SP
   usa CONTADO/RECIBO según `ESCONTADO`); falta tratar el anticipo
   (`PORCENTAJE_ANTICIPO_FORMA_PAGO_FP`).
5. **Enlace contable** y conciliación bancaria (`ESCONCILIADO_EFEC`).
6. **Espejo de cobro** a cliente (efectos/remesas de cobro) si se quiere
   simetría con ventas.

---

## Notas de ejecución

- En el migrador:
  - `tipos_efecto_compra` corre en wave 0 y asegura tambien en
    `fza_formas_pago` los textos `FormaPago` y codigos `TipoEfecto` legacy
    usados por documentos.
  - `bancos_empresa` corre en wave 1 y crea `fza_empresas_bancos` desde
    `ocbanrem` cruzado con usos reales en `ocfacpro` / `ocefepro` /
    `ocrempro`.
  - `efectos_compra` corre en wave 6, despues de `facturas_compra`. Si el
    legacy trae un efecto parcialmente pagado, el migrador lo divide en efecto
    pagado y efecto pendiente.
  - `remesas_compra` corre en wave 7, despues de los efectos, y recalcula sus
    totales desde `fza_efectos_compra`.
- El esquema debe existir antes de migrar (depende de `fza_facturas_compra`,
  `fza_efectos_compra`, `fza_remesas_compra` y `fza_tipos_efecto`).
- **Idempotente** (`INFORMATION_SCHEMA`, `DROP ... IF EXISTS`,
  `INSERT ... WHERE NOT EXISTS`). Requiere cliente **`DELIMITER`-aware**.
- Las stored procedures **no se han probado contra una BBDD viva** en esta
  entrega: validar con datos reales antes de cablear los Mtos.
- **No** toca `factuzam_original.sql`.
