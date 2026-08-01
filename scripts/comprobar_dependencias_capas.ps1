Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Quitar-ContenidoNoEjecutable {
  param([string]$Contenido)
  $resultado = [regex]::Replace(
    $Contenido,
    "'(?:''|[^'])*'",
    "''")
  $resultado = [regex]::Replace(
    $resultado,
    '(?s)\{.*?\}|\(\*.*?\*\)',
    ' ')
  $resultado = [regex]::Replace($resultado, '(?m)//[^\r\n]*', ' ')
  return $resultado
}

function Visitar-Unidad {
  param(
    [string]$Unidad,
    [hashtable]$Grafo,
    [hashtable]$Estado
  )
  $Estado.Indices[$Unidad] = $Estado.Indice
  $Estado.Minimos[$Unidad] = $Estado.Indice
  $Estado.Indice++
  $Estado.Pila.Push($Unidad)
  [void]$Estado.EnPila.Add($Unidad)
  foreach ($dependencia in $Grafo[$Unidad]) {
    if (-not $Estado.Indices.ContainsKey($dependencia)) {
      Visitar-Unidad -Unidad $dependencia -Grafo $Grafo -Estado $Estado
      $Estado.Minimos[$Unidad] = [Math]::Min(
        $Estado.Minimos[$Unidad],
        $Estado.Minimos[$dependencia])
    }
    elseif ($Estado.EnPila.Contains($dependencia)) {
      $Estado.Minimos[$Unidad] = [Math]::Min(
        $Estado.Minimos[$Unidad],
        $Estado.Indices[$dependencia])
    }
  }
  if ($Estado.Minimos[$Unidad] -eq $Estado.Indices[$Unidad]) {
    $componente = [System.Collections.Generic.List[string]]::new()
    do {
      $miembro = $Estado.Pila.Pop()
      [void]$Estado.EnPila.Remove($miembro)
      $componente.Add($miembro)
    } while ($miembro -ne $Unidad)
    $Estado.Componentes.Add($componente.ToArray())
  }
}

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rutaProyecto = Join-Path $raiz 'fzam.dpr'
$dependenciasPermitidas = @()
$maximoUsosLibADatos = 0
$usosLibADatos = [System.Collections.Generic.List[string]]::new()
$unidadesLibADatos = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
$infracciones = [System.Collections.Generic.List[string]]::new()
$dialogosFueraPresentacion = [System.Collections.Generic.List[string]]::new()
$deudaConocida = [System.Collections.Generic.List[string]]::new()
$dominioSinDialogos = @(
  'inLibConexionesUniDAC',
  'inLibDocumentosTrabajo',
  'inLibGenerarTicketCaja',
  'inLibValoresAutomaticos'
)
$unidades = @{}
$contenidoProyecto = Get-Content -LiteralPath $rutaProyecto -Raw
$rutasProyecto = foreach ($coincidencia in [regex]::Matches(
  $contenidoProyecto,
  "(?is)\b[A-Za-z_][A-Za-z0-9_.]*\s+in\s+'([^']+\.pas)'")) {
  Join-Path $raiz $coincidencia.Groups[1].Value
}
$archivos = $rutasProyecto |
  Sort-Object -Unique |
  Where-Object { Test-Path -LiteralPath $_ } |
  ForEach-Object { Get-Item -LiteralPath $_ } |
  Where-Object {
    $_.FullName -notlike '*\3rdpartyComp\*' -and
    $_.FullName -notlike '*\Lib\sqlformatter\*'
  }

foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $coincidenciaUnidad = [regex]::Match(
    $limpio,
    '(?im)^\s*unit\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;')
  if ($coincidenciaUnidad.Success) {
    $nombre = $coincidenciaUnidad.Groups[1].Value
    $unidades[$nombre.ToLowerInvariant()] = @{
      Archivo = $archivo.FullName
      Limpio = $limpio
      Nombre = $nombre
    }
  }
}

$grafo = @{}
foreach ($clave in $unidades.Keys) {
  $grafo[$clave] = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
}

