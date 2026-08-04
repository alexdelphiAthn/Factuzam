# Fase 6S — modo de entrada y contexto de foto

Fecha: 27/07/2026. D1.3 y decimonoveno fascículo de D1 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Ocho `KeyDown` de documentos | 155 | 68 | -87 |
| Cuatro preferencias del pivote | 54 | 20 | -34 |
| Dos saltos directos de modo | 20 | 14 | -6 |
| Ocho resoluciones de artículo/SKU | 109 | 53 | -56 |
| Ocho selectores de fuentes y comentarios | 78 | 40 | -38 |
| Imports directos de `inLibFotos` | 6 | 0 | -6 |
| Fachada `inLibColumnasDocumento` | 841 | 950 | +109 |
| Total productivo de 6S | 1.263 | 1.145 | **-118** |

El alcance productivo baja un 9 %. El contador de la aplicación confirma
la misma reducción: pasa de 309.045 líneas al cerrar 6R a 308.927 líneas
en 6S. Las pruebas añadidas no se incluyen en estas cifras.

## Implementación

`inLibColumnasDocumento` incorpora cinco colaboradores:

- `ProcesarTeclaCambioModoDocumento` reconoce F1 sin modificadores,
  comprueba si el contexto permite el cambio, consume la tecla, avanza por
  el ciclo configurado y solicita la reconstrucción;
- `CambiarModoEntradaDocumento` concentra los saltos directos y evita
  reconstruir cuando el modo solicitado ya está activo;
- `PersistirPreferenciaPivoteDocumento` guarda `S/N` en la cabecera solo
  cuando el dataset y el campo están disponibles, y deja el registro
  posteado;
- `ResolverArtSkuActivoDocumento` obtiene el artículo y el SKU desde el
  dataset conectado a la vista de líneas;
- `DataSourcesParaFotoDocumento` devuelve la cabecera y, cuando existe,
  el `DataSource` real de esa misma vista.

Los ocho documentos comparten el procesamiento de teclado, manteniendo
sus ciclos:

- inventarios: Auto y SKU;
- albaranes de venta: Auto, SKU y tallas en línea;
- pedidos de compra: Auto, SKU, tallas en línea y tallas horizontales;
- pedidos y facturas de venta, albaranes, facturas y devoluciones de
  compra: Auto, SKU y tallas horizontales.

Se conservan las guardas particulares de pestaña, data module y modo
clásico de facturas. Los botones de expansión de pedidos de venta y de
compra reutilizan el salto directo. Los cuatro documentos de compra
delegan la persistencia de `ESPIVOTE_HORIZONTAL_*` sin cambiar el flujo
del pivote antiguo, actualmente retirado de la interfaz.

Pedidos, albaranes y facturas de venta, inventarios y los cuatro
documentos de compra comparten también la resolución del artículo/SKU y
la selección de fuentes para la foto flotante. Ambas operaciones parten
de la misma vista, por lo que el registro resuelto y el hook de refresco
no pueden apuntar a detalles distintos. Devoluciones de compra conserva
su fallback por `CODIGO_ART_DEVCLIN` y `CODIGO_UNIDAD_DEVCLIN`.

## Pruebas automáticas

Se añaden siete pruebas DUnitX sin BBDD:

1. ciclo completo de cuatro modos y una reconstrucción por pulsación;
2. rechazo de F1 fuera de contexto, con modificadores o de otra tecla;
3. salto directo sin reconstrucción redundante;
4. persistencia de los valores `S` y `N`;
5. tolerancia a dataset nulo, inactivo o sin el campo de preferencia;
6. resolución de artículo/SKU desde el dataset de la vista;
7. selección de cabecera y detalle para el refresco de foto.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 70/70 | 0 | 0 |
| Debug / Win32 | 0 errores | 70/70 | 0 | 0 |
| Release / Win64 | 0 errores | 70/70 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de modificar el módulo de
pruebas. La aplicación principal Release/Win64 compila con Delphi 37 con
0 errores: 308.927 líneas en 10,80 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6S no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `git diff --check` sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir los ocho documentos y pulsar F1 dentro y fuera de la pestaña de
   líneas; fuera de ella no debe cambiar el modo.
2. Repetir con Ctrl+F1, Alt+F1 y Mayús+F1; ningún modificador debe activar
   el ciclo.
3. Recorrer el ciclo completo de cada familia y comprobar captions,
   columnas, foco y editor tras cada reconstrucción.
4. En inventarios, comprobar que F1 solo alterna Auto y SKU.
5. En pedidos de compra, comprobar los cuatro pasos, incluido tallas en
   línea antes de tallas horizontales.
6. En facturas de venta con creación de artículos activa, comprobar que
   F1 sigue inerte.
7. Pulsar `Expandir filas` y `Expandir recibidos`; deben saltar a tallas
   horizontales y no reconstruir de nuevo si ya estaban en ese modo.
8. Abrir la foto flotante en los ocho documentos y navegar por líneas;
   debe seguir el artículo y el SKU enfocados en cada grid.
9. En devoluciones de compra, repetir con una línea cuya vista necesite
   el fallback y verificar que la foto sigue resolviéndose.
