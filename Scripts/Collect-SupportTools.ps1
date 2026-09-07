. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\Run-Benchmarks.ps1"

function Get-SupportToolRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [string]$Unit = '',

        [string]$Severity = 'Info',

        [string]$Message = ''
    )

    Write-DiagnosticRecord -RunContext $RunContext -Category 'SupportTool' -Name $Name -Value $Value -Unit $Unit -Severity $Severity -Source 'Collect-SupportTools.ps1' -Message $Message
}

function Import-CrystalDiskInfoText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Raw
    $metrics = [System.Collections.Generic.List[object]]::new()

    $healthMatch = [regex]::Match($content, 'Health Status\s*:\s*(.+)')
    if ($healthMatch.Success) {
        $metrics.Add([pscustomobject]@{
            Name = 'CrystalDiskInfo:HealthStatus'
            Value = $healthMatch.Groups[1].Value.Trim()
            Unit = ''
        })
    }

    $tempMatch = [regex]::Match($content, 'Temperature\s*:\s*([0-9]+)')
    if ($tempMatch.Success) {
        $metrics.Add([pscustomobject]@{
            Name = 'CrystalDiskInfo:Temperature'
            Value = [int]$tempMatch.Groups[1].Value
            Unit = 'C'
        })
    }

    [pscustomobject]@{
        Source = 'CrystalDiskInfo'
        Metrics = @($metrics)
        Path = $Path
    }
}

function Import-AutorunsCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rows = @(Import-Csv -LiteralPath $Path)
    $metrics = [System.Collections.Generic.List[object]]::new()
    $metrics.Add([pscustomobject]@{
        Name = 'Autoruns:TotalEntries'
        Value = @($rows).Count
        Unit = 'entries'
    })

    $unsignedCount = @(
        $rows | Where-Object {
            [string]::IsNullOrWhiteSpace($_.Signer) -or
            [string]::IsNullOrWhiteSpace($_.Verified) -or
            $_.Verified -notmatch '^Verified$'
        }
    ).Count
    $metrics.Add([pscustomobject]@{
        Name = 'Autoruns:UnsignedEntries'
        Value = $unsignedCount
        Unit = 'entries'
    })

    [pscustomobject]@{
        Source = 'Autoruns'
        Metrics = @($metrics)
        Path = $Path
    }
}

function Get-SupportToolExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $true)]
        [string[]]$ExecutableHints
    )

    $safeName = ($ToolName -replace '[^A-Za-z0-9]+', '')
    $projectRoot = Get-ProjectRoot
    $roots = @(
        (Join-Path $projectRoot ("ToolkitPrograms\Installed\{0}" -f $safeName)),
        (Join-Path $projectRoot 'ToolkitPrograms\AutoInstall'),
        (Join-Path $projectRoot 'ToolkitPrograms\Optional'),
        ${env:ProgramFiles},
        ${env:ProgramFiles(x86)}
    ) | Where-Object { Test-Path -LiteralPath $_ }

    foreach ($root in $roots) {
        foreach ($hint in $ExecutableHints) {
            $match = @(Get-ChildItem -LiteralPath $root -Filter $hint -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
            if (@($match).Count -gt 0) {
                return $match[0].FullName
            }
        }
    }

    return $null
}

