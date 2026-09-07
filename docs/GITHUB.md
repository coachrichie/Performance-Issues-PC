# GitHub Export

## Goal

The GitHub version of this project should be clean, portable, and safe to publish internally or externally without customer runtime data.

## Included

- source scripts
- config
- tests
- Markdown documentation
- Word documentation
- GitHub workflow and templates
- project health files
- distribution builder

## Excluded Or Ignored

- generated reports
- raw logs
- customer-specific benchmark exports
- most local installer binaries
- local planning metadata

## Publish Checklist

1. Run the full Pester suite.
2. Run at least one dry-run validation.
3. Rebuild the Word documentation if content changed.
4. Regenerate `Distributions\GitHub Repository\`.
5. Confirm no customer logs or sensitive exports are present.

## Suggested Repository Use

- internal support engineering baseline
- repeatable triage toolkit
- controlled diagnostics automation
- benchmark comparison reference starter

## Do Not Publish Blindly

Before pushing anywhere public, review:

- `Config\tools.json`
- `Config\benchmark-references.json`
- `docs\`
- `PC-Performance-Diagnose-Dokumentation.docx`
- `.github\workflows\validate.yml`
- `.gitignore`

## Current AutoInstall Tool Sources

As of July 29, 2026, the repository's current `ToolkitPrograms\AutoInstall\` folder is aligned to the following tool set.

| Local file | Tool | Current role in project | Official source |
|---|---|---|---|
| `cpu-z_2.18-en.exe` | CPU-Z | AutoInstall, hardware identification | [CPUID CPU-Z](https://cpuid.com/softwares/cpu-z.html) |
| `CrystalDiskInfo9_9_2.exe` | CrystalDiskInfo | AutoInstall, health/temperature evaluation | [CrystalDiskInfo](https://crystalmark.info/en/software/crystaldiskinfo/) |
| `Autoruns64a.exe` | Autoruns | AutoInstall as portable GUI, manual startup review; automatic CSV parsing requires `Autorunsc` | [Autoruns / Autorunsc](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns) |
| `procexp.exe` | Process Explorer | AutoInstall as portable GUI, manual deep process inspection | [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer) |
| `Procmon.exe` | Process Monitor | AutoInstall as portable GUI, manual deep trace inspection | [Process Monitor](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon) |
| `Unigine_Heaven-4.0.exe` | UNIGINE Heaven | AutoInstall / benchmark support | [UNIGINE Heaven Benchmark](https://benchmark.unigine.com/heaven?lang=index.php) |
| `hwi_834x.exe` | HWiNFO | Useful for support triage, currently kept manual until automation parameters are verified | [HWiNFO](https://www.hwinfo.com/) |
| `hwmonitor_1.60.exe` | HWMonitor | Useful for support triage, currently kept manual until automation parameters are verified | [HWMonitor](https://www.cpuid.com/softwares/HWmonitor.html) |

## Notes On AutoInstall Interpretation

- Not every file in `ToolkitPrograms\AutoInstall\` is treated like a classic installer.
- The project distinguishes between:
  - silent installers
  - portable prepared tools
  - optional/manual tools
- This is intentional for support triage, because some utilities are far more useful as controlled manual inspection tools than as blind automated runs.

## Recommended GitHub Review Focus

When someone reviews or forks this project on GitHub, they should pay special attention to:

- `Config\tools.json`
- `Scripts\Install-Tools.ps1`
- `Scripts\Collect-SupportTools.ps1`
- `ToolkitPrograms\AutoInstall\README.md`

These files define how local binaries are interpreted and which tools are considered safe and useful for support-triage automation.

## Local Verification

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools -OutputRoot .\GitHubValidationOutput
.\Create-Distributions.ps1
```
