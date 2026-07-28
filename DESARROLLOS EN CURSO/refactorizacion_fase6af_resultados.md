# Fase 6AF — cifrado AES

Fecha: 28/07/2026. D3.5, quinto fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 966 | 877 | **-89** |
| `inLibCifrado` | 0 | 217 | +217 |
| Núcleo extraído | 966 | 1.094 | **+128** |
| Tres consumidores migrados | 2.542 | 2.551 | +9 |
| Total productivo del alcance | 3.508 | 3.645 | **+137** |

La fachada baja un 9,2 %. El alcance productivo completo crece un
3,9 % por la API especializada, las seis delegaciones compatibles y
la migración explícita de los consumidores. Las 197 líneas de
`PruebasCifrado.pas` quedan excluidas.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 877 líneas, **-646 (-42,4 %)**;
- unidades especializadas o código añadido a ellas: 1.118 líneas;
- núcleo completo: 1.523 a 1.995 líneas, **+472**;
- alcance productivo acumulado: **+505 líneas**;
- dependencias directas de `inLibtb`: 50 a 11, incluida la fachada.

## Implementación

La nueva unidad `inLibCifrado` concentra:

- cifrado y descifrado con clave y vector explícitos;
- las variantes con la clave predeterminada;
- las variantes históricas con contraseña adicional;
- codificación Base64;
- relleno compatible con PKCS#7;
- texto de entrada y salida en UTF-8.

Se conservan byte a byte:

- Rijndael/AES con clave de 256 bits y modo CBC;
- la clave y el vector de inicialización históricos;
- el Base64 almacenado en INI y en copias de seguridad;
- el resultado vacío al descifrar una entrada vacía, corrupta o no
  compatible.

`inLibtb` conserva las seis firmas antiguas como fachada, pero deja de
exponer `DCPrijndael`, `dcpbase64`, `DCPcrypt2` y
`System.NetEncoding`.

Se migran directamente:

- `inMtoLogon`, para contraseña de conexión, cambio de contraseña y
  contraseña recordada;
- `UniDataConn`, para la credencial de la conexión principal;
- `inLibBackupWorker`, para cifrar y restaurar copias de seguridad.

El worker de copias deja de depender de `inLibtb`. `inMtoLogon` y
`UniDataConn` conservan temporalmente esa dependencia por las funciones
INI, previstas para D3.7.

## Compatibilidad de la contraseña de copias

La clave histórica ya ocupa exactamente los 256 bits que recibe
`TDCP_rijndael.Init`. La contraseña adicional se concatena después y,
por tanto, no participa en el cifrado efectivo. D3.5 mantiene
deliberadamente ese comportamiento para poder abrir todas las copias
existentes.

Corregirlo requiere un formato cifrado versionado, autenticación del
contenido y una ruta de lectura del formato anterior. Se deja como
corrección funcional separada: cambiarlo silenciosamente en esta
refactorización invalidaría copias ya guardadas.

## Pruebas automáticas

`PruebasCifrado.pas` añade ocho pruebas DUnitX:

1. recuperación y recifrado de una credencial persistida;
2. vector conocido de texto ASCII;
3. compatibilidad UTF-8 y Base64 con Unicode;
4. retorno vacío ante entradas inválidas o vacías;
5. bloque de relleno de una entrada vacía;
6. clave y vector explícitos;
7. compatibilidad histórica de la variante con contraseña;
8. equivalencia de las seis firmas de la fachada.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 141/141 | 0 | 0 |
| Debug / Win32 | 0 errores | 141/141 | 0 | 0 |
| Release / Win64 | 0 errores | 141/141 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados.

La aplicación se reconstruyó en Release/Win64 con Delphi 37 en
`build/validacion_d35/Win64/Release`: 0 errores, 311.273 líneas y
10,78 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.5 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD y ficheros
reales**.

1. Iniciar sesión con una contraseña de conexión ya guardada.
2. Guardar otra contraseña de conexión, reiniciar y volver a entrar.
3. Recordar la contraseña de un usuario y probar el inicio automático.
4. Cambiar la contraseña de `root`, reiniciar y reconectar.
5. Crear una copia cifrada y restaurarla con esta misma versión.
6. Restaurar una copia cifrada creada antes de D3.5.
7. Intentar restaurar un fichero vacío o corrupto y comprobar el
   mensaje de error.

D3 queda abierto: **5 de 9 fascículos**. El siguiente es D3.6:
búsquedas y filtros.
