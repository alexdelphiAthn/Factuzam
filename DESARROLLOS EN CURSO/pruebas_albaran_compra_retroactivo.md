# Pruebas - Albarán de compra retroactivo (venta antes que la entrada)

Batería de pruebas para el caso del cliente despistado: crea la sesión de
compras y el pedido, le llega la mercancía, la **vende** (TPV o albarán de
venta) y solo después pica el albarán de compra, poniéndole **fecha
anterior a la venta** para que el papel cuadre con la realidad.

Objetivo: reproducir el caso de forma controlada, medir exactamente qué
queda mal en BBDD y validar el **procedimiento correctivo** que dejaremos
documentado para soporte. No se trata (de momento) de bloquear al usuario,
sino de saber reparar.

Carpeta: `DESARROLLOS EN CURSO/` (documento suelto, estilo
`pruebas_multialmacen_pmp.md`).

Modo de ejecución recomendado:

- P0-P3 forman la cadena principal y deben ejecutarse seguidas sobre el
  mismo SKU.
- P4, P5, P6 y P8 conviene ejecutarlas con SKU nuevo (`TESTRETRO4`,
  `TESTRETRO5`...) o tras restaurar una copia de la BBDD de pruebas. Si
  se encadenan todas sobre `TESTRETRO1`, los stocks/costes acumulados de
  una fase contaminan el resultado esperado de la siguiente.
- P7 debe partir exactamente del estado de P2: venta ya grabada, albarán
  retroactivo ya grabado y sin haber lanzado todavía el correctivo P3.
- Tras cada acción, cerrar y reabrir la consulta de verificación. En
  pruebas anteriores se ha visto caché en el generador de procesos si se
  reejecuta el mismo SQL sin refrescar.

## Comportamiento actual confirmado en código (base de la batería)

Verificado sobre `factuzam_original.sql` y `src/` a fecha 05/07/2026:

- `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` es **incremental**: valora las
  salidas (`TIPO_MOV='S'`) al `PRECIO_MEDIO_STK` vigente **en el momento
  de grabar**, no en la fecha del documento. Una venta sin stock previo
  sale a coste 0 y deja `CANTIDAD_STK` negativa.
- `inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra`
  inserta el movimiento 'AC' (que nace con `FECHA_MOV = NOW()`) y después
  lo pisa con `FECHA_ALBC` (queda a las 00:00). **No lanza recálculo
  después de generar**: la entrada retroactiva se pondera sobre el estado
  actual, no reordena el histórico. Cuando se graba desde el Mto puede
  haber una reversión previa si el albarán ya tenía movimientos; esa
  reversión sí recalcula, pero ocurre antes de regenerar el 'AC'.
- `SP_RECALCULAR_PMP_LOTE_ALMACEN` / `SP_RECALCULAR_PMP_SKU_ALMACEN`
  reconstruyen PMP, `TOTAL_COSTE_MOV` de cada movimiento y
  `fza_articulos_stockactual` barriendo el histórico ordenado por
  `FECHA_MOV, INSTANTE_ALTA`. Son el candidato natural a núcleo del
  procedimiento correctivo.
- `ActualizarCostesSkuDesdeAlbaranCompra` pisa
  `PRECIO_ULT_COMPRA_SKUC` y `FECHA_ULT_COMPRA_SKUC` **sin comparar
  fechas**: un albarán retroactivo grabado el último "gana" aunque su
  fecha sea la más antigua.
- `ActualizarArticulosProveedorDesdeAlbaranCompra` pisa
  `PRECIO_ULT_COMPRA_AP` y pone `FECHA_VALIDEZ_AP = NOW()`: el precio
  viejo queda disfrazado de vigente.
- Movimientos de venta: caja actualiza `FECHA_MOV` con hora real
  (`FechaCajaConHora`, `UniDataCaja.pas`); los albaranes de venta la
  pisan con la fecha del documento (`UniDataAlbaranes.pas`), a las 00:00
  igual que los 'AC'.

## Datos base

Usar una BBDD de pruebas. **No ejecutar en producción.**

| Dato | Valor |
|------|-------|
| Empresa | `012` |
| Almacén | `GEN` |
| Proveedor | `PRVTEST` o proveedor existente |
| Cliente | cliente de pruebas existente |
| Artículo / SKU | `TESTRETRO1` (sin tallas, SKU = artículo, PVP 25,00) |
| Serie albaranes compra | `C1` |
| "Hoy" en los casos | `D` (sustituir por la fecha real de ejecución) |

