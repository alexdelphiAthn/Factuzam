Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$proyecto = Join-Path $raiz 'tests\FactuzamConexionTests.dproj'
$plataformas = @('Win32', 'Win64')
$configuracion = 'Debug'

$errores = [System.Collections.Generic.List[string]]::new()
$delphiRoot = $env:FACTUZAM_DELPHI_ROOT
if ([string]::IsNullOrWhiteSpace($delphiRoot)) {
  $delphiRoot = $env:BDS
}
if ([string]::IsNullOrWhiteSpace($delphiRoot)) {
  $errores.Add(
    'Falta Delphi. Defina FACTUZAM_DELPHI_ROOT con la raíz de RAD Studio.')
}

$rsvars = ''
if (-not [string]::IsNullOrWhiteSpace($delphiRoot)) {
  $rsvars = Join-Path $delphiRoot 'bin\rsvars.bat'
  if (-not (Test-Path -LiteralPath $rsvars -PathType Leaf)) {
    $errores.Add("No existe el entorno de Delphi: $rsvars.")
  }
}

$devExpressRoot = $env:FACTUZAM_DEVEXPRESS_ROOT
if ([string]::IsNullOrWhiteSpace($devExpressRoot)) {
  $errores.Add(
    'Falta DevExpress. Defina FACTUZAM_DEVEXPRESS_ROOT; consulte eng\README.md.')
}
$fastReportRoot = $env:FACTUZAM_FASTREPORT_ROOT
if ([string]::IsNullOrWhiteSpace($fastReportRoot)) {
  $errores.Add(
    'Falta FastReport. Defina FACTUZAM_FASTREPORT_ROOT; consulte eng\README.md.')
}
$uniDacRoot = $env:FACTUZAM_UNIDAC_ROOT
if ([string]::IsNullOrWhiteSpace($uniDacRoot)) {
  $errores.Add(
    'Falta UniDAC. Defina FACTUZAM_UNIDAC_ROOT; consulte eng\README.md.')
}
$dunitXRoot = $env:FACTUZAM_DUNITX_ROOT
if ([string]::IsNullOrWhiteSpace($dunitXRoot)) {
  $errores.Add(
    'Falta DUnitX. Defina FACTUZAM_DUNITX_ROOT; consulte eng\README.md.')
}
else {
  $unidadDUnitX = Join-Path $dunitXRoot 'DUnitX.TestFramework.pas'
  if (-not (Test-Path -LiteralPath $unidadDUnitX -PathType Leaf)) {
    $errores.Add("DUnitX.TestFramework.pas no existe en $dunitXRoot.")
  }
}

foreach ($destino in $plataformas) {
  if (-not [string]::IsNullOrWhiteSpace($devExpressRoot)) {
    $rutaDevExpress = if ($destino -eq 'Win32') {
      $devExpressRoot
    }
    else {
      Join-Path $devExpressRoot 'Win64'
    }
    $unidadDevExpress = Join-Path $rutaDevExpress 'cxClasses.dcu'
    if (-not (Test-Path -LiteralPath $unidadDevExpress -PathType Leaf)) {
      $errores.Add(
        "DevExpress no contiene cxClasses.dcu para $($destino): " +
        "$rutaDevExpress.")
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($fastReportRoot)) {
    $rutaFastReport = Join-Path $fastReportRoot $destino
    $unidadFastReport = Join-Path $rutaFastReport 'frxClass.dcu'
    if (-not (Test-Path -LiteralPath $unidadFastReport -PathType Leaf)) {
      $errores.Add(
        "FastReport no contiene frxClass.dcu para $($destino): " +
        "$rutaFastReport.")
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($uniDacRoot)) {
    $rutaUniDac = Join-Path $uniDacRoot $destino
    $unidadUniDac = Join-Path $rutaUniDac 'Uni.dcu'
    if (-not (Test-Path -LiteralPath $unidadUniDac -PathType Leaf)) {
      $errores.Add(
        "UniDAC no contiene Uni.dcu para $($destino): $rutaUniDac.")
    }
  }
}

$msbuild = ''
$candidatos = @(
  (Join-Path $env:SystemRoot (
    'Microsoft.NET\Framework\v4.0.30319\MSBuild.exe')),
  (Join-Path $env:SystemRoot (
    'Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe'))
)
foreach ($candidato in $candidatos) {
  if (([string]::IsNullOrWhiteSpace($msbuild)) -and
      (Test-Path -LiteralPath $candidato -PathType Leaf)) {
    $msbuild = $candidato
  }
}
if ([string]::IsNullOrWhiteSpace($msbuild)) {
  $comandoMsBuild = Get-Command 'MSBuild.exe' -ErrorAction SilentlyContinue
  if ($null -ne $comandoMsBuild) {
    $msbuild = $comandoMsBuild.Source
  }
}
if ([string]::IsNullOrWhiteSpace($msbuild)) {
  $errores.Add(
    'No se encontró MSBuild.exe. Instale .NET Framework o añádalo a PATH.')
}

if ($errores.Count -gt 0) {
  Write-Output 'No se pueden ejecutar las pruebas de conexión:'
  foreach ($errorDependencia in $errores) {
    Write-Output "  - $errorDependencia"
  }
  exit 2
}

Write-Output (
  'Dependencias de pruebas: OK. Plataformas: ' +
  ($plataformas -join ', ') + '.')

foreach ($destino in $plataformas) {
  $salidaDcu = Join-Path $raiz (
    "build\reproducible\tests\dcu\$destino\$configuracion")
  $salidaExe = Join-Path $raiz (
    "build\reproducible\tests\bin\$destino\$configuracion")
  [void](New-Item -ItemType Directory -Path $salidaDcu -Force)
  [void](New-Item -ItemType Directory -Path $salidaExe -Force)

  Write-Output (
    "Compilando pruebas de conexión $configuracion $destino...")
  $argumentos = @(
    '"' + $proyecto + '"',
    '/t:Build',
    "/p:Config=$configuracion",
    "/p:Platform=$destino",
    '/p:DCC_DcuOutput="' + $salidaDcu + '"',
    '/p:DCC_ExeOutput="' + $salidaExe + '"',
    '/nologo',
    '/verbosity:minimal'
  )
  $orden = 'call "' + $rsvars + '" && "' + $msbuild + '" ' +
    ($argumentos -join ' ')
  & $env:ComSpec /d /s /c $orden
  if ($LASTEXITCODE -ne 0) {
    Write-Output (
      "Compilación fallida: $configuracion $destino " +
      "(código $LASTEXITCODE).")
    exit 1
  }

  $ejecutable = Join-Path $salidaExe 'FactuzamConexionTests.exe'
  if (-not (Test-Path -LiteralPath $ejecutable -PathType Leaf)) {
    Write-Output "No se generó el ejecutable de pruebas: $ejecutable."
    exit 2
  }

  Write-Output "Ejecutando pruebas de conexión $destino..."
  & $ejecutable
  $codigoPruebas = $LASTEXITCODE
  if ($codigoPruebas -eq 1) {
    Write-Output "Hay pruebas fallidas en $destino."
    exit 1
  }
  if ($codigoPruebas -ne 0) {
    Write-Output (
      "El runner de $destino terminó con código $codigoPruebas.")
    exit 2
  }
  Write-Output "Pruebas correctas: $destino."
}

exit 0
