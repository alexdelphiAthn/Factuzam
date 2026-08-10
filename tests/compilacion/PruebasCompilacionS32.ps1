param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runner = Join-Path $raiz 'eng\compilar.ps1'
$correctas = 0
$fallidas = [System.Collections.Generic.List[string]]::new()

function Probar {
  param(
    [string]$Nombre,
    [scriptblock]$Prueba
  )
  try {
    & $Prueba
    $script:correctas++
    Write-Output "OK  $Nombre"
  }
  catch {
    $script:fallidas.Add("$($Nombre): $($_.Exception.Message)")
    Write-Output "FALLO  $Nombre"
  }
}

function Exigir {
  param(
    [bool]$Condicion,
    [string]$Mensaje
  )
  if (-not $Condicion) {
    throw $Mensaje
  }
}

function Ejecutar-Runner {
  param([string[]]$Argumentos)
  $salida = & pwsh -NoProfile -File $runner @Argumentos 2>&1
  return [pscustomobject]@{
    Codigo = $LASTEXITCODE
    Salida = (($salida | ForEach-Object { $_.ToString() }) -join (
      [Environment]::NewLine))
  }
}

function Con-Entorno {
  param(
    [hashtable]$Valores,
    [scriptblock]$Accion
  )
  $nombres = @(
    'FACTUZAM_DELPHI_ROOT',
    'FACTUZAM_DEVEXPRESS_ROOT',
    'FACTUZAM_FASTREPORT_ROOT',
    'FACTUZAM_UNIDAC_ROOT',
    'BDS'
  )
  $anteriores = @{}
  foreach ($nombre in $nombres) {
    $anteriores[$nombre] = [Environment]::GetEnvironmentVariable(
      $nombre,
      'Process')
    [Environment]::SetEnvironmentVariable($nombre, $null, 'Process')
  }
  try {
    foreach ($nombre in $Valores.Keys) {
      [Environment]::SetEnvironmentVariable(
        $nombre,
        $Valores[$nombre],
        'Process')
    }
    & $Accion
  }
  finally {
    foreach ($nombre in $nombres) {
      [Environment]::SetEnvironmentVariable(
        $nombre,
        $anteriores[$nombre],
        'Process')
    }
  }
}

function Nueva-RaizTemporal {
  $ruta = Join-Path (
    [System.IO.Path]::GetTempPath()) (
    'factuzam_s32_' + [guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path $ruta)
  return $ruta
}

function Eliminar-RaizTemporal {
  param([string]$Ruta)
  $resuelta = [System.IO.Path]::GetFullPath($Ruta)
  $temporal = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::GetTempPath()).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar)
  $prefijo = $temporal + [System.IO.Path]::DirectorySeparatorChar
  $nombre = [System.IO.Path]::GetFileName($resuelta)
  if ((-not $resuelta.StartsWith(
        $prefijo,
        [System.StringComparison]::OrdinalIgnoreCase)) -or
      (-not $nombre.StartsWith(
        'factuzam_s32_',
        [System.StringComparison]::Ordinal))) {
    throw "Ruta temporal S32 no válida: $resuelta."
  }
  if (Test-Path -LiteralPath $resuelta) {
    Remove-Item -LiteralPath $resuelta -Recurse -Force
  }
}

function Crear-ArchivoVacio {
  param([string]$Ruta)
  [void](New-Item -ItemType Directory -Path (
    Split-Path -Parent $Ruta) -Force)
  [System.IO.File]::WriteAllText(
    $Ruta,
    '',
    [System.Text.UTF8Encoding]::new($false))
}

Probar 'El dproj no contiene rutas de máquina' {
  $contenido = [System.IO.File]::ReadAllText(
    (Join-Path $raiz 'fzam.dproj'))
  Exigir ($contenido -notmatch '(?i)\b[A-Z]:\\') (
    'fzam.dproj todavía contiene una ruta absoluta de Windows.')
  Exigir ($contenido -match 'Factuzam\.Dependencias\.props') (
    'fzam.dproj no importa las propiedades compartidas.')
}

Probar 'Las propiedades separan Win32 y Win64' {
  $contenido = [System.IO.File]::ReadAllText(
    (Join-Path $raiz 'eng\Factuzam.Dependencias.props'))
  foreach ($texto in @(
      "Platform)'=='Win32'",
      "Platform)'=='Win64'",
      'FactuzamDependenciasPlataforma',
      'ValidarDependenciasFactuzam')) {
    Exigir ($contenido.Contains($texto)) "Falta $texto en las propiedades."
  }
}

