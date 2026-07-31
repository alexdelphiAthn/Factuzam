param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoSentenciasSql = 158,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoUnidadesConSql = 53,
  [switch]$MostrarTodos,
  [string]$RutaInventario = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Quitar-ComentariosPascal {
  param([string]$Contenido)
  $resultado = [System.Text.StringBuilder]::new()
  $estado = 'normal'
  $indice = 0
  while ($indice -lt $Contenido.Length) {
    $caracter = $Contenido[$indice]
    if ($indice + 1 -lt $Contenido.Length) {
      $siguiente = $Contenido[$indice + 1]
    }
    else {
      $siguiente = [char]0
    }
    if ($estado -eq 'normal') {
      if ($caracter -eq "'") {
        $estado = 'cadena'
        [void]$resultado.Append($caracter)
        $indice++
      }
      elseif (($caracter -eq '/') -and ($siguiente -eq '/')) {
        $estado = 'linea'
        [void]$resultado.Append('  ')
        $indice += 2
      }
      elseif ($caracter -eq '{') {
        $estado = 'llave'
        [void]$resultado.Append(' ')
        $indice++
      }
      elseif (($caracter -eq '(') -and ($siguiente -eq '*')) {
        $estado = 'parentesis'
        [void]$resultado.Append('  ')
        $indice += 2
      }
      else {
        [void]$resultado.Append($caracter)
        $indice++
      }
    }
    elseif ($estado -eq 'cadena') {
      [void]$resultado.Append($caracter)
      $indice++
      if ($caracter -eq "'") {
        if (($indice -lt $Contenido.Length) -and
            ($Contenido[$indice] -eq "'")) {
          [void]$resultado.Append($Contenido[$indice])
          $indice++
        }
        else {
          $estado = 'normal'
        }
      }
    }
    elseif ($estado -eq 'linea') {
      if (($caracter -eq "`r") -or ($caracter -eq "`n")) {
        $estado = 'normal'
        [void]$resultado.Append($caracter)
      }
      else {
        [void]$resultado.Append(' ')
      }
      $indice++
    }
    elseif ($estado -eq 'llave') {
      if ($caracter -eq '}') {
        $estado = 'normal'
      }
      if (($caracter -eq "`r") -or ($caracter -eq "`n")) {
        [void]$resultado.Append($caracter)
      }
      else {
        [void]$resultado.Append(' ')
      }
      $indice++
    }
    else {
      if (($caracter -eq '*') -and ($siguiente -eq ')')) {
        [void]$resultado.Append('  ')
        $estado = 'normal'
        $indice += 2
      }
      else {
        if (($caracter -eq "`r") -or ($caracter -eq "`n")) {
          [void]$resultado.Append($caracter)
        }
        else {
          [void]$resultado.Append(' ')
        }
        $indice++
      }
    }
  }
  return $resultado.ToString()
}

function Obtener-SentenciasPascal {
  param([string]$Contenido)
  $sentencias = [System.Collections.Generic.List[string]]::new()
  $inicio = 0
  $indice = 0
  $enCadena = $false
  while ($indice -lt $Contenido.Length) {
    $caracter = $Contenido[$indice]
    if ($caracter -eq "'") {
      if ($enCadena -and
          ($indice + 1 -lt $Contenido.Length) -and
          ($Contenido[$indice + 1] -eq "'")) {
        $indice += 2
      }
      else {
        $enCadena = -not $enCadena
        $indice++
      }
    }
    elseif (($caracter -eq ';') -and (-not $enCadena)) {
      $sentencias.Add(
        $Contenido.Substring($inicio, $indice - $inicio + 1))
      $inicio = $indice + 1
      $indice++
    }
    else {
      $indice++
    }
  }
  if ($inicio -lt $Contenido.Length) {
    $sentencias.Add($Contenido.Substring($inicio))
  }
  return $sentencias.ToArray()
}

