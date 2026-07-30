param(
  [string]$Ruta = 'src',
  [string]$Salida =
    'DESARROLLOS EN CURSO/traducciones_d22_fastreport.sql',
  [string]$Idioma = 'es-ES',
  [string]$Usuario = 'Sistema'
)

$ErrorActionPreference = 'Stop'

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

function Convertir-HexUtf8 {
  param([string]$Valor)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Valor)
  return [Convert]::ToHexString($bytes)
}

function Tiene-TextoVisible {
  param([string]$Texto)
  $sinExpresiones = [regex]::Replace(
    $Texto,
    '\[[^\]]*\]',
    '')
  return $sinExpresiones -match
    '[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'
}

function Obtener-InformeSeleccionado {
  param([string[]]$Lineas)
  $indiceActivo = -1
  $indiceOrigen = -1
  for ($i = 0; $i -lt $Lineas.Count; $i++) {
    if ($Lineas[$i] -match
        '^\s*(?:object|inherited)\s+frxrprt1:\s*TfrxReport') {
      $indiceActivo = $i
    }
    elseif ($Lineas[$i] -match
            '^\s*(?:object|inherited)\s+frxReportOrigen:\s*TfrxReport') {
      $indiceOrigen = $i
    }
  }
  if ($indiceOrigen -lt 0) {
    return 'frxrprt1'
  }
  $finActivo = $Lineas.Count - 1
  if ($indiceOrigen -gt $indiceActivo) {
    $finActivo = $indiceOrigen - 1
  }
  $memosActivo = @(
    $Lineas[$indiceActivo..$finActivo] |
      Where-Object { $_ -match '^\s*Memo\.UTF8W\s*=' }
  ).Count
  $memosOrigen = @(
    $Lineas[$indiceOrigen..($Lineas.Count - 1)] |
      Where-Object { $_ -match '^\s*Memo\.UTF8W\s*=' }
  ).Count
  if ($memosOrigen -ge $memosActivo) {
    return 'frxReportOrigen'
  }
  return 'frxrprt1'
}

$raizResuelta = (Resolve-Path -LiteralPath $Ruta).Path
$salidaResuelta = [IO.Path]::GetFullPath(
  (Join-Path (Get-Location).Path $Salida))
$directorioTrabajo = (Get-Location).Path
$entradas = [System.Collections.Generic.List[object]]::new()
$claves = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
$patronInforme =
  '^\s*(?:object|inherited)\s+\w+:\s*TfrxReport\s*$'
