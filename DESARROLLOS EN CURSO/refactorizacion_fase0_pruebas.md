# Plan de pruebas — Fase 0 (pasos 0.4–0.6)

Los pasos 0.1–0.3 solo borraban declaraciones muertas (riesgo nulo: su prueba es
compilar). Los pasos 0.4–0.6 tocan tres mecanismos delicados en ejecución:
resolución de items de menú al arrancar, cancelación de grids con ESC/botón, y
cierre de pestañas por mensaje de Windows. Este plan cubre exactamente esos tres.

**Requisito previo**: compilar `fzam.dproj` sin errores y sin hints nuevos
respecto a la compilación de referencia. Ejecutar contra BBDD de pruebas, nunca
producción.

---

## Bloque A — Arranque y menú (afectado por 0.4: `TfzaForm.Create`)

El cambio: `TfzaForm.Create` ya no castea el Owner a `TfrmMtoPrincipal` para hacer
`FindComponent(FMenuItem)`; lo llama directamente sobre el `TComponent` recibido.
`TfzaForm` se crea para CADA fila de `fza_winf` al arrancar (`oFzaWinf.Charge`),
así que un fallo aquí se ve inmediatamente tras el logon.

| # | Prueba | Resultado esperado |
|---|---|---|
| A1 | Logon con usuario administrador | La aplicación arranca sin excepciones y el menú completo es visible |
| A2 | Revisar el menú entero: cada entrada de mantenimiento abre su pantalla (muestreo mínimo: Clientes, Artículos, Proveedores, Facturas, Pedidos, Albaranes, Sesiones de compra, Inventarios, Tarifas, Usuarios) | Cada pantalla abre en su pestaña con el caption correcto |
| A3 | Logon con un usuario de perfil restringido | Los items sin permiso aparecen ocultos/deshabilitados exactamente igual que antes del cambio (AplicarPermisosMenu usa `CallRegistrado`, que lee `FmnMenuItem`) |
| A4 | Atajos de teclado definidos en `fza_winf` (columna shortcut) | Siguen abriendo su pantalla |

Si A3 falla (items visibles que no deberían), el sospechoso es `FmnMenuItem` a
`nil` por el `FindComponent`: comprobar que el Owner pasado a `TfzaWinF.Create`
sigue siendo el form principal.

## Bloque B — Cancelación de grids (afectado por 0.5: `CancelarGrids`)

El cambio: `CancelarGrids` recibe ahora el `TcxPageControl` en lugar del form
principal, y el llamante de ESC solo la invoca dentro de fzam (antes, en
standalone lanzaba `EInvalidCast`; ahora no hace nada, que es el comportamiento
del otro llamante).

| # | Prueba | Resultado esperado |
|---|---|---|
| B1 | Abrir Clientes → editar una celda del grid (estado dsEdit) → pulsar ESC | La edición se cancela, el registro vuelve a su valor, sin excepción |
| B2 | Abrir Clientes → botón Nuevo (dsInsert) → ESC | La fila nueva desaparece |
| B3 | Con DOS pestañas abiertas (Clientes y Artículos), editar en la pestaña ACTIVA y pulsar ESC | Solo cancela la pestaña activa (el mecanismo usa `ActivePageIndex`: es el mismo comportamiento de antes, verificar que no cambió) |
| B4 | Botón Cancelar del Mto (el llamante de `btnCancelarClick`) con edición pendiente | Cancela igual que antes |
| B5 | ESC en una pantalla SIN edición pendiente | No pasa nada, sin excepción |

## Bloque C — Cierre de pestañas (afectado por 0.6: `WM_FREECONTROL`)

El cambio: constante unificada a `WM_USER + 1` (el valor que ya funcionaba) y el
handler declarado con la constante. El riesgo sería un valor mal unificado: se
notaría en que el botón Salir deja la pestaña abierta.

| # | Prueba | Resultado esperado |
|---|---|---|
| C1 | Abrir un Mto → botón Salir sin cambios pendientes | La pestaña se cierra y desaparece del page control |
| C2 | Abrir un Mto → editar sin grabar → botón Salir → responder "Sí" al diálogo | Graba, muestra "Cambios grabados" y cierra la pestaña |
| C3 | Igual que C2 pero responder "No" | Revierte, muestra "Cambios revertidos/cancelados" y cierra la pestaña |
| C4 | Abrir 3 pestañas, cerrar la del medio con Salir | Se cierra la correcta; las otras dos siguen operativas y el foco queda en una pestaña viva |
| C5 | Cerrar la aplicación entera con pestañas abiertas | Cierre limpio, sin AV al salir |

## Bloque D — Regresión rápida transversal (por los uses tocados en 0.1–0.3)

| # | Prueba | Resultado esperado |
|---|---|---|
| D1 | Crear factura con 2 líneas → grabar → consolidar → borrar | Flujo completo sin errores (UniDataFacturas fue tocado) |
| D2 | Crear albarán desde pedido de compra | Sin errores (UniDataPedidosCompra/AlbaranesCompra tocados) |
| D3 | Abrir el diálogo de parámetros de aplicación y aceptar | Sin errores (inMtoPrincipal tocado) |

---

## Criterio de salida de la Fase 0

- Los 4 bloques pasan al 100%.
- Compilación sin hints nuevos.
- (Ya verificado en frío) el ciclo de dependencias pasó de 44 a 14 unidades y
  ningún `UniData*` depende ya de `inMtoPrincipal`.

Cualquier fallo: los cambios son 4 ficheros aislados (`inLibUnitForm`,
`inLibDevExp`, `inMtoGen`, `inMtoPrincipal`) — `git diff`/`git checkout -- <fichero>`
revierte el paso concreto sin afectar al resto.

## Nota para la Fase 1

La Fase 1 (transacciones en borrado de factura, movimientos de almacén, albarán
desde pedido) tocará integridad de datos: su plan de pruebas irá en documento
propio e incluirá pruebas destructivas en BBDD de pruebas (fallo provocado a
mitad de operación, verificación de rollback completo con SELECTs antes/después,
y prueba de concurrencia con dos puestos grabando la misma factura). No empezarla
hasta que esta fase esté validada.
