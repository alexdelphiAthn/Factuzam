# Fase 6M — columnas comunes en ventas e inventarios (resultados)

Fecha: 27/07/2026. Decimotercer fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Cuatro construcciones del modo SKU | 538 | 483 | -55 |
| Cuatro cargas de atributos globales | 197 | 69 | -128 |
| Total productivo del alcance | 735 | 552 | **-183** |

El código productivo del alcance baja un 25 %. No se han creado unidades
nuevas ni duplicado helpers: se reutiliza `inLibColumnasDocumento`.

El contador actual de la compilación principal es 307.787 líneas. No se
compara con el de 6L porque durante la fase hubo cambios concurrentes en
`inLibMsg` ajenos a 6M.

## Implementación

Pedidos, albaranes y facturas de venta, además de inventarios, usan ahora:

- `CrearConfigColumnasSkuDocumento` para conexión, contexto, vista,
  dataset, modo, almacén y campos convencionales;
- `MostrarColumnasAtributoGlobalesDocumento` para consultar, ordenar y
  aplicar los cinco nombres globales de atributo.

Se conservan de forma explícita las diferencias reales:

- pedidos y albaranes mantienen su cálculo de precio por SKU;
- facturas mantiene líneas fuera de catálogo, almacén de línea vacío y
  configuración propia del pivote de venta;
- inventarios mantiene `CANTIDAD_FISICA_INVLIN`, almacén solo en cabecera,
  `NUM_ATRIBUTOS_REQ_INV_LINEA` y campos de atributo sin sufijo;
- inventarios conserva además el cálculo de anchura según los valores
  cargados y el margen del indicador de color.

No se han centralizado los métodos completos `ConstruirModoEntrada`.
Desmontaje, pivotes, columnas host, captions y reglas de edición siguen en
cada formulario porque no son equivalentes.

## Pruebas automáticas

Los contratos reutilizados ya estaban cubiertos por
`PruebasColumnasDocumento`:

1. configuración convencional de campos SKU;
2. aplicación de nombres por `Tag`;
3. tratamiento seguro de conexión o vista nulas.

La batería DUnitX se mantiene en 47 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 47/47 | 0 | 0 |
| Debug / Win32 | 0 errores | 47/47 | 0 | 0 |
| Release / Win64 | 0 errores | 47/47 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.787
líneas en 10,94 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6M no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas de 6M dentro del máximo de 80 columnas;
- `git diff --check` de los archivos de la fase sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. En pedidos, recorrer con F1 desglose, SKU y tallas horizontales.
2. En albaranes, recorrer desglose, SKU y tallas inline.
3. En facturas normales, comprobar líneas libres y artículos de catálogo.
4. En facturas simplificadas, comprobar que la vista heredada se mantiene.
5. En inventarios, alternar desglose y SKU y guardar una cantidad física.
6. Verificar captions Color/Talla al entrar en cada modo.
7. En inventarios, comprobar anchuras, almacén de cabecera y atributos.
8. Confirmar que los precios y columnas host de cada documento no cambian.

El siguiente fascículo previsto es 6N: generalizar la persistencia de
cabecera para pedidos y albaranes de venta sin perder la recreación de la
línea vacía ni la validación de cliente.
