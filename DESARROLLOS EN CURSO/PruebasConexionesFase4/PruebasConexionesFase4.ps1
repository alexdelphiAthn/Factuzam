$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaBase = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaMto = Join-Path $raiz 'src\Forms\inMtoGen.pas'
$rutaBusqueda = Join-Path $raiz 'src\Forms\inMtoGenSearch.pas'
$base = Get-Content -Raw -LiteralPath $rutaBase
$mto = Get-Content -Raw -LiteralPath $rutaMto
$busqueda = Get-Content -Raw -LiteralPath $rutaBusqueda
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

Comprobar ($base -match
    'property ConexionPrincipal: TUniConnection read GetConexionPrincipal') `
  'TfrmBase publica la conexión principal del servicio'
Comprobar ($base -match
    'Application\.MainForm,\s*IProveedorConexiones') `
  'TfrmBase hereda el servicio desde el formulario principal'
Comprobar ($mto -match
    'property ConexionTrabajo: TUniConnection read GetConexionTrabajo') `
  'TfrmMtoGen publica una conexión de trabajo protegida'
Comprobar ($mto -match
    'Result := FConn;\s*if not Assigned\(Result\) then\s*' +
    'Result := ConexionPrincipal') `
  'La conexión propia tiene prioridad sobre la principal'
Comprobar ($mto -notmatch '\boConn\b|\boDmConn\b') `
  'TfrmMtoGen no depende de las conexiones globales'
Comprobar ($busqueda -notmatch '\boConn\b') `
  'TfrmMtoSearch no depende de la conexión global'
Comprobar ($mto -match 'ConnGrabar := ConexionTrabajo') `
  'La grabación genérica usa la conexión de trabajo'
Comprobar ($mto -match 'ConnPerfiles := ConexionPrincipal') `
  'Los perfiles compartidos solicitan la conexión principal'
Comprobar ($busqueda -match 'Conn := ConexionTrabajo') `
  'El alta rápida usa una conexión inyectada'

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
  throw 'Las comprobaciones de la Fase IV no han sido superadas.'
}
