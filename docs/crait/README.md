# Crait Home Assistant

Target: Raspberry Pi OS Lite 64-bit, Debian 13 trixie, at `jarves@192.168.1.115`.

Run the supplied installer with sudo on Crait, with `compose.yaml` alongside it.
It installs Docker from Docker's official Debian repository and starts Home
Assistant Container. Docker is enabled at boot and Home Assistant uses
`restart: unless-stopped`. A manually stopped container remains stopped across
reboots until explicitly started again.

Configuration and the history database persist in `/opt/homeassistant/config`.
The web interface is at `http://192.168.1.115:8123`. Finish onboarding there to
create the administrator account. No router port forwarding is configured.

The container uses host networking for local discovery. The Compose file includes
the D-Bus mount and NET_ADMIN/NET_RAW capabilities for Bluetooth (the host must
run BlueZ). GPIO will be owned by a separate
native service; this installation does not switch any relay outputs.

Administrative commands on Crait:

```bash
sudo docker compose -f /opt/homeassistant/compose.yaml ps
sudo docker compose -f /opt/homeassistant/compose.yaml logs --tail 100
sudo docker compose -f /opt/homeassistant/compose.yaml restart
```

Updates are manual. Back up the configuration before an update, then run:

```bash
sudo docker compose -f /opt/homeassistant/compose.yaml pull
sudo docker compose -f /opt/homeassistant/compose.yaml up -d
```

## Inverter monitoring

Full Energy BBGI-3024WPro is connected through a Ugreen CR104 USB-to-DB9
adapter and the inverter-supplied DB9-to-RJ45 cable. The adapter uses the
`pl2303` driver. Verified serial settings: **2400 baud, 8N1**, no flow control.
The stable device path is set in `inverter-reader.py`.

Run on Crait with these files together:

```bash
sudo bash /home/jarves/homeassistant-setup/install-inverter.sh
```

The installer verifies a real reading, installs a native service, backs up and
updates Home Assistant's package configuration, checks that configuration, then
restarts HA. It needs sudo; no password belongs in these files. Existing
block-style package mappings and `!include_dir_named` packages are supported.
Other layouts require manually merging `inverter.yaml`.

The service runs as `jarves` with `dialout` access and exposes read-only JSON at
`http://127.0.0.1:8766/status`. HA's host networking makes it reachable inside the
container. No container device mapping or MQTT broker is needed. HA polls every
15 seconds, sharing one serial response across three measurement sensors:

- Inverter AC Input Voltage (V)
- Inverter Battery Charge (%) — the inverter's estimate, not a BMS measurement
- Inverter Battery Voltage (V)

History uses the existing HA recorder and its configured retention. Serial
timeouts and invalid checksums produce HTTP 503 rather than stale readings.
The adapter is opened by stable ID for every poll, allowing reconnection.
Stop the service before manually reading from the same serial port.

```bash
curl --fail http://127.0.0.1:8766/status
sudo systemctl status crait-inverter.service
sudo journalctl -u crait-inverter.service -n 30
```

The query recovered from VPower Runtime 1.03 is `CMSG` + byte `0x06` + `INV-HB`,
with no terminator. A `VPHB` response has a 4-byte header, a length byte, then
that many payload bytes including a final checksum (sum of preceding payload
bytes modulo 256). Absolute response offsets: AC input is little-endian uint16
at 17 divided by 10; battery voltage is uint16 at 25 divided by 10; battery charge
is a **single byte at 27** (byte 28 is charge current). Fields and checksum were
confirmed in the extracted .NET code and checked against real responses.
No write or inverter configuration commands are implemented.

Protocol and integration sources:
- https://mybroadband.co.za/forum/threads/fivestar-sunmagic-rs232-protocol-decoding.1242521/
- https://u-protect.com.ua/content/files/programa-dlja-nalashtuvannja-ta-montoringu-12510731.zip
- https://www.home-assistant.io/integrations/rest/
- https://www.home-assistant.io/docs/configuration/packages/

Official references:
- https://www.home-assistant.io/installation/linux/
- https://docs.docker.com/engine/install/debian/
