# Informe de pruebas: filtros guardados mediante interfaz

## Alcance

La fase IX-A sustituye el acceso global a `odmFiltros` por el contrato
`IFiltrosGuardados`.

Los cambios principales son:

- Nuevo contrato `IFiltrosGuardados` y proveedor
  `IProveedorFiltrosGuardados`.
- Intercambio de datos mediante `TFiltroGuardadoInfo`,
  `TFiltrosGuardadosList`, `TDestinoCompartidoInfo` y
  `TDestinosCompartidosList`.
- `TdmFiltros` implementa el contrato y conserva el acceso UniDAC.
- `TfrmPrincipal` crea la implementación y la publica en la raíz de
  formularios.
- `TfrmBase` permite asignar y heredar el servicio entre formularios.
- `TfrmMtoGen` consume únicamente la interfaz.
- `TfrmModalGestionFiltros` consume la interfaz y proyecta el listado en
  un `TClientDataSet` local para mantener el enlace con el grid.
- Se elimina la variable global `odmFiltros`.
- La consulta y el `TDataSource` internos de `TdmFiltros` dejan de formar
  parte de su API pública.

No se han modificado el esquema de la base de datos ni
`factuzam_original.sql`.

## Resultado de las pruebas

| Prueba | Plataforma | Configuración | Resultado |
| --- | --- | --- | --- |
| Contrato con implementación simulada | Win32 | Consola | 6/6 correctas |
| Comprobaciones estructurales | PowerShell | Repositorio | 17/17 correctas |
| Aplicación principal | Win64 | Debug | Compila, 0 errores |
| Aplicación principal | Win32 | Release | Compila, 0 errores |
| Aplicación principal | Win64 | Release | Compila, 0 errores |

Las compilaciones finales se realizaron con Delphi/RS37, que es la
versión de librerías configurada en `fzam.dproj`. Las compilaciones Win64
se dirigieron a carpetas temporales para no interferir con una posible
instancia de la aplicación.

Los avisos e indicaciones mostrados por el compilador pertenecen al
código existente. Entre ellos permanece la indicación H2077 en
`TdmFiltros.EsPropietario`; no impide la compilación.

## Prueba del contrato

El ejecutable de prueba usa una implementación simulada de
`IFiltrosGuardados`, sin UniDAC ni conexión de base de datos. Se
comprobaron estos casos:

1. El proveedor publica el servicio mediante la interfaz.
2. El contrato devuelve una lista de filtros.
3. El DTO conserva la identidad y la propiedad del filtro.
4. El contenido serializado atraviesa el contrato.
5. El DTO conserva los destinos compartidos.
6. Las órdenes se despachan a través de la interfaz.

Resultado: 6 pruebas correctas y 0 fallos.

## Comprobaciones estructurales

El script `PruebasFiltrosFase9.ps1` valida:

- Existencia de los contratos del servicio y del proveedor.
- Uso de DTO para cruzar la frontera del contrato.
- Implementación del contrato por `TdmFiltros`.
- Ausencia de la consulta de listado en la API pública.
- Publicación y herencia del servicio desde `TfrmBase`.
- Composición de la implementación en `TfrmPrincipal`.
- Liberación de la interfaz antes de destruir el `DataModule`.
- Ausencia completa de referencias a `odmFiltros`.
- Ausencia de dependencia de filtros en `inLibGlobalVar`.
- Dependencia de `TfrmMtoGen` respecto al contrato.
- Dataset local del modal para alimentar el grid.
- Ausencia de acceso concreto al `DataModule` desde el modal.
- Uso de conexión y contexto de sesión inyectados.
- Conservación de los 253 enlaces persistentes a
  `dmConn.conUni` existentes en 52 DFM.
- Ausencia de cambios en los DFM incluidos en esta fase.
- Integridad de `factuzam_original.sql`.

Resultado: 17 comprobaciones correctas y 0 fallos.

## Medida del desacoplamiento

Antes de la sustitución existían 42 referencias a `odmFiltros`
repartidas entre 4 unidades. Después del cambio quedan 0 referencias.

La unidad concreta `UniDataFiltros` queda limitada a:

- Su propia implementación.
- `TfrmPrincipal`, como raíz de composición.

Los consumidores funcionales ya no conocen `TdmFiltros`, sus consultas
ni sus componentes UniDAC.

## Pruebas funcionales recomendadas

Las siguientes pruebas requieren una base de datos de la aplicación y
deben ejecutarse manualmente:

1. Abrir un mantenimiento y guardar un filtro nuevo.
2. Abrir la lista de filtros y aplicar el filtro guardado.
3. Sobrescribir un filtro propio existente.
4. Abrir la gestión de filtros y comprobar el listado.
5. Renombrar, copiar y borrar un filtro propio.
6. Compartir y dejar de compartir con un usuario.
7. Compartir y dejar de compartir con un grupo.
8. Compartir y dejar de compartir con todos.
9. Comprobar que un usuario no propietario no puede modificar el filtro.
10. Repetir la gestión con un usuario administrador.

No se ha ejecutado ninguna operación contra los datos del usuario
durante estas pruebas automatizadas.
