param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoConsultasUi = 173,
  [switch]$MostrarTodos
)

# El punto de partida era 189 construcciones directas de TUniQuery en UI.
# Las extracciones de P1 dejan el máximo en 173. Este tope es un trinquete:
# puede bajarse cuando se extraigan consultas, pero nunca debe incrementarse.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rutasRelativas = @(
  'src\Core',
  'src\Forms',
  'src\Modals',
  'src\Caja\Forms',
  'src\Caja\Modals'
)
$patron = '(?i)\bTUniQuery\s*\.\s*Create\s*\('
$apariciones = [System.Collections.Generic.List[object]]::new()
foreach ($rutaRelativa in $rutasRelativas) {
  $ruta = Join-Path $Raiz $rutaRelativa
  if (Test-Path -LiteralPath $ruta -PathType Container) {
    foreach ($archivo in Get-ChildItem -LiteralPath $ruta `
      -Recurse -Filter '*.pas' -File) {
      $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
      foreach ($coincidencia in [regex]::Matches($contenido, $patron)) {
        $linea = (
          [regex]::Matches(
            $contenido.Substring(0, $coincidencia.Index),
            "`n")
        ).Count + 1
        $apariciones.Add([pscustomobject]@{
          Ruta = [System.IO.Path]::GetRelativePath(
            $Raiz,
            $archivo.FullName)
          Linea = $linea
        })
      }
    }
  }
}

if ($MostrarTodos) {
  Write-Output 'Construcciones directas de TUniQuery en UI:'
  Write-Output (
    $apariciones |
      Sort-Object Ruta, Linea |
      Format-Table Ruta, Linea -AutoSize |
      Out-String
  ).TrimEnd()
}

if ($apariciones.Count -gt $MaximoConsultasUi) {
  Write-Error (
    'Construcciones TUniQuery.Create en UI: ' +
    "$($apariciones.Count); máximo permitido: $MaximoConsultasUi.")
  exit 1
}

Write-Output (
  'Consultas UI: OK. TUniQuery.Create: ' +
  "$($apariciones.Count); máximo permitido: $MaximoConsultasUi.")
