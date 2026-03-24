[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulesDir = Join-Path $PSScriptRoot 'modules'
. "$modulesDir\helpers.ps1"
. "$modulesDir\system.ps1"
. "$modulesDir\tweaks.ps1"
. "$modulesDir\apps.ps1"

$script:currentStep = 0
$script:totalSteps  = 28

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Body
    )
    $script:currentStep++
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

    Invoke-Step 'BIOS Recommendations'       { Set-BiosRecommendationsFileIfWanted }
    Invoke-Step 'App Installer (Ninite)'    { Open-NiniteIfWanted }
    Invoke-Step 'GPU Drivers'               { Open-GpuDriverPageIfWanted }
    Invoke-Step 'DDU'                       { Open-DduPageIfWanted }
    Invoke-Step 'Chipset Drivers'           { Open-ChipsetsDriverPageIfWanted }
    Invoke-Step 'Monitoring Tools'          { Open-MonitoringToolsIfWanted }
    Invoke-Step 'CrystalDiskMark'           { Open-CrystalDiskMarkIfWanted }
    Invoke-Step 'GPU Scheduling'            { Set-HardwareAcceleratedGpuSchedulingOn }
    Invoke-Step 'Variable Refresh Rate'     { Set-VariableRefreshRateOn }
    Invoke-Step 'Game Mode'                 { Set-GameModeOff }
    Invoke-Step 'Xbox Game Bar'             { Set-XboxGameBarOff }
    Invoke-Step 'Fullscreen Optimizations'  { Set-FullscreenOptimizationsOff }
    Invoke-Step 'Timer Resolution'          { Set-TimerResolution }
    Invoke-Step 'MSI Mode'                  { Set-MsiModeForGpu }
    Invoke-Step 'Power Plan'                { Set-PowerPlan }
    Invoke-Step 'Mouse Acceleration'        { Set-MouseAccelerationOff }
    Invoke-Step 'File Extensions'           { Set-FileExtensionsVisible }
    Invoke-Step 'Hidden Files'              { Set-HiddenFilesVisible }
    Invoke-Step 'Dark Mode'                 { Set-DarkModeOn }
    Invoke-Step 'Diagnostic Data'           { Set-OptionalDiagnosticDataOff }
    Invoke-Step 'Delivery Optimization'     { Set-DeliveryOptimizationHttpOnly }
    Invoke-Step 'DNS'                       { Set-DnsServers }
    Invoke-Step 'NIC Power Saving'          { Set-NicPowerSavingOff }
    Invoke-Step 'System Protection'         { Set-SystemProtectionIfWanted }
    Invoke-Step 'Clipboard History'         { Set-ClipboardHistoryIfWanted }
    Invoke-Step 'Do Not Disturb'            { Test-DoNotDisturbIfWanted }
    Invoke-Step 'Windows Update'            { Start-WindowsUpdateIfWanted }
    Invoke-Step 'Debloater'                 { Start-DebloaterIfWanted }

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
