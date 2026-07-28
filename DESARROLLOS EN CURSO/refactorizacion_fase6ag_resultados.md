# Fase 6AG — poda de búsquedas y filtros obsoletos

Fecha: 28/07/2026. D3.6, sexto fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo. Esta tanda no añade
ninguna:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 877 | 691 | **-186** |
| `inLibGenBusq` | 98 | 95 | **-3** |
| Total productivo del alcance | 975 | 786 | **-189** |

`inLibtb` baja un 21,2 % en esta tanda y el alcance productivo completo,
un 19,4 %. No se crea una unidad especializada porque el inventario
encontró cero consumidores para el bloque retirado.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 691 líneas, **-832 (-54,6 %)**;
- unidades especializadas o código añadido a ellas: 1.118 líneas;
- núcleo completo: 1.523 a 1.809 líneas, **+286**;
- alcance productivo acumulado: **+316 líneas**;
- dependencias directas de `inLibtb`: 50 a 11, incluida la fachada.

## Inventario y decisión

La búsqueda global, incluyendo proyectos independientes y pruebas, no
encontró ninguna llamada a:

- `SetFilterSQL`;
- `ObtenerCadenaFiltro`;
- `BusqDataBase`;
- `BusqDataBaseMD`.

`SetFilterSQL` solo copiaba `SQL.Text` a una variable local que después
no se usaba. Las otras tres rutinas eran prototipos antiguos: construían
filtros con `LIKE`, modificaban las consultas mediante
`SQLBuilder4D` y las abrían directamente, pero no formaban parte de
ningún flujo de la aplicación.

Tras la indicación de retirar lo que no se usa, se eliminan tanto sus
declaraciones públicas como las implementaciones. Crear una fachada y
una unidad nueva para código sin consumidores habría aumentado de nuevo
el proyecto sin aportar comportamiento.

## Dependencias retiradas

`inLibtb` deja de exponer:

- `SQLBuilder4D`;
- `SQLBuilder4D.Parser`;
- `SQLBuilder4D.Parser.GaSQLParser`;
- `System.StrUtils`.

La revisión de `inLibGenBusq`, la librería viva que abre búsquedas
genéricas, detectó 31 imports sin uso heredados de una copia antigua.
Sus dependencias bajan de 36 a 5:

- `Forms`;
- `Uni`;
- `DBAccess`;
- `SysUtils`;
- `inLibMsg`.

Se conserva completa `TBusquedaUtils`, que tiene consumidores reales en
ventas, compras, inventarios, caja, modales y librerías de artículos.
También permanecen `inLibFiltroUsuario`, `inLibGestorFiltrosMto` e
`inLibBusquedasCompra`, todos con consumidores y pruebas activas.

## Pruebas automáticas

No se añaden pruebas para rutinas eliminadas que nunca se ejecutaban.
La evidencia de retirada segura es:

1. búsqueda global sin referencias a las cuatro firmas;
2. compilación de todos sus consumidores;
3. batería DUnitX completa;
4. compilación de la aplicación principal.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 141/141 | 0 | 0 |
| Debug / Win32 | 0 errores | 141/141 | 0 | 0 |
| Release / Win64 | 0 errores | 141/141 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados.

La aplicación se reconstruyó en Release/Win64 con Delphi 37 en
`build/validacion_d36/Win64/Release`: 0 errores, 311.084 líneas y
22,75 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.6 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- ninguna referencia residual a las cuatro firmas retiradas;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

No hay un flujo funcional asociado al código eliminado. Para validar la
limpieza de imports de `inLibGenBusq` queda una comprobación manual
breve:

1. abrir y seleccionar un registro en una búsqueda genérica de ventas;
2. repetir en una búsqueda de compras;
3. repetir en una búsqueda de inventario;
4. cancelar una búsqueda y comprobar que no cambia el registro actual.

D3 queda abierto: **6 de 9 fascículos**. El siguiente es D3.7:
INI, ficheros y rutas.
