$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaServicio = Join-Path $raiz 'src\Lib\inLibAuditoriaDatos.pas'
$rutaContrato = Join-Path $raiz 'src\Lib\inLibAuditoriaDatosIntf.pas'
$rutaConexion = Join-Path $raiz 'src\DataModules\UniDataConn.pas'
$rutaBaseForm = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaBaseDatos = Join-Path $raiz 'src\DataModules\UniDataGen.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$servicio = Get-Content -Raw -LiteralPath $rutaServicio
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$conexion = Get-Content -Raw -LiteralPath $rutaConexion
$baseForm = Get-Content -Raw -LiteralPath $rutaBaseForm
$baseDatos = Get-Content -Raw -LiteralPath $rutaBaseDatos
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

Comprobar ($contrato -match 'IServicioAuditoriaDatos = interface') `
  'Existe un contrato independiente para la auditoría'
Comprobar ($contrato -match 'IProveedorAuditoriaDatos = interface') `
  'Existe un contrato para publicar el servicio'
Comprobar ($servicio -match
    'constructor Create\(const AUsuario: string\)') `
  'El servicio recibe el usuario mediante el constructor'
Comprobar ($servicio -notmatch
    '\binLibGlobalVar\b|\boUser\b|\bodmConn\b|\boDmConn\b') `
  'La implementación no depende de variables globales'
Comprobar ($conexion -notmatch 'ActualizarUserTimeModif') `
  'TdmConn ha dejado de gestionar la auditoría'
Comprobar ($baseForm -match
    'IProveedorAuditoriaDatos') `
  'TfrmBase publica la auditoría a sus descendientes'
Comprobar ($baseDatos -match
    'Supports\(AOwner, IProveedorAuditoriaDatos') `
  'TdmBase hereda la auditoría de su propietario'
Comprobar ($principal -match
    'TServicioAuditoriaDatos\.Create\(ContextoSesion\)') `
  'La ventana principal compone el servicio con el contexto autenticado'

$fuentes = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.pas'
$textoFuentes = ($fuentes | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName
}) -join "`n"
Comprobar ($textoFuentes -notmatch 'ActualizarUserTimeModif') `
  'No quedan llamadas al método antiguo'

$referenciasGlobales = @(
  Select-String -Path ($fuentes.FullName) `
    -Pattern '\bodmConn\b|\boDmConn\b'
)
Comprobar ($referenciasGlobales.Count -eq 20) `
  'odmConn queda limitado al monitor SQL y a su ciclo de vida'

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
  throw 'Las comprobaciones de la Fase V no han sido superadas.'
}
