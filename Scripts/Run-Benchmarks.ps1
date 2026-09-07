. "$PSScriptRoot\Common.ps1"

function Get-BenchmarkAutomationRecord {
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

    Write-DiagnosticRecord -RunContext $RunContext -Category 'BenchmarkAutomation' -Name $Name -Value $Value -Severity $Severity -Source 'Run-Benchmarks.ps1' -Message $Message
}

function Get-BenchmarkToolConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    $manifestPath = Join-Path (Get-ProjectRoot) 'Config\tools.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    @($manifest.Tools | Where-Object { $_.Name -eq $ToolName } | Select-Object -First 1)[0]
}

function Get-BenchmarkSearchRoots {
    [CmdletBinding()]
    param(
        [string]$ToolName
    )

    $projectRoot = Get-ProjectRoot
    $safeName = ($ToolName -replace '[^A-Za-z0-9]+', '')
    @(
        (Join-Path $projectRoot ("BenchmarkTools\{0}" -f $safeName)),
        (Join-Path $projectRoot 'BenchmarkTools'),
        ${env:ProgramFiles},
        ${env:ProgramFiles(x86)}
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }
}

function Find-BenchmarkExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $true)]
        [string[]]$ExecutableHints
    )

    foreach ($root in @(Get-BenchmarkSearchRoots -ToolName $ToolName)) {
        foreach ($hint in $ExecutableHints) {
            $match = @(Get-ChildItem -LiteralPath $root -Filter $hint -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
            if (@($match).Count -gt 0) {
                return $match[0].FullName
            }
        }
    }

    return $null
}

function Get-PythonExecutablePath {
    [CmdletBinding()]
    param()

    $command = Get-Command python -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $pyCommand = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCommand) {
        return $pyCommand.Source
    }

    return $null
}

function New-PCMark10AutomationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory = $true)]
        [string]$ImportRoot
    )

    if ([System.IO.Path]::GetFileName($ExecutablePath) -ieq 'PCMark10Cmd.exe') {
        $resultBase = Join-Path $ImportRoot 'pcmark10-auto'
        return [pscustomobject]@{
            ToolName = 'PCMark10'
            Status = 'Ready'
            FilePath = $ExecutablePath
            WorkingDirectory = Split-Path -Parent $ExecutablePath
            ArgumentList = @(
                '--definition=pcm10_benchmark.pcmdef',
                ("--out={0}" -f (Join-Path $ImportRoot 'pcmark10-auto.pcmark-result')),
                ("--export-xml={0}" -f (Join-Path $ImportRoot 'pcmark10-auto.xml')),
                '--systeminfo=on',
                '--accepteula'
            )
            ExpectedOutputPath = (Join-Path $ImportRoot 'pcmark10-auto.xml')
        }
    }

    return [pscustomobject]@{
        ToolName = 'PCMark10'
        Status = 'UnsupportedEdition'
        FilePath = $ExecutablePath
        WorkingDirectory = Split-Path -Parent $ExecutablePath
        ArgumentList = @()
        ExpectedOutputPath = $null
    }
}

function New-UnigineHeavenAutomationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath,

        [string]$PythonPath,

        [Parameter(Mandatory = $true)]
        [string]$ImportRoot
    )

    $benchmarkRoot = Split-Path -Parent $ExecutablePath
    $automationScript = Join-Path $benchmarkRoot 'automation\single_run.py'
    if ([string]::IsNullOrWhiteSpace($PythonPath)) {
        return [pscustomobject]@{
            ToolName = 'UnigineHeaven'
            Status = 'AutomationUnavailable'
            FilePath = $ExecutablePath
            WorkingDirectory = $benchmarkRoot
            ArgumentList = @()
            ExpectedOutputPath = (Join-Path $ImportRoot 'heaven-auto.csv')
        }
    }

    return [pscustomobject]@{
        ToolName = 'UnigineHeaven'
        Status = 'Ready'
        FilePath = $PythonPath
        WorkingDirectory = $benchmarkRoot
        ArgumentList = @($automationScript)
        ExpectedOutputPath = (Join-Path $ImportRoot 'heaven-auto.csv')
    }
}

function Invoke-BenchmarkAutomationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [Parameter(Mandatory = $true)]
        [psobject]$Plan,

        [switch]$DryRun
    )

    $records = [System.Collections.Generic.List[object]]::new()

    if ($Plan.Status -ne 'Ready') {
        $severity = if ($Plan.Status -eq 'UnsupportedEdition') { 'Warning' } else { 'Info' }
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name $Plan.ToolName -Value $Plan.Status -Severity $severity -Message 'Automation plan was not executable'))
        return $records
    }

    if ($DryRun) {
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name $Plan.ToolName -Value 'DryRun' -Message 'Benchmark automation plan prepared but not executed'))
        return $records
    }

    try {
        $process = Start-Process -FilePath $Plan.FilePath -ArgumentList $Plan.ArgumentList -WorkingDirectory $Plan.WorkingDirectory -PassThru -WindowStyle Hidden
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name $Plan.ToolName -Value 'Started' -Message ('Started benchmark automation using {0}' -f $Plan.FilePath)))
    }
    catch {
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name $Plan.ToolName -Value 'LaunchFailed' -Severity 'Warning' -Message $_.Exception.Message))
    }

    return $records
}

function Invoke-ConfiguredBenchmarks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [switch]$DryRun
    )

    $records = [System.Collections.Generic.List[object]]::new()
    $importRoots = Get-ConfiguredBenchmarkImportRoots

    $pcMarkConfig = Get-BenchmarkToolConfig -ToolName 'PCMark 10'
    $pcMarkHints = @('PCMark10Cmd.exe')
    if ($pcMarkConfig -and $pcMarkConfig.ExecutableHints) {
        $pcMarkHints += @($pcMarkConfig.ExecutableHints)
    }
    $pcMarkExecutable = Find-BenchmarkExecutable -ToolName 'PCMark10' -ExecutableHints ($pcMarkHints | Select-Object -Unique)
    if ($pcMarkExecutable) {
        $pcMarkPlan = New-PCMark10AutomationPlan -ExecutablePath $pcMarkExecutable -ImportRoot $importRoots.PcMark10
        @(Invoke-BenchmarkAutomationPlan -RunContext $RunContext -Plan $pcMarkPlan -DryRun:$DryRun) | ForEach-Object { $records.Add($_) }
    } else {
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name 'PCMark10' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'No supported PCMark 10 executable was found'))
    }

    $heavenConfig = Get-BenchmarkToolConfig -ToolName 'Unigine Heaven'
    $heavenHints = @('Heaven.exe')
    if ($heavenConfig -and $heavenConfig.ExecutableHints) {
        $heavenHints += @($heavenConfig.ExecutableHints)
    }
    $heavenExecutable = Find-BenchmarkExecutable -ToolName 'UnigineHeaven' -ExecutableHints ($heavenHints | Select-Object -Unique)
    if ($heavenExecutable) {
        $heavenPlan = New-UnigineHeavenAutomationPlan -ExecutablePath $heavenExecutable -PythonPath (Get-PythonExecutablePath) -ImportRoot $importRoots.UnigineHeaven
        @(Invoke-BenchmarkAutomationPlan -RunContext $RunContext -Plan $heavenPlan -DryRun:$DryRun) | ForEach-Object { $records.Add($_) }
    } else {
        $records.Add((Get-BenchmarkAutomationRecord -RunContext $RunContext -Name 'UnigineHeaven' -Value 'ExecutableNotFound' -Severity 'Warning' -Message 'No supported Unigine Heaven executable was found'))
    }

    return $records
}
