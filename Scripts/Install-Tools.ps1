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

    $installersRoot = Resolve-ProjectPath -Path 'Installers' -AllowMissing
    return Resolve-ProjectPath -Path $SourceFile -BasePath $installersRoot -AllowMissing
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
        Name = [string]$Tool.Name
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

                if (-not (Test-Path -LiteralPath $sourcePath)) {
                    $status = 'Error'
                    $errorMessage = "Installer source file not found: $sourcePath"
                }
                elseif ($DryRun) {
                    $status = 'DryRun'
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
