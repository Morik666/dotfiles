#!/bin/sh

quickshell kill --path ~/.config/quickshell >/dev/null 2>&1 || pkill quickshell >/dev/null 2>&1 || true
sleep 0.2
quickshell --path ~/.config/quickshell >/tmp/quickshell.log 2>&1 &
