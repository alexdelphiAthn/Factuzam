# Fecha de aplicacion de descuento en tarifa

## Problema

El descuento de una tarifa vive por linea en `fza_articulos_tarifas`
(`PRECIO_DTO_ARTTAR`, `PORCENTAJE_DTO_ARTTAR`, `PRECIO_FINAL_ARTTAR`). Hasta
ahora, mientras la linea estuviera **vigente** (entre `FECHA_DESDE_ARTTAR` y
`FECHA_HASTA_ARTTAR`, o sin fin) y **activa**, el descuento se aplicaba
**siempre**.

El cliente quiere acotar *cuando* se aplica el descuento sin tener que abrir
una segunda tarifa (p. ej. una de REBAJAS). Como ya existe la **sesion de
cambio de precios**, con una sola tarifa basta: se le anaden dos fechas que
definen la ventana de rebajas.

## Solucion

Dos fechas a nivel de **cabecera de tarifa** (`fza_tarifas`, sufijo `TAR`):

| Columna                | Tipo   | Significado                              |
|------------------------|--------|------------------------------------------|
| `FECHA_DESDE_DTO_TAR`  | `date` | Inicio de aplicacion del descuento       |
| `FECHA_HASTA_DTO_TAR`  | `date` | Fin de aplicacion del descuento          |

La ventana es **de cabecera**: gobierna todos los descuentos de esa tarifa
(misma temporada de rebajas para todos sus articulos).

### Semantica (la evalua el codigo en venta)

- Ambas `NULL` → sin ventana: el descuento se aplica **siempre** (clasico, 100%
  retrocompatible).
- Una `NULL` → cota abierta por ese lado.
- Fecha del documento **fuera** de la ventana → **no** se aplica el descuento:
  se cobra `PRECIO_SALIDA` y se anula `% / importe` de descuento de la linea.

Afecta a **venta en caja** y **venta mayor / factura**.

## Donde se aplica

- `inLibArticulosResolver.pas`: predicado comun
  `DescuentoEnVentana` (puro) + `DescuentoTarifaVigente` (consulta la cabecera).
  `ResolverPrecio` (precio autoritativo de **caja**) anula el descuento fuera de
  ventana.
- `UniDataFacturas.pas` → `CopiarArticuloaLinea` (**venta mayor / factura**):
  si la fecha de la factura cae fuera de la ventana, cobra `PRECIO_SALIDA` y
  pone descuento a 0.

Robusto: si la BBDD aun no tiene las columnas, el predicado degrada al
comportamiento clasico (descuento siempre aplicado).

## Sesion de cambios de tarifa

`fza_tarifas_cambios` recibe la misma ventana (sufijo `TARC`):
`FECHA_DESDE_DTO_TARC` / `FECHA_HASTA_DTO_TARC`. Al **aplicar** la sesion, si se
informa al menos una de las dos, se fija la ventana en la **tarifa destino**
(`CODIGO_TAR_DESTINO_TARC`). Si ambas quedan vacias, no se toca la ventana
existente de la tarifa.

## UI

- Mantenimiento de tarifas (`inMtoTarifas`): dos editores de fecha en la
  cabecera (`Dto. desde` / `Dto. hasta`), sobre la vista `vi_tarifas`.
- Sesion de cambios (`inMtoTarifasCambios`): dos editores de fecha en la
  cabecera de la sesion.

## Idempotencia

- Columnas: se anaden solo si no existen (`INFORMATION_SCHEMA.COLUMNS`).
- `vi_tarifas`: `CREATE OR REPLACE`.
- No se toca `factuzam_original.sql`.
