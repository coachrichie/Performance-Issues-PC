. "$PSScriptRoot\Common.ps1"
function Get-StressDecision { param([double]$TemperatureC,[double]$WarningTemperatureC=85,[double]$AbortTemperatureC=95)
    [pscustomobject]@{ Action=if($TemperatureC -ge $AbortTemperatureC){'Abort'}elseif($TemperatureC -ge $WarningTemperatureC){'Warn'}else{'Continue'} }
}
function Invoke-BoundedStressTest { param([ValidateSet('Cpu','Gpu')][string]$Kind,[int]$DurationSeconds,[psobject]$RunContext,[switch]$DryRun)
    if($DryRun){return [pscustomobject]@{Name="$Kind-Stress";Status='DryRun';DurationSeconds=$DurationSeconds}}
    return [pscustomobject]@{Name="$Kind-Stress";Status='Skipped';DurationSeconds=0;Message='Stress executable not configured'}
}
