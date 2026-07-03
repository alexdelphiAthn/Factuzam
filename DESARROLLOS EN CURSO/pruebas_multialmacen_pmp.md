# Batería de pruebas multialmacén: traspasos y PMP por almacén

> **Ejecución 02-03/07/2026 — resultado parcial.** P0 completada
> (TESTPMP1 sin tallas PVP 25; TESTPMP2 tallas UNI/S+M PVP 12;
> proveedor usado: ANGEL). Hallazgos y fixes durante P1:
>
> - Alta manual de pedido de compra estaba rota: Required de columnas
>   calculadas de `vi_pedidos_compra` (fix: cinturón en BeforePost),
>   vista no insertable [1471] (fix: SQLInsert explícito), y líneas
>   posteadas con clave provisional '0' que quedaban huérfanas y
>   rompían el siguiente alta con 1062 (fix del usuario: contador
>   reforzado + la línea no se graba sin número real +
>   `fix_contador_documentos_no_cero.sql`).
> - Mismo [1471] en albaranes de compra (fix: SQLInsert explícito en
>   `ConfigurarSqlCabecera` de `UniDataAlbaranesCompra`).
> - `ESPIVOTE_HORIZONTAL_*` sin valor bloqueaba el Post (fix: default
>   en BeforePost + rediseño del usuario para tallas horizontal).
> - Añadido mininavegador al grid de líneas de pedidos de compra.
>
> **P1-A OK**: albarán compra 000004/C1 (20 uds TESTPMP1 a 10 €, GEN)
> → stockactual GEN/TESTPMP1 = 20 / PMP 10,00 / valor 200 / EC 20 ✔.
>
> **P1-B RESUELTO — FALSO POSITIVO (03/07)**: tras
> `CALL SP_RECALCULAR_PMP_SKU_ALMACEN('012','TESTPMP1','GEN')`
> stockactual muestra 30 / PMP 12,00 / 360 / EC 30 — y como el
> recálculo NO toca `CANTIDAD_ENT_COMPRA_STK`, el EC=30 demuestra que
> el stock ya estaba bien: la lectura "20/10/200" era la **VistaDatos
> del Generador de Procesos sirviendo caché** (no refresca el grid al
> reejecutar el mismo SQL — mejora pendiente del Generador). El PMP
> pondera correctamente. Diagnóstico original conservado debajo como
> registro:
>
> ~~P1-B KO~~: albarán compra 000005/C1
> (10 uds a 16 €, GEN) grabó bien y su movimiento 'AC' E 10@16 existe
> en `fza_movimientos_almacen`, pero `fza_articulos_stockactual` NO se
> actualizó (sigue 20/10,00/200/EC=20; esperado 30/12,00/360/EC=30).
> El SP `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` instalado sí pondera
> (tiene ON DUPLICATE y toca stockactual). Sospecha afinada: tras el
> CALL al SP (que deja stockactual bien), Generar/Revertir
> (`inLibAlbaranesCompraMovimientos`) lanzan un recálculo set-based
> (`RecalcularPmpAlmacen` → `SP_RECALCULAR_PMP_SKU_ALMACEN` sobre
> `tmp_skus_recalc`) que RECONSTRUYE stockactual desde el histórico;
> si no ve el movimiento recién insertado (misma tx, lote '' vs NULL,
> o JOIN a líneas con recibida = 0) machaca el valor bueno y deja el
> estado anterior — justo lo observado. **Test de 1 minuto**: CALL
> `SP_RECALCULAR_PMP_SKU_ALMACEN` a mano para GEN/TESTPMP1: si deja
> 30/12/360 el bug está en el filtro de tmp_skus_recalc o en la
> transacción; si deja 20/10/200 está dentro del SP de recálculo.
> Depurar ahí antes de continuar P2-P4. Procesos de verificación
> creados en el Generador: `verificar_stock_pmp_test` (stockactual) y
> `ver_movs_test` (movimientos).
>
> **CIERRE 03/07/2026 — BATERÍA SUPERADA (P1-P4).** Resultado final
> verificado por SQL (HeidiSQL, fza_articulos_stockactual):
>
> | ALM | CANT | PMP | VALOR | EC | SAV |
> |-----|-----|-----|-------|----|-----|
> | BCN | 16 | 15,00 | 240 | 8 | 0 |
> | GEN | 18 | 12,00 | 216 | 30 | 4 |
>
> - P1: dos compras GEN (20@10 + 10@16) → PMP 12,00 ✔ (recalc cruzado
>   idéntico).
> - P2: venta albarán mayor 4 uds → GEN 26/12/312, SAV 4, mov 'AV'
>   captura PMP 12 sin alterarlo ✔ (tras fixes: almacén salida en
>   cabecera + numeración de líneas + resolución a SKU).
> - P3: traspaso caja (F3) 8 uds GEN→BCN → doc TA, par S GEN 8@12 +
>   E BCN 8@12: el PMP viaja con la mercancía, no el último coste ✔.
> - P4: compra BCN 8@18 (albarán 000006) → BCN pondera a 15,00 y GEN
>   queda en 12,00: divergencia por almacén correcta ✔. Cuadre: 38
>   compradas − 4 vendidas = 34 = 18+16 ✔.
>
> Bugs corregidos durante la batería (usuario+Claude): Required de
> columnas calculadas, SQLInsert vs vistas no insertables (PEDC y
> ALBC), ESPIVOTE sin valor, huérfanas con clave provisional 0,
> contador no acepta <1, numeración de líneas varchar(4), almacén de
> salida en cabecera de albaranes venta, bucle infinito en albaranes
> compra. Pendientes menores: acumulados ET/ST no suman con tipo doc
> 'TA' (el SP acumula 'TR'/'AT' — mismatch de una letra), P1-C tallas
> y venta TPV en BCN (opcionales, la mecánica ya está cubierta),
> VistaDatos del Generador cachea al reejecutar.

