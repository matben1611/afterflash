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
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            default { Write-Host "Please enter 'Yes' or 'No'." }
        }
    }
}

function Test-RegistryKey {
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

    Test-RegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    Write-Ok "$Path -> $Name = $Value"
}

function Set-StringValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    Test-RegistryKey -Path $Path
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
    Write-Ok "$Path -> $Name = $Value"
}

function Set-BiosRecommendationsFileIfWanted {
    Write-Host ""
    $createBiosFile = Read-YesNo -Prompt "Do you want to create a BIOS recommendations file on the desktop"

    if ($createBiosFile) {
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $filePath = Join-Path $desktopPath 'bios-recommendations.txt'

        $content = @"
Recommended BIOS Settings
=========================

- Enable EXPO/XMP
  Enables the rated memory speed and timings instead of slow default JEDEC values.

- Enable Resizable BAR
  Can improve GPU performance and is generally recommended on modern gaming systems.

- Disable CSM
  Ensures proper UEFI boot behavior and avoids legacy compatibility issues.

- Check Secure Boot
  Recommended for a modern Windows setup and required by some security features.

- Enable TPM / fTPM
  Required for Windows 11 features and useful for security-related functionality.

- Check SATA / NVMe configuration
  Make sure storage devices are detected correctly and running in the intended mode.

- Configure fan curves
  Helps balance temperatures and noise levels for daily use.

- Disable iGPU if not needed
  Can simplify the system configuration on builds that only use a dedicated graphics card.

- Enable Memory Context Restore only if the system remains stable
  Can reduce boot times, but may cause memory instability on some systems.

- Review X3D-specific recommendations
  X3D CPUs often perform best with sensible stock-like settings instead of aggressive tuning.

PBO / Curve Optimizer
=====================

IMPORTANT DISCLAIMER
--------------------
PBO and Curve Optimizer are not guaranteed-safe "set and forget" settings.
Even if a system boots and seems fine in games, unstable values can still cause:
- random crashes
- WHEA errors
- corrupted installs or files
- game instability
- rare idle or sleep crashes

Every CPU is different.
A value that works on one chip can be unstable on another.
If you do not want to test stability properly, leave these settings at stock.

Recommended conservative starting points
----------------------------------------
These are not maximum-performance values.
They are only reasonable starting points for light tuning.

PBO:
- Precision Boost Overdrive = Enabled or Advanced
- PBO Limits = Motherboard or Auto
- Scalar = Auto or 1-10 -> higher values can cause stability issues
- Max CPU Boost Clock Override = 0 MHz or try 200MHz for maxmimum performance
- Thermal Limit = Auto

Curve Optimizer:
- Curve Optimizer Mode = Negative
- Start with:
  - All Cores = Negative 10

If stable, you can cautiously try:
- All Cores = Negative 15-30

Only if the system is known to be very stable:
- Best cores = Negative 5 to 10
- Other cores = Negative 10 to 20

Safe recommendation for most users
----------------------------------
If you want a simple baseline:
- PBO = Enabled
- Curve Optimizer = Negative 10 on all cores
- Boost Override = 0 MHz
- Scalar = Auto

For X3D CPUs
------------
Be extra conservative on X3D CPUs.
A very reasonable baseline is:
- PBO = Enabled
- Curve Optimizer = Negative 10 all-core
- no extra boost override
- leave the rest on Auto unless you really know what you are doing

If you notice crashes, stutter, WHEA errors, failed boots, or strange behavior:
- set Curve Optimizer closer to 0
- disable PBO tuning
- return to stock settings

"@

        Set-Content -Path $filePath -Value $content -Encoding UTF8
        Write-Ok "BIOS recommendations file created: $filePath"
    }
    else {
        Write-Info "BIOS recommendations file was not created."
    }

    Write-Host ""
}

