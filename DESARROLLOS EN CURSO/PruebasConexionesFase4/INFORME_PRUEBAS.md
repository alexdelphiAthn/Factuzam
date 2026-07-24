# Informe de pruebas: conexiones, fase IV

Fecha: 24/07/2026

## Resultado

La capa base de mantenimientos ha dejado de acceder directamente a la
conexión global `oConn`.

El cambio afecta a `TfrmBase`, `TfrmMtoGen` y `TfrmMtoSearch`, por lo que
establece el punto de acceso que podrán utilizar progresivamente sus
formularios descendientes.

## Estructura incorporada

- `TfrmBase.ConexionPrincipal` publica la conexión principal recibida
  mediante `IServicioConexiones`.
- `TfrmBase` intenta heredar el servicio de su propietario inmediato.
- Si el propietario no lo publica, lo obtiene de `Application.MainForm`.
- `TfrmMtoGen.ConexionTrabajo` utiliza primero su conexión propia `FConn`.
- Si todavía no existe `FConn`, utiliza la conexión principal inyectada.
- Si ninguna está disponible, genera un error explícito.

La búsqueda rápida, la carga de perfiles, las transacciones de grabación y
las operaciones sobre guías utilizan ahora estos accesores.

## Reducción de acoplamiento

| Medida | Antes | Después |
| --- | ---: | ---: |
| Unidades Pascal con `oConn` | 126 | 124 |
| Referencias a `oConn` | 991 | 976 |

`inMtoGen.pas` e `inMtoGenSearch.pas` no contienen ya referencias a
`oConn`.

`TfrmMtoSearch` mantiene por ahora `odmConn.ActualizarUserTimeModif`
exclusivamente para completar los campos de auditoría. Esa responsabilidad
debe extraerse posteriormente a un servicio de auditoría y no forma parte
del servicio de conexiones.

## Pruebas automatizadas de Fase IV

Script:
`DESARROLLOS EN CURSO/PruebasConexionesFase4/`
`PruebasConexionesFase4.ps1`

Resultado: **11 pruebas ejecutadas, 11 correctas y 0 fallos**.

| Grupo | Comprobación |
| --- | --- |
| Publicación | `TfrmBase` expone la conexión principal |
| Propagación | Existe respaldo mediante `Application.MainForm` |
| Prioridad | `FConn` tiene prioridad sobre la principal |
| Desacoplamiento | Las dos bases de mantenimiento no leen `oConn` |
| Transacciones | La grabación usa `ConexionTrabajo` |
| Perfiles | La operación compartida usa `ConexionPrincipal` |
| Alta rápida | Usa una conexión inyectada |
| Diseñador | Permanecen 253 enlaces en 52 DFM |
| Integridad | No hay ningún DFM modificado |

## Pruebas del contrato

El proyecto de pruebas de la Fase I se ha recompilado y ejecutado después
de estos cambios.

Resultado: **6 pruebas ejecutadas, 6 correctas y 0 fallos**.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Delphi continúa mostrando advertencias y sugerencias preexistentes fuera
del cambio.

## Compatibilidad con el diseñador

No se ha modificado ningún DFM. Se conservan los 253 enlaces persistentes
`Connection = dmConn.conUni` distribuidos en 52 DFM.

## Prueba funcional recomendada

La comprobación manual debe abrir:

1. un mantenimiento normal desde el menú;
2. una segunda instancia del mismo mantenimiento;
3. una búsqueda o alta rápida modal;
4. la grabación y recuperación de un perfil de grid.

Esto permite confirmar tanto la conexión propia de cada pestaña como la
herencia del servicio en formularios cuyo propietario inmediato no sea la
ventana principal.
