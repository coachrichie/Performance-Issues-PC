. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Collect-Benchmarks.ps1"

Describe 'benchmark import sync' {
    BeforeAll {
        $script:Context = New-RunContext -OutputRoot (Join-Path $TestDrive 'benchmark-sync')
    }

    It 'copies PCMark and Heaven exports from trusted source folders into BenchmarkImports' {
        $sourceRoot = Join-Path $TestDrive 'sources'
        $pcSource = Join-Path $sourceRoot 'Desktop'
        $heavenSource = Join-Path $sourceRoot 'Documents'
        $pcImport = Join-Path $TestDrive 'imports\PCMark10'
        $heavenImport = Join-Path $TestDrive 'imports\UnigineHeaven'
        New-Item -ItemType Directory -Path $pcSource -Force | Out-Null
        New-Item -ItemType Directory -Path $heavenSource -Force | Out-Null

        @'
<Results><Result><ProductivityScore>4765</ProductivityScore></Result></Results>
'@ | Set-Content -LiteralPath (Join-Path $pcSource 'pcmark-result.xml') -Encoding UTF8
        @'
Score,FPS
1850,73.4
'@ | Set-Content -LiteralPath (Join-Path $heavenSource 'heaven-result.csv') -Encoding UTF8

        $records = Sync-BenchmarkImports -RunContext $script:Context -PcMarkSourceRoots @($pcSource) -HeavenSourceRoots @($heavenSource) -PcMarkImportRoot $pcImport -HeavenImportRoot $heavenImport

        (Test-Path (Join-Path $pcImport 'pcmark-result.xml')) | Should Be $true
        (Test-Path (Join-Path $heavenImport 'heaven-result.csv')) | Should Be $true
        ($records | Where-Object { $_.Category -eq 'BenchmarkImport' -and $_.Name -eq 'PCMark10' }).Value | Should Be 'Imported'
        ($records | Where-Object { $_.Category -eq 'BenchmarkImport' -and $_.Name -eq 'UnigineHeaven' }).Value | Should Be 'Imported'
    }

    It 'does not create duplicate copies when the same export already exists in the import folder' {
        $sourceRoot = Join-Path $TestDrive 'sources-existing'
        $pcSource = Join-Path $sourceRoot 'Desktop'
        $pcImport = Join-Path $TestDrive 'imports-existing\PCMark10'
        New-Item -ItemType Directory -Path $pcSource -Force | Out-Null
        New-Item -ItemType Directory -Path $pcImport -Force | Out-Null

        $content = @'
<Results><Result><ProductivityScore>4765</ProductivityScore></Result></Results>
'@
        $sourceFile = Join-Path $pcSource 'pcmark-result.xml'
        $importFile = Join-Path $pcImport 'pcmark-result.xml'
        $content | Set-Content -LiteralPath $sourceFile -Encoding UTF8
        $content | Set-Content -LiteralPath $importFile -Encoding UTF8

        $records = Sync-BenchmarkImports -RunContext $script:Context -PcMarkSourceRoots @($pcSource) -HeavenSourceRoots @() -PcMarkImportRoot $pcImport -HeavenImportRoot (Join-Path $TestDrive 'unused')

        (@(Get-ChildItem -LiteralPath $pcImport -File).Count) | Should Be 1
        ($records | Where-Object { $_.Category -eq 'BenchmarkImport' -and $_.Name -eq 'PCMark10' }).Value | Should Be 'AlreadyImported'
    }
}