Preparación (P0):

1. Crear el artículo `TESTRETRO1` sin stock previo en `GEN`.
2. Verificar limpieza: sin filas en `fza_movimientos_almacen`,
   `fza_articulos_stockactual`, `fza_articulos_skus_costes` ni
   `fza_articulos_pdte_recibir` para el SKU.
3. Crear sesión de compras + pedido de compra de 20 uds a 10,00 € con
   fecha `D-3` (alimenta el pendiente de recibir para P6).
4. Si `TESTRETRO1` ya existe por una ejecución anterior, usar un código
   nuevo o restaurar una copia de pruebas. No limpiar datos a mano en una
   BBDD que no sea desechable.

Consulta de verificación general (reutilizar en cada fase):

```sql
SELECT m.CODIGO_EMP_MOV AS EMP, m.CODIGO_ALM_MOV AS ALM,
       DATE(m.FECHA_MOV) AS FECHA, TIME(m.FECHA_MOV) AS HORA,
       m.TIPO_DOC_MOV AS TD, m.TIPO_MOV AS TM, m.NUMERO_MOV,
       m.CANTIDAD_MOV AS CANT, m.PRECIO_COSTE_UNITARIO_MOV AS COSTE_UNI,
       m.PRECIO_MEDIO_MOV AS PMP_MOV, m.TOTAL_COSTE_MOV AS COSTE_TOT,
       m.INSTANTE_ALTA
  FROM fza_movimientos_almacen m
 WHERE m.CODIGO_UNIDAD_MOV = 'TESTRETRO1'
   AND m.CODIGO_EMP_MOV = '012'
   AND m.CODIGO_ALM_MOV = 'GEN'
   AND m.ESACTIVO_MOV = 'S'
 ORDER BY m.FECHA_MOV, m.INSTANTE_ALTA;
SELECT CODIGO_ALM_STK ALM, LOTE_STK LOTE,
       CANTIDAD_STK CANT, PRECIO_MEDIO_STK PMP,
       VALOR_TOTAL_STK VALOR, CANTIDAD_ENT_COMPRA_STK EC,
       CANTIDAD_SAL_VENTA_STK SV, CANTIDAD_SAL_ALBVENTA_STK SAV
  FROM fza_articulos_stockactual
 WHERE CODIGO_UNIDAD_STK = 'TESTRETRO1'
   AND CODIGO_ALM_STK = 'GEN';
SELECT SKUC.CODIGO_UNIDAD_SKU_SKUC SKU,
       SKUC.PRECIO_ULT_COMPRA_SKUC COSTE_ULT_SKU,
       SKUC.FECHA_ULT_COMPRA_SKUC FECHA_ULT_SKU,
       AP.CODIGO_PRV_AP PRV, AP.PRECIO_ULT_COMPRA_AP COSTE_ULT_PRV,
       AP.FECHA_VALIDEZ_AP FECHA_VALIDEZ_PRV
  FROM fza_articulos_skus_costes SKUC
  LEFT JOIN fza_articulos_proveedores AP
    ON AP.CODIGO_ART_AP = SKUC.CODIGO_UNIDAD_SKU_SKUC
 WHERE SKUC.CODIGO_UNIDAD_SKU_SKUC = 'TESTRETRO1';
```

## P1 - El despiste: venta sin entrada previa

Día `D`: vender 4 uds de `TESTRETRO1` (albarán de venta con fecha `D`;
repetir la batería con venta TPV si da tiempo, cambia el fechado del
movimiento).

Esperado (así de roto debe quedar, es el punto de partida):

| Métrica | Valor |
|---------|-------|
| `CANTIDAD_STK` | -4 |
| `PRECIO_MEDIO_STK` | 0 |
| `VALOR_TOTAL_STK` | 0 |
| Mov. venta `TOTAL_COSTE_MOV` | 0 (margen falso del 100%) |
| `SAV` (o `SV` si TPV) | 4 |

Anotar `INSTANTE_ALTA` del movimiento de venta: se usa para comparar con
la grabación del 'AC' en P2/P7.

## P2 - El "arreglo" del cliente: albarán de compra retroactivo

Día `D`: crear el albarán de compra (desde la sesión/pedido de P0 si el
flujo lo permite, o picado a mano) con 20 uds a 10,00 € y **fecha
`D-3`**, anterior a la venta.

