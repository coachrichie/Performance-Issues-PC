# Usage

## Primary Entry Point

- `Performance Test.cmd`

This is the intended customer-facing launcher. It starts `Performance Test.ps1`, requests elevation through Windows UAC, and then runs the full workflow.

## Secondary Entry Points

- `Start-Diagnose.cmd`
- `Start-Diagnose.ps1`

These are useful for engineering, dry-runs, and selective execution.

## Typical Commands

```powershell
.\Performance Test.cmd
.\Start-Diagnose.ps1 -DryRun
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
.\Start-Diagnose.ps1 -OutputRoot .\Reports
```

## Current Full Workflow

`Performance Test.ps1` runs:

```powershell
.\Start-Diagnose.ps1 -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
```

## Recommended Operating Modes

### Dry Run

Use this to validate the pipeline without launching installers or external benchmark/support tools.

### Live Collection

Use this when approved tools are staged and you want the full cumulative report package.

### Support Tool Collection

The current build can integrate:

- CrystalDiskInfo
- Autoruns
- Process Explorer
- Process Monitor

Useful but currently not forced into blind automation:

- HWiNFO
- HWMonitor

### Benchmarks

The current build supports triage collection and comparison for:

- WinSAT
- PCMark 10 imports
- Unigine Heaven imports

## Output Structure

- `<output-root>/Reports/<run-id>/Abschlussbericht.html`
- `<output-root>/Reports/<run-id>/Rohbewertung.html`
- `<output-root>/Reports/<run-id>/Records.csv`
- `<output-root>/Reports/<run-id>/Run.zip`
- `<output-root>/Raw/<run-id>/diagnostic-records.jsonl`
- `<output-root>/Logs/<run-id>/`

## Operator Notes

- Review `Abschlussbericht.html` first for quick triage.
- Use `Rohbewertung.html` for detailed technical review.
- Use `Records.csv` for filtering, pivots, and multi-run comparison.
- Keep raw logs private because they may contain system names, users, paths, and event data.

## Recommended Customer Flow

1. Copy the prepared customer toolkit folder to the target PC.
2. Confirm that approved tools are present in `ToolkitPrograms\AutoInstall\`.
3. Start `Performance Test.cmd`.
4. Confirm the Windows elevation prompt.
5. Wait for report generation.
6. Open `Abschlussbericht.html`.
7. Use `Rohbewertung.html` and `Records.csv` for technical deep dive.
