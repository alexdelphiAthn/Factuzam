# Fase 6A — columnas visuales de documentos (resultados)

Fecha: 27/07/2026. Primer fascículo de D1 terminado. Sin commit.

## Alcance real encontrado

El plan proponía empezar por `CrearColumnasTallas` y
`CrearColumnasAtributos`. La revisión del código actual encontró ambas
implementaciones duplicadas en cuatro formularios:

- `inMtoPedidosCompra`;
- `inMtoAlbaranesCompra`;
- `inMtoDevolucionesCompra`;
- `inMtoFacturasCompra`.

Los formularios de venta no contienen actualmente este par de métodos, por lo
que no se han modificado en este fascículo.

## Implementación

La nueva unidad `inLibColumnasDocumento` concentra la creación y configuración
de las columnas DevExpress:

- nombres correlativos con dos dígitos;
- columnas de talla no-bound, ocultas, con `Tag` positivo;
- editor numérico `TcxCurrencyEditProperties` y formato `#,##0`;
- columnas de atributo ocultas, no editables y con `Tag` negativo;
- callback opcional `OnGetDataText`.

Cada formulario conserva sus métodos privados como fachada de dos líneas y
aporta únicamente su vista, prefijo y array de columnas. También se conservan
las dos particularidades existentes:

- `inMtoPedidosCompra` sigue usando `ANCHO_TALLA_PX`;
- sus atributos siguen recibiendo `AtribGetDataText`.

No se crea todavía un nuevo ancestro visual `TfrmMtoDocumentoBase`. Para este
primer par de métodos, un colaborador sin estado evita acoplar el ancestro a
controles concretos de cada DFM. Los siguientes fascículos podrán apoyarse en
esta unidad cuando exista suficiente estado realmente común para justificar el
ancestro.

En los cuatro formularios se han retirado 130 líneas duplicadas y se han
dejado 20 líneas de delegación. La lógica común vive una sola vez.

## Pruebas automáticas

Se añadió `TPruebasColumnasDocumento` con cuatro casos:

1. creación y formato de columnas de talla;
2. creación de atributos ocultos y no editables;
3. conservación del callback de texto;
4. guarda ante una vista nula.

La batería DUnitX pasa de 16 a 20 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 20/20 | 0 | 0 |
| Debug / Win32 | 0 errores | 20/20 | 0 | 0 |
| Release / Win64 | 0 errores | 20/20 | 0 | 0 |

La aplicación principal Release/Win64 también compila con 0 errores:
307.730 líneas en 10,78 segundos.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes nuevas en UTF-8 con BOM y CRLF;
- fuentes nuevas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación visual

Estado actual: **pendiente de ejecución manual**.

En cada uno de los cuatro documentos afectados:

1. abrir un documento con líneas de varios artículos y tallas;
2. activar el modo de tallas y comprobar 20 columnas como máximo, anchos,
   cantidades y rótulos;
3. activar el desglose por atributos y comprobar hasta cinco columnas,
   ocultación correcta y ausencia de edición directa;
4. volver al modo anterior y confirmar que no quedan columnas duplicadas;
5. navegar entre documentos y repetir el cambio de modo.

En pedidos de compra debe verificarse además que las celdas de atributo siguen
mostrando el texto derivado del SKU, ya que es el único consumidor que conecta
`AtribGetDataText`.

El siguiente fascículo natural es 6B: extraer
`RefrescarVisibilidadTallas`, `RefrescarVisibilidadAtributos` y los captions
visuales que no consulten datos.
