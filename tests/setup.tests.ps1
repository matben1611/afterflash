param()

# Test that script is syntactically valid
Describe "setup.ps1 Validation" {
    
    It "Script exists" {
        Test-Path -Path "$PSScriptRoot/../scripts/setup.ps1" | Should Be $true
    }

    It "Script has valid PowerShell syntax" {
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content -Path "$PSScriptRoot/../scripts/setup.ps1" -Raw),
            [ref]$errors
        )
        $errors.Count | Should Be 0
    }

    It "Script can be parsed without execution" {
        { 
            [void]([System.Management.Automation.PSParser]::Tokenize(
                (Get-Content -Path "$PSScriptRoot/../scripts/setup.ps1" -Raw),
                [ref]@()
            ))
        } | Should Not Throw
    }
}

Describe "Script Structure" {
    
    BeforeAll {
        $scriptContent = Get-Content -Path "$PSScriptRoot/../scripts/setup.ps1" -Raw
    }

    It "Contains function Test-IsAdmin" {
        $scriptContent | Should Match 'function\s+Test-IsAdmin'
    }

    It "Contains function Wait-A-Bit" {
        $scriptContent | Should Match 'function\s+Wait-A-Bit'
    }

    It "Contains function Read-YesNo" {
        $scriptContent | Should Match 'function\s+Read-YesNo'
    }

    It "Contains function Write-Info" {
        $scriptContent | Should Match 'function\s+Write-Info'
    }

    It "Contains function Write-Ok" {
        $scriptContent | Should Match 'function\s+Write-Ok'
    }

    It "Contains function Set-DwordValue" {
        $scriptContent | Should Match 'function\s+Set-DwordValue'
    }

    It "Contains function Set-StringValue" {
        $scriptContent | Should Match 'function\s+Set-StringValue'
    }

    It "Contains Set-BiosRecommendationsFileIfWanted function" {
        $scriptContent | Should Match 'function\s+Set-BiosRecommendationsFileIfWanted'
    }

    It "Contains Set-OptionalDiagnosticDataOff function" {
        $scriptContent | Should Match 'function\s+Set-OptionalDiagnosticDataOff'
    }

    It "Contains Set-DeliveryOptimizationHttpOnly function" {
        $scriptContent | Should Match 'function\s+Set-DeliveryOptimizationHttpOnly'
    }

    It "Contains Set-HardwareAcceleratedGpuSchedulingOn function" {
        $scriptContent | Should Match 'function\s+Set-HardwareAcceleratedGpuSchedulingOn'
    }

    It "Contains Set-VariableRefreshRateOff function" {
        $scriptContent | Should Match 'function\s+Set-VariableRefreshRateOff'
    }

    It "Contains Set-GameModeOff function" {
        $scriptContent | Should Match 'function\s+Set-GameModeOff'
    }

    It "Contains Set-MouseAccelerationOff function" {
        $scriptContent | Should Match 'function\s+Set-MouseAccelerationOff'
    }

    It "Contains Show-SystemInformation function" {
        $scriptContent | Should Match 'function\s+Show-SystemInformation'
    }

    It "Uses Read-YesNo for user confirmations" {
        $scriptContent | Should Match 'Read-YesNo'
    }

    It "Has proper error handling" {
        $scriptContent | Should Match 'catch\s*{'
    }

    It "Uses Write-Verbose for debugging" {
        $scriptContent | Should Match 'Write-Verbose'
    }
}
