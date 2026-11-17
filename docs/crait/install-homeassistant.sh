#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo 'Run this installer with sudo.' >&2
  exit 1
fi

source /etc/os-release
if [[ ${VERSION_CODENAME:-} != trixie ]] || [[ $(dpkg --print-architecture) != arm64 ]]; then
  echo 'This installer targets Crait: Debian/Raspberry Pi OS trixie arm64.' >&2
  exit 1
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test -f "$source_dir/compose.yaml"
if [[ -e /opt/homeassistant/compose.yaml ]] && ! cmp -s "$source_dir/compose.yaml" /opt/homeassistant/compose.yaml; then
  echo 'Existing Compose configuration differs; review it before replacing.' >&2
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl --fail --silent --show-error --location https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod 0644 /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: arm64
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

install -d -m 0755 /opt/homeassistant
install -d -m 0700 /opt/homeassistant/config
install -m 0644 "$source_dir/compose.yaml" /opt/homeassistant/compose.yaml
docker compose -f /opt/homeassistant/compose.yaml config --quiet
docker compose -f /opt/homeassistant/compose.yaml pull
docker compose -f /opt/homeassistant/compose.yaml up -d
docker compose -f /opt/homeassistant/compose.yaml ps
echo 'Home Assistant is starting. Open http://192.168.1.115:8123 after initialization.'
