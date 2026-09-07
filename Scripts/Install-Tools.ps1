Set-StrictMode -Version Latest

. "$PSScriptRoot/Common.ps1"

function Get-InstallerManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $resolvedManifestPath = Resolve-ProjectPath -Path $ManifestPath
    $manifest = Get-Content -LiteralPath $resolvedManifestPath -Raw | ConvertFrom-Json

    if (-not $manifest -or -not $manifest.Tools) {
        throw "Installer manifest is missing a Tools collection: $resolvedManifestPath"
    }

    return $manifest
}

function Test-BlockedInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Tool
    )

    $blockedPattern = '(?i)(chip|pc-putzer|revo)'
    return ($Tool.Name -match $blockedPattern) -or ($Tool.SourceFile -match $blockedPattern)
}

function Test-FixedArgumentArray {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$InstallArguments
    )

    if (-not ($InstallArguments -is [System.Array])) {
        return $false
    }

    foreach ($argument in $InstallArguments) {
        if ($argument -isnot [string]) {
            return $false
        }
    }

    return $true
}

function Resolve-InstallerSourcePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile
    )

    $preferredRoot = Resolve-ProjectPath -Path 'ToolkitPrograms\AutoInstall' -AllowMissing
    $fallbackRoot = Resolve-ProjectPath -Path 'Installers' -AllowMissing

    $preferredPath = Resolve-ProjectPath -Path $SourceFile -BasePath $preferredRoot -AllowMissing
    if (Test-Path -LiteralPath $preferredPath) {
        return $preferredPath
    }

    return Resolve-ProjectPath -Path $SourceFile -BasePath $fallbackRoot -AllowMissing
}

function New-InstallerResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Tool,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,

        [Parameter(Mandatory = $true)]
        [datetime]$EndedAt,

        [AllowNull()]
        [string]$SourcePath,

        [AllowNull()]
        [Nullable[int]]$ExitCode,

        [AllowNull()]
        [string]$Error
    )

    $arguments = if ($Tool.InstallArguments -is [System.Array]) {
        @($Tool.InstallArguments)
    }
    elseif ($null -eq $Tool.InstallArguments) {
        @()
    }
    else {
        @($Tool.InstallArguments)
    }

    [pscustomobject]@{
        RunId = ''
        Timestamp = (Get-Date).ToString('o')
        Category = 'Installer'
        Name = [string]$Tool.Name
        Value = $Status
        Unit = ''
        Severity = if ($Status -eq 'Error') { 'Error' } elseif ($Status -eq 'Warning') { 'Warning' } else { 'Info' }
        Source = 'Install-Tools.ps1'
        Message = if ($Error) { $Error } elseif ($SourcePath) { "Source: $SourcePath" } else { '' }
        SourceFile = [string]$Tool.SourceFile
        SourcePath = $SourcePath
        Status = $Status
        StartedAt = $StartedAt.ToString('o')
        EndedAt = $EndedAt.ToString('o')
        ExitCode = $ExitCode
        Error = $Error
        InstallArguments = [object]$arguments
    }
}

function Get-InstalledToolsRoot {
    [CmdletBinding()]
    param()

    $root = Resolve-ProjectPath -Path 'ToolkitPrograms\Installed' -AllowMissing
    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    return $root
}

function Get-SafeToolDirectoryName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return ($Name -replace '[^A-Za-z0-9]+', '')
}

function Get-AllowlistedTools {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $manifest = Get-InstallerManifest -ManifestPath $ManifestPath

    foreach ($tool in $manifest.Tools) {
        if ($tool.AutoInstall -ne $true) {
            continue
        }

        if (Test-BlockedInstaller -Tool $tool) {
            continue
        }

        $tool
    }
}

function Get-InstallMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Tool
    )

    if ($Tool.PSObject.Properties['InstallMode'] -and -not [string]::IsNullOrWhiteSpace([string]$Tool.InstallMode)) {
        return [string]$Tool.InstallMode
    }

    return 'Installer'
}

function Install-AllowlistedTools {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [psobject]$RunContext,

        [switch]$DryRun
    )

    $results = @()
    $tools = @(Get-AllowlistedTools -ManifestPath $ManifestPath)

    foreach ($tool in $tools) {
        $startedAt = Get-Date
        $status = 'Pending'
        $sourcePath = $null
        $exitCode = $null
        $errorMessage = $null

        try {
            if (-not (Test-FixedArgumentArray -InstallArguments $tool.InstallArguments)) {
                $status = 'Warning'
                $errorMessage = 'InstallArguments must be a fixed array of strings.'
            }
            else {
                $sourcePath = Resolve-InstallerSourcePath -SourceFile $tool.SourceFile
                $installMode = Get-InstallMode -Tool $tool

                if (-not (Test-Path -LiteralPath $sourcePath)) {
                    $status = 'Error'
                    $errorMessage = "Installer source file not found: $sourcePath"
                }
                elseif ($DryRun) {
                    $status = 'DryRun'
                }
                elseif ($installMode -eq 'Portable') {
                    $status = 'Prepared'
                }
                elseif ([System.IO.Path]::GetExtension($sourcePath) -ieq '.zip') {
                    $destinationRoot = Join-Path (Get-InstalledToolsRoot) (Get-SafeToolDirectoryName -Name $tool.Name)
                    if (Test-Path -LiteralPath $destinationRoot) {
                        Remove-Item -LiteralPath $destinationRoot -Recurse -Force
                    }
                    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
                    Expand-Archive -LiteralPath $sourcePath -DestinationPath $destinationRoot -Force
                    $status = 'Installed'
                }
                else {
                    $process = Start-Process -FilePath $sourcePath -ArgumentList $tool.InstallArguments -Wait -PassThru
                    $exitCode = $process.ExitCode

                    if ($exitCode -eq 0) {
                        $status = 'Installed'
                    }
                    else {
                        $status = 'Error'
                        $errorMessage = "Installer exited with code $exitCode."
                    }
                }
            }
        }
        catch {
            $status = 'Error'
            $errorMessage = $_.Exception.Message
        }

        $endedAt = Get-Date
        $results += New-InstallerResult -Tool $tool -Status $status -StartedAt $startedAt -EndedAt $endedAt -SourcePath $sourcePath -ExitCode $exitCode -Error $errorMessage
    }

    return $results
}
