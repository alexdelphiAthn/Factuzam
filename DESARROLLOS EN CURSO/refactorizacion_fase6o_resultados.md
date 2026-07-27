# Fase 6O — presentación común de documentos (resultados)

Fecha: 27/07/2026. Decimoquinto fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Diez métodos de presentación | 268 | 121 | -147 |
| Librería común de presentación | 0 | 82 | +82 |
| Núcleo productivo medido | 268 | 203 | **-65** |
| Integración en formularios y proyecto | 0 | 9 | +9 |
| Total productivo de 6O | 268 | 212 | **-56** |

El código productivo del alcance baja un 21 %. Las 104 líneas de la
prueba nueva y sus referencias de proyecto no se incluyen en las cifras.

El contador global del compilador sube respecto a 6N por los cambios
concurrentes de literales y traducción. No se usa para medir 6O porque
mezcla trabajo ajeno; la tabla anterior compara exclusivamente el alcance
productivo medido antes y después de esta fase.

## Implementación

La nueva unidad `inLibPresentacionDocumento` centraliza dos reglas:

- `TextoProveedorDocumento` resuelve el código, nombre comercial y razón
  social mediante el dataset de proveedores;
- `TextoTotalPrendasDocumento` valida la cabecera y aplica el formato
  numérico común al total obtenido mediante callback.

La etiqueta de proveedor se reutiliza en:

- sesiones de compra;
- pedidos de compra;
- albaranes de compra;
- facturas de compra;
- devoluciones de compra.

El total de prendas se reutiliza en:

- pedidos y albaranes de venta;
- facturas de venta, conservando su guarda contra reentrada;
- facturas y devoluciones de compra.

Se mantienen los resultados existentes: etiqueta vacía sin proveedor,
razón social como sustituta del nombre comercial, razón entre paréntesis
cuando difiere y aviso textual cuando el código no aparece en el lookup.

Inventarios no se ha incluido porque no tiene proveedor ni un total de
prendas equivalente; no se ha forzado una abstracción artificial.

## Pruebas automáticas

Se añaden dos pruebas sin BBDD:

1. composición de código, nombre comercial y razón social, incluido un
   proveedor inexistente;
2. total cero sin cabecera y total formateado con cabecera activa.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 50/50 | 0 | 0 |
| Debug / Win32 | 0 errores | 50/50 | 0 | 0 |
| Release / Win64 | 0 errores | 50/50 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.987
líneas en 29,92 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6O no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- unidad común y prueba nueva en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir sesiones y los cuatro documentos de compra y recorrer
   proveedores con nombre comercial vacío, igual y distinto de la razón
   social.
2. Escribir un código de proveedor inexistente y comprobar el texto.
3. Navegar entre documentos sin líneas y con varias prendas.
4. Verificar el total en pedidos y albaranes de venta.
5. Verificar el total en facturas y devoluciones de compra.
6. Navegar rápidamente por facturas de venta y confirmar que la guarda
   contra reentrada sigue evitando refrescos recursivos.

