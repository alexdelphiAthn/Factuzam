# Fase 7 — rendimiento del recálculo de venta

Fecha: 29/07/2026. Sin commit.

## Resultado

El recálculo completo conserva el motor fiscal común, pero ahora:

- reutiliza una única instancia de `TLinFac` durante el recorrido;
- cachea los doce `TField` usados por cada línea;
- reserva de una vez el vector que recibe el motor fiscal;
- calcula cada línea antes de incorporarla al documento;
- permite recalcular una línea sin acumular todo el documento;
- agrupa los cambios del editor y acumula el documento una vez al
  confirmar la fila.

Los procesos que realizan `Post` de forma masiva no activan por sí solos
el recálculo interactivo pendiente. Así se evita convertir una carga de
líneas en un proceso cuadrático.

## Medición Win32

Mediana de cinco ejecuciones Release con el mismo equipo y proceso:

| Líneas | Antes, ms | Después, ms | Reducción |
|---:|---:|---:|---:|
| 20 | 0,149 | 0,087 | 41,6 % |
| 200 | 1,270 | 0,662 | 47,9 % |
| 2.000 | 17,143 | 10,046 | 41,4 % |

El recálculo aislado de una línea tarda aproximadamente 3,9
microsegundos y no depende del número de líneas del documento. En un
documento de 2.000 líneas evita recorrer unas 2.000 líneas por cada
cambio del editor.

La prueba reproducible está en
`tests/RendimientoMotorFiscalVenta.dpr`. Mide 20, 200 y 2.000 líneas,
el recálculo completo, el unitario y los `Post` producidos.

## Logging

`AbrirDetalles` conserva un único `LogPerf` para el límite completo de
la operación. Se han eliminado sus tiempos por consulta interna.

Las aperturas perezosas conservan un tiempo por operación porque cada
una corresponde a una acción independiente del usuario. No se han
añadido logs dentro del recorrido ni del cálculo de líneas.

## Validación

- Aplicación Release Win32: 0 errores, 317.344 líneas.
- Aplicación Release Win64: 0 errores, 317.344 líneas.
- DUnitX Win32: 211 de 212 pruebas correctas, 0 fugas.
- DUnitX Win64: 211 de 212 pruebas correctas, 0 fugas.
- Dependencias de capa: 403 unidades, ciclo mayor 1.
- Flujos largos: 45 métodos por encima de 200, sin regresión.
- UTF-8 con BOM, CRLF y `git diff --check` correctos en el alcance.

La única prueba roja sigue siendo
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption`: espera
`Perfil activo`, pero el comportamiento actual conserva `Original`.
Es un cambio concurrente ajeno a esta fase.

El comprobador SQL también detecta un cambio concurrente fuera del
alcance: `TfrmMtoFacturasBase.btnConsolidarClick` ya no muestra
directamente `StartTransaction`. Esta fase no modifica ese flujo.
