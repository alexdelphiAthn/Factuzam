param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoFanOut = 101,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoFanInConCuerpo = 84,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoFanInInLibMsg = 0
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
    ' ')
  $resultado = [regex]::Replace(
    $resultado,
    '(?s)\{.*?\}|\(\*.*?\*\)',
    ' ')
  $resultado = [regex]::Replace(
    $resultado,
    '(?m)//[^\r\n]*',
    ' ')
  return $resultado
}

function Tiene-CuerpoUnidad {
  param([string]$Contenido)
  $interfaz = [regex]::Match(
    $Contenido,
    '(?is)\binterface\b(?<cuerpo>.*?)\bimplementation\b')
  if ($interfaz.Success -and
      ($interfaz.Groups['cuerpo'].Value -match
       '(?im)^[ \t]*(var|resourcestring)[ \t]*\r?$')) {
    return $true
  }
  $implementacion = [regex]::Match(
    $Contenido,
    '(?is)\bimplementation\b(?<cuerpo>.*)\bend\s*\.')
  if (-not $implementacion.Success) {
    return $false
  }
  return $implementacion.Groups['cuerpo'].Value -match
    '(?im)^[ \t]*(?:class\s+)?' +
    '(procedure|function|constructor|destructor|operator|' +
    'initialization|finalization)\b'
}

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$unidades = @{}
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $coincidencia = [regex]::Match(
    $limpio,
    '(?im)^[ \t]*unit\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;')
  if ($coincidencia.Success) {
    $nombre = $coincidencia.Groups[1].Value
    $unidades[$nombre.ToLowerInvariant()] = @{
      Archivo = $archivo.FullName
      Cuerpo = Tiene-CuerpoUnidad -Contenido $limpio
      Dependencias =
        [System.Collections.Generic.HashSet[string]]::new(
          [System.StringComparer]::OrdinalIgnoreCase)
      Nombre = $nombre
    }
  }
}
foreach ($unidad in $unidades.Values) {
  foreach ($bloque in [regex]::Matches(
    (Get-Content -LiteralPath $unidad.Archivo -Raw |
      ForEach-Object {
        Quitar-ContenidoNoEjecutable -Contenido $_
      }),
    '(?is)\buses\b(.*?);')) {
    foreach ($coincidencia in [regex]::Matches(
      $bloque.Groups[1].Value,
      '\b[A-Za-z_][A-Za-z0-9_.]*\b')) {
      if ($coincidencia.Value -ine 'in') {
        [void]$unidad.Dependencias.Add($coincidencia.Value)
      }
    }
  }
}

$fanIn = @{}
foreach ($clave in $unidades.Keys) {
  $fanIn[$clave] = 0
}
$medicionesFanOut = [System.Collections.Generic.List[object]]::new()
foreach ($unidad in $unidades.Values) {
  $fanOut = 0
  foreach ($dependencia in $unidad.Dependencias) {
    if ($unidades.ContainsKey($dependencia.ToLowerInvariant())) {
      $fanOut++
    }
  }
  $medicionesFanOut.Add([pscustomobject]@{
    FanOut = $fanOut
    Ruta = [System.IO.Path]::GetRelativePath(
      $Raiz,
      $unidad.Archivo)
    Unidad = $unidad.Nombre
  })
  foreach ($dependencia in $unidad.Dependencias) {
    $clave = $dependencia.ToLowerInvariant()
    if ($unidades.ContainsKey($clave)) {
      $fanIn[$clave]++
    }
  }
}
$medicionesFanIn = [System.Collections.Generic.List[object]]::new()
foreach ($clave in $unidades.Keys) {
  $unidad = $unidades[$clave]
  if ($unidad.Cuerpo) {
    $medicionesFanIn.Add([pscustomobject]@{
      FanIn = $fanIn[$clave]
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $unidad.Archivo)
      Unidad = $unidad.Nombre
    })
  }
}

Write-Output 'Mayor fan-out por unidad:'
Write-Output (
  $medicionesFanOut |
    Sort-Object FanOut -Descending |
    Select-Object -First 20 |
    Format-Table Unidad, FanOut, Ruta -AutoSize |
    Out-String
).TrimEnd()
Write-Output 'Mayor fan-in entre unidades con cuerpo:'
Write-Output (
  $medicionesFanIn |
    Sort-Object FanIn -Descending |
    Select-Object -First 20 |
    Format-Table Unidad, FanIn, Ruta -AutoSize |
    Out-String
).TrimEnd()

$fanOutMayor = (
  $medicionesFanOut |
    Measure-Object FanOut -Maximum
).Maximum
$fanInMayor = (
  $medicionesFanIn |
    Measure-Object FanIn -Maximum
).Maximum
$claveInLibMsg = 'inlibmsg'
$fanInInLibMsg = if ($fanIn.ContainsKey($claveInLibMsg)) {
  $fanIn[$claveInLibMsg]
} else {
  0
}
$errores = [System.Collections.Generic.List[string]]::new()
if ($fanOutMayor -gt $MaximoFanOut) {
  $errores.Add(
    "Fan-out maximo: $fanOutMayor; maximo permitido: $MaximoFanOut.")
}
if ($fanInMayor -gt $MaximoFanInConCuerpo) {
  $errores.Add(
    "Fan-in maximo con cuerpo: $fanInMayor; maximo permitido: " +
    "$MaximoFanInConCuerpo.")
}
if ($fanInInLibMsg -gt $MaximoFanInInLibMsg) {
  $errores.Add(
    "Fan-in de inLibMsg: $fanInInLibMsg; maximo permitido: " +
    "$MaximoFanInInLibMsg.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  'Acoplamiento: OK. Unidades analizadas: ' +
  "$($unidades.Count). Fan-out maximo: $fanOutMayor. " +
  "Fan-in maximo con cuerpo: $fanInMayor. " +
  "Fan-in de inLibMsg: $fanInInLibMsg.")
