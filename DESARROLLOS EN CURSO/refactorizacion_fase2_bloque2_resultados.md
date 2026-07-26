# Fase 2, bloque 2 — Modal de remesas unificado (compra + venta)

Fecha: 26/07/2026.

## Cambio

`inMtoModalCargarEfectosRemesa` es ahora un único formulario parametrizado que
sustituye al par clónico al 99% (`...Remesa` / `...RemesaVenta`):

- **`TConfigRemesa`** (record): tablas de efectos/remesas, sufijos de campo
  (EFEC/EFV, REMC/REMV), campos de factura y tercero, SPs (`PRC_REMC_*` /
  `PRC_REMV_*`), nombre del parámetro del efecto y literal "pagados/cobrados".
- **Alias neutros en el SELECT** (`SERIE_FAC_EFECTO`, `TERCERO_EFECTO`,
  `SERIE_REMESA`…): el mismo `.dfm` sirve para ambas variantes; la columna
  `colPrv` pasa a `colTercero` y su caption ("Proveedor"/"Cliente") se pone en
  runtime.
- **`Configurar(AConfig)`** aplica la variante tras el `Create` (el SQL ya no
  se construye en `FormCreate`, que por defecto deja la variante compra —
  comportamiento histórico de la unidad). Fábricas **`CrearParaCompra`** /
  **`CrearParaVenta`** para los llamantes.
- `PrepararNuevaRemesa` (antes solo en la variante venta) ahora disponible en
  ambas.

Llamantes actualizados: `inMtoRemesasCompra` (1 sitio), `inMtoRemesasVenta`
(2 sitios + uses), `inMtoPrincipal` (2 sitios + uses). `fzam.dpr` pierde la
unidad Venta. Los ficheros `inMtoModalCargarEfectosRemesaVenta.pas/.dfm` están
en `_to_delete/` (no borrados, por si quieres conservarlos en el histórico
antes de eliminarlos).

Balance: −2 ficheros, ~370 líneas duplicadas eliminadas; a cambio ~70 líneas
de configuración explícita en la unidad única.

## Compilación (ejecutada en tu máquina)

Lanzada con tu `compilar_release_win64.cmd` (colocado en la raíz del repo)
mediante control remoto del escritorio. Resultado en
`resultado_build_release_win64.txt`:

- **0 errores**. 307.826 líneas, 16,2 s, `fzam.exe` Win64 Release regenerado.
- 10 warnings y ~100 hints, todos preexistentes (variables no usadas, casts
  AnsiString→string…); ninguno nuevo en las unidades tocadas por la
  refactorización ni en `inLibImpuestosComun`.

Nota sobre el script: la línea `echo EXITCODE=%ERRORLEVEL%>> "%LOG%"` nunca
escribe el valor — en cmd, el dígito expandido pegado a `>>` se interpreta
como redirección de handle. Arreglo sugerido:
`set "EC=%ERRORLEVEL%"` y luego `echo EXITCODE=%EC% >> "%LOG%"`.

## Plan de pruebas UI (manual — toca pantallas)

BBDD de pruebas. El objetivo es que AMBAS variantes se comporten exactamente
como antes de la unificación.

| # | Prueba | Resultado esperado |
|---|---|---|
| R1 | Menú principal → Cargar efectos (compra): buscar por empresa | Grid con efectos de compra pendientes, columna "Proveedor" |
| R2 | Igual con Cargar efectos de venta | Efectos de venta, columna "Cliente" |
| R3 | Compra: crear remesa nueva con 2 efectos marcados | Remesa REMC creada, mensaje "…ya remesados o pagados: N" |
| R4 | Venta: crear remesa nueva con 2 efectos | Remesa REMV creada, mensaje "…o cobrados: N" |
| R5 | Añadir efectos a remesa EXISTENTE desde el Mto de Remesas de compra (botón Añadir efecto) | El modal abre preseleccionando la remesa; efectos añadidos |
| R6 | Igual desde Remesas de venta, y también el flujo "sin remesa seleccionada" (CrearRemesaDesdeEfectos con `PrepararNuevaRemesa`) | La empresa llega rellenada; al aceptar, el grid localiza la remesa nueva |
| R7 | Combo de remesas existentes muestra serie/número/fecha en ambas variantes | Formato "SERIE / NUMERO (dd/mm/yyyy)" |
| R8 | Abrir el `.dfm` en el IDE (una vez) | El diseñador carga sin avisos de propiedades desconocidas |

Ojo con el IDE: RAD Studio estaba abierto durante los cambios — si tenía
alguna de estas unidades en el editor, ciérralas SIN guardar para no pisar
las versiones nuevas del disco.

## Estado de la Fase 2

| Bloque | Estado |
|---|---|
| 1. `inLibImpuestosComun` (14 funciones) | Hecho, compilado |
| 2. Modal de remesas unificado | Hecho, compilado — pendiente pruebas UI R1–R8 |
| 3. Fusión `CrearAlbaranDesdePedido` compras (2 variantes → 1) | Pendiente |
| 4. Conversión IVA incl./excl. única + bug `AsInteger` | Pendiente |
