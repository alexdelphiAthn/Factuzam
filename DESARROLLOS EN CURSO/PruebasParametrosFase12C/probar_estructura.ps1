param(
  [string]$RaizRepositorio = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Stop'
$fallos = [System.Collections.Generic.List[string]]::new()
function Comprobar {
  param(
    [bool]$Condicion,
    [string]$Descripcion
  )
  if ($Condicion) {
    Write-Output "OK: $Descripcion"
  }
  else {
    Write-Output "FALLO: $Descripcion"
    $fallos.Add($Descripcion)
  }
}
function Leer {
  param([string]$RutaRelativa)
  return Get-Content -LiteralPath (
    Join-Path $RaizRepositorio $RutaRelativa
  ) -Raw -Encoding UTF8
}
$permitidosAlias = @(
  'src\Core\inMtoPrincipal.pas'
  'src\Lib\inLibAppParam.pas'
  'src\Caja\Lib\inLibCajaParam.pas'
)
$archivosPas = Get-ChildItem -LiteralPath (
  Join-Path $RaizRepositorio 'src'
) -Recurse -File -Filter '*.pas'
$referenciasAliasFuera = @(
  foreach ($archivo in $archivosPas) {
    $relativa = [System.IO.Path]::GetRelativePath(
      $RaizRepositorio,
      $archivo.FullName
    )
    if ($permitidosAlias -notcontains $relativa) {
      $contenido = Get-Content -LiteralPath $archivo.FullName -Raw -Encoding UTF8
      if ($contenido -match '\b(?:oAppParams|oCajaParams)\b') {
        $relativa
      }
    }
  }
)
$dependenciasAntiguasFuera = @(
  foreach ($archivo in $archivosPas) {
    $relativa = [System.IO.Path]::GetRelativePath(
      $RaizRepositorio,
      $archivo.FullName
    )
    if ($permitidosAlias -notcontains $relativa) {
      $contenido = Get-Content -LiteralPath $archivo.FullName -Raw -Encoding UTF8
      if ($contenido -match '\binLib(?:App|Caja)Param\b') {
        $relativa
      }
    }
  }
)
$ventas = Leer 'src\Lib\inLibVentasWsCola.pas'
$verifactu = Leer 'src\verifactu\inLibVerifactuCola.pas'
$conexion = Leer 'src\DataModules\UniDataConn.pas'
$impresora = Leer 'src\Lib\inLibBuscarImpresora.pas'
$principal = Leer 'src\Core\inMtoPrincipal.pas'
$log = Leer 'src\Lib\inLibLog.pas'
Comprobar (
  $referenciasAliasFuera.Count -eq 0
) 'los alias globales solo aparecen en la raíz y las dos unidades puente'
Comprobar (
  $dependenciasAntiguasFuera.Count -eq 0
) 'ningún otro consumidor depende de las unidades antiguas'
Comprobar (
  $log -notmatch '\binLib(?:App|Caja)Param\b'
) 'inLibLog continúa desacoplado de las unidades de parámetros'
Comprobar (
  ($ventas -match '\bFParametrosApp:\s*IParametrosAplicacion;') -and
  ($ventas -match '\bFParametrosApp\s*:=\s*AParametrosApp;') -and
  ($ventas -match '\bFParametrosApp\s*:=\s*nil;')
) 'el hilo de ventas conserva y libera IParametrosAplicacion'
Comprobar (
  ($ventas -match 'class\s+function\s+Activa\(\s*const\s+' +
    'AParametrosCaja:\s*IParametrosCaja\)') -and
  ($ventas -match 'class\s+procedure\s+RegistrarFactura\(\s*const\s+' +
    'AParametrosCaja:\s*IParametrosCaja;') -and
  ($ventas -match 'class\s+procedure\s+AdjuntarPdfSeguro\(\s*const\s+' +
    'AParametrosCaja:\s*IParametrosCaja;')
) 'la API estática de ventas recibe IParametrosCaja explícitamente'
Comprobar (
  ($verifactu -match '\bFParametrosApp:\s*IParametrosAplicacion;') -and
  ($verifactu -match '\bFParametrosCaja:\s*IParametrosCaja;') -and
  ($verifactu -match '\bFParametrosApp\s*:=\s*AParametrosApp;') -and
  ($verifactu -match '\bFParametrosCaja\s*:=\s*AParametrosCaja;')
) 'el hilo Verifactu conserva ambos servicios de parámetros'
Comprobar (
  ($conexion -match '\bFParametrosApp:\s*IParametrosAplicacion;') -and
  ($conexion -match 'procedure\s+AsignarParametrosApp\(') -and
  ($conexion -notmatch '\binLibAppParam\b')
) 'UniDataConn recibe el modo de depuración mediante interfaz'
Comprobar (
  ($impresora -match 'function\s+GetImpresoraCaja\(\s*const\s+' +
    'AParametrosCaja:\s*IParametrosCaja;') -and
  ($impresora -match 'AParametrosCaja\.GetString\(') -and
  ($impresora -notmatch '\boCajaParams\b')
) 'la búsqueda de impresora recibe IParametrosCaja'
Comprobar (
  ($principal -match 'TVerifactuCola\.IniciarHilo\(\s*Conexiones,\s*' +
    'ParametrosApp,\s*ParametrosCaja,') -and
  ($principal -match 'TVentasWsCola\.IniciarHilo\(\s*Conexiones,\s*' +
    'ParametrosApp,') -and
  ($principal -match 'FDmConn\.AsignarParametrosApp\(')
) 'la raíz inyecta los servicios en hilos y conexión'
& git -C $RaizRepositorio diff --quiet -- factuzam_original.sql
Comprobar (
  $LASTEXITCODE -eq 0
) 'factuzam_original.sql permanece intacto'
if ($referenciasAliasFuera.Count -gt 0) {
  Write-Output ('  Alias fuera de alcance: ' +
    ($referenciasAliasFuera -join ', '))
}
if ($dependenciasAntiguasFuera.Count -gt 0) {
  Write-Output ('  Dependencias antiguas: ' +
    ($dependenciasAntiguasFuera -join ', '))
}
if ($fallos.Count -gt 0) {
  Write-Output ''
  Write-Output "RESULTADO ESTRUCTURAL: $($fallos.Count) FALLO(S)"
  exit 1
}
Write-Output ''
Write-Output 'RESULTADO ESTRUCTURAL: CORRECTO'
exit 0
