# Compila fzam.dproj en las tres configuraciones habituales dirigiendo la
# salida a una carpeta temporal aislada, para no tocar los ejecutables que el
# usuario pueda tener abiertos. Deja el resultado en resultado_compilacion.txt.
$ErrorActionPreference = 'Continue'
$carpeta = $PSScriptRoot
$raiz = (Resolve-Path (Join-Path $carpeta '..\..')).Path
$proyecto = Join-Path $raiz 'fzam.dproj'
$log = Join-Path $carpeta 'resultado_compilacion.txt'
$temporal = Join-Path $env:TEMP ('fzam_fase11a_' + $PID)
$lineas = New-Object System.Collections.Generic.List[string]
function Anota($t) { $lineas.Add($t) }

Anota ('Compilacion Fase XI-A - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Anota ('Proyecto: ' + $proyecto)
Anota ('Salida temporal: ' + $temporal)
Anota ''

# --- localizar rsvars.bat ---
$candidatos = @()
foreach ($base in @(
    "${env:ProgramFiles(x86)}\Embarcadero\Studio",
    "$env:ProgramFiles\Embarcadero\Studio")) {
  if (Test-Path -LiteralPath $base) {
    $candidatos += Get-ChildItem -LiteralPath $base -Directory |
      ForEach-Object { Join-Path $_.FullName 'bin\rsvars.bat' } |
      Where-Object { Test-Path -LiteralPath $_ }
  }
}
Anota 'rsvars.bat encontrados:'
foreach ($c in $candidatos) { Anota ('  ' + $c) }
if ($candidatos.Count -eq 0) {
  Anota 'NO HAY CADENA DE HERRAMIENTAS DELPHI LOCALIZABLE'
  Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
  exit 1
}
$rsvars = $candidatos | Sort-Object {
  [double]((Split-Path (Split-Path $_ -Parent) -Leaf))
} -Descending | Select-Object -First 1
Anota ('Elegido: ' + $rsvars)
Anota ''

New-Item -ItemType Directory -Force -Path $temporal | Out-Null
$matriz = @(
  @{ Config = 'Debug';   Plataforma = 'Win64' },
  @{ Config = 'Release'; Plataforma = 'Win32' },
  @{ Config = 'Release'; Plataforma = 'Win64' }
)
$resumen = New-Object System.Collections.Generic.List[string]
foreach ($m in $matriz) {
  $etiqueta = $m.Config + ' ' + $m.Plataforma
  $salidaCfg = Join-Path $temporal ($m.Config + '_' + $m.Plataforma)
  New-Item -ItemType Directory -Force -Path $salidaCfg | Out-Null
  Anota '=================================================='
  Anota ('### ' + $etiqueta)
  $orden = 'call "' + $rsvars + '" && msbuild "' + $proyecto +
    '" /t:Build /p:Config=' + $m.Config + ' /p:Platform=' + $m.Plataforma +
    ' /p:DCC_ExeOutput="' + $salidaCfg + '"' +
    ' /p:DCC_DcuOutput="' + $salidaCfg + '\dcu"' +
    ' /nologo /verbosity:minimal'
  $salida = & cmd.exe /c $orden 2>&1
  $codigo = $LASTEXITCODE
  foreach ($l in $salida) { Anota ('  ' + $l) }
  $errores = @($salida | Select-String -Pattern '\bError\b|\bE\d{4}\b|\bF\d{4}\b')
  $estado = if ($codigo -eq 0) { 'CORRECTA' } else { 'FALLO' }
  $resumen.Add(('{0,-16} {1,-9} salida={2} lineas-con-error={3}' -f
    $etiqueta, $estado, $codigo, $errores.Count))
  Anota ''
}
Anota '=================================================='
Anota 'RESUMEN'
foreach ($l in $resumen) { Anota $l }
Remove-Item -LiteralPath $temporal -Recurse -Force -ErrorAction SilentlyContinue
Anota ''
Anota 'Artefactos temporales eliminados.'
Anota 'FIN'
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8
