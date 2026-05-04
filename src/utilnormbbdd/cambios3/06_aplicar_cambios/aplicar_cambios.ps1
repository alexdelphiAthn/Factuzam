<#
  aplicar_cambios.ps1
  Aplica los renombrados de columnas definidos en aplicar_cambios.csv
  a los ficheros .pas y .dfm de una carpeta (recursivo).
  Generado por Factuzam Normalizer.
  Reglas:
   - Reemplazo CASE-SENSITIVE.
   - Solo "palabra completa" (boundary regex \b en clase [A-Za-z0-9_]).
   - Procesa nombres mas largos primero.
   - Crea .bak antes de modificar (si no existe).
  Uso:
    .\aplicar_cambios.ps1 -Carpeta 'C:\ruta\proyecto'
    .\aplicar_cambios.ps1 -Carpeta '...' -DryRun
#>
param(
    [Parameter(Mandatory=$true)] [string] $Carpeta,
    [string] $Csv = (Join-Path $PSScriptRoot 'aplicar_cambios.csv'),
    [string[]] $Extensiones = @('.pas', '.dfm'),
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# --- Validaciones ----------------------------------------------------------
if (-not (Test-Path -LiteralPath $Carpeta -PathType Container)) {
    Write-Error "La carpeta indicada no existe: $Carpeta"
    exit 1
}
if (-not (Test-Path -LiteralPath $Csv -PathType Leaf)) {
    Write-Error "No encuentro el CSV de pares: $Csv"
    exit 1
}

# --- Cargar CSV de pares ---------------------------------------------------
$pares = Import-Csv -LiteralPath $Csv -Delimiter ';' -Encoding UTF8
if (-not $pares -or $pares.Count -eq 0) {
    Write-Error "El CSV no contiene pares de renombrado: $Csv"
    exit 1
}
# Filtrar pares vacios o no cambiantes, y deduplicar por OldName
$seen = @{}
$pairs = @()
foreach ($p in $pares) {
    if (-not $p.OldName -or -not $p.NewName) { continue }
    if ($p.OldName -eq $p.NewName)            { continue }
    if ($seen.ContainsKey($p.OldName))         { continue }
    $seen[$p.OldName] = $true
    $pairs += [pscustomobject]@{ Old = $p.OldName; New = $p.NewName }
}
# Orden: nombres mas largos primero (para no romper compuestos)
$pairs = $pairs | Sort-Object @{Expression={$_.Old.Length}; Descending=$true}, Old
Write-Host ("Pares de renombrado a aplicar: {0}" -f $pairs.Count)

# --- Recolectar ficheros ---------------------------------------------------
$archivos = @()
foreach ($ext in $Extensiones) {
    $archivos += Get-ChildItem -LiteralPath $Carpeta -Recurse -File `
                 -Filter ("*" + $ext) -ErrorAction SilentlyContinue
}
# Deduplicar por ruta
$archivos = $archivos | Sort-Object FullName -Unique
Write-Host ("Ficheros a revisar: {0}" -f $archivos.Count)

# --- Helper: detectar codificacion sin BOM (heuristica) --------------------
function Get-FileEncoding {
    param([string] $Path)
    $bytes = [byte[]](Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 4 -TotalCount 4)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return 'utf-8-bom'
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { return 'utf-16le' }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { return 'utf-16be' }
    # Sin BOM: tratar como ANSI Windows-1252 (por defecto en .pas/.dfm antiguos).
    return 'ansi'
}

# --- Helper: leer contenido respetando codificacion -----------------------
function Read-Text {
    param([string] $Path, [string] $Enc)
    switch ($Enc) {
        'utf-8-bom' { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
        'utf-16le'  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::Unicode) }
        'utf-16be'  { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::BigEndianUnicode) }
        default      { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding(1252)) }
    }
}

# --- Helper: escribir contenido respetando codificacion -------------------
function Write-Text {
    param([string] $Path, [string] $Content, [string] $Enc)
    switch ($Enc) {
        'utf-8-bom' { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($true)) }
        'utf-16le'  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::Unicode) }
        'utf-16be'  { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::BigEndianUnicode) }
        default      { [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::GetEncoding(1252)) }
    }
}

# --- Bucle principal -------------------------------------------------------
$totalFicherosTocados = 0
$totalReemplazos      = 0
$detalle              = @()

foreach ($f in $archivos) {
    try {
        $enc = Get-FileEncoding -Path $f.FullName
        $original = Read-Text -Path $f.FullName -Enc $enc
        $modificado = $original
        $reempEnFichero = 0

        foreach ($par in $pairs) {
            $patron = '(?<![A-Za-z0-9_])' + [regex]::Escape($par.Old) + '(?![A-Za-z0-9_])'
            $matches = [regex]::Matches($modificado, $patron)
            if ($matches.Count -gt 0) {
                $reempEnFichero += $matches.Count
                $modificado = [regex]::Replace($modificado, $patron, $par.New)
            }
        }

        if ($modificado -ne $original) {
            if ($DryRun) {
                Write-Host ("[DRY] {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)
            } else {
                $bak = "$($f.FullName).bak"
                if (-not (Test-Path -LiteralPath $bak)) {
                    Copy-Item -LiteralPath $f.FullName -Destination $bak -ErrorAction Stop
                }
                Write-Text -Path $f.FullName -Content $modificado -Enc $enc
                Write-Host ("OK   {0,4} reemplazos -> {1}" -f $reempEnFichero, $f.FullName)
            }
            $totalFicherosTocados++
            $totalReemplazos += $reempEnFichero
            $detalle += [pscustomobject]@{
                Archivo     = $f.FullName
                Reemplazos  = $reempEnFichero
                Codificacion= $enc
            }
        }
    } catch {
        Write-Warning ("Error procesando {0}: {1}" -f $f.FullName, $_.Exception.Message)
    }
}

# --- Resumen ----------------------------------------------------------------
Write-Host ""
if ($DryRun) {
    Write-Host ("=== DRY RUN: {0} ficheros cambiarian, {1} reemplazos en total ===" -f $totalFicherosTocados, $totalReemplazos)
} else {
    Write-Host ("=== Listo: {0} ficheros modificados, {1} reemplazos aplicados ===" -f $totalFicherosTocados, $totalReemplazos)
}

# Volcar log csv junto al script
if ($detalle.Count -gt 0) {
    $logCsv = Join-Path $PSScriptRoot ("aplicar_cambios_log_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".csv")
    $detalle | Export-Csv -LiteralPath $logCsv -Delimiter ';' -Encoding UTF8 -NoTypeInformation
    Write-Host ("Detalle: {0}" -f $logCsv)
}
