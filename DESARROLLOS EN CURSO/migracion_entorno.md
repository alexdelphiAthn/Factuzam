# Migración del entorno (cajas, series, contadores, contador por familia)

"Ajuste del entorno": deja la instalación migrada lista para **operar**
(numeración, series y cajas), no migra documentos. Dominio del migrador
`src/utilmigsqlsrv/inLibMigEntorno.pas` (4 sub-dominios). **No** requiere
cambios de esquema: las cuatro tablas destino ya existen.

| Origen (SQL Server) | Destino (Factuzam) | Dominio |
|---|---|---|
| `dbo.occajas` | `fza_almacenes_cajas` | `entorno_cajas` |
| `dbo.occtador` + catálogo Factuzam | `fza_empresas_series` | `entorno_series` |
| `dbo.occtador` | `fza_contadores` | `entorno_contadores` |
| `dbo.ocnivnro` | `fza_articulos_familias.CONTADOR_ART_FAM` | `entorno_contadores_familia` |

## 1. Cajas (`occajas` → `fza_almacenes_cajas`)

Una fila por caja física (incluida la caja `99` central/virtual).
- `CODIGO_ALM_ALMCAJ` = `ocalm.Abreviatura` (fallback al número).
- `CODIGO_CAJA_ALMCAJ` = `occajas.Caja`.
- `DESCRIPCION_ALMCAJ` = `occajas.Nombre` (p.ej. `Alm: ZUÑIGA - Caja: 01`),
  con fallback `Alm: <alm> - Caja: <caja>`.

La tabla destino **no tiene columnas de auditoría**: idempotente por
`INSERT IGNORE` (PK almacén+caja). Requiere **Almacenes** migrados.

## 2. Series actuales (`occtador` + catálogo → `fza_empresas_series`)

No se migra `ocseract`. La configuración por almacén del legacy no representa
las filas por tipo documental que necesita Factuzam.

Para cada empresa se toma de `occtador` el ejercicio más reciente y su serie
principal. Si hay varias series en ese ejercicio, gana la utilizada por más
tipos documentales. En LosChicos el resultado es empresa `1`, ejercicio `2026`
y serie base `A1`.

Se crea una fila distinta para cada tipo presente en `fza_tipos_documentos`,
`fza_contadores` o `fza_empresas_series`:

- Serie general: `<Ejercicio>.<SerieBase>`; en este caso `2026.A1`.
- Factura normal: `2026.A1N` (`SUBTIPO_EMPSER='NORMAL'`).
- Factura simplificada: `2026.A1` (`SUBTIPO_EMPSER='SIMPLIFICADA'`).
- Factura rectificativa: `2026.A1R` (`SUBTIPO_EMPSER='RECTIFICATIVA'`).
- Vigencia: primer y último día del ejercicio.
- Empresa: la empresa propietaria del contador actual; almacén y caja quedan
  vacíos para que la serie sea general de empresa.

Los códigos internos se reservan con el contador global `ES`. Es re-ejecutable:
si ya existe la misma empresa, tipo, subtipo, serie y vigencia, se conserva.

## 3. Contadores (`occtador` → `fza_contadores`)

`occtador` numera por `(TipoDoc, Empresa, Almacén, Caja, Ejercicio, Serie)`,
pero `fza_contadores` solo por **`(TipoDoc, Empresa, Serie)`**. Consolidación:

- **El ejercicio va dentro de la serie**: `SERIE_CON = '<Ejercicio>.<Serie>'`
  (p.ej. `2025.A1`), igual que `SERIE_FAC` en facturas.
- **Almacén/caja se consolidan con el contador MÁXIMO** (`MAX(Contador)` por
  grupo). Tomar el máximo es seguro: garantiza que la numeración nueva no
  reutiliza números ya emitidos. Se usa `Contador` (no `ContadorCalculado`,
  que viene NULL en años recientes).
- **Contadores globales** del legacy (`Serie='-'`, p.ej. `CL`, `MV`, `PV`):
  van con `EMPRESA_CON='-'`, `SERIE_CON='-'`, `DEFAULT_CON='S'`.
- **Solo tipos del catálogo** `fza_tipos_documentos`: `VE, AL, AT, TR, FC,
  FP, IN, MV, CL, PV, PC, AE`. Los demás (`CB, CD, CM, CN, CR, DE, OV, OD,
  OM, PP, RO, VR`…) se **omiten** y se listan en el log
  (`contadores: N tipos legacy omitidos (fuera de catalogo): ...`).
- `NUM_DIGITOS_CON` = ancho deducido del propio contador (mínimo 6).

Re-ejecutable: al arrancar **borra** los contadores creados por este usuario
(`USUARIO_ALTA`) y reinserta (refresca el valor, no lo conserva). Requiere
**Empresas** migradas.

## 4. Contador por familia (`ocnivnro` → `fza_articulos_familias`)

`ocnivnro` ES el contador real del legacy por familia hoja: `Codigo` =
familia, `Contador` = último número de artículo emitido. El código de familia
coincide **literalmente** con `CODIGO_FAM_FAM` (la migración de familias
conserva `ocniv.Codigo`), y el código de artículo legacy es
`<familia 5 díg> + <contador padded>` (p.ej. `101010006` = familia `10101` +
`0006`). Por tanto:

`UPDATE fza_articulos_familias SET CONTADOR_ART_FAM = MAX(ocnivnro.Contador),
ESCONTADOR_ART_FAM='S' WHERE CODIGO_FAM_FAM = ocnivnro.Codigo`.

Idempotente (UPDATE). Requiere **Familias** migradas. Las familias sin fila
en `ocnivnro` conservan el valor que les puso la migración de familias.

### Ancho del contador (`PAD_ART_FAM`) — ya automático

El antiguo parámetro de UI **"Dígitos contador art."** se ha **eliminado**.
`MigrarFamilias` deduce el ancho automáticamente: longitud más común de los
códigos de artículo **numéricos** del legacy (`ocartp`) menos la longitud del
código de familia (p.ej. `9 - 5 = 4`). Si no hay códigos numéricos, usa 4.

## Orden de ejecución (waves)

- Wave 1 (tras Empresas/Familias de wave 0): `entorno_contadores`,
  `entorno_contadores_familia`.
- Wave 2 (tras Almacenes de wave 1): `entorno_cajas`, `entorno_series`.

## Pendiente / a revisar

- Tipos de contador fuera del catálogo (`OV` orden de venta, etc.): hoy se
  omiten. Si se quiere conservar su numeración, añadir el código a
  `MapearTipoContador` (y, si procede, a `fza_tipos_documentos`).
