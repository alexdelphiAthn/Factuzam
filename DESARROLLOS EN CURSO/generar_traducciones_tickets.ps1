param(
  [string]$Raiz = (Join-Path $PSScriptRoot '..'),
  [string]$Idioma = 'ca-ES',
  [string]$RutaSalida = (
    Join-Path $PSScriptRoot 'traducciones_ca_es_tickets_d24.sql')
)

$catalogoCatalan = @"
STicketRegaloNumero|TIQUET REGAL Núm. %s
STicketFacturaSimplificadaNumero|FACTURA SIMPLIFICADA Núm. %s
STicketOperacionNumero|TIQUET D'OPERACIÓ Núm. %s
STicketCifNif|CIF/NIF: %s
STicketTelefono|TELÈFON: %s
STicketEtiquetaOperacionNumero|OPERACIÓ NÚM.
STicketFormatoTienda|%s Bot.%s-%s
STicketCabeceraArticulos|Article/SKU                 U.    Total
STicketSuma|SUMA
STicketDescuento|DESCOMPTE
STicketValeRecogido|VAL RECOLLIT
STicketAPagar|A PAGAR
STicketCambioEfectivo|CANVI EFECTIU
STicketValeEmitidoFavor|VAL EMÈS AL SEU FAVOR
STicketCodigoValeEmitido|CODI DEL VAL EMÈS:
STicketCodigoValeEmitidoEspacio|CODI DEL VAL EMÈS: 
STicketBaseImponible|BASE IMPOSABLE
STicketBaseImponibleReducida|BASE IMPOSABLE RED.
STicketTotalIvaFormato|TOTAL IVA(%.0f%%)
STicketLeAtendio|L'HA ATÈS: %s
STicketIvaIncluido|IVA INCLÒS
STicketGraciasVisita|GRÀCIES PER LA SEVA VISITA
STicketResumenOperacion|*** RESUM DE L'OPERACIÓ ***
STicketDepositosEntregas|DIPÒSITS I LLIURAMENTS
STicketEtiquetaCodigoCliente|CODI CLIENT:
STicketEtiquetaFecha|DATA:
STicketEtiquetaNumeroOperacion|NÚM. OPERACIÓ:
STicketValorArticulo|Valor de l'article: %s €
STicketEntregasCuenta|LLIURAMENTS A COMPTE
STicketCuentaArticulo|A compte: %s
STicketCuentaInicialArticulo|A compte inicial: %s
STicketCuentaArticuloPendiente|A compte per a article pendent
STicketCuentaInicial|A compte inicial
STicketDevolucionEconomica|DEVOLUCIÓ ECONÒMICA
STicketTotalNuevosDepositos|TOTAL DIPÒSITS NOUS: %s €
STicketTotalDepositosDevueltos|TOTAL DIPÒSITS RETORNATS: %s €
STicketAnticiposEntregadosAhora|BESTRETES LLIURADES ARA: %s €
STicketDevueltoOperacion|RETORNAT EN AQUESTA OPERACIÓ: %s €
STicketTotalPagadoDepositos|TOTAL PAGAT (TIQUET + DIPÒSITS): %s €
STicketConformeCliente|Conforme, el client
STicketMovimientoDepositosPrestamos|MOVIMENT DE DIPÒSITS/PRÉSTECS
STicketDevolucionArticulos|DEVOLUCIÓ D'ARTICLES
STicketEstadoCuentaDepositos|ESTAT DEL SEU COMPTE LLIURAMENTS/DIPÒSITS
STicketFormatoFechaLarga|dd/mm/yyyy hh:nn
STicketEmpresa|EMPRESA:
STicketCliente|CLIENT:
STicketFechaHora|Data/Hora
STicketTotal|Total
STicketPendiente|Pendent
STicketRetiradoEn|  RETIRAT A (%s)
STicketEntregaInicial|  > Lliurament inicial
STicketACuenta|  > A compte
STicketTotalPendientePago|TOTAL PENDENT DE PAGAMENT:
STicketEntradaCambio|ENTRADA DE CANVI
STicketGastoRetiradaCaja|DESPESA / RETIRADA DE CAIXA
STicketFecha|Data:
STicketCaja|Caixa:
STicketEmpleado|Empleat:
STicketOperacionAbreviada|Op.:
STicketConcepto|Concepte:
STicketImporte|IMPORT:
STicketFirma|Signatura:
STicketSolicitudTraspaso|SOL·LICITUD DE TRASPÀS
STicketTraspaso|TRASPÀS
STicketOrigen|Origen:
STicketDestino|Destinació:
STicketEstado|Estat:
STicketArticulos|ARTICLES
STicketUnidadesPedidas|  Unitats demanades:
STicketUnidades|  Unitats:
STicketStockOrigen|  Estoc origen:
STicketStockDestino|  Estoc destinació:
STicketStockOrigenTrasTraspaso|  Estoc origen després del traspàs:
STicketStockDestinoTrasTraspaso|  Estoc destinació després del traspàs:
STicketOperacion|Operació:
STicketStockOrigenActual|  Estoc origen actual:
STicketStockDestinoActual|  Estoc destinació actual:
STicketCif|CIF: %s
STicketPrimeraOperacion|Primera operació:
STicketUltimaOperacion|Última operació:
STicketOperaciones|OPERACIONS
STicketUnidadesVenta|UNITATS VENDA
STicketLineasArticulos|LÍNIES D'ARTICLES
STicketBruto|  BRUT
STicketVentasNormales|  Vendes normals
STicketVentasPrestamos|+ Vendes préstecs
STicketDevoluciones|− Devolucions
STicketTotalVentas|= TOTAL VENDES
STicketCobros|COBRAMENTS
STicketValesRecogidos|  Vals recollits
STicketValesEmitidos|+ Vals emesos
STicketCobrosClientes|+ Cobraments clients
STicketPendienteCobro|− Pendent cobrament
STicketIngresosCaja|= Ingressos caixa
STicketEfectivo|EFECTIU
STicketEfectivoIngresos|  Efectiu ingressos
STicketEfectivoEntradas|+ Efectiu entrades
STicketEfectivoSalidas|− Efectiu sortides
STicketEfectivoAnterior|+ Efectiu anterior
STicketEfectivoCaja|= Efectiu en caixa
STicketOtrosIngresos|+ Altres (targeta/...)
STicketSaldoRecontar|= SALDO A RECOMPTAR
STicketDevolucionesClientes|DEVOLUCIONS CLIENTS
STicketNetoArticulos|  NET ARTICLES
STicketResumenNetoSeccion|RESUM NET PER SECCIÓ
STicketResumenVentasTemporada|RESUM VENDES PER TEMPORADA
STicketFormatoResumenTemporada|%-20s %s u.
STicketResumenVentasEmpleado|RESUM VENDES PER EMPLEAT
STicketFormatoResumenEmpleado|%-12s  %3d op.
STicketResumenFormaPago|RESUM PER FORMA DE PAGAMENT
STicketFormatoResumenFormaPago|%-12s  %3d u.
STicketResumenVentasSerie|RESUM VENDES PER SÈRIE
STicketCabeceraSerie|SÈ
STicketCabeceraBaseImponible|BASE IMP
STicketCabeceraPorcentajeIva|%IVA
STicketCabeceraCuota|QUOTA
STicketArqueoCaja|ARQUEIG CAIXA %s
STicketPeriodoSeleccionado|PERÍODE SELECCIONAT
STicketDesde|DES DE %s
STicketHasta|FINS A %s
STicketDuplicado|*** DUPLICAT ***
STicketCierreCaja|TANCAMENT DE CAIXA %s
STicketPeriodoCerrado|PERÍODE TANCAT
STicketInicio|Inici:
STicketFin|Fi:
STicketVentas|Vendes:
STicketCierrePor|Tancament per:
STicketVendedor|Venedor:
STicketBilletesMonedas|BITLLETS I MONEDES
STicketEfectivoSistema|EFECTIU SISTEMA
STicketVentasSangrado|  Vendes:
STicketEntradasSangrado|  + Entrades:
STicketGastosSangrado|  - Despeses:
STicketAnteriorSangrado|  + Anterior:
STicketTotalSangrado|  = Total:
STicketRecuento|RECOMPTE
STicketSistemaAbreviado|Sist.
STicketRecuentoAbreviado|Rec.
STicketDiferenciaAbreviada|Dif.
STicketTotalSistema|TOTAL SISTEMA:
STicketTotalRecontado|TOTAL RECOMPTAT:
STicketDiferencia|DIFERÈNCIA:
STicketRetirada|RETIRADA:
STicketDestinoSangrado|  Destinació:
STicketDejoCaja|DEIXO EN CAIXA:
STicketObservaciones|Obs.: %s
STicketCambio|CANVI
STicketNumeroFactura|Núm. Fac.: %s
STicketOperacionCorta|Op.%s
STicketClienteCorto|Cli.: %s
STicketTotalTraspasoCoste|TOTAL TRASPÀS (cost)
STicketEntregadoCuenta|  Lliurat a compte
STicketPendienteSangrado|  Pendent
STicketRotuloTraspaso|TRASPÀS
STicketRotuloIngreso|INGRÉS
STicketRotuloGasto|DESPESA
STicketRotuloDeposito|DIPÒSIT
STicketRotuloVenta|VENDA
STicketTraspasosSalientes|-TRASPASSOS SORTINTS (ORIGEN)-
STicketIngresosPorCaja|-INGRESSOS PER CAIXA-
STicketGastosPorCaja|-DESPESES PER CAIXA-
STicketVentasCreditoDepositos|-VENDES A CRÈDIT (DIPÒSITS)-
STicketVentasFacturadas|-VENDES FACTURADES-
STicketTraspasos|TRASPASSOS
STicketSubtotalCoste|SUBTOTAL (cost)
STicketIngresos|INGRESSOS
STicketSubtotal|SUBTOTAL
STicketGastos|DESPESES
STicketDepositos|DIPÒSITS
STicketSubtotalVenta|SUBTOTAL VENDA
STicketSubtotalCobrado|SUBTOTAL COBRAT
STicketTotalVentasSinSigno|TOTAL VENDES
STicketArqueoCajaHora|-ARQUEIG CAIXA %s HORA %s-
STicketDel|DEL %s
STicketAl|AL  %s
STicketTodasSeries|TOTES LES SÈRIES
STicketSeries|SÈRIES: %s
STicketOrdenCronologico|ORDRE: CRONOLÒGIC
STicketOrdenTipoDocumento|ORDRE: PER TIPUS DE DOCUMENT
STicketSinOperaciones|Sense operacions
STicketResumen|-RESUM-
"@

