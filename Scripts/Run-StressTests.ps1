. "$PSScriptRoot\Common.ps1"

function Get-StressDecision {
    param(
        [double]$TemperatureC,
        [double]$WarningTemperatureC = 85,
        [double]$AbortTemperatureC = 95
    )

    [pscustomobject]@{
        Action = if ($TemperatureC -ge $AbortTemperatureC) {
            'Abort'
        } elseif ($TemperatureC -ge $WarningTemperatureC) {
            'Warn'
        } else {
            'Continue'
        }
    }
}

function New-StressRecord {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [string]$Message = '',

        [string]$Severity = 'Info',

        [string]$Unit = ''
    )

    Write-DiagnosticRecord -RunContext $RunContext -Category 'Stress' -Name $Name -Value $Value -Unit $Unit -Severity $Severity -Source 'Run-StressTests.ps1' -Message $Message
}

function Invoke-BoundedStressTest {
    param(
        [ValidateSet('Cpu','Gpu')]
        [string]$Kind,

        [int]$DurationSeconds,

        [psobject]$RunContext,

        [switch]$DryRun
    )

    if ($DryRun) {
        return (New-StressRecord -RunContext $RunContext -Name "$Kind-Stress" -Value 'DryRun' -Message ("Stress test skipped in dry run; planned duration {0}s" -f $DurationSeconds))
    }

    return (New-StressRecord -RunContext $RunContext -Name "$Kind-Stress" -Value 'Skipped' -Severity 'Warning' -Message 'Stress executable not configured')
}
