# Diagnostics Scope

## What The Toolkit Collects

- CPU load and scheduler-related Windows data
- RAM usage and memory pressure indicators
- Disk capacity, disk activity, and filesystem utilization
- Network adapter and connectivity context
- Selected event and process information relevant to performance triage
- Sensor availability state for temperature-aware decisions

## Performance Issues Covered

- High sustained CPU utilization
- Memory pressure and low available RAM
- Disk saturation and storage bottlenecks
- Oversized folders and storage growth patterns
- Basic network instability indicators
- Thermal-risk visibility when a supported sensor source is available

## Current Boundaries

- Temperature collection depends on sensor availability and approved tooling
- GPU and CPU stress execution is currently disabled in live mode and recorded as skipped until a validated temperature source is integrated
- Built-in Windows tools are collected through scripts; Task Manager itself is not silently manipulated, but equivalent performance data is gathered through Windows APIs and command-line sources

## Reading The Results

- Start with `Report.html` for summary findings
- Use `Records.csv` to sort by severity, timestamp, or category
- Compare multiple runs when the issue is intermittent

## Suggested Next Extensions

- Add a validated sensor provider with machine-readable export
- Add optional ETW-based traces for advanced storage or boot analysis
- Add optional SMART health parsing if approved in the environment
