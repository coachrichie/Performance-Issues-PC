Describe 'diagnostic launchers' {
    It 'preserves the exit code and uses execution policy bypass' {
        $launcher = Get-Content "$PSScriptRoot/../Start-Diagnose.cmd" -Raw
        $launcher | Should Match 'powershell\.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Diagnose\.ps1" %\*'
        $launcher | Should Match 'exit /b %errorlevel%'
    }

    It 'accepts the expected startup parameters' {
        $script = Get-Command "$PSScriptRoot/../Start-Diagnose.ps1"
        ($script.Parameters.Keys -join ',') | Should Match 'InstallTools'
        ($script.Parameters.Keys -join ',') | Should Match 'RunStressTests'
        ($script.Parameters.Keys -join ',') | Should Match 'RunBenchmarks'
        ($script.Parameters.Keys -join ',') | Should Match 'RunSupportTools'
        ($script.Parameters.Keys -join ',') | Should Match 'DryRun'
        ($script.Parameters.Keys -join ',') | Should Match 'OutputRoot'
    }

    It 'provides a single support entrypoint that elevates and runs the full workflow' {
        $launcher = Get-Content "$PSScriptRoot/../Performance Test.cmd" -Raw
        $script = Get-Content "$PSScriptRoot/../Performance Test.ps1" -Raw

        $launcher | Should Match 'powershell\.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Performance Test\.ps1"'
        $script | Should Match 'Start-Process'
        $script | Should Match '-Verb RunAs'
        $script | Should Match 'Start-Diagnose\.ps1'
        $script | Should Match '-InstallTools'
        $script | Should Match '-RunStressTests'
        $script | Should Match '-RunBenchmarks'
        $script | Should Match '-RunSupportTools'
    }
}
