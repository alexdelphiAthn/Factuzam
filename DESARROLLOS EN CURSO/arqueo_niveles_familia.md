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

La jerarquía se recorre con un CTE recursivo (`WITH RECURSIVE fam_ruta`)
sobre `fza_articulos_familias`, construyendo la ruta raíz→hoja como
`NOMBRE|NOMBRE|…`. `SUBSTRING_INDEX(ruta, '|', N)` recorta a los N primeros
niveles y un `REPLACE` cambia el separador interno `|` por el visual `-`.

**OJO con la colación (no quitar el `COLLATE`).** El ancla del CTE hace
`CAST(... AS CHAR(2000)) COLLATE utf8mb4_spanish_ci`. El `CAST` produce la
colación por defecto del servidor (en MariaDB moderno `utf8mb4_uca1400_ai_ci`),
que choca con las columnas de la BBDD (`utf8mb4_spanish_ci`) dentro del
`CONCAT`/recursión y lanza `[1267] Illegal mix of collations` al comparar.
El `COLLATE` fuerza la ruta a la colación de las tablas. Si algún día se
regenera la BBDD con otra colación, hay que ajustar este `COLLATE`.

Tocado en dos sitios (ambos comparten la misma consulta):

- `src/Caja/Lib/inLibArqueoTicket.pas` — `EscribirResumenSeccion` (ticket
  impreso).
- `src/Caja/Modals/inMtoModalArqueo.pas` — `ConfigurarResumenes`/`qryResFam`
  (vista en pantalla, pestaña Resúmenes).

El nivel saneado lo entrega `inLibCajaParam.NivelesFamiliaArqueo` y se inyecta
como literal entero en el SQL (no como parámetro, porque `qryResFam` comparte
el binder `AbrirQryConParams` con el resto de consultas del arqueo).
