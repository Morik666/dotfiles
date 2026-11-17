#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo 'Run with sudo.' >&2
  exit 1
fi
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
docker compose -f "$source_dir/compose.yaml" config --quiet
cp -p /opt/homeassistant/compose.yaml "/opt/homeassistant/compose.yaml.backup-$(date +%Y%m%d-%H%M%S)"
install -m 0644 "$source_dir/compose.yaml" /opt/homeassistant/compose.yaml
docker compose -f /opt/homeassistant/compose.yaml up -d --pull never
docker compose -f /opt/homeassistant/compose.yaml ps