Esperado SIN tocar nada más (documenta el estado dañado):

| Métrica | Valor | ¿Correcto? |
|---------|-------|------------|
| `CANTIDAD_STK` | 16 | Sí (la cantidad suma bien) |
| Mov. 'AC' `FECHA_MOV` | `D-3` 00:00 | Sí |
| `VALOR_TOTAL_STK` | 200,00 | No (la venta salió a coste 0 y no descontó valor) |
| `PRECIO_MEDIO_STK` | 12,50 (200/16) | No (esperado 10,00) |
| Mov. venta `TOTAL_COSTE_MOV` | 0 | No (esperado 40,00) |
| `PRECIO_ULT_COMPRA_SKUC` / `FECHA_ULT_COMPRA_SKUC` | 10,00 / `D-3` | Sí (aquí aún no hay conflicto) |

Comprobación extra: consulta de stock a fecha `D-2` (informes de
balance / stocks acumulados) ya muestra 20 uds, la línea temporal
"cuadra" hacia fuera aunque los costes estén mal por dentro.

## P3 - Procedimiento correctivo candidato: recálculo PMP

Con el estado de P2, ejecutar:

```sql
CALL SP_RECALCULAR_PMP_SKU_ALMACEN('012', 'TESTRETRO1', 'GEN');
```

Esperado (criterio de aceptación del correctivo):

| Métrica | Valor |
|---------|-------|
| `CANTIDAD_STK` | 16 |
| `PRECIO_MEDIO_STK` | 10,00 |
| `VALOR_TOTAL_STK` | 160,00 |
| Mov. venta `PRECIO_MEDIO_MOV` / `TOTAL_COSTE_MOV` | 10,00 / 40,00 |
| Mov. 'AC' intacto | 20 uds a 10,00 |
| `EC` / `SAV` | 20 / 4 (el recálculo los reconstruye desde movimientos) |

Si esto sale, el SP reordena bien por `FECHA_MOV, INSTANTE_ALTA` y el
correctivo es "recalcular el SKU/almacén tras detectar el retroactivo"
(o un lote de SKUs por almacén con `SP_RECALCULAR_PMP_LOTE_ALMACEN`).
Verificar también que el informe de movimientos de ventas por artículos
ya enseña el margen real (lee `TOTAL_COSTE_MOV`).

## P4 - Último coste pisado hacia atrás

Ejecutar preferiblemente con un SKU limpio o después de P3 si solo se
quiere comprobar la tabla de últimos costes. El objetivo aquí no es el
PMP, sino `fza_articulos_skus_costes` y `fza_articulos_proveedores`.

1. Albarán de compra `D-1`, 5 uds a 16,00 € (grabado primero).
2. Albarán de compra retroactivo `D-5`, 5 uds a 10,00 € (grabado después).
3. Consultar `fza_articulos_skus_costes` y `fza_articulos_proveedores`
   con la consulta general.

Esperado HOY (fallo a documentar):

| Métrica | Valor actual | Valor correcto |
|---------|--------------|----------------|
| `PRECIO_ULT_COMPRA_SKUC` | 10,00 | 16,00 |
| `FECHA_ULT_COMPRA_SKUC` | `D-5` | `D-1` |
| `FECHA_VALIDEZ_AP` | NOW() con precio 10,00 | debería conservar el precio del albarán de `D-1` |

Consulta de diagnóstico para identificar qué albarán debería mandar antes
de preparar el script correctivo:

```sql
SELECT A.FECHA_ALBC, A.INSTANTE_ALTA, A.SERIE_ALBC, A.NUMERO_ALBC,
       A.CODIGO_PRV_ALBC, L.CODIGO_UNIDAD_ALBCLIN SKU,
       L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN PRECIO_LINEA,
       L.PORCENTAJE_IVA_ALBCLIN IVA,
       A.PORCENTAJE_DTO_COMERCIAL_ALBC DTO_COMERCIAL
  FROM fza_albaranes_compra_lineas L
  JOIN fza_albaranes_compra A
    ON A.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN
   AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN
 WHERE L.CODIGO_UNIDAD_ALBCLIN = 'TESTRETRO1'
 ORDER BY A.FECHA_ALBC DESC, A.INSTANTE_ALTA DESC, L.LINEA_ALBCLIN DESC;
```

