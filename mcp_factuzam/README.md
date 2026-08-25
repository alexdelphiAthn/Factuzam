# MCP de Factuzam

Servidor MCP local para consultar stock, obtener el informe oficial de
movimientos de venta y preparar una venta. La creación definitiva de una venta
solo puede delegarse en un puente externo que ejecute el dominio Delphi de
Factuzam de forma transaccional e idempotente.

El paquete Python no inserta ni modifica directamente tablas de Factuzam. En
particular, no intenta reconstruir una venta con `INSERT`: hacerlo omitiría
validaciones, numeración, movimientos de stock, impuestos, pagos, fiscalidad,
Verifactu y rollback que ya coordina la aplicación.

La revisión del MCP anterior y la razón de este rediseño están en
[`REVISION.md`](REVISION.md).

## Estado y límites

- Transporte previsto: `stdio`, adecuado para una integración local con
  Codex.
- SDK: MCP Python v2, fijado como `mcp>=2,<3`.
- Lecturas: conexión MariaDB exclusiva de solo lectura, con `SELECT` y
  `EXECUTE` sobre la base necesaria.
- Autorización: scopes y allowlists estáticos del proceso; vacío significa
  denegar.
- Ventas: deshabilitadas salvo que
  `FACTUZAM_VENTAS_HABILITADAS=SI` y exista un puente Delphi externo válido.
- El puente Delphi no forma parte de este paquete y no se presupone instalado.

