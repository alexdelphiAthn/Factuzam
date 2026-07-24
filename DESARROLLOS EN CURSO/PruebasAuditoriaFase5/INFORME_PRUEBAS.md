# Informe de pruebas: auditoría de datos, fase V

Fecha: 24/07/2026

## Resultado

La auditoría estándar de los datasets ha dejado de ser responsabilidad de
`TdmConn`.

Se han migrado 19 puntos de uso distribuidos entre diez unidades. Ninguno
accede ya a `odmConn` para completar `USUARIO_ALTA`, `USUARIO_MODIF`,
`INSTANTE_ALTA` o `INSTANTE_MODIF`.

## Estructura incorporada

- `IServicioAuditoriaDatos` define la operación de auditoría.
- `IProveedorAuditoriaDatos` permite publicar el servicio sin conocer su
  implementación.
- `TServicioAuditoriaDatos` recibe el usuario autenticado por constructor y
  no lee variables globales.
- `TfrmBase` publica el servicio a todos sus formularios descendientes.
- `TdmBase` lo hereda de su formulario propietario o del formulario principal.
- `TdmPerfiles`, que no desciende de `TdmBase`, aplica el mismo contrato.
- `TfrmMtoPrincipal` compone el servicio después de establecer la conexión y
  lo invalida durante el cierre.

Si el servicio falta durante la ejecución, las clases base generan un error
explícito. En modo diseño omiten la auditoría para no impedir el uso de los
data modules y grids persistentes.

## Compatibilidad funcional

La implementación conserva exactamente el comportamiento anterior:

| Estado del dataset | Campos modificados |
| --- | --- |
| Inserción | `USUARIO_MODIF`, `USUARIO_ALTA`, `INSTANTE_ALTA` e `INSTANTE_MODIF` |
| Edición | Solo `USUARIO_MODIF` |
| Consulta | Ninguno |
| Dataset nulo | Ninguno |

Los campos continúan siendo opcionales: el servicio solo escribe los que
existen en el dataset.

`INSTANTE_MODIF` no se actualiza al editar porque el método anterior tampoco
lo hacía. Cambiar esa regla debe tratarse como una decisión funcional
independiente.

## Reducción de acoplamiento

- `TdmConn` ya no contiene `ActualizarUserTimeModif`.
- Se han eliminado seis dependencias directas a la unidad `UniDataConn`.
- No quedan llamadas a `ActualizarUserTimeModif` dentro de `src`.
- `odmConn` permanece en ocho unidades y veinte líneas, limitado al ciclo de
  vida de la instancia y al monitor SQL.

El siguiente corte natural es extraer el monitor SQL tras una interfaz para
eliminar también esos accesos restantes a `odmConn`.

## Pruebas del servicio

Proyecto:
`PruebasAuditoriaFase5.dpr`

Resultado actualizado tras la Fase VIII:
**13 pruebas ejecutadas, 13 correctas y 0 fallos**.

Se han probado:

- dataset nulo;
- alta y los cuatro campos de auditoría;
- edición y conservación de los tres campos que no modificaba el código
  anterior;
- ausencia de campos de auditoría;
- dataset en estado de consulta;
- lectura del usuario inicial desde el contexto de sesión;
- actualización del usuario auditado al cambiar la identidad del contexto.

El ejecutable y los DCU temporales se eliminaron después de ejecutar las
pruebas.

## Pruebas estructurales

Script:
`PruebasAuditoriaFase5.ps1`

Resultado: **12 pruebas ejecutadas, 12 correctas y 0 fallos**.

Las comprobaciones cubren los contratos, la ausencia de variables globales en
la implementación, la composición desde la ventana principal, la retirada
del método antiguo, el alcance residual de `odmConn` y la integridad de los
DFM.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Delphi continúa mostrando advertencias y sugerencias preexistentes fuera de
este cambio.

## Compatibilidad con el diseñador

No se ha modificado ningún DFM. Se conservan los 253 enlaces persistentes
`Connection = dmConn.conUni` distribuidos en 52 DFM.

## Prueba funcional recomendada

1. Abrir un mantenimiento con grid desde el diseñador y comprobar que muestra
   datos con `dmConn.conUni`.
2. Iniciar la aplicación con un usuario real.
3. Insertar y editar registros en Artículos, Empresas y Atributos.
4. Verificar los campos de auditoría después de cada operación.
5. Grabar y recuperar un perfil de grid.

Esta prueba cubre las dos rutas de propagación: formularios descendientes de
`TfrmBase` y data modules descendientes de `TdmBase`.
