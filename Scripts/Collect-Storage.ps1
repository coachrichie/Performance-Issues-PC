. "$PSScriptRoot\Common.ps1"
function Collect-Storage {
    param([Parameter(Mandatory=$true)][psobject]$RunContext,[switch]$DryRun)
    $out=[System.Collections.Generic.List[object]]::new(); $add={param($n,$v,$u='',$s='Info',$m='')$out.Add((Write-DiagnosticRecord $RunContext 'Storage' $n $v $u $s 'Collect-Storage.ps1' $m))}
    if($DryRun){&$add 'DryRun' 'Enabled';return $out}
    try { Get-Volume -ErrorAction Stop | Where-Object DriveLetter | ForEach-Object { $sev=if($_.Size -and $_.SizeRemaining/$_.Size -lt .1){'Warning'}else{'Info'}; &$add "Volume:$($_.DriveLetter)" ([math]::Round($_.SizeRemaining/1GB,2)) 'GB' $sev 'Free space remaining' } } catch { &$add 'Volumes' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { Get-PhysicalDisk -ErrorAction Stop | ForEach-Object { $sev=if($_.HealthStatus -ne 'Healthy'){'Warning'}else{'Info'}; &$add "Disk:$($_.FriendlyName):Health" $_.HealthStatus '' $sev } } catch { &$add 'PhysicalDisks' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { Get-Counter '\LogicalDisk(_Total)\% Disk Time' -ErrorAction Stop | ForEach-Object { &$add 'DiskTimePercent' $_.CounterSamples[0].CookedValue '%' } } catch { &$add 'DiskTimePercent' 'Unavailable' '' 'Warning' $_.Exception.Message }
    return $out
}
