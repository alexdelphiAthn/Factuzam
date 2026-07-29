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

$rutaStock = 'src\Forms\inMtoStockConsulta.pas'
$rutaModal =
  'src\Modals\inMtoModalFacturarAlbaranesFechas.pas'
$rutaDfmStock = 'src\Forms\inMtoStockConsulta.dfm'
$rutaDfmModal =
  'src\Modals\inMtoModalFacturarAlbaranesFechas.dfm'
$stock = Get-Content -Raw -LiteralPath (Join-Path $raiz $rutaStock)
$modal = Get-Content -Raw -LiteralPath (Join-Path $raiz $rutaModal)
$dfmStock = Get-Content -Raw -LiteralPath (Join-Path $raiz $rutaDfmStock)
$dfmModal = Get-Content -Raw -LiteralPath (Join-Path $raiz $rutaDfmModal)

Comprobar (($stock -match
    'TfrmStockConsulta\s*=\s*class\(TfrmBase\)') -and
    ($modal -match
    'TfrmModalFacturarAlbaranesFechas\s*=\s*class\(TfrmBase\)')) `
  'Las dos pantallas heredan de TfrmBase'

Comprobar (($dfmStock -match
    '^\s*inherited frmStockConsulta: TfrmStockConsulta') -and
    ($dfmModal -match
    '^\s*inherited frmModalFacturarAlbaranesFechas: ' +
    'TfrmModalFacturarAlbaranesFechas')) `
  'Los dos DFM declaran herencia visual'

Comprobar (($stock -notmatch '\boConn\b') -and
    ($modal -notmatch '\boConn\b')) `
  'Las dos pantallas ya no leen la conexion global'

$refsStock = ([regex]::Matches(
  $stock,
  '\bConexionPrincipal\b')).Count
$refsModal = ([regex]::Matches(
  $modal,
  '\bConexionPrincipal\b')).Count
Comprobar (($refsStock -eq 15) -and ($refsModal -eq 1)) `
  'Las lecturas heredadas y las llamadas XI-C usan ConexionPrincipal'

Comprobar (($stock -notmatch
    '\bF(Permisos|PerfilesUsuario|ContextoSesion)\b') -and
    ($stock -notmatch
    'constructor\s+Create\(\s*AOwner:\s*TComponent;')) `
  'StockConsulta no duplica servicios ni constructor de inyeccion'

Comprobar (($stock -match
    'procedure MostrarStockConsulta\(const ACodArt, ACodSku: string\)') -and
    ($stock -notmatch
    'procedure MostrarStockConsulta\([^;]*APermisos')) `
  'La apertura de stock ya no transporta servicios'

Comprobar (($stock -match
    '(?s)procedure TfrmStockConsulta\.FormCreate\(.*?begin\s+inherited;') -and
    ($modal -match
    '(?s)procedure TfrmModalFacturarAlbaranesFechas\.FormCreate' +
    '\(.*?begin\s+inherited;')) `
  'Los FormCreate encadenan la inicializacion de TfrmBase'

Comprobar (($stock -notmatch '\binLibGlobalVar\b') -and
    ($modal -notmatch '\binLibGlobalVar\b')) `
  'Las dos unidades retiran el uses de inLibGlobalVar'

# Unidades que conservan oConn tras XI-B1. Son el trabajo pendiente de
# XI-B2/B3/B4, XI-C y XI-D.
$pendientes = @(
  'src\Caja\DataModules\UniDataCaja.pas',
  'src\Caja\DataModules\UniDataTraspaso.pas',
  'src\Caja\Lib\inLibArqueoTicket.pas',
  'src\Caja\Lib\inLibCajaParam.pas',
  'src\Caja\Lib\inLibFaseCobro.pas',
  'src\Caja\Lib\inLibGenerarTicketCaja.pas',
  'src\Core\inMtoAppParam.pas',
  'src\Core\inMtoPrincipal.pas',
  'src\DataModules\UniDataConsultaOpe.pas',
  'src\DataModules\UniDataInventarios.pas',
  'src\Lib\inLibAppParam.pas',
  'src\Lib\inLibArticulosValidador.pas',
  'src\Lib\inLibAtributosPaleta.pas',
  'src\Lib\inLibComprasSesiones.pas',
  'src\Lib\inLibComprasSesionesMaterializar.pas',
  'src\Lib\inLibConfigCampos.pas',
  'src\Lib\inLibContadorLineas.pas',
  'src\Lib\inLibCorreoTickets.pas',
  'src\Lib\inLibData.pas',
  'src\Lib\inLibDocumentosTrabajo.pas',
  'src\Lib\inLibFacturas.pas',
  'src\Lib\inLibFormatoDocumento.pas',
  'src\Lib\inLibFotos.pas',
  'src\Lib\inLibGenBusq.pas',
  'src\Lib\inLibGenerarTicket.pas',
  'src\Lib\inLibGenerarTicketBD.pas',
  'src\Lib\inLibGlobalVar.pas',
  'src\Lib\inLibInformesGuiasCache.pas',
  'src\Lib\inLibInventarioNube.pas',
  'src\Lib\inLibShowMto.pas',
  'src\Lib\inLibUnidadesMedida.pas',
  'src\Lib\inLibVentasCalendario.pas',
  'src\Modals\inMtoModalFacturarTicket.pas',
  'src\Modals\inMtoModalSerieFechaFactura.pas',
  'src\Modals\inMtoModalVerifactuDecl.pas'
)

$archivosPascal = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
    -Filter '*.pas' |
    Where-Object { $_.FullName -notmatch '\\vcl3?7?\\' }
)
$archivosPascal += Get-Item -LiteralPath (Join-Path $raiz 'fzam.dpr')
$fuera = @()
$refs = 0
$lineasRefs = 0
$unidades = 0
foreach ($archivo in $archivosPascal) {
  $relativa = $archivo.FullName.Substring($raiz.Length + 1)
  $coincidencias = @(
    Select-String -LiteralPath $archivo.FullName `
      -Pattern '\boConn\b' -AllMatches
  )
  $cuenta = 0
  foreach ($coincidencia in $coincidencias) {
    $cuenta += $coincidencia.Matches.Count
  }
  if ($cuenta -gt 0) {
    $refs += $cuenta
    $lineasRefs += $coincidencias.Count
    $unidades++
    if ($pendientes -notcontains $relativa) {
      $fuera += $relativa
    }
  }
}

Comprobar (($fuera.Count -eq 0) -and
    ($refs -le 169) -and
    ($lineasRefs -le 165) -and
    ($unidades -le 36)) `
  'El pendiente queda acotado a 169 refs, 165 lineas y 36 unidades'

$largas = @()
foreach ($ruta in @($rutaStock, $rutaModal)) {
  $numero = 0
  foreach ($linea in (Get-Content -LiteralPath (Join-Path $raiz $ruta))) {
    $numero++
    if (($linea -match '\bConexionPrincipal\b') -and
        ($linea.Length -gt 80)) {
      $largas += ('{0}:{1}' -f $ruta, $numero)
    }
  }
}
Comprobar ($largas.Count -eq 0) `
  'Ninguna linea migrada supera 80 columnas'

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
  'Solo cambian los dos DFM necesarios para la herencia visual'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase XI-B1 no han sido superadas.'
}
