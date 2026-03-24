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
