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

function Set-BiosRecommendationsFileIfWanted {
    Write-Host ""
    $createBiosFile = Read-YesNo -Prompt "Do you want to create a BIOS recommendations file on the desktop"

    if ($createBiosFile) {
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $filePath = Join-Path $desktopPath 'bios-recommendations.txt'

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
