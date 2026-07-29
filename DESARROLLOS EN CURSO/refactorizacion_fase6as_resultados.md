# Fase 6AS — configuración de consulta de operaciones

Fecha: 29/07/2026. D4.9, novena tanda de métodos largos. Sin commit
manual. El workflow `Auto-update 2026-07-29 18:29:02` incorporó el
código y la guarda D4.9 mientras se ejecutaban las validaciones.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `TdmConsultaOpe.DataModuleCreate` | 333 | 8 | **-325** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `UniDataConsultaOpe` completa | 744 | 735 | **-9** |

D4.9 reduce complejidad y volumen. El evento queda como coordinador de
cinco operaciones privadas, todas con consumidor y ninguna por encima
de 86 líneas. No se crean constantes ni unidades auxiliares de un solo
uso.

## Implementación

`DataModuleCreate` mantiene el orden original y delega en:

1. `ConectarConsultas`;
2. `ConfigurarConsultaMaestro`;
3. `ConfigurarConsultasCaja`;
4. `ConfigurarConsultasMovimientoCliente`;
5. `ConfigurarConsultasDepositoFactura`.

Se conservan las nueve `TUniQuery`, sus nueve `TDataSource`, la conexión
inyectada, todos los SQL y parámetros, la exclusión de simplificadas
sustituidas y el orden de configuración.

El DFM no cambia. `OnCreate` continúa apuntando a
`DataModuleCreate`, y el constructor sigue asignando `FConexion` antes
de `inherited Create(AOwner)`, que es quien carga el DFM y dispara el
evento.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.9:

- `DataModuleCreate` no puede superar 100 líneas;
- los cinco colaboradores deben existir una sola vez;
- cada colaborador debe tener consumidor;
- ninguno puede superar 100 líneas;
- se protege el orden de conexión y configuración;
- se protege la inyección anterior a `OnCreate`;
- se conservan las nueve fuentes SQL y la exclusión fiscal;
- el DFM debe conservar `OnCreate = DataModuleCreate`;
- el límite global baja de 42 a 41 métodos mayores de 200 líneas.

Resultado: fachada de 8 líneas, colaborador máximo de 86 y 41 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La aplicación se reconstruyó con Delphi 37 en Release/Win64 y
Release/Win32 dentro de `build/validacion_d49`. Ambas plataformas
enlazaron `UniDataConsultaOpe` sin errores.

La matriz DUnitX se recompiló en salida aislada:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 222/223 | 0 | 1 |
| Debug / Win32 | 0 errores | 222/223 | 0 | 1 |
| Release / Win64 | 0 errores | 222/223 | 0 | 1 |
| Release / Win32 | 0 errores | 222/223 | 0 | 1 |

La única roja sigue siendo ajena a D4.9:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

La batería general no enlaza `UniDataConsultaOpe`; la validación
automática específica la cubren la compilación de la aplicación y las
guardas estructurales de Pascal, SQL y DFM.

La antigua batería de conexión global XI-D queda roja en ocho
comprobaciones globales por el desarrollo paralelo actual: otros
constructores, llamantes y auxiliares, dependencias huérfanas, recuento
de enlaces DFM, DFM modificados y dump modelo modificado. Sus
comprobaciones específicas de ausencia de `oConn`, raíz de composición,
transacciones y barrera de librerías sí pasan. D4.9 no modifica esos
archivos.

También pasan:

- el comprobador de flujos largos;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- `git diff --check` limitado al alcance;
- el DFM de `TdmConsultaOpe` permanece sin cambios.

El comprobador global de dependencias queda rojo por dos aristas del
desarrollo paralelo del usuario:
`inLibCajaOpeComposicion -> inMtoCajaImpresorVenta` y
`inLibCajaOpeComposicion -> inMtoCajaGrabadorVenta`.
D4.9 no modifica ningún `uses` ni añade dependencias.

El workflow automático incorporó en su commit la modificación paralela
de `factuzam_original.sql` (+95/-6). D4.9 no lo ha tocado ni revertido.

## Validación funcional pendiente

Con una BBDD de pruebas:

1. Abrir F10 desde consulta y desde el histórico de operaciones.
2. Cargar el maestro por fecha, empresa, almacén y caja.
3. Probar búsqueda por operación, factura, cliente, concepto, artículo
   y SKU.
4. Seleccionar una operación con varias filas y validar la pestaña de
   operación.
5. Validar pagos y vales emitidos/redimidos.
6. Validar movimientos con color y talla, y la ficha del cliente.
7. Validar depósitos agrupados y sus distintos roles.
8. Validar factura por serie/número y por el fallback de operación.
9. Cambiar de fila repetidamente y comprobar cachés y cierre de pestañas.

El siguiente fascículo es **D4.10**:
`TModoEntradaTallas.Desmontar`, actualmente con 332 líneas.
