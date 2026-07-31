param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$archivosCriticos = @(
  'src\DataModules\UniDataFacturas.pas',
  'src\DataModules\UniDataAlbaranes.pas',
  'src\DataModules\UniDataComprasSesionesAlbaranes.pas',
  'src\DataModules\UniDataComprasSesionesArticulos.pas',
  'src\DataModules\UniDataComprasSesionesDocumentosComun.pas',
  'src\DataModules\UniDataComprasSesionesEstado.pas',
  'src\DataModules\UniDataComprasSesionesPedidos.pas',
  'src\DataModules\UniDataComprasSesionesReversion.pas',
  'src\Caja\DataModules\UniDataCaja.pas',
  'src\Lib\inLibFacturasMovimientos.pas'
)
$infracciones = [System.Collections.Generic.List[string]]::new()
$clasificaciones = @{
  ValorExterno = 0
  IdentificadorListaBlanca = 0
  LiteralFijo = 0
}

function Obtener-Linea {
  param(
    [string]$Contenido,
    [int]$Indice
  )
  return (
    [regex]::Matches($Contenido.Substring(0, $Indice), "`n")
  ).Count + 1
}

function Obtener-FinSentenciaPascal {
  param(
    [string]$Contenido,
    [int]$Inicio
  )
  $enCadena = $false
  $indice = $Inicio
  while ($indice -lt $Contenido.Length) {
    $caracter = $Contenido[$indice]
    if ($caracter -eq "'") {
      if ($enCadena -and
          ($indice + 1 -lt $Contenido.Length) -and
          ($Contenido[$indice + 1] -eq "'")) {
        $indice += 2
      }
      else {
        $enCadena = -not $enCadena
        $indice++
      }
    }
    elseif (($caracter -eq ';') -and (-not $enCadena)) {
      return $indice
    }
    elseif ((-not $enCadena) -and
            ($caracter -eq "`n") -and
            ($Contenido.Substring($indice) -match
             '^\n\s*else\b')) {
      return $indice
    }
    else {
      $indice++
    }
  }
  return $Contenido.Length - 1
}

function Quitar-CadenasPascal {
  param([string]$Expresion)
  $resultado = [regex]::Replace(
    $Expresion,
    "'(?:''|[^'])*'",
    ' ')
  $resultado = [regex]::Replace(
    $resultado,
    '(?m)//[^\r\n]*',
    ' ')
  return $resultado
}

function Obtener-BloqueMetodo {
  param(
    [string]$Contenido,
    [string]$Nombre
  )
  $patronInicio =
    '(?im)^(?:class\s+)?(?:procedure|function)\s+' +
    [regex]::Escape($Nombre) +
    '\b'
  $inicios = [regex]::Matches($Contenido, $patronInicio)
  if ($inicios.Count -eq 0) {
    return $null
  }
  $inicio = $inicios[$inicios.Count - 1]
  $resto = $Contenido.Substring($inicio.Index + $inicio.Length)
  $siguiente = [regex]::Match(
    $resto,
    '(?im)^(?:class\s+)?(?:procedure|function|' +
    'constructor|destructor)\s+[A-Za-z_][A-Za-z0-9_.]*\b')
  if ($siguiente.Success) {
    return $Contenido.Substring(
      $inicio.Index,
      $inicio.Length + $siguiente.Index)
  }
  return $Contenido.Substring($inicio.Index)
}

function Agregar-Infraccion {
  param(
    [string]$Ruta,
    [int]$Linea,
    [string]$Mensaje
  )
  $infracciones.Add("${Ruta}:${Linea} $Mensaje")
}

$asignacionesVariablesPermitidas = @{
  'src\DataModules\UniDataAlbaranes.pas|SqlInsertAlbaran' =
    'IdentificadorListaBlanca'
  'src\DataModules\UniDataAlbaranes.pas|SqlUpdateAlbaran' =
    'IdentificadorListaBlanca'
  'src\DataModules\UniDataAlbaranes.pas|sSql' =
    'LiteralFijo'
  'src\DataModules\UniDataComprasSesionesReversion.pas|ASql' =
    'LiteralFijo'
  'src\Caja\DataModules\UniDataCaja.pas|SQLStr' =
    'LiteralFijo'
}

