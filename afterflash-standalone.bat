@echo off
set "TMPPS=%TEMP%\afterflash_setup.ps1"

for /f "tokens=1 delims=:" %%L in ('findstr /n "^##PSBEGIN##" "%~f0"') do set /a PSSTART=%%L
more +%PSSTART% "%~f0" > "%TMPPS%"
if errorlevel 1 ( echo Fehler beim Extrahieren des Scripts. & pause & exit /b 1 )

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%"
if errorlevel 1 pause
goto :eof

##PSBEGIN##
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Typewriter {
    param(
        [Parameter(Mandatory)][string]$Text,
        [int]$DelayMs = 35
    )
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

function Wait-A-Bit {
    $seconds = Get-Random -Minimum 1 -Maximum 3
    $totalMs = $seconds * 1000
    $frames  = @('|', '/', '-', '\')
    $frameMs = 80
    $ticks   = [math]::Ceiling($totalMs / $frameMs)

    for ($i = 0; $i -lt $ticks; $i++) {
        $frame = $frames[$i % $frames.Count]
        Write-Host -NoNewline "`r  $frame  "
        Start-Sleep -Milliseconds $frameMs
    }
    Write-Host "`r     "
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
            'y'   { Write-Host ""; Write-Host ""; return $true }
            'yes' { Write-Host ""; Write-Host ""; return $true }
            'n'   { Write-Host ""; Write-Host ""; return $false }
            'no'  { Write-Host ""; Write-Host ""; return $false }
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

        # Gather system information
        $cpu = "Unknown"
        $gpu = "Unknown"
        $installedRam = "Unknown"
        $mainboardName = "Unknown"

        try {
            $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop |
                Select-Object -First 1 -ExpandProperty Name
        }
        catch {
            Write-Verbose "Unable to retrieve CPU information"
        }

        try {
            $gpuList = Get-CimInstance Win32_VideoController -ErrorAction Stop |
                Select-Object -ExpandProperty Name |
                Where-Object { $_ -and $_.Trim() -ne "" }
            $gpu = ($gpuList -join ", ")
        }
        catch {
            Write-Verbose "Unable to retrieve GPU information"
        }

        try {
            $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
            $totalRamBytes = ($memoryModules | Measure-Object -Property Capacity -Sum).Sum
            if ($totalRamBytes) {
                $installedRam = "$([math]::Round($totalRamBytes / 1GB, 0)) GB"
            }
        }
        catch {
            Write-Verbose "Unable to retrieve RAM information"
        }

        try {
            $baseBoard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | Select-Object -First 1
            $invalidBoardValues = @("", "Default string", "To be filled by O.E.M.", "System Version", "Undefined")
            if ($baseBoard.Product -and $invalidBoardValues -notcontains $baseBoard.Product.Trim()) {
                $mainboardName = $baseBoard.Product
            }
        }
        catch {
            Write-Verbose "Unable to retrieve mainboard information"
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $content = @"
=================================================================================
                           SYSTEM INFORMATION
=================================================================================
CPU:         $cpu
GPU:         $gpu
RAM:         $installedRam
Mainboard:   $mainboardName
Generated:   $timestamp
=================================================================================


RECOMMENDED BIOS SETTINGS
-------------------------------------------------------------------------------

[EXPO/XMP MEMORY PROFILE]
  Enable this setting to run your memory at the manufacturer's rated speed
  and timings instead of conservative JEDEC defaults.

  Most modern memory kits support this feature.
  Recommended: ENABLED

[RESIZABLE BAR / SAM (Smart Access Memory)]
  Allows the GPU to access the entire VRAM instead of small chunks.
  Can improve performance in some scenarios, especially gaming.

  Recommended: ENABLED (if available in your BIOS)

[SECURE BOOT]
  Modern security feature required by Windows 11 features and Trusted Platform Module.
  Should be enabled for a secure modern setup.

  Recommended: ENABLED

[TPM / fTPM (Trusted Platform Module)]
  Required for Windows 11 advanced security features.
  Usually found under Security or Trusted Computing.

  Recommended: ENABLED

[CSM (Compatibility Support Module)]
  Legacy feature for older devices. Modern systems don't need this.
  Can cause boot issues if enabled unnecessarily.

  Recommended: DISABLED

[STORAGE CONFIGURATION]
  Verify SATA and NVMe controllers are in the correct mode (AHCI for SATA).
  Ensure all your storage devices are detected and running properly.

  Recommended: Check once, leave as default unless issues occur

[FAN CURVES]
  Configure custom fan curves for better cooling and noise balance.
  Most modern boards offer this under System Health or Temperature Monitoring.

  Recommended: Optional - adjust based on your cooling solution

[INTEGRATED GPU (iGPU)]
  If you're using a dedicated graphics card, disabling the iGPU can simplify
  system configuration and avoid potential conflicts.

  Recommended: DISABLE (if you have a discrete GPU)


ADVANCED TUNING: PBO & CURVE OPTIMIZER
-------------------------------------------------------------------------------

!!! IMPORTANT DISCLAIMER !!!
-------------------------------------------------------------------------------
PBO and Curve Optimizer are NOT guaranteed-safe "set and forget" settings!

Even if your system boots and performs well in games initially, unstable values
can cause serious issues:
  * Random system crashes
  * Game crashes and unexpected behavior
  * WHEA errors (shown in Windows Event Viewer)
  * Data corruption or file loss
  * Sleep/idle instability (crashes when idle)

Every CPU is unique due to manufacturing variation. A setting that works on one
chip can be unstable on another, even from the same batch.

IF YOU DON'T WANT TO TEST STABILITY THOROUGHLY, LEAVE THESE AT STOCK DEFAULTS.
-------------------------------------------------------------------------------


CONSERVATIVE RECOMMENDED BASELINE
-------------------------------------------------------------------------------

These settings are NOT maximum performance - they are safe starting points
for light tuning that most systems should handle:

PBO Settings:
  Precision Boost Overdrive .................... Enabled or Advanced
  PBO Limits .................................. Motherboard or Auto
  Max CPU Boost Override ....................... 0 MHz (or 200 MHz for mild boost)
  Scalar ....................................... Auto (1-10 OK, higher = stability risk)
  Thermal Limit ................................ Auto

Curve Optimizer Settings:
  Mode ......................................... Negative
  Start conservative ............................ All Cores = Negative 10

If successful and stable for 2+ weeks:
  Can cautiously try ............................ Negative 15-20 on all cores

Only if proven stable:
  Best cores ................................... Negative 5-10
  Other cores .................................. Negative 10-20


SPECIAL: X3D CPUs (Ryzen 7/5 X3D)
-------------------------------------------------------------------------------
X3D CPUs already have large 3D V-Cache and work best with minimal tuning:

Conservative recommendation:
  PBO .......................................... Enabled
  Curve Optimizer .............................. Negative 10 all-core (conservative)
  Boost Override ............................... 0 MHz (no extra margin needed)
  Everything else .............................. Stock/Auto

If your X3D system becomes unstable (crashes, WHEA errors, game crashes):
  Reduce Curve Optimizer ....................... closer to 0 (Negative 5)
  Disable PBO completely ....................... use stock only
  Return to stock .............................. if problems persist


HOW TO TEST STABILITY
-------------------------------------------------------------------------------
1. Make BIOS changes one at a time
2. Run system normally for 1-2 weeks
3. Watch for crashes, WHEA errors, or game instability
4. If stable after 2 weeks, each change is good
5. If issues appear, revert the last change


FINDING WHEA ERRORS
-------------------------------------------------------------------------------
Windows Event Viewer > Windows Logs > System > Look for "WHEA-Logger" errors.
Multiple WHEA errors = your overclock/tuning isn't stable enough.


FINAL ADVICE
-------------------------------------------------------------------------------
* When in doubt, use stock settings
* Stability is more important than +5% performance
* Test thoroughly before trusting your system
* Keep backups of important data

Good luck!

"@

        Set-Content -Path $filePath -Value $content -Encoding ASCII
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
    $disableDiagnostics = Read-YesNo -Prompt "Do you want to disable optional diagnostic data"

    if ($disableDiagnostics) {
        Write-Info "Disabling optional diagnostic data..."

        Set-DwordValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
            -Name 'AllowTelemetry' `
            -Value 1

        Write-Ok "Diagnostic data set to Required only."
    }
    else {
        Write-Info "Diagnostic data settings were not changed."
    }

    Write-Host ""
}

function Set-DeliveryOptimizationHttpOnly {
    Write-Host ""
    $disableDeliveryOptimization = Read-YesNo -Prompt "Do you want to disable Delivery Optimization peer-to-peer"

    if ($disableDeliveryOptimization) {
        Write-Info "Setting Delivery Optimization to HTTP only..."

        Set-DwordValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' `
            -Name 'DODownloadMode' `
            -Value 0

        Write-Ok "Delivery Optimization peer-to-peer disabled."
    }
    else {
        Write-Info "Delivery Optimization settings were not changed."
    }

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
    $enableGpuScheduling = Read-YesNo -Prompt "Do you want to enable hardware-accelerated GPU scheduling"

    if ($enableGpuScheduling) {
        Write-Info "Enabling hardware-accelerated GPU scheduling..."

        Set-DwordValue `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
            -Name 'HwSchMode' `
            -Value 2

        Write-WarnMsg "A restart may be required."
    }
    else {
        Write-Info "Hardware-accelerated GPU scheduling was not changed."
    }

    Write-Host ""
}

function Set-VariableRefreshRateOn {
    Write-Host ""
    $enableVrr = Read-YesNo -Prompt "Do you want to enable Variable Refresh Rate"

    if ($enableVrr) {
        Write-Info "Enabling Variable Refresh Rate..."

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

        $map['VRROptimizeEnable'] = '1'

        $newValue = (($map.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';') + ';'

        Set-StringValue -Path $path -Name $name -Value $newValue
        Write-WarnMsg "Signing out/in or restarting may be required."
    }
    else {
        Write-Info "Variable Refresh Rate settings were not changed."
    }

    Write-Host ""
}

function Set-GameModeOff {
    Write-Host ""
    $disableGameMode = Read-YesNo -Prompt "Do you want to disable Game Mode"

    if ($disableGameMode) {
        Write-Info "Disabling Game Mode..."

        Set-DwordValue `
            -Path 'HKCU:\Software\Microsoft\GameBar' `
            -Name 'AutoGameModeEnabled' `
            -Value 0

        Write-Ok "Game Mode disabled."
    }
    else {
        Write-Info "Game Mode settings were not changed."
    }

    Write-Host ""
}

function Set-MouseAccelerationOff {
    Write-Host ""
    $disableMouseAcceleration = Read-YesNo -Prompt "Do you want to disable mouse acceleration"

    if ($disableMouseAcceleration) {
        Write-Info "Disabling mouse acceleration..."

        $path = 'HKCU:\Control Panel\Mouse'
        Test-RegistryKey -Path $path

        Set-StringValue -Path $path -Name 'MouseSpeed'      -Value '0'
        Set-StringValue -Path $path -Name 'MouseThreshold1' -Value '0'
        Set-StringValue -Path $path -Name 'MouseThreshold2' -Value '0'

        Write-WarnMsg "Signing out/in or restarting may be required."
    }
    else {
        Write-Info "Mouse acceleration settings were not changed."
    }

    Write-Host ""
}

function Set-PowerPlan {
    Write-Host ""
    $setPowerPlan = Read-YesNo -Prompt "Do you want to set the optimal power plan for your CPU"

    if (-not $setPowerPlan) {
        Write-Info "Power plan was not changed."
        Write-Host ""
        return
    }

    $cpu = "Unknown"
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty Name
    }
    catch {
        Write-Verbose "Unable to retrieve CPU information"
    }

    $cpuLower = $cpu.ToLowerInvariant()

    if ($cpuLower -match 'x3d') {
        Write-Info "X3D CPU detected: $cpu"
        Write-Info "Setting power plan to Balanced (recommended for X3D)..."
        powercfg /setactive SCHEME_BALANCED | Out-Null
        Write-Ok "Power plan set to Balanced."
    }
    else {
        Write-Info "CPU detected: $cpu"

        $ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        $schemes = powercfg /list 2>&1

        if ($schemes -match $ultimateGuid) {
            Write-Info "Setting power plan to Ultimate Performance..."
            powercfg /setactive $ultimateGuid | Out-Null
            Write-Ok "Power plan set to Ultimate Performance."
        }
        else {
            Write-Info "Ultimate Performance not available."
            Write-Info "Setting power plan to High Performance..."
            powercfg /setactive SCHEME_MIN | Out-Null
            Write-Ok "Power plan set to High Performance."
        }
    }

    Write-Host ""
}

function Start-WindowsUpdateIfWanted {
    Write-Host ""
    $startUpdate = Read-YesNo -Prompt "Do you want to check for Windows Updates now"

    if ($startUpdate) {
        Write-Info "Triggering Windows Update scan..."

        try {
            Start-Process "UsoClient.exe" -ArgumentList "StartScan"
        }
        catch {
            Write-Verbose "UsoClient scan trigger failed, continuing..."
        }

        Start-Process "ms-settings:windowsupdate"
        Write-Ok "Windows Update scan triggered."
        Write-Info "Check the Windows Update page for progress."
    }
    else {
        Write-Info "Windows Update was not started."
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
    catch {
        Write-Verbose "Unable to retrieve CPU information"
    }

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
    catch {
        Write-Verbose "Unable to retrieve GPU information"
    }

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
    catch {
        Write-Verbose "Unable to retrieve RAM information"
    }

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
    catch {
        Write-Verbose "Unable to retrieve mainboard information"
    }

    try {
        $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1

        if ($bios.SMBIOSBIOSVersion -and $bios.SMBIOSBIOSVersion.Trim() -ne "") {
            $biosVersion = $bios.SMBIOSBIOSVersion
        }
        elseif ($bios.Version -and $bios.Version.Trim() -ne "") {
            $biosVersion = $bios.Version
        }
    }
    catch {
        Write-Verbose "Unable to retrieve BIOS information"
    }

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
    catch {
        Write-Verbose "Unable to retrieve OS information"
    }

    Write-Host ("{0,-20}: {1}" -f "CPU", $cpu)
    Write-Host ("{0,-20}: {1}" -f "GPU", $gpu)
    Write-Host ("{0,-20}: {1}" -f "Installed RAM", $installedRam)
    Write-Host ("{0,-20}: {1}" -f "RAM Speed", $ramSpeed)
    Write-Host ("{0,-20}: {1}" -f "Mainboard", $mainboardName)
    Write-Host ("{0,-20}: {1}" -f "BIOS Version", $biosVersion)
    Write-Host ("{0,-20}: {1}" -f "OS Version", $osVersion)
    Write-Host ("{0,-20}: {1}" -f "OS Type", $osType)

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

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

    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop |
            Select-Object -ExpandProperty Name |
            Where-Object { $_ -and $_.Trim() -ne "" }

        if ($gpus) {
            # Filter out integrated GPUs and prioritize discrete GPUs
            $integratedPatterns = @('Intel.*Graphics', 'AMD.*Radeon.*Graphics', 'Microsoft.*Hyper-V')
            $dedicatedGpus = @()
            $integratedGpus = @()

            foreach ($gpu in $gpus) {
                $isIntegrated = $false
                foreach ($pattern in $integratedPatterns) {
                    if ($gpu -match $pattern) {
                        $isIntegrated = $true
                        $integratedGpus += $gpu
                        break
                    }
                }

                if (-not $isIntegrated) {
                    $dedicatedGpus += $gpu
                }
            }

            # Prefer dedicated GPU, fallback to integrated
            $selectedGpu = if ($dedicatedGpus.Count -gt 0) { $dedicatedGpus[0] } else { $gpus[0] }

            $selectedGpuLower = $selectedGpu.ToLowerInvariant()

            if ($selectedGpuLower -match 'nvidia') {
                Write-Info "NVIDIA GPU detected: $selectedGpu"
                Write-Info "Opening NVIDIA driver page..."
                Start-Process "https://www.nvidia.com/en-us/drivers/"
                Write-Ok "NVIDIA driver page opened."
                Write-Host ""
                return
            }
            elseif ($selectedGpuLower -match 'amd.*radeon' -and $selectedGpuLower -notmatch 'graphics') {
                Write-Info "AMD Radeon GPU detected: $selectedGpu"
                Write-Info "Opening AMD driver page..."
                Start-Process "https://www.amd.com/en/support/download/drivers.html"
                Write-Ok "AMD driver page opened."
                Write-Host ""
                return
            }
            elseif ($selectedGpuLower -match 'amd') {
                Write-Info "AMD GPU detected: $selectedGpu"
                Write-Info "Opening AMD driver page..."
                Start-Process "https://www.amd.com/en/support/download/drivers.html"
                Write-Ok "AMD driver page opened."
                Write-Host ""
                return
            }
            else {
                Write-WarnMsg "Could not determine GPU vendor from: $selectedGpu"
                Write-Info "Detected GPUs: $($gpus -join ', ')"
                Write-Host ""
            }
        }
        else {
            Write-WarnMsg "No GPUs detected via WMI."
        }
    }
    catch {
        Write-Verbose "Unable to query GPU information via WMI"
    }

    # Fallback to manual selection
    Write-Host ""

    while ($true) {
        $gpuVendor = (Read-Host "Please specify your GPU vendor (NVIDIA/AMD)").Trim().ToLowerInvariant()

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
                Write-Host "Please enter NVIDIA or AMD."
            }
        }
    }
}

