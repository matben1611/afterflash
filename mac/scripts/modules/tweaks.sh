#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# tweaks.sh — system tweaks for afterflash-mac
# ---------------------------------------------------------------------------

# ── Performance ─────────────────────────────────────────────────────────────

set_animations_off() {
    echo ""
    if read_yes_no "Do you want to disable window opening/closing animations"; then
        write_info "Disabling window animations..."
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
        write_ok "Window animations disabled."
        write_warn "Log out and back in to apply."
    else
        write_info "Window animation settings were not changed."
    fi
    echo ""
}

set_transparency_off() {
    echo ""
    if read_yes_no "Do you want to reduce transparency (improves performance on older Macs)"; then
        write_info "Reducing transparency..."
        defaults write com.apple.universalaccess reduceTransparency -bool true
        write_ok "Transparency reduced."
        write_warn "Log out and back in to apply."
    else
        write_info "Transparency settings were not changed."
    fi
    echo ""
}

set_reduce_motion() {
    echo ""
    if read_yes_no "Do you want to enable Reduce Motion (disables parallax and dock animations)"; then
        write_info "Enabling Reduce Motion..."
        defaults write com.apple.universalaccess reduceMotion -bool true
        write_ok "Reduce Motion enabled."
        write_warn "Log out and back in to apply."
    else
        write_info "Reduce Motion settings were not changed."
    fi
    echo ""
}

set_app_nap_off() {
    echo ""
    if read_yes_no "Do you want to disable App Nap (prevents background apps from throttling)"; then
        write_info "Disabling App Nap..."
        defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
        write_ok "App Nap disabled."
    else
        write_info "App Nap settings were not changed."
    fi
    echo ""
}

set_key_repeat_fast() {
    echo ""
    if read_yes_no "Do you want to set fast key repeat (better for typing and coding)"; then
        write_info "Setting fast key repeat..."
        defaults write NSGlobalDomain KeyRepeat -int 1
        defaults write NSGlobalDomain InitialKeyRepeat -int 15
        write_ok "Key repeat set to fast."
        write_warn "Log out and back in to apply."
    else
        write_info "Key repeat settings were not changed."
    fi
    echo ""
}

set_mouse_acceleration_off() {
    echo ""
    if read_yes_no "Do you want to disable mouse acceleration"; then
        write_info "Disabling mouse acceleration..."
        defaults write .GlobalPreferences com.apple.mouse.scaling -1
        write_ok "Mouse acceleration disabled."
        write_warn "Log out and back in to apply."
    else
        write_info "Mouse acceleration settings were not changed."
    fi
    echo ""
}

# ── UI ───────────────────────────────────────────────────────────────────────

set_dark_mode() {
    echo ""
    if read_yes_no "Do you want to enable Dark Mode"; then
        write_info "Enabling Dark Mode..."
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null
        write_ok "Dark Mode enabled."
    else
        write_info "Dark Mode settings were not changed."
    fi
    echo ""
}

set_file_extensions_visible() {
    echo ""
    if read_yes_no "Do you want to show file extensions in Finder"; then
        write_info "Enabling file extensions in Finder..."
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true
        killall Finder 2>/dev/null || true
        write_ok "File extensions are now visible."
    else
        write_info "File extension settings were not changed."
    fi
    echo ""
}

set_hidden_files_visible() {
    echo ""
    if read_yes_no "Do you want to show hidden files in Finder"; then
        write_info "Enabling hidden files in Finder..."
        defaults write com.apple.finder AppleShowAllFiles -bool true
        killall Finder 2>/dev/null || true
        write_ok "Hidden files are now visible."
    else
        write_info "Hidden file settings were not changed."
    fi
    echo ""
}

set_dock_autohide() {
    echo ""
    if read_yes_no "Do you want to enable Dock auto-hide"; then
        write_info "Enabling Dock auto-hide..."
        defaults write com.apple.dock autohide -bool true
        killall Dock 2>/dev/null || true
        write_ok "Dock auto-hide enabled."
    else
        write_info "Dock auto-hide settings were not changed."
    fi
    echo ""
}

set_dock_animation_fast() {
    echo ""
    if read_yes_no "Do you want to speed up the Dock show/hide animation"; then
        write_info "Speeding up Dock animation..."
        defaults write com.apple.dock autohide-time-modifier -float 0.3
        defaults write com.apple.dock autohide-delay -float 0
        killall Dock 2>/dev/null || true
        write_ok "Dock animation speed increased."
    else
        write_info "Dock animation settings were not changed."
    fi
    echo ""
}

set_finder_statusbar() {
    echo ""
    if read_yes_no "Do you want to show the Finder status bar and path bar"; then
        write_info "Enabling Finder status bar and path bar..."
        defaults write com.apple.finder ShowStatusBar -bool true
        defaults write com.apple.finder ShowPathbar -bool true
        killall Finder 2>/dev/null || true
        write_ok "Finder status bar and path bar enabled."
    else
        write_info "Finder status bar settings were not changed."
    fi
    echo ""
}

set_screenshot_location() {
    echo ""
    if read_yes_no "Do you want to change the screenshot save location to ~/Pictures/Screenshots"; then
        local dir="$HOME/Pictures/Screenshots"
        write_info "Setting screenshot location to $dir..."
        mkdir -p "$dir"
        defaults write com.apple.screencapture location "$dir"
        write_ok "Screenshot location set to $dir."
        write_warn "Log out and back in to apply."
    else
        write_info "Screenshot location was not changed."
    fi
    echo ""
}

