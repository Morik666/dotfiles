# OpenWrt network record

Last audited: 2026-09-13  
Device: ASUS RT-AX53U  
Role: planned main router for the house

This file intentionally excludes Wi-Fi passwords, the root password, private
keys, MAC addresses, DHCP client identities, and other secrets.

## Installation

- Clean installation performed with:

  ```sh
  sysupgrade -n /tmp/openwrt-25.12.3-ramips-mt7621-asus_rt-ax53u-squashfs-sysupgrade.bin
  ```

- Local image SHA-256:

  ```text
  3ea794971966bbc6f9f5dedb383aea0e9d4141daeabcbed449d4792a7477e2db
  ```

- The digest matched the official OpenWrt 25.12.3 image for
  `ramips/mt7621/asus_rt-ax53u`.
- `-n` deliberately discarded configuration from the previous, untrusted
  installation.
- Audited firmware: OpenWrt 25.12.3, revision `r32912-6639b15f62`, Linux
  6.12.85, squashfs root filesystem.
- Reported board: `asus,rt-ax53u` / MediaTek MT7621.

## Current configuration

### LAN

- Router address: `192.168.1.1/24`
- Bridge: `br-lan`
- Bridge ports: `lan1`, `lan2`, `lan3`
- DHCPv4 server: enabled
- DHCP pool: `192.168.1.100` through `192.168.1.249`
- Lease time: 12 hours
- DHCPv6, router advertisements, and SLAAC: enabled
- Local DNS resolver: dnsmasq on the LAN address

### WAN

- Physical device: `wan`
- IPv4: DHCP client
- IPv6: DHCPv6 client
- WAN was physically disconnected during the audit, so ISP addressing, DNS,
  routing, NTP synchronization, and Internet connectivity were not tested.
- If the ISP requires PPPoE, VLAN tagging, a static address, or MAC
  registration, replace the default DHCP WAN settings with the ISP-provided
  values.

### Firewall

- Default input: reject
- Default forwarding: reject
- LAN input/output/forward: accept
- WAN input: reject
- WAN forwarding: drop
- LAN-to-WAN forwarding: enabled
- IPv4 masquerading/NAT and MTU fixing: enabled on WAN
- The generated nftables ruleset passed `fw4 check`.
- LuCI and SSH listen on all router addresses, but the WAN firewall zone blocks
  unsolicited access to them. Do not add WAN rules for ports 22, 80, or 443.

### Wi-Fi

| Band | SSID | Channel/width | Security | Network | State |
|---|---|---|---|---|---|
| 2.4 GHz | `Manti-Fi` | 1 / 20 MHz | WPA3-SAE | LAN | Up |
| 5 GHz | `Manti-Fi 5G` | 36 / 80 MHz | WPA3-SAE | LAN | Up |

- Runtime regulatory domain: Ukraine (`UA`, DFS-ETSI) on both radios.
- Transmit power observed: 20 dBm on both radios.
- 802.11r fast transition is not enabled.
- No wireless clients or DHCP leases were present during the audit.

### Administration

- Root password was set after the clean installation (not recorded here).
- The workstation's Ed25519 public key was added for SSH administration.
- Dropbear currently permits both public-key and root-password authentication.
- LuCI listens on HTTP and HTTPS; HTTP-to-HTTPS redirection is currently off.
- Hostname is the default `OpenWrt`.
- Timezone is the default UTC. At audit time the router clock was incorrect
  because WAN/NTP connectivity was unavailable.

## Recommended remaining work

1. Connect the ISP/modem/ONT only to the main router's WAN port and validate the
   required ISP protocol, IPv4, IPv6, DNS, and NTP synchronization.
2. Set timezone to `Europe/Kyiv` and choose a descriptive hostname such as
   `router-main`.
3. Explicitly save country `UA` on both radio device configurations, even
   though the runtime domain was already correct.
4. Enable LuCI HTTP-to-HTTPS redirection. After confirming SSH key login works,
   consider disabling SSH password authentication.
5. Keep router administration unavailable from WAN. Use a VPN for remote
   administration if it is needed later.
6. Back up `/etc/config` from LuCI after the WAN and AP deployment is complete;
   keep that backup private because it contains credentials.

## Planned dumb AP and roaming layout

- Use Ethernet backhaul. Connect main-router LAN to AP LAN; do not use the AP's
  WAN port unless that model's configuration explicitly bridges it into LAN.
- Only this main router should provide DHCP, DNS, routing, NAT, and the Internet
  firewall.
