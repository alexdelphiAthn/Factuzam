<#
Compara los SQL del directorio raíz de DESARROLLOS EN CURSO con una BBDD.
Ejemplos:
  pwsh scripts/inventariar_sql_desarrollos.ps1 -BaseDatos Factuzam
  pwsh scripts/inventariar_sql_desarrollos.ps1 -SoloInventario
#>
[CmdletBinding()]
param(
  [string]$Servidor = '127.0.0.1',
  [int]$Puerto = 3306,
  [string]$BaseDatos,
  [string]$Usuario = 'root',
  [System.Management.Automation.PSCredential]$Credencial,
  [string]$Cliente,
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [switch]$SoloInventario
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Resolver-ClienteMariaDb {
  param([string]$RutaSolicitada)
  if (-not [string]::IsNullOrWhiteSpace($RutaSolicitada)) {
    if (Test-Path -LiteralPath $RutaSolicitada -PathType Leaf) {
      return (Resolve-Path -LiteralPath $RutaSolicitada).Path
    }
    $comandoSolicitado = Get-Command $RutaSolicitada -ErrorAction SilentlyContinue
    if ($null -ne $comandoSolicitado) {
      return $comandoSolicitado.Source
    }
    throw "No se encuentra el cliente MariaDB indicado: $RutaSolicitada"
  }
  foreach ($nombreComando in @('mariadb', 'mysql')) {
    $comando = Get-Command $nombreComando -ErrorAction SilentlyContinue
    if ($null -ne $comando) {
      return $comando.Source
    }
  }
  $rutasInstaladas = @(
    Get-ChildItem `
      -Path 'C:\Program Files\MariaDB *\bin\mariadb.exe',
            'C:\Program Files\MariaDB *\bin\mysql.exe' `
      -File `
      -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending
  )
  if ($rutasInstaladas.Count -gt 0) {
    return $rutasInstaladas[0].FullName
  }
  throw 'No se encuentra mariadb.exe ni mysql.exe.'
}
function Ejecutar-ComprobadorSql {
  param(
    [string]$Ejecutable,
    [string]$RutaSql,
    [string]$HostMariaDb,
    [int]$PuertoMariaDb,
    [string]$NombreBaseDatos,
    [System.Management.Automation.PSCredential]$CredencialMariaDb
  )
  $inicio = [System.Diagnostics.ProcessStartInfo]::new()
  $inicio.FileName = $Ejecutable
  $inicio.UseShellExecute = $false
  $inicio.RedirectStandardInput = $true
  $inicio.RedirectStandardOutput = $true
  $inicio.RedirectStandardError = $true
  $inicio.CreateNoWindow = $true
  $inicio.StandardInputEncoding = [System.Text.UTF8Encoding]::new($false)
  $inicio.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
  $inicio.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)
  $inicio.ArgumentList.Add("--host=$HostMariaDb")
  $inicio.ArgumentList.Add("--port=$PuertoMariaDb")
  $inicio.ArgumentList.Add("--user=$($CredencialMariaDb.UserName)")
  $inicio.ArgumentList.Add("--database=$NombreBaseDatos")
  $inicio.ArgumentList.Add('--default-character-set=utf8mb4')
  $inicio.ArgumentList.Add('--batch')
  $inicio.ArgumentList.Add('--raw')
  $inicio.ArgumentList.Add('--skip-column-names')
  $clavePlana = $null
  $punteroClave = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
    $CredencialMariaDb.Password)
  try {
    $clavePlana = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
      $punteroClave)
    $inicio.Environment['MYSQL_PWD'] = $clavePlana
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($punteroClave)
    $clavePlana = $null
  }
  $proceso = [System.Diagnostics.Process]::new()
  $proceso.StartInfo = $inicio
  try {
    [void]$proceso.Start()
    [void]$inicio.Environment.Remove('MYSQL_PWD')
    $tareaSalida = $proceso.StandardOutput.ReadToEndAsync()
    $tareaError = $proceso.StandardError.ReadToEndAsync()
    $contenidoSql = [System.IO.File]::ReadAllText($RutaSql)
    $proceso.StandardInput.Write($contenidoSql)
    $proceso.StandardInput.Close()
    $proceso.WaitForExit()
    $salida = $tareaSalida.GetAwaiter().GetResult()
    $error = $tareaError.GetAwaiter().GetResult()
    if ($proceso.ExitCode -ne 0) {
      throw "MariaDB devolvió el código $($proceso.ExitCode): $error"
    }
    return $salida
  }
  finally {
    $proceso.Dispose()
  }
}
$rutaDesarrollos = Join-Path $Raiz 'DESARROLLOS EN CURSO'
$rutaComprobador = Join-Path $rutaDesarrollos 'comprobar_scripts_aplicados.sql'
if (-not (Test-Path -LiteralPath $rutaComprobador -PathType Leaf)) {
  throw "No existe el comprobador SQL: $rutaComprobador"
}
$contenidoComprobador = Get-Content -Raw -LiteralPath $rutaComprobador
$marcaNoVerificables = '-- Scripts solo-datos, no detectables por esquema.'
$posicionMarca = $contenidoComprobador.IndexOf($marcaNoVerificables)
if ($posicionMarca -lt 0) {
  throw 'No se encuentra la sección de scripts no verificables.'
}
$seccionReglas = $contenidoComprobador.Substring(0, $posicionMarca)
$seccionNoVerificables = $contenidoComprobador.Substring($posicionMarca)
$scriptsConRegla = @(
  [regex]::Matches($seccionReglas, "'(?<script>[^']+\.sql)'") |
    ForEach-Object { $_.Groups['script'].Value } |
    Sort-Object -Unique
)
$scriptsNoVerificables = @(
  [regex]::Matches(
    $seccionNoVerificables,
    '(?m)^\s*--\s+(?<script>[^\s]+\.sql)(?:\s|$)') |
    ForEach-Object { $_.Groups['script'].Value } |
    Sort-Object -Unique
)
$scriptsDirectorio = @(
  Get-ChildItem -LiteralPath $rutaDesarrollos -File -Filter '*.sql' |
    Where-Object { $_.Name -ne 'comprobar_scripts_aplicados.sql' } |
    Select-Object -ExpandProperty Name |
    Sort-Object -Unique
)
$catalogados = @($scriptsConRegla) + @($scriptsNoVerificables)
$scriptsSinRegla = @(
  $scriptsDirectorio |
    Where-Object { $_ -notin $catalogados }
)
Write-Output 'Inventario de DESARROLLOS EN CURSO (solo el directorio raíz)'
Write-Output "  SQL encontrados:          $($scriptsDirectorio.Count)"
Write-Output "  Con regla de detección:    $($scriptsConRegla.Count)"
Write-Output "  Solo datos/no verificable: $($scriptsNoVerificables.Count)"
Write-Output "  Sin regla en el catálogo:  $($scriptsSinRegla.Count)"
if ($SoloInventario) {
  if ($scriptsSinRegla.Count -gt 0) {
    Write-Output ''
    Write-Output 'SQL sin regla en el catálogo:'
    $scriptsSinRegla | ForEach-Object { Write-Output "  $_" }
  }
  return
}
if ([string]::IsNullOrWhiteSpace($BaseDatos)) {
  throw 'Indica -BaseDatos o utiliza -SoloInventario.'
}
if ($null -eq $Credencial) {
  $Credencial = Get-Credential `
    -UserName $Usuario `
    -Message "Credenciales MariaDB para $Servidor/$BaseDatos"
}
$ejecutableCliente = Resolver-ClienteMariaDb -RutaSolicitada $Cliente
$salidaSql = Ejecutar-ComprobadorSql `
  -Ejecutable $ejecutableCliente `
  -RutaSql $rutaComprobador `
  -HostMariaDb $Servidor `
  -PuertoMariaDb $Puerto `
  -NombreBaseDatos $BaseDatos `
  -CredencialMariaDb $Credencial
$resultados = @(
  $salidaSql -split "`r?`n" |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object {
      $campos = $_ -split "`t", 4
      if ($campos.Count -ne 4) {
        throw "Salida inesperada del comprobador: $_"
      }
      [pscustomobject]@{
        Orden = [int]$campos[0]
        Script = $campos[1]
        Estado = $campos[2]
        Objeto = $campos[3]
      }
    }
)
$faltantes = @($resultados | Where-Object { $_.Estado -eq '>>> FALTA <<<' })
$aplicados = @($resultados | Where-Object { $_.Estado -eq 'OK' })
Write-Output ''
Write-Output "Base de datos: $BaseDatos en ${Servidor}:$Puerto"
Write-Output "  Aplicados detectados: $($aplicados.Count)"
Write-Output "  Faltantes detectados: $($faltantes.Count)"
Write-Output "  No verificables:       $($scriptsNoVerificables.Count)"
Write-Output "  Sin regla:             $($scriptsSinRegla.Count)"
Write-Output ''
Write-Output 'FALTAN:'
if ($faltantes.Count -eq 0) {
  Write-Output '  Ninguno de los scripts verificables.'
}
else {
  $faltantes | Format-Table Orden, Script, Objeto -AutoSize
}
Write-Output 'APLICADOS:'
if ($aplicados.Count -eq 0) {
  Write-Output '  Ninguno.'
}
else {
  $aplicados | Format-Table Orden, Script, Objeto -AutoSize
}
Write-Output 'NO VERIFICABLES POR SER SOLO DATOS:'
$scriptsNoVerificables | ForEach-Object { Write-Output "  $_" }
if ($scriptsSinRegla.Count -gt 0) {
  Write-Output ''
  Write-Output 'SIN REGLA EN EL CATÁLOGO ACTUAL:'
  $scriptsSinRegla | ForEach-Object { Write-Output "  $_" }
}
