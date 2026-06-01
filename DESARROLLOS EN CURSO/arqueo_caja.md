# Arqueo de Caja

Pantalla F11 del menú de caja (TPV). Permite revisar el cuadre del día —o de un
rango de fechas— de una caja concreta calculando, en vivo y a partir de las
operaciones ya registradas en BBDD, los totales que figuran en el ticket de
arqueo (bruto, descuentos, neto, cobros, efectivo, tarjetas, vales, depósitos).

En este primer paso la pantalla es de **solo lectura**: muestra los importes
calculados desde `fza_caja_operaciones`, `fza_caja_pagos` y `fza_caja_vales`,
sin permitir todavía recuento manual ni cierre Z.

La tabla `fza_caja_arqueos` se crea ya con todas las columnas que necesitará el
cierre Z futuro (sello/firma del arqueo, importes recontados, retirados,
anteriores), aunque hoy no se inserte ningún registro. Cuando se implemente el
F5 Recuento, ese flujo persistirá una fila en `fza_caja_arqueos` y marcará
`CODIGO_ARQUEO_OPCAJA` en `fza_caja_operaciones` (FK lógica ya existente).

---

## 1. Archivos nuevos

| Archivo | Contenido |
|---|---|
| `DESARROLLOS EN CURSO/arqueo_caja.sql` | Script DDL: crea `fza_caja_arqueos` con sus índices. Idempotente. |
| `src/Caja/Lib/inLibArqueo.pas` | `TArqueoCalculadora.Calcular` — record `TArqueoCaja` con todos los importes calculados a partir de la BBDD. |
| `src/Caja/Modals/inMtoModalArqueo.pas` + `.dfm` | `TfrmModalArqueo` — pantalla modal con el detalle de cuadre. `class function Ejecutar(...)` siguiendo el patrón del libro de estilo. |

## 2. Archivos modificados

| Archivo | Cambio |
|---|---|
| `LIBRO_DE_ESTILO_BBDD.md` | Registra el sufijo `ARQ` en el catálogo de la sección 2. |
| `src/Caja/Forms/inMtoCajaMenu.pas` | `lblArqueoClick` deja de ser TODO: lanza `TfrmModalArqueo.Ejecutar` con la empresa/almacén/caja actuales y `FFechaCaja` como rango por defecto. |
| `fzam.dpr` | Registra `inLibArqueo` y `inMtoModalArqueo`. |
| `DESARROLLOS EN CURSO/menu_caja.md` | F11 deja de figurar como TODO. |

> El dump de referencia `factuzam_original.sql` **no** se toca. El DDL nuevo
> vive aislado en `DESARROLLOS EN CURSO/arqueo_caja.sql` y se aplicará a la
> BBDD por el cauce habitual (DBComparer / script manual).

---

## 3. Tabla `fza_caja_arqueos`

Sufijo `ARQ`. PK: `CODIGO_ARQ` (cadena identificativa del arqueo, generada al
hacer el cierre Z; en este primer paso no se usa).

Columnas relevantes (todas las monetarias `decimal(19,6)`):

- Contexto: `CODIGO_EMP_ARQ`, `CODIGO_ALM_ARQ`, `CODIGO_CAJA_ARQ`,
  `FECHA_DESDE_ARQ`, `FECHA_HASTA_ARQ`, `CODIGO_EMPLEADO_ARQ` (opcional).
- Estado: `FASE_ARQ` (`'ABIERTO'` / `'CERRADO'`).
- Contadores: `CANTIDAD_VENTAS_ARQ`, `CANTIDAD_OPERACIONES_ARQ`.
- Líneas: `TOTAL_BRUTO_LINEAS_ARQ`, `TOTAL_DESCUENTOS_LINEAS_ARQ`.
- Operaciones: `TOTAL_BRUTO_OPERACIONES_ARQ`,
  `TOTAL_DESCUENTOS_OPERACIONES_ARQ`,
  `TOTAL_NETO_ARQ`, `TOTAL_PRESTAMOS_ARQ`.
- Cobros: `TOTAL_VALES_RECOGIDOS_ARQ`, `TOTAL_VALES_EMITIDOS_ARQ`,
  `TOTAL_COBROS_CLIENTES_ARQ`, `TOTAL_PENDIENTE_COBRO_ARQ`,
  `TOTAL_INGRESOS_CAJA_ARQ`.
- Efectivo / otros: `TOTAL_EFECTIVO_INGRESOS_ARQ`,
  `TOTAL_EFECTIVO_ENTRADAS_ARQ`, `TOTAL_EFECTIVO_SALIDAS_ARQ`,
  `TOTAL_EFECTIVO_ANTERIOR_ARQ`, `TOTAL_EFECTIVO_CAJA_ARQ`,
  `TOTAL_OTROS_INGRESOS_ARQ`, `TOTAL_SALDO_RECONTAR_ARQ`.

  > Nota: el cubo "efectivo" agrupa las formas de pago con cajón
  > (`ESABRE_CAJON_FORMA_PAGO_CFP = 'S'`) y "otros" todas las demás
  > (tarjeta, bono, divisa, cripto...). La discriminación es siempre por
  > flag, nunca por código hardcoded — el TPV admite N formas de pago.
  > El desglose por forma se calcula al vuelo en `TArqueoPagoForma` y se
  > guardará en una tabla hija (`fza_caja_arqueos_pagos`) cuando se
  > implemente el cierre Z; en este primer paso no se persiste.
- Observaciones: `OBSERVACIONES_ARQ`.
- Auditoría estándar: `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`,
  `USUARIO_MODIF`.

Índices:

- `IDX_ARQ_CTX_FECHA` (empresa, almacén, caja, fecha desde).
- `IDX_ARQ_FECHA` (fecha desde, fecha hasta).
- `IDX_ARQ_FASE` (fase).

