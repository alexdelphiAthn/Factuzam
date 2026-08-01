param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(1, [int]::MaxValue)]
  [int]$MaximoColumnas = 80,
  [ValidateRange(-1, [int]::MaxValue)]
  [int]$MaximoExit = -1,
  [ValidateRange(-1, [int]::MaxValue)]
  [int]$MaximoContinue = -1,
  [ValidateRange(-1, [int]::MaxValue)]
  [int]$MaximoWith = -1,
  [ValidateRange(-1, [int]::MaxValue)]
  [int]$MaximoLineasAnchas = -1,
  [ValidateRange(-1, [int]::MaxValue)]
  [int]$MaximoLineasConTabulador = -1,
  [string]$RutaLineaBase = (
    Join-Path $PSScriptRoot 'estilo_linea_base.csv'),
  [switch]$OmitirLineaBasePorUnidad,
  [switch]$ActualizarLineaBase,
  [switch]$MostrarTodos
)

# Trinquete gradual de Clean Code. La linea base se conserva por unidad:
# una unidad existente no puede empeorar y una nueva debe entrar sin Exit,
# Continue, with, lineas anchas ni tabuladores. La actualizacion solo reduce
# deuda ya registrada; nunca admite deuda nueva.

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
        $ruta = $_.FullName.Replace('/', '\')
        -not ($exclusiones | Where-Object { $ruta.Contains($_) })
      }
  )
}

function Quitar-ContenidoNoEjecutable {
  param([string]$Contenido)
  return [regex]::Replace(
    $Contenido,
    "(?s)'(?:''|[^'\r\n])*'|//[^\r\n]*|\{.*?\}|\(\*.*?\*\)",
    {
      param($coincidencia)
      return [regex]::Replace(
        $coincidencia.Value,
        '[^\r\n]',
        ' ')
    })
}

function Medir-EstiloUnidad {
  param(
    [string]$Contenido,
    [int]$Columnas
  )
  $lineasAnchas = 0
  $lineasConTabulador = 0
  foreach ($linea in [regex]::Split($Contenido, "`r`n|`n|`r")) {
    if ($linea.Length -gt $Columnas) {
      $lineasAnchas++
    }
    if ($linea.Contains("`t")) {
      $lineasConTabulador++
    }
  }
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $Contenido
  return [pscustomobject]@{
    Exit = [regex]::Matches($limpio, '(?i)\bexit\b').Count
    Continue = [regex]::Matches($limpio, '(?i)\bcontinue\b').Count
    With = [regex]::Matches($limpio, '(?i)\bwith\b').Count
    Anchas = $lineasAnchas
    Tabuladores = $lineasConTabulador
  }
}

function Sumar-Columna {
  param(
    [object[]]$Lista,
    [string]$Propiedad
  )
  if ($Lista.Count -eq 0) {
    return 0
  }
  return [int](
    $Lista |
      Measure-Object $Propiedad -Sum
  ).Sum
}

function Leer-LineaBase {
  param([string]$Ruta)
  if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
    throw "No se encontro la linea base de estilo: $Ruta."
  }
  $filas = @(Import-Csv -LiteralPath $Ruta -Delimiter ';')
  $resultado = [System.Collections.Generic.Dictionary[string, object]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  foreach ($fila in $filas) {
    if ($resultado.ContainsKey($fila.Ruta)) {
      throw "Ruta duplicada en la linea base de estilo: $($fila.Ruta)."
    }
    $resultado.Add($fila.Ruta, [pscustomobject]@{
      Ruta = $fila.Ruta
      Exit = [int]$fila.Exit
      Continue = [int]$fila.Continue
      With = [int]$fila.With
      Anchas = [int]$fila.Anchas
      Tabuladores = [int]$fila.Tabuladores
    })
  }
  return $resultado
}

