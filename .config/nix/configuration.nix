{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/system-users.nix
    ./modules/desktop.nix
    ./modules/packages.nix
  ];
}
