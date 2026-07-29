Describe 'diagnostic reporting' {
    BeforeAll {
        . "$PSScriptRoot/../Scripts/Common.ps1"
        . "$PSScriptRoot/../Scripts/Build-Report.ps1"
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'report')
    }

    It 'writes HTML, CSV, and ZIP output' {
        $record = Write-DiagnosticRecord -RunContext $script:Context -Category 'Test' -Name 'Example' -Value 'OK'
        $paths = Build-DiagnosticReport -RunContext $script:Context -Records @($record)
        (Test-Path $paths.HtmlPath) | Should Be $true
        (Test-Path $paths.CsvPath) | Should Be $true
        (Test-Path $paths.ZipPath) | Should Be $true
    }
}
