# Fase 6X — guías de grid de `TfrmMtoGen`

Fecha: 28/07/2026. D2.3 y tercer fascículo de D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 2.768 | 2.353 | **-415** |
| Nuevo `inLibGestorGuiasGridMto` | 0 | 610 | +610 |
| Total productivo del alcance | 2.768 | 2.963 | **+195** |

El formulario baja un 15,0 %. El alcance productivo completo crece un
7,0 % por la clase, los callbacks, la propiedad explícita de cuatro
recursos y la separación de operaciones para poder comprobarlas.

Acumulado de D2: `TfrmMtoGen` ha bajado de 3.346 a 2.353 líneas,
**-993 (-29,7 %)**. Los tres colaboradores suman 1.504 líneas y el
alcance productivo acumulado pasa de 3.346 a 3.857,
**+511 (+15,3 %)**.

Durante el trabajo continuaron cambios concurrentes de traducción,
especialmente en `inLibMsg`. Por ello el contador global de la
aplicación, 309.963 líneas, no permite aislar D2.3. El balance atribuible
al fascículo es el de la tabla.

## Implementación

La nueva clase `TGestorGuiasGridMto` concentra:

- propiedad del popup de columnas;
- propiedad de la SQL original antes del enriquecimiento;
- propiedad de campos guía, tabla de origen y columnas visibles;
- enriquecimiento de la consulta mediante `EnriquecerQueryConGuias`;
- reapertura defensiva y restauración de la SQL si falla;
- creación y limpieza de columnas dinámicas;
- reaplicación de su visibilidad tras los perfiles;
- composición del menú, agrupado por tabla guía;
- alternancia y renombrado de columnas;
- alta de guías y selección de campos visibles;
- persistencia y borrado de guías e invalidación de caché.

La unidad vive en `src/Lib` y no depende de formularios del proyecto.
Tres callbacks tipados aíslan:

- la obtención de la conexión del mantenimiento;
- la resolución de la consulta principal;
- la apertura del modal específico `TfrmModalGridGuias`.

`TfrmMtoGen` conserva una fachada protegida de una línea llamada
`AplicarGuiasGrid`. Es necesaria porque `TfrmMtoSearch` la utiliza desde
su override de `CrearTablaPrincipal`. El resto del formulario se limita
a ciclo de vida y dos adaptadores.

El gestor de perfiles de D2.2 recibe ahora directamente
`TGestorGuiasGridMto.BorrarGuias`; desaparece el adaptador intermedio
del formulario.

## Pruebas automáticas

Se añade `PruebasGestorGuiasGridMto.pas` con cinco pruebas DUnitX sin
BBDD:

1. copia independiente de las tres listas de estado;
2. reaplicación de columnas visibles y ocultas;
3. agrupación de campos guía por tabla en el popup;
4. alternancia de la visibilidad de una columna;
5. limpieza exclusiva de columnas procedentes de guías.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 92/92 | 0 | 0 |
| Debug / Win32 | 0 errores | 92/92 | 0 | 0 |
| Release / Win64 | 0 errores | 92/92 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes nuevos.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37:
0 errores, 309.963 líneas y 11,31 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6X no
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

1. Abrir un mantenimiento con guías y comprobar el `LEFT JOIN`, campos
   dinámicos y visibilidad guardada.
2. Abrir el popup y verificar columnas normales y submenús por tabla.
3. Mostrar y ocultar columnas desde el popup.
4. Renombrar varias columnas visibles y guardar después el layout.
5. Crear o editar una guía, elegir campos, cerrar y reabrir la pantalla.
6. Resetear el layout y confirmar el borrado de guías y la caché.
7. Repetir la carga desde una búsqueda modal para validar la fachada
   heredable `AplicarGuiasGrid`.

D2 queda en **3 de 6 colaboradores**. El siguiente fascículo es D2.4:
tareas y overlay.
