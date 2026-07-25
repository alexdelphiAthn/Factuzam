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

$librerias = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
    -Filter 'inLib*.pas'
)
$global = $librerias |
  Where-Object { $_.Name -eq 'inLibGlobalVar.pas' }
$consumidores = $librerias |
  Where-Object { $_.Name -ne 'inLibGlobalVar.pas' }
$usosGlobales = @(
  $consumidores |
    Select-String -Pattern '\boConn\b'
)
Comprobar ($usosGlobales.Count -eq 0) `
  'Ninguna libreria inLib consume oConn'

$textoGlobal = Get-Content -Raw -LiteralPath $global.FullName
$refsGlobal = ([regex]::Matches($textoGlobal, '\boConn\b')).Count
Comprobar ($refsGlobal -eq 0) `
  'XI-D retira la declaracion y la inicializacion de oConn'

$principal = Leer 'src\Core\inMtoPrincipal.pas'
$asignaciones = @(
  'oAppParams.AsignarConexion(ConexionPrincipal);',
  'oCajaParams.AsignarConexion(ConexionPrincipal);',
  'oUnidades.AsignarConexion(ConexionPrincipal);',
  'oFotos.AsignarConexion(ConexionPrincipal);'
)
$asignadas = @(
  $asignaciones |
    Where-Object { $principal.Contains($_) }
)
$posServicio = $principal.IndexOf('AsignarConexiones(')
$posPrimera = $principal.IndexOf($asignaciones[0])
$posTemporizador = $principal.IndexOf('tmr1Timer(nil);')
Comprobar (($asignadas.Count -eq 4) -and
    ($posServicio -ge 0) -and
    ($posPrimera -gt $posServicio) -and
    ($posTemporizador -gt $posPrimera)) `
  'La raiz inyecta la conexion en los cuatro servicios persistentes'

$servicios = @(
  'src\Lib\inLibAppParam.pas',
  'src\Caja\Lib\inLibCajaParam.pas',
  'src\Lib\inLibUnidadesMedida.pas',
  'src\Lib\inLibFotos.pas'
)
$serviciosCorrectos = @()
foreach ($ruta in $servicios) {
  $texto = Leer $ruta
  if (($texto -match 'FConexion:\s*TUniConnection;') -and
      ($texto -match
        'procedure\s+\w+\.AsignarConexion\(AConexion:\s*TUniConnection\)') -and
      ($texto -match 'FConexion\s*:=\s*AConexion;')) {
    $serviciosCorrectos += $ruta
  }
}
Comprobar ($serviciosCorrectos.Count -eq $servicios.Count) `
  'Los servicios persistentes almacenan la conexion inyectada'

$config = Leer 'src\Lib\inLibConfigCampos.pas'
$guias = Leer 'src\Lib\inLibInformesGuiasCache.pas'
$cachesCorrectas =
  ($config -match
    'constructor\s+Create\(AConexion:\s*TUniConnection\);') -and
  ($guias -match
    'constructor\s+Create\(AConexion:\s*TUniConnection\);') -and
  ($config -match
    'if\s+AConn\s*=\s*nil\s+then\s+AConn\s*:=\s*FConexion;') -and
  ($guias -match
    'if\s+AConn\s*=\s*nil\s+then\s+AConn\s*:=\s*FConexion;') -and
  ($principal -match
    'TConfigCamposCache\.Create\(ConexionPrincipal\)') -and
  ($principal -match
    'TInformesGuiasCache\.Create\(ConexionPrincipal\)')
Comprobar $cachesCorrectas `
  'Las caches reciben la conexion en el constructor'

$contador = Leer 'src\Lib\inLibContadorLineas.pas'
$contadorCorrecto =
  ($contador -match
    'function\s+GetSiguienteLineaDoc\(\s*AConexion:\s*TUniConnection;') -and
  ($contador -match 'AConexion\.StartTransaction;') -and
  ($contador -match 'AConexion\.Commit;') -and
  ($contador -match 'AConexion\.Rollback;') -and
  ($contador -notmatch '\boConn\b')
Comprobar $contadorCorrecto `
  'Los contadores transaccionan sobre la conexion del llamante'

