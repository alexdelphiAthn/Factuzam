# Fase 1, bloque 4 (pasos 1.2 + 1.6 + 1.7) — Movimientos de almacén e índice único

Fecha: 26/07/2026. Ficheros: `src/DataModules/UniDataFacturas.pas` +
`DESARROLLOS EN CURSO/movimientos_indice_unico_fcve.sql` (nuevo).

## 1.2 — Generación de movimientos transaccional

`GenerarMovimientosSalidaFactura` envuelve ahora todo el bucle (contador MV +
`unstrdprcInsertarMovFac` + `UPDATE NUMERO_MOV_FACLIN`) en el idiom
`bTransPropia`: o se insertan TODOS los movimientos pendientes o ninguno. El
refresco de `unqryMovimientosFac` queda fuera, tras el commit.

**Decisión pendiente tuya** (documentada como comentario en `unqryFacAfterPost`):
el plan proponía además mover la llamada del `AfterPost` al flujo explícito de
consolidación, para no evaluarla en cada grabación intermedia. NO lo he hecho
porque el flujo de caja (tickets simplificados) crea facturas por código y
depende de ese `AfterPost`; moverla sin poder probar la caja sería apostar.
Con la transacción + el índice único, el riesgo de corrupción queda cubierto
aunque siga en `AfterPost`. Si quieres moverla, es un cambio de una línea que
conviene hacer con la app delante.

## 1.6 — Índice único de movimientos FC/VE (script idempotente)

**Hallazgo previo que cambió el diseño**: el índice único "ingenuo" sobre
`(TIPO_DOC_MOV, SERIE, NUMERO, LINEA)` es inviable — traspasos (TR),
inventarios (IN) y tarifas (TA) generan legítimamente varios movimientos por
clave (56 grupos en la demo). La unicidad solo aplica a FC/VE, que además
comparten identidad (la caja registra 'VE' y el mantenimiento 'FC' del mismo
documento — el caso exacto de doble descuento de stock).

Solución (MariaDB): columna generada `CLAVE_FCVE_MOV` que solo tiene valor
para FC/VE (NULL para el resto; los NULL no colisionan en UNIQUE) + índice
único `UX_MOV_CLAVE_FCVE`. Script en
`DESARROLLOS EN CURSO/movimientos_indice_unico_fcve.sql`, idempotente
(INFORMATION_SCHEMA + PREPARE/EXECUTE, patrón del repo), con la consulta de
duplicados históricos comentada para ejecutar ANTES en cada BBDD real.

NO se ha tocado `factuzam_original.sql` (regla dura nº 1).

## 1.7 — Fugas rápidas

- `BuscarCliente` y `CalcularRetencionesEmpresa`: `try/finally` con
  `FreeAndNil` (antes una excepción en `Open` filtraba la query).
- Eliminado el `Sleep(0)` usado como rama vacía; condición invertida.

## Resultados de pruebas (MariaDB 10.11 + demo; script `test_indice_movimientos.py`)

| # | Prueba | Resultado |
|---|---|---|
| T1 | INSERT duplicado FC/FC misma clave → error 1062 | **PASA** |
| T2 | El caso real: movimiento VE (caja) + FC (mantenimiento) de la misma línea → bloqueado | **PASA** |
| T3 | TR e IN siguen admitiendo múltiples movimientos por clave (sin regresión) | **PASA** |
| T4 | **Carrera de dos puestos**: ambos pasan el `SELECT` de existencia a la vez (el guard antiguo engañado en los dos), insertan → solo queda 1 movimiento; la 2ª sesión recibe error y su transacción revierte | **PASA** |
| T5 | Corte a mitad de la generación (3 líneas, falla tras la 2ª) → 0 movimientos, atómico | **PASA** |

**5/5.** El script se aplicó DOS veces a la BBDD de pruebas para verificar la
idempotencia (2ª pasada: "ya existe" sin error).

Verificaciones en frío del `.pas`: balance `begin`/`end`/`try` correcto,
sin líneas nuevas >80 columnas, `Sleep(0)` a 0 en el fichero.

## Comportamiento nuevo a conocer

Si dos puestos graban la misma factura a la vez, el segundo verá ahora un
error de clave duplicada (antes: stock descontado DOS veces en silencio). Al
reintentar la grabación, el `SELECT` de existencia ya encuentra el movimiento
y no lo duplica. Si se quiere absorber ese error sin mensaje, la opción es
capturar el 1062 en `GenerarMovimientosSalidaFactura` y tratarlo como "ya
generado" — prefer verlo al menos una temporada antes de silenciarlo.

## Pendiente manual

- Compilar `UniDataFacturas.pas`.
- Aplicar `movimientos_indice_unico_fcve.sql` a la BBDD de pruebas real
  (tras pasar la consulta de duplicados) y después a producción.
- Flujo UI: grabar factura simplificada y normal con ESMUEVE_STOCK, verificar
  movimientos y stock; decidir si mover la generación fuera del `AfterPost`.

---

**Con esto la Fase 1 está completa (5/5 bloques).** Recuento total de la fase:
20 pruebas automatizadas de integridad, 20 PASA. Siguiente en el plan global:
Fase 2 (duplicación barata: `inLibImpuestosComun`, modales de remesa,
fusión de `CrearAlbaranDesdePedido` de compras, conversión IVA única).
