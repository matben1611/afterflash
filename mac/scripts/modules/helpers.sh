#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# helpers.sh — shared utility functions for afterflash-mac
# ---------------------------------------------------------------------------
# Global variables expected to be set by setup.sh:
#   QUICK_SETUP, CURRENT_STEP, TOTAL_STEPS, CURRENT_STEP_APPLIED, LOG_FILE

write_typewriter() {
    local text="$1"
    local delay="${2:-0.04}"
    local i
    for (( i=0; i<${#text}; i++ )); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

is_root() {
    [[ $EUID -eq 0 ]]
}

wait_a_bit() {
    local seconds=$(( RANDOM % 3 + 1 ))
    local frames=('|' '/' '-' '\')
    local end=$(( $(date +%s) + seconds ))
    local i=0
    while [[ $(date +%s) -lt $end ]]; do
        printf '\r  %s  ' "${frames[$((i % 4))]}"
        sleep 0.08
        (( i++ )) || true
    done
    printf '\r     \n'
}

add_to_log() {
    local msg="$1"
    if [[ -n "${LOG_FILE:-}" ]]; then
        local ts
        ts=$(date '+%H:%M:%S')
        echo "[$ts] $msg" >> "$LOG_FILE"
    fi
}

write_info() {
    echo "[INFO ] $1"
    add_to_log "[INFO ] $1"
}

write_ok() {
    echo "[ OK  ] $1"
    add_to_log "[ OK  ] $1"
    CURRENT_STEP_APPLIED=true
}

write_warn() {
    echo "[WARN ] $1" >&2
    add_to_log "[WARN ] $1"
}

read_yes_no() {
    local prompt="$1"

    if [[ "${QUICK_SETUP:-false}" == "true" ]]; then
        echo "$prompt (Yes/No): Yes"
        echo ""
        return 0
    fi

    while true; do
        printf '%s (Yes/No): ' "$prompt"
        read -r answer
        case "${answer,,}" in
            y|yes) echo ""; return 0 ;;
            n|no)  echo ""; return 1 ;;
            *)     echo "Please enter 'Yes' or 'No'." ;;
        esac
    done
}

run_defaults() {
    local domain="$1"
    local key="$2"
    local type="$3"
    local value="$4"
    defaults write "$domain" "$key" "$type" "$value"
    write_ok "defaults write $domain $key = $value"
}
