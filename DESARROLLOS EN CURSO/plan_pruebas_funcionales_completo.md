# Plan maestro de pruebas funcionales — toda la refactorización (Fases 0–3)

Fecha: 26/07/2026. Una sola pasada, ordenada por pantalla, cubre todos los
cambios. Ejecutar contra **BBDD de pruebas** (las marcadas ⚠ son destructivas
o requieren provocar fallos).

## Ya validado automáticamente (no requiere tu tiempo)

- **Compilación Release/Win64: 0 errores** tras cada bloque; el último build
  (09:10) incluye verificado el estado final de todos los ficheros.
- **Regresión de integridad de datos: 20/20** sobre `factuzam_demo.sql`
  recién cargado con el índice único aplicado: borrado atómico de factura
  (6/6), albarán desde pedido de venta (5/5), reversión de sesiones (4/4),
  índice único FC/VE + concurrencia (5/5). Scripts reproducibles en
  `DESARROLLOS EN CURSO/test_*.py`.
- **Equivalencia estructural**: las 14 funciones fiscales extraídas son
  idénticas byte a byte a los originales; la fusión de albaranes quedó
  demostrada por la aritmética del compilador (−278 líneas exactas).

## PASO 0 — Arranque y navegación (Fase 0)

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Logon administrador; revisar el menú completo | Arranca sin errores; menú visible entero |
| ☐ | Abrir en muestreo: Clientes, Artículos, Proveedores, Facturas, Pedidos, Albaranes, Sesiones, Inventarios, Tarifas, Usuarios | Cada pantalla abre con su caption |
| ☐ | Logon con usuario restringido | Items sin permiso ocultos como siempre |
| ☐ | En un Mto: editar celda → ESC | Cancela la edición, sin excepción |
| ☐ | Botón Salir con y sin cambios pendientes; 3 pestañas y cerrar la del medio | Diálogo grabar/revertir; la pestaña se cierra; el resto vive |
| ☐ | Cerrar la aplicación con pestañas abiertas | Cierre limpio |

## PASO 1 — Facturas (Fases 1, 2.4 y 3) — la pantalla más tocada

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Crear factura NORMAL: cliente, 2-3 líneas por SKU, grabar | Totales correctos; combo de series se refresca al insertar (W2) |
| ☐ | Pestañas de detalle (líneas/recibos/Verifactu/registro/movimientos) navegando entre facturas | Detalle sigue a la cabecera (W1 — maestro-detalle nuevo) |
| ☐ | Tarifa IVA-incluido vs IVA-excluido en líneas | La columna de precio editable conmuta (W3); s/IVA = c/IVA÷1,21 exacto (I1/I2) |
| ☐ | Validaciones: grabar sin razón social cliente / sin serie / NIF inválido / sin fecha | Mensaje + pestaña + foco EXACTAMENTE como antes (V1–V4 — ahora vía eventos) |
| ☐ | Factura desde form NORMAL y SIMPLIFICADA | TIPO_FAC correcto en cada uno (W4) |
| ☐ | Editar cantidad/precio/descuento en varias líneas | Totales del pie se refrescan (A1/A2) |
| ☐ ⚠ | Corromper % IVA de cabecera en BBDD (NULL) y editar una línea | Error visible "Error al recalcular totales…", NO se graba, entrada en el log (A3 — antes se grababa mal en silencio) |
| ☐ | Consolidar factura simplificada con stock; grabarla DOS veces | Movimientos generados una sola vez (índice único); stock correcto |
| ☐ ⚠ | Borrar factura borrador con líneas+efectos+movimientos; comprobar contadores antes/después | Todo desaparece junto (B1). Con fallo provocado, todo queda íntegro (B5 — ya probado en banco) |
| ☐ | Borrar 2 facturas seguidas; crear una nueva después | Sin errores de transacción; numeración normal (B7/B8) |
| ☐ | Imprimir factura y recibos | Sin cambios |

## PASO 2 — Pedidos y albaranes de venta (Fase 1.3)

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Pedido de venta → Crear albarán (todo y parcial) | Albarán correcto, pedido pasa a PARCIAL/CERRADO |
| ☐ | Con albarán existente (añadir líneas) | Igual que antes |

## PASO 3 — Compras: pedidos, albaranes y sesiones (Fases 1.5 y 2.3)

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Pedido de compra → Crear albarán "todo lo pendiente" | Mismas líneas/cantidades que antes (P1) |
| ☐ | Igual con cantidades celda a celda en el pivote | Sin cambios (P2) |
| ☐ | Almacén sin pendientes | Mensaje claro (P3) |
| ☐ | Línea parcialmente recibida → albarán de lo pendiente | Solo recibe lo pendiente (P4) |
| ☐ | Materializar sesión completa (pedido y/o albarán) | Igual que antes (P5) |
| ☐ | Revertir materialización y RE-materializar | Sin documentos duplicados; pestaña Log de sesiones con avisos si faltara alguna tabla |
| ☐ | Documento de compra con recargo de equivalencia | Totales idénticos a antes (bloque fiscal 2.1) |

## PASO 4 — Remesas (Fase 2.2 — modal unificado)

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Menú → Cargar efectos (compra): buscar, columna "Proveedor" | Efectos de compra pendientes (R1) |
| ☐ | Menú → Cargar efectos de venta: columna "Cliente" | Efectos de venta (R2) |
| ☐ | Crear remesa nueva con 2 efectos en cada variante | REMC/REMV creadas; mensajes "pagados"/"cobrados" (R3/R4) |
| ☐ | Añadir a remesa EXISTENTE desde ambos Mtos de remesas | Modal preseleccionado; efectos añadidos (R5/R6) |
| ☐ | Combo de remesas: formato "SERIE / NUMERO (fecha)" | Igual en ambas (R7) |
| ☐ | Abrir el dfm del modal en el IDE una vez | Carga sin avisos (R8) |

## PASO 5 — BBDD real (Fase 1.6)

| ✔ | Prueba | Esperado |
|---|---|---|
| ☐ | Ejecutar la consulta de duplicados FC/VE (comentada en `movimientos_indice_unico_fcve.sql`) en la BBDD de pruebas real | Si devuelve filas: decidir limpieza ANTES de aplicar |
| ☐ | Aplicar el script (2 veces seguidas) | 2ª pasada dice "ya existe" sin error |

## Si algo falla

Cada bloque está documentado en su `refactorizacion_*_resultados.md` con los
ficheros exactos tocados; `git diff`/`git checkout -- <fichero>` revierte
quirúrgicamente. Ningún cambio de esquema salvo el índice (reversible con
`ALTER TABLE fza_movimientos_almacen DROP COLUMN CLAVE_FCVE_MOV;` que
arrastra el índice).

## Después de la pasada

1. **Commit en git** (rama de trabajo) — hay ~20 ficheros tocados y 12
   documentos/scripts nuevos en `DESARROLLOS EN CURSO`, todo sin consolidar.
2. Los dos ficheros de `_to_delete/` (modal Venta) pueden borrarse
   definitivamente cuando el paso 4 esté verificado.
3. Decisión pendiente anotada: mover la generación de movimientos fuera del
   `AfterPost` (comentario en `unqryFacAfterPost`) — hacerlo con la caja
   delante.
