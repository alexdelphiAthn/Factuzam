$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaVerifactu = Join-Path $raiz 'src\verifactu\inLibVerifactuCola.pas'
$rutaVentas = Join-Path $raiz 'src\Lib\inLibVentasWsCola.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaServicio = Join-Path $raiz 'src\Lib\inLibConexionesUniDAC.pas'
$rutaProyecto = Join-Path $raiz 'fzam.dpr'

$verifactu = Get-Content -Raw -LiteralPath $rutaVerifactu
$ventas = Get-Content -Raw -LiteralPath $rutaVentas
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$servicio = Get-Content -Raw -LiteralPath $rutaServicio
$proyecto = Get-Content -Raw -LiteralPath $rutaProyecto
$pruebas = 0
$fallos = 0

function Comprobar {
  param(
    [bool]$Condicion,
    [string]$Nombre
  )
  $script:pruebas++
  if ($Condicion) {
    Write-Output "[OK] $Nombre"
  }
  else {
    $script:fallos++
    Write-Output "[ERROR] $Nombre"
  }
}

Comprobar ($verifactu -notmatch '\bCrearConexionPropia\b') `
  'Verifactu no conserva el creador de conexión duplicado'
Comprobar ($ventas -notmatch '\bCrearConexionPropia\b') `
  'Ventas WS no conserva el creador de conexión duplicado'
Comprobar ($verifactu -notmatch '\boConn\b') `
  'El hilo Verifactu no lee la conexión global'
Comprobar ($ventas -notmatch '\boConn\b') `
  'El hilo de ventas WS no lee la conexión global'
Comprobar ($verifactu -match 'FConexiones\.CrearConexion\s*\(\s*nil,\s*' +
    'uctSegundoPlano\s*\)') `
  'Verifactu solicita una conexión de segundo plano'
Comprobar ($ventas -match 'FConexiones\.CrearConexion\s*\(\s*nil,\s*' +
    'uctSegundoPlano\s*\)') `
  'Ventas WS solicita una conexión de segundo plano'
Comprobar ($servicio -match 'uctSegundoPlano:\s*' +
    'AConexion\.AfterConnect := FConexionPrincipal\.AfterConnect') `
  'El servicio conserva el AfterConnect para segundo plano'

$paradaVentas = $principal.IndexOf('TVentasWsCola.DetenerHilo')
$paradaVerifactu = $principal.IndexOf('TVerifactuCola.DetenerHilo')
$invalidacion = $principal.IndexOf('Conexiones.Invalidar')
Comprobar (($paradaVentas -ge 0) -and
    ($paradaVentas -lt $invalidacion)) `
  'Ventas WS se detiene antes de invalidar el servicio'
Comprobar (($paradaVerifactu -ge 0) -and
    ($paradaVerifactu -lt $invalidacion)) `
  'Verifactu se detiene antes de invalidar el servicio'
Comprobar (($proyecto -match 'TVentasWsCola\.DetenerHilo') -and
    ($proyecto -match 'TVerifactuCola\.DetenerHilo')) `
  'La salida garantizada detiene ambas colas'

$dfm = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.dfm'
$dfmConConexion = @()
$enlaces = 0
foreach ($archivo in $dfm) {
  $coincidencias = @(Select-String -LiteralPath $archivo.FullName `
    -SimpleMatch 'Connection = dmConn.conUni')
  if ($coincidencias.Count -gt 0) {
    $dfmConConexion += $archivo
    $enlaces += $coincidencias.Count
  }
}
Comprobar (($dfmConConexion.Count -eq 52) -and ($enlaces -eq 253)) `
  'Se conservan los 253 enlaces persistentes de 52 DFM'

$dfmModificados = @(& git -C $raiz diff --name-only -- '*.dfm')
Comprobar ($dfmModificados.Count -eq 0) `
  'No hay DFM modificados'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase III no han sido superadas.'
}
