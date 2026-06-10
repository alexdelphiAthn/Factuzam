# Arqueo — niveles de familia en "Resumen neto por sección"

## Qué

El bloque **RESUMEN NETO POR SECCIÓN** del arqueo (cierre Z) agrupaba las
ventas siempre a 2 niveles fijos: `PADRE-HIJO` (familia + su padre inmediato
vía `CODIGO_SUBFAMILIA_FAM`). Ahora el número de niveles de la jerarquía de
familias que se desglosan es **configurable**.

## Parámetro (Parámetros de Caja)

- **Clave**: `vgerArqueoNivelesFamilia`
- **Categoría**: `Arqueo`
- **Tipo**: entero
- **Por defecto**: `2` (reproduce el comportamiento anterior)
- **Rango saneado**: `[1..9]` (ver `inLibCajaParam.NivelesFamiliaArqueo`)

Semántica (N = valor del parámetro):

| N | Qué sale |
|---|----------|
| 1 | Solo la **sección** raíz. Todo se acumula en el ancestro de nivel 1. |
| 2 | `seccion-familia` (comportamiento clásico). |
| 3 | `seccion-familia-subfamilia`. |
| … | Un nivel más por cada unidad. |

Una familia más profunda que N se agrega a su ancestro de nivel N; una
familia menos honda que N muestra su ruta completa.

## No requiere cambios de esquema

El parámetro se persiste con el resto de parámetros de caja a través de
`PRC_SETPERFILFORMULARIO` / `PRC_GETPERFILFORMULARIO` (formulario
`frmMtoCajaParam`). No hay DDL. El formulario `inMtoCajaParam` lo dibuja
automáticamente al leer `oCajaParams.Params` (categoría `Arqueo`).

## Implementación

La consulta la construye `TArqueoCalculadora.SQLResumenSeccion(ANiveles,
AOrden)` en `src/Caja/Lib/inLibArqueo.pas`, compartida por los dos
consumidores (solo difieren en el `ORDER BY`):

- `src/Caja/Lib/inLibArqueoTicket.pas` — `EscribirResumenSeccion` (ticket
  impreso, `NETO DESC`).
- `src/Caja/Modals/inMtoModalArqueo.pas` — `ConfigurarResumenes`/`qryResFam`
  (pestaña Resúmenes, `FAMILIA`).

La jerarquía se resuelve con **8 `LEFT JOIN` estáticos** sobre
`fza_articulos_familias` (`a1` = padre, `a2` = abuelo, …, vía
`CODIGO_SUBFAMILIA_FAM`), no con un CTE recursivo. `CONCAT_WS('|', a8…a1, f)`
monta la ruta raíz→hoja (ignora los ancestros NULL),
`SUBSTRING_INDEX(ruta, '|', N)` recorta a los N primeros niveles y un
`REPLACE` cambia el separador `|` por el visual `-`. Profundidad máxima
soportada: 9 niveles (de ahí el tope del parámetro).

**Por qué NO un `WITH RECURSIVE` (no "modernizar" esto).** Se intentó y en
producción lanzaba `[1267] Illegal mix of collations
(utf8mb4_uca1400_ai_ci vs utf8mb4_spanish_ci) for operation '='`: las
columnas de la tabla temporal de un CTE recursivo salen con la colación de
la **conexión** (en MariaDB ≥11.5 el default de utf8mb4 es
`uca1400_ai_ci`), no con la de las tablas (`utf8mb4_spanish_ci`), y el JOIN
recursivo mezcla ambas. Ni siquiera un `COLLATE` en el `CAST` del ancla lo
cura del todo. Con joins estáticos solo se comparan columnas reales entre
sí y el problema desaparece por construcción (y además funciona en
servidores sin soporte de CTE).

El nivel saneado lo entrega `inLibCajaParam.NivelesFamiliaArqueo` y se
inyecta como literal entero en el SQL (no como parámetro, porque
`qryResFam` comparte el binder `AbrirQryConParams` con el resto de
consultas del arqueo).