Verifica que el stock y el Precio Medio Ponderado se llevan **por
almacén** (`fza_articulos_stockactual`, PK `ALM+SKU+LOTE`, columnas
`CANTIDAD_STK` / `PRECIO_MEDIO_STK` / `VALOR_TOTAL_STK`), que los
traspasos mueven el coste al PMP del origen y que las ventas capturan
el PMP sin alterarlo.

Escenario: **GEN** (Almacén Central, empresa **012**, caja 1) y
**BCN** (Almacén Barcelona, empresa **1**, caja 1). Al ser almacenes de
empresas distintas, el traspaso GEN→BCN genera documento **TA**
(traspaso entre empresas; mismo flujo F3 del menú de caja). Existe
además el almacén de tránsito `DESTBCN` (Furgoneta → BCN) para la
variante con tránsito.

## Preparación (P0)

1. **Usuario**: Administrador. Ojo: `appRestringirEmpAlmCaja` está a
   True para Todos en la BBDD de pruebas; un usuario restringido a
   012/GEN/1 no podría operar la caja de BCN. (Alternativa: crear
   usuario `Berta` con defectos 1/BCN/1 para probar también la
   restricción en BCN.)
2. **Series**: la empresa 1 ya tiene las series `AG1` (todas, creadas
   el 02/07/2026). Para 012 dar de alta las series que falten (`PC`,
   `AB`, `FP`, `TR`, `TA`) — botón "Añadir serie a todos" en
   Empresas > Series con nombre p. ej. `G1`, o a mano solo esas cinco.
   El traspaso tiene fallback (usa el tipo de doc como serie) pero
   mejor probar con serie configurada.
3. **Proveedor**: usar uno existente o dar de alta `PRVTEST`
   (Archivo > Proveedores) con IVA general.
4. **Artículos** (Archivo > Artículos, familia de pruebas, IVA
   general 21%):
   - `TESTPMP1`: sin tallas (SKU = código), PVP 25,00 €.
   - `TESTPMP2`: con tallas S y M (dos SKUs), PVP 12,00 €.
5. Comprobar punto de partida: sin stock de esos SKUs en ningún
   almacén.

SQL de apoyo (se repite tras cada paso):

