#!/usr/bin/env bash
set -euo pipefail

# Run in a terminal so sudo can request authentication when needed.
printer=HP_LaserJet_MFP_M141w_FB52B2_USB
uuid=3ecbb76e-741a-450d-aa6c-f0306681221c
trap 'printf "\nPrinting recovery failed. Press Enter to close.\n"; read -r _' ERR

printf 'Restarting CUPS and printer discovery…\n'
sudo systemctl start ipp-usb.service
sudo systemctl restart cups.service
sudo systemctl restart cups-browsed.service

# Find this specific USB printer. ipp-usb may allocate a different local port.
uri=$(ippfind -T 5 --local --txt-UUID "^${uuid}$" \
    --exec echo 'ipp://localhost:{service_port}/{txt_rp}' \;)
if [[ -z "$uri" || "$uri" == *$'\n'* ]]; then
    printf 'Could not uniquely locate the HP USB printer. Check its power and USB cable.\n' >&2
    false
fi
printf 'Connecting %s directly to %s…\n' "$printer" "$uri"
# Keep the existing queue and its jobs, bypassing the broken implicitclass backend.
sudo lpadmin -p "$printer" -v "$uri" -m everywhere -o cups-browsed=false
sudo cupsenable "$printer"
printf '\n'
lpstat -t
printf '\nDirect USB queue configured. Queued jobs are preserved. Press Enter to close.\n'
read -r _
