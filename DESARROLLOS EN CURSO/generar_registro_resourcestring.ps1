param(
  [string]$Raiz = (Join-Path $PSScriptRoot '..')
)

$raizResuelta = (Resolve-Path -LiteralPath $Raiz).Path
$directorioLib = Join-Path $raizResuelta 'src\Lib'
$rutaSalida = Join-Path `
  $directorioLib `
  'inLibRegistroResourcestringTraducciones.pas'
$entradas = [System.Collections.Generic.List[object]]::new()
$claves = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase)
$fuentes = [System.Collections.Generic.List[object]]::new()
$archivosMensajes = @(
  Get-ChildItem -LiteralPath $directorioLib -Filter 'inLibMsg*.pas' |
    Where-Object {
      $_.Name -ne 'inLibMsgRegistroTraducciones.pas'
    } |
    Sort-Object Name
)
foreach ($archivo in $archivosMensajes) {
  $fuentes.Add(
    [pscustomobject]@{
      Unidad = $archivo.BaseName
      Ruta = $archivo.FullName
      Contexto = 'src/Lib/' + $archivo.Name
    })
}
$rutaVcl = Join-Path $raizResuelta 'src\vcl37\Vcl.Consts.pas'
if (-not (Test-Path -LiteralPath $rutaVcl)) {
  throw "No se encontró $rutaVcl."
}
$fuentes.Add(
  [pscustomobject]@{
    Unidad = 'Vcl.Consts'
    Ruta = $rutaVcl
    Contexto = 'src/vcl37/Vcl.Consts.pas'
  })
foreach ($fuente in $fuentes) {
  $texto = [System.IO.File]::ReadAllText($fuente.Ruta)
  $interfaz = [regex]::Match(
    $texto,
    '(?is)\binterface\b(.*?)\bimplementation\b')
  if (-not $interfaz.Success) {
    throw "No se encontró la interfaz de $($fuente.Ruta)."
  }
  $bloques = [regex]::Matches(
    $interfaz.Groups[1].Value,
    '(?ims)^\s*resourcestring\s+(.*?)' +
    '(?=^\s*(?:const|type|var|threadvar|procedure|function)\b|\z)')
  foreach ($bloque in $bloques) {
    $declaraciones = [regex]::Matches(
      $bloque.Groups[1].Value,
      '(?m)^\s*([A-Za-z_]\w*)\s*=')
    foreach ($declaracion in $declaraciones) {
      $nombre = $declaracion.Groups[1].Value
      $clave = $fuente.Unidad + '.' + $nombre
      if ($claves.Add($clave)) {
        $entradas.Add(
          [pscustomobject]@{
            Unidad = $fuente.Unidad
            Nombre = $nombre
            Clave = $clave
            Contexto = $fuente.Contexto
          })
      }
    }
  }
}
if ($entradas.Count -eq 0) {
  throw 'No se encontraron resourcestring en las fuentes configuradas.'
}
$lineas = [System.Collections.Generic.List[string]]::new()
$lineas.Add('unit inLibRegistroResourcestringTraducciones;')
$lineas.Add('')
$lineas.Add('interface')
$lineas.Add('')
$lineas.Add('type')
$lineas.Add('  TRegistrarResourcestringTraduccion = reference to procedure(')
$lineas.Add('    const AClave, AContexto: string;')
$lineas.Add('    ARecurso: PResStringRec);')
$lineas.Add('')
$lineas.Add('procedure EnumerarResourcestringsTraduccion(')
$lineas.Add('  const ARegistrar: TRegistrarResourcestringTraduccion);')
$lineas.Add('')
$lineas.Add('implementation')
$lineas.Add('')
$lineas.Add('uses')
for ($i = 0; $i -lt $fuentes.Count; $i++) {
  $terminador = ','
  if ($i -eq $fuentes.Count - 1) {
    $terminador = ';'
  }
  $lineas.Add('  ' + $fuentes[$i].Unidad + $terminador)
}
$lineas.Add('')
$lineas.Add('{$WARN SYMBOL_DEPRECATED OFF}')
$lineas.Add('procedure EnumerarResourcestringsTraduccion(')
$lineas.Add('  const ARegistrar: TRegistrarResourcestringTraduccion);')
$lineas.Add('begin')
foreach ($entrada in $entradas) {
  if ($entrada.Unidad -eq 'Vcl.Consts') {
    $lineas.Add(
      '{$IF DECLARED(' + $entrada.Nombre + ')}')
  }
  $lineas.Add('  ARegistrar(')
  $lineas.Add("    '$($entrada.Unidad).' +")
  $lineas.Add("    '$($entrada.Nombre)',")
  $lineas.Add("    '$($entrada.Contexto)',")
  $lineas.Add("    @$($entrada.Unidad).")
  $lineas.Add("      $($entrada.Nombre));")
  if ($entrada.Unidad -eq 'Vcl.Consts') {
    $lineas.Add('{$ENDIF}')
  }
}
$lineas.Add('end;')
$lineas.Add('{$WARN SYMBOL_DEPRECATED ON}')
$lineas.Add('')
$lineas.Add('end.')
$largas = for ($i = 0; $i -lt $lineas.Count; $i++) {
  if ($lineas[$i].Length -gt 80) {
    "$($i + 1):$($lineas[$i].Length)"
  }
}
if ($largas) {
  throw 'El registro generado supera 80 columnas: ' + ($largas -join ', ')
}
$contenido = ($lineas -join "`r`n") + "`r`n"
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText(
  $rutaSalida,
  $contenido,
  $utf8Bom)
Write-Output "UNIDADES=$($fuentes.Count)"
Write-Output "MENSAJES=$($entradas.Count)"
Write-Output "SALIDA=$rutaSalida"
