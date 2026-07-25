$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaBaseForm = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaBaseDatos = Join-Path $raiz 'src\DataModules\UniDataGen.pas'
$rutaCaja = Join-Path $raiz 'src\Caja\DataModules\UniDataCaja.pas'
$rutaTraspaso = Join-Path $raiz 'src\Caja\DataModules\UniDataTraspaso.pas'
$rutaStock = Join-Path $raiz 'src\Forms\inMtoStockConsulta.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaMtoGen = Join-Path $raiz 'src\Forms\inMtoGen.pas'
$rutaCajaForm = Join-Path $raiz 'src\Caja\Forms\inMtoCajaOpe.pas'
$rutaAdaptador = Join-Path $raiz 'src\Lib\inLibContextoSesionGlobal.pas'
$baseForm = Get-Content -Raw -LiteralPath $rutaBaseForm
$baseDatos = Get-Content -Raw -LiteralPath $rutaBaseDatos
$caja = Get-Content -Raw -LiteralPath $rutaCaja
$traspaso = Get-Content -Raw -LiteralPath $rutaTraspaso
$stock = Get-Content -Raw -LiteralPath $rutaStock
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$mtoGen = Get-Content -Raw -LiteralPath $rutaMtoGen
$cajaForm = Get-Content -Raw -LiteralPath $rutaCajaForm
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

Comprobar (
    ($baseForm -match
      'property IdentidadSesion: TIdentidadSesion') -and
    ($baseForm -match
      'property UbicacionSesion: TUbicacionSesion') -and
    ($baseForm -match
      'Result := FContextoSesion\.Identidad') -and
    ($baseForm -match
      'Result := FContextoSesion\.Ubicacion')
  ) 'TfrmBase publica instantáneas tipadas de la sesión'
Comprobar (
    ($baseDatos -match
      'property IdentidadSesion: TIdentidadSesion') -and
    ($baseDatos -match
      'property UbicacionSesion: TUbicacionSesion') -and
    ($baseDatos -match
      'Result := FContextoSesion\.Identidad') -and
    ($baseDatos -match
      'Result := FContextoSesion\.Ubicacion')
  ) 'TdmBase publica instantáneas tipadas de la sesión'

$rutasVisualesDatos = @(
  'src\Core',
  'src\Forms',
  'src\Modals',
  'src\Caja\Forms',
  'src\Caja\Modals',
  'src\DataModules',
  'src\Caja\DataModules'
)
$archivosVisualesDatos = @(
  foreach ($ruta in $rutasVisualesDatos) {
    Get-ChildItem -LiteralPath (Join-Path $raiz $ruta) -Filter '*.pas'
  }
)
$patronGlobalSesion =
  '\b(oUser|oGroup|oRootGroup|oEmpresa|oAlmacen|oCaja)\b'
$referenciasGlobales = @(
  Select-String -Path $archivosVisualesDatos.FullName `
    -Pattern $patronGlobalSesion
)
Comprobar ($referenciasGlobales.Count -eq 0) `
  'Formularios y DataModules no leen variables globales de sesión'

$referenciasIdentidad = @(
  Select-String -Path $archivosVisualesDatos.FullName `
    -Pattern '\bIdentidadSesion\b'
)
$referenciasUbicacion = @(
  Select-String -Path $archivosVisualesDatos.FullName `
    -Pattern '\bUbicacionSesion\b'
)
Comprobar (
    ($referenciasIdentidad.Count -ge 300) -and
    ($referenciasUbicacion.Count -ge 90)
  ) 'Los consumidores usan identidad y ubicación tipadas'

Comprobar (
    ($caja -match
      'FContextoSesion: IContextoSesionAplicacion') -and
    ($caja -match
      'procedure AsignarContextoSesion\(') -and
    ($caja -match
      'IdentidadSesion\.Usuario')
  ) 'El DataModule de caja recibe el contexto sin cambiar su herencia'
Comprobar (
    ($traspaso -match
      'FContextoSesion: IContextoSesionAplicacion') -and
    ($traspaso -match
      'Supports\(AOwner, IProveedorContextoSesion') -and
    ($traspaso -match
      'IdentidadSesion\.Usuario')
  ) 'El DataModule de traspasos hereda el contexto de su propietario'
Comprobar (
    ($stock -match
      'const AContextoSesion:\s*IContextoSesionAplicacion') -and
    ($stock -match
      'FContextoSesion := AContextoSesion') -and
    ($stock -notmatch $patronGlobalSesion)
  ) 'La consulta de stock recibe el contexto explícitamente'
Comprobar (
    ($principal -match
      'MostrarStockConsulta\(\s*LForm,\s*Permisos,\s*' +
      'PerfilesUsuario,\s*ContextoSesion') -and
    ($mtoGen -match
      'MostrarStockConsulta\(\s*Self,\s*Permisos,\s*' +
      'PerfilesUsuario,\s*ContextoSesion') -and
    ($cajaForm -match
      'MostrarStockConsulta\(\s*Self,\s*Permisos,\s*' +
      'PerfilesUsuario,\s*ContextoSesion')
  ) 'Los tres puntos de apertura entregan el contexto al stock'

$sinDependenciaGlobal = @(
  'src\DataModules/UniDataIvas.pas',
  'src/DataModules/UniDataTarifas.pas',
  'src/DataModules/UniDataTarifasCambios.pas',
  'src/Forms/inMtoAlbaranes.pas',
  'src/Forms/inMtoDocumentosTrabajo.pas',
  'src/Forms/inMtoPedidos.pas',
  'src/Forms/inMtoRemesasVenta.pas',
  'src/Modals/inMtoModalAddBlockDocumentoTrabajo.pas',
  'src/Modals/inMtoModalAddBlockInventario.pas',
  'src/Modals/inMtoModalAddBlockTarifa.pas',
  'src/Modals/inMtoModalCalcularMargen.pas',
  'src/Modals/inMtoModalCargarSesionTarifa.pas'
)
$importsGlobales = @(
  Select-String -LiteralPath (
    $sinDependenciaGlobal |
      ForEach-Object { Join-Path $raiz $_ }
  ) -Pattern '\binLibGlobalVar\b'
)
Comprobar ($importsGlobales.Count -eq 0) `
  'Doce unidades eliminan su dependencia completa de inLibGlobalVar'
Comprobar (
    (-not (Test-Path -LiteralPath $rutaAdaptador))
  ) 'El adaptador transitorio se retira al completar la Fase X-C'

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

$dfmModificados = @(
  & git -C $raiz diff --name-only -- 'src/*.dfm' 'src/**/*.dfm'
)
Comprobar ($dfmModificados.Count -eq 0) `
  'No se modifica ningún DFM'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase X-B no han sido superadas.'
}
