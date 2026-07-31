# Fase 2 — SQL de `inLibFotos` tras contrato

Fecha: 31/07/2026.

Estado: **IMPLEMENTADA Y VALIDADA EN RELEASE WIN32 + WIN64**.

## 1. Línea base

`inLibFotos` contenía:

- 1.975 líneas;
- 19 sentencias SQL literales;
- persistencia de fotos de artículos, SKU y sesiones de compra;
- gestión de archivos PNG en 300/600/real;
- resolución con fallback y caché por lote;
- integración con FastReport y fotos embebidas en formularios.

Es una unidad de infraestructura. La extracción no introduce records de
negocio ni mueve la lógica de archivos, resolución o presentación.

## 2. Diseño

- `inLibFotosPersistenciaIntf` define `IRepositorioFotos` y su fábrica
  registrable.
- Los métodos de lectura devuelven `TDataSet`; el contrato documenta que
  el llamador es su propietario.
- `UniDataFotosRepositorio` implementa el puerto con UniDAC y registra
  la fábrica en `initialization`.
- `inLibFotos` conserva su API pública y recibe el repositorio al ejecutar
  `TFotosArticulos.AsignarConexion`.
- La ausencia del adaptador falla explícitamente con
  `SErrorPersistenciaFotosNoRegistrada`.

Las consultas repetidas por artículo/unidad y por foto de sesión se
centralizan en un único método del repositorio. Por eso las 19
construcciones originales quedan en 14 construcciones reutilizables en
el adaptador, manteniendo tablas, filtros, orden, parámetros y
operaciones de escritura.

## 3. Resultado medido

```text
Antes:
  inLibFotos                         1.975/43   19 SQL

Después:
  inLibFotos                         1.763/43    0 SQL
  inLibFotosPersistenciaIntf            96/2     0 SQL
  UniDataFotosRepositorio              466/33   14 SQL
```

El trinquete de dominio baja de 212/58 a **193 sentencias en 57
unidades**. Las dependencias `inLib* -> UniData*` permanecen en 0/0.

`inLibFotos` y el adaptador quedan vigilados por tamaño. Ambos superan
el objetivo orientativo de 30 rutinas, pero respetan los topes de esta
tanda; su separación SRP posterior no forma parte de la extracción SQL.

## 4. Pruebas

`PruebasFotosPersistencia` añade tres casos sin BBDD:

1. la fábrica registrada se invoca sin abrir una conexión;
2. la ausencia de fábrica falla de forma ruidosa;
3. los prefijos de SKU se ordenan de más a menos específico.

El `TearDown` restaura el adaptador UniDAC real.

## 5. Verificación

```text
FactuzamTests Release Win32: compilado; 408/411
FactuzamTests Release Win64: compilado; 408/411
Casos nuevos: 3/3 en ambas plataformas
fzam Debug Win64: compilado
fzam Release Win32: compilado
fzam Release Win64: compilado
SQL en dominio: 193/57, correcto
Dependencias inLib* -> UniData*: 0/0, correcto
SQL/transacciones: correcto
Supports: correcto
```

Los tres fallos globales de DUnitX siguen siendo las expectativas
conocidas del catálogo: dos esperan 120 registros y obtienen 123; una
espera 7 lecturas de caja y obtiene 10.

La compilación global ya no está bloqueada por la ausencia de
`inLibMsgRegistroTraducciones.pas`: no quedan referencias activas a esa
unidad. Los trinquetes globales de tamaño y acoplamiento conservan
regresiones concurrentes ajenas a esta tanda.

## 6. Ficheros de la tanda

- `src/Lib/inLibFotosPersistenciaIntf.pas`
- `src/DataModules/UniDataFotosRepositorio.pas`
- `src/Lib/inLibFotos.pas`
- `src/Lib/inLibMsgArticulos.pas`
- `tests/PruebasFotosPersistencia.pas`
- `fzam.dpr`, `fzam.dproj`
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj`
- `scripts/comprobar_sql_en_dominio.ps1`
- `scripts/comprobar_tamano_clases.ps1`
- `PLAN_SOLID.md`
