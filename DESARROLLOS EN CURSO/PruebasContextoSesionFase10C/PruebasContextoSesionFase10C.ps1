$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaGlobales = Join-Path $raiz 'src\Lib\inLibGlobalVar.pas'
$rutaAdaptador = Join-Path $raiz 'src\Lib\inLibContextoSesionGlobal.pas'
$rutaProyecto = Join-Path $raiz 'fzam.dpr'
$rutaDocumentos = Join-Path $raiz 'src\Lib\inLibDocumentosTrabajo.pas'
$rutaFiltro = Join-Path $raiz 'src\Lib\inLibFiltroUsuario.pas'
$rutaLayout = Join-Path $raiz 'src\Lib\inLibLayoutForm.pas'
$rutaPermisos = Join-Path $raiz 'src\Lib\inLibPermisosAdmin.pas'
$rutaFotos = Join-Path $raiz 'src\Lib\inLibFotos.pas'
$rutaValores = Join-Path $raiz 'src\Lib\inLibValoresAutomaticos.pas'
$rutaPivote = Join-Path $raiz 'src\Lib\inLibGridPivoteCompra.pas'
$rutaVentasWs = Join-Path $raiz 'src\Lib\inLibVentasWsCola.pas'
$rutaVerifactu = Join-Path $raiz 'src\verifactu\inLibVerifactu.pas'
$rutaCola = Join-Path $raiz 'src\verifactu\inLibVerifactuCola.pas'
$rutaEnvio = Join-Path $raiz 'src\verifactu\inLibVerifactuEnvio.pas'
$proyecto = Get-Content -Raw -LiteralPath $rutaProyecto
$documentos = Get-Content -Raw -LiteralPath $rutaDocumentos
$filtro = Get-Content -Raw -LiteralPath $rutaFiltro
$layout = Get-Content -Raw -LiteralPath $rutaLayout
$permisos = Get-Content -Raw -LiteralPath $rutaPermisos
$fotos = Get-Content -Raw -LiteralPath $rutaFotos
$valores = Get-Content -Raw -LiteralPath $rutaValores
$pivote = Get-Content -Raw -LiteralPath $rutaPivote
$ventasWs = Get-Content -Raw -LiteralPath $rutaVentasWs
$verifactu = Get-Content -Raw -LiteralPath $rutaVerifactu
$cola = Get-Content -Raw -LiteralPath $rutaCola
$envio = Get-Content -Raw -LiteralPath $rutaEnvio
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
$archivosFuente = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse -Filter '*.pas'
)
$archivosFuente += Get-Item -LiteralPath $rutaProyecto
$archivosConsumidores = @(
  $archivosFuente | Where-Object {
    ($_.FullName -ne $rutaGlobales) -and
    ($_.FullName -ne $rutaAdaptador) -and
    ($_.FullName -ne $rutaProyecto)
  }
)
$referenciasGlobales = @(
  Select-String -Path $archivosConsumidores.FullName `
    -Pattern $patronGlobalSesion
)
$referenciasAdaptador = @(
  Select-String -Path $archivosConsumidores.FullName `
    -Pattern '(?i)\binLibContextoSesionGlobal\b'
)
$consumidoresNoVisuales = $documentos + $filtro + $layout + $permisos +
  $fotos + $valores + $pivote + $ventasWs + $verifactu + $cola + $envio

Comprobar ($referenciasGlobales.Count -eq 0) `
  'Los consumidores no leen variables globales de sesión'
Comprobar ($consumidoresNoVisuales -notmatch $patronGlobalSesion) `
  'Las librerías migradas no leen estado global de sesión'