function Open-ChipsetsDriverPageIfWanted {
    Write-Host ""
    $openChipsetsPage = Read-YesNo -Prompt "Do you want to open the chipset driver download page"

    if (-not $openChipsetsPage) {
        Write-Info "Chipset driver page was not opened."
        Write-Host ""
        return
    }

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty Name
        $cpuLower = $cpu.ToLowerInvariant()

        if ($cpuLower -match 'intel') {
            Write-Info "Intel CPU detected."
            Write-Info "Opening Intel chipset drivers page..."
            Start-Process "https://www.intel.com/content/www/us/en/download-center/home.html"
            Write-Ok "Intel chipset driver page opened."
            Write-Host ""
            return
        }
        elseif ($cpuLower -match 'amd') {
            Write-Info "AMD CPU detected."
            Write-Info "Opening AMD chipset drivers page..."
            Start-Process "https://www.amd.com/en/support/download/drivers.html"
            Write-Ok "AMD chipset driver page opened."
            Write-Host ""
            return
        }
        else {
            Write-WarnMsg "Could not determine CPU manufacturer from: $cpu"
            Write-Host ""

            while ($true) {
                $cpuVendor = (Read-Host "Please specify your CPU vendor (Intel/AMD)").Trim().ToLowerInvariant()

                switch ($cpuVendor) {
                    'intel' {
                        Write-Info "Opening Intel chipset drivers page..."
                        Start-Process "https://www.intel.com/content/www/us/en/download-center/home.html"
                        Write-Ok "Intel chipset driver page opened."
                        Write-Host ""
                        return
                    }

                    'amd' {
                        Write-Info "Opening AMD chipset drivers page..."
                        Start-Process "https://www.amd.com/en/support/download/drivers.html"
                        Write-Ok "AMD chipset driver page opened."
                        Write-Host ""
                        return
                    }

                    default {
                        Write-Host "Please enter Intel or AMD."
                    }
                }
            }
        }
    }
    catch {
        Write-WarnMsg "Unable to determine CPU information. Please select manually."
        Write-Host ""

        while ($true) {
            $cpuVendor = (Read-Host "Please specify your CPU vendor (Intel/AMD)").Trim().ToLowerInvariant()

            switch ($cpuVendor) {
                'intel' {
                    Write-Info "Opening Intel chipset drivers page..."
                    Start-Process "https://www.intel.com/content/www/us/en/download-center/home.html"
                    Write-Ok "Intel chipset driver page opened."
                    Write-Host ""
                    return
                }

                'amd' {
                    Write-Info "Opening AMD chipset drivers page..."
                    Start-Process "https://www.amd.com/en/support/download/drivers.html"
                    Write-Ok "AMD chipset driver page opened."
                    Write-Host ""
                    return
                }

                default {
                    Write-Host "Please enter Intel or AMD."
                }
            }
        }
    }
}

