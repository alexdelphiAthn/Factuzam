param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [int]$MaximoFlujo = 100,
  [int]$MaximoMetodosMayoresDe200 = 49
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
