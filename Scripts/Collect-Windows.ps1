. "$PSScriptRoot\Common.ps1"
function Collect-Windows {
    param([Parameter(Mandatory=$true)][psobject]$RunContext,[switch]$DryRun)
    $out = [System.Collections.Generic.List[object]]::new()
    $add = { param($n,$v,$u='',$s='Info',$m='') $out.Add((Write-DiagnosticRecord $RunContext 'Windows' $n $v $u $s 'Collect-Windows.ps1' $m)) }
    if ($DryRun) { & $add 'DryRun' 'Enabled'; return $out }
    try { $os=Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; & $add 'OS' $os.Caption; & $add 'Build' $os.BuildNumber; & $add 'UptimeHours' ((Get-Date)-$os.LastBootUpTime).TotalHours 'h' } catch { & $add 'OSQuery' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { $cs=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; & $add 'ComputerModel' $cs.Model; & $add 'TotalMemoryGB' ([math]::Round($cs.TotalPhysicalMemory/1GB,2)) 'GB' } catch { & $add 'ComputerQuery' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { $proc=Get-Process | ForEach-Object { try { [pscustomobject]@{Name=$_.ProcessName;CpuSeconds=$_.CPU} } catch {} } | Sort-Object CpuSeconds -Descending | Select-Object -First 20; $proc | ForEach-Object { & $add "Process:$($_.Name)" $_.CpuSeconds 's' } } catch { & $add 'Processes' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { $events=@(Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2,3} -MaxEvents 50 -ErrorAction Stop); & $add 'SystemEventsLast50' $events.Count '' 'Info' 'Recent System warnings/errors' } catch { & $add 'SystemEvents' 'Unavailable' '' 'Warning' $_.Exception.Message }
    return $out
}
