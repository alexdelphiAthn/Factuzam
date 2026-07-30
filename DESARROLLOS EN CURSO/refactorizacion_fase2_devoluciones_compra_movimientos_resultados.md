# Fase 2 — `inLibDevolucionesCompraMovimientos` tras contrato

Fecha: 30/07/2026.

Estado: **IMPLEMENTADA Y VALIDADA EN RELEASE WIN32 + WIN64**.

## 1. Línea base

`inLibDevolucionesCompraMovimientos` reunía:

- 417 líneas;
- 9 asignaciones `SQL.Text`;
- generación de salidas de almacén desde líneas o celdas;
- protección frente a generación duplicada;
- reversión y recálculo de PMP y stock;
- dos procedimientos públicos consumidos por
  `UniDataDevolucionesCompra`.

## 2. Diseño

- `inLibDevolucionesCompraMovimientosIntf` contiene
  `IMovimientosDevolucionCompra` y
  `TFabricaMovimientosDevolucionCompra`.
- `inLibDevolucionesCompraMovimientos` queda como fachada sin SQL y
  conserva las dos firmas públicas.
- `UniDataDevolucionesCompraMovimientos` contiene la implementación
  UniDAC original y registra `CrearMovimientosDevolucionCompraUniDAC`
  en `initialization`.
- La fábrica falla explícitamente con
  `SErrorMovimientosDevolucionCompraNoRegistrados` si falta el
  adaptador.

No cambian las llamadas de `UniDataDevolucionesCompra`.

## 3. Paridad del SQL

Las nueve asignaciones `SQL.Text` se compararon antes y después y son
idénticas carácter a carácter.

```text
Antes:
  inLibDevolucionesCompraMovimientos           417    9 SQL

Después:
  inLibDevolucionesCompraMovimientos            56    0 SQL
  inLibDevolucionesCompraMovimientosIntf         62    0 SQL
  UniDataDevolucionesCompraMovimientos          447    9 SQL
```

El trinquete de dominio baja de 232/60 a **223 sentencias en 59
unidades**. Las dependencias `inLib* -> UniData*` permanecen en 0/0.

## 4. Pruebas

`PruebasDevolucionesCompraMovimientos` añade tres casos sin BBDD:

1. la generación delega serie, número y usuario;
2. la reversión delega serie, número y usuario;
3. la ausencia de fábrica falla de forma ruidosa.

El `TearDown` restaura el adaptador UniDAC real.

## 5. Verificación

```text
FactuzamTests Release Win32: compilado; 396/399
FactuzamTests Release Win64: compilado; 396/399
Casos nuevos: 3/3 en ambas plataformas
fzam Release Win32: compilado
fzam Release Win64: compilado
SQL en dominio: 223/59, correcto
Dependencias inLib* -> UniData*: 0/0, correcto
SQL/transacciones: correcto
Supports: correcto
Tamaño focal: correcto
```

Los tres fallos globales de DUnitX siguen siendo las expectativas
conocidas del catálogo: dos esperan 120 registros y obtienen 123; una
espera 7 lecturas de caja y obtiene 10.

Los trinquetes globales de tamaño y acoplamiento tienen regresiones
concurrentes ajenas a esta tanda:

- `inLibLog` presenta fan-in 85 con tope 84;
- `TfrmMtoFacturasBase`, `TfrmMtoOpeCaja` y
  `TfrmStockConsulta` superan sus topes de líneas.

Las tres unidades de esta extracción cumplen sus topes focales.

## 6. Ficheros de la tanda

- `src/Lib/inLibDevolucionesCompraMovimientosIntf.pas`
- `src/Lib/inLibDevolucionesCompraMovimientos.pas`
- `src/DataModules/UniDataDevolucionesCompraMovimientos.pas`
- `src/Lib/inLibMsgCompras.pas`
- `tests/PruebasDevolucionesCompraMovimientos.pas`
- `fzam.dpr`, `fzam.dproj`
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj`
- `scripts/comprobar_sql_en_dominio.ps1`
- `scripts/comprobar_tamano_clases.ps1`
- `PLAN_SOLID.md`
