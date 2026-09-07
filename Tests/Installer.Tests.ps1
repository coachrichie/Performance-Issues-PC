. "$PSScriptRoot/../Scripts/Common.ps1"

$installerScript = Join-Path $PSScriptRoot '../Scripts/Install-Tools.ps1'
if (Test-Path -LiteralPath $installerScript) {
    . $installerScript
}

function New-TestManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [object[]]$Tools
    )

    $manifest = @{
        Tools = $Tools
    }

    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8
}

Describe 'allowlisted installer execution' {
    BeforeAll {
        $script:ProjectRoot = Split-Path -Parent $PSScriptRoot
        $script:InstallerRoot = Join-Path $script:ProjectRoot 'Installers'
        $script:PreferredInstallerRoot = Join-Path $script:ProjectRoot 'ToolkitPrograms\AutoInstall'
        $script:FixtureRoot = Join-Path $PSScriptRoot 'fixtures'
        $script:FixtureOutputRoot = Join-Path $PSScriptRoot 'TestOutput'
        $script:FixtureRunId = [Guid]::NewGuid().ToString()
        $script:InstallerFixtureRelativeRoot = Join-Path 'PesterFixtures' $script:FixtureRunId
        $script:InstallerFixtureRoot = Join-Path $script:InstallerRoot $script:InstallerFixtureRelativeRoot
        $script:PreferredInstallerFixtureRoot = Join-Path $script:PreferredInstallerRoot $script:InstallerFixtureRelativeRoot
        $script:ManifestFixtureRoot = Join-Path $script:FixtureRoot $script:FixtureRunId
        $script:OutputFixtureRoot = Join-Path $script:FixtureOutputRoot $script:FixtureRunId

        foreach ($path in @($script:InstallerRoot, $script:PreferredInstallerRoot, $script:FixtureRoot, $script:FixtureOutputRoot, $script:InstallerFixtureRoot, $script:PreferredInstallerFixtureRoot, $script:ManifestFixtureRoot, $script:OutputFixtureRoot)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }

        Set-Content -LiteralPath (Join-Path $script:InstallerFixtureRoot 'test-tool.exe') -Value 'placeholder executable' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:InstallerFixtureRoot 'second-tool.exe') -Value 'placeholder executable' -Encoding UTF8

        $script:RunContext = New-RunContext -OutputRoot $script:OutputFixtureRoot
    }

    AfterAll {
        foreach ($path in @($script:InstallerFixtureRoot, $script:PreferredInstallerFixtureRoot, $script:ManifestFixtureRoot, $script:OutputFixtureRoot)) {
            if (Test-Path -LiteralPath $path) {
                Remove-Item -LiteralPath $path -Recurse -Force
            }
        }
    }

    It 'stores installer arguments as fixed arrays in the checked-in manifest' {
        $manifest = Get-Content "$PSScriptRoot/../Config/tools.json" -Raw | ConvertFrom-Json

        foreach ($tool in $manifest.Tools) {
            ($tool.InstallArguments -is [System.Array]) | Should Be $true
        }
    }

    It 'returns only auto-install tools and excludes blocked installers' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'allowlisted-tools.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'TestTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'test-tool.exe')
                InstallArguments = @('/S')
                AutoInstall = $true
            },
            @{
                Name = 'PC-Putzer Deluxe'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'pc-putzer.exe')
                InstallArguments = @('/S')
                AutoInstall = $true
            },
            @{
                Name = 'CHIP Downloader'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'chip-installer.exe')
                InstallArguments = @('/S')
                AutoInstall = $true
            },
            @{
                Name = 'ManualTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'manual-tool.exe')
                InstallArguments = @('/S')
                AutoInstall = $false
            }
        )

        $tools = Get-AllowlistedTools -ManifestPath $manifestPath

        @($tools.Name) | Should Be @('TestTool')
    }

    It 'returns one dry-run record per allowlisted attempt without launching installers' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'dry-run-tools.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'TestTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'test-tool.exe')
                InstallArguments = @('/S')
                AutoInstall = $true
            },
            @{
                Name = 'SecondTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'second-tool.exe')
                InstallArguments = @('/quiet')
                AutoInstall = $true
            },
            @{
                Name = 'SkippedTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'manual-tool.exe')
                InstallArguments = @('/S')
                AutoInstall = $false
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext -DryRun

        @($result).Count | Should Be 2
        @($result | ForEach-Object Name) | Should Be @('TestTool', 'SecondTool')
        @($result | Select-Object -ExpandProperty Status | Sort-Object -Unique) | Should Be @('DryRun')
        @($result | Where-Object { -not $_.StartedAt -or -not $_.EndedAt }).Count | Should Be 0
        @($result | Where-Object { $_.ExitCode -ne $null }).Count | Should Be 0
        @($result | Where-Object { $_.Error }).Count | Should Be 0
        @($result | Select-Object -ExpandProperty Category | Sort-Object -Unique) | Should Be @('Installer')
    }

    It 'returns an error record when a source path escapes the project root' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'unsafe-path-tools.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'EscapingTool'
                SourceFile = '..\..\outside.exe'
                InstallArguments = @('/S')
                AutoInstall = $true
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext -DryRun

        @($result).Count | Should Be 1
        $result[0].Status | Should Be 'Error'
        $result[0].Error | Should Match 'project root'
    }

    It 'returns a warning record when install arguments are not a fixed array' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'invalid-arguments-tools.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'BadArgumentsTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'test-tool.exe')
                InstallArguments = '/S /quiet'
                AutoInstall = $true
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext -DryRun

        @($result).Count | Should Be 1
        $result[0].Status | Should Be 'Warning'
        $result[0].Error | Should Match 'InstallArguments'
    }

    It 'returns an error record when an allowlisted installer file is missing' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'missing-tool.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'MissingTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'missing-tool.exe')
                InstallArguments = @('/S')
                AutoInstall = $true
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext -DryRun

        @($result).Count | Should Be 1
        $result[0].Status | Should Be 'Error'
        $result[0].Error | Should Match 'not found'
    }

    It 'prefers ToolkitPrograms AutoInstall over the legacy Installers folder' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'preferred-root.json'
        $relativeFile = Join-Path $script:InstallerFixtureRelativeRoot 'preferred-tool.exe'
        Set-Content -LiteralPath (Join-Path $script:InstallerFixtureRoot 'preferred-tool.exe') -Value 'legacy copy' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:PreferredInstallerFixtureRoot 'preferred-tool.exe') -Value 'preferred copy' -Encoding UTF8

        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'PreferredTool'
                SourceFile = $relativeFile
                InstallArguments = @('/S')
                AutoInstall = $true
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext -DryRun

        $result[0].SourcePath | Should Match 'ToolkitPrograms\\AutoInstall'
    }

    It 'marks portable allowlisted tools as prepared without launching them' {
        $manifestPath = Join-Path $script:ManifestFixtureRoot 'portable-tool.json'
        New-TestManifest -Path $manifestPath -Tools @(
            @{
                Name = 'PortableTool'
                SourceFile = (Join-Path $script:InstallerFixtureRelativeRoot 'test-tool.exe')
                InstallArguments = @()
                InstallMode = 'Portable'
                AutoInstall = $true
            }
        )

        $result = Install-AllowlistedTools -ManifestPath $manifestPath -RunContext $script:RunContext

        @($result).Count | Should Be 1
        $result[0].Status | Should Be 'Prepared'
        $result[0].ExitCode | Should Be $null
    }
}
