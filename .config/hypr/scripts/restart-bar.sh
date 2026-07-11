#!/bin/sh

mantix_shell_path="/home/jarves/Projects/MantixShell"

quickshell kill --path "$mantix_shell_path" >/dev/null 2>&1 || pkill quickshell >/dev/null 2>&1 || true
sleep 0.2
quickshell --path "$mantix_shell_path" >/tmp/quickshell.log 2>&1 &
