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
- `NUMERO_FAC` = `'<Almacen>-<Caja>-<NroDoc>'` (p.ej. `12-1-61258`).

`NroDoc` es el **nº de documento/ticket** del legacy (`occaj.NroDoc`), el que
ve el usuario en el ticket — **no** la `Operacion` (id interno, otro contador).
Antes se usaba `Operacion` y el número no coincidía con el del ticket original.
Único por almacén/caja dentro de su `SERIE_FAC` (= ejercicio.serie); si el
legacy reusara `NroDoc` dentro de la misma serie/ejercicio, el `INSERT IGNORE`
descartaría el duplicado (poco probable, pero a vigilar). En instalación
**multiempresa** habría que prefijar la empresa.

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
- **Recargo de equivalencia (RE):** se acumula en la **misma banda** que su
  IVA, desde `occaj.PorcenRecargo1-4`/`CuotaRE1-4` (cuota calculada si viene
  NULL). `TOTAL_IMPUESTOS_FAC` = IVA + RE de todas las bandas. En venta
  minorista el RE suele ser 0.

## Idempotencia y rendimiento

`fza_facturas` tiene PK `(NUMERO_FAC, SERIE_FAC)` y `fza_facturas_lineas`
`(NUMERO_FAC, SERIE_FAC, LINEA)`. La migración borra al arrancar lo migrado
por el usuario (`USUARIO_ALTA`) en ambas tablas y reinserta.

Cabeceras y líneas se vuelcan con **`INSERT IGNORE` por lotes** (`TBulkInsert`,
2000 filas/lote), no fila a fila: con ~774k líneas el round-trip por fila era
inviable. No hay FK física entre líneas y cabecera (es FK *lógica*), así que
cada buffer se vuelca por su cuenta. Un fallo de lote se registra y la
migración continúa (antes un único error abortaba el dominio entero con un
`raise`).

**Dos pasadas, sin `ORDER BY`:** las cabeceras se leen de `occaj` (una fila por
operación) y las líneas de `occajarp`, en cursores separados. El `ORDER BY` que
antes agrupaba las líneas por operación obligaba a SQL Server a **ordenar las
~774k filas anchas del JOIN antes de devolver la primera**, y el `Open` del
cursor se quedaba minutos "petado" en `0 / 774223`. Sin orden, cada cursor
arranca al instante y la barra avanza desde la primera fila; la cabecera ya no
necesita deduplicar (sale una por fila de `occaj`). Se ven dos fases en el log:
`facturas 1/2: cabeceras` y `facturas 2/2: lineas`.

## Enlaces post-inserción (al final del dominio)

Tras las dos pasadas, `EnlazarFacturas` ejecuta dos `UPDATE` set-based:

1. **Empresa emisora + flags**: rellena en la cabecera los datos del emisor
   (`RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, dirección, población…) desde
   `fza_empresas` (`LEFT JOIN` por `CODIGO_EMP`), que antes quedaban vacíos
   (pestaña "Datos Empresa Emisora" en blanco). Además fija
   `ESFECHADEENTREGA_FAC`, `ESDESCRIPCIONES_AMP_FAC` y `ESCREARARTICULOS_FAC`
   a `'N'`, y `ESRETENCIONES_CLIENTE_FAC` a `'N'` (venta detalle: el cliente no
   tiene IRPF/retención; la columna trae `DEFAULT 'S'` en el esquema).
1b. **Datos del cliente**: rellena `RAZON_SOCIAL_CLIENTE_FAC`,
   `NIF_CLIENTE_FAC`, contacto y dirección (`*_CLIENTE_FAC`) desde
   `fza_clientes` con `JOIN` (no `LEFT`) por `CODIGO_CLI_FAC`: las facturas a
   público/anónimo (cliente `'0'` o inexistente) no casan y se dejan sin datos
   de cliente, que es lo correcto para un ticket simplificado.
2. **Movimiento → factura**: pone `TIPO_DOC_REF_MOV='FC'` y
   `SERIE/NUMERO/LINEA_DOC_REF_MOV` en `fza_movimientos_almacen` uniendo por
   `NUMERO_MOV` (= `fza_facturas_lineas.NUMERO_MOV_FACLIN`). Sin esto la
   pestaña "Movimientos" de la factura sale vacía (la app filtra por esas
   columnas `*_DOC_REF_MOV`).

El **ticket** reimpreso enlaza operación → factura por
`fza_caja_operaciones.SERIE_FAC_OPCAJA`/`NUMERO_FAC_OPCAJA`; por eso la
migración de **Ventas** rellena esas columnas con la MISMA clave de factura
(`'<Ejercicio>.<Serie>'` / `'<Alm>-<Caja>-<NroDoc>'`) en las operaciones de
venta.

La pestaña **"Movimientos"** de la factura lista `vi_movimientos` filtrando por
`TIPO_DOC_REF_MOV='FC'` + `SERIE/NUMERO_DOC_REF_MOV`, y **muestra y ordena por
`LINEA_MOV`** (no por `LINEA_REF_MOV`). Por eso `EnlazarFacturas` fija, además
de las columnas `*_DOC_REF_MOV`, `m.LINEA_MOV = l.LINEA_FACLIN`: así cada
movimiento de venta queda alineado con su línea de factura (en la migración
`LINEA_MOV` nacía siempre `'0001'`).

## Cómo ejecutarlo

Dominio **"Facturas de venta (occajarp)"** (**wave 4**, después de Movimientos
de la wave 3: el enlace `*_DOC_REF_MOV` necesita los movimientos ya migrados).
Requisitos: Almacenes, Empresas, Clientes, SKUs y Movimientos migrados.

## Pendiente / a revisar

- IVA y RE por bandas N/R/S/E en la cabecera: **hechos** (desde las 4 bandas
  del legacy). Queda como afinado opcional el resto del estado fiscal
  (`FASE_FAC`/Verifactu/XML) y los datos denormalizados de empresa/cliente.
- Estado fiscal de la cabecera (`FASE_FAC`, Verifactu, XML): se deja
  `SIMPLIFICADA`/consolidada sin firma. Decidir política para histórico.
- Datos denormalizados de empresa/cliente en la cabecera (razón social,
  NIF, dirección…): hoy se dejan a NULL; rellenar si se quiere reimprimir.
- Líneas de cobro/anticipo (`ANTICIPO`) ligadas a depósitos: no se generan
  aquí (los cobros se migran como operación `CB` en ventas).
