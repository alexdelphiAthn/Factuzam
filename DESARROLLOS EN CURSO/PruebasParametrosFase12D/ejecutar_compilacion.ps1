param(
  [string]$RaizRepositorio = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Continue'
$proyecto = Join-Path $RaizRepositorio 'fzam.dproj'
$log = Join-Path $PSScriptRoot 'resultado_compilacion.txt'
$raizTemporal = [System.IO.Path]::GetFullPath($env:TEMP)
$temporal = Join-Path $raizTemporal ('fzam_fase12d_' + $PID)
$lineas = [System.Collections.Generic.List[string]]::new()
$hayFallos = $false
function Anotar {
  param([string]$Texto)
  $lineas.Add($Texto)
}
Anotar ('Compilación Fase XII-D - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Anotar ('Proyecto: ' + $proyecto)
Anotar ('Salida temporal: ' + $temporal)
Anotar ''
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
Anotar 'rsvars.bat encontrados:'
foreach ($candidato in $candidatos) {
  Anotar ('  ' + $candidato)
}
if ($candidatos.Count -eq 0) {
  Anotar 'NO HAY CADENA DE HERRAMIENTAS DELPHI LOCALIZABLE'
  Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
  exit 1
}
$rsvars = $candidatos | Sort-Object {
  [double](
    Split-Path (
      Split-Path (
        Split-Path $_ -Parent
      ) -Parent
    ) -Leaf
  )
} -Descending | Select-Object -First 1
Anotar ('Elegido: ' + $rsvars)
Anotar ''
New-Item -ItemType Directory -Force -Path $temporal | Out-Null
$temporalResuelto = (Resolve-Path -LiteralPath $temporal).Path
$prefijoSeguro = $raizTemporal.TrimEnd('\') + '\fzam_fase12d_'
if (-not $temporalResuelto.StartsWith(
  $prefijoSeguro,
  [System.StringComparison]::OrdinalIgnoreCase
)) {
  throw "Directorio temporal no seguro: $temporalResuelto"
}
$matriz = @(
  @{ Configuracion = 'Debug'; Plataforma = 'Win64' },
  @{ Configuracion = 'Release'; Plataforma = 'Win32' },
  @{ Configuracion = 'Release'; Plataforma = 'Win64' }
)
$resumen = [System.Collections.Generic.List[string]]::new()
foreach ($elemento in $matriz) {
  $etiqueta = $elemento.Configuracion + ' ' + $elemento.Plataforma
  $salidaConfiguracion = Join-Path $temporal (
    $elemento.Configuracion + '_' + $elemento.Plataforma
  )
  New-Item -ItemType Directory -Force -Path $salidaConfiguracion |
    Out-Null
  Anotar '=================================================='
  Anotar ('### ' + $etiqueta)
  $orden = 'call "' + $rsvars + '" && msbuild "' + $proyecto +
    '" /t:Build /p:Config=' + $elemento.Configuracion +
    ' /p:Platform=' + $elemento.Plataforma +
    ' /p:DCC_ExeOutput="' + $salidaConfiguracion + '"' +
    ' /p:DCC_DcuOutput="' + $salidaConfiguracion + '\dcu"' +
    ' /nologo /verbosity:minimal'
  $salida = & cmd.exe /c $orden 2>&1
  $codigo = $LASTEXITCODE
  foreach ($linea in $salida) {
    Anotar ('  ' + $linea)
  }
  $errores = @(
    $salida | Select-String -Pattern '\berror [EF]\d{4}\b'
  )
  $avisos = @(
    $salida | Select-String -Pattern '\b(?:Hint )?warning [WH]\d{4}\b'
  )
  $obsoletos = @(
    $salida | Select-String -Pattern '(?i)deprecated|obsoleto'
  )
  $estado = 'CORRECTA'
  if (($codigo -ne 0) -or ($obsoletos.Count -gt 0)) {
    $estado = 'FALLO'
    $hayFallos = $true
  }
  $resumen.Add((
    '{0,-16} {1,-9} salida={2} errores={3} avisos={4} deprecated={5}' -f
    $etiqueta,
    $estado,
    $codigo,
    $errores.Count,
    $avisos.Count,
    $obsoletos.Count
  ))
  Anotar ''
}
Anotar '=================================================='
Anotar 'RESUMEN'
foreach ($linea in $resumen) {
  Anotar $linea
}
if ($temporalResuelto.StartsWith(
  $prefijoSeguro,
  [System.StringComparison]::OrdinalIgnoreCase
)) {
  [System.IO.Directory]::Delete($temporalResuelto, $true)
  Anotar ''
  Anotar 'Artefactos temporales eliminados.'
}
else {
  Anotar ''
  Anotar 'No se elimina el directorio temporal porque no es seguro.'
  $hayFallos = $true
}
Anotar 'FIN'
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
if ($hayFallos) {
  exit 1
}
