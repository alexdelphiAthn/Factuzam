param(
  [string]$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [int]$MaximoMiembros = 10
)
$ErrorActionPreference = 'Stop'
$nombresRetirados = @(
  'ILineasDocumentoTallas',
  'IPersistenciaModoTallas',
  'IRepositorioTicketsCaja',
  'ILecturasMaterializacionComprasSesiones',
  'IRepositorioFotos',
  'IRepositorioGridPivoteCompra',
  'IRepositorioPivoteVenta',
  'IDBHelpers',
  'IDBMetadataProvider'
)
# El resguardo examina todas las unidades activas de primera parte, no
# solo los *Intf.pas: una interfaz ancha o un contrato retirado tampoco
# pueden esconderse en el resto de unidades del arbol propio.
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
$rutaSrc = Join-Path $Raiz 'src'
$archivos = @(
  Get-ChildItem -Path $rutaSrc -Recurse -Filter '*.pas' -File |
    Where-Object {
      $ruta = $_.FullName
      -not ($exclusiones | Where-Object { $ruta.Contains($_) })
    }
)
$interfacesAmplias = [System.Collections.Generic.List[object]]::new()
$referenciasRetiradas = [System.Collections.Generic.List[string]]::new()
$patronInterfaz =
  '(?ms)^\s*(?<nombre>I[A-Za-z0-9_]+)\s*=\s*' +
  'interface(?:\([^\)]*\))?\s*' +
  '(?:\[''\{[^\]]+\]\]\s*)?' +
  '(?<cuerpo>.*?)(?=^\s*end;)'
$patronMiembro =
  '(?im)^\s*(?:class\s+)?(?:procedure|function)\b'
foreach ($archivo in $archivos) {
  $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
  if ([string]::IsNullOrEmpty($contenido)) {
    continue
  }
  foreach ($coincidencia in [regex]::Matches(
    $contenido, $patronInterfaz)) {
    $miembros = [regex]::Matches(
      $coincidencia.Groups['cuerpo'].Value,
      $patronMiembro).Count
    if ($miembros -gt $MaximoMiembros) {
      $interfacesAmplias.Add([pscustomobject]@{
        Archivo = $archivo.FullName.Substring($Raiz.Length + 1)
        Interfaz = $coincidencia.Groups['nombre'].Value
        Miembros = $miembros
      })
    }
  }
  foreach ($nombre in $nombresRetirados) {
    if ($contenido -match "\b$([regex]::Escape($nombre))\b") {
      $referenciasRetiradas.Add(
        "$($archivo.FullName.Substring($Raiz.Length + 1)): $nombre")
    }
  }
}
if ($interfacesAmplias.Count -gt 0) {
  $detalle = $interfacesAmplias |
    ForEach-Object {
      "$($_.Archivo): $($_.Interfaz) tiene $($_.Miembros) miembros"
    }
  throw "Hay interfaces con mas de $MaximoMiembros miembros:`n" +
    ($detalle -join "`n")
}
if ($referenciasRetiradas.Count -gt 0) {
  throw "Han reaparecido contratos retirados:`n" +
    ($referenciasRetiradas -join "`n")
}
Write-Output (
  'Interfaces segregadas: OK. Unidades analizadas: ' +
  "$($archivos.Count); maximo permitido: $MaximoMiembros " +
  "miembros; contratos retirados: $($nombresRetirados.Count).")
