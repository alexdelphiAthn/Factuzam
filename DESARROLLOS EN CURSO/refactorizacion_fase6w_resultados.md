# Fase 6W — perfiles de pantalla de `TfrmMtoGen`

Fecha: 28/07/2026. D2.2 y segundo fascículo de D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 2.985 | 2.768 | **-217** |
| Nuevo `inLibGestorPerfilesMto` | 0 | 449 | +449 |
| Total productivo del alcance | 2.985 | 3.217 | **+232** |

El formulario baja un 7,3 %. El alcance productivo completo crece un
7,8 % por la clase, los contratos de callback, la propiedad explícita
del diccionario y las defensas de ciclo de vida. D2.2 separa una
responsabilidad y crea puntos comprobables; no es una reducción global.

Acumulado de D2: `TfrmMtoGen` ha bajado de 3.346 a 2.768 líneas,
**-578 (-17,3 %)**. Los dos colaboradores suman 894 líneas y el alcance
productivo acumulado pasa de 3.346 a 3.662, **+316 (+9,4 %)**.

Durante el trabajo continuaron cambios concurrentes de traducción,
especialmente en `inLibMsg`. Por ello el contador global de la
aplicación, 309.613 líneas, no permite aislar D2.2. El balance atribuible
al fascículo es el de la tabla.

## Implementación

La nueva clase `TGestorPerfilesMto` concentra:

- propiedad y liberación del diccionario `TProfileDicc`;
- carga del perfil efectivo de usuario y grupo;
- lectura de valores con predeterminado;
- aplicación de captions, columnas, anchos y foco de grid;
- carga de perfiles comunes, captions y columnas;
- composición y persistencia del lote del layout;
- reseteo de todos los grids del formulario;
- preparación y apertura de la consulta de perfiles;
- restauración del foco tras abrir los datos.

La unidad vive en `src/Lib` y no depende de `inMtoGen` ni de sus
descendientes. Cuatro callbacks tipados aíslan:

- el modal que solicita usuario o grupo de destino;
- los perfiles particulares aportados por descendientes;
- el reseteo que aún ejecuta `TdmBase`;
- el borrado de guías, reservado para D2.3.

`TfrmMtoGen` conserva los métodos virtuales existentes. El campo público
`oPerfilDic` queda como alias no propietario para no romper los
descendientes que leen opciones propias. El gestor es el único
propietario y se libera con `FreeAndNil`.

## Pruebas automáticas

Se añade `PruebasGestorPerfilesMto.pas` con cuatro pruebas DUnitX sin
BBDD:

1. carga de valores, predeterminados y caption del formulario;
2. grabación de los seis perfiles comunes;
3. composición del lote común más el hook particular;
4. recorrido de grids y callback de borrado de guías al resetear.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 87/87 | 0 | 0 |
| Debug / Win32 | 0 errores | 87/87 | 0 | 0 |
| Release / Win64 | 0 errores | 87/87 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes nuevos.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37:
0 errores, 309.613 líneas y 24,73 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6W no
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

1. Abrir un mantenimiento con perfil propio y comprobar captions,
   visibilidad, orden y ancho de columnas.
2. Guardar el layout con Alt+F12 para usuario y grupo; cerrar y reabrir.
3. Repetir en Artículos, Facturas simplificadas y Movimientos para
   comprobar sus perfiles particulares.
4. Resetear con Ctrl+F12 y confirmar que también desaparecen las guías.
5. Abrir la pestaña de perfiles en un mantenimiento y en una búsqueda
   modal.
6. Navegar tras la precarga síncrona y asíncrona y comprobar que se
   restaura el registro enfocado.

D2 queda en **2 de 6 colaboradores**. El siguiente fascículo es D2.3:
guías de grid.
