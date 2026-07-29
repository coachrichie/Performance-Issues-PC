# Usage

## Entry Points

- `Start-Diagnose.cmd`
- `Start-Diagnose.ps1`

## Typical Commands

```powershell
.\Start-Diagnose.ps1 -DryRun
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests
.\Start-Diagnose.ps1 -OutputRoot .\Reports
```

## Recommended Operating Modes

### Dry Run

Use this when you want to validate the collection pipeline without launching installers or benchmark tools.

### Live Collection

Use this when the approved tools are already present and you want to gather a full report package.

### Guided Stress Testing

This switch is reserved for the future validated stress workflow. In the current build, real stress execution is skipped safely and logged as such.

## Output Structure

- `<output-root>/Reports/<run-id>/Report.html`
- `<output-root>/Reports/<run-id>/Records.csv`
- `<output-root>/Reports/<run-id>/Run.zip`
- `<output-root>/Raw/<run-id>/diagnostic-records.jsonl`
- `<output-root>/Logs/<run-id>/`

## Operator Notes

- Review the HTML report first for quick triage.
- Use `Records.csv` for filtering and pivot analysis.
- Keep raw logs private because they may contain system names, users, paths, and event data.
