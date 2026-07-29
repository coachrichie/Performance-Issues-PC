# PC Performance Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portable Windows 10/11 x64 PowerShell diagnostic kit that installs only the approved tools, collects performance evidence, runs bounded CPU/GPU tests, and emits HTML, CSV, and ZIP results.

**Architecture:** `Start-Diagnose.ps1` orchestrates focused PowerShell modules through a shared run context and normalized record schema. A JSON configuration and tool manifest control allowlisted installers, thresholds, output paths, and dry-run behavior. Reports are generated from collected records and preserved together with original logs.

**Tech Stack:** Windows PowerShell 5.1-compatible PowerShell, CMD launcher, JSON, CSV, HTML, built-in Windows CIM/Event Log/Performance Counter APIs, Pester tests where available.

## Global Constraints

- Target Windows 10/11 x64.
- Never store or request an administrator password.
- Never perform cleanup, uninstall, registry tuning, driver changes, or network configuration changes.
- Never auto-capture Wireshark packets.
- Only installers in the explicit allowlist may be started.
- Default stress duration is 10 minutes per test; warning is 85 °C and abort is 95 °C.
- Missing sensors must be represented as unavailable, never as zero.
- Module failures are logged and do not silently disappear.
- All installer and stress-test operations support dry-run mode.

---

### Task 1: Create the project skeleton and safe configuration

**Files:**
- Create: `Start-Diagnose.cmd`
- Create: `Start-Diagnose.ps1`
- Create: `Config/diagnostics.json`
- Create: `Config/tools.json`
- Create: `Scripts/Common.ps1`
- Create: `README.md`
- Test: `Tests/Configuration.Tests.ps1`

**Interfaces:**
- `Start-Diagnose.ps1` accepts `[switch]$InstallTools`, `[switch]$RunStressTests`, `[switch]$DryRun`, and `[string]$OutputRoot`.
- `Common.ps1` exports `New-RunContext`, `Write-DiagnosticRecord`, `Test-SafeChildPath`, and `Get-ConfiguredThresholds`.
- `tools.json` contains each tool's source filename, purpose, install arguments, executable hints, and `AutoInstall` boolean.

- [ ] **Step 1: Write failing configuration tests**

```powershell
Describe 'diagnostic configuration' {
    It 'loads 10 minute stress defaults and safe thresholds' {
        $config = Get-Content "$PSScriptRoot/../Config/diagnostics.json" -Raw | ConvertFrom-Json
        $config.Stress.CpuDurationSeconds | Should -Be 600
        $config.Stress.GpuDurationSeconds | Should -Be 600
        $config.Stress.AbortTemperatureC | Should -Be 95
    }

    It 'does not allow packet capture as an automatic action' {
        $config = Get-Content "$PSScriptRoot/../Config/diagnostics.json" -Raw | ConvertFrom-Json
        $config.Network.AutoPacketCapture | Should -BeFalse
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail because files do not exist**

Run: `Invoke-Pester -Path Tests/Configuration.Tests.ps1 -Output Detailed`

Expected: FAIL because the configuration files have not been created.

- [ ] **Step 3: Add the skeleton, launcher, configuration, and common helpers**

`Start-Diagnose.cmd` must call `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Diagnose.ps1" %*` and preserve the exit code. `New-RunContext` must create a timestamped run directory under `Reports`, `Logs`, and `Raw`, while `Test-SafeChildPath` must reject paths escaping the project root.

- [ ] **Step 4: Run the focused tests and confirm they pass**

Run: `Invoke-Pester -Path Tests/Configuration.Tests.ps1 -Output Detailed`

Expected: PASS with no failed tests.

- [ ] **Step 5: Commit**

```text
git add Start-Diagnose.cmd Start-Diagnose.ps1 Config Scripts Tests README.md
git commit -m "feat: scaffold diagnostic kit"
```

### Task 2: Add manifest-based installer handling

**Files:**
- Modify: `Scripts/Common.ps1`
- Create: `Scripts/Install-Tools.ps1`
- Modify: `Config/tools.json`
- Test: `Tests/Installer.Tests.ps1`

**Interfaces:**
- `Get-AllowlistedTools` returns only entries with `AutoInstall: true`.
- `Install-AllowlistedTools -ManifestPath -RunContext -DryRun` returns one normalized record per installer attempt.
- Unknown filenames, missing files, and unrecognized silent switches produce `Warning`/`Error` records without execution.

- [ ] **Step 1: Write failing tests for allowlisting, dry-run, and missing files**

```powershell
Describe 'allowlisted installer execution' {
    It 'excludes CHIP installers and PC-Putzer' {
        $tools = Get-AllowlistedTools -ManifestPath "$PSScriptRoot/../Config/tools.json"
        ($tools.Name -join ',') | Should -Not -Match 'CHIP|PC-Putzer'
    }

    It 'does not start a process in dry-run mode' {
        $result = Install-AllowlistedTools -ManifestPath "$PSScriptRoot/fixtures/tools.json" -RunContext $script:Context -DryRun
        $result | Where-Object Name -eq 'TestTool' | Select-Object -ExpandProperty Status | Should -Be 'DryRun'
    }
}
```

