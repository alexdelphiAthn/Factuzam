# Compilación reproducible

IA-S32 elimina del proyecto las rutas propias de una máquina. El proyecto
importa `Factuzam.Dependencias.props` y obtiene sus dependencias mediante
propiedades MSBuild o variables de entorno.

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
