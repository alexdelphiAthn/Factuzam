[CmdletBinding()]
param(
  [ValidateSet('Debug', 'Release')]
  [string]$Configuracion = 'Debug',
  [ValidateSet('Win32', 'Win64')]
  [string]$Plataforma = 'Win64',
  [ValidateRange(1, 64)]
  [int]$Hilos = 2,
  [string]$DirectorioSalida = '',
  [switch]$SoloValidar
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Obtener-RutaObligatoria {
  param(
    [string]$Valor,
    [string]$Variable,
    [string]$Descripcion
  )

  if ([string]::IsNullOrWhiteSpace($Valor)) {
    throw "Falta $Descripcion. Defina $Variable."
  }
  if (-not (Test-Path -LiteralPath $Valor -PathType Container)) {
    throw "$Variable no contiene un directorio valido: $Valor"
  }
  return (Resolve-Path -LiteralPath $Valor).Path
}

function Buscar-RaizPorArchivo {
  param(
    [string]$Inicio,
    [string]$ArchivoRelativo
  )

  $actual = [System.IO.DirectoryInfo]::new($Inicio)
  while ($null -ne $actual) {
    if (Test-Path -LiteralPath (
        Join-Path $actual.FullName $ArchivoRelativo) -PathType Leaf) {
      return $actual.FullName
    }
    $actual = $actual.Parent
  }
  return ''
}

function Restaurar-VariableEntorno {
  param(
    [string]$Nombre,
    [AllowNull()]
    [string]$Valor
  )

  [Environment]::SetEnvironmentVariable(
    $Nombre,
    $Valor,
    [EnvironmentVariableTarget]::Process)
}

function Ruta-EstaDentroDe {
  param(
    [string]$Ruta,
    [string]$Raiz
  )

  $rutaNormalizada = [IO.Path]::GetFullPath($Ruta).TrimEnd('\')
  $raizNormalizada = [IO.Path]::GetFullPath($Raiz).TrimEnd('\')
  return (
    ($rutaNormalizada -ieq $raizNormalizada) -or
    $rutaNormalizada.StartsWith(
      "$raizNormalizada\",
      [StringComparison]::OrdinalIgnoreCase))
}

function Agregar-RutaExclusion {
  param(
    [System.Collections.Generic.List[string]]$Rutas,
    [string]$Ruta
  )

  if ([string]::IsNullOrWhiteSpace($Ruta) -or
      -not (Test-Path -LiteralPath $Ruta -PathType Container)) {
    return
  }

  $rutaResuelta = (Resolve-Path -LiteralPath $Ruta).Path.TrimEnd('\')
  $yaExiste = $Rutas | Where-Object { $_ -ieq $rutaResuelta } |
    Select-Object -First 1
  if ($null -eq $yaExiste) {
    $Rutas.Add($rutaResuelta)
  }
}

function Expandir-RutaConfigurada {
  param(
    [string]$Ruta,
    [hashtable]$Macros
  )

  if ([string]::IsNullOrWhiteSpace($Ruta)) {
    return ''
  }

  $resultado = [Environment]::ExpandEnvironmentVariables(
    $Ruta.Trim().Trim('"'))
  for ($intento = 0; $intento -lt 10; $intento++) {
    $coincidencias = [regex]::Matches($resultado, '\$\(([^)]+)\)')
    if ($coincidencias.Count -eq 0) {
      break
    }

    $huboSustitucion = $false
    foreach ($coincidencia in $coincidencias) {
      $nombreMacro = $coincidencia.Groups[1].Value
      $macroEncontrada = $Macros.ContainsKey($nombreMacro)
      if ($macroEncontrada) {
        $valorMacro = [string]$Macros[$nombreMacro]
      }
      else {
        $valorMacro = [Environment]::GetEnvironmentVariable(
          $nombreMacro,
          [EnvironmentVariableTarget]::Process)
        if ([string]::IsNullOrWhiteSpace($valorMacro)) {
          $valorMacro = [Environment]::GetEnvironmentVariable(
            $nombreMacro,
            [EnvironmentVariableTarget]::User)
        }
        if ([string]::IsNullOrWhiteSpace($valorMacro)) {
          $valorMacro = [Environment]::GetEnvironmentVariable(
            $nombreMacro,
            [EnvironmentVariableTarget]::Machine)
        }
        $macroEncontrada = -not [string]::IsNullOrWhiteSpace($valorMacro)
      }

      if ($macroEncontrada) {
        $resultado = $resultado.Replace(
          $coincidencia.Value,
          $valorMacro)
        $huboSustitucion = $true
      }
    }
    if (-not $huboSustitucion) {
      break
    }
  }

  return $resultado.Trim().Trim('"')
}

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$proyecto = Join-Path $raiz 'fzam.dproj'

$delphiRootValor = $env:FACTUZAM_DELPHI_ROOT
if ([string]::IsNullOrWhiteSpace($delphiRootValor)) {
  $delphiRootValor = $env:BDS
}
$delphiRoot = Obtener-RutaObligatoria `
  $delphiRootValor `
  'FACTUZAM_DELPHI_ROOT' `
  'Delphi'
$rsvars = Join-Path $delphiRoot 'bin\rsvars.bat'
$nombreCompiladorDelphi = if ($Plataforma -eq 'Win32') {
  'dcc32.exe'
}
else {
  'dcc64.exe'
}
$compiladorDelphi = Join-Path $delphiRoot "bin\$nombreCompiladorDelphi"
if (-not (Test-Path -LiteralPath $rsvars -PathType Leaf) -or
    -not (Test-Path -LiteralPath $compiladorDelphi -PathType Leaf)) {
  throw (
    'FACTUZAM_DELPHI_ROOT no es una instalacion completa de Delphi: ' +
    "faltan bin\rsvars.bat o bin\$nombreCompiladorDelphi.")
}
$versionDelphi = [Diagnostics.FileVersionInfo]::GetVersionInfo(
  $compiladorDelphi)
if ($versionDelphi.ProductMajorPart -ne 37) {
  throw (
    'Este analisis requiere Delphi 13 / Studio 37.0; se encontro la ' +
    "version $($versionDelphi.ProductVersion) en $compiladorDelphi.")
}
$devExpressRoot = Obtener-RutaObligatoria `
  $env:FACTUZAM_DEVEXPRESS_ROOT `
  'FACTUZAM_DEVEXPRESS_ROOT' `
  'DevExpress'
$fastReportRoot = Obtener-RutaObligatoria `
  $env:FACTUZAM_FASTREPORT_ROOT `
  'FACTUZAM_FASTREPORT_ROOT' `
  'FastReport'
$uniDacRoot = Obtener-RutaObligatoria `
  $env:FACTUZAM_UNIDAC_ROOT `
  'FACTUZAM_UNIDAC_ROOT' `
  'UniDAC'

$pascalAnalyzer = $env:FACTUZAM_PASCAL_ANALYZER
if (-not [string]::IsNullOrWhiteSpace($pascalAnalyzer)) {
  if (-not (Test-Path -LiteralPath $pascalAnalyzer -PathType Leaf)) {
    throw "FACTUZAM_PASCAL_ANALYZER no existe: $pascalAnalyzer"
  }
  $pascalAnalyzer = (Resolve-Path -LiteralPath $pascalAnalyzer).Path
}
else {
  $candidatosPal = [System.Collections.Generic.List[string]]::new()
  if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $candidatosPal.Add((Join-Path $env:ProgramFiles (
      'Peganza\Pascal Analyzer 9\palcmd.exe')))
  }
  $programFilesX86 = ${env:ProgramFiles(x86)}
  if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
    $candidatosPal.Add((Join-Path $programFilesX86 (
      'Peganza\Pascal Analyzer 9\palcmd.exe')))
  }
  $pascalAnalyzer = $candidatosPal |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
  if ([string]::IsNullOrWhiteSpace($pascalAnalyzer)) {
    throw (
      'No se encontro PALCMD. Instale Pascal Analyzer 9 o defina ' +
      'FACTUZAM_PASCAL_ANALYZER.')
  }
  $pascalAnalyzer = (Resolve-Path -LiteralPath $pascalAnalyzer).Path
}

$versionPalTexto = [Diagnostics.FileVersionInfo]::GetVersionInfo(
  $pascalAnalyzer).ProductVersion
try {
  $versionPal = [Version]$versionPalTexto
}
catch {
  throw "No se pudo determinar la version de PALCMD: $pascalAnalyzer"
}
if ($versionPal -ne [Version]'9.21.5.0') {
  throw (
    'Se requiere Pascal Analyzer 9.21.5 para reproducir los informes; ' +
    "se encontro $versionPalTexto.")
}

$configuracionPal = Join-Path $PSScriptRoot 'PascalAnalyzer.ini'
if (-not (Test-Path -LiteralPath $configuracionPal -PathType Leaf)) {
  throw "Falta la configuracion versionada: $configuracionPal"
}
$lineasConfiguracionBase = @(Get-Content -LiteralPath $configuracionPal)
$indicesExclusion = @(for (
    $indice = 0;
    $indice -lt $lineasConfiguracionBase.Count;
    $indice++) {
  if ($lineasConfiguracionBase[$indice] -like 'IdExcludeDirs=*') {
    $indice
  }
})
if ($indicesExclusion.Count -ne 1) {
  throw 'PascalAnalyzer.ini debe contener una unica clave IdExcludeDirs.'
}

$devExpressSourceRoot = $env:FACTUZAM_DEVEXPRESS_SOURCE_ROOT
if ([string]::IsNullOrWhiteSpace($devExpressSourceRoot)) {
  $devExpressSourceRoot = Buscar-RaizPorArchivo `
    $devExpressRoot `
    'ExpressLibrary\Sources\cxClasses.pas'
}
$devExpressSourceRoot = Obtener-RutaObligatoria `
  $devExpressSourceRoot `
  'FACTUZAM_DEVEXPRESS_SOURCE_ROOT' `
  'las fuentes de DevExpress'
if (-not (Test-Path -LiteralPath (Join-Path $devExpressSourceRoot (
      'ExpressLibrary\Sources\cxClasses.pas')) -PathType Leaf)) {
  throw (
    'FACTUZAM_DEVEXPRESS_SOURCE_ROOT debe apuntar a la raiz VCL que ' +
    'contiene ExpressLibrary\Sources\cxClasses.pas.')
}

$fastReportSourceRoot = $env:FACTUZAM_FASTREPORT_SOURCE_ROOT
if ([string]::IsNullOrWhiteSpace($fastReportSourceRoot)) {
  $fastReportBase = Buscar-RaizPorArchivo `
    $fastReportRoot `
    'Sources\FastReport\VCL\Sources\frxClass.pas'
  if (-not [string]::IsNullOrWhiteSpace($fastReportBase)) {
    $fastReportSourceRoot = Join-Path $fastReportBase 'Sources'
  }
}
$fastReportSourceRoot = Obtener-RutaObligatoria `
  $fastReportSourceRoot `
  'FACTUZAM_FASTREPORT_SOURCE_ROOT' `
  'las fuentes de FastReport'
if (-not (Test-Path -LiteralPath (Join-Path $fastReportSourceRoot (
      'FastReport\VCL\Sources\frxClass.pas')) -PathType Leaf)) {
  throw (
    'FACTUZAM_FASTREPORT_SOURCE_ROOT debe contener ' +
    'FastReport\VCL\Sources\frxClass.pas.')
}

$devExpressSources = Get-ChildItem -LiteralPath $devExpressSourceRoot `
    -Directory |
  ForEach-Object { Join-Path $_.FullName 'Sources' } |
  Where-Object {
    (Test-Path -LiteralPath $_ -PathType Container) -and
    ($null -ne (Get-ChildItem -LiteralPath $_ -Filter '*.pas' -File |
      Select-Object -First 1))
  } |
  Sort-Object -Unique
$fastReportSources = Get-ChildItem -LiteralPath $fastReportSourceRoot `
    -Directory |
  ForEach-Object { Join-Path $_.FullName 'VCL\Sources' } |
  Where-Object {
    (Test-Path -LiteralPath $_ -PathType Container) -and
    ($null -ne (Get-ChildItem -LiteralPath $_ -Filter '*.pas' -File |
      Select-Object -First 1))
  } |
  Sort-Object -Unique

if ($devExpressSources.Count -eq 0) {
  throw 'No se encontraron directorios Pascal de DevExpress.'
}
if ($fastReportSources.Count -eq 0) {
  throw 'No se encontraron directorios Pascal de FastReport.'
}

$devExpressBin = if ($Plataforma -eq 'Win32') {
  $devExpressRoot
}
else {
  Join-Path $devExpressRoot 'Win64'
}
$fastReportBin = Join-Path $fastReportRoot $Plataforma
$uniDacBin = Join-Path $uniDacRoot $Plataforma

$unidadesBinarias = @(
  @{ Ruta = $devExpressBin; Unidad = 'cxClasses.dcu'; Nombre = 'DevExpress' },
  @{ Ruta = $fastReportBin; Unidad = 'frxClass.dcu'; Nombre = 'FastReport' },
  @{ Ruta = $uniDacBin; Unidad = 'Uni.dcu'; Nombre = 'UniDAC' }
)
foreach ($dependencia in $unidadesBinarias) {
  $unidad = Join-Path $dependencia.Ruta $dependencia.Unidad
  if (-not (Test-Path -LiteralPath $unidad -PathType Leaf)) {
    throw (
      "$($dependencia.Nombre) no contiene $($dependencia.Unidad) " +
      "para $($Plataforma): $($dependencia.Ruta)")
  }
}

$rutasDependencias = @(
  $devExpressBin,
  $fastReportBin,
  $uniDacBin
) + $devExpressSources + $fastReportSources
$rutasDependencias = $rutasDependencias | Sort-Object -Unique

# PAL debe analizar las fuentes externas para resolver los simbolos, pero sus
# identificadores no deben mezclarse con los informes del codigo de Factuzam.
$rutasExcluidasInformes = [System.Collections.Generic.List[string]]::new()
foreach ($rutaExterna in @(
    $delphiRoot,
    $devExpressRoot,
    $devExpressSourceRoot,
    $fastReportRoot,
    $fastReportSourceRoot,
    $uniDacRoot)) {
  Agregar-RutaExclusion $rutasExcluidasInformes $rutaExterna
}

$claveBiblioteca = (
  "HKCU:\Software\Embarcadero\BDS\37.0\Library\$Plataforma")
if (Test-Path -LiteralPath $claveBiblioteca) {
  $bibliotecaDelphi = Get-ItemProperty -LiteralPath $claveBiblioteca
  $macrosDelphi = @{
    BDS = $delphiRoot
    BDSBIN = (Join-Path $delphiRoot 'bin')
    BDSLIB = (Join-Path $delphiRoot 'lib')
    BDSCOMMONDIR = (Join-Path (
      [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::CommonDocuments)) (
      'Embarcadero\Studio\37.0'))
    BDSUSERDIR = (Join-Path (
      [Environment]::GetFolderPath('MyDocuments')) (
      'Embarcadero\Studio\37.0'))
    DXVCL = $devExpressSourceRoot
    LANGDIR = ''
    Platform = $Plataforma
  }
  foreach ($nombrePropiedad in @('Search Path', 'Browsing Path')) {
    $valorPropiedad = $bibliotecaDelphi.$nombrePropiedad
    foreach ($rutaBiblioteca in ($valorPropiedad -split ';')) {
      $rutaBiblioteca = Expandir-RutaConfigurada `
        $rutaBiblioteca `
        $macrosDelphi
      if ([IO.Path]::IsPathRooted($rutaBiblioteca) -and
          -not (Ruta-EstaDentroDe $rutaBiblioteca $raiz)) {
        Agregar-RutaExclusion $rutasExcluidasInformes $rutaBiblioteca
      }
    }
  }
}

foreach ($rutaTercerosProyecto in @(
    (Join-Path $raiz 'src\Lib3par'),
    (Join-Path $raiz 'src\3rdpartyComp'))) {
  Agregar-RutaExclusion $rutasExcluidasInformes $rutaTercerosProyecto
}
$rutasExcluidasInformes.Sort()

Write-Output (
  'Pascal Analyzer: dependencias validas. ' +
  "DevExpress=$($devExpressSources.Count) carpetas de fuentes; " +
  "FastReport=$($fastReportSources.Count) carpetas de fuentes; " +
  'UniDAC=solo DCU.')
if ($SoloValidar) {
  exit 0
}

if ([string]::IsNullOrWhiteSpace($DirectorioSalida)) {
  $marcaTiempo = Get-Date -Format 'yyyyMMdd-HHmmss'
  $identificador = [Guid]::NewGuid().ToString('N').Substring(0, 8)
  $DirectorioSalida = Join-Path ([IO.Path]::GetTempPath()) (
    "Factuzam-PascalAnalyzer-$marcaTiempo-$identificador")
}
$DirectorioSalida = [IO.Path]::GetFullPath($DirectorioSalida)
if (Test-Path -LiteralPath $DirectorioSalida) {
  if (-not (Test-Path -LiteralPath $DirectorioSalida -PathType Container)) {
    throw "DirectorioSalida no es un directorio: $DirectorioSalida"
  }
  $elementoExistente = Get-ChildItem -LiteralPath $DirectorioSalida -Force |
    Select-Object -First 1
  if ($null -ne $elementoExistente) {
    throw "DirectorioSalida debe estar vacio: $DirectorioSalida"
  }
}
else {
  [void](New-Item -ItemType Directory -Path $DirectorioSalida)
}

$configuracionEfectiva = Join-Path $DirectorioSalida (
  'PascalAnalyzer.effective.ini')
$lineasConfiguracion = @($lineasConfiguracionBase)
$valorExclusiones = $rutasExcluidasInformes |
  ForEach-Object { "$_<+>" }
$lineasConfiguracion[$indicesExclusion[0]] = (
  'IdExcludeDirs=' + ($valorExclusiones -join ';'))
[IO.File]::WriteAllLines(
  $configuracionEfectiva,
  [string[]]$lineasConfiguracion,
  [Text.UTF8Encoding]::new($true))

$opcionCompilador = if ($Plataforma -eq 'Win32') {
  '/CD13W32'
}
else {
  '/CD13W64'
}
$argumentos = @(
  $proyecto,
  '/A-',
  '/FA',
  '/Q',
  "/I=$configuracionEfectiva",
  $opcionCompilador,
  "/BUILD=$Configuracion",
  '/F=T',
  "/R=$DirectorioSalida",
  '/NAME=Factuzam',
  "/T=$Hilos"
)

$dependenciasAnteriores = [Environment]::GetEnvironmentVariable(
  'FactuzamDependenciasPlataforma',
  [EnvironmentVariableTarget]::Process)
$bdsAnterior = [Environment]::GetEnvironmentVariable(
  'BDS',
  [EnvironmentVariableTarget]::Process)

$codigoSalida = 99
try {
  [Environment]::SetEnvironmentVariable(
    'FactuzamDependenciasPlataforma',
    ($rutasDependencias -join ';'),
    [EnvironmentVariableTarget]::Process)
  [Environment]::SetEnvironmentVariable(
    'BDS',
    $delphiRoot,
    [EnvironmentVariableTarget]::Process)

  Write-Output (
    "Analizando fzam: Delphi 13 $Plataforma $Configuracion...")
  & $pascalAnalyzer @argumentos
  $codigoSalida = $LASTEXITCODE
}
finally {
  Restaurar-VariableEntorno `
    'FactuzamDependenciasPlataforma' `
    $dependenciasAnteriores
  Restaurar-VariableEntorno 'BDS' $bdsAnterior
}

if ($codigoSalida -ne 0) {
  throw "Pascal Analyzer termino con codigo $codigoSalida."
}

$informesEsperados = @(
  'Totals.txt',
  'Modules.txt',
  'Strong Warnings.txt',
  'Warnings.txt',
  'Memory.txt',
  'Exception.txt',
  'Security.txt',
  'SBOM.json',
  'Complexity.txt'
)
$informesFaltantes = [System.Collections.Generic.List[string]]::new()
$informeTotales = $null
foreach ($nombreInforme in $informesEsperados) {
  $informe = Get-ChildItem -LiteralPath $DirectorioSalida `
      -Filter $nombreInforme -File -Recurse |
    Select-Object -First 1
  if ($null -eq $informe) {
    $informesFaltantes.Add($nombreInforme)
  }
  elseif ($nombreInforme -eq 'Totals.txt') {
    $informeTotales = $informe
  }
}
if ($informesFaltantes.Count -gt 0) {
  throw (
    'PALCMD termino sin error, pero faltan informes configurados: ' +
    ($informesFaltantes -join ', '))
}

Write-Output "Informes generados: $($informeTotales.Directory.FullName)"
Write-Output "Configuracion efectiva: $configuracionEfectiva"

exit 0
