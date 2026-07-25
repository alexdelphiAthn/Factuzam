param(
  [string]$RaizRepositorio = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Stop'
$raizSrc = Join-Path $RaizRepositorio 'src'
if (-not (Test-Path -LiteralPath $raizSrc)) {
  throw "No existe la carpeta src en $RaizRepositorio"
}
$archivoProyecto = Join-Path $RaizRepositorio 'fzam.dpr'
$archivos = @(
  Get-ChildItem -LiteralPath $raizSrc -Recurse -File -Filter '*.pas'
)
if (Test-Path -LiteralPath $archivoProyecto) {
  $archivos += Get-Item -LiteralPath $archivoProyecto
}
$contenidos = @{}
foreach ($archivo in $archivos) {
  $contenidos[$archivo.FullName] = Get-Content -LiteralPath $archivo.FullName -Raw -Encoding UTF8
}
function Obtener-RutaRelativa {
  param([string]$Ruta)
  return [System.IO.Path]::GetRelativePath($RaizRepositorio, $Ruta)
}
function Obtener-UnidadesConPatron {
  param(
    [string]$Patron,
    [string[]]$Excluir = @()
  )
  $resultado = @()
  foreach ($archivo in $archivos) {
    if ($Excluir -contains $archivo.Name) {
      continue
    }
    if ([regex]::IsMatch($contenidos[$archivo.FullName], $Patron)) {
      $resultado += Obtener-RutaRelativa $archivo.FullName
    }
  }
  return @($resultado | Sort-Object)
}
function Obtener-UsosDeUnidad {
  param([string]$NombreUnidad)
  $resultado = @()
  foreach ($archivo in $archivos) {
    $bloquesUses = [regex]::Matches(
      $contenidos[$archivo.FullName],
      '(?is)\buses\b(?<contenido>.*?);'
    )
    foreach ($bloqueUses in $bloquesUses) {
      if ([regex]::IsMatch(
        $bloqueUses.Groups['contenido'].Value,
        "\b$([regex]::Escape($NombreUnidad))\b"
      )) {
        $resultado += Obtener-RutaRelativa $archivo.FullName
        break
      }
    }
  }
  return @($resultado | Sort-Object)
}
function Obtener-MetodosGlobal {
  param([string]$NombreGlobal)
  $conteos = @{}
  foreach ($contenido in $contenidos.Values) {
    $coincidencias = [regex]::Matches(
      $contenido,
      "\b$([regex]::Escape($NombreGlobal))\.(?<metodo>[A-Za-z_][A-Za-z0-9_]*)"
    )
    foreach ($coincidencia in $coincidencias) {
      $metodo = $coincidencia.Groups['metodo'].Value
      if (-not $conteos.ContainsKey($metodo)) {
        $conteos[$metodo] = 0
      }
      $conteos[$metodo]++
    }
  }
  return $conteos
}
function Mostrar-Lista {
  param(
    [string]$Titulo,
    [object[]]$Elementos
  )
  Write-Output "$Titulo ($($Elementos.Count))"
  foreach ($elemento in $Elementos) {
    Write-Output "  $elemento"
  }
}
$usosApp = Obtener-UsosDeUnidad 'inLibAppParam'
$usosCaja = Obtener-UsosDeUnidad 'inLibCajaParam'
$mencionesApp = Obtener-UnidadesConPatron '\binLibAppParam\b'
$mencionesCaja = Obtener-UnidadesConPatron '\binLibCajaParam\b'
$globalesApp = Obtener-UnidadesConPatron '\boAppParams\.'
$globalesCaja = Obtener-UnidadesConPatron '\boCajaParams\.'
$nombresGlobales = Obtener-UnidadesConPatron '\bo(App|Caja)Params\b'
$funcionesCaja = Obtener-UnidadesConPatron '\b(TarifaDefecto|NivelesFamiliaArqueo)\b' @('inLibCajaParam.pas')
$metodosApp = Obtener-MetodosGlobal 'oAppParams'
$metodosCaja = Obtener-MetodosGlobal 'oCajaParams'
$totalApp = ($metodosApp.Values | Measure-Object -Sum).Sum
$totalCaja = ($metodosCaja.Values | Measure-Object -Sum).Sum
$unidadesGlobales = @(
  @($globalesApp) + @($globalesCaja) | Sort-Object -Unique
)
$inicializacion = @()
foreach ($archivo in $archivos) {
  $contenido = $contenidos[$archivo.FullName]
  $secciones = [regex]::Matches(
    $contenido,
    '(?is)\binitialization\b(?<contenido>.*?)(?:\bfinalization\b|\bend\.)'
  )
  foreach ($seccion in $secciones) {
    if ([regex]::IsMatch(
      $seccion.Groups['contenido'].Value,
      '\bo(App|Caja)Params\.'
    )) {
      $inicializacion += Obtener-RutaRelativa $archivo.FullName
      break
    }
  }
}
Write-Output 'INVENTARIO DE PARÁMETROS GLOBALES — FASE XII-0'
Write-Output "Raíz: $RaizRepositorio"
Write-Output "Unidades Pascal analizadas: $($archivos.Count)"
Write-Output (
  "Accesos directos: $($totalApp + $totalCaja) en " +
  "$($unidadesGlobales.Count) unidades ($totalApp App / $totalCaja Caja)"
)
Write-Output "Unidades que mencionan los nombres globales: $($nombresGlobales.Count)"
Write-Output ''
Mostrar-Lista 'ficheros que mencionan inLibAppParam' $mencionesApp
Write-Output ''
Mostrar-Lista 'ficheros que mencionan inLibCajaParam' $mencionesCaja
Write-Output ''
Mostrar-Lista 'uses inLibAppParam' $usosApp
Write-Output ''
Mostrar-Lista 'uses inLibCajaParam' $usosCaja
Write-Output ''
Write-Output 'Entradas explícitas en fzam.dpr'
Write-Output "  inLibAppParam: $([regex]::IsMatch($contenidos[$archivoProyecto], '\binLibAppParam\b'))"
Write-Output "  inLibCajaParam: $([regex]::IsMatch($contenidos[$archivoProyecto], '\binLibCajaParam\b'))"
Write-Output ''
Mostrar-Lista 'unidades con oAppParams.*' $globalesApp
Write-Output ''
Mostrar-Lista 'unidades con oCajaParams.*' $globalesCaja
Write-Output ''
Mostrar-Lista 'unidades con funciones libres de Caja' $funcionesCaja
Write-Output ''
Write-Output 'Métodos directos App'
foreach ($entrada in @($metodosApp.GetEnumerator() | Sort-Object Name)) {
  Write-Output "  $($entrada.Name): $($entrada.Value)"
}
Write-Output ''
Write-Output 'Métodos directos Caja'
foreach ($entrada in @($metodosCaja.GetEnumerator() | Sort-Object Name)) {
  Write-Output "  $($entrada.Name): $($entrada.Value)"
}
Write-Output ''
Mostrar-Lista 'lecturas de parámetros dentro de initialization' $inicializacion
Write-Output ''
$patronesPropagacion = [ordered]@{
  'SqlFiltroEmpAlmCaja' = '\bSqlFiltroEmpAlmCaja\b'
  'TArticulosResolver.Create' = '\bTArticulosResolver\.Create\b'
  'ExportarExcel' = '\bExportarExcel\b'
  'TClienteFactuzamApi' = '\bTClienteFactuzamApi\b'
  'TVentasWsCola' = '\bTVentasWsCola\.'
}
Write-Output 'Indicadores de propagación por firmas'
foreach ($entrada in $patronesPropagacion.GetEnumerator()) {
  $unidades = Obtener-UnidadesConPatron $entrada.Value
  Write-Output "  $($entrada.Key): $($unidades.Count) unidades"
}
