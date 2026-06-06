# Migración del histórico de movimientos de almacén

Incorpora el histórico transaccional de stock del legacy (`dbo.ocmovarp`,
SQL Server) a `fza_movimientos_almacen` (MariaDB) y, a partir de él,
reconstruye el stock actual.

Implementado como un **dominio nuevo del migrador** Delphi
(`src/utilmigsqlsrv/inLibMigMovimientos.pas`), no como script SQL: el
origen vive en SQL Server y solo el migrador (UniDAC con provider SQL
Server) puede leerlo. No requiere cambios de esquema: `fza_movimientos_almacen`
y `fza_articulos_stockactual` ya existen con todas las columnas necesarias.

---

## Decisiones tomadas (usuario)

1. **Coste/PMP por fila = el del propio movimiento** (`ocmovarp`):
   - `PrecioMedio` → `PRECIO_MEDIO_MOV`
   - `PrecioCoste` → `PRECIO_COSTE_UNITARIO_MOV` (si viene 0, usa `PrecioMedio`)

2. **Salvaguarda del 15% contra `ocalbproarp`**: si el coste del
   movimiento se desvía **más de un 15%** del precio real del **último
   albarán de entrada** del artículo (`ocalbproarp.PrecioSIva`, sin IVA),
   el dato del legacy se considera poco fiable y se toma el del albarán
   para esa fila (tanto coste como PMP). También cubre el caso de coste 0
   con un albarán de referencia conocido. Si no hay albarán (`precio > 0`)
   se conserva el dato del movimiento.

   ```
   refAlb = PrecioSIva del último albarán de entrada del artículo
   si refAlb > 0 y |coste_mov - refAlb| > 0.15 * refAlb:
        coste = refAlb ; pmp = refAlb
   ```

   El último precio se precalcula una sola vez con `ROW_NUMBER()` (mismo
   patrón que `inLibMigArticulosProveedores`) y se cruza por `LEFT JOIN`,
   por artículo. Para cambiar a **media de entradas** basta sustituir el
   CTE `cte_alb` por un `AVG(PrecioSIva) GROUP BY Articulo`.

3. **Movimientos activos que recalculan stock** (`ESACTIVO_MOV='S'`): tras
   volcar el histórico se reconstruye `fza_articulos_stockactual`.

> Por (3), esta migración es **alternativa** a *Inventario inicial*
> (`inLibMigInventarios`): ejecuta **una u otra**, no las dos, o el stock
> se contaría dos veces. Como `movimientos` reconstruye el stock desde el
> histórico completo, es la fuente de verdad cuando se usa.

---

## Por qué NO se usa `SP_RECALCULAR_PMP_LOTE_ALMACEN`

El SP canónico del sistema recalcula el PMP como media ponderada móvil a
partir de `PRECIO_COSTE_UNITARIO_MOV` de las entradas y **sobrescribe**
`PRECIO_MEDIO_MOV` fila a fila (paso 3 del SP). Eso **destruiría** el PMP
del legacy que la decisión (1) pide conservar. Por eso la reconstrucción
de stock es propia y respeta el PMP por fila:

- `CANTIDAD_STK`      = Σ(entradas) − Σ(salidas)            (agregación)
- acumuladores `_STK` = Σ por subtipo (compra/traspaso/venta/…)
- `PRECIO_MEDIO_STK`  = PMP del **último** movimiento del SKU (legacy)
- `VALOR_TOTAL_STK`   = `CANTIDAD_STK * PRECIO_MEDIO_STK`

Son dos sentencias `set-based` (UPSERT) sin tablas temporales,
deterministas e idempotentes. La clasificación de los acumuladores por
subtipo replica la de `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` para que
`stockactual` quede coherente con lo que calcularía la app.

---

## Mapeo de columnas `ocmovarp` → `fza_movimientos_almacen`

