# Fase 6AH — configuración INI y rutas

Fecha: 28/07/2026. D3.7, séptimo fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 691 | 567 | **-124** |
| `inLibConfiguracionIni` | 0 | 118 | +118 |
| `inLibDir` | 163 | 87 | **-76** |
| `inLibLicenciaAplicacion` | 396 | 384 | **-12** |
| Dos consumidores migrados | 1.642 | 1.664 | +22 |
| Total productivo del alcance | 2.892 | 2.820 | **-72** |

`inLibtb` baja un 17,9 % en esta tanda. El alcance productivo completo,
incluyendo la nueva unidad y los consumidores, también se reduce:
72 líneas menos, un 2,5 %. Las 170 líneas de
`PruebasConfiguracionIni.pas` quedan excluidas.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 567 líneas, **-956 (-62,8 %)**;
- unidades especializadas o código añadido a ellas: 1.236 líneas;
- núcleo completo: 1.523 a 1.803 líneas, **+280**;
- alcance productivo acumulado: **+244 líneas**;
- dependencias directas de `inLibtb`: 50 a 9, incluida la fachada.

## Implementación

La nueva unidad `inLibConfiguracionIni` concentra:

- construcción de la ruta del INI;
- nombre predeterminado derivado del ejecutable;
- nombre alternativo recibido como primer parámetro;
- descarte de parámetros que empiezan por `/` o `-`;
- lectura de cadenas;
- escritura de cadenas;
- persistencia del valor predeterminado cuando la clave no existe.

Se conserva el contrato histórico:

- el directorio lo proporciona el consumidor;
- el fichero predeterminado sigue siendo `fzam.ini`;
- un parámetro posicional selecciona otro fichero dentro del mismo
  directorio;
- los interruptores no cambian el fichero;
- leer una clave ausente devuelve y escribe su valor predeterminado.

Se migran directamente:

- `inMtoLogon`, para conexión, usuario recordado, contraseña y acceso
  automático;
- `UniDataConn`, para preparar la conexión principal;
- `inLibLicenciaAplicacion`, que deja de duplicar la resolución del
  parámetro y del fichero.

`inMtoLogon` y `UniDataConn` dejan de depender de `inLibtb`.

## Código retirado

La búsqueda global confirmó que no tenían consumidores:

- `NomEjecutable`;
- `FileSinExtension`;
- `leCadINI` y `esCadINI`, las variantes sin directorio;
- las fachadas antiguas `leCadINIDir` y `esCadINIDir`, después de migrar
  sus dos únicos consumidores;
- los helpers privados `ParametroIniAplicacion`, `GetAppFolder` y
  `CrearFichBBDD`.

`inLibtb` deja de arrastrar `ADODB`, controles VCL, `COMObj`, `Forms` e
`IniFiles` por este bloque.

`inLibDir` queda limitada a sus referencias reales:

- seis funciones: directorio de aplicación, carpeta especial, carpeta
  de usuario, escritorio, log y tickets;
- tres constantes: documentos, escritorio y datos locales.

Salen `NomApp`, el wrapper sin consumidores de la carpeta temporal y
las demás constantes CSIDL sin referencias.

## Pruebas automáticas

`PruebasConfiguracionIni.pas` añade seis pruebas:

1. nombre del INI derivado del ejecutable;
2. fichero alternativo por parámetro posicional;
3. exclusión de interruptores con `/` y `-`;
4. devolución y persistencia de un valor ausente;
5. escritura y lectura sin cambios;
6. ruta compartida por configuración y licencia.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 147/147 | 0 | 0 |
| Debug / Win32 | 0 errores | 147/147 | 0 | 0 |
| Release / Win64 | 0 errores | 147/147 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados.

La aplicación se reconstruyó en Release/Win64 con Delphi 37 en
`build/validacion_d37/Win64/Release`: 0 errores, 311.015 líneas y
15,88 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.7 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- ninguna referencia residual a las firmas retiradas;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con el INI real**.

1. Arrancar con un `fzam.ini` existente en la carpeta del usuario.
2. Guardar otra conexión, reiniciar y comprobar host, BBDD, usuario,
   puerto y contraseña.
3. Activar usuario y contraseña recordados y repetir el arranque.
4. Activar y desactivar el acceso automático.
5. Arrancar con un fichero alternativo como primer parámetro.
6. Arrancar con un interruptor y confirmar que sigue usando `fzam.ini`.
7. Registrar o validar una licencia y comprobar que usa el mismo INI.
8. Generar un log y un ticket para comprobar sus carpetas.

D3 queda abierto: **7 de 9 fascículos**. El siguiente es D3.8:
NIF, CCC e IBAN.
