. "$PSScriptRoot\Common.ps1"
function Collect-Network {
    param([Parameter(Mandatory=$true)][psobject]$RunContext,[switch]$DryRun)
    $out=[System.Collections.Generic.List[object]]::new(); $add={param($n,$v,$u='',$s='Info',$m='')$out.Add((Write-DiagnosticRecord $RunContext 'Network' $n $v $u $s 'Collect-Network.ps1' $m))}
    &$add 'AutoPacketCapture' 'Disabled' '' 'Info' 'Wireshark packet capture is never automatic'
    if($DryRun){&$add 'DryRun' 'Enabled';return $out}
    try { Get-NetIPConfiguration -ErrorAction Stop | ForEach-Object { &$add "Adapter:$($_.InterfaceAlias):IPv4" (($_.IPv4Address.IPAddress -join ', ')); &$add "Adapter:$($_.InterfaceAlias):Gateway" (($_.IPv4DefaultGateway.NextHop -join ', ')) } } catch { &$add 'Adapters' 'Unavailable' '' 'Warning' $_.Exception.Message }
    try { &$add 'DnsServers' ((Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses -join ', ') } catch { &$add 'DnsServers' 'Unavailable' '' 'Warning' $_.Exception.Message }
    return $out
}
