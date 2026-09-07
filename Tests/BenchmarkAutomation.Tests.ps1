. "$PSScriptRoot/../Scripts/Common.ps1"
. "$PSScriptRoot/../Scripts/Run-Benchmarks.ps1"

Describe 'benchmark automation' {
    It 'builds a PCMark 10 command line plan when PCMark10Cmd.exe is available' {
        $importRoot = Join-Path $TestDrive 'pcmark-import'
        New-Item -ItemType Directory -Path $importRoot -Force | Out-Null
        $plan = New-PCMark10AutomationPlan -ExecutablePath 'C:\Bench\PCMark10Cmd.exe' -ImportRoot $importRoot

        $plan.ToolName | Should Be 'PCMark10'
        $plan.FilePath | Should Be 'C:\Bench\PCMark10Cmd.exe'
        ($plan.ArgumentList -join ' ') | Should Match '--definition=pcm10_benchmark\.pcmdef'
        ($plan.ArgumentList -join ' ') | Should Match '--out='
        ($plan.ArgumentList -join ' ') | Should Match '--export-xml'
        ($plan.ArgumentList -join ' ') | Should Match '--accepteula'
    }

    It 'marks PCMark 10 as unsupported when only the GUI executable is found' {
        $result = New-PCMark10AutomationPlan -ExecutablePath 'C:\Bench\pcmark10.exe' -ImportRoot (Join-Path $TestDrive 'pcmark-import')

        $result.Status | Should Be 'UnsupportedEdition'
    }

    It 'builds a Unigine Heaven automation plan when python and single_run.py are available' {
        $importRoot = Join-Path $TestDrive 'heaven-import'
        New-Item -ItemType Directory -Path $importRoot -Force | Out-Null
        $plan = New-UnigineHeavenAutomationPlan -ExecutablePath 'C:\Bench\Heaven\Heaven.exe' -PythonPath 'C:\Python\python.exe' -ImportRoot $importRoot

        $plan.ToolName | Should Be 'UnigineHeaven'
        $plan.FilePath | Should Be 'C:\Python\python.exe'
        ($plan.ArgumentList -join ' ') | Should Match 'single_run\.py'
    }

    It 'returns a dry-run execution record for a supported benchmark plan' {
        $context = New-RunContext -OutputRoot (Join-Path $TestDrive 'benchmark-run')
        $plan = [pscustomobject]@{
            ToolName = 'PCMark10'
            FilePath = 'C:\Bench\PCMark10Cmd.exe'
            ArgumentList = @('--help')
            WorkingDirectory = 'C:\Bench'
            ExpectedOutputPath = 'C:\Temp\result.xml'
            Status = 'Ready'
        }

        $records = Invoke-BenchmarkAutomationPlan -RunContext $context -Plan $plan -DryRun

        ($records | Where-Object Name -eq 'PCMark10').Value | Should Be 'DryRun'
    }
}
