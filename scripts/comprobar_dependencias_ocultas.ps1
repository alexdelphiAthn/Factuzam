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
$archivosPropios = @(
  $archivosPascal |
    Where-Object { $_.FullName -notmatch '\\3rdpartyComp\\' }
)
$archivosPresentacion = @(
  $archivosPropios |
    Where-Object {
      $_.FullName -match '\\(?:Core|Forms|Modals)\\'
    }
)

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

function Agregar-CoincidenciasTexto {
  param(
    [System.IO.FileInfo[]]$Archivos,
    [string]$Patron,
    [string]$Descripcion
  )
  foreach ($archivo in $Archivos) {
    $texto = Get-Content -LiteralPath $archivo.FullName -Raw
    $coincidencias = [regex]::Matches($texto, $Patron)
    foreach ($coincidencia in $coincidencias) {
      $prefijo = $texto.Substring(0, $coincidencia.Index)
      $linea = ([regex]::Matches($prefijo, "`n")).Count + 1
      $relativa = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
      $fallos.Add("${Descripcion}: ${relativa}:${linea}")
    }
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

Agregar-Coincidencias `
  -Archivos $archivosPropios `
  -Patron '\bBuscarCompositor\b' `
  -Descripcion 'Localizador de compositor de pantalla'
Agregar-Coincidencias `
  -Archivos $archivosPropios `
  -Patron '\bObtenerCompositor[A-Za-z0-9_]*Pantalla\b' `
  -Descripcion 'Acceso global a compositor de pantalla'
Agregar-Coincidencias `
  -Archivos $archivosPropios `
  -Patron '\bICompositor[A-Za-z0-9_]*Pantalla\b' `
  -Descripcion 'Contrato de compositor de pantalla obsoleto'
Agregar-Coincidencias `
  -Archivos $archivosPresentacion `
  -Patron (
    '\bF[A-Za-z0-9_]*\s*:\s*' +
    'IRepositorios[A-Za-z0-9_]*Pantalla\b') `
  -Descripcion 'Familia amplia de repositorios almacenada en presentación'
Agregar-Coincidencias `
  -Archivos $archivosPropios `
  -Patron '\bOwner\.FindComponent\s*\(' `
  -Descripcion 'Resolución de dependencia mediante Owner.FindComponent'
Agregar-Coincidencias `
  -Archivos $archivosPropios `
  -Patron '\.GetInterface\s*\(' `
  -Descripcion 'Resolución de dependencia mediante GetInterface'
Agregar-CoincidenciasTexto `
  -Archivos $archivosPropios `
  -Patron (
    '(?is)Supports\s*\(\s*Application\.MainForm\s*,\s*' +
    'I(?:Repositorios|Compositor)[A-Za-z0-9_]*Pantalla\b') `
  -Descripcion 'Repositorio de feature resuelto desde Application.MainForm'

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
  'Dependencias ocultas: OK. Log, configuración, factorías, ' +
  'localizadores y contextos de pantalla comprobados.')
