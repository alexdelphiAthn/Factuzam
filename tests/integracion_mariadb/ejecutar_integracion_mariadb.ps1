[CmdletBinding()]
param(
  [switch]$UsarServidorExterno,
  [switch]$ConservarDatosTemporales
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Obtener-VariableObligatoria {
  param([Parameter(Mandatory = $true)][string]$Nombre)
  $valor = [Environment]::GetEnvironmentVariable($Nombre, 'Process')
  if ([string]::IsNullOrWhiteSpace($valor)) {
    throw "Falta la variable de entorno obligatoria $Nombre."
  }
  return $valor
}

function Obtener-PuertoLibre {
  foreach ($puerto in 34061..34160) {
    $escucha = [System.Net.Sockets.TcpListener]::new(
      [System.Net.IPAddress]::Loopback,
      $puerto)
    try {
      $escucha.Start()
      return $puerto
    }
    catch [System.Net.Sockets.SocketException] {
      continue
    }
    finally {
      $escucha.Stop()
    }
  }
  throw 'No hay un puerto libre en el rango 34061..34160.'
}

function Obtener-BinariosMariaDb {
  $configurado = [Environment]::GetEnvironmentVariable(
    'FACTUZAM_MARIADB_BIN',
    'Process')
  if (-not [string]::IsNullOrWhiteSpace($configurado)) {
    $binarios = [System.IO.Path]::GetFullPath($configurado)
  }
  else {
    $candidatos = Get-ChildItem -Path "$env:ProgramFiles\MariaDB *\bin" `
      -Directory -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending
    if (-not $candidatos) {
      throw 'No se ha encontrado una instalación local de MariaDB.'
    }
    $binarios = $candidatos[0].FullName
  }
  foreach ($ejecutable in @('mariadb-install-db.exe', 'mariadbd.exe')) {
    if (-not (Test-Path -LiteralPath (Join-Path $binarios $ejecutable))) {
      throw "Falta $ejecutable en $binarios."
    }
  }
  return $binarios
}

function Esperar-MariaDb {
  param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Proceso)
  $sonda = "import os,pymysql; pymysql.connect(" +
    "host=os.environ['FACTUZAM_TEST_DB_HOST']," +
    "port=int(os.environ['FACTUZAM_TEST_DB_PORT'])," +
    "user=os.environ['FACTUZAM_TEST_DB_USER']," +
    "password=os.environ['FACTUZAM_TEST_DB_PASSWORD']," +
    "connect_timeout=1).close()"
  for ($intento = 0; $intento -lt 40; $intento++) {
    if ($Proceso.HasExited) {
      throw "MariaDB terminó durante el arranque (código $($Proceso.ExitCode))."
    }
    $preferenciaAnterior = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    & python -c $sonda 2>$null
    $codigoSonda = $LASTEXITCODE
    $ErrorActionPreference = $preferenciaAnterior
    if ($codigoSonda -eq 0) {
      return
    }
    Start-Sleep -Milliseconds 250
  }
  $ErrorActionPreference = 'Continue'
  & python -c $sonda
  $ErrorActionPreference = $preferenciaAnterior
  throw 'MariaDB no ha aceptado conexiones dentro del plazo esperado.'
}

function Eliminar-DatosTemporales {
  param(
    [Parameter(Mandatory = $true)][string]$Ruta,
    [Parameter(Mandatory = $true)][string]$RaizTemporal
  )
  $rutaCompleta = [System.IO.Path]::GetFullPath($Ruta)
  $raizCompleta = [System.IO.Path]::GetFullPath($RaizTemporal).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar)
  $padre = [System.IO.Directory]::GetParent($rutaCompleta).FullName.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar)
  $nombre = [System.IO.Path]::GetFileName($rutaCompleta)
  if (($padre -ne $raizCompleta) -or
      ($nombre -notmatch '^factuzam-mariadb-it-[0-9a-f]{32}$')) {
    throw "Se rechazó eliminar una ruta temporal inesperada: $rutaCompleta"
  }
  if (Test-Path -LiteralPath $rutaCompleta) {
    Remove-Item -LiteralPath $rutaCompleta -Recurse -Force
  }
}

$directorioPruebas = $PSScriptRoot
$procesoMariaDb = $null
$directorioDatos = $null
$raizTemporal = [System.IO.Path]::GetTempPath()
$codigoPruebas = 1
$env:PYTHONDONTWRITEBYTECODE = '1'

& python -c 'import pymysql'
if ($LASTEXITCODE -ne 0) {
  throw 'Falta PyMySQL. Instala tests/integracion_mariadb/requirements.txt.'
}

try {
  if ($UsarServidorExterno) {
    Obtener-VariableObligatoria 'FACTUZAM_TEST_DB_HOST' | Out-Null
    Obtener-VariableObligatoria 'FACTUZAM_TEST_DB_PORT' | Out-Null
    Obtener-VariableObligatoria 'FACTUZAM_TEST_DB_USER' | Out-Null
    Obtener-VariableObligatoria 'FACTUZAM_TEST_DB_PASSWORD' | Out-Null
    $permiso = Obtener-VariableObligatoria `
      'FACTUZAM_TEST_DB_ALLOW_DISPOSABLE'
    if ($permiso -ne 'SI') {
      throw 'FACTUZAM_TEST_DB_ALLOW_DISPOSABLE debe valer SI.'
    }
  }
  else {
    $binarios = Obtener-BinariosMariaDb
    $puerto = Obtener-PuertoLibre
    $idEjecucion = [Guid]::NewGuid().ToString('N')
    $directorioDatos = Join-Path $raizTemporal `
      "factuzam-mariadb-it-$idEjecucion"
    New-Item -ItemType Directory -Path $directorioDatos -Force | Out-Null
    $instalador = Join-Path $binarios 'mariadb-install-db.exe'
    & $instalador --datadir=$directorioDatos --port=$puerto --silent
    if ($LASTEXITCODE -ne 0) {
      throw "No se pudo inicializar MariaDB (código $LASTEXITCODE)."
    }
    $env:FACTUZAM_TEST_DB_HOST = '127.0.0.1'
    $env:FACTUZAM_TEST_DB_PORT = $puerto.ToString()
    $env:FACTUZAM_TEST_DB_USER = 'root'
    # La instancia se limita a loopback y usa skip-grant-tables. La clave
    # aleatoria solo vive en el entorno del runner y el directorio se destruye.
    $env:FACTUZAM_TEST_DB_PASSWORD = [Guid]::NewGuid().ToString('N')
    $env:FACTUZAM_TEST_DB_ALLOW_DISPOSABLE = 'SI'
    $servidor = Join-Path $binarios 'mariadbd.exe'
    $archivoConfiguracion = Join-Path $directorioDatos 'my.ini'
    $argumentos = @(
      "--defaults-file=`"$archivoConfiguracion`"",
      "--port=$puerto",
      '--bind-address=127.0.0.1',
      '--skip-grant-tables',
      '--skip-name-resolve',
      '--console'
    )
    $procesoMariaDb = Start-Process -FilePath $servidor `
      -ArgumentList $argumentos -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $directorioDatos 'servidor.out.log') `
      -RedirectStandardError (Join-Path $directorioDatos 'servidor.err.log') `
      -PassThru
    Esperar-MariaDb -Proceso $procesoMariaDb
  }
  $env:FACTUZAM_TEST_DB_RUN_ID = [Guid]::NewGuid().ToString('N').Substring(0, 8)
  & python -m unittest discover -s $directorioPruebas -p 'test_*.py' -v
  $codigoPruebas = $LASTEXITCODE
}
finally {
  if (($null -ne $procesoMariaDb) -and (-not $procesoMariaDb.HasExited)) {
    Stop-Process -Id $procesoMariaDb.Id -Force
    $procesoMariaDb.WaitForExit(5000) | Out-Null
  }
  if (($null -ne $directorioDatos) -and
      (-not $ConservarDatosTemporales)) {
    Eliminar-DatosTemporales -Ruta $directorioDatos `
      -RaizTemporal $raizTemporal
  }
}

exit $codigoPruebas
