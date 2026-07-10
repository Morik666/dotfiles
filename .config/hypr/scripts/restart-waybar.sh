#!/bin/sh

pkill waybar >/dev/null 2>&1 || true
sleep 1
hyprctl dispatch exec "waybar >/tmp/waybar.log 2>&1"
