param(
  [Parameter(Mandatory = $true)]
  [string]$Ruta,
  [string[]]$Patrones = @('*.dfm'),
  [string]$Idioma = 'es-ES',
  [string]$Usuario = 'Sistema'
)

function Convertir-CadenaDfm {
  param([string]$Expresion)
  $resultado = [System.Text.StringBuilder]::new()
  $i = 0
  while ($i -lt $Expresion.Length) {
    if ($Expresion[$i] -eq "'") {
      $i++
      while ($i -lt $Expresion.Length) {
        if ($Expresion[$i] -eq "'") {
          if (($i + 1 -lt $Expresion.Length) -and
              ($Expresion[$i + 1] -eq "'")) {
            [void]$resultado.Append("'")
            $i += 2
          }
          else {
            $i++
            break
          }
        }
        else {
          [void]$resultado.Append($Expresion[$i])
          $i++
        }
      }
    }
    elseif ($Expresion[$i] -eq '#') {
      $i++
      $inicio = $i
      while (($i -lt $Expresion.Length) -and
             [char]::IsDigit($Expresion[$i])) {
        $i++
      }
      if ($i -gt $inicio) {
        $codigo = [int]$Expresion.Substring(
          $inicio,
          $i - $inicio)
        [void]$resultado.Append(
          [char]::ConvertFromUtf32($codigo))
      }
    }
    else {
      $i++
    }
  }
  return $resultado.ToString()
}

function Escapar-Sql {
  param([string]$Valor)
  return $Valor.Replace("'", "''")
}

function Formatear-ClaveSql {
  param([string]$Clave)
  $maximo = 74
  if ($Clave.Length -le $maximo) {
    "  ('$(Escapar-Sql $Clave)',"
  }
  else {
    $fragmentos = [System.Collections.Generic.List[string]]::new()
    $inicio = 0
    while ($inicio -lt $Clave.Length) {
      $longitud = [Math]::Min(
        70,
        $Clave.Length - $inicio)
      $fragmentos.Add($Clave.Substring($inicio, $longitud))
      $inicio += $longitud
    }
    '  (CONCAT('
    for ($i = 0; $i -lt $fragmentos.Count; $i++) {
      $terminador = ','
      if ($i -eq $fragmentos.Count - 1) {
        $terminador = ''
      }
      "     '$(Escapar-Sql $fragmentos[$i])'$terminador"
    }
    '   ),'
  }
}

function Formatear-TextoControlSql {
  param([string]$Texto)
  $tokens = [System.Collections.Generic.List[string]]::new()
  $inicio = 0
  for ($i = 0; $i -lt $Texto.Length; $i++) {
    $codigo = [int]$Texto[$i]
    if ($codigo -in @(9, 10, 13)) {
      if ($i -gt $inicio) {
        $fragmento = $Texto.Substring($inicio, $i - $inicio)
        while ($fragmento.Length -gt 0) {
          $longitud = [Math]::Min(65, $fragmento.Length)
          $tokens.Add(
            "'" + (Escapar-Sql $fragmento.Substring(0, $longitud)) + "'")
          $fragmento = $fragmento.Substring($longitud)
        }
      }
      $tokens.Add('CHAR(' + $codigo + ')')
      $inicio = $i + 1
    }
  }
  if ($inicio -lt $Texto.Length) {
    $fragmento = $Texto.Substring($inicio)
    while ($fragmento.Length -gt 0) {
      $longitud = [Math]::Min(65, $fragmento.Length)
      $tokens.Add(
        "'" + (Escapar-Sql $fragmento.Substring(0, $longitud)) + "'")
      $fragmento = $fragmento.Substring($longitud)
    }
  }
  '   CONCAT('
  for ($i = 0; $i -lt $tokens.Count; $i++) {
    $terminador = ','
    if ($i -eq $tokens.Count - 1) {
      $terminador = ''
    }
    "     $($tokens[$i])$terminador"
  }
  '   ),'
}

