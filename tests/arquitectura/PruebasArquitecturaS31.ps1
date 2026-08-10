param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$analizador = Join-Path $PSScriptRoot 'comprobar_arquitectura_s31.ps1'
$utf8SinBom = [System.Text.UTF8Encoding]::new($false)
$pruebasOk = 0
$pruebasFallidas = [System.Collections.Generic.List[string]]::new()

function Nueva-RaizFixture {
  $ruta = Join-Path (
    [System.IO.Path]::GetTempPath()) (
    'factuzam_s31_' + [guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path (Join-Path $ruta 'src'))
  return $ruta
}

function Eliminar-RaizFixture {
  param([string]$Raiz)
  $ruta = [System.IO.Path]::GetFullPath($Raiz)
  $temporal = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::GetTempPath()).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar)
  $prefijo = $temporal + [System.IO.Path]::DirectorySeparatorChar
  if ((-not $ruta.StartsWith(
        $prefijo,
        [System.StringComparison]::OrdinalIgnoreCase)) -or
      (-not ([System.IO.Path]::GetFileName($ruta)).StartsWith(
        'factuzam_s31_',
        [System.StringComparison]::Ordinal))) {
    throw "Se rechazo limpiar una ruta que no es fixture S31: $ruta."
  }
  if (Test-Path -LiteralPath $ruta) {
    Remove-Item -LiteralPath $ruta -Recurse -Force
  }
}

function Escribir-Unidad {
  param(
    [string]$Raiz,
    [string]$Relativa,
    [string]$Contenido
  )
  $ruta = Join-Path $Raiz $Relativa
  [void](New-Item -ItemType Directory -Path (
    Split-Path -Parent $ruta) -Force)
  [System.IO.File]::WriteAllText(
    $ruta,
    ($Contenido.Trim() + [Environment]::NewLine),
    $utf8SinBom)
}

function Ejecutar-Analizador {
  param(
    [string]$Raiz,
    [string[]]$Argumentos = @()
  )
  $salida = & pwsh -NoProfile -File $analizador -Raiz $Raiz @Argumentos 2>&1
  return [pscustomobject]@{
    Codigo = $LASTEXITCODE
    Salida = (($salida | ForEach-Object { $_.ToString() }) -join (
      [Environment]::NewLine))
  }
}

function Ejecutar-Caso {
  param(
    [string]$Nombre,
    [scriptblock]$Preparar,
    [int]$CodigoEsperado,
    [string[]]$DebeContener = @(),
    [string[]]$NoDebeContener = @(),
    [string[]]$Argumentos = @()
  )
  $raiz = Nueva-RaizFixture
  try {
    & $Preparar $raiz
    $resultado = Ejecutar-Analizador -Raiz $raiz -Argumentos $Argumentos
    $errores = [System.Collections.Generic.List[string]]::new()
    if ($resultado.Codigo -ne $CodigoEsperado) {
      $errores.Add(
        "codigo $($resultado.Codigo), esperado $CodigoEsperado")
    }
    foreach ($patron in $DebeContener) {
      if ($resultado.Salida -notmatch $patron) {
        $errores.Add("no contiene /$patron/")
      }
    }
    foreach ($patron in $NoDebeContener) {
      if ($resultado.Salida -match $patron) {
        $errores.Add("contiene el patron prohibido /$patron/")
      }
    }
    if ($errores.Count -eq 0) {
      $script:pruebasOk++
      Write-Output "OK  $Nombre"
    }
    else {
      $script:pruebasFallidas.Add(
        "$($Nombre): $($errores -join '; '). Salida: $($resultado.Salida)")
      Write-Output "FALLO  $Nombre"
    }
  }
  catch {
    $script:pruebasFallidas.Add("$($Nombre): $($_.Exception.Message)")
    Write-Output "FALLO  $Nombre"
  }
  finally {
    Eliminar-RaizFixture -Raiz $raiz
  }
}

function Crear-FanOut {
  param(
    [string]$Raiz,
    [int]$CantidadUi,
    [int]$CantidadComposicion
  )
  $cantidad = [Math]::Max($CantidadUi, $CantidadComposicion)
  for ($indice = 1; $indice -le $cantidad; $indice++) {
    $nombre = 'inLibDep{0:d3}' -f $indice
    Escribir-Unidad $Raiz "src\Lib\$nombre.pas" @"
unit $nombre;
interface
implementation
end.
"@
  }
  $dependenciasUi = @()
  for ($indice = 1; $indice -le $CantidadUi; $indice++) {
    $dependenciasUi += ('inLibDep{0:d3}' -f $indice)
  }
  $dependenciasComposicion = @()
  for ($indice = 1; $indice -le $CantidadComposicion; $indice++) {
    $dependenciasComposicion += ('inLibDep{0:d3}' -f $indice)
  }
  $usesUi = if ($dependenciasUi.Count -gt 0) {
    'uses ' + ($dependenciasUi -join ', ') + ';'
  } else {
    ''
  }
  $usesComposicion = if ($dependenciasComposicion.Count -gt 0) {
    'uses ' + ($dependenciasComposicion -join ', ') + ';'
  } else {
    ''
  }
  Escribir-Unidad $Raiz 'src\Forms\inMtoFanOutCaso.pas' @"
unit inMtoFanOutCaso;
interface
$usesUi
implementation
end.
"@
  Escribir-Unidad $Raiz (
    'src\DataModules\UniDataCasoComposicion.pas') @"
unit UniDataCasoComposicion;
interface
$usesComposicion
implementation
end.
"@
}

