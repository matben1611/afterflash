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
        }
    }
    catch {
        Write-WarnMsg "Unable to determine CPU information. Please select manually."
        Write-Host ""
    }

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
        $script:debloaterStarted = $true
        Start-Sleep -Milliseconds 500
        exit
    }
    else {
        Write-Info "Debloater was not started."
    }

    Write-Host ""
}
