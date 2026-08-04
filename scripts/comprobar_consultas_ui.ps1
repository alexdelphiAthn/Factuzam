param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoConsultasUi = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoComponentesUniDacDfm = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoAsignacionesSqlText = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoLlamadasSqlAdd = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoAsignacionesCommandText = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoTransaccionesCreadas = 0,
  [ValidateRange(0, [int]::MaxValue)]
  [int]$MaximoProcedimientosCreados = 0,
  [switch]$MostrarTodos
)

# Congela las formas de acceso directo a datos que todavía viven en UI.
# Cada máximo solo puede bajar cuando la consulta se extrae de la pantalla.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rutasRelativas = @(
  'src\Core',
  'src\Forms',
  'src\Modals',
  'src\Caja\Forms',
  'src\Caja\Modals'
)
$definiciones = @(
  [pscustomobject]@{
    Nombre = 'TUniQuery.Create'
    Extensiones = @('*.pas')
    Patron = '(?i)\bTUniQuery\s*\.\s*Create\s*\('
    Maximo = $MaximoConsultasUi
  },
  [pscustomobject]@{
    Nombre = 'Componentes UniDAC en DFM'
    Extensiones = @('*.dfm')
    Patron = '(?im)^\s*(?:object|inherited|inline)\s+' +
      '\w+\s*:\s*TUni\w+\s*$'
    Maximo = $MaximoComponentesUniDacDfm
  },
  [pscustomobject]@{
    Nombre = 'SQL.Text :='
    Extensiones = @('*.pas')
    Patron = '(?i)\bSQL\s*\.\s*Text\s*:='
    Maximo = $MaximoAsignacionesSqlText
  },
  [pscustomobject]@{
    Nombre = 'SQL.Add'
    Extensiones = @('*.pas')
    Patron = '(?i)\bSQL\s*\.\s*Add\s*\('
    Maximo = $MaximoLlamadasSqlAdd
  },
  [pscustomobject]@{
    Nombre = 'CommandText'
    Extensiones = @('*.pas', '*.dfm')
    Patron = '(?i)\bCommandText\s*(?::=|=)'
    Maximo = $MaximoAsignacionesCommandText
  },
  [pscustomobject]@{
    Nombre = 'Transacciones creadas/iniciadas'
    Extensiones = @('*.pas')
    Patron = '(?im)^(?!\s*//)[^\r\n]*(?:' +
      '\bTUniTransaction\s*\.\s*Create\s*\(' +
      '|\.\s*StartTransaction\b)'
    Maximo = $MaximoTransaccionesCreadas
  },
  [pscustomobject]@{
    Nombre = 'TUniStoredProc.Create'
    Extensiones = @('*.pas')
    Patron = '(?i)\bTUniStoredProc\s*\.\s*Create\s*\('
    Maximo = $MaximoProcedimientosCreados
  }
)
$apariciones = [System.Collections.Generic.List[object]]::new()
foreach ($definicion in $definiciones) {
  foreach ($rutaRelativa in $rutasRelativas) {
    $ruta = Join-Path $Raiz $rutaRelativa
    if (Test-Path -LiteralPath $ruta -PathType Container) {
      foreach ($extension in $definicion.Extensiones) {
        $archivos = Get-ChildItem -LiteralPath $ruta `
          -Recurse -Filter $extension -File
        foreach ($archivo in $archivos) {
          $contenido = Get-Content -LiteralPath $archivo.FullName -Raw
          $coincidencias = [regex]::Matches(
            $contenido,
            $definicion.Patron)
          foreach ($coincidencia in $coincidencias) {
            $linea = (
              [regex]::Matches(
                $contenido.Substring(0, $coincidencia.Index),
                "`n")
            ).Count + 1
            $apariciones.Add([pscustomobject]@{
              Categoria = $definicion.Nombre
              Ruta = [System.IO.Path]::GetRelativePath(
                $Raiz,
                $archivo.FullName)
              Linea = $linea
            })
          }
        }
      }
    }
  }
}

if ($MostrarTodos) {
  Write-Output 'Accesos directos a datos encontrados en UI:'
  Write-Output (
    $apariciones |
      Sort-Object Categoria, Ruta, Linea |
      Format-Table Categoria, Ruta, Linea -AutoSize |
      Out-String
  ).TrimEnd()
}

$fallos = [System.Collections.Generic.List[string]]::new()
$resumen = [System.Collections.Generic.List[string]]::new()
foreach ($definicion in $definiciones) {
  $total = @(
    $apariciones |
      Where-Object { $_.Categoria -eq $definicion.Nombre }
  ).Count
  $detalle = (
    "$($definicion.Nombre): $total; máximo permitido: " +
    "$($definicion.Maximo).")
  $resumen.Add($detalle)
  if ($total -gt $definicion.Maximo) {
    $fallos.Add($detalle)
  }
}

if ($fallos.Count -gt 0) {
  Write-Output 'Accesos directos a datos en UI fuera de tope:'
  $fallos | ForEach-Object { Write-Output "  $_" }
  exit 1
}

Write-Output 'Consultas UI: OK.'
$resumen | ForEach-Object { Write-Output "  $_" }
