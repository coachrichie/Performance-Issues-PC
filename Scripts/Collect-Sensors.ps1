. "$PSScriptRoot\Common.ps1"
function Get-SensorSnapshot { param([Parameter(Mandatory=$true)][psobject]$RunContext)
    $r=[System.Collections.Generic.List[object]]::new(); $r.Add((Write-DiagnosticRecord $RunContext 'Sensor' 'CpuTemperature' 'Unavailable' 'C' 'Warning' 'Collect-Sensors.ps1' 'No reliable built-in temperature source')); return $r
}
