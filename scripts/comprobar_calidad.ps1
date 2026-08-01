param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ejecutablePowerShell = (Get-Command pwsh).Source
$rutaPropia = $MyInvocation.MyCommand.Path
$rutas = [System.Collections.Generic.List[string]]::new()
$comprobadores = Get-ChildItem `
  -LiteralPath (Join-Path $Raiz 'scripts') `
  -Filter 'comprobar_*.ps1' `
  -File |
    Where-Object { $_.FullName -ne $rutaPropia } |
    Sort-Object Name
foreach ($comprobador in $comprobadores) {
  $rutas.Add($comprobador.FullName)
}
$rutas.Add(
  (Join-Path $Raiz 'tests\PruebasTrinquetesEstilo.ps1'))
$fallos = [System.Collections.Generic.List[string]]::new()
foreach ($ruta in $rutas) {
  $nombre = [System.IO.Path]::GetFileName($ruta)
  Write-Output "=== $nombre ==="
  & $ejecutablePowerShell `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $ruta
  if ($LASTEXITCODE -ne 0) {
    $fallos.Add("${nombre}: código $LASTEXITCODE")
  }
}
if ($fallos.Count -gt 0) {
  Write-Output 'Comprobaciones fallidas:'
  $fallos | ForEach-Object { Write-Output "  $_" }
  exit 1
}
Write-Output (
  'Calidad: OK. Comprobaciones ejecutadas: ' + $rutas.Count + '.')
