[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulesDir = Join-Path $PSScriptRoot 'modules'
. "$modulesDir\helpers.ps1"
. "$modulesDir\system.ps1"
. "$modulesDir\tweaks.ps1"
. "$modulesDir\apps.ps1"
. "$modulesDir\monitoring.ps1"

$script:quickSetup         = $false
$script:currentStep        = 0
$script:totalSteps         = 29
$script:currentStepApplied = $false
$script:report             = [System.Collections.ArrayList]::new()
$script:logFile            = Join-Path $env:TEMP "afterflash-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Body,
        [switch]$SkipInQuickSetup
    )
    $script:currentStep++
    $script:currentStepApplied = $false

    if ($script:quickSetup) {
        if (-not $SkipInQuickSetup) {
            try { & $Body } catch { Write-Verbose "Step '$Label' failed: $_" }
            if ($script:currentStepApplied) { [void]$script:report.Add($Label) }
        }
        return
    }

    Write-Host "  [$script:currentStep/$script:totalSteps] $Label" -ForegroundColor Cyan
    & $Body
    if ($script:currentStepApplied) { [void]$script:report.Add($Label) }
    Wait-A-Bit
}

function Show-Report {
    if ($script:report.Count -eq 0) { return }

    Write-Host ""
    Write-Host "========================================"
    Write-Host "          Changes Applied               "
    Write-Host "========================================"
    foreach ($entry in $script:report) {
        Write-Host "  [+] $entry"
    }
    Write-Host "========================================"
    Write-Host ""
}

try {
    Restart-AsAdmin

    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
    Clear-Host

    Add-Content -Path $script:logFile -Value "afterflash log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
    Add-Content -Path $script:logFile -Value "========================================" -Encoding UTF8

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

    Invoke-Step 'Hardware Monitoring' { Show-HardwareMonitoring }

    Write-Host ""
    $createRestorePoint = Read-YesNo -Prompt "Do you want to create a System Restore Point before making changes"
    if ($createRestorePoint) {
        Write-Info "Creating System Restore Point..."
        try {
            Checkpoint-Computer -Description "afterflash $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
            Write-Ok "Restore Point created."
        }
        catch {
            Write-WarnMsg "Could not create Restore Point. System Protection may be disabled on C:."
        }
    }
    Write-Host ""

    Write-Host ""
    $script:quickSetup = Read-YesNo -Prompt "Do you want to use Quick Setup (applies all tweaks automatically)"
    Write-Host ""

    if ($script:quickSetup) {
        Write-Host "  Applying all tweaks..." -ForegroundColor Cyan
        Write-Host ""
    }

    Invoke-Step 'BIOS Recommendations'       { Set-BiosRecommendationsFileIfWanted }
    Invoke-Step 'App Installer (Ninite)'     { Open-NiniteIfWanted }           -SkipInQuickSetup
    Invoke-Step 'GPU Drivers'                { Open-GpuDriverPageIfWanted }    -SkipInQuickSetup
    Invoke-Step 'DDU'                        { Open-DduPageIfWanted }           -SkipInQuickSetup
    Invoke-Step 'Chipset Drivers'            { Open-ChipsetsDriverPageIfWanted } -SkipInQuickSetup
    Invoke-Step 'Monitoring Tools'           { Open-MonitoringToolsIfWanted }   -SkipInQuickSetup
    Invoke-Step 'CrystalDiskMark'            { Open-CrystalDiskMarkIfWanted }   -SkipInQuickSetup
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
    Invoke-Step 'DNS'                        { Set-DnsServers }                 -SkipInQuickSetup
    Invoke-Step 'NIC Power Saving'           { Set-NicPowerSavingOff }
    Invoke-Step 'System Protection'          { Set-SystemProtectionIfWanted }   -SkipInQuickSetup
    Invoke-Step 'Clipboard History'          { Set-ClipboardHistoryIfWanted }   -SkipInQuickSetup
    Invoke-Step 'Do Not Disturb'             { Test-DoNotDisturbIfWanted }      -SkipInQuickSetup
    Invoke-Step 'Windows Update'             { Start-WindowsUpdateIfWanted }    -SkipInQuickSetup
    Invoke-Step 'Debloater'                  { Start-DebloaterIfWanted }

    Show-Report

    Write-Host ""
    Write-Host "========================================"
    Write-Host "               Finished                 "
    Write-Host "========================================"
    Write-Host ""
    Write-Host "  Log saved to: $script:logFile" -ForegroundColor DarkGray
    Write-Host ""
}
catch {
    Write-Error $_
}
finally {
    Read-Host "`nPress Enter to exit..."
}
