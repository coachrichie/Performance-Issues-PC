# Contributing

Thank you for improving this diagnostic toolkit.

## Goals

- Keep the toolkit portable
- Prefer read-only data collection
- Make every automated action explicit and reviewable
- Keep report output reproducible

## Development Workflow

1. Create a branch for your change.
2. Keep changes scoped to one concern where possible.
3. Add or update tests when behavior changes.
4. Run the local verification steps before opening a pull request.

## Local Verification

```powershell
Invoke-Pester -Script .\Tests -PassThru
.\Start-Diagnose.ps1 -DryRun -OutputRoot .\Reports\ContributorDryRun
```

## Safety Rules

- Do not add automatic cleanup or registry tuning.
- Do not store credentials or automate admin password entry.
- Do not enable packet capture by default.
- Do not auto-run CHIP wrappers or similar third-party downloader installers.
- Keep stress tests bounded and abortable.

## Pull Requests

- Explain the user-visible reason for the change.
- Note any new tools, binaries, or external dependencies.
- Include verification evidence.
