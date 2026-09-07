# Security And Privacy

## Safety Model

This toolkit is intentionally conservative. It is designed for diagnostics, not repair automation.

## Explicit Non-Goals

- No password capture or password storage
- No registry cleaning
- No driver tuning
- No automatic uninstall or cleanup tools
- No automatic packet capture
- No silent bypass of Windows UAC

## Sensitive Data Handling

Collected artifacts may contain:

- Computer names
- User names
- Process names
- File paths
- Event log data
- Network configuration details

Review reports before sharing them publicly.

This also applies to:

- `Records.csv`
- `Rohbewertung.html`
- `Run.zip`
- imported benchmark exports

## Trusted Tooling

Only allowlisted tools should be added to the automation workflow. Third-party wrappers, downloader stubs, or ad-supported installers should stay excluded.

## Trusted Automation Scope

Approved automation is limited to:

- diagnostics collection
- bounded benchmark handling
- support-tool log collection
- report generation
- distribution-folder generation

## Reporting A Security Concern

If you discover a security issue in the scripts or packaged workflow, report it privately to the project maintainer before opening a public issue.
