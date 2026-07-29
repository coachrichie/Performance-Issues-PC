[CmdletBinding()]
param(
    [switch]$InstallTools,
    [switch]$RunStressTests,
    [switch]$DryRun,
    [string]$OutputRoot = $PSScriptRoot
)

$scriptRoot = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\Scripts\Common.ps1"
. "$PSScriptRoot\Scripts\Install-Tools.ps1"
. "$PSScriptRoot\Scripts\Collect-Windows.ps1"
. "$PSScriptRoot\Scripts\Collect-Storage.ps1"
. "$PSScriptRoot\Scripts\Collect-Network.ps1"
. "$PSScriptRoot\Scripts\Collect-Sensors.ps1"
. "$PSScriptRoot\Scripts\Run-StressTests.ps1"
. "$PSScriptRoot\Scripts\Build-Report.ps1"

Set-StrictMode -Version Latest

try {
    $runContext = New-RunContext -OutputRoot $OutputRoot
    $thresholds = Get-ConfiguredThresholds
    $records = [System.Collections.Generic.List[object]]::new()
    $addRecords = { param($items) foreach ($item in @($items)) { if ($null -ne $item) { $records.Add($item) } } }

    Write-DiagnosticRecord -RunContext $runContext -Category 'Launcher' -Name 'Start-Diagnose' -Value 'Initialized' -Severity 'Info' -Source 'Start-Diagnose.ps1' -Message 'Launcher initialized' | Out-Null

    if ($InstallTools) {
        & $addRecords (Install-AllowlistedTools -ManifestPath (Join-Path $PSScriptRoot 'Config\tools.json') -RunContext $runContext -DryRun:$DryRun)
    }

    & $addRecords (Collect-Windows -RunContext $runContext -DryRun:$DryRun)
    & $addRecords (Collect-Storage -RunContext $runContext -DryRun:$DryRun)
    & $addRecords (Collect-Network -RunContext $runContext -DryRun:$DryRun)
    & $addRecords (Get-SensorSnapshot -RunContext $runContext)

    if ($RunStressTests) {
        if ($DryRun) {
            & $addRecords (Invoke-BoundedStressTest -Kind Cpu -DurationSeconds $thresholds.Stress.CpuDurationSeconds -RunContext $runContext -DryRun)
            & $addRecords (Invoke-BoundedStressTest -Kind Gpu -DurationSeconds $thresholds.Stress.GpuDurationSeconds -RunContext $runContext -DryRun)
        } else {
            & $addRecords (Write-DiagnosticRecord -RunContext $runContext -Category 'Stress' -Name 'Tests' -Value 'Skipped' -Severity 'Warning' -Source 'Start-Diagnose.ps1' -Message 'Stress tests require a verified sensor source and are disabled in this build')
        }
    }

    if ($DryRun) {
        Write-DiagnosticRecord -RunContext $runContext -Category 'Launcher' -Name 'DryRun' -Value $true -Severity 'Info' -Source 'Start-Diagnose.ps1' -Message 'Dry run requested' | Out-Null
    }

    if (-not $thresholds) {
        throw 'Failed to load configuration.'
    }

    & $addRecords (Write-DiagnosticRecord -RunContext $runContext -Category 'Launcher' -Name 'Completed' -Value 'OK' -Source 'Start-Diagnose.ps1')
    $result = Build-DiagnosticReport -RunContext $runContext -Records @($records)
    Write-Output "HTML: $($result.HtmlPath)"
    Write-Output "CSV:  $($result.CsvPath)"
    Write-Output "ZIP:  $($result.ZipPath)"
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