function Set-XboxGameBarOff {
    Write-Host ""
    $disableGameBar = Read-YesNo -Prompt "Do you want to disable Xbox Game Bar"

    if ($disableGameBar) {
        Write-Info "Disabling Xbox Game Bar..."

        Set-DwordValue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' `
            -Name 'AppCaptureEnabled' `
            -Value 0

        Set-DwordValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' `
            -Name 'AllowGameDVR' `
            -Value 0

        Write-Ok "Xbox Game Bar disabled."
    }
    else {
        Write-Info "Xbox Game Bar settings were not changed."
    }

    Write-Host ""
}

function Set-FullscreenOptimizationsOff {
    Write-Host ""
    $disableFso = Read-YesNo -Prompt "Do you want to disable fullscreen optimizations globally"

    if ($disableFso) {
        Write-Info "Disabling fullscreen optimizations..."

        Set-DwordValue `
            -Path 'HKCU:\System\GameConfigStore' `
            -Name 'GameDVR_FSEBehaviorMode' `
            -Value 2

        Set-DwordValue `
            -Path 'HKCU:\System\GameConfigStore' `
            -Name 'GameDVR_HonorUserFSEBehaviorMode' `
            -Value 1

        Set-DwordValue `
            -Path 'HKCU:\System\GameConfigStore' `
            -Name 'GameDVR_FSEBehavior' `
            -Value 2

        Set-DwordValue `
            -Path 'HKCU:\System\GameConfigStore' `
            -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' `
            -Value 1

        Write-Ok "Fullscreen optimizations disabled."
        Write-WarnMsg "Signing out/in or restarting may be required."
    }
    else {
        Write-Info "Fullscreen optimization settings were not changed."
    }

    Write-Host ""
}

