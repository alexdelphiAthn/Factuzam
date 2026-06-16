# TestPerformanceConn

Banco de pruebas **independiente** (proyecto Delphi suelto, sin relación
con la migración ni con la aplicación principal) para medir y comparar el
coste de los distintos modos de acceso del provider **SQL Server** de
UniDAC, eligiéndolos en un desplegable.

| Modo (combo)     | Transporte                   | COM            |
|------------------|------------------------------|----------------|
| `prDirect`       | Protocolo TDS sobre sockets  | NO necesita    |
| `prMSOLEDB`      | OLE DB nativo (MSOLEDBSQL)   | SÍ: CoInitialize / CoUninitialize |
| `prNativeClient` | SQL Server Native Client (SNAC) | SÍ          |
| `prSQL`          | OLE DB (SQLOLEDB, legacy)    | SÍ             |
| `prAuto`         | Lo decide UniDAC             | según resuelva |

El combo `Provider` es **editable**: puedes elegir uno de la lista o
teclear cualquier otro valor que admita tu versión de UniDAC. Solo hace
falta que el driver correspondiente esté instalado en la máquina; si no,
UniDAC lanza *"Required provider is not installed"*.

## Cómo se mide

Cada operación se cronometra con `TStopwatch` (`System.Diagnostics`) y se
muestra en milisegundos (con decimales) en la etiqueta superior y en el
registro inferior. Así se puede comparar, operación a operación y modo a
modo, el coste de unos frente a otros:

- **Conectar**: fija `SpecificOptions['Provider']` con el valor del combo
  y abre la conexión, cronometrando el `Open`. Decide COM según el modo:
  `prDirect` sin COM; cualquier otro (OLE DB) con `CoInitialize`.
- **Lanzar SQL**: ejecuta el texto del memo. Si empieza por `SELECT`
  abre el cursor y recorre todo el resultset (para medir el proceso
  completo, no solo la ida); en otro caso usa `ExecSQL`.
- **Desconectar**: cierra la conexión (cronometrado) y, si el modo usaba
  COM, hace el `CoUninitialize` que equilibra el `CoInitialize`.

## Nota sobre COM

Los modos OLE DB (todos menos `prDirect`) exigen que el hilo que abre la
conexión tenga COM inicializado, o UniDAC lanza *"CoInitialize has not
been called"*. Por eso, al conectar en esos modos se hace `CoInitialize(nil)`
antes de `Open` y `CoUninitialize` al desconectar. El flag `FComIniciado`
garantiza que el par quede siempre equilibrado (incluso si el `Open`
falla o si se cierra el formulario conectado). `prDirect` no toca COM.

## Ficheros

```
FactuzamTestSqlSrv.dpr     Programa (VCL, Win32/Win64).
FactuzamTestSqlSrv.dproj   Proyecto Delphi 12.
UTestSqlSrv.pas / .dfm     Formulario único con toda la lógica.
```

El `.res` lo regenera el IDE al compilar. UniDAC se resuelve por los
paquetes instalados en el IDE (igual que `utilmigsqlsrv`), no hay rutas
de búsqueda propias en el `.dproj`.

## Aviso

`prDirect` (TDS por sockets) normalmente **no** soporta autenticación
Windows; para ese modo usa usuario/clave de SQL Server. El check de
*Autenticación Windows* es útil sobre todo con los modos OLE DB.
