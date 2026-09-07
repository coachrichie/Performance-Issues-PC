. "$PSScriptRoot\Common.ps1"

function Get-BenchmarkAssessmentClass {
    param(
        [string]$Assessment
    )

    switch ($Assessment) {
        'InExpectedRange' { return 'status-green' }
        'AboveExpectedRange' { return 'status-green' }
        'UnderExpectedRange' { return 'status-yellow' }
        'BelowMinimum' { return 'status-red' }
        'BenchmarkMissing' { return 'status-gray' }
        'CollectionBlocked' { return 'status-gray' }
        'NoResultYet' { return 'status-gray' }
        default { return 'status-gray' }
    }
}

function Get-HtmlEscapedValue {
    param(
        [object]$Value
    )

    ((("$Value" -replace '&', '&amp;') -replace '<', '&lt;') -replace '>', '&gt;')
}

function Get-LikelyCauseItems {
    param(
        [object[]]$Records
    )

    $items = [System.Collections.Generic.List[string]]::new()
    $warnings = @($Records | Where-Object { $_.Severity -in @('Warning', 'Error') })

    if (@($Records | Where-Object { $_.Category -eq 'BenchmarkComparison' -and $_.Value -in @('BelowMinimum', 'UnderExpectedRange') }).Count -gt 0) {
        $items.Add('Benchmark-Werte liegen unter dem erwarteten Bereich und deuten auf Leistungsprobleme der betroffenen Komponente hin.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'BenchmarkComparison' -and $_.Value -eq 'CollectionBlocked' }).Count -gt 0) {
        $items.Add('Ein Teil der Benchmark-Daten konnte wegen fehlender Rechte oder blockierter Abfragen nicht erfasst werden.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'Storage' -and $_.Severity -eq 'Warning' }).Count -gt 0) {
        $items.Add('Speicher- oder Datentraegerwerte enthalten Warnungen und sollten als moegliche Ursache fuer Verlangsamungen geprueft werden.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'SupportTool' -and $_.Name -eq 'CrystalDiskInfo:HealthStatus' -and "$($_.Value)" -notmatch 'Good|Healthy' }).Count -gt 0) {
        $items.Add('CrystalDiskInfo meldet einen auffaelligen Laufwerkszustand; Datentraeger-Gesundheit sollte priorisiert geprueft werden.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'SupportTool' -and $_.Name -eq 'Autoruns:TotalEntries' -and [int]$_.Value -gt 40 }).Count -gt 0) {
        $items.Add('Autoruns zeigt viele aktive Autostart-Eintraege; ein ueberladener Systemstart ist als Ursache plausibel.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'Sensor' -and $_.Severity -eq 'Warning' }).Count -gt 0) {
        $items.Add('Temperatur- oder Sensordaten sind unvollstaendig; thermische Ursachen koennen deshalb nur eingeschraenkt bewertet werden.')
    }

    $topProcess = @($Records | Where-Object { $_.Category -eq 'Windows' -and $_.Name -like 'Process:*' } | Sort-Object { [double]($_.Value) } -Descending | Select-Object -First 1)
    if ($topProcess) {
        $items.Add(('Auffaellig hoher Prozessverbrauch erkannt: {0} mit Wert {1} {2}.' -f $topProcess[0].Name, $topProcess[0].Value, $topProcess[0].Unit))
    }

    if ($items.Count -eq 0 -and $warnings.Count -gt 0) {
        $items.Add('Es liegen Warnungen vor, aber keine eindeutige Einzelursache; die Rohbewertung sollte zur Detailanalyse herangezogen werden.')
    }

    if ($items.Count -eq 0) {
        $items.Add('Keine klaren Leistungsursachen im aktuellen Lauf erkannt; Benchmark- und Systemwerte wirken unauffaellig oder waren nicht vollstaendig verfuegbar.')
    }

    return @($items)
}

function Get-RecommendedNextSteps {
    param(
        [object[]]$Records
    )

    $steps = [System.Collections.Generic.List[string]]::new()
    if (@($Records | Where-Object { $_.Category -eq 'BenchmarkComparison' -and $_.Value -eq 'CollectionBlocked' }).Count -gt 0) {
        $steps.Add('Diagnoselauf erneut mit Administratorrechten und entsperrten Systemabfragen ausfuehren.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'BenchmarkSource' -and $_.Value -eq 'NoResultYet' }).Count -gt 0) {
        $steps.Add('Fehlende Benchmark-Exporte von PCMark 10 oder Unigine Heaven erzeugen und erneut auswerten.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'Storage' -and $_.Severity -eq 'Warning' }).Count -gt 0) {
        $steps.Add('Datentraegerzustand, freien Speicher und I/O-Belastung im Detail pruefen.')
    }

    if (@($Records | Where-Object { $_.Category -eq 'SupportTool' -and $_.Name -eq 'Autoruns:TotalEntries' -and [int]$_.Value -gt 40 }).Count -gt 0) {
        $steps.Add('Autostart-Eintraege mit Autoruns pruefen und nicht benoetigte Drittanbieter-Starts reduzieren.')
    }

    if ($steps.Count -eq 0) {
        $steps.Add('Rohbewertung und CSV bei Bedarf mit einem zweiten Lauf unter Last vergleichen.')
    }

    return @($steps)
}

function Build-DiagnosticReport {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [object[]]$Records
    )

    $csv = Join-Path $RunContext.ReportsPath 'Records.csv'
    $summaryHtml = Join-Path $RunContext.ReportsPath 'Abschlussbericht.html'
    $rawHtml = Join-Path $RunContext.ReportsPath 'Rohbewertung.html'
    $zip = Join-Path $RunContext.ReportsPath 'Run.zip'
    $get = {
        param($object, $name, $fallback = '')
        $property = $object.PSObject.Properties[$name]
        if ($property -and $null -ne $property.Value -and "$($property.Value)" -ne '') {
            return $property.Value
        }

        return $fallback
    }

    $normalized = @(
        $Records | ForEach-Object {
            [pscustomobject]@{
                RunId = &$get $_ 'RunId' $RunContext.RunId
                Timestamp = &$get $_ 'Timestamp' ((Get-Date).ToString('o'))
                Category = &$get $_ 'Category' 'Tool'
                Name = &$get $_ 'Name' 'Unnamed'
                Value = &$get $_ 'Value' ''
                Unit = &$get $_ 'Unit' ''
                Severity = &$get $_ 'Severity' 'Info'
                Source = &$get $_ 'Source' 'Unknown'
                Message = &$get $_ 'Message' ''
            }
        }
    )

    $normalized | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

    $rows = (
        $normalized | ForEach-Object {
            '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>' -f
                (Get-HtmlEscapedValue $_.Timestamp),
                (Get-HtmlEscapedValue $_.Category),
                (Get-HtmlEscapedValue $_.Name),
                (Get-HtmlEscapedValue $_.Value),
                (Get-HtmlEscapedValue $_.Severity)
        }
    ) -join "`n"

    $benchmarkRows = (
        $normalized | Where-Object { $_.Category -eq 'BenchmarkComparison' } | ForEach-Object {
            $assessmentClass = Get-BenchmarkAssessmentClass -Assessment $_.Value
            '<tr class="{4}"><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td></tr>' -f
                (Get-HtmlEscapedValue $_.Name),
                (Get-HtmlEscapedValue $_.Value),
                (Get-HtmlEscapedValue $_.Unit),
                (Get-HtmlEscapedValue $_.Message),
                $assessmentClass
        }
    ) -join "`n"

    $benchmarkSection = if ([string]::IsNullOrWhiteSpace($benchmarkRows)) {
        '<h2>Benchmark Comparison</h2><p>No benchmark comparison data available for this run.</p>'
    }
    else {
        '<h2>Benchmark Comparison</h2><table border="1"><tr><th>Metric</th><th>Assessment</th><th>Unit</th><th>Interpretation</th></tr>{0}</table>' -f $benchmarkRows
    }

    $likelyCauses = Get-LikelyCauseItems -Records $normalized
    $causeList = ($likelyCauses | ForEach-Object { '<li>{0}</li>' -f (Get-HtmlEscapedValue $_) }) -join "`n"
    $nextSteps = Get-RecommendedNextSteps -Records $normalized
    $stepList = ($nextSteps | ForEach-Object { '<li>{0}</li>' -f (Get-HtmlEscapedValue $_) }) -join "`n"
    $warningCount = @($normalized | Where-Object { $_.Severity -in @('Warning', 'Error') }).Count
    $infoCount = @($normalized | Where-Object { $_.Severity -eq 'Info' }).Count

@"
<html><head><meta charset="utf-8"><title>Abschlussbericht $($RunContext.RunId)</title><style>body{font-family:Segoe UI,Arial,sans-serif;}table{border-collapse:collapse;}th,td{padding:4px 6px;} .card{border:1px solid #d0d7de;padding:12px;margin:10px 0;} .metric{font-size:20px;font-weight:bold;}</style></head><body><h1>Abschlussbericht</h1><p>Run: $($RunContext.RunId)</p><div class="card"><div class="metric">$warningCount Warnungen</div><p>$infoCount weitere Informationswerte wurden protokolliert.</p></div><div class="card"><h2>Wahrscheinliche Ursachen</h2><ul>$causeList</ul></div><div class="card"><h2>Empfohlene nächste Schritte</h2><ul>$stepList</ul></div><div class="card"><h2>Rohbewertung</h2><p>Die technische Detailausgabe befindet sich in <code>Rohbewertung.html</code> und <code>Records.csv</code>.</p></div></body></html>
"@ | Set-Content -LiteralPath $summaryHtml -Encoding UTF8

@"
<html><head><meta charset="utf-8"><title>Rohbewertung $($RunContext.RunId)</title><style>.status-green{background-color:#d9f2d9;}.status-yellow{background-color:#fff3cd;}.status-red{background-color:#f8d7da;}.status-gray{background-color:#e2e3e5;}table{border-collapse:collapse;}th,td{padding:4px 6px;}body{font-family:Segoe UI,Arial,sans-serif;}</style></head><body><h1>Rohbewertung</h1><p>Run: $($RunContext.RunId)</p><p>Hinweis: Rohdaten können personenbezogene System- und Netzwerkdaten enthalten.</p>$benchmarkSection<table border="1"><tr><th>Zeit</th><th>Kategorie</th><th>Name</th><th>Wert</th><th>Status</th></tr>$rows</table></body></html>
"@ | Set-Content -LiteralPath $rawHtml -Encoding UTF8

    Compress-Archive -Path (Join-Path $RunContext.ReportsPath '*'), (Join-Path $RunContext.RawPath '*'), (Join-Path $RunContext.LogsPath '*') -DestinationPath $zip -Force
    [pscustomobject]@{
        SummaryHtmlPath = $summaryHtml
        RawHtmlPath = $rawHtml
        HtmlPath = $rawHtml
        CsvPath = $csv
        ZipPath = $zip
    }
}
