# Fallback de SKU: artículo sin variaciones usa su propio código como unidad

## Objetivo (decidido con el usuario)
Que un artículo SIN variaciones tenga siempre una **unidad/SKU base** con
`CODIGO_UNIDAD_SKU = CODIGO_ART_ART`. Así stock, movimientos, tarifas a nivel
SKU y la consulta de stock (Ctrl+U) funcionan igual que con artículos con
variaciones, sin casos especiales. Opcion elegida: **crear el SKU base**
(no fallback en runtime).

## Por qué
La consulta de stock (`inMtoStockConsulta`) y casi todo el stock parten de
`fza_articulos_skus`:
```sql
FROM fza_articulos_skus SKU
JOIN fza_articulos_stockactual STK ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU
WHERE SKU.CODIGO_ART_SKU = <articulo>
```
Un artículo sin SKU no devuelve filas → Ctrl+U sale vacío y no puede acumular
stock. Creando un SKU base se resuelve de raíz.

## Trabajo a hacer
1. **Alta automática en el alta de artículo** (`UniDataArticulos`):
   cuando el artículo no es de variaciones (`ESVARIACION_ART = 'N'`), tras
   grabar la cabecera crear el SKU base si no existe
   (`CODIGO_UNIDAD_SKU = CODIGO_ART_ART`). Localizar el punto correcto
   (¿AfterPost de unqryTablaG? ¿al pulsar grabar?) y reusar la logica de
   creacion de SKU que ya exista.
2. **Backfill idempotente** (script SQL en DESARROLLOS EN CURSO): para cada
   artículo sin ningún SKU, insertar el SKU base. `INSERT ... SELECT` con
   `NOT EXISTS`.

## Puntos delicados (columnas NOT NULL de fza_articulos_skus)
- `CODIGO_UNIDAD_SKU` (PK/parte): = `CODIGO_ART_ART`.
- `CODIGO_ART_SKU`: = `CODIGO_ART_ART`.
- `CODIGO_VAR_SKU` **NOT NULL sin default**: hay que decidir el valor para un
  SKU base sin variación (probablemente '' o '0' o el codigo de variacion
  "nula" que use el sistema). REVISAR como se rellena en SKUs existentes de
  articulos sin variacion antes de fijarlo.
- `ESACTIVO_SKU`: 'S'.
- Auditoria (`USUARIO_ALTA/MODIF`, `INSTANTE_*`): 'SISTEMA' / now.
- Revisar si hay que crear tambien fila en `fza_articulos_stockactual` o si se
  crea sola con el primer movimiento (probablemente lo segundo).

## Estado: IMPLEMENTADO
- `CODIGO_VAR_SKU` para SKU base = **'-'** (convencion ya usada en BBDD,
  p.ej. el SKU 'BOLSO-PIEL').
- Alta automatica: `UniDataArticulos.unqryTablaGAfterPost` ->
  `AsegurarSkuBase` (solo si ESVARIACION_ART='N' y el articulo no tiene
  ningun SKU). Idempotente (NOT EXISTS + INSERT IGNORE).
- Backfill existentes: `sku_base_articulo.sql`.
- NOTA: la consulta de stock (Ctrl+U) hace INNER JOIN a
  fza_articulos_stockactual, asi que la linea aparece cuando el SKU tenga
  fila de stock (se crea con el primer movimiento/entrada). Si se quiere ver
  el "0" antes de cualquier movimiento, habria que crear la fila de stock a 0
  o pasar ese JOIN a LEFT JOIN (pendiente, decidir si hace falta).

## Verificacion
- Crear un articulo simple (sin variaciones) -> debe nacer con SKU base.
- Ctrl+U sobre ese articulo -> muestra una linea de stock (a 0) en lugar de
  vacio.
- Una entrada/compra sobre ese articulo -> suma stock correctamente.
