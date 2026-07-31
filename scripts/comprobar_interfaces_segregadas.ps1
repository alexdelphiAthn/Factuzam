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
  'IRepositorioPivoteVenta'
)
$rutaSrc = Join-Path $Raiz 'src'
$interfacesAmplias = [System.Collections.Generic.List[object]]::new()
$referenciasRetiradas = [System.Collections.Generic.List[string]]::new()
$patronInterfaz =
  '(?ms)^\s*(?<nombre>I[A-Za-z0-9_]+)\s*=\s*' +
  'interface(?:\([^\)]*\))?\s*' +
  '(?:\[''\{[^\]]+\]\]\s*)?' +
  '(?<cuerpo>.*?)(?=^\s*end;)'
$patronMiembro =
  '(?im)^\s*(?:class\s+)?(?:procedure|function)\b'
Get-ChildItem -Path $rutaSrc -Recurse -Filter '*Intf.pas' |
  ForEach-Object {
    $contenido = Get-Content -LiteralPath $_.FullName -Raw
    foreach ($coincidencia in [regex]::Matches(
      $contenido, $patronInterfaz)) {
      $miembros = [regex]::Matches(
        $coincidencia.Groups['cuerpo'].Value,
        $patronMiembro).Count
      if ($miembros -gt $MaximoMiembros) {
        $interfacesAmplias.Add([pscustomobject]@{
          Archivo = $_.FullName.Substring($Raiz.Length + 1)
          Interfaz = $coincidencia.Groups['nombre'].Value
          Miembros = $miembros
        })
      }
    }
    foreach ($nombre in $nombresRetirados) {
      if ($contenido -match "\b$([regex]::Escape($nombre))\b") {
        $referenciasRetiradas.Add(
          "$($_.FullName.Substring($Raiz.Length + 1)): $nombre")
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
  'Interfaces segregadas: OK. Maximo permitido: ' +
  "$MaximoMiembros miembros; contratos retirados: " +
  "$($nombresRetirados.Count).")
