Describe 'diagnostic collectors' {
    BeforeAll {
        . "$PSScriptRoot/../Scripts/Common.ps1"
        . "$PSScriptRoot/../Scripts/Collect-Windows.ps1"
        . "$PSScriptRoot/../Scripts/Collect-Storage.ps1"
        . "$PSScriptRoot/../Scripts/Collect-Network.ps1"
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'collector')
    }

    It 'returns normalized records from the Windows collector' {
        $records = Collect-Windows -RunContext $script:Context -DryRun
        @($records).Count | Should BeGreaterThan 0
        ($records[0].PSObject.Properties.Name -contains 'Category') | Should Be $true
    }

    It 'does not enable packet capture in the network collector' {
        $records = Collect-Network -RunContext $script:Context -DryRun
        ($records | Where-Object Name -eq 'AutoPacketCapture').Value | Should Be 'Disabled'
    }
}
