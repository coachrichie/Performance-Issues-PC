# PC Performance Diagnostics

Portable Windows diagnostics toolkit for investigating performance issues on Windows 10 and Windows 11 x64 systems. The project collects read-only system, storage, memory, network, and report data and packages each run as HTML, CSV, ZIP, and raw records for later analysis.

## What This Repository Contains

- PowerShell launcher and orchestration scripts
- Configurable tool manifest and diagnostic thresholds
- Pester test suite
- Word documentation and GitHub-ready project files
- A local `Installers/` staging folder for approved binaries

## Safety Boundaries

- No automatic cleanup, uninstall, registry tuning, driver changes, or network reconfiguration
- No stored credentials and no admin password handling
- No automatic packet capture
- Only explicitly allowlisted tools are eligible for later automation
- Wireshark is never used for automatic packet capture
- Raw data can contain computer names, user names, file paths, process names, event data, and network context

## Quick Start

Open PowerShell as Administrator if you want the toolkit to install approved tools.

```powershell
.\Start-Diagnose.ps1 -DryRun
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests
.\Start-Diagnose.ps1 -OutputRoot .\ToolkitOutput
```

`-DryRun` skips installer execution and stress tooling. The scripts do not process or store an admin password. Real stress execution is currently kept disabled until a validated temperature source is integrated.

## Repository Layout

- `Config/` - diagnostic thresholds and tool manifest
- `Scripts/` - collectors, installers, stress modules, and report builder
- `Tests/` - Pester validation
- `Installers/` - locally staged binaries that stay out of GitHub
- `docs/` - installation, usage, diagnostics, and security documentation
- `Reports/` - generated runtime output, ignored by Git

When `-OutputRoot` is used, the toolkit creates `Reports`, `Logs`, and `Raw` underneath that chosen root.

## Documentation

- `docs/INSTALLATION.md`
- `docs/USAGE.md`
- `docs/DIAGNOSTICS.md`
- `docs/SECURITY.md`
- `PC-Performance-Diagnose-Dokumentation.docx`

## Local Verification

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -OutputRoot .\ReadmeValidationOutput
```

## Excluded Tools

PC-Putzer, Revo Uninstaller, and the CHIP-wrapped GPU-Z and Prime95 installers remain excluded from automatic execution and are not part of the approved automation path.
