param(
  [string]$RaizRepositorio = (Split-Path -Parent $PSScriptRoot),
  [switch]$OmitirLineaBase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PruebasCorrectas = 0
$script:PruebasFallidas = 0
$script:DetalleFallos = [System.Collections.Generic.List[string]]::new()
$rutaEstilo = Join-Path $RaizRepositorio `
  'scripts\comprobar_estilo_codigo.ps1'
$rutaMetodos = Join-Path $RaizRepositorio `
  'scripts\comprobar_metodos_largos.ps1'
$rutaInterfaces = Join-Path $RaizRepositorio `
  'scripts\comprobar_interfaces_segregadas.ps1'
$utf8ConBom = [System.Text.UTF8Encoding]::new($true)
[System.Text.Encoding]::RegisterProvider(
  [System.Text.CodePagesEncodingProvider]::Instance)
$windows1252 = [System.Text.Encoding]::GetEncoding(1252)

function Registrar-Prueba {
  param(
    [string]$Nombre,
    [scriptblock]$Prueba
  )
  try {
    & $Prueba
    $script:PruebasCorrectas++
    Write-Output "OK: $Nombre"
  }
  catch {
    $script:PruebasFallidas++
    $detalle = "FALLO: ${Nombre}: $($_.Exception.Message)"
    $script:DetalleFallos.Add($detalle)
    Write-Output $detalle
  }
}

function Confirmar-Condicion {
  param(
    [bool]$Condicion,
    [string]$Mensaje
  )
  if (-not $Condicion) {
    throw $Mensaje
  }
}

function Ejecutar-Script {
  param(
    [string]$Ruta,
    [string[]]$Argumentos = @()
  )
  $inicio = [System.Diagnostics.ProcessStartInfo]::new()
  $inicio.FileName = (Get-Command pwsh).Source
  $inicio.UseShellExecute = $false
  $inicio.RedirectStandardOutput = $true
  $inicio.RedirectStandardError = $true
  $inicio.ArgumentList.Add('-NoProfile')
  $inicio.ArgumentList.Add('-ExecutionPolicy')
  $inicio.ArgumentList.Add('Bypass')
  $inicio.ArgumentList.Add('-File')
  $inicio.ArgumentList.Add($Ruta)
  foreach ($argumento in $Argumentos) {
    $inicio.ArgumentList.Add($argumento)
  }
  $proceso = [System.Diagnostics.Process]::new()
  $proceso.StartInfo = $inicio
  $null = $proceso.Start()
  $salida = $proceso.StandardOutput.ReadToEnd()
  $errorProceso = $proceso.StandardError.ReadToEnd()
  $proceso.WaitForExit()
  $resultado = [pscustomobject]@{
    Codigo = $proceso.ExitCode
    Error = $errorProceso
    Salida = $salida
    Texto = $salida + $errorProceso
  }
  $proceso.Dispose()
  return $resultado
}

function Confirmar-Resultado {
  param(
    [object]$Resultado,
    [int]$Codigo,
    [string[]]$Textos
  )
  Confirmar-Condicion `
    -Condicion ($Resultado.Codigo -eq $Codigo) `
    -Mensaje (
      "Codigo esperado: $Codigo; real: $($Resultado.Codigo). " +
      "Salida: $($Resultado.Texto)")
  foreach ($texto in $Textos) {
    Confirmar-Condicion `
      -Condicion $Resultado.Texto.Contains($texto) `
      -Mensaje "No aparece el texto esperado: $texto."
  }
}

function Escribir-ArchivoPrueba {
  param(
    [string]$Ruta,
    [string]$Contenido,
    [System.Text.Encoding]$Codificacion = $utf8ConBom
  )
  $directorio = Split-Path -Parent $Ruta
  $null = New-Item -ItemType Directory -Path $directorio -Force
  [System.IO.File]::WriteAllText(
    $Ruta,
    $Contenido,
    $Codificacion)
}

function Nueva-RaizPrueba {
  $ruta = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    ('factuzam_trinquetes_' + [guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Path $ruta
  return $ruta
}

function Agregar-RutinasGeneradas {
  param([string]$Raiz)
  $contenidoResourcestring = @(
    'unit inLibRegistroResourcestringTraducciones;',
    'interface',
    'implementation',
    'procedure EnumerarResourcestringsTraduccion;',
    'begin',
    'end;',
    'end.'
  ) -join "`r`n"
  $contenidoParametros = @(
    'unit inLibRegistroParametrosTraducciones;',
    'interface',
    'implementation',
    'procedure EnumerarParametrosTraduccion;',
    'begin',
    'end;',
    'end.'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz `
      'src\Lib\inLibRegistroResourcestringTraducciones.pas') `
    -Contenido $contenidoResourcestring
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz `
      'src\Lib\inLibRegistroParametrosTraducciones.pas') `
    -Contenido $contenidoParametros
}

function Crear-MetodoSimple {
  param(
    [string]$Nombre,
    [int]$NumeroLineas
  )
  $lineas = [System.Collections.Generic.List[string]]::new()
  $lineas.Add("procedure $Nombre;")
  $lineas.Add('begin')
  while ($lineas.Count -lt ($NumeroLineas - 1)) {
    $lineas.Add('  Valor := Valor + 1;')
  }
  $lineas.Add('end;')
  return $lineas.ToArray()
}

function Crear-MetodoAnidado {
  param(
    [string]$Nombre,
    [int]$NumeroLineas
  )
  $lineas = [System.Collections.Generic.List[string]]::new()
  @(
    "procedure $Nombre;",
    'begin',
    "  Texto := 'begin end case try repeat until';",
    '  { begin case try repeat',
    '    end until }',
    '  case Valor of',
    '    0:',
    '      begin',
    '        try',
    '          repeat',
    '            Valor := Valor + 1;',
    '          until Valor > 0;',
    '        finally',
    '          Valor := 0;',
    '        end;',
    '      end;',
    '  end;'
  ) | ForEach-Object { $lineas.Add($_) }
  while ($lineas.Count -lt ($NumeroLineas - 1)) {
    $lineas.Add('  Valor := Valor + 1;')
  }
  $lineas.Add('end;')
  return $lineas.ToArray()
}

function Agregar-CasosMetodos {
  param([string]$Raiz)
  $lineas = [System.Collections.Generic.List[string]]::new()
  @(
    'unit CasosMetodos;',
    'interface',
    'implementation'
  ) | ForEach-Object { $lineas.Add($_) }
  $lineas.AddRange([string[]](Crear-MetodoSimple `
    -Nombre 'MetodoLimite' `
    -NumeroLineas 120))
  $lineas.AddRange([string[]](Crear-MetodoAnidado `
    -Nombre 'MetodoLargo' `
    -NumeroLineas 130))
  $lineas.Add('end.')
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz 'src\CasosMetodos.pas') `
    -Contenido ($lineas -join "`r`n")
}

