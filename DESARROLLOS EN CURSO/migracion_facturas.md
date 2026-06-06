# Migración de facturas de venta (fase 2 de ventas)

Reconstruye el detalle de venta del legacy como **factura SIMPLIFICADA** en
Factuzam. Nuevo dominio del migrador (`src/utilmigsqlsrv/inLibMigFacturas.pas`).
Complementa a `inLibMigVentas` (capa de caja). No requiere cambios de esquema.

| Origen | Destino |
|---|---|
| `occaj` (operación de venta) | `fza_facturas` (cabecera, una por operación) |
| `occajarp` (líneas) | `fza_facturas_lineas` |

## Alcance

Solo operaciones de **venta**: `occaj.TipoDoc='VE'` y `Tipo<>'C'`. Se
excluyen cobros (`C`, van como adelanto en ventas), albaranes (`AL`, van a
depósito) y traspasos (`TR`/`AT`).

## Numeración (determinista, trazable)

- `SERIE_FAC` = `'<Ejercicio>.<Serie>'` (p.ej. `2001.B1`).
- `NUMERO_FAC` = `'<Almacen>-<Caja>-<Operacion>'`.

Único por empresa/serie (la `Operacion` es única dentro de empresa/almacén/
caja). En instalación **multiempresa** habría que prefijar la empresa.

Cada **línea** enlaza:
- con su operación de caja: `NUMERO_OPERACION_FACLIN` = `Operacion` a 8 dígitos
  (+ `CODIGO_ALM/CAJA/EMP`), igual que `fza_caja_operaciones`.
- con su movimiento de almacén: `NUMERO_MOV_FACLIN` = `'MH'+NumeroMovArt`
  (mismo prefijo que `inLibMigMovimientos`), cuando `occajarp.NumeroMovArt>0`.

## Mapeo de líneas (`occajarp` → `fza_facturas_lineas`)

| Destino | Origen |
|---|---|
| `CODIGO_ART_FACLIN` | `Articulo` (NULL si genérico `0`/vacío) |
| `CODIGO_UNIDAD_FACLIN` | `ARTICULO/COLOR/TALLA` (slot de color de `occolor`) |
| `TIPO_ARTICULO_FACLIN` | `ESTANDAR`, o `SERVICIO` si artículo genérico |
| `CANTIDAD_FACLIN` | `Cantidad` |
| `PRECIO_VENTA_SIVA_ARTICULO_FACLIN` | `PrecioSIva` |
| `PRECIO_VENTA_CIVA_ARTICULO_FACLIN` | `PrecioCIva` |
| `PORCENTAJE_IVA_FACLIN` | `PorIva` |
| `PORCENTAJE_DTO_FACLIN` | `PorDto` |
| `TOTAL_FACLIN` / `TOTAL_FAC_SIVA_FACLIN` | `NetoCIva` / `NetoSIva` |
| `DESCRIPCION_ARTICULO_FACLIN` | `Descripcion` |
| `CODIGO_VENDEDOR_FACLIN` | `Vendedor` |

## Cabecera (`occaj` → `fza_facturas`)

- `TIPO_FAC='SIMPLIFICADA'`, `ESCONSOLIDADA_FAC='S'`, `FORMA_PAGO_FAC='CONTADO'`.
- `FECHA_FAC` = `FechaOpe` (o `Fecha`).
- `CODIGO_CLI_FAC` = `Cliente` (o `'0'` público).
- `CODIGO_CAJERO_FAC` = `Vendedor`; `CODIGO_ALM/CAJA_FAC` + `NUMERO_OPERACION_FAC`.
- **IVA por bandas N/R/S/E:** se usan las 4 bandas que el legacy trae en
  `occaj` (`BaseImp1-4`/`PorcenIva1-4`/`CuotaIVA1-4`), clasificando cada una
  por su % (`0`=Exento, `<6`=Super, `<13`=Reducido, resto=Normal) y
  acumulando base+cuota en su banda. La cuota se calcula si el legacy no la
  trae (filas antiguas con `CuotaIVA` NULL). Si no hay bandas pero sí `Neto`,
  se deriva una banda única del total. `TOTAL_LIQUIDO_FAC=Neto`. Las **líneas**
  llevan además su IVA real por fila (`occajarp.PorIva`).

## Idempotencia

`fza_facturas` tiene PK `(NUMERO_FAC, SERIE_FAC)`, pero por consistencia con
ventas la migración borra al arrancar lo migrado por el usuario
(`USUARIO_ALTA`) en `fza_facturas_lineas` y `fza_facturas` y reinserta.

## Cómo ejecutarlo

Dominio **"Facturas de venta (occajarp)"** (wave 3). Requisitos: Almacenes,
Clientes y SKUs migrados. Coherente con "Ventas / Caja" (comparten
`NUMERO_OPERACION`) y con "Movimientos" (comparten `NUMERO_MOV`).

## Pendiente / a revisar

- Recargo de equivalencia (RE) en la cabecera: hoy no se mapea (las bandas
  RE quedan a NULL). El desglose de IVA N/R/S/E ya está hecho.
- Estado fiscal de la cabecera (`FASE_FAC`, Verifactu, XML): se deja
  `SIMPLIFICADA`/consolidada sin firma. Decidir política para histórico.
- Datos denormalizados de empresa/cliente en la cabecera (razón social,
  NIF, dirección…): hoy se dejan a NULL; rellenar si se quiere reimprimir.
- Líneas de cobro/anticipo (`ANTICIPO`) ligadas a depósitos: no se generan
  aquí (los cobros se migran como operación `CB` en ventas).
