param()

BeforeAll {
    $script:scriptsDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts'
    $script:modulesDir = Join-Path $script:scriptsDir 'modules'
}

Describe "setup.ps1 Validation" {

    It "Script exists" {
        Test-Path (Join-Path $script:scriptsDir 'setup.ps1') | Should -Be $true
    }

    It "Script has valid PowerShell syntax" {
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content (Join-Path $script:scriptsDir 'setup.ps1') -Raw),
            [ref]$errors
        )
        $errors.Count | Should -Be 0
    }

    It "Script can be parsed without execution" {
        {
            [void]([System.Management.Automation.PSParser]::Tokenize(
                (Get-Content (Join-Path $script:scriptsDir 'setup.ps1') -Raw),
                [ref]@()
            ))
        } | Should -Not -Throw
    }
}

Describe "Module Syntax Validation" {

    It "modules\helpers.ps1 has valid PowerShell syntax" {
        $path = Join-Path $script:modulesDir 'helpers.ps1'
        Test-Path $path | Should -Be $true
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "modules\system.ps1 has valid PowerShell syntax" {
        $path = Join-Path $script:modulesDir 'system.ps1'
        Test-Path $path | Should -Be $true
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "modules\tweaks.ps1 has valid PowerShell syntax" {
        $path = Join-Path $script:modulesDir 'tweaks.ps1'
        Test-Path $path | Should -Be $true
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "modules\apps.ps1 has valid PowerShell syntax" {
        $path = Join-Path $script:modulesDir 'apps.ps1'
        Test-Path $path | Should -Be $true
        $errors = @()
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$errors)
        $errors.Count | Should -Be 0
    }
}

Describe "Script Structure" {

    BeforeAll {
        $script:allContent = (Get-ChildItem -Path $script:modulesDir -Filter '*.ps1') |
            ForEach-Object { Get-Content $_.FullName -Raw } |
            Out-String
    }

    # --- Helpers ---
    It "Contains function Test-IsAdmin" {
        $script:allContent | Should -Match 'function\s+Test-IsAdmin'
    }

    It "Contains function Wait-A-Bit" {
        $script:allContent | Should -Match 'function\s+Wait-A-Bit'
    }

    It "Contains function Read-YesNo" {
        $script:allContent | Should -Match 'function\s+Read-YesNo'
    }

    It "Contains function Write-Info" {
        $script:allContent | Should -Match 'function\s+Write-Info'
    }

    It "Contains function Write-Ok" {
        $script:allContent | Should -Match 'function\s+Write-Ok'
    }

    It "Contains function Write-WarnMsg" {
        $script:allContent | Should -Match 'function\s+Write-WarnMsg'
    }

    It "Contains function Set-DwordValue" {
        $script:allContent | Should -Match 'function\s+Set-DwordValue'
    }

    It "Contains function Set-StringValue" {
        $script:allContent | Should -Match 'function\s+Set-StringValue'
    }

    It "Contains function Test-RegistryKey" {
        $script:allContent | Should -Match 'function\s+Test-RegistryKey'
    }

    # --- System ---
    It "Contains function Show-SystemInformation" {
        $script:allContent | Should -Match 'function\s+Show-SystemInformation'
    }

    # --- Performance tweaks ---
    It "Contains function Set-HardwareAcceleratedGpuSchedulingOn" {
        $script:allContent | Should -Match 'function\s+Set-HardwareAcceleratedGpuSchedulingOn'
    }

    It "Contains function Set-VariableRefreshRateOn" {
        $script:allContent | Should -Match 'function\s+Set-VariableRefreshRateOn'
    }

    It "Contains function Set-GameModeOff" {
        $script:allContent | Should -Match 'function\s+Set-GameModeOff'
    }

    It "Contains function Set-XboxGameBarOff" {
        $script:allContent | Should -Match 'function\s+Set-XboxGameBarOff'
    }

    It "Contains function Set-FullscreenOptimizationsOff" {
        $script:allContent | Should -Match 'function\s+Set-FullscreenOptimizationsOff'
    }

    It "Contains function Set-TimerResolution" {
        $script:allContent | Should -Match 'function\s+Set-TimerResolution'
    }

    It "Contains function Set-MsiModeForGpu" {
        $script:allContent | Should -Match 'function\s+Set-MsiModeForGpu'
    }

    It "Contains function Set-MouseAccelerationOff" {
        $script:allContent | Should -Match 'function\s+Set-MouseAccelerationOff'
    }

    It "Contains function Set-PowerPlan" {
        $script:allContent | Should -Match 'function\s+Set-PowerPlan'
    }

    # --- Privacy tweaks ---
    It "Contains function Set-OptionalDiagnosticDataOff" {
        $script:allContent | Should -Match 'function\s+Set-OptionalDiagnosticDataOff'
    }

    It "Contains function Set-DeliveryOptimizationHttpOnly" {
        $script:allContent | Should -Match 'function\s+Set-DeliveryOptimizationHttpOnly'
    }

    # --- Network tweaks ---
    It "Contains function Set-DnsServers" {
        $script:allContent | Should -Match 'function\s+Set-DnsServers'
    }

    It "Contains function Set-NicPowerSavingOff" {
        $script:allContent | Should -Match 'function\s+Set-NicPowerSavingOff'
    }

    # --- UI tweaks ---
    It "Contains function Set-FileExtensionsVisible" {
        $script:allContent | Should -Match 'function\s+Set-FileExtensionsVisible'
    }

    It "Contains function Set-HiddenFilesVisible" {
        $script:allContent | Should -Match 'function\s+Set-HiddenFilesVisible'
    }

    It "Contains function Set-DarkModeOn" {
        $script:allContent | Should -Match 'function\s+Set-DarkModeOn'
    }

    # --- Optional tweaks ---
    It "Contains function Set-SystemProtectionIfWanted" {
        $script:allContent | Should -Match 'function\s+Set-SystemProtectionIfWanted'
    }

    It "Contains function Set-ClipboardHistoryIfWanted" {
        $script:allContent | Should -Match 'function\s+Set-ClipboardHistoryIfWanted'
    }

    It "Contains function Test-DoNotDisturbIfWanted" {
        $script:allContent | Should -Match 'function\s+Test-DoNotDisturbIfWanted'
    }

    # --- Apps ---
    It "Contains function Open-NiniteIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-NiniteIfWanted'
    }

    It "Contains function Open-GpuDriverPageIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-GpuDriverPageIfWanted'
    }

    It "Contains function Open-ChipsetsDriverPageIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-ChipsetsDriverPageIfWanted'
    }

    It "Contains function Open-DduPageIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-DduPageIfWanted'
    }

    It "Contains function Open-MonitoringToolsIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-MonitoringToolsIfWanted'
    }

    It "Contains function Open-CrystalDiskMarkIfWanted" {
        $script:allContent | Should -Match 'function\s+Open-CrystalDiskMarkIfWanted'
    }

    It "Contains function Start-WindowsUpdateIfWanted" {
        $script:allContent | Should -Match 'function\s+Start-WindowsUpdateIfWanted'
    }

    It "Contains function Start-DebloaterIfWanted" {
        $script:allContent | Should -Match 'function\s+Start-DebloaterIfWanted'
    }

    # --- General patterns ---
    It "Uses Read-YesNo for user confirmations" {
        $script:allContent | Should -Match 'Read-YesNo'
    }

    It "Uses Write-Verbose for debugging" {
        $script:allContent | Should -Match 'Write-Verbose'
    }
}

