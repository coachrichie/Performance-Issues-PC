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
        ($script.Parameters.Keys -join ',') | Should Match 'DryRun'
        ($script.Parameters.Keys -join ',') | Should Match 'OutputRoot'
    }
}
