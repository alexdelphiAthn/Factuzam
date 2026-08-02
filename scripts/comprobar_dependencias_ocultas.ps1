param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$fallos = [System.Collections.Generic.List[string]]::new()
$rutaSrc = Join-Path $Raiz 'src'
$rutaAdaptadorLog = Join-Path $rutaSrc 'Lib\inLibLog.pas'
$rutaFrmBase = Join-Path $rutaSrc 'Core\inMtoFrmBase.pas'
$archivosPascal = Get-ChildItem `
  -LiteralPath $rutaSrc `
  -Filter '*.pas' `
  -File `
  -Recurse

function Agregar-Coincidencias {
  param(
    [System.IO.FileInfo[]]$Archivos,
    [string]$Patron,
    [string]$Descripcion
  )
  $coincidencias = $Archivos |
    Select-String -Pattern $Patron -CaseSensitive
  foreach ($coincidencia in $coincidencias) {
    $relativa = [System.IO.Path]::GetRelativePath(
      $Raiz,
      $coincidencia.Path)
    $fallos.Add(
      "${Descripcion}: ${relativa}:$($coincidencia.LineNumber)")
  }
}

$consumidoresLogConcreto = @(
  $archivosPascal |
    Where-Object { $_.FullName -ne $rutaAdaptadorLog }
)
Agregar-Coincidencias `
  -Archivos $consumidoresLogConcreto `
  -Patron '\binLibLog\b' `
  -Descripcion 'Dependencia directa del log concreto'
Agregar-Coincidencias `
  -Archivos $archivosPascal `
  -Patron '\boConfigCampos\b' `
  -Descripcion 'Configuración de campos global'

$archivoFrmBase = Get-Item -LiteralPath $rutaFrmBase
Agregar-Coincidencias `
  -Archivos @($archivoFrmBase) `
  -Patron '\bUniData[A-Za-z0-9_]*\b' `
  -Descripcion 'Adaptador UniDAC conocido por TfrmBase'
Agregar-Coincidencias `
  -Archivos @($archivoFrmBase) `
  -Patron 'function\s+TfrmBase\.Crear(?:Repositorio|Servicio|Persistencia)' `
  -Descripcion 'Factoría concreta alojada en TfrmBase'

$contextosEsperados = @(
  'TContextoDependenciasFacturas',
  'TContextoDependenciasOperacionCaja',
  'TContextoDependenciasComprasSesiones',
  'TContextoDependenciasInventario',
  'TContextoDependenciasArticulos',
  'TContextoDependenciasStockConsulta'
)
$textoFuentes = ($archivosPascal | Get-Content -Raw) -join "`n"
foreach ($contexto in $contextosEsperados) {
  if (-not $textoFuentes.Contains($contexto)) {
    $fallos.Add("Falta el contexto específico ${contexto}.")
  }
}

if ($fallos.Count -gt 0) {
  Write-Output 'Dependencias ocultas detectadas:'
  $fallos | ForEach-Object { Write-Output "  $_" }
  exit 1
}
Write-Output (
  'Dependencias ocultas: OK. Log, configuración, factorías y ' +
  'contextos de pantalla comprobados.')