$ficheros = @(
  Get-ChildItem -LiteralPath $raizResuelta -Recurse -Filter '*.dfm' |
    Where-Object {
      Select-String -LiteralPath $_.FullName -Quiet `
        -Pattern $patronInforme
    }
)

foreach ($fichero in $ficheros | Sort-Object FullName) {
  $lineas = Get-Content -LiteralPath $fichero.FullName
  $informeSeleccionado = Obtener-InformeSeleccionado $lineas
  $pila = [System.Collections.Generic.List[object]]::new()
  $nivelItem = 0
  $i = 0
  while ($i -lt $lineas.Count) {
    $linea = $lineas[$i].Trim()
    if ($linea -match
        '^(?:object|inherited|inline)\s+([^:]+):\s*([^\s\[]+)') {
      $pila.Add(
        [pscustomobject]@{
          Nombre = $matches[1].Trim()
          Clase = $matches[2].Trim()
        })
    }
    elseif ($linea -match '^item(?:\s|$)') {
      $nivelItem++
    }
    elseif ($linea -match '^end>\s*$') {
      if ($nivelItem -gt 0) {
        $nivelItem--
      }
    }
    elseif ($linea -match '^end\s*$') {
      if ($nivelItem -gt 0) {
        $nivelItem--
      }
      elseif ($pila.Count -gt 0) {
        $pila.RemoveAt($pila.Count - 1)
      }
    }
    elseif ($linea -match '^Memo\.UTF8W\s*=\s*\(\s*$') {
      $informe = $null
      foreach ($componente in $pila) {
        if ($componente.Clase -eq 'TfrxReport') {
          $informe = $componente
        }
      }
      if (($null -ne $informe) -and
          ($informe.Nombre -eq $informeSeleccionado) -and
          ($pila.Count -gt 0)) {
        $lineasMemo = [System.Collections.Generic.List[string]]::new()
        $terminado = $false
        while (($i + 1 -lt $lineas.Count) -and
               (-not $terminado)) {
          $i++
          $expresion = $lineas[$i].Trim()
          if ($expresion.EndsWith(')')) {
            $expresion = $expresion.Substring(
              0,
              $expresion.Length - 1)
            $terminado = $true
          }
          $lineasMemo.Add(
            (Convertir-CadenaDfm $expresion))
        }
        $texto = $lineasMemo -join "`r`n"
        $objeto = $pila[$pila.Count - 1]
        if ((Tiene-TextoVisible $texto) -and
            ($texto -ne '-')) {
          $clave = 'FastReport.' + $fichero.BaseName +
            '.Predeterminado.' + $objeto.Nombre + '.Memo'
          if (-not $claves.Add($clave)) {
            throw "Clave FastReport duplicada: $clave"
          }
          $contexto = [IO.Path]::GetRelativePath(
            $directorioTrabajo,
            $fichero.FullName).Replace('\', '/') +
            '#' + $informeSeleccionado
          $entradas.Add(
            [pscustomobject]@{
              Clave = $clave
              Texto = $texto
              Contexto = $contexto
            })
        }
      }
    }
    $i++
  }
}

if ($entradas.Count -eq 0) {
  throw 'No se encontraron literales FastReport en los DFM.'
}

$sql = [System.Collections.Generic.List[string]]::new()
$sql.Add('-- D22-A: literales de plantillas FastReport predeterminadas.')
$sql.Add('-- Generado por generar_traducciones_fastreport.ps1.')
$sql.Add('SET NAMES utf8mb4;')
$sql.Add('INSERT INTO fza_traducciones (')
$sql.Add('  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,')
$sql.Add('  ESACTIVO_TRAD, INSTANTE_ALTA, USUARIO_ALTA')
$sql.Add(') VALUES')
for ($i = 0; $i -lt $entradas.Count; $i++) {
  $entrada = $entradas[$i]
  $terminador = ','
  if ($i -eq $entradas.Count - 1) {
    $terminador = ''
  }
  $claveHex = Convertir-HexUtf8 $entrada.Clave
  $textoHex = Convertir-HexUtf8 $entrada.Texto
  $contextoHex = Convertir-HexUtf8 $entrada.Contexto
  $sql.Add(
    '  (CONVERT(0x' + $claveHex + ' USING utf8mb4),')
  $sql.Add(
    "   '$Idioma', CONVERT(0x$textoHex USING utf8mb4),")
  $sql.Add(
    '   CONVERT(0x' + $contextoHex + ' USING utf8mb4),')
  $sql.Add(
    "   'S', CURRENT_TIMESTAMP, '$Usuario')$terminador")
}
$sql.Add('ON DUPLICATE KEY UPDATE')
$sql.Add('  TEXTO_TRAD = VALUES(TEXTO_TRAD),')
$sql.Add('  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),')
$sql.Add('  ESACTIVO_TRAD = VALUES(ESACTIVO_TRAD),')
$sql.Add('  INSTANTE_MODIF = CURRENT_TIMESTAMP,')
$sql.Add('  USUARIO_MODIF = VALUES(USUARIO_ALTA);')
$codificacion = [System.Text.UTF8Encoding]::new($true)
[IO.File]::WriteAllLines(
  $salidaResuelta,
  $sql,
  $codificacion)
Write-Output "INFORMES=$($ficheros.Count)"
Write-Output "LITERALES=$($entradas.Count)"
Write-Output "SALIDA=$salidaResuelta"
