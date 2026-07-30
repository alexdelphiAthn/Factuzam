param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoVariablesGlobales = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoExceptVacios = 0
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

function Contar-VariablesInterfaz {
  param([string]$Contenido)
  $inicio = [regex]::Match(
    $Contenido,
    '(?im)^[ \t]*interface\b')
  $fin = [regex]::Match(
    $Contenido,
    '(?im)^[ \t]*implementation\b')
  if ((-not $inicio.Success) -or
      (-not $fin.Success) -or
      ($fin.Index -le $inicio.Index)) {
    return 0
  }
  $interfaz = $Contenido.Substring(
    $inicio.Index + $inicio.Length,
    $fin.Index - ($inicio.Index + $inicio.Length))
  $total = 0
  $patronBloque =
    '(?ims)^[ \t]*var[ \t]*\r?$\s*(?<cuerpo>.*?)' +
    '(?=^[ \t]*(?:type|const|resourcestring|threadvar|uses|' +
    'procedure|function)\b|\z)'
  foreach ($bloque in [regex]::Matches($interfaz, $patronBloque)) {
    foreach ($declaracion in [regex]::Matches(
      $bloque.Groups['cuerpo'].Value,
      '(?im)^[ \t]*(?<nombres>' +
      '[A-Za-z_][A-Za-z0-9_]*' +
      '(?:\s*,\s*[A-Za-z_][A-Za-z0-9_]*)*)\s*:')) {
      $total += @(
        $declaracion.Groups['nombres'].Value -split ','
      ).Count
    }
  }
  return $total
}

function Obtener-Linea {
  param(
    [string]$Contenido,
    [int]$Indice
  )
  return (
    [regex]::Matches($Contenido.Substring(0, $Indice), "`n")
  ).Count + 1
}

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$mediciones = [System.Collections.Generic.List[object]]::new()
$exceptVacios = [System.Collections.Generic.List[object]]::new()
$patronExceptVacio =
  '(?is)\bexcept\s*' +
  '(?:(?:on\s+[A-Za-z_][A-Za-z0-9_]*' +
  '(?:\s*:\s*[A-Za-z_][A-Za-z0-9_.]*)?\s+do\s*)?' +
  '(?:begin\s*end\s*;?|;))*\s*end\s*;'
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $globales = Contar-VariablesInterfaz -Contenido $contenido
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $vaciosUnidad = [regex]::Matches(
    $limpio,
    $patronExceptVacio)
  if (($globales -gt 0) -or ($vaciosUnidad.Count -gt 0)) {
    $mediciones.Add([pscustomobject]@{
      ExceptVacios = $vaciosUnidad.Count
      Globales = $globales
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
      Unidad = $archivo.BaseName
    })
  }
  foreach ($except in $vaciosUnidad) {
    $exceptVacios.Add([pscustomobject]@{
      Linea = Obtener-Linea `
        -Contenido $limpio `
        -Indice $except.Index
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
    })
  }
}
$totalGlobales = 0
foreach ($medicion in $mediciones) {
  $totalGlobales += $medicion.Globales
}

Write-Output 'Variables globales por unidad:'
Write-Output (
  $mediciones |
    Where-Object { $_.Globales -gt 0 } |
    Sort-Object Globales -Descending |
    Select-Object -First 20 |
    Format-Table Unidad, Globales, Ruta -AutoSize |
    Out-String
).TrimEnd()
Write-Output 'Except vacios detectados:'
Write-Output (
  $exceptVacios |
    Sort-Object Ruta, Linea |
    Format-Table Ruta, Linea -AutoSize |
    Out-String
).TrimEnd()

$errores = [System.Collections.Generic.List[string]]::new()
if ($totalGlobales -gt $MaximoVariablesGlobales) {
  $errores.Add(
    "Variables var en interface: $totalGlobales; maximo permitido: " +
    "$MaximoVariablesGlobales.")
}
if ($exceptVacios.Count -gt $MaximoExceptVacios) {
  $errores.Add(
    "Except vacios: $($exceptVacios.Count); maximo permitido: " +
    "$MaximoExceptVacios.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  'Estado global: OK. Variables var en interface: ' +
  "$totalGlobales. Except vacios: $($exceptVacios.Count).")
