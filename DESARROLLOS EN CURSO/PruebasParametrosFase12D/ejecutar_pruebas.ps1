param(
  [string]$RaizRepositorio = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Continue'
$log = Join-Path $PSScriptRoot 'resultado_pruebas.txt'
$raizTemporal = [System.IO.Path]::GetFullPath($env:TEMP)
$temporal = Join-Path $raizTemporal ('fzam_fase12d_pruebas_' + $PID)
$lineas = [System.Collections.Generic.List[string]]::new()
$hayFallos = $false
function Anotar {
  param([string]$Texto)
  $lineas.Add($Texto)
  Write-Output $Texto
}
function EjecutarControl {
  param(
    [string]$Titulo,
    [string]$Script
  )
  Anotar ('### ' + $Titulo)
  $salida = & $Script -RaizRepositorio $RaizRepositorio 2>&1
  $codigo = $LASTEXITCODE
  foreach ($linea in $salida) {
    Anotar ('  ' + $linea)
  }
  if ($codigo -ne 0) {
    $script:hayFallos = $true
  }
  Anotar ''
}
Anotar ('Pruebas Fase XII-D - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Anotar ''
EjecutarControl 'Regresión estructural XII-C' (
  Join-Path $RaizRepositorio (
    'DESARROLLOS EN CURSO\PruebasParametrosFase12C\' +
    'probar_estructura.ps1'
  )
)
EjecutarControl 'Estructura XII-D' (
  Join-Path $PSScriptRoot 'probar_estructura.ps1'
)
$baseStudio = "${env:ProgramFiles(x86)}\Embarcadero\Studio"
$candidatos = @()
if (Test-Path -LiteralPath $baseStudio) {
  $candidatos = @(
    Get-ChildItem -LiteralPath $baseStudio -Directory |
      ForEach-Object {
        Join-Path $_.FullName 'bin\rsvars.bat'
      } |
      Where-Object {
        Test-Path -LiteralPath $_
      }
  )
}
if ($candidatos.Count -eq 0) {
  Anotar 'FALLO: no se encontró la cadena de herramientas Delphi.'
  $hayFallos = $true
}
else {
  $rsvars = $candidatos | Sort-Object {
    [double](
      Split-Path (
        Split-Path (
          Split-Path $_ -Parent
        ) -Parent
      ) -Leaf
    )
  } -Descending | Select-Object -First 1
  New-Item -ItemType Directory -Path $temporal -Force | Out-Null
  $dpr = Join-Path $RaizRepositorio (
    'DESARROLLOS EN CURSO\PruebasParametrosFase12A\' +
    'PruebasParametrosBase.dpr'
  )
  $rutaLib = Join-Path $RaizRepositorio 'src\Lib'
  $rutaCajaLib = Join-Path $RaizRepositorio 'src\Caja\Lib'
  foreach ($plataforma in @('Win32', 'Win64')) {
    Anotar "### Regresión unitaria XII-A $plataforma"
    $salidaPlataforma = Join-Path $temporal $plataforma
    New-Item -ItemType Directory -Path $salidaPlataforma -Force |
      Out-Null
    $compilador = 'dcc32'
    if ($plataforma -eq 'Win64') {
      $compilador = 'dcc64'
    }
    $orden = 'call "' + $rsvars + '" && ' + $compilador +
      ' -B -Q -U"' + $rutaLib + ';' + $rutaCajaLib + '"' +
      ' -E"' + $salidaPlataforma + '"' +
      ' -N0"' + $salidaPlataforma + '"' +
      ' "' + $dpr + '"'
    $salidaCompilacion = & cmd.exe /c $orden 2>&1
    $codigoCompilacion = $LASTEXITCODE
    foreach ($linea in $salidaCompilacion) {
      Anotar ('  ' + $linea)
    }
    if ($codigoCompilacion -ne 0) {
      Anotar "  FALLO DE COMPILACIÓN $plataforma"
      $hayFallos = $true
    }
    else {
      $ejecutable = Join-Path $salidaPlataforma (
        'PruebasParametrosBase.exe'
      )
      $salidaEjecucion = & $ejecutable 2>&1
      $codigoEjecucion = $LASTEXITCODE
      foreach ($linea in $salidaEjecucion) {
        Anotar ('  ' + $linea)
      }
      if ($codigoEjecucion -ne 0) {
        Anotar "  FALLO DE EJECUCIÓN $plataforma"
        $hayFallos = $true
      }
    }
    Anotar ''
  }
  $temporalResuelto = (Resolve-Path -LiteralPath $temporal).Path
  $prefijoSeguro = $raizTemporal.TrimEnd('\') +
    '\fzam_fase12d_pruebas_'
  if ($temporalResuelto.StartsWith(
    $prefijoSeguro,
    [System.StringComparison]::OrdinalIgnoreCase
  )) {
    [System.IO.Directory]::Delete($temporalResuelto, $true)
  }
  else {
    Anotar "FALLO: directorio temporal no seguro: $temporalResuelto"
    $hayFallos = $true
  }
}
if ($hayFallos) {
  Anotar 'RESULTADO GLOBAL: FALLO'
  Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
  exit 1
}
Anotar 'RESULTADO GLOBAL: CORRECTO'
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
exit 0
