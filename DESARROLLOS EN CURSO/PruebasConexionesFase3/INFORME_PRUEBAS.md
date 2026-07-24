# Informe de pruebas: conexiones, fase III

Fecha: 24/07/2026

## Resultado

Las colas persistentes de Verifactu y ventas WS ya reciben
`IServicioConexiones` al arrancar. Sus hilos solicitan conexiones con
`uctSegundoPlano` y han dejado de leer la variable global `oConn`.

Se han eliminado las dos implementaciones duplicadas
`CrearConexionPropia`.

## Ciclo de vida

1. `TfrmMtoPrincipal` crea y publica el servicio.
2. El formulario pasa el servicio a `TVerifactuCola.IniciarHilo` y
   `TVentasWsCola.IniciarHilo`.
3. Cada hilo conserva una referencia a la interfaz durante su ejecución.
4. Cada hilo crea y libera su propia `TUniConnection`.
5. El cierre detiene y espera a ambos hilos.
6. Después se invalida el servicio y se libera `FDmConn`.

La salida garantizada de `fzam.dpr` también detiene ahora las dos colas.

## Configuración de segundo plano

`TServicioConexionesUniDAC` conserva el comportamiento previo:

- pooling y reconexión local;
- opciones de conexión MySQL ya utilizadas;
- ejecución de `AfterConnect` para aplicar colación y timeouts;
- ausencia del manejador `OnError` de UI en los trabajadores.

## Pruebas automatizadas de Fase III

Script:
`DESARROLLOS EN CURSO/PruebasConexionesFase3/`
`PruebasConexionesFase3.ps1`

Resultado: **12 pruebas ejecutadas, 12 correctas y 0 fallos**.

| Grupo | Comprobación |
| --- | --- |
| Desacoplamiento | No queda `CrearConexionPropia` en las colas |
| Desacoplamiento | Ningún hilo de cola lee `oConn` |
| Servicio | Ambas colas solicitan `uctSegundoPlano` |
| Configuración | Segundo plano conserva `AfterConnect` |
| Cierre | Ambas colas paran antes de invalidar el servicio |
| Cierre alternativo | `fzam.dpr` detiene las dos colas |
| Diseñador | Permanecen 253 enlaces en 52 DFM |
| Integridad | No hay ningún DFM modificado |

## Pruebas del contrato

El proyecto de pruebas de Fase I se ha recompilado y ejecutado después de
los cambios del servicio.

Resultado: **6 pruebas ejecutadas, 6 correctas y 0 fallos**.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Delphi continúa mostrando advertencias y sugerencias ya existentes fuera de
la fachada de conexiones y de las rutas migradas.

## Compatibilidad con el diseñador

No se ha modificado ningún DFM. Los `DataModule` mantienen sus enlaces
persistentes `Connection = dmConn.conUni`, por lo que se conserva la
posibilidad de probar grids con datos desde el diseñador.

## Límite de las pruebas

No se ha realizado en esta ejecución una conexión real a MariaDB ni envíos a
AEAT o al servicio de ventas. La prueba funcional recomendada consiste en
iniciar ambas colas con intervalos cortos, comprobar su actividad en el log y
cerrar la aplicación mientras están a la espera.
