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
$carpetasRelativas = @(
  'src\Forms'
  'src\Modals'
  'src\DataModules'
  'src\Caja\Forms'
  'src\Caja\Modals'
  'src\Caja\DataModules'
)
$archivos = @(
  foreach ($carpetaRelativa in $carpetasRelativas) {
    Get-ChildItem -LiteralPath (
      Join-Path $RaizRepositorio $carpetaRelativa
    ) -Recurse -File -Filter '*.pas'
  }
) | Where-Object {
  $_.Name -ne 'UniDataConn.pas'
}
$codigo = ($archivos | ForEach-Object {
  Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
}) -join "`n"
$dataCaja = Leer 'src\Caja\DataModules\UniDataCaja.pas'
$llamantesCaja = (
  (Leer 'src\Caja\Forms\inMtoCajaOpe.pas') +
  (Leer 'src\Caja\Modals\inMtoModalGastoCaja.pas') +
  (Leer 'src\Modals\inMtoModalEntradaCambio.pas')
)
Comprobar (
  $codigo -notmatch '\bo(?:App|Caja)Params\b'
) 'no quedan accesos a los alias globales en el alcance XII-B'
Comprobar (
  $codigo -notmatch '\binLib(?:App|Caja)Param\b'
) 'no quedan dependencias de las unidades antiguas en el alcance XII-B'
Comprobar (
  $codigo -notmatch (
    '(?<!\.)\b(?:TarifaDefecto|NivelesFamiliaArqueo)\b'
  )
) 'no quedan llamadas a las funciones libres en el alcance XII-B'
Comprobar (
  ([regex]::Matches(
    $codigo,
    '\bParametrosApp\.(?:Get\w+|TarifaDefecto|NivelesFamiliaArqueo)\b'
  )).Count -eq 20
) 'se conservan las 20 lecturas de parámetros de aplicación del lote'
Comprobar (
  ([regex]::Matches(
    $codigo,
    '\bParametrosCaja\.(?:Get\w+|TarifaDefecto|NivelesFamiliaArqueo)\b'
  )).Count -eq 40
) 'se conservan las 40 lecturas de parámetros de caja del lote'
Comprobar (
  $dataCaja -match '\bFParametrosCaja:\s*IParametrosCaja;'
) 'TdmCajaOpe conserva IParametrosCaja como dependencia'
Comprobar (
  $dataCaja -match (
    'constructor\s+Create\(\s*AOwner:\s*TComponent;\s*' +
    'AConexion:\s*TUniConnection;\s*' +
    'const\s+AParametrosCaja:\s*IParametrosCaja\)'
  )
) 'el constructor de TdmCajaOpe exige IParametrosCaja'
Comprobar (
  $dataCaja -match '\bFParametrosCaja\s*:=\s*AParametrosCaja;'
) 'TdmCajaOpe guarda la interfaz recibida'
Comprobar (
  $dataCaja -match (
    'function\s+TdmCajaOpe\.GetTarifaDefault:\s*string;\s*' +
    'begin\s*Result\s*:=\s*FParametrosCaja\.TarifaDefecto;'
  )
) 'TdmCajaOpe resuelve la tarifa mediante la interfaz inyectada'
Comprobar (
  ([regex]::Matches(
    $llamantesCaja,
    'TdmCajaOpe\.Create\([^;]+,\s*ParametrosCaja\)'
  )).Count -eq 3
) 'los tres llamantes propagan ParametrosCaja a TdmCajaOpe'
& git -C $RaizRepositorio diff --quiet -- factuzam_original.sql
Comprobar (
  $LASTEXITCODE -eq 0
) 'factuzam_original.sql permanece intacto'
if ($fallos.Count -gt 0) {
  Write-Output ''
  Write-Output "RESULTADO ESTRUCTURAL: $($fallos.Count) FALLO(S)"
  exit 1
}
Write-Output ''
Write-Output 'RESULTADO ESTRUCTURAL: CORRECTO'
exit 0