- [ ] **Step 2: Run the tests and verify the expected missing-function failures**

Run: `Invoke-Pester -Path Tests/Installer.Tests.ps1 -Output Detailed`

Expected: FAIL because installer functions do not yet exist.

- [ ] **Step 3: Implement manifest validation and process execution**

Use `Start-Process -Wait -PassThru` only after path validation and allowlist matching. Pass each manifest's fixed argument array; never concatenate user-provided command text. Capture start time, end time, exit code, installation path, and exception text. Default all uncertain third-party installers to `AutoInstall: false` until their switches are verified.

- [ ] **Step 4: Run installer tests in dry-run mode**

Run: `Invoke-Pester -Path Tests/Installer.Tests.ps1 -Output Detailed`

Expected: PASS without launching an installer.

- [ ] **Step 5: Commit**

```text
git add Scripts/Install-Tools.ps1 Scripts/Common.ps1 Config/tools.json Tests/Installer.Tests.ps1
git commit -m "feat: add safe allowlisted installer runner"
```

### Task 3: Implement Windows, storage, and network collection

**Files:**
- Create: `Scripts/Collect-Windows.ps1`
- Create: `Scripts/Collect-Storage.ps1`
- Create: `Scripts/Collect-Network.ps1`
- Test: `Tests/Collectors.Tests.ps1`

**Interfaces:**
- Each collector accepts `-RunContext` and `-DryRun` and returns normalized records.
- `Collect-Windows` uses CIM, `Get-Process`, services, scheduled/autostart sources, pagefile, power plan, and selected System/Application event logs.
- `Collect-Storage` uses `Get-Volume`, `Get-Disk`, `Get-PhysicalDisk`, and safe read-only health queries.
- `Collect-Network` uses adapters, IP/DNS/gateway data, and bounded connectivity checks only.

- [ ] **Step 1: Write failing tests for normalized records and unavailable values**

```powershell
Describe 'collector record contract' {
    It 'represents missing sensor data as unavailable' {
        $record = New-DiagnosticRecord -Category 'Sensor' -Name 'CpuTemperature' -Value $null -Source 'test'
        $record.Value | Should -Be 'Unavailable'
        $record.Severity | Should -Be 'Warning'
    }
}
```

- [ ] **Step 2: Run the tests and verify they fail for the missing helper**

Run: `Invoke-Pester -Path Tests/Collectors.Tests.ps1 -Output Detailed`

Expected: FAIL because `New-DiagnosticRecord` is not implemented.

- [ ] **Step 3: Implement collectors with bounded queries and explicit error records**

Wrap each OS query in a narrow `try/catch`, emit source and command names, cap event-log and process result counts, and write raw command output to the run's `Raw` directory. Do not use `netsh trace`, packet capture, or any write operation against system configuration.

- [ ] **Step 4: Run collector tests and a non-mutating dry run**

Run: `Invoke-Pester -Path Tests/Collectors.Tests.ps1 -Output Detailed`; then `.Start-Diagnose.ps1 -DryRun -OutputRoot .\Reports\TestRun`.

Expected: PASS; dry run creates only project-local output files and no installer process.

- [ ] **Step 5: Commit**

```text
git add Scripts/Collect-Windows.ps1 Scripts/Collect-Storage.ps1 Scripts/Collect-Network.ps1 Tests/Collectors.Tests.ps1
git commit -m "feat: collect Windows storage and network diagnostics"
```

### Task 4: Add sensor sampling and bounded stress tests

**Files:**
- Create: `Scripts/Collect-Sensors.ps1`
- Create: `Scripts/Run-StressTests.ps1`
- Modify: `Config/diagnostics.json`
- Test: `Tests/Stress.Tests.ps1`

**Interfaces:**
- `Get-SensorSnapshot -RunContext` returns CPU/GPU load, temperature, clock, and availability records.
- `Invoke-BoundedStressTest -Kind Cpu|Gpu -DurationSeconds -WarningTemperatureC -AbortTemperatureC -RunContext -DryRun` returns start/end/abort records and never exceeds the configured duration.

- [ ] **Step 1: Write failing tests for threshold decisions and dry-run behavior**

```powershell
Describe 'stress-test safety decisions' {
    It 'aborts when a sampled temperature reaches the abort threshold' {
        (Get-StressDecision -TemperatureC 95 -WarningTemperatureC 85 -AbortTemperatureC 95).Action | Should -Be 'Abort'
    }

    It 'does not start stress software in dry-run mode' {
        (Invoke-BoundedStressTest -Kind Cpu -DurationSeconds 600 -RunContext $script:Context -DryRun).Status | Should -Be 'DryRun'
    }
}
```

