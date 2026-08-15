$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$worker = Join-Path $raiz 'src\Lib\inLibPrestaShopCola.pas'
$codigo = Get-Content -LiteralPath $worker -Raw

function Obtener-Bloque {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Inicio,
    [Parameter(Mandatory = $true)]
    [string]$Fin
  )

  $posInicio = $codigo.IndexOf($Inicio)
  $posFin = $codigo.IndexOf($Fin, $posInicio + $Inicio.Length)
  if (($posInicio -lt 0) -or ($posFin -lt 0)) {
    throw "No se pudo aislar el bloque $Inicio"
  }
  return $codigo.Substring($posInicio, $posFin - $posInicio)
}

function Comprobar-SincronizacionDecimal {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Bloque,
    [Parameter(Mandatory = $true)]
    [string]$Lectura,
    [Parameter(Mandatory = $true)]
    [string]$Actualizacion,
    [Parameter(Mandatory = $true)]
    [string]$ErrorEsperado
  )

  $numeroLecturas = ([regex]::Matches($Bloque, [regex]::Escape($Lectura))).Count
  $numeroActualizaciones = ([regex]::Matches($Bloque, [regex]::Escape($Actualizacion))).Count
  if ($numeroLecturas -ne 2) {
    throw "$Lectura debe aparecer exactamente dos veces en el código"
  }
  if ($numeroActualizaciones -ne 1) {
    throw "$Actualizacion debe aparecer exactamente una vez en el código"
  }

  $patron = '(?s)' + [regex]::Escape($Lectura) +
    '.*?if PrecioDiferente\(.*?\) then\s*begin' +
    '.*?' + [regex]::Escape($Actualizacion) +
    '.*?AsegurarLease\(ATrabajo\);\s*' +
    '.*?' + [regex]::Escape($Lectura) +
    '.*?' + [regex]::Escape($ErrorEsperado) +
    '.*?\r?\n\s*end;'
  if ($Bloque -notmatch $patron) {
    throw "La segunda $Lectura no está limitada a la rama que hace PATCH"
  }
}

$articulo = Obtener-Bloque `
  -Inicio 'procedure THiloPrestaShopCola.ProcesarArticulo(' `
  -Fin 'function THiloPrestaShopCola.PrepararPlanArticulo('
$linea = Obtener-Bloque `
  -Inicio 'procedure THiloPrestaShopCola.ProcesarLinea(' `
  -Fin 'procedure THiloPrestaShopCola.GuardarError('

Comprobar-SincronizacionDecimal `
  -Bloque $articulo `
  -Lectura 'ACliente.LeerPrecioProducto(' `
  -Actualizacion 'ACliente.ActualizarPrecioProducto(' `
  -ErrorEsperado 'SPrecioProductoNoVerificado'

Comprobar-SincronizacionDecimal `
  -Bloque $linea `
  -Lectura 'ACliente.LeerImpactoPrecioCombinacion(' `
  -Actualizacion 'ACliente.ActualizarImpactoPrecioCombinacion(' `
  -ErrorEsperado 'SPrecioCombinacionNoVerificado'

$numeroLecturasStock = ([regex]::Matches(
  $linea,
  [regex]::Escape('ACliente.LeerCantidadStock('))).Count
$numeroActualizacionesStock = ([regex]::Matches(
  $linea,
  [regex]::Escape('ACliente.ActualizarCantidadStock('))).Count
if ($numeroLecturasStock -ne 2) {
  throw 'LeerCantidadStock debe aparecer exactamente dos veces en el código'
}
if ($numeroActualizacionesStock -ne 1) {
  throw 'ActualizarCantidadStock debe aparecer exactamente una vez en el código'
}
$patronStock = '(?s)ACliente\.LeerCantidadStock\(' +
  '.*?if iActual <> ALinea\.Cantidad then\s*begin' +
  '.*?ACliente\.ActualizarCantidadStock\(' +
  '.*?AsegurarLease\(ATrabajo\);\s*' +
  '.*?ACliente\.LeerCantidadStock\(' +
  '.*?SStockPrestaShopNoVerificado' +
  '.*?\r?\n\s*end;'
if ($linea -notmatch $patronStock) {
  throw 'La segunda lectura de stock no está limitada a la rama que hace PATCH'
}

if ($codigo -match 'TerminateThread') {
  throw 'El worker contiene TerminateThread'
}
if ($codigo -notmatch 'if FControlTrabajo\.DebeLiberarTrabajo or\s*\(E is ECierreForzadoPrestaShop\) then\s*LiberarTrabajoActual') {
  throw 'La optimización alteró la liberación segura al cerrar'
}

'LECTURAS_PRESTASHOP=OK'
