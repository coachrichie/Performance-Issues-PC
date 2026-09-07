# Diagnostics Scope

## What The Toolkit Collects

- CPU load and scheduler-related Windows data
- RAM usage and memory pressure indicators
- Disk capacity, disk activity, and filesystem utilization
- Network adapter and connectivity context
- Selected event and process information relevant to performance triage
- Sensor availability state for temperature-aware decisions
- Benchmark source states and imported benchmark results
- Support-tool logs from CrystalDiskInfo and Autoruns
- Manual deep-inspection launch points for Process Explorer and Process Monitor

## Performance Issues Covered

- High sustained CPU utilization
- Memory pressure and low available RAM
- Disk saturation and storage bottlenecks
- Oversized folders and storage growth patterns
- Basic network instability indicators
- Thermal-risk visibility when a supported sensor source is available
- Excessive autostart density
- Storage-health warnings from SMART-style exports

## Current Boundaries

- Temperature collection still depends on sensor availability and approved tooling
- Live GPU and CPU stress execution remains bounded and may be skipped when no validated sensor path is available
- Built-in Windows tools are collected through scripts; Task Manager itself is not silently automated, but equivalent performance data is gathered through Windows APIs and command-line sources
- PCMark 10 and Unigine Heaven are strongest when export files are available or automation-compatible installations are present

## Cumulative Reporting

The toolkit normalizes collected values into a shared record stream and then builds:

- `Abschlussbericht.html`
- `Rohbewertung.html`
- `Records.csv`
- `Run.zip`

Likely-cause detection currently includes:

- benchmark underperformance
- storage warnings
- suspicious drive-health results
- oversized autostart counts
- missing or blocked collection paths
- unusually heavy top processes

Current note:

- Autoruns can only be fully parsed automatically when a CLI exporter variant is available
- with the GUI variant, the toolkit launches the tool for manual startup review instead

## Reading The Results

- Start with `Abschlussbericht.html` for summary findings
- Use `Rohbewertung.html` to inspect all normalized records
- Use `Records.csv` to sort by severity, timestamp, or category
- Compare multiple runs when the issue is intermittent

## Suggested Next Extensions

- Add a validated temperature provider with richer machine-readable export
- Add optional ETW-based traces for advanced storage or boot analysis
- Add vendor-specific benchmark baselines for more precise hardware comparison

## Current Triage-Oriented Output Logic

The toolkit already tries to identify likely causes from combined evidence such as:

- benchmark deviations
- drive health signals
- excessive autostarts
- storage pressure
- blocked or missing collection channels

The resulting interpretation is intentionally support-oriented, not a promise of fully automated root-cause certainty.