- [ ] **Step 2: Run tests and confirm expected failures**

Run: `Invoke-Pester -Path Tests/Stress.Tests.ps1 -Output Detailed`

Expected: FAIL because the decision and stress functions do not exist.

- [ ] **Step 3: Implement sensor probing and safety controller**

Prefer installed tool output only when its format is known; otherwise use Windows-provided readings and record unavailable sensors. Start Prime95 or Unigine Heaven only from validated executable paths, poll sensors every five seconds, stop at duration/abort/user cancellation, and always attempt process termination in a `finally` block.

- [ ] **Step 4: Run tests and dry-run stress path**

Run: `Invoke-Pester -Path Tests/Stress.Tests.ps1 -Output Detailed`; then `.Start-Diagnose.ps1 -DryRun -RunStressTests`.

Expected: PASS; no stress executable is launched.

- [ ] **Step 5: Commit**

```text
git add Scripts/Collect-Sensors.ps1 Scripts/Run-StressTests.ps1 Config/diagnostics.json Tests/Stress.Tests.ps1
git commit -m "feat: add monitored bounded stress tests"
```

### Task 5: Generate HTML, CSV, ZIP, and complete orchestration

**Files:**
- Create: `Scripts/Build-Report.ps1`
- Modify: `Start-Diagnose.ps1`
- Modify: `README.md`
- Test: `Tests/Reporting.Tests.ps1`

**Interfaces:**
- `Build-DiagnosticReport -RunContext -Records` writes `Report.html`, `Records.csv`, `ToolInventory.csv`, and `Run.zip`.
- The report includes summary severity, unavailable-data count, thermal events, top resource consumers, event-log highlights, tool results, privacy notice, and source paths.
- `Start-Diagnose.ps1` invokes modules in order, catches module errors, and exits nonzero only when orchestration itself cannot create or finalize a run.

- [ ] **Step 1: Write failing report tests**

```powershell
Describe 'diagnostic reporting' {
    It 'writes all three requested output formats' {
        Build-DiagnosticReport -RunContext $script:Context -Records @(
            (New-DiagnosticRecord -Category 'Test' -Name 'Example' -Value 'OK' -Source 'test')
        )
        Test-Path "$($script:Context.ReportPath)/Report.html" | Should -BeTrue
        Test-Path "$($script:Context.ReportPath)/Records.csv" | Should -BeTrue
        Test-Path "$($script:Context.ReportPath)/Run.zip" | Should -BeTrue
    }
}
```

- [ ] **Step 2: Run tests and verify the expected missing-function failure**

Run: `Invoke-Pester -Path Tests/Reporting.Tests.ps1 -Output Detailed`

Expected: FAIL because report generation is not implemented.

- [ ] **Step 3: Implement deterministic report generation and orchestration**

HTML must HTML-encode all collected text, use a stable section order, and show timestamps in local time plus ISO 8601. CSV uses UTF-8 with a header. ZIP creation must include raw logs, normalized records, tool inventory, configuration copy, and report. The orchestrator must print the final paths and return the report status.

- [ ] **Step 4: Run the full test suite and dry-run end to end**

Run: `Invoke-Pester -Path Tests -Output Detailed`; then `.Start-Diagnose.ps1 -DryRun -OutputRoot .\Reports\EndToEnd`.

Expected: all tests PASS; the dry run creates HTML, CSV, and ZIP without launching installers, stress tools, or packet capture.

- [ ] **Step 5: Commit**

```text
git add Start-Diagnose.ps1 Scripts/Build-Report.ps1 README.md Tests/Reporting.Tests.ps1
git commit -m "feat: orchestrate diagnostics and package reports"
```

### Task 6: Copy the user's tools and perform final verification

**Files:**
- Create: `Installers/` populated only from the approved source paths.
- Modify: `Config/tools.json` with actual copied filenames and verified hashes.
- Modify: `README.md` with the final tool inventory.

- [ ] **Step 1: Resolve and hash each source file without executing it**

Use `Get-FileHash -Algorithm SHA256` on the user-provided tool paths. Copy only the allowlisted files into `Installers/`; do not copy PC-Putzer, Revo, or CHIP installers.

- [ ] **Step 2: Verify manifest paths remain inside the project root**

Run the path-validation test and inspect the manifest for exactly the copied filenames, source notes, and `AutoInstall` values.

- [ ] **Step 3: Run final verification**

Run: `Invoke-Pester -Path Tests -Output Detailed`; then `.Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests`.

Expected: all tests PASS; every tool action is reported as `DryRun`, no installer or stress-test process starts, no packet capture occurs, and all requested report formats are produced.

- [ ] **Step 4: Commit**

```text
git add Installers Config/tools.json README.md
git commit -m "chore: add approved diagnostic tools"
```

