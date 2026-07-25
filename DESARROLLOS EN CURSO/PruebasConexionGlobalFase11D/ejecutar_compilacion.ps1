$ErrorActionPreference = 'Stop'

$scriptXiC = Join-Path (
  Split-Path $PSScriptRoot -Parent
) 'PruebasConexionGlobalFase11C\ejecutar_compilacion.ps1'
$logXiD = Join-Path $PSScriptRoot 'resultado_compilacion.txt'

& $scriptXiC `
  -Fase 'XI-D' `
  -PrefijoTemporal 'fzam_fase11d_' `
  -RutaLog $logXiD