function Obtener-TipoSqlLiteral {
  param([string]$Sentencia)
  $literales = foreach ($literal in [regex]::Matches(
    $Sentencia,
    "'(?:''|[^'])*'")) {
    $literal.Value.Substring(
      1,
      $literal.Value.Length - 2
    ).Replace("''", "'")
  }
  $sql = ($literales -join ' ').Trim()
  $patron =
    '(?is)\b(SELECT|INSERT|UPDATE|DELETE|REPLACE|CALL|' +
    'CREATE|ALTER|DROP|TRUNCATE|MERGE)\b'
  $coincidencia = [regex]::Match($sql, $patron)
  $tipo = ''
  if ($coincidencia.Success -and
      ($sql -notmatch
       '^(?i:SELECT|INSERT|UPDATE|DELETE|REPLACE|CALL|' +
       'CREATE|ALTER|DROP|TRUNCATE|MERGE)$')) {
    $tipo = $coincidencia.Groups[1].Value.ToUpperInvariant()
    $esSentenciaSql = switch ($tipo) {
      'SELECT' {
        $sql -match '(?is)\bSELECT\b\s+([A-Z_`*:@0-9]|\()'
      }
      'INSERT' {
        $sql -match '(?is)\bINSERT\b.*\bINTO\b'
      }
      'UPDATE' {
        $sql -match '(?is)\bUPDATE\b.*\bSET\b'
      }
      'DELETE' {
        $sql -match '(?is)\bDELETE\b.*\bFROM\b'
      }
      'REPLACE' {
        $sql -match '(?is)\bREPLACE\b.*\bINTO\b'
      }
      'CALL' {
        $sql -match '(?is)\bCALL\b\s+[A-Z_`]'
      }
      default {
        $sql -match
          '(?is)\b(CREATE|ALTER|DROP|TRUNCATE|MERGE)\b.*' +
          '\b(TABLE|DATABASE|INDEX|VIEW|PROCEDURE|FUNCTION|' +
          'TRIGGER|EVENT|COLUMN)\b'
      }
    }
    if (-not $esSentenciaSql) {
      $tipo = ''
    }
    if ($tipo -in @('CREATE', 'ALTER', 'DROP', 'TRUNCATE', 'MERGE')) {
      $tipo = 'DDL'
    }
  }
  return $tipo
}

function Medir-SqlLiteral {
  param([string]$Contenido)
  $totales = [ordered]@{
    SELECT = 0
    INSERT = 0
    UPDATE = 0
    DELETE = 0
    REPLACE = 0
    CALL = 0
    DDL = 0
  }
  $sinComentarios = Quitar-ComentariosPascal -Contenido $Contenido
  foreach ($sentencia in Obtener-SentenciasPascal `
    -Contenido $sinComentarios) {
    $tipo = Obtener-TipoSqlLiteral -Sentencia $sentencia
    if ($tipo -ne '') {
      $totales[$tipo]++
    }
  }
  return [pscustomobject]@{
    Sentencias = [int](
      $totales.Values |
        Measure-Object -Sum
    ).Sum
    Select = $totales.SELECT
    Insert = $totales.INSERT
    Update = $totales.UPDATE
    Delete = $totales.DELETE
    Replace = $totales.REPLACE
    Call = $totales.CALL
    Ddl = $totales.DDL
  }
}

$directorios = @(
  (Join-Path $Raiz 'src\Lib'),
  (Join-Path $Raiz 'src\Caja\Lib')
)
$rutasAdicionalesVigiladas = @(
  (Join-Path $Raiz 'src\verifactu\inLibVerifactuCola.pas')
)
foreach ($directorio in $directorios) {
  if (-not (Test-Path -LiteralPath $directorio -PathType Container)) {
    throw "No se encontro el directorio de dominio: $directorio."
  }
}
foreach ($rutaAdicional in $rutasAdicionalesVigiladas) {
  if (-not (Test-Path -LiteralPath $rutaAdicional -PathType Leaf)) {
    throw "No se encontro la unidad de dominio vigilada: $rutaAdicional."
  }
}
$archivos = @(
  Get-ChildItem -LiteralPath $directorios `
    -Recurse -Filter '*.pas' -File |
    Where-Object {
      $_.FullName -notlike '*\Lib\backup\*' -and
      $_.FullName -notlike '*\Lib\sqlformatter\*'
    }
  Get-Item -LiteralPath $rutasAdicionalesVigiladas
)
$mediciones = [System.Collections.Generic.List[object]]::new()
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $medicion = Medir-SqlLiteral -Contenido $contenido
  if ($medicion.Sentencias -gt 0) {
    $mediciones.Add([pscustomobject]@{
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
      Sentencias = $medicion.Sentencias
      Select = $medicion.Select
      Insert = $medicion.Insert
      Update = $medicion.Update
      Delete = $medicion.Delete
      Replace = $medicion.Replace
      Call = $medicion.Call
      Ddl = $medicion.Ddl
      Unidad = $archivo.BaseName
    })
  }
}
$totalSentencias = (
  $mediciones |
    Measure-Object Sentencias -Sum
).Sum
if ($null -eq $totalSentencias) {
  $totalSentencias = 0
}
$unidadesConSql = $mediciones.Count
$ordenadas = @(
  $mediciones |
    Sort-Object Sentencias -Descending
)
$limite = 20
if ($MostrarTodos) {
  $limite = $ordenadas.Count
}

