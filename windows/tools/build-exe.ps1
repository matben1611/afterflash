[CmdletBinding()]
param(
    [switch]$Force
)

try {
    $ErrorActionPreference = 'Stop'

    $toolsDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $root     = Split-Path -Parent $toolsDir      # windows/
    $repoRoot = Split-Path -Parent $root           # repo root

    $batFile     = Join-Path $root     'afterflash-standalone.bat'
    $pngFile     = Join-Path $repoRoot 'assets\afterflash.png'
    $versionFile = Join-Path $repoRoot 'VERSION'
    $ps1File     = Join-Path $root     'afterflash-standalone.ps1'
    $icoFile     = Join-Path $root     'afterflash.ico'
    # --- 0. Read version ---
    if (-not (Test-Path $versionFile)) {
        throw "VERSION file not found at $versionFile"
    }
    $version = (Get-Content $versionFile -Raw).Trim()
    $exeFile = Join-Path $repoRoot "afterflash-$version.exe"
    Write-Host "Version: $version"
    Write-Host ""

    # --- 1. Check if rebuild is needed ---
    if (-not $Force -and (Test-Path $exeFile)) {
        $batTime = (Get-Item $batFile).LastWriteTime
        $exeTime = (Get-Item $exeFile).LastWriteTime

        if ($exeTime -ge $batTime) {
            Write-Host "EXE is up to date (bat: $($batTime.ToString('yyyy-MM-dd HH:mm:ss')), exe: $($exeTime.ToString('yyyy-MM-dd HH:mm:ss')))"
            Write-Host "Use -Force to rebuild anyway."
            return
        }

        Write-Host "BAT is newer than EXE - rebuilding..."
        Write-Host ""
    }

    # --- 2. Check if exe is locked ---
    if (Test-Path $exeFile) {
        try {
            $stream = [System.IO.File]::Open($exeFile, 'Open', 'ReadWrite', 'None')
            $stream.Close()
        } catch {
            throw "afterflash.exe is still running. Close it first, then try again."
        }
    }

    # --- 3. Extract PS code from bat ---
    Write-Host "[1/4] Extracting PowerShell code from bat..."
    $lines = Get-Content $batFile
    $startIndex = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##PSBEGIN##') {
            $startIndex = $i + 1
            break
        }
    }
    if ($null -eq $startIndex) {
        throw "##PSBEGIN## marker not found in $batFile"
    }
    $psContent = $lines[$startIndex..($lines.Count - 1)] -join "`r`n"
    Set-Content -Path $ps1File -Value $psContent -Encoding UTF8
    Write-Host "    -> $ps1File"

    # --- 4. Convert PNG to ICO ---
    Write-Host "[2/4] Converting PNG to ICO..."
    Add-Type -AssemblyName System.Drawing

    $bitmap  = [System.Drawing.Bitmap]::new($pngFile)
    $resized = [System.Drawing.Bitmap]::new($bitmap, [System.Drawing.Size]::new(256, 256))

    $ms = [System.IO.MemoryStream]::new()
    $resized.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $ms.ToArray()
    $ms.Dispose()
    $resized.Dispose()
    $bitmap.Dispose()

    # Write a valid ICO file (Vista+ format with embedded PNG)
    $fs = [System.IO.FileStream]::new($icoFile, [System.IO.FileMode]::Create)
    $bw = [System.IO.BinaryWriter]::new($fs)
    $bw.Write([uint16]0)                      # Reserved
    $bw.Write([uint16]1)                      # Type: ICO
    $bw.Write([uint16]1)                      # Image count
    $bw.Write([byte]0)                        # Width  (0 = 256)
    $bw.Write([byte]0)                        # Height (0 = 256)
    $bw.Write([byte]0)                        # ColorCount
    $bw.Write([byte]0)                        # Reserved
    $bw.Write([uint16]1)                      # Planes
    $bw.Write([uint16]32)                     # BitCount
    $bw.Write([uint32]$pngBytes.Length)       # Image size
    $bw.Write([uint32]22)                     # Offset (6 header + 16 entry)
    $bw.Write($pngBytes)
    $bw.Dispose()
    $fs.Dispose()

    Write-Host "    -> $icoFile"

    # --- 5. Install PS2EXE if needed ---
    Write-Host "[3/4] Checking PS2EXE..."
    if (-not (Get-Module -ListAvailable -Name PS2EXE)) {
        Write-Host "    PS2EXE not found, installing..."
        Install-Module PS2EXE -Scope CurrentUser -Force
    }
    Import-Module PS2EXE

    # --- 6. Compile to EXE ---
    Write-Host "[4/4] Compiling to EXE..."
    Invoke-PS2EXE `
        -InputFile    $ps1File `
        -OutputFile   $exeFile `
        -iconFile     $icoFile `
        -title        'afterflash' `
        -description  'Windows Setup & Optimizer' `
        -version      $version `
        -requireAdmin `
        -verbose

    # --- Cleanup temp files ---
    Remove-Item -Path $ps1File -ErrorAction SilentlyContinue
    Remove-Item -Path $icoFile -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "Done: $exeFile ($version)"
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
}
finally {
    Read-Host "`nPress Enter to exit..."
}
