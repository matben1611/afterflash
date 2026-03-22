<!-- markdownlint-disable MD033 -->

# afterflash

<p align="center">
  <img src="afterflash.png" alt="afterflash.png" width="500">
</p>

Windows PowerShell setup script for quickly applying post-build system tweaks,
performance settings, and optional debloat actions on a fresh PC. Built out of
my personal interest in PC building and optimization, with the goal of saving
time and reducing repetitive setup work after each build.

This serves as a personal documentation base for my own builds and related
projects, and I plan to continue expanding it over time.

## Windows Post-Build Setup Script

A PowerShell-based post-build setup script for freshly installed
Windows systems.

This project automates a small set of useful Windows configuration
changes after building or setting up a PC.  
It is designed to be simple, interactive, and easy to extend without
requiring a graphical user interface.

The script currently focuses on a few performance-related and
quality-of-life settings, optional prompts for selected features, and
the ability to launch an external debloater at the end.

## Overview

After a fresh Windows installation, many users manually change the same
settings over and over again. This script helps reduce that repetitive work
by applying predefined system changes through PowerShell.

**System Information**

- Overview of CPU, GPU, RAM, mainboard, BIOS version and OS

**Driver Downloads**

- GPU driver page for AMD or NVIDIA (auto-detected)
- Chipset driver page for Intel or AMD (auto-detected)

**Performance** *(applied with confirmation)*

- Hardware-Accelerated GPU Scheduling: **On**
- Variable Refresh Rate: **Off**
- Game Mode: **Off**
- Mouse Acceleration: **Off**
- Balanced Power Plan for **X3D CPUs**

**Privacy** *(applied with confirmation)*

- Optional diagnostic data: **disabled**
- Delivery Optimization P2P: **disabled**

**Optional**

- System Protection (restore points) on C:
- Clipboard History
- Do Not Disturb / Notifications
- BIOS recommendations file on the Desktop

**Tools**

- [Ninite](https://ninite.com/) for bulk app installation
- [Win11Debloat](https://github.com/Raphire/Win11Debloat) integration
- Verification script to manually check applied settings

The script is intentionally interactive for selected settings so the
user can decide case by case during execution.

## Goals

This project aims to provide:

- A quick post-build configuration workflow
- A lightweight portable PowerShell-based solution without a GUI
- A simple foundation that can be expanded over time
- A tool to get the maximum performance out of your expensive hardware

### If PowerShell says the script is not digitally signed

Run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File
```

## Quick Start

1. **Clone or download** this repository to your PC
2. **Open PowerShell** (no admin required, script will prompt for elevation)
3. **Navigate** to the repository directory
4. **Run** the setup script:

```powershell
.\scripts\setup.ps1
```

The script will guide you through each configuration step with interactive
prompts for optional settings.

## Requirements

- **Windows 10** or **Windows 11**
- **PowerShell 5.0+** (comes pre-installed on Windows 10/11)
- **Administrator privileges** (script will request elevation)

## Usage

### Main Setup Script

Run the main optimization script:

```powershell
.\scripts\setup.ps1
```

### Verification Script

After running the setup, use the verification script to manually check
that all settings were applied correctly:

```powershell
.\scripts\verify.ps1
```

This script opens relevant Windows settings pages without making changes.

## Development

### Running Tests

All linting and testing commands for local development:

#### 1. Pester Unit Tests

Tests are written with [Pester 5.7.1](https://pester.dev/):

```powershell
Remove-Module Pester -Force -ErrorAction SilentlyContinue
Invoke-Pester -Path ./tests -Output Detailed
```

#### 2. PSScriptAnalyzer Code Analysis

Code quality and PowerShell best practices:

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./scripts/PSScriptAnalyzerSettings.psd1
```

#### 3. Markdown Linting

Documentation formatting and consistency (requires Node.js/npm):

```powershell
npm install -g markdownlint-cli
markdownlint -c .markdownlint.json .
```

#### Run All Tests

Run all three checks at once:

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./scripts/PSScriptAnalyzerSettings.psd1; `
Remove-Module Pester -Force -ErrorAction SilentlyContinue; `
Invoke-Pester -Path ./tests -Output Detailed; `
markdownlint -c .markdownlint.json .
```

### Code Analysis

The project uses PSScriptAnalyzer for code quality:

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse `
  -Settings ./scripts/PSScriptAnalyzerSettings.psd1
```

## License

This project is licensed under the
[MIT License](LICENSE) - see the LICENSE file for details.

## Acknowledgments

- **Win11Debloat** by Raphire for debloating functionality
- **Ninite** for bulk application installation support
- Community feedback and contributions

## Features

### Automatic elevation

The script automatically checks whether it is running with
administrator privileges. If not, it relaunches itself as
Administrator.

### Interactive prompts

Some settings are not forced automatically and instead ask the user
for confirmation, for example:

- X3D CPU power plan handling
- System Protection
- Clipboard History
- Do Not Disturb configuration
- Debloater launch

### Clean terminal output

The script prints structured status messages to show what is
happening during execution.

## Included settings

### Applied automatically

These settings are applied without additional confirmation:

- Hardware-Accelerated GPU Scheduling = **On**
- Variable Refresh Rate = **Off**
- Game Mode = **Off**
- Mouse acceleration = **Off**
- Optional diagnostic data = **Reduced / Required only**
- Delivery Optimization = **HTTP only / peer-to-peer disabled**

### Applied conditionally

These settings depend on user input:

- Power plan = **Balanced** if the user confirms an X3D CPU is installed
- System Protection = optional
- Clipboard History = optional
- Do Not Disturb = optional manual configuration prompt
- Debloater launch = optional

## External Tool Integration

At the end of the setup process, this project can optionally launch
**Win11Debloat** by **Raphire**.

Win11Debloat is a lightweight PowerShell project for decluttering and
customizing Windows. According to its repository, it can remove
pre-installed apps, disable telemetry, remove intrusive interface
elements, and perform other Windows customization changes. It supports
both **Windows 10** and **Windows 11**.

In this project, Win11Debloat is not bundled directly. Instead, it is
started optionally through its official quick-launch command:

## Win11Debloat

```powershell
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
```

## Ninite

[Ninite](https://ninite.com/) is not bundled with this repository.
If selected by the user, the script opens the official website in
the browser.

## BIOS Change Disclaimer

> [!CAUTION]
> **Do not change BIOS settings unless you understand what they do
> and are willing to test system stability properly afterward.**
>
> **If you are unsure, stay close to stock settings or only apply
> conservative changes.**  
> **Make adjustments step by step and verify stability after every
> change.**
>
> **This project does not apply BIOS settings automatically.**  
> **It only provides recommendations for manual review.**
>
> **You are fully responsible for any BIOS changes you make.**

The BIOS recommendations referenced by this project are general
baseline suggestions only.

They are **not universal safe settings** and should not be applied
blindly. BIOS behavior can vary significantly depending on:

- motherboard vendor and BIOS version
- CPU model
- memory kit
- cooling solution
- overall system stability

This is especially important for settings such as:

- **EXPO / XMP**
- **PBO**
- **Curve Optimizer**
- **Memory Context Restore**
- **fan curves**
- **disabling the iGPU**
- **storage and boot-related options**
- **Resizable BAR**
- **Secure Boot**
- **TPM / fTPM**

Some of these changes can improve performance, boot times,
temperatures, or noise levels, but they can also introduce:

- failed boots
- random crashes
- WHEA errors
- memory instability
- game instability
- sleep / idle instability
- rare data corruption
