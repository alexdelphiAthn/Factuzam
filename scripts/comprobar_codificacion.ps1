param(
  [string]$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$RutaLineaBase = 'scripts\codificacion_linea_base.csv',
  [switch]$ActualizarLineaBase,
  [switch]$MostrarTodos
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$extensionesBomUtf8 = @('.pas', '.dfm', '.dpr')
$extensionesCrLf = @(
  '.pas', '.dfm', '.dpr', '.dproj', '.groupproj', '.deployproj',
  '.dpk', '.fmx', '.dsv', '.~dsk', '.inc', '.rc', '.sql', '.md',
  '.txt', '.bat', '.cmd', '.ps1', '.xml', '.json', '.csv',
  '.dxsettings'
)
$extensionesLf = @(
  '.php', '.py', '.html', '.css', '.svg', '.nsi', '.bpk', '.cpp',
  '.dof', '.conf', '.kof', '.skincfg'
)
$nombresLf = @(
  '.editorconfig', '.gitignore', '.gitconfig', 'LICENSE', 'README',
  'touch', 'entornopre'
)
$nombresCrLf = @('.gitattributes')
$directoriosIgnorados = @(
  '.git', '__history', '__recovery', '$tmp', 'Android64', 'Win32', 'Win64',
  'Debug', 'Release', 'bin', 'build', 'dcu'
)
$prefijosSinControlTexto = @(
  'DESARROLLOS EN CURSO\migracion\',
  'src\3rdpartyComp\',
  'factuzam_original.sql'
)
$utf8Estricto = [System.Text.UTF8Encoding]::new($false, $true)

function Obtener-ArchivosActuales {
  return @(
    Get-ChildItem -LiteralPath $Raiz -File -Recurse -Force |
      ForEach-Object {
        $rutaRelativa = [System.IO.Path]::GetRelativePath(
          $Raiz,
          $_.FullName).Replace('/', '\')
        $partes = $rutaRelativa.Split('\')
        $ignorar = @(
          $partes |
            Where-Object { $directoriosIgnorados -contains $_ }
        ).Count -gt 0
        if (-not $ignorar) {
          $rutaRelativa
        }
      } |
      Sort-Object -Unique
  )
}

function Tiene-BomUtf8 {
  param([byte[]]$Bytes)
  return ($Bytes.Length -ge 3) -and
    ($Bytes[0] -eq 0xEF) -and
    ($Bytes[1] -eq 0xBB) -and
    ($Bytes[2] -eq 0xBF)
}

function Es-Utf8Valido {
  param([byte[]]$Bytes)
  try {
    [void]$utf8Estricto.GetString($Bytes)
    return $true
  }
  catch [System.Text.DecoderFallbackException] {
    return $false
  }
}

function Obtener-FinalesLinea {
  param([byte[]]$Bytes)
  $tieneCrLf = $false
  $tieneLf = $false
  $tieneCr = $false
  $indice = 0
  while ($indice -lt $Bytes.Length) {
    if ($Bytes[$indice] -eq 0x0D) {
      if (($indice + 1 -lt $Bytes.Length) -and
          ($Bytes[$indice + 1] -eq 0x0A)) {
        $tieneCrLf = $true
        $indice += 2
      }
      else {
        $tieneCr = $true
        $indice++
      }
    }
    elseif ($Bytes[$indice] -eq 0x0A) {
      $tieneLf = $true
      $indice++
    }
    else {
      $indice++
    }
  }
  return [pscustomobject]@{
    CrLf = $tieneCrLf
    Lf = $tieneLf
    Cr = $tieneCr
  }
}

function Agregar-Problema {
  param(
    [System.Collections.Generic.List[object]]$Problemas,
    [string]$Problema,
    [string]$Ruta
  )
  $Problemas.Add([pscustomobject]@{
    Problema = $Problema
    Ruta = $Ruta
  })
}

function Obtener-ProblemasArchivo {
  param(
    [string]$RutaRelativa,
    [System.Collections.Generic.List[object]]$Problemas
  )
  $rutaExcluida = @(
    $prefijosSinControlTexto |
      Where-Object {
        $RutaRelativa.StartsWith(
          $_,
          [System.StringComparison]::OrdinalIgnoreCase)
      }
  ).Count -gt 0
  if ($rutaExcluida) {
    return
  }
  $rutaCompleta = Join-Path $Raiz $RutaRelativa
  if (-not (Test-Path -LiteralPath $rutaCompleta -PathType Leaf)) {
    return
  }
  $extension = [System.IO.Path]::GetExtension(
    $RutaRelativa).ToLowerInvariant()
  $nombre = [System.IO.Path]::GetFileName($RutaRelativa)
  $requiereCrLf = ($extensionesCrLf -contains $extension) -or
    ($nombresCrLf -contains $nombre)
  $requiereLf = ($extensionesLf -contains $extension) -or
    ($nombresLf -contains $nombre)
  $requiereBom = $extensionesBomUtf8 -contains $extension
  if (-not ($requiereCrLf -or $requiereLf -or $requiereBom)) {
    return
  }
  $bytes = [System.IO.File]::ReadAllBytes($rutaCompleta)
  if ($requiereBom -and (-not (Tiene-BomUtf8 -Bytes $bytes))) {
    Agregar-Problema $Problemas 'BOM_UTF8_AUSENTE' $RutaRelativa
  }
  if (-not (Es-Utf8Valido -Bytes $bytes)) {
    Agregar-Problema $Problemas 'UTF8_INVALIDO' $RutaRelativa
  }
  $finales = Obtener-FinalesLinea -Bytes $bytes
  $cantidadTipos = [int]$finales.CrLf + [int]$finales.Lf +
    [int]$finales.Cr
  if ($cantidadTipos -gt 1) {
    Agregar-Problema $Problemas 'FINALES_MEZCLADOS' $RutaRelativa
  }
  elseif ($requiereCrLf -and $finales.Lf) {
    Agregar-Problema $Problemas 'FINALES_LF_EN_CRLF' $RutaRelativa
  }
  elseif ($requiereLf -and $finales.CrLf) {
    Agregar-Problema $Problemas 'FINALES_CRLF_EN_LF' $RutaRelativa
  }
  elseif ($finales.Cr) {
    Agregar-Problema $Problemas 'FINALES_CR_SOLO' $RutaRelativa
  }
}

function Clave-Problema {
  param([object]$Problema)
  return $Problema.Problema + '|' + $Problema.Ruta
}

function Guardar-LineaBase {
  param(
    [string]$Ruta,
    [object[]]$Problemas
  )
  $directorio = Split-Path -Parent $Ruta
  if (-not (Test-Path -LiteralPath $directorio)) {
    [void](New-Item -ItemType Directory -Path $directorio)
  }
  $lineas = @(
    $Problemas |
      Sort-Object Problema, Ruta |
      ConvertTo-Csv -Delimiter ';' -NoTypeInformation
  )
  $contenido = ($lineas -join "`r`n") + "`r`n"
  $utf8SinBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Ruta, $contenido, $utf8SinBom)
}

$problemas = [System.Collections.Generic.List[object]]::new()
$archivos = Obtener-ArchivosActuales
foreach ($ruta in $archivos) {
  Obtener-ProblemasArchivo -RutaRelativa $ruta -Problemas $problemas
}
$rutaLineaBaseCompleta = Join-Path $Raiz $RutaLineaBase
if ($ActualizarLineaBase) {
  Guardar-LineaBase -Ruta $rutaLineaBaseCompleta -Problemas $problemas
  Write-Output (
    'Línea base de codificación actualizada: ' + $problemas.Count +
    ' excepciones en ' + $RutaLineaBase + '.')
  return
}
if (-not (Test-Path -LiteralPath $rutaLineaBaseCompleta)) {
  throw 'No existe la línea base. Ejecute con -ActualizarLineaBase.'
}
$lineaBase = @(
  Import-Csv -LiteralPath $rutaLineaBaseCompleta -Delimiter ';'
)
$clavesActuales = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
$clavesBase = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
foreach ($problema in $problemas) {
  [void]$clavesActuales.Add((Clave-Problema $problema))
}
foreach ($problema in $lineaBase) {
  [void]$clavesBase.Add((Clave-Problema $problema))
}
$nuevos = @(
  $problemas |
    Where-Object { -not $clavesBase.Contains((Clave-Problema $_)) } |
    Sort-Object Problema, Ruta
)
$resueltos = @(
  $lineaBase |
    Where-Object { -not $clavesActuales.Contains((Clave-Problema $_)) } |
    Sort-Object Problema, Ruta
)
$resumen = @(
  $problemas |
    Group-Object Problema |
    Sort-Object Name
)
Write-Output 'Excepciones de codificación y finales de línea:'
foreach ($grupo in $resumen) {
  Write-Output ('  ' + $grupo.Name + ': ' + $grupo.Count)
}
if ($MostrarTodos) {
  $problemas |
    Sort-Object Problema, Ruta |
    Format-Table Problema, Ruta -AutoSize
}
if ($nuevos.Count -gt 0) {
  Write-Output 'Infracciones nuevas:'
  $nuevos |
    Format-Table Problema, Ruta -AutoSize
}
if ($resueltos.Count -gt 0) {
  Write-Output 'Excepciones resueltas pendientes de retirar de la línea base:'
  $resueltos |
    Format-Table Problema, Ruta -AutoSize
}
if (($nuevos.Count -gt 0) -or ($resueltos.Count -gt 0)) {
  throw (
    'La codificación se aparta de la línea base. Nuevas: ' +
    $nuevos.Count + '; resueltas sin consolidar: ' + $resueltos.Count + '.')
}
Write-Output (
  'Codificación: OK. Archivos revisados: ' + $archivos.Count +
  '; excepciones heredadas: ' + $problemas.Count +
  '; nuevas: 0.')
