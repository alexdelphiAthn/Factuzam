# Fase 2 — `inLibArticulosVariaciones` tras contrato

Fecha: 31/07/2026.

Estado: **IMPLEMENTADA Y VALIDADA EN RELEASE WIN32 + WIN64**.

## 1. Línea base

`inLibArticulosVariaciones` reunía:

- 629 líneas y 16 rutinas de implementación;
- 11 sentencias SQL: 7 `SELECT`, 2 `INSERT`, 1 `UPDATE` y 1
  `DELETE`;
- tres operaciones públicas de garantía de SKU;
- el gestor visual `TGestorVariaciones`, consumido por
  `inMtoArticulos`.

## 2. Diseño

- `inLibArticulosVariacionesIntf` contiene
  `IArticulosVariaciones`, `IGestorArticulosVariaciones` y la fábrica
  registrable `TFabricaArticulosVariaciones`.
- `inLibArticulosVariaciones` queda como fachada sin SQL y conserva:
  - `TGestorVariaciones` y sus propiedades;
  - `AsegurarSkuArticuloSinVariaciones`;
  - `AsegurarSkuArticuloActivo`;
  - `ArticuloTieneSkuActivo`.
- `UniDataArticulosVariaciones` implementa ambos contratos, conserva
  la lógica anterior y registra `CrearArticulosVariacionesUniDAC` en
  `initialization`.
- La fábrica falla explícitamente con
  `SErrorArticulosVariacionesNoRegistradas` si falta el adaptador.

No cambian las llamadas de `inMtoArticulos` ni de
`inLibArticulosCodigosBarras`.

## 3. Paridad del SQL

Las once asignaciones `SQL.Text` se compararon antes y después y son
idénticas carácter a carácter.

```text
Antes:
  inLibArticulosVariaciones           629/16   11 SQL

Después:
  inLibArticulosVariaciones           136/10    0 SQL
  inLibArticulosVariacionesIntf        73/2     0 SQL
  UniDataArticulosVariaciones         692/43   11 SQL
```

El trinquete de dominio baja de 223/59 a **212 sentencias en 58
unidades**. Las dependencias `inLib* -> UniData*` permanecen en 0/0.

El adaptador cumple el tope duro de 1.200 líneas. Su medición de 43
rutinas queda por encima del objetivo de 30 porque el trinquete cuenta
en `implementation` tanto las declaraciones privadas de las dos
clases como sus implementaciones. Una separación posterior entre
gestor visual y persistencia permitiría reducir esa cifra.

## 4. Pruebas

`PruebasArticulosVariaciones` añade cinco casos sin BBDD:

1. garantizar un SKU sin variaciones delega código y usuario;
2. garantizar un SKU activo delega código y usuario;
3. la consulta de SKU activo devuelve el resultado del servicio;
4. `TGestorVariaciones` delega operaciones y propiedades;
5. la ausencia de fábrica falla de forma ruidosa.

El `TearDown` restaura el adaptador UniDAC real.

## 5. Verificación

```text
FactuzamTests Release Win32: compilado; 401/404
FactuzamTests Release Win64: compilado; 401/404
Casos nuevos: 5/5 en ambas plataformas
fzam Release Win32: compilado
fzam Release Win64: compilado
SQL en dominio: 212/58, correcto
Dependencias inLib* -> UniData*: 0/0, correcto
SQL/transacciones: correcto
Supports: correcto
Tamaño focal: correcto
```

Los tres fallos globales de DUnitX siguen siendo las expectativas
conocidas del catálogo: dos esperan 120 registros y obtienen 123; una
espera 7 lecturas de caja y obtiene 10.

Los trinquetes globales de tamaño y acoplamiento conservan regresiones
concurrentes ajenas a esta tanda:

- `inLibLog` presenta fan-in 85 con tope 84;
- `TfrmMtoFacturasBase`, `TfrmMtoOpeCaja` y
  `TfrmStockConsulta` superan sus topes de líneas.

## 6. Ficheros de la tanda

- `src/Lib/inLibArticulosVariacionesIntf.pas`
- `src/Lib/inLibArticulosVariaciones.pas`
- `src/DataModules/UniDataArticulosVariaciones.pas`
- `src/Lib/inLibMsgArticulos.pas`
- `tests/PruebasArticulosVariaciones.pas`
- `fzam.dpr`, `fzam.dproj`
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj`
- `scripts/comprobar_sql_en_dominio.ps1`
- `scripts/comprobar_tamano_clases.ps1`
- `PLAN_SOLID.md`
