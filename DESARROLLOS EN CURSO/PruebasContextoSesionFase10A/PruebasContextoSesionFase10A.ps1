$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaContrato = Join-Path $raiz 'src\Lib\inLibContextoSesionIntf.pas'
$rutaLogon = Join-Path $raiz 'src\Core\inMtoLogon.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaProyecto = Join-Path $raiz 'fzam.dpr'
$rutaAdaptador = Join-Path $raiz 'src\Lib\inLibContextoSesionGlobal.pas'
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$logon = Get-Content -Raw -LiteralPath $rutaLogon
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$proyecto = Get-Content -Raw -LiteralPath $rutaProyecto
$adaptador = Get-Content -Raw -LiteralPath $rutaAdaptador
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
    ($contrato -match 'TResultadoInicioSesion = record') -and
    ($contrato -match 'Autenticado: Boolean') -and
    ($contrato -match 'Identidad\s*: TIdentidadSesion') -and
    ($contrato -match 'Ubicacion\s*: TUbicacionSesion')
  ) 'El contrato define un resultado tipado de inicio de sesión'
Comprobar (
    ($contrato -match 'class function CrearAutenticado') -and
    ($contrato -match 'class function CrearNoAutenticado')
  ) 'El resultado diferencia explícitamente éxito y ausencia de sesión'
Comprobar (
    ($logon -match
      'property ResultadoInicioSesion: TResultadoInicioSesion') -and
    ($logon -match
      'TResultadoInicioSesion\.CrearAutenticado')
  ) 'El formulario de acceso publica el resultado tipado'
Comprobar ($logon -notmatch '\bsSuccess\b') `
  'Se elimina el indicador textual de éxito del formulario de acceso'
$patronEscrituraGlobal =
  '\b(oUser|oGroup|oRootGroup|oEmpresa|oAlmacen|oCaja)\s*:='
Comprobar ($logon -notmatch $patronEscrituraGlobal) `
  'El formulario de acceso no escribe las variables globales de sesión'
Comprobar (
    ($proyecto -match
      'function CrearContextoSesionInicial\(') -and
    ($proyecto -match
      'frmLogon\.ResultadoInicioSesion')
  ) 'El proyecto recibe el resultado mediante la API del formulario'
Comprobar ($proyecto -notmatch '\bsSuccess\b') `
  'El proyecto no interpreta indicadores de sesión basados en texto'
Comprobar ($proyecto -match
    'TContextoSesionGlobal\.Create\(\s*' +
    'ResultadoInicioSesion\.Identidad,\s*' +
    'ResultadoInicioSesion\.Ubicacion\)') `
  'La raíz compone el adaptador temporal desde el resultado tipado'
Comprobar (
    ($principal -match
      'procedure TfrmMtoPrincipal\.InicializarAplicacion\(') -and
    ($principal -match
      'AsignarContextoSesion\(AContextoSesion\)')
  ) 'La ventana principal recibe el contexto explícitamente'
Comprobar ($principal -notmatch
    'TIdentidadSesion\.Crear\(oUser|TUbicacionSesion\.Crear\(oEmpresa') `
  'La ventana principal no reconstruye el contexto desde globals'
Comprobar ($principal -notmatch '\binLibContextoSesionGlobal\b') `
  'La ventana principal desconoce el adaptador de compatibilidad'
Comprobar (
    ($adaptador -match 'TContextoSesionGlobal') -and
    ($adaptador -match 'SincronizarGlobales')
  ) 'Se conserva el adaptador para los consumidores aún no migrados'

$dfmObjetivo = @(
  'src/Core/inMtoLogon.dfm',
  'src/Core/inMtoPrincipal.dfm'
)
$dfmObjetivoModificados = @(
  & git -C $raiz diff --name-only -- $dfmObjetivo
)
Comprobar ($dfmObjetivoModificados.Count -eq 0) `
  'No se modifican los formularios persistentes del alcance'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase X-A no han sido superadas.'
}
