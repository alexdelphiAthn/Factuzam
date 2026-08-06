param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [int]$MaximoFlujo = 92,
  [int]$MaximoMetodosMayoresDe200 = 0
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
    [string]$Nombre,
    [int]$Maximo = $MaximoFlujo
  )
  $ruta = Join-Path $Raiz $RutaRelativa
  $metodos = Obtener-MetodosPascal -Ruta $ruta
  $encontrados = @($metodos | Where-Object { $_.Nombre -eq $Nombre })
  if ($encontrados.Count -ne 1) {
    throw "No se encontro una implementacion unica de $Nombre."
  }
  $metodo = $encontrados[0]
  if ($metodo.Lineas -gt $Maximo) {
    throw (
      "$RutaRelativa`:$($metodo.Linea) $Nombre ocupa " +
      "$($metodo.Lineas) lineas; maximo permitido: $Maximo.")
  }
  return $metodo
}

$objetivos = @(
  @{
    Ruta = 'src\Caja\DataModules\UniDataCaja.pas'
    Nombre = 'TdmCajaOpe.GrabarFacturaSimplificada'
  },
  @{
    Ruta = 'src\verifactu\UniDataVerifactuColaOperaciones.pas'
    Nombre = 'GuardarRegistroNoVerifactu'
  },
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Nombre = 'TMaterializadorComprasSesiones.Ejecutar'
  },
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Nombre = 'TRevertidorComprasSesiones.Ejecutar'
  },
  @{
    Ruta = 'src\DataModules\UniDataPedidosCompraCreacionAlbaran.pas'
    Nombre = 'CrearAlbaranDesdePedidoConCantidadesInterno'
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
    Ruta = 'src\Caja\DataModules\UniDataArqueoPersistencia.pas'
    Nombre = 'TPersistenciaArqueoUniDAC.GrabarArqueo'
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
    Ruta = 'src\Lib\inLibColumnasSkuModoTallas.pas'
    Nombre = 'TModoEntradaTallas.Desmontar'
  },
  @{
    Ruta = 'src\Lib\inLibPrestaImporter.pas'
    Nombre = 'TPrestaConn.CargarPedido'
  },
  @{
    Ruta = 'src\Forms\inMtoDevolucionesCompra.pas'
    Nombre = 'TfrmMtoDevolucionesCompra.DevolverTodoStock'
    Maximo = 30
  },
  @{
    Ruta = 'src\Forms\inMtoDevolucionesCompra.pas'
    Nombre = 'TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion'
  },
  @{
    Ruta = 'src\Forms\inMtoPedidosCompra.pas'
    Nombre = 'TfrmMtoPedidosCompra.btnCrearAlbaranClick'
    Maximo = 15
  },
  @{
    Ruta = 'src\Forms\inMtoPedidos.pas'
    Nombre = 'TfrmMtoPedidos.ConstruirModoEntrada'
    Maximo = 60
  },
  @{
    Ruta = 'src\Forms\inMtoAlbaranes.pas'
    Nombre = 'TfrmMtoAlbaranes.AplicarArticuloAlbaran'
    Maximo = 60
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Nombre = 'TdmAlbaranes.GenerarMovimientosSalida'
    Maximo = 60
  },
  @{
    Ruta = 'src\Core\inMtoPreviewTicket.pas'
    Nombre = 'TFormVisualizador.ProcesarComandosESCPOS'
  },
  @{
    Ruta = 'src\Caja\Lib\inLibTiraCajaTicket.pas'
    Nombre = 'TTiraCajaTicket.Imprimir'
  },
  @{
    Ruta = 'src\Lib\inLibGenerarTicket.pas'
    Nombre = 'ImprimirT'
  },
  @{
    Ruta = 'src\Core\inMtoPrincipal.pas'
    Nombre = 'TfrmMtoPrincipal.InicializarAplicacion'
  }
)
$mediciones = [System.Collections.Generic.List[object]]::new()
foreach ($objetivo in $objetivos) {
  $maximoObjetivo = $MaximoFlujo
  if ($objetivo.ContainsKey('Maximo')) {
    $maximoObjetivo = [int]$objetivo.Maximo
  }
  $medicion = Comprobar-Metodo `
    -RutaRelativa $objetivo.Ruta `
    -Nombre $objetivo.Nombre `
    -Maximo $maximoObjetivo
  $mediciones.Add($medicion)
}

$gruposFlujosExtraidos = @(
  @{
    Ruta = 'src\Core\inMtoPreviewTicket.pas'
    Patron = '^TFormVisualizador\.(LeerByteComando|LeerWordComando|' +
      'VaciarBufferTexto|ReiniciarFormatoTexto|DibujarLineaCorte|' +
      'ProcesarComandoESC|ProcesarCodigoBarras|ProcesarComandoQR|' +
      'ProcesarImagenRasterGS|ProcesarComandoGS)$'
    Minimo = 10
  },
  @{
    Ruta = 'src\Caja\Lib\inLibTiraCajaTicket.pas'
    Patron = '^TImpresorTiraCajaTicket\.'
    Minimo = 12
  },
  @{
    Ruta = 'src\Lib\inLibGenerarTicket.pas'
    Patron = '^TImpresorTicketVenta\.'
    Minimo = 16
  },
  @{
    Ruta = 'src\Core\inMtoPrincipal.pas'
    Patron = '^TfrmMtoPrincipal\.(PrepararContextoAplicacion|' +
      'MostrarSplashInicio|CrearInfraestructuraAplicacion|' +
      'CrearParametrosSesion|CrearServiciosSesion|' +
      'ComprobarConfiguracionFiscal|CargarDatosArranque|' +
      'RegistrarFabricasPantallas|IniciarProcesosSegundoPlano|' +
      'ActualizarEstadoSesion|ConfigurarPresentacionPrincipal|' +
      'RegistrarInicioAplicacion|CargarServiciosAplicacion|' +
      'ActivarAplicacion|PresentarAplicacion|' +
      'FinalizarArranqueAplicacion)$'
    Minimo = 16
  }
)
foreach ($grupo in $gruposFlujosExtraidos) {
  $rutaGrupo = Join-Path $Raiz $grupo.Ruta
  $metodosGrupo = @(
    Obtener-MetodosPascal -Ruta $rutaGrupo |
      Where-Object { $_.Nombre -match $grupo.Patron }
  )
  if ($metodosGrupo.Count -lt $grupo.Minimo) {
    throw "Faltan colaboradores extraidos en $($grupo.Ruta)."
  }
  foreach ($metodo in $metodosGrupo) {
    if ($metodo.Lineas -gt $MaximoFlujo) {
      throw (
        "$($grupo.Ruta)`:$($metodo.Linea) $($metodo.Nombre) ocupa " +
        "$($metodo.Lineas) lineas; maximo permitido: $MaximoFlujo.")
    }
  }
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

