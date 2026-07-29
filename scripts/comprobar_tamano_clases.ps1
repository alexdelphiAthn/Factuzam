param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasPorClase = 4075,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoMetodosPorClase = 133,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoCamposPorClase = 49
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
  "$maximoMetodos metodos y $maximoCampos campos F*.")
