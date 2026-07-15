#!/bin/sh

set -eu

external_desc="Samsung Electric Company LF24T450F HK2R900537"
external_mode="1920x1080@60"
external_scale="1"
laptop_monitor="eDP-1"
laptop_mode="2560x1600@165"
laptop_position="0x0"
laptop_scale="1.6"
pinned_workspaces="1 2"
external_state_file="/tmp/hypr-known-external-monitor"

external_monitor_name() {
    hyprctl monitors all | awk -v desc="$external_desc" '
        /^Monitor / {
            monitor = $2
            sub(/:.*/, "", monitor)
        }
        index($0, "description: " desc) {
            print monitor
            exit
        }
    '
}

remember_external_monitor() {
    monitor="$1"

    [ -n "$monitor" ] && printf '%s\n' "$monitor" >"$external_state_file"
}

known_external_monitor_name() {
    monitor="$(external_monitor_name)"

    if [ -n "$monitor" ]; then
        remember_external_monitor "$monitor"
        printf '%s\n' "$monitor"
        return 0
    fi

    if [ -r "$external_state_file" ]; then
        sed -n '1p' "$external_state_file"
    fi
}

lid_is_closed() {
    for state in /proc/acpi/button/lid/*/state; do
        [ -r "$state" ] || continue
        grep -qi closed "$state" && return 0
    done

    return 1
}

regular_workspaces() {
    hyprctl workspaces | awk '/^workspace ID / && $3 ~ /^[0-9]+$/ { print $3 }'
}

is_pinned_workspace() {
    workspace="$1"

    for pinned in $pinned_workspaces; do
        [ "$workspace" = "$pinned" ] && return 0
    done

    return 1
}

move_workspace_to_monitor() {
    workspace="$1"
    monitor="$2"

    hyprctl dispatch moveworkspacetomonitor "$workspace" "$monitor" >/dev/null 2>&1 || true
}

move_all_workspaces_to_monitor() {
    monitor="$1"

    regular_workspaces | while read -r workspace; do
        move_workspace_to_monitor "$workspace" "$monitor"
    done
}

move_pinned_workspaces_to_monitor() {
    monitor="$1"

    for workspace in $pinned_workspaces; do
        move_workspace_to_monitor "$workspace" "$monitor"
    done
}

move_unpinned_workspaces_to_monitor() {
    monitor="$1"

    regular_workspaces | while read -r workspace; do
        if ! is_pinned_workspace "$workspace"; then
            move_workspace_to_monitor "$workspace" "$monitor"
        fi
    done
}

enable_laptop_monitor() {
    hyprctl keyword monitor "$laptop_monitor, $laptop_mode, $laptop_position, $laptop_scale" >/dev/null
}

disable_laptop_monitor() {
    hyprctl keyword monitor "$laptop_monitor, disable" >/dev/null
}

focus_monitor() {
    monitor="$1"

    hyprctl dispatch focusmonitor "$monitor" >/dev/null 2>&1 || true
}

external_transform() {
    monitor="$1"

    hyprctl monitors all | awk -v wanted="$monitor" '
        $1 == "Monitor" {
            current = $2
            sub(/:.*/, "", current)
        }
        current == wanted && $1 == "transform:" {
            print $2
            exit
        }
    '
}

toggle_external_rotation() {
    monitor="$(external_monitor_name)"

    if [ -z "$monitor" ]; then
        notify-send "Monitor rotation" "External monitor is not connected"
        return 1
    fi

    transform="$(external_transform "$monitor")"

    if [ "$transform" = "0" ]; then
        hyprctl keyword monitor "$monitor,$external_mode,-1080x0,$external_scale,transform,3" >/dev/null
        orientation="Portrait"
    else
        hyprctl keyword monitor "$monitor,$external_mode,-1920x0,$external_scale,transform,0" >/dev/null
        orientation="Landscape"
    fi

    sleep 1
    pkill -x .noctalia-wrapp 2>/dev/null || true
    noctalia --daemon

    notify-send "Monitor rotation" "$orientation mode"
}

place_for_open_lid() {
    external_monitor="$(external_monitor_name)"

    enable_laptop_monitor

    if [ -n "$external_monitor" ]; then
        remember_external_monitor "$external_monitor"
        move_pinned_workspaces_to_monitor "$external_monitor"
        move_unpinned_workspaces_to_monitor "$laptop_monitor"
        focus_monitor "$external_monitor"
    else
        move_all_workspaces_to_monitor "$laptop_monitor"
        focus_monitor "$laptop_monitor"
    fi
}

place_for_closed_lid() {
    external_monitor="$(external_monitor_name)"

    if [ -n "$external_monitor" ]; then
        remember_external_monitor "$external_monitor"
        move_all_workspaces_to_monitor "$external_monitor"
        disable_laptop_monitor
        move_all_workspaces_to_monitor "$external_monitor"
        focus_monitor "$external_monitor"
    fi
}

case "${1:-}" in
    lid-close)
        place_for_closed_lid
        ;;
    lid-open)
        place_for_open_lid
        ;;
    monitor-added)
        if lid_is_closed; then
            place_for_closed_lid
        else
            external_monitor="$(external_monitor_name)"
            if [ -n "$external_monitor" ]; then
                remember_external_monitor "$external_monitor"
                move_pinned_workspaces_to_monitor "$external_monitor"
                focus_monitor "$external_monitor"
            fi
        fi
        ;;
    monitor-removed)
        removed_monitor="${2:-}"
        known_external_monitor="$(known_external_monitor_name)"

        if [ -n "$removed_monitor" ] && [ "$removed_monitor" = "$known_external_monitor" ]; then
            enable_laptop_monitor
            move_all_workspaces_to_monitor "$laptop_monitor"
            focus_monitor "$laptop_monitor"
        fi
        ;;
    sync)
        if lid_is_closed; then
            place_for_closed_lid
        else
            place_for_open_lid
        fi
        ;;
    rotate-external)
        toggle_external_rotation
        ;;
    *)
        echo "usage: $0 lid-close|lid-open|monitor-added|monitor-removed|sync|rotate-external" >&2
        exit 2
        ;;
esac
