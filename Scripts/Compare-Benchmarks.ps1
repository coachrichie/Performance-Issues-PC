. "$PSScriptRoot\Common.ps1"

function Get-BenchmarkAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$ActualValue,

        [Parameter(Mandatory = $true)]
        [psobject]$Reference
    )

    if ($ActualValue -lt [double]$Reference.Minimum) {
        return 'BelowMinimum'
    }

    if ($ActualValue -lt [double]$Reference.ExpectedLow) {
        return 'UnderExpectedRange'
    }

    if ($ActualValue -le [double]$Reference.ExpectedHigh) {
        return 'InExpectedRange'
    }

    return 'AboveExpectedRange'
}

function Compare-BenchmarkRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [object[]]$Records,

        [psobject]$References = (Get-BenchmarkReferences)
    )

    $out = [System.Collections.Generic.List[object]]::new()
    $benchmarkRecords = @($Records | Where-Object { $_.Category -eq 'Benchmark' })
    $sourceRecords = @($Records | Where-Object { $_.Category -eq 'BenchmarkSource' })

    foreach ($reference in @($References.Benchmarks)) {
        $match = @($benchmarkRecords | Where-Object { $_.Name -eq $reference.Metric } | Select-Object -First 1)
        $comparisonName = '{0}:{1}' -f $reference.Category, $reference.DisplayName

        if (-not $match) {
            $sourceStatusRecord = @($sourceRecords | Where-Object { $_.Name -eq $reference.Source } | Select-Object -First 1)
            if ($sourceStatusRecord) {
                $sourceStatus = $sourceStatusRecord[0].Value
                $sourceMessage = $sourceStatusRecord[0].Message
                $severity = if ($sourceStatus -eq 'DataAvailable') { 'Warning' } elseif ($sourceStatus -eq 'CollectionBlocked') { 'Warning' } else { 'Info' }
                $value = if ($sourceStatus -eq 'DataAvailable') { 'BenchmarkMissing' } else { $sourceStatus }
                $message = if ([string]::IsNullOrWhiteSpace($sourceMessage)) { 'No benchmark result found for source' } else { $sourceMessage }
                $out.Add((Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkComparison' -Name $comparisonName -Value $value -Severity $severity -Source 'Compare-Benchmarks.ps1' -Message $message))
                continue
            }

            $out.Add((Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkComparison' -Name $comparisonName -Value 'BenchmarkMissing' -Severity 'Warning' -Source 'Compare-Benchmarks.ps1' -Message ('No benchmark result found for {0}' -f $reference.Metric)))
            continue
        }

        $actualValue = [double]$match[0].Value
        $assessment = Get-BenchmarkAssessment -ActualValue $actualValue -Reference $reference
        $severity = if ($assessment -in @('BelowMinimum', 'UnderExpectedRange')) { 'Warning' } else { 'Info' }
        $message = 'Actual {0} {1}; expected {2}-{3} {1}' -f $actualValue, $reference.Unit, $reference.ExpectedLow, $reference.ExpectedHigh

        $out.Add((Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkComparison' -Name $comparisonName -Value $assessment -Unit $reference.Unit -Severity $severity -Source 'Compare-Benchmarks.ps1' -Message $message))
    }

    return $out
}
