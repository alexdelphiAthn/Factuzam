$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$salida = Join-Path $raiz 'build_codex_cierre_prestashop'
$prueba = Join-Path $PSScriptRoot 'PruebasCierreColaPrestaShop.dpr'
$repositorio = Join-Path $raiz 'src\DataModules\UniDataPrestaShopCola.pas'
$worker = Join-Path $raiz 'src\Lib\inLibPrestaShopCola.pas'
$principal = Join-Path $raiz 'src\Core\inMtoPrincipal.pas'

New-Item -ItemType Directory -Path $salida -Force | Out-Null

$codigoRepositorio = Get-Content -LiteralPath $repositorio -Raw
$patronLiberacion = '(?s)function TRepositorioPrestaShopColaUniDAC\.LiberarReclamacionSinIntento.*?(?=\r?\nfunction TRepositorioPrestaShopColaUniDAC\.MarcarAltaEnCurso)'
$coincidencia = [regex]::Match($codigoRepositorio, $patronLiberacion)
if (-not $coincidencia.Success) {
  throw 'No se encontró LiberarReclamacionSinIntento'
}
$liberacion = $coincidencia.Value

if ($liberacion -notmatch 'ID_RECLAMACION_PSCOLA = :TOKEN') {
  throw 'La liberación no está protegida por token'
}
if ($liberacion -notmatch 'RowsAffected = 1') {
  throw 'La liberación no exige una única fila afectada'
}
if ($liberacion -match 'CONTADOR_INTENTOS_PSCOLA\s*=') {
  throw 'La liberación consume o modifica intentos'
}
if ($liberacion -match 'MENSAJE_ERROR_PSCOLA\s*=') {
  throw 'La liberación modifica la marca o el mensaje de la cola'
}
if ($liberacion -match 'VERSION_DESEADA_PSCOLA\s*=') {
  throw 'La liberación pisa una versión deseada concurrente'
}
if ($liberacion -notmatch 'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA') {
  throw 'La liberación no preserva el indicador de precio reclamado'
}
if ($liberacion -notmatch 'ESCAMBIO_STOCK_RECLAMADO_PSCOLA') {
  throw 'La liberación no preserva el indicador de stock reclamado'
}
if ($liberacion -notmatch 'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA') {
  throw 'La liberación no preserva la acción de visibilidad reclamada'
}

$codigoWorker = Get-Content -LiteralPath $worker -Raw
if ($codigoWorker -match 'TerminateThread') {
  throw 'El worker contiene TerminateThread'
}
if ($codigoWorker -notmatch 'ComprobarCierreSeguro;\s*FRepositorio\.MarcarEnviada') {
  throw 'Falta el punto seguro antes de confirmar la fila enviada'
}
if ($codigoWorker -notmatch 'if FControlTrabajo\.DebeLiberarTrabajo or\s*\(E is ECierreForzadoPrestaShop\) then\s*LiberarTrabajoActual') {
  throw 'Una excepción HTTP durante el cierre no libera primero la fila'
}

$codigoPrincipal = Get-Content -LiteralPath $principal -Raw
$posCierre = $codigoPrincipal.IndexOf('procedure TfrmMtoPrincipal.FormClose(')
$posRelanzamiento = $codigoPrincipal.IndexOf('RelanzarLoginSiPendiente;', $posCierre)
$posInvocar = $codigoPrincipal.IndexOf('procedure TfrmMtoPrincipal.mnuInvocarLoginClick')
$bloqueInvocar = [regex]::Match(
  $codigoPrincipal.Substring($posInvocar),
  '(?s)^.*?\r?\nend;').Value
if ($posRelanzamiento -lt $posCierre) {
  throw 'El relanzamiento no se ejecuta desde el cierre aprobado'
}
if ($bloqueInvocar -match 'ShellExecute') {
  throw 'Invocar login todavía relanza antes de aprobar el cierre'
}

$unidades = Join-Path $raiz 'src\Lib'
$orden = 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && dcc32 -B -Q -E"' + $salida + '" -N0"' + $salida + '" -U"' + $unidades + '" "' + $prueba + '"'
& cmd.exe /d /c $orden
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$ejecutable = Join-Path $salida 'PruebasCierreColaPrestaShop.exe'
& $ejecutable
exit $LASTEXITCODE
