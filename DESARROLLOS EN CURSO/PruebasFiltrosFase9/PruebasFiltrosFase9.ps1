$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaContrato = Join-Path $raiz 'src\Lib\inLibFiltrosGuardadosIntf.pas'
$rutaImplementacion = Join-Path $raiz 'src\DataModules\UniDataFiltros.pas'
$rutaBase = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaMto = Join-Path $raiz 'src\Forms\inMtoGen.pas'
$rutaModal = Join-Path $raiz 'src\Modals\inMtoModalGestionFiltros.pas'
$rutaGlobales = Join-Path $raiz 'src\Lib\inLibGlobalVar.pas'
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$implementacion = Get-Content -Raw -LiteralPath $rutaImplementacion
$base = Get-Content -Raw -LiteralPath $rutaBase
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$mto = Get-Content -Raw -LiteralPath $rutaMto
$modal = Get-Content -Raw -LiteralPath $rutaModal
$globales = Get-Content -Raw -LiteralPath $rutaGlobales
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

Comprobar ($contrato -match 'IFiltrosGuardados = interface') `
  'Existe el contrato del servicio de filtros'
Comprobar ($contrato -match 'IProveedorFiltrosGuardados = interface') `
  'Existe el contrato para publicar el servicio'
Comprobar (
    ($contrato -match 'TFiltroGuardadoInfo = record') -and
    ($contrato -match 'TDestinoCompartidoInfo = record')
  ) 'Los datos cruzan la interfaz mediante DTO'
Comprobar ($implementacion -match
    'IProveedorContextoSesion,\s*IFiltrosGuardados') `
  'TdmFiltros implementa el contrato'
Comprobar ($implementacion -notmatch
    '\bunqryListado\b|\bdsListado\b|\bAbrirListadoParaGrid\b') `
  'TdmFiltros no expone la query de listado'
Comprobar (
    ($base -match 'IProveedorFiltrosGuardados') -and
    ($base -match 'HeredarFiltrosGuardados\(AOwner\)')
  ) 'TfrmBase publica y hereda el servicio'
Comprobar ($principal -match
    'AsignarFiltrosGuardados\(FdmDataFiltros\)') `
  'La ventana principal compone la implementación'
Comprobar ($principal -match
    'AsignarFiltrosGuardados\(nil\);\s*' +
    'if \(FdmDataFiltros <> nil\) then\s*' +
    'FreeAndNil\(FdmDataFiltros\)') `
  'La interfaz se libera antes que el DataModule'

$fuentes = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.pas'
$referenciasGlobales = @(
  Select-String -Path $fuentes.FullName -Pattern '\bodmFiltros\b' `
    -CaseSensitive
)
Comprobar ($referenciasGlobales.Count -eq 0) `
  'No quedan referencias a odmFiltros'
Comprobar ($globales -notmatch
    '\bUniDataFiltros\b|\bTdmFiltros\b|\bodmFiltros\b') `
  'inLibGlobalVar no depende del módulo de filtros'
Comprobar (
    ($mto -match '\binLibFiltrosGuardadosIntf\b') -and
    ($mto -notmatch '\bUniDataFiltros\b')
  ) 'TfrmMtoGen depende del contrato'
Comprobar (
    ($modal -match '\bTClientDataSet\b') -and
    ($modal -match '\bTFiltrosGuardadosList\b')
  ) 'El modal proyecta los DTO en un dataset local'
Comprobar ($modal -notmatch
    '\bodmFiltros\b|\bunqryListado\b|\bdsListado\b') `
  'El modal no accede al DataModule ni a su query'
Comprobar ($modal -notmatch
    '\binLibGlobalVar\b|\boUser\b|\boGroup\b|\boRootGroup\b|\boConn\b') `
  'El modal usa contexto y conexión inyectados'

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
  'src/Core/inMtoFrmBase.dfm',
  'src/Core/inMtoPrincipal.dfm',
  'src/DataModules/UniDataFiltros.dfm',
  'src/Forms/inMtoGen.dfm',
  'src/Modals/inMtoModalGestionFiltros.dfm'
)
$dfmObjetivoModificados = @(
  & git -C $raiz diff --name-only -- $dfmObjetivo
)
Comprobar ($dfmObjetivoModificados.Count -eq 0) `
  'No hay DFM modificados dentro del alcance de la Fase IX'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase IX no han sido superadas.'
}