$gruposAyudantesRecepcion = @(
  @{
    Ruta = 'src\DataModules\UniDataPedidosCompraCreacionAlbaran.pas'
    Nombres = @(
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
      'BorrarCabeceraAlbaranCompra'
    )
  },
  @{
    Ruta = 'src\DataModules\UniDataPedidosCompraAlbaranComun.pas'
    Nombres = @(
      'CerrarAlbaranCompra',
      'AplicarTemporadaArticulosAlbaran',
      'FinalizarAlbaranCreado'
    )
  }
)
foreach ($grupo in $gruposAyudantesRecepcion) {
  $rutaPedidosCompra = Join-Path $Raiz $grupo.Ruta
  $contenidoPedidosCompra =
    Get-Content -LiteralPath $rutaPedidosCompra -Raw
  $metodosPedidosCompra =
    Obtener-MetodosPascal -Ruta $rutaPedidosCompra
  foreach ($nombre in $grupo.Nombres) {
    $metodo = @(
      $metodosPedidosCompra |
        Where-Object { $_.Nombre -eq $nombre }
    )
    if ($metodo.Count -ne 1) {
      throw "No se encontro un ayudante unico de recepcion: $nombre."
    }
    if ($metodo[0].Lineas -gt $MaximoFlujo) {
      throw (
        "$($grupo.Ruta)`:$($metodo[0].Linea) $nombre ocupa " +
        "$($metodo[0].Lineas) lineas; maximo permitido: " +
        "$MaximoFlujo.")
    }
    $referencias = [regex]::Matches(
      $contenidoPedidosCompra,
      "\b$nombre\b").Count
    if ($referencias -lt 2) {
      throw "El ayudante de recepcion $nombre no tiene consumidor."
    }
  }
}
$rutaPedidosCompra = Join-Path $Raiz `
  'src\DataModules\UniDataPedidosCompraCreacionAlbaran.pas'
$contenidoPedidosCompra =
  Get-Content -LiteralPath $rutaPedidosCompra -Raw
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
  'ReferenciaDocumento',
  'FechaOperacion',
  'TextoSeries',
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
    '(?s)ProcesarOperaciones.*?ListarOperaciones' -or
    $contenidoTiraCaja -notmatch
    '(?s)VolcarVenta.*?ListarLineasVenta' -or
    $contenidoTiraCaja -notmatch
    '(?s)VolcarTraspaso.*?ListarLineasTraspaso' -or
    $contenidoTiraCaja -notmatch
    '(?s)VolcarDeposito.*?ListarDepositos') {
  throw 'La tira Excel no conserva el lote o sus read models compartidos.'
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
  'ImporteAnticipo',
  'PrecioCosteUnitario'
)
foreach ($contrato in $contratosTiraCaja) {
  if (-not $contenidoTiraCaja.Contains($contrato)) {
    throw "La tira Excel no conserva el contrato: $contrato."
  }
}

$rutaArqueoPersistencia =
  Join-Path $Raiz 'src\Caja\DataModules\UniDataArqueoPersistencia.pas'
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
      "UniDataArqueoPersistencia.pas`:$($metodo[0].Linea) $nombre ocupa " +
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
    'CargarCabecera.*?ListarNuevosDepositosResguardo.*?' +
    'EscribirCabecera.*?EscribirDepositos.*?EscribirEntregas.*?' +
    'EscribirDevolucionEconomica.*?' +
    'ListarDepositosDevueltosResguardo.*?EscribirDepositos.*?' +
    'EscribirResumen.*?GenerarSalida') {
  throw 'El resguardo no conserva el orden de sus secciones y salida.'
}
$contratosResguardoDeposito = @(
  'IRepositorioResguardosCaja',
  'ListarNuevosDepositosResguardo',
  'ListarEntregasResguardo',
  'ListarDevolucionesEconomicasResguardo',
  'ListarDepositosDevueltosResguardo',
  'ObtenerTotalPagadoResguardo',
  'ListarPieTicket',
  'STicketMovimientoDepositosPrestamos',
  'STicketEntregasCuenta',
  'STicketDevolucionEconomica',
  'STicketDevolucionArticulos',
  'STicketTotalPagadoDepositos',
  'ImprimirOPrevisualizarTicket'
)
foreach ($contrato in $contratosResguardoDeposito) {
  if (-not $contenidoGenerarTicketBD.Contains($contrato)) {
    throw "El resguardo no conserva el contrato: $contrato."
  }
}
$rutaTicketRecordatorio =
  Join-Path $Raiz 'src\Lib\inLibTicketRecordatorio.pas'
