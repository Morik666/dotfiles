#!/bin/sh

pkill waybar >/dev/null 2>&1 || true
sleep 0.2
waybar >/tmp/waybar.log 2>&1 &