function Escribir-LineaBaseInicial {
  param(
    [string]$Ruta,
    [object[]]$Mediciones
  )
  $directorio = Split-Path -Parent $Ruta
  if (-not (Test-Path -LiteralPath $directorio)) {
    $null = New-Item -ItemType Directory -Path $directorio
  }
  $Mediciones |
    Sort-Object Ruta |
    Select-Object Ruta, Exit, Continue, With, Anchas, Tabuladores |
    Export-Csv `
      -LiteralPath $Ruta `
      -Delimiter ';' `
      -NoTypeInformation `
      -Encoding utf8BOM
}

function Actualizar-LineaBaseExistente {
  param(
    [string]$Ruta,
    [object[]]$Mediciones,
    [System.Collections.Generic.Dictionary[string, object]]$LineaBase
  )
  $porRuta = [System.Collections.Generic.Dictionary[string, object]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  foreach ($medicion in $Mediciones) {
    $porRuta.Add($medicion.Ruta, $medicion)
  }
  $actualizada = [System.Collections.Generic.List[object]]::new()
  foreach ($fila in $LineaBase.Values) {
    if ($porRuta.ContainsKey($fila.Ruta)) {
      $medicion = $porRuta[$fila.Ruta]
      $reducida = [pscustomobject]@{
        Ruta = $fila.Ruta
        Exit = [Math]::Min($fila.Exit, $medicion.Exit)
        Continue = [Math]::Min($fila.Continue, $medicion.Continue)
        With = [Math]::Min($fila.With, $medicion.With)
        Anchas = [Math]::Min($fila.Anchas, $medicion.Anchas)
        Tabuladores = [Math]::Min(
          $fila.Tabuladores,
          $medicion.Tabuladores)
      }
      $total = $reducida.Exit + $reducida.Continue +
        $reducida.With + $reducida.Anchas + $reducida.Tabuladores
      if ($total -gt 0) {
        $actualizada.Add($reducida)
      }
    }
  }
  Escribir-LineaBaseInicial -Ruta $Ruta -Mediciones $actualizada
}

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$mediciones = [System.Collections.Generic.List[object]]::new()
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  if ([string]::IsNullOrEmpty($contenido)) {
    continue
  }
  $medicion = Medir-EstiloUnidad `
    -Contenido $contenido `
    -Columnas $MaximoColumnas
  $totalUnidad = $medicion.Exit + $medicion.Continue +
    $medicion.With + $medicion.Anchas + $medicion.Tabuladores
  if ($totalUnidad -gt 0) {
    $mediciones.Add([pscustomobject]@{
      Unidad = $archivo.BaseName
      Exit = $medicion.Exit
      Continue = $medicion.Continue
      With = $medicion.With
      Anchas = $medicion.Anchas
      Tabuladores = $medicion.Tabuladores
      Total = $totalUnidad
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName).Replace('/', '\')
    })
  }
}

$lineaBase = $null
if (-not $OmitirLineaBasePorUnidad) {
  if (-not (Test-Path -LiteralPath $RutaLineaBase -PathType Leaf)) {
    if (-not $ActualizarLineaBase) {
      throw "No se encontro la linea base de estilo: $RutaLineaBase."
    }
    Escribir-LineaBaseInicial `
      -Ruta $RutaLineaBase `
      -Mediciones $mediciones.ToArray()
  }
  $lineaBase = Leer-LineaBase -Ruta $RutaLineaBase
}

$errores = [System.Collections.Generic.List[string]]::new()
if (-not $OmitirLineaBasePorUnidad) {
  foreach ($medicion in $mediciones) {
    if (-not $lineaBase.ContainsKey($medicion.Ruta)) {
      $errores.Add(
        "Unidad con deuda nueva y sin linea base: $($medicion.Ruta).")
      continue
    }
    $tope = $lineaBase[$medicion.Ruta]
    foreach ($propiedad in @(
      'Exit',
      'Continue',
      'With',
      'Anchas',
      'Tabuladores')) {
      if ($medicion.$propiedad -gt $tope.$propiedad) {
        $errores.Add(
          "$($medicion.Ruta): $propiedad = $($medicion.$propiedad); " +
          "linea base: $($tope.$propiedad).")
      }
    }
  }
}

