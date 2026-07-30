# Fase 2 — `inLibVentasWsJson` tras contrato

Fecha: 30/07/2026.

Estado: **IMPLEMENTADA Y VALIDADA EN RELEASE WIN32 + WIN64**.

## 1. Línea base

`inLibVentasWsJson` reunía:

- 505 líneas y 9 rutinas de implementación;
- 17 sentencias SQL literales, todas `SELECT`;
- serialización de cabecera, líneas, pagos, recibos, efectos, caja,
  movimientos, vales, depósitos, relaciones, datos fiscales,
  documentos PDF y fotos;
- una única llamada pública:
  `TVentasWsJson.ConstruirEvento`.

## 2. Diseño

- `inLibVentasWsJsonIntf` contiene `IVentasWsJson` y
  `TFabricaVentasWsJson`.
- `inLibVentasWsJson` queda como fachada sin SQL, conservando la firma
  estática de `TVentasWsJson.ConstruirEvento`.
- `UniDataVentasWsJson` conserva la serialización y las consultas
  originales e implementa el contrato mediante
  `TVentasWsJsonUniDAC`.
- El adaptador registra `CrearVentasWsJsonUniDAC` en
  `initialization`.
- La fábrica falla explícitamente con
  `SErrorVentasWsJsonNoRegistrado` si falta el adaptador.

No cambian las llamadas de `inLibVentasWsCola` ni de
`pruebaventasws/UPrincipal`.

## 3. Paridad del SQL

Las cinco asignaciones `SQL.Text` se compararon antes y después y son
idénticas. Las otras doce consultas viajan como parámetro de
`ConstruirArray`; el cuerpo completo de `ConstruirEvento` también se
comparó carácter a carácter y es idéntico.

```text
Antes:
  inLibVentasWsJson                 505/9   17 SQL

Después:
  inLibVentasWsJson                  52/1    0 SQL
  inLibVentasWsJsonIntf              64/2    0 SQL
  UniDataVentasWsJson               553/19  17 SQL
```

El trinquete de dominio baja de 249/61 a **232 sentencias en 60
unidades**. Las dependencias `inLib* -> UniData*` permanecen en 0/0.

## 4. Pruebas

`PruebasVentasWsJson` añade dos casos sin BBDD:

1. la fachada delega todos los parámetros y devuelve el JSON del
   servicio registrado;
2. la ausencia de fábrica falla de forma ruidosa.

El `TearDown` restaura el adaptador UniDAC real.

## 5. Verificación

```text
FactuzamTests Release Win32: compilado; 393/396
FactuzamTests Release Win64: compilado; 393/396
Casos nuevos: 2/2 en ambas plataformas
fzam Release Win32: compilado
fzam Release Win64: compilado
PruebaVentasWs Release Win32: compilado
```

Los tres fallos globales siguen siendo las expectativas conocidas del
catálogo: dos esperan 120 registros y obtienen 123; una espera
7 lecturas de caja y obtiene 10.

## 6. Ficheros de la tanda

- `src/Lib/inLibVentasWsJsonIntf.pas`
- `src/Lib/inLibVentasWsJson.pas`
- `src/DataModules/UniDataVentasWsJson.pas`
- `src/Lib/inLibMsgIntegraciones.pas`
- `tests/PruebasVentasWsJson.pas`
- `fzam.dpr`, `fzam.dproj`
- `tests/FactuzamTests.dpr`, `tests/FactuzamTests.dproj`
- `src/pruebaventasws/PruebaVentasWs.dpr`
- `src/pruebaventasws/PruebaVentasWs.dproj`
- `scripts/comprobar_sql_en_dominio.ps1`
- `scripts/comprobar_tamano_clases.ps1`
- `PLAN_SOLID.md`
