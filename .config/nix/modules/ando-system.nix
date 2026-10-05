{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ando"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
  };
  # services.xserver.xkb = {
  #   layout = "us,ua";
  #   variant = ",homophonic";
  #   options = "grp:win_space_toggle";
  # };

  users.users.jarves.extraGroups = [ "networkmanager" "scanner" "lp" ];

  # Enable automatic login for the user.
  services.getty.autologinUser = "jarves";

  system.stateVersion = "25.05"; # Do not change
}
