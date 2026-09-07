# Distribution

## Purpose

This project supports two handoff targets:

- a customer-ready toolkit folder for live IT support use
- a GitHub-ready repository export without customer-specific runtime output

## Build Both Distribution Folders

```powershell
.\Create-Distributions.ps1
```

This creates:

- `Distributions\Customer Toolkit\`
- `Distributions\GitHub Repository\`

## Distribution Philosophy

The two output folders have different goals:

- Customer Toolkit: execute diagnostics on a target PC
- GitHub Repository: maintain and publish the project safely

## Customer Toolkit Contents

The customer toolkit contains the files needed to copy the package to a target PC and start:

```powershell
.\Performance Test.cmd
```

Included:

- launchers
- scripts
- config
- documentation
- benchmark import folders
- toolkit program folders
- optional empty report structure
- customer start note

Not included automatically:

- historic runtime reports from your development machine

## GitHub Repository Contents

The GitHub export contains the project source, tests, documentation, and community files.

Intended use:

- publish project source
- share automation logic
- version documentation and tests

Not intended:

- shipping customer logs
- shipping locally extracted tools
- shipping copied runtime report folders

## Recommended Operator Flow

1. Maintain and test in the main project folder.
2. Run `.\Create-Distributions.ps1`.
3. Copy `Distributions\Customer Toolkit\` to the customer PC.
4. Publish or archive `Distributions\GitHub Repository\` as needed.

## Customer Folder Preparation

Place approved support tools into:

- `ToolkitPrograms\AutoInstall\`
- `ToolkitPrograms\Optional\`

Recommended examples:

- CrystalDiskInfo ZIP
- Autoruns ZIP
- Process Explorer ZIP
- CPU-Z EXE
- TreeSize Free setup
- Wireshark setup

## Notes

- ZIP tools can be extracted automatically into `ToolkitPrograms\Installed\`.
- Reports are created only when the toolkit is executed on the target machine.
- Review generated reports before external sharing because they may contain sensitive host data.
- Re-run `Create-Distributions.ps1` after documentation or structural changes.
