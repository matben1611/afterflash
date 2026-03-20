<p align="center">
  <img src="afterflash.png" alt="afterflash.png" width="500">
</p>

# afterflash
Windows PowerShell setup script for quickly applying post-build system tweaks, performance settings, and optional debloat actions on a fresh PC. Built out of my personal interest in PC building and optimization, with the goal of saving time and reducing repetitive setup work after each build.

# Windows Post-Build Setup Script

A PowerShell-based post-build setup script for freshly installed Windows systems.

This project automates a small set of useful Windows configuration changes after building or setting up a PC.  
It is designed to be simple, interactive, and easy to extend without requiring a graphical user interface.

The script currently focuses on a few performance-related and quality-of-life settings, optional prompts for selected features, and the ability to launch an external debloater at the end.

---

## Overview

After a fresh Windows installation, many users manually change the same settings over and over again.  
This script helps reduce that repetitive work by applying predefined system changes through PowerShell.

The current implementation includes:

- Enabling **Hardware-Accelerated GPU Scheduling**
- Disabling **Variable Refresh Rate**
- Disabling **Game Mode**
- Setting **Balanced Power Mode** if an **X3D CPU** is installed
- Disabling **mouse acceleration**
- Disabling **optional diagnostic data**
- Restricting **Delivery Optimization**
- Optional prompt to enable **System Protection**
- Optional prompt to enable **Clipboard History**
- Optional prompt to open **Do Not Disturb / Notifications settings**
- Optional creation of a **BIOS recommendations text file** on the desktop
- Optional prompt to open **Ninite** for bulk app installation
- Optional prompt to launch the **Raphire Debloater**
- A separate **verification script** for manually checking applied settings through the relevant Windows pages

The script is intentionally interactive for selected settings so the user can decide case by case during execution.

The script is intentionally interactive for selected settings so the user can decide case by case during execution.

---

## Goals

This project aims to provide:

- A quick post-build configuration workflow
- A lightweight PowerShell-based solution without a GUI
- A simple foundation that can be expanded over time
- A more user-friendly setup experience through prompts and automatic elevation

---

### If PowerShell says the script is not digitally signed

Run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File
```


## Features

### Automatic elevation
The script automatically checks whether it is running with administrator privileges.  
If not, it relaunches itself as Administrator.

### Interactive prompts
Some settings are not forced automatically and instead ask the user for confirmation, for example:

- X3D CPU power plan handling
- System Protection
- Clipboard History
- Do Not Disturb configuration
- Debloater launch

### Clean terminal output
The script prints structured status messages to show what is happening during execution.

---

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

---

## External Tool Integration

At the end of the setup process, this project can optionally launch **Win11Debloat** by **Raphire**.

Win11Debloat is a lightweight PowerShell project for decluttering and customizing Windows. According to its repository, it can remove pre-installed apps, disable telemetry, remove intrusive interface elements, and perform other Windows customization changes. It supports both **Windows 10** and **Windows 11**. :contentReference[oaicite:0]{index=0}

In this project, Win11Debloat is not bundled directly.  
Instead, it is started optionally through its official quick-launch command:

```powershell
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
```
Ninite is not bundled with this repository.  
If selected by the user, the script simply opens the official website in the browser:

## BIOS Change Disclaimer

The BIOS recommendations referenced by this project are general baseline suggestions only.

They are **not universal safe settings** and should not be applied blindly.  
BIOS behavior can vary significantly depending on:

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

Some of these changes can improve performance, boot times, temperatures, or noise levels, but they can also introduce:

- failed boots
- random crashes
- WHEA errors
- memory instability
- game instability
- sleep / idle instability
- rare data corruption

Do not change BIOS settings unless you understand what they do and are willing to test system stability properly afterward.

If you are unsure, stay close to stock settings or only apply conservative changes.  
Make adjustments step by step and verify stability after every change.

This project does **not** apply BIOS settings automatically.  
It only provides recommendations for manual review.

You are fully responsible for any BIOS changes you make.
