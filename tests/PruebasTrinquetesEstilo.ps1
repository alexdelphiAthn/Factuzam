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
$rutaConsultasUi = Join-Path $RaizRepositorio `
  'scripts\comprobar_consultas_ui.ps1'
$rutaDependenciasOcultas = Join-Path $RaizRepositorio `
  'scripts\comprobar_dependencias_ocultas.ps1'
$rutaPruebasDelphi = Join-Path $RaizRepositorio `
  'scripts\ejecutar_pruebas_delphi.ps1'
$rutaWorkflowCalidad = Join-Path $RaizRepositorio `
  '.github\workflows\calidad.yml'
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
    '  with Objeto do',
    '    Valor := 1;',
    "  Texto := 'Exit Continue with';",
    '  // Exit Continue with',
    '  { Exit',
    '    Continue with }',
    '  (* Exit Continue with *)',
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
    ForEach-Object { "    function Consulta${_}: Integer;" }
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

function Agregar-CasosConsultasUi {
  param([string]$Raiz)
  $contenido = @(
    'unit CasosConsultasUi;',
    'interface',
    'implementation',
    'procedure Ejecutar;',
    'begin',
    '  Uno := TUniQuery.Create(nil);',
    '  Dos := TUniQuery . Create (nil);',
    "  Uno.SQL.Text := 'SELECT 1';",
    "  Dos . SQL . Text := 'SELECT 2';",
    "  Uno.SQL.Add(' WHERE 1 = 1');",
    "  Dos . SQL . Add (' WHERE 2 = 2');",
    '  TrxUno := TUniTransaction.Create(nil);',
    '  Conexion.StartTransaction;',
    '  ProcUno := TUniStoredProc.Create(nil);',
    '  ProcDos := TUniStoredProc . Create (nil);',
    'end;',
    'end.'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz 'src\Forms\CasosConsultasUi.pas') `
    -Contenido $contenido
  $contenidoDfm = @(
    'object frmCasosConsultasUi: TfrmCasosConsultasUi',
    '  object unqryUno: TUniQuery',
    "    CommandText = 'SELECT 3'",
    '  end',
    '  object unstrdprcDos: TUniStoredProc',
    "    CommandText = 'SELECT 4'",
    '  end',
    'end'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $Raiz 'src\Forms\CasosConsultasUi.dfm') `
    -Contenido $contenidoDfm
}

function Agregar-ContratosSinUniDAC {
  param([string]$Raiz)
  $rutas = @(
    'src\Lib\inLibModoTallasIntf.pas',
    'src\Lib\inLibColumnasSkuIntf.pas',
    'src\Lib\inLibVentasWsJsonIntf.pas',
    'src\Lib\inLibVentasWsColaIntf.pas',
    'src\Lib\inLibVentasWsCola.pas',
    'src\Lib\inLibFacturaePersistenciaIntf.pas',
    'src\Lib\inLibPedidosCompraIntf.pas',
    'src\Lib\inLibAplicacionArticuloCompraIntf.pas',
    'src\verifactu\inLibVerifactuEsquemaIntf.pas'
  )
  foreach ($ruta in $rutas) {
    $unidad = [System.IO.Path]::GetFileNameWithoutExtension($ruta)
    $contenido = @(
      "unit $unidad;",
      'interface',
      'implementation',
      'end.'
    ) -join "`r`n"
    Escribir-ArchivoPrueba `
      -Ruta (Join-Path $Raiz $ruta) `
      -Contenido $contenido
  }
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
  foreach ($ruta in @(
    $rutaEstilo,
    $rutaMetodos,
    $rutaInterfaces,
    $rutaConsultasUi,
    $rutaDependenciasOcultas,
    $rutaPruebasDelphi)) {
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
        'With:',
        'Lineas anchas:',
        'Lineas con tabulador:'
      )
  }
  Registrar-Prueba 'linea base real de metodos' {
    $resultado = Ejecutar-Script -Ruta $rutaMetodos
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Metodos largos: OK.',
        'De mas de 120 lineas:',
        'Riesgo acumulado:',
        'Mayor riesgo:'
      )
  }
  Registrar-Prueba 'linea base real de interfaces' {
    $resultado = Ejecutar-Script -Ruta $rutaInterfaces
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Interfaces segregadas: OK.',
        'contratos retirados: 13;'
      )
  }
  Registrar-Prueba 'linea base real de consultas UI' {
    $resultado = Ejecutar-Script -Ruta $rutaConsultasUi
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Consultas UI: OK.',
        'TUniQuery.Create: 0;',
        'Componentes UniDAC en DFM: 0;',
        'SQL.Text :=: 0;',
        'SQL.Add: 0;',
        'CommandText: 0;',
        'Transacciones creadas/iniciadas: 0;',
        'TUniStoredProc.Create: 0;'
      )
  }
  Registrar-Prueba 'linea base real de dependencias ocultas' {
    $resultado = Ejecutar-Script -Ruta $rutaDependenciasOcultas
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Dependencias ocultas: OK.',
        'localizadores y contextos de pantalla comprobados.'
      )
  }
}

