# Fase 6H — nombres globales de atributos (resultados)

Fecha: 27/07/2026. Octavo fascículo de D1 terminado. Sin commit.

## Selección del alcance

Los cuatro `MostrarColumnasAtributoGlobales*` ejecutaban la misma consulta
y repetían el mismo recorrido del grid. Solo cambiaban la conexión y la
vista.

El contrato que se conserva es:

- leer como máximo cinco nombres globales;
- ordenar por orden y nombre;
- asociar el primer nombre al `Tag=1`, el segundo al `Tag=2`, etc.;
- actualizar todas las columnas que compartan ese `Tag`;
- no tocar las columnas propias con `Tag` negativo;
- hacer visibles únicamente las columnas para las que haya nombre.

## Implementación

`AplicarNombresAtributosGlobalesDocumento` contiene la lógica visual,
independiente de la BBDD. Recorre los nombres y actualiza todas las columnas
de la vista cuyo `Tag` positivo coincide con su orden.

`MostrarColumnasAtributoGlobalesDocumento` contiene la consulta única a
`fza_variaciones_atributos`, limita el resultado a cinco nombres y delega
su aplicación. Si falta la conexión o la vista, no modifica nada.

Los cuatro formularios se reducen a pasar su conexión y su vista. La
consulta SQL solo permanece en `inLibColumnasDocumento`.

Los cuatro métodos pasan de 158 a 28 líneas: reducción de 130 líneas en los
formularios.

## Pruebas automáticas

Se añaden dos casos a `TPruebasColumnasDocumento`:

1. aplicación a `Tag` positivos, incluidos Tags duplicados, sin alterar un
   `Tag` negativo;
2. conservación de la vista cuando no hay conexión y tolerancia de
   parámetros nulos.

La batería DUnitX pasa de 36 a 38 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 38/38 | 0 | 0 |
| Debug / Win32 | 0 errores | 38/38 | 0 | 0 |
| Release / Win64 | 0 errores | 38/38 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.977
líneas en 12,61 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6H no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- consulta global anterior en formularios: 0 referencias;
- bucle por `Tag` duplicado anterior: 0 referencias;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En pedidos, albaranes, devoluciones y facturas de compra:

1. abrir el modo desglose con Color y Talla configurados globalmente;
2. comprobar captions y visibilidad desde la primera línea;
3. verificar una BBDD con menos de cinco atributos globales;
4. cambiar entre desglose, SKU y tallas horizontales;
5. confirmar que las columnas propias con `Tag` negativo conservan caption
   y visibilidad;
6. cerrar y reabrir cada formulario.

Conviene repetir con dos columnas del contrato que compartan el mismo
`Tag`, para confirmar que ambas reciben el mismo caption.

El siguiente candidato 6I es centralizar las búsquedas de artículos por
proveedor y de SKUs por artículo. Los cuatro formularios repiten las mismas
consultas; deben permanecer locales los mensajes, identificadores de
diálogo y campos concretos del documento.
