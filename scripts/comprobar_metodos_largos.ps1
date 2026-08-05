param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(1, [int]::MaxValue)]
  [int]$UmbralLineas = 120,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoMetodosLargos = 58,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLineasPorMetodo = 200,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoRiesgoAcumulado = 10820,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoRiesgoPorMetodo = 250,
  [switch]$MostrarTodos
)

# Trinquete gradual del libro de estilo (seccion 14.5): a partir de
# $UmbralLineas un metodo mezcla pasos y debe revisarse. El tope de
# metodos de mas de 200 lineas vive en comprobar_flujos_largos.ps1;
# este script congela el recuento, la longitud y el riesgo. El riesgo
# pondera decisiones, salidas tempranas, excepciones, escrituras y las
# zonas de caja/Verifactu para ordenar las extracciones por impacto.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Medir-BloqueMetodo {
  param([string]$Bloque)
  $inicio = [regex]::Match(
    $Bloque,
    '(?im)^begin\b')
  if (-not $inicio.Success) {
    return $null
  }
  $tokens = [regex]::Matches(
    $Bloque.Substring($inicio.Index),
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
      return [pscustomobject]@{
        Lineas = (
          [regex]::Matches($Bloque.Substring(0, $longitud), "`n")
        ).Count + 1
        Longitud = $longitud
      }
    }
  }
  return [pscustomobject]@{
    Lineas = ([regex]::Matches($Bloque, "`n")).Count + 1
    Longitud = $Bloque.Length
  }
}

function Obtener-MetodosPascal {
  param(
    [string]$Limpio,
    [string]$RutaRelativa
  )
  $patron =
    '(?m)^(?:class\s+)?(?:procedure|function|constructor|destructor)' +
    '\s+(?<nombre>[A-Za-z_][A-Za-z0-9_.]*)\b'
  $coincidencias = [regex]::Matches($Limpio, $patron)
  $metodos = [System.Collections.Generic.List[object]]::new()
  for ($indice = 0; $indice -lt $coincidencias.Count; $indice++) {
    $inicio = $coincidencias[$indice].Index
    if ($indice + 1 -lt $coincidencias.Count) {
      $fin = $coincidencias[$indice + 1].Index
    }
    else {
      $fin = $Limpio.Length
    }
    $bloque = $Limpio.Substring($inicio, $fin - $inicio)
    $medidaBloque = Medir-BloqueMetodo -Bloque $bloque
    if ($null -ne $medidaBloque) {
      $bloqueMetodo = $bloque.Substring(0, $medidaBloque.Longitud)
      $decisiones = [regex]::Matches(
        $bloqueMetodo,
        '(?i)\b(if|case|for|while|repeat)\b').Count
      $salidas = [regex]::Matches(
        $bloqueMetodo,
        '(?i)\b(exit|continue)\b').Count
      $excepciones = [regex]::Matches(
        $bloqueMetodo,
        '(?i)\bexcept\b').Count
      $escrituras = [regex]::Matches(
        $bloqueMetodo,
        '(?i)\b(ExecSQL|StartTransaction|Commit|Rollback)\b').Count
      $esZonaCritica = $RutaRelativa -match
        '(?i)^src\\(verifactu|Caja)\\'
      $riesgo = $medidaBloque.Lineas + ($decisiones * 4) +
        ($salidas * 8) + ($excepciones * 8) + ($escrituras * 6)
      $zona = '-'
      if ($esZonaCritica) {
        $riesgo += 30
        $zona = 'Fiscal/Caja'
      }
      $numeroLinea = (
        [regex]::Matches($Limpio.Substring(0, $inicio), "`n")
      ).Count + 1
      $metodos.Add([pscustomobject]@{
        Nombre = $coincidencias[$indice].Groups['nombre'].Value
        Linea = $numeroLinea
        Lineas = $medidaBloque.Lineas
        Decisiones = $decisiones
        Salidas = $salidas
        Excepciones = $excepciones
        Escrituras = $escrituras
        Riesgo = $riesgo
        Zona = $zona
        Ruta = $RutaRelativa
      })
    }
  }
  return $metodos
}

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$largos = [System.Collections.Generic.List[object]]::new()
$generadosEncontrados = [System.Collections.Generic.List[object]]::new()
$maximoLineas = 0
$nombreMaximo = ''
$maximoRiesgo = 0
$nombreMaximoRiesgo = ''
$totalMetodos = 0
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $rutaRelativa = [System.IO.Path]::GetRelativePath(
    $Raiz,
    $archivo.FullName).Replace('/', '\')
  foreach ($metodo in Obtener-MetodosPascal `
    -Limpio $limpio `
    -RutaRelativa $rutaRelativa) {
    $esGenerado = $false
    foreach ($metodoGenerado in $metodosGenerados) {
      if (($rutaRelativa -eq $metodoGenerado.Ruta) -and
          ($metodo.Nombre -eq $metodoGenerado.Nombre)) {
        $esGenerado = $true
      }
    }
    if ($esGenerado) {
      $generadosEncontrados.Add($metodo)
    }
    else {
      $totalMetodos++
      if ($metodo.Lineas -gt $maximoLineas) {
        $maximoLineas = $metodo.Lineas
        $nombreMaximo = $metodo.Nombre
      }
      if ($metodo.Lineas -gt $UmbralLineas) {
        $largos.Add($metodo)
      }
    }
  }
}

