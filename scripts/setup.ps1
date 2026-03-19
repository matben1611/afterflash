[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-A-Bit {
    $seconds = Get-Random -Minimum 1 -Maximum 3
    Start-Sleep -Seconds $seconds
}

function Restart-AsAdmin {
    if (-not (Test-IsAdmin)) {
        Write-Host ""
        Write-Host "This script requires administrator privileges."
        Wait-A-Bit

        Write-Host "User Account Control will open now..."
        Wait-A-Bit
        Write-Host ""

        $scriptPath = $PSCommandPath

        if (-not $scriptPath) {
            throw "The script path could not be determined. Start the script directly with .\setup.ps1"
        }

        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', "`"$scriptPath`""
            )

        exit
    }
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO ] $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[ OK  ] $Message"
}

function Write-WarnMsg {
    param([string]$Message)
    Write-Warning $Message
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $answer = (Read-Host "$Prompt (Yes/No)").Trim().ToLowerInvariant()

        switch ($answer) {
            'y'     { return $true }
            'yes'   { return $true }
            'n'     { return $false }
            'no'    { return $false }
            default { Write-Host "Please enter 'Yes' or 'No'." }
        }
    }
}

function Ensure-RegistryKey {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-DwordValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    Ensure-RegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    Write-Ok "$Path -> $Name = $Value"
}

function Set-StringValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    Ensure-RegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
    Write-Ok "$Path -> $Name = $Value"
}

function Set-OptionalDiagnosticDataOff {
    Write-Host ""
    Write-Info "Disabling optional diagnostic data..."

    Set-DwordValue `
        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
        -Name 'AllowTelemetry' `
        -Value 1

    Write-Ok "Diagnostic data set to Required only."
    Write-Host ""
}

function Set-DeliveryOptimizationHttpOnly {
    Write-Host ""
    Write-Info "Setting Delivery Optimization to HTTP only..."

    Set-DwordValue `
        -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' `
        -Name 'DODownloadMode' `
        -Value 0

    Write-Ok "Delivery Optimization peer-to-peer disabled."
    Write-Host ""
}

function Set-SystemProtectionIfWanted {
    Write-Host ""
    $enableSystemProtection = Read-YesNo -Prompt "Do you want to enable System Protection on drive C"

    if ($enableSystemProtection) {
        Write-Info "Enabling System Protection on C: ..."
        Enable-ComputerRestore -Drive "C:\"
        Write-Ok "System Protection enabled on C:."
    }
    else {
        Write-Info "System Protection was not changed."
    }

    Write-Host ""
}

function Set-ClipboardHistoryIfWanted {
    Write-Host ""
    $enableClipboardHistory = Read-YesNo -Prompt "Do you want to enable Clipboard History"

    if ($enableClipboardHistory) {
        Write-Info "Enabling Clipboard History..."

        Set-DwordValue `
            -Path 'HKCU:\Software\Microsoft\Clipboard' `
            -Name 'EnableClipboardHistory' `
            -Value 1

        Write-Ok "Clipboard History enabled."

        $openClipboardSettings = Read-YesNo -Prompt "Do you want to open Clipboard settings now"

        if ($openClipboardSettings) {
            Start-Process "ms-settings:clipboard"
            Write-Info "Clipboard settings opened."
        }
    }
    else {
        Write-Info "Clipboard History was not changed."
    }

    Write-Host ""
}

function Configure-DoNotDisturbIfWanted {
    Write-Host ""
    $configureDnd = Read-YesNo -Prompt "Do you want to configure Do Not Disturb now"

    if ($configureDnd) {
        Write-Info "Opening Notifications settings..."
        Start-Process "ms-settings:notifications"
        Write-Info "Set Do Not Disturb manually in the Notifications page."
    }
    else {
        Write-Info "Do Not Disturb was not changed."
    }

    Write-Host ""
}

