{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/bespin-ssh.nix
    ../../modules/bespin-packages.nix
  ];
  networking.hostName = "bespin";
  networking.useDHCP = true;
  networking.firewall.enable = true;

  # Set these to the installed system's values before the first deployment.
  # Keep stateVersion unchanged after installation.
  system.stateVersion = "26.05";
  users.users.jarves.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 YOUR_PUBLIC_KEY"
  ];
  assertions = [ {
    assertion = config.users.users.jarves.openssh.authorizedKeys.keys != [ ];
    message = "bespin: add your SSH public key in hosts/bespin/default.nix before deployment.";
  } ];
}