function Set-TimerResolution {
    Write-Host ""
    $setTimer = Read-YesNo -Prompt "Do you want to enable high-precision timer resolution"

    if ($setTimer) {
        Write-Info "Configuring timer resolution..."
        bcdedit /set useplatformtick yes | Out-Null
        bcdedit /set disabledynamictick yes | Out-Null
        Write-Ok "High-precision timer resolution enabled."
        Write-WarnMsg "A restart is required for this change to take effect."
    }
    else {
        Write-Info "Timer resolution was not changed."
    }

    Write-Host ""
}

function Set-MsiModeForGpu {
    Write-Host ""
    $enableMsi = Read-YesNo -Prompt "Do you want to enable MSI mode for your GPU"

    if (-not $enableMsi) {
        Write-Info "MSI mode was not changed."
        Write-Host ""
        return
    }

    Write-Info "Enabling MSI mode for GPU..."

    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop |
            Where-Object { $_.PNPDeviceID -like 'PCI\*' }

        if (-not $gpus) {
            Write-WarnMsg "No PCI GPU found."
            Write-Host ""
            return
        }

        foreach ($gpu in $gpus) {
            $msiPath      = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            $affinityPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.PNPDeviceID)\Device Parameters\Interrupt Management\Affinity Policy"

            Test-RegistryKey -Path $msiPath
            New-ItemProperty -Path $msiPath -Name 'MSISupported' -Value 1 -PropertyType DWord -Force | Out-Null

            Test-RegistryKey -Path $affinityPath
            New-ItemProperty -Path $affinityPath -Name 'DevicePriority' -Value 3 -PropertyType DWord -Force | Out-Null

            Write-Ok "MSI mode enabled for: $($gpu.Name)"
        }

        Write-WarnMsg "A restart is required for MSI mode to take effect."
    }
    catch {
        Write-WarnMsg "Could not enable MSI mode: $_"
    }

    Write-Host ""
}

