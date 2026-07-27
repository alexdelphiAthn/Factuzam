# Fase 6E — desmontaje y configuración base del modo (resultados)

Fecha: 27/07/2026. Quinto fascículo de D1 terminado. Sin commit.

## Selección del alcance

Se compararon los cuatro `ConstruirModoEntrada`. El desmontaje del grid y
la construcción inicial de `TConfigColumnasSku` eran iguales salvo por la
vista, el dataset, el almacén y el prefijo de línea.

Se mantienen expresamente dentro de cada formulario:

- las transacciones de reorganización de líneas;
- la guarda de reentrada y la clave de cabecera de pedidos;
- el desempaquetado de atributos;
- la degradación controlada a SKU;
- la elección entre gestor genérico, tallas inline y pivote por bandas;
- las referencias adicionales de pedidos.

## Implementación

`PrepararReconstruccionModoDocumento` conserva el orden del teardown:

1. cierra el editor activo, tolerando `EInvalidOperation`;
2. cancela el dataset si continúa en edición;
3. desmonta el modo anterior;
4. retira los eventos instalados sobre la vista;
5. elimina las columnas;
6. anula el modo y todas las referencias comunes a columnas.

`CrearConfigColumnasSkuDocumento` parte de un registro a cero y configura
conexión, sesión, vista, dataset, modo y almacén. Los campos de artículo,
SKU, descripción, cantidad, almacén, número de atributos y los cinco pares
`ATTRn_VALOR`/`ATTRn_NOMBRE` se derivan de un único prefijo de línea.

Pedidos conserva localmente la limpieza de `FColColorProveedorPivot` y
`colLineaPedcARecibir`, porque no existen en los otros documentos.

Los cuatro formularios reutilizan además `CaptionModoLineasDocumento` con
el modo efectivo detectado después del montaje. Así se conserva la
rotulación correcta cuando el modo automático degrada a SKU.

## Pruebas automáticas

Se añaden dos casos a `TPruebasColumnasDocumento`:

1. teardown de una vista con columnas y un `TClientDataSet` en inserción;
2. derivación completa de `TConfigColumnasSku` para el prefijo `ALBCLIN`.

La batería DUnitX pasa de 30 a 32 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 32/32 | 0 | 0 |
| Debug / Win32 | 0 errores | 32/32 | 0 | 0 |
| Release / Win64 | 0 errores | 32/32 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.819
líneas en 28,14 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6E no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- bloques anteriores de teardown/configuración base: 0 referencias;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En pedidos, albaranes, devoluciones y facturas de compra:

1. entrar sucesivamente en desglose, SKU y tallas horizontales;
2. cambiar de modo mientras una celda está en edición;
3. confirmar que no quedan editores, columnas ni eventos del modo anterior;
4. comprobar captions, cantidades, precios y totales tras cada cambio;
5. navegar entre cabeceras y repetir la secuencia;
6. cerrar y reabrir el formulario.

En pedidos debe comprobarse también el modo inline, el pivote por bandas,
las columnas «Recibida» y «A recibir» y la reconstrucción al cambiar de
cabecera.

En una BBDD anterior sin columnas `ATTRn`, el modo automático debe degradar
una sola vez a SKU y mostrar el caption efectivo `[SKU]`.

El siguiente candidato 6F es extraer la factoría común de columnas host y
el núcleo compartido por albaranes, devoluciones y facturas. Las columnas
de recepción de pedidos y las diferencias de precio deben seguir locales.
