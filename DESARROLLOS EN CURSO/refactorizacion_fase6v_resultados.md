# Fase 6V — filtros guardados de `TfrmMtoGen`

Fecha: 28/07/2026. D2.1 y primer fascículo de D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 3.346 | 2.985 | **-361** |
| Nuevo `inLibGestorFiltrosMto` | 0 | 445 | +445 |
| Total productivo del alcance | 3.346 | 3.430 | **+84** |

La clase dios baja un 10,8 %. El alcance productivo completo crece un
2,5 % por el contrato del colaborador, sus campos, constructor y los
adaptadores de diálogo. Este fascículo prioriza separar responsabilidad
y permitir pruebas directas; no se presenta como reducción global.

Durante el trabajo hubo cambios concurrentes de traducción, también en
`TfrmMtoGen` y en la nueva unidad. Por eso el contador global de la
aplicación no es atribuible a D2.1: pasa de 308.880 líneas al cerrar 6U
a 309.121 en el árbol final. El balance aislado es el de la tabla.

## Implementación

La nueva clase `TGestorFiltrosMto` concentra:

- captura de la búsqueda global y del filtro DevExpress activo;
- serialización y restauración Base64;
- reconocimiento de una búsqueda global dentro del árbol de criterios;
- construcción del menú de filtros propios y compartidos;
- carga de filtros mediante `IFiltrosGuardados`;
- guardado nuevo o sobrescritura;
- restauración defensiva antes, durante y después de los modales;
- aplicación del filtro devuelto por la gestión y compartición.

La unidad vive en `src/Lib` y no depende de formularios. Dos callbacks
tipados solicitan los datos del filtro y abren su gestión. De este modo
`TfrmMtoGen` conserva como fachada:

- un campo `FGestorFiltros`;
- creación y liberación con el ciclo de vida del formulario;
- el evento del botón, reducido a una delegación;
- dos adaptadores pequeños para los modales existentes.

También desaparecen de `TfrmMtoGen` el estado Base64/búsqueda, ocho
métodos privados, `System.NetEncoding` y el acceso directo a
`IFiltrosGuardados`.

## Pruebas automáticas

Se añade `PruebasGestorFiltrosMto.pas` con cinco pruebas DUnitX sin BBDD:

1. extracción de un mismo texto de búsqueda en varias columnas;
2. rechazo de un filtro que contiene textos `LIKE` distintos;
3. serialización Base64 y restauración del filtro y del editor;
4. captura y restauración de la búsqueda global;
5. composición de las acciones del menú sin servicio configurado.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 83/83 | 0 | 0 |
| Debug / Win32 | 0 errores | 83/83 | 0 | 0 |
| Release / Win64 | 0 errores | 83/83 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de añadir el módulo de
pruebas. La aplicación principal Release/Win64 se reconstruyó con
Delphi 37: 0 errores, 309.121 líneas y 10,03 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6V no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check` sin errores.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir un mantenimiento, aplicar una búsqueda global y desplegar el
   menú; el texto y el filtro deben permanecer visibles.
2. Guardar la búsqueda con nombre, limpiar la lista y volver a aplicarla.
3. Repetir con un filtro manual de varias columnas, sin búsqueda global.
4. Sobrescribir un filtro propio existente y confirmar el aviso.
5. Abrir la gestión, renombrar, compartir, aplicar y borrar filtros.
6. Aplicar un filtro compartido y verificar que el menú muestra su
   propietario.
7. Cancelar ambos modales y cerrar la pestaña; no deben quedar filtros
   parciales, callbacks pendientes ni errores de acceso.

D2 queda en **1 de 6 colaboradores**. El siguiente fascículo es D2.2:
perfiles de pantalla.
