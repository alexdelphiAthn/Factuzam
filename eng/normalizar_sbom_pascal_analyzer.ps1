[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$RutaSbom,
  [Parameter(Mandatory)]
  [string]$RutaSecurity,
  [Parameter(Mandatory)]
  [string]$RutaStatus,
  [Parameter(Mandatory)]
  [string]$RaizProyecto,
  [Parameter(Mandatory)]
  [string]$UniDacRoot,
  [Parameter(Mandatory)]
  [ValidateSet('Win32', 'Win64')]
  [string]$Plataforma
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ReferenciaRaiz = 'urn:factuzam:application:fzam'
$NombrePropiedadClasificacion = 'factuzam:component:classification'
$ReferenciaUniDacBase = 'urn:factuzam:component:devart:unidac'
$ReferenciaDacBase = 'urn:factuzam:component:devart:dac'
$SubcarpetasTerceros = @(
  'src\Lib3par',
  'src\3rdpartyComp',
  'src\Lib\sqlformatter',
  'src\vcl37'
)
$UnidadesDacNoCargadas = @(
  'DAScript',
  'DASQLMonitor',
  'DBAccess',
  'MemDS',
  'VirtualTable'
)
$UnidadesUniDacNoCargadas = @(
  'MySQLUniProvider',
  'PostgreSQLUniProvider',
  'Uni',
  'UniScript',
  'UniSQLMonitor'
)
$UnidadesDevartNoCargadas = @(
  'DAScript',
  'DASQLMonitor',
  'DBAccess',
  'MemDS',
  'MySQLUniProvider',
  'PostgreSQLUniProvider',
  'Uni',
  'UniScript',
  'UniSQLMonitor',
  'VirtualTable'
)

function Tiene-Propiedad {
  param(
    [AllowNull()]
    [object]$Objeto,
    [string]$Nombre
  )

  return (
    ($null -ne $Objeto) -and
    ($null -ne $Objeto.PSObject.Properties[$Nombre]))
}

function Establecer-Campo {
  param(
    [object]$Objeto,
    [string]$Nombre,
    [AllowNull()]
    [object]$Valor
  )

  if (Tiene-Propiedad $Objeto $Nombre) {
    $Objeto.PSObject.Properties[$Nombre].Value = $Valor
  }
  else {
    $Objeto | Add-Member -NotePropertyName $Nombre -NotePropertyValue $Valor
  }
}

function Obtener-RutaArchivo {
  param(
    [string]$Ruta,
    [string]$Descripcion
  )

  if ([string]::IsNullOrWhiteSpace($Ruta) -or
      -not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
    throw "$Descripcion no existe: $Ruta"
  }
  return (Resolve-Path -LiteralPath $Ruta).Path
}

function Obtener-RutaDirectorio {
  param(
    [string]$Ruta,
    [string]$Descripcion
  )

  if ([string]::IsNullOrWhiteSpace($Ruta) -or
      -not (Test-Path -LiteralPath $Ruta -PathType Container)) {
    throw "$Descripcion no existe: $Ruta"
  }
  return (Resolve-Path -LiteralPath $Ruta).Path.TrimEnd('\')
}

function Normalizar-Ruta {
  param([string]$Ruta)

  if ([string]::IsNullOrWhiteSpace($Ruta) -or
      -not [IO.Path]::IsPathRooted($Ruta)) {
    throw "El SBOM contiene una ruta no absoluta: $Ruta"
  }
  return [IO.Path]::GetFullPath($Ruta)
}

function Ruta-EstaDentroDe {
  param(
    [string]$Ruta,
    [string]$Raiz
  )

  $rutaNormalizada = [IO.Path]::GetFullPath($Ruta).TrimEnd('\')
  $raizNormalizada = [IO.Path]::GetFullPath($Raiz).TrimEnd('\')
  return (
    ($rutaNormalizada -ieq $raizNormalizada) -or
    $rutaNormalizada.StartsWith(
      "$raizNormalizada\",
      [StringComparison]::OrdinalIgnoreCase))
}

function Obtener-RutaComponente {
  param(
    [object]$Componente,
    [switch]$PermitirAusente
  )

  $rutas = @()
  if (Tiene-Propiedad $Componente 'properties') {
    $rutas = @(
      $Componente.properties |
        Where-Object {
          (Tiene-Propiedad $_ 'name') -and
          ([string]$_.name -ceq 'path')
        } |
        ForEach-Object {
          if (-not (Tiene-Propiedad $_ 'value')) {
            throw 'Una propiedad path no contiene value.'
          }
          [string]$_.value
        })
  }

  if ($rutas.Count -eq 0 -and $PermitirAusente) {
    return ''
  }
  if ($rutas.Count -ne 1) {
    $referencia = if (Tiene-Propiedad $Componente 'bom-ref') {
      [string]$Componente.'bom-ref'
    }
    else {
      '<sin bom-ref>'
    }
    throw (
      "El componente $referencia debe contener una unica propiedad path; " +
      "contiene $($rutas.Count).")
  }
  return (Normalizar-Ruta $rutas[0])
}

function Establecer-PropiedadComponente {
  param(
    [object]$Componente,
    [string]$Nombre,
    [string]$Valor
  )

  $propiedades = @()
  if (Tiene-Propiedad $Componente 'properties') {
    $propiedades = @(
      $Componente.properties |
        Where-Object {
          -not (
            (Tiene-Propiedad $_ 'name') -and
            ([string]$_.name -ceq $Nombre))
        })
  }
  $propiedades += [pscustomobject][ordered]@{
    name = $Nombre
    value = $Valor
  }
  Establecer-Campo $Componente 'properties' @($propiedades)
}

function Establecer-HashSha256 {
  param(
    [object]$Componente,
    [string]$Hash
  )

  if ($Hash -cnotmatch '^[0-9A-F]{64}$') {
    throw "Hash SHA-256 no valido: $Hash"
  }
  $hashes = @()
  if (Tiene-Propiedad $Componente 'hashes') {
    $hashes = @(
      $Componente.hashes |
        Where-Object {
          -not (
            (Tiene-Propiedad $_ 'alg') -and
            ([string]$_.alg -ieq 'SHA-256'))
        })
  }
  $hashes += [pscustomobject][ordered]@{
    alg = 'SHA-256'
    content = $Hash
  }
  Establecer-Campo $Componente 'hashes' @($hashes)
}

function Establecer-LicenciaSpdx {
  param(
    [object]$Componente,
    [string]$Id
  )

  $licencias = @()
  if (Tiene-Propiedad $Componente 'licenses') {
    $licencias = @(
      $Componente.licenses |
        Where-Object {
          -not (
            (Tiene-Propiedad $_ 'license') -and
            (Tiene-Propiedad $_.license 'id') -and
            ([string]$_.license.id -ceq $Id))
        })
  }
  $licencias += [pscustomobject][ordered]@{
    license = [pscustomobject][ordered]@{
      id = $Id
    }
  }
  Establecer-Campo $Componente 'licenses' @($licencias)
}

function Obtener-HashArchivo {
  param([string]$Ruta)

  return (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Obtener-HashTexto {
  param([string]$Texto)

  $algoritmo = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Texto)
    $hash = $algoritmo.ComputeHash($bytes)
    return (($hash | ForEach-Object { $_.ToString('X2') }) -join '')
  }
  finally {
    $algoritmo.Dispose()
  }
}

function Escribir-BytesAtomico {
  param(
    [string]$Ruta,
    [byte[]]$Contenido
  )

  $directorio = Split-Path -Parent $Ruta
  if (-not (Test-Path -LiteralPath $directorio -PathType Container)) {
    throw "No existe el directorio de salida: $directorio"
  }
  $temporal = Join-Path $directorio (
    ".$(Split-Path -Leaf $Ruta).$PID.$([Guid]::NewGuid().ToString('N')).tmp")
  $respaldoTemporal = Join-Path $directorio (
    ".$(Split-Path -Leaf $Ruta).$PID.$([Guid]::NewGuid().ToString('N')).bak")
  try {
    [IO.File]::WriteAllBytes($temporal, $Contenido)
    if (Test-Path -LiteralPath $Ruta -PathType Leaf) {
      [IO.File]::Replace($temporal, $Ruta, $respaldoTemporal)
    }
    else {
      [IO.File]::Move($temporal, $Ruta)
    }
  }
  finally {
    if (Test-Path -LiteralPath $temporal -PathType Leaf) {
      Remove-Item -LiteralPath $temporal -Force
    }
    if (Test-Path -LiteralPath $respaldoTemporal -PathType Leaf) {
      Remove-Item -LiteralPath $respaldoTemporal -Force
    }
  }
}

function Escribir-TextoAtomico {
  param(
    [string]$Ruta,
    [string]$Contenido
  )

  $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Contenido)
  Escribir-BytesAtomico $Ruta $bytes
}

function Preservar-ArchivoRaw {
  param(
    [string]$Origen,
    [string]$Destino
  )

  if (Test-Path -LiteralPath $Destino) {
    if (-not (Test-Path -LiteralPath $Destino -PathType Leaf)) {
      throw "La copia raw no es un archivo: $Destino"
    }
    $origenInfo = Get-Item -LiteralPath $Origen
    $destinoInfo = Get-Item -LiteralPath $Destino
    $coincide = (
      ($origenInfo.Length -eq $destinoInfo.Length) -and
      ((Obtener-HashArchivo $Origen) -ceq (Obtener-HashArchivo $Destino)))
    if (-not $coincide) {
      throw (
        'La copia raw existente no corresponde al informe de entrada: ' +
        $Destino)
    }
    return
  }
  Escribir-BytesAtomico $Destino ([IO.File]::ReadAllBytes($Origen))
}

function Convertir-AJsonDeterminista {
  param([object]$Objeto)

  $json = ConvertTo-Json -InputObject $Objeto -Depth 100
  $json = $json.Replace("`r`n", "`n").Replace("`n", "`r`n")
  return $json
}

function Leer-UnidadesNoCargadas {
  param([string]$Ruta)

  $lineas = [IO.File]::ReadAllLines($Ruta)
  $indices = @(
    for ($i = 0; $i -lt $lineas.Count; $i++) {
      if ($lineas[$i] -match '^Not loaded files \((\d+)\):\s*(.*)$') {
        $i
      }
    })
  if ($indices.Count -ne 1) {
    throw (
      'Status.txt debe contener una unica seccion Not loaded files; ' +
      "se encontraron $($indices.Count).")
  }

  $indice = $indices[0]
  [void]($lineas[$indice] -match '^Not loaded files \((\d+)\):\s*(.*)$')
  $cantidadDeclarada = [int]$Matches[1]
  $unidades = [System.Collections.Generic.List[string]]::new()
  $primera = $Matches[2].Trim()
  if ($primera -ne '') {
    $unidades.Add($primera)
  }
  for ($i = $indice + 1; $i -lt $lineas.Count; $i++) {
    if ([string]::IsNullOrWhiteSpace($lineas[$i])) {
      break
    }
    if ($lineas[$i] -notmatch '^\s+(.+?)\s*$') {
      throw "Linea inesperada en Not loaded files: $($lineas[$i])"
    }
    $unidades.Add($Matches[1])
  }
  if ($unidades.Count -ne $cantidadDeclarada) {
    throw (
      'Status.txt declara ' + $cantidadDeclarada +
      " unidades no cargadas, pero se leyeron $($unidades.Count).")
  }
  return [string[]]$unidades
}

function Reparar-MetadatosPascalAnalyzer {
  param([object]$Sbom)

  if (-not (Tiene-Propiedad $Sbom 'metadata') -or
      -not (Tiene-Propiedad $Sbom.metadata 'tools')) {
    throw 'El SBOM no contiene metadata.tools de Pascal Analyzer.'
  }

  $contenedoresHerramientas = @($Sbom.metadata.tools)
  if ($contenedoresHerramientas.Count -ne 1 -or
      -not (Tiene-Propiedad $contenedoresHerramientas[0] 'components')) {
    throw 'metadata.tools no tiene la forma esperada de Pascal Analyzer.'
  }
  $contenedorHerramientas = $contenedoresHerramientas[0]

  # PAL 9.21.5 envuelve el objeto moderno tools en un array. CycloneDX 1.7
  # admite el objeto moderno o el array legacy, pero no esa combinacion.
  if ($Sbom.metadata.tools -is [Array]) {
    Establecer-Campo $Sbom.metadata 'tools' $contenedorHerramientas
  }

  $herramientas = @(
    $contenedorHerramientas.components |
      Where-Object {
        (Tiene-Propiedad $_ 'name') -and
        ([string]$_.name -like 'Pascal Analyzer*')
      })
  if ($herramientas.Count -ne 1) {
    throw (
      'Se esperaba una unica herramienta Pascal Analyzer en metadata.tools; ' +
      "se encontraron $($herramientas.Count).")
  }

  $licencias = @($herramientas[0].licenses)
  if ($licencias.Count -ne 1 -or
      -not (Tiene-Propiedad $licencias[0] 'license')) {
    throw 'La licencia de Pascal Analyzer no tiene la forma esperada.'
  }
  $licencia = $licencias[0].license
  if (Tiene-Propiedad $licencia 'expression') {
    if ([string]$licencia.expression -cne 'UNLICENSED' -or
        -not (Tiene-Propiedad $licencia 'name') -or
        [string]$licencia.name -cne 'Commercial (not open-source)') {
      throw 'La licencia no estandar de Pascal Analyzer ha cambiado.'
    }

    # PAL 9.21.5 escribe expression dentro de license, combinacion que no
    # admite el esquema CycloneDX. El nombre comercial ya conserva el dato
    # correcto y UNLICENSED no aporta una licencia SPDX aplicable.
    $licencia.PSObject.Properties.Remove('expression')
  }

  $herramienta = $herramientas[0]
  if (-not (Tiene-Propiedad $herramienta 'supplier') -or
      -not (Tiene-Propiedad $herramienta.supplier 'url')) {
    throw 'El proveedor de Pascal Analyzer no contiene la URL esperada.'
  }
  if ($herramienta.supplier.url -is [string]) {
    if ([string]$herramienta.supplier.url -cne 'https://peganza.com') {
      throw 'La URL del proveedor de Pascal Analyzer ha cambiado.'
    }

    # organizationalEntity.url es un array en CycloneDX 1.7; PAL lo emite
    # como una cadena escalar.
    Establecer-Campo `
      $herramienta.supplier `
      'url' `
      ([string[]]@([string]$herramienta.supplier.url))
  }
}

function Validar-UnidadesDevart {
  param([string[]]$Unidades)

  if ($Unidades.Count -ne $UnidadesDevartNoCargadas.Count) {
    throw (
      'Las unidades no cargadas no coinciden con el conjunto UniDAC ' +
      "esperado: $($Unidades -join ', ').")
  }
  for ($i = 0; $i -lt $UnidadesDevartNoCargadas.Count; $i++) {
    if ($Unidades[$i] -ine $UnidadesDevartNoCargadas[$i]) {
      throw (
        'Las unidades no cargadas no coinciden con el conjunto UniDAC ' +
        "esperado: $($Unidades -join ', ').")
    }
  }
}

function Obtener-RutaLogicaComponente {
  param(
    [string]$Ruta,
    [string]$Raiz,
    [string]$Hash
  )

  if (Ruta-EstaDentroDe $Ruta $Raiz) {
    $rutaNormalizada = [IO.Path]::GetFullPath($Ruta)
    $raizNormalizada = [IO.Path]::GetFullPath($Raiz).TrimEnd('\')
    if ($rutaNormalizada.Length -le $raizNormalizada.Length) {
      throw "No se pudo obtener una ruta logica del proyecto para $Ruta."
    }
    $relativa = $rutaNormalizada.Substring(
      $raizNormalizada.Length + 1).Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($relativa) -or
        $relativa -eq '.' -or
        $relativa.StartsWith('../', [StringComparison]::Ordinal)) {
      throw "No se pudo obtener una ruta logica del proyecto para $Ruta."
    }
    return $relativa
  }

  if ($Hash -cnotmatch '^[0-9A-F]{64}$') {
    throw "No se puede sanear una ruta externa sin SHA-256: $Ruta"
  }
  $nombre = [IO.Path]::GetFileName($Ruta)
  if ([string]::IsNullOrWhiteSpace($nombre)) {
    $nombre = 'component'
  }
  $nombre = [regex]::Replace($nombre, '[^A-Za-z0-9._-]', '_')
  return "third-party/sha256/$($Hash.ToLowerInvariant())/$nombre"
}

function Obtener-ValorPropiedadComponente {
  param(
    [object]$Componente,
    [string]$Nombre,
    [switch]$PermitirAusente
  )

  $valores = @()
  if (Tiene-Propiedad $Componente 'properties') {
    $valores = @(
      $Componente.properties |
        Where-Object {
          (Tiene-Propiedad $_ 'name') -and
          ([string]$_.name -ceq $Nombre)
        } |
        ForEach-Object {
          if (-not (Tiene-Propiedad $_ 'value')) {
            throw "La propiedad $Nombre no contiene value."
          }
          [string]$_.value
        })
  }
  if ($valores.Count -eq 0 -and $PermitirAusente) {
    return ''
  }
  if ($valores.Count -ne 1) {
    throw (
      "El componente debe contener una unica propiedad $Nombre; " +
      "contiene $($valores.Count).")
  }
  return $valores[0]
}

function Obtener-DigestArtefactos {
  param([System.Collections.Generic.List[object]]$Artefactos)

  if ($Artefactos.Count -eq 0) {
    throw 'No se puede calcular el digest de un conjunto vacio de artefactos.'
  }
  Ordenar-ArtefactosPorNombreOrdinal $Artefactos
  $material = (
    (($Artefactos |
          ForEach-Object { "$($_.Nombre)=$($_.Hash)" }) -join "`n") + "`n")
  return (Obtener-HashTexto $material)
}

function Ordenar-ArtefactosPorNombreOrdinal {
  param([System.Collections.Generic.List[object]]$Artefactos)

  $comparacion = [System.Comparison[object]]{
    param([object]$Izquierdo, [object]$Derecho)

    return [StringComparer]::Ordinal.Compare(
      [string]$Izquierdo.Nombre,
      [string]$Derecho.Nombre)
  }
  $Artefactos.Sort($comparacion)
  for ($i = 1; $i -lt $Artefactos.Count; $i++) {
    if ([StringComparer]::Ordinal.Equals(
        [string]$Artefactos[$i - 1].Nombre,
        [string]$Artefactos[$i].Nombre)) {
      throw "Nombre logico de artefacto duplicado: $($Artefactos[$i].Nombre)"
    }
  }
}

function Buscar-BinarioUniDac {
  param(
    [string]$Raiz,
    [string]$Nombre,
    [string]$Arquitectura
  )

  $padre = Split-Path -Parent $Raiz
  $candidatos = @(
    (Join-Path $Raiz "Bin\$Arquitectura\$Nombre"),
    (Join-Path $Raiz "$Arquitectura\$Nombre"),
    (Join-Path $padre "Bin\$Arquitectura\$Nombre")
  )
  $conjuntoEncontrados = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase)
  foreach ($candidato in $candidatos) {
    if (Test-Path -LiteralPath $candidato -PathType Leaf) {
      [void]$conjuntoEncontrados.Add(
        (Resolve-Path -LiteralPath $candidato).Path)
    }
  }
  $encontrados = @($conjuntoEncontrados)
  if ($encontrados.Count -ne 1) {
    throw (
      "Se esperaba encontrar una vez $Nombre para $Arquitectura; " +
      "se encontraron $($encontrados.Count).")
  }
  return $encontrados[0]
}

function Obtener-VersionBinario {
  param([string]$Ruta)

  $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($Ruta)
  $version = [string]$info.ProductVersion
  if ([string]::IsNullOrWhiteSpace($version)) {
    $version = [string]$info.FileVersion
  }
  $version = $version.Trim()
  if ($version -notmatch '^\d+(\.\d+)+$') {
    throw "No se pudo obtener una version numerica de ${Ruta}: $version"
  }
  return $version
}

function Agregar-ReferenciasBom {
  param(
    [AllowNull()]
    [object]$Nodo,
    [System.Collections.Generic.HashSet[string]]$Referencias,
    [string]$RutaLogica
  )

  if ($null -eq $Nodo -or
      $Nodo -is [string] -or
      $Nodo -is [ValueType]) {
    return
  }
  if ($Nodo -is [System.Collections.IEnumerable] -and
      -not ($Nodo -is [System.Collections.IDictionary])) {
    $indice = 0
    foreach ($elemento in $Nodo) {
      Agregar-ReferenciasBom $elemento $Referencias "$RutaLogica[$indice]"
      $indice++
    }
    return
  }

  $propiedadRef = $Nodo.PSObject.Properties['bom-ref']
  if ($null -ne $propiedadRef) {
    $referencia = [string]$propiedadRef.Value
    if ([string]::IsNullOrWhiteSpace($referencia)) {
      throw "bom-ref vacio en $RutaLogica."
    }
    if (-not $Referencias.Add($referencia)) {
      throw "bom-ref duplicado en el documento: $referencia"
    }
  }
  foreach ($propiedad in $Nodo.PSObject.Properties) {
    if ($propiedad.Name -cne 'bom-ref') {
      Agregar-ReferenciasBom (
        $propiedad.Value) $Referencias "$RutaLogica.$($propiedad.Name)"
    }
  }
}

function Validar-SinRutasAbsolutas {
  param(
    [AllowNull()]
    [object]$Nodo,
    [string]$RutaObjeto
  )

  if ($null -eq $Nodo -or $Nodo -is [ValueType]) {
    return
  }
  if ($Nodo -is [string]) {
    $texto = [string]$Nodo
    $esRutaLocal = (
      [regex]::IsMatch(
        $texto,
        '^[A-Za-z]:',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant) -or
      $texto.StartsWith('\', [StringComparison]::Ordinal) -or
      $texto.StartsWith('/', [StringComparison]::Ordinal) -or
      $texto.StartsWith('file:', [StringComparison]::OrdinalIgnoreCase))
    if ($esRutaLocal) {
      throw "El SBOM normalizado conserva una ruta absoluta en $RutaObjeto."
    }
    return
  }
  if ($Nodo -is [System.Collections.IEnumerable] -and
      -not ($Nodo -is [System.Collections.IDictionary])) {
    $indice = 0
    foreach ($elemento in $Nodo) {
      Validar-SinRutasAbsolutas $elemento "$RutaObjeto[$indice]"
      $indice++
    }
    return
  }
  foreach ($propiedad in $Nodo.PSObject.Properties) {
    Validar-SinRutasAbsolutas `
      $propiedad.Value `
      "$RutaObjeto.$($propiedad.Name)"
  }
}

function Obtener-ClasificacionRuta {
  param(
    [string]$Ruta,
    [string]$Raiz
  )

  if (-not (Ruta-EstaDentroDe $Ruta $Raiz)) {
    return 'third-party'
  }
  foreach ($subcarpetaTerceros in $SubcarpetasTerceros) {
    if (Ruta-EstaDentroDe $Ruta (Join-Path $Raiz $subcarpetaTerceros)) {
      return 'third-party'
    }
  }
  return 'first-party'
}

function Validar-SbomNormalizado {
  param(
    [object]$Sbom,
    [string]$RutaLogicaMain,
    [string]$ReferenciaUniDac,
    [string]$DigestUniDac,
    [string]$ReferenciaDac,
    [string]$DigestDac,
    [System.Collections.Generic.Dictionary[string,string]]$HashesPorReferencia,
    [System.Collections.Generic.Dictionary[string,string]]$RutasPorReferencia,
    [System.Collections.Generic.Dictionary[string,string]]$ClasificacionesPorReferencia,
    [System.Collections.Generic.Dictionary[string,bool]]$ExternalPorReferencia,
    [AllowEmptyString()]
    [string]$ReferenciaMainAnterior
  )

  foreach ($campo in @(
      'bomFormat', 'specVersion', 'metadata', 'components', 'dependencies')) {
    if (-not (Tiene-Propiedad $Sbom $campo)) {
      throw "El SBOM no contiene el campo obligatorio $campo."
    }
  }
  if ([string]$Sbom.bomFormat -cne 'CycloneDX' -or
      [string]$Sbom.specVersion -cne '1.7') {
    throw (
      'El normalizador solo admite CycloneDX 1.7; se encontro ' +
      "$($Sbom.bomFormat) $($Sbom.specVersion).")
  }
  if (-not (Tiene-Propiedad $Sbom.metadata 'component')) {
    throw 'El SBOM normalizado no contiene metadata.component.'
  }
  $raizComponente = $Sbom.metadata.component
  if ([string]$raizComponente.'bom-ref' -cne $ReferenciaRaiz -or
      [string]$raizComponente.type -cne 'application' -or
      [string]$raizComponente.name -cne 'Factuzam') {
    throw 'metadata.component no identifica la aplicacion Factuzam esperada.'
  }
  if ((Obtener-ValorPropiedadComponente $raizComponente 'path') -cne
      $RutaLogicaMain) {
    throw 'metadata.component no contiene la ruta logica de fzam.dpr.'
  }
  if (-not (Tiene-Propiedad $raizComponente 'isExternal') -or
      -not ($raizComponente.isExternal -is [bool]) -or
      [bool]$raizComponente.isExternal) {
    throw 'metadata.component debe declarar isExternal=false.'
  }

  $referenciasGlobales = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal)
  Agregar-ReferenciasBom $Sbom $referenciasGlobales '$'

  $referenciasProducto = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal)
  foreach ($componente in @($Sbom.components) + @($raizComponente)) {
    $referencia = [string]$componente.'bom-ref'
    if (-not $referenciasProducto.Add($referencia)) {
      throw "Componente de producto duplicado: $referencia"
    }
  }
  if (-not $referenciasProducto.Contains($ReferenciaUniDac)) {
    throw 'El componente agregado UniDAC no esta presente.'
  }
  if (-not $referenciasProducto.Contains($ReferenciaDac)) {
    throw 'El componente agregado DAC no esta presente.'
  }

  $referenciasDependencia = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal)
  $dependenciasRaiz = 0
  $dependenciasUniDac = @()
  foreach ($dependencia in $Sbom.dependencies) {
    if (-not (Tiene-Propiedad $dependencia 'ref')) {
      throw 'Una entrada dependencies no contiene ref.'
    }
    $origen = [string]$dependencia.ref
    if ([string]::IsNullOrWhiteSpace($origen) -or
        -not $referenciasProducto.Contains($origen)) {
      throw "Referencia de dependencia no resuelta: '$origen'."
    }
    if ([IO.Path]::IsPathRooted($origen)) {
      throw "dependencies.ref conserva una ruta sin normalizar: $origen"
    }
    if (-not $referenciasDependencia.Add($origen)) {
      throw "dependencies.ref duplicado: $origen"
    }
    if ($origen -ceq $ReferenciaRaiz) {
      $dependenciasRaiz++
    }

    if (Tiene-Propiedad $dependencia 'dependsOn') {
      $destinos = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal)
      foreach ($destinoObjeto in $dependencia.dependsOn) {
        $destino = [string]$destinoObjeto
        if ([string]::IsNullOrWhiteSpace($destino) -or
            -not $referenciasProducto.Contains($destino)) {
          throw (
            "Target de dependencia no resuelto: '$origen' -> '$destino'.")
        }
        if ([IO.Path]::IsPathRooted($destino)) {
          throw "dependsOn conserva una ruta sin normalizar: $destino"
        }
        if (-not $destinos.Add($destino)) {
          throw "Target duplicado: '$origen' -> '$destino'."
        }
        if (-not [string]::IsNullOrWhiteSpace($ReferenciaMainAnterior) -and
            $destino -ceq $ReferenciaMainAnterior) {
          throw "Permanece una referencia al antiguo main: $destino"
        }
      }
      if ($origen -ceq $ReferenciaUniDac) {
        $dependenciasUniDac = @($dependencia.dependsOn)
      }
    }
    if (-not [string]::IsNullOrWhiteSpace($ReferenciaMainAnterior) -and
        $origen -ceq $ReferenciaMainAnterior) {
      throw "Permanece el antiguo main como origen: $origen"
    }
  }
  if ($dependenciasRaiz -ne 1) {
    throw (
      'Debe existir exactamente una entrada dependencies para la raiz; ' +
      "se encontraron $dependenciasRaiz.")
  }
  if ($referenciasDependencia.Count -ne $referenciasProducto.Count) {
    throw (
      'El grafo no contiene exactamente un nodo por componente: ' +
      "$($referenciasDependencia.Count) nodos para " +
      "$($referenciasProducto.Count) componentes.")
  }
  foreach ($referenciaProducto in $referenciasProducto) {
    if (-not $referenciasDependencia.Contains($referenciaProducto)) {
      throw "El componente no tiene nodo dependencies: $referenciaProducto"
    }
  }
  if ($dependenciasUniDac.Count -ne 1 -or
      [string]$dependenciasUniDac[0] -cne $ReferenciaDac) {
    throw 'El nodo UniDAC debe depender exactamente del componente DAC.'
  }

  $composiciones = @($Sbom.compositions)
  if ($composiciones.Count -ne 1 -or
      [string]$composiciones[0].aggregate -cne 'incomplete' -or
      @($composiciones[0].assemblies).Count -ne 1 -or
      [string](@($composiciones[0].assemblies)[0]) -cne $ReferenciaRaiz) {
    throw 'El SBOM debe declarar incompleta la composicion de la raiz Factuzam.'
  }
  $referenciasComposicion = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal)
  foreach ($referenciaComposicion in @($composiciones[0].dependencies)) {
    if (-not $referenciasProducto.Contains([string]$referenciaComposicion) -or
        -not $referenciasComposicion.Add([string]$referenciaComposicion)) {
      throw "Referencia de composicion invalida: $referenciaComposicion"
    }
  }
  if ($referenciasComposicion.Count -ne $referenciasProducto.Count) {
    throw 'La composicion incompleta no cubre todos los nodos de dependencias.'
  }

  $cantidadFicheros = 0
  $cantidadFirstParty = 0
  $cantidadThirdParty = 0
  foreach ($componente in @($Sbom.components) + @($raizComponente)) {
    $referenciaComponente = [string]$componente.'bom-ref'
    if ($HashesPorReferencia.ContainsKey($referenciaComponente)) {
      $cantidadFicheros++
      if (-not $RutasPorReferencia.ContainsKey($referenciaComponente) -or
          -not $ClasificacionesPorReferencia.ContainsKey($referenciaComponente) -or
          -not $ExternalPorReferencia.ContainsKey($referenciaComponente)) {
        throw "Faltan metadatos esperados para $referenciaComponente."
      }
      $rutaLogica = Obtener-ValorPropiedadComponente $componente 'path'
      if ([IO.Path]::IsPathRooted($rutaLogica) -or
          $rutaLogica -cne $RutasPorReferencia[$referenciaComponente]) {
        throw "Ruta logica ausente o incorrecta para $referenciaComponente."
      }
      $hashesSha = @()
      if (Tiene-Propiedad $componente 'hashes') {
        $hashesSha = @(
          $componente.hashes |
            Where-Object {
              (Tiene-Propiedad $_ 'alg') -and
              ([string]$_.alg -ieq 'SHA-256')
            })
      }
      if ($hashesSha.Count -ne 1 -or
          [string]$hashesSha[0].content -cne
            $HashesPorReferencia[$referenciaComponente]) {
        throw "Hash SHA-256 ausente o incorrecto para $rutaLogica."
      }

      $clasificacionEsperada =
        $ClasificacionesPorReferencia[$referenciaComponente]
      $clasificaciones = @(
        $componente.properties |
          Where-Object {
            (Tiene-Propiedad $_ 'name') -and
            ([string]$_.name -ceq $NombrePropiedadClasificacion)
          })
      if ($clasificaciones.Count -ne 1 -or
          [string]$clasificaciones[0].value -cne $clasificacionEsperada) {
        throw "Clasificacion incorrecta para $rutaLogica."
      }
      if ($rutaLogica.StartsWith(
          'src/Lib/sqlformatter/',
          [StringComparison]::OrdinalIgnoreCase)) {
        $licenciasApache = @(
          $componente.licenses |
            Where-Object {
              (Tiene-Propiedad $_ 'license') -and
              (Tiene-Propiedad $_.license 'id') -and
              ([string]$_.license.id -ceq 'Apache-2.0')
            })
        if ($licenciasApache.Count -ne 1) {
          throw "Licencia Apache-2.0 ausente para $rutaLogica."
        }
      }
      $esExternoEsperado = $ExternalPorReferencia[$referenciaComponente]
      if (-not (Tiene-Propiedad $componente 'isExternal') -or
          -not ($componente.isExternal -is [bool]) -or
          [bool]$componente.isExternal -ne $esExternoEsperado) {
        throw "isExternal no conserva la semantica de PAL para $rutaLogica."
      }
      if ($clasificacionEsperada -ceq 'first-party') {
        $cantidadFirstParty++
      }
      else {
        $cantidadThirdParty++
      }
    }
    elseif ($referenciaComponente -ceq $ReferenciaUniDac -or
            $referenciaComponente -ceq $ReferenciaDac) {
      $cantidadThirdParty++
      if (-not (Tiene-Propiedad $componente 'isExternal') -or
          -not ($componente.isExternal -is [bool]) -or
          [bool]$componente.isExternal) {
        throw (
          'Los componentes Devart se compilan en el producto y deben ' +
          'declarar isExternal=false.')
      }
      $digestEsperado = if ($referenciaComponente -ceq $ReferenciaUniDac) {
        $DigestUniDac
      }
      else {
        $DigestDac
      }
      if ((Obtener-ValorPropiedadComponente `
            $componente `
            'factuzam:aggregate:sha256') -cne $digestEsperado) {
        throw "El digest agregado de $($componente.name) es incorrecto."
      }
    }
    elseif ([string]$componente.type -ceq 'file') {
      throw (
        "El componente file $($componente.'bom-ref') no contiene path.")
    }
  }
  if ($cantidadFicheros -ne $HashesPorReferencia.Count) {
    throw (
      "Se validaron $cantidadFicheros ficheros, pero se calcularon " +
      "$($HashesPorReferencia.Count) hashes.")
  }

  Validar-SinRutasAbsolutas $Sbom '$'

  return [pscustomobject][ordered]@{
    Componentes = @($Sbom.components).Count + 1
    Dependencias = @($Sbom.dependencies).Count
    Ficheros = $cantidadFicheros
    FirstParty = $cantidadFirstParty
    ThirdParty = $cantidadThirdParty
  }
}

$RutaSbom = Obtener-RutaArchivo $RutaSbom 'SBOM.json'
$RutaSecurity = Obtener-RutaArchivo $RutaSecurity 'Security.txt'
$RutaStatus = Obtener-RutaArchivo $RutaStatus 'Status.txt'
$RaizProyecto = Obtener-RutaDirectorio $RaizProyecto 'la raiz del proyecto'
$UniDacRoot = Obtener-RutaDirectorio $UniDacRoot 'la raiz de UniDAC'

$rutaMain = Normalizar-Ruta (Join-Path $RaizProyecto 'fzam.dpr')
if (-not (Test-Path -LiteralPath $rutaMain -PathType Leaf)) {
  throw "No existe el programa principal: $rutaMain"
}

$unidadesNoCargadas = Leer-UnidadesNoCargadas $RutaStatus
Validar-UnidadesDevart $unidadesNoCargadas

$rutaUniDacBpl = Buscar-BinarioUniDac `
  $UniDacRoot 'unidac370.bpl' $Plataforma
$rutaDacBpl = Buscar-BinarioUniDac `
  $UniDacRoot 'dac370.bpl' $Plataforma
$versionUniDac = Obtener-VersionBinario $rutaUniDacBpl
$versionDac = Obtener-VersionBinario $rutaDacBpl
$artefactosDac = [System.Collections.Generic.List[object]]::new()
$artefactosUniDac = [System.Collections.Generic.List[object]]::new()
$artefactosDac.Add([pscustomobject][ordered]@{
    Nombre = "bin/$Plataforma/dac370.bpl"
    Ruta = $rutaDacBpl
  })
$artefactosUniDac.Add([pscustomobject][ordered]@{
    Nombre = "bin/$Plataforma/unidac370.bpl"
    Ruta = $rutaUniDacBpl
  })
$directorioDcuUniDac = Join-Path $UniDacRoot $Plataforma
foreach ($unidad in $UnidadesDevartNoCargadas) {
  $rutaDcu = Join-Path $directorioDcuUniDac "$unidad.dcu"
  if (-not (Test-Path -LiteralPath $rutaDcu -PathType Leaf)) {
    throw "No existe la unidad binaria UniDAC esperada: $rutaDcu"
  }
  $artefactoUnidad = [pscustomobject][ordered]@{
      Nombre = "lib/$Plataforma/$unidad.dcu"
      Ruta = (Resolve-Path -LiteralPath $rutaDcu).Path
    }
  if ($UnidadesDacNoCargadas -contains $unidad) {
    $artefactosDac.Add($artefactoUnidad)
  }
  else {
    $artefactosUniDac.Add($artefactoUnidad)
  }
}
foreach ($artefacto in @($artefactosDac) + @($artefactosUniDac)) {
  $artefacto | Add-Member -NotePropertyName Hash -NotePropertyValue (
    Obtener-HashArchivo $artefacto.Ruta)
}
$digestAgregadoDac = Obtener-DigestArtefactos $artefactosDac
$digestAgregadoUniDac = Obtener-DigestArtefactos $artefactosUniDac
$sufijoPlataforma = $Plataforma.ToLowerInvariant()
$referenciaUniDac = "${ReferenciaUniDacBase}:${versionUniDac}:$sufijoPlataforma"
$referenciaDac = "${ReferenciaDacBase}:${versionDac}:$sufijoPlataforma"

$textoSbomEntrada = [IO.File]::ReadAllText($RutaSbom)
try {
  $sbomEntrada = ConvertFrom-Json -InputObject $textoSbomEntrada
}
catch {
  throw "SBOM.json no contiene JSON valido: $($_.Exception.Message)"
}

$yaNormalizado = (
  (Tiene-Propiedad $sbomEntrada 'metadata') -and
  (Tiene-Propiedad $sbomEntrada.metadata 'component') -and
  (Tiene-Propiedad $sbomEntrada.metadata.component 'bom-ref') -and
  ([string]$sbomEntrada.metadata.component.'bom-ref' -ceq $ReferenciaRaiz))

$rutaRawSbom = Join-Path (Split-Path -Parent $RutaSbom) 'SBOM.pal.raw.json'
$rutaRawSecurity = Join-Path (
  (Split-Path -Parent $RutaSecurity)) 'Security.pal.raw.txt'
if ($yaNormalizado) {
  if (-not (Test-Path -LiteralPath $rutaRawSbom -PathType Leaf) -or
      -not (Test-Path -LiteralPath $rutaRawSecurity -PathType Leaf)) {
    throw (
      'El SBOM ya esta normalizado, pero faltan copias raw; no se ' +
      'sobrescribiran los originales de PAL con contenido normalizado.')
  }
  if (-not (Tiene-Propiedad $sbomEntrada 'version') -or
      -not (($sbomEntrada.version -is [int]) -or
            ($sbomEntrada.version -is [long])) -or
      [long]$sbomEntrada.version -lt 1) {
    throw 'El SBOM normalizado no contiene una version documental valida.'
  }
  try {
    $sbom = ConvertFrom-Json -InputObject (
      [IO.File]::ReadAllText($rutaRawSbom))
  }
  catch {
    throw "SBOM.pal.raw.json no contiene JSON valido: $($_.Exception.Message)"
  }
  if ((Tiene-Propiedad $sbom 'metadata') -and
      (Tiene-Propiedad $sbom.metadata 'component') -and
      (Tiene-Propiedad $sbom.metadata.component 'bom-ref') -and
      [string]$sbom.metadata.component.'bom-ref' -ceq $ReferenciaRaiz) {
    throw 'SBOM.pal.raw.json contiene una salida ya normalizada.'
  }
  Establecer-Campo $sbom 'version' ([long]$sbomEntrada.version)
}
else {
  Preservar-ArchivoRaw $RutaSbom $rutaRawSbom
  Preservar-ArchivoRaw $RutaSecurity $rutaRawSecurity
  $sbom = $sbomEntrada
}
Reparar-MetadatosPascalAnalyzer $sbom

foreach ($campo in @(
    'bomFormat', 'specVersion', 'metadata', 'components', 'dependencies')) {
  if (-not (Tiene-Propiedad $sbom $campo)) {
    throw "El SBOM no contiene el campo obligatorio $campo."
  }
}
if ([string]$sbom.bomFormat -cne 'CycloneDX' -or
    [string]$sbom.specVersion -cne '1.7') {
  throw (
    'El normalizador solo admite CycloneDX 1.7; se encontro ' +
    "$($sbom.bomFormat) $($sbom.specVersion).")
}
if (-not $yaNormalizado) {
  if (-not (Tiene-Propiedad $sbom 'version') -or
      -not (($sbom.version -is [int]) -or
            ($sbom.version -is [long])) -or
      [long]$sbom.version -lt 1) {
    throw 'El SBOM original no contiene una version documental valida.'
  }
  Establecer-Campo $sbom 'version' ([long]$sbom.version + 1)
}

$comparadorRutas = [StringComparer]::OrdinalIgnoreCase
$referenciasPorRuta = [System.Collections.Generic.Dictionary[string,string]]::new(
  $comparadorRutas)
$componentesPorReferencia = @{}
foreach ($componente in $sbom.components) {
  if (-not (Tiene-Propiedad $componente 'bom-ref')) {
    throw 'Un componente no contiene bom-ref.'
  }
  $referencia = [string]$componente.'bom-ref'
  if ([string]::IsNullOrWhiteSpace($referencia) -or
      $componentesPorReferencia.ContainsKey($referencia)) {
    throw "bom-ref de componente vacio o duplicado: '$referencia'."
  }
  $componentesPorReferencia[$referencia] = $componente
  $ruta = Obtener-RutaComponente $componente -PermitirAusente
  if ($ruta -ne '') {
    if ($referenciasPorRuta.ContainsKey($ruta)) {
      throw "Ruta de componente duplicada: $ruta"
    }
    $referenciasPorRuta.Add($ruta, $referencia)
  }
}

$referenciaMainAnterior = ''
if (-not $referenciasPorRuta.ContainsKey($rutaMain)) {
  throw 'SBOM.json no contiene un componente para fzam.dpr.'
}
$referenciaMainAnterior = $referenciasPorRuta[$rutaMain]
$componenteRaiz = $componentesPorReferencia[$referenciaMainAnterior]
$sbom.components = @(
  $sbom.components |
    Where-Object {
      [string]$_.'bom-ref' -cne $referenciaMainAnterior
    })
Establecer-Campo $componenteRaiz 'type' 'application'
Establecer-Campo $componenteRaiz 'bom-ref' $ReferenciaRaiz
Establecer-Campo $componenteRaiz 'name' 'Factuzam'
Establecer-Campo $componenteRaiz 'scope' 'required'
Establecer-Campo $componenteRaiz 'isExternal' $false
Establecer-Campo $sbom.metadata 'component' $componenteRaiz
$referenciasPorRuta[$rutaMain] = $ReferenciaRaiz

foreach ($referenciaDevart in @($referenciaUniDac, $referenciaDac)) {
  if ($componentesPorReferencia.ContainsKey($referenciaDevart)) {
    throw "PAL ya contiene la referencia reservada $referenciaDevart."
  }
}

$componenteUniDac = [pscustomobject][ordered]@{
  type = 'library'
  'bom-ref' = $referenciaUniDac
  supplier = [pscustomobject][ordered]@{
    name = 'Devart'
  }
  publisher = 'Devart'
  group = 'devart'
  name = 'UniDAC'
  version = $versionUniDac
  isExternal = $false
  scope = 'required'
  licenses = @(
    [pscustomobject][ordered]@{
      license = [pscustomobject][ordered]@{
        name = 'Commercial'
      }
    })
  properties = @(
    [pscustomobject][ordered]@{
      name = $NombrePropiedadClasificacion
      value = 'third-party'
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:aggregate:sha256'
      value = $digestAgregadoUniDac
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:aggregate-digest-format'
      value = ('SHA-256 of UTF-8 logical-path=<SHA-256> LF, ' +
        'sorted by path using ordinal comparison')
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:analysis:source-resolution'
      value = 'DCU-only'
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:platform'
      value = $Plataforma
    }) + @(
      $artefactosUniDac |
        ForEach-Object {
          [pscustomobject][ordered]@{
            name = 'factuzam:unidac:artifact'
            value = "$($_.Nombre)|SHA-256|$($_.Hash)"
          }
        })
}

$componenteDac = [pscustomobject][ordered]@{
  type = 'library'
  'bom-ref' = $referenciaDac
  supplier = [pscustomobject][ordered]@{
    name = 'Devart'
  }
  publisher = 'Devart'
  group = 'devart'
  name = 'DAC'
  version = $versionDac
  isExternal = $false
  scope = 'required'
  licenses = @(
    [pscustomobject][ordered]@{
      license = [pscustomobject][ordered]@{
        name = 'Commercial'
      }
    })
  properties = @(
    [pscustomobject][ordered]@{
      name = $NombrePropiedadClasificacion
      value = 'third-party'
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:aggregate:sha256'
      value = $digestAgregadoDac
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:aggregate-digest-format'
      value = ('SHA-256 of UTF-8 logical-path=<SHA-256> LF, ' +
        'sorted by path using ordinal comparison')
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:analysis:source-resolution'
      value = 'DCU-only'
    },
    [pscustomobject][ordered]@{
      name = 'factuzam:platform'
      value = $Plataforma
    }) + @(
      $artefactosDac |
        ForEach-Object {
          [pscustomobject][ordered]@{
            name = 'factuzam:dac:artifact'
            value = "$($_.Nombre)|SHA-256|$($_.Hash)"
          }
        })
}
$sbom.components = @(
  @($sbom.components) + @($componenteUniDac, $componenteDac))

$componentesProducto = @($sbom.components) + @($componenteRaiz)
$referenciasProducto = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal)
foreach ($componente in $componentesProducto) {
  $referencia = [string]$componente.'bom-ref'
  if (-not $referenciasProducto.Add($referencia)) {
    throw "Referencia de componente duplicada tras normalizar: $referencia"
  }
}
$referenciasProductoOrdenadas = [System.Collections.Generic.List[string]]::new()
foreach ($referencia in $referenciasProducto) {
  $referenciasProductoOrdenadas.Add($referencia)
}
$referenciasProductoOrdenadas.Sort([StringComparer]::Ordinal)

$vacios = [System.Collections.Generic.List[object]]::new()
foreach ($dependencia in $sbom.dependencies) {
  if (-not (Tiene-Propiedad $dependencia 'ref')) {
    throw 'Una entrada dependencies no contiene ref.'
  }
  if (Tiene-Propiedad $dependencia 'dependsOn') {
    foreach ($destino in $dependencia.dependsOn) {
      if ([string]$destino -ceq '') {
        $vacios.Add($dependencia)
      }
      elseif ([string]::IsNullOrWhiteSpace([string]$destino)) {
        throw (
          "Target de dependencia en blanco no reconocido: $($dependencia.ref).")
      }
    }
  }
}
if ($vacios.Count -eq 0) {
  throw (
    'Status.txt declara unidades UniDAC no cargadas, pero PAL no produjo ' +
    'ningun target vacio que permita representarlas en el grafo.')
}
else {
  $origenesVacios = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase)
  foreach ($dependencia in $vacios) {
    $origen = [string]$dependencia.ref
    if (-not [IO.Path]::IsPathRooted($origen)) {
      throw "El origen de un target vacio no es una ruta: $origen"
    }
    $rutaOrigen = Normalizar-Ruta $origen
    if (-not (Ruta-EstaDentroDe $rutaOrigen $RaizProyecto)) {
      throw "Un target vacio procede de codigo externo: $rutaOrigen"
    }
    [void]$origenesVacios.Add($rutaOrigen)
  }
}

foreach ($dependencia in $sbom.dependencies) {
  $origen = [string]$dependencia.ref
  if (-not $referenciasProducto.Contains($origen)) {
    if (-not [IO.Path]::IsPathRooted($origen)) {
      throw "dependencies.ref no es ruta ni bom-ref conocido: $origen"
    }
    $rutaOrigen = Normalizar-Ruta $origen
    if (-not $referenciasPorRuta.ContainsKey($rutaOrigen)) {
      throw "No se puede mapear dependencies.ref: $rutaOrigen"
    }
    $origen = $referenciasPorRuta[$rutaOrigen]
    $dependencia.ref = $origen
  }

  if (Tiene-Propiedad $dependencia 'dependsOn') {
    $destinos = @()
    $uniDacAgregado = $false
    foreach ($destinoObjeto in $dependencia.dependsOn) {
      $destino = [string]$destinoObjeto
      if ($destino -ceq '') {
        $destino = $referenciaUniDac
        if ($uniDacAgregado) {
          continue
        }
        $uniDacAgregado = $true
      }
      elseif (-not [string]::IsNullOrWhiteSpace($referenciaMainAnterior) -and
              $destino -ceq $referenciaMainAnterior) {
        $destino = $ReferenciaRaiz
      }
      elseif (-not $referenciasProducto.Contains($destino) -and
              [IO.Path]::IsPathRooted($destino)) {
        $rutaDestino = Normalizar-Ruta $destino
        if (-not $referenciasPorRuta.ContainsKey($rutaDestino)) {
          throw "No se puede mapear dependsOn: $rutaDestino"
        }
        $destino = $referenciasPorRuta[$rutaDestino]
      }
      $destinos += $destino
    }
    $dependencia.dependsOn = @($destinos)
  }
}

$referenciasConNodo = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal)
foreach ($dependencia in $sbom.dependencies) {
  if (-not $referenciasConNodo.Add([string]$dependencia.ref)) {
    throw "dependencies.ref duplicado tras mapear: $($dependencia.ref)"
  }
}
foreach ($referencia in $referenciasProductoOrdenadas) {
  if ($referenciasConNodo.Contains($referencia)) {
    continue
  }
  $destinos = if ($referencia -ceq $referenciaUniDac) {
    @($referenciaDac)
  }
  else {
    @()
  }
  $sbom.dependencies = @($sbom.dependencies) + @(
    [pscustomobject][ordered]@{
      ref = $referencia
      dependsOn = @($destinos)
    })
  [void]$referenciasConNodo.Add($referencia)
}

Establecer-Campo $sbom 'compositions' @(
  [pscustomobject][ordered]@{
    aggregate = 'incomplete'
    assemblies = @($ReferenciaRaiz)
    dependencies = @($referenciasProductoOrdenadas)
  })

$hashesPorReferencia =
  [System.Collections.Generic.Dictionary[string,string]]::new(
    [StringComparer]::Ordinal)
$rutasPorReferencia =
  [System.Collections.Generic.Dictionary[string,string]]::new(
    [StringComparer]::Ordinal)
$clasificacionesPorReferencia =
  [System.Collections.Generic.Dictionary[string,string]]::new(
    [StringComparer]::Ordinal)
$externalPorReferencia =
  [System.Collections.Generic.Dictionary[string,bool]]::new(
    [StringComparer]::Ordinal)
foreach ($componente in @($sbom.components) + @($componenteRaiz)) {
  $ruta = Obtener-RutaComponente $componente -PermitirAusente
  if ($ruta -eq '') {
    continue
  }
  if (-not (Test-Path -LiteralPath $ruta -PathType Leaf)) {
    throw "No se puede calcular SHA-256; falta el fichero $ruta."
  }
  $referencia = [string]$componente.'bom-ref'
  if ($hashesPorReferencia.ContainsKey($referencia)) {
    throw "No se puede calcular SHA-256 dos veces para $referencia."
  }
  $hash = Obtener-HashArchivo $ruta
  $rutaLogica = Obtener-RutaLogicaComponente $ruta $RaizProyecto $hash
  $clasificacion = Obtener-ClasificacionRuta $ruta $RaizProyecto
  if (-not (Tiene-Propiedad $componente 'isExternal')) {
    Establecer-Campo $componente 'isExternal' $false
  }
  elseif (-not ($componente.isExternal -is [bool])) {
    throw "isExternal no es booleano para $ruta."
  }
  $hashesPorReferencia.Add($referencia, $hash)
  $rutasPorReferencia.Add($referencia, $rutaLogica)
  $clasificacionesPorReferencia.Add($referencia, $clasificacion)
  $externalPorReferencia.Add($referencia, [bool]$componente.isExternal)
  Establecer-HashSha256 $componente $hash
  Establecer-PropiedadComponente $componente 'path' $rutaLogica
  Establecer-PropiedadComponente `
    $componente `
    $NombrePropiedadClasificacion `
    $clasificacion
  if (Ruta-EstaDentroDe `
      $ruta (Join-Path $RaizProyecto 'src\Lib\sqlformatter')) {
    Establecer-LicenciaSpdx $componente 'Apache-2.0'
    Establecer-PropiedadComponente `
      $componente `
      'factuzam:third-party:origin' `
      'SQL Formatter / Tim Sinaeve'
  }
  if ([string]$componente.type -ceq 'file') {
    Establecer-Campo $componente 'name' ([IO.Path]::GetFileName($ruta))
  }
}

Establecer-PropiedadComponente `
  $componenteRaiz `
  'factuzam:normalizer' `
  'normalizar_sbom_pascal_analyzer.ps1/2'
Establecer-PropiedadComponente `
  $componenteRaiz `
  'factuzam:analysis:scope' `
  'source-resolution; not reconciled with release artifacts'

$rutaLogicaMain = $rutasPorReferencia[$ReferenciaRaiz]

$estadisticas = Validar-SbomNormalizado `
  $sbom `
  $rutaLogicaMain `
  $referenciaUniDac `
  $digestAgregadoUniDac `
  $referenciaDac `
  $digestAgregadoDac `
  $hashesPorReferencia `
  $rutasPorReferencia `
  $clasificacionesPorReferencia `
  $externalPorReferencia `
  $referenciaMainAnterior

$jsonNormalizado = Convertir-AJsonDeterminista $sbom
try {
  $sbomRoundTrip = ConvertFrom-Json -InputObject $jsonNormalizado
}
catch {
  throw "El JSON serializado no se puede volver a leer: $($_.Exception.Message)"
}
$estadisticasRoundTrip = Validar-SbomNormalizado `
  $sbomRoundTrip `
  $rutaLogicaMain `
  $referenciaUniDac `
  $digestAgregadoUniDac `
  $referenciaDac `
  $digestAgregadoDac `
  $hashesPorReferencia `
  $rutasPorReferencia `
  $clasificacionesPorReferencia `
  $externalPorReferencia `
  $referenciaMainAnterior

foreach ($nombre in @(
    'Componentes', 'Dependencias', 'Ficheros', 'FirstParty', 'ThirdParty')) {
  if ($estadisticas.$nombre -ne $estadisticasRoundTrip.$nombre) {
    throw "El round-trip JSON cambia la estadistica $nombre."
  }
}

$rutaCoverage = Join-Path (
  (Split-Path -Parent $RutaSecurity)) 'Security Coverage.txt'
$lineasCoverage = @(
  'Factuzam - Pascal Analyzer Security Coverage',
  '================================================',
  '',
  'Vulnerability scan: NOT PERFORMED',
  'Vulnerability status: UNKNOWN',
  '',
  'The Pascal Analyzer Security report generates an experimental SBOM.',
  'It does not query a vulnerability database or establish CVE status.',
  '',
  "CycloneDX: $($sbom.bomFormat) $($sbom.specVersion)",
  "Root component: $ReferenciaRaiz",
  "Components: $($estadisticas.Componentes)",
  "Dependency nodes: $($estadisticas.Dependencias)",
  "Files with SHA-256: $($estadisticas.Ficheros)",
  "First-party components: $($estadisticas.FirstParty)",
  "Third-party components: $($estadisticas.ThirdParty)",
  'Unresolved dependency references: 0',
  'Dependency composition: INCOMPLETE (source resolution only)',
  '',
  "UniDAC: $versionUniDac",
  "DAC: $versionDac",
  "UniDAC aggregate SHA-256: $digestAgregadoUniDac",
  "DAC aggregate SHA-256: $digestAgregadoDac",
  'Devart source coverage: DCU-only; UniDAC and DAC are separate components.',
  "UniDAC evidence artifacts: $($artefactosUniDac.Count)",
  "DAC evidence artifacts: $($artefactosDac.Count)",
  '',
  'Not loaded Pascal units:'
)
$lineasCoverage += @(
  $unidadesNoCargadas | ForEach-Object { "- $_" }
)
$lineasCoverage += @(
  '',
  'Classification rule:',
  '- first-party: files below the Factuzam repository root',
  ('- third-party: all other files and vendored sources in ' +
    'src/Lib3par, src/3rdpartyComp, src/Lib/sqlformatter or src/vcl37'),
  '- isExternal: runtime component supplied by the deployment environment',
  '',
  'Sanitized export set: SBOM.json, Security.txt, Security Coverage.txt',
  ('All other Pascal Analyzer reports in this directory are internal and may ' +
    'contain local paths.'),
  '',
  'Raw PAL SBOM: SBOM.pal.raw.json (internal; contains local paths)',
  'Raw PAL Security report: Security.pal.raw.txt (internal; contains local paths)')
$textoCoverage = ($lineasCoverage -join "`r`n")

$lineasSecurity = @(
  '****************************************************************************',
  '*              Normalized Security Report for Factuzam                    *',
  '****************************************************************************',
  '',
  'Vulnerability scan: NOT PERFORMED',
  'Vulnerability status: UNKNOWN',
  '',
  'Reference normalization: PASS',
  "Files with SHA-256: $($estadisticas.Ficheros)",
  "First-party components: $($estadisticas.FirstParty)",
  "Third-party components: $($estadisticas.ThirdParty)",
  'Security coverage details: Security Coverage.txt',
  '',
  'Normalized CycloneDX SBOM:',
  '----------------------------------------------------------------------------',
  '')
$textoSecurity = (($lineasSecurity -join "`r`n") + $jsonNormalizado)

Escribir-TextoAtomico $RutaSbom $jsonNormalizado
Escribir-TextoAtomico $rutaCoverage $textoCoverage
Escribir-TextoAtomico $RutaSecurity $textoSecurity

Write-Output (
  'SBOM normalizado: ' +
  "$($estadisticas.Componentes) componentes; " +
  "$($estadisticas.Dependencias) nodos; " +
  "$($estadisticas.Ficheros) ficheros con SHA-256; " +
  "$($estadisticas.FirstParty) first-party; " +
  "$($estadisticas.ThirdParty) third-party.")
Write-Output 'Vulnerability scan: NOT PERFORMED; status: UNKNOWN.'
Write-Output "Cobertura de seguridad: $rutaCoverage"