function Open-NiniteIfWanted {
    Write-Host ""
    $openNinite = Read-YesNo -Prompt "Do you want to open Ninite to install useful apps"

    if ($openNinite) {
        Write-Info "Opening Ninite in your browser..."
        Start-Process "https://ninite.com/"
        Write-Ok "Ninite opened."
    }
    else {
        Write-Info "Ninite was not opened."
    }

    Write-Host ""
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

function Test-DoNotDisturbIfWanted {
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

    Test-RegistryKey -Path $path

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
    Test-RegistryKey -Path $path

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

function Show-SystemInformation {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "           System Information           " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $cpu = "Unknown"
    $gpu = "Unknown"
    $installedRam = "Unknown"
    $ramSpeed = "Not reported by system"
    $mainboardName = "Unknown"
    $biosVersion = "Unknown"
    $osVersion = "Unknown"
    $osType = "Unknown"

    try {
        $cpu = Get-CimInstance Win32_Processor |
            Select-Object -First 1 -ExpandProperty Name
    }
    catch {}

    try {
        $gpuList = Get-CimInstance Win32_VideoController |
            Select-Object -ExpandProperty Name

        $gpu = ($gpuList |
            Where-Object { $_ -and $_.Trim() -ne "" } |
            Select-Object -Unique) -join ", "

        if (-not $gpu) {
            $gpu = "Unknown"
        }
    }
    catch {}

    try {
        $memoryModules = Get-CimInstance Win32_PhysicalMemory
        $totalRamBytes = ($memoryModules | Measure-Object -Property Capacity -Sum).Sum

        if ($totalRamBytes) {
            $installedRam = "$([math]::Round($totalRamBytes / 1GB, 0)) GB"
        }

        $ramSpeedValue = $memoryModules |
            ForEach-Object {
                if ($_.ConfiguredClockSpeed -and $_.ConfiguredClockSpeed -gt 0) {
                    $_.ConfiguredClockSpeed
                }
                elseif ($_.Speed -and $_.Speed -gt 0) {
                    $_.Speed
                }
            } |
            Where-Object { $_ } |
            Select-Object -First 1

        if ($ramSpeedValue) {
            $ramSpeed = "$ramSpeedValue MT/s"
        }
    }
    catch {}

    try {
        $baseBoard = Get-CimInstance Win32_BaseBoard | Select-Object -First 1

        $invalidBoardValues = @(
            "",
            "Default string",
            "To be filled by O.E.M.",
            "System Version",
            "Undefined"
        )

        if (
            $baseBoard.Product -and
            $invalidBoardValues -notcontains $baseBoard.Product.Trim()
        ) {
            $mainboardName = $baseBoard.Product
        }
        else {
            $mainboardName = "Not reported"
        }
    }
    catch {}

    try {
        $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1

        if ($bios.SMBIOSBIOSVersion -and $bios.SMBIOSBIOSVersion.Trim() -ne "") {
            $biosVersion = $bios.SMBIOSBIOSVersion
        }
        elseif ($bios.Version -and $bios.Version.Trim() -ne "") {
            $biosVersion = $bios.Version
        }
    }
    catch {}

    try {
        $os = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1

        $caption = $os.Caption
        $build = $os.BuildNumber
        $version = $os.Version

        if ($caption -and $build -and $version) {
            $osVersion = "$caption ($version, Build $build)"
        }
        elseif ($caption) {
            $osVersion = $caption
        }

        if ($os.OSArchitecture -and $os.OSArchitecture.Trim() -ne "") {
            $osType = $os.OSArchitecture
        }
    }
    catch {}

    Write-Host ("{0,-20}: {1}" -f "CPU", $cpu)
    Write-Host ("{0,-20}: {1}" -f "GPU", $gpu)
    Write-Host ("{0,-20}: {1}" -f "Installed RAM", $installedRam)
    Write-Host ("{0,-20}: {1}" -f "RAM Speed", $ramSpeed)
    Write-Host ("{0,-20}: {1}" -f "Mainboard", $mainboardName)
    Write-Host ("{0,-20}: {1}" -f "BIOS Version", $biosVersion)
    Write-Host ("{0,-20}: {1}" -f "OS Version", $osVersion)
    Write-Host ("{0,-20}: {1}" -f "OS Type", $osType)

    Write-Host ""
}

function Open-GpuDriverPageIfWanted {
    Write-Host ""
    $openDriverPage = Read-YesNo -Prompt "Do you want to open the GPU driver download page"

    if (-not $openDriverPage) {
        Write-Info "GPU driver page was not opened."
        Write-Host ""
        return
    }

    while ($true) {
        $gpuVendor = (Read-Host "Which GPU vendor do you use? (AMD/NVIDIA)").Trim().ToLowerInvariant()

        switch ($gpuVendor) {
            'amd' {
                Write-Info "Opening AMD driver page..."
                Start-Process "https://www.amd.com/en/support/download/drivers.html"
                Write-Ok "AMD driver page opened."
                Write-Host ""
                return
            }

            'nvidia' {
                Write-Info "Opening NVIDIA driver page..."
                Start-Process "https://www.nvidia.com/en-us/drivers/"
                Write-Ok "NVIDIA driver page opened."
                Write-Host ""
                return
            }

            default {
                Write-Host "Please enter AMD or NVIDIA."
            }
        }
    }
}

try {
    Restart-AsAdmin

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

    Wait-A-Bit

    Open-NiniteIfWanted

    Wait-A-Bit

    Open-GpuDriverPageIfWanted

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
    Test-DoNotDisturbIfWanted

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