| Destino | Origen / regla |
|---|---|
| `NUMERO_MOV` | `'MH' + Numero` a 10 dígitos (PK; prefijo evita choque con el contador `MV`) |
| `TIPO_DOC_MOV` | `MapearTipoDoc(TipoDoc, dirección)` (heurística, ver abajo) |
| `SERIE_DOC_MOV` / `NUMERO_DOC_MOV` | `Serie` / `NroDoc` (cadena vacía si faltan; son NOT NULL) |
| `LINEA_MOV` | `'0001'` (ocmovarp es una fila por movimiento) |
| `CODIGO_EMP_MOV` | `Empresa` (entero como texto) |
| `CODIGO_ALM_MOV` | `ocalm.Abreviatura` del almacén, fallback al número |
| `CODIGO_ALM_CONTRA_MOV` | en traspasos: abreviatura de (`EmpresaDes`,`AlmacenDes`) |
| `FECHA_MOV` | `FechaOpe`, fallback `Fecha`, fallback NULL |
| `CODIGO_ART_MOV` | `Articulo` |
| `CODIGO_UNIDAD_MOV` | `ARTICULO/COLOR/TALLA` (mismo patrón que SKUs e Inventarios) |
| `DESCRIPCION_ARTICULO_MOV` | `ocartp.DescripcionLarga`/`Corta` |
| `TIPO_MOV` | `DeducirTipoMov` (`E`/`S`) |
| `CANTIDAD_MOV` | `ABS(UnidadesStock)`; si 0, `ABS(Cantidad)` |
| `PRECIO_COSTE_UNITARIO_MOV` | `PrecioCoste` (fallback `PrecioMedio`), corregido por salvaguarda 15% |
| `PRECIO_MEDIO_MOV` | `PrecioMedio`, corregido por salvaguarda 15% |
| `TOTAL_COSTE_MOV` | `CANTIDAD_MOV * PRECIO_COSTE_UNITARIO_MOV` |
| `CODIGO_CLI_MOV` | `Cliente` |
| `ESACTIVO_MOV` | `'S'` |
| `CODIGO_ALM_DOC_MOV` | = `CODIGO_ALM_MOV` |
| auditoría | las pone el motor (`Now()` + usuario configurado) |

Se **excluyen** los movimientos anulados (`Invalido='S'`) y los de
cantidad efectiva 0 (no aportan al histórico de stock; se cuentan como
*saltadas*).

---

## Heurísticas (primera versión — afinar con datos reales)

Sin catálogo del cliente de los códigos `Tipo`/`TipoDoc` del legacy, dos
puntos quedan como heurística aislada y fácil de tocar:

- **Dirección `TIPO_MOV`** (`DeducirTipoMov`): `Tipo` si es `'E'`/`'S'`;
  si no, signo de `UnidadesStock`; si no, signo de `Cantidad`; por
  defecto entrada.
- **`TIPO_DOC_MOV`** (`MapearTipoDoc`): los códigos que ya coinciden con
  el destino (`AC/AV/TR/AT/IN/DP/VE/AE`) pasan tal cual; sinónimos
  frecuentes mapeados (`FC/FV/TK/TP→VE`, `FP/AP→AC`, `RG/RI→IN`);
  desconocido por dirección (`E→IN`, `S→VE`).

`CANTIDAD_STK` (el stock neto) sale correcto en cualquier caso porque se
calcula por dirección E/S; solo el desglose por subtipo de acumuladores
depende de la calidad del mapeo de `TipoDoc`.

---

## Idempotencia

- Volcado de movimientos: PK `NUMERO_MOV` + `INSERT IGNORE` (bulk de
  5000). Re-ejecutar no duplica.
- Reconstrucción de `stockactual`: recalcula desde cero por UPSERT sobre
  el histórico activo. Re-ejecutable, determinista.

---

## Cómo ejecutarlo

En el Migrator, dominio **"Movimientos histórico (stock)"** (wave 3,
detrás de SKUs y Almacenes). Requisitos previos: haber migrado
**Almacenes** y **SKUs** (el movimiento referencia `CODIGO_ALM` y
`CODIGO_UNIDAD`). No marcar a la vez *Inventario inicial* y *Movimientos*
sobre la misma BBDD.

---

## Pendiente / a revisar

- Confirmar el catálogo real de `ocmovarp.Tipo` / `TipoDoc` para ajustar
  `DeducirTipoMov` y `MapearTipoDoc`.
- Decidir si la referencia de la salvaguarda 15% debe ser el **último**
  albarán (actual) o la **media** de entradas, y si por artículo o por
  SKU (color/talla). Hoy: último, por artículo.
- Lotes: `ocmovarplotes` no se migra (el histórico va con `LOTE_STK=''`).
