# Migración de ventas / caja (occaj, occajarp)

Migra la capa de **caja** del legacy (`dbo.occaj` cabecera + `dbo.occajarp`
líneas) a Factuzam. Nuevo dominio del migrador Delphi
(`src/utilmigsqlsrv/inLibMigVentas.pas`). No requiere cambios de esquema.

---

## Qué migra (primera versión)

| Origen | Destino |
|---|---|
| `occaj` (cabecera de operación) | `fza_caja_operaciones` |
| columnas de pago de `occaj` | `fza_caja_pagos` (formas de pago) |
| operaciones `AL` | `fza_depositos_cliente` + operación `DE` |

**Fase 2 (implementada aparte en `inLibMigFacturas.pas`):** reconstrucción
de las líneas de venta de `occajarp` como `fza_facturas` /
`fza_facturas_lineas`. El stock de esas ventas YA entra por la migración de
**Movimientos** (`ocmovarp`); este dominio (ventas) solo migra la capa de
caja (operaciones + pagos + depósitos). Ver `migracion_facturas.md`.

---

## Mapeo de tipo de operación (`occaj.TipoDoc`/`Tipo` → `TIPO_OPERACION_OPCAJA`)

Confirmado con datos reales (50 últimas filas de occaj):

| Legacy | → Factuzam | Notas |
|---|---|---|
| `AL` (Tipo `A`) | **`DE`** | Albarán a cliente → **depósito**. Crea `fza_depositos_cliente`. |
| Tipo `C` (cobro) | **`CB`** | Cobro a cuenta → **adelanto**. Se enlaza al depósito del cliente. |
| `TR` (Tipo `T`) | `TR` | Traspaso. `ESTRASPASO='S'` + almacén contra (EmpresaDes/AlmacenDes). |
| `AT` | `AT` | Traspaso entre empresas. |
| Tipo `L` | `VL` | Vale emitido. |
| resto (`VE`, Tipo `V`/`P`...) | `VE` | Venta. |

Cumple la regla del usuario: **"las operaciones AL se convierten en
depósitos y los CB contiguos en adelantos"**.

### Depósitos y adelantos (AL → DE + CB)

- Cada `AL` abre un **depósito** (`fza_depositos_cliente`, `ESTADO='PENDIENTE'`)
  con la PRIMERA línea de artículo de `occajarp` (artículo, SKU, precio) y se
  enlaza a su operación `DE` vía `ID_DEPOSITO_OPCAJA`. ID determinista:
  `DM<empresa>-<caja>-<operacion>`.
- Los **cobros** (`CB`) se enlazan al **último depósito abierto del mismo
  cliente** (heurística de "contiguo"), manteniendo en memoria un mapa
  cliente→depósito durante el barrido cronológico.

**Comportamiento:**
- `AL` multilínea: se crea **un depósito por línea de artículo** (ID
  `DM<emp>-<alm>-<caja>-<op>-<linea>`, con el almacén porque `Operacion` se
  numera por empresa/almacén/caja); el `DE` se enlaza al primero.
- Los cobros (`CB`) **reparten** su importe (waterfall) entre los depósitos
  `PENDIENTE` del cliente —en orden de creación, rellenando cada uno hasta su
  `PRECIO_VENTA_DEP`—, **acumulan** en `IMPORTE_ANTICIPO_DEP` y dejan cada
  depósito **`CERRADO`** al alcanzar su precio.
- **Cobro sin cliente**: hereda el cliente del **documento adyacente** (último
  documento con cliente en la misma caja), que es como el legacy enlaza el
  cobro con su albarán/cuenta. Si aun así no hay cliente, el `CB` queda suelto.

Todo esto es afinable en una segunda pasada cuando se decida la política
exacta de reconstrucción de depósitos.

---

## Formas de pago

El legacy guarda el desglose en **columnas** de `occaj` (no en líneas).
Cada columna no nula genera una línea en `fza_caja_pagos`:

| Columna occaj | `CODIGO_FP_CFP` |
|---|---|
| `Efectivo` | `EFE` |
| `Tarjeta` | `TARJ` |
| `ValeTienda` | `VALE` |
| `ValePromocion` | `VALE` |

`EFE` y `TARJ` ya existen en el seed `fza_caja_formas_pago`. La forma de
pago `VALE` (vales de tienda) se asegura al arrancar con un `INSERT IGNORE`.
No se migran `Euros` (redundante con `Efectivo` en la época del euro) ni
`ValeEmitido` (es un vale entregado como cambio, no un cobro).

---

## Resolución de códigos

- `CODIGO_EMP` = `occaj.Empresa` (entero como texto).
- `CODIGO_ALM` = `ocalm.Abreviatura` del almacén, fallback al número.
- `CODIGO_CAJA` = `occaj.Caja`.
- `NUMERO_OPERACION` = `occaj.Operacion` a 8 dígitos.
- `CODIGO_EMPLEADO` = `occaj.Vendedor`.
- `FECHA_OPERACION` = `FechaOpe` (o `Fecha`) + `Hora` (`HH:MM:SS`).
- `IMPORTE_TOTAL` = `occaj.Neto` (con signo: devoluciones negativas).
- `CODIGO_UNIDAD` del depósito = `ARTICULO/COLOR/TALLA` (patrón de SKUs, con
  resolución del slot de color por `ocartcol`+`occolor`).

---

## Idempotencia

`fza_caja_operaciones.ID_OPCAJA` es autonumérico: NO hay clave de negocio
única, así que `INSERT IGNORE` no sirve. La migración es re-ejecutable
porque al arrancar **borra lo migrado por este usuario** (`USUARIO_ALTA =
<usuario>`) en `fza_caja_pagos`, `fza_caja_operaciones` y
`fza_depositos_cliente`, y vuelve a insertar. Todo dentro de la transacción
del dominio.

---

## Cómo ejecutarlo

Dominio **"Ventas / Caja (occaj)"** (wave 3, detrás de Almacenes, SKUs y
Clientes). Requisitos previos: **Almacenes**, **Clientes** y **SKUs**
migrados (la operación referencia `CODIGO_ALM`, `CODIGO_CLI` y el depósito
referencia `CODIGO_UNIDAD`).

---

## Pendiente / a revisar

- Catálogo real de `occaj.Tipo`/`TipoDoc` para afinar `MapearTipoOp`
  (hoy: heurística basada en los datos vistos: V/P→VE, C→CB, A/AL→DE,
  L→VL, TR/AT→traspaso).
- Política de depósitos: **completa** — multilínea (un depósito por línea),
  reparto del cobro (waterfall) entre los depósitos del cliente, cierre al
  alcanzar el precio, y herencia del cliente del **documento adyacente** para
  los cobros sin cliente.
- Fase 2 hecha en `inLibMigFacturas.pas` (detalle de venta como factura
  SIMPLIFICADA). Queda afinar las bandas de IVA N/R/S/E y el estado
  fiscal/Verifactu de la cabecera.
- Rendimiento: hoy inserta fila a fila (claro y con enlace de depósitos).
  Si el volumen de caja lo exige, pasar operaciones+pagos a `TBulkInsert`.
