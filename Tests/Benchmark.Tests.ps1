. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Compare-Benchmarks.ps1"

Describe 'benchmark comparison' {
    BeforeAll {
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'benchmark')
        $script:References = [pscustomobject]@{
            Benchmarks = @(
                [pscustomobject]@{
                    Metric = 'WinSAT:CPUScore'
                    Source = 'WinSAT'
                    Category = 'CPU'
                    DisplayName = 'CPU WinSAT'
                    Unit = 'score'
                    Minimum = 5.5
                    ExpectedLow = 7.0
                    ExpectedHigh = 9.9
                },
                [pscustomobject]@{
                    Metric = 'WinSAT:MemoryScore'
                    Source = 'WinSAT'
                    Category = 'RAM'
                    DisplayName = 'RAM WinSAT'
                    Unit = 'score'
                    Minimum = 5.0
                    ExpectedLow = 6.5
                    ExpectedHigh = 9.9
                },
                [pscustomobject]@{
                    Metric = 'PCMark10:Productivity'
                    Source = 'PCMark10'
                    Category = 'System'
                    DisplayName = 'PCMark 10 Productivity'
                    Unit = 'score'
                    Minimum = 4500
                    ExpectedLow = 4500
                    ExpectedHigh = 15000
                }
            )
        }
    }

    It 'classifies benchmark scores below expectation' {
        $records = @(
            [pscustomobject]@{ Category = 'Hardware'; Name = 'CPUModel'; Value = 'Intel Test CPU'; Unit = ''; Severity = 'Info'; Source = 'test'; Message = '' },
            [pscustomobject]@{ Category = 'Benchmark'; Name = 'WinSAT:CPUScore'; Value = 6.1; Unit = 'score'; Severity = 'Info'; Source = 'test'; Message = '' }
        )

        $result = Compare-BenchmarkRecords -RunContext $script:Context -Records $records -References $script:References

        ($result | Where-Object Name -eq 'CPU:CPU WinSAT').Value | Should Be 'UnderExpectedRange'
    }

    It 'classifies benchmark scores inside the expected range' {
        $records = @(
            [pscustomobject]@{ Category = 'Benchmark'; Name = 'WinSAT:MemoryScore'; Value = 7.2; Unit = 'score'; Severity = 'Info'; Source = 'test'; Message = '' }
        )

        $result = Compare-BenchmarkRecords -RunContext $script:Context -Records $records -References $script:References

        ($result | Where-Object Name -eq 'RAM:RAM WinSAT').Value | Should Be 'InExpectedRange'
    }

    It 'reports missing benchmark results when no matching measurement exists' {
        $records = @(
            [pscustomobject]@{ Category = 'Hardware'; Name = 'CPUModel'; Value = 'Intel Test CPU'; Unit = ''; Severity = 'Info'; Source = 'test'; Message = '' }
        )

        $result = Compare-BenchmarkRecords -RunContext $script:Context -Records $records -References $script:References

        ($result | Where-Object Name -eq 'CPU:CPU WinSAT').Value | Should Be 'BenchmarkMissing'
    }

    It 'propagates blocked source states when the benchmark source could not be read' {
        $records = @(
            [pscustomobject]@{ Category = 'BenchmarkSource'; Name = 'WinSAT'; Value = 'CollectionBlocked'; Unit = ''; Severity = 'Warning'; Source = 'test'; Message = 'Access denied' }
        )

        $result = Compare-BenchmarkRecords -RunContext $script:Context -Records $records -References $script:References

        ($result | Where-Object Name -eq 'CPU:CPU WinSAT').Value | Should Be 'CollectionBlocked'
    }

    It 'evaluates imported PCMark 10 productivity scores against triage thresholds' {
        $records = @(
            [pscustomobject]@{ Category = 'BenchmarkSource'; Name = 'PCMark10'; Value = 'DataAvailable'; Unit = ''; Severity = 'Info'; Source = 'test'; Message = 'ParsedSuccessfully' },
            [pscustomobject]@{ Category = 'Benchmark'; Name = 'PCMark10:Productivity'; Value = 4765; Unit = 'score'; Severity = 'Info'; Source = 'test'; Message = '' }
        )

        $result = Compare-BenchmarkRecords -RunContext $script:Context -Records $records -References $script:References

        ($result | Where-Object Name -eq 'System:PCMark 10 Productivity').Value | Should Be 'InExpectedRange'
    }
}
