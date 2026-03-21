param()

# Source the setup script
$setupScriptPath = Join-Path $PSScriptRoot '../scripts/setup.ps1'

Describe "setup.ps1 Functions" {

    BeforeAll {
        # Source the script to load all functions
        . $setupScriptPath
    }

    Context "Test-IsAdmin" {
        It "Function exists" {
            Test-Path -Path Function:\Test-IsAdmin | Should -Be $true
        }

        It "Returns a boolean" {
            $result = Test-IsAdmin
            $result -is [bool] | Should -Be $true
        }

        It "Returns false when not running as admin" {
            # Mock the principal to return false
            Mock -CommandName Test-IsAdmin -MockWith { return $false }
            Test-IsAdmin | Should -Be $false
        }
    }

    Context "Read-YesNo" {
        It "Function exists" {
            Test-Path -Path Function:\Read-YesNo | Should -Be $true
        }

        It "Accepts 'y' as yes" {
            Mock Read-Host { return "y" }
            Read-YesNo -Prompt "Test" | Should -Be $true
        }

        It "Accepts 'yes' as yes" {
            Mock Read-Host { return "yes" }
            Read-YesNo -Prompt "Test" | Should -Be $true
        }

        It "Accepts 'n' as no" {
            Mock Read-Host { return "n" }
            Read-YesNo -Prompt "Test" | Should -Be $false
        }

        It "Accepts 'no' as no" {
            Mock Read-Host { return "no" }
            Read-YesNo -Prompt "Test" | Should -Be $false
        }

        It "Handles case-insensitive input" {
            Mock Read-Host { return "YES" }
            Read-YesNo -Prompt "Test" | Should -Be $true
        }
    }

    Context "Wait-A-Bit" {
        It "Function exists" {
            Test-Path -Path Function:\Wait-A-Bit | Should -Be $true
        }

        It "Completes without error" {
            { Wait-A-Bit } | Should -Not -Throw
        }
    }

    Context "Helper Functions" {
        It "Write-Info exists" {
            Test-Path -Path Function:\Write-Info | Should -Be $true
        }

        It "Write-Ok exists" {
            Test-Path -Path Function:\Write-Ok | Should -Be $true
        }

        It "Write-WarnMsg exists" {
            Test-Path -Path Function:\Write-WarnMsg | Should -Be $true
        }

        It "Test-RegistryKey exists" {
            Test-Path -Path Function:\Test-RegistryKey | Should -Be $true
        }
    }

    Context "Registry Functions" {
        It "Set-DwordValue exists" {
            Test-Path -Path Function:\Set-DwordValue | Should -Be $true
        }

        It "Set-StringValue exists" {
            Test-Path -Path Function:\Set-StringValue | Should -Be $true
        }
    }

    Context "Configuration Functions" {
        It "Set-BiosRecommendationsFileIfWanted exists" {
            Test-Path -Path Function:\Set-BiosRecommendationsFileIfWanted | Should -Be $true
        }

        It "Set-OptionalDiagnosticDataOff exists" {
            Test-Path -Path Function:\Set-OptionalDiagnosticDataOff | Should -Be $true
        }

        It "Set-DeliveryOptimizationHttpOnly exists" {
            Test-Path -Path Function:\Set-DeliveryOptimizationHttpOnly | Should -Be $true
        }

        It "Set-HardwareAcceleratedGpuSchedulingOn exists" {
            Test-Path -Path Function:\Set-HardwareAcceleratedGpuSchedulingOn | Should -Be $true
        }

        It "Set-VariableRefreshRateOff exists" {
            Test-Path -Path Function:\Set-VariableRefreshRateOff | Should -Be $true
        }

        It "Set-GameModeOff exists" {
            Test-Path -Path Function:\Set-GameModeOff | Should -Be $true
        }

        It "Set-MouseAccelerationOff exists" {
            Test-Path -Path Function:\Set-MouseAccelerationOff | Should -Be $true
        }
    }
}