- Give APs unique management addresses outside the DHCP pool, for example
  `192.168.1.2`, `.3`, and `.4`, or create static DHCP reservations for them.
- Disable DHCP servers on every dumb AP and set their gateway/DNS to
  `192.168.1.1`.
- Use identical SSID, encryption mode, and passphrase on corresponding radios
  across all APs. The present two-SSID design can be retained (`Manti-Fi` for
  2.4 GHz and `Manti-Fi 5G` for 5 GHz), or both bands can share one SSID if
  automatic band selection is preferred.
- Keep 2.4 GHz at 20 MHz and assign nearby APs channels 1, 6, and 11 to reduce
  overlap. Select distinct 5 GHz channels after checking local utilization and
  DFS behavior.
- Start with ordinary client-controlled roaming. Add 802.11k/v only after all
  APs are configured consistently. Test client compatibility before enabling
  802.11r; OpenWrt documents restrictions with WPA3-SAE and mixed WPA2/WPA3.
- Avoid excessive transmit power: clients must also be able to transmit back,
  and oversized cells can make devices cling to a distant AP.

## Audit result

The verified offline configuration is internally consistent and safe as a
standard main-router baseline. Wi-Fi, LAN DHCP, NAT, and firewall structure are
correct. The only major unverified part is the ISP/WAN connection.

## Dumb AP 1: Xiaomi Mi Router 4A

Added: 2026-09-13  
Hostname: `ap-xiaomi-1`  
Management address: `192.168.1.2`

### Hardware and installation

- Exact model: Xiaomi Mi Router 4A 100M International Edition V2
- Board: `xiaomi,mi-router-4a-100m-intl-v2` (`R4ACv2` in stock firmware)
- SoC: MediaTek MT7628AN
- Ethernet ports are limited to 100 Mbps.
- Previous stock firmware: Xiaomi `3.0.129`
- Installed firmware: OpenWrt 25.12.3, revision `r32912-6639b15f62`, target
  `ramips/mt76x8`, Linux 6.12.85
- Official image:
  `openwrt-25.12.3-ramips-mt76x8-xiaomi_mi-router-4a-100m-intl-v2-squashfs-sysupgrade.bin`
- Verified image SHA-256:

  ```text
  02d8372f8c863099eee54731a0e575f11023ef61c6b0fc1dd19c23f890d870f8
  ```

- OpenWRTInvasion was used twice to obtain temporary stock-firmware shell
  access, as documented for R4ACv2.
- The original partition layout was confirmed before flashing. OpenWrt was
  written to the stock `OS1` partition using `/sbin/mtd`.
- A complete 16 MiB stock flash backup is stored outside this repository at:

  ```text
  /home/jarves/Downloads/xiaomi-r4acv2-stock-full-flash-2026-09-13.bin
  ```

- Backup SHA-256:

  ```text
  c9351a3ae542223ed1ba5813b8a660599130138d48510ba8ce8cd86657cd748a
  ```

  Keep that file private: it contains device-specific calibration data,
  identifiers, and the original configuration.

### Dumb-AP configuration

- Static LAN address: `192.168.1.2/24`
- Gateway and DNS: main router at `192.168.1.1`
- DHCPv4 server: disabled (`dhcp.lan.ignore=1`)
- DHCPv6 and router-advertisement server settings removed
- IPv6 prefix delegation removed from the AP LAN interface
- Stock `wan` and `wan6` routed interfaces removed
- All three physical Ethernet sockets are bridged into LAN through switch VLAN
  1 (`0 2 4 6t`). The WAN-labeled socket can therefore be used as the wired
  backhaul to the ASUS.
- Verified wired backhaul: 100 Mbps full duplex
- Pre-change configuration backup on the AP:
  `/root/pre-dumb-ap-config-2026-09-13.tar.gz`
- Firewall configuration retained and validated with `fw4 check`.
- Timezone: `Europe/Kyiv`

### Staged wireless configuration

| Band | SSID | Channel/width | Country | State |
|---|---|---|---|---|
| 2.4 GHz | `Manti-Fi` | 6 / 20 MHz | UA | Disabled pending security key |
| 5 GHz | `Manti-Fi 5G` | 149 / 80 MHz | UA | Enabled, WPA3-SAE |

Set the same encryption mode and passphrase as the corresponding ASUS SSID,
then enable each wireless interface. Channel 100 was initially selected but the
MT7615 radio failed DFS CAC and disabled the AP. Channel 149/80 MHz was selected
instead and verified active at 20 dBm with a WPA3-SAE client associated.
