. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Run-Benchmarks.ps1"
. "$PSScriptRoot/../Scripts/Collect-SupportTools.ps1"

Describe 'support tools integration' {
    It 'parses CrystalDiskInfo text dumps into support metrics' {
        $path = Join-Path $TestDrive 'DiskInfo.txt'
        @'
Health Status : Good (98 %)
Temperature : 34 C
'@ | Set-Content -LiteralPath $path -Encoding UTF8

        $parsed = Import-CrystalDiskInfoText -Path $path

        ($parsed.Metrics | Where-Object Name -eq 'CrystalDiskInfo:HealthStatus').Value | Should Be 'Good (98 %)'
        ($parsed.Metrics | Where-Object Name -eq 'CrystalDiskInfo:Temperature').Value | Should Be 34
    }

    It 'parses Autoruns CSV into cumulative metrics' {
        $path = Join-Path $TestDrive 'Autoruns.csv'
        @'
Entry,Signer,Verified
App1,,Not verified
App2,Vendor,Verified
'@ | Set-Content -LiteralPath $path -Encoding UTF8

        $parsed = Import-AutorunsCsv -Path $path

        ($parsed.Metrics | Where-Object Name -eq 'Autoruns:TotalEntries').Value | Should Be 2
        ($parsed.Metrics | Where-Object Name -eq 'Autoruns:UnsignedEntries').Value | Should Be 1
    }

    It 'returns dry-run records for all configured support tools' {
        $context = New-RunContext -OutputRoot (Join-Path $TestDrive 'support-tools')

        $records = Invoke-SupportTools -RunContext $context -DryRun

        ($records | Where-Object Name -eq 'CrystalDiskInfo:Run').Value | Should Be 'DryRun'
        ($records | Where-Object Name -eq 'Autoruns:Run').Value | Should Be 'DryRun'
        ($records | Where-Object Name -eq 'ProcessExplorer:Run').Value | Should Be 'DryRun'
        ($records | Where-Object Name -eq 'ProcessMonitor:Run').Value | Should Be 'DryRun'
    }

    It 'skips executable discovery during a dry-run' {
        Mock Get-SupportToolExecutable { throw 'Executable discovery should not run during dry-run' }
        $context = New-RunContext -OutputRoot (Join-Path $TestDrive 'support-tools-fast')

        { Invoke-SupportTools -RunContext $context -DryRun } | Should Not Throw
    }
}