if ($Idioma -ne 'ca-ES') {
  throw 'Este catálogo propone únicamente la traducción ca-ES.'
}
$raizResuelta = (Resolve-Path -LiteralPath $Raiz).Path
$rutaFuente = Join-Path $raizResuelta 'src\Lib\inLibMsgTickets.pas'
$textoFuente = [System.IO.File]::ReadAllText($rutaFuente)
$bloque = [regex]::Match(
  $textoFuente,
  '(?is)\bresourcestring\b(.*?)\bimplementation\b')
if (-not $bloque.Success) {
  throw "No se encontró el bloque resourcestring en $rutaFuente."
}
$nombres = [System.Collections.Generic.List[string]]::new()
$originales = @{}
$coincidencias = [regex]::Matches(
  $bloque.Groups[1].Value,
  '(?ms)^\s*(STicket[A-Za-z0-9_]+)\s*=\s*(.*?);')
foreach ($coincidencia in $coincidencias) {
  $nombre = $coincidencia.Groups[1].Value
  $partes = [regex]::Matches(
    $coincidencia.Groups[2].Value,
    "'(?:''|[^'])*'")
  $original = ''
  foreach ($parte in $partes) {
    $original += $parte.Value.Substring(
      1,
      $parte.Value.Length - 2).Replace("''", "'")
  }
  $nombres.Add($nombre)
  $originales[$nombre] = $original
}
$traducciones = @{}
foreach ($linea in ($catalogoCatalan -split "`r?`n")) {
  if ($linea.Trim() -ne '') {
    $separador = $linea.IndexOf('|')
    if ($separador -lt 1) {
      throw "Línea de catálogo no válida: $linea"
    }
    $nombre = $linea.Substring(0, $separador)
    $traduccion = $linea.Substring($separador + 1)
    if ($traducciones.ContainsKey($nombre)) {
      throw "Traducción duplicada: $nombre"
    }
    $traducciones[$nombre] = $traduccion
  }
}
$faltantes = @($nombres | Where-Object {
  -not $traducciones.ContainsKey($_)
})
$sobrantes = @($traducciones.Keys | Where-Object {
  -not $nombres.Contains($_)
})
if ($faltantes.Count -gt 0) {
  throw 'Faltan traducciones: ' + ($faltantes -join ', ')
}
if ($sobrantes.Count -gt 0) {
  throw 'Sobran traducciones: ' + ($sobrantes -join ', ')
}
$patronFormato = '%(?:[-+0-9.]*[dDuUxXeEfFgGnNmMpPsS%])'
foreach ($nombre in $nombres) {
  $formatosOriginal = (
    [regex]::Matches($originales[$nombre], $patronFormato) |
      ForEach-Object { $_.Value }) -join '|'
  $formatosTraduccion = (
    [regex]::Matches($traducciones[$nombre], $patronFormato) |
      ForEach-Object { $_.Value }) -join '|'
  if ($formatosOriginal -ne $formatosTraduccion) {
    throw "Marcadores incompatibles en $nombre."
  }
}
function Convertir-HexUtf8([string]$Valor) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Valor)
  return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
}
$lineas = [System.Collections.Generic.List[string]]::new()
$lineas.Add('-- D24: traducción catalana de todos los tickets térmicos.')
$lineas.Add('-- Generado por generar_traducciones_tickets.ps1.')
$lineas.Add('-- Idempotente: actualiza la pareja clave/idioma si ya existe.')
$lineas.Add('SET NAMES utf8mb4;')
$lineas.Add('INSERT INTO fza_traducciones (')
$lineas.Add('  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,')
$lineas.Add('  ESACTIVO_TRAD, INSTANTE_ALTA, USUARIO_ALTA')
$lineas.Add(') VALUES')
$contexto = 'src/Lib/inLibMsgTickets.pas'
for ($i = 0; $i -lt $nombres.Count; $i++) {
  $nombre = $nombres[$i]
  $clave = 'inLibMsgTickets.' + $nombre
  $terminador = ','
  if ($i -eq $nombres.Count - 1) {
    $terminador = ''
  }
  $lineas.Add(
    '  (CONVERT(0x' + (Convertir-HexUtf8 $clave) +
    ' USING utf8mb4),')
  $lineas.Add(
    "   '$Idioma', CONVERT(0x" +
    (Convertir-HexUtf8 $traducciones[$nombre]) +
    ' USING utf8mb4),')
  $lineas.Add(
    '   CONVERT(0x' + (Convertir-HexUtf8 $contexto) +
    ' USING utf8mb4),')
  $lineas.Add(
    "   'S', CURRENT_TIMESTAMP, 'D24')$terminador")
}
$lineas.Add('ON DUPLICATE KEY UPDATE')
$lineas.Add('  TEXTO_TRAD = VALUES(TEXTO_TRAD),')
$lineas.Add('  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),')
$lineas.Add('  ESACTIVO_TRAD = ''S'',')
$lineas.Add('  INSTANTE_MODIF = CURRENT_TIMESTAMP,')
$lineas.Add('  USUARIO_MODIF = VALUES(USUARIO_ALTA);')
$lineas.Add('-- Comprobación de las traducciones de ticket activas.')
$lineas.Add('SELECT COUNT(*) AS TICKETS_CA_ES')
$lineas.Add('  FROM fza_traducciones')
$lineas.Add(' WHERE IDIOMA_TRAD = ''ca-ES''')
$lineas.Add('   AND ESACTIVO_TRAD = ''S''')
$lineas.Add(
  "   AND CLAVE_TRAD LIKE 'inLibMsgTickets.%';")
$contenido = ($lineas -join "`r`n") + "`r`n"
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText(
  $RutaSalida,
  $contenido,
  $utf8Bom)
Write-Output "IDIOMA=$Idioma"
Write-Output "TRADUCCIONES=$($nombres.Count)"
Write-Output "SALIDA=$RutaSalida"
