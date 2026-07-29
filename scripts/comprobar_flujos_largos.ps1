param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [int]$MaximoFlujo = 100,
  [int]$MaximoMetodosMayoresDe200 = 41
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Quitar-ContenidoNoEjecutable {
  param([string]$Contenido)
  $resultado = [regex]::Replace(
    $Contenido,
    "'(?:''|[^'])*'",
    {
      param($coincidencia)
      return [regex]::Replace(
        $coincidencia.Value,
        '[^\r\n]',
        ' ')
    })
  $resultado = [regex]::Replace(
    $resultado,
    '(?s)\{.*?\}|\(\*.*?\*\)',
    {
      param($coincidencia)
      return [regex]::Replace(
        $coincidencia.Value,
        '[^\r\n]',
        ' ')
    })
  $resultado = [regex]::Replace(
    $resultado,
    '(?m)//[^\r\n]*',
    {
      param($coincidencia)
      return ' ' * $coincidencia.Value.Length
    })
  return $resultado
}

function Medir-BloqueMetodo {
  param([string]$Bloque)
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $Bloque
  $inicio = [regex]::Match(
    $limpio,
    '(?im)^begin\b')
  if (-not $inicio.Success) {
    return 0
  }
  $tokens = [regex]::Matches(
    $limpio.Substring($inicio.Index),
    '(?i)\b(begin|case|try|asm|end|repeat|until)\b')
  $nivel = 0
  foreach ($token in $tokens) {
    $palabra = $token.Groups[1].Value.ToLowerInvariant()
    if ($palabra -in @('begin', 'case', 'try', 'asm', 'repeat')) {
      $nivel++
    }
    elseif ($palabra -in @('end', 'until')) {
      $nivel--
    }
    if ($nivel -eq 0) {
      $longitud = $inicio.Index + $token.Index + $token.Length
      return (
        [regex]::Matches($limpio.Substring(0, $longitud), "`n")
      ).Count + 1
    }
  }
  return ([regex]::Matches($limpio, "`n")).Count + 1
}

function Obtener-MetodosPascal {
  param([string]$Ruta)
  $contenido = Get-Content -LiteralPath $Ruta -Raw
  $patron =
    '(?m)^(?:class\s+)?(?:procedure|function|constructor|destructor)' +
    '\s+(?<nombre>[A-Za-z_][A-Za-z0-9_.]*)\b'
  $coincidencias = [regex]::Matches($contenido, $patron)
  $metodos = [System.Collections.Generic.List[object]]::new()
  for ($indice = 0; $indice -lt $coincidencias.Count; $indice++) {
    $inicio = $coincidencias[$indice].Index
    if ($indice + 1 -lt $coincidencias.Count) {
      $fin = $coincidencias[$indice + 1].Index
    }
    else {
      $fin = $contenido.Length
    }
    $bloque = $contenido.Substring($inicio, $fin - $inicio)
    $numeroLineas = Medir-BloqueMetodo -Bloque $bloque
    if ($numeroLineas -gt 0) {
      $numeroLinea =
        ([regex]::Matches($contenido.Substring(0, $inicio), "`n")).Count + 1
      $metodos.Add([pscustomobject]@{
        Nombre = $coincidencias[$indice].Groups['nombre'].Value
        Linea = $numeroLinea
        Lineas = $numeroLineas
        Ruta = $Ruta
      })
    }
  }
  return $metodos
}

