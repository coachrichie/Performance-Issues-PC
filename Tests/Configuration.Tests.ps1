Describe 'diagnostic configuration' {
    It 'loads 10 minute stress defaults and safe thresholds' {
        $config = Get-Content "$PSScriptRoot/../Config/diagnostics.json" -Raw | ConvertFrom-Json
        $config.Stress.CpuDurationSeconds | Should Be 600
        $config.Stress.GpuDurationSeconds | Should Be 600
        $config.Stress.AbortTemperatureC | Should Be 95
    }

    It 'does not allow packet capture as an automatic action' {
        $config = Get-Content "$PSScriptRoot/../Config/diagnostics.json" -Raw | ConvertFrom-Json
        $config.Network.AutoPacketCapture | Should Be $false
    }
}