function Set-HardwareAcceleratedGpuSchedulingOn {
    Write-Host ""
    Write-Info "Enabling hardware-accelerated GPU scheduling..."
    
    Set-DwordValue `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
        -Name 'HwSchMode' `
        -Value 2

    Write-WarnMsg "A restart may be required."
    Write-Host ""
}

function Set-VariableRefreshRateOff {
    Write-Host ""
    Write-Info "Disabling Variable Refresh Rate..."

    $path = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    $name = 'DirectXUserGlobalSettings'

    Ensure-RegistryKey -Path $path

    $existing = ''
    try {
        $existing = (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name
    }
    catch {
        $existing = ''
    }

    $map = [ordered]@{}

    if ($existing) {
        $tokens = $existing -split ';' | Where-Object { $_ -and $_.Trim() -ne '' }
        foreach ($token in $tokens) {
            $parts = $token -split '=', 2
            if ($parts.Count -eq 2) {
                $map[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }

    $map['VRROptimizeEnable'] = '0'

    $newValue = (($map.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';') + ';'

    Set-StringValue -Path $path -Name $name -Value $newValue
    Write-WarnMsg "Signing out/in or restarting may be required."
    Write-Host ""
}

function Set-GameModeOff {
    Write-Host ""
    Write-Info "Disabling Game Mode..."

    Set-DwordValue `
        -Path 'HKCU:\Software\Microsoft\GameBar' `
        -Name 'AutoGameModeEnabled' `
        -Value 0

    Write-Host ""
}

function Set-MouseAccelerationOff {
    Write-Host ""
    Write-Info "Disabling mouse acceleration..."

    $path = 'HKCU:\Control Panel\Mouse'
    Ensure-RegistryKey -Path $path

    Set-StringValue -Path $path -Name 'MouseSpeed'      -Value '0'
    Set-StringValue -Path $path -Name 'MouseThreshold1' -Value '0'
    Set-StringValue -Path $path -Name 'MouseThreshold2' -Value '0'

    Write-WarnMsg "Signing out/in or restarting may be required."
    Write-Host ""
}

function Set-BalancedPowerPlanIfX3D {
    Write-Host ""
    $isX3D = Read-YesNo -Prompt "Is an X3D CPU installed?"

    if ($isX3D) {
        Write-Info "Setting power plan to Balanced..."
        powercfg /setactive SCHEME_BALANCED | Out-Null
        Write-Ok "Power plan set to Balanced."
    }
    else {
        Write-Info "X3D answer = No -> power plan remains unchanged."
    }

    Write-Host ""
}

function Start-DebloaterIfWanted {
    Write-Host ""
    $startDebloater = Read-YesNo -Prompt "Do you want to start the debloater"

    if ($startDebloater) {
        Write-Info "Starting debloater in a new PowerShell window..."

        $command = '& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))'

        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            '-NoExit',
            '-ExecutionPolicy', 'Bypass',
            '-Command', $command
        )

        Write-Ok "Debloater started in a new window."
    }
    else {
        Write-Info "Debloater was not started."
    }

    Write-Host ""
}

try {
    Restart-AsAdmin

    Write-Host ""
    Write-Host "========================================"
    Write-Host "         Windows Setup Starting         "
    Write-Host "========================================"
    Write-Host ""

    Wait-A-Bit
    Set-HardwareAcceleratedGpuSchedulingOn

    Wait-A-Bit
    Set-VariableRefreshRateOff

    Wait-A-Bit
    Set-GameModeOff

    Wait-A-Bit
    Set-BalancedPowerPlanIfX3D

    Wait-A-Bit
    Set-MouseAccelerationOff

    Wait-A-Bit
    Set-OptionalDiagnosticDataOff

    Wait-A-Bit
    Set-DeliveryOptimizationHttpOnly

    Wait-A-Bit
    Set-SystemProtectionIfWanted

    Wait-A-Bit
    Set-ClipboardHistoryIfWanted

    Wait-A-Bit
    Configure-DoNotDisturbIfWanted

    Write-Host ""
    Write-Host "========================================"
    Write-Host "          Settings Applied              "
    Write-Host "========================================"
    Write-Host ""

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
