$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaContrato = Join-Path $raiz 'src\Lib\inLibMonitorSQLIntf.pas'
$rutaServicio = Join-Path $raiz 'src\Lib\inLibMonitorSQLUniDAC.pas'
$rutaLog = Join-Path $raiz 'src\Lib\inLibLog.pas'
$rutaGlobales = Join-Path $raiz 'src\Lib\inLibGlobalVar.pas'
$rutaConexion = Join-Path $raiz 'src\DataModules\UniDataConn.pas'
$rutaBase = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$servicio = Get-Content -Raw -LiteralPath $rutaServicio
$log = Get-Content -Raw -LiteralPath $rutaLog
$globales = Get-Content -Raw -LiteralPath $rutaGlobales
$conexion = Get-Content -Raw -LiteralPath $rutaConexion
$base = Get-Content -Raw -LiteralPath $rutaBase
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
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

Comprobar ($contrato -match 'IServicioMonitorSQL = interface') `
  'Existe el contrato de control del monitor'
Comprobar ($contrato -match 'IReceptorEventosMonitorSQL = interface') `
  'La recepción de eventos tiene un contrato separado'
Comprobar ($contrato -match 'IRegistroMonitorSQL = interface') `
  'El registro de trazas está abstraído para poder probarlo'
Comprobar ($servicio -notmatch
    '\binLibGlobalVar\b|\bTdmConn\b|\bodmConn\b') `
  'La implementación no depende de globals ni de TdmConn'
Comprobar ($conexion -notmatch
    'FSQLPendiente|FSQLActual|FSQLStartMs|CerrarSQLPendiente') `
  'TdmConn ya no contiene el estado ni el cierre del monitor'
Comprobar ($conexion -match
    'FReceptorMonitorSQL\.ProcesarEvento\(Text, Evento\)') `
  'El evento persistente de UniDAC actúa como puente'
Comprobar ($base -match 'IProveedorMonitorSQL') `
  'TfrmBase publica el servicio a sus descendientes'
Comprobar ($log -match
    'FMonitorSQL\.EstablecerActivo\(bSQLFinal\)') `
  'TLog controla la activación mediante la interfaz'
Comprobar ($principal -match
    'TServicioMonitorSQLUniDAC\.Create') `
  'La ventana principal compone el servicio'
Comprobar ($globales -notmatch
    '\bodmConn\b|\bUniDataConn\b') `
  'El estado global ya no declara odmConn ni depende de UniDataConn'

$fuentes = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.pas'
$textoFuentes = ($fuentes | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName
}) -join "`n"
Comprobar ($textoFuentes -notmatch '\bodmConn\b|\boDmConn\b') `
  'No quedan referencias a odmConn en src'

$cierres = @(
  Select-String -Path ($fuentes.FullName) `
    -Pattern '^\s*CerrarMonitorSQLPendiente;'
)
Comprobar ($cierres.Count -eq 5) `
  'Los cinco formularios de Caja usan el servicio heredado'

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
  throw 'Las comprobaciones de la Fase VI no han sido superadas.'
}
