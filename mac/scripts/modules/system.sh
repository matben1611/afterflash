#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# system.sh — system information and tips file for afterflash-mac
# ---------------------------------------------------------------------------

show_system_information() {
    echo ""
    echo "========================================"
    echo "         System Information             "
    echo "========================================"
    echo ""

    local cpu gpu ram_gb macos_name macos_version arch

    cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    gpu=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | awk -F': ' '/Chipset Model/{print $2; exit}' || echo "Unknown")
    local ram_bytes
    ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    ram_gb=$(( ram_bytes / 1073741824 ))
    macos_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
    macos_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    arch=$(uname -m)

    printf '%-20s: %s\n'    "CPU"          "$cpu"
    printf '%-20s: %s\n'    "GPU"          "${gpu:-Unknown}"
    printf '%-20s: %s GB\n' "RAM"          "$ram_gb"
    printf '%-20s: %s %s\n' "macOS"        "$macos_name" "$macos_version"
    printf '%-20s: %s\n'    "Architecture" "$arch"

    echo ""
    echo "========================================"
    echo "========================================"
    echo ""
}

create_mac_tips_file_if_wanted() {
    echo ""
    if read_yes_no "Do you want to create a Mac optimization tips file on the Desktop"; then
        local desktop="$HOME/Desktop"
        local filepath="$desktop/mac-tips.txt"

        local cpu macos_name macos_version timestamp
        cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
        macos_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
        macos_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        cat > "$filepath" << EOF
=================================================================================
                           SYSTEM INFORMATION
=================================================================================
CPU:         $cpu
macOS:       $macos_name $macos_version
Generated:   $timestamp
=================================================================================


MAC OPTIMIZATION TIPS
-------------------------------------------------------------------------------

[ENERGY SAVER / BATTERY SETTINGS]
  System Settings > Battery > Options
  - Disable "Enable Power Nap" if you don't need background syncing
  - Set display sleep timers to your preference

  For desktops: Set energy saver to "Never" sleep if needed for server use.

[STARTUP ITEMS]
  System Settings > General > Login Items
  - Review and remove apps you don't need at startup
  - Reduces boot time and background resource usage

[SPOTLIGHT INDEXING]
  System Settings > Siri & Spotlight > Spotlight Privacy
  - Exclude large folders (VMs, archives, node_modules) from indexing
  - Reduces CPU/disk usage after major file operations

[SSD TRIM]
  Third-party SSDs may need TRIM enabled:
    sudo trimforce enable
  Apple SSDs handle this automatically.

[MEMORY PRESSURE]
  Open Activity Monitor > Memory tab
  - Check Memory Pressure graph (green = good, yellow/red = upgrade RAM)
  - Sort by Memory to find heavy processes

[STORAGE MANAGEMENT]
  Apple Menu > About This Mac > More Info > Storage Settings
  - Use "Optimize Storage" to offload unused content to iCloud
  - Regularly empty Trash to reclaim space

[THERMAL MANAGEMENT]
  macOS manages thermals automatically.
  Useful monitoring tools:
  - iStat Menus: Comprehensive system monitor (paid)
  - Activity Monitor (built-in): CPU/Memory/Disk/Network

[SECURITY]
  System Settings > Privacy & Security
  - FileVault: ENABLE (encrypts entire disk - critical for laptops)
  - Firewall: ENABLE
  - Gatekeeper: Keep on "App Store and identified developers"

[DEVELOPER TOOLS]
  Install Homebrew for package management:
    /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  Install Xcode Command Line Tools:
    xcode-select --install

[DISPLAY]
  System Settings > Displays
  - Enable "True Tone" for better color accuracy
  - Set resolution to "Default for display" unless you need HiDPI scaling
  - For external displays: verify refresh rate is set to maximum

[ACCESSIBILITY - PERFORMANCE]
  System Settings > Accessibility > Display
  - "Reduce Motion": ON  (disables parallax and heavy animations)
  - "Reduce Transparency": ON  (improves performance on older Macs)


GOOD TO KNOW
-------------------------------------------------------------------------------
* SMC Reset: Only for Intel Macs — power/thermal issues
* NVRAM/PRAM Reset: Clears display res, startup disk, time zone
* Safe Mode: Boot holding Shift — runs disk check, disables login items
* Recovery Mode: Cmd+R (Intel) or hold Power button (Apple Silicon)

Good luck!
EOF

        write_ok "Mac tips file created: $filepath"
    else
        write_info "Mac tips file was not created."
    fi
    echo ""
}
