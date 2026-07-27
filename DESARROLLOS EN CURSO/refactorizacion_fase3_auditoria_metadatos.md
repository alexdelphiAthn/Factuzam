# Fase 3 — Auditoría en frío de metadatos de pantallas (B2/B3)

Fecha: 27/07/2026. En vez de la pasada manual clic a clic, se hizo un
**cruce en frío** de las cuatro fuentes que B2 y B3 dejaron acopladas.
Es más completo que muestrear a mano: cubre las 52 pantallas y los 45
ítems de una vez y no depende de acordarse de pulsar cada menú.

Fuentes cruzadas:

- `fza_winforms` (52 filas del dump modelo): `CALL`, `CAPTION`,
  `MENUITEM`, `UNITF`, `SHORTCUT`, `DATAMODULE`.
- `inMtoCatalogoPantallas.pas`: 52 clases de formulario + 48 de data
  module registradas por código (el registro de B2).
- `inMtoPrincipal.dfm`: ítems de menú reales y su `OnClick`.
- `fza_permisos`: los 60 códigos `menu.%`.

## Lo que está bien (verificado, no tocar)

**Registro de clases (B2) — 100/100 resuelven.** Cada `UNITF_WINF` (52) y
cada `DATAMODULE_WINF` (48) de la BBDD apunta a una clase que (a) está
registrada en `inMtoCatalogoPantallas` y (b) se declara justo en la
unidad cuyo nombre lleva el `QualifiedClassName`. Es decir: el validador
de arranque `TfzaWinF.ComprobarRegistradas` pasa limpio para las 52
filas del modelo. La única excepción es la fila que sobra en la BBDD de
desarrollo (ver abajo), que es precisamente lo que el validador está para
cazar.

**Manejador único (B3) — 45/45 resuelven.** Los 45 ítems de menú cableados
a `MenuGenericoClick` tienen todos su fila en `fza_winforms` con
`MENUITEM_WINF` = el nombre del ítem, así que `CallRegistrado(item)`
devuelve el `CALL` correcto para cada uno. No hay ni un solo clic de
apertura que caiga en `CALL` vacío. Los 2 ítems que se dejaron con
manejador propio (Sesiones vía `mnuCrearArtculosyunpedidoounalbarn` →
`Sesiones1Click`, y `Formasdepago2` → `Formasdepago2Click`) siguen
coherentes: abren por su handler, no por el genérico.

## Lo que está mal (se arregla con scripts)

| # | Qué | Efecto | Script |
|---|---|---|---|
| 1 | `fza_winforms` fila `ArticulosPropiedades` (solo en BBDD dev) apunta a la clase `inMtoArticulosPropiedades.TfrmMtoArticulosPropiedades`, que **no existe** | `ComprobarRegistradas` deja un ERROR en el log en **cada arranque** | `limpiar_winform_articulospropiedades.sql` (ya en disco) |
| 2 | `fza_permisos` código `menu.mnuFormaPagoVenta` | Permiso muerto: el ítem `mnuFormaPagoVenta` ya no existe (solo aparece en `src/Core/__history`, era un ítem renombrado/retirado) ni es un `CALL`. `TienePermiso()` nunca lo consulta | `limpiar_permisos_menu_huerfanos.sql` (nuevo) |

El #1 es el hallazgo real de B2. El #2 es un fantasma de un ítem de menú
retirado: quitarlo no afecta a Formas de Pago, cuyo permiso sigue vivo en
`menu.FormasdePago` y `menu.Formasdepago2`. Los dos DELETE son
idempotentes, con `SELECT` previo, verificación y `ROLLBACK` comentado.

## Lo que está inconsistente pero NO se toca (a propósito)

Tres filas tienen `MENUITEM_WINF` apuntando a un ítem de menú que **no
existe** en el `.dfm`, porque esas pantallas no se abren por menú sino por
atajo o desde otra pantalla:

- `FormasdePago` → `mnuFormasdePago` (se abre con Ctrl+Q).
- `ComprasPlantillas` → `mnuComprasPlantillas` (se abre desde Sesiones).
- `PropiedadesValores` → `mnuPropiedadesValores` (Ctrl+Alt+Y / desde
  Propiedades).

En runtime da igual: `FindComponent('mnuFormasdePago')` devuelve `nil`
exactamente igual que `FindComponent('')`, así que `mnMenuItem` queda a
`nil` en los dos casos y ni `CallRegistrado` ni `CodigoMenu` cambian de
comportamiento. Ponerlas a cadena vacía sería solo cosmético (cero cambio
de runtime), así que no merece un `UPDATE` sobre `fza_winforms` en las
BBDD de clientes.

Aparte, `ComprasSesiones` registra `MENUITEM_WINF='Sesiones1'`, que es el
**submenú contenedor** 'Sesiones', no el ítem que dispara
(`mnuCrearArtculosyunpedidoounalbarn`). Aquí **sí** cambiaría algo si se
tocara: el ítem real coge hoy el permiso `menu.mnuCrearArtculosyunpedidoounalbarn`
(que existe y funciona); si se moviera el `MENUITEM` al ítem real, el
permiso pasaría a `menu.ComprasSesiones` y habría que migrar las filas de
`fza_permisos` de los clientes. No compensa: Sesiones abre y respeta
permiso tal cual está. Se deja.

## Nota fuera del alcance de B2/B3

Hay colisiones de atajo preexistentes (`Ctrl+Alt+F` en Facturas y
Facturas de Compra; `Ctrl+Alt+P` en Pedidos y Pedidos de Compra). No es
cosa del registro ni del manejador único; se anota por si interesa
revisarlo en otra pasada.

## Para aplicar

1. `limpiar_winform_articulospropiedades.sql` — quita la fila muerta y sus
   permisos (`menu.ArticulosPropiedades`). Idempotente.
2. `limpiar_permisos_menu_huerfanos.sql` — quita `menu.mnuFormaPagoVenta`.
   Idempotente.

Ambos en `DESARROLLOS EN CURSO/`. Aplicar a la BBDD de desarrollo y, tras
revisar el `SELECT` previo, a las de clientes. No tocan
`factuzam_original.sql`.