function Set-FileExtensionsVisible {
    Write-Host ""
    $showExtensions = Read-YesNo -Prompt "Do you want to show file extensions in Explorer"

    if ($showExtensions) {
        Write-Info "Enabling file extensions in Explorer..."

        Set-DwordValue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
            -Name 'HideFileExt' `
            -Value 0

        Write-Ok "File extensions are now visible."
        Write-WarnMsg "Restart Explorer or sign out to apply."
    }
    else {
        Write-Info "File extension settings were not changed."
    }

    Write-Host ""
}

function Set-DarkModeOn {
    Write-Host ""
    $enableDarkMode = Read-YesNo -Prompt "Do you want to enable Dark Mode"

    if ($enableDarkMode) {
        Write-Info "Enabling Dark Mode..."

        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Set-DwordValue -Path $path -Name 'AppsUseLightTheme'    -Value 0
        Set-DwordValue -Path $path -Name 'SystemUsesLightTheme' -Value 0

        Write-Ok "Dark Mode enabled."
    }
    else {
        Write-Info "Dark Mode settings were not changed."
    }

    Write-Host ""
}

function Set-HiddenFilesVisible {
    Write-Host ""
    $showHidden = Read-YesNo -Prompt "Do you want to show hidden files in Explorer"

    if ($showHidden) {
        Write-Info "Enabling hidden files in Explorer..."

        Set-DwordValue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
            -Name 'Hidden' `
            -Value 1

        Write-Ok "Hidden files are now visible."
        Write-WarnMsg "Restart Explorer or sign out to apply."
    }
    else {
        Write-Info "Hidden file settings were not changed."
    }

    Write-Host ""
}

