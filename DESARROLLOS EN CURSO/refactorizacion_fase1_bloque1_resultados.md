# Resultados de pruebas — Fase 1, bloque 1 (borrado atómico de factura)

Fecha: 26/07/2026. Entorno: MariaDB 10.11 con `factuzam_demo.sql` cargado
íntegro (166 facturas, 144 tablas InnoDB, collation `utf8mb4_spanish_ci`),
en contenedor aislado. Se replicó la **secuencia SQL exacta** que ejecuta
`TdmFacturas.unqryTablaGBeforeDelete` tras el refactor 1.1 (transacción →
DELETE efectos → líneas → recibos → `CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC`
VE y FC → DELETE cabecera → commit / rollback), con datos reales de la demo.
Script reproducible: `test_borrado_factura.py` (adjunto en esta carpeta).

## Verificaciones previas del entorno

| Comprobación | Resultado |
|---|---|
| Motor de TODAS las tablas implicadas (facturas, líneas, recibos, efectos, movimientos) | InnoDB — las transacciones y el rollback son efectivos |
| `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC` y `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE` | Sin `COMMIT`/`START TRANSACTION` internos — no rompen la atomicidad |
| Sentencias de la secuencia | Ninguna es DDL — no hay commits implícitos de MySQL |

## Resultados

| # | Prueba (ref. plan) | Datos | Resultado |
|---|---|---|---|
| T1 | B1 — borrado feliz | A1/000028 (4 líneas, 4 movs) | **PASA**: todos los contadores a 0 tras commit |
| T2 | B5 — fallo a mitad (tabla `fza_recibos` renombrada) | A1/000030 (12 líneas, 1 efecto, 4 movs) | **PASA**: error capturado, rollback, factura ÍNTEGRA (12/1/4 intactos) |
| T3 | B6 — cabecera bloqueada por otra sesión (`FOR UPDATE`, timeout 2s) | A1/000027 (3 líneas, 3 movs) | **PASA**: error 1205, rollback, factura íntegra — valida el camino `OnDeleteError` |
| T4 | Demostración del código ANTIGUO (sin transacción) con el mismo fallo | 2026.A1/000135 (4 líneas, 4 movs) | **PASA** (confirma el bug que motivó el cambio): cabecera viva con 0 líneas y movimientos huérfanos |
| T5 | B7 — dos borrados consecutivos en la misma sesión | A1/000035 y A1/000031 | **PASA**: sin errores de transacción ya activa |
| T6 | Rollback de lo borrado por el SP (cursor + SP anidado) | 2026.A1/000166 (3 movs) | **PASA**: movs 3 → 0 → 3 tras rollback |

**6/6 superadas.** La T4 es la evidencia del riesgo corregido: con el código
anterior, el mismo fallo dejaba la factura corrupta (cabecera sin líneas y
stock descontado); con el nuevo, queda íntegra.

## Incidencia de entorno (no afecta al código)

Con la BBDD creada con collation por defecto `utf8mb4_general_ci`, los SP de
movimientos fallan con "Illegal mix of collations" porque comparan parámetros
(collation de la BBDD) contra columnas (`utf8mb4_spanish_ci`). En la demo real
no ocurre porque la BBDD se crea con `SET NAMES … utf8mb4_spanish_ci`. Apunte
preventivo: si algún día una instalación se crea con otra collation por
defecto, estos SP fallarán — puede valer la pena fijar `COLLATE` explícito en
los parámetros de los SP o documentar el requisito en el instalador.

## Qué queda pendiente de validar a mano (requiere la app compilada)

- Bloque A completo del plan (1.4, recalculo de totales): A1–A5, en especial
  A3 (fallo provocado → la edición se aborta con mensaje y entrada en el log).
- B2/B3/B4 (los `Abort` de confirmación, fase Verifactu y efectos cobrados:
  diálogos de UI) y B8 (numeración tras borrado).
- Compilación de `UniDataFacturas.pas`, `inLibtb.pas`, `inLibFacturas.pas`.
