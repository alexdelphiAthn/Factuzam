# Compilación reproducible

IA-S32 elimina del proyecto las rutas propias de una máquina. El proyecto
importa `Factuzam.Dependencias.props` y obtiene sus dependencias mediante
propiedades MSBuild o variables de entorno.

## Migraciones funcionales

Antes de desplegar un binario con galerías de fotos, aplique una vez
`eng\migraciones\20260826_fotos_multiples.sql` sobre cada base de datos. El
script conserva las fotos existentes como posición 1 y puede ejecutarse de
nuevo sin duplicar la columna ni la clave primaria. Todos los puestos que
compartan la base deben actualizarse juntos: una versión antigua no conoce la
posición de la foto al rotar o eliminar.

Para evitar que las temporadas específicas de color/SKU multipliquen filas en
Archivo > Artículos, aplique también
`eng\migraciones\20260826_vi_articulos_sin_duplicados.sql`. La migración solo
recrea `vi_articulos`; no elimina artículos ni propiedades.

## Variables requeridas

| Variable | Directorio esperado |
| --- | --- |
| `FACTUZAM_DELPHI_ROOT` | Raíz de RAD Studio; debe contener `bin\rsvars.bat`. |
| `FACTUZAM_DEVEXPRESS_ROOT` | Biblioteca DevExpress para Win32; Win64 está en el subdirectorio `Win64`. |
| `FACTUZAM_FASTREPORT_ROOT` | Raíz VCL de FastReport con subdirectorios `Win32` y `Win64`. |
| `FACTUZAM_UNIDAC_ROOT` | Raíz `Lib` de UniDAC con subdirectorios `Win32` y `Win64`. |

`dependencias.ejemplo.ps1` contiene asignaciones sin rutas personales ni
credenciales. Se puede copiar fuera del repositorio y cargar antes de
compilar:

```powershell
. C:\configuracion-factuzam\dependencias.ps1
.\eng\compilar.ps1 -Configuracion Debug -Plataforma Ambas
```

El runner valida primero `cxClasses.dcu`, `frxClass.dcu` y `Uni.dcu` para
cada plataforma solicitada. Si falta una variable o unidad, termina con
código `2` y explica qué debe configurarse.

También se pueden pasar propiedades directamente a MSBuild:

```text
/p:FactuzamDevExpressRoot=<directorio>
/p:FactuzamFastReportRoot=<directorio>
/p:FactuzamUniDacRoot=<directorio>
```

La compilación directa del `dproj` ejecuta la misma validación mediante el
target `ValidarDependenciasFactuzam`.

## Comandos

Validar sin compilar:

```powershell
.\eng\compilar.ps1 -SoloValidar -Plataforma Ambas
```

Compilar Debug Win32 y Win64:

```powershell
.\eng\compilar.ps1 -Configuracion Debug -Plataforma Ambas
```

Compilar Release Win64:

```powershell
.\eng\compilar.ps1 -Configuracion Release -Plataforma Win64
```

Las salidas se escriben bajo `build\reproducible`. El runner no crea logs ni
resultados en la raíz.

UniDAC, JVCL y el resto de paquetes usados por el proyecto deben corresponder
a la versión de Delphi del runner. Las rutas explícitas de UniDAC se añaden al
proyecto; los paquetes instalados por sus proveedores siguen siendo
responsabilidad de la imagen del runner.

## Configuración local de DelphiLSP

Los archivos `*.delphilsp.json` no se versionan porque contienen rutas y
opciones de la instalación local. RAD Studio los genera al activar `Generate
LSP Config` en las opciones de Code Insight y volver a abrir el proyecto. Cada
desarrollador debe generar su propia copia cuando utilice DelphiLSP desde un
editor externo.

## Análisis estático con Pascal Analyzer

`analizar_pascal.ps1` ejecuta PALCMD con Delphi 13 sobre el proyecto y añade
las fuentes instaladas de DevExpress y FastReport sin guardar rutas locales en
el repositorio. Reutiliza las cuatro variables requeridas para compilar y la
selección de informes se fija en `PascalAnalyzer.ini`, por lo que no depende de
las preferencias de Pascal Analyzer de cada desarrollador. Para que el
resultado sea comparable, el runner exige Pascal Analyzer 9.21.5.
Genera los informes Totals, Modules, Strong Warnings, Warnings, Memory,
Complexity, Exception, Status y Security, junto con el SBOM CycloneDX
asociado. Conserva las salidas originales de PAL como `SBOM.pal.raw.json` y
`Security.pal.raw.txt`; `SBOM.json` y `Security.txt` contienen la version
normalizada, y `Security Coverage.txt` documenta el alcance real del analisis.

