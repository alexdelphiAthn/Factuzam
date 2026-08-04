# Fase 6AA — diagnóstico de metadata de `TfrmMtoGen`

Fecha: 28/07/2026. D2.6, sexto fascículo y recorrido D2 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `TfrmMtoGen` | 2.197 | 2.156 | **-41** |
| `inLibDiag` | 69 | 165 | +96 |
| Total productivo del alcance | 2.266 | 2.321 | **+55** |

El formulario baja un 1,9 %. El alcance productivo completo crece un
2,4 % porque la antigua rutina monolítica se divide en detección pura,
composición del mensaje y registro. La detección puede reutilizarse y
probarse sin abrir formularios ni escribir en el log.

Balance final de D2: `TfrmMtoGen` ha bajado de 3.346 a 2.156 líneas,
**-1.190 (-35,6 %)**. Los cinco gestores suman 1.970 líneas y el código
añadido a `inLibDiag` suma 96. El alcance productivo acumulado atribuible
a D2 pasa de 3.346 a 4.222 líneas, **+876 (+26,2 %)**.

Los contadores globales de compilación incluyen cambios concurrentes de
traducción y no permiten aislar D2.6. El balance atribuible al fascículo
es el de la tabla.

## Implementación

`inLibDiag` incorpora:

- `TIncidenciaMetadataCampo`, con nombre y tipo detectados;
- `DetectarCamposBooleanosNumericos`, sin efectos secundarios;
- `MensajeCampoBooleanoNumerico`, con el diagnóstico y la solución;
- `DiagnosticarCamposBooleanos`, que registra todas las incidencias.

La detección trabaja con `TDataSet`, no con `TUniQuery`, por lo que no
añade una dependencia de UniDAC. Conserva exactamente los tipos
numéricos incompatibles y la comparación sin distinguir mayúsculas del
prefijo `ES`.

Los flujos síncrono y asíncrono de apertura de la tabla principal siguen
ejecutando el diagnóstico en el mismo punto. `TfrmMtoGen` ya no contiene
el recorrido de campos, la clasificación de tipos ni la composición del
mensaje.

## Pruebas automáticas

Se añade `PruebasDiagnosticoMetadata.pas` con cinco pruebas DUnitX sin
BBDD:

1. un dataset nulo no produce incidencias;
2. un dataset inactivo no produce incidencias;
3. solo se detectan campos `ES*` numéricos;
4. el prefijo se reconoce sin distinguir mayúsculas;
5. el mensaje incluye contexto, campo, tipo y solución.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 109/109 | 0 | 0 |
| Debug / Win32 | 0 errores | 109/109 | 0 | 0 |
| Release / Win64 | 0 errores | 109/109 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes nuevos.
La aplicación principal Release/Win64 se reconstruyó con Delphi 37 sin
errores: 310.756 líneas y 19,36 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6AA no
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

1. Abrir por la ruta asíncrona una vista con un campo `ES*` numérico.
2. Repetir mediante una búsqueda que use la ruta síncrona.
3. Verificar que un campo `ES*` `varchar(1)` no genera error.
4. Verificar que un campo numérico sin prefijo `ES` no genera error.
5. Probar una vista con varias incidencias y comprobar un log por campo.
6. Confirmar que el log propone recrear la vista afectada.

D2 queda **cerrado: 6 de 6 colaboradores**. El siguiente bloque del plan
es D3: partir `inLibtb` manteniendo una fachada compatible.
