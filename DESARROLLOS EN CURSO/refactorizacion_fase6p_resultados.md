# Fase 6P — navegación común entre mantenimientos (resultados)

Fecha: 27/07/2026. Decimosexto fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Veinte métodos de navegación | 289 | 202 | -87 |
| Fachada común `inLibShowMto` | 279 | 335 | +56 |
| Total productivo de 6P | 568 | 537 | **-31** |

El código productivo del alcance baja un 5 %. No se ha creado otra
unidad: las reglas se incorporan a la fachada que ya abre y localiza
mantenimientos. La prueba nueva y sus referencias de proyecto no se
incluyen en las cifras.

El contador global del compilador no se compara con 6O porque continúa
mezclando cambios concurrentes de literales y traducción. El balance
anterior procede de medir exclusivamente los métodos y la fachada antes
y después de 6P.

## Implementación

`inLibShowMto` incorpora:

- `CodigoMtoDataSet`, que valida el dataset y recorta el código;
- `ClaveMtoDataSet`, que compone una clave `serie,número` solo cuando
  ambos valores existen;
- `ShowMtoCodigoDataSet`, para abrir un mantenimiento por código;
- `ShowMtoDocumentoDataSet`, para abrir documentos relacionados y
  mostrar opcionalmente el aviso existente cuando falta la relación.

Los consumidores migrados incluyen:

- artículos de pedidos, albaranes, facturas y devoluciones de compra;
- artículos de sesiones de compra, facturas de venta e inventarios;
- proveedores de sesiones y los cuatro documentos de compra;
- albaranes creados desde pedidos de compra y venta;
- pedidos relacionados con albaranes de compra y venta;
- facturas creadas desde albaranes de compra;
- cliente y empresa de facturas de venta;
- movimientos de almacén de facturas de venta.

Se conserva que un código vacío abre el mantenimiento sin localizar, que
una relación documental incompleta muestra el aviso específico cuando el
formulario ya lo hacía y que las pestañas inactivas no navegan.

## Pruebas automáticas

Se añaden dos pruebas sin BBDD:

1. dataset nulo o vacío y recorte de un código válido;
2. composición de `serie,número` y rechazo de una clave incompleta.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 52/52 | 0 | 0 |
| Debug / Win32 | 0 errores | 52/52 | 0 | 0 |
| Release / Win64 | 0 errores | 52/52 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 308.811
líneas en 26,39 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6P no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fachada común y prueba nueva en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir artículos desde sesiones, inventarios y cada documento migrado.
2. Abrir proveedores con código válido y con cabecera sin proveedor.
3. Desde pedidos de compra y venta, abrir el albarán creado.
4. Desde albaranes de compra y venta, abrir el pedido relacionado.
5. Desde un albarán de compra, abrir la factura creada.
6. Confirmar los avisos cuando pedido o factura relacionados no existen.
7. En facturas de venta, abrir cliente, empresa y movimiento de almacén.

