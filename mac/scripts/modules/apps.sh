#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# apps.sh — app installation and tool helpers for afterflash-mac
# ---------------------------------------------------------------------------

install_homebrew_if_wanted() {
    echo ""
    if read_yes_no "Do you want to install Homebrew (package manager for macOS)"; then
        if command -v brew &>/dev/null; then
            write_info "Homebrew is already installed."
            write_ok "Homebrew already present."
        else
            write_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            write_ok "Homebrew installation initiated."
        fi
    else
        write_info "Homebrew was not installed."
    fi
    echo ""
}

install_xcode_clt_if_wanted() {
    echo ""
    if read_yes_no "Do you want to install Xcode Command Line Tools"; then
        if xcode-select -p &>/dev/null; then
            write_info "Xcode Command Line Tools are already installed."
            write_ok "Xcode CLT already present."
        else
            write_info "Installing Xcode Command Line Tools..."
            xcode-select --install
            write_ok "Xcode CLT installation initiated. Follow the dialog to complete."
        fi
    else
        write_info "Xcode Command Line Tools were not installed."
    fi
    echo ""
}

open_monitoring_tools_if_wanted() {
    echo ""
    write_info "Monitoring Tools"

    if read_yes_no "Do you want to open Activity Monitor (built-in CPU/Memory/Disk monitor)"; then
        open -a "Activity Monitor" 2>/dev/null && write_ok "Activity Monitor opened." \
            || write_warn "Activity Monitor could not be opened."
    fi

    if read_yes_no "Do you want to open the iStat Menus website (comprehensive system monitor)"; then
        open "https://bjango.com/mac/istatmenus/" 2>/dev/null
        write_ok "iStat Menus page opened."
    fi

    if read_yes_no "Do you want to open GPU Monitor Lite in the App Store"; then
        open "macappstore://apps.apple.com/app/gpu-monitor-lite/id1195299957" 2>/dev/null
        write_ok "GPU Monitor Lite page opened."
    fi

    echo ""
}

open_disk_tools_if_wanted() {
    echo ""
    write_info "Disk Tools"

    if read_yes_no "Do you want to open Disk Utility (check disk health and S.M.A.R.T. status)"; then
        open -a "Disk Utility" 2>/dev/null && write_ok "Disk Utility opened." \
            || write_warn "Disk Utility could not be opened."
    fi

    if read_yes_no "Do you want to open Blackmagic Disk Speed Test in the App Store"; then
        open "macappstore://apps.apple.com/app/blackmagic-disk-speed-test/id425264550" 2>/dev/null
        write_ok "Blackmagic Disk Speed Test page opened."
    fi

    echo ""
}

run_macos_updates_if_wanted() {
    echo ""
    if read_yes_no "Do you want to check for macOS software updates"; then
        write_info "Checking for available updates..."
        softwareupdate --list 2>&1 | tail -20

        if read_yes_no "Do you want to install all available updates now"; then
            write_info "Installing updates (this may take a while)..."
            if is_root; then
                softwareupdate --install --all
                write_ok "Software updates installed."
            else
                write_warn "Requires sudo — run manually: sudo softwareupdate --install --all"
            fi
        fi
    else
        write_info "macOS updates were not checked."
    fi
    echo ""
}

run_cleanup_if_wanted() {
    echo ""
    if read_yes_no "Do you want to clean Homebrew cache and remove unused dependencies"; then
        if command -v brew &>/dev/null; then
            write_info "Running Homebrew cleanup..."
            brew cleanup
            brew autoremove
            write_ok "Homebrew cache cleaned."
        else
            write_warn "Homebrew is not installed — skipping cleanup."
        fi
    else
        write_info "Cleanup was not performed."
    fi
    echo ""
}
