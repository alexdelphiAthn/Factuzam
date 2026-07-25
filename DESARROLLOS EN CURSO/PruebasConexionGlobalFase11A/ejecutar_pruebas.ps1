# Lanza las baterias estructurales de PowerShell de las fases de retirada de
# estado global y deja el resultado en resultado_pruebas.txt.
$ErrorActionPreference = 'Continue'
$carpeta = $PSScriptRoot
$desarrollos = (Resolve-Path (Join-Path $carpeta '..')).Path
$log = Join-Path $carpeta 'resultado_pruebas.txt'

$baterias = @(
  'PruebasConexionGlobalFase11A\PruebasConexionGlobalFase11A.ps1',
  'PruebasContextoSesionFase10D\PruebasContextoSesionFase10D.ps1',
  'PruebasContextoSesionFase10C\PruebasContextoSesionFase10C.ps1',
  'PruebasContextoSesionFase10B\PruebasContextoSesionFase10B.ps1',
  'PruebasContextoSesionFase10A\PruebasContextoSesionFase10A.ps1',
  'PruebasContextoSesionFase8\PruebasContextoSesionFase8.ps1',
  'PruebasPerfilesFase9\PruebasPerfilesFase9.ps1',
  'PruebasFiltrosFase9\PruebasFiltrosFase9.ps1',
  'PruebasConexionesFase7\PruebasConexionesFase7.ps1',
  'PruebasConexionesFase4\PruebasConexionesFase4.ps1',
  'PruebasConexionesFase3\PruebasConexionesFase3.ps1'
)

$lineas = New-Object System.Collections.Generic.List[string]
$lineas.Add('Pruebas estructurales - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$lineas.Add('PowerShell ' + $PSVersionTable.PSVersion.ToString())
$lineas.Add('')
$resumen = New-Object System.Collections.Generic.List[string]

foreach ($relativa in $baterias) {
  $ruta = Join-Path $desarrollos $relativa
  $nombre = Split-Path $relativa -Leaf
  $lineas.Add('==================================================')
  $lineas.Add('### ' + $nombre)
  if (-not (Test-Path -LiteralPath $ruta)) {
    $lineas.Add('  NO ENCONTRADO')
    $resumen.Add(('{0,-42} NO ENCONTRADO' -f $nombre))
    continue
  }
  $salida = & powershell -NoProfile -ExecutionPolicy Bypass -File $ruta 2>&1
  $codigo = $LASTEXITCODE
  foreach ($l in $salida) { $lineas.Add('  ' + $l) }
  $marcador = ($salida | Select-String -Pattern 'Pruebas: \d+ \| Fallos: \d+' |
    Select-Object -Last 1)
  $texto = if ($marcador) { $marcador.Line.Trim() } else { 'sin marcador' }
  $estado = if ($codigo -eq 0) { 'OK' } else { 'FALLO' }
  $resumen.Add(('{0,-42} {1,-6} {2}' -f $nombre, $estado, $texto))
  $lineas.Add('')
}

$lineas.Add('==================================================')
$lineas.Add('RESUMEN')
foreach ($l in $resumen) { $lineas.Add($l) }
$lineas.Add('')
$lineas.Add('FIN')
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
