. "$PSScriptRoot\Common.ps1"
function Build-DiagnosticReport {
    param([Parameter(Mandatory=$true)][psobject]$RunContext,[Parameter(Mandatory=$true)][object[]]$Records)
    $csv=Join-Path $RunContext.ReportsPath 'Records.csv'; $html=Join-Path $RunContext.ReportsPath 'Report.html'; $zip=Join-Path $RunContext.ReportsPath 'Run.zip'
    $get = { param($o,$n,$fallback=''); $p=$o.PSObject.Properties[$n]; if($p -and $null -ne $p.Value -and "$($p.Value)" -ne ''){$p.Value}else{$fallback} }
    $normalized = @($Records | ForEach-Object { [pscustomobject]@{RunId=&$get $_ 'RunId' $RunContext.RunId;Timestamp=&$get $_ 'Timestamp' ((Get-Date).ToString('o'));Category=&$get $_ 'Category' 'Tool';Name=&$get $_ 'Name' 'Unnamed';Value=&$get $_ 'Value' '';Unit=&$get $_ 'Unit' '';Severity=&$get $_ 'Severity' 'Info';Source=&$get $_ 'Source' 'Unknown';Message=&$get $_ 'Message' ''} })
    $normalized | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    $rows=($normalized | ForEach-Object { '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>' -f (($_.Timestamp -replace '&','&amp;') -replace '<','&lt;'),(($_.Category -replace '&','&amp;') -replace '<','&lt;'),(($_.Name -replace '&','&amp;') -replace '<','&lt;'),(($_.Value -replace '&','&amp;') -replace '<','&lt;'),$_.Severity }) -join "`n"
    @"
<html><head><meta charset="utf-8"><title>PC-Diagnose $($RunContext.RunId)</title></head><body><h1>PC Performance Diagnose</h1><p>Run: $($RunContext.RunId)</p><p>Hinweis: Rohdaten können personenbezogene System- und Netzwerkdaten enthalten.</p><table border="1"><tr><th>Zeit</th><th>Kategorie</th><th>Name</th><th>Wert</th><th>Status</th></tr>$rows</table></body></html>
"@ | Set-Content -LiteralPath $html -Encoding UTF8
    Compress-Archive -Path (Join-Path $RunContext.ReportsPath '*'),(Join-Path $RunContext.RawPath '*'),(Join-Path $RunContext.LogsPath '*') -DestinationPath $zip -Force
    [pscustomobject]@{HtmlPath=$html;CsvPath=$csv;ZipPath=$zip}
}