$raizDependenciasOcultas = Nueva-RaizPrueba
try {
  $contenidoFrmBase = @(
    'unit inMtoFrmBase;',
    'interface',
    'type',
    '  TContextoDependenciasFacturas = record end;',
    '  TContextoDependenciasOperacionCaja = record end;',
    '  TContextoDependenciasComprasSesiones = record end;',
    '  TContextoDependenciasInventario = record end;',
    '  TContextoDependenciasArticulos = record end;',
    '  TContextoDependenciasStockConsulta = record end;',
    'implementation',
    'end.'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $raizDependenciasOcultas `
      'src\Core\inMtoFrmBase.pas') `
    -Contenido $contenidoFrmBase
  $contenidoCasoOculto = @(
    'unit CasoDependenciaOculta;',
    'interface',
    'type',
    '  TFormularioMalo = class',
    '  private',
    '    FRepositorios: IRepositoriosArticulosPantalla;',
    '  end;',
    'implementation',
    'procedure Resolver;',
    'var',
    '  Compositor: ICompositorArticulosPantalla;',
    'begin',
    "  Owner.FindComponent('Repositorios');",
    '  Objeto.GetInterface(',
    '    IRepositoriosArticulosPantalla, Repositorios);',
    '  BuscarCompositor;',
    '  ObtenerCompositorArticulosPantalla;',
    '  Supports(Application.MainForm,',
    '    IRepositoriosArticulosPantalla, Repositorios);',
    'end;',
    'end.'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta (Join-Path $raizDependenciasOcultas `
      'src\Forms\CasoDependenciaOculta.pas') `
    -Contenido $contenidoCasoOculto
  Registrar-Prueba 'dependencias ocultas: bloquea localizadores' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaDependenciasOcultas `
      -Argumentos @('-Raiz', $raizDependenciasOcultas)
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Localizador de compositor de pantalla',
        'Acceso global a compositor de pantalla',
        'Contrato de compositor de pantalla obsoleto',
        'Familia amplia de repositorios almacenada en presentación',
        'Resolución de dependencia mediante Owner.FindComponent',
        'Resolución de dependencia mediante GetInterface',
        'Repositorio de feature resuelto desde Application.MainForm'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizDependenciasOcultas
}

Registrar-Prueba 'CI Delphi obligatoria en cada PR' {
  $workflow = Get-Content -LiteralPath $rutaWorkflowCalidad -Raw
  $scriptDelphi = Get-Content -LiteralPath $rutaPruebasDelphi -Raw
  $bloqueCalidad = [regex]::Match(
    $workflow,
    '(?ms)^  trinquetes:.*?(?=^  [a-zA-Z0-9_-]+:|\z)').Value
  $bloqueDelphi = [regex]::Match(
    $workflow,
    '(?ms)^  pruebas-delphi:.*?(?=^  [a-zA-Z0-9_-]+:|\z)').Value
  Confirmar-Condicion `
    -Condicion $workflow.Contains('pull_request:') `
    -Mensaje 'El workflow no se ejecuta en pull_request.'
  Confirmar-Condicion `
    -Condicion $workflow.Contains('merge_group:') `
    -Mensaje 'El workflow no protege la cola de integración.'
  Confirmar-Condicion `
    -Condicion $bloqueCalidad.Contains(
      '.\scripts\comprobar_calidad.ps1') `
    -Mensaje 'El job de trinquetes no ejecuta todos los controles.'
  Confirmar-Condicion `
    -Condicion ($bloqueDelphi -ne '') `
    -Mensaje 'No existe el job obligatorio de Delphi.'
  Confirmar-Condicion `
    -Condicion (-not $bloqueDelphi.Contains("`n    if:")) `
    -Mensaje 'El job Delphi no puede quedar condicionado.'
  Confirmar-Condicion `
    -Condicion $bloqueDelphi.Contains(
      '.\scripts\ejecutar_pruebas_delphi.ps1') `
    -Mensaje 'El job Delphi no ejecuta su entrada automatizada.'
  Confirmar-Condicion `
    -Condicion $scriptDelphi.Contains("'fzam.dproj'") `
    -Mensaje 'La validación Delphi no compila fzam.dproj.'
  Confirmar-Condicion `
    -Condicion $scriptDelphi.Contains("@('Win32', 'Win64')") `
    -Mensaje 'La validación Delphi no exige Win32 y Win64.'
  Confirmar-Condicion `
    -Condicion $scriptDelphi.Contains("'tests\FactuzamTests.dproj'") `
    -Mensaje 'La validación Delphi no compila DUnitX.'
  Confirmar-Condicion `
    -Condicion $scriptDelphi.Contains('Ejecutar-Bateria') `
    -Mensaje 'La validación Delphi no ejecuta DUnitX.'
}

$raizConsultasUi = Nueva-RaizPrueba
try {
  Agregar-CasosConsultasUi -Raiz $raizConsultasUi
  Registrar-Prueba 'consultas UI: permite el limite exacto' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaConsultasUi `
      -Argumentos @(
        '-Raiz', $raizConsultasUi,
        '-MaximoConsultasUi', '2',
        '-MaximoComponentesUniDacDfm', '2',
        '-MaximoAsignacionesSqlText', '2',
        '-MaximoLlamadasSqlAdd', '2',
        '-MaximoAsignacionesCommandText', '2',
        '-MaximoTransaccionesCreadas', '2',
        '-MaximoProcedimientosCreados', '2'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'TUniQuery.Create: 2; máximo permitido: 2.',
        'Componentes UniDAC en DFM: 2; máximo permitido: 2.',
        'SQL.Text :=: 2; máximo permitido: 2.',
        'SQL.Add: 2; máximo permitido: 2.',
        'CommandText: 2; máximo permitido: 2.',
        'Transacciones creadas/iniciadas: 2; máximo permitido: 2.',
        'TUniStoredProc.Create: 2; máximo permitido: 2.'
      )
  }
  $casosTopeConsultasUi = @(
    [pscustomobject]@{
      Nombre = 'TUniQuery.Create'
      Parametro = '-MaximoConsultasUi'
    },
    [pscustomobject]@{
      Nombre = 'Componentes UniDAC en DFM'
      Parametro = '-MaximoComponentesUniDacDfm'
    },
    [pscustomobject]@{
      Nombre = 'SQL.Text :='
      Parametro = '-MaximoAsignacionesSqlText'
    },
    [pscustomobject]@{
      Nombre = 'SQL.Add'
      Parametro = '-MaximoLlamadasSqlAdd'
    },
    [pscustomobject]@{
      Nombre = 'CommandText'
      Parametro = '-MaximoAsignacionesCommandText'
    },
    [pscustomobject]@{
      Nombre = 'Transacciones creadas/iniciadas'
      Parametro = '-MaximoTransaccionesCreadas'
    },
    [pscustomobject]@{
      Nombre = 'TUniStoredProc.Create'
      Parametro = '-MaximoProcedimientosCreados'
    }
  )
  foreach ($caso in $casosTopeConsultasUi) {
    Registrar-Prueba "consultas UI: bloquea $($caso.Nombre)" {
      $argumentos = [System.Collections.Generic.List[string]]::new()
      $argumentos.Add('-Raiz')
      $argumentos.Add($raizConsultasUi)
      foreach ($limite in $casosTopeConsultasUi) {
        $argumentos.Add($limite.Parametro)
        if ($limite.Parametro -eq $caso.Parametro) {
          $argumentos.Add('1')
        }
        else {
          $argumentos.Add('2')
        }
      }
      $resultado = Ejecutar-Script `
        -Ruta $rutaConsultasUi `
        -Argumentos $argumentos.ToArray()
      Confirmar-Resultado `
        -Resultado $resultado `
        -Codigo 1 `
        -Textos @(
          'Accesos directos a datos en UI fuera de tope:',
          "$($caso.Nombre): 2; máximo permitido: 1."
        )
    }
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizConsultasUi
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
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoWith', '1',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 0 `
      -Textos @(
        'Exit: 3.',
        'Continue: 1.',
        'With: 1.',
        'Lineas anchas: 1.',
        'Lineas con tabulador: 1.'
      )
  }
  Registrar-Prueba 'estilo: fallo independiente de Exit' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '2',
        '-MaximoContinue', '1',
        '-MaximoWith', '1',
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
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '3',
        '-MaximoContinue', '0',
        '-MaximoWith', '1',
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
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoWith', '1',
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
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoWith', '1',
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
  Registrar-Prueba 'estilo: fallo independiente de with' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizEstilo,
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '3',
        '-MaximoContinue', '1',
        '-MaximoWith', '0',
        '-MaximoLineasAnchas', '1',
        '-MaximoLineasConTabulador', '1'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @('Sentencias with: 1; maximo permitido: 0.')
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizEstilo
}

$raizLineaBaseEstilo = Nueva-RaizPrueba
try {
  Agregar-CasosEstilo -Raiz $raizLineaBaseEstilo
  $rutaLineaBaseEstilo = Join-Path `
    $raizLineaBaseEstilo `
    'estilo_linea_base.csv'
  $contenidoLineaBase = @(
    'Ruta;Exit;Continue;With;Anchas;Tabuladores',
    'src\CasosEstilo.pas;3;1;0;1;1'
  ) -join "`r`n"
  Escribir-ArchivoPrueba `
    -Ruta $rutaLineaBaseEstilo `
    -Contenido $contenidoLineaBase
  Registrar-Prueba 'estilo: bloquea deuda nueva por unidad' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaEstilo `
      -Argumentos @(
        '-Raiz', $raizLineaBaseEstilo,
        '-RutaLineaBase', $rutaLineaBaseEstilo
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'src\CasosEstilo.pas: With = 1; linea base: 0.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizLineaBaseEstilo
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
        'Mas largo: 130 lineas (MetodoLargo).',
        'Riesgo acumulado: 138.',
        'Mayor riesgo: 138 (MetodoLargo).'
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
  Registrar-Prueba 'metodos: fallo por riesgo acumulado' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizMetodos,
        '-UmbralLineas', '120',
        '-MaximoMetodosLargos', '1',
        '-MaximoLineasPorMetodo', '130',
        '-MaximoRiesgoAcumulado', '137'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Riesgo acumulado de metodos largos: 138;',
        'maximo permitido: 137.'
      )
  }
  Registrar-Prueba 'metodos: fallo por riesgo individual' {
    $resultado = Ejecutar-Script `
      -Ruta $rutaMetodos `
      -Argumentos @(
        '-Raiz', $raizMetodos,
        '-UmbralLineas', '120',
        '-MaximoMetodosLargos', '1',
        '-MaximoLineasPorMetodo', '130',
        '-MaximoRiesgoPorMetodo', '137'
      )
    Confirmar-Resultado `
      -Resultado $resultado `
      -Codigo 1 `
      -Textos @(
        'Riesgo del metodo mas expuesto (MetodoLargo): 138;',
        'maximo permitido: 137.'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizMetodos
}

$raizInterfaces = Nueva-RaizPrueba
try {
  Agregar-CasosInterfaces -Raiz $raizInterfaces
  Agregar-ContratosSinUniDAC -Raiz $raizInterfaces
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
        'Unidades analizadas: 10;'
      )
  }
}
finally {
  Borrar-RaizPrueba -Ruta $raizInterfaces
}

$raizRetirados = Nueva-RaizPrueba
try {
  Agregar-ContratosSinUniDAC -Raiz $raizRetirados
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
        '-OmitirLineaBasePorUnidad',
        '-MaximoExit', '0',
        '-MaximoContinue', '0',
        '-MaximoWith', '0',
        '-MaximoLineasAnchas', '0',
        '-MaximoLineasConTabulador', '0'
      )
    Confirmar-Resultado `
      -Resultado $resultadoEstilo `
      -Codigo 0 `
      -Textos @(
        'Exit: 0.',
        'Continue: 0.',
        'With: 0.',
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