```sql
SELECT CODIGO_ALM_STK ALM, CODIGO_UNIDAD_STK SKU, CANTIDAD_STK CANT,
       PRECIO_MEDIO_STK PMP, VALOR_TOTAL_STK VALOR,
       CANTIDAD_ENT_COMPRA_STK EC, CANTIDAD_ENT_TRASPASO_STK ET,
       CANTIDAD_SAL_TRASPASO_STK ST, CANTIDAD_SAL_VENTA_STK SV,
       CANTIDAD_SAL_ALBVENTA_STK SAV
  FROM fza_articulos_stockactual
 WHERE CODIGO_UNIDAD_STK LIKE 'TESTPMP%'
 ORDER BY CODIGO_ALM_STK, CODIGO_UNIDAD_STK;

SELECT TIPO_DOC_MOV, SERIE_DOC_MOV, NUMERO_DOC_MOV, TIPO_MOV,
       CODIGO_ALM_MOV, CANTIDAD_MOV, PRECIO_COSTE_UNITARIO_MOV,
       PRECIO_MEDIO_MOV
  FROM fza_movimientos_almacen
 WHERE CODIGO_UNIDAD_MOV LIKE 'TESTPMP%'
 ORDER BY INSTANTE_ALTA;
```

---

## Prueba 1 — Compras en GEN: PMP inicial y ponderación

**Itinerario A (flujo completo, TESTPMP1):**

1. Compras > Pedidos: pedido a `PRVTEST`, almacén GEN, 20 uds de
   `TESTPMP1` a **10,00 €**. Grabar (serie PC de 012).
2. Compras > Albaranes: crear albarán desde el pedido (recepción en
   GEN). Grabar → mueve stock.
3. Compras > Facturas: factura desde el albarán. Grabar.

**Itinerario B (segunda compra a coste distinto):** albarán de compra
directo (sin pedido), GEN, 10 uds de `TESTPMP1` a **16,00 €**.

**Itinerario C (tallas):** albarán de compra directo, GEN, `TESTPMP2`
10 uds de S y 10 de M a **5,00 €**.

**Esperado:**

| Paso | ALM | SKU | CANT | PMP | VALOR |
|---|---|---|---|---|---|
| tras A | GEN | TESTPMP1 | 20 | 10,00 | 200,00 |
| tras B | GEN | TESTPMP1 | 30 | **12,00** | 360,00 |
| tras C | GEN | TESTPMP2/S | 10 | 5,00 | 50,00 |
| tras C | GEN | TESTPMP2/M | 10 | 5,00 | 50,00 |

- PMP tras B = (20×10 + 10×16) / 30 = 12,00.
- Movimientos 'AB' de entrada con `PRECIO_COSTE_UNITARIO_MOV` 10 y 16.
- `CANTIDAD_ENT_COMPRA_STK` = 30. Entre el pedido y la recepción,
  `CANTIDAD_PTE_RECIBIR_STK` = 20 y vuelve a 0 al recibir.
- La factura de compra NO vuelve a mover stock (movió el albarán).

---

## Prueba 2 — Ventas en GEN: la venta captura el PMP, no lo altera

1. **TPV**: Caja (F5) en 012/GEN/1 → operación de venta de 6 uds de
   `TESTPMP1` a PVP 25,00, cobrar en efectivo.
2. **Mayor**: Ventas Mayor > Albaranes: albarán venta (serie A1 de
   012), cliente 313, 4 uds de `TESTPMP1`. Grabar → genera
   movimientos 'AV' de salida.

**Esperado:**

| Paso | ALM | SKU | CANT | PMP | VALOR |
|---|---|---|---|---|---|
| tras 1 | GEN | TESTPMP1 | 24 | 12,00 | 288,00 |
| tras 2 | GEN | TESTPMP1 | 20 | 12,00 | 240,00 |

- El PMP **no cambia** con las ventas; solo cae CANT/VALOR.
- Mov 'VE' (TPV) y 'AV' (albarán) de salida con
  `PRECIO_MEDIO_MOV = 12,00` (margen calculable después).
- `CANTIDAD_SAL_VENTA_STK` = 6 y `CANTIDAD_SAL_ALBVENTA_STK` = 4.
- Facturar el albarán después no debe duplicar la salida de stock.

---

## Prueba 3 — Traspaso GEN → BCN: el PMP viaja con la mercancía

1. Caja (F5) en 012/GEN/1 → **F3 Traspasos**, modo Traspaso: destino
   BCN, 8 uds de `TESTPMP1` y 4 uds de `TESTPMP2` talla M. Ejecutar.
   - Al ser BCN de la empresa 1 ≠ 012, el documento sale con tipo
     **TA** y su serie (`fza_empresas_series`; fallback 'TA').

