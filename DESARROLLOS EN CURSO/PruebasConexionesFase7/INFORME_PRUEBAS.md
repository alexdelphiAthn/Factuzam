# Informe de pruebas: conexiones, fase VII

Fecha: 24/07/2026

## Resultado

`TdmBase` recibe ahora `IServicioConexiones` mediante inyección y lo publica a
sus descendientes. La primera familia de data modules ha dejado de acceder a
la conexión global `oConn`.

Se han migrado nueve unidades:

- `UniDataGen`;
- `UniDataAlmacenes`;
- `UniDataAtributosBasicos`;
- `UniDataGenFilter`;
- `UniDataPropiedadesValores`;
- `UniDataGrupos`;
- `UniDataIvasGrupos`;
- `UniDataIvas`;
- `UniDataTarifas`.

## Estructura incorporada

`TdmBase` implementa `IProveedorConexiones` y conserva el servicio mediante
`IServicioConexiones`.

Durante su construcción:

1. intenta heredar el servicio del formulario propietario;
2. si el propietario no lo publica, consulta `Application.MainForm`;
3. después carga el DFM y ejecuta el evento `DataModuleCreate`.

Los descendientes disponen de:

- `Conexiones`;
- `ConexionPrincipal`;
- `CrearConexionTrabajo`.

Si falta el servicio durante la ejecución se genera un error explícito. En
modo diseño se mantiene la conexión persistente del DFM y no se exige que
exista el formulario principal de la aplicación.

## Cambios en los data modules

Las conexiones asignadas manualmente a queries y stored procedures utilizan
ahora `ConexionPrincipal`.

También se han retirado las dependencias a `UniDataConn` e
`inLibGlobalVar` cuando únicamente se utilizaban para obtener `oConn`.

Las consultas que ya se abrían en `DataModuleCreate` continúan utilizando la
conexión principal compartida. Las consultas cerradas pueden reasignarse
posteriormente a la conexión propia del mantenimiento mediante
`ReasignarConexion`, conservando el comportamiento anterior.

## Reducción de acoplamiento

| Medida | Antes | Después | Reducción |
| --- | ---: | ---: | ---: |
| Referencias a `oConn` | 976 | 957 | 19 |
| Unidades con `oConn` | 124 | 115 | 9 |

Ninguna de las nueve unidades migradas contiene ya referencias a `oConn`.

## Pruebas estructurales

Script:
`PruebasConexionesFase7.ps1`

Resultado: **16 pruebas ejecutadas, 16 correctas y 0 fallos**.

Las comprobaciones cubren:

- implementación de `IProveedorConexiones`;
- orden de la inyección antes de cargar el DFM;
- herencia desde propietario y formulario principal;
- publicación de la conexión principal;
- creación de conexiones de trabajo;
- migración de queries base y perfiles;
- ausencia de `oConn` y `UniDataConn` en la familia;
- reducción global de referencias;
- conexiones persistentes del diseñador;
- integridad de los DFM del alcance;
- integridad de `factuzam_original.sql`.

## Pruebas del contrato

Se ha recompilado y ejecutado de nuevo
`PruebasConexionesFase1.dpr`.

Resultado: **6 pruebas ejecutadas, 6 correctas y 0 fallos**.

El ejecutable y los DCU temporales se eliminaron después de las pruebas.

## Compilación

| Configuración | Resultado |
| --- | --- |
| Debug Win64 | Correcto, 0 errores |
| Release Win32 | Correcto, 0 errores |
| Release Win64 | Correcto, 0 errores |

Delphi continúa mostrando advertencias y sugerencias preexistentes fuera de
este cambio.

## Compatibilidad con el diseñador

Se conservan los 253 enlaces persistentes
`Connection = dmConn.conUni` distribuidos en 52 DFM.

No se ha modificado ninguno de los nueve DFM correspondientes a esta fase.

El árbol de trabajo contiene cambios ajenos a esta fase en
`UniDataComprasSesiones.dfm` e `inMtoComprasSesiones.dfm`. Se han conservado
sin intervenir y no afectan a las comprobaciones de los data modules
migrados.

## Prueba funcional recomendada

1. Abrir desde el diseñador Almacenes, Atributos básicos, Grupos, IVAs y
   Tarifas, comprobando que los grids pueden mostrar datos.
2. Iniciar la aplicación y abrir esos mantenimientos.
3. Abrir simultáneamente dos instancias de un mantenimiento.
4. Insertar y editar un registro.
5. Abrir el filtro genérico y comprobar la consulta de empresas.

La siguiente tanda de conexiones puede abordar Formas de pago, Usuarios,
Variaciones, Familias y los data modules de efectos antes de entrar en
Facturas, Pedidos y Devoluciones.
