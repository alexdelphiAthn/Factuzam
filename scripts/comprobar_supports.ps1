param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoSupportsFueraDeListaBlanca = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Trinquete de la Fase 4 del PLAN_SOLID: Supports() solo en creacion,
# teardown o lista blanca (broadcast de caja, Exigir*, Heredar*). Todo
# uso nuevo fuera de esos contextos rompe el build. El tope solo baja.

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
        $ruta = $_.FullName
        -not ($exclusiones | Where-Object { $ruta.Contains($_) })
      }
  )
}

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

# Unidades enteras permitidas: descubrimiento de receptores sobre
# Screen.Forms (broadcast), no localizacion de servicios.
$unidadesListaBlanca = @('inLibCajaVentanasIntf.pas')

# Rutinas permitidas: descubrimiento en creacion, teardown o asercion
# ruidosa. Se compara el ultimo segmento del nombre (sin la clase).
$rutinasExactas = @(
  'Create', 'CreateNew', 'Destroy',
  'FormCreate', 'FormDestroy', 'FormClose',
  'InicializarAplicacion', 'ConstruirModoEntrada',
  'CrearTablaPrincipal', 'CrearOperacionCaja',
  'CrearConsultaOperacionesCaja'
)
$patronPrefijos = '^(Heredar|Exigir|ResolverServicio)'

# Cabeceras de rutina de primer nivel (columna 1): las anidadas se
# atribuyen a la rutina contenedora.
$patronCabecera =
  '^(?:class\s+)?(?:procedure|function|constructor|destructor)' +
  '\s+([\w.]+)'

$rutaSrc = Join-Path $Raiz 'src'
if (-not (Test-Path -LiteralPath $rutaSrc -PathType Container)) {
  throw "No se encontro el directorio de fuentes: $rutaSrc."
}
$infracciones = [System.Collections.Generic.List[object]]::new()
$archivos = Obtener-ArchivosPascalPropios -RutaRaiz $Raiz
foreach ($archivo in $archivos) {
  if ($unidadesListaBlanca -contains $archivo.Name) {
    continue
  }
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  $limpio = Quitar-ContenidoNoEjecutable -Contenido $contenido
  $lineas = $limpio -split "`n"
  $rutina = ''
  for ($i = 0; $i -lt $lineas.Count; $i++) {
    $cabecera = [regex]::Match($lineas[$i], $patronCabecera)
    if ($cabecera.Success) {
      $partes = $cabecera.Groups[1].Value -split '\.'
      $rutina = $partes[$partes.Count - 1]
    }
    if ($lineas[$i] -match '\bSupports\s*\(') {
      $permitida =
        ($rutinasExactas -contains $rutina) -or
        ($rutina -match $patronPrefijos)
      if (-not $permitida) {
        $infracciones.Add([pscustomobject]@{
          Linea = $i + 1
          Rutina = $rutina
          Ruta = [System.IO.Path]::GetRelativePath(
            $Raiz,
            $archivo.FullName)
        })
      }
    }
  }
}

Write-Output 'Supports() fuera de lista blanca:'
Write-Output (
  $infracciones |
    Sort-Object Ruta, Linea |
    Format-Table Ruta, Linea, Rutina -AutoSize |
    Out-String
).TrimEnd()

if ($infracciones.Count -gt $MaximoSupportsFueraDeListaBlanca) {
  Write-Error (
    "Supports fuera de lista blanca: $($infracciones.Count); " +
    "maximo permitido: $MaximoSupportsFueraDeListaBlanca.")
  exit 1
}
Write-Output (
  'Supports: OK. Fuera de lista blanca: ' +
  "$($infracciones.Count) (tope $MaximoSupportsFueraDeListaBlanca).")