$sesiones = Leer 'src\Lib\inLibComprasSesiones.pas'
$materializar = Leer 'src\Lib\inLibComprasSesionesMaterializar.pas'
Comprobar (($sesiones -match 'FDM\.ConexionPrincipal') -and
    ($sesiones -match 'ADM\.ConexionPrincipal') -and
    ($materializar -match 'conn\s*:=\s*ADM\.ConexionPrincipal;') -and
    ($sesiones -notmatch '\boConn\b') -and
    ($materializar -notmatch '\boConn\b')) `
  'Compras y materializacion usan la conexion de su modulo de datos'

$ticket = Leer 'src\Lib\inLibGenerarTicket.pas'
$ticketBd = Leer 'src\Lib\inLibGenerarTicketBD.pas'
$correo = Leer 'src\Lib\inLibCorreoTickets.pas'
$contratosTicket =
  ($ticket -match
    'procedure\s+ImprimirT\(AConexion:\s*TUniConnection;') -and
  ($ticketBd -match
    'procedure\s+ImprimirTicketDesdeBD\(AConexion:\s*TUniConnection;') -and
  ($correo -match
    'function\s+EnviarDocumentacionOperacion\(AConexion:\s*TUniConnection;')
Comprobar $contratosTicket `
  'Tickets y correo exigen una conexion explicita'

$tablas = Leer 'src\Lib\inLibtb.pas'
$busquedas = Leer 'src\Lib\inLibGenBusq.pas'
$facturas = Leer 'src\Lib\inLibFacturas.pas'
$contratosGenerales =
  ($tablas -match
    'function\s+ObtenerSiguienteContador\(AConexion:\s*TUniConnection;') -and
  ($busquedas -match
    'EjecutarBusqueda\(AConexion:\s*TUniConnection;') -and
  ($facturas -match
    'constructor\s+Create\(AConexion:\s*TUniConnection;')
Comprobar $contratosGenerales `
  'Tablas, busquedas y facturacion exigen una conexion explicita'

$atributos = Leer 'src\Lib\inLibAtributosPaleta.pas'
$contratosAtributos =
  ($atributos -match
    'function\s+ObtenerInfoBasico\(AConexion:\s*TUniConnection;') -and
  ($atributos -match
    'procedure\s+CargarMapaAtributosArticulo\(AConexion:\s*TUniConnection;') -and
  ($atributos -match
    'function\s+SeleccionarAvConPaleta\(AConexion:\s*TUniConnection;')
Comprobar $contratosAtributos `
  'La paleta y sus caches reciben la conexion del consumidor'

$restantesPermitidos = @()
$archivosPascal = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
    -Filter '*.pas'
)
$refs = 0
$lineasRefs = 0
$unidades = 0
$fuera = @()
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
    if ($restantesPermitidos -notcontains $relativa) {
      $fuera += $relativa
    }
  }
}
Comprobar (($fuera.Count -eq 0) -and
    ($refs -eq 0) -and
    ($lineasRefs -eq 0) -and
    ($unidades -eq 0)) `
  'XI-D deja cero referencias pendientes'

$largas = @()
foreach ($archivo in $consumidores) {
  $numero = 0
  foreach ($linea in (Get-Content -LiteralPath $archivo.FullName)) {
    $numero++
    if (($linea -match '\b(AConexion|ConexionPrincipal)\b') -and
        ($linea.Length -gt 80)) {
      $largas += ('{0}:{1}' -f $archivo.FullName, $numero)
    }
  }
}
Comprobar ($largas.Count -eq 0) `
  'Las lineas de inyeccion en inLib respetan 80 columnas'

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
  'XI-C no modifica ningun DFM'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase XI-C no han sido superadas.'
}
