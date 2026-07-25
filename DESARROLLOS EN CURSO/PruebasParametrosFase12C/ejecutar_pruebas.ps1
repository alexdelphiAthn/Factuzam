param(
  [string]$RaizRepositorio = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Continue'
$log = Join-Path $PSScriptRoot 'resultado_pruebas.txt'
$lineas = [System.Collections.Generic.List[string]]::new()
$hayFallos = $false
function Anotar {
  param([string]$Texto)
  $lineas.Add($Texto)
  Write-Output $Texto
}
Anotar ('Pruebas Fase XII-C - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Anotar ''
Anotar '### Regresión XII-A'
$scriptFaseA = Join-Path $RaizRepositorio (
  'DESARROLLOS EN CURSO\PruebasParametrosFase12A\ejecutar_pruebas.ps1'
)
$salidaFaseA = & $scriptFaseA -RaizRepositorio $RaizRepositorio 2>&1
$codigoFaseA = $LASTEXITCODE
foreach ($linea in $salidaFaseA) {
  Anotar ('  ' + $linea)
}
if ($codigoFaseA -ne 0) {
  $hayFallos = $true
}
Anotar ''
Anotar '### Estructura XII-C'
$salidaEstructura = & (
  Join-Path $PSScriptRoot 'probar_estructura.ps1'
) -RaizRepositorio $RaizRepositorio 2>&1
$codigoEstructura = $LASTEXITCODE
foreach ($linea in $salidaEstructura) {
  Anotar ('  ' + $linea)
}
if ($codigoEstructura -ne 0) {
  $hayFallos = $true
}
Anotar ''
if ($hayFallos) {
  Anotar 'RESULTADO GLOBAL: FALLO'
  Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
  exit 1
}
Anotar 'RESULTADO GLOBAL: CORRECTO'
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
exit 0
