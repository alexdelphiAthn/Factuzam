param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$objetivos = @(
  @{
    Ruta = 'src\Forms\inMtoComprasSesiones.pas'
    Metodo = 'btnCrearClick'
  },
  @{
    Ruta = 'src\Forms\inMtoPedidosCompra.pas'
    Metodo = 'btnCrearAlbaranClick'
  },
  @{
    Ruta = 'src\Forms\inMtoDevolucionesCompra.pas'
    Metodo = 'DevolverTodoStock'
  },
  @{
    Ruta = 'src\Forms\inMtoFacturasBase.pas'
    Metodo = 'GuardarPendienteAntesDeImprimir'
  },
  @{
    Ruta = 'src\Forms\inMtoFacturasBase.pas'
    Clase = 'TControladorFacturas'
    Metodo = 'GuardarPendienteAntesDeImprimir'
  },
  @{
    Ruta = 'src\Forms\inMtoFacturasBase.pas'
    Clase = 'TControladorFacturas'
    Metodo = 'MostrarSkuArticulo'
  },
  @{
    Ruta = 'src\Forms\inMtoFacturasBase.pas'
    Metodo = 'ContarHijosActivos'
  },
  @{
    Ruta = 'src\Forms\inMtoArticulos.pas'
    Metodo = 'AsegurarSkuArticuloSinVariaciones'
  },
  @{
    Ruta = 'src\Forms\inMtoArticulos.pas'
    Metodo = 'AsegurarSkuArticulo'
  },
  @{
    Ruta = 'src\Forms\inMtoArticulos.pas'
    Metodo = 'btnGenerarCBClick'
  },
  @{
    Ruta = 'src\Forms\inMtoArticulos.pas'
    Metodo = 'ConstruirSqlArticulos'
  }
)

$patronProhibido =
  '(?i)\.SQL\.Text\s*:=|StartTransaction|\.Commit\s*;|\.Rollback\s*;'
$errores = [System.Collections.Generic.List[string]]::new()

foreach ($objetivo in $objetivos) {
  $ruta = Join-Path $Raiz $objetivo.Ruta
  $contenido = Get-Content -LiteralPath $ruta -Raw
  $nombre = [Regex]::Escape($objetivo.Metodo)
  if ($objetivo.ContainsKey('Clase')) {
    $clase = [Regex]::Escape($objetivo.Clase)
    $etiqueta =
      "$($objetivo.Ruta):$($objetivo.Clase).$($objetivo.Metodo)"
  }
  else {
    $clase = 'Tfrm\w+'
    $etiqueta = "$($objetivo.Ruta):$($objetivo.Metodo)"
  }
  $patronMetodo =
    "(?ms)^(?:procedure|function)\s+$clase\.$nombre\b.*?" +
    "(?=^(?:procedure|function|constructor|destructor)" +
    "\s+T\w+\.|\z)"
  $coincidencia = [Regex]::Match($contenido, $patronMetodo)
  if (-not $coincidencia.Success) {
    $errores.Add("No se encontro $etiqueta.")
  }
  elseif ([Regex]::IsMatch($coincidencia.Value, $patronProhibido)) {
    $errores.Add("SQL o transaccion directa en $etiqueta.")
  }
}

$rutaSesiones = Join-Path $Raiz 'src\Forms\inMtoComprasSesiones.pas'
$sesiones = Get-Content -LiteralPath $rutaSesiones -Raw
if ($sesiones -match 'MaterializarSesionConTx') {
  $errores.Add(
    'MaterializarSesionConTx sigue declarado dentro del formulario.')
}

if ($errores.Count -gt 0) {
  $errores | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output (
  'Formularios delgados: OK. Metodos protegidos: ' +
  $objetivos.Count + '.')
