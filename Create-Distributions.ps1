[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distributionRoot = Join-Path $projectRoot 'Distributions'
$customerRoot = Join-Path $distributionRoot 'Customer Toolkit'
$githubRoot = Join-Path $distributionRoot 'GitHub Repository'

function Reset-Folder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Copy-ProjectItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Ensure-Folder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

Reset-Folder -Path $distributionRoot
Reset-Folder -Path $customerRoot
Reset-Folder -Path $githubRoot

$sharedItems = @(
    'Config',
    'Scripts',
    'docs',
    'BenchmarkImports',
    'ToolkitPrograms',
    'README.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'LICENSE',
    'CODE_OF_CONDUCT.md',
    '.gitignore',
    '.gitattributes',
    'SECURITY.md',
    'Start-Diagnose.cmd',
    'Start-Diagnose.ps1',
    'Performance Test.cmd',
    'Performance Test.ps1',
    'PC-Performance-Diagnose-Dokumentation.docx',
    'build_documentation.py',
    'Create-Distributions.ps1'
)

foreach ($item in $sharedItems) {
    Copy-ProjectItem -Source (Join-Path $projectRoot $item) -Destination $customerRoot
}

$githubOnlyItems = @(
    '.github',
    'Tests'
)

foreach ($item in $sharedItems + $githubOnlyItems) {
    Copy-ProjectItem -Source (Join-Path $projectRoot $item) -Destination $githubRoot
}

$customerExtraFolders = @(
    'Reports',
    'Logs',
    'Raw',
    'Installers',
    'ToolkitPrograms\Installed',
    'BenchmarkImports\PCMark10',
    'BenchmarkImports\UnigineHeaven'
)

foreach ($folder in $customerExtraFolders) {
    Ensure-Folder -Path (Join-Path $customerRoot $folder)
}

@'
Lege in diesem Ordner die freigegebenen Installer-Dateien fuer den Kundeneinsatz ab.

Empfohlene Pfade:
- ToolkitPrograms\AutoInstall\
- ToolkitPrograms\Optional\

Starte danach beim Kunden:
- Performance Test.cmd
'@ | Set-Content -LiteralPath (Join-Path $customerRoot 'KUNDEN-START.txt') -Encoding UTF8

@'
Version: 0.1.x
Stand: 2026-07-29
Zweck: IT-Support-Triage fuer Windows-Performance-Probleme
'@ | Set-Content -LiteralPath (Join-Path $customerRoot 'VERSION.txt') -Encoding UTF8

@'
Dieser Ordner ist fuer GitHub oder interne Versionsverwaltung vorbereitet.

Nicht enthalten sein sollten:
- Kundenberichte
- sensible Rohdaten
- lokale Benchmark-Exporte
- nicht freigegebene Installer
'@ | Set-Content -LiteralPath (Join-Path $githubRoot 'GITHUB-HINWEIS.txt') -Encoding UTF8

@'
Version: 0.1.x
Stand: 2026-07-29
Zweck: GitHub-/Quellcode-Export des Performance-Toolkits
'@ | Set-Content -LiteralPath (Join-Path $githubRoot 'VERSION.txt') -Encoding UTF8

Write-Output "Customer Toolkit: $customerRoot"
Write-Output "GitHub Repository: $githubRoot"
