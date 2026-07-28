# Fase 6Z — dominio de artículos de `TfrmMtoGen`

Fecha: 28/07/2026. D2.5 y quinto fascículo de D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 2.183 | 2.197 | **+14** |
| Nuevo `inLibGestorArticulosMto` | 0 | 163 | +163 |
| Total productivo del alcance | 2.183 | 2.360 | **+177** |

Esta extracción no reduce el formulario: añade 14 líneas por los
adaptadores que mantienen aislada la librería respecto a los formularios
de foto y stock. El crecimiento productivo completo es del 8,1 %. A
cambio, la coordinación puede probarse sin abrir formularios ni BBDD y
los descendientes conservan sus overrides sin depender del gestor.

Acumulado de D2: `TfrmMtoGen` ha bajado de 3.346 a 2.197 líneas,
**-1.149 (-34,3 %)**. Los cinco colaboradores suman 1.970 líneas y el
alcance productivo acumulado pasa de 3.346 a 4.167,
**+821 (+24,5 %)**.

Los contadores globales de compilación incluyen cambios concurrentes de
traducción y no permiten aislar D2.5. El balance atribuible al fascículo
es el de la tabla.

## Implementación

La nueva clase `TGestorArticulosMto` concentra:

- alternancia de la pantalla flotante de foto;
- resolución del artículo/SKU antes de mostrar la foto;
- selección de los `DataSource` que refrescan la foto;
- rechazo de la apertura cuando no hay artículo activo;
- consulta de stock con el artículo/SKU resuelto;
- desvinculación de la foto antes de destruir los `DataSource`;
- resolución predeterminada sobre el dataset principal;
- selección predeterminada del `DataSource` principal.

La unidad vive en `src/Lib` y no depende de formularios del proyecto.
Recibe callbacks tipados para las operaciones visuales. Los adaptadores
de `TfrmMtoGen` son el único punto que conoce `inMtoFotoArticulo` e
`inMtoStockConsulta`.

Se mantienen las fachadas virtuales `ResolverArtSkuActivo`,
`ResolverArtSkuStock` y `DataSourcesParaFoto`. Por ello siguen
despachando a los overrides de ventas, compras, inventarios, caja y los
mantenimientos con subgrids. El comportamiento predeterminado de la base
delega en el gestor.

## Pruebas automáticas

Se añade `PruebasGestorArticulosMto.pas` con siete pruebas DUnitX sin
BBDD:

1. resolución de los campos canónicos de artículo y SKU;
2. selección predeterminada del `DataSource` principal;
3. ocultación de una foto visible sin resolver de nuevo;
4. apertura y vinculación de una foto oculta;
5. rechazo de la foto cuando el artículo está vacío;
6. propagación del artículo/SKU a la consulta de stock;
7. desvinculación mediante una lista vacía de `DataSource`.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 104/104 | 0 | 0 |
| Debug / Win32 | 0 errores | 104/104 | 0 | 0 |
| Release / Win64 | 0 errores | 104/104 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes nuevos.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37 sin
errores: 310.629 líneas y 11,28 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6Z no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Alternar la foto desde un mantenimiento con artículo en la tabla base.
2. Cambiar entre SKU, stock y movimientos dentro de Artículos.
3. Repetir en ventas, compras e inventarios sobre la línea activa.
4. Comprobar que un registro sin artículo no abre una foto vacía.
5. Consultar stock con y sin SKU mediante Ctrl+U.
6. Cambiar de pestaña con la foto abierta y verificar el refresco.
7. Cerrar el mantenimiento con la foto abierta y comprobar la desvinculación.

D2 queda en **5 de 6 colaboradores**. El siguiente fascículo es D2.6:
diagnóstico de metadata BBDD.
