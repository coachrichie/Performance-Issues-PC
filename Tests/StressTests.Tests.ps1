. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Run-StressTests.ps1"

Describe 'stress test records' {
    It 'returns normalized diagnostic records during dry runs' {
        $context = New-RunContext -OutputRoot (Join-Path $TestDrive 'stress-tests')

        $record = Invoke-BoundedStressTest -Kind Cpu -DurationSeconds 600 -RunContext $context -DryRun

        $record.Category | Should Be 'Stress'
        $record.Name | Should Be 'Cpu-Stress'
        $record.Value | Should Be 'DryRun'
        $record.Severity | Should Be 'Info'
    }
}