Ejecutar-Caso 'ARQ01 positivo: unidad sin localizador' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Forms\inMtoLimpio.pas' @'
unit inMtoLimpio;
interface
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ01_MAINFORM')

Ejecutar-Caso 'ARQ01 limite: MainForm solo como estado visual' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Forms\inMtoMainFormVisual.pas' @'
unit inMtoMainFormVisual;
interface
implementation
procedure LeerTitulo;
begin
  Application.MainForm.Caption;
end;
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ01_MAINFORM')

Ejecutar-Caso 'ARQ01 negativo: Supports resuelve dependencia' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Forms\inMtoMainFormOculto.pas' @'
unit inMtoMainFormOculto;
interface
implementation
procedure Resolver;
begin
  Supports(Application.MainForm, IInterface, Servicio);
end;
end.
'@
} 1 @('ARQ01_MAINFORM')

Ejecutar-Caso 'ARQ02 positivo: sin DmConn' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Core\inMtoSinDmConn.pas' @'
unit inMtoSinDmConn;
interface
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ02_DMCONN')

Ejecutar-Caso 'ARQ02 limite: DmConn en composicion UniDAC' {
  param($raiz)
  Escribir-Unidad $raiz (
    'src\DataModules\UniDataCasoComposicion.pas') @'
unit UniDataCasoComposicion;
interface
implementation
procedure Componer;
begin
  Modulo.DmConn;
end;
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ02_DMCONN')

Ejecutar-Caso 'ARQ02 negativo: DmConn fuera de composicion' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Core\inMtoDmConnOculto.pas' @'
unit inMtoDmConnOculto;
interface
implementation
procedure Usar;
begin
  Modulo.DmConn;
end;
end.
'@
} 1 @('ARQ02_DMCONN')

Ejecutar-Caso 'ARQ03 positivo: data module inyectado' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Forms\inMtoDmInyectado.pas' @'
unit inMtoDmInyectado;
interface
type
  IRepositorio = interface
  end;
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ03_DM_CREATE_UI')

Ejecutar-Caso 'ARQ03 limite: Create dentro del adaptador' {
  param($raiz)
  Escribir-Unidad $raiz 'src\DataModules\UniDataCaso.pas' @'
unit UniDataCaso;
interface
implementation
procedure Crear;
begin
  TdmCaso.Create(nil);
end;
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ03_DM_CREATE_UI')

Ejecutar-Caso 'ARQ03 negativo: Create desde UI' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Forms\inMtoCreaDm.pas' @'
unit inMtoCreaDm;
interface
implementation
procedure Crear;
begin
  TdmCaso.Create(nil);
end;
end.
'@
} 1 @('ARQ03_DM_CREATE_UI')

Ejecutar-Caso 'ARQ04 positivo: contrato agnostico' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibCasoIntf.pas' @'
unit inLibCasoIntf;
interface
type
  IConexionAplicacion = interface
  end;
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ04_UNIDAC_CONTRATO')

Ejecutar-Caso 'ARQ04 limite: UniDAC dentro del adaptador' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibCasoUniDAC.pas' @'
unit inLibCasoUniDAC;
interface
type
  IAdaptadorUniDac = interface
    procedure Conectar(AConexion: TUniConnection);
  end;
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ04_UNIDAC_CONTRATO')

Ejecutar-Caso 'ARQ04 negativo: UniDAC en contrato' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibCasoPublico.pas' @'
unit inLibCasoPublico;
interface
procedure Conectar(AConexion: TUniConnection);
implementation
procedure Conectar(AConexion: TUniConnection);
begin
end;
end.
'@
} 1 @('ARQ04_UNIDAC_CONTRATO', 'TUniConnection')

Ejecutar-Caso 'ARQ05 positivo: sin registro global' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibSinRegistro.pas' @'
unit inLibSinRegistro;
interface
implementation
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ05_ESTADO_GLOBAL')

Ejecutar-Caso 'ARQ05 limite: diccionario local' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibRegistroLocal.pas' @'
unit inLibRegistroLocal;
interface
implementation
procedure Usar;
var
  FabricasLocales: TDictionary<string, TObject>;