function Set-DnsServers {
    Write-Host ""
    $setDns = Read-YesNo -Prompt "Do you want to set custom DNS servers"

    if (-not $setDns) {
        Write-Info "DNS settings were not changed."
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  1. Cloudflare (1.1.1.1 / 1.0.0.1) - Fast, privacy-focused"
    Write-Host "  2. Google    (8.8.8.8 / 8.8.4.4)  - Reliable, widely used"
    Write-Host ""

    $choice = ""
    while ($choice -ne '1' -and $choice -ne '2') {
        $choice = (Read-Host "  Select DNS provider (1/2)").Trim()
        if ($choice -ne '1' -and $choice -ne '2') {
            Write-Host "  Please enter 1 or 2."
        }
    }

    if ($choice -eq '1') {
        $primary   = '1.1.1.1'
        $secondary = '1.0.0.1'
        $provider  = 'Cloudflare'
    }
    else {
        $primary   = '8.8.8.8'
        $secondary = '8.8.4.4'
        $provider  = 'Google'
    }

    Write-Info "Setting DNS to $provider ($primary / $secondary)..."

    $adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($primary, $secondary)
        Write-Ok "DNS set on: $($adapter.Name)"
    }

    Write-Host ""
}

function Set-NicPowerSavingOff {
    Write-Host ""
    $disableNicPower = Read-YesNo -Prompt "Do you want to disable NIC power saving"

    if (-not $disableNicPower) {
        Write-Info "NIC power saving settings were not changed."
        Write-Host ""
        return
    }

    Write-Info "Disabling NIC power saving..."

    $adapterClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}'
    $count = 0

    Get-ChildItem $adapterClass -ErrorAction SilentlyContinue | ForEach-Object {
        $netCfgId = (Get-ItemProperty $_.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue).NetCfgInstanceId
        if ($netCfgId) {
            New-ItemProperty -Path $_.PSPath -Name 'PnPCapabilities' -Value 24 -PropertyType DWord -Force | Out-Null
            $count++
        }
    }

    Write-Ok "NIC power saving disabled on $count adapter(s)."
    Write-WarnMsg "A restart is required for this change to take effect."

    Write-Host ""
}

