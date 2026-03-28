#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

source "$MODULES_DIR/helpers.sh"
source "$MODULES_DIR/system.sh"
source "$MODULES_DIR/tweaks.sh"
source "$MODULES_DIR/apps.sh"

# ── Globals ──────────────────────────────────────────────────────────────────

QUICK_SETUP=false
CURRENT_STEP=0
TOTAL_STEPS=27
CURRENT_STEP_APPLIED=false
REPORT=()
LOG_FILE="/tmp/afterflash-mac-$(date '+%Y%m%d-%H%M%S').log"

# ── Orchestration ─────────────────────────────────────────────────────────────

invoke_step() {
    local label="$1"
    local func="$2"
    local skip_in_quick="${3:-false}"

    CURRENT_STEP=$(( CURRENT_STEP + 1 ))
    CURRENT_STEP_APPLIED=false

    if [[ "$QUICK_SETUP" == "true" ]]; then
        if [[ "$skip_in_quick" != "true" ]]; then
            "$func" || true
            if [[ "$CURRENT_STEP_APPLIED" == "true" ]]; then
                REPORT+=("$label")
            fi
        fi
        return
    fi

    echo "  [$CURRENT_STEP/$TOTAL_STEPS] $label"
    "$func" || true
    if [[ "$CURRENT_STEP_APPLIED" == "true" ]]; then
        REPORT+=("$label")
    fi
    wait_a_bit
}

show_report() {
    if [[ ${#REPORT[@]} -eq 0 ]]; then return; fi

    echo ""
    echo "========================================"
    echo "          Changes Applied               "
    echo "========================================"
    for entry in "${REPORT[@]}"; do
        echo "  [+] $entry"
    done
    echo "========================================"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

{
    echo "afterflash-mac log - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
} > "$LOG_FILE"

clear

echo ""
echo "========================================"
echo "          Mac Setup Starting            "
echo "========================================"
echo ""

wait_a_bit

echo ""
write_typewriter "  Scanning system hardware..." 0.04
sleep 0.4

show_system_information

wait_a_bit

echo ""
if read_yes_no "Do you want to use Quick Setup (applies all tweaks automatically)"; then
    QUICK_SETUP=true
fi
echo ""

if [[ "$QUICK_SETUP" == "true" ]]; then
    echo "  Applying all tweaks..."
    echo ""
fi

#                  Label                      Function                       Skip in Quick
invoke_step        'Mac Tips File'            create_mac_tips_file_if_wanted true
invoke_step        'Homebrew'                 install_homebrew_if_wanted     true
invoke_step        'Xcode CLT'               install_xcode_clt_if_wanted    true
invoke_step        'Window Animations'       set_animations_off
invoke_step        'Transparency'            set_transparency_off
invoke_step        'Reduce Motion'           set_reduce_motion
invoke_step        'App Nap'                 set_app_nap_off
invoke_step        'Key Repeat'              set_key_repeat_fast
invoke_step        'Mouse Acceleration'      set_mouse_acceleration_off
invoke_step        'Dark Mode'               set_dark_mode
invoke_step        'File Extensions'         set_file_extensions_visible
invoke_step        'Hidden Files'            set_hidden_files_visible
invoke_step        'Dock Auto-Hide'          set_dock_autohide
invoke_step        'Dock Animation'          set_dock_animation_fast
invoke_step        'Finder Status Bar'       set_finder_statusbar
invoke_step        'Screenshot Location'     set_screenshot_location
invoke_step        'Screenshot Format'       set_screenshot_format_jpg
invoke_step        'Analytics'               set_analytics_off
invoke_step        'Siri Suggestions'        set_siri_suggestions_off
invoke_step        'DNS'                     set_dns_servers                 true
invoke_step        'Wi-Fi Power Saving'      set_wifi_power_saving_off
invoke_step        'Sleep Settings'          set_sleep_settings
invoke_step        'Screensaver'             set_screensaver_off
invoke_step        'Monitoring Tools'        open_monitoring_tools_if_wanted true
invoke_step        'Disk Tools'              open_disk_tools_if_wanted       true
invoke_step        'macOS Updates'           run_macos_updates_if_wanted     true
invoke_step        'Homebrew Cleanup'        run_cleanup_if_wanted           true

show_report

echo ""
echo "========================================"
echo "               Finished                 "
echo "========================================"
echo ""
echo "  Log saved to: $LOG_FILE"
echo ""

printf '\nPress Enter to exit...'
read -r
