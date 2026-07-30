# Fase 2 — `inLibAlbaranesCompraMovimientos` tras contrato

Fecha: 30/07/2026.

Estado: **IMPLEMENTADA; PRUEBAS DUNITX DEL FOCO SUPERADAS**. El proyecto
`FactuzamTests` compila en Release Win32 y Win64 y los tres casos de
albaranes de compra pasan en ambas plataformas. La batería global queda
en 363/369 por seis incidencias ajenas al foco, detalladas en §7.

## 1. Línea base

`src/Lib/inLibAlbaranesCompraMovimientos.pas` reunía:

- 634 líneas y 6 rutinas;
- 12 sentencias SQL literales con el analizador vigente
  (4 `SELECT`, 3 `INSERT`, 1 `UPDATE`, 1 `CALL`, 3 DDL de la tabla
  temporal); el 26 de la tabla del plan procedía de la línea base
  anterior;
- dos operaciones públicas acopladas a `TUniConnection`: generación y
  reversión de movimientos de almacén (SP
  `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`, borrado por documento y
  recálculo de PMP con `SP_RECALCULAR_PMP_LOTE_ALMACEN`).

Consumidores con llamada real: `UniDataAlbaranesCompra` (3),
`UniDataComprasSesionesAlbaranes` (1) e `inLibPedidosCompra` (3).

## 2. Diseño: contrato con fábrica registrable

Inyectar el servicio por parámetro habría arrastrado la firma por toda
la cadena de `inLibPedidosCompra` (que es el siguiente foco y cambiará
de API en su propia tanda). Se usa el patrón ya sancionado de
`TFabricaModoTallas` (§14.4: la unidad `UniData*` se registra en su
`initialization`; el dominio no la conoce):

- `inLibAlbaranesCompraMovimientosIntf` (58/2): puerto
  `IMovimientosAlbaranCompra` (generar/revertir por serie, número y
  usuario) y `TFabricaMovimientosAlbaranCompra` con registro y fallo
  ruidoso (`SErrorMovimientosAlbaranCompraNoRegistrados`, nuevo en
  `inLibMsgCompras`).
- `inLibAlbaranesCompraMovimientos` (68/2, **0 SQL**): fachada con las
  mismas firmas públicas de siempre; resuelve el puerto vía fábrica y
  delega. **Ningún consumidor cambia de llamada.**
- `UniDataAlbaranesCompraMovimientos` (657/13, 12 SQL): implementación
  movida verbatim (cabecera, fuentes líneas/celdas, SP de inserción,
  fecha, proveedor y costes SKU, reversión con recálculo de PMP), el
  adaptador `TMovimientosAlbaranCompraUniDAC` y el registro en
  `initialization`. La gestión transaccional no cambia: la transacción
  sigue siendo del llamante, documentado en la fachada.

## 3. Medición

```text
Antes:   inLibAlbaranesCompraMovimientos            634/6   12 SQL
Después: fachada + contrato                          68/2 + 58/2   0 SQL
         UniDataAlbaranesCompraMovimientos          657/13  12 SQL
```

Las 12 sentencias conservan tipos y texto (movidas sin tocar). El
dominio `inLib*` pierde 12 sentencias y una unidad con SQL: los topes
de `comprobar_sql_en_dominio.ps1` bajan de 304/64 a **292/63**. Las
tres unidades entran vigiladas en `comprobar_tamano_clases.ps1`
(68/2, 58/2 y 657/13; objetivos 600/30 y 1.200/30). Ningún tope sube.

## 4. Pruebas sin BBDD

`PruebasAlbaranesCompraMovimientos` añade tres casos:

1. la fachada delega la generación en el servicio registrado con todos
   los datos;
2. la fachada delega la reversión;
3. fábrica ausente: fallo ruidoso.

El `TearDown` restaura la fábrica UniDAC real
(`CrearMovimientosAlbaranCompraUniDAC`), lo que además compila
explícitamente el adaptador en `FactuzamTests`. Los tres casos se
ejecutaron correctamente en Release Win32 y Win64 el 30/07/2026.

## 5. Incidencia con la tanda concurrente

La tanda concurrente de traducciones sobrescribió `fzam.dpr` y
`FactuzamTests.dpr` desde una copia anterior y se perdieron las altas
de `UniDataVerifactuColaOperaciones` (VFC-R3) y
`inLibAnfitrionDatosIntf` (2b). Esta tanda las repone junto con las
suyas; los `.pas`, scripts y documentos no se vieron afectados.

## 6. Ficheros tocados

- `src/Lib/inLibAlbaranesCompraMovimientosIntf.pas` (nueva)
- `src/Lib/inLibAlbaranesCompraMovimientos.pas` (fachada sin SQL)
- `src/DataModules/UniDataAlbaranesCompraMovimientos.pas` (nueva)
- `src/Lib/inLibMsgCompras.pas` (mensaje nuevo)
- `tests/PruebasAlbaranesCompraMovimientos.pas` (nueva)
- `fzam.dpr` y `tests/FactuzamTests.dpr` (altas + reposición de las
  perdidas)
- `scripts/comprobar_sql_en_dominio.ps1` (topes 292/63)
- `scripts/comprobar_tamano_clases.ps1` (tres unidades vigiladas)
- `PLAN_SOLID.md` (§3.1, §4 Fase 2, §6 y §8)

## 7. Verificación DUnitX

Ejecutada el 30/07/2026 con Delphi 37.0:

```text
FactuzamTests Release Win32: compilado
PruebasAlbaranesCompraMovimientos: 3/3
Batería global: 363/369, 0 ignoradas y 0 fugas

FactuzamTests Release Win64: compilado
PruebasAlbaranesCompraMovimientos: 3/3
Batería global: 363/369, 0 ignoradas y 0 fugas
```

Los tres casos del foco no figuran entre los fallos ni los errores
notificados por DUnitX. Las seis incidencias globales son idénticas en
las dos plataformas y quedan fuera de esta tanda:

- tres expectativas desactualizadas del catálogo SQL: dos esperan 120
  registros y obtienen 123; otra espera 7 lecturas de caja y obtiene
  10;
- tres pruebas de `PruebasConexiones` no pueden crear la conexión
  porque el ejecutable no registra `MySQLUniProvider`. **Causa
  encontrada:** el proveedor llegaba por arrastre del `uses` de
  `UniDataConn` en `inLibGridColumnChooser`, retirado en la Fase 2b
  por no referenciar ningún símbolo; era código muerto en compilación
  pero cargaba el proveedor en el enlace de `FactuzamTests`.
  **Corregido:** `MySQLUniProvider` se registra ahora explícito en el
  `uses` de `FactuzamTests.dpr`, con comentario.

## 8. Pendiente

1. Resolver las tres expectativas desactualizadas del catálogo SQL
   (tanda concurrente) y repetir la batería global hasta dejarla
   completamente en verde; las tres de `PruebasConexiones` quedan
   corregidas con el registro explícito del proveedor.
2. Ejecutar los trinquetes y la compilación global de la aplicación al
   cerrar las tandas concurrentes.
3. Siguiente foco de la Fase 2: `inLibPedidosCompra` (15 sentencias).
