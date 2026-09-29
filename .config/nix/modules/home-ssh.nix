{ config, pkgs, ... }:
let
  homeSSH = pkgs.writeShellApplication {
    name = "home-ssh-firewall";
    runtimeInputs = [ pkgs.iptables pkgs.networkmanager pkgs.util-linux ];
    text = builtins.readFile ./home-ssh-firewall.sh;
  };
in
{
  assertions = [
    {
      assertion = !config.networking.nftables.enable;
      message = "Home SSH dispatcher requires the NixOS iptables firewall.";
    }
  ];

  services.openssh = {
    enable = true;
    openFirewall = false;
    # Home access uses IPv4 only; do not expose SSH over global IPv6.
    settings = {
      AddressFamily = "inet";
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      AllowUsers = [ "jarves" ];
    };
  };

  networking.firewall = {
    enable = true;
    extraCommands = "${homeSSH}/bin/home-ssh-firewall";
  };

  networking.networkmanager.dispatcherScripts = [
    { source = "${homeSSH}/bin/home-ssh-firewall"; type = "basic"; }
    { source = "${homeSSH}/bin/home-ssh-firewall"; type = "pre-up"; }
    { source = "${homeSSH}/bin/home-ssh-firewall"; type = "pre-down"; }
  ];
}
