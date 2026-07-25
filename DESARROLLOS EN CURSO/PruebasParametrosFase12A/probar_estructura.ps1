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
$contrato = Leer 'src\Lib\inLibParametrosIntf.pas'
$motor = Leer 'src\Lib\inLibParametrosBase.pas'
$app = Leer 'src\Lib\inLibAppParam.pas'
$caja = Leer 'src\Caja\Lib\inLibCajaParam.pas'
$editorApp = Leer 'src\Core\inMtoAppParam.pas'
$editorCaja = Leer 'src\Caja\Forms\inMtoCajaParam.pas'
$principal = Leer 'src\Core\inMtoPrincipal.pas'
$formBase = Leer 'src\Core\inMtoFrmBase.pas'
$dmBase = Leer 'src\DataModules\UniDataGen.pas'
$log = Leer 'src\Lib\inLibLog.pas'
$proyectoDpr = Leer 'fzam.dpr'
$proyectoDproj = Leer 'fzam.dproj'
$archivosSrc = @(
  Get-ChildItem -LiteralPath (Join-Path $RaizRepositorio 'src') `
    -Recurse -File -Filter '*.pas'
)
$codigoSrc = ($archivosSrc | ForEach-Object {
  Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
}) -join "`n"
Comprobar (
  $contrato -notmatch '\bUni(?:DAC)?\b'
) 'el contrato puro no depende de UniDAC'
Comprobar (
  ([regex]::Matches($contrato, "\['\{[0-9A-F-]{36}\}'\]")).Count -eq 6
) 'las seis interfaces declaran GUID'
Comprobar (
  $contrato -notmatch '\binLib(?!ParametrosIntf)\w+'
) 'el contrato puro no depende de otras unidades del proyecto'
Comprobar (
  $motor -match '\bTCriticalSection\b'
) 'el motor protege la instantánea con TCriticalSection'
Comprobar (
  $motor -match '\bIPerfilesUsuario\b'
) 'el motor usa IPerfilesUsuario'
Comprobar (
  $motor -notmatch '\bTUni(Query|Connection)\b'
) 'el motor no contiene componentes UniDAC'
Comprobar (
  $codigoSrc -notmatch '\b(TParamDef|TAppParamDef)\b'
) 'no quedan las clases de definición duplicadas'
Comprobar (
  $codigoSrc -notmatch '\bo(App|Caja)Params\.Params\b'
) 'no queda acceso al diccionario mediante los globales'
Comprobar (
  $codigoSrc -notmatch (
    '\bo(App|Caja)Params\.' +
    '(AsignarConexion|InicializarParametros\w+|Recargar)\b'
  )
) 'los alias no exponen ciclo de vida ni edición'
Comprobar (
  ($editorApp + $editorCaja) -notmatch '\bTObjectDictionary\b'
) 'los editores no conocen TObjectDictionary'
Comprobar (
  ($editorApp + $editorCaja) -match '\bListarDefiniciones\b'
) 'los editores consumen instantáneas de edición'
Comprobar (
  $log -notmatch '\binLibAppParam\b'
) 'inLibLog ya no depende de inLibAppParam'
Comprobar (
  $log -match 'AplicarModosDepuracion\(\s*' +
    'const AParametros: IParametrosAplicacion'
) 'el log recibe IParametrosAplicacion'
Comprobar (
  $app -notmatch '(?im)^\s*initialization\s*$'
) 'los parámetros de aplicación no nacen en initialization'
Comprobar (
  $caja -notmatch '(?im)^\s*initialization\s*$'
) 'los parámetros de caja no nacen en initialization'
Comprobar (
  $app -match 'oAppParams:\s*IParametrosAplicacion'
) 'el alias global App es una interfaz'
Comprobar (
  $caja -match 'oCajaParams:\s*IParametrosCaja'
) 'el alias global Caja es una interfaz'
Comprobar (
  ([regex]::Matches(
    $app,
    "(?s)RegistrarParametro\s*\(\s*'[^']*'\s*,\s*'[^']+'"
  )).Count -eq 49
) 'el catálogo App conserva 49 claves'
Comprobar (
  ([regex]::Matches(
    $caja,
    "(?s)RegistrarParametro\s*\(\s*'[^']*'\s*,\s*'[^']+'"
  )).Count -eq 30
) 'el catálogo Caja conserva 30 claves'
Comprobar (
  ($formBase + $dmBase) -match '\bIProveedorParametros\b'
) 'las clases base propagan los parámetros de lectura'
$posicionPerfiles = $principal.IndexOf(
  'FdmDataPerfiles := TdmPerfiles.Create(Self)'
)
$posicionParametros = $principal.IndexOf(
  'ParametrosAppCreados := CrearParametrosAplicacion'
)
Comprobar (
  ($posicionPerfiles -ge 0) -and
  ($posicionParametros -gt $posicionPerfiles)
) 'la raíz crea parámetros después de TdmPerfiles'
$posicionLiberarParametros = $principal.IndexOf('oAppParams := nil')
$posicionLiberarPerfiles = $principal.IndexOf(
  'FreeAndNil(FdmDataPerfiles)'
)
Comprobar (
  ($posicionLiberarParametros -ge 0) -and
  ($posicionLiberarPerfiles -gt $posicionLiberarParametros)
) 'la raíz libera parámetros antes de TdmPerfiles'
foreach ($unidad in @('inLibParametrosIntf', 'inLibParametrosBase')) {
  Comprobar (
    $proyectoDpr -match "\b$unidad\b"
  ) "$unidad está registrada en fzam.dpr"
  Comprobar (
    $proyectoDproj -match "\b$unidad\.pas\b"
  ) "$unidad está registrada en fzam.dproj"
}
if ($fallos.Count -gt 0) {
  Write-Output ''
  Write-Output "TOTAL FALLOS: $($fallos.Count)"
  exit 1
}
Write-Output ''
Write-Output 'RESULTADO ESTRUCTURAL: CORRECTO'
exit 0
