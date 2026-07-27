# Fase 6F — columnas host de documentos de compra (resultados)

Fecha: 27/07/2026. Sexto fascículo de D1 terminado. Sin commit.

## Selección del alcance

Se compararon los cuatro `CrearColumnasHost*`. Albaranes, devoluciones y
facturas compartían estructura, captions, anchos, editabilidad y patrón de
campos. La factura solo aplicaba un formato monetario adicional al precio.

Pedidos conserva diferencias de negocio que no deben convertirse en
parámetros genéricos:

- cantidades pedida, recibida y a recibir;
- editabilidad especial de la cantidad en tallas inline;
- evento de cambio y vínculos de tipo de cantidad;
- precio con IVA `PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN`;
- anchos propios de línea, descripción, total y almacén.

## Implementación

`CrearColumnaHostDocumento` crea una columna a partir de vista, caption,
campo, ancho y editabilidad. Sustituye las cuatro funciones locales `Col`.

`CrearColumnasHostDocumentoCompra` centraliza el núcleo de albaranes,
devoluciones y facturas:

1. línea, modelo del proveedor y descripción;
2. cantidad y tipo de cantidad fuera del pivote por bandas;
3. precio de compra sin IVA y porcentaje de IVA;
4. total monetario o total de unidades según el modo;
5. almacén;
6. colocación de `LINEA` delante de las columnas creadas por el modo.

El resultado `TColumnasHostDocumentoCompra` devuelve las referencias que
los formularios todavía necesitan. Cada formulario conserva la llamada a
`VincularCantidadGrid`; facturas conserva el formato `#,##0.00 €`.

Pedidos usa la factoría elemental, pero mantiene toda su composición y sus
eventos en `TfrmMtoPedidosCompra`.

Los tres métodos completamente compartidos pasan de 122 a 38 líneas:
reducción de 84 líneas dentro de los formularios.

## Pruebas automáticas

Se añaden tres casos a `TPruebasColumnasDocumento`:

1. propiedades y comportamiento con vista nula de la factoría;
2. derivación por prefijo, editabilidad y orden de columnas;
3. omisión de cantidad y caption `Total uds.` en el pivote por bandas.

La batería DUnitX pasa de 32 a 35 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 35/35 | 0 | 0 |
| Debug / Win32 | 0 errores | 35/35 | 0 | 0 |
| Release / Win64 | 0 errores | 35/35 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.804
líneas en 10,83 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6F no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- funciones locales `Col` anteriores: 0 referencias;
- núcleo anterior duplicado en los tres formularios: 0 referencias;
- fuentes nuevas y modificadas en UTF-8 con BOM y CRLF;
- unidad común y pruebas sin líneas de más de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En albaranes, devoluciones y facturas de compra:

1. abrir desglose y SKU y confirmar cantidad editable;
2. abrir tallas horizontales por bandas y confirmar que no aparece la
   columna de cantidad;
3. comprobar `Total` en modos normales y `Total uds.` en bandas;
4. verificar que `Línea` queda delante del bloque artículo/SKU/tallas;
5. editar modelo del proveedor, precio, IVA y almacén;
6. comprobar totales y persistencia tras cambiar de modo.

En facturas debe verificarse además el formato `#,##0.00 €` del precio.

En pedidos:

1. comprobar columnas y anchos en desglose, SKU, inline y bandas;
2. verificar que «Pedida» queda bloqueada en inline;
3. editar «A recibir» y comprobar su límite y recálculo;
4. confirmar que el precio sigue ligado al campo con IVA;
5. comprobar que «Recibida» conserva su tipo de cantidad.

El siguiente candidato 6G es derivar la configuración común de
`TGridPivoteVentaConfig` usada por el modo de bandas. La elección del modo,
la reentrada, las transacciones y la degradación a SKU deben seguir en cada
formulario.
