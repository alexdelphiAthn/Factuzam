param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(1, [int]::MaxValue)]
  [int]$MaximoColumnas = 80,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoExit = 1349,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoContinue = 107,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasAnchas = 577,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasConTabulador = 0,
  [switch]$MostrarTodos
)

# Trinquete gradual del libro de estilo (secciones 1 y 16): evitar
# Exit y Continue, 80 columnas maximo y sangria con espacios, nunca
# tabuladores. Los topes congelan la medida actual del codigo legado
# y solo pueden bajar; el codigo nuevo entra limpio porque cualquier
# infraccion nueva supera el tope y falla el build.

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
    Anchas = $lineasAnchas
    Tabuladores = $lineasConTabulador
  }
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
    $medicion.Anchas + $medicion.Tabuladores
  if ($totalUnidad -gt 0) {
    $mediciones.Add([pscustomobject]@{
      Unidad = $archivo.BaseName
      Exit = $medicion.Exit
      Continue = $medicion.Continue
      Anchas = $medicion.Anchas
      Tabuladores = $medicion.Tabuladores
      Total = $totalUnidad
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
    })
  }
}

function Sumar-Columna {
  param(
    [System.Collections.Generic.List[object]]$Lista,
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

$totalExit = Sumar-Columna -Lista $mediciones -Propiedad 'Exit'
$totalContinue = Sumar-Columna -Lista $mediciones -Propiedad 'Continue'
$totalAnchas = Sumar-Columna -Lista $mediciones -Propiedad 'Anchas'
$totalTabuladores = Sumar-Columna `
  -Lista $mediciones `
  -Propiedad 'Tabuladores'

$ordenadas = @(
  $mediciones |
    Sort-Object Total -Descending
)
$limite = 20
if ($MostrarTodos) {
  $limite = $ordenadas.Count
}
Write-Output 'Estilo por unidad (Exit, Continue, ancho, tabuladores):'
Write-Output (
  $ordenadas |
    Select-Object -First $limite |
    Format-Table `
      Unidad, Exit, Continue, Anchas, Tabuladores, Ruta `
      -AutoSize |
    Out-String -Width 200
).TrimEnd()

$errores = [System.Collections.Generic.List[string]]::new()
if ($totalExit -gt $MaximoExit) {
  $errores.Add(
    "Llamadas a Exit: $totalExit; maximo permitido: $MaximoExit.")
}
if ($totalContinue -gt $MaximoContinue) {
  $errores.Add(
    "Llamadas a Continue: $totalContinue; maximo permitido: " +
    "$MaximoContinue.")
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
  "$totalContinue. Lineas anchas: $totalAnchas. Lineas con " +
  "tabulador: $totalTabuladores.")