set_screenshot_format_jpg() {
    echo ""
    if read_yes_no "Do you want to set screenshot format to JPG (smaller file size than PNG)"; then
        write_info "Setting screenshot format to JPG..."
        defaults write com.apple.screencapture type jpg
        write_ok "Screenshot format set to JPG."
    else
        write_info "Screenshot format was not changed."
    fi
    echo ""
}

# ── Privacy ──────────────────────────────────────────────────────────────────

set_analytics_off() {
    echo ""
    if read_yes_no "Do you want to disable sending crash reports and analytics to Apple"; then
        write_info "Disabling analytics and crash reporter dialog..."
        defaults write com.apple.CrashReporter DialogType none
        write_ok "Crash reporter dialog and analytics disabled."
    else
        write_info "Analytics settings were not changed."
    fi
    echo ""
}

set_siri_suggestions_off() {
    echo ""
    if read_yes_no "Do you want to disable Siri suggestions in Spotlight"; then
        write_info "Disabling Siri suggestions in Spotlight..."
        defaults write com.apple.assistant.support 'Siri Data Sharing Opt-In Status' -int 2
        defaults write com.apple.Spotlight orderedItems -array \
            '{"enabled" = 1;"name" = "APPLICATIONS";}' \
            '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
            '{"enabled" = 1;"name" = "DIRECTORIES";}' \
            '{"enabled" = 1;"name" = "PDF";}' \
            '{"enabled" = 1;"name" = "DOCUMENTS";}' \
            '{"enabled" = 0;"name" = "FONTS";}' \
            '{"enabled" = 1;"name" = "MESSAGES";}' \
            '{"enabled" = 0;"name" = "CONTACT";}' \
            '{"enabled" = 0;"name" = "EVENT_TODO";}' \
            '{"enabled" = 0;"name" = "IMAGES";}' \
            '{"enabled" = 0;"name" = "BOOKMARKS";}' \
            '{"enabled" = 0;"name" = "MUSIC";}' \
            '{"enabled" = 0;"name" = "MOVIES";}' \
            '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
            '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
            '{"enabled" = 0;"name" = "SOURCE";}' \
            '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
            '{"enabled" = 0;"name" = "MENU_OTHER";}' \
            '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
            '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
            '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
        write_ok "Siri suggestions in Spotlight disabled."
    else
        write_info "Siri suggestion settings were not changed."
    fi
    echo ""
}

# ── Network ──────────────────────────────────────────────────────────────────

set_dns_servers() {
    echo ""
    if read_yes_no "Do you want to set custom DNS servers"; then
        echo ""
        echo "  1. Cloudflare (1.1.1.1 / 1.0.0.1) - Fast, privacy-focused"
        echo "  2. Google    (8.8.8.8 / 8.8.4.4)  - Reliable, widely used"
        echo ""

        local choice=""
        if [[ "${QUICK_SETUP:-false}" == "true" ]]; then
            choice="1"
        else
            while [[ "$choice" != "1" && "$choice" != "2" ]]; do
                printf "  Select DNS provider (1/2): "
                read -r choice
                if [[ "$choice" != "1" && "$choice" != "2" ]]; then
                    echo "  Please enter 1 or 2."
                fi
            done
        fi

        local primary secondary provider
        if [[ "$choice" == "1" ]]; then
            primary="1.1.1.1"; secondary="1.0.0.1"; provider="Cloudflare"
        else
            primary="8.8.8.8"; secondary="8.8.4.4"; provider="Google"
        fi

        write_info "Setting DNS to $provider ($primary / $secondary)..."

        while IFS= read -r service; do
            [[ -z "$service" ]] && continue
            networksetup -setdnsservers "$service" "$primary" "$secondary" 2>/dev/null \
                && write_ok "DNS set on: $service" || true
        done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)

        dscacheutil -flushcache 2>/dev/null || true
        killall -HUP mDNSResponder 2>/dev/null || true
        write_ok "DNS cache flushed."
    else
        write_info "DNS settings were not changed."
    fi
    echo ""
}

set_wifi_power_saving_off() {
    echo ""
    if read_yes_no "Do you want to disable Wi-Fi power saving (recommended for desktops)"; then
        write_info "Disabling Wi-Fi power saving..."
        if is_root; then
            pmset -a womp 0 2>/dev/null || true
            write_ok "Wi-Fi power saving disabled."
        else
            write_warn "Requires sudo — run manually: sudo pmset -a womp 0"
        fi
    else
        write_info "Wi-Fi power saving settings were not changed."
    fi
    echo ""
}

# ── Power / Sleep ─────────────────────────────────────────────────────────────

set_sleep_settings() {
    echo ""
    if read_yes_no "Do you want to configure sleep (display sleep: 15 min, system: never)"; then
        write_info "Configuring sleep settings..."
        if is_root; then
            pmset -a displaysleep 15 2>/dev/null || true
            pmset -a sleep 0 2>/dev/null || true
            write_ok "Display sleep: 15 min, System sleep: disabled."
        else
            write_warn "Requires sudo — run manually: sudo pmset -a displaysleep 15 sleep 0"
        fi
    else
        write_info "Sleep settings were not changed."
    fi
    echo ""
}

set_screensaver_off() {
    echo ""
    if read_yes_no "Do you want to disable the screensaver"; then
        write_info "Disabling screensaver..."
        defaults -currentHost write com.apple.screensaver idleTime 0
        write_ok "Screensaver disabled."
    else
        write_info "Screensaver settings were not changed."
    fi
    echo ""
}
