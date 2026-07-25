# Compila las tres configuraciones habituales en una carpeta temporal para
# no tocar los ejecutables que el usuario pueda tener abiertos.
param(
  [string]$Fase = 'XI-C',
  [string]$PrefijoTemporal = 'fzam_fase11c_',
  [string]$RutaLog = ''
)

$ErrorActionPreference = 'Continue'
$carpeta = $PSScriptRoot
$raiz = (Resolve-Path (Join-Path $carpeta '..\..')).Path
$proyecto = Join-Path $raiz 'fzam.dproj'
if ($RutaLog -eq '') {
  $rutaLogSalida = Join-Path $carpeta 'resultado_compilacion.txt'
}
else {
  $rutaLogSalida = $RutaLog
}
$temporal = Join-Path $env:TEMP ($PrefijoTemporal + $PID)
$lineas = New-Object System.Collections.Generic.List[string]

function Anotar {
  param([string]$Texto)
  $lineas.Add($Texto)
}

Anotar ('Compilacion Fase ' + $Fase + ' - ' +
  (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Anotar ('Proyecto: ' + $proyecto)
Anotar ('Salida temporal: ' + $temporal)
Anotar ''

$candidatos = @()
foreach ($base in @(
    "${env:ProgramFiles(x86)}\Embarcadero\Studio",
    "$env:ProgramFiles\Embarcadero\Studio")) {
  if (Test-Path -LiteralPath $base) {
    $candidatos += Get-ChildItem -LiteralPath $base -Directory |
      ForEach-Object { Join-Path $_.FullName 'bin\rsvars.bat' } |
      Where-Object { Test-Path -LiteralPath $_ }
  }
}
Anotar 'rsvars.bat encontrados:'
foreach ($candidato in $candidatos) {
  Anotar ('  ' + $candidato)
}
if ($candidatos.Count -eq 0) {
  Anotar 'NO HAY CADENA DE HERRAMIENTAS DELPHI LOCALIZABLE'
  Set-Content -LiteralPath $rutaLogSalida -Value $lineas `
    -Encoding UTF8 -ErrorAction Stop
  throw 'No se ha encontrado rsvars.bat.'
}
$rsvars = $candidatos | Sort-Object {
  [version](Split-Path (
    Split-Path (Split-Path $_ -Parent) -Parent
  ) -Leaf)
} -Descending | Select-Object -First 1
Anotar ('Elegido: ' + $rsvars)
Anotar ''

New-Item -ItemType Directory -Force -Path $temporal | Out-Null
$matriz = @(
  @{ Config = 'Debug';   Plataforma = 'Win64' },
  @{ Config = 'Release'; Plataforma = 'Win32' },
  @{ Config = 'Release'; Plataforma = 'Win64' }
)
$resumen = New-Object System.Collections.Generic.List[string]
$fallos = 0
foreach ($elemento in $matriz) {
  $etiqueta = $elemento.Config + ' ' + $elemento.Plataforma
  $salidaCfg = Join-Path $temporal (
    $elemento.Config + '_' + $elemento.Plataforma
  )
  New-Item -ItemType Directory -Force -Path $salidaCfg | Out-Null
  Anotar '=================================================='
  Anotar ('### ' + $etiqueta)
  $orden = 'call "' + $rsvars + '" && msbuild "' + $proyecto +
    '" /t:Build /p:Config=' + $elemento.Config +
    ' /p:Platform=' + $elemento.Plataforma +
    ' /p:DCC_ExeOutput="' + $salidaCfg + '"' +
    ' /p:DCC_DcuOutput="' + $salidaCfg + '\dcu"' +
    ' /nologo /verbosity:minimal'
  $salida = & cmd.exe /c $orden 2>&1
  $codigo = $LASTEXITCODE
  foreach ($linea in $salida) {
    Anotar ('  ' + $linea)
  }
  $errores = @(
    $salida |
      Select-String -Pattern '\bError\b|\bE\d{4}\b|\bF\d{4}\b'
  )
  if ($codigo -ne 0) {
    $fallos++
  }
  if ($codigo -eq 0) {
    $estado = 'CORRECTA'
  }
  else {
    $estado = 'FALLO'
  }
  $resumen.Add((
    '{0,-16} {1,-9} salida={2} lineas-con-error={3}' -f
      $etiqueta,
      $estado,
      $codigo,
      $errores.Count
  ))
  Anotar ''
}
Anotar '=================================================='
Anotar 'RESUMEN'
foreach ($linea in $resumen) {
  Anotar $linea
}

$tempRaiz = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
$tempSalida = [IO.Path]::GetFullPath($temporal)
if (($tempSalida.StartsWith(
      $tempRaiz,
      [StringComparison]::OrdinalIgnoreCase)) -and
    ((Split-Path $tempSalida -Leaf) -like ($PrefijoTemporal + '*'))) {
  Remove-Item -LiteralPath $tempSalida -Recurse -Force `
    -ErrorAction SilentlyContinue
  Anotar ''
  Anotar 'Artefactos temporales eliminados.'
}
else {
  $fallos++
  Anotar ''
  Anotar 'No se elimina la salida: la ruta temporal no es segura.'
}
Anotar 'FIN'
Set-Content -LiteralPath $rutaLogSalida -Value $lineas `
  -Encoding UTF8 -ErrorAction Stop
if ($fallos -gt 0) {
  throw ('Ha fallado la matriz de compilacion de ' + $Fase + '.')
}
