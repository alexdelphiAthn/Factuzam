# Fase 6AT — des-pivote del modo de tallas

Fecha: 29/07/2026. D4.10, décima tanda de métodos largos. Sin commit
manual.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `TModoEntradaTallas.Desmontar` | 332 | 14 | **-318** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibColumnasSkuModoTallas` completa | 2.905 | 2.998 | **+93** |

La unidad crece un 3,2 %. D4.10 reduce complejidad, no volumen: el
des-pivote pasa a una fachada y once operaciones privadas con nombre.
Todas tienen consumidor y ninguna supera 58 líneas.

No se crea otra unidad ni cambia la API pública. El estado temporal de
la conversión vive en `TDesmontajeTallas`, sin añadir campos de proceso
a `TModoEntradaTallas`.

## Implementación

`TDesmontajeTallas` separa:

- localización numérica de líneas `Integer` o `varchar` rellenadas;
- lectura agrupada de celdas por línea, talla y almacén;
- cálculo de la siguiente numeración;
- recuperación y caché de los atributos de cada artículo;
- actualización de la primera talla sobre la línea original;
- creación de una línea por cada talla/almacén adicional;
- borrado de las celdas transferidas;
- coordinación de invariante, transacción y notificación al host.

Se conserva el orden crítico:

1. silenciar los hooks internos;
2. iniciar transacción propia cuando no exista una exterior;
3. medir las unidades;
4. cargar y expandir las celdas;
5. borrar las celdas transferidas;
6. restaurar el estado interno;
7. comprobar el invariante;
8. `Commit`, o `Rollback` y relanzamiento;
9. notificar una sola vez los posts silenciados.

También se conservan el agrupado distribuido, el fallback del almacén
de la línea, los precios, atributos, SKU, talla visible, pivote a cero,
formato de numeración y log de celdas expandidas.

El colaborador garantiza además que las colecciones y `FEnProceso` se
restauren si `StartTransaction` falla antes de entrar en la conversión.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.10:

- `Desmontar` no puede superar 100 líneas;
- las once operaciones privadas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protege el orden transaccional completo;
- se protege la fachada y la liberación del colaborador;
- se conservan agrupado, tabla de atributos, borrado, claves opcionales,
  formato de línea, pivote y log;
- el límite global baja de 41 a 40 métodos mayores de 200 líneas.

Resultado: fachada de 14 líneas, colaborador máximo de 58 y 40 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La aplicación principal se reconstruyó con Delphi 37 en Release/Win32
y Release/Win64 dentro de `build/validacion_d410`. Ambas plataformas
enlazan el refactor sin errores.

La matriz DUnitX general no enlaza
`inLibColumnasSkuModoTallas`, pero se recompiló en salida aislada para
controlar regresiones concurrentes:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 222/223 | 0 | 1 |
| Debug / Win32 | 0 errores | 222/223 | 0 | 1 |
| Release / Win64 | 0 errores | 222/223 | 0 | 1 |
| Release / Win32 | 0 errores | 222/223 | 0 | 1 |

La única roja sigue siendo ajena a D4.10:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

El banco específico `ColumnSKUcxGridTest` no llega a compilar el
objetivo: `inMtoPruebaColumnasSkuLogon` conserva referencias a los
globales ya retirados `oConn`, `oUser`, `oGroup` y `orootGroup`.
Es un bloqueo previo a D4.10 y no se ha corregido fuera de alcance.

También pasan:

- el comprobador de flujos largos;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- compilación de la unidad dentro de la aplicación principal.

El comprobador global de dependencias queda rojo por dos aristas del
desarrollo paralelo:
`inLibCajaOpeComposicion -> inMtoCajaImpresorVenta` y
`inLibCajaOpeComposicion -> inMtoCajaGrabadorVenta`.
D4.10 no modifica ningún `uses` ni añade dependencias.

La modificación paralela de `factuzam_original.sql` fue incorporada por
el commit automático anterior. D4.10 no toca ni revierte el dump.

## Validación funcional pendiente

Con una BBDD y documentos de pruebas:

1. Salir de tallas con un documento sin celdas.
2. Expandir varias tallas de una misma línea.
3. Expandir la misma talla distribuida entre varios almacenes.
4. Probar líneas numéricas y `varchar` con distintos rellenos.
5. Comprobar SKU, talla visible, atributos, precio y cantidades.
6. Repetir el ciclo desglose → tallas → desglose sin pérdidas.
7. Probar con transacción propia y dentro de una transacción exterior.
8. Forzar un atributo o línea inexistente y verificar rollback por el
   invariante de unidades.
9. Confirmar una sola notificación final de posts al host.

El siguiente fascículo es **D4.11**:
`TPrestaConn.CargarPedido`, actualmente con 312 líneas.
