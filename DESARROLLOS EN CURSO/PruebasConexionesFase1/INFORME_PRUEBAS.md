# Informe de pruebas: conexiones, fase I

Fecha: 24/07/2026

## Resultado

La fachada de conexiones queda incorporada sin cambiar el comportamiento
actual de acceso a datos.

## Alcance

- Contrato `IServicioConexiones`.
- Contrato `IProveedorConexiones`.
- Implementación `TServicioConexionesUniDAC`.
- Publicación del servicio desde `TfrmMtoPrincipal`.
- Propagación del servicio mediante `TfrmBase`.
- Conservación de `oConn` y `odmConn` como puente de compatibilidad.
- Conservación de `dmConn.conUni` en los DFM para trabajar con datos en el
  diseñador.

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

## Compilación

| Configuración | Resultado |
| --- | --- |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

## Compatibilidad con el diseñador

- No se ha modificado ningún DFM.
- Permanecen 253 enlaces `Connection = dmConn.conUni`.
- Los enlaces están distribuidos en 52 DFM.
- `TfrmMtoPrincipal` sigue asignando `oConn` y `odmConn`.

## Límite de esta fase

La aplicación todavía no solicita conexiones de trabajo a través del nuevo
servicio. Esa sustitución corresponde a la fase II. Por tanto, esta fase
introduce el contrato y el punto de composición sin alterar las rutas actuales.
