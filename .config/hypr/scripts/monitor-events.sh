#!/bin/sh

set -eu

socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
layout_script="${HOME}/.config/hypr/scripts/monitor-layout.sh"

if [ ! -S "$socket" ]; then
    echo "Hyprland event socket not found: $socket" >&2
    exit 1
fi

read_events() {
    if command -v socat >/dev/null 2>&1; then
        socat -U - "UNIX-CONNECT:${socket}"
    elif command -v nc >/dev/null 2>&1; then
        nc -U "$socket"
    else
        echo "socat or nc is required to read Hyprland monitor events" >&2
        exit 1
    fi
}

(
    "$layout_script" sync
    sleep 3
    "$layout_script" sync
) &

read_events | while read -r event; do
    case "$event" in
        monitoradded*|monitoraddedv2*)
            "$layout_script" monitor-added
            ;;
        monitorremoved*)
            monitor="${event#*>>}"
            monitor="${monitor%%,*}"
            "$layout_script" monitor-removed "$monitor"
            ;;
    esac
done
