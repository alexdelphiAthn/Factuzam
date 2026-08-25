# Revisión del MCP histórico de Factuzam

## Localización

El MCP no estaba en el árbol actual de Factuzam. La revisión encontró tres
referencias concordantes:

- versión completa en el commit Git `551ee40f`, bajo
  `DESARROLLOS EN CURSO/mcp/`;
- eliminación de ese directorio en el commit `92e47f41`;
- copia archivada en
  `C:\DISCO_DURO\proyectos\factuzam_web\DESARROLLOS EN CURSO\manual programador\archivo_historico\DESARROLLOS_EN_CURSO\mcp\`.

La copia archivada y la versión del commit completo contienen el mismo servidor
de referencia. Se estudiaron como material histórico; no se reactivaron ni se
editaron dentro del archivo.

Comandos de comprobación:

```powershell
git show '551ee40f:DESARROLLOS EN CURSO/mcp/servidor_mcp.py'
git show --stat 92e47f41
```

## Capacidades antiguas

El servidor histórico ofrecía ocho tools:

1. `buscar_clientes`;
2. `buscar_facturas`;
3. `ventas_por_fecha`;
4. `ventas_agrupadas`;
5. `comparar_ventas`;
6. `stock_articulos`;
7. `deuda_clientes`;
8. `factura_pdf`.

Era esencialmente un servidor de consulta. No existía una operación segura para
registrar una venta y tampoco un adaptador al caso de uso Delphi.

## Hallazgos

### Críticos

1. **Incompatibilidad de dependencia.** El código usaba la API v1
   `mcp.server.fastmcp.FastMCP`, pero declaraba `mcp>=1.8` sin límite superior.
   Una instalación actual puede resolver MCP v2, donde esa API cambió, y fallar
   al importar. El paquete nuevo fija `mcp>=2,<3` y usa el entry point v2.

2. **Credenciales inseguras por defecto.** La conexión histórica aceptaba
   `root` sin contraseña. Esto convertía una herramienta de lectura en un
   proceso con capacidad administrativa sobre la base.

3. **Autenticación HTTP opcional.** El token era optativo y único, sin scopes,
   principal, empresa, almacén o caja. Así podían exponerse clientes, deuda,
   costes y ventas fuera del ámbito de un operador.

4. **Semántica incorrecta de ventas anuladas.** Las consultas reproducían una
   parte de la lógica con un filtro de fase demasiado simple. No cubrían todos
   los estados anulados (`SIN_VERIF_ANULADA`, `VERIFACTU_ANULADA` y
   `NOVERIFACTU_ANULADA`), eventos de anulación Verifactu ni facturas
   simplificadas sustituidas por rectificativas. El contrato válido ya está
   centralizado en `PRC_GET_MOV_VENTAS_ART`.

5. **No era válido añadir una venta con SQL directo.** Una venta de Factuzam no
   es solo cabecera y líneas: intervienen validaciones, serie y numeración,
   impuestos, stock, totales, registro fiscal, formas de pago, vales y rollback.
   Implementar `INSERT` desde Python produciría estados parciales o fiscalmente
   incoherentes.

### Altos

6. **Efecto lateral de PDF.** `factura_pdf` escribía una ruta en el sistema de
   archivos del servidor. La salida no estaba modelada como recurso/contenido y
   la ruta podía ser distinta de la máquina cliente.

7. **Sin pruebas automatizadas.** No había tests de protocolo, validación,
   autorización, consultas, límites, anulaciones, idempotencia o rollback.

8. **Límites y tipos insuficientes.** Fechas y rangos se validaban de forma
   limitada, algunas listas podían crecer sin paginación y los importes
   `Decimal` se transformaban a coma flotante, perdiendo exactitud potencial.

9. **Sin separación lectura/escritura.** Aunque el README describía consultas,
   las credenciales concedidas al proceso podían permitir mucho más. Una futura
   tool de venta habría compartido el mismo contexto privilegiado.

## Contratos nativos comprobados

### Informe de movimientos de venta

El contrato está definido por
`TCriteriosInformeMovimientosVentasArticulo` en
`src/Lib/inLibInformeMovimientosVentasArticuloPersistenciaIntf.pas` y su
adaptador UniDAC en
`src/DataModules/UniDataInformeMovimientosVentasArticuloRepositorio.pas`.

El adaptador llama al procedimiento `PRC_GET_MOV_VENTAS_ART`, incluido en
`factuzam_demo.sql`, con:

- fechas de inicio, fin e inicio de compras;
- almacenes, familias, proveedores, temporadas y artículos;
- tres niveles de agrupación;
- nivel de familia;
- opción de limitar a ventas.

El resultado contiene unidades e importes de entrada y venta, coste, beneficio,
márgenes, rotación/sell-through y códigos de agrupación. La exportación Excel de
`src/Lib/inLibMovVentasArtExcel.pas` confirma el significado de las columnas.

Por tanto, el nuevo `informe_movimientos_venta` envuelve el procedimiento
nativo en vez de duplicar sus reglas con una consulta alternativa.

### Grabación de una venta

El contrato de dominio se encuentra en
`src/Caja/Lib/inLibCajaVentaIntf.pas` mediante
`TSolicitudGrabacionVenta` e `IUnidadTrabajoVentaCaja`. La orquestación de
`TGrabacionFacturaCaja.Ejecutar`, en `src/Caja/DataModules/UniDataCaja.pas`,
valida el contexto, inicia la transacción, procesa líneas y stock, recalcula,
registra fiscalmente, registra pagos y confirma o revierte la transacción.

`src/Caja/DataModules/UniDataCajaUnidadTrabajo.pas` y
`src/Caja/Lib/inLibCajaOpeComposicion.pas` muestran la adaptación y composición
actuales. Parte de esa composición sigue vinculada a la aplicación VCL. No se ha
encontrado un servicio headless listo para invocar desde Python.

Conclusión: `crear_venta` solo puede ser un cliente de un futuro puente Delphi
estrecho, autenticado, transaccional e idempotente. Este paquete no afirma que
ese puente exista y nunca sustituye su ausencia con escritura SQL.

## Decisiones del servidor nuevo

| Área | Decisión |
| --- | --- |
| Ubicación | Paquete mantenido `mcp_factuzam/`, separado del archivo histórico. |
| SDK | MCP Python v2, `mcp>=2,<3`. |
| Transporte | `stdio` local como configuración base. |
| Base de datos | Usuario MariaDB de solo lectura; `SELECT` y `EXECUTE` mínimos. |
| Autorización | `FACTUZAM_MCP_PRINCIPAL`, scopes deny-by-default y allowlists de empresa/almacén/caja. |
| Stock | `consultar_stock`; almacén obligatorio y autorizado. Costes condicionados a `caja.verCoste`. |
| Informe | `informe_movimientos_venta` sobre `PRC_GET_MOV_VENTAS_ART`. |
| Venta | Flujo `preparar_venta` → aprobación → `crear_venta`; deshabilitado por defecto. |
| Escritura | Solo puente Delphi externo; nunca SQL de escritura desde Python. |
| Reintentos | Clave de idempotencia y `consultar_estado_venta`. |
| Codex | Secretos heredados mediante `env_vars`; aprobación requerida para `crear_venta`. |
| Pruebas | `unittest` para validación, autorización, SQL parametrizado y cliente del puente simulado. |

## Modelo de permisos

Scopes reconocidos:

- `stock:read`: consulta de existencias;
- `ventas:read`: informe de movimientos;
- `ventas:create`: preparación, creación y consulta del estado de una venta;
- `caja.verCoste`: exposición explícita de coste cuando corresponda.

No hay scopes implícitos y una lista vacía no equivale a administrador. Las
herramientas de venta exigen simultáneamente empresa, almacén y caja en las
allowlists. El puente debe repetir estas comprobaciones en su propio límite de
confianza.

## Riesgo residual y trabajo pendiente

La consulta de stock y el informe pueden verificarse con un usuario de lectura.
La creación de ventas permanece correctamente cerrada hasta desarrollar y
desplegar el puente Delphi. Ese trabajo debe incluir, antes de producción:

1. composición headless de las dependencias de caja sin UI VCL;
2. autenticación mutua o token rotatorio y TLS/loopback;
3. almacenamiento duradero de idempotencia y estados;
4. pruebas de concurrencia, timeout, reintento y claves reutilizadas;
5. pruebas de rollback en cada fase de grabación;
6. validación fiscal y Verifactu en una base no productiva;
7. auditoría con correlación entre principal, clave y documento creado;
8. revisión de permisos de empresa, almacén, caja y visualización de costes.

Hasta completar ese puente, la respuesta segura de `crear_venta` es una
denegación controlada. Conceder escritura al usuario MariaDB del MCP no resuelve
este pendiente y está expresamente fuera del diseño.
