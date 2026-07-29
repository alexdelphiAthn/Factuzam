param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoSentenciasSql = 524,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoUnidadesConSql = 79
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

function Contar-SentenciasSqlLiterales {
  param([string]$Contenido)
  $sinComentarios = Quitar-ComentariosPascal -Contenido $Contenido
  $total = 0
  foreach ($sentencia in Obtener-SentenciasPascal `
    -Contenido $sinComentarios) {
    $literales = foreach ($literal in [regex]::Matches(
      $sentencia,
      "'(?:''|[^'])*'")) {
      $literal.Value.Substring(
        1,
        $literal.Value.Length - 2
      ).Replace("''", "'")
    }
    $sql = $literales -join ' '
    if ($sql -match
      '(?is)\b(SELECT|INSERT|UPDATE|DELETE|REPLACE|CALL|' +
      'CREATE|ALTER|DROP|TRUNCATE|MERGE)\b') {
      $total++
    }
  }
  return $total
}

$directorios = @(
  (Join-Path $Raiz 'src\Lib'),
  (Join-Path $Raiz 'src\Caja\Lib')
)
foreach ($directorio in $directorios) {
  if (-not (Test-Path -LiteralPath $directorio -PathType Container)) {
    throw "No se encontro el directorio de dominio: $directorio."
  }
}
$archivos = @(
  Get-ChildItem -LiteralPath $directorios `
    -Recurse -Filter '*.pas' -File |
    Where-Object {
      $_.FullName -notlike '*\Lib\backup\*' -and
      $_.FullName -notlike '*\Lib\sqlformatter\*'
    }
)
$mediciones = [System.Collections.Generic.List[object]]::new()
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $sentencias = Contar-SentenciasSqlLiterales -Contenido $contenido
  if ($sentencias -gt 0) {
    $mediciones.Add([pscustomobject]@{
      Ruta = [System.IO.Path]::GetRelativePath(
        $Raiz,
        $archivo.FullName)
      Sentencias = $sentencias
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

Write-Output 'SQL literal por unidad de dominio:'
Write-Output (
  $mediciones |
    Sort-Object Sentencias -Descending |
    Select-Object -First 20 |
    Format-Table Unidad, Sentencias, Ruta -AutoSize |
    Out-String
).TrimEnd()

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