No usar un `UPDATE` parcial que reponga solo la fecha: el precio debe
recomponerse con la misma expresión de descuentos/recargo de
`ActualizarCostesSkuDesdeAlbaranCompra` y el proveedor con la de
`ActualizarArticulosProveedorDesdeAlbaranCompra`. En esta prueba basta
verificar a mano que el albarán de `D-1` es el que debe mandar. Si hay
dos albaranes con la misma `FECHA_ALBC`, anotar el empate y decidir si
debe mandar el de mayor `INSTANTE_ALTA` o si se exige intervención manual.

## P5 - Caso límite: venta y compra retroactiva el mismo día

Usar un SKU limpio (`TESTRETRO5`, por ejemplo), porque el caso solo es
claro si no hay stock ni PMP previo.

1. Venta de 2 uds con albarán de venta fecha `D` (su `FECHA_MOV` queda a
   las 00:00 de `D`).
2. Albarán de compra retroactivo con la **misma fecha `D`** (también
   00:00), grabado después.
3. `CALL SP_RECALCULAR_PMP_SKU_ALMACEN(...)`.

Con empate en `FECHA_MOV`, el SP desempata por `INSTANTE_ALTA`: la venta
se grabó antes, así que el recálculo ordena **venta antes que compra**
incluso tras el correctivo. Documentar el resultado real:

- Si la venta sigue saliendo a coste 0/PMP viejo: limitación conocida
  del correctivo. Anotar como candidata a regla de desempate en el SP
  (a igual fecha, entradas antes que salidas). Decisión aparte.
- Repetir con venta TPV: ahí `FECHA_MOV` lleva hora real y el 'AC' a las
  00:00 queda delante, debería ordenar bien.

## P6 - Pendiente de recibir con fecha incoherente

Usar un pedido pendiente nuevo o ejecutar antes de servir el pedido de P0.
Con pedido fecha `D-3`, crear albarán de compra desde la sesión con fecha
`D-5` (anterior incluso al pedido).

Verificar:

- `fza_articulos_pdte_recibir` descarga `CANTIDAD_PDR` igualmente (la
  descarga no depende de fechas) y no queda residuo para el SKU.
- La vista de pendientes muestra `FECHA_PEDIDO_MIN` posterior a la fecha
  del albarán que lo sirvió: incoherencia solo cosmética, anotar si
  algún informe la expone al usuario.

```sql
SELECT CODIGO_ART_PDR, CANTIDAD_PDR, FECHA_PEDIDO_PDR
  FROM fza_articulos_pdte_recibir
 WHERE CODIGO_ART_PDR = 'TESTRETRO1';
```

## P7 - Correctivo alternativo: Revertir + Generar movimientos del Mto

Hipótesis a confirmar: revertir movimientos del albarán retroactivo
(`RevertirMovimientosDesdeAlbaranCompra`) SÍ recalcula (deja el estado
"solo venta": -4 uds a coste 0), pero regenerar
(`GenerarMovimientosDesdeAlbaranCompra`) vuelve a insertar incremental
y **reproduce el PMP malo de P2** porque no relanza el recálculo.

Si se confirma: el procedimiento correctivo de soporte debe terminar
SIEMPRE con el `CALL SP_RECALCULAR_PMP_*`; revertir/regenerar desde el
Mto no basta por sí solo.

## P8 - Facturación y Verifactu (comprobación de perímetro)

- Facturar la venta de P1 ANTES de crear el albarán retroactivo de P2 y
  confirmar que la factura emitida (y su registro Verifactu, si la BBDD
  de pruebas está en modo Verifactu) no se ve alterada por nada de lo
  anterior: el albarán de compra no entra en el encadenamiento y el
  correctivo solo toca costes, nunca importes de venta.
- Facturar el albarán de compra retroactivo con factura de proveedor de
  fecha `D-3`. El SP `PRC_FACC_FACTURAR_ALBARAN` crea la factura con
  `FECHA_FACC = CURDATE()`; si el Mto permite editarla después a `D-3`,
  verificar que no valida contra `FECHA_ALBC` y anotar el comportamiento.

## Resultado esperado de la batería

Al terminar debe quedar respondido, con datos reales:

1. Qué repara `SP_RECALCULAR_PMP_SKU_ALMACEN` por sí solo (P3) y qué no
   (P4 último coste, P5 empates de fecha).