foreach ($rutaRelativa in $archivosCriticos) {
  $ruta = Join-Path $Raiz $rutaRelativa
  $contenido = Get-Content -LiteralPath $ruta -Raw
  foreach ($quoted in [regex]::Matches($contenido, '\bQuotedStr\s*\(')) {
    Agregar-Infraccion `
      -Ruta $rutaRelativa `
      -Linea (Obtener-Linea $contenido $quoted.Index) `
      -Mensaje (
        'valor concatenado con QuotedStr; usar un parámetro SQL.')
  }
  foreach ($adicion in [regex]::Matches(
    $contenido,
    '(?i)\bSQL\.(?:Add|Append)\s*\(')) {
    Agregar-Infraccion `
      -Ruta $rutaRelativa `
      -Linea (Obtener-Linea $contenido $adicion.Index) `
      -Mensaje (
        'SQL.Add/Append elude la clasificación; usar una asignación Text.')
  }
  $patronAsignacion =
    '(?im)\b(?:[A-Za-z_][A-Za-z0-9_]*\.)?' +
    'SQL(?:Insert|Update|Delete|Refresh|Lock)?\.Text\s*:='
  foreach ($asignacion in [regex]::Matches(
    $contenido,
    $patronAsignacion)) {
    $inicioExpresion = $asignacion.Index + $asignacion.Length
    $finExpresion = Obtener-FinSentenciaPascal `
      -Contenido $contenido `
      -Inicio $inicioExpresion
    $expresion = $contenido.Substring(
      $inicioExpresion,
      $finExpresion - $inicioExpresion)
    $sinCadenas = Quitar-CadenasPascal -Expresion $expresion
    $resto = [regex]::Replace($sinCadenas, '[\s+()]', '')
    $resto = [regex]::Replace($resto, '(?i)sLineBreak', '')
    $linea = Obtener-Linea $contenido $asignacion.Index
    if ($resto -eq '') {
      $clasificaciones.LiteralFijo++
    }
    elseif ($sinCadenas -match
      '\b(QuotedStr|Format|FieldByName|AsString|IntToStr)\b') {
      $clasificaciones.ValorExterno++
      Agregar-Infraccion `
        -Ruta $rutaRelativa `
        -Linea $linea `
        -Mensaje (
          'valor externo concatenado en SQL; debe ser un parámetro.')
    }
    elseif (($rutaRelativa -eq
             'src\DataModules\UniDataFacturas.pas') -and
            ($sinCadenas -match '\bsCampos\b')) {
      $metodo = Obtener-BloqueMetodo `
        -Contenido $contenido `
        -Nombre 'TdmFacturas.PrepararCabeceraSinCamposComplejos'
      if ($metodo -notmatch '\bDelimitarIdentificadorSql\b') {
        Agregar-Infraccion `
          -Ruta $rutaRelativa `
          -Linea $linea `
          -Mensaje 'identificador dinámico sin lista blanca.'
      }
      else {
        $clasificaciones.IdentificadorListaBlanca++
      }
    }
    elseif ($resto -match '^[A-Za-z_][A-Za-z0-9_]*$') {
      $clave = "$rutaRelativa|$resto"
      if ($asignacionesVariablesPermitidas.ContainsKey($clave)) {
        $tipo = $asignacionesVariablesPermitidas[$clave]
        $clasificaciones[$tipo]++
      }
      else {
        Agregar-Infraccion `
          -Ruta $rutaRelativa `
          -Linea $linea `
          -Mensaje (
            "SQL dinámico no clasificado ($resto).")
      }
    }
    else {
      Agregar-Infraccion `
        -Ruta $rutaRelativa `
        -Linea $linea `
        -Mensaje 'concatenación SQL dinámica no clasificada.'
    }
  }
}