Probar 'El ejemplo no contiene rutas personales' {
  $contenido = [System.IO.File]::ReadAllText(
    (Join-Path $raiz 'eng\dependencias.ejemplo.ps1'))
  Exigir ($contenido -notmatch
    '(?i)\b[A-Z]:\\(?:Users|DISCO_DURO|Program Files)\\') (
    'El ejemplo contiene una ruta propia de una máquina.')
  foreach ($variable in @(
      'FACTUZAM_DELPHI_ROOT',
      'FACTUZAM_DEVEXPRESS_ROOT',
      'FACTUZAM_FASTREPORT_ROOT',
      'FACTUZAM_UNIDAC_ROOT')) {
    Exigir ($contenido.Contains($variable)) "Falta $variable en el ejemplo."
  }
}

Probar 'El runner falla rápido sin dependencias' {
  Con-Entorno @{} {
    $resultado = Ejecutar-Runner @(
      '-SoloValidar',
      '-Plataforma',
      'Ambas')
    Exigir ($resultado.Codigo -eq 2) (
      "Código inesperado: $($resultado.Codigo).")
    foreach ($dependencia in @('Delphi', 'DevExpress', 'FastReport', 'UniDAC')) {
      Exigir ($resultado.Salida.Contains("Falta $dependencia")) (
        "El diagnóstico no menciona $dependencia.")
    }
  }
}

Probar 'El runner acepta ambas plataformas configuradas' {
  $temporal = Nueva-RaizTemporal
  try {
    $delphi = Join-Path $temporal 'delphi'
    $devExpress = Join-Path $temporal 'devexpress'
    $fastReport = Join-Path $temporal 'fastreport'
    $uniDac = Join-Path $temporal 'unidac'
    Crear-ArchivoVacio (Join-Path $delphi 'bin\rsvars.bat')
    Crear-ArchivoVacio (Join-Path $devExpress 'cxClasses.dcu')
    Crear-ArchivoVacio (Join-Path $devExpress 'Win64\cxClasses.dcu')
    Crear-ArchivoVacio (Join-Path $fastReport 'Win32\frxClass.dcu')
    Crear-ArchivoVacio (Join-Path $fastReport 'Win64\frxClass.dcu')
    Crear-ArchivoVacio (Join-Path $uniDac 'Win32\Uni.dcu')
    Crear-ArchivoVacio (Join-Path $uniDac 'Win64\Uni.dcu')
    Con-Entorno @{
      FACTUZAM_DELPHI_ROOT = $delphi
      FACTUZAM_DEVEXPRESS_ROOT = $devExpress
      FACTUZAM_FASTREPORT_ROOT = $fastReport
      FACTUZAM_UNIDAC_ROOT = $uniDac
    } {
      $resultado = Ejecutar-Runner @(
        '-SoloValidar',
        '-Plataforma',
        'Ambas')
      Exigir ($resultado.Codigo -eq 0) $resultado.Salida
      Exigir ($resultado.Salida.Contains('Win32, Win64')) (
        'El runner no confirmó las dos plataformas.')
    }
  }
  finally {
    Eliminar-RaizTemporal $temporal
  }
}

Probar 'El lanzador Release no crea un resultado en la raíz' {
  $contenido = [System.IO.File]::ReadAllText(
    (Join-Path $raiz 'compilar_release_win64.cmd'))
  Exigir ($contenido -notmatch '(?i)resultado_build|set\s+"RAIZ=') (
    'El lanzador conserva una ruta fija o el antiguo resultado.')
  Exigir ($contenido -match
    '(?i)eng\\compilar\.ps1.*Release.*Win64|eng\\compilar\.ps1') (
    'El lanzador no delega en el runner reproducible.')
}

Probar 'CI solicita las dos plataformas' {
  $contenido = [System.IO.File]::ReadAllText(
    (Join-Path $raiz '.github\workflows\calidad.yml'))
  Exigir ($contenido -match '(?i)eng\\compilar\.ps1') (
    'El workflow no usa el runner reproducible.')
  Exigir ($contenido -match '(?i)-Plataforma\s+Ambas') (
    'El workflow no solicita Win32 y Win64.')
}

Write-Output ''
Write-Output (
  "Compilación S32: $correctas correctas; $($fallidas.Count) fallidas.")
if ($fallidas.Count -gt 0) {
  foreach ($fallo in $fallidas) {
    Write-Output "  $fallo"
  }
  exit 1
}
exit 0
