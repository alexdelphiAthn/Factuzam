# IA-S99 — informe de barrera final

- Fecha de ejecución: 2026-08-10.
- Revisión de partida: `df01faf97db3`.
- Resultado: **barrera roja; IA-S99 no se puede cerrar**.

No se ha creado ningún commit ni se ha hecho push. Las pruebas se ejecutaron
en serie sobre el árbol de trabajo actual.

## Resultado verificable

| Comprobación | Resultado | Evidencia |
| --- | --- | --- |
| Fixtures de arquitectura S31 | OK | 24/24. |
| Fixtures de compilación S32 | OK | 7/7. |
| Aplicación Release Win32 | OK | 433.265 líneas compiladas. |
| Aplicación Release Win64 | OK | 433.265 líneas compiladas. |
| Integración MariaDB S30 | OK | 6/6, incluida concurrencia y limpieza. |
| DUnitX Release Win32 | OK | 1.085/1.085, sin ignorados, fugas ni errores. |
| DUnitX Release Win64 | FALLO | La suite no compila; tres errores en `PruebasPedidoOcr.pas`. |
| Auditoría de arquitectura S31 | FALLO | 218 infracciones propias. |

La suite DUnitX ya no forma parte del checkout. Para obtener evidencia se
copiaron sus fuentes históricas únicamente a `build\reproducible` y se
resolvieron primero las unidades del `src` activo. Esa ejecución no sustituye
la necesidad de recuperar un proyecto de pruebas versionado y reproducible.

Win64 falla al compilar los tests en:

- líneas 79 y 81: `E2532` al inferir tipos distintos en `AreEqual`;
- línea 108: `E2250`, ninguna sobrecarga compatible de `WillRaise`.

No se modificó la copia temporal para forzar un resultado verde.

## Nueva medida demostrada

| Métrica | Tope anterior | Medida | Nuevo tope |
| --- | ---: | ---: | ---: |
| Fan-out UI | 45 | 45 | 45 |
| Fan-out de composición | 50 | 47 | 47 |

El tope de composición se ha bajado a 47 y sus fixtures rechazan volver a 48.
No se ha creado una baseline de excepciones para la deuda arquitectónica.

Otras medidas:

- 972 unidades propias, 12 de terceros y 0 generadas en `fzam.dpr`;
- 44 contextos de pantalla;
- 330 capacidades entregadas, 327 usadas y 3 sin usar;
- fan-in máximo con cuerpo: 84;
- clases: máximo 1.998 líneas, 102 métodos y 37 campos;
- métodos largos: 25 por encima de 120 líneas; máximo 164;
- consultas/SQL/transacciones creadas desde UI: 0.

## Deuda que bloquea la barrera

| Regla | Infracciones |
| --- | ---: |
| `ARQ01_MAINFORM` | 40 |
| `ARQ02_DMCONN` | 6 |
| `ARQ03_DM_CREATE_UI` | 12 |
| `ARQ04_UNIDAC_CONTRATO` | 154 |
| `ARQ05_ESTADO_GLOBAL` | 3 |
| `ARQ07_CONTEXTO_NO_USADO` | 3 |
| **Total** | **218** |

Esta deuda corresponde principalmente a IA-S10–IA-S13, que eran
prerrequisitos de S31 y no están cerradas. Por tanto, no es admisible
convertir las 218 infracciones en una lista blanca.

## Comprobadores históricos

Los antiguos scripts de calidad fueron eliminados del checkout. Como
evidencia complementaria se ejecutaron 14 copias históricas, en modo de solo
lectura, contra la raíz activa:

- 13 terminaron correctamente;
- `comprobar_sql_transacciones.ps1` falló porque todavía busca
  `TdmFacturas.PrepararCabeceraSinCamposComplejos` en
  `UniDataFacturas.pas`;
- el método fue extraído a `UniDataFacturasConfiguracion.pas` y sigue usando
  `DelimitarIdentificadorSql` con lista blanca, por lo que el diagnóstico es
  un trinquete desactualizado y no una concatenación insegura demostrada.

Al no estar versionados en el checkout, estos comprobadores no satisfacen la
reproducibilidad exigida por IA-S99.

## Cambios de esta barrera

- CI pasa de Debug a Release para Win32 y Win64.
- El máximo de fan-out de composición baja de 50 a 47.
- Se añade un fixture que impide ampliarlo a 48.
- Se conserva ausente `resultado_build_release_win64.txt`.
- No se editan proyectos vendorizados ni `factuzam_original.sql`.

El árbol candidato contiene 49 entradas sucias: 35 modificadas y 14 no
seguidas. No existe un manifiesto versionado que marque cada tarea como
`LISTA_PARA_INTEGRAR`, así que la condición de integración selectiva tampoco
puede demostrarse.

## Condiciones para repetir y cerrar S99

1. Eliminar las 218 infracciones de S31 sin ampliar límites ni exclusiones.
2. Recuperar o reemplazar el proyecto DUnitX dentro del checkout.
3. Corregir y ejecutar DUnitX Release Win64.
4. Reintegrar los comprobadores de calidad vigentes, actualizando el de SQL
   para reconocer la unidad extraída.
5. Registrar qué tareas están `LISTA_PARA_INTEGRAR`.
6. Repetir Release Win32/Win64, DUnitX, MariaDB y todos los trinquetes en
   serie.
