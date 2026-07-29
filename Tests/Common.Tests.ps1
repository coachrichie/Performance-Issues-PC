. "$PSScriptRoot/../Scripts/Common.ps1"

Describe 'shared diagnostic helpers' {
    It 'rejects paths escaping the project root' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $root | Out-Null

        Test-SafeChildPath -Root $root -CandidatePath '..\escape.txt' | Should Be $false
    }

    It 'accepts paths inside the project root' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $root | Out-Null

        Test-SafeChildPath -Root $root -CandidatePath 'inside\item.txt' | Should Be $true
    }

    It 'creates timestamped report, log, and raw directories' {
        $outputRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $outputRoot | Out-Null

        $context = New-RunContext -OutputRoot $outputRoot

        $context.RunId | Should Match '^\d{8}-\d{6}-\d{3}$'
        Test-Path $context.ReportsPath | Should Be $true
        Test-Path $context.LogsPath | Should Be $true
        Test-Path $context.RawPath | Should Be $true
    }

    It 'loads configured thresholds from diagnostics json' {
        $thresholds = Get-ConfiguredThresholds
        $thresholds.Stress.CpuDurationSeconds | Should Be 600
        $thresholds.Stress.GpuDurationSeconds | Should Be 600
        $thresholds.Stress.AbortTemperatureC | Should Be 95
    }
}
