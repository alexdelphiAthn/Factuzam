param(
  [string]$Raiz = (Join-Path $PSScriptRoot '..')
)
function Obtener-LlamadasRegistrarParametro {
  param([string]$Texto)
  $resultado = [System.Collections.Generic.List[string]]::new()
  $coincidencias = [regex]::Matches(
    $Texto,
    'RegistrarParametro\s*\(')
  foreach ($coincidencia in $coincidencias) {
    $inicio = $coincidencia.Index + $coincidencia.Length
    $indice = $inicio
    $nivel = 1
    $enCadena = $false
    while (($indice -lt $Texto.Length) -and ($nivel -gt 0)) {
      $caracter = $Texto[$indice]
      if ($enCadena) {
        if (($caracter -eq "'") -and
            ($indice + 1 -lt $Texto.Length) -and
            ($Texto[$indice + 1] -eq "'")) {
          $indice++
        } elseif ($caracter -eq "'") {
          $enCadena = $false
        }
      } elseif ($caracter -eq "'") {
        $enCadena = $true
      } elseif ($caracter -eq '(') {
        $nivel++
      } elseif ($caracter -eq ')') {
        $nivel--
      }
      $indice++
    }
    if ($nivel -ne 0) {
      throw 'Llamada RegistrarParametro sin cierre.'
    }
    $resultado.Add(
      $Texto.Substring(
        $inicio,
        $indice - $inicio - 1))
  }
  return $resultado
}
function Separar-ArgumentosPascal {
  param([string]$Texto)
  $resultado = [System.Collections.Generic.List[string]]::new()
  $inicio = 0
  $indice = 0
  $nivel = 0
  $enCadena = $false
  while ($indice -le $Texto.Length) {
    if ($indice -eq $Texto.Length) {
      $resultado.Add(
        $Texto.Substring($inicio).Trim())
      break
    }
    $caracter = $Texto[$indice]
    if ($enCadena) {
      if (($caracter -eq "'") -and
          ($indice + 1 -lt $Texto.Length) -and
          ($Texto[$indice + 1] -eq "'")) {
        $indice++
      } elseif ($caracter -eq "'") {
        $enCadena = $false
      }
    } elseif ($caracter -eq "'") {
      $enCadena = $true
    } elseif ($caracter -eq '(') {
      $nivel++
    } elseif ($caracter -eq ')') {
      $nivel--
    } elseif (($caracter -eq ',') -and ($nivel -eq 0)) {
      $resultado.Add(
        $Texto.Substring(
          $inicio,
          $indice - $inicio).Trim())
      $inicio = $indice + 1
    }
    $indice++
  }
  return $resultado
}
function Obtener-LiteralPascal {
  param([string]$Expresion)
  $partes = [regex]::Matches(
    $Expresion,
    "'((?:''|[^'])*)'")
  $resultado = ''
  foreach ($parte in $partes) {
    $resultado +=
      $parte.Groups[1].Value.Replace("''", "'")
  }
  return $resultado
}
function Normalizar-SegmentoClave {
  param([string]$Texto)
  $descompuesto = $Texto.Normalize(
    [System.Text.NormalizationForm]::FormD)
  $resultado = ''
  foreach ($caracter in $descompuesto.ToCharArray()) {
    $categoria =
      [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory(
        $caracter)
    if ($categoria -ne
        [System.Globalization.UnicodeCategory]::NonSpacingMark) {
      $valor = [string]$caracter
      if ($valor -cmatch '^[A-Za-z0-9]$') {
        $resultado += $valor
      }
    }
  }
  return $resultado
}
function Agregar-ExpresionCadenaPascal {
  param(
    [System.Collections.Generic.List[string]]$Lineas,
    [string]$Valor,
    [string]$Sufijo
  )
  $resto = $Valor
  while ($resto.Length -gt 56) {
    $trozo = $resto.Substring(0, 56).Replace("'", "''")
    $Lineas.Add("    '$trozo' +")
    $resto = $resto.Substring(56)
  }
  $resto = $resto.Replace("'", "''")
  $Lineas.Add("    '$resto'$Sufijo")
}
$raizResuelta = (Resolve-Path -LiteralPath $Raiz).Path
$rutaSalida = Join-Path `
  $raizResuelta `
  'src\Lib\inLibRegistroParametrosTraducciones.pas'
$fuentes = @(
  [pscustomobject]@{
    Ruta = Join-Path $raizResuelta 'src\Lib\inLibAppParam.pas'
    UnidadClave = 'inMtoAppParam'
    Contexto = 'src/Lib/inLibAppParam.pas'
  },
  [pscustomobject]@{
    Ruta = Join-Path $raizResuelta 'src\Caja\Lib\inLibCajaParam.pas'
    UnidadClave = 'inMtoCajaParam'
    Contexto = 'src/Caja/Lib/inLibCajaParam.pas'
  }
)
$entradas = [System.Collections.Generic.List[object]]::new()
$categorias = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
foreach ($fuente in $fuentes) {
  $texto = [System.IO.File]::ReadAllText($fuente.Ruta)
  $llamadas = Obtener-LlamadasRegistrarParametro $texto
  foreach ($llamada in $llamadas) {
    $argumentos = Separar-ArgumentosPascal $llamada
    if ($argumentos.Count -lt 3) {
      throw "Llamada incompleta en $($fuente.Ruta)."
    }
    $categoria = Obtener-LiteralPascal $argumentos[0]
    $nombre = Obtener-LiteralPascal $argumentos[1]
    if (($categoria -ne '') -and ($nombre -ne '')) {
      $segmentoCategoria =
        Normalizar-SegmentoClave $categoria
      $claveCategoria =
        $fuente.UnidadClave +
        '.Parametros.Categoria.' +
        $segmentoCategoria
      if ($categorias.Add($claveCategoria)) {
        $entradas.Add(
          [pscustomobject]@{
            Clave = $claveCategoria
            Texto = $categoria
            Expresion = ''
            Contexto = $fuente.Contexto
          })
      }
      $expresion = ''
      $descripcion = ''
      if ($argumentos[2] -match
          '\bSDescripcionParametroIdioma\b') {
        $expresion = 'SDescripcionParametroIdioma'
      } else {
        $descripcion =
          Obtener-LiteralPascal $argumentos[2]
      }
      $entradas.Add(
        [pscustomobject]@{
          Clave =
            $fuente.UnidadClave +
            '.Parametros.' +
            $nombre +
            '.Descripcion'
          Texto = $descripcion
          Expresion = $expresion
          Contexto = $fuente.Contexto
        })
    }
  }
}
$lineas = [System.Collections.Generic.List[string]]::new()
$lineas.Add('unit inLibRegistroParametrosTraducciones;')
$lineas.Add('')
$lineas.Add('interface')
$lineas.Add('')
$lineas.Add('type')
$lineas.Add('  TRegistrarParametroTraduccion = reference to procedure(')
$lineas.Add('    const AClave, ATexto, AContexto: string);')
$lineas.Add('')
$lineas.Add('procedure EnumerarParametrosTraduccion(')
$lineas.Add('  const ARegistrar: TRegistrarParametroTraduccion);')
$lineas.Add('')
$lineas.Add('implementation')
$lineas.Add('')
$lineas.Add('uses')
$lineas.Add('  inLibMsgConfiguracion;')
$lineas.Add('')
$lineas.Add('procedure EnumerarParametrosTraduccion(')
$lineas.Add('  const ARegistrar: TRegistrarParametroTraduccion);')
$lineas.Add('begin')
foreach ($entrada in $entradas) {
  $lineas.Add('  ARegistrar(')
  Agregar-ExpresionCadenaPascal `
    $lineas `
    $entrada.Clave `
    ','
  if ($entrada.Expresion -ne '') {
    $lineas.Add("    $($entrada.Expresion),")
  } else {
    Agregar-ExpresionCadenaPascal `
      $lineas `
      $entrada.Texto `
      ','
  }
  Agregar-ExpresionCadenaPascal `
    $lineas `
    $entrada.Contexto `
    ');'
}
$lineas.Add('end;')
$lineas.Add('')
$lineas.Add('end.')
$largas = for ($i = 0; $i -lt $lineas.Count; $i++) {
  if ($lineas[$i].Length -gt 80) {
    "$($i + 1):$($lineas[$i].Length)"
  }
}
if ($largas) {
  throw 'El registro generado supera 80 columnas: ' +
    ($largas -join ', ')
}
$contenido = ($lineas -join "`r`n") + "`r`n"
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText(
  $rutaSalida,
  $contenido,
  $utf8Bom)
Write-Output "TEXTOS=$($entradas.Count)"
Write-Output "SALIDA=$rutaSalida"
