. "$PSScriptRoot\Common.ps1"

function Get-WinSATInstance {
    [CmdletBinding()]
    param()

    Get-CimInstance Win32_WinSAT -Namespace root\cimv2 -ErrorAction Stop
}

function Get-BenchmarkSourceRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [string]$Message = '',

        [string]$Severity = 'Info'
    )

    Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkSource' -Name $Name -Value $Value -Severity $Severity -Source 'Collect-Benchmarks.ps1' -Message $Message
}

function Get-BenchmarkImportRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [string]$Message = '',

        [string]$Severity = 'Info'
    )

    Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkImport' -Name $Name -Value $Value -Severity $Severity -Source 'Collect-Benchmarks.ps1' -Message $Message
}

function Get-WinSATCollectionStatus {
    [CmdletBinding()]
    param(
        [string]$ErrorMessage
    )

    if ([string]::IsNullOrWhiteSpace($ErrorMessage)) {
        return 'NoResultYet'
    }

    if ($ErrorMessage -match 'Access is denied|Zugriff verweigert') {
        return 'CollectionBlocked'
    }

    return 'NoResultYet'
}

function Get-ConfiguredBenchmarkImportRoots {
    [CmdletBinding()]
    param()

    $projectRoot = Get-ProjectRoot
    [pscustomobject]@{
        PcMark10 = Join-Path $projectRoot 'BenchmarkImports\PCMark10'
        UnigineHeaven = Join-Path $projectRoot 'BenchmarkImports\UnigineHeaven'
    }
}

function Get-ConfiguredBenchmarkSearchRoots {
    [CmdletBinding()]
    param()

    $profileRoot = [Environment]::GetFolderPath('UserProfile')
    [pscustomobject]@{
        PcMark10 = @(
            (Join-Path $profileRoot 'Desktop'),
            (Join-Path $profileRoot 'Documents'),
            (Join-Path $profileRoot 'Downloads')
        )
        UnigineHeaven = @(
            (Join-Path $profileRoot 'Desktop'),
            (Join-Path $profileRoot 'Documents'),
            (Join-Path $profileRoot 'Downloads')
        )
    }
}

function Get-LatestBenchmarkExportFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string[]]$Patterns
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return $null
    }

    $matches = foreach ($pattern in $Patterns) {
        Get-ChildItem -LiteralPath $Root -Filter $pattern -File -ErrorAction SilentlyContinue
    }

    $result = @($matches | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1)
    if (@($result).Count -eq 0) {
        return $null
    }

    return $result[0]
}

function Get-XmlNodeInnerText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [xml]$Document,

        [Parameter(Mandatory = $true)]
        [string[]]$NodeNames
    )

    foreach ($nodeName in $NodeNames) {
        $node = $Document.SelectSingleNode("//$nodeName")
        if ($node -and -not [string]::IsNullOrWhiteSpace($node.InnerText)) {
            return $node.InnerText
        }
    }

    return $null
}

function Import-PCMark10Export {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    [xml]$document = Get-Content -LiteralPath $Path -Raw
    $metrics = [System.Collections.Generic.List[object]]::new()

    $map = @(
        @{ Name = 'PCMark10:Overall'; Nodes = @('PCMark10Score', 'Score', 'OverallScore') },
        @{ Name = 'PCMark10:Essentials'; Nodes = @('EssentialsScore') },
        @{ Name = 'PCMark10:Productivity'; Nodes = @('ProductivityScore') },
        @{ Name = 'PCMark10:DigitalContentCreation'; Nodes = @('DigitalContentCreationScore') }
    )

    foreach ($item in $map) {
        $rawValue = Get-XmlNodeInnerText -Document $document -NodeNames $item.Nodes
        if (-not [string]::IsNullOrWhiteSpace($rawValue)) {
            $metrics.Add([pscustomobject]@{
                Name = $item.Name
                Value = [double]$rawValue
                Unit = 'score'
            })
        }
    }

    [pscustomobject]@{
        Source = 'PCMark10'
        Metrics = @($metrics)
        Path = $Path
    }
}

function Import-UnigineHeavenExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rows = @(Import-Csv -LiteralPath $Path)
    $metrics = [System.Collections.Generic.List[object]]::new()
    if (@($rows).Count -eq 0) {
        throw 'Unigine Heaven export contained no rows.'
    }

    $row = $rows[0]
    if ($row.PSObject.Properties['Score']) {
        $metrics.Add([pscustomobject]@{
            Name = 'UnigineHeaven:Score'
            Value = [double]$row.Score
            Unit = 'score'
        })
    }

    if ($row.PSObject.Properties['FPS']) {
        $metrics.Add([pscustomobject]@{
            Name = 'UnigineHeaven:FPS'
            Value = [double]$row.FPS
            Unit = 'fps'
        })
    }

    [pscustomobject]@{
        Source = 'UnigineHeaven'
        Metrics = @($metrics)
        Path = $Path
    }
}

