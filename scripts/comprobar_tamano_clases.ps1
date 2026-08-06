param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasPorClase = 1999,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoMetodosPorClase = 103,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoCamposPorClase = 37,
  [hashtable]$LimitesClases = @{
    TfrmMtoComprasSesiones = @{
      Lineas = 1843
      Metodos = 83
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoFacturasBase = @{
      Lineas = 1603
      Metodos = 73
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoOpeCaja = @{
      Lineas = 1949
      Metodos = 95
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TEditorLineasCajaVcl = @{
      Lineas = 1817
      Metodos = 68
      Campos = 30
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 35
    }
    TdmCajaOpe = @{
      Lineas = 1704
      Metodos = 27
      Campos = 12
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TfrmMtoPedidosCompra = @{
      Lineas = 1964
      Metodos = 77
      Campos = 26
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TfrmMtoDevolucionesCompra = @{
      Lineas = 1929
      Metodos = 80
      Campos = 21
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TdmPedidos = @{
      Lineas = 1847
      Metodos = 46
      Campos = 4
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TdmFacturas = @{
      Lineas = 1999
      Metodos = 71
      Campos = 23
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TdmAlbaranes = @{
      Lineas = 1796
      Metodos = 42
      Campos = 5
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
      ObjetivoCampos = 30
    }
    TOperacionMovimientosAlbaranVenta = @{
      Lineas = 102
      Metodos = 6
      Campos = 2
      ObjetivoLineas = 300
      ObjetivoMetodos = 15
      ObjetivoCampos = 5
    }
    TPersistenciaMovimientosAlbaranVentaUniDAC = @{
      Lineas = 593
      Metodos = 22
      Campos = 3
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TUnidadTrabajoMovimientosAlbaranVentaUniDAC = @{
      Lineas = 57
      Metodos = 5
      Campos = 1
      ObjetivoLineas = 200
      ObjetivoMetodos = 10
      ObjetivoCampos = 5
    }
    TfrmMtoArticulos = @{
      Lineas = 1905
      Metodos = 87
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoPedidos = @{
      Lineas = 1872
      Metodos = 73
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmStockConsulta = @{
      Lineas = 1027
      Metodos = 38
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoInventarios = @{
      Lineas = 1979
      Metodos = 76
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TGridPivoteVenta = @{
      Lineas = 900
      Metodos = 32
      Campos = 10
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 25
    }
    TGridPivoteCompra = @{
      Lineas = 259
      Metodos = 29
      Campos = 5
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 25
    }
    TPedidosCompraUniDAC = @{
      Lineas = 143
      Metodos = 9
      Campos = 4
      ObjetivoLineas = 300
      ObjetivoMetodos = 15
      ObjetivoCampos = 6
    }
    TPedidosCompraPendientesUniDAC = @{
      Lineas = 46
      Metodos = 4
      Campos = 1
      ObjetivoLineas = 150
      ObjetivoMetodos = 5
      ObjetivoCampos = 3
    }
    TCreacionAlbaranPedidoCompraUniDAC = @{
      Lineas = 62
      Metodos = 3
      Campos = 1
      ObjetivoLineas = 150
      ObjetivoMetodos = 6
      ObjetivoCampos = 3
    }
    TIncorporacionAlbaranPedidoCompraUniDAC = @{
      Lineas = 60
      Metodos = 3
      Campos = 1
      ObjetivoLineas = 150
      ObjetivoMetodos = 5
      ObjetivoCampos = 3
    }
    TRecepcionPedidoCompraUniDAC = @{
      Lineas = 35
      Metodos = 2
      Campos = 1
      ObjetivoLineas = 150
      ObjetivoMetodos = 5
      ObjetivoCampos = 5
    }
    TCachePivoteCompra = @{
      Lineas = 127
      Metodos = 3
      Campos = 20
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TCorrespondenciaPivoteCompra = @{
      Lineas = 432
      Metodos = 11
      Campos = 3
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TEstadoEdicionPivoteCompra = @{
      Lineas = 33
      Metodos = 3
      Campos = 2
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TValidadorPivoteCompra = @{
      Lineas = 126
      Metodos = 3
      Campos = 3
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TPresentacionPivoteCompra = @{
      Lineas = 705
      Metodos = 19
      Campos = 11
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TEdicionPivoteCompra = @{
      Lineas = 1170
      Metodos = 21
      Campos = 9
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TModeloPivoteVenta = @{
      Lineas = 727
      Metodos = 31
      Campos = 15
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TPresentacionPivoteVenta = @{
      Lineas = 1131
      Metodos = 40
      Campos = 15
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TVistaPivoteVenta = @{
      Lineas = 290
      Metodos = 10
      Campos = 8
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TRepositorioPivoteVentaUniDAC = @{
      Lineas = 471
      Metodos = 15
      Campos = 2
      ObjetivoLineas = 1200
      ObjetivoMetodos = 40
      ObjetivoCampos = 20
    }
    TModoEntradaTallas = @{
      Lineas = 448
      Metodos = 22
      Campos = 12
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 20
    }
  },
  [hashtable]$LimitesUnidades = @{
    'src\Lib\inLibPedidosVentaPresentacionReglas.pas' = @{
      Lineas = 92
      Rutinas = 2
      ObjetivoLineas = 300
      ObjetivoRutinas = 10
    }
    'src\DataModules\UniDataPedidosVentaFlujoEdicion.pas' = @{
      Lineas = 216
      Rutinas = 11
      ObjetivoLineas = 400
      ObjetivoRutinas = 20
    }
    'src\Lib\inLibAlbaranesVentaPresentacionArticulo.pas' = @{
      Lineas = 108
      Rutinas = 2
      ObjetivoLineas = 300
      ObjetivoRutinas = 10
    }
    'src\Lib\inLibAlbaranesVentaPresentacionMovimientos.pas' = @{
      Lineas = 181
      Rutinas = 15
      ObjetivoLineas = 300
      ObjetivoRutinas = 20
    }
    'src\Lib\inLibVentasWsJson.pas' = @{
      Lineas = 49
      Rutinas = 1
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibVentasWsJsonIntf.pas' = @{
      Lineas = 32
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataVentasWsJson.pas' = @{
      Lineas = 550
      Rutinas = 19
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompra.pas' = @{
      Lineas = 167
      Rutinas = 8
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompraIntf.pas' = @{
      Lineas = 108
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataPedidosCompraOperaciones.pas' = @{
      Lineas = 177
      Rutinas = 19
      ObjetivoLineas = 300
      ObjetivoRutinas = 20
    }
    'src\DataModules\UniDataPedidosCompraPendientes.pas' = @{
      Lineas = 342
      Rutinas = 13
      ObjetivoLineas = 500
      ObjetivoRutinas = 15
    }
    'src\DataModules\UniDataPedidosCompraAlbaranComun.pas' = @{
      Lineas = 286
      Rutinas = 5
      ObjetivoLineas = 400
      ObjetivoRutinas = 10
    }
    'src\DataModules\UniDataPedidosCompraCreacionAlbaran.pas' = @{
      Lineas = 650
      Rutinas = 24
      ObjetivoLineas = 800
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataPedidosCompraIncorporacionAlbaran.pas' = @{
      Lineas = 158
      Rutinas = 9
      ObjetivoLineas = 700
      ObjetivoRutinas = 20
    }
    'src\DataModules\UniDataPedidosCompraRecepcion.pas' = @{
      Lineas = 68
      Rutinas = 5
      ObjetivoLineas = 250
      ObjetivoRutinas = 10
    }
    'src\Lib\inLibAlbaranesCompraMovimientos.pas' = @{
      Lineas = 64
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibAlbaranesCompraMovimientosIntf.pas' = @{
      Lineas = 27
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataAlbaranesCompraMovimientos.pas' = @{
      Lineas = 521
      Rutinas = 14
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibDevolucionesCompraMovimientos.pas' = @{
      Lineas = 182
      Rutinas = 17
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibDevolucionesCompraMovimientosIntf.pas' = @{
      Lineas = 39
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataDevolucionesCompraMovimientos.pas' = @{
      Lineas = 355
      Rutinas = 24
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibDevolucionesCompraPresentacionFlujo.pas' = @{
      Lineas = 509
      Rutinas = 21
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompraPresentacionOperacion.pas' = @{
      Lineas = 182
      Rutinas = 6
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompraPresentacionRecepcion.pas' = @{
      Lineas = 178
      Rutinas = 4
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompraPresentacionCantidades.pas' = @{
      Lineas = 587
      Rutinas = 24
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataPedidosCompraFlujoTransaccion.pas' = @{
      Lineas = 78
      Rutinas = 11
      ObjetivoLineas = 300
      ObjetivoRutinas = 20
    }
    'src\Lib\inLibArticulosVariaciones.pas' = @{
      Lineas = 169
      Rutinas = 12
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibArticulosVariacionesIntf.pas' = @{
      Lineas = 62
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataArticulosVariaciones.pas' = @{
      Lineas = 102
      Rutinas = 11
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFotos.pas' = @{
      Lineas = 293
      Rutinas = 22
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFotosPersistenciaIntf.pas' = @{
      Lineas = 97
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFotosRepositorio.pas' = @{
      Lineas = 40
      Rutinas = 1
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturasLecturasIntf.pas' = @{
      Lineas = 45
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFacturasLecturas.pas' = @{
      Lineas = 248
      Rutinas = 19
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturasValidacionCabecera.pas' = @{
      Lineas = 183
      Rutinas = 6
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturasValidacionDatos.pas' = @{
      Lineas = 531
      Rutinas = 19
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\inLibFacturasValidacionUniDAC.pas' = @{
      Lineas = 105
      Rutinas = 2
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuNoVerifactuExportIntf.pas' = @{
      Lineas = 34
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuNoVerifactuExport.pas' = @{
      Lineas = 218
      Rutinas = 17
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturaePersistenciaIntf.pas' = @{
      Lineas = 36
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFacturaeRepositorio.pas' = @{
      Lineas = 306
      Rutinas = 21
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesAlbaranes.pas' = @{
      Lineas = 656
      Rutinas = 9
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesArticulos.pas' = @{
      Lineas = 885
      Rutinas = 24
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesComposicion.pas' = @{
      Lineas = 87
      Rutinas = 1
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesDocumentosComun.pas' = @{
      Lineas = 40
      Rutinas = 1
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesEstado.pas' = @{
      Lineas = 202
      Rutinas = 7
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesMaterializar.pas' = @{
      Lineas = 209
      Rutinas = 12
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesPedidos.pas' = @{
      Lineas = 736
      Rutinas = 11
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesReversion.pas' = @{
      Lineas = 328
      Rutinas = 11
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesUnidadTrabajo.pas' = @{
      Lineas = 141
      Rutinas = 10
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibComprasSesionesMaterializacionIntf.pas' = @{
      Lineas = 70
      Rutinas = 0
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPivoteVentaCalculo.pas' = @{
      Lineas = 208
      Rutinas = 13
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPivoteVentaIntf.pas' = @{
      Lineas = 80
      Rutinas = 0
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibComprasSesionesMaterializar.pas' = @{
      Lineas = 300
      Rutinas = 10
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuCola.pas' = @{
      Lineas = 204
      Rutinas = 9
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuColaIntf.pas' = @{
      Lineas = 60
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuTipos.pas' = @{
      Lineas = 25
      Rutinas = 0
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuConstruccionEnvio.pas' = @{
      Lineas = 391
      Rutinas = 20
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuRegistroEventos.pas' = @{
      Lineas = 521
      Rutinas = 28
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuColaRepositorio.pas' = @{
      Lineas = 282
      Rutinas = 20
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuColaProcesador.pas' = @{
      Lineas = 400
      Rutinas = 17
      ObjetivoLineas = 800
      ObjetivoRutinas = 20
    }
    'src\verifactu\UniDataVerifactuColaResultados.pas' = @{
      Lineas = 117
      Rutinas = 2
      ObjetivoLineas = 900
      ObjetivoRutinas = 25
    }
    'src\verifactu\UniDataVerifactuResultadosEnvioOperacion.pas' = @{
      Lineas = 176
      Rutinas = 5
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuResultadosEnvioPersistencia.pas' = @{
      Lineas = 418
      Rutinas = 29
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
  }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Obtener-ArchivosPascalPropios {
  param([string]$RutaRaiz)
  $exclusiones = @(
    '\3rdpartyComp\',
    '\Lib3par\',
    '\Lib\sqlformatter\',
    '\apps_fmx\',
    '\certapiweb\',
    '\fotos_nube\',
    '\otras pruebas\',
    '\pruebas prestashop\',
    '\pruebaventasws\',
    '\utilfmt80\',
    '\utilmigsqlsrv\',
    '\utilnormbbdd\',
    '\vcl\',
    '\vcl37\'
  )
  $archivos = Get-ChildItem -LiteralPath (Join-Path $RutaRaiz 'src') `
    -Recurse -Filter '*.pas' -File
  return @(
    $archivos |
      Where-Object {
        $ruta = $_.FullName
        -not ($exclusiones | Where-Object { $ruta.Contains($_) })
      }
  )
}

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

function Contar-Lineas {
  param([string]$Contenido)
  return ([regex]::Matches($Contenido, "`n")).Count + 1
}

function Contar-LineasFisicas {
  param([string]$Contenido)
  if ([string]::IsNullOrEmpty($Contenido)) {
    return 0
  }
  $cantidad = [regex]::Matches(
    $Contenido,
    "`r`n|`n|`r"
  ).Count
  if (-not $Contenido.EndsWith("`n") -and
      -not $Contenido.EndsWith("`r")) {
    $cantidad++
  }
  return $cantidad
}

function Medir-UnidadProcedural {
  param(
    [string]$RutaRelativa,
    [string]$RutaRaiz
  )
  $rutaCompleta = Join-Path $RutaRaiz $RutaRelativa
  $contenido = Get-Content -LiteralPath $rutaCompleta -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $inicioImplementacion = [regex]::Match(
    $limpio,
    '(?im)^[ \t]*implementation[ \t]*\r?$')
  $rutinas = 0
  if ($inicioImplementacion.Success) {
    $implementacion = $limpio.Substring(
      $inicioImplementacion.Index + $inicioImplementacion.Length)
    $patronRutinaGlobal =
      '(?im)^[ \t]*(?:class\s+)?' +
      '(?:procedure|function|constructor|destructor|operator)\s+' +
      '[A-Za-z_][A-Za-z0-9_]*\b'
    $rutinas = [regex]::Matches(
      $implementacion,
      $patronRutinaGlobal).Count
  }
  return [pscustomobject]@{
    TieneImplementacion = $inicioImplementacion.Success
    Lineas = Contar-LineasFisicas -Contenido $contenido
    Ruta = $RutaRelativa
    Rutinas = $rutinas
    Unidad = [System.IO.Path]::GetFileNameWithoutExtension(
      $RutaRelativa)
  }
}

function Medir-ClasesUnidad {
  param(
    [System.IO.FileInfo]$Archivo,
    [string]$RutaRaiz
  )
  $contenido = Get-Content -LiteralPath $Archivo.FullName -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $clases = @{}
  $patronClase =
    '(?im)^(?<sangria>[ \t]*)(?<clase>T[A-Za-z_][A-Za-z0-9_]*)' +
    '\s*=\s*class(?:\s*\([^\r\n]*\))?'
  foreach ($coincidencia in [regex]::Matches($limpio, $patronClase)) {
    $sangria = [regex]::Escape(
      $coincidencia.Groups['sangria'].Value)
    $inicioResto = $coincidencia.Index + $coincidencia.Length
    $resto = $limpio.Substring($inicioResto)
    $fin = [regex]::Match(
      $resto,
      "(?m)^${sangria}end\s*;")
    if ($fin.Success) {
      $longitud =
        $coincidencia.Length + $fin.Index + $fin.Length
      $bloque = $contenido.Substring(
        $coincidencia.Index,
        $longitud)
      $metodos = [regex]::Matches(
        $bloque,
        '(?im)^[ \t]*(?:class\s+)?' +
        '(?:procedure|function|constructor|destructor|operator)\b'
      ).Count
      $campos = 0
      foreach ($campo in [regex]::Matches(
        $bloque,
        '(?im)^[ \t]*(?<nombres>' +
        'F[A-Za-z_][A-Za-z0-9_]*' +
        '(?:\s*,\s*F[A-Za-z_][A-Za-z0-9_]*)*)\s*:')) {
        $campos += @(
          $campo.Groups['nombres'].Value -split ','
        ).Count
      }
      $nombre = $coincidencia.Groups['clase'].Value
      $clases[$nombre.ToLowerInvariant()] = [pscustomobject]@{
        Campos = $campos
        Clase = $nombre
        Lineas = Contar-Lineas -Contenido $bloque
        Metodos = $metodos
        Ruta = [System.IO.Path]::GetRelativePath(
          $RutaRaiz,
          $Archivo.FullName)
      }
    }
  }
  $patronImplementacion =
    '(?im)^[ \t]*(?:class\s+)?' +
    '(?:procedure|function|constructor|destructor|operator)\s+' +
    '(?<clase>T[A-Za-z_][A-Za-z0-9_]*)\.' +
    '[A-Za-z_][A-Za-z0-9_]*\b'
  $implementaciones = [regex]::Matches(
    $limpio,
    $patronImplementacion)
  for ($indice = 0; $indice -lt $implementaciones.Count; $indice++) {
    $implementacion = $implementaciones[$indice]
    $clave = $implementacion.Groups['clase'].Value.ToLowerInvariant()
    if ($clases.ContainsKey($clave)) {
      $inicio = $implementacion.Index
      if ($indice + 1 -lt $implementaciones.Count) {
        $fin = $implementaciones[$indice + 1].Index
      }
      else {
        $fin = $contenido.Length
      }
      $bloque = $contenido.Substring($inicio, $fin - $inicio)
      $clases[$clave].Lineas += (
        [regex]::Matches($bloque, "`n")
      ).Count
    }
  }
  return @($clases.Values)
}

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$mediciones = [System.Collections.Generic.List[object]]::new()
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  foreach ($clase in Medir-ClasesUnidad `
    -Archivo $archivo `
    -RutaRaiz $Raiz) {
    $mediciones.Add($clase)
  }
}
if ($mediciones.Count -eq 0) {
  throw 'No se encontraron clases Pascal para analizar.'
}

$mayores = @(
  $mediciones |
    Sort-Object Lineas, Metodos, Campos -Descending |
    Select-Object -First 20
)
Write-Output 'Clases de mayor tamaño:'
Write-Output (
  $mayores |
    Format-Table Clase, Lineas, Metodos, Campos, Ruta -AutoSize |
    Out-String
).TrimEnd()

$errores = [System.Collections.Generic.List[string]]::new()
$medicionesObjetivo = [System.Collections.Generic.List[object]]::new()
foreach ($nombreClase in @($LimitesClases.Keys | Sort-Object)) {
  $limite = $LimitesClases[$nombreClase]
  $clasesEncontradas = @(
    $mediciones |
      Where-Object { $_.Clase -eq $nombreClase }
  )
  if ($clasesEncontradas.Count -ne 1) {
    $errores.Add(
      "Clase vigilada ${nombreClase}: encontradas " +
      "$($clasesEncontradas.Count); se esperaba una.")
  }
  else {
    $claseEncontrada = $clasesEncontradas[0]
    $topeCampos = $null
    $objetivoCampos = $null
    if ($limite.ContainsKey('Campos')) {
      $topeCampos = [int]$limite.Campos
    }
    if ($limite.ContainsKey('ObjetivoCampos')) {
      $objetivoCampos = [int]$limite.ObjetivoCampos
    }
    $objetivoLineas = [int]$limite.ObjetivoLineas
    $objetivoMetodos = [int]$limite.ObjetivoMetodos
    $objetivoCumplido =
      ($claseEncontrada.Lineas -le $objetivoLineas) -and
      ($claseEncontrada.Metodos -le $objetivoMetodos) -and
      (($null -eq $objetivoCampos) -or
       ($claseEncontrada.Campos -le $objetivoCampos))
    $medicionesObjetivo.Add([pscustomobject]@{
      Clase = $claseEncontrada.Clase
      ActualLineas = $claseEncontrada.Lineas
      TopeAnteriorLineas = [int]$limite.Lineas
      ObjetivoLineas = $objetivoLineas
      ActualMetodos = $claseEncontrada.Metodos
      TopeAnteriorMetodos = [int]$limite.Metodos
      ObjetivoMetodos = $objetivoMetodos
      ActualCampos = $claseEncontrada.Campos
      TopeAnteriorCampos = $topeCampos
      ObjetivoCampos = $objetivoCampos
      EstadoObjetivo = if ($objetivoCumplido) {
        'ALCANZADO'
      }
      else {
        'PENDIENTE'
      }
    })
    if ($claseEncontrada.Lineas -gt [int]$limite.Lineas) {
      $errores.Add(
        "Lineas de ${nombreClase}: $($claseEncontrada.Lineas); " +
        "maximo permitido: $($limite.Lineas).")
    }
    if ($claseEncontrada.Metodos -gt [int]$limite.Metodos) {
      $errores.Add(
        "Metodos de ${nombreClase}: $($claseEncontrada.Metodos); " +
        "maximo permitido: $($limite.Metodos).")
    }
    if (($null -ne $topeCampos) -and
        ($claseEncontrada.Campos -gt $topeCampos)) {
      $errores.Add(
        "Campos de ${nombreClase}: $($claseEncontrada.Campos); " +
        "maximo permitido: $topeCampos.")
    }
  }
}
Write-Output ''
Write-Output 'Clases-dios vigiladas:'
Write-Output (
  $medicionesObjetivo |
    Format-Table `
      Clase, ActualLineas, TopeAnteriorLineas, ObjetivoLineas, `
      ActualMetodos, TopeAnteriorMetodos, ObjetivoMetodos, `
      ActualCampos, TopeAnteriorCampos, ObjetivoCampos, `
      EstadoObjetivo `
      -AutoSize |
    Out-String -Width 260
).TrimEnd()

$medicionesUnidades = [System.Collections.Generic.List[object]]::new()
foreach ($rutaUnidad in @($LimitesUnidades.Keys | Sort-Object)) {
  $limite = $LimitesUnidades[$rutaUnidad]
  $rutaCompleta = Join-Path $Raiz $rutaUnidad
  if (-not (Test-Path -LiteralPath $rutaCompleta -PathType Leaf)) {
    $errores.Add(
      "Unidad procedural vigilada no encontrada: ${rutaUnidad}.")
  }
  else {
    $unidad = Medir-UnidadProcedural `
      -RutaRelativa $rutaUnidad `
      -RutaRaiz $Raiz
    if (-not $unidad.TieneImplementacion) {
      $errores.Add(
        "Unidad procedural ${rutaUnidad}: no se encontro implementation.")
    }
    $objetivoCumplido =
      ($unidad.Lineas -le [int]$limite.ObjetivoLineas) -and
      ($unidad.Rutinas -le [int]$limite.ObjetivoRutinas)
    $medicionesUnidades.Add([pscustomobject]@{
      Unidad = $unidad.Unidad
      ActualLineas = $unidad.Lineas
      TopeAnteriorLineas = [int]$limite.Lineas
      ObjetivoLineas = [int]$limite.ObjetivoLineas
      ActualRutinas = $unidad.Rutinas
      TopeAnteriorRutinas = [int]$limite.Rutinas
      ObjetivoRutinas = [int]$limite.ObjetivoRutinas
      EstadoObjetivo = if ($objetivoCumplido) {
        'ALCANZADO'
      }
      else {
        'PENDIENTE'
      }
      Ruta = $unidad.Ruta
    })
    if ($unidad.Lineas -gt [int]$limite.Lineas) {
      $errores.Add(
        "Lineas de ${rutaUnidad}: $($unidad.Lineas); " +
        "maximo permitido: $($limite.Lineas).")
    }
    if ($unidad.Rutinas -gt [int]$limite.Rutinas) {
      $errores.Add(
        "Rutinas de ${rutaUnidad}: $($unidad.Rutinas); " +
        "maximo permitido: $($limite.Rutinas).")
    }
  }
}
Write-Output ''
Write-Output 'Unidades procedurales vigiladas:'
Write-Output (
  $medicionesUnidades |
    Format-Table `
      Unidad, ActualLineas, TopeAnteriorLineas, ObjetivoLineas, `
      ActualRutinas, TopeAnteriorRutinas, ObjetivoRutinas, `
      EstadoObjetivo, Ruta `
      -AutoSize |
    Out-String -Width 260
).TrimEnd()

$maximoLineas = ($mediciones | Measure-Object Lineas -Maximum).Maximum
$maximoMetodos = ($mediciones | Measure-Object Metodos -Maximum).Maximum
$maximoCampos = ($mediciones | Measure-Object Campos -Maximum).Maximum
if ($maximoLineas -gt $MaximoLineasPorClase) {
  $errores.Add(
    "Lineas por clase: $maximoLineas; maximo permitido: " +
    "$MaximoLineasPorClase.")
}
if ($maximoMetodos -gt $MaximoMetodosPorClase) {
  $errores.Add(
    "Metodos por clase: $maximoMetodos; maximo permitido: " +
    "$MaximoMetodosPorClase.")
}
if ($maximoCampos -gt $MaximoCamposPorClase) {
  $errores.Add(
    "Campos F* por clase: $maximoCampos; maximo permitido: " +
    "$MaximoCamposPorClase.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object {
    Write-Error $_ -ErrorAction Continue
  }
  exit 1
}
Write-Output (
  'Tamano de clases: OK. Clases analizadas: ' +
  "$($mediciones.Count). Maximos: $maximoLineas lineas, " +
  "$maximoMetodos metodos y $maximoCampos campos F*. " +
  "Unidades procedurales vigiladas: $($medicionesUnidades.Count).")