La referencia del SDK está en la
[documentación oficial de MCP Python](https://github.com/modelcontextprotocol/python-sdk),
y la sintaxis utilizada para Codex se puede contrastar en la
[referencia oficial de configuración de Codex](https://developers.openai.com/codex/config-reference/).

## Tools expuestos

| Tool | Efecto | Requisitos mínimos |
| --- | --- | --- |
| `estado_integracion_factuzam` | Muestra presencia de configuración, scopes y recuentos de allowlists sin revelar sus valores ni secretos. | Ninguno; no abre MariaDB ni contacta con el puente. |
| `consultar_stock` | Consulta existencias por artículo/SKU y almacén autorizado. | `stock:read`; almacén en allowlist. |
| `informe_movimientos_venta` | Ejecuta el informe nativo `PRC_GET_MOV_VENTAS_ART`, conservando sus reglas de anulaciones y sustituciones. | `ventas:read`; almacenes solicitados autorizados. |
| `preparar_venta` | Valida y normaliza una solicitud y exige un resumen revisable con cliente efectivo, líneas, desglose fiscal, cobros y totales; no crea la venta. | `ventas:create`; empresa, almacén y caja autorizados. |
| `crear_venta` | Envía una preparación confirmada al puente Delphi con clave de idempotencia. | Todo lo anterior, ventas habilitadas, puente configurado y aprobación explícita. |
| `consultar_estado_venta` | Consulta al puente el resultado de una clave de idempotencia. | `ventas:create`; mismos límites de empresa, almacén y caja. |

El scope adicional `caja.verCoste` permite devolver datos de coste cuando el
tool los soporte. No se deriva de `stock:read` ni de `ventas:read`.

Los esquemas completos de entrada se publican por MCP y se pueden inspeccionar
desde el cliente. Las fechas usan ISO `AAAA-MM-DD`; importes y cantidades deben
enviarse como valores decimales, no como texto localizado.

## Instalación en Windows

Desde PowerShell y sin activar el entorno virtual:

```powershell
Set-Location 'C:\DISCO_DURO\proyectos\Factuzam\mcp_factuzam'
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -e .
```

También funcionan versiones posteriores compatibles de Python. El requisito
mínimo declarado es Python 3.11.

## Cuenta MariaDB de lectura

Usa una cuenta distinta de la aplicación y de cualquier cuenta administrativa.
Debe estar limitada al host desde el que se ejecuta el MCP y tener únicamente:

- `SELECT` sobre los objetos que consultan stock y validaciones;
- `EXECUTE` sobre `PRC_GET_MOV_VENTAS_ART`;
- ninguna capacidad `INSERT`, `UPDATE`, `DELETE`, DDL, `FILE` o `GRANT`.

No uses `root`, una contraseña vacía ni la misma cuenta que emplearía el puente
de ventas. La escritura pertenece exclusivamente al proceso Delphi y sus
credenciales no se entregan al servidor Python.

## Configuración del entorno

Consulta [`.env.example`](.env.example) para ver todas las variables. Es una
plantilla documental: el servidor lee variables del proceso y no carga archivos
`.env` automáticamente.

Configuración mínima para consultas:

```powershell
$env:FACTUZAM_DB_HOST = '127.0.0.1'
$env:FACTUZAM_DB_PORT = '3306'
$env:FACTUZAM_DB_NAME = 'factuzam_demo'
$env:FACTUZAM_DB_USER = 'factuzam_mcp_ro'
$env:FACTUZAM_MCP_PRINCIPAL = 'codex-local'
$env:FACTUZAM_MCP_SCOPES = 'stock:read,ventas:read'
$env:FACTUZAM_MCP_TRANSPORTE = 'stdio'
$env:FACTUZAM_EMPRESAS_PERMITIDAS = 'EMP01'
$env:FACTUZAM_ALMACENES_PERMITIDOS = 'ALM01,ALM02'
$env:FACTUZAM_CAJAS_PERMITIDAS = 'CAJA01'
```

Define una única fuente para la clave: `FACTUZAM_DB_PASSWORD` mediante el
mecanismo de arranque, o `FACTUZAM_DB_CREDENTIAL_TARGET` con el nombre de una
credencial genérica del Administrador de credenciales de Windows. La segunda
opción evita guardar el secreto en TOML. Evita `setx` para contraseñas y no
pongas la clave o el token del puente en archivos versionados ni argumentos de
línea de comandos.

Las listas usan códigos separados por comas, sin comodines. Las herramientas de
venta exigen que empresa, almacén y caja estén presentes en sus tres allowlists;
no basta con omitir una lista.

Si MariaDB no está en loopback, configura `FACTUZAM_DB_SSL_CA` con la ruta a la
CA que valida su certificado. Los timeouts `FACTUZAM_DB_CONNECT_TIMEOUT`,
`FACTUZAM_DB_READ_TIMEOUT` y `FACTUZAM_DB_WRITE_TIMEOUT` se expresan en
segundos. Los límites de rango y resultado se controlan con
`FACTUZAM_MCP_MAX_REPORT_DAYS`, `FACTUZAM_MCP_MAX_STOCK_PAGE_SIZE` y
`FACTUZAM_MCP_MAX_REPORT_ROWS`; no los eleves sin medir el coste de las
consultas sobre una copia representativa.

`FACTUZAM_MCP_MAX_STOCK_OFFSET` limita paginaciones profundas y
`FACTUZAM_MCP_MAX_PURCHASE_LOOKBACK_DAYS` acota la antigüedad de
`inicio_compras`; ambos evitan recorridos accidentales desproporcionados.

## Ejecución local por stdio

Para una prueba manual, el proceso queda esperando mensajes MCP por la entrada
estándar:

```powershell
.\.venv\Scripts\factuzam-mcp.exe
```

No escribas diagnósticos en `stdout` desde el servidor porque corromperían el
protocolo; los logs deben salir por `stderr`. Interrumpe la prueba con
`Ctrl+C`.

## Conexión con Codex

1. Instala el paquete en `.venv`.
2. Haz que las variables necesarias existan en el entorno del proceso que abre
   Codex.
3. Copia la tabla de [`.codex.config.example.toml`](.codex.config.example.toml)
   a una de estas ubicaciones y sustituye sus rutas:

   - proyecto: `<raíz Factuzam>\.codex\config.toml`;
   - usuario: `%USERPROFILE%\.codex\config.toml`.

4. Reinicia Codex para que el servidor herede el entorno y se vuelva a
   descubrir.

La opción `env_vars` contiene nombres, no valores: permite reenviar el entorno
local sin guardar secretos en TOML. `default_tools_approval_mode = "writes"`
deja las consultas sin fricción y solicita aprobación para escrituras;
`crear_venta` además lleva una regla explícita `prompt`.

Si inicialmente solo quieres lectura, elimina `preparar_venta`, `crear_venta` y
`consultar_estado_venta` de `enabled_tools` y no concedas `ventas:create`.

## Flujo seguro de venta

La venta se separa deliberadamente en dos pasos:

1. `preparar_venta` valida principal, scope, empresa, almacén, caja, cliente,
   líneas, cantidades y códigos. Devuelve contexto, líneas, cobros y totales
   recalculados para revisión, pero no registra una venta.
2. El operador revisa la preparación y autoriza `crear_venta`. La petición debe
   llevar confirmación explícita y una clave de idempotencia estable.
3. `crear_venta` solo continúa si las ventas están habilitadas y el puente está
   configurado. El puente debe usar la unidad de trabajo Delphi de Factuzam.
4. Un timeout no autoriza a reintentar con una clave nueva. Se consulta
   `consultar_estado_venta` con la misma clave para evitar una venta duplicada.
   Esta recuperación sigue disponible aunque después se cambie
   `FACTUZAM_VENTAS_HABILITADAS` a `NO`.

Para habilitar este flujo se necesitan, como mínimo:

```text
FACTUZAM_MCP_SCOPES=ventas:create
FACTUZAM_VENTAS_HABILITADAS=SI
FACTUZAM_VENTAS_BRIDGE_URL=<HTTPS o loopback>
FACTUZAM_VENTAS_BRIDGE_TOKEN=<secreto>
```

Además deben existir `FACTUZAM_MCP_PRINCIPAL` y las allowlists de empresa,
almacén y caja. El bridge debe rechazar por sí mismo cualquier principal,
ámbito o clave fuera de contrato; no debe confiar únicamente en la validación
del MCP.

## Contrato exigido al puente Delphi

Este repositorio no implementa ni instala el puente. Antes de habilitar ventas,
el servicio externo debe cumplir estos invariantes:

- invocar el caso de uso nativo de caja, representado por
  `TSolicitudGrabacionVenta` e `IUnidadTrabajoVentaCaja`;
- ejecutar toda la operación en una transacción y hacer rollback completo ante
  un error;
- aplicar autorización por principal, empresa, almacén y caja;
- tratar la clave de idempotencia como única y devolver siempre el mismo
  resultado terminal para la misma solicitud;
- rechazar la reutilización de una clave con contenido diferente;
- registrar auditoría sin contraseñas, tokens ni datos de pago sensibles;
- ofrecer consulta de estado para resolver timeouts sin repetir la operación;
- limitar tamaño de respuesta y tiempo de espera según las variables del MCP.

El MCP valida el esquema y el destino, pero esa validación no reemplaza las
reglas de negocio del proceso Delphi.

El cliente incluido espera este contrato HTTP mínimo:

| Método y ruta | Uso |
| --- | --- |
| `POST /v1/ventas/preparaciones` | Recibe empresa, almacén, caja, cliente opcional, tipo de documento, serie, tarifa, líneas y cobros; devuelve `preparacion_id`, `caduca_en` ISO-8601 con zona y un `resumen` completo según `CONTRATO_PUENTE_VENTAS.md`. |
| `POST /v1/ventas` | Confirma `preparacion_id` con `confirmar: true`; la misma clave viaja en cuerpo y cabecera `Idempotency-Key`. Devuelve un `estado` del contrato. |
| `GET /v1/ventas/estado/{idempotency_key}` | Devuelve `DESCONOCIDA`, `PENDIENTE`, `CONFIRMADA` o `FALLIDA`. Si está confirmada incluye `documento` con empresa, serie y número. |

Todas las llamadas llevan `Authorization: Bearer …`,
`X-Factuzam-Principal` y `Accept: application/json`. Solo se admite HTTP en
loopback; para cualquier otro host la URL debe usar HTTPS. El token y el
principal no deben contener caracteres de control, y la respuesta queda
limitada a un objeto JSON UTF-8 de hasta 1 MiB. El cliente no usa proxies del
entorno y rechaza cualquier redirección. Después de enviar una confirmación,
un timeout, HTTP 408/425/429 o 5xx, una respuesta inválida/incompleta o un fallo
de cierre se presenta como resultado indeterminado: se debe consultar el estado
con la misma clave, nunca crear otra.

## Pruebas

Las pruebas usan `unittest` de la biblioteca estándar y no necesitan una base
de datos real:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -p 'test_*.py' -v
```

Para comprobar también que el paquete se importa y que el entry point existe:

```powershell
.\.venv\Scripts\python.exe -c "from factuzam_mcp.server import main; print(main.__name__)"
.\.venv\Scripts\python.exe -m pip check
```

Una validación contra una instalación real debe usar una base no productiva y
credenciales de solo lectura. No habilites `crear_venta` en una prueba de
integración hasta disponer de un puente Delphi con pruebas de rollback e
idempotencia.

## Referencias dentro de Factuzam

El informe y la venta no se han deducido solo de las tablas. Sus contratos
nativos están en:

- `src/Lib/inLibInformeMovimientosVentasArticuloPersistenciaIntf.pas`;
- `src/DataModules/UniDataInformeMovimientosVentasArticuloRepositorio.pas`;
- `src/Lib/inLibMovVentasArtExcel.pas`;
- `factuzam_demo.sql`, procedimiento `PRC_GET_MOV_VENTAS_ART`;
- `src/Caja/Lib/inLibCajaVentaIntf.pas`;
- `src/Caja/DataModules/UniDataCajaUnidadTrabajo.pas`;
- `src/Caja/DataModules/UniDataCaja.pas`;
- `src/Caja/Lib/inLibCajaOpeComposicion.pas`.

## Diagnóstico rápido

- **No aparecen tools:** comprueba rutas absolutas en TOML, reinicia Codex y
  ejecuta manualmente `factuzam-mcp.exe` con el mismo usuario.
- **Acceso denegado:** revisa el scope y la allowlist correspondiente. Vacío es
  denegación, no acceso global.
- **Falla el informe:** verifica permiso `EXECUTE` y que
  `PRC_GET_MOV_VENTAS_ART` exista en la base seleccionada.
- **No se crea la venta:** es el comportamiento esperado mientras las ventas
  estén deshabilitadas o no exista puente. No concedas permisos de escritura a
  MariaDB como atajo.
- **Timeout al crear:** consulta el estado con la misma clave de idempotencia;
  no prepares una segunda venta hasta conocer el resultado.
