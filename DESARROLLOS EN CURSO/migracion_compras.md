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

## Modelo: una línea por SKU + `ID_AC_PIVOT` (como el nativo)

Una línea Factuzam por cada fila del legacy (un SKU concreto
`Articulo/Color/Talla`), con su almacén y su cantidad en la propia línea.
**Esto NO es una simplificación: es exactamente como Factuzam materializa
una compra.** La materialización nativa de una sesión de compra
(`inLibComprasSesionesMaterializar.InsertarLineaPedidoCompra`) inserta también
**una línea por SKU** y **no** rellena las tablas de celdas
(`fza_*_compra_celdas`) — las celdas son solo una ayuda transitoria del Mto
para editar en modo "tallas en horizontal", no el almacenamiento canónico.

Lo que hace que la rejilla de tallas del Mto esté disponible es el
**`ID_AC_PIVOT_*LIN`** de la línea (el conjunto/tallaje del artículo). Por eso
cada línea lleva su `ID_AC_PIVOT`, resuelto del tallaje asignado al artículo
(`fza_articulos_conjuntos_asign` con `ID_VA_ACA='TAL'`, cargado en un mapa
artículo→`ID_AC` una sola vez). Artículo sin tallaje (escalar) → `ID_AC_PIVOT`
queda a `NULL`. Resultado: un pedido/albarán migrado se comporta en el Mto
**igual** que uno creado por la aplicación.

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
su `TIPO_IVA_ARTICULO` clasificado desde ese porcentaje (`0`=Exento, `<6`=
Super, `<13`=Reducido, resto=Normal). Esto es importante porque las facturas
de compra generadas desde albarán copian ese campo de la línea del albarán.

## Forma de pago

Pedidos y albaranes guardan `FORMA_PAGO_*` con el código legacy `TipoEfecto`
cuando viene informado. Si no hay `TipoEfecto`, se conserva el texto histórico
`FormaPago` como fallback. Las facturas de compra generadas desde albarán
copian `FORMA_PAGO_ALBC` a `FORMA_PAGO_FACC`, y los efectos usan ese valor para
repartir vencimientos.

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

- **Celdas (`fza_*_compra_celdas`)**: no se generan **a propósito** — la
  materialización nativa tampoco las crea (almacena una línea por SKU con su
  `ID_AC_PIVOT`). El Mto las construye al editar en modo pivote. No es una
  carencia de la migración.
- **Facturas de compra**: no se migran en esta pasada; por eso los albaranes
  quedan `CERRADO` y no `FACTURADO`, y no se rellena `NUMERO_FAC_ALBC`.
- **Enlace movimiento ↔ albarán (`REF_MOV`)**: la línea de albarán legacy no
  guarda el `NUMERO_MOV` del movimiento que generó, así que no se enlaza la
  entrada de stock con su albarán (el stock entra igualmente por Movimientos).
