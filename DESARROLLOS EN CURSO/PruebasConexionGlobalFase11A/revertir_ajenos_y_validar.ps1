# 1) retira el index.lock huerfano que dejo un git interrumpido;
# 2) devuelve a su estado original los ficheros ajenos al alcance de XI-A;
# 3) vuelve a lanzar las pruebas estructurales y la compilacion.
$ErrorActionPreference = 'Continue'
$carpeta = $PSScriptRoot
$raiz = (Resolve-Path (Join-Path $carpeta '..\..')).Path
$log = Join-Path $carpeta 'resultado_reversion.txt'
$lineas = New-Object System.Collections.Generic.List[string]
function Anota($t) { $lineas.Add($t) }

Anota ('Reversion de ficheros ajenos - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$lock = Join-Path $raiz '.git\index.lock'
if (Test-Path -LiteralPath $lock) {
  Remove-Item -LiteralPath $lock -Force
  Anota 'index.lock huerfano eliminado.'
} else {
  Anota 'No habia index.lock.'
}

$ajenos = @(
  'src/3rdpartyComp/SynEdit/Source/SynEditReg.pas',
  'src/3rdpartyComp/SynEdit/Source/SynTextDrawer.pas',
  'src/3rdpartyComp/SynEdit/Source/SynAutoCorrect.pas',
  'src/3rdpartyComp/DCPCrypt-master/DCPblockciphers.pas',
  'src/3rdpartyComp/SQLBuilder4Delphi/unittest/SQLBuilder4D.Parser.UnitTest.pas',
  'src/Lib/inLibDir.pas',
  'src/Lib/inLibMsg.pas',
  'src/otras pruebas/parametros VerticalGrid/Unit1.pas'
)
Anota ''
Anota 'Devolviendo a su estado original:'
foreach ($f in $ajenos) {
  $salida = & git -C $raiz checkout -- $f 2>&1
  Anota ('  ' + $f + '  -> ' + ($(if ($LASTEXITCODE -eq 0) { 'OK' } else { 'ERROR' })))
  foreach ($l in $salida) { if ($l -notmatch 'LF will be replaced') { Anota ('     ' + $l) } }
}

Anota ''
Anota 'Ficheros modificados que quedan:'
$modificados = @(& git -C $raiz diff --name-only 2>&1 |
  Where-Object { $_ -notmatch 'LF will be replaced' -and
                 $_ -notmatch 'original line endings' })
Anota ('  total: ' + $modificados.Count)
foreach ($m in $modificados) { Anota ('  ' + $m) }
Set-Content -LiteralPath $log -Value $lineas -Encoding UTF8

# 4) relanzar pruebas y compilacion
& powershell -NoProfile -ExecutionPolicy Bypass -File `
  (Join-Path $carpeta 'ejecutar_pruebas.ps1')
& powershell -NoProfile -ExecutionPolicy Bypass -File `
  (Join-Path $carpeta 'ejecutar_compilacion.ps1')
Add-Content -LiteralPath $log -Value 'Pruebas y compilacion relanzadas. FIN'
