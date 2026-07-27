# Fase 6B — visibilidad y captions de documentos (resultados)

Fecha: 27/07/2026. Segundo fascículo de D1 terminado. Sin commit.

## Resultado

`inLibColumnasDocumento` incorpora dos operaciones comunes:

- `EstablecerVisibilidadColumnasDocumento`, que muestra u oculta únicamente
  las columnas asignadas;
- `CaptionModoLineasDocumento`, que resuelve el rótulo de la pestaña según el
  modo de entrada.

Los cuatro formularios de compra delegan ahora:

- la ocultación de tallas cuando el pivote o el gestor no están activos;
- la visibilidad conjunta de las columnas de atributos;
- los captions de modo SKU, desglose y tallas horizontales.

Se han conservado de forma explícita todas las diferencias existentes:

- albaranes y devoluciones mantienen el prefijo acelerador `&1_`;
- albaranes, devoluciones y facturas mantienen el espacio final del caption
  antes de construir el modo;
- pedidos distingue `Tallas horiz.` de `Tallas horiz. bandas`;
- pedidos sigue ocultando o mostrando su columna SKU y recolocando los
  atributos junto a ella;
- la carga de nombres de atributos continúa en cada formulario porque
  consulta el artículo activo y la BBDD.

La condición sobre `FPivote` y las llamadas a `FGestorTallas` también
permanecen en los formularios. La librería común solo conoce columnas y modos
visuales, no el ciclo de vida de esos dos colaboradores.

Respecto al cierre de 6A, se han retirado otras 105 líneas de los cuatro
formularios y se han dejado 39 líneas de delegación y configuración: 66 líneas
netas menos en las clases.

## Pruebas automáticas

`TPruebasColumnasDocumento` añade tres casos:

1. visibilidad con referencias de columna parcialmente asignadas;
2. captions comunes, incluido el espaciado anterior;
3. diferencia entre el pivote horizontal y el pivote por bandas de pedidos.

La batería DUnitX pasa de 20 a 23 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 23/23 | 0 | 0 |
| Debug / Win32 | 0 errores | 23/23 | 0 | 0 |
| Release / Win64 | 0 errores | 23/23 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.756 líneas
en 11,08 segundos.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación visual

Estado actual: **pendiente de ejecución manual**.

En pedidos, albaranes, devoluciones y facturas de compra:

1. abrir el formulario y comprobar el caption inicial exacto;
2. recorrer SKU, desglose y tallas horizontales y verificar el rótulo;
3. desactivar el pivote y confirmar que no queda ninguna talla visible;
4. mostrar y ocultar atributos varias veces;
5. confirmar que los nombres de atributos se siguen cargando para el artículo
   activo.

En pedidos de compra debe comprobarse además:

1. que la columna SKU se oculta en desglose y reaparece en modo SKU;
2. que los atributos quedan inmediatamente después de su hueco;
3. que los modos horizontal y por bandas muestran captions distintos.

La carga de captions desde datos no forma parte de 6B. Es candidata para un
fascículo posterior con fixtures que separen la consulta de la aplicación
visual.
