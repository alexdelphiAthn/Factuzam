# Migración de compras (pedidos, albaranes y facturas)

Importa la cadena de **compras** del legacy a Factuzam. Nuevo dominio del
migrador (`src/utilmigsqlsrv/inLibMigCompras.pas`). Requiere que el destino
tenga las tablas de compras y la ampliación de temporada de factura:
`DESARROLLOS EN CURSO/facturas_compra_temporada.sql`.

| Origen (SQL Server) | Destino (MariaDB) |
|---|---|
| `dbo.ocped` (TipoDoc `'PP'`)    | `fza_pedidos_compra` (cabecera) |
| `dbo.ocpedarp`                  | `fza_pedidos_compra_lineas` |
| `dbo.ocalbpro` (TipoDoc `'AE'`) | `fza_albaranes_compra` (cabecera) |
| `dbo.ocalbproarp`               | `fza_albaranes_compra_lineas` |
| `dbo.ocfacpro`                  | `fza_facturas_compra` (cabecera) |
| `dbo.ocfacproart` / `ocalbproarp` facturado | `fza_facturas_compra_lineas` |

## Temporada de cabecera

Pedidos y facturas conservan la temporada de cabecera del legacy. En pedidos
sale de `ocped.Temporada` y en facturas de `ocfacpro.Temporada`; ambos códigos
se traducen por `octem.Nombre` y se enlazan con `fza_propiedades_valores`
(`ID_PROP_PV='TEMPORADA'`). En facturas el valor queda en
`ID_PV_TEMPORADA_FACC`, añadido por
`DESARROLLOS EN CURSO/facturas_compra_temporada.sql`.

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
  Si el legacy trae `NroFactura`, queda como `FACTURADO` y enlazado a la
  factura importada.

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
SKUs (waves 0-2).

Dominio **"Facturas de compra (ocfacpro)"**, **wave 5**. Entra después de
albaranes para poder enlazar `NUMERO_FAC_ALBC` / `SERIE_FAC_ALBC` y marcar
líneas facturadas cuando `ocfacproart` trae referencia de albarán.
Si una factura no tiene detalle en `ocfacproart`, sus líneas se reconstruyen
desde `ocalbproarp` usando `NroFactura` / `SerieFactura` / `EjercicioFactura`.

Después de facturas entran los dominios de cartera de pagos:
- **"Bancos de cargo por empresa (ocbanrem)"**: crea `fza_empresas_bancos`
  desde las cuentas usadas en facturas, efectos y remesas de compra.
- **"Tipos de efecto de compra (octipefe)"**: conserva los códigos legacy de
  tipo de efecto en `fza_tipos_efecto`.
- **"Efectos de compra (ocefepro/occobpro)"**, **wave 6**: importa
  vencimientos y concilia los pagos legacy sobre los propios efectos. Si un
  efecto viene parcialmente pagado, lo divide en pagado y pendiente. La
  referencia documental del efecto queda en `REFERENCIA_DOCUMENTO_EFEC` para
  que las conciliaciones posteriores puedan apuntar al efecto resumen.
- **"Remesas de pago (ocrempro)"**, **wave 7**: importa remesas y recalcula
  contador/total desde los efectos enlazados.

## Pendiente / a revisar

- **Celdas (`fza_*_compra_celdas`)**: no se generan **a propósito** — la
  materialización nativa tampoco las crea (almacena una línea por SKU con su
  `ID_AC_PIVOT`). El Mto las construye al editar en modo pivote. No es una
  carencia de la migración.
- **Enlace movimiento ↔ albarán (`REF_MOV`)**: la línea de albarán legacy no
  guarda el `NUMERO_MOV` del movimiento que generó, así que no se enlaza la
  entrada de stock con su albarán (el stock entra igualmente por Movimientos).