$contenidoTicketRecordatorio =
  Get-Content -LiteralPath $rutaTicketRecordatorio -Raw
if (-not $contenidoTicketRecordatorio.Contains('FRutasPDF.Add')) {
  throw 'El recordatorio no conserva la salida de la ruta PDF.'
}
if ($contenidoGenerarTicketBD -match
    '(?i)\b(TUniConnection|TUniQuery|SELECT|INSERT|UPDATE|DELETE|CALL)\b') {
  throw 'inLibGenerarTicketBD no puede volver a conocer UniDAC ni SQL.'
}
$rutaFormularioConsultaOpe =
  Join-Path $Raiz 'src\Forms\inMtoConsultaOpe.pas'
$contenidoFormularioConsultaOpe =
  Get-Content -LiteralPath $rutaFormularioConsultaOpe -Raw
if ($contenidoFormularioConsultaOpe -notmatch
    '(?s)TDependenciasConsultaOperacionesCaja.*?' +
    'FRepositorioTraspasoTicket\s*:=\s*' +
    'ADependencias\.TraspasoTicket' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)FRepositoriosTicketsCaja\s*:=\s*' +
    'ADependencias\.Tickets' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)FLecturasImpresionTicket\s*:=\s*' +
    'ADependencias\.LecturasTicket' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)EnviarDocumentacionOperacion\(.*?' +
    'FRepositorioTraspasoTicket.*?' +
    'FRepositoriosTicketsCaja.*?ConexionPrincipal' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)ImprimirTicketDesdeBD\(.*?' +
    'FRepositoriosTicketsCaja\.Tickets' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)ImprimirResguardoDeposito\(.*?' +
    'FRepositoriosTicketsCaja\.Resguardos' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)ImprimirRecordatorio\(.*?' +
    'FRepositoriosTicketsCaja\.Recordatorios' -or
    $contenidoFormularioConsultaOpe -notmatch
    '(?s)ImprimirTicketOperacionCaja\(.*?' +
    'FLecturasImpresionTicket') {
  throw 'La consulta de operaciones no conserva el repositorio de tickets.'
}
$rutaFormularioCajaOpe =
  Join-Path $Raiz 'src\Caja\Forms\inMtoCajaOpe.pas'
