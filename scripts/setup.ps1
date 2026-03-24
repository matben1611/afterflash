[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulesDir = Join-Path $PSScriptRoot 'modules'
. "$modulesDir\helpers.ps1"
. "$modulesDir\system.ps1"
. "$modulesDir\tweaks.ps1"
. "$modulesDir\apps.ps1"

$script:quickSetup  = $false
$script:currentStep = 0
$script:totalSteps  = 28

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Body,
        [switch]$SkipInQuickSetup
    )
    $script:currentStep++

    if ($script:quickSetup) {
        if (-not $SkipInQuickSetup) {
            try { & $Body } catch { Write-Verbose "Step '$Label' failed: $_" }
        }
        return
    }

    Write-Host "  [$script:currentStep/$script:totalSteps] $Label" -ForegroundColor Cyan
    & $Body
    Wait-A-Bit
}

try {
    Restart-AsAdmin

    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
    Clear-Host

    Write-Host ""
    Write-Host "========================================"
    Write-Host "         Windows Setup Starting         "
    Write-Host "========================================"
    Write-Host ""

    Wait-A-Bit

    Write-Host ""
    Write-Typewriter "  Scanning system hardware..." -DelayMs 40
    Start-Sleep -Milliseconds 400

    Show-SystemInformation

    Wait-A-Bit

    Write-Host ""
    $script:quickSetup = Read-YesNo -Prompt "Do you want to use Quick Setup (applies all tweaks automatically)"
    Write-Host ""

    if ($script:quickSetup) {
        Write-Host "  Applying all tweaks..." -ForegroundColor Cyan
        Write-Host ""
    }

    Invoke-Step 'BIOS Recommendations'       { Set-BiosRecommendationsFileIfWanted }
    Invoke-Step 'App Installer (Ninite)'     { Open-NiniteIfWanted }          -SkipInQuickSetup
    Invoke-Step 'GPU Drivers'                { Open-GpuDriverPageIfWanted }   -SkipInQuickSetup
    Invoke-Step 'DDU'                        { Open-DduPageIfWanted }          -SkipInQuickSetup
    Invoke-Step 'Chipset Drivers'            { Open-ChipsetsDriverPageIfWanted } -SkipInQuickSetup
    Invoke-Step 'Monitoring Tools'           { Open-MonitoringToolsIfWanted }  -SkipInQuickSetup
    Invoke-Step 'CrystalDiskMark'            { Open-CrystalDiskMarkIfWanted }  -SkipInQuickSetup
    Invoke-Step 'GPU Scheduling'             { Set-HardwareAcceleratedGpuSchedulingOn }
    Invoke-Step 'Variable Refresh Rate'      { Set-VariableRefreshRateOn }
    Invoke-Step 'Game Mode'                  { Set-GameModeOff }
    Invoke-Step 'Xbox Game Bar'              { Set-XboxGameBarOff }
    Invoke-Step 'Fullscreen Optimizations'   { Set-FullscreenOptimizationsOff }
    Invoke-Step 'Timer Resolution'           { Set-TimerResolution }
    Invoke-Step 'MSI Mode'                   { Set-MsiModeForGpu }
    Invoke-Step 'Power Plan'                 { Set-PowerPlan }
    Invoke-Step 'Mouse Acceleration'         { Set-MouseAccelerationOff }
    Invoke-Step 'File Extensions'            { Set-FileExtensionsVisible }
    Invoke-Step 'Hidden Files'               { Set-HiddenFilesVisible }
    Invoke-Step 'Dark Mode'                  { Set-DarkModeOn }
    Invoke-Step 'Diagnostic Data'            { Set-OptionalDiagnosticDataOff }
    Invoke-Step 'Delivery Optimization'      { Set-DeliveryOptimizationHttpOnly }
    Invoke-Step 'DNS'                        { Set-DnsServers } -SkipInQuickSetup
    Invoke-Step 'NIC Power Saving'           { Set-NicPowerSavingOff }
    Invoke-Step 'System Protection'          { Set-SystemProtectionIfWanted } -SkipInQuickSetup
    Invoke-Step 'Clipboard History'          { Set-ClipboardHistoryIfWanted } -SkipInQuickSetup
    Invoke-Step 'Do Not Disturb'             { Test-DoNotDisturbIfWanted }    -SkipInQuickSetup
    Invoke-Step 'Windows Update'             { Start-WindowsUpdateIfWanted } -SkipInQuickSetup
    Invoke-Step 'Debloater'                  { Start-DebloaterIfWanted }

    Write-Host ""
    Write-Host "========================================"
    Write-Host "               Finished                 "
    Write-Host "========================================"
    Write-Host ""
}
catch {
    Write-Error $_
}
finally {
    Read-Host "`nPress Enter to exit..."
}