Comprobar ($referenciasAdaptador.Count -eq 0) `
  'Ningún consumidor depende del adaptador transitorio'
Comprobar (
    ($proyecto -match '\binLibContextoSesionIntf\b') -and
    ($proyecto -match '\binLibContextoSesion\b')
  ) 'El proyecto registra los contratos y la implementación del contexto'
Comprobar (
    ($documentos -match
      'AContextoSesion:\s*IContextoSesionAplicacion') -and
    ($documentos -match
      'AContextoSesion\.Identidad\.Usuario') -and
    ($documentos -match
      'AContextoSesion\.Ubicacion')
  ) 'Documentos de trabajo recibe identidad y ubicación por contrato'
Comprobar (
    ($filtro -match
      'RestriccionEmpAlmCajaActiva\(\s*' +
      'const AContextoSesion: IContextoSesionAplicacion') -and
    ($filtro -match 'AContextoSesion\.Identidad\.EsAdministrador') -and
    ($filtro -match 'AContextoSesion\.Ubicacion')
  ) 'Los filtros de usuario dependen del contexto explícito'
Comprobar (
    ($layout -match
      'const AContextoSesion: IContextoSesionAplicacion') -and
    ($layout -match 'Identidad := AContextoSesion\.Identidad')
  ) 'La carga de layouts recibe la identidad mediante el contexto'
Comprobar (
    ($permisos -match
      'const AContextoSesion: IContextoSesionAplicacion') -and
    ($permisos -match 'AContextoSesion\.Identidad\.Usuario')
  ) 'La administración de permisos recibe el contexto'
Comprobar (
    ($fotos -match
      'AFicheroOrigen, AUsuario: string') -and
    ($fotos -match
      'AHorario: Boolean;\s*const AUsuario: string') -and
    ($fotos -notmatch $patronGlobalSesion)
  ) 'La escritura de fotos recibe el usuario explícitamente'
Comprobar (
    ($valores -match
      'ObtenerSiguienteContador\(AConexion:\s*TUniConnection;\s*' +
      'const ATipoDocumento,\s*AUsuario:\s*string\)') -and
    ($valores -match
      '''pUSUARIO_MODIF''.*AsString :=\s*AUsuario')
  ) 'La reserva de contadores recibe el usuario explícitamente'
Comprobar (
    ($pivote -match
      'ContextoSesion\s*: IContextoSesionAplicacion') -and
    ($pivote -match
      'FCfg\.ContextoSesion\.Identidad\.Usuario')
  ) 'El pivote de compras recibe el contexto en su configuración'
Comprobar (
    ($ventasWs -match 'FUsuario: string') -and
    ($ventasWs -match
      'THiloVentasWsCola\.Create\(\s*AConexiones, AUsuario\)') -and
    ($ventasWs -notmatch $patronGlobalSesion)
  ) 'La cola de ventas captura el usuario al crear su hilo'
Comprobar (
    ($cola -match 'FUsuario:\s*string') -and
    ($cola -match
      'THiloVerifactuCola\.Create\(AConexiones, AUsuario\)') -and
    ($cola -notmatch $patronGlobalSesion)
  ) 'La cola Verifactu captura el usuario al crear su hilo'
Comprobar (
    ($verifactu -match
      'RegistrarEventoVerifactu\(AConn: TUniConnection;\s*' +
      'const AUsuario: string') -and
    ($envio -match
      'EnviarRegistroFactura\(AConn: TUniConnection;\s*' +
      'const AUsuario: string')
  ) 'El subsistema fiscal recibe el usuario en sus contratos'

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

$dfmPermitidosXI_B1 = @(
  'src\Forms\inMtoStockConsulta.dfm',
  'src\Modals\inMtoModalFacturarAlbaranesFechas.dfm'
)
$dfmModificados = @(
  & git -C $raiz diff --name-only -- 'src/*.dfm' 'src/**/*.dfm' |
    ForEach-Object { $_.Replace('/', '\') }
)
$dfmFueraXI_B1 = @(
  $dfmModificados |
    Where-Object { $dfmPermitidosXI_B1 -notcontains $_ }
)
Comprobar ($dfmFueraXI_B1.Count -eq 0) `
  'Solo XI-B1 modifica DFM para introducir herencia visual'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase X-C no han sido superadas.'
}