$contenidoFormularioCajaOpe =
  Get-Content -LiteralPath $rutaFormularioCajaOpe -Raw
$rutaComposicionCajaOpe = Join-Path $Raiz `
  'src\Caja\Forms\inMtoCajaOperacionVclInyeccion.pas'
$contenidoComposicionCajaOpe =
  Get-Content -LiteralPath $rutaComposicionCajaOpe -Raw
if ($contenidoFormularioCajaOpe -notmatch
    '(?s)TDependenciasOperacionCaja.*?' +
    'FDependenciasPantalla\s*:=\s*ADependencias' -or
    $contenidoFormularioCajaOpe -notmatch
    '(?s)EnviarDocumentacionOperacion\(.*?' +
    'FDependenciasPantalla\.TraspasoTicket.*?' +
    'FDependenciasPantalla\.Tickets.*?ConexionPrincipal' -or
    $contenidoFormularioCajaOpe -notmatch
    '(?s)CrearDependenciasOperacionCajaVclUniDAC\(.*?' +
    'FDependenciasPantalla\.Tickets' -or
    $contenidoComposicionCajaOpe -notmatch
    '(?s)AsignarRepositorioTicketsCaja\(ARepositoriosTickets\).*?' +
    'TImpresorVentaVcl\.Create\(.*?' +
    'ARepositoriosTickets\.Tickets') {
  throw 'La caja no conserva la composición del repositorio de tickets.'
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
  'SQLExcluirVentaRetirada'
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

$rutaModoTallas =
  Join-Path $Raiz 'src\Lib\inLibColumnasSkuModoTallas.pas'
$contenidoModoTallas =
  Get-Content -LiteralPath $rutaModoTallas -Raw
$rutaTallasConversion =
  Join-Path $Raiz 'src\Lib\inLibModoTallasConversion.pas'
$contenidoTallasConversion =
  Get-Content -LiteralPath $rutaTallasConversion -Raw
$rutaTallasLineas =
  Join-Path $Raiz 'src\Lib\inLibModoTallasLineas.pas'
$contenidoTallasLineas =
  Get-Content -LiteralPath $rutaTallasLineas -Raw
$rutaTallasPersistencia =
  Join-Path $Raiz 'src\DataModules\UniDataModoTallas.pas'
$contenidoTallasPersistencia =
  Get-Content -LiteralPath $rutaTallasPersistencia -Raw
$ayudantesDesmontajeTallas = @(
  'UnidadesDocumento',
  'ResolverTallaArticulo',
  'AplicarCelda',
  'ExpandirCeldas',
  'Expandir',
  'Ejecutar'
)
$metodosTallasConversion =
  Obtener-MetodosPascal -Ruta $rutaTallasConversion
$contenidoDesmontaje =
  $contenidoTallasConversion + $contenidoModoTallas
foreach ($nombre in $ayudantesDesmontajeTallas) {
  $nombreCompleto = 'TDesmontajeTallas.' + $nombre
  $metodo = @(
    $metodosTallasConversion |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de des-pivote: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibModoTallasConversion.pas`:$($metodo[0].Linea) " +
      "$nombre ocupa $($metodo[0].Lineas) lineas; " +
      "maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoDesmontaje,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de des-pivote $nombre no tiene consumidor."
  }
}
if ($contenidoTallasConversion -notmatch
    '(?s)TDesmontajeTallas\.Ejecutar.*?EnTransaccion.*?' +
    'IniciarTransaccion.*?rUnidadesAntes := UnidadesDocumento.*?' +
    'Expandir.*?ComprobarInvarianteUnidades.*?' +
    'ConfirmarTransaccion.*?except.*?RevertirTransaccion.*?raise') {
  throw 'El des-pivote no conserva su orden transaccional.'
}
if ($contenidoTallasPersistencia -notmatch
    '(?s)IniciarTransaccion;.*?StartTransaction.*?' +
    'ConfirmarTransaccion;.*?Commit.*?' +
    'RevertirTransaccion;.*?Rollback') {
  throw 'La persistencia de tallas pierde su puente transaccional.'
}
if ($contenidoModoTallas -notmatch
    '(?s)TModoEntradaTallas\.Desmontar.*?' +
    'TDesmontajeTallas\.Create\(.*?Ejecutar.*?' +
    'FreeAndNil\(Desmontaje\)') {
  throw 'La fachada de des-pivote no coordina su colaborador.'
}
$contratosDesmontajeConversion = @(
  'ModoTallas.Desmontar: %d celdas expandidas a lineas'
)
foreach ($contrato in $contratosDesmontajeConversion) {
  if (-not $contenidoTallasConversion.Contains($contrato)) {
    throw "El des-pivote no conserva el contrato: $contrato."
  }
}
$contratosDesmontajeLineas = @(
  'Format(''%.*d''',
  'ConjuntoPivot).AsInteger := 0'
)
foreach ($contrato in $contratosDesmontajeLineas) {
  if (-not $contenidoTallasLineas.Contains($contrato)) {
    throw "Las lineas de tallas no conservan el contrato: $contrato."
  }
}
$contratosDesmontajePersistencia = @(
  'JOIN fza_atributos_valores AV',
  'AS ALMC',
  'AS VALOR',
  'AS CANT',
  'GROUP BY',
  'HAVING SUM(c.',
  'ORDER BY LIN, ALMC, VALOR',
  'DELETE FROM ',
  'WhereNumero',
  'WhereDocExtra'
)
foreach ($contrato in $contratosDesmontajePersistencia) {
  if (-not $contenidoTallasPersistencia.Contains($contrato)) {
    throw (
      "La persistencia de tallas no conserva el contrato: $contrato.")
  }
}
if ($contenidoModoTallas -match
    '(?i)\b(TUniConnection|TUniQuery|SELECT|INSERT|UPDATE|' +
    'DELETE|CALL)\b') {
  throw 'inLibColumnasSkuModoTallas no puede volver a conocer SQL.'
}

