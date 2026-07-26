# Pruebas funcionales de interfaz — Factuzam recién compilado

Fecha: 26/07/2026. Conduciendo la aplicación en tu equipo.
Build: `Win64\Release\fzam.exe` 1.0.15.202606260100.alpha.
Conexión: **127.0.0.1:3306 (Factuzam)** — desarrollo. Usuario: Administrador.

## Resultado: 26 comprobaciones en pantalla, 0 fallos

### Ronda 1 — navegación y validaciones

| # | Prueba | Qué valida | Resultado |
|---|---|---|---|
| 1 | Arranque y conexión | El build entero con Fases 0–3 + bloque A | **OK** |
| 2 | Menús Compras / Ventas Mayor | Menú principal | **OK** |
| 3 | Compras → Cargar efectos en remesa | Modal unificado, variante compra | **OK — columna "Proveedor"** |
| 4 | Buscar efectos (empresas 012 y 1) | El SELECT nuevo con alias contra la BBDD real | **OK**, sin error |
| 5 | Buscador de empresas (…) | `TBusquedaUtils.EjecutarBusqueda` | **OK** |
| 6 | Ventas Mayor → Cargar efectos | **La misma ventana**, variante venta | **OK — columna "Cliente"** |
| 7 | Ventas Mayor → Borradores | Mto de facturas | **OK** (23 borradores) |
| 8 | Abrir ficha | Detalle cableado por `AsignarMaestroCabecera` | **OK** |
| 9 | Navegar al siguiente registro | **Maestro-detalle** (W1) | **OK**: las líneas siguen a la cabecera |
| 10 | Pestaña Efectos | Apertura perezosa + MasterSource nuevo | **OK** |
| 11 | Pestaña Totales | Cálculo fiscal | **OK**: 65,95 + 13,85 = 79,80 |
| 12 | Nuevo Borrador | `TipoFacturaDefecto` + `OnNuevaFactura` | **OK**: NORMAL + check de stock |
| 13-14 | Grabar sin razón social | V1: mensaje → **salta a "Datos Cliente"** | **OK** (`OnCampoInvalido`) |
| 15-16 | Validación de país y aborto del Post | Encadenado + excepción | **OK**, idéntico al anterior |
| 17 | Cancelar | Sin basura | **OK** |
| 18 | Botón Salir → cerrar pestaña | `WM_FREECONTROL` + `Release` diferido | **OK**, sin AV |
| 19 | Contadores: abrir, ESC en grid, cerrar ×2 | `ShowMto`, `CancelarGrids`, estabilidad | **OK** |

### Ronda 2 — con datos creados para la ocasión

| # | Prueba | Qué valida | Resultado |
|---|---|---|---|
| 20 | Generar efectos desde la factura 000028 (726,00 €) | Diálogo de banco + generación | **OK**: 1 efecto PENDIENTE, vto. 22/02/2026 |
| 21 | Modal de remesas **con datos reales** | **Los 7 alias nuevos del `.dfm`** | **OK: todas las columnas pintan** — A1 / 000028 / 1 / DISTRIBUCIONES VELÁZQU… / 22/02/2026 / 726,00 € / PENDIENTE |
| 22 | Cargar en remesa (crear nueva) | Flujo completo + `TextoOmitidos` de la variante | **OK**: "Cargados 1 efecto(s) en la remesa - / 000001. Omitidos (ya remesados o **cobrados**): 0." |
| 23 | Cierre del modal con mrOk | Handler `CrearParaVenta` de `inMtoPrincipal` | **OK**: abre Remesas de Cobro |
| 24 | Remesa creada | Datos en la pantalla de remesas | **OK**: 000001, ABIERTA, 1 efecto, 726,00 € |
| 25 | Botón "Añadir efecto" desde Remesas | `PrepararRemesaExistente` + `CargarRemesasAbiertas` | **OK**: empresa rellena, modo "Añadir a remesa existente" y **combo preseleccionado "- / 000001 (26/07/2026)"** |
| 26 | Factura con impuestos incluidos (000122) al editar línea | **W3**: `AplicarEdicionPreciosLinea` (movido del DM al form) | **OK: la columna cambia a "Total con IVA"** (en las facturas sin impuestos incluidos se mantiene "Total sin IVA") |

### Las dos pruebas que más valían

- **#21**: el grid del modal unificado pintando datos reales. Cada columna
  enlaza por `FieldName` con un alias que reescribí (`SERIE_FAC_EFECTO`,
  `TERCERO_EFECTO`, …). Un solo alias mal y esa columna habría salido vacía.
- **#3 vs #6 y #22**: la misma ventana dice "Proveedor"/"Cliente" y el mensaje
  final dice "pagados"/"cobrados" según la variante. La unificación con
  `TConfigRemesa` funcionando en vivo.

## Datos de prueba que he dejado en desarrollo

- Factura **A1/000028** (empresa 1): le generé **1 efecto de cobro** de 726,00 €.
- **Remesa de cobro "-" / 000001** (26/07/2026, ABIERTA) con ese efecto dentro.

Si quieres dejarlo como estaba: quita el efecto de la remesa, borra la remesa
000001 y elimina el efecto de la factura 000028.

## Observación (no es regresión)

En el borrador **000033** el desglose por tipo muestra 60,00 € de base Normal
frente a 65,95 € de base imponible total (falta la línea de envío de 5,95 €).
En el 000028 y el 000122 el desglose cuadra perfectamente, así que apunta a
dato persistido antiguo de ese borrador concreto, no al código. Regrabándolo
se confirma.

## Lo que sigue sin probarse en pantalla

- **Compras**: albarán desde pedido, y materializar/revertir sesión.
- **Re-login** repetido y cierre de la app con el monitor SQL visible (bloque A).
- **Impresión** de factura.
- Variante **compra** del modal con datos reales (haría falta una factura de
  compra con efectos pendientes; la lógica ya está validada a nivel de datos).

## Balance de toda la validación

| Capa | Comprobaciones | Fallos |
|---|---|---|
| Datos y contratos (automatizada, demo limpia) | 58 | 0 |
| Interfaz (conduciendo la aplicación) | 26 | 0 |
| Compilación Release/Win64 | 0 errores tras cada bloque | — |