function Add-NormalizedBenchmarkMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]]$Target,

        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [object[]]$Metrics
    )

    foreach ($metric in @($Metrics)) {
        $Target.Add((Write-DiagnosticRecord -RunContext $RunContext -Category 'Benchmark' -Name $metric.Name -Value $metric.Value -Unit $metric.Unit -Severity 'Info' -Source 'Collect-Benchmarks.ps1' -Message ('ParsedSuccessfully from {0}' -f $Source)))
    }
}

function Get-BenchmarkImportDestinationPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $true)]
        [string]$SourceFilePath
    )

    $sourceItem = Get-Item -LiteralPath $SourceFilePath -ErrorAction Stop
    $candidate = Join-Path $DestinationRoot $sourceItem.Name

    if (-not (Test-Path -LiteralPath $candidate)) {
        return [pscustomobject]@{ Path = $candidate; Status = 'NewFile' }
    }

    $sourceHash = (Get-FileHash -LiteralPath $sourceItem.FullName -Algorithm SHA256).Hash
    $existingHash = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
    if ($sourceHash -eq $existingHash) {
        return [pscustomobject]@{ Path = $candidate; Status = 'AlreadyImported' }
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($sourceItem.Name)
    $extension = [System.IO.Path]::GetExtension($sourceItem.Name)
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $alternate = Join-Path $DestinationRoot ('{0}-{1}{2}' -f $baseName, $timestamp, $extension)
    return [pscustomobject]@{ Path = $alternate; Status = 'ConflictCopy' }
}

function Sync-BenchmarkImports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [string[]]$PcMarkSourceRoots,

        [string[]]$HeavenSourceRoots,

        [string]$PcMarkImportRoot,

        [string]$HeavenImportRoot,

        [switch]$DryRun
    )

    $records = [System.Collections.Generic.List[object]]::new()
    $importRoots = Get-ConfiguredBenchmarkImportRoots
    $searchRoots = Get-ConfiguredBenchmarkSearchRoots

    if (-not $PcMarkSourceRoots) { $PcMarkSourceRoots = @($searchRoots.PcMark10) }
    if (-not $HeavenSourceRoots) { $HeavenSourceRoots = @($searchRoots.UnigineHeaven) }
    if ([string]::IsNullOrWhiteSpace($PcMarkImportRoot)) { $PcMarkImportRoot = $importRoots.PcMark10 }
    if ([string]::IsNullOrWhiteSpace($HeavenImportRoot)) { $HeavenImportRoot = $importRoots.UnigineHeaven }

    foreach ($targetDir in @($PcMarkImportRoot, $HeavenImportRoot)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    if ($DryRun) {
        $records.Add((Get-BenchmarkImportRecord -RunContext $RunContext -Name 'PCMark10' -Value 'DryRun' -Message 'Benchmark import sync skipped in dry run'))
        $records.Add((Get-BenchmarkImportRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'DryRun' -Message 'Benchmark import sync skipped in dry run'))
        return $records
    }

    $syncPlans = @(
        @{ Name = 'PCMark10'; SourceRoots = @($PcMarkSourceRoots); Patterns = @('*.xml'); DestinationRoot = $PcMarkImportRoot },
        @{ Name = 'UnigineHeaven'; SourceRoots = @($HeavenSourceRoots); Patterns = @('*.csv'); DestinationRoot = $HeavenImportRoot }
    )

    foreach ($plan in $syncPlans) {
        $matchedFiles = [System.Collections.Generic.List[object]]::new()
        foreach ($root in @($plan.SourceRoots)) {
            if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) {
                continue
            }

            foreach ($pattern in @($plan.Patterns)) {
                @(Get-ChildItem -LiteralPath $root -Filter $pattern -File -Recurse -ErrorAction SilentlyContinue) | ForEach-Object {
                    $matchedFiles.Add($_)
                }
            }
        }

        if (@($matchedFiles).Count -eq 0) {
            $records.Add((Get-BenchmarkImportRecord -RunContext $RunContext -Name $plan.Name -Value 'NoFilesFound' -Message 'No matching export files found in trusted source folders'))
            continue
        }

        $finalStatus = $null
        $finalMessage = ''
        foreach ($file in @($matchedFiles | Sort-Object LastWriteTimeUtc -Descending)) {
            $destination = Get-BenchmarkImportDestinationPath -DestinationRoot $plan.DestinationRoot -SourceFilePath $file.FullName
            if ($destination.Status -eq 'AlreadyImported') {
                if ($finalStatus -ne 'Imported') {
                    $finalStatus = 'AlreadyImported'
                    $finalMessage = 'Latest matching export already exists in import folder'
                }
                continue
            }

            Copy-Item -LiteralPath $file.FullName -Destination $destination.Path -Force
            $finalStatus = 'Imported'
            $finalMessage = 'Copied benchmark exports into import folder'
        }

        if ([string]::IsNullOrWhiteSpace($finalStatus)) {
            $finalStatus = 'NoFilesFound'
        }

        if ([string]::IsNullOrWhiteSpace($finalMessage)) {
            $finalMessage = if ($finalStatus -eq 'AlreadyImported') { 'Latest matching export already exists in import folder' } else { 'Copied benchmark exports into import folder' }
        }

        $records.Add((Get-BenchmarkImportRecord -RunContext $RunContext -Name $plan.Name -Value $finalStatus -Message $finalMessage))
    }

    return $records
}

