# Called by both the firewall and NetworkManager. Serialize concurrent events.
exec 9>/run/home-ssh-firewall.lock
flock 9

# The standard NixOS iptables firewall owns the hook. If it is stopped,
# a dispatcher event must not create an independent firewall.
iptables -w -S nixos-fw >/dev/null 2>&1 || exit 0
iptables -w -N home-ssh 2>/dev/null || true

# Block SSH before rebuilding the allowlist, including established sessions.
# This guard also makes a failed NetworkManager query fail closed.
iptables -w -I nixos-fw 1 ! -i lo -p tcp --dport 22 -j DROP
iptables -w -F home-ssh
iptables -w -A home-ssh -j DROP

excluded_interface=""
case "${2:-}" in
  pre-up|pre-down|down) excluded_interface="${1:-}" ;;
esac

# NetworkManager may not be running yet during firewall startup. An empty
# allowlist lets the firewall finish starting with SSH blocked.
connections=$(nmcli --terse --escape no --fields UUID,DEVICE connection show --active) || connections=""
while IFS=: read -r uuid interface; do
  case "$uuid" in
    # MantiFi and Manti-Fi 5G. Profile UUIDs survive display-name changes.
    ed1e1bfa-95fd-4991-bfb6-18a044b398b0|0f400ebe-9e1c-45a9-8705-ec800b2577f2) ;;
    *) continue ;;
  esac
  [[ -n "$interface" && "$interface" != "$excluded_interface" ]] || continue
  state=$(LC_ALL=C nmcli --get-values GENERAL.STATE device show "$interface") || continue
  [[ "$state" == "100 (connected)" ]] || continue
  iptables -w -I home-ssh 1 -i "$interface" -s 192.168.1.0/24 -j ACCEPT
done <<< "$connections"

# Insert before the standard established-connection and allowed-port rules.
if ! iptables -w -C nixos-fw ! -i lo -p tcp --dport 22 -j home-ssh 2>/dev/null; then
  iptables -w -I nixos-fw 1 ! -i lo -p tcp --dport 22 -j home-ssh
fi
while iptables -w -C nixos-fw ! -i lo -p tcp --dport 22 -j DROP 2>/dev/null; do
  iptables -w -D nixos-fw ! -i lo -p tcp --dport 22 -j DROP
done
