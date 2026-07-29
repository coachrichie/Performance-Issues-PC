Set-StrictMode -Version Latest

function Get-ProjectRoot {
    Split-Path -Parent $PSScriptRoot
}

function Get-NormalizedFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$BasePath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-SafeChildPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$CandidatePath
    )

    $rootFull = Get-NormalizedFullPath -Path $Root
    if (-not $rootFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $rootFull = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    }

    $candidateFull = Get-NormalizedFullPath -Path $CandidatePath -BasePath $rootFull

    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    return $candidateFull.StartsWith($rootFull, $comparison)
}

function Resolve-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$BasePath = (Get-ProjectRoot),

        [switch]$AllowMissing
    )

    $projectRoot = Get-NormalizedFullPath -Path (Get-ProjectRoot)
    $resolvedBasePath = Get-NormalizedFullPath -Path $BasePath
    $resolvedPath = Get-NormalizedFullPath -Path $Path -BasePath $resolvedBasePath

    if (-not (Test-SafeChildPath -Root $projectRoot -CandidatePath $resolvedPath)) {
        throw "Path escapes the project root: $resolvedPath"
    }

    if (-not $AllowMissing -and -not (Test-Path -LiteralPath $resolvedPath)) {
        throw "Path not found: $resolvedPath"
    }

    return $resolvedPath
}

function New-RunContext {
    [CmdletBinding()]
    param(
        [string]$OutputRoot = (Get-ProjectRoot)
    )

    $resolvedOutputRoot = Get-NormalizedFullPath -Path $OutputRoot
    $runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'

    $reportsPath = Join-Path $resolvedOutputRoot "Reports\$runId"
    $logsPath = Join-Path $resolvedOutputRoot "Logs\$runId"
    $rawPath = Join-Path $resolvedOutputRoot "Raw\$runId"

    foreach ($path in @($reportsPath, $logsPath, $rawPath)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

    [pscustomobject]@{
        ProjectRoot = Get-ProjectRoot
        OutputRoot = $resolvedOutputRoot
        RunId = $runId
        StartedAt = Get-Date
        ReportsPath = $reportsPath
        LogsPath = $logsPath
        RawPath = $rawPath
    }
}

function Write-DiagnosticRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [object]$Value,

        [string]$Unit = '',

        [string]$Severity = 'Info',

        [string]$Source = 'Common.ps1',

        [string]$Message = ''
    )

    $record = [pscustomobject]@{
        RunId = $RunContext.RunId
        Timestamp = (Get-Date).ToString('o')
        Category = $Category
        Name = $Name
        Value = $Value
        Unit = $Unit
        Severity = $Severity
        Source = $Source
        Message = $Message
    }

    if ($RunContext.RawPath) {
        $recordPath = Join-Path $RunContext.RawPath 'diagnostic-records.jsonl'
        $record | ConvertTo-Json -Compress | Add-Content -LiteralPath $recordPath -Encoding UTF8
    }

    return $record
}

function Get-ConfiguredThresholds {
    [CmdletBinding()]
    param()

    $configPath = Join-Path (Get-ProjectRoot) 'Config\diagnostics.json'
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}
