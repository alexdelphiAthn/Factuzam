[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InputPath,

    [string]$OutputPath,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-OptionalValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$PropertyName,
        $DefaultValue = $null
    )

    $property = $Object.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $DefaultValue
    }

    return $property.Value
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$scriptDirectory = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $candidates = @(
        Get-ChildItem -LiteralPath $scriptDirectory -Filter '*.azure-ocr.*.json' -File |
            Where-Object { $_.Name -notlike '*.para-ia.json' -and $_.Name -notlike '*.normalizado*.json' }
    )

    if ($candidates.Count -eq 0) {
        throw "No se encontro un JSON de Azure OCR en $scriptDirectory"
    }
    if ($candidates.Count -gt 1) {
        $names = ($candidates | ForEach-Object { $_.Name }) -join ', '
        throw "Hay varios JSON de Azure OCR ($names). Indica uno con -InputPath."
    }

    $inputFile = $candidates[0]
}
else {
    $inputFile = Get-Item -LiteralPath (Resolve-Path -LiteralPath $InputPath).Path
}

$rawJson = [IO.File]::ReadAllText($inputFile.FullName)
try {
    $azureResult = $rawJson | ConvertFrom-Json
}
catch {
    throw "El archivo no contiene JSON valido: $($inputFile.FullName)"
}

if ([string](Get-OptionalValue -Object $azureResult -PropertyName 'status') -ne 'succeeded') {
    throw 'El resultado de Azure no tiene estado succeeded.'
}

$analysis = Get-OptionalValue -Object $azureResult -PropertyName 'analyzeResult'
if ($null -eq $analysis) {
    throw 'El JSON no contiene analyzeResult.'
}

$pageSummaries = @(
    foreach ($page in @(Get-OptionalValue -Object $analysis -PropertyName 'pages' -DefaultValue @())) {
        [ordered]@{
            page_number = [int](Get-OptionalValue -Object $page -PropertyName 'pageNumber' -DefaultValue 0)
            width       = Get-OptionalValue -Object $page -PropertyName 'width'
            height      = Get-OptionalValue -Object $page -PropertyName 'height'
            unit        = [string](Get-OptionalValue -Object $page -PropertyName 'unit' -DefaultValue '')
        }
    }
)

$tableSummaries = @()
$tableIndex = 0
foreach ($table in @(Get-OptionalValue -Object $analysis -PropertyName 'tables' -DefaultValue @())) {
    $tableIndex++
    $pageNumbers = @(
        foreach ($region in @(Get-OptionalValue -Object $table -PropertyName 'boundingRegions' -DefaultValue @())) {
            [int](Get-OptionalValue -Object $region -PropertyName 'pageNumber' -DefaultValue 0)
        }
    )

    $cells = @(
        foreach ($cell in @(Get-OptionalValue -Object $table -PropertyName 'cells' -DefaultValue @())) {
            [ordered]@{
                row         = [int](Get-OptionalValue -Object $cell -PropertyName 'rowIndex' -DefaultValue 0)
                column      = [int](Get-OptionalValue -Object $cell -PropertyName 'columnIndex' -DefaultValue 0)
                row_span    = [int](Get-OptionalValue -Object $cell -PropertyName 'rowSpan' -DefaultValue 1)
                column_span = [int](Get-OptionalValue -Object $cell -PropertyName 'columnSpan' -DefaultValue 1)
                kind        = [string](Get-OptionalValue -Object $cell -PropertyName 'kind' -DefaultValue 'content')
                text        = [string](Get-OptionalValue -Object $cell -PropertyName 'content' -DefaultValue '')
            }
        }
    )

    $tableSummaries += [ordered]@{
        index       = $tableIndex
        pages       = $pageNumbers
        row_count   = [int](Get-OptionalValue -Object $table -PropertyName 'rowCount' -DefaultValue 0)
        column_count = [int](Get-OptionalValue -Object $table -PropertyName 'columnCount' -DefaultValue 0)
        cells       = $cells
    }
}

$compactResult = [ordered]@{
    schema_version = 1
    source          = [ordered]@{
        file_name = $inputFile.Name
        status    = [string](Get-OptionalValue -Object $azureResult -PropertyName 'status' -DefaultValue '')
    }
    ocr             = [ordered]@{
        api_version = [string](Get-OptionalValue -Object $analysis -PropertyName 'apiVersion' -DefaultValue '')
        model_id    = [string](Get-OptionalValue -Object $analysis -PropertyName 'modelId' -DefaultValue '')
        pages       = $pageSummaries
    }
    full_text       = [string](Get-OptionalValue -Object $analysis -PropertyName 'content' -DefaultValue '')
    tables          = $tableSummaries
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $inputFile.DirectoryName "$($inputFile.BaseName).para-ia.json"
}
elseif (-not [IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path (Get-Location).Path $OutputPath
}

$OutputPath = [IO.Path]::GetFullPath($OutputPath)
if ((Test-Path -LiteralPath $OutputPath) -and -not $Force) {
    throw "El archivo de salida ya existe: $OutputPath. Usa -Force o elige otra ruta."
}

$serialized = $compactResult | ConvertTo-Json -Depth 20 -Compress
Write-Utf8NoBom -Path $OutputPath -Content $serialized

$outputFile = Get-Item -LiteralPath $OutputPath
$reductionPercent = if ($inputFile.Length -gt 0) {
    [Math]::Round((1 - ($outputFile.Length / [double]$inputFile.Length)) * 100, 1)
}
else {
    0
}

Write-Host "Entrada:  $($inputFile.FullName)"
Write-Host "Salida:   $($outputFile.FullName)"
Write-Host "Tablas:   $($tableSummaries.Count)"
Write-Host "Reduccion: $reductionPercent%"
return $outputFile.FullName

