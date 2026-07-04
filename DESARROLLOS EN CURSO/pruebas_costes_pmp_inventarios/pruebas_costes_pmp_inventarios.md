# Pruebas - Costes por SKU, PMP, inventarios, traspasos e informe de ventas

Paquete de pruebas funcionales para validar que el coste fluye bien desde
compras hasta stock, ventas, traspasos, inventarios e informe de
"Movimientos de ventas por articulos y fechas".

El punto central de esta bateria es que un mismo articulo tiene varios SKUs
con costes distintos. Eso obliga a comprobar dos niveles:

- Coste articulo/proveedor: `fza_articulos_proveedores` queda como fallback
  historico del articulo.
- Coste SKU: `fza_articulos_skus_costes` es el dato operativo cuando el SKU
  tiene coste propio.

Carpeta: `DESARROLLOS EN CURSO/pruebas_costes_pmp_inventarios/`.

## Datos base

Usar una BBDD de pruebas. No ejecutar en produccion.

Codigos propuestos:

| Dato | Valor |
|------|-------|
| Empresa GEN | `012` |
| Almacen origen | `GEN` |
| Empresa BCN | `1` |
| Almacen destino | `BCN` |
| Proveedor | `PRVTEST` o proveedor existente |
| Cliente | cliente de pruebas existente |
| Articulo | `TESTSKU01` |
| SKU 1 | `TESTSKU01/NEGRO/S` |
| SKU 2 | `TESTSKU01/NEGRO/M` |
| SKU 3 | `TESTSKU01/AZUL/S` |

Si el generador de SKUs crea codigos ligeramente distintos, sustituirlos en
`verificaciones_costes_pmp_inventarios.sql`.

Preparacion manual:

1. Crear o reutilizar proveedor de pruebas.
2. Crear el articulo `TESTSKU01` con tres SKUs activos.
3. Poner PVP de referencia:
   - SKU 1: 25,00
   - SKU 2: 30,00
   - SKU 3: 35,00
4. Verificar que no hay stock previo de esos SKUs en `GEN` ni `BCN`.

## P1 - Compra con costes distintos por SKU

Crear albaran de compra en `GEN`, fecha `2026-07-10`, con estas lineas:

| SKU | Cantidad | Coste |
|-----|----------|-------|
| `TESTSKU01/NEGRO/S` | 10 | 8,00 |
| `TESTSKU01/NEGRO/M` | 6 | 12,00 |
| `TESTSKU01/AZUL/S` | 4 | 15,00 |

Esperado:

| SKU | Stock GEN | PMP GEN | Valor GEN | Ultimo coste SKU |
|-----|-----------|---------|-----------|------------------|
| `TESTSKU01/NEGRO/S` | 10 | 8,00 | 80,00 | 8,00 |
| `TESTSKU01/NEGRO/M` | 6 | 12,00 | 72,00 | 12,00 |
| `TESTSKU01/AZUL/S` | 4 | 15,00 | 60,00 | 15,00 |

Comprobaciones:

- `fza_articulos_skus_costes` tiene una fila por SKU con su coste propio.
- Los movimientos de compra `AC` tienen `PRECIO_COSTE_UNITARIO_MOV` distinto
  por SKU.
- `fza_articulos_stockactual.PRECIO_MEDIO_STK` queda distinto por SKU.
- `fza_articulos_proveedores.PRECIO_ULT_COMPRA_AP` no se usa para representar
  todos los costes del articulo; con costes por SKU solo sirve como fallback.

## P2 - Segunda compra para ponderar cada SKU por separado

Crear segundo albaran de compra en `GEN`, fecha `2026-07-11`:

| SKU | Cantidad | Coste |
|-----|----------|-------|
| `TESTSKU01/NEGRO/S` | 5 | 14,00 |
| `TESTSKU01/NEGRO/M` | 6 | 9,00 |

Esperado:

| SKU | Stock GEN | PMP GEN | Valor GEN | Ultimo coste SKU |
|-----|-----------|---------|-----------|------------------|
| `TESTSKU01/NEGRO/S` | 15 | 10,00 | 150,00 | 14,00 |
| `TESTSKU01/NEGRO/M` | 12 | 10,50 | 126,00 | 9,00 |
| `TESTSKU01/AZUL/S` | 4 | 15,00 | 60,00 | 15,00 |