if ($ActualizarLineaBase -and ($errores.Count -eq 0)) {
  Actualizar-LineaBaseExistente `
    -Ruta $RutaLineaBase `
    -Mediciones $mediciones.ToArray() `
    -LineaBase $lineaBase
  $lineaBase = Leer-LineaBase -Ruta $RutaLineaBase
  Write-Output "Linea base de estilo actualizada: $RutaLineaBase."
}

if (-not $OmitirLineaBasePorUnidad) {
  if ($MaximoExit -lt 0) {
    $MaximoExit = Sumar-Columna `
      -Lista @($lineaBase.Values) `
      -Propiedad 'Exit'
  }
  if ($MaximoContinue -lt 0) {
    $MaximoContinue = Sumar-Columna `
      -Lista @($lineaBase.Values) `
      -Propiedad 'Continue'
  }
  if ($MaximoWith -lt 0) {
    $MaximoWith = Sumar-Columna `
      -Lista @($lineaBase.Values) `
      -Propiedad 'With'
  }
  if ($MaximoLineasAnchas -lt 0) {
    $MaximoLineasAnchas = Sumar-Columna `
      -Lista @($lineaBase.Values) `
      -Propiedad 'Anchas'
  }
  if ($MaximoLineasConTabulador -lt 0) {
    $MaximoLineasConTabulador = Sumar-Columna `
      -Lista @($lineaBase.Values) `
      -Propiedad 'Tabuladores'
  }
}
elseif (@(
  $MaximoExit,
  $MaximoContinue,
  $MaximoWith,
  $MaximoLineasAnchas,
  $MaximoLineasConTabulador) -contains -1) {
  throw 'Al omitir la linea base deben indicarse todos los maximos.'
}

$totalExit = Sumar-Columna -Lista $mediciones.ToArray() -Propiedad 'Exit'
$totalContinue = Sumar-Columna `
  -Lista $mediciones.ToArray() `
  -Propiedad 'Continue'
$totalWith = Sumar-Columna -Lista $mediciones.ToArray() -Propiedad 'With'
$totalAnchas = Sumar-Columna `
  -Lista $mediciones.ToArray() `
  -Propiedad 'Anchas'
$totalTabuladores = Sumar-Columna `
  -Lista $mediciones.ToArray() `
  -Propiedad 'Tabuladores'

$ordenadas = @(
  $mediciones |
    Sort-Object Total -Descending
)
$limite = 20
if ($MostrarTodos) {
  $limite = $ordenadas.Count
}
Write-Output (
  'Estilo por unidad (Exit, Continue, with, ancho, tabuladores):')
Write-Output (
  $ordenadas |
    Select-Object -First $limite |
    Format-Table `
      Unidad, Exit, Continue, With, Anchas, Tabuladores, Ruta `
      -AutoSize |
    Out-String -Width 200
).TrimEnd()

if ($totalExit -gt $MaximoExit) {
  $errores.Add(
    "Llamadas a Exit: $totalExit; maximo permitido: $MaximoExit.")
}
if ($totalContinue -gt $MaximoContinue) {
  $errores.Add(
    "Llamadas a Continue: $totalContinue; maximo permitido: " +
    "$MaximoContinue.")
}
if ($totalWith -gt $MaximoWith) {
  $errores.Add(
    "Sentencias with: $totalWith; maximo permitido: $MaximoWith.")
}
if ($totalAnchas -gt $MaximoLineasAnchas) {
  $errores.Add(
    "Lineas de mas de $MaximoColumnas columnas: $totalAnchas; " +
    "maximo permitido: $MaximoLineasAnchas.")
}
if ($totalTabuladores -gt $MaximoLineasConTabulador) {
  $errores.Add(
    "Lineas con tabuladores: $totalTabuladores; maximo permitido: " +
    "$MaximoLineasConTabulador.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  "Estilo de codigo: OK. Exit: $totalExit. Continue: " +
  "$totalContinue. With: $totalWith. Lineas anchas: $totalAnchas. " +
  "Lineas con tabulador: $totalTabuladores.")
