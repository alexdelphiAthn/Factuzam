$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rutaBase = Join-Path $raiz 'src\DataModules\UniDataGen.pas'
$base = Get-Content -Raw -LiteralPath $rutaBase
$nombresObjetivo = @(
  'UniDataGen.pas',
  'UniDataAlmacenes.pas',
  'UniDataAtributosBasicos.pas',
  'UniDataGenFilter.pas',
  'UniDataPropiedadesValores.pas',
  'UniDataGrupos.pas',
  'UniDataIvasGrupos.pas',
  'UniDataIvas.pas',
  'UniDataTarifas.pas'
)
$rutasObjetivo = $nombresObjetivo | ForEach-Object {
  Join-Path $raiz "src\DataModules\$_"
}
$textoObjetivos = ($rutasObjetivo | ForEach-Object {
  Get-Content -Raw -LiteralPath $_
}) -join "`n"
$pruebas = 0
$fallos = 0

function Comprobar {
  param(
    [bool]$Condicion,
    [string]$Nombre
  )
  $script:pruebas++
  if ($Condicion) {
    Write-Output "[OK] $Nombre"
  }
  else {
    $script:fallos++
    Write-Output "[ERROR] $Nombre"
  }
}

Comprobar ($base -match
    'TdmBase = class\(\s*TDataModule,\s*' +
    'IProveedorAuditoriaDatos,\s*IProveedorConexiones') `
  'TdmBase implementa IProveedorConexiones'
Comprobar ($base -match 'FConexiones: IServicioConexiones') `
  'TdmBase conserva el servicio mediante su interfaz'
Comprobar ($base -match
    'HeredarConexiones\(AOwner\);\s*inherited Create\(AOwner\)') `
  'La conexión se hereda antes de cargar el DFM'
Comprobar ($base -match
    'Supports\(AOwner, IProveedorConexiones, Proveedor\)') `
  'El propietario inmediato puede proporcionar las conexiones'
Comprobar ($base -match
    'Application\.MainForm,\s*IProveedorConexiones') `
  'Existe respaldo mediante el formulario principal'
Comprobar ($base -match
    'property ConexionPrincipal: TUniConnection') `
  'Los descendientes reciben una conexión principal explícita'
Comprobar ($base -match
    'Result := FConexiones\.CrearConexion\(AOwner, AUso\)') `
  'TdmBase puede solicitar conexiones de trabajo'
Comprobar ($base -match
    'unqryTablaG\.Connection := Conexion;\s*' +
    'unqryPerfiles\.Connection := Conexion') `
  'Las queries base usan la conexión inyectada'
Comprobar ($base -match
    'unqrySol\.Connection := ConexionPrincipal') `
  'La operación de perfiles usa la conexión inyectada'
Comprobar ($base -notmatch '\boConn\b') `
  'TdmBase no depende de oConn'
Comprobar ($textoObjetivos -notmatch '\boConn\b') `
  'La primera familia de data modules no depende de oConn'
Comprobar ($textoObjetivos -notmatch '\bUniDataConn\b') `
  'La familia migrada no depende directamente de UniDataConn'

$fuentes = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.pas'
$referenciasOConn = @(
  Select-String -Path ($fuentes.FullName) -Pattern '\boConn\b'
)
$unidadesOConn = @(
  $referenciasOConn | Select-Object -ExpandProperty Path -Unique
)
Comprobar (
    ($referenciasOConn.Count -eq 957) -and
    ($unidadesOConn.Count -eq 115)
  ) 'oConn baja a 957 referencias en 115 unidades'

$dfm = Get-ChildItem -LiteralPath (Join-Path $raiz 'src') -Recurse `
  -Filter '*.dfm'
$dfmConConexion = @()
$enlaces = 0
foreach ($archivo in $dfm) {
  $coincidencias = @(Select-String -LiteralPath $archivo.FullName `
    -SimpleMatch 'Connection = dmConn.conUni')
  if ($coincidencias.Count -gt 0) {
    $dfmConConexion += $archivo
    $enlaces += $coincidencias.Count
  }
}
Comprobar (($dfmConConexion.Count -eq 52) -and ($enlaces -eq 253)) `
  'Se conservan los 253 enlaces persistentes de 52 DFM'

$dfmObjetivo = $nombresObjetivo | ForEach-Object {
  'src/DataModules/' + [System.IO.Path]::ChangeExtension($_, '.dfm')
}
$dfmObjetivoModificados = @(
  & git -C $raiz diff --name-only -- $dfmObjetivo
)
Comprobar ($dfmObjetivoModificados.Count -eq 0) `
  'No hay DFM modificados dentro del alcance de la Fase VII'

$dumpModificado = @(
  & git -C $raiz diff --name-only -- 'factuzam_original.sql'
)
Comprobar ($dumpModificado.Count -eq 0) `
  'El dump modelo permanece intacto'

Write-Output ''
Write-Output "Pruebas: $pruebas | Fallos: $fallos"
if ($fallos -gt 0) {
  throw 'Las comprobaciones de la Fase VII no han sido superadas.'
}