begin
  FabricasLocales := TDictionary<string, TObject>.Create;
end;
end.
'@
} 0 @('Arquitectura S31: OK') @('ARQ05_ESTADO_GLOBAL')

Ejecutar-Caso 'ARQ05 negativo: fabrica global inicializada' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibRegistroGlobal.pas' @'
unit inLibRegistroGlobal;
interface
implementation
var
  oFabricasPantallas: TDictionary<string, TObject>;
initialization
  oFabricasPantallas := TDictionary<string, TObject>.Create;
end.
'@
} 1 @('ARQ05_ESTADO_GLOBAL', 'oFabricasPantallas')

Ejecutar-Caso 'ARQ06 positivo: presupuestos holgados' {
  param($raiz)
  Crear-FanOut $raiz 1 1
} 0 @('Fan-out UI: 1/45', 'Fan-out composicion: 1/47') @(
  'ARQ06_FANOUT')

Ejecutar-Caso 'ARQ06 limite: UI 45 y composicion 47' {
  param($raiz)
  Crear-FanOut $raiz 45 47
} 0 @('Fan-out UI: 45/45', 'Fan-out composicion: 47/47') @(
  'ARQ06_FANOUT')

Ejecutar-Caso 'ARQ06 negativo: UI 46 y composicion 48' {
  param($raiz)
  Crear-FanOut $raiz 46 48
} 1 @('ARQ06_FANOUT_UI', 'ARQ06_FANOUT_RAIZ', 'Fan-out UI 46',
  'Fan-out raiz 48')

Ejecutar-Caso 'ARQ07 positivo: no entrega contexto' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibSinContexto.pas' @'
unit inLibSinContexto;
interface
implementation
end.
'@
} 0 @('capacidades entregadas=0; usadas=0; sin usar=0') @(
  'ARQ07_CONTEXTO_NO_USADO')

Ejecutar-Caso 'ARQ07 limite: cada capacidad entregada se usa' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibContextoUsado.pas' @'
unit inLibContextoUsado;
interface
type
  TContextoPantallaCaso = record
    Servicio: IInterface;
  end;
var
  Contexto: TContextoPantallaCaso;
implementation
procedure Usar;
begin
  Contexto.Servicio := nil;
end;
end.
'@
} 0 @('capacidades entregadas=1; usadas=1; sin usar=0') @(
  'ARQ07_CONTEXTO_NO_USADO')

Ejecutar-Caso 'ARQ07 negativo: capacidad entregada sin usar' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibContextoSobredimensionado.pas' @'
unit inLibContextoSobredimensionado;
interface
type
  TContextoPantallaCaso = record
    Usado: IInterface;
    Sobra: IInterface;
  end;
var
  Contexto: TContextoPantallaCaso;
implementation
procedure Usar;
begin
  Contexto.Usado := nil;
end;
end.
'@
} 1 @('ARQ07_CONTEXTO_NO_USADO', 'TContextoPantallaCaso.Sobra')

Ejecutar-Caso 'Clasificacion: generado y tercero no son propios' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibPropio.pas' @'
unit inLibPropio;
interface
implementation
end.
'@
  Escribir-Unidad $raiz 'src\Forms\Caso.generated.pas' @'
unit CasoGenerado;
interface
implementation
procedure Oculto;
begin
  Supports(Application.MainForm, IInterface, Servicio);
end;
end.
'@
  Escribir-Unidad $raiz 'src\Lib3par\CasoTercero.pas' @'
unit CasoTercero;
interface
implementation
procedure Oculto;
begin
  TdmCaso.Create(nil);
end;
end.
'@
} 0 @('Clasificacion: propios=1; generados=1; terceros=1') @(
  'ARQ01_MAINFORM', 'ARQ03_DM_CREATE_UI')

Ejecutar-Caso 'Baseline: el limite UI no se puede ampliar' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibPropio.pas' @'
unit inLibPropio;
interface
implementation
end.
'@
} 1 @('46', 'maximum allowed range|ValidateRange|intervalo') @() @(
  '-MaximoFanOutUi', '46')

Ejecutar-Caso 'Baseline: el limite de composicion no se puede ampliar' {
  param($raiz)
  Escribir-Unidad $raiz 'src\Lib\inLibPropio.pas' @'
unit inLibPropio;
interface
implementation
end.
'@
} 1 @('48', 'maximum allowed range|ValidateRange|intervalo') @() @(
  '-MaximoFanOutComposicion', '48')

Write-Output ''
Write-Output (
  "Fixtures S31: $pruebasOk correctos; " +
  "$($pruebasFallidas.Count) fallidos.")
if ($pruebasFallidas.Count -gt 0) {
  foreach ($fallo in $pruebasFallidas) {
    Write-Output "  $fallo"
  }
  exit 1
}
exit 0
