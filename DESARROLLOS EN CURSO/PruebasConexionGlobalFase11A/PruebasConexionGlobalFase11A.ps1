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

$patronGlobal = '\boConn\b'

# Unidades que todavia pueden leer la conexion global. Son el trabajo
# pendiente de XI-B, XI-C y XI-D; cualquier otra unidad que aparezca aqui
# es una regresion de XI-A.
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
  'src\Forms\inMtoStockConsulta.pas',
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
  'src\Modals\inMtoModalFacturarAlbaranesFechas.pas',
  'src\Modals\inMtoModalFacturarTicket.pas',
  'src\Modals\inMtoModalSerieFechaFactura.pas',
  'src\Modals\inMtoModalVerifactuDecl.pas'
)

# Unidades migradas en XI-A. Deben usar ConexionPrincipal y no declarar
# ninguna variable local llamada oConn.
$migradas = @(
  'src\Caja\Forms\inMtoCajaFaseCobro.pas',
  'src\Caja\Forms\inMtoCajaMenu.pas',
  'src\Caja\Forms\inMtoCajaOpe.pas',
  'src\Caja\Forms\inMtoCajaOperacionesHist.pas',
  'src\Caja\Forms\inMtoCajaPagosHist.pas',
  'src\Caja\Forms\inMtoCajaParam.pas',
  'src\Caja\Forms\inMtoCajaSeleccionVale.pas',
  'src\Caja\Forms\inMtoTraspasoOpe.pas',
  'src\Caja\Modals\inMtoModalImpArqueos.pas',
  'src\Caja\Modals\inMtoModalImpDepositos.pas',
  'src\Caja\Modals\inMtoModalImpOperaciones.pas',
  'src\Caja\Modals\inMtoModalImpPagos.pas',
  'src\Core\inMtoAppParam.pas',
  'src\Core\inMtoPrincipal.pas',
  'src\DataModules\UniDataAlbaranes.pas',
  'src\DataModules\UniDataAlbaranesCompra.pas',
  'src\DataModules\UniDataArticulos.pas',
  'src\DataModules\UniDataAtributosConjuntos.pas',
  'src\DataModules\UniDataClientes.pas',
  'src\DataModules\UniDataComprasSesiones.pas',
  'src\DataModules\UniDataDevolucionesCompra.pas',
  'src\DataModules\UniDataDocumentosTrabajo.pas',
  'src\DataModules\UniDataEfectosCompra.pas',
  'src\DataModules\UniDataEfectosVenta.pas',
  'src\DataModules\UniDataEmpresas.pas',
  'src\DataModules\UniDataFacturas.pas',
  'src\DataModules\UniDataFacturasCompra.pas',
  'src\DataModules\UniDataFamilias.pas',
  'src\DataModules\UniDataFormasdePago.pas',
  'src\DataModules\UniDataGeneradorProcesos.pas',
  'src\DataModules\UniDataInventarios.pas',
  'src\DataModules\UniDataPedidos.pas',
  'src\DataModules\UniDataPedidosCompra.pas',
  'src\DataModules\UniDataProveedores.pas',
  'src\DataModules\UniDataRemesasCompra.pas',
  'src\DataModules\UniDataRemesasVenta.pas',
  'src\DataModules\UniDataUsuarios.pas',
  'src\DataModules\UniDataVariaciones.pas',
  'src\Forms\inMtoAlbaranesCompra.pas',
  'src\Forms\inMtoArticulos.pas',
  'src\Forms\inMtoBusquedaDatos.pas',
  'src\Forms\inMtoClientes.pas',
  'src\Forms\inMtoComprasPlantillas.pas',
  'src\Forms\inMtoComprasSesiones.pas',
  'src\Forms\inMtoConsultaOpe.pas',
  'src\Forms\inMtoDevolucionesCompra.pas',
  'src\Forms\inMtoEmpresas.pas',
  'src\Forms\inMtoFacturasBase.pas',
  'src\Forms\inMtoFacturasCompra.pas',
  'src\Forms\inMtoFacturasNormal.pas',
  'src\Forms\inMtoGeneradorProcesos.pas',
  'src\Forms\inMtoInventarios.pas',
  'src\Forms\inMtoPedidosCompra.pas',
  'src\Forms\inMtoPermisosArbol.pas',
  'src\Forms\inMtoPropiedades.pas',
  'src\Modals\inMtoModalCargarEfectosRemesa.pas',
  'src\Modals\inMtoModalCargarEfectosRemesaVenta.pas',
  'src\Modals\inMtoModalFacRec.pas',
  'src\Modals\inMtoModalFacturarAlbaranes.pas',
  'src\Modals\inMtoModalFacturarTicket.pas',
  'src\Modals\inMtoModalGenerarSKUs.pas',
  'src\Modals\inMtoModalGenImp.pas',
  'src\Modals\inMtoModalGuiasBase.pas',
  'src\Modals\inMtoModalImpBalanceSinTallas.pas',
  'src\Modals\inMtoModalImpBalanceTallas.pas',
  'src\Modals\inMtoModalImpDocsProveedor.pas',
  'src\Modals\inMtoModalImpEfectosPago.pas',
  'src\Modals\inMtoModalImpFac.pas',
  'src\Modals\inMtoModalImpMovVentasArt.pas',
  'src\Modals\inMtoModalImpMultiFiltro.pas',
  'src\Modals\inMtoModalListadoVentas.pas',
  'src\Modals\inMtoModalSelAlmacenAlbaran.pas',
  'src\Modals\inMtoModalSelAlmacenPedido.pas',
  'src\Modals\inMtoModalSeleccionarBanco.pas',
  'src\Modals\inMtoModalSelFamilia.pas',
  'src\Modals\inMtoModalVerifactuDecl.pas',
  'src\Modals\inMtoModalWizardEditar.pas',
  'src\verifactu\inMtoVerifactuLog.pas'
)

