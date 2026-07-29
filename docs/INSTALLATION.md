# Installation

## Purpose

This repository packages a portable Windows performance diagnostics toolkit. The repository itself does not include large installer binaries on GitHub. Local operators place approved binaries into `Installers/` before running installation automation.

## Requirements

- Windows 10 or Windows 11 x64
- PowerShell 5.1 or newer
- Administrative shell for installer execution when needed
- Enough free disk space for reports and raw logs

## Repository Setup

1. Clone or copy the repository to a local folder.
2. Place approved tool installers into `Installers/`.
3. Review `Config/tools.json` and `Config/diagnostics.json`.
4. Open PowerShell as Administrator if tool installation is planned.

## Supported Local Payloads

The current repository structure expects filenames that match the tool manifest in `Config/tools.json`.

- `cpu-z_2.18-en.exe`
- `TreeSizeFreeSetup.exe`
- `Unigine_Heaven-4.0.exe`
- `Wireshark-4.6.3-x64.exe`
- Optional ZIP payloads and additional manual tools listed in the manifest

## First Validation

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -OutputRoot .\FirstValidationOutput
```

## What Is Deliberately Excluded

- Automatic admin password handling
- Automatic cleanup or repair tools
- Automatic packet capture
- CHIP wrapper installers and generic cleanup software

## Output Root Behavior

The toolkit creates `Reports`, `Logs`, and `Raw` beneath the path passed to `-OutputRoot`. For example, `-OutputRoot .\FirstValidationOutput` produces results under `.\FirstValidationOutput\Reports\`.
