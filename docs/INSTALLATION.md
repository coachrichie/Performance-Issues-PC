# Installation

## Purpose

This repository packages a portable Windows performance diagnostics toolkit for IT support triage. The preferred deployment model is a copied folder on the target PC plus one guided entry point: `Performance Test.cmd`.

## Requirements

- Windows 10 or Windows 11 x64
- PowerShell 5.1 or newer
- Local administrator approval when installations or privileged queries are needed
- Enough free disk space for reports, raw logs, and optional benchmark exports

## Preferred Setup

1. Copy or clone the repository to a local folder.
2. Place approved support tools into `ToolkitPrograms\AutoInstall\`.
3. Place optional/manual tools into `ToolkitPrograms\Optional\`.
4. Review `Config\tools.json`, `Config\diagnostics.json`, and `Config\benchmark-references.json`.
5. Start `Performance Test.cmd` or run a dry-run first.

## Recommended Folder Preparation For Customer Use

Preferred staging:

- `ToolkitPrograms\AutoInstall\`
- `ToolkitPrograms\Optional\`

Recommended examples:

- CPU-Z
- TreeSize Free
- Unigine Heaven
- Wireshark
- CrystalDiskInfo
- Autoruns
- Process Explorer

## Legacy Fallback

If a file is not found in `ToolkitPrograms\AutoInstall\`, the toolkit still checks the older `Installers\` folder.

## Typical Approved Payloads

Expected filenames are defined in `Config\tools.json`. Current examples include:

- `cpu-z_2.18-en.exe`
- `TreeSizeFreeSetup.exe`
- `Unigine_Heaven-4.0.exe`
- `Wireshark-4.6.3-x64.exe`
- `CrystalDiskInfo.zip`
- `Autoruns.zip`
- `ProcessExplorer.zip`

## First Validation

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools -OutputRoot .\FirstValidationOutput
.\Create-Distributions.ps1
```

## Deliberately Excluded

- Automatic admin password handling
- Automatic cleanup or repair tools
- Automatic packet capture
- CHIP wrapper installers and generic cleanup software

## Output Root Behavior

The toolkit creates `Reports`, `Logs`, and `Raw` beneath the path passed to `-OutputRoot`. Each run generates a timestamped run folder and normally produces:

- `Abschlussbericht.html`
- `Rohbewertung.html`
- `Records.csv`
- `Run.zip`
