# PC Performance Diagnostics

Portable Windows toolkit for IT support triage of performance issues on Windows 10 and Windows 11 x64 clients. The toolkit can install approved diagnostics, launch built-in and third-party checks, collect logs, and create both a management-friendly summary and a technical raw evaluation.

## Main Support Workflow

For customer use, copy the prepared toolkit folder to the target PC and start:

```powershell
.\Performance Test.cmd
```

`Performance Test.ps1` elevates with Windows UAC and then starts:

```powershell
.\Start-Diagnose.ps1 -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
```

Important:

- The toolkit does not capture or store an administrator password.
- Windows decides the UAC prompt flow; the toolkit does not bypass it.
- In the current build, live stress execution remains safely bounded and can still be skipped if no trustworthy sensor path is available.

## Deliverables Per Run

Each run creates:

- `Abschlussbericht.html` - concise support summary
- `Rohbewertung.html` - full technical raw evaluation
- `Records.csv` - normalized cumulative record export
- `Run.zip` - bundled report, raw data, and logs

When `-OutputRoot` is used, the toolkit creates `Reports`, `Logs`, and `Raw` below that root.

## What This Repository Contains

- PowerShell launchers and orchestration scripts
- Configurable manifests for tools, thresholds, and benchmark references
- Automated collection for Windows, storage, network, benchmark, and support-tool signals
- Pester test suite
- Word and Markdown documentation
- GitHub project scaffolding
- Distribution builder for customer and GitHub handoff folders

## Safety Boundaries

- No automatic cleanup, uninstall, registry tuning, driver changes, or network reconfiguration
- No stored credentials and no admin password handling
- No automatic packet capture
- Only explicitly allowlisted tools are eligible for automation
- Wireshark is never used for automatic packet capture
- Raw data can contain computer names, user names, file paths, process names, event data, and network context

## Supported Automated Areas

- Windows inventory and process context
- RAM, storage, and disk pressure indicators
- Benchmark import and triage comparison
- SMART/drive-health parsing through CrystalDiskInfo log export
- Autostart review through Autoruns export when the CLI variant exists, otherwise GUI launch for manual inspection
- Interactive deep inspection via Process Explorer and Process Monitor launch

## Current AutoInstall Triage Set

Based on the files currently present in `ToolkitPrograms/AutoInstall`, the most relevant triage set is:

- CPU-Z
- CrystalDiskInfo
- Autoruns
- Process Explorer
- Process Monitor
- Unigine Heaven

Useful but currently kept manual/optional until parameter verification:

- HWiNFO
- HWMonitor

## Quick Start

```powershell
.\Performance Test.cmd
.\Start-Diagnose.ps1 -DryRun
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
.\Start-Diagnose.ps1 -OutputRoot .\ToolkitOutput
.\Create-Distributions.ps1
```

## Repository Layout

- `Config/` - thresholds, tool manifest, benchmark reference data
- `Scripts/` - collectors, installers, support tools, benchmarks, stress logic, reporting
- `Tests/` - Pester validation
- `ToolkitPrograms/AutoInstall/` - preferred drop folder for automatically installable tools
- `ToolkitPrograms/Optional/` - optional/manual support tools
- `ToolkitPrograms/Installed/` - extracted ZIP-based portable tools during installation runs
- `BenchmarkImports/` - drop zone for PCMark 10 XML and Unigine Heaven CSV exports
- `Installers/` - legacy local staging folder, still supported as fallback
- `docs/` - installation, usage, diagnostics, distribution, and security documentation
- `Distributions/` - generated handoff folders for customer use and GitHub publication
- `Reports/` - generated runtime output, ignored by Git

## Tool Staging

Preferred customer-ready payloads belong here:

- `ToolkitPrograms/AutoInstall/`
- `ToolkitPrograms/Optional/`

Legacy fallback path:

- `Installers/`

## Documentation

- `docs/BEDIENUNGSANLEITUNG.md`
- `docs/INSTALLATION.md`
- `docs/USAGE.md`
- `docs/DIAGNOSTICS.md`
- `docs/SECURITY.md`
- `docs/DISTRIBUTION.md`
- `docs/GITHUB.md`
- `BenchmarkImports/README.md`
- `PC-Performance-Diagnose-Dokumentation.docx`

## Local Verification

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools -OutputRoot .\ReadmeValidationOutput
.\Create-Distributions.ps1
```

## Customer And GitHub Handoff

Create both prepared handoff folders with:

```powershell
.\Create-Distributions.ps1
```

Outputs:

- `Distributions\Customer Toolkit\`
- `Distributions\GitHub Repository\`

## Excluded Tools

PC-Putzer, Revo Uninstaller, and the CHIP-wrapped GPU-Z and Prime95 installers remain excluded from automatic execution and are not part of the approved automation path.