Formula:

- SKU 1: `(10 * 8 + 5 * 14) / 15 = 10,00`.
- SKU 2: `(6 * 12 + 6 * 9) / 12 = 10,50`.
- SKU 3 no cambia.

## P3 - Venta con costes distintos por SKU

Crear venta en `GEN`, fecha `2026-07-12`. Para que el informe P7 la recoja,
debe acabar en `fza_facturas_lineas`: usar TPV/ticket o facturar el albaran
antes de ejecutar el informe.

| SKU | Cantidad | PVP |
|-----|----------|-----|
| `TESTSKU01/NEGRO/S` | 3 | 25,00 |
| `TESTSKU01/NEGRO/M` | 2 | 30,00 |
| `TESTSKU01/AZUL/S` | 1 | 35,00 |

Esperado en stock:

| SKU | Stock GEN | PMP GEN | Valor GEN |
|-----|-----------|---------|-----------|
| `TESTSKU01/NEGRO/S` | 12 | 10,00 | 120,00 |
| `TESTSKU01/NEGRO/M` | 10 | 10,50 | 105,00 |
| `TESTSKU01/AZUL/S` | 3 | 15,00 | 45,00 |

Esperado en movimientos de salida:

| SKU | Cantidad | PMP capturado | Coste salida |
|-----|----------|---------------|--------------|
| `TESTSKU01/NEGRO/S` | 3 | 10,00 | 30,00 |
| `TESTSKU01/NEGRO/M` | 2 | 10,50 | 21,00 |
| `TESTSKU01/AZUL/S` | 1 | 15,00 | 15,00 |

Total venta:

- Unidades: 6
- Importe venta: 170,00
- Coste real vendido por SKU: 66,00
- Beneficio: 104,00
- Margen sobre venta: 61,18 %

Esta prueba debe confirmar que la venta captura el PMP de cada SKU y no cambia
el PMP del stock restante.

## P4 - Traspaso con PMP distinto por SKU

Traspasar desde `GEN` a `BCN`, fecha `2026-07-13`:

| SKU | Cantidad |
|-----|----------|
| `TESTSKU01/NEGRO/S` | 4 |
| `TESTSKU01/NEGRO/M` | 3 |

Esperado:

| Almacen | SKU | Stock | PMP | Valor |
|---------|-----|-------|-----|-------|
| `GEN` | `TESTSKU01/NEGRO/S` | 8 | 10,00 | 80,00 |
| `GEN` | `TESTSKU01/NEGRO/M` | 7 | 10,50 | 73,50 |
| `GEN` | `TESTSKU01/AZUL/S` | 3 | 15,00 | 45,00 |
| `BCN` | `TESTSKU01/NEGRO/S` | 4 | 10,00 | 40,00 |
| `BCN` | `TESTSKU01/NEGRO/M` | 3 | 10,50 | 31,50 |

Comprobaciones:

- El movimiento de salida de `GEN` usa el PMP del SKU en origen.
- El movimiento de entrada de `BCN` hereda ese mismo coste.
- El traspaso no usa el ultimo coste de compra del SKU (`14,00` y `9,00`),
  sino el PMP en origen (`10,00` y `10,50`).
- `TESTSKU01/AZUL/S` no se altera.

## P5 - Compra en destino para divergir PMP por almacen

Crear albaran de compra en `BCN`, fecha `2026-07-14`:

| SKU | Cantidad | Coste |
|-----|----------|-------|
| `TESTSKU01/NEGRO/S` | 4 | 16,00 |
| `TESTSKU01/NEGRO/M` | 3 | 7,00 |

Esperado:

| Almacen | SKU | Stock | PMP | Valor | Ultimo coste SKU |
|---------|-----|-------|-----|-------|------------------|
| `BCN` | `TESTSKU01/NEGRO/S` | 8 | 13,00 | 104,00 | 16,00 |
| `BCN` | `TESTSKU01/NEGRO/M` | 6 | 8,75 | 52,50 | 7,00 |
| `GEN` | `TESTSKU01/NEGRO/S` | 8 | 10,00 | 80,00 | 16,00 |
| `GEN` | `TESTSKU01/NEGRO/M` | 7 | 10,50 | 73,50 | 7,00 |

Notas:

- `fza_articulos_skus_costes` guarda el ultimo coste de compra global del SKU,
  no por almacen.
