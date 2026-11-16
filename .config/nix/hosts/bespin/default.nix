{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/bespin-ssh.nix
    ../../modules/bespin-packages.nix
  ];
  networking.hostName = "bespin";
  # Preserve the installed system's EFI bootloader and network management.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Keep stateVersion unchanged after installation.
  system.stateVersion = "26.05";
  users.users.jarves.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFf3H1h4LDVwVetHc/nQ7jLXMWztMN/OSxHT4Ry56gm morik@tsiupa.in.ua"
  ];
  assertions = [ {
    assertion = config.users.users.jarves.openssh.authorizedKeys.keys != [ ];
    message = "bespin: add your SSH public key in hosts/bespin/default.nix before deployment.";
  } ];
}
