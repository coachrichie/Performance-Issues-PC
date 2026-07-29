# Installer Payloads

This folder is intentionally kept in the repository without committing the actual binary payloads.

## Why

Installer executables and ZIP archives are usually large, change frequently, and may carry separate license terms. They should be copied locally by the operator after review.

## Expected Files

The filenames expected by the current tool manifest are documented in `Config/tools.json`.

## Excluded From Automation

The following categories should remain excluded from automatic execution:

- Cleanup and registry-fix tools
- Downloader wrappers
- CHIP installers or similar repackaged delivery tools
- Packet capture automation
