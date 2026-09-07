# Benchmark Imports

Drop benchmark export files into these subfolders so the toolkit can pick them up automatically during a run.

## Expected folders

- `BenchmarkImports/PCMark10/`
- `BenchmarkImports/UnigineHeaven/`

## Supported input files

- `PCMark10`: XML export
- `Unigine Heaven`: CSV export

## Current behavior

- The newest matching file in each folder is used
- Missing files are reported as `NoResultYet`
- Blocked WinSAT access is reported separately as `CollectionBlocked`