---

## 4. Cálculo de los importes (solo lectura)

Todo se calcula en `TArqueoCalculadora.Calcular`, una única clase con queries
parametrizadas (`oConn`, empresa, almacén, caja, fecha desde, fecha hasta).
Filtros siempre por `FECHA_OPERACION_OPCAJA BETWEEN :desde AND :hasta`
(datetime, no date) y el contexto Empresa+Almacén+Caja del menú. Las
fechas del modal son `TcxDateEdit` con `Kind=ckDateTime`; los defaults
son 00:00:00 para "desde" y 23:59:59 para "hasta" del rango pedido,
así un arqueo de un día concreto cubre el día entero. Se evita la
columna `FECHA_OP_DIA_OPCAJA` (que no siempre está poblada en filas
recién insertadas) usando directamente el datetime de la operación.

| Concepto en la pantalla | Origen |
|---|---|
| `Ventas` (contador arriba a la derecha) | `COUNT(DISTINCT NUMERO_OPERACION_OPCAJA)` con `TIPO_OPERACION_OPCAJA = 'VE'`. |
| Líneas — Bruto + / = | `SUM(TOTAL_FACLIN)` (sin descuentos) de las facturas asociadas a las operaciones de tipo `VE`. |
| Líneas — Descuento | `SUM` de descuentos de línea sobre esas mismas líneas. |
| Operaciones — Descuentos | Descuento global de cabecera (`TOTAL_BASES_FAC` menos suma de líneas). |
| Operaciones — Neto | `SUM(IMPORTE_TOTAL_OPCAJA)` con `TIPO_OPERACION_OPCAJA = 'VE'`. |
| Préstamos / Ventas Préstamos | `SUM(PRECIO_VENTA_DEP × CANTIDAD_PENDIENTE_DEP)` de `fza_depositos_cliente` cuya `FECHA_CREACION_DEP` cae en el rango (no se filtra por `ESTADO_DEP` para que los arqueos pasados sigan reflejando los préstamos que se abrieron entonces aunque hoy estén cerrados). Es el **valor entero de la mercancía comprometida**, no el pendiente. |
| Devoluciones | `ABS(SUM(IMPORTE_TOTAL_OPCAJA))` con `TIPO_OPERACION_OPCAJA = 'DV'`. Las devoluciones son operaciones con tipo canónico **DV** (no VE negativas). |
| Cobros — Vales recogidos | `SUM(IMPORTE_REDIMIDO_VL)` de `fza_caja_vales` redimidos en la caja en el rango. |
| Cobros — Vales emitidos | `SUM(IMPORTE_NOMINAL_VL)` de `fza_caja_vales` emitidos en la caja en el rango. |
| Cobros clientes | `SUM(IMPORTE_TOTAL_OPCAJA)` de `fza_caja_operaciones` con `TIPO IN ('CB','DE') AND IMPORTE > 0 AND ID_DEPOSITO_OPCAJA NOT NULL`, dentro del rango. Es el flujo de efectivo entrado como anticipos. Lee de operaciones (no del snapshot de `fza_depositos_cliente.IMPORTE_ANTICIPO_DEP`) para que un arqueo de temporada pasada vea los cobros que se hicieron entonces aunque los depósitos ya estén cerrados hoy. |
| Pendiente cobro | `Préstamos − Cobros clientes` — saldo que el cliente aún debe entregar para retirar la mercancía. |
| Ingresos caja | `Efectivo ingresos + Otros ingresos` (= `SaldoRecontar`). Es la suma directa de `fza_caja_pagos.IMPORTE_ENTREGADO_PAGO`. La antigua fórmula compleja (`Neto − Préstamos − VR + VE + CC − Pendiente`) arrastraba los desajustes del flujo real y daba cifras irreales; se sustituye por la suma directa de pagos. |
| Efectivo ingresos | `SUM(IMPORTE_ENTREGADO_PAGO)` de `fza_caja_pagos` para las formas con `ESABRE_CAJON_FORMA_PAGO_CFP = 'S'` (efectivo, divisas en metálico, lo que se mete en el cajón). |
| Efectivo entradas / salidas | `SUM(IMPORTE_TOTAL_OPCAJA)` con `TIPO_OPERACION_OPCAJA IN ('EC','GC')`. |
| Efectivo anterior | 0 (solo se rellena cuando se cierre el arqueo anterior y se enlace). |
| Efectivo en caja | Efectivo ingresos + entradas − salidas + anterior. |
| Otros ingresos (tarj., bono, divisa, cripto) | `SUM(IMPORTE_ENTREGADO_PAGO)` para las formas con `ESABRE_CAJON_FORMA_PAGO_CFP = 'N'`. |
| Saldo efectivo + otros | Efectivo en caja + otros ingresos. |

---

## 5. Estado del flujo

```
inMtoCajaMenu (TfrmMtoMenuCaja)
   └── F11 ──> TfrmModalArqueo.Ejecutar(
                  Self, oConn,
                  FEmpresa, FAlmacen, FCaja,
                  FFechaCaja, FFechaCaja)
                  └── TArqueoCalculadora.Calcular(...)
                        ├── fza_caja_operaciones
                        ├── fza_caja_pagos
                        ├── fza_caja_vales
                        └── fza_facturas (+ líneas)
                  └── ESC → cierra
```

Pendiente para próximas iteraciones (no en este PR):

- F5 Recuento: diálogo para entrar efectivo recontado, retirado, anterior y
  cerrar el arqueo (insertar en `fza_caja_arqueos` y marcar las operaciones).
- F12 Resumen y F11 Tira caja (impresora).
- Pestañas "Resúmenes" y "Más datos".
- Encadenado de efectivo anterior automático (leer del arqueo previo cerrado).
