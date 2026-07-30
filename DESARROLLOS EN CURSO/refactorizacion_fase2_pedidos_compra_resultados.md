# Fase 2 — `inLibPedidosCompra` tras contrato

Fecha: 30/07/2026.

Estado: **IMPLEMENTADA Y VALIDADA EN RELEASE WIN32 + WIN64**.

## 1. Línea base real

El analizador vigente encontró en `inLibPedidosCompra`:

- 1.695 líneas y 30 rutinas de implementación;
- 28 sentencias SQL literales: 10 `SELECT`, 7 `INSERT`, 8 `UPDATE` y
  3 `DELETE`;
- ocho operaciones públicas: pendientes de recibir, creación e
  incorporación de albaranes —con sus variantes por celdas—, cálculo
  del pendiente y el caso de uso transaccional de recepción.

La cifra de 15 sentencias de `PLAN_SOLID.md` pertenecía a una línea base
anterior. Los bloques `SQL.Text` antes y después de la extracción se
compararon automáticamente: 28/28, idénticos y en el mismo orden.

## 2. Diseño

- `inLibPedidosCompraIntf` contiene los dos `record` públicos,
  `IPedidosCompra` y `TFabricaPedidosCompra`.
- `inLibPedidosCompra` queda como fachada sin SQL, con las mismas ocho
  firmas públicas y alias de los dos tipos históricos.
- `UniDataPedidosCompraOperaciones` implementa el contrato, conserva el
  SQL y la transacción originales y registra
  `CrearPedidosCompraUniDAC` en `initialization`.
- La fábrica falla de forma explícita mediante
  `SErrorPedidosCompraNoRegistrados` si no hay adaptador registrado.

Los consumidores mantienen sus llamadas:
`UniDataPedidosCompra`, `UniDataComprasSesionesAlbaranes`,
`inMtoPedidosCompra` e `inMtoModalSelAlmacenPedido`.

## 3. Medición

```text
Antes:
  inLibPedidosCompra                         1.695/30   28 SQL

Después:
  inLibPedidosCompra                          174/8     0 SQL
  inLibPedidosCompraIntf                      111/2     0 SQL
  UniDataPedidosCompraOperaciones           1.748/57  28 SQL
```

El trinquete de dominio baja de 277/62 a **249 sentencias en 61
unidades**. `comprobar_dependencias_capas.ps1` mantiene
`inLib* -> UniData*` en 0/0.

## 4. Pruebas sin BBDD

`PruebasPedidosCompra` añade seis casos que cubren los ocho puntos de
la fachada:

1. generar y borrar pendientes;
2. crear albarán, con y sin cantidades por celdas;
3. calcular el pendiente total;
4. incorporar, con y sin cantidades por celdas;
5. ejecutar el caso de uso transaccional con sus `record`;
6. fábrica ausente: fallo ruidoso.

La fábrica falsa verifica los parámetros y resultados. El `TearDown`
restaura el adaptador UniDAC real.

## 5. Verificación

```text
FactuzamTests Release Win32: compilado
Batería: 389/392; los 6 casos del foco pasan

FactuzamTests Release Win64: compilado
Batería: 390/393; los 6 casos del foco pasan

fzam Release Win32: compilado
fzam Release Win64: compilado con salida alternativa
```

Los tres fallos globales son las expectativas del catálogo ya
identificadas: dos esperan 120 registros y obtienen 123; una espera
7 lecturas de caja y obtiene 10.

La salida normal Win64 de `fzam` estaba bloqueada por una instancia
abierta del ejecutable. Sin cerrar el proceso del usuario, se repitió
la compilación enviando el ejecutable a
`build/validacion_pedidos_compra/app/Win64_Release`, con resultado
correcto.

## 6. Ficheros de la tanda

- `src/Lib/inLibPedidosCompraIntf.pas`
- `src/Lib/inLibPedidosCompra.pas`
- `src/DataModules/UniDataPedidosCompraOperaciones.pas`
- `src/Lib/inLibMsgCompras.pas`
- `tests/PruebasPedidosCompra.pas`
- `fzam.dpr`, `fzam.dproj`
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj`
- `scripts/comprobar_sql_en_dominio.ps1`
- `scripts/comprobar_flujos_largos.ps1`
- `scripts/comprobar_tamano_clases.ps1`
- `PLAN_SOLID.md`
