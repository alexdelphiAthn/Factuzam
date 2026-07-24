$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaContrato = Join-Path $raiz 'src\Lib\inLibContextoSesionIntf.pas'
$rutaContexto = Join-Path $raiz 'src\Lib\inLibContextoSesion.pas'
$rutaAdaptador = Join-Path $raiz 'src\Lib\inLibContextoSesionGlobal.pas'
$rutaBaseForm = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaBaseDatos = Join-Path $raiz 'src\DataModules\UniDataGen.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaProyecto = Join-Path $raiz 'fzam.dpr'
$rutaAuditoria = Join-Path $raiz 'src\Lib\inLibAuditoriaDatos.pas'
$rutaPerfiles = Join-Path $raiz 'src\DataModules\UniDataPerfiles.pas'
$rutaFiltros = Join-Path $raiz 'src\DataModules\UniDataFiltros.pas'
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$contexto = Get-Content -Raw -LiteralPath $rutaContexto
$adaptador = Get-Content -Raw -LiteralPath $rutaAdaptador
$baseForm = Get-Content -Raw -LiteralPath $rutaBaseForm
$baseDatos = Get-Content -Raw -LiteralPath $rutaBaseDatos
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$proyecto = Get-Content -Raw -LiteralPath $rutaProyecto
$auditoria = Get-Content -Raw -LiteralPath $rutaAuditoria
$perfiles = Get-Content -Raw -LiteralPath $rutaPerfiles
$filtros = Get-Content -Raw -LiteralPath $rutaFiltros
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

Comprobar ($contrato -match 'IContextoSesionAplicacion = interface') `
  'Existe un contrato separado de lectura'
Comprobar ($contrato -match 'IGestorContextoSesion = interface') `
  'Existe un contrato separado de escritura'
Comprobar ($contrato -match 'IProveedorContextoSesion = interface') `
  'Existe un contrato para publicar el contexto'
Comprobar (
    ($contrato -match 'TIdentidadSesion = record') -and
    ($contrato -match 'TUbicacionSesion = record')
  ) 'Identidad y ubicación son estructuras independientes'
Comprobar (
    ($contexto -match 'TCriticalSection') -and
    ($contexto -notmatch 'inLibGlobalVar')
  ) 'La implementación es sincronizada y no depende de globales'
Comprobar (
    ($adaptador -match 'TContextoSesionGlobal') -and
    ($adaptador -match 'SincronizarGlobales')
  ) 'El puente global está aislado en un adaptador de transición'
Comprobar (
    ($baseForm -match 'IProveedorContextoSesion') -and
    ($baseForm -match 'HeredarContextoSesion\(AOwner\)')
  ) 'TfrmBase publica y hereda el contexto'
Comprobar (
    ($baseDatos -match 'IProveedorContextoSesion') -and
    ($baseDatos -match 'HeredarContextoSesion\(AOwner\)')
  ) 'TdmBase publica y hereda el contexto'
Comprobar (
    ($proyecto -match
      'TContextoSesionGlobal\.Create\(\s*' +
      'ResultadoInicioSesion\.Identidad,\s*' +
      'ResultadoInicioSesion\.Ubicacion\)') -and
    ($principal -match
      'AsignarContextoSesion\(AContextoSesion\)')
  ) 'La raíz compone e inyecta el contexto desde el resultado del login'
Comprobar ($principal -match
    'TServicioAuditoriaDatos\.Create\(ContextoSesion\)') `
  'La auditoría recibe el contexto en lugar del usuario global'
Comprobar (
    ($auditoria -match 'FContextoSesion: IContextoSesionAplicacion') -and
    ($auditoria -match 'FContextoSesion\.Identidad\.Usuario')
  ) 'La auditoría consulta la identidad del contexto'
$patronSesion = '\bo(User|Group|RootGroup|Empresa|Almacen|Caja)\b'
Comprobar ($perfiles -notmatch $patronSesion) `
  'Perfiles no lee las variables globales de sesión'
Comprobar ($perfiles -notmatch '\boConn\b') `
  'Perfiles recibe también la conexión mediante interfaz'
Comprobar ($filtros -notmatch
    $patronSesion + '|\boConn\b|\binLibGlobalVar\b') `
  'Filtros no depende de sesión ni conexión globales'
Comprobar (
    ($principal -match 'IdentidadActual := ContextoSesion\.Identidad') -and
    ($principal -match 'UbicacionActual := ContextoSesion\.Ubicacion')
  ) 'La interfaz principal usa instantáneas del contexto'

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

$dfmObjetivo = @(
  'src/DataModules/UniDataPerfiles.dfm',
  'src/DataModules/UniDataFiltros.dfm',
  'src/Core/inMtoFrmBase.dfm',
  'src/Core/inMtoPrincipal.dfm'
)
$dfmObjetivoModificados = @(
  & git -C $raiz diff --name-only -- $dfmObjetivo
)
Comprobar ($dfmObjetivoModificados.Count -eq 0) `
  'No hay DFM modificados dentro del alcance de la Fase VIII'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase VIII no han sido superadas.'
}
