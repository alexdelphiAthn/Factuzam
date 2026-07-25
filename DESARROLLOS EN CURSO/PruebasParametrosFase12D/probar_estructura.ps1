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
$archivosPas = Get-ChildItem -LiteralPath (
  Join-Path $RaizRepositorio 'src'
) -Recurse -File -Filter '*.pas'
$referenciasAlias = @(
  foreach ($archivo in $archivosPas) {
    $contenido = Get-Content -LiteralPath $archivo.FullName -Raw -Encoding UTF8
    if ($contenido -match '\b(?:oAppParams|oCajaParams)\b') {
      [System.IO.Path]::GetRelativePath(
        $RaizRepositorio,
        $archivo.FullName
      )
    }
  }
)
$permitidosImplementacion = @(
  'src\Core\inMtoPrincipal.pas'
  'src\Lib\inLibAppParam.pas'
  'src\Caja\Lib\inLibCajaParam.pas'
)
$dependenciasImplementacionFuera = @(
  foreach ($archivo in $archivosPas) {
    $relativa = [System.IO.Path]::GetRelativePath(
      $RaizRepositorio,
      $archivo.FullName
    )
    if ($permitidosImplementacion -notcontains $relativa) {
      $contenido = Get-Content -LiteralPath $archivo.FullName -Raw -Encoding UTF8
      if ($contenido -match '\binLib(?:App|Caja)Param\b') {
        $relativa
      }
    }
  }
)
$app = Leer 'src\Lib\inLibAppParam.pas'
$caja = Leer 'src\Caja\Lib\inLibCajaParam.pas'
$principal = Leer 'src\Core\inMtoPrincipal.pas'
$estilo = Leer 'LIBRO_DE_ESTILO_DELPHI.md'
$proyectoDpr = Leer 'fzam.dpr'
$proyectoDproj = Leer 'fzam.dproj'
Comprobar (
  $referenciasAlias.Count -eq 0
) 'no existen variables globales oAppParams ni oCajaParams'
Comprobar (
  $app -notmatch '\bdeprecated\b'
) 'inLibAppParam no conserva declaraciones de transición'
Comprobar (
  $caja -notmatch '\bdeprecated\b'
) 'inLibCajaParam no conserva declaraciones de transición'
Comprobar (
  $caja -notmatch (
    '(?m)^function\s+(?:TarifaDefecto|NivelesFamiliaArqueo)\b'
  )
) 'no quedan funciones libres de parámetros de caja'
Comprobar (
  $dependenciasImplementacionFuera.Count -eq 0
) 'ningún consumidor depende de las unidades de implementación'
Comprobar (
  ($principal -match '\bCrearParametrosAplicacion\(') -and
  ($principal -match '\bCrearParametrosCaja\(') -and
  ($principal -match '\bAsignarParametros\(\s*' +
    'ParametrosAppCreados,\s*ParametrosCajaCreados\)')
) 'la raíz crea y conserva los servicios mediante interfaces'
Comprobar (
  ($principal -match '\bParametrosApp\.GetBool\(') -and
  ($principal -match '\bParametrosApp\.GetPath\(') -and
  ($principal -match '\bParametrosApp\.GetString\(')
) 'la raíz consume su propiedad ParametrosApp'
$posicionLiberarParametros = $principal.IndexOf(
  'AsignarParametros(nil, nil)'
)
$posicionLiberarPerfiles = $principal.IndexOf(
  'FreeAndNil(FdmDataPerfiles)'
)
Comprobar (
  ($posicionLiberarParametros -ge 0) -and
  ($posicionLiberarPerfiles -gt $posicionLiberarParametros)
) 'los parámetros se liberan antes que el servicio de perfiles'
Comprobar (
  ($estilo -match '\bIProveedorParametros\b') -and
  ($estilo -match '\bIParametrosAplicacion\b') -and
  ($estilo -match '\bIParametrosCaja\b')
) 'el libro de estilo documenta el patrón de parámetros'
Comprobar (
  ($proyectoDpr -match '\binLibAppParam\b') -and
  ($proyectoDpr -match '\binLibCajaParam\b') -and
  ($proyectoDproj -match '\binLibAppParam\.pas\b') -and
  ($proyectoDproj -match '\binLibCajaParam\.pas\b')
) 'las implementaciones continúan registradas en el proyecto'
& git -C $RaizRepositorio diff --quiet -- factuzam_original.sql
Comprobar (
  $LASTEXITCODE -eq 0
) 'factuzam_original.sql permanece intacto'
if ($referenciasAlias.Count -gt 0) {
  Write-Output ('  Alias encontrados: ' + ($referenciasAlias -join ', '))
}
if ($dependenciasImplementacionFuera.Count -gt 0) {
  Write-Output ('  Dependencias fuera de la raíz: ' +
    ($dependenciasImplementacionFuera -join ', '))
}
if ($fallos.Count -gt 0) {
  Write-Output ''
  Write-Output "RESULTADO ESTRUCTURAL: $($fallos.Count) FALLO(S)"
  exit 1
}
Write-Output ''
Write-Output 'RESULTADO ESTRUCTURAL: CORRECTO'
exit 0