foreach ($clave in $unidades.Keys) {
  $unidad = $unidades[$clave]
  $dependencias = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  foreach ($bloqueUses in [regex]::Matches(
    $unidad.Limpio,
    '(?is)\buses\b(.*?);')) {
    foreach ($coincidencia in [regex]::Matches(
      $bloqueUses.Groups[1].Value,
      '\b[A-Za-z_][A-Za-z0-9_.]*\b')) {
      $dependencia = $coincidencia.Value
      [void]$dependencias.Add($dependencia)
      $claveDependencia = $dependencia.ToLowerInvariant()
      if ($unidades.ContainsKey($claveDependencia)) {
        [void]$grafo[$clave].Add($claveDependencia)
      }
    }
  }
  $esCapaLogica = $unidad.Nombre -match '^(?i)(inLib|UniData)'
  if ($esCapaLogica) {
    foreach ($dependencia in $dependencias) {
      if ($dependencia -match '^(?i)inMto') {
        $clavePermitida =
          ($unidad.Nombre + '->' + $dependencia).ToLowerInvariant()
        $relativa = [System.IO.Path]::GetRelativePath(
          $raiz,
          $unidad.Archivo)
        $detalle =
          $unidad.Nombre + ' -> ' + $dependencia + ' (' + $relativa + ')'
        if ($dependenciasPermitidas -contains $clavePermitida) {
          $deudaConocida.Add($detalle)
        }
        else {
          $infracciones.Add($detalle)
        }
      }
    }
  }
  if ($unidad.Nombre -match '^(?i)inLib') {
    foreach ($dependencia in $dependencias) {
      if ($dependencia -match '^(?i)UniData') {
        $relativa = [System.IO.Path]::GetRelativePath(
          $raiz,
          $unidad.Archivo)
        $usosLibADatos.Add(
          $unidad.Nombre + ' -> ' + $dependencia + ' (' + $relativa + ')')
        [void]$unidadesLibADatos.Add($unidad.Nombre)
      }
    }
  }
  $esDatos = $unidad.Nombre -match '^(?i)UniData'
  $esDominioControlado = $dominioSinDialogos -contains $unidad.Nombre
  if ($esDatos -or $esDominioControlado) {
    $dialogos = [regex]::Matches(
      $unidad.Limpio,
      '(?i)\b(ShowMessage\w*|MessageDlg\w*|InputQuery\w*|' +
      'MessageBox\w*)\b')
    if ($dialogos.Count -gt 0) {
      $relativa = [System.IO.Path]::GetRelativePath(
        $raiz,
        $unidad.Archivo)
      $nombresDialogos = $dialogos |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique
      $dialogosFueraPresentacion.Add(
        $unidad.Nombre + ': ' + ($nombresDialogos -join ', ') +
        ' (' + $relativa + ')')
    }
  }
  if ($unidad.Nombre -ine 'inMtoPrincipal' -and
      $unidad.Limpio -match '\b(TfrmMtoPrincipal|frmMtoPrincipal)\b') {
    $relativa = [System.IO.Path]::GetRelativePath(
      $raiz,
      $unidad.Archivo)
    $infracciones.Add(
      $unidad.Nombre + ' conoce directamente al formulario principal (' +
      $relativa + ')')
  }
}

$estado = @{
  Componentes = [System.Collections.Generic.List[object]]::new()
  EnPila = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  Indice = 0
  Indices = @{}
  Minimos = @{}
  Pila = [System.Collections.Generic.Stack[string]]::new()
}
foreach ($unidad in $grafo.Keys) {
  if (-not $estado.Indices.ContainsKey($unidad)) {
    Visitar-Unidad -Unidad $unidad -Grafo $grafo -Estado $estado
  }
}

$ciclos = [System.Collections.Generic.List[string]]::new()
foreach ($componente in $estado.Componentes) {
  if ($componente.Count -gt 1) {
    $nombres = foreach ($miembro in $componente) {
      $unidades[$miembro].Nombre
    }
    $ciclos.Add(($nombres | Sort-Object) -join ' -> ')
  }
}

if ($infracciones.Count -gt 0) {
  Write-Host 'Dependencias de capa no permitidas:'
  foreach ($infraccion in $infracciones) {
    Write-Host ('  ' + $infraccion)
  }
}
if ($ciclos.Count -gt 0) {
  Write-Host 'Ciclos de unidades no permitidos:'
  foreach ($ciclo in $ciclos) {
    Write-Host ('  ' + $ciclo)
  }
}
if ($usosLibADatos.Count -gt 0) {
  Write-Host 'Deuda inLib* -> UniData* (Opcion A, objetivo 0):'
  foreach ($uso in ($usosLibADatos | Sort-Object)) {
    Write-Host ('  ' + $uso)
  }
}
if ($dialogosFueraPresentacion.Count -gt 0) {
  Write-Host 'Dialogos fuera de la capa de presentacion:'
  foreach ($dialogo in $dialogosFueraPresentacion) {
    Write-Host ('  ' + $dialogo)
  }
}
$excesoLibADatos = $usosLibADatos.Count -gt $maximoUsosLibADatos
if ($excesoLibADatos) {
  Write-Host (
    'Dependencias inLib* -> UniData*: ' + $usosLibADatos.Count +
    '; maximo permitido: ' + $maximoUsosLibADatos + '.')
}
if (($infracciones.Count -gt 0) -or ($ciclos.Count -gt 0) -or
    $excesoLibADatos -or ($dialogosFueraPresentacion.Count -gt 0)) {
  exit 1
}

Write-Host (
  'Dependencias de capa: OK. Unidades analizadas: ' +
  $unidades.Count + '. Ciclo mayor: 1. Usos inLib*->UniData*: ' +
  $usosLibADatos.Count + '/' + $maximoUsosLibADatos +
  ' en ' + $unidadesLibADatos.Count + ' unidades.')
if ($deudaConocida.Count -gt 0) {
  Write-Host 'Deuda conocida permitida:'
  foreach ($dependencia in $deudaConocida) {
    Write-Host ('  ' + $dependencia)
  }
}