Write-Output 'SQL literal por unidad de dominio:'
Write-Output (
  $ordenadas |
    Select-Object -First $limite |
    Format-Table `
      Unidad, Sentencias, Select, Insert, Update, Delete, Replace, Call, Ddl,
        Ruta `
      -AutoSize |
    Out-String
).TrimEnd()
Write-Output ''
Write-Output 'Totales por tipo:'
Write-Output (
  [pscustomobject]@{
    Select = [int]($mediciones | Measure-Object Select -Sum).Sum
    Insert = [int]($mediciones | Measure-Object Insert -Sum).Sum
    Update = [int]($mediciones | Measure-Object Update -Sum).Sum
    Delete = [int]($mediciones | Measure-Object Delete -Sum).Sum
    Replace = [int]($mediciones | Measure-Object Replace -Sum).Sum
    Call = [int]($mediciones | Measure-Object Call -Sum).Sum
    Ddl = [int]($mediciones | Measure-Object Ddl -Sum).Sum
  } |
    Format-Table -AutoSize |
    Out-String
).TrimEnd()

if ($RutaInventario -ne '') {
  $rutaSalida = $RutaInventario
  if (-not [System.IO.Path]::IsPathRooted($rutaSalida)) {
    $rutaSalida = Join-Path $Raiz $rutaSalida
  }
  $directorioSalida = Split-Path -Parent $rutaSalida
  if (($directorioSalida -ne '') -and
      (-not (Test-Path -LiteralPath $directorioSalida))) {
    [void](New-Item -ItemType Directory -Path $directorioSalida)
  }
  $ordenadas |
    Export-Csv `
      -LiteralPath $rutaSalida `
      -Delimiter ';' `
      -NoTypeInformation `
      -Encoding UTF8
  Write-Output "Inventario completo guardado en: $rutaSalida"
}

$errores = [System.Collections.Generic.List[string]]::new()
if ($totalSentencias -gt $MaximoSentenciasSql) {
  $errores.Add(
    "Sentencias SQL literales: $totalSentencias; maximo permitido: " +
    "$MaximoSentenciasSql.")
}
if ($unidadesConSql -gt $MaximoUnidadesConSql) {
  $errores.Add(
    "Unidades con SQL literal: $unidadesConSql; maximo permitido: " +
    "$MaximoUnidadesConSql.")
}
if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}
Write-Output (
  'SQL en dominio: OK. Sentencias literales: ' +
  "$totalSentencias. Unidades con SQL: $unidadesConSql.")