function Open-DduPageIfWanted {
    Write-Host ""
    $openDdu = Read-YesNo -Prompt "Do you want to open the DDU (Display Driver Uninstaller) download page"

    if ($openDdu) {
        Write-Info "Opening DDU download page..."
        Start-Process "https://www.guru3d.com/files-details/display-driver-uninstaller-download.html"
        Write-Ok "DDU page opened."
    }
    else {
        Write-Info "DDU page was not opened."
    }

    Write-Host ""
}

function Open-MonitoringToolsIfWanted {
    Write-Host ""
    Write-Info "Monitoring Tools"

    $openHwinfo = Read-YesNo -Prompt "Do you want to open the HWiNFO64 download page"
    if ($openHwinfo) {
        Start-Process "https://www.hwinfo.com/download/"
        Write-Ok "HWiNFO64 page opened."
    }

    $openGpuz = Read-YesNo -Prompt "Do you want to open the GPU-Z download page"
    if ($openGpuz) {
        Start-Process "https://www.techpowerup.com/gpuz/"
        Write-Ok "GPU-Z page opened."
    }

    $openCpuz = Read-YesNo -Prompt "Do you want to open the CPU-Z download page"
    if ($openCpuz) {
        Start-Process "https://www.cpuid.com/softwares/cpu-z.html"
        Write-Ok "CPU-Z page opened."
    }

    Write-Host ""
}

function Open-CrystalDiskMarkIfWanted {
    Write-Host ""
    $openCdm = Read-YesNo -Prompt "Do you want to open the CrystalDiskMark download page"

    if ($openCdm) {
        Write-Info "Opening CrystalDiskMark download page..."
        Start-Process "https://crystalmark.info/en/software/crystaldiskmark/"
        Write-Ok "CrystalDiskMark page opened."
    }
    else {
        Write-Info "CrystalDiskMark page was not opened."
    }

    Write-Host ""
}

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