Describe "setup.ps1 Orchestration" {

    BeforeAll {
        $script:setupContent = Get-Content (Join-Path $script:scriptsDir 'setup.ps1') -Raw
    }

    It "Dot-sources all modules" {
        $script:setupContent | Should -Match '\.\s+".*helpers\.ps1"'
        $script:setupContent | Should -Match '\.\s+".*system\.ps1"'
        $script:setupContent | Should -Match '\.\s+".*tweaks\.ps1"'
        $script:setupContent | Should -Match '\.\s+".*apps\.ps1"'
    }

    It "Has proper error handling" {
        $script:setupContent | Should -Match 'catch\s*{'
    }

    It "Defines quickSetup flag" {
        $script:setupContent | Should -Match '\$script:quickSetup'
    }

    It "Defines report collection" {
        $script:setupContent | Should -Match '\$script:report'
    }

    It "Defines currentStepApplied flag" {
        $script:setupContent | Should -Match '\$script:currentStepApplied'
    }

    It "Contains Show-Report call" {
        $script:setupContent | Should -Match 'Show-Report'
    }

    It "Contains Invoke-Step function" {
        $script:setupContent | Should -Match 'function\s+Invoke-Step'
    }

    It "Contains Checkpoint-Computer for restore point" {
        $script:setupContent | Should -Match 'Checkpoint-Computer'
    }

    It "Invokes all expected steps" {
        $script:setupContent | Should -Match "Invoke-Step 'GPU Scheduling'"
        $script:setupContent | Should -Match "Invoke-Step 'Variable Refresh Rate'"
        $script:setupContent | Should -Match "Invoke-Step 'Game Mode'"
        $script:setupContent | Should -Match "Invoke-Step 'Xbox Game Bar'"
        $script:setupContent | Should -Match "Invoke-Step 'Fullscreen Optimizations'"
        $script:setupContent | Should -Match "Invoke-Step 'Timer Resolution'"
        $script:setupContent | Should -Match "Invoke-Step 'MSI Mode'"
        $script:setupContent | Should -Match "Invoke-Step 'Power Plan'"
        $script:setupContent | Should -Match "Invoke-Step 'Mouse Acceleration'"
        $script:setupContent | Should -Match "Invoke-Step 'DNS'"
        $script:setupContent | Should -Match "Invoke-Step 'NIC Power Saving'"
        $script:setupContent | Should -Match "Invoke-Step 'File Extensions'"
        $script:setupContent | Should -Match "Invoke-Step 'Hidden Files'"
        $script:setupContent | Should -Match "Invoke-Step 'Dark Mode'"
        $script:setupContent | Should -Match "Invoke-Step 'Diagnostic Data'"
        $script:setupContent | Should -Match "Invoke-Step 'Delivery Optimization'"
        $script:setupContent | Should -Match "Invoke-Step 'Debloater'"
    }
}

Describe "Write-Ok sets currentStepApplied" {

    BeforeAll {
        $script:helpersContent = Get-Content (Join-Path $script:modulesDir 'helpers.ps1') -Raw
    }

    It "Write-Ok sets \$script:currentStepApplied to true" {
        $script:helpersContent | Should -Match '\$script:currentStepApplied\s*=\s*\$true'
    }
}
