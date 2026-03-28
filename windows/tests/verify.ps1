[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Wait-A-Bit {
    $seconds = Get-Random -Minimum 1 -Maximum 3
    Start-Sleep -Seconds $seconds
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "========================================"
    Write-Host " $Title"
    Write-Host "========================================"
    Write-Host ""
}

function Open-CheckStep {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Instruction,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    Write-Section $Title
    Write-Host $Instruction
    Write-Host ""
    Read-Host "Press Enter to open this page"
    & $Action
    Write-Host ""
    Read-Host "Check the setting, then press Enter to continue"
    Wait-A-Bit
}

try {
    Write-Section "Windows Settings Verification"

    Open-CheckStep `
        -Title "Graphics Settings" `
        -Instruction "Check that Hardware-accelerated GPU scheduling is ON and Variable refresh rate is OFF." `
        -Action { Start-Process "ms-settings:display-advancedgraphics" }

    Open-CheckStep `
        -Title "Gaming Settings" `
        -Instruction "Check that Game Mode is OFF." `
        -Action { Start-Process "ms-settings:gaming-gamemode" }

    Open-CheckStep `
        -Title "Mouse Settings" `
        -Instruction "Open additional mouse options and check that Enhance pointer precision is OFF." `
        -Action { Start-Process "main.cpl" }

    Open-CheckStep `
        -Title "Clipboard Settings" `
        -Instruction "Check whether Clipboard history matches your chosen value." `
        -Action { Start-Process "ms-settings:clipboard" }

    Open-CheckStep `
        -Title "Notifications / Do Not Disturb" `
        -Instruction "Check whether Do Not Disturb matches your chosen value." `
        -Action { Start-Process "ms-settings:notifications" }

    Open-CheckStep `
        -Title "System Protection" `
        -Instruction "Check whether Protection for drive C: is turned on." `
        -Action { Start-Process "SystemPropertiesProtection.exe" }

    Open-CheckStep `
        -Title "Diagnostic Data" `
        -Instruction "Check that Windows is not set to send optional diagnostic data." `
        -Action { Start-Process "ms-settings:privacy-feedback" }

    Write-Section "Verification Finished"
}
catch {
    Write-Error $_
}
