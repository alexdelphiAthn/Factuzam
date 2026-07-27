# Fase 6I — búsquedas comunes de compras (resultados)

Fecha: 27/07/2026. Noveno fascículo de D1 terminado. Sin commit.

## Balance de código

Esta fase se ha medido separando producción, pruebas y documentación:

| Concepto | Antes | Después | Balance |
|---|---:|---:|---:|
| Doce métodos de formulario | 478 | 188 | -290 |
| Nueva unidad productiva | 0 | 159 | +159 |
| Total productivo del alcance | 478 | 347 | **-131** |
| Pruebas nuevas | 0 | 95 | +95 |
| Producción más pruebas | 478 | 442 | **-36** |

El código productivo del alcance baja un 27 %. Incluso contando las pruebas,
la fase elimina 36 líneas. El informe y las referencias de proyecto hacen
crecer el repositorio, pero no el código ejecutable.

El contador de compilación principal pasa de 307.977 a 307.842 líneas. En
esta fase coincide con el balance, aunque no se usa como métrica general
porque depende de las unidades recompiladas.

## Implementación

La nueva unidad `inLibBusquedasCompra` centraliza:

- SQL de artículos activos asociados a un proveedor;
- SQL de SKUs activos y agregación ordenada de atributos;
- creación, parametrización y liberación de `TUniQuery`;
- ejecución del formulario genérico de búsqueda;
- lectura segura de un campo de texto desde un dataset activo.

Los formularios conservan de forma explícita:

- campo de proveedor de cada cabecera;
- dataset y campo de artículo de cada línea;
- mensajes por documento cerrado o artículo/proveedor vacío;
- conexión usada por cada documento;
- caption e identificador del formulario de búsqueda.

No se han cambiado las consultas de stock, paletas o atributos básicos que
también mencionan las tablas SKU: pertenecen a otros flujos.

## Pruebas automáticas

Se añade `PruebasBusquedasCompra` con tres casos:

1. parámetro de proveedor, filtro de activos y columnas del artículo;
2. parámetro de artículo, filtro de SKUs activos y agregación de atributos;
3. dataset nulo, cerrado, vacío, campo inexistente y valor con espacios.

La batería DUnitX pasa de 38 a 41 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 41/41 | 0 | 0 |
| Debug / Win32 | 0 errores | 41/41 | 0 | 0 |
| Release / Win64 | 0 errores | 41/41 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.842
líneas en 26,80 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6I no modifica
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

1. buscar artículo sin proveedor y comprobar el mensaje;
2. buscar artículo con proveedor y seleccionar un resultado;
3. comprobar que solo aparecen artículos activos del proveedor;
4. buscar SKU sin artículo y comprobar el mensaje;
5. buscar SKU con artículo y revisar la descripción de atributos;
6. seleccionar el SKU y verificar su aplicación a la línea;
7. cancelar ambos diálogos sin modificar la línea.

Debe comprobarse también que cada diálogo conserva su identificador y que
devoluciones sigue usando `ConexionPrincipal`.

Antes de abrir 6J se repetirá esta medición. El candidato con retorno es la
carga de atributos básicos de color repetida en albaranes, facturas y
pedidos; solo se extraerá si mantiene una reducción productiva clara.
