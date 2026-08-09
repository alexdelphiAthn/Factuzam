param(
  [string]$Servidor = '127.0.0.1',
  [int]$Puerto = 3306,
  [string]$Usuario = 'root',
  [string]$Cliente = 'C:\Program Files\MariaDB 12.3\bin\mariadb.exe'
)

$ErrorActionPreference = 'Stop'
$raizProyecto = Split-Path -Parent $PSScriptRoot
$rutaSql = Join-Path $raizProyecto 'sql\001_alexcontazam.sql'
$claveSegura = Read-Host 'Contraseña MariaDB' -AsSecureString
$puntero = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
  $claveSegura
)

try {
  $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
    $puntero
  )
  foreach ($baseDatos in @('alexcontazam', 'contazam')) {
    $sql = (Get-Content -LiteralPath $rutaSql -Raw).Replace(
      'alexcontazam',
      $baseDatos
    )
    $sql | & $Cliente `
      --host=$Servidor `
      --port=$Puerto `
      --user=$Usuario `
      --ssl=0 `
      --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) {
      throw "No se pudo preparar la base $baseDatos."
    }
    Write-Host "Base $baseDatos preparada."
  }
}
finally {
  Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($puntero)
}