function Comprobar-Metodo {
  param(
    [string]$RutaRelativa,
    [string]$Nombre
  )
  $ruta = Join-Path $Raiz $RutaRelativa
  $metodos = Obtener-MetodosPascal -Ruta $ruta
  $encontrados = @($metodos | Where-Object { $_.Nombre -eq $Nombre })
  if ($encontrados.Count -ne 1) {
    throw "No se encontro una implementacion unica de $Nombre."
  }
  $metodo = $encontrados[0]
  if ($metodo.Lineas -gt $MaximoFlujo) {
    throw (
      "$RutaRelativa`:$($metodo.Linea) $Nombre ocupa " +
      "$($metodo.Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  return $metodo
}

$objetivos = @(
  @{
    Ruta = 'src\Caja\DataModules\UniDataCaja.pas'
    Nombre = 'TdmCajaOpe.GrabarFacturaSimplificada'
  },
  @{
    Ruta = 'src\verifactu\inLibVerifactuCola.pas'
    Nombre = 'GuardarRegistroNoVerifactu'
  },
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Nombre = 'MaterializarSesion'
  },
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Nombre = 'RevertirMaterializacion'
  },
  @{
    Ruta = 'src\Lib\inLibPedidosCompra.pas'
    Nombre = 'CrearAlbaranDesdePedidoConCantidades'
  },
  @{
    Ruta = 'src\Lib\inLibBalanceTallasExcel.pas'
    Nombre = 'ExportarBalanceTallasExcel'
  },
  @{
    Ruta = 'src\Lib\inLibBalanceSinTallasExcel.pas'
    Nombre = 'ExportarBalanceSinTallasExcel'
  },
  @{
    Ruta = 'src\Lib\inLibFacturaExcel.pas'
    Nombre = 'ExportarFacturaADevExpress'
  },
  @{
    Ruta = 'src\Caja\Lib\inLibTiraCajaTicket.pas'
    Nombre = 'TTiraCajaTicket.ExportarExcel'
  },
  @{
    Ruta = 'src\Caja\Lib\inLibArqueoPersistencia.pas'
    Nombre = 'TArqueoPersistencia.GrabarArqueo'
  },
  @{
    Ruta = 'src\Lib\inLibGenerarTicketBD.pas'
    Nombre = 'ImprimirResguardoDeposito'
  },
  @{
    Ruta = 'src\DataModules\UniDataConsultaOpe.pas'
    Nombre = 'TdmConsultaOpe.DataModuleCreate'
  },
  @{
    Ruta = 'src\Forms\inMtoDevolucionesCompra.pas'
    Nombre = 'TfrmMtoDevolucionesCompra.DevolverTodoStock'
  }
)
$mediciones = [System.Collections.Generic.List[object]]::new()
foreach ($objetivo in $objetivos) {
  $medicion = Comprobar-Metodo `
    -RutaRelativa $objetivo.Ruta `
    -Nombre $objetivo.Nombre
  $mediciones.Add($medicion)
}

