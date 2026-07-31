param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MinimoPantallas = 52,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MinimoDataModules = 48
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rutaSrc = Join-Path $Raiz 'src'
$rutaDpr = Join-Path $Raiz 'fzam.dpr'
$rutaCatalogo = Join-Path $rutaSrc 'Core\inMtoCatalogoPantallas.pas'
$errores = [System.Collections.Generic.List[string]]::new()
if (Test-Path -LiteralPath $rutaCatalogo -PathType Leaf) {
  $errores.Add(
    'El catálogo central sigue existiendo: ' + $rutaCatalogo + '.')
}
$contenidoDpr = Get-Content -LiteralPath $rutaDpr -Raw
if ($contenidoDpr -match '\binMtoCatalogoPantallas\b') {
  $errores.Add('fzam.dpr sigue enlazando el catálogo central.')
}
$registros = [System.Collections.Generic.List[object]]::new()
$archivos = Get-ChildItem -LiteralPath $rutaSrc `
  -Recurse -Filter '*.pas' -File
$patronRegistro =
  '(?m)^[ \t]*Registrar(?<tipo>Pantalla|DataModule)' +
  '\((?<clase>T[A-Za-z0-9_]+)\);'
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $coincidencias = [regex]::Matches($contenido, $patronRegistro)
  if ($coincidencias.Count -gt 1) {
    $errores.Add(
      'La unidad registra más de una clase: ' + $archivo.FullName + '.')
  }
  foreach ($coincidencia in $coincidencias) {
    $clase = $coincidencia.Groups['clase'].Value
    $tipo = $coincidencia.Groups['tipo'].Value
    if ($contenido -notmatch (
      '(?m)^[ \t]*' + [regex]::Escape($clase) +
      '[ \t]*=[ \t]*class\b')) {
      $errores.Add(
        "El registro de $clase no vive junto a su declaración: " +
        $archivo.FullName + '.')
    }
    if ($contenido -notmatch '\binLibRegistroPantallas\b') {
      $errores.Add(
        'Falta inLibRegistroPantallas en ' + $archivo.FullName + '.')
    }
    $unidad = [regex]::Match(
      $contenido,
      '(?im)^[ \t]*unit[ \t]+(?<unidad>[^;]+);').Groups['unidad'].Value
    if ($contenidoDpr -notmatch (
      '(?im)^[ \t]*' + [regex]::Escape($unidad.Trim()) +
      '[ \t]+in\b')) {
      $errores.Add(
        "La unidad $unidad no está enlazada explícitamente en fzam.dpr.")
    }
    $registros.Add([pscustomobject]@{
      Clase = $clase
      Ruta = [System.IO.Path]::GetRelativePath($Raiz, $archivo.FullName)
      Tipo = $tipo
      Unidad = $unidad.Trim()
    })
  }
}
$pantallas = @($registros | Where-Object { $_.Tipo -eq 'Pantalla' })
$dataModules = @(
  $registros | Where-Object { $_.Tipo -eq 'DataModule' })
if ($pantallas.Count -lt $MinimoPantallas) {
  $errores.Add(
    "Pantallas registradas: $($pantallas.Count); mínimo: $MinimoPantallas.")
}
if ($dataModules.Count -lt $MinimoDataModules) {
  $errores.Add(
    'Data modules registrados: ' + $dataModules.Count +
    "; mínimo: $MinimoDataModules.")
}
$duplicados = @(
  $registros |
    Group-Object Tipo, Clase |
    Where-Object { $_.Count -gt 1 })
foreach ($duplicado in $duplicados) {
  $errores.Add('Registro duplicado: ' + $duplicado.Name + '.')
}
Write-Output (
  'Registro descentralizado: ' + $pantallas.Count + ' pantallas y ' +
  $dataModules.Count + ' data modules.')
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output 'Registro de pantallas: OK.'
