#requires -Version 7.0
<#
.SYNOPSIS
  Comprime Factuzam y factuzam_web en un unico archivo 7z.

.DESCRIPTION
  Incluye el estado actual de ambos repositorios: archivos versionados,
  modificaciones locales y archivos nuevos que Git no ignore. Excluye .git,
  cualquier archivo que coincida con las reglas de exclusion de Git aunque ya
  estuviera versionado, los archivos borrados localmente y todos los .exe.

.EXAMPLE
  pwsh -File .\scripts\comprimir_factuzam_y_web.ps1

.EXAMPLE
  pwsh -File .\scripts\comprimir_factuzam_y_web.ps1 `
    -Salida C:\copias\factuzam_fuentes.7z
#>
[CmdletBinding()]
param(
  [string]$RutaFactuzam = (Split-Path -Parent $PSScriptRoot),
  [string]$RutaFactuzamWeb = (
    Join-Path `
      (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) `
      'factuzam_web'),
  [string]$Salida,
  [ValidateRange(0, 9)]
  [int]$NivelCompresion = 9
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Obtener-Ejecutable7Zip {
  $comandos = @(
    Get-Command 7z.exe, 7zz.exe, 7za.exe `
      -CommandType Application `
      -ErrorAction SilentlyContinue
  )
  if ($comandos.Count -gt 0) {
    return $comandos[0].Source
  }
  $candidatos = @(
    (Join-Path $env:ProgramFiles '7-Zip\7z.exe')
  )
  if (${env:ProgramFiles(x86)}) {
    $candidatos += Join-Path ${env:ProgramFiles(x86)} '7-Zip\7z.exe'
  }
  foreach ($candidato in $candidatos) {
    if (Test-Path -LiteralPath $candidato -PathType Leaf) {
      return $candidato
    }
  }
  throw 'No se encuentra 7-Zip. Instala 7-Zip o anade 7z.exe al PATH.'
}

function Ejecutar-Git {
  param(
    [Parameter(Mandatory)]
    [string]$Repositorio,
    [Parameter(Mandatory)]
    [string[]]$Argumentos
  )
  $argumentosCompletos = @(
    '-c'
    "safe.directory=$Repositorio"
    '-c'
    'core.quotePath=false'
    '-C'
    $Repositorio
  ) + $Argumentos
  $salidaGit = @(& $script:EjecutableGit @argumentosCompletos 2>&1)
  $codigoGit = $LASTEXITCODE
  if ($codigoGit -ne 0) {
    $detalle = ($salidaGit | ForEach-Object { "$_" }) -join [Environment]::NewLine
    throw "Git no pudo leer '$Repositorio'.`n$detalle"
  }
  return @($salidaGit | ForEach-Object { "$_" })
}

