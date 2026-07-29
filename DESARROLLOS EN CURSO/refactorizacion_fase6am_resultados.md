# Fase 6AM — balance por tallas Excel por pasos

Fecha: 29/07/2026. D4.3, tercera tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `ExportarBalanceTallasExcel` | 436 | 12 | **-424** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibBalanceTallasExcel` completa | 529 | 602 | **+73** |

Actualización posterior: D4.4 traslada el motor a
`inLibBalanceExcelComun`. La unidad queda como una fachada de 35 líneas
y comparte la implementación con el balance sin tallas. El balance
conjunto actualizado está en `refactorizacion_fase6an_resultados.md`.

La unidad crece un 13,8 % por el estado y el ciclo de vida explícitos
del exportador. El flujo público deja de mezclar el estado con todas las
operaciones locales: ahora es una fachada que crea, ejecuta y libera
`TExportadorBalanceTallas`.

El exportador tiene 16 operaciones internas, todas con consumidor. Con
constructor y destructor son 18 métodos; el mayor ocupa 46 líneas. No
se ha añadido ninguna abstracción sin uso.

## Implementación

`TExportadorBalanceTallas` conserva en un único contexto:

- la hoja, el dataset y la fila actual;
- los cortes de familia y artículo;
- las bandas y sus filas para las fórmulas;
- los tres niveles de agrupación;
- los acumulados de existencias y ventas;
- el diccionario de fotos precargadas.

Las operaciones separan la precarga de fotos, escritura y formato de
cabeceras, incrustación de imagen, detalle por talla, totales por banda,
cortes de grupo, total general y configuración de columnas.

Se conserva el comportamiento anterior:

- una sola consulta de fotos mediante `ResolverArticulosLote`;
- fórmulas `SUM` con `SepFormula` para que recalculen al editar;
- cierre del artículo antes de procesar el corte de grupo;
- jerarquía de tres niveles y reapertura de familia y artículo;
- existencias finales y ventas acumuladas por separado;
- `DisableControls`/`EnableControls` y `BeginUpdate`/`EndUpdate`;
- foto opcional sin deformación y referencia de proveedor opcional.

El ciclo de vida libera con `FreeAndNil` listas, diccionarios y fotos
también si falla la preparación previa al bloqueo de la hoja.

## Protección automática

`scripts/comprobar_flujos_largos.ps1` incorpora D4.3:

- `ExportarBalanceTallasExcel` no puede superar 100 líneas;
- las 16 operaciones internas deben existir una sola vez;
- cada operación debe tener un consumidor;
- ninguna puede superar 100 líneas;
- se exige la precarga de fotos en lote;
- se exige el par `BeginUpdate`/`EndUpdate`;
- el límite global baja de 48 a 47 métodos mayores de 200 líneas.

Resultado: fachada de 12 líneas y 47 métodos productivos por encima de
200, justo el nuevo límite.

## Pruebas automáticas

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 200/200 | 0 | 0 |
| Debug / Win32 | 0 errores | 200/200 | 0 | 0 |
| Release / Win64 | 0 errores | 200/200 | 0 | 0 |
| Release / Win32 | 0 errores | 200/200 | 0 | 0 |

La batería general no enlaza esta unidad, que depende directamente del
runtime visual de DevExpress. La compilación de la aplicación valida el
código extraído; la equivalencia visual y las fórmulas quedan cubiertas
por el plan funcional siguiente.

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d43/Win64/Release`: 0 errores, 316.245 líneas y
18,27 segundos.

También pasan:

- el comprobador de flujos largos;
- el comprobador de dependencias de capa;
- UTF-8 con BOM y CRLF en la unidad Pascal;
- ninguna línea de producción añadida por encima de 80 columnas;
- ningún `Exit` ni `Continue`;
- `git diff --check` limitado al alcance;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Pendiente de ejecución manual con datos representativos:

1. Exportar un resultado vacío y otro con una sola familia.
2. Combinar artículos, bandas, colores y las catorce tallas.
3. Revisar cortes de familia, artículo y grupos de niveles 1 a 3.
4. Editar detalles y confirmar el recálculo de todos los `SUM`.
5. Comparar existencias, importe y ventas con el informe FastReport.
6. Probar artículos con foto, sin foto y con distinta proporción.
7. Comprobar la referencia de proveedor presente y ausente.
8. Guardar el resultado como XLSX desde la vista previa.

El siguiente fascículo es **D4.4**:
`ExportarBalanceSinTallasExcel`.