Validar la instalación sin ejecutar el análisis:

```powershell
.\eng\analizar_pascal.ps1 -SoloValidar
```

Analizar Win64 Debug y escribir los informes en un directorio temporal:

```powershell
.\eng\analizar_pascal.ps1 -Configuracion Debug -Plataforma Win64
```

De forma opcional pueden definirse estas variables:

| Variable | Uso |
| --- | --- |
| `FACTUZAM_PASCAL_ANALYZER` | Ruta completa a `palcmd.exe`. |
| `FACTUZAM_DEVEXPRESS_SOURCE_ROOT` | Raíz VCL que contiene las fuentes de DevExpress. |
| `FACTUZAM_FASTREPORT_SOURCE_ROOT` | Raíz `Sources` de FastReport. |

Si no se indican las dos raíces de fuentes, el script intenta obtenerlas a
partir de `FACTUZAM_DEVEXPRESS_ROOT` y `FACTUZAM_FASTREPORT_ROOT`. La
instalación actual de UniDAC solo distribuye las unidades principales como
DCU; Pascal Analyzer informará de esa limitación aunque el proyecto compile.
Las fuentes externas se siguen analizando para resolver símbolos, pero sus
identificadores se excluyen de los informes que admiten ese filtro para
mantenerlos centrados en el código propio. `Totals.txt` conserva deliberadamente
el total global de unidades analizadas, incluidas las dependencias.

El postprocesado del SBOM añade el componente raíz de Factuzam, cierra y valida
las referencias del grafo, calcula SHA-256 para los ficheros inventariados,
sustituye las rutas absolutas por identificadores lógicos y clasifica por
separado código propio y dependencias, incluidas las fuentes vendorizadas de
`src/Lib/sqlformatter` y `src/vcl37`. Las fuentes SQL Formatter se identifican
además con su licencia Apache-2.0. `isExternal` mantiene el significado de
CycloneDX —componente de ejecución proporcionado por el entorno— y no se usa
como sinónimo de tercero. Las unidades que PAL no puede cargar desde fuentes se
representan mediante componentes separados para UniDAC y DAC, identificados
con sus versiones y con las huellas de sus DCU/BPL de evidencia. El grafo crea
un nodo para cada componente y declara la composición como incompleta porque
describe la resolución de fuentes, no una entrega reconciliada con el EXE o el
instalador.

El conjunto saneado que puede exportarse está formado exclusivamente por
`SBOM.json`, `Security.txt` y `Security Coverage.txt`. Las copias raw y los demás
informes de Pascal Analyzer (`Status.txt`, `Modules.txt`, `Complexity.txt`, etc.)
son evidencia interna y pueden contener rutas locales; no debe publicarse ni
copiarse como entrega el directorio completo de resultados.

Pascal Analyzer no consulta una base de vulnerabilidades. Por eso
`Security Coverage.txt` declara `Vulnerability scan: NOT PERFORMED` y estado
`UNKNOWN`: el informe no debe interpretarse como ausencia de CVE. Para obtener
cobertura de vulnerabilidades hace falta un escáner posterior y, en las
dependencias comerciales sin identificadores públicos fiables, revisar también
los avisos de seguridad de sus proveedores.

Los informes no se escriben en el repositorio salvo que se pase expresamente
`-DirectorioSalida`; si se especifica, el directorio debe estar vacío. El
script confirma que PALCMD terminó y generó los informes, pero no aplica un
umbral automático de avisos ni actúa como puerta de calidad.

## Proyecto de pruebas

`tests\FactuzamTests.dproj`, citado por el plan original de IA-S32, fue
eliminado del repositorio en el commit `3b709913` junto al antiguo conjunto de
scripts y pruebas. IA-S32 no lo restaura. Si se vuelve a incorporar, debe:

1. importar `eng\Factuzam.Dependencias.props`;
2. usar `$(FactuzamDependenciasPruebas)` en `DCC_UnitSearchPath`;
3. definir `FactuzamRequiereDUnitX=true`.

De esta forma reutilizará las mismas rutas por plataforma y la validación de
DUnitX sin introducir rutas absolutas.

## Runner de CI

El runner Windows autoalojado debe configurar las cuatro variables requeridas
en el entorno del servicio. El workflow compila siempre Release Win32 y Win64;
un cambio que rompa una plataforma no queda oculto por la otra.