function Obtener-ContenidoRepositorio {
  param(
    [Parameter(Mandatory)]
    [pscustomobject]$Repositorio
  )
  $rutasIgnoradasVersionadas = @(Ejecutar-Git `
    -Repositorio $Repositorio.Ruta `
    -Argumentos @(
      'ls-files', '--cached', '--ignored', '--exclude-standard', '--'))
  $ignoradas = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  foreach ($rutaIgnorada in $rutasIgnoradasVersionadas) {
    [void]$ignoradas.Add($rutaIgnorada.Replace('\', '/'))
  }
  $candidatas = @(Ejecutar-Git `
    -Repositorio $Repositorio.Ruta `
    -Argumentos @(
      'ls-files', '--cached', '--others', '--exclude-standard', '--'))
  $incluidas = [System.Collections.Generic.List[string]]::new()
  $cantidadIgnoradas = 0
  $cantidadEjecutables = 0
  $cantidadBorradas = 0
  foreach ($rutaRelativaOriginal in $candidatas) {
    $rutaRelativa = $rutaRelativaOriginal.Replace('\', '/')
    if ($ignoradas.Contains($rutaRelativa)) {
      $cantidadIgnoradas++
      continue
    }
    if ([System.IO.Path]::GetExtension($rutaRelativa) -ieq '.exe') {
      $cantidadEjecutables++
      continue
    }
    $rutaNativa = $rutaRelativa.Replace(
      '/',
      [System.IO.Path]::DirectorySeparatorChar)
    $origen = Join-Path $Repositorio.Ruta $rutaNativa
    if ([System.IO.File]::Exists($origen)) {
      $incluidas.Add((Join-Path $Repositorio.Nombre $rutaNativa))
      continue
    }
    if ([System.IO.Directory]::Exists($origen)) {
      throw "Se encontro un posible submodulo no admitido: '$origen'."
    }
    $cantidadBorradas++
  }
  return [pscustomobject]@{
    Nombre = $Repositorio.Nombre
    Rutas = $incluidas.ToArray()
    IgnoradasVersionadas = $cantidadIgnoradas
    Ejecutables = $cantidadEjecutables
    Borradas = $cantidadBorradas
  }
}

$comandosGit = @(
  Get-Command git.exe `
    -CommandType Application `
    -ErrorAction Stop
)
$EjecutableGit = $comandosGit[0].Source
$ejecutable7Zip = Obtener-Ejecutable7Zip
$rutaFactuzamResuelta = (Resolve-Path -LiteralPath $RutaFactuzam).Path
$rutaFactuzamWebResuelta = (Resolve-Path -LiteralPath $RutaFactuzamWeb).Path
$padreFactuzam = Split-Path -Parent $rutaFactuzamResuelta
$padreFactuzamWeb = Split-Path -Parent $rutaFactuzamWebResuelta
if ($padreFactuzam -ine $padreFactuzamWeb) {
  throw 'Factuzam y factuzam_web deben estar dentro de la misma carpeta.'
}
$repositorios = @(
  [pscustomobject]@{
    Nombre = Split-Path -Leaf $rutaFactuzamResuelta
    Ruta = $rutaFactuzamResuelta
  }
  [pscustomobject]@{
    Nombre = Split-Path -Leaf $rutaFactuzamWebResuelta
    Ruta = $rutaFactuzamWebResuelta
  }
)
foreach ($repositorio in $repositorios) {
  $esRepositorio = Ejecutar-Git `
    -Repositorio $repositorio.Ruta `
    -Argumentos @('rev-parse', '--is-inside-work-tree')
  if (($esRepositorio -join '').Trim() -ne 'true') {
    throw "La ruta no es un repositorio Git: '$($repositorio.Ruta)'."
  }
}
if ([string]::IsNullOrWhiteSpace($Salida)) {
  $nombreArchivo = 'Factuzam_y_factuzam_web_{0}.7z' -f (
    Get-Date -Format 'yyyyMMdd_HHmmss')
  $Salida = Join-Path $padreFactuzam $nombreArchivo
}
elseif (-not [System.IO.Path]::IsPathRooted($Salida)) {
  $Salida = Join-Path (Get-Location).Path $Salida
}
if ([System.IO.Path]::GetExtension($Salida) -ine '.7z') {
  $Salida += '.7z'
}
$rutaSalida = [System.IO.Path]::GetFullPath($Salida)
if (Test-Path -LiteralPath $rutaSalida) {
  throw "La salida ya existe y no se actualizara: '$rutaSalida'."
}
$directorioSalida = Split-Path -Parent $rutaSalida
if (-not (Test-Path -LiteralPath $directorioSalida -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $directorioSalida)
}
$resultados = @(
  $repositorios | ForEach-Object { Obtener-ContenidoRepositorio $_ }
)
$rutasArchivo = @($resultados | ForEach-Object { $_.Rutas })
if ($rutasArchivo.Count -eq 0) {
  throw 'Git no ha seleccionado ningun archivo para comprimir.'
}
$identificador = [System.Guid]::NewGuid().ToString('N')
$listaTemporal = Join-Path `
  ([System.IO.Path]::GetTempPath()) `
  "factuzam_7z_$identificador.txt"
$archivoParcial = Join-Path `
  $directorioSalida `
  ".$([System.IO.Path]::GetFileNameWithoutExtension($rutaSalida)).$identificador.partial.7z"
$completado = $false
try {
  [System.IO.File]::WriteAllLines(
    $listaTemporal,
    $rutasArchivo,
    [System.Text.UTF8Encoding]::new($false))
  foreach ($resultado in $resultados) {
    $resumenRepositorio = (
      '{0}: {1} archivos incluidos; {2} versionados ignorados, ' +
      '{3} ejecutables y {4} borrados omitidos.') -f
      $resultado.Nombre,
      $resultado.Rutas.Count,
      $resultado.IgnoradasVersionadas,
      $resultado.Ejecutables,
      $resultado.Borradas
    Write-Output $resumenRepositorio
  }
  Push-Location -LiteralPath $padreFactuzam
  try {
    & $ejecutable7Zip `
      'a' `
      '-t7z' `
      "-mx=$NivelCompresion" `
      '-mmt=on' `
      '-scsUTF-8' `
      '-bso0' `
      '-bsp0' `
      $archivoParcial `
      "@$listaTemporal"
    if ($LASTEXITCODE -ne 0) {
      throw "7-Zip no pudo crear el archivo (codigo $LASTEXITCODE)."
    }
    & $ejecutable7Zip `
      't' `
      '-bso0' `
      '-bsp0' `
      $archivoParcial
    if ($LASTEXITCODE -ne 0) {
      throw "7-Zip no pudo verificar el archivo (codigo $LASTEXITCODE)."
    }
  }
  finally {
    Pop-Location
  }
  Move-Item -LiteralPath $archivoParcial -Destination $rutaSalida
  $completado = $true
}
finally {
  if (Test-Path -LiteralPath $listaTemporal) {
    Remove-Item -LiteralPath $listaTemporal -Force
  }
  if (-not $completado -and (Test-Path -LiteralPath $archivoParcial)) {
    Remove-Item -LiteralPath $archivoParcial -Force
  }
}
$archivoFinal = Get-Item -LiteralPath $rutaSalida
$tamanoMiB = [Math]::Round($archivoFinal.Length / 1MB, 2)
Write-Output (
  "Archivo creado y verificado: '$rutaSalida' " +
  "($($rutasArchivo.Count) archivos, $tamanoMiB MiB).")
