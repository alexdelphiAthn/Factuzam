# Anexo SRP — Resultados de L0: instrumentación

Fecha: 30/07/2026.

## Resultado

L0 queda implementado en `scripts/comprobar_tamano_clases.ps1`.

El trinquete vigila ahora:

- las seis clases-dios de formulario;
- `TGridPivoteVenta`;
- `TModoEntradaTallas`;
- unidades procedurales por líneas y número de rutinas, empezando por
  `UniDataComprasSesionesMaterializar`.

La salida diferencia:

1. valor actual;
2. tope anterior que hace fallar el build;
3. objetivo final de la fase;
4. estado `PENDIENTE` o `ALCANZADO`.

## Cambios realizados

1. El límite de `TfrmMtoComprasSesiones` baja de 3.663 a su medida de
   clase confirmada de 3.660 líneas.
2. `TGridPivoteVenta` queda vigilada individualmente en líneas, métodos
   y campos.
3. `TModoEntradaTallas` queda vigilada individualmente en líneas,
   métodos y campos.
4. Se añade `LimitesUnidades` para código procedural.
5. Las unidades procedurales cuentan solo rutinas declaradas después de
   `implementation`; los métodos `TClase.Metodo` siguen perteneciendo a
   la medición de clases.
6. La desaparición o duplicación de una clase vigilada sigue siendo
   error.
7. La desaparición de una unidad procedural vigilada es ahora error.
   Cuando C1-C7 la divida o elimine, el mismo fascículo debe sustituir
   su entrada por las nuevas unidades.
8. El resumen final informa también del número de unidades procedurales
   vigiladas.

## Línea base congelada

| Objetivo | Actual y tope | Objetivo final |
|---|---:|---:|
| `TfrmMtoComprasSesiones` — líneas | 3.660 | 2.000 |
| `TGridPivoteVenta` — líneas | 2.971 | 1.500 |
| `TGridPivoteVenta` — métodos | 86 | 45 |
| `TGridPivoteVenta` — campos | 49 | 25 |
| `TModoEntradaTallas` — líneas | 2.481 | 1.500 |
| `TModoEntradaTallas` — métodos | 71 | 45 |
| `TModoEntradaTallas` — campos | 29 | 20 |
| `UniDataComprasSesionesMaterializar` — líneas físicas | 3.042 | 600 |
| `UniDataComprasSesionesMaterializar` — rutinas | 75 | 30 |

La tarea C1-C7 puede reducir estas cifras en paralelo. Cada fascículo
debe sustituir el tope por su nueva medida; L0 no conserva margen.

## Validación positiva

Ejecución usada por el build:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\comprobar_tamano_clases.ps1
```

Resultado:

- código de salida 0;
- máximos globales: 4.060 líneas, 133 métodos y 49 campos;
- ocho clases-dios con límite individual;
- una unidad procedural vigilada;
- `git diff --check` correcto.

El número total de clases puede variar mientras haya trabajo
concurrente; no forma parte del techo SRP.

## Pruebas negativas

Se ejecutaron seis casos con límites inyectados. Todos devolvieron
código 1:

| Caso | Resultado |
|---|---|
| `TGridPivoteVenta` supera el límite de líneas | detectado |
| `TGridPivoteVenta` supera el límite de campos | detectado |
| clase vigilada ausente | detectado |
| unidad procedural supera el límite de líneas | detectado |
| unidad procedural supera el límite de rutinas | detectado |
| unidad procedural ausente | detectado |

## Compilación

Se intentó `Release/Win64`. El compilador arrancó correctamente, pero la
compilación completa quedó bloqueada por trabajo concurrente ajeno a
L0:

```text
src\Caja\Lib\inLibTiraCajaTicket.pas(35):
error F2613: Unit 'inLibTiraCajaTicketIntf' not found.
```

En ese momento `inLibTiraCajaTicketIntf.pas` y su repositorio eran
ficheros nuevos sin integrar todavía en `fzam.dproj`. L0 no toca esas
unidades. La compilación se repetirá cuando termine ese fascículo
concurrente.

## Protocolo para C1-C7

La tarea concurrente debe cumplir estas reglas:

1. Si baja líneas, rutinas, métodos o campos, baja el tope
   correspondiente en el mismo fascículo.
2. Nunca actualiza un tope al alza para hacer pasar el script.
3. Si divide `UniDataComprasSesionesMaterializar`, sustituye su entrada
   en `LimitesUnidades`; no la borra dejando las unidades resultantes
   sin vigilancia.
4. Mantiene 600 líneas y 30 rutinas como objetivo de la fachada final,
   y 1.200 líneas como máximo para cada unidad resultante.
5. Ejecuta el script antes de compilar y adjunta su salida al documento
   de resultados del fascículo.

