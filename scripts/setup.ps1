[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulesDir = Join-Path $PSScriptRoot 'modules'
. "$modulesDir\helpers.ps1"
. "$modulesDir\system.ps1"
. "$modulesDir\tweaks.ps1"
. "$modulesDir\apps.ps1"

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host

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
    Wait-A-Bit

    Show-SystemInformation

    Wait-A-Bit

    Set-BiosRecommendationsFileIfWanted
    Open-NiniteIfWanted
    Open-GpuDriverPageIfWanted
    Open-ChipsetsDriverPageIfWanted
    Set-HardwareAcceleratedGpuSchedulingOn
    Set-VariableRefreshRateOn
    Set-GameModeOff
    Set-PowerPlan
    Set-MouseAccelerationOff
    Set-OptionalDiagnosticDataOff
    Set-DeliveryOptimizationHttpOnly
    Set-SystemProtectionIfWanted
    Set-ClipboardHistoryIfWanted
    Test-DoNotDisturbIfWanted

    Write-Host ""
    Write-Host "========================================"
    Write-Host "          Settings Applied              "
    Write-Host "========================================"
    Write-Host ""

    Start-WindowsUpdateIfWanted
    Wait-A-Bit
    Start-DebloaterIfWanted
    Wait-A-Bit

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
