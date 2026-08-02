param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [string]$RutaRsVars = $env:FACTUZAM_RSVARS,
  [ValidateSet('Debug', 'Release')]
  [string]$Configuracion = 'Release',
  [ValidateSet('Win32', 'Win64')]
  [string[]]$Plataformas = @('Win32', 'Win64'),
  [switch]$OmitirCalidad
)

# Entrada automatizada para un equipo o runner que tenga Delphi instalado.
# Ejecuta los trinquetes, compila fzam y compila y ejecuta DUnitX.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolver-RsVars {
  param([string]$RutaIndicada)
  if (-not [string]::IsNullOrWhiteSpace($RutaIndicada)) {
    if (-not (Test-Path -LiteralPath $RutaIndicada -PathType Leaf)) {
      throw "No se encontro rsvars.bat: $RutaIndicada."
    }
    return (Resolve-Path -LiteralPath $RutaIndicada).Path
  }
  $rutaStudio = 'C:\Program Files (x86)\Embarcadero\Studio'
  if (-not (Test-Path -LiteralPath $rutaStudio -PathType Container)) {
    throw (
      'No se encontro Delphi. Indique FACTUZAM_RSVARS o use ' +
      'el parametro -RutaRsVars.')
  }
  $candidatos = @(
    Get-ChildItem -LiteralPath $rutaStudio -Directory |
      Sort-Object {
        try {
          return [version]$_.Name
        }
        catch {
          return [version]'0.0'
        }
      } -Descending |
      ForEach-Object {
        Join-Path $_.FullName 'bin\rsvars.bat'
      } |
      Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
      }
  )
  if ($candidatos.Count -eq 0) {
    throw (
      'No se encontro rsvars.bat. Indique FACTUZAM_RSVARS o use ' +
      'el parametro -RutaRsVars.')
  }
  return $candidatos[0]
}

function Ejecutar-PowerShell {
  param([string]$RutaScript)
  $ejecutable = (Get-Command pwsh).Source
  & $ejecutable `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $RutaScript
  if ($LASTEXITCODE -ne 0) {
    throw (
      "Fallo $([IO.Path]::GetFileName($RutaScript)): " +
      "codigo $LASTEXITCODE.")
  }
}

function Compilar-Proyecto {
  param(
    [string]$RsVars,
    [string]$Proyecto,
    [string]$Plataforma,
    [string]$Config,
    [string]$Descripcion
  )
  $comando = (
    'call "{0}" && msbuild "{1}" /t:Build /p:Config={2} ' +
    '/p:Platform={3} /nologo /verbosity:minimal'
  ) -f $RsVars, $Proyecto, $Config, $Plataforma
  & $env:ComSpec /d /s /c $comando
  if ($LASTEXITCODE -ne 0) {
    throw (
      "Fallo al compilar $Descripcion $Plataforma/${Config}: " +
      "codigo $LASTEXITCODE.")
  }
}

function Ejecutar-Bateria {
  param([string]$RutaEjecutable)
  if (-not (Test-Path -LiteralPath $RutaEjecutable -PathType Leaf)) {
    throw "No se genero el ejecutable de pruebas: $RutaEjecutable."
  }
  & $RutaEjecutable
  if ($LASTEXITCODE -ne 0) {
    throw (
      "Fallo la bateria ${RutaEjecutable}: codigo $LASTEXITCODE.")
  }
}

$rutaAplicacion = Join-Path $Raiz 'fzam.dproj'
$rutaPruebas = Join-Path $Raiz 'tests\FactuzamTests.dproj'
if (-not (Test-Path -LiteralPath $rutaAplicacion -PathType Leaf)) {
  throw "No se encontro el proyecto principal: $rutaAplicacion."
}
if (-not (Test-Path -LiteralPath $rutaPruebas -PathType Leaf)) {
  throw "No se encontro el proyecto de pruebas: $rutaPruebas."
}
if (-not $OmitirCalidad) {
  Ejecutar-PowerShell `
    -RutaScript (Join-Path $Raiz 'scripts\comprobar_calidad.ps1')
}
$rsVars = Resolver-RsVars -RutaIndicada $RutaRsVars
foreach ($plataforma in $Plataformas) {
  Write-Output (
    "=== fzam $plataforma/$Configuracion ===")
  Compilar-Proyecto `
    -RsVars $rsVars `
    -Proyecto $rutaAplicacion `
    -Plataforma $plataforma `
    -Config $Configuracion `
    -Descripcion 'fzam'
  Write-Output (
    "=== DUnitX $plataforma/$Configuracion ===")
  Compilar-Proyecto `
    -RsVars $rsVars `
    -Proyecto $rutaPruebas `
    -Plataforma $plataforma `
    -Config $Configuracion `
    -Descripcion 'DUnitX'
  $rutaEjecutable = Join-Path `
    $Raiz `
    "tests\bin\$plataforma\$Configuracion\FactuzamTests.exe"
  Ejecutar-Bateria -RutaEjecutable $rutaEjecutable
}
Write-Output (
  'Validacion Delphi: OK. Plataformas: ' +
  ($Plataformas -join ', ') +
  ". Configuracion: $Configuracion.")
