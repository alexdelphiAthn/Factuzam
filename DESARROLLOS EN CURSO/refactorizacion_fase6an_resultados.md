# Fase 6AN — motor común de balances Excel

Fecha: 29/07/2026. D4.4, cuarta tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `ExportarBalanceSinTallasExcel` | 405 | 5 | **-400** |
| `ExportarBalanceTallasExcel` | 12 | 5 | **-7** |
| Motor y fachadas | 1.094 | 738 | **-356** |
| Registro en `dpr`/`dproj` | 0 | 2 | **+2** |
| Total del alcance D4.4 | 1.094 | 740 | **-354** |

El punto de partida incluye la extracción D4.3. Frente a las dos
unidades originales, que sumaban 1.021 líneas, el motor común, las dos
fachadas y sus dos registros suman 740: **-281 líneas productivas**
acumuladas en D4.3 y D4.4.

`inLibBalanceExcelComun` ocupa 668 líneas. Sus 17 operaciones internas
tienen consumidor. Con constructor y destructor son 19 métodos; el
mayor ocupa 49 líneas.

## Implementación compartida

Las fachadas públicas conservan sus firmas y seleccionan uno de los dos
modos de `TExportadorBalanceExcel`:

- `tbeConTallas` para `ExportarBalanceTallasExcel`;
- `tbeSinTallas` para `ExportarBalanceSinTallasExcel`.

El motor comparte:

- precarga de fotos por artículo en una sola consulta;
- cabeceras de familia y artículo;
- acumulación y fórmulas de totales por banda;
- tres niveles de agrupación y sus resúmenes;
- total general de existencias, importe y ventas;
- incrustación y ajuste proporcional de la foto;
- bloqueo de la hoja y controles del dataset;
- propiedad y liberación de listas y diccionarios.

El modo conserva las diferencias reales:

- título con o sin tallas;
- catorce columnas `T01..T14` solo cuando corresponden;
- `Cdad.` en el balance por tallas y `Cantidad` en el otro;
- columna `Concepto` solo en el balance sin tallas;
- posiciones de cantidad, precio, importe, ventas y foto;
- anchos de columna específicos de cada informe.

No queda una segunda implementación del motor.

## Protección automática

`scripts/comprobar_flujos_largos.ps1` incorpora D4.4:

- las dos fachadas no pueden superar 100 líneas;
- cada fachada debe seleccionar su modo correcto;
- las 17 operaciones del motor deben existir una sola vez;
- cada operación debe tener consumidor y no superar 100 líneas;
- se conservan títulos, etiquetas y campos de talla;
- se conservan la precarga de fotos y el bloqueo de hoja;
- el límite global baja de 47 a 46 métodos mayores de 200 líneas.

Resultado: fachadas de 5 líneas y 46 métodos productivos por encima de
200, justo el nuevo límite.

## Pruebas automáticas

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 204/205 | 0 | 1 |
| Debug / Win32 | 0 errores | 204/205 | 0 | 1 |
| Release / Win64 | 0 errores | 204/205 | 0 | 1 |
| Release / Win32 | 0 errores | 204/205 | 0 | 1 |

La batería general no enlaza estas unidades, que dependen directamente
del runtime visual de DevExpress. La aplicación valida el motor y las
dos fachadas; la equivalencia visual queda en el plan funcional.

La única prueba roja es
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption`. Un cambio
concurrente ajeno a D4.4 ha desactivado la sustitución de captions en
`inLibGestorPerfilesMto`, pero la prueba antigua todavía espera
`Perfil activo` en vez de `Original`. La ejecución repetida confirma que
es determinista. No se ha modificado ese trabajo desde esta fase.

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d44/Win64/Release`: 0 errores, 316.105 líneas y
12,69 segundos.

También pasan:

- el comprobador de flujos largos;
- el comprobador de dependencias de capa;
- UTF-8 con BOM y CRLF en las tres unidades Pascal;
- ninguna línea de producción añadida por encima de 80 columnas;
- ningún `Exit` ni `Continue`;
- `git diff --check` limitado al alcance;
- D4.4 no modifica `factuzam_original.sql`.

Durante la validación apareció una modificación concurrente ajena a
D4.4 en `factuzam_original.sql` (95 líneas añadidas y 6 eliminadas).
Incumple la regla dura del repositorio y queda pendiente de revisión por
su autor; esta fase no la revierte ni la incorpora a su alcance.

## Plan de comprobación funcional

Pendiente de ejecución manual con los dos informes:

1. Exportar resultados vacíos y con una sola familia.
2. Comparar títulos, cabeceras y anchos de ambos modos.
3. Probar bandas, colores y las catorce tallas.
4. Revisar cortes de familia, artículo y grupos de niveles 1 a 3.
5. Editar detalles y confirmar el recálculo de los `SUM`.
6. Comparar existencias, importe y ventas con FastReport.
7. Probar artículos con foto, sin foto y con referencia de proveedor.
8. Guardar ambos resultados como XLSX desde la vista previa.

El siguiente fascículo es **D4.5**:
`ExportarFacturaADevExpress`.
