# Informe de pruebas: monitor SQL, fase VI

Fecha: 24/07/2026

## Resultado

El monitor SQL ha dejado de depender de la instancia global `odmConn`.

La temporización de sentencias, el cierre de operaciones pendientes y el
control de activación se encuentran ahora detrás de interfaces. `TdmConn`
conserva el componente persistente `TUniSQLMonitor` y su evento `OnSQL`, pero
solo traduce los eventos UniDAC y los entrega al nuevo servicio.

La variable global `odmConn` se ha eliminado completamente de `src`.

## Estructura incorporada

- `IServicioMonitorSQL` publica las operaciones utilizadas por formularios y
  por el sistema de log.
- `IReceptorEventosMonitorSQL` separa la entrada de eventos técnicos de
  UniDAC de las operaciones disponibles para los consumidores.
- `IRegistroMonitorSQL` abstrae el destino de las trazas.
- `IProveedorMonitorSQL` permite que los formularios hereden el servicio.
- `TServicioMonitorSQLUniDAC` mantiene el estado y el cronómetro de la
  sentencia pendiente.
- `TRegistroMonitorSQLLog` adapta el servicio al `TLog` existente.
- `TfrmBase` hereda y publica el servicio a todos sus descendientes.
- `TfrmMtoPrincipal` compone los objetos y controla su invalidación.

## Cambios en consumidores

Los cuatro modales de impresión de Caja y el menú principal de Caja llaman a
`CerrarMonitorSQLPendiente`, heredado de `TfrmBase`.

`TLog` activa o desactiva el monitor mediante `IServicioMonitorSQL`, sin
conocer `TdmConn` ni acceder directamente a `TUniSQLMonitor1`.

`inLibGlobalVar` ya no declara `odmConn` y tampoco necesita incluir
`UniDataConn`.

## Compatibilidad funcional

Se mantiene el comportamiento anterior:

- una ejecución SQL inicia el cronómetro;
- un evento final registra la sentencia correctamente;
- un error registra la sentencia como fallida;
- una nueva ejecución cierra antes la sentencia anterior;
- los selectores modales pueden cerrar explícitamente el pendiente;
- el SQL se muestra en el memo cuando el modo SQL está activo.

Además, al desactivar el monitor se descarta cualquier sentencia pendiente
para que no aparezca como una traza antigua al reactivarlo.

La destrucción de `TdmConn` invalida también el servicio. Esto evita conservar
una referencia al componente UniDAC si falla la creación del formulario
principal o se reinicia la sesión.

## Pruebas del servicio

Proyecto:
`PruebasMonitorSQLFase6.dpr`

Resultado: **15 pruebas ejecutadas, 15 correctas y 0 fallos**.

Se han probado:

- ejecución y finalización correctas;
- registro de errores;
- cierre explícito antes de abrir un modal;
- cierre repetido sin duplicados;
- monitorización desactivada;
- descarte del pendiente al desactivar;
- ejecuciones consecutivas;
- activación y desactivación de `TUniSQLMonitor`;
- operaciones posteriores a la invalidación.

El ejecutable y los DCU temporales se eliminaron después de ejecutar las
pruebas.

## Pruebas estructurales

Script:
`PruebasMonitorSQLFase6.ps1`

Resultado: **14 pruebas ejecutadas, 14 correctas y 0 fallos**.

Las comprobaciones cubren los contratos, la separación de responsabilidades,
la composición, la propagación por `TfrmBase`, la eliminación de `odmConn`,
los cinco consumidores de Caja y la integridad de los DFM.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Delphi continúa mostrando advertencias y sugerencias preexistentes fuera de
este cambio.

## Compatibilidad con el diseñador

No se ha modificado ningún DFM.

- Se conservan los 253 enlaces persistentes
  `Connection = dmConn.conUni` de 52 DFM.
- `UniDataConn.dfm` conserva `UniSQLMonitor1`.
- El evento persistente `OnSQL = UniSQLMonitor1SQL` permanece conectado.
- La variable de diseño `dmConn` continúa existiendo en `UniDataConn`.

## Prueba funcional recomendada

1. Activar y desactivar `appModoDebugSQL`.
2. Ejecutar varias consultas desde un mantenimiento.
3. Comprobar el memo SQL y el archivo de log.
4. Abrir los selectores de caja desde el menú y desde un informe.
5. Cerrar y reiniciar la sesión.

El siguiente candidato de refactorización es la conexión global `oConn`.
Conviene migrarla por familias de data modules para mantener cambios
revisables y reducir el riesgo transaccional.