function Collect-Benchmarks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [switch]$DryRun,

        [string]$PcMarkImportRoot,

        [string]$HeavenImportRoot
    )

    $out = [System.Collections.Generic.List[object]]::new()
    $defaults = Get-ConfiguredBenchmarkImportRoots
    if ([string]::IsNullOrWhiteSpace($PcMarkImportRoot)) {
        $PcMarkImportRoot = $defaults.PcMark10
    }
    if ([string]::IsNullOrWhiteSpace($HeavenImportRoot)) {
        $HeavenImportRoot = $defaults.UnigineHeaven
    }

    if ($DryRun) {
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'WinSAT' -Value 'NoResultYet' -Message 'Dry run skips benchmark collection'))
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'PCMark10' -Value 'NoResultYet' -Message 'Dry run; parser ready but no export imported'))
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'NoResultYet' -Message 'Dry run; parser ready but no export imported'))
        return $out
    }

    try {
        $winsat = Get-WinSATInstance
        $scores = @(
            @{ Name = 'WinSAT:CPUScore'; Value = $winsat.CPUScore },
            @{ Name = 'WinSAT:MemoryScore'; Value = $winsat.MemoryScore },
            @{ Name = 'WinSAT:DiskScore'; Value = $winsat.DiskScore }
        )

        $availableScores = @($scores | Where-Object { $null -ne $_.Value -and [double]$_.Value -gt 0 })
        if (@($availableScores).Count -gt 0) {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'WinSAT' -Value 'DataAvailable' -Message 'WinSAT benchmark values collected'))
            foreach ($score in $availableScores) {
                $out.Add((Write-DiagnosticRecord -RunContext $RunContext -Category 'Benchmark' -Name $score.Name -Value ([math]::Round([double]$score.Value, 1)) -Unit 'score' -Severity 'Info' -Source 'Collect-Benchmarks.ps1' -Message 'ParsedSuccessfully'))
            }
        }
        else {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'WinSAT' -Value 'NoResultYet' -Message 'WinSAT is present but no benchmark values were available'))
        }
    }
    catch {
        $status = Get-WinSATCollectionStatus -ErrorMessage $_.Exception.Message
        $severity = if ($status -eq 'CollectionBlocked') { 'Warning' } else { 'Info' }
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'WinSAT' -Value $status -Severity $severity -Message $_.Exception.Message))
    }

    $pcMarkFile = Get-LatestBenchmarkExportFile -Root $PcMarkImportRoot -Patterns @('*.xml')
    if ($pcMarkFile) {
        $pcMark = Import-PCMark10Export -Path $pcMarkFile.FullName
        if (@($pcMark.Metrics).Count -gt 0) {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'PCMark10' -Value 'DataAvailable' -Message ('ParsedSuccessfully from {0}' -f $pcMarkFile.Name)))
            Add-NormalizedBenchmarkMetrics -RunContext $RunContext -Target $out -Source 'PCMark10' -Metrics $pcMark.Metrics
        } else {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'PCMark10' -Value 'NoResultYet' -Message ('Export found but no supported scores were detected in {0}' -f $pcMarkFile.Name)))
        }
    } else {
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'PCMark10' -Value 'NoResultYet' -Message 'No PCMark 10 XML export found'))
    }

    $heavenFile = Get-LatestBenchmarkExportFile -Root $HeavenImportRoot -Patterns @('*.csv')
    if ($heavenFile) {
        $heaven = Import-UnigineHeavenExport -Path $heavenFile.FullName
        if (@($heaven.Metrics).Count -gt 0) {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'DataAvailable' -Message ('ParsedSuccessfully from {0}' -f $heavenFile.Name)))
            Add-NormalizedBenchmarkMetrics -RunContext $RunContext -Target $out -Source 'UnigineHeaven' -Metrics $heaven.Metrics
        } else {
            $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'NoResultYet' -Message ('Export found but no supported scores were detected in {0}' -f $heavenFile.Name)))
        }
    } else {
        $out.Add((Get-BenchmarkSourceRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'NoResultYet' -Message 'No Unigine Heaven CSV export found'))
    }

    return $out
}
