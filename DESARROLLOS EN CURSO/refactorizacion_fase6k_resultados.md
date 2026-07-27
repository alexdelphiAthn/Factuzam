# Fase 6K — persistencia común de cabeceras de compra (resultados)

Fecha: 27/07/2026. Undécimo fascículo de D1 terminado. Sin commit.

## Balance de código

Esta fase se ha medido separando producción, pruebas y documentación:

| Concepto | Antes | Después | Balance |
|---|---:|---:|---:|
| Cuatro métodos de formulario | 290 | 54 | -236 |
| Callback propio de devoluciones | 0 | 16 | +16 |
| Ampliación de la unidad común | 0 | 84 | +84 |
| Total productivo del alcance | 290 | 154 | **-136** |
| Pruebas nuevas | 0 | 62 | +62 |
| Producción más pruebas | 290 | 216 | **-74** |

El código productivo del alcance baja un 47 %. Incluso contando las
pruebas, la fase elimina 74 líneas.

El contador de compilación principal pasa de 307.844 a 307.802 líneas.
Su descenso de 42 líneas no coincide con la medición directa porque
depende de las unidades que Delphi decide compilar.

## Implementación

`inLibValidacionTallasCompra` centraliza ahora también:

- validación de cabecera activa o en edición;
- cancelación de una línea nueva vacía mientras falta la numeración;
- publicación de la cabecera para obtener serie y número definitivos;
- valor predeterminado `N` para el pivote horizontal;
- sincronización de serie y número en la línea activa;
- reapertura del dataset de líneas cuando está en navegación.

Los formularios conservan:

- el error propio cuando no está inicializado su módulo de datos;
- datasets, prefijos y tabla de cada documento;
- el comportamiento silencioso previo de devoluciones si no existe su
  módulo de datos;
- la obligación de seleccionar almacén de salida en devoluciones.

La regla del almacén de devoluciones queda en
`ValidarAlmacenSalidaParaLineas`, pasada como callback al flujo común.
Mantiene el orden previo: primero se valida la cabecera y después se
cambia a la pestaña de cabecera, se enfoca el almacén y se informa del
error.

## Pruebas automáticas

Se amplía `PruebasValidacionTallasCompra` con:

1. comprobaciones de línea vacía con y sin SKU;
2. nombre configurado del campo de pivote de cabecera;
3. publicación de una cabecera sin número;
4. valor predeterminado `N` del pivote;
5. sincronización de serie y número en una línea activa.

La batería DUnitX pasa de 44 a 45 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 45/45 | 0 | 0 |
| Debug / Win32 | 0 errores | 45/45 | 0 | 0 |
| Release / Win64 | 0 errores | 45/45 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.802
líneas en 10,91 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6K no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `git diff --check` de los archivos de la fase sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En pedidos, albaranes, devoluciones y facturas de compra:

1. crear una cabecera aún sin número e iniciar una línea vacía;
2. provocar la persistencia y comprobar que la línea vacía se cancela;
3. verificar que la cabecera obtiene número y el pivote vacío pasa a `N`;
4. iniciar una línea con artículo y comprobar serie y número sincronizados;
5. repetir desde una cabecera ya guardada y revisar la reapertura de líneas;
6. en devoluciones, omitir el almacén y comprobar pestaña, foco y mensaje;
7. seleccionar el almacén y confirmar que la persistencia continúa.

El siguiente candidato es 6L: `CargarBasicosColorArticulo`. Solo debe
extraerse si la medición previa confirma una reducción productiva clara.
