# Informe de pruebas: perfiles de usuario mediante interfaz

## Alcance

La fase IX-B sustituye el acceso global a `odmPerfiles` por el contrato
`IPerfilesUsuario`.

Los cambios principales son:

- Nuevo contrato `IPerfilesUsuario` y proveedor
  `IProveedorPerfilesUsuario`.
- Las estructuras `TDictValue`, `TProfileDicc`, `TPerfilItem` y
  `TPerfilList` dejan de pertenecer al DataModule.
- `TdmPerfiles` implementa el contrato y concentra la consulta,
  persistencia y caché de perfiles.
- `TfrmPrincipal` crea la implementación y la publica como raíz de
  composición.
- `TfrmBase` y `TdmBase` heredan y propagan el servicio.
- `inLibUser` deja de ejecutar consultas y recibe el servicio
  explícitamente.
- Las utilidades de DevExpress, captions, layouts y validación reciben
  `IPerfilesUsuario` en vez de consultar una variable global.
- La consulta flotante de stock recibe el servicio explícitamente y lo
  desvincula antes de destruir el DataModule principal.
- Se retiran `Assign_Profile_Dict` y `AddRecordToDict`, ya sin
  consumidores.
- Se elimina la variable global `odmPerfiles`.

No se han modificado el esquema de la base de datos ni
`factuzam_original.sql`.

## Resultado de las pruebas

| Prueba | Plataforma | Configuración | Resultado |
| --- | --- | --- | --- |
| Contrato con implementación simulada | Win32 | Consola | 9/9 correctas |
| Comprobaciones estructurales | PowerShell | Repositorio | 20/20 correctas |
| Aplicación principal | Win64 | Debug | Compila, 0 errores |
| Aplicación principal | Win32 | Release | Compila, 0 errores |
| Aplicación principal | Win64 | Release | Compila, 0 errores |

Las compilaciones se realizaron con Delphi/RS37. Las salidas ejecutables
se dirigieron a carpetas temporales para no interferir con instancias o
binarios de trabajo.

Los avisos e indicaciones mostrados por el compilador pertenecen al
código existente y no impiden la compilación.

## Prueba del contrato

El ejecutable de prueba utiliza una implementación simulada de
`IPerfilesUsuario`, sin UniDAC ni conexión de base de datos. Se
comprobaron estos casos:

1. El proveedor publica el servicio mediante la interfaz.
2. La grabación individual atraviesa el contrato.
3. La estructura de lista permite grabar perfiles por lote.
4. La lectura de valores atraviesa el contrato.
5. La lectura de subclaves atraviesa el contrato.
6. Se devuelve el perfil del contexto actual.
7. Se puede solicitar un perfil para una identidad explícita.
8. Las órdenes de precarga, resincronización e invalidación se
   despachan mediante la interfaz.
9. La eliminación se despacha mediante la interfaz.

Resultado: 9 pruebas correctas y 0 fallos.

## Comprobaciones estructurales

El script `PruebasPerfilesFase9.ps1` valida:

- Existencia de los contratos del servicio y del proveedor.
- Ubicación de las estructuras de intercambio en el contrato.
- Implementación del contrato por `TdmPerfiles`.
- Retirada de la API antigua de diccionarios intermedios.
- Publicación y herencia desde `TfrmBase`.
- Propagación del servicio desde `TdmBase`.
- Composición y liberación ordenada desde `TfrmPrincipal`.
- Ausencia completa de referencias a `odmPerfiles`.
- Ausencia de perfiles en `inLibGlobalVar`.
- Ausencia de consultas UniDAC en `inLibUser`.
- Inyección explícita en layouts, utilidades y consulta de stock.
- Consumo del contrato desde el modal de impresión.
- Ausencia de imports concretos en los antiguos consumidores de
  estructuras.
- Conservación de los 253 enlaces persistentes a `dmConn.conUni`
  existentes en 52 DFM.
- En la Fase IX no hubo cambios en los DFM incluidos. La barrera admite
  después el cambio de raíz de `inMtoStockConsulta.dfm` exigido por la
  herencia visual de XI-B1.
- Integridad de `factuzam_original.sql`.

Resultado: 20 comprobaciones correctas y 0 fallos.

## Medida del desacoplamiento

Antes de la sustitución existían 58 referencias a `odmPerfiles`
repartidas entre 13 unidades. Después del cambio quedan 0 referencias.

La unidad concreta `UniDataPerfiles` solo se importa desde
`TfrmPrincipal`, además de existir como su propia implementación. Los
consumidores utilizan `IPerfilesUsuario`.

El cambio alcanza:

- Carga y guardado de perfiles de mantenimientos.
- Persistencia individual y por lotes.
- Perfiles de grids y captions.
- Restauración, guardado y reseteo de layouts.
- Caché de perfiles de formularios.
- Formatos de impresión.
- Preferencia de visualización de la consulta de stock.
- Configuración de símbolos prohibidos.

## Pruebas funcionales recomendadas

Las siguientes pruebas requieren una base de datos de la aplicación:

1. Arrancar con precarga de cachés en serie.
2. Arrancar con precarga de cachés en paralelo.
3. Abrir un mantenimiento y comprobar la restauración de su perfil.
4. Guardar y volver a cargar la configuración de un grid.
5. Guardar, restaurar y resetear un layout.
6. Guardar perfiles por lotes desde Artículos.
7. Repetir la grabación por lotes desde los históricos de Caja.
8. Abrir la gestión de formatos de impresión.
9. Marcar, cambiar y eliminar un formato predeterminado.
10. Crear, editar y borrar un formato de impresión.
11. Cambiar el modo de la consulta de stock y volver a abrirla.
12. Cerrar la aplicación dejando abierta la consulta de stock.
13. Validar campos que utilizan la configuración de símbolos
    prohibidos.
14. Repetir las operaciones para usuario, grupo y `Todos`.

No se ha ejecutado ninguna operación contra los datos del usuario
durante estas pruebas automatizadas.
