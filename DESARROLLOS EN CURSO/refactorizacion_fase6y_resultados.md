# Fase 6Y — tareas y overlay de `TfrmMtoGen`

Fecha: 28/07/2026. D2.4 y cuarto fascículo de D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 2.353 | 2.183 | **-170** |
| Nuevo `inLibGestorTareasMto` | 0 | 303 | +303 |
| Total productivo del alcance | 2.353 | 2.486 | **+133** |

El formulario baja un 7,2 %. El alcance productivo completo crece un
5,7 % por encapsular el estado, el cierre seguro, los callbacks y las
operaciones que ahora pueden comprobarse de forma aislada.

Acumulado de D2: `TfrmMtoGen` ha bajado de 3.346 a 2.183 líneas,
**-1.163 (-34,8 %)**. Los cuatro colaboradores suman 1.807 líneas y el
alcance productivo acumulado pasa de 3.346 a 3.990,
**+644 (+19,2 %)**.

Durante el trabajo continuaron cambios concurrentes de traducción,
especialmente en `inLibMsg`. Por ello el contador global de la
aplicación no permite aislar D2.4. El balance atribuible al fascículo es
el de la tabla.

## Implementación

La nueva clase `TGestorTareasMto` concentra:

- propiedad y construcción del overlay de carga;
- bloqueo reentrante mediante un contador equilibrado;
- registro y espera de las tareas en curso;
- rechazo de trabajo nuevo durante el cierre;
- cancelación de la operación activa mediante callback;
- espera de hasta 5 segundos al cerrar una pestaña;
- espera de hasta 15 segundos al cerrar la aplicación;
- ejecución del callback de finalización en el hilo principal;
- registro aislado de errores de la tarea y de su callback.

El estado de ciclo de vida capturado por los callbacks encolados tiene
conteo de referencias. Si una tarea supera el tiempo de espera, el
callback puede consultar que el formulario está destruyéndose sin
acceder al gestor ni al formulario ya liberados.

`TfrmMtoGen` conserva las fachadas protegidas de una línea
`BloquearTabPorOcupado` y `EjecutarEnBackground`. Son necesarias para
los mantenimientos descendientes, en particular `inMtoInventarios`.
El formulario se limita a crear el gestor, aportar los callbacks de
cierre y cancelación, y liberarlo durante `FormDestroy`.

## Pruebas automáticas

Se añade `PruebasGestorTareasMto.pas` con cinco pruebas DUnitX sin BBDD:

1. el bloqueo reentrante mantiene el overlay hasta equilibrar el contador;
2. un desbloqueo sobrante no deja el contador en negativo;
3. el cierre de la aplicación impide iniciar trabajo nuevo;
4. una tarea activa termina durante `EsperarFinalizacion`;
5. el estado de destrucción impide iniciar trabajo nuevo.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 97/97 | 0 | 0 |
| Debug / Win32 | 0 errores | 97/97 | 0 | 0 |
| Release / Win64 | 0 errores | 97/97 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes nuevos.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37 sin
errores: 310.330 líneas y 11,19 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6Y no
modifica esa unidad.

Durante la matriz apareció una colisión en un literal añadido de forma
concurrente a `inLibMsg`: la constante nueva duplicaba
`SErrorCodigoAcreedorSepaNoValido`. Se diferenció como
`SErrorFormatoCodigoAcreedorSepaNoValido`; no se revirtió ningún otro
cambio de traducción.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir un mantenimiento con carga asíncrona y comprobar el overlay.
2. Encadenar bloqueos y verificar que solo desaparece al equilibrarlos.
3. Forzar éxito y error y comprobar los callbacks en el hilo principal.
4. Repetir la operación de inventarios que usa las dos fachadas.
5. Cerrar una pestaña durante una tarea y comprobar cancelación y espera.
6. Cerrar la aplicación durante una tarea y comprobar la espera ampliada.
7. Verificar que no queda un callback encolado accediendo al formulario.

D2 queda en **4 de 6 colaboradores**. El siguiente fascículo es D2.5:
dominio de artículos.
