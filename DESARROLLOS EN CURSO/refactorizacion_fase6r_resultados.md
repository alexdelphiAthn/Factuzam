# Fase 6R — ciclo de vida y navegación de documentos (resultados)

Fecha: 27/07/2026. Decimoctavo fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Doce `FormCreate` y `FormDestroy` | 647 | 496 | -151 |
| Hooks de navegación migrados | 263 | 177 | -86 |
| Fachada `inLibColumnasDocumento` | 686 | 841 | +155 |
| Total productivo de 6R | 1.596 | 1.514 | **-82** |

El código productivo del alcance baja un 5 %. Las pruebas añadidas no se
incluyen en estas cifras. El contador global del compilador tampoco se
compara con 6Q porque el árbol contiene cambios concurrentes.

## Implementación

`inLibColumnasDocumento` incorpora colaboradores de ciclo de vida para:

- configurar columnas de búsqueda con botón y validación;
- crear la configuración visual base de la columna Color del pivote;
- desmontar el modo y liberar gestor y pivote sin bloquear el cierre;
- decidir si una navegación debe construir, reconstruir tallas o
  desempaquetar atributos;
- actualizar captions y atributos al cambiar la línea enfocada;
- preparar la entrada al grid, asegurar su primera línea, reconstruir
  cuando proceda y mostrar el editor del modo resultante.

Los `FormCreate` de pedidos y albaranes de venta y de los cuatro
documentos de compra reutilizan la configuración de columnas. Los cuatro
documentos de compra comparten la creación base de Color.

Albaranes, facturas y devoluciones de compra comparten el cierre
defensivo. Pedidos de compra conserva su cierre especial: agrupa la
reorganización de líneas, aborta el recálculo repetitivo y sincroniza el
pendiente de recibir una sola vez.

La política común de navegación se usa en albaranes de venta y en
albaranes, facturas y devoluciones de compra. Los cuatro documentos de
compra comparten además los hooks de foco y entrada al grid.

Se mantienen locales las diferencias con efectos de negocio:

- refrescos de empresa, almacenes, proveedor y total de prendas;
- cálculos fiscales y sincronización de movimientos en `AfterPost`;
- navegación por clave y fusión diferida de pedidos de compra;
- desmontaje reforzado de pedidos de venta;
- presentación clásica y hooks del data module en facturas de venta;
- desacoplamiento de datasources y lookups al destruir inventarios.

## Pruebas automáticas

Se añaden cinco pruebas sin BBDD:

1. configuración del botón y la validación de una columna de búsqueda;
2. creación base de la columna Color;
3. decisión entre construir, desempaquetar, reconstruir tallas o no
   actuar mientras la cabecera está en edición;
4. entrada al grid con primera línea, reconstrucción y apertura del
   editor;
5. cierre que tolera una excepción durante el desmontaje.

La batería actual incluye además pruebas concurrentes ajenas a 6R:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 63/63 | 0 | 0 |
| Debug / Win32 | 0 errores | 63/63 | 0 | 0 |
| Release / Win64 | 0 errores | 63/63 | 0 | 0 |

La aplicación principal Release/Win64 compila con Delphi 37 con 0
errores: 309.045 líneas en 10,69 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6R no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `git diff --check` sin errores en los archivos de la fase;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir y cerrar repetidamente los ocho documentos, también con el modo
   de tallas activo.
2. Navegar entre cabeceras y verificar almacenes, proveedor y total de
   prendas.
3. Editar una cabecera y confirmar que el hook no reconstruye las líneas
   hasta volver a navegación.
4. Entrar por primera vez en los grids de compra y comprobar la línea
   inicial, el editor abierto y la restauración de Enter-como-Tab al
   salir.
5. En pedidos de compra, entrar con líneas SKU pendientes de fusionar y
   confirmar que la fusión solo ocurre al entrar en el grid.
6. Cerrar pedidos de compra con cambios en tallas y verificar una única
   sincronización del pendiente de recibir.
7. Probar los botones de artículo, SKU y Color de todos los formularios
   migrados.