function Formatear-TextoSql {
  param([string]$Texto)
  $maximo = 70
  $tieneControl = $Texto.IndexOfAny(
    [char[]]@([char]9, [char]10, [char]13)) -ge 0
  if ($tieneControl) {
    Formatear-TextoControlSql $Texto
  }
  elseif ($Texto.Length -le $maximo) {
    "   '$(Escapar-Sql $Texto)',"
  }
  else {
    $fragmentos = [System.Collections.Generic.List[string]]::new()
    $inicio = 0
    while ($inicio -lt $Texto.Length) {
      $longitud = [Math]::Min(
        $maximo,
        $Texto.Length - $inicio)
      if (($inicio + $longitud) -lt $Texto.Length) {
        $ultimoEspacio = $Texto.LastIndexOf(
          ' ',
          $inicio + $longitud - 1,
          $longitud)
        if ($ultimoEspacio -ge $inicio) {
          $longitud = $ultimoEspacio - $inicio + 1
        }
      }
      $fragmentos.Add($Texto.Substring($inicio, $longitud))
      $inicio += $longitud
    }
    '   CONCAT('
    for ($i = 0; $i -lt $fragmentos.Count; $i++) {
      $terminador = ','
      if ($i -eq $fragmentos.Count - 1) {
        $terminador = ''
      }
      "     '$(Escapar-Sql $fragmentos[$i])'$terminador"
    }
    '   ),'
  }
}

$entradas = [System.Collections.Generic.List[object]]::new()
$claves = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
$raizResuelta = (Resolve-Path -LiteralPath $Ruta).Path
$directorioTrabajo = (Get-Location).Path
$ficheros = @(
  Get-ChildItem -LiteralPath $raizResuelta -Filter '*.dfm' |
    Where-Object {
      $nombre = $_.Name
      @($Patrones | Where-Object { $nombre -like $_ }).Count -gt 0
    }
)
if ($ficheros.Count -eq 0) {
  throw 'No se encontraron ficheros DFM para los patrones indicados.'
}

