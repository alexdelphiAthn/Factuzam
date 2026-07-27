# Fase 6C — carga común de captions de atributos (resultados)

Fecha: 27/07/2026. Tercer fascículo de D1 terminado. Sin commit.

## Resultado

Se ha eliminado la implementación duplicada de
`CargarCaptionsAtributosLineaActiva` en:

- pedidos de compra;
- albaranes de compra;
- devoluciones de compra;
- facturas de compra.

`inLibColumnasDocumento` centraliza ahora tres responsabilidades separadas:

1. restablecer los placeholders `Atributo 1` a `Atributo N`;
2. leer los nombres mediante la `TUniQuery` configurada por el data module;
3. aplicar los nombres obtenidos a las columnas disponibles.

Cada formulario conserva únicamente la elección de:

- data module;
- query de definición del artículo;
- dataset de líneas;
- campo de código de artículo.

La consulta común mantiene los nombres `ARTICULO` y `NOMBRE_ATRIBUTO` usados
por las cuatro queries existentes, limita el resultado al número de columnas
y consume cada fila en el mismo orden anterior.

También se conserva el comportamiento de las guardas:

- sin data module no se realiza ninguna operación;
- con query nula se conservan los captions anteriores;
- con query válida pero sin líneas se muestran los placeholders;
- sin artículo no se abre la query.

El cierre de la query está ahora protegido por `try/finally`, de modo que una
excepción durante su apertura o lectura no la deja activa.

Respecto al cierre de 6B, los formularios pierden 132 líneas y reciben 20
líneas de delegación: reducción neta de 112 líneas en las cuatro clases. La
lógica compartida vive una sola vez.

## Pruebas automáticas

Se han añadido tres casos a `TPruebasColumnasDocumento`:

1. restablecimiento y aplicación parcial de nombres;
2. conservación del caption cuando la query es nula;
3. placeholders y query cerrada cuando no existe dataset de líneas.

La batería DUnitX pasa de 23 a 26 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 26/26 | 0 | 0 |
| Debug / Win32 | 0 errores | 26/26 | 0 | 0 |
| Release / Win64 | 0 errores | 26/26 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.730 líneas
en 10,95 segundos.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En cada uno de los cuatro documentos:

1. abrir una línea con un artículo sin atributos y comprobar los placeholders;
2. navegar a artículos con uno, dos y cinco atributos;
3. comprobar nombre, orden y placeholders de las columnas sobrantes;
4. cambiar varias veces entre SKU y desglose;
5. navegar entre documentos y confirmar que no se conserva el caption del
   artículo anterior;
6. cerrar el formulario tras provocar varias recargas y comprobar que no queda
   una query activa.

El siguiente candidato de D1 debe medirse entre
`InicializarGestorYPivote` y la configuración del modo de entrada. Ambos
mezclan más colaboradores que los fascículos visuales ya completados.