function Agregar-CasosEstilo {
  param([string]$Raiz)
  $linea80 = '//' + ('a' * 78)
  $linea81 = '//' + ('a' * 79)
  $lineaAcentuada79 = '//' + ('á' * 77)
  $lineas = @(
    'unit CasosEstilo;',
    'interface',
    'implementation',
    'procedure Ejecutar;',
    'begin',
    '  if Uno then',
    '    Exit;',
    '  if Dos then',
    '    Exit;',
    '  if Tres then',
    '    Exit;',
    '  while Falso do',
    '    Continue;',
    "  Texto := 'Exit Continue';",
    '  // Exit Continue',
    '  { Exit',
    '    Continue }',
    '  (* Exit Continue *)',
    $linea80,
    $linea81,
    $lineaAcentuada79,
    "`tValor := 1;",
    'end;',
    'end.'
  )
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz 'src\CasosEstilo.pas') `
    -Contenido ($lineas -join "`r`n") `
    -Codificacion $windows1252
}

function Agregar-CasosInterfaces {
  param([string]$Raiz)
  # Unidad activa que NO es *Intf.pas: el resguardo tambien la examina
  $miembrosJustos = 1..10 |
    ForEach-Object { "    procedure Operacion$_;" }
  $miembrosDeMas = 1..11 |
    ForEach-Object { "    function Consulta$_: Integer;" }
  $lineas = @(
    'unit CasosInterfaces;',
    'interface',
    'type',
    '  IContratoJusto = interface',
    "    ['{6E9C1D3A-0000-4000-8000-000000000001}']"
  ) + $miembrosJustos + @(
    '  end;',
    '  IContratoAncho = interface',
    "    ['{6E9C1D3A-0000-4000-8000-000000000002}']"
  ) + $miembrosDeMas + @(
    '  end;',
    'implementation',
    'end.'
  )
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz 'src\CasosInterfaces.pas') `
    -Contenido ($lineas -join "`r`n")
}

function Borrar-RaizPrueba {
  param([string]$Ruta)
  $temporal = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::GetTempPath())
  $objetivo = [System.IO.Path]::GetFullPath($Ruta)
  $nombre = Split-Path -Leaf $objetivo
  $esTemporal = $objetivo.StartsWith(
    $temporal,
    [System.StringComparison]::OrdinalIgnoreCase)
  $esPrueba = $nombre.StartsWith(
    'factuzam_trinquetes_',
    [System.StringComparison]::Ordinal)
  if ($esTemporal -and $esPrueba -and
      (Test-Path -LiteralPath $objetivo)) {
    Remove-Item -LiteralPath $objetivo -Recurse -Force
  }
}

Registrar-Prueba 'sintaxis y formato de los scripts' {
  foreach ($ruta in @($rutaEstilo, $rutaMetodos, $rutaInterfaces)) {
    $tokens = $null
    $errores = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
      $ruta,
      [ref]$tokens,
      [ref]$errores)
    Confirmar-Condicion `
      -Condicion ($errores.Count -eq 0) `
      -Mensaje "Errores de sintaxis en $ruta."
    $contenido = Get-Content -LiteralPath $ruta -Raw
    $anchas = @(
      [regex]::Split($contenido, "`r`n|`n|`r") |
        Where-Object { $_.Length -gt 80 }
    )
    Confirmar-Condicion `
      -Condicion ($anchas.Count -eq 0) `
      -Mensaje "Hay lineas de mas de 80 columnas en $ruta."
    Confirmar-Condicion `
      -Condicion (-not $contenido.Contains("`t")) `
      -Mensaje "Hay tabuladores en $ruta."
  }
}

if (-not $OmitirLineaBase) {
  Registrar-Prueba 'linea base real de estilo' {
    $resultado = Ejecutar-Script -Ruta $rutaEstilo
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Estilo de codigo: OK.',
        'Exit: 1349.',
        'Continue: 107.',
        'Lineas anchas: 575.',
        'Lineas con tabulador: 0.'
      )
  }
  Registrar-Prueba 'linea base real de metodos' {
    $resultado = Ejecutar-Script -Ruta $rutaMetodos
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Metodos largos: OK.',
        'Analizados: 7335.',
        'De mas de 120 lineas: 124.',
        'Mas largo: 312 lineas',
        'Rutinas generadas fuera del limite: 2.'
      )
  }
  Registrar-Prueba 'linea base real de interfaces' {
    $resultado = Ejecutar-Script -Ruta $rutaInterfaces
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Interfaces segregadas: OK.',
        'contratos retirados: 9.'
      )
  }
}

$raizEstilo = Nueva-RaizPrueba
try {
  Agregar-RutinasGeneradas -Raiz $raizEstilo
  Agregar-CasosEstilo -Raiz $raizEstilo
  Registrar-Prueba 'estilo: limites, comentarios y codificacion' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Exit: 3.',
        'Continue: 1.',
        'Lineas anchas: 1.',
        'Lineas con tabulador: 1.'
      )
  }
  Registrar-Prueba 'estilo: fallo independiente de Exit' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-MaximoExit', '2',
        '-MaximoContinue', '1',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @('Llamadas a Exit: 3; maximo permitido: 2.')
  }
  Registrar-Prueba 'estilo: fallo independiente de Continue' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-MaximoExit', '3',
        '-MaximoContinue', '0',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @('Llamadas a Continue: 1; maximo permitido: 0.')
  }
  Registrar-Prueba 'estilo: fallo independiente de ancho' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoLineasAnchas', '0',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Lineas de mas de 80 columnas: 1; maximo permitido: 0.'
      )
  }
  Registrar-Prueba 'estilo: fallo independiente de tabulador' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '0'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Lineas con tabuladores: 1; maximo permitido: 0.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizEstilo
}

$raizMetodos = Nueva-RaizPrueba
try {
  Agregar-RutinasGeneradas -Raiz $raizMetodos
  Agregar-CasosMetodos -Raiz $raizMetodos
  Registrar-Prueba 'metodos: limite exacto y bloques anidados' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizMetodos,
        '-UmbralLineas', '120',
        '-MaximoMetodosLargos', '1',
        '-MaximoLineasPorMetodo', '130'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'De mas de 120 lineas: 1.',
        'Mas largo: 130 lineas (MetodoLargo).'
      )
  }
  Registrar-Prueba 'metodos: fallo por cantidad' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizMetodos,
        '-UmbralLineas', '120',
        '-MaximoMetodosLargos', '0',
        '-MaximoLineasPorMetodo', '130'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Metodos de mas de 120 lineas: 1; maximo permitido: 0.'
      )
  }
  Registrar-Prueba 'metodos: fallo por longitud maxima' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizMetodos,
        '-UmbralLineas', '120',
        '-MaximoMetodosLargos', '1',
        '-MaximoLineasPorMetodo', '129'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Lineas del metodo mas largo (MetodoLargo): 130;',
        'maximo permitido: 129.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizMetodos
}

$raizInterfaces = Nueva-RaizPrueba
try {
  Agregar-CasosInterfaces -Raiz $raizInterfaces
  Registrar-Prueba 'interfaces: ancha detectada fuera de *Intf.pas' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaInterfaces `
      -Argumentos @('-Raiz', $raizInterfaces)
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @('IContratoAncho tiene 11 miembros')
  }
  Registrar-Prueba 'interfaces: limite exacto permitido' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaInterfaces `
      -Argumentos @('-Raiz', $raizInterfaces, '-MaximoMiembros', '11')
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Interfaces segregadas: OK.',
        'Unidades analizadas: 1;'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizInterfaces
}

$raizRetirados = Nueva-RaizPrueba
try {
  $contenidoRetirado = @(
    'unit CasosRetirados;',
    'interface',
    'type',
    '  TUsoRetirado = class',
    '    FContrato: IDBHelpers;',
    '  end;',
    'implementation',
    'end.'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $raizRetirados 'src\CasosRetirados.pas') `
    -Contenido $contenidoRetirado
  Registrar-Prueba 'interfaces: contrato retirado reaparecido' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaInterfaces `
      -Argumentos @('-Raiz', $raizRetirados)
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Han reaparecido contratos retirados',
        'CasosRetirados.pas: IDBHelpers'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizRetirados
}

$raizSinGenerados = Nueva-RaizPrueba
try {
  $null = New-Item `
    -ItemType Directory `
    -Path (Join-Path $raizSinGenerados 'src')
  Agregar-CasosMetodos -Raiz $raizSinGenerados
  Registrar-Prueba 'metodos: integridad de rutinas generadas' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizSinGenerados,
        '-MaximoMetodosLargos', '10',
        '-MaximoLineasPorMetodo', '1000'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'No se localizaron todas las rutinas generadas excluidas',
        'esperadas: 2.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizSinGenerados
}

$raizExclusiones = Nueva-RaizPrueba
try {
  Agregar-RutinasGeneradas -Raiz $raizExclusiones
  $contenidoExcluido = @(
    'unit Ignorada;',
    'interface',
    'implementation',
    (Crear-MetodoSimple -Nombre 'MetodoIgnorado' -NumeroLineas 150),
    "`tExit; // " + ('a' * 90),
    'end.'
  ) | ForEach-Object { $_ }
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $raizExclusiones `
      'src\3rdpartyComp\Ignorada.pas') `
    -Contenido ($contenidoExcluido -join "`r`n")
  Registrar-Prueba 'exclusiones y arbol propio limpio' {
    $resultadoEstilo = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizExclusiones,
        '-MaximoExit', '0',
        '-MaximoContinue', '0',
        '-MaximoLineasAnchas', '0',
        '-MaximoLineasConTabulador', '0'
      )
    Confirmar-Resultado `
      -Resultado $resultadoEstilo `
      -Codigo 0 `
      -Textos @(
        'Exit: 0.',
        'Continue: 0.',
        'Lineas anchas: 0.',
        'Lineas con tabulador: 0.'
      )
    $resultadoMetodos = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizExclusiones,
        '-MaximoMetodosLargos', '0',
        '-MaximoLineasPorMetodo', '0'
      )
    Confirmar-Resultado `
      -Resultado $resultadoMetodos `
      -Codigo 0 `
      -Textos @(
        'De mas de 120 lineas: 0.',
        'Mas largo: 0 lineas',
        'Rutinas generadas fuera del limite: 2.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizExclusiones
}

Write-Output ''
Write-Output (
  "Pruebas correctas: $script:PruebasCorrectas. " +
  "Fallidas: $script:PruebasFallidas.")
if ($script:PruebasFallidas -gt 0) {
  $script:DetalleFallos | ForEach-Object { Write-Error $_ }
  exit 1
}