$archivosPascal = @(
  Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse -Filter '*.pas' |
    Where-Object { $_.FullName -notmatch '\\vcl3?7?\\' }
)
$archivosPascal += Get-Item -LiteralPath (Join-Path $raiz 'fzam.dpr')

$fuera = @()
$refs = 0
$lineasRefs = 0
foreach ($archivo in $archivosPascal) {
  $relativa = $archivo.FullName.Substring($raiz.Length + 1)
  $coincidencias = @(
    Select-String -LiteralPath $archivo.FullName -Pattern $patronGlobal -AllMatches
  )
  $cuenta = 0
  foreach ($coincidencia in $coincidencias) {
    $cuenta += $coincidencia.Matches.Count
  }
  if ($cuenta -gt 0) {
    $refs += $cuenta
    $lineasRefs += $coincidencias.Count
    if ($pendientes -notcontains $relativa) {
      $fuera += $relativa
    }
  }
}

Comprobar ($fuera.Count -eq 0) `
  'Ninguna unidad fuera del pendiente de XI-B/C/D lee la conexion global'
Comprobar (($refs -le 183) -and ($lineasRefs -le 179)) `
  'Las lineas y referencias pendientes a la conexion global no crecen'

$frmBase = Get-Content -Raw -LiteralPath `
  (Join-Path $raiz 'src\Core\inMtoFrmBase.pas')
$dmBase = Get-Content -Raw -LiteralPath `
  (Join-Path $raiz 'src\DataModules\UniDataGen.pas')
Comprobar ($frmBase -match
    'property ConexionPrincipal: TUniConnection read GetConexionPrincipal') `
  'TfrmBase publica ConexionPrincipal'
Comprobar ($dmBase -match '(?s)property ConexionPrincipal: TUniConnection\s*' +
    'read GetConexionPrincipal') `
  'TdmBase publica ConexionPrincipal'

$sinPropiedad = @()
$conLocal = @()
foreach ($relativa in $migradas) {
  $contenido = Get-Content -Raw -LiteralPath (Join-Path $raiz $relativa)
  if ($contenido -notmatch '\bConexionPrincipal\b') {
    $sinPropiedad += $relativa
  }
  if ($contenido -match '(?m)^\s*oConn\s*:(?!=)') {
    $conLocal += $relativa
  }
}
Comprobar ($sinPropiedad.Count -eq 0) `
  'Las 78 unidades migradas resuelven la conexion por ConexionPrincipal'
Comprobar ($conLocal.Count -eq 0) `
  'Ninguna unidad migrada declara una variable local llamada oConn'

# Estado definitivo tras XI-D: el puente de compatibilidad ya no existe.
$principal = Get-Content -Raw -LiteralPath `
  (Join-Path $raiz 'src\Core\inMtoPrincipal.pas')
Comprobar ($principal -notmatch '\boConn\b') `
  'La raiz no reintroduce el puente retirado en XI-D'

$largas = @()
foreach ($archivo in $archivosPascal) {
  $numero = 0
  foreach ($linea in (Get-Content -LiteralPath $archivo.FullName)) {
    $numero++
    if (($linea -match '\bConexionPrincipal\b') -and ($linea.Length -gt 80)) {
      $largas += ('{0}:{1}' -f $archivo.Name, $numero)
    }
  }
}
Comprobar ($largas.Count -eq 0) `
  'Ninguna linea con ConexionPrincipal pasa de 80 columnas'

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
  'Ningun DFM ajeno a la herencia visual de XI-B1 se modifica'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase XI-A no han sido superadas.'
}
