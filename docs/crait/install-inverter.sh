#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this installer with sudo on Crait." >&2
  exit 1
fi
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=/opt/homeassistant/config
stamp=$(date +%Y%m%d-%H%M%S)
backup="$config_dir/configuration.yaml.backup-inverter-$stamp"
package_backup="$config_dir/crait-inverter.yaml.backup-$stamp"

# Confirm a real, checksum-validated reading before changing Home Assistant.
runuser -u jarves -- python3 "$source_dir/inverter-reader.py"
docker inspect homeassistant >/dev/null
cp -p "$config_dir/configuration.yaml" "$backup"
if [[ -f "$config_dir/crait-inverter.yaml" ]]; then
  cp -p "$config_dir/crait-inverter.yaml" "$package_backup"
fi
install -d -m 0755 /opt/crait-inverter
install -m 0644 "$source_dir/inverter-reader.py" /opt/crait-inverter/inverter-reader.py
install -m 0644 "$source_dir/crait-inverter.service" /etc/systemd/system/crait-inverter.service
install -m 0644 "$source_dir/inverter.yaml" "$config_dir/crait-inverter.yaml"
restore_config() {
  cp -p "$backup" "$config_dir/configuration.yaml"
  if [[ -f "$package_backup" ]]; then
    cp -p "$package_backup" "$config_dir/crait-inverter.yaml"
  fi
}
if ! docker exec -i homeassistant python3 - < "$source_dir/configure-inverter.py"; then
  restore_config
  echo "HA configuration restored. See the error above." >&2
  exit 1
fi
if ! docker exec homeassistant python3 -m homeassistant --script check_config --config /config; then
  restore_config
  echo "HA configuration check failed; main configuration restored. HA was not restarted." >&2
  exit 1
fi
systemctl daemon-reload
systemctl enable --now crait-inverter.service
systemctl restart crait-inverter.service
for attempt in {1..10}; do
  if curl --fail --silent http://127.0.0.1:8766/status; then
    break
  fi
  if [[ $attempt -eq 10 ]]; then
    echo "Reader did not become ready; inspect journalctl -u crait-inverter." >&2
    exit 1
  fi
  sleep 1
done
docker restart homeassistant
echo "Installed. HA polls every 15 seconds. Configuration backup: $backup"
