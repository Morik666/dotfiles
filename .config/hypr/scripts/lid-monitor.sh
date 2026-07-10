#!/bin/sh

set -eu

external_desc="Samsung Electric Company LF24T450F HK2R900537"
laptop_monitor="eDP-1"
laptop_mode="2560x1600@165"
laptop_position="0x0"
laptop_scale="1.6"

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

move_workspaces_to_monitor() {
    monitor="$1"

    hyprctl workspaces | awk '/^workspace ID / { print $3 }' | while read -r workspace; do
        hyprctl dispatch moveworkspacetomonitor "$workspace" "$monitor" >/dev/null 2>&1 || true
    done
}

restart_waybar() {
    (
        lockdir="/tmp/hypr-lid-waybar-restart.lock"

        if ! mkdir "$lockdir" 2>/dev/null; then
            exit 0
        fi
        trap 'rmdir "$lockdir"' EXIT

        pkill -f '[w]aybar' >/dev/null 2>&1 || true
        sleep 0.5
        pkill -f '[w]aybar' >/dev/null 2>&1 || true
        sleep 0.2

        hyprctl dispatch exec "waybar >/tmp/waybar.log 2>&1"
    ) &
}

case "${1:-}" in
    close)
        external_monitor="$(external_monitor_name)"

        if [ -n "$external_monitor" ]; then
            move_workspaces_to_monitor "$external_monitor"
            hyprctl keyword monitor "$laptop_monitor, disable"
            move_workspaces_to_monitor "$external_monitor"
            hyprctl dispatch focusmonitor "$external_monitor" >/dev/null 2>&1 || true
            restart_waybar
        fi
        ;;
    open)
        hyprctl keyword monitor "$laptop_monitor, $laptop_mode, $laptop_position, $laptop_scale"
        restart_waybar
        ;;
    *)
        echo "usage: $0 close|open" >&2
        exit 2
        ;;
esac
