# Fase 6AE — configuración de conexiones UniDAC

Fecha: 28/07/2026. D3.4, cuarto fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 1.005 | 966 | **-39** |
| `inLibConexionesUniDAC` | 121 | 208 | +87 |
| Núcleo extraído | 1.126 | 1.174 | **+48** |
| Dos consumidores migrados | 1.634 | 1.637 | +3 |
| Total productivo del alcance | 2.760 | 2.811 | **+51** |

La fachada baja un 3,9 %. El alcance productivo completo crece un
1,8 % por las dos APIs especializadas, las delegaciones compatibles y
la separación de configuración y conexión. Las 177 líneas de
`PruebasConexiones.pas` quedan excluidas.

No se crea una unidad adicional: se amplía
`inLibConexionesUniDAC`, que ya contiene el servicio de conexiones de
trabajo.

## Corrección del inventario de dependencias

La revisión sin distinguir mayúsculas encontró que `inMtoLogon` escribía
la unidad como `inlibtb`. Los recuentos anteriores eran coherentes entre
sí, pero omitían ese consumidor.

Recuento directo corregido:

- inicio de D3: 50, no 49;
- final de D3.1: 48, no 47;
- final de D3.2: 17, no 16;
- final de D3.3 y D3.4: 12, no 11.

D3.4 no elimina aún las dependencias de `inMtoLogon` y `UniDataConn`
porque ambas unidades siguen usando cifrado e INI, previstos para D3.5
y D3.7.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 966 líneas, **-557 (-36,6 %)**;
- unidades especializadas o código añadido a ellas: 901 líneas;
- núcleo completo: 1.523 a 1.867 líneas, **+344**;
- alcance productivo acumulado: **+368 líneas**;
- dependencias directas de `inLibtb`: 50 a 12.

## Implementación

`inLibConexionesUniDAC` incorpora:

- `ConfigurarConexionMySQL`, para la conexión principal;
- `ConfigurarYConectarMySQL`, para los flujos de login y preparación de
  la BBDD;
- un helper interno común para credenciales, servidor, base y puerto.

Se conservan:

- el `ConnectString` heredado;
- el puerto predeterminado 3306;
- Unicode y `utf8mb4`;
- pooling y validación;
- mínimo 3 y máximo 20 conexiones;
- `LocalFailover` y `DisconnectedMode`;
- el mismo mensaje y propagación de errores al conectar.

`inLibtb` conserva las dos firmas antiguas como fachada. Su interfaz
deja de arrastrar `Dialogs` y `Vcl.Consts`.

Se migran directamente:

- `inMtoLogon`, con sus diez rutas de conexión;
- `UniDataConn`, para configurar la conexión principal.

## Pruebas automáticas

`PruebasConexiones.pas` añade cuatro pruebas DUnitX sin conexión real:

1. asignación de servidor, BBDD, usuario, contraseña y puerto;
2. fallback al puerto 3306 cuando el valor no es válido;
3. Unicode, charset, protocolo, pooling, timeout y failover;
4. equivalencia entre la API especializada y la fachada.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 133/133 | 0 | 0 |
| Debug / Win32 | 0 errores | 133/133 | 0 | 0 |
| Release / Win64 | 0 errores | 133/133 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados.

La aplicación seguía abierta y bloqueaba su ejecutable habitual. Sin
cerrarla, se reconstruyó Release/Win64 con Delphi 37 en
`build/validacion_d34/Win64/Release`: 0 errores, 311.133 líneas y
25,95 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.4 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Iniciar sesión con credenciales válidas.
2. Probar usuario, contraseña, host y puerto incorrectos.
3. Comprobar el fallback 3306 con un puerto no válido.
4. Crear o preparar una BBDD desde el formulario de login.
5. Subir un script y reconectar a la BBDD seleccionada.
6. Confirmar la colación y los timeouts de sesión tras conectar.
7. Simular una pérdida de red y comprobar el failover.
8. Verificar que una conexión ya abierta no se reconecta.

D3 queda abierto: **4 de 9 fascículos**. El siguiente es D3.5:
cifrado AES.