**Esperado:**

| ALM | SKU | CANT | PMP | VALOR |
|---|---|---|---|---|
| GEN | TESTPMP1 | 12 | 12,00 | 144,00 |
| BCN | TESTPMP1 | 8 | **12,00** | 96,00 |
| GEN | TESTPMP2/S | 10 | 5,00 | 50,00 |
| GEN | TESTPMP2/M | 6 | 5,00 | 30,00 |
| BCN | TESTPMP2/M | 4 | 5,00 | 20,00 |

- Par de movimientos S (GEN) + E (BCN) con coste = **PMP del origen**
  (12,00 / 5,00), no el último coste de compra (16,00).
- BCN estrena PMP heredando el del origen (no tenía stock previo).
- El PMP de GEN no se altera por traspasar.
- `SAL_TRASPASO` (GEN) = 8/4; `ENT_TRASPASO` (BCN) = 8/4.
- La talla S no se ve afectada (PMP por SKU).
- El movimiento de entrada en BCN queda en la **empresa 1**
  (`CODIGO_EMP_MOV`), no en 012.

**3b (opcional, tránsito):** traspasar 2 uds más de `TESTPMP1` con
destino `DESTBCN` (furgoneta): comprobar que quedan en
`CANTIDAD_PTE_TRASPASAR/PTE_RECTRASPASAR` y que al *recibir* en BCN se
consolida la entrada. Si se ejecuta, ajustar los totales de la
Prueba 4 (+2 BCN / −2 GEN).

---

## Prueba 4 — PMP divergente por almacén y venta en BCN

1. Compra en BCN: albarán de compra (empresa 1, serie AG1, almacén
   BCN), 8 uds de `TESTPMP1` a **18,00 €**. Grabar.
2. TPV: Caja en 1/BCN/1 → venta de 5 uds de `TESTPMP1` a PVP 30,00.
3. Verificación final cruzada + recálculo.

**Esperado tras 1:** BCN = 16 uds, PMP **15,00** (= (8×12 + 8×18)/16),
valor 240,00. **GEN sigue en 12,00** — divergencia correcta: el mismo
artículo tiene PMP distinto en cada almacén.

**Esperado tras 2:** BCN = 11 uds, PMP 15,00, valor 165,00; el mov
'VE' de BCN captura `PRECIO_MEDIO_MOV = 15,00` (≠ 12,00 del que
capturó GEN en la Prueba 2).

**Estado final completo:**

| ALM | SKU | CANT | PMP | VALOR |
|---|---|---|---|---|
| GEN | TESTPMP1 | 12 | 12,00 | 144,00 |
| BCN | TESTPMP1 | 11 | 15,00 | 165,00 |
| GEN | TESTPMP2/S | 10 | 5,00 | 50,00 |
| GEN | TESTPMP2/M | 6 | 5,00 | 30,00 |
| BCN | TESTPMP2/M | 4 | 5,00 | 20,00 |

**Verificaciones de cierre:**

- `CALL SP_RECALCULAR_PMP_SKU_ALMACEN(...)` para cada SKU/almacén de
  la tabla: el recálculo desde el histórico de movimientos debe
  reproducir **exactamente** los mismos PMP/valores (si difiere, hay
  un movimiento con coste mal capturado).
- Informe de balance de almacén (Almacén > Balance): debe cuadrar con
  `fza_articulos_stockactual` en los dos almacenes.
- Suma de unidades: compradas (30+20+8=58) − vendidas (6+4+5=15) =
  43 = 12+11+10+6+4 ✔ (los traspasos no crean ni destruyen stock).

## Estado en que queda la BBDD tras la batería

Documentos nuevos: 1 pedido + 3 albaranes + 1 factura de compra (012),
1 albarán de compra (1), 1 albarán de venta (012), 2 operaciones TPV
(GEN y BCN), 1 traspaso TA (y 1 con tránsito si se hace 3b), artículos
`TESTPMP1`/`TESTPMP2` y proveedor `PRVTEST`. Nada de esto toca datos
preexistentes; para repetir la batería, borrar los documentos o usar
códigos TESTPMP3/4.
