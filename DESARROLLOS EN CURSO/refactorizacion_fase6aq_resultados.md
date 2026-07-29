# Fase 6AQ — grabación del arqueo por pasos

Fecha: 29/07/2026. D4.7, séptima tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `TArqueoPersistencia.GrabarArqueo` | 371 | 21 | **-350** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibArqueoPersistencia` completa | 470 | 588 | **+118** |

La unidad crece un 25,1 %. D4.7 reduce complejidad, no volumen: el flujo
transaccional se convierte en una fachada y diez operaciones internas
con nombre. Todas tienen consumidor y ninguna supera 53 líneas.

No se crea otra unidad, no se cambia la API pública y cada línea de
recuento conserva su propia instancia `TUniQuery`.

## Implementación

`TGrabacionArqueo` conserva en un contexto explícito el arqueo, recuento,
totales, retirada, observaciones, empleado y usuario. El flujo queda
separado en:

- creación de consultas conectadas;
- reserva del número de retirada;
- inserción de cabecera;
- detección y actualización de columnas opcionales;
- inserción de las líneas de recuento;
- marcado de las operaciones incluidas;
- creación de la retirada de efectivo;
- coordinación de la transacción.

Se conserva el orden crítico:

1. generar `CODIGO_ARQ`;
2. reservar `PRC_GET_NEXT_OP_CAJA` fuera de la transacción;
3. iniciar la transacción;
4. cabecera, opcionales, recuento, marcado y retirada;
5. `Commit`, o `Rollback` y relanzamiento ante cualquier excepción.

También se conservan los SQL, parámetros, auditoría, columnas opcionales
según `INFORMATION_SCHEMA` y el posible hueco de numeración si una
retirada reservada termina en rollback.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.7:

- `TArqueoPersistencia.GrabarArqueo` no puede superar 100 líneas;
- las diez operaciones internas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protege el orden completo de la transacción;
- se protege el numerador centralizado previo;
- se conservan tablas, campos opcionales, marcado y tipo `GC`;
- el límite global baja de 44 a 43 métodos mayores de 200 líneas.

Resultado: fachada de 21 líneas, colaborador máximo de 53 y 43 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La unidad se compiló directamente con Delphi 37 en Win64 y Win32:
0 errores en ambas plataformas.

La matriz DUnitX se recompiló en salida aislada:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 216/217 | 0 | 1 |
| Debug / Win32 | 0 errores | 216/217 | 0 | 1 |
| Release / Win64 | 0 errores | 216/217 | 0 | 1 |
| Release / Win32 | 0 errores | 216/217 | 0 | 1 |

La única roja sigue siendo ajena a D4.7:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

La batería general no enlaza `inLibArqueoPersistencia`. La aplicación se
reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d47/Win64/Release`: 0 errores, 318.728 líneas y
10,62 segundos.

También pasan:

- el comprobador de flujos largos;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- `git diff --check` limitado al alcance;
- compilación directa de la unidad en las dos plataformas.

El comprobador global de dependencias queda rojo por dos aristas del
desarrollo paralelo del usuario:
`inLibCajaOpeComposicion -> inMtoCajaImpresorVenta` y
`inLibCajaOpeComposicion -> inMtoCajaGrabadorVenta`.
D4.7 no modifica ningún `uses` ni añade dependencias.

`factuzam_original.sql` sigue modificado (+95/-6) por el desarrollo
paralelo del usuario. D4.7 no lo ha tocado ni revertido.

## Validación funcional pendiente

Con una BBDD de pruebas:

1. Cerrar un arqueo con varias formas de pago y diferencias.
2. Repetir con todas, algunas y ninguna columna opcional instalada.
3. Verificar que solo se marcan operaciones sin arqueo del rango.
4. Probar sin retirada y con retirada, numerador y operación `GC`.
5. Comparar todos los totales, desglose, observaciones y auditoría.
6. Forzar un fallo tras la cabecera y comprobar el rollback completo.
7. Confirmar el hueco esperado si la retirada se reservó antes del fallo.
8. Probar dos cajas y varios cierres del mismo día.

El siguiente fascículo es **D4.8**:
`ImprimirResguardoDeposito`, actualmente con 339 líneas.
