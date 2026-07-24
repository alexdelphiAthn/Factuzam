$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaContrato = Join-Path $raiz 'src\Lib\inLibPerfilesUsuarioIntf.pas'
$rutaImplementacion = Join-Path $raiz 'src\DataModules\UniDataPerfiles.pas'
$rutaBase = Join-Path $raiz 'src\Core\inMtoFrmBase.pas'
$rutaBaseDatos = Join-Path $raiz 'src\DataModules\UniDataGen.pas'
$rutaPrincipal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'
$rutaGlobales = Join-Path $raiz 'src\Lib\inLibGlobalVar.pas'
$rutaUsuarios = Join-Path $raiz 'src\Lib\inLibUser.pas'
$rutaLayouts = Join-Path $raiz 'src\Lib\inLibLayoutForm.pas'
$rutaDevExpress = Join-Path $raiz 'src\Lib\inLibDevExp.pas'
$rutaWindows = Join-Path $raiz 'src\Lib\inLibWin.pas'
$rutaUtilidades = Join-Path $raiz 'src\Lib\inLibtb.pas'
$rutaStock = Join-Path $raiz 'src\Forms\inMtoStockConsulta.pas'
$rutaModal = Join-Path $raiz 'src\Modals\inMtoModalGenImp.pas'
$contrato = Get-Content -Raw -LiteralPath $rutaContrato
$implementacion = Get-Content -Raw -LiteralPath $rutaImplementacion
$base = Get-Content -Raw -LiteralPath $rutaBase
$baseDatos = Get-Content -Raw -LiteralPath $rutaBaseDatos
$principal = Get-Content -Raw -LiteralPath $rutaPrincipal
$globales = Get-Content -Raw -LiteralPath $rutaGlobales
$usuarios = Get-Content -Raw -LiteralPath $rutaUsuarios
$layouts = Get-Content -Raw -LiteralPath $rutaLayouts
$devExpress = Get-Content -Raw -LiteralPath $rutaDevExpress
$windows = Get-Content -Raw -LiteralPath $rutaWindows
$utilidades = Get-Content -Raw -LiteralPath $rutaUtilidades
$stock = Get-Content -Raw -LiteralPath $rutaStock
$modal = Get-Content -Raw -LiteralPath $rutaModal
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

Comprobar ($contrato -match 'IPerfilesUsuario = interface') `
  'Existe el contrato del servicio de perfiles'
Comprobar ($contrato -match 'IProveedorPerfilesUsuario = interface') `
  'Existe el contrato para publicar el servicio'
Comprobar (
    ($contrato -match 'TProfileDicc = TDictionary') -and
    ($contrato -match 'TPerfilItem = record') -and
    ($contrato -match 'TPerfilList = TList')
  ) 'Las estructuras de perfiles pertenecen al contrato'
Comprobar ($implementacion -match
    'IProveedorContextoSesion,\s*IPerfilesUsuario') `
  'TdmPerfiles implementa el contrato'
Comprobar ($implementacion -notmatch
    '\bAssign_Profile_Dict\b|\bAddRecordToDict\b') `
  'Se retira la API antigua de diccionarios intermedios'
Comprobar (
    ($base -match 'IProveedorPerfilesUsuario') -and
    ($base -match 'HeredarPerfilesUsuario\(AOwner\)')
  ) 'TfrmBase publica y hereda el servicio'
Comprobar (
    ($baseDatos -match 'IProveedorPerfilesUsuario') -and
    ($baseDatos -match 'HeredarPerfilesUsuario\(AOwner\)')
  ) 'TdmBase propaga el servicio a los DataModules'
Comprobar ($principal -match
    'AsignarPerfilesUsuario\(FdmDataPerfiles\)') `
  'La ventana principal compone la implementación'
Comprobar ($principal -match
    'AsignarPerfilesUsuario\(nil\);\s*' +
    'if \(FdmDataPerfiles <> nil\) then\s*' +
    'FreeAndNil\(FdmDataPerfiles\)') `
  'La interfaz se libera antes que el DataModule'

$fuentes = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.pas'
$referenciasGlobales = @(
  Select-String -Path $fuentes.FullName -Pattern '\bodmPerfiles\b' `
    -CaseSensitive
)
Comprobar ($referenciasGlobales.Count -eq 0) `
  'No quedan referencias a odmPerfiles'
Comprobar ($globales -notmatch
    '\bUniDataPerfiles\b|\bTdmPerfiles\b|\bodmPerfiles\b') `
  'inLibGlobalVar no depende del módulo de perfiles'
Comprobar (
    ($usuarios -match '\bIPerfilesUsuario\b') -and
    ($usuarios -notmatch '\binLibGlobalVar\b|\bTUniQuery\b')
  ) 'inLibUser recibe el servicio y no consulta la BBDD'
Comprobar (
    ($layouts -match 'FPerfilesUsuario: IPerfilesUsuario') -and
    ($layouts -notmatch '\bUniDataPerfiles\b|\bodmPerfiles\b')
  ) 'La persistencia de layouts recibe el servicio explícitamente'
Comprobar (
    ($devExpress -notmatch '\bUniDataPerfiles\b|\bodmPerfiles\b') -and
    ($windows -notmatch '\bodmPerfiles\b') -and
    ($utilidades -notmatch '\bodmPerfiles\b')
  ) 'Las utilidades ya no dependen de la global de perfiles'
Comprobar (
    ($stock -match 'FPerfilesUsuario: IPerfilesUsuario') -and
    ($stock -match 'procedure DesvincularPerfilesStockConsulta') -and
    ($stock -notmatch '\bUniDataPerfiles\b|\bodmPerfiles\b') -and
    ($principal -match
      'DesvincularPerfilesStockConsulta;\s*AsignarPerfilesUsuario\(nil\)')
  ) 'La consulta de stock recibe el servicio de forma explícita'
Comprobar (
    ($modal -match '\bPerfilesUsuario\.') -and
    ($modal -notmatch '\bodmPerfiles\b')
  ) 'El modal de impresión consume el contrato heredado'

$consumidoresAnteriores = @(
  'src/Caja/Forms/inMtoCajaOperacionesHist.pas',
  'src/Caja/Forms/inMtoCajaPagosHist.pas',
  'src/Forms/inMtoArticulos.pas',
  'src/Forms/inMtoFacturasSimplif.pas',
  'src/Forms/inMtoGen.pas',
  'src/Forms/inMtoMovimientosAlmacen.pas',
  'src/Forms/inMtoStockConsulta.pas',
  'src/Lib/inLibDevExp.pas',
  'src/Lib/inLibLayoutForm.pas'
)
$dependenciasConcretas = @(
  Select-String -LiteralPath (
    $consumidoresAnteriores |
      ForEach-Object { Join-Path $raiz $_ }
  ) -Pattern '\bUniDataPerfiles\b' -CaseSensitive
)
Comprobar ($dependenciasConcretas.Count -eq 0) `
  'Los consumidores de estructuras ya no importan el DataModule'

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
  'src/DataModules/UniDataGen.dfm',
  'src/DataModules/UniDataPerfiles.dfm',
  'src/Forms/inMtoGen.dfm',
  'src/Forms/inMtoStockConsulta.dfm',
  'src/Modals/inMtoModalGenImp.dfm'
)
$dfmObjetivoModificados = @(
  & git -C $raiz diff --name-only -- $dfmObjetivo
)
Comprobar ($dfmObjetivoModificados.Count -eq 0) `
  'No hay DFM modificados dentro del alcance de perfiles'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de perfiles de la Fase IX no han sido superadas.'
}
