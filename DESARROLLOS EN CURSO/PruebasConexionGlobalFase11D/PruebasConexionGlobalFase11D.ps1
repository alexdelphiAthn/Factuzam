$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
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

function Leer {
  param([string]$Ruta)
  Get-Content -Raw -LiteralPath (Join-Path $raiz $Ruta)
}

$archivosPascal = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
    -Filter '*.pas'
)
$archivosPascal += Get-Item -LiteralPath (Join-Path $raiz 'fzam.dpr')
$referencias = @()
foreach ($archivo in $archivosPascal) {
  $referencias += @(
    Select-String -LiteralPath $archivo.FullName `
      -Pattern '\boConn\b' -AllMatches
  )
}
Comprobar ($referencias.Count -eq 0) `
  'No existe ninguna referencia a oConn en src ni fzam.dpr'

$globales = Leer 'src\Lib\inLibGlobalVar.pas'
Comprobar (($globales -notmatch '\boConn\b') -and
    ($globales -notmatch '(?m)^\s*uses\s+Uni\b') -and
    ($globales -notmatch '(?m)^\s*Uni\s*,')) `
  'inLibGlobalVar ya no declara la conexion ni depende de UniDAC'

$principal = Leer 'src\Core\inMtoPrincipal.pas'
Comprobar (($principal -notmatch '\boConn\b') -and
    ($principal -match 'AsignarConexiones\(') -and
    ($principal -match
      'TServicioConexionesUniDAC\.Create\(FDmConn\.conUni\)')) `
  'La raiz conserva el servicio y elimina el puente global'

$caja = Leer 'src\Caja\DataModules\UniDataCaja.pas'
$traspaso = Leer 'src\Caja\DataModules\UniDataTraspaso.pas'
$consulta = Leer 'src\DataModules\UniDataConsultaOpe.pas'
$constructores =
  ($caja -match
    'constructor\s+Create\(\s*AOwner:\s*TComponent;\s*' +
    'AConexion:\s*TUniConnection\)') -and
  ($traspaso -match
    'constructor\s+Create\(\s*AOwner:\s*TComponent;\s*' +
    'AConexion:\s*TUniConnection\)') -and
  ($consulta -match
    'constructor\s+Create\(\s*AOwner:\s*TComponent;\s*' +
    'AConexion:\s*TUniConnection\)')
Comprobar $constructores `
  'Los tres modulos directos reciben la conexion en el constructor'

$ordenInicializacion =
  ($caja -match
    '(?s)constructor TdmCajaOpe\.Create\(.*?begin\s+' +
    'FConexion\s*:=\s*AConexion;.*?inherited Create\(AOwner\);') -and
  ($traspaso -match
    '(?s)constructor TdmTraspaso\.Create\(.*?begin\s+' +
    'FConexion\s*:=\s*AConexion;.*?inherited Create\(AOwner\);') -and
  ($consulta -match
    '(?s)constructor TdmConsultaOpe\.Create\(.*?begin\s+' +
    'FConexion\s*:=\s*AConexion;\s+inherited Create\(AOwner\);')
Comprobar $ordenInicializacion `
  'La conexion se asigna antes de disparar DataModuleCreate'

Comprobar (($caja -notmatch '\boConn\b') -and
    ($traspaso -notmatch '\boConn\b') -and
    ($consulta -notmatch '\boConn\b') -and
    ($caja -match 'FConexion\.StartTransaction;') -and
    ($caja -match 'FConexion\.Commit;') -and
    ($caja -match 'FConexion\.Rollback;') -and
    ($traspaso -match 'FConexion\.StartTransaction;') -and
    ($traspaso -match 'FConexion\.Commit;') -and
    ($traspaso -match 'FConexion\.Rollback;')) `
  'Caja y traspaso conservan la misma conexion en sus transacciones'

$cajaForm = Leer 'src\Caja\Forms\inMtoCajaOpe.pas'
$traspasoForm = Leer 'src\Caja\Forms\inMtoTraspasoOpe.pas'
$consultaForm = Leer 'src\Forms\inMtoConsultaOpe.pas'
$consultaHist = Leer 'src\Caja\Forms\inMtoCajaOperacionesHist.pas'
$entrada = Leer 'src\Modals\inMtoModalEntradaCambio.pas'
$gasto = Leer 'src\Caja\Modals\inMtoModalGastoCaja.pas'
$llamantes =
  ($cajaForm -match
    'TdmCajaOpe\.Create\(Self,\s*ConexionPrincipal\)') -and
  ($entrada -match 'TdmCajaOpe\.Create\(nil,\s*FConn\)') -and
  ($gasto -match 'TdmCajaOpe\.Create\(nil,\s*FConn\)') -and
  ($traspasoForm -match
    'TdmTraspaso\.Create\(Self,\s*ConexionPrincipal\)') -and
  ($consultaForm -match
    'TdmConsultaOpe\.Create\(Self,\s*ConexionPrincipal\)') -and
  ($consultaHist -match
    'TdmConsultaOpe\.Create\(Self,\s*ConexionPrincipal\)')
Comprobar $llamantes `
  'Todos los llamantes entregan una conexion explicita'

$appParam = Leer 'src\Core\inMtoAppParam.pas'
$verifactu = Leer 'src\Modals\inMtoModalVerifactuDecl.pas'
$fiscalExplicito =
  ($principal -match
    'RegistrarEventoFiscalSeguro\(\s*AConexion:\s*TUniConnection;') -and
  ($appParam -match
    'RegistrarCambioConfiguracionVerifactuSeguro\(\s*' +
    'AConexion:\s*TUniConnection;') -and
  ($verifactu -match
    'AnexoEmpresasInstalacionHtml\(\s*' +
    'AConexion:\s*TUniConnection\)') -and
  ($verifactu -match 'Qry\.Connection\s*:=\s*AConexion;')
Comprobar $fiscalExplicito `
  'Los auxiliares fiscales reciben la conexion por contrato'

$librerias = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
    -Filter 'inLib*.pas'
)
$refsLibrerias = @(
  $librerias |
    Select-String -Pattern '\boConn\b'
)
Comprobar ($refsLibrerias.Count -eq 0) `
  'La barrera XI-C sigue protegiendo todas las librerias inLib'

$patronSimbolosGlobales =
  '(?i)\b(TLogSesionProc|oInfGuiasCache|oMemoSQL|ofrmMto2|' +
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
  'No queda ningun uses huerfano de inLibGlobalVar'

$pruebaXD = Leer (
  'DESARROLLOS EN CURSO\PruebasContextoSesionFase10D\' +
  'PruebasContextoSesionFase10D.ps1')
Comprobar ($pruebaXD -notmatch
    'TLogSesionProc\|oInfGuiasCache\|oConn\|oMemoSQL') `
  'La deteccion historica de uses ya no admite oConn'

$largas = @()
foreach ($archivo in $archivosPascal) {
  $numero = 0
  foreach ($linea in (Get-Content -LiteralPath $archivo.FullName)) {
    $numero++
    if (($linea -match '\bConexionPrincipal\b') -and
        ($linea.Length -gt 80)) {
      $largas += ('{0}:{1}' -f $archivo.FullName, $numero)
    }
  }
}
Comprobar ($largas.Count -eq 0) `
  'Las lineas migradas respetan 80 columnas'

$dfm = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.dfm'
$dfmConConexion = @()
$enlaces = 0
foreach ($archivo in $dfm) {
  $coincidencias = @(
    Select-String -LiteralPath $archivo.FullName `
      -SimpleMatch 'Connection = dmConn.conUni'
  )
  if ($coincidencias.Count -gt 0) {
    $dfmConConexion += $archivo
    $enlaces += $coincidencias.Count
  }
}
Comprobar (($dfmConConexion.Count -eq 52) -and ($enlaces -eq 253)) `
  'Se conservan los 253 enlaces persistentes de 52 DFM'

$dfmPermitidos = @(
  'src\Forms\inMtoStockConsulta.dfm',
  'src\Modals\inMtoModalFacturarAlbaranesFechas.dfm'
)
$dfmModificados = @(
  & git -C $raiz diff --name-only -- 'src/*.dfm' 'src/**/*.dfm' |
    ForEach-Object { $_.Replace('/', '\') }
)
$dfmFuera = @(
  $dfmModificados |
    Where-Object { $dfmPermitidos -notcontains $_ }
)
Comprobar (($dfmFuera.Count -eq 0) -and
    ($dfmModificados.Count -eq 2)) `
  'XI-D no modifica ningun DFM'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase XI-D no han sido superadas.'
}