$listasBlancas = @(
  @{
    Ruta = 'src\DataModules\UniDataFacturas.pas'
    Metodo = 'TdmFacturas.PrepararCabeceraSinCamposComplejos'
  },
  @{
    Ruta = 'src\DataModules\UniDataFacturas.pas'
    Metodo = 'TdmFacturas.QuitarCampoComplejoCabecera'
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Metodo = 'SqlInsertAlbaran'
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Metodo = 'SqlUpdateAlbaran'
  }
)
foreach ($objetivo in $listasBlancas) {
  $ruta = Join-Path $Raiz $objetivo.Ruta
  $contenido = Get-Content -LiteralPath $ruta -Raw
  $metodo = Obtener-BloqueMetodo `
    -Contenido $contenido `
    -Nombre $objetivo.Metodo
  if (($null -eq $metodo) -or
      ($metodo -notmatch '\bDelimitarIdentificadorSql\b')) {
    Agregar-Infraccion `
      -Ruta $objetivo.Ruta `
      -Linea 1 `
      -Mensaje (
        "$($objetivo.Metodo) debe validar sus identificadores.")
  }
}

$coordinadores = @(
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Metodo = 'TMaterializadorComprasSesiones.Ejecutar'
    Marcas = @(
      'FUnidadTrabajo.Iniciar',
      'FUnidadTrabajo.Confirmar',
      'FUnidadTrabajo.Revertir'
    )
  },
  @{
    Ruta = 'src\Lib\inLibComprasSesionesMaterializar.pas'
    Metodo = 'TRevertidorComprasSesiones.Ejecutar'
    Marcas = @(
      'FUnidadTrabajo.Iniciar',
      'FUnidadTrabajo.Confirmar',
      'FUnidadTrabajo.Revertir'
    )
  },
  @{
    Ruta = 'src\DataModules\UniDataFacturas.pas'
    Metodo = 'TdmFacturas.ProcesarFacturaPosteada'
    Marcas = @('StartTransaction', 'Commit', 'Rollback')
  },
  @{
    Ruta = 'src\Lib\inLibFacturasConsolidacion.pas'
    Metodo = 'TServicioConsolidacionFactura.Consolidar'
    Marcas = @(
      'StartTransaction',
      'FServicioEmision.Emitir',
      'FServicioMovimientos.GenerarSalidas',
      'Commit',
      'Rollback'
    )
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Metodo = 'TdmAlbaranes.ProcesarLineasPosteadas'
    Marcas = @('StartTransaction', 'Commit', 'Rollback')
  },
  @{
    Ruta = 'src\Caja\DataModules\UniDataCaja.pas'
    Metodo = 'TGrabacionFacturaCaja.Ejecutar'
    Marcas = @(
      'IniciarTransaccion',
      'ConfirmarTransaccion',
      'RevertirTransaccion'
    )
  },
  @{
    Ruta = 'src\Lib\inLibFacturasMovimientos.pas'
    Metodo = 'TServicioMovimientosFactura.GenerarSalidas'
    Marcas = @('StartTransaction', 'Commit', 'Rollback')
  }
)
foreach ($objetivo in $coordinadores) {
  $ruta = Join-Path $Raiz $objetivo.Ruta
  $contenido = Get-Content -LiteralPath $ruta -Raw
  $metodo = Obtener-BloqueMetodo `
    -Contenido $contenido `
    -Nombre $objetivo.Metodo
  if ($null -eq $metodo) {
    Agregar-Infraccion `
      -Ruta $objetivo.Ruta `
      -Linea 1 `
      -Mensaje "no se encontró $($objetivo.Metodo)."
  }
  else {
    foreach ($marca in $objetivo.Marcas) {
      $patronMarca = [regex]::Escape($marca)
      if ($metodo -notmatch "\b$patronMarca\b") {
        Agregar-Infraccion `
          -Ruta $objetivo.Ruta `
          -Linea 1 `
          -Mensaje (
            "$($objetivo.Metodo) no hace visible $marca.")
      }
    }
  }
}

$eventosDelgados = @(
  @{
    Ruta = 'src\DataModules\UniDataFacturas.pas'
    Metodo = 'TdmFacturas.unqryFacAfterPost'
    Delegado = 'ProcesarFacturaPosteada'
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Metodo = 'TdmAlbaranes.unqryTablaGAfterPost'
    Delegado = 'ProcesarCabeceraPosteada'
  },
  @{
    Ruta = 'src\DataModules\UniDataAlbaranes.pas'
    Metodo = 'TdmAlbaranes.unqryAlbaranesLineasAfterPost'
    Delegado = 'ProcesarLineasPosteadas'
  },
  @{
    Ruta = 'src\Forms\inMtoFacturasBase.pas'
    Metodo = 'TControladorFacturas.btnConsolidarClick'
    Delegado = 'Servicio.Consolidar'
  }
)
foreach ($objetivo in $eventosDelgados) {
  $ruta = Join-Path $Raiz $objetivo.Ruta
  $contenido = Get-Content -LiteralPath $ruta -Raw
  $metodo = Obtener-BloqueMetodo `
    -Contenido $contenido `
    -Nombre $objetivo.Metodo
  $patronDelegado = [regex]::Escape($objetivo.Delegado)
  if (($null -eq $metodo) -or
      ($metodo -notmatch "\b$patronDelegado\b")) {
    Agregar-Infraccion `
      -Ruta $objetivo.Ruta `
      -Linea 1 `
      -Mensaje (
        "$($objetivo.Metodo) debe delegar en $($objetivo.Delegado).")
  }
  elseif ($metodo -match
    '\b(StartTransaction|Commit|Rollback|ExecSQL|ExecProc)\b') {
    Agregar-Infraccion `
      -Ruta $objetivo.Ruta `
      -Linea 1 `
      -Mensaje "$($objetivo.Metodo) contiene lógica empresarial."
  }
}

$plantillaResumen =
  'Clasificación SQL: {0} literales fijos, {1} identificadores con ' +
  'lista blanca y {2} valores externos concatenados.'
$resumen = $plantillaResumen -f
  $clasificaciones.LiteralFijo,
  $clasificaciones.IdentificadorListaBlanca,
  $clasificaciones.ValorExterno
Write-Host $resumen
if ($infracciones.Count -gt 0) {
  $infracciones | ForEach-Object { Write-Error $_ }
  throw "SQL/transacciones: $($infracciones.Count) infracciones."
}
Write-Host 'SQL, transacciones y eventos críticos: OK.'
