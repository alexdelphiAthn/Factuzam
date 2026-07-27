Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rutaSrc = Join-Path $raiz 'src'

$dependenciasPermitidas = @()

$infracciones = [System.Collections.Generic.List[string]]::new()
$deudaConocida = [System.Collections.Generic.List[string]]::new()
$archivos = Get-ChildItem -LiteralPath $rutaSrc -Recurse -Filter '*.pas' |
  Where-Object {
    $_.FullName -notlike '*\3rdpartyComp\*'
  }

foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $coincidenciaUnidad = [regex]::Match(
    $contenido,
    '(?im)^\s*unit\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;')
  $procesarUnidad = $coincidenciaUnidad.Success
  if ($procesarUnidad) {
    $unidad = $coincidenciaUnidad.Groups[1].Value
    $procesarUnidad = (($unidad -match '^(?i)inLib') -or
                       ($unidad -match '^(?i)UniData'))
  }
  if ($procesarUnidad) {
    $limpio = [regex]::Replace(
      $contenido,
      '(?s)\{.*?\}|\(\*.*?\*\)',
      ' ')
    $limpio = [regex]::Replace($limpio, '(?m)//[^\r\n]*', ' ')
    $limpio = [regex]::Replace($limpio, "'(?:''|[^'])*'", "''")
    $dependencias = [System.Collections.Generic.HashSet[string]]::new(
      [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($bloqueUses in [regex]::Matches(
      $limpio,
      '(?is)\buses\b(.*?);')) {
      foreach ($dependencia in [regex]::Matches(
        $bloqueUses.Groups[1].Value,
        '\b(inMto[A-Za-z0-9_.]*)\b',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        [void]$dependencias.Add($dependencia.Groups[1].Value)
      }
    }
    foreach ($dependencia in $dependencias) {
      $clave = ($unidad + '->' + $dependencia).ToLowerInvariant()
      $relativa = [System.IO.Path]::GetRelativePath(
        $raiz,
        $archivo.FullName)
      $detalle = $unidad + ' -> ' + $dependencia + ' (' + $relativa + ')'
      if ($dependenciasPermitidas -contains $clave) {
        $deudaConocida.Add($detalle)
      }
      else {
        $infracciones.Add($detalle)
      }
    }
  }
}

if ($infracciones.Count -gt 0) {
  Write-Host 'Dependencias de capa no permitidas:'
  foreach ($infraccion in $infracciones) {
    Write-Host ('  ' + $infraccion)
  }
  exit 1
}

Write-Host 'Dependencias de capa: OK.'
if ($deudaConocida.Count -gt 0) {
  Write-Host 'Deuda conocida permitida:'
  foreach ($dependencia in $deudaConocida) {
    Write-Host ('  ' + $dependencia)
  }
}