$rutaPrestaImporter =
  Join-Path $Raiz 'src\Lib\inLibPrestaImporter.pas'
$contenidoPrestaImporter =
  Get-Content -LiteralPath $rutaPrestaImporter -Raw
$ayudantesCargaPedidoPresta = @(
  'SolicitarNodo',
  'LeerImporte',
  'LeerNif',
  'CargarPedidoBase',
  'CargarCliente',
  'AsignarDireccion',
  'CargarProvincia',
  'CargarDireccion',
  'CargarDirecciones',
  'CargarCabeceraEconomica',
  'CargarTransportista',
  'CargarEstadoPedido',
  'CargarLineas',
  'CargarMensajesHilo',
  'CargarMensajes',
  'Ejecutar'
)
$metodosPrestaImporter =
  Obtener-MetodosPascal -Ruta $rutaPrestaImporter
foreach ($nombre in $ayudantesCargaPedidoPresta) {
  $nombreCompleto = 'TCargaPedidoPresta.' + $nombre
  $metodo = @(
    $metodosPrestaImporter |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw "No se encontro un ayudante unico de pedido Presta: $nombre."
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibPrestaImporter.pas`:$($metodo[0].Linea) " +
      "$nombre ocupa $($metodo[0].Lineas) lineas; " +
      "maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoPrestaImporter,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de pedido Presta $nombre no tiene consumidor."
  }
}
if ($contenidoPrestaImporter -notmatch
    '(?s)TCargaPedidoPresta\.Ejecutar.*?' +
    'CargarPedidoBase.*?CargarCliente.*?CargarDirecciones.*?' +
    'CargarCabeceraEconomica.*?CargarTransportista.*?' +
    'CargarEstadoPedido.*?CargarLineas.*?try.*?' +
    'CargarMensajes.*?except.*?Result := FPedido.*?FPedido := nil') {
  throw 'La carga de pedido Presta no conserva su secuencia.'
}
if ($contenidoPrestaImporter -notmatch
    '(?s)TPrestaConn\.CargarPedido.*?' +
    'TCargaPedidoPresta\.Create\(Self\).*?Ejecutar\(sIdPedido\).*?' +
    'FreeAndNil\(Carga\)') {
  throw 'La fachada de pedido Presta no coordina su colaborador.'
}
$contratosCargaPedidoPresta = @(
  '/orders/?display=full&filter[id]=[',
  '/customers/?display=[firstname,lastname,email]&filter[id]=[',
  '/addresses/?display=[id,firstname,lastname,address1,address2,',
  '/states/?display=[id,name]&filter[id]=[',
  '/carriers/?display=[name]&filter[id]=[',
  '/order_states/?display=[name]&filter[id]=[',
  '/customer_threads/?display=full&filter[id_order]=[',
  '/customer_messages/?display=full&filter[id_customer_thread]=[',
  'LeerNif(Nodo, ''vatnumber'', ''vat_number'')',
  'LeerNif(Nodo, ''vat_number'', ''vatnumber'')',
  'FPedido.PutAdressDelinbil',
  'Nodo.NodeName = ''order_row''',
  'Nodo.NodeName = ''customer_message''',
  'Los pedidos sin hilos de mensajes son válidos.'
)
foreach ($contrato in $contratosCargaPedidoPresta) {
  if (-not $contenidoPrestaImporter.Contains($contrato)) {
    throw "La carga de pedido Presta no conserva: $contrato."
  }
}

$rutaAplicacionArticuloDevolucion =
  Join-Path $Raiz `
    'src\Lib\inLibComprasPantallaArticuloDevolucion.pas'
$contenidoAplicacionArticuloDevolucion =
  Get-Content -LiteralPath $rutaAplicacionArticuloDevolucion -Raw
$rutaFormularioArticuloDevolucion =
  Join-Path $Raiz 'src\Forms\inMtoDevolucionesCompra.pas'
$contenidoFormularioArticuloDevolucion =
  Get-Content -LiteralPath $rutaFormularioArticuloDevolucion -Raw
$rutaPresentacionArticuloDevolucion = Join-Path $Raiz `
  'src\Lib\inLibDevolucionesCompraPresentacionFlujo.pas'
$contenidoPresentacionArticuloDevolucion =
  Get-Content -LiteralPath $rutaPresentacionArticuloDevolucion -Raw
$ayudantesAplicacionArticuloDevolucion = @(
  'ResolverEntrada',
  'CargarDatos',
  'CrearLinea',
  'Ejecutar'
)
$metodosAplicacionArticuloDevolucion =
  Obtener-MetodosPascal -Ruta $rutaAplicacionArticuloDevolucion
foreach ($nombre in $ayudantesAplicacionArticuloDevolucion) {
  $nombreCompleto =
    'TAplicacionArticuloDevolucionCompra.' + $nombre
  $metodo = @(
    $metodosAplicacionArticuloDevolucion |
      Where-Object { $_.Nombre -eq $nombreCompleto }
  )
  if ($metodo.Count -ne 1) {
    throw (
      'No se encontro un ayudante unico de articulo devuelto: ' +
      "$nombre.")
  }
  if ($metodo[0].Lineas -gt $MaximoFlujo) {
    throw (
      "inLibComprasPantallaArticuloDevolucion.pas:" +
      "$($metodo[0].Linea) " +
      "$nombre ocupa $($metodo[0].Lineas) lineas; " +
      "maximo permitido: $MaximoFlujo.")
  }
  $referencias = [regex]::Matches(
    $contenidoAplicacionArticuloDevolucion +
      $contenidoFormularioArticuloDevolucion +
      $contenidoPresentacionArticuloDevolucion,
    "\b$nombre\b").Count
  if ($referencias -lt 3) {
    throw "El ayudante de articulo devuelto $nombre no tiene consumidor."
  }
}
if ($contenidoAplicacionArticuloDevolucion -notmatch
    '(?s)TAplicacionArticuloDevolucionCompra\.Ejecutar.*?' +
    'ResolverEntrada.*?CargarDatos.*?' +
    'ResolverConjuntoPivotArticulo.*?CrearLinea.*?' +
    'Result\.Aplicado := True') {
  throw 'La aplicacion de articulo devuelto no conserva su secuencia.'
}
if ($contenidoFormularioArticuloDevolucion -notmatch
    '(?s)TfrmMtoDevolucionesCompra\.AplicarArticuloDevolucion.*?' +
    'AsegurarCabeceraPersistidaParaLineas.*?' +
    'FAplicandoArticulo := True.*?try.*?' +
    'RecogerEntradaArticuloDevolucion.*?' +
    'FAplicacionArticulo\.Ejecutar.*?' +
    'PresentarResultadoArticuloDevolucion.*?' +
    'finally.*?FAplicandoArticulo := False') {
  throw 'La fachada de articulo devuelto no coordina su colaborador.'
}
$contratosAplicacionArticuloDevolucion = @(
  'FResolver.ResolverDatos(',
  'FResolver.ResolverUltimoCoste(',
  'FDatos.ModeloProveedorArticulo(',
  'FDatos.EsCodigoArticuloExacto(',
  'FDatos.ResolverConjuntoPivotArticulo(',
  'Result.Total := Result.Cantidad * Result.PrecioCompra',
  'Result.PrepararColor :='
)
foreach ($contrato in $contratosAplicacionArticuloDevolucion) {
  if (-not $contenidoAplicacionArticuloDevolucion.Contains($contrato)) {
    throw "La aplicacion de articulo devuelto no conserva: $contrato."
  }
}
$contratosFormularioArticuloDevolucion = @(
  'RefrescarVisibilidadTallas',
  'CargarCaptionsAtributosLineaActiva'
)
foreach ($contrato in $contratosFormularioArticuloDevolucion) {
  if (-not $contenidoFormularioArticuloDevolucion.Contains($contrato)) {
    throw "La fachada de articulo devuelto no conserva: $contrato."
  }
}
$contratosPresentacionArticuloDevolucion = @(
  'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
  'ID_AC_PIVOT_DEVCLIN',
  'TOTAL_UNIDADES_DEVCLIN',
  'PrepararColorPendienteDevolucion(',
  'TThread.ForceQueue(nil'
)
foreach ($contrato in $contratosPresentacionArticuloDevolucion) {
  if (-not $contenidoPresentacionArticuloDevolucion.Contains($contrato)) {
    throw "La presentacion de articulo devuelto no conserva: $contrato."
  }
}
$rutaRepositorioArticuloDevolucion = Join-Path $Raiz `
  'src\DataModules\UniDataDevolucionesCompraRepositorio.pas'
$contenidoRepositorioArticuloDevolucion = Get-Content `
  -LiteralPath $rutaRepositorioArticuloDevolucion `
  -Raw
$contratosRepositorioArticuloDevolucion = @(
  'FROM fza_articulos_conjuntos_asign ACA',
  'ACA.ID_VA_ACA <>',
  'FROM fza_articulos_proveedores AP',
  'AP.CODIGO_PRV_AP = :PROVEEDOR',
  'AP.ESPROVEEDORPRINCIPAL_AP',
  'FROM fza_articulos'
)
foreach ($contrato in $contratosRepositorioArticuloDevolucion) {
  if (-not $contenidoRepositorioArticuloDevolucion.Contains($contrato)) {
    throw "El repositorio de articulo devuelto no conserva: $contrato."
  }
}

$exclusiones = @(
  '\3rdpartyComp\',
  '\Lib3par\',
  '\Lib\sqlformatter\',
  '\apps_fmx\',
  '\certapiweb\',
  '\fotos_nube\',
  '\otras pruebas\',
  '\pruebaventasws\',
  '\utilfmt80\',
  '\utilmigsqlsrv\',
  '\utilnormbbdd\',
  '\pruebas prestashop\',
  '\vcl\',
  '\vcl37\'
)
# Solo estas rutinas generadas quedan fuera de la deuda escrita a mano.
$metodosGenerados = @(
  @{
    Ruta = 'src\Lib\inLibRegistroResourcestringTraducciones.pas'
    Nombre = 'EnumerarResourcestringsTraduccion'
  },
  @{
    Ruta = 'src\Lib\inLibRegistroParametrosTraducciones.pas'
    Nombre = 'EnumerarParametrosTraduccion'
  }
)
$metodosLargos = [System.Collections.Generic.List[object]]::new()
$metodosGeneradosEncontrados =
  [System.Collections.Generic.List[object]]::new()
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
    $rutaRelativa = $archivo.FullName.Substring($Raiz.Length + 1)
    $metodos = Obtener-MetodosPascal -Ruta $archivo.FullName
    foreach ($metodo in $metodos) {
      $esGenerado = $false
      foreach ($metodoGenerado in $metodosGenerados) {
        if (($rutaRelativa -eq $metodoGenerado.Ruta) -and
            ($metodo.Nombre -eq $metodoGenerado.Nombre)) {
          $esGenerado = $true
        }
      }
      if ($esGenerado) {
        $metodosGeneradosEncontrados.Add($metodo)
      }
      elseif ($metodo.Lineas -gt 200) {
        $metodosLargos.Add($metodo)
      }
    }
  }
}
if ($metodosGeneradosEncontrados.Count -ne $metodosGenerados.Count) {
  throw (
    'No se localizaron todas las rutinas generadas excluidas del limite: ' +
    "$($metodosGeneradosEncontrados.Count); esperadas: " +
    "$($metodosGenerados.Count).")
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
Write-Output (
  'Rutinas generadas fuera del limite: ' +
  $metodosGeneradosEncontrados.Count + '.')
