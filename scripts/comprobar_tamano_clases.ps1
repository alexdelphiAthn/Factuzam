param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasPorClase = 4075,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoMetodosPorClase = 133,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoCamposPorClase = 49,
  [hashtable]$LimitesClases = @{
    TfrmMtoComprasSesiones = @{
      Lineas = 3634
      Metodos = 99
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoFacturasBase = @{
      Lineas = 1779
      Metodos = 104
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoOpeCaja = @{
      Lineas = 3981
      Metodos = 104
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoArticulos = @{
      Lineas = 3344
      Metodos = 97
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmStockConsulta = @{
      Lineas = 3088
      Metodos = 81
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TfrmMtoInventarios = @{
      Lineas = 3069
      Metodos = 77
      ObjetivoLineas = 2000
      ObjetivoMetodos = 120
    }
    TGridPivoteVenta = @{
      Lineas = 944
      Metodos = 40
      Campos = 10
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 25
    }
    TGridPivoteCompra = @{
      Lineas = 2490
      Metodos = 48
      Campos = 32
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 25
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
      Lineas = 2481
      Metodos = 71
      Campos = 29
      ObjetivoLineas = 1500
      ObjetivoMetodos = 45
      ObjetivoCampos = 20
    }
  },
  [hashtable]$LimitesUnidades = @{
    'src\Lib\inLibVentasWsJson.pas' = @{
      Lineas = 52
      Rutinas = 1
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibVentasWsJsonIntf.pas' = @{
      Lineas = 64
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataVentasWsJson.pas' = @{
      Lineas = 553
      Rutinas = 19
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompra.pas' = @{
      Lineas = 174
      Rutinas = 8
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibPedidosCompraIntf.pas' = @{
      Lineas = 111
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataPedidosCompraOperaciones.pas' = @{
      Lineas = 1748
      Rutinas = 57
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibAlbaranesCompraMovimientos.pas' = @{
      Lineas = 68
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibAlbaranesCompraMovimientosIntf.pas' = @{
      Lineas = 58
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataAlbaranesCompraMovimientos.pas' = @{
      Lineas = 657
      Rutinas = 13
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibDevolucionesCompraMovimientos.pas' = @{
      Lineas = 56
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibDevolucionesCompraMovimientosIntf.pas' = @{
      Lineas = 62
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataDevolucionesCompraMovimientos.pas' = @{
      Lineas = 447
      Rutinas = 11
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibArticulosVariaciones.pas' = @{
      Lineas = 136
      Rutinas = 10
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibArticulosVariacionesIntf.pas' = @{
      Lineas = 73
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataArticulosVariaciones.pas' = @{
      Lineas = 692
      Rutinas = 43
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFotos.pas' = @{
      Lineas = 1763
      Rutinas = 43
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFotosPersistenciaIntf.pas' = @{
      Lineas = 96
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFotosRepositorio.pas' = @{
      Lineas = 466
      Rutinas = 33
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturasLecturasIntf.pas' = @{
      Lineas = 74
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFacturasLecturas.pas' = @{
      Lineas = 252
      Rutinas = 19
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\verifactu\inLibVerifactuNoVerifactuExportIntf.pas' = @{
      Lineas = 64
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuNoVerifactuExport.pas' = @{
      Lineas = 222
      Rutinas = 17
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\Lib\inLibFacturaePersistenciaIntf.pas' = @{
      Lineas = 66
      Rutinas = 2
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataFacturaeRepositorio.pas' = @{
      Lineas = 310
      Rutinas = 21
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesAlbaranes.pas' = @{
      Lineas = 638
      Rutinas = 9
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesArticulos.pas' = @{
      Lineas = 1091
      Rutinas = 26
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesComposicion.pas' = @{
      Lineas = 72
      Rutinas = 1
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesDocumentosComun.pas' = @{
      Lineas = 83
      Rutinas = 1
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesEstado.pas' = @{
      Lineas = 221
      Rutinas = 7
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesMaterializar.pas' = @{
      Lineas = 189
      Rutinas = 12
      ObjetivoLineas = 600
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesPedidos.pas' = @{
      Lineas = 770
      Rutinas = 12
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\DataModules\UniDataComprasSesionesReversion.pas' = @{
      Lineas = 359
      Rutinas = 12
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
      Lineas = 75
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
      Lineas = 206
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
    'src\verifactu\UniDataVerifactuColaRepositorio.pas' = @{
      Lineas = 881
      Rutinas = 36
      ObjetivoLineas = 1200
      ObjetivoRutinas = 30
    }
    'src\verifactu\UniDataVerifactuColaProcesador.pas' = @{
      Lineas = 417
      Rutinas = 17
      ObjetivoLineas = 800
      ObjetivoRutinas = 20
    }
    'src\verifactu\UniDataVerifactuColaResultados.pas' = @{
      Lineas = 317
      Rutinas = 5
      ObjetivoLineas = 900
      ObjetivoRutinas = 25
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
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  'Tamano de clases: OK. Clases analizadas: ' +
  "$($mediciones.Count). Maximos: $maximoLineas lineas, " +
  "$maximoMetodos metodos y $maximoCampos campos F*. " +
  "Unidades procedurales vigiladas: $($medicionesUnidades.Count).")
