[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-File', ('"{0}"' -f $PSCommandPath)
    )

    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait
    exit $LASTEXITCODE
}

$startScript = Join-Path $PSScriptRoot 'Start-Diagnose.ps1'
& $startScript -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
exit $LASTEXITCODE
