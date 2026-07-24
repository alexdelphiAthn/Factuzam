# Informe de pruebas: conexiones, fase II

Fecha: 24/07/2026

## Resultado

Los mantenimientos genéricos y las precargas del formulario principal ya
solicitan sus conexiones de trabajo mediante `IServicioConexiones`.

Se han retirado las implementaciones duplicadas
`TfrmMtoGen.CrearConexionPropia` y
`TfrmMtoPrincipal.CrearConexionPrecarga`.

## Rutas migradas

| Consumidor | Uso solicitado | Propietario |
| --- | --- | --- |
| `TfrmMtoGen` | `uctMantenimiento` | El propio formulario |
| Precargas de `TfrmMtoPrincipal` | `uctPrecarga` | Sin propietario |

`TfrmMtoGen` conserva la conexión persistente `dmConn.conUni` como respaldo.
La conexión creada por el servicio se inyecta en los componentes del
`DataModule` antes de abrir la tabla principal.

## Pruebas automatizadas

Proyecto:
`DESARROLLOS EN CURSO/PruebasConexionesFase1/PruebasConexionesFase1.dpr`

Resultado: **6 pruebas ejecutadas, 6 correctas y 0 fallos**.

| Escenario | Resultado |
| --- | --- |
| Servicio sin conexión principal | Correcto |
| Estado no disponible sin conexión | Correcto |
| Rechazo de conexiones de trabajo sin principal | Correcto |
| Publicación de la conexión persistente recibida | Correcto |
| Principal cerrada informada como no disponible | Correcto |
| Invalidación segura de la referencia no propietaria | Correcto |

Estas pruebas no abren una conexión real contra MariaDB. La integración de
las unidades y los tipos UniDAC se valida mediante la compilación completa.

## Comprobaciones estáticas

- No quedan referencias a `CrearConexionPropia` ni
  `CrearConexionPrecarga` en las dos rutas migradas.
- `TfrmMtoGen` solicita `uctMantenimiento`.
- `TfrmMtoPrincipal` solicita `uctPrecarga`.
- No se ha modificado ningún DFM.
- Permanecen 253 enlaces `Connection = dmConn.conUni` en 52 DFM.
- `TfrmMtoPrincipal` conserva `oConn` y `odmConn` como puente de
  compatibilidad.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Las advertencias y sugerencias mostradas por Delphi ya estaban presentes y
no corresponden a la fachada de conexiones ni a las dos rutas migradas.

La primera compilación incremental Win64 Debug encontró un DCU antiguo de
`inMtoFrmBase`. Una compilación completa regeneró el DCU y eliminó el error
E2003 sobre `AsignarConexiones`.

## Compatibilidad con el diseñador

Los `DataModule` continúan declarando `Connection = dmConn.conUni` en sus
DFM. Esto permite abrirlos y probar grids con datos en el diseñador. La
sustitución por la conexión de trabajo solo se realiza durante la ejecución.

## Pendiente para el siguiente corte

Las colas persistentes de Verifactu y ventas conservan por ahora sus
constructores de conexión propios. Se ejecutan en hilos de larga duración y
requieren inyectar el servicio al crear el hilo, detenerlo antes de invalidar
el servicio y evitar acceder a interfaces VCL desde el trabajador.