$ordenados = @(
  $largos |
    Sort-Object -Property `
      @{ Expression = 'Riesgo'; Descending = $true }, `
      @{ Expression = 'Lineas'; Descending = $true }
)
$riesgoAcumulado = 0
foreach ($metodo in $largos) {
  $riesgoAcumulado += $metodo.Riesgo
  if ($metodo.Riesgo -gt $maximoRiesgo) {
    $maximoRiesgo = $metodo.Riesgo
    $nombreMaximoRiesgo = $metodo.Nombre
  }
}
$limite = 20
if ($MostrarTodos) {
  $limite = $ordenados.Count
}
Write-Output "Metodos de mas de $UmbralLineas lineas:"
Write-Output (
  $ordenados |
    Select-Object -First $limite |
    Format-Table `
      Nombre, Riesgo, Lineas, Decisiones, Salidas, Escrituras, Zona, `
      Linea, Ruta `
      -AutoSize |
    Out-String -Width 240
).TrimEnd()

$errores = [System.Collections.Generic.List[string]]::new()
if ($generadosEncontrados.Count -ne $metodosGenerados.Count) {
  $errores.Add(
    'No se localizaron todas las rutinas generadas excluidas del ' +
    "limite: $($generadosEncontrados.Count); esperadas: " +
    "$($metodosGenerados.Count).")
}
if ($largos.Count -gt $MaximoMetodosLargos) {
  $errores.Add(
    "Metodos de mas de $UmbralLineas lineas: $($largos.Count); " +
    "maximo permitido: $MaximoMetodosLargos.")
}
if ($maximoLineas -gt $MaximoLineasPorMetodo) {
  $errores.Add(
    "Lineas del metodo mas largo ($nombreMaximo): $maximoLineas; " +
    "maximo permitido: $MaximoLineasPorMetodo.")
}
if ($riesgoAcumulado -gt $MaximoRiesgoAcumulado) {
  $errores.Add(
    "Riesgo acumulado de metodos largos: $riesgoAcumulado; " +
    "maximo permitido: $MaximoRiesgoAcumulado.")
}
if ($maximoRiesgo -gt $MaximoRiesgoPorMetodo) {
  $errores.Add(
    "Riesgo del metodo mas expuesto ($nombreMaximoRiesgo): " +
    "$maximoRiesgo; maximo permitido: $MaximoRiesgoPorMetodo.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  "Metodos largos: OK. Analizados: $totalMetodos. De mas de " +
  "$UmbralLineas lineas: $($largos.Count). Mas largo: " +
  "$maximoLineas lineas ($nombreMaximo). Rutinas generadas fuera " +
  "del limite: $($generadosEncontrados.Count). Riesgo acumulado: " +
  "$riesgoAcumulado. Mayor riesgo: $maximoRiesgo " +
  "($nombreMaximoRiesgo).")