$rutaCaja = Join-Path $Raiz 'src\Caja\DataModules\UniDataCaja.pas'
$ayudantesCaja = @(
  Obtener-MetodosPascal -Ruta $rutaCaja |
    Where-Object { $_.Nombre -match '^TGrabacionFacturaCaja\.' }
)
if ($ayudantesCaja.Count -eq 0) {
  throw 'No se encontraron las operaciones extraidas de caja.'
}
foreach ($metodo in $ayudantesCaja) {
  if ($metodo.Lineas -gt $MaximoFlujo) {
    throw (
      "UniDataCaja.pas`:$($metodo.Linea) $($metodo.Nombre) ocupa " +
      "$($metodo.Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
}

$rutaPedidosCompra =
  Join-Path $Raiz 'src\Lib\inLibPedidosCompra.pas'
$contenidoPedidosCompra =
  Get-Content -LiteralPath $rutaPedidosCompra -Raw
$ayudantesRecepcion = @(
  'CalcularTotalCeldasRecepcion',
  'ValidarSolicitudRecepcionCeldas',
  'ReservarNumeroAlbaranCompra',
  'PrepararInsercionCabeceraAlbaranPedido',
  'AsignarParametrosCabeceraAlbaranPedido',
  'CrearCabeceraAlbaranPedido',
  'PrepararConsultaLineaPedidoRecepcion',
  'CargarLineaPedidoRecepcion',
  'CalcularCantidadRecepcion',
  'PrepararInsercionLineaAlbaranPedido',
  'AsignarParametrosLineaAlbaranPedido',
  'InsertarLineaAlbaranPedido',
  'ActualizarCantidadRecibidaPedido',
  'ProcesarCeldasRecepcionPedido',
  'BorrarCabeceraAlbaranCompra',
  'CerrarAlbaranCompra',
  'AplicarTemporadaArticulosAlbaran',
  'FinalizarAlbaranCreado'
)
$metodosPedidosCompra =
  Obtener-MetodosPascal -Ruta $rutaPedidosCompra
foreach ($nombre in $ayudantesRecepcion) {
  $metodo = @(
    $metodosPedidosCompra |
      Where-Object { $_.Nombre -eq $nombre }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de recepcion: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibPedidosCompra.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoPedidosCompra,
    "\b$nombre\b").Count
  if ($referencias -lt 2) {
    throw "El ayudante de recepcion $nombre no tiene consumidor."
  }
}
if ($contenidoPedidosCompra -notmatch
    '(?s)PrepararConsultaLineaPedidoRecepcion.*?' +
    'JOIN\s+fza_pedidos_compra\s+P.*?' +
    'P\.SERIE_PEDC\s*=\s*L\.SERIE_PEDC_PEDCLIN') {
  throw 'La consulta de linea no enlaza la cabecera fiscal del pedido.'
}

$rutaBalanceComun =
  Join-Path $Raiz 'src\Lib\inLibBalanceExcelComun.pas'
$contenidoBalanceComun =
  Get-Content -LiteralPath $rutaBalanceComun -Raw
$ayudantesBalance = @(
  'CampoTexto',
  'FormulaSuma',
  'EscribirNumero',
  'FormatearFila',
  'EscribirCabeceraColumnas',
  'IncrustarFoto',
  'AcumularBanda',
  'EmitirTotalesArticulo',
  'AbrirGrupo',
  'EmitirResumenGrupo',
  'PrecargarFotos',
  'GestionarAgrupaciones',
  'GestionarCabeceras',
  'EscribirDetalle',
  'ProcesarDatos',
  'ConfigurarColumnas',
  'Ejecutar'
)
$metodosBalanceComun =
  Obtener-MetodosPascal -Ruta $rutaBalanceComun
foreach ($nombre in $ayudantesBalance) {
  $nombreCompleto = 'TExportadorBalanceExcel.' + $nombre
  $metodo = @(
    $metodosBalanceComun |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico del balance: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibBalanceExcelComun.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoBalanceComun,
    "\b$nombre\b").Count
  if ($referencias -lt 2) {
    throw "El ayudante del balance $nombre no tiene consumidor."
  }
}
$rutaBalanceTallas =
  Join-Path $Raiz 'src\Lib\inLibBalanceTallasExcel.pas'
$rutaBalanceSinTallas =
  Join-Path $Raiz 'src\Lib\inLibBalanceSinTallasExcel.pas'
$contenidoBalanceTallas =
  Get-Content -LiteralPath $rutaBalanceTallas -Raw
$contenidoBalanceSinTallas =
  Get-Content -LiteralPath $rutaBalanceSinTallas -Raw
if ($contenidoBalanceComun -notmatch
    '(?s)PrecargarFotos.*?ResolverArticulosLote' -or
    $contenidoBalanceComun -notmatch
    '(?s)TExportadorBalanceExcel\.Ejecutar.*?BeginUpdate.*?EndUpdate') {
  throw 'El balance no conserva la carga en lote o el bloqueo de la hoja.'
}
if ($contenidoBalanceTallas -notmatch
    '(?s)ExportarBalanceExcel\s*\(.*?tbeConTallas\s*\)' -or
    $contenidoBalanceSinTallas -notmatch
    '(?s)ExportarBalanceExcel\s*\(.*?tbeSinTallas\s*\)') {
  throw 'Las fachadas de balance no seleccionan su modo correcto.'
}
$contratosBalance = @(
  'BALANCE DE ALMACEN POR TALLAS',
  'BALANCE DE ALMACEN SIN TALLAS',
  "'Cdad.'",
  "'Cantidad'",
  "'Concepto'",
  "'ETIQ_T%.2d'",
  "'T%.2d'"
)
foreach ($contrato in $contratosBalance) {
  if (-not $contenidoBalanceComun.Contains($contrato)) {
    throw "El motor de balance no conserva el contrato: $contrato."
  }
}

$rutaFacturaExcel =
  Join-Path $Raiz 'src\Lib\inLibFacturaExcel.pas'
$contenidoFacturaExcel =
  Get-Content -LiteralPath $rutaFacturaExcel -Raw
$ayudantesFacturaExcel = @(
  'CampoTexto',
  'CampoNumero',
  'TituloFactura',
  'PuedeIncrustarQR',
  'Rango',
  'ConfigurarNombreHoja',
  'AgregarImagenQR',
  'IncrustarQRVerifactu',
  'EscribirInterviniente',
  'EscribirCabecera',
  'EscribirCabeceraLineas',
  'EscribirLinea',
  'EscribirLineas',
  'EscribirCabeceraImpuestos',
  'PintarImpuesto',
  'PintarImpuestoSiProcede',
  'CargarRecargos',
  'EscribirTablaImpuestos',
  'EscribirResumen',
  'EscribirFormaPago',
  'ConfigurarColumnas',
  'Ejecutar'
)
$metodosFacturaExcel =
  Obtener-MetodosPascal -Ruta $rutaFacturaExcel
foreach ($nombre in $ayudantesFacturaExcel) {
  $nombreCompleto = 'TExportadorFacturaDevExpress.' + $nombre
  $metodo = @(
    $metodosFacturaExcel |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de factura Excel: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibFacturaExcel.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoFacturaExcel,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de factura Excel $nombre no tiene consumidor."
  }
}
if ($contenidoFacturaExcel -notmatch
    '(?s)TExportadorFacturaDevExpress\.Ejecutar.*?' +
    'BeginUpdate.*?EndUpdate' -or
    $contenidoFacturaExcel -notmatch
    '(?s)EscribirLineas.*?DisableControls.*?EnableControls' -or
    $contenidoFacturaExcel -notmatch
    '(?s)IncrustarQRVerifactu.*?ConstruirUrlQR.*?' +
    'GenerarQRPngVerifactu') {
  throw 'La factura Excel no conserva sus cierres o el QR tributario.'
}
$contratosFacturaExcel = @(
  'FACTURA SIMPLIFICADA',
  'FACTURA RECTIFICATIVA',
  'Base Imponible',
  'Total Impuestos (IVA+RE):',
  'TOTAL A PAGAR:',
  'FORMA_PAGO_FAC',
  'ESIMP_INCL_TARIFA_CLIENTE_FAC',
  'TIPO_IVA_ARTICULO_FACLIN'
)
foreach ($contrato in $contratosFacturaExcel) {
  if (-not $contenidoFacturaExcel.Contains($contrato)) {
    throw "La factura Excel no conserva el contrato: $contrato."
  }
}

$rutaTiraCaja =
  Join-Path $Raiz 'src\Caja\Lib\inLibTiraCajaTicket.pas'
$contenidoTiraCaja =
  Get-Content -LiteralPath $rutaTiraCaja -Raw
$ayudantesTiraCaja = @(
  'TextoOperacion',
  'ReferenciaDocumento',
  'FechaOperacion',
  'TextoSeries',
  'CrearConsultaDetalle',
  'AsignarParametrosDetalle',
  'EscribirMoneda',
  'EscribirCabecera',
  'VolcarVenta',
  'VolcarTraspaso',
  'VolcarIngresoGasto',
  'VolcarDeposito',
  'EscribirTituloGrupo',
  'EscribirSubtotalGrupo',
  'VolcarFila',
  'ProcesarOperaciones',
  'EscribirCierre',
  'Ejecutar'
)
$metodosTiraCaja =
  Obtener-MetodosPascal -Ruta $rutaTiraCaja
foreach ($nombre in $ayudantesTiraCaja) {
  $nombreCompleto = 'TExportadorTiraCajaExcel.' + $nombre
  $metodo = @(
    $metodosTiraCaja |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de tira de caja: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibTiraCajaTicket.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoTiraCaja,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de tira de caja $nombre no tiene consumidor."
  }
}
if ($contenidoTiraCaja -notmatch
    '(?s)TExportadorTiraCajaExcel\.Ejecutar.*?' +
    'BeginUpdate.*?EndUpdate' -or
    $contenidoTiraCaja -notmatch
    '(?s)ProcesarOperaciones.*?SQLOperaciones.*?' +
    'AsignarParamsOperaciones' -or
    $contenidoTiraCaja -notmatch
    '(?s)CrearConsultaDetalle.*?AsignarParametrosDetalle.*?Open') {
  throw 'La tira Excel no conserva el lote o sus consultas compartidas.'
}
$contratosTiraCaja = @(
  'TIRA DE CAJA · CAJA',
  'ORDEN: CRONOLOGICO',
  'ORDEN: POR TIPO DE DOCUMENTO',
  'TRASPASOS SALIENTES (ORIGEN)',
  'VENTAS A CREDITO (DEPOSITOS)',
  'SUBTOTAL TRASPASOS (coste)',
  'SUBTOTAL DEPOSITOS',
  'Crédito (depósito)',
  'IMPORTE_ANTICIPO_DEP',
  'PRECIO_COSTE_UNITARIO_MOV'
)
foreach ($contrato in $contratosTiraCaja) {
  if (-not $contenidoTiraCaja.Contains($contrato)) {
    throw "La tira Excel no conserva el contrato: $contrato."
  }
}

$rutaArqueoPersistencia =
  Join-Path $Raiz 'src\Caja\Lib\inLibArqueoPersistencia.pas'
$contenidoArqueoPersistencia =
  Get-Content -LiteralPath $rutaArqueoPersistencia -Raw
$ayudantesGrabacionArqueo = @(
  'CrearConsulta',
  'ConstruirSetOpcional',
  'ReservarNumeroRetirada',
  'InsertarCabecera',
  'AsignarParametrosOpcionales',
  'ActualizarColumnasOpcionales',
  'InsertarLineasRecuento',
  'MarcarOperaciones',
  'InsertarRetirada',
  'Ejecutar'
)
$metodosArqueoPersistencia =
  Obtener-MetodosPascal -Ruta $rutaArqueoPersistencia
foreach ($nombre in $ayudantesGrabacionArqueo) {
  $nombreCompleto = 'TGrabacionArqueo.' + $nombre
  $metodo = @(
    $metodosArqueoPersistencia |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de grabacion: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibArqueoPersistencia.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoArqueoPersistencia,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de grabacion $nombre no tiene consumidor."
  }
}
if ($contenidoArqueoPersistencia -notmatch
    '(?s)TGrabacionArqueo\.Ejecutar.*?' +
    'GenerarCodigoArqueo.*?ReservarNumeroRetirada.*?StartTransaction.*?' +
    'InsertarCabecera.*?ActualizarColumnasOpcionales.*?' +
    'InsertarLineasRecuento.*?MarcarOperaciones.*?InsertarRetirada.*?' +
    'Commit.*?except.*?Rollback') {
  throw 'La grabacion del arqueo no conserva su orden transaccional.'
}
if ($contenidoArqueoPersistencia -notmatch
    '(?s)ReservarNumeroRetirada.*?PRC_GET_NEXT_OP_CAJA.*?' +
    'pEmpresa.*?pAlmacen.*?pCaja.*?pUsuario.*?pcont') {
  throw 'La retirada no conserva el numerador centralizado previo.'
}
$contratosGrabacionArqueo = @(
  'INSERT INTO fza_caja_arqueos (',
  'INFORMATION_SCHEMA.COLUMNS',
  'INSERT INTO fza_caja_arqueos_recuento (',
  'SET CODIGO_ARQUEO_OPCAJA = :pARQ',
  'CODIGO_ARQUEO_OPCAJA IS NULL',
  'TOTAL_RECUENTO_ARQ',
  'DIFERENCIA_TOTAL_ARQ',
  'EFECTIVO_DEJADO_CAJA_ARQ',
  'DESGLOSE_BILLETES_ARQ',
  'IMPORTE_RETIRADA_ARQ',
  'TIPO_OPERACION_OPCAJA',
  "''GC''"
)
foreach ($contrato in $contratosGrabacionArqueo) {
  if (-not $contenidoArqueoPersistencia.Contains($contrato)) {
    throw "La grabacion del arqueo no conserva el contrato: $contrato."
  }
}

$rutaGenerarTicketBD =
  Join-Path $Raiz 'src\Lib\inLibGenerarTicketBD.pas'
$contenidoGenerarTicketBD =
  Get-Content -LiteralPath $rutaGenerarTicketBD -Raw
$ayudantesResguardoDeposito = @(
  'AsignarParametro',
  'AbrirConsulta',
  'CargarCabecera',
  'EscribirTituloSeccion',
  'EscribirCabecera',
  'EscribirDepositos',
  'EscribirEntregas',
  'EscribirDevolucionEconomica',
  'HayMovimientos',
  'TotalPagadoCaja',
  'EscribirResumen',
  'GenerarSalida',
  'Ejecutar'
)
$metodosGenerarTicketBD =
  Obtener-MetodosPascal -Ruta $rutaGenerarTicketBD
foreach ($nombre in $ayudantesResguardoDeposito) {
  $nombreCompleto = 'TGeneradorResguardoDeposito.' + $nombre
  $metodo = @(
    $metodosGenerarTicketBD |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico del resguardo: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibGenerarTicketBD.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoGenerarTicketBD,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante del resguardo $nombre no tiene consumidor."
  }
}
if ($contenidoGenerarTicketBD -notmatch
    '(?s)TGeneradorResguardoDeposito\.Ejecutar.*?' +
    'CargarCabecera.*?SQL_NUEVOS_DEPOSITOS_RESGUARDO.*?' +
    'EscribirCabecera.*?EscribirDepositos.*?EscribirEntregas.*?' +
    'EscribirDevolucionEconomica.*?' +
    'SQL_DEPOSITOS_DEVUELTOS_RESGUARDO.*?EscribirDepositos.*?' +
    'EscribirResumen.*?GenerarSalida') {
  throw 'El resguardo no conserva el orden de sus secciones y salida.'
}
$contratosResguardoDeposito = @(
  'fza_depositos_cliente',
  'fza_caja_operaciones',
  'fza_caja_pagos',
  'AS TOTAL_PVP',
  'MOVIMIENTO DE DEPÓSITOS/PRÉSTAMOS',
  'ENTREGAS A CUENTA',
  'DEVOLUCIÓN ECONÓMICA',
  'DEVOLUCIÓN DE ARTÍCULOS',
  'TOTAL PAGADO (TICKET + DEPÓSITOS):',
  'EscribirPieTicketCaja',
  'ImprimirOPrevisualizarTicket',
  'ARutasPDF.Add'
)
foreach ($contrato in $contratosResguardoDeposito) {
  if (-not $contenidoGenerarTicketBD.Contains($contrato)) {
    throw "El resguardo no conserva el contrato: $contrato."
  }
}

$rutaConsultaOpe =
  Join-Path $Raiz 'src\DataModules\UniDataConsultaOpe.pas'
$contenidoConsultaOpe =
  Get-Content -LiteralPath $rutaConsultaOpe -Raw
$ayudantesConsultaOpe = @(
  'ConectarConsultas',
  'ConfigurarConsultaMaestro',
  'ConfigurarConsultasCaja',
  'ConfigurarConsultasMovimientoCliente',
  'ConfigurarConsultasDepositoFactura'
)
$metodosConsultaOpe =
  Obtener-MetodosPascal -Ruta $rutaConsultaOpe
foreach ($nombre in $ayudantesConsultaOpe) {
  $nombreCompleto = 'TdmConsultaOpe.' + $nombre
  $metodo = @(
    $metodosConsultaOpe |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de consulta F10: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "UniDataConsultaOpe.pas`:$($metodo[0].Linea) $nombre ocupa " +
      "$($metodo[0].Lineas) lineas; maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoConsultaOpe,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de consulta F10 $nombre no tiene consumidor."
  }
}
if ($contenidoConsultaOpe -notmatch
    '(?s)TdmConsultaOpe\.DataModuleCreate.*?' +
    'ConectarConsultas.*?ConfigurarConsultaMaestro.*?' +
    'ConfigurarConsultasCaja.*?' +
    'ConfigurarConsultasMovimientoCliente.*?' +
    'ConfigurarConsultasDepositoFactura') {
  throw 'La consulta F10 no conserva el orden de configuracion.'
}
if ($contenidoConsultaOpe -notmatch
    '(?s)constructor TdmConsultaOpe\.Create.*?' +
    'FConexion\s*:=\s*AConexion.*?inherited Create\(AOwner\)') {
  throw 'La consulta F10 no recibe la conexion antes de OnCreate.'
}
$contratosConsultaOpe = @(
  'qryMaestro.Connection',
  'qryFacturaLin.Connection',
  'fza_caja_operaciones',
  'fza_caja_pagos',
  'fza_caja_vales',
  'fza_movimientos_almacen',
  'fza_clientes',
  'fza_caja_depositos_view',
  'fza_facturas',
  'fza_facturas_lineas',
  'SQLExcluirSimplificadaSustituida'
)
foreach ($contrato in $contratosConsultaOpe) {
  if (-not $contenidoConsultaOpe.Contains($contrato)) {
    throw "La consulta F10 no conserva el contrato: $contrato."
  }
}
$rutaDfmConsultaOpe =
  Join-Path $Raiz 'src\DataModules\UniDataConsultaOpe.dfm'
$contenidoDfmConsultaOpe =
  Get-Content -LiteralPath $rutaDfmConsultaOpe -Raw
if ($contenidoDfmConsultaOpe -notmatch
    '(?m)^\s*OnCreate\s*=\s*DataModuleCreate\s*$') {
  throw 'El DFM de consulta F10 no conserva su evento OnCreate.'
}

$exclusiones = @(
  '\3rdpartyComp\',
  '\Lib3par\',
  '\sqlformatter\',
  '\utilmigsqlsrv\',
  '\utilnormbbdd\',
  '\pruebas prestashop\'
)
$metodosLargos = [System.Collections.Generic.List[object]]::new()
$archivos = Get-ChildItem -LiteralPath (Join-Path $Raiz 'src') `
  -Recurse -Filter '*.pas' -File
foreach ($archivo in $archivos) {
  $excluido = $false
  foreach ($exclusion in $exclusiones) {
    if ($archivo.FullName.Contains($exclusion)) {
      $excluido = $true
    }
  }
  if (-not $excluido) {
    $metodos = Obtener-MetodosPascal -Ruta $archivo.FullName
    foreach ($metodo in $metodos) {
      if ($metodo.Lineas -gt 200) {
        $metodosLargos.Add($metodo)
      }
    }
  }
}
if ($metodosLargos.Count -gt $MaximoMetodosMayoresDe200) {
  throw (
    'La deuda de metodos mayores de 200 lineas ha crecido: ' +
    "$($metodosLargos.Count); maximo permitido: " +
    "$MaximoMetodosMayoresDe200.")
}

$resumen = $mediciones |
  Sort-Object Lineas -Descending |
  ForEach-Object { "$($_.Nombre)=$($_.Lineas)" }
Write-Output (
  'Flujos largos: OK. ' + ($resumen -join ', ') + '.')
Write-Output (
  'Metodos mayores de 200 lineas: ' + $metodosLargos.Count +
  ". Limite de no regresion: $MaximoMetodosMayoresDe200.")
