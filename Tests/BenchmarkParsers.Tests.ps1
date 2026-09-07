. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Collect-Benchmarks.ps1"

Describe 'benchmark export parsers' {
    It 'parses PCMark 10 XML exports into normalized benchmark metrics' {
        $xmlPath = Join-Path $TestDrive 'pcmark10-result.xml'
        @'
<Results>
  <Result>
    <PCMark10Score>5123</PCMark10Score>
    <EssentialsScore>4321</EssentialsScore>
    <ProductivityScore>4765</ProductivityScore>
    <DigitalContentCreationScore>3890</DigitalContentCreationScore>
  </Result>
</Results>
'@ | Set-Content -LiteralPath $xmlPath -Encoding UTF8

        $parsed = Import-PCMark10Export -Path $xmlPath

        $parsed.Source | Should Be 'PCMark10'
        ($parsed.Metrics | Where-Object Name -eq 'PCMark10:Essentials').Value | Should Be 4321
        ($parsed.Metrics | Where-Object Name -eq 'PCMark10:Productivity').Value | Should Be 4765
        ($parsed.Metrics | Where-Object Name -eq 'PCMark10:DigitalContentCreation').Value | Should Be 3890
    }

    It 'parses Unigine Heaven CSV exports into normalized benchmark metrics' {
        $csvPath = Join-Path $TestDrive 'heaven-results.csv'
        @'
Score,FPS,Min FPS,Max FPS
1850,73.4,24.6,144.2
'@ | Set-Content -LiteralPath $csvPath -Encoding UTF8

        $parsed = Import-UnigineHeavenExport -Path $csvPath

        $parsed.Source | Should Be 'UnigineHeaven'
        ($parsed.Metrics | Where-Object Name -eq 'UnigineHeaven:Score').Value | Should Be 1850
        ($parsed.Metrics | Where-Object Name -eq 'UnigineHeaven:FPS').Value | Should Be 73.4
    }
}
