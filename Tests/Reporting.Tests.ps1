Describe 'diagnostic reporting' {
    BeforeAll {
        . "$PSScriptRoot/../Scripts/Common.ps1"
        . "$PSScriptRoot/../Scripts/Build-Report.ps1"
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'report')
    }

    It 'writes summary, raw evaluation, CSV, and ZIP output' {
        $records = @(
            (Write-DiagnosticRecord -RunContext $script:Context -Category 'Test' -Name 'Example' -Value 'OK'),
            (Write-DiagnosticRecord -RunContext $script:Context -Category 'BenchmarkComparison' -Name 'CPU:CPU WinSAT' -Value 'InExpectedRange' -Message 'Actual 7.8 score; expected 7.0-9.9 score'),
            (Write-DiagnosticRecord -RunContext $script:Context -Category 'BenchmarkComparison' -Name 'Storage:Storage WinSAT' -Value 'CollectionBlocked' -Message 'WinSAT query blocked'),
            (Write-DiagnosticRecord -RunContext $script:Context -Category 'Storage' -Name 'DiskTimePercent' -Value 'Unavailable' -Severity 'Warning' -Message 'Counter not available'),
            (Write-DiagnosticRecord -RunContext $script:Context -Category 'Windows' -Name 'Process:ExampleApp' -Value 999 's' 'Warning' 'test' 'High CPU time')
        )
        $paths = Build-DiagnosticReport -RunContext $script:Context -Records $records
        (Test-Path $paths.SummaryHtmlPath) | Should Be $true
        (Test-Path $paths.RawHtmlPath) | Should Be $true
        (Test-Path $paths.CsvPath) | Should Be $true
        (Test-Path $paths.ZipPath) | Should Be $true
        (Get-Content $paths.SummaryHtmlPath -Raw) | Should Match 'Abschlussbericht'
        (Get-Content $paths.SummaryHtmlPath -Raw) | Should Match 'Wahrscheinliche Ursachen'
        (Get-Content $paths.RawHtmlPath -Raw) | Should Match 'Rohbewertung'
        (Get-Content $paths.RawHtmlPath -Raw) | Should Match 'Benchmark Comparison'
        (Get-Content $paths.RawHtmlPath -Raw) | Should Match 'status-green'
        (Get-Content $paths.RawHtmlPath -Raw) | Should Match 'status-gray'
    }
}