- `fza_articulos_stockactual` guarda PMP por almacen; por eso `GEN` y `BCN`
  divergen correctamente.

## P6 - Inventario con ajuste de cantidad y PMP nuevo

Crear inventario en `GEN`, fecha `2026-07-15`, con lineas:

| SKU | Teorico esperado | Fisico contado | PMP nuevo |
|-----|------------------|----------------|-----------|
| `TESTSKU01/NEGRO/S` | 8 | 9 | 11,00 |
| `TESTSKU01/NEGRO/M` | 7 | 5 | 10,50 |
| `TESTSKU01/AZUL/S` | 3 | 3 | 15,00 |

Aplicar inventario.

Esperado:

| SKU | Stock GEN | PMP GEN | Valor GEN |
|-----|-----------|---------|-----------|
| `TESTSKU01/NEGRO/S` | 9 | 11,00 | 99,00 |
| `TESTSKU01/NEGRO/M` | 5 | 10,50 | 52,50 |
| `TESTSKU01/AZUL/S` | 3 | 15,00 | 45,00 |

Comprobaciones:

- El SKU 1 cambia cantidad y PMP.
- El SKU 2 cambia cantidad, pero conserva PMP.
- El SKU 3 tiene diferencia cero; la regularizacion no debe crear movimientos
  efectivos para esa linea.
- Los movimientos `IN` se generan con salida del teorico y entrada del fisico.
- Si se ejecuta "Eliminar regularizacion", el stock vuelve al estado anterior:
  `GEN` SKU 1 = 8 a 10,00; SKU 2 = 7 a 10,50; SKU 3 = 3 a 15,00.

## P7 - Informe de ventas por articulo y fechas

Ejecutar al final de toda la bateria:

```sql
CALL PRC_GET_MOV_VENTAS_ART(
  '2026-07-12',
  '2026-07-12',
  NULL,
  'GEN,BCN',
  '',
  '',
  '',
  'TESTSKU01',
  '',
  '',
  '',
  0,
  'S'
);
```

Esperado para `TESTSKU01`:

| Campo | Valor |
|-------|-------|
| `UDS_VENTA` | 6 |
| `IMP_VENTA` | 170,00 |
| `IMP_COSTE` | 66,00 |
| `BENEFICIO` | 104,00 |
| `MARGEN1` | 61,18 |

Criterio importante:

El coste del informe debe salir de los SKUs vendidos:

```text
(3 * 10,00) + (2 * 10,50) + (1 * 15,00) = 66,00
```

No debe recalcular la venta historica con el coste medio actual del articulo,
porque despues hay traspasos, compras en `BCN` e inventario. Si el informe
devuelve otro `IMP_COSTE`, la prueba ha encontrado una regresion de margen con
costes distintos por SKU.

## P8 - Recalculo y cuadre final

Ejecutar recalc para cada SKU/almacen tocado:

```sql
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('012', 'TESTSKU01/NEGRO/S', 'GEN');
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('012', 'TESTSKU01/NEGRO/M', 'GEN');
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('012', 'TESTSKU01/AZUL/S', 'GEN');
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('1', 'TESTSKU01/NEGRO/S', 'BCN');
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('1', 'TESTSKU01/NEGRO/M', 'BCN');
```

El recalc no debe cambiar ningun stock/PMP esperado. Si cambia, hay un problema
entre el movimiento historico y el resumen de `fza_articulos_stockactual`.

Cuadre de unidades antes de eliminar regularizacion:

| SKU | Compras | Ventas | Traspaso neto GEN | Inventario GEN | Stock final total |
|-----|---------|--------|-------------------|----------------|-------------------|
| SKU 1 | 19 | 3 | 0 | +1 | 17 |
| SKU 2 | 15 | 2 | 0 | -2 | 11 |
| SKU 3 | 4 | 1 | 0 | 0 | 3 |

Detalle final esperado:

| Almacen | SKU | Stock |
|---------|-----|-------|
| `GEN` | `TESTSKU01/NEGRO/S` | 9 |
| `BCN` | `TESTSKU01/NEGRO/S` | 8 |
| `GEN` | `TESTSKU01/NEGRO/M` | 5 |
| `BCN` | `TESTSKU01/NEGRO/M` | 6 |
| `GEN` | `TESTSKU01/AZUL/S` | 3 |
