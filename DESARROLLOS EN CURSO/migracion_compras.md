# Migración de compras (pedidos y albaranes de entrada)

Importa la cadena de **compras** del legacy a Factuzam. Nuevo dominio del
migrador (`src/utilmigsqlsrv/inLibMigCompras.pas`). No requiere cambios de
esquema: las tablas destino ya existen (ver `pedidos_compra.sql` y
`albaranes_compra.sql`).

| Origen (SQL Server) | Destino (MariaDB) |
|---|---|
| `dbo.ocped` (TipoDoc `'PP'`)    | `fza_pedidos_compra` (cabecera) |
| `dbo.ocpedarp`                  | `fza_pedidos_compra_lineas` |
| `dbo.ocalbpro` (TipoDoc `'AE'`) | `fza_albaranes_compra` (cabecera) |
| `dbo.ocalbproarp`               | `fza_albaranes_compra_lineas` |

## Modelo PLANO (decisión del usuario)

Una línea Factuzam por cada fila del legacy (un SKU concreto
`Articulo/Color/Talla`), con su almacén en la propia línea. **No** se generan
celdas (`fza_*_compra_celdas`, la rejilla pivotada de tallas): estos pedidos y
albaranes **no traen distribución** por tallas, así que la cantidad queda en la
línea y su almacén. Las celdas se dejan para una migración futura con
distribución incluida.

## Numeración (determinista, trazable)

Misma forma que el resto de documentos:
- `SERIE`  = `'<Ejercicio>.<Serie>'` (p.ej. `2007.90`).
- `NUMERO` = `NroPedido` / `NroAlbaran` a 6 dígitos (`Format('%.6d')`).

PK destino: `(NUMERO_PEDC, SERIE_PEDC)` / `(NUMERO_ALBC, SERIE_ALBC)` y las
líneas añaden `LINEA` (= `Orden` del legacy a 4 dígitos).

## Proveedor y empresa emisora

- **Proveedor**: ya viene **denormalizado** en `ocped`/`ocalbpro`
  (`Proveedor`, `RazonSocial`, `NIF`, dirección…). Se copia tal cual a las
  columnas `*_PRV_*` de la cabecera.
- **Empresa emisora**: se rellena al final (`EnlazarEmpresaCompra`) desde
  `fza_empresas` (`JOIN` por `CODIGO_EMP`), igual que en facturas de venta —
  razón social, NIF, móvil, email, dirección, población, provincia y CP.

## Almacén

- Cabecera: `CODIGO_ALM_*` = abreviatura del almacén del documento (`ocalm`,
  fallback al número de almacén).
- Línea: `CODIGO_ALMACEN_*LIN` = abreviatura del almacén de **la propia
  línea** (un pedido/albarán puede repartir líneas en varios almacenes).

## SKU / color

`CODIGO_UNIDAD_*LIN` = `ARTICULO/COLOR/TALLA` con los mismos placeholders que
el resto de la migración (color vacío → `0`, talla vacía/`0`/`UNI` → `UNI`),
resolviendo el slot de color con la descripción canónica de `occolor`
(vía `ocartcol`); si es `INDEFINIDO` o vacío se usa el color crudo de la línea.
En pedidos se guarda además `COLOR_TEXTO_PEDCLIN` (texto libre del color).

## IVA (bandas N/R/S/E)

Cabecera: las 4 bandas del legacy (`ImpBaseImp{i}` / `PorIVA{i}` /
`CuotaIVA{i}`, `i=1..4`) se clasifican por su % (`0`=Exento, `<6`=Super,
`<13`=Reducido, resto=Normal) y se acumula la cuota en su banda (calculándola
si el legacy la trae a 0). Los totales (`TOTAL_BASES`, `TOTAL_IMPUESTOS`,
`TOTAL_LIQUIDO`) salen de los importes del propio documento legacy
(`ImpBaseImp`, `TotalIVA`, `ImpPedido`/`ImpAlbaran`). En compra **no** hay
recargo de equivalencia en la cabecera. Cada línea lleva su `PORCENTAJE_IVA` y
`TIPO_IVA_ARTICULO='N'` (literal, igual que artículos y facturas).

## Estado

- **Pedido** (`ESTADO_PEDC`): según lo recibido frente a lo pedido —
  `ABIERTO` (nada recibido), `PARCIAL` (algo) o `RECIBIDO` (todo), comparando
  `CantidadPed` vs `CantidadRcbda` de la cabecera.
- **Albarán** (`ESTADO_ALBC`): **`CERRADO`** siempre. Un albarán histórico es
  mercancía YA recibida con su stock ya migrado por el dominio de
  **Movimientos** (`ocmovarp`). El Mto de compras maneja la transición
  `ABIERTO↔CERRADO` (CERRADO = stock generado), así que se deja `CERRADO`.
  **No** se usa `FACTURADO`: no migramos facturas de compra en esta pasada y
  dejaría una referencia de factura colgando.

## Enlace albarán → pedido

Si el albarán legacy referencia un pedido (`NroPedido > 0`), la cabecera y las
líneas rellenan `NUMERO_PED_ALBC`/`SERIE_PED_ALBC` (y `NUMERO_PEDC_ALBCLIN`/
`SERIE_PEDC_ALBCLIN` en la línea) con la **misma clave** que genera este módulo
para el pedido (`'<Ejercicio>.<Serie>'` / `NroPedido` a 6 dígitos).

## Idempotencia y rendimiento

Cada procedimiento **borra al arrancar** lo migrado por el usuario
(`USUARIO_ALTA`) en su par cabecera/líneas y reinserta. Cabeceras y líneas se
vuelcan con **`INSERT IGNORE` por lotes** (`TBulkInsert`, 2000 filas/lote), en
**dos pasadas sin `ORDER BY`** (cada cursor arranca al instante; misma lección
que facturas: un `ORDER BY` sobre el JOIN obligaría a ordenar todo antes de la
primera fila). Un fallo de lote se registra y la migración continúa.

## Cómo ejecutarlo

Dominios **"Pedidos de compra (ocped)"** y **"Albaranes de compra
(ocalbpro)"**, **wave 3**. Solo necesitan Empresas, Almacenes, Proveedores y
SKUs (waves 0-2); **no** dependen de Movimientos ni de Facturas, así que
corren en paralelo con ellos.

## Pendiente / a revisar

- **Distribución por tallas (celdas)**: no se generan
  `fza_*_compra_celdas`. Pendiente para migraciones con distribución.
- **Facturas de compra**: no se migran en esta pasada; por eso los albaranes
  quedan `CERRADO` y no `FACTURADO`, y no se rellena `NUMERO_FAC_ALBC`.
- **Enlace movimiento ↔ albarán (`REF_MOV`)**: la línea de albarán legacy no
  guarda el `NUMERO_MOV` del movimiento que generó, así que no se enlaza la
  entrada de stock con su albarán (el stock entra igualmente por Movimientos).
