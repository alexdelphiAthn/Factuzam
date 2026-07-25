$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaGlobales = Join-Path $raiz 'src\Lib\inLibGlobalVar.pas'
$rutaAdaptador = Join-Path $raiz 'src\Lib\inLibContextoSesionGlobal.pas'
$rutaProyecto = Join-Path $raiz 'fzam.dpr'
$globales = Get-Content -Raw -LiteralPath $rutaGlobales
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

$patronGlobalSesion =
  '(?i)\b(oUser|oGroup|oRootGroup|oEmpresa|oAlmacen|oCaja)\b'
$archivosPascal = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse -Filter '*.pas'
)
$archivosPascal += Get-Item -LiteralPath $rutaProyecto
$referenciasGlobales = @(
  Select-String -Path $archivosPascal.FullName -Pattern $patronGlobalSesion
)
$referenciasAdaptador = @(
  Select-String -Path $archivosPascal.FullName `
    -Pattern '(?i)\b(inLibContextoSesionGlobal|TContextoSesionGlobal)\b'
)

Comprobar (-not (Test-Path -LiteralPath $rutaAdaptador)) `
  'El adaptador global de contexto ya no existe'
Comprobar ($referenciasAdaptador.Count -eq 0) `
  'Ninguna fuente puede volver a registrar o consumir el adaptador'
Comprobar ($globales -notmatch $patronGlobalSesion) `
  'inLibGlobalVar no declara las seis variables de sesión'
Comprobar ($referenciasGlobales.Count -eq 0) `
  'Ninguna fuente puede volver a usar las seis variables retiradas'
Comprobar ($proyecto -match
    'TContextoSesionAplicacion\.Create\(\s*' +
    'ResultadoInicioSesion\.Identidad,\s*' +
    'ResultadoInicioSesion\.Ubicacion\)') `
  'La raíz compone directamente el contexto definitivo'
Comprobar ($proyecto -notmatch
    '(?i)\b(inLibContextoSesionGlobal|TContextoSesionGlobal)\b') `
  'El proyecto no registra la compatibilidad eliminada'

$patronSimbolosGlobales =
  '(?i)\b(TLogSesionProc|oInfGuiasCache|oConn|oMemoSQL|ofrmMto2|' +
  'oNomImpresoraCaja|oAppName|oVersion|oAll|oLogSesion|' +
  'oLicenciaAplicacionComprobada|oLicenciaAplicacionBBDD|' +
  'oLicenciaAplicacionEstado|oLicenciaAplicacionMensaje|' +
  'oCerrandoApp|LogSes)\b'
$usesHuerfanos = @()
foreach ($archivo in $archivosPascal) {
  $contenido = Get-Content -Raw -LiteralPath $archivo.FullName
  if ($contenido -match '(?i)\binLibGlobalVar\b') {
    $sinNombreUnidad = $contenido -replace
      '(?i)\binLibGlobalVar\b', ''
    if ($sinNombreUnidad -notmatch $patronSimbolosGlobales) {
      $usesHuerfanos += $archivo.FullName
    }
  }
}
Comprobar ($usesHuerfanos.Count -eq 0) `
  'No quedan uses de inLibGlobalVar sin un consumidor real'

$unidadesLimpiadas = @(
  'src\DataModules\UniDataEmpleados.pas',
  'src\Forms\inMtoGenSearch.pas',
  'src\Lib\inLibDevExp.pas',
  'src\Lib\inLibGridPivoteVenta.pas',
  'src\Lib\inLibWin.pas',
  'src\Modals\inMtoModalDistribuidor.pas',
  'src\otras pruebas\parametros VerticalGrid\Unit1.pas'
)
$limpiezaCorrecta = $true
foreach ($rutaRelativa in $unidadesLimpiadas) {
  $contenido = Get-Content -Raw -LiteralPath (Join-Path $raiz $rutaRelativa)
  if ($contenido -match '(?i)\binLibGlobalVar\b') {
    $limpiezaCorrecta = $false
  }
}
Comprobar $limpiezaCorrecta `
  'Se retiran los siete uses obsoletos detectados en X-D'

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
  throw 'Las comprobaciones de la Fase X-D no han sido superadas.'
}
