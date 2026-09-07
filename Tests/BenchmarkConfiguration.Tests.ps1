Describe 'benchmark reference configuration' {
    It 'loads local benchmark references for CPU, RAM, and storage' {
        $config = Get-Content "$PSScriptRoot/../Config/benchmark-references.json" -Raw | ConvertFrom-Json

        @($config.Benchmarks).Count | Should BeGreaterThan 2
        (@($config.Benchmarks).Metric -contains 'WinSAT:CPUScore') | Should Be $true
        (@($config.Benchmarks).Metric -contains 'WinSAT:MemoryScore') | Should Be $true
        (@($config.Benchmarks).Metric -contains 'WinSAT:DiskScore') | Should Be $true
    }

    It 'stores curated internet source metadata for support triage' {
        $config = Get-Content "$PSScriptRoot/../Config/benchmark-references.json" -Raw | ConvertFrom-Json

        $config.Metadata.CuratedFor | Should Be 'ITSupportTriage'
        $config.Metadata.RetrievedOn | Should Be '2026-07-29'
        @($config.Sources).Count | Should BeGreaterThan 2
    }

    It 'includes official PCMark 10 triage thresholds from UL' {
        $config = Get-Content "$PSScriptRoot/../Config/benchmark-references.json" -Raw | ConvertFrom-Json

        $essentials = @($config.TriageThresholds | Where-Object { $_.Name -eq 'PCMark10:Essentials' })[0]
        $productivity = @($config.TriageThresholds | Where-Object { $_.Name -eq 'PCMark10:Productivity' })[0]
        $dcc = @($config.TriageThresholds | Where-Object { $_.Name -eq 'PCMark10:DigitalContentCreation' })[0]

        $essentials.MinimumRecommended | Should Be 4100
        $productivity.MinimumRecommended | Should Be 4500
        $dcc.MinimumRecommended | Should Be 3450
        $essentials.SourceId | Should Be 'ul-good-score'
    }

    It 'keeps Heaven references as source-backed but conservative until local exports are available' {
        $config = Get-Content "$PSScriptRoot/../Config/benchmark-references.json" -Raw | ConvertFrom-Json

        $heaven = @($config.TriageThresholds | Where-Object { $_.Name -eq 'UnigineHeaven:Score' })[0]

        $heaven.Status | Should Be 'NeedsLocalBaseline'
        $heaven.SourceId | Should Be 'unigine-heaven-product'
    }
}