foreach ($fichero in $ficheros | Sort-Object Name) {
  $lineas = Get-Content -LiteralPath $fichero.FullName
  $pila = [System.Collections.Generic.List[object]]::new()
  $claseRaiz = ''
  $i = 0
  while ($i -lt $lineas.Count) {
    $linea = $lineas[$i].Trim()
    if ($linea -match
        '^(object|inherited|inline)\s+([^:]+):\s*([^\s\[]+)') {
      $marco = [pscustomobject]@{
        Tipo = 'componente'
        Nombre = $matches[2].Trim()
        Clase = $matches[3].Trim()
      }
      $pila.Add($marco)
      if ($claseRaiz -eq '') {
        $claseRaiz = $marco.Clase
      }
    }
    elseif ($linea -match
            '^([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*=\s*<$') {
      $rutaColeccion = $matches[1]
      for ($j = $pila.Count - 1; $j -ge 0; $j--) {
        if ($pila[$j].Tipo -eq 'item') {
          $rutaColeccion = $pila[$j].Ruta + '.' + $rutaColeccion
          break
        }
      }
      $pila.Add(
        [pscustomobject]@{
          Tipo = 'coleccion'
          Nombre = $matches[1]
          Clase = ''
          Ruta = $rutaColeccion
          Siguiente = 0
        })
    }
    elseif ($linea -match '^item(\s|$)') {
      $coleccion = $null
      for ($j = $pila.Count - 1; $j -ge 0; $j--) {
        if ($pila[$j].Tipo -eq 'coleccion') {
          $coleccion = $pila[$j]
          break
        }
      }
      if ($null -eq $coleccion) {
        throw "Item sin colección en $($fichero.FullName):$($i + 1)"
      }
      $rutaItem = $coleccion.Ruta +
        '[' + $coleccion.Siguiente + ']'
      $coleccion.Siguiente++
      $pila.Add(
        [pscustomobject]@{
          Tipo = 'item'
          Nombre = ''
          Clase = ''
          Ruta = $rutaItem
        })
    }
    elseif ($linea -match '^end>\s*$') {
      if (($pila.Count -gt 0) -and
          ($pila[$pila.Count - 1].Tipo -eq 'item')) {
        $pila.RemoveAt($pila.Count - 1)
      }
      if (($pila.Count -gt 0) -and
          ($pila[$pila.Count - 1].Tipo -eq 'coleccion')) {
        $pila.RemoveAt($pila.Count - 1)
      }
    }
    elseif ($linea -match '^end\)?\s*$') {
      if ($pila.Count -gt 0) {
        $pila.RemoveAt($pila.Count - 1)
      }
    }
    elseif ($linea -match
            '^(Caption|Hint|Title|DisplayName)\s*=\s*(.*)$') {
      $propiedad = $matches[1]
      $expresion = $matches[2]
      while (($i + 1 -lt $lineas.Count) -and
             ($lineas[$i + 1].Trim() -match "^('|#)")) {
        $i++
        $expresion += $lineas[$i].Trim()
      }
      $item = $null
      $componente = $null
      for ($j = $pila.Count - 1; $j -ge 0; $j--) {
        if (($pila[$j].Tipo -eq 'item') -and
            ($null -eq $item)) {
          $item = $pila[$j]
        }
        elseif ($null -eq $componente) {
          if ($pila[$j].Tipo -eq 'componente') {
            $componente = $pila[$j]
          }
        }
      }
      $texto = Convertir-CadenaDfm $expresion
      if (($null -ne $componente) -and
          ($texto -ne '') -and
          ($texto -ne '-')) {
        $clave = $fichero.BaseName + '.' + $claseRaiz
        if ($componente.Clase -ne $claseRaiz) {
          $clave += '.' + $componente.Nombre
        }
        if ($null -ne $item) {
          $clave += '.' + $item.Ruta
        }
        $clave += '.' + $propiedad
        if (-not $claves.Add($clave)) {
          throw "Clave duplicada: $clave"
        }
        $contexto = [IO.Path]::GetRelativePath(
          $directorioTrabajo,
          $fichero.FullName).Replace('\', '/')
        $entradas.Add(
          [pscustomobject]@{
            Clave = $clave
            Texto = $texto
            Contexto = $contexto
          })
      }
    }
    $i++
  }
}

'-- Catálogo de textos españoles extraídos de los DFM.'
'-- Generado por generar_traducciones_dfm.ps1.'
'INSERT INTO `fza_traducciones` ('
'  `CLAVE_TRAD`, `IDIOMA_TRAD`, `TEXTO_TRAD`, `CONTEXTO_TRAD`,'
'  `ESACTIVO_TRAD`, `INSTANTE_ALTA`, `USUARIO_ALTA`'
') VALUES'
for ($i = 0; $i -lt $entradas.Count; $i++) {
  $entrada = $entradas[$i]
  $terminador = ','
  if ($i -eq $entradas.Count - 1) {
    $terminador = ''
  }
  Formatear-ClaveSql $entrada.Clave
  "   '$(Escapar-Sql $Idioma)',"
  Formatear-TextoSql $entrada.Texto
  "   '$(Escapar-Sql $entrada.Contexto)',"
  "   'S', CURRENT_TIMESTAMP, '$(Escapar-Sql $Usuario)')$terminador"
}
'ON DUPLICATE KEY UPDATE'
'  `TEXTO_TRAD` = VALUES(`TEXTO_TRAD`),'
'  `CONTEXTO_TRAD` = VALUES(`CONTEXTO_TRAD`),'
'  `ESACTIVO_TRAD` = VALUES(`ESACTIVO_TRAD`),'
'  `INSTANTE_MODIF` = CURRENT_TIMESTAMP,'
'  `USUARIO_MODIF` = VALUES(`USUARIO_ALTA`);'