2. Borrador del procedimiento correctivo de soporte, en este orden:
   detectar SKUs afectados (movimiento 'AC' con `FECHA_MOV` anterior a
   salidas ya grabadas del mismo SKU/almacén, comparando también
   `INSTANTE_ALTA`), recalcular PMP por SKU/almacén o por lote de SKUs
   del almacén, reponer último coste SKU/proveedor desde el albarán de
   fecha máxima, y revisar informes de márgenes del periodo afectado.
3. Lista de defensas preventivas a valorar después (aviso en el Mto al
   grabar `FECHA_ALBC` anterior al último movimiento del SKU, recálculo
   automático tras grabar un 'AC' retroactivo, guarda por fecha en los
   `ON DUPLICATE` de últimos costes).

Consulta de detección de retroactivos claros en BBDD de clientes (germen
del futuro script de auditoría):

```sql
SELECT m.CODIGO_EMP_MOV AS EMP, m.CODIGO_ALM_MOV AS ALM,
       m.CODIGO_UNIDAD_MOV AS SKU,
       m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV,
       m.FECHA_MOV AS FECHA_ALBARAN,
       m.INSTANTE_ALTA AS GRABADO_ALBARAN,
       MIN(mv.FECHA_MOV) AS PRIMERA_FECHA_SALIDA,
       MIN(mv.INSTANTE_ALTA) AS PRIMERA_GRABACION_SALIDA,
       COUNT(DISTINCT mv.NUMERO_MOV) AS SALIDAS_PREVIAS_POSTERIORES
  FROM fza_movimientos_almacen m
  JOIN fza_movimientos_almacen mv
    ON mv.CODIGO_UNIDAD_MOV = m.CODIGO_UNIDAD_MOV
   AND mv.CODIGO_ALM_MOV    = m.CODIGO_ALM_MOV
   AND mv.CODIGO_EMP_MOV    = m.CODIGO_EMP_MOV
   AND mv.TIPO_MOV          = 'S'
   AND mv.ESACTIVO_MOV      = 'S'
   AND mv.FECHA_MOV         > m.FECHA_MOV
   AND mv.INSTANTE_ALTA     < m.INSTANTE_ALTA
 WHERE m.TIPO_DOC_MOV = 'AC'
   AND m.TIPO_MOV     = 'E'
   AND m.ESACTIVO_MOV = 'S'
   AND DATE(m.FECHA_MOV) < DATE(m.INSTANTE_ALTA)
 GROUP BY m.CODIGO_EMP_MOV, m.CODIGO_ALM_MOV, m.CODIGO_UNIDAD_MOV,
          m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV, m.FECHA_MOV, m.INSTANTE_ALTA;
```

Consulta separada para el caso P5 (misma fecha de documento, salida
grabada antes que la entrada):

```sql
SELECT m.CODIGO_EMP_MOV AS EMP, m.CODIGO_ALM_MOV AS ALM,
       m.CODIGO_UNIDAD_MOV AS SKU,
       m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV,
       m.FECHA_MOV AS FECHA_ALBARAN,
       m.INSTANTE_ALTA AS GRABADO_ALBARAN,
       COUNT(DISTINCT mv.NUMERO_MOV) AS SALIDAS_MISMA_FECHA_ANTES
  FROM fza_movimientos_almacen m
  JOIN fza_movimientos_almacen mv
    ON mv.CODIGO_UNIDAD_MOV = m.CODIGO_UNIDAD_MOV
   AND mv.CODIGO_ALM_MOV    = m.CODIGO_ALM_MOV
   AND mv.CODIGO_EMP_MOV    = m.CODIGO_EMP_MOV
   AND mv.TIPO_MOV          = 'S'
   AND mv.ESACTIVO_MOV      = 'S'
   AND mv.FECHA_MOV         = m.FECHA_MOV
   AND mv.INSTANTE_ALTA     < m.INSTANTE_ALTA
 WHERE m.TIPO_DOC_MOV = 'AC'
   AND m.TIPO_MOV     = 'E'
   AND m.ESACTIVO_MOV = 'S'
 GROUP BY m.CODIGO_EMP_MOV, m.CODIGO_ALM_MOV, m.CODIGO_UNIDAD_MOV,
          m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV, m.FECHA_MOV, m.INSTANTE_ALTA;
```

## Registro de resultados

| Fase | Fecha ejecución | Resultado | Notas |
|------|-----------------|-----------|-------|
| P0 | | | |
| P1 | | | |
| P2 | | | |
| P3 | | | |
| P4 | | | |
| P5 | | | |
| P6 | | | |
| P7 | | | |
| P8 | | | |
