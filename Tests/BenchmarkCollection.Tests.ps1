. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Collect-Benchmarks.ps1"

Describe 'benchmark collection' {
    BeforeAll {
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'benchmark-collection')
    }

    It 'emits a blocked WinSAT source record when the query is denied' {
        Mock Get-WinSATInstance { throw 'Access is denied.' }

        $records = Collect-Benchmarks -RunContext $script:Context

        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'WinSAT' }).Value | Should Be 'CollectionBlocked'
    }

    It 'normalizes WinSAT scores into benchmark records when data is available' {
        Mock Get-WinSATInstance {
            [pscustomobject]@{
                CPUScore = 7.8
                MemoryScore = 7.4
                DiskScore = 8.1
            }
        }

        $records = Collect-Benchmarks -RunContext $script:Context

        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'WinSAT' }).Value | Should Be 'DataAvailable'
        ($records | Where-Object { $_.Category -eq 'Benchmark' -and $_.Name -eq 'WinSAT:CPUScore' }).Value | Should Be 7.8
        ($records | Where-Object { $_.Category -eq 'Benchmark' -and $_.Name -eq 'WinSAT:MemoryScore' }).Value | Should Be 7.4
        ($records | Where-Object { $_.Category -eq 'Benchmark' -and $_.Name -eq 'WinSAT:DiskScore' }).Value | Should Be 8.1
    }

    It 'includes prepared external benchmark sources even when no exports exist yet' {
        Mock Get-WinSATInstance {
            [pscustomobject]@{
                CPUScore = 7.8
                MemoryScore = 7.4
                DiskScore = 8.1
            }
        }

        $records = Collect-Benchmarks -RunContext $script:Context

        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'PCMark10' }).Value | Should Be 'NoResultYet'
        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'UnigineHeaven' }).Value | Should Be 'NoResultYet'
    }

    It 'collects PCMark 10 exports from the configured import folder' {
        $pcMarkRoot = Join-Path $TestDrive 'pcmark-imports'
        New-Item -ItemType Directory -Path $pcMarkRoot | Out-Null
        $pcMarkFile = Join-Path $pcMarkRoot 'result.xml'
        @'
<Results>
  <Result>
    <EssentialsScore>4321</EssentialsScore>
    <ProductivityScore>4765</ProductivityScore>
    <DigitalContentCreationScore>3890</DigitalContentCreationScore>
  </Result>
</Results>
'@ | Set-Content -LiteralPath $pcMarkFile -Encoding UTF8

        Mock Get-WinSATInstance { throw 'Access is denied.' }

        $records = Collect-Benchmarks -RunContext $script:Context -PcMarkImportRoot $pcMarkRoot

        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'PCMark10' }).Value | Should Be 'DataAvailable'
        ($records | Where-Object { $_.Category -eq 'Benchmark' -and $_.Name -eq 'PCMark10:Productivity' }).Value | Should Be 4765
    }

    It 'collects Unigine Heaven exports from the configured import folder' {
        $heavenRoot = Join-Path $TestDrive 'heaven-imports'
        New-Item -ItemType Directory -Path $heavenRoot | Out-Null
        $heavenFile = Join-Path $heavenRoot 'result.csv'
        @'
Score,FPS,Min FPS,Max FPS
1850,73.4,24.6,144.2
'@ | Set-Content -LiteralPath $heavenFile -Encoding UTF8

        Mock Get-WinSATInstance { throw 'Access is denied.' }

        $records = Collect-Benchmarks -RunContext $script:Context -HeavenImportRoot $heavenRoot

        ($records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Name -eq 'UnigineHeaven' }).Value | Should Be 'DataAvailable'
        ($records | Where-Object { $_.Category -eq 'Benchmark' -and $_.Name -eq 'UnigineHeaven:Score' }).Value | Should Be 1850
    }
}
