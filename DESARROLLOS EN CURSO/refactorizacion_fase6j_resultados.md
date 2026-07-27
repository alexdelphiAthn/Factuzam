# Fase 6J — validación común de tallas en compras (resultados)

Fecha: 27/07/2026. Décimo fascículo de D1 terminado. Sin commit.

## Balance de código

Esta fase se ha medido separando producción, pruebas y documentación:

| Concepto | Antes | Después | Balance |
|---|---:|---:|---:|
| Cuatro métodos de formulario | 444 | 68 | -376 |
| Nueva unidad productiva | 0 | 216 | +216 |
| Total productivo del alcance | 444 | 284 | **-160** |
| Pruebas nuevas | 0 | 113 | +113 |
| Producción más pruebas | 444 | 397 | **-47** |

El código productivo del alcance baja un 36 %. Incluso contando las
pruebas, la fase elimina 47 líneas. Cada adaptador conserva de forma
explícita el documento, los datasets, la conexión y los callbacks.

El contador de compilación principal pasa de 307.842 a 307.844 líneas.
Este contador no mide el tamaño del cambio: depende de las unidades que
Delphi decide compilar y aquí solo aumenta dos líneas pese a añadirse una
unidad completa.

## Implementación

La nueva unidad `inLibValidacionTallasCompra` centraliza:

- construcción de nombres de campos a partir de los prefijos de cabecera
  y línea;
- detección de artículo o SKU en la línea activa;
- detección del sistema de tallas asignado;
- validación del estado de cabecera y línea;
- persistencia de la cabecera mediante un callback del formulario;
- consulta de líneas guardadas sin sistema de tallas;
- composición de incidencias;
- llamada final al validador del pivote mediante otro callback.

Los cuatro formularios conservan adaptadores de 17 líneas. No se ha
alterado el orden de las operaciones: primero se valida o publica la línea
activa, después se asegura la numeración de la cabecera, se consultan las
líneas persistidas y finalmente se delega en `ValidarPivotePosible`.

## Pruebas automáticas

Se añade `PruebasValidacionTallasCompra` con tres casos sin BBDD:

1. generación de campos de cabecera y línea;
2. detección de artículo, SKU y sistema de tallas en un dataset;
3. SQL parametrizado con la tabla y los campos configurados.

La batería DUnitX pasa de 41 a 44 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 44/44 | 0 | 0 |
| Debug / Win32 | 0 errores | 44/44 | 0 | 0 |
| Release / Win64 | 0 errores | 44/44 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.844
líneas en 10,78 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6J no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- fuentes nuevas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En pedidos, albaranes, devoluciones y facturas de compra:

1. intentar activar tallas sin cabecera activa y comprobar el mensaje;
2. en alta, intentarlo sin artículo en la línea;
3. usar un artículo sin sistema de tallas y comprobar el rechazo;
4. usar un artículo con sistema y verificar que la línea se publica;
5. hacerlo con cabecera aún sin número y comprobar su persistencia;
6. dejar una línea guardada sin sistema y revisar la lista de incidencias;
7. corregirla y comprobar que se alcanza la validación final del pivote.

El siguiente fascículo previsto es 6K:
`AsegurarCabeceraPersistidaParaLineas`.