function Invoke-SupportTools {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [switch]$DryRun
    )

    $records = [System.Collections.Generic.List[object]]::new()

    $crystalPath = Get-SupportToolExecutable -ToolName 'CrystalDiskInfo' -ExecutableHints @('DiskInfo64.exe', 'DiskInfo32.exe', 'DiskInfo.exe')
    if ($DryRun) {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'CrystalDiskInfo:Run' -Value 'DryRun' -Message 'CrystalDiskInfo execution skipped in dry run'))
    } elseif ($crystalPath) {
        try {
            $workingDir = $RunContext.LogsPath
            $process = Start-Process -FilePath $crystalPath -ArgumentList @('/CopyExit') -WorkingDirectory $workingDir -Wait -PassThru
            $dumpPath = Join-Path $workingDir 'DiskInfo.txt'
            if (Test-Path -LiteralPath $dumpPath) {
                $parsed = Import-CrystalDiskInfoText -Path $dumpPath
                foreach ($metric in @($parsed.Metrics)) {
                    $severity = if ($metric.Name -eq 'CrystalDiskInfo:HealthStatus' -and "$($metric.Value)" -notmatch 'Good|Healthy') { 'Warning' } else { 'Info' }
                    $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name $metric.Name -Value $metric.Value -Unit $metric.Unit -Severity $severity -Message 'Imported from CrystalDiskInfo log'))
                }
            } else {
                $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'CrystalDiskInfo:Run' -Value 'NoLogFile' -Severity 'Warning' -Message 'CrystalDiskInfo completed without DiskInfo.txt'))
            }
        } catch {
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'CrystalDiskInfo:Run' -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
        }
    } else {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'CrystalDiskInfo:Run' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'CrystalDiskInfo executable not found'))
    }

    $autorunsPath = Get-SupportToolExecutable -ToolName 'Autoruns' -ExecutableHints @('Autorunsc64.exe', 'Autorunsc.exe')
    if ($DryRun) {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'DryRun' -Message 'Autoruns execution skipped in dry run'))
    } elseif ($autorunsPath) {
        try {
            $csvPath = Join-Path $RunContext.LogsPath 'Autoruns.csv'
            $process = Start-Process -FilePath $autorunsPath -ArgumentList @('-a', '*', '-c', '-h', '-s', '-m', '-accepteula') -RedirectStandardOutput $csvPath -Wait -PassThru -WindowStyle Hidden
            if (Test-Path -LiteralPath $csvPath) {
                $parsed = Import-AutorunsCsv -Path $csvPath
                foreach ($metric in @($parsed.Metrics)) {
                    $severity = if ($metric.Name -eq 'Autoruns:TotalEntries' -and [int]$metric.Value -gt 40) { 'Warning' } else { 'Info' }
                    $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name $metric.Name -Value $metric.Value -Unit $metric.Unit -Severity $severity -Message 'Imported from Autoruns CSV'))
                }
            } else {
                $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'NoLogFile' -Severity 'Warning' -Message 'Autoruns completed without CSV output'))
            }
        } catch {
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
        }
    } else {
        $autorunsGuiPath = Get-SupportToolExecutable -ToolName 'Autoruns' -ExecutableHints @('Autoruns64a.exe', 'Autoruns64.exe', 'Autoruns.exe')
        if ($autorunsGuiPath) {
            try {
                $process = Start-Process -FilePath $autorunsGuiPath -PassThru
                $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'GuiLaunched' -Message 'Autoruns GUI started for manual autostart review; no CSV exporter was available'))
            } catch {
                $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
            }
        } else {
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'Autoruns:Run' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'Autoruns executable not found'))
        }
    }

    $procExpPath = Get-SupportToolExecutable -ToolName 'ProcessExplorer' -ExecutableHints @('procexp64.exe', 'procexp.exe')
    if ($DryRun) {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessExplorer:Run' -Value 'DryRun' -Message 'Process Explorer launch skipped in dry run'))
    } elseif ($procExpPath) {
        try {
            $process = Start-Process -FilePath $procExpPath -PassThru
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessExplorer:Run' -Value 'Launched' -Message 'Process Explorer started for interactive inspection; no official CLI log export configured'))
        } catch {
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessExplorer:Run' -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
        }
    } else {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessExplorer:Run' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'Process Explorer executable not found'))
    }

    $procmonPath = Get-SupportToolExecutable -ToolName 'ProcessMonitor' -ExecutableHints @('Procmon64.exe', 'Procmon.exe')
    if ($DryRun) {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessMonitor:Run' -Value 'DryRun' -Message 'Process Monitor launch skipped in dry run'))
    } elseif ($procmonPath) {
        try {
            $process = Start-Process -FilePath $procmonPath -PassThru
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessMonitor:Run' -Value 'Launched' -Message 'Process Monitor started for manual deep tracing; automatic trace capture remains disabled'))
        } catch {
            $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessMonitor:Run' -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
        }
    } else {
        $records.Add((Get-SupportToolRecord -RunContext $RunContext -Name 'ProcessMonitor:Run' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'Process Monitor executable not found'))
    }

    return $records
}
