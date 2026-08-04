param(
  [string]$RaizProyecto = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Obtener-ClavesSql {
  param([string[]]$Lineas)
  $resultado = [System.Collections.Generic.List[string]]::new()
  for ($indice = 0; $indice -lt $Lineas.Count; $indice++) {
    $linea = $Lineas[$indice]
    if ($linea -match "^  \('([^']*)',") {
      $resultado.Add($Matches[1])
    }
    elseif ($linea -eq '  (CONCAT(') {
      $fragmentos = [System.Collections.Generic.List[string]]::new()
      $indice++
      while (($indice -lt $Lineas.Count) -and
             ($Lineas[$indice] -ne '   ),')) {
        if ($Lineas[$indice] -match "^     '([^']*)'[,]?$") {
          $fragmentos.Add($Matches[1])
        }
        $indice++
      }
      $resultado.Add(($fragmentos -join ''))
    }
  }
  return $resultado
}

$raiz = [System.IO.Path]::GetFullPath($RaizProyecto)
$rutaDesarrollos = Join-Path $raiz 'DESARROLLOS EN CURSO'
$rutaProyecto = Join-Path $raiz 'fzam.dproj'
$rutaGenerador = Join-Path $rutaDesarrollos `
  'generar_traducciones_dfm.ps1'
$contenidoProyecto = [System.IO.File]::ReadAllText($rutaProyecto)
$referenciasPas = [regex]::Matches(
  $contenidoProyecto,
  '<DCCReference Include="([^"]+\.pas)"') |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique
$rutasDfm = [System.Collections.Generic.List[string]]::new()
foreach ($referenciaPas in $referenciasPas) {
  $rutaPas = Join-Path $raiz $referenciaPas
  $rutaDfm = [System.IO.Path]::ChangeExtension($rutaPas, '.dfm')
  if (Test-Path -LiteralPath $rutaDfm) {
    $rutasDfm.Add($rutaDfm)
  }
}

$clavesEsperadas = [System.Collections.Generic.List[string]]::new()
$dfmConClaves = 0
foreach ($rutaDfm in $rutasDfm) {
  $directorioDfm = Split-Path $rutaDfm -Parent
  $nombreDfm = Split-Path $rutaDfm -Leaf
  $lineasGeneradas = @(
    & $rutaGenerador -Ruta $directorioDfm -Patrones $nombreDfm
  )
  $clavesDfm = @(Obtener-ClavesSql -Lineas $lineasGeneradas)
  if ($clavesDfm.Count -gt 0) {
    $dfmConClaves++
    foreach ($clave in $clavesDfm) {
      $clavesEsperadas.Add($clave)
    }
  }
}

$catalogos = Get-ChildItem -LiteralPath $rutaDesarrollos `
  -Filter 'traducciones_d*.sql' |
  Sort-Object Name
$clavesActuales = [System.Collections.Generic.List[string]]::new()
$incidencias = [System.Collections.Generic.List[string]]::new()
foreach ($catalogo in $catalogos) {
  $bytes = [System.IO.File]::ReadAllBytes($catalogo.FullName)
  $tieneBom = ($bytes.Length -ge 3) -and
    ($bytes[0] -eq 239) -and
    ($bytes[1] -eq 187) -and
    ($bytes[2] -eq 191)
  if (-not $tieneBom) {
    $incidencias.Add(
      "$($catalogo.Name): no usa UTF-8 con BOM.")
  }
  $texto = [System.IO.File]::ReadAllText($catalogo.FullName)
  if ([regex]::IsMatch($texto, "(?<!`r)`n")) {
    $incidencias.Add(
      "$($catalogo.Name): contiene saltos LF sin CR.")
  }
  $lineas = [System.IO.File]::ReadAllLines($catalogo.FullName)
  if (($lineas | Where-Object { $_.Length -gt 80 }).Count -gt 0) {
    $incidencias.Add(
      "$($catalogo.Name): contiene líneas de más de 80 columnas.")
  }
  if (($lineas | Where-Object { $_ -match '[ \t]+$' }).Count -gt 0) {
    $incidencias.Add(
      "$($catalogo.Name): contiene espacios finales.")
  }
  $clavesCatalogo = Obtener-ClavesSql -Lineas $lineas
  foreach ($clave in $clavesCatalogo) {
    $clavesActuales.Add($clave)
  }
}

$comparador = [System.StringComparer]::Ordinal
$esperadas = [System.Collections.Generic.HashSet[string]]::new(
  $comparador)
$actuales = [System.Collections.Generic.HashSet[string]]::new(
  $comparador)
foreach ($clave in $clavesEsperadas) {
  [void]$esperadas.Add($clave)
}
foreach ($clave in $clavesActuales) {
  [void]$actuales.Add($clave)
}
$faltantes = [System.Collections.Generic.List[string]]::new()
$sobrantes = [System.Collections.Generic.List[string]]::new()
foreach ($clave in $esperadas) {
  if (-not $actuales.Contains($clave)) {
    $faltantes.Add($clave)
  }
}
foreach ($clave in $actuales) {
  if (-not $esperadas.Contains($clave)) {
    $sobrantes.Add($clave)
  }
}
$duplicadas = @(
  $clavesActuales |
    Group-Object |
    Where-Object { $_.Count -gt 1 }
)
if ($faltantes.Count -gt 0) {
  $incidencias.Add(
    "Faltan $($faltantes.Count) claves esperadas.")
}
if ($sobrantes.Count -gt 0) {
  $incidencias.Add(
    "Sobran $($sobrantes.Count) claves ajenas al proyecto.")
}
if ($duplicadas.Count -gt 0) {
  $incidencias.Add(
    "Hay $($duplicadas.Count) claves duplicadas.")
}
$longitudMaxima = (
  $clavesActuales |
    Measure-Object -Property Length -Maximum
).Maximum
if ($longitudMaxima -gt 255) {
  $incidencias.Add(
    "La clave más larga supera 255 caracteres: $longitudMaxima.")
}
$clavesColecciones = @(
  $clavesActuales |
    Where-Object { $_ -match '\[\d+\]' }
).Count

Write-Output "DFM del proyecto: $($rutasDfm.Count)"
Write-Output "DFM con claves: $dfmConClaves"
Write-Output "Catálogos revisados: $($catalogos.Count)"
Write-Output "Claves esperadas: $($clavesEsperadas.Count)"
Write-Output "Claves catalogadas: $($clavesActuales.Count)"
Write-Output "Claves únicas: $($actuales.Count)"
Write-Output "Claves de colecciones: $clavesColecciones"
Write-Output "Longitud máxima: $longitudMaxima"
Write-Output "Faltantes: $($faltantes.Count)"
Write-Output "Sobrantes: $($sobrantes.Count)"
Write-Output "Duplicadas: $($duplicadas.Count)"

if ($incidencias.Count -gt 0) {
  throw ($incidencias -join [System.Environment]::NewLine)
}
